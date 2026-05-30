import 'database.dart';

/// Groupe les stops par secteur (code postal extrait de l'adresse).
/// Carte #290 : visualiser les arrets par quartier/CP AVANT l'optim
/// pour reperer une adresse aberrante / un colis hors zone.
class SectorGrouping {
  SectorGrouping._();

  static final RegExp _cpRegex = RegExp(r'\b(\d{5})\b');

  /// Map cp -> liste de stops. Stops sans CP detectable -> cle '?'.
  /// Ordre des cles : ordre d'apparition (LinkedHashMap).
  static Map<String, List<Stop>> groupByPostalCode(List<Stop> stops) {
    final out = <String, List<Stop>>{};
    for (final s in stops) {
      final cp = _extractCp(s);
      out.putIfAbsent(cp, () => <Stop>[]).add(s);
    }
    return out;
  }

  static String _extractCp(Stop s) {
    final src = '${s.adresseNormalisee ?? ''} ${s.adresseBrute}';
    final m = _cpRegex.firstMatch(src);
    return m?.group(1) ?? '?';
  }

  /// Retourne les CPs isoles = qui n'apparaissent que dans 1 seul
  /// stop. Utile pour reperer l'aberration "1 colis a 28000 alors que
  /// le reste de la tournee est a 78250".
  static List<String> isolatedCps(List<Stop> stops) {
    final grouped = groupByPostalCode(stops);
    return [
      for (final e in grouped.entries)
        if (e.key != '?' && e.value.length == 1) e.key,
    ];
  }
}
