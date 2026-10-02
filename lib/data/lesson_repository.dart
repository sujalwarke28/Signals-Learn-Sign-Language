import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/lesson.dart';
import '../models/question.dart';
import 'firestore_refs.dart';

class LessonRepository {
  LessonRepository(FirebaseFirestore db)
      : _db = db,
        _refs = Refs(db);

  final FirebaseFirestore _db;
  final Refs _refs;

  /// All lessons, ordered for the library. Sorting by `order` then `title`
  /// happens client-side so a newly uploaded lesson needs no composite index.
  Stream<List<Lesson>> watchLessons() =>
      _refs.lessons.snapshots().map((snap) {
        final lessons = snap.docs.map(Lesson.fromDoc).toList();
        lessons.sort((a, b) {
          final byOrder = a.order.compareTo(b.order);
          return byOrder != 0 ? byOrder : a.title.compareTo(b.title);
        });
        return lessons;
      });

  Stream<Lesson?> watchLesson(String id) =>
      _refs.lesson(id).snapshots().map((d) => d.exists ? Lesson.fromDoc(d) : null);

  Stream<List<Question>> watchQuestions(String lessonId) =>
      _refs.questions(lessonId).snapshots().map((snap) {
        final questions =
            snap.docs.map((d) => Question.fromDoc(d, lessonId: lessonId)).toList();
        questions.sort((a, b) => a.order.compareTo(b.order));
        return questions;
      });

  Future<List<Question>> fetchQuestions(String lessonId) async {
    final snap = await _refs.questions(lessonId).get();
    final questions =
        snap.docs.map((d) => Question.fromDoc(d, lessonId: lessonId)).toList();
    questions.sort((a, b) => a.order.compareTo(b.order));
    return questions;
  }

  /// Creates a lesson and its questions in one atomic batch, so a lesson can
  /// never show up in the library with a half-written quiz.
  Future<String> createLesson({
    required Lesson lesson,
    required List<Question> questions,
  }) async {
    final lessonRef = lesson.id.isEmpty ? _refs.lessons.doc() : _refs.lesson(lesson.id);
    final batch = _db.batch();
    batch.set(lessonRef, lesson.toMap());
    for (var i = 0; i < questions.length; i++) {
      final q = questions[i];
      batch.set(
        lessonRef.collection('questions').doc(),
        {...q.toMap(), 'order': i},
      );
    }
    await batch.commit();
    return lessonRef.id;
  }

  Future<void> addQuestions(String lessonId, List<Question> questions) async {
    final existing = await _refs.questions(lessonId).get();
    var order = existing.docs.length;
    final batch = _db.batch();
    for (final q in questions) {
      batch.set(_refs.questions(lessonId).doc(), {...q.toMap(), 'order': order++});
    }
    await batch.commit();
  }

  Future<void> deleteLesson(String lessonId) async {
    final questions = await _refs.questions(lessonId).get();
    final batch = _db.batch();
    for (final d in questions.docs) {
      batch.delete(d.reference);
    }
    batch.delete(_refs.lesson(lessonId));
    await batch.commit();
  }

  /// Highest `order` currently in use, so new lessons land at the end.
  Future<int> nextOrder() async {
    final snap = await _refs.lessons.get();
    if (snap.docs.isEmpty) return 0;
    return snap.docs
            .map((d) => (d.data()['order'] as num?)?.toInt() ?? 0)
            .reduce((a, b) => a > b ? a : b) +
        1;
  }
}
