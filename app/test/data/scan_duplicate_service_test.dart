import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/scan_duplicate_check.dart';
import 'package:opti_route/data/scan_duplicate_service.dart';
import 'package:opti_route/data/stops_repository.dart';

import '../helpers/test_db.dart';

/// Branchement des controles de doublon (carte #315) : le service doit
/// aller chercher le bon jeu d'arrets en base puis rendre exactement ce
/// que rendent les fonctions pures de [ScanDuplicateCheck].
void main() {
  late AppDatabase db;
  late ScanDuplicateService service;
  late int tourneeHier;
  late int tourneeDuJour;

  // "Maintenant" fige pour que la fenetre de 30 jours soit
  // deterministe (pas de dependance a l'heure du runner CI).
  final now = DateTime(2026, 6, 30, 10);

  setUp(() async {
    db = makeTestDb();
    service = ScanDuplicateService(StopsRepository(db));
    tourneeHier = await seedTournee(db, nom: 'Hier', date: DateTime(2026, 6, 1));
    tourneeDuJour =
        await seedTournee(db, nom: 'Jour', date: DateTime(2026, 6, 30));
  });

  tearDown(() async {
    await db.close();
  });

  Future<Stop> seedStop({
    required int tourneeId,
    String adresse = '1 rue T',
    String? nomClient,
    String statut = 'a_livrer',
    DateTime? livreLe,
    String? trackings,
  }) async {
    final id = await db.into(db.stops).insert(
          StopsCompanion.insert(
            tourneeId: tourneeId,
            adresseBrute: adresse,
            nomClient: Value(nomClient),
            statutLivraison: Value(statut),
            livreLe: Value(livreLe),
            trackingNumbers: Value(trackings),
          ),
        );
    return (db.select(db.stops)..where((s) => s.id.equals(id))).getSingle();
  }

  group('ScanDuplicateService.findRecentDelivered', () {
    test('trouve une livraison recente faite dans une AUTRE tournee',
        () async {
      final dejaLivre = await seedStop(
        tourneeId: tourneeHier,
        nomClient: 'Dupont',
        statut: 'livre',
        livreLe: now.subtract(const Duration(days: 5)),
        trackings: '["FA280000440358"]',
      );
      final found =
          await service.findRecentDelivered('FA280000440358', now: now);
      expect(found?.id, dejaLivre.id);
    });

    test('remonte aussi une livraison de la tournee EN COURS', () async {
      // Decision produit assumee : la fenetre ne saute pas la tournee du
      // jour. Un arret valide il y a 20 minutes qu'on re-scanne est bien
      // une re-livraison potentielle -- c'est meme le cas ou l'alerte
      // sert le plus. En contrepartie le libelle doit dire
      // "aujourd'hui" et pas une date seche (cf relivraisonSummary).
      final dejaLivre = await seedStop(
        tourneeId: tourneeDuJour,
        nomClient: 'Dupont',
        statut: 'livre',
        livreLe: now.subtract(const Duration(minutes: 20)),
        trackings: '["FA280000440358"]',
      );
      final found =
          await service.findRecentDelivered('FA280000440358', now: now);
      expect(found?.id, dejaLivre.id);
    });

    test('null hors de la fenetre de 30 jours', () async {
      await seedStop(
        tourneeId: tourneeHier,
        statut: 'livre',
        livreLe: now.subtract(const Duration(days: 40)),
        trackings: '["FA280000440358"]',
      );
      expect(
        await service.findRecentDelivered('FA280000440358', now: now),
        isNull,
      );
    });

    test('null si l\'arret porteur du numero n\'est pas livre', () async {
      await seedStop(
        tourneeId: tourneeDuJour,
        livreLe: now.subtract(const Duration(days: 1)),
        trackings: '["FA280000440358"]',
      );
      expect(
        await service.findRecentDelivered('FA280000440358', now: now),
        isNull,
      );
    });

    test('null si le code scanne est vide', () async {
      await seedStop(
        tourneeId: tourneeHier,
        statut: 'livre',
        livreLe: now.subtract(const Duration(days: 1)),
        trackings: '["FA280000440358"]',
      );
      expect(await service.findRecentDelivered('   ', now: now), isNull);
    });

    test('null quand aucun arret ne porte ce numero', () async {
      await seedStop(
        tourneeId: tourneeHier,
        statut: 'livre',
        livreLe: now.subtract(const Duration(days: 1)),
        trackings: '["FA280000440358"]',
      );
      expect(await service.findRecentDelivered('XYZ999', now: now), isNull);
    });
  });

  group('ScanDuplicateService.verifyBarcode', () {
    test('match quand le code appartient bien a l\'arret attendu', () async {
      final attendu = await seedStop(
        tourneeId: tourneeDuJour,
        trackings: '["FA1","FA2"]',
      );
      final r = await service.verifyBarcode(
        scannedBarcode: 'FA1',
        expectedStop: attendu,
      );
      expect(r.kind, ScanMatchKind.match);
    });

    test('wrongStop : suggere l\'arret de la tournee qui porte le code',
        () async {
      final attendu =
          await seedStop(tourneeId: tourneeDuJour, trackings: '["FA1"]');
      final voisin = await seedStop(
        tourneeId: tourneeDuJour,
        adresse: '2 rue U',
        trackings: '["FA2"]',
      );
      final r = await service.verifyBarcode(
        scannedBarcode: 'FA2',
        expectedStop: attendu,
      );
      expect(r.kind, ScanMatchKind.wrongStop);
      expect(r.suggestedStop?.id, voisin.id);
    });

    test('unknown : le code n\'est sur aucun arret de la tournee', () async {
      final attendu =
          await seedStop(tourneeId: tourneeDuJour, trackings: '["FA1"]');
      // Un arret d'une autre tournee porte le code : il ne doit PAS
      // etre suggere (on ne propose que des arrets de la meme tournee).
      await seedStop(tourneeId: tourneeHier, trackings: '["FA9"]');
      final r = await service.verifyBarcode(
        scannedBarcode: 'FA9',
        expectedStop: attendu,
      );
      expect(r.kind, ScanMatchKind.unknown);
      expect(r.suggestedStop, isNull);
    });
  });
}
