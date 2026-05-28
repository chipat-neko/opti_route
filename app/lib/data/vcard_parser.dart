/// Un contact extrait d'un fichier vCard (.vcf), par exemple un export
/// Google Contacts (carte #102). Champs optionnels : tous peuvent etre
/// absents selon ce que le contact contient.
class VcardContact {
  const VcardContact({
    this.nom,
    this.rue,
    this.codePostal,
    this.ville,
    this.lat,
    this.lng,
    this.telephone,
  });

  final String? nom;
  final String? rue;
  final String? codePostal;
  final String? ville;
  final double? lat;
  final double? lng;
  final String? telephone;

  /// Adresse lisible composee depuis rue + CP + ville. Vide si aucun
  /// champ adresse n'est renseigne.
  String get adresseComposee {
    final parts = <String>[
      if ((rue ?? '').trim().isNotEmpty) rue!.trim(),
      [
        if ((codePostal ?? '').trim().isNotEmpty) codePostal!.trim(),
        if ((ville ?? '').trim().isNotEmpty) ville!.trim(),
      ].join(' ').trim(),
    ].where((s) => s.isNotEmpty).toList();
    return parts.join(', ');
  }

  bool get hasAdresse => adresseComposee.isNotEmpty;
  bool get hasCoords => lat != null && lng != null;
}

/// Parseur vCard 3.0 / 4.0 minimaliste mais robuste (carte #102).
/// Fonction PURE : prend le contenu texte d'un .vcf, retourne la liste
/// des contacts. Gere le repliement de lignes (RFC : ligne suivante
/// commencant par espace/tab = continuation), l'echappement (\, \; \\ \n)
/// et les parametres de propriete (TYPE=..., etc.).
class VcardParser {
  VcardParser._();

  static List<VcardContact> parse(String content) {
    final out = <VcardContact>[];
    final lines = _unfold(content);
    List<String>? current; // lignes de la carte en cours
    for (final line in lines) {
      final upper = line.toUpperCase();
      if (upper == 'BEGIN:VCARD') {
        current = <String>[];
      } else if (upper == 'END:VCARD') {
        if (current != null) {
          final c = _parseCard(current);
          if (c != null) out.add(c);
        }
        current = null;
      } else {
        current?.add(line);
      }
    }
    return out;
  }

  /// Replie les lignes : une ligne qui commence par un espace ou une
  /// tabulation est la continuation de la precedente (RFC 2425 5.8.1).
  static List<String> _unfold(String content) {
    final raw = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');
    final folded = <String>[];
    for (final l in raw) {
      if (l.isNotEmpty && (l.startsWith(' ') || l.startsWith('\t')) &&
          folded.isNotEmpty) {
        folded[folded.length - 1] = folded.last + l.substring(1);
      } else {
        folded.add(l);
      }
    }
    return folded;
  }

  static VcardContact? _parseCard(List<String> lines) {
    String? fn;
    String? nComposed;
    String? org;
    String? rue;
    String? cp;
    String? ville;
    double? lat;
    double? lng;
    String? tel;

    for (final line in lines) {
      final colon = line.indexOf(':');
      if (colon < 0) continue;
      final namePart = line.substring(0, colon);
      final value = line.substring(colon + 1);
      // Nom de propriete = avant le premier ';' (le reste = parametres).
      final prop = namePart.split(';').first.toUpperCase();

      switch (prop) {
        case 'FN':
          fn = _unescape(value).trim();
        case 'N':
          // Family;Given;Middle;Prefix;Suffix
          final comps = _splitValue(value);
          final family = comps.isNotEmpty ? _unescape(comps[0]).trim() : '';
          final given = comps.length > 1 ? _unescape(comps[1]).trim() : '';
          nComposed = [given, family].where((s) => s.isNotEmpty).join(' ');
        case 'ORG':
          org = _unescape(_splitValue(value).first).trim();
        case 'ADR':
          // PoBox;Ext;Street;Locality;Region;PostalCode;Country
          final comps = _splitValue(value);
          String at(int i) =>
              comps.length > i ? _unescape(comps[i]).trim() : '';
          rue = at(2).isNotEmpty ? at(2) : null;
          ville = at(3).isNotEmpty ? at(3) : null;
          cp = at(5).isNotEmpty ? at(5) : null;
        case 'GEO':
          final g = _parseGeo(value);
          if (g != null) {
            lat = g.$1;
            lng = g.$2;
          }
        case 'TEL':
          tel ??= _unescape(value).trim();
      }
    }

    final nom = (fn != null && fn.isNotEmpty)
        ? fn
        : (nComposed != null && nComposed.isNotEmpty)
            ? nComposed
            : (org != null && org.isNotEmpty)
                ? org
                : null;

    // Carte vide (ni nom, ni adresse, ni tel) -> ignore.
    final hasAnything = nom != null ||
        rue != null ||
        ville != null ||
        cp != null ||
        (tel != null && tel.isNotEmpty);
    if (!hasAnything) return null;

    return VcardContact(
      nom: nom,
      rue: rue,
      codePostal: cp,
      ville: ville,
      lat: lat,
      lng: lng,
      telephone: (tel != null && tel.isNotEmpty) ? tel : null,
    );
  }

  /// Decoupe une valeur structuree sur les `;` non echappes.
  static List<String> _splitValue(String value) {
    final out = <String>[];
    final buf = StringBuffer();
    var escaped = false;
    for (var i = 0; i < value.length; i++) {
      final ch = value[i];
      if (escaped) {
        buf.write('\\');
        buf.write(ch);
        escaped = false;
      } else if (ch == '\\') {
        escaped = true;
      } else if (ch == ';') {
        out.add(buf.toString());
        buf.clear();
      } else {
        buf.write(ch);
      }
    }
    if (escaped) buf.write('\\');
    out.add(buf.toString());
    return out;
  }

  /// GEO : "lat;lng" (vCard 3.0) ou "geo:lat,lng" (vCard 4.0).
  static (double, double)? _parseGeo(String value) {
    var v = value.trim();
    if (v.toLowerCase().startsWith('geo:')) v = v.substring(4);
    final parts = v.contains(';') ? v.split(';') : v.split(',');
    if (parts.length < 2) return null;
    final lat = double.tryParse(parts[0].trim());
    final lng = double.tryParse(parts[1].trim());
    if (lat == null || lng == null) return null;
    return (lat, lng);
  }

  /// Inverse de l'echappement vCard : \\ \, \; \n.
  static String _unescape(String v) {
    final buf = StringBuffer();
    var escaped = false;
    for (var i = 0; i < v.length; i++) {
      final ch = v[i];
      if (escaped) {
        switch (ch) {
          case 'n':
          case 'N':
            buf.write('\n');
          default:
            buf.write(ch);
        }
        escaped = false;
      } else if (ch == '\\') {
        escaped = true;
      } else {
        buf.write(ch);
      }
    }
    return buf.toString();
  }
}
