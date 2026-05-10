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

@DriftDatabase(tables: [Tournees, Stops, Parametres])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'opti_route'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
