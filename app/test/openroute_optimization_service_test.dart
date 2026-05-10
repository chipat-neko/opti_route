import 'dart:convert';

import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/openroute_optimization_service.dart';

void main() {
  group('OpenRouteOptimizationService - ordre des priorites', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    /// Cree une tournee + N stops avec lat/lng + priorite + ordrePriorite.
    Future<(Tournee, List<Stop>)> seedTournee(
      List<({String priorite, int? ordre})> specs,
    ) async {
      final tourneeId = await db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: 'T',
              date: DateTime(2026, 5, 10),
              pointDepartLat: 48.0,
              pointDepartLng: 1.0,
              pointDepartLabel: 'Depot',
            ),
          );
      for (var i = 0; i < specs.length; i++) {
        await db.into(db.stops).insert(
              StopsCompanion.insert(
                tourneeId: tourneeId,
                adresseBrute: 'A$i',
                lat: Value(48.0 + 0.01 * i),
                lng: Value(1.0 + 0.01 * i),
                priorite: Value(specs[i].priorite),
                ordrePriorite: Value(specs[i].ordre),
              ),
            );
      }
      final tournee = await (db.select(db.tournees)
            ..where((t) => t.id.equals(tourneeId)))
          .getSingle();
      final stops = await (db.select(db.stops)
            ..where((s) => s.tourneeId.equals(tourneeId))
            ..orderBy([(s) => OrderingTerm.asc(s.id)]))
          .get();
      return (tournee, stops);
    }

    /// Mock HTTP qui renvoie l'ordre des jobs tel quel (VROOM = identite).
    /// Permet de verifier que le service respecte les firsts/lasts en
    /// pre/post-traitement, independamment du solveur.
    MockClient mockVroomEcho() {
      return MockClient((req) async {
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        final jobs = body['jobs'] as List;
        final steps = [
          for (final j in jobs)
            {'type': 'job', 'job': (j as Map)['id']},
        ];
        return http.Response(
          jsonEncode({
            'code': 0,
            'summary': {'duration': 0, 'distance': 0},
            'routes': [
              {'duration': 0, 'distance': 0, 'steps': steps},
            ],
          }),
          200,
        );
      });
    }

    test('un seul EN 1ER : il est en position 1 dans l\'ordre final',
        () async {
      final (tournee, stops) = await seedTournee([
        (priorite: 'flexible', ordre: null),
        (priorite: 'obligatoire_premier', ordre: 1),
        (priorite: 'flexible', ordre: null),
      ]);
      final svc = OpenRouteOptimizationService(
        apiKey: 'k',
        client: mockVroomEcho(),
      );
      final r = await svc.optimize(tournee: tournee, stops: stops);
      svc.close();
      expect(r.orderedStopIds.first, stops[1].id);
    });

    test('plusieurs EN 1ER : ordre respecte selon ordrePriorite', () async {
      final (tournee, stops) = await seedTournee([
        (priorite: 'flexible', ordre: null),
        (priorite: 'obligatoire_premier', ordre: 2),
        (priorite: 'obligatoire_premier', ordre: 1),
        (priorite: 'obligatoire_premier', ordre: 3),
        (priorite: 'flexible', ordre: null),
      ]);
      final svc = OpenRouteOptimizationService(
        apiKey: 'k',
        client: mockVroomEcho(),
      );
      final r = await svc.optimize(tournee: tournee, stops: stops);
      svc.close();
      // Les 3 firsts doivent etre dans cet ordre : ordre 1, 2, 3.
      expect(r.orderedStopIds[0], stops[2].id); // ordre 1
      expect(r.orderedStopIds[1], stops[1].id); // ordre 2
      expect(r.orderedStopIds[2], stops[3].id); // ordre 3
    });

    test('plusieurs EN DERNIER : ordre respecte en fin de liste', () async {
      final (tournee, stops) = await seedTournee([
        (priorite: 'flexible', ordre: null),
        (priorite: 'obligatoire_dernier', ordre: 2),
        (priorite: 'obligatoire_dernier', ordre: 1),
        (priorite: 'flexible', ordre: null),
      ]);
      final svc = OpenRouteOptimizationService(
        apiKey: 'k',
        client: mockVroomEcho(),
      );
      final r = await svc.optimize(tournee: tournee, stops: stops);
      svc.close();
      // Les 2 derniers : ordre 1 puis ordre 2.
      expect(r.orderedStopIds[r.orderedStopIds.length - 2], stops[2].id);
      expect(r.orderedStopIds.last, stops[1].id);
    });

    test('mix firsts + flexibles + lasts : structure firsts...flex...lasts',
        () async {
      final (tournee, stops) = await seedTournee([
        (priorite: 'obligatoire_premier', ordre: 1),
        (priorite: 'flexible', ordre: null),
        (priorite: 'obligatoire_dernier', ordre: 1),
        (priorite: 'flexible', ordre: null),
        (priorite: 'obligatoire_premier', ordre: 2),
      ]);
      final svc = OpenRouteOptimizationService(
        apiKey: 'k',
        client: mockVroomEcho(),
      );
      final r = await svc.optimize(tournee: tournee, stops: stops);
      svc.close();
      expect(r.orderedStopIds[0], stops[0].id); // first ordre 1
      expect(r.orderedStopIds[1], stops[4].id); // first ordre 2
      // Les flexibles sont au milieu (ordre VROOM = identite ici).
      expect(r.orderedStopIds.last, stops[2].id); // last ordre 1
      expect(r.orderedStopIds, hasLength(5));
    });

    test('100 % firsts + lasts : pas d\'appel VROOM, ordre fixe', () async {
      var apiCalled = false;
      final mock = MockClient((req) async {
        apiCalled = true;
        return http.Response('{}', 500);
      });
      final (tournee, stops) = await seedTournee([
        (priorite: 'obligatoire_premier', ordre: 1),
        (priorite: 'obligatoire_dernier', ordre: 1),
      ]);
      final svc = OpenRouteOptimizationService(apiKey: 'k', client: mock);
      final r = await svc.optimize(tournee: tournee, stops: stops);
      svc.close();
      expect(apiCalled, isFalse);
      expect(r.orderedStopIds, [stops[0].id, stops[1].id]);
    });
  });
}
