import 'dart:async';

import 'package:drift/drift.dart' show Value;

import 'database.dart';
import 'location_service.dart';
import 'notifications_service.dart';
import 'stops_repository.dart';
import 'tournees_repository.dart';

/// Position GPS reduite au couple (lat, lng) -- ce que
/// [StopsRepository.markLivre] attend comme preuve de passage.
typedef GpsFix = ({double lat, double lng});

/// Capture best-effort de la position courante pour servir de preuve de
/// passage. Retourne null si la permission n'a pas ete accordee, si le
/// GPS est down (offline, indoors, batterie faible) ou si le fix prend
/// plus de 4 s.
///
/// Timeout court volontaire : on ne bloque pas l'UX pendant que Noah
/// enchaine les "Marquer livre" en sortant du vehicule. Ne throw JAMAIS
/// -- au pire on enregistre le statut sans coords.
///
/// Etait recopie a l'identique dans `StopRowActions._captureGpsPosition`
/// et dans `ProchainArretCard._markLivreFromCard` avant d'atterrir ici.
Future<GpsFix?> captureGpsBestEffort() async {
  try {
    final ok = await LocationService.ensurePermission();
    if (!ok) return null;
    final pos = await LocationService.currentPosition()
        .timeout(const Duration(seconds: 4));
    return (lat: pos.latitude, lng: pos.longitude);
  } catch (_) {
    return null; // best-effort : on continue sans coords
  }
}

/// Ce que [MarkLivreService.syncStatutTournee] a fait au statut de la
/// tournee. Sert aux tests (et permettrait a un appelant d'afficher un
/// message different quand la tournee vient de se cloturer).
enum StatutTourneeChange {
  /// Rien n'a bouge : il reste des arrets a traiter, ou la tournee etait
  /// deja dans le bon etat.
  inchange,

  /// Tous les arrets ont un statut definitif -> tournee passee en
  /// 'terminee' (+ recap et annulation des rappels).
  terminee,

  /// Un statut a ete annule apres coup -> la tournee repasse en
  /// 'optimisee' pour qu'on puisse la finir.
  rouverte,
}

/// Notifications declenchees par la cloture automatique d'une tournee.
///
/// Existe pour que [MarkLivreService] soit testable : [NotificationsService]
/// est un singleton a constructeur prive branche sur
/// `flutter_local_notifications`, donc impossible a monter dans un test
/// unitaire. En prod, l'implementation par defaut delegue mot pour mot
/// aux memes appels qu'avant l'extraction.
abstract interface class MarkLivreNotifications {
  Future<void> showEndOfRouteSummary({
    required int tourneeId,
    required String nomTournee,
    required int nbLivres,
    required int nbEchecs,
    required int dureeTotaleMin,
  });

  Future<void> cancelTourneeRappel(int tourneeId);

  Future<void> cancelTourneeNonTermineeReminder(int tourneeId);
}

/// Implementation reelle : delegue au singleton du plugin.
class _PluginNotifications implements MarkLivreNotifications {
  const _PluginNotifications();

  @override
  Future<void> showEndOfRouteSummary({
    required int tourneeId,
    required String nomTournee,
    required int nbLivres,
    required int nbEchecs,
    required int dureeTotaleMin,
  }) {
    return NotificationsService.instance.showEndOfRouteSummary(
      tourneeId: tourneeId,
      nomTournee: nomTournee,
      nbLivres: nbLivres,
      nbEchecs: nbEchecs,
      dureeTotaleMin: dureeTotaleMin,
    );
  }

  @override
  Future<void> cancelTourneeRappel(int tourneeId) =>
      NotificationsService.instance.cancelTourneeRappel(tourneeId);

  @override
  Future<void> cancelTourneeNonTermineeReminder(int tourneeId) =>
      NotificationsService.instance.cancelTourneeNonTermineeReminder(tourneeId);
}

