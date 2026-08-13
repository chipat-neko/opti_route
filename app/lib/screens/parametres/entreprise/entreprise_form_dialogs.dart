import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_tokens.dart';

/// ════════════════════════════════════════════════════════════════
/// Dialogs de saisie « Créer mon entreprise » / « Ajouter un
/// entrepôt » (F27).
/// ════════════════════════════════════════════════════════════════
///
/// Extraits de `entreprise_multi_tenant_section.dart`. Ce sont de
/// simples formulaires : ils **valident la saisie** et renvoient un
/// résultat via `Navigator.pop`, sans jamais appeler le cloud. C'est
/// l'appelant qui décide quoi en faire (et qui gère l'état busy).

/// Résultat du dialog « Créer mon entreprise ».
class EntrepriseFormResult {
  const EntrepriseFormResult(this.nom, this.siret, this.code);
  final String nom;
  final String? siret;
  final String? code;
}

/// Formulaire de création d'entreprise : nom (requis), SIRET
/// (optionnel, 14 chiffres) et code d'activation (#374) quand
/// [requiresCode] est vrai.
class EntrepriseFormDialog extends StatefulWidget {
  const EntrepriseFormDialog({super.key, required this.requiresCode});

  /// Code maître (#374) exigé, sauf pour le super admin.
  final bool requiresCode;

  @override
  State<EntrepriseFormDialog> createState() => _EntrepriseFormDialogState();
}

class _EntrepriseFormDialogState extends State<EntrepriseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _siretCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  @override
  void dispose() {
    _nomCtrl.dispose();
    _siretCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  void _valider() {
    if (_formKey.currentState?.validate() ?? false) {
      final siret = _siretCtrl.text.trim();
      final code = _codeCtrl.text.trim();
      Navigator.of(context).pop(
        EntrepriseFormResult(
          _nomCtrl.text.trim(),
          siret.isEmpty ? null : siret,
          code.isEmpty ? null : code,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Créer mon entreprise'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nomCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nom de l\'entreprise',
                hintText: 'Ex : CALOTE Transports',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
            ),
            const SizedBox(height: AppSpacing.x8),
            TextFormField(
              controller: _siretCtrl,
              keyboardType: TextInputType.number,
              maxLength: 14,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'SIRET (optionnel)',
                hintText: '14 chiffres',
              ),
              validator: (v) {
                final s = v?.trim() ?? '';
                if (s.isEmpty) return null;
                return s.length == 14 ? null : '14 chiffres, ou laisse vide';
              },
            ),
            if (widget.requiresCode) ...[
              const SizedBox(height: AppSpacing.x8),
              TextFormField(
                controller: _codeCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Code d\'activation',
                  hintText: '6 chiffres fournis par le responsable',
                ),
                validator: (v) {
                  if (!widget.requiresCode) return null;
                  return (v == null || v.trim().isEmpty) ? 'Code requis' : null;
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
        FilledButton(onPressed: _valider, child: const Text('Créer')),
      ],
    );
  }
}

/// Résultat du dialog « Ajouter un entrepôt ».
class EntrepotFormResult {
  const EntrepotFormResult(this.nom, this.adresse);
  final String nom;
  final String? adresse;
}

/// Formulaire d'ajout d'entrepôt : nom (requis) + adresse (optionnelle).
class EntrepotFormDialog extends StatefulWidget {
  const EntrepotFormDialog({super.key});

  @override
  State<EntrepotFormDialog> createState() => _EntrepotFormDialogState();
}

class _EntrepotFormDialogState extends State<EntrepotFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _adresseCtrl = TextEditingController();

  @override
  void dispose() {
    _nomCtrl.dispose();
    _adresseCtrl.dispose();
    super.dispose();
  }

  void _valider() {
    if (_formKey.currentState?.validate() ?? false) {
      final adresse = _adresseCtrl.text.trim();
      Navigator.of(context).pop(
        EntrepotFormResult(
          _nomCtrl.text.trim(),
          adresse.isEmpty ? null : adresse,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un entrepôt'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nomCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nom de l\'entrepôt',
                hintText: 'Ex : Dépôt Chartres',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
            ),
            const SizedBox(height: AppSpacing.x8),
            TextFormField(
              controller: _adresseCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Adresse (optionnelle)',
                hintText: 'Ex : 12 rue des Lilas, 28000 Chartres',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(onPressed: _valider, child: const Text('Ajouter')),
      ],
    );
  }
}
