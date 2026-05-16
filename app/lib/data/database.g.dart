// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $TourneesTable extends Tournees with TableInfo<$TourneesTable, Tournee> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TourneesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nomMeta = const VerificationMeta('nom');
  @override
  late final GeneratedColumn<String> nom = GeneratedColumn<String>(
    'nom',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pointDepartLatMeta = const VerificationMeta(
    'pointDepartLat',
  );
  @override
  late final GeneratedColumn<double> pointDepartLat = GeneratedColumn<double>(
    'point_depart_lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pointDepartLngMeta = const VerificationMeta(
    'pointDepartLng',
  );
  @override
  late final GeneratedColumn<double> pointDepartLng = GeneratedColumn<double>(
    'point_depart_lng',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pointDepartLabelMeta = const VerificationMeta(
    'pointDepartLabel',
  );
  @override
  late final GeneratedColumn<String> pointDepartLabel = GeneratedColumn<String>(
    'point_depart_label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vehiculeCapaciteColisMeta =
      const VerificationMeta('vehiculeCapaciteColis');
  @override
  late final GeneratedColumn<int> vehiculeCapaciteColis = GeneratedColumn<int>(
    'vehicule_capacite_colis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statutMeta = const VerificationMeta('statut');
  @override
  late final GeneratedColumn<String> statut = GeneratedColumn<String>(
    'statut',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('brouillon'),
  );
  static const VerificationMeta _distanceTotaleMMeta = const VerificationMeta(
    'distanceTotaleM',
  );
  @override
  late final GeneratedColumn<int> distanceTotaleM = GeneratedColumn<int>(
    'distance_totale_m',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dureeTotaleSMeta = const VerificationMeta(
    'dureeTotaleS',
  );
  @override
  late final GeneratedColumn<int> dureeTotaleS = GeneratedColumn<int>(
    'duree_totale_s',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _optimiseeLeMeta = const VerificationMeta(
    'optimiseeLe',
  );
  @override
  late final GeneratedColumn<DateTime> optimiseeLe = GeneratedColumn<DateTime>(
    'optimisee_le',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _traceGeojsonMeta = const VerificationMeta(
    'traceGeojson',
  );
  @override
  late final GeneratedColumn<String> traceGeojson = GeneratedColumn<String>(
    'trace_geojson',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _demareeLeMeta = const VerificationMeta(
    'demareeLe',
  );
  @override
  late final GeneratedColumn<DateTime> demareeLe = GeneratedColumn<DateTime>(
    'demaree_le',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isTemplateMeta = const VerificationMeta(
    'isTemplate',
  );
  @override
  late final GeneratedColumn<bool> isTemplate = GeneratedColumn<bool>(
    'is_template',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_template" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _profilOrsMeta = const VerificationMeta(
    'profilOrs',
  );
  @override
  late final GeneratedColumn<String> profilOrs = GeneratedColumn<String>(
    'profil_ors',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('driving-car'),
  );
  static const VerificationMeta _eviterPeagesMeta = const VerificationMeta(
    'eviterPeages',
  );
  @override
  late final GeneratedColumn<bool> eviterPeages = GeneratedColumn<bool>(
    'eviter_peages',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("eviter_peages" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _rappelLeMeta = const VerificationMeta(
    'rappelLe',
  );
  @override
  late final GeneratedColumn<DateTime> rappelLe = GeneratedColumn<DateTime>(
    'rappel_le',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pauseeLeMeta = const VerificationMeta(
    'pauseeLe',
  );
  @override
  late final GeneratedColumn<DateTime> pauseeLe = GeneratedColumn<DateTime>(
    'pausee_le',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pauseeSecondsMeta = const VerificationMeta(
    'pauseeSeconds',
  );
  @override
  late final GeneratedColumn<int> pauseeSeconds = GeneratedColumn<int>(
    'pausee_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _coequipierDefautIdMeta =
      const VerificationMeta('coequipierDefautId');
  @override
  late final GeneratedColumn<int> coequipierDefautId = GeneratedColumn<int>(
    'coequipier_defaut_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _creeLeMeta = const VerificationMeta('creeLe');
  @override
  late final GeneratedColumn<DateTime> creeLe = GeneratedColumn<DateTime>(
    'cree_le',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _cloudIdMeta = const VerificationMeta(
    'cloudId',
  );
  @override
  late final GeneratedColumn<String> cloudId = GeneratedColumn<String>(
    'cloud_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nom,
    date,
    pointDepartLat,
    pointDepartLng,
    pointDepartLabel,
    vehiculeCapaciteColis,
    statut,
    distanceTotaleM,
    dureeTotaleS,
    optimiseeLe,
    traceGeojson,
    demareeLe,
    isTemplate,
    profilOrs,
    eviterPeages,
    rappelLe,
    pauseeLe,
    pauseeSeconds,
    coequipierDefautId,
    creeLe,
    cloudId,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tournees';
  @override
  VerificationContext validateIntegrity(
    Insertable<Tournee> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('nom')) {
      context.handle(
        _nomMeta,
        nom.isAcceptableOrUnknown(data['nom']!, _nomMeta),
      );
    } else if (isInserting) {
      context.missing(_nomMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('point_depart_lat')) {
      context.handle(
        _pointDepartLatMeta,
        pointDepartLat.isAcceptableOrUnknown(
          data['point_depart_lat']!,
          _pointDepartLatMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pointDepartLatMeta);
    }
    if (data.containsKey('point_depart_lng')) {
      context.handle(
        _pointDepartLngMeta,
        pointDepartLng.isAcceptableOrUnknown(
          data['point_depart_lng']!,
          _pointDepartLngMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pointDepartLngMeta);
    }
    if (data.containsKey('point_depart_label')) {
      context.handle(
        _pointDepartLabelMeta,
        pointDepartLabel.isAcceptableOrUnknown(
          data['point_depart_label']!,
          _pointDepartLabelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pointDepartLabelMeta);
    }
    if (data.containsKey('vehicule_capacite_colis')) {
      context.handle(
        _vehiculeCapaciteColisMeta,
        vehiculeCapaciteColis.isAcceptableOrUnknown(
          data['vehicule_capacite_colis']!,
          _vehiculeCapaciteColisMeta,
        ),
      );
    }
    if (data.containsKey('statut')) {
      context.handle(
        _statutMeta,
        statut.isAcceptableOrUnknown(data['statut']!, _statutMeta),
      );
    }
    if (data.containsKey('distance_totale_m')) {
      context.handle(
        _distanceTotaleMMeta,
        distanceTotaleM.isAcceptableOrUnknown(
          data['distance_totale_m']!,
          _distanceTotaleMMeta,
        ),
      );
    }
    if (data.containsKey('duree_totale_s')) {
      context.handle(
        _dureeTotaleSMeta,
        dureeTotaleS.isAcceptableOrUnknown(
          data['duree_totale_s']!,
          _dureeTotaleSMeta,
        ),
      );
    }
    if (data.containsKey('optimisee_le')) {
      context.handle(
        _optimiseeLeMeta,
        optimiseeLe.isAcceptableOrUnknown(
          data['optimisee_le']!,
          _optimiseeLeMeta,
        ),
      );
    }
    if (data.containsKey('trace_geojson')) {
      context.handle(
        _traceGeojsonMeta,
        traceGeojson.isAcceptableOrUnknown(
          data['trace_geojson']!,
          _traceGeojsonMeta,
        ),
      );
    }
    if (data.containsKey('demaree_le')) {
      context.handle(
        _demareeLeMeta,
        demareeLe.isAcceptableOrUnknown(data['demaree_le']!, _demareeLeMeta),
      );
    }
    if (data.containsKey('is_template')) {
      context.handle(
        _isTemplateMeta,
        isTemplate.isAcceptableOrUnknown(data['is_template']!, _isTemplateMeta),
      );
    }
    if (data.containsKey('profil_ors')) {
      context.handle(
        _profilOrsMeta,
        profilOrs.isAcceptableOrUnknown(data['profil_ors']!, _profilOrsMeta),
      );
    }
    if (data.containsKey('eviter_peages')) {
      context.handle(
        _eviterPeagesMeta,
        eviterPeages.isAcceptableOrUnknown(
          data['eviter_peages']!,
          _eviterPeagesMeta,
        ),
      );
    }
    if (data.containsKey('rappel_le')) {
      context.handle(
        _rappelLeMeta,
        rappelLe.isAcceptableOrUnknown(data['rappel_le']!, _rappelLeMeta),
      );
    }
    if (data.containsKey('pausee_le')) {
      context.handle(
        _pauseeLeMeta,
        pauseeLe.isAcceptableOrUnknown(data['pausee_le']!, _pauseeLeMeta),
      );
    }
    if (data.containsKey('pausee_seconds')) {
      context.handle(
        _pauseeSecondsMeta,
        pauseeSeconds.isAcceptableOrUnknown(
          data['pausee_seconds']!,
          _pauseeSecondsMeta,
        ),
      );
    }
    if (data.containsKey('coequipier_defaut_id')) {
      context.handle(
        _coequipierDefautIdMeta,
        coequipierDefautId.isAcceptableOrUnknown(
          data['coequipier_defaut_id']!,
          _coequipierDefautIdMeta,
        ),
      );
    }
    if (data.containsKey('cree_le')) {
      context.handle(
        _creeLeMeta,
        creeLe.isAcceptableOrUnknown(data['cree_le']!, _creeLeMeta),
      );
    }
    if (data.containsKey('cloud_id')) {
      context.handle(
        _cloudIdMeta,
        cloudId.isAcceptableOrUnknown(data['cloud_id']!, _cloudIdMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Tournee map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tournee(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      nom: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nom'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      pointDepartLat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}point_depart_lat'],
      )!,
      pointDepartLng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}point_depart_lng'],
      )!,
      pointDepartLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}point_depart_label'],
      )!,
      vehiculeCapaciteColis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}vehicule_capacite_colis'],
      )!,
      statut: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}statut'],
      )!,
      distanceTotaleM: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}distance_totale_m'],
      ),
      dureeTotaleS: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duree_totale_s'],
      ),
      optimiseeLe: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}optimisee_le'],
      ),
      traceGeojson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trace_geojson'],
      ),
      demareeLe: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}demaree_le'],
      ),
      isTemplate: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_template'],
      )!,
      profilOrs: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profil_ors'],
      )!,
      eviterPeages: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}eviter_peages'],
      )!,
      rappelLe: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}rappel_le'],
      ),
      pauseeLe: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}pausee_le'],
      ),
      pauseeSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pausee_seconds'],
      )!,
      coequipierDefautId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}coequipier_defaut_id'],
      ),
      creeLe: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cree_le'],
      )!,
      cloudId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cloud_id'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TourneesTable createAlias(String alias) {
    return $TourneesTable(attachedDatabase, alias);
  }
}

class Tournee extends DataClass implements Insertable<Tournee> {
  final int id;
  final String nom;
  final DateTime date;
  final double pointDepartLat;
  final double pointDepartLng;
  final String pointDepartLabel;
  final int vehiculeCapaciteColis;
  final String statut;
  final int? distanceTotaleM;
  final int? dureeTotaleS;
  final DateTime? optimiseeLe;

  /// Trace de l'itineraire optimise au format GeoJSON LineString (juste
  /// la liste des coordonnees [lng, lat] encodee en JSON string), pour
  /// affichage en polyline sur la carte. Nullable : pas tous les
  /// fournisseurs d'optimisation renvoient une trace.
  final String? traceGeojson;

  /// Timestamp du tap "Demarrer" sur le FAB de la tournee. Sert a
  /// calculer le temps ecoule et l'afficher dans le bandeau "Prochain
  /// arret" / les stats post-tournee. Null si jamais demarre, conserve
  /// meme apres Pause / Terminee (utile pour l'historique).
  final DateTime? demareeLe;

  /// Marqueur "tournee modele" : si vrai, la tournee apparait dans la
  /// section "Templates" de l'historique avec un bouton "Creer une
  /// nouvelle tournee depuis ce template" qui appelle duplicate().
  /// Sert pour les tournees recurrentes (memes 30 clients chaque
  /// semaine).
  final bool isTemplate;

  /// Profil OpenRouteService utilise pour le calcul d'itineraire :
  /// - `driving-car` (defaut) : VL classique, prend toutes les routes
  /// - `driving-hgv` : camion lourd > 3.5t, respecte les restrictions
  ///   de hauteur, poids, largeur, interdictions camion et evite les
  ///   centres-ville pietonnises.
  ///
  /// Pour Noah en VUL standard (< 3.5t), `driving-car` est correct.
  /// `driving-hgv` peut etre necessaire pour les transporteurs PL.
  final String profilOrs;

  /// Eviter les peages quand on calcule l'itineraire. Ajoute
  /// `options.avoid_features: ['tollways']` aux appels Directions ORS.
  /// Defaut false : pour un livreur urbain les peages sont rares et
  /// l'evitement allonge enormement le trajet.
  final bool eviterPeages;

  /// Date / heure a laquelle une notification locale de rappel doit
  /// se declencher (ex: 6h45 le matin de la tournee pour reveiller
  /// Noah). Null = pas de rappel programme. Stocke en local time, on
  /// le re-zone via flutter_local_notifications a la programmation.
  final DateTime? rappelLe;

  /// Timestamp du dernier tap "Mettre en pause". Null si jamais paused
  /// ou si actuellement en cours. Sert au calcul du temps reellement
  /// travaille (exclut les pauses).
  final DateTime? pauseeLe;

  /// Cumul des secondes de pause sur cette tournee. Mis a jour au
  /// "Reprendre" : pauseeSeconds += now - pauseeLe.
  final int pauseeSeconds;

  /// Id du coequipier affecte par defaut pour TOUS les nouveaux stops
  /// crees dans cette tournee (FK vers `coequipiers.id`, nullable).
  /// Sert au chef d'equipe qui prepare une tournee complete pour Lucas :
  /// chaque ajout d'arret prend automatiquement `coequipierId = lucas.id`
  /// sans avoir a le configurer 30x. Modifiable apres coup par stop.
  final int? coequipierDefautId;
  final DateTime creeLe;

  /// UUID v4 attribue par l'app au moment du 1er push vers Supabase
  /// (sous-jalon 2.B). Null = jamais synchronisee. Une fois set, sert
  /// de cle de rapprochement pour les UPDATE ulterieurs (idempotence
  /// du push : INSERT si null, UPDATE sinon). Format : UUID standard
  /// 36 chars avec tirets, ex `7c9e6679-7425-40de-944b-e07fc1f90ae7`.
  final String? cloudId;

