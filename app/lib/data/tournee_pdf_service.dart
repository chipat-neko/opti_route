import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import 'database.dart';

/// Service de generation de PDF recap d'une tournee. Sortie : fichier
/// dans le repertoire temporaire + partage via le selecteur natif
/// Android (`share_plus`). Tout est genere localement, aucune API
/// externe.
class TourneePdfService {
  /// Genere le PDF, le sauve dans un fichier temporaire, et lance le
  /// partage. Retourne le chemin du fichier genere.
  ///
  /// [coutCarburantEur] : si fourni, ajoute une ligne "Cout carburant"
  /// dans le tableau de stats. Calcule en amont via
  /// `ParametresRepository.estimerCoutCarburant`.
  Future<String> exportAndShare({
    required Tournee tournee,
    required List<Stop> stops,
    double? coutCarburantEur,
    String? entrepriseNom,
    String? entrepriseSiret,
    String? entrepriseSlogan,
    /// Si fourni, le PDF aura un sous-titre `Fiche de <nom>` pour
    /// distinguer visuellement les fiches d'un PDF d'equipe.
    String? coequipierNom,
  }) async {
    final pdf = await _buildDocument(
      tournee: tournee,
      stops: stops,
      coutCarburantEur: coutCarburantEur,
      entrepriseNom: entrepriseNom,
      entrepriseSiret: entrepriseSiret,
      entrepriseSlogan: entrepriseSlogan,
      coequipierNom: coequipierNom,
    );
    final dir = await getTemporaryDirectory();
    final dateStr = DateFormat('yyyy-MM-dd').format(tournee.date);
    final safeNom = tournee.nom
        .replaceAll(RegExp(r'[^a-zA-Z0-9 _-]'), '')
        .trim();
    final file =
        File('${dir.path}/tournee-$dateStr-${safeNom.replaceAll(" ", "_")}.pdf');
    await file.writeAsBytes(await pdf.save());

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'Tournee ${tournee.nom}',
        text:
            'Recap de la tournee "${tournee.nom}" du '
            '${DateFormat('dd/MM/yyyy', 'fr').format(tournee.date)}.',
      ),
    );

    return file.path;
  }

  /// Genere un PDF cible pour UN coequipier (filtre uniquement ses
  /// stops affectes) + share natif. Sert au chef d'equipe qui veut
  /// distribuer une fiche papier individuelle.
  ///
  /// [coequipierIdOrNull] : null = filtre les stops sans affectation
  /// (= ceux de Noah lui-meme).
  Future<String> exportForCoequipier({
    required Tournee tournee,
    required List<Stop> allStops,
    required int? coequipierIdOrNull,
    required String coequipierNom,
    double? coutCarburantEur,
    String? entrepriseNom,
    String? entrepriseSiret,
    String? entrepriseSlogan,
  }) async {
    final filtered = allStops
        .where((s) => s.coequipierId == coequipierIdOrNull)
        .toList(growable: false);
    final pdf = await _buildDocument(
      tournee: tournee,
      stops: filtered,
      coutCarburantEur: coutCarburantEur,
      entrepriseNom: entrepriseNom,
      entrepriseSiret: entrepriseSiret,
      entrepriseSlogan: entrepriseSlogan,
      coequipierNom: coequipierNom,
    );
    final dir = await getTemporaryDirectory();
    final dateStr = DateFormat('yyyy-MM-dd').format(tournee.date);
    final safeNom = tournee.nom
        .replaceAll(RegExp(r'[^a-zA-Z0-9 _-]'), '')
        .trim();
    final safeCo = coequipierNom
        .replaceAll(RegExp(r'[^a-zA-Z0-9 _-]'), '')
        .trim()
        .replaceAll(' ', '_');
    final file = File(
      '${dir.path}/tournee-$dateStr-${safeNom.replaceAll(" ", "_")}'
      '-$safeCo.pdf',
    );
    await file.writeAsBytes(await pdf.save());

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'Fiche ${tournee.nom} - $coequipierNom',
        text:
            'Fiche de $coequipierNom pour la tournee "${tournee.nom}" '
            'du ${DateFormat('dd/MM/yyyy', 'fr').format(tournee.date)}.',
      ),
    );

    return file.path;
  }

  Future<pw.Document> _buildDocument({
    required Tournee tournee,
    required List<Stop> stops,
    double? coutCarburantEur,
    String? entrepriseNom,
    String? entrepriseSiret,
    String? entrepriseSlogan,
    String? coequipierNom,
  }) async {
    final pdf = pw.Document(
      title: 'Tournee ${tournee.nom}',
      author: entrepriseNom ?? 'opti_route',
    );
    final dateFmt = DateFormat('EEEE d MMMM y', 'fr');

    final livres = stops.where((s) => s.statutLivraison == 'livre').length;
    final echecs = stops.where((s) => s.statutLivraison == 'echec').length;
    final colisTotal = stops.fold<int>(0, (sum, s) => sum + s.nbColis);
    final colisLivres = stops
        .where((s) => s.statutLivraison == 'livre')
        .fold<int>(0, (sum, s) => sum + s.nbColis);
    final km = tournee.distanceTotaleM == null
        ? '—'
        : '${(tournee.distanceTotaleM! / 1000).toStringAsFixed(1)} km';
    final dur = tournee.dureeTotaleS == null
        ? '—'
        : _formatDuration(tournee.dureeTotaleS!);

    final hasEntreprise = (entrepriseNom != null && entrepriseNom.isNotEmpty);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.copyWith(
          marginTop: 18 * PdfPageFormat.mm,
          marginBottom: 18 * PdfPageFormat.mm,
          marginLeft: 16 * PdfPageFormat.mm,
          marginRight: 16 * PdfPageFormat.mm,
        ),
        // Footer entreprise (visible sur chaque page) : nom +
        // mentions legales SIRET + slogan. Affichage discret pour ne
        // pas voler la place au contenu metier.
        footer: hasEntreprise
            ? (context) => pw.Container(
                  margin: const pw.EdgeInsets.only(top: 8),
                  padding: const pw.EdgeInsets.only(top: 4),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      top: pw.BorderSide(
                        color: PdfColors.grey400,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            entrepriseNom,
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey800,
                            ),
                          ),
                          if (entrepriseSiret != null &&
                              entrepriseSiret.isNotEmpty)
                            pw.Text(
                              'SIRET $entrepriseSiret',
                              style: const pw.TextStyle(
                                fontSize: 7,
                                color: PdfColors.grey600,
                              ),
                            ),
                          if (entrepriseSlogan != null &&
                              entrepriseSlogan.isNotEmpty)
                            pw.Text(
                              entrepriseSlogan,
                              style: pw.TextStyle(
                                fontSize: 7,
                                color: PdfColors.grey600,
                                fontStyle: pw.FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                      pw.Text(
                        'Page ${context.pageNumber} / ${context.pagesCount}',
                        style: const pw.TextStyle(
                          fontSize: 7,
                          color: PdfColors.grey500,
                        ),
                      ),
                    ],
                  ),
                )
            : null,
        build: (context) => [
          // Header
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.green700, width: 2),
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  tournee.nom,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green700,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  dateFmt.format(tournee.date).toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                    letterSpacing: 0.6,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'Depart : ${tournee.pointDepartLabel}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                if (coequipierNom != null && coequipierNom.isNotEmpty) ...[
                  pw.SizedBox(height: 6),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.lime300,
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(4),
                      ),
                    ),
                    child: pw.Text(
                      'FICHE DE $coequipierNom',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          // Stats row
          _statsTable(
            arretsTotal: stops.length,
            livres: livres,
            echecs: echecs,
            colisTotal: colisTotal,
            colisLivres: colisLivres,
            km: km,
            duree: dur,
            coutCarburantEur: coutCarburantEur,
          ),
          pw.SizedBox(height: 18),
          // Liste des arrets
          pw.Text(
            'Arrets',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 8),
          _stopsTable(stops),
          pw.SizedBox(height: 16),
          pw.Text(
            'Genere par opti_route le ${DateFormat('dd/MM/yyyy a HH:mm', 'fr').format(DateTime.now())}.',
            style: pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey600,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _statsTable({
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
            cell('Statut', _statutLabel(_inferStatut(arretsTotal, livres, echecs))),
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

  pw.Widget _stopsTable(List<Stop> stops) {
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
            _th('#'),
            _th('Adresse'),
            _th('Colis'),
            _th('Statut'),
          ],
        ),
        for (var i = 0; i < stops.length; i++)
          _stopRow(i + 1, stops[i]),
      ],
    );
  }

  pw.TableRow _stopRow(int index, Stop stop) {
    final nom = stop.nomClient?.trim() ?? '';
    final adresse = stop.adresseNormalisee ?? stop.adresseBrute;
    final statut = _statutLabel(stop.statutLivraison);
    final raison = stop.statutLivraison == 'echec' && stop.raisonEchec != null
        ? ' (${stop.raisonEchec})'
        : '';
    final color = _statutColor(stop.statutLivraison);

    return pw.TableRow(
      children: [
        _td(
          pw.Text(
            '$index',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ),
        _td(
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
        _td(
          pw.Text(
            '${stop.nbColis}',
            style: const pw.TextStyle(fontSize: 10),
            textAlign: pw.TextAlign.center,
          ),
        ),
        _td(
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

  pw.Widget _th(String text) {
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

  pw.Widget _td(pw.Widget child) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: child,
    );
  }

  static String _formatDuration(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    if (h == 0) return '${m}min';
    return '${h}h${m.toString().padLeft(2, '0')}';
  }

  static String _statutLabel(String s) => switch (s) {
        'a_livrer' => 'A livrer',
        'livre' => 'LIVRE',
        'echec' => 'ECHEC',
        'brouillon' => 'Brouillon',
        'optimisee' => 'Optimisee',
        'en_cours' => 'En cours',
        'terminee' => 'Terminee',
        _ => s,
      };

  static String _inferStatut(int total, int livres, int echecs) {
    if (total == 0) return 'brouillon';
    if (livres + echecs == total) return 'terminee';
    if (livres + echecs > 0) return 'en_cours';
    return 'optimisee';
  }

  static PdfColor _statutColor(String s) => switch (s) {
        'livre' => PdfColors.green700,
        'echec' => PdfColors.red700,
        _ => PdfColors.grey700,
      };
}
