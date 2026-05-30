import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/eta_calculator.dart';
import 'package:opti_route/screens/frais_form/type_helpers.dart';

// Regressions de la passe agents « bugs latents » 2026-05-29.
// Couvre la classe « crash sur entree vide / limite » (cartes #265, #267).
// #261 (_initials) et #266 (firstWhere) = fix trivial verifie par lecture
// + analyze ; non testes ici (helpers prives / reponse solveur a mocker).

Stop _stop({required int id, required double lat, required double lng}) {
  final now = DateTime(2026, 5, 29);
  return Stop(
    id: id,
    tourneeId: 1,
    adresseBrute: 'A$id',
    type: 'livraison',
    lat: lat,
    lng: lng,
    nbColis: 1,
    priorite: 'flexible',
    dureeArretMin: 2,
    statutLivraison: 'a_livrer',
    positionLocked: false,
    deposeSansContact: false,
    codPaye: false,
    creeLe: now,
    updatedAt: now,
  );
}

void main() {
  group('Regression bugs latents (passe agents 2026-05-29)', () {
    test('#265 labelForType("") ne crashe pas (RangeError sur type[0])', () {
      expect(labelForType(''), '');
      expect(labelForType('carburant'), 'Carburant');
      expect(labelForType('inconnu'), 'Inconnu');
    });

    test('#267 computeSegments(avgSpeedKmh: 0) ne crashe pas (div par 0)', () {
      final segments = EtaCalculator.computeSegments(
        orderedStops: [
          _stop(id: 1, lat: 48.44, lng: 1.48),
          _stop(id: 2, lat: 48.45, lng: 1.49),
        ],
        depotLat: 48.43,
        depotLng: 1.47,
        avgSpeedKmh: 0,
      );
      expect(segments.length, 2);
      // Duree finie (pas Infinity/NaN) grace au clamp a 30 km/h.
      for (final seg in segments.values) {
        expect(seg.duration.inSeconds, isNonNegative);
      }
    });
  });
}
