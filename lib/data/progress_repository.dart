import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants.dart';
import '../models/lesson.dart';
import '../models/lesson_progress.dart';
import '../models/question.dart';
import '../models/quiz_attempt.dart';
import 'firestore_refs.dart';

/// Reads and writes the learner's own progress.
///
/// The three writes below are the only places lesson state changes, and each
/// one re-derives `status` from the two facts that define it — video watched and
/// quiz passed — rather than setting it directly.
class ProgressRepository {
  ProgressRepository(FirebaseFirestore db)
      : _db = db,
        _refs = Refs(db);

  final FirebaseFirestore _db;
  final Refs _refs;

  Stream<Map<String, LessonProgress>> watchProgress(String uid) =>
      _refs.progress(uid).snapshots().map((snap) => {
            for (final d in snap.docs) d.id: LessonProgress.fromDoc(d),
          });

  Stream<LessonProgress> watchLessonProgress(String uid, String lessonId) =>
      _refs.lessonProgress(uid, lessonId).snapshots().map(
            (d) => d.exists ? LessonProgress.fromDoc(d) : LessonProgress.notStarted(lessonId),
          );

  Stream<List<QuizAttempt>> watchAttempts(String uid) =>
      _refs.attempts(uid).snapshots().map((snap) {
        final attempts = snap.docs.map(QuizAttempt.fromDoc).toList();
        attempts.sort((a, b) {
          final at = a.createdAt, bt = b.createdAt;
          if (at == null && bt == null) return 0;
          if (at == null) return 1;
          if (bt == null) return -1;
          return bt.compareTo(at);
        });
        return attempts;
      });

  Stream<List<QuizAttempt>> watchLessonAttempts(String uid, String lessonId) =>
      _refs.attempts(uid).where('lessonId', isEqualTo: lessonId).snapshots().map(
          (snap) => snap.docs.map(QuizAttempt.fromDoc).toList());

  /// Called the moment the video starts playing: not started -> in progress.
  Future<void> markVideoStarted(String uid, String lessonId) async {
    final ref = _refs.lessonProgress(uid, lessonId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final existing =
          snap.exists ? LessonProgress.fromDoc(snap) : LessonProgress.notStarted(lessonId);
      // Don't drag a finished lesson back to in-progress on a re-watch.
      if (existing.isCompleted) return;
      tx.set(
        ref,
        {
          'status': LessonStatus.inProgress.name,
          'videoCompleted': existing.videoCompleted,
          'quizPassed': existing.quizPassed,
          'startedAt': existing.startedAt == null
              ? FieldValue.serverTimestamp()
              : Timestamp.fromDate(existing.startedAt!),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  Future<void> saveVideoPosition(String uid, String lessonId, int seconds) =>
      _refs.lessonProgress(uid, lessonId).set(
        {'lastPositionSeconds': seconds, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );

  /// Video watched through — unlocks the quiz. Doesn't complete the lesson on
  /// its own; the quiz still has to be passed.
  Future<void> markVideoCompleted(String uid, String lessonId) async {
    final ref = _refs.lessonProgress(uid, lessonId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final existing =
          snap.exists ? LessonProgress.fromDoc(snap) : LessonProgress.notStarted(lessonId);
      final status = _statusFor(videoCompleted: true, quizPassed: existing.quizPassed);
      tx.set(
        ref,
        {
          'videoCompleted': true,
          'quizPassed': existing.quizPassed,
          'status': status.name,
          'startedAt': existing.startedAt == null
              ? FieldValue.serverTimestamp()
              : Timestamp.fromDate(existing.startedAt!),
          if (status == LessonStatus.completed && existing.completedAt == null)
            'completedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  /// Scores a finished quiz, stores the attempt, and folds the result into the
  /// lesson's progress document — all in one transaction so the Dashboard and
  /// Progress streams never observe a half-applied result.
  Future<QuizAttempt> submitAttempt({
    required String uid,
    required Lesson lesson,
    required List<Question> questions,
    required Map<String, int> answers,
  }) async {
    var score = 0;
    for (final q in questions) {
      final picked = answers[q.id];
      if (picked != null && q.isCorrect(picked)) score++;
    }
    final total = questions.length;
    final percent = total == 0 ? 0 : ((score / total) * 100).round();
    final passed = percent >= AppConstants.passThresholdPercent;

    final attemptRef = _refs.attempts(uid).doc();
    final progressRef = _refs.lessonProgress(uid, lesson.id);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(progressRef);
      final existing = snap.exists
          ? LessonProgress.fromDoc(snap)
          : LessonProgress.notStarted(lesson.id);

      tx.set(attemptRef, {
        'lessonId': lesson.id,
        'lessonTitle': lesson.title,
        'category': lesson.category,
        'score': score,
        'total': total,
        'percent': percent,
        'passed': passed,
        'answers': answers,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final quizPassed = existing.quizPassed || passed;
      // Reaching the quiz requires finishing the video, but be forgiving if the
      // flag never landed (e.g. the app was killed mid-playback).
      final videoCompleted = existing.videoCompleted || passed;
      final status = _statusFor(videoCompleted: videoCompleted, quizPassed: quizPassed);

      tx.set(
        progressRef,
        {
          'videoCompleted': videoCompleted,
          'quizPassed': quizPassed,
          'status': status.name,
          'bestScorePercent':
              percent > existing.bestScorePercent ? percent : existing.bestScorePercent,
          'attemptCount': existing.attemptCount + 1,
          'startedAt': existing.startedAt == null
              ? FieldValue.serverTimestamp()
              : Timestamp.fromDate(existing.startedAt!),
          if (status == LessonStatus.completed && existing.completedAt == null)
            'completedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });

    return QuizAttempt(
      id: attemptRef.id,
      lessonId: lesson.id,
      lessonTitle: lesson.title,
      category: lesson.category,
      score: score,
      total: total,
      passed: passed,
      answers: answers,
      createdAt: DateTime.now(),
    );
  }

  /// The lesson state machine, in one expression.
  static LessonStatus _statusFor({
    required bool videoCompleted,
    required bool quizPassed,
  }) {
    if (videoCompleted && quizPassed) return LessonStatus.completed;
    return LessonStatus.inProgress;
  }
}
