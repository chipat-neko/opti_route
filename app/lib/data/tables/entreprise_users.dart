import 'package:drift/drift.dart';

import 'entreprises.dart';

/// Membres d'une entreprise (relation user × entreprise au niveau global).
///
/// Carte #362. Décisions questionnaire #361 :
/// - Q4 : un user peut être `admin_entreprise` (créateur, modifie
///   profil, supprime entrepôts) ou `membre` (rattaché à des entrepôts
///   via `entrepot_users`)
/// - Q5 : départ progressif J+30 → `revoked_at` non-null + statut
///   = `'revoque'`, devient `'expire'` après J+30 (cron Supabase)
///
/// Pas de FK locale vers auth.users (pas de table locale qui mirroir
/// les users Supabase) : on stocke juste l'UUID.
class EntrepriseUsers extends Table {
  TextColumn get cloudId => text()();

  TextColumn get entrepriseId =>
      text().references(Entreprises, #cloudId, onDelete: KeyAction.cascade)();

  /// UUID Supabase auth.users
  TextColumn get userId => text()();

  /// 'admin_entreprise' | 'membre'
  TextColumn get role => text()();

  /// 'actif' | 'revoque' | 'expire'
  TextColumn get statut => text().withDefault(const Constant('actif'))();

  /// Quand revoked_at est set : compte à rebours J+30 avant `expire`.
  /// Null si statut='actif' ou 'expire'.
  DateTimeColumn get revokedAt => dateTime().nullable()();

  DateTimeColumn get creeLe => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {cloudId};
}
