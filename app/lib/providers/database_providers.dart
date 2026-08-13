import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/coequipiers_repository.dart';
import '../data/database.dart';
import '../data/entreprise_repository.dart';
import '../data/frais_repository.dart';
import '../data/ambient_light_service.dart';
import '../data/fuel_price_service.dart';
import '../data/auto_backup_service.dart';
import '../data/eta_calculator.dart';
import '../data/local_reorder_service.dart';
import '../data/mark_livre_service.dart';
import '../data/app_role.dart';
import '../data/parametres_repository.dart';
import 'app_lifecycle_provider.dart';
import '../data/role_service.dart';
import '../data/resume_hebdo_service.dart';
import '../data/chef_carte_service.dart';
import '../data/chef_stats_service.dart';
import '../data/chef_tournees_service.dart';
import '../data/client_memory_service.dart';
import '../data/client_stats_service.dart';
import '../data/security_service.dart';
import '../data/batch_scan_commit_service.dart';
import '../data/notifications_service.dart';
import '../data/osrm_route_service.dart';
import '../data/route_metrics_auto_updater.dart';
import '../data/recurrence_service.dart';
import '../data/recurrences_repository.dart';
import '../data/saved_destinations_repository.dart';
import '../data/secure_screen_service.dart';
import '../data/stats_service.dart';
import '../data/stops_repository.dart';
import '../data/template_share_service.dart';
import '../data/tournees_repository.dart';
import '../data/unified_search_service.dart';
import '../data/work_sessions_repository.dart';
import '../theme/app_tokens.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final tourneesRepositoryProvider = Provider<TourneesRepository>((ref) {
  return TourneesRepository(ref.watch(appDatabaseProvider));
});

final stopsRepositoryProvider = Provider<StopsRepository>((ref) {
  return StopsRepository(ref.watch(appDatabaseProvider));
});

/// Repository des sessions de travail (pointage debut/fin, carte #279).
final workSessionsRepositoryProvider = Provider<WorkSessionsRepository>((ref) {
  return WorkSessionsRepository(ref.watch(appDatabaseProvider));
});

/// Session de travail en cours (null si aucune ouverte). Stream pour
/// que l'UI du toggle "Commencer / Terminer" se mette a jour en live.
final currentWorkSessionProvider =
    StreamProvider.autoDispose<WorkSession?>((ref) {
  return ref.watch(workSessionsRepositoryProvider).watchCurrent();
});

/// Client OSRM partage (singleton) pour le calcul de distance + duree
/// routieres exactes via OSM. Pas de cle API, gratuit.
final osrmRouteServiceProvider = Provider<OsrmRouteService>((ref) {
  final svc = OsrmRouteService();
  ref.onDispose(svc.close);
  return svc;
});

/// Auto-update des metrics (distance + duree) d'une tournee a chaque
/// modif de stops. Debounce 500ms pour eviter le spam OSRM quand
/// l'utilisateur reorganise plusieurs arrets rapidement.
final routeMetricsAutoUpdaterProvider =
    Provider<RouteMetricsAutoUpdater>((ref) {
  final updater = RouteMetricsAutoUpdater(
    db: ref.watch(appDatabaseProvider),
    osrm: ref.watch(osrmRouteServiceProvider),
  );
  ref.onDispose(updater.dispose);
  return updater;
});

/// Service d'export/import de templates de tournee au format JSON.
/// Use case Phase 1 (pas de cloud) : partager un template entre
/// coequipiers via WhatsApp/mail/Drive. Le destinataire recoit un
/// fichier .json qu'il importe via "Importer un template".
final templateShareServiceProvider = Provider<TemplateShareService>((ref) {
  return TemplateShareService(
    db: ref.watch(appDatabaseProvider),
    tournees: ref.watch(tourneesRepositoryProvider),
    stops: ref.watch(stopsRepositoryProvider),
  );
});

/// Service de recherche unifiee : scan en parallele tournees + stops +
/// carnet, scoring Levenshtein. Utilise par [unifiedSearchProvider]
/// et par le UnifiedSearchScreen accessible via l'icone Search des
/// AppBars principaux.
final unifiedSearchServiceProvider = Provider<UnifiedSearchService>((ref) {
  return UnifiedSearchService(ref.watch(appDatabaseProvider));
});

/// Recherche live pour une query donnee. Family pour pouvoir watcher
/// plusieurs queries en parallele si jamais (typiquement 1 a la fois
/// dans l'UI). FutureProvider car le service fait du I/O Drift.
///
/// **autoDispose** : chaque query string genere une nouvelle instance
/// de provider. Sans autoDispose, les anciennes (a chaque touche tape)
/// resteraient en cache memoire jusqu'a la mort de l'app. Avec
/// autoDispose, des qu'aucun widget ne watch plus la query "abc", elle
/// est garbage collected.
final unifiedSearchProvider = FutureProvider.autoDispose
    .family<List<SearchHit>, String>((ref, query) async {
  return ref.watch(unifiedSearchServiceProvider).search(query);
});

/// Service de re-ordonnancement LOCAL (nearest-neighbor, haversine).
/// Appele apres chaque ajout/edition/suppression d'arret pour
/// maintenir la liste pre-triee sans consommer le quota ORS. La vraie
/// optimisation VROOM reste declenchee par le bouton "Optimiser".
final localReorderServiceProvider = Provider<LocalReorderService>((ref) {
  return LocalReorderService(
    ref.watch(stopsRepositoryProvider),
    ref.watch(tourneesRepositoryProvider),
  );
});

/// Validation "arret livre" + cloture automatique de la tournee.
/// Source unique de verite partagee par la bottom sheet d'actions, le
/// swipe de ligne, les boutons 1 tap (ProchainArretCard,
/// ProximiteBanner), "Tout livrer" (StopsBulkActions) et la commande
/// vocale "livre" (VoiceCommandFab) -- cf [MarkLivreService].
final markLivreServiceProvider = Provider<MarkLivreService>((ref) {
  return MarkLivreService(
    ref.watch(stopsRepositoryProvider),
    ref.watch(tourneesRepositoryProvider),
  );
});

final savedDestinationsRepositoryProvider =
    Provider<SavedDestinationsRepository>((ref) {
  return SavedDestinationsRepository(ref.watch(appDatabaseProvider));
});

