import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/fec_export.dart';

void main() {
  group('FecExport (#320)', () {
    test('headers FEC 18 colonnes', () {
      expect(FecExport.headers, hasLength(18));
      expect(FecExport.headers.first, 'JournalCode');
    });

    test('toCsv : header + lignes', () {
      final entries = [
        FecEntry(
          journalCode: 'VE',
          journalLib: 'Ventes',
          ecritureNum: 'V001',
          ecritureDate: DateTime(2026, 5, 30),
          compteNum: '411000',
          compteLib: 'Clients',
          pieceRef: 'FA001',
          pieceDate: DateTime(2026, 5, 30),
          libelle: 'Livraison 12 colis',
          debit: 42.50,
        ),
        FecEntry(
          journalCode: 'VE',
          journalLib: 'Ventes',
          ecritureNum: 'V001',
          ecritureDate: DateTime(2026, 5, 30),
          compteNum: '707000',
          compteLib: 'Ventes services',
          pieceRef: 'FA001',
          pieceDate: DateTime(2026, 5, 30),
          libelle: 'Livraison 12 colis',
          credit: 42.50,
        ),
      ];
      final csv = FecExport.toCsv(entries);
      final lines = csv.trim().split('\n');
      expect(lines.length, 3);
      expect(lines[0].split('|').length, 18);
      expect(lines[1], contains('20260530'));
      expect(lines[1], contains('42,50'));
      expect(FecExport.balance(entries), 0);
    });

    test('balance != 0 si dette/credit pas equilibres', () {
      final out = FecExport.balance([
        FecEntry(
          journalCode: 'VE',
          journalLib: 'L',
          ecritureNum: 'E',
          ecritureDate: DateTime(2026, 1, 1),
          compteNum: '411',
          compteLib: 'X',
          pieceRef: 'P',
          pieceDate: DateTime(2026, 1, 1),
          libelle: 'l',
          debit: 100,
        ),
      ]);
      expect(out, 100);
    });
  });
}
