import '../bordereau_extraction.dart';

/// Parser dedie aux **etiquettes autocollantes Transports France
/// Alliance** (sous-type MESEXP imprime par Eure et Loir Acheminement
/// et derives FA56 PNEUS / FA28 / FA02).
///
/// Calibre sur les 9 photos de reference du 11 mai 2026 (cf
/// `bordereaux_test/Bordereau livraison/colis/`). Deux sous-variantes
/// gerees :
///
/// **Variante A — Etiquette "complete"** :
/// - Layout structure avec labels `Destinataire :`, `RECEP :`,
///   `UM :`, `Poids :`, `PRODUIT : MESEXP`.
/// - Adresse format `FR - 28240 - LA LOUPE` (tirets).
///
/// **Variante B — Etiquette "compacte" (FA56 PNEUS et derives)** :
/// - Pas de label `Destinataire :`, le bloc adresse est en haut.
/// - Adresse format `FR 28400 ARCISSES` (sans tirets, separateurs
///   espaces).
/// - Compteur `COLIS X/Y` au lieu de `UM: X/Y`.
class ColisBordereauParser {
  const ColisBordereauParser();

  /// Adresse "FR - 28240 - LA LOUPE" OU "FR 28400 ARCISSES". Tirets ou
  /// espaces comme separateurs. Capture aussi les suffixes
  /// `SUR ...` / `SOUS ...` dans le groupe ville (ex: COURVILLE SUR
  /// EURE).
  static final _frAddressRegex = RegExp(
    r"FR\s*[-\s]\s*(\d{5})\s*[-\s]\s*([A-Z][A-Z\s\-']+?(?:\s+(?:SUR|SOUS|LES|EN|SAINT|SAINTE)\s+[A-Z][A-Z\s\-']+)?)(?:\s*$|\s+[A-Z]{2,}\d|\s+TRAVEE|\s+REF\.|\s+PRODUIT)",
    caseSensitive: false,
  );

  /// Variante plus permissive : sert au fallback si la stricte ne
  /// matche pas (ville coupee par l'OCR).
  static final _frAddressLooseRegex = RegExp(
    r"FR\s*[-\s]\s*(\d{5})\s*[-\s]\s*([A-Z][A-Z\s\-']*)",
    caseSensitive: false,
  );

  /// "UM: 1/3" -> total = 3. Y represente le nombre total de colis de
  /// l'envoi, X l'index du colis courant.
  static final _umRegex = RegExp(
    r"\bUM\s*:?\s*\d+\s*/\s*(\d+)",
    caseSensitive: false,
  );

  /// Variante "COLIS X/Y" (sous-format FA56 PNEUS et derives).
  static final _colisCounterRegex = RegExp(
    r"\bCOLIS\s+\d+\s*/\s*(\d+)",
    caseSensitive: false,
  );

  /// Marqueurs qui delimitent la fin du bloc destinataire. Inclure
  /// "um:", "poids", "recep" : sur les etiquettes ML Kit peut ramener
  /// le bloc destinataire colle avec les champs administratifs qui le
  /// suivent dans le layout visuel.
  static const _destinataireStopMarkers = [
    'travee',
    'travée',
    'ref.',
    'ref :',
    'produit',
    'instruction',
    'centre livreur',
    'tel:',
    'tel :',
    'um:',
    'um ',
    'poids',
    'recep',
    'dre_',
  ];

