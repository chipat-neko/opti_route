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

  /// Id du coequipier affecte par defaut pour TOUS les nouveaux stops
  /// crees dans cette tournee (FK vers `coequipiers.id`, nullable).
  /// Sert au chef d'equipe qui prepare une tournee complete pour Lucas :
  /// chaque ajout d'arret prend automatiquement `coequipierId = lucas.id`
  /// sans avoir a le configurer 30x. Modifiable apres coup par stop.
  IntColumn get coequipierDefautId => integer().nullable()();

  DateTimeColumn get creeLe => dateTime().withDefault(currentDateAndTime)();

  /// UUID v4 attribue par l'app au moment du 1er push vers Supabase
  /// (sous-jalon 2.B). Null = jamais synchronisee. Une fois set, sert
  /// de cle de rapprochement pour les UPDATE ulterieurs (idempotence
  /// du push : INSERT si null, UPDATE sinon). Format : UUID standard
  /// 36 chars avec tirets, ex `7c9e6679-7425-40de-944b-e07fc1f90ae7`.
  TextColumn get cloudId => text().nullable()();

  /// Timestamp de la derniere modification locale (sous-jalon 2.D-1c).
  /// Set automatiquement par un trigger SQLite `AFTER UPDATE WHEN
  /// NEW.updated_at = OLD.updated_at` qui se declenche a chaque UPDATE
  /// si le code Dart n'a pas explicitement touche a la colonne.
  /// Default `currentDateAndTime` au INSERT.
  ///
  /// Sert au pull cloud (last-write-wins) : si cloud.updated_at >
  /// local.updated_at, le cloud ecrase ; sinon on skip (local plus
  /// recent ou egal). Plus safe que le cloud-wins strict du 2.D-1a.
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}
