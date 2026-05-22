import 'dart:async';
import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'bordereau_extraction.dart';
import 'supabase_service.dart';

/// Service qui appelle l'Edge Function `ocr-enhance` (Supabase + Gemini
/// Flash) pour ameliorer le resultat du parser local.
///
/// Workflow attendu cote UI (offline-first) :
/// 1. OCR + parser local : resultat instantane affiche en orange
/// 2. En parallele : [enhance] envoie le texte OCR a la function
/// 3. Quand la reponse Gemini arrive (~1s plus tard), l'UI bascule
///    sur ce resultat si la confidence est >= local
/// 4. Si la function timeout / erreur / quota free tier depasse : on
///    garde silencieusement le resultat local
///
/// Cle Gemini cote serveur uniquement (secret Supabase), jamais expose
/// dans l'APK.
class OcrLlmEnhanceService {
  OcrLlmEnhanceService();

  /// Timeout court : si le LLM ne repond pas en 5s, on lache et on
  /// reste sur le resultat local. Evite que l'UI attende indefiniment.
  static const _timeout = Duration(seconds: 5);

  /// Appelle l'Edge Function et retourne le resultat enrichi.
  /// Retourne null si :
  /// - Pas de connexion Supabase (offline ou non-authentifie)
  /// - Function timeout / erreur / quota depasse
  /// - Reponse vide / mal formee
  ///
  /// L'appel est SILENT en cas d'erreur : aucun throw, juste null,
  /// pour que l'UI puisse continuer avec le resultat local.
  Future<BordereauExtraction?> enhance({
    required List<String> ocrLines,
    BordereauFormat? formatHint,
    String? parserUsed,
  }) async {
    if (ocrLines.isEmpty) return null;
    if (!SupabaseService.instance.isConfigured) return null;
    if (SupabaseService.instance.currentUser == null) {
      // Pas connecte : on ne peut pas appeler la function (verify_jwt).
      return null;
    }
    try {
      final response = await Supabase.instance.client.functions
          .invoke(
            'ocr-enhance',
            body: {
              'ocr_text': ocrLines.join('\n'),
              if (formatHint != null) 'format_hint': formatHint.name,
              'parser_used': ?parserUsed,
            },
          )
          .timeout(_timeout);
      if (response.status != 200) return null;
      // La function renvoie deja du JSON parse via Edge Runtime.
      final data = response.data is Map
          ? response.data as Map<String, dynamic>
          : (response.data is String
              ? jsonDecode(response.data as String) as Map<String, dynamic>
              : null);
      if (data == null || data.containsKey('error')) return null;
      return parseResponse(data);
    } catch (_) {
      // Timeout / network / parsing / quota : silent fallback.
      return null;
    }
  }

  /// Convertit la reponse JSON de l'Edge Function en
  /// [BordereauExtraction]. Public + statique pour permettre les tests
  /// sans dependance Supabase (cf [ocr_llm_enhance_service_test.dart]).
  ///
  /// Tolere les champs manquants / mal types : retombe sur null /
  /// confidence low / format livraison plutot que de throw.
  static BordereauExtraction parseResponse(Map<String, dynamic> data) {
    final confStr = data['confidence'] as String? ?? 'low';
    final formatStr = data['format'] as String? ?? 'livraison';
    final confidence = ExtractionConfidence.values.firstWhere(
      (c) => c.name == confStr,
      orElse: () => ExtractionConfidence.low,
    );
    final format = formatStr == 'enlevement'
        ? BordereauFormat.enlevement
        : BordereauFormat.livraison;
    int? nbColis;
    final nbRaw = data['nb_colis'];
    if (nbRaw is int) {
      nbColis = nbRaw;
    } else if (nbRaw is num) {
      nbColis = nbRaw.toInt();
    } else if (nbRaw is String) {
      nbColis = int.tryParse(nbRaw);
    }
    return BordereauExtraction(
      nomDestinataire: _str(data['nom_destinataire']),
      rue: _str(data['rue']),
      codePostal: _str(data['code_postal']),
      ville: _str(data['ville']),
      telephone: _str(data['telephone']),
      nbColis: nbColis,
      confidence: confidence,
      format: format,
      source: ExtractionSource.llmGemini,
    );
  }

  static String? _str(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }
}
