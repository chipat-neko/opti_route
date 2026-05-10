import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

class Tournees extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nom => text().withLength(min: 1, max: 100)();
  DateTimeColumn get date => dateTime()();
  RealColumn get pointDepartLat => real()();
  RealColumn get pointDepartLng => real()();
  TextColumn get pointDepartLabel => text()();
  IntColumn get vehiculeCapaciteColis =>
      integer().withDefault(const Constant(0))();
  TextColumn get statut => text().withDefault(const Constant('brouillon'))();
  IntColumn get distanceTotaleM => integer().nullable()();
  IntColumn get dureeTotaleS => integer().nullable()();
  DateTimeColumn get optimiseeLe => dateTime().nullable()();
  DateTimeColumn get creeLe => dateTime().withDefault(currentDateAndTime)();
}

class Stops extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get tourneeId => integer()
      .references(Tournees, #id, onDelete: KeyAction.cascade)();
  TextColumn get adresseBrute => text()();
  TextColumn get adresseNormalisee => text().nullable()();
  RealColumn get lat => real().nullable()();
  RealColumn get lng => real().nullable()();
  IntColumn get nbColis => integer().withDefault(const Constant(1))();
  TextColumn get priorite => text().withDefault(const Constant('flexible'))();
  TextColumn get fenetreDebut => text().nullable()();
  TextColumn get fenetreFin => text().nullable()();
  IntColumn get dureeArretMin => integer().withDefault(const Constant(3))();
  TextColumn get notes => text().nullable()();
  TextColumn get nomClient => text().nullable()();
  TextColumn get statutLivraison =>
      text().withDefault(const Constant('a_livrer'))();
  IntColumn get ordreOptimise => integer().nullable()();
  /// Ordre choisi par l'utilisateur **a l'interieur** d'un groupe de
  /// priorite egale (obligatoire_premier ou obligatoire_dernier).
  /// 1 = livre en premier de son groupe, 2 = en deuxieme, etc.
  /// Null = pas applicable (priorite flexible / eviter).
  IntColumn get ordrePriorite => integer().nullable()();
  DateTimeColumn get creeLe => dateTime().withDefault(currentDateAndTime)();
}

class Parametres extends Table {
  TextColumn get cle => text()();
  TextColumn get valeur => text()();

  @override
  Set<Column> get primaryKey => {cle};
}

/// Une feuille d'expediteur attachee a un arret.
///
/// Cas reel : un livreur peut deposer au meme point des colis venant
/// d'expediteurs differents (Chronopost + La Poste + Colissimo). Chaque
/// expediteur a sa propre ref, son nb de colis, son poids, son contact.
/// Le design `screen-delivery.jsx` montre N feuilles empilees sous une
/// meme adresse client.
class Sheets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get stopId =>
      integer().references(Stops, #id, onDelete: KeyAction.cascade)();
  TextColumn get expediteur => text().withLength(min: 1, max: 100)();
  TextColumn get refCode => text().nullable()();
  TextColumn get nomDestinataire => text().nullable()();
  TextColumn get telephone => text().nullable()();
  IntColumn get nbColis => integer().withDefault(const Constant(1))();
  RealColumn get poidsKg => real().nullable()();
  TextColumn get statut => text().withDefault(const Constant('a_livrer'))();
  TextColumn get raisonEchec => text().nullable()();
  DateTimeColumn get creeLe => dateTime().withDefault(currentDateAndTime)();
}

/// Cache local des reponses Nominatim (et plus tard d'autres APIs).
/// Cle = la requete normalisee (ex: "14 rue foo paris").
/// `expire_le` permet d'invalider apres N jours sans avoir a tout
/// purger.
class GeocodeCache extends Table {
  TextColumn get query => text()();
  TextColumn get responseJson => text()();
  DateTimeColumn get expireLe => dateTime()();

  @override
  Set<Column> get primaryKey => {query};
}

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
}

@DriftDatabase(
  tables: [Tournees, Stops, Parametres, Sheets, GeocodeCache, SavedDestinations],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'opti_route'));

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(sheets);
          }
          if (from < 3) {
            await m.createTable(geocodeCache);
          }
          if (from < 4) {
            await m.addColumn(tournees, tournees.distanceTotaleM);
            await m.addColumn(tournees, tournees.dureeTotaleS);
            await m.addColumn(tournees, tournees.optimiseeLe);
          }
          if (from < 5) {
            await m.createTable(savedDestinations);
          }
          if (from < 6) {
            await m.addColumn(stops, stops.ordrePriorite);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
