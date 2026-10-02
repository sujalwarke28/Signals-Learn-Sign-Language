import 'package:flutter_test/flutter_test.dart';
import 'package:signals/router/app_router.dart';

void main() {
  group('auth redirect', () {
    test('holds on the splash until auth resolves', () {
      expect(
        authRedirect(resolved: false, signedIn: false, location: Routes.home),
        Routes.splash,
      );
      // Already there: nothing to do, or the router loops on itself.
      expect(
        authRedirect(resolved: false, signedIn: false, location: Routes.splash),
        isNull,
      );
    });

    test('signing out of a signed-in screen lands on the welcome page', () {
      // The bug this guards: a learner on /home taps sign out, and the screen
      // stayed put while Firestore reported permission-denied underneath it.
      expect(
        authRedirect(resolved: true, signedIn: false, location: Routes.home),
        Routes.welcome,
      );
    });

    test('every signed-in screen bounces to welcome once signed out', () {
      for (final location in [
        Routes.home,
        Routes.lessons,
        Routes.progress,
        Routes.community,
        Routes.settings,
        Routes.addLesson,
        Routes.lesson('abc'),
        Routes.watch('abc'),
        Routes.quiz('abc'),
        Routes.results('abc'),
        Routes.post('abc'),
        Routes.newPost,
      ]) {
        expect(
          authRedirect(resolved: true, signedIn: false, location: location),
          Routes.welcome,
          reason: '$location should send a signed-out learner to welcome',
        );
      }
    });

    test('signed out, the public screens are left alone', () {
      expect(
        authRedirect(resolved: true, signedIn: false, location: Routes.welcome),
        isNull,
      );
      expect(
        authRedirect(resolved: true, signedIn: false, location: Routes.login),
        isNull,
      );
      expect(
        authRedirect(resolved: true, signedIn: false, location: Routes.signup),
        isNull,
      );
    });

    test('resolved on the splash with nobody signed in goes to welcome', () {
      // Not left on the splash: nothing is still resolving, so staying there
      // would strand the app on a spinner forever.
      expect(
        authRedirect(resolved: true, signedIn: false, location: Routes.splash),
        Routes.welcome,
      );
    });

    test('a signed-in learner is pulled off the auth screens', () {
      for (final location in [
        Routes.welcome,
        Routes.login,
        Routes.signup,
        Routes.splash,
      ]) {
        expect(
          authRedirect(resolved: true, signedIn: true, location: location),
          Routes.home,
          reason: '$location should not be shown to someone already signed in',
        );
      }
    });

    test('a signed-in learner is left where they are', () {
      for (final location in [
        Routes.home,
        Routes.lessons,
        Routes.settings,
        Routes.lesson('abc'),
        Routes.watch('abc', rewatch: true),
      ]) {
        expect(
          authRedirect(resolved: true, signedIn: true, location: location),
          isNull,
          reason: '$location should be reachable while signed in',
        );
      }
    });
  });
}
