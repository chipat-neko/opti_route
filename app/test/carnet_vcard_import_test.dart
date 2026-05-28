import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:opti_route/data/carnet_import_service.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/saved_destinations_repository.dart';

/// Test d'integration de l'import vCard (carte #102) : du .vcf jusqu'aux
/// lignes du carnet (sans geocoder -> on n'utilise que les contacts qui
/// ont des coords GEO).
void main() {
  late AppDatabase db;
  late SavedDestinationsRepository repo;
  late CarnetImportService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = SavedDestinationsRepository(db);
    service = CarnetImportService(repo); // pas de geocoder
  });

  tearDown(() async {
    await db.close();
  });

  test('importe les contacts avec GEO + telephone, ignore sans adresse',
      () async {
    const vcf = '''
BEGIN:VCARD
VERSION:3.0
FN:Garage Dupont
ADR;TYPE=WORK:;;12 rue de la Paix;Chartres;;28000;France
TEL:0612345678
GEO:48.4500;1.4900
END:VCARD
BEGIN:VCARD
VERSION:3.0
FN:Pharmacie Centrale
ADR:;;5 av des Lilas;Luce;;28110;France
GEO:48.4400;1.4700
END:VCARD
BEGIN:VCARD
VERSION:3.0
FN:Contact sans adresse
TEL:0700000000
END:VCARD
''';

    final res = await service.importVcardFromText(vcf);

    expect(res.lineCount, 3);
    expect(res.created, 2); // les 2 avec GEO
    expect(res.rejected, 1); // celui sans adresse (et sans geocoder)

    final all = await repo.getAll();
    expect(all, hasLength(2));
    final dupont = all.firstWhere((d) => d.nomClient == 'Garage Dupont');
    expect(dupont.telephone, '0612345678');
    expect(dupont.ville, 'Chartres');
    expect(dupont.codePostal, '28000');
    expect(dupont.lat, 48.45);
  });

  test('fichier vide / sans carte -> rien importe', () async {
    final res = await service.importVcardFromText('coucou');
    expect(res.created, 0);
    expect(await repo.count(), 0);
  });

  test('re-import du meme contact -> fusionne, pas duplique', () async {
    const vcf = '''
BEGIN:VCARD
FN:Client X
ADR:;;1 rue A;Ville;;10000;France
GEO:48.0;1.0
END:VCARD
''';
    await service.importVcardFromText(vcf);
    final res2 = await service.importVcardFromText(vcf);
    expect(await repo.count(), 1); // pas de doublon
    expect(res2.merged, 1);
  });
}
