import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/tour_assistant/assistant_suggestion.dart';
import 'package:opti_route/data/tour_assistant/nearest_after_fail_rule.dart';
import 'package:opti_route/data/tour_assistant/time_window_rule.dart';
import 'package:opti_route/data/tour_assistant/tour_context.dart';

/// Tests unitaires pour les regles V5.3 ajoutees au TourAssistant :
/// - TimeWindowRule (urgence fenetre horaire qui se ferme).
/// - NearestAfterFailRule (voisin le plus proche apres echec recent).
void main() {
  group('TimeWindowRule.evaluate', () {
    const rule = TimeWindowRule();
    final now = DateTime(2026, 5, 11, 14); // 14h00

    test('master assistant disabled -> null', () {
      final ctx = _ctx(
        stops: [
          _stop(1, 48.0, 1.0),
          _stop(2, 48.0, 1.0, fenetreFin: '14:20'),
        ],
        masterEnabled: false,
        now: now,
      );
      expect(rule.evaluate(ctx), isNull);
    });

    test('regle timeWindow disabled -> null', () {
      final ctx = _ctx(
        stops: [
          _stop(1, 48.0, 1.0),
          _stop(2, 48.0, 1.0, fenetreFin: '14:20'),
        ],
        timeWindowEnabled: false,
        now: now,
      );
      expect(rule.evaluate(ctx), isNull);
    });

    test('tournee non en_cours -> null', () {
      final ctx = _ctx(
        statut: 'optimisee',
        stops: [
          _stop(1, 48.0, 1.0),
          _stop(2, 48.0, 1.0, fenetreFin: '14:20'),
        ],
        now: now,
      );
      expect(rule.evaluate(ctx), isNull);
    });

    test('aucun stop avec fenetreFin -> null', () {
      final ctx = _ctx(
        stops: [
          _stop(1, 48.0, 1.0),
          _stop(2, 48.0, 1.0),
          _stop(3, 48.0, 1.0),
        ],
        now: now,
      );
      expect(rule.evaluate(ctx), isNull);
    });

    test('fenetreFin dans 20 min -> propose', () {
      // 14h00 vs fenetreFin 14:20 = 20 min restantes <= 30 min seuil.
      final ctx = _ctx(
        stops: [
          _stop(1, 48.0, 1.0), // prochain prevu, sans urgence
          _stop(2, 48.0, 1.0, fenetreFin: '14:20', name: 'Pharmacie'),
        ],
        now: now,
      );
      final s = rule.evaluate(ctx);
      expect(s, isNotNull);
      expect(s!.stop.id, 2);
      expect(s.kind, SuggestionKind.timeWindow);
      expect(s.minutesUrgent, 20);
      expect(s.priority, greaterThanOrEqualTo(85));
    });

    test('fenetreFin dans 5 min -> propose avec priorite plus haute', () {
      final ctx5 = _ctx(
        stops: [
          _stop(1, 48.0, 1.0),
          _stop(2, 48.0, 1.0, fenetreFin: '14:05'),
        ],
        now: now,
      );
      final ctx20 = _ctx(
        stops: [
          _stop(1, 48.0, 1.0),
          _stop(2, 48.0, 1.0, fenetreFin: '14:20'),
        ],
        now: now,
      );
      final s5 = rule.evaluate(ctx5);
      final s20 = rule.evaluate(ctx20);
      expect(s5, isNotNull);
      expect(s20, isNotNull);
      expect(s5!.priority, greaterThan(s20!.priority),
          reason: 'plus c\'est urgent, plus la priorite est haute');
    });

    test('fenetreFin dans 45 min -> null (>30 min seuil)', () {
      final ctx = _ctx(
        stops: [
          _stop(1, 48.0, 1.0),
          _stop(2, 48.0, 1.0, fenetreFin: '14:45'),
        ],
        now: now,
      );
      expect(rule.evaluate(ctx), isNull);
    });

    test('fenetreFin deja passee -> null (foutu)', () {
      final ctx = _ctx(
        stops: [
          _stop(1, 48.0, 1.0),
          _stop(2, 48.0, 1.0, fenetreFin: '13:30'),
        ],
        now: now,
      );
      expect(rule.evaluate(ctx), isNull);
    });

    test('plusieurs candidats urgents -> prend le plus urgent', () {
      final ctx = _ctx(
        stops: [
          _stop(1, 48.0, 1.0),
          _stop(2, 48.0, 1.0, fenetreFin: '14:25', name: 'Pharmacie'),
          _stop(3, 48.0, 1.0, fenetreFin: '14:08', name: 'Boulangerie'),
          _stop(4, 48.0, 1.0, fenetreFin: '14:18', name: 'Bar'),
        ],
        now: now,
      );
      final s = rule.evaluate(ctx);
      expect(s, isNotNull);
      expect(s!.stop.id, 3,
          reason: 'la boulangerie ferme dans 8 min, plus urgent');
    });

    test('priorite eviter_si_possible -> skip meme si urgent', () {
      final ctx = _ctx(
        stops: [
          _stop(1, 48.0, 1.0),
          _stop(2, 48.0, 1.0,
              fenetreFin: '14:10', priorite: 'eviter_si_possible'),
        ],
        now: now,
      );
      expect(rule.evaluate(ctx), isNull);
    });

    test('le 1er restant a une fenetre urgente -> skip (deja prevu)', () {
      // Index 0 = prochain prevu. Si lui-meme a une fenetre urgente,
      // Noah va naturellement le livrer en 1er, pas la peine de proposer.
      final ctx = _ctx(
        stops: [
          _stop(1, 48.0, 1.0, fenetreFin: '14:10'), // urgent mais prevu
          _stop(2, 48.0, 1.0),
        ],
        now: now,
      );
      expect(rule.evaluate(ctx), isNull);
    });

    test('seulement fenetreDebut definie (pas fenetreFin) -> null', () {
      final ctx = _ctx(
        stops: [
          _stop(1, 48.0, 1.0),
          _stop(2, 48.0, 1.0, fenetreDebut: '14:00'),
        ],
        now: now,
      );
      expect(rule.evaluate(ctx), isNull);
    });
  });

  group('NearestAfterFailRule.evaluate', () {
    const rule = NearestAfterFailRule();
    final now = DateTime(2026, 5, 11, 14);

    test('master assistant disabled -> null', () {
      final ctx = _ctx(
        stops: [
          _stop(1, 48.0, 1.0, statutLivraison: 'echec', livreLe: now),
          _stop(2, 49.0, 2.0),
          _stop(3, 48.001, 1.001),
        ],
        currentPos: _pos(48.0, 1.0),
        masterEnabled: false,
        now: now,
      );
      expect(rule.evaluate(ctx), isNull);
    });

    test('regle nearestAfterFail disabled -> null', () {
      final ctx = _ctx(
        stops: [
          _stop(1, 48.0, 1.0, statutLivraison: 'echec', livreLe: now),
          _stop(2, 49.0, 2.0),
          _stop(3, 48.001, 1.001),
        ],
        currentPos: _pos(48.0, 1.0),
        nearestAfterFailEnabled: false,
        now: now,
      );
      expect(rule.evaluate(ctx), isNull);
    });

    test('pas de position GPS -> null', () {
      final ctx = _ctx(
        stops: [
          _stop(1, 48.0, 1.0, statutLivraison: 'echec', livreLe: now),
          _stop(2, 49.0, 2.0),
          _stop(3, 48.001, 1.001),
        ],
        currentPos: null,
        now: now,
      );
      expect(rule.evaluate(ctx), isNull);
    });

    test('aucun echec recent -> null', () {
      // Echec il y a 60 min = ancien (seuil 5 min).
      final ancien = now.subtract(const Duration(minutes: 60));
      final ctx = _ctx(
        stops: [
          _stop(1, 48.0, 1.0, statutLivraison: 'echec', livreLe: ancien),
          _stop(2, 49.0, 2.0),
          _stop(3, 48.001, 1.001),
        ],
        currentPos: _pos(48.0, 1.0),
        now: now,
      );
      expect(rule.evaluate(ctx), isNull);
    });

    test('echec recent + voisin plus proche -> propose le voisin', () {
      final ctx = _ctx(
        stops: [
          _stop(1, 48.0, 1.0,
              statutLivraison: 'echec',
              livreLe: now.subtract(const Duration(minutes: 2)),
              name: 'Client absent'),
          _stop(2, 49.0, 2.0, name: 'Loin'),       // prochain prevu, loin
          _stop(3, 48.001, 1.001, name: 'Voisin'), // plus proche que stop 2
        ],
        currentPos: _pos(48.0, 1.0),
        now: now,
      );
      final s = rule.evaluate(ctx);
      expect(s, isNotNull);
      expect(s!.stop.id, 3);
      expect(s.kind, SuggestionKind.nearestAfterFail);
      expect(s.distanceMeters, lessThan(200));
    });

    test('echec recent + le plus proche = le prochain prevu -> null', () {
      // Si le plus proche est deja le prochain prevu, pas la peine de
      // proposer (Noah va le faire naturellement).
      final ctx = _ctx(
        stops: [
          _stop(1, 48.0, 1.0,
              statutLivraison: 'echec',
              livreLe: now.subtract(const Duration(minutes: 2))),
          _stop(2, 48.001, 1.001, name: 'Prochain prevu, proche'),
          _stop(3, 49.0, 2.0, name: 'Loin'),
        ],
        currentPos: _pos(48.0, 1.0),
        now: now,
      );
      expect(rule.evaluate(ctx), isNull);
    });

    test('voisin priorite eviter_si_possible -> skip, prend le suivant',
        () {
      final ctx = _ctx(
        stops: [
          _stop(1, 48.0, 1.0,
              statutLivraison: 'echec',
              livreLe: now.subtract(const Duration(minutes: 2))),
          _stop(2, 49.0, 2.0, name: 'Loin (prochain prevu)'),
          _stop(3, 48.001, 1.001,
              priorite: 'eviter_si_possible', name: 'Eviter'),
          _stop(4, 48.005, 1.005, name: 'Voisin acceptable'),
        ],
        currentPos: _pos(48.0, 1.0),
        now: now,
      );
      final s = rule.evaluate(ctx);
      expect(s, isNotNull);
      expect(s!.stop.id, 4);
    });

    test('aucun voisin a_livrer -> null', () {
      // Tous les stops a_livrer sont 0 (juste l'echec) ou pas a_livrer.
      final ctx = _ctx(
        stops: [
          _stop(1, 48.0, 1.0,
              statutLivraison: 'echec',
              livreLe: now.subtract(const Duration(minutes: 2))),
        ],
        currentPos: _pos(48.0, 1.0),
        now: now,
      );
      expect(rule.evaluate(ctx), isNull);
    });

    test('voisin sans coords ignore, prend le suivant', () {
      final ctx = _ctx(
        stops: [
          _stop(1, 48.0, 1.0,
              statutLivraison: 'echec',
              livreLe: now.subtract(const Duration(minutes: 2))),
          _stop(2, 49.0, 2.0, name: 'Loin'),
          _stop(3, null, null, name: 'Sans coords'),
          _stop(4, 48.001, 1.001, name: 'Voisin avec coords'),
        ],
        currentPos: _pos(48.0, 1.0),
        now: now,
      );
      final s = rule.evaluate(ctx);
      expect(s, isNotNull);
      expect(s!.stop.id, 4);
    });

    test('echec sans livreLe (cas degenere) -> ignore cet echec', () {
      // Un stop marque 'echec' mais sans livreLe (data corrompue) ne
      // doit pas declencher la regle.
      final ctx = _ctx(
        stops: [
          _stop(1, 48.0, 1.0, statutLivraison: 'echec', livreLe: null),
          _stop(2, 49.0, 2.0),
          _stop(3, 48.001, 1.001),
        ],
        currentPos: _pos(48.0, 1.0),
        now: now,
      );
      expect(rule.evaluate(ctx), isNull);
    });
  });
}

