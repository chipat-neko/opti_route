import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/parametres_repository.dart';
import 'package:opti_route/data/tournee_text_share_service.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr');
  });

  group('TourneeTextShareService.formatPlainText', () {
    late AppDatabase db;
    late TourneeTextShareService svc;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      svc = TourneeTextShareService();
    });

    tearDown(() async {
      await db.close();
    });

    Future<(Tournee, List<Stop>)> seedSimpleTournee() async {
      final id = await db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: 'Tournee test',
              date: DateTime(2026, 5, 12),
              pointDepartLat: 48.0,
              pointDepartLng: 1.0,
              pointDepartLabel: 'Depot',
              distanceTotaleM: const Value(45000),
              dureeTotaleS: const Value(5400),
            ),
          );
      await db.into(db.stops).insert(
            StopsCompanion.insert(
              tourneeId: id,
              adresseBrute: '12 rue des Lilas, 28100 Dreux',
              nomClient: const Value('CALOTE Noah'),
              nbColis: const Value(3),
              fenetreFin: const Value('12:00'),
            ),
          );
      await db.into(db.stops).insert(
            StopsCompanion.insert(
              tourneeId: id,
              adresseBrute: '4 av. de la Gare, 28100 Dreux',
              nomClient: const Value('Carrefour'),
              nbColis: const Value(1),
            ),
          );
      final tournee = await (db.select(db.tournees)
            ..where((t) => t.id.equals(id)))
          .getSingle();
      final stops = await (db.select(db.stops)
            ..where((s) => s.tourneeId.equals(id))
            ..orderBy([(s) => OrderingTerm.asc(s.id)]))
          .get();
      return (tournee, stops);
    }

    test('header contient nom + date + nb arrets + colis + distance', () async {
      final (t, stops) = await seedSimpleTournee();
      final out = await svc.formatPlainText(tournee: t, stops: stops);
      expect(out, contains('Tournee "Tournee test"'));
      expect(out, contains('mardi 12 mai 2026'));
      expect(out, contains('2 arrets'));
      expect(out, contains('4 colis')); // 3 + 1
      expect(out, contains('45.0 km'));
      expect(out, contains('1h30'));
    });

    test('format arret : numero, titre, adresse, colis, fenetre', () async {
      final (t, stops) = await seedSimpleTournee();
      final out = await svc.formatPlainText(tournee: t, stops: stops);
      expect(out, contains('1. CALOTE Noah'));
      expect(out, contains('12 rue des Lilas, 28100 Dreux'));
      expect(out, contains('3 colis - avant 12:00'));
      expect(out, contains('2. Carrefour'));
    });

    test('arret sans nom : adresse comme titre, pas de duplication',
        () async {
      final id = await db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: 'T',
              date: DateTime(2026, 5, 12),
              pointDepartLat: 48.0,
              pointDepartLng: 1.0,
              pointDepartLabel: 'Depot',
            ),
          );
      await db.into(db.stops).insert(
            StopsCompanion.insert(
              tourneeId: id,
              adresseBrute: '1 rue du Test, 28100 Dreux',
            ),
          );
      final tournee =
          await (db.select(db.tournees)..where((t) => t.id.equals(id)))
              .getSingle();
      final stops = await (db.select(db.stops)
            ..where((s) => s.tourneeId.equals(id)))
          .get();

      final out =
          await svc.formatPlainText(tournee: tournee, stops: stops);
      // L'adresse apparait 1 seule fois en titre, pas en ligne adresse
      expect('1 rue du Test, 28100 Dreux'.allMatches(out).length, 1);
    });

    test('avec ParametresRepository : cout carburant dans le header',
        () async {
      final params = ParametresRepository(db);
      await params.setCoutCarburantLitre(1.85);
      await params.setConsoLitresPar100Km(7);

      final svc2 = TourneeTextShareService(parametres: params);

      final id = await db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: 'T',
              date: DateTime(2026, 5, 12),
              pointDepartLat: 48.0,
              pointDepartLng: 1.0,
              pointDepartLabel: 'Depot',
              distanceTotaleM: const Value(50000), // 50 km
              dureeTotaleS: const Value(3600), // 1h
            ),
          );
      await db.into(db.stops).insert(
            StopsCompanion.insert(
              tourneeId: id,
              adresseBrute: 'A',
            ),
          );
      final tournee = await (db.select(db.tournees)
            ..where((t) => t.id.equals(id)))
          .getSingle();
      final stops = await (db.select(db.stops)
            ..where((s) => s.tourneeId.equals(id)))
          .get();

      final out = await svc2.formatPlainText(tournee: tournee, stops: stops);
      // 50 km * 7L/100 = 3.5L * 1.85 = 6.475 EUR -> "6,48 EUR" formate
      expect(out, contains('6,48 EUR'));
    });

    test('sans ParametresRepository : pas de cout dans le header', () async {
      final (t, stops) = await seedSimpleTournee();
      final out = await svc.formatPlainText(tournee: t, stops: stops);
      expect(out, isNot(contains('EUR')));
    });

    test('tournee vide (0 arret) : header sans crash, pas de liste',
        () async {
      final id = await db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: 'T vide',
              date: DateTime(2026, 5, 12),
              pointDepartLat: 48.0,
              pointDepartLng: 1.0,
              pointDepartLabel: 'Depot',
            ),
          );
      final tournee = await (db.select(db.tournees)
            ..where((t) => t.id.equals(id)))
          .getSingle();

      final out =
          await svc.formatPlainText(tournee: tournee, stops: const []);
      expect(out, contains('T vide'));
      expect(out, contains('0 arret')); // singulier
      expect(out, contains('0 colis'));
      // Pas de "1." ni "2." dans le texte
      expect(out, isNot(contains('\n1. ')));
    });

    test('priorites speciales : EN 1ER / EN DERNIER / A EVITER', () async {
      final id = await db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: 'T',
              date: DateTime(2026, 5, 12),
              pointDepartLat: 48.0,
              pointDepartLng: 1.0,
              pointDepartLabel: 'Depot',
            ),
          );
      await db.into(db.stops).insert(
            StopsCompanion.insert(
              tourneeId: id,
              adresseBrute: 'A',
              priorite: const Value('obligatoire_premier'),
            ),
          );
      await db.into(db.stops).insert(
            StopsCompanion.insert(
              tourneeId: id,
              adresseBrute: 'B',
              priorite: const Value('obligatoire_dernier'),
            ),
          );
      await db.into(db.stops).insert(
            StopsCompanion.insert(
              tourneeId: id,
              adresseBrute: 'C',
              priorite: const Value('eviter_si_possible'),
            ),
          );
      final tournee =
          await (db.select(db.tournees)..where((t) => t.id.equals(id)))
              .getSingle();
      final stops = await (db.select(db.stops)
            ..where((s) => s.tourneeId.equals(id))
            ..orderBy([(s) => OrderingTerm.asc(s.id)]))
          .get();

      final out =
          await svc.formatPlainText(tournee: tournee, stops: stops);
      expect(out, contains('EN 1ER'));
      expect(out, contains('EN DERNIER'));
      expect(out, contains('A EVITER'));
    });
  });
}
