import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/database_providers.dart';
import '../theme/app_tokens.dart';

/// Icone hamburger avec un point vert lime quand une tournee est en
/// cours quelque part dans la base. A utiliser comme `leading` des
/// `AppBar` des ecrans accessibles depuis le drawer pour rappeler au
/// livreur qu'il a une tournee active a ne pas oublier.
class DrawerBadgeIcon extends ConsumerWidget {
  const DrawerBadgeIcon({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final hasEnCours = ref.watch(hasTourneeEnCoursProvider);
    return Builder(
      builder: (context) => IconButton(
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.menu),
            if (hasEnCours)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.lime,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).appBarTheme.backgroundColor ??
                          p.cream,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
        tooltip: hasEnCours ? 'Menu - tournee en cours' : 'Menu',
        onPressed: () => Scaffold.of(context).openDrawer(),
      ),
    );
  }
}
