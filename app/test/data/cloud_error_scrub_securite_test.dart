import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/cloud_error_humanizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

// Tests securite "mentalite hacker" : un message d'erreur affiche a
// l'utilisateur (SnackBar / ecran Diagnostic) ne doit JAMAIS contenir un
// secret exploitable (JWT de session, Bearer token, apikey en query).
// Une capture d'ecran ou un copier-coller suffirait sinon a voler la
// session. Cf durcissement nuit 2026-06-01 (information disclosure).
void main() {
  // JWT realiste (3 segments base64url). Header/payload/signature factices.
  const fakeJwt =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
      '.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6Ik5vYWgifQ'
      '.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';

  group('scrubSecrets', () {
    test('masque un JWT seul', () {
      final r = scrubSecrets(fakeJwt);
      expect(r, '***');
      expect(r.contains('eyJ'), isFalse);
    });

    test('masque un JWT au milieu d\'un message', () {
      final r = scrubSecrets('Echec auth avec token $fakeJwt sur /rest/v1');
      expect(r.contains('eyJ'), isFalse);
      expect(r.contains('SflKxw'), isFalse);
      expect(r.contains('Echec auth'), isTrue); // contexte conserve
    });

    test('masque un en-tete Bearer', () {
      final r = scrubSecrets('Authorization: Bearer abc123DEF.ghi-_jkl');
      expect(r.contains('abc123DEF'), isFalse);
      expect(r.contains('Bearer ***'), isTrue);
    });

    test('masque apikey/access_token/refresh_token en query string', () {
      expect(
        scrubSecrets('https://x.supabase.co/rest/v1/t?apikey=SECRETKEY123'),
        isNot(contains('SECRETKEY123')),
      );
      expect(
        scrubSecrets('callback#access_token=AAbb.cc-dd_ee&type=recovery'),
        isNot(contains('AAbb.cc-dd_ee')),
      );
      expect(
        scrubSecrets('refresh_token=zzzYYYxxx111'),
        isNot(contains('zzzYYYxxx111')),
      );
    });

    test('masque PLUSIEURS secrets dans le meme message', () {
      final r = scrubSecrets(
        'token $fakeJwt et Bearer OTHERtoken99 plus apikey=KKK999',
      );
      expect(r.contains('eyJ'), isFalse);
      expect(r.contains('OTHERtoken99'), isFalse);
      expect(r.contains('KKK999'), isFalse);
    });

    test('message sans secret -> inchange (pas de faux positif)', () {
      const msg = 'Pas de connexion internet (verifie wifi/4G).';
      expect(scrubSecrets(msg), msg);
    });

    test('chaine vide -> vide', () {
      expect(scrubSecrets(''), '');
    });
  });

  group('humanizeCloudError ne fuit pas de secret (fallback)', () {
    test('exception generique contenant un JWT -> JWT masque', () {
      final r = humanizeCloudError(Exception('Boom token=$fakeJwt'));
      expect(r.contains('eyJ'), isFalse);
      expect(r.contains('SflKxw'), isFalse);
    });

    test('ClientException-like avec Bearer -> masque', () {
      final r = humanizeCloudError(
        Exception('ClientException GET https://x/rest Bearer SeCreT.tok-en_99'),
      );
      expect(r.contains('SeCreT.tok-en_99'), isFalse);
    });

    test('le scrub s\'applique AVANT la troncature a 120', () {
      // 200 caracteres dont un JWT au debut : apres scrub le JWT disparait,
      // le reste reste lisible et tronque proprement <= 120.
      final r = humanizeCloudError(Exception('$fakeJwt ${'y' * 200}'));
      expect(r.contains('eyJ'), isFalse);
      expect(r.length, lessThanOrEqualTo(120));
    });
  });

  group('humanizeCloudError Postgrest message scrub', () {
    test('message Postgrest contenant un JWT -> masque', () {
      final e = PostgrestException(message: 'detail interne $fakeJwt suite');
      final r = humanizeCloudError(e);
      expect(r.contains('eyJ'), isFalse);
      expect(r.contains('detail interne'), isTrue);
    });
  });
}
