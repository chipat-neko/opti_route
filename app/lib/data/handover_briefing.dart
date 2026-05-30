import 'database.dart';

/// Compose un briefing complet pour un remplaçant (carte #312) :
/// pour chaque stop, les "us et coutumes" qui ne sont pas dans le
/// QR/JSON de partage (carnet vigilance, code, étage, parking, mémo
/// vocal). Pure fn lisible humain + TTS.
class HandoverBriefing {
  HandoverBriefing._();

  static String composeText({
    required Tournee tournee,
    required List<Stop> orderedStops,
    Map<int, SavedDestination>? carnetByStopId,
  }) {
    final buf = StringBuffer();
    buf.writeln('=== PASSATION DE TOURNEE ===');
    buf.writeln('Tournee : ${tournee.nom}');
    buf.writeln('Date    : ${_fmtDate(tournee.date)}');
    buf.writeln('Depart  : ${tournee.pointDepartLabel}');
    buf.writeln('Stops   : ${orderedStops.length}');
    buf.writeln('');
    for (var i = 0; i < orderedStops.length; i++) {
      final s = orderedStops[i];
      final c = carnetByStopId?[s.id];
      buf.writeln('--- Arret ${i + 1} ---');
      buf.writeln('Adresse  : ${s.adresseBrute}');
      if ((s.nomClient ?? '').isNotEmpty) buf.writeln('Client   : ${s.nomClient}');
      buf.writeln('Colis    : ${s.nbColis}');
      if ((s.fenetreDebut ?? '').isNotEmpty ||
          (s.fenetreFin ?? '').isNotEmpty) {
        buf.writeln(
            'Fenetre  : ${s.fenetreDebut ?? '-'} -> ${s.fenetreFin ?? '-'}');
      }
      if (c != null) {
        if ((c.codeAcces ?? '').isNotEmpty) {
          buf.writeln('CODE     : ${c.codeAcces}');
        }
        if ((c.etageBatiment ?? '').isNotEmpty) {
          buf.writeln('Etage    : ${c.etageBatiment}');
        }
        if ((c.noteStationnement ?? '').isNotEmpty) {
          buf.writeln('Parking  : ${c.noteStationnement}');
        }
        if (c.isProblematique) buf.writeln('!! VIGILANCE !!');
        if (c.photoObligatoire) buf.writeln('!! PHOTO OBLIGATOIRE !!');
      }
      if ((s.notes ?? '').isNotEmpty) buf.writeln('Notes    : ${s.notes}');
      if ((s.memoVocal ?? '').isNotEmpty) {
        buf.writeln('Memo voc : ${s.memoVocal}');
      }
      buf.writeln('');
    }
    return buf.toString();
  }

  /// Phrases TTS pour un stop (lecture vocale au remplaçant à l'approche).
  /// Format compact, sans préambule, prêt à passer à `FlutterTts.speak`.
  static String composeTtsForStop({
    required Stop stop,
    SavedDestination? carnet,
  }) {
    final parts = <String>[];
    if ((stop.nomClient ?? '').isNotEmpty) parts.add(stop.nomClient!);
    parts.add(stop.adresseBrute);
    if (carnet != null) {
      if ((carnet.codeAcces ?? '').isNotEmpty) {
        parts.add('Code : ${carnet.codeAcces}');
      }
      if ((carnet.etageBatiment ?? '').isNotEmpty) parts.add(carnet.etageBatiment!);
      if (carnet.isProblematique) parts.add('Attention vigilance.');
      if (carnet.photoObligatoire) parts.add('Photo obligatoire.');
      if ((carnet.noteStationnement ?? '').isNotEmpty) {
        parts.add('Parking : ${carnet.noteStationnement}');
      }
    }
    if ((stop.memoVocal ?? '').isNotEmpty) parts.add(stop.memoVocal!);
    parts.add(stop.nbColis == 1 ? '1 colis' : '${stop.nbColis} colis');
    return parts.join('. ');
  }

  static String _fmtDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
  }
}
