import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:signals/core/theme/app_theme.dart';
import 'package:signals/screens/welcome/welcome_screen.dart';

/// The landing page is the first thing a stranger sees, and it is the one
/// screen nobody signs in to reach — so a layout exception here is a blank
/// first impression with no way around it.
///
/// These guard the failure this project has actually hit before: unbounded
/// constraints blowing up at viewport widths nobody developed at.
Widget _app({bool reducedMotion = false}) => MaterialApp(
  theme: AppTheme.light(),
  darkTheme: AppTheme.dark(),
  // MaterialApp installs its own MediaQuery from the view, so one wrapped
  // around the app is thrown away. The builder runs underneath it.
  builder: reducedMotion
      ? (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        )
      : null,
  home: const WelcomeScreen(),
);

Future<void> _settle(WidgetTester tester) async {
  await tester.pumpWidget(_app());
  // The hero trail repeats forever, so pumpAndSettle would never return.
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

void main() {
  group('welcome screen', () {
    const sizes = <String, Size>{
      'small phone': Size(360, 640),
      'large phone': Size(430, 932),
      'tablet': Size(834, 1112),
      'laptop': Size(1440, 900),
      'wide desktop': Size(1920, 1080),
    };

    for (final entry in sizes.entries) {
      testWidgets('lays out on a ${entry.key} without exceptions', (
        tester,
      ) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await _settle(tester);

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('scrolls to the closing call to action', (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _settle(tester);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -4000));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }

      expect(tester.takeException(), isNull);
      expect(find.text('Start with hello'), findsOneWidget);
    });

    testWidgets('states the motto and leads with the person, not the product', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _settle(tester);

      expect(find.text('Say'), findsOneWidget);
      expect(find.text('with your hands.'), findsOneWidget);
      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('holds the hero still when the OS asks for reduced motion', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(reducedMotion: true));
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }

      expect(tester.takeException(), isNull);
      // The cycling word stops cycling: the first one stays put.
      expect(find.text('hello'), findsOneWidget);
    });
  });
}
