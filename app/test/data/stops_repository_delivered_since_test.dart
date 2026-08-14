import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/stops_repository.dart';

import '../helpers/test_db.dart';

/// Fenetre de recherche des re-livraisons (carte #315) :
/// [StopsRepository.getDeliveredSince] doit filtrer statut + date en
/// SQL, agreger toutes les tournees, et savoir se restreindre a un
/// numero de tracking precis.
void main() {
  late AppDatabase db;
  late StopsRepository repo;
  late int tourneeA;
  late int tourneeB;

  // Borne de la fenetre testee : on garde `livreLe >= cutoff`.
  final cutoff = DateTime(2026, 6, 1, 12);

  setUp(() async {
    db = makeTestDb();
    repo = StopsRepository(db);
    tourneeA = await seedTournee(db, nom: 'A', date: DateTime(2026, 6, 1));
    tourneeB = await seedTournee(db, nom: 'B', date: DateTime(2026, 6, 2));
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> seedStop({
    required int tourneeId,
    String adresse = '1 rue T',
    String statut = 'livre',
    DateTime? livreLe,
    String? trackings,
  }) {
    return db.into(db.stops).insert(
          StopsCompanion.insert(
            tourneeId: tourneeId,
            adresseBrute: adresse,
            statutLivraison: Value(statut),
            livreLe: Value(livreLe),
            trackingNumbers: Value(trackings),
          ),
        );
  }

  group('StopsRepository.getDeliveredSince - fenetre temporelle', () {
    test('exclut juste avant le cutoff, garde le cutoff et juste apres',
        () async {
      final avant = await seedStop(
        tourneeId: tourneeA,
        adresse: 'avant',
        livreLe: cutoff.subtract(const Duration(seconds: 1)),
      );
      final pile = await seedStop(
        tourneeId: tourneeA,
        adresse: 'pile',
        livreLe: cutoff,
      );
      final apres = await seedStop(
        tourneeId: tourneeA,
        adresse: 'apres',
        livreLe: cutoff.add(const Duration(seconds: 1)),
      );

      final ids = (await repo.getDeliveredSince(cutoff)).map((s) => s.id);
      expect(ids, containsAll([pile, apres]));
      expect(ids, isNot(contains(avant)));
    });

    test('ignore les arrets non livres, meme dans la fenetre', () async {
      final aLivrer = await seedStop(
        tourneeId: tourneeA,
        adresse: 'a livrer',
        statut: 'a_livrer',
        livreLe: cutoff.add(const Duration(hours: 1)),
      );
      final echec = await seedStop(
        tourneeId: tourneeA,
        adresse: 'echec',
        statut: 'echec',
        livreLe: cutoff.add(const Duration(hours: 2)),
      );
      final livre = await seedStop(
        tourneeId: tourneeA,
        adresse: 'livre',
        livreLe: cutoff.add(const Duration(hours: 3)),
      );

      final ids = (await repo.getDeliveredSince(cutoff)).map((s) => s.id);
      expect(ids, [livre]);
      expect(ids, isNot(contains(aLivrer)));
      expect(ids, isNot(contains(echec)));
    });

    test('ignore un arret livre sans horodatage (livreLe null)', () async {
      await seedStop(tourneeId: tourneeA, adresse: 'sans date');
      expect(await repo.getDeliveredSince(cutoff), isEmpty);
    });

    test('agrege toutes les tournees, pas seulement la courante', () async {
      final a = await seedStop(
        tourneeId: tourneeA,
        livreLe: cutoff.add(const Duration(hours: 1)),
      );
      final b = await seedStop(
        tourneeId: tourneeB,
        livreLe: cutoff.add(const Duration(hours: 2)),
      );
      final ids = (await repo.getDeliveredSince(cutoff)).map((s) => s.id);
      expect(ids, containsAll([a, b]));
    });

    test('trie du plus recent au plus ancien', () async {
      final vieux = await seedStop(
        tourneeId: tourneeA,
        adresse: 'vieux',
        livreLe: cutoff.add(const Duration(hours: 1)),
      );
      final recent = await seedStop(
        tourneeId: tourneeB,
        adresse: 'recent',
        livreLe: cutoff.add(const Duration(hours: 5)),
      );
      final rows = await repo.getDeliveredSince(cutoff);
      expect(rows.map((s) => s.id).toList(), [recent, vieux]);
    });
  });

  group('StopsRepository.getDeliveredSince - filtre tracking', () {
    test('ne garde que les arrets qui portent ce numero', () async {
      final porteur = await seedStop(
        tourneeId: tourneeA,
        livreLe: cutoff.add(const Duration(hours: 1)),
        trackings: '["FA280001","FA280002"]',
      );
      await seedStop(
        tourneeId: tourneeB,
        livreLe: cutoff.add(const Duration(hours: 2)),
        trackings: '["FA280003"]',
      );
      final rows =
          await repo.getDeliveredSince(cutoff, trackingNumber: 'FA280002');
      expect(rows.map((s) => s.id), [porteur]);
    });

    test('une sous-chaine d\'un autre numero ne matche PAS', () async {
      await seedStop(
        tourneeId: tourneeA,
        livreLe: cutoff.add(const Duration(hours: 1)),
        trackings: '["FA280001"]',
      );
      expect(
        await repo.getDeliveredSince(cutoff, trackingNumber: 'FA28000'),
        isEmpty,
      );
    });

    test('insensible a la casse (comme le check pur en aval)', () async {
      final minuscule = await seedStop(
        tourneeId: tourneeA,
        livreLe: cutoff.add(const Duration(hours: 1)),
        trackings: '["fa280001"]',
      );
      final rows =
          await repo.getDeliveredSince(cutoff, trackingNumber: 'FA280001');
      expect(rows.map((s) => s.id), [minuscule]);
    });

    test('tolere un JSON tracking_numbers casse (pas de faux positif)',
        () async {
      await seedStop(
        tourneeId: tourneeA,
        livreLe: cutoff.add(const Duration(hours: 1)),
        trackings: 'pas-du-json"FA280001"',
      );
      expect(
        await repo.getDeliveredSince(cutoff, trackingNumber: 'FA280001'),
        isEmpty,
      );
    });

    test('le filtre tracking ne shunte pas la fenetre ni le statut',
        () async {
      // Meme numero, mais hors fenetre d'un cote et non livre de l'autre.
      await seedStop(
        tourneeId: tourneeA,
        livreLe: cutoff.subtract(const Duration(days: 1)),
        trackings: '["FA280001"]',
      );
      await seedStop(
        tourneeId: tourneeB,
        statut: 'a_livrer',
        livreLe: cutoff.add(const Duration(hours: 1)),
        trackings: '["FA280001"]',
      );
      expect(
        await repo.getDeliveredSince(cutoff, trackingNumber: 'FA280001'),
        isEmpty,
      );
    });
  });
}
