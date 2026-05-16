import 'package:drift/drift.dart';

/// Carnet local des coequipiers / aidants livraison.
///
/// Cas d'usage : Noah travaille seul la plupart du temps, mais il
/// arrive qu'un collegue ou un membre de famille l'aide sur une
/// tournee (livraisons partagees). On veut alors :
/// - Affecter un arret a une personne (colonne `stops.coequipierId`)
/// - Voir dans la liste qui a livre quoi (badge avatar)
/// - Calculer des stats par personne ("Papa a livre 12 colis ce mois")
///
/// 100% local, jamais uploade, jamais synchronise. Pour le mode equipe
/// vrai (multi-comptes + sync backend), voir la roadmap Phase 2.
class Coequipiers extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Nom court a afficher en badge (ex: "Papa", "Lucas", "Maman").
  /// Max 20 chars pour tenir dans les chips/avatars sans wrap.
  TextColumn get nom => text().withLength(min: 1, max: 20)();

  /// Couleur du tag pour l'avatar (cle dans `colorFromTag` :
  /// 'lime' / 'emerald' / 'amber' / 'red' / 'cream' / 'ink').
  /// Null = couleur par defaut (cream).
  TextColumn get colorTag => text().nullable()();

  /// Telephone (optionnel) pour le partage de tournee via SMS / WhatsApp.
  TextColumn get telephone => text().nullable()();

  /// Vrai = visible dans le selecteur. Faux = archive (ancien aidant
  /// qui ne livre plus avec Noah). On garde l'entree en base pour
  /// preserver l'historique des stats.
  BoolColumn get actif => boolean().withDefault(const Constant(true))();

  DateTimeColumn get creeLe => dateTime().withDefault(currentDateAndTime)();

  /// UUID v4 attribue par l'app au 1er push Supabase (sous-jalon 2.B).
  /// Null = coequipier jamais sync. Voir `Tournees.cloudId` pour le
  /// pattern.
  TextColumn get cloudId => text().nullable()();
}
