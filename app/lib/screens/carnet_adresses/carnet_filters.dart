import '../../data/database.dart';
import '../../data/saved_destinations_repository.dart';
import '../../utils/text_normalize.dart';

/// ════════════════════════════════════════════════════════════════
/// Etat + logique de filtrage de la liste du carnet d'adresses.
/// ════════════════════════════════════════════════════════════════
///
/// Extrait de `carnet_adresses_screen.dart` (refactor F27) : les 4
/// filtres vivaient en champs separes du State et le tri se faisait
/// dans une methode privee, donc impossible a tester sans monter tout
/// l'ecran. Ici c'est du pur Dart (aucun import Flutter) :
/// [filterCarnet] et [periodeCutoff] se testent directement.

/// Combinaison des filtres appliques a la liste du carnet, hors
/// recherche texte (celle-ci vit dans le controller du champ de
/// recherche de l'ecran).
class CarnetFilters {
  const CarnetFilters({
    this.colorTag,
    this.tag,
    this.periode,
    this.regularite,
  });

  /// Aucun filtre actif : la liste montre tout le carnet.
  static const CarnetFilters none = CarnetFilters();

  /// Filtre couleur actif (`colorTag`). Null = tous. 'favoris' =
  /// uniquement les `isFavori = true` (cas special pour faciliter le
  /// tri).
  final String? colorTag;

  /// Filtre tag libre (`tagsJson`). Null = aucun filtre tag.
  final String? tag;

  /// Filtre periode d'ajout (`creeLe`). Null = pas de filtre.
  /// '30d' = derniers 30 jours, '6m' = derniers 6 mois, '1y' = derniere
  /// annee. Carte Trello #105.
  final String? periode;

  /// Filtre regularite (`useCount`). Null = pas de filtre.
  /// 'reguliers' = useCount >= 5, 'uniques' = useCount == 1.
  /// Carte Trello #105.
  final String? regularite;

  /// Compte les filtres actifs hors recherche texte (utilise pour le
  /// badge "X filtres actifs"). Carte Trello #105.
  int get activeCount {
    var n = 0;
    if (colorTag != null) n++;
    if (tag != null) n++;
    if (periode != null) n++;
    if (regularite != null) n++;
    return n;
  }

  // Quatre `withXxx` plutot qu'un `copyWith` : avec des champs
  // nullables, `copyWith(colorTag: null)` ne saurait pas distinguer
  // "remets a null" de "n'y touche pas". Chaque methode ci-dessous
  // ecrit explicitement le seul champ qu'elle nomme.

  CarnetFilters withColorTag(String? value) => CarnetFilters(
        colorTag: value,
        tag: tag,
        periode: periode,
        regularite: regularite,
      );

  CarnetFilters withTag(String? value) => CarnetFilters(
        colorTag: colorTag,
        tag: value,
        periode: periode,
        regularite: regularite,
      );

  CarnetFilters withPeriode(String? value) => CarnetFilters(
        colorTag: colorTag,
        tag: tag,
        periode: value,
        regularite: regularite,
      );

  CarnetFilters withRegularite(String? value) => CarnetFilters(
        colorTag: colorTag,
        tag: tag,
        periode: periode,
        regularite: value,
      );
}

/// Borne inferieure du filtre periode.
DateTime periodeCutoff(String periode) {
  final now = DateTime.now();
  return switch (periode) {
    '30d' => now.subtract(const Duration(days: 30)),
    '6m' => now.subtract(const Duration(days: 30 * 6)),
    '1y' => now.subtract(const Duration(days: 365)),
    _ => DateTime(1970),
  };
}

/// Applique [filters] puis la recherche texte [query] a la liste
/// complete [all]. [query] est attendu deja trim + lowercase (c'est ce
/// que produit le champ de recherche) ; la comparaison passe ensuite
/// par [normalizeText] pour ignorer les accents (une recherche "luce"
/// matche une ville dont le nom porte un accent aigu).
List<SavedDestination> filterCarnet(
  List<SavedDestination> all,
  CarnetFilters filters,
  String query,
) {
  Iterable<SavedDestination> filtered = all;
  final cf = filters.colorTag;
  if (cf != null) {
    if (cf == 'favoris') {
      filtered = filtered.where((d) => d.isFavori);
    } else {
      filtered = filtered.where((d) => d.colorTag == cf);
    }
  }
  final tf = filters.tag;
  if (tf != null) {
    filtered = filtered.where((d) {
      final tags = SavedDestinationsRepository.parseTags(d.tagsJson);
      return tags.any((t) => t.toLowerCase() == tf.toLowerCase());
    });
  }
  // Carte Trello #105 : filtre periode d'ajout (creeLe).
  final pf = filters.periode;
  if (pf != null) {
    final cutoff = periodeCutoff(pf);
    filtered = filtered.where((d) => d.creeLe.isAfter(cutoff));
  }
  // Carte Trello #105 : filtre regularite (useCount).
  final rf = filters.regularite;
  if (rf == 'reguliers') {
    filtered = filtered.where((d) => d.useCount >= 5);
  } else if (rf == 'uniques') {
    filtered = filtered.where((d) => d.useCount == 1);
  }
  if (query.isEmpty) return filtered.toList();
  final norm = normalizeText(query);
  return filtered.where((d) {
    final hay = normalizeText([
      d.nomClient ?? '',
      d.adresseDisplay,
      d.ville ?? '',
      d.codePostal ?? '',
    ].join(' '));
    return hay.contains(norm);
  }).toList();
}
