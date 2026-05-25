import 'package:drift/drift.dart';

import 'stops.dart';

/// Codes courts (4 chars [a-z0-9]) attribues a un stop pour generer
/// un lien tracking lisible par le client final (ex Amazon Auneau).
///
/// Format URL finale : `https://<domaine>/<code>` ou `<domaine>` est
/// court (ex `fa28.ro` 7 chars, `optr.ro` 7 chars). Avec un code de
/// 4 chars on tape exactement 20 caracteres (contrainte stricte du
/// logiciel client). Voir constante `kTrackingDomain` dans
/// `app_constants.dart`.
///
/// Source des donnees pour la page :
/// - Statut livre/echec lu depuis [Stops]
/// - Preuve photo lue depuis [Stops.preuvePhotoPath] -> uploadee en
///   Supabase Storage avec URL signee (24h validity)
///
/// Le lien n'est genere que sur demande explicite (bouton "Generer
/// lien tracking" dans la bottom sheet d'un stop). Carte Trello #141.
class TrackingCodes extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// FK vers le stop concerne. Un stop = max 1 code (unique index).
  IntColumn get stopId =>
      integer().customConstraint('NOT NULL REFERENCES stops(id) ON DELETE CASCADE')();

  /// Code court 4 caracteres [a-z0-9] (1.6M combinations). Unique
  /// au niveau de la base : pas 2 stops avec le meme code.
  TextColumn get code => text().withLength(min: 3, max: 5).unique()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// True une fois que la row a ete push au cloud Supabase (table
  /// `tracking_links`). Null/false en attendant le deploiement de
  /// l'Edge Function backend (MVP scaffold pour l'instant).
  BoolColumn get cloudPushed =>
      boolean().withDefault(const Constant(false))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {stopId},
      ];
}
