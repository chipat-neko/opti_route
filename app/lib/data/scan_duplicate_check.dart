import 'database.dart';

/// Detection de doublons au scan (carte #315) :
/// 1. **Re-livraison** : tracking deja livre dans les 30 derniers jours
/// 2. **Erreur stop** : code-barres scanne ne match pas le stop selectionne
class ScanDuplicateCheck {
  ScanDuplicateCheck._();

  /// Fenetre temporelle de recherche des doublons (30 jours).
  static const Duration windowDuplicate = Duration(days: 30);

  /// Cherche si [tracking] correspond a un stop livre dans les 30
  /// derniers jours. Retourne le stop existant ou null.
  static Stop? findRecentDelivered({
    required String tracking,
    required List<Stop> recentStops,
    DateTime? now,
  }) {
    final t = now ?? DateTime.now();
    final cutoff = t.subtract(windowDuplicate);
    final normalized = tracking.trim().toUpperCase();
    if (normalized.isEmpty) return null;
    for (final s in recentStops) {
      if (s.statutLivraison != 'livre') continue;
      if (s.livreLe == null || s.livreLe!.isBefore(cutoff)) continue;
      final raw = (s.trackingNumbers ?? '').toUpperCase();
      if (raw.contains(normalized)) return s;
    }
    return null;
  }

  /// Vérifie si [scannedBarcode] match le tracking attendu de
  /// [expectedStop]. Retourne :
  /// - `match` si le code est dans la liste tracking du stop
  /// - `wrongStop(otherStop)` si le code appartient à un AUTRE stop
  ///   de la tournée actuelle
  /// - `unknown` si le code n'est rattaché à aucun stop
  static ScanMatch verifyBarcode({
    required String scannedBarcode,
    required Stop expectedStop,
    required List<Stop> tourneeStops,
  }) {
    final code = scannedBarcode.trim().toUpperCase();
    if (code.isEmpty) return const ScanMatch.unknown();
    if ((expectedStop.trackingNumbers ?? '').toUpperCase().contains(code)) {
      return const ScanMatch.match();
    }
    for (final s in tourneeStops) {
      if (s.id == expectedStop.id) continue;
      if ((s.trackingNumbers ?? '').toUpperCase().contains(code)) {
        return ScanMatch.wrongStop(s);
      }
    }
    return const ScanMatch.unknown();
  }
}

/// Résultat de verifyBarcode.
class ScanMatch {
  const ScanMatch._(this.kind, [this.suggestedStop]);
  const ScanMatch.match() : this._(ScanMatchKind.match);
  const ScanMatch.unknown() : this._(ScanMatchKind.unknown);
  const ScanMatch.wrongStop(Stop s) : this._(ScanMatchKind.wrongStop, s);

  final ScanMatchKind kind;
  final Stop? suggestedStop;
}

enum ScanMatchKind { match, wrongStop, unknown }
