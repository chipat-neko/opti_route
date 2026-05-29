import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/chef_stats_service.dart';
import 'package:opti_route/data/database.dart';

// Complete chef_stats_service_test : getters derives, seuils precis,
// melange d'alertes, equality ChefAlerte, filtres.
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
    int? distanceM,
  }) {
    return db.into(db.tournees).insert(
          TourneesCompanion.insert(
            nom: nom,
            date: DateTime(2026, 5, 29),
            pointDepartLat: 48.0,
            pointDepartLng: 1.0,
            pointDepartLabel: 'D',
            statut: Value(statut),
            distanceTotaleM: Value(distanceM),
          ),
        );
  }

  Future<void> seedStop(int tId, String statut, {int nbColis = 1}) async {
    final sId = await db.into(db.stops).insert(
          StopsCompanion.insert(
            tourneeId: tId,
            adresseBrute: 'A',
            nbColis: Value(nbColis),
          ),
        );
    if (statut != 'a_livrer') {
      final row = await (db.select(db.stops)..where((s) => s.id.equals(sId)))
          .getSingle();
      await db.update(db.stops).replace(
            row.copyWith(statutLivraison: statut),
          );
    }
  }

  Future<ChefStatsJour> compute() async {
    final tournees = await db.select(db.tournees).get();
    final stops = await db.select(db.stops).get();
    return ChefStatsJour.computeFromBundle(
      tournees: tournees,
      stops: stops,
    );
  }

  group('ChefStatsJour — getters derives', () {
    test('empty constant : tous les compteurs a 0', () {
      const s = ChefStatsJour.empty;
      expect(s.nbTournees, 0);
      expect(s.totalStops, 0);
      expect(s.nbLivres, 0);
      expect(s.nbEchecs, 0);
      expect(s.colisLivres, 0);
      expect(s.distanceMeters, 0);
      expect(s.alertes, isEmpty);
      expect(s.restants, 0);
      expect(s.distanceKm, 0);
      expect(s.tauxReussite, 0);
    });

    test('restants = totalStops - livres - echecs', () async {
      final t = await seedTournee(nom: 'T', statut: 'en_cours');
      await seedStop(t, 'livre');
      await seedStop(t, 'livre');
      await seedStop(t, 'echec');
      await seedStop(t, 'a_livrer');
      await seedStop(t, 'a_livrer');
      final s = await compute();
      expect(s.totalStops, 5);
      expect(s.nbLivres, 2);
      expect(s.nbEchecs, 1);
      expect(s.restants, 2);
    });

    test('distanceKm = distanceMeters / 1000', () async {
      await seedTournee(nom: 'T', statut: 'terminee', distanceM: 12500);
      final s = await compute();
      expect(s.distanceKm, 12.5);
    });

    test('tauxReussite = livres / (livres + echecs), 0 si aucune tentative',
        () async {
      final t = await seedTournee(nom: 'T', statut: 'en_cours');
      // Sans aucun stop tente -> taux = 0
      var s = await compute();
      expect(s.tauxReussite, 0);
      // 3 livres + 1 echec = 75%
      await seedStop(t, 'livre');
      await seedStop(t, 'livre');
      await seedStop(t, 'livre');
      await seedStop(t, 'echec');
      s = await compute();
      expect(s.tauxReussite, closeTo(0.75, 0.001));
    });
  });

  group('ChefStatsJour — seuils precis taux echec', () {
    test('exactement 20% (1/5) : PAS critique (strict >)', () async {
      final t = await seedTournee(nom: 'T', statut: 'en_cours');
      for (var i = 0; i < 4; i++) {
        await seedStop(t, 'livre');
      }
      await seedStop(t, 'echec');
      final s = await compute();
      expect(s.alertes.where((a) => a.severite == ChefAlerteSeverite.critique),
          isEmpty);
    });

    test('exactement 4 tentatives : pas d\'alerte (< kMinTentativesPourAlerte)',
        () async {
      final t = await seedTournee(nom: 'T', statut: 'en_cours');
      await seedStop(t, 'echec');
      await seedStop(t, 'echec');
      await seedStop(t, 'echec');
      await seedStop(t, 'echec');
      final s = await compute();
      expect(s.alertes.where((a) => a.severite == ChefAlerteSeverite.critique),
          isEmpty);
    });
  });

  group('ChefStatsJour — alertes par tournee', () {
    test('exactement kMinStopsBloquee (3) sans livraison : attention', () async {
      final t = await seedTournee(nom: 'T', statut: 'en_cours');
      for (var i = 0; i < 3; i++) {
        await seedStop(t, 'a_livrer');
      }
      final s = await compute();
      expect(s.alertes.any((a) => a.severite == ChefAlerteSeverite.attention),
          isTrue);
    });

    test('2 stops sans livraison : pas d\'attention (< kMinStopsBloquee)',
        () async {
      final t = await seedTournee(nom: 'T', statut: 'en_cours');
      await seedStop(t, 'a_livrer');
      await seedStop(t, 'a_livrer');
      final s = await compute();
      expect(s.alertes.where((a) => a.severite == ChefAlerteSeverite.attention),
          isEmpty);
    });

    test('tournee terminee : pas d\'alerte par tournee', () async {
      final t = await seedTournee(nom: 'T', statut: 'terminee');
      for (var i = 0; i < 5; i++) {
        await seedStop(t, 'a_livrer'); // tous non traites
      }
      final s = await compute();
      expect(
        s.alertes.where((a) => a.severite == ChefAlerteSeverite.attention),
        isEmpty,
        reason: 'attention ne touche que les en_cours',
      );
    });
  });

  group('ChefStatsJour — colisLivres + filtres', () {
    test('colisLivres : somme nbColis des livres uniquement', () async {
      final t = await seedTournee(nom: 'T', statut: 'en_cours');
      await seedStop(t, 'livre', nbColis: 3);
      await seedStop(t, 'livre', nbColis: 2);
      await seedStop(t, 'echec', nbColis: 10); // ignore
      await seedStop(t, 'a_livrer', nbColis: 99); // ignore
      final s = await compute();
      expect(s.colisLivres, 5);
    });

    test('nbTourneesEnCours / nbTourneesTerminees filtres independants',
        () async {
      await seedTournee(nom: 'T1', statut: 'brouillon');
      await seedTournee(nom: 'T2', statut: 'en_cours');
      await seedTournee(nom: 'T3', statut: 'en_cours');
      await seedTournee(nom: 'T4', statut: 'terminee');
      final s = await compute();
      expect(s.nbTournees, 4);
      expect(s.nbTourneesEnCours, 2);
      expect(s.nbTourneesTerminees, 1);
    });
  });

  group('ChefAlerte — equality et toString', () {
    test('== sur severite + message', () {
      const a = ChefAlerte(ChefAlerteSeverite.info, 'msg');
      const b = ChefAlerte(ChefAlerteSeverite.info, 'msg');
      const c = ChefAlerte(ChefAlerteSeverite.critique, 'msg');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('hashCode coherent avec ==', () {
      const a = ChefAlerte(ChefAlerteSeverite.info, 'msg');
      const b = ChefAlerte(ChefAlerteSeverite.info, 'msg');
      expect(a.hashCode, b.hashCode);
    });

    test('toString contient severite + message', () {
      const a = ChefAlerte(ChefAlerteSeverite.attention, 'hello');
      expect(a.toString(), contains('attention'));
      expect(a.toString(), contains('hello'));
    });

    test('ChefAlerteSeverite : 3 valeurs', () {
      expect(ChefAlerteSeverite.values, hasLength(3));
      expect(ChefAlerteSeverite.values,
          containsAll(const [
            ChefAlerteSeverite.info,
            ChefAlerteSeverite.attention,
            ChefAlerteSeverite.critique,
          ]));
    });
  });
}
