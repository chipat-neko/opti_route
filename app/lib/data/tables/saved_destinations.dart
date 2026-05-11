import 'package:drift/drift.dart';

/// Carnet d'adresses local : chaque arret valide ajoute (ou rafraichit)
/// une entree ici. Sert a pre-suggerer les adresses connues quand le
/// livreur retape le nom d'un client deja livre.
///
/// 100 % local au telephone (dans la meme base SQLite que le reste).
/// Cle d'unicite logique : `nomClient` + lat/lng arrondis (pour
/// mutualiser les variantes orthographiques de l'adresse postale).
class SavedDestinations extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Nom du client / enseigne (ex: "Garage Aguilar"). Optionnel : on
  /// accepte aussi une entree adresse seule.
  TextColumn get nomClient => text().nullable()();

  /// Libelle d'adresse complet pour affichage (ex: "51 Avenue
  /// d'Orleans, 28000 Chartres").
  TextColumn get adresseDisplay => text()();

  RealColumn get lat => real()();
  RealColumn get lng => real()();

  // Composantes optionnelles (pour matcher l'autocomplete sur la rue
  // ou la ville isolement).
  TextColumn get rue => text().nullable()();
  TextColumn get codePostal => text().nullable()();
  TextColumn get ville => text().nullable()();

  IntColumn get useCount => integer().withDefault(const Constant(1))();
  DateTimeColumn get lastUsedAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get creeLe => dateTime().withDefault(currentDateAndTime)();

  /// Marqueur "favori" choisi manuellement par l'utilisateur depuis
  /// l'ecran de detail du carnet. Les favoris remontent en haut de la
  /// liste, peu importe le useCount ou lastUsedAt. Sert a epingler
  /// les clients critiques / fragiles / a soigner.
  BoolColumn get isFavori =>
      boolean().withDefault(const Constant(false))();

  /// Couleur custom choisie pour repérer ce client visuellement (le
  /// fond de la pastille bookmark dans la liste prend cette couleur).
  /// Format : nom de la couleur dans la palette ('lime', 'emerald',
  /// 'red', 'amber', 'cream', 'ink'). Null = couleur par defaut
  /// (lime ou amber selon isFavori).
  TextColumn get colorTag => text().nullable()();
}
