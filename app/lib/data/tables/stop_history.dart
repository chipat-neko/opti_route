import 'package:drift/drift.dart';

import 'stops.dart';

/// Journal des changements de statut d'un arret. Sert a tracer "qui
/// a fait quoi et quand" en cas de litige client ou pour debugger
/// pourquoi un arret est marque comme echec.
///
/// On log uniquement les transitions de statutLivraison (a_livrer ->
/// livre / echec / inverse). Pas les modifications de notes / nb colis
/// qui sont moins critiques et alourdiraient la table.
///
/// Cascade : si la tournee/stop est supprimee, l'historique aussi.
class StopHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get stopId =>
      integer().references(Stops, #id, onDelete: KeyAction.cascade)();

  /// Action effectuee. Valeurs : 'mark_livre' / 'mark_echec' /
  /// 'mark_a_livrer'.
  TextColumn get action => text()();

  /// Statut precedent ('a_livrer' / 'livre' / 'echec').
  TextColumn get fromStatus => text()();

  /// Statut apres l'action.
  TextColumn get toStatus => text()();

  /// Raison d'echec saisie pour 'mark_echec'. Null sinon.
  TextColumn get raison => text().nullable()();

  DateTimeColumn get timestamp =>
      dateTime().withDefault(currentDateAndTime)();
}
