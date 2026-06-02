import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// ════════════════════════════════════════════════════════════════
/// Écran « Nos offres » (comparatif des plans) — carte #381 / #381-D.
/// ════════════════════════════════════════════════════════════════
///
/// Écran 100 % statique et en LECTURE SEULE : il présente les 4 paliers
/// envisagés (Free / Tier 1 / Tier 2 / Tier 3) sans rien brider ni
/// encaisser. C'est la vitrine « Passer premium » accessible depuis le
/// menu, pensée discrète. Les prix sont des **placeholders** (« — ») tant
/// que Noah ne les a pas fixés ; aucune logique de paiement ici.
///
/// Pourquoi maintenant : poser l'écran (additif, sans risque) pendant que
/// le bridage serveur (#381-C) et le paiement (#381-E) restent à décider.
class OffresScreen extends StatelessWidget {
  const OffresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(title: const Text('Nos offres')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.x16),
        children: [
          Text(
            'Choisis la formule adaptée à ton activité. Tout est gratuit '
            'pendant la phase de test — les prix seront communiqués avant '
            'toute facturation.',
            style: TextStyle(fontSize: 13.5, color: p.textMute, height: 1.5),
          ),
          const SizedBox(height: AppSpacing.x16),
          for (final plan in _plans) _carteOffre(context, plan),
          const SizedBox(height: AppSpacing.x16),
          Text(
            'Tu as un code promo ? Saisis-le dans Paramètres → Compte cloud '
            'pour débloquer une formule offerte.',
            style: TextStyle(fontSize: 12, color: p.textFaint, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _carteOffre(BuildContext context, _Offre o) {
    final p = context.palette;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.x12),
      padding: const EdgeInsets.all(AppSpacing.x16),
      decoration: BoxDecoration(
        color: p.creamSoft,
        borderRadius: BorderRadius.circular(AppRadius.r14),
        border: o.miseEnAvant
            ? Border.all(color: AppColors.emerald, width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.x8, vertical: 3),
                decoration: BoxDecoration(
                  color: o.badgeColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  o.badge,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: o.badgeColor,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                o.prix,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: p.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x8),
          Text(
            o.nom,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: p.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.x4),
          Text(o.cible,
              style: TextStyle(fontSize: 12.5, color: p.textMute, height: 1.4)),
          const SizedBox(height: AppSpacing.x12),
          for (final f in o.features)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.x6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_outline,
                      size: 16, color: AppColors.emerald),
                  const SizedBox(width: AppSpacing.x8),
                  Expanded(
                    child: Text(f,
                        style: TextStyle(fontSize: 13, color: p.ink, height: 1.4)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static const _plans = <_Offre>[
    _Offre(
      badge: 'FREE',
      badgeColor: AppColors.emerald,
      nom: 'Solo',
      prix: 'Gratuit',
      cible: 'Pour le chauffeur indépendant qui travaille seul.',
      features: [
        'Optimisation de tournées illimitée',
        'Carnet d\'adresses local',
        'Scan de bordereaux (OCR)',
        'Statistiques & notes de frais',
        'Tout reste sur ton téléphone',
      ],
    ),
    _Offre(
      badge: 'TIER 1',
      badgeColor: AppColors.lime,
      nom: 'Petite équipe',
      prix: '—',
      cible: 'Un entrepôt, jusqu\'à 5 personnes, sans créer d\'entreprise.',
      features: [
        'Tout le plan Solo',
        'Carnet partagé d\'un entrepôt',
        'Jusqu\'à 5 membres',
        'Invitations par code ou mail',
      ],
    ),
    _Offre(
      badge: 'TIER 2',
      badgeColor: AppColors.amber,
      nom: 'Petite entreprise',
      prix: '—',
      miseEnAvant: true,
      cible: 'Crée ton entreprise avec jusqu\'à 2 entrepôts.',
      features: [
        'Tout le plan Petite équipe',
        'Création d\'entreprise',
        'Jusqu\'à 2 entrepôts',
        'Gestion des employés (rôles, mutation)',
        'Notes privées par employé',
      ],
    ),
    _Offre(
      badge: 'TIER 3',
      badgeColor: AppColors.red,
      nom: 'Grande entreprise',
      prix: '—',
      cible: 'Flotte multi-sites, sans aucune limite.',
      features: [
        'Tout le plan Petite entreprise',
        'Entrepôts illimités',
        'Membres illimités',
        'Vue chef multi-entrepôts',
        'Support prioritaire',
      ],
    ),
  ];
}

/// Données statiques d'une offre (vitrine). Aucun lien avec une logique
/// de bridage : c'est purement informatif (#381-D).
class _Offre {
  const _Offre({
    required this.badge,
    required this.badgeColor,
    required this.nom,
    required this.prix,
    required this.cible,
    required this.features,
    this.miseEnAvant = false,
  });

  final String badge;
  final Color badgeColor;
  final String nom;
  final String prix;
  final String cible;
  final List<String> features;
  final bool miseEnAvant;
}
