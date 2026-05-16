import 'package:drift/drift.dart';

/// Membres d'une tournée partagée (jalon 3.A — mode équipe live).
///
/// Cache local de la table `tournee_membres` cloud. Sert à savoir :
/// - À quelle tournée un user a accès (au-delà des tournées qu'il
///   possède en propre)
/// - Qui sont les coéquipiers d'une tournée partagée (pour afficher
///   "Partagée avec Lucas, Mathieu" dans la liste)
/// - Si on est owner ou simple member (UI conditionnelle : seul l'owner
///   voit le bouton "Inviter coéquipier" et "Éjecter ce coéquipier")
///
/// Pas de cloudId TEXT séparé : la PK logique est (tourneeCloudId,
/// userCloudId), tous les deux des UUID. On stocke directement ces 2
/// strings et le local id auto-increment sert juste à Drift.
///
/// Pas de updatedAt non plus : les rows sont append-only (on ne modifie
/// jamais le role après coup, et joined_at est figé). Les seuls events
/// possibles sont INSERT (rejoindre) et DELETE (quitter / éjecter), que
/// le pull cloud → local reflète intégralement.
class TourneeMembres extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// UUID cloud de la tournée (= `tournees.cloud_id` de la table Tournees).
  /// Ne pas confondre avec le `tourneeId` int local (PK Drift). On stocke
  /// directement l'UUID pour décorréler du local id (un membre peut
  /// exister dans le cache avant que la tournée elle-même soit pull).
  TextColumn get tourneeCloudId => text()();

  /// UUID Supabase du user (= `auth.users.id`). Sert à matcher avec
  /// le current user au cold start ("est-ce que JE suis membre de cette
  /// tournée ?").
  TextColumn get userCloudId => text()();

  /// `owner` ou `member`. CHECK constraint au niveau DB (cf migration).
  TextColumn get role => text()();

  DateTimeColumn get joinedAt => dateTime().withDefault(currentDateAndTime)();
}
