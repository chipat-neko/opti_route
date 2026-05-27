import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/doublon_detection_service.dart';
import 'package:opti_route/data/saved_destinations_repository.dart';

/// Tests de la detection de doublons carnet (carte #103) :
/// [DoublonDetectionService.detect] (pur) + [SavedDestinationsRepository
/// .mergeInto] (fusion). DB Drift en memoire pour de vraies rows.
void main() {
  late AppDatabase db;
  late SavedDestinationsRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = SavedDestinationsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> seed({
    String? nom,
    required String adresse,
    required double lat,
    required double lng,
    String? rue,
    String? cp,
    String? ville,
    int useCount = 1,
    bool favori = false,
    String? tel,
  }) {
    return db.into(db.savedDestinations).insert(
          SavedDestinationsCompanion.insert(
            nomClient: Value(nom),
            adresseDisplay: adresse,
            lat: lat,
            lng: lng,
            rue: Value(rue),
            codePostal: Value(cp),
            ville: Value(ville),
            useCount: Value(useCount),
            isFavori: Value(favori),
            telephone: Value(tel),
          ),
        );
  }

  Future<List<DoublonPaire>> detect() async {
    final all = await db.select(db.savedDestinations).get();
    return DoublonDetectionService.detect(all);
  }

  test('carnet vide -> aucune paire', () async {
    expect(await detect(), isEmpty);
  });

  test('nom similaire + GPS proche -> doublon', () async {
    await seed(nom: 'Garage Dupont', adresse: '1 rue A', lat: 48.4500, lng: 1.4900);
    await seed(nom: 'Garage Dupon', adresse: '1 rue A bis', lat: 48.4504, lng: 1.4901);

    final paires = await detect();
    expect(paires, hasLength(1));
    expect(paires.single.raison, contains('Nom similaire'));
  });

  test('meme adresseDisplay -> doublon (meme adresse)', () async {
    await seed(nom: 'Client X', adresse: '5 Avenue des Lilas, Chartres', lat: 48.45, lng: 1.49);
    await seed(nom: 'Client Y', adresse: '5 Avenue des Lilas, Chartres', lat: 48.46, lng: 1.50);

    final paires = await detect();
    expect(paires, hasLength(1));
    expect(paires.single.raison, 'Meme adresse');
  });

  test('noms differents + loin -> pas de doublon', () async {
    await seed(nom: 'Boulangerie', adresse: 'Paris', lat: 48.85, lng: 2.35);
    await seed(nom: 'Pharmacie', adresse: 'Marseille', lat: 43.30, lng: 5.37);

    expect(await detect(), isEmpty);
  });

  test('meme nom + meme ville mais GPS loin -> doublon', () async {
    // > 100 m d'ecart (donc heuristique 1 ne matche pas), mais meme nom
    // exact + meme ville.
    await seed(nom: 'Mairie', adresse: 'place 1', lat: 48.4500, lng: 1.4900, ville: 'Luce');
    await seed(nom: 'Mairie', adresse: 'place 2', lat: 48.4600, lng: 1.5000, ville: 'Luce');

    final paires = await detect();
    expect(paires, hasLength(1));
    expect(paires.single.raison, 'Meme nom + meme ville');
  });

  test('mergeInto : cumule useCount, comble les vides, supprime le drop',
      () async {
    final keep = await seed(
      nom: 'Client',
      adresse: 'addr',
      lat: 48.45,
      lng: 1.49,
      useCount: 3,
    );
    final drop = await seed(
      nom: 'Client',
      adresse: 'addr',
      lat: 48.45,
      lng: 1.49,
      useCount: 2,
      favori: true,
      tel: '0612345678',
    );

    await repo.mergeInto(keep, drop);

    final rows = await db.select(db.savedDestinations).get();
    expect(rows, hasLength(1));
    final merged = rows.single;
    expect(merged.id, keep);
    expect(merged.useCount, 5); // 3 + 2
    expect(merged.isFavori, isTrue); // OR
    expect(merged.telephone, '0612345678'); // comble le vide depuis drop
  });
}
