import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/database.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';

/// ════════════════════════════════════════════════════════════════
/// Bloc en-tete de l'ecran "Tournee du jour" : date en mono, nom de
/// la tournee en gros, ligne discrete avec le point de depart.
/// ════════════════════════════════════════════════════════════════
///
/// Pas de logique metier, c'est juste de l'affichage. Le seul truc
/// qui pourrait casser est le format de date i18n (intl `fr` doit
/// etre initialise dans `main()` via `initializeDateFormatting`).
class Header extends StatelessWidget {
  const Header({super.key, required this.tournee});

  final Tournee tournee;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final dateLabel = DateFormat('EEEE d MMMM', 'fr')
        .format(tournee.date)
        .toUpperCase();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dateLabel,
          style: appMonoStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: p.textMute,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: AppSpacing.x6),
        Text(
          tournee.nom,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: p.ink,
            letterSpacing: -0.5,
            height: 1.1,
          ),
        ),
        const SizedBox(height: AppSpacing.x4),
        Text(
          'Depart : ${tournee.pointDepartLabel}',
          style: TextStyle(
            fontSize: 13,
            color: p.textMute,
            height: 1.4,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
