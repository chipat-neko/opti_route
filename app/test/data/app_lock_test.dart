import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/app_lock.dart';

void main() {
  group('AppLock (#326)', () {
    test('hashPin deterministe', () {
      expect(AppLock.hashPin('1234'), AppLock.hashPin('1234'));
      expect(AppLock.hashPin('1234'), isNot(AppLock.hashPin('1235')));
      expect(AppLock.hashPin('1234').length, 64);
    });

    test('verify true / false', () {
      final h = AppLock.hashPin('123456');
      expect(AppLock.verify(pin: '123456', storedHash: h), isTrue);
      expect(AppLock.verify(pin: '654321', storedHash: h), isFalse);
    });

    test('isValidPin : 4-6 chiffres uniquement', () {
      expect(AppLock.isValidPin('1234'), isTrue);
      expect(AppLock.isValidPin('123456'), isTrue);
      expect(AppLock.isValidPin('123'), isFalse);
      expect(AppLock.isValidPin('1234567'), isFalse);
      expect(AppLock.isValidPin('12a4'), isFalse);
      expect(AppLock.isValidPin(''), isFalse);
    });

    test('verify : pin vide -> false (hash vide)', () {
      expect(
        AppLock.verify(pin: '', storedHash: AppLock.hashPin('1234')),
        isFalse,
      );
    });
  });
}
