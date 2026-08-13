import 'package:flutter/material.dart';

/// ════════════════════════════════════════════════════════════════
/// Menus "Importer / peupler" et "Exporter" de l'app bar du carnet.
/// ════════════════════════════════════════════════════════════════
///
/// Extraits de `carnet_adresses_screen.dart` (refactor F27) : les deux
/// PopupMenuButton faisaient ~95 lignes inline dans les `actions` de
/// l'AppBar, pour au final ne faire que remonter un choix.
///
/// **Pattern callback unique** (comme `tournee_du_jour/plus_menu.dart`)
/// : un seul `onAction(enum)` par menu, le mapping vers les handlers
/// reste dans l'ecran parent qui a le contexte + la ref.

/// Entrees du menu "Importer / peupler".
enum CarnetImportAction { vcard, csv, csvGeocode, backfill }

/// Entrees du menu "Exporter".
enum CarnetExportAction { csv, vcard }

/// Bouton "upload" de l'app bar : les 4 facons de remplir le carnet
/// (vCard, CSV complet, CSV simplifie geocode, historique des arrets).
class CarnetImportMenu extends StatelessWidget {
  const CarnetImportMenu({super.key, required this.onAction});

  final ValueChanged<CarnetImportAction> onAction;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<CarnetImportAction>(
      icon: const Icon(Icons.file_upload_outlined),
      tooltip: 'Importer / peupler',
      onSelected: onAction,
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: CarnetImportAction.vcard,
          child: ListTile(
            leading: Icon(Icons.contact_phone_outlined),
            title: Text('Importer vCard'),
            subtitle: Text(
              'Contacts Google / Android (.vcf), geocode auto',
              style: TextStyle(fontSize: 11),
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: CarnetImportAction.csv,
          child: ListTile(
            leading: Icon(Icons.upload_file_outlined),
            title: Text('Importer CSV complet'),
            subtitle: Text(
              'CSV avec lat/lng (export precedent)',
              style: TextStyle(fontSize: 11),
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: CarnetImportAction.csvGeocode,
          child: ListTile(
            leading: Icon(Icons.add_location_outlined),
            title: Text('Importer CSV simplifie'),
            subtitle: Text(
              'Nom + adresse, geocodage auto BAN',
              style: TextStyle(fontSize: 11),
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: CarnetImportAction.backfill,
          child: ListTile(
            leading: Icon(Icons.history_outlined),
            title: Text('Depuis l\'historique'),
            subtitle: Text(
              'Tous mes arrets deja faits',
              style: TextStyle(fontSize: 11),
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}

/// Bouton "partager" de l'app bar : export CSV (sauvegarde tableur) ou
/// vCard (import direct dans l'app Contacts).
class CarnetExportMenu extends StatelessWidget {
  const CarnetExportMenu({super.key, required this.onAction});

  final ValueChanged<CarnetExportAction> onAction;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<CarnetExportAction>(
      icon: const Icon(Icons.ios_share),
      tooltip: 'Exporter',
      onSelected: onAction,
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: CarnetExportAction.csv,
          child: ListTile(
            leading: Icon(Icons.description_outlined),
            title: Text('Exporter en CSV'),
            subtitle: Text(
              'Sauvegarde tableur',
              style: TextStyle(fontSize: 11),
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: CarnetExportAction.vcard,
          child: ListTile(
            leading: Icon(Icons.contact_phone_outlined),
            title: Text('Exporter en vCard'),
            subtitle: Text(
              'Import direct dans Contacts',
              style: TextStyle(fontSize: 11),
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}
