import 'dart:async';

import 'package:flutter/foundation.dart';

import 'database.dart';
import 'notifications_service.dart';
import 'recurrences_repository.dart';
import 'tournees_repository.dart';

/// Frequences supportees par une recurrence de tournee (carte #113).
class RecurrenceFrequence {
  RecurrenceFrequence._();

  static const quotidien = 'quotidien';
  static const joursOuvres = 'jours_ouvres';
  static const hebdo = 'hebdo';
  static const mensuel = 'mensuel';

  static const all = [quotidien, joursOuvres, hebdo, mensuel];
}

/// Genere automatiquement les tournees recurrentes (carte #113).
///
/// Choix d'archi : PAS de WorkManager (daemon natif lourd, batterivore,
/// non testable). A la place, [runDue] est appele a l'ouverture de l'app
/// (depuis main.dart, comme [AutoBackupService.maybeRunAutoBackup]) : si
/// une recurrence active cible aujourd'hui et n'a pas encore genere ce
/// jour, on clone le template. Tradeoff : la tournee est creee a la 1ere
/// ouverture du jour plutot qu'a 6h pile -- suffisant pour le besoin
/// "elle est prete quand je commence ma journee".
class RecurrenceService {
  RecurrenceService(this._recurrences, this._tournees, this._notifications);

  final RecurrencesRepository _recurrences;
  final TourneesRepository _tournees;
  final NotificationsService _notifications;

  /// Logique PURE : faut-il generer une tournee pour cette recurrence a
  /// la date [date] ? Deterministe (aucune I/O), testable.
  ///
  /// - inactif -> false
  /// - deja genere le meme jour calendaire que [date] -> false (dedup)
  /// - sinon, match selon la frequence (jour de semaine / du mois)
  static bool shouldGenerateOn({
    required String frequence,
    required bool actif,
    int? jourSemaine,
    int? jourMois,
    DateTime? derniereGeneration,
    required DateTime date,
  }) {
    if (!actif) return false;
    if (derniereGeneration != null && _sameDay(derniereGeneration, date)) {
      return false;
    }
    switch (frequence) {
      case RecurrenceFrequence.quotidien:
        return true;
      case RecurrenceFrequence.joursOuvres:
        return date.weekday >= DateTime.monday &&
            date.weekday <= DateTime.friday;
      case RecurrenceFrequence.hebdo:
        return jourSemaine != null && date.weekday == jourSemaine;
      case RecurrenceFrequence.mensuel:
        return jourMois != null && date.day == jourMois;
      default:
        return false;
    }
  }

  /// Variante prenant une row [TourneeRecurrence].
  static bool shouldGenerate(TourneeRecurrence rec, DateTime date) {
    return shouldGenerateOn(
      frequence: rec.frequence,
      actif: rec.actif,
      jourSemaine: rec.jourSemaine,
      jourMois: rec.jourMois,
      derniereGeneration: rec.derniereGenerationLe,
      date: date,
    );
  }

  /// Evalue toutes les recurrences actives et genere les tournees dues
  /// pour [now] (defaut : maintenant). Pour chaque generation : clone le
  /// template, marque la recurrence generee (dedup), pousse une notif.
  /// Best-effort : une erreur sur une recurrence n'interrompt pas les
  /// autres. Retourne le nombre de tournees generees.
  Future<int> runDue({DateTime? now}) async {
    final today = now ?? DateTime.now();
    final actives = await _recurrences.getActives();
    var generated = 0;
    for (final rec in actives) {
      if (!shouldGenerate(rec, today)) continue;
      try {
        final newId =
            await _tournees.duplicate(rec.templateId, targetDate: today);
        await _recurrences.markGenerated(rec.id, today);
        final nouvelle = await _tournees.getById(newId);
        if (nouvelle != null) {
          // Notif best-effort : on avale toute erreur (ex: plugin notif
          // indisponible) pour ne pas casser la generation ni polluer
          // le zone async (utile aussi en tests sans plateforme).
          unawaited(
            _notifications
                .showTourneeRecurrenteCreee(
                  tourneeId: newId,
                  nomTournee: nouvelle.nom,
                )
                .catchError((Object _) {}),
          );
        }
        generated++;
      } catch (e) {
        debugPrint('[RecurrenceService] generation echouee '
            'template=${rec.templateId}: $e');
      }
    }
    return generated;
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
