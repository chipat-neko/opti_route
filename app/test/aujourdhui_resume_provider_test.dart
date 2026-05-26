import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/providers/database_providers.dart';

/// Tests du provider `aujourdhuiResumeProvider` (carte Trello #100).
///
/// On valide :
/// - Empty quand aucune tournee du jour
/// - Aggregation correcte (colis, distance, duree, premier/dernier
///   horodatage) sur 2 tournees du jour
/// - Filtre temporel : une tournee hier ne contribue pas
void main() {
  group('aujourdhuiResumeProvider', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('empty si aucune tournee aujourd\'hui', () async {
      // Attend que le stream emette sa premiere valeur (liste vide).
      await _waitForTourneesCount(container, 0);

      final r = await container.read(aujourdhuiResumeProvider.future);
      expect(r.isEmpty, isTrue);
      expect(r.hasActivite, isFalse);
      expect(r.avancement, 0);
      expect(r.nbArretsRestants, 0);
    });

    test('aggregation 2 tournees du jour (matin + aprem)', () async {
      final today = DateTime.now();
      final dateToday =
          DateTime(today.year, today.month, today.day, 8, 0);

      // Tournee matin terminee
      final t1 = await db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: 'Matin',
              date: dateToday,
              pointDepartLat: 48.0,
              pointDepartLng: 1.0,
              pointDepartLabel: 'D',
              statut: const Value('terminee'),
              distanceTotaleM: const Value(25000),
              dureeTotaleS: const Value(3600),
            ),
          );
      await _insertStopLivre(db, t1,
          nbColis: 3, livreLe: dateToday.add(const Duration(hours: 1)));
      await _insertStopLivre(db, t1,
          nbColis: 2, livreLe: dateToday.add(const Duration(hours: 2)));

      // Tournee aprem en cours
      final t2 = await db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: 'Aprem',
              date: dateToday,
              pointDepartLat: 48.0,
              pointDepartLng: 1.0,
              pointDepartLabel: 'D',
              statut: const Value('en_cours'),
              distanceTotaleM: const Value(15000),
              dureeTotaleS: const Value(1800),
            ),
          );
      await _insertStopLivre(db, t2,
          nbColis: 4, livreLe: dateToday.add(const Duration(hours: 6)));
      await _insertStopEchec(db, t2);
      // Stop encore a_livrer (default)
      await db.into(db.stops).insert(
            StopsCompanion.insert(
              tourneeId: t2,
              adresseBrute: 'A',
              nbColis: const Value(1),
            ),
          );

      // Pump le stream jusqu'a obtenir les 2 tournees (le watch Drift
      // emet a chaque insert).
      await _waitForTourneesCount(container, 2);

      final r = await container.read(aujourdhuiResumeProvider.future);
      expect(r.isEmpty, isFalse);
      expect(r.nbTournees, 2);
      expect(r.nbTourneesTerminees, 1);
      expect(r.nbTourneesEnCours, 1);
      expect(r.nbArretsTotaux, 5);
      expect(r.nbLivres, 3);
      expect(r.nbEchecs, 1);
      expect(r.nbColisLivres, 9); // 3+2+4
      expect(r.distanceMeters, 40000); // 25000+15000
      expect(r.durationSeconds, 5400); // 3600+1800
      expect(r.hasActivite, isTrue);
      expect(r.nbArretsRestants, 1);
      // avancement = (3 + 1) / 5 = 0.8
      expect(r.avancement, closeTo(0.8, 0.001));
      // tauxReussite = 3 / (3 + 1) = 0.75
      expect(r.tauxReussite, closeTo(0.75, 0.001));
      expect(r.premierLivreLe, isNotNull);
      expect(r.dernierLivreLe, isNotNull);
      expect(r.premierLivreLe!.isBefore(r.dernierLivreLe!), isTrue);
    });

    test('tournee d\'hier ne contribue pas au resume du jour', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final tId = await db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: 'Hier',
              date: yesterday,
              pointDepartLat: 48.0,
              pointDepartLng: 1.0,
              pointDepartLabel: 'D',
              statut: const Value('terminee'),
            ),
          );
      await _insertStopLivre(db, tId, nbColis: 10);

      await _waitForTourneesCount(container, 1);

      final r = await container.read(aujourdhuiResumeProvider.future);
      // 1 tournee dans la base, mais datee d'hier -> tourneesDuJour vide
      // -> resume empty.
      expect(r.isEmpty, isTrue);
      expect(r.nbColisLivres, 0);
    });
  });

  group('AujourdhuiResume derives', () {
    test('avancement borne entre 0 et 1', () {
      const r = AujourdhuiResume(
        nbTournees: 1,
        nbTourneesTerminees: 0,
        nbTourneesEnCours: 1,
        nbArretsTotaux: 10,
        nbLivres: 7,
        nbEchecs: 2,
        nbColisLivres: 20,
        distanceMeters: 50000,
        durationSeconds: 7200,
      );
      expect(r.avancement, closeTo(0.9, 0.001));
      expect(r.nbArretsRestants, 1);
      expect(r.tauxReussite, closeTo(7 / 9, 0.001));
    });

    test('nbArretsRestants jamais negatif', () {
      const r = AujourdhuiResume(
        nbTournees: 1,
        nbTourneesTerminees: 1,
        nbTourneesEnCours: 0,
        nbArretsTotaux: 5,
        nbLivres: 4,
        nbEchecs: 2, // overflow theorique (livres + echecs > total)
        nbColisLivres: 8,
        distanceMeters: 0,
        durationSeconds: 0,
      );
      expect(r.nbArretsRestants, 0);
    });
  });
}

/// Poll le `tourneesStreamProvider` toutes les 50 ms jusqu'a atteindre
/// le nombre de tournees attendu (ou timeout 5s). Necessaire car le
/// stream Drift n'est pas resolu de facon synchrone apres un insert.
Future<void> _waitForTourneesCount(
  ProviderContainer container,
  int expected, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  // Sans listener actif, le provider est "auto-paused" -> le stream
  // n'est jamais abonne. On force l'abonnement via listen() puis poll.
  final sub = container.listen<AsyncValue<List<Tournee>>>(
    tourneesStreamProvider,
    (_, _) {},
    fireImmediately: true,
  );
  try {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final state = sub.read();
      final list = state.asData?.value;
      if (list != null && list.length == expected) return;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    throw StateError(
      'Timeout waiting for $expected tournees in stream provider',
    );
  } finally {
    sub.close();
  }
}

Future<int> _insertStopLivre(
  AppDatabase db,
  int tourneeId, {
  required int nbColis,
  DateTime? livreLe,
}) async {
  final sId = await db.into(db.stops).insert(
        StopsCompanion.insert(
          tourneeId: tourneeId,
          adresseBrute: 'Adresse',
          nbColis: Value(nbColis),
        ),
      );
  await (db.update(db.stops)..where((s) => s.id.equals(sId))).write(
    StopsCompanion(
      statutLivraison: const Value('livre'),
      livreLe: Value(livreLe),
    ),
  );
  return sId;
}

Future<int> _insertStopEchec(AppDatabase db, int tourneeId) async {
  final sId = await db.into(db.stops).insert(
        StopsCompanion.insert(
          tourneeId: tourneeId,
          adresseBrute: 'AdresseE',
        ),
      );
  await (db.update(db.stops)..where((s) => s.id.equals(sId))).write(
    const StopsCompanion(
      statutLivraison: Value('echec'),
    ),
  );
  return sId;
}
