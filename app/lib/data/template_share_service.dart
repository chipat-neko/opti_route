import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'database.dart';
import 'stops_repository.dart';
import 'tournees_repository.dart';

/// ════════════════════════════════════════════════════════════════
/// Service d'export / import de templates de tournee au format JSON.
/// ════════════════════════════════════════════════════════════════
///
/// Use case Phase 1 (pas de cloud) : Lucas a un template "Lundi sud"
/// pour sa tournee hebdo, il veut le partager avec Noah. Solution
/// pragmatique sans backend :
///
/// 1. Lucas tape "Partager le template" -> genere un .json dans le
///    dossier temp + share natif (WhatsApp, mail, Drive, etc.)
/// 2. Noah recoit le .json, l'ouvre dans opti_route via
///    "Importer un template" -> file_picker -> [importFromJson]
/// 3. La tournee est creee chez Noah avec son flag `isTemplate = true`,
///    tous les stops reproduits (sans coords pour eviter les conflits
///    de geocodage, c'est l'auto-reorder local qui ressoudera).
///
/// Le format JSON est volontairement simple et stable (versionne)
/// pour faciliter l'evolution future.
class TemplateShareService {
  TemplateShareService({
    required this.db,
    required this.tournees,
    required this.stops,
  });

  final AppDatabase db;

  final TourneesRepository tournees;
  final StopsRepository stops;

  /// Version du format JSON. Incrementer en cas de breaking change
  /// (ex: ajout d'un champ obligatoire). Les imports avec une version
  /// future seront rejetes proprement.
  static const _formatVersion = 1;

