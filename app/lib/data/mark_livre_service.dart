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
/// tournee. Sert aux tests, a l'undo du batch (cf [MarkLivreResult]) et
/// permettrait a un appelant d'afficher un message different quand la
/// tournee vient de se cloturer.
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

/// Ce qui est arrive au statut de la tournee, PLUS le statut qu'elle
/// avait juste avant.
///
/// [statutAvant] existe pour l'undo de "Tout livrer" (carte #115) :
/// quand le batch cloture la tournee, le SnackBar "Annuler" doit la
/// remettre exactement dans l'etat d'ou elle vient ('en_cours' le plus
/// souvent, mais pas forcement) -- pas dans l'etat 'optimisee' que
/// choisirait une simple re-synchronisation. null quand la tournee n'a
/// pas pu etre lue (introuvable, ou sans aucun arret) : dans ce cas
/// [change] vaut toujours [StatutTourneeChange.inchange], donc il n'y a
/// rien a restaurer.
typedef MarkLivreResult = ({StatutTourneeChange change, String? statutAvant});

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
/// Source unique de verite pour les cinq entrees "marquer livre" de
/// l'ecran Tournee du jour :
///   - la bottom sheet d'actions (`StopRowActions.handleTap`) ;
///   - le swipe sur une ligne (`StopRowActions.handleSwipeLivre`) ;
///   - les boutons 1 tap (`ProchainArretCard` et `ProximiteBanner`, via
///     `StopRowActions.markLivreRapide`) ;
///   - "Tout livrer" (`StopsBulkActions.batchLivre`, via
///     [markLivreBatch]) ;
///   - la commande vocale "livre" (`VoiceCommandFab`).
///
/// Avant, la sequence "capture GPS -> markLivre -> bascule en terminee"
/// existait en deux exemplaires divergents (`StopRowActions` et
/// `ProchainArretCard`). Ce service porte l'UNION des deux :
/// re-verification du statut courant de la tournee, recap de fin de
/// tournee, annulation des DEUX rappels, et retour en 'optimisee' quand
/// un statut est annule apres la cloture.
///
/// Les deux dernieres copies l'ont rejoint ensuite, chacune incomplete a
/// sa maniere : "Tout livrer" oubliait le recap et le rappel >8h, et la
/// commande vocale n'avait ni preuve GPS ni cloture du tout.
///
/// Porte aussi [markEchec] (commande vocale "echec"), parce qu'un echec
/// est un statut definitif au meme titre qu'un "livre" : il doit
/// declencher la meme cloture. Les autres changements de statut
/// (bottom sheet, retour en 'a_livrer', undo du dernier statut) gardent
/// leur ecriture cote appelant et appellent [syncStatutTournee] apres.
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

  /// Marque [stop] en echec avec [raison] et la position GPS courante
  /// comme preuve, puis re-synchronise le statut de la tournee.
  ///
  /// Un echec est un statut DEFINITIF pour la cloture : la
  /// re-synchronisation compte 'livre' ET 'echec' (cf
  /// [_syncStatutTournee]), donc echouer sur le DERNIER arret termine
  /// la tournee exactement comme le livrer -- recap et annulation des
  /// deux rappels compris.
  ///
  /// Pas de crochet `pendantCaptureGps` ici, contrairement a
  /// [markLivre] : il n'existe que pour ouvrir le pad de signature du
  /// destinataire pendant le fix, ce qui n'a pas de sens sur un echec.
  /// Le fix est donc simplement attendu avant l'ecriture, comme le
  /// faisait deja la bottom sheet d'actions.
  Future<StatutTourneeChange> markEchec(Stop stop, String raison) async {
    final pos = await _capturerGps();
    await _stops.markEchec(stop.id, raison, position: pos);
    return syncStatutTournee(stop.tourneeId);
  }

  /// Marque livres TOUS les [stops] fournis, avec UNE SEULE capture GPS
  /// pour le lot entier, puis re-synchronise le statut de la tournee.
  ///
  /// Un fix par arret serait lent (jusqu'a 4 s chacun) et inutile :
  /// "Tout livrer" se declenche depuis un seul endroit, l'utilisateur
  /// n'a pas bouge entre deux arrets du lot. Tous les arrets recoivent
  /// donc la meme preuve de passage -- c'est le comportement d'origine
  /// de `StopsBulkActions.batchLivre`.
  ///
  /// [stops] ne doit contenir que des arrets d'une meme tournee (c'est
  /// le cas : le lot vient d'un `getByTournee` filtre) -- verifie par un
  /// `assert`, car un lot melange ne re-synchroniserait que la premiere
  /// tournee. No-op sur une liste vide, y compris la capture GPS.
  ///
  /// Retourne, en plus du changement de statut, le statut qu'avait la
  /// tournee AVANT : l'undo du batch en a besoin (cf [MarkLivreResult]).
  Future<MarkLivreResult> markLivreBatch(List<Stop> stops) async {
    if (stops.isEmpty) {
      return (change: StatutTourneeChange.inchange, statutAvant: null);
    }
    final tourneeId = stops.first.tourneeId;
    // Une seule tournee est re-synchronisee : un lot melange laisserait
    // les autres tournees avec un statut perime, en silence.
    assert(
      stops.every((s) => s.tourneeId == tourneeId),
      'markLivreBatch attend des arrets d\'une seule tournee',
    );
    final pos = await _capturerGps();
    for (final s in stops) {
      await _stops.markLivre(s.id, position: pos);
    }
    return _syncStatutTournee(tourneeId);
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
    return (await _syncStatutTournee(tourneeId)).change;
  }

  /// Corps de [syncStatutTournee], qui rend EN PLUS le statut d'avant.
  /// Seul [markLivreBatch] en a besoin (pour son undo) : les autres
  /// appelants gardent la version enum, plus simple a lire.
  Future<MarkLivreResult> _syncStatutTournee(int tourneeId) async {
    const MarkLivreResult rienAFaire = (
      change: StatutTourneeChange.inchange,
      statutAvant: null,
    );
    final stops = await _stops.getByTournee(tourneeId);
    if (stops.isEmpty) return rienAFaire;
    final tournee = await _tournees.getById(tourneeId);
    if (tournee == null) return rienAFaire;
    final statutAvant = tournee.statut;
    final tousValides = stops.every(
      (s) => s.statutLivraison == 'livre' || s.statutLivraison == 'echec',
    );
    final etaitTerminee = statutAvant == 'terminee';
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
      return (change: StatutTourneeChange.terminee, statutAvant: statutAvant);
    }
    if (!tousValides && etaitTerminee) {
      // L'utilisateur a annule un statut deja pose. On retire la marque
      // "terminee" pour qu'il finisse la tournee.
      await _tournees.update(
        tourneeId,
        const TourneesCompanion(statut: Value('optimisee')),
      );
      return (change: StatutTourneeChange.rouverte, statutAvant: statutAvant);
    }
    return (change: StatutTourneeChange.inchange, statutAvant: statutAvant);
  }
}
