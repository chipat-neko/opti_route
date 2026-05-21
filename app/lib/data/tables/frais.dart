import 'package:drift/drift.dart';

/// Notes de frais : depenses pro liees a l'activite de livraison
/// (carburant, peages, parking, repas, autre).
///
/// Cas d'usage : Noah veut tracker ses depenses pro pour la compta
/// (URSSAF, expert-comptable, declaration fiscale annuelle) ou pour
/// les rembourser quand il bosse pour un donneur d'ordre. Plutot que
/// de garder les tickets papier qui se perdent / decolorent, il les
/// saisit direct dans l'app au moment de la depense.
///
/// 100% local en Phase 1, jamais uploade. Photo justificatif en
/// `app_documents/frais_photos/<id>.jpg` (cf PreuvePhotoService pour
/// le pattern).
///
/// Rattachement optionnel a une tournee : utile pour calculer la marge
/// brute par tournee (revenus - frais), ou pour scinder les depenses
/// commune vs perso (carburant maison vs carburant tournee).
class Frais extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Date de la depense (jour, pas heure precise). Stocke en DateTime
  /// pour faciliter les filtres par mois / annee.
  DateTimeColumn get date => dateTime()();

  /// Type : 'carburant', 'peage', 'parking', 'repas', 'autre'.
  /// String libre (pas un enum Drift) pour permettre l'evolution sans
  /// migration de schema.
  TextColumn get type => text().withLength(min: 1, max: 20)();

  /// Montant en CENTIMES (entier). Evite les imprecisions float
  /// (`15.30` -> `15.299999...`). 1235 = 12,35 EUR.
  IntColumn get montantCentimes => integer()();

  /// Libelle court (ex: "Station Total Luce", "Peage A11 sortie 4").
  /// Max 80 chars pour rester lisible dans la liste sans wrap excessif.
  TextColumn get libelle => text().withLength(min: 1, max: 80)();

  /// Notes complementaires optionnelles (numero de facture, contexte,
  /// "remboursable par client X", etc.).
  TextColumn get notes => text().nullable()();

  /// Rattachement optionnel a une tournee. Null = depense generale
  /// (carburant maison, parking permanent, etc.).
  IntColumn get tourneeId => integer().nullable()();

  /// Chemin local de la photo du justificatif (ticket / facture).
  /// Null si pas de photo. Stocke en
  /// `getApplicationDocumentsDirectory()/frais_photos/<id>.jpg`.
  TextColumn get photoPath => text().nullable()();

  DateTimeColumn get creeLe => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}
