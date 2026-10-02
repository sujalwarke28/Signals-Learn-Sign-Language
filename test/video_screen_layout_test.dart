import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:signals/core/theme/app_theme.dart';
import 'package:signals/models/lesson.dart';
import 'package:signals/models/lesson_progress.dart';
import 'package:signals/providers/auth_providers.dart';
import 'package:signals/providers/lesson_providers.dart';
import 'package:signals/providers/progress_providers.dart';
import 'package:signals/screens/lessons/video_lesson_screen.dart';

final _lesson = Lesson(
  id: 'l1',
  title: 'ABCDE!!!',
  description: 'd',
  category: 'Alphabet',
  durationSeconds: 60,
  videoUrl: 'https://example.com/a.mp4',
  order: 0,
);

Widget _app({required bool rewatch, required LessonProgress progress}) {
  return ProviderScope(
    overrides: [
      currentUidProvider.overrideWithValue('uid1'),
      lessonProvider.overrideWith((ref, id) => Stream.value(_lesson)),
      questionsProvider.overrideWith((ref, id) => Stream.value(const [])),
      progressMapProvider.overrideWith((ref) => Stream.value({'l1': progress})),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: VideoLessonScreen(lessonId: 'l1', rewatch: rewatch),
    ),
  );
}

Future<void> _pump(WidgetTester tester, Widget w) async {
  await tester.pumpWidget(w);
  // Let the post-frame callback run and the (inevitably failing) player settle.
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

void main() {
  testWidgets('the video screen lays out even when the player cannot load',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pump(
      tester,
      _app(
        rewatch: true,
        progress: LessonProgress(
          lessonId: 'l1',
          status: LessonStatus.completed,
          videoCompleted: true,
        ),
      ),
    );

    // The body must render, not just the app bar.
    expect(find.text('ABCDE!!!'), findsWidgets);
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('the video screen lays out at phone width', (tester) async {
    tester.view.physicalSize = const Size(390, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pump(
      tester,
      _app(
        rewatch: false,
        progress: LessonProgress(lessonId: 'l1', status: LessonStatus.notStarted),
      ),
    );

    expect(find.byType(Scaffold), findsOneWidget);
  });
}
