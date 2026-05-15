import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/unified_search_service.dart';
import '../providers/database_providers.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import 'carnet_adresses_screen.dart';
import 'carnet_edit_screen.dart';
import 'parametres_screen.dart';
import 'scan_bordereau_screen.dart';
import 'stats_screen.dart';
import 'tournee_du_jour_screen.dart';
import 'tournee_form_screen.dart';

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

  /// Liste des dernieres recherches recuperees de [ParametresRepository].
  /// Chargee une fois au mount, mise a jour quand l'utilisateur tap une
  /// recente (remontee en tete) ou ouvre un resultat (la query courante
  /// est ajoutee). Affichee comme chips quand le champ est vide.
  List<String> _recents = const [];

  @override
  void initState() {
    super.initState();
    // Auto-focus du champ a l'ouverture pour que l'utilisateur puisse
    // taper immediatement (sans avoir a clicker dedans).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    _loadRecents();
  }

  Future<void> _loadRecents() async {
    final list = await ref
        .read(parametresRepositoryProvider)
        .getRecentSearches();
    if (!mounted) return;
    setState(() => _recents = list);
  }

  /// Memorise la query qui vient d'aboutir a un tap sur un resultat.
  /// Best-effort : ne bloque pas la navigation si l'I/O echoue.
  Future<void> _rememberQuery(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return;
    try {
      await ref
          .read(parametresRepositoryProvider)
          .addRecentSearch(trimmed);
    } catch (_) {/* best-effort */}
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

  /// Tap sur un chip "recherche recente" : pre-remplit le champ, met
  /// le focus dessus, et lance la recherche immediatement (sans
  /// debounce, l'user veut un retour instantane sur une query connue).
  void _applyRecent(String query) {
    _controller.text = query;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: query.length),
    );
    _debounceTimer?.cancel();
    setState(() => _debouncedQuery = query);
    _focusNode.requestFocus();
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
  /// Arrets, Carnet), avec un compteur par section. Empty state remplace
  /// par recherches recentes + actions rapides (raccourcis vers les
  /// ecrans principaux).
  Widget _buildResults(List<SearchHit> hits) {
    final p = context.palette;
    if (_debouncedQuery.trim().length < 2) {
      return _EmptyState(
        recents: _recents,
        onRecentTap: _applyRecent,
        onClearRecents: () async {
          await ref
              .read(parametresRepositoryProvider)
              .clearRecentSearches();
          if (!mounted) return;
          setState(() => _recents = const []);
        },
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
          for (final h in tournees)
            _TourneeHitTile(
              hit: h,
              query: _debouncedQuery,
              onBeforeOpen: () => _rememberQuery(_debouncedQuery),
            ),
        ],
        if (stops.isNotEmpty) ...[
          _SectionHeader(label: 'ARRETS', count: stops.length),
          for (final h in stops)
            _StopHitTile(
              hit: h,
              query: _debouncedQuery,
              onBeforeOpen: () => _rememberQuery(_debouncedQuery),
            ),
        ],
        if (clients.isNotEmpty) ...[
          _SectionHeader(label: 'CARNET', count: clients.length),
          for (final h in clients)
            _ClientHitTile(
              hit: h,
              query: _debouncedQuery,
              onBeforeOpen: () => _rememberQuery(_debouncedQuery),
            ),
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

/// Construit la liste des actions rapides "raccourcis" affichees dans
/// l'empty state. Statique : la liste est connue a la compile.
/// Chaque entree porte son icone, son label et la route a pousser.
List<_QuickAction> _quickActionsFor(BuildContext context) {
  void open(WidgetBuilder builder) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: builder),
    );
  }

  return [
    _QuickAction(
      icon: Icons.add_road,
      label: 'Nouvelle tournee',
      onTap: () => open((_) => const TourneeFormScreen()),
    ),
    _QuickAction(
      icon: Icons.contacts_outlined,
      label: 'Carnet d\'adresses',
      onTap: () => open((_) => const CarnetAdressesScreen()),
    ),
    _QuickAction(
      icon: Icons.bar_chart_outlined,
      label: 'Statistiques',
      onTap: () => open((_) => const StatsScreen()),
    ),
    _QuickAction(
      icon: Icons.document_scanner_outlined,
      label: 'Scanner un bordereau',
      onTap: () => open((_) => const ScanBordereauScreen()),
    ),
    _QuickAction(
      icon: Icons.settings_outlined,
      label: 'Parametres',
      onTap: () => open((_) => const ParametresScreen()),
    ),
  ];
}

