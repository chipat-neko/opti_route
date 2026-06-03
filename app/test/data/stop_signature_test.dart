import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/stops_repository.dart';

/// Vérifie la colonne `stops.signaturePath` (#signature Noah) + le
/// helper repo `setSignature`. La signature (PNG local) est capturée au
/// "Marquer livré" (facultative).
void main() {
  late AppDatabase db;
  late StopsRepository repo;
  late int stopId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = StopsRepository(db);
    final tourneeId = await db.into(db.tournees).insert(
          TourneesCompanion.insert(
            nom: 'T',
            date: DateTime(2026, 6, 3),
            pointDepartLat: 48.0,
            pointDepartLng: 2.0,
            pointDepartLabel: 'Depot',
          ),
        );
    stopId = await db.into(db.stops).insert(
          StopsCompanion.insert(tourneeId: tourneeId, adresseBrute: 'A'),
        );
  });

  tearDown(() => db.close());

  Future<Stop> read() =>
      (db.select(db.stops)..where((s) => s.id.equals(stopId))).getSingle();

  test('signaturePath null par défaut', () async {
    expect((await read()).signaturePath, isNull);
  });

  test('setSignature enregistre le chemin', () async {
    await repo.setSignature(stopId, '/data/signatures/${stopId}_123.png');
    expect((await read()).signaturePath, '/data/signatures/${stopId}_123.png');
  });

  test('setSignature(null) efface', () async {
    await repo.setSignature(stopId, '/x.png');
    await repo.setSignature(stopId, null);
    expect((await read()).signaturePath, isNull);
  });
}
