import 'package:flutter_test/flutter_test.dart';
import 'package:signals/router/app_router.dart';

void main() {
  group('watch route carries the rewatch intent', () {
    test('a normal watch has no rewatch flag', () {
      final url = Routes.watch('l1');
      expect(url, '/lessons/l1/watch');
      expect(Routes.isRewatch(Uri.parse(url)), isFalse);
    });

    test('a rewatch round-trips through the URL', () {
      final url = Routes.watch('l1', rewatch: true);
      expect(Routes.isRewatch(Uri.parse(url)), isTrue);
    });

    test('the lesson id survives the query string', () {
      final uri = Uri.parse(Routes.watch('abc123', rewatch: true));
      expect(uri.path, '/lessons/abc123/watch');
    });

    test('an unrelated query param does not trigger a rewatch', () {
      expect(Routes.isRewatch(Uri.parse('/lessons/l1/watch?foo=true')), isFalse);
    });
  });
}
