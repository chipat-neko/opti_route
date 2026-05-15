import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Tests de [SupabaseService] sans backend Supabase reel.
///
/// On peut juste verifier le comportement quand `--dart-define` n'a
/// PAS ete fourni : la build de test n'embarque pas de credentials,
/// donc `isConfigured` doit etre false et toutes les methodes d'auth
/// doivent throw une [AuthException] explicite plutot que crasher.
void main() {
  group('SupabaseService - mode local-only (no credentials)', () {
    test('isConfigured = false sans dart-define', () {
      // Les tests CI tournent sans --dart-define=SUPABASE_URL=... donc
      // la build de test n'a pas de credentials -- comportement attendu
      // est isConfigured == false.
      expect(SupabaseService.instance.isConfigured, isFalse);
    });

    test('currentUser = null sans init', () {
      expect(SupabaseService.instance.currentUser, isNull);
    });

    test('init() est no-op et n\'execute pas si pas configure', () async {
      // Ne throw pas : on log juste un debugPrint et on continue.
      await SupabaseService.instance.init();
      expect(SupabaseService.instance.currentUser, isNull);
    });

    test('sendOtpToEmail throw AuthException explicite', () async {
      await expectLater(
        () => SupabaseService.instance.sendOtpToEmail('noah@example.com'),
        throwsA(isA<AuthException>().having(
          (e) => e.message,
          'message',
          contains('non configure'),
        )),
      );
    });

    test('verifyOtp throw AuthException explicite', () async {
      await expectLater(
        () => SupabaseService.instance.verifyOtp(
          email: 'noah@example.com',
          code: '123456',
        ),
        throwsA(isA<AuthException>().having(
          (e) => e.message,
          'message',
          contains('non configure'),
        )),
      );
    });

    test('signOut() est no-op sans crasher', () async {
      // En mode non-init, signOut ne doit rien faire (l'app n'a pas
      // de session a invalider de toute facon).
      await SupabaseService.instance.signOut();
    });
  });
}
