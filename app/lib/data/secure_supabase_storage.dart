import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Stockage CHIFFRE de la session Supabase (audit #179).
///
/// Par defaut, `supabase_flutter` persiste la session -- dont le
/// `refresh_token` longue duree -- en SharedPreferences EN CLAIR, donc
/// volable sur un device roote ou vole. Ce [LocalStorage] custom la
/// stocke dans `flutter_secure_storage` (EncryptedSharedPreferences /
/// Keystore sur Android, Keychain sur iOS, DPAPI sur Windows). Il est
/// branche dans [SupabaseService.init] via
/// `FlutterAuthClientOptions(localStorage: SecureSupabaseLocalStorage())`.
///
/// Note migration : au 1er lancement apres l'ajout, une session ecrite
/// par l'ancienne version (en clair) n'est pas relue ici -> l'utilisateur
/// se reconnecte une fois (OTP email). Sans gravite (pas de perte de
/// donnees locales, juste un re-login cloud).
class SecureSupabaseLocalStorage extends LocalStorage {
  SecureSupabaseLocalStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  /// Cle de la session persistee. Propre a ce storage (peu importe la
  /// cle qu'utilisait l'ancien backend SharedPreferences).
  static const _sessionKey = 'supabase_session_v1';

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() => _storage.containsKey(key: _sessionKey);

  @override
  Future<String?> accessToken() => _storage.read(key: _sessionKey);

  @override
  Future<void> removePersistedSession() =>
      _storage.delete(key: _sessionKey);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: _sessionKey, value: persistSessionString);
}
