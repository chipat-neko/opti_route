import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/backup_service.dart';

// Tests directs de BackupException : message + toString + Exception
// implementation. Utilise indirectement par backup_service_test mais
// pas teste directement.
void main() {
  group('BackupException', () {
    test('expose message', () {
      const e = BackupException('disque plein');
      expect(e.message, 'disque plein');
    });

    test('toString : prefix + message', () {
      const e = BackupException('test msg');
      expect(e.toString(), 'BackupException: test msg');
    });

    test('implements Exception', () {
      const e = BackupException('msg');
      expect(e, isA<Exception>());
    });

    test('const constructor : identical pour memes valeurs', () {
      const a = BackupException('msg');
      const b = BackupException('msg');
      expect(identical(a, b), isTrue);
    });

    test('messages differents : pas identical', () {
      const a = BackupException('a');
      const b = BackupException('b');
      expect(identical(a, b), isFalse);
    });

    test('message vide : toString = "BackupException: "', () {
      const e = BackupException('');
      expect(e.toString(), 'BackupException: ');
    });

    test('message long : pas tronque dans toString', () {
      final msg = 'X' * 200;
      final e = BackupException(msg);
      expect(e.toString(), 'BackupException: $msg');
      expect(e.toString().length, greaterThan(200));
    });
  });
}
