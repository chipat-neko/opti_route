import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

/// ════════════════════════════════════════════════════════════════
/// Reception et parsing des partages externes (Google Maps, etc.)
/// ════════════════════════════════════════════════════════════════
///
/// Gere les partages Android `ACTION_SEND` avec MIME text/plain :
/// l'utilisateur fait 'Partager -> opti_route' depuis Google Maps,
/// SMS, mail, etc. -> on recoit le texte, on parse, on emet un
/// [SharedAddress] sur le stream.
///
/// Use case principal (demande Noah 2026-05-20) : un client appelle
/// avec une nouvelle adresse a livrer en cours de tournee. Noah
/// ouvre Google Maps, cherche l'adresse, tap 'Partager' -> opti_route,
/// on lui propose d'ajouter cet arret a la tournee active.
///
/// Format typique recu de Google Maps app :
///   "Mme Dupont\nhttps://maps.app.goo.gl/abc123"
///   OU
///   "https://maps.app.goo.gl/abc123"
///
/// On expand le short link pour extraire les coords / l'adresse.
class ShareIntentService {
  ShareIntentService();

  StreamSubscription<List<SharedMediaFile>>? _liveSub;
  final _addressController =
      StreamController<SharedAddress>.broadcast();

  /// Stream sur lequel arrivent les adresses partagees pretes a
  /// etre ajoutees a une tournee. L'UI doit s'y subscriber au boot.
  Stream<SharedAddress> get addressStream => _addressController.stream;

  /// Initialise l'ecoute :
  /// 1. Recupere un eventuel partage qui a lance l'app (cold start)
  /// 2. S'abonne aux futurs partages quand l'app est deja ouverte
  ///
  /// A appeler depuis main.dart apres runApp().
  Future<void> init() async {
    // 1. Cold start : si l'app a ete ouverte VIA un partage, on
    //    recupere ce contenu initial.
    try {
      final initial =
          await ReceiveSharingIntent.instance.getInitialMedia();
      _handleShared(initial);
    } catch (e) {
      debugPrint('[ShareIntent] init cold-start fail : $e');
    }
    // 2. Subscribe aux partages futurs (app deja en background ou
    //    foreground quand le user partage).
    _liveSub =
        ReceiveSharingIntent.instance.getMediaStream().listen(_handleShared);
  }

  void dispose() {
    _liveSub?.cancel();
    _addressController.close();
  }

  Future<void> _handleShared(List<SharedMediaFile> media) async {
    if (media.isEmpty) return;
    for (final m in media) {
      // Pour les partages text/plain, le contenu arrive dans
      // `m.path` (qui contient le texte brut, pas un path filesystem).
      final raw = m.path.trim();
      if (raw.isEmpty) continue;
      final parsed = await parseSharedText(raw);
      if (parsed != null) _addressController.add(parsed);
    }
    // Marque les partages comme consommes pour eviter de les
    // re-traiter au prochain init.
    await ReceiveSharingIntent.instance.reset();
  }

  /// Parse un texte partage pour en extraire un [SharedAddress].
  /// Logique :
  ///   1. Cherche un nom (1ere ligne si non-URL)
  ///   2. Cherche une URL Google Maps (short ou long)
  ///   3. Si short link `maps.app.goo.gl` -> expand via HTTP HEAD
  ///   4. Extrait coords `@lat,lng` ou nom `/place/<name>/`
  ///
  /// Retourne null si aucune adresse exploitable detectee.
  ///
  /// Visible pour les tests (pure, sans I/O externe sauf HTTP HEAD
  /// optionnel pour expand short links).
  static Future<SharedAddress?> parseSharedText(String raw) async {
    final lines = raw
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isEmpty) return null;

    // Cherche une URL Google Maps dans le contenu.
    String? gmapsUrl;
    String? name;
    for (final line in lines) {
      if (_isGoogleMapsUrl(line)) {
        gmapsUrl ??= line;
      } else {
        name ??= line;
      }
    }

    // Si on a une URL short, on l'expand pour acceder aux coords.
    String? expandedUrl;
    if (gmapsUrl != null && gmapsUrl.contains('maps.app.goo.gl')) {
      expandedUrl = await _expandShortLink(gmapsUrl);
    } else {
      expandedUrl = gmapsUrl;
    }

