// Test d'integration : flow complet des notes de frais (carburant +
// peages + parking) + filtrage par mois / tournee + total par categorie.
//
// Couvre les scenarios reels de Noah :
//   - Plein de gazole le matin avant la tournee, lie a la tournee
//   - Peage A11 pendant la tournee
//   - Parking au depot le soir
//   - Recap mensuel pour la compta : total carburant + total peages

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/frais_repository.dart';
import 'package:opti_route/data/tournees_repository.dart';

void main() {
  group('Flow integration : notes de frais (carburant + peage + parking)',
      () {
    late AppDatabase db;
    late FraisRepository frais;
    late TourneesRepository tournees;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      frais = FraisRepository(db);
      tournees = TourneesRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('flow journee : carburant + peage + parking lies a la tournee',
        () async {
      // 1. Cree une tournee a Dreux (28).
      final tId = await tournees.create(TourneesCompanion.insert(
        nom: 'Tournee Dreux',
        date: DateTime(2026, 5, 13),
        pointDepartLat: 48.737,
        pointDepartLng: 1.366,
        pointDepartLabel: 'Depot Chartres',
      ));

      // 2. Plein de gazole le matin : 65L a 1.752 EUR/L = 113.88 EUR.
      final fuelId = await frais.create(
        date: DateTime(2026, 5, 13, 7, 30),
        type: 'carburant',
        montantCentimes: 11388,
        libelle: 'Plein Diesel TOTAL',
        notes: '65 litres a 1.752 EUR/L',
        tourneeId: tId,
      );

      // 3. Peage A11 Chartres-Le Mans pendant la tournee.
      await frais.create(
        date: DateTime(2026, 5, 13, 10, 15),
        type: 'peage',
        montantCentimes: 950,
        libelle: 'Peage A11 sortie Le Mans',
        tourneeId: tId,
      );

      // 4. Parking depot le soir.
      await frais.create(
        date: DateTime(2026, 5, 13, 18, 0),
        type: 'parking',
        montantCentimes: 350,
        libelle: 'Parking depot Chartres',
        tourneeId: tId,
      );

      // 5. Verifie watchByTournee : 3 entrees, triees date desc.
      final tourneeFrais = await frais.watchByTournee(tId).first;
      expect(tourneeFrais, hasLength(3));
      expect(tourneeFrais.first.type, 'parking',
          reason: 'tri date desc -> parking 18h en premier');
      expect(tourneeFrais.last.type, 'carburant');

      // 6. Total tournee : 113.88 + 9.50 + 3.50 = 126.88 EUR.
      final totalTournee = tourneeFrais.fold<int>(
        0,
        (sum, f) => sum + f.montantCentimes,
      );
      expect(totalTournee, 12688);

      // 7. Update du plein : Noah s'est trompe, c'etait 1.762 EUR/L donc
      //    65L * 1.762 = 114.53 EUR (11453 centimes).
      await frais.update(fuelId,
          montantCentimes: 11453,
          notes: '65 litres a 1.762 EUR/L (corrige)');
      final updated = await frais.getById(fuelId);
      expect(updated!.montantCentimes, 11453);
      expect(updated.notes, contains('corrige'));
    });

    test('totalCentimes filtre par type sur le mois', () async {
      // Trois mois differents, 3 types differents.
      await frais.create(
        date: DateTime(2026, 4, 15),
        type: 'carburant',
        montantCentimes: 10000,
        libelle: 'avril',
      );
      await frais.create(
        date: DateTime(2026, 5, 5),
        type: 'carburant',
        montantCentimes: 11000,
        libelle: 'mai 1',
      );
      await frais.create(
        date: DateTime(2026, 5, 20),
        type: 'carburant',
        montantCentimes: 12000,
        libelle: 'mai 2',
      );
      await frais.create(
        date: DateTime(2026, 5, 20),
        type: 'peage',
        montantCentimes: 500,
        libelle: 'mai peage',
      );

      // Total carburant mai = 11000 + 12000 = 23000 centimes.
      final totalCarbMai = await frais.totalCentimes(
        from: DateTime(2026, 5),
        to: DateTime(2026, 6),
        type: 'carburant',
      );
      expect(totalCarbMai, 23000);

      // Total tous types mai = 23000 + 500 = 23500 centimes.
      final totalMai = await frais.totalCentimes(
        from: DateTime(2026, 5),
        to: DateTime(2026, 6),
      );
      expect(totalMai, 23500);

      // Total peage avril = 0 (pas d'entree).
      final totalPeageAvril = await frais.totalCentimes(
        from: DateTime(2026, 4),
        to: DateTime(2026, 5),
        type: 'peage',
      );
      expect(totalPeageAvril, 0);
    });

    test('watchByMonth : ne retourne que les frais du mois', () async {
      await frais.create(
        date: DateTime(2026, 4, 30, 23, 59),
        type: 'carburant',
        montantCentimes: 5000,
        libelle: 'avril fin',
      );
      await frais.create(
        date: DateTime(2026, 5, 1, 0, 1),
        type: 'carburant',
        montantCentimes: 6000,
        libelle: 'mai debut',
      );
      await frais.create(
        date: DateTime(2026, 5, 15),
        type: 'parking',
        montantCentimes: 200,
        libelle: 'mai milieu',
      );
      await frais.create(
        date: DateTime(2026, 6, 1, 0, 0),
        type: 'carburant',
        montantCentimes: 7000,
        libelle: 'juin debut',
      );

      final maiFrais = await frais.watchByMonth(2026, 5).first;
      expect(maiFrais, hasLength(2));
      expect(maiFrais.map((f) => f.libelle).toSet(),
          {'mai debut', 'mai milieu'});

      final juinFrais = await frais.watchByMonth(2026, 6).first;
      expect(juinFrais, hasLength(1));
      expect(juinFrais.first.libelle, 'juin debut');
    });

    test('delete : retire de la liste + des totaux', () async {
      final id = await frais.create(
        date: DateTime(2026, 5, 10),
        type: 'autre',
        montantCentimes: 1500,
        libelle: 'a supprimer',
      );
      expect(
        await frais.totalCentimes(
          from: DateTime(2026, 5),
          to: DateTime(2026, 6),
        ),
        1500,
      );

      final removed = await frais.delete(id);
      expect(removed, 1);
      expect(
        await frais.totalCentimes(
          from: DateTime(2026, 5),
          to: DateTime(2026, 6),
        ),
        0,
      );
    });

    test('frais sans tournee : pas remonte dans watchByTournee', () async {
      final tId = await tournees.create(TourneesCompanion.insert(
        nom: 'T',
        date: DateTime(2026, 5, 13),
        pointDepartLat: 48.0,
        pointDepartLng: 1.0,
        pointDepartLabel: 'D',
      ));
      await frais.create(
        date: DateTime(2026, 5, 13),
        type: 'carburant',
        montantCentimes: 5000,
        libelle: 'lie',
        tourneeId: tId,
      );
      await frais.create(
        date: DateTime(2026, 5, 13),
        type: 'parking',
        montantCentimes: 200,
        libelle: 'orphelin (pas de tournee)',
      );

      final tourneeFrais = await frais.watchByTournee(tId).first;
      expect(tourneeFrais, hasLength(1));
      expect(tourneeFrais.first.libelle, 'lie');
    });
  });
}
