import 'package:flutter/material.dart';

import '../../data/supplies_stock.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';

/// Panneau "Logistique" du logiciel chef :
/// - Stock fournitures (#331) : scotch, étiquettes, sacs isothermes
/// - Plan chargement 3D (#332) : préparation tournée veille
///
/// MVP : storage in-memory pour le stock (la persistance Drift suivra
/// dans une PR dédiée si Noah veut historiser). Plan 3D = bouton qui
/// dirige vers LoadingPlan3D.compute (le rendu CustomPainter futur).
class ChefLogistiquePanel extends StatefulWidget {
  const ChefLogistiquePanel({super.key});

  @override
  State<ChefLogistiquePanel> createState() => _ChefLogistiquePanelState();
}

class _ChefLogistiquePanelState extends State<ChefLogistiquePanel> {
  final List<SupplyItem> _items = [
    const SupplyItem(id: 'scotch', name: 'Scotch', currentQty: 8, minQty: 5),
    const SupplyItem(
        id: 'etiq', name: 'Étiquettes retour', currentQty: 12, minQty: 10),
    const SupplyItem(
        id: 'sac', name: 'Sacs isothermes', currentQty: 1, minQty: 3),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final attention = SuppliesStock.needAttention(_items);
    return Container(
      decoration: BoxDecoration(
        color: p.paper,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.all(AppSpacing.x16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.inventory_2_outlined, size: 20, color: p.ink),
                const SizedBox(width: AppSpacing.x8),
                Text('Logistique',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: p.ink)),
              ],
            ),
            const Divider(height: AppSpacing.x22),
            Text(
              'Stock fournitures',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: p.textMute,
                  letterSpacing: 0.5),
            ),
            const SizedBox(height: AppSpacing.x8),
            if (attention.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(AppSpacing.x10),
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.r10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_outlined,
                        color: AppColors.red, size: 18),
                    const SizedBox(width: AppSpacing.x6),
                    Expanded(
                      child: Text(
                        '${attention.length} fourniture(s) à recommander',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.x8),
            for (final item in _items) _SupplyRow(item: item),
            const SizedBox(height: AppSpacing.x16),
            Text(
              'Préparation tournée',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: p.textMute,
                  letterSpacing: 0.5),
            ),
            const SizedBox(height: AppSpacing.x6),
            OutlinedButton.icon(
              onPressed: () => _showLoadingPlanInfo(context),
              icon: const Icon(Icons.view_in_ar_outlined, size: 18),
              label: const Text('Plan chargement 3D'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44)),
            ),
          ],
        ),
      ),
    );
  }

  void _showLoadingPlanInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Plan chargement 3D'),
        content: const Text(
            'LoadingPlan3D.compute place chaque colis selon (fragile/lourd) '
            '+ ordre livraison (avant/milieu/fond). Rendu CustomPainter à wire '
            'dans une future PR à partir d\'une tournée sélectionnée.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK')),
        ],
      ),
    );
  }
}

class _SupplyRow extends StatelessWidget {
  const _SupplyRow({required this.item});

  final SupplyItem item;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = switch (item.alertLevel) {
      3 => AppColors.red,
      2 => AppColors.amber,
      1 => AppColors.amber,
      _ => p.textMute,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x4),
      child: Row(
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: AppSpacing.x8),
          Expanded(child: Text(item.name, style: TextStyle(color: p.ink))),
          Text('${item.currentQty}',
              style: appMonoStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
