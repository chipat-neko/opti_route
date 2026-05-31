// Wrapper conditionnel pour `navigator.storage.persist()` (Web only).
// Sur les autres plateformes, no-op qui retourne true.
//
// Usage depuis main.dart :
//   unawaited(requestPersistentStorage());
export 'persist_storage_stub.dart'
    if (dart.library.js_interop) 'persist_storage_web.dart';