  BordereauExtraction parse(List<String> rawLines) {
    final lines = rawLines
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    // Etape 1 : label "Destinataire" (sans "contact", autre champ
    // MESEXP). Delimite le bloc.
    final destIdx = lines.indexWhere((l) {
      final lower = l.toLowerCase();
      return lower.contains('destinataire') && !lower.contains('contact');
    });

    String? nomDest;
    String? rue;
    String? cp;
    String? ville;

    if (destIdx >= 0) {
      final block = <String>[];
      for (var i = destIdx + 1; i < lines.length && i < destIdx + 8; i++) {
        final lower = lines[i].toLowerCase();
        if (_destinataireStopMarkers.any(lower.contains)) break;
        block.add(lines[i]);
      }
      // Bloc typique : nom / rue / (complement) / FR - CP - VILLE.
      if (block.isNotEmpty) {
        nomDest = block.first;
      }
      var foundFr = false;
      for (var i = 1; i < block.length; i++) {
        final match = _frAddressRegex.firstMatch(block[i]) ??
            _frAddressLooseRegex.firstMatch(block[i]);
        if (match != null) {
          cp = match.group(1);
          ville = _cleanVille(match.group(2));
          if (i > 1) {
            rue = block.sublist(1, i).join(' · ');
          }
          foundFr = true;
          break;
        }
      }
      // Fallback : OCR partiel sans "FR - CP - VILLE" reconnaissable
      // (ex: "28 - LA LOUPE" tronque). On garde quand meme la rue
      // depuis les lignes intermediaires pour ne pas tout perdre.
      if (!foundFr && block.length > 1) {
        rue = block.sublist(1).join(' · ');
      }
    }

    // Etape 2 (fallback variante B) : pas de label "Destinataire" trouve.
    // Localiser le pattern FR puis remonter pour rue + nom, en sautant
    // la zone EXP: (expediteur).
    if (cp == null) {
      for (var i = 0; i < lines.length; i++) {
        if (_isExpediteurLine(lines, i)) continue;
        final match = _frAddressRegex.firstMatch(lines[i]) ??
            _frAddressLooseRegex.firstMatch(lines[i]);
        if (match == null) continue;
        cp = match.group(1);
        ville = _cleanVille(match.group(2));
        if (i >= 1 && !_isLabelOrTransporter(lines[i - 1])) {
          rue = lines[i - 1];
        }
        if (i >= 2 && !_isLabelOrTransporter(lines[i - 2])) {
          final candidate = lines[i - 2];
          if (_looksLikeStreet(candidate)) {
            // -2 est la 2e ligne de rue, -3 est le nom (s'il existe).
            var combined = '$candidate · ${rue ?? ''}'.trim();
            if (combined.endsWith(' · ')) {
              combined = combined.substring(0, combined.length - 3);
            }
            rue = combined;
            if (i >= 3 && !_isLabelOrTransporter(lines[i - 3])) {
              nomDest = lines[i - 3];
            }
          } else {
            nomDest = candidate;
          }
        }
        break;
      }
    }

    // Etape 3 : nombre de colis depuis UM ou COLIS.
    int? nbColis;
    for (final line in lines) {
      final mUm = _umRegex.firstMatch(line);
      if (mUm != null) {
        nbColis = int.tryParse(mUm.group(1) ?? '');
        if (nbColis != null) break;
      }
      final mCol = _colisCounterRegex.firstMatch(line);
      if (mCol != null) {
        nbColis = int.tryParse(mCol.group(1) ?? '');
        if (nbColis != null) break;
      }
    }

    // Score de confiance (memes regles que MESEXP papier).
    final hasNom = nomDest != null && nomDest.isNotEmpty;
    final hasRue = rue != null && rue.isNotEmpty;
    final hasVille = (cp != null && cp.isNotEmpty) ||
        (ville != null && ville.isNotEmpty);
    final ExtractionConfidence confidence;
    if (hasNom && (hasRue || hasVille)) {
      confidence = ExtractionConfidence.high;
    } else if (hasNom || hasRue || hasVille || nbColis != null) {
      confidence = ExtractionConfidence.low;
    } else {
      confidence = ExtractionConfidence.none;
    }

    return BordereauExtraction(
      nomDestinataire: nomDest,
      rue: rue,
      codePostal: cp,
      ville: ville,
      nbColis: nbColis,
      confidence: confidence,
    );
  }

  /// Vrai si la ligne ou l'une des 2 precedentes contient un marqueur
  /// d'expediteur. Sert a ignorer le pattern FR de l'expediteur.
  static bool _isExpediteurLine(List<String> lines, int idx) {
    final from = (idx - 2).clamp(0, lines.length - 1);
    for (var i = from; i <= idx; i++) {
      final lower = lines[i].toLowerCase();
      if (lower.startsWith('exp:') ||
          lower.startsWith('exp :') ||
          lower.contains('expediteur') ||
          lower.contains('expéditeur')) {
        return true;
      }
    }
    return false;
  }

  /// Vrai si la ligne est un label/code technique (a ne pas confondre
  /// avec un nom destinataire).
  static bool _isLabelOrTransporter(String line) {
    final lower = line.toLowerCase();
    const labels = [
      'transports france alliance',
      'france alliance',
      'centre livreur',
      'eure et loir',
      'gellainville',
      'exp:',
      'exp :',
      'date :',
      'date:',
      'heure',
      'recep',
      'um:',
      'um :',
      'poids',
      'travee',
      'travée',
      'ref.',
      'ref :',
      'produit',
      'mesexp',
      'instruction',
      'colis ',
      'destinataire',
    ];
    for (final l in labels) {
      if (lower.contains(l)) return true;
    }
    if (RegExp(r'^(?:T\d{2,}|NAV\d+|FA\d+|\d{2})\s*$').hasMatch(line.trim())) {
      return true;
    }
    return false;
  }

  /// Vrai si la ligne ressemble a une rue (chiffre + mot de voirie OU
  /// mots cles type "ZONE ARTISANALE", "VILLAGE DES ENTREPRISES"...).
  static bool _looksLikeStreet(String line) {
    final lower = line.toLowerCase();
    if (RegExp(
            r'^\d+\s+(?:rue|avenue|av\.?|bd|boulevard|chemin|place|impasse|allee|all[ée]e|voie|route|rte|quai|cours|passage|faubourg|fbg)\b',
            caseSensitive: false)
        .hasMatch(lower)) {
      return true;
    }
    const streetWords = [
      ' rue ',
      ' avenue ',
      ' boulevard ',
      ' chemin ',
      ' place ',
      ' route ',
      ' impasse ',
      ' allee ',
      ' allée ',
      ' voie ',
      ' quai ',
      ' cours ',
      ' faubourg ',
      ' zone artisanale',
      ' zone industrielle',
      ' village des',
    ];
    final padded = ' $lower ';
    for (final w in streetWords) {
      if (padded.contains(w)) return true;
    }
    return false;
  }

  /// Nettoie la ville : retire les caracteres parasites et coupe au
  /// 1er marqueur technique trouve.
  static String? _cleanVille(String? raw) {
    if (raw == null) return null;
    var s = raw.trim();
    for (final stop in ['produit', 'travee', 'travée', 'tel', 'ref.']) {
      final i = s.toLowerCase().indexOf(stop);
      if (i > 0) s = s.substring(0, i).trim();
    }
    return s.isEmpty ? null : s;
  }
}