/// Repository multi-tenant (entreprises / entrepôts / memberships).
/// Carte #364 (épopée #361). Source de vérité = Supabase ; ce repo
/// lit/écrit le miroir local Drift.
final entrepriseRepositoryProvider = Provider<EntrepriseRepository>((ref) {
  return EntrepriseRepository(ref.watch(appDatabaseProvider));
});

/// Entreprises connues localement (miroir RLS-filtré du pull cloud) =
/// en pratique les entreprises du user courant. Carte #364.
final mesEntreprisesProvider =
    StreamProvider.autoDispose<List<Entreprise>>((ref) {
  return ref.watch(entrepriseRepositoryProvider).watchAllEntreprises();
});

/// Entrepôts d'une entreprise donnée (stream local réactif). Carte #364.
final entrepotsParEntrepriseProvider = StreamProvider.autoDispose
    .family<List<Entrepot>, String>((ref, entrepriseId) {
  return ref
      .watch(entrepriseRepositoryProvider)
      .watchEntrepotsForEntreprise(entrepriseId);
});

/// Flag "wizard migration carnet terminé" (carte #365). Sert au banner
/// persistant : tant que false, on propose de partager les adresses.
final carnetMigrationDoneProvider = StreamProvider.autoDispose<bool>((ref) {
  return ref.watch(parametresRepositoryProvider).watchCarnetMigrationDone();
});

/// Nombre d'adresses du carnet encore privées (sans entreprise). Carte
/// #365. Alimente le badge du banner « Tu as N adresses locales ».
final carnetPriveesCountProvider = StreamProvider.autoDispose<int>((ref) {
  return ref.watch(savedDestinationsRepositoryProvider).watchCountPrivees();
});

/// Lookup async du telephone client par nom (case-insensitive).
/// Retourne null si pas de match dans le carnet. Sert au bouton
/// "Appeler client" dans StopActionSheet (QW4 2026-05-31).
///
/// `family<String?>` : la cle est le nomClient ; null si vide.
final clientPhoneByNomProvider =
    FutureProvider.family.autoDispose<String?, String>((ref, nomClient) async {
  if (nomClient.trim().isEmpty) return null;
  final repo = ref.watch(savedDestinationsRepositoryProvider);
  final entry = await repo.findByNomClient(nomClient);
  final tel = entry?.telephone?.trim();
  return (tel == null || tel.isEmpty) ? null : tel;
});

/// Lookup async des consignes client (preferencePersonnalisee +
/// photoObligatoire) par nom. Sert au bandeau d'alerte dans
/// StopActionSheet (F5+F6 sprint immediat 2026-05-31).
///
/// Retourne null si client absent du carnet. Sinon retourne un
/// record (preference, photoObligatoire) — chaque champ peut etre
/// null/false.
final clientConsignesByNomProvider = FutureProvider.family
    .autoDispose<({String? preference, bool photoObligatoire})?, String>(
        (ref, nomClient) async {
  if (nomClient.trim().isEmpty) return null;
  final repo = ref.watch(savedDestinationsRepositoryProvider);
  final entry = await repo.findByNomClient(nomClient);
  if (entry == null) return null;
  return (
    preference: entry.preferencePersonnalisee?.trim().isEmpty ?? true
        ? null
        : entry.preferencePersonnalisee?.trim(),
    photoObligatoire: entry.photoObligatoire,
  );
});

/// Carnet complet, charge UNE seule fois et partage entre tous les
/// lookups (stream Drift -> se rafraichit auto quand le carnet change).
///
/// Avant (audit #213), chaque badge "client connu" appelait
/// `findSimilarClient` qui rechargeait tout le carnet via `getAll()` :
/// une tournee de 50 stops = 50 full-scans de la table. Ce provider
/// centralise le chargement -> 1 seul scan partage.
final carnetForMatchingProvider =
    StreamProvider<List<SavedDestination>>((ref) {
  return ref.watch(savedDestinationsRepositoryProvider).watchAll();
});

/// Recherche un client connu (entry [SavedDestinations]) qui matche un
/// nom via fuzzy nom (Levenshtein) + bonus ville. Retourne null si pas
/// de match. Utilise par le badge "client connu" dans la liste de stops
/// (carte Trello #94).
///
/// Family keyee par le NOM (et non le stopId) : deux stops du meme
/// client partagent le meme calcul. Le carnet vient du cache
/// [carnetForMatchingProvider] -> aucun rechargement par stop (#213).
final clientHistoryProvider =
    FutureProvider.autoDispose.family<SavedDestination?, String>(
        (ref, nomClient) async {
  if (nomClient.trim().isEmpty) return null;
  final all = await ref.watch(carnetForMatchingProvider.future);
  if (all.isEmpty) return null;
  // Stop n'a pas de champ ville dedie -- on se contente du match nom
  // uniquement (suffit pour distinguer un client deja livre, le bonus
  // ville sert surtout au scan bordereau).
  return ClientMemoryService.matchInList(nomClient, all);
});

final coequipiersRepositoryProvider = Provider<CoequipiersRepository>((ref) {
  return CoequipiersRepository(ref.watch(appDatabaseProvider));
});

/// Repository des notes de frais (carburant / peages / parking / repas /
/// autre). Voir `tables/frais.dart` pour le schema.
final fraisRepositoryProvider = Provider<FraisRepository>((ref) {
  return FraisRepository(ref.watch(appDatabaseProvider));
});

/// Stream des frais d'un mois donne (year, month 1-12). Famille de
/// providers pour permettre plusieurs filtres mois simultanes en cache.
final fraisByMonthProvider = StreamProvider.autoDispose
    .family<List<Frai>, (int, int)>((ref, ym) {
  final (year, month) = ym;
  return ref.watch(fraisRepositoryProvider).watchByMonth(year, month);
});

/// Coequipiers actifs (visibles dans le selecteur d'affectation).
final coequipiersActifsProvider =
    StreamProvider.autoDispose<List<Coequipier>>((ref) {
  return ref.watch(coequipiersRepositoryProvider).watchActifs();
});

/// Tous les coequipiers (actifs + archives) pour l'UI de gestion.
final coequipiersAllProvider =
    StreamProvider.autoDispose<List<Coequipier>>((ref) {
  return ref.watch(coequipiersRepositoryProvider).watchAll();
});

