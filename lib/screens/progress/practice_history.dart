import '../../models/quiz_attempt.dart';

/// One day on the practice strip.
class PracticeDay {
  const PracticeDay({required this.date, required this.attempts});

  final DateTime date;
  final int attempts;

  bool get practised => attempts > 0;
}

/// Buckets quiz attempts into the last [days] calendar days, oldest first.
///
/// Calendar days rather than rolling 24-hour windows: someone who practised at
/// 23:50 last night and 00:10 tonight has shown up on two days, and the strip
/// should say so.
///
/// Pure, so the bucketing is testable without Firestore — the same reason
/// [recallCandidate] and [LibrarySnapshot.from] are.
List<PracticeDay> practiceHistory({
  required List<QuizAttempt> attempts,
  required DateTime today,
  int days = 14,
}) {
  final end = DateTime(today.year, today.month, today.day);
  final counts = <DateTime, int>{};

  for (final a in attempts) {
    final at = a.createdAt;
    if (at == null) continue;
    final day = DateTime(at.year, at.month, at.day);
    final age = end.difference(day).inDays;
    if (age < 0 || age >= days) continue;
    counts[day] = (counts[day] ?? 0) + 1;
  }

  return [
    for (var i = days - 1; i >= 0; i--)
      () {
        final d = end.subtract(Duration(days: i));
        return PracticeDay(date: d, attempts: counts[d] ?? 0);
      }(),
  ];
}
