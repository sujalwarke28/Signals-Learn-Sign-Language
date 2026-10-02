import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:signals/core/theme/app_theme.dart';
import 'package:signals/models/app_user.dart';
import 'package:signals/models/forum_post.dart';
import 'package:signals/models/lesson.dart';
import 'package:signals/models/lesson_progress.dart';
import 'package:signals/models/quiz_attempt.dart';
import 'package:signals/providers/auth_providers.dart';
import 'package:signals/providers/forum_providers.dart';
import 'package:signals/providers/lesson_providers.dart';
import 'package:signals/providers/progress_providers.dart';
import 'package:signals/screens/dashboard/dashboard_screen.dart';
import 'package:signals/screens/dashboard/lesson_path.dart';

/// The two dashboards share a route, so the only thing keeping an admin out of
/// the learner's streak-and-badges screen (and vice versa) is the role switch.
/// These pin that down.

final _lessons = [
  Lesson(
    id: 'l1',
    title: 'The letter A',
    description: '',
    category: 'Alphabet',
    durationSeconds: 60,
    videoUrl: 'https://example.com/a.mp4',
    isPlaceholderVideo: true,
    createdAt: DateTime(2026, 9, 1),
  ),
  Lesson(
    id: 'l2',
    title: 'The letter B',
    description: '',
    category: 'Alphabet',
    durationSeconds: 60,
    videoUrl: 'https://example.com/b.mp4',
    createdAt: DateTime(2026, 9, 2),
  ),
];

AppUser _user({required bool admin}) => AppUser(
      uid: 'u1',
      email: 'sam@example.com',
      displayName: 'Sam Okafor',
      role: admin ? UserRole.admin : UserRole.learner,
    );

Widget _app({required bool admin}) => ProviderScope(
      overrides: [
        currentUidProvider.overrideWithValue('u1'),
        appUserProvider.overrideWith((ref) => Stream.value(_user(admin: admin))),
        lessonsProvider.overrideWith((ref) => Stream.value(_lessons)),
        progressMapProvider.overrideWith(
          (ref) => Stream.value(<String, LessonProgress>{}),
        ),
        attemptsProvider.overrideWith(
          (ref) => Stream.value(<QuizAttempt>[]),
        ),
        forumPostsProvider.overrideWith(
          (ref) => Stream.value(<ForumPost>[
            const ForumPost(
              id: 'p1',
              authorId: 'u2',
              authorName: 'Ada',
              title: 'How do I sign Thursday?',
              body: '',
            ),
          ]),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const DashboardScreen(),
      ),
    );

Future<void> _pump(WidgetTester tester, {required bool admin}) async {
  await tester.pumpWidget(_app(admin: admin));
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

void main() {
  group('dashboard by role', () {
    testWidgets('a learner gets the course, not the console', (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pump(tester, admin: false);

      expect(tester.takeException(), isNull);
      expect(find.text('Library console'), findsNothing);
      expect(find.text('New lesson'), findsNothing);
      // Greeted by first name, and handed one obvious next action.
      expect(find.text('Sam'), findsOneWidget);
      expect(find.text('UP NEXT'), findsOneWidget);
      expect(find.text('Start the lesson'), findsOneWidget);
      // The library is drawn as a path, not listed as category rows.
      expect(find.text('Your path'), findsOneWidget);
      expect(find.byType(LessonPath), findsOneWidget);
    });

    testWidgets('an admin gets the console, not the course', (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pump(tester, admin: true);

      expect(tester.takeException(), isNull);
      expect(find.text('Library console'), findsOneWidget);
      expect(find.text('ADMIN'), findsOneWidget);
      expect(find.text('New lesson'), findsOneWidget);
      // None of the learner's furniture should follow them in.
      expect(find.text('UP NEXT'), findsNothing);
      expect(find.text('Badges'), findsNothing);
      expect(find.text('Your path'), findsNothing);
      expect(find.byType(LessonPath), findsNothing);
      expect(find.text('Start the lesson'), findsNothing);
    });

    testWidgets('the console surfaces what a learner would trip over',
        (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pump(tester, admin: true);

      expect(find.text('Needs attention'), findsOneWidget);
      // One lesson on stand-in footage, one question with no reply.
      expect(find.text('Still using stand-in footage'), findsOneWidget);
      expect(find.textContaining('No reply yet'), findsOneWidget);
    });

    for (final size in const [Size(360, 640), Size(834, 1112), Size(1440, 900)]) {
      testWidgets('both roles lay out at ${size.width.toInt()}px wide',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await _pump(tester, admin: false);
        expect(tester.takeException(), isNull, reason: 'learner at $size');

        await _pump(tester, admin: true);
        expect(tester.takeException(), isNull, reason: 'admin at $size');
      });
    }
  });
}
