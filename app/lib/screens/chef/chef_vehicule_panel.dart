import 'package:flutter/material.dart';

import '../../data/incident_report.dart';
import '../../data/maintenance_alerts.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';

/// Panneau "Véhicule" du logiciel chef :
/// - Alertes entretien (#316) : vidange / CT / pneus hiver
/// - Constat sinistre (#334) : génération PDF
///
/// MVP : pas de table Drift entretien dédiée — les seuils sont
/// calculés depuis le compteur km fourni par le chef en saisie libre
/// (ou par un futur lien direct avec un odo cumulé). Ici on prend
/// `0` km par défaut + un bouton "Mettre à jour le compteur".
class ChefVehiculePanel extends StatefulWidget {
  const ChefVehiculePanel({super.key});

  @override
  State<ChefVehiculePanel> createState() => _ChefVehiculePanelState();
}

class _ChefVehiculePanelState extends State<ChefVehiculePanel> {
  int _currentKm = 0;
  int? _lastVidangeKm;
  DateTime? _firstRegistration;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final alerts = MaintenanceAlerts.compute(
      currentOdometerKm: _currentKm,
      now: DateTime.now(),
      lastVidangeOdometerKm: _lastVidangeKm,
      firstRegistrationDate: _firstRegistration,
    );
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
                Icon(Icons.directions_car_outlined, size: 20, color: p.ink),
                const SizedBox(width: AppSpacing.x8),
                Text('Véhicule',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: p.ink)),
              ],
            ),
            const Divider(height: AppSpacing.x22),
            OutlinedButton.icon(
              onPressed: _editKmDialog,
              icon: const Icon(Icons.straighten, size: 18),
              label: Text('Compteur km : $_currentKm'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44)),
            ),
            const SizedBox(height: AppSpacing.x12),
            if (alerts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.x12),
                child: Text(
                  'Aucune alerte d\'entretien active.',
                  style: TextStyle(fontSize: 13, color: p.textMute),
                  textAlign: TextAlign.center,
                ),
              )
            else
              for (final a in alerts) _AlertRow(alert: a),
            const SizedBox(height: AppSpacing.x16),
            OutlinedButton.icon(
              onPressed: () => _composeSinistre(context),
              icon: const Icon(Icons.warning_amber_outlined, size: 18),
              label: const Text('Préparer constat amiable'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editKmDialog() async {
    final ctrl = TextEditingController(text: _currentKm.toString());
    final ctrlVidange = TextEditingController(
        text: _lastVidangeKm == null ? '' : _lastVidangeKm.toString());
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mettre à jour le compteur'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Km actuels'),
            ),
            TextField(
              controller: ctrlVidange,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Km derniere vidange (optionnel)'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler')),
          FilledButton(
            onPressed: () {
              setState(() {
                _currentKm = int.tryParse(ctrl.text) ?? _currentKm;
                _lastVidangeKm = int.tryParse(ctrlVidange.text);
              });
              Navigator.of(context).pop();
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  Future<void> _composeSinistre(BuildContext context) async {
    final body = IncidentReport.compose(
      kind: IncidentKind.accrochage,
      when: DateTime.now(),
    );
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Constat amiable'),
        content: SingleChildScrollView(
          child: SelectableText(body,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer')),
        ],
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({required this.alert});

  final MaintenanceAlert alert;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (icon, label) = switch (alert.kind) {
      MaintenanceKind.vidange => (Icons.opacity, 'Vidange'),
      MaintenanceKind.courroie =>
        (Icons.settings_input_component_outlined, 'Courroie'),
      MaintenanceKind.controlTechnique => (Icons.verified_outlined, 'CT'),
      MaintenanceKind.pneusHiver =>
        (Icons.ac_unit, 'Pneus hiver'),
    };
    final due = alert.dueInKm != null
        ? '${alert.dueInKm} km'
        : alert.dueInDays != null
            ? '${alert.dueInDays} j'
            : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x6),
      child: Row(
        children: [
          Icon(icon,
              size: 18,
              color: alert.isOverdue ? AppColors.red : AppColors.amber),
          const SizedBox(width: AppSpacing.x8),
          Expanded(child: Text(label, style: TextStyle(color: p.ink))),
          Text(due,
              style: appMonoStyle(
                  fontSize: 12,
                  color: alert.isOverdue ? AppColors.red : p.textMute)),
        ],
      ),
    );
  }
}
