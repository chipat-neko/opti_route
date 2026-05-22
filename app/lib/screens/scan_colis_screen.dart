import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../data/database.dart';
import '../providers/database_providers.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

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
/// Le caller (typiquement TourneeDuJourScreen) decide de la suite :
/// toast de confirmation si +1 colis, ou navigation vers l'ecran de
/// creation d'arret si nouveau code.
class ScanColisScreen extends ConsumerStatefulWidget {
  const ScanColisScreen({super.key});

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
    // Recherche match dans la tournee active.
    final tourneeAsync = ref.read(currentTourneeProvider);
    final tournee = tourneeAsync.value;
    Stop? matched;
    if (tournee != null) {
      final repo = ref.read(stopsRepositoryProvider);
      matched = await repo.findByTrackingInTournee(tournee.id, code);
      // Si match : on incremente directement ici, le caller n'a qu'a
      // afficher le toast.
      if (matched != null) {
        await repo.incrementColisWithTracking(
          matched.id,
          trackingNumber: code,
        );
      }
    }
    if (!mounted) return;
    Navigator.of(context).pop(
      ScanColisResult(trackingNumber: code, matchedStop: matched),
    );
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
