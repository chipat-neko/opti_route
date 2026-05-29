import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/cloud_error_humanizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

void main() {
  group('humanizeCloudError', () {
    test('SocketException -> pas de connexion internet', () {
      expect(humanizeCloudError(const SocketException('failed')),
          contains('Pas de connexion'));
    });

    test('TimeoutException -> delai depasse', () {
      expect(
          humanizeCloudError(TimeoutException('x')), contains('Delai depasse'));
    });

    test('Postgrest 401 -> session expiree', () {
      expect(
        humanizeCloudError(PostgrestException(message: 'x', code: '401')),
        contains('Session expiree'),
      );
    });

    test('Postgrest PGRST301 -> session expiree', () {
      expect(
        humanizeCloudError(PostgrestException(message: 'x', code: 'PGRST301')),
        contains('Session expiree'),
      );
    });

    test('Postgrest message "JWT expired" -> session expiree', () {
      expect(
        humanizeCloudError(PostgrestException(message: 'JWT expired')),
        contains('Session expiree'),
      );
    });

    test('Postgrest 403 -> acces refuse (RLS)', () {
      expect(
        humanizeCloudError(PostgrestException(message: 'x', code: '403')),
        contains('Acces refuse'),
      );
    });

    test('Postgrest 42P17 -> RLS recursive', () {
      expect(
        humanizeCloudError(PostgrestException(message: 'x', code: '42P17')),
        contains('RLS recursive'),
      );
    });

    test('Postgrest autre code -> message direct (sans wrapper)', () {
      expect(
        humanizeCloudError(
            PostgrestException(message: 'colonne manquante', code: '42703')),
        'colonne manquante',
      );
    });

    test('string "Failed host lookup" -> pas de connexion', () {
      expect(humanizeCloudError(Exception('Failed host lookup: api.x')),
          contains('Pas de connexion'));
    });

    test('string "connection refused" -> serveur injoignable', () {
      expect(humanizeCloudError(Exception('Connection refused')),
          contains('injoignable'));
    });

    test('fallback court -> renvoie le toString tel quel', () {
      final e = Exception('boom');
      expect(humanizeCloudError(e), e.toString());
    });

    test('fallback long -> tronque a 120 chars avec ...', () {
      final r = humanizeCloudError(Exception('x' * 300));
      expect(r.length, 120);
      expect(r.endsWith('...'), isTrue);
    });
  });

  group('humanizeAnyError', () {
    test('FileSystemException "No space" -> disque plein', () {
      expect(
        humanizeAnyError(const FileSystemException(
            'write', '/x', OSError('No space left on device', 28))),
        contains('Disque plein'),
      );
    });

    test('FileSystemException "Permission denied" -> permission refusee', () {
      expect(
        humanizeAnyError(const FileSystemException(
            'write', '/x', OSError('Permission denied', 13))),
        contains('Permission refusee'),
      );
    });

    test('sqlite "constraint" -> conflit base locale', () {
      expect(
        humanizeAnyError(Exception('SqliteException: UNIQUE constraint failed')),
        contains('Conflit dans la base'),
      );
    });

    test('sqlite "database is locked" -> base occupee', () {
      expect(
        humanizeAnyError(Exception('SqliteException: database is locked')),
        contains('occupee'),
      );
    });

    test('delegue a humanizeCloudError pour le reste', () {
      expect(humanizeAnyError(const SocketException('x')),
          contains('Pas de connexion'));
    });
  });
}
