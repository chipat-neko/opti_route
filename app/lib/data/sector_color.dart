import 'package:flutter/material.dart' show Color;

/// Assigne une couleur stable a un code postal (carte #293) pour
/// colorier les markers d'une carte ou les pilules des stops dans la
/// liste : tous les "28000" ont la meme teinte, distincte de "28100".
///
/// Palette 8 couleurs (alpha=0xFF) optimisee pour lisibilite sur fond
/// blanc/creme. Le mapping CP -> index est deterministe (hash modulo
/// palette.length) pour rester stable entre les rendus.
class SectorColor {
  SectorColor._();

  static const List<Color> palette = [
    Color(0xFF1E88E5), // bleu vif
    Color(0xFFE53935), // rouge vif
    Color(0xFF8E24AA), // violet
    Color(0xFFFB8C00), // orange
    Color(0xFF43A047), // vert
    Color(0xFF00ACC1), // cyan
    Color(0xFFFDD835), // jaune
    Color(0xFF6D4C41), // brun
  ];

  static Color forCp(String cp) {
    if (cp.isEmpty || cp == '?') return const Color(0xFF9E9E9E);
    final h = _stableHash(cp) % palette.length;
    return palette[h];
  }

  /// Hash deterministe (FNV-1a 32 bits simplifie) -- pas crypto, juste
  /// stable d'un run a l'autre. Le hashCode Dart varie d'un run a
  /// l'autre, donc on roule notre propre hash.
  static int _stableHash(String s) {
    var h = 0x811c9dc5;
    for (final c in s.codeUnits) {
      h = (h ^ c) * 0x01000193;
      h &= 0xFFFFFFFF;
    }
    return h;
  }
}
