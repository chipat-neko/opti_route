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
  /// 'reguliers' = useCount >= 5, 'uniques' = useCount <= 1 (chip
  /// "jamais reutilises"). Le compteur demarre a 1 a la creation de la
  /// fiche (1re livraison) et n'est incremente qu'aux livraisons
  /// suivantes : une fiche jamais reutilisee vaut donc 1, et 0 pour les
  /// rares fiches arrivees du cloud sans usage. Carte Trello #105.
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

/// Borne inferieure du filtre periode. [now] n'est la que pour les
/// tests (par defaut : l'instant courant).
///
/// '6m' et '1y' reculent en arithmetique CALENDAIRE. Avant, ils
/// soustrayaient 30 * 6 = 180 jours et 365 jours : 6 mois calendaires
/// font en realite 181 a 184 jours selon la periode de l'annee, et une
/// annee bissextile en fait 366. La borne tombait donc jusqu'a 4 jours
/// trop tard (trop recente), soit une fenetre d'autant plus courte que
/// ce que le libelle du chip promet. '30d' reste une vraie duree de
/// 30 jours : c'est exactement ce que son libelle annonce.
///
/// Debordement de quantieme : quand le jour n'existe pas dans le mois
/// cible, on le borne au DERNIER jour de ce mois. 31 aout - 6 mois =
/// 28 fevrier (et non le 3 mars, ce que donnerait la normalisation
/// automatique de `DateTime(2026, 2, 31)`, qui raccourcirait encore la
/// fenetre au lieu de l'elargir).
DateTime periodeCutoff(String periode, {DateTime? now}) {
  final ref = now ?? DateTime.now();
  return switch (periode) {
    '30d' => ref.subtract(const Duration(days: 30)),
    '6m' => _reculeDeMois(ref, 6),
    '1y' => _reculeDeMois(ref, 12),
    _ => DateTime(1970),
  };
}

/// Recule [mois] mois calendaires depuis [from] en gardant l'heure, avec
/// le quantieme borne au dernier jour du mois cible (cf [periodeCutoff]).
DateTime _reculeDeMois(DateTime from, int mois) {
  final total = from.year * 12 + (from.month - 1) - mois;
  final annee = total ~/ 12;
  final moisCible = total % 12 + 1;
  // Jour 0 du mois suivant = dernier jour du mois cible (28/29/30/31).
  final dernierJour = DateTime(annee, moisCible + 1, 0).day;
  return DateTime(
    annee,
    moisCible,
    from.day < dernierJour ? from.day : dernierJour,
    from.hour,
    from.minute,
    from.second,
    from.millisecond,
    from.microsecond,
  );
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
    // Chip "jamais reutilises" : useCount part a 1 des la creation de la
    // fiche, donc 1 = livre une seule fois. Le `== 1` d'origine laissait
    // echapper les fiches a 0 (jamais utilisees du tout), qui sont a
    // plus forte raison jamais reutilisees.
    filtered = filtered.where((d) => d.useCount <= 1);
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
