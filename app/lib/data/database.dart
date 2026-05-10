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

@DriftDatabase(tables: [Tournees, Stops, Parametres, Sheets, GeocodeCache])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'opti_route'));

  @override
  int get schemaVersion => 3;

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
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
