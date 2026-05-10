import 'bordereau_extraction.dart';

/// Parser pour extraire automatiquement les champs cles d'un bordereau
/// de livraison a partir des lignes OCR.
///
/// Strategie heuristique (cf memory `reference_format_bordereau.md`) :
/// 1. Cherche les marqueurs `Destinataire`, `Lieu de livraison`,
///    `Total colis` dans les lignes.
/// 2. Le bloc apres `Destinataire` (jusqu'au prochain marqueur) =
///    nom + adresse rue.
/// 3. Le bloc apres `Lieu de livraison` = code postal + ville.
/// 4. La valeur apres `Total colis` = nombre.
/// 5. Fallbacks : si un marqueur est absent, on tente avec regex
///    (CP francais `\b\d{5}\b`, etc.).
class BordereauParser {
  static const _markersLieuLivraison = [
    'lieu de livraison',
    'lieu livraison',
  ];
  static const _markersTotalColis = ['total colis', 'colis :'];
  static const _markersContact = ['contact destinataire'];

  static const _stopMarkers = [
    'lieu de livraison',
    'total colis',
    'transporteur',
    'commissionnaire',
    'instruction',
    'matieres dangereuses',
    'matières dangereuses',
    'lettre de voiture',
    'contact destinataire',
    'ref. dest',
    'ref dest',
  ];

  static final _cpVilleRegex = RegExp(
    r"(\d{5})\s+([A-Za-zÀ-ÿ][A-Za-zÀ-ÿ\s\-']+)",
  );
  static final _cpRegex = RegExp(r'\b(\d{5})\b');
  static final _telRegex = RegExp(r'\b(0\d[\s.\-]?\d{2}[\s.\-]?\d{2}[\s.\-]?\d{2}[\s.\-]?\d{2})\b');

  BordereauExtraction parse(List<String> rawLines) {
    final lines = rawLines
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList(growable: false);

    final destIdx = _findDestinataireIndex(lines);
    final lieuIdx = _findIndex(lines, _markersLieuLivraison);
    final colisIdx = _findIndex(lines, _markersTotalColis);
    final contactIdx = _findIndex(lines, _markersContact);

    // Strategie 1 : bloc destinataire structure (label "Destinataire"
    // suivi du contenu). Marche quand l'OCR retourne les lignes dans
    // un ordre logique (top-to-bottom).
    String? nomDest;
    String? rue;
    if (destIdx >= 0) {
      final endIdx = _findNextStopIndex(lines, destIdx + 1);
      final block = lines.sublist(destIdx + 1, endIdx);
      if (block.isNotEmpty) {
        nomDest = block.first;
        if (block.length > 1) {
          rue = block.skip(1).join(' · ');
        }
      }
    }

    // Strategie 2 (fallback) : si la strategie structurelle a rate ou
    // si le nom est probablement faux (trop court, contient un label),
    // on cherche par OCCURRENCES. Le destinataire est mentionne 2 fois
    // sur le bordereau (dans "Contact destinataire" + dans le bloc
    // Destinataire), alors que l'expediteur est mentionne 1 fois.
    if (_looksUnreliable(nomDest)) {
      final byOccurrence = _findNomByOccurrences(lines);
      if (byOccurrence != null) {
        nomDest = byOccurrence;
      }
    }

    // Bloc Lieu de livraison : on regarde les 3 lignes suivantes,
    // **une par une** (concatener les lignes ferait deborder la regex
    // ville sur "Nature de la marchandise GALET" par ex).
    String? cp;
    String? ville;
    if (lieuIdx >= 0) {
      for (var i = lieuIdx + 1; i < lines.length && i < lieuIdx + 4; i++) {
        final line = lines[i];
        final m = _cpVilleRegex.firstMatch(line);
        if (m != null) {
          cp = m.group(1);
          ville = _cleanVille(m.group(2));
          break;
        }
        final cpOnly = _cpRegex.firstMatch(line);
        if (cpOnly != null && cp == null) {
          cp = cpOnly.group(1);
          // La ville sera peut-etre sur la ligne suivante.
        }
      }
    }

    // Fallback : si pas de CP, on cherche dans tout le bordereau, en
    // privilegiant un CP qui n'est PAS celui de l'expediteur.
    if (cp == null) {
      cp = _findReceiverCp(lines, destIdx);
      if (cp != null) {
        // Re-chercher la ville accolee
        for (final line in lines) {
          if (line.contains(cp)) {
            final m = RegExp(r"(\d{5})\s+([A-Za-zÀ-ÿ][A-Za-zÀ-ÿ\s\-']+)")
                .firstMatch(line);
            if (m != null && m.group(1) == cp) {
              ville = _cleanVille(m.group(2));
              break;
            }
          }
        }
      }
    }

    // Total colis
    int? nbColis;
    if (colisIdx >= 0) {
      final lineColis = lines[colisIdx];
      final inSame = RegExp(r'colis\s*:?\s*(\d+)', caseSensitive: false)
          .firstMatch(lineColis);
      if (inSame != null) {
        nbColis = int.tryParse(inSame.group(1) ?? '');
      } else if (colisIdx + 1 < lines.length) {
        final m = _cpRegex.firstMatch(lines[colisIdx + 1]);
        if (m == null) {
          final n = RegExp(r'\b(\d+)\b').firstMatch(lines[colisIdx + 1]);
          nbColis = n != null ? int.tryParse(n.group(1) ?? '') : null;
        }
      }
    }

    // Telephone : depuis "Contact destinataire" si dispo
    String? telephone;
    if (contactIdx >= 0) {
      final candidates = lines.skip(contactIdx).take(2).join(' ');
      final m = _telRegex.firstMatch(candidates);
      telephone = m?.group(1)?.replaceAll(RegExp(r'[\s.\-]'), '');
    }

    return BordereauExtraction(
      nomDestinataire: nomDest,
      rue: rue,
      codePostal: cp,
      ville: ville,
      telephone: telephone,
      nbColis: nbColis,
    );
  }

