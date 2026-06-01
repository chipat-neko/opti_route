import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/address_suggestion.dart';
import '../../data/batch_scan_commit_service.dart';
import '../../data/bordereau_extraction.dart';
import '../../providers/database_providers.dart';
import '../../providers/geocoding_providers.dart';
import '../scan_bordereau_screen.dart';

/// Resultat du scan a appliquer au state de [AjoutArretScreen].
/// L'ecran caller pousse ces valeurs dans son setState.
class BordereauScanResult {
  const BordereauScanResult({
    this.address,
    this.scannedAddressText,
    this.nomClient,
    this.nbColis,
    this.isEnlevement = false,
  });

  /// Adresse validee (lat/lng + label complet) si trouvee.
  final AddressSuggestion? address;

  /// Texte d'adresse libre a pre-remplir dans le champ (cas pas de match).
  final String? scannedAddressText;

  final String? nomClient;
  final int? nbColis;

  /// True si le bordereau est de type ENLEVEMENT (Noah ramasse vs livre).
  final bool isEnlevement;
}

/// Ouvre `ScanBordereauScreen` + traite le resultat OCR. Cherche
/// l'adresse via 2 strategies en parallele (nom + adresse postale),
/// filtre les resultats par CP/ville pour eviter les faux positifs
/// inter-villes (cas reel 28300 vs 28400), et score les candidats
/// (POI > rue complete > rue > commune). Retourne null si l'utilisateur
/// annule le scan.
///
/// Extrait de `ajout_arret_screen.dart` (carte Trello #165).
Future<BordereauScanResult?> handleBordereauScan(
  BuildContext context,
  WidgetRef ref,
) async {
  final extraction = await Navigator.of(context).push<BordereauExtraction?>(
    MaterialPageRoute(
      builder: (_) => const ScanBordereauScreen(),
    ),
  );
  if (extraction == null || !context.mounted) return null;

  // PII (nom destinataire) : debug uniquement, jamais en release (#178).
  if (kDebugMode) {
    debugPrint('OCRDUMP === ajout_arret recu extraction.format = '
        '${extraction.format.name}, nomDest = ${extraction.nomDestinataire}');
  }

  AddressSuggestion? found;
  final service = ref.read(geocodingServiceProvider);
  final results = <AddressSuggestion>[];

  final nomQuery = extraction.rechercheParNom;
  if (nomQuery != null && nomQuery.length >= 3) {
    try {
      results.addAll(await service.search(nomQuery));
    } catch (_) {/* on tente l'adresse */}
  }
  final addrQuery = extraction.adressePostale;
  if (addrQuery != null && addrQuery.length >= 3) {
    try {
      results.addAll(await service.search(addrQuery));
    } catch (_) {/* tant pis */}
  }

  if (results.isNotEmpty) {
    // Sprint 2026-05-23 v2 (Noah) : ne PAS proposer une "supposition"
    // si elle est dans une AUTRE ville/CP que ce qu'on a sur le
    // bordereau. Cas reel : BAN trouvait "23 Avenue des Parigaudes,
    // 28300" pour NOGENT AUTO alors que la vraie adresse est 28400
    // ARCISSES. Le 28300 c'est Mainvilliers, pas Arcisses.
    final extractedCp = extraction.codePostal;
    final extractedVille = extraction.ville?.toLowerCase();
    final filtered = results.where((r) {
      if (extractedCp == null && extractedVille == null) return true;
      if (extractedCp != null && r.postcode != null) {
        if (r.postcode == extractedCp) return true;
        if (extractedVille != null &&
            r.city != null &&
            extractedCp.length >= 2 &&
            r.postcode!.startsWith(extractedCp.substring(0, 2)) &&
            r.city!.toLowerCase().contains(extractedVille)) {
          return true;
        }
        return false;
      }
      if (extractedVille != null && r.city != null) {
        return r.city!.toLowerCase().contains(extractedVille);
      }
      return true;
    }).toList();

    if (filtered.isEmpty) {
      if (kDebugMode) {
        debugPrint('OCRDUMP === geocodage : ${results.length} resultats '
            'rejetes (CP/ville different de "$extractedCp $extractedVille"). '
            'Pas de validation auto.');
      }
    } else {
      int score(AddressSuggestion a) {
        if (a.isPoi) return 3;
        if (a.road != null && a.houseNumber != null) return 3;
        if (a.road != null) return 2;
        return 1;
      }
      filtered.sort((a, b) => score(b).compareTo(score(a)));
      found = filtered.first;
    }
  }

  return BordereauScanResult(
    address: found,
    scannedAddressText: found == null ? (addrQuery ?? nomQuery) : null,
    nomClient: extraction.nomDestinataire,
    nbColis: extraction.nbColis,
    isEnlevement: extraction.format == BordereauFormat.enlevement,
  );
}

