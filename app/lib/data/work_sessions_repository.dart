import 'package:drift/drift.dart';

import 'database.dart';

/// Repository pointage debut/fin de service (carte #279).
///
/// Invariants :
/// - **Au plus une session ouverte** (`endedAt` null) a la fois.
///   `startSession()` est un no-op si une session est deja ouverte.
/// - `endCurrentSession()` est un no-op si aucune session n'est ouverte.
///
/// Fonctions pure-data : pas d'UI, pas de SnackBar. Le caller (widget)
/// observe via [watchCurrent] et appelle [startSession] / [endCurrentSession]
/// au tap. Les calculs de duree cumulee (jour / semaine) sont fournis
/// par [durationForDay] et [durationForRange] (les sessions ouvertes
/// sont cappees a `now` pour le calcul).
class WorkSessionsRepository {
  WorkSessionsRepository(this._db);

  final AppDatabase _db;

  /// Retourne la session ouverte (endedAt null) la plus recente, ou
  /// null si aucune.
  Future<WorkSession?> getCurrent() async {
    final q = _db.select(_db.workSessions)
      ..where((s) => s.endedAt.isNull())
      ..orderBy([(s) => OrderingTerm.desc(s.startedAt)])
      ..limit(1);
    return q.getSingleOrNull();
  }

  /// Stream de la session courante (ouverte) ; null si aucune. Permet
  /// a l'UI de basculer son label "Commencer" <-> "Terminer" en live.
  Stream<WorkSession?> watchCurrent() {
    final q = _db.select(_db.workSessions)
      ..where((s) => s.endedAt.isNull())
      ..orderBy([(s) => OrderingTerm.desc(s.startedAt)])
      ..limit(1);
    return q.watchSingleOrNull();
  }

  /// Demarre une nouvelle session a [now] (default `DateTime.now()`).
  /// No-op si une session est deja ouverte (retourne l'existante).
  Future<WorkSession> startSession({DateTime? now}) async {
    final existing = await getCurrent();
    if (existing != null) return existing;
    final start = now ?? DateTime.now();
    final id = await _db.into(_db.workSessions).insert(
          WorkSessionsCompanion.insert(startedAt: start),
        );
    return (_db.select(_db.workSessions)..where((s) => s.id.equals(id)))
        .getSingle();
  }

  /// Termine la session ouverte a [now]. No-op si aucune session
  /// ouverte. Retourne true si une session a effectivement ete fermee.
  Future<bool> endCurrentSession({DateTime? now}) async {
    final current = await getCurrent();
    if (current == null) return false;
    await (_db.update(_db.workSessions)
          ..where((s) => s.id.equals(current.id)))
        .write(WorkSessionsCompanion(endedAt: Value(now ?? DateTime.now())));
    return true;
  }

  /// Sessions chevauchant la fenetre [from, to[ (ordre ascendant par
  /// startedAt). Inclut une session encore ouverte si startedAt <= to.
  Future<List<WorkSession>> getByDateRange({
    required DateTime from,
    required DateTime to,
  }) async {
    final q = _db.select(_db.workSessions)
      ..where((s) =>
          s.startedAt.isSmallerThanValue(to) &
          (s.endedAt.isNull() | s.endedAt.isBiggerOrEqualValue(from)))
      ..orderBy([(s) => OrderingTerm.asc(s.startedAt)]);
    return q.get();
  }

  /// Duree cumulee travaillee sur [day] (24h locales). Les sessions en
  /// cours sont cappees a [now].
  Future<Duration> durationForDay(DateTime day, {DateTime? now}) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return durationForRange(from: start, to: end, now: now);
  }

  /// Duree cumulee dans la fenetre [from, to[. Les sessions ouvertes
  /// sont cappees a min([now], to).
  Future<Duration> durationForRange({
    required DateTime from,
    required DateTime to,
    DateTime? now,
  }) async {
    final clamp = (now ?? DateTime.now()).isBefore(to) ? (now ?? DateTime.now()) : to;
    final sessions = await getByDateRange(from: from, to: to);
    var total = Duration.zero;
    for (final s in sessions) {
      final segStart = s.startedAt.isBefore(from) ? from : s.startedAt;
      final rawEnd = s.endedAt ?? clamp;
      final segEnd = rawEnd.isAfter(to) ? to : rawEnd;
      if (segEnd.isAfter(segStart)) {
        total += segEnd.difference(segStart);
      }
    }
    return total;
  }
}
