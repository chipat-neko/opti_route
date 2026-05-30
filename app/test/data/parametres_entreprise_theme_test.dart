import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/parametres_repository.dart';

// Tests des helpers defaut+set+clear pour entreprise (nom/SIRET/slogan),
// theme preset, densite UI, contraste eleve, mode chef. Aucun n'etait
// couvert dans parametres_repository_test (qui se concentrait sur ORS,
// theme mode, watchers, cle API, carburant).
void main() {
  late AppDatabase db;
  late ParametresRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = ParametresRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Entreprise — nom/SIRET/slogan', () {
    test('defauts null', () async {
      expect(await repo.getEntrepriseNom(), isNull);
      expect(await repo.getEntrepriseSiret(), isNull);
      expect(await repo.getEntrepriseSlogan(), isNull);
    });

    test('setEntrepriseNom : trim applique', () async {
      await repo.setEntrepriseNom('  SARL Noah Express  ');
      expect(await repo.getEntrepriseNom(), 'SARL Noah Express');
    });

    test('setEntrepriseSiret : trim applique', () async {
      await repo.setEntrepriseSiret('  12345678901234  ');
      expect(await repo.getEntrepriseSiret(), '12345678901234');
    });

    test('setEntrepriseSlogan : trim applique', () async {
      await repo.setEntrepriseSlogan('  Vite et bien livre  ');
      expect(await repo.getEntrepriseSlogan(), 'Vite et bien livre');
    });

    test('clear*Entreprise* : remet null', () async {
      await repo.setEntrepriseNom('X');
      await repo.setEntrepriseSiret('Y');
      await repo.setEntrepriseSlogan('Z');
      await repo.clearEntrepriseNom();
      await repo.clearEntrepriseSiret();
      await repo.clearEntrepriseSlogan();
      expect(await repo.getEntrepriseNom(), isNull);
      expect(await repo.getEntrepriseSiret(), isNull);
      expect(await repo.getEntrepriseSlogan(), isNull);
    });
  });

  group('Theme preset', () {
    test('defaut : "lime"', () async {
      expect(await repo.getThemePreset(), 'lime');
    });

    test('setThemePreset : ocean / terracotta / mono', () async {
      await repo.setThemePreset('ocean');
      expect(await repo.getThemePreset(), 'ocean');
      await repo.setThemePreset('terracotta');
      expect(await repo.getThemePreset(), 'terracotta');
      await repo.setThemePreset('mono');
      expect(await repo.getThemePreset(), 'mono');
    });

    test('watchThemePreset : emit defaut puis update', () async {
      final stream = repo.watchThemePreset();
      final values = <String>[];
      final sub = stream.listen(values.add);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await repo.setThemePreset('ocean');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await sub.cancel();
      expect(values, contains('lime'));
      expect(values, contains('ocean'));
    });
  });

  group('Densite UI', () {
    test('defaut : "normal"', () async {
      expect(await repo.getDensiteUi(), 'normal');
    });

    test('set/get round-trip "large"', () async {
      await repo.setDensiteUi('large');
      expect(await repo.getDensiteUi(), 'large');
    });
  });

  group('Contraste eleve', () {
    test('defaut : false', () async {
      expect(await repo.getContrasteEleve(), isFalse);
    });

    test('set true, puis re-set false', () async {
      await repo.setContrasteEleve(true);
      expect(await repo.getContrasteEleve(), isTrue);
      await repo.setContrasteEleve(false);
      expect(await repo.getContrasteEleve(), isFalse);
    });
  });

  group('Mode chef', () {
    test('defaut : false (solo)', () async {
      expect(await repo.getModeChef(), isFalse);
    });

    test('set true puis false : toggle round-trip', () async {
      await repo.setModeChef(true);
      expect(await repo.getModeChef(), isTrue);
      await repo.setModeChef(false);
      expect(await repo.getModeChef(), isFalse);
    });
  });

  group('Veille reminder HHmm', () {
    test('defaut : null (pas de rappel veille auto)', () async {
      expect(await repo.getVeilleReminderHHmm(), isNull);
    });

    test('set/get round-trip', () async {
      await repo.setVeilleReminderHHmm('21:00');
      expect(await repo.getVeilleReminderHHmm(), '21:00');
    });

    test('clear retire la valeur', () async {
      await repo.setVeilleReminderHHmm('20:30');
      await repo.clearVeilleReminderHHmm();
      expect(await repo.getVeilleReminderHHmm(), isNull);
    });
  });
}