/// Map id->Coequipier de TOUS les coequipiers (actifs + archives) pour
/// resolution rapide depuis `stop.coequipierId` dans la liste d'arrets
/// (sans relancer une requete par row).
///
/// Important : on inclut les archives car les stops historiques peuvent
/// pointer sur un coequipier archive. Sans ca, les badges _StopRow
/// afficheraient "?" alors qu'on a l'info en base.
final coequipiersByIdProvider =
    Provider.autoDispose<Map<int, Coequipier>>((ref) {
  final list = ref.watch(coequipiersAllProvider).asData?.value ?? const [];
  return {for (final c in list) c.id: c};
});

final parametresRepositoryProvider = Provider<ParametresRepository>((ref) {
  return ParametresRepository(ref.watch(appDatabaseProvider));
});

/// Service de rôle Chauffeur/Chef (carte split 2026-05-30).
final roleServiceProvider = Provider<RoleService>((ref) {
  return RoleService(ref.watch(parametresRepositoryProvider));
});

/// Rôle courant (toggle local Paramètres). Stream pour gating UI
/// réactif. L'override serveur est appliqué quand le caller fournit
/// `serverRoleRaw` via `resolveCurrentRole` (cf RoleService).
final currentRoleProvider = StreamProvider.autoDispose<AppRole>((ref) {
  return ref.watch(roleServiceProvider).watchLocalRole();
});

/// Service de recuperation du prix moyen du carburant en temps reel
/// (API publique data.gouv.fr, sans cle). Carte Trello #39.
final fuelPriceServiceProvider = Provider<FuelPriceService>((ref) {
  final svc = FuelPriceService();
  ref.onDispose(svc.dispose);
  return svc;
});

/// Prix moyen du Diesel pour un departement donne (default "28"
/// = Eure-et-Loir, zone principale de l'utilisateur). Cache Riverpod
/// jusqu'au prochain redemarrage de l'app -- pas besoin de refetch
/// le prix toutes les 30 secondes, il bouge typiquement 1 fois par
/// jour. Retourne null si reseau down ou API en erreur (l'UI doit
/// gerer ce cas en gardant la valeur saisie manuellement).
final fuelPriceAverageProvider =
    FutureProvider.family<FuelPriceResult?, String>((ref, departement) async {
  return ref.read(fuelPriceServiceProvider).getAverageDieselPrice(
        departement: departement,
      );
});

/// Stations Diesel les plus proches d'une position GPS donnee (carte
/// Trello #39 V4). Family avec une cle composite (lat, lng) arrondie
/// au 0.01 deg (~1 km) pour eviter de re-fetch a chaque micro-deplacement
/// du livreur. Resultats triees par distance croissante, limite 5 par
/// defaut.
final nearbyDieselStationsProvider = FutureProvider.autoDispose
    .family<List<FuelStation>, (double, double)>((ref, coords) async {
  final (lat, lng) = coords;
  return ref.read(fuelPriceServiceProvider).findNearbyDieselStations(
        lat: lat,
        lng: lng,
      );
});

/// Service de sauvegarde locale periodique (cf AutoBackupService).
/// Le declenchement reel se fait depuis main.dart via
/// `maybeRunAutoBackup()` au boot (best-effort, en arriere-plan).
final autoBackupServiceProvider = Provider<AutoBackupService>((ref) {
  return AutoBackupService(ref.watch(parametresRepositoryProvider));
});

/// Service de verrouillage local (PIN + biometrie). Hash SHA-256 +
/// delegation `local_auth` au TEE Android pour la biometrie.
final securityServiceProvider = Provider<SecurityService>((ref) {
  return SecurityService(ref.watch(parametresRepositoryProvider));
});

/// Stream "verrou actif ET PIN defini". Combine `verrou_actif` + presence
/// de `pin_hash`. Sert au routeur d'app pour decider d'afficher
/// LockScreen au demarrage.
final lockEnabledStreamProvider = StreamProvider.autoDispose<bool>((ref) {
  // On reconstruit a chaque toggle du flag verrou_actif. La presence
  // du hash est verifiee a chaque emission (lecture async).
  return ref
      .watch(parametresRepositoryProvider)
      .watchVerrouActif()
      .asyncMap((flag) async {
    if (!flag) return false;
    final hash = await ref
        .read(parametresRepositoryProvider)
        .getPinHash();
    return hash != null && hash.isNotEmpty;
  });
});

/// Service FLAG_SECURE : masque l'app dans le selecteur de taches
/// Android + bloque les captures d'ecran (carte #111). No-op hors
/// Android. Const (sans etat) -- l'etat vit dans les parametres.
final secureScreenServiceProvider = Provider<SecureScreenService>((ref) {
  return const SecureScreenService();
});

/// Toggle "masquer dans le selecteur d'apps" (FLAG_SECURE, carte #111).
/// Default false. `main.dart` ecoute ce stream et applique le flag natif
/// a chaque changement (au demarrage via fireImmediately + a chaque
/// bascule du toggle dans Parametres > Securite).
final secureScreenEnabledProvider = StreamProvider<bool>((ref) {
  return ref.watch(parametresRepositoryProvider).watchSecureScreen();
});

/// Service de commit du scan batch (carte #119) : dedup + creation en
/// masse des arrets depuis un lot de bordereaux scannes.
final batchScanCommitServiceProvider =
    Provider<BatchScanCommitService>((ref) {
  return BatchScanCommitService(ref.watch(stopsRepositoryProvider));
});

/// Repository des recurrences de tournee (carte #113).
final recurrencesRepositoryProvider =
    Provider<RecurrencesRepository>((ref) {
  return RecurrencesRepository(ref.watch(appDatabaseProvider));
});

/// Recurrence active d'un template donne (pour l'UI de config). Null si
/// aucune recurrence configuree sur ce template.
final recurrenceForTemplateProvider =
    StreamProvider.family<TourneeRecurrence?, int>((ref, templateId) {
  return ref
      .watch(recurrencesRepositoryProvider)
      .watchByTemplate(templateId);
});

/// Service de generation des tournees recurrentes (carte #113). Appele
/// a l'ouverture de l'app (main.dart) via [RecurrenceService.runDue].
final recurrenceServiceProvider = Provider<RecurrenceService>((ref) {
  return RecurrenceService(
    ref.watch(recurrencesRepositoryProvider),
    ref.watch(tourneesRepositoryProvider),
    NotificationsService.instance,
  );
});

