import 'package:drift/drift.dart';

import 'entreprises.dart';
import 'entrepots.dart';

/// Invitations en attente : un chef envoie un mail à un futur employé
/// pour le faire rejoindre une entreprise/entrepôt.
///
/// Carte #362. Décision questionnaire #361 Q8 : provider mail =
/// Supabase SMTP intégré (magic link via `auth.admin.inviteUserByEmail`).
///
/// Cycle de vie :
///   pending → accepted (user clique le magic link et accepte)
///           → expired (TTL 7 jours dépassé)
///           → revoked (chef annule l'invitation avant acceptation)
class EntrepriseInvitations extends Table {
  TextColumn get cloudId => text()();

  TextColumn get entrepriseId =>
      text().references(Entreprises, #cloudId, onDelete: KeyAction.cascade)();

  /// Optionnel : si l'invitation cible un entrepôt précis. NULL =
  /// invitation au niveau entreprise (l'admin pourra rattacher
  /// l'employé à des entrepôts après acceptation).
  TextColumn get entrepotId =>
      text().references(Entrepots, #cloudId, onDelete: KeyAction.setNull).nullable()();

  TextColumn get email => text()();

  /// 'admin_entreprise' | 'chef_entrepot' | 'employe'
  TextColumn get roleTarget => text()();

  /// UUID Supabase auth.users de l'inviteur
  TextColumn get invitedBy => text()();

  /// 'pending' | 'accepted' | 'expired' | 'revoked'
  TextColumn get statut => text().withDefault(const Constant('pending'))();

  /// TTL 7 jours par défaut (cf #363 Edge Function `invite_employee`).
  DateTimeColumn get expiresAt => dateTime()();

  DateTimeColumn get creeLe => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {cloudId};
}
