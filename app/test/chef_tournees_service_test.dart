import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:opti_route/data/chef_tournees_service.dart';
import 'package:opti_route/data/database.dart';

/// Tests de la fonction pure [ChefTourneeProgress.computeFromBundle]
/// (epopee #88, [#88·2]) : agregation progression par tournee + tri
/// (en cours d'abord, puis alphabetique). DB Drift en memoire pour
/// produire de vraies rows Tournee/Stop.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> seedTournee({
    required String nom,
    required String statut,
    DateTime? pauseeLe,
  }) {
    return db.into(db.tournees).insert(
          TourneesCompanion.insert(
            nom: nom,
            date: DateTime.now(),
            pointDepartLat: 48.0,
            pointDepartLng: 1.0,
            pointDepartLabel: 'Depot',
            statut: Value(statut),
            pauseeLe: Value(pauseeLe),
          ),
        );
  }

  Future<void> seedStop(int tourneeId, String statut) async {
    final sId = await db.into(db.stops).insert(
          StopsCompanion.insert(
            tourneeId: tourneeId,
            adresseBrute: 'A',
          ),
        );
    if (statut != 'a_livrer') {
      final row = await (db.select(db.stops)
            ..where((s) => s.id.equals(sId)))
          .getSingle();
      await db.update(db.stops).replace(
            row.copyWith(statutLivraison: statut),
          );
    }
  }

  Future<List<ChefTourneeProgress>> compute() async {
    final tournees = await db.select(db.tournees).get();
    final stops = await db.select(db.stops).get();
    return ChefTourneeProgress.computeFromBundle(
      tournees: tournees,
      stops: stops,
    );
  }

  test('liste vide si aucune tournee', () {
    final out = ChefTourneeProgress.computeFromBundle(
      tournees: const [],
      stops: const [],
    );
    expect(out, isEmpty);
  });

  test('progression + compteurs d\'une tournee', () async {
    final t = await seedTournee(nom: 'T', statut: 'en_cours');
    await seedStop(t, 'livre');
    await seedStop(t, 'livre');
    await seedStop(t, 'echec');
    await seedStop(t, 'a_livrer');

    final out = await compute();
    expect(out, hasLength(1));
    final p = out.single;
    expect(p.total, 4);
    expect(p.livres, 2);
    expect(p.echecs, 1);
    // (2 livres + 1 echec) / 4 = 0.75
    expect(p.progression, closeTo(0.75, 0.001));
    expect(p.estEnCours, isTrue);
  });

  test('tri : en cours d\'abord, puis alphabetique', () async {
    await seedTournee(nom: 'Zebra', statut: 'en_cours');
    await seedTournee(nom: 'Alpha', statut: 'terminee');
    await seedTournee(nom: 'Beta', statut: 'en_cours');

    final out = await compute();
    expect(out.map((e) => e.nom).toList(), ['Beta', 'Zebra', 'Alpha']);
  });

  test('flag enPause remonte', () async {
    await seedTournee(
      nom: 'EnPause',
      statut: 'en_cours',
      pauseeLe: DateTime(2026, 5, 27, 12),
    );

    final out = await compute();
    expect(out.single.enPause, isTrue);
  });

  test('progression 0 si tournee sans stop', () async {
    await seedTournee(nom: 'Vide', statut: 'en_cours');
    final out = await compute();
    expect(out.single.total, 0);
    expect(out.single.progression, 0);
  });
}