/// Service de resume hebdomadaire chef (carte Trello #101).
final resumeHebdoServiceProvider = Provider<ResumeHebdoService>((ref) {
  return ResumeHebdoService(ref.watch(appDatabaseProvider));
});

/// Resume hebdomadaire pour la semaine contenant [reference] (default
/// = maintenant). Recharge a chaque modif de tournee / stop.
final resumeHebdoProvider =
    FutureProvider.autoDispose.family<ResumeHebdo, DateTime?>((ref, reference) async {
  ref.watch(tourneesStreamProvider);
  return ref.read(resumeHebdoServiceProvider).computeWeek(
        reference: reference,
      );
});

final statsServiceProvider = Provider<StatsService>((ref) {
  return StatsService(ref.watch(appDatabaseProvider));
});

final clientStatsServiceProvider = Provider<ClientStatsService>((ref) {
  return ClientStatsService(ref.watch(appDatabaseProvider));
});

/// Stats agregees pour un client donne du carnet (livraisons, echecs,
/// derniere visite, raisons d'echec). Recalcule a chaque modif des
/// stops via le watch implicite sur tourneesStreamProvider.
final clientStatsProvider = FutureProvider.autoDispose.family<ClientStats, int>(
    (ref, savedDestinationId) async {
  ref.watch(tourneesStreamProvider);
  final repo = ref.read(savedDestinationsRepositoryProvider);
  final entry = await repo.getById(savedDestinationId);
  if (entry == null) return ClientStats.empty;
  return ref.read(clientStatsServiceProvider).computeFor(entry);
});

/// Stream du flag "onboarding deja fait". Sert au routeur d'app a
/// decider d'afficher le walkthrough ou le contenu normal.
final onboardingDoneStreamProvider = StreamProvider<bool>((ref) {
  return ref.watch(parametresRepositoryProvider).watchOnboardingDone();
});

/// Profil choisi a l'ecran "Qui es-tu ?" (carte #373). Null = pas encore
/// choisi -> HomeScreen affiche ProfilChoiceScreen une fois (apres le
/// walkthrough onboarding, avant le contenu normal).
final profilTypeProvider = StreamProvider<String?>((ref) {
  return ref.watch(parametresRepositoryProvider).watchProfilType();
});

/// Mode de theme (system / light / dark) choisi dans Parametres.
/// Watche dans MyApp pour basculer entre `theme` et `darkTheme` du
/// MaterialApp via `themeMode`.
final themeModeProvider = StreamProvider<ThemeMode>((ref) {
  return ref
      .watch(parametresRepositoryProvider)
      .watchThemeMode()
      .map((s) => switch (s) {
            'light' => ThemeMode.light,
            'dark' => ThemeMode.dark,
            _ => ThemeMode.system,
          });
});

/// Toggle "mode auto luminosite" (carte Trello #95). Default false.
final ambientLightAutoEnabledProvider = StreamProvider<bool>((ref) {
  return ref
      .watch(parametresRepositoryProvider)
      .watchAmbientLightAuto();
});

/// Stream du ThemeMode derive du capteur de luminosite ambiante. Vide
/// si le toggle est OFF ou si la plateforme ne supporte pas le capteur
/// (iOS, desktop, web). MyApp consomme ce stream pour ecraser
/// silencieusement [themeModeProvider] quand l'auto est ON.
final ambientLightThemeModeProvider = StreamProvider<ThemeMode>((ref) {
  final enabled = ref.watch(ambientLightAutoEnabledProvider).asData?.value;
  if (enabled != true) return const Stream<ThemeMode>.empty();
  if (!AmbientLightService.isSupported) {
    return const Stream<ThemeMode>.empty();
  }
  // Batterie (feat/opti-batterie) : on suspend l'ECHANTILLONNAGE du
  // capteur `light` quand l'app est en arriere-plan (ecran non visible
  // = aucun theme a ajuster), sans reconstruire ce provider. On passe
  // par un StreamController pilote via `ref.listen` (et non
  // `ref.watch`) : ainsi le stream expose reste vivant et conserve sa
  // DERNIERE valeur de theme -> aucun flash au retour au premier plan.
  final controller = StreamController<ThemeMode>();
  final svc = AmbientLightService();
  StreamSubscription<ThemeMode>? sub;

  void subscribe() {
    sub ??= svc.themeModeStream().listen(
      controller.add,
      onError: controller.addError,
    );
  }

  void unsubscribe() {
    sub?.cancel();
    sub = null;
  }

  // Etat initial selon le foreground courant (lu sans creer de
  // dependance de rebuild).
  if (ref.read(appForegroundProvider) == AppForeground.foreground) {
    subscribe();
  }
  // Transitions foreground/background SANS rebuild du provider : on
  // coupe/reprend juste la souscription au capteur.
  ref.listen<AppForeground>(appForegroundProvider, (_, next) {
    if (next == AppForeground.foreground) {
      subscribe();
    } else {
      unsubscribe();
    }
  });

  ref.onDispose(() {
    unsubscribe();
    controller.close();
  });

  return controller.stream;
});

/// ThemeMode effectivement applique. Si l'auto luminosite est ON et
/// qu'on a au moins une lecture du capteur, on overrride le choix
/// user. Sinon on tombe sur le choix user (system / light / dark).
final effectiveThemeModeProvider = Provider<ThemeMode>((ref) {
  final autoOn =
      ref.watch(ambientLightAutoEnabledProvider).asData?.value ?? false;
  if (autoOn) {
    // Le stream ambiant reste vivant meme capteur suspendu (cf
    // ambientLightThemeModeProvider) : sa derniere valeur persiste,
    // donc asData?.value suffit et il n'y a pas de flash au retour au
    // premier plan (feat/opti-batterie).
    final autoMode = ref.watch(ambientLightThemeModeProvider).asData?.value;
    if (autoMode != null) return autoMode;
  }
  return ref.watch(themeModeProvider).asData?.value ?? ThemeMode.system;
});

/// Preset de palette de couleurs choisi (lime / ocean / terracotta /
/// mono). MyApp watch ce provider et reconstruit le ThemeData a chaque
/// changement.
final themePresetProvider = StreamProvider<AppThemePreset>((ref) {
  return ref
      .watch(parametresRepositoryProvider)
      .watchThemePreset()
      .map(AppThemePreset.fromName);
});

