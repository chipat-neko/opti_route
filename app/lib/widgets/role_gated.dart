import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_role.dart';
import '../providers/database_providers.dart';

/// Masque un widget si le rôle courant ne peut pas voir la feature.
/// Utilise `currentRoleProvider` + `FeatureRegistry.canSee`.
///
/// Usage :
/// ```dart
/// RoleGated(
///   featureKey: 'compta.km_urssaf',
///   child: KmUrssafSection(),
/// )
/// ```
///
/// Quand le toggle Mode chef change, le widget se rebuild automatiquement
/// (Stream du provider). Le `fallback` (default: SizedBox.shrink) est
/// affiché à la place.
class RoleGated extends ConsumerWidget {
  const RoleGated({
    super.key,
    required this.featureKey,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  });

  final String featureKey;
  final Widget child;
  final Widget fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRole = ref.watch(currentRoleProvider);
    final role = asyncRole.asData?.value ?? AppRole.chauffeur;
    final canSee = FeatureRegistry.canSee(
      featureKey: featureKey,
      role: role,
    );
    return canSee ? child : fallback;
  }
}
