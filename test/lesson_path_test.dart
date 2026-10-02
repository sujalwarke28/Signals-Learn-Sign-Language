import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:signals/core/theme/app_theme.dart';
import 'package:signals/models/lesson.dart';
import 'package:signals/models/lesson_progress.dart';
import 'package:signals/screens/dashboard/lesson_path.dart';

/// The path does real geometry — a curve through computed points, extracted by
/// length. The counts that break that maths are 0, 1 and "more than fits", so
/// those are the ones pinned here.

Lesson _lesson(int i) => Lesson(
      id: 'l$i',
      title: 'Lesson $i',
      description: '',
      category: 'Alphabet',
      durationSeconds: 60,
      videoUrl: 'https://example.com/$i.mp4',
      order: i,
    );

Widget _app(List<Lesson> lessons, {Map<String, LessonProgress>? progress}) =>
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: LessonPath(
              lessons: lessons,
              progress: progress ?? const {},
              currentId: lessons.isEmpty ? null : lessons.first.id,
              onTap: (_) {},
            ),
          ),
        ),
      ),
    );

Future<void> _settle(WidgetTester tester, Widget w) async {
  await tester.pumpWidget(w);
  // The current node pulses forever, so pumpAndSettle would never return.
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

void main() {
  group('lesson path', () {
    testWidgets('renders nothing at all for an empty library', (tester) async {
      await _settle(tester, _app(const []));
      expect(tester.takeException(), isNull);
      // Scaffold and Material bring their own CustomPaints, so the thing to
      // assert is that the path itself takes up no room.
      expect(tester.getSize(find.byType(LessonPath)), Size.zero);
    });

    testWidgets('a single lesson draws its node without a curve to nowhere',
        (tester) async {
      // One point can't make a path; the painter must bail rather than throw.
      await _settle(tester, _app([_lesson(0)]));
      expect(tester.takeException(), isNull);
      expect(find.text('Lesson 0'), findsOneWidget);
    });

    testWidgets('every lesson gets a node', (tester) async {
      await _settle(tester, _app([for (var i = 0; i < 7; i++) _lesson(i)]));
      expect(tester.takeException(), isNull);
      for (var i = 0; i < 7; i++) {
        expect(find.text('Lesson $i'), findsOneWidget);
      }
    });

    testWidgets('completed lessons are marked done', (tester) async {
      await _settle(
        tester,
        _app(
          [for (var i = 0; i < 4; i++) _lesson(i)],
          progress: {
            'l0': LessonProgress(
              lessonId: 'l0',
              status: LessonStatus.completed,
              completedAt: DateTime(2026, 9, 1),
            ),
            'l1': LessonProgress(
              lessonId: 'l1',
              status: LessonStatus.completed,
              completedAt: DateTime(2026, 9, 2),
            ),
          },
        ),
      );
      expect(tester.takeException(), isNull);
      // Two ticks inside the nodes, plus the small done badge on each.
      expect(find.byIcon(Icons.check_rounded), findsNWidgets(2));
      expect(find.byIcon(Icons.done_rounded), findsNWidgets(2));
    });

    for (final width in const [320.0, 390.0, 760.0]) {
      testWidgets('nodes stay inside the column at ${width.toInt()}px',
          (tester) async {
        tester.view.physicalSize = Size(width, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await _settle(tester, _app([for (var i = 0; i < 5; i++) _lesson(i)]));
        expect(tester.takeException(), isNull);

        // The wave amplitude is a fraction of the width, so a node drifting
        // off-screen would mean the geometry scaled wrong rather than clipped.
        for (var i = 0; i < 5; i++) {
          final box = tester.getRect(find.text('Lesson $i'));
          expect(box.left, greaterThanOrEqualTo(-1),
              reason: 'node $i ran off the left at $width');
          expect(box.right, lessThanOrEqualTo(width + 1),
              reason: 'node $i ran off the right at $width');
        }
      });
    }
  });
}
