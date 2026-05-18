import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/unified_search_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';
import '../carnet_edit_screen.dart';
import '../tournee_du_jour_screen.dart';

/// ════════════════════════════════════════════════════════════════
/// Tiles + widgets visuels de [UnifiedSearchScreen] — extraits du
/// fichier principal pour reduire sa taille (1056 -> ~600 lignes) et
/// faciliter la lecture. Aucun changement de comportement.
/// ════════════════════════════════════════════════════════════════
///
/// Toutes les classes sont publiques (suffix `Tile` / `HighlightedText`)
/// pour pouvoir etre importees depuis le screen. Le `query` sert au
/// highlight Lime du substring matche.

/// Section header monospace : "TOURNEES · 3", utilise pour separer
/// visuellement les groupes de hits (tournees / arrets / carnet) dans
/// la ListView principale.
class SearchSectionHeader extends StatelessWidget {
  const SearchSectionHeader({
    super.key,
    required this.label,
    required this.count,
  });
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
class TourneeHitTile extends StatelessWidget {
  const TourneeHitTile({
    super.key,
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
      title: HighlightedText(
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
class StopHitTile extends StatelessWidget {
  const StopHitTile({
    super.key,
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
      title: HighlightedText(
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
class ClientHitTile extends StatelessWidget {
  const ClientHitTile({
    super.key,
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
      title: HighlightedText(
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

/// Texte qui met en gras + accent lime les substrings matchant la
/// query (case-insensitive). Si la query ne match pas exactement dans
/// le texte (cas Levenshtein fuzzy), on retombe sur un Text normal.
class HighlightedText extends StatelessWidget {
  const HighlightedText({
    super.key,
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
