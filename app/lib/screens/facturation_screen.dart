import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/cloud_error_humanizer.dart';
import '../data/facturation_service.dart';
import '../providers/database_providers.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// Ecran de facturation mensuelle indicative.
///
/// Entree : periode (date debut + date fin) + tarifs (par arret /
/// par colis / au km). Sortie : recap chiffres (nb tournees, arrets
/// livres, colis, km, cout carburant, total facturable HT, marge
/// brute estimee).
///
/// Note importante : ce n'est PAS une facture officielle (pas de TVA,
/// pas d'IBAN, pas de mentions legales). C'est un outil d'aide a la
/// negociation tarifaire et au pilotage de marge.
class FacturationScreen extends ConsumerStatefulWidget {
  const FacturationScreen({super.key});

  @override
  ConsumerState<FacturationScreen> createState() =>
      _FacturationScreenState();
}

class _FacturationScreenState extends ConsumerState<FacturationScreen> {
  late DateTime _since;
  late DateTime _until;
  final _tarifArretCtrl = TextEditingController(text: '1.50');
  final _tarifColisCtrl = TextEditingController(text: '0.30');
  final _tarifKmCtrl = TextEditingController(text: '0.50');
  FactureMensuelle? _facture;
  bool _calculating = false;

  @override
  void initState() {
    super.initState();
    // Defaut : mois en cours.
    final now = DateTime.now();
    _since = DateTime(now.year, now.month, 1);
    _until = DateTime(now.year, now.month + 1, 1);
  }