/// Densite UI : 'normal' (defaut) ou 'large' (mode conduite, polices
/// +15%, cibles tactiles agrandies).
final densiteUiProvider = StreamProvider<String>((ref) {
  return ref.watch(parametresRepositoryProvider).watchDensiteUi();
});

/// Toggle contraste eleve : renforce bordures et textes pour lecture
/// en plein soleil.
final contrasteEleveProvider = StreamProvider<bool>((ref) {
  return ref.watch(parametresRepositoryProvider).watchContrasteEleve();
});

/// Heure du rappel veille auto au format "HH:mm", ou null si desactive.
final veilleReminderHHmmProvider = StreamProvider<String?>((ref) {
  return ref.watch(parametresRepositoryProvider).watchVeilleReminderHHmm();
});

/// Mode "chef d'equipe" : active la vue tableau de bord agregee dans
/// le drawer + l'affectation en masse depuis la liste d'arrets.
final modeChefProvider = StreamProvider<bool>((ref) {
  return ref.watch(parametresRepositoryProvider).watchModeChef();
});

/// Mode eco batterie (carte #258) : reduit la precision/frequence GPS en
/// consultation passive. Lu par `currentPositionProvider`.
final modeEcoProvider = StreamProvider<bool>((ref) {
  return ref.watch(parametresRepositoryProvider).watchModeEco();
});

/// Compteurs motivants (cumul annuel + streak sans echec). Recalcule
/// a chaque changement des tournees pour rester en sync.
final motivationStatsProvider = FutureProvider<MotivationStats>((ref) async {
  ref.watch(tourneesStreamProvider);
  return ref.read(statsServiceProvider).compteursMotivants();
});

/// Stats par coequipier sur la fenetre [days] derniers jours. Map
/// `coequipierId? -> CoequipierStats`. Cle null = Noah lui-meme.
final statsParCoequipierProvider =
    FutureProvider.family<Map<int?, CoequipierStats>, int>(
        (ref, days) async {
  ref.watch(tourneesStreamProvider);
  final since = DateTime.now().subtract(Duration(days: days));
  return ref.read(statsServiceProvider).statsParCoequipier(since: since);
});

/// Top 5 raisons d'echec sur la fenetre [days] derniers jours.
/// Recalcule a chaque modif de tournee / stop.
final topRaisonsEchecProvider =
    FutureProvider.family<List<({String raison, int n})>, int>(
        (ref, days) async {
  ref.watch(tourneesStreamProvider);
  final since = DateTime.now().subtract(Duration(days: days));
  return ref
      .read(statsServiceProvider)
      .topRaisonsEchecGlobales(since: since);
});

/// ETA estimee pour chaque stop d'une tournee donnee. Map stopId ->
/// DateTime (heure d'arrivee estimee). Recalcule en watch des stops
/// (changement d'ordre / statut) et du `tourneesStreamProvider`.
///
/// Pour eviter les recalculs a chaque frame (ETA depend de "now"), on
/// ne recompute qu'a chaque modif du flux. L'heure de depart est fixe
/// au moment du compute : si la tournee est `en_cours`, on prend now,
/// sinon `demareeLe` ou now si jamais demarre.
final etasParStopProvider =
    FutureProvider.family<Map<int, DateTime>, int>((ref, tourneeId) async {
  final tournees = ref.watch(tourneesStreamProvider).asData?.value ?? const [];
  final tournee = tournees.where((t) => t.id == tourneeId).firstOrNull;
  if (tournee == null) return const {};
  final stops =
      await ref.read(stopsRepositoryProvider).getByTournee(tourneeId);
  final startAt = tournee.statut == 'en_cours'
      ? (tournee.demareeLe ?? DateTime.now())
      : DateTime.now();
  return EtaCalculator.computeEtas(
    startAt: startAt,
    orderedStops: stops,
    dureeTotaleS: tournee.dureeTotaleS,
  );
});

/// Heure de fin de tournee estimee (carte #276). Reactif aux memes
/// dependances que [etasParStopProvider] : se recalibre a chaque
/// validation d'arret.
///
/// Retourne null si aucun stop pending OU si la tournee n'a pas
/// d'ETAs calculables (jamais demarree avec stops vides, etc).
final endOfTourProvider =
    FutureProvider.family<DateTime?, int>((ref, tourneeId) async {
  final etas = await ref.watch(etasParStopProvider(tourneeId).future);
  if (etas.isEmpty) return null;
  final stops = await ref.read(stopsRepositoryProvider).getByTournee(tourneeId);
  return EtaCalculator.computeEndOfTour(orderedStops: stops, etas: etas);
});

/// Statut "ok/early/late/none" du croisement ETA vs fenetre horaire
/// par stop (carte #276). Permet a [EtaBadge] de colorer / surcharger
/// son affichage sans connaitre le stop complet.
final etaWindowStatusProvider =
    FutureProvider.family<Map<int, EtaWindowStatus>, int>(
        (ref, tourneeId) async {
  final etas = await ref.watch(etasParStopProvider(tourneeId).future);
  if (etas.isEmpty) return const {};
  final stops = await ref.read(stopsRepositoryProvider).getByTournee(tourneeId);
  final out = <int, EtaWindowStatus>{};
  for (final s in stops) {
    final eta = etas[s.id];
    if (eta == null) continue;
    out[s.id] = EtaCalculator.crossWindow(
      eta: eta,
      fenetreDebut: s.fenetreDebut,
      fenetreFin: s.fenetreFin,
    );
  }
  return out;
});

/// Segments (distance + duree estimee) PAR STOP de la tournee. Sert
/// au badge "8 km · 15 min" affiche dans chaque [StopRow] (style
/// Spoke route planner). Watche le stream tournees pour re-calculer
/// quand l'ordre change.
final segmentsParStopProvider =
    FutureProvider.family<Map<int, SegmentInfo>, int>(
        (ref, tourneeId) async {
  final tournees =
      ref.watch(tourneesStreamProvider).asData?.value ?? const [];
  final tournee =
      tournees.where((t) => t.id == tourneeId).firstOrNull;
  if (tournee == null) return const {};
  final stops =
      await ref.read(stopsRepositoryProvider).getByTournee(tourneeId);
  return EtaCalculator.computeSegments(
    orderedStops: stops,
    depotLat: tournee.pointDepartLat,
    depotLng: tournee.pointDepartLng,
  );
});

