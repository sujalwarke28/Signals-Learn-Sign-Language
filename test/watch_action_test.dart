import 'package:flutter_test/flutter_test.dart';

import 'package:signals/models/lesson.dart';
import 'package:signals/models/lesson_progress.dart';
import 'package:signals/screens/lessons/watch_action.dart';

Lesson _lesson({String videoUrl = 'https://example.com/a.mp4'}) => Lesson(
      id: 'l1',
      title: 'T',
      description: 'd',
      category: 'Alphabet',
      durationSeconds: 60,
      videoUrl: videoUrl,
      order: 0,
    );

LessonProgress _p(LessonStatus status, {bool videoCompleted = false}) =>
    LessonProgress(
      lessonId: 'l1',
      status: status,
      videoCompleted: videoCompleted,
    );

void main() {
  group('watch action, rewatch disabled', () {
    test('a finished video cannot be re-entered', () {
      final a = watchActionFor(
        lesson: _lesson(),
        progress: _p(LessonStatus.completed, videoCompleted: true),
        allowRewatch: false,
      );
      expect(a.enabled, isFalse);
      expect(a.rewatch, isFalse);
      expect(a.label, isNot(contains('Rewatch')));
    });

    test('an unfinished video is still watchable', () {
      final a = watchActionFor(
        lesson: _lesson(),
        progress: _p(LessonStatus.inProgress),
        allowRewatch: false,
      );
      expect(a.enabled, isTrue);
      expect(a.label, 'Continue watching');
    });

    test('a fresh lesson starts', () {
      final a = watchActionFor(
        lesson: _lesson(),
        progress: _p(LessonStatus.notStarted),
        allowRewatch: false,
      );
      expect(a.enabled, isTrue);
      expect(a.label, 'Start lesson');
    });

    test('a lesson with no video is never enabled', () {
      final a = watchActionFor(
        lesson: _lesson(videoUrl: ''),
        progress: _p(LessonStatus.notStarted),
        allowRewatch: false,
      );
      expect(a.enabled, isFalse);
    });
  });

  group('watch action, rewatch enabled', () {
    test('a finished video offers a rewatch that restarts it', () {
      final a = watchActionFor(
        lesson: _lesson(),
        progress: _p(LessonStatus.completed, videoCompleted: true),
        allowRewatch: true,
      );
      expect(a.enabled, isTrue);
      expect(a.rewatch, isTrue);
      expect(a.label, 'Rewatch video');
    });

    test('an unfinished video resumes rather than rewatching', () {
      final a = watchActionFor(
        lesson: _lesson(),
        progress: _p(LessonStatus.inProgress),
        allowRewatch: true,
      );
      expect(a.rewatch, isFalse);
      expect(a.label, 'Continue watching');
    });

    test('a missing video is still not watchable', () {
      final a = watchActionFor(
        lesson: _lesson(videoUrl: ''),
        progress: _p(LessonStatus.completed, videoCompleted: true),
        allowRewatch: true,
      );
      expect(a.enabled, isFalse);
      expect(a.rewatch, isFalse);
    });
  });

  test('the feature is now enabled (phase 4)', () {
    expect(kAllowRewatch, isTrue);
  });
}
