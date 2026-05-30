/// Export FEC (Fichier des Ecritures Comptables) format URSSAF /
/// expert-comptable. Carte #320. Pure fn.
///
/// Format simplifié 18 colonnes obligatoires (cf BOI-CF-IOR-60-40-20),
/// avec séparateur `|` (tab impossible côté Drift sans helper),
/// encodage UTF-8.
class FecExport {
  FecExport._();

  static const List<String> headers = [
    'JournalCode',
    'JournalLib',
    'EcritureNum',
    'EcritureDate',
    'CompteNum',
    'CompteLib',
    'CompAuxNum',
    'CompAuxLib',
    'PieceRef',
    'PieceDate',
    'EcritureLib',
    'Debit',
    'Credit',
    'EcritureLet',
    'DateLet',
    'ValidDate',
    'Montantdevise',
    'Idevise',
  ];

  /// Convertit une liste d'écritures en CSV FEC valide. Le caller
  /// fournit les écritures déjà calculées depuis les COD/factures.
  static String toCsv(List<FecEntry> entries) {
    final buf = StringBuffer()
      ..writeln(headers.join('|'));
    for (final e in entries) {
      buf.writeln(e.asRow().join('|'));
    }
    return buf.toString();
  }

  /// Cumul des Débit - Crédit. Le total doit etre 0 pour un FEC
  /// équilibré (chaque écriture débit a une contrepartie crédit).
  static double balance(List<FecEntry> entries) {
    var d = 0.0;
    var c = 0.0;
    for (final e in entries) {
      d += e.debit;
      c += e.credit;
    }
    return d - c;
  }
}

class FecEntry {
  const FecEntry({
    required this.journalCode,
    required this.journalLib,
    required this.ecritureNum,
    required this.ecritureDate,
    required this.compteNum,
    required this.compteLib,
    required this.pieceRef,
    required this.pieceDate,
    required this.libelle,
    this.debit = 0,
    this.credit = 0,
  });

  final String journalCode;
  final String journalLib;
  final String ecritureNum;
  final DateTime ecritureDate;
  final String compteNum;
  final String compteLib;
  final String pieceRef;
  final DateTime pieceDate;
  final String libelle;
  final double debit;
  final double credit;

  List<String> asRow() => [
        journalCode,
        journalLib,
        ecritureNum,
        _fmt(ecritureDate),
        compteNum,
        compteLib,
        '', // CompAuxNum
        '', // CompAuxLib
        pieceRef,
        _fmt(pieceDate),
        libelle,
        _money(debit),
        _money(credit),
        '', // EcritureLet
        '', // DateLet
        _fmt(ecritureDate), // ValidDate
        '0,00',
        'EUR',
      ];

  static String _fmt(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

  static String _money(double v) {
    final cents = (v * 100).round();
    final entier = cents ~/ 100;
    final dec = (cents % 100).abs().toString().padLeft(2, '0');
    return '$entier,$dec';
  }
}
