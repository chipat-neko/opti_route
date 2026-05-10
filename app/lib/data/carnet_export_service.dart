import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'database.dart';
import 'saved_destinations_repository.dart';

/// Export du carnet d'adresses local au format CSV. Permet a Noah de
/// sauvegarder son carnet (par ex avant de changer de telephone) ou de
/// le partager (mail, Drive, copie sur PC).
class CarnetExportService {
  CarnetExportService(this._repo);

  final SavedDestinationsRepository _repo;

  /// Genere un CSV avec toutes les entrees du carnet et le partage via
  /// le selecteur natif Android (`Share.shareXFiles`). Retourne le
  /// nombre d'entrees exportees.
  Future<int> exportAndShare() async {
    final stream = _repo.watchAll();
    final all = await stream.first;
    final csv = _toCsv(all);

    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().toIso8601String().split('.').first
        .replaceAll(':', '-');
    final file = File('${dir.path}/carnet-opti-route-$timestamp.csv');
    await file.writeAsString(csv);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'Carnet d\'adresses opti_route',
        text:
            'Sauvegarde de ${all.length} entree(s) du carnet d\'adresses '
            'opti_route au ${DateTime.now().toIso8601String().split("T").first}.',
      ),
    );

    return all.length;
  }

  /// Format CSV avec en-tete + une ligne par entree. Les champs sont
  /// echappes selon RFC 4180 (guillemets doubles autour des champs qui
  /// contiennent virgule, guillemet ou retour ligne ; guillemets
  /// internes doubles).
  static String _toCsv(List<SavedDestination> all) {
    final buf = StringBuffer();
    const headers = [
      'id',
      'nom_client',
      'adresse_display',
      'rue',
      'code_postal',
      'ville',
      'lat',
      'lng',
      'use_count',
      'last_used_at',
      'cree_le',
    ];
    buf.writeln(headers.map(_escape).join(','));
    for (final d in all) {
      buf.writeln([
        d.id.toString(),
        d.nomClient ?? '',
        d.adresseDisplay,
        d.rue ?? '',
        d.codePostal ?? '',
        d.ville ?? '',
        d.lat.toStringAsFixed(6),
        d.lng.toStringAsFixed(6),
        d.useCount.toString(),
        d.lastUsedAt.toIso8601String(),
        d.creeLe.toIso8601String(),
      ].map(_escape).join(','));
    }
    return buf.toString();
  }

  static String _escape(String value) {
    final needsQuotes =
        value.contains(',') || value.contains('"') || value.contains('\n');
    if (!needsQuotes) return value;
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }
}
