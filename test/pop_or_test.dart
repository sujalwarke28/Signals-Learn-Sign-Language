import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:signals/router/app_router.dart';

/// Guards the crash a learner hit by opening sign-up straight from the welcome
/// page: `go` replaces the stack, so the "Sign in" link had nothing to pop and
/// GoRouter threw "There is nothing to pop".

Widget _app(GoRouter router) => MaterialApp.router(routerConfig: router);

GoRouter _router({required String initial}) => GoRouter(
  initialLocation: initial,
  routes: [
    GoRoute(
      path: '/login',
      builder: (_, __) => const Scaffold(body: Text('login screen')),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, __) => Scaffold(
        body: Column(
          children: [
            const Text('signup screen'),
            TextButton(
              onPressed: () => context.popOr('/login'),
              child: const Text('Sign in'),
            ),
          ],
        ),
      ),
    ),
  ],
);

void main() {
  group('popOr', () {
    testWidgets('falls back when the route was opened cold', (tester) async {
      await tester.pumpWidget(_app(_router(initial: '/signup')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('login screen'), findsOneWidget);
    });

    testWidgets('still pops when there is a route underneath', (tester) async {
      final router = _router(initial: '/login');
      await tester.pumpWidget(_app(router));
      await tester.pumpAndSettle();

      router.push('/signup');
      await tester.pumpAndSettle();
      expect(find.text('signup screen'), findsOneWidget);

      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('login screen'), findsOneWidget);
    });
  });
}