/// Resume des distances/durees restantes d'une tournee (somme des
/// segments pour les stops non encore livres). Sert au compteur compact
/// "X km restants" dans l'AppBar de l'ecran Tournee du jour. Carte
/// Trello #93.
///
/// Retourne null si :
/// - tournee introuvable
/// - aucun stop non-livre (= tournee terminee)
/// Sinon record (meters: int, duration: Duration, countStops: int).
final distanceRestanteProvider =
    FutureProvider.family<({int meters, Duration duration, int countStops})?,
        int>((ref, tourneeId) async {
  final segments =
      await ref.watch(segmentsParStopProvider(tourneeId).future);
  if (segments.isEmpty) return null;
  final stops =
      await ref.read(stopsRepositoryProvider).getByTournee(tourneeId);
  var meters = 0;
  var duration = Duration.zero;
  var count = 0;
  for (final s in stops) {
    // Ne sommer que les stops a livrer (pas les livres ni les echecs
    // ni les ramasses deja faites). C'est ce qu'on doit "encore
    // parcourir".
    if (s.statutLivraison == 'livre' || s.statutLivraison == 'echec') {
      continue;
    }
    final seg = segments[s.id];
    if (seg == null) continue;
    meters += seg.meters;
    duration += seg.duration;
    count++;
  }
  if (count == 0) return null;
  return (meters: meters, duration: duration, countStops: count);
});

/// Compteur d'optimisations OpenRouteService consommees aujourd'hui.
/// Reset auto au passage minuit (gere dans le repo). Affiche dans
/// Parametres pour qu'on voie ou on en est par rapport au quota
/// 500/jour du plan free ORS.
///
/// autoDispose (item 16) : observe uniquement par la section ORS de
/// Parametres (ecran secondaire) -> se libere hors de cet ecran,
/// re-souscrit au retour. Aucun provider derive ne le watch.
final orsUsedTodayProvider = StreamProvider.autoDispose<int>((ref) {
  return ref.watch(parametresRepositoryProvider).watchOrsUsedToday();
});

/// Cout carburant estime (en EUR) pour une distance donnee (en metres).
/// Recalcule a chaque changement du parametre `coutCarburantLitre` ou
/// `consoLitresPar100Km` (via watchAll des parametres).
final coutCarburantProvider =
    FutureProvider.autoDispose.family<double, int>((ref, distanceMeters) async {
  return ref
      .read(parametresRepositoryProvider)
      .estimerCoutCarburant(distanceMeters: distanceMeters);
});

/// Stats cumulatives depuis [days] jours (typiquement 7, 30, 365).
/// Recalcule a chaque modif d'une tournee ou d'un stop (le stream
/// `tourneesStreamProvider` pousse, on relance le compute).
final statsProvider =
    FutureProvider.family<TourneeStats, int>((ref, days) async {
  // Sert de trigger : on watch les tournees pour invalider quand elles
  // changent (ajout, statut modifie, suppression).
  ref.watch(tourneesStreamProvider);
  final since = DateTime.now().subtract(Duration(days: days));
  return ref.read(statsServiceProvider).compute(since: since);
});

/// Snapshot tournees+stops sur la fenetre la plus large (365j). Sert de
/// source partagee aux cards "7j / 30j / 365j" du StatsScreen pour
/// n'executer **qu'une** paire de requetes Drift au lieu de 6 (2 par
/// card x 3 cards). Les TourneeStats par fenetre sont derives in-memory
/// via [StatsService.computeFromBundle].
///
/// autoDispose : recalcule ~365j de stats a chaque write DB (watch
/// `tourneesStreamProvider`). Sans consommateur (StatsScreen ferme) on
/// se libere pour ne plus recomputer a chaque write. Les deux providers
/// derives ([statsFromBundleProvider], [statsPreviousWindowProvider])
/// sont eux aussi autoDispose : keep-alive, ils garderaient ce provider
/// vif et neutraliseraient l'autoDispose.
final statsBundleProvider = FutureProvider.autoDispose<StatsBundle>((ref) async {
  ref.watch(tourneesStreamProvider);
  final since = DateTime.now().subtract(const Duration(days: 365));
  return ref.read(statsServiceProvider).computeBundle(since: since);
});

/// TourneeStats pour la fenetre [days], **derive** du
/// [statsBundleProvider] (filtrage in-memory). Remplace le calcul a
/// part par card -- 0 query Drift supplementaire.
final statsFromBundleProvider =
    Provider.autoDispose.family<AsyncValue<TourneeStats>, int>((ref, days) {
  final bundle = ref.watch(statsBundleProvider);
  return bundle.whenData((b) => StatsService.computeFromBundle(
        b,
        since: DateTime.now().subtract(Duration(days: days)),
      ));
});

/// TourneeStats pour la fenetre **precedente** de meme duree [days].
/// Ex : days=7 -> retourne stats des jours [J-14, J-7[.
/// Utilise pour comparer S vs S-1 dans StatsCard (carte Trello #99).
/// 0 query Drift, derive du bundle 365j deja en cache.
final statsPreviousWindowProvider =
    Provider.autoDispose.family<AsyncValue<TourneeStats>, int>((ref, days) {
  final bundle = ref.watch(statsBundleProvider);
  return bundle.whenData((b) {
    final now = DateTime.now();
    return StatsService.computeFromBundle(
      b,
      since: now.subtract(Duration(days: days * 2)),
      until: now.subtract(Duration(days: days)),
    );
  });
});

/// Colis livres par jour de la semaine (ISO 8601 : 1=lundi -> 7=dimanche)
/// sur la fenetre [days]. Vide si aucune tournee.
final colisParJourProvider =
    FutureProvider.family<Map<int, int>, int>((ref, days) async {
  ref.watch(tourneesStreamProvider);
  final since = DateTime.now().subtract(Duration(days: days));
  return ref.read(statsServiceProvider).colisParJourDeSemaine(since: since);
});

