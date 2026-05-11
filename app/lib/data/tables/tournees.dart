import 'package:drift/drift.dart';

class Tournees extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nom => text().withLength(min: 1, max: 100)();
  DateTimeColumn get date => dateTime()();
  RealColumn get pointDepartLat => real()();
  RealColumn get pointDepartLng => real()();
  TextColumn get pointDepartLabel => text()();
  IntColumn get vehiculeCapaciteColis =>
      integer().withDefault(const Constant(0))();
  TextColumn get statut => text().withDefault(const Constant('brouillon'))();
  IntColumn get distanceTotaleM => integer().nullable()();
  IntColumn get dureeTotaleS => integer().nullable()();
  DateTimeColumn get optimiseeLe => dateTime().nullable()();

  /// Trace de l'itineraire optimise au format GeoJSON LineString (juste
  /// la liste des coordonnees [lng, lat] encodee en JSON string), pour
  /// affichage en polyline sur la carte. Nullable : pas tous les
  /// fournisseurs d'optimisation renvoient une trace.
  TextColumn get traceGeojson => text().nullable()();

  /// Timestamp du tap "Demarrer" sur le FAB de la tournee. Sert a
  /// calculer le temps ecoule et l'afficher dans le bandeau "Prochain
  /// arret" / les stats post-tournee. Null si jamais demarre, conserve
  /// meme apres Pause / Terminee (utile pour l'historique).
  DateTimeColumn get demareeLe => dateTime().nullable()();

  /// Marqueur "tournee modele" : si vrai, la tournee apparait dans la
  /// section "Templates" de l'historique avec un bouton "Creer une
  /// nouvelle tournee depuis ce template" qui appelle duplicate().
  /// Sert pour les tournees recurrentes (memes 30 clients chaque
  /// semaine).
  BoolColumn get isTemplate =>
      boolean().withDefault(const Constant(false))();

  /// Timestamp du dernier tap "Pause" non encore repris : non null
  /// uniquement quand la tournee est sur PAUSE en ce moment. La
  /// reprise (tap "Reprendre") remet cette colonne a null et ajoute
  /// (now - pausedAtLast) a `pausedTotalS`. Sert au calcul du temps
  /// ecoule en excluant les pauses.
  DateTimeColumn get pausedAtLast => dateTime().nullable()();

  /// Cumul total des pauses passees (en secondes). Croit a chaque
  /// reprise. Le temps ecoule "actif" d'une tournee demarree est :
  /// (now - demareeLe) - pausedTotalS - (now - pausedAtLast if paused).
  IntColumn get pausedTotalS =>
      integer().withDefault(const Constant(0))();

  DateTimeColumn get creeLe => dateTime().withDefault(currentDateAndTime)();
}
