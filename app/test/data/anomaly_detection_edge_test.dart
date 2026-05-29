import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/anomaly_detection_service.dart';
import 'package:opti_route/data/database.dart';

// Complete anomaly_detection_test : seuils precis, demareeLe null,
// listes massives, ordre de tri par severite, equality / hashCode.
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
      final row = await (db.select(db.stops)..where((s) => s.id.equals(sId)))
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

  group('AnomalyDetectionService — gardes precoces', () {
    test('0 stops mais en_cours -> aucune anomalie (early return)', () async {
      final t = await seedTournee(statut: 'en_cours', demareeLe: now);
      expect(await detect(t), isEmpty);
    });

    test('demareeLe null mais restants > 0 : pas d\'anomalie inactivite',
        () async {
      // Le bloc d'inactivite a une garde "demareeLe != null". Sans
      // demarrage, on ne peut pas inferer une duree d'inactivite.
      final t = await seedTournee(statut: 'en_cours', demareeLe: null);
      await seedStop(t, 'a_livrer');
      final a = await detect(t);
      // Aucune anomalie (pas en_cours bloque... non, statut OK,
      // mais pas de demareeLe -> pas d'inactivite, et restants > 0
      // donc pas d'info "a cloturer").
      expect(a.where((x) => x.severite == AnomalieSeverite.attention),
          isEmpty);
    });
  });

  group('AnomalyDetectionService — seuils precis taux echec', () {
    test('exactement 20% (1/5) : PAS critique (strict >)', () async {
      final t = await seedTournee(
        statut: 'en_cours',
        demareeLe: now.subtract(const Duration(minutes: 30)),
      );
      final recent = now.subtract(const Duration(minutes: 5));
      for (var i = 0; i < 4; i++) {
        await seedStop(t, 'livre', livreLe: recent);
      }
      await seedStop(t, 'echec', livreLe: recent);
      await seedStop(t, 'a_livrer');
      final a = await detect(t);
      expect(a.where((x) => x.severite == AnomalieSeverite.critique),
          isEmpty,
          reason: '1/5 = 20% = seuil, PAS critique (strict >)');
    });

    test('exactement 4 tentatives : sous le minimum -> pas critique', () async {
      final t = await seedTournee(
        statut: 'en_cours',
        demareeLe: now.subtract(const Duration(minutes: 30)),
      );
      final recent = now.subtract(const Duration(minutes: 5));
      await seedStop(t, 'livre', livreLe: recent);
      await seedStop(t, 'echec', livreLe: recent);
      await seedStop(t, 'echec', livreLe: recent);
      await seedStop(t, 'echec', livreLe: recent);
      await seedStop(t, 'a_livrer');
      // 4 tentatives < kMinTentatives (5)
      final a = await detect(t);
      expect(a.where((x) => x.severite == AnomalieSeverite.critique),
          isEmpty);
    });
  });

  group('AnomalyDetectionService — seuil inactivite', () {
    test('inactivite exactement 2h (>=) -> attention', () async {
      // Tournee demarree il y a exactement 2h, aucune livraison.
      final t = await seedTournee(
        statut: 'en_cours',
        demareeLe: now.subtract(const Duration(hours: 2)),
      );
      await seedStop(t, 'a_livrer');
      final a = await detect(t);
      expect(a.any((x) => x.severite == AnomalieSeverite.attention),
          isTrue);
    });

    test('inactivite 1h59m -> pas d\'attention', () async {
      final t = await seedTournee(
        statut: 'en_cours',
        demareeLe: now.subtract(const Duration(hours: 1, minutes: 59)),
      );
      await seedStop(t, 'a_livrer');
      final a = await detect(t);
      expect(a.where((x) => x.severite == AnomalieSeverite.attention),
          isEmpty);
    });
  });

  group('AnomalyDetectionService — tri et combinaison', () {
    test('tri par severite descendant (critique -> attention -> info)',
        () async {
      // On va declencher critique (taux echec) + attention (inactivite).
      // demareeLe -3h, plusieurs livre/echec anciens (> 2h) pour declencher
      // l'inactivite, et un ratio echecs > 20% sur 5+.
      final t = await seedTournee(
        statut: 'en_cours',
        demareeLe: now.subtract(const Duration(hours: 3)),
      );
      // 5 livres + 3 echecs = 3/8 = 37.5% > 20% sur 8 tentatives, et
      // tous remontent a > 2h en arriere.
      final ancien = now.subtract(const Duration(hours: 2, minutes: 30));
      for (var i = 0; i < 5; i++) {
        await seedStop(t, 'livre', livreLe: ancien);
      }
      for (var i = 0; i < 3; i++) {
        await seedStop(t, 'echec', livreLe: ancien);
      }
      await seedStop(t, 'a_livrer');

      final a = await detect(t);
      expect(a.length, greaterThanOrEqualTo(2));
      // critique en premier
      expect(a.first.severite, AnomalieSeverite.critique);
      // attention apres
      expect(
        a.indexWhere((x) => x.severite == AnomalieSeverite.attention),
        greaterThan(0),
      );
    });

    test('50 stops tous livres + en_cours : 1 info a cloturer', () async {
      final t = await seedTournee(
        statut: 'en_cours',
        demareeLe: now.subtract(const Duration(hours: 1)),
      );
      final recent = now.subtract(const Duration(minutes: 5));
      for (var i = 0; i < 50; i++) {
        await seedStop(t, 'livre', livreLe: recent);
      }
      final a = await detect(t);
      expect(a.where((x) => x.severite == AnomalieSeverite.info),
          hasLength(1));
    });
  });

  group('Anomalie — equality et hashCode', () {
    test('== sur severite + message', () {
      const a = Anomalie(AnomalieSeverite.info, 'msg');
      const b = Anomalie(AnomalieSeverite.info, 'msg');
      const c = Anomalie(AnomalieSeverite.critique, 'msg');
      const d = Anomalie(AnomalieSeverite.info, 'autre');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a, isNot(equals(d)));
    });

    test('hashCode coherent avec ==', () {
      const a = Anomalie(AnomalieSeverite.info, 'msg');
      const b = Anomalie(AnomalieSeverite.info, 'msg');
      expect(a.hashCode, b.hashCode);
    });

    test('toString contient le message', () {
      const a = Anomalie(AnomalieSeverite.critique, 'hello world');
      expect(a.toString(), contains('hello world'));
      expect(a.toString(), contains('critique'));
    });

    test('AnomalieSeverite : 3 valeurs', () {
      expect(AnomalieSeverite.values, hasLength(3));
      expect(
        AnomalieSeverite.values,
        containsAll(const [
          AnomalieSeverite.info,
          AnomalieSeverite.attention,
          AnomalieSeverite.critique,
        ]),
      );
    });
  });
}
