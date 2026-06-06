import 'bordereau_extraction.dart';
import 'bordereau_patterns.dart';

/// Parser pour les étiquettes **France Alliance** (colis livrés par Noah).
///
/// Contrairement à MESEXP (1 feuille récap pour toute la tournée), ici
/// chaque étiquette est **collée sur un colis**. Le réseau France Alliance
/// regroupe plusieurs émetteurs/transporteurs avec des mises en page
/// différentes, mais qui partagent des ancres communes :
///
/// - **ALLIANCE PR** (pièces/pneus auto) : bandeaux `EXPEDITEUR` /
///   `DESTINATAIRE`, le nom suit une ligne `Code Client X-X`.
/// - **CSG / Seigneurie Gauthier** (peinture) : `COLIS x/y` en tête,
///   `EXPEDITEUR` / `DESTINATAIRE` côte à côte.
/// - **FA28 Transports / Beauceronne** : idem côte à côte, `No Colis`.
/// - **GETTYGO / France Alliance Réseau** : pas de mot `DESTINATAIRE`,
///   le destinataire est le bloc du haut.
///
/// Stratégie : on isole le bloc destinataire (ancre `DESTINATAIRE`, sinon
/// bloc précédant le 1er `CP VILLE`), on sépare nom / rue / CP+ville, et on
/// récupère téléphone + `COLIS x/y`. Le bloc `EXPEDITEUR` est ignoré.
///
/// ⚠️ Logique pure (`List<String>` -> `BordereauExtraction`), testable hors
/// device. La validation finale sur le vrai OCR ML Kit passe par le harness
/// d'éval (cf docs/ocr-france-alliance.md).
class FranceAllianceBordereauParser {
  static final _cpVilleRegex = BordereauPatterns.cpVilleRegex;
  static final _cpRegex = BordereauPatterns.cpRegex;
  static final _telRegex = BordereauPatterns.telRegex;
  static final _telSep = BordereauPatterns.telSepRegex;

  /// Ancre destinataire (tolère un suffixe : "DESTINATAIRE 0303603-1").
  static final _destMarker =
      RegExp(r'^\s*destinataire\b', caseSensitive: false);

  /// Ligne "Code Client 5359-0" (format ALLIANCE PR), à sauter : ce n'est
  /// pas le nom mais un identifiant interne.
  static final _codeClientMarker =
      RegExp(r'^\s*code\s*client\b', caseSensitive: false);

  /// "COLIS 1/11" -> total = 11. "COLIS 1/N" -> total inconnu (null).
  /// Le dénominateur peut être un nombre ou la lettre N.
  static final _colisFractionRegex =
      RegExp(r'\bcolis\s+\d{1,3}\s*/\s*(\d{1,3}|n)\b', caseSensitive: false);

  /// Lignes qui terminent (ou n'appartiennent pas à) le bloc destinataire :
  /// colonne "article" de ALLIANCE PR, en-tête expéditeur, transporteur...
  static final _stopMarkers = <RegExp>[
    RegExp(r'^\s*expediteur\b', caseSensitive: false),
    RegExp(r'^\s*no\s*dms', caseSensitive: false),
    RegExp(r'^\s*code\s*article', caseSensitive: false),
    RegExp(r'^\s*libell', caseSensitive: false),
    RegExp(r'^\s*r[eé]f\s*client', caseSensitive: false),
    RegExp(r'^\s*emplact', caseSensitive: false),
    RegExp(r'^\s*commentaire', caseSensitive: false),
    RegExp(r'^\s*transporteur', caseSensitive: false),
    RegExp(r'^\s*qt[eé]\b', caseSensitive: false),
    RegExp(r'^\s*no\s*colis', caseSensitive: false),
    RegExp(r'^\s*date\s+d', caseSensitive: false),
    RegExp(r'^\s*n[°o]\s+de\b', caseSensitive: false),
  ];

  /// Mots-clés réseau, pour le routeur OCR (choisir ce parser).
  static bool looksLikeFranceAlliance(List<String> lines) {
    final joined = lines.join('\n').toLowerCase();
    return joined.contains('alliance pr') ||
        joined.contains('france alliance') ||
        joined.contains('seigneurie gauthier') ||
        joined.contains('fa28 transports') ||
        joined.contains('gettygo') ||
        joined.contains('beauceronne') ||
        joined.contains('orn alliance');
  }

