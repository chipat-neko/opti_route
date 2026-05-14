import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../data/location_service.dart';
import '../../data/navigation_service.dart';
import '../../data/notifications_service.dart';
import '../../providers/database_providers.dart';
import '../../providers/location_providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';

/// ════════════════════════════════════════════════════════════════
/// Card "Prochain arret" — encart noir mis en avant en haut de
/// l'ecran pendant qu'une tournee est en cours.
/// ════════════════════════════════════════════════════════════════
///
/// Selectionne le premier arret encore "a_livrer" dans l'ordre
/// optimise et affiche :
///   - un badge "PROCHAIN" lime ;
///   - la distance a vol d'oiseau live depuis la position GPS du
///     chauffeur (rafraichie par `currentPositionProvider`) ;
///   - le nom client (si renseigne) + l'adresse normalisee ;
///   - deux boutons rapides Maps / Waze pour lancer la navigation ;
///   - un gros bouton "Marquer livre" emerald qui valide l'arret
///     sans passer par la bottom sheet (mode livraison rapide).
///
/// Si tous les arrets ont deja un statut definitif (livre/echec) ou
/// si aucun n'a de coords, le widget retourne un `SizedBox.shrink()`
/// pour ne rien afficher (le bandeau de progression + la liste
/// suffisent dans ce cas).
class ProchainArretCard extends ConsumerWidget {
  const ProchainArretCard({super.key, required this.stops});

  final List<Stop> stops;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;

    // ─── 1. Selection du candidat "prochain arret" ───────────────
    // On prend le premier stop encore "a_livrer" qui a des coords.
    // Les stops sans coords sont ignores (on ne peut pas calculer la
    // distance ni proposer la navigation Maps/Waze).
    Stop? candidat;
    for (final s in stops) {
      if (s.statutLivraison == 'a_livrer' &&
          s.lat != null &&
          s.lng != null) {
        candidat = s;
        break;
      }
    }
    if (candidat == null) {
      // Aucun stop a livrer (tournee finie) ou aucun avec coords :
      // on n'affiche rien. Le ProgressBanner + la StopsList suffisent.
      return const SizedBox.shrink();
    }
    // Promotion non-null : variable `final` apres l'early return.
    final prochain = candidat;
    final lat = prochain.lat!;
    final lng = prochain.lng!;

    // ─── 2. Calcul de la distance live depuis la position GPS ────
    // `currentPositionProvider` est un StreamProvider qui emet
    // periodiquement la position du device (interval defini dans
    // location_providers.dart). Si la permission n'est pas accordee
    // ou si le GPS est down, la valeur est null et on n'affiche pas
    // de distance.
    final positionAsync = ref.watch(currentPositionProvider);
    final distanceLabel = positionAsync.maybeWhen(
      data: (pos) {
        if (pos == null) return null;
        final m = LocationService.distanceMeters(
          fromLat: pos.latitude,
          fromLng: pos.longitude,
          toLat: lat,
          toLng: lng,
        );
        return _formatDistanceMeters(m);
      },
      orElse: () => null,
    );

    final nom = (prochain.nomClient ?? '').trim();
    final hasNom = nom.isNotEmpty;

