import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import 'unified_search/hit_tiles.dart';

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
/// **Filtres** : chips Tout / Tournees / Arrets / Carnet sous la barre
/// pour ne montrer qu'une categorie a la fois. Compteurs entre parents
/// pour donner la repartition d'un coup d'oeil.
///
/// **Navigation clavier** (utile en web ou avec clavier branche en
/// Bluetooth) :
///   - fleches haut/bas : change le resultat selectionne
///   - Enter : ouvre le resultat selectionne (ou le 1er si rien selectionne)
///   - Escape : ferme la palette
///
/// Debounce 200 ms sur les keystrokes pour eviter de spam Drift a
/// chaque touche pendant que l'utilisateur tape vite.
class UnifiedSearchScreen extends ConsumerStatefulWidget {
  const UnifiedSearchScreen({super.key});

  @override
  ConsumerState<UnifiedSearchScreen> createState() =>
      _UnifiedSearchScreenState();
}

/// Categorie de filtre pour les resultats. `all` = pas de filtre.
enum _HitCategory { all, tournees, stops, clients }

class _UnifiedSearchScreenState extends ConsumerState<UnifiedSearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();

  /// Query effective utilisee pour le watch Riverpod. Debounce evite
  /// que chaque touche tape ne declenche un scan Drift complet.
  String _debouncedQuery = '';
  Timer? _debounceTimer;

  /// Filtre courant. Toggleable via les chips. [_HitCategory.all]
  /// montre toutes les categories regroupees.
  _HitCategory _filter = _HitCategory.all;

  /// Index du resultat selectionne dans la liste FILTREE (pas dans
  /// `hits` brut). -1 = rien selectionne (etat initial avant nav
  /// clavier). Mis a 0 automatiquement a chaque nouveau set de
  /// resultats pour permettre Enter -> 1er hit sans avoir a presser
  /// flecha bas avant.
  int _selectedIndex = -1;

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
    // Intercepte les touches clavier de navigation (fleches, Enter,
    // Escape) avant que le TextField ne les consomme. On laisse passer
    // tout le reste pour preserver le typing normal.
    _focusNode.onKeyEvent = _handleKey;
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
    _scrollController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      setState(() {
        _debouncedQuery = value;
        // Une nouvelle query reset la selection au 1er resultat (qui
        // n'existe pas encore avant que le provider retourne).
        _selectedIndex = -1;
      });
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
    setState(() {
      _debouncedQuery = query;
      _selectedIndex = -1;
    });
    _focusNode.requestFocus();
  }

  /// Applique le filtre courant a la liste brute de hits. Garde l'ordre
  /// d'origine (deja trie par score Levenshtein).
  List<SearchHit> _applyFilter(List<SearchHit> hits) {
    switch (_filter) {
      case _HitCategory.all:
        return hits;
      case _HitCategory.tournees:
        return hits.whereType<SearchHitTournee>().toList();
      case _HitCategory.stops:
        return hits.whereType<SearchHitStop>().toList();
      case _HitCategory.clients:
        return hits.whereType<SearchHitClient>().toList();
    }
  }

  /// Handler clavier global de la palette. Intercepte les fleches /
  /// Enter / Escape AVANT que le TextField ne traite (ce qui ferait
  /// bouger le curseur de texte au lieu de naviguer dans la liste).
  /// Retourne `handled` pour les touches consommees, `ignored` sinon.
  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final hits = _currentFilteredHits();
    if (key == LogicalKeyboardKey.escape) {
      Navigator.of(context).maybePop();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      if (hits.isEmpty) return KeyEventResult.ignored;
      setState(() {
        _selectedIndex = (_selectedIndex + 1).clamp(0, hits.length - 1);
      });
      _scrollSelectedIntoView();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      if (hits.isEmpty) return KeyEventResult.ignored;
      setState(() {
        _selectedIndex = _selectedIndex <= 0 ? 0 : _selectedIndex - 1;
      });
      _scrollSelectedIntoView();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (hits.isEmpty) return KeyEventResult.ignored;
      final idx = _selectedIndex < 0 ? 0 : _selectedIndex;
      _openHit(hits[idx]);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// Recupere la liste filtree des hits depuis le provider Riverpod.
  /// Utilise par [_handleKey] qui n'a pas acces a hitsAsync en
  /// closure.
  List<SearchHit> _currentFilteredHits() {
    if (_debouncedQuery.trim().length < 2) return const [];
    final async = ref.read(unifiedSearchProvider(_debouncedQuery));
    final hits = async.asData?.value ?? const [];
    return _applyFilter(hits);
  }

  /// Navigue vers l'ecran correspondant au hit, apres avoir memorise
  /// la query courante dans l'historique.
  void _openHit(SearchHit hit) {
    _rememberQuery(_debouncedQuery);
    if (hit is SearchHitTournee) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => TourneeDuJourScreen(tournee: hit.tournee),
        ),
      );
    } else if (hit is SearchHitStop) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => TourneeDuJourScreen(tournee: hit.tournee),
        ),
      );
    } else if (hit is SearchHitClient) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => CarnetEditScreen(entry: hit.client),
        ),
      );
    }
  }

  /// Scroll le resultat selectionne dans la vue. Best-effort : si
  /// l'estimation Y rate (hauteur tile dynamique), au pire la liste
  /// scroll au mauvais endroit -- non bloquant pour la nav.
  void _scrollSelectedIntoView() {
    if (!_scrollController.hasClients) return;
    // Heuristique simple : chaque ListTile fait ~72 px (3 lignes) +
    // les headers de section ~36 px (mais avec filtre `all` seulement).
    // Pour rester simple on prend 76 px par item.
    const itemHeight = 76.0;
    final targetOffset = _selectedIndex * itemHeight;
    final viewport = _scrollController.position.viewportDimension;
    final current = _scrollController.offset;
    // Scroll uniquement si le target est hors viewport.
    if (targetOffset < current ||
        targetOffset > current + viewport - itemHeight) {
      _scrollController.animateTo(
        targetOffset.clamp(
          0,
          _scrollController.position.maxScrollExtent,
        ),
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );
    }
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
          onSubmitted: (_) {
            final hits = _currentFilteredHits();
            if (hits.isNotEmpty) _openHit(hits[0]);
          },
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
        bottom: hitsAsync.asData != null && _debouncedQuery.trim().length >= 2
            ? _FilterBar(
                hits: hitsAsync.asData!.value,
                current: _filter,
                onChanged: (f) => setState(() {
                  _filter = f;
                  _selectedIndex = -1;
                }),
              )
            : null,
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

  /// Affichage des resultats : regroupes par categorie quand le filtre
  /// est `all`, sinon liste plate. Empty state remplace par recherches
  /// recentes + actions rapides (raccourcis vers les ecrans principaux).
  Widget _buildResults(List<SearchHit> hits) {
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

    final filtered = _applyFilter(hits);
    if (filtered.isEmpty) {
      return _Hint(
        icon: Icons.filter_alt_off_outlined,
        title: 'Aucun resultat dans cette categorie',
        subtitle: 'Bascule sur "Tout" ou une autre categorie.',
      );
    }

    // Si filtre `all` : on garde le regroupement par section.
    // Si filtre specifique : liste plate avec selection visible.
    if (_filter == _HitCategory.all) {
      return _buildGroupedList(filtered);
    }
    return _buildFlatList(filtered);
  }

  /// Vue groupee par categorie (utilisee quand filtre = all).
  /// Pas de selection visible ici car la liste mixe avec des headers
  /// (l'indice dans la liste ne correspond pas a l'indice du hit).
  Widget _buildGroupedList(List<SearchHit> filtered) {
    final p = context.palette;
    final tournees = filtered.whereType<SearchHitTournee>().toList();
    final stops = filtered.whereType<SearchHitStop>().toList();
    final clients = filtered.whereType<SearchHitClient>().toList();

    // Index continu pour la selection clavier (les headers ne comptent
    // pas comme positions selectionnables).
    var flatIndex = 0;
    Widget tileFor(SearchHit h) {
      final selected = flatIndex == _selectedIndex;
      final widget = _tileFor(h, selected);
      flatIndex++;
      return widget;
    }

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x8),
      children: [
        if (tournees.isNotEmpty) ...[
          SearchSectionHeader(label: 'TOURNEES', count: tournees.length),
          for (final h in tournees) tileFor(h),
        ],
        if (stops.isNotEmpty) ...[
          SearchSectionHeader(label: 'ARRETS', count: stops.length),
          for (final h in stops) tileFor(h),
        ],
        if (clients.isNotEmpty) ...[
          SearchSectionHeader(label: 'CARNET', count: clients.length),
          for (final h in clients) tileFor(h),
        ],
        const SizedBox(height: AppSpacing.x18),
        Center(
          child: Text(
            '${filtered.length} resultat${filtered.length > 1 ? "s" : ""}'
            ' · ↑↓ pour naviguer · Enter pour ouvrir',
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

  /// Vue plate (filtre actif specifique) : pas de headers, just les
  /// tiles dans l'ordre du score. Selection visible.
  Widget _buildFlatList(List<SearchHit> filtered) {
    final p = context.palette;
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x8),
      itemCount: filtered.length + 1,
      itemBuilder: (_, i) {
        if (i == filtered.length) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.x14),
            child: Center(
              child: Text(
                '${filtered.length} resultat${filtered.length > 1 ? "s" : ""}'
                ' · ↑↓ pour naviguer · Enter pour ouvrir',
                style: TextStyle(
                  fontSize: 11,
                  color: p.textMute,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          );
        }
        return _tileFor(filtered[i], i == _selectedIndex);
      },
    );
  }

  /// Dispatch sur le bon widget de tile selon le type de hit.
  /// [selected] : si true, la tile est entouree d'un border lime pour
  /// indiquer la cible courante de la touche Enter (nav clavier).
  Widget _tileFor(SearchHit h, bool selected) {
    void cb() => _rememberQuery(_debouncedQuery);
    Widget tile;
    if (h is SearchHitTournee) {
      tile = TourneeHitTile(hit: h, query: _debouncedQuery, onBeforeOpen: cb);
    } else if (h is SearchHitStop) {
      tile = StopHitTile(hit: h, query: _debouncedQuery, onBeforeOpen: cb);
    } else if (h is SearchHitClient) {
      tile = ClientHitTile(hit: h, query: _debouncedQuery, onBeforeOpen: cb);
    } else {
      tile = const SizedBox.shrink();
    }
    if (!selected) return tile;
    // Border lime pour signaler la selection clavier.
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.lime, width: 2),
        borderRadius: BorderRadius.circular(AppRadius.r10),
      ),
      child: tile,
    );
  }
}

