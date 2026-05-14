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
    // \b en debut pour eviter de matcher au milieu d'un long numero
    // (ex: "0237911586 THEODORE CHARTRES" matchait "11586 THEODORE").
    // [\s\-]+ accepte aussi le format "FR-CP-VILLE" ou "FR - CP - VILLE"
    // des etiquettes colis Transports France Alliance.
    r"\b(\d{5})[\s\-]+([A-Za-zÀ-ÿ][A-Za-zÀ-ÿ\s\-']+)",
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
    // un ordre logique. **Tout ou rien** : si le nom de la strategie
    // 1 est suspect (label technique), on rejette aussi sa rue (elle
    // vient du meme bloc fautif).
    String? nomDest;
    String? rue;
    if (destIdx >= 0) {
      final endIdx = _findNextStopIndex(lines, destIdx + 1);
      final block = lines.sublist(destIdx + 1, endIdx);
      if (block.isNotEmpty && !_looksUnreliable(block.first)) {
        nomDest = block.first;
        if (block.length > 1) {
          rue = block.skip(1).join(' · ');
        }
      }
    }

    // Strategie 2 (fallback) : nom par OCCURRENCES.
    // Le destinataire est mentionne 2 fois sur le bordereau (dans
    // "Contact destinataire" + dans le bloc Destinataire), alors que
    // l'expediteur est mentionne 1 fois.
    if (nomDest == null) {
      nomDest = _findNomByOccurrences(lines);
      // Si on bascule sur le fallback, on cherche la rue par adjacence
      // au nom (la rue de la strategie 1 vient du meme bloc fautif et
      // doit etre ignoree -- mais elle est deja a null grace au reset
      // ci-dessus).
      if (nomDest != null) {
        rue = _findRueAdjacenteNom(lines, nomDest);
      }
    } else {
      // Nom de la strategie 1 OK mais pas de rue : tenter l'adjacence.
      rue ??= _findRueAdjacenteNom(lines, nomDest);
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

    // Fallback 1 : adjacence au nom destinataire avec bonus si la
    // ville matche un mot du nom (ex: "CHARTRES" dans "THEODORE
    // CHARTRES" -> on prefere "28000 CHARTRES" meme si un autre CP
    // est plus proche en distance).
    if (cp == null && nomDest != null) {
      final adj = _findCpAdjacentNom(lines, nomDest);
      if (adj != null) {
        cp = adj.cp;
        ville = adj.ville;
      }
    }

    // Fallback 2 : 1er CP trouve apres le label Destinataire (ancien
    // comportement). Risque de prendre le CP du transporteur si l'ordre
    // OCR est chaotique.
    if (cp == null) {
      cp = _findReceiverCp(lines, destIdx);
      if (cp != null) {
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

    // Score de confiance :
    // - high : on a un nom + au moins (rue ou cp+ville)
    // - low : on a quelque chose mais c'est partiel ou ambigu
    // - none : aucun champ utile
    final ExtractionConfidence confidence;
    final hasNom = nomDest != null && nomDest.isNotEmpty;
    final hasRue = rue != null && rue.isNotEmpty;
    final hasVille = (cp != null && cp.isNotEmpty) ||
        (ville != null && ville.isNotEmpty);
    final hasColisOrTel = nbColis != null || telephone != null;

    if (hasNom && (hasRue || hasVille)) {
      confidence = ExtractionConfidence.high;
    } else if (hasNom || hasRue || hasVille || hasColisOrTel) {
      confidence = ExtractionConfidence.low;
    } else {
      confidence = ExtractionConfidence.none;
    }

    return BordereauExtraction(
      nomDestinataire: nomDest,
      rue: rue,
      codePostal: cp,
      ville: ville,
      telephone: telephone,
      nbColis: nbColis,
      confidence: confidence,
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
  ///
  /// Filtres anti-faux-positifs :
  /// - `_isObviousLabel` : exclut les labels techniques.
  /// - `_looksLikeStreet` : exclut les rues (commencent par AVENUE/RUE/etc).
  /// - `_looksLikeTransporter` : exclut les transporteurs courants.
  /// - `_lineIsStreet` : ne compte pas une occurrence si la ligne
  ///   complete est une rue numerotee (ex: "LOUIS PASTEUR" dans
  ///   "24 AVENUE LOUIS PASTEUR" est juste un nom de saint, pas un
  ///   destinataire).
  static String? _findNomByOccurrences(List<String> lines) {
    final pattern = RegExp(r"([A-Z][A-Z\-']+(?:\s+[A-Z][A-Z\-']+)+)");
    final candidates = <String>{};
    for (final line in lines) {
      for (final m in pattern.allMatches(line)) {
        final s = m.group(1)!.trim();
        if (s.length < 10) continue;
        if (_isObviousLabel(s)) continue;
        if (_looksLikeStreet(s)) continue;
        if (_looksLikeTransporter(s)) continue;
        candidates.add(s);
      }
    }

    String? best;
    int bestCount = 0;
    for (final cand in candidates) {
      var count = 0;
      for (final line in lines) {
        if (!line.contains(cand)) continue;
        // Si l'occurrence est dans une ligne qui est manifestement
        // une rue numerotee, on ne la compte pas.
        if (_lineIsStreet(line)) continue;
        count++;
      }
      if (count > bestCount ||
          (count == bestCount && best != null && cand.length > best.length)) {
        bestCount = count;
        best = cand;
      }
    }

    // Strict : au moins 2 mentions pour etre confident. Sinon on
    // retourne null et l'UI affichera une carte "incertain".
    return bestCount >= 2 ? best : null;
  }

  /// Vrai si la ligne entiere est une rue numerotee (commence par un
  /// chiffre suivi d'un mot de voirie). Sert a ignorer les occurrences
  /// d'un candidat dans une rue (ex: "LOUIS PASTEUR" dans "24 AVENUE
  /// LOUIS PASTEUR").
  static final _streetLineRegex = RegExp(
    r"^\d+\s*(?:bis|ter|quater)?\s+(?:RUE|AVENUE|AV\.?|BD|BOULEVARD|CHEMIN|PLACE|IMPASSE|ALL[EÉ]E|VOIE|ROUTE|RTE|QUAI|COURS|PASSAGE|FAUBOURG|FBG)\b",
    caseSensitive: false,
  );

  static bool _lineIsStreet(String line) {
    return _streetLineRegex.hasMatch(line.trim());
  }

  /// Vrai si le candidat ressemble a une rue (commence ou contient un
  /// mot de rue francais). Evite de prendre "AVENUE LOUIS PASTEUR"
  /// comme nom d'entreprise.
  static bool _looksLikeStreet(String s) {
    final lower = s.toLowerCase();
    const streetWords = [
      'rue ',
      'avenue ',
      'boulevard ',
      ' bd ',
      'impasse ',
      'place ',
      'chemin ',
      'voie ',
      'route ',
      'allee ',
      'allée ',
      'cours ',
      'quai ',
      'passage ',
      'faubourg ',
      'fbg ',
    ];
    final padded = ' ${lower.toLowerCase()} ';
    for (final w in streetWords) {
      if (padded.contains(w)) return true;
    }
    return false;
  }

  /// Vrai si le candidat ressemble a un nom de transporteur courant.
  /// Evite de prendre "EURE ET LOIR ACHEMINEMENT" ou "FA45 TRANSPORTS"
  /// comme destinataire.
  static bool _looksLikeTransporter(String s) {
    final lower = s.toLowerCase();
    const transporterWords = [
      'acheminement',
      'transports',
      'transporteur',
      'logistique',
      'messagerie',
    ];
    for (final w in transporterWords) {
      if (lower.contains(w)) return true;
    }
    return false;
  }

  /// Vrai si le nom semble peu fiable (trop court, ou contient un
  /// libelle technique).
  ///
  /// Seuil de longueur fixe a 3 caracteres pour accepter les noms
  /// courts mais legitimes : "NOVA" (4), "IBM", "BMW", "FA45". Le
  /// filtre principal est la liste de mots techniques.
  static bool _looksUnreliable(String? name) {
    if (name == null || name.isEmpty) return true;
    if (name.length < 3) return true;
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

  /// Cherche le CP+ville du destinataire par adjacence au nom dans le
  /// flux OCR, avec un **bonus** si le nom de ville apparait dans le
  /// nom du destinataire (cas typique : "THEODORE CHARTRES" -> "28000
  /// CHARTRES" est preferee meme si un autre CP est plus proche en
  /// distance).
  static ({String cp, String? ville})? _findCpAdjacentNom(
    List<String> lines,
    String nomDest,
  ) {
    final nomIndices = <int>[];
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].contains(nomDest)) nomIndices.add(i);
    }
    if (nomIndices.isEmpty) return null;

    final nomWords = nomDest
        .split(RegExp(r'\s+'))
        .where((w) => w.length >= 4)
        .map((w) => w.toLowerCase())
        .toList();

    // Trouver toutes les lignes contenant un CP+ville
    final candidates = <({int idx, String cp, String? ville})>[];
    for (var i = 0; i < lines.length; i++) {
      final m = _cpVilleRegex.firstMatch(lines[i]);
      if (m != null) {
        candidates.add((
          idx: i,
          cp: m.group(1)!,
          ville: _cleanVille(m.group(2)),
        ));
      } else {
        final cpOnly = _cpRegex.firstMatch(lines[i]);
        if (cpOnly != null) {
          candidates.add((idx: i, cp: cpOnly.group(1)!, ville: null));
        }
      }
    }
    if (candidates.isEmpty) return null;

    ({int idx, String cp, String? ville})? best;
    int bestScore = 999999;
    for (final c in candidates) {
      var minDist = 999;
      for (final nomIdx in nomIndices) {
        final d = (c.idx - nomIdx).abs();
        if (d < minDist) minDist = d;
      }
      var score = minDist;
      // Bonus -1000 si la ville contient un mot du nom destinataire.
      final villeLower = c.ville?.toLowerCase() ?? '';
      for (final w in nomWords) {
        if (villeLower.contains(w)) {
          score -= 1000;
          break;
        }
      }
      if (score < bestScore) {
        bestScore = score;
        best = c;
      }
    }

    return best == null ? null : (cp: best.cp, ville: best.ville);
  }

  /// Cherche la rue du destinataire **adjacente** au nom dans le flux
  /// OCR. ML Kit groupe les lignes du meme bloc visuel ensemble : la
  /// rue est donc typiquement a +/- 1 ligne du nom, meme si l'ordre
  /// global des blocs est chaotique.
  ///
  /// On scanne en cercles concentriques autour de chaque occurrence
  /// du nom (rayon 1, puis 2, ..., 8 pour la BP). On prend la 1ere rue
  /// trouvee et on accole la BP si elle est proche aussi.
  static String? _findRueAdjacenteNom(List<String> lines, String nomDest) {
    final ruePattern = RegExp(
      r"^\d+\s*(?:bis|ter|quater)?\s+(?:RUE|AVENUE|AV\.?|BD|BOULEVARD|CHEMIN|PLACE|IMPASSE|ALLEE|ALL[EÉ]E|VOIE|ROUTE|RTE|QUAI|COURS|PASSAGE|FAUBOURG|FBG)\b",
      caseSensitive: false,
    );
    final bpPattern = RegExp(r"^BP\s*\d+", caseSensitive: false);

    final nomIndices = <int>[];
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].contains(nomDest)) nomIndices.add(i);
    }
    if (nomIndices.isEmpty) return null;

    String? rue;
    int rueDist = 999;
    String? bp;
    int bpDist = 999;

    // Rayon 8 (englobe la BP qui est souvent plus eloignee que la rue).
    for (final nomIdx in nomIndices) {
      for (var offset = 1; offset <= 8; offset++) {
        for (final i in [nomIdx - offset, nomIdx + offset]) {
          if (i < 0 || i >= lines.length) continue;
          final line = lines[i].trim();
          if (rue == null || offset < rueDist) {
            if (ruePattern.hasMatch(line)) {
              rue = line;
              rueDist = offset;
            }
          }
          if (bp == null || offset < bpDist) {
            if (bpPattern.hasMatch(line)) {
              bp = line;
              bpDist = offset;
            }
          }
        }
      }
    }

    if (rue == null && bp == null) return null;
    return [?rue, ?bp].join(' · ');
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
