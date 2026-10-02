import 'package:cloud_firestore/cloud_firestore.dart';

/// A finished quiz run, stored at `users/{uid}/attempts/{attemptId}`.
///
/// These documents are the single source of truth for every score the app
/// reports — nothing about progress is hardcoded or simulated.
class QuizAttempt {
  const QuizAttempt({
    required this.id,
    required this.lessonId,
    required this.lessonTitle,
    required this.category,
    required this.score,
    required this.total,
    required this.passed,
    this.answers = const {},
    this.createdAt,
  });

  final String id;
  final String lessonId;
  final String lessonTitle;
  final String category;
  final int score;
  final int total;
  final bool passed;

  /// questionId -> the option index the learner picked.
  final Map<String, int> answers;
  final DateTime? createdAt;

  int get percent => total == 0 ? 0 : ((score / total) * 100).round();

  factory QuizAttempt.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return QuizAttempt(
      id: doc.id,
      lessonId: (data['lessonId'] as String?) ?? '',
      lessonTitle: (data['lessonTitle'] as String?) ?? '',
      category: (data['category'] as String?) ?? '',
      score: (data['score'] as num?)?.toInt() ?? 0,
      total: (data['total'] as num?)?.toInt() ?? 0,
      passed: (data['passed'] as bool?) ?? false,
      answers: ((data['answers'] as Map?) ?? const {})
          .map((k, v) => MapEntry('$k', (v as num).toInt())),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'lessonId': lessonId,
        'lessonTitle': lessonTitle,
        'category': category,
        'score': score,
        'total': total,
        'passed': passed,
        'percent': percent,
        'answers': answers,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
