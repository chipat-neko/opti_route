import 'package:flutter/material.dart';

import '../data/database.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// Dialog de reordonnancement (drag & drop) pour les arrets ayant la
/// meme priorite (`obligatoire_premier` ou `obligatoire_dernier`).
///
/// Affiche en haut un titre explicite ("Ordre de livraison des arrets
/// EN 1ER") et la liste reorganisable. Au validate, retourne la liste
/// d'ids dans l'ordre choisi par le livreur ; au cancel, retourne null
/// (le caller peut alors annuler l'optimisation entiere).
class OrdrePrioriteDialog extends StatefulWidget {
  const OrdrePrioriteDialog({
    super.key,
    required this.titre,
    required this.sousTitre,
    required this.stops,
  });

  final String titre;
  final String sousTitre;
  final List<Stop> stops;

  /// Helper : ouvre le dialog si `stops.length >= 2`. Si 0 ou 1 stop,
  /// renvoie immediatement la liste d'ids telle quelle (rien a choisir).
  static Future<List<int>?> showIfNeeded(
    BuildContext context, {
    required String titre,
    required String sousTitre,
    required List<Stop> stops,
  }) async {
    if (stops.length < 2) {
      return stops.map((s) => s.id).toList();
    }
    return showDialog<List<int>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => OrdrePrioriteDialog(
        titre: titre,
        sousTitre: sousTitre,
        stops: stops,
      ),
    );
  }

  @override
  State<OrdrePrioriteDialog> createState() => _OrdrePrioriteDialogState();
}

class _OrdrePrioriteDialogState extends State<OrdrePrioriteDialog> {
  late List<Stop> _ordered;

  @override
  void initState() {
    super.initState();
    _ordered = List.of(widget.stops);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Dialog(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.r18)),
      ),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x18,
        vertical: AppSpacing.x28,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x18,
                AppSpacing.x18,
                AppSpacing.x18,
                AppSpacing.x10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.titre,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: p.ink,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x6),
                  Text(
                    widget.sousTitre,
                    style: TextStyle(
                      fontSize: 13,
                      color: p.textMute,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ReorderableListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.x12,
                  vertical: AppSpacing.x10,
                ),
                itemCount: _ordered.length,
                onReorder: _onReorder,
                buildDefaultDragHandles: false,
                itemBuilder: (context, index) {
                  final stop = _ordered[index];
                  return _ReorderTile(
                    key: ValueKey(stop.id),
                    index: index,
                    stop: stop,
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.x16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context)
                          .pop(_ordered.map((s) => s.id).toList()),
                      child: const Text('Valider l\'ordre'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      final adjusted = newIndex > oldIndex ? newIndex - 1 : newIndex;
      final item = _ordered.removeAt(oldIndex);
      _ordered.insert(adjusted, item);
    });
  }
}

class _ReorderTile extends StatelessWidget {
  const _ReorderTile({
    super.key,
    required this.index,
    required this.stop,
  });

  final int index;
  final Stop stop;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final nomRaw = stop.nomClient?.trim() ?? '';
    final hasNom = nomRaw.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x6),
      child: Container(
        decoration: BoxDecoration(
          color: p.paper,
          borderRadius: BorderRadius.circular(AppRadius.r14),
          border: Border.all(color: p.divider),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x12,
          vertical: AppSpacing.x10,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.lime,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${index + 1}',
                style: appMonoStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: p.ink,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasNom)
                    Text(
                      nomRaw,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: p.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    stop.adresseNormalisee ?? stop.adresseBrute,
                    style: TextStyle(
                      fontSize: hasNom ? 12 : 14,
                      color: hasNom ? p.textMute : p.ink,
                      fontWeight: hasNom ? FontWeight.w500 : FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.x8,
                  vertical: AppSpacing.x8,
                ),
                child: Icon(
                  Icons.drag_handle,
                  color: p.textMute,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
