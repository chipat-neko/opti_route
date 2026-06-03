import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/preuve_photo_service.dart';
import '../providers/database_providers.dart';
import '../theme/app_tokens.dart';

/// ════════════════════════════════════════════════════════════════
/// Pad de signature du destinataire (demande Noah 2026-06-03).
/// ════════════════════════════════════════════════════════════════
///
/// Affiché (optionnellement) au moment du « Marquer livré ». Le
/// destinataire signe au doigt ; on capture le tracé en PNG. 100 % local,
/// aucune dépendance externe (CustomPaint + RepaintBoundary.toImage).
///
/// [show] retourne les octets PNG si l'utilisateur valide une signature,
/// ou `null` s'il passe / annule / ne dessine rien (la signature est
/// FACULTATIVE : on ne bloque jamais la livraison).
class SignaturePadDialog extends StatefulWidget {
  const SignaturePadDialog({super.key, required this.titre});

  final String titre;

  static Future<Uint8List?> show(BuildContext context, {String? titre}) {
    return showDialog<Uint8List?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SignaturePadDialog(
        titre: titre ?? 'Signature du destinataire',
      ),
    );
  }

  @override
  State<SignaturePadDialog> createState() => _SignaturePadDialogState();
}

class _SignaturePadDialogState extends State<SignaturePadDialog> {
  final GlobalKey _boundaryKey = GlobalKey();
  // Liste de points ; `null` marque une rupture de trait (lever du doigt).
  final List<Offset?> _points = <Offset?>[];

  bool get _hasInk => _points.any((p) => p != null);

  void _addPoint(Offset? p) => setState(() => _points.add(p));

  void _clear() => setState(_points.clear);

  Future<Uint8List?> _capturePng() async {
    final ctx = _boundaryKey.currentContext;
    if (ctx == null) return null;
    final boundary = ctx.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 2.5);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Dialog(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.r18)),
      ),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x16,
        vertical: AppSpacing.x22,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.titre,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: p.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.x4),
            Text(
              'Fais signer le destinataire ci-dessous (facultatif).',
              style: TextStyle(fontSize: 12.5, color: p.textMute),
            ),
            const SizedBox(height: AppSpacing.x12),
            // Zone de signature : fond blanc (la capture PNG sera donc
            // lisible quel que soit le thème de l'app).
            RepaintBoundary(
              key: _boundaryKey,
              child: Container(
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                  border: Border.all(color: p.inkLine),
                ),
                clipBehavior: Clip.antiAlias,
                child: GestureDetector(
                  // opaque : sans ça le CustomPaint (sans child) n'est pas
                  // hit-testable et AUCUN geste n'est capté -> impossible de
                  // dessiner. C'est LE point qui bloquait le canva.
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (d) => _addPoint(d.localPosition),
                  onPanUpdate: (d) => _addPoint(d.localPosition),
                  onPanEnd: (_) => _addPoint(null),
                  child: CustomPaint(
                    painter: _SignaturePainter(_points),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.x10),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _hasInk ? _clear : null,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Effacer'),
                ),
                const Spacer(),
                TextButton(
                  // « Passer » : signature non obligatoire.
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('Passer'),
                ),
                const SizedBox(width: AppSpacing.x8),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.emerald,
                    foregroundColor: p.paper,
                  ),
                  onPressed: _hasInk
                      ? () async {
                          final png = await _capturePng();
                          if (context.mounted) Navigator.of(context).pop(png);
                        }
                      : null,
                  child: const Text('Valider'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  _SignaturePainter(this.points);
  final List<Offset?> points;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5;
    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      if (a != null && b != null) {
        canvas.drawLine(a, b, paint);
      } else if (a != null && b == null) {
        // Point isolé (simple tap) : dessine un petit rond.
        canvas.drawCircle(a, 1.4, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_SignaturePainter old) => old.points.length != points.length;
}

/// Affiche le pad de signature pour [stopId] et, si une signature est
/// validée, l'enregistre (PNG local) + met à jour `stops.signaturePath`.
/// Si l'utilisateur passe (signature facultative), ne fait rien.
/// Best-effort : n'échoue jamais (la livraison est déjà validée en amont).
Future<void> captureSignatureForStop(
  BuildContext context,
  WidgetRef ref,
  int stopId,
) async {
  final png = await SignaturePadDialog.show(context);
  if (png == null) return;
  try {
    final path = await PreuvePhotoService().saveSignature(
      stopId: stopId,
      png: png,
    );
    if (path != null) {
      await ref.read(stopsRepositoryProvider).setSignature(stopId, path);
    }
  } catch (_) {
    // best-effort : la livraison reste valide même si la sauvegarde échoue.
  }
}
