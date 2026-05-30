/// Construit un message SOS standardise + son URI sms:/whatsapp:.
/// Carte #286 : bouton SOS qui declenche un SMS pre-rempli avec
/// position GPS + horodatage + message court (« SOS, j'ai besoin
/// d'aide »).
///
/// Pure fn. L'integration UI (geolocator + url_launcher) est cote
/// widget. Centralise la mise en forme pour rester testable.
class SosMessage {
  SosMessage._();

  /// Construit le texte du message. Format :
  ///   "SOS - Noah - `HH:MM` - lat,lng (https://maps.google.com/?q=lat,lng)"
  ///
  /// [lat] / [lng] peuvent etre null si GPS indisponible : on emet
  /// alors un message sans coordonnees, pour ne pas bloquer l'envoi
  /// (l'urgence prime sur la precision).
  static String compose({
    String? name,
    double? lat,
    double? lng,
    DateTime? now,
  }) {
    final t = now ?? DateTime.now();
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    final who = (name ?? '').trim().isEmpty ? 'opti_route' : name!.trim();
    final buf = StringBuffer('SOS - $who - $hh:$mm');
    if (lat != null && lng != null) {
      final la = lat.toStringAsFixed(5);
      final ln = lng.toStringAsFixed(5);
      buf.write(' - position $la,$ln');
      buf.write(' (https://maps.google.com/?q=$la,$ln)');
    } else {
      buf.write(' - position GPS indisponible');
    }
    return buf.toString();
  }

  /// URI `sms:` pre-rempli pour [recipient] avec [body]. Le body est
  /// URL-encoded.
  static Uri smsUri({required String recipient, required String body}) {
    return Uri(
      scheme: 'sms',
      path: recipient,
      queryParameters: {'body': body},
    );
  }
}
