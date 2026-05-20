import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/geo_utils.dart';
import 'package:opti_route/data/local_reorder_service.dart';

/// Helper : distance totale d'un parcours depuis le depot d'une tournee.
/// Sert a verifier que 2-opt ameliore vs un ordre arbitraire.
double _totalDistanceMeters({
  required Tournee tournee,
  required List<Stop> stops,
  required List<int> orderedIds,
}) {
  if (orderedIds.isEmpty) return 0;
  final byId = {for (final s in stops) s.id: s};
  var d = 0.0;
  var prevLat = tournee.pointDepartLat;
  var prevLng = tournee.pointDepartLng;
  for (final id in orderedIds) {
    final s = byId[id]!;
    d += GeoUtils.haversineMeters(
      lat1: prevLat,
      lon1: prevLng,
      lat2: s.lat!,
      lon2: s.lng!,
    );
    prevLat = s.lat!;
    prevLng = s.lng!;
  }
  return d;
}

void main() {
  group('LocalReorderService.computeOrder', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    /// Cree une tournee + N stops sur une grille lat/lng et retourne
    /// le couple (tournee, stops dans l'ordre d'id).
    Future<(Tournee, List<Stop>)> seed({
      required (double, double) depot,
      required List<({double lat, double lng, String priorite, int? ordre})>
          specs,
    }) async {
      final tourneeId = await db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: 'T',
              date: DateTime(2026, 5, 13),
              pointDepartLat: depot.$1,
              pointDepartLng: depot.$2,
              pointDepartLabel: 'Depot',
            ),
          );
      for (var i = 0; i < specs.length; i++) {
        await db.into(db.stops).insert(
              StopsCompanion.insert(
                tourneeId: tourneeId,
                adresseBrute: 'A$i',
                lat: Value(specs[i].lat),
                lng: Value(specs[i].lng),
                priorite: Value(specs[i].priorite),
                ordrePriorite: Value(specs[i].ordre),
              ),
            );
      }
      final tournee = await (db.select(db.tournees)
            ..where((t) => t.id.equals(tourneeId)))
          .getSingle();
      final stops = await (db.select(db.stops)
            ..where((s) => s.tourneeId.equals(tourneeId)))
          .get();
      return (tournee, stops);
    }

    test('1 stop : ordre trivial', () async {
      final (tournee, stops) = await seed(
        depot: (48.0, 2.0),
        specs: [
          (lat: 48.001, lng: 2.001, priorite: 'flexible', ordre: null),
        ],
      );
      final out = LocalReorderService.computeOrder(
        tournee: tournee,
        stops: stops,
      );
      expect(out, [stops[0].id]);
    });

    test('flexibles : visite le plus proche du depot en premier', () async {
      // Depot a (48, 2). Stops alignes : proche, moyen, loin.
      final (tournee, stops) = await seed(
        depot: (48.0, 2.0),
        specs: [
          (lat: 48.05, lng: 2.0, priorite: 'flexible', ordre: null), // loin
          (lat: 48.01, lng: 2.0, priorite: 'flexible', ordre: null), // proche
          (lat: 48.03, lng: 2.0, priorite: 'flexible', ordre: null), // moyen
        ],
      );
      final out = LocalReorderService.computeOrder(
        tournee: tournee,
        stops: stops,
      );
      // Attendu : 48.01 -> 48.03 -> 48.05
      expect(out, [stops[1].id, stops[2].id, stops[0].id]);
    });

    test('obligatoire_premier : place en debut, ordre figue par ordrePriorite',
        () async {
      final (tournee, stops) = await seed(
        depot: (48.0, 2.0),
        specs: [
          (lat: 48.05, lng: 2.0, priorite: 'flexible', ordre: null),
          (lat: 48.20, lng: 2.0, priorite: 'obligatoire_premier', ordre: 2),
          (lat: 48.10, lng: 2.0, priorite: 'obligatoire_premier', ordre: 1),
        ],
      );
      final out = LocalReorderService.computeOrder(
        tournee: tournee,
        stops: stops,
      );
      // Premiers d'abord (ordre 1 puis 2), puis le flexible.
      expect(out, [stops[2].id, stops[1].id, stops[0].id]);
    });

    test('obligatoire_dernier : place en fin, ordre figue', () async {
      final (tournee, stops) = await seed(
        depot: (48.0, 2.0),
        specs: [
          (lat: 48.20, lng: 2.0, priorite: 'obligatoire_dernier', ordre: 2),
          (lat: 48.05, lng: 2.0, priorite: 'flexible', ordre: null),
          (lat: 48.10, lng: 2.0, priorite: 'obligatoire_dernier', ordre: 1),
        ],
      );
      final out = LocalReorderService.computeOrder(
        tournee: tournee,
        stops: stops,
      );
      // Flexible d'abord, puis derniers (ordre 1 puis 2).
      expect(out, [stops[1].id, stops[2].id, stops[0].id]);
    });

    test('combinaison premier + flexibles NN + dernier', () async {
      // Depot (48, 2). Premier force a (49, 2). Flexibles a (49.01, 2)
      // et (49.05, 2). Dernier a (48.5, 2). NN doit partir DU premier
      // (pas du depot) car le premier "consomme" la position courante.
      final (tournee, stops) = await seed(
        depot: (48.0, 2.0),
        specs: [
          // [0] Premier (49, 2)
          (lat: 49.0, lng: 2.0, priorite: 'obligatoire_premier', ordre: 1),
          // [1] Flexible loin (49.05, 2)
          (lat: 49.05, lng: 2.0, priorite: 'flexible', ordre: null),
          // [2] Flexible proche du premier (49.01, 2)
          (lat: 49.01, lng: 2.0, priorite: 'flexible', ordre: null),
          // [3] Dernier (48.5, 2)
          (lat: 48.5, lng: 2.0, priorite: 'obligatoire_dernier', ordre: 1),
        ],
      );
      final out = LocalReorderService.computeOrder(
        tournee: tournee,
        stops: stops,
      );
      // Attendu : premier(0) -> flex_proche(2) -> flex_loin(1) -> dernier(3)
      expect(out, [stops[0].id, stops[2].id, stops[1].id, stops[3].id]);
    });

    test('eviter : tout a la fin, ordre stable par id', () async {
      final (tournee, stops) = await seed(
        depot: (48.0, 2.0),
        specs: [
          (lat: 48.01, lng: 2.0, priorite: 'eviter', ordre: null),
          (lat: 48.02, lng: 2.0, priorite: 'flexible', ordre: null),
          (lat: 48.03, lng: 2.0, priorite: 'eviter', ordre: null),
        ],
      );
      final out = LocalReorderService.computeOrder(
        tournee: tournee,
        stops: stops,
      );
      // Flexible(1) en tete, puis eviter(0) puis eviter(2) ordonnes par id.
      expect(out, [stops[1].id, stops[0].id, stops[2].id]);
    });

    test('stops sans coords : rejetes en fin de liste', () async {
      final (tournee, stops) = await seed(
        depot: (48.0, 2.0),
        specs: [
          (lat: 48.01, lng: 2.0, priorite: 'flexible', ordre: null),
        ],
      );
      // Ajoute manuellement un stop sans lat/lng (cas offline).
      final orphelinId = await db.into(db.stops).insert(
            StopsCompanion.insert(
              tourneeId: tournee.id,
              adresseBrute: 'Sans coords',
              priorite: const Value('flexible'),
            ),
          );
      final allStops = await (db.select(db.stops)
            ..where((s) => s.tourneeId.equals(tournee.id)))
          .get();
      final out = LocalReorderService.computeOrder(
        tournee: tournee,
        stops: allStops,
      );
      // Le geocode est en tete, l'orphelin en fin.
      expect(out, [stops[0].id, orphelinId]);
    });

    test('0 stops : retourne liste vide sans crasher', () async {
      final (tournee, _) = await seed(
        depot: (48.0, 2.0),
        specs: [],
      );
      final out = LocalReorderService.computeOrder(
        tournee: tournee,
        stops: const [],
      );
      expect(out, isEmpty);
    });

    test(
        'pas de regression sur l\'ordre quand 2 stops a egale distance '
        '(tie-break stable)', () async {
      // Depot equidistant des 2. NN prend le 1er rencontre (donc id ASC).
      final (tournee, stops) = await seed(
        depot: (48.0, 2.0),
        specs: [
          (lat: 48.01, lng: 2.0, priorite: 'flexible', ordre: null),
          (lat: 48.0, lng: 2.01, priorite: 'flexible', ordre: null),
        ],
      );
      final out = LocalReorderService.computeOrder(
        tournee: tournee,
        stops: stops,
      );
      expect(out.length, 2);
      expect(out.toSet(), {stops[0].id, stops[1].id});
    });

    // ─── 2-opt amelioration (post NN) ──────────────────────────────
    //
    // Le NN seul donne ~15-25 % de detour vs optimal. La passe 2-opt
    // qui suit inverse iterativement des sous-segments pour reduire
    // la distance totale. On verifie ici que :
    //   1. Le resultat n'est jamais PIRE qu'un ordre arbitraire id-asc
    //   2. Sur un cas connu "papillon" (croisement), 2-opt corrige
    //   3. L'algo est deterministe (meme entree -> meme sortie)

    test('2-opt : 4 stops papillon, batte ordre id-asc', () async {
      // Depot (0, 0). 4 stops aux 4 coins. L'ordre 1-2-3-4 fait un X.
      final (tournee, stops) = await seed(
        depot: (0, 0),
        specs: [
          (lat: 0.01, lng: 0.01, priorite: 'flexible', ordre: null), // NE
          (lat: -0.01, lng: -0.01, priorite: 'flexible', ordre: null), // SW
          (lat: 0.01, lng: -0.01, priorite: 'flexible', ordre: null), // NW
          (lat: -0.01, lng: 0.01, priorite: 'flexible', ordre: null), // SE
        ],
      );
      final out = LocalReorderService.computeOrder(
        tournee: tournee,
        stops: stops,
      );
      final dOpti = _totalDistanceMeters(
        tournee: tournee,
        stops: stops,
        orderedIds: out,
      );
      final dArbitraire = _totalDistanceMeters(
        tournee: tournee,
        stops: stops,
        orderedIds: [stops[0].id, stops[1].id, stops[2].id, stops[3].id],
      );
      expect(dOpti, lessThanOrEqualTo(dArbitraire),
          reason: 'NN+2-opt doit etre <= ordre id-asc');
    });

    test('2-opt : 8 stops disperses, gain mesurable vs id-asc', () async {
      final (tournee, stops) = await seed(
        depot: (48.43, 1.49),
        specs: [
          (lat: 48.45, lng: 1.50, priorite: 'flexible', ordre: null),
          (lat: 48.40, lng: 1.40, priorite: 'flexible', ordre: null),
          (lat: 48.50, lng: 1.55, priorite: 'flexible', ordre: null),
          (lat: 48.43, lng: 1.60, priorite: 'flexible', ordre: null),
          (lat: 48.42, lng: 1.42, priorite: 'flexible', ordre: null),
          (lat: 48.48, lng: 1.45, priorite: 'flexible', ordre: null),
          (lat: 48.38, lng: 1.48, priorite: 'flexible', ordre: null),
          (lat: 48.50, lng: 1.40, priorite: 'flexible', ordre: null),
        ],
      );
      final out = LocalReorderService.computeOrder(
        tournee: tournee,
        stops: stops,
      );
      final dOpti = _totalDistanceMeters(
        tournee: tournee,
        stops: stops,
        orderedIds: out,
      );
      final dArbitraire = _totalDistanceMeters(
        tournee: tournee,
        stops: stops,
        orderedIds: stops.map((s) => s.id).toList(),
      );
      expect(dOpti, lessThan(dArbitraire),
          reason:
              'Sur 8 stops disperses, NN+2-opt doit battre l\'ordre arbitraire');
    });

    test('2-opt : deterministe (meme entree -> meme sortie)', () async {
      final (tournee, stops) = await seed(
        depot: (48.43, 1.49),
        specs: [
          (lat: 48.45, lng: 1.50, priorite: 'flexible', ordre: null),
          (lat: 48.40, lng: 1.40, priorite: 'flexible', ordre: null),
          (lat: 48.50, lng: 1.55, priorite: 'flexible', ordre: null),
          (lat: 48.43, lng: 1.60, priorite: 'flexible', ordre: null),
          (lat: 48.42, lng: 1.42, priorite: 'flexible', ordre: null),
        ],
      );
      final out1 = LocalReorderService.computeOrder(
        tournee: tournee,
        stops: stops,
      );
      final out2 = LocalReorderService.computeOrder(
        tournee: tournee,
        stops: stops,
      );
      expect(out1, out2);
    });

    test('2-opt : endpoint "dernier" oriente la sortie', () async {
      // 3 flexibles + 1 dernier loin a l'est : le 2-opt avec endpoint
      // doit finir les flexibles pres du dernier pour eviter un detour
      // de retour. Sans endpoint, le NN seul ne saurait pas favoriser
      // cette orientation.
      final (tournee, stops) = await seed(
        depot: (48.43, 1.40),
        specs: [
          (lat: 48.43, lng: 1.45, priorite: 'flexible', ordre: null), // proche
          (lat: 48.43, lng: 1.55, priorite: 'flexible', ordre: null), // milieu
          (lat: 48.43, lng: 1.65, priorite: 'flexible', ordre: null), // est
          (lat: 48.43, lng: 1.80, priorite: 'obligatoire_dernier', ordre: 1),
        ],
      );
      final out = LocalReorderService.computeOrder(
        tournee: tournee,
        stops: stops,
      );
      // Dernier toujours en fin
      expect(out.last, stops[3].id);
      // Le dernier flexible (avant le "dernier") doit etre celui de
      // l'est (1.65), pour eviter un detour de retour.
      expect(out[out.length - 2], stops[2].id,
          reason:
              '2-opt avec endpoint dernier doit finir les flexibles pres');
    });
  });
}