  static int _findIndex(List<String> lines, List<String> markers) {
    for (var i = 0; i < lines.length; i++) {
      final lower = lines[i].toLowerCase();
      for (final m in markers) {
        if (lower.contains(m)) return i;
      }
    }
    return -1;
  }

  /// "Destinataire" tout seul, en excluant "Contact destinataire" qui
  /// est un autre marqueur dans le format MESEXP. Tolerance OCR :
  /// accepte aussi "desinataire" (sans le 't') que ML Kit produit
  /// parfois.
  static int _findDestinataireIndex(List<String> lines) {
    for (var i = 0; i < lines.length; i++) {
      final lower = lines[i].toLowerCase().trim();
      // Tolerance OCR : "destinataire" ou "desinataire" (sans 't')
      if (!lower.contains('estinataire')) continue;
      if (lower.contains('contact')) continue;
      if (lower.contains('ref')) continue; // "Ref. dest."
      return i;
    }
    return -1;
  }

  /// Heuristique : le nom du destinataire apparait 2 fois ou plus sur
  /// le bordereau (dans "Contact destinataire" + dans le bloc
  /// Destinataire), alors que l'expediteur est mentionne 1 seule fois.
  /// On cherche donc les segments en MAJUSCULES qui apparaissent
  /// plusieurs fois, et on prend celui qui apparait le plus.
  static String? _findNomByOccurrences(List<String> lines) {
    // Pattern : 2+ mots en MAJUSCULES, longueur totale >= 10.
    final pattern = RegExp(r"([A-Z][A-Z\-']+(?:\s+[A-Z][A-Z\-']+)+)");
    final candidates = <String>{};
    for (final line in lines) {
      for (final m in pattern.allMatches(line)) {
        final s = m.group(1)!.trim();
        if (s.length < 10) continue;
        // Exclure les fragments evidemment non-noms (labels, codes...)
        if (_isObviousLabel(s)) continue;
        candidates.add(s);
      }
    }

    String? best;
    int bestCount = 0;
    for (final cand in candidates) {
      var count = 0;
      for (final line in lines) {
        if (line.contains(cand)) count++;
      }
      // En cas d'egalite, on prefere le plus long (plus specifique).
      if (count > bestCount ||
          (count == bestCount && best != null && cand.length > best.length)) {
        bestCount = count;
        best = cand;
      }
    }

    // Au moins 2 mentions pour etre confident.
    return bestCount >= 2 ? best : null;
  }

  /// Vrai si le nom semble peu fiable (trop court, ou contient un
  /// libelle technique).
  static bool _looksUnreliable(String? name) {
    if (name == null || name.isEmpty) return true;
    if (name.length < 5) return true;
    final lower = name.toLowerCase();
    const technicalWords = [
      'lettre',
      'voiture',
      'matieres',
      'matières',
      'marchandise',
      'transporteur',
      'commissionnaire',
      'siret',
      'tel',
      'facture',
      'colis',
    ];
    for (final w in technicalWords) {
      if (lower.contains(w)) return true;
    }
    return false;
  }

  static bool _isObviousLabel(String s) {
    final lower = s.toLowerCase();
    const labels = [
      'lettre de voiture',
      'matieres dangereuses',
      'matières dangereuses',
      'transporteur',
      'commissionnaire',
      'instruction de livraison',
      'document de suivi',
      'lieu de livraison',
      'contact destinataire',
      'expediteur',
      'expéditeur',
      'destinataire',
      'desinataire',
      'mesexp',
      'messagerie express',
      'nature de la marchandise',
    ];
    for (final l in labels) {
      if (lower.contains(l)) return true;
    }
    return false;
  }

  static int _findNextStopIndex(List<String> lines, int from) {
    for (var i = from; i < lines.length; i++) {
      final lower = lines[i].toLowerCase();
      for (final m in _stopMarkers) {
        if (lower.contains(m)) return i;
      }
    }
    return lines.length;
  }

  /// Si on trouve plusieurs CP dans le bordereau (expediteur +
  /// destinataire), on prefere celui qui apparait APRES le marqueur
  /// `Destinataire` dans le flux OCR.
  static String? _findReceiverCp(List<String> lines, int destIdx) {
    String? firstCp;
    for (var i = 0; i < lines.length; i++) {
      final m = _cpRegex.firstMatch(lines[i]);
      if (m == null) continue;
      firstCp ??= m.group(1);
      if (destIdx >= 0 && i > destIdx) {
        return m.group(1);
      }
    }
    return firstCp;
  }

  /// Nettoie le nom de ville : retire les retours de mots-cles qui
  /// auraient pu se faufiler ("Total colis", "Transporteur"...) en
  /// coupant a la premiere occurrence.
  static String? _cleanVille(String? raw) {
    if (raw == null) return null;
    var s = raw.trim();
    for (final stop in _stopMarkers) {
      final i = s.toLowerCase().indexOf(stop);
      if (i > 0) s = s.substring(0, i).trim();
    }
    return s.isEmpty ? null : s;
  }
}
