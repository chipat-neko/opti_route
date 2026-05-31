import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;

import 'features.dart';

/// Resultat d'une classification : la classe predite (NOM_CLIENT, RUE,
/// CP_VILLE, TEL, REF, PARASITE) et la confiance dans [0, 1].
class BordereauClass {
  const BordereauClass(this.label, this.confidence);
  final String label;
  final double confidence;

  /// True si on est sous le seuil de confiance et qu'on doit basculer
  /// l'OCR en "carte orange" (validation manuelle requise).
  bool get isLowConfidence => confidence < 0.70;

  @override
  String toString() =>
      '$label (${(confidence * 100).toStringAsFixed(0)}%)';
}

/// Classifier ML pour les lignes OCR de bordereaux.
///
/// Charge le `bordereau_classifier.json` exporte par
/// `tools/export_forest_json.py` (RandomForest sklearn re-serialise en
/// JSON compact). Inferenceur en pur Dart : pas de dep ONNX runtime.
///
/// Singleton paresseux : appelez `instance.load()` une fois au boot, puis
/// `instance.classify(...)` autant de fois que voulu.
///
/// Sortie audit OCR (#337) : avant, les lignes etaient classees par
/// heuristiques fragiles (regexes + listes de mots-cles). Maintenant un
/// vrai modele entraine sur 68 bordereaux Gemini-labellises (3451
/// lignes), accuracy_test = 0.932.
class BordereauMlClassifier {
  BordereauMlClassifier._();
  static final instance = BordereauMlClassifier._();

  bool _loaded = false;
  List<String> _classes = const [];
  List<_Tree> _trees = const [];
  int _nFeatures = 0;
  double _trainAccuracy = 0;

  /// True quand le JSON a ete charge et que le modele est utilisable.
  bool get isLoaded => _loaded;

  /// Accuracy du modele sur le test set (rapport au moment du training).
  /// Sert juste a remonter une info de debug.
  double get trainAccuracy => _trainAccuracy;

  /// Charge le modele depuis assets/ml/bordereau_classifier.json.
  /// A appeler une fois au boot (`unawaited(BordereauMlClassifier.instance.load())`).
  /// Idempotent : appels suivants no-op.
  Future<void> load() async {
    if (_loaded) return;
    try {
      final raw = await rootBundle
          .loadString('assets/ml/bordereau_classifier.json');
      final data = json.decode(raw) as Map<String, dynamic>;
      _classes = (data['classes'] as List).cast<String>();
      _nFeatures = data['n_features'] as int;
      _trainAccuracy = (data['accuracy_test'] as num).toDouble();
      final treesRaw = data['trees'] as List;
      _trees = treesRaw.map((t) {
        final m = t as Map<String, dynamic>;
        return _Tree(
          feature: (m['feature'] as List).cast<int>(),
          threshold: (m['threshold'] as List).map((e) => (e as num).toDouble()).toList(),
          left: (m['left'] as List).cast<int>(),
          right: (m['right'] as List).cast<int>(),
          value: (m['value'] as List)
              .map((row) => (row as List).map((e) => (e as num).toDouble()).toList())
              .toList(),
        );
      }).toList(growable: false);
      _loaded = true;
      debugPrint(
          '[BordereauML] loaded ${_trees.length} trees, '
          'classes=$_classes, train_acc=${_trainAccuracy.toStringAsFixed(3)}');
    } catch (e) {
      debugPrint('[BordereauML] load failed: $e -- classifier indispo');
      _loaded = false;
    }
  }

  /// Classifie une ligne OCR. Retourne null si le modele n'est pas
  /// charge (caller doit fallback sur ses heuristiques precedentes).
  ///
  /// [text] : contenu OCR de la ligne
  /// [relY] / [relX] : position relative dans [0, 1] dans le bordereau
  /// [blockHeight] / [blockWidth] : taille du block en pixels bruts
  BordereauClass? classify({
    required String text,
    required double relY,
    required double relX,
    required double blockHeight,
    required double blockWidth,
  }) {
    if (!_loaded) return null;
    final feats = computeFeatures(
      text: text,
      relY: relY,
      relX: relX,
      blockHeight: blockHeight,
      blockWidth: blockWidth,
    );
    if (feats.length != _nFeatures) {
      debugPrint(
          '[BordereauML] feature count mismatch: ${feats.length} vs $_nFeatures');
      return null;
    }
    // Pour chaque arbre, traverse jusqu'a une leaf et accumule le vote
    // pondere (= value[leafIdx] qui est un vecteur de class_counts).
    final votes = List<double>.filled(_classes.length, 0);
    for (final tree in _trees) {
      var node = 0;
      // Garde-fou : profondeur max 256 pour eviter une boucle infinie en
      // cas de JSON corrompu.
      for (var depth = 0; depth < 256; depth++) {
        final f = tree.feature[node];
        if (f == -1) break; // leaf
        final th = tree.threshold[node];
        node = feats[f] <= th ? tree.left[node] : tree.right[node];
      }
      final value = tree.value[node];
      for (var i = 0; i < votes.length; i++) {
        votes[i] += value[i];
      }
    }
    // Argmax + confiance = vote_max / vote_total
    var maxIdx = 0;
    var maxVote = votes[0];
    var total = votes[0];
    for (var i = 1; i < votes.length; i++) {
      total += votes[i];
      if (votes[i] > maxVote) {
        maxVote = votes[i];
        maxIdx = i;
      }
    }
    final conf = total > 0 ? maxVote / total : 0.0;
    return BordereauClass(_classes[maxIdx], conf);
  }
}

class _Tree {
  _Tree({
    required this.feature,
    required this.threshold,
    required this.left,
    required this.right,
    required this.value,
  });
  final List<int> feature;
  final List<double> threshold;
  final List<int> left;
  final List<int> right;
  final List<List<double>> value;
}
