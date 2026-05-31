import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../providers/database_providers.dart';
import '../theme/app_tokens.dart';

/// Panneau "Options livraison" qui regroupe les 4 champs Drift ajoutes
/// recemment sans UI (sprint immediat 2026-05-31, audit #337) :
///
/// - **memoVocal** (#280) : memo libre (saisie clavier ; dictee STT
///   reportee a une PR ulterieure, infra speech_to_text deja en deps)
/// - **deposeSansContact** (#287) : toggle "Depose devant la porte"
/// - **montantCod + codPaye** (#296) : montant + case encaissee
/// - **notationEmoji** (#324) : 3 boutons happy/neutral/angry, visibles
///   uniquement si statut=livre
///
/// Affiche sous forme d'ExpansionTile replie par defaut (pour ne pas
/// alourdir la sheet pour les livraisons standard). Le tile est ouvert
/// automatiquement si l'un des champs a deja une valeur.
class StopExtrasPanel extends ConsumerStatefulWidget {
  const StopExtrasPanel({super.key, required this.stop});

  final Stop stop;

  @override
  ConsumerState<StopExtrasPanel> createState() => _StopExtrasPanelState();
}

class _StopExtrasPanelState extends ConsumerState<StopExtrasPanel> {
  late final TextEditingController _memoCtrl;
  late final TextEditingController _codCtrl;
  Timer? _memoDebounce;
  Timer? _codDebounce;

  @override
  void initState() {
    super.initState();
    _memoCtrl = TextEditingController(text: widget.stop.memoVocal ?? '');
    _codCtrl = TextEditingController(
      text: widget.stop.montantCod == null
          ? ''
          : widget.stop.montantCod!.toStringAsFixed(2).replaceAll('.', ','),
    );
  }

  @override
  void dispose() {
    _memoDebounce?.cancel();
    _codDebounce?.cancel();
    _memoCtrl.dispose();
    _codCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveMemo(String value) async {
    final repo = ref.read(stopsRepositoryProvider);
    await repo.setMemoVocal(widget.stop.id, value);
  }

  Future<void> _saveCodMontant(String value) async {
    final cleaned = value.trim().replaceAll(',', '.').replaceAll(' ', '');
    final montant = cleaned.isEmpty ? null : double.tryParse(cleaned);
    final repo = ref.read(stopsRepositoryProvider);
    await repo.setMontantCod(widget.stop.id, montant);
  }

  Future<void> _toggleCodPaye(bool? value) async {
    if (value == null) return;
    final repo = ref.read(stopsRepositoryProvider);
    await repo.setCodPaye(widget.stop.id, value);
  }

  Future<void> _toggleDeposeSansContact(bool? value) async {
    if (value == null) return;
    final repo = ref.read(stopsRepositoryProvider);
    await repo.setDeposeSansContact(widget.stop.id, value);
  }

  Future<void> _setNotation(String? emoji) async {
    final repo = ref.read(stopsRepositoryProvider);
    final current = widget.stop.notationEmoji;
    // Toggle : retap sur la meme valeur = clear
    await repo.setNotationEmoji(
        widget.stop.id, current == emoji ? null : emoji);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final stop = widget.stop;
    final hasAnyValue = (stop.memoVocal?.isNotEmpty ?? false) ||
        stop.deposeSansContact ||
        stop.montantCod != null ||
        stop.notationEmoji != null;
    final isLivre = stop.statutLivraison == 'livre';

    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
      ),
      child: ExpansionTile(
        initiallyExpanded: hasAnyValue,
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(
          top: AppSpacing.x8,
          bottom: AppSpacing.x4,
        ),
        leading: Icon(Icons.tune, size: 20, color: p.ink),
        title: Text(
          'Options livraison',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: p.ink,
          ),
        ),
        subtitle: hasAnyValue
            ? Text(
                _summary(stop),
                style: TextStyle(fontSize: 11, color: p.textMute),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        children: [
          // === Memo vocal (texte libre pour l'instant) ===
          _SectionLabel(label: 'Memo', icon: Icons.notes),
          TextField(
            controller: _memoCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Code interphone, etage, consigne...',
              hintStyle: TextStyle(color: p.textFaint, fontSize: 13),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.r10),
              ),
            ),
            onChanged: (v) {
              _memoDebounce?.cancel();
              _memoDebounce = Timer(
                  const Duration(milliseconds: 600), () => _saveMemo(v));
            },
          ),

          const SizedBox(height: AppSpacing.x12),

          // === Depose sans contact ===
          CheckboxListTile(
            value: stop.deposeSansContact,
            onChanged: _toggleDeposeSansContact,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
              'Depose sans contact',
              style: TextStyle(fontSize: 13, color: p.ink),
            ),
            subtitle: Text(
              'Colis depose devant la porte / boite',
              style: TextStyle(fontSize: 11, color: p.textMute),
            ),
            dense: true,
          ),

          // === COD (contre-remboursement) ===
          _SectionLabel(label: 'Contre-remboursement (COD)', icon: Icons.euro),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: false),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                  ],
                  decoration: InputDecoration(
                    hintText: 'Montant',
                    suffixText: '€',
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.r10),
                    ),
                  ),
                  onChanged: (v) {
                    _codDebounce?.cancel();
                    _codDebounce = Timer(
                        const Duration(milliseconds: 600),
                        () => _saveCodMontant(v));
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.x10),
              Flexible(
                child: CheckboxListTile(
                  value: stop.codPaye,
                  onChanged: stop.montantCod == null ? null : _toggleCodPaye,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    'Encaisse',
                    style: TextStyle(fontSize: 13, color: p.ink),
                  ),
                  dense: true,
                ),
              ),
            ],
          ),

          // === Notation emoji (uniquement si statut=livre) ===
          if (isLivre) ...[
            _SectionLabel(
                label: 'Notation client', icon: Icons.sentiment_satisfied),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _EmojiButton(
                    emoji: '😊',
                    label: 'Content',
                    selected: stop.notationEmoji == 'happy',
                    onTap: () => _setNotation('happy')),
                _EmojiButton(
                    emoji: '😐',
                    label: 'Neutre',
                    selected: stop.notationEmoji == 'neutral',
                    onTap: () => _setNotation('neutral')),
                _EmojiButton(
                    emoji: '😡',
                    label: 'Mecontent',
                    selected: stop.notationEmoji == 'angry',
                    onTap: () => _setNotation('angry')),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _summary(Stop stop) {
    final parts = <String>[];
    if (stop.memoVocal?.isNotEmpty ?? false) parts.add('memo');
    if (stop.deposeSansContact) parts.add('sans contact');
    if (stop.montantCod != null) {
      parts.add(
          '${stop.montantCod!.toStringAsFixed(0)} € ${stop.codPaye ? "OK" : "a encaisser"}');
    }
    if (stop.notationEmoji != null) {
      parts.add(switch (stop.notationEmoji) {
        'happy' => '😊',
        'neutral' => '😐',
        'angry' => '😡',
        _ => '',
      });
    }
    return parts.join(' · ');
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.x10, bottom: AppSpacing.x6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: p.textMute),
          const SizedBox(width: AppSpacing.x6),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w800,
              color: p.textMute,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmojiButton extends StatelessWidget {
  const _EmojiButton({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.r12),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x12, vertical: AppSpacing.x8),
        decoration: BoxDecoration(
          color: selected ? AppColors.lime.withValues(alpha: 0.3) : null,
          borderRadius: BorderRadius.circular(AppRadius.r12),
          border: Border.all(
            color: selected ? AppColors.lime : p.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: p.textMute,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
