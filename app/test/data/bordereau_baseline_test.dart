import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/bordereau_extraction.dart';
import 'package:opti_route/data/bordereau_parser.dart';

/// ════════════════════════════════════════════════════════════════
/// Baseline OCR Phase A : mesure de la confiance d'extraction sur
/// un corpus de fixtures statiques.
/// ════════════════════════════════════════════════════════════════
///
/// **Objectif** : verifier que les parsers actuels produisent au
/// minimum 90 % de [ExtractionConfidence.high] sur un echantillon
/// representatif des bordereaux reels que Noah scanne (cf
/// `bordereaux_test/` a la racine du repo, photos exportees de son
/// telephone).
///
/// **Limite** : les fixtures sont une transcription "ideale" du
/// contenu visible -- elles servent de BORNE SUPERIEURE. Le vrai
/// taux ML Kit en production sera plus bas (caracteres mal reconnus,
/// lignes melangees, photos sombres...). Pour la mesure terrain, c'est
/// le CSV de [OcrStatsLog] qui fait foi.
///
/// **Comment ajouter une fixture** :
/// 1. Photographier un bordereau exemple (cf bordereaux_test/)
/// 2. Transcrire le texte visible en respectant l'ordre top-to-bottom
///    que ML Kit produirait (label puis valeur, colonne par colonne)
/// 3. Sauver dans test/fixtures/ocr/{slug}.txt
/// 4. Ajouter une entree dans [_fixtures] avec le destinataire attendu
///
/// Le test affiche un rapport en fin de run avec le detail par fixture.
void main() {
  test('baseline OCR : >= 90% des fixtures donnent confidence high',
      () async {
    final results = <_FixtureResult>[];
    for (final f in _fixtures) {
      final file = File('test/fixtures/ocr/${f.filename}');
      expect(await file.exists(), isTrue,
          reason: 'Fixture manquante : ${f.filename}');
      final lines = _loadFixture(await file.readAsString());
      final result = BordereauParser().parse(lines);
      results.add(_FixtureResult(fixture: f, extraction: result));
    }

    // Rapport detaille : utile en CI / quand on debogue une regression.
    final report = StringBuffer()..writeln('\n=== Baseline OCR ===');
    for (final r in results) {
      final mark = r.extraction.confidence == ExtractionConfidence.high
          ? 'OK'
          : 'KO';
      report.writeln('[$mark] ${r.fixture.filename}');
      report.writeln('     nom=${r.extraction.nomDestinataire}');
      report.writeln('     cp=${r.extraction.codePostal} '
          'ville=${r.extraction.ville}');
      report.writeln('     confidence=${r.extraction.confidence.name}');
    }
    final high = results
        .where((r) => r.extraction.confidence == ExtractionConfidence.high)
        .length;
    final ratio = high / results.length;
    report.writeln('=== Total : $high/${results.length} '
        '(${(ratio * 100).toStringAsFixed(1)} %) ===');
    // ignore: avoid_print
    print(report);

    expect(ratio, greaterThanOrEqualTo(0.90),
        reason: 'Cible Phase A : >= 90 % carte verte sur fixtures.');
  });

  test('chaque fixture extrait au moins le destinataire ou la ville',
      () async {
    for (final f in _fixtures) {
      final file = File('test/fixtures/ocr/${f.filename}');
      final lines = _loadFixture(await file.readAsString());
      final r = BordereauParser().parse(lines);
      final hasNom = r.nomDestinataire != null && r.nomDestinataire!.isNotEmpty;
      final hasVille =
          r.ville != null || (r.codePostal != null && r.codePostal!.isNotEmpty);
      expect(hasNom || hasVille, isTrue,
          reason: '${f.filename} : ni nom ni ville extraits');
    }
  });
}

/// Convertit le contenu d'un fichier fixture en lignes OCR utilisables.
/// Strip les commentaires `#...`, ignore le separateur `---`, conserve
/// l'ordre top-to-bottom et les lignes non vides.
List<String> _loadFixture(String raw) {
  final out = <String>[];
  var inBody = false;
  for (final line in raw.split('\n')) {
    final trimmed = line.trim();
    if (!inBody) {
      if (trimmed == '---') {
        inBody = true;
      }
      continue;
    }
    if (trimmed.isEmpty) continue;
    if (trimmed.startsWith('#')) continue;
    out.add(trimmed);
  }
  return out;
}

/// Catalogue des fixtures et de leur destinataire attendu. Chaque entree
/// est documentee (chemin de la photo source dans `bordereaux_test/`)
/// pour que Noah puisse retrouver l'image originale en cas de regression.
const _fixtures = [
  _Fixture(
    filename: 'mesexp_bordereau_nova.txt',
    expectedNomContains: 'NOVA',
    expectedCp: '28190',
  ),
  _Fixture(
    filename: 'mesexp_bordereau_atelier.txt',
    expectedNomContains: 'ATELIER',
    expectedCp: '28240',
  ),
  _Fixture(
    filename: 'mesexp_colis_dematos.txt',
    expectedNomContains: 'DE MATOS',
    expectedCp: '28240',
  ),
  _Fixture(
    filename: 'mesexp_colis_nova.txt',
    expectedNomContains: 'NOVA',
    expectedCp: '28190',
  ),
];

class _Fixture {
  const _Fixture({
    required this.filename,
    required this.expectedNomContains,
    required this.expectedCp,
  });
  final String filename;
  final String expectedNomContains;
  final String expectedCp;
}

class _FixtureResult {
  const _FixtureResult({required this.fixture, required this.extraction});
  final _Fixture fixture;
  final BordereauExtraction extraction;
}
