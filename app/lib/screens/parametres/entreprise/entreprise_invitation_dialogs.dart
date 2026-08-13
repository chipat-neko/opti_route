import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/database.dart';
import '../../../theme/app_tokens.dart';
import '../../../widgets/snack.dart';

/// ════════════════════════════════════════════════════════════════
/// Dialogs du flux d'invitation par code 6 chiffres (#366, F27).
/// ════════════════════════════════════════════════════════════════
///
/// Extraits de `entreprise_multi_tenant_section.dart`. Les trois pièces
/// du flux, côté UI seulement (aucun appel cloud ici) :
///   - [InviteDialog] : le chef choisit la méthode (code / mail), le
///     rôle cible et l'entrepôt, et renvoie un [InviteResult] ;
///   - [CodeEmployeDialog] : affiche le code généré, copiable ;
///   - [RejoindreCodeDialog] : l'employé saisit le code reçu.
///
/// Le **rôle cible** (`roleTarget`) n'est qu'une proposition du
/// formulaire : c'est le serveur qui l'applique (et le re-valide) à
/// l'acceptation de l'invitation.

/// Résultat du dialog d'invitation (#366).
class InviteResult {
  const InviteResult({
    required this.parMail,
    required this.roleTarget,
    this.email,
    this.entrepotId,
  });
  final bool parMail; // true = mail magic link, false = code 6 chiffres
  final String roleTarget; // 'employe' | 'chef_entrepot'
  final String? email;
  final String? entrepotId;
}

/// Dialog « Inviter un employé » : méthode (code/mail), rôle, entrepôt
/// optionnel. UI simple/fonctionnelle (focus fonctions, pas le visuel).
class InviteDialog extends StatefulWidget {
  const InviteDialog({super.key, required this.entrepots});

  final List<Entrepot> entrepots;

  @override
  State<InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends State<InviteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _parMail = false;
  String _role = 'employe';
  String? _entrepotId;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  void _valider() {
    if (_parMail && !(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      InviteResult(
        parMail: _parMail,
        roleTarget: _role,
        email: _parMail ? _emailCtrl.text.trim() : null,
        entrepotId: _entrepotId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Inviter un employé'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Méthode : code ou mail
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Code')),
                ButtonSegment(value: true, label: Text('Mail')),
              ],
              selected: {_parMail},
              onSelectionChanged: (s) => setState(() => _parMail = s.first),
            ),
            const SizedBox(height: AppSpacing.x12),
            // Rôle
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(labelText: 'Rôle'),
              items: const [
                DropdownMenuItem(value: 'employe', child: Text('Employé')),
                DropdownMenuItem(
                    value: 'chef_entrepot', child: Text('Chef d\'entrepôt')),
              ],
              onChanged: (v) => setState(() => _role = v ?? 'employe'),
            ),
            const SizedBox(height: AppSpacing.x10),
            // Entrepôt optionnel
            DropdownButtonFormField<String?>(
              initialValue: _entrepotId,
              decoration:
                  const InputDecoration(labelText: 'Entrepôt (optionnel)'),
              items: [
                const DropdownMenuItem(
                    value: null, child: Text('Toute l\'entreprise')),
                for (final e in widget.entrepots)
                  DropdownMenuItem(value: e.cloudId, child: Text(e.nom)),
              ],
              onChanged: (v) => setState(() => _entrepotId = v),
            ),
            if (_parMail) ...[
              const SizedBox(height: AppSpacing.x10),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email de l\'employé',
                  hintText: 'marc@exemple.com',
                ),
                validator: (v) {
                  final s = v?.trim() ?? '';
                  if (s.isEmpty || !s.contains('@')) return 'Email invalide';
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _valider,
          child: Text(_parMail ? 'Envoyer' : 'Générer le code'),
        ),
      ],
    );
  }
}

/// Dialog qui montre le code d'invitation généré pour un employé, avec
/// un bouton « Copier ».
class CodeEmployeDialog {
  CodeEmployeDialog._();

  /// Affiche le code généré dans un dialog copiable (72h de validité).
  static Future<void> show(
    BuildContext context,
    String code, {
    String validite = '72 h',
  }) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Code d\'invitation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Donne ce code à ton employé. Il le saisira dans '
                '« Rejoindre une équipe ». Valable $validite.'),
            const SizedBox(height: AppSpacing.x16),
            SelectableText(
              code,
              style: const TextStyle(
                  fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: 4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              ctx.showInfo('Code copié');
            },
            child: const Text('Copier'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Dialog de saisie d'un code d'invitation à 6 chiffres pour rejoindre
/// une entreprise/entrepôt depuis les Paramètres (même flux que
/// l'onboarding « Qui es-tu ? »).
class RejoindreCodeDialog extends StatefulWidget {
  const RejoindreCodeDialog({super.key});

  @override
  State<RejoindreCodeDialog> createState() => _RejoindreCodeDialogState();
}

class _RejoindreCodeDialogState extends State<RejoindreCodeDialog> {
  final _ctrl = TextEditingController();
  bool _vide = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rejoindre avec un code'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Saisis le code à 6 chiffres donné par ton chef '
              '(entreprise ou entrepôt).'),
          const SizedBox(height: AppSpacing.x12),
          TextField(
            controller: _ctrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 6,
            decoration: InputDecoration(
              labelText: 'Code',
              hintText: '123456',
              errorText: _vide ? 'Code requis' : null,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () {
            final code = _ctrl.text.trim();
            if (code.isEmpty) {
              setState(() => _vide = true);
              return;
            }
            Navigator.of(context).pop(code);
          },
          child: const Text('Rejoindre'),
        ),
      ],
    );
  }
}