/// Mode rafale (carte #119) : ouvre [ScanBordereauScreen] en mode batch,
/// recupere le lot d'extractions, geocode chacune (best-effort), et cree
/// les arrets en masse dans [tourneeId] via [BatchScanCommitService]
/// (avec deduplication). Retourne le bilan (crees / doublons), ou null
/// si annule / lot vide.
Future<BatchCommitSummary?> handleBordereauScanBatch(
  BuildContext context,
  WidgetRef ref,
  int tourneeId,
) async {
  final extractions =
      await Navigator.of(context).push<List<BordereauExtraction>>(
    MaterialPageRoute(
      builder: (_) => const ScanBordereauScreen(batch: true),
    ),
  );
  if (extractions == null || extractions.isEmpty || !context.mounted) {
    return null;
  }
  final items = <BatchScanItem>[];
  for (final e in extractions) {
    final found = await _geocodeForBatch(ref, e);
    items.add(BatchScanItem(
      adresse: found?.adressePostale ??
          e.adressePostale ??
          e.rue ??
          e.nomDestinataire ??
          'Adresse a preciser',
      nomClient: e.nomDestinataire,
      lat: found?.lat,
      lng: found?.lon,
      nbColis: e.nbColis ?? 1,
      isEnlevement: e.format == BordereauFormat.enlevement,
    ));
  }
  return ref
      .read(batchScanCommitServiceProvider)
      .commit(tourneeId: tourneeId, items: items);
}

/// Geocodage best-effort d'une extraction pour le mode batch : cherche
/// par nom puis par adresse, filtre legerement par CP, retourne le
/// meilleur candidat ou null. Version compacte de la logique de
/// [handleBordereauScan] (suffisant pour un pre-remplissage de masse que
/// Noah peut ajuster ensuite arret par arret).
Future<AddressSuggestion?> _geocodeForBatch(
  WidgetRef ref,
  BordereauExtraction extraction,
) async {
  final service = ref.read(geocodingServiceProvider);
  final results = <AddressSuggestion>[];
  final nomQuery = extraction.rechercheParNom;
  if (nomQuery != null && nomQuery.length >= 3) {
    try {
      results.addAll(await service.search(nomQuery));
    } catch (_) {/* on tente l'adresse */}
  }
  final addrQuery = extraction.adressePostale;
  if (addrQuery != null && addrQuery.length >= 3) {
    try {
      results.addAll(await service.search(addrQuery));
    } catch (_) {/* tant pis */}
  }
  if (results.isEmpty) return null;
  final extractedCp = extraction.codePostal;
  final filtered = extractedCp == null
      ? results
      : results
          .where((r) => r.postcode == null || r.postcode == extractedCp)
          .toList();
  final pool = filtered.isEmpty ? results : filtered;
  int score(AddressSuggestion a) {
    if (a.isPoi) return 3;
    if (a.road != null && a.houseNumber != null) return 3;
    if (a.road != null) return 2;
    return 1;
  }
  pool.sort((a, b) => score(b).compareTo(score(a)));
  return pool.first;
}