class _QuickAction {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

/// Empty state avec 2 sections :
/// 1. Recherches recentes (chips) -- si l'historique est non vide
/// 2. Actions rapides (tiles) -- toujours visibles
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.recents,
    required this.onRecentTap,
    required this.onClearRecents,
  });

  final List<String> recents;
  final ValueChanged<String> onRecentTap;
  final VoidCallback onClearRecents;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final actions = _quickActionsFor(context);
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x14),
      children: [
        if (recents.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.x14,
              AppSpacing.x8,
              AppSpacing.x14,
              AppSpacing.x8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'RECENT',
                    style: appMonoStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: p.textMute,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onClearRecents,
                  child: const Text('Effacer'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.x14,
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final q in recents)
                  ActionChip(
                    avatar: const Icon(Icons.history, size: 16),
                    label: Text(q),
                    onPressed: () => onRecentTap(q),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x18),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x14,
            AppSpacing.x8,
            AppSpacing.x14,
            AppSpacing.x8,
          ),
          child: Text(
            'ACTIONS RAPIDES',
            style: appMonoStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: p.textMute,
              letterSpacing: 0.6,
            ),
          ),
        ),
        for (final a in actions)
          ListTile(
            leading: CircleAvatar(
              backgroundColor: p.creamSoft,
              foregroundColor: p.ink,
              child: Icon(a.icon, size: 18),
            ),
            title: Text(
              a.label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: a.onTap,
          ),
        const SizedBox(height: AppSpacing.x18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x28),
          child: Text(
            'Tape au moins 2 caracteres pour chercher dans tes tournees, '
            'arrets et clients du carnet. Tolerance fautes de frappe.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: p.textMute,
              height: 1.4,
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
/// [query] sert au highlight du match ; [onBeforeOpen] memorise la
/// query dans l'historique des recherches recentes avant la nav.
class _TourneeHitTile extends StatelessWidget {
  const _TourneeHitTile({
    required this.hit,
    required this.query,
    required this.onBeforeOpen,
  });
  final SearchHitTournee hit;
  final String query;
  final VoidCallback onBeforeOpen;

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
      title: _HighlightedText(
        text: t.nom,
        query: query,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '$df · ${_statutLabel(t.statut)}',
        style: TextStyle(fontSize: 12, color: p.textMute),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        onBeforeOpen();
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
  const _StopHitTile({
    required this.hit,
    required this.query,
    required this.onBeforeOpen,
  });
  final SearchHitStop hit;
  final String query;
  final VoidCallback onBeforeOpen;

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
      title: _HighlightedText(
        text: primary,
        query: query,
        style: const TextStyle(fontWeight: FontWeight.w700),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '$secondary\n→ ${hit.tournee.nom}',
        style: TextStyle(fontSize: 12, color: p.textMute),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      isThreeLine: true,
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        onBeforeOpen();
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
  const _ClientHitTile({
    required this.hit,
    required this.query,
    required this.onBeforeOpen,
  });
  final SearchHitClient hit;
  final String query;
  final VoidCallback onBeforeOpen;

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
      title: _HighlightedText(
        text: primary,
        query: query,
        style: const TextStyle(fontWeight: FontWeight.w700),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        secondary,
        style: TextStyle(fontSize: 12, color: p.textMute),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        onBeforeOpen();
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

/// Texte qui met en gras + accent emerald les substrings matchant la
/// query (case-insensitive). Si la query ne match pas exactement dans
/// le texte (cas Levenshtein fuzzy), on retombe sur un Text normal.
class _HighlightedText extends StatelessWidget {
  const _HighlightedText({
    required this.text,
    required this.query,
    this.style,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final String query;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final spans = _buildSpans(text, query, style);
    if (spans.length == 1) {
      // Pas de match exact -> texte normal (rapide, evite RichText).
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
      );
    }
    return RichText(
      text: TextSpan(style: style, children: spans),
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
    );
  }

  static List<InlineSpan> _buildSpans(
    String text,
    String query,
    TextStyle? base,
  ) {
    final q = query.trim();
    if (q.isEmpty) return [TextSpan(text: text)];
    final lower = text.toLowerCase();
    final qLower = q.toLowerCase();
    final spans = <InlineSpan>[];
    var i = 0;
    while (i < text.length) {
      final idx = lower.indexOf(qLower, i);
      if (idx < 0) {
        spans.add(TextSpan(text: text.substring(i)));
        break;
      }
      if (idx > i) {
        spans.add(TextSpan(text: text.substring(i, idx)));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + qLower.length),
        style: TextStyle(
          backgroundColor: AppColors.lime.withValues(alpha: 0.45),
          fontWeight: FontWeight.w800,
          color: base?.color,
        ),
      ));
      i = idx + qLower.length;
    }
    return spans;
  }
}
