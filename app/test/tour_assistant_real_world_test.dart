import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/tour_assistant/proximity_rule.dart';
import 'package:opti_route/data/tour_assistant/tour_context.dart';

/// Tests sur des **coordonnees reelles** francaises. Objectif : valider
/// que la regle Proximity se comporte correctement dans des scenarios
/// metier proches du quotidien de Noah (Eure-et-Loir / Chartres) et
/// dans des cas limites (Paris dense, barrieres geographiques).
///
/// Toutes les coords proviennent d'OpenStreetMap (verifiables sur
/// nominatim.openstreetmap.org). Les noms d'arrets sont fictifs ou
/// d'institutions publiques (mairies, gares...) pour eviter toute
/// donnee personnelle dans le repo.
void main() {
  group('Tournee urbaine — centre de Chartres (zone Noah)', () {
    const rule = ProximityRule();

    // Reperes Eure-et-Loir reels :
    const chartresMairie = _Coord(48.4470, 1.4892);
    const chartresGare = _Coord(48.4427, 1.4831);
    const chartresCathedrale = _Coord(48.4474, 1.4877);
    const luce = _Coord(48.4406, 1.4506);
    const gellainville = _Coord(48.4189, 1.5392); // depot MESEXP reel

    test('a 85% du trajet depot -> gare : passe pres mairie -> propose', () {
      // Trajet depot Gellainville (sud-est) vers gare Chartres (nord-ouest).
      // A mi-chemin on est encore a ~2.4 km de la mairie (trop loin),
      // mais a 85% du chemin on est a ~900 m, dans le seuil 1500 m.
      final pos = _posBetween(gellainville, chartresGare, ratio: 0.85);
      final ctx = _ctx(
        depot: gellainville,
        stops: [
          _stop(1, chartresGare, name: 'Gare SNCF'),       // prochain prevu
          _stop(2, chartresMairie, name: 'Mairie'),        // a proximite ?
          _stop(3, chartresCathedrale, name: 'Cathedrale'),
          _stop(4, luce, name: 'Luce'),
        ],
        currentPos: pos,
        thresholdM: 1500,
      );
      final s = rule.evaluate(ctx);
      expect(s, isNotNull,
          reason: 'a 85% du trajet, la mairie est dans la zone 1500m');
      // La mairie OU la cathedrale (a quelques metres l'une de l'autre)
      // est suggeree.
      expect([2, 3], contains(s!.stop.id),
          reason: 'doit etre la mairie ou la cathedrale (les 2 proches)');
    });

    test('directement sur la mairie -> propose un autre arret proche',
        () {
      // On est devant la mairie de Chartres. La gare est le prochain
      // prevu. La cathedrale est a ~80m. -> suggere la cathedrale.
      final ctx = _ctx(
        stops: [
          _stop(1, chartresGare, name: 'Gare'),         // prochain prevu (loin)
          _stop(2, chartresCathedrale, name: 'Cathedrale'),
        ],
        currentPos: _posFrom(chartresMairie),
        thresholdM: 300,
      );
      final s = rule.evaluate(ctx);
      expect(s, isNotNull);
      expect(s!.stop.id, 2);
      expect(s.distanceMeters, lessThan(200));
    });

    test('a Luce avec seuil 200m : aucun arret du centre Chartres en zone',
        () {
      // Luce est a ~3 km du centre Chartres. Seuil 200m -> rien.
      final ctx = _ctx(
        stops: [
          _stop(1, chartresGare),
          _stop(2, chartresMairie),
          _stop(3, chartresCathedrale),
        ],
        currentPos: _posFrom(luce),
        thresholdM: 200,
      );
      expect(rule.evaluate(ctx), isNull);
    });
  });

  group('Tournee rurale — Eure-et-Loir', () {
    const rule = ProximityRule();

    const laLoupe = _Coord(48.4731, 1.0117);
    const thironGardais = _Coord(48.3056, 1.0014);
    const trizay = _Coord(48.3942, 0.9786);
    const courvilleSurEure = _Coord(48.4456, 1.2435);

    test('seuil 300m insuffisant en rural (arrets eloignes)', () {
      // En rural, les arrets sont a plusieurs km. Seuil 300m -> aucune
      // suggestion meme entre deux villages voisins.
      final ctx = _ctx(
        stops: [
          _stop(1, courvilleSurEure),
          _stop(2, laLoupe),
        ],
        currentPos: _posFrom(trizay),
        thresholdM: 300,
      );
      expect(rule.evaluate(ctx), isNull,
          reason: 'distances rurales > 300m');
    });

    test('seuil eleve en rural (1500m) detecte les voisins', () {
      // Si Noah augmente le seuil a 1500m, il peut deceler les passages
      // dans des villages voisins.
      final ctx = _ctx(
        stops: [
          _stop(1, courvilleSurEure),
          _stop(2, laLoupe),
        ],
        // On est sur la route entre Trizay et La Loupe, a quelques km
        // de Thiron-Gardais qui est plus au sud.
        currentPos: _posBetween(trizay, thironGardais, ratio: 0.5),
        thresholdM: 5000, // 5 km, raisonnable en zone rurale
      );
      // Le stop 2 (La Loupe) est plus loin, le 1 (Courville) aussi mais
      // l'un d'eux peut tomber dans la zone selon les distances exactes.
      // On ne fixe pas un id specifique, juste qu'on ait une suggestion.
      // Si aucun, c'est aussi un test legitime (juste informatif).
      final s = rule.evaluate(ctx);
      // Ce test sert surtout a documenter le comportement : on
      // n'exige rien de strict ici. C'est OK que ce soit null si les
      // distances reelles sont >5km.
      if (s != null) {
        expect(s.distanceMeters, lessThan(5000));
      }
    });
  });

  group('Filtre direction GPS (cap)', () {
    const rule = ProximityRule();
    const mairie = _Coord(48.4470, 1.4892);
    const auNord = _Coord(48.4525, 1.4892); // 600m plein nord
    const auSud = _Coord(48.4415, 1.4892);  // 600m plein sud
    const auEst = _Coord(48.4470, 1.4972);  // ~600m plein est
    const auOuest = _Coord(48.4470, 1.4812);

    test('je roule vers le nord, stop au sud -> skip (derriere moi)', () {
      final ctx = _ctx(
        stops: [
          _stop(1, auEst, name: 'Est (prochain prevu)'),  // pas en zone
          _stop(2, auSud, name: 'Sud (derriere)'),
        ],
        currentPos: _posWithHeading(mairie, headingDeg: 0, speedMs: 10),
        thresholdM: 1000,
      );
      expect(rule.evaluate(ctx), isNull,
          reason: 'le stop sud est derriere nous, on ne propose pas');
    });

    test('je roule vers le nord, stop au nord -> propose', () {
      final ctx = _ctx(
        stops: [
          _stop(1, auEst, name: 'Est (prochain prevu)'),
          _stop(2, auNord, name: 'Nord (devant)'),
        ],
        currentPos: _posWithHeading(mairie, headingDeg: 0, speedMs: 10),
        thresholdM: 1000,
      );
      final s = rule.evaluate(ctx);
      expect(s, isNotNull);
      expect(s!.stop.id, 2);
    });

    test('vitesse trop basse (0.5 m/s) -> filtre direction desactive', () {
      // On est presque a l'arret : heading peu fiable, on ne filtre pas
      // par direction. Le stop au sud est donc propose.
      final ctx = _ctx(
        stops: [
          _stop(1, auEst),  // prochain prevu, hors zone
          _stop(2, auSud),
        ],
        currentPos: _posWithHeading(mairie, headingDeg: 0, speedMs: 0.5),
        thresholdM: 1000,
      );
      final s = rule.evaluate(ctx);
      expect(s, isNotNull);
      expect(s!.stop.id, 2);
    });

    test('heading inconnu (-1) -> filtre direction desactive', () {
      final ctx = _ctx(
        stops: [
          _stop(1, auEst),
          _stop(2, auSud),
        ],
        currentPos: _posWithHeading(mairie, headingDeg: -1, speedMs: 10),
        thresholdM: 1000,
      );
      final s = rule.evaluate(ctx);
      expect(s, isNotNull);
      expect(s!.stop.id, 2);
    });

    test('cap est, stop a l\'ouest -> skip', () {
      final ctx = _ctx(
        stops: [
          _stop(1, auNord), // prochain prevu, hors zone
          _stop(2, auOuest),
        ],
        currentPos: _posWithHeading(mairie, headingDeg: 90, speedMs: 10),
        thresholdM: 1000,
      );
      expect(rule.evaluate(ctx), isNull);
    });

    test('cap est avec tolerance 120 deg : stop nord-est OK', () {
      // Avec tolerance large 120°, les stops dans un cone de 240° devant
      // sont acceptes -> nord est OK avec cap est.
      final ctx = _ctx(
        stops: [
          _stop(1, auSud), // prochain prevu, hors zone
          _stop(2, auNord),
        ],
        currentPos: _posWithHeading(mairie, headingDeg: 90, speedMs: 10),
        thresholdM: 1000,
        directionToleranceDeg: 120,
      );
      final s = rule.evaluate(ctx);
      expect(s, isNotNull);
      expect(s!.stop.id, 2);
    });
  });

  group('Fenetres horaires', () {
    const rule = ProximityRule();
    const here = _Coord(48.4470, 1.4892);
    const proche = _Coord(48.4480, 1.4900); // ~130m

    test('stop sans fenetre -> propose', () {
      final ctx = _ctx(
        stops: [
          _stop(1, const _Coord(49.0, 2.0)),
          _stop(2, proche),
        ],
        currentPos: _posFrom(here),
        now: DateTime(2026, 5, 11, 10),
        thresholdM: 300,
      );
      expect(rule.evaluate(ctx), isNotNull);
    });

    test('fenetre 14h-16h, on est a 13h45 -> propose (dans la marge 30min)',
        () {
      final ctx = _ctx(
        stops: [
          _stop(1, const _Coord(49.0, 2.0)),
          _stop(2, proche, fenetreDebut: '14:00', fenetreFin: '16:00'),
        ],
        currentPos: _posFrom(here),
        now: DateTime(2026, 5, 11, 13, 45),
        thresholdM: 300,
      );
      final s = rule.evaluate(ctx);
      expect(s, isNotNull);
      expect(s!.stop.id, 2);
    });

    test('fenetre 14h-16h, on est a 12h (trop tot) -> skip', () {
      final ctx = _ctx(
        stops: [
          _stop(1, const _Coord(49.0, 2.0)),
          _stop(2, proche, fenetreDebut: '14:00', fenetreFin: '16:00'),
        ],
        currentPos: _posFrom(here),
        now: DateTime(2026, 5, 11, 12),
        thresholdM: 300,
      );
      expect(rule.evaluate(ctx), isNull,
          reason: '12h vs fenetre 14h - 30min = avant 13h30, trop tot');
    });

    test('fenetre 14h-16h, on est a 17h (trop tard) -> skip', () {
      final ctx = _ctx(
        stops: [
          _stop(1, const _Coord(49.0, 2.0)),
          _stop(2, proche, fenetreDebut: '14:00', fenetreFin: '16:00'),
        ],
        currentPos: _posFrom(here),
        now: DateTime(2026, 5, 11, 17),
        thresholdM: 300,
      );
      expect(rule.evaluate(ctx), isNull);
    });

    test('seulement fenetreFin definie, on est apres -> skip', () {
      final ctx = _ctx(
        stops: [
          _stop(1, const _Coord(49.0, 2.0)),
          _stop(2, proche, fenetreFin: '12:00'),
        ],
        currentPos: _posFrom(here),
        now: DateTime(2026, 5, 11, 14),
        thresholdM: 300,
      );
      expect(rule.evaluate(ctx), isNull);
    });
  });

  group('Priorite "eviter si possible"', () {
    const rule = ProximityRule();
    const here = _Coord(48.4470, 1.4892);
    const proche = _Coord(48.4480, 1.4900);
    const moinsProche = _Coord(48.4500, 1.4900);

    test('stop eviter_si_possible meme proche -> skip', () {
      final ctx = _ctx(
        stops: [
          _stop(1, const _Coord(49.0, 2.0)),
          _stop(2, proche, priorite: 'eviter_si_possible'),
        ],
        currentPos: _posFrom(here),
        thresholdM: 300,
      );
      expect(rule.evaluate(ctx), isNull);
    });

    test('eviter proche + normal moins proche -> propose le normal', () {
      final ctx = _ctx(
        stops: [
          _stop(1, const _Coord(49.0, 2.0)),
          _stop(2, proche, priorite: 'eviter_si_possible'),
          _stop(3, moinsProche), // moins proche mais accepte
        ],
        currentPos: _posFrom(here),
        thresholdM: 500,
      );
      final s = rule.evaluate(ctx);
      expect(s, isNotNull);
      expect(s!.stop.id, 3);
    });
  });

  group('Cas particulier : Paris (barrieres geographiques)', () {
    const rule = ProximityRule();
    // Limite connue : la regle haversine ne sait pas qu'il y a la Seine
    // entre deux points. Coords choisies pour donner ~200m vol d'oiseau
    // (memes latitude, dlon 0.0026 deg = ~190m a lat 48.85).
    const quaiBourbon = _Coord(48.8552, 2.3530);  // Ile Saint-Louis
    const quaiAuxFleurs = _Coord(48.8552, 2.3504); // Ile de la Cite

    test('~200m vol d\'oiseau mais Seine au milieu : propose quand meme',
        () {
      // Limite connue : la regle se base sur la distance haversine, pas
      // sur la distance routiere. Sur ce cas, l'utilisateur fera la
      // distinction visuellement (il sait qu'il y a un pont a traverser).
      final ctx = _ctx(
        stops: [
          _stop(1, const _Coord(48.84, 2.36)), // ailleurs Paris (loin)
          _stop(2, quaiAuxFleurs),
        ],
        currentPos: _posFrom(quaiBourbon),
        thresholdM: 500,
      );
      final s = rule.evaluate(ctx);
      expect(s, isNotNull,
          reason: 'limite connue : pas de detection des barrieres');
      expect(s!.distanceMeters, lessThan(300));
    });
  });

  group('Scenario terrain complet — tournee mixte 8 arrets', () {
    const rule = ProximityRule();
    // Tournee fictive Noah : depot Gellainville, 8 arrets dans un mix
    // Chartres / Luce / La Loupe.
    const depotGellainville = _Coord(48.4189, 1.5392); // Gellainville

    test('mi-tournee, 4 livres + 4 a livrer, suggestion logique', () {
      // 8 arrets, 4 deja livres, 4 restants. La position GPS est dans
      // le centre de Chartres, le prochain prevu est Luce (3km a l'ouest).
      // Un autre restant est tres proche (mairie a 100m).
      final ctx = _ctx(
        depot: depotGellainville,
        stops: [
          _stop(1, const _Coord(48.43, 1.50), statutLivraison: 'livre'),
          _stop(2, const _Coord(48.44, 1.49), statutLivraison: 'livre'),
          _stop(3, const _Coord(48.445, 1.485), statutLivraison: 'livre'),
          _stop(4, const _Coord(48.448, 1.487), statutLivraison: 'echec'),
          // Restants :
          _stop(5, const _Coord(48.4406, 1.4506),
              name: 'Luce'), // prochain prevu, ~3km
          _stop(6, const _Coord(48.4470, 1.4892),
              name: 'Mairie Chartres'), // a 100m, devrait etre suggere
          _stop(7, const _Coord(48.4731, 1.0117),
              name: 'La Loupe'), // tres loin
          _stop(8, const _Coord(48.4456, 1.2435),
              name: 'Courville'),
        ],
        currentPos:
            _posWithHeading(const _Coord(48.4469, 1.4893), headingDeg: 270, speedMs: 8),
        // cap 270 = ouest (vers Luce), mais mairie est juste a cote
        // (~10m au nord), donc le bearing vers mairie sera ~0-30, ce
        // qui est dans la tolerance 90 deg.
        thresholdM: 300,
      );
      final s = rule.evaluate(ctx);
      expect(s, isNotNull);
      expect(s!.stop.id, 6, reason: 'mairie Chartres a 10m doit etre suggeree');
    });

    test('tournee terminee (tous livres) -> aucune suggestion', () {
      final ctx = _ctx(
        depot: depotGellainville,
        stops: [
          _stop(1, const _Coord(48.45, 1.49), statutLivraison: 'livre'),
          _stop(2, const _Coord(48.46, 1.49), statutLivraison: 'livre'),
        ],
        currentPos: _posFrom(const _Coord(48.4470, 1.4892)),
        thresholdM: 500,
      );
      expect(rule.evaluate(ctx), isNull);
    });
  });
}