// ─── Helpers ─────────────────────────────────────────────────────

TourContext _ctx({
  String statut = 'en_cours',
  required List<Stop> stops,
  Position? currentPos,
  bool masterEnabled = true,
  bool timeWindowEnabled = true,
  bool nearestAfterFailEnabled = true,
  DateTime? now,
}) {
  return TourContext(
    tournee: _tournee(statut: statut),
    stops: stops,
    currentPosition: currentPos,
    now: now ?? DateTime(2026, 5, 11, 14),
    params: TourAssistantParams(
      enabled: masterEnabled,
      timeWindowEnabled: timeWindowEnabled,
      nearestAfterFailEnabled: nearestAfterFailEnabled,
    ),
  );
}

Tournee _tournee({String statut = 'en_cours'}) {
  return Tournee(
    id: 1,
    nom: 'T',
    date: DateTime(2026, 5, 11),
    pointDepartLat: 48.0,
    pointDepartLng: 1.0,
    pointDepartLabel: 'Depot',
    vehiculeCapaciteColis: 0,
    statut: statut,
    isTemplate: false,
    creeLe: DateTime(2026, 5, 11),
  );
}

Stop _stop(
  int id,
  double? lat,
  double? lng, {
  String statutLivraison = 'a_livrer',
  String priorite = 'flexible',
  String? fenetreDebut,
  String? fenetreFin,
  String? name,
  DateTime? livreLe,
}) {
  return Stop(
    id: id,
    tourneeId: 1,
    adresseBrute: 'Adresse $id',
    nomClient: name,
    lat: lat,
    lng: lng,
    nbColis: 1,
    priorite: priorite,
    fenetreDebut: fenetreDebut,
    fenetreFin: fenetreFin,
    dureeArretMin: 3,
    statutLivraison: statutLivraison,
    livreLe: livreLe,
    creeLe: DateTime(2026, 5, 11),
  );
}

Position _pos(double lat, double lng) {
  return Position(
    latitude: lat,
    longitude: lng,
    timestamp: DateTime(2026, 5, 11, 14),
    accuracy: 5,
    altitude: 0,
    heading: -1,
    speed: 0,
    speedAccuracy: 0,
    altitudeAccuracy: 0,
    headingAccuracy: 0,
  );
}
