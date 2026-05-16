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

  /// Notes pre-definies par client : code interphone, instructions
  /// fragiles, heures preferees, etc. Affichees automatiquement comme
  /// notes du prochain arret cree pour ce client (pre-remplies dans le
  /// champ Notes de `AjoutArretScreen`). L'utilisateur peut les
  /// surcharger pour cet arret precis sans modifier le carnet.
  TextColumn get notesCarnet => text().nullable()();

  /// Liste de tags libres sous forme JSON (ex: '["pro","fragile"]').
  /// Null = aucun tag. L'UI filtre par tag dans la liste du carnet.
  TextColumn get tagsJson => text().nullable()();

  /// Chemin local d'une photo de la facade / interphone (aide visuelle
  /// a la livraison). Null si pas de photo. Stockee en
  /// `app_documents/carnet/<id>_<ts>.jpg`.
  TextColumn get photoPath => text().nullable()();

  /// Code d'acces (interphone, portail) — courant et explicite.
  /// Affiche en gros dans la fiche client. Optionnel.
  TextColumn get codeAcces => text().nullable()();

  /// Etage / batiment / appartement, separe du code pour pouvoir
  /// l'afficher en gros lui aussi. Ex: "Bat C, 3e etage, app. 12".
  TextColumn get etageBatiment => text().nullable()();

  /// UUID v4 attribue par l'app au 1er push Supabase (sous-jalon 2.B).
  /// Null = entree carnet jamais sync. Voir `Tournees.cloudId` pour le
  /// pattern.
  TextColumn get cloudId => text().nullable()();

  /// Timestamp de la derniere modification locale (sous-jalon 2.D-1c).
  /// Voir `Tournees.updatedAt` pour le pattern complet.
  ///
  /// Distinct de `lastUsedAt` (qui represente le dernier usage du
  /// carnet pour l'autocomplete, mis a jour automatiquement a chaque
  /// nouvel arret creant cette adresse) — `updatedAt` ne change que
  /// quand le contenu de la fiche elle-meme est edite (notes carnet,
  /// favori, color tag, photo, etc.). Sert au last-write-wins pull.
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}