/// Cout carburant cumule sur la fenetre [days]. Combine la somme des
/// distances des tournees dans la fenetre x les parametres carburant
/// courants. Retourne en EUR.
final coutCarburantCumuleProvider =
    FutureProvider.family<double, int>((ref, days) async {
  ref.watch(tourneesStreamProvider);
  final since = DateTime.now().subtract(Duration(days: days));
  final stats = ref.read(statsServiceProvider);
  final dist = await stats.distanceTotaleMeters(since: since);
  if (dist == 0) return 0;
  return ref
      .read(parametresRepositoryProvider)
      .estimerCoutCarburant(distanceMeters: dist);
});

/// Stream des arrets pour une tournee donnee.
final stopsByTourneeProvider =
    StreamProvider.family<List<Stop>, int>((ref, tourneeId) {
  return ref.watch(stopsRepositoryProvider).watchByTournee(tourneeId);
});

final tourneesStreamProvider = StreamProvider<List<Tournee>>((ref) {
  return ref.watch(tourneesRepositoryProvider).watchAll();
});

/// Stream d'une tournee unique par id. Sert a [TourneeDuJourScreen]
/// (et a d'autres ecrans qui veulent re-rendre quand le statut /
/// pauseeLe / demareeLe change). Sans ce provider, l'objet
/// `widget.tournee` passe au constructeur reste immuable et l'UI
/// affiche l'ancien etat apres une action (bug 2026-05-14 sur
/// Demarrer / Pause / Reprise / Terminer).
final tourneeByIdProvider =
    StreamProvider.family<Tournee?, int>((ref, id) {
  return ref.watch(tourneesRepositoryProvider).watchById(id);
});

/// Vrai s'il existe au moins une tournee `statut == 'en_cours'` dans
/// la base, peu importe sa date. Sert a afficher un badge "tournee
/// active" sur l'icone drawer pour eviter d'oublier qu'on est en
/// mode actif quand on navigue dans d'autres ecrans.
final hasTourneeEnCoursProvider = Provider<bool>((ref) {
  final list = ref.watch(tourneesStreamProvider).asData?.value ?? const [];
  return list.any((t) => t.statut == 'en_cours');
});

/// Stream du nombre de membres d'une tournee partagee (jalon 3.B).
/// Retourne 0 si la tournee n'a jamais ete pushee au cloud OU s'il
/// n'y a aucun row dans tournee_membres pour ce tourneeCloudId.
/// Une tournee est consideree "partagee" si count >= 2 (owner + au
/// moins 1 member). count == 1 = tournee perso (owner seul).
final tourneeMembresCountProvider =
    StreamProvider.family<int, String>((ref, tourneeCloudId) {
  final db = ref.watch(appDatabaseProvider);
  final query = db.select(db.tourneeMembres)
    ..where((m) => m.tourneeCloudId.equals(tourneeCloudId));
  return query.watch().map((rows) => rows.length);
});

/// Toutes les tournees datees d'aujourd'hui (peu importe leur statut).
/// Sert a afficher un bandeau "X autres tournees aujourd'hui" quand
/// le livreur en a planifie plusieurs (matin/aprem) le meme jour.
final tourneesDuJourProvider = Provider<List<Tournee>>((ref) {
  final list = ref.watch(tourneesStreamProvider).asData?.value ?? const [];
  final today = DateTime.now();
  bool isToday(DateTime d) =>
      d.year == today.year && d.month == today.month && d.day == today.day;
  return list.where((t) => isToday(t.date)).toList();
});

/// Tournee active du jour, ou null si rien aujourd'hui.
///
/// Regles de selection :
/// 1. S'il y a une tournee `statut == 'en_cours'` (peu importe la date),
///    elle remporte (le livreur est en plein milieu).
/// 2. Sinon, parmi les tournees datees d'aujourd'hui, on prend la plus
///    avancee : optimisee > brouillon > terminee.
/// 3. Sinon, null — l'UI affichera un empty state "pas de tournee
///    aujourd'hui".
final currentTourneeProvider = Provider<AsyncValue<Tournee?>>((ref) {
  return ref.watch(tourneesStreamProvider).whenData((list) {
    final inProgress = list.where((t) => t.statut == 'en_cours');
    if (inProgress.isNotEmpty) return inProgress.first;

    final today = DateTime.now();
    bool isToday(DateTime d) =>
        d.year == today.year && d.month == today.month && d.day == today.day;

    final todayList = list.where((t) => isToday(t.date)).toList();
    if (todayList.isEmpty) return null;

    const order = {'optimisee': 0, 'brouillon': 1, 'terminee': 2};
    todayList.sort((a, b) =>
        (order[a.statut] ?? 99).compareTo(order[b.statut] ?? 99));
    return todayList.first;
  });
});

/// Resume agrege de toutes les tournees datees d'aujourd'hui (peu
/// importe leur statut). Sert au compteur "X colis livres aujourd'hui"
/// dans HomeScreen : Noah voit son avancement sans devoir ouvrir
/// chaque tournee individuellement.
///
/// Carte Trello #100 : sert au cas typique multi-tournees (matin +
/// aprem) ou quand toutes les tournees du jour sont terminees et que
/// l'app retombe sur `_NoTourTodayScreen` -- le resume reste visible.
///
/// Recharge automatiquement quand une tournee du jour est ajoutee /
/// modifiee (depend de `tourneesDuJourProvider`). 1 seule query Drift
/// supplementaire (les stops du jour) -- les tournees sont deja en
/// cache via `tourneesStreamProvider`.
final aujourdhuiResumeProvider =
    FutureProvider<AujourdhuiResume>((ref) async {
  final tournees = ref.watch(tourneesDuJourProvider);
  if (tournees.isEmpty) return AujourdhuiResume.empty;

  final db = ref.watch(appDatabaseProvider);
  final ids = tournees.map((t) => t.id).toList();
  final stops = await (db.select(db.stops)
        ..where((s) => s.tourneeId.isIn(ids)))
      .get();

  final livres = stops.where((s) => s.statutLivraison == 'livre').toList();
  final echecs = stops.where((s) => s.statutLivraison == 'echec').length;
  final colisLivres = livres.fold<int>(0, (a, s) => a + s.nbColis);
  final distance =
      tournees.fold<int>(0, (a, t) => a + (t.distanceTotaleM ?? 0));
  final duree =
      tournees.fold<int>(0, (a, t) => a + (t.dureeTotaleS ?? 0));

  // Premier et dernier horodatage de livraison du jour (utile pour
  // afficher "12h05 - 17h32"). On filtre sur livreLe non-null et on
  // trie ascendant.
  final livresWithTime = livres.where((s) => s.livreLe != null).toList()
    ..sort((a, b) => a.livreLe!.compareTo(b.livreLe!));
  DateTime? premier;
  DateTime? dernier;
  if (livresWithTime.isNotEmpty) {
    premier = livresWithTime.first.livreLe;
    dernier = livresWithTime.last.livreLe;
  }

  return AujourdhuiResume(
    nbTournees: tournees.length,
    nbTourneesTerminees:
        tournees.where((t) => t.statut == 'terminee').length,
    nbTourneesEnCours:
        tournees.where((t) => t.statut == 'en_cours').length,
    nbArretsTotaux: stops.length,
    nbLivres: livres.length,
    nbEchecs: echecs,
    nbColisLivres: colisLivres,
    distanceMeters: distance,
    durationSeconds: duree,
    premierLivreLe: premier,
    dernierLivreLe: dernier,
  );
});