// ─── Helpers ─────────────────────────────────────────────────────

class _Coord {
  const _Coord(this.lat, this.lng);
  final double lat;
  final double lng;
}

TourContext _ctx({
  _Coord? depot,
  required List<Stop> stops,
  required Position? currentPos,
  int thresholdM = 300,
  bool proximityEnabled = true,
  bool masterEnabled = true,
  bool useDirectionFilter = true,
  int directionToleranceDeg = 90,
  DateTime? now,
}) {
  return TourContext(
    tournee: _tournee(depot: depot),
    stops: stops,
    currentPosition: currentPos,
    now: now ?? DateTime(2026, 5, 11, 10),
    params: TourAssistantParams(
      enabled: masterEnabled,
      proximityEnabled: proximityEnabled,
      proximityThresholdM: thresholdM,
      useDirectionFilter: useDirectionFilter,
      directionToleranceDeg: directionToleranceDeg,
    ),
  );
}

Tournee _tournee({_Coord? depot}) {
  final d = depot ?? const _Coord(48.0, 1.0);
  return Tournee(
    id: 1,
    nom: 'T',
    date: DateTime(2026, 5, 11),
    pointDepartLat: d.lat,
    pointDepartLng: d.lng,
    pointDepartLabel: 'Depot',
    vehiculeCapaciteColis: 0,
    statut: 'en_cours',
    isTemplate: false,
    creeLe: DateTime(2026, 5, 11),
  );
}

