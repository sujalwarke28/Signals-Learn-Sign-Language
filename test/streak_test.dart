import 'package:flutter_test/flutter_test.dart';
import 'package:signals/models/lesson.dart';
import 'package:signals/models/lesson_progress.dart';
import 'package:signals/models/progress_summary.dart';
import 'package:signals/models/quiz_attempt.dart';

/// A fixed "today" so these tests never depend on when they run.
final today = DateTime(2026, 10, 1);
DateTime daysAgo(int n) => DateTime(2026, 10, 1 - n);

QuizAttempt attemptOn(DateTime? when, {String id = 'a'}) => QuizAttempt(
      id: id,
      lessonId: 'l1',
      lessonTitle: 'Greetings',
      category: 'Basics',
      score: 4,
      total: 5,
      passed: true,
      createdAt: when,
    );

LessonProgress watchedOn(DateTime? when, {String id = 'l1'}) => LessonProgress(
      lessonId: id,
      status: LessonStatus.inProgress,
      updatedAt: when,
    );

Lesson lesson(String id) => Lesson(
      id: id,
      title: 'Lesson $id',
      description: 'desc',
      category: 'Basics',
      durationSeconds: 60,
      videoUrl: 'https://example.com/$id.mp4',
    );

int streakFrom({
  List<QuizAttempt> attempts = const [],
  Map<String, LessonProgress> progress = const {},
}) =>
    ProgressSummary.from(
      // A lesson has to exist: with no lessons *and* no attempts, from()
      // short-circuits to `empty` before any streak is computed.
      lessons: [lesson('l1'), lesson('l2'), lesson('l3')],
      progress: progress,
      attempts: attempts,
      today: today,
    ).dayStreak;

void main() {
  group('day streak', () {
    test('no activity at all is no streak', () {
      expect(streakFrom(), 0);
    });

    test('counts consecutive days of quizzes', () {
      expect(
        streakFrom(attempts: [
          attemptOn(today, id: 'a'),
          attemptOn(daysAgo(1), id: 'b'),
          attemptOn(daysAgo(2), id: 'c'),
        ]),
        3,
      );
    });

    test('watching a lesson counts, not just sitting a quiz', () {
      expect(
        streakFrom(progress: {
          'l1': watchedOn(today, id: 'l1'),
          'l2': watchedOn(daysAgo(1), id: 'l2'),
          'l3': watchedOn(daysAgo(2), id: 'l3'),
        }),
        3,
      );
    });

    test('quizzes and lesson activity combine into one run of days', () {
      expect(
        streakFrom(
          attempts: [attemptOn(daysAgo(2))],
          progress: {
            'l1': watchedOn(today, id: 'l1'),
            'l2': watchedOn(daysAgo(1), id: 'l2'),
          },
        ),
        3,
      );
    });

    test('two sessions on one day still count as one day', () {
      expect(
        streakFrom(attempts: [
          attemptOn(DateTime(2026, 10, 1, 9), id: 'a'),
          attemptOn(DateTime(2026, 10, 1, 21), id: 'b'),
        ]),
        1,
      );
    });

    test('yesterday alone keeps the streak alive through today', () {
      expect(streakFrom(attempts: [attemptOn(daysAgo(1))]), 1);
    });

    test('a missed day breaks it', () {
      expect(
        streakFrom(attempts: [
          attemptOn(daysAgo(2), id: 'a'),
          attemptOn(daysAgo(3), id: 'b'),
        ]),
        0,
      );
    });

    test('a gap only counts the run nearest today', () {
      expect(
        streakFrom(attempts: [
          attemptOn(today, id: 'a'),
          attemptOn(daysAgo(1), id: 'b'),
          // gap at daysAgo(2)
          attemptOn(daysAgo(3), id: 'c'),
          attemptOn(daysAgo(4), id: 'd'),
        ]),
        2,
      );
    });

    test('an unresolved server timestamp counts as today', () {
      // Firestore hands back null for a serverTimestamp it has not confirmed,
      // so a quiz submitted seconds ago must not be dropped from the streak.
      expect(streakFrom(attempts: [attemptOn(null)]), 1);
    });

    test('an unfinished lesson does not credit today via a null completedAt', () {
      // Regression: treating every null timestamp as "today" pinned the streak
      // at 1 forever, because an in-progress lesson has no completedAt.
      expect(
        streakFrom(progress: {
          'l1': LessonProgress(
            lessonId: 'l1',
            status: LessonStatus.inProgress,
            startedAt: daysAgo(9),
            updatedAt: daysAgo(9),
          ),
        }),
        0,
      );
    });

    test('a notStarted lesson is not activity', () {
      expect(
        streakFrom(progress: {
          'l1': LessonProgress(
            lessonId: 'l1',
            status: LessonStatus.notStarted,
            updatedAt: today,
          ),
        }),
        0,
      );
    });

    test('the run is measured against the day passed in, not the real clock', () {
      // Same data, read on a later day: the streak is gone rather than frozen.
      expect(streakFrom(attempts: [attemptOn(daysAgo(5))]), 0);
    });
  });
}
