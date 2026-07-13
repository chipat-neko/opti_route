/// ════════════════════════════════════════════════════════════════
/// Constantes centralisees de l'application.
/// ════════════════════════════════════════════════════════════════
///
/// Source unique de verite pour les magic strings / numbers utilises
/// a plusieurs endroits du code. Cree au Sprint 3.A (audit refactor
/// 2026-05-22) pour eliminer la duplication des litteraux 'livre',
/// 'en_cours', timeouts, seuils, etc.
///
/// **Convention** : prefixe `k` (Flutter convention) pour les
/// constantes globales, distinguer des enum values.
///
/// **Migration** : les nouvelles features doivent utiliser ces
/// constantes. Les anciennes hardcoded (60+ occurrences au moment de
/// la creation de ce fichier) migrent progressivement quand on touche
/// au code concerne (pas de big-bang risque).
///
/// Pour les types Stop (`livraison` / `ramasse`), voir le fichier
/// dedie [stop_types.dart].
library;

// ════════════════════════════════════════════════════════════════
// Enums-strings de statut : volontairement en LITTERAUX directs
// ════════════════════════════════════════════════════════════════
//
// Les statuts (`Stops.statutLivraison` = a_livrer/livre/echec,
// `Tournees.statut` = brouillon/optimisee/en_cours/terminee), raisons
// d'echec et priorites restent des litteraux directs dans le code ET la
// DB (Drift). Des constantes equivalentes avaient ete creees au Sprint
// 3.A mais JAMAIS adoptees (0 usage contre 91 litteraux) -> supprimees
// (audit #223) pour ne pas garder une double source de verite. Ne PAS
// les re-ajouter ; pour une vraie securite de type un jour, passer par
// un enum + TypeConverter Drift (plus gros chantier).

// ════════════════════════════════════════════════════════════════
// Seuils & timeouts
// ════════════════════════════════════════════════════════════════

/// Distance en metres en-dessous de laquelle on considere 2 arrets
/// geographiquement IDENTIQUES (utilise pour la detection de doublon
/// au save d'un nouvel arret).
const double kDoublonSeuilMetres = 30;

/// Distance en metres en-dessous de laquelle on reutilise un point
/// du cache geocode plutot que de re-appeler la BAN.
const double kGeocodeCacheSeuilMetres = 50;

/// Timeout pour les appels reseau "rapides" (BAN, geocode).
const Duration kHttpTimeoutShort = Duration(seconds: 15);

/// Timeout pour les appels reseau "longs" (ORS optimization).
const Duration kHttpTimeoutLong = Duration(seconds: 60);

/// Timeout pour les Edge Functions Supabase (Gemini OCR enhance).
const Duration kEdgeFunctionTimeout = Duration(seconds: 5);

/// Seuil variance Laplacien en-dessous duquel une photo est consideree
/// "trop floue" pour donner un OCR fiable.
const double kBlurThresholdLaplacian = 50;

/// Score qualite OCR en-dessous duquel on retente avec rotations
/// 90/180/270. Default fixe par OcrService.qualityScore.
const int kOcrQualityThreshold = 8;

// ════════════════════════════════════════════════════════════════
// Limites
// ════════════════════════════════════════════════════════════════

/// Quota gratuit ORS par jour (limite officielle openrouteservice.org).
const int kOrsDailyQuota = 500;

/// Taille max du carnet d'adresses avant warning "tu as beaucoup
/// d'entrees, pense a archiver les vieilles". Pas un blocage hard.
const int kCarnetWarningSize = 1000;

/// Distance Levenshtein max pour considerer 2 noms client comme
/// "potentiellement identiques" (fuzzy match dans ClientMemoryService).
const int kClientMemoryMaxDistance = 3;

/// Ratio de similarite minimum (0..1) pour matcher 2 noms longs ou
/// la distance absolue peut etre > 3 sans etre une faute OCR.
const double kClientMemoryMinRatio = 0.85;

// ════════════════════════════════════════════════════════════════
// Zone geographique principale de Noah (Eure-et-Loir)
// ════════════════════════════════════════════════════════════════

/// Prefixe CP du departement principal de Noah (28 = Eure-et-Loir).
/// Quand le parser bordereau hesite entre 2 adresses (cas typique
/// MESEXP retour : adresse 28xxx du fournisseur a ramasser VS adresse
/// 72xxx de la destination finale), on prefere celle qui commence par
/// ce prefixe.
///
/// Si Noah change de zone : modifier cette constante. Pour plusieurs
/// departements, voir [kCodePostalPreferes].
const String kCodePostalPrefere = '28';

/// Liste etendue des departements ou Noah livre regulierement, par
/// ordre de preference. Sert au fallback si [kCodePostalPrefere] ne
/// match aucune adresse du bordereau scanne.
/// 28 = Eure-et-Loir (principal), 27 = Eure, 41 = Loir-et-Cher,
/// 72 = Sarthe, 78 = Yvelines, 91 = Essonne.
const List<String> kCodePostalPreferes = ['28', '27', '41', '72', '78', '91'];