  BordereauExtraction parse(List<String> rawLines) {
    final lines = rawLines
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList(growable: false);
    if (lines.isEmpty) {
      return const BordereauExtraction(confidence: ExtractionConfidence.none);
    }

    final joined = lines.join('\n');
    final nbColis = _parseNbColis(joined);
    final telGlobal = _firstTel(joined);

    // 1) Bloc destinataire : après l'ancre DESTINATAIRE si présente, sinon
    //    le bloc précédant le 1er "CP VILLE" (cas GETTYGO sans ancre).
    final destIdx = _findIndex(lines, _destMarker);
    final List<String> block = destIdx != -1
        ? _collectAfter(lines, destIdx + 1)
        : _collectBeforeFirstCp(lines);
    if (block.isEmpty) {
      return _partial(telGlobal, nbColis, joined);
    }

    // 2) Découpe nom / rue / CP+ville.
    String? cp;
    String? ville;
    var cpIdx = -1;
    for (var i = 0; i < block.length; i++) {
      final m = _cpVilleRegex.firstMatch(block[i]);
      if (m != null) {
        cp = m.group(1);
        ville = m.group(2)?.trim();
        cpIdx = i;
        break;
      }
    }
    if (cpIdx == -1) {
      // CP seul (ville sur une autre ligne / OCR fragmenté).
      for (var i = 0; i < block.length; i++) {
        final m = _cpRegex.firstMatch(block[i]);
        if (m != null) {
          cp = m.group(1);
          cpIdx = i;
          break;
        }
      }
    }

    // Lignes au-dessus du CP = nom + rue. On purge FR/FRANCE et tel seuls.
    final avant = <String>[];
    final upper = cpIdx == -1 ? block.length : cpIdx;
    for (var i = 0; i < upper; i++) {
      final l = block[i];
      if (_isNoiseLine(l)) continue;
      avant.add(l);
    }

    String? nom;
    String? rue;
    if (avant.length >= 2) {
      rue = avant.last;
      nom = _joinNom(avant.sublist(0, avant.length - 1));
    } else if (avant.length == 1) {
      nom = avant.first; // pas de rue distincte
    }

    // Téléphone parfois collé au nom ("GARAGE DU CENTRE 0237267502").
    if (nom != null) {
      final telInline = _telRegex.firstMatch(nom);
      if (telInline != null) {
        nom = nom.replaceFirst(telInline.group(0)!, '').trim();
      }
    }
    nom = _cleanNom(nom);

    // Téléphone : on privilégie celui DANS le bloc destinataire (sinon on
    // capterait le tél du transporteur, ex "FA28 TRANSPORTS Tel ..." qui
    // précède le destinataire). Fallback : 1er tél du bordereau.
    final tel = _firstTel(block.join('\n')) ?? telGlobal;
    final hasCore = (nom != null && nom.isNotEmpty) &&
        (cp != null || (rue != null && rue.isNotEmpty));
    final hasSomething =
        nom != null || cp != null || rue != null || ville != null;

    return BordereauExtraction(
      nomDestinataire: nom,
      rue: rue,
      codePostal: cp,
      ville: ville,
      telephone: tel,
      nbColis: nbColis,
      confidence: hasCore
          ? ExtractionConfidence.high
          : hasSomething
              ? ExtractionConfidence.low
              : ExtractionConfidence.none,
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────

  /// Collecte les lignes du bloc destinataire à partir de [start] :
  /// saute "Code Client", s'arrête à un stop marker, et inclut la ligne
  /// CP+ville (puis stoppe). Plafonné à 7 lignes.
  static List<String> _collectAfter(List<String> lines, int start) {
    final out = <String>[];
    final hardLimit = (start + 7).clamp(0, lines.length);
    for (var i = start; i < hardLimit; i++) {
      final l = lines[i];
      if (_codeClientMarker.hasMatch(l)) continue;
      if (_isStopMarker(l)) break;
      out.add(l);
      if (_cpVilleRegex.hasMatch(l) || _cpRegex.hasMatch(l)) break;
    }
    return out;
  }

  /// Cas sans ancre DESTINATAIRE (GETTYGO) : le destinataire est le bloc
  /// du haut. On prend jusqu'à 4 lignes précédant le 1er CP+ville, en
  /// sautant les en-têtes connus.
  static List<String> _collectBeforeFirstCp(List<String> lines) {
    var cpIdx = -1;
    for (var i = 0; i < lines.length; i++) {
      if (_cpVilleRegex.hasMatch(lines[i])) {
        cpIdx = i;
        break;
      }
    }
    if (cpIdx == -1) return const [];
    final start = (cpIdx - 4).clamp(0, cpIdx);
    final out = <String>[];
    for (var i = start; i <= cpIdx; i++) {
      final l = lines[i];
      if (_isHeaderLine(l) || _isStopMarker(l)) continue;
      out.add(l);
    }
    return out;
  }

  /// Recolle les lignes d'un nom. Une ligne courte (≤6) tout en majuscules
  /// sans espace est traitée comme la suite d'un mot coupé par la largeur
  /// de l'étiquette (ex "CARROSSERIE DE LA CO" + "LLINE" -> "...COLLINE").
  static String _joinNom(List<String> parts) {
    final buf = StringBuffer();
    for (final raw in parts) {
      final p = raw.trim();
      if (p.isEmpty) continue;
      if (buf.isEmpty) {
        buf.write(p);
      } else if (p.length <= 6 &&
          p == p.toUpperCase() &&
          !p.contains(' ') &&
          !p.contains(RegExp(r'\d'))) {
        buf.write(p); // continuation d'un mot coupé
      } else {
        buf
          ..write(' ')
          ..write(p);
      }
    }
    return buf.toString();
  }

  static String? _cleanNom(String? nom) {
    if (nom == null) return null;
    final n = nom.replaceAll(BordereauPatterns.whitespaceRegex, ' ').trim();
    return n.isEmpty ? null : n;
  }

  int? _parseNbColis(String joined) {
    // Une fraction "colis x/y" prime et court-circuite le fallback (sinon
    // "COLIS 1/N" ferait capturer le numérateur "1" par colisSameLineRegex).
    final m = _colisFractionRegex.firstMatch(joined);
    if (m != null) {
      final denom = m.group(1)!;
      if (denom.toLowerCase() == 'n') return null; // total inconnu (x/N)
      final total = int.tryParse(denom);
      return (total != null && total > 0) ? total : null;
    }
    // Fallback format MESEXP-like ("total colis : N") si jamais présent.
    final m2 = BordereauPatterns.colisSameLineRegex.firstMatch(joined);
    if (m2 != null) return int.tryParse(m2.group(1)!);
    return null;
  }

  String? _firstTel(String joined) {
    final m = _telRegex.firstMatch(joined);
    if (m == null) return null;
    return m.group(1)!.replaceAll(_telSep, '');
  }

  /// Ligne sans valeur d'adresse : "FR", "FRANCE", ou un téléphone seul.
  static bool _isNoiseLine(String l) {
    final t = l.trim();
    if (RegExp(r'^fr$', caseSensitive: false).hasMatch(t)) return true;
    if (RegExp(r'^france$', caseSensitive: false).hasMatch(t)) return true;
    final stripped = t.replaceAll(_telSep, '');
    if (RegExp(r'^0\d{9}$').hasMatch(stripped)) return true; // tél seul
    if (RegExp(r'^tel\b', caseSensitive: false).hasMatch(t)) return true;
    return false;
  }

  static bool _isHeaderLine(String l) {
    final low = l.toLowerCase();
    return low.contains('gettygo') ||
        low.startsWith('getty') ||
        low.contains('alliance pr') ||
        low.contains('france alliance') ||
        low.contains('fa28 transports') ||
        low.contains('seigneurie gauthier') ||
        RegExp(r'^\s*colis\b', caseSensitive: false).hasMatch(l);
  }

  static bool _isStopMarker(String l) {
    for (final m in _stopMarkers) {
      if (m.hasMatch(l)) return true;
    }
    return false;
  }

  static int _findIndex(List<String> lines, RegExp pattern) {
    for (var i = 0; i < lines.length; i++) {
      if (pattern.hasMatch(lines[i])) return i;
    }
    return -1;
  }

  BordereauExtraction _partial(String? tel, int? nbColis, String joined) {
    final cpVille = _cpVilleRegex.firstMatch(joined);
    if (cpVille == null && tel == null) {
      return const BordereauExtraction(confidence: ExtractionConfidence.none);
    }
    return BordereauExtraction(
      codePostal: cpVille?.group(1),
      ville: cpVille?.group(2)?.trim(),
      telephone: tel,
      nbColis: nbColis,
      confidence: ExtractionConfidence.low,
    );
  }
}
