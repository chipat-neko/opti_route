import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/screens/tournee_du_jour/prochain_arret_card.dart';

/// Tests de la fonction de selection `firstAlivrerWithCoords` utilisee
/// par `ProchainArretCard` pour determiner le prochain stop (carte
/// Trello #149).
///
/// Scenario du bug Noah :
///   1. Le card affiche stop1 -> Maps lance la nav vers stop1 OK
///   2. Noah valide stop1 livre -> l'UI bascule sur stop2 OK
///   3. Re-tap Maps -> doit lancer la nav vers stop2 (pas stop1)
///
/// La fonction `firstAlivrerWithCoords` doit donc TOUJOURS retourner
/// le premier stop encore `a_livrer` avec des coords, et jamais un
/// stop deja `livre`.
void main() {
  group('firstAlivrerWithCoords', () {
    test('retourne le premier stop a_livrer avec coords', () {
      final stops = [
        _stop(id: 1, statut: 'a_livrer', lat: 48.0, lng: 1.0),
        _stop(id: 2, statut: 'a_livrer', lat: 48.1, lng: 1.1),
      ];
      final r = firstAlivrerWithCoords(stops);
      expect(r, isNotNull);
      expect(r!.id, 1);
    });

    test('apres validation stop 1 livre -> retourne stop 2', () {
      // Reproduction exacte du bug Trello #149 : on commence avec 2
      // stops a_livrer (la fonction renvoie stop1). On valide stop1
      // (statut passe a 'livre'). Au tap suivant, la fonction doit
      // renvoyer stop2, JAMAIS stop1.
      var stops = [
        _stop(id: 1, statut: 'a_livrer', lat: 48.0, lng: 1.0),
        _stop(id: 2, statut: 'a_livrer', lat: 48.1, lng: 1.1),
      ];
      final premier = firstAlivrerWithCoords(stops);
      expect(premier!.id, 1, reason: 'premier tap = stop 1');

      // Simule la mise a jour DB : stop 1 -> livre
      stops = [
        _stop(id: 1, statut: 'livre', lat: 48.0, lng: 1.0),
        _stop(id: 2, statut: 'a_livrer', lat: 48.1, lng: 1.1),
      ];
      final second = firstAlivrerWithCoords(stops);
      expect(second, isNotNull, reason: 'doit trouver stop 2');
      expect(second!.id, 2, reason: 'second tap = stop 2 (pas stop 1)');
      expect(second.lat, 48.1);
      expect(second.lng, 1.1);
    });

    test('skip stops echec', () {
      final stops = [
        _stop(id: 1, statut: 'echec', lat: 48.0, lng: 1.0),
        _stop(id: 2, statut: 'a_livrer', lat: 48.1, lng: 1.1),
      ];
      final r = firstAlivrerWithCoords(stops);
      expect(r!.id, 2);
    });

    test('skip stops sans coords GPS', () {
      final stops = [
        _stop(id: 1, statut: 'a_livrer', lat: null, lng: null),
        _stop(id: 2, statut: 'a_livrer', lat: 48.1, lng: 1.1),
      ];
      final r = firstAlivrerWithCoords(stops);
      expect(r!.id, 2);
    });

    test('liste vide -> null', () {
      expect(firstAlivrerWithCoords(const []), isNull);
    });

    test('tous livre/echec -> null (tournee terminee)', () {
      final stops = [
        _stop(id: 1, statut: 'livre', lat: 48.0, lng: 1.0),
        _stop(id: 2, statut: 'echec', lat: 48.1, lng: 1.1),
      ];
      expect(firstAlivrerWithCoords(stops), isNull);
    });
  });
}

Stop _stop({
  required int id,
  required String statut,
  required double? lat,
  required double? lng,
}) {
  final now = DateTime(2026, 5, 26, 12);
  return Stop(
    id: id,
    tourneeId: 1,
    adresseBrute: 'Adresse $id',
    type: 'livraison',
    lat: lat,
    lng: lng,
    nbColis: 1,
    priorite: 'flexible',
    dureeArretMin: 2,
    statutLivraison: statut,
    positionLocked: false,
    creeLe: now,
    updatedAt: now,
  );
}
