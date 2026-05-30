import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'database.dart';

/// Compose un dossier litige opposable pour un stop livre/echec
/// (carte #311). Pure fn. Le caller fait l'export PDF ou le partage
/// mail/WhatsApp depuis le texte retourne.
///
/// Contenu :
/// - identite stop (id, adresse, nomClient, tracking)
/// - statut + raisonEchec si applicable
/// - timestamp livreLe (ISO 8601 + horaire wall-clock)
/// - GPS livreLat/Lng (preuve de passage)
/// - mention preuvePhotoPath / cloudPhotoPath (chemins, le caller
///   joindra le fichier au PDF)
/// - mention deposeSansContact si applicable
/// - **hash SHA-256** des champs ci-dessus pour opposabilite (audit
///   trail signe : tout changement ulterieur des donnees casse le hash).
class DisputeFile {
  const DisputeFile({
    required this.body,
    required this.hash,
  });

  /// Texte du dossier (lisible humain + structure).
  final String body;

  /// Hash SHA-256 hex (64 chars) du body normalise.
  final String hash;

  bool get isOpposable => hash.length == 64;

  static DisputeFile compose({
    required Stop stop,
    DateTime? now,
  }) {
    final t = now ?? DateTime.now();
    final livreIso = stop.livreLe?.toIso8601String() ?? '(non livre)';
    final livreWall = stop.livreLe == null
        ? '-'
        : '${_pad(stop.livreLe!.day)}/${_pad(stop.livreLe!.month)}/'
            '${stop.livreLe!.year} '
            '${_pad(stop.livreLe!.hour)}:${_pad(stop.livreLe!.minute)}';
    final gps = (stop.livreLat == null || stop.livreLng == null)
        ? '(GPS indisponible)'
        : '${stop.livreLat!.toStringAsFixed(5)},${stop.livreLng!.toStringAsFixed(5)}';
    final tracking = (stop.trackingNumbers ?? '').replaceAll(
        RegExp('[\\[\\]"]'), '');
    final lines = <String>[
      '=== DOSSIER LITIGE OPPOSABLE ===',
      'Genere le : ${t.toIso8601String()}',
      '',
      '-- Identite arret --',
      'Stop ID    : ${stop.id}',
      'Tournee ID : ${stop.tourneeId}',
      'Adresse    : ${stop.adresseBrute}',
      if ((stop.nomClient ?? '').isNotEmpty)
        'Client     : ${stop.nomClient}',
      if (tracking.isNotEmpty) 'Tracking   : $tracking',
      'Nb colis   : ${stop.nbColis}',
      '',
      '-- Validation --',
      'Statut     : ${stop.statutLivraison}',
      if ((stop.raisonEchec ?? '').isNotEmpty)
        'Raison     : ${stop.raisonEchec}',
      'Horodatage : $livreWall ($livreIso)',
      'GPS preuve : $gps',
      if (stop.deposeSansContact) 'Mode       : DEPOSE SANS CONTACT',
      if ((stop.preuvePhotoPath ?? '').isNotEmpty)
        'Photo local: ${stop.preuvePhotoPath}',
      if ((stop.cloudPhotoPath ?? '').isNotEmpty)
        'Photo cloud: ${stop.cloudPhotoPath}',
    ];
    final body = lines.join('\n');
    final hash = sha256.convert(utf8.encode(body)).toString();
    return DisputeFile(
      body: '$body\n\n-- Signature --\nSHA-256: $hash',
      hash: hash,
    );
  }

  static String _pad(int v) => v.toString().padLeft(2, '0');
}
