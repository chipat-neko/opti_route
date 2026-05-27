import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/stops_repository.dart';

/// Tests de l'annulation en masse (carte #115) :
/// [StopsRepository.markAaLivrerBatch] repasse les arrets livres en
/// 'a_livrer' et ignore ceux deja en attente.
void main() {
  late AppDatabase db;
  late StopsRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = StopsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> seedTournee() {
    return db.into(db.tournees).insert(
          TourneesCompanion.insert(
            nom: 'T',
            date: DateTime.now(),
            pointDepartLat: 48.0,
            pointDepartLng: 1.0,
            pointDepartLabel: 'D',
          ),
        );
  }

  Future<int> seedStop(int tourneeId) {
    return db.into(db.stops).insert(
          StopsCompanion.insert(
            tourneeId: tourneeId,
            adresseBrute: 'A',
          ),
        );
  }

  test('repasse les arrets livres en a_livrer + cumule le compte',
      () async {
    final t = await seedTournee();
    final s1 = await seedStop(t);
    final s2 = await seedStop(t);
    final s3 = await seedStop(t);

    await repo.markLivre(s1);
    await repo.markLivre(s2);
    await repo.markLivre(s3);

    final n = await repo.markAaLivrerBatch([s1, s2, s3]);
    expect(n, 3);

    final rows = await repo.getByTournee(t);
    expect(rows.every((s) => s.statutLivraison == 'a_livrer'), isTrue);
  });

  test('ignore les arrets deja en a_livrer', () async {
    final t = await seedTournee();
    final s1 = await seedStop(t); // livre
    final s2 = await seedStop(t); // reste a_livrer
    await repo.markLivre(s1);

    final n = await repo.markAaLivrerBatch([s1, s2]);
    // Seul s1 etait a reverter.
    expect(n, 1);
  });
}
