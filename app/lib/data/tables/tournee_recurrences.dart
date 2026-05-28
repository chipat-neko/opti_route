import 'package:drift/drift.dart';

import 'tournees.dart';

/// Recurrence automatique attachee a un template de tournee (carte #114
/// templates -> carte #113). Quand actif, l'app genere automatiquement
/// une tournee depuis le template au jour cible (evalue a l'ouverture de
/// l'app, cf [RecurrenceService.runDue]).
///
/// Une ligne par template (au plus). `frequence` decrit le calendrier :
/// - 'quotidien'    : tous les jours
/// - 'jours_ouvres' : du lundi au vendredi
/// - 'hebdo'        : chaque [jourSemaine] (1=lundi .. 7=dimanche)
/// - 'mensuel'      : chaque [jourMois] (1..31) du mois
class TourneeRecurrences extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Le template source a cloner (FK Tournees.id, normalement isTemplate).
  IntColumn get templateId =>
      integer().references(Tournees, #id, onDelete: KeyAction.cascade)();

  TextColumn get frequence => text()();

  /// 1=lundi .. 7=dimanche. Requis si frequence == 'hebdo'.
  IntColumn get jourSemaine => integer().nullable()();

  /// 1..31. Requis si frequence == 'mensuel'. Si > nb de jours du mois,
  /// la recurrence ne se declenche pas ce mois-la (cas rare, ex 31 fev).
  IntColumn get jourMois => integer().nullable()();

  BoolColumn get actif => boolean().withDefault(const Constant(true))();

  /// Jour de la derniere generation reussie. Sert au dedup intra-jour :
  /// on ne genere pas deux fois la meme tournee le meme jour (si l'app
  /// est rouverte plusieurs fois). Null = jamais genere.
  DateTimeColumn get derniereGenerationLe => dateTime().nullable()();

  DateTimeColumn get creeLe => dateTime().withDefault(currentDateAndTime)();
}
