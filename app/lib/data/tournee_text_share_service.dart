import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import 'database.dart';

/// Service de partage rapide d'une tournee sous forme **texte court**,
/// destine a etre envoye par WhatsApp / SMS / mail. Plus rapide a
/// produire et a lire qu'un PDF, et tient dans un message sans piece
/// jointe.
///
/// Format type :
/// ```
/// Tournee du 12/05/2026 - 8 arrets - 45 km / 1h30
///
/// 1. CALOTE Noah
///    12 rue des Lilas, 28100 Dreux
///    3 colis - avant 12:00
///
/// 2. Carrefour Dreux
///    4 av. de la Gare, 28100 Dreux
///    1 colis
///
/// ...
/// ```
class TourneeTextShareService {
  /// Format texte pur de la tournee. Si [orderedStops] est fourni, on
  /// l'utilise tel quel (ordre optimise). Sinon on retombe sur l'ordre
  /// naturel de la liste.
  String formatPlainText({
    required Tournee tournee,
    required List<Stop> stops,
  }) {
    final dateLabel = DateFormat('EEEE d MMMM y', 'fr').format(tournee.date);
    final buf = StringBuffer();

    // En-tete
    buf.writeln('Tournee "${tournee.nom}"');
    buf.writeln(dateLabel);
    final nb = stops.length;
    final totalColis = stops.fold<int>(0, (acc, s) => acc + s.nbColis);
    buf.write('$nb arret${nb > 1 ? "s" : ""} - $totalColis colis');
    if (tournee.distanceTotaleM != null && tournee.dureeTotaleS != null) {
      final km = (tournee.distanceTotaleM! / 1000).toStringAsFixed(1);
      buf.write(' - $km km / ${_formatDuration(tournee.dureeTotaleS!)}');
    }
    buf.writeln();
    buf.writeln();

    // Liste des arrets
    for (var i = 0; i < stops.length; i++) {
      final s = stops[i];
      buf.writeln('${i + 1}. ${_titreArret(s)}');
      final adresse = s.adresseNormalisee ?? s.adresseBrute;
      // Si le titre EST l'adresse, on n'ecrit pas l'adresse 2 fois
      if (_titreArret(s) != adresse) {
        buf.writeln('   $adresse');
      }
      final details = <String>[];
      details.add('${s.nbColis} colis');
      if (s.fenetreDebut != null && s.fenetreFin != null) {
        details.add('${s.fenetreDebut} - ${s.fenetreFin}');
      } else if (s.fenetreDebut != null) {
        details.add('apres ${s.fenetreDebut}');
      } else if (s.fenetreFin != null) {
        details.add('avant ${s.fenetreFin}');
      }
      if (s.priorite == 'obligatoire_premier') details.add('EN 1ER');
      if (s.priorite == 'obligatoire_dernier') details.add('EN DERNIER');
      if (s.priorite == 'eviter_si_possible') details.add('A EVITER');
      if (details.isNotEmpty) {
        buf.writeln('   ${details.join(' - ')}');
      }
      if (s.notes != null && s.notes!.trim().isNotEmpty) {
        buf.writeln('   Note: ${s.notes!.trim()}');
      }
      // Separateur entre arrets, sauf apres le dernier
      if (i < stops.length - 1) buf.writeln();
    }

    return buf.toString();
  }

  /// Lance le partage natif Android avec le texte formate. Le selecteur
  /// propose toutes les apps qui acceptent du texte (WhatsApp, SMS,
  /// Gmail, Telegram, etc.).
  Future<void> shareAsText({
    required Tournee tournee,
    required List<Stop> stops,
  }) async {
    final text = formatPlainText(tournee: tournee, stops: stops);
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: 'Tournee ${tournee.nom}',
      ),
    );
  }

  /// Titre d'un arret : nom du client si renseigne, sinon adresse.
  static String _titreArret(Stop s) {
    final nom = s.nomClient?.trim();
    if (nom != null && nom.isNotEmpty) return nom;
    return s.adresseNormalisee ?? s.adresseBrute;
  }

  static String _formatDuration(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    if (h == 0) return '${m}min';
    return '${h}h${m.toString().padLeft(2, '0')}';
  }
}
