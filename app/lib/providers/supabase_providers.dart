import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/cloud_auto_pull_service.dart';
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

/// Service de pull initial auto au 1er sign-in (sous-jalon 2.D-1b).
/// Encapsule la logique du flag par-user `cloud_pull_done_for_<uuid>`
/// pour ne declencher le pull qu'une seule fois par user/telephone.
final cloudAutoPullServiceProvider = Provider<CloudAutoPullService>((ref) {
  return CloudAutoPullService(
    ref.watch(cloudSyncServiceProvider),
    ref.watch(parametresRepositoryProvider),
  );
});

/// Etat de l'auto-pull initial pour affichage UI :
/// - `AsyncData(null)` : idle (rien a pull ou deja fait)
/// - `AsyncLoading()` : pull en cours
/// - `AsyncData(result)` : pull termine avec ce resultat (non-null)
/// - `AsyncError(e, st)` : erreur (CloudSyncException ou autre)
///
/// Modifie par le listener dans OptiRouteApp.build qui declenche le
/// pull au sign-in via `ref.read(cloudPullStateProvider.notifier).state = ...`.
/// Watche par `cloud_section.dart` pour afficher un indicateur
/// "Sync initial en cours..." ou un toast de fin.
class CloudPullStateNotifier
    extends Notifier<AsyncValue<CloudPullResult?>> {
  @override
  AsyncValue<CloudPullResult?> build() => const AsyncData(null);

  /// Setter explicite. On l'expose via une methode dediee plutot que
  /// de laisser le caller faire `.state = ...` directement — ca
  /// permet de logger / instrumentaliser plus tard si besoin.
  void set(AsyncValue<CloudPullResult?> value) => state = value;
}

final cloudPullStateProvider = NotifierProvider<CloudPullStateNotifier,
    AsyncValue<CloudPullResult?>>(CloudPullStateNotifier.new);
