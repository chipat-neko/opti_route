import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/nominatim_service.dart';

final nominatimServiceProvider = Provider<NominatimService>((ref) {
  final service = NominatimService();
  ref.onDispose(service.close);
  return service;
});
