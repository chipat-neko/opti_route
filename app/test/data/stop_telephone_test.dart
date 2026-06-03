import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';

/// Vérifie la nouvelle colonne `stops.telephone` (#B Noah) : persistance
/// + mise à jour. Le numéro saisi sur l'arrêt permet l'appel en 1 tap.
void main() {
  late AppDatabase db;
  late int tourneeId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    tourneeId = await db.into(db.tournees).insert(
          TourneesCompanion.insert(
            nom: 'T',
            date: DateTime(2026, 6, 3),
            pointDepartLat: 48.0,
            pointDepartLng: 2.0,
            pointDepartLabel: 'Depot',
          ),
        );
  });

  tearDown(() => db.close());

  test('telephone null par défaut', () async {
    final id = await db.into(db.stops).insert(
          StopsCompanion.insert(tourneeId: tourneeId, adresseBrute: 'A'),
        );
    final s = await (db.select(db.stops)..where((s) => s.id.equals(id)))
        .getSingle();
    expect(s.telephone, isNull);
  });

  test('telephone persiste à l\'insert', () async {
    final id = await db.into(db.stops).insert(
          StopsCompanion.insert(
            tourneeId: tourneeId,
            adresseBrute: 'A',
            telephone: const Value('06 12 34 56 78'),
          ),
        );
    final s = await (db.select(db.stops)..where((s) => s.id.equals(id)))
        .getSingle();
    expect(s.telephone, '06 12 34 56 78');
  });

  test('telephone modifiable à l\'update', () async {
    final id = await db.into(db.stops).insert(
          StopsCompanion.insert(tourneeId: tourneeId, adresseBrute: 'A'),
        );
    await (db.update(db.stops)..where((s) => s.id.equals(id)))
        .write(const StopsCompanion(telephone: Value('0102030405')));
    final s = await (db.select(db.stops)..where((s) => s.id.equals(id)))
        .getSingle();
    expect(s.telephone, '0102030405');
  });
}
