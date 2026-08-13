import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../data/database.dart';
import '../data/scan_duplicate_check.dart';
import '../providers/database_providers.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import 'scan_colis/alerts.dart';

/// Resultat retourne par [ScanColisScreen] au pop.
class ScanColisResult {
  const ScanColisResult({
    required this.trackingNumber,
    this.matchedStop,
  });

  /// Code-barre brut detecte par mobile_scanner (ex "FA280000440358").
  final String trackingNumber;

  /// Arret existant de la tournee active qui contient deja ce tracking
  /// (cas +1 colis). Null si aucun match -> le caller ouvre l'ecran
  /// "Nouvel arret" pre-rempli avec [trackingNumber].
  final Stop? matchedStop;
}

/// Ecran de scan code-barre colis. Ouvre la camera en plein ecran via
/// `mobile_scanner` et detecte automatiquement les codes 1D (Code128,
/// EAN13, CODE39) utilises par MESEXP, Colissimo, Chronopost.
///
/// Workflow :
/// 1. Camera live avec viseur centre
/// 2. Detection auto -> cherche dans les stops de la tournee active si
///    un arret contient deja ce code dans `tracking_numbers`
/// 3. Si match -> increment +1 colis sur cet arret + pop avec result
/// 4. Sinon -> pop avec result (trackingNumber seul, matchedStop = null)
///
/// Deux garde-fous anti-doublon (carte #315) s'intercalent avant le
/// rattachement, via `ScanDuplicateService` :
/// - **re-livraison** : le tracking a deja ete livre dans les 30
///   derniers jours (toutes tournees) -> alerte + choix ;
/// - **mauvais arret** : le code appartient a un autre arret de la
///   tournee -> proposition de basculer dessus. Ce 2e controle n'a de
///   sens que si le scan a ete lance depuis un arret precis
///   ([expectedStop]).
///
/// Les deux alertes PREVIENNENT sans BLOQUER (cf `scan_colis/alerts`).
///
/// Le caller (typiquement TourneeDuJourScreen) decide de la suite :
/// toast de confirmation si +1 colis, ou navigation vers l'ecran de
/// creation d'arret si nouveau code.
class ScanColisScreen extends ConsumerStatefulWidget {
  const ScanColisScreen({super.key, this.expectedStop});

  /// Arret attendu quand le scan est lance depuis un arret precis
  /// ("est-ce bien le bon colis pour ce client ?"). Null = scan libre
  /// depuis la tournee : il n'y a alors pas de notion de "mauvais
  /// arret", seule la detection de re-livraison s'applique.
  final Stop? expectedStop;

  @override
  ConsumerState<ScanColisScreen> createState() => _ScanColisScreenState();
}

