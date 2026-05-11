import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/parametres_repository.dart';
import '../data/client_stats_service.dart';
import '../data/saved_destinations_repository.dart';
import '../data/sheets_repository.dart';
import '../data/stats_service.dart';
import '../data/stops_repository.dart';
import '../data/tournees_repository.dart';

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

final savedDestinationsRepositoryProvider =
    Provider<SavedDestinationsRepository>((ref) {
  return SavedDestinationsRepository(ref.watch(appDatabaseProvider));
});

final parametresRepositoryProvider = Provider<ParametresRepository>((ref) {
  return ParametresRepository(ref.watch(appDatabaseProvider));
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

/// Compteur d'optimisations OpenRouteService consommees aujourd'hui.
/// Reset auto au passage minuit (gere dans le repo). Affiche dans
/// Parametres pour qu'on voie ou on en est par rapport au quota
/// 500/jour du plan free ORS.
final orsUsedTodayProvider = StreamProvider<int>((ref) {
  return ref.watch(parametresRepositoryProvider).watchOrsUsedToday();
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
