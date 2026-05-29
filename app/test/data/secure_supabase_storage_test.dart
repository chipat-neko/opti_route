import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/secure_supabase_storage.dart';

// Premier test pour SecureSupabaseLocalStorage : verifie l'usage de
// la cle "supabase_session_v1" via flutter_secure_storage (mock du
// MethodChannel "plugins.it_nomads.com/flutter_secure_storage").
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  // In-memory backing store qui simule le keystore.
  late Map<String, String> backing;

  setUp(() {
    backing = <String, String>{};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      final args = (call.arguments as Map?)?.cast<dynamic, dynamic>();
      final key = args?['key'] as String?;
      switch (call.method) {
        case 'containsKey':
          return backing.containsKey(key);
        case 'read':
          return backing[key];
        case 'write':
          backing[key!] = args!['value'] as String;
          return null;
        case 'delete':
          backing.remove(key);
          return null;
        case 'readAll':
          return Map<String, String>.from(backing);
        case 'deleteAll':
          backing.clear();
          return null;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('SecureSupabaseLocalStorage', () {
    test('initialize ne throw pas', () async {
      final s = SecureSupabaseLocalStorage();
      await s.initialize();
    });

    test('hasAccessToken : false si rien stocke', () async {
      final s = SecureSupabaseLocalStorage();
      expect(await s.hasAccessToken(), isFalse);
    });

    test('persistSession + hasAccessToken : true', () async {
      final s = SecureSupabaseLocalStorage();
      await s.persistSession('jwt.token.payload');
      expect(await s.hasAccessToken(), isTrue);
    });

    test('persistSession + accessToken : retourne la session', () async {
      final s = SecureSupabaseLocalStorage();
      await s.persistSession('jwt.token.payload');
      expect(await s.accessToken(), 'jwt.token.payload');
    });

    test('removePersistedSession efface', () async {
      final s = SecureSupabaseLocalStorage();
      await s.persistSession('x');
      await s.removePersistedSession();
      expect(await s.hasAccessToken(), isFalse);
      expect(await s.accessToken(), isNull);
    });

    test('persistSession 2x : ecrase l\'ancienne', () async {
      final s = SecureSupabaseLocalStorage();
      await s.persistSession('v1');
      await s.persistSession('v2');
      expect(await s.accessToken(), 'v2');
    });

    test('utilise la cle "supabase_session_v1" dans le keystore', () async {
      final s = SecureSupabaseLocalStorage();
      await s.persistSession('check');
      expect(
        backing.containsKey('supabase_session_v1'),
        isTrue,
        reason: 'change cette cle = re-login force pour tous les users',
      );
    });

    test('constructeur accepte une FlutterSecureStorage personnalisee',
        () async {
      // Sanity check : on peut injecter (utile pour tests futurs).
      final custom = FlutterSecureStorage();
      final s = SecureSupabaseLocalStorage(custom);
      await s.persistSession('inject');
      expect(await s.accessToken(), 'inject');
    });
  });
}
