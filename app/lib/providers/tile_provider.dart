import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cached_tile_provider.dart';

/// `CachedTileProvider` partage entre les ecrans qui ont une carte
/// (`CarteScreen`, `PointerCarteScreen`). Singleton via Riverpod pour
/// que les tuiles deja en cache soient instant a charger depuis n'importe
/// quel ecran.
final cachedTileProviderInstance = Provider<CachedTileProvider>((ref) {
  return CachedTileProvider();
});
