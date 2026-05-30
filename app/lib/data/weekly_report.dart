import 'database.dart';

/// Rapport hebdomadaire automatique pour le donneur d'ordre (carte
/// #321). Pure fn qui agrege une semaine de tournees en texte court
/// prêt à envoyer par mail/WhatsApp.
class WeeklyReport {
  WeeklyReport._();

  /// Composeur d'un rapport hebdo lisible pour TFA/Telia.
  static String compose({
    required DateTime weekStart,
    required List<Tournee> tournees,
    required List<Stop> allStops,
  }) {
    final livres =
        allStops.where((s) => s.statutLivraison == 'livre').length;
    final echecs =
        allStops.where((s) => s.statutLivraison == 'echec').length;
    final tentatives = livres + echecs;
    final tauxReussite =
        tentatives == 0 ? 0.0 : 100.0 * livres / tentatives;
    final colisTotal =
        allStops.fold<int>(0, (sum, s) => sum + s.nbColis);
    final kmTotal = tournees.fold<int>(
        0, (sum, t) => sum + (t.distanceTotaleM ?? 0));

    final buf = StringBuffer();
    buf.writeln('=== Rapport hebdo opti_route ===');
    buf.writeln('Semaine du ${_fmt(weekStart)}');
    buf.writeln('');
    buf.writeln('Tournees    : ${tournees.length}');
    buf.writeln('Stops total : ${allStops.length}');
    buf.writeln('Colis total : $colisTotal');
    buf.writeln('Livres      : $livres');
    buf.writeln('Echecs      : $echecs');
    buf.writeln('Tx reussite : ${tauxReussite.toStringAsFixed(1)}%');
    buf.writeln('Km parcourus: ${(kmTotal / 1000).toStringAsFixed(1)} km');
    if (echecs > 0) {
      final raisons = <String, int>{};
      for (final s in allStops.where((s) => s.statutLivraison == 'echec')) {
        final r = (s.raisonEchec ?? 'autre').toLowerCase();
        raisons[r] = (raisons[r] ?? 0) + 1;
      }
      buf.writeln('');
      buf.writeln('Detail echecs :');
      for (final e in raisons.entries) {
        buf.writeln('  - ${e.key} : ${e.value}');
      }
    }
    return buf.toString();
  }

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
