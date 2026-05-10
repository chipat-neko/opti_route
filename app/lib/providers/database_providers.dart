import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/tournees_repository.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final tourneesRepositoryProvider = Provider<TourneesRepository>((ref) {
  return TourneesRepository(ref.watch(appDatabaseProvider));
});

final tourneesStreamProvider = StreamProvider<List<Tournee>>((ref) {
  return ref.watch(tourneesRepositoryProvider).watchAll();
});
