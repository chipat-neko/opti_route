import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/entreprise_repository.dart';

/// Couverture des méthodes du repo multi-tenant pas encore testées
/// (membres entreprise/entrepôt, invitations pending, notes perso local).
/// Complète entreprise_repository_test.dart (tests de couverture #361).
void main() {
  late AppDatabase db;
  late EntrepriseRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = EntrepriseRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  DateTime now() => DateTime.now();

  /// Crée une entreprise + entrepôt parents (FK requises).
  Future<void> seedParents({
    String entrepriseId = 'ent-1',
    String entrepotId = 'epot-1',
    String userId = 'user-1',
  }) async {
    await repo.upsertEntreprise(Entreprise(
      cloudId: entrepriseId, nom: 'CALOTE', siret: null, createdBy: userId,
      creeLe: now(), updatedAt: now(),
    ));
    await repo.upsertEntrepot(Entrepot(
      cloudId: entrepotId, entrepriseId: entrepriseId, nom: 'Dépôt',
      adresse: null, lat: null, lng: null, creeLe: now(), updatedAt: now(),
    ));
  }

  group('Membres entreprise (#366)', () {
    test('watchMembersOfEntreprise retourne tous les membres (tous statuts)',
        () async {
      await seedParents();
      await repo.upsertEntrepriseUser(EntrepriseUser(
        cloudId: 'eu-a', entrepriseId: 'ent-1', userId: 'user-1',
        role: 'admin_entreprise', statut: 'actif', revokedAt: null,
        creeLe: now(), updatedAt: now(),
      ));
      await repo.upsertEntrepriseUser(EntrepriseUser(
        cloudId: 'eu-b', entrepriseId: 'ent-1', userId: 'user-2',
        role: 'membre', statut: 'revoque',
        revokedAt: now(), creeLe: now(), updatedAt: now(),
      ));
      final membres = await repo.watchMembersOfEntreprise('ent-1').first;
      // watchMembers ne filtre PAS sur le statut (vue gestion = tout voir).
      expect(membres, hasLength(2));
    });

    test('watchEntreprisesForUser ne renvoie que les actifs', () async {
      await seedParents(entrepriseId: 'ent-1');
      await repo.upsertEntreprise(Entreprise(
        cloudId: 'ent-2', nom: 'B', siret: null, createdBy: 'user-1',
        creeLe: now(), updatedAt: now(),
      ));
      await repo.upsertEntrepriseUser(EntrepriseUser(
        cloudId: 'eu-1', entrepriseId: 'ent-1', userId: 'user-1',
        role: 'admin_entreprise', statut: 'actif', revokedAt: null,
        creeLe: now(), updatedAt: now(),
      ));
      await repo.upsertEntrepriseUser(EntrepriseUser(
        cloudId: 'eu-2', entrepriseId: 'ent-2', userId: 'user-1',
        role: 'membre', statut: 'revoque', revokedAt: now(),
        creeLe: now(), updatedAt: now(),
      ));
      final actives = await repo.watchEntreprisesForUser('user-1').first;
      expect(actives, hasLength(1));
      expect(actives.first.entrepriseId, 'ent-1');
    });
  });

  group('Membres entrepôt (#366)', () {
    test('watchMembersOfEntrepot liste les membres de l\'entrepôt', () async {
      await seedParents();
      await repo.upsertEntrepotUser(EntrepotUser(
        cloudId: 'epu-1', entrepotId: 'epot-1', userId: 'user-1',
        role: 'chef_entrepot', statut: 'actif', revokedAt: null,
        creeLe: now(), updatedAt: now(),
      ));
      await repo.upsertEntrepotUser(EntrepotUser(
        cloudId: 'epu-2', entrepotId: 'epot-1', userId: 'user-2',
        role: 'employe', statut: 'actif', revokedAt: null,
        creeLe: now(), updatedAt: now(),
      ));
      final membres = await repo.watchMembersOfEntrepot('epot-1').first;
      expect(membres, hasLength(2));
    });

    test('watchEntrepotsForUser ne renvoie que les actifs', () async {
      await seedParents();
      await repo.upsertEntrepotUser(EntrepotUser(
        cloudId: 'epu-actif', entrepotId: 'epot-1', userId: 'user-9',
        role: 'employe', statut: 'actif', revokedAt: null,
        creeLe: now(), updatedAt: now(),
      ));
      await repo.upsertEntrepot(Entrepot(
        cloudId: 'epot-2', entrepriseId: 'ent-1', nom: 'Dépôt 2',
        adresse: null, lat: null, lng: null, creeLe: now(), updatedAt: now(),
      ));
      await repo.upsertEntrepotUser(EntrepotUser(
        cloudId: 'epu-rev', entrepotId: 'epot-2', userId: 'user-9',
        role: 'employe', statut: 'revoque', revokedAt: now(),
        creeLe: now(), updatedAt: now(),
      ));
      final actifs = await repo.watchEntrepotsForUser('user-9').first;
      expect(actifs, hasLength(1));
      expect(actifs.first.entrepotId, 'epot-1');
    });
  });

  group('Invitations pending (#366)', () {
    test('watchPendingInvitations ne renvoie que les pending', () async {
      await seedParents();
      await repo.upsertInvitation(EntrepriseInvitation(
        cloudId: 'inv-p', entrepriseId: 'ent-1', entrepotId: null,
        email: 'a@x.com', roleTarget: 'employe', invitedBy: 'user-1',
        statut: 'pending', expiresAt: now().add(const Duration(days: 7)),
        creeLe: now(),
      ));
      await repo.upsertInvitation(EntrepriseInvitation(
        cloudId: 'inv-a', entrepriseId: 'ent-1', entrepotId: null,
        email: 'b@x.com', roleTarget: 'employe', invitedBy: 'user-1',
        statut: 'accepted', expiresAt: now().add(const Duration(days: 7)),
        creeLe: now(),
      ));
      final pendings = await repo.watchPendingInvitations('ent-1').first;
      expect(pendings, hasLength(1));
      expect(pendings.first.email, 'a@x.com');
    });
  });

  group('Notes perso local (#367)', () {
    test('upsert puis get retourne la note', () async {
      await repo.upsertNotePerso(SavedDestinationNotesPersoData(
        cloudId: 'np-1', savedDestinationId: 'sd-1', userId: 'user-1',
        notes: 'Sonner fort', creeLe: now(), updatedAt: now(),
      ));
      final n = await repo.getNotePerso(
          savedDestinationId: 'sd-1', userId: 'user-1');
      expect(n, isNotNull);
      expect(n!.notes, 'Sonner fort');
    });

    test('isolation par user : user-2 ne voit pas la note de user-1',
        () async {
      await repo.upsertNotePerso(SavedDestinationNotesPersoData(
        cloudId: 'np-1', savedDestinationId: 'sd-1', userId: 'user-1',
        notes: 'privé', creeLe: now(), updatedAt: now(),
      ));
      final autre = await repo.getNotePerso(
          savedDestinationId: 'sd-1', userId: 'user-2');
      expect(autre, isNull);
    });

    test('isolation par client : même user, autre destination = null',
        () async {
      await repo.upsertNotePerso(SavedDestinationNotesPersoData(
        cloudId: 'np-1', savedDestinationId: 'sd-1', userId: 'user-1',
        notes: 'x', creeLe: now(), updatedAt: now(),
      ));
      final autre = await repo.getNotePerso(
          savedDestinationId: 'sd-2', userId: 'user-1');
      expect(autre, isNull);
    });

    test('watchNotePerso émet la note courante', () async {
      await repo.upsertNotePerso(SavedDestinationNotesPersoData(
        cloudId: 'np-1', savedDestinationId: 'sd-1', userId: 'user-1',
        notes: 'live', creeLe: now(), updatedAt: now(),
      ));
      final n = await repo
          .watchNotePerso(savedDestinationId: 'sd-1', userId: 'user-1')
          .first;
      expect(n?.notes, 'live');
    });

    test('deleteNotePerso supprime la note', () async {
      await repo.upsertNotePerso(SavedDestinationNotesPersoData(
        cloudId: 'np-1', savedDestinationId: 'sd-1', userId: 'user-1',
        notes: 'à supprimer', creeLe: now(), updatedAt: now(),
      ));
      await repo.deleteNotePerso('np-1');
      final n = await repo.getNotePerso(
          savedDestinationId: 'sd-1', userId: 'user-1');
      expect(n, isNull);
    });
  });
}
