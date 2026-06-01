import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/parametres_repository.dart';

/// Tests du flag profil_type (écran « Qui es-tu ? », carte #373).
void main() {
  late AppDatabase db;
  late ParametresRepository params;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    params = ParametresRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('défaut null (écran « Qui es-tu ? » à afficher)', () async {
    expect(await params.getProfilType(), isNull);
  });

  test('setProfilType solo persiste', () async {
    await params.setProfilType('solo');
    expect(await params.getProfilType(), 'solo');
  });

  test('setProfilType chef_entreprise persiste', () async {
    await params.setProfilType('chef_entreprise');
    expect(await params.getProfilType(), 'chef_entreprise');
  });

  test('setProfilType employe persiste', () async {
    await params.setProfilType('employe');
    expect(await params.getProfilType(), 'employe');
  });

  test('clearProfilType remet à null (ré-affiche l\'écran)', () async {
    await params.setProfilType('employe');
    expect(await params.getProfilType(), 'employe');
    await params.clearProfilType();
    expect(await params.getProfilType(), isNull);
  });

  test('watch émet la valeur courante', () async {
    await params.setProfilType('solo');
    expect(await params.watchProfilType().first, 'solo');
  });
}
