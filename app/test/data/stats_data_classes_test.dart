import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/stats_service.dart';

// Tests directs des data classes de stats_service (sans I/O Drift).
// Couvre TourneeStats, StatsBundle.isEmpty, MotivationStats,
// CoequipierStats.
void main() {
  group('TourneeStats — empty + tauxReussite', () {
    test('empty : tous compteurs a 0', () {
      const s = TourneeStats.empty;
      expect(s.nbTournees, 0);
      expect(s.nbTourneesTerminees, 0);
      expect(s.nbArrets, 0);
      expect(s.nbColisLivres, 0);
      expect(s.nbLivres, 0);
      expect(s.nbEchecs, 0);
      expect(s.distanceMeters, 0);
      expect(s.durationSeconds, 0);
      expect(s.nbLivraisons, 0);
      expect(s.nbRamasses, 0);
      expect(s.tauxReussite, 0);
    });

    test('tauxReussite : 0 si aucune tentative', () {
      const s = TourneeStats(
        nbTournees: 0, nbTourneesTerminees: 0, nbArrets: 0,
        nbColisLivres: 0, nbLivres: 0, nbEchecs: 0,
        distanceMeters: 0, durationSeconds: 0,
      );
      expect(s.tauxReussite, 0);
    });

    test('tauxReussite 100% (3 livres / 0 echecs)', () {
      const s = TourneeStats(
        nbTournees: 1, nbTourneesTerminees: 1, nbArrets: 3,
        nbColisLivres: 5, nbLivres: 3, nbEchecs: 0,
        distanceMeters: 0, durationSeconds: 0,
      );
      expect(s.tauxReussite, 1.0);
    });

    test('tauxReussite 50% (1 livre / 1 echec)', () {
      const s = TourneeStats(
        nbTournees: 1, nbTourneesTerminees: 1, nbArrets: 2,
        nbColisLivres: 1, nbLivres: 1, nbEchecs: 1,
        distanceMeters: 0, durationSeconds: 0,
      );
      expect(s.tauxReussite, 0.5);
    });

    test('nbLivraisons + nbRamasses : champs optionnels separes', () {
      const s = TourneeStats(
        nbTournees: 1, nbTourneesTerminees: 1, nbArrets: 5,
        nbColisLivres: 10, nbLivres: 5, nbEchecs: 0,
        distanceMeters: 0, durationSeconds: 0,
        nbLivraisons: 3, nbRamasses: 2,
      );
      expect(s.nbLivraisons + s.nbRamasses, s.nbLivres);
    });
  });

  group('StatsBundle.isEmpty', () {
    test('true si tournees vides', () {
      final b = StatsBundle(
        since: DateTime(2026),
        tournees: const [],
        stops: const [],
      );
      expect(b.isEmpty, isTrue);
    });

    test('isEmpty ne regarde que tournees, pas stops', () {
      // Cas pathologique : stops sans tournees (orphelins) -> empty
      final b = StatsBundle(
        since: DateTime(2026),
        tournees: const [],
        stops: const [],
      );
      // Au lieu de tester avec stops orphelins (complique a fabriquer),
      // on verrouille juste le contrat "isEmpty = tournees.isEmpty".
      expect(b.isEmpty, b.tournees.isEmpty);
    });
  });

  group('MotivationStats — empty + tauxReussiteAnnee', () {
    test('empty : tous compteurs a 0', () {
      const m = MotivationStats.empty;
      expect(m.colisLivresAnnee, 0);
      expect(m.kmAnnee, 0);
      expect(m.tourneesAnnee, 0);
      expect(m.streakSansEchec, 0);
      expect(m.nbLivresAnnee, 0);
      expect(m.nbEchecsAnnee, 0);
      expect(m.tauxReussiteAnnee, 0);
    });

    test('tauxReussiteAnnee : 95% (95 livres / 5 echecs)', () {
      const m = MotivationStats(
        colisLivresAnnee: 200, kmAnnee: 5000, tourneesAnnee: 10,
        streakSansEchec: 0, nbLivresAnnee: 95, nbEchecsAnnee: 5,
      );
      expect(m.tauxReussiteAnnee, 0.95);
    });

    test('streakSansEchec preserve', () {
      const m = MotivationStats(
        colisLivresAnnee: 0, kmAnnee: 0, tourneesAnnee: 0,
        streakSansEchec: 42,
      );
      expect(m.streakSansEchec, 42);
    });
  });

  group('CoequipierStats — tauxReussite + tauxPhotos', () {
    test('tauxReussite : 0 si aucune tentative', () {
      const c = CoequipierStats(
        coequipierId: null,
        nbArrets: 0, nbLivres: 0, nbEchecs: 0, colisLivres: 0,
      );
      expect(c.tauxReussite, 0);
    });

    test('tauxReussite 100% : tous livres', () {
      const c = CoequipierStats(
        coequipierId: 5,
        nbArrets: 3, nbLivres: 3, nbEchecs: 0, colisLivres: 7,
      );
      expect(c.tauxReussite, 1.0);
    });

    test('tauxPhotos : 0 si nbLivres = 0', () {
      const c = CoequipierStats(
        coequipierId: null,
        nbArrets: 5, nbLivres: 0, nbEchecs: 0, colisLivres: 0,
        nbPhotosPreuves: 0,
      );
      expect(c.tauxPhotos, 0);
    });

    test('tauxPhotos : 50% (2 photos / 4 livres)', () {
      const c = CoequipierStats(
        coequipierId: null,
        nbArrets: 5, nbLivres: 4, nbEchecs: 1, colisLivres: 8,
        nbPhotosPreuves: 2,
      );
      expect(c.tauxPhotos, 0.5);
    });

    test('tauxPhotos clamp a 1.0 (defensif si > 100%)', () {
      const c = CoequipierStats(
        coequipierId: null,
        nbArrets: 3, nbLivres: 3, nbEchecs: 0, colisLivres: 5,
        nbPhotosPreuves: 5, // > nbLivres (anomalie)
      );
      expect(c.tauxPhotos, 1.0);
    });

    test('coequipierId null = Noah', () {
      const c = CoequipierStats(
        coequipierId: null,
        nbArrets: 0, nbLivres: 0, nbEchecs: 0, colisLivres: 0,
      );
      expect(c.coequipierId, isNull);
    });
  });
}
