import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import 'database.dart';
import 'saved_destinations_repository.dart';

/// Genere un PDF "annuaire" du carnet d'adresses : tableau trie
/// alphabetiquement (par nom client si present, sinon par adresse),
/// avec favoris en haut, et partage via le selecteur natif Android.
class CarnetPdfService {
  CarnetPdfService(this._repo);

  final SavedDestinationsRepository _repo;

  /// Genere, sauve dans un fichier temporaire, et partage. Retourne
  /// le nombre d'entrees exportees.
  Future<int> exportAndShare() async {
    final all = await _repo.watchAll().first;
    final pdf = await _buildDocument(all);
    final dir = await getTemporaryDirectory();
    final stamp =
        DateTime.now().toIso8601String().split('.').first.replaceAll(':', '-');
    final file = File('${dir.path}/carnet-opti-route-$stamp.pdf');
    await file.writeAsBytes(await pdf.save());

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'Carnet d\'adresses opti_route',
        text:
            'Annuaire client opti_route : ${all.length} entree(s), '
            'export au ${DateFormat('dd/MM/yyyy', 'fr').format(DateTime.now())}.',
      ),
    );

    return all.length;
  }

  Future<pw.Document> _buildDocument(List<SavedDestination> all) async {
    final pdf = pw.Document(
      title: 'Carnet opti_route',
      author: 'opti_route',
    );
    final sorted = _sortFavorisFirstThenAlpha(all);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.copyWith(
          marginTop: 18 * PdfPageFormat.mm,
          marginBottom: 18 * PdfPageFormat.mm,
          marginLeft: 16 * PdfPageFormat.mm,
          marginRight: 16 * PdfPageFormat.mm,
        ),
        header: (context) => context.pageNumber == 1
            ? pw.SizedBox.shrink()
            : _runningHeader(),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 8),
          child: pw.Text(
            'Page ${context.pageNumber} / ${context.pagesCount}',
            style: pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey600,
            ),
          ),
        ),
        build: (context) => [
          _coverHeader(all.length),
          pw.SizedBox(height: 18),
          if (sorted.isEmpty)
            pw.Text(
              'Carnet vide.',
              style: pw.TextStyle(
                fontSize: 12,
                fontStyle: pw.FontStyle.italic,
                color: PdfColors.grey600,
              ),
            )
          else
            _entriesTable(sorted),
          pw.SizedBox(height: 14),
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

  pw.Widget _coverHeader(int count) {
    return pw.Container(
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
            'Carnet d\'adresses',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green700,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'opti_route — $count entree(s)',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _runningHeader() {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        'Carnet d\'adresses opti_route',
        style: pw.TextStyle(
          fontSize: 9,
          color: PdfColors.grey600,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  pw.Widget _entriesTable(List<SavedDestination> entries) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: const {
        0: pw.FixedColumnWidth(12),
        1: pw.FlexColumnWidth(4),
        2: pw.FixedColumnWidth(48),
        3: pw.FixedColumnWidth(60),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _th(''),
            _th('Nom / Adresse'),
            _th('Utilisations'),
            _th('Derniere visite'),
          ],
        ),
        for (final e in entries) _entryRow(e),
      ],
    );
  }

  pw.TableRow _entryRow(SavedDestination e) {
    final nom = (e.nomClient ?? '').trim();
    final adresse = e.adresseDisplay;
    final last = DateFormat('dd/MM/yyyy', 'fr').format(e.lastUsedAt);

    return pw.TableRow(
      children: [
        _td(
          pw.Text(
            e.isFavori ? '*' : '',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.amber800,
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
            '${e.useCount}',
            style: const pw.TextStyle(fontSize: 10),
            textAlign: pw.TextAlign.center,
          ),
        ),
        _td(
          pw.Text(
            last,
            style: const pw.TextStyle(fontSize: 9),
            textAlign: pw.TextAlign.center,
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

  /// Favoris en haut (epingles), reste trie alphabetiquement par nom
  /// client (si present), sinon par adresse. Normalisation Unicode pour
  /// que les accents ne perturbent pas le tri.
  static List<SavedDestination> _sortFavorisFirstThenAlpha(
    List<SavedDestination> all,
  ) {
    String key(SavedDestination d) {
      final s = (d.nomClient?.trim().isNotEmpty == true
              ? d.nomClient!.trim()
              : d.adresseDisplay)
          .toLowerCase();
      return _stripAccents(s);
    }

    final favoris = all.where((e) => e.isFavori).toList()
      ..sort((a, b) => key(a).compareTo(key(b)));
    final others = all.where((e) => !e.isFavori).toList()
      ..sort((a, b) => key(a).compareTo(key(b)));
    return [...favoris, ...others];
  }

  static String _stripAccents(String s) {
    const a = 'àâäáãåçéèêëíìîïñóòôöõùúûüýÿ';
    const b = 'aaaaaaceeeeiiiinooooouuuuyy';
    var out = s;
    for (var i = 0; i < a.length; i++) {
      out = out.replaceAll(a[i], b[i]);
    }
    return out;
  }
}