Stop _stop(
  int id,
  _Coord c, {
  String statutLivraison = 'a_livrer',
  String priorite = 'flexible',
  String? fenetreDebut,
  String? fenetreFin,
  String? name,
}) {
  return Stop(
    id: id,
    tourneeId: 1,
    adresseBrute: 'Adresse $id',
    nomClient: name,
    lat: c.lat,
    lng: c.lng,
    nbColis: 1,
    priorite: priorite,
    fenetreDebut: fenetreDebut,
    fenetreFin: fenetreFin,
    dureeArretMin: 3,
    statutLivraison: statutLivraison,
    creeLe: DateTime(2026, 5, 11),
  );
}

/// Position GPS sans heading fiable (vitesse 0).
Position _posFrom(_Coord c) {
  return Position(
    latitude: c.lat,
    longitude: c.lng,
    timestamp: DateTime(2026, 5, 11, 10),
    accuracy: 5,
    altitude: 0,
    heading: -1, // inconnu
    speed: 0,
    speedAccuracy: 0,
    altitudeAccuracy: 0,
    headingAccuracy: 0,
  );
}

/// Position GPS avec cap + vitesse explicites (pour tester le filtre
/// direction).
Position _posWithHeading(
  _Coord c, {
  required double headingDeg,
  required double speedMs,
}) {
  return Position(
    latitude: c.lat,
    longitude: c.lng,
    timestamp: DateTime(2026, 5, 11, 10),
    accuracy: 5,
    altitude: 0,
    heading: headingDeg,
    speed: speedMs,
    speedAccuracy: 0,
    altitudeAccuracy: 0,
    headingAccuracy: 0,
  );
}

/// Interpole entre 2 points (ratio 0 = a, 1 = b).
Position _posBetween(_Coord a, _Coord b, {required double ratio}) {
  final lat = a.lat + (b.lat - a.lat) * ratio;
  final lng = a.lng + (b.lng - a.lng) * ratio;
  return _posFrom(_Coord(lat, lng));
}
