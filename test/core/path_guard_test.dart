import 'package:flutter_test/flutter_test.dart';
import 'package:joss_code/src/core/security/path_guard.dart';

void main() {
  group('PathGuard', () {
    test('allows paths inside workspace', () {
      const guard = PathGuard();

      expect(
        guard.isWithin(r'C:\workspace\lib\main.dart', r'C:\workspace'),
        isTrue,
      );
    });

    test('blocks path traversal outside workspace', () {
      const guard = PathGuard();

      expect(
        () => guard.safeJoin(r'C:\workspace', r'..\secret.txt'),
        throwsA(isA<Object>()),
      );
    });
  });
}
