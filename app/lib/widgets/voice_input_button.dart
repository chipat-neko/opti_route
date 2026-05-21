import 'package:flutter/foundation.dart' show ValueListenable;
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
/// Pendant l'ecoute, un overlay flottant s'affiche en bas d'ecran avec
/// le texte partiel reconnu en LIVE (mis a jour a chaque mot). Permet
/// au user de verifier ce qui est compris avant de relacher, plutot
/// que d'attendre la fin pour decouvrir une erreur. Style "live caption".
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

class _VoiceInputButtonState extends State<VoiceInputButton>
    with _VoiceListenMixin {
  @override
  String get _localeId => widget.localeId;

  @override
  void _onFinalResult(String transcript) => widget.onResult(transcript);

  @override
  void _onCannotInit() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Reconnaissance vocale indisponible '
          '(permission micro refusee ?).',
        ),
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
      onPressed: _toggleListening,
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

class _VoiceInputButtonOutlinedState extends State<VoiceInputButtonOutlined>
    with _VoiceListenMixin {
  @override
  String get _localeId => widget.localeId;

  @override
  void _onFinalResult(String transcript) => widget.onResult(transcript);

  @override
  void _onCannotInit() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Reconnaissance vocale indisponible '
          '(permission micro refusee ?).',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _toggleListening,
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

/// Mixin partage entre les 2 variantes du bouton vocal : encapsule
/// l'init speech_to_text, le toggle listen/stop, et l'affichage de
/// l'overlay live "caption" qui montre le texte partiel a chaque mot
/// reconnu.
///
/// Les classes qui mixin doivent implementer :
///   - [_localeId] : la locale (ex: 'fr_FR')
///   - [_onFinalResult] : callback final avec le texte complet
///   - [_onCannotInit] : message d'erreur si l'init speech echoue
///     (typiquement un SnackBar)
mixin _VoiceListenMixin<T extends StatefulWidget> on State<T> {
  final _speech = stt.SpeechToText();
  bool _initialized = false;
  bool _listening = false;
  String _transcript = '';

  // Overlay live "caption" : affiche le texte partiel pendant la dictee.
  OverlayEntry? _overlayEntry;
  final ValueNotifier<String> _liveTranscript = ValueNotifier<String>('');

  String get _localeId;
  void _onFinalResult(String transcript);
  void _onCannotInit();

  @override
  void dispose() {
    if (_listening) _speech.stop();
    _hideOverlay();
    _liveTranscript.dispose();
    super.dispose();
  }

  Future<bool> _ensureInit() async {
    if (_initialized) return true;
    final ok = await _speech.initialize(
      onError: (e) => debugPrint('[VoiceInput] error: ${e.errorMsg}'),
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) {
            setState(() => _listening = false);
            _hideOverlay();
          }
        }
      },
    );
    _initialized = ok;
    return ok;
  }

  Future<void> _toggleListening() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      _hideOverlay();
      if (_transcript.isNotEmpty) _onFinalResult(_transcript);
      return;
    }
    final ok = await _ensureInit();
    if (!ok) {
      if (mounted) _onCannotInit();
      return;
    }
    _transcript = '';
    _liveTranscript.value = '';
    if (!mounted) return;
    setState(() => _listening = true);
    _showOverlay();
    await _speech.listen(
      onResult: (r) {
        _transcript = r.recognizedWords;
        _liveTranscript.value = r.recognizedWords;
        if (r.finalResult && mounted) {
          setState(() => _listening = false);
          _hideOverlay();
          if (_transcript.isNotEmpty) _onFinalResult(_transcript);
        }
      },
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
        localeId: _localeId,
      ),
    );
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;
    final overlay = Overlay.of(context, rootOverlay: true);
    _overlayEntry = OverlayEntry(
      builder: (_) => _VoiceLiveOverlay(
        transcript: _liveTranscript,
        onCancel: () async {
          await _speech.stop();
          if (mounted) setState(() => _listening = false);
          _hideOverlay();
          // On NE PROPAGE PAS le transcript au cancel : intention
          // explicite "annuler la dictee".
        },
      ),
    );
    overlay.insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

/// Overlay "live caption" affiche en bas de l'ecran pendant la dictee
/// vocale. Montre le texte partiel reconnu mis a jour a chaque mot,
/// avec un indicateur d'ecoute anime (pulse lime) et un bouton "X"
/// pour annuler la dictee sans la valider.
///
/// Position : SafeArea bottom + padding 18px pour ne pas chevaucher
/// les FAB / boutons systeme. Material elevation 12 pour flotter
/// au-dessus de tout. Layout responsive : 92% de la largeur d'ecran.
class _VoiceLiveOverlay extends StatelessWidget {
  const _VoiceLiveOverlay({
    required this.transcript,
    required this.onCancel,
  });

  final ValueListenable<String> transcript;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: MediaQuery.of(context).viewInsets.bottom +
          MediaQuery.of(context).padding.bottom +
          16,
      child: SafeArea(
        top: false,
        left: false,
        right: false,
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(AppRadius.r18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.x16,
              AppSpacing.x14,
              AppSpacing.x10,
              AppSpacing.x14,
            ),
            child: Row(
              children: [
                const _PulseDot(),
                const SizedBox(width: AppSpacing.x12),
                Expanded(
                  child: ValueListenableBuilder<String>(
                    valueListenable: transcript,
                    builder: (_, text, _) {
                      return Text(
                        text.isEmpty ? 'Parle... j\'ecoute' : text,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: text.isEmpty
                              ? AppColors.cream.withValues(alpha: 0.6)
                              : AppColors.cream,
                          fontStyle: text.isEmpty
                              ? FontStyle.italic
                              : FontStyle.normal,
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.x8),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.cream,
                    size: 22,
                  ),
                  tooltip: 'Annuler la dictee',
                  onPressed: onCancel,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Petit point lime qui pulse pour signaler que le micro est actif.
/// Animation infinie : 800ms d'ease in/out, opacite et taille varient
/// legerement.
class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        // t passe de 0 a 1 puis revient a 0 grace au reverse.
        final t = _ctrl.value;
        final size = 10.0 + 4.0 * t;
        final alpha = 0.55 + 0.45 * t;
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.lime.withValues(alpha: alpha),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
