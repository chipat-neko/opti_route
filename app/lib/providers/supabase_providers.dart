import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/carnet_auto_push_service.dart';
import '../data/chef_presence_service.dart';
import '../data/cloud_auto_pull_service.dart';
import '../data/cloud_auto_push_service.dart';
import '../data/cloud_sync_service.dart';
import '../data/live_presence_service.dart';
import '../data/supabase_service.dart';
import '../data/tournee_realtime_service.dart';
import 'database_providers.dart';

/// Stream de l'utilisateur Supabase connecte (null si pas connecte ou
/// service non configure). Sert aux ecrans cloud (sync, partage equipe)
/// pour montrer le bon CTA "Se connecter" ou "Se deconnecter".
///
/// Emit immediatement [SupabaseService.currentUser] apres avoir attendu
/// la fin de l'init Supabase, puis a chaque AuthState change.
///
/// **Bug history (fix 2026-05-21)** : sans le `await svc.init()`, le
/// provider etait cree au boot AVANT que `unawaited(init())` dans
/// main.dart ne termine. `_initialized` etait alors false, donc :
///   - `svc.currentUser` -> null (init pas finie)
///   - `svc.authStateChanges` -> Stream.empty() (se termine
///     immediatement, le `await for` sort tout de suite)
/// Resultat : le user qui validait son code OTP voyait son auth
/// reussir cote API, mais le StreamProvider restait fige a `null` -> le
/// `_SignInTile` restait affiche au lieu de `_SignedInTile`. La page de
/// connexion semblait "revenir comme avant" apres OTP.
///
/// Le `await svc.init()` est idempotent (early-return si deja init),
/// donc safe a appeler ici.
final cloudUserProvider = StreamProvider<User?>((ref) async* {
  final svc = SupabaseService.instance;
  await svc.init();
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

/// Membres d'une entreprise via RPC cloud (carte #366). autoDispose +
/// family keyée par entrepriseId : rechargé à chaque ouverture de la
/// section. Invalider après une invitation/révocation pour rafraîchir.
final entrepriseMembresProvider = FutureProvider.autoDispose
    .family<List<EntrepriseMembreInfo>, String>((ref, entrepriseId) async {
  return ref
      .watch(cloudSyncServiceProvider)
      .listEntrepriseMembers(entrepriseId);
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

/// Service d'auto-push du carnet vers Supabase (carte Trello #57 V2).
/// Watche la table `saved_destinations` en continu et push debounce 5s
/// les rows modifiees. Couvre TOUS les sites de modification (carnet
/// backfill, vCard import, upsertFromValidatedStop a chaque livraison),
/// complement du push V1 wire dans les 3 ecrans (edit/color/favori).
///
/// Singleton : un seul watch a la fois pour eviter les double-push.
/// Demarre depuis le bootstrap de l'app (cf main.dart / app.dart) ou
/// au sign-in (cloudUserProvider listen). Stop au sign-out.
final carnetAutoPushServiceProvider = Provider<CarnetAutoPushService>((ref) {
  final service = CarnetAutoPushService(
    ref.watch(cloudSyncServiceProvider),
    ref.watch(appDatabaseProvider),
    SupabaseService.instance,
  );
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
  final service = TourneeRealtimeService(
    ref.watch(appDatabaseProvider),
    ref.watch(cloudAutoPushServiceProvider),
  );
  ref.onDispose(service.unsubscribe);
  return service;
});

/// Service de push periodique de la position GPS du device courant
/// sur le channel Realtime de la tournee partagee active (jalon 3.C).
/// Demarre par TourneeDuJourScreen quand on ouvre une tournee partagee
/// `en_cours`, stop dans dispose.
final livePresenceServiceProvider = Provider<LivePresenceService>((ref) {
  final service =
      LivePresenceService(ref.watch(tourneeRealtimeServiceProvider));
  ref.onDispose(service.stop);
  return service;
});

/// Service de presence live multi-tournees pour le logiciel chef
/// (carte #174). Observe les positions de tous les chauffeurs des
/// tournees d'equipe en cours. autoDispose : on coupe les channels des
/// que le panneau carte chef se ferme.
final chefPresenceServiceProvider =
    Provider.autoDispose<ChefPresenceService>((ref) {
  final svc = ChefPresenceService();
  ref.onDispose(() {
    svc.stop();
    svc.dispose();
  });
  return svc;
});

/// cloudIds des tournees d'equipe EN COURS a observer (statut en_cours
/// + cloudId non null = tournee partagee/synchronisee).
final equipeTourneesActivesCloudIdsProvider =
    Provider.autoDispose<Set<String>>((ref) {
  final tournees = ref.watch(tourneesDuJourProvider);
  return tournees
      .where((t) => t.statut == 'en_cours' && t.cloudId != null)
      .map((t) => t.cloudId!)
      .toSet();
});

/// Positions GPS live des chauffeurs de l'equipe (carte #174), agregees
/// sur tous les channels Realtime des tournees en cours. Map
/// `userCloudId -> LivePosition`. Vide si cloud non configure / pas
/// connecte / aucune tournee partagee en cours.
final equipePresenceProvider =
    StreamProvider.autoDispose<Map<String, LivePosition>>((ref) {
  if (!SupabaseService.instance.isConfigured) {
    return Stream.value(const <String, LivePosition>{});
  }
  final user = ref.watch(cloudUserProvider).asData?.value;
  if (user == null) {
    return Stream.value(const <String, LivePosition>{});
  }
  final cloudIds = ref.watch(equipeTourneesActivesCloudIdsProvider);
  final svc = ref.watch(chefPresenceServiceProvider);
  // (Re)synchronise les abonnements Realtime quand l'ensemble des
  // tournees actives change. Best-effort (le service log ses erreurs).
  unawaited(svc.sync(Supabase.instance.client, cloudIds));
  return svc.positionsStream;
});
