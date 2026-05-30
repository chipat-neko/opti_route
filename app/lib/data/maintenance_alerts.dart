/// Rappels d'entretien véhicule (carte #316). Pure fn.
/// Croise km parcourus + date dernier événement avec les seuils
/// constructeur/légaux. Émet des alertes "dans X km" / "dans Y jours".
class MaintenanceAlerts {
  MaintenanceAlerts._();

  static const int vidangeIntervalKm = 10000;
  static const int courroieIntervalKm = 100000;
  static const int ctIntervalYears = 4; // contrôle technique VL
  static const int ctRenewalYears = 2; // renouvellement post 4 ans
  static const int pneusHiverMonth = 11; // novembre

  /// Construit la liste des alertes actives à [now]. Le caller fournit
  /// l'odo courant + les snapshots du dernier événement.
  static List<MaintenanceAlert> compute({
    required int currentOdometerKm,
    required DateTime now,
    int? lastVidangeOdometerKm,
    DateTime? firstRegistrationDate,
    DateTime? lastCtDate,
    DateTime? lastCourroieDate,
    int? lastCourroieOdometerKm,
  }) {
    final out = <MaintenanceAlert>[];
    if (lastVidangeOdometerKm != null) {
      final delta = currentOdometerKm - lastVidangeOdometerKm;
      if (delta >= vidangeIntervalKm - 500) {
        out.add(MaintenanceAlert(
          kind: MaintenanceKind.vidange,
          dueInKm: (vidangeIntervalKm - delta).clamp(-99999, 99999),
        ));
      }
    }
    if (lastCourroieOdometerKm != null) {
      final delta = currentOdometerKm - lastCourroieOdometerKm;
      if (delta >= courroieIntervalKm - 5000) {
        out.add(MaintenanceAlert(
          kind: MaintenanceKind.courroie,
          dueInKm: courroieIntervalKm - delta,
        ));
      }
    }
    if (firstRegistrationDate != null) {
      final firstCt = DateTime(
        firstRegistrationDate.year + ctIntervalYears,
        firstRegistrationDate.month,
        firstRegistrationDate.day,
      );
      final reference = lastCtDate ?? firstCt;
      final nextCt = lastCtDate == null
          ? firstCt
          : DateTime(
              reference.year + ctRenewalYears,
              reference.month,
              reference.day,
            );
      final daysLeft = nextCt.difference(now).inDays;
      if (daysLeft <= 30) {
        out.add(MaintenanceAlert(
          kind: MaintenanceKind.controlTechnique,
          dueInDays: daysLeft,
        ));
      }
    }
    if (now.month == pneusHiverMonth) {
      out.add(const MaintenanceAlert(kind: MaintenanceKind.pneusHiver));
    }
    return out;
  }
}

class MaintenanceAlert {
  const MaintenanceAlert({
    required this.kind,
    this.dueInKm,
    this.dueInDays,
  });

  final MaintenanceKind kind;
  final int? dueInKm;
  final int? dueInDays;

  bool get isOverdue =>
      (dueInKm != null && dueInKm! <= 0) ||
      (dueInDays != null && dueInDays! <= 0);
}

enum MaintenanceKind { vidange, courroie, controlTechnique, pneusHiver }
