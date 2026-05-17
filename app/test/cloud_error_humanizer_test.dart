import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/cloud_error_humanizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


void main() {
  group('humanizeCloudError - exceptions Dart typed', () {
    test('SocketException -> "Pas de connexion internet"', () {
      const e = SocketException('Failed host lookup');
      expect(humanizeCloudError(e),
          contains('Pas de connexion internet'));
    });

    test('TimeoutException -> "Delai depasse"', () {
      final e = TimeoutException('took too long', const Duration(seconds: 30));
      expect(humanizeCloudError(e), contains('Delai depasse'));
    });
  });

  group('humanizeCloudError - PostgrestException', () {
    test('code 401 -> "Session expiree"', () {
      const e = PostgrestException(message: 'JWT expired', code: '401');
      expect(humanizeCloudError(e), contains('Session expiree'));
    });

    test('code PGRST301 -> "Session expiree"', () {
      const e = PostgrestException(
          message: 'JWT invalid', code: 'PGRST301');
      expect(humanizeCloudError(e), contains('Session expiree'));
    });

    test('message "JWT expired" sans code -> "Session expiree"', () {
      const e = PostgrestException(message: 'JWT expired');
      expect(humanizeCloudError(e), contains('Session expiree'));
    });

    test('code 403 -> "Acces refuse"', () {
      const e = PostgrestException(message: 'Forbidden', code: '403');
      expect(humanizeCloudError(e), contains('Acces refuse'));
    });

    test('code 42P17 -> message specifique SQL re-jouer', () {
      const e = PostgrestException(
          message: 'infinite recursion detected', code: '42P17');
      expect(humanizeCloudError(e), contains('RLS recursive'));
    });

    test('autres codes : message texte direct (sans wrapper Postgrest)', () {
      const e = PostgrestException(
          message: 'Some other error', code: '42710');
      // On retourne le message brut, pas le toString() complet
      expect(humanizeCloudError(e), 'Some other error');
    });
  });

  group('humanizeCloudError - string matching fallback', () {
    test('ClientException("Failed host lookup") -> internet', () {
      // On wrap dans une exception generique car ClientException vient
      // de http/ qui n'est pas directement importe ici. Notre fallback
      // string-match doit detecter le pattern.
      final e = Exception('ClientException with SocketException: '
          'Failed host lookup: foo.supabase.co');
      expect(humanizeCloudError(e),
          contains('Pas de connexion internet'));
    });

    test('Exception("network is unreachable") -> internet', () {
      final e = Exception('network is unreachable');
      expect(humanizeCloudError(e),
          contains('Pas de connexion internet'));
    });

    test('Exception("timeout") -> delai depasse', () {
      final e = Exception('Operation timeout exceeded');
      expect(humanizeCloudError(e), contains('Delai depasse'));
    });

    test('Exception("connection refused") -> Supabase injoignable', () {
      final e = Exception('Connection refused by host');
      expect(humanizeCloudError(e), contains('Supabase injoignable'));
    });
  });

  group('humanizeCloudError - fallback', () {
    test('Exception inconnue : message court retourne tel quel', () {
      final e = Exception('Something weird happened');
      final result = humanizeCloudError(e);
      // Exception toString commence par "Exception: "
      expect(result, contains('Something weird happened'));
    });

    test('Exception avec message > 120 chars : tronque a 117 + "..."', () {
      final long = 'x' * 200;
      final e = Exception(long);
      final result = humanizeCloudError(e);
      expect(result.length, 120);
      expect(result.endsWith('...'), isTrue);
    });

    test('message exactement 120 chars : pas de truncation', () {
      // Exception("y" * 109) -> toString = "Exception: " + 109 = 120 chars
      final e = Exception('y' * 109);
      final result = humanizeCloudError(e);
      expect(result.length, 120);
      expect(result.endsWith('...'), isFalse);
    });
  });

  group('humanizeAnyError - extension Drift + I/O', () {
    test('FileSystemException avec OSError "No space" -> disque plein', () {
      final e = FileSystemException(
          'write failed', '/some/path', const OSError('No space left on device', 28));
      expect(humanizeAnyError(e), contains('Disque plein'));
    });

    test('FileSystemException avec OSError "Permission denied"', () {
      final e = FileSystemException(
          'write failed', '/some/path', const OSError('Permission denied', 13));
      expect(humanizeAnyError(e), contains('Permission refusee'));
    });

    test('FileSystemException sans OSError specifique -> "Erreur fichier"',
        () {
      const e = FileSystemException('unknown error', '/x');
      expect(humanizeAnyError(e), contains('Erreur fichier'));
    });

    test('Exception toString contient "SqliteException" + "constraint"', () {
      final e = Exception(
          'SqliteException(constraint failed: UNIQUE on tournees.id)');
      expect(humanizeAnyError(e), contains('Conflit dans la base locale'));
    });

    test('Exception toString contient "database is locked"', () {
      final e =
          Exception('SqliteException(database is locked) [code: 5]');
      expect(humanizeAnyError(e), contains('occupee'));
    });

    test('Exception "drift" generique -> "Erreur base de donnees locale"',
        () {
      final e = Exception('drift query failed mid-transaction');
      expect(humanizeAnyError(e), contains('base de donnees locale'));
    });

    test('humanizeAnyError delegue a humanizeCloudError pour le reste', () {
      // SocketException reste pris par humanizeCloudError via fall-through
      const e = SocketException('Failed host lookup');
      expect(humanizeAnyError(e), contains('Pas de connexion internet'));
    });
  });
}
