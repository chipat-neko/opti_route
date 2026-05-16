import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/cloud_auto_pull_service.dart';
import '../data/cloud_auto_push_service.dart';
import '../data/cloud_sync_service.dart';
import '../data/supabase_service.dart';
import '../data/tournee_realtime_service.dart';
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

/// Service d'auto-pull cloud a chaque sign-in (sous-jalon 2.D-1d).
/// Delegue le pull last-write-wins au CloudSyncService.
final cloudAutoPullServiceProvider = Provider<CloudAutoPullService>((ref) {
  return CloudAutoPullService(ref.watch(cloudSyncServiceProvider));
});

/// Etat de l'auto-pull pour affichage UI :
/// - `AsyncData(null)` : idle (aucun pull en cours, pas encore fait)
/// - `AsyncLoading()` : pull en cours
/// - `AsyncData(result)` : pull termine avec ce resultat
/// - `AsyncError(e, st)` : erreur (CloudSyncException ou autre)
///
/// Modifie par le listener dans OptiRouteApp.build qui declenche le
/// pull a chaque sign-in via `ref.read(cloudPullStateProvider.notifier).state = ...`.
/// Watche par `cloud_section.dart` pour afficher un indicateur
/// "Synchronisation en cours..." ou un toast de fin.
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

/// Service d'auto-push de la tournee active vers Supabase (sous-jalon
/// 2.D-2). Debounce 5s, silencieux. Demarre via [CloudAutoPushService.
/// watchTournee] depuis [TourneeDuJourScreen.initState], arrete via
/// [CloudAutoPushService.stop] dans `dispose`.
///
/// Singleton : un seul watch a la fois (la "tournee active" courante).
/// Garder l'instance entre les ouvertures d'ecran evite des re-init
/// inutiles.
final cloudAutoPushServiceProvider = Provider<CloudAutoPushService>((ref) {
  final service = CloudAutoPushService(
    ref.watch(cloudSyncServiceProvider),
    ref.watch(appDatabaseProvider),
    SupabaseService.instance,
  );
  // Cleanup propre si jamais le Provider est dispose (theoriquement
  // pas avant la fin de l'app vu qu'il n'est pas autoDispose).
  ref.onDispose(service.stop);
  return service;
});

/// Service Realtime pour les tournees partagees (jalon 3.A). Subscribe
/// au channel `tournee:<cloudUuid>` quand un ecran de tournee partagee
/// s'ouvre, merge les events Postgres Changes dans la DB Drift locale.
///
/// Singleton : un seul channel actif a la fois (la tournee partagee
/// actuellement consultee). Pas autoDispose pour eviter de re-init
/// chaque ouverture d'ecran.
final tourneeRealtimeServiceProvider =
    Provider<TourneeRealtimeService>((ref) {
  final service = TourneeRealtimeService(ref.watch(appDatabaseProvider));
  ref.onDispose(service.unsubscribe);
  return service;
});
