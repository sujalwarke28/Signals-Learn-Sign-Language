import 'package:cloud_firestore/cloud_firestore.dart';

enum LessonStatus {
  notStarted,
  inProgress,
  completed;

  static LessonStatus fromName(String? name) => LessonStatus.values
      .firstWhere((s) => s.name == name, orElse: () => LessonStatus.notStarted);

  String get label => switch (this) {
        LessonStatus.notStarted => 'Not started',
        LessonStatus.inProgress => 'In progress',
        LessonStatus.completed => 'Completed',
      };
}

/// Per-learner, per-lesson state at `users/{uid}/progress/{lessonId}`.
///
/// A lesson is `completed` only when the video has been watched through *and*
/// the quiz has been passed; the state machine lives in
/// [ProgressRepository.recomputeStatus].
class LessonProgress {
  const LessonProgress({
    required this.lessonId,
    required this.status,
    this.videoCompleted = false,
    this.quizPassed = false,
    this.bestScorePercent = 0,
    this.attemptCount = 0,
    this.lastPositionSeconds = 0,
    this.startedAt,
    this.completedAt,
    this.updatedAt,
  });

  final String lessonId;
  final LessonStatus status;
  final bool videoCompleted;
  final bool quizPassed;
  final int bestScorePercent;
  final int attemptCount;
  final int lastPositionSeconds;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? updatedAt;

  bool get isCompleted => status == LessonStatus.completed;
  bool get isInProgress => status == LessonStatus.inProgress;

  /// The quiz only opens up once the video has actually been watched.
  bool get quizUnlocked => videoCompleted;

  static LessonProgress notStarted(String lessonId) =>
      LessonProgress(lessonId: lessonId, status: LessonStatus.notStarted);

  factory LessonProgress.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return LessonProgress(
      lessonId: doc.id,
      status: LessonStatus.fromName(data['status'] as String?),
      videoCompleted: (data['videoCompleted'] as bool?) ?? false,
      quizPassed: (data['quizPassed'] as bool?) ?? false,
      bestScorePercent: (data['bestScorePercent'] as num?)?.toInt() ?? 0,
      attemptCount: (data['attemptCount'] as num?)?.toInt() ?? 0,
      lastPositionSeconds: (data['lastPositionSeconds'] as num?)?.toInt() ?? 0,
      startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