    // ─── 3. Construction de l'UI ────────────────────────────────
    return Container(
      decoration: BoxDecoration(
        color: p.ink,
        borderRadius: BorderRadius.circular(AppRadius.r18),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.all(AppSpacing.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header : badge "PROCHAIN" a gauche, distance a droite.
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.x8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.lime,
                  borderRadius: BorderRadius.circular(AppRadius.r6),
                ),
                child: Text(
                  'PROCHAIN',
                  style: appMonoStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: p.ink,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const Spacer(),
              if (distanceLabel != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.near_me_outlined,
                      color: AppColors.lime,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      distanceLabel,
                      style: appMonoStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.lime,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.x10),
          // Nom client (si renseigne) — affiche en grande police.
          if (hasNom)
            Text(
              nom,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: p.paper,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (hasNom) const SizedBox(height: 2),
          // Adresse (normalisee si geocodee, sinon brute saisie).
          // Plus discrete (alpha 70 %) si le nom client est present
          // au-dessus, plus grosse sinon (l'adresse devient le titre).
          Text(
            prochain.adresseNormalisee ?? prochain.adresseBrute,
            style: TextStyle(
              fontSize: hasNom ? 13 : 16,
              color: p.paper.withValues(alpha: hasNom ? 0.7 : 1),
              fontWeight: hasNom ? FontWeight.w500 : FontWeight.w700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.x12),
          // ─── Boutons navigation Maps / Waze ─────────────────────
          // Lancent une intent externe vers l'app correspondante.
          // Si l'app n'est pas installee, l'OS propose au user de
          // l'installer (NavigationService gere ca).
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: p.paper,
                    foregroundColor: p.ink,
                    minimumSize: const Size(0, 44),
                  ),
                  onPressed: () => NavigationService.launchGoogleMaps(
                    lat: lat,
                    lng: lng,
                  ),
                  icon: const Icon(Icons.map_outlined, size: 16),
                  label: const Text(
                    'Maps',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.x8),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: p.paper,
                    foregroundColor: p.ink,
                    minimumSize: const Size(0, 44),
                  ),
                  onPressed: () => NavigationService.launchWaze(
                    lat: lat,
                    lng: lng,
                  ),
                  icon: const Icon(Icons.navigation_outlined, size: 16),
                  label: const Text(
                    'Waze',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
          // ─── Gros bouton "Marquer livre" ────────────────────────
          // Mode livraison rapide : pas besoin d'ouvrir la bottom
          // sheet pour valider. Capture la position GPS comme preuve
          // et passe au prochain arret. Le ProgressBanner se met a
          // jour automatiquement (watch via Riverpod).
          const SizedBox(height: AppSpacing.x10),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.emerald,
              foregroundColor: p.paper,
              minimumSize: const Size(double.infinity, 48),
            ),
            onPressed: () => _markLivreFromCard(context, ref, prochain),
            icon: const Icon(Icons.check_circle, size: 20),
            label: const Text(
              'Marquer livre',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Marque le stop comme livre en capturant la position GPS courante
  /// comme preuve de passage. Si tous les arrets ont alors un statut
  /// definitif, bascule la tournee en 'terminee' et annule le rappel.
  ///
  /// Best-effort sur le GPS (timeout 4 s) : si le device est offline
  /// ou la permission refusee, on enregistre quand meme le statut
  /// sans coords plutot que d'echouer.
  static Future<void> _markLivreFromCard(
    BuildContext context,
    WidgetRef ref,
    Stop stop,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    // Capture GPS best-effort en parallele du markLivre (4 s max).
    ({double lat, double lng})? pos;
    try {
      final ok = await LocationService.ensurePermission();
      if (ok) {
        final p = await LocationService.currentPosition()
            .timeout(const Duration(seconds: 4));
        pos = (lat: p.latitude, lng: p.longitude);
      }
    } catch (_) {/* best-effort : on continue sans coords */}

    await ref.read(stopsRepositoryProvider).markLivre(stop.id, position: pos);

    // Bascule auto en 'terminee' si tous les arrets ont un statut.
    // Meme logique que _TourneeDuJourScreenState._maybeFinishTournee
    // (qu'on duplique ici car cette methode est static).
    final stopsRepo = ref.read(stopsRepositoryProvider);
    final tourneesRepo = ref.read(tourneesRepositoryProvider);
    final allStops = await stopsRepo.getByTournee(stop.tourneeId);
    final tousValides = allStops.isNotEmpty &&
        allStops.every((s) =>
            s.statutLivraison == 'livre' || s.statutLivraison == 'echec');
    if (tousValides) {
      await tourneesRepo.update(
        stop.tourneeId,
        const TourneesCompanion(statut: Value('terminee')),
      );
      // Bascule automatique vers terminee : on annule le rappel s'il
      // y en avait un encore programme (la tournee est faite).
      await NotificationsService.instance
          .cancelTourneeRappel(stop.tourneeId);
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          stop.nomClient?.isNotEmpty == true
              ? '${stop.nomClient} marque livre'
              : 'Arret marque livre',
        ),
        backgroundColor: AppColors.emerald,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Format compact de distance : "350 m" / "1.2 km".
  static String _formatDistanceMeters(double m) {
    if (m < 1000) return '${m.round()} m';
    return '${(m / 1000).toStringAsFixed(1)} km';
  }
}
