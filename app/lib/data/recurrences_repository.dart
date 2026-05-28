import 'package:drift/drift.dart';

import 'database.dart';

/// CRUD des recurrences de tournee (carte #113). Au plus UNE recurrence
/// par template : [upsert] cree ou met a jour la ligne du template.
class RecurrencesRepository {
  RecurrencesRepository(this._db);

  final AppDatabase _db;

  /// Recurrence d'un template, ou null si aucune.
  Future<TourneeRecurrence?> getByTemplate(int templateId) {
    return (_db.select(_db.tourneeRecurrences)
          ..where((r) => r.templateId.equals(templateId)))
        .getSingleOrNull();
  }

  /// Stream de la recurrence d'un template (pour l'UI de config).
  Stream<TourneeRecurrence?> watchByTemplate(int templateId) {
    return (_db.select(_db.tourneeRecurrences)
          ..where((r) => r.templateId.equals(templateId)))
        .watchSingleOrNull();
  }

  /// Toutes les recurrences actives (sert a [RecurrenceService.runDue]).
  Future<List<TourneeRecurrence>> getActives() {
    return (_db.select(_db.tourneeRecurrences)
          ..where((r) => r.actif.equals(true)))
        .get();
  }

  /// Cree ou met a jour la recurrence du template. Reset
  /// `derniereGenerationLe` a null a chaque (re)config pour que le
  /// prochain jour cible declenche bien une generation.
  Future<void> upsert({
    required int templateId,
    required String frequence,
    int? jourSemaine,
    int? jourMois,
    bool actif = true,
  }) async {
    final existing = await getByTemplate(templateId);
    if (existing == null) {
      await _db.into(_db.tourneeRecurrences).insert(
            TourneeRecurrencesCompanion.insert(
              templateId: templateId,
              frequence: frequence,
              jourSemaine: Value(jourSemaine),
              jourMois: Value(jourMois),
              actif: Value(actif),
            ),
          );
    } else {
      await (_db.update(_db.tourneeRecurrences)
            ..where((r) => r.id.equals(existing.id)))
          .write(TourneeRecurrencesCompanion(
        frequence: Value(frequence),
        jourSemaine: Value(jourSemaine),
        jourMois: Value(jourMois),
        actif: Value(actif),
        derniereGenerationLe: const Value(null),
      ));
    }
  }

  /// Active / desactive la recurrence d'un template (sans changer la
  /// config de frequence). No-op si pas de recurrence.
  Future<void> setActif(int templateId, bool actif) async {
    await (_db.update(_db.tourneeRecurrences)
          ..where((r) => r.templateId.equals(templateId)))
        .write(TourneeRecurrencesCompanion(actif: Value(actif)));
  }

  /// Marque une recurrence comme generee a [when] (dedup intra-jour).
  Future<void> markGenerated(int recurrenceId, DateTime when) async {
    await (_db.update(_db.tourneeRecurrences)
          ..where((r) => r.id.equals(recurrenceId)))
        .write(TourneeRecurrencesCompanion(
      derniereGenerationLe: Value(when),
    ));
  }

  Future<int> deleteForTemplate(int templateId) {
    return (_db.delete(_db.tourneeRecurrences)
          ..where((r) => r.templateId.equals(templateId)))
        .go();
  }
}
