import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:signals/core/theme/app_theme.dart';
import 'package:signals/models/lesson.dart';
import 'package:signals/models/lesson_progress.dart';
import 'package:signals/models/progress_summary.dart';
import 'package:signals/models/question.dart';
import 'package:signals/models/quiz_attempt.dart';
import 'package:signals/widgets/common.dart';
import 'package:signals/widgets/video_frame.dart';

Lesson _lesson(String id, {String category = 'Alphabet', int order = 0}) => Lesson(
      id: id,
      title: 'Lesson $id',
      description: 'desc',
      category: category,
      durationSeconds: 60,
      videoUrl: 'https://example.com/$id.mp4',
      order: order,
    );

LessonProgress _completed(String id) => LessonProgress(
      lessonId: id,
      status: LessonStatus.completed,
      videoCompleted: true,
      quizPassed: true,
      bestScorePercent: 80,
      attemptCount: 1,
    );

Question _question({String? imageUrl}) => Question(
      id: 'q1',
      lessonId: 'l1',
      prompt: 'Which handshape?',
      options: const ['a', 'b', 'c', 'd'],
      correctIndex: 0,
      imageUrl: imageUrl,
    );

QuizAttempt _attempt(
  String lessonId, {
  required int score,
  required int total,
  String category = 'Alphabet',
  DateTime? at,
}) =>
    QuizAttempt(
      id: 'a-$lessonId-$score',
      lessonId: lessonId,
      lessonTitle: 'Lesson $lessonId',
      category: category,
      score: score,
      total: total,
      passed: total > 0 && (score / total) * 100 >= 70,
      createdAt: at ?? DateTime.now(),
    );

