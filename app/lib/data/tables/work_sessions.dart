import 'package:drift/drift.dart';

/// Sessions de travail (carte #279) : un pointage debut/fin de service.
/// Une session ouverte = `endedAt` null, en cours. Au plus une seule
/// session ouverte a la fois (geree cote repository).
///
/// Sert au cumul des heures travaillees par jour/semaine et au calcul
/// du ratio "colis livres / heure" cote stats. Pas de pause auto GPS
/// pour le MVP -- le pointage est manuel (bouton dans Parametres).
class WorkSessions extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Timestamp de debut de service (tap "Commencer le service").
  DateTimeColumn get startedAt => dateTime()();

  /// Timestamp de fin de service (tap "Terminer le service"). Null
  /// si la session est encore en cours.
  DateTimeColumn get endedAt => dateTime().nullable()();

  /// Notes libres optionnelles (ex: "tournee Chartres + retour 18h").
  /// Pas utilisees aujourd'hui mais reservees pour une future UI.
  TextColumn get notes => text().nullable()();

  DateTimeColumn get creeLe => dateTime().withDefault(currentDateAndTime)();
}
