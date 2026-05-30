import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/local_reorder_service.dart';

void main() {
  late AppDatabase db;
  late int tourneeId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    tourneeId = await db.into(db.tournees).insert(
          TourneesCompanion.insert(
            nom: 'T',
            date: DateTime(2026, 5, 30),
            pointDepartLat: 48.0,
            pointDepartLng: 1.0,
            pointDepartLabel: 'D',
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  Future<Stop> seed({
    required double lat,
    required double lng,
    String statut = 'a_livrer',
    String priorite = 'flexible',
  }) async {
    final id = await db.into(db.stops).insert(
          StopsCompanion.insert(
            tourneeId: tourneeId,
            adresseBrute: 'X',
            lat: Value(lat),
            lng: Value(lng),
            statutLivraison: Value(statut),
            priorite: Value(priorite),
          ),
        );
    return (db.select(db.stops)..where((s) => s.id.equals(id))).getSingle();
  }

  group('LocalReorderService.computeOrderForPending (#278)', () {
    test('aucun pending -> liste vide', () async {
      final s = await seed(lat: 48.1, lng: 1.1, statut: 'livre');
      final order = LocalReorderService.computeOrderForPending(
        originLat: 48.0,
        originLng: 1.0,
        pendingStops: [s],
      );
      expect(order, isEmpty,
          reason: 'livre = pas dans pending, filtre');
    });

    test('origin proche du stop 3 -> ordre commence par s3', () async {
      // Depot a (48.0, 1.0), s1 a 1km nord, s2 a 5km, s3 a 10km.
      final s1 = await seed(lat: 48.009, lng: 1.0);
      final s2 = await seed(lat: 48.045, lng: 1.0);
      final s3 = await seed(lat: 48.090, lng: 1.0);
      // Origin GPS = juste à côté de s3 (latitude proche)
      final order = LocalReorderService.computeOrderForPending(
        originLat: 48.090,
        originLng: 1.0,
        pendingStops: [s1, s2, s3],
      );
      expect(order.first, s3.id, reason: 'plus proche en premier');
    });

    test('origine depot vs origine GPS donne des ordres differents',
        () async {
      // s1 proche du depot, s3 loin
      final s1 = await seed(lat: 48.005, lng: 1.0);
      final s2 = await seed(lat: 48.050, lng: 1.0);
      final s3 = await seed(lat: 48.100, lng: 1.0);
      // Depuis depot (48,1) : ordre = [s1, s2, s3]
      final orderFromDepot = LocalReorderService.computeOrderForPending(
        originLat: 48.0,
        originLng: 1.0,
        pendingStops: [s1, s2, s3],
      );
      expect(orderFromDepot.first, s1.id);
      // Depuis s3 (48.100,1) : ordre = [s3, s2, s1]
      final orderFromS3 = LocalReorderService.computeOrderForPending(
        originLat: 48.100,
        originLng: 1.0,
        pendingStops: [s1, s2, s3],
      );
      expect(orderFromS3.first, s3.id);
      expect(orderFromS3.last, s1.id);
    });

    test('livres / echecs exclus du calcul', () async {
      final livre = await seed(lat: 48.005, lng: 1.0, statut: 'livre');
      final echec = await seed(lat: 48.010, lng: 1.0, statut: 'echec');
      final pending = await seed(lat: 48.050, lng: 1.0);
      final order = LocalReorderService.computeOrderForPending(
        originLat: 48.0,
        originLng: 1.0,
        pendingStops: [livre, echec, pending],
      );
      expect(order, [pending.id]);
    });

    test('obligatoire_premier reste devant, obligatoire_dernier reste apres',
        () async {
      final p = await seed(
          lat: 48.090, lng: 1.0, priorite: 'obligatoire_premier');
      final flex = await seed(lat: 48.010, lng: 1.0);
      final d = await seed(
          lat: 48.005, lng: 1.0, priorite: 'obligatoire_dernier');
      final order = LocalReorderService.computeOrderForPending(
        originLat: 48.0,
        originLng: 1.0,
        pendingStops: [p, flex, d],
      );
      // p en premier malgre etre loin, d en dernier malgre etre proche.
      expect(order.first, p.id);
      expect(order.last, d.id);
    });

    test('stops sans coords -> rejetes a la fin', () async {
      final ok = await seed(lat: 48.010, lng: 1.0);
      final noCoords = await db.into(db.stops).insert(
            StopsCompanion.insert(
              tourneeId: tourneeId,
              adresseBrute: 'orphan',
              statutLivraison: const Value('a_livrer'),
            ),
          );
      final orphan = await (db.select(db.stops)
            ..where((s) => s.id.equals(noCoords)))
          .getSingle();
      final order = LocalReorderService.computeOrderForPending(
        originLat: 48.0,
        originLng: 1.0,
        pendingStops: [ok, orphan],
      );
      expect(order.first, ok.id);
      expect(order.last, orphan.id);
    });
  });
}
