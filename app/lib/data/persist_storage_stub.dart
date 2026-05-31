/// Stub pour les plateformes non-web. La persistance n'est pas un
/// concept applicable a Android/Windows/iOS (le stockage n'est pas
/// evictionnable). Retourne true par defaut.
Future<bool> requestPersistentStorage() async => true;
