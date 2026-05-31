import 'package:drift/drift.dart';

import 'entrepots.dart';

/// Membres d'un entrepôt (relation user × entrepôt).
///
/// Carte #362. Décisions questionnaire #361 :
/// - Q2 : un user peut être rattaché à plusieurs entrepôts
///   (multi-sites, intérim, polyvalent) → table M:N
/// - Q4 : roles `'chef_entrepot'` (peut inviter, voir tout l'entrepôt)
///   vs `'employe'` (voit le carnet en lecture, gère ses notes perso)
/// - Q5 : départ progressif J+30 (même mécanique que entreprise_users)
class EntrepotUsers extends Table {
  TextColumn get cloudId => text()();

  TextColumn get entrepotId =>
      text().references(Entrepots, #cloudId, onDelete: KeyAction.cascade)();

  /// UUID Supabase auth.users
  TextColumn get userId => text()();

  /// 'chef_entrepot' | 'employe'
  TextColumn get role => text()();

  /// 'actif' | 'revoque' | 'expire'
  TextColumn get statut => text().withDefault(const Constant('actif'))();

  DateTimeColumn get revokedAt => dateTime().nullable()();

  DateTimeColumn get creeLe => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {cloudId};
}
