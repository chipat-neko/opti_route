import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'database.dart';
import 'saved_destinations_repository.dart';

/// Export du carnet d'adresses au format **vCard 3.0** (.vcf). Permet
/// d'importer chaque entree dans l'app Contacts native d'Android, ce qui
/// est utile en cas de changement de telephone ou pour synchroniser avec
/// Google Contacts.
///
/// Une entree par vCard, concatenees dans un seul fichier. Champs
/// remplis :
/// - FN / N : nom du client (ou "ADRESSE" si pas de nom)
/// - ORG : nom du client en doublon (entreprise) si renseigne
/// - ADR;TYPE=WORK : rue / ville / cp
/// - GEO : lat,lng (utile dans Google Contacts pour le pin maps)
/// - NOTE : compteur de livraisons + date du dernier passage
///
/// Format vCard 3.0 : reference https://datatracker.ietf.org/doc/html/rfc2426
class CarnetVcardExportService {
  CarnetVcardExportService(this._repo);

  final SavedDestinationsRepository _repo;

  /// Genere le .vcf et le partage via le selecteur natif (Contacts,
  /// Drive, mail). Retourne le nombre d'entrees exportees.
  Future<int> exportAndShare() async {
    final all = await _repo.watchAll().first;
    final content = toVcard(all);

    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now()
        .toIso8601String()
        .split('.')
        .first
        .replaceAll(':', '-');
    final file = File('${dir.path}/carnet-opti-route-$stamp.vcf');
    await file.writeAsString(content);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'Carnet d\'adresses opti_route (vCard)',
        text:
            'Sauvegarde vCard de ${all.length} entree(s). Ouvre avec '
            'l\'app Contacts pour les importer.',
      ),
    );
    return all.length;
  }

  /// Genere le contenu vCard de toutes les entrees. Public pour
  /// pouvoir tester directement la serialisation sans toucher au fs.
  @visibleForTesting
  static String toVcard(List<SavedDestination> entries) {
    final buf = StringBuffer();
    final df = DateFormat('dd/MM/yyyy', 'fr');
    for (final d in entries) {
      final nom = (d.nomClient?.trim().isNotEmpty ?? false)
          ? d.nomClient!.trim()
          : 'Adresse opti_route';
      buf.writeln('BEGIN:VCARD');
      buf.writeln('VERSION:3.0');
      // N: famille;prenom;... -> on met tout en famille pour rester
      // compatible avec les imports qui exigent la presence du champ.
      buf.writeln('N:${_escape(nom)};;;;');
      buf.writeln('FN:${_escape(nom)}');
      if (d.nomClient != null && d.nomClient!.trim().isNotEmpty) {
        buf.writeln('ORG:${_escape(d.nomClient!.trim())}');
      }
      // ADR;TYPE=WORK:PoBox;Extended;Street;Locality;Region;PostalCode;Country
      buf.writeln(
        'ADR;TYPE=WORK:;;${_escape(d.rue ?? "")};${_escape(d.ville ?? "")};;'
        '${_escape(d.codePostal ?? "")};France',
      );
      buf.writeln(
        'GEO:${d.lat.toStringAsFixed(6)};${d.lng.toStringAsFixed(6)}',
      );
      // NOTE : compteur + date dernier passage. Une seule ligne (les
      // sauts de ligne dans NOTE compliquent l'import sur certains
      // smartphones).
      buf.writeln(
        'NOTE:opti_route - livre ${d.useCount} fois (dernier : '
        '${df.format(d.lastUsedAt)})',
      );
      if (d.isFavori) {
        buf.writeln('CATEGORIES:opti_route,Favori');
      } else {
        buf.writeln('CATEGORIES:opti_route');
      }
      buf.writeln('END:VCARD');
    }
    return buf.toString();
  }

  /// Echappe les caracteres speciaux selon RFC 2426 :
  /// virgules, points-virgules, backslashes, retours-ligne. Les
  /// accents passent tels quels (l'encodage du fichier est UTF-8 ; les
  /// apps Contacts modernes le supportent).
  static String _escape(String v) {
    return v
        .replaceAll(r'\', r'\\')
        .replaceAll(',', r'\,')
        .replaceAll(';', r'\;')
        .replaceAll('\n', r'\n');
  }
}
