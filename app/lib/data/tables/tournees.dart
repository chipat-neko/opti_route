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

  /// Profil OpenRouteService utilise pour le calcul d'itineraire :
  /// - `driving-car` (defaut) : VL classique, prend toutes les routes
  /// - `driving-hgv` : camion lourd > 3.5t, respecte les restrictions
  ///   de hauteur, poids, largeur, interdictions camion et evite les
  ///   centres-ville pietonnises.
  ///
  /// Pour Noah en VUL standard (< 3.5t), `driving-car` est correct.
  /// `driving-hgv` peut etre necessaire pour les transporteurs PL.
  TextColumn get profilOrs =>
      text().withDefault(const Constant('driving-car'))();

  /// Eviter les peages quand on calcule l'itineraire. Ajoute
  /// `options.avoid_features: ['tollways']` aux appels Directions ORS.
  /// Defaut false : pour un livreur urbain les peages sont rares et
  /// l'evitement allonge enormement le trajet.
  BoolColumn get eviterPeages =>
      boolean().withDefault(const Constant(false))();

  /// Date / heure a laquelle une notification locale de rappel doit
  /// se declencher (ex: 6h45 le matin de la tournee pour reveiller
  /// Noah). Null = pas de rappel programme. Stocke en local time, on
  /// le re-zone via flutter_local_notifications a la programmation.
  DateTimeColumn get rappelLe => dateTime().nullable()();

  /// Timestamp du dernier tap "Mettre en pause". Null si jamais paused
  /// ou si actuellement en cours. Sert au calcul du temps reellement
  /// travaille (exclut les pauses).
  DateTimeColumn get pauseeLe => dateTime().nullable()();

  /// Cumul des secondes de pause sur cette tournee. Mis a jour au
  /// "Reprendre" : pauseeSeconds += now - pauseeLe.
  IntColumn get pauseeSeconds =>
      integer().withDefault(const Constant(0))();

  DateTimeColumn get creeLe => dateTime().withDefault(currentDateAndTime)();
}
