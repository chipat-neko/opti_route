import 'package:drift/drift.dart';

import 'tournees.dart';

class Stops extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get tourneeId => integer()
      .references(Tournees, #id, onDelete: KeyAction.cascade)();
  TextColumn get adresseBrute => text()();
  TextColumn get adresseNormalisee => text().nullable()();
  RealColumn get lat => real().nullable()();
  RealColumn get lng => real().nullable()();
  IntColumn get nbColis => integer().withDefault(const Constant(1))();
  TextColumn get priorite => text().withDefault(const Constant('flexible'))();
  TextColumn get fenetreDebut => text().nullable()();
  TextColumn get fenetreFin => text().nullable()();
  IntColumn get dureeArretMin => integer().withDefault(const Constant(3))();
  TextColumn get notes => text().nullable()();
  TextColumn get nomClient => text().nullable()();
  TextColumn get statutLivraison =>
      text().withDefault(const Constant('a_livrer'))();

  /// Raison de l'echec quand `statutLivraison == 'echec'` :
  /// 'absent' / 'refuse' / 'adresse_fausse' / 'autre'. Null sinon.
  TextColumn get raisonEchec => text().nullable()();

  /// Position GPS au moment du "Marquer livre" / "Marquer echec" --
  /// sert de preuve de passage en cas de litige client.
  /// Null si la permission GPS etait refusee ou l'app etait offline.
  RealColumn get livreLat => real().nullable()();
  RealColumn get livreLng => real().nullable()();

  /// Timestamp de la validation (livre OU echec). Sert aussi a calculer
  /// le temps passe sur la tournee a posteriori.
  DateTimeColumn get livreLe => dateTime().nullable()();

  IntColumn get ordreOptimise => integer().nullable()();

  /// Ordre choisi par l'utilisateur **a l'interieur** d'un groupe de
  /// priorite egale (obligatoire_premier ou obligatoire_dernier).
  /// 1 = livre en premier de son groupe, 2 = en deuxieme, etc.
  /// Null = pas applicable (priorite flexible / eviter).
  IntColumn get ordrePriorite => integer().nullable()();

  /// Chemin local (filesystem app) de la photo preuve de livraison.
  /// Null si pas de photo prise. Stockage privé dans
  /// `app_documents/preuves/<stopId>_<timestamp>.jpg`.
  TextColumn get preuvePhotoPath => text().nullable()();

  /// Id du coequipier affecte a cet arret (FK vers `coequipiers.id`).
  /// Null = Noah lui-meme (cas par defaut, pas d'aidant). Pas de
  /// cascade : si on supprime un coequipier, on le retire de l'UI
  /// mais on garde la trace dans les arrets pour l'historique.
  IntColumn get coequipierId => integer().nullable()();

  DateTimeColumn get creeLe => dateTime().withDefault(currentDateAndTime)();

  /// UUID v4 attribue par l'app au 1er push Supabase (sous-jalon 2.B).
  /// Null = stop jamais sync. Voir `Tournees.cloudId` pour le pattern.
  TextColumn get cloudId => text().nullable()();
}
