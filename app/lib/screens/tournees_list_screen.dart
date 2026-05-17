import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/cloud_error_humanizer.dart';
import '../data/database.dart';
import '../data/template_share_service.dart';
import '../providers/database_providers.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_drawer.dart';
import '../widgets/drawer_badge_icon.dart';
import '../widgets/offline_geocode_banner.dart';
import 'tournee_du_jour_screen.dart';
import 'tournee_form_screen.dart';
import 'tournees_list/section_widgets.dart';
import 'unified_search_screen.dart';

class TourneesListScreen extends ConsumerStatefulWidget {
  const TourneesListScreen({super.key});

  @override
  ConsumerState<TourneesListScreen> createState() =>
      _TourneesListScreenState();
}

class _TourneesListScreenState extends ConsumerState<TourneesListScreen> {
  String _query = '';

  /// Action de l'icone download dans l'AppBar : ouvre le file picker
  /// pour selectionner un fichier .json exporte par un autre user
  /// (typiquement un coequipier qui partage son template via WhatsApp).
  /// Importe la tournee et ses stops, marque `isTemplate = true`, et
  /// ouvre l'ecran de la nouvelle tournee.
  Future<void> _onImportTemplate() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Choisir un template opti_route (.json)',
      );
      if (picked == null || picked.files.isEmpty) return;
      final path = picked.files.first.path;
      if (path == null) return;
      final body = await File(path).readAsString();
      final newId =
          await ref.read(templateShareServiceProvider).importFromJson(body);
      final newTournee =
          await ref.read(tourneesRepositoryProvider).getById(newId);
      if (!mounted || newTournee == null) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Template "${newTournee.nom}" importe'),
          backgroundColor: AppColors.emerald,
          duration: const Duration(seconds: 2),
        ),
      );
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => TourneeDuJourScreen(tournee: newTournee),
        ),
      );
    } on TemplateShareException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Import refuse : ${e.message}'),
          backgroundColor: AppColors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur import : ${humanizeAnyError(e)}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final tourneesAsync = ref.watch(tourneesStreamProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: const DrawerBadgeIcon(),
        title: const Text('Historique des tournees'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Recherche universelle',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const UnifiedSearchScreen(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Importer un template (JSON)',
            onPressed: _onImportTemplate,
          ),
        ],
      ),
      body: Column(
        children: [
          // Bandeau "N arrets sans GPS" : auto-hide si 0. Permet de
          // re-essayer le geocodage hors-ligne via un CTA tap.
          const OfflineGeocodeBanner(),
          // Champ recherche, visible des qu'on a >= 3 tournees pour
          // ne pas polluer les nouveaux utilisateurs.
          tourneesAsync.maybeWhen(
            data: (list) {
              if (list.length < 3) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x14,
                  AppSpacing.x10,
                  AppSpacing.x14,
                  AppSpacing.x4,
                ),
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, size: 20),
                    hintText: 'Rechercher par nom, client, date...',
                    isDense: true,
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() => _query = ''),
                          )
                        : null,
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          Expanded(
            child: tourneesAsync.when(
              data: (tournees) {
                final filtered = _filter(tournees, _query);
                if (tournees.isEmpty) return const EmptyState();
                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.x22),
                      child: Text(
                        'Aucune tournee ne correspond a "$_query".',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: p.textMute),
                      ),
                    ),
                  );
                }
                return TourneesList(tournees: filtered);
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Erreur : $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle tournee'),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, {Tournee? tournee}) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TourneeFormScreen(initial: tournee),
      ),
    );
  }

  static List<Tournee> _filter(List<Tournee> all, String q) {
    final query = q.trim().toLowerCase();
    if (query.isEmpty) return all;
    return all.where((t) {
      // Match sur le nom, le point de depart, et le mois/jour formate.
      final hay =
          '${t.nom} ${t.pointDepartLabel} ${DateFormat('d MMM y', 'fr').format(t.date)}'
              .toLowerCase();
      return hay.contains(query);
    }).toList();
  }
}
