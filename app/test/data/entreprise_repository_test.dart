import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/entreprise_repository.dart';

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

  group('Schema v48 (multi-tenant)', () {
    test('schemaVersion = 48', () {
      expect(db.schemaVersion, 48);
    });

    test('Toutes les 6 nouvelles tables existent et acceptent les inserts',
        () async {
      // Smoke test : si l'une des 6 tables n'est pas creee correctement,
      // l'insert throw.
      const entrepriseId = 'ent-1';
      const entrepotId = 'epot-1';
      const userId = 'user-1';

      await repo.upsertEntreprise(Entreprise(
        cloudId: entrepriseId,
        nom: 'CALOTE Noah',
        siret: null,
        createdBy: userId,
        creeLe: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      await repo.upsertEntrepot(Entrepot(
        cloudId: entrepotId,
        entrepriseId: entrepriseId,
        nom: 'Entrepot Auneau',
        adresse: null,
        lat: null,
        lng: null,
        creeLe: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      await repo.upsertEntrepriseUser(EntrepriseUser(
        cloudId: 'eu-1',
        entrepriseId: entrepriseId,
        userId: userId,
        role: 'admin_entreprise',
        statut: 'actif',
        revokedAt: null,
        creeLe: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      await repo.upsertEntrepotUser(EntrepotUser(
        cloudId: 'epu-1',
        entrepotId: entrepotId,
        userId: userId,
        role: 'chef_entrepot',
        statut: 'actif',
        revokedAt: null,
        creeLe: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      await repo.upsertInvitation(EntrepriseInvitation(
        cloudId: 'inv-1',
        entrepriseId: entrepriseId,
        entrepotId: entrepotId,
        email: 'marc@example.com',
        roleTarget: 'employe',
        invitedBy: userId,
        statut: 'pending',
        expiresAt: DateTime.now().add(const Duration(days: 7)),
        creeLe: DateTime.now(),
      ));

      await repo.upsertNotePerso(SavedDestinationNotesPersoData(
        cloudId: 'np-1',
        savedDestinationId: 'sd-1',
        userId: userId,
        notes: 'Sent l\'alcool',
        creeLe: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      // Verif lectures
      expect((await repo.getEntrepriseById(entrepriseId))!.nom, 'CALOTE Noah');
      expect((await repo.getEntrepotById(entrepotId))!.nom, 'Entrepot Auneau');
      expect(
          (await repo.getNotePerso(
                  savedDestinationId: 'sd-1', userId: userId))!
              .notes,
          contains('alcool'));
    });

    test('saved_destinations a les colonnes entrepriseId + entrepotId', () async {
      const userId = 'user-2';
      const entrepriseId = 'ent-2';
      const entrepotId = 'epot-2';

      await repo.upsertEntreprise(Entreprise(
        cloudId: entrepriseId, nom: 'X', siret: null, createdBy: userId,
        creeLe: DateTime.now(), updatedAt: DateTime.now(),
      ));
      await repo.upsertEntrepot(Entrepot(
        cloudId: entrepotId, entrepriseId: entrepriseId, nom: 'A', adresse: null,
        lat: null, lng: null, creeLe: DateTime.now(), updatedAt: DateTime.now(),
      ));

      final id = await db.into(db.savedDestinations).insert(
            SavedDestinationsCompanion.insert(
              adresseDisplay: '12 rue de la Paix',
              lat: 48.86,
              lng: 2.33,
              ville: const Value('Paris'),
              entrepriseId: const Value(entrepriseId),
              entrepotId: const Value(entrepotId),
            ),
          );
      final row = await (db.select(db.savedDestinations)
            ..where((s) => s.id.equals(id)))
          .getSingle();
      expect(row.entrepriseId, entrepriseId);
      expect(row.entrepotId, entrepotId);
    });

    test('watchEntrepriseUser filtre statut=actif', () async {
      const entrepriseId = 'ent-3';
      const userId = 'user-3';
      await repo.upsertEntreprise(Entreprise(
        cloudId: entrepriseId, nom: 'Y', siret: null, createdBy: userId,
        creeLe: DateTime.now(), updatedAt: DateTime.now(),
      ));
      // 1 actif + 1 revoque
      await repo.upsertEntrepriseUser(EntrepriseUser(
        cloudId: 'eu-actif', entrepriseId: entrepriseId, userId: userId,
        role: 'membre', statut: 'actif', revokedAt: null,
        creeLe: DateTime.now(), updatedAt: DateTime.now(),
      ));
      await repo.upsertEntrepriseUser(EntrepriseUser(
        cloudId: 'eu-revoque', entrepriseId: entrepriseId, userId: 'autre-user',
        role: 'membre', statut: 'revoque',
        revokedAt: DateTime.now().subtract(const Duration(days: 5)),
        creeLe: DateTime.now(), updatedAt: DateTime.now(),
      ));

      final actifs = await repo.watchEntreprisesForUser(userId).first;
      expect(actifs, hasLength(1));
      expect(actifs.first.statut, 'actif');
    });
  });
}
