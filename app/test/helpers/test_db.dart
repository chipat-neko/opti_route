// Helpers de test partagés (F46) : construction d'une AppDatabase en
// mémoire + seed minimal. But : arrêter de recopier le même
// `AppDatabase(NativeDatabase.memory())` + insert de tournée dans chaque
// fichier de test. Les nouveaux tests passent par ici ; les 115 existants
// pourront migrer progressivement.
import 'package:drift/native.dart';
import 'package:opti_route/data/database.dart';

/// Une AppDatabase Drift en mémoire, isolée et éphémère (repartie propre
/// à chaque appel). À fermer via `await db.close()` en fin de test.
AppDatabase makeTestDb() => AppDatabase(NativeDatabase.memory());

/// Insère une tournée minimale valide et retourne son id.
/// Tous les champs non nullables du schéma sont renseignés avec des
/// valeurs par défaut ; surchargeables au besoin.
Future<int> seedTournee(
  AppDatabase db, {
  String nom = 'T',
  DateTime? date,
  double pointDepartLat = 48.0,
  double pointDepartLng = 1.0,
  String pointDepartLabel = 'Dépôt',
}) {
  return db.into(db.tournees).insert(
        TourneesCompanion.insert(
          nom: nom,
          date: date ?? DateTime(2026, 1, 1),
          pointDepartLat: pointDepartLat,
          pointDepartLng: pointDepartLng,
          pointDepartLabel: pointDepartLabel,
        ),
      );
}
