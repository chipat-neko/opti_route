import 'package:drift/drift.dart';

import 'tournees.dart';

class Stops extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get tourneeId => integer()
      .references(Tournees, #id, onDelete: KeyAction.cascade)();
  TextColumn get adresseBrute => text()();
  TextColumn get adresseNormalisee => text().nullable()();

  /// Type d'arret : 'livraison' (defaut, on depose un colis chez le
  /// destinataire) ou 'ramasse' (on recupere un colis chez le client
  /// pour le rapporter au depot). Les ramasses sont comptes separement
  /// dans les stats / facturation (cf [StatsService]) et ont un visuel
  /// distinct dans la liste (icone download + tag orange).
  ///
  /// Use cases ramasse :
  /// - Retour client : Noah doit recuperer un colis chez Mme Dupont
  /// - Enlevement fournisseur : ramener un envoi entrant au depot
  /// - Echange (livre A + ramasse B au meme point) : 2 stops distincts
  TextColumn get type => text().withDefault(const Constant('livraison'))();
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

  /// Chemin dans le bucket Supabase Storage `preuves` ou la photo
  /// preuve de livraison est stockee, format `<user_id>/<stop_uuid>.jpg`
  /// (sous-jalon 2.E). Null = photo jamais uploadee au cloud OU pas de
  /// photo locale (`preuvePhotoPath` null). Set au push apres upload
  /// reussi vers Storage.
  ///
  /// Le download lors d'un pull (au 1er sign-in sur un 2e device) sera
  /// implemente dans un sous-jalon ulterieur — pour le MVP 2.E, on ne
  /// fait que l'upload. Sur un nouveau device, Noah devra re-prendre
  /// les photos preuves (le metier-critique = adresses + statuts,
  /// les photos sont un confort).
  TextColumn get cloudPhotoPath => text().nullable()();

  /// Timestamp de la derniere modification locale (sous-jalon 2.D-1c).
  /// Voir `Tournees.updatedAt` pour le pattern complet (trigger SQLite
  /// + last-write-wins au pull).
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}
