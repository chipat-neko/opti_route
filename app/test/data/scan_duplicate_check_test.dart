import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/scan_duplicate_check.dart';

void main() {
  late AppDatabase db;
  late int tId;
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    tId = await db.into(db.tournees).insert(TourneesCompanion.insert(
        nom: 'T',
        date: DateTime(2026, 5, 30),
        pointDepartLat: 48.0,
        pointDepartLng: 1.0,
        pointDepartLabel: 'D'));
  });
  tearDown(() async => db.close());

  Future<Stop> seed({
    String tracking = '',
    String statut = 'a_livrer',
    DateTime? livreLe,
  }) async {
    final id = await db.into(db.stops).insert(StopsCompanion.insert(
        tourneeId: tId,
        adresseBrute: 'A',
        statutLivraison: Value(statut),
        livreLe: Value(livreLe),
        trackingNumbers: Value(tracking.isEmpty ? null : tracking)));
    return (db.select(db.stops)..where((s) => s.id.equals(id))).getSingle();
  }

  group('findRecentDelivered (#315)', () {
    test('aucun match -> null', () async {
      final s = await seed(
          tracking: '["FA1"]',
          statut: 'livre',
          livreLe: DateTime(2026, 5, 25));
      expect(
        ScanDuplicateCheck.findRecentDelivered(
          tracking: 'FA999',
          recentStops: [s],
          now: DateTime(2026, 5, 30),
        ),
        isNull,
      );
    });

    test('match dans la fenetre 30j -> stop', () async {
      final s = await seed(
          tracking: '["FA280000440358"]',
          statut: 'livre',
          livreLe: DateTime(2026, 5, 10));
      final out = ScanDuplicateCheck.findRecentDelivered(
        tracking: 'FA280000440358',
        recentStops: [s],
        now: DateTime(2026, 5, 30),
      );
      expect(out, isNotNull);
      expect(out!.id, s.id);
    });

    test('hors fenetre -> null', () async {
      final s = await seed(
          tracking: '["FA1"]',
          statut: 'livre',
          livreLe: DateTime(2026, 4, 1));
      expect(
        ScanDuplicateCheck.findRecentDelivered(
          tracking: 'FA1',
          recentStops: [s],
          now: DateTime(2026, 5, 30),
        ),
        isNull,
      );
    });

    test('case insensitive', () async {
      final s = await seed(
          tracking: '["fa1"]',
          statut: 'livre',
          livreLe: DateTime(2026, 5, 25));
      expect(
        ScanDuplicateCheck.findRecentDelivered(
          tracking: 'FA1',
          recentStops: [s],
          now: DateTime(2026, 5, 30),
        ),
        isNotNull,
      );
    });
  });

  group('verifyBarcode (#315)', () {
    test('match expected', () async {
      final s = await seed(tracking: '["FA1","FA2"]');
      final r = ScanDuplicateCheck.verifyBarcode(
        scannedBarcode: 'FA1',
        expectedStop: s,
        tourneeStops: [s],
      );
      expect(r.kind, ScanMatchKind.match);
    });

    test('wrong stop -> suggere le bon', () async {
      final a = await seed(tracking: '["FA1"]');
      final b = await seed(tracking: '["FA2"]');
      final r = ScanDuplicateCheck.verifyBarcode(
        scannedBarcode: 'FA2',
        expectedStop: a,
        tourneeStops: [a, b],
      );
      expect(r.kind, ScanMatchKind.wrongStop);
      expect(r.suggestedStop!.id, b.id);
    });

    test('unknown', () async {
      final a = await seed(tracking: '["FA1"]');
      final r = ScanDuplicateCheck.verifyBarcode(
        scannedBarcode: 'XYZ',
        expectedStop: a,
        tourneeStops: [a],
      );
      expect(r.kind, ScanMatchKind.unknown);
    });

    test('code vide -> unknown', () async {
      final a = await seed(tracking: '["FA1"]');
      final r = ScanDuplicateCheck.verifyBarcode(
        scannedBarcode: '  ',
        expectedStop: a,
        tourneeStops: [a],
      );
      expect(r.kind, ScanMatchKind.unknown);
    });
  });
}
