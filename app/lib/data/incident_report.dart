/// Brouillon de constat amiable / rapport sinistre pré-rempli (carte
/// #334). Pure fn : prend les infos contextuelles (GPS, heure, météo)
/// + un type d'incident, retourne un texte structuré prêt à envoyer
/// par mail à l'assurance.
class IncidentReport {
  IncidentReport._();

  static String compose({
    required IncidentKind kind,
    required DateTime when,
    double? lat,
    double? lng,
    String? addressApprox,
    String? weatherSummary,
    String? freeText,
  }) {
    final buf = StringBuffer()
      ..writeln('=== INCIDENT - ${kind.label.toUpperCase()} ===')
      ..writeln('Date : ${_fmtDate(when)} ${_fmtTime(when)}');
    if (addressApprox != null && addressApprox.isNotEmpty) {
      buf.writeln('Lieu (approx) : $addressApprox');
    }
    if (lat != null && lng != null) {
      buf.writeln(
          'GPS : ${lat.toStringAsFixed(5)},${lng.toStringAsFixed(5)}');
      buf.writeln(
          'Maps : https://maps.google.com/?q=${lat.toStringAsFixed(5)},${lng.toStringAsFixed(5)}');
    }
    if (weatherSummary != null && weatherSummary.isNotEmpty) {
      buf.writeln('Conditions : $weatherSummary');
    }
    buf.writeln('');
    buf.writeln('-- Description --');
    if ((freeText ?? '').trim().isEmpty) {
      buf.writeln('(à compléter par Noah)');
    } else {
      buf.writeln(freeText!.trim());
    }
    buf.writeln('');
    buf.writeln('-- À joindre --');
    buf.writeln('- Photos prises sur place');
    buf.writeln('- Coordonnées du tiers (nom, adresse, assureur, n° contrat)');
    buf.writeln('- Plaque immatriculation du tiers');
    if (kind == IncidentKind.theft || kind == IncidentKind.aggression) {
      buf.writeln('- Récépissé de dépôt de plainte');
    }
    return buf.toString();
  }

  static String _fmtDate(DateTime d) =>
      '${_pad(d.day)}/${_pad(d.month)}/${d.year}';
  static String _fmtTime(DateTime d) => '${_pad(d.hour)}:${_pad(d.minute)}';
  static String _pad(int v) => v.toString().padLeft(2, '0');
}

enum IncidentKind {
  accrochage('Accrochage / accident'),
  panne('Panne'),
  theft('Vol / cambriolage'),
  aggression('Agression / incident client'),
  autre('Autre');

  const IncidentKind(this.label);
  final String label;
}