/// ════════════════════════════════════════════════════════════════
/// Validation "arret livre" + cloture automatique de la tournee.
/// ════════════════════════════════════════════════════════════════
///
/// Source unique de verite pour les trois entrees "marquer livre" de
/// l'ecran Tournee du jour :
///   - la bottom sheet d'actions (`StopRowActions.handleTap`) ;
///   - le swipe sur une ligne (`StopRowActions.handleSwipeLivre`) ;
///   - les boutons 1 tap (`ProchainArretCard` et `ProximiteBanner`, via
///     `StopRowActions.markLivreRapide`).
///
/// Avant, la sequence "capture GPS -> markLivre -> bascule en terminee"
/// existait en deux exemplaires divergents (`StopRowActions` et
/// `ProchainArretCard`). Ce service porte l'UNION des deux :
/// re-verification du statut courant de la tournee, recap de fin de
/// tournee, annulation des DEUX rappels, et retour en 'optimisee' quand
/// un statut est annule apres la cloture.
///
/// Ne touche a rien d'autre : le retour utilisateur (haptique, SnackBar,
/// signature du destinataire) reste cote widget, ou il differe
/// legitimement d'un appelant a l'autre.
class MarkLivreService {
  MarkLivreService(
    this._stops,
    this._tournees, {
    Future<GpsFix?> Function()? capturerGps,
    MarkLivreNotifications? notifications,
  })  : _capturerGps = capturerGps ?? captureGpsBestEffort,
        _notifications = notifications ?? const _PluginNotifications();

  final StopsRepository _stops;
  final TourneesRepository _tournees;
  final Future<GpsFix?> Function() _capturerGps;
  final MarkLivreNotifications _notifications;

  /// Marque [stop] livre avec la position GPS courante comme preuve,
  /// puis re-synchronise le statut de la tournee.
  ///
  /// La capture GPS est lancee EN ARRIERE-PLAN puis attendue juste avant
  /// l'ecriture : [pendantCaptureGps] (typiquement l'ouverture du pad de
  /// signature) tourne pendant ce temps. Avant, on attendait le fix GPS
  /// -- lent en interieur -- AVANT d'ouvrir le canva, d'ou une grosse
  /// latence d'ouverture (retour Noah dev2 2026-06-03).
  Future<StatutTourneeChange> markLivre(
    Stop stop, {
    Future<void> Function()? pendantCaptureGps,
  }) async {
    final gpsFuture = _capturerGps();
    if (pendantCaptureGps != null) await pendantCaptureGps();
    await _stops.markLivre(stop.id, position: await gpsFuture);
    return syncStatutTournee(stop.tourneeId);
  }

  /// Aligne le statut de la tournee sur l'etat de ses arrets :
  /// - tous livres / en echec et tournee pas encore cloturee -> 'terminee',
  ///   notification de recap, annulation du rappel matin ET du rappel
  ///   "tournee non terminee >8h" ;
  /// - un statut annule apres coup sur une tournee deja 'terminee' ->
  ///   retour en 'optimisee' pour qu'on puisse la finir.
  ///
  /// A appeler apres TOUT changement de statut d'arret (livre, echec,
  /// retour en a_livrer), pas seulement apres un "livre".
  ///
  /// No-op si la tournee n'a aucun arret ou n'existe plus.
  Future<StatutTourneeChange> syncStatutTournee(int tourneeId) async {
    final stops = await _stops.getByTournee(tourneeId);
    if (stops.isEmpty) return StatutTourneeChange.inchange;
    final tournee = await _tournees.getById(tourneeId);
    if (tournee == null) return StatutTourneeChange.inchange;
    final tousValides = stops.every(
      (s) => s.statutLivraison == 'livre' || s.statutLivraison == 'echec',
    );
    final etaitTerminee = tournee.statut == 'terminee';
    if (tousValides && !etaitTerminee) {
      await _tournees.update(
        tourneeId,
        const TourneesCompanion(statut: Value('terminee')),
      );
      // Notif post-tournee : recap livres / echecs / duree.
      final nbLivres = stops.where((s) => s.statutLivraison == 'livre').length;
      final nbEchecs = stops.where((s) => s.statutLivraison == 'echec').length;
      final dureeMin = (tournee.dureeTotaleS ?? 0) ~/ 60;
      unawaited(
        _notifications.showEndOfRouteSummary(
          tourneeId: tourneeId,
          nomTournee: tournee.nom,
          nbLivres: nbLivres,
          nbEchecs: nbEchecs,
          dureeTotaleMin: dureeMin,
        ),
      );
      // Si un rappel matin etait programme et toujours pendant, on
      // l'annule (la tournee est faite).
      unawaited(_notifications.cancelTourneeRappel(tourneeId));
      // Idem pour le rappel "tournee non terminee >8h" (#121).
      unawaited(_notifications.cancelTourneeNonTermineeReminder(tourneeId));
      return StatutTourneeChange.terminee;
    }
    if (!tousValides && etaitTerminee) {
      // L'utilisateur a annule un statut deja pose. On retire la marque
      // "terminee" pour qu'il finisse la tournee.
      await _tournees.update(
        tourneeId,
        const TourneesCompanion(statut: Value('optimisee')),
      );
      return StatutTourneeChange.rouverte;
    }
    return StatutTourneeChange.inchange;
  }
}
