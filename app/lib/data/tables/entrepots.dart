import 'package:drift/drift.dart';

import 'entreprises.dart';

/// Mirroir local de la table cloud `entrepots`.
///
/// Un entrepôt = un site/agence rattaché à une entreprise (ex : Paris,
/// Lyon, Marseille pour une entreprise multi-sites). Une entreprise
/// peut avoir N entrepôts (illimité, cf décision questionnaire #361
/// Q1).
///
/// Carte Trello #362.
class Entrepots extends Table {
  TextColumn get cloudId => text()();

  /// FK vers `entreprises.cloudId`.
  TextColumn get entrepriseId =>
      text().references(Entreprises, #cloudId, onDelete: KeyAction.cascade)();

  TextColumn get nom => text()();

  /// Adresse postale du site (texte libre, géocodée optionnellement).
  TextColumn get adresse => text().nullable()();

  RealColumn get lat => real().nullable()();
  RealColumn get lng => real().nullable()();

  DateTimeColumn get creeLe => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {cloudId};
}
