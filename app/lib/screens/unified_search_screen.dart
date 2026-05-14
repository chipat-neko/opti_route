import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/unified_search_service.dart';
import '../providers/database_providers.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import 'carnet_edit_screen.dart';
import 'tournee_du_jour_screen.dart';

/// ════════════════════════════════════════════════════════════════
/// Recherche universelle (Cmd+K style) — modal plein ecran.
/// ════════════════════════════════════════════════════════════════
///
/// Accessible via une icone loupe dans les AppBars principaux (Home,
/// Historique des tournees, Carnet). Tape "boul" et tu trouves :
///   - les **tournees** qui contiennent "boul" dans leur nom
///   - les **arrets** dont nom client / adresse / notes matchent
///   - les **clients** du carnet correspondants
///
/// Tri global par score Levenshtein (le plus proche en premier),
/// regroupement visuel par categorie. Tap sur un resultat = navigue
/// directement vers l'ecran approprie.
///
/// Debounce 200 ms sur les keystrokes pour eviter de spam Drift a
/// chaque touche pendant que l'utilisateur tape vite.
class UnifiedSearchScreen extends ConsumerStatefulWidget {
  const UnifiedSearchScreen({super.key});

  @override
  ConsumerState<UnifiedSearchScreen> createState() =>
      _UnifiedSearchScreenState();
}

class _UnifiedSearchScreenState extends ConsumerState<UnifiedSearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  /// Query effective utilisee pour le watch Riverpod. Debounce evite
  /// que chaque touche tape ne declenche un scan Drift complet.
  String _debouncedQuery = '';
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Auto-focus du champ a l'ouverture pour que l'utilisateur puisse
    // taper immediatement (sans avoir a clicker dedans).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      setState(() => _debouncedQuery = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final hitsAsync = _debouncedQuery.trim().length < 2
        ? const AsyncValue<List<SearchHit>>.data([])
        : ref.watch(unifiedSearchProvider(_debouncedQuery));

    return Scaffold(
      backgroundColor: p.cream,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: TextField(
          controller: _controller,
          focusNode: _focusNode,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Rechercher tournees, arrets, clients...',
            border: InputBorder.none,
          ),
          style: const TextStyle(fontSize: 16),
          textInputAction: TextInputAction.search,
          onChanged: _onQueryChanged,
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Effacer',
              onPressed: () {
                _controller.clear();
                _onQueryChanged('');
              },
            ),
        ],
      ),
      body: hitsAsync.when(
        data: (hits) => _buildResults(hits),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Erreur de recherche : $e',
            style: const TextStyle(color: AppColors.red),
          ),
        ),
      ),
    );
  }

  /// Affichage des resultats : regroupes par categorie (Tournees,
  /// Arrets, Carnet), avec un compteur par section. Empty state
  /// different selon que la query est trop courte ou que rien n'a
  /// matche.
  Widget _buildResults(List<SearchHit> hits) {
    final p = context.palette;
    if (_debouncedQuery.trim().length < 2) {
      return _Hint(
        icon: Icons.search,
        title: 'Tape au moins 2 caracteres',
        subtitle:
            'Cherche dans tes tournees, arrets, clients du carnet. Tolerance fautes de frappe inclue.',
      );
    }
    if (hits.isEmpty) {
      return _Hint(
        icon: Icons.search_off,
        title: 'Aucun resultat pour "$_debouncedQuery"',
        subtitle: 'Essaye avec moins de caracteres, ou un mot different.',
      );
    }

    // Regroupement par categorie
    final tournees = hits.whereType<SearchHitTournee>().toList();
    final stops = hits.whereType<SearchHitStop>().toList();
    final clients = hits.whereType<SearchHitClient>().toList();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x8),
      children: [
        if (tournees.isNotEmpty) ...[
          _SectionHeader(label: 'TOURNEES', count: tournees.length),
          for (final h in tournees) _TourneeHitTile(hit: h),
        ],
        if (stops.isNotEmpty) ...[
          _SectionHeader(label: 'ARRETS', count: stops.length),
          for (final h in stops) _StopHitTile(hit: h),
        ],
        if (clients.isNotEmpty) ...[
          _SectionHeader(label: 'CARNET', count: clients.length),
          for (final h in clients) _ClientHitTile(hit: h),
        ],
        const SizedBox(height: AppSpacing.x18),
        Center(
          child: Text(
            '${hits.length} resultat${hits.length > 1 ? "s" : ""}',
            style: TextStyle(
              fontSize: 11,
              color: p.textMute,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: p.textMute, size: 48),
            const SizedBox(height: AppSpacing.x14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: p.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.x6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: p.textMute,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.count});
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x14,
        AppSpacing.x14,
        AppSpacing.x14,
        AppSpacing.x6,
      ),
      child: Text(
        '$label · $count',
        style: appMonoStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: context.palette.textMute,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

/// Tile pour une tournee : tap = ouvre TourneeDuJourScreen.
class _TourneeHitTile extends StatelessWidget {
  const _TourneeHitTile({required this.hit});
  final SearchHitTournee hit;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = hit.tournee;
    final df = DateFormat('d MMM yyyy', 'fr').format(t.date);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: p.creamSoft,
        foregroundColor: p.ink,
        child: const Icon(Icons.local_shipping_outlined, size: 18),
      ),
      title: Text(t.nom, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(
        '$df · ${_statutLabel(t.statut)}',
        style: TextStyle(fontSize: 12, color: p.textMute),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => TourneeDuJourScreen(tournee: t),
          ),
        );
      },
    );
  }

  static String _statutLabel(String s) => switch (s) {
        'brouillon' => 'Brouillon',
        'optimisee' => 'Optimisee',
        'en_cours' => 'En cours',
        'terminee' => 'Terminee',
        _ => s,
      };
}

