import 'dart:js_interop';

/// Bindings minimaux pour `navigator.storage.persist()` (Web Storage API).
@JS('navigator.storage.persist')
external JSPromise<JSBoolean> _persistJs();

/// Demande au navigateur de marquer le stockage comme persistant
/// (IndexedDB, Drift WASM, Cache API). Sans ce flag, le navigateur peut
/// evincer les donnees sous pression de quota (mode best-effort).
///
/// QW10 audit #340 (2026-05-31) : sans cet appel, IndexedDB Drift peut
/// etre purgee silencieusement → perte totale des tournees/carnet
/// d'un user PWA sans avertissement.
///
/// Retourne true si la persistance est accordee, false sinon (user a
/// refuse, navigateur non-conforme, etc.). Idempotent : appeler 2x ne
/// fait pas de mal.
Future<bool> requestPersistentStorage() async {
  try {
    final js = _persistJs();
    final result = await js.toDart;
    return result.toDart;
  } catch (_) {
    // navigator.storage.persist() pas dispo (Safari iOS <16.4 par ex)
    // ou bloque par les reglages. Best-effort.
    return false;
  }
}
