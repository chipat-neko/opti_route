import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:latlong2/latlong.dart';

import 'database.dart';
import 'osrm_route_service.dart';

/// ════════════════════════════════════════════════════════════════
/// Re-calcule automatiquement la distance + duree routieres exactes
/// d'une tournee a chaque modif d'arrets, via OSRM.
/// ════════════════════════════════════════════════════════════════
///
/// **Trigger** : appele par l'UI ([Body] de tournee_du_jour) qui watch
/// les stops via Riverpod et appelle [requestUpdate] a chaque emit.
///
/// **Debounce 500ms** : si Noah ajoute / supprime / reorganise plusieurs
/// arrets rapidement, on n'appelle OSRM qu'une seule fois 500ms apres
/// la derniere modif. Evite de spammer la demo publique OSRM.
///
/// **Best-effort** : si OSRM est down ou retourne null, on ne touche
/// PAS la DB (les valeurs precedentes restent, le fallback haversine
/// continue d'afficher ~). Pas d'erreur a l'utilisateur.
///
/// **N'ecrase PAS les valeurs VROOM/ORS** : on update toujours, mais si
/// VROOM tournait juste apres, ses valeurs prendront le dessus. Le
/// trade-off : on prefere des chiffres a jour (meme via OSRM) plutot
/// que des vieux chiffres VROOM perimes apres modif.
class RouteMetricsAutoUpdater {
  RouteMetricsAutoUpdater({
    required AppDatabase db,
    required OsrmRouteService osrm,
    Duration debounce = const Duration(milliseconds: 500),
  })  : _db = db,
        _osrm = osrm,
        _debounce = debounce;

  final AppDatabase _db;
  final OsrmRouteService _osrm;
  final Duration _debounce;
  Timer? _timer;
  bool _running = false;

  /// Demande un recalcul des metrics pour [tourneeId] avec [stops].
  /// Debounce automatique : si appele plusieurs fois en < 500ms, seul
  /// le dernier appel declenche l'OSRM.
  void requestUpdate(int tourneeId, List<Stop> stops) {
    _timer?.cancel();
    _timer = Timer(_debounce, () {
      // Pas d'await ici - le Timer.callback est synchrone, on lance
      // la requete en arriere-plan et on ne bloque pas.
      _runUpdate(tourneeId, stops);
    });
  }

  /// Force un recalcul immediat (pour les tests + bouton manuel
  /// eventuel). Pas de debounce.
  Future<void> forceUpdate(int tourneeId, List<Stop> stops) async {
    _timer?.cancel();
    await _runUpdate(tourneeId, stops);
  }

  /// Annule un debounce en cours (a appeler quand l'ecran tournee
  /// se ferme pour eviter une requete fantome).
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _runUpdate(int tourneeId, List<Stop> stops) async {
    if (_running) return;
    _running = true;
    try {
      // 1. Construit les waypoints (depot + stops geocodes dans l'ordre).
      final tournee = await (_db.select(_db.tournees)
            ..where((t) => t.id.equals(tourneeId)))
          .getSingleOrNull();
      if (tournee == null) return;
      final waypoints = <LatLng>[
        LatLng(tournee.pointDepartLat, tournee.pointDepartLng),
        for (final s in stops)
          if (s.lat != null && s.lng != null) LatLng(s.lat!, s.lng!),
      ];
      if (waypoints.length < 2) return;

      // 2. Appelle OSRM (best-effort, null possible).
      final result = await _osrm.fetchRoute(waypoints);
      if (result == null) return;

      // 2bis. Idempotence : si distance + duree calculees sont identiques
      // a ce qui est deja en base, on NE re-ecrit PAS. Un write drift
      // notifie le stream tournee meme sans changement de valeur, ce qui
      // rebuild Body -> re-appelle requestUpdate -> nouvelle requete OSRM :
      // boucle write->rebuild->write superflue. On la coupe a la source.
      // `tournee` est deja charge en debut de methode (etape 1).
      if (tournee.distanceTotaleM == result.meters &&
          tournee.dureeTotaleS == result.seconds) {
        return;
      }

      // 3. Update la DB. On ne touche pas optimiseeLe / traceGeojson
      // pour ne pas faire croire qu'on a re-optimise via VROOM.
      await (_db.update(_db.tournees)..where((t) => t.id.equals(tourneeId)))
          .write(TourneesCompanion(
        distanceTotaleM: Value(result.meters),
        dureeTotaleS: Value(result.seconds),
      ));
    } catch (e) {
      debugPrint('[RouteMetricsAutoUpdater] erreur : $e');
    } finally {
      _running = false;
    }
  }
}
