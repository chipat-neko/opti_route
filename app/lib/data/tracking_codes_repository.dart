import 'dart:math';

import 'app_constants.dart';
import 'database.dart';

/// Gere les codes courts attribues aux stops pour generer des liens
/// tracking 20 chars (carte Trello #141, MVP Amazon Auneau).
///
/// Un stop a au plus 1 code. Si on demande de generer un code pour un
/// stop qui en a deja un, on retourne le code existant (idempotent).
class TrackingCodesRepository {
  TrackingCodesRepository(this._db);

  final AppDatabase _db;
  final Random _rng = Random.secure();

  /// Caracteres autorises dans un code : minuscules + chiffres.
  /// Pas de majuscules (eviter confusion casse), pas de 'l'/'1'/'0'/'o'
  /// pour la lisibilite si l'utilisateur doit retaper a la main.
  static const String _alphabet = 'abcdefghijkmnpqrstuvwxyz23456789';

  /// Recupere le code existant pour ce stop, ou null si pas encore
  /// genere.
  Future<TrackingCode?> getByStopId(int stopId) {
    return (_db.select(_db.trackingCodes)
          ..where((t) => t.stopId.equals(stopId)))
        .getSingleOrNull();
  }

  /// Genere un code unique pour ce stop. Idempotent : si un code
  /// existe deja pour ce stopId, on le retourne sans en creer un nouveau.
  ///
  /// Strategie unicite : on tire un code aleatoire et on retente si la
  /// row existe deja (collision rarissime sur 1.6M combinations).
  Future<TrackingCode> generateForStop(int stopId) async {
    final existing = await getByStopId(stopId);
    if (existing != null) return existing;

    for (var attempt = 0; attempt < 8; attempt++) {
      final code = _randomCode(kTrackingCodeLength);
      final clash = await (_db.select(_db.trackingCodes)
            ..where((t) => t.code.equals(code)))
          .getSingleOrNull();
      if (clash != null) continue;

      final id = await _db.into(_db.trackingCodes).insert(
            TrackingCodesCompanion.insert(stopId: stopId, code: code),
          );
      return (_db.select(_db.trackingCodes)..where((t) => t.id.equals(id)))
          .getSingle();
    }
    throw Exception(
      'Generation code tracking : 8 tentatives epuisees (collisions). '
      'Augmenter kTrackingCodeLength.',
    );
  }

  /// URL tracking complete pour un code donne. Forme : `https://<domaine>/<code>`.
  /// Utilise [kTrackingDomain] qui est configurable en constante.
  static String buildUrl(String code) => 'https://$kTrackingDomain/$code';

  String _randomCode(int len) {
    final buf = StringBuffer();
    for (var i = 0; i < len; i++) {
      buf.write(_alphabet[_rng.nextInt(_alphabet.length)]);
    }
    return buf.toString();
  }
}
