import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'database.dart';

/// ════════════════════════════════════════════════════════════════
/// Helpers de widgets PDF pour la generation du recap de tournee.
/// ════════════════════════════════════════════════════════════════
///
/// Extrait de `tournee_pdf_service.dart` (538 lignes initiales) pour
/// alleger le service principal. Toutes les fonctions sont top-level
/// pures : ni state, ni I/O, ni access a la DB. Elles prennent leurs
/// dependances en parametres et retournent un `pw.Widget` ou une
/// string formatee.
///
/// **Pourquoi top-level plutot qu'une classe** : ce sont des helpers
/// reutilisables, pas des methodes d'un meme objet. Pas de
/// composition possible entre eux (chaque fonction est independante).
/// L'absence de prefixe `Pdf` est OK car le namespace `pw.` est deja
/// importe pour le pdf package.

/// Tableau de stats 4 colonnes (Arrets / Colis / Distance / Duree)
/// avec 2 rangees principales et une optionnelle pour le cout carburant.
pw.Widget buildStatsTable({
  required int arretsTotal,
  required int livres,
  required int echecs,
  required int colisTotal,
  required int colisLivres,
  required String km,
  required String duree,
  double? coutCarburantEur,
}) {
  pw.Widget cell(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 7,
              color: PdfColors.grey700,
              letterSpacing: 0.4,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey300),
    columnWidths: const {
      0: pw.FlexColumnWidth(1),
      1: pw.FlexColumnWidth(1),
      2: pw.FlexColumnWidth(1),
      3: pw.FlexColumnWidth(1),
    },
    children: [
      pw.TableRow(
        children: [
          cell('Arrets', '$arretsTotal'),
          cell('Colis', '$colisLivres / $colisTotal'),
          cell('Distance', km),
          cell('Duree', duree),
        ],
      ),
      pw.TableRow(
        children: [
          cell('Livres', '$livres'),
          cell('Echecs', '$echecs'),
          cell('A livrer', '${arretsTotal - livres - echecs}'),
          cell('Statut', statutLabel(inferStatut(arretsTotal, livres, echecs))),
        ],
      ),
      if (coutCarburantEur != null && coutCarburantEur > 0)
        pw.TableRow(
          children: [
            cell(
              'Cout carburant',
              '${coutCarburantEur.toStringAsFixed(2).replaceAll('.', ',')} EUR',
            ),
            cell('', ''),
            cell('', ''),
            cell('', ''),
          ],
        ),
    ],
  );
}

/// Tableau de la liste des arrets : 4 colonnes (#, adresse, colis,
/// statut). En-tete grise + 1 row par stop via [buildStopRow].
pw.Widget buildStopsTable(List<Stop> stops) {
  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey300),
    columnWidths: const {
      0: pw.FixedColumnWidth(28),
      1: pw.FlexColumnWidth(3),
      2: pw.FixedColumnWidth(40),
      3: pw.FixedColumnWidth(60),
    },
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: [
          pdfTh('#'),
          pdfTh('Adresse'),
          pdfTh('Colis'),
          pdfTh('Statut'),
        ],
      ),
      for (var i = 0; i < stops.length; i++)
        buildStopRow(i + 1, stops[i]),
    ],
  );
}

/// Une ligne du tableau des arrets : numero / adresse + nom client /
/// nb colis / statut colore (vert livre, rouge echec, gris a livrer).
/// La raison d'echec est concatenee au statut entre parentheses.
pw.TableRow buildStopRow(int index, Stop stop) {
  final nom = stop.nomClient?.trim() ?? '';
  final adresse = stop.adresseNormalisee ?? stop.adresseBrute;
  final statut = statutLabel(stop.statutLivraison);
  final raison = stop.statutLivraison == 'echec' && stop.raisonEchec != null
      ? ' (${stop.raisonEchec})'
      : '';
  final color = statutColor(stop.statutLivraison);

  return pw.TableRow(
    children: [
      pdfTd(
        pw.Text(
          '$index',
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 10,
          ),
          textAlign: pw.TextAlign.center,
        ),
      ),
      pdfTd(
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (nom.isNotEmpty)
              pw.Text(
                nom,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            pw.Text(
              adresse,
              style: pw.TextStyle(
                fontSize: nom.isEmpty ? 10 : 8,
                color: nom.isEmpty ? PdfColors.black : PdfColors.grey700,
              ),
            ),
          ],
        ),
      ),
      pdfTd(
        pw.Text(
          '${stop.nbColis}',
          style: const pw.TextStyle(fontSize: 10),
          textAlign: pw.TextAlign.center,
        ),
      ),
      pdfTd(
        pw.Text(
          '$statut$raison',
          style: pw.TextStyle(
            fontSize: 9,
            color: color,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
    ],
  );
}

/// Header de tableau (gras + uppercase + petit + gris). Padding 6 px.
pw.Widget pdfTh(String text) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(6),
    child: pw.Text(
      text.toUpperCase(),
      style: pw.TextStyle(
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.grey700,
      ),
    ),
  );
}

/// Cellule de tableau standard avec padding asymetrique (6h / 4v).
pw.Widget pdfTd(pw.Widget child) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    child: child,
  );
}

/// Format duree compact pour le PDF : "3h05" ou "45min" si < 1h.
String formatPdfDuration(int totalSeconds) {
  final h = totalSeconds ~/ 3600;
  final m = (totalSeconds % 3600) ~/ 60;
  if (h == 0) return '${m}min';
  return '${h}h${m.toString().padLeft(2, '0')}';
}

/// Label lisible pour un statut (Stop ou Tournee). Majuscule pour les
/// statuts metiers (LIVRE / ECHEC) qui doivent ressortir, capitalize
/// pour les statuts d'etat de tournee.
String statutLabel(String s) => switch (s) {
      'a_livrer' => 'A livrer',
      'livre' => 'LIVRE',
      'echec' => 'ECHEC',
      'brouillon' => 'Brouillon',
      'optimisee' => 'Optimisee',
      'en_cours' => 'En cours',
      'terminee' => 'Terminee',
      _ => s,
    };

/// Statut de tournee inferé a partir du nb total / livrés / échecs.
/// Utilise dans le tableau de stats quand on ne stocke pas le statut
/// brut de la Tournee (cas exports filtres par coequipier).
String inferStatut(int total, int livres, int echecs) {
  if (total == 0) return 'brouillon';
  if (livres + echecs == total) return 'terminee';
  if (livres + echecs > 0) return 'en_cours';
  return 'optimisee';
}

/// Couleur PDF du statut d'un stop pour le rendre identifiable d'un
/// coup d'oeil dans le tableau (vert livre, rouge echec, gris autre).
PdfColor statutColor(String s) => switch (s) {
      'livre' => PdfColors.green700,
      'echec' => PdfColors.red700,
      _ => PdfColors.grey700,
    };
