import 'package:drift/drift.dart';

/// Notes perso d'un employé sur un client partagé.
///
/// Carte #362. Décision questionnaire #361 Q7 : 2 zones de notes
/// (partagées au niveau carnet + perso par employé).
///
/// **Exemple concret** :
/// - Le carnet entrepôt a "Mme Dupont, 12 rue de la Paix" avec note
///   partagée "Code interphone : 1234B" (visible par tous les employés
///   de l'entrepôt)
/// - Marc (employé) ajoute SA note perso : "Sent l'alcool le matin,
///   pas commode" → visible UNIQUEMENT par Marc.
///
/// RLS Supabase strict : `SELECT/UPDATE/DELETE` uniquement si
/// `user_id = auth.uid()`. Les autres employés du même entrepôt ne
/// voient JAMAIS les notes perso de Marc.
class SavedDestinationNotesPerso extends Table {
  TextColumn get cloudId => text()();

  /// Référence le cloud_id de la `saved_destinations` partagée.
  /// On ne met PAS de FK Drift ici parce que cette table peut référer
  /// un savedDestinations qui n'existe pas encore localement (pull
  /// décalé). Le sync cloud rétablit l'intégrité.
  TextColumn get savedDestinationId => text()();

  /// UUID Supabase auth.users du propriétaire de la note.
  TextColumn get userId => text()();

  TextColumn get notes => text().nullable()();

  DateTimeColumn get creeLe => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {cloudId};
}
