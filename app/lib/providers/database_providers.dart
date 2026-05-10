import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/sheets_repository.dart';
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

final tourneesStreamProvider = StreamProvider<List<Tournee>>((ref) {
  return ref.watch(tourneesRepositoryProvider).watchAll();
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
