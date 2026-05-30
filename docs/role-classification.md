# Classification Chauffeur / Chef

Référence pour wirer le widget `RoleGated` sur les nouvelles features. Le défaut est **chauffeur** (visible par tous) — seules les features explicitement listées en **chef-only** doivent être gated.

Le toggle est dans **Paramètres > Mode équipe** (`mode_chef_equipe`) et l'override serveur Supabase est `user.app_metadata.role`.

## Chef-only (cachées au chauffeur)

### Compta / fiscal
| Feature key | Justification |
|---|---|
| `compta.km_urssaf` | Barème URSSAF, déductible — gestion paie |
| `compta.fec_export` | FEC pour expert-comptable — admin |
| `compta.facturation` | Génération factures donneurs d'ordre |
| `compta.cod_total_caisse` | Total caisse fin de tournée — gestion |

### Véhicule / sinistres
| Feature key | Justification |
|---|---|
| `vehicule.entretien_alerts` | Vidange, CT, courroie, pneus — gestion parc |
| `vehicule.constat_sinistre` | Constat amiable PDF — déclaration assurance |

### Stats avancées
| Feature key | Justification |
|---|---|
| `stats.heatmap_echecs` | Analyse zone/heure — décision tactique |
| `stats.historique_client` | Best/worst hour, taux par client — sales |
| `stats.comparateur_tournees` | Diff prévue/réalisée — négo donneur d'ordre |
| `stats.carte_chaleur_temps_perdu` | Zones consommatrices — négo grille |
| `stats.weekly_report_donneur_ordre` | PDF hebdo TFA — comm chef-client |

### Equipe / dispatch
| Feature key | Justification |
|---|---|
| `equipe.dispatch_live` | Réassigner stops entre coéquipiers — chef |
| `equipe.invitation_coequipier` | Code invitation Supabase — chef |
| `equipe.split_paie_double_cabine` | Split CA par coéquipier — gestion |

### Logistique préparatoire
| Feature key | Justification |
|---|---|
| `logistique.plan_chargement_3d` | Préparation tournée veille — chef |
| `logistique.stock_fournitures` | Commande scotch/étiquettes/sacs — gestion |

### Pointage avancé
| Feature key | Justification |
|---|---|
| `pointage.cumul_semaine` | Heures hebdo — paie chef |
| `pointage.cumul_mois` | Heures mensuelles — paie chef |

## Chauffeur (visibles par défaut)

### Tournée terrain
- `tournee.eta_dynamique`, `tournee.fin_retour_depot`, `tournee.recalc_position`
- `tournee.compteur_colis_camion`, `tournee.recap_depot`
- `tournee.briefing_matinal`, `tournee.debrief_vocal`
- `tournee.passation_remplacant`

### Stop / livraison
- `stop.memo_vocal`, `stop.notation_emoji`, `stop.depose_sans_contact`
- `stop.mentions_ocr`, `stop.preferences_client`
- `stop.litige_dossier` (chauffeur a besoin d'opposer une preuve)
- `stop.scan_doublons`

### Carnet
- `carnet.note_stationnement`, `carnet.parking_spots`
- `carnet.vigilance`, `carnet.fenetre_horaire_suggeree`

### Sécurité chauffeur
- `securite.sos_button`, `securite.pin_app_lock`
- `securite.temps_conduite`, `securite.eco_conduite`
- `securite.battery_mode`

### Autre
- `meteo.tournee`, `colis.chaine_froid`
- `message.jarrive_client`, `geofence.arrivee`
- `pointage.toggle_service`, `pointage.cumul_jour`

## Usage

```dart
// Dans n'importe quel widget Riverpod :
RoleGated(
  featureKey: 'compta.km_urssaf',
  child: KmUrssafSection(),
)

// Ou impérativement :
final canSee = FeatureRegistry.canSee(
  featureKey: 'compta.km_urssaf',
  role: AppRole.chauffeur,
);
```

## Toggle utilisateur

Paramètres > **Entreprise / Mode équipe** > toggle "Mode chef d'équipe" (existant). Le rebuild des `RoleGated` est automatique via `currentRoleProvider` Stream.

## Override serveur

`RoleService.resolveCurrentRole(serverRoleRaw: user.appMetadata['role'])`. Si `'chef'` côté serveur → force chef quoi qu'il arrive (anti-promotion d'un sous-traitant). Le toggle local reste prioritaire dans tous les autres cas.
