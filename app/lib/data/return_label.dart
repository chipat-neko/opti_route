import 'database.dart';

/// Genere le contenu texte d'une etiquette retour pour un colis refuse
/// ou non distribue (carte #306). A coller/joindre au colis pour le
/// tri retour au depot.
class ReturnLabel {
  ReturnLabel._();

  static String compose({
    required Stop stop,
    DateTime? when,
  }) {
    final t = when ?? stop.livreLe ?? DateTime.now();
    final dd = t.day.toString().padLeft(2, '0');
    final mm = t.month.toString().padLeft(2, '0');
    final hh = t.hour.toString().padLeft(2, '0');
    final mn = t.minute.toString().padLeft(2, '0');
    final raison = (stop.raisonEchec ?? 'non distribue').toUpperCase();
    final tracking = (stop.trackingNumbers ?? '').replaceAll(RegExp('[\\[\\]"]'), '');
    final buf = StringBuffer();
    buf.writeln('=== RETOUR DEPOT ===');
    buf.writeln('Raison : $raison');
    buf.writeln('Date   : $dd/$mm/${t.year} $hh:$mn');
    if (tracking.isNotEmpty) buf.writeln('Track  : $tracking');
    if ((stop.nomClient ?? '').isNotEmpty) {
      buf.writeln('Client : ${stop.nomClient}');
    }
    buf.writeln('Adresse: ${stop.adresseBrute}');
    buf.writeln('Colis  : ${stop.nbColis}');
    if ((stop.preuvePhotoPath ?? '').isNotEmpty) {
      buf.writeln('[photo preuve disponible dans opti_route]');
    }
    return buf.toString();
  }
}
