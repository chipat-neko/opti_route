import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/handover_briefing.dart';

void main() {
  late AppDatabase db;
  late int tId;
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    tId = await db.into(db.tournees).insert(TourneesCompanion.insert(
        nom: 'Lundi',
        date: DateTime(2026, 5, 30),
        pointDepartLat: 48.0,
        pointDepartLng: 1.0,
        pointDepartLabel: 'Depot Chartres'));
  });
  tearDown(() async => db.close());

  Future<Tournee> getT() async =>
      (db.select(db.tournees)..where((t) => t.id.equals(tId))).getSingle();

  Future<Stop> seedStop({
    String? nom,
    String? memo,
    String? notes,
    int colis = 1,
  }) async {
    final id = await db.into(db.stops).insert(StopsCompanion.insert(
        tourneeId: tId,
        adresseBrute: '1 rue X',
        nomClient: Value(nom),
        memoVocal: Value(memo),
        notes: Value(notes),
        nbColis: Value(colis)));
    return (db.select(db.stops)..where((s) => s.id.equals(id))).getSingle();
  }

  Future<SavedDestination> seedDest({
    String? code,
    String? etage,
    String? parking,
    bool vigilance = false,
    bool photoObl = false,
  }) async {
    final id = await db.into(db.savedDestinations).insert(
          SavedDestinationsCompanion.insert(
            adresseDisplay: '1 rue X',
            lat: 48,
            lng: 1,
            codeAcces: Value(code),
            etageBatiment: Value(etage),
            noteStationnement: Value(parking),
            isProblematique: Value(vigilance),
            photoObligatoire: Value(photoObl),
          ),
        );
    return (db.select(db.savedDestinations)..where((s) => s.id.equals(id)))
        .getSingle();
  }

  group('HandoverBriefing.composeText (#312)', () {
    test('en-tete + 0 stop', () async {
      final t = await getT();
      final s = HandoverBriefing.composeText(
          tournee: t, orderedStops: const []);
      expect(s, contains('PASSATION'));
      expect(s, contains('Lundi'));
      expect(s, contains('Depot Chartres'));
      expect(s, contains('Stops   : 0'));
    });

    test('avec carnet enrichi (code + etage + parking + vigilance)',
        () async {
      final stop = await seedStop(nom: 'M. A', memo: 'sonnette HS');
      final dest = await seedDest(
        code: '1234B',
        etage: '3e D',
        parking: 'sous-sol',
        vigilance: true,
      );
      final t = await getT();
      final out = HandoverBriefing.composeText(
        tournee: t,
        orderedStops: [stop],
        carnetByStopId: {stop.id: dest},
      );
      expect(out, contains('M. A'));
      expect(out, contains('CODE     : 1234B'));
      expect(out, contains('Etage    : 3e D'));
      expect(out, contains('Parking  : sous-sol'));
      expect(out, contains('!! VIGILANCE !!'));
      expect(out, contains('Memo voc : sonnette HS'));
    });

    test('photo obligatoire flaggee', () async {
      final stop = await seedStop();
      final dest = await seedDest(photoObl: true);
      final t = await getT();
      final out = HandoverBriefing.composeText(
        tournee: t,
        orderedStops: [stop],
        carnetByStopId: {stop.id: dest},
      );
      expect(out, contains('PHOTO OBLIGATOIRE'));
    });
  });

  group('HandoverBriefing.composeTtsForStop (#312)', () {
    test('compact, jointures par point', () async {
      final stop = await seedStop(nom: 'M. A', memo: 'sonnette HS', colis: 3);
      final dest = await seedDest(code: '1234B', etage: '3e');
      final tts = HandoverBriefing.composeTtsForStop(
          stop: stop, carnet: dest);
      expect(tts, contains('M. A'));
      expect(tts, contains('Code : 1234B'));
      expect(tts, contains('3e'));
      expect(tts, contains('sonnette HS'));
      expect(tts, contains('3 colis'));
    });

    test('sans carnet -> juste stop', () async {
      final stop = await seedStop(nom: 'A');
      final tts = HandoverBriefing.composeTtsForStop(stop: stop);
      expect(tts, contains('A'));
      expect(tts, contains('1 colis'));
    });
  });
}
