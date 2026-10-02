import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:signals/core/theme/app_theme.dart';
import 'package:signals/models/app_user.dart';
import 'package:signals/models/forum_post.dart';
import 'package:signals/models/lesson.dart';
import 'package:signals/models/lesson_progress.dart';
import 'package:signals/models/quiz_attempt.dart';
import 'package:signals/providers/app_providers.dart';
import 'package:signals/providers/auth_providers.dart';
import 'package:signals/providers/forum_providers.dart';
import 'package:signals/providers/lesson_providers.dart';
import 'package:signals/providers/progress_providers.dart';
import 'package:signals/screens/forum/forum_list_screen.dart';
import 'package:signals/screens/lessons/lesson_library_screen.dart';
import 'package:signals/screens/progress/progress_screen.dart';
import 'package:signals/widgets/practice_strip.dart';
import 'package:signals/screens/forum/channel_composer.dart';
import 'package:signals/screens/forum/channel_rail.dart';
import 'package:signals/widgets/screen_canopy.dart';

/// The three tabs now share the canopy treatment. These check that each one
/// actually renders at real viewport sizes — the canopy is a gradient Stack
/// with an animated painter inside it, which is exactly the shape of thing that
/// has overflowed on this project before.

final _lessons = [
  for (var i = 0; i < 5; i++)
    Lesson(
      id: 'l$i',
      title: 'Lesson $i',
      description: 'A description',
      category: i.isEven ? 'Alphabet' : 'Numbers',
      durationSeconds: 90,
      videoUrl: 'https://example.com/$i.mp4',
      order: i,
      createdAt: DateTime(2026, 9, i + 1),
    ),
];

final _attempts = [
  QuizAttempt(
    id: 'a1',
    lessonId: 'l0',
    lessonTitle: 'Lesson 0',
    category: 'Alphabet',
    score: 4,
    total: 4,
    passed: true,
    answers: const {},
    createdAt: DateTime(2026, 10, 1),
  ),
];

final _posts = [
  const ForumPost(
    id: 'p1',
    authorId: 'u2',
    authorName: 'Ada Lovelace',
    title: 'How do I sign Thursday?',
    body: 'I keep mixing it up with Tuesday.',
    topics: ['Question'],
  ),
  const ForumPost(
    id: 'p2',
    authorId: 'u3',
    authorName: 'Bo',
    title: 'Finished the alphabet',
    body: 'Took me three weeks but it stuck.',
    topics: ['General'],
    replyCount: 4,
  ),
];

late SharedPreferences _prefs;

Widget _wrap(Widget screen) => ProviderScope(
  overrides: [
    // The channel rail persists per-channel read state locally.
    sharedPreferencesProvider.overrideWithValue(_prefs),
    currentUidProvider.overrideWithValue('u1'),
    appUserProvider.overrideWith(
      (ref) => Stream.value(
        const AppUser(
          uid: 'u1',
          email: 'sam@example.com',
          displayName: 'Sam Okafor',
          role: UserRole.learner,
        ),
      ),
    ),
    lessonsProvider.overrideWith((ref) => Stream.value(_lessons)),
    progressMapProvider.overrideWith(
      (ref) => Stream.value({
        'l0': LessonProgress(
          lessonId: 'l0',
          status: LessonStatus.completed,
          bestScorePercent: 100,
          completedAt: DateTime(2026, 10, 1),
        ),
      }),
    ),
    attemptsProvider.overrideWith((ref) => Stream.value(_attempts)),
    forumPostsProvider.overrideWith((ref) => Stream.value(_posts)),
  ],
  child: MaterialApp(theme: AppTheme.light(), home: screen),
);

Future<void> _settle(WidgetTester tester, Widget w) async {
  await tester.pumpWidget(w);
  // Canopy trails and medallion reveals never stop, so pumpAndSettle hangs.
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _prefs = await SharedPreferences.getInstance();
  });

  const sizes = <String, Size>{
    'small phone': Size(360, 640),
    'large phone': Size(430, 932),
    'tablet': Size(834, 1112),
    'desktop': Size(1440, 900),
  };

  final screens = <String, Widget Function()>{
    'library': () => const LessonLibraryScreen(),
    'progress': () => const ProgressScreen(),
    'community': () => const ForumListScreen(),
  };

  for (final screen in screens.entries) {
    group(screen.key, () {
      for (final size in sizes.entries) {
        testWidgets('lays out on a ${size.key}', (tester) async {
          tester.view.physicalSize = size.value;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          await _settle(tester, _wrap(screen.value()));
          expect(tester.takeException(), isNull);
          // Community is deliberately a chat layout rather than a canopy
          // screen — channels down the side, messages beside them.
          if (screen.key == 'community') {
            expect(find.text('All messages'), findsWidgets);
          } else {
            expect(find.byType(ScreenCanopy), findsOneWidget);
          }
        });
      }
    });
  }

  testWidgets('the library canopy names the library and its count', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _settle(tester, _wrap(const LessonLibraryScreen()));
    expect(find.text('Library'), findsOneWidget);
    expect(find.textContaining('5 lessons'), findsOneWidget);
  });

  testWidgets('progress shows the practice strip with its total in words', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _settle(tester, _wrap(const ProgressScreen()));
    expect(find.byType(PracticeStrip), findsOneWidget);
    // The chart is never colour-alone: the figure is stated as text too.
    expect(find.text('Practice, last 14 days'), findsOneWidget);
  });

  testWidgets('the rail is persistent on a wide window', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _settle(tester, _wrap(const ForumListScreen()));
    expect(find.byType(ChannelRail), findsOneWidget);
    // Scoped to the rail: message cards also tag themselves with #channel.
    Finder inRail(String label) => find.descendant(
      of: find.byType(ChannelRail),
      matching: find.text(label),
    );
    expect(inRail('#general'), findsOneWidget);
    expect(inRail('#practice-tips'), findsOneWidget);
    expect(inRail('Mentions'), findsOneWidget);
  });

  testWidgets('on a phone the rail hides behind a drawer', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _settle(tester, _wrap(const ForumListScreen()));
    // Not on screen until asked for — a fixed rail would eat a third of it.
    expect(find.byType(ChannelRail), findsNothing);

    await tester.tap(find.byIcon(Icons.tag_rounded));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
    expect(find.byType(ChannelRail), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('messages read as a transcript, not a stack of cards', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _settle(tester, _wrap(const ForumListScreen()));

    // Bodies are shown in full rather than as a card's two-line preview.
    expect(find.textContaining('I keep mixing it up'), findsOneWidget);
    // Reply counts still surface; "needs an answer" does not, because most
    // chat messages are not questions awaiting one.
    expect(find.text('4 replies'), findsOneWidget);
    expect(find.text('Needs an answer'), findsNothing);
  });

  testWidgets('a channel has a composer instead of a floating button', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _settle(tester, _wrap(const ForumListScreen()));

    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byType(ChannelComposer), findsOneWidget);
    // The bar names where the message will land.
    expect(find.text('Message #general'), findsOneWidget);
  });
}
