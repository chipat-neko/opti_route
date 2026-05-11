import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/eta_calculator.dart';

/// Tests purs (pas de DB) sur la logique d'estimation d'ETA.
/// Les distances sont approximatives ; les attentes ciblent l'ordre
/// et la coherence, pas la precision metrique.
void main() {
  group('computeEtaForStops', () {
    test('liste vide -> map vide', () {
      final etas = computeEtaForStops(_tournee(), const []);
      expect(etas, isEmpty);
    });

    test('aucun arret a_livrer -> map vide', () {
      final etas = computeEtaForStops(_tournee(), [
        _stop(id: 1, statut: 'livre', lat: 48.5, lng: 1.5),
        _stop(id: 2, statut: 'echec', lat: 48.6, lng: 1.6),
      ]);
      expect(etas, isEmpty);
    });

    test('arret a_livrer sans coords -> map vide (on ne ment pas)', () {
      final etas = computeEtaForStops(_tournee(), [
        _stop(id: 1, statut: 'a_livrer', lat: null, lng: null),
      ]);
      expect(etas, isEmpty);
    });

    test('un seul arret a_livrer avec coords -> ETA dans la map', () {
      final etas = computeEtaForStops(_tournee(), [
        _stop(id: 1, statut: 'a_livrer', lat: 48.5, lng: 1.5),
      ]);
      expect(etas.containsKey(1), isTrue);
      // L'ETA doit etre apres maintenant (calcul = now + duree de trajet)
      expect(etas[1]!.isAfter(DateTime.now()), isTrue);
    });

    test('plusieurs a_livrer : ETAs croissantes dans l\'ordre', () {
      final etas = computeEtaForStops(_tournee(), [
        _stop(id: 1, statut: 'a_livrer', lat: 48.1, lng: 1.1),
        _stop(id: 2, statut: 'a_livrer', lat: 48.2, lng: 1.2),
        _stop(id: 3, statut: 'a_livrer', lat: 48.3, lng: 1.3),
      ]);
      expect(etas.length, 3);
      expect(etas[1]!.isBefore(etas[2]!), isTrue);
      expect(etas[2]!.isBefore(etas[3]!), isTrue);
    });

    test('mix livre + a_livrer : map ne contient que les a_livrer', () {
      final etas = computeEtaForStops(_tournee(), [
        _stop(id: 1, statut: 'livre', lat: 48.1, lng: 1.1),
        _stop(id: 2, statut: 'a_livrer', lat: 48.2, lng: 1.2),
        _stop(id: 3, statut: 'a_livrer', lat: 48.3, lng: 1.3),
      ]);
      expect(etas.keys, unorderedEquals([2, 3]));
    });

    test('le point de depart = dernier livre quand on est en milieu de tournee',
        () {
      // Si tournee.pointDepart est tres loin mais le dernier livre est
      // tout pres du prochain a_livrer, l'ETA doit etre courte (on part
      // du dernier livre, pas du depot).
      final tournee = _tournee(pointDepartLat: 50.0, pointDepartLng: 5.0);
      final stops = [
        _stop(id: 1, statut: 'livre', lat: 48.10, lng: 1.10),
        _stop(id: 2, statut: 'a_livrer', lat: 48.11, lng: 1.11),
      ];
      final etas = computeEtaForStops(tournee, stops);
      // ETA tres proche de maintenant car distance livre->a_livrer ~1.5 km.
      final delta = etas[2]!.difference(DateTime.now()).inMinutes;
      expect(delta, lessThan(10));
    });

    test('dureeArretMin entre stops : impacte l\'ETA du suivant', () {
      // Meme paire de coords mais dureeArretMin different sur le 1er
      // arret : le 2e doit etre plus tard.
      final stops1 = [
        _stop(id: 1, statut: 'a_livrer', lat: 48.1, lng: 1.1, dureeArretMin: 3),
        _stop(id: 2, statut: 'a_livrer', lat: 48.2, lng: 1.2, dureeArretMin: 3),
      ];
      final stops2 = [
        _stop(id: 1, statut: 'a_livrer', lat: 48.1, lng: 1.1, dureeArretMin: 30),
        _stop(id: 2, statut: 'a_livrer', lat: 48.2, lng: 1.2, dureeArretMin: 3),
      ];
      final etas1 = computeEtaForStops(_tournee(), stops1);
      final etas2 = computeEtaForStops(_tournee(), stops2);
      // ETA stop 2 avec dureeArret 30min > ETA stop 2 avec dureeArret 3min
      expect(etas2[2]!.isAfter(etas1[2]!), isTrue);
      final diffMinutes =
          etas2[2]!.difference(etas1[2]!).inMinutes;
      // Difference = ~27 minutes (30 - 3)
      expect(diffMinutes, inInclusiveRange(25, 30));
    });

    test('vitesse moyenne effective deduite de distanceTotaleM/dureeTotaleS',
        () {
      // Tournee dont la duree totale ORS suggere une vitesse moyenne
      // basse (ville : 25 km/h). L'ETA doit etre plus tardive qu'avec
      // le fallback 50 km/h.
      final stops = [
        _stop(id: 1, statut: 'a_livrer', lat: 48.1, lng: 1.1),
        _stop(id: 2, statut: 'a_livrer', lat: 48.2, lng: 1.2),
      ];
      // distance haversine env. 11 km de depot a stop2 (passing par stop1).
      // Avec dureeTotaleS = 2640s pour 11000m => 15 km/h drive,
      // avec 2 stops × 3 min de service = 360s service,
      // drive time = 2280s, vitesse = 11000 / 2280 ≈ 4.82 m/s ≈ 17.4 km/h.
      final tourneeLente = _tournee(
        distanceTotaleM: 11000,
        dureeTotaleS: 2640,
      );
      final tourneeSansDonnees = _tournee();
      final etasLente = computeEtaForStops(tourneeLente, stops);
      final etasFallback = computeEtaForStops(tourneeSansDonnees, stops);
      // Avec vitesse ~17 km/h vs 50 km/h, l'ETA lente est forcement plus
      // tardive.
      expect(etasLente[2]!.isAfter(etasFallback[2]!), isTrue);
    });

    test('vitesse absurde (< 5 km/h) -> fallback 50 km/h', () {
      // Tournee dont les donnees donnent une vitesse de conduite < 5 km/h
      // (probablement des donnees corrompues / un test) : on doit
      // basculer sur le fallback.
      final stops = [
        _stop(id: 1, statut: 'a_livrer', lat: 48.1, lng: 1.1),
      ];
      final tourneeAbsurde = _tournee(
        distanceTotaleM: 100,
        dureeTotaleS: 36000, // 100m en 10h => 10m/h, mais service deduit
      );
      final etasAbsurde = computeEtaForStops(tourneeAbsurde, stops);
      final etasFallback = computeEtaForStops(_tournee(), stops);
      // L'ETA absurde doit etre tres proche de celle du fallback (pas
      // dix heures plus tard).
      final diffSec = etasAbsurde[1]!.difference(etasFallback[1]!).inSeconds.abs();
      expect(diffSec, lessThan(5));
    });
  });
}

Tournee _tournee({
  double pointDepartLat = 48.0,
  double pointDepartLng = 1.0,
  int? distanceTotaleM,
  int? dureeTotaleS,
}) {
  return Tournee(
    id: 1,
    nom: 'T',
    date: DateTime(2026, 5, 11),
    pointDepartLat: pointDepartLat,
    pointDepartLng: pointDepartLng,
    pointDepartLabel: 'Depot',
    vehiculeCapaciteColis: 0,
    statut: 'optimisee',
    distanceTotaleM: distanceTotaleM,
    dureeTotaleS: dureeTotaleS,
    isTemplate: false,
    creeLe: DateTime(2026, 5, 11),
  );
}

Stop _stop({
  required int id,
  required String statut,
  double? lat,
  double? lng,
  int dureeArretMin = 3,
}) {
  return Stop(
    id: id,
    tourneeId: 1,
    adresseBrute: 'Test $id',
    lat: lat,
    lng: lng,
    nbColis: 1,
    priorite: 'flexible',
    dureeArretMin: dureeArretMin,
    statutLivraison: statut,
    creeLe: DateTime(2026, 5, 11),
  );
}
