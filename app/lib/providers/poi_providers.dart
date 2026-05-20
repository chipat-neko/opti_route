import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/overpass_poi_service.dart';

/// Provider singleton du [OverpassPoiService] (Sprint 2B Spoke
/// parity). Un seul http.Client partage entre les recherches, cleanup
/// auto via `ref.onDispose`.
///
/// Pas autoDispose : l'http.Client interne survit entre les
/// ouvertures de l'ecran POI pour reutiliser les connexions
/// keep-alive vers overpass-api.de.
final overpassPoiServiceProvider = Provider<OverpassPoiService>((ref) {
  final svc = OverpassPoiService();
  ref.onDispose(svc.close);
  return svc;
});
