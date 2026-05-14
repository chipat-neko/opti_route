// Test d'integration leger : scan bordereau (OCR + parser) → creation
// d'un stop pre-rempli en base. Valide la chaine
// `lignes OCR -> BordereauExtraction -> StopsCompanion -> DB row`
// sans avoir besoin de ML Kit (qui requiert un device Android).
//
// Les "lignes OCR" sont chargees depuis les fixtures de
// `test/fixtures/ocr/` -- elles servent egalement au test baseline
// (cf bordereau_baseline_test.dart).

import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/bordereau_extraction.dart';
import 'package:opti_route/data/bordereau_parser.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/stops_repository.dart';
import 'package:opti_route/data/tournees_repository.dart';

void main() {
  group('Flow integration : scan bordereau -> stop pre-rempli', () {
    late AppDatabase db;
    late TourneesRepository tournees;
    late StopsRepository stops;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      tournees = TourneesRepository(db);
      stops = StopsRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('bordereau MESEXP NOVA : extraction confidence=high -> stop cree',
        () async {
      // 1. Charge le fixture OCR (transcription ideale d'une photo reelle
      //    du dossier bordereaux_test/mesexp/).
      final raw = await File('test/fixtures/ocr/mesexp_bordereau_nova.txt')
          .readAsString();
      final lines = _loadFixture(raw);

      // 2. Parse via BordereauParser (logique pure, sans ML Kit).
      final extraction = BordereauParser().parse(lines);
      expect(extraction.confidence, ExtractionConfidence.high);
      expect(extraction.nomDestinataire, 'NOVA');
      expect(extraction.codePostal, '28190');
      expect(extraction.ville, 'COURVILLE SUR EURE');

      // 3. Construit l'adresse postale comme le fait
      //    AjoutArretScreen apres scan.
      expect(extraction.adressePostale,
          contains('28190 COURVILLE SUR EURE'));
      expect(extraction.rechercheParNom, contains('NOVA'));

      // 4. Cree une tournee + stop pre-rempli depuis l'extraction.
      //    On simule la suite du flow : nomClient = nomDestinataire,
      //    adresseBrute = adressePostale, nbColis = extraction.nbColis.
      //    (Pas de geocodage reseau dans ce test : lat/lng restent null
      //    et le retry hors-ligne s'en chargera.)
      final tId = await tournees.create(TourneesCompanion.insert(
        nom: 'Tournee scan',
        date: DateTime(2026, 5, 14),
        pointDepartLat: 48.0,
        pointDepartLng: 1.0,
        pointDepartLabel: 'Depot',
      ));
      final sId = await stops.create(StopsCompanion.insert(
        tourneeId: tId,
        adresseBrute: extraction.adressePostale!,
        nomClient: Value(extraction.nomDestinataire),
        nbColis: Value(extraction.nbColis ?? 1),
      ));

      // 5. Verifie que le stop est round-trip correct.
      final s = await stops.getById(sId);
      expect(s, isNotNull);
      expect(s!.nomClient, 'NOVA');
      expect(s.adresseBrute, contains('28190'));
      expect(s.statutLivraison, 'a_livrer');
      // Pas de coords : c'est attendu (geocodage non execute ici).
      expect(s.lat, isNull);
    });

    test('etiquette colis MESEXP DE MATOS : meme flow, format hyphene',
        () async {
      final raw = await File('test/fixtures/ocr/mesexp_colis_dematos.txt')
          .readAsString();
      final lines = _loadFixture(raw);
      final extraction = BordereauParser().parse(lines);

      // Confidence=high meme sur le format "FR-CP-VILLE" hyphene des
      // etiquettes colis Transports France Alliance.
      expect(extraction.confidence, ExtractionConfidence.high);
      expect(extraction.nomDestinataire, contains('DE MATOS'));
      expect(extraction.codePostal, '28240');

      final tId = await tournees.create(TourneesCompanion.insert(
        nom: 'T',
        date: DateTime(2026, 5, 14),
        pointDepartLat: 48.0,
        pointDepartLng: 1.0,
        pointDepartLabel: 'D',
      ));
      final sId = await stops.create(StopsCompanion.insert(
        tourneeId: tId,
        adresseBrute: extraction.adressePostale!,
        nomClient: Value(extraction.nomDestinataire),
      ));
      final s = await stops.getById(sId);
      expect(s!.nomClient, contains('DE MATOS'));
    });

    test('extraction low confidence : stop cree quand meme avec adresse brute',
        () async {
      // Cas degrade : un OCR tres bruite ne donne aucun marqueur fiable.
      // L'app doit quand meme permettre la creation du stop pour que
      // l'utilisateur edite manuellement.
      final extraction = BordereauParser().parse(['blabla', '12345', 'foo']);
      expect(extraction.confidence,
          isIn([ExtractionConfidence.low, ExtractionConfidence.none]));

      final tId = await tournees.create(TourneesCompanion.insert(
        nom: 'T',
        date: DateTime(2026, 5, 14),
        pointDepartLat: 48.0,
        pointDepartLng: 1.0,
        pointDepartLabel: 'D',
      ));
      // En mode low confidence, l'UI tomberait sur l'adresse brute du
      // scan complet (extraction.adressePostale peut etre null).
      // Le stop est creable avec une adresse texte minimale.
      final sId = await stops.create(StopsCompanion.insert(
        tourneeId: tId,
        adresseBrute: extraction.adressePostale ?? 'Saisie manuelle',
      ));
      final s = await stops.getById(sId);
      expect(s, isNotNull);
      expect(s!.statutLivraison, 'a_livrer');
    });
  });
}

/// Convertit le contenu d'une fixture en lignes OCR (idem
/// bordereau_baseline_test.dart). Strip commentaires + frontmatter.
List<String> _loadFixture(String raw) {
  final out = <String>[];
  var inBody = false;
  for (final line in raw.split('\n')) {
    final trimmed = line.trim();
    if (!inBody) {
      if (trimmed == '---') inBody = true;
      continue;
    }
    if (trimmed.isEmpty) continue;
    if (trimmed.startsWith('#')) continue;
    out.add(trimmed);
  }
  return out;
}