class _ScanColisScreenState extends ConsumerState<ScanColisScreen> {
  final MobileScannerController _controller = MobileScannerController(
    // 1D codes seulement (les bordereaux MESEXP/Colissimo/Chronopost
    // utilisent Code128 + EAN13 + CODE39). Restreindre accelere la
    // detection vs scanner tous formats.
    formats: const [
      BarcodeFormat.code128,
      BarcodeFormat.ean13,
      BarcodeFormat.code39,
      BarcodeFormat.code93,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.itf14,
    ],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _processing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final code = capture.barcodes
        .map((b) => b.rawValue)
        .whereType<String>()
        .firstWhere((s) => s.isNotEmpty, orElse: () => '');
    if (code.isEmpty) return;
    _processing = true;
    await _controller.stop();

    // ─── Garde-fou 1 : re-livraison ────────────────────────────────
    // Avant tout rattachement, on regarde si ce numero a deja ete
    // livre recemment (toutes tournees). Alerte informative : si le
    // livreur prefere ne rien rattacher, on relance juste la camera
    // pour le colis suivant plutot que de fermer l'ecran.
    final checks = ref.read(scanDuplicateServiceProvider);
    final dejaLivre = await checks.findRecentDelivered(code);
    if (!mounted) return;
    if (dejaLivre != null) {
      final continuer =
          await askConfirmRelivraison(context, dejaLivre: dejaLivre);
      if (!mounted) return;
      if (!continuer) {
        _processing = false;
        await _relancerCamera();
        return;
      }
    }

    // ─── Garde-fou 2 : mauvais arret ───────────────────────────────
    // Uniquement quand le scan a un arret attendu. Sans arret attendu
    // (scan libre depuis la tournee), la notion n'existe pas.
    var cible = widget.expectedStop;
    if (cible != null) {
      final verdict = await checks.verifyBarcode(
        scannedBarcode: code,
        expectedStop: cible,
      );
      final suggere = verdict.suggestedStop;
      if (verdict.kind == ScanMatchKind.wrongStop && suggere != null) {
        if (!mounted) return;
        final choix = await askWrongStopChoice(
          context,
          expected: cible,
          suggested: suggere,
        );
        if (choix == WrongStopChoice.basculer) cible = suggere;
      }
    }

    // Le livreur a pu quitter l'ecran pendant les alertes : au-dela de
    // ce point on ecrit en base et on pop, donc `ref` et `context`
    // doivent encore etre vivants.
    if (!mounted) return;
    final repo = ref.read(stopsRepositoryProvider);
    Stop? matched;
    if (cible != null) {
      // Scan avec arret attendu : on rattache a cet arret (ou a celui
      // sur lequel le livreur a bascule).
      matched = cible;
    } else {
      // Scan libre : recherche d'un match dans la tournee active.
      final tournee = ref.read(currentTourneeProvider).value;
      if (tournee != null) {
        matched = await repo.findByTrackingInTournee(tournee.id, code);
      }
    }
    // Si match : on incremente directement ici, le caller n'a qu'a
    // afficher le toast. Idempotent si le tracking est deja present.
    if (matched != null) {
      await repo.incrementColisWithTracking(
        matched.id,
        trackingNumber: code,
      );
    }
    if (!mounted) return;
    Navigator.of(context).pop(
      ScanColisResult(trackingNumber: code, matchedStop: matched),
    );
  }

  /// Relance l'apercu camera apres une alerte ou le livreur a choisi de
  /// ne rien rattacher (il enchaine sur le colis suivant).
  ///
  /// `start()` peut echouer sur le terrain (permission revoquee, camera
  /// prise par une autre app, appareil qui refuse le cycle stop/start).
  /// Sans garde, l'exception remonte dans le callback `onDetect` et le
  /// livreur reste sur un apercu fige, sans message : on ferme l'ecran
  /// a la place, il n'a qu'a le rouvrir. L'alerte ne doit jamais finir
  /// en cul-de-sac.
  Future<void> _relancerCamera() async {
    try {
      await _controller.start();
    } catch (_) {
      // Redemarrage impossible : sortir vaut mieux que rester bloque.
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.6),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Scanner colis'),
        actions: [
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _controller,
            builder: (context, state, _) {
              final torchOn = state.torchState == TorchState.on;
              return IconButton(
                tooltip: torchOn ? 'Eteindre la torche' : 'Allumer la torche',
                icon: Icon(torchOn ? Icons.flash_on : Icons.flash_off),
                onPressed: () => _controller.toggleTorch(),
              );
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Viseur centre : carre transparent + bordure lime pour
          // indiquer la zone optimale ou placer le code.
          IgnorePointer(
            child: Center(
              child: Container(
                width: 260,
                height: 160,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.lime, width: 3),
                  borderRadius: BorderRadius.circular(AppRadius.r14),
                ),
              ),
            ),
          ),
          // Hint bas : explique au user qu'il faut juste viser.
          Positioned(
            left: 0,
            right: 0,
            bottom: 32,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.x14,
                  vertical: AppSpacing.x10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(AppRadius.r14),
                ),
                child: Text(
                  'Vise le code-barre du colis',
                  style: appMonoStyle(
                    fontSize: 12,
                    color: Colors.white,
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
