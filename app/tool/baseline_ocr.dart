// ignore_for_file: avoid_print
// Script ad-hoc pour valider la baseline OCR en pur Dart, sans
// passer par `flutter test` (qui crash sur le lock Windows
// sqlite3.dll, cf project_pending_flutter_test_validation).
//
// Usage : dart tool/baseline_ocr.dart
//
// Imprime le rapport et exit 0 si >= 90 % carte verte, exit 1 sinon.
// La CI Linux relance le vrai test via `flutter test`.

import 'dart:io';

import 'package:opti_route/data/bordereau_extraction.dart';
import 'package:opti_route/data/bordereau_parser.dart';

void main() async {
  final fixtures = [
    ('mesexp_bordereau_nova.txt', 'NOVA', '28190'),
    ('mesexp_bordereau_atelier.txt', 'ATELIER', '28240'),
    ('mesexp_colis_dematos.txt', 'DE MATOS', '28240'),
    ('mesexp_colis_nova.txt', 'NOVA', '28190'),
  ];

  var high = 0;
  final report = StringBuffer()..writeln('\n=== Baseline OCR ===');
  for (final (name, nomAttendu, cpAttendu) in fixtures) {
    final raw = await File('test/fixtures/ocr/$name').readAsString();
    final lines = _loadFixture(raw);
    final r = BordereauParser().parse(lines);
    final ok = r.confidence == ExtractionConfidence.high;
    if (ok) high++;
    report.writeln('[${ok ? 'OK' : 'KO'}] $name');
    report.writeln('     attendu: nom~$nomAttendu cp=$cpAttendu');
    report.writeln('     obtenu : nom=${r.nomDestinataire}');
    report.writeln('              cp=${r.codePostal} ville=${r.ville}');
    report.writeln('              rue=${r.rue}');
    report.writeln('              confidence=${r.confidence.name}');
  }
  final ratio = high / fixtures.length;
  report.writeln('=== Total : $high/${fixtures.length} '
      '(${(ratio * 100).toStringAsFixed(1)} %) ===');
  print(report);

  if (ratio < 0.90) {
    print('FAIL : cible 90 % non atteinte.');
    exit(1);
  }
}

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
