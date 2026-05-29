import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/chef_carte_service.dart';
import 'package:opti_route/data/database.dart';

// Complete chef_carte_service_test : equality des points, getters
// derives, filtre stops orphelins, fallback label, enum.
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
    double lat = 48,
    double lng = 1,
  }) {
    return db.into(db.tournees).insert(
          TourneesCompanion.insert(
            nom: nom,
            date: DateTime(2026, 5, 29),
            pointDepartLat: lat,
            pointDepartLng: lng,
            pointDepartLabel: 'D',
          ),
        );
  }

  Future<int> seedStop(
    int tId, {
    double? lat,
    double? lng,
    String? nomClient,
    String adresse = 'adresse',
    String statut = 'a_livrer',
  }) async {
    final id = await db.into(db.stops).insert(
          StopsCompanion.insert(
            tourneeId: tId,
            adresseBrute: adresse,
            lat: lat != null ? Value(lat) : const Value.absent(),
            lng: lng != null ? Value(lng) : const Value.absent(),
            nomClient: Value(nomClient),
          ),
        );
    if (statut != 'a_livrer') {
      final row = await (db.select(db.stops)..where((s) => s.id.equals(id)))
          .getSingle();
      await db.update(db.stops).replace(row.copyWith(statutLivraison: statut));
    }
    return id;
  }

  Future<ChefCarteJour> compute() async {
    final tournees = await db.select(db.tournees).get();
    final stops = await db.select(db.stops).get();
    return ChefCarteJour.computeFromBundle(tournees: tournees, stops: stops);
  }

  group('ChefCarteJour — getters derives', () {
    test('empty : isEmpty=true, nbDepots=0, nbStops=0', () {
      const j = ChefCarteJour.empty;
      expect(j.isEmpty, isTrue);
      expect(j.nbDepots, 0);
      expect(j.nbStops, 0);
      expect(j.points, isEmpty);
    });

    test('1 tournee + 2 stops geolocalises : nbDepots=1, nbStops=2',
        () async {
      final t = await seedTournee(nom: 'T');
      await seedStop(t, lat: 48.1, lng: 1.1);
      await seedStop(t, lat: 48.2, lng: 1.2);
      final j = await compute();
      expect(j.nbDepots, 1);
      expect(j.nbStops, 2);
      expect(j.isEmpty, isFalse);
    });
  });

  group('ChefCarteJour — filtres et fallbacks', () {
    test('stop dont tourneeId pas dans tournees du bundle : filtre',
        () async {
      // Cree 2 tournees, mais on ne passe que la premiere a la fonction.
      final t1 = await seedTournee(nom: 'T1');
      final t2 = await seedTournee(nom: 'T2');
      await seedStop(t1, lat: 48.1, lng: 1.1);
      await seedStop(t2, lat: 48.2, lng: 1.2);

      // Passe uniquement t1.
      final tournees =
          await (db.select(db.tournees)..where((t) => t.id.equals(t1))).get();
      final stops = await db.select(db.stops).get();
      final j = ChefCarteJour.computeFromBundle(
        tournees: tournees,
        stops: stops,
      );
      // 1 depot (t1) + 1 stop (de t1). Le stop de t2 est ignore.
      expect(j.nbDepots, 1);
      expect(j.nbStops, 1);
    });

    test('0 tournees + stops : empty (early return)', () async {
      // Insere un stop "orphelin" mais sans tournees dans le bundle.
      final t = await seedTournee(nom: 'T');
      await seedStop(t, lat: 48.1, lng: 1.1);
      final j = ChefCarteJour.computeFromBundle(
        tournees: const [],
        stops: await db.select(db.stops).get(),
      );
      expect(j.isEmpty, isTrue);
    });

    test('label stop : nomClient si present, sinon adresseBrute', () async {
      final t = await seedTournee(nom: 'T');
      // Avec nomClient
      await seedStop(t, lat: 48.1, lng: 1.1, nomClient: 'Garage X', adresse: '1 rue X');
      // Sans nomClient (fallback adresseBrute)
      await seedStop(t, lat: 48.2, lng: 1.2, adresse: '2 rue Y');
      final j = await compute();
      final labels = j.points.where((p) => p.type == ChefPointType.stop).map((p) => p.label).toSet();
      expect(labels, contains('Garage X'));
      expect(labels, contains('2 rue Y'));
    });

    test('stop avec lat null mais lng renseigne : ignore', () async {
      final t = await seedTournee(nom: 'T');
      // Stop "moitie geocode" : lat null -> ignore
      await seedStop(t, lng: 1.1);
      final j = await compute();
      expect(j.nbStops, 0, reason: 'lat null -> ignore');
    });

    test('statut livraison preserve sur le point (livre / echec / a_livrer)',
        () async {
      final t = await seedTournee(nom: 'T');
      await seedStop(t, lat: 48.1, lng: 1.1, statut: 'livre');
      await seedStop(t, lat: 48.2, lng: 1.2, statut: 'echec');
      await seedStop(t, lat: 48.3, lng: 1.3); // a_livrer par defaut
      final j = await compute();
      final statuts = j.points
          .where((p) => p.type == ChefPointType.stop)
          .map((p) => p.statut)
          .toSet();
      expect(statuts, containsAll(['livre', 'echec', 'a_livrer']));
    });
  });

  group('ChefCartePoint — equality et structure', () {
    test('== sur lat + lng + type + statut + label', () {
      const a = ChefCartePoint(
        lat: 48, lng: 1, type: ChefPointType.stop,
        statut: 'livre', label: 'X',
      );
      const b = ChefCartePoint(
        lat: 48, lng: 1, type: ChefPointType.stop,
        statut: 'livre', label: 'X',
      );
      const c = ChefCartePoint(
        lat: 48, lng: 1, type: ChefPointType.depot,
        statut: 'livre', label: 'X',
      );
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('hashCode coherent avec ==', () {
      const a = ChefCartePoint(
        lat: 48, lng: 1, type: ChefPointType.depot, label: 'X',
      );
      const b = ChefCartePoint(
        lat: 48, lng: 1, type: ChefPointType.depot, label: 'X',
      );
      expect(a.hashCode, b.hashCode);
    });

    test('statut + label optionnels (null par defaut)', () {
      const p = ChefCartePoint(
        lat: 48, lng: 1, type: ChefPointType.depot,
      );
      expect(p.statut, isNull);
      expect(p.label, isNull);
    });

    test('ChefPointType : 2 valeurs (depot, stop)', () {
      expect(ChefPointType.values, hasLength(2));
      expect(ChefPointType.values, containsAll(const [
        ChefPointType.depot,
        ChefPointType.stop,
      ]));
    });
  });
}
