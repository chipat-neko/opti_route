import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../data/local_route_estimate.dart';
import '../../providers/database_providers.dart';
import '../../theme/app_tokens.dart';
import '../cloud/coequipiers_section.dart';
import 'autres_tournees_banner.dart';
import 'banners.dart';
import 'header.dart';
import 'prochain_arret_card.dart';
import 'progress_banner.dart';
import 'recap_depot_card.dart';
import 'stat_row.dart';
import 'stops_list.dart';
import 'stops_section.dart';

/// ════════════════════════════════════════════════════════════════
/// Body principal de [TourneeDuJourScreen].
/// ════════════════════════════════════════════════════════════════
///
/// Empile dans un ListView les sous-widgets thematiques :
/// Header, AutresTourneesDuJourBanner, StatRow, CoutCarburantBanner,
/// OptimisedBanner, ProgressBanner, ProchainArretCard, StopsSection.
///
/// Extrait de `tournee_du_jour_screen.dart` pour symetrie avec les
/// autres widgets du dossier `tournee_du_jour/`. L'etat de la tournee
/// + ses stops sont passes en parametre par l'ecran parent qui les
/// watch via Riverpod ; l'etat local se limite a la memoire de ce qui
/// a deja ete soumis a OSRM (cf [_BodyState._maybeRequestMetricsUpdate]),
/// qui evite de relancer une requete a chaque rebuild.
class Body extends ConsumerStatefulWidget {
  const Body({
    super.key,
    required this.tournee,
    required this.stops,
  });

  final Tournee tournee;
  final List<Stop> stops;

  @override
  ConsumerState<Body> createState() => _BodyState();
}

/// Signature de l'itineraire soumis a OSRM : point de depart de la
/// tournee + sequence ORDONNEE des coordonnees des arrets geocodes.
///
/// C'est exactement ce que [RouteMetricsAutoUpdater] consomme pour
/// construire ses waypoints. Tout le reste d'un arret (nom du client,
/// nb de colis, notes, statut de livraison, priorite...) ne change pas
/// la route : le modifier ne doit donc pas rappeler OSRM.
///
/// Les arrets non geocodes (lat ou lng null) sont ignores : le service
/// les filtre deja, en ajouter ou en supprimer ne modifie pas le
/// trace. Deux arrets distincts aux memes coordonnees donnent la meme
/// signature, ce qui est correct (meme trace, memes metriques).
///
/// Publique (et hors de la classe State) pour etre testable directement,
/// sans monter tout l'ecran : cf
/// `test/screens/tournee_du_jour_body_signature_test.dart`.
String routeSignature(Tournee tournee, List<Stop> stops) {
  final buf = StringBuffer()
    ..write(tournee.id)
    ..write('@')
    ..write(tournee.pointDepartLat)
    ..write(',')
    ..write(tournee.pointDepartLng);
  for (final s in stops) {
    final lat = s.lat;
    final lng = s.lng;
    if (lat == null || lng == null) continue;
    buf
      ..write('|')
      ..write(lat)
      ..write(',')
      ..write(lng);
  }
  return buf.toString();
}

class _BodyState extends ConsumerState<Body> {
  /// Signature du dernier itineraire pour lequel on a demande un
  /// recalcul OSRM. Null tant qu'on n'a rien demande.
  String? _lastRouteSignature;

  /// La tournee etait-elle sans metriques au passage precedent ? Sert a
  /// detecter le moment ou `invalidateOptimization` vient de les effacer
  /// (distance/duree remises a null) alors que l'itineraire, lui, n'a
  /// pas bouge -- typiquement l'edition d'un arret qui ne touche pas aux
  /// coordonnees.
  bool _metricsEtaientManquantes = false;

  @override
  void initState() {
    super.initState();
    _maybeRequestMetricsUpdate();
  }

  @override
  void didUpdateWidget(covariant Body oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeRequestMetricsUpdate();
  }

