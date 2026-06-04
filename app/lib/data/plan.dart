/// Catalogue des plans / abonnements (#381-A, carte Trello #388).
///
/// ⚠️ FONDATION NEUTRE : à ce stade le plan sert UNIQUEMENT à exposer un
/// badge informatif. AUCUNE limite n'est appliquée (le bridage réel =
/// #381-C / carte #390). `maxEntrepots` / `maxMembres` à `null` = illimité.
///
/// Le catalogue local ci-dessous est un miroir du seed SQL
/// (`docs/supabase-schema-plans-381a.sql`). Il permet d'afficher le badge
/// hors-ligne sans appel cloud.
class Plan {
  const Plan({
    required this.code,
    required this.nom,
    required this.badge,
    this.maxEntrepots,
    this.maxMembres,
    this.peutCreerEntreprise = false,
  });

  /// Code stable : free | tier1 | tier2 | tier3 | illimite.
  final String code;

  /// Libellé long (ex. « Petite entreprise »).
  final String nom;

  /// Libellé court affiché dans le badge (ex. « Tier 1 »).
  final String badge;

  /// Nombre max d'entrepôts ; `null` = illimité.
  final int? maxEntrepots;

  /// Nombre max de membres ; `null` = illimité.
  final int? maxMembres;

  /// Le plan autorise-t-il la création d'une entreprise ?
  final bool peutCreerEntreprise;

  bool get entrepotsIllimites => maxEntrepots == null;
  bool get membresIllimites => maxMembres == null;

  /// Catalogue local (miroir du seed SQL). Source de vérité = Supabase ;
  /// ceci sert d'affichage offline + de secours.
  static const Map<String, Plan> catalogue = <String, Plan>{
    'free': Plan(
      code: 'free',
      nom: 'Solo',
      badge: 'Free',
      maxEntrepots: 0,
      maxMembres: 1,
    ),
    'tier1': Plan(
      code: 'tier1',
      nom: 'Petite équipe',
      badge: 'Tier 1',
      maxEntrepots: 1,
      maxMembres: 5,
    ),
    'tier2': Plan(
      code: 'tier2',
      nom: 'Petite entreprise',
      badge: 'Tier 2',
      maxEntrepots: 2,
      peutCreerEntreprise: true,
    ),
    'tier3': Plan(
      code: 'tier3',
      nom: 'Grande entreprise',
      badge: 'Tier 3',
      peutCreerEntreprise: true,
    ),
    'illimite': Plan(
      code: 'illimite',
      nom: 'Illimité',
      badge: 'Illimité',
      peutCreerEntreprise: true,
    ),
  };

  /// Code par défaut (grandfathering) : aucune limite.
  static const String defaultCode = 'illimite';

  /// Résout un code vers son [Plan]. Retombe sur `illimite` si le code est
  /// `null` ou inconnu — un code non reconnu ne doit JAMAIS brider.
  static Plan fromCode(String? code) =>
      catalogue[code] ?? catalogue[defaultCode]!;
}
