import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../data/database.dart';
import '../../data/voice_command_parser.dart';
import '../../providers/database_providers.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/snack.dart';

/// ════════════════════════════════════════════════════════════════
/// FAB mains-libres carte #273.
/// ════════════════════════════════════════════════════════════════
///
/// Tap = enchaine :
///   1. Annonce TTS du prochain stop pending ("Prochain arret :
///      `client`, `adresse`, `nb` colis")
///   2. Active la reconnaissance vocale (STT) pour 6 sec
///   3. Parse la transcription via [VoiceCommandParser]
///   4. Marque le stop comme livre / echec / passe le tour
///
/// Tap pendant l'annonce ou l'ecoute = annule (stop TTS + STT).
///
/// Tout est on-device (zero cle API, zero quota). TTS = flutter_tts,
/// STT = speech_to_text.
class VoiceCommandFab extends ConsumerStatefulWidget {
  const VoiceCommandFab({super.key, required this.tournee});

  final Tournee tournee;

  @override
  ConsumerState<VoiceCommandFab> createState() => _VoiceCommandFabState();
}

class _VoiceCommandFabState extends ConsumerState<VoiceCommandFab> {
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _stt = stt.SpeechToText();

  bool _ttsReady = false;
  bool _sttReady = false;
  bool _busy = false; // soit en train de parler, soit en train d'ecouter

  Timer? _listenTimeout;

  @override
  void dispose() {
    _listenTimeout?.cancel();
    unawaited(_tts.stop());
    unawaited(_stt.stop());
    super.dispose();
  }

  Future<bool> _ensureTts() async {
    if (_ttsReady) return true;
    try {
      await _tts.setLanguage('fr-FR');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      _ttsReady = true;
    } catch (e) {
      debugPrint('[VoiceCommandFab] TTS init failed: $e');
    }
    return _ttsReady;
  }

  Future<bool> _ensureStt() async {
    if (_sttReady) return true;
    _sttReady = await _stt.initialize(
      onError: (e) =>
          debugPrint('[VoiceCommandFab] STT error: ${e.errorMsg}'),
      onStatus: (status) =>
          debugPrint('[VoiceCommandFab] STT status: $status'),
    );
    return _sttReady;
  }

  Future<void> _onTap() async {
    if (_busy) {
      // Annulation explicite : stoppe tout, reset.
      await _abort();
      return;
    }
    final stops = await ref
        .read(stopsRepositoryProvider)
        .getByTournee(widget.tournee.id);
    Stop? next;
    for (final s in stops) {
      if (s.statutLivraison == 'a_livrer') {
        next = s;
        break;
      }
    }
    if (next == null) {
      _snack('Plus d\'arret a livrer.');
      return;
    }
    setState(() => _busy = true);
    try {
      await _speakAndListen(next);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _abort() async {
    _listenTimeout?.cancel();
    await _tts.stop();
    await _stt.stop();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _speakAndListen(Stop next) async {
    final ttsOk = await _ensureTts();
    if (!ttsOk) {
      _snack('Synthese vocale indisponible.');
      return;
    }
    final sttOk = await _ensureStt();
    if (!sttOk) {
      _snack('Micro indisponible (permission refusee ?).');
      return;
    }
    final phrase = _composePhrase(next);
    await _tts.awaitSpeakCompletion(true);
    await _tts.speak(phrase);
    if (!mounted || !_busy) return;
    // Ecoute pendant max 6 sec, ou jusqu'au finalResult.
    final completer = Completer<String>();
    _listenTimeout = Timer(const Duration(seconds: 6), () {
      if (!completer.isCompleted) completer.complete('');
      unawaited(_stt.stop());
    });
    await _stt.listen(
      onResult: (r) {
        if (r.finalResult && !completer.isCompleted) {
          completer.complete(r.recognizedWords);
        }
      },
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
        localeId: 'fr_FR',
      ),
    );
    final transcript = await completer.future;
    _listenTimeout?.cancel();
    if (!mounted || !_busy) return;
    final cmd = VoiceCommandParser.parse(transcript);
    await _handleCommand(cmd, next);
  }

  Future<void> _handleCommand(VoiceCommand cmd, Stop next) async {
    final repo = ref.read(stopsRepositoryProvider);
    switch (cmd) {
      case VoiceCommand.livre:
        await repo.markLivre(next.id);
        _snack('Marque livre : ${next.nomClient ?? next.adresseBrute}');
      case VoiceCommand.echec:
        await repo.markEchec(next.id, 'autre');
        _snack('Marque echec : ${next.nomClient ?? next.adresseBrute}');
      case VoiceCommand.passer:
        _snack('Arret passe. Tap a nouveau pour le suivant.');
      case VoiceCommand.stop:
      case VoiceCommand.unknown:
        _snack('Commande non reconnue. Reessaye.');
    }
  }

  String _composePhrase(Stop s) {
    final name = (s.nomClient ?? '').trim();
    final addr = s.adresseBrute.trim();
    final colis = s.nbColis == 1 ? '1 colis' : '${s.nbColis} colis';
    final parts = <String>[
      'Prochain arret.',
      if (name.isNotEmpty) name,
      addr,
      colis,
    ];
    return parts.join(', ');
  }

  void _snack(String msg) {
    if (!mounted) return;
    context.showInfo(msg);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return FloatingActionButton.small(
      heroTag: 'fab-voice-command',
      backgroundColor: _busy ? AppColors.red : AppColors.lime,
      foregroundColor: _busy ? AppColors.cream : p.ink,
      onPressed: _onTap,
      tooltip: _busy
          ? 'Annuler la commande vocale'
          : 'Commande vocale (annonce + ecoute)',
      child: Icon(_busy ? Icons.mic : Icons.record_voice_over_outlined),
    );
  }
}
