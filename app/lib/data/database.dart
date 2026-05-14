import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/coequipiers.dart';
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
export 'tables/coequipiers.dart';
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
    Coequipiers,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(
          executor ??
              driftDatabase(
                name: 'opti_route',
                // **Obligatoire en compile Web** : sans ce param, Drift
                // throw `ArgumentError('When compiling to the web, the
                // web parameter needs to be set.')` au boot, ce qui
                // donne une page blanche sur GitHub Pages.
                //
                // Les 2 binaires sont hostes dans `web/` (cf
                // app/web/sqlite3.wasm + app/web/drift_worker.js,
                // telecharges depuis les GitHub releases de
                // simolus3/sqlite3.dart v3.3.1 et simolus3/drift v2.33.0).
                //
                // Sur native (Android/iOS), ce param est ignore -- la
                // DB SQLite vit dans `getApplicationDocumentsDirectory()`
                // via path_provider + sqlite3_flutter_libs.
                web: DriftWebOptions(
                  sqlite3Wasm: Uri.parse('sqlite3.wasm'),
                  driftWorker: Uri.parse('drift_worker.js'),
                ),
              ),
        );

  @override
  int get schemaVersion => 21;

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
          if (from < 18) {
            await m.addColumn(stops, stops.preuvePhotoPath);
            await m.addColumn(tournees, tournees.pauseeLe);
            await m.addColumn(tournees, tournees.pauseeSeconds);
          }
          if (from < 19) {
            await m.addColumn(savedDestinations, savedDestinations.tagsJson);
            await m.addColumn(savedDestinations, savedDestinations.photoPath);
            await m.addColumn(savedDestinations, savedDestinations.codeAcces);
            await m.addColumn(
                savedDestinations, savedDestinations.etageBatiment);
          }
          if (from < 20) {
            await m.createTable(coequipiers);
            await m.addColumn(stops, stops.coequipierId);
          }
          if (from < 21) {
            await m.addColumn(tournees, tournees.coequipierDefautId);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
