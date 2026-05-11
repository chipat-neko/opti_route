import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/tour_assistant/assistant_suggestion.dart';
import 'package:opti_route/data/tour_assistant/proximity_rule.dart';
import 'package:opti_route/data/tour_assistant/tour_assistant.dart';
import 'package:opti_route/data/tour_assistant/tour_context.dart';

void main() {
  group('ProximityRule.evaluate', () {
    const rule = ProximityRule();

    test('tournee non en_cours -> null', () {
      final ctx = _ctx(
        statut: 'optimisee',
        stops: [_stop(1, 48.0, 1.0), _stop(2, 48.001, 1.001)],
        currentPos: _pos(48.0005, 1.0005),
      );
      expect(rule.evaluate(ctx), isNull);
    });

    test('pas de position GPS -> null', () {
      final ctx = _ctx(
        stops: [_stop(1, 48.0, 1.0), _stop(2, 48.001, 1.001)],
        currentPos: null,
      );
      expect(rule.evaluate(ctx), isNull);
    });

    test('1 seul stop a_livrer -> null (rien a swap)', () {
      final ctx = _ctx(
        stops: [_stop(1, 48.0, 1.0)],
        currentPos: _pos(48.0001, 1.0001),
      );
      expect(rule.evaluate(ctx), isNull);
    });

    test('le prochain prevu est dans la zone -> on l\'ignore (filtre)',
        () {
      // Seul le 1er stop est en zone : c'est deja le prochain prevu,
      // pas de suggestion a faire.
      final ctx = _ctx(
        stops: [
          _stop(1, 48.0001, 1.0001), // tres proche, mais c'est le prochain
          _stop(2, 49.0, 2.0), // loin
        ],
        currentPos: _pos(48.0, 1.0),
      );
      expect(rule.evaluate(ctx), isNull);
    });

    test('un stop suivant est dans la zone -> on le propose', () {
      // Stop #2 a ~111 m de la position, #1 (prochain prevu) loin.
      final ctx = _ctx(
        stops: [
          _stop(1, 49.0, 2.0),
          _stop(2, 48.001, 1.0),
        ],
        currentPos: _pos(48.0, 1.0),
        thresholdM: 200,
      );
      final s = rule.evaluate(ctx);
      expect(s, isNotNull);
      expect(s!.stop.id, 2);
      expect(s.kind, SuggestionKind.proximity);
      expect(s.distanceMeters, lessThan(200));
    });

    test('plusieurs candidats -> on prend le plus proche', () {
      final ctx = _ctx(
        stops: [
          _stop(1, 49.0, 2.0), // prochain prevu, loin
          _stop(2, 48.002, 1.0), // ~222 m
          _stop(3, 48.001, 1.0), // ~111 m
        ],
        currentPos: _pos(48.0, 1.0),
        thresholdM: 500,
      );
      final s = rule.evaluate(ctx);
      expect(s, isNotNull);
      expect(s!.stop.id, 3, reason: 'doit choisir le plus proche');
    });

    test('proximityEnabled = false -> null meme si en zone', () {
      final ctx = _ctx(
        stops: [_stop(1, 49.0, 2.0), _stop(2, 48.001, 1.0)],
        currentPos: _pos(48.0, 1.0),
        thresholdM: 200,
        proximityEnabled: false,
      );
      expect(rule.evaluate(ctx), isNull);
    });

    test('master enabled = false -> null', () {
      final ctx = _ctx(
        stops: [_stop(1, 49.0, 2.0), _stop(2, 48.001, 1.0)],
        currentPos: _pos(48.0, 1.0),
        thresholdM: 200,
        masterEnabled: false,
      );
      expect(rule.evaluate(ctx), isNull);
    });

    test('stop sans coords -> ignore mais ne casse pas', () {
      final ctx = _ctx(
        stops: [
          _stop(1, 49.0, 2.0),
          _stop(2, null, null), // sans coords
          _stop(3, 48.001, 1.0),
        ],
        currentPos: _pos(48.0, 1.0),
        thresholdM: 200,
      );
      final s = rule.evaluate(ctx);
      expect(s, isNotNull);
      expect(s!.stop.id, 3);
    });

    test('stops livres / echec ignores', () {
      final ctx = _ctx(
        stops: [
          _stop(1, 49.0, 2.0),
          _stop(2, 48.001, 1.0, statutLivraison: 'livre'),
          _stop(3, 48.0005, 1.0, statutLivraison: 'echec'),
        ],
        currentPos: _pos(48.0, 1.0),
        thresholdM: 500,
      );
      // Apres filtre `a_livrer`, il ne reste que stop 1. Donc null.
      expect(rule.evaluate(ctx), isNull);
    });
  });

  group('TourAssistant cooldown', () {
    test('apres refus, cooldown bloque la meme suggestion', () {
      final assistant = TourAssistant();
      final stop = _stop(7, 48.001, 1.0);
      final suggestion = AssistantSuggestion(
        kind: SuggestionKind.proximity,
        stop: stop,
        message: 'test',
        priority: 70,
      );
      final t0 = DateTime(2026, 5, 11, 10);
      assistant.recordRefuse(suggestion, t0, cooldownMinutes: 5);

      // 2 minutes plus tard : toujours en cooldown.
      final ctx = _ctx(
        stops: [_stop(1, 49.0, 2.0), stop],
        currentPos: _pos(48.0, 1.0),
        thresholdM: 200,
        now: t0.add(const Duration(minutes: 2)),
      );
      expect(assistant.evaluate(ctx), isNull);

      // 6 minutes plus tard : cooldown expire.
      final ctx2 = _ctx(
        stops: [_stop(1, 49.0, 2.0), stop],
        currentPos: _pos(48.0, 1.0),
        thresholdM: 200,
        now: t0.add(const Duration(minutes: 6)),
      );
      expect(assistant.evaluate(ctx2), isNotNull);
    });

    test('accept retire le cooldown (no-op si pas en cooldown)', () {
      final assistant = TourAssistant();
      final stop = _stop(7, 48.001, 1.0);
      final suggestion = AssistantSuggestion(
        kind: SuggestionKind.proximity,
        stop: stop,
        message: 'test',
        priority: 70,
      );
      // recordAccept sur une suggestion non en cooldown ne casse rien.
      expect(() => assistant.recordAccept(suggestion), returnsNormally);
    });

    test('resetCooldowns vide la map', () {
      final assistant = TourAssistant();
      final stop = _stop(7, 48.001, 1.0);
      final suggestion = AssistantSuggestion(
        kind: SuggestionKind.proximity,
        stop: stop,
        message: 'test',
        priority: 70,
      );
      assistant.recordRefuse(suggestion, DateTime(2026, 5, 11),
          cooldownMinutes: 5);
      assistant.resetCooldowns();

      final ctx = _ctx(
        stops: [_stop(1, 49.0, 2.0), stop],
        currentPos: _pos(48.0, 1.0),
        thresholdM: 200,
        now: DateTime(2026, 5, 11),
      );
      expect(assistant.evaluate(ctx), isNotNull);
    });
  });
}