/// Tile pour un stop : tap = ouvre la tournee parente (l'utilisateur
/// peut ensuite scroller jusqu'au stop dans la liste).
class _StopHitTile extends StatelessWidget {
  const _StopHitTile({required this.hit});
  final SearchHitStop hit;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = hit.stop;
    final primary = (s.nomClient?.isNotEmpty ?? false)
        ? s.nomClient!
        : s.adresseBrute.split(',').first.trim();
    final secondary = s.adresseNormalisee ?? s.adresseBrute;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: p.creamSoft,
        foregroundColor: p.ink,
        child: const Icon(Icons.location_on_outlined, size: 18),
      ),
      title: Text(primary,
          style: const TextStyle(fontWeight: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '$secondary\n→ ${hit.tournee.nom}',
        style: TextStyle(fontSize: 12, color: p.textMute),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      isThreeLine: true,
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => TourneeDuJourScreen(tournee: hit.tournee),
          ),
        );
      },
    );
  }
}

/// Tile pour un client du carnet : tap = ouvre CarnetEditScreen.
class _ClientHitTile extends StatelessWidget {
  const _ClientHitTile({required this.hit});
  final SearchHitClient hit;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final c = hit.client;
    final primary =
        (c.nomClient?.isNotEmpty ?? false) ? c.nomClient! : c.adresseDisplay;
    final secondary = (c.nomClient?.isNotEmpty ?? false)
        ? c.adresseDisplay
        : '${c.useCount} livraison${c.useCount > 1 ? "s" : ""}';
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: colorFromTag(c.colorTag, defaultColor: p.creamSoft),
        foregroundColor: p.ink,
        child: Text(
          _initials(primary),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
        ),
      ),
      title: Text(primary,
          style: const TextStyle(fontWeight: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      subtitle: Text(
        secondary,
        style: TextStyle(fontSize: 12, color: p.textMute),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => CarnetEditScreen(entry: c),
          ),
        );
      },
    );
  }

  static String _initials(String s) {
    final parts = s.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1))
        .toUpperCase();
  }
}
