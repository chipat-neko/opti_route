import 'dart:io';

/// Pour chaque fichier passe en argument, enleve "const " devant chaque
/// constructeur Widget commencant par une majuscule, dont le scope de
/// parentheses contient une reference `p.X` ou X est une couleur
/// contextuelle.
///
/// Lance : `dart run tool/strip_const.dart fichier.dart [fichier2.dart ...]`
void main(List<String> args) {
  const paletteWords = [
    'cream',
    'creamSoft',
    'paper',
    'ink',
    'inkSoft',
    'inkLine',
    'divider',
    'text',
    'textMute',
    'textFaint',
  ];
  final pPattern = RegExp(r'\bp\.(' + paletteWords.join('|') + r')\b');
  final constRegex = RegExp(r'\bconst\s+([A-Z]\w*)\s*\(');

  for (final path in args) {
    final file = File(path);
    var text = file.readAsStringSync();
    final matches = constRegex.allMatches(text).toList();
    final ranges = <_Range>[];

    for (final m in matches) {
      final startParen = m.end - 1; // position du "("
      var depth = 1;
      var i = startParen + 1;
      while (i < text.length && depth > 0) {
        final c = text[i];
        if (c == '(') {
          depth++;
        } else if (c == ')') {
          depth--;
        }
        i++;
      }
      if (depth != 0) continue;
      final inner = text.substring(startParen + 1, i - 1);
      if (pPattern.hasMatch(inner)) {
        // Longueur du "const " incluant whitespace
        final constLen = RegExp(r'^const\s+').firstMatch(m.group(0)!)!.end;
        ranges.add(_Range(m.start, constLen));
      }
    }

    // Tri decroissant pour preserver les indices
    ranges.sort((a, b) => b.start - a.start);
    for (final r in ranges) {
      text = text.substring(0, r.start) + text.substring(r.start + r.length);
    }

    file.writeAsStringSync(text);
    stdout.writeln('Stripped ${ranges.length} const blocks: $path');
  }
}

class _Range {
  _Range(this.start, this.length);
  final int start;
  final int length;
}
