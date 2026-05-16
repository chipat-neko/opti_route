import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/cloud_sync_service.dart';
import '../data/supabase_service.dart';
import 'database_providers.dart';

/// Stream de l'utilisateur Supabase connecte (null si pas connecte ou
/// service non configure). Sert aux ecrans cloud (sync, partage equipe)
/// pour montrer le bon CTA "Se connecter" ou "Se deconnecter".
///
/// Emit immediatement [SupabaseService.currentUser] au mount, puis a
/// chaque AuthState change.
final cloudUserProvider = StreamProvider<User?>((ref) async* {
  final svc = SupabaseService.instance;
  yield svc.currentUser;
  await for (final event in svc.authStateChanges) {
    yield event.session?.user;
  }
});

/// Vrai si la build de l'app a ete compilee avec les credentials
/// Supabase (--dart-define=SUPABASE_URL=...). Sert a masquer les
/// sections cloud dans Parametres pour les builds dev sans backend.
final cloudConfiguredProvider = Provider<bool>(
  (ref) => SupabaseService.instance.isConfigured,
);

/// Service de sync local → cloud (sous-jalon 2.B). Permet de pousser
/// une tournee + ses stops + les coequipiers references vers Supabase.
/// Idempotent : re-push d'une tournee deja sync = UPDATE via upsert.
///
/// Le service throw [CloudSyncException] si pas configure / pas
/// authentifie / erreur reseau. L'UI affiche le message dans une
/// SnackBar.
final cloudSyncServiceProvider = Provider<CloudSyncService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return CloudSyncService(db, SupabaseService.instance);
});
