import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:opti_route/data/chef_stats_service.dart';
import 'package:opti_route/data/database.dart';

/// Tests de la fonction pure [ChefStatsJour.computeFromBundle] (epopee
/// #88, [#88·4]) : compteurs agreges + alertes (taux d'echec eleve,
/// tournee bloquee, tournee a cloturer, tri par gravite). On seed une
/// DB Drift en memoire puis on relit les rows pour les passer a la
/// fonction pure (meme pattern que stats_service_test).
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> seedTournee({
    required String nom,
    required String statut,
    int? distanceM,
  }) {
    return db.into(db.tournees).insert(
          TourneesCompanion.insert(
            nom: nom,
            date: DateTime.now(),
            pointDepartLat: 48.0,
            pointDepartLng: 1.0,
            pointDepartLabel: 'D',
            statut: Value(statut),
            distanceTotaleM: Value(distanceM),
          ),
        );
  }

  Future<void> seedStop(
    int tourneeId,
    String statut, {
    int nbColis = 1,
  }) async {
    final sId = await db.into(db.stops).insert(
          StopsCompanion.insert(
            tourneeId: tourneeId,
            adresseBrute: 'A',
            nbColis: Value(nbColis),
          ),
        );
    if (statut != 'a_livrer') {
      final row = await (db.select(db.stops)
            ..where((s) => s.id.equals(sId)))
          .getSingle();
      await db.update(db.stops).replace(
            row.copyWith(statutLivraison: statut),
          );
    }
  }

  Future<ChefStatsJour> compute() async {
    final tournees = await db.select(db.tournees).get();
    final stops = await db.select(db.stops).get();
    return ChefStatsJour.computeFromBundle(
      tournees: tournees,
      stops: stops,
    );
  }

  test('bundle vide -> empty', () {
    final s = ChefStatsJour.computeFromBundle(
      tournees: const [],
      stops: const [],
    );
    expect(s.nbTournees, 0);
    expect(s.alertes, isEmpty);
    expect(identical(s, ChefStatsJour.empty), isTrue);
  });

  test('compteurs de base : livres / echecs / restants / colis', () async {
    final t = await seedTournee(nom: 'T', statut: 'terminee');
    await seedStop(t, 'livre', nbColis: 3);
    await seedStop(t, 'livre', nbColis: 2);
    await seedStop(t, 'echec');
    await seedStop(t, 'a_livrer');
    await seedStop(t, 'a_livrer');

    final s = await compute();
    expect(s.nbTournees, 1);
    expect(s.totalStops, 5);
    expect(s.nbLivres, 2);
    expect(s.nbEchecs, 1);
    expect(s.restants, 2);
    expect(s.colisLivres, 5);
    expect(s.tauxReussite, closeTo(2 / 3, 0.001));
  });

  test('distance cumulee sur plusieurs tournees -> km', () async {
    await seedTournee(nom: 'A', statut: 'terminee', distanceM: 12000);
    await seedTournee(nom: 'B', statut: 'terminee', distanceM: 8500);

    final s = await compute();
    expect(s.distanceMeters, 20500);
    expect(s.distanceKm, closeTo(20.5, 0.001));
  });

  test('alerte critique si taux d\'echec > 20% sur echantillon suffisant',
      () async {
    final t = await seedTournee(nom: 'T', statut: 'terminee');
    // 4 livres + 2 echecs = 6 tentatives, 33% echec.
    for (var i = 0; i < 4; i++) {
      await seedStop(t, 'livre');
    }
    await seedStop(t, 'echec');
    await seedStop(t, 'echec');

    final s = await compute();
    expect(
      s.alertes.any((a) => a.severite == ChefAlerteSeverite.critique),
      isTrue,
    );
  });

  test('pas d\'alerte taux d\'echec sur echantillon trop petit', () async {
    final t = await seedTournee(nom: 'T', statut: 'terminee');
    // 1 seule tentative en echec : < kMinTentativesPourAlerte.
    await seedStop(t, 'echec');

    final s = await compute();
    expect(
      s.alertes.any((a) => a.severite == ChefAlerteSeverite.critique),
      isFalse,
    );
  });

  test('alerte attention : tournee en cours sans aucune livraison',
      () async {
    final t = await seedTournee(nom: 'Matin', statut: 'en_cours');
    await seedStop(t, 'a_livrer');
    await seedStop(t, 'a_livrer');
    await seedStop(t, 'a_livrer');

    final s = await compute();
    final att =
        s.alertes.where((a) => a.severite == ChefAlerteSeverite.attention);
    expect(att, hasLength(1));
    expect(att.first.message, contains('Matin'));
  });

  test('alerte info : tournee en cours entierement traitee (a cloturer)',
      () async {
    final t = await seedTournee(nom: 'Aprem', statut: 'en_cours');
    await seedStop(t, 'livre');
    await seedStop(t, 'livre');

    final s = await compute();
    final info =
        s.alertes.where((a) => a.severite == ChefAlerteSeverite.info);
    expect(info, hasLength(1));
    expect(info.first.message, contains('cloturer'));
  });

  test('les alertes sont triees par gravite (critique en premier)',
      () async {
    // Tournee en cours bloquee (attention) ...
    final a = await seedTournee(nom: 'Bloquee', statut: 'en_cours');
    await seedStop(a, 'a_livrer');
    await seedStop(a, 'a_livrer');
    await seedStop(a, 'a_livrer');
    // ... + tournee terminee avec gros taux d'echec (critique).
    final b = await seedTournee(nom: 'Echecs', statut: 'terminee');
    for (var i = 0; i < 4; i++) {
      await seedStop(b, 'livre');
    }
    await seedStop(b, 'echec');
    await seedStop(b, 'echec');

    final s = await compute();
    expect(s.alertes.length, greaterThanOrEqualTo(2));
    expect(s.alertes.first.severite, ChefAlerteSeverite.critique);
  });
}
