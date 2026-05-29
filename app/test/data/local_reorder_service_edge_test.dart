import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/local_reorder_service.dart';

// Complete local_reorder_service_test : tous-eviter, tous-sansCoords,
// ordrePriorite null/duplique, et massif (50 stops).
void main() {
  group('LocalReorderService.computeOrder — cas-limites groupes', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    Future<(Tournee, List<Stop>)> seed({
      required (double, double) depot,
      required List<({double? lat, double? lng, String priorite, int? ordre})>
          specs,
    }) async {
      final tourneeId = await db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: 'T',
              date: DateTime(2026, 5, 29),
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
                lat: specs[i].lat != null
                    ? Value(specs[i].lat)
                    : const Value.absent(),
                lng: specs[i].lng != null
                    ? Value(specs[i].lng)
                    : const Value.absent(),
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

    test('tous "eviter" : ordre stable par id, pas de NN', () async {
      final (tournee, stops) = await seed(
        depot: (48.0, 2.0),
        specs: [
          (lat: 48.05, lng: 2.0, priorite: 'eviter', ordre: null),
          (lat: 48.01, lng: 2.0, priorite: 'eviter', ordre: null),
          (lat: 48.03, lng: 2.0, priorite: 'eviter', ordre: null),
        ],
      );
      final out = LocalReorderService.computeOrder(
        tournee: tournee,
        stops: stops,
      );
      // Tous eviter -> ordre id ascendant, peu importe la geographie
      expect(out, [stops[0].id, stops[1].id, stops[2].id]);
    });

    test('tous sansCoords : tous a la fin (ordre d\'insertion preserve)',
        () async {
      final (tournee, stops) = await seed(
        depot: (48.0, 2.0),
        specs: [
          (lat: null, lng: null, priorite: 'flexible', ordre: null),
          (lat: null, lng: null, priorite: 'flexible', ordre: null),
        ],
      );
      final out = LocalReorderService.computeOrder(
        tournee: tournee,
        stops: stops,
      );
      expect(out, [stops[0].id, stops[1].id]);
    });

    test('priorite obligatoire_premier mais sansCoords : -> bucket sansCoords',
        () async {
      // Un stop avec priorite "premier" mais sans coords ne peut pas
      // etre place en debut (NN ne sait pas calculer). Il doit aller
      // dans sansCoords (en fin) plutot que crasher.
      final (tournee, stops) = await seed(
        depot: (48.0, 2.0),
        specs: [
          (lat: 48.01, lng: 2.0, priorite: 'flexible', ordre: null),
          (lat: null, lng: null, priorite: 'obligatoire_premier', ordre: 1),
        ],
      );
      final out = LocalReorderService.computeOrder(
        tournee: tournee,
        stops: stops,
      );
      // Flexible(0) traite, puis le "premier sans coords" rejete en fin.
      expect(out, [stops[0].id, stops[1].id]);
    });

    test('ordrePriorite null dans obligatoire_premier : non-null d\'abord',
        () async {
      final (tournee, stops) = await seed(
        depot: (48.0, 2.0),
        specs: [
          (lat: 48.01, lng: 2.0, priorite: 'obligatoire_premier', ordre: null),
          (lat: 48.02, lng: 2.0, priorite: 'obligatoire_premier', ordre: 1),
          (lat: 48.03, lng: 2.0, priorite: 'obligatoire_premier', ordre: 2),
        ],
      );
      final out = LocalReorderService.computeOrder(
        tournee: tournee,
        stops: stops,
      );
      // ordre 1 puis 2 puis null (au dernier rang du groupe premier)
      expect(out, [stops[1].id, stops[2].id, stops[0].id]);
    });

    test('ordrePriorite duplique : tie-break par id ascendant', () async {
      final (tournee, stops) = await seed(
        depot: (48.0, 2.0),
        specs: [
          (lat: 48.01, lng: 2.0, priorite: 'obligatoire_premier', ordre: 1),
          (lat: 48.02, lng: 2.0, priorite: 'obligatoire_premier', ordre: 1),
        ],
      );
      final out = LocalReorderService.computeOrder(
        tournee: tournee,
        stops: stops,
      );
      // Meme ordre 1 -> id ascendant
      expect(out, [stops[0].id, stops[1].id]);
    });

    test('priorite inconnue : traitee comme "flexible"', () async {
      // Switch default -> bucket flexibles. On vise la branche fallback
      // pour eviter qu'un futur ajout de priorite oublie le default.
      final (tournee, stops) = await seed(
        depot: (48.0, 2.0),
        specs: [
          (lat: 48.05, lng: 2.0, priorite: 'inconnue_xyz', ordre: null),
          (lat: 48.01, lng: 2.0, priorite: 'inconnue_xyz', ordre: null),
        ],
      );
      final out = LocalReorderService.computeOrder(
        tournee: tournee,
        stops: stops,
      );
      // NN normal : le plus proche (48.01) d'abord
      expect(out, [stops[1].id, stops[0].id]);
    });

    test('20 stops aleatoires : pas de crash, length conservee', () async {
      final specs = List.generate(
        20,
        (i) => (
          lat: 48.0 + (i % 5) * 0.01,
          lng: 2.0 + (i ~/ 5) * 0.01,
          priorite: 'flexible',
          ordre: null,
        ),
      );
      final (tournee, stops) = await seed(depot: (48.0, 2.0), specs: specs);
      final out = LocalReorderService.computeOrder(
        tournee: tournee,
        stops: stops,
      );
      expect(out.length, 20);
      expect(out.toSet().length, 20, reason: 'pas de doublons d\'id');
      expect(out.toSet(), stops.map((s) => s.id).toSet());
    });

    test('3 stops : skip 2-opt (length < 4) mais NN s\'applique', () async {
      // 2-opt early-return si length < 4, mais le NN doit quand meme
      // ordonner les 3 stops du plus proche au plus loin.
      final (tournee, stops) = await seed(
        depot: (48.0, 2.0),
        specs: [
          (lat: 48.05, lng: 2.0, priorite: 'flexible', ordre: null),
          (lat: 48.01, lng: 2.0, priorite: 'flexible', ordre: null),
          (lat: 48.03, lng: 2.0, priorite: 'flexible', ordre: null),
        ],
      );
      final out = LocalReorderService.computeOrder(
        tournee: tournee,
        stops: stops,
      );
      expect(out, [stops[1].id, stops[2].id, stops[0].id]);
    });

    test('mix complet : premier + flexibles + dernier + eviter + sansCoords',
        () async {
      final (tournee, stops) = await seed(
        depot: (48.0, 2.0),
        specs: [
          (lat: 48.10, lng: 2.0, priorite: 'obligatoire_premier', ordre: 1),
          (lat: 48.20, lng: 2.0, priorite: 'flexible', ordre: null),
          (lat: 48.30, lng: 2.0, priorite: 'obligatoire_dernier', ordre: 1),
          (lat: 48.05, lng: 2.0, priorite: 'eviter', ordre: null),
          (lat: null, lng: null, priorite: 'flexible', ordre: null),
        ],
      );
      final out = LocalReorderService.computeOrder(
        tournee: tournee,
        stops: stops,
      );
      // Premier(0) -> flexible(1) -> dernier(2) -> eviter(3) -> sansCoords(4)
      expect(out, [stops[0].id, stops[1].id, stops[2].id, stops[3].id, stops[4].id]);
    });
  });
}
