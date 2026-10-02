import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/quiz_attempt.dart';
import '../providers/auth_providers.dart';
import '../screens/admin/add_lesson_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/forum/forum_list_screen.dart';
import '../screens/forum/new_post_screen.dart';
import '../screens/forum/post_detail_screen.dart';
import '../screens/lessons/lesson_detail_screen.dart';
import '../screens/lessons/lesson_library_screen.dart';
import '../screens/lessons/video_lesson_screen.dart';
import '../screens/progress/progress_screen.dart';
import '../screens/quiz/quiz_screen.dart';
import '../screens/quiz/results_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/shell/app_shell.dart';
import '../screens/shell/splash_screen.dart';

class Routes {
  const Routes._();
  static const splash = '/splash';
  static const login = '/login';
  static const signup = '/signup';
  static const home = '/home';
  static const lessons = '/lessons';
  static const progress = '/progress';
  static const community = '/community';
  static const settings = '/settings';
  static const addLesson = '/admin/add-lesson';

  static String lesson(String id) => '/lessons/$id';
  /// Query parameter carrying the rewatch intent through the URL.
  static const rewatchParam = 'rewatch';

  /// [rewatch] restarts the video from the beginning instead of resuming.
  static String watch(String id, {bool rewatch = false}) {
    final base = '/lessons/$id/watch';
    return rewatch ? '$base?$rewatchParam=true' : base;
  }

  /// Reads the rewatch intent back out of a location. Pure, so the round-trip
  /// is testable without building a router.
  static bool isRewatch(Uri uri) => uri.queryParameters[rewatchParam] == 'true';
  static String quiz(String id) => '/lessons/$id/quiz';
  static String results(String id) => '/lessons/$id/results';
  static String post(String id) => '/community/$id';
  static const newPost = '/community/new';
}

/// Where the router should send a request, or null to let it through.
///
/// Pure, so the rules are unit-testable without standing up Firebase or a
/// navigator — the same reason [watchActionFor] is a free function.
String? authRedirect({
  required bool resolved,
  required bool signedIn,
  required String location,
}) {
  // Hold on the splash until we know whether anyone is signed in, so we never
  // flash the login screen at a returning user.
  if (!resolved) return location == Routes.splash ? null : Routes.splash;

  final onAuthScreen = location == Routes.login ||
      location == Routes.signup ||
      location == Routes.splash;

  // Signed out, the only places worth being are login and sign-up. The splash
  // is excluded because nothing is still resolving by this point, so sitting
  // there would strand the app on a spinner.
  if (!signedIn) {
    return onAuthScreen && location != Routes.splash ? null : Routes.login;
  }
  if (onAuthScreen) return Routes.home;
  return null;
}

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellKeys = [
  GlobalKey<NavigatorState>(debugLabel: 'home'),
  GlobalKey<NavigatorState>(debugLabel: 'lessons'),
  GlobalKey<NavigatorState>(debugLabel: 'progress'),
  GlobalKey<NavigatorState>(debugLabel: 'community'),
];

final routerProvider = Provider<GoRouter>((ref) {
  // GoRouter is built once and re-evaluates `redirect` whenever this ticks, so
  // signing in or out never tears down the router (and the navigation stack
  // with it).
  final refresh = ValueNotifier<int>(0);
  ref.listen(authStateProvider, (_, __) => refresh.value++);
  ref.listen(authResolvedProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.home,
    refreshListenable: refresh,
    debugLogDiagnostics: false,
    redirect: (context, state) => authRedirect(
      resolved: ref.read(authResolvedProvider),
      signedIn: ref.read(currentUidProvider) != null,
      location: state.matchedLocation,
    ),
    routes: [
      GoRoute(path: Routes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: Routes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: Routes.signup, builder: (_, __) => const SignupScreen()),
      GoRoute(
        path: Routes.settings,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(
        path: Routes.addLesson,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const AddLessonScreen(),
      ),

      // Full-screen flows: pushed above the bottom navigation bar on purpose,
      // so a learner watching a video or mid-quiz can't tab away by accident.
      GoRoute(
        path: '/lessons/:id/watch',
        parentNavigatorKey: _rootKey,
        builder: (_, state) => VideoLessonScreen(
          lessonId: state.pathParameters['id']!,
          rewatch: Routes.isRewatch(state.uri),
        ),
      ),
      GoRoute(
        path: '/lessons/:id/quiz',
        parentNavigatorKey: _rootKey,
        builder: (_, state) => QuizScreen(lessonId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/lessons/:id/results',
        parentNavigatorKey: _rootKey,
        builder: (_, state) => ResultsScreen(
          lessonId: state.pathParameters['id']!,
          attempt: state.extra as QuizAttempt?,
        ),
      ),

      // Not `.indexedStack`: that keeps every branch mounted at once, so the
      // Home card's Hero and the Lessons list's Hero for the same lesson share
      // a tag inside one subtree, which Flutter rejects ("multiple heroes that
      // share the same tag"). Wrapping the inactive branches in a disabled
      // HeroMode drops them from the Hero scan while keeping their state alive.
      StatefulShellRoute(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        navigatorContainerBuilder: (context, navigationShell, children) =>
            IndexedStack(
          index: navigationShell.currentIndex,
          children: [
            for (var i = 0; i < children.length; i++)
              HeroMode(
                enabled: i == navigationShell.currentIndex,
                child: children[i],
              ),
          ],
        ),
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellKeys[0],
            routes: [GoRoute(path: Routes.home, builder: (_, __) => const DashboardScreen())],
          ),
          StatefulShellBranch(
            navigatorKey: _shellKeys[1],
            routes: [
              GoRoute(
                path: Routes.lessons,
                builder: (_, __) => const LessonLibraryScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, state) =>
                        LessonDetailScreen(lessonId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellKeys[2],
            routes: [GoRoute(path: Routes.progress, builder: (_, __) => const ProgressScreen())],
          ),
          StatefulShellBranch(
            navigatorKey: _shellKeys[3],
            routes: [
              GoRoute(
                path: Routes.community,
                builder: (_, __) => const ForumListScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    parentNavigatorKey: _rootKey,
                    builder: (_, __) => const NewPostScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (_, state) =>
                        PostDetailScreen(postId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.explore_off_rounded, size: 48),
              const SizedBox(height: 16),
              Text('No screen at ${state.uri}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => context.go(Routes.home),
                child: const Text('Back to dashboard'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
});
