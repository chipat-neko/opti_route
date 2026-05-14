import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/bordereau_validator.dart';
import '../data/ocr_service.dart';
import 'geocoding_providers.dart';

final ocrServiceProvider = Provider<OcrService>((ref) {
  final service = OcrService();
  ref.onDispose(service.close);
  return service;
});

/// Validateur post-OCR : prend une extraction brute, interroge la BAN
/// et retourne une version validee + corrigee si possible. Cf
/// [BordereauValidator] pour le detail de la strategie.
///
/// Reutilise le `banGeocodingServiceProvider` deja en place (cache
/// active, headers User-Agent, etc.).
final bordereauValidatorProvider = Provider<BordereauValidator>((ref) {
  final ban = ref.watch(banGeocodingServiceProvider);
  return BordereauValidator(ban);
});
