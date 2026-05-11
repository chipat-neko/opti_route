import '../parametres_repository.dart';
import 'assistant_suggestion.dart';

/// Calibration progressive du TourAssistant. Mémorise les
/// acceptations / refus de l'utilisateur et ajuste les seuils
/// numériques (typiquement le rayon de proximité) après un nombre
/// configurable d'événements.
///
/// Approche conservatrice :
/// - Compte accept / reject pour chaque `SuggestionKind`.
/// - Tous les `_adjustEveryN` événements, recalcule le taux
///   d'acceptation et ajuste le seuil :
///   - >= 70 % accept → augmente le seuil (l'utilisateur veut plus
///     de suggestions).
///   - <= 30 % accept → réduit le seuil (l'utilisateur trouve qu'on
///     l'embête).
///   - Entre les 2 → pas d'ajustement.
/// - Bornes dures : entre `_minProximityM` et `_maxProximityM`.
/// - Step d'ajustement : +/- 50 m.
/// - Après ajustement, les compteurs sont reset pour repartir sur le
///   nouveau seuil.
class AssistantCalibration {
  AssistantCalibration(this._params);

  final ParametresRepository _params;

  static const int _adjustEveryN = 10;
  static const int _minProximityM = 100;
  static const int _maxProximityM = 800;
  static const int _stepM = 50;

  /// Enregistre une acceptation. Si on atteint `_adjustEveryN`
  /// événements (accept + reject confondus), déclenche l'ajustement.
  Future<void> recordAccept(SuggestionKind kind) async {
    await _params.assistantIncrement(kind, accept: true);
    await _maybeAdjust(kind);
  }

  Future<void> recordRefuse(SuggestionKind kind) async {
    await _params.assistantIncrement(kind, accept: false);
    await _maybeAdjust(kind);
  }

  Future<void> _maybeAdjust(SuggestionKind kind) async {
    if (kind != SuggestionKind.proximity) {
      // Pour l'instant on ne calibre que le seuil proximity. Les
      // autres regles ont des seuils non numeriques (booleens).
      return;
    }
    final accepts = await _params.assistantAcceptCount(kind);
    final refuses = await _params.assistantRefuseCount(kind);
    final total = accepts + refuses;
    if (total < _adjustEveryN) return;

    final acceptRate = accepts / total;
    final current = await _params.assistantProximityThresholdM();
    int next = current;
    if (acceptRate >= 0.7) {
      next = (current + _stepM).clamp(_minProximityM, _maxProximityM);
    } else if (acceptRate <= 0.3) {
      next = (current - _stepM).clamp(_minProximityM, _maxProximityM);
    }
    // Reset des compteurs pour le prochain cycle, qu'on ait ajuste
    // ou pas (on repart sur 10 nouveaux events).
    await _params.assistantResetCounters(kind);
    if (next != current) {
      await _params.setAssistantProximityThresholdM(next);
    }
  }
}
