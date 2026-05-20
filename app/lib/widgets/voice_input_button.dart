import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../theme/app_tokens.dart';

/// ════════════════════════════════════════════════════════════════
/// Bouton micro qui dicte une adresse (ou tout texte) dans un champ.
/// ════════════════════════════════════════════════════════════════
///
/// Inspire de Spoke route planner (https://spoke.com/route-planner) :
/// "Speak, search, or scan to add stops" mains-libres au volant.
///
/// Tap = demarre l'ecoute (Google Speech on-device, gratuit). Affiche
/// un IconButton qui passe rouge + anime pendant l'ecoute. Le texte
/// reconnu est propage via [onResult] des la fin de la dictee
/// (silence > 1.5s ou nouveau tap).
///
/// Permissions micro : auto-demandees au 1er tap par le plugin
/// speech_to_text. Si refusees, SnackBar explicatif.
///
/// Sur web (Chrome), utilise l'API Web Speech native (gratuite aussi).
/// Sur iOS, Speech framework natif Apple. Aucun service externe, zero
/// cle API, zero quota.
class VoiceInputButton extends StatefulWidget {
  const VoiceInputButton({
    super.key,
    required this.onResult,
    this.localeId = 'fr_FR',
    this.tooltip = 'Dicter l\'adresse',
  });

  /// Appele a la fin de la dictee avec le texte reconnu (non vide).
  /// Le caller decide quoi en faire (remplir un TextField, lancer
  /// l'autocomplete, etc.).
  final ValueChanged<String> onResult;

  /// Code locale (ex: 'fr_FR', 'en_US'). Determine la langue de
  /// reconnaissance. Default fr_FR pour Noah.
  final String localeId;

  final String tooltip;

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton> {
  final _speech = stt.SpeechToText();
  bool _initialized = false;
  bool _listening = false;
  String _transcript = '';

  @override
  void dispose() {
    if (_listening) _speech.stop();
    super.dispose();
  }

  /// Initialise le plugin (1ere fois seulement). Le plugin demande
  /// la permission micro automatiquement au 1er appel.
  Future<bool> _ensureInit() async {
    if (_initialized) return true;
    final ok = await _speech.initialize(
      onError: (e) {
        debugPrint('[VoiceInput] error: ${e.errorMsg}');
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _listening = false);
        }
      },
    );
    _initialized = ok;
    return ok;
  }

  Future<void> _toggle() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      if (_transcript.isNotEmpty) widget.onResult(_transcript);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final ok = await _ensureInit();
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Reconnaissance vocale indisponible '
            '(permission micro refusee ?).',
          ),
        ),
      );
      return;
    }
    _transcript = '';
    if (!mounted) return;
    setState(() => _listening = true);
    await _speech.listen(
      onResult: (r) {
        _transcript = r.recognizedWords;
        if (r.finalResult && mounted) {
          setState(() => _listening = false);
          if (_transcript.isNotEmpty) widget.onResult(_transcript);
        }
      },
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
        localeId: widget.localeId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return IconButton(
      icon: Icon(
        _listening ? Icons.mic : Icons.mic_none_outlined,
        color: _listening ? AppColors.red : p.ink,
      ),
      tooltip: _listening ? 'Arreter la dictee' : widget.tooltip,
      onPressed: _toggle,
    );
  }
}

/// Variante en OutlinedButton.icon, taille bouton 48 px (matche les
/// boutons "Scanner" / "Hors ligne" de l'ecran d'ajout d'arret).
/// Quand l'ecoute est active, le bouton passe rouge avec le label
/// "Ecoute..." pour signaler clairement l'etat au user.
class VoiceInputButtonOutlined extends StatefulWidget {
  const VoiceInputButtonOutlined({
    super.key,
    required this.onResult,
    this.localeId = 'fr_FR',
  });

  final ValueChanged<String> onResult;
  final String localeId;

  @override
  State<VoiceInputButtonOutlined> createState() =>
      _VoiceInputButtonOutlinedState();
}

class _VoiceInputButtonOutlinedState extends State<VoiceInputButtonOutlined> {
  final _speech = stt.SpeechToText();
  bool _initialized = false;
  bool _listening = false;
  String _transcript = '';

  @override
  void dispose() {
    if (_listening) _speech.stop();
    super.dispose();
  }

  Future<bool> _ensureInit() async {
    if (_initialized) return true;
    final ok = await _speech.initialize(
      onError: (e) => debugPrint('[VoiceInput] error: ${e.errorMsg}'),
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _listening = false);
        }
      },
    );
    _initialized = ok;
    return ok;
  }

  Future<void> _toggle() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      if (_transcript.isNotEmpty) widget.onResult(_transcript);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final ok = await _ensureInit();
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Reconnaissance vocale indisponible '
            '(permission micro refusee ?).',
          ),
        ),
      );
      return;
    }
    _transcript = '';
    if (!mounted) return;
    setState(() => _listening = true);
    await _speech.listen(
      onResult: (r) {
        _transcript = r.recognizedWords;
        if (r.finalResult && mounted) {
          setState(() => _listening = false);
          if (_transcript.isNotEmpty) widget.onResult(_transcript);
        }
      },
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
        localeId: widget.localeId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _toggle,
      icon: Icon(
        _listening ? Icons.mic : Icons.mic_none_outlined,
        color: _listening ? AppColors.red : null,
      ),
      label: Text(_listening ? 'Ecoute...' : 'Dicter'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        foregroundColor: _listening ? AppColors.red : null,
        side: _listening
            ? const BorderSide(color: AppColors.red, width: 1.5)
            : null,
      ),
    );
  }
}
