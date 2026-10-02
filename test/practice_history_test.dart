import 'package:flutter_test/flutter_test.dart';

import 'package:signals/models/quiz_attempt.dart';
import 'package:signals/screens/progress/practice_history.dart';

final _today = DateTime(2026, 10, 2, 9);

QuizAttempt _attempt(DateTime? at) => QuizAttempt(
      id: 'a${at?.millisecondsSinceEpoch ?? 0}',
      lessonId: 'l1',
      lessonTitle: 'Lesson',
      category: 'Alphabet',
      score: 3,
      total: 4,
      passed: true,
      answers: const {},
      createdAt: at,
    );

void main() {
  group('practice history', () {
    test('always returns one entry per day, oldest first', () {
      final days = practiceHistory(attempts: const [], today: _today);
      expect(days.length, 14);
      expect(days.first.date, DateTime(2026, 9, 19));
      expect(days.last.date, DateTime(2026, 10, 2));
      expect(days.every((d) => !d.practised), isTrue);
    });

    test('buckets several attempts onto the same day', () {
      final days = practiceHistory(
        attempts: [
          _attempt(DateTime(2026, 10, 2, 8)),
          _attempt(DateTime(2026, 10, 2, 21)),
          _attempt(DateTime(2026, 10, 1, 12)),
        ],
        today: _today,
      );
      expect(days.last.attempts, 2);
      expect(days[days.length - 2].attempts, 1);
    });

    test('counts calendar days, so either side of midnight is two days', () {
      // The point of the strip is "did you show up", and showing up at 23:50
      // and again at 00:10 is twice.
      final days = practiceHistory(
        attempts: [
          _attempt(DateTime(2026, 10, 1, 23, 50)),
          _attempt(DateTime(2026, 10, 2, 0, 10)),
        ],
        today: _today,
      );
      expect(days.where((d) => d.practised).length, 2);
    });

    test('drops anything outside the window', () {
      final days = practiceHistory(
        attempts: [
          _attempt(DateTime(2026, 9, 1)), // too old
          _attempt(DateTime(2026, 10, 9)), // in the future
        ],
        today: _today,
      );
      expect(days.every((d) => !d.practised), isTrue);
    });

    test('survives attempts with no timestamp', () {
      // Documents written before createdAt existed must not crash the chart.
      final days = practiceHistory(attempts: [_attempt(null)], today: _today);
      expect(days.length, 14);
      expect(days.every((d) => !d.practised), isTrue);
    });

    test('honours a different window length', () {
      expect(
        practiceHistory(attempts: const [], today: _today, days: 7).length,
        7,
      );
    });
  });
}
