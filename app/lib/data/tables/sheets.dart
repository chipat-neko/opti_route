import 'package:drift/drift.dart';

import 'stops.dart';

/// Une feuille d'expediteur attachee a un arret.
///
/// Cas reel : un livreur peut deposer au meme point des colis venant
/// d'expediteurs differents (Chronopost + La Poste + Colissimo). Chaque
/// expediteur a sa propre ref, son nb de colis, son poids, son contact.
/// Le design `screen-delivery.jsx` montre N feuilles empilees sous une
/// meme adresse client.
class Sheets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get stopId =>
      integer().references(Stops, #id, onDelete: KeyAction.cascade)();
  TextColumn get expediteur => text().withLength(min: 1, max: 100)();
  TextColumn get refCode => text().nullable()();
  TextColumn get nomDestinataire => text().nullable()();
  TextColumn get telephone => text().nullable()();
  IntColumn get nbColis => integer().withDefault(const Constant(1))();
  RealColumn get poidsKg => real().nullable()();
  TextColumn get statut => text().withDefault(const Constant('a_livrer'))();
  TextColumn get raisonEchec => text().nullable()();
  DateTimeColumn get creeLe => dateTime().withDefault(currentDateAndTime)();
}