  /// Timestamp de la derniere modification locale (sous-jalon 2.D-1c).
  /// Set automatiquement par un trigger SQLite `AFTER UPDATE WHEN
  /// NEW.updated_at = OLD.updated_at` qui se declenche a chaque UPDATE
  /// si le code Dart n'a pas explicitement touche a la colonne.
  /// Default `currentDateAndTime` au INSERT.
  ///
  /// Sert au pull cloud (last-write-wins) : si cloud.updated_at >
  /// local.updated_at, le cloud ecrase ; sinon on skip (local plus
  /// recent ou egal). Plus safe que le cloud-wins strict du 2.D-1a.
  final DateTime updatedAt;
  const Tournee({
    required this.id,
    required this.nom,
    required this.date,
    required this.pointDepartLat,
    required this.pointDepartLng,
    required this.pointDepartLabel,
    required this.vehiculeCapaciteColis,
    required this.statut,
    this.distanceTotaleM,
    this.dureeTotaleS,
    this.optimiseeLe,
    this.traceGeojson,
    this.demareeLe,
    required this.isTemplate,
    required this.profilOrs,
    required this.eviterPeages,
    this.rappelLe,
    this.pauseeLe,
    required this.pauseeSeconds,
    this.coequipierDefautId,
    required this.creeLe,
    this.cloudId,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['nom'] = Variable<String>(nom);
    map['date'] = Variable<DateTime>(date);
    map['point_depart_lat'] = Variable<double>(pointDepartLat);
    map['point_depart_lng'] = Variable<double>(pointDepartLng);
    map['point_depart_label'] = Variable<String>(pointDepartLabel);
    map['vehicule_capacite_colis'] = Variable<int>(vehiculeCapaciteColis);
    map['statut'] = Variable<String>(statut);
    if (!nullToAbsent || distanceTotaleM != null) {
      map['distance_totale_m'] = Variable<int>(distanceTotaleM);
    }
    if (!nullToAbsent || dureeTotaleS != null) {
      map['duree_totale_s'] = Variable<int>(dureeTotaleS);
    }
    if (!nullToAbsent || optimiseeLe != null) {
      map['optimisee_le'] = Variable<DateTime>(optimiseeLe);
    }
    if (!nullToAbsent || traceGeojson != null) {
      map['trace_geojson'] = Variable<String>(traceGeojson);
    }
    if (!nullToAbsent || demareeLe != null) {
      map['demaree_le'] = Variable<DateTime>(demareeLe);
    }
    map['is_template'] = Variable<bool>(isTemplate);
    map['profil_ors'] = Variable<String>(profilOrs);
    map['eviter_peages'] = Variable<bool>(eviterPeages);
    if (!nullToAbsent || rappelLe != null) {
      map['rappel_le'] = Variable<DateTime>(rappelLe);
    }
    if (!nullToAbsent || pauseeLe != null) {
      map['pausee_le'] = Variable<DateTime>(pauseeLe);
    }
    map['pausee_seconds'] = Variable<int>(pauseeSeconds);
    if (!nullToAbsent || coequipierDefautId != null) {
      map['coequipier_defaut_id'] = Variable<int>(coequipierDefautId);
    }
    map['cree_le'] = Variable<DateTime>(creeLe);
    if (!nullToAbsent || cloudId != null) {
      map['cloud_id'] = Variable<String>(cloudId);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TourneesCompanion toCompanion(bool nullToAbsent) {
    return TourneesCompanion(
      id: Value(id),
      nom: Value(nom),
      date: Value(date),
      pointDepartLat: Value(pointDepartLat),
      pointDepartLng: Value(pointDepartLng),
      pointDepartLabel: Value(pointDepartLabel),
      vehiculeCapaciteColis: Value(vehiculeCapaciteColis),
      statut: Value(statut),
      distanceTotaleM: distanceTotaleM == null && nullToAbsent
          ? const Value.absent()
          : Value(distanceTotaleM),
      dureeTotaleS: dureeTotaleS == null && nullToAbsent
          ? const Value.absent()
          : Value(dureeTotaleS),
      optimiseeLe: optimiseeLe == null && nullToAbsent
          ? const Value.absent()
          : Value(optimiseeLe),
      traceGeojson: traceGeojson == null && nullToAbsent
          ? const Value.absent()
          : Value(traceGeojson),
      demareeLe: demareeLe == null && nullToAbsent
          ? const Value.absent()
          : Value(demareeLe),
      isTemplate: Value(isTemplate),
      profilOrs: Value(profilOrs),
      eviterPeages: Value(eviterPeages),
      rappelLe: rappelLe == null && nullToAbsent
          ? const Value.absent()
          : Value(rappelLe),
      pauseeLe: pauseeLe == null && nullToAbsent
          ? const Value.absent()
          : Value(pauseeLe),
      pauseeSeconds: Value(pauseeSeconds),
      coequipierDefautId: coequipierDefautId == null && nullToAbsent
          ? const Value.absent()
          : Value(coequipierDefautId),
      creeLe: Value(creeLe),
      cloudId: cloudId == null && nullToAbsent
          ? const Value.absent()
          : Value(cloudId),
      updatedAt: Value(updatedAt),
    );
  }

  factory Tournee.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tournee(
      id: serializer.fromJson<int>(json['id']),
      nom: serializer.fromJson<String>(json['nom']),
      date: serializer.fromJson<DateTime>(json['date']),
      pointDepartLat: serializer.fromJson<double>(json['pointDepartLat']),
      pointDepartLng: serializer.fromJson<double>(json['pointDepartLng']),
      pointDepartLabel: serializer.fromJson<String>(json['pointDepartLabel']),
      vehiculeCapaciteColis: serializer.fromJson<int>(
        json['vehiculeCapaciteColis'],
      ),
      statut: serializer.fromJson<String>(json['statut']),
      distanceTotaleM: serializer.fromJson<int?>(json['distanceTotaleM']),
      dureeTotaleS: serializer.fromJson<int?>(json['dureeTotaleS']),
      optimiseeLe: serializer.fromJson<DateTime?>(json['optimiseeLe']),
      traceGeojson: serializer.fromJson<String?>(json['traceGeojson']),
      demareeLe: serializer.fromJson<DateTime?>(json['demareeLe']),
      isTemplate: serializer.fromJson<bool>(json['isTemplate']),
      profilOrs: serializer.fromJson<String>(json['profilOrs']),
      eviterPeages: serializer.fromJson<bool>(json['eviterPeages']),
      rappelLe: serializer.fromJson<DateTime?>(json['rappelLe']),
      pauseeLe: serializer.fromJson<DateTime?>(json['pauseeLe']),
      pauseeSeconds: serializer.fromJson<int>(json['pauseeSeconds']),
      coequipierDefautId: serializer.fromJson<int?>(json['coequipierDefautId']),
      creeLe: serializer.fromJson<DateTime>(json['creeLe']),
      cloudId: serializer.fromJson<String?>(json['cloudId']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nom': serializer.toJson<String>(nom),
      'date': serializer.toJson<DateTime>(date),
      'pointDepartLat': serializer.toJson<double>(pointDepartLat),
      'pointDepartLng': serializer.toJson<double>(pointDepartLng),
      'pointDepartLabel': serializer.toJson<String>(pointDepartLabel),
      'vehiculeCapaciteColis': serializer.toJson<int>(vehiculeCapaciteColis),
      'statut': serializer.toJson<String>(statut),
      'distanceTotaleM': serializer.toJson<int?>(distanceTotaleM),
      'dureeTotaleS': serializer.toJson<int?>(dureeTotaleS),
      'optimiseeLe': serializer.toJson<DateTime?>(optimiseeLe),
      'traceGeojson': serializer.toJson<String?>(traceGeojson),
      'demareeLe': serializer.toJson<DateTime?>(demareeLe),
      'isTemplate': serializer.toJson<bool>(isTemplate),
      'profilOrs': serializer.toJson<String>(profilOrs),
      'eviterPeages': serializer.toJson<bool>(eviterPeages),
      'rappelLe': serializer.toJson<DateTime?>(rappelLe),
      'pauseeLe': serializer.toJson<DateTime?>(pauseeLe),
      'pauseeSeconds': serializer.toJson<int>(pauseeSeconds),
      'coequipierDefautId': serializer.toJson<int?>(coequipierDefautId),
      'creeLe': serializer.toJson<DateTime>(creeLe),
      'cloudId': serializer.toJson<String?>(cloudId),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Tournee copyWith({
    int? id,
    String? nom,
    DateTime? date,
    double? pointDepartLat,
    double? pointDepartLng,
    String? pointDepartLabel,
    int? vehiculeCapaciteColis,
    String? statut,
    Value<int?> distanceTotaleM = const Value.absent(),
    Value<int?> dureeTotaleS = const Value.absent(),
    Value<DateTime?> optimiseeLe = const Value.absent(),
    Value<String?> traceGeojson = const Value.absent(),
    Value<DateTime?> demareeLe = const Value.absent(),
    bool? isTemplate,
    String? profilOrs,
    bool? eviterPeages,
    Value<DateTime?> rappelLe = const Value.absent(),
    Value<DateTime?> pauseeLe = const Value.absent(),
    int? pauseeSeconds,
    Value<int?> coequipierDefautId = const Value.absent(),
    DateTime? creeLe,
    Value<String?> cloudId = const Value.absent(),
    DateTime? updatedAt,
  }) => Tournee(
    id: id ?? this.id,
    nom: nom ?? this.nom,
    date: date ?? this.date,
    pointDepartLat: pointDepartLat ?? this.pointDepartLat,
    pointDepartLng: pointDepartLng ?? this.pointDepartLng,
    pointDepartLabel: pointDepartLabel ?? this.pointDepartLabel,
    vehiculeCapaciteColis: vehiculeCapaciteColis ?? this.vehiculeCapaciteColis,
    statut: statut ?? this.statut,
    distanceTotaleM: distanceTotaleM.present
        ? distanceTotaleM.value
        : this.distanceTotaleM,
    dureeTotaleS: dureeTotaleS.present ? dureeTotaleS.value : this.dureeTotaleS,
    optimiseeLe: optimiseeLe.present ? optimiseeLe.value : this.optimiseeLe,
    traceGeojson: traceGeojson.present ? traceGeojson.value : this.traceGeojson,
    demareeLe: demareeLe.present ? demareeLe.value : this.demareeLe,
    isTemplate: isTemplate ?? this.isTemplate,
    profilOrs: profilOrs ?? this.profilOrs,
    eviterPeages: eviterPeages ?? this.eviterPeages,
    rappelLe: rappelLe.present ? rappelLe.value : this.rappelLe,
    pauseeLe: pauseeLe.present ? pauseeLe.value : this.pauseeLe,
    pauseeSeconds: pauseeSeconds ?? this.pauseeSeconds,
    coequipierDefautId: coequipierDefautId.present
        ? coequipierDefautId.value
        : this.coequipierDefautId,
    creeLe: creeLe ?? this.creeLe,
    cloudId: cloudId.present ? cloudId.value : this.cloudId,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Tournee copyWithCompanion(TourneesCompanion data) {
    return Tournee(
      id: data.id.present ? data.id.value : this.id,
      nom: data.nom.present ? data.nom.value : this.nom,
      date: data.date.present ? data.date.value : this.date,
      pointDepartLat: data.pointDepartLat.present
          ? data.pointDepartLat.value
          : this.pointDepartLat,
      pointDepartLng: data.pointDepartLng.present
          ? data.pointDepartLng.value
          : this.pointDepartLng,
      pointDepartLabel: data.pointDepartLabel.present
          ? data.pointDepartLabel.value
          : this.pointDepartLabel,
      vehiculeCapaciteColis: data.vehiculeCapaciteColis.present
          ? data.vehiculeCapaciteColis.value
          : this.vehiculeCapaciteColis,
      statut: data.statut.present ? data.statut.value : this.statut,
      distanceTotaleM: data.distanceTotaleM.present
          ? data.distanceTotaleM.value
          : this.distanceTotaleM,
      dureeTotaleS: data.dureeTotaleS.present
          ? data.dureeTotaleS.value
          : this.dureeTotaleS,
      optimiseeLe: data.optimiseeLe.present
          ? data.optimiseeLe.value
          : this.optimiseeLe,
      traceGeojson: data.traceGeojson.present
          ? data.traceGeojson.value
          : this.traceGeojson,
      demareeLe: data.demareeLe.present ? data.demareeLe.value : this.demareeLe,
      isTemplate: data.isTemplate.present
          ? data.isTemplate.value
          : this.isTemplate,
      profilOrs: data.profilOrs.present ? data.profilOrs.value : this.profilOrs,
      eviterPeages: data.eviterPeages.present
          ? data.eviterPeages.value
          : this.eviterPeages,
      rappelLe: data.rappelLe.present ? data.rappelLe.value : this.rappelLe,
      pauseeLe: data.pauseeLe.present ? data.pauseeLe.value : this.pauseeLe,
      pauseeSeconds: data.pauseeSeconds.present
          ? data.pauseeSeconds.value
          : this.pauseeSeconds,
      coequipierDefautId: data.coequipierDefautId.present
          ? data.coequipierDefautId.value
          : this.coequipierDefautId,
      creeLe: data.creeLe.present ? data.creeLe.value : this.creeLe,
      cloudId: data.cloudId.present ? data.cloudId.value : this.cloudId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tournee(')
          ..write('id: $id, ')
          ..write('nom: $nom, ')
          ..write('date: $date, ')
          ..write('pointDepartLat: $pointDepartLat, ')
          ..write('pointDepartLng: $pointDepartLng, ')
          ..write('pointDepartLabel: $pointDepartLabel, ')
          ..write('vehiculeCapaciteColis: $vehiculeCapaciteColis, ')
          ..write('statut: $statut, ')
          ..write('distanceTotaleM: $distanceTotaleM, ')
          ..write('dureeTotaleS: $dureeTotaleS, ')
          ..write('optimiseeLe: $optimiseeLe, ')
          ..write('traceGeojson: $traceGeojson, ')
          ..write('demareeLe: $demareeLe, ')
          ..write('isTemplate: $isTemplate, ')
          ..write('profilOrs: $profilOrs, ')
          ..write('eviterPeages: $eviterPeages, ')
          ..write('rappelLe: $rappelLe, ')
          ..write('pauseeLe: $pauseeLe, ')
          ..write('pauseeSeconds: $pauseeSeconds, ')
          ..write('coequipierDefautId: $coequipierDefautId, ')
          ..write('creeLe: $creeLe, ')
          ..write('cloudId: $cloudId, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    nom,
    date,
    pointDepartLat,
    pointDepartLng,
    pointDepartLabel,
    vehiculeCapaciteColis,
    statut,
    distanceTotaleM,
    dureeTotaleS,
    optimiseeLe,
    traceGeojson,
    demareeLe,
    isTemplate,
    profilOrs,
    eviterPeages,
    rappelLe,
    pauseeLe,
    pauseeSeconds,
    coequipierDefautId,
    creeLe,
    cloudId,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tournee &&
          other.id == this.id &&
          other.nom == this.nom &&
          other.date == this.date &&
          other.pointDepartLat == this.pointDepartLat &&
          other.pointDepartLng == this.pointDepartLng &&
          other.pointDepartLabel == this.pointDepartLabel &&
          other.vehiculeCapaciteColis == this.vehiculeCapaciteColis &&
          other.statut == this.statut &&
          other.distanceTotaleM == this.distanceTotaleM &&
          other.dureeTotaleS == this.dureeTotaleS &&
          other.optimiseeLe == this.optimiseeLe &&
          other.traceGeojson == this.traceGeojson &&
          other.demareeLe == this.demareeLe &&
          other.isTemplate == this.isTemplate &&
          other.profilOrs == this.profilOrs &&
          other.eviterPeages == this.eviterPeages &&
          other.rappelLe == this.rappelLe &&
          other.pauseeLe == this.pauseeLe &&
          other.pauseeSeconds == this.pauseeSeconds &&
          other.coequipierDefautId == this.coequipierDefautId &&
          other.creeLe == this.creeLe &&
          other.cloudId == this.cloudId &&
          other.updatedAt == this.updatedAt);
}

class TourneesCompanion extends UpdateCompanion<Tournee> {
  final Value<int> id;
  final Value<String> nom;
  final Value<DateTime> date;
  final Value<double> pointDepartLat;
  final Value<double> pointDepartLng;
  final Value<String> pointDepartLabel;
  final Value<int> vehiculeCapaciteColis;
  final Value<String> statut;
  final Value<int?> distanceTotaleM;
  final Value<int?> dureeTotaleS;
  final Value<DateTime?> optimiseeLe;
  final Value<String?> traceGeojson;
  final Value<DateTime?> demareeLe;
  final Value<bool> isTemplate;
  final Value<String> profilOrs;
  final Value<bool> eviterPeages;
  final Value<DateTime?> rappelLe;
  final Value<DateTime?> pauseeLe;
  final Value<int> pauseeSeconds;
  final Value<int?> coequipierDefautId;
  final Value<DateTime> creeLe;
  final Value<String?> cloudId;
  final Value<DateTime> updatedAt;
  const TourneesCompanion({
    this.id = const Value.absent(),
    this.nom = const Value.absent(),
    this.date = const Value.absent(),
    this.pointDepartLat = const Value.absent(),
    this.pointDepartLng = const Value.absent(),
    this.pointDepartLabel = const Value.absent(),
    this.vehiculeCapaciteColis = const Value.absent(),
    this.statut = const Value.absent(),
    this.distanceTotaleM = const Value.absent(),
    this.dureeTotaleS = const Value.absent(),
    this.optimiseeLe = const Value.absent(),
    this.traceGeojson = const Value.absent(),
    this.demareeLe = const Value.absent(),
    this.isTemplate = const Value.absent(),
    this.profilOrs = const Value.absent(),
    this.eviterPeages = const Value.absent(),
    this.rappelLe = const Value.absent(),
    this.pauseeLe = const Value.absent(),
    this.pauseeSeconds = const Value.absent(),
    this.coequipierDefautId = const Value.absent(),
    this.creeLe = const Value.absent(),
    this.cloudId = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  TourneesCompanion.insert({
    this.id = const Value.absent(),
    required String nom,
    required DateTime date,
    required double pointDepartLat,
    required double pointDepartLng,
    required String pointDepartLabel,
    this.vehiculeCapaciteColis = const Value.absent(),
    this.statut = const Value.absent(),
    this.distanceTotaleM = const Value.absent(),
    this.dureeTotaleS = const Value.absent(),
    this.optimiseeLe = const Value.absent(),
    this.traceGeojson = const Value.absent(),
    this.demareeLe = const Value.absent(),
    this.isTemplate = const Value.absent(),
    this.profilOrs = const Value.absent(),
    this.eviterPeages = const Value.absent(),
    this.rappelLe = const Value.absent(),
    this.pauseeLe = const Value.absent(),
    this.pauseeSeconds = const Value.absent(),
    this.coequipierDefautId = const Value.absent(),
    this.creeLe = const Value.absent(),
    this.cloudId = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : nom = Value(nom),
       date = Value(date),
       pointDepartLat = Value(pointDepartLat),
       pointDepartLng = Value(pointDepartLng),
       pointDepartLabel = Value(pointDepartLabel);
  static Insertable<Tournee> custom({
    Expression<int>? id,
    Expression<String>? nom,
    Expression<DateTime>? date,
    Expression<double>? pointDepartLat,
    Expression<double>? pointDepartLng,
    Expression<String>? pointDepartLabel,
    Expression<int>? vehiculeCapaciteColis,
    Expression<String>? statut,
    Expression<int>? distanceTotaleM,
    Expression<int>? dureeTotaleS,
    Expression<DateTime>? optimiseeLe,
    Expression<String>? traceGeojson,
    Expression<DateTime>? demareeLe,
    Expression<bool>? isTemplate,
    Expression<String>? profilOrs,
    Expression<bool>? eviterPeages,
    Expression<DateTime>? rappelLe,
    Expression<DateTime>? pauseeLe,
    Expression<int>? pauseeSeconds,
    Expression<int>? coequipierDefautId,
    Expression<DateTime>? creeLe,
    Expression<String>? cloudId,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nom != null) 'nom': nom,
      if (date != null) 'date': date,
      if (pointDepartLat != null) 'point_depart_lat': pointDepartLat,
      if (pointDepartLng != null) 'point_depart_lng': pointDepartLng,
      if (pointDepartLabel != null) 'point_depart_label': pointDepartLabel,
      if (vehiculeCapaciteColis != null)
        'vehicule_capacite_colis': vehiculeCapaciteColis,
      if (statut != null) 'statut': statut,
      if (distanceTotaleM != null) 'distance_totale_m': distanceTotaleM,
      if (dureeTotaleS != null) 'duree_totale_s': dureeTotaleS,
      if (optimiseeLe != null) 'optimisee_le': optimiseeLe,
      if (traceGeojson != null) 'trace_geojson': traceGeojson,
      if (demareeLe != null) 'demaree_le': demareeLe,
      if (isTemplate != null) 'is_template': isTemplate,
      if (profilOrs != null) 'profil_ors': profilOrs,
      if (eviterPeages != null) 'eviter_peages': eviterPeages,
      if (rappelLe != null) 'rappel_le': rappelLe,
      if (pauseeLe != null) 'pausee_le': pauseeLe,
      if (pauseeSeconds != null) 'pausee_seconds': pauseeSeconds,
      if (coequipierDefautId != null)
        'coequipier_defaut_id': coequipierDefautId,
      if (creeLe != null) 'cree_le': creeLe,
      if (cloudId != null) 'cloud_id': cloudId,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  TourneesCompanion copyWith({
    Value<int>? id,
    Value<String>? nom,
    Value<DateTime>? date,
    Value<double>? pointDepartLat,
    Value<double>? pointDepartLng,
    Value<String>? pointDepartLabel,
    Value<int>? vehiculeCapaciteColis,
    Value<String>? statut,
    Value<int?>? distanceTotaleM,
    Value<int?>? dureeTotaleS,
    Value<DateTime?>? optimiseeLe,
    Value<String?>? traceGeojson,
    Value<DateTime?>? demareeLe,
    Value<bool>? isTemplate,
    Value<String>? profilOrs,
    Value<bool>? eviterPeages,
    Value<DateTime?>? rappelLe,
    Value<DateTime?>? pauseeLe,
    Value<int>? pauseeSeconds,
    Value<int?>? coequipierDefautId,
    Value<DateTime>? creeLe,
    Value<String?>? cloudId,
    Value<DateTime>? updatedAt,
  }) {
    return TourneesCompanion(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      date: date ?? this.date,
      pointDepartLat: pointDepartLat ?? this.pointDepartLat,
      pointDepartLng: pointDepartLng ?? this.pointDepartLng,
      pointDepartLabel: pointDepartLabel ?? this.pointDepartLabel,
      vehiculeCapaciteColis:
          vehiculeCapaciteColis ?? this.vehiculeCapaciteColis,
      statut: statut ?? this.statut,
      distanceTotaleM: distanceTotaleM ?? this.distanceTotaleM,
      dureeTotaleS: dureeTotaleS ?? this.dureeTotaleS,
      optimiseeLe: optimiseeLe ?? this.optimiseeLe,
      traceGeojson: traceGeojson ?? this.traceGeojson,
      demareeLe: demareeLe ?? this.demareeLe,
      isTemplate: isTemplate ?? this.isTemplate,
      profilOrs: profilOrs ?? this.profilOrs,
      eviterPeages: eviterPeages ?? this.eviterPeages,
      rappelLe: rappelLe ?? this.rappelLe,
      pauseeLe: pauseeLe ?? this.pauseeLe,
      pauseeSeconds: pauseeSeconds ?? this.pauseeSeconds,
      coequipierDefautId: coequipierDefautId ?? this.coequipierDefautId,
      creeLe: creeLe ?? this.creeLe,
      cloudId: cloudId ?? this.cloudId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nom.present) {
      map['nom'] = Variable<String>(nom.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (pointDepartLat.present) {
      map['point_depart_lat'] = Variable<double>(pointDepartLat.value);
    }
    if (pointDepartLng.present) {
      map['point_depart_lng'] = Variable<double>(pointDepartLng.value);
    }
    if (pointDepartLabel.present) {
      map['point_depart_label'] = Variable<String>(pointDepartLabel.value);
    }
    if (vehiculeCapaciteColis.present) {
      map['vehicule_capacite_colis'] = Variable<int>(
        vehiculeCapaciteColis.value,
      );
    }
    if (statut.present) {
      map['statut'] = Variable<String>(statut.value);
    }
    if (distanceTotaleM.present) {
      map['distance_totale_m'] = Variable<int>(distanceTotaleM.value);
    }
    if (dureeTotaleS.present) {
      map['duree_totale_s'] = Variable<int>(dureeTotaleS.value);
    }
    if (optimiseeLe.present) {
      map['optimisee_le'] = Variable<DateTime>(optimiseeLe.value);
    }
    if (traceGeojson.present) {
      map['trace_geojson'] = Variable<String>(traceGeojson.value);
    }
    if (demareeLe.present) {
      map['demaree_le'] = Variable<DateTime>(demareeLe.value);
    }
    if (isTemplate.present) {
      map['is_template'] = Variable<bool>(isTemplate.value);
    }
    if (profilOrs.present) {
      map['profil_ors'] = Variable<String>(profilOrs.value);
    }
    if (eviterPeages.present) {
      map['eviter_peages'] = Variable<bool>(eviterPeages.value);
    }
    if (rappelLe.present) {
      map['rappel_le'] = Variable<DateTime>(rappelLe.value);
    }
    if (pauseeLe.present) {
      map['pausee_le'] = Variable<DateTime>(pauseeLe.value);
    }
    if (pauseeSeconds.present) {
      map['pausee_seconds'] = Variable<int>(pauseeSeconds.value);
    }
    if (coequipierDefautId.present) {
      map['coequipier_defaut_id'] = Variable<int>(coequipierDefautId.value);
    }
    if (creeLe.present) {
      map['cree_le'] = Variable<DateTime>(creeLe.value);
    }
    if (cloudId.present) {
      map['cloud_id'] = Variable<String>(cloudId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TourneesCompanion(')
          ..write('id: $id, ')
          ..write('nom: $nom, ')
          ..write('date: $date, ')
          ..write('pointDepartLat: $pointDepartLat, ')
          ..write('pointDepartLng: $pointDepartLng, ')
          ..write('pointDepartLabel: $pointDepartLabel, ')
          ..write('vehiculeCapaciteColis: $vehiculeCapaciteColis, ')
          ..write('statut: $statut, ')
          ..write('distanceTotaleM: $distanceTotaleM, ')
          ..write('dureeTotaleS: $dureeTotaleS, ')
          ..write('optimiseeLe: $optimiseeLe, ')
          ..write('traceGeojson: $traceGeojson, ')
          ..write('demareeLe: $demareeLe, ')
          ..write('isTemplate: $isTemplate, ')
          ..write('profilOrs: $profilOrs, ')
          ..write('eviterPeages: $eviterPeages, ')
          ..write('rappelLe: $rappelLe, ')
          ..write('pauseeLe: $pauseeLe, ')
          ..write('pauseeSeconds: $pauseeSeconds, ')
          ..write('coequipierDefautId: $coequipierDefautId, ')
          ..write('creeLe: $creeLe, ')
          ..write('cloudId: $cloudId, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $StopsTable extends Stops with TableInfo<$StopsTable, Stop> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StopsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _tourneeIdMeta = const VerificationMeta(
    'tourneeId',
  );
  @override
  late final GeneratedColumn<int> tourneeId = GeneratedColumn<int>(
    'tournee_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tournees (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _adresseBruteMeta = const VerificationMeta(
    'adresseBrute',
  );
  @override
  late final GeneratedColumn<String> adresseBrute = GeneratedColumn<String>(
    'adresse_brute',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _adresseNormaliseeMeta = const VerificationMeta(
    'adresseNormalisee',
  );
  @override
  late final GeneratedColumn<String> adresseNormalisee =
      GeneratedColumn<String>(
        'adresse_normalisee',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lngMeta = const VerificationMeta('lng');
  @override
  late final GeneratedColumn<double> lng = GeneratedColumn<double>(
    'lng',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nbColisMeta = const VerificationMeta(
    'nbColis',
  );
  @override
  late final GeneratedColumn<int> nbColis = GeneratedColumn<int>(
    'nb_colis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _prioriteMeta = const VerificationMeta(
    'priorite',
  );
  @override
  late final GeneratedColumn<String> priorite = GeneratedColumn<String>(
    'priorite',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('flexible'),
  );
  static const VerificationMeta _fenetreDebutMeta = const VerificationMeta(
    'fenetreDebut',
  );
  @override
  late final GeneratedColumn<String> fenetreDebut = GeneratedColumn<String>(
    'fenetre_debut',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fenetreFinMeta = const VerificationMeta(
    'fenetreFin',
  );
  @override
  late final GeneratedColumn<String> fenetreFin = GeneratedColumn<String>(
    'fenetre_fin',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dureeArretMinMeta = const VerificationMeta(
    'dureeArretMin',
  );
  @override
  late final GeneratedColumn<int> dureeArretMin = GeneratedColumn<int>(
    'duree_arret_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(3),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nomClientMeta = const VerificationMeta(
    'nomClient',
  );
  @override
  late final GeneratedColumn<String> nomClient = GeneratedColumn<String>(
    'nom_client',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statutLivraisonMeta = const VerificationMeta(
    'statutLivraison',
  );
  @override
  late final GeneratedColumn<String> statutLivraison = GeneratedColumn<String>(
    'statut_livraison',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('a_livrer'),
  );
  static const VerificationMeta _raisonEchecMeta = const VerificationMeta(
    'raisonEchec',
  );
  @override
  late final GeneratedColumn<String> raisonEchec = GeneratedColumn<String>(
    'raison_echec',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _livreLatMeta = const VerificationMeta(
    'livreLat',
  );
  @override
  late final GeneratedColumn<double> livreLat = GeneratedColumn<double>(
    'livre_lat',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _livreLngMeta = const VerificationMeta(
    'livreLng',
  );
  @override
  late final GeneratedColumn<double> livreLng = GeneratedColumn<double>(
    'livre_lng',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _livreLeMeta = const VerificationMeta(
    'livreLe',
  );
  @override
  late final GeneratedColumn<DateTime> livreLe = GeneratedColumn<DateTime>(
    'livre_le',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ordreOptimiseMeta = const VerificationMeta(
    'ordreOptimise',
  );
  @override
  late final GeneratedColumn<int> ordreOptimise = GeneratedColumn<int>(
    'ordre_optimise',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ordrePrioriteMeta = const VerificationMeta(
    'ordrePriorite',
  );
  @override
  late final GeneratedColumn<int> ordrePriorite = GeneratedColumn<int>(
    'ordre_priorite',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _preuvePhotoPathMeta = const VerificationMeta(
    'preuvePhotoPath',
  );
  @override
  late final GeneratedColumn<String> preuvePhotoPath = GeneratedColumn<String>(
    'preuve_photo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coequipierIdMeta = const VerificationMeta(
    'coequipierId',
  );
  @override
  late final GeneratedColumn<int> coequipierId = GeneratedColumn<int>(
    'coequipier_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _creeLeMeta = const VerificationMeta('creeLe');
  @override
  late final GeneratedColumn<DateTime> creeLe = GeneratedColumn<DateTime>(
    'cree_le',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _cloudIdMeta = const VerificationMeta(
    'cloudId',
  );
  @override
  late final GeneratedColumn<String> cloudId = GeneratedColumn<String>(
    'cloud_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cloudPhotoPathMeta = const VerificationMeta(
    'cloudPhotoPath',
  );
  @override
  late final GeneratedColumn<String> cloudPhotoPath = GeneratedColumn<String>(
    'cloud_photo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tourneeId,
    adresseBrute,
    adresseNormalisee,
    lat,
    lng,
    nbColis,
    priorite,
    fenetreDebut,
    fenetreFin,
    dureeArretMin,
    notes,
    nomClient,
    statutLivraison,
    raisonEchec,
    livreLat,
    livreLng,
    livreLe,
    ordreOptimise,
    ordrePriorite,
    preuvePhotoPath,
    coequipierId,
    creeLe,
    cloudId,
    cloudPhotoPath,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stops';
  @override
  VerificationContext validateIntegrity(
    Insertable<Stop> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('tournee_id')) {
      context.handle(
        _tourneeIdMeta,
        tourneeId.isAcceptableOrUnknown(data['tournee_id']!, _tourneeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tourneeIdMeta);
    }
    if (data.containsKey('adresse_brute')) {
      context.handle(
        _adresseBruteMeta,
        adresseBrute.isAcceptableOrUnknown(
          data['adresse_brute']!,
          _adresseBruteMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_adresseBruteMeta);
    }
    if (data.containsKey('adresse_normalisee')) {
      context.handle(
        _adresseNormaliseeMeta,
        adresseNormalisee.isAcceptableOrUnknown(
          data['adresse_normalisee']!,
          _adresseNormaliseeMeta,
        ),
      );
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    }
    if (data.containsKey('lng')) {
      context.handle(
        _lngMeta,
        lng.isAcceptableOrUnknown(data['lng']!, _lngMeta),
      );
    }
    if (data.containsKey('nb_colis')) {
      context.handle(
        _nbColisMeta,
        nbColis.isAcceptableOrUnknown(data['nb_colis']!, _nbColisMeta),
      );
    }
    if (data.containsKey('priorite')) {
      context.handle(
        _prioriteMeta,
        priorite.isAcceptableOrUnknown(data['priorite']!, _prioriteMeta),
      );
    }
    if (data.containsKey('fenetre_debut')) {
      context.handle(
        _fenetreDebutMeta,
        fenetreDebut.isAcceptableOrUnknown(
          data['fenetre_debut']!,
          _fenetreDebutMeta,
        ),
      );
    }
    if (data.containsKey('fenetre_fin')) {
      context.handle(
        _fenetreFinMeta,
        fenetreFin.isAcceptableOrUnknown(data['fenetre_fin']!, _fenetreFinMeta),
      );
    }
    if (data.containsKey('duree_arret_min')) {
      context.handle(
        _dureeArretMinMeta,
        dureeArretMin.isAcceptableOrUnknown(
          data['duree_arret_min']!,
          _dureeArretMinMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('nom_client')) {
      context.handle(
        _nomClientMeta,
        nomClient.isAcceptableOrUnknown(data['nom_client']!, _nomClientMeta),
      );
    }
    if (data.containsKey('statut_livraison')) {
      context.handle(
        _statutLivraisonMeta,
        statutLivraison.isAcceptableOrUnknown(
          data['statut_livraison']!,
          _statutLivraisonMeta,
        ),
      );
    }
    if (data.containsKey('raison_echec')) {
      context.handle(
        _raisonEchecMeta,
        raisonEchec.isAcceptableOrUnknown(
          data['raison_echec']!,
          _raisonEchecMeta,
        ),
      );
    }
    if (data.containsKey('livre_lat')) {
      context.handle(
        _livreLatMeta,
        livreLat.isAcceptableOrUnknown(data['livre_lat']!, _livreLatMeta),
      );
    }
    if (data.containsKey('livre_lng')) {
      context.handle(
        _livreLngMeta,
        livreLng.isAcceptableOrUnknown(data['livre_lng']!, _livreLngMeta),
      );
    }
    if (data.containsKey('livre_le')) {
      context.handle(
        _livreLeMeta,
        livreLe.isAcceptableOrUnknown(data['livre_le']!, _livreLeMeta),
      );
    }
    if (data.containsKey('ordre_optimise')) {
      context.handle(
        _ordreOptimiseMeta,
        ordreOptimise.isAcceptableOrUnknown(
          data['ordre_optimise']!,
          _ordreOptimiseMeta,
        ),
      );
    }
    if (data.containsKey('ordre_priorite')) {
      context.handle(
        _ordrePrioriteMeta,
        ordrePriorite.isAcceptableOrUnknown(
          data['ordre_priorite']!,
          _ordrePrioriteMeta,
        ),
      );
    }
    if (data.containsKey('preuve_photo_path')) {
      context.handle(
        _preuvePhotoPathMeta,
        preuvePhotoPath.isAcceptableOrUnknown(
          data['preuve_photo_path']!,
          _preuvePhotoPathMeta,
        ),
      );
    }
    if (data.containsKey('coequipier_id')) {
      context.handle(
        _coequipierIdMeta,
        coequipierId.isAcceptableOrUnknown(
          data['coequipier_id']!,
          _coequipierIdMeta,
        ),
      );
    }
    if (data.containsKey('cree_le')) {
      context.handle(
        _creeLeMeta,
        creeLe.isAcceptableOrUnknown(data['cree_le']!, _creeLeMeta),
      );
    }
    if (data.containsKey('cloud_id')) {
      context.handle(
        _cloudIdMeta,
        cloudId.isAcceptableOrUnknown(data['cloud_id']!, _cloudIdMeta),
      );
    }
    if (data.containsKey('cloud_photo_path')) {
      context.handle(
        _cloudPhotoPathMeta,
        cloudPhotoPath.isAcceptableOrUnknown(
          data['cloud_photo_path']!,
          _cloudPhotoPathMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Stop map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Stop(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      tourneeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tournee_id'],
      )!,
      adresseBrute: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}adresse_brute'],
      )!,
      adresseNormalisee: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}adresse_normalisee'],
      ),
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      ),
      lng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lng'],
      ),
      nbColis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}nb_colis'],
      )!,
      priorite: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}priorite'],
      )!,
      fenetreDebut: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fenetre_debut'],
      ),
      fenetreFin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fenetre_fin'],
      ),
      dureeArretMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duree_arret_min'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      nomClient: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nom_client'],
      ),
      statutLivraison: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}statut_livraison'],
      )!,
      raisonEchec: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raison_echec'],
      ),
      livreLat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}livre_lat'],
      ),
      livreLng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}livre_lng'],
      ),
      livreLe: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}livre_le'],
      ),
      ordreOptimise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ordre_optimise'],
      ),
      ordrePriorite: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ordre_priorite'],
      ),
      preuvePhotoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preuve_photo_path'],
      ),
      coequipierId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}coequipier_id'],
      ),
      creeLe: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cree_le'],
      )!,
      cloudId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cloud_id'],
      ),
      cloudPhotoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cloud_photo_path'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $StopsTable createAlias(String alias) {
    return $StopsTable(attachedDatabase, alias);
  }
}

class Stop extends DataClass implements Insertable<Stop> {
  final int id;
  final int tourneeId;
  final String adresseBrute;
  final String? adresseNormalisee;
  final double? lat;
  final double? lng;
  final int nbColis;
  final String priorite;
  final String? fenetreDebut;
  final String? fenetreFin;
  final int dureeArretMin;
  final String? notes;
  final String? nomClient;
  final String statutLivraison;

  /// Raison de l'echec quand `statutLivraison == 'echec'` :
  /// 'absent' / 'refuse' / 'adresse_fausse' / 'autre'. Null sinon.
  final String? raisonEchec;

  /// Position GPS au moment du "Marquer livre" / "Marquer echec" --
  /// sert de preuve de passage en cas de litige client.
  /// Null si la permission GPS etait refusee ou l'app etait offline.
  final double? livreLat;
  final double? livreLng;

  /// Timestamp de la validation (livre OU echec). Sert aussi a calculer
  /// le temps passe sur la tournee a posteriori.
  final DateTime? livreLe;
  final int? ordreOptimise;

  /// Ordre choisi par l'utilisateur **a l'interieur** d'un groupe de
  /// priorite egale (obligatoire_premier ou obligatoire_dernier).
  /// 1 = livre en premier de son groupe, 2 = en deuxieme, etc.
  /// Null = pas applicable (priorite flexible / eviter).
  final int? ordrePriorite;

  /// Chemin local (filesystem app) de la photo preuve de livraison.
  /// Null si pas de photo prise. Stockage privé dans
  /// `app_documents/preuves/<stopId>_<timestamp>.jpg`.
  final String? preuvePhotoPath;

  /// Id du coequipier affecte a cet arret (FK vers `coequipiers.id`).
  /// Null = Noah lui-meme (cas par defaut, pas d'aidant). Pas de
  /// cascade : si on supprime un coequipier, on le retire de l'UI
  /// mais on garde la trace dans les arrets pour l'historique.
  final int? coequipierId;
  final DateTime creeLe;

  /// UUID v4 attribue par l'app au 1er push Supabase (sous-jalon 2.B).
  /// Null = stop jamais sync. Voir `Tournees.cloudId` pour le pattern.
  final String? cloudId;

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
  final String? cloudPhotoPath;

  /// Timestamp de la derniere modification locale (sous-jalon 2.D-1c).
  /// Voir `Tournees.updatedAt` pour le pattern complet (trigger SQLite
  /// + last-write-wins au pull).
  final DateTime updatedAt;
  const Stop({
    required this.id,
    required this.tourneeId,
    required this.adresseBrute,
    this.adresseNormalisee,
    this.lat,
    this.lng,
    required this.nbColis,
    required this.priorite,
    this.fenetreDebut,
    this.fenetreFin,
    required this.dureeArretMin,
    this.notes,
    this.nomClient,
    required this.statutLivraison,
    this.raisonEchec,
    this.livreLat,
    this.livreLng,
    this.livreLe,
    this.ordreOptimise,
    this.ordrePriorite,
    this.preuvePhotoPath,
    this.coequipierId,
    required this.creeLe,
    this.cloudId,
    this.cloudPhotoPath,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['tournee_id'] = Variable<int>(tourneeId);
    map['adresse_brute'] = Variable<String>(adresseBrute);
    if (!nullToAbsent || adresseNormalisee != null) {
      map['adresse_normalisee'] = Variable<String>(adresseNormalisee);
    }
    if (!nullToAbsent || lat != null) {
      map['lat'] = Variable<double>(lat);
    }
    if (!nullToAbsent || lng != null) {
      map['lng'] = Variable<double>(lng);
    }
    map['nb_colis'] = Variable<int>(nbColis);
    map['priorite'] = Variable<String>(priorite);
    if (!nullToAbsent || fenetreDebut != null) {
      map['fenetre_debut'] = Variable<String>(fenetreDebut);
    }
    if (!nullToAbsent || fenetreFin != null) {
      map['fenetre_fin'] = Variable<String>(fenetreFin);
    }
    map['duree_arret_min'] = Variable<int>(dureeArretMin);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || nomClient != null) {
      map['nom_client'] = Variable<String>(nomClient);
    }
    map['statut_livraison'] = Variable<String>(statutLivraison);
    if (!nullToAbsent || raisonEchec != null) {
      map['raison_echec'] = Variable<String>(raisonEchec);
    }
    if (!nullToAbsent || livreLat != null) {
      map['livre_lat'] = Variable<double>(livreLat);
    }
    if (!nullToAbsent || livreLng != null) {
      map['livre_lng'] = Variable<double>(livreLng);
    }
    if (!nullToAbsent || livreLe != null) {
      map['livre_le'] = Variable<DateTime>(livreLe);
    }
    if (!nullToAbsent || ordreOptimise != null) {
      map['ordre_optimise'] = Variable<int>(ordreOptimise);
    }
    if (!nullToAbsent || ordrePriorite != null) {
      map['ordre_priorite'] = Variable<int>(ordrePriorite);
    }
    if (!nullToAbsent || preuvePhotoPath != null) {
      map['preuve_photo_path'] = Variable<String>(preuvePhotoPath);
    }
    if (!nullToAbsent || coequipierId != null) {
      map['coequipier_id'] = Variable<int>(coequipierId);
    }
    map['cree_le'] = Variable<DateTime>(creeLe);
    if (!nullToAbsent || cloudId != null) {
      map['cloud_id'] = Variable<String>(cloudId);
    }
    if (!nullToAbsent || cloudPhotoPath != null) {
      map['cloud_photo_path'] = Variable<String>(cloudPhotoPath);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  StopsCompanion toCompanion(bool nullToAbsent) {
    return StopsCompanion(
      id: Value(id),
      tourneeId: Value(tourneeId),
      adresseBrute: Value(adresseBrute),
      adresseNormalisee: adresseNormalisee == null && nullToAbsent
          ? const Value.absent()
          : Value(adresseNormalisee),
      lat: lat == null && nullToAbsent ? const Value.absent() : Value(lat),
      lng: lng == null && nullToAbsent ? const Value.absent() : Value(lng),
      nbColis: Value(nbColis),
      priorite: Value(priorite),
      fenetreDebut: fenetreDebut == null && nullToAbsent
          ? const Value.absent()
          : Value(fenetreDebut),
      fenetreFin: fenetreFin == null && nullToAbsent
          ? const Value.absent()
          : Value(fenetreFin),
      dureeArretMin: Value(dureeArretMin),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      nomClient: nomClient == null && nullToAbsent
          ? const Value.absent()
          : Value(nomClient),
      statutLivraison: Value(statutLivraison),
      raisonEchec: raisonEchec == null && nullToAbsent
          ? const Value.absent()
          : Value(raisonEchec),
      livreLat: livreLat == null && nullToAbsent
          ? const Value.absent()
          : Value(livreLat),
      livreLng: livreLng == null && nullToAbsent
          ? const Value.absent()
          : Value(livreLng),
      livreLe: livreLe == null && nullToAbsent
          ? const Value.absent()
          : Value(livreLe),
      ordreOptimise: ordreOptimise == null && nullToAbsent
          ? const Value.absent()
          : Value(ordreOptimise),
      ordrePriorite: ordrePriorite == null && nullToAbsent
          ? const Value.absent()
          : Value(ordrePriorite),
      preuvePhotoPath: preuvePhotoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(preuvePhotoPath),
      coequipierId: coequipierId == null && nullToAbsent
          ? const Value.absent()
          : Value(coequipierId),
      creeLe: Value(creeLe),
      cloudId: cloudId == null && nullToAbsent
          ? const Value.absent()
          : Value(cloudId),
      cloudPhotoPath: cloudPhotoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(cloudPhotoPath),
      updatedAt: Value(updatedAt),
    );
  }

  factory Stop.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Stop(
      id: serializer.fromJson<int>(json['id']),
      tourneeId: serializer.fromJson<int>(json['tourneeId']),
      adresseBrute: serializer.fromJson<String>(json['adresseBrute']),
      adresseNormalisee: serializer.fromJson<String?>(
        json['adresseNormalisee'],
      ),
      lat: serializer.fromJson<double?>(json['lat']),
      lng: serializer.fromJson<double?>(json['lng']),
      nbColis: serializer.fromJson<int>(json['nbColis']),
      priorite: serializer.fromJson<String>(json['priorite']),
      fenetreDebut: serializer.fromJson<String?>(json['fenetreDebut']),
      fenetreFin: serializer.fromJson<String?>(json['fenetreFin']),
      dureeArretMin: serializer.fromJson<int>(json['dureeArretMin']),
      notes: serializer.fromJson<String?>(json['notes']),
      nomClient: serializer.fromJson<String?>(json['nomClient']),
      statutLivraison: serializer.fromJson<String>(json['statutLivraison']),
      raisonEchec: serializer.fromJson<String?>(json['raisonEchec']),
      livreLat: serializer.fromJson<double?>(json['livreLat']),
      livreLng: serializer.fromJson<double?>(json['livreLng']),
      livreLe: serializer.fromJson<DateTime?>(json['livreLe']),
      ordreOptimise: serializer.fromJson<int?>(json['ordreOptimise']),
      ordrePriorite: serializer.fromJson<int?>(json['ordrePriorite']),
      preuvePhotoPath: serializer.fromJson<String?>(json['preuvePhotoPath']),
      coequipierId: serializer.fromJson<int?>(json['coequipierId']),
      creeLe: serializer.fromJson<DateTime>(json['creeLe']),
      cloudId: serializer.fromJson<String?>(json['cloudId']),
      cloudPhotoPath: serializer.fromJson<String?>(json['cloudPhotoPath']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'tourneeId': serializer.toJson<int>(tourneeId),
      'adresseBrute': serializer.toJson<String>(adresseBrute),
      'adresseNormalisee': serializer.toJson<String?>(adresseNormalisee),
      'lat': serializer.toJson<double?>(lat),
      'lng': serializer.toJson<double?>(lng),
      'nbColis': serializer.toJson<int>(nbColis),
      'priorite': serializer.toJson<String>(priorite),
      'fenetreDebut': serializer.toJson<String?>(fenetreDebut),
      'fenetreFin': serializer.toJson<String?>(fenetreFin),
      'dureeArretMin': serializer.toJson<int>(dureeArretMin),
      'notes': serializer.toJson<String?>(notes),
      'nomClient': serializer.toJson<String?>(nomClient),
      'statutLivraison': serializer.toJson<String>(statutLivraison),
      'raisonEchec': serializer.toJson<String?>(raisonEchec),
      'livreLat': serializer.toJson<double?>(livreLat),
      'livreLng': serializer.toJson<double?>(livreLng),
      'livreLe': serializer.toJson<DateTime?>(livreLe),
      'ordreOptimise': serializer.toJson<int?>(ordreOptimise),
      'ordrePriorite': serializer.toJson<int?>(ordrePriorite),
      'preuvePhotoPath': serializer.toJson<String?>(preuvePhotoPath),
      'coequipierId': serializer.toJson<int?>(coequipierId),
      'creeLe': serializer.toJson<DateTime>(creeLe),
      'cloudId': serializer.toJson<String?>(cloudId),
      'cloudPhotoPath': serializer.toJson<String?>(cloudPhotoPath),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Stop copyWith({
    int? id,
    int? tourneeId,
    String? adresseBrute,
    Value<String?> adresseNormalisee = const Value.absent(),
    Value<double?> lat = const Value.absent(),
    Value<double?> lng = const Value.absent(),
    int? nbColis,
    String? priorite,
    Value<String?> fenetreDebut = const Value.absent(),
    Value<String?> fenetreFin = const Value.absent(),
    int? dureeArretMin,
    Value<String?> notes = const Value.absent(),
    Value<String?> nomClient = const Value.absent(),
    String? statutLivraison,
    Value<String?> raisonEchec = const Value.absent(),
    Value<double?> livreLat = const Value.absent(),
    Value<double?> livreLng = const Value.absent(),
    Value<DateTime?> livreLe = const Value.absent(),
    Value<int?> ordreOptimise = const Value.absent(),
    Value<int?> ordrePriorite = const Value.absent(),
    Value<String?> preuvePhotoPath = const Value.absent(),
    Value<int?> coequipierId = const Value.absent(),
    DateTime? creeLe,
    Value<String?> cloudId = const Value.absent(),
    Value<String?> cloudPhotoPath = const Value.absent(),
    DateTime? updatedAt,
  }) => Stop(
    id: id ?? this.id,
    tourneeId: tourneeId ?? this.tourneeId,
    adresseBrute: adresseBrute ?? this.adresseBrute,
    adresseNormalisee: adresseNormalisee.present
        ? adresseNormalisee.value
        : this.adresseNormalisee,
    lat: lat.present ? lat.value : this.lat,
    lng: lng.present ? lng.value : this.lng,
    nbColis: nbColis ?? this.nbColis,
    priorite: priorite ?? this.priorite,
    fenetreDebut: fenetreDebut.present ? fenetreDebut.value : this.fenetreDebut,
    fenetreFin: fenetreFin.present ? fenetreFin.value : this.fenetreFin,
    dureeArretMin: dureeArretMin ?? this.dureeArretMin,
    notes: notes.present ? notes.value : this.notes,
    nomClient: nomClient.present ? nomClient.value : this.nomClient,
    statutLivraison: statutLivraison ?? this.statutLivraison,
    raisonEchec: raisonEchec.present ? raisonEchec.value : this.raisonEchec,
    livreLat: livreLat.present ? livreLat.value : this.livreLat,
    livreLng: livreLng.present ? livreLng.value : this.livreLng,
    livreLe: livreLe.present ? livreLe.value : this.livreLe,
    ordreOptimise: ordreOptimise.present
        ? ordreOptimise.value
        : this.ordreOptimise,
    ordrePriorite: ordrePriorite.present
        ? ordrePriorite.value
        : this.ordrePriorite,
    preuvePhotoPath: preuvePhotoPath.present
        ? preuvePhotoPath.value
        : this.preuvePhotoPath,
    coequipierId: coequipierId.present ? coequipierId.value : this.coequipierId,
    creeLe: creeLe ?? this.creeLe,
    cloudId: cloudId.present ? cloudId.value : this.cloudId,
    cloudPhotoPath: cloudPhotoPath.present
        ? cloudPhotoPath.value
        : this.cloudPhotoPath,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Stop copyWithCompanion(StopsCompanion data) {
    return Stop(
      id: data.id.present ? data.id.value : this.id,
      tourneeId: data.tourneeId.present ? data.tourneeId.value : this.tourneeId,
      adresseBrute: data.adresseBrute.present
          ? data.adresseBrute.value
          : this.adresseBrute,
      adresseNormalisee: data.adresseNormalisee.present
          ? data.adresseNormalisee.value
          : this.adresseNormalisee,
      lat: data.lat.present ? data.lat.value : this.lat,
      lng: data.lng.present ? data.lng.value : this.lng,
      nbColis: data.nbColis.present ? data.nbColis.value : this.nbColis,
      priorite: data.priorite.present ? data.priorite.value : this.priorite,
      fenetreDebut: data.fenetreDebut.present
          ? data.fenetreDebut.value
          : this.fenetreDebut,
      fenetreFin: data.fenetreFin.present
          ? data.fenetreFin.value
          : this.fenetreFin,
      dureeArretMin: data.dureeArretMin.present
          ? data.dureeArretMin.value
          : this.dureeArretMin,
      notes: data.notes.present ? data.notes.value : this.notes,
      nomClient: data.nomClient.present ? data.nomClient.value : this.nomClient,
      statutLivraison: data.statutLivraison.present
          ? data.statutLivraison.value
          : this.statutLivraison,
      raisonEchec: data.raisonEchec.present
          ? data.raisonEchec.value
          : this.raisonEchec,
      livreLat: data.livreLat.present ? data.livreLat.value : this.livreLat,
      livreLng: data.livreLng.present ? data.livreLng.value : this.livreLng,
      livreLe: data.livreLe.present ? data.livreLe.value : this.livreLe,
      ordreOptimise: data.ordreOptimise.present
          ? data.ordreOptimise.value
          : this.ordreOptimise,
      ordrePriorite: data.ordrePriorite.present
          ? data.ordrePriorite.value
          : this.ordrePriorite,
      preuvePhotoPath: data.preuvePhotoPath.present
          ? data.preuvePhotoPath.value
          : this.preuvePhotoPath,
      coequipierId: data.coequipierId.present
          ? data.coequipierId.value
          : this.coequipierId,
      creeLe: data.creeLe.present ? data.creeLe.value : this.creeLe,
      cloudId: data.cloudId.present ? data.cloudId.value : this.cloudId,
      cloudPhotoPath: data.cloudPhotoPath.present
          ? data.cloudPhotoPath.value
          : this.cloudPhotoPath,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Stop(')
          ..write('id: $id, ')
          ..write('tourneeId: $tourneeId, ')
          ..write('adresseBrute: $adresseBrute, ')
          ..write('adresseNormalisee: $adresseNormalisee, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('nbColis: $nbColis, ')
          ..write('priorite: $priorite, ')
          ..write('fenetreDebut: $fenetreDebut, ')
          ..write('fenetreFin: $fenetreFin, ')
          ..write('dureeArretMin: $dureeArretMin, ')
          ..write('notes: $notes, ')
          ..write('nomClient: $nomClient, ')
          ..write('statutLivraison: $statutLivraison, ')
          ..write('raisonEchec: $raisonEchec, ')
          ..write('livreLat: $livreLat, ')
          ..write('livreLng: $livreLng, ')
          ..write('livreLe: $livreLe, ')
          ..write('ordreOptimise: $ordreOptimise, ')
          ..write('ordrePriorite: $ordrePriorite, ')
          ..write('preuvePhotoPath: $preuvePhotoPath, ')
          ..write('coequipierId: $coequipierId, ')
          ..write('creeLe: $creeLe, ')
          ..write('cloudId: $cloudId, ')
          ..write('cloudPhotoPath: $cloudPhotoPath, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    tourneeId,
    adresseBrute,
    adresseNormalisee,
    lat,
    lng,
    nbColis,
    priorite,
    fenetreDebut,
    fenetreFin,
    dureeArretMin,
    notes,
    nomClient,
    statutLivraison,
    raisonEchec,
    livreLat,
    livreLng,
    livreLe,
    ordreOptimise,
    ordrePriorite,
    preuvePhotoPath,
    coequipierId,
    creeLe,
    cloudId,
    cloudPhotoPath,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Stop &&
          other.id == this.id &&
          other.tourneeId == this.tourneeId &&
          other.adresseBrute == this.adresseBrute &&
          other.adresseNormalisee == this.adresseNormalisee &&
          other.lat == this.lat &&
          other.lng == this.lng &&
          other.nbColis == this.nbColis &&
          other.priorite == this.priorite &&
          other.fenetreDebut == this.fenetreDebut &&
          other.fenetreFin == this.fenetreFin &&
          other.dureeArretMin == this.dureeArretMin &&
          other.notes == this.notes &&
          other.nomClient == this.nomClient &&
          other.statutLivraison == this.statutLivraison &&
          other.raisonEchec == this.raisonEchec &&
          other.livreLat == this.livreLat &&
          other.livreLng == this.livreLng &&
          other.livreLe == this.livreLe &&
          other.ordreOptimise == this.ordreOptimise &&
          other.ordrePriorite == this.ordrePriorite &&
          other.preuvePhotoPath == this.preuvePhotoPath &&
          other.coequipierId == this.coequipierId &&
          other.creeLe == this.creeLe &&
          other.cloudId == this.cloudId &&
          other.cloudPhotoPath == this.cloudPhotoPath &&
          other.updatedAt == this.updatedAt);
}

class StopsCompanion extends UpdateCompanion<Stop> {
  final Value<int> id;
  final Value<int> tourneeId;
  final Value<String> adresseBrute;
  final Value<String?> adresseNormalisee;
  final Value<double?> lat;
  final Value<double?> lng;
  final Value<int> nbColis;
  final Value<String> priorite;
  final Value<String?> fenetreDebut;
  final Value<String?> fenetreFin;
  final Value<int> dureeArretMin;
  final Value<String?> notes;
  final Value<String?> nomClient;
  final Value<String> statutLivraison;
  final Value<String?> raisonEchec;
  final Value<double?> livreLat;
  final Value<double?> livreLng;
  final Value<DateTime?> livreLe;
  final Value<int?> ordreOptimise;
  final Value<int?> ordrePriorite;
  final Value<String?> preuvePhotoPath;
  final Value<int?> coequipierId;
  final Value<DateTime> creeLe;
  final Value<String?> cloudId;
  final Value<String?> cloudPhotoPath;
  final Value<DateTime> updatedAt;
  const StopsCompanion({
    this.id = const Value.absent(),
    this.tourneeId = const Value.absent(),
    this.adresseBrute = const Value.absent(),
    this.adresseNormalisee = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.nbColis = const Value.absent(),
    this.priorite = const Value.absent(),
    this.fenetreDebut = const Value.absent(),
    this.fenetreFin = const Value.absent(),
    this.dureeArretMin = const Value.absent(),
    this.notes = const Value.absent(),
    this.nomClient = const Value.absent(),
    this.statutLivraison = const Value.absent(),
    this.raisonEchec = const Value.absent(),
    this.livreLat = const Value.absent(),
    this.livreLng = const Value.absent(),
    this.livreLe = const Value.absent(),
    this.ordreOptimise = const Value.absent(),
    this.ordrePriorite = const Value.absent(),
    this.preuvePhotoPath = const Value.absent(),
    this.coequipierId = const Value.absent(),
    this.creeLe = const Value.absent(),
    this.cloudId = const Value.absent(),
    this.cloudPhotoPath = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  StopsCompanion.insert({
    this.id = const Value.absent(),
    required int tourneeId,
    required String adresseBrute,
    this.adresseNormalisee = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.nbColis = const Value.absent(),
    this.priorite = const Value.absent(),
    this.fenetreDebut = const Value.absent(),
    this.fenetreFin = const Value.absent(),
    this.dureeArretMin = const Value.absent(),
    this.notes = const Value.absent(),
    this.nomClient = const Value.absent(),
    this.statutLivraison = const Value.absent(),
    this.raisonEchec = const Value.absent(),
    this.livreLat = const Value.absent(),
    this.livreLng = const Value.absent(),
    this.livreLe = const Value.absent(),
    this.ordreOptimise = const Value.absent(),
    this.ordrePriorite = const Value.absent(),
    this.preuvePhotoPath = const Value.absent(),
    this.coequipierId = const Value.absent(),
    this.creeLe = const Value.absent(),
    this.cloudId = const Value.absent(),
    this.cloudPhotoPath = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : tourneeId = Value(tourneeId),
       adresseBrute = Value(adresseBrute);
  static Insertable<Stop> custom({
    Expression<int>? id,
    Expression<int>? tourneeId,
    Expression<String>? adresseBrute,
    Expression<String>? adresseNormalisee,
    Expression<double>? lat,
    Expression<double>? lng,
    Expression<int>? nbColis,
    Expression<String>? priorite,
    Expression<String>? fenetreDebut,
    Expression<String>? fenetreFin,
    Expression<int>? dureeArretMin,
    Expression<String>? notes,
    Expression<String>? nomClient,
    Expression<String>? statutLivraison,
    Expression<String>? raisonEchec,
    Expression<double>? livreLat,
    Expression<double>? livreLng,
    Expression<DateTime>? livreLe,
    Expression<int>? ordreOptimise,
    Expression<int>? ordrePriorite,
    Expression<String>? preuvePhotoPath,
    Expression<int>? coequipierId,
    Expression<DateTime>? creeLe,
    Expression<String>? cloudId,
    Expression<String>? cloudPhotoPath,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tourneeId != null) 'tournee_id': tourneeId,
      if (adresseBrute != null) 'adresse_brute': adresseBrute,
      if (adresseNormalisee != null) 'adresse_normalisee': adresseNormalisee,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (nbColis != null) 'nb_colis': nbColis,
      if (priorite != null) 'priorite': priorite,
      if (fenetreDebut != null) 'fenetre_debut': fenetreDebut,
      if (fenetreFin != null) 'fenetre_fin': fenetreFin,
      if (dureeArretMin != null) 'duree_arret_min': dureeArretMin,
      if (notes != null) 'notes': notes,
      if (nomClient != null) 'nom_client': nomClient,
      if (statutLivraison != null) 'statut_livraison': statutLivraison,
      if (raisonEchec != null) 'raison_echec': raisonEchec,
      if (livreLat != null) 'livre_lat': livreLat,
      if (livreLng != null) 'livre_lng': livreLng,
      if (livreLe != null) 'livre_le': livreLe,
      if (ordreOptimise != null) 'ordre_optimise': ordreOptimise,
      if (ordrePriorite != null) 'ordre_priorite': ordrePriorite,
      if (preuvePhotoPath != null) 'preuve_photo_path': preuvePhotoPath,
      if (coequipierId != null) 'coequipier_id': coequipierId,
      if (creeLe != null) 'cree_le': creeLe,
      if (cloudId != null) 'cloud_id': cloudId,
      if (cloudPhotoPath != null) 'cloud_photo_path': cloudPhotoPath,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  StopsCompanion copyWith({
    Value<int>? id,
    Value<int>? tourneeId,
    Value<String>? adresseBrute,
    Value<String?>? adresseNormalisee,
    Value<double?>? lat,
    Value<double?>? lng,
    Value<int>? nbColis,
    Value<String>? priorite,
    Value<String?>? fenetreDebut,
    Value<String?>? fenetreFin,
    Value<int>? dureeArretMin,
    Value<String?>? notes,
    Value<String?>? nomClient,
    Value<String>? statutLivraison,
    Value<String?>? raisonEchec,
    Value<double?>? livreLat,
    Value<double?>? livreLng,
    Value<DateTime?>? livreLe,
    Value<int?>? ordreOptimise,
    Value<int?>? ordrePriorite,
    Value<String?>? preuvePhotoPath,
    Value<int?>? coequipierId,
    Value<DateTime>? creeLe,
    Value<String?>? cloudId,
    Value<String?>? cloudPhotoPath,
    Value<DateTime>? updatedAt,
  }) {
    return StopsCompanion(
      id: id ?? this.id,
      tourneeId: tourneeId ?? this.tourneeId,
      adresseBrute: adresseBrute ?? this.adresseBrute,
      adresseNormalisee: adresseNormalisee ?? this.adresseNormalisee,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      nbColis: nbColis ?? this.nbColis,
      priorite: priorite ?? this.priorite,
      fenetreDebut: fenetreDebut ?? this.fenetreDebut,
      fenetreFin: fenetreFin ?? this.fenetreFin,
      dureeArretMin: dureeArretMin ?? this.dureeArretMin,
      notes: notes ?? this.notes,
      nomClient: nomClient ?? this.nomClient,
      statutLivraison: statutLivraison ?? this.statutLivraison,
      raisonEchec: raisonEchec ?? this.raisonEchec,
      livreLat: livreLat ?? this.livreLat,
      livreLng: livreLng ?? this.livreLng,
      livreLe: livreLe ?? this.livreLe,
      ordreOptimise: ordreOptimise ?? this.ordreOptimise,
      ordrePriorite: ordrePriorite ?? this.ordrePriorite,
      preuvePhotoPath: preuvePhotoPath ?? this.preuvePhotoPath,
      coequipierId: coequipierId ?? this.coequipierId,
      creeLe: creeLe ?? this.creeLe,
      cloudId: cloudId ?? this.cloudId,
      cloudPhotoPath: cloudPhotoPath ?? this.cloudPhotoPath,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (tourneeId.present) {
      map['tournee_id'] = Variable<int>(tourneeId.value);
    }
    if (adresseBrute.present) {
      map['adresse_brute'] = Variable<String>(adresseBrute.value);
    }
    if (adresseNormalisee.present) {
      map['adresse_normalisee'] = Variable<String>(adresseNormalisee.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lng.present) {
      map['lng'] = Variable<double>(lng.value);
    }
    if (nbColis.present) {
      map['nb_colis'] = Variable<int>(nbColis.value);
    }
    if (priorite.present) {
      map['priorite'] = Variable<String>(priorite.value);
    }
    if (fenetreDebut.present) {
      map['fenetre_debut'] = Variable<String>(fenetreDebut.value);
    }
    if (fenetreFin.present) {
      map['fenetre_fin'] = Variable<String>(fenetreFin.value);
    }
    if (dureeArretMin.present) {
      map['duree_arret_min'] = Variable<int>(dureeArretMin.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (nomClient.present) {
      map['nom_client'] = Variable<String>(nomClient.value);
    }
    if (statutLivraison.present) {
      map['statut_livraison'] = Variable<String>(statutLivraison.value);
    }
    if (raisonEchec.present) {
      map['raison_echec'] = Variable<String>(raisonEchec.value);
    }
    if (livreLat.present) {
      map['livre_lat'] = Variable<double>(livreLat.value);
    }
    if (livreLng.present) {
      map['livre_lng'] = Variable<double>(livreLng.value);
    }
    if (livreLe.present) {
      map['livre_le'] = Variable<DateTime>(livreLe.value);
    }
    if (ordreOptimise.present) {
      map['ordre_optimise'] = Variable<int>(ordreOptimise.value);
    }
    if (ordrePriorite.present) {
      map['ordre_priorite'] = Variable<int>(ordrePriorite.value);
    }
    if (preuvePhotoPath.present) {
      map['preuve_photo_path'] = Variable<String>(preuvePhotoPath.value);
    }
    if (coequipierId.present) {
      map['coequipier_id'] = Variable<int>(coequipierId.value);
    }
    if (creeLe.present) {
      map['cree_le'] = Variable<DateTime>(creeLe.value);
    }
    if (cloudId.present) {
      map['cloud_id'] = Variable<String>(cloudId.value);
    }
    if (cloudPhotoPath.present) {
      map['cloud_photo_path'] = Variable<String>(cloudPhotoPath.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StopsCompanion(')
          ..write('id: $id, ')
          ..write('tourneeId: $tourneeId, ')
          ..write('adresseBrute: $adresseBrute, ')
          ..write('adresseNormalisee: $adresseNormalisee, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('nbColis: $nbColis, ')
          ..write('priorite: $priorite, ')
          ..write('fenetreDebut: $fenetreDebut, ')
          ..write('fenetreFin: $fenetreFin, ')
          ..write('dureeArretMin: $dureeArretMin, ')
          ..write('notes: $notes, ')
          ..write('nomClient: $nomClient, ')
          ..write('statutLivraison: $statutLivraison, ')
          ..write('raisonEchec: $raisonEchec, ')
          ..write('livreLat: $livreLat, ')
          ..write('livreLng: $livreLng, ')
          ..write('livreLe: $livreLe, ')
          ..write('ordreOptimise: $ordreOptimise, ')
          ..write('ordrePriorite: $ordrePriorite, ')
          ..write('preuvePhotoPath: $preuvePhotoPath, ')
          ..write('coequipierId: $coequipierId, ')
          ..write('creeLe: $creeLe, ')
          ..write('cloudId: $cloudId, ')
          ..write('cloudPhotoPath: $cloudPhotoPath, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ParametresTable extends Parametres
    with TableInfo<$ParametresTable, Parametre> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ParametresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cleMeta = const VerificationMeta('cle');
  @override
  late final GeneratedColumn<String> cle = GeneratedColumn<String>(
    'cle',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valeurMeta = const VerificationMeta('valeur');
  @override
  late final GeneratedColumn<String> valeur = GeneratedColumn<String>(
    'valeur',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [cle, valeur];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'parametres';
  @override
  VerificationContext validateIntegrity(
    Insertable<Parametre> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cle')) {
      context.handle(
        _cleMeta,
        cle.isAcceptableOrUnknown(data['cle']!, _cleMeta),
      );
    } else if (isInserting) {
      context.missing(_cleMeta);
    }
    if (data.containsKey('valeur')) {
      context.handle(
        _valeurMeta,
        valeur.isAcceptableOrUnknown(data['valeur']!, _valeurMeta),
      );
    } else if (isInserting) {
      context.missing(_valeurMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cle};
  @override
  Parametre map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Parametre(
      cle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cle'],
      )!,
      valeur: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}valeur'],
      )!,
    );
  }

  @override
  $ParametresTable createAlias(String alias) {
    return $ParametresTable(attachedDatabase, alias);
  }
}

class Parametre extends DataClass implements Insertable<Parametre> {
  final String cle;
  final String valeur;
  const Parametre({required this.cle, required this.valeur});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cle'] = Variable<String>(cle);
    map['valeur'] = Variable<String>(valeur);
    return map;
  }

  ParametresCompanion toCompanion(bool nullToAbsent) {
    return ParametresCompanion(cle: Value(cle), valeur: Value(valeur));
  }

  factory Parametre.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Parametre(
      cle: serializer.fromJson<String>(json['cle']),
      valeur: serializer.fromJson<String>(json['valeur']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cle': serializer.toJson<String>(cle),
      'valeur': serializer.toJson<String>(valeur),
    };
  }

  Parametre copyWith({String? cle, String? valeur}) =>
      Parametre(cle: cle ?? this.cle, valeur: valeur ?? this.valeur);
  Parametre copyWithCompanion(ParametresCompanion data) {
    return Parametre(
      cle: data.cle.present ? data.cle.value : this.cle,
      valeur: data.valeur.present ? data.valeur.value : this.valeur,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Parametre(')
          ..write('cle: $cle, ')
          ..write('valeur: $valeur')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(cle, valeur);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Parametre &&
          other.cle == this.cle &&
          other.valeur == this.valeur);
}

class ParametresCompanion extends UpdateCompanion<Parametre> {
  final Value<String> cle;
  final Value<String> valeur;
  final Value<int> rowid;
  const ParametresCompanion({
    this.cle = const Value.absent(),
    this.valeur = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ParametresCompanion.insert({
    required String cle,
    required String valeur,
    this.rowid = const Value.absent(),
  }) : cle = Value(cle),
       valeur = Value(valeur);
  static Insertable<Parametre> custom({
    Expression<String>? cle,
    Expression<String>? valeur,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cle != null) 'cle': cle,
      if (valeur != null) 'valeur': valeur,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ParametresCompanion copyWith({
    Value<String>? cle,
    Value<String>? valeur,
    Value<int>? rowid,
  }) {
    return ParametresCompanion(
      cle: cle ?? this.cle,
      valeur: valeur ?? this.valeur,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cle.present) {
      map['cle'] = Variable<String>(cle.value);
    }
    if (valeur.present) {
      map['valeur'] = Variable<String>(valeur.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ParametresCompanion(')
          ..write('cle: $cle, ')
          ..write('valeur: $valeur, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SheetsTable extends Sheets with TableInfo<$SheetsTable, Sheet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SheetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _stopIdMeta = const VerificationMeta('stopId');
  @override
  late final GeneratedColumn<int> stopId = GeneratedColumn<int>(
    'stop_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES stops (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _expediteurMeta = const VerificationMeta(
    'expediteur',
  );
  @override
  late final GeneratedColumn<String> expediteur = GeneratedColumn<String>(
    'expediteur',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _refCodeMeta = const VerificationMeta(
    'refCode',
  );
  @override
  late final GeneratedColumn<String> refCode = GeneratedColumn<String>(
    'ref_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nomDestinataireMeta = const VerificationMeta(
    'nomDestinataire',
  );
  @override
  late final GeneratedColumn<String> nomDestinataire = GeneratedColumn<String>(
    'nom_destinataire',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _telephoneMeta = const VerificationMeta(
    'telephone',
  );
  @override
  late final GeneratedColumn<String> telephone = GeneratedColumn<String>(
    'telephone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nbColisMeta = const VerificationMeta(
    'nbColis',
  );
  @override
  late final GeneratedColumn<int> nbColis = GeneratedColumn<int>(
    'nb_colis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _poidsKgMeta = const VerificationMeta(
    'poidsKg',
  );
  @override
  late final GeneratedColumn<double> poidsKg = GeneratedColumn<double>(
    'poids_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statutMeta = const VerificationMeta('statut');
  @override
  late final GeneratedColumn<String> statut = GeneratedColumn<String>(
    'statut',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('a_livrer'),
  );
  static const VerificationMeta _raisonEchecMeta = const VerificationMeta(
    'raisonEchec',
  );
  @override
  late final GeneratedColumn<String> raisonEchec = GeneratedColumn<String>(
    'raison_echec',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _creeLeMeta = const VerificationMeta('creeLe');
  @override
  late final GeneratedColumn<DateTime> creeLe = GeneratedColumn<DateTime>(
    'cree_le',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    stopId,
    expediteur,
    refCode,
    nomDestinataire,
    telephone,
    nbColis,
    poidsKg,
    statut,
    raisonEchec,
    creeLe,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sheets';
  @override
  VerificationContext validateIntegrity(
    Insertable<Sheet> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('stop_id')) {
      context.handle(
        _stopIdMeta,
        stopId.isAcceptableOrUnknown(data['stop_id']!, _stopIdMeta),
      );
    } else if (isInserting) {
      context.missing(_stopIdMeta);
    }
    if (data.containsKey('expediteur')) {
      context.handle(
        _expediteurMeta,
        expediteur.isAcceptableOrUnknown(data['expediteur']!, _expediteurMeta),
      );
    } else if (isInserting) {
      context.missing(_expediteurMeta);
    }
    if (data.containsKey('ref_code')) {
      context.handle(
        _refCodeMeta,
        refCode.isAcceptableOrUnknown(data['ref_code']!, _refCodeMeta),
      );
    }
    if (data.containsKey('nom_destinataire')) {
      context.handle(
        _nomDestinataireMeta,
        nomDestinataire.isAcceptableOrUnknown(
          data['nom_destinataire']!,
          _nomDestinataireMeta,
        ),
      );
    }
    if (data.containsKey('telephone')) {
      context.handle(
        _telephoneMeta,
        telephone.isAcceptableOrUnknown(data['telephone']!, _telephoneMeta),
      );
    }
    if (data.containsKey('nb_colis')) {
      context.handle(
        _nbColisMeta,
        nbColis.isAcceptableOrUnknown(data['nb_colis']!, _nbColisMeta),
      );
    }
    if (data.containsKey('poids_kg')) {
      context.handle(
        _poidsKgMeta,
        poidsKg.isAcceptableOrUnknown(data['poids_kg']!, _poidsKgMeta),
      );
    }
    if (data.containsKey('statut')) {
      context.handle(
        _statutMeta,
        statut.isAcceptableOrUnknown(data['statut']!, _statutMeta),
      );
    }
    if (data.containsKey('raison_echec')) {
      context.handle(
        _raisonEchecMeta,
        raisonEchec.isAcceptableOrUnknown(
          data['raison_echec']!,
          _raisonEchecMeta,
        ),
      );
    }
    if (data.containsKey('cree_le')) {
      context.handle(
        _creeLeMeta,
        creeLe.isAcceptableOrUnknown(data['cree_le']!, _creeLeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Sheet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Sheet(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      stopId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stop_id'],
      )!,
      expediteur: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expediteur'],
      )!,
      refCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ref_code'],
      ),
      nomDestinataire: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nom_destinataire'],
      ),
      telephone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}telephone'],
      ),
      nbColis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}nb_colis'],
      )!,
      poidsKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}poids_kg'],
      ),
      statut: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}statut'],
      )!,
      raisonEchec: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raison_echec'],
      ),
      creeLe: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cree_le'],
      )!,
    );
  }

  @override
  $SheetsTable createAlias(String alias) {
    return $SheetsTable(attachedDatabase, alias);
  }
}

class Sheet extends DataClass implements Insertable<Sheet> {
  final int id;
  final int stopId;
  final String expediteur;
  final String? refCode;
  final String? nomDestinataire;
  final String? telephone;
  final int nbColis;
  final double? poidsKg;
  final String statut;
  final String? raisonEchec;
  final DateTime creeLe;
  const Sheet({
    required this.id,
    required this.stopId,
    required this.expediteur,
    this.refCode,
    this.nomDestinataire,
    this.telephone,
    required this.nbColis,
    this.poidsKg,
    required this.statut,
    this.raisonEchec,
    required this.creeLe,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['stop_id'] = Variable<int>(stopId);
    map['expediteur'] = Variable<String>(expediteur);
    if (!nullToAbsent || refCode != null) {
      map['ref_code'] = Variable<String>(refCode);
    }
    if (!nullToAbsent || nomDestinataire != null) {
      map['nom_destinataire'] = Variable<String>(nomDestinataire);
    }
    if (!nullToAbsent || telephone != null) {
      map['telephone'] = Variable<String>(telephone);
    }
    map['nb_colis'] = Variable<int>(nbColis);
    if (!nullToAbsent || poidsKg != null) {
      map['poids_kg'] = Variable<double>(poidsKg);
    }
    map['statut'] = Variable<String>(statut);
    if (!nullToAbsent || raisonEchec != null) {
      map['raison_echec'] = Variable<String>(raisonEchec);
    }
    map['cree_le'] = Variable<DateTime>(creeLe);
    return map;
  }

  SheetsCompanion toCompanion(bool nullToAbsent) {
    return SheetsCompanion(
      id: Value(id),
      stopId: Value(stopId),
      expediteur: Value(expediteur),
      refCode: refCode == null && nullToAbsent
          ? const Value.absent()
          : Value(refCode),
      nomDestinataire: nomDestinataire == null && nullToAbsent
          ? const Value.absent()
          : Value(nomDestinataire),
      telephone: telephone == null && nullToAbsent
          ? const Value.absent()
          : Value(telephone),
      nbColis: Value(nbColis),
      poidsKg: poidsKg == null && nullToAbsent
          ? const Value.absent()
          : Value(poidsKg),
      statut: Value(statut),
      raisonEchec: raisonEchec == null && nullToAbsent
          ? const Value.absent()
          : Value(raisonEchec),
      creeLe: Value(creeLe),
    );
  }

  factory Sheet.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Sheet(
      id: serializer.fromJson<int>(json['id']),
      stopId: serializer.fromJson<int>(json['stopId']),
      expediteur: serializer.fromJson<String>(json['expediteur']),
      refCode: serializer.fromJson<String?>(json['refCode']),
      nomDestinataire: serializer.fromJson<String?>(json['nomDestinataire']),
      telephone: serializer.fromJson<String?>(json['telephone']),
      nbColis: serializer.fromJson<int>(json['nbColis']),
      poidsKg: serializer.fromJson<double?>(json['poidsKg']),
      statut: serializer.fromJson<String>(json['statut']),
      raisonEchec: serializer.fromJson<String?>(json['raisonEchec']),
      creeLe: serializer.fromJson<DateTime>(json['creeLe']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'stopId': serializer.toJson<int>(stopId),
      'expediteur': serializer.toJson<String>(expediteur),
      'refCode': serializer.toJson<String?>(refCode),
      'nomDestinataire': serializer.toJson<String?>(nomDestinataire),
      'telephone': serializer.toJson<String?>(telephone),
      'nbColis': serializer.toJson<int>(nbColis),
      'poidsKg': serializer.toJson<double?>(poidsKg),
      'statut': serializer.toJson<String>(statut),
      'raisonEchec': serializer.toJson<String?>(raisonEchec),
      'creeLe': serializer.toJson<DateTime>(creeLe),
    };
  }

  Sheet copyWith({
    int? id,
    int? stopId,
    String? expediteur,
    Value<String?> refCode = const Value.absent(),
    Value<String?> nomDestinataire = const Value.absent(),
    Value<String?> telephone = const Value.absent(),
    int? nbColis,
    Value<double?> poidsKg = const Value.absent(),
    String? statut,
    Value<String?> raisonEchec = const Value.absent(),
    DateTime? creeLe,
  }) => Sheet(
    id: id ?? this.id,
    stopId: stopId ?? this.stopId,
    expediteur: expediteur ?? this.expediteur,
    refCode: refCode.present ? refCode.value : this.refCode,
    nomDestinataire: nomDestinataire.present
        ? nomDestinataire.value
        : this.nomDestinataire,
    telephone: telephone.present ? telephone.value : this.telephone,
    nbColis: nbColis ?? this.nbColis,
    poidsKg: poidsKg.present ? poidsKg.value : this.poidsKg,
    statut: statut ?? this.statut,
    raisonEchec: raisonEchec.present ? raisonEchec.value : this.raisonEchec,
    creeLe: creeLe ?? this.creeLe,
  );
  Sheet copyWithCompanion(SheetsCompanion data) {
    return Sheet(
      id: data.id.present ? data.id.value : this.id,
      stopId: data.stopId.present ? data.stopId.value : this.stopId,
      expediteur: data.expediteur.present
          ? data.expediteur.value
          : this.expediteur,
      refCode: data.refCode.present ? data.refCode.value : this.refCode,
      nomDestinataire: data.nomDestinataire.present
          ? data.nomDestinataire.value
          : this.nomDestinataire,
      telephone: data.telephone.present ? data.telephone.value : this.telephone,
      nbColis: data.nbColis.present ? data.nbColis.value : this.nbColis,
      poidsKg: data.poidsKg.present ? data.poidsKg.value : this.poidsKg,
      statut: data.statut.present ? data.statut.value : this.statut,
      raisonEchec: data.raisonEchec.present
          ? data.raisonEchec.value
          : this.raisonEchec,
      creeLe: data.creeLe.present ? data.creeLe.value : this.creeLe,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Sheet(')
          ..write('id: $id, ')
          ..write('stopId: $stopId, ')
          ..write('expediteur: $expediteur, ')
          ..write('refCode: $refCode, ')
          ..write('nomDestinataire: $nomDestinataire, ')
          ..write('telephone: $telephone, ')
          ..write('nbColis: $nbColis, ')
          ..write('poidsKg: $poidsKg, ')
          ..write('statut: $statut, ')
          ..write('raisonEchec: $raisonEchec, ')
          ..write('creeLe: $creeLe')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    stopId,
    expediteur,
    refCode,
    nomDestinataire,
    telephone,
    nbColis,
    poidsKg,
    statut,
    raisonEchec,
    creeLe,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Sheet &&
          other.id == this.id &&
          other.stopId == this.stopId &&
          other.expediteur == this.expediteur &&
          other.refCode == this.refCode &&
          other.nomDestinataire == this.nomDestinataire &&
          other.telephone == this.telephone &&
          other.nbColis == this.nbColis &&
          other.poidsKg == this.poidsKg &&
          other.statut == this.statut &&
          other.raisonEchec == this.raisonEchec &&
          other.creeLe == this.creeLe);
}

class SheetsCompanion extends UpdateCompanion<Sheet> {
  final Value<int> id;
  final Value<int> stopId;
  final Value<String> expediteur;
  final Value<String?> refCode;
  final Value<String?> nomDestinataire;
  final Value<String?> telephone;
  final Value<int> nbColis;
  final Value<double?> poidsKg;
  final Value<String> statut;
  final Value<String?> raisonEchec;
  final Value<DateTime> creeLe;
  const SheetsCompanion({
    this.id = const Value.absent(),
    this.stopId = const Value.absent(),
    this.expediteur = const Value.absent(),
    this.refCode = const Value.absent(),
    this.nomDestinataire = const Value.absent(),
    this.telephone = const Value.absent(),
    this.nbColis = const Value.absent(),
    this.poidsKg = const Value.absent(),
    this.statut = const Value.absent(),
    this.raisonEchec = const Value.absent(),
    this.creeLe = const Value.absent(),
  });
  SheetsCompanion.insert({
    this.id = const Value.absent(),
    required int stopId,
    required String expediteur,
    this.refCode = const Value.absent(),
    this.nomDestinataire = const Value.absent(),
    this.telephone = const Value.absent(),
    this.nbColis = const Value.absent(),
    this.poidsKg = const Value.absent(),
    this.statut = const Value.absent(),
    this.raisonEchec = const Value.absent(),
    this.creeLe = const Value.absent(),
  }) : stopId = Value(stopId),
       expediteur = Value(expediteur);
  static Insertable<Sheet> custom({
    Expression<int>? id,
    Expression<int>? stopId,
    Expression<String>? expediteur,
    Expression<String>? refCode,
    Expression<String>? nomDestinataire,
    Expression<String>? telephone,
    Expression<int>? nbColis,
    Expression<double>? poidsKg,
    Expression<String>? statut,
    Expression<String>? raisonEchec,
    Expression<DateTime>? creeLe,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (stopId != null) 'stop_id': stopId,
      if (expediteur != null) 'expediteur': expediteur,
      if (refCode != null) 'ref_code': refCode,
      if (nomDestinataire != null) 'nom_destinataire': nomDestinataire,
      if (telephone != null) 'telephone': telephone,
      if (nbColis != null) 'nb_colis': nbColis,
      if (poidsKg != null) 'poids_kg': poidsKg,
      if (statut != null) 'statut': statut,
      if (raisonEchec != null) 'raison_echec': raisonEchec,
      if (creeLe != null) 'cree_le': creeLe,
    });
  }

  SheetsCompanion copyWith({
    Value<int>? id,
    Value<int>? stopId,
    Value<String>? expediteur,
    Value<String?>? refCode,
    Value<String?>? nomDestinataire,
    Value<String?>? telephone,
    Value<int>? nbColis,
    Value<double?>? poidsKg,
    Value<String>? statut,
    Value<String?>? raisonEchec,
    Value<DateTime>? creeLe,
  }) {
    return SheetsCompanion(
      id: id ?? this.id,
      stopId: stopId ?? this.stopId,
      expediteur: expediteur ?? this.expediteur,
      refCode: refCode ?? this.refCode,
      nomDestinataire: nomDestinataire ?? this.nomDestinataire,
      telephone: telephone ?? this.telephone,
      nbColis: nbColis ?? this.nbColis,
      poidsKg: poidsKg ?? this.poidsKg,
      statut: statut ?? this.statut,
      raisonEchec: raisonEchec ?? this.raisonEchec,
      creeLe: creeLe ?? this.creeLe,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (stopId.present) {
      map['stop_id'] = Variable<int>(stopId.value);
    }
    if (expediteur.present) {
      map['expediteur'] = Variable<String>(expediteur.value);
    }
    if (refCode.present) {
      map['ref_code'] = Variable<String>(refCode.value);
    }
    if (nomDestinataire.present) {
      map['nom_destinataire'] = Variable<String>(nomDestinataire.value);
    }
    if (telephone.present) {
      map['telephone'] = Variable<String>(telephone.value);
    }
    if (nbColis.present) {
      map['nb_colis'] = Variable<int>(nbColis.value);
    }
    if (poidsKg.present) {
      map['poids_kg'] = Variable<double>(poidsKg.value);
    }
    if (statut.present) {
      map['statut'] = Variable<String>(statut.value);
    }
    if (raisonEchec.present) {
      map['raison_echec'] = Variable<String>(raisonEchec.value);
    }
    if (creeLe.present) {
      map['cree_le'] = Variable<DateTime>(creeLe.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SheetsCompanion(')
          ..write('id: $id, ')
          ..write('stopId: $stopId, ')
          ..write('expediteur: $expediteur, ')
          ..write('refCode: $refCode, ')
          ..write('nomDestinataire: $nomDestinataire, ')
          ..write('telephone: $telephone, ')
          ..write('nbColis: $nbColis, ')
          ..write('poidsKg: $poidsKg, ')
          ..write('statut: $statut, ')
          ..write('raisonEchec: $raisonEchec, ')
          ..write('creeLe: $creeLe')
          ..write(')'))
        .toString();
  }
}

class $GeocodeCacheTable extends GeocodeCache
    with TableInfo<$GeocodeCacheTable, GeocodeCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GeocodeCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _queryMeta = const VerificationMeta('query');
  @override
  late final GeneratedColumn<String> query = GeneratedColumn<String>(
    'query',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _responseJsonMeta = const VerificationMeta(
    'responseJson',
  );
  @override
  late final GeneratedColumn<String> responseJson = GeneratedColumn<String>(
    'response_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expireLeMeta = const VerificationMeta(
    'expireLe',
  );
  @override
  late final GeneratedColumn<DateTime> expireLe = GeneratedColumn<DateTime>(
    'expire_le',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [query, responseJson, expireLe];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'geocode_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<GeocodeCacheData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('query')) {
      context.handle(
        _queryMeta,
        query.isAcceptableOrUnknown(data['query']!, _queryMeta),
      );
    } else if (isInserting) {
      context.missing(_queryMeta);
    }
    if (data.containsKey('response_json')) {
      context.handle(
        _responseJsonMeta,
        responseJson.isAcceptableOrUnknown(
          data['response_json']!,
          _responseJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_responseJsonMeta);
    }
    if (data.containsKey('expire_le')) {
      context.handle(
        _expireLeMeta,
        expireLe.isAcceptableOrUnknown(data['expire_le']!, _expireLeMeta),
      );
    } else if (isInserting) {
      context.missing(_expireLeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {query};
  @override
  GeocodeCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GeocodeCacheData(
      query: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}query'],
      )!,
      responseJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}response_json'],
      )!,
      expireLe: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expire_le'],
      )!,
    );
  }

  @override
  $GeocodeCacheTable createAlias(String alias) {
    return $GeocodeCacheTable(attachedDatabase, alias);
  }
}

class GeocodeCacheData extends DataClass
    implements Insertable<GeocodeCacheData> {
  final String query;
  final String responseJson;
  final DateTime expireLe;
  const GeocodeCacheData({
    required this.query,
    required this.responseJson,
    required this.expireLe,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['query'] = Variable<String>(query);
    map['response_json'] = Variable<String>(responseJson);
    map['expire_le'] = Variable<DateTime>(expireLe);
    return map;
  }

  GeocodeCacheCompanion toCompanion(bool nullToAbsent) {
    return GeocodeCacheCompanion(
      query: Value(query),
      responseJson: Value(responseJson),
      expireLe: Value(expireLe),
    );
  }

  factory GeocodeCacheData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GeocodeCacheData(
      query: serializer.fromJson<String>(json['query']),
      responseJson: serializer.fromJson<String>(json['responseJson']),
      expireLe: serializer.fromJson<DateTime>(json['expireLe']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'query': serializer.toJson<String>(query),
      'responseJson': serializer.toJson<String>(responseJson),
      'expireLe': serializer.toJson<DateTime>(expireLe),
    };
  }

  GeocodeCacheData copyWith({
    String? query,
    String? responseJson,
    DateTime? expireLe,
  }) => GeocodeCacheData(
    query: query ?? this.query,
    responseJson: responseJson ?? this.responseJson,
    expireLe: expireLe ?? this.expireLe,
  );
  GeocodeCacheData copyWithCompanion(GeocodeCacheCompanion data) {
    return GeocodeCacheData(
      query: data.query.present ? data.query.value : this.query,
      responseJson: data.responseJson.present
          ? data.responseJson.value
          : this.responseJson,
      expireLe: data.expireLe.present ? data.expireLe.value : this.expireLe,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GeocodeCacheData(')
          ..write('query: $query, ')
          ..write('responseJson: $responseJson, ')
          ..write('expireLe: $expireLe')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(query, responseJson, expireLe);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GeocodeCacheData &&
          other.query == this.query &&
          other.responseJson == this.responseJson &&
          other.expireLe == this.expireLe);
}

class GeocodeCacheCompanion extends UpdateCompanion<GeocodeCacheData> {
  final Value<String> query;
  final Value<String> responseJson;
  final Value<DateTime> expireLe;
  final Value<int> rowid;
  const GeocodeCacheCompanion({
    this.query = const Value.absent(),
    this.responseJson = const Value.absent(),
    this.expireLe = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GeocodeCacheCompanion.insert({
    required String query,
    required String responseJson,
    required DateTime expireLe,
    this.rowid = const Value.absent(),
  }) : query = Value(query),
       responseJson = Value(responseJson),
       expireLe = Value(expireLe);
  static Insertable<GeocodeCacheData> custom({
    Expression<String>? query,
    Expression<String>? responseJson,
    Expression<DateTime>? expireLe,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (query != null) 'query': query,
      if (responseJson != null) 'response_json': responseJson,
      if (expireLe != null) 'expire_le': expireLe,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GeocodeCacheCompanion copyWith({
    Value<String>? query,
    Value<String>? responseJson,
    Value<DateTime>? expireLe,
    Value<int>? rowid,
  }) {
    return GeocodeCacheCompanion(
      query: query ?? this.query,
      responseJson: responseJson ?? this.responseJson,
      expireLe: expireLe ?? this.expireLe,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (query.present) {
      map['query'] = Variable<String>(query.value);
    }
    if (responseJson.present) {
      map['response_json'] = Variable<String>(responseJson.value);
    }
    if (expireLe.present) {
      map['expire_le'] = Variable<DateTime>(expireLe.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GeocodeCacheCompanion(')
          ..write('query: $query, ')
          ..write('responseJson: $responseJson, ')
          ..write('expireLe: $expireLe, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SavedDestinationsTable extends SavedDestinations
    with TableInfo<$SavedDestinationsTable, SavedDestination> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavedDestinationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nomClientMeta = const VerificationMeta(
    'nomClient',
  );
  @override
  late final GeneratedColumn<String> nomClient = GeneratedColumn<String>(
    'nom_client',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _adresseDisplayMeta = const VerificationMeta(
    'adresseDisplay',
  );
  @override
  late final GeneratedColumn<String> adresseDisplay = GeneratedColumn<String>(
    'adresse_display',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lngMeta = const VerificationMeta('lng');
  @override
  late final GeneratedColumn<double> lng = GeneratedColumn<double>(
    'lng',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rueMeta = const VerificationMeta('rue');
  @override
  late final GeneratedColumn<String> rue = GeneratedColumn<String>(
    'rue',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _codePostalMeta = const VerificationMeta(
    'codePostal',
  );
  @override
  late final GeneratedColumn<String> codePostal = GeneratedColumn<String>(
    'code_postal',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _villeMeta = const VerificationMeta('ville');
  @override
  late final GeneratedColumn<String> ville = GeneratedColumn<String>(
    'ville',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _useCountMeta = const VerificationMeta(
    'useCount',
  );
  @override
  late final GeneratedColumn<int> useCount = GeneratedColumn<int>(
    'use_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _lastUsedAtMeta = const VerificationMeta(
    'lastUsedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastUsedAt = GeneratedColumn<DateTime>(
    'last_used_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _creeLeMeta = const VerificationMeta('creeLe');
  @override
  late final GeneratedColumn<DateTime> creeLe = GeneratedColumn<DateTime>(
    'cree_le',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _isFavoriMeta = const VerificationMeta(
    'isFavori',
  );
  @override
  late final GeneratedColumn<bool> isFavori = GeneratedColumn<bool>(
    'is_favori',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favori" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _colorTagMeta = const VerificationMeta(
    'colorTag',
  );
  @override
  late final GeneratedColumn<String> colorTag = GeneratedColumn<String>(
    'color_tag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesCarnetMeta = const VerificationMeta(
    'notesCarnet',
  );
  @override
  late final GeneratedColumn<String> notesCarnet = GeneratedColumn<String>(
    'notes_carnet',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tagsJsonMeta = const VerificationMeta(
    'tagsJson',
  );
  @override
  late final GeneratedColumn<String> tagsJson = GeneratedColumn<String>(
    'tags_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _photoPathMeta = const VerificationMeta(
    'photoPath',
  );
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
    'photo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _codeAccesMeta = const VerificationMeta(
    'codeAcces',
  );
  @override
  late final GeneratedColumn<String> codeAcces = GeneratedColumn<String>(
    'code_acces',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _etageBatimentMeta = const VerificationMeta(
    'etageBatiment',
  );
  @override
  late final GeneratedColumn<String> etageBatiment = GeneratedColumn<String>(
    'etage_batiment',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cloudIdMeta = const VerificationMeta(
    'cloudId',
  );
  @override
  late final GeneratedColumn<String> cloudId = GeneratedColumn<String>(
    'cloud_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nomClient,
    adresseDisplay,
    lat,
    lng,
    rue,
    codePostal,
    ville,
    useCount,
    lastUsedAt,
    creeLe,
    isFavori,
    colorTag,
    notesCarnet,
    tagsJson,
    photoPath,
    codeAcces,
    etageBatiment,
    cloudId,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_destinations';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavedDestination> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('nom_client')) {
      context.handle(
        _nomClientMeta,
        nomClient.isAcceptableOrUnknown(data['nom_client']!, _nomClientMeta),
      );
    }
    if (data.containsKey('adresse_display')) {
      context.handle(
        _adresseDisplayMeta,
        adresseDisplay.isAcceptableOrUnknown(
          data['adresse_display']!,
          _adresseDisplayMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_adresseDisplayMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lng')) {
      context.handle(
        _lngMeta,
        lng.isAcceptableOrUnknown(data['lng']!, _lngMeta),
      );
    } else if (isInserting) {
      context.missing(_lngMeta);
    }
    if (data.containsKey('rue')) {
      context.handle(
        _rueMeta,
        rue.isAcceptableOrUnknown(data['rue']!, _rueMeta),
      );
    }
    if (data.containsKey('code_postal')) {
      context.handle(
        _codePostalMeta,
        codePostal.isAcceptableOrUnknown(data['code_postal']!, _codePostalMeta),
      );
    }
    if (data.containsKey('ville')) {
      context.handle(
        _villeMeta,
        ville.isAcceptableOrUnknown(data['ville']!, _villeMeta),
      );
    }
    if (data.containsKey('use_count')) {
      context.handle(
        _useCountMeta,
        useCount.isAcceptableOrUnknown(data['use_count']!, _useCountMeta),
      );
    }
    if (data.containsKey('last_used_at')) {
      context.handle(
        _lastUsedAtMeta,
        lastUsedAt.isAcceptableOrUnknown(
          data['last_used_at']!,
          _lastUsedAtMeta,
        ),
      );
    }
    if (data.containsKey('cree_le')) {
      context.handle(
        _creeLeMeta,
        creeLe.isAcceptableOrUnknown(data['cree_le']!, _creeLeMeta),
      );
    }
    if (data.containsKey('is_favori')) {
      context.handle(
        _isFavoriMeta,
        isFavori.isAcceptableOrUnknown(data['is_favori']!, _isFavoriMeta),
      );
    }
    if (data.containsKey('color_tag')) {
      context.handle(
        _colorTagMeta,
        colorTag.isAcceptableOrUnknown(data['color_tag']!, _colorTagMeta),
      );
    }
    if (data.containsKey('notes_carnet')) {
      context.handle(
        _notesCarnetMeta,
        notesCarnet.isAcceptableOrUnknown(
          data['notes_carnet']!,
          _notesCarnetMeta,
        ),
      );
    }
    if (data.containsKey('tags_json')) {
      context.handle(
        _tagsJsonMeta,
        tagsJson.isAcceptableOrUnknown(data['tags_json']!, _tagsJsonMeta),
      );
    }
    if (data.containsKey('photo_path')) {
      context.handle(
        _photoPathMeta,
        photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta),
      );
    }
    if (data.containsKey('code_acces')) {
      context.handle(
        _codeAccesMeta,
        codeAcces.isAcceptableOrUnknown(data['code_acces']!, _codeAccesMeta),
      );
    }
    if (data.containsKey('etage_batiment')) {
      context.handle(
        _etageBatimentMeta,
        etageBatiment.isAcceptableOrUnknown(
          data['etage_batiment']!,
          _etageBatimentMeta,
        ),
      );
    }
    if (data.containsKey('cloud_id')) {
      context.handle(
        _cloudIdMeta,
        cloudId.isAcceptableOrUnknown(data['cloud_id']!, _cloudIdMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SavedDestination map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedDestination(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      nomClient: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nom_client'],
      ),
      adresseDisplay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}adresse_display'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lng'],
      )!,
      rue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rue'],
      ),
      codePostal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code_postal'],
      ),
      ville: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ville'],
      ),
      useCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}use_count'],
      )!,
      lastUsedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_used_at'],
      )!,
      creeLe: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cree_le'],
      )!,
      isFavori: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favori'],
      )!,
      colorTag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_tag'],
      ),
      notesCarnet: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes_carnet'],
      ),
      tagsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags_json'],
      ),
      photoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_path'],
      ),
      codeAcces: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code_acces'],
      ),
      etageBatiment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}etage_batiment'],
      ),
      cloudId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cloud_id'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SavedDestinationsTable createAlias(String alias) {
    return $SavedDestinationsTable(attachedDatabase, alias);
  }
}

class SavedDestination extends DataClass
    implements Insertable<SavedDestination> {
  final int id;

  /// Nom du client / enseigne (ex: "Garage Aguilar"). Optionnel : on
  /// accepte aussi une entree adresse seule.
  final String? nomClient;

  /// Libelle d'adresse complet pour affichage (ex: "51 Avenue
  /// d'Orleans, 28000 Chartres").
  final String adresseDisplay;
  final double lat;
  final double lng;
  final String? rue;
  final String? codePostal;
  final String? ville;
  final int useCount;
  final DateTime lastUsedAt;
  final DateTime creeLe;

  /// Marqueur "favori" choisi manuellement par l'utilisateur depuis
  /// l'ecran de detail du carnet. Les favoris remontent en haut de la
  /// liste, peu importe le useCount ou lastUsedAt. Sert a epingler
  /// les clients critiques / fragiles / a soigner.
  final bool isFavori;

  /// Couleur custom choisie pour repérer ce client visuellement (le
  /// fond de la pastille bookmark dans la liste prend cette couleur).
  /// Format : nom de la couleur dans la palette ('lime', 'emerald',
  /// 'red', 'amber', 'cream', 'ink'). Null = couleur par defaut
  /// (lime ou amber selon isFavori).
  final String? colorTag;

  /// Notes pre-definies par client : code interphone, instructions
  /// fragiles, heures preferees, etc. Affichees automatiquement comme
  /// notes du prochain arret cree pour ce client (pre-remplies dans le
  /// champ Notes de `AjoutArretScreen`). L'utilisateur peut les
  /// surcharger pour cet arret precis sans modifier le carnet.
  final String? notesCarnet;

  /// Liste de tags libres sous forme JSON (ex: '["pro","fragile"]').
  /// Null = aucun tag. L'UI filtre par tag dans la liste du carnet.
  final String? tagsJson;

  /// Chemin local d'une photo de la facade / interphone (aide visuelle
  /// a la livraison). Null si pas de photo. Stockee en
  /// `app_documents/carnet/<id>_<ts>.jpg`.
  final String? photoPath;

  /// Code d'acces (interphone, portail) — courant et explicite.
  /// Affiche en gros dans la fiche client. Optionnel.
  final String? codeAcces;

  /// Etage / batiment / appartement, separe du code pour pouvoir
  /// l'afficher en gros lui aussi. Ex: "Bat C, 3e etage, app. 12".
  final String? etageBatiment;

  /// UUID v4 attribue par l'app au 1er push Supabase (sous-jalon 2.B).
  /// Null = entree carnet jamais sync. Voir `Tournees.cloudId` pour le
  /// pattern.
  final String? cloudId;

  /// Timestamp de la derniere modification locale (sous-jalon 2.D-1c).
  /// Voir `Tournees.updatedAt` pour le pattern complet.
  ///
  /// Distinct de `lastUsedAt` (qui represente le dernier usage du
  /// carnet pour l'autocomplete, mis a jour automatiquement a chaque
  /// nouvel arret creant cette adresse) — `updatedAt` ne change que
  /// quand le contenu de la fiche elle-meme est edite (notes carnet,
  /// favori, color tag, photo, etc.). Sert au last-write-wins pull.
  final DateTime updatedAt;
  const SavedDestination({
    required this.id,
    this.nomClient,
    required this.adresseDisplay,
    required this.lat,
    required this.lng,
    this.rue,
    this.codePostal,
    this.ville,
    required this.useCount,
    required this.lastUsedAt,
    required this.creeLe,
    required this.isFavori,
    this.colorTag,
    this.notesCarnet,
    this.tagsJson,
    this.photoPath,
    this.codeAcces,
    this.etageBatiment,
    this.cloudId,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || nomClient != null) {
      map['nom_client'] = Variable<String>(nomClient);
    }
    map['adresse_display'] = Variable<String>(adresseDisplay);
    map['lat'] = Variable<double>(lat);
    map['lng'] = Variable<double>(lng);
    if (!nullToAbsent || rue != null) {
      map['rue'] = Variable<String>(rue);
    }
    if (!nullToAbsent || codePostal != null) {
      map['code_postal'] = Variable<String>(codePostal);
    }
    if (!nullToAbsent || ville != null) {
      map['ville'] = Variable<String>(ville);
    }
    map['use_count'] = Variable<int>(useCount);
    map['last_used_at'] = Variable<DateTime>(lastUsedAt);
    map['cree_le'] = Variable<DateTime>(creeLe);
    map['is_favori'] = Variable<bool>(isFavori);
    if (!nullToAbsent || colorTag != null) {
      map['color_tag'] = Variable<String>(colorTag);
    }
    if (!nullToAbsent || notesCarnet != null) {
      map['notes_carnet'] = Variable<String>(notesCarnet);
    }
    if (!nullToAbsent || tagsJson != null) {
      map['tags_json'] = Variable<String>(tagsJson);
    }
    if (!nullToAbsent || photoPath != null) {
      map['photo_path'] = Variable<String>(photoPath);
    }
    if (!nullToAbsent || codeAcces != null) {
      map['code_acces'] = Variable<String>(codeAcces);
    }
    if (!nullToAbsent || etageBatiment != null) {
      map['etage_batiment'] = Variable<String>(etageBatiment);
    }
    if (!nullToAbsent || cloudId != null) {
      map['cloud_id'] = Variable<String>(cloudId);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SavedDestinationsCompanion toCompanion(bool nullToAbsent) {
    return SavedDestinationsCompanion(
      id: Value(id),
      nomClient: nomClient == null && nullToAbsent
          ? const Value.absent()
          : Value(nomClient),
      adresseDisplay: Value(adresseDisplay),
      lat: Value(lat),
      lng: Value(lng),
      rue: rue == null && nullToAbsent ? const Value.absent() : Value(rue),
      codePostal: codePostal == null && nullToAbsent
          ? const Value.absent()
          : Value(codePostal),
      ville: ville == null && nullToAbsent
          ? const Value.absent()
          : Value(ville),
      useCount: Value(useCount),
      lastUsedAt: Value(lastUsedAt),
      creeLe: Value(creeLe),
      isFavori: Value(isFavori),
      colorTag: colorTag == null && nullToAbsent
          ? const Value.absent()
          : Value(colorTag),
      notesCarnet: notesCarnet == null && nullToAbsent
          ? const Value.absent()
          : Value(notesCarnet),
      tagsJson: tagsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(tagsJson),
      photoPath: photoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoPath),
      codeAcces: codeAcces == null && nullToAbsent
          ? const Value.absent()
          : Value(codeAcces),
      etageBatiment: etageBatiment == null && nullToAbsent
          ? const Value.absent()
          : Value(etageBatiment),
      cloudId: cloudId == null && nullToAbsent
          ? const Value.absent()
          : Value(cloudId),
      updatedAt: Value(updatedAt),
    );
  }

  factory SavedDestination.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedDestination(
      id: serializer.fromJson<int>(json['id']),
      nomClient: serializer.fromJson<String?>(json['nomClient']),
      adresseDisplay: serializer.fromJson<String>(json['adresseDisplay']),
      lat: serializer.fromJson<double>(json['lat']),
      lng: serializer.fromJson<double>(json['lng']),
      rue: serializer.fromJson<String?>(json['rue']),
      codePostal: serializer.fromJson<String?>(json['codePostal']),
      ville: serializer.fromJson<String?>(json['ville']),
      useCount: serializer.fromJson<int>(json['useCount']),
      lastUsedAt: serializer.fromJson<DateTime>(json['lastUsedAt']),
      creeLe: serializer.fromJson<DateTime>(json['creeLe']),
      isFavori: serializer.fromJson<bool>(json['isFavori']),
      colorTag: serializer.fromJson<String?>(json['colorTag']),
      notesCarnet: serializer.fromJson<String?>(json['notesCarnet']),
      tagsJson: serializer.fromJson<String?>(json['tagsJson']),
      photoPath: serializer.fromJson<String?>(json['photoPath']),
      codeAcces: serializer.fromJson<String?>(json['codeAcces']),
      etageBatiment: serializer.fromJson<String?>(json['etageBatiment']),
      cloudId: serializer.fromJson<String?>(json['cloudId']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nomClient': serializer.toJson<String?>(nomClient),
      'adresseDisplay': serializer.toJson<String>(adresseDisplay),
      'lat': serializer.toJson<double>(lat),
      'lng': serializer.toJson<double>(lng),
      'rue': serializer.toJson<String?>(rue),
      'codePostal': serializer.toJson<String?>(codePostal),
      'ville': serializer.toJson<String?>(ville),
      'useCount': serializer.toJson<int>(useCount),
      'lastUsedAt': serializer.toJson<DateTime>(lastUsedAt),
      'creeLe': serializer.toJson<DateTime>(creeLe),
      'isFavori': serializer.toJson<bool>(isFavori),
      'colorTag': serializer.toJson<String?>(colorTag),
      'notesCarnet': serializer.toJson<String?>(notesCarnet),
      'tagsJson': serializer.toJson<String?>(tagsJson),
      'photoPath': serializer.toJson<String?>(photoPath),
      'codeAcces': serializer.toJson<String?>(codeAcces),
      'etageBatiment': serializer.toJson<String?>(etageBatiment),
      'cloudId': serializer.toJson<String?>(cloudId),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SavedDestination copyWith({
    int? id,
    Value<String?> nomClient = const Value.absent(),
    String? adresseDisplay,
    double? lat,
    double? lng,
    Value<String?> rue = const Value.absent(),
    Value<String?> codePostal = const Value.absent(),
    Value<String?> ville = const Value.absent(),
    int? useCount,
    DateTime? lastUsedAt,
    DateTime? creeLe,
    bool? isFavori,
    Value<String?> colorTag = const Value.absent(),
    Value<String?> notesCarnet = const Value.absent(),
    Value<String?> tagsJson = const Value.absent(),
    Value<String?> photoPath = const Value.absent(),
    Value<String?> codeAcces = const Value.absent(),
    Value<String?> etageBatiment = const Value.absent(),
    Value<String?> cloudId = const Value.absent(),
    DateTime? updatedAt,
  }) => SavedDestination(
    id: id ?? this.id,
    nomClient: nomClient.present ? nomClient.value : this.nomClient,
    adresseDisplay: adresseDisplay ?? this.adresseDisplay,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    rue: rue.present ? rue.value : this.rue,
    codePostal: codePostal.present ? codePostal.value : this.codePostal,
    ville: ville.present ? ville.value : this.ville,
    useCount: useCount ?? this.useCount,
    lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    creeLe: creeLe ?? this.creeLe,
    isFavori: isFavori ?? this.isFavori,
    colorTag: colorTag.present ? colorTag.value : this.colorTag,
    notesCarnet: notesCarnet.present ? notesCarnet.value : this.notesCarnet,
    tagsJson: tagsJson.present ? tagsJson.value : this.tagsJson,
    photoPath: photoPath.present ? photoPath.value : this.photoPath,
    codeAcces: codeAcces.present ? codeAcces.value : this.codeAcces,
    etageBatiment: etageBatiment.present
        ? etageBatiment.value
        : this.etageBatiment,
    cloudId: cloudId.present ? cloudId.value : this.cloudId,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SavedDestination copyWithCompanion(SavedDestinationsCompanion data) {
    return SavedDestination(
      id: data.id.present ? data.id.value : this.id,
      nomClient: data.nomClient.present ? data.nomClient.value : this.nomClient,
      adresseDisplay: data.adresseDisplay.present
          ? data.adresseDisplay.value
          : this.adresseDisplay,
      lat: data.lat.present ? data.lat.value : this.lat,
      lng: data.lng.present ? data.lng.value : this.lng,
      rue: data.rue.present ? data.rue.value : this.rue,
      codePostal: data.codePostal.present
          ? data.codePostal.value
          : this.codePostal,
      ville: data.ville.present ? data.ville.value : this.ville,
      useCount: data.useCount.present ? data.useCount.value : this.useCount,
      lastUsedAt: data.lastUsedAt.present
          ? data.lastUsedAt.value
          : this.lastUsedAt,
      creeLe: data.creeLe.present ? data.creeLe.value : this.creeLe,
      isFavori: data.isFavori.present ? data.isFavori.value : this.isFavori,
      colorTag: data.colorTag.present ? data.colorTag.value : this.colorTag,
      notesCarnet: data.notesCarnet.present
          ? data.notesCarnet.value
          : this.notesCarnet,
      tagsJson: data.tagsJson.present ? data.tagsJson.value : this.tagsJson,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
      codeAcces: data.codeAcces.present ? data.codeAcces.value : this.codeAcces,
      etageBatiment: data.etageBatiment.present
          ? data.etageBatiment.value
          : this.etageBatiment,
      cloudId: data.cloudId.present ? data.cloudId.value : this.cloudId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedDestination(')
          ..write('id: $id, ')
          ..write('nomClient: $nomClient, ')
          ..write('adresseDisplay: $adresseDisplay, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('rue: $rue, ')
          ..write('codePostal: $codePostal, ')
          ..write('ville: $ville, ')
          ..write('useCount: $useCount, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('creeLe: $creeLe, ')
          ..write('isFavori: $isFavori, ')
          ..write('colorTag: $colorTag, ')
          ..write('notesCarnet: $notesCarnet, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('photoPath: $photoPath, ')
          ..write('codeAcces: $codeAcces, ')
          ..write('etageBatiment: $etageBatiment, ')
          ..write('cloudId: $cloudId, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    nomClient,
    adresseDisplay,
    lat,
    lng,
    rue,
    codePostal,
    ville,
    useCount,
    lastUsedAt,
    creeLe,
    isFavori,
    colorTag,
    notesCarnet,
    tagsJson,
    photoPath,
    codeAcces,
    etageBatiment,
    cloudId,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedDestination &&
          other.id == this.id &&
          other.nomClient == this.nomClient &&
          other.adresseDisplay == this.adresseDisplay &&
          other.lat == this.lat &&
          other.lng == this.lng &&
          other.rue == this.rue &&
          other.codePostal == this.codePostal &&
          other.ville == this.ville &&
          other.useCount == this.useCount &&
          other.lastUsedAt == this.lastUsedAt &&
          other.creeLe == this.creeLe &&
          other.isFavori == this.isFavori &&
          other.colorTag == this.colorTag &&
          other.notesCarnet == this.notesCarnet &&
          other.tagsJson == this.tagsJson &&
          other.photoPath == this.photoPath &&
          other.codeAcces == this.codeAcces &&
          other.etageBatiment == this.etageBatiment &&
          other.cloudId == this.cloudId &&
          other.updatedAt == this.updatedAt);
}

class SavedDestinationsCompanion extends UpdateCompanion<SavedDestination> {
  final Value<int> id;
  final Value<String?> nomClient;
  final Value<String> adresseDisplay;
  final Value<double> lat;
  final Value<double> lng;
  final Value<String?> rue;
  final Value<String?> codePostal;
  final Value<String?> ville;
  final Value<int> useCount;
  final Value<DateTime> lastUsedAt;
  final Value<DateTime> creeLe;
  final Value<bool> isFavori;
  final Value<String?> colorTag;
  final Value<String?> notesCarnet;
  final Value<String?> tagsJson;
  final Value<String?> photoPath;
  final Value<String?> codeAcces;
  final Value<String?> etageBatiment;
  final Value<String?> cloudId;
  final Value<DateTime> updatedAt;
  const SavedDestinationsCompanion({
    this.id = const Value.absent(),
    this.nomClient = const Value.absent(),
    this.adresseDisplay = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.rue = const Value.absent(),
    this.codePostal = const Value.absent(),
    this.ville = const Value.absent(),
    this.useCount = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    this.creeLe = const Value.absent(),
    this.isFavori = const Value.absent(),
    this.colorTag = const Value.absent(),
    this.notesCarnet = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.codeAcces = const Value.absent(),
    this.etageBatiment = const Value.absent(),
    this.cloudId = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SavedDestinationsCompanion.insert({
    this.id = const Value.absent(),
    this.nomClient = const Value.absent(),
    required String adresseDisplay,
    required double lat,
    required double lng,
    this.rue = const Value.absent(),
    this.codePostal = const Value.absent(),
    this.ville = const Value.absent(),
    this.useCount = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    this.creeLe = const Value.absent(),
    this.isFavori = const Value.absent(),
    this.colorTag = const Value.absent(),
    this.notesCarnet = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.codeAcces = const Value.absent(),
    this.etageBatiment = const Value.absent(),
    this.cloudId = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : adresseDisplay = Value(adresseDisplay),
       lat = Value(lat),
       lng = Value(lng);
  static Insertable<SavedDestination> custom({
    Expression<int>? id,
    Expression<String>? nomClient,
    Expression<String>? adresseDisplay,
    Expression<double>? lat,
    Expression<double>? lng,
    Expression<String>? rue,
    Expression<String>? codePostal,
    Expression<String>? ville,
    Expression<int>? useCount,
    Expression<DateTime>? lastUsedAt,
    Expression<DateTime>? creeLe,
    Expression<bool>? isFavori,
    Expression<String>? colorTag,
    Expression<String>? notesCarnet,
    Expression<String>? tagsJson,
    Expression<String>? photoPath,
    Expression<String>? codeAcces,
    Expression<String>? etageBatiment,
    Expression<String>? cloudId,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nomClient != null) 'nom_client': nomClient,
      if (adresseDisplay != null) 'adresse_display': adresseDisplay,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (rue != null) 'rue': rue,
      if (codePostal != null) 'code_postal': codePostal,
      if (ville != null) 'ville': ville,
      if (useCount != null) 'use_count': useCount,
      if (lastUsedAt != null) 'last_used_at': lastUsedAt,
      if (creeLe != null) 'cree_le': creeLe,
      if (isFavori != null) 'is_favori': isFavori,
      if (colorTag != null) 'color_tag': colorTag,
      if (notesCarnet != null) 'notes_carnet': notesCarnet,
      if (tagsJson != null) 'tags_json': tagsJson,
      if (photoPath != null) 'photo_path': photoPath,
      if (codeAcces != null) 'code_acces': codeAcces,
      if (etageBatiment != null) 'etage_batiment': etageBatiment,
      if (cloudId != null) 'cloud_id': cloudId,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SavedDestinationsCompanion copyWith({
    Value<int>? id,
    Value<String?>? nomClient,
    Value<String>? adresseDisplay,
    Value<double>? lat,
    Value<double>? lng,
    Value<String?>? rue,
    Value<String?>? codePostal,
    Value<String?>? ville,
    Value<int>? useCount,
    Value<DateTime>? lastUsedAt,
    Value<DateTime>? creeLe,
    Value<bool>? isFavori,
    Value<String?>? colorTag,
    Value<String?>? notesCarnet,
    Value<String?>? tagsJson,
    Value<String?>? photoPath,
    Value<String?>? codeAcces,
    Value<String?>? etageBatiment,
    Value<String?>? cloudId,
    Value<DateTime>? updatedAt,
  }) {
    return SavedDestinationsCompanion(
      id: id ?? this.id,
      nomClient: nomClient ?? this.nomClient,
      adresseDisplay: adresseDisplay ?? this.adresseDisplay,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      rue: rue ?? this.rue,
      codePostal: codePostal ?? this.codePostal,
      ville: ville ?? this.ville,
      useCount: useCount ?? this.useCount,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      creeLe: creeLe ?? this.creeLe,
      isFavori: isFavori ?? this.isFavori,
      colorTag: colorTag ?? this.colorTag,
      notesCarnet: notesCarnet ?? this.notesCarnet,
      tagsJson: tagsJson ?? this.tagsJson,
      photoPath: photoPath ?? this.photoPath,
      codeAcces: codeAcces ?? this.codeAcces,
      etageBatiment: etageBatiment ?? this.etageBatiment,
      cloudId: cloudId ?? this.cloudId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nomClient.present) {
      map['nom_client'] = Variable<String>(nomClient.value);
    }
    if (adresseDisplay.present) {
      map['adresse_display'] = Variable<String>(adresseDisplay.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lng.present) {
      map['lng'] = Variable<double>(lng.value);
    }
    if (rue.present) {
      map['rue'] = Variable<String>(rue.value);
    }
    if (codePostal.present) {
      map['code_postal'] = Variable<String>(codePostal.value);
    }
    if (ville.present) {
      map['ville'] = Variable<String>(ville.value);
    }
    if (useCount.present) {
      map['use_count'] = Variable<int>(useCount.value);
    }
    if (lastUsedAt.present) {
      map['last_used_at'] = Variable<DateTime>(lastUsedAt.value);
    }
    if (creeLe.present) {
      map['cree_le'] = Variable<DateTime>(creeLe.value);
    }
    if (isFavori.present) {
      map['is_favori'] = Variable<bool>(isFavori.value);
    }
    if (colorTag.present) {
      map['color_tag'] = Variable<String>(colorTag.value);
    }
    if (notesCarnet.present) {
      map['notes_carnet'] = Variable<String>(notesCarnet.value);
    }
    if (tagsJson.present) {
      map['tags_json'] = Variable<String>(tagsJson.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (codeAcces.present) {
      map['code_acces'] = Variable<String>(codeAcces.value);
    }
    if (etageBatiment.present) {
      map['etage_batiment'] = Variable<String>(etageBatiment.value);
    }
    if (cloudId.present) {
      map['cloud_id'] = Variable<String>(cloudId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavedDestinationsCompanion(')
          ..write('id: $id, ')
          ..write('nomClient: $nomClient, ')
          ..write('adresseDisplay: $adresseDisplay, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('rue: $rue, ')
          ..write('codePostal: $codePostal, ')
          ..write('ville: $ville, ')
          ..write('useCount: $useCount, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('creeLe: $creeLe, ')
          ..write('isFavori: $isFavori, ')
          ..write('colorTag: $colorTag, ')
          ..write('notesCarnet: $notesCarnet, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('photoPath: $photoPath, ')
          ..write('codeAcces: $codeAcces, ')
          ..write('etageBatiment: $etageBatiment, ')
          ..write('cloudId: $cloudId, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $StopHistoryTable extends StopHistory
    with TableInfo<$StopHistoryTable, StopHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StopHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _stopIdMeta = const VerificationMeta('stopId');
  @override
  late final GeneratedColumn<int> stopId = GeneratedColumn<int>(
    'stop_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES stops (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fromStatusMeta = const VerificationMeta(
    'fromStatus',
  );
  @override
  late final GeneratedColumn<String> fromStatus = GeneratedColumn<String>(
    'from_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toStatusMeta = const VerificationMeta(
    'toStatus',
  );
  @override
  late final GeneratedColumn<String> toStatus = GeneratedColumn<String>(
    'to_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _raisonMeta = const VerificationMeta('raison');
  @override
  late final GeneratedColumn<String> raison = GeneratedColumn<String>(
    'raison',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    stopId,
    action,
    fromStatus,
    toStatus,
    raison,
    timestamp,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stop_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<StopHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('stop_id')) {
      context.handle(
        _stopIdMeta,
        stopId.isAcceptableOrUnknown(data['stop_id']!, _stopIdMeta),
      );
    } else if (isInserting) {
      context.missing(_stopIdMeta);
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('from_status')) {
      context.handle(
        _fromStatusMeta,
        fromStatus.isAcceptableOrUnknown(data['from_status']!, _fromStatusMeta),
      );
    } else if (isInserting) {
      context.missing(_fromStatusMeta);
    }
    if (data.containsKey('to_status')) {
      context.handle(
        _toStatusMeta,
        toStatus.isAcceptableOrUnknown(data['to_status']!, _toStatusMeta),
      );
    } else if (isInserting) {
      context.missing(_toStatusMeta);
    }
    if (data.containsKey('raison')) {
      context.handle(
        _raisonMeta,
        raison.isAcceptableOrUnknown(data['raison']!, _raisonMeta),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StopHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StopHistoryData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      stopId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stop_id'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      fromStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_status'],
      )!,
      toStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_status'],
      )!,
      raison: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raison'],
      ),
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
    );
  }

  @override
  $StopHistoryTable createAlias(String alias) {
    return $StopHistoryTable(attachedDatabase, alias);
  }
}

class StopHistoryData extends DataClass implements Insertable<StopHistoryData> {
  final int id;
  final int stopId;

  /// Action effectuee. Valeurs : 'mark_livre' / 'mark_echec' /
  /// 'mark_a_livrer'.
  final String action;

  /// Statut precedent ('a_livrer' / 'livre' / 'echec').
  final String fromStatus;

  /// Statut apres l'action.
  final String toStatus;

  /// Raison d'echec saisie pour 'mark_echec'. Null sinon.
  final String? raison;
  final DateTime timestamp;
  const StopHistoryData({
    required this.id,
    required this.stopId,
    required this.action,
    required this.fromStatus,
    required this.toStatus,
    this.raison,
    required this.timestamp,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['stop_id'] = Variable<int>(stopId);
    map['action'] = Variable<String>(action);
    map['from_status'] = Variable<String>(fromStatus);
    map['to_status'] = Variable<String>(toStatus);
    if (!nullToAbsent || raison != null) {
      map['raison'] = Variable<String>(raison);
    }
    map['timestamp'] = Variable<DateTime>(timestamp);
    return map;
  }

  StopHistoryCompanion toCompanion(bool nullToAbsent) {
    return StopHistoryCompanion(
      id: Value(id),
      stopId: Value(stopId),
      action: Value(action),
      fromStatus: Value(fromStatus),
      toStatus: Value(toStatus),
      raison: raison == null && nullToAbsent
          ? const Value.absent()
          : Value(raison),
      timestamp: Value(timestamp),
    );
  }

  factory StopHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StopHistoryData(
      id: serializer.fromJson<int>(json['id']),
      stopId: serializer.fromJson<int>(json['stopId']),
      action: serializer.fromJson<String>(json['action']),
      fromStatus: serializer.fromJson<String>(json['fromStatus']),
      toStatus: serializer.fromJson<String>(json['toStatus']),
      raison: serializer.fromJson<String?>(json['raison']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'stopId': serializer.toJson<int>(stopId),
      'action': serializer.toJson<String>(action),
      'fromStatus': serializer.toJson<String>(fromStatus),
      'toStatus': serializer.toJson<String>(toStatus),
      'raison': serializer.toJson<String?>(raison),
      'timestamp': serializer.toJson<DateTime>(timestamp),
    };
  }

  StopHistoryData copyWith({
    int? id,
    int? stopId,
    String? action,
    String? fromStatus,
    String? toStatus,
    Value<String?> raison = const Value.absent(),
    DateTime? timestamp,
  }) => StopHistoryData(
    id: id ?? this.id,
    stopId: stopId ?? this.stopId,
    action: action ?? this.action,
    fromStatus: fromStatus ?? this.fromStatus,
    toStatus: toStatus ?? this.toStatus,
    raison: raison.present ? raison.value : this.raison,
    timestamp: timestamp ?? this.timestamp,
  );
  StopHistoryData copyWithCompanion(StopHistoryCompanion data) {
    return StopHistoryData(
      id: data.id.present ? data.id.value : this.id,
      stopId: data.stopId.present ? data.stopId.value : this.stopId,
      action: data.action.present ? data.action.value : this.action,
      fromStatus: data.fromStatus.present
          ? data.fromStatus.value
          : this.fromStatus,
      toStatus: data.toStatus.present ? data.toStatus.value : this.toStatus,
      raison: data.raison.present ? data.raison.value : this.raison,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StopHistoryData(')
          ..write('id: $id, ')
          ..write('stopId: $stopId, ')
          ..write('action: $action, ')
          ..write('fromStatus: $fromStatus, ')
          ..write('toStatus: $toStatus, ')
          ..write('raison: $raison, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, stopId, action, fromStatus, toStatus, raison, timestamp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StopHistoryData &&
          other.id == this.id &&
          other.stopId == this.stopId &&
          other.action == this.action &&
          other.fromStatus == this.fromStatus &&
          other.toStatus == this.toStatus &&
          other.raison == this.raison &&
          other.timestamp == this.timestamp);
}

class StopHistoryCompanion extends UpdateCompanion<StopHistoryData> {
  final Value<int> id;
  final Value<int> stopId;
  final Value<String> action;
  final Value<String> fromStatus;
  final Value<String> toStatus;
  final Value<String?> raison;
  final Value<DateTime> timestamp;
  const StopHistoryCompanion({
    this.id = const Value.absent(),
    this.stopId = const Value.absent(),
    this.action = const Value.absent(),
    this.fromStatus = const Value.absent(),
    this.toStatus = const Value.absent(),
    this.raison = const Value.absent(),
    this.timestamp = const Value.absent(),
  });
  StopHistoryCompanion.insert({
    this.id = const Value.absent(),
    required int stopId,
    required String action,
    required String fromStatus,
    required String toStatus,
    this.raison = const Value.absent(),
    this.timestamp = const Value.absent(),
  }) : stopId = Value(stopId),
       action = Value(action),
       fromStatus = Value(fromStatus),
       toStatus = Value(toStatus);
  static Insertable<StopHistoryData> custom({
    Expression<int>? id,
    Expression<int>? stopId,
    Expression<String>? action,
    Expression<String>? fromStatus,
    Expression<String>? toStatus,
    Expression<String>? raison,
    Expression<DateTime>? timestamp,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (stopId != null) 'stop_id': stopId,
      if (action != null) 'action': action,
      if (fromStatus != null) 'from_status': fromStatus,
      if (toStatus != null) 'to_status': toStatus,
      if (raison != null) 'raison': raison,
      if (timestamp != null) 'timestamp': timestamp,
    });
  }

  StopHistoryCompanion copyWith({
    Value<int>? id,
    Value<int>? stopId,
    Value<String>? action,
    Value<String>? fromStatus,
    Value<String>? toStatus,
    Value<String?>? raison,
    Value<DateTime>? timestamp,
  }) {
    return StopHistoryCompanion(
      id: id ?? this.id,
      stopId: stopId ?? this.stopId,
      action: action ?? this.action,
      fromStatus: fromStatus ?? this.fromStatus,
      toStatus: toStatus ?? this.toStatus,
      raison: raison ?? this.raison,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (stopId.present) {
      map['stop_id'] = Variable<int>(stopId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (fromStatus.present) {
      map['from_status'] = Variable<String>(fromStatus.value);
    }
    if (toStatus.present) {
      map['to_status'] = Variable<String>(toStatus.value);
    }
    if (raison.present) {
      map['raison'] = Variable<String>(raison.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StopHistoryCompanion(')
          ..write('id: $id, ')
          ..write('stopId: $stopId, ')
          ..write('action: $action, ')
          ..write('fromStatus: $fromStatus, ')
          ..write('toStatus: $toStatus, ')
          ..write('raison: $raison, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }
}

class $CoequipiersTable extends Coequipiers
    with TableInfo<$CoequipiersTable, Coequipier> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CoequipiersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nomMeta = const VerificationMeta('nom');
  @override
  late final GeneratedColumn<String> nom = GeneratedColumn<String>(
    'nom',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 20,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorTagMeta = const VerificationMeta(
    'colorTag',
  );
  @override
  late final GeneratedColumn<String> colorTag = GeneratedColumn<String>(
    'color_tag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _telephoneMeta = const VerificationMeta(
    'telephone',
  );
  @override
  late final GeneratedColumn<String> telephone = GeneratedColumn<String>(
    'telephone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actifMeta = const VerificationMeta('actif');
  @override
  late final GeneratedColumn<bool> actif = GeneratedColumn<bool>(
    'actif',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("actif" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _creeLeMeta = const VerificationMeta('creeLe');
  @override
  late final GeneratedColumn<DateTime> creeLe = GeneratedColumn<DateTime>(
    'cree_le',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _cloudIdMeta = const VerificationMeta(
    'cloudId',
  );
  @override
  late final GeneratedColumn<String> cloudId = GeneratedColumn<String>(
    'cloud_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nom,
    colorTag,
    telephone,
    actif,
    creeLe,
    cloudId,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'coequipiers';
  @override
  VerificationContext validateIntegrity(
    Insertable<Coequipier> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('nom')) {
      context.handle(
        _nomMeta,
        nom.isAcceptableOrUnknown(data['nom']!, _nomMeta),
      );
    } else if (isInserting) {
      context.missing(_nomMeta);
    }
    if (data.containsKey('color_tag')) {
      context.handle(
        _colorTagMeta,
        colorTag.isAcceptableOrUnknown(data['color_tag']!, _colorTagMeta),
      );
    }
    if (data.containsKey('telephone')) {
      context.handle(
        _telephoneMeta,
        telephone.isAcceptableOrUnknown(data['telephone']!, _telephoneMeta),
      );
    }
    if (data.containsKey('actif')) {
      context.handle(
        _actifMeta,
        actif.isAcceptableOrUnknown(data['actif']!, _actifMeta),
      );
    }
    if (data.containsKey('cree_le')) {
      context.handle(
        _creeLeMeta,
        creeLe.isAcceptableOrUnknown(data['cree_le']!, _creeLeMeta),
      );
    }
    if (data.containsKey('cloud_id')) {
      context.handle(
        _cloudIdMeta,
        cloudId.isAcceptableOrUnknown(data['cloud_id']!, _cloudIdMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Coequipier map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Coequipier(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      nom: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nom'],
      )!,
      colorTag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_tag'],
      ),
      telephone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}telephone'],
      ),
      actif: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}actif'],
      )!,
      creeLe: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cree_le'],
      )!,
      cloudId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cloud_id'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CoequipiersTable createAlias(String alias) {
    return $CoequipiersTable(attachedDatabase, alias);
  }
}

class Coequipier extends DataClass implements Insertable<Coequipier> {
  final int id;

  /// Nom court a afficher en badge (ex: "Papa", "Lucas", "Maman").
  /// Max 20 chars pour tenir dans les chips/avatars sans wrap.
  final String nom;

  /// Couleur du tag pour l'avatar (cle dans `colorFromTag` :
  /// 'lime' / 'emerald' / 'amber' / 'red' / 'cream' / 'ink').
  /// Null = couleur par defaut (cream).
  final String? colorTag;

  /// Telephone (optionnel) pour le partage de tournee via SMS / WhatsApp.
  final String? telephone;

  /// Vrai = visible dans le selecteur. Faux = archive (ancien aidant
  /// qui ne livre plus avec Noah). On garde l'entree en base pour
  /// preserver l'historique des stats.
  final bool actif;
  final DateTime creeLe;

  /// UUID v4 attribue par l'app au 1er push Supabase (sous-jalon 2.B).
  /// Null = coequipier jamais sync. Voir `Tournees.cloudId` pour le
  /// pattern.
  final String? cloudId;

  /// Timestamp de la derniere modification locale (sous-jalon 2.D-1c).
  /// Voir `Tournees.updatedAt` pour le pattern complet.
  final DateTime updatedAt;
  const Coequipier({
    required this.id,
    required this.nom,
    this.colorTag,
    this.telephone,
    required this.actif,
    required this.creeLe,
    this.cloudId,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['nom'] = Variable<String>(nom);
    if (!nullToAbsent || colorTag != null) {
      map['color_tag'] = Variable<String>(colorTag);
    }
    if (!nullToAbsent || telephone != null) {
      map['telephone'] = Variable<String>(telephone);
    }
    map['actif'] = Variable<bool>(actif);
    map['cree_le'] = Variable<DateTime>(creeLe);
    if (!nullToAbsent || cloudId != null) {
      map['cloud_id'] = Variable<String>(cloudId);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CoequipiersCompanion toCompanion(bool nullToAbsent) {
    return CoequipiersCompanion(
      id: Value(id),
      nom: Value(nom),
      colorTag: colorTag == null && nullToAbsent
          ? const Value.absent()
          : Value(colorTag),
      telephone: telephone == null && nullToAbsent
          ? const Value.absent()
          : Value(telephone),
      actif: Value(actif),
      creeLe: Value(creeLe),
      cloudId: cloudId == null && nullToAbsent
          ? const Value.absent()
          : Value(cloudId),
      updatedAt: Value(updatedAt),
    );
  }

  factory Coequipier.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Coequipier(
      id: serializer.fromJson<int>(json['id']),
      nom: serializer.fromJson<String>(json['nom']),
      colorTag: serializer.fromJson<String?>(json['colorTag']),
      telephone: serializer.fromJson<String?>(json['telephone']),
      actif: serializer.fromJson<bool>(json['actif']),
      creeLe: serializer.fromJson<DateTime>(json['creeLe']),
      cloudId: serializer.fromJson<String?>(json['cloudId']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nom': serializer.toJson<String>(nom),
      'colorTag': serializer.toJson<String?>(colorTag),
      'telephone': serializer.toJson<String?>(telephone),
      'actif': serializer.toJson<bool>(actif),
      'creeLe': serializer.toJson<DateTime>(creeLe),
      'cloudId': serializer.toJson<String?>(cloudId),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Coequipier copyWith({
    int? id,
    String? nom,
    Value<String?> colorTag = const Value.absent(),
    Value<String?> telephone = const Value.absent(),
    bool? actif,
    DateTime? creeLe,
    Value<String?> cloudId = const Value.absent(),
    DateTime? updatedAt,
  }) => Coequipier(
    id: id ?? this.id,
    nom: nom ?? this.nom,
    colorTag: colorTag.present ? colorTag.value : this.colorTag,
    telephone: telephone.present ? telephone.value : this.telephone,
    actif: actif ?? this.actif,
    creeLe: creeLe ?? this.creeLe,
    cloudId: cloudId.present ? cloudId.value : this.cloudId,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Coequipier copyWithCompanion(CoequipiersCompanion data) {
    return Coequipier(
      id: data.id.present ? data.id.value : this.id,
      nom: data.nom.present ? data.nom.value : this.nom,
      colorTag: data.colorTag.present ? data.colorTag.value : this.colorTag,
      telephone: data.telephone.present ? data.telephone.value : this.telephone,
      actif: data.actif.present ? data.actif.value : this.actif,
      creeLe: data.creeLe.present ? data.creeLe.value : this.creeLe,
      cloudId: data.cloudId.present ? data.cloudId.value : this.cloudId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Coequipier(')
          ..write('id: $id, ')
          ..write('nom: $nom, ')
          ..write('colorTag: $colorTag, ')
          ..write('telephone: $telephone, ')
          ..write('actif: $actif, ')
          ..write('creeLe: $creeLe, ')
          ..write('cloudId: $cloudId, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    nom,
    colorTag,
    telephone,
    actif,
    creeLe,
    cloudId,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Coequipier &&
          other.id == this.id &&
          other.nom == this.nom &&
          other.colorTag == this.colorTag &&
          other.telephone == this.telephone &&
          other.actif == this.actif &&
          other.creeLe == this.creeLe &&
          other.cloudId == this.cloudId &&
          other.updatedAt == this.updatedAt);
}

class CoequipiersCompanion extends UpdateCompanion<Coequipier> {
  final Value<int> id;
  final Value<String> nom;
  final Value<String?> colorTag;
  final Value<String?> telephone;
  final Value<bool> actif;
  final Value<DateTime> creeLe;
  final Value<String?> cloudId;
  final Value<DateTime> updatedAt;
  const CoequipiersCompanion({
    this.id = const Value.absent(),
    this.nom = const Value.absent(),
    this.colorTag = const Value.absent(),
    this.telephone = const Value.absent(),
    this.actif = const Value.absent(),
    this.creeLe = const Value.absent(),
    this.cloudId = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CoequipiersCompanion.insert({
    this.id = const Value.absent(),
    required String nom,
    this.colorTag = const Value.absent(),
    this.telephone = const Value.absent(),
    this.actif = const Value.absent(),
    this.creeLe = const Value.absent(),
    this.cloudId = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : nom = Value(nom);
  static Insertable<Coequipier> custom({
    Expression<int>? id,
    Expression<String>? nom,
    Expression<String>? colorTag,
    Expression<String>? telephone,
    Expression<bool>? actif,
    Expression<DateTime>? creeLe,
    Expression<String>? cloudId,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nom != null) 'nom': nom,
      if (colorTag != null) 'color_tag': colorTag,
      if (telephone != null) 'telephone': telephone,
      if (actif != null) 'actif': actif,
      if (creeLe != null) 'cree_le': creeLe,
      if (cloudId != null) 'cloud_id': cloudId,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CoequipiersCompanion copyWith({
    Value<int>? id,
    Value<String>? nom,
    Value<String?>? colorTag,
    Value<String?>? telephone,
    Value<bool>? actif,
    Value<DateTime>? creeLe,
    Value<String?>? cloudId,
    Value<DateTime>? updatedAt,
  }) {
    return CoequipiersCompanion(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      colorTag: colorTag ?? this.colorTag,
      telephone: telephone ?? this.telephone,
      actif: actif ?? this.actif,
      creeLe: creeLe ?? this.creeLe,
      cloudId: cloudId ?? this.cloudId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nom.present) {
      map['nom'] = Variable<String>(nom.value);
    }
    if (colorTag.present) {
      map['color_tag'] = Variable<String>(colorTag.value);
    }
    if (telephone.present) {
      map['telephone'] = Variable<String>(telephone.value);
    }
    if (actif.present) {
      map['actif'] = Variable<bool>(actif.value);
    }
    if (creeLe.present) {
      map['cree_le'] = Variable<DateTime>(creeLe.value);
    }
    if (cloudId.present) {
      map['cloud_id'] = Variable<String>(cloudId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CoequipiersCompanion(')
          ..write('id: $id, ')
          ..write('nom: $nom, ')
          ..write('colorTag: $colorTag, ')
          ..write('telephone: $telephone, ')
          ..write('actif: $actif, ')
          ..write('creeLe: $creeLe, ')
          ..write('cloudId: $cloudId, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $TourneeMembresTable extends TourneeMembres
    with TableInfo<$TourneeMembresTable, TourneeMembre> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TourneeMembresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _tourneeCloudIdMeta = const VerificationMeta(
    'tourneeCloudId',
  );
  @override
  late final GeneratedColumn<String> tourneeCloudId = GeneratedColumn<String>(
    'tournee_cloud_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userCloudIdMeta = const VerificationMeta(
    'userCloudId',
  );
  @override
  late final GeneratedColumn<String> userCloudId = GeneratedColumn<String>(
    'user_cloud_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _joinedAtMeta = const VerificationMeta(
    'joinedAt',
  );
  @override
  late final GeneratedColumn<DateTime> joinedAt = GeneratedColumn<DateTime>(
    'joined_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tourneeCloudId,
    userCloudId,
    role,
    joinedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tournee_membres';
  @override
  VerificationContext validateIntegrity(
    Insertable<TourneeMembre> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('tournee_cloud_id')) {
      context.handle(
        _tourneeCloudIdMeta,
        tourneeCloudId.isAcceptableOrUnknown(
          data['tournee_cloud_id']!,
          _tourneeCloudIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tourneeCloudIdMeta);
    }
    if (data.containsKey('user_cloud_id')) {
      context.handle(
        _userCloudIdMeta,
        userCloudId.isAcceptableOrUnknown(
          data['user_cloud_id']!,
          _userCloudIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_userCloudIdMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('joined_at')) {
      context.handle(
        _joinedAtMeta,
        joinedAt.isAcceptableOrUnknown(data['joined_at']!, _joinedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TourneeMembre map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TourneeMembre(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      tourneeCloudId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tournee_cloud_id'],
      )!,
      userCloudId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_cloud_id'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      joinedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}joined_at'],
      )!,
    );
  }

  @override
  $TourneeMembresTable createAlias(String alias) {
    return $TourneeMembresTable(attachedDatabase, alias);
  }
}

class TourneeMembre extends DataClass implements Insertable<TourneeMembre> {
  final int id;

  /// UUID cloud de la tournée (= `tournees.cloud_id` de la table Tournees).
  /// Ne pas confondre avec le `tourneeId` int local (PK Drift). On stocke
  /// directement l'UUID pour décorréler du local id (un membre peut
  /// exister dans le cache avant que la tournée elle-même soit pull).
  final String tourneeCloudId;

  /// UUID Supabase du user (= `auth.users.id`). Sert à matcher avec
  /// le current user au cold start ("est-ce que JE suis membre de cette
  /// tournée ?").
  final String userCloudId;

  /// `owner` ou `member`. CHECK constraint au niveau DB (cf migration).
  final String role;
  final DateTime joinedAt;
  const TourneeMembre({
    required this.id,
    required this.tourneeCloudId,
    required this.userCloudId,
    required this.role,
    required this.joinedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['tournee_cloud_id'] = Variable<String>(tourneeCloudId);
    map['user_cloud_id'] = Variable<String>(userCloudId);
    map['role'] = Variable<String>(role);
    map['joined_at'] = Variable<DateTime>(joinedAt);
    return map;
  }

  TourneeMembresCompanion toCompanion(bool nullToAbsent) {
    return TourneeMembresCompanion(
      id: Value(id),
      tourneeCloudId: Value(tourneeCloudId),
      userCloudId: Value(userCloudId),
      role: Value(role),
      joinedAt: Value(joinedAt),
    );
  }

  factory TourneeMembre.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TourneeMembre(
      id: serializer.fromJson<int>(json['id']),
      tourneeCloudId: serializer.fromJson<String>(json['tourneeCloudId']),
      userCloudId: serializer.fromJson<String>(json['userCloudId']),
      role: serializer.fromJson<String>(json['role']),
      joinedAt: serializer.fromJson<DateTime>(json['joinedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'tourneeCloudId': serializer.toJson<String>(tourneeCloudId),
      'userCloudId': serializer.toJson<String>(userCloudId),
      'role': serializer.toJson<String>(role),
      'joinedAt': serializer.toJson<DateTime>(joinedAt),
    };
  }

  TourneeMembre copyWith({
    int? id,
    String? tourneeCloudId,
    String? userCloudId,
    String? role,
    DateTime? joinedAt,
  }) => TourneeMembre(
    id: id ?? this.id,
    tourneeCloudId: tourneeCloudId ?? this.tourneeCloudId,
    userCloudId: userCloudId ?? this.userCloudId,
    role: role ?? this.role,
    joinedAt: joinedAt ?? this.joinedAt,
  );
  TourneeMembre copyWithCompanion(TourneeMembresCompanion data) {
    return TourneeMembre(
      id: data.id.present ? data.id.value : this.id,
      tourneeCloudId: data.tourneeCloudId.present
          ? data.tourneeCloudId.value
          : this.tourneeCloudId,
      userCloudId: data.userCloudId.present
          ? data.userCloudId.value
          : this.userCloudId,
      role: data.role.present ? data.role.value : this.role,
      joinedAt: data.joinedAt.present ? data.joinedAt.value : this.joinedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TourneeMembre(')
          ..write('id: $id, ')
          ..write('tourneeCloudId: $tourneeCloudId, ')
          ..write('userCloudId: $userCloudId, ')
          ..write('role: $role, ')
          ..write('joinedAt: $joinedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, tourneeCloudId, userCloudId, role, joinedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TourneeMembre &&
          other.id == this.id &&
          other.tourneeCloudId == this.tourneeCloudId &&
          other.userCloudId == this.userCloudId &&
          other.role == this.role &&
          other.joinedAt == this.joinedAt);
}

class TourneeMembresCompanion extends UpdateCompanion<TourneeMembre> {
  final Value<int> id;
  final Value<String> tourneeCloudId;
  final Value<String> userCloudId;
  final Value<String> role;
  final Value<DateTime> joinedAt;
  const TourneeMembresCompanion({
    this.id = const Value.absent(),
    this.tourneeCloudId = const Value.absent(),
    this.userCloudId = const Value.absent(),
    this.role = const Value.absent(),
    this.joinedAt = const Value.absent(),
  });
  TourneeMembresCompanion.insert({
    this.id = const Value.absent(),
    required String tourneeCloudId,
    required String userCloudId,
    required String role,
    this.joinedAt = const Value.absent(),
  }) : tourneeCloudId = Value(tourneeCloudId),
       userCloudId = Value(userCloudId),
       role = Value(role);
  static Insertable<TourneeMembre> custom({
    Expression<int>? id,
    Expression<String>? tourneeCloudId,
    Expression<String>? userCloudId,
    Expression<String>? role,
    Expression<DateTime>? joinedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tourneeCloudId != null) 'tournee_cloud_id': tourneeCloudId,
      if (userCloudId != null) 'user_cloud_id': userCloudId,
      if (role != null) 'role': role,
      if (joinedAt != null) 'joined_at': joinedAt,
    });
  }

  TourneeMembresCompanion copyWith({
    Value<int>? id,
    Value<String>? tourneeCloudId,
    Value<String>? userCloudId,
    Value<String>? role,
    Value<DateTime>? joinedAt,
  }) {
    return TourneeMembresCompanion(
      id: id ?? this.id,
      tourneeCloudId: tourneeCloudId ?? this.tourneeCloudId,
      userCloudId: userCloudId ?? this.userCloudId,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (tourneeCloudId.present) {
      map['tournee_cloud_id'] = Variable<String>(tourneeCloudId.value);
    }
    if (userCloudId.present) {
      map['user_cloud_id'] = Variable<String>(userCloudId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (joinedAt.present) {
      map['joined_at'] = Variable<DateTime>(joinedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TourneeMembresCompanion(')
          ..write('id: $id, ')
          ..write('tourneeCloudId: $tourneeCloudId, ')
          ..write('userCloudId: $userCloudId, ')
          ..write('role: $role, ')
          ..write('joinedAt: $joinedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TourneesTable tournees = $TourneesTable(this);
  late final $StopsTable stops = $StopsTable(this);
  late final $ParametresTable parametres = $ParametresTable(this);
  late final $SheetsTable sheets = $SheetsTable(this);
  late final $GeocodeCacheTable geocodeCache = $GeocodeCacheTable(this);
  late final $SavedDestinationsTable savedDestinations =
      $SavedDestinationsTable(this);
  late final $StopHistoryTable stopHistory = $StopHistoryTable(this);
  late final $CoequipiersTable coequipiers = $CoequipiersTable(this);
  late final $TourneeMembresTable tourneeMembres = $TourneeMembresTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    tournees,
    stops,
    parametres,
    sheets,
    geocodeCache,
    savedDestinations,
    stopHistory,
    coequipiers,
    tourneeMembres,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tournees',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('stops', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'stops',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('sheets', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'stops',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('stop_history', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$TourneesTableCreateCompanionBuilder =
    TourneesCompanion Function({
      Value<int> id,
      required String nom,
      required DateTime date,
      required double pointDepartLat,
      required double pointDepartLng,
      required String pointDepartLabel,
      Value<int> vehiculeCapaciteColis,
      Value<String> statut,
      Value<int?> distanceTotaleM,
      Value<int?> dureeTotaleS,
      Value<DateTime?> optimiseeLe,
      Value<String?> traceGeojson,
      Value<DateTime?> demareeLe,
      Value<bool> isTemplate,
      Value<String> profilOrs,
      Value<bool> eviterPeages,
      Value<DateTime?> rappelLe,
      Value<DateTime?> pauseeLe,
      Value<int> pauseeSeconds,
      Value<int?> coequipierDefautId,
      Value<DateTime> creeLe,
      Value<String?> cloudId,
      Value<DateTime> updatedAt,
    });
typedef $$TourneesTableUpdateCompanionBuilder =
    TourneesCompanion Function({
      Value<int> id,
      Value<String> nom,
      Value<DateTime> date,
      Value<double> pointDepartLat,
      Value<double> pointDepartLng,
      Value<String> pointDepartLabel,
      Value<int> vehiculeCapaciteColis,
      Value<String> statut,
      Value<int?> distanceTotaleM,
      Value<int?> dureeTotaleS,
      Value<DateTime?> optimiseeLe,
      Value<String?> traceGeojson,
      Value<DateTime?> demareeLe,
      Value<bool> isTemplate,
      Value<String> profilOrs,
      Value<bool> eviterPeages,
      Value<DateTime?> rappelLe,
      Value<DateTime?> pauseeLe,
      Value<int> pauseeSeconds,
      Value<int?> coequipierDefautId,
      Value<DateTime> creeLe,
      Value<String?> cloudId,
      Value<DateTime> updatedAt,
    });

final class $$TourneesTableReferences
    extends BaseReferences<_$AppDatabase, $TourneesTable, Tournee> {
  $$TourneesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$StopsTable, List<Stop>> _stopsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.stops,
    aliasName: $_aliasNameGenerator(db.tournees.id, db.stops.tourneeId),
  );

  $$StopsTableProcessedTableManager get stopsRefs {
    final manager = $$StopsTableTableManager(
      $_db,
      $_db.stops,
    ).filter((f) => f.tourneeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_stopsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TourneesTableFilterComposer
    extends Composer<_$AppDatabase, $TourneesTable> {
  $$TourneesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nom => $composableBuilder(
    column: $table.nom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pointDepartLat => $composableBuilder(
    column: $table.pointDepartLat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pointDepartLng => $composableBuilder(
    column: $table.pointDepartLng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pointDepartLabel => $composableBuilder(
    column: $table.pointDepartLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get vehiculeCapaciteColis => $composableBuilder(
    column: $table.vehiculeCapaciteColis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get statut => $composableBuilder(
    column: $table.statut,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get distanceTotaleM => $composableBuilder(
    column: $table.distanceTotaleM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dureeTotaleS => $composableBuilder(
    column: $table.dureeTotaleS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get optimiseeLe => $composableBuilder(
    column: $table.optimiseeLe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get traceGeojson => $composableBuilder(
    column: $table.traceGeojson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get demareeLe => $composableBuilder(
    column: $table.demareeLe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isTemplate => $composableBuilder(
    column: $table.isTemplate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get profilOrs => $composableBuilder(
    column: $table.profilOrs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get eviterPeages => $composableBuilder(
    column: $table.eviterPeages,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get rappelLe => $composableBuilder(
    column: $table.rappelLe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get pauseeLe => $composableBuilder(
    column: $table.pauseeLe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pauseeSeconds => $composableBuilder(
    column: $table.pauseeSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get coequipierDefautId => $composableBuilder(
    column: $table.coequipierDefautId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get creeLe => $composableBuilder(
    column: $table.creeLe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cloudId => $composableBuilder(
    column: $table.cloudId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> stopsRefs(
    Expression<bool> Function($$StopsTableFilterComposer f) f,
  ) {
    final $$StopsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.stops,
      getReferencedColumn: (t) => t.tourneeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StopsTableFilterComposer(
            $db: $db,
            $table: $db.stops,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TourneesTableOrderingComposer
    extends Composer<_$AppDatabase, $TourneesTable> {
  $$TourneesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nom => $composableBuilder(
    column: $table.nom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pointDepartLat => $composableBuilder(
    column: $table.pointDepartLat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pointDepartLng => $composableBuilder(
    column: $table.pointDepartLng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pointDepartLabel => $composableBuilder(
    column: $table.pointDepartLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get vehiculeCapaciteColis => $composableBuilder(
    column: $table.vehiculeCapaciteColis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get statut => $composableBuilder(
    column: $table.statut,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get distanceTotaleM => $composableBuilder(
    column: $table.distanceTotaleM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dureeTotaleS => $composableBuilder(
    column: $table.dureeTotaleS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get optimiseeLe => $composableBuilder(
    column: $table.optimiseeLe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get traceGeojson => $composableBuilder(
    column: $table.traceGeojson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get demareeLe => $composableBuilder(
    column: $table.demareeLe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isTemplate => $composableBuilder(
    column: $table.isTemplate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get profilOrs => $composableBuilder(
    column: $table.profilOrs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get eviterPeages => $composableBuilder(
    column: $table.eviterPeages,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get rappelLe => $composableBuilder(
    column: $table.rappelLe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get pauseeLe => $composableBuilder(
    column: $table.pauseeLe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pauseeSeconds => $composableBuilder(
    column: $table.pauseeSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get coequipierDefautId => $composableBuilder(
    column: $table.coequipierDefautId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get creeLe => $composableBuilder(
    column: $table.creeLe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cloudId => $composableBuilder(
    column: $table.cloudId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TourneesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TourneesTable> {
  $$TourneesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nom =>
      $composableBuilder(column: $table.nom, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get pointDepartLat => $composableBuilder(
    column: $table.pointDepartLat,
    builder: (column) => column,
  );

  GeneratedColumn<double> get pointDepartLng => $composableBuilder(
    column: $table.pointDepartLng,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pointDepartLabel => $composableBuilder(
    column: $table.pointDepartLabel,
    builder: (column) => column,
  );

  GeneratedColumn<int> get vehiculeCapaciteColis => $composableBuilder(
    column: $table.vehiculeCapaciteColis,
    builder: (column) => column,
  );

  GeneratedColumn<String> get statut =>
      $composableBuilder(column: $table.statut, builder: (column) => column);

  GeneratedColumn<int> get distanceTotaleM => $composableBuilder(
    column: $table.distanceTotaleM,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dureeTotaleS => $composableBuilder(
    column: $table.dureeTotaleS,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get optimiseeLe => $composableBuilder(
    column: $table.optimiseeLe,
    builder: (column) => column,
  );

  GeneratedColumn<String> get traceGeojson => $composableBuilder(
    column: $table.traceGeojson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get demareeLe =>
      $composableBuilder(column: $table.demareeLe, builder: (column) => column);

  GeneratedColumn<bool> get isTemplate => $composableBuilder(
    column: $table.isTemplate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get profilOrs =>
      $composableBuilder(column: $table.profilOrs, builder: (column) => column);

  GeneratedColumn<bool> get eviterPeages => $composableBuilder(
    column: $table.eviterPeages,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get rappelLe =>
      $composableBuilder(column: $table.rappelLe, builder: (column) => column);

  GeneratedColumn<DateTime> get pauseeLe =>
      $composableBuilder(column: $table.pauseeLe, builder: (column) => column);

  GeneratedColumn<int> get pauseeSeconds => $composableBuilder(
    column: $table.pauseeSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get coequipierDefautId => $composableBuilder(
    column: $table.coequipierDefautId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get creeLe =>
      $composableBuilder(column: $table.creeLe, builder: (column) => column);

  GeneratedColumn<String> get cloudId =>
      $composableBuilder(column: $table.cloudId, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> stopsRefs<T extends Object>(
    Expression<T> Function($$StopsTableAnnotationComposer a) f,
  ) {
    final $$StopsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.stops,
      getReferencedColumn: (t) => t.tourneeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StopsTableAnnotationComposer(
            $db: $db,
            $table: $db.stops,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TourneesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TourneesTable,
          Tournee,
          $$TourneesTableFilterComposer,
          $$TourneesTableOrderingComposer,
          $$TourneesTableAnnotationComposer,
          $$TourneesTableCreateCompanionBuilder,
          $$TourneesTableUpdateCompanionBuilder,
          (Tournee, $$TourneesTableReferences),
          Tournee,
          PrefetchHooks Function({bool stopsRefs})
        > {
  $$TourneesTableTableManager(_$AppDatabase db, $TourneesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TourneesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TourneesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TourneesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> nom = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<double> pointDepartLat = const Value.absent(),
                Value<double> pointDepartLng = const Value.absent(),
                Value<String> pointDepartLabel = const Value.absent(),
                Value<int> vehiculeCapaciteColis = const Value.absent(),
                Value<String> statut = const Value.absent(),
                Value<int?> distanceTotaleM = const Value.absent(),
                Value<int?> dureeTotaleS = const Value.absent(),
                Value<DateTime?> optimiseeLe = const Value.absent(),
                Value<String?> traceGeojson = const Value.absent(),
                Value<DateTime?> demareeLe = const Value.absent(),
                Value<bool> isTemplate = const Value.absent(),
                Value<String> profilOrs = const Value.absent(),
                Value<bool> eviterPeages = const Value.absent(),
                Value<DateTime?> rappelLe = const Value.absent(),
                Value<DateTime?> pauseeLe = const Value.absent(),
                Value<int> pauseeSeconds = const Value.absent(),
                Value<int?> coequipierDefautId = const Value.absent(),
                Value<DateTime> creeLe = const Value.absent(),
                Value<String?> cloudId = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => TourneesCompanion(
                id: id,
                nom: nom,
                date: date,
                pointDepartLat: pointDepartLat,
                pointDepartLng: pointDepartLng,
                pointDepartLabel: pointDepartLabel,
                vehiculeCapaciteColis: vehiculeCapaciteColis,
                statut: statut,
                distanceTotaleM: distanceTotaleM,
                dureeTotaleS: dureeTotaleS,
                optimiseeLe: optimiseeLe,
                traceGeojson: traceGeojson,
                demareeLe: demareeLe,
                isTemplate: isTemplate,
                profilOrs: profilOrs,
                eviterPeages: eviterPeages,
                rappelLe: rappelLe,
                pauseeLe: pauseeLe,
                pauseeSeconds: pauseeSeconds,
                coequipierDefautId: coequipierDefautId,
                creeLe: creeLe,
                cloudId: cloudId,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String nom,
                required DateTime date,
                required double pointDepartLat,
                required double pointDepartLng,
                required String pointDepartLabel,
                Value<int> vehiculeCapaciteColis = const Value.absent(),
                Value<String> statut = const Value.absent(),
                Value<int?> distanceTotaleM = const Value.absent(),
                Value<int?> dureeTotaleS = const Value.absent(),
                Value<DateTime?> optimiseeLe = const Value.absent(),
                Value<String?> traceGeojson = const Value.absent(),
                Value<DateTime?> demareeLe = const Value.absent(),
                Value<bool> isTemplate = const Value.absent(),
                Value<String> profilOrs = const Value.absent(),
                Value<bool> eviterPeages = const Value.absent(),
                Value<DateTime?> rappelLe = const Value.absent(),
                Value<DateTime?> pauseeLe = const Value.absent(),
                Value<int> pauseeSeconds = const Value.absent(),
                Value<int?> coequipierDefautId = const Value.absent(),
                Value<DateTime> creeLe = const Value.absent(),
                Value<String?> cloudId = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => TourneesCompanion.insert(
                id: id,
                nom: nom,
                date: date,
                pointDepartLat: pointDepartLat,
                pointDepartLng: pointDepartLng,
                pointDepartLabel: pointDepartLabel,
                vehiculeCapaciteColis: vehiculeCapaciteColis,
                statut: statut,
                distanceTotaleM: distanceTotaleM,
                dureeTotaleS: dureeTotaleS,
                optimiseeLe: optimiseeLe,
                traceGeojson: traceGeojson,
                demareeLe: demareeLe,
                isTemplate: isTemplate,
                profilOrs: profilOrs,
                eviterPeages: eviterPeages,
                rappelLe: rappelLe,
                pauseeLe: pauseeLe,
                pauseeSeconds: pauseeSeconds,
                coequipierDefautId: coequipierDefautId,
                creeLe: creeLe,
                cloudId: cloudId,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TourneesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({stopsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (stopsRefs) db.stops],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (stopsRefs)
                    await $_getPrefetchedData<Tournee, $TourneesTable, Stop>(
                      currentTable: table,
                      referencedTable: $$TourneesTableReferences
                          ._stopsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$TourneesTableReferences(db, table, p0).stopsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.tourneeId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TourneesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TourneesTable,
      Tournee,
      $$TourneesTableFilterComposer,
      $$TourneesTableOrderingComposer,
      $$TourneesTableAnnotationComposer,
      $$TourneesTableCreateCompanionBuilder,
      $$TourneesTableUpdateCompanionBuilder,
      (Tournee, $$TourneesTableReferences),
      Tournee,
      PrefetchHooks Function({bool stopsRefs})
    >;
typedef $$StopsTableCreateCompanionBuilder =
    StopsCompanion Function({
      Value<int> id,
      required int tourneeId,
      required String adresseBrute,
      Value<String?> adresseNormalisee,
      Value<double?> lat,
      Value<double?> lng,
      Value<int> nbColis,
      Value<String> priorite,
      Value<String?> fenetreDebut,
      Value<String?> fenetreFin,
      Value<int> dureeArretMin,
      Value<String?> notes,
      Value<String?> nomClient,
      Value<String> statutLivraison,
      Value<String?> raisonEchec,
      Value<double?> livreLat,
      Value<double?> livreLng,
      Value<DateTime?> livreLe,
      Value<int?> ordreOptimise,
      Value<int?> ordrePriorite,
      Value<String?> preuvePhotoPath,
      Value<int?> coequipierId,
      Value<DateTime> creeLe,
      Value<String?> cloudId,
      Value<String?> cloudPhotoPath,
      Value<DateTime> updatedAt,
    });
typedef $$StopsTableUpdateCompanionBuilder =
    StopsCompanion Function({
      Value<int> id,
      Value<int> tourneeId,
      Value<String> adresseBrute,
      Value<String?> adresseNormalisee,
      Value<double?> lat,
      Value<double?> lng,
      Value<int> nbColis,
      Value<String> priorite,
      Value<String?> fenetreDebut,
      Value<String?> fenetreFin,
      Value<int> dureeArretMin,
      Value<String?> notes,
      Value<String?> nomClient,
      Value<String> statutLivraison,
      Value<String?> raisonEchec,
      Value<double?> livreLat,
      Value<double?> livreLng,
      Value<DateTime?> livreLe,
      Value<int?> ordreOptimise,
      Value<int?> ordrePriorite,
      Value<String?> preuvePhotoPath,
      Value<int?> coequipierId,
      Value<DateTime> creeLe,
      Value<String?> cloudId,
      Value<String?> cloudPhotoPath,
      Value<DateTime> updatedAt,
    });

final class $$StopsTableReferences
    extends BaseReferences<_$AppDatabase, $StopsTable, Stop> {
  $$StopsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TourneesTable _tourneeIdTable(_$AppDatabase db) => db.tournees
      .createAlias($_aliasNameGenerator(db.stops.tourneeId, db.tournees.id));

  $$TourneesTableProcessedTableManager get tourneeId {
    final $_column = $_itemColumn<int>('tournee_id')!;

    final manager = $$TourneesTableTableManager(
      $_db,
      $_db.tournees,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tourneeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$SheetsTable, List<Sheet>> _sheetsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.sheets,
    aliasName: $_aliasNameGenerator(db.stops.id, db.sheets.stopId),
  );

  $$SheetsTableProcessedTableManager get sheetsRefs {
    final manager = $$SheetsTableTableManager(
      $_db,
      $_db.sheets,
    ).filter((f) => f.stopId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_sheetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$StopHistoryTable, List<StopHistoryData>>
  _stopHistoryRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.stopHistory,
    aliasName: $_aliasNameGenerator(db.stops.id, db.stopHistory.stopId),
  );

  $$StopHistoryTableProcessedTableManager get stopHistoryRefs {
    final manager = $$StopHistoryTableTableManager(
      $_db,
      $_db.stopHistory,
    ).filter((f) => f.stopId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_stopHistoryRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$StopsTableFilterComposer extends Composer<_$AppDatabase, $StopsTable> {
  $$StopsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get adresseBrute => $composableBuilder(
    column: $table.adresseBrute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get adresseNormalisee => $composableBuilder(
    column: $table.adresseNormalisee,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nbColis => $composableBuilder(
    column: $table.nbColis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get priorite => $composableBuilder(
    column: $table.priorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fenetreDebut => $composableBuilder(
    column: $table.fenetreDebut,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fenetreFin => $composableBuilder(
    column: $table.fenetreFin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dureeArretMin => $composableBuilder(
    column: $table.dureeArretMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nomClient => $composableBuilder(
    column: $table.nomClient,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get statutLivraison => $composableBuilder(
    column: $table.statutLivraison,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get raisonEchec => $composableBuilder(
    column: $table.raisonEchec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get livreLat => $composableBuilder(
    column: $table.livreLat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get livreLng => $composableBuilder(
    column: $table.livreLng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get livreLe => $composableBuilder(
    column: $table.livreLe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ordreOptimise => $composableBuilder(
    column: $table.ordreOptimise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ordrePriorite => $composableBuilder(
    column: $table.ordrePriorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get preuvePhotoPath => $composableBuilder(
    column: $table.preuvePhotoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get coequipierId => $composableBuilder(
    column: $table.coequipierId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get creeLe => $composableBuilder(
    column: $table.creeLe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cloudId => $composableBuilder(
    column: $table.cloudId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cloudPhotoPath => $composableBuilder(
    column: $table.cloudPhotoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$TourneesTableFilterComposer get tourneeId {
    final $$TourneesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tourneeId,
      referencedTable: $db.tournees,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TourneesTableFilterComposer(
            $db: $db,
            $table: $db.tournees,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> sheetsRefs(
    Expression<bool> Function($$SheetsTableFilterComposer f) f,
  ) {
    final $$SheetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sheets,
      getReferencedColumn: (t) => t.stopId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SheetsTableFilterComposer(
            $db: $db,
            $table: $db.sheets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> stopHistoryRefs(
    Expression<bool> Function($$StopHistoryTableFilterComposer f) f,
  ) {
    final $$StopHistoryTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.stopHistory,
      getReferencedColumn: (t) => t.stopId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StopHistoryTableFilterComposer(
            $db: $db,
            $table: $db.stopHistory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StopsTableOrderingComposer
    extends Composer<_$AppDatabase, $StopsTable> {
  $$StopsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get adresseBrute => $composableBuilder(
    column: $table.adresseBrute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get adresseNormalisee => $composableBuilder(
    column: $table.adresseNormalisee,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nbColis => $composableBuilder(
    column: $table.nbColis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get priorite => $composableBuilder(
    column: $table.priorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fenetreDebut => $composableBuilder(
    column: $table.fenetreDebut,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fenetreFin => $composableBuilder(
    column: $table.fenetreFin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dureeArretMin => $composableBuilder(
    column: $table.dureeArretMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nomClient => $composableBuilder(
    column: $table.nomClient,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get statutLivraison => $composableBuilder(
    column: $table.statutLivraison,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get raisonEchec => $composableBuilder(
    column: $table.raisonEchec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get livreLat => $composableBuilder(
    column: $table.livreLat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get livreLng => $composableBuilder(
    column: $table.livreLng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get livreLe => $composableBuilder(
    column: $table.livreLe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ordreOptimise => $composableBuilder(
    column: $table.ordreOptimise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ordrePriorite => $composableBuilder(
    column: $table.ordrePriorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get preuvePhotoPath => $composableBuilder(
    column: $table.preuvePhotoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get coequipierId => $composableBuilder(
    column: $table.coequipierId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get creeLe => $composableBuilder(
    column: $table.creeLe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cloudId => $composableBuilder(
    column: $table.cloudId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cloudPhotoPath => $composableBuilder(
    column: $table.cloudPhotoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TourneesTableOrderingComposer get tourneeId {
    final $$TourneesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tourneeId,
      referencedTable: $db.tournees,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TourneesTableOrderingComposer(
            $db: $db,
            $table: $db.tournees,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StopsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StopsTable> {
  $$StopsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get adresseBrute => $composableBuilder(
    column: $table.adresseBrute,
    builder: (column) => column,
  );

  GeneratedColumn<String> get adresseNormalisee => $composableBuilder(
    column: $table.adresseNormalisee,
    builder: (column) => column,
  );

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lng =>
      $composableBuilder(column: $table.lng, builder: (column) => column);

  GeneratedColumn<int> get nbColis =>
      $composableBuilder(column: $table.nbColis, builder: (column) => column);

  GeneratedColumn<String> get priorite =>
      $composableBuilder(column: $table.priorite, builder: (column) => column);

  GeneratedColumn<String> get fenetreDebut => $composableBuilder(
    column: $table.fenetreDebut,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fenetreFin => $composableBuilder(
    column: $table.fenetreFin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dureeArretMin => $composableBuilder(
    column: $table.dureeArretMin,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get nomClient =>
      $composableBuilder(column: $table.nomClient, builder: (column) => column);

  GeneratedColumn<String> get statutLivraison => $composableBuilder(
    column: $table.statutLivraison,
    builder: (column) => column,
  );

  GeneratedColumn<String> get raisonEchec => $composableBuilder(
    column: $table.raisonEchec,
    builder: (column) => column,
  );

  GeneratedColumn<double> get livreLat =>
      $composableBuilder(column: $table.livreLat, builder: (column) => column);

  GeneratedColumn<double> get livreLng =>
      $composableBuilder(column: $table.livreLng, builder: (column) => column);

  GeneratedColumn<DateTime> get livreLe =>
      $composableBuilder(column: $table.livreLe, builder: (column) => column);

  GeneratedColumn<int> get ordreOptimise => $composableBuilder(
    column: $table.ordreOptimise,
    builder: (column) => column,
  );

  GeneratedColumn<int> get ordrePriorite => $composableBuilder(
    column: $table.ordrePriorite,
    builder: (column) => column,
  );

  GeneratedColumn<String> get preuvePhotoPath => $composableBuilder(
    column: $table.preuvePhotoPath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get coequipierId => $composableBuilder(
    column: $table.coequipierId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get creeLe =>
      $composableBuilder(column: $table.creeLe, builder: (column) => column);

  GeneratedColumn<String> get cloudId =>
      $composableBuilder(column: $table.cloudId, builder: (column) => column);

  GeneratedColumn<String> get cloudPhotoPath => $composableBuilder(
    column: $table.cloudPhotoPath,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$TourneesTableAnnotationComposer get tourneeId {
    final $$TourneesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tourneeId,
      referencedTable: $db.tournees,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TourneesTableAnnotationComposer(
            $db: $db,
            $table: $db.tournees,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> sheetsRefs<T extends Object>(
    Expression<T> Function($$SheetsTableAnnotationComposer a) f,
  ) {
    final $$SheetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sheets,
      getReferencedColumn: (t) => t.stopId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SheetsTableAnnotationComposer(
            $db: $db,
            $table: $db.sheets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> stopHistoryRefs<T extends Object>(
    Expression<T> Function($$StopHistoryTableAnnotationComposer a) f,
  ) {
    final $$StopHistoryTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.stopHistory,
      getReferencedColumn: (t) => t.stopId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StopHistoryTableAnnotationComposer(
            $db: $db,
            $table: $db.stopHistory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StopsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StopsTable,
          Stop,
          $$StopsTableFilterComposer,
          $$StopsTableOrderingComposer,
          $$StopsTableAnnotationComposer,
          $$StopsTableCreateCompanionBuilder,
          $$StopsTableUpdateCompanionBuilder,
          (Stop, $$StopsTableReferences),
          Stop,
          PrefetchHooks Function({
            bool tourneeId,
            bool sheetsRefs,
            bool stopHistoryRefs,
          })
        > {
  $$StopsTableTableManager(_$AppDatabase db, $StopsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StopsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StopsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StopsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> tourneeId = const Value.absent(),
                Value<String> adresseBrute = const Value.absent(),
                Value<String?> adresseNormalisee = const Value.absent(),
                Value<double?> lat = const Value.absent(),
                Value<double?> lng = const Value.absent(),
                Value<int> nbColis = const Value.absent(),
                Value<String> priorite = const Value.absent(),
                Value<String?> fenetreDebut = const Value.absent(),
                Value<String?> fenetreFin = const Value.absent(),
                Value<int> dureeArretMin = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> nomClient = const Value.absent(),
                Value<String> statutLivraison = const Value.absent(),
                Value<String?> raisonEchec = const Value.absent(),
                Value<double?> livreLat = const Value.absent(),
                Value<double?> livreLng = const Value.absent(),
                Value<DateTime?> livreLe = const Value.absent(),
                Value<int?> ordreOptimise = const Value.absent(),
                Value<int?> ordrePriorite = const Value.absent(),
                Value<String?> preuvePhotoPath = const Value.absent(),
                Value<int?> coequipierId = const Value.absent(),
                Value<DateTime> creeLe = const Value.absent(),
                Value<String?> cloudId = const Value.absent(),
                Value<String?> cloudPhotoPath = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => StopsCompanion(
                id: id,
                tourneeId: tourneeId,
                adresseBrute: adresseBrute,
                adresseNormalisee: adresseNormalisee,
                lat: lat,
                lng: lng,
                nbColis: nbColis,
                priorite: priorite,
                fenetreDebut: fenetreDebut,
                fenetreFin: fenetreFin,
                dureeArretMin: dureeArretMin,
                notes: notes,
                nomClient: nomClient,
                statutLivraison: statutLivraison,
                raisonEchec: raisonEchec,
                livreLat: livreLat,
                livreLng: livreLng,
                livreLe: livreLe,
                ordreOptimise: ordreOptimise,
                ordrePriorite: ordrePriorite,
                preuvePhotoPath: preuvePhotoPath,
                coequipierId: coequipierId,
                creeLe: creeLe,
                cloudId: cloudId,
                cloudPhotoPath: cloudPhotoPath,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int tourneeId,
                required String adresseBrute,
                Value<String?> adresseNormalisee = const Value.absent(),
                Value<double?> lat = const Value.absent(),
                Value<double?> lng = const Value.absent(),
                Value<int> nbColis = const Value.absent(),
                Value<String> priorite = const Value.absent(),
                Value<String?> fenetreDebut = const Value.absent(),
                Value<String?> fenetreFin = const Value.absent(),
                Value<int> dureeArretMin = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> nomClient = const Value.absent(),
                Value<String> statutLivraison = const Value.absent(),
                Value<String?> raisonEchec = const Value.absent(),
                Value<double?> livreLat = const Value.absent(),
                Value<double?> livreLng = const Value.absent(),
                Value<DateTime?> livreLe = const Value.absent(),
                Value<int?> ordreOptimise = const Value.absent(),
                Value<int?> ordrePriorite = const Value.absent(),
                Value<String?> preuvePhotoPath = const Value.absent(),
                Value<int?> coequipierId = const Value.absent(),
                Value<DateTime> creeLe = const Value.absent(),
                Value<String?> cloudId = const Value.absent(),
                Value<String?> cloudPhotoPath = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => StopsCompanion.insert(
                id: id,
                tourneeId: tourneeId,
                adresseBrute: adresseBrute,
                adresseNormalisee: adresseNormalisee,
                lat: lat,
                lng: lng,
                nbColis: nbColis,
                priorite: priorite,
                fenetreDebut: fenetreDebut,
                fenetreFin: fenetreFin,
                dureeArretMin: dureeArretMin,
                notes: notes,
                nomClient: nomClient,
                statutLivraison: statutLivraison,
                raisonEchec: raisonEchec,
                livreLat: livreLat,
                livreLng: livreLng,
                livreLe: livreLe,
                ordreOptimise: ordreOptimise,
                ordrePriorite: ordrePriorite,
                preuvePhotoPath: preuvePhotoPath,
                coequipierId: coequipierId,
                creeLe: creeLe,
                cloudId: cloudId,
                cloudPhotoPath: cloudPhotoPath,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$StopsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                tourneeId = false,
                sheetsRefs = false,
                stopHistoryRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (sheetsRefs) db.sheets,
                    if (stopHistoryRefs) db.stopHistory,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (tourneeId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.tourneeId,
                                    referencedTable: $$StopsTableReferences
                                        ._tourneeIdTable(db),
                                    referencedColumn: $$StopsTableReferences
                                        ._tourneeIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (sheetsRefs)
                        await $_getPrefetchedData<Stop, $StopsTable, Sheet>(
                          currentTable: table,
                          referencedTable: $$StopsTableReferences
                              ._sheetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StopsTableReferences(db, table, p0).sheetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.stopId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (stopHistoryRefs)
                        await $_getPrefetchedData<
                          Stop,
                          $StopsTable,
                          StopHistoryData
                        >(
                          currentTable: table,
                          referencedTable: $$StopsTableReferences
                              ._stopHistoryRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StopsTableReferences(
                                db,
                                table,
                                p0,
                              ).stopHistoryRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.stopId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$StopsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StopsTable,
      Stop,
      $$StopsTableFilterComposer,
      $$StopsTableOrderingComposer,
      $$StopsTableAnnotationComposer,
      $$StopsTableCreateCompanionBuilder,
      $$StopsTableUpdateCompanionBuilder,
      (Stop, $$StopsTableReferences),
      Stop,
      PrefetchHooks Function({
        bool tourneeId,
        bool sheetsRefs,
        bool stopHistoryRefs,
      })
    >;
typedef $$ParametresTableCreateCompanionBuilder =
    ParametresCompanion Function({
      required String cle,
      required String valeur,
      Value<int> rowid,
    });
typedef $$ParametresTableUpdateCompanionBuilder =
    ParametresCompanion Function({
      Value<String> cle,
      Value<String> valeur,
      Value<int> rowid,
    });

class $$ParametresTableFilterComposer
    extends Composer<_$AppDatabase, $ParametresTable> {
  $$ParametresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get cle => $composableBuilder(
    column: $table.cle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valeur => $composableBuilder(
    column: $table.valeur,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ParametresTableOrderingComposer
    extends Composer<_$AppDatabase, $ParametresTable> {
  $$ParametresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get cle => $composableBuilder(
    column: $table.cle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valeur => $composableBuilder(
    column: $table.valeur,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ParametresTableAnnotationComposer
    extends Composer<_$AppDatabase, $ParametresTable> {
  $$ParametresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get cle =>
      $composableBuilder(column: $table.cle, builder: (column) => column);

  GeneratedColumn<String> get valeur =>
      $composableBuilder(column: $table.valeur, builder: (column) => column);
}

class $$ParametresTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ParametresTable,
          Parametre,
          $$ParametresTableFilterComposer,
          $$ParametresTableOrderingComposer,
          $$ParametresTableAnnotationComposer,
          $$ParametresTableCreateCompanionBuilder,
          $$ParametresTableUpdateCompanionBuilder,
          (
            Parametre,
            BaseReferences<_$AppDatabase, $ParametresTable, Parametre>,
          ),
          Parametre,
          PrefetchHooks Function()
        > {
  $$ParametresTableTableManager(_$AppDatabase db, $ParametresTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ParametresTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ParametresTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ParametresTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> cle = const Value.absent(),
                Value<String> valeur = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ParametresCompanion(cle: cle, valeur: valeur, rowid: rowid),
          createCompanionCallback:
              ({
                required String cle,
                required String valeur,
                Value<int> rowid = const Value.absent(),
              }) => ParametresCompanion.insert(
                cle: cle,
                valeur: valeur,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ParametresTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ParametresTable,
      Parametre,
      $$ParametresTableFilterComposer,
      $$ParametresTableOrderingComposer,
      $$ParametresTableAnnotationComposer,
      $$ParametresTableCreateCompanionBuilder,
      $$ParametresTableUpdateCompanionBuilder,
      (Parametre, BaseReferences<_$AppDatabase, $ParametresTable, Parametre>),
      Parametre,
      PrefetchHooks Function()
    >;
typedef $$SheetsTableCreateCompanionBuilder =
    SheetsCompanion Function({
      Value<int> id,
      required int stopId,
      required String expediteur,
      Value<String?> refCode,
      Value<String?> nomDestinataire,
      Value<String?> telephone,
      Value<int> nbColis,
      Value<double?> poidsKg,
      Value<String> statut,
      Value<String?> raisonEchec,
      Value<DateTime> creeLe,
    });
typedef $$SheetsTableUpdateCompanionBuilder =
    SheetsCompanion Function({
      Value<int> id,
      Value<int> stopId,
      Value<String> expediteur,
      Value<String?> refCode,
      Value<String?> nomDestinataire,
      Value<String?> telephone,
      Value<int> nbColis,
      Value<double?> poidsKg,
      Value<String> statut,
      Value<String?> raisonEchec,
      Value<DateTime> creeLe,
    });

final class $$SheetsTableReferences
    extends BaseReferences<_$AppDatabase, $SheetsTable, Sheet> {
  $$SheetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $StopsTable _stopIdTable(_$AppDatabase db) =>
      db.stops.createAlias($_aliasNameGenerator(db.sheets.stopId, db.stops.id));

  $$StopsTableProcessedTableManager get stopId {
    final $_column = $_itemColumn<int>('stop_id')!;

    final manager = $$StopsTableTableManager(
      $_db,
      $_db.stops,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_stopIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SheetsTableFilterComposer
    extends Composer<_$AppDatabase, $SheetsTable> {
  $$SheetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get expediteur => $composableBuilder(
    column: $table.expediteur,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get refCode => $composableBuilder(
    column: $table.refCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nomDestinataire => $composableBuilder(
    column: $table.nomDestinataire,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get telephone => $composableBuilder(
    column: $table.telephone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nbColis => $composableBuilder(
    column: $table.nbColis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get poidsKg => $composableBuilder(
    column: $table.poidsKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get statut => $composableBuilder(
    column: $table.statut,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get raisonEchec => $composableBuilder(
    column: $table.raisonEchec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get creeLe => $composableBuilder(
    column: $table.creeLe,
    builder: (column) => ColumnFilters(column),
  );

  $$StopsTableFilterComposer get stopId {
    final $$StopsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.stopId,
      referencedTable: $db.stops,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StopsTableFilterComposer(
            $db: $db,
            $table: $db.stops,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SheetsTableOrderingComposer
    extends Composer<_$AppDatabase, $SheetsTable> {
  $$SheetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get expediteur => $composableBuilder(
    column: $table.expediteur,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get refCode => $composableBuilder(
    column: $table.refCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nomDestinataire => $composableBuilder(
    column: $table.nomDestinataire,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get telephone => $composableBuilder(
    column: $table.telephone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nbColis => $composableBuilder(
    column: $table.nbColis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get poidsKg => $composableBuilder(
    column: $table.poidsKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get statut => $composableBuilder(
    column: $table.statut,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get raisonEchec => $composableBuilder(
    column: $table.raisonEchec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get creeLe => $composableBuilder(
    column: $table.creeLe,
    builder: (column) => ColumnOrderings(column),
  );

  $$StopsTableOrderingComposer get stopId {
    final $$StopsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.stopId,
      referencedTable: $db.stops,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StopsTableOrderingComposer(
            $db: $db,
            $table: $db.stops,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SheetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SheetsTable> {
  $$SheetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get expediteur => $composableBuilder(
    column: $table.expediteur,
    builder: (column) => column,
  );

  GeneratedColumn<String> get refCode =>
      $composableBuilder(column: $table.refCode, builder: (column) => column);

  GeneratedColumn<String> get nomDestinataire => $composableBuilder(
    column: $table.nomDestinataire,
    builder: (column) => column,
  );

  GeneratedColumn<String> get telephone =>
      $composableBuilder(column: $table.telephone, builder: (column) => column);

  GeneratedColumn<int> get nbColis =>
      $composableBuilder(column: $table.nbColis, builder: (column) => column);

  GeneratedColumn<double> get poidsKg =>
      $composableBuilder(column: $table.poidsKg, builder: (column) => column);

  GeneratedColumn<String> get statut =>
      $composableBuilder(column: $table.statut, builder: (column) => column);

  GeneratedColumn<String> get raisonEchec => $composableBuilder(
    column: $table.raisonEchec,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get creeLe =>
      $composableBuilder(column: $table.creeLe, builder: (column) => column);

  $$StopsTableAnnotationComposer get stopId {
    final $$StopsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.stopId,
      referencedTable: $db.stops,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StopsTableAnnotationComposer(
            $db: $db,
            $table: $db.stops,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SheetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SheetsTable,
          Sheet,
          $$SheetsTableFilterComposer,
          $$SheetsTableOrderingComposer,
          $$SheetsTableAnnotationComposer,
          $$SheetsTableCreateCompanionBuilder,
          $$SheetsTableUpdateCompanionBuilder,
          (Sheet, $$SheetsTableReferences),
          Sheet,
          PrefetchHooks Function({bool stopId})
        > {
  $$SheetsTableTableManager(_$AppDatabase db, $SheetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SheetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SheetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SheetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> stopId = const Value.absent(),
                Value<String> expediteur = const Value.absent(),
                Value<String?> refCode = const Value.absent(),
                Value<String?> nomDestinataire = const Value.absent(),
                Value<String?> telephone = const Value.absent(),
                Value<int> nbColis = const Value.absent(),
                Value<double?> poidsKg = const Value.absent(),
                Value<String> statut = const Value.absent(),
                Value<String?> raisonEchec = const Value.absent(),
                Value<DateTime> creeLe = const Value.absent(),
              }) => SheetsCompanion(
                id: id,
                stopId: stopId,
                expediteur: expediteur,
                refCode: refCode,
                nomDestinataire: nomDestinataire,
                telephone: telephone,
                nbColis: nbColis,
                poidsKg: poidsKg,
                statut: statut,
                raisonEchec: raisonEchec,
                creeLe: creeLe,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int stopId,
                required String expediteur,
                Value<String?> refCode = const Value.absent(),
                Value<String?> nomDestinataire = const Value.absent(),
                Value<String?> telephone = const Value.absent(),
                Value<int> nbColis = const Value.absent(),
                Value<double?> poidsKg = const Value.absent(),
                Value<String> statut = const Value.absent(),
                Value<String?> raisonEchec = const Value.absent(),
                Value<DateTime> creeLe = const Value.absent(),
              }) => SheetsCompanion.insert(
                id: id,
                stopId: stopId,
                expediteur: expediteur,
                refCode: refCode,
                nomDestinataire: nomDestinataire,
                telephone: telephone,
                nbColis: nbColis,
                poidsKg: poidsKg,
                statut: statut,
                raisonEchec: raisonEchec,
                creeLe: creeLe,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$SheetsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({stopId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (stopId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.stopId,
                                referencedTable: $$SheetsTableReferences
                                    ._stopIdTable(db),
                                referencedColumn: $$SheetsTableReferences
                                    ._stopIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SheetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SheetsTable,
      Sheet,
      $$SheetsTableFilterComposer,
      $$SheetsTableOrderingComposer,
      $$SheetsTableAnnotationComposer,
      $$SheetsTableCreateCompanionBuilder,
      $$SheetsTableUpdateCompanionBuilder,
      (Sheet, $$SheetsTableReferences),
      Sheet,
      PrefetchHooks Function({bool stopId})
    >;
typedef $$GeocodeCacheTableCreateCompanionBuilder =
    GeocodeCacheCompanion Function({
      required String query,
      required String responseJson,
      required DateTime expireLe,
      Value<int> rowid,
    });
typedef $$GeocodeCacheTableUpdateCompanionBuilder =
    GeocodeCacheCompanion Function({
      Value<String> query,
      Value<String> responseJson,
      Value<DateTime> expireLe,
      Value<int> rowid,
    });

class $$GeocodeCacheTableFilterComposer
    extends Composer<_$AppDatabase, $GeocodeCacheTable> {
  $$GeocodeCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get query => $composableBuilder(
    column: $table.query,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get responseJson => $composableBuilder(
    column: $table.responseJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expireLe => $composableBuilder(
    column: $table.expireLe,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GeocodeCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $GeocodeCacheTable> {
  $$GeocodeCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get query => $composableBuilder(
    column: $table.query,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get responseJson => $composableBuilder(
    column: $table.responseJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expireLe => $composableBuilder(
    column: $table.expireLe,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GeocodeCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $GeocodeCacheTable> {
  $$GeocodeCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get query =>
      $composableBuilder(column: $table.query, builder: (column) => column);

  GeneratedColumn<String> get responseJson => $composableBuilder(
    column: $table.responseJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get expireLe =>
      $composableBuilder(column: $table.expireLe, builder: (column) => column);
}

class $$GeocodeCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GeocodeCacheTable,
          GeocodeCacheData,
          $$GeocodeCacheTableFilterComposer,
          $$GeocodeCacheTableOrderingComposer,
          $$GeocodeCacheTableAnnotationComposer,
          $$GeocodeCacheTableCreateCompanionBuilder,
          $$GeocodeCacheTableUpdateCompanionBuilder,
          (
            GeocodeCacheData,
            BaseReferences<_$AppDatabase, $GeocodeCacheTable, GeocodeCacheData>,
          ),
          GeocodeCacheData,
          PrefetchHooks Function()
        > {
  $$GeocodeCacheTableTableManager(_$AppDatabase db, $GeocodeCacheTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GeocodeCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GeocodeCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GeocodeCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> query = const Value.absent(),
                Value<String> responseJson = const Value.absent(),
                Value<DateTime> expireLe = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GeocodeCacheCompanion(
                query: query,
                responseJson: responseJson,
                expireLe: expireLe,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String query,
                required String responseJson,
                required DateTime expireLe,
                Value<int> rowid = const Value.absent(),
              }) => GeocodeCacheCompanion.insert(
                query: query,
                responseJson: responseJson,
                expireLe: expireLe,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GeocodeCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GeocodeCacheTable,
      GeocodeCacheData,
      $$GeocodeCacheTableFilterComposer,
      $$GeocodeCacheTableOrderingComposer,
      $$GeocodeCacheTableAnnotationComposer,
      $$GeocodeCacheTableCreateCompanionBuilder,
      $$GeocodeCacheTableUpdateCompanionBuilder,
      (
        GeocodeCacheData,
        BaseReferences<_$AppDatabase, $GeocodeCacheTable, GeocodeCacheData>,
      ),
      GeocodeCacheData,
      PrefetchHooks Function()
    >;
typedef $$SavedDestinationsTableCreateCompanionBuilder =
    SavedDestinationsCompanion Function({
      Value<int> id,
      Value<String?> nomClient,
      required String adresseDisplay,
      required double lat,
      required double lng,
      Value<String?> rue,
      Value<String?> codePostal,
      Value<String?> ville,
      Value<int> useCount,
      Value<DateTime> lastUsedAt,
      Value<DateTime> creeLe,
      Value<bool> isFavori,
      Value<String?> colorTag,
      Value<String?> notesCarnet,
      Value<String?> tagsJson,
      Value<String?> photoPath,
      Value<String?> codeAcces,
      Value<String?> etageBatiment,
      Value<String?> cloudId,
      Value<DateTime> updatedAt,
    });
typedef $$SavedDestinationsTableUpdateCompanionBuilder =
    SavedDestinationsCompanion Function({
      Value<int> id,
      Value<String?> nomClient,
      Value<String> adresseDisplay,
      Value<double> lat,
      Value<double> lng,
      Value<String?> rue,
      Value<String?> codePostal,
      Value<String?> ville,
      Value<int> useCount,
      Value<DateTime> lastUsedAt,
      Value<DateTime> creeLe,
      Value<bool> isFavori,
      Value<String?> colorTag,
      Value<String?> notesCarnet,
      Value<String?> tagsJson,
      Value<String?> photoPath,
      Value<String?> codeAcces,
      Value<String?> etageBatiment,
      Value<String?> cloudId,
      Value<DateTime> updatedAt,
    });

class $$SavedDestinationsTableFilterComposer
    extends Composer<_$AppDatabase, $SavedDestinationsTable> {
  $$SavedDestinationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nomClient => $composableBuilder(
    column: $table.nomClient,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get adresseDisplay => $composableBuilder(
    column: $table.adresseDisplay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rue => $composableBuilder(
    column: $table.rue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get codePostal => $composableBuilder(
    column: $table.codePostal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ville => $composableBuilder(
    column: $table.ville,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get useCount => $composableBuilder(
    column: $table.useCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get creeLe => $composableBuilder(
    column: $table.creeLe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavori => $composableBuilder(
    column: $table.isFavori,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorTag => $composableBuilder(
    column: $table.colorTag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notesCarnet => $composableBuilder(
    column: $table.notesCarnet,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get codeAcces => $composableBuilder(
    column: $table.codeAcces,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get etageBatiment => $composableBuilder(
    column: $table.etageBatiment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cloudId => $composableBuilder(
    column: $table.cloudId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SavedDestinationsTableOrderingComposer
    extends Composer<_$AppDatabase, $SavedDestinationsTable> {
  $$SavedDestinationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nomClient => $composableBuilder(
    column: $table.nomClient,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get adresseDisplay => $composableBuilder(
    column: $table.adresseDisplay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rue => $composableBuilder(
    column: $table.rue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get codePostal => $composableBuilder(
    column: $table.codePostal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ville => $composableBuilder(
    column: $table.ville,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get useCount => $composableBuilder(
    column: $table.useCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get creeLe => $composableBuilder(
    column: $table.creeLe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavori => $composableBuilder(
    column: $table.isFavori,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorTag => $composableBuilder(
    column: $table.colorTag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notesCarnet => $composableBuilder(
    column: $table.notesCarnet,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get codeAcces => $composableBuilder(
    column: $table.codeAcces,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get etageBatiment => $composableBuilder(
    column: $table.etageBatiment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cloudId => $composableBuilder(
    column: $table.cloudId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SavedDestinationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SavedDestinationsTable> {
  $$SavedDestinationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nomClient =>
      $composableBuilder(column: $table.nomClient, builder: (column) => column);

  GeneratedColumn<String> get adresseDisplay => $composableBuilder(
    column: $table.adresseDisplay,
    builder: (column) => column,
  );

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lng =>
      $composableBuilder(column: $table.lng, builder: (column) => column);

  GeneratedColumn<String> get rue =>
      $composableBuilder(column: $table.rue, builder: (column) => column);

  GeneratedColumn<String> get codePostal => $composableBuilder(
    column: $table.codePostal,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ville =>
      $composableBuilder(column: $table.ville, builder: (column) => column);

  GeneratedColumn<int> get useCount =>
      $composableBuilder(column: $table.useCount, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get creeLe =>
      $composableBuilder(column: $table.creeLe, builder: (column) => column);

  GeneratedColumn<bool> get isFavori =>
      $composableBuilder(column: $table.isFavori, builder: (column) => column);

  GeneratedColumn<String> get colorTag =>
      $composableBuilder(column: $table.colorTag, builder: (column) => column);

  GeneratedColumn<String> get notesCarnet => $composableBuilder(
    column: $table.notesCarnet,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tagsJson =>
      $composableBuilder(column: $table.tagsJson, builder: (column) => column);

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);

  GeneratedColumn<String> get codeAcces =>
      $composableBuilder(column: $table.codeAcces, builder: (column) => column);

  GeneratedColumn<String> get etageBatiment => $composableBuilder(
    column: $table.etageBatiment,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cloudId =>
      $composableBuilder(column: $table.cloudId, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SavedDestinationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SavedDestinationsTable,
          SavedDestination,
          $$SavedDestinationsTableFilterComposer,
          $$SavedDestinationsTableOrderingComposer,
          $$SavedDestinationsTableAnnotationComposer,
          $$SavedDestinationsTableCreateCompanionBuilder,
          $$SavedDestinationsTableUpdateCompanionBuilder,
          (
            SavedDestination,
            BaseReferences<
              _$AppDatabase,
              $SavedDestinationsTable,
              SavedDestination
            >,
          ),
          SavedDestination,
          PrefetchHooks Function()
        > {
  $$SavedDestinationsTableTableManager(
    _$AppDatabase db,
    $SavedDestinationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavedDestinationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavedDestinationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavedDestinationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> nomClient = const Value.absent(),
                Value<String> adresseDisplay = const Value.absent(),
                Value<double> lat = const Value.absent(),
                Value<double> lng = const Value.absent(),
                Value<String?> rue = const Value.absent(),
                Value<String?> codePostal = const Value.absent(),
                Value<String?> ville = const Value.absent(),
                Value<int> useCount = const Value.absent(),
                Value<DateTime> lastUsedAt = const Value.absent(),
                Value<DateTime> creeLe = const Value.absent(),
                Value<bool> isFavori = const Value.absent(),
                Value<String?> colorTag = const Value.absent(),
                Value<String?> notesCarnet = const Value.absent(),
                Value<String?> tagsJson = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                Value<String?> codeAcces = const Value.absent(),
                Value<String?> etageBatiment = const Value.absent(),
                Value<String?> cloudId = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SavedDestinationsCompanion(
                id: id,
                nomClient: nomClient,
                adresseDisplay: adresseDisplay,
                lat: lat,
                lng: lng,
                rue: rue,
                codePostal: codePostal,
                ville: ville,
                useCount: useCount,
                lastUsedAt: lastUsedAt,
                creeLe: creeLe,
                isFavori: isFavori,
                colorTag: colorTag,
                notesCarnet: notesCarnet,
                tagsJson: tagsJson,
                photoPath: photoPath,
                codeAcces: codeAcces,
                etageBatiment: etageBatiment,
                cloudId: cloudId,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> nomClient = const Value.absent(),
                required String adresseDisplay,
                required double lat,
                required double lng,
                Value<String?> rue = const Value.absent(),
                Value<String?> codePostal = const Value.absent(),
                Value<String?> ville = const Value.absent(),
                Value<int> useCount = const Value.absent(),
                Value<DateTime> lastUsedAt = const Value.absent(),
                Value<DateTime> creeLe = const Value.absent(),
                Value<bool> isFavori = const Value.absent(),
                Value<String?> colorTag = const Value.absent(),
                Value<String?> notesCarnet = const Value.absent(),
                Value<String?> tagsJson = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                Value<String?> codeAcces = const Value.absent(),
                Value<String?> etageBatiment = const Value.absent(),
                Value<String?> cloudId = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SavedDestinationsCompanion.insert(
                id: id,
                nomClient: nomClient,
                adresseDisplay: adresseDisplay,
                lat: lat,
                lng: lng,
                rue: rue,
                codePostal: codePostal,
                ville: ville,
                useCount: useCount,
                lastUsedAt: lastUsedAt,
                creeLe: creeLe,
                isFavori: isFavori,
                colorTag: colorTag,
                notesCarnet: notesCarnet,
                tagsJson: tagsJson,
                photoPath: photoPath,
                codeAcces: codeAcces,
                etageBatiment: etageBatiment,
                cloudId: cloudId,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SavedDestinationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SavedDestinationsTable,
      SavedDestination,
      $$SavedDestinationsTableFilterComposer,
      $$SavedDestinationsTableOrderingComposer,
      $$SavedDestinationsTableAnnotationComposer,
      $$SavedDestinationsTableCreateCompanionBuilder,
      $$SavedDestinationsTableUpdateCompanionBuilder,
      (
        SavedDestination,
        BaseReferences<
          _$AppDatabase,
          $SavedDestinationsTable,
          SavedDestination
        >,
      ),
      SavedDestination,
      PrefetchHooks Function()
    >;
typedef $$StopHistoryTableCreateCompanionBuilder =
    StopHistoryCompanion Function({
      Value<int> id,
      required int stopId,
      required String action,
      required String fromStatus,
      required String toStatus,
      Value<String?> raison,
      Value<DateTime> timestamp,
    });
typedef $$StopHistoryTableUpdateCompanionBuilder =
    StopHistoryCompanion Function({
      Value<int> id,
      Value<int> stopId,
      Value<String> action,
      Value<String> fromStatus,
      Value<String> toStatus,
      Value<String?> raison,
      Value<DateTime> timestamp,
    });

final class $$StopHistoryTableReferences
    extends BaseReferences<_$AppDatabase, $StopHistoryTable, StopHistoryData> {
  $$StopHistoryTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $StopsTable _stopIdTable(_$AppDatabase db) => db.stops.createAlias(
    $_aliasNameGenerator(db.stopHistory.stopId, db.stops.id),
  );

  $$StopsTableProcessedTableManager get stopId {
    final $_column = $_itemColumn<int>('stop_id')!;

    final manager = $$StopsTableTableManager(
      $_db,
      $_db.stops,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_stopIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$StopHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $StopHistoryTable> {
  $$StopHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fromStatus => $composableBuilder(
    column: $table.fromStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toStatus => $composableBuilder(
    column: $table.toStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get raison => $composableBuilder(
    column: $table.raison,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  $$StopsTableFilterComposer get stopId {
    final $$StopsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.stopId,
      referencedTable: $db.stops,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StopsTableFilterComposer(
            $db: $db,
            $table: $db.stops,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StopHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $StopHistoryTable> {
  $$StopHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fromStatus => $composableBuilder(
    column: $table.fromStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toStatus => $composableBuilder(
    column: $table.toStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get raison => $composableBuilder(
    column: $table.raison,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  $$StopsTableOrderingComposer get stopId {
    final $$StopsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.stopId,
      referencedTable: $db.stops,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StopsTableOrderingComposer(
            $db: $db,
            $table: $db.stops,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StopHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $StopHistoryTable> {
  $$StopHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get fromStatus => $composableBuilder(
    column: $table.fromStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get toStatus =>
      $composableBuilder(column: $table.toStatus, builder: (column) => column);

  GeneratedColumn<String> get raison =>
      $composableBuilder(column: $table.raison, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  $$StopsTableAnnotationComposer get stopId {
    final $$StopsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.stopId,
      referencedTable: $db.stops,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StopsTableAnnotationComposer(
            $db: $db,
            $table: $db.stops,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StopHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StopHistoryTable,
          StopHistoryData,
          $$StopHistoryTableFilterComposer,
          $$StopHistoryTableOrderingComposer,
          $$StopHistoryTableAnnotationComposer,
          $$StopHistoryTableCreateCompanionBuilder,
          $$StopHistoryTableUpdateCompanionBuilder,
          (StopHistoryData, $$StopHistoryTableReferences),
          StopHistoryData,
          PrefetchHooks Function({bool stopId})
        > {
  $$StopHistoryTableTableManager(_$AppDatabase db, $StopHistoryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StopHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StopHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StopHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> stopId = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String> fromStatus = const Value.absent(),
                Value<String> toStatus = const Value.absent(),
                Value<String?> raison = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
              }) => StopHistoryCompanion(
                id: id,
                stopId: stopId,
                action: action,
                fromStatus: fromStatus,
                toStatus: toStatus,
                raison: raison,
                timestamp: timestamp,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int stopId,
                required String action,
                required String fromStatus,
                required String toStatus,
                Value<String?> raison = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
              }) => StopHistoryCompanion.insert(
                id: id,
                stopId: stopId,
                action: action,
                fromStatus: fromStatus,
                toStatus: toStatus,
                raison: raison,
                timestamp: timestamp,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$StopHistoryTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({stopId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (stopId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.stopId,
                                referencedTable: $$StopHistoryTableReferences
                                    ._stopIdTable(db),
                                referencedColumn: $$StopHistoryTableReferences
                                    ._stopIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$StopHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StopHistoryTable,
      StopHistoryData,
      $$StopHistoryTableFilterComposer,
      $$StopHistoryTableOrderingComposer,
      $$StopHistoryTableAnnotationComposer,
      $$StopHistoryTableCreateCompanionBuilder,
      $$StopHistoryTableUpdateCompanionBuilder,
      (StopHistoryData, $$StopHistoryTableReferences),
      StopHistoryData,
      PrefetchHooks Function({bool stopId})
    >;
typedef $$CoequipiersTableCreateCompanionBuilder =
    CoequipiersCompanion Function({
      Value<int> id,
      required String nom,
      Value<String?> colorTag,
      Value<String?> telephone,
      Value<bool> actif,
      Value<DateTime> creeLe,
      Value<String?> cloudId,
      Value<DateTime> updatedAt,
    });
typedef $$CoequipiersTableUpdateCompanionBuilder =
    CoequipiersCompanion Function({
      Value<int> id,
      Value<String> nom,
      Value<String?> colorTag,
      Value<String?> telephone,
      Value<bool> actif,
      Value<DateTime> creeLe,
      Value<String?> cloudId,
      Value<DateTime> updatedAt,
    });

class $$CoequipiersTableFilterComposer
    extends Composer<_$AppDatabase, $CoequipiersTable> {
  $$CoequipiersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nom => $composableBuilder(
    column: $table.nom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorTag => $composableBuilder(
    column: $table.colorTag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get telephone => $composableBuilder(
    column: $table.telephone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get actif => $composableBuilder(
    column: $table.actif,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get creeLe => $composableBuilder(
    column: $table.creeLe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cloudId => $composableBuilder(
    column: $table.cloudId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CoequipiersTableOrderingComposer
    extends Composer<_$AppDatabase, $CoequipiersTable> {
  $$CoequipiersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nom => $composableBuilder(
    column: $table.nom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorTag => $composableBuilder(
    column: $table.colorTag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get telephone => $composableBuilder(
    column: $table.telephone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get actif => $composableBuilder(
    column: $table.actif,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get creeLe => $composableBuilder(
    column: $table.creeLe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cloudId => $composableBuilder(
    column: $table.cloudId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CoequipiersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CoequipiersTable> {
  $$CoequipiersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nom =>
      $composableBuilder(column: $table.nom, builder: (column) => column);

  GeneratedColumn<String> get colorTag =>
      $composableBuilder(column: $table.colorTag, builder: (column) => column);

  GeneratedColumn<String> get telephone =>
      $composableBuilder(column: $table.telephone, builder: (column) => column);

  GeneratedColumn<bool> get actif =>
      $composableBuilder(column: $table.actif, builder: (column) => column);

  GeneratedColumn<DateTime> get creeLe =>
      $composableBuilder(column: $table.creeLe, builder: (column) => column);

  GeneratedColumn<String> get cloudId =>
      $composableBuilder(column: $table.cloudId, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CoequipiersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CoequipiersTable,
          Coequipier,
          $$CoequipiersTableFilterComposer,
          $$CoequipiersTableOrderingComposer,
          $$CoequipiersTableAnnotationComposer,
          $$CoequipiersTableCreateCompanionBuilder,
          $$CoequipiersTableUpdateCompanionBuilder,
          (
            Coequipier,
            BaseReferences<_$AppDatabase, $CoequipiersTable, Coequipier>,
          ),
          Coequipier,
          PrefetchHooks Function()
        > {
  $$CoequipiersTableTableManager(_$AppDatabase db, $CoequipiersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CoequipiersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CoequipiersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CoequipiersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> nom = const Value.absent(),
                Value<String?> colorTag = const Value.absent(),
                Value<String?> telephone = const Value.absent(),
                Value<bool> actif = const Value.absent(),
                Value<DateTime> creeLe = const Value.absent(),
                Value<String?> cloudId = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CoequipiersCompanion(
                id: id,
                nom: nom,
                colorTag: colorTag,
                telephone: telephone,
                actif: actif,
                creeLe: creeLe,
                cloudId: cloudId,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String nom,
                Value<String?> colorTag = const Value.absent(),
                Value<String?> telephone = const Value.absent(),
                Value<bool> actif = const Value.absent(),
                Value<DateTime> creeLe = const Value.absent(),
                Value<String?> cloudId = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CoequipiersCompanion.insert(
                id: id,
                nom: nom,
                colorTag: colorTag,
                telephone: telephone,
                actif: actif,
                creeLe: creeLe,
                cloudId: cloudId,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CoequipiersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CoequipiersTable,
      Coequipier,
      $$CoequipiersTableFilterComposer,
      $$CoequipiersTableOrderingComposer,
      $$CoequipiersTableAnnotationComposer,
      $$CoequipiersTableCreateCompanionBuilder,
      $$CoequipiersTableUpdateCompanionBuilder,
      (
        Coequipier,
        BaseReferences<_$AppDatabase, $CoequipiersTable, Coequipier>,
      ),
      Coequipier,
      PrefetchHooks Function()
    >;
typedef $$TourneeMembresTableCreateCompanionBuilder =
    TourneeMembresCompanion Function({
      Value<int> id,
      required String tourneeCloudId,
      required String userCloudId,
      required String role,
      Value<DateTime> joinedAt,
    });
typedef $$TourneeMembresTableUpdateCompanionBuilder =
    TourneeMembresCompanion Function({
      Value<int> id,
      Value<String> tourneeCloudId,
      Value<String> userCloudId,
      Value<String> role,
      Value<DateTime> joinedAt,
    });

class $$TourneeMembresTableFilterComposer
    extends Composer<_$AppDatabase, $TourneeMembresTable> {
  $$TourneeMembresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tourneeCloudId => $composableBuilder(
    column: $table.tourneeCloudId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userCloudId => $composableBuilder(
    column: $table.userCloudId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get joinedAt => $composableBuilder(
    column: $table.joinedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TourneeMembresTableOrderingComposer
    extends Composer<_$AppDatabase, $TourneeMembresTable> {
  $$TourneeMembresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tourneeCloudId => $composableBuilder(
    column: $table.tourneeCloudId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userCloudId => $composableBuilder(
    column: $table.userCloudId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get joinedAt => $composableBuilder(
    column: $table.joinedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TourneeMembresTableAnnotationComposer
    extends Composer<_$AppDatabase, $TourneeMembresTable> {
  $$TourneeMembresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tourneeCloudId => $composableBuilder(
    column: $table.tourneeCloudId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userCloudId => $composableBuilder(
    column: $table.userCloudId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<DateTime> get joinedAt =>
      $composableBuilder(column: $table.joinedAt, builder: (column) => column);
}

class $$TourneeMembresTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TourneeMembresTable,
          TourneeMembre,
          $$TourneeMembresTableFilterComposer,
          $$TourneeMembresTableOrderingComposer,
          $$TourneeMembresTableAnnotationComposer,
          $$TourneeMembresTableCreateCompanionBuilder,
          $$TourneeMembresTableUpdateCompanionBuilder,
          (
            TourneeMembre,
            BaseReferences<_$AppDatabase, $TourneeMembresTable, TourneeMembre>,
          ),
          TourneeMembre,
          PrefetchHooks Function()
        > {
  $$TourneeMembresTableTableManager(
    _$AppDatabase db,
    $TourneeMembresTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TourneeMembresTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TourneeMembresTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TourneeMembresTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> tourneeCloudId = const Value.absent(),
                Value<String> userCloudId = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<DateTime> joinedAt = const Value.absent(),
              }) => TourneeMembresCompanion(
                id: id,
                tourneeCloudId: tourneeCloudId,
                userCloudId: userCloudId,
                role: role,
                joinedAt: joinedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String tourneeCloudId,
                required String userCloudId,
                required String role,
                Value<DateTime> joinedAt = const Value.absent(),
              }) => TourneeMembresCompanion.insert(
                id: id,
                tourneeCloudId: tourneeCloudId,
                userCloudId: userCloudId,
                role: role,
                joinedAt: joinedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TourneeMembresTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TourneeMembresTable,
      TourneeMembre,
      $$TourneeMembresTableFilterComposer,
      $$TourneeMembresTableOrderingComposer,
      $$TourneeMembresTableAnnotationComposer,
      $$TourneeMembresTableCreateCompanionBuilder,
      $$TourneeMembresTableUpdateCompanionBuilder,
      (
        TourneeMembre,
        BaseReferences<_$AppDatabase, $TourneeMembresTable, TourneeMembre>,
      ),
      TourneeMembre,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TourneesTableTableManager get tournees =>
      $$TourneesTableTableManager(_db, _db.tournees);
  $$StopsTableTableManager get stops =>
      $$StopsTableTableManager(_db, _db.stops);
  $$ParametresTableTableManager get parametres =>
      $$ParametresTableTableManager(_db, _db.parametres);
  $$SheetsTableTableManager get sheets =>
      $$SheetsTableTableManager(_db, _db.sheets);
  $$GeocodeCacheTableTableManager get geocodeCache =>
      $$GeocodeCacheTableTableManager(_db, _db.geocodeCache);
  $$SavedDestinationsTableTableManager get savedDestinations =>
      $$SavedDestinationsTableTableManager(_db, _db.savedDestinations);
  $$StopHistoryTableTableManager get stopHistory =>
      $$StopHistoryTableTableManager(_db, _db.stopHistory);
  $$CoequipiersTableTableManager get coequipiers =>
      $$CoequipiersTableTableManager(_db, _db.coequipiers);
  $$TourneeMembresTableTableManager get tourneeMembres =>
      $$TourneeMembresTableTableManager(_db, _db.tourneeMembres);
}
