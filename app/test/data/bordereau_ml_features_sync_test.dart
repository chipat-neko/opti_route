import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/bordereau_ml/features.dart';

/// Garde-fou anti-divergence ML (audit 2026-06-11).
///
/// Le Random Forest a ete entraine avec les mots-cles / regex de
/// `tools/train_classifier.py`, exportes dans `assets/ml/features.json`.
/// L'inference Dart (`features.dart`) DOIT reproduire exactement ces
/// valeurs, sinon les features calculees a l'inference different de
/// celles vues a l'entrainement et l'accuracy chute silencieusement
/// (c'etait le cas : kRueKw et kParasiteKw avaient derive).
///
/// Ce test lit le features.json (source de verite, regenere a chaque
/// training) et le compare aux constantes Dart. Apres un re-training qui
/// change les mots-cles, ce test echoue tant que features.dart n'est pas
/// realigne — c'est voulu.
void main() {
  late Map<String, dynamic> spec;

  setUpAll(() {
    final raw = File('assets/ml/features.json').readAsStringSync();
    spec = json.decode(raw) as Map<String, dynamic>;
  });

  List<String> specList(String key) => (spec[key] as List).cast<String>();

  test('kTelKw == features.json tel_kw', () {
    expect(kTelKw, specList('tel_kw'));
  });

  test('kRueKw == features.json rue_kw', () {
    expect(kRueKw, specList('rue_kw'));
  });

  test('kRefKw == features.json ref_kw', () {
    expect(kRefKw, specList('ref_kw'));
  });

  test('kParasiteKw == features.json parasite_kw', () {
    expect(kParasiteKw, specList('parasite_kw'));
  });

  test('kPunctChars == features.json punct_chars (comparaison en set)', () {
    // Python exporte ''.join(sorted(PUNCT)) : l'ordre differe, seul
    // l'ensemble des caracteres compte (usage : `contains`).
    final dartSet = kPunctChars.split('').toSet();
    final pySet = (spec['punct_chars'] as String).split('').toSet();
    expect(dartSet, pySet);
  });

  test('kCpPattern == features.json cp_pattern', () {
    expect(kCpPattern.pattern, spec['cp_pattern']);
  });

  test('kPhonePattern == features.json phone_pattern', () {
    expect(kPhonePattern.pattern, spec['phone_pattern']);
  });

  test('computeFeatures produit bien les 20 features attendues', () {
    final names = specList('feature_names');
    final feats = computeFeatures(
      text: 'TEL 02 37 26 75 02',
      relY: 0.5,
      relX: 0.1,
      blockHeight: 40,
      blockWidth: 200,
    );
    expect(feats.length, names.length,
        reason: 'le vecteur Dart doit avoir autant de features que '
            'feature_names du JSON');
  });

  test('n_words reproduit le split() Python (espaces de bord ignores)', () {
    // "  GARAGE DUPONT " -> 2 mots cote Python, pas 3.
    final feats = computeFeatures(
      text: '  GARAGE DUPONT ',
      relY: 0,
      relX: 0,
      blockHeight: 1,
      blockWidth: 1,
    );
    expect(feats[1], 2.0);
  });
}
