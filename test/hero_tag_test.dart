import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression test for the blank-screen bug.
///
/// Home's "continue learning" card and the Lessons tab's card both build a Hero
/// tagged `lesson-art-<id>` for the same lesson. `StatefulShellRoute.indexedStack`
/// keeps every branch mounted at once, so both Heroes live in one subtree and
/// Flutter throws "multiple heroes that share the same tag" the moment a route
/// transition looks for them — which aborts the push and leaves a blank screen.
///
/// The router now wraps inactive branches in a disabled [HeroMode], which is the
/// only thing that prunes a subtree from the Hero scan.
const _tag = 'lesson-art-1';

Widget _branch() =>
    const Center(child: Hero(tag: _tag, child: SizedBox(width: 40, height: 40)));

Widget _shell({required bool guarded, int index = 0}) => IndexedStack(
      index: index,
      children: [
        for (var i = 0; i < 2; i++)
          if (guarded) HeroMode(enabled: i == index, child: _branch()) else _branch(),
      ],
    );

Future<void> _openDetail(WidgetTester tester, {required bool guarded}) async {
  final nav = GlobalKey<NavigatorState>();
  await tester.pumpWidget(MaterialApp(
    navigatorKey: nav,
    home: Scaffold(body: _shell(guarded: guarded)),
  ));
  await tester.pumpAndSettle();

  nav.currentState!.push(MaterialPageRoute<void>(
    builder: (_) => const Scaffold(
      body: Center(child: Hero(tag: _tag, child: SizedBox(width: 80, height: 80))),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('reproduces the bug: live shell branches collide on one hero tag',
      (tester) async {
    await _openDetail(tester, guarded: false);
    expect(tester.takeException(), isFlutterError);
  });

  testWidgets('the fix: a disabled HeroMode on inactive branches stops the collision',
      (tester) async {
    await _openDetail(tester, guarded: true);
    expect(tester.takeException(), isNull);
  });
}
