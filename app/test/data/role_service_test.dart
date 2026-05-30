import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/app_role.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/parametres_repository.dart';
import 'package:opti_route/data/role_service.dart';

void main() {
  late AppDatabase db;
  late RoleService svc;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    svc = RoleService(ParametresRepository(db));
  });
  tearDown(() async => db.close());

  group('RoleService.readLocalRole', () {
    test('default chauffeur (toggle jamais set)', () async {
      expect(await svc.readLocalRole(), AppRole.chauffeur);
    });

    test('apres writeLocalRole(chef) -> chef', () async {
      await svc.writeLocalRole(AppRole.chef);
      expect(await svc.readLocalRole(), AppRole.chef);
    });

    test('toggle chef -> chauffeur', () async {
      await svc.writeLocalRole(AppRole.chef);
      await svc.writeLocalRole(AppRole.chauffeur);
      expect(await svc.readLocalRole(), AppRole.chauffeur);
    });
  });

  group('RoleService.resolveCurrentRole', () {
    test('sans override serveur -> suit local', () async {
      await svc.writeLocalRole(AppRole.chef);
      expect(await svc.resolveCurrentRole(), AppRole.chef);
    });

    test('override serveur chef -> chef meme si local chauffeur', () async {
      expect(
        await svc.resolveCurrentRole(serverRoleRaw: 'chef'),
        AppRole.chef,
      );
      expect(
        await svc.resolveCurrentRole(serverRoleRaw: 'CHEF'),
        AppRole.chef,
      );
      expect(
        await svc.resolveCurrentRole(serverRoleRaw: 'manager'),
        AppRole.chef,
      );
    });

    test('override serveur chauffeur n\'écrase PAS local chef', () async {
      await svc.writeLocalRole(AppRole.chef);
      expect(
        await svc.resolveCurrentRole(serverRoleRaw: 'chauffeur'),
        AppRole.chef,
        reason: 'override ne retrograde pas',
      );
    });

    test('serveur vide / null -> suit local', () async {
      expect(await svc.resolveCurrentRole(serverRoleRaw: ''),
          AppRole.chauffeur);
      expect(await svc.resolveCurrentRole(serverRoleRaw: null),
          AppRole.chauffeur);
    });
  });

  group('RoleService.watchLocalRole', () {
    test('emet a chaque toggle', () async {
      final values = <AppRole>[];
      final sub = svc.watchLocalRole().listen(values.add);
      await svc.writeLocalRole(AppRole.chef);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await svc.writeLocalRole(AppRole.chauffeur);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await sub.cancel();
      expect(values.any((v) => v == AppRole.chef), isTrue);
      expect(values.any((v) => v == AppRole.chauffeur), isTrue);
    });
  });
}
