import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/batch_scan_commit_service.dart';

// Tests directs des data classes BatchScanItem + BatchCommitSummary
// (sans I/O DB). Verrouille les defauts + getter total.
void main() {
  group('BatchScanItem — defauts', () {
    test('adresse seule : nbColis=1, isEnlevement=false, nomClient/lat/lng null',
        () {
      const item = BatchScanItem(adresse: '12 rue X');
      expect(item.adresse, '12 rue X');
      expect(item.nbColis, 1);
      expect(item.isEnlevement, isFalse);
      expect(item.nomClient, isNull);
      expect(item.lat, isNull);
      expect(item.lng, isNull);
    });

    test('isEnlevement true preserve', () {
      const item = BatchScanItem(adresse: 'X', isEnlevement: true);
      expect(item.isEnlevement, isTrue);
    });

    test('nbColis custom', () {
      const item = BatchScanItem(adresse: 'X', nbColis: 7);
      expect(item.nbColis, 7);
    });

    test('coords fournies', () {
      const item = BatchScanItem(
        adresse: 'X',
        lat: 48.5,
        lng: 1.5,
      );
      expect(item.lat, 48.5);
      expect(item.lng, 1.5);
    });

    test('nomClient fourni', () {
      const item = BatchScanItem(adresse: 'X', nomClient: 'Garage X');
      expect(item.nomClient, 'Garage X');
    });
  });

  group('BatchCommitSummary — total', () {
    test('total = crees + doublons', () {
      const s = BatchCommitSummary(crees: 3, doublons: 2);
      expect(s.total, 5);
    });

    test('total 0 si tout vide', () {
      const s = BatchCommitSummary(crees: 0, doublons: 0);
      expect(s.total, 0);
    });

    test('total avec seulement crees', () {
      const s = BatchCommitSummary(crees: 10, doublons: 0);
      expect(s.total, 10);
    });

    test('total avec seulement doublons', () {
      const s = BatchCommitSummary(crees: 0, doublons: 5);
      expect(s.total, 5);
    });
  });
}
