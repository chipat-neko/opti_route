import 'bordereau_patterns.dart';

/// Filtres textuels partages par les parsers de bordereaux pour
/// rejeter les candidats qui ne sont PAS un vrai nom de destinataire :
/// labels techniques, rues, villes, transporteurs, fragments OCR.
///
/// Extraits de [BordereauParser] le 2026-05-22 (audit refactor P0 #2)
/// pour decoupler la logique de filtrage du parsing principal. Toutes
/// les methodes sont `static` et pures (pas d'etat).
///
/// Ordre d'appel typique dans le parser :
/// ```dart
/// if (BordereauTextFilters.looksUnreliable(c)) continue;
/// if (BordereauTextFilters.isObviousLabel(c)) continue;
/// if (BordereauTextFilters.lineIsStreet(c)) continue;
/// if (BordereauTextFilters.looksLikeStreet(c)) continue;
/// ```
abstract final class BordereauTextFilters {
  /// Vrai si [s] est un libelle technique du bordereau (header,
  /// section, label) plutot qu'un nom d'entreprise destinataire.
  static bool isObviousLabel(String s) {
    final lower = s.toLowerCase();
    const labels = [
      'lettre de voiture',
      'matieres dangereuses',
      'matières dangereuses',
      'transporteur',
      'commissionnaire',
      'instruction',
      'instruc tion',
      'ins truction',
      'document de suivi',
      'lieu de livraison',
      'contact destinataire',
      'expediteur',
      'expéditeur',
      'expedi teur',
      'destinataire',
      'desinataire',
      'mesexp',
      'messagerie express',
      'nature de la marchandise',
      // Ajouts Sprint 2026-05-23
      'recep.',
      'recep:',
      'agence remettante',
      'france alliance',
      'allonnes',
      // Ajouts feedback Noah 2026-05-23 (screenshot scan reel) :
      // les zones d'activite, ZA, ZI, ZAC sont des noms de lieux
      // industriels, JAMAIS des noms de clients. On les rejette tot.
      'za de',
      'za de la',
      'z.a.',
      'z.a ',
      ' za ',
      'zone artisanale',
      'zone industrielle',
      'zone d\'activite',
      'zone d\'activité',
      'zac de',
      'z.i.',
      'rance alliance',
      'ranceallian',
      'rancealliance',
      'chenardiere',
      'lachenardiere',
      'sapiniere',
      'sapinière',
      'blaise pascal', // rue de zone industrielle Sarthe
      // Labels expediteurs Sarthe (Alliance PR) frequents sur les
      // MESEXP retour observes 2026-05-23. Specifique au workflow Noah.
      'champ du chataignier',
      'chataignier',
      'châtaignier',
      'voivres',
      'voivres les le mans',
      'le mans',
      'alliance pr',
      'allianc pr',
    ];
    for (final l in labels) {
      if (lower.contains(l)) return true;
    }
    return false;
  }

  /// Vrai si la ligne entiere est une rue numerotee (commence par un
  /// chiffre suivi d'un mot de voirie). Sert a ignorer les occurrences
  /// d'un candidat dans une rue (ex: "LOUIS PASTEUR" dans "24 AVENUE
  /// LOUIS PASTEUR").
  static bool lineIsStreet(String line) {
    return BordereauPatterns.streetLineRegex.hasMatch(line.trim());
  }

  /// Vrai si le candidat ressemble a une rue (commence ou contient un
  /// mot de rue francais). Evite de prendre "AVENUE LOUIS PASTEUR"
  /// comme nom d'entreprise.
  static bool looksLikeStreet(String s) {
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
    final padded = ' $lower ';
    for (final w in streetWords) {
      if (padded.contains(w)) return true;
    }
    return false;
  }

  /// Vrai si le candidat est en realite un nom de VILLE (ou un fragment
  /// d'une ville detectee). Sert a eviter que [_findNomByOccurrences]
  /// extraie "COURVILLE SUR" comme nom du destinataire alors que c'est
  /// la ville imprimee EN GROS dans le bloc destination ENLEVEMENT.
  ///
  /// 3 regles cumulatives :
  ///   1. Exact match : candidate == une ville detectee
  ///   2. Prefixe strict avec espace : "COURVILLE SUR" prefixe
  ///      "COURVILLE SUR EURE" (avec espace de delimitation pour
  ///      eviter "COUR" qui match "COURVILLE")
  ///   3. Tous les mots significatifs (>= 4 chars) de la candidate
  ///      sont dans cityWords. Cas "NOGENT LE ROTROU" : NOGENT et
  ///      ROTROU dans cityWords -> exclu. Mais "THEODORE CHARTRES"
  ///      garde car THEODORE n'est pas dans cityWords.
  static bool looksLikeCity(String candidate, Set<String> cityWords) {
    if (cityWords.isEmpty) return false;
    final upper = candidate.toUpperCase().trim();
    if (cityWords.contains(upper)) return true;
    for (final city in cityWords) {
      if (city.length > upper.length && city.startsWith('$upper ')) {
        return true;
      }
    }
    final words = upper
        .split(BordereauPatterns.whitespaceRegex)
        .where((w) => w.length >= 4)
        .toList();
    if (words.isEmpty) return false;
    for (final w in words) {
      if (!cityWords.contains(w)) return false;
    }
    return true;
  }