/// Stats agregees de la journee pour TOUTE l'equipe (logiciel chef,
/// epopee #88 / [#88·4]). Recharge quand une tournee du jour change
/// (depend de `tourneesDuJourProvider`). 1 seule query Drift en plus
/// (les stops du jour). Le calcul + les alertes vivent dans la fonction
/// pure [ChefStatsJour.computeFromBundle].
final equipeStatsJourProvider =
    FutureProvider<ChefStatsJour>((ref) async {
  final tournees = ref.watch(tourneesDuJourProvider);
  if (tournees.isEmpty) return ChefStatsJour.empty;

  final db = ref.watch(appDatabaseProvider);
  final ids = tournees.map((t) => t.id).toList();
  final stops = await (db.select(db.stops)
        ..where((s) => s.tourneeId.isIn(ids)))
      .get();

  return ChefStatsJour.computeFromBundle(tournees: tournees, stops: stops);
});

/// Liste des tournees du jour avec leur progression, pour le panneau
/// "tournees en cours" du logiciel chef (epopee #88 / [#88·2]). Meme
/// source que `equipeStatsJourProvider` (tournees du jour + 1 query
/// stops). Le tri + l'agregation vivent dans la fonction pure
/// [ChefTourneeProgress.computeFromBundle].
final equipeTourneesEnCoursProvider =
    FutureProvider<List<ChefTourneeProgress>>((ref) async {
  final tournees = ref.watch(tourneesDuJourProvider);
  if (tournees.isEmpty) return const [];

  final db = ref.watch(appDatabaseProvider);
  final ids = tournees.map((t) => t.id).toList();
  final stops = await (db.select(db.stops)
        ..where((s) => s.tourneeId.isIn(ids)))
      .get();

  return ChefTourneeProgress.computeFromBundle(
    tournees: tournees,
    stops: stops,
  );
});

/// Points geolocalises du jour (depots + stops) pour la carte du
/// logiciel chef (epopee #88 / [#88·3]). Meme source que les autres
/// providers chef. Agregation pure dans
/// [ChefCarteJour.computeFromBundle].
final equipeCarteJourProvider =
    FutureProvider<ChefCarteJour>((ref) async {
  final tournees = ref.watch(tourneesDuJourProvider);
  if (tournees.isEmpty) return ChefCarteJour.empty;

  final db = ref.watch(appDatabaseProvider);
  final ids = tournees.map((t) => t.id).toList();
  final stops = await (db.select(db.stops)
        ..where((s) => s.tourneeId.isIn(ids)))
      .get();

  return ChefCarteJour.computeFromBundle(tournees: tournees, stops: stops);
});

/// Snapshot immuable du resume du jour, consomme par [AujourdhuiResume]
/// dans HomeScreen. Tous les champs sont en valeur (pas de stream
/// derive) pour pouvoir tester l'UI sans Drift.
class AujourdhuiResume {
  const AujourdhuiResume({
    required this.nbTournees,
    required this.nbTourneesTerminees,
    required this.nbTourneesEnCours,
    required this.nbArretsTotaux,
    required this.nbLivres,
    required this.nbEchecs,
    required this.nbColisLivres,
    required this.distanceMeters,
    required this.durationSeconds,
    this.premierLivreLe,
    this.dernierLivreLe,
  });

  static const empty = AujourdhuiResume(
    nbTournees: 0,
    nbTourneesTerminees: 0,
    nbTourneesEnCours: 0,
    nbArretsTotaux: 0,
    nbLivres: 0,
    nbEchecs: 0,
    nbColisLivres: 0,
    distanceMeters: 0,
    durationSeconds: 0,
  );

  final int nbTournees;
  final int nbTourneesTerminees;
  final int nbTourneesEnCours;
  final int nbArretsTotaux;
  final int nbLivres;
  final int nbEchecs;
  final int nbColisLivres;
  final int distanceMeters;
  final int durationSeconds;
  final DateTime? premierLivreLe;
  final DateTime? dernierLivreLe;

  /// Aucune tournee planifiee aujourd'hui -> l'UI doit cacher la card.
  bool get isEmpty => nbTournees == 0;

  /// Vrai si au moins 1 stop a ete traite (livre ou echec). Sert au UI
  /// pour decider d'afficher la progress bar ou juste les compteurs.
  bool get hasActivite => nbLivres + nbEchecs > 0;

  /// Pourcentage d'avancement = (livres + echecs) / total. 0 si pas
  /// d'arret. Borne entre 0 et 1.
  double get avancement {
    if (nbArretsTotaux == 0) return 0;
    return ((nbLivres + nbEchecs) / nbArretsTotaux).clamp(0.0, 1.0);
  }

  /// Nombre de stops restants a traiter (ni livre ni echec). 0 si la
  /// journee est terminee.
  int get nbArretsRestants {
    final r = nbArretsTotaux - nbLivres - nbEchecs;
    return r < 0 ? 0 : r;
  }

  /// Taux de reussite sur les stops cloturés (livres / (livres +
  /// echecs)). 0 si aucun stop cloture.
  double get tauxReussite {
    final total = nbLivres + nbEchecs;
    if (total == 0) return 0;
    return nbLivres / total;
  }
}
