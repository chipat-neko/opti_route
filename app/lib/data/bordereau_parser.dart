import 'package:flutter/foundation.dart' show debugPrint;

import 'app_constants.dart';
import 'bordereau_extraction.dart';
import 'bordereau_format_detector.dart';
import 'bordereau_patterns.dart';
import 'bordereau_text_filters.dart';
import 'ocr_service.dart' show OcrBlock;

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
    // ENLEVEMENT (Eure et Loir Acheminement) : bloc "destination" en
    // colonne, le nom client + rue + CP/ville sont a cote du label.
    'destination',
    'a enlever chez',
    'à enlever chez',
  ];
  static const _markersTotalColis = [
    'total colis',
    'colis :',
    // ENLEVEMENT : la colonne du tableau s'appelle "U.M."
    // (Unites de Manutention). La valeur 1/2/3... est sur la ligne
    // d'apres ou meme cellule.
    'u.m.',
    'u m ',
  ];
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

  // Patterns regex deplaces dans BordereauPatterns (audit 2026-05-22)
  // pour eliminer la triple duplication entre les 3 parseurs.
  static final _cpVilleRegex = BordereauPatterns.cpVilleRegex;
  static final _cpRegex = BordereauPatterns.cpRegex;
  static final _telRegex = BordereauPatterns.telRegex;

  /// **Approche spatiale pure** (feedback Noah 2026-05-23) :
  /// 1. Trouve le bloc qui contient le label "destinataire" (LIVRAISON)
  ///    OU "à enlever chez" (ENLEVEMENT)
  /// 2. Trouve le bloc PHYSIQUEMENT en dessous (top du contenu > bottom
  ///    du label, overlap horizontal X > 30%, plus proche verticalement)
  /// 3. Extrait nom + adresse depuis CE bloc, sans heuristique de contenu
  ///
  /// **Hypothese** : sur tous les bordereaux MESEXP / Colissimo /
  /// Chronopost, le label "destinataire" est en HEADER, le contenu
  /// (nom + adresse) est dans le rectangle JUSTE EN DESSOUS. C'est ce
  /// que voit visuellement Noah quand il scanne le bordereau.
  ///
  /// **Plus simple et plus fiable** que [parseFromBlocks] qui tentait
  /// de filtrer le contenu (heuristiques labels, departements, etc).
  /// Ici on fait juste de la geometrie : le bloc en bas est le bon.
  ///
  /// Pour le `nbColis`, on NE l'extrait pas (Noah le saisit a la main).
  ///
  /// Retourne null si aucun label trouve ou aucun bloc en dessous
  /// detecte -> le caller fallback sur [parseFromBlocks].
  BordereauExtraction? parseFromBlocksSpatial(List<OcrBlock> blocks) {
    if (blocks.isEmpty) return null;
    // Debug : log la structure des blocs pour analyse sur les cas
    // pathologiques (filtrer dans logcat via grep OCRDUMP-SPATIAL).
    for (var i = 0; i < blocks.length; i++) {
      final b = blocks[i];
      // Logue uniquement le 1er mot de chaque ligne pour rester court.
      final preview = b.lines.take(3).map((l) {
        final words = l.split(' ');
        return words.take(2).join(' ');
      }).join(' | ');
      // Position : [left,top,right,bottom]
      debugPrint(
          'OCRDUMP-SPATIAL bloc#$i [${b.left.toInt()},${b.top.toInt()},'
          '${b.right.toInt()},${b.bottom.toInt()}] (${b.lines.length}L): $preview');
    }

    // Detection format global pour decider quel label prioriser.
    final allLines = <String>[];
    for (final b in blocks) {
      allLines.addAll(b.lines);
    }
    final format = BordereauFormatDetector.detect(allLines);

    // Marqueurs prioritaires selon le format.
    final markers = format == BordereauFormat.enlevement
        ? const ['enlever chez', 'estinataire', 'destinataire']
        : const ['estinataire', 'destinataire', 'enlever chez'];

    // Chercher le bloc qui contient un de ces marqueurs.
    OcrBlock? labelBlock;
    for (final marker in markers) {
      for (final b in blocks) {
        for (final line in b.lines) {
          final lower = line.toLowerCase().trim();
          if (lower.contains(marker)) {
            // Exclure les faux positifs typiques.
            if (marker == 'estinataire' &&
                (lower.contains('contact') || lower.contains('ref'))) {
              continue;
            }
            labelBlock = b;
            break;
          }
        }
        if (labelBlock != null) break;
      }
      if (labelBlock != null) break;
    }
    if (labelBlock == null) return null;

    // v3 Sprint 2026-05-23 (logs Noah analyses) : sur les bordereaux
    // MESEXP retour, le label "à enlever chez" est souvent dans un
    // COIN de la cellule tableau (ex en haut a droite), et le contenu
    // remplit la cellule (peut etre a GAUCHE ou DESSOUS du label).
    // L'approche "strictement dessous + overlap X" ratait ces cas.
    //
    // Nouvelle strategie : prendre les N blocs les plus PROCHES du
    // label en distance Euclidienne (centre a centre), filtrer les
    // parasites (headers tableau, labels), grouper les 3 plus proches
    // restants comme contenu destinataire.
    final labelCenterX = (labelBlock.left + labelBlock.right) / 2;
    final labelCenterY = (labelBlock.top + labelBlock.bottom) / 2;
    final candidates = <({OcrBlock block, double distance})>[];
    for (final b in blocks) {
      if (identical(b, labelBlock)) continue;
      // Filtre 1 : bloc qui contient un autre label tableau ou parasite
      // (Régime, U.M., Vol, Poids, Date, Client, Ligne, Nature, etc).
      var isHeaderBlock = false;
      for (final line in b.lines) {
        if (BordereauTextFilters.isTableHeaderLine(line) ||
            BordereauTextFilters.isObviousLabel(line)) {
          isHeaderBlock = true;
          break;
        }
      }
      if (isHeaderBlock) continue;
      // Distance Euclidienne entre centres
      final bCenterX = (b.left + b.right) / 2;
      final bCenterY = (b.top + b.bottom) / 2;
      final dx = bCenterX - labelCenterX;
      final dy = bCenterY - labelCenterY;
      final dist = (dx * dx + dy * dy);
      candidates.add((block: b, distance: dist));
    }
    if (candidates.isEmpty) return null;
    // Trier par distance croissante
    candidates.sort((a, b) => a.distance.compareTo(b.distance));

    // Prendre les 5 plus proches puis filtrer ceux dont les lignes
    // sont des fragments parasites (juste un mot court, juste un
    // numero, etc).
    // Prendre les 5 plus proches blocs (apres filtre parasite) et
    // ASSEMBLER leurs lignes en preservant l'ordre de proximite.
    // Le bloc le plus proche fournit en general le nom, les suivants
    // l'adresse. _buildExtractionFromContentLines fera le tri.
    final nearby = candidates.take(5).map((c) => c.block).toList();
    final assembledLines = <String>[];
    for (final b in nearby) {
      for (final line in b.lines) {
        final clean = line.trim();
        if (clean.isEmpty) continue;
        if (BordereauTextFilters.looksUnreliable(clean)) continue;
        if (BordereauTextFilters.isTableHeaderLine(clean)) continue;
        assembledLines.add(clean);
      }
    }
    if (assembledLines.isEmpty) return null;
    // Debug : afficher l'assemblage final pour audit
    debugPrint(
        'OCRDUMP-SPATIAL assembled (${assembledLines.length} lignes): '
        '${assembledLines.join(" | ")}');
    return _buildExtractionFromContentLines(assembledLines, format);
  }

  /// Construit une [BordereauExtraction] depuis les lignes "contenu"
  /// du bloc destinataire trouve par [parseFromBlocksSpatial].
  ///
  /// Heuristique simple :
  /// - 1ere ligne non-vide qui n'est PAS un CP/ville/rue -> nomDest
  /// - ligne avec un numero + voirie (RUE/AVENUE/etc) -> rue
  /// - ligne avec CP 5 chiffres + ville -> cp + ville
  /// - reste -> ignore (ou ajoute a rue si rien d'autre)
  static BordereauExtraction _buildExtractionFromContentLines(
    List<String> lines,
    BordereauFormat format,
  ) {
    String? nomDest;
    String? rue;
    String? cp;
    String? ville;

    // Sprint 2026-05-23 v4 : 2 passes pour pas que le 1er candidat
    // gagne automatiquement. Pass 1 : extraire CP/ville/rue (assignes
    // direct). Pass 2 : choisir le meilleur NOM parmi les lignes non
    // categorisees, en preferant les lignes 100% MAJUSCULES (nom
    // d'entreprise typique : NOGENT AUTO, GARAGE LANCTIN DAMIEN, etc).
    final nameCandidates = <String>[];
    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      // CP+ville sur la meme ligne
      final cpVille = BordereauPatterns.cpVilleRegex.firstMatch(line);
      if (cpVille != null) {
        cp ??= cpVille.group(1);
        ville ??= _cleanVille(cpVille.group(2));
        continue;
      }
      // CP seul
      final cpOnly = BordereauPatterns.cpRegex.firstMatch(line);
      if (cpOnly != null && cp == null) {
        cp = cpOnly.group(1);
        continue;
      }
      // Rue : matche pattern rue (numerotee OU RN/RD)
      if (BordereauPatterns.ruePattern.hasMatch(line)) {
        rue ??= line;
        continue;
      }
      // Nombre seul (8.0, 1.0, 2.0...) : skip, c'est probablement un
      // poids/U.M./quantite parasite.
      if (BordereauPatterns.unitColisLineRegex.hasMatch(line)) {
        continue;
      }
      // Tout le reste = candidat nom potentiel
      nameCandidates.add(line);
    }

    // Choisir le nom : prefere une ligne 100% MAJUSCULES (>= 2 mots OU
    // >= 4 chars). Sinon fallback : prend la 1ere ligne candidate.
    String? bestName;
    int bestScore = -1;
    for (final cand in nameCandidates) {
      final upper = cand.toUpperCase() == cand;
      final wordCount = cand.split(BordereauPatterns.whitespaceRegex).length;
      final score =
          (upper ? 100 : 0) + (wordCount >= 2 ? 50 : 0) + cand.length;
      if (score > bestScore) {
        bestScore = score;
        bestName = cand;
      }
    }
    nomDest = bestName;

    // Si on n'a pas trouve de rue mais qu'il reste des candidats non
    // utilises pour le nom, en prendre 1 comme rue (complement adresse).
    if (rue == null && nameCandidates.length > 1 && nomDest != null) {
      for (final cand in nameCandidates) {
        if (cand == nomDest) continue;
        rue = cand;
        break;
      }
    }

    final ExtractionConfidence confidence;
    final hasNom = nomDest != null && nomDest.isNotEmpty;
    final hasAddr = (rue != null && rue.isNotEmpty) ||
        (cp != null && cp.isNotEmpty) ||
        (ville != null && ville.isNotEmpty);
    if (hasNom && hasAddr) {
      confidence = ExtractionConfidence.high;
    } else if (hasNom || hasAddr) {
      confidence = ExtractionConfidence.low;
    } else {
      confidence = ExtractionConfidence.none;
    }

    return BordereauExtraction(
      nomDestinataire: nomDest,
      rue: rue,
      codePostal: cp,
      ville: ville,
      confidence: confidence,
      format: format,
    );
  }

  // _horizontalOverlap supprime v3 Sprint 2026-05-23 : remplace par
  // distance Euclidienne centre-a-centre dans parseFromBlocksSpatial.

  /// Parse en ciblant le GROS encadre visuel du bordereau (typiquement
  /// celui qui contient le nom + adresse de ramasse / destinataire).
  ///
  /// Utilise les bounding boxes ML Kit pour :
  /// 1. Detecter le format global (ENLEVEMENT/LIVRAISON) sur toutes les
  ///    lignes concatenees
  /// 2. Trouver le bloc qui contient le label prioritaire ('enlever
  ///    chez' / 'estinataire' / 'destination') selon le format
  /// 3. Si plusieurs blocs candidats : prendre celui qui a la plus
  ///    grande SURFACE (= le gros encadre central visuel)
  /// 4. Construire la "zone de scan" = ce bloc + tous les blocs qui
  ///    chevauchent verticalement avec lui (overlap Y > 30%)
  /// 5. Appeler [parse] sur cette zone uniquement -> elimine la
  ///    pollution des blocs voisins (en-tete, footer, conditions
  ///    generales)
  ///
  /// Si aucun bloc candidat n'est trouve (pas de label dans les blocs),
  /// fallback sur [parse] avec toutes les lignes (comportement actuel).
  BordereauExtraction parseFromBlocks(List<OcrBlock> blocks) {
    if (blocks.isEmpty) return parse(const []);

    // Detection format sur l'ensemble des lignes.
    final allLines = <String>[];
    for (final b in blocks) {
      allLines.addAll(b.lines);
    }
    final format = BordereauFormatDetector.detect(allLines);

    // Sprint 2026-05-23 : pre-filtre des blocs PARASITES qui sont
    // manifestement des blocs "transporteur" / "conditions generales"
    // / "footer". Si on les inclut dans le ciblage bbox, le parser
    // peut extraire des noms parasites (ex "Eure et Loir Acheminement"
    // au lieu du destinataire). On les exclut tot pour cibler les
    // blocs metier.
    var usableBlocks = blocks.where((b) {
      return !_isParasiteBlock(b);
    }).toList();

    // Renforcement v2 (feedback Noah 2026-05-23 sur MESEXP retour) :
    // si AU MOINS UN bloc contient un CP du dpt prefere (28), on exclut
    // tous les autres blocs qui contiennent UNIQUEMENT des CP hors-zone
    // (cas type : bloc expediteur "Alliance PR" 72210 VOIVRES, alors
    // que le destinataire ramasse est "GARAGE LANCTIN" 28190).
    // Marche pour ENLEVEMENT comme LIVRAISON (sauf si tu vraiment
    // travailles partout en France -- dans ce cas il faut changer
    // kCodePostalPrefere).
    final hasPreferredCpAnywhere = blocks.any((b) =>
        b.lines.any((l) {
          final m = BordereauPatterns.cpRegex.firstMatch(l);
          return m != null && m.group(1)!.startsWith(kCodePostalPrefere);
        }));
    if (hasPreferredCpAnywhere) {
      usableBlocks = usableBlocks.where((b) {
        // Garder si le bloc N'A AUCUN CP (label seulement, OK) OU
        // contient un CP du dpt prefere. Exclure les blocs qui ont
        // SEULEMENT des CP hors-zone (= blocs expediteur typiquement).
        var hasAnyCp = false;
        var hasPreferredCp = false;
        for (final line in b.lines) {
          final m = BordereauPatterns.cpRegex.firstMatch(line);
          if (m != null) {
            hasAnyCp = true;
            if (m.group(1)!.startsWith(kCodePostalPrefere)) {
              hasPreferredCp = true;
              break;
            }
          }
        }
        if (!hasAnyCp) return true; // bloc sans CP : on garde
        return hasPreferredCp;
      }).toList();
    }

    // Si tous les blocs sont marques parasites (rare, image tres
    // bizarre), on retombe sur tous les blocs pour ne pas tout perdre.
    final blocksToUse = usableBlocks.isEmpty ? blocks : usableBlocks;

    // Ordre de priorite des marqueurs en mode bbox. ATTENTION : on
    // EXCLUT 'destination' sur ENLEVEMENT car ce label pointe vers
    // l'adresse de destination FINALE (Alliance PR a Voivres) et non
    // vers le lieu de ramasse. En mode parse() plat, ML Kit melange
    // les blocs et 'destination' tombe par chance sur le bon bloc,
    // mais en mode bbox c'est isole donc on a la mauvaise adresse.
    // Si 'enlever chez' et 'estinataire' echouent, on fallback sur
    // parse(allLines) qui sait gerer le melange.
    final markerPriority = format == BordereauFormat.enlevement
        ? const ['enlever chez', 'estinataire']
        : const ['estinataire', 'destination', 'enlever chez'];

    // Pour chaque marqueur dans l'ordre, on cherche les blocs qui
    // contiennent ce label (ou sont ADJACENTS verticalement a un bloc
    // qui le contient).
    for (final marker in markerPriority) {
      final hits = <OcrBlock>[];
      for (final b in blocksToUse) {
        for (final line in b.lines) {
          final lower = line.toLowerCase().trim();
          if (marker == 'estinataire') {
            if (!lower.contains('estinataire')) continue;
            if (lower.contains('contact')) continue;
            if (lower.contains('ref')) continue;
            hits.add(b);
            break;
          }
          if (marker == 'destination') {
            if (lower == 'destination' || lower.startsWith('destination ')) {
              hits.add(b);
              break;
            }
            continue;
          }
          if (lower.contains(marker)) {
            hits.add(b);
            break;
          }
        }
      }
      if (hits.isEmpty) continue;

      // Plusieurs blocs contiennent le label : on prend le GROS (plus
      // grande surface). C'est le critere visuel de Noah : "toujours
      // dans le gros encadre".
      hits.sort((a, b) => b.area.compareTo(a.area));
      final anchor = hits.first;

      // Zone de scan = anchor + blocs adjacents verticalement (chevauche
      // sur l'axe Y, donc meme bande horizontale). Filtre les blocs
      // tres petits (surface < 5% de l'anchor) qui sont du bruit.
      // On exclut aussi les blocs parasites identifies au pre-filtre.
      final zone = <OcrBlock>[anchor];
      for (final b in blocksToUse) {
        if (identical(b, anchor)) continue;
        if (b.area < anchor.area * 0.05) continue;
        if (_verticalOverlap(anchor, b) < 0.3) continue;
        zone.add(b);
      }
      // Trier par X (gauche -> droite) puis Y (haut -> bas) pour avoir
      // un ordre de lecture naturel.
      zone.sort((a, b) {
        final dx = a.left.compareTo(b.left);
        if (dx != 0) return dx;
        return a.top.compareTo(b.top);
      });
      final zoneLines = <String>[];
      for (final b in zone) {
        zoneLines.addAll(b.lines);
      }
      // On delegue a parse() qui sait deja faire le reste (filtres,
      // fallback, format, etc) -- mais sur un sous-ensemble cible.
      final zoneResult = parse(zoneLines);
      // Validation du resultat cible : si le nom extrait est solide
      // (2+ mots OU >= 8 chars), on garde. Sinon, le ciblage bbox a
      // probablement isole un bloc parasite (header tableau, footer)
      // et on fallback sur le parse classique de toutes les lignes
      // qui s'en sort mieux dans ces cas-la.
      final nom = zoneResult.nomDestinataire;
      if (nom != null) {
        final wordCount = nom.split(BordereauPatterns.whitespaceRegex).length;
        if (wordCount >= 2 || nom.length >= 8) {
          return zoneResult;
        }
      }
      // Resultat fragment : on essaie le marqueur suivant.
      continue;
    }

    // Aucun marqueur n'a donne un resultat solide : fallback complet.
    return parse(allLines);
  }

  /// Vrai si le bloc est manifestement un bloc PARASITE (transporteur,
  /// footer conditions generales, en-tete MESEXP, etc) qui ne contient
  /// pas le destinataire et qui pollue le ciblage si on le garde.
  ///
  /// Heuristique : on regarde si plus de 30% des lignes du bloc
  /// contiennent un mot-cle parasite. Le seuil 30% (au lieu de 1
  /// ligne) evite de rejeter les blocs destinataire qui auraient juste
  /// le mot "destination" comme header.
  static bool _isParasiteBlock(OcrBlock block) {
    if (block.lines.isEmpty) return false;
    // Sprint 2026-05-23 (feedback Noah) : bloc avec "ZA DE" + un CP
    // hors zone Eure-et-Loir = bloc EXPEDITEUR (Sarthe, Paris, etc).
    // On le marque parasite pour ne pas extraire son nom comme client.
    var hasZaKeyword = false;
    var hasOutOfZoneCp = false;
    for (final line in block.lines) {
      final lower = line.toLowerCase();
      if (lower.contains('za de') ||
          lower.contains('z.a.') ||
          lower.contains('zone artisanale') ||
          lower.contains('zone industrielle')) {
        hasZaKeyword = true;
      }
      final cpMatch = BordereauPatterns.cpRegex.firstMatch(line);
      if (cpMatch != null) {
        final cp = cpMatch.group(1)!;
        final isInZone = kCodePostalPreferes.any((d) => cp.startsWith(d));
        // Cas typique : CP 72xxx (Sarthe), 75xxx (Paris), etc, dans
        // un bloc qui contient aussi "ZA DE" = bloc expediteur.
        if (!isInZone) hasOutOfZoneCp = true;
      }
    }
    if (hasZaKeyword && hasOutOfZoneCp) return true;
    const parasiteKeywords = [
      // Transporteur Eure et Loir Acheminement
      'eure et loir',
      'eure-et-loir',
      'acheminement',
      'siret:',
      'siret ',
      // Footer conditions generales
      'avril 1999',
      'décret du 6',
      'decret du 6',
      'commerce',
      'recommandee',
      'recommandée',
      'conditions générales',
      'conditions generales',
      'art l133',
      'art |133',
      'art 1133',
      'art i133',
      'l133-3',
      // En-tete MESEXP / labels secondaires
      'agence remettante',
      'documents de suivi',
      'document de suivi',
      'cachet de l\'expéditeur',
      'cachet de l\'expediteur',
    ];
    var hits = 0;
    for (final line in block.lines) {
      final lower = line.toLowerCase();
      for (final kw in parasiteKeywords) {
        if (lower.contains(kw)) {
          hits++;
          break;
        }
      }
    }
    // > 30 % des lignes contiennent un mot-cle parasite = bloc parasite
    return hits / block.lines.length > 0.3;
  }

  /// Ratio de chevauchement vertical entre 2 blocs (0 = aucun, 1 =
  /// totalement contenu). Calcule par rapport au plus petit des deux.
  static double _verticalOverlap(OcrBlock a, OcrBlock b) {
    final overlapTop = a.top > b.top ? a.top : b.top;
    final overlapBottom = a.bottom < b.bottom ? a.bottom : b.bottom;
    final overlap = overlapBottom - overlapTop;
    if (overlap <= 0) return 0;
    final smaller = a.height < b.height ? a.height : b.height;
    if (smaller <= 0) return 0;
    return overlap / smaller;
  }

  BordereauExtraction parse(List<String> rawLines) {
    final lines = rawLines
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList(growable: false);

    // Detection du format : ENLEVEMENT si on voit un des marqueurs
    // specifiques (label "ENLEVEMENT" en gros sur le bordereau,
    // "à enlever chez" en header de colonne, "Contact et lieu
    // d'enlèvement" en bas, ou "période/date d'enlèvement" en haut).
    // Tres important pour Noah : sur un enlevement, on ne veut PAS
    // l'adresse "destination" (= destinataire final ulterieur), on
    // veut "à enlever chez" (= le lieu OU il va ramasser).
    final format = BordereauFormatDetector.detect(lines);

    final destIdx = _findDestinataireIndex(lines, format);
    final lieuIdx = _findIndex(lines, _markersLieuLivraison);
    final colisIdx = _findIndex(lines, _markersTotalColis);
    final contactIdx = _findIndex(lines, _markersContact);

    // Strategie 1 : bloc destinataire structure.
    //
    // Sur ENLEVEMENT (ramasse), Noah veut EXPLICITEMENT l'adresse
    // "à enlever chez" (= lieu de ramasse), pas "destination" (= lieu
    // de livraison finale). On essaie donc les marqueurs dans cet
    // ordre de priorite :
    //   1. ENLEVEMENT : "enlever chez" > "estinataire" > "destination"
    //   2. LIVRAISON  : "estinataire" > "destination"
    // Pour chaque marqueur, on tente l'extraction. Si le candidat
    // trouve est solide (2+ mots OU >= 8 chars), on garde directement.
    // Sinon on essaie le marqueur suivant ; on garde a la fin le
    // meilleur candidat trouve (1-mot court mieux que rien).
    final markerPriority = format == BordereauFormat.enlevement
        ? const ['enlever chez', 'estinataire', 'destination']
        : const ['estinataire', 'destination', 'enlever chez'];
    String? nomDest;
    String? rue;
    ({String name, String? rue, int score})? bestFallback;
    for (final marker in markerPriority) {
      final cand = _tryExtractFromMarker(lines, marker);
      if (cand == null) continue;
      final wordCount = cand.name.split(BordereauPatterns.whitespaceRegex).length;
      final isSolid = wordCount >= 2 || cand.name.length >= 8;
      if (isSolid) {
        nomDest = cand.name;
        rue = cand.rue;
        break;
      }
      // Fragment (T10, PARE, AUTO) : on garde comme fallback si rien
      // de mieux n'arrive. Score = nb_mots * 100 + length pour
      // departager 2 fragments entre eux.
      final score = wordCount * 100 + cand.name.length;
      if (bestFallback == null || score > bestFallback.score) {
        bestFallback = (name: cand.name, rue: cand.rue, score: score);
      }
    }
    if (nomDest == null && bestFallback != null) {
      nomDest = bestFallback.name;
      rue = bestFallback.rue;
    }

    // Extraire l'ensemble des villes mentionnees dans le doc (sert a
    // exclure ces noms de villes du candidate set du _findNomByOccurrences
    // ci-dessous). Cas reel observe sur les bordereaux ENLEVEMENT
    // 2026-05-22 : "COURVILLE SUR EURE" est imprime EN GROS dans le
    // bloc destination + apparait 2x au total. La strategie 2 prenait
    // "COURVILLE SUR" comme nom destinataire au lieu de "GARAGE LANCTIN
    // DAMIEN".
    final cityWords = <String>{};
    for (final line in lines) {
      final m = _cpVilleRegex.firstMatch(line);
      if (m == null) continue;
      final ville = (m.group(2) ?? '').toUpperCase().trim();
      if (ville.length >= 4) cityWords.add(ville);
      // Ajouter aussi chaque mot ville >= 4 chars pour matcher les
      // sous-strings (ex "COURVILLE" dans "COURVILLE SUR EURE").
      for (final w in ville.split(BordereauPatterns.whitespaceRegex)) {
        if (w.length >= 4) cityWords.add(w);
      }
    }

    // Strategie 2 (fallback) : nom par OCCURRENCES.
    // Le destinataire est mentionne 2 fois sur le bordereau (dans
    // "Contact destinataire" + dans le bloc Destinataire), alors que
    // l'expediteur est mentionne 1 fois.
    if (nomDest == null) {
      nomDest = _findNomByOccurrences(lines, cityWords);
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
    //
    // Sprint 2026-05-23 : on collecte TOUS les CP/ville candidats du
    // bloc (au lieu de prendre le 1er) et on prefere ceux du
    // departement prefere Noah (28). Cas reel observe : bloc destination
    // contient 72560 CHANGE en 1er ET 28400 NOGENT plus loin -- on
    // veut le 28400.
    String? cp;
    String? ville;
    if (lieuIdx >= 0) {
      final blockCandidates = <({String cp, String? ville})>[];
      for (var i = lieuIdx + 1; i < lines.length && i < lieuIdx + 4; i++) {
        final line = lines[i];
        final m = _cpVilleRegex.firstMatch(line);
        if (m != null) {
          blockCandidates.add((cp: m.group(1)!, ville: _cleanVille(m.group(2))));
        } else {
          final cpOnly = _cpRegex.firstMatch(line);
          if (cpOnly != null) {
            blockCandidates.add((cp: cpOnly.group(1)!, ville: null));
          }
        }
      }
      // Trie : CP du dpt prefere en 1er, puis dpts elargis, puis autres.
      // Ordre stable pour les egalites (preserve l'ordre OCR initial).
      if (blockCandidates.isNotEmpty) {
        int rank(String c) {
          if (c.startsWith(kCodePostalPrefere)) return 0;
          for (var i = 0; i < kCodePostalPreferes.length; i++) {
            if (c.startsWith(kCodePostalPreferes[i])) return i + 1;
          }
          return 99;
        }
        blockCandidates.sort((a, b) => rank(a.cp).compareTo(rank(b.cp)));
        cp = blockCandidates.first.cp;
        ville = blockCandidates.first.ville;
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
            final m = BordereauPatterns.cpVilleSimpleRegex.firstMatch(line);
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
      // Format LIVRAISON : "Total colis : 3" tout sur la meme ligne.
      final inSame = BordereauPatterns.colisSameLineRegex.firstMatch(lineColis);
      if (inSame != null) {
        nbColis = int.tryParse(inSame.group(1) ?? '');
      } else {
        // Format ENLEVEMENT (U.M.) : la valeur est sur une ligne plus
        // bas dans le tableau. L'OCR peut intercaler "Client", "Date",
        // "1.0" ou la valeur reelle. On scanne les 12 lignes suivantes
        // pour trouver le 1er nombre 1-99 (entier ou decimal X.0) qui
        // n'est PAS un CP (5 chiffres).
        for (var i = colisIdx + 1;
            i < lines.length && i <= colisIdx + 12;
            i++) {
          final line = lines[i].trim();
          // Skip lignes contenant un CP (eviter 28190 etc).
          if (_cpRegex.hasMatch(line)) continue;
          // Match "1", "1.0", "1,0" en debut ou isole sur la ligne.
          final m = BordereauPatterns.unitColisLineRegex.firstMatch(line);
          if (m != null) {
            nbColis = int.tryParse(m.group(1) ?? '');
            if (nbColis != null && nbColis > 0 && nbColis < 100) break;
            nbColis = null;
          }
        }
      }
    }

    // Telephone : depuis "Contact destinataire" si dispo
    String? telephone;
    if (contactIdx >= 0) {
      final candidates = lines.skip(contactIdx).take(2).join(' ');
      final m = _telRegex.firstMatch(candidates);
      telephone = m?.group(1)?.replaceAll(BordereauPatterns.telSepRegex, '');
    }

    // Score de confiance :
    // - high : on a un nom + au moins (rue ou cp+ville)
    // - low : on a quelque chose mais c'est partiel ou ambigu
    // - none : aucun champ utile
    ExtractionConfidence confidence;
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

    // Heuristique Sprint 2.B : si le nom est un fragment 1-mot court
    // (PEINTURE, TUBE, AUTO, BRANLY...), c'est presque toujours un
    // mot decoupe par ML Kit, pas le vrai nom client. On retrograde
    // a "low" pour que l'UI affiche la carte orange "incertain" plutot
    // qu'une carte verte trompeuse. Whitelist pour les vrais noms
    // courts d'entreprise (cas baseline_test NOVA).
    if (confidence == ExtractionConfidence.high && nomDest != null) {
      if (_isLikelyOcrFragment(nomDest)) {
        confidence = ExtractionConfidence.low;
      }
    }

    return BordereauExtraction(
      nomDestinataire: nomDest,
      rue: rue,
      codePostal: cp,
      ville: ville,
      telephone: telephone,
      nbColis: nbColis,
      confidence: confidence,
      format: format,
    );
  }

  /// Vrai si [name] ressemble a un fragment OCR plutot qu'a un vrai
  /// nom d'entreprise : 1 seul mot court (< 10 chars) qui n'est PAS
  /// dans la whitelist des noms courts connus (NOVA, IBM, BIC, etc).
  ///
  /// Heuristique Sprint 2.B : sur les bordereaux mal cadres, ML Kit
  /// extrait souvent juste un fragment du nom (ex: "PEINTURE" au lieu
  /// de "BROSSE PEINTURE", "AUTO" au lieu de "GS AUTO"). Plutot que
  /// d'afficher une carte verte trompeuse, on retrograde a "low" pour
  /// inviter l'utilisateur a verifier.
  static bool _isLikelyOcrFragment(String name) {
    final trimmed = name.trim();
    if (trimmed.contains(' ')) return false; // multi-mots = OK
    if (trimmed.length >= 10) return false; // mot long = sans doute OK
    const knownShortNames = {
      'NOVA', 'IBM', 'BMW', 'BIC', 'FA45', 'EDF', 'GDF',
      'SNCF', 'RATP', 'LIDL', 'IKEA', 'ZARA', 'FNAC',
    };
    if (knownShortNames.contains(trimmed.toUpperCase())) return false;
    return true;
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

  /// Cherche le 1er bloc adjacent a [marker] dans [lines] et tente d'y
  /// trouver un candidat nom destinataire valide (skip labels, rues,
  /// CP/ville). Retourne null si le marqueur n'est pas trouve ou si
  /// aucun candidat valide n'est dans le bloc.
  ///
  /// [marker] : sous-chaine lowercase a chercher. Cas speciaux pour
  /// "estinataire" (exclut "contact" / "ref") et "destination" (match
  /// strict pour eviter "document d'expedition").
  static ({String name, String? rue})? _tryExtractFromMarker(
    List<String> lines,
    String marker,
  ) {
    int idx = -1;
    for (var i = 0; i < lines.length; i++) {
      final lower = lines[i].toLowerCase().trim();
      if (marker == 'estinataire') {
        if (!lower.contains('estinataire')) continue;
        if (lower.contains('contact')) continue;
        if (lower.contains('ref')) continue;
        idx = i;
        break;
      }
      if (marker == 'destination') {
        if (lower == 'destination' || lower.startsWith('destination ')) {
          idx = i;
          break;
        }
        continue;
      }
      if (lower.contains(marker)) {
        idx = i;
        break;
      }
    }
    if (idx < 0) return null;
    final endIdx = _findNextStopIndex(lines, idx + 1);
    final block = lines.sublist(idx + 1, endIdx);
    final maxScan = block.length < 6 ? block.length : 6;
    String? cand;
    int nomIdxInBlock = -1;
    for (var i = 0; i < maxScan; i++) {
      final c = block[i].trim();
      if (BordereauTextFilters.looksUnreliable(c)) continue;
      if (BordereauTextFilters.isObviousLabel(c)) continue;
      if (BordereauTextFilters.lineIsStreet(c)) continue;
      if (BordereauTextFilters.looksLikeStreet(c)) continue;
      // Sprint 2026-05-23 : exclure les headers de tableau (Vol U.M.
      // Poids Client Date) qui sont parfois mal segmentes par ML Kit
      // et passent les autres filtres.
      if (BordereauTextFilters.isTableHeaderLine(c)) continue;
      if (_cpRegex.hasMatch(c)) continue;
      cand = c;
      nomIdxInBlock = i;
      break;
    }
    if (cand == null) return null;
    return (
      name: cand,
      rue: block.length > nomIdxInBlock + 1
          ? block.skip(nomIdxInBlock + 1).join(' · ')
          : null,
    );
  }

  // _detectFormat migre vers [BordereauFormatDetector.detect]
  // (audit refactor 2026-05-22).

  /// "Destinataire" tout seul, en excluant "Contact destinataire" qui
  /// est un autre marqueur dans le format MESEXP. Tolerance OCR :
  /// accepte aussi "desinataire" (sans le 't') que ML Kit produit
  /// parfois.
  ///
  /// Parcours **lineaire** : on prend le 1er marqueur trouve dans
  /// l'ordre des lignes OCR, peu importe le type (destinataire /
  /// destination / enlever chez). Raison : sur les MESEXP retour,
  /// ML Kit peut placer "destination" AVANT "à enlever chez" et le
  /// 1er bloc adjacent est typiquement le bon. Si on priorise un
  /// marqueur particulier (cf historique git), on tombe sur les
  /// fragments header tableau (T10, PARE, AGGLO) du mauvais bloc.
  ///
  /// Le [format] passe par cohérence d'API mais n'influe pas sur
  /// le choix du marqueur ici (il sert juste a etiqueter l'UI).
  static int _findDestinataireIndex(
    List<String> lines,
    BordereauFormat format,
  ) {
    for (var i = 0; i < lines.length; i++) {
      final lower = lines[i].toLowerCase().trim();
      // Format LIVRAISON : "destinataire" ou "desinataire" (sans 't')
      if (lower.contains('estinataire')) {
        if (lower.contains('contact')) continue;
        if (lower.contains('ref')) continue;
        return i;
      }
      // Format ENLEVEMENT : "destination" (lowercase, header colonne).
      if (lower == 'destination' || lower.startsWith('destination ')) {
        return i;
      }
      // Format ENLEVEMENT : "a enlever chez" ou "à enlever chez"
      if (lower.contains('enlever chez')) return i;
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
  static String? _findNomByOccurrences(
    List<String> lines, [
    Set<String> cityWords = const <String>{},
  ]) {
    final pattern = BordereauPatterns.upperCaseSequenceRegex;
    final candidates = <String>{};
    for (final line in lines) {
      for (final m in pattern.allMatches(line)) {
        final s = m.group(1)!.trim();
        if (s.length < 10) continue;
        if (BordereauTextFilters.isObviousLabel(s)) continue;
        if (BordereauTextFilters.looksLikeStreet(s)) continue;
        if (BordereauTextFilters.looksLikeTransporter(s)) continue;
        if (BordereauTextFilters.looksLikeCity(s, cityWords)) continue;
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
        if (BordereauTextFilters.lineIsStreet(line)) continue;
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

  // _lineIsStreet migre vers [BordereauTextFilters.lineIsStreet]
  // (audit refactor 2026-05-22).

  // _looksLikeStreet migre vers [BordereauTextFilters.looksLikeStreet]
  // (audit refactor 2026-05-22).

  // _looksLikeCity migre vers [BordereauTextFilters.looksLikeCity]
  // (audit refactor 2026-05-22).

  // _looksLikeTransporter migre vers [BordereauTextFilters.looksLikeTransporter]
  // (audit refactor 2026-05-22).

  // _looksUnreliable migre vers [BordereauTextFilters.looksUnreliable]
  // (audit refactor 2026-05-22).

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
        .split(BordereauPatterns.whitespaceRegex)
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
      // Bonus heuristique departement prefere (Sprint 2026-05-23) :
      // si Noah travaille en 28, on prefere les CP commencant par 28
      // (-500). Cas typique MESEXP retour : 2 adresses dans le bloc,
      // 28190 COURVILLE (ramasse) et 72210 VOIVRES (destination
      // finale). On veut le 28.
      if (c.cp.startsWith(kCodePostalPrefere)) {
        score -= 500;
      } else {
        // Bonus moindre pour les autres dpts de la zone elargie.
        for (final dept in kCodePostalPreferes) {
          if (dept != kCodePostalPrefere && c.cp.startsWith(dept)) {
            score -= 100;
            break;
          }
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
    final ruePattern = BordereauPatterns.ruePattern;
    final bpPattern = BordereauPatterns.bpPattern;

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

  // _isObviousLabel migre vers [BordereauTextFilters.isObviousLabel]
  // (audit refactor 2026-05-22).

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