  @override
  void dispose() {
    _tarifArretCtrl.dispose();
    _tarifColisCtrl.dispose();
    _tarifKmCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      initialDateRange: DateTimeRange(start: _since, end: _until),
      locale: const Locale('fr', 'FR'),
    );
    if (picked == null) return;
    setState(() {
      _since = picked.start;
      _until = picked.end;
    });
  }

  Future<void> _calculer() async {
    setState(() => _calculating = true);
    final tarifArret = double.tryParse(
        _tarifArretCtrl.text.replaceAll(',', '.'),
    );
    final tarifColis = double.tryParse(
        _tarifColisCtrl.text.replaceAll(',', '.'),
    );
    final tarifKm = double.tryParse(
        _tarifKmCtrl.text.replaceAll(',', '.'),
    );
    try {
      final db = ref.read(appDatabaseProvider);
      final params = ref.read(parametresRepositoryProvider);
      final svc = FacturationService(db, params);
      final f = await svc.calculer(
        since: _since,
        until: _until,
        tarifParArretEur: tarifArret,
        tarifParColisEur: tarifColis,
        tarifKilometriqueEur: tarifKm,
      );
      if (!mounted) return;
      setState(() {
        _facture = f;
        _calculating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _calculating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur calcul : ${humanizeAnyError(e)}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final df = DateFormat('d MMM yyyy', 'fr');

    return Scaffold(
      appBar: AppBar(title: const Text('Facturation')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.x18),
        children: [
          // Header explicatif
          Container(
            padding: const EdgeInsets.all(AppSpacing.x14),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppRadius.r14),
              border: Border.all(
                color: AppColors.amber.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_outlined,
                    color: AppColors.amber, size: 18),
                const SizedBox(width: AppSpacing.x8),
                Expanded(
                  child: Text(
                    'Recap indicatif pour negociation tarifaire. '
                    'PAS une facture officielle (sans TVA, sans mentions '
                    'legales). Pour la vraie facturation, exporte en '
                    'CSV et passe par ton outil compta.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: p.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x22),

          // Periode
          const _SectionTitle('Periode'),
          const SizedBox(height: AppSpacing.x8),
          OutlinedButton.icon(
            onPressed: _pickRange,
            icon: const Icon(Icons.date_range_outlined),
            label: Text(
              '${df.format(_since)}  →  ${df.format(_until.subtract(const Duration(days: 1)))}',
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              alignment: Alignment.centerLeft,
            ),
          ),
          const SizedBox(height: AppSpacing.x22),

          // Tarifs
          const _SectionTitle('Tarifs HT'),
          const SizedBox(height: AppSpacing.x8),
          Text(
            'Au moins un des trois est requis. Tous les autres peuvent '
            'rester a 0 si tu ne factures qu\'un seul critere.',
            style: TextStyle(
              fontSize: 12.5,
              color: p.textMute,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.x10),
          _TarifField(
            label: 'EUR par arret livre',
            controller: _tarifArretCtrl,
            icon: Icons.location_on_outlined,
          ),
          const SizedBox(height: AppSpacing.x10),
          _TarifField(
            label: 'EUR par colis livre',
            controller: _tarifColisCtrl,
            icon: Icons.inventory_2_outlined,
          ),
          const SizedBox(height: AppSpacing.x10),
          _TarifField(
            label: 'EUR par km parcouru',
            controller: _tarifKmCtrl,
            icon: Icons.straighten_outlined,
          ),
          const SizedBox(height: AppSpacing.x22),

          FilledButton.icon(
            onPressed: _calculating ? null : _calculer,
            icon: _calculating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.lime,
                    ),
                  )
                : const Icon(Icons.calculate_outlined),
            label: const Text('Calculer le recap facturable'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),

          // Resultat
          if (_facture != null) ...[
            const SizedBox(height: AppSpacing.x22),
            const _SectionTitle('Resultat'),
            const SizedBox(height: AppSpacing.x10),
            _FactureRecap(facture: _facture!),
          ],
        ],
      ),
    );
  }
}

class _TarifField extends StatelessWidget {
  const _TarifField({
    required this.label,
    required this.controller,
    required this.icon,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixText: 'EUR',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: appMonoStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: context.palette.textMute,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _FactureRecap extends StatelessWidget {
  const _FactureRecap({required this.facture});
  final FactureMensuelle facture;

  static String _eur(double v) {
    final cents = (v * 100).round();
    return '${(cents ~/ 100).toString()},${(cents % 100).toString().padLeft(2, '0')} EUR';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (facture.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.x18),
        decoration: BoxDecoration(
          color: p.paper,
          borderRadius: BorderRadius.circular(AppRadius.r14),
          border: Border.all(color: p.divider),
        ),
        child: Row(
          children: [
            Icon(Icons.inbox_outlined, color: p.textMute),
            const SizedBox(width: AppSpacing.x10),
            Expanded(
              child: Text(
                'Aucune tournee terminee sur cette periode.',
                style: TextStyle(color: p.textMute),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.x18),
      decoration: BoxDecoration(
        color: p.paper,
        borderRadius: BorderRadius.circular(AppRadius.r18),
        border: Border.all(color: p.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats brutes
          _row(p, 'Tournees terminees', '${facture.nbTournees}'),
          _row(p, 'Arrets livres', '${facture.nbArretsLivres}'),
          _row(p, 'Colis livres', '${facture.nbColisLivres}'),
          _row(p, 'Km parcourus', '${facture.kmTotal.toStringAsFixed(1)} km'),
          const Divider(height: AppSpacing.x18),
          // Montants
          if (facture.mtArrets > 0)
            _row(p, 'Mt arrets', _eur(facture.mtArrets), accent: false),
          if (facture.mtColis > 0)
            _row(p, 'Mt colis', _eur(facture.mtColis), accent: false),
          if (facture.mtKm > 0)
            _row(p, 'Mt km', _eur(facture.mtKm), accent: false),
          const Divider(height: AppSpacing.x18),
          _row(p, 'TOTAL HT facturable', _eur(facture.totalHt),
              accent: true),
          const SizedBox(height: AppSpacing.x8),
          _row(p, 'Cout carburant estime', '-${_eur(facture.coutCarburantEur)}',
              accent: false, danger: true),
          _row(
            p,
            'Marge brute estimee',
            _eur(facture.margeBruteEstimee),
            accent: true,
            danger: facture.margeBruteEstimee < 0,
          ),
        ],
      ),
    );
  }

  Widget _row(
    AppPalette p,
    String label,
    String value, {
    bool accent = false,
    bool danger = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: accent ? 13 : 12,
                fontWeight: accent ? FontWeight.w800 : FontWeight.w500,
                color: accent ? p.ink : p.textMute,
              ),
            ),
          ),
          Text(
            value,
            style: appMonoStyle(
              fontSize: accent ? 15 : 13,
              fontWeight: FontWeight.w800,
              color: danger
                  ? AppColors.red
                  : accent
                      ? AppColors.emerald
                      : p.ink,
            ),
          ),
        ],
      ),
    );
  }
}