void main() {
  group('quiz scoring', () {
    test('counts only correct selections', () {
      const questions = [
        Question(
          id: 'q1',
          lessonId: 'l1',
          prompt: 'One?',
          options: ['a', 'b', 'c', 'd'],
          correctIndex: 2,
        ),
        Question(
          id: 'q2',
          lessonId: 'l1',
          prompt: 'Two?',
          options: ['a', 'b', 'c', 'd'],
          correctIndex: 0,
        ),
      ];
      expect(questions[0].isCorrect(2), isTrue);
      expect(questions[0].isCorrect(1), isFalse);
      expect(questions[1].correctOption, 'a');
    });
  });

  group('question image', () {
    test('is absent by default, so text-only questions are unaffected', () {
      final q = _question();
      expect(q.imageUrl, isNull);
      expect(q.hasImage, isFalse);
    });

    test('hasImage treats an empty url as no image', () {
      // An admin who attaches then removes a picture can leave '' behind; the
      // quiz must not try to render that.
      expect(_question(imageUrl: '').hasImage, isFalse);
      expect(
        _question(imageUrl: 'https://res.cloudinary.com/x/image/upload/c.jpg')
            .hasImage,
        isTrue,
      );
    });

    test('the url survives a Firestore round trip', () {
      const url = 'https://res.cloudinary.com/demo/image/upload/sign.jpg';
      expect(_question(imageUrl: url).toMap()['imageUrl'], url);
      expect(_question().toMap()['imageUrl'], isNull);
    });
  });

  group('ProgressSummary', () {
    test('is empty with no lessons and no attempts', () {
      final summary = ProgressSummary.from(
        lessons: const [],
        progress: const {},
        attempts: const [],
      );
      expect(summary.completionPercent, 0);
      expect(summary.totalLessons, 0);
      expect(summary.badges.every((b) => !b.earned), isTrue);
    });

    test('completion percentage comes from completed lesson documents', () {
      final lessons = [_lesson('l1'), _lesson('l2', order: 1), _lesson('l3', order: 2)];
      final summary = ProgressSummary.from(
        lessons: lessons,
        progress: {'l1': _completed('l1')},
        attempts: [_attempt('l1', score: 4, total: 5)],
      );
      expect(summary.completedLessons, 1);
      expect(summary.totalLessons, 3);
      expect(summary.completionPercent, 33);
    });

    test('average score uses the best attempt per lesson, not the latest', () {
      final lessons = [_lesson('l1'), _lesson('l2', order: 1)];
      final summary = ProgressSummary.from(
        lessons: lessons,
        progress: const {},
        attempts: [
          _attempt('l1', score: 5, total: 5), // 100%
          _attempt('l1', score: 1, total: 5), // 20% retry, should be ignored
          _attempt('l2', score: 3, total: 5), // 60%
        ],
      );
      // best of l1 = 100, best of l2 = 60 -> 80
      expect(summary.averageScorePercent, 80);
    });

    test('perfect runs and pass counts are derived from attempts', () {
      final summary = ProgressSummary.from(
        lessons: [_lesson('l1')],
        progress: const {},
        attempts: [
          _attempt('l1', score: 5, total: 5),
          _attempt('l1', score: 2, total: 5),
        ],
      );
      expect(summary.totalAttempts, 2);
      expect(summary.passedAttempts, 1);
      expect(summary.perfectQuizzes, 1);
    });

    test('per-category breakdown groups lessons correctly', () {
      final lessons = [
        _lesson('l1', category: 'Alphabet'),
        _lesson('l2', category: 'Alphabet', order: 1),
        _lesson('l3', category: 'Numbers', order: 2),
      ];
      final summary = ProgressSummary.from(
        lessons: lessons,
        progress: {'l1': _completed('l1')},
        attempts: [_attempt('l1', score: 4, total: 5)],
      );
      expect(summary.categories.length, 2);
      final alphabet = summary.categories.first;
      expect(alphabet.category, 'Alphabet');
      expect(alphabet.totalLessons, 2);
      expect(alphabet.completedLessons, 1);
      expect(alphabet.completionPercent, 50);
      final numbers = summary.categories.last;
      expect(numbers.hasAttempts, isFalse);
      expect(numbers.averageScorePercent, 0);
    });

    test('day streak counts consecutive days back from today', () {
      final today = DateTime.now();
      final summary = ProgressSummary.from(
        lessons: [_lesson('l1')],
        progress: const {},
        attempts: [
          _attempt('l1', score: 5, total: 5, at: today),
          _attempt('l1', score: 5, total: 5, at: today.subtract(const Duration(days: 1))),
          _attempt('l1', score: 5, total: 5, at: today.subtract(const Duration(days: 2))),
          // gap at day 3 breaks the streak
          _attempt('l1', score: 5, total: 5, at: today.subtract(const Duration(days: 4))),
        ],
      );
      expect(summary.dayStreak, 3);
    });

    test('streak is zero when the last practice was more than a day ago', () {
      final summary = ProgressSummary.from(
        lessons: [_lesson('l1')],
        progress: const {},
        attempts: [
          _attempt('l1',
              score: 5, total: 5, at: DateTime.now().subtract(const Duration(days: 5))),
        ],
      );
      expect(summary.dayStreak, 0);
    });

    test('continue lesson prefers an in-progress lesson over the next unseen one', () {
      final lessons = [_lesson('l1'), _lesson('l2', order: 1)];
      final summary = ProgressSummary.from(
        lessons: lessons,
        progress: {
          'l2': const LessonProgress(
            lessonId: 'l2',
            status: LessonStatus.inProgress,
            videoCompleted: true,
          ),
        },
        attempts: const [],
      );
      expect(summary.continueLesson?.id, 'l2');
      expect(summary.nextLesson?.id, 'l1');
    });

    test('graduate badge unlocks only when every lesson is complete', () {
      final lessons = [_lesson('l1'), _lesson('l2', order: 1)];
      var summary = ProgressSummary.from(
        lessons: lessons,
        progress: {'l1': _completed('l1')},
        attempts: const [],
      );
      expect(summary.badges.firstWhere((b) => b.id == 'graduate').earned, isFalse);

      summary = ProgressSummary.from(
        lessons: lessons,
        progress: {'l1': _completed('l1'), 'l2': _completed('l2')},
        attempts: const [],
      );
      expect(summary.badges.firstWhere((b) => b.id == 'graduate').earned, isTrue);
    });
  });

  group('VideoFrame', () {
    // Pumping inside a Column is the point: a Column hands its children
    // unbounded height, which is what let a bare AspectRatio overflow.
    Widget host(double aspectRatio, {double height = 300}) => MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                VideoFrame(
                  height: height,
                  aspectRatio: aspectRatio,
                  child: const SizedBox.expand(),
                ),
              ],
            ),
          ),
        );

    testWidgets('a portrait clip does not overflow its frame', (tester) async {
      tester.view.physicalSize = const Size(400, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(host(9 / 16));

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(VideoFrame)).height, 300);
    });

    testWidgets('keeps the same height for any aspect ratio', (tester) async {
      for (final ratio in [9 / 16, 1.0, 16 / 9, 2.35]) {
        await tester.pumpWidget(host(ratio));
        expect(
          tester.getSize(find.byType(VideoFrame)).height,
          300,
          reason: 'frame height must not follow the clip shape',
        );
      }
    });

    testWidgets('letterboxes a portrait clip instead of cropping it',
        (tester) async {
      await tester.pumpWidget(host(9 / 16, height: 320));

      // 320 tall at 9:16 leaves the video 180 wide, centred on black, rather
      // than stretching to the full frame width.
      final video = tester.getSize(find.byType(AspectRatio));
      expect(video.height, 320);
      expect(video.width, closeTo(180, 0.5));
    });
  });

  group('theme', () {
    test('light and dark both carry the custom colour extension', () {
      for (final theme in [AppTheme.light(), AppTheme.dark()]) {
        expect(theme.extension<AppColors>(), isNotNull);
        expect(theme.useMaterial3, isTrue);
      }
      expect(AppTheme.light().brightness, Brightness.light);
      expect(AppTheme.dark().brightness, Brightness.dark);
    });
  });

  group('widgets', () {
    testWidgets('StatusPill renders the status label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: StatusPill(status: LessonStatus.inProgress),
          ),
        ),
      );
      expect(find.text('In progress'), findsOneWidget);
    });

    testWidgets('lesson grid widens on a desktop-sized viewport', (tester) async {
      expect(Breakpoints.lessonColumns(390), 1);
      expect(Breakpoints.lessonColumns(800), 2);
      expect(Breakpoints.lessonColumns(1400), 3);
    });
  });
}
