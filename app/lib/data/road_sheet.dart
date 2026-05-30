import 'database.dart';

/// Genere une feuille de route texte (carte #298), prete a imprimer
/// sur une A4 en secours anti-panne batterie. Format simple : 1 ligne
/// par arret, colonnes "N  Adresse  Colis  Notes  [ ] livre  [ ] echec".
///
/// Fonction PURE : prend la tournee + stops + retourne string. Le
/// caller fait l'impression (text/plain, ou rendu sur canvas PDF).
class RoadSheetGenerator {
  RoadSheetGenerator._();

  static String compose({
    required Tournee tournee,
    required List<Stop> orderedStops,
  }) {
    final buf = StringBuffer();
    buf.writeln('Feuille de route - ${tournee.nom}');
    buf.writeln('Date : ${_fmtDate(tournee.date)}');
    buf.writeln('Depart : ${tournee.pointDepartLabel}');
    buf.writeln('');
    buf.writeln(
        '#  Adresse                                          Colis  Livre  Echec');
    buf.writeln(
        '---------------------------------------------------------------------');
    for (var i = 0; i < orderedStops.length; i++) {
      final s = orderedStops[i];
      final num = (i + 1).toString().padLeft(2);
      final addr = s.adresseBrute.length > 47
          ? '${s.adresseBrute.substring(0, 44)}...'
          : s.adresseBrute.padRight(47);
      final col = s.nbColis.toString().padLeft(5);
      buf.writeln('$num  $addr  $col   [ ]    [ ]');
      final extras = <String>[];
      if ((s.nomClient ?? '').isNotEmpty) extras.add('client: ${s.nomClient}');
      if ((s.notes ?? '').isNotEmpty) extras.add('notes: ${s.notes}');
      if (extras.isNotEmpty) {
        buf.writeln('    ${extras.join(' | ')}');
      }
    }
    return buf.toString();
  }

  static String _fmtDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
  }
}
