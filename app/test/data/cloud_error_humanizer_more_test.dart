import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/cloud_error_humanizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

// Complete cloud_error_humanizer_test : strings supplementaires (no
// address, deadline exceeded, network unreachable, connection reset),
// PostgrestException via message "invalid token", FileSystemException
// sans osError, Drift / disk i/o.
void main() {
  group('humanizeCloudError — strings supplementaires', () {
    test('"no address associated" -> pas de connexion', () {
      expect(
        humanizeCloudError(Exception('No address associated with hostname')),
        contains('connexion internet'),
      );
    });

    test('"deadline exceeded" -> delai depasse', () {
      expect(
        humanizeCloudError(Exception('gRPC error: deadline exceeded')),
        contains('Delai depasse'),
      );
    });

    test('"network is unreachable" -> pas de connexion', () {
      expect(
        humanizeCloudError(Exception('Network is unreachable')),
        contains('connexion internet'),
      );
    });

    test('"connection reset" -> serveur injoignable', () {
      expect(
        humanizeCloudError(Exception('Connection reset by peer')),
        contains('Serveur Supabase'),
      );
    });
  });

  group('humanizeCloudError — Postgrest detection par message', () {
    test('PostgrestException message contient "invalid token" -> session expiree',
        () {
      const e = PostgrestException(message: 'invalid token, please re-login');
      expect(humanizeCloudError(e), contains('Session expiree'));
    });

    test('PostgrestException autre code + message court : prend le message',
        () {
      const e =
          PostgrestException(message: 'duplicate key error', code: '23505');
      expect(humanizeCloudError(e), 'duplicate key error');
    });
  });

  group('humanizeCloudError — fallback troncature', () {
    test('exception sans pattern + message > 120 chars : tronque a 117 + ...',
        () {
      final long = 'X' * 200;
      final result = humanizeCloudError(Exception(long));
      // toString d'Exception ajoute "Exception: " devant : "Exception: XXX..."
      expect(result.length, lessThanOrEqualTo(120));
      expect(result, endsWith('...'));
    });
  });

  group('humanizeAnyError — FileSystemException', () {
    test('FileSystemException sans osError -> fallback "Erreur fichier"', () {
      const e = FileSystemException('echec ecriture', '/tmp/x');
      expect(humanizeAnyError(e), contains('Erreur fichier'));
      expect(humanizeAnyError(e), contains('echec ecriture'));
    });

    test('FileSystemException avec osError "Permission denied" : msg specifique',
        () {
      const e = FileSystemException(
        'open failed',
        '/tmp/x',
        OSError('Permission denied', 13),
      );
      expect(humanizeAnyError(e), contains('Permission refusee'));
    });
  });

  group('humanizeAnyError — Drift / SQLite', () {
    test('toString contient "SqliteException" + "constraint" -> conflit',
        () {
      final e = Exception(
          'SqliteException(2067): UNIQUE constraint failed: trains.id');
      expect(humanizeAnyError(e), contains('Conflit'));
    });

    test('toString contient "drift" + "database is locked" : occupee', () {
      final e = Exception('Drift: database is locked');
      expect(humanizeAnyError(e), contains('occupee'));
    });

    test('toString contient "drift" + "disk i/o" : occupee', () {
      final e = Exception('Drift: disk I/O error');
      expect(humanizeAnyError(e), contains('occupee'));
    });

    test('toString contient "drift" mais pas constraint/disk : msg generique',
        () {
      final e = Exception('Drift: some other error');
      expect(humanizeAnyError(e), 'Erreur base de donnees locale.');
    });
  });

  group('humanizeAnyError — delegation a humanizeCloudError', () {
    test('SocketException : meme message que humanizeCloudError', () {
      final e = const SocketException('Failed host lookup');
      expect(humanizeAnyError(e), humanizeCloudError(e));
    });

    test('TimeoutException : meme message que humanizeCloudError', () {
      final e = TimeoutException('Slow');
      expect(humanizeAnyError(e), humanizeCloudError(e));
    });
  });
}