  /// Demande au service un recalcul OSRM de la distance + duree, mais
  /// UNIQUEMENT quand ca sert a quelque chose :
  /// - au 1er affichage de l'ecran ;
  /// - quand l'itineraire change reellement : ordre des arrets, coords,
  ///   point de depart (cf [routeSignature]) ;
  /// - quand distance/duree viennent d'etre effacees par
  ///   `invalidateOptimization` sans que l'itineraire bouge.
  ///
  /// F25 volet 2 : avant, l'appel etait fait dans `build()`, donc rejoue
  /// a chaque rebuild (changement de theme, scroll, rebuild du parent,
  /// simple passage d'un arret en "livre"...) alors que le trace etait
  /// identique. Le debounce 500ms cote service reste en place pour le
  /// cas "on reorganise plusieurs arrets d'affilee".
  ///
  /// Best-effort : si OSRM est down, la DB garde ses valeurs precedentes
  /// et le fallback haversine de [build] affiche `~`. On ne re-tente pas
  /// tant que rien ne change (nouvelle tentative au prochain changement
  /// d'itineraire ou a la reouverture de l'ecran).
  void _maybeRequestMetricsUpdate() {
    final signature = routeSignature(widget.tournee, widget.stops);
    final manquantes = (widget.tournee.distanceTotaleM ?? 0) <= 0;
    final itineraireChange = signature != _lastRouteSignature;
    final metricsEffacees = manquantes && !_metricsEtaientManquantes;
    _lastRouteSignature = signature;
    _metricsEtaientManquantes = manquantes;
    if (!itineraireChange && !metricsEffacees) return;
    ref
        .read(routeMetricsAutoUpdaterProvider)
        .requestUpdate(widget.tournee.id, widget.stops);
  }

  @override
  Widget build(BuildContext context) {
    final tournee = widget.tournee;
    final stops = widget.stops;

    // Fallback : si distanceTotaleM est null ou 0 (jamais calcule),
    // on affiche une estimation locale haversine en attendant que OSRM
    // reponde. Marquee `isEstimate` pour le prefixe `~`.
    final hasMetrics = (tournee.distanceTotaleM ?? 0) > 0;
    final est = hasMetrics
        ? null
        : LocalRouteEstimate.compute(tournee: tournee, stops: stops);
    final displayMeters = hasMetrics ? tournee.distanceTotaleM : est?.meters;
    final displaySeconds = hasMetrics ? tournee.dureeTotaleS : est?.seconds;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x18,
        AppSpacing.x8,
        AppSpacing.x18,
        AppSpacing.x18,
      ),
      children: [
        Header(tournee: tournee),
        // Jalon 3.B : section coequipiers (visible seulement si la
        // tournee est partagee = au moins 1 member en plus du owner).
        // Auto-masquee sinon via SizedBox.shrink interne.
        CoequipiersSection(tournee: tournee),
        AutresTourneesDuJourBanner(currentTourneeId: tournee.id),
        const SizedBox(height: AppSpacing.x16),
        StatRow(
          arretsCount: stops.length,
          colisTotal: stops.fold<int>(0, (sum, s) => sum + s.nbColis),
          distanceMeters: displayMeters,
          durationSeconds: displaySeconds,
          isEstimate: !hasMetrics && (displayMeters ?? 0) > 0,
        ),
        if (tournee.distanceTotaleM != null &&
            tournee.distanceTotaleM! > 0) ...[
          const SizedBox(height: AppSpacing.x8),
          CoutCarburantBanner(distanceMeters: tournee.distanceTotaleM!),
        ],
        // Carte #276 : fin estimee de tournee (auto-masque si pas en_cours
        // ou pas d'ETA calculable).
        const SizedBox(height: AppSpacing.x8),
        EndOfTourChip(tournee: tournee),
        if (tournee.statut == 'optimisee') ...[
          const SizedBox(height: AppSpacing.x12),
          OptimisedBanner(tournee: tournee),
        ],
        // Carte #274 : ProgressBanner visible des que la tournee a demarre
        // (avant on attendait la 1ere livraison), pour avoir un compteur
        // "X colis dans le camion" visible en permanence.
        if (tournee.demareeLe != null) ...[
          const SizedBox(height: AppSpacing.x12),
          ProgressBanner(
            stops: stops,
            tourneeTerminee: tournee.statut == 'terminee',
            demareeLe: tournee.demareeLe,
            isEnPause: tournee.pauseeLe != null,
          ),
        ],
        // Alertes anomalies (carte #122) : auto-masquees si aucune.
        AnomaliesBanner(tournee: tournee, stops: stops),
        // Carte #275 : recap des colis a rapporter au depot quand la
        // tournee est terminee (echecs livraison + ramasses recoltees).
        // Auto-masque si rien a rapporter.
        if (tournee.statut == 'terminee') ...[
          const SizedBox(height: AppSpacing.x12),
          RecapDepotCard(stops: stops),
        ],
        if (tournee.statut == 'en_cours') ...[
          const SizedBox(height: AppSpacing.x12),
          ProchainArretCard(stops: stops),
        ],
        const SizedBox(height: AppSpacing.x18),
        if (stops.isEmpty)
          const StopsPlaceholder()
        else
          StopsSection(stops: stops),
      ],
    );
  }
}
