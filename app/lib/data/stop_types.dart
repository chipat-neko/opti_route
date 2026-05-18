/// ════════════════════════════════════════════════════════════════
/// Constantes du champ `Stops.type` + helpers d'affichage.
/// ════════════════════════════════════════════════════════════════
///
/// Centralise les valeurs autorisees pour eviter les fautes de frappe
/// "livraision" / "ramassse" etc. dans le code. Voir [Stops.type] dans
/// `lib/data/tables/stops.dart` pour la def schema.
library;

/// Type 'livraison' : on depose un colis chez le destinataire (cas
/// par defaut). Le statut final est `livre` ou `echec`.
const String kStopTypeLivraison = 'livraison';

/// Type 'ramasse' : on recupere un colis chez le client pour le
/// rapporter au depot. Le statut final reste `livre` (= "fait") mais
/// le verbe employe en UI est "ramasse" / "ramassee".
const String kStopTypeRamasse = 'ramasse';

/// Liste exhaustive des types autorises -- sert aux dropdowns /
/// SegmentedButton et a la validation au sauve.
const List<String> kStopTypeValues = [
  kStopTypeLivraison,
  kStopTypeRamasse,
];

/// Verbe d'action present infinitif selon le type. Exemple d'usage :
/// label de bouton "Marquer ${verbInfinitif(type)}".
String stopActionVerbInfinitif(String type) =>
    type == kStopTypeRamasse ? 'ramasse' : 'livre';

/// Verbe au participe passe (feminin/masculin variable selon contexte
/// ex. "colis ramasse" vs "tournee terminee" -- on prend la forme
/// masculin par defaut). "ramasse(e)" / "livre(e)" si besoin du genre
/// dans le texte.
String stopActionVerbParticipe(String type) =>
    type == kStopTypeRamasse ? 'ramasse' : 'livre';

/// Label court pour les tags / chips UI. ALL CAPS car les tags de
/// l'app le sont (cf StopTag).
String stopTypeLabelUpper(String type) =>
    type == kStopTypeRamasse ? 'RAMASSE' : 'LIVRAISON';

/// Label normal (1ere lettre majuscule) pour les SnackBar / dialogs.
String stopTypeLabel(String type) =>
    type == kStopTypeRamasse ? 'Ramasse' : 'Livraison';
