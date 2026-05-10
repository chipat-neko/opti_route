import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ocr_service.dart';

final ocrServiceProvider = Provider<OcrService>((ref) {
  final service = OcrService();
  ref.onDispose(service.close);
  return service;
});
