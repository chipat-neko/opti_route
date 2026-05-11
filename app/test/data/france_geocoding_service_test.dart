import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/address_suggestion.dart';
import 'package:opti_route/data/ban_geocoding_service.dart';
import 'package:opti_route/data/france_geocoding_service.dart';
import 'package:opti_route/data/geocoding_service.dart';
import 'package:opti_route/data/photon_service.dart';
import 'package:opti_route/data/recherche_entreprises_service.dart';

void main() {
  group('FranceGeocodingService.search - ordre des sources', () {
    test('query commence par un nombre (adresse) : ordre BAN, Photon, '
        'SIRENE et arret precoce sur BAN si numero', () async {
      final ban = _StubBan(returns: [_precise('12 rue X')]);
      final entr = _StubEntreprises();
      final photon = _StubPhoton();
      final svc = FranceGeocodingService(
        ban: ban,
        entreprises: entr,
        photon: photon,
      );
      await svc.search('12 rue X');
      expect(ban.called, isTrue);
      // Adresse precise -> on s'arrete a BAN, les autres ne sont pas
      // sollicites.
      expect(photon.called, isFalse);
      expect(entr.called, isFalse);
    });

    test('query nom d\'entreprise : ordre SIRENE, Photon, BAN', () async {
      final ban = _StubBan();
      final entr = _StubEntreprises(returns: [_poi('Carrefour Dreux')]);
      final photon = _StubPhoton();
      final svc = FranceGeocodingService(
        ban: ban,
        entreprises: entr,
        photon: photon,
      );
      await svc.search('Carrefour Dreux');
      expect(entr.called, isTrue);
      // POI precis -> on s'arrete a SIRENE
      expect(photon.called, isFalse);
      expect(ban.called, isFalse);
    });

    test('source 1 sans resultat precis : tente la 2eme + 3eme + dedupe',
        () async {
      // BAN renvoie une rue sans numero (non precise)
      final ban = _StubBan(returns: [_imprecise('rue X')]);
      final photon = _StubPhoton(returns: [_poi('Magasin Y')]);
      final entr = _StubEntreprises();
      final svc = FranceGeocodingService(
        ban: ban,
        entreprises: entr,
        photon: photon,
      );
      // Query "14 rue X" -> ordre BAN, Photon, SIRENE
      final r = await svc.search('14 rue X');
      expect(ban.called, isTrue);
      expect(photon.called, isTrue);
      // POI precis sur Photon -> arret avant SIRENE
      expect(entr.called, isFalse);
      // Resultat agrege
      expect(r.length, 2);
    });

    test('toutes les sources echouent : retourne []', () async {
      final ban = _StubBan(throwsError: true);
      final photon = _StubPhoton(throwsError: true);
      final entr = _StubEntreprises(throwsError: true);
      final svc = FranceGeocodingService(
        ban: ban,
        entreprises: entr,
        photon: photon,
      );
      final r = await svc.search('test');
      expect(r, isEmpty);
    });

    test('dedupe par lat/lon arrondis a 5 decimales', () async {
      final ban = _StubBan(returns: [
        _imprecise('A', lat: 48.12345, lon: 1.0),
        _imprecise('B', lat: 48.123456789, lon: 1.0), // duplique
      ]);
      final photon = _StubPhoton();
      final entr = _StubEntreprises();
      final svc = FranceGeocodingService(
        ban: ban,
        entreprises: entr,
        photon: photon,
      );
      // Query adresse mais BAN ne renvoie pas de hit precis -> on devrait
      // continuer + dedupe.
      final r = await svc.search('14 quelconque');
      // 2 dans BAN -> 1 apres dedup (meme lat 48.12345)
      expect(r.length, 1);
    });
  });
}

AddressSuggestion _precise(String label) => AddressSuggestion(
      displayName: label,
      lat: 48.0,
      lon: 1.0,
      road: label,
      houseNumber: '12',
    );

AddressSuggestion _imprecise(String label, {double lat = 48.0, double lon = 1.0}) =>
    AddressSuggestion(displayName: label, lat: lat, lon: lon, road: label);

AddressSuggestion _poi(String name) => AddressSuggestion(
      displayName: name,
      lat: 48.0,
      lon: 1.0,
      poiName: name,
    );

class _StubBan implements BanGeocodingService {
  _StubBan({this.returns = const [], this.throwsError = false});
  final List<AddressSuggestion> returns;
  final bool throwsError;
  bool called = false;

  @override
  String get providerKey => 'ban';

  @override
  Future<List<AddressSuggestion>> search(String q,
      {int limit = 10, String acceptLanguage = 'fr-FR'}) async {
    called = true;
    if (throwsError) throw const GeocodingException('stub');
    return returns;
  }

  @override
  Future<AddressSuggestion?> reverseGeocode({
    required double lat,
    required double lng,
  }) async {
    throw UnimplementedError();
  }

  @override
  void close() {}
}

class _StubEntreprises implements RechercheEntreprisesService {
  _StubEntreprises({this.returns = const [], this.throwsError = false});
  final List<AddressSuggestion> returns;
  final bool throwsError;
  bool called = false;

  @override
  String get providerKey => 'sirene';

  @override
  Future<List<AddressSuggestion>> search(String q,
      {int limit = 10, String acceptLanguage = 'fr-FR'}) async {
    called = true;
    if (throwsError) throw const GeocodingException('stub');
    return returns;
  }

  @override
  void close() {}
}

class _StubPhoton implements PhotonService {
  _StubPhoton({this.returns = const [], this.throwsError = false});
  final List<AddressSuggestion> returns;
  final bool throwsError;
  bool called = false;

  @override
  String get providerKey => 'photon';

  @override
  Future<List<AddressSuggestion>> search(String q,
      {int limit = 10, String acceptLanguage = 'fr'}) async {
    called = true;
    if (throwsError) throw const GeocodingException('stub');
    return returns;
  }

  @override
  void close() {}
}
