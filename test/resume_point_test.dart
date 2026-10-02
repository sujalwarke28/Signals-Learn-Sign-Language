import 'package:flutter_test/flutter_test.dart';

import 'package:signals/models/lesson_progress.dart';
import 'package:signals/screens/lessons/watch_action.dart';

LessonProgress _p({int at = 0, bool done = false}) => LessonProgress(
      lessonId: 'l1',
      status: done ? LessonStatus.completed : LessonStatus.inProgress,
      videoCompleted: done,
      lastPositionSeconds: at,
    );

const _len = Duration(seconds: 100);

void main() {
  group('resume point', () {
    test('a rewatch always starts from zero, even mid-way', () {
      expect(
        resumePointFor(rewatch: true, progress: _p(at: 42), duration: _len),
        Duration.zero,
      );
    });

    test('a normal entry resumes at the saved position', () {
      expect(
        resumePointFor(rewatch: false, progress: _p(at: 42), duration: _len),
        const Duration(seconds: 42),
      );
    });

    test('a finished video starts over rather than resuming', () {
      expect(
        resumePointFor(rewatch: false, progress: _p(at: 99, done: true), duration: _len),
        Duration.zero,
      );
    });

    test('a position at the very end restarts instead of freezing', () {
      expect(
        resumePointFor(rewatch: false, progress: _p(at: 100), duration: _len),
        Duration.zero,
      );
    });

    test('a fresh lesson starts from zero', () {
      expect(
        resumePointFor(rewatch: false, progress: _p(), duration: _len),
        Duration.zero,
      );
    });

    test('an unknown duration still honours the saved position', () {
      expect(
        resumePointFor(rewatch: false, progress: _p(at: 42), duration: Duration.zero),
        const Duration(seconds: 42),
      );
    });
  });
}
