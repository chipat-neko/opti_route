import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/chef_tournees_service.dart';
import 'package:opti_route/data/database.dart';

// Complete chef_tournees_service_test : getters derives,
// computeFromBundle filtres et tris sub-cas, statuts varies.
void main() {
  group('ChefTourneeProgress — getters derives', () {
    test('progression : 0 quand pas de stop (total=0)', () {
      const p = ChefTourneeProgress(
        tourneeId: 1, nom: 'T', statut: 'en_cours',
        pointDepartLabel: 'D', coequipierId: null,
        total: 0, livres: 0, echecs: 0, enPause: false,
      );
      expect(p.progression, 0);
    });

    test('progression 0.5 : 1 livre + 1 echec sur 4 stops', () {
      const p = ChefTourneeProgress(
        tourneeId: 1, nom: 'T', statut: 'en_cours',
        pointDepartLabel: 'D', coequipierId: null,
        total: 4, livres: 1, echecs: 1, enPause: false,
      );
      expect(p.progression, 0.5);
    });

    test('progression : clamp a 1.0 si livres + echecs > total (defensive)',
        () {
      const p = ChefTourneeProgress(
        tourneeId: 1, nom: 'T', statut: 'en_cours',
        pointDepartLabel: 'D', coequipierId: null,
        total: 3, livres: 5, echecs: 0, enPause: false,
      );
      expect(p.progression, 1.0,
          reason: 'clamp defensif ; ne doit jamais retourner > 1');
    });

    test('estEnCours : true seulement pour statut "en_cours"', () {
      const a = ChefTourneeProgress(
        tourneeId: 1, nom: 'T', statut: 'en_cours',
        pointDepartLabel: 'D', coequipierId: null,
        total: 0, livres: 0, echecs: 0, enPause: false,
      );
      const b = ChefTourneeProgress(
        tourneeId: 2, nom: 'U', statut: 'terminee',
        pointDepartLabel: 'D', coequipierId: null,
        total: 0, livres: 0, echecs: 0, enPause: false,
      );
      const c = ChefTourneeProgress(
        tourneeId: 3, nom: 'V', statut: 'brouillon',
        pointDepartLabel: 'D', coequipierId: null,
        total: 0, livres: 0, echecs: 0, enPause: false,
      );
      expect(a.estEnCours, isTrue);
      expect(b.estEnCours, isFalse);
      expect(c.estEnCours, isFalse);
    });
  });

  group('ChefTourneeProgress.computeFromBundle — tri et filtres', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    Future<int> seedTournee({
      required String nom,
      String statut = 'brouillon',
      DateTime? pauseeLe,
    }) {
      return db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: nom,
              date: DateTime(2026, 5, 29),
              pointDepartLat: 48.0,
              pointDepartLng: 1.0,
              pointDepartLabel: 'D',
              statut: Value(statut),
              pauseeLe: Value(pauseeLe),
            ),
          );
    }

    Future<int> seedStop({required int tId, String statut = 'a_livrer'}) async {
      final id = await db.into(db.stops).insert(
            StopsCompanion.insert(tourneeId: tId, adresseBrute: 'A'),
          );
      if (statut != 'a_livrer') {
        final row = await (db.select(db.stops)..where((s) => s.id.equals(id)))
            .getSingle();
        await db.update(db.stops).replace(row.copyWith(statutLivraison: statut));
      }
      return id;
    }

    Future<List<ChefTourneeProgress>> compute() async {
      final t = await db.select(db.tournees).get();
      final s = await db.select(db.stops).get();
      return ChefTourneeProgress.computeFromBundle(tournees: t, stops: s);
    }

    test('terminees triees aussi alphabetiquement entre elles', () async {
      await seedTournee(nom: 'Zebra', statut: 'terminee');
      await seedTournee(nom: 'Alpha', statut: 'terminee');
      await seedTournee(nom: 'Beta', statut: 'terminee');
      final progs = await compute();
      expect(progs.map((p) => p.nom).toList(),
          ['Alpha', 'Beta', 'Zebra']);
    });

    test('stop dont tourneeId n\'est pas dans la liste de tournees : '
        'agrege quand meme dans byTournee mais ignore au final', () async {
      // Cree 2 tournees + stops dans la 2e, puis ne passe QUE la 1ere
      // dans computeFromBundle.
      final t1 = await seedTournee(nom: 'A');
      final t2 = await seedTournee(nom: 'B');
      await seedStop(tId: t2, statut: 'livre');
      await seedStop(tId: t2, statut: 'livre');

      final tournees =
          await (db.select(db.tournees)..where((t) => t.id.equals(t1))).get();
      final stops = await db.select(db.stops).get();
      final progs = ChefTourneeProgress.computeFromBundle(
        tournees: tournees, stops: stops,
      );
      expect(progs, hasLength(1));
      expect(progs.first.total, 0,
          reason: 'stops de t2 ne sont pas inclus puisque t2 hors bundle');
    });

    test('mix statuts : en_cours + terminees', () async {
      await seedTournee(nom: 'B-encours', statut: 'en_cours');
      await seedTournee(nom: 'A-encours', statut: 'en_cours');
      await seedTournee(nom: 'C-terminee', statut: 'terminee');
      final progs = await compute();
      expect(progs.map((p) => p.nom).toList(),
          ['A-encours', 'B-encours', 'C-terminee'],
          reason: 'en_cours d\'abord, tri alpha intra-groupe');
    });

    test('coequipierId : null par defaut (toujours Noah dans v1)', () async {
      await seedTournee(nom: 'T');
      final progs = await compute();
      expect(progs.first.coequipierId, isNull);
    });

    test('enPause = true quand pauseeLe est posee', () async {
      await seedTournee(
        nom: 'T',
        statut: 'en_cours',
        pauseeLe: DateTime(2026, 5, 29, 12),
      );
      final progs = await compute();
      expect(progs.first.enPause, isTrue);
    });

    test('compteurs : livres + echecs + a_livrer separes', () async {
      final t = await seedTournee(nom: 'T', statut: 'en_cours');
      await seedStop(tId: t, statut: 'livre');
      await seedStop(tId: t, statut: 'livre');
      await seedStop(tId: t, statut: 'echec');
      await seedStop(tId: t, statut: 'a_livrer');
      await seedStop(tId: t, statut: 'a_livrer');
      final progs = await compute();
      expect(progs.first.total, 5);
      expect(progs.first.livres, 2);
      expect(progs.first.echecs, 1);
    });
  });
}
