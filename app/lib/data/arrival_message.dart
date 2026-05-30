/// Compose un message "j'arrive" + son URI sms:/whatsapp: a destination
/// du destinataire. Carte #289 : moins d'absents -> moins de seconds
/// passages.
class ArrivalMessage {
  ArrivalMessage._();

  /// Texte standardise. Format :
  ///   "Bonjour `nom`, votre livraison arrive vers `HH:MM` (~`minutes` min).
  ///    Merci de rester joignable. Cordialement."
  ///
  /// `eta` est arrondi a la minute la plus proche pour [formatEta].
  static String compose({
    required String nomClient,
    required DateTime eta,
    DateTime? now,
  }) {
    final t = now ?? DateTime.now();
    final mins = eta.difference(t).inMinutes;
    final hh = eta.hour.toString().padLeft(2, '0');
    final mm = eta.minute.toString().padLeft(2, '0');
    final nom = nomClient.trim().isEmpty ? '' : '${nomClient.trim()}, ';
    final approx = mins <= 0
        ? ''
        : ' (~$mins min)';
    return 'Bonjour ${nom}votre livraison arrive vers $hh:$mm$approx. '
        'Merci de rester joignable.';
  }

  static Uri smsUri({required String recipient, required String body}) {
    return Uri(
      scheme: 'sms',
      path: recipient,
      queryParameters: {'body': body},
    );
  }

  /// URI WhatsApp `https://wa.me/<num>?text=<body>`. Le numero doit
  /// etre en format international sans '+' (ex: '33612345678').
  static Uri whatsAppUri({
    required String phoneIntl,
    required String body,
  }) {
    final encoded = Uri.encodeQueryComponent(body);
    return Uri.parse('https://wa.me/$phoneIntl?text=$encoded');
  }
}
