import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/supabase_service.dart';
import '../../theme/app_tokens.dart';

/// ════════════════════════════════════════════════════════════════
/// Ecran d'authentification cloud (Phase 2 Supabase, jalon 1).
/// ════════════════════════════════════════════════════════════════
///
/// Flow simple en 2 etapes :
/// 1. Email -> bouton "Envoyer le code"
/// 2. Code OTP 6 chiffres -> bouton "Verifier"
///
/// Pas de magic link / deep link dans ce jalon pour eviter la
/// configuration Android/iOS Universal Links. OTP par code email
/// fonctionne sans rien d'autre que le mailer Supabase (gratuit).
///
/// Affiche un avertissement si [SupabaseService.isConfigured] est
/// false (build sans --dart-define SUPABASE_URL). L'utilisateur peut
/// quand meme fermer l'ecran et continuer en mode local-only.
class CloudAuthScreen extends ConsumerStatefulWidget {
  const CloudAuthScreen({super.key});

  @override
  ConsumerState<CloudAuthScreen> createState() => _CloudAuthScreenState();
}

enum _AuthStep { askEmail, askOtp }

class _CloudAuthScreenState extends ConsumerState<CloudAuthScreen> {
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  _AuthStep _step = _AuthStep.askEmail;
  bool _busy = false;
  String? _error;
  String? _sentToEmail;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final email = _emailCtrl.text.trim();
      await SupabaseService.instance.sendOtpToEmail(email);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _step = _AuthStep.askOtp;
        _sentToEmail = email;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Erreur reseau ou serveur : $e';
      });
    }
  }

  Future<void> _verifyCode() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final user = await SupabaseService.instance.verifyOtp(
        email: _sentToEmail!,
        code: _otpCtrl.text.trim(),
      );
      if (!mounted) return;
      if (user == null) {
        setState(() {
          _busy = false;
          _error = 'Code refuse, reessaye.';
        });
        return;
      }
      Navigator.of(context).pop(true);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Erreur : $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final configured = SupabaseService.instance.isConfigured;

    return Scaffold(
      backgroundColor: p.cream,
      appBar: AppBar(
        title: const Text('Connexion cloud'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.x22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!configured) _buildNotConfiguredWarning(p),
              if (configured) ...[
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.emeraldSoft,
                    borderRadius: BorderRadius.circular(AppRadius.r22),
                  ),
                  child: const Icon(
                    Icons.cloud_outlined,
                    size: 40,
                    color: AppColors.emerald,
                  ),
                ),
                const SizedBox(height: AppSpacing.x22),
                Text(
                  _step == _AuthStep.askEmail
                      ? 'Connecte ton compte cloud'
                      : 'Verifie ton email',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: p.ink,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.x10),
                Text(
                  _step == _AuthStep.askEmail
                      ? 'On t\'enverra un code a 6 chiffres par mail. '
                          'Pas de mot de passe a retenir. Aucune CB.'
                      : 'Tu as recu un code a 6 chiffres a $_sentToEmail. '
                          'Tape-le ci-dessous (valable 1 heure).',
                  style: TextStyle(
                    fontSize: 13,
                    color: p.textMute,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.x22),
                if (_step == _AuthStep.askEmail) ..._buildEmailStep()
                else ..._buildOtpStep(),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.x14),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.x12),
                    decoration: BoxDecoration(
                      color: AppColors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppRadius.r10),
                      border: Border.all(
                        color: AppColors.red.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.red,
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildEmailStep() {
    return [
      TextField(
        controller: _emailCtrl,
        keyboardType: TextInputType.emailAddress,
        autocorrect: false,
        enableSuggestions: false,
        decoration: const InputDecoration(
          labelText: 'Adresse email',
          hintText: 'noah@example.com',
          prefixIcon: Icon(Icons.mail_outline),
        ),
      ),
      const SizedBox(height: AppSpacing.x18),
      FilledButton.icon(
        onPressed: _busy ? null : _sendCode,
        icon: _busy
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.lime,
                ),
              )
            : const Icon(Icons.send),
        label: const Text('Envoyer le code'),
      ),
    ];
  }

  List<Widget> _buildOtpStep() {
    return [
      TextField(
        controller: _otpCtrl,
        keyboardType: TextInputType.number,
        autocorrect: false,
        enableSuggestions: false,
        maxLength: 6,
        decoration: const InputDecoration(
          labelText: 'Code a 6 chiffres',
          hintText: '123456',
          prefixIcon: Icon(Icons.password),
        ),
      ),
      const SizedBox(height: AppSpacing.x10),
      FilledButton.icon(
        onPressed: _busy ? null : _verifyCode,
        icon: _busy
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.lime,
                ),
              )
            : const Icon(Icons.check),
        label: const Text('Verifier'),
      ),
      const SizedBox(height: AppSpacing.x8),
      TextButton.icon(
        onPressed: _busy
            ? null
            : () {
                setState(() {
                  _step = _AuthStep.askEmail;
                  _otpCtrl.clear();
                  _error = null;
                });
              },
        icon: const Icon(Icons.edit_outlined, size: 16),
        label: const Text('Changer d\'email'),
      ),
    ];
  }

  Widget _buildNotConfiguredWarning(AppPalette p) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x18),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.r14),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_outlined,
              color: AppColors.amber, size: 28),
          const SizedBox(height: AppSpacing.x10),
          Text(
            'Cloud pas active sur cette build',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: p.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.x6),
          Text(
            'Cette version de l\'app a ete compilee sans les credentials '
            'Supabase. Le mode local-only fonctionne normalement ; le '
            'sync cloud sera dispo dans une prochaine release.',
            style: TextStyle(
              fontSize: 13,
              color: p.textMute,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.x14),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Compris, je continue en local'),
          ),
        ],
      ),
    );
  }
}
