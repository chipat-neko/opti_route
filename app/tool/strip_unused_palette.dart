import 'dart:io';

/// Pour chaque fichier, supprime les lignes `final p = context.palette;`
/// si la methode/scope englobant ne contient PAS d'utilisation de `p.`.
/// Le scope est determine par la prochaine accolade fermante au meme
/// niveau d'indentation que la declaration `}`.
void main(List<String> args) {
  for (final path in args) {
    final file = File(path);
    final text = file.readAsStringSync();
    final lines = text.split('\n');
    final out = <String>[];
    final declRegex = RegExp(r'^(\s*)final\s+p\s*=\s*context\.palette\s*;\s*$');

    for (var i = 0; i < lines.length; i++) {
      final m = declRegex.firstMatch(lines[i]);
      if (m == null) {
        out.add(lines[i]);
        continue;
      }
      // Chercher la fin du scope englobant : depth-counting des accolades
      var depth = 0;
      var endIdx = lines.length;
      for (var j = i + 1; j < lines.length; j++) {
        for (final c in lines[j].split('')) {
          if (c == '{') depth++;
          if (c == '}') depth--;
        }
        if (depth < 0) {
          endIdx = j;
          break;
        }
      }
      // Tester si dans [i+1, endIdx] on a un usage de p.
      var used = false;
      for (var j = i + 1; j <= endIdx && j < lines.length; j++) {
        if (RegExp(r'\bp\.\w+').hasMatch(lines[j])) {
          used = true;
          break;
        }
      }
      if (used) {
        out.add(lines[i]);
      }
      // Sinon on saute la ligne
    }

    file.writeAsStringSync(out.join('\n'));
    stdout.writeln('Cleaned unused p in: $path');
  }
}
