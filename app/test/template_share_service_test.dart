import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/stops_repository.dart';
import 'package:opti_route/data/template_share_service.dart';
import 'package:opti_route/data/tournees_repository.dart';

void main() {
  late AppDatabase db;
  late TourneesRepository tournees;
  late StopsRepository stops;
  late TemplateShareService svc;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    tournees = TourneesRepository(db);
    stops = StopsRepository(db);
    svc = TemplateShareService(tournees: tournees, stops: stops);
  });

  tearDown(() async {
    await db.close();
  });

  group('TemplateShareService.importFromJson', () {
    test('importe une tournee + ses stops, isTemplate=true', () async {
      const json = '''
      {
        "version": 1,
        "tournee": {
          "nom": "Tournee Lucas",
          "pointDepartLat": 48.0,
          "pointDepartLng": 1.0,
          "pointDepartLabel": "Depot Lucas",
          "vehiculeCapaciteColis": 50,
          "profilOrs": "driving-hgv",
          "eviterPeages": true
        },
        "stops": [
          {
            "adresseBrute": "12 rue X",
            "nomClient": "Boulangerie A",
            "nbColis": 3,
            "priorite": "obligatoire_premier",
            "ordrePriorite": 1,
            "fenetreDebut": "09:00",
            "fenetreFin": "12:00",
            "dureeArretMin": 5,
            "notes": "Code 1234B"
          },
          {
            "adresseBrute": "5 av Y",
            "priorite": "flexible"
          }
        ]
      }
      ''';

      final newId = await svc.importFromJson(json);
      final t = await tournees.getById(newId);
      expect(t, isNotNull);
      expect(t!.nom, '[Import] Tournee Lucas');
      expect(t.isTemplate, true);
      expect(t.profilOrs, 'driving-hgv');
      expect(t.eviterPeages, true);
      expect(t.vehiculeCapaciteColis, 50);

      final stopsList = await stops.getByTournee(newId);
      expect(stopsList, hasLength(2));
      // Stops importes : pas de coords (sera re-geocode au prochain
      // retour reseau via OfflineGeocodeAutomation).
      expect(stopsList.every((s) => s.lat == null), true);
      // 1er stop : champs detailles preserves
      final s1 = stopsList.firstWhere((s) => s.adresseBrute == '12 rue X');
      expect(s1.nomClient, 'Boulangerie A');
      expect(s1.nbColis, 3);
      expect(s1.priorite, 'obligatoire_premier');
      expect(s1.ordrePriorite, 1);
      expect(s1.fenetreDebut, '09:00');
      expect(s1.notes, 'Code 1234B');
      // 2e stop : defaults appliques
      final s2 = stopsList.firstWhere((s) => s.adresseBrute == '5 av Y');
      expect(s2.nbColis, 1);
      expect(s2.priorite, 'flexible');
      expect(s2.dureeArretMin, 3);
    });

    test('rejette version future', () async {
      const json = '''
      {"version": 99, "tournee": {}, "stops": []}
      ''';
      await expectLater(
        () => svc.importFromJson(json),
        throwsA(isA<TemplateShareException>().having(
          (e) => e.message,
          'message',
          contains('non supportee'),
        )),
      );
    });

    test('rejette JSON malforme', () async {
      await expectLater(
        () => svc.importFromJson('{ pas du json valide'),
        throwsA(isA<TemplateShareException>().having(
          (e) => e.message,
          'message',
          contains('non parsable'),
        )),
      );
    });

    test('rejette structure incomplete (point depart manquant)', () async {
      const json = '''
      {"version": 1, "tournee": {"nom": "X"}, "stops": []}
      ''';
      await expectLater(
        () => svc.importFromJson(json),
        throwsA(isA<TemplateShareException>().having(
          (e) => e.message,
          'message',
          contains('Point de depart'),
        )),
      );
    });

    test('rejette nom vide', () async {
      const json = '''
      {
        "version": 1,
        "tournee": {
          "nom": "  ",
          "pointDepartLat": 48.0,
          "pointDepartLng": 1.0,
          "pointDepartLabel": "X"
        },
        "stops": []
      }
      ''';
      await expectLater(
        () => svc.importFromJson(json),
        throwsA(isA<TemplateShareException>().having(
          (e) => e.message,
          'message',
          contains('Nom'),
        )),
      );
    });

    test('round-trip : export -> import -> egalite des champs cles',
        () async {
      // Cree une tournee + stop en base
      final srcId = await tournees.create(TourneesCompanion.insert(
        nom: 'Source',
        date: DateTime(2026, 5, 14),
        pointDepartLat: 48.5,
        pointDepartLng: 1.5,
        pointDepartLabel: 'Depot test',
        vehiculeCapaciteColis: const Value(30),
      ));
      await stops.create(StopsCompanion.insert(
        tourneeId: srcId,
        adresseBrute: '12 rue test',
        nomClient: const Value('Client test'),
        nbColis: const Value(2),
        notes: const Value('note importante'),
      ));

      // Serialise manuellement (on n'a pas acces a la methode privee,
      // on simule un import direct depuis un JSON construit).
      final srcTournee = await tournees.getById(srcId);
      final srcStops = await stops.getByTournee(srcId);
      // Simule l'export sans appeler share natif
      final exportJson = {
        'version': 1,
        'tournee': {
          'nom': srcTournee!.nom,
          'pointDepartLat': srcTournee.pointDepartLat,
          'pointDepartLng': srcTournee.pointDepartLng,
          'pointDepartLabel': srcTournee.pointDepartLabel,
          'vehiculeCapaciteColis': srcTournee.vehiculeCapaciteColis,
          'profilOrs': srcTournee.profilOrs,
          'eviterPeages': srcTournee.eviterPeages,
        },
        'stops': [
          for (final s in srcStops)
            {
              'adresseBrute': s.adresseBrute,
              'nomClient': s.nomClient,
              'nbColis': s.nbColis,
              'priorite': s.priorite,
              'notes': s.notes,
            },
        ],
      };
      // Importe
      final newId = await svc.importFromJson(
        const _JsonHelper().encode(exportJson),
      );
      final imported = await tournees.getById(newId);
      final importedStops = await stops.getByTournee(newId);
      expect(imported!.nom, '[Import] Source');
      expect(imported.pointDepartLabel, 'Depot test');
      expect(imported.vehiculeCapaciteColis, 30);
      expect(importedStops, hasLength(1));
      expect(importedStops.first.adresseBrute, '12 rue test');
      expect(importedStops.first.nomClient, 'Client test');
      expect(importedStops.first.notes, 'note importante');
    });
  });
}

/// Helper minimaliste pour eviter d'importer dart:convert dans le test
/// principal (lisibilite).
class _JsonHelper {
  const _JsonHelper();
  String encode(Map<String, dynamic> m) {
    // Ré-utilise jsonEncode mais isole l'import :
    final buf = StringBuffer('{');
    var first = true;
    void writeKV(String k, dynamic v) {
      if (!first) buf.write(',');
      first = false;
      buf.write('"$k":');
      _writeValue(buf, v);
    }

    m.forEach(writeKV);
    buf.write('}');
    return buf.toString();
  }

  void _writeValue(StringBuffer buf, dynamic v) {
    if (v == null) {
      buf.write('null');
    } else if (v is bool) {
      buf.write(v ? 'true' : 'false');
    } else if (v is num) {
      buf.write(v);
    } else if (v is String) {
      buf.write('"${v.replaceAll('"', '\\"')}"');
    } else if (v is Map<String, dynamic>) {
      buf.write(encode(v));
    } else if (v is List) {
      buf.write('[');
      var first = true;
      for (final e in v) {
        if (!first) buf.write(',');
        first = false;
        _writeValue(buf, e);
      }
      buf.write(']');
    } else {
      buf.write('null');
    }
  }
}
