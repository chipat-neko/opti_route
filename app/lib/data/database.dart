import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/coequipiers.dart';
import 'tables/geocode_cache.dart';
import 'tables/parametres.dart';
import 'tables/saved_destinations.dart';
import 'tables/sheets.dart';
import 'tables/stop_history.dart';
import 'tables/stops.dart';
import 'tables/tournee_membres.dart';
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
export 'tables/tournee_membres.dart';
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
    TourneeMembres,
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
  int get schemaVersion => 26;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          // Indexes utiles aux requetes frequentes -- cf migration v22
          // ci-dessous pour les motifs et les gains de perf attendus.
          await _createPerfIndexes();
          // Triggers `AFTER UPDATE` qui maintiennent updated_at a jour
          // automatiquement -- cf migration v25 ci-dessous.
          await _createUpdatedAtTriggers();
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
          if (from < 22) {
            await _createPerfIndexes();
          }
          if (from < 23) {
            // Sous-jalon 2.B : ajout de cloud_id (UUID v4 stocke en TEXT
            // nullable) sur les 4 tables candidates au sync Supabase.
            // Null = jamais sync ; set = a deja ete push au moins une
            // fois (sert d'idempotence pour les re-push : INSERT/UPDATE).
            await m.addColumn(tournees, tournees.cloudId);
            await m.addColumn(stops, stops.cloudId);
            await m.addColumn(coequipiers, coequipiers.cloudId);
            await m.addColumn(savedDestinations, savedDestinations.cloudId);
          }
          if (from < 24) {
            // Sous-jalon 2.E : photos preuves vers Supabase Storage.
            // Colonne pour stocker le chemin dans le bucket
            // `<user_id>/<stop_uuid>.jpg` apres upload reussi.
            await m.addColumn(stops, stops.cloudPhotoPath);
          }
          if (from < 26) {
            // Sous-jalon 3.A : table locale `tournee_membres` qui
            // cache les adhesions cloud. Sert a l'UI pour distinguer
            // tournee perso vs partagee, et afficher le badge nombre
            // de coequipiers / le role owner/member.
            await m.createTable(tourneeMembres);
          }
          if (from < 25) {
            // Sous-jalon 2.D-1c : colonne `updated_at` sur les 4 tables
            // candidates au sync cloud (tournees, stops, coequipiers,
            // saved_destinations) + triggers `AFTER UPDATE` SQLite qui
            // touchent automatiquement la colonne a chaque modification.
            //
            // Sert au pull last-write-wins : si cloud.updated_at >
            // local.updated_at on ecrase, sinon on skip.
            //
            // Sur upgrade, les rows existants ont updated_at = NULL
            // (Drift ne peut pas appliquer le DEFAULT a posteriori).
            // On les backfill manuellement a now() apres l'ADD COLUMN
            // pour qu'ils participent correctement au last-write-wins
            // (sinon ils seraient toujours consideres comme "infiniment
            // anciens" et ecrases au moindre pull).
            await m.addColumn(tournees, tournees.updatedAt);
            await m.addColumn(stops, stops.updatedAt);
            await m.addColumn(coequipiers, coequipiers.updatedAt);
            await m.addColumn(
                savedDestinations, savedDestinations.updatedAt);
            await customStatement(
                "UPDATE tournees SET updated_at = strftime('%s','now') "
                'WHERE updated_at IS NULL');
            await customStatement(
                "UPDATE stops SET updated_at = strftime('%s','now') "
                'WHERE updated_at IS NULL');
            await customStatement(
                "UPDATE coequipiers SET updated_at = strftime('%s','now') "
                'WHERE updated_at IS NULL');
            await customStatement(
                "UPDATE saved_destinations SET updated_at = "
                "strftime('%s','now') WHERE updated_at IS NULL");
            await _createUpdatedAtTriggers();
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  /// Indexes pour les requetes frequentes (SQLite ne cree pas d'index
  /// auto sur les colonnes FK cote referencing). Idempotent grace au
  /// IF NOT EXISTS -- appele a la fois en onCreate (nouveau install)
  /// et en migration v22 (upgrade depuis une version anterieure).
  ///
  /// Gains attendus :
  /// - getByTournee : ~100x sur >1000 stops
  /// - stats par coequipier : ~10x si plusieurs livreurs
  /// - retry geocode hors-ligne : ~3x quand DB > 1000 stops
  /// - stats window queries (tournees.date >= since) : ~5x sur DB historique
  Future<void> _createPerfIndexes() async {
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_stops_tournee_id ON stops(tournee_id)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_stops_coequipier_id ON stops(coequipier_id)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_stops_statut_livraison ON stops(statut_livraison)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_stops_lat_null ON stops(lat) WHERE lat IS NULL');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_tournees_date ON tournees(date)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_stop_history_stop_id ON stop_history(stop_id)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_geocode_cache_expire_le ON geocode_cache(expire_le)');
  }

  /// Triggers SQLite qui maintiennent automatiquement `updated_at` a
  /// jour a chaque UPDATE (sous-jalon 2.D-1c).
  ///
  /// Pattern : `AFTER UPDATE WHEN NEW.updated_at = OLD.updated_at`.
  /// La clause WHEN evite la boucle infinie : la 2e execution (celle
  /// du trigger lui-meme) change updated_at donc la condition devient
  /// fausse et le trigger ne se re-declenche pas.
  ///
  /// Si le code Dart touche explicitement `updated_at` (ex: pull
  /// cloud qui ecrase avec le timestamp serveur), le trigger ne tire
  /// pas — c'est voulu, on veut preserver le timestamp source.
  ///
  /// Appele en onCreate (nouvelle install) et en migration v25
  /// (upgrade). Idempotent grace au `IF NOT EXISTS`.
  Future<void> _createUpdatedAtTriggers() async {
    for (final table in const [
      'tournees',
      'stops',
      'coequipiers',
      'saved_destinations',
    ]) {
      await customStatement(
        'CREATE TRIGGER IF NOT EXISTS ${table}_touch_updated_at '
        'AFTER UPDATE ON $table FOR EACH ROW '
        'WHEN NEW.updated_at = OLD.updated_at '
        'BEGIN '
        "UPDATE $table SET updated_at = strftime('%s','now') "
        'WHERE id = NEW.id; '
        'END;',
      );
    }
  }
}
