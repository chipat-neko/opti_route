import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/address_suggestion.dart';
import 'package:opti_route/data/ban_geocoding_service.dart';
import 'package:opti_route/data/france_geocoding_service.dart';
import 'package:opti_route/data/geocoding_service.dart';
import 'package:opti_route/data/photon_service.dart';
import 'package:opti_route/data/recherche_entreprises_service.dart';

void main() {
  group('FranceGeocodingService.search - cascade 2 etages', () {
    test('query adresse avec hit BAN precis : BAN seul appele '
        '(economie de quota)', () async {
      // Cascade 2026-06-11 : si BAN retourne un hit precis (numero de
      // rue), Photon et SIRENE ne sont pas consultes du tout.
      final ban = _StubBan(returns: [_precise('12 rue X')]);
      final entr = _StubEntreprises(returns: [_poi('Marque')]);
      final photon = _StubPhoton(returns: [_poi('OSM Result')]);
      final svc = FranceGeocodingService(
        ban: ban,
        entreprises: entr,
        photon: photon,
      );
      final r = await svc.search('12 rue X');
      expect(ban.called, isTrue);
      expect(photon.called, isFalse);
      expect(entr.called, isFalse);
      expect(r.first.houseNumber, '12');
    });

    test('query adresse sans hit BAN precis : fallback Photon + SIRENE',
        () async {
      final ban = _StubBan(returns: [_imprecise('rue X', lat: 47.0)]);
      final entr = _StubEntreprises(returns: [_poi('Marque', lat: 48.5)]);
      final photon = _StubPhoton(returns: [_poi('OSM Result', lat: 49.0)]);
      final svc = FranceGeocodingService(
        ban: ban,
        entreprises: entr,
        photon: photon,
      );
      final r = await svc.search('12 rue X');
      expect(ban.called, isTrue);
      expect(photon.called, isTrue);
      expect(entr.called, isTrue);
      // BAN reste en tete (ordre de pertinence adresse), puis Photon.
      expect(r, hasLength(3));
      expect(r.first.road, 'rue X');
    });

    test('query nom d\'entreprise : SIRENE + Photon, BAN pas appele '
        'quand un hit precis existe', () async {
      final ban = _StubBan(returns: [_imprecise('rue Carrefour')]);
      final entr = _StubEntreprises(returns: [_poi('Carrefour Dreux')]);
      final photon = _StubPhoton(returns: [_poi('Carrefour OSM')]);
      final svc = FranceGeocodingService(
        ban: ban,
        entreprises: entr,
        photon: photon,
      );
      final r = await svc.search('Carrefour Dreux');
      expect(entr.called, isTrue);
      expect(photon.called, isTrue);
      expect(ban.called, isFalse);
      // SIRENE en 1er pour les noms d'entreprise.
      expect(r.first.poiName, 'Carrefour Dreux');
    });

    test('query nom sans hit precis : BAN appele en secours', () async {
      final ban = _StubBan(returns: [_imprecise('rue Carrefour')]);
      final entr = _StubEntreprises();
      final photon = _StubPhoton();
      final svc = FranceGeocodingService(
        ban: ban,
        entreprises: entr,
        photon: photon,
      );
      final r = await svc.search('Carrefour Dreux');
      expect(entr.called, isTrue);
      expect(photon.called, isTrue);
      expect(ban.called, isTrue);
      expect(r, hasLength(1));
      expect(r.first.road, 'rue Carrefour');
    });

    test('agregation et dedupe par coords arrondies', () async {
      final ban = _StubBan(returns: [_imprecise('rue X', lat: 48.0, lon: 1.0)]);
      final photon = _StubPhoton(
        returns: [_poi('Magasin Y', lat: 48.5, lon: 1.5)],
      );
      final entr = _StubEntreprises();
      final svc = FranceGeocodingService(
        ban: ban,
        entreprises: entr,
        photon: photon,
      );
      final r = await svc.search('14 rue X');
      // 2 resultats distincts agreges (coords differentes -> pas dedup)
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

    test('providerKey vaut "france"', () {
      final svc = FranceGeocodingService(
        ban: _StubBan(),
        entreprises: _StubEntreprises(),
        photon: _StubPhoton(),
      );
      expect(svc.providerKey, 'france');
    });

    test('un seul resultat : retourne tel quel sans dedup', () async {
      final ban = _StubBan(returns: [_precise('12 rue X')]);
      final entr = _StubEntreprises();
      final photon = _StubPhoton();
      final svc = FranceGeocodingService(
        ban: ban,
        entreprises: entr,
        photon: photon,
      );
      final r = await svc.search('12 rue X');
      expect(r, hasLength(1));
      expect(r.first.houseNumber, '12');
    });

    test('close() ferme toutes les sources', () {
      final ban = _StubBan();
      final entr = _StubEntreprises();
      final photon = _StubPhoton();
      // Les stubs ont des close() no-op, on verifie juste qu'aucune
      // exception ne remonte de la cascade.
      final svc = FranceGeocodingService(
        ban: ban,
        entreprises: entr,
        photon: photon,
      );
      expect(() => svc.close(), returnsNormally);
    });

    test('une source echoue : les autres sont quand meme retournees',
        () async {
      // En parallel mode, un echec ne stoppe pas les autres.
      final ban = _StubBan(returns: const []);
      final photon = _StubPhoton(throwsError: true);
      final entr = _StubEntreprises(returns: [_poi('Final POI')]);
      final svc = FranceGeocodingService(
        ban: ban,
        entreprises: entr,
        photon: photon,
      );
      final r = await svc.search('12 rue X');
      expect(ban.called, isTrue);
      expect(photon.called, isTrue);
      expect(entr.called, isTrue);
      expect(r, hasLength(1));
      expect(r.first.poiName, 'Final POI');
    });

    test('dedupe par lat/lon arrondis a 5 decimales', () async {
      // 48.123451 et 48.123452 arrondissent toutes les 2 a "48.12345"
      // a 5 decimales (toStringAsFixed(5)).
      final ban = _StubBan(returns: [
        _imprecise('A', lat: 48.123451, lon: 1.0),
        _imprecise('B', lat: 48.123452, lon: 1.0), // duplique apres arrondi
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
      // 2 dans BAN -> 1 apres dedup
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

AddressSuggestion _poi(String name, {double lat = 48.0, double lon = 1.0}) =>
    AddressSuggestion(
      displayName: name,
      lat: lat,
      lon: lon,
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