  /// Genere un fichier JSON portant la tournee + ses stops, et
  /// declenche le share natif Android (WhatsApp / mail / Drive). Le
  /// fichier est ecrit dans le dossier temp avec un nom horodate.
  ///
  /// Retourne null si le share a ete annule, sinon le path du fichier
  /// (pour usage debug / test).
  Future<String?> shareTemplate(int tourneeId) async {
    final tournee = await tournees.getById(tourneeId);
    if (tournee == null) {
      throw const TemplateShareException('Tournee introuvable');
    }
    final stopsList = await stops.getByTournee(tourneeId);

    final json = _serializeToJson(tournee, stopsList);
    final body = const JsonEncoder.withIndent('  ').convert(json);

    final dir = await getTemporaryDirectory();
    final ts = DateTime.now()
        .toIso8601String()
        .split('.')
        .first
        .replaceAll(':', '-');
    // Nom de fichier "safe" (pas de slash, espaces -> underscore)
    final safeName = tournee.nom
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
    final file = File('${dir.path}/template_${safeName}_$ts.json');
    await file.writeAsString(body);

    final shareResult = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'Template opti_route : ${tournee.nom}',
        text:
            'Voici un template de tournee pour opti_route. Ouvre-le '
            'dans l\'app via Parametres -> Importer un template.',
      ),
    );
    if (shareResult.status == ShareResultStatus.dismissed) return null;
    return file.path;
  }

  /// Importe un template depuis un fichier JSON et cree une nouvelle
  /// tournee (avec `isTemplate = true`) + tous ses stops. Retourne
  /// l'id de la tournee creee.
  ///
  /// Strategie :
  /// - Coords des stops mises a null (sera re-geocode automatiquement
  ///   par l'OfflineGeocodeAutomation au prochain retour reseau).
  /// - Statuts forces a 'a_livrer' (un template ne porte pas de
  ///   livraisons en cours).
  /// - Le nom est prefixe "[Import]" pour signaler l'origine, l'user
  ///   peut renommer apres.
  Future<int> importFromJson(String jsonStr) async {
    final dynamic decoded;
    try {
      decoded = jsonDecode(jsonStr);
    } catch (e) {
      throw const TemplateShareException(
          'Fichier JSON invalide (non parsable)');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const TemplateShareException('Format JSON inattendu');
    }
    final version = decoded['version'];
    if (version is! int || version > _formatVersion) {
      throw TemplateShareException(
          'Version $version non supportee (max : $_formatVersion). '
          'Mets a jour opti_route.');
    }
    final tourneeData = decoded['tournee'];
    final stopsData = decoded['stops'];
    if (tourneeData is! Map<String, dynamic> || stopsData is! List) {
      throw const TemplateShareException('Structure JSON corrompue');
    }

    final nom = (tourneeData['nom'] as String?)?.trim();
    if (nom == null || nom.isEmpty) {
      throw const TemplateShareException('Nom de tournee manquant');
    }
    final pointLat = (tourneeData['pointDepartLat'] as num?)?.toDouble();
    final pointLng = (tourneeData['pointDepartLng'] as num?)?.toDouble();
    final pointLabel = tourneeData['pointDepartLabel'] as String?;
    if (pointLat == null || pointLng == null || pointLabel == null) {
      throw const TemplateShareException('Point de depart manquant');
    }

    // Cree tournee + stops atomiquement : si une ligne stop foire en
    // milieu d'import, on rollback pour pas se retrouver avec une
    // tournee orpheline a moitie remplie. Plus rapide aussi (1 batch
    // INSERT au lieu de N round-trips SQLite).
    return db.transaction(() async {
      final newId = await tournees.create(TourneesCompanion.insert(
        nom: '[Import] $nom',
        date: DateTime.now(),
        pointDepartLat: pointLat,
        pointDepartLng: pointLng,
        pointDepartLabel: pointLabel,
        isTemplate: const Value(true),
        vehiculeCapaciteColis: Value(
            (tourneeData['vehiculeCapaciteColis'] as num?)?.toInt() ?? 0),
        profilOrs:
            Value(tourneeData['profilOrs'] as String? ?? 'driving-car'),
        eviterPeages:
            Value(tourneeData['eviterPeages'] as bool? ?? false),
      ));

      final companions = <StopsCompanion>[];
      for (final raw in stopsData) {
        if (raw is! Map<String, dynamic>) continue;
        companions.add(StopsCompanion.insert(
          tourneeId: newId,
          adresseBrute: (raw['adresseBrute'] as String?) ?? '',
          nomClient: Value(raw['nomClient'] as String?),
          nbColis: Value((raw['nbColis'] as num?)?.toInt() ?? 1),
          priorite: Value((raw['priorite'] as String?) ?? 'flexible'),
          ordrePriorite:
              Value((raw['ordrePriorite'] as num?)?.toInt()),
          fenetreDebut: Value(raw['fenetreDebut'] as String?),
          fenetreFin: Value(raw['fenetreFin'] as String?),
          dureeArretMin:
              Value((raw['dureeArretMin'] as num?)?.toInt() ?? 3),
          notes: Value(raw['notes'] as String?),
        ));
      }
      if (companions.isNotEmpty) {
        await db.batch((b) => b.insertAll(db.stops, companions));
      }
      return newId;
    });
  }

  /// Construit la structure JSON exportable. Pure (pas d'I/O), facile
  /// a tester en isolation. Le format est volontairement minimal :
  /// pas d'id Drift (qui ne signifient rien pour le destinataire),
  /// pas de coords (qui peuvent etre invalides hors zone Noah), pas
  /// de coequipierId (qui n'existe pas chez le destinataire).
  static Map<String, dynamic> _serializeToJson(
    Tournee tournee,
    List<Stop> stops,
  ) {
    return {
      'version': _formatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'tournee': {
        'nom': tournee.nom,
        'pointDepartLat': tournee.pointDepartLat,
        'pointDepartLng': tournee.pointDepartLng,
        'pointDepartLabel': tournee.pointDepartLabel,
        'vehiculeCapaciteColis': tournee.vehiculeCapaciteColis,
        'profilOrs': tournee.profilOrs,
        'eviterPeages': tournee.eviterPeages,
      },
      'stops': [
        for (final s in stops)
          {
            'adresseBrute': s.adresseBrute,
            'nomClient': s.nomClient,
            'nbColis': s.nbColis,
            'priorite': s.priorite,
            'ordrePriorite': s.ordrePriorite,
            'fenetreDebut': s.fenetreDebut,
            'fenetreFin': s.fenetreFin,
            'dureeArretMin': s.dureeArretMin,
            'notes': s.notes,
          },
      ],
    };
  }
}

/// Exception specifique pour les erreurs de share/import template.
/// Permet a l'UI de pop un SnackBar explicite plutot que "Erreur : ...".
class TemplateShareException implements Exception {
  const TemplateShareException(this.message);
  final String message;

  @override
  String toString() => 'TemplateShareException: $message';
}
