import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/coequipiers_repository.dart';
import '../data/database.dart';
import '../data/eta_calculator.dart';
import '../data/local_reorder_service.dart';
import '../data/parametres_repository.dart';
import '../data/client_stats_service.dart';
import '../data/security_service.dart';
import '../data/saved_destinations_repository.dart';
import '../data/sheets_repository.dart';
import '../data/stats_service.dart';
import '../data/stops_repository.dart';
import '../data/tournees_repository.dart';
import '../theme/app_tokens.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final tourneesRepositoryProvider = Provider<TourneesRepository>((ref) {
  return TourneesRepository(ref.watch(appDatabaseProvider));
});

final sheetsRepositoryProvider = Provider<SheetsRepository>((ref) {
  return SheetsRepository(ref.watch(appDatabaseProvider));
});

final stopsRepositoryProvider = Provider<StopsRepository>((ref) {
  return StopsRepository(ref.watch(appDatabaseProvider));
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

final savedDestinationsRepositoryProvider =
    Provider<SavedDestinationsRepository>((ref) {
  return SavedDestinationsRepository(ref.watch(appDatabaseProvider));
});

final coequipiersRepositoryProvider = Provider<CoequipiersRepository>((ref) {
  return CoequipiersRepository(ref.watch(appDatabaseProvider));
});

/// Coequipiers actifs (visibles dans le selecteur d'affectation).
final coequipiersActifsProvider = StreamProvider<List<Coequipier>>((ref) {
  return ref.watch(coequipiersRepositoryProvider).watchActifs();
});

/// Tous les coequipiers (actifs + archives) pour l'UI de gestion.
final coequipiersAllProvider = StreamProvider<List<Coequipier>>((ref) {
  return ref.watch(coequipiersRepositoryProvider).watchAll();
});

/// Map id->Coequipier de TOUS les coequipiers (actifs + archives) pour
/// resolution rapide depuis `stop.coequipierId` dans la liste d'arrets
/// (sans relancer une requete par row).
///
/// Important : on inclut les archives car les stops historiques peuvent
/// pointer sur un coequipier archive. Sans ca, les badges _StopRow
/// afficheraient "?" alors qu'on a l'info en base.
final coequipiersByIdProvider = Provider<Map<int, Coequipier>>((ref) {
  final list = ref.watch(coequipiersAllProvider).asData?.value ?? const [];
  return {for (final c in list) c.id: c};
});

final parametresRepositoryProvider = Provider<ParametresRepository>((ref) {
  return ParametresRepository(ref.watch(appDatabaseProvider));
});

/// Service de verrouillage local (PIN + biometrie). Hash SHA-256 +
/// delegation `local_auth` au TEE Android pour la biometrie.
final securityServiceProvider = Provider<SecurityService>((ref) {
  return SecurityService(ref.watch(parametresRepositoryProvider));
});

/// Stream "verrou actif ET PIN defini". Combine `verrou_actif` + presence
/// de `pin_hash`. Sert au routeur d'app pour decider d'afficher
/// LockScreen au demarrage.
final lockEnabledStreamProvider = StreamProvider<bool>((ref) {
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

final statsServiceProvider = Provider<StatsService>((ref) {
  return StatsService(ref.watch(appDatabaseProvider));
});

final clientStatsServiceProvider = Provider<ClientStatsService>((ref) {
  return ClientStatsService(ref.watch(appDatabaseProvider));
});

/// Stats agregees pour un client donne du carnet (livraisons, echecs,
/// derniere visite, raisons d'echec). Recalcule a chaque modif des
/// stops via le watch implicite sur tourneesStreamProvider.
final clientStatsProvider = FutureProvider.family<ClientStats, int>(
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

/// Nom de l'entreprise du chef d'equipe (optionnel, affiche dans les
/// exports PDF / texte).
final entrepriseNomProvider = StreamProvider<String?>((ref) {
  return ref.watch(parametresRepositoryProvider).watchEntrepriseNom();
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

/// Compteur d'optimisations OpenRouteService consommees aujourd'hui.
/// Reset auto au passage minuit (gere dans le repo). Affiche dans
/// Parametres pour qu'on voie ou on en est par rapport au quota
/// 500/jour du plan free ORS.
final orsUsedTodayProvider = StreamProvider<int>((ref) {
  return ref.watch(parametresRepositoryProvider).watchOrsUsedToday();
});

/// Cout carburant estime (en EUR) pour une distance donnee (en metres).
/// Recalcule a chaque changement du parametre `coutCarburantLitre` ou
/// `consoLitresPar100Km` (via watchAll des parametres).
final coutCarburantProvider =
    FutureProvider.family<double, int>((ref, distanceMeters) async {
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

/// Vrai s'il existe au moins une tournee `statut == 'en_cours'` dans
/// la base, peu importe sa date. Sert a afficher un badge "tournee
/// active" sur l'icone drawer pour eviter d'oublier qu'on est en
/// mode actif quand on navigue dans d'autres ecrans.
final hasTourneeEnCoursProvider = Provider<bool>((ref) {
  final list = ref.watch(tourneesStreamProvider).asData?.value ?? const [];
  return list.any((t) => t.statut == 'en_cours');
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
