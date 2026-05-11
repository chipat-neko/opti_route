import 'package:drift/drift.dart';

/// Cache local des reponses Nominatim (et plus tard d'autres APIs).
/// Cle = la requete normalisee (ex: "14 rue foo paris").
/// `expire_le` permet d'invalider apres N jours sans avoir a tout
/// purger.
class GeocodeCache extends Table {
  TextColumn get query => text()();
  TextColumn get responseJson => text()();
  DateTimeColumn get expireLe => dateTime()();

  @override
  Set<Column> get primaryKey => {query};
}
