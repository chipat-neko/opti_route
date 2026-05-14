import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';
import 'tournee_row.dart';

/// ════════════════════════════════════════════════════════════════
/// Widgets de structure de la liste des tournees.
/// ════════════════════════════════════════════════════════════════
///
/// Extrait de `tournees_list_screen.dart` (772 lignes initiales) :
/// - [EmptyState]    : ecran central "Aucune tournee" + invite a creer
/// - [SectionHeader] : titre de section ("Templates" / "En cours" /
///                     "Terminees") en majuscules grises
/// - [TourneesList]  : ListView qui tri en 3 sections et empile les
///                     [TourneeRow]

/// Affiche au centre de l'ecran quand la table tournees est vide :
/// icone + message + invite a tapper "+" en bas.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: p.creamSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_shipping_outlined,
                size: 44,
                color: p.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.x18),
            Text(
              'Aucune tournee',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.x8),
            Text(
              'Tape sur "+" en bas pour creer ta premiere tournee.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: p.textMute,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Titre de section en majuscules grises (fontSize 11, mono 700).
/// Sert de separateur entre les groupes "Templates" / "En cours" /
/// "Terminees" dans la liste principale.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x6,
        AppSpacing.x14,
        AppSpacing.x6,
        AppSpacing.x8,
      ),
      child: Text(
        label.toUpperCase(),
        style: appMonoStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: p.textMute,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

/// ListView qui tri les tournees en 3 sections (templates / actives /
/// terminees), chacune triee par date decroissante. Empile
/// [SectionHeader] + [TourneeRow]s en alternance.
class TourneesList extends ConsumerWidget {
  const TourneesList({super.key, required this.tournees});

  final List<Tournee> tournees;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Tri en 3 sections : templates en haut (modeles reutilisables),
    // actives ensuite (brouillon / optimisee / en_cours), terminees en
    // bas. A l'interieur de chaque section, ordre par date decroissante.
    final templates = tournees.where((t) => t.isTemplate).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final actives = tournees
        .where((t) => !t.isTemplate && t.statut != 'terminee')
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final terminees = tournees
        .where((t) => !t.isTemplate && t.statut == 'terminee')
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final items = <Widget>[];
    if (templates.isNotEmpty) {
      items.add(const SectionHeader('Templates recurrents'));
      for (final t in templates) {
        items.add(TourneeRow(tournee: t));
      }
    }
    if (actives.isNotEmpty) {
      items.add(const SectionHeader('En cours / a venir'));
      for (final t in actives) {
        items.add(TourneeRow(tournee: t));
      }
    }
    if (terminees.isNotEmpty) {
      items.add(const SectionHeader('Terminees'));
      for (final t in terminees) {
        items.add(TourneeRow(tournee: t));
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x14,
        vertical: AppSpacing.x10,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => items[i],
    );
  }
}
