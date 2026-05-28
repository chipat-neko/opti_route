import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:opti_route/data/anomaly_detection_service.dart';
import 'package:opti_route/data/database.dart';

/// Tests de la detection d'anomalies (carte #122). Fonction pure, `now`
/// injecte -> deterministe. DB memoire pour produire de vraies rows.
void main() {
  late AppDatabase db;
  final now = DateTime(2026, 5, 28, 12, 0);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> seedTournee({
    required String statut,
    DateTime? demareeLe,
  }) {
    return db.into(db.tournees).insert(
          TourneesCompanion.insert(
            nom: 'T',
            date: now,
            pointDepartLat: 48.0,
            pointDepartLng: 1.0,
            pointDepartLabel: 'D',
            statut: Value(statut),
            demareeLe: Value(demareeLe),
          ),
        );
  }

  Future<void> seedStop(
    int tourneeId,
    String statut, {
    DateTime? livreLe,
  }) async {
    final sId = await db.into(db.stops).insert(
          StopsCompanion.insert(tourneeId: tourneeId, adresseBrute: 'A'),
        );
    if (statut != 'a_livrer') {
      final row = await (db.select(db.stops)
            ..where((s) => s.id.equals(sId)))
          .getSingle();
      await db.update(db.stops).replace(
            row.copyWith(statutLivraison: statut, livreLe: Value(livreLe)),
          );
    }
  }

  Future<List<Anomalie>> detect(int tId) async {
    final t = await (db.select(db.tournees)..where((x) => x.id.equals(tId)))
        .getSingle();
    final stops =
        await (db.select(db.stops)..where((s) => s.tourneeId.equals(tId)))
            .get();
    return AnomalyDetectionService.detect(tournee: t, stops: stops, now: now);
  }

  bool has(List<Anomalie> a, AnomalieSeverite s) =>
      a.any((x) => x.severite == s);

  test('tournee non en_cours -> aucune anomalie', () async {
    final t = await seedTournee(statut: 'terminee', demareeLe: now);
    await seedStop(t, 'livre', livreLe: now);
    expect(await detect(t), isEmpty);
  });

  test('taux d\'echec > 20% sur >=5 tentatives -> critique', () async {
    final t = await seedTournee(
        statut: 'en_cours', demareeLe: now.subtract(const Duration(minutes: 30)));
    final recent = now.subtract(const Duration(minutes: 5));
    for (var i = 0; i < 4; i++) {
      await seedStop(t, 'livre', livreLe: recent);
    }
    await seedStop(t, 'echec', livreLe: recent);
    await seedStop(t, 'echec', livreLe: recent);
    await seedStop(t, 'a_livrer'); // restants > 0 -> pas "a cloturer"

    final a = await detect(t);
    expect(has(a, AnomalieSeverite.critique), isTrue);
    expect(has(a, AnomalieSeverite.info), isFalse);
  });

  test('echantillon trop petit -> pas d\'alerte taux', () async {
    final t = await seedTournee(
        statut: 'en_cours', demareeLe: now.subtract(const Duration(minutes: 10)));
    await seedStop(t, 'echec', livreLe: now.subtract(const Duration(minutes: 2)));
    await seedStop(t, 'a_livrer');
    expect(has(await detect(t), AnomalieSeverite.critique), isFalse);
  });

  test('inactivite >= 2h -> attention', () async {
    final t = await seedTournee(
        statut: 'en_cours', demareeLe: now.subtract(const Duration(hours: 3)));
    await seedStop(t, 'a_livrer');
    final a = await detect(t);
    expect(has(a, AnomalieSeverite.attention), isTrue);
  });

  test('activite recente -> pas d\'inactivite', () async {
    final t = await seedTournee(
        statut: 'en_cours', demareeLe: now.subtract(const Duration(hours: 3)));
    await seedStop(t, 'livre',
        livreLe: now.subtract(const Duration(minutes: 10)));
    await seedStop(t, 'a_livrer');
    expect(has(await detect(t), AnomalieSeverite.attention), isFalse);
  });

  test('tous traites mais en_cours -> info a cloturer', () async {
    final t = await seedTournee(
        statut: 'en_cours', demareeLe: now.subtract(const Duration(hours: 1)));
    await seedStop(t, 'livre', livreLe: now.subtract(const Duration(minutes: 5)));
    await seedStop(t, 'livre', livreLe: now.subtract(const Duration(minutes: 3)));
    final a = await detect(t);
    expect(has(a, AnomalieSeverite.info), isTrue);
  });
}
