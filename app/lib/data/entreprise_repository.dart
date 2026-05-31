import 'package:drift/drift.dart';

import 'database.dart';

/// CRUD basique pour les 6 nouvelles tables multi-tenant (carte #362).
///
/// La source de verite reste Supabase ; ces repositories servent au
/// mirroir local Drift et a la lecture offline. Le sync cloud
/// (push/pull) sera ajoute dans une PR ulterieure (carte #363).
///
/// Pour rester compact, les 6 entites sont regroupees dans un seul
/// repository facade. Si le besoin grandit (filtres complexes,
/// agregations), on les separera.
class EntrepriseRepository {
  EntrepriseRepository(this._db);

  final AppDatabase _db;

  // ═══════════════════════════════════════════════════════════════
  // Entreprises
  // ═══════════════════════════════════════════════════════════════

  Future<Entreprise?> getEntrepriseById(String cloudId) {
    return (_db.select(_db.entreprises)
          ..where((e) => e.cloudId.equals(cloudId)))
        .getSingleOrNull();
  }

  Stream<List<Entreprise>> watchAllEntreprises() {
    return _db.select(_db.entreprises).watch();
  }

  Future<void> upsertEntreprise(Entreprise e) {
    return _db.into(_db.entreprises).insertOnConflictUpdate(e);
  }

  Future<int> deleteEntreprise(String cloudId) {
    return (_db.delete(_db.entreprises)..where((e) => e.cloudId.equals(cloudId)))
        .go();
  }

  // ═══════════════════════════════════════════════════════════════
  // Entrepots
  // ═══════════════════════════════════════════════════════════════

  Future<Entrepot?> getEntrepotById(String cloudId) {
    return (_db.select(_db.entrepots)..where((e) => e.cloudId.equals(cloudId)))
        .getSingleOrNull();
  }

  Stream<List<Entrepot>> watchEntrepotsForEntreprise(String entrepriseId) {
    return (_db.select(_db.entrepots)
          ..where((e) => e.entrepriseId.equals(entrepriseId)))
        .watch();
  }

  Stream<List<Entrepot>> watchAllEntrepots() => _db.select(_db.entrepots).watch();

  Future<void> upsertEntrepot(Entrepot e) {
    return _db.into(_db.entrepots).insertOnConflictUpdate(e);
  }

  Future<int> deleteEntrepot(String cloudId) {
    return (_db.delete(_db.entrepots)..where((e) => e.cloudId.equals(cloudId)))
        .go();
  }

  // ═══════════════════════════════════════════════════════════════
  // EntrepriseUsers (membership entreprise)
  // ═══════════════════════════════════════════════════════════════

  /// Toutes les entreprises auxquelles ce user appartient avec un
  /// statut actif. Le sync filtrera aussi `revoked_at` cote cloud.
  Stream<List<EntrepriseUser>> watchEntreprisesForUser(String userId) {
    return (_db.select(_db.entrepriseUsers)
          ..where((u) => u.userId.equals(userId) & u.statut.equals('actif')))
        .watch();
  }

  Stream<List<EntrepriseUser>> watchMembersOfEntreprise(String entrepriseId) {
    return (_db.select(_db.entrepriseUsers)
          ..where((u) => u.entrepriseId.equals(entrepriseId)))
        .watch();
  }

  Future<void> upsertEntrepriseUser(EntrepriseUser u) {
    return _db.into(_db.entrepriseUsers).insertOnConflictUpdate(u);
  }

  Future<int> deleteEntrepriseUser(String cloudId) {
    return (_db.delete(_db.entrepriseUsers)
          ..where((u) => u.cloudId.equals(cloudId)))
        .go();
  }

  // ═══════════════════════════════════════════════════════════════
  // EntrepotUsers (membership entrepot)
  // ═══════════════════════════════════════════════════════════════

  Stream<List<EntrepotUser>> watchEntrepotsForUser(String userId) {
    return (_db.select(_db.entrepotUsers)
          ..where((u) => u.userId.equals(userId) & u.statut.equals('actif')))
        .watch();
  }

  Stream<List<EntrepotUser>> watchMembersOfEntrepot(String entrepotId) {
    return (_db.select(_db.entrepotUsers)
          ..where((u) => u.entrepotId.equals(entrepotId)))
        .watch();
  }

  Future<void> upsertEntrepotUser(EntrepotUser u) {
    return _db.into(_db.entrepotUsers).insertOnConflictUpdate(u);
  }

  Future<int> deleteEntrepotUser(String cloudId) {
    return (_db.delete(_db.entrepotUsers)
          ..where((u) => u.cloudId.equals(cloudId)))
        .go();
  }

  // ═══════════════════════════════════════════════════════════════
  // EntrepriseInvitations
  // ═══════════════════════════════════════════════════════════════

  Stream<List<EntrepriseInvitation>> watchPendingInvitations(
      String entrepriseId) {
    return (_db.select(_db.entrepriseInvitations)
          ..where((i) =>
              i.entrepriseId.equals(entrepriseId) & i.statut.equals('pending')))
        .watch();
  }

  Future<void> upsertInvitation(EntrepriseInvitation i) {
    return _db.into(_db.entrepriseInvitations).insertOnConflictUpdate(i);
  }

  Future<int> deleteInvitation(String cloudId) {
    return (_db.delete(_db.entrepriseInvitations)
          ..where((i) => i.cloudId.equals(cloudId)))
        .go();
  }

  // ═══════════════════════════════════════════════════════════════
  // SavedDestinationNotesPerso
  // ═══════════════════════════════════════════════════════════════

  /// Note perso d'un user sur un client donne. Retourne null si pas
  /// de note pour ce user × cette destination.
  Future<SavedDestinationNotesPersoData?> getNotePerso({
    required String savedDestinationId,
    required String userId,
  }) {
    return (_db.select(_db.savedDestinationNotesPerso)
          ..where((n) =>
              n.savedDestinationId.equals(savedDestinationId) &
              n.userId.equals(userId)))
        .getSingleOrNull();
  }

  /// Watch reactif : utile pour la UI fiche client qui se rafraichit
  /// quand l'user edite ses notes perso.
  Stream<SavedDestinationNotesPersoData?> watchNotePerso({
    required String savedDestinationId,
    required String userId,
  }) {
    return (_db.select(_db.savedDestinationNotesPerso)
          ..where((n) =>
              n.savedDestinationId.equals(savedDestinationId) &
              n.userId.equals(userId)))
        .watchSingleOrNull();
  }

  Future<void> upsertNotePerso(SavedDestinationNotesPersoData n) {
    return _db.into(_db.savedDestinationNotesPerso).insertOnConflictUpdate(n);
  }

  Future<int> deleteNotePerso(String cloudId) {
    return (_db.delete(_db.savedDestinationNotesPerso)
          ..where((n) => n.cloudId.equals(cloudId)))
        .go();
  }
}