  /// Vrai si la ligne est un HEADER DE TABLEAU (contient 2+ mots-cles
  /// types "Vol", "Poids", "U.M.", "Code", "Regime", "Client", "Date").
  /// Cas typique : ligne "Vol/lg Poids U.M. Client Date" sur les
  /// bordereaux MESEXP retour. Sert a exclure les candidats noms qui
  /// sont en fait des headers de colonnes mal segmentees par ML Kit.
  static bool isTableHeaderLine(String line) {
    final lower = line.toLowerCase();
    const headers = [
      'vol/',
      'vol /',
      'vol ',
      'poids',
      'u.m',
      'um.',
      'um ',
      'regime',
      'régime',
      'client',
      'periode',
      'période',
      'date',
      'code',
      'ligne',
      'nature',
    ];
    var matches = 0;
    for (final h in headers) {
      if (lower.contains(h)) matches++;
      if (matches >= 2) return true;
    }
    return false;
  }

  /// Vrai si le candidat ressemble a un nom de transporteur courant.
  /// Evite de prendre "EURE ET LOIR ACHEMINEMENT" ou "FA45 TRANSPORTS"
  /// comme destinataire.
  static bool looksLikeTransporter(String s) {
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

  /// Vrai si le nom semble peu fiable (trop court, numero de reference,
  /// label technique, code tracking).
  ///
  /// Seuil de longueur fixe a 3 caracteres pour accepter les noms
  /// courts mais legitimes : "NOVA" (4), "IBM", "BMW", "FA45". Le
  /// filtre principal est la liste de mots techniques (~30 entrees).
  static bool looksUnreliable(String? name) {
    if (name == null || name.isEmpty) return true;
    if (name.length < 3) return true;
    // Numero de reference (FA280000..., 72070741, etc) : pas d'espace
    // et au moins 4 chiffres -> ce n'est pas un nom d'entreprise.
    // Cas reels observes 2026-05-22 : sur les bordereaux ENLEVEMENT
    // mal cadres, OCR remonte la moitie basse + numero ref en debut
    // du bloc destination. Le filtre garde "NOVA" (0 chiffres) mais
    // rejette "FA280000440358" (12 chiffres).
    if (!name.contains(' ')) {
      final digits = name
          .replaceAll(BordereauPatterns.digitsOnlyRegex, '')
          .length;
      if (digits >= 4) return true;
    }
    // Code tracking avec slash (ex: "270521 /6552AGNCMVZ04L").
    if (name.contains('/') &&
        BordereauPatterns.trackingCodeRegex.hasMatch(name)) {
      return true;
    }
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
      // Labels ENLEVEMENT (Eure et Loir Acheminement) frequents en
      // 1ere ligne du bloc "destination" a cause de l'ordre OCR
      // chaotique.
      'donneur',
      "donneur d'ordre",
      'ordre',
      'messagerie',
      'express',
      'ref.',
      'ref ',
      'enlevement',
      'enlèvement',
      'exemplaire',
      'travee',
      'travée',
      'alpr',
      'retour',
      'régime',
      'regime',
      'nature',
      'ligne',
      'dangereuses',
      'mesexp',
      'destination',
      'contact',
      'a enlever',
      'à enlever',
      // Labels transporteur Eure et Loir Acheminement (bordereau
      // MESEXP retour) : "enleveur", "transpoteur" (typo OCR),
      // "agence remettante"
      'enleveur',
      'transpoteur',
      'transporteur',
      'remettante',
      'expediteur',
      'expéditeur',
      // Labels secondaires observes 2026-05-22 (page_33-34).
      'poids',
      ' kg',
      'pads',
      ' km',
      'date',
      'periode',
      'période',
      // Labels tableau MESEXP retour ajoutes 2026-05-23 (feedback Noah)
      'alpr retour',
      'alprret',
      'ref d.o',
      'ref d.o.',
      'ref. exp',
      'ref exp',
      'd.o.',
      'u.m',
      'um.',
      'vol/lg',
      'vol / lg',
      'vol /lg',
      'vol/ lg',
      'instruction',
      'conditions',
      'recevables',
      'reception',
      'rception',
      'recep.',
      'recep:',
      'recep ',
      'travee',
      'document',
      'lieu',
      'agence',
      'remettante',
      'eure et loir',
      'eure-et-loir',
      'alliance pr',
      'pare brise',
      // Codes regime / type marchandise
      ' t10',
      ' to1',
      ' to7',
      ' t07',
      // Defaults inscrits sur les bordereaux conditions generales
      'avril 1999',
      'decret du 6',
      'décret du 6',
      'commerce',
      'recommandee',
      'recommandée',
    ];
    for (final w in technicalWords) {
      if (lower.contains(w)) return true;
    }
    return false;
  }
}
