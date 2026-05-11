import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../data/clipboard_address_helper.dart';

/// Recoit les Share Intents Android (typiquement depuis Google Maps :
/// menu Partager -> opti_route) et expose le texte d'adresse extrait
/// via un `ValueNotifier`.
///
/// L'ecran d'ajout d'arret (`AjoutArretScreen`) ecoute ce notifier
/// dans son `initState` : si du texte est dispo, il pre-remplit le
/// champ adresse + relance l'autocomplete BAN/SIRENE/Photon.
///
/// 2 cas geres :
/// 1. **Cold start** : app lancee directement depuis un Share. On
///    recupere via `getInitialMedia()` au demarrage.
/// 2. **App au second plan** : un Share arrive alors qu'opti_route
///    est deja en cours. On l'attrape via le stream `getMediaStream()`.
class ShareIntentHandler {
  ShareIntentHandler._();
  static final instance = ShareIntentHandler._();

  /// Notifier expose a l'UI. Quand non-null, contient une adresse
  /// extraite d'un Share Intent recent.
  ///
  /// Apres consommation cote UI, appeler `clear()` pour eviter de
  /// repeter l'action sur les rebuilds.
  final ValueNotifier<String?> pendingAddress = ValueNotifier(null);

  StreamSubscription<List<SharedMediaFile>>? _sub;
  bool _initialized = false;

  /// A appeler une seule fois au demarrage (depuis `main.dart`).
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      // 1. Cas cold-start : app lancee depuis un Share.
      final initial =
          await ReceiveSharingIntent.instance.getInitialMedia();
      _handleMediaList(initial);

      // 2. Cas app deja ouverte : flux des shares suivants.
      _sub = ReceiveSharingIntent.instance.getMediaStream().listen(
        _handleMediaList,
        onError: (Object e) {
          debugPrint('SHARE_INTENT erreur stream: $e');
        },
      );

      // Signal au plugin que l'event cold-start a ete consomme.
      ReceiveSharingIntent.instance.reset();
    } catch (e) {
      debugPrint('SHARE_INTENT init erreur: $e');
    }
  }

  void _handleMediaList(List<SharedMediaFile> list) {
    if (list.isEmpty) return;
    for (final m in list) {
      // Le plugin met SharedMediaType.text quand l'app a ete partagee
      // depuis "Share -> text/plain". Sur certaines apps (Google Maps
      // par ex.) le texte arrive en path / mimeType text/plain.
      if (m.type == SharedMediaType.text || m.path.contains(' ')) {
        final text = m.path; // contient le texte partage
        final extracted = ClipboardAddressHelper.extractAddress(text);
        debugPrint('SHARE_INTENT recu : "${_trim(text)}" -> extracted="${_trim(extracted ?? '')}"');
        if (extracted != null && extracted.isNotEmpty) {
          pendingAddress.value = extracted;
          return; // 1 seule adresse a la fois
        }
      }
    }
  }

  /// L'UI a consomme l'adresse, on remet a null pour ne pas le faire
  /// 2 fois.
  void clear() {
    pendingAddress.value = null;
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
    pendingAddress.dispose();
  }

  static String _trim(String s) => s.length > 80 ? '${s.substring(0, 80)}...' : s;
}