    // Tente d'extraire coords + nom de lieu de l'URL Google Maps.
    double? lat;
    double? lng;
    String? placeFromUrl;
    if (expandedUrl != null) {
      final coords = _extractCoordsFromGmapsUrl(expandedUrl);
      lat = coords?.$1;
      lng = coords?.$2;
      placeFromUrl = _extractPlaceFromGmapsUrl(expandedUrl);
    }

    final finalName = name ?? placeFromUrl;
    // Si rien d'utile -> null
    if (finalName == null && lat == null) return null;
    return SharedAddress(
      rawText: raw,
      name: finalName,
      lat: lat,
      lng: lng,
      sourceUrl: gmapsUrl,
    );
  }

  static bool _isGoogleMapsUrl(String s) {
    final lower = s.toLowerCase();
    return lower.startsWith('http') &&
        (lower.contains('maps.app.goo.gl') ||
            lower.contains('google.com/maps') ||
            lower.contains('maps.google.com'));
  }

  /// Suit la redirection 302 d'un short link Google Maps pour acceder
  /// a l'URL complete qui contient les coords / nom. Best-effort : si
  /// l'expansion echoue (offline, timeout), retourne null.
  static Future<String?> _expandShortLink(String shortUrl) async {
    try {
      // On utilise GET sans suivre les redirections pour capturer
      // le header Location du 302.
      final client = http.Client();
      try {
        final req = http.Request('GET', Uri.parse(shortUrl))
          ..followRedirects = false;
        final stream = await client
            .send(req)
            .timeout(const Duration(seconds: 4));
        // Drain le body sans le lire pour liberer la connexion
        await stream.stream.drain();
        final loc = stream.headers['location'];
        if (loc == null || loc.isEmpty) return null;
        return loc;
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('[ShareIntent] expand short link fail : $e');
      return null;
    }
  }

  /// Extrait `(lat, lng)` d'une URL Google Maps. Formats supportes :
  ///   /@48.43,1.49,17z         -> centre carte
  ///   /place/.../@48.43,1.49   -> centre place
  ///   ?q=48.43,1.49            -> query
  ///   ?ll=48.43,1.49           -> legacy
  static (double, double)? _extractCoordsFromGmapsUrl(String url) {
    // Pattern 1 : @lat,lng[,zoom]
    final at = RegExp(r'@(-?\d+\.\d+),(-?\d+\.\d+)').firstMatch(url);
    if (at != null) {
      final lat = double.tryParse(at.group(1)!);
      final lng = double.tryParse(at.group(2)!);
      if (lat != null && lng != null) return (lat, lng);
    }
    // Pattern 2 : ?q=lat,lng OR ?ll=lat,lng
    final q = RegExp(r'[?&](?:q|ll|center)=(-?\d+\.\d+),(-?\d+\.\d+)')
        .firstMatch(url);
    if (q != null) {
      final lat = double.tryParse(q.group(1)!);
      final lng = double.tryParse(q.group(2)!);
      if (lat != null && lng != null) return (lat, lng);
    }
    return null;
  }

  /// Extrait le nom de lieu d'une URL `/place/<NAME>/`. Le nom est
  /// URL-encoded avec `+` pour les espaces. On le decode et nettoie.
  static String? _extractPlaceFromGmapsUrl(String url) {
    final m = RegExp(r'/place/([^/@?]+)').firstMatch(url);
    if (m == null) return null;
    try {
      final raw = Uri.decodeComponent(m.group(1)!.replaceAll('+', ' '));
      return raw.trim();
    } catch (_) {
      return null;
    }
  }
}

/// Une adresse extraite d'un partage externe, prete a etre integree
/// a une tournee via [BulkPasteScreen] ou un dialog dedie.
class SharedAddress {
  const SharedAddress({
    required this.rawText,
    this.name,
    this.lat,
    this.lng,
    this.sourceUrl,
  });

  /// Texte brut tel que recu (debug + fallback).
  final String rawText;

  /// Nom de lieu extrait (1ere ligne ou /place/.../).
  final String? name;

  /// Coords extraites de l'URL si presentes.
  final double? lat;
  final double? lng;

  /// URL Google Maps source (court ou long).
  final String? sourceUrl;

  bool get hasCoords => lat != null && lng != null;

  /// String a passer a l'autocomplete d'adresse / au geocoder si on
  /// n'a pas de coords directes. Priorite : nom > URL > rawText.
  String get queryHint => name ?? sourceUrl ?? rawText;
}
