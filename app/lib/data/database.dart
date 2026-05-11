import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/geocode_cache.dart';
import 'tables/parametres.dart';
import 'tables/saved_destinations.dart';
import 'tables/sheets.dart';
import 'tables/stop_history.dart';
import 'tables/stops.dart';
import 'tables/tournees.dart';

// Re-export des tables pour que les modules historiques qui faisaient
// `import 'database.dart'` puissent continuer a utiliser
// `TourneesCompanion`, `Stop`, etc. sans changer leurs imports.
export 'tables/geocode_cache.dart';
export 'tables/parametres.dart';
export 'tables/saved_destinations.dart';
export 'tables/sheets.dart';
export 'tables/stop_history.dart';
export 'tables/stops.dart';
export 'tables/tournees.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Tournees,
    Stops,
    Parametres,
    Sheets,
    GeocodeCache,
    SavedDestinations,
    StopHistory,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'opti_route'));

  @override
  int get schemaVersion => 17;

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
          if (from < 7) {
            await m.addColumn(stops, stops.raisonEchec);
          }
          if (from < 8) {
            await m.addColumn(tournees, tournees.traceGeojson);
          }
          if (from < 9) {
            await m.addColumn(stops, stops.livreLat);
            await m.addColumn(stops, stops.livreLng);
            await m.addColumn(stops, stops.livreLe);
          }
          if (from < 10) {
            await m.addColumn(savedDestinations, savedDestinations.isFavori);
          }
          if (from < 11) {
            await m.addColumn(tournees, tournees.demareeLe);
          }
          if (from < 12) {
            await m.addColumn(tournees, tournees.isTemplate);
          }
          if (from < 13) {
            await m.addColumn(
                savedDestinations, savedDestinations.colorTag);
          }
          if (from < 14) {
            await m.createTable(stopHistory);
          }
          if (from < 15) {
            await m.addColumn(tournees, tournees.profilOrs);
            await m.addColumn(tournees, tournees.eviterPeages);
          }
          if (from < 16) {
            await m.addColumn(tournees, tournees.rappelLe);
          }
          if (from < 17) {
            await m.addColumn(
                savedDestinations, savedDestinations.notesCarnet);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
