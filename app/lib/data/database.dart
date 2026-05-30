import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/coequipiers.dart';
import 'tables/frais.dart';
import 'tables/geocode_cache.dart';
import 'tables/parametres.dart';
import 'tables/saved_destinations.dart';
import 'tables/sheets.dart';
import 'tables/stop_history.dart';
import 'tables/stops.dart';
import 'tables/tournee_membres.dart';
import 'tables/tournee_recurrences.dart';
import 'tables/tournees.dart';
import 'tables/tracking_codes.dart';
import 'tables/work_sessions.dart';

// Re-export des tables pour que les modules historiques qui faisaient
// `import 'database.dart'` puissent continuer a utiliser
// `TourneesCompanion`, `Stop`, etc. sans changer leurs imports.
export 'tables/coequipiers.dart';
export 'tables/frais.dart';
export 'tables/geocode_cache.dart';
export 'tables/parametres.dart';
export 'tables/saved_destinations.dart';
export 'tables/sheets.dart';
export 'tables/stop_history.dart';
export 'tables/stops.dart';
export 'tables/tournee_membres.dart';
export 'tables/tournee_recurrences.dart';
export 'tables/tournees.dart';
export 'tables/tracking_codes.dart';
export 'tables/work_sessions.dart';

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
    Frais,
    TrackingCodes,
    TourneeRecurrences,
    WorkSessions,
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
  int get schemaVersion => 45;

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
          if (from < 25) {
            // Sous-jalon 2.D-1c : colonne `updated_at` sur les 4 tables
            // candidates au sync cloud (tournees, stops, coequipiers,
            // saved_destinations) + triggers `AFTER UPDATE` SQLite qui
            // touchent automatiquement la colonne a chaque modification.
            //
            // Sert au pull last-write-wins : si cloud.updated_at >
            // local.updated_at on ecrase, sinon on skip.
            //
            // ════════════════════════════════════════════════════════
            // Reecriture 2026-05-19 (fix #166) suite au crash web :
            // ════════════════════════════════════════════════════════
            // L'ancienne version utilisait `m.addColumn(...)` qui
            // genere un ALTER TABLE ADD COLUMN ... DEFAULT
            // (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)).
            //
            // SQLite refuse les DEFAULT non-constants dans ADD COLUMN.
            // Sur Drift Web -> SqliteException(1) "Cannot add a column
            // with non-constant default" -> migration v25 echouait
            // silencieusement -> updated_at n'existait pas -> tous
            // les fromRow crashaient sur `data['updated_at']!`.
            //
            // Sur Android natif, sqlite3 lib avait peut-etre une
            // version plus permissive qui acceptait. Mais pour etre
            // safe partout, on utilise customStatement avec DEFAULT
            // CONSTANT 0, puis backfill via UPDATE.
            //
            // Le UPDATE backfill subsequent (avec strftime ou int)
            // est OK car strftime est autorise dans UPDATE.
            for (final t in const ['tournees', 'stops', 'coequipiers',
                'saved_destinations']) {
              try {
                await customStatement(
                  'ALTER TABLE $t ADD COLUMN updated_at INTEGER '
                  'NOT NULL DEFAULT 0',
                );
              } on Object catch (_) {
                // Colonne existe deja (rare : retry de migration ou
                // version sqlite plus permissive qui avait laisse
                // passer l'ancienne version). Swallow.
              }
              await customStatement(
                "UPDATE $t SET updated_at = strftime('%s','now') "
                'WHERE updated_at IS NULL OR updated_at = 0',
              );
            }
            await _createUpdatedAtTriggers();
          }
          if (from < 26) {
            // Sous-jalon 3.A : table locale `tournee_membres` qui
            // cache les adhesions cloud. Sert a l'UI pour distinguer
            // tournee perso vs partagee, et afficher le badge nombre
            // de coequipiers / le role owner/member.
            await m.createTable(tourneeMembres);
          }
          if (from < 27) {
            // Feature ramasses (2026-05-18) : ajout colonne `type` sur
            // stops, 'livraison' default ('livraison' = on depose un
            // colis, 'ramasse' = on en recupere un).
            await m.addColumn(stops, stops.type);
          }
          if (from < 28) {
            // Bug fix 2026-05-18 #160 : backfill stops.type.
            await customStatement(
              "UPDATE stops SET type = 'livraison' WHERE type IS NULL",
            );
          }
          if (from < 29) {
            // Bug fix 2026-05-18 #161 + bump v29 : audit complet des
            // colonnes non-nullable avec default constant ajoutees
            // par migration. Drift Web (sqlite3.wasm) n'applique PAS
            // le default aux rows existantes lors d'un ADD COLUMN.
            // Code genere Drift fait `data['col']!` -> crash si NULL.
            //
            // Couvre v12 (isTemplate), v15 (profilOrs + eviterPeages),
            // v18 (pauseeSeconds). v27/type deja fait en v28.
            //
            // Sur Android natif sqlite3 ces UPDATE sont des no-op.
            // Safe a forcer. Cf [[feedback-drift-web-default-backfill]].
            await customStatement(
              "UPDATE tournees SET is_template = 0 WHERE is_template IS NULL",
            );
            await customStatement(
              "UPDATE tournees SET profil_ors = 'driving-car' "
              'WHERE profil_ors IS NULL',
            );
            await customStatement(
              'UPDATE tournees SET eviter_peages = 0 '
              'WHERE eviter_peages IS NULL',
            );
            await customStatement(
              'UPDATE tournees SET pausee_seconds = 0 '
              'WHERE pausee_seconds IS NULL',
            );
          }
          if (from < 30) {
            // Bug fix 2026-05-18 #162 - oubli dans v29 : meme probleme
            // pour saved_destinations.is_favori, BoolColumn default
            // false ajoutee par migration v10. Si Noah a un carnet
            // d'adresses pre-v10 -> crash dans SavedDestination.fromRow
            // sur Drift Web.
            await customStatement(
              'UPDATE saved_destinations SET is_favori = 0 '
              'WHERE is_favori IS NULL',
            );
          }
          if (from < 31) {
            // (No-op : ce bloc avait tente un UPDATE sur updated_at,
            // mais sur Drift Web la colonne n'existait meme pas car
            // l'ALTER TABLE de v25 avait silencieusement echoue. Cf
            // bloc v32 ci-dessous pour la vraie correction.)
          }
          if (from < 33) {
            // Nouvelle table `frais` pour les notes de frais
            // (carburant / peages / parking / repas / autre).
            // 100% local en Phase 1. Cf tables/frais.dart pour le
            // detail des colonnes et le cas d'usage.
            await m.createTable(frais);
          }
          if (from < 34) {
            // Colonne `tracking_numbers` (TEXT JSON list nullable) sur
            // stops : numeros de codes-barres scannes pour cet arret.
            // Sert au workflow ScanColisScreen pour matcher un scan a
            // un arret existant (-> +1 colis) ou creer un nouvel arret.
            await m.addColumn(stops, stops.trackingNumbers);
          }
          if (from < 35) {
            // Colonne `telephone` (TEXT nullable) sur saved_destinations :
            // numero de tel du client pour bouton "Appeler" dans la fiche
            // carnet. Carte Trello #106.
            await m.addColumn(savedDestinations, savedDestinations.telephone);
          }
          if (from < 36) {
            // Table `tracking_codes` : codes courts (4 chars) attribues
            // a un stop pour generer un lien tracking 20 chars lisible
            // par le client final (Amazon Auneau). MVP scaffold local
            // pour l'instant : `cloud_pushed` reste false tant que
            // l'Edge Function backend n'est pas deployee. Carte #141.
            await m.createTable(trackingCodes);
          }
          if (from < 38) {
            // Table `tournee_recurrences` : recurrence automatique d'un
            // template de tournee (carte #113). L'app genere la tournee
            // au jour cible a l'ouverture (cf RecurrenceService.runDue).
            await m.createTable(tourneeRecurrences);
          }
          if (from < 39) {
            // Table `work_sessions` : pointage debut/fin de service de
            // Noah (carte #279). Une seule session ouverte a la fois
            // (gere cote WorkSessionsRepository).
            await m.createTable(workSessions);
          }
          if (from < 40) {
            // Colonne `memo_vocal` sur stops (carte #280) : memo texte
            // dicte via STT. DEFAULT NULL = compatible ADD COLUMN.
            await m.addColumn(stops, stops.memoVocal);
          }
          if (from < 41) {
            // Colonne `depose_sans_contact` sur stops (carte #287) :
            // marqueur "depose devant la porte / boite", DEFAULT false
            // constant -> compatible ADD COLUMN sur sqlite + sqlite3.wasm.
            await m.addColumn(stops, stops.deposeSansContact);
          }
          if (from < 42) {
            // Colonne `note_stationnement` sur saved_destinations
            // (carte #288). DEFAULT NULL = compatible ADD COLUMN.
            await m.addColumn(
                savedDestinations, savedDestinations.noteStationnement);
          }
          if (from < 43) {
            // Colonne `is_problematique` sur saved_destinations
            // (carte #292). DEFAULT false constant = compatible
            // ADD COLUMN sur sqlite + sqlite3.wasm.
            await m.addColumn(
                savedDestinations, savedDestinations.isProblematique);
          }
          if (from < 44) {
            // Carte #296 : contre-remboursement (COD). Colonnes
            // montant_cod (real nullable) + cod_paye (bool default false).
            await m.addColumn(stops, stops.montantCod);
            await m.addColumn(stops, stops.codPaye);
          }
          if (from < 45) {
            // Carte #301 : photo preuve obligatoire pour certains
            // clients. Colonne bool default false.
            await m.addColumn(
                savedDestinations, savedDestinations.photoObligatoire);
          }
          if (from < 37) {
            // Colonne `position_locked` (BOOL, default false) sur stops :
            // verrouille un arret a sa position courante pour qu'il ne
            // soit pas deplace par le tri rapide / l'optim VROOM / le
            // drag&drop. Carte Trello #114. DEFAULT constant (false) ->
            // compatible ADD COLUMN sur SQLite (cf note migration v32).
            await m.addColumn(stops, stops.positionLocked);
          }
          if (from < 32) {
            // ════════════════════════════════════════════════════════
            // VRAIE CAUSE TROUVEE 2026-05-19 :
            // ════════════════════════════════════════════════════════
            // La migration v25 essayait :
            //   ALTER TABLE tournees ADD COLUMN updated_at INTEGER
            //   NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP)
            //   AS INTEGER));
            //
            // SQLite refuse les DEFAULT non-constants dans ADD COLUMN.
            // Resultat sur Drift Web : SqliteException(1) "Cannot add
            // a column with non-constant default" -> migration v25
            // a echoue silencieusement -> la colonne updated_at
            // n'existe PAS sur les 4 tables -> tout fromRow crash sur
            // `data['updated_at']!`.
            //
            // Sur Android natif sqlite3 a peut-etre une version plus
            // permissive (ou throw differemment) qui a laisse passer.
            //
            // Fix : ADD COLUMN manuel avec DEFAULT CONSTANT (0), puis
            // backfill avec timestamp en seconds via UPDATE.
            // Idempotent : si la colonne existe deja (Android), le ADD
            // COLUMN throws "duplicate column name" qu'on swallow.
            final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
            const tables = ['tournees', 'stops', 'coequipiers',
                'saved_destinations'];
            for (final t in tables) {
              try {
                await customStatement(
                  'ALTER TABLE $t ADD COLUMN updated_at INTEGER '
                  'NOT NULL DEFAULT 0',
                );
              } on Object catch (_) {
                // Colonne existe deja (Android natif ou retry). OK.
              }
              await customStatement(
                'UPDATE $t SET updated_at = $nowSec '
                "WHERE updated_at IS NULL OR updated_at = 0 "
                "OR typeof(updated_at) != 'integer'",
              );
            }
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
