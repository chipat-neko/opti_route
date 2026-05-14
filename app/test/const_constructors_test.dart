import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/address_suggestion.dart';
import 'package:opti_route/data/bordereau_extraction.dart';
import 'package:opti_route/data/client_stats_service.dart';
import 'package:opti_route/data/geocoding_service.dart';
import 'package:opti_route/data/location_service.dart';
import 'package:opti_route/data/ocr_service.dart';
import 'package:opti_route/data/optimization_service.dart';
import 'package:opti_route/data/stops_geocode_retry_service.dart';
import 'package:opti_route/widgets/stop_action_sheet.dart';

/// Tests qui verifient que les models immuables exposent bien des
/// constructeurs `const`. Si quelqu'un retire le `const` d'un model,
/// ces tests cassent — c'est un canary contre les regressions de
/// performances Flutter (qui optimise les const widgets dans son tree).
void main() {
  group('const constructors', () {
    test('AddressSuggestion', () {
      const s = AddressSuggestion(
        displayName: 'A',
        lat: 48,
        lon: 1,
      );
      expect(s, isA<AddressSuggestion>());
    });

    test('BordereauExtraction', () {
      const e = BordereauExtraction();
      expect(e, isA<BordereauExtraction>());
    });

    test('OcrResult', () {
      const r = OcrResult(fullText: '', lines: []);
      expect(r, isA<OcrResult>());
    });

    test('OptimizationResult', () {
      const r = OptimizationResult(
        orderedStopIds: [],
        totalDistanceMeters: 0,
        totalDurationSeconds: 0,
      );
      expect(r, isA<OptimizationResult>());
    });

    test('OptimizationException', () {
      const e = OptimizationException('msg');
      expect(e, isA<OptimizationException>());
    });

    test('GeocodingException', () {
      const e = GeocodingException('msg');
      expect(e, isA<GeocodingException>());
    });

    test('LocationPermissionDenied', () {
      const e = LocationPermissionDenied('msg');
      expect(e, isA<LocationPermissionDenied>());
    });

    test('BatchGeocodeResult', () {
      const r = BatchGeocodeResult(
        totalCandidats: 0,
        resolved: [],
        unresolved: [],
      );
      expect(r, isA<BatchGeocodeResult>());
    });

    test('ClientStats', () {
      const s = ClientStats(
        nbLivraisons: 0,
        nbEchecs: 0,
        derniereLivraison: null,
        raisonsEchecCourantes: [],
      );
      expect(s, isA<ClientStats>());
    });

    test('MarkLivreAction', () {
      const a = MarkLivreAction();
      expect(a, isA<StopAction>());
    });

    test('MarkEchecAction', () {
      const a = MarkEchecAction('absent');
      expect(a, isA<StopAction>());
    });

    test('MarkAaLivrerAction', () {
      const a = MarkAaLivrerAction();
      expect(a, isA<StopAction>());
    });

    test('OpenDetailsAction', () {
      const a = OpenDetailsAction();
      expect(a, isA<StopAction>());
    });
  });

  group('Sealed types - exhaustivite StopAction', () {
    /// Ce switch verifie qu'on couvre bien les 6 sous-types. Si on ajoute
    /// un 7e sous-type a StopAction, Dart fait echouer la compilation
    /// jusqu'a ce qu'on l'ajoute ici aussi (sealed -> switch exhaustif).
    test('switch exhaustif sur les 6 actions', () {
      String label(StopAction a) => switch (a) {
            MarkLivreAction() => 'livre',
            MarkEchecAction() => 'echec',
            MarkAaLivrerAction() => 'a_livrer',
            OpenDetailsAction() => 'details',
            TakePreuvePhotoAction() => 'preuve_photo',
            MoveToTourneeAction() => 'move',
          };

      expect(label(const MarkLivreAction()), 'livre');
      expect(label(const MarkEchecAction('absent')), 'echec');
      expect(label(const MarkAaLivrerAction()), 'a_livrer');
      expect(label(const OpenDetailsAction()), 'details');
      expect(label(const TakePreuvePhotoAction()), 'preuve_photo');
      expect(label(const MoveToTourneeAction(42)), 'move');
    });
  });
}