// ─── Helpers ─────────────────────────────────────────────────────

TourContext _ctx({
  String statut = 'en_cours',
  required List<Stop> stops,
  required Position? currentPos,
  int thresholdM = 300,
  bool proximityEnabled = true,
  bool masterEnabled = true,
  DateTime? now,
}) {
  return TourContext(
    tournee: _tournee(statut: statut),
    stops: stops,
    currentPosition: currentPos,
    now: now ?? DateTime(2026, 5, 11, 10),
    params: TourAssistantParams(
      enabled: masterEnabled,
      proximityEnabled: proximityEnabled,
      proximityThresholdM: thresholdM,
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

Stop _stop(int id, double? lat, double? lng,
    {String statutLivraison = 'a_livrer'}) {
  return Stop(
    id: id,
    tourneeId: 1,
    adresseBrute: 'Adresse $id',
    nomClient: 'Client $id',
    lat: lat,
    lng: lng,
    nbColis: 1,
    priorite: 'flexible',
    dureeArretMin: 3,
    statutLivraison: statutLivraison,
    creeLe: DateTime(2026, 5, 11),
  );
}

Position _pos(double lat, double lng) {
  return Position(
    latitude: lat,
    longitude: lng,
    timestamp: DateTime(2026, 5, 11, 10),
    accuracy: 5,
    altitude: 0,
    heading: 0,
    speed: 0,
    speedAccuracy: 0,
    altitudeAccuracy: 0,
    headingAccuracy: 0,
  );
}
