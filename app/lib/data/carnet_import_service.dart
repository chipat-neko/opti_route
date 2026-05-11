import 'dart:convert';
import 'dart:io';

import 'saved_destinations_repository.dart';

/// Resultat d'un import CSV : combien de lignes lues, combien creees,
/// combien fusionnees avec une entree existante (meme nomClient ou
/// meme coords), combien rejetees (CSV malforme, coords invalides...).
class CarnetImportResult {
  const CarnetImportResult({
    required this.lineCount,
    required this.created,
    required this.merged,
    required this.rejected,
    required this.errors,
  });

  final int lineCount;
  final int created;
  final int merged;
  final int rejected;
  final List<String> errors;
}

/// Restaure le carnet d'adresses local depuis un CSV genere par
/// `CarnetExportService.exportAndShare` (PR #58). Utile apres
/// changement de telephone, ou pour fusionner 2 carnets.
///
/// La fusion utilise `SavedDestinationsRepository.upsertFromValidatedStop`
/// qui detecte automatiquement les doublons (par nomClient case-
/// insensitive, ou par coords arrondies a ~11m).
class CarnetImportService {
  CarnetImportService(this._repo);

  final SavedDestinationsRepository _repo;

  Future<CarnetImportResult> importFromFile(File file) async {
    final content = await file.readAsString();
    return importFromText(content);
  }

  Future<CarnetImportResult> importFromText(String csv) async {
    final lines = const LineSplitter().convert(csv);
    if (lines.isEmpty) {
      return const CarnetImportResult(
        lineCount: 0,
        created: 0,
        merged: 0,
        rejected: 0,
        errors: ['Fichier vide'],
      );
    }

    // Header attendu : id,nom_client,adresse_display,rue,code_postal,
    // ville,lat,lng,use_count,last_used_at,cree_le. On detecte aussi
    // les exports incomplets et on prend ce qu'on peut.
    final header = _parseCsvLine(lines.first);
    final idxNom = header.indexOf('nom_client');
    final idxAddr = header.indexOf('adresse_display');
    final idxRue = header.indexOf('rue');
    final idxCp = header.indexOf('code_postal');
    final idxVille = header.indexOf('ville');
    final idxLat = header.indexOf('lat');
    final idxLng = header.indexOf('lng');

    if (idxAddr < 0 || idxLat < 0 || idxLng < 0) {
      return CarnetImportResult(
        lineCount: lines.length - 1,
        created: 0,
        merged: 0,
        rejected: lines.length - 1,
        errors: [
          'Header CSV invalide : il faut au moins les colonnes '
              'adresse_display, lat, lng. Header lu : ${header.join(", ")}.'
        ],
      );
    }

    final existingBefore = await _repo.count();
    var rejected = 0;
    final errors = <String>[];
    final dataLines = lines.skip(1).toList();

    for (var i = 0; i < dataLines.length; i++) {
      final raw = dataLines[i].trim();
      if (raw.isEmpty) continue;
      try {
        final fields = _parseCsvLine(raw);
        final addr = idxAddr < fields.length ? fields[idxAddr] : '';
        final lat = idxLat < fields.length
            ? double.tryParse(fields[idxLat])
            : null;
        final lng = idxLng < fields.length
            ? double.tryParse(fields[idxLng])
            : null;
        if (addr.isEmpty || lat == null || lng == null) {
          rejected++;
          continue;
        }
        await _repo.upsertFromValidatedStop(
          nomClient:
              idxNom >= 0 && idxNom < fields.length ? fields[idxNom] : null,
          adresseDisplay: addr,
          lat: lat,
          lng: lng,
          rue: idxRue >= 0 && idxRue < fields.length ? fields[idxRue] : null,
          codePostal:
              idxCp >= 0 && idxCp < fields.length ? fields[idxCp] : null,
          ville: idxVille >= 0 && idxVille < fields.length
              ? fields[idxVille]
              : null,
        );
      } catch (e) {
        rejected++;
        if (errors.length < 5) {
          errors.add('Ligne ${i + 2} : $e');
        }
      }
    }

    final existingAfter = await _repo.count();
    final created = existingAfter - existingBefore;
    final processed = dataLines.where((l) => l.trim().isNotEmpty).length;
    final merged = processed - created - rejected;

    return CarnetImportResult(
      lineCount: dataLines.length,
      created: created,
      merged: merged,
      rejected: rejected,
      errors: errors,
    );
  }

  /// Parser CSV minimal qui gere les guillemets RFC 4180 (le format
  /// exporte par CarnetExportService).
  static List<String> _parseCsvLine(String line) {
    final fields = <String>[];
    final buf = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (inQuotes) {
        if (ch == '"') {
          // Guillemet double a l'interieur = un seul guillemet litteral
          if (i + 1 < line.length && line[i + 1] == '"') {
            buf.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          buf.write(ch);
        }
      } else {
        if (ch == ',') {
          fields.add(buf.toString());
          buf.clear();
        } else if (ch == '"' && buf.isEmpty) {
          inQuotes = true;
        } else {
          buf.write(ch);
        }
      }
    }
    fields.add(buf.toString());
    return fields;
  }
}