/// Barre de filtres : 4 ChoiceChip "Tout / Tournees / Arrets / Carnet"
/// avec le compteur de chaque categorie entre parenthese. Affichee
/// uniquement quand on a >= 2 caracteres de query (sinon pas de
/// resultats a filtrer).
class _FilterBar extends StatelessWidget implements PreferredSizeWidget {
  const _FilterBar({
    required this.hits,
    required this.current,
    required this.onChanged,
  });

  final List<SearchHit> hits;
  final _HitCategory current;
  final ValueChanged<_HitCategory> onChanged;

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    final nbTournees = hits.whereType<SearchHitTournee>().length;
    final nbStops = hits.whereType<SearchHitStop>().length;
    final nbClients = hits.whereType<SearchHitClient>().length;

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x12,
          vertical: AppSpacing.x6,
        ),
        children: [
          _Chip(
            label: 'Tout (${hits.length})',
            selected: current == _HitCategory.all,
            onSelected: () => onChanged(_HitCategory.all),
          ),
          if (nbTournees > 0)
            _Chip(
              label: 'Tournees ($nbTournees)',
              selected: current == _HitCategory.tournees,
              onSelected: () => onChanged(_HitCategory.tournees),
            ),
          if (nbStops > 0)
            _Chip(
              label: 'Arrets ($nbStops)',
              selected: current == _HitCategory.stops,
              onSelected: () => onChanged(_HitCategory.stops),
            ),
          if (nbClients > 0)
            _Chip(
              label: 'Carnet ($nbClients)',
              selected: current == _HitCategory.clients,
              onSelected: () => onChanged(_HitCategory.clients),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
      ),
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

// _SectionHeader / _TourneeHitTile / _StopHitTile / _ClientHitTile /
// _HighlightedText sont extraits dans lib/screens/unified_search/hit_tiles.dart
// (refactor 2026-05-18, split du fichier 1056 -> ~790 lignes).
