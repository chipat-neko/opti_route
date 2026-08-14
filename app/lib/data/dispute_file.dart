import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'database.dart';

/// Etat de la photo preuve AU MOMENT ou le dossier est compose.
///
/// Sert a dire la verite dans le corps du dossier : un dossier qui se
/// tait sur une photo disparue laisse croire qu'il n'y en a jamais eu.
enum DisputePhotoState {
  /// Aucun chemin de photo preuve sur l'arret : il n'y a jamais eu de photo.
  aucune,

  /// Les octets du fichier ont ete fournis : leur empreinte est dans le
  /// corps du dossier, donc couverte par le hash final.
  jointe,

  /// L'arret porte un chemin de photo mais le fichier n'a pas pu etre lu
  /// (cache nettoye, photo supprimee a la main, pas encore retelechargee
  /// du cloud). Le hash ne couvre alors que le texte.
  introuvable,
}

/// Compose un dossier litige opposable pour un stop livre/echec
/// (carte #311). Pure fn : elle ne touche NI la base NI le disque. Le
/// caller lit le fichier photo et passe ses octets, puis fait l'export
/// PDF ou le partage mail/WhatsApp depuis le texte retourne.
///
/// Contenu :
/// - identite stop (id, adresse, nomClient, tracking)
/// - statut + raisonEchec si applicable
/// - timestamp livreLe (ISO 8601 + horaire wall-clock)
/// - GPS livreLat/Lng (preuve de passage)
/// - mention preuvePhotoPath / cloudPhotoPath (chemins, le caller
///   joindra le fichier au PDF)
/// - etat de la photo preuve + **empreinte SHA-256 de ses octets**
/// - mention deposeSansContact si applicable
/// - **hash SHA-256** de tout ce qui precede pour opposabilite (audit
///   trail signe : tout changement ulterieur des donnees casse le hash).
///
/// Portee du hash (decision proprietaire 2026-08) : le hash couvre le
/// texte ET l'image. L'empreinte des octets de la photo est ecrite DANS
/// le corps, donc remplacer le fichier image change l'empreinte, donc
/// change le hash. Avant, seul le texte etait couvert : on pouvait
/// substituer la photo sans que le hash bouge, ce qui vidait le mot
/// "opposable" de son sens.
class DisputeFile {
  const DisputeFile({
    required this.body,
    required this.hash,
    required this.photoState,
    this.photoHash,
  });

  /// Texte du dossier (lisible humain + structure), signature incluse.
  final String body;

  /// Hash SHA-256 hex (64 chars) du corps normalise, empreinte photo
  /// comprise quand il y en a une.
  final String hash;

  /// Ce que le dossier a pu constater de la photo preuve.
  final DisputePhotoState photoState;

  /// SHA-256 hex des octets de la photo preuve, ou null si aucun octet
  /// n'a ete fourni (pas de photo, ou fichier introuvable).
  final String? photoHash;

  bool get isOpposable => hash.length == 64;

  /// true quand le hash englobe aussi les octets de l'image.
  bool get coversPhoto => photoHash != null;

  /// [photoBytes] : octets du fichier photo preuve, lus par le CALLER
  /// (le module reste pur). Les 3 cas possibles :
  /// - octets NON VIDES fournis -> [DisputePhotoState.jointe], hash etendu
  ///   a l'image ;
  /// - pas d'octets exploitables mais un chemin sur l'arret ->
  ///   [DisputePhotoState.introuvable], le dossier dit explicitement que le
  ///   fichier n'a pas pu etre lu ;
  /// - ni octets ni chemin -> [DisputePhotoState.aucune].
  ///
  /// Une liste VIDE compte comme "pas d'octets" : un fichier de 0 octet est
  /// une photo illisible, et signer l'empreinte du vide (e3b0c442...) ferait
  /// dire au dossier qu'une image est couverte alors qu'il n'y a rien.
  static DisputeFile compose({
    required Stop stop,
    DateTime? now,
    List<int>? photoBytes,
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

    final hasPhotoPath = (stop.preuvePhotoPath ?? '').isNotEmpty ||
        (stop.cloudPhotoPath ?? '').isNotEmpty;
    final photoHash = (photoBytes == null || photoBytes.isEmpty)
        ? null
        : sha256.convert(photoBytes).toString();
    final photoState = photoHash != null
        ? DisputePhotoState.jointe
        : (hasPhotoPath
            ? DisputePhotoState.introuvable
            : DisputePhotoState.aucune);

    // Un dossier oppose a un client doit dire POURQUOI l'image n'est pas
    // couverte : "jamais prise" et "pas pu etre lue" ne racontent pas la
    // meme histoire.
    final portee = switch (photoState) {
      DisputePhotoState.jointe =>
        'Le SHA-256 ci-dessous couvre TOUT le texte de ce dossier, '
            'empreinte de la photo comprise : remplacer le fichier image '
            'change son empreinte, donc casse la signature.',
      DisputePhotoState.introuvable =>
        'Le SHA-256 ci-dessous couvre le texte de ce dossier. Aucune '
            'image n\'est couverte : le fichier photo reference plus haut '
            'n\'a pas pu etre lu au moment de la generation.',
      DisputePhotoState.aucune =>
        'Le SHA-256 ci-dessous couvre le texte de ce dossier. Aucune '
            'image n\'est couverte : aucune photo preuve n\'a jamais ete '
            'prise sur cet arret.',
    };

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
      '',
      '-- Preuve photo --',
      'Etat photo : ${_labelPhoto(photoState)}',
      if (photoHash != null) 'Photo SHA  : $photoHash',
      '',
      '-- Portee de la signature --',
      portee,
    ];
    final body = lines.join('\n');
    final hash = sha256.convert(utf8.encode(body)).toString();
    return DisputeFile(
      body: '$body\n\n-- Signature --\nSHA-256: $hash',
      hash: hash,
      photoState: photoState,
      photoHash: photoHash,
    );
  }

  static String _labelPhoto(DisputePhotoState state) => switch (state) {
        DisputePhotoState.aucune =>
          'AUCUNE photo preuve n\'a ete prise sur cet arret',
        DisputePhotoState.jointe =>
          'jointe et signee (empreinte ci-dessous)',
        DisputePhotoState.introuvable =>
          'ABSENTE DU STOCKAGE : un chemin existe sur l\'arret mais le '
              'fichier n\'a pas pu etre lu (supprime ou pas encore '
              'retelecharge du cloud)',
      };

  static String _pad(int v) => v.toString().padLeft(2, '0');
}
