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
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('livraison'),
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
  static const VerificationMeta _positionLockedMeta = const VerificationMeta(
    'positionLocked',
  );
  @override
  late final GeneratedColumn<bool> positionLocked = GeneratedColumn<bool>(
    'position_locked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("position_locked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
  static const VerificationMeta _trackingNumbersMeta = const VerificationMeta(
    'trackingNumbers',
  );
  @override
  late final GeneratedColumn<String> trackingNumbers = GeneratedColumn<String>(
    'tracking_numbers',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _memoVocalMeta = const VerificationMeta(
    'memoVocal',
  );
  @override
  late final GeneratedColumn<String> memoVocal = GeneratedColumn<String>(
    'memo_vocal',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deposeSansContactMeta = const VerificationMeta(
    'deposeSansContact',
  );
  @override
  late final GeneratedColumn<bool> deposeSansContact = GeneratedColumn<bool>(
    'depose_sans_contact',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("depose_sans_contact" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _montantCodMeta = const VerificationMeta(
    'montantCod',
  );
  @override
  late final GeneratedColumn<double> montantCod = GeneratedColumn<double>(
    'montant_cod',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _codPayeMeta = const VerificationMeta(
    'codPaye',
  );
  @override
  late final GeneratedColumn<bool> codPaye = GeneratedColumn<bool>(
    'cod_paye',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("cod_paye" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _notationEmojiMeta = const VerificationMeta(
    'notationEmoji',
  );
  @override
  late final GeneratedColumn<String> notationEmoji = GeneratedColumn<String>(
    'notation_emoji',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tourneeId,
    adresseBrute,
    adresseNormalisee,
    type,
    lat,
    lng,
    nbColis,
    priorite,
    fenetreDebut,
    fenetreFin,
    dureeArretMin,
    notes,
    nomClient,
    telephone,
    statutLivraison,
    raisonEchec,
    livreLat,
    livreLng,
    livreLe,
    ordreOptimise,
    positionLocked,
    ordrePriorite,
    preuvePhotoPath,
    coequipierId,
    creeLe,
    cloudId,
    cloudPhotoPath,
    updatedAt,
    trackingNumbers,
    memoVocal,
    deposeSansContact,
    montantCod,
    codPaye,
    notationEmoji,
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
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
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
    if (data.containsKey('telephone')) {
      context.handle(
        _telephoneMeta,
        telephone.isAcceptableOrUnknown(data['telephone']!, _telephoneMeta),
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
    if (data.containsKey('position_locked')) {
      context.handle(
        _positionLockedMeta,
        positionLocked.isAcceptableOrUnknown(
          data['position_locked']!,
          _positionLockedMeta,
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
    if (data.containsKey('tracking_numbers')) {
      context.handle(
        _trackingNumbersMeta,
        trackingNumbers.isAcceptableOrUnknown(
          data['tracking_numbers']!,
          _trackingNumbersMeta,
        ),
      );
    }
    if (data.containsKey('memo_vocal')) {
      context.handle(
        _memoVocalMeta,
        memoVocal.isAcceptableOrUnknown(data['memo_vocal']!, _memoVocalMeta),
      );
    }
    if (data.containsKey('depose_sans_contact')) {
      context.handle(
        _deposeSansContactMeta,
        deposeSansContact.isAcceptableOrUnknown(
          data['depose_sans_contact']!,
          _deposeSansContactMeta,
        ),
      );
    }
    if (data.containsKey('montant_cod')) {
      context.handle(
        _montantCodMeta,
        montantCod.isAcceptableOrUnknown(data['montant_cod']!, _montantCodMeta),
      );
    }
    if (data.containsKey('cod_paye')) {
      context.handle(
        _codPayeMeta,
        codPaye.isAcceptableOrUnknown(data['cod_paye']!, _codPayeMeta),
      );
    }
    if (data.containsKey('notation_emoji')) {
      context.handle(
        _notationEmojiMeta,
        notationEmoji.isAcceptableOrUnknown(
          data['notation_emoji']!,
          _notationEmojiMeta,
        ),
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
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
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
      telephone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}telephone'],
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
      positionLocked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}position_locked'],
      )!,
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
      trackingNumbers: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tracking_numbers'],
      ),
      memoVocal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memo_vocal'],
      ),
      deposeSansContact: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}depose_sans_contact'],
      )!,
      montantCod: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}montant_cod'],
      ),
      codPaye: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}cod_paye'],
      )!,
      notationEmoji: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notation_emoji'],
      ),
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
  final String type;
  final double? lat;
  final double? lng;
  final int nbColis;
  final String priorite;
  final String? fenetreDebut;
  final String? fenetreFin;
  final int dureeArretMin;
  final String? notes;
  final String? nomClient;

  /// Numero de telephone du destinataire, saisi directement sur l'arret
  /// (ou pre-rempli par l'OCR du bordereau). Permet d'appeler en 1 tap
  /// sans passer par le carnet. Null si non renseigne. Demande Noah
  /// 2026-06-03.
  final String? telephone;
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

  /// Arret "verrouille" a sa position courante (carte #114). Quand true,
  /// les algos de reordonnancement (tri rapide local, optim VROOM,
  /// drag&drop) gardent cet arret a son index actuel et reordonnent les
  /// autres autour. Default false. Use cases : finir par un client precis,
  /// fenetre horaire stricte en milieu de tournee, priorite client.
  final bool positionLocked;

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

  /// Numeros de tracking (codes-barres) des colis scannes pour cet arret.
  /// Format JSON list de strings, ex: `["FA280000440358","FA280000440359"]`.
  /// Null = aucun colis scanne (creation manuelle / via bordereau OCR).
  ///
  /// Workflow : sur ScanColisScreen, chaque scan code-barre cherche les
  /// arrets de la tournee active dont ce numero est deja dans la liste.
  /// Si trouve -> +1 colis sur cet arret. Sinon -> nouvel arret cree avec
  /// le code comme 1er element + nb_colis = 1.
  ///
  /// Sert aussi a eviter les doublons : un meme code-barre ne peut pas
  /// etre compte 2x meme si Noah scanne le meme colis 2 fois par erreur.
  final String? trackingNumbers;

  /// Memo vocal dicte (transcrit en texte via STT on-device) attache
  /// a un arret, ex: "sonnette HS, passer par l'arriere". Carte #280.
  /// Plus rapide que taper en conduisant. Texte plutot qu'audio brut
  /// pour rester lisible / partageable / sans dependance lecteur media.
  final String? memoVocal;

  /// True si le colis a ete depose devant la porte / dans la boite a
  /// lettres sans remise en main propre (client absent mais joignable
  /// qui a autorise). Carte #287. Combine avec preuvePhotoPath + GPS
  /// (livreLat/Lng) + livreLe = preuve opposable au donneur d'ordre.
  /// Le stop reste statutLivraison='livre' (succes), c'est juste un
  /// marqueur pour les litiges et la facturation.
  final bool deposeSansContact;

  /// Montant a percevoir en contre-remboursement (especes/cheque) lors
  /// de la livraison, en EUR. Carte #296. Null = pas de COD.
  final double? montantCod;

  /// True si le montant COD a ete encaisse (cocher au moment de la
  /// remise). Carte #296. False par defaut.
  final bool codPaye;

  /// Notation 1-clic du client final apres livraison (carte #324) :
  /// 'happy', 'neutral', 'angry', null. Stocke en texte pour rester
  /// lisible humain et evoluer sans migration.
  final String? notationEmoji;
  const Stop({
    required this.id,
    required this.tourneeId,
    required this.adresseBrute,
    this.adresseNormalisee,
    required this.type,
    this.lat,
    this.lng,
    required this.nbColis,
    required this.priorite,
    this.fenetreDebut,
    this.fenetreFin,
    required this.dureeArretMin,
    this.notes,
    this.nomClient,
    this.telephone,
    required this.statutLivraison,
    this.raisonEchec,
    this.livreLat,
    this.livreLng,
    this.livreLe,
    this.ordreOptimise,
    required this.positionLocked,
    this.ordrePriorite,
    this.preuvePhotoPath,
    this.coequipierId,
    required this.creeLe,
    this.cloudId,
    this.cloudPhotoPath,
    required this.updatedAt,
    this.trackingNumbers,
    this.memoVocal,
    required this.deposeSansContact,
    this.montantCod,
    required this.codPaye,
    this.notationEmoji,
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
    map['type'] = Variable<String>(type);
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
    if (!nullToAbsent || telephone != null) {
      map['telephone'] = Variable<String>(telephone);
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
    map['position_locked'] = Variable<bool>(positionLocked);
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
    if (!nullToAbsent || trackingNumbers != null) {
      map['tracking_numbers'] = Variable<String>(trackingNumbers);
    }
    if (!nullToAbsent || memoVocal != null) {
      map['memo_vocal'] = Variable<String>(memoVocal);
    }
    map['depose_sans_contact'] = Variable<bool>(deposeSansContact);
    if (!nullToAbsent || montantCod != null) {
      map['montant_cod'] = Variable<double>(montantCod);
    }
    map['cod_paye'] = Variable<bool>(codPaye);
    if (!nullToAbsent || notationEmoji != null) {
      map['notation_emoji'] = Variable<String>(notationEmoji);
    }
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
      type: Value(type),
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
      telephone: telephone == null && nullToAbsent
          ? const Value.absent()
          : Value(telephone),
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
      positionLocked: Value(positionLocked),
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
      trackingNumbers: trackingNumbers == null && nullToAbsent
          ? const Value.absent()
          : Value(trackingNumbers),
      memoVocal: memoVocal == null && nullToAbsent
          ? const Value.absent()
          : Value(memoVocal),
      deposeSansContact: Value(deposeSansContact),
      montantCod: montantCod == null && nullToAbsent
          ? const Value.absent()
          : Value(montantCod),
      codPaye: Value(codPaye),
      notationEmoji: notationEmoji == null && nullToAbsent
          ? const Value.absent()
          : Value(notationEmoji),
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
      type: serializer.fromJson<String>(json['type']),
      lat: serializer.fromJson<double?>(json['lat']),
      lng: serializer.fromJson<double?>(json['lng']),
      nbColis: serializer.fromJson<int>(json['nbColis']),
      priorite: serializer.fromJson<String>(json['priorite']),
      fenetreDebut: serializer.fromJson<String?>(json['fenetreDebut']),
      fenetreFin: serializer.fromJson<String?>(json['fenetreFin']),
      dureeArretMin: serializer.fromJson<int>(json['dureeArretMin']),
      notes: serializer.fromJson<String?>(json['notes']),
      nomClient: serializer.fromJson<String?>(json['nomClient']),
      telephone: serializer.fromJson<String?>(json['telephone']),
      statutLivraison: serializer.fromJson<String>(json['statutLivraison']),
      raisonEchec: serializer.fromJson<String?>(json['raisonEchec']),
      livreLat: serializer.fromJson<double?>(json['livreLat']),
      livreLng: serializer.fromJson<double?>(json['livreLng']),
      livreLe: serializer.fromJson<DateTime?>(json['livreLe']),
      ordreOptimise: serializer.fromJson<int?>(json['ordreOptimise']),
      positionLocked: serializer.fromJson<bool>(json['positionLocked']),
      ordrePriorite: serializer.fromJson<int?>(json['ordrePriorite']),
      preuvePhotoPath: serializer.fromJson<String?>(json['preuvePhotoPath']),
      coequipierId: serializer.fromJson<int?>(json['coequipierId']),
      creeLe: serializer.fromJson<DateTime>(json['creeLe']),
      cloudId: serializer.fromJson<String?>(json['cloudId']),
      cloudPhotoPath: serializer.fromJson<String?>(json['cloudPhotoPath']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      trackingNumbers: serializer.fromJson<String?>(json['trackingNumbers']),
      memoVocal: serializer.fromJson<String?>(json['memoVocal']),
      deposeSansContact: serializer.fromJson<bool>(json['deposeSansContact']),
      montantCod: serializer.fromJson<double?>(json['montantCod']),
      codPaye: serializer.fromJson<bool>(json['codPaye']),
      notationEmoji: serializer.fromJson<String?>(json['notationEmoji']),
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
      'type': serializer.toJson<String>(type),
      'lat': serializer.toJson<double?>(lat),
      'lng': serializer.toJson<double?>(lng),
      'nbColis': serializer.toJson<int>(nbColis),
      'priorite': serializer.toJson<String>(priorite),
      'fenetreDebut': serializer.toJson<String?>(fenetreDebut),
      'fenetreFin': serializer.toJson<String?>(fenetreFin),
      'dureeArretMin': serializer.toJson<int>(dureeArretMin),
      'notes': serializer.toJson<String?>(notes),
      'nomClient': serializer.toJson<String?>(nomClient),
      'telephone': serializer.toJson<String?>(telephone),
      'statutLivraison': serializer.toJson<String>(statutLivraison),
      'raisonEchec': serializer.toJson<String?>(raisonEchec),
      'livreLat': serializer.toJson<double?>(livreLat),
      'livreLng': serializer.toJson<double?>(livreLng),
      'livreLe': serializer.toJson<DateTime?>(livreLe),
      'ordreOptimise': serializer.toJson<int?>(ordreOptimise),
      'positionLocked': serializer.toJson<bool>(positionLocked),
      'ordrePriorite': serializer.toJson<int?>(ordrePriorite),
      'preuvePhotoPath': serializer.toJson<String?>(preuvePhotoPath),
      'coequipierId': serializer.toJson<int?>(coequipierId),
      'creeLe': serializer.toJson<DateTime>(creeLe),
      'cloudId': serializer.toJson<String?>(cloudId),
      'cloudPhotoPath': serializer.toJson<String?>(cloudPhotoPath),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'trackingNumbers': serializer.toJson<String?>(trackingNumbers),
      'memoVocal': serializer.toJson<String?>(memoVocal),
      'deposeSansContact': serializer.toJson<bool>(deposeSansContact),
      'montantCod': serializer.toJson<double?>(montantCod),
      'codPaye': serializer.toJson<bool>(codPaye),
      'notationEmoji': serializer.toJson<String?>(notationEmoji),
    };
  }

  Stop copyWith({
    int? id,
    int? tourneeId,
    String? adresseBrute,
    Value<String?> adresseNormalisee = const Value.absent(),
    String? type,
    Value<double?> lat = const Value.absent(),
    Value<double?> lng = const Value.absent(),
    int? nbColis,
    String? priorite,
    Value<String?> fenetreDebut = const Value.absent(),
    Value<String?> fenetreFin = const Value.absent(),
    int? dureeArretMin,
    Value<String?> notes = const Value.absent(),
    Value<String?> nomClient = const Value.absent(),
    Value<String?> telephone = const Value.absent(),
    String? statutLivraison,
    Value<String?> raisonEchec = const Value.absent(),
    Value<double?> livreLat = const Value.absent(),
    Value<double?> livreLng = const Value.absent(),
    Value<DateTime?> livreLe = const Value.absent(),
    Value<int?> ordreOptimise = const Value.absent(),
    bool? positionLocked,
    Value<int?> ordrePriorite = const Value.absent(),
    Value<String?> preuvePhotoPath = const Value.absent(),
    Value<int?> coequipierId = const Value.absent(),
    DateTime? creeLe,
    Value<String?> cloudId = const Value.absent(),
    Value<String?> cloudPhotoPath = const Value.absent(),
    DateTime? updatedAt,
    Value<String?> trackingNumbers = const Value.absent(),
    Value<String?> memoVocal = const Value.absent(),
    bool? deposeSansContact,
    Value<double?> montantCod = const Value.absent(),
    bool? codPaye,
    Value<String?> notationEmoji = const Value.absent(),
  }) => Stop(
    id: id ?? this.id,
    tourneeId: tourneeId ?? this.tourneeId,
    adresseBrute: adresseBrute ?? this.adresseBrute,
    adresseNormalisee: adresseNormalisee.present
        ? adresseNormalisee.value
        : this.adresseNormalisee,
    type: type ?? this.type,
    lat: lat.present ? lat.value : this.lat,
    lng: lng.present ? lng.value : this.lng,
    nbColis: nbColis ?? this.nbColis,
    priorite: priorite ?? this.priorite,
    fenetreDebut: fenetreDebut.present ? fenetreDebut.value : this.fenetreDebut,
    fenetreFin: fenetreFin.present ? fenetreFin.value : this.fenetreFin,
    dureeArretMin: dureeArretMin ?? this.dureeArretMin,
    notes: notes.present ? notes.value : this.notes,
    nomClient: nomClient.present ? nomClient.value : this.nomClient,
    telephone: telephone.present ? telephone.value : this.telephone,
    statutLivraison: statutLivraison ?? this.statutLivraison,
    raisonEchec: raisonEchec.present ? raisonEchec.value : this.raisonEchec,
    livreLat: livreLat.present ? livreLat.value : this.livreLat,
    livreLng: livreLng.present ? livreLng.value : this.livreLng,
    livreLe: livreLe.present ? livreLe.value : this.livreLe,
    ordreOptimise: ordreOptimise.present
        ? ordreOptimise.value
        : this.ordreOptimise,
    positionLocked: positionLocked ?? this.positionLocked,
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
    trackingNumbers: trackingNumbers.present
        ? trackingNumbers.value
        : this.trackingNumbers,
    memoVocal: memoVocal.present ? memoVocal.value : this.memoVocal,
    deposeSansContact: deposeSansContact ?? this.deposeSansContact,
    montantCod: montantCod.present ? montantCod.value : this.montantCod,
    codPaye: codPaye ?? this.codPaye,
    notationEmoji: notationEmoji.present
        ? notationEmoji.value
        : this.notationEmoji,
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
      type: data.type.present ? data.type.value : this.type,
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
      telephone: data.telephone.present ? data.telephone.value : this.telephone,
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
      positionLocked: data.positionLocked.present
          ? data.positionLocked.value
          : this.positionLocked,
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
      trackingNumbers: data.trackingNumbers.present
          ? data.trackingNumbers.value
          : this.trackingNumbers,
      memoVocal: data.memoVocal.present ? data.memoVocal.value : this.memoVocal,
      deposeSansContact: data.deposeSansContact.present
          ? data.deposeSansContact.value
          : this.deposeSansContact,
      montantCod: data.montantCod.present
          ? data.montantCod.value
          : this.montantCod,
      codPaye: data.codPaye.present ? data.codPaye.value : this.codPaye,
      notationEmoji: data.notationEmoji.present
          ? data.notationEmoji.value
          : this.notationEmoji,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Stop(')
          ..write('id: $id, ')
          ..write('tourneeId: $tourneeId, ')
          ..write('adresseBrute: $adresseBrute, ')
          ..write('adresseNormalisee: $adresseNormalisee, ')
          ..write('type: $type, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('nbColis: $nbColis, ')
          ..write('priorite: $priorite, ')
          ..write('fenetreDebut: $fenetreDebut, ')
          ..write('fenetreFin: $fenetreFin, ')
          ..write('dureeArretMin: $dureeArretMin, ')
          ..write('notes: $notes, ')
          ..write('nomClient: $nomClient, ')
          ..write('telephone: $telephone, ')
          ..write('statutLivraison: $statutLivraison, ')
          ..write('raisonEchec: $raisonEchec, ')
          ..write('livreLat: $livreLat, ')
          ..write('livreLng: $livreLng, ')
          ..write('livreLe: $livreLe, ')
          ..write('ordreOptimise: $ordreOptimise, ')
          ..write('positionLocked: $positionLocked, ')
          ..write('ordrePriorite: $ordrePriorite, ')
          ..write('preuvePhotoPath: $preuvePhotoPath, ')
          ..write('coequipierId: $coequipierId, ')
          ..write('creeLe: $creeLe, ')
          ..write('cloudId: $cloudId, ')
          ..write('cloudPhotoPath: $cloudPhotoPath, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('trackingNumbers: $trackingNumbers, ')
          ..write('memoVocal: $memoVocal, ')
          ..write('deposeSansContact: $deposeSansContact, ')
          ..write('montantCod: $montantCod, ')
          ..write('codPaye: $codPaye, ')
          ..write('notationEmoji: $notationEmoji')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    tourneeId,
    adresseBrute,
    adresseNormalisee,
    type,
    lat,
    lng,
    nbColis,
    priorite,
    fenetreDebut,
    fenetreFin,
    dureeArretMin,
    notes,
    nomClient,
    telephone,
    statutLivraison,
    raisonEchec,
    livreLat,
    livreLng,
    livreLe,
    ordreOptimise,
    positionLocked,
    ordrePriorite,
    preuvePhotoPath,
    coequipierId,
    creeLe,
    cloudId,
    cloudPhotoPath,
    updatedAt,
    trackingNumbers,
    memoVocal,
    deposeSansContact,
    montantCod,
    codPaye,
    notationEmoji,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Stop &&
          other.id == this.id &&
          other.tourneeId == this.tourneeId &&
          other.adresseBrute == this.adresseBrute &&
          other.adresseNormalisee == this.adresseNormalisee &&
          other.type == this.type &&
          other.lat == this.lat &&
          other.lng == this.lng &&
          other.nbColis == this.nbColis &&
          other.priorite == this.priorite &&
          other.fenetreDebut == this.fenetreDebut &&
          other.fenetreFin == this.fenetreFin &&
          other.dureeArretMin == this.dureeArretMin &&
          other.notes == this.notes &&
          other.nomClient == this.nomClient &&
          other.telephone == this.telephone &&
          other.statutLivraison == this.statutLivraison &&
          other.raisonEchec == this.raisonEchec &&
          other.livreLat == this.livreLat &&
          other.livreLng == this.livreLng &&
          other.livreLe == this.livreLe &&
          other.ordreOptimise == this.ordreOptimise &&
          other.positionLocked == this.positionLocked &&
          other.ordrePriorite == this.ordrePriorite &&
          other.preuvePhotoPath == this.preuvePhotoPath &&
          other.coequipierId == this.coequipierId &&
          other.creeLe == this.creeLe &&
          other.cloudId == this.cloudId &&
          other.cloudPhotoPath == this.cloudPhotoPath &&
          other.updatedAt == this.updatedAt &&
          other.trackingNumbers == this.trackingNumbers &&
          other.memoVocal == this.memoVocal &&
          other.deposeSansContact == this.deposeSansContact &&
          other.montantCod == this.montantCod &&
          other.codPaye == this.codPaye &&
          other.notationEmoji == this.notationEmoji);
}

class StopsCompanion extends UpdateCompanion<Stop> {
  final Value<int> id;
  final Value<int> tourneeId;
  final Value<String> adresseBrute;
  final Value<String?> adresseNormalisee;
  final Value<String> type;
  final Value<double?> lat;
  final Value<double?> lng;
  final Value<int> nbColis;
  final Value<String> priorite;
  final Value<String?> fenetreDebut;
  final Value<String?> fenetreFin;
  final Value<int> dureeArretMin;
  final Value<String?> notes;
  final Value<String?> nomClient;
  final Value<String?> telephone;
  final Value<String> statutLivraison;
  final Value<String?> raisonEchec;
  final Value<double?> livreLat;
  final Value<double?> livreLng;
  final Value<DateTime?> livreLe;
  final Value<int?> ordreOptimise;
  final Value<bool> positionLocked;
  final Value<int?> ordrePriorite;
  final Value<String?> preuvePhotoPath;
  final Value<int?> coequipierId;
  final Value<DateTime> creeLe;
  final Value<String?> cloudId;
  final Value<String?> cloudPhotoPath;
  final Value<DateTime> updatedAt;
  final Value<String?> trackingNumbers;
  final Value<String?> memoVocal;
  final Value<bool> deposeSansContact;
  final Value<double?> montantCod;
  final Value<bool> codPaye;
  final Value<String?> notationEmoji;
  const StopsCompanion({
    this.id = const Value.absent(),
    this.tourneeId = const Value.absent(),
    this.adresseBrute = const Value.absent(),
    this.adresseNormalisee = const Value.absent(),
    this.type = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.nbColis = const Value.absent(),
    this.priorite = const Value.absent(),
    this.fenetreDebut = const Value.absent(),
    this.fenetreFin = const Value.absent(),
    this.dureeArretMin = const Value.absent(),
    this.notes = const Value.absent(),
    this.nomClient = const Value.absent(),
    this.telephone = const Value.absent(),
    this.statutLivraison = const Value.absent(),
    this.raisonEchec = const Value.absent(),
    this.livreLat = const Value.absent(),
    this.livreLng = const Value.absent(),
    this.livreLe = const Value.absent(),
    this.ordreOptimise = const Value.absent(),
    this.positionLocked = const Value.absent(),
    this.ordrePriorite = const Value.absent(),
    this.preuvePhotoPath = const Value.absent(),
    this.coequipierId = const Value.absent(),
    this.creeLe = const Value.absent(),
    this.cloudId = const Value.absent(),
    this.cloudPhotoPath = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.trackingNumbers = const Value.absent(),
    this.memoVocal = const Value.absent(),
    this.deposeSansContact = const Value.absent(),
    this.montantCod = const Value.absent(),
    this.codPaye = const Value.absent(),
    this.notationEmoji = const Value.absent(),
  });
  StopsCompanion.insert({
    this.id = const Value.absent(),
    required int tourneeId,
    required String adresseBrute,
    this.adresseNormalisee = const Value.absent(),
    this.type = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.nbColis = const Value.absent(),
    this.priorite = const Value.absent(),
    this.fenetreDebut = const Value.absent(),
    this.fenetreFin = const Value.absent(),
    this.dureeArretMin = const Value.absent(),
    this.notes = const Value.absent(),
    this.nomClient = const Value.absent(),
    this.telephone = const Value.absent(),
    this.statutLivraison = const Value.absent(),
    this.raisonEchec = const Value.absent(),
    this.livreLat = const Value.absent(),
    this.livreLng = const Value.absent(),
    this.livreLe = const Value.absent(),
    this.ordreOptimise = const Value.absent(),
    this.positionLocked = const Value.absent(),
    this.ordrePriorite = const Value.absent(),
    this.preuvePhotoPath = const Value.absent(),
    this.coequipierId = const Value.absent(),
    this.creeLe = const Value.absent(),
    this.cloudId = const Value.absent(),
    this.cloudPhotoPath = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.trackingNumbers = const Value.absent(),
    this.memoVocal = const Value.absent(),
    this.deposeSansContact = const Value.absent(),
    this.montantCod = const Value.absent(),
    this.codPaye = const Value.absent(),
    this.notationEmoji = const Value.absent(),
  }) : tourneeId = Value(tourneeId),
       adresseBrute = Value(adresseBrute);
  static Insertable<Stop> custom({
    Expression<int>? id,
    Expression<int>? tourneeId,
    Expression<String>? adresseBrute,
    Expression<String>? adresseNormalisee,
    Expression<String>? type,
    Expression<double>? lat,
    Expression<double>? lng,
    Expression<int>? nbColis,
    Expression<String>? priorite,
    Expression<String>? fenetreDebut,
    Expression<String>? fenetreFin,
    Expression<int>? dureeArretMin,
    Expression<String>? notes,
    Expression<String>? nomClient,
    Expression<String>? telephone,
    Expression<String>? statutLivraison,
    Expression<String>? raisonEchec,
    Expression<double>? livreLat,
    Expression<double>? livreLng,
    Expression<DateTime>? livreLe,
    Expression<int>? ordreOptimise,
    Expression<bool>? positionLocked,
    Expression<int>? ordrePriorite,
    Expression<String>? preuvePhotoPath,
    Expression<int>? coequipierId,
    Expression<DateTime>? creeLe,
    Expression<String>? cloudId,
    Expression<String>? cloudPhotoPath,
    Expression<DateTime>? updatedAt,
    Expression<String>? trackingNumbers,
    Expression<String>? memoVocal,
    Expression<bool>? deposeSansContact,
    Expression<double>? montantCod,
    Expression<bool>? codPaye,
    Expression<String>? notationEmoji,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tourneeId != null) 'tournee_id': tourneeId,
      if (adresseBrute != null) 'adresse_brute': adresseBrute,
      if (adresseNormalisee != null) 'adresse_normalisee': adresseNormalisee,
      if (type != null) 'type': type,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (nbColis != null) 'nb_colis': nbColis,
      if (priorite != null) 'priorite': priorite,
      if (fenetreDebut != null) 'fenetre_debut': fenetreDebut,
      if (fenetreFin != null) 'fenetre_fin': fenetreFin,
      if (dureeArretMin != null) 'duree_arret_min': dureeArretMin,
      if (notes != null) 'notes': notes,
      if (nomClient != null) 'nom_client': nomClient,
      if (telephone != null) 'telephone': telephone,
      if (statutLivraison != null) 'statut_livraison': statutLivraison,
      if (raisonEchec != null) 'raison_echec': raisonEchec,
      if (livreLat != null) 'livre_lat': livreLat,
      if (livreLng != null) 'livre_lng': livreLng,
      if (livreLe != null) 'livre_le': livreLe,
      if (ordreOptimise != null) 'ordre_optimise': ordreOptimise,
      if (positionLocked != null) 'position_locked': positionLocked,
      if (ordrePriorite != null) 'ordre_priorite': ordrePriorite,
      if (preuvePhotoPath != null) 'preuve_photo_path': preuvePhotoPath,
      if (coequipierId != null) 'coequipier_id': coequipierId,
      if (creeLe != null) 'cree_le': creeLe,
      if (cloudId != null) 'cloud_id': cloudId,
      if (cloudPhotoPath != null) 'cloud_photo_path': cloudPhotoPath,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (trackingNumbers != null) 'tracking_numbers': trackingNumbers,
      if (memoVocal != null) 'memo_vocal': memoVocal,
      if (deposeSansContact != null) 'depose_sans_contact': deposeSansContact,
      if (montantCod != null) 'montant_cod': montantCod,
      if (codPaye != null) 'cod_paye': codPaye,
      if (notationEmoji != null) 'notation_emoji': notationEmoji,
    });
  }

  StopsCompanion copyWith({
    Value<int>? id,
    Value<int>? tourneeId,
    Value<String>? adresseBrute,
    Value<String?>? adresseNormalisee,
    Value<String>? type,
    Value<double?>? lat,
    Value<double?>? lng,
    Value<int>? nbColis,
    Value<String>? priorite,
    Value<String?>? fenetreDebut,
    Value<String?>? fenetreFin,
    Value<int>? dureeArretMin,
    Value<String?>? notes,
    Value<String?>? nomClient,
    Value<String?>? telephone,
    Value<String>? statutLivraison,
    Value<String?>? raisonEchec,
    Value<double?>? livreLat,
    Value<double?>? livreLng,
    Value<DateTime?>? livreLe,
    Value<int?>? ordreOptimise,
    Value<bool>? positionLocked,
    Value<int?>? ordrePriorite,
    Value<String?>? preuvePhotoPath,
    Value<int?>? coequipierId,
    Value<DateTime>? creeLe,
    Value<String?>? cloudId,
    Value<String?>? cloudPhotoPath,
    Value<DateTime>? updatedAt,
    Value<String?>? trackingNumbers,
    Value<String?>? memoVocal,
    Value<bool>? deposeSansContact,
    Value<double?>? montantCod,
    Value<bool>? codPaye,
    Value<String?>? notationEmoji,
  }) {
    return StopsCompanion(
      id: id ?? this.id,
      tourneeId: tourneeId ?? this.tourneeId,
      adresseBrute: adresseBrute ?? this.adresseBrute,
      adresseNormalisee: adresseNormalisee ?? this.adresseNormalisee,
      type: type ?? this.type,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      nbColis: nbColis ?? this.nbColis,
      priorite: priorite ?? this.priorite,
      fenetreDebut: fenetreDebut ?? this.fenetreDebut,
      fenetreFin: fenetreFin ?? this.fenetreFin,
      dureeArretMin: dureeArretMin ?? this.dureeArretMin,
      notes: notes ?? this.notes,
      nomClient: nomClient ?? this.nomClient,
      telephone: telephone ?? this.telephone,
      statutLivraison: statutLivraison ?? this.statutLivraison,
      raisonEchec: raisonEchec ?? this.raisonEchec,
      livreLat: livreLat ?? this.livreLat,
      livreLng: livreLng ?? this.livreLng,
      livreLe: livreLe ?? this.livreLe,
      ordreOptimise: ordreOptimise ?? this.ordreOptimise,
      positionLocked: positionLocked ?? this.positionLocked,
      ordrePriorite: ordrePriorite ?? this.ordrePriorite,
      preuvePhotoPath: preuvePhotoPath ?? this.preuvePhotoPath,
      coequipierId: coequipierId ?? this.coequipierId,
      creeLe: creeLe ?? this.creeLe,
      cloudId: cloudId ?? this.cloudId,
      cloudPhotoPath: cloudPhotoPath ?? this.cloudPhotoPath,
      updatedAt: updatedAt ?? this.updatedAt,
      trackingNumbers: trackingNumbers ?? this.trackingNumbers,
      memoVocal: memoVocal ?? this.memoVocal,
      deposeSansContact: deposeSansContact ?? this.deposeSansContact,
      montantCod: montantCod ?? this.montantCod,
      codPaye: codPaye ?? this.codPaye,
      notationEmoji: notationEmoji ?? this.notationEmoji,
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
    if (type.present) {
      map['type'] = Variable<String>(type.value);
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
    if (telephone.present) {
      map['telephone'] = Variable<String>(telephone.value);
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
    if (positionLocked.present) {
      map['position_locked'] = Variable<bool>(positionLocked.value);
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
    if (trackingNumbers.present) {
      map['tracking_numbers'] = Variable<String>(trackingNumbers.value);
    }
    if (memoVocal.present) {
      map['memo_vocal'] = Variable<String>(memoVocal.value);
    }
    if (deposeSansContact.present) {
      map['depose_sans_contact'] = Variable<bool>(deposeSansContact.value);
    }
    if (montantCod.present) {
      map['montant_cod'] = Variable<double>(montantCod.value);
    }
    if (codPaye.present) {
      map['cod_paye'] = Variable<bool>(codPaye.value);
    }
    if (notationEmoji.present) {
      map['notation_emoji'] = Variable<String>(notationEmoji.value);
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
          ..write('type: $type, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('nbColis: $nbColis, ')
          ..write('priorite: $priorite, ')
          ..write('fenetreDebut: $fenetreDebut, ')
          ..write('fenetreFin: $fenetreFin, ')
          ..write('dureeArretMin: $dureeArretMin, ')
          ..write('notes: $notes, ')
          ..write('nomClient: $nomClient, ')
          ..write('telephone: $telephone, ')
          ..write('statutLivraison: $statutLivraison, ')
          ..write('raisonEchec: $raisonEchec, ')
          ..write('livreLat: $livreLat, ')
          ..write('livreLng: $livreLng, ')
          ..write('livreLe: $livreLe, ')
          ..write('ordreOptimise: $ordreOptimise, ')
          ..write('positionLocked: $positionLocked, ')
          ..write('ordrePriorite: $ordrePriorite, ')
          ..write('preuvePhotoPath: $preuvePhotoPath, ')
          ..write('coequipierId: $coequipierId, ')
          ..write('creeLe: $creeLe, ')
          ..write('cloudId: $cloudId, ')
          ..write('cloudPhotoPath: $cloudPhotoPath, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('trackingNumbers: $trackingNumbers, ')
          ..write('memoVocal: $memoVocal, ')
          ..write('deposeSansContact: $deposeSansContact, ')
          ..write('montantCod: $montantCod, ')
          ..write('codPaye: $codPaye, ')
          ..write('notationEmoji: $notationEmoji')
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
  static const VerificationMeta _noteStationnementMeta = const VerificationMeta(
    'noteStationnement',
  );
  @override
  late final GeneratedColumn<String> noteStationnement =
      GeneratedColumn<String>(
        'note_stationnement',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _isProblematiqueMeta = const VerificationMeta(
    'isProblematique',
  );
  @override
  late final GeneratedColumn<bool> isProblematique = GeneratedColumn<bool>(
    'is_problematique',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_problematique" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _photoObligatoireMeta = const VerificationMeta(
    'photoObligatoire',
  );
  @override
  late final GeneratedColumn<bool> photoObligatoire = GeneratedColumn<bool>(
    'photo_obligatoire',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("photo_obligatoire" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _preferencePersonnaliseeMeta =
      const VerificationMeta('preferencePersonnalisee');
  @override
  late final GeneratedColumn<String> preferencePersonnalisee =
      GeneratedColumn<String>(
        'preference_personnalisee',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _entrepriseIdMeta = const VerificationMeta(
    'entrepriseId',
  );
  @override
  late final GeneratedColumn<String> entrepriseId = GeneratedColumn<String>(
    'entreprise_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _entrepotIdMeta = const VerificationMeta(
    'entrepotId',
  );
  @override
  late final GeneratedColumn<String> entrepotId = GeneratedColumn<String>(
    'entrepot_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    telephone,
    cloudId,
    updatedAt,
    noteStationnement,
    isProblematique,
    photoObligatoire,
    preferencePersonnalisee,
    entrepriseId,
    entrepotId,
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
    if (data.containsKey('telephone')) {
      context.handle(
        _telephoneMeta,
        telephone.isAcceptableOrUnknown(data['telephone']!, _telephoneMeta),
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
    if (data.containsKey('note_stationnement')) {
      context.handle(
        _noteStationnementMeta,
        noteStationnement.isAcceptableOrUnknown(
          data['note_stationnement']!,
          _noteStationnementMeta,
        ),
      );
    }
    if (data.containsKey('is_problematique')) {
      context.handle(
        _isProblematiqueMeta,
        isProblematique.isAcceptableOrUnknown(
          data['is_problematique']!,
          _isProblematiqueMeta,
        ),
      );
    }
    if (data.containsKey('photo_obligatoire')) {
      context.handle(
        _photoObligatoireMeta,
        photoObligatoire.isAcceptableOrUnknown(
          data['photo_obligatoire']!,
          _photoObligatoireMeta,
        ),
      );
    }
    if (data.containsKey('preference_personnalisee')) {
      context.handle(
        _preferencePersonnaliseeMeta,
        preferencePersonnalisee.isAcceptableOrUnknown(
          data['preference_personnalisee']!,
          _preferencePersonnaliseeMeta,
        ),
      );
    }
    if (data.containsKey('entreprise_id')) {
      context.handle(
        _entrepriseIdMeta,
        entrepriseId.isAcceptableOrUnknown(
          data['entreprise_id']!,
          _entrepriseIdMeta,
        ),
      );
    }
    if (data.containsKey('entrepot_id')) {
      context.handle(
        _entrepotIdMeta,
        entrepotId.isAcceptableOrUnknown(data['entrepot_id']!, _entrepotIdMeta),
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
      telephone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}telephone'],
      ),
      cloudId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cloud_id'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      noteStationnement: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note_stationnement'],
      ),
      isProblematique: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_problematique'],
      )!,
      photoObligatoire: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}photo_obligatoire'],
      )!,
      preferencePersonnalisee: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preference_personnalisee'],
      ),
      entrepriseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entreprise_id'],
      ),
      entrepotId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entrepot_id'],
      ),
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

  /// Numero de telephone du client. Format libre (06xxx, +33xxx, fixe
  /// 02xxx, etc.). Affiche dans la fiche client avec un bouton "Appeler"
  /// qui lance `tel:<numero>` via url_launcher. Ajoute schema v35
  /// (carte Trello #106).
  final String? telephone;

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

  /// Note libre sur ou se garer pour cette adresse (carte #288), ex:
  /// "parking sous-sol entree D" / "place handicapee derriere".
  /// Rejoue a chaque retour chez ce client. Nullable.
  final String? noteStationnement;

  /// True si l'adresse est marquee "vigilance" (carte #292) : echecs
  /// repetes, acces camion complique, client agressif, fausse adresse.
  /// Affiche un badge rouge quand elle reapparait dans une tournee.
  final bool isProblematique;

  /// True si une photo de preuve est OBLIGATOIRE pour pouvoir marquer
  /// "livre" sur un stop a cette adresse (carte #301). L'UI doit
  /// bloquer le bouton tant que preuvePhotoPath est null.
  final bool photoObligatoire;

  /// Preference persistante du client (carte #335), ex: "Sonner 2 fois",
  /// "Ne supporte pas le depot sans signature", "Code change tous les
  /// mois". Affichee en gros a l'arrivee. Distinct de `notesCarnet`
  /// (libre) : `preferencePersonnalisee` est une consigne forte qu'on
  /// doit voir avant chaque livraison.
  final String? preferencePersonnalisee;

  /// Carnet partage entreprise (epopee #361, carte #362). UUID de
  /// `entreprises.cloud_id`. Si NULL : adresse perso au user.
  /// Si set + entrepotId NULL : adresse partagee au niveau entreprise
  /// entier (mutualisee tous les entrepots).
  /// Si set + entrepotId set : adresse rattachee a un entrepot
  /// specifique (carnet entrepot local).
  final String? entrepriseId;

  /// FK locale optionnelle vers `entrepots.cloud_id`. Voir
  /// `entrepriseId` ci-dessus pour la semantique.
  final String? entrepotId;
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
    this.telephone,
    this.cloudId,
    required this.updatedAt,
    this.noteStationnement,
    required this.isProblematique,
    required this.photoObligatoire,
    this.preferencePersonnalisee,
    this.entrepriseId,
    this.entrepotId,
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
    if (!nullToAbsent || telephone != null) {
      map['telephone'] = Variable<String>(telephone);
    }
    if (!nullToAbsent || cloudId != null) {
      map['cloud_id'] = Variable<String>(cloudId);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || noteStationnement != null) {
      map['note_stationnement'] = Variable<String>(noteStationnement);
    }
    map['is_problematique'] = Variable<bool>(isProblematique);
    map['photo_obligatoire'] = Variable<bool>(photoObligatoire);
    if (!nullToAbsent || preferencePersonnalisee != null) {
      map['preference_personnalisee'] = Variable<String>(
        preferencePersonnalisee,
      );
    }
    if (!nullToAbsent || entrepriseId != null) {
      map['entreprise_id'] = Variable<String>(entrepriseId);
    }
    if (!nullToAbsent || entrepotId != null) {
      map['entrepot_id'] = Variable<String>(entrepotId);
    }
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
      telephone: telephone == null && nullToAbsent
          ? const Value.absent()
          : Value(telephone),
      cloudId: cloudId == null && nullToAbsent
          ? const Value.absent()
          : Value(cloudId),
      updatedAt: Value(updatedAt),
      noteStationnement: noteStationnement == null && nullToAbsent
          ? const Value.absent()
          : Value(noteStationnement),
      isProblematique: Value(isProblematique),
      photoObligatoire: Value(photoObligatoire),
      preferencePersonnalisee: preferencePersonnalisee == null && nullToAbsent
          ? const Value.absent()
          : Value(preferencePersonnalisee),
      entrepriseId: entrepriseId == null && nullToAbsent
          ? const Value.absent()
          : Value(entrepriseId),
      entrepotId: entrepotId == null && nullToAbsent
          ? const Value.absent()
          : Value(entrepotId),
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
      telephone: serializer.fromJson<String?>(json['telephone']),
      cloudId: serializer.fromJson<String?>(json['cloudId']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      noteStationnement: serializer.fromJson<String?>(
        json['noteStationnement'],
      ),
      isProblematique: serializer.fromJson<bool>(json['isProblematique']),
      photoObligatoire: serializer.fromJson<bool>(json['photoObligatoire']),
      preferencePersonnalisee: serializer.fromJson<String?>(
        json['preferencePersonnalisee'],
      ),
      entrepriseId: serializer.fromJson<String?>(json['entrepriseId']),
      entrepotId: serializer.fromJson<String?>(json['entrepotId']),
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
      'telephone': serializer.toJson<String?>(telephone),
      'cloudId': serializer.toJson<String?>(cloudId),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'noteStationnement': serializer.toJson<String?>(noteStationnement),
      'isProblematique': serializer.toJson<bool>(isProblematique),
      'photoObligatoire': serializer.toJson<bool>(photoObligatoire),
      'preferencePersonnalisee': serializer.toJson<String?>(
        preferencePersonnalisee,
      ),
      'entrepriseId': serializer.toJson<String?>(entrepriseId),
      'entrepotId': serializer.toJson<String?>(entrepotId),
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
    Value<String?> telephone = const Value.absent(),
    Value<String?> cloudId = const Value.absent(),
    DateTime? updatedAt,
    Value<String?> noteStationnement = const Value.absent(),
    bool? isProblematique,
    bool? photoObligatoire,
    Value<String?> preferencePersonnalisee = const Value.absent(),
    Value<String?> entrepriseId = const Value.absent(),
    Value<String?> entrepotId = const Value.absent(),
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
    telephone: telephone.present ? telephone.value : this.telephone,
    cloudId: cloudId.present ? cloudId.value : this.cloudId,
    updatedAt: updatedAt ?? this.updatedAt,
    noteStationnement: noteStationnement.present
        ? noteStationnement.value
        : this.noteStationnement,
    isProblematique: isProblematique ?? this.isProblematique,
    photoObligatoire: photoObligatoire ?? this.photoObligatoire,
    preferencePersonnalisee: preferencePersonnalisee.present
        ? preferencePersonnalisee.value
        : this.preferencePersonnalisee,
    entrepriseId: entrepriseId.present ? entrepriseId.value : this.entrepriseId,
    entrepotId: entrepotId.present ? entrepotId.value : this.entrepotId,
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
      telephone: data.telephone.present ? data.telephone.value : this.telephone,
      cloudId: data.cloudId.present ? data.cloudId.value : this.cloudId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      noteStationnement: data.noteStationnement.present
          ? data.noteStationnement.value
          : this.noteStationnement,
      isProblematique: data.isProblematique.present
          ? data.isProblematique.value
          : this.isProblematique,
      photoObligatoire: data.photoObligatoire.present
          ? data.photoObligatoire.value
          : this.photoObligatoire,
      preferencePersonnalisee: data.preferencePersonnalisee.present
          ? data.preferencePersonnalisee.value
          : this.preferencePersonnalisee,
      entrepriseId: data.entrepriseId.present
          ? data.entrepriseId.value
          : this.entrepriseId,
      entrepotId: data.entrepotId.present
          ? data.entrepotId.value
          : this.entrepotId,
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
          ..write('telephone: $telephone, ')
          ..write('cloudId: $cloudId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('noteStationnement: $noteStationnement, ')
          ..write('isProblematique: $isProblematique, ')
          ..write('photoObligatoire: $photoObligatoire, ')
          ..write('preferencePersonnalisee: $preferencePersonnalisee, ')
          ..write('entrepriseId: $entrepriseId, ')
          ..write('entrepotId: $entrepotId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
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
    telephone,
    cloudId,
    updatedAt,
    noteStationnement,
    isProblematique,
    photoObligatoire,
    preferencePersonnalisee,
    entrepriseId,
    entrepotId,
  ]);
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
          other.telephone == this.telephone &&
          other.cloudId == this.cloudId &&
          other.updatedAt == this.updatedAt &&
          other.noteStationnement == this.noteStationnement &&
          other.isProblematique == this.isProblematique &&
          other.photoObligatoire == this.photoObligatoire &&
          other.preferencePersonnalisee == this.preferencePersonnalisee &&
          other.entrepriseId == this.entrepriseId &&
          other.entrepotId == this.entrepotId);
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
  final Value<String?> telephone;
  final Value<String?> cloudId;
  final Value<DateTime> updatedAt;
  final Value<String?> noteStationnement;
  final Value<bool> isProblematique;
  final Value<bool> photoObligatoire;
  final Value<String?> preferencePersonnalisee;
  final Value<String?> entrepriseId;
  final Value<String?> entrepotId;
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
    this.telephone = const Value.absent(),
    this.cloudId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.noteStationnement = const Value.absent(),
    this.isProblematique = const Value.absent(),
    this.photoObligatoire = const Value.absent(),
    this.preferencePersonnalisee = const Value.absent(),
    this.entrepriseId = const Value.absent(),
    this.entrepotId = const Value.absent(),
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
    this.telephone = const Value.absent(),
    this.cloudId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.noteStationnement = const Value.absent(),
    this.isProblematique = const Value.absent(),
    this.photoObligatoire = const Value.absent(),
    this.preferencePersonnalisee = const Value.absent(),
    this.entrepriseId = const Value.absent(),
    this.entrepotId = const Value.absent(),
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
    Expression<String>? telephone,
    Expression<String>? cloudId,
    Expression<DateTime>? updatedAt,
    Expression<String>? noteStationnement,
    Expression<bool>? isProblematique,
    Expression<bool>? photoObligatoire,
    Expression<String>? preferencePersonnalisee,
    Expression<String>? entrepriseId,
    Expression<String>? entrepotId,
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
      if (telephone != null) 'telephone': telephone,
      if (cloudId != null) 'cloud_id': cloudId,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (noteStationnement != null) 'note_stationnement': noteStationnement,
      if (isProblematique != null) 'is_problematique': isProblematique,
      if (photoObligatoire != null) 'photo_obligatoire': photoObligatoire,
      if (preferencePersonnalisee != null)
        'preference_personnalisee': preferencePersonnalisee,
      if (entrepriseId != null) 'entreprise_id': entrepriseId,
      if (entrepotId != null) 'entrepot_id': entrepotId,
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
    Value<String?>? telephone,
    Value<String?>? cloudId,
    Value<DateTime>? updatedAt,
    Value<String?>? noteStationnement,
    Value<bool>? isProblematique,
    Value<bool>? photoObligatoire,
    Value<String?>? preferencePersonnalisee,
    Value<String?>? entrepriseId,
    Value<String?>? entrepotId,
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
      telephone: telephone ?? this.telephone,
      cloudId: cloudId ?? this.cloudId,
      updatedAt: updatedAt ?? this.updatedAt,
      noteStationnement: noteStationnement ?? this.noteStationnement,
      isProblematique: isProblematique ?? this.isProblematique,
      photoObligatoire: photoObligatoire ?? this.photoObligatoire,
      preferencePersonnalisee:
          preferencePersonnalisee ?? this.preferencePersonnalisee,
      entrepriseId: entrepriseId ?? this.entrepriseId,
      entrepotId: entrepotId ?? this.entrepotId,
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
    if (telephone.present) {
      map['telephone'] = Variable<String>(telephone.value);
    }
    if (cloudId.present) {
      map['cloud_id'] = Variable<String>(cloudId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (noteStationnement.present) {
      map['note_stationnement'] = Variable<String>(noteStationnement.value);
    }
    if (isProblematique.present) {
      map['is_problematique'] = Variable<bool>(isProblematique.value);
    }
    if (photoObligatoire.present) {
      map['photo_obligatoire'] = Variable<bool>(photoObligatoire.value);
    }
    if (preferencePersonnalisee.present) {
      map['preference_personnalisee'] = Variable<String>(
        preferencePersonnalisee.value,
      );
    }
    if (entrepriseId.present) {
      map['entreprise_id'] = Variable<String>(entrepriseId.value);
    }
    if (entrepotId.present) {
      map['entrepot_id'] = Variable<String>(entrepotId.value);
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
          ..write('telephone: $telephone, ')
          ..write('cloudId: $cloudId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('noteStationnement: $noteStationnement, ')
          ..write('isProblematique: $isProblematique, ')
          ..write('photoObligatoire: $photoObligatoire, ')
          ..write('preferencePersonnalisee: $preferencePersonnalisee, ')
          ..write('entrepriseId: $entrepriseId, ')
          ..write('entrepotId: $entrepotId')
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

class $FraisTable extends Frais with TableInfo<$FraisTable, Frai> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FraisTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 20,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _montantCentimesMeta = const VerificationMeta(
    'montantCentimes',
  );
  @override
  late final GeneratedColumn<int> montantCentimes = GeneratedColumn<int>(
    'montant_centimes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _libelleMeta = const VerificationMeta(
    'libelle',
  );
  @override
  late final GeneratedColumn<String> libelle = GeneratedColumn<String>(
    'libelle',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 80,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _tourneeIdMeta = const VerificationMeta(
    'tourneeId',
  );
  @override
  late final GeneratedColumn<int> tourneeId = GeneratedColumn<int>(
    'tournee_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
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
    date,
    type,
    montantCentimes,
    libelle,
    notes,
    tourneeId,
    photoPath,
    creeLe,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'frais';
  @override
  VerificationContext validateIntegrity(
    Insertable<Frai> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('montant_centimes')) {
      context.handle(
        _montantCentimesMeta,
        montantCentimes.isAcceptableOrUnknown(
          data['montant_centimes']!,
          _montantCentimesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_montantCentimesMeta);
    }
    if (data.containsKey('libelle')) {
      context.handle(
        _libelleMeta,
        libelle.isAcceptableOrUnknown(data['libelle']!, _libelleMeta),
      );
    } else if (isInserting) {
      context.missing(_libelleMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('tournee_id')) {
      context.handle(
        _tourneeIdMeta,
        tourneeId.isAcceptableOrUnknown(data['tournee_id']!, _tourneeIdMeta),
      );
    }
    if (data.containsKey('photo_path')) {
      context.handle(
        _photoPathMeta,
        photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta),
      );
    }
    if (data.containsKey('cree_le')) {
      context.handle(
        _creeLeMeta,
        creeLe.isAcceptableOrUnknown(data['cree_le']!, _creeLeMeta),
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
  Frai map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Frai(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      montantCentimes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}montant_centimes'],
      )!,
      libelle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}libelle'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      tourneeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tournee_id'],
      ),
      photoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_path'],
      ),
      creeLe: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cree_le'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $FraisTable createAlias(String alias) {
    return $FraisTable(attachedDatabase, alias);
  }
}

class Frai extends DataClass implements Insertable<Frai> {
  final int id;

  /// Date de la depense (jour, pas heure precise). Stocke en DateTime
  /// pour faciliter les filtres par mois / annee.
  final DateTime date;

  /// Type : 'carburant', 'peage', 'parking', 'repas', 'autre'.
  /// String libre (pas un enum Drift) pour permettre l'evolution sans
  /// migration de schema.
  final String type;

  /// Montant en CENTIMES (entier). Evite les imprecisions float
  /// (`15.30` -> `15.299999...`). 1235 = 12,35 EUR.
  final int montantCentimes;

  /// Libelle court (ex: "Station Total Luce", "Peage A11 sortie 4").
  /// Max 80 chars pour rester lisible dans la liste sans wrap excessif.
  final String libelle;

  /// Notes complementaires optionnelles (numero de facture, contexte,
  /// "remboursable par client X", etc.).
  final String? notes;

  /// Rattachement optionnel a une tournee. Null = depense generale
  /// (carburant maison, parking permanent, etc.).
  final int? tourneeId;

  /// Chemin local de la photo du justificatif (ticket / facture).
  /// Null si pas de photo. Stocke en
  /// `getApplicationDocumentsDirectory()/frais_photos/<id>.jpg`.
  final String? photoPath;
  final DateTime creeLe;
  final DateTime updatedAt;
  const Frai({
    required this.id,
    required this.date,
    required this.type,
    required this.montantCentimes,
    required this.libelle,
    this.notes,
    this.tourneeId,
    this.photoPath,
    required this.creeLe,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    map['type'] = Variable<String>(type);
    map['montant_centimes'] = Variable<int>(montantCentimes);
    map['libelle'] = Variable<String>(libelle);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || tourneeId != null) {
      map['tournee_id'] = Variable<int>(tourneeId);
    }
    if (!nullToAbsent || photoPath != null) {
      map['photo_path'] = Variable<String>(photoPath);
    }
    map['cree_le'] = Variable<DateTime>(creeLe);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  FraisCompanion toCompanion(bool nullToAbsent) {
    return FraisCompanion(
      id: Value(id),
      date: Value(date),
      type: Value(type),
      montantCentimes: Value(montantCentimes),
      libelle: Value(libelle),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      tourneeId: tourneeId == null && nullToAbsent
          ? const Value.absent()
          : Value(tourneeId),
      photoPath: photoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoPath),
      creeLe: Value(creeLe),
      updatedAt: Value(updatedAt),
    );
  }

  factory Frai.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Frai(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      type: serializer.fromJson<String>(json['type']),
      montantCentimes: serializer.fromJson<int>(json['montantCentimes']),
      libelle: serializer.fromJson<String>(json['libelle']),
      notes: serializer.fromJson<String?>(json['notes']),
      tourneeId: serializer.fromJson<int?>(json['tourneeId']),
      photoPath: serializer.fromJson<String?>(json['photoPath']),
      creeLe: serializer.fromJson<DateTime>(json['creeLe']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'type': serializer.toJson<String>(type),
      'montantCentimes': serializer.toJson<int>(montantCentimes),
      'libelle': serializer.toJson<String>(libelle),
      'notes': serializer.toJson<String?>(notes),
      'tourneeId': serializer.toJson<int?>(tourneeId),
      'photoPath': serializer.toJson<String?>(photoPath),
      'creeLe': serializer.toJson<DateTime>(creeLe),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Frai copyWith({
    int? id,
    DateTime? date,
    String? type,
    int? montantCentimes,
    String? libelle,
    Value<String?> notes = const Value.absent(),
    Value<int?> tourneeId = const Value.absent(),
    Value<String?> photoPath = const Value.absent(),
    DateTime? creeLe,
    DateTime? updatedAt,
  }) => Frai(
    id: id ?? this.id,
    date: date ?? this.date,
    type: type ?? this.type,
    montantCentimes: montantCentimes ?? this.montantCentimes,
    libelle: libelle ?? this.libelle,
    notes: notes.present ? notes.value : this.notes,
    tourneeId: tourneeId.present ? tourneeId.value : this.tourneeId,
    photoPath: photoPath.present ? photoPath.value : this.photoPath,
    creeLe: creeLe ?? this.creeLe,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Frai copyWithCompanion(FraisCompanion data) {
    return Frai(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      type: data.type.present ? data.type.value : this.type,
      montantCentimes: data.montantCentimes.present
          ? data.montantCentimes.value
          : this.montantCentimes,
      libelle: data.libelle.present ? data.libelle.value : this.libelle,
      notes: data.notes.present ? data.notes.value : this.notes,
      tourneeId: data.tourneeId.present ? data.tourneeId.value : this.tourneeId,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
      creeLe: data.creeLe.present ? data.creeLe.value : this.creeLe,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Frai(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('type: $type, ')
          ..write('montantCentimes: $montantCentimes, ')
          ..write('libelle: $libelle, ')
          ..write('notes: $notes, ')
          ..write('tourneeId: $tourneeId, ')
          ..write('photoPath: $photoPath, ')
          ..write('creeLe: $creeLe, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    date,
    type,
    montantCentimes,
    libelle,
    notes,
    tourneeId,
    photoPath,
    creeLe,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Frai &&
          other.id == this.id &&
          other.date == this.date &&
          other.type == this.type &&
          other.montantCentimes == this.montantCentimes &&
          other.libelle == this.libelle &&
          other.notes == this.notes &&
          other.tourneeId == this.tourneeId &&
          other.photoPath == this.photoPath &&
          other.creeLe == this.creeLe &&
          other.updatedAt == this.updatedAt);
}

class FraisCompanion extends UpdateCompanion<Frai> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<String> type;
  final Value<int> montantCentimes;
  final Value<String> libelle;
  final Value<String?> notes;
  final Value<int?> tourneeId;
  final Value<String?> photoPath;
  final Value<DateTime> creeLe;
  final Value<DateTime> updatedAt;
  const FraisCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.type = const Value.absent(),
    this.montantCentimes = const Value.absent(),
    this.libelle = const Value.absent(),
    this.notes = const Value.absent(),
    this.tourneeId = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.creeLe = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  FraisCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    required String type,
    required int montantCentimes,
    required String libelle,
    this.notes = const Value.absent(),
    this.tourneeId = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.creeLe = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : date = Value(date),
       type = Value(type),
       montantCentimes = Value(montantCentimes),
       libelle = Value(libelle);
  static Insertable<Frai> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<String>? type,
    Expression<int>? montantCentimes,
    Expression<String>? libelle,
    Expression<String>? notes,
    Expression<int>? tourneeId,
    Expression<String>? photoPath,
    Expression<DateTime>? creeLe,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (type != null) 'type': type,
      if (montantCentimes != null) 'montant_centimes': montantCentimes,
      if (libelle != null) 'libelle': libelle,
      if (notes != null) 'notes': notes,
      if (tourneeId != null) 'tournee_id': tourneeId,
      if (photoPath != null) 'photo_path': photoPath,
      if (creeLe != null) 'cree_le': creeLe,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  FraisCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? date,
    Value<String>? type,
    Value<int>? montantCentimes,
    Value<String>? libelle,
    Value<String?>? notes,
    Value<int?>? tourneeId,
    Value<String?>? photoPath,
    Value<DateTime>? creeLe,
    Value<DateTime>? updatedAt,
  }) {
    return FraisCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      type: type ?? this.type,
      montantCentimes: montantCentimes ?? this.montantCentimes,
      libelle: libelle ?? this.libelle,
      notes: notes ?? this.notes,
      tourneeId: tourneeId ?? this.tourneeId,
      photoPath: photoPath ?? this.photoPath,
      creeLe: creeLe ?? this.creeLe,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (montantCentimes.present) {
      map['montant_centimes'] = Variable<int>(montantCentimes.value);
    }
    if (libelle.present) {
      map['libelle'] = Variable<String>(libelle.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (tourneeId.present) {
      map['tournee_id'] = Variable<int>(tourneeId.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (creeLe.present) {
      map['cree_le'] = Variable<DateTime>(creeLe.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FraisCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('type: $type, ')
          ..write('montantCentimes: $montantCentimes, ')
          ..write('libelle: $libelle, ')
          ..write('notes: $notes, ')
          ..write('tourneeId: $tourneeId, ')
          ..write('photoPath: $photoPath, ')
          ..write('creeLe: $creeLe, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $TrackingCodesTable extends TrackingCodes
    with TableInfo<$TrackingCodesTable, TrackingCode> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrackingCodesTable(this.attachedDatabase, [this._alias]);
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
    $customConstraints: 'NOT NULL REFERENCES stops(id) ON DELETE CASCADE',
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 3,
      maxTextLength: 5,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _cloudPushedMeta = const VerificationMeta(
    'cloudPushed',
  );
  @override
  late final GeneratedColumn<bool> cloudPushed = GeneratedColumn<bool>(
    'cloud_pushed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("cloud_pushed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    stopId,
    code,
    createdAt,
    cloudPushed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tracking_codes';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrackingCode> instance, {
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
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('cloud_pushed')) {
      context.handle(
        _cloudPushedMeta,
        cloudPushed.isAcceptableOrUnknown(
          data['cloud_pushed']!,
          _cloudPushedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {stopId},
  ];
  @override
  TrackingCode map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrackingCode(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      stopId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stop_id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      cloudPushed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}cloud_pushed'],
      )!,
    );
  }

  @override
  $TrackingCodesTable createAlias(String alias) {
    return $TrackingCodesTable(attachedDatabase, alias);
  }
}

class TrackingCode extends DataClass implements Insertable<TrackingCode> {
  final int id;

  /// FK vers le stop concerne. Un stop = max 1 code (unique index).
  final int stopId;

  /// Code court 4 caracteres [a-z0-9] (1.6M combinations). Unique
  /// au niveau de la base : pas 2 stops avec le meme code.
  final String code;
  final DateTime createdAt;

  /// True une fois que la row a ete push au cloud Supabase (table
  /// `tracking_links`). Null/false en attendant le deploiement de
  /// l'Edge Function backend (MVP scaffold pour l'instant).
  final bool cloudPushed;
  const TrackingCode({
    required this.id,
    required this.stopId,
    required this.code,
    required this.createdAt,
    required this.cloudPushed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['stop_id'] = Variable<int>(stopId);
    map['code'] = Variable<String>(code);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['cloud_pushed'] = Variable<bool>(cloudPushed);
    return map;
  }

  TrackingCodesCompanion toCompanion(bool nullToAbsent) {
    return TrackingCodesCompanion(
      id: Value(id),
      stopId: Value(stopId),
      code: Value(code),
      createdAt: Value(createdAt),
      cloudPushed: Value(cloudPushed),
    );
  }

  factory TrackingCode.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrackingCode(
      id: serializer.fromJson<int>(json['id']),
      stopId: serializer.fromJson<int>(json['stopId']),
      code: serializer.fromJson<String>(json['code']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      cloudPushed: serializer.fromJson<bool>(json['cloudPushed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'stopId': serializer.toJson<int>(stopId),
      'code': serializer.toJson<String>(code),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'cloudPushed': serializer.toJson<bool>(cloudPushed),
    };
  }

  TrackingCode copyWith({
    int? id,
    int? stopId,
    String? code,
    DateTime? createdAt,
    bool? cloudPushed,
  }) => TrackingCode(
    id: id ?? this.id,
    stopId: stopId ?? this.stopId,
    code: code ?? this.code,
    createdAt: createdAt ?? this.createdAt,
    cloudPushed: cloudPushed ?? this.cloudPushed,
  );
  TrackingCode copyWithCompanion(TrackingCodesCompanion data) {
    return TrackingCode(
      id: data.id.present ? data.id.value : this.id,
      stopId: data.stopId.present ? data.stopId.value : this.stopId,
      code: data.code.present ? data.code.value : this.code,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      cloudPushed: data.cloudPushed.present
          ? data.cloudPushed.value
          : this.cloudPushed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrackingCode(')
          ..write('id: $id, ')
          ..write('stopId: $stopId, ')
          ..write('code: $code, ')
          ..write('createdAt: $createdAt, ')
          ..write('cloudPushed: $cloudPushed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, stopId, code, createdAt, cloudPushed);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrackingCode &&
          other.id == this.id &&
          other.stopId == this.stopId &&
          other.code == this.code &&
          other.createdAt == this.createdAt &&
          other.cloudPushed == this.cloudPushed);
}

class TrackingCodesCompanion extends UpdateCompanion<TrackingCode> {
  final Value<int> id;
  final Value<int> stopId;
  final Value<String> code;
  final Value<DateTime> createdAt;
  final Value<bool> cloudPushed;
  const TrackingCodesCompanion({
    this.id = const Value.absent(),
    this.stopId = const Value.absent(),
    this.code = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.cloudPushed = const Value.absent(),
  });
  TrackingCodesCompanion.insert({
    this.id = const Value.absent(),
    required int stopId,
    required String code,
    this.createdAt = const Value.absent(),
    this.cloudPushed = const Value.absent(),
  }) : stopId = Value(stopId),
       code = Value(code);
  static Insertable<TrackingCode> custom({
    Expression<int>? id,
    Expression<int>? stopId,
    Expression<String>? code,
    Expression<DateTime>? createdAt,
    Expression<bool>? cloudPushed,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (stopId != null) 'stop_id': stopId,
      if (code != null) 'code': code,
      if (createdAt != null) 'created_at': createdAt,
      if (cloudPushed != null) 'cloud_pushed': cloudPushed,
    });
  }

  TrackingCodesCompanion copyWith({
    Value<int>? id,
    Value<int>? stopId,
    Value<String>? code,
    Value<DateTime>? createdAt,
    Value<bool>? cloudPushed,
  }) {
    return TrackingCodesCompanion(
      id: id ?? this.id,
      stopId: stopId ?? this.stopId,
      code: code ?? this.code,
      createdAt: createdAt ?? this.createdAt,
      cloudPushed: cloudPushed ?? this.cloudPushed,
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
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (cloudPushed.present) {
      map['cloud_pushed'] = Variable<bool>(cloudPushed.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrackingCodesCompanion(')
          ..write('id: $id, ')
          ..write('stopId: $stopId, ')
          ..write('code: $code, ')
          ..write('createdAt: $createdAt, ')
          ..write('cloudPushed: $cloudPushed')
          ..write(')'))
        .toString();
  }
}

class $TourneeRecurrencesTable extends TourneeRecurrences
    with TableInfo<$TourneeRecurrencesTable, TourneeRecurrence> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TourneeRecurrencesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<int> templateId = GeneratedColumn<int>(
    'template_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tournees (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _frequenceMeta = const VerificationMeta(
    'frequence',
  );
  @override
  late final GeneratedColumn<String> frequence = GeneratedColumn<String>(
    'frequence',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jourSemaineMeta = const VerificationMeta(
    'jourSemaine',
  );
  @override
  late final GeneratedColumn<int> jourSemaine = GeneratedColumn<int>(
    'jour_semaine',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _jourMoisMeta = const VerificationMeta(
    'jourMois',
  );
  @override
  late final GeneratedColumn<int> jourMois = GeneratedColumn<int>(
    'jour_mois',
    aliasedName,
    true,
    type: DriftSqlType.int,
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
  static const VerificationMeta _derniereGenerationLeMeta =
      const VerificationMeta('derniereGenerationLe');
  @override
  late final GeneratedColumn<DateTime> derniereGenerationLe =
      GeneratedColumn<DateTime>(
        'derniere_generation_le',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
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
    templateId,
    frequence,
    jourSemaine,
    jourMois,
    actif,
    derniereGenerationLe,
    creeLe,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tournee_recurrences';
  @override
  VerificationContext validateIntegrity(
    Insertable<TourneeRecurrence> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    } else if (isInserting) {
      context.missing(_templateIdMeta);
    }
    if (data.containsKey('frequence')) {
      context.handle(
        _frequenceMeta,
        frequence.isAcceptableOrUnknown(data['frequence']!, _frequenceMeta),
      );
    } else if (isInserting) {
      context.missing(_frequenceMeta);
    }
    if (data.containsKey('jour_semaine')) {
      context.handle(
        _jourSemaineMeta,
        jourSemaine.isAcceptableOrUnknown(
          data['jour_semaine']!,
          _jourSemaineMeta,
        ),
      );
    }
    if (data.containsKey('jour_mois')) {
      context.handle(
        _jourMoisMeta,
        jourMois.isAcceptableOrUnknown(data['jour_mois']!, _jourMoisMeta),
      );
    }
    if (data.containsKey('actif')) {
      context.handle(
        _actifMeta,
        actif.isAcceptableOrUnknown(data['actif']!, _actifMeta),
      );
    }
    if (data.containsKey('derniere_generation_le')) {
      context.handle(
        _derniereGenerationLeMeta,
        derniereGenerationLe.isAcceptableOrUnknown(
          data['derniere_generation_le']!,
          _derniereGenerationLeMeta,
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
  TourneeRecurrence map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TourneeRecurrence(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}template_id'],
      )!,
      frequence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}frequence'],
      )!,
      jourSemaine: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}jour_semaine'],
      ),
      jourMois: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}jour_mois'],
      ),
      actif: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}actif'],
      )!,
      derniereGenerationLe: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}derniere_generation_le'],
      ),
      creeLe: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cree_le'],
      )!,
    );
  }

  @override
  $TourneeRecurrencesTable createAlias(String alias) {
    return $TourneeRecurrencesTable(attachedDatabase, alias);
  }
}

class TourneeRecurrence extends DataClass
    implements Insertable<TourneeRecurrence> {
  final int id;

  /// Le template source a cloner (FK Tournees.id, normalement isTemplate).
  final int templateId;
  final String frequence;

  /// 1=lundi .. 7=dimanche. Requis si frequence == 'hebdo'.
  final int? jourSemaine;

  /// 1..31. Requis si frequence == 'mensuel'. Si > nb de jours du mois,
  /// la recurrence ne se declenche pas ce mois-la (cas rare, ex 31 fev).
  final int? jourMois;
  final bool actif;

  /// Jour de la derniere generation reussie. Sert au dedup intra-jour :
  /// on ne genere pas deux fois la meme tournee le meme jour (si l'app
  /// est rouverte plusieurs fois). Null = jamais genere.
  final DateTime? derniereGenerationLe;
  final DateTime creeLe;
  const TourneeRecurrence({
    required this.id,
    required this.templateId,
    required this.frequence,
    this.jourSemaine,
    this.jourMois,
    required this.actif,
    this.derniereGenerationLe,
    required this.creeLe,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['template_id'] = Variable<int>(templateId);
    map['frequence'] = Variable<String>(frequence);
    if (!nullToAbsent || jourSemaine != null) {
      map['jour_semaine'] = Variable<int>(jourSemaine);
    }
    if (!nullToAbsent || jourMois != null) {
      map['jour_mois'] = Variable<int>(jourMois);
    }
    map['actif'] = Variable<bool>(actif);
    if (!nullToAbsent || derniereGenerationLe != null) {
      map['derniere_generation_le'] = Variable<DateTime>(derniereGenerationLe);
    }
    map['cree_le'] = Variable<DateTime>(creeLe);
    return map;
  }

  TourneeRecurrencesCompanion toCompanion(bool nullToAbsent) {
    return TourneeRecurrencesCompanion(
      id: Value(id),
      templateId: Value(templateId),
      frequence: Value(frequence),
      jourSemaine: jourSemaine == null && nullToAbsent
          ? const Value.absent()
          : Value(jourSemaine),
      jourMois: jourMois == null && nullToAbsent
          ? const Value.absent()
          : Value(jourMois),
      actif: Value(actif),
      derniereGenerationLe: derniereGenerationLe == null && nullToAbsent
          ? const Value.absent()
          : Value(derniereGenerationLe),
      creeLe: Value(creeLe),
    );
  }

  factory TourneeRecurrence.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TourneeRecurrence(
      id: serializer.fromJson<int>(json['id']),
      templateId: serializer.fromJson<int>(json['templateId']),
      frequence: serializer.fromJson<String>(json['frequence']),
      jourSemaine: serializer.fromJson<int?>(json['jourSemaine']),
      jourMois: serializer.fromJson<int?>(json['jourMois']),
      actif: serializer.fromJson<bool>(json['actif']),
      derniereGenerationLe: serializer.fromJson<DateTime?>(
        json['derniereGenerationLe'],
      ),
      creeLe: serializer.fromJson<DateTime>(json['creeLe']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'templateId': serializer.toJson<int>(templateId),
      'frequence': serializer.toJson<String>(frequence),
      'jourSemaine': serializer.toJson<int?>(jourSemaine),
      'jourMois': serializer.toJson<int?>(jourMois),
      'actif': serializer.toJson<bool>(actif),
      'derniereGenerationLe': serializer.toJson<DateTime?>(
        derniereGenerationLe,
      ),
      'creeLe': serializer.toJson<DateTime>(creeLe),
    };
  }

  TourneeRecurrence copyWith({
    int? id,
    int? templateId,
    String? frequence,
    Value<int?> jourSemaine = const Value.absent(),
    Value<int?> jourMois = const Value.absent(),
    bool? actif,
    Value<DateTime?> derniereGenerationLe = const Value.absent(),
    DateTime? creeLe,
  }) => TourneeRecurrence(
    id: id ?? this.id,
    templateId: templateId ?? this.templateId,
    frequence: frequence ?? this.frequence,
    jourSemaine: jourSemaine.present ? jourSemaine.value : this.jourSemaine,
    jourMois: jourMois.present ? jourMois.value : this.jourMois,
    actif: actif ?? this.actif,
    derniereGenerationLe: derniereGenerationLe.present
        ? derniereGenerationLe.value
        : this.derniereGenerationLe,
    creeLe: creeLe ?? this.creeLe,
  );
  TourneeRecurrence copyWithCompanion(TourneeRecurrencesCompanion data) {
    return TourneeRecurrence(
      id: data.id.present ? data.id.value : this.id,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      frequence: data.frequence.present ? data.frequence.value : this.frequence,
      jourSemaine: data.jourSemaine.present
          ? data.jourSemaine.value
          : this.jourSemaine,
      jourMois: data.jourMois.present ? data.jourMois.value : this.jourMois,
      actif: data.actif.present ? data.actif.value : this.actif,
      derniereGenerationLe: data.derniereGenerationLe.present
          ? data.derniereGenerationLe.value
          : this.derniereGenerationLe,
      creeLe: data.creeLe.present ? data.creeLe.value : this.creeLe,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TourneeRecurrence(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('frequence: $frequence, ')
          ..write('jourSemaine: $jourSemaine, ')
          ..write('jourMois: $jourMois, ')
          ..write('actif: $actif, ')
          ..write('derniereGenerationLe: $derniereGenerationLe, ')
          ..write('creeLe: $creeLe')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    templateId,
    frequence,
    jourSemaine,
    jourMois,
    actif,
    derniereGenerationLe,
    creeLe,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TourneeRecurrence &&
          other.id == this.id &&
          other.templateId == this.templateId &&
          other.frequence == this.frequence &&
          other.jourSemaine == this.jourSemaine &&
          other.jourMois == this.jourMois &&
          other.actif == this.actif &&
          other.derniereGenerationLe == this.derniereGenerationLe &&
          other.creeLe == this.creeLe);
}

class TourneeRecurrencesCompanion extends UpdateCompanion<TourneeRecurrence> {
  final Value<int> id;
  final Value<int> templateId;
  final Value<String> frequence;
  final Value<int?> jourSemaine;
  final Value<int?> jourMois;
  final Value<bool> actif;
  final Value<DateTime?> derniereGenerationLe;
  final Value<DateTime> creeLe;
  const TourneeRecurrencesCompanion({
    this.id = const Value.absent(),
    this.templateId = const Value.absent(),
    this.frequence = const Value.absent(),
    this.jourSemaine = const Value.absent(),
    this.jourMois = const Value.absent(),
    this.actif = const Value.absent(),
    this.derniereGenerationLe = const Value.absent(),
    this.creeLe = const Value.absent(),
  });
  TourneeRecurrencesCompanion.insert({
    this.id = const Value.absent(),
    required int templateId,
    required String frequence,
    this.jourSemaine = const Value.absent(),
    this.jourMois = const Value.absent(),
    this.actif = const Value.absent(),
    this.derniereGenerationLe = const Value.absent(),
    this.creeLe = const Value.absent(),
  }) : templateId = Value(templateId),
       frequence = Value(frequence);
  static Insertable<TourneeRecurrence> custom({
    Expression<int>? id,
    Expression<int>? templateId,
    Expression<String>? frequence,
    Expression<int>? jourSemaine,
    Expression<int>? jourMois,
    Expression<bool>? actif,
    Expression<DateTime>? derniereGenerationLe,
    Expression<DateTime>? creeLe,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (templateId != null) 'template_id': templateId,
      if (frequence != null) 'frequence': frequence,
      if (jourSemaine != null) 'jour_semaine': jourSemaine,
      if (jourMois != null) 'jour_mois': jourMois,
      if (actif != null) 'actif': actif,
      if (derniereGenerationLe != null)
        'derniere_generation_le': derniereGenerationLe,
      if (creeLe != null) 'cree_le': creeLe,
    });
  }

  TourneeRecurrencesCompanion copyWith({
    Value<int>? id,
    Value<int>? templateId,
    Value<String>? frequence,
    Value<int?>? jourSemaine,
    Value<int?>? jourMois,
    Value<bool>? actif,
    Value<DateTime?>? derniereGenerationLe,
    Value<DateTime>? creeLe,
  }) {
    return TourneeRecurrencesCompanion(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      frequence: frequence ?? this.frequence,
      jourSemaine: jourSemaine ?? this.jourSemaine,
      jourMois: jourMois ?? this.jourMois,
      actif: actif ?? this.actif,
      derniereGenerationLe: derniereGenerationLe ?? this.derniereGenerationLe,
      creeLe: creeLe ?? this.creeLe,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<int>(templateId.value);
    }
    if (frequence.present) {
      map['frequence'] = Variable<String>(frequence.value);
    }
    if (jourSemaine.present) {
      map['jour_semaine'] = Variable<int>(jourSemaine.value);
    }
    if (jourMois.present) {
      map['jour_mois'] = Variable<int>(jourMois.value);
    }
    if (actif.present) {
      map['actif'] = Variable<bool>(actif.value);
    }
    if (derniereGenerationLe.present) {
      map['derniere_generation_le'] = Variable<DateTime>(
        derniereGenerationLe.value,
      );
    }
    if (creeLe.present) {
      map['cree_le'] = Variable<DateTime>(creeLe.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TourneeRecurrencesCompanion(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('frequence: $frequence, ')
          ..write('jourSemaine: $jourSemaine, ')
          ..write('jourMois: $jourMois, ')
          ..write('actif: $actif, ')
          ..write('derniereGenerationLe: $derniereGenerationLe, ')
          ..write('creeLe: $creeLe')
          ..write(')'))
        .toString();
  }
}

class $WorkSessionsTable extends WorkSessions
    with TableInfo<$WorkSessionsTable, WorkSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkSessionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
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
  List<GeneratedColumn> get $columns => [id, startedAt, endedAt, notes, creeLe];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'work_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
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
  WorkSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      creeLe: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cree_le'],
      )!,
    );
  }

  @override
  $WorkSessionsTable createAlias(String alias) {
    return $WorkSessionsTable(attachedDatabase, alias);
  }
}

class WorkSession extends DataClass implements Insertable<WorkSession> {
  final int id;

  /// Timestamp de debut de service (tap "Commencer le service").
  final DateTime startedAt;

  /// Timestamp de fin de service (tap "Terminer le service"). Null
  /// si la session est encore en cours.
  final DateTime? endedAt;

  /// Notes libres optionnelles (ex: "tournee Chartres + retour 18h").
  /// Pas utilisees aujourd'hui mais reservees pour une future UI.
  final String? notes;
  final DateTime creeLe;
  const WorkSession({
    required this.id,
    required this.startedAt,
    this.endedAt,
    this.notes,
    required this.creeLe,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['cree_le'] = Variable<DateTime>(creeLe);
    return map;
  }

  WorkSessionsCompanion toCompanion(bool nullToAbsent) {
    return WorkSessionsCompanion(
      id: Value(id),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      creeLe: Value(creeLe),
    );
  }

  factory WorkSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkSession(
      id: serializer.fromJson<int>(json['id']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      notes: serializer.fromJson<String?>(json['notes']),
      creeLe: serializer.fromJson<DateTime>(json['creeLe']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'notes': serializer.toJson<String?>(notes),
      'creeLe': serializer.toJson<DateTime>(creeLe),
    };
  }

  WorkSession copyWith({
    int? id,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    DateTime? creeLe,
  }) => WorkSession(
    id: id ?? this.id,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    notes: notes.present ? notes.value : this.notes,
    creeLe: creeLe ?? this.creeLe,
  );
  WorkSession copyWithCompanion(WorkSessionsCompanion data) {
    return WorkSession(
      id: data.id.present ? data.id.value : this.id,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      notes: data.notes.present ? data.notes.value : this.notes,
      creeLe: data.creeLe.present ? data.creeLe.value : this.creeLe,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkSession(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('notes: $notes, ')
          ..write('creeLe: $creeLe')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, startedAt, endedAt, notes, creeLe);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkSession &&
          other.id == this.id &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.notes == this.notes &&
          other.creeLe == this.creeLe);
}

class WorkSessionsCompanion extends UpdateCompanion<WorkSession> {
  final Value<int> id;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<String?> notes;
  final Value<DateTime> creeLe;
  const WorkSessionsCompanion({
    this.id = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.creeLe = const Value.absent(),
  });
  WorkSessionsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.creeLe = const Value.absent(),
  }) : startedAt = Value(startedAt);
  static Insertable<WorkSession> custom({
    Expression<int>? id,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<String>? notes,
    Expression<DateTime>? creeLe,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (notes != null) 'notes': notes,
      if (creeLe != null) 'cree_le': creeLe,
    });
  }

  WorkSessionsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<String?>? notes,
    Value<DateTime>? creeLe,
  }) {
    return WorkSessionsCompanion(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      notes: notes ?? this.notes,
      creeLe: creeLe ?? this.creeLe,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (creeLe.present) {
      map['cree_le'] = Variable<DateTime>(creeLe.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkSessionsCompanion(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('notes: $notes, ')
          ..write('creeLe: $creeLe')
          ..write(')'))
        .toString();
  }
}

class $EntreprisesTable extends Entreprises
    with TableInfo<$EntreprisesTable, Entreprise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntreprisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cloudIdMeta = const VerificationMeta(
    'cloudId',
  );
  @override
  late final GeneratedColumn<String> cloudId = GeneratedColumn<String>(
    'cloud_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nomMeta = const VerificationMeta('nom');
  @override
  late final GeneratedColumn<String> nom = GeneratedColumn<String>(
    'nom',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _siretMeta = const VerificationMeta('siret');
  @override
  late final GeneratedColumn<String> siret = GeneratedColumn<String>(
    'siret',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    cloudId,
    nom,
    siret,
    createdBy,
    creeLe,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entreprises';
  @override
  VerificationContext validateIntegrity(
    Insertable<Entreprise> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cloud_id')) {
      context.handle(
        _cloudIdMeta,
        cloudId.isAcceptableOrUnknown(data['cloud_id']!, _cloudIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cloudIdMeta);
    }
    if (data.containsKey('nom')) {
      context.handle(
        _nomMeta,
        nom.isAcceptableOrUnknown(data['nom']!, _nomMeta),
      );
    } else if (isInserting) {
      context.missing(_nomMeta);
    }
    if (data.containsKey('siret')) {
      context.handle(
        _siretMeta,
        siret.isAcceptableOrUnknown(data['siret']!, _siretMeta),
      );
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    } else if (isInserting) {
      context.missing(_createdByMeta);
    }
    if (data.containsKey('cree_le')) {
      context.handle(
        _creeLeMeta,
        creeLe.isAcceptableOrUnknown(data['cree_le']!, _creeLeMeta),
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
  Set<GeneratedColumn> get $primaryKey => {cloudId};
  @override
  Entreprise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Entreprise(
      cloudId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cloud_id'],
      )!,
      nom: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nom'],
      )!,
      siret: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}siret'],
      ),
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      )!,
      creeLe: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cree_le'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $EntreprisesTable createAlias(String alias) {
    return $EntreprisesTable(attachedDatabase, alias);
  }
}

class Entreprise extends DataClass implements Insertable<Entreprise> {
  /// `cloud_id` UUID v4 (TEXT) = clé primaire locale ET cloud.
  /// Pas d'auto-increment : l'ID est généré côté Supabase puis miroir
  /// local. Simplifie la sync (1 ID partout, pas de mapping).
  final String cloudId;
  final String nom;

  /// SIRET (14 chiffres) optionnel. Stocké en TEXT pour préserver
  /// les zéros de tête (ex: "01234567890123").
  final String? siret;

  /// User qui a créé l'entreprise (= admin_entreprise initial).
  /// Stocke l'UUID Supabase de auth.users.
  final String createdBy;
  final DateTime creeLe;
  final DateTime updatedAt;
  const Entreprise({
    required this.cloudId,
    required this.nom,
    this.siret,
    required this.createdBy,
    required this.creeLe,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cloud_id'] = Variable<String>(cloudId);
    map['nom'] = Variable<String>(nom);
    if (!nullToAbsent || siret != null) {
      map['siret'] = Variable<String>(siret);
    }
    map['created_by'] = Variable<String>(createdBy);
    map['cree_le'] = Variable<DateTime>(creeLe);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  EntreprisesCompanion toCompanion(bool nullToAbsent) {
    return EntreprisesCompanion(
      cloudId: Value(cloudId),
      nom: Value(nom),
      siret: siret == null && nullToAbsent
          ? const Value.absent()
          : Value(siret),
      createdBy: Value(createdBy),
      creeLe: Value(creeLe),
      updatedAt: Value(updatedAt),
    );
  }

  factory Entreprise.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Entreprise(
      cloudId: serializer.fromJson<String>(json['cloudId']),
      nom: serializer.fromJson<String>(json['nom']),
      siret: serializer.fromJson<String?>(json['siret']),
      createdBy: serializer.fromJson<String>(json['createdBy']),
      creeLe: serializer.fromJson<DateTime>(json['creeLe']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cloudId': serializer.toJson<String>(cloudId),
      'nom': serializer.toJson<String>(nom),
      'siret': serializer.toJson<String?>(siret),
      'createdBy': serializer.toJson<String>(createdBy),
      'creeLe': serializer.toJson<DateTime>(creeLe),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Entreprise copyWith({
    String? cloudId,
    String? nom,
    Value<String?> siret = const Value.absent(),
    String? createdBy,
    DateTime? creeLe,
    DateTime? updatedAt,
  }) => Entreprise(
    cloudId: cloudId ?? this.cloudId,
    nom: nom ?? this.nom,
    siret: siret.present ? siret.value : this.siret,
    createdBy: createdBy ?? this.createdBy,
    creeLe: creeLe ?? this.creeLe,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Entreprise copyWithCompanion(EntreprisesCompanion data) {
    return Entreprise(
      cloudId: data.cloudId.present ? data.cloudId.value : this.cloudId,
      nom: data.nom.present ? data.nom.value : this.nom,
      siret: data.siret.present ? data.siret.value : this.siret,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      creeLe: data.creeLe.present ? data.creeLe.value : this.creeLe,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Entreprise(')
          ..write('cloudId: $cloudId, ')
          ..write('nom: $nom, ')
          ..write('siret: $siret, ')
          ..write('createdBy: $createdBy, ')
          ..write('creeLe: $creeLe, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(cloudId, nom, siret, createdBy, creeLe, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Entreprise &&
          other.cloudId == this.cloudId &&
          other.nom == this.nom &&
          other.siret == this.siret &&
          other.createdBy == this.createdBy &&
          other.creeLe == this.creeLe &&
          other.updatedAt == this.updatedAt);
}

class EntreprisesCompanion extends UpdateCompanion<Entreprise> {
  final Value<String> cloudId;
  final Value<String> nom;
  final Value<String?> siret;
  final Value<String> createdBy;
  final Value<DateTime> creeLe;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const EntreprisesCompanion({
    this.cloudId = const Value.absent(),
    this.nom = const Value.absent(),
    this.siret = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.creeLe = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EntreprisesCompanion.insert({
    required String cloudId,
    required String nom,
    this.siret = const Value.absent(),
    required String createdBy,
    this.creeLe = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : cloudId = Value(cloudId),
       nom = Value(nom),
       createdBy = Value(createdBy);
  static Insertable<Entreprise> custom({
    Expression<String>? cloudId,
    Expression<String>? nom,
    Expression<String>? siret,
    Expression<String>? createdBy,
    Expression<DateTime>? creeLe,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cloudId != null) 'cloud_id': cloudId,
      if (nom != null) 'nom': nom,
      if (siret != null) 'siret': siret,
      if (createdBy != null) 'created_by': createdBy,
      if (creeLe != null) 'cree_le': creeLe,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EntreprisesCompanion copyWith({
    Value<String>? cloudId,
    Value<String>? nom,
    Value<String?>? siret,
    Value<String>? createdBy,
    Value<DateTime>? creeLe,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return EntreprisesCompanion(
      cloudId: cloudId ?? this.cloudId,
      nom: nom ?? this.nom,
      siret: siret ?? this.siret,
      createdBy: createdBy ?? this.createdBy,
      creeLe: creeLe ?? this.creeLe,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cloudId.present) {
      map['cloud_id'] = Variable<String>(cloudId.value);
    }
    if (nom.present) {
      map['nom'] = Variable<String>(nom.value);
    }
    if (siret.present) {
      map['siret'] = Variable<String>(siret.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (creeLe.present) {
      map['cree_le'] = Variable<DateTime>(creeLe.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntreprisesCompanion(')
          ..write('cloudId: $cloudId, ')
          ..write('nom: $nom, ')
          ..write('siret: $siret, ')
          ..write('createdBy: $createdBy, ')
          ..write('creeLe: $creeLe, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EntrepotsTable extends Entrepots
    with TableInfo<$EntrepotsTable, Entrepot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntrepotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cloudIdMeta = const VerificationMeta(
    'cloudId',
  );
  @override
  late final GeneratedColumn<String> cloudId = GeneratedColumn<String>(
    'cloud_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entrepriseIdMeta = const VerificationMeta(
    'entrepriseId',
  );
  @override
  late final GeneratedColumn<String> entrepriseId = GeneratedColumn<String>(
    'entreprise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES entreprises (cloud_id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nomMeta = const VerificationMeta('nom');
  @override
  late final GeneratedColumn<String> nom = GeneratedColumn<String>(
    'nom',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _adresseMeta = const VerificationMeta(
    'adresse',
  );
  @override
  late final GeneratedColumn<String> adresse = GeneratedColumn<String>(
    'adresse',
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
    cloudId,
    entrepriseId,
    nom,
    adresse,
    lat,
    lng,
    creeLe,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entrepots';
  @override
  VerificationContext validateIntegrity(
    Insertable<Entrepot> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cloud_id')) {
      context.handle(
        _cloudIdMeta,
        cloudId.isAcceptableOrUnknown(data['cloud_id']!, _cloudIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cloudIdMeta);
    }
    if (data.containsKey('entreprise_id')) {
      context.handle(
        _entrepriseIdMeta,
        entrepriseId.isAcceptableOrUnknown(
          data['entreprise_id']!,
          _entrepriseIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_entrepriseIdMeta);
    }
    if (data.containsKey('nom')) {
      context.handle(
        _nomMeta,
        nom.isAcceptableOrUnknown(data['nom']!, _nomMeta),
      );
    } else if (isInserting) {
      context.missing(_nomMeta);
    }
    if (data.containsKey('adresse')) {
      context.handle(
        _adresseMeta,
        adresse.isAcceptableOrUnknown(data['adresse']!, _adresseMeta),
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
    if (data.containsKey('cree_le')) {
      context.handle(
        _creeLeMeta,
        creeLe.isAcceptableOrUnknown(data['cree_le']!, _creeLeMeta),
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
  Set<GeneratedColumn> get $primaryKey => {cloudId};
  @override
  Entrepot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Entrepot(
      cloudId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cloud_id'],
      )!,
      entrepriseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entreprise_id'],
      )!,
      nom: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nom'],
      )!,
      adresse: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}adresse'],
      ),
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      ),
      lng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lng'],
      ),
      creeLe: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cree_le'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $EntrepotsTable createAlias(String alias) {
    return $EntrepotsTable(attachedDatabase, alias);
  }
}

class Entrepot extends DataClass implements Insertable<Entrepot> {
  final String cloudId;

  /// FK vers `entreprises.cloudId`.
  final String entrepriseId;
  final String nom;

  /// Adresse postale du site (texte libre, géocodée optionnellement).
  final String? adresse;
  final double? lat;
  final double? lng;
  final DateTime creeLe;
  final DateTime updatedAt;
  const Entrepot({
    required this.cloudId,
    required this.entrepriseId,
    required this.nom,
    this.adresse,
    this.lat,
    this.lng,
    required this.creeLe,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cloud_id'] = Variable<String>(cloudId);
    map['entreprise_id'] = Variable<String>(entrepriseId);
    map['nom'] = Variable<String>(nom);
    if (!nullToAbsent || adresse != null) {
      map['adresse'] = Variable<String>(adresse);
    }
    if (!nullToAbsent || lat != null) {
      map['lat'] = Variable<double>(lat);
    }
    if (!nullToAbsent || lng != null) {
      map['lng'] = Variable<double>(lng);
    }
    map['cree_le'] = Variable<DateTime>(creeLe);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  EntrepotsCompanion toCompanion(bool nullToAbsent) {
    return EntrepotsCompanion(
      cloudId: Value(cloudId),
      entrepriseId: Value(entrepriseId),
      nom: Value(nom),
      adresse: adresse == null && nullToAbsent
          ? const Value.absent()
          : Value(adresse),
      lat: lat == null && nullToAbsent ? const Value.absent() : Value(lat),
      lng: lng == null && nullToAbsent ? const Value.absent() : Value(lng),
      creeLe: Value(creeLe),
      updatedAt: Value(updatedAt),
    );
  }

  factory Entrepot.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Entrepot(
      cloudId: serializer.fromJson<String>(json['cloudId']),
      entrepriseId: serializer.fromJson<String>(json['entrepriseId']),
      nom: serializer.fromJson<String>(json['nom']),
      adresse: serializer.fromJson<String?>(json['adresse']),
      lat: serializer.fromJson<double?>(json['lat']),
      lng: serializer.fromJson<double?>(json['lng']),
      creeLe: serializer.fromJson<DateTime>(json['creeLe']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cloudId': serializer.toJson<String>(cloudId),
      'entrepriseId': serializer.toJson<String>(entrepriseId),
      'nom': serializer.toJson<String>(nom),
      'adresse': serializer.toJson<String?>(adresse),
      'lat': serializer.toJson<double?>(lat),
      'lng': serializer.toJson<double?>(lng),
      'creeLe': serializer.toJson<DateTime>(creeLe),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Entrepot copyWith({
    String? cloudId,
    String? entrepriseId,
    String? nom,
    Value<String?> adresse = const Value.absent(),
    Value<double?> lat = const Value.absent(),
    Value<double?> lng = const Value.absent(),
    DateTime? creeLe,
    DateTime? updatedAt,
  }) => Entrepot(
    cloudId: cloudId ?? this.cloudId,
    entrepriseId: entrepriseId ?? this.entrepriseId,
    nom: nom ?? this.nom,
    adresse: adresse.present ? adresse.value : this.adresse,
    lat: lat.present ? lat.value : this.lat,
    lng: lng.present ? lng.value : this.lng,
    creeLe: creeLe ?? this.creeLe,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Entrepot copyWithCompanion(EntrepotsCompanion data) {
    return Entrepot(
      cloudId: data.cloudId.present ? data.cloudId.value : this.cloudId,
      entrepriseId: data.entrepriseId.present
          ? data.entrepriseId.value
          : this.entrepriseId,
      nom: data.nom.present ? data.nom.value : this.nom,
      adresse: data.adresse.present ? data.adresse.value : this.adresse,
      lat: data.lat.present ? data.lat.value : this.lat,
      lng: data.lng.present ? data.lng.value : this.lng,
      creeLe: data.creeLe.present ? data.creeLe.value : this.creeLe,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Entrepot(')
          ..write('cloudId: $cloudId, ')
          ..write('entrepriseId: $entrepriseId, ')
          ..write('nom: $nom, ')
          ..write('adresse: $adresse, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('creeLe: $creeLe, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    cloudId,
    entrepriseId,
    nom,
    adresse,
    lat,
    lng,
    creeLe,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Entrepot &&
          other.cloudId == this.cloudId &&
          other.entrepriseId == this.entrepriseId &&
          other.nom == this.nom &&
          other.adresse == this.adresse &&
          other.lat == this.lat &&
          other.lng == this.lng &&
          other.creeLe == this.creeLe &&
          other.updatedAt == this.updatedAt);
}

class EntrepotsCompanion extends UpdateCompanion<Entrepot> {
  final Value<String> cloudId;
  final Value<String> entrepriseId;
  final Value<String> nom;
  final Value<String?> adresse;
  final Value<double?> lat;
  final Value<double?> lng;
  final Value<DateTime> creeLe;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const EntrepotsCompanion({
    this.cloudId = const Value.absent(),
    this.entrepriseId = const Value.absent(),
    this.nom = const Value.absent(),
    this.adresse = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.creeLe = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EntrepotsCompanion.insert({
    required String cloudId,
    required String entrepriseId,
    required String nom,
    this.adresse = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.creeLe = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : cloudId = Value(cloudId),
       entrepriseId = Value(entrepriseId),
       nom = Value(nom);
  static Insertable<Entrepot> custom({
    Expression<String>? cloudId,
    Expression<String>? entrepriseId,
    Expression<String>? nom,
    Expression<String>? adresse,
    Expression<double>? lat,
    Expression<double>? lng,
    Expression<DateTime>? creeLe,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cloudId != null) 'cloud_id': cloudId,
      if (entrepriseId != null) 'entreprise_id': entrepriseId,
      if (nom != null) 'nom': nom,
      if (adresse != null) 'adresse': adresse,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (creeLe != null) 'cree_le': creeLe,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EntrepotsCompanion copyWith({
    Value<String>? cloudId,
    Value<String>? entrepriseId,
    Value<String>? nom,
    Value<String?>? adresse,
    Value<double?>? lat,
    Value<double?>? lng,
    Value<DateTime>? creeLe,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return EntrepotsCompanion(
      cloudId: cloudId ?? this.cloudId,
      entrepriseId: entrepriseId ?? this.entrepriseId,
      nom: nom ?? this.nom,
      adresse: adresse ?? this.adresse,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      creeLe: creeLe ?? this.creeLe,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cloudId.present) {
      map['cloud_id'] = Variable<String>(cloudId.value);
    }
    if (entrepriseId.present) {
      map['entreprise_id'] = Variable<String>(entrepriseId.value);
    }
    if (nom.present) {
      map['nom'] = Variable<String>(nom.value);
    }
    if (adresse.present) {
      map['adresse'] = Variable<String>(adresse.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lng.present) {
      map['lng'] = Variable<double>(lng.value);
    }
    if (creeLe.present) {
      map['cree_le'] = Variable<DateTime>(creeLe.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntrepotsCompanion(')
          ..write('cloudId: $cloudId, ')
          ..write('entrepriseId: $entrepriseId, ')
          ..write('nom: $nom, ')
          ..write('adresse: $adresse, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('creeLe: $creeLe, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EntrepriseUsersTable extends EntrepriseUsers
    with TableInfo<$EntrepriseUsersTable, EntrepriseUser> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntrepriseUsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cloudIdMeta = const VerificationMeta(
    'cloudId',
  );
  @override
  late final GeneratedColumn<String> cloudId = GeneratedColumn<String>(
    'cloud_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entrepriseIdMeta = const VerificationMeta(
    'entrepriseId',
  );
  @override
  late final GeneratedColumn<String> entrepriseId = GeneratedColumn<String>(
    'entreprise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES entreprises (cloud_id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
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
  static const VerificationMeta _statutMeta = const VerificationMeta('statut');
  @override
  late final GeneratedColumn<String> statut = GeneratedColumn<String>(
    'statut',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('actif'),
  );
  static const VerificationMeta _revokedAtMeta = const VerificationMeta(
    'revokedAt',
  );
  @override
  late final GeneratedColumn<DateTime> revokedAt = GeneratedColumn<DateTime>(
    'revoked_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
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
    cloudId,
    entrepriseId,
    userId,
    role,
    statut,
    revokedAt,
    creeLe,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entreprise_users';
  @override
  VerificationContext validateIntegrity(
    Insertable<EntrepriseUser> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cloud_id')) {
      context.handle(
        _cloudIdMeta,
        cloudId.isAcceptableOrUnknown(data['cloud_id']!, _cloudIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cloudIdMeta);
    }
    if (data.containsKey('entreprise_id')) {
      context.handle(
        _entrepriseIdMeta,
        entrepriseId.isAcceptableOrUnknown(
          data['entreprise_id']!,
          _entrepriseIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_entrepriseIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('statut')) {
      context.handle(
        _statutMeta,
        statut.isAcceptableOrUnknown(data['statut']!, _statutMeta),
      );
    }
    if (data.containsKey('revoked_at')) {
      context.handle(
        _revokedAtMeta,
        revokedAt.isAcceptableOrUnknown(data['revoked_at']!, _revokedAtMeta),
      );
    }
    if (data.containsKey('cree_le')) {
      context.handle(
        _creeLeMeta,
        creeLe.isAcceptableOrUnknown(data['cree_le']!, _creeLeMeta),
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
  Set<GeneratedColumn> get $primaryKey => {cloudId};
  @override
  EntrepriseUser map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EntrepriseUser(
      cloudId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cloud_id'],
      )!,
      entrepriseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entreprise_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      statut: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}statut'],
      )!,
      revokedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}revoked_at'],
      ),
      creeLe: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cree_le'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $EntrepriseUsersTable createAlias(String alias) {
    return $EntrepriseUsersTable(attachedDatabase, alias);
  }
}

class EntrepriseUser extends DataClass implements Insertable<EntrepriseUser> {
  final String cloudId;
  final String entrepriseId;

  /// UUID Supabase auth.users
  final String userId;

  /// 'admin_entreprise' | 'membre'
  final String role;

  /// 'actif' | 'revoque' | 'expire'
  final String statut;

  /// Quand revoked_at est set : compte à rebours J+30 avant `expire`.
  /// Null si statut='actif' ou 'expire'.
  final DateTime? revokedAt;
  final DateTime creeLe;
  final DateTime updatedAt;
  const EntrepriseUser({
    required this.cloudId,
    required this.entrepriseId,
    required this.userId,
    required this.role,
    required this.statut,
    this.revokedAt,
    required this.creeLe,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cloud_id'] = Variable<String>(cloudId);
    map['entreprise_id'] = Variable<String>(entrepriseId);
    map['user_id'] = Variable<String>(userId);
    map['role'] = Variable<String>(role);
    map['statut'] = Variable<String>(statut);
    if (!nullToAbsent || revokedAt != null) {
      map['revoked_at'] = Variable<DateTime>(revokedAt);
    }
    map['cree_le'] = Variable<DateTime>(creeLe);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  EntrepriseUsersCompanion toCompanion(bool nullToAbsent) {
    return EntrepriseUsersCompanion(
      cloudId: Value(cloudId),
      entrepriseId: Value(entrepriseId),
      userId: Value(userId),
      role: Value(role),
      statut: Value(statut),
      revokedAt: revokedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(revokedAt),
      creeLe: Value(creeLe),
      updatedAt: Value(updatedAt),
    );
  }

  factory EntrepriseUser.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EntrepriseUser(
      cloudId: serializer.fromJson<String>(json['cloudId']),
      entrepriseId: serializer.fromJson<String>(json['entrepriseId']),
      userId: serializer.fromJson<String>(json['userId']),
      role: serializer.fromJson<String>(json['role']),
      statut: serializer.fromJson<String>(json['statut']),
      revokedAt: serializer.fromJson<DateTime?>(json['revokedAt']),
      creeLe: serializer.fromJson<DateTime>(json['creeLe']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cloudId': serializer.toJson<String>(cloudId),
      'entrepriseId': serializer.toJson<String>(entrepriseId),
      'userId': serializer.toJson<String>(userId),
      'role': serializer.toJson<String>(role),
      'statut': serializer.toJson<String>(statut),
      'revokedAt': serializer.toJson<DateTime?>(revokedAt),
      'creeLe': serializer.toJson<DateTime>(creeLe),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  EntrepriseUser copyWith({
    String? cloudId,
    String? entrepriseId,
    String? userId,
    String? role,
    String? statut,
    Value<DateTime?> revokedAt = const Value.absent(),
    DateTime? creeLe,
    DateTime? updatedAt,
  }) => EntrepriseUser(
    cloudId: cloudId ?? this.cloudId,
    entrepriseId: entrepriseId ?? this.entrepriseId,
    userId: userId ?? this.userId,
    role: role ?? this.role,
    statut: statut ?? this.statut,
    revokedAt: revokedAt.present ? revokedAt.value : this.revokedAt,
    creeLe: creeLe ?? this.creeLe,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  EntrepriseUser copyWithCompanion(EntrepriseUsersCompanion data) {
    return EntrepriseUser(
      cloudId: data.cloudId.present ? data.cloudId.value : this.cloudId,
      entrepriseId: data.entrepriseId.present
          ? data.entrepriseId.value
          : this.entrepriseId,
      userId: data.userId.present ? data.userId.value : this.userId,
      role: data.role.present ? data.role.value : this.role,
      statut: data.statut.present ? data.statut.value : this.statut,
      revokedAt: data.revokedAt.present ? data.revokedAt.value : this.revokedAt,
      creeLe: data.creeLe.present ? data.creeLe.value : this.creeLe,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EntrepriseUser(')
          ..write('cloudId: $cloudId, ')
          ..write('entrepriseId: $entrepriseId, ')
          ..write('userId: $userId, ')
          ..write('role: $role, ')
          ..write('statut: $statut, ')
          ..write('revokedAt: $revokedAt, ')
          ..write('creeLe: $creeLe, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    cloudId,
    entrepriseId,
    userId,
    role,
    statut,
    revokedAt,
    creeLe,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EntrepriseUser &&
          other.cloudId == this.cloudId &&
          other.entrepriseId == this.entrepriseId &&
          other.userId == this.userId &&
          other.role == this.role &&
          other.statut == this.statut &&
          other.revokedAt == this.revokedAt &&
          other.creeLe == this.creeLe &&
          other.updatedAt == this.updatedAt);
}

class EntrepriseUsersCompanion extends UpdateCompanion<EntrepriseUser> {
  final Value<String> cloudId;
  final Value<String> entrepriseId;
  final Value<String> userId;
  final Value<String> role;
  final Value<String> statut;
  final Value<DateTime?> revokedAt;
  final Value<DateTime> creeLe;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const EntrepriseUsersCompanion({
    this.cloudId = const Value.absent(),
    this.entrepriseId = const Value.absent(),
    this.userId = const Value.absent(),
    this.role = const Value.absent(),
    this.statut = const Value.absent(),
    this.revokedAt = const Value.absent(),
    this.creeLe = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EntrepriseUsersCompanion.insert({
    required String cloudId,
    required String entrepriseId,
    required String userId,
    required String role,
    this.statut = const Value.absent(),
    this.revokedAt = const Value.absent(),
    this.creeLe = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : cloudId = Value(cloudId),
       entrepriseId = Value(entrepriseId),
       userId = Value(userId),
       role = Value(role);
  static Insertable<EntrepriseUser> custom({
    Expression<String>? cloudId,
    Expression<String>? entrepriseId,
    Expression<String>? userId,
    Expression<String>? role,
    Expression<String>? statut,
    Expression<DateTime>? revokedAt,
    Expression<DateTime>? creeLe,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cloudId != null) 'cloud_id': cloudId,
      if (entrepriseId != null) 'entreprise_id': entrepriseId,
      if (userId != null) 'user_id': userId,
      if (role != null) 'role': role,
      if (statut != null) 'statut': statut,
      if (revokedAt != null) 'revoked_at': revokedAt,
      if (creeLe != null) 'cree_le': creeLe,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EntrepriseUsersCompanion copyWith({
    Value<String>? cloudId,
    Value<String>? entrepriseId,
    Value<String>? userId,
    Value<String>? role,
    Value<String>? statut,
    Value<DateTime?>? revokedAt,
    Value<DateTime>? creeLe,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return EntrepriseUsersCompanion(
      cloudId: cloudId ?? this.cloudId,
      entrepriseId: entrepriseId ?? this.entrepriseId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      statut: statut ?? this.statut,
      revokedAt: revokedAt ?? this.revokedAt,
      creeLe: creeLe ?? this.creeLe,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cloudId.present) {
      map['cloud_id'] = Variable<String>(cloudId.value);
    }
    if (entrepriseId.present) {
      map['entreprise_id'] = Variable<String>(entrepriseId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (statut.present) {
      map['statut'] = Variable<String>(statut.value);
    }
    if (revokedAt.present) {
      map['revoked_at'] = Variable<DateTime>(revokedAt.value);
    }
    if (creeLe.present) {
      map['cree_le'] = Variable<DateTime>(creeLe.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntrepriseUsersCompanion(')
          ..write('cloudId: $cloudId, ')
          ..write('entrepriseId: $entrepriseId, ')
          ..write('userId: $userId, ')
          ..write('role: $role, ')
          ..write('statut: $statut, ')
          ..write('revokedAt: $revokedAt, ')
          ..write('creeLe: $creeLe, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EntrepotUsersTable extends EntrepotUsers
    with TableInfo<$EntrepotUsersTable, EntrepotUser> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntrepotUsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cloudIdMeta = const VerificationMeta(
    'cloudId',
  );
  @override
  late final GeneratedColumn<String> cloudId = GeneratedColumn<String>(
    'cloud_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entrepotIdMeta = const VerificationMeta(
    'entrepotId',
  );
  @override
  late final GeneratedColumn<String> entrepotId = GeneratedColumn<String>(
    'entrepot_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES entrepots (cloud_id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
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
  static const VerificationMeta _statutMeta = const VerificationMeta('statut');
  @override
  late final GeneratedColumn<String> statut = GeneratedColumn<String>(
    'statut',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('actif'),
  );
  static const VerificationMeta _revokedAtMeta = const VerificationMeta(
    'revokedAt',
  );
  @override
  late final GeneratedColumn<DateTime> revokedAt = GeneratedColumn<DateTime>(
    'revoked_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
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
    cloudId,
    entrepotId,
    userId,
    role,
    statut,
    revokedAt,
    creeLe,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entrepot_users';
  @override
  VerificationContext validateIntegrity(
    Insertable<EntrepotUser> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cloud_id')) {
      context.handle(
        _cloudIdMeta,
        cloudId.isAcceptableOrUnknown(data['cloud_id']!, _cloudIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cloudIdMeta);
    }
    if (data.containsKey('entrepot_id')) {
      context.handle(
        _entrepotIdMeta,
        entrepotId.isAcceptableOrUnknown(data['entrepot_id']!, _entrepotIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entrepotIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('statut')) {
      context.handle(
        _statutMeta,
        statut.isAcceptableOrUnknown(data['statut']!, _statutMeta),
      );
    }
    if (data.containsKey('revoked_at')) {
      context.handle(
        _revokedAtMeta,
        revokedAt.isAcceptableOrUnknown(data['revoked_at']!, _revokedAtMeta),
      );
    }
    if (data.containsKey('cree_le')) {
      context.handle(
        _creeLeMeta,
        creeLe.isAcceptableOrUnknown(data['cree_le']!, _creeLeMeta),
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
  Set<GeneratedColumn> get $primaryKey => {cloudId};
  @override
  EntrepotUser map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EntrepotUser(
      cloudId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cloud_id'],
      )!,
      entrepotId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entrepot_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      statut: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}statut'],
      )!,
      revokedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}revoked_at'],
      ),
      creeLe: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cree_le'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $EntrepotUsersTable createAlias(String alias) {
    return $EntrepotUsersTable(attachedDatabase, alias);
  }
}

class EntrepotUser extends DataClass implements Insertable<EntrepotUser> {
  final String cloudId;
  final String entrepotId;

  /// UUID Supabase auth.users
  final String userId;

  /// 'chef_entrepot' | 'employe'
  final String role;

  /// 'actif' | 'revoque' | 'expire'
  final String statut;
  final DateTime? revokedAt;
  final DateTime creeLe;
  final DateTime updatedAt;
  const EntrepotUser({
    required this.cloudId,
    required this.entrepotId,
    required this.userId,
    required this.role,
    required this.statut,
    this.revokedAt,
    required this.creeLe,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cloud_id'] = Variable<String>(cloudId);
    map['entrepot_id'] = Variable<String>(entrepotId);
    map['user_id'] = Variable<String>(userId);
    map['role'] = Variable<String>(role);
    map['statut'] = Variable<String>(statut);
    if (!nullToAbsent || revokedAt != null) {
      map['revoked_at'] = Variable<DateTime>(revokedAt);
    }
    map['cree_le'] = Variable<DateTime>(creeLe);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  EntrepotUsersCompanion toCompanion(bool nullToAbsent) {
    return EntrepotUsersCompanion(
      cloudId: Value(cloudId),
      entrepotId: Value(entrepotId),
      userId: Value(userId),
      role: Value(role),
      statut: Value(statut),
      revokedAt: revokedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(revokedAt),
      creeLe: Value(creeLe),
      updatedAt: Value(updatedAt),
    );
  }

  factory EntrepotUser.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EntrepotUser(
      cloudId: serializer.fromJson<String>(json['cloudId']),
      entrepotId: serializer.fromJson<String>(json['entrepotId']),
      userId: serializer.fromJson<String>(json['userId']),
      role: serializer.fromJson<String>(json['role']),
      statut: serializer.fromJson<String>(json['statut']),
      revokedAt: serializer.fromJson<DateTime?>(json['revokedAt']),
      creeLe: serializer.fromJson<DateTime>(json['creeLe']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cloudId': serializer.toJson<String>(cloudId),
      'entrepotId': serializer.toJson<String>(entrepotId),
      'userId': serializer.toJson<String>(userId),
      'role': serializer.toJson<String>(role),
      'statut': serializer.toJson<String>(statut),
      'revokedAt': serializer.toJson<DateTime?>(revokedAt),
      'creeLe': serializer.toJson<DateTime>(creeLe),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  EntrepotUser copyWith({
    String? cloudId,
    String? entrepotId,
    String? userId,
    String? role,
    String? statut,
    Value<DateTime?> revokedAt = const Value.absent(),
    DateTime? creeLe,
    DateTime? updatedAt,
  }) => EntrepotUser(
    cloudId: cloudId ?? this.cloudId,
    entrepotId: entrepotId ?? this.entrepotId,
    userId: userId ?? this.userId,
    role: role ?? this.role,
    statut: statut ?? this.statut,
    revokedAt: revokedAt.present ? revokedAt.value : this.revokedAt,
    creeLe: creeLe ?? this.creeLe,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  EntrepotUser copyWithCompanion(EntrepotUsersCompanion data) {
    return EntrepotUser(
      cloudId: data.cloudId.present ? data.cloudId.value : this.cloudId,
      entrepotId: data.entrepotId.present
          ? data.entrepotId.value
          : this.entrepotId,
      userId: data.userId.present ? data.userId.value : this.userId,
      role: data.role.present ? data.role.value : this.role,
      statut: data.statut.present ? data.statut.value : this.statut,
      revokedAt: data.revokedAt.present ? data.revokedAt.value : this.revokedAt,
      creeLe: data.creeLe.present ? data.creeLe.value : this.creeLe,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EntrepotUser(')
          ..write('cloudId: $cloudId, ')
          ..write('entrepotId: $entrepotId, ')
          ..write('userId: $userId, ')
          ..write('role: $role, ')
          ..write('statut: $statut, ')
          ..write('revokedAt: $revokedAt, ')
          ..write('creeLe: $creeLe, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    cloudId,
    entrepotId,
    userId,
    role,
    statut,
    revokedAt,
    creeLe,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EntrepotUser &&
          other.cloudId == this.cloudId &&
          other.entrepotId == this.entrepotId &&
          other.userId == this.userId &&
          other.role == this.role &&
          other.statut == this.statut &&
          other.revokedAt == this.revokedAt &&
          other.creeLe == this.creeLe &&
          other.updatedAt == this.updatedAt);
}

class EntrepotUsersCompanion extends UpdateCompanion<EntrepotUser> {
  final Value<String> cloudId;
  final Value<String> entrepotId;
  final Value<String> userId;
  final Value<String> role;
  final Value<String> statut;
  final Value<DateTime?> revokedAt;
  final Value<DateTime> creeLe;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const EntrepotUsersCompanion({
    this.cloudId = const Value.absent(),
    this.entrepotId = const Value.absent(),
    this.userId = const Value.absent(),
    this.role = const Value.absent(),
    this.statut = const Value.absent(),
    this.revokedAt = const Value.absent(),
    this.creeLe = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EntrepotUsersCompanion.insert({
    required String cloudId,
    required String entrepotId,
    required String userId,
    required String role,
    this.statut = const Value.absent(),
    this.revokedAt = const Value.absent(),
    this.creeLe = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : cloudId = Value(cloudId),
       entrepotId = Value(entrepotId),
       userId = Value(userId),
       role = Value(role);
  static Insertable<EntrepotUser> custom({
    Expression<String>? cloudId,
    Expression<String>? entrepotId,
    Expression<String>? userId,
    Expression<String>? role,
    Expression<String>? statut,
    Expression<DateTime>? revokedAt,
    Expression<DateTime>? creeLe,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cloudId != null) 'cloud_id': cloudId,
      if (entrepotId != null) 'entrepot_id': entrepotId,
      if (userId != null) 'user_id': userId,
      if (role != null) 'role': role,
      if (statut != null) 'statut': statut,
      if (revokedAt != null) 'revoked_at': revokedAt,
      if (creeLe != null) 'cree_le': creeLe,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EntrepotUsersCompanion copyWith({
    Value<String>? cloudId,
    Value<String>? entrepotId,
    Value<String>? userId,
    Value<String>? role,
    Value<String>? statut,
    Value<DateTime?>? revokedAt,
    Value<DateTime>? creeLe,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return EntrepotUsersCompanion(
      cloudId: cloudId ?? this.cloudId,
      entrepotId: entrepotId ?? this.entrepotId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      statut: statut ?? this.statut,
      revokedAt: revokedAt ?? this.revokedAt,
      creeLe: creeLe ?? this.creeLe,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cloudId.present) {
      map['cloud_id'] = Variable<String>(cloudId.value);
    }
    if (entrepotId.present) {
      map['entrepot_id'] = Variable<String>(entrepotId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (statut.present) {
      map['statut'] = Variable<String>(statut.value);
    }
    if (revokedAt.present) {
      map['revoked_at'] = Variable<DateTime>(revokedAt.value);
    }
    if (creeLe.present) {
      map['cree_le'] = Variable<DateTime>(creeLe.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntrepotUsersCompanion(')
          ..write('cloudId: $cloudId, ')
          ..write('entrepotId: $entrepotId, ')
          ..write('userId: $userId, ')
          ..write('role: $role, ')
          ..write('statut: $statut, ')
          ..write('revokedAt: $revokedAt, ')
          ..write('creeLe: $creeLe, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EntrepriseInvitationsTable extends EntrepriseInvitations
    with TableInfo<$EntrepriseInvitationsTable, EntrepriseInvitation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntrepriseInvitationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cloudIdMeta = const VerificationMeta(
    'cloudId',
  );
  @override
  late final GeneratedColumn<String> cloudId = GeneratedColumn<String>(
    'cloud_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entrepriseIdMeta = const VerificationMeta(
    'entrepriseId',
  );
  @override
  late final GeneratedColumn<String> entrepriseId = GeneratedColumn<String>(
    'entreprise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES entreprises (cloud_id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _entrepotIdMeta = const VerificationMeta(
    'entrepotId',
  );
  @override
  late final GeneratedColumn<String> entrepotId = GeneratedColumn<String>(
    'entrepot_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES entrepots (cloud_id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleTargetMeta = const VerificationMeta(
    'roleTarget',
  );
  @override
  late final GeneratedColumn<String> roleTarget = GeneratedColumn<String>(
    'role_target',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _invitedByMeta = const VerificationMeta(
    'invitedBy',
  );
  @override
  late final GeneratedColumn<String> invitedBy = GeneratedColumn<String>(
    'invited_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statutMeta = const VerificationMeta('statut');
  @override
  late final GeneratedColumn<String> statut = GeneratedColumn<String>(
    'statut',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
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
    cloudId,
    entrepriseId,
    entrepotId,
    email,
    roleTarget,
    invitedBy,
    statut,
    expiresAt,
    creeLe,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entreprise_invitations';
  @override
  VerificationContext validateIntegrity(
    Insertable<EntrepriseInvitation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cloud_id')) {
      context.handle(
        _cloudIdMeta,
        cloudId.isAcceptableOrUnknown(data['cloud_id']!, _cloudIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cloudIdMeta);
    }
    if (data.containsKey('entreprise_id')) {
      context.handle(
        _entrepriseIdMeta,
        entrepriseId.isAcceptableOrUnknown(
          data['entreprise_id']!,
          _entrepriseIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_entrepriseIdMeta);
    }
    if (data.containsKey('entrepot_id')) {
      context.handle(
        _entrepotIdMeta,
        entrepotId.isAcceptableOrUnknown(data['entrepot_id']!, _entrepotIdMeta),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('role_target')) {
      context.handle(
        _roleTargetMeta,
        roleTarget.isAcceptableOrUnknown(data['role_target']!, _roleTargetMeta),
      );
    } else if (isInserting) {
      context.missing(_roleTargetMeta);
    }
    if (data.containsKey('invited_by')) {
      context.handle(
        _invitedByMeta,
        invitedBy.isAcceptableOrUnknown(data['invited_by']!, _invitedByMeta),
      );
    } else if (isInserting) {
      context.missing(_invitedByMeta);
    }
    if (data.containsKey('statut')) {
      context.handle(
        _statutMeta,
        statut.isAcceptableOrUnknown(data['statut']!, _statutMeta),
      );
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
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
  Set<GeneratedColumn> get $primaryKey => {cloudId};
  @override
  EntrepriseInvitation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EntrepriseInvitation(
      cloudId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cloud_id'],
      )!,
      entrepriseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entreprise_id'],
      )!,
      entrepotId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entrepot_id'],
      ),
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      roleTarget: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role_target'],
      )!,
      invitedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invited_by'],
      )!,
      statut: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}statut'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      )!,
      creeLe: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cree_le'],
      )!,
    );
  }

  @override
  $EntrepriseInvitationsTable createAlias(String alias) {
    return $EntrepriseInvitationsTable(attachedDatabase, alias);
  }
}

class EntrepriseInvitation extends DataClass
    implements Insertable<EntrepriseInvitation> {
  final String cloudId;
  final String entrepriseId;

  /// Optionnel : si l'invitation cible un entrepôt précis. NULL =
  /// invitation au niveau entreprise (l'admin pourra rattacher
  /// l'employé à des entrepôts après acceptation).
  final String? entrepotId;
  final String email;

  /// 'admin_entreprise' | 'chef_entrepot' | 'employe'
  final String roleTarget;

  /// UUID Supabase auth.users de l'inviteur
  final String invitedBy;

  /// 'pending' | 'accepted' | 'expired' | 'revoked'
  final String statut;

  /// TTL 7 jours par défaut (cf #363 Edge Function `invite_employee`).
  final DateTime expiresAt;
  final DateTime creeLe;
  const EntrepriseInvitation({
    required this.cloudId,
    required this.entrepriseId,
    this.entrepotId,
    required this.email,
    required this.roleTarget,
    required this.invitedBy,
    required this.statut,
    required this.expiresAt,
    required this.creeLe,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cloud_id'] = Variable<String>(cloudId);
    map['entreprise_id'] = Variable<String>(entrepriseId);
    if (!nullToAbsent || entrepotId != null) {
      map['entrepot_id'] = Variable<String>(entrepotId);
    }
    map['email'] = Variable<String>(email);
    map['role_target'] = Variable<String>(roleTarget);
    map['invited_by'] = Variable<String>(invitedBy);
    map['statut'] = Variable<String>(statut);
    map['expires_at'] = Variable<DateTime>(expiresAt);
    map['cree_le'] = Variable<DateTime>(creeLe);
    return map;
  }

  EntrepriseInvitationsCompanion toCompanion(bool nullToAbsent) {
    return EntrepriseInvitationsCompanion(
      cloudId: Value(cloudId),
      entrepriseId: Value(entrepriseId),
      entrepotId: entrepotId == null && nullToAbsent
          ? const Value.absent()
          : Value(entrepotId),
      email: Value(email),
      roleTarget: Value(roleTarget),
      invitedBy: Value(invitedBy),
      statut: Value(statut),
      expiresAt: Value(expiresAt),
      creeLe: Value(creeLe),
    );
  }

  factory EntrepriseInvitation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EntrepriseInvitation(
      cloudId: serializer.fromJson<String>(json['cloudId']),
      entrepriseId: serializer.fromJson<String>(json['entrepriseId']),
      entrepotId: serializer.fromJson<String?>(json['entrepotId']),
      email: serializer.fromJson<String>(json['email']),
      roleTarget: serializer.fromJson<String>(json['roleTarget']),
      invitedBy: serializer.fromJson<String>(json['invitedBy']),
      statut: serializer.fromJson<String>(json['statut']),
      expiresAt: serializer.fromJson<DateTime>(json['expiresAt']),
      creeLe: serializer.fromJson<DateTime>(json['creeLe']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cloudId': serializer.toJson<String>(cloudId),
      'entrepriseId': serializer.toJson<String>(entrepriseId),
      'entrepotId': serializer.toJson<String?>(entrepotId),
      'email': serializer.toJson<String>(email),
      'roleTarget': serializer.toJson<String>(roleTarget),
      'invitedBy': serializer.toJson<String>(invitedBy),
      'statut': serializer.toJson<String>(statut),
      'expiresAt': serializer.toJson<DateTime>(expiresAt),
      'creeLe': serializer.toJson<DateTime>(creeLe),
    };
  }

  EntrepriseInvitation copyWith({
    String? cloudId,
    String? entrepriseId,
    Value<String?> entrepotId = const Value.absent(),
    String? email,
    String? roleTarget,
    String? invitedBy,
    String? statut,
    DateTime? expiresAt,
    DateTime? creeLe,
  }) => EntrepriseInvitation(
    cloudId: cloudId ?? this.cloudId,
    entrepriseId: entrepriseId ?? this.entrepriseId,
    entrepotId: entrepotId.present ? entrepotId.value : this.entrepotId,
    email: email ?? this.email,
    roleTarget: roleTarget ?? this.roleTarget,
    invitedBy: invitedBy ?? this.invitedBy,
    statut: statut ?? this.statut,
    expiresAt: expiresAt ?? this.expiresAt,
    creeLe: creeLe ?? this.creeLe,
  );
  EntrepriseInvitation copyWithCompanion(EntrepriseInvitationsCompanion data) {
    return EntrepriseInvitation(
      cloudId: data.cloudId.present ? data.cloudId.value : this.cloudId,
      entrepriseId: data.entrepriseId.present
          ? data.entrepriseId.value
          : this.entrepriseId,
      entrepotId: data.entrepotId.present
          ? data.entrepotId.value
          : this.entrepotId,
      email: data.email.present ? data.email.value : this.email,
      roleTarget: data.roleTarget.present
          ? data.roleTarget.value
          : this.roleTarget,
      invitedBy: data.invitedBy.present ? data.invitedBy.value : this.invitedBy,
      statut: data.statut.present ? data.statut.value : this.statut,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      creeLe: data.creeLe.present ? data.creeLe.value : this.creeLe,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EntrepriseInvitation(')
          ..write('cloudId: $cloudId, ')
          ..write('entrepriseId: $entrepriseId, ')
          ..write('entrepotId: $entrepotId, ')
          ..write('email: $email, ')
          ..write('roleTarget: $roleTarget, ')
          ..write('invitedBy: $invitedBy, ')
          ..write('statut: $statut, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('creeLe: $creeLe')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    cloudId,
    entrepriseId,
    entrepotId,
    email,
    roleTarget,
    invitedBy,
    statut,
    expiresAt,
    creeLe,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EntrepriseInvitation &&
          other.cloudId == this.cloudId &&
          other.entrepriseId == this.entrepriseId &&
          other.entrepotId == this.entrepotId &&
          other.email == this.email &&
          other.roleTarget == this.roleTarget &&
          other.invitedBy == this.invitedBy &&
          other.statut == this.statut &&
          other.expiresAt == this.expiresAt &&
          other.creeLe == this.creeLe);
}

class EntrepriseInvitationsCompanion
    extends UpdateCompanion<EntrepriseInvitation> {
  final Value<String> cloudId;
  final Value<String> entrepriseId;
  final Value<String?> entrepotId;
  final Value<String> email;
  final Value<String> roleTarget;
  final Value<String> invitedBy;
  final Value<String> statut;
  final Value<DateTime> expiresAt;
  final Value<DateTime> creeLe;
  final Value<int> rowid;
  const EntrepriseInvitationsCompanion({
    this.cloudId = const Value.absent(),
    this.entrepriseId = const Value.absent(),
    this.entrepotId = const Value.absent(),
    this.email = const Value.absent(),
    this.roleTarget = const Value.absent(),
    this.invitedBy = const Value.absent(),
    this.statut = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.creeLe = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EntrepriseInvitationsCompanion.insert({
    required String cloudId,
    required String entrepriseId,
    this.entrepotId = const Value.absent(),
    required String email,
    required String roleTarget,
    required String invitedBy,
    this.statut = const Value.absent(),
    required DateTime expiresAt,
    this.creeLe = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : cloudId = Value(cloudId),
       entrepriseId = Value(entrepriseId),
       email = Value(email),
       roleTarget = Value(roleTarget),
       invitedBy = Value(invitedBy),
       expiresAt = Value(expiresAt);
  static Insertable<EntrepriseInvitation> custom({
    Expression<String>? cloudId,
    Expression<String>? entrepriseId,
    Expression<String>? entrepotId,
    Expression<String>? email,
    Expression<String>? roleTarget,
    Expression<String>? invitedBy,
    Expression<String>? statut,
    Expression<DateTime>? expiresAt,
    Expression<DateTime>? creeLe,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cloudId != null) 'cloud_id': cloudId,
      if (entrepriseId != null) 'entreprise_id': entrepriseId,
      if (entrepotId != null) 'entrepot_id': entrepotId,
      if (email != null) 'email': email,
      if (roleTarget != null) 'role_target': roleTarget,
      if (invitedBy != null) 'invited_by': invitedBy,
      if (statut != null) 'statut': statut,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (creeLe != null) 'cree_le': creeLe,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EntrepriseInvitationsCompanion copyWith({
    Value<String>? cloudId,
    Value<String>? entrepriseId,
    Value<String?>? entrepotId,
    Value<String>? email,
    Value<String>? roleTarget,
    Value<String>? invitedBy,
    Value<String>? statut,
    Value<DateTime>? expiresAt,
    Value<DateTime>? creeLe,
    Value<int>? rowid,
  }) {
    return EntrepriseInvitationsCompanion(
      cloudId: cloudId ?? this.cloudId,
      entrepriseId: entrepriseId ?? this.entrepriseId,
      entrepotId: entrepotId ?? this.entrepotId,
      email: email ?? this.email,
      roleTarget: roleTarget ?? this.roleTarget,
      invitedBy: invitedBy ?? this.invitedBy,
      statut: statut ?? this.statut,
      expiresAt: expiresAt ?? this.expiresAt,
      creeLe: creeLe ?? this.creeLe,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cloudId.present) {
      map['cloud_id'] = Variable<String>(cloudId.value);
    }
    if (entrepriseId.present) {
      map['entreprise_id'] = Variable<String>(entrepriseId.value);
    }
    if (entrepotId.present) {
      map['entrepot_id'] = Variable<String>(entrepotId.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (roleTarget.present) {
      map['role_target'] = Variable<String>(roleTarget.value);
    }
    if (invitedBy.present) {
      map['invited_by'] = Variable<String>(invitedBy.value);
    }
    if (statut.present) {
      map['statut'] = Variable<String>(statut.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (creeLe.present) {
      map['cree_le'] = Variable<DateTime>(creeLe.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntrepriseInvitationsCompanion(')
          ..write('cloudId: $cloudId, ')
          ..write('entrepriseId: $entrepriseId, ')
          ..write('entrepotId: $entrepotId, ')
          ..write('email: $email, ')
          ..write('roleTarget: $roleTarget, ')
          ..write('invitedBy: $invitedBy, ')
          ..write('statut: $statut, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('creeLe: $creeLe, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SavedDestinationNotesPersoTable extends SavedDestinationNotesPerso
    with
        TableInfo<
          $SavedDestinationNotesPersoTable,
          SavedDestinationNotesPersoData
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavedDestinationNotesPersoTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cloudIdMeta = const VerificationMeta(
    'cloudId',
  );
  @override
  late final GeneratedColumn<String> cloudId = GeneratedColumn<String>(
    'cloud_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _savedDestinationIdMeta =
      const VerificationMeta('savedDestinationId');
  @override
  late final GeneratedColumn<String> savedDestinationId =
      GeneratedColumn<String>(
        'saved_destination_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    cloudId,
    savedDestinationId,
    userId,
    notes,
    creeLe,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_destination_notes_perso';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavedDestinationNotesPersoData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cloud_id')) {
      context.handle(
        _cloudIdMeta,
        cloudId.isAcceptableOrUnknown(data['cloud_id']!, _cloudIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cloudIdMeta);
    }
    if (data.containsKey('saved_destination_id')) {
      context.handle(
        _savedDestinationIdMeta,
        savedDestinationId.isAcceptableOrUnknown(
          data['saved_destination_id']!,
          _savedDestinationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_savedDestinationIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('cree_le')) {
      context.handle(
        _creeLeMeta,
        creeLe.isAcceptableOrUnknown(data['cree_le']!, _creeLeMeta),
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
  Set<GeneratedColumn> get $primaryKey => {cloudId};
  @override
  SavedDestinationNotesPersoData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedDestinationNotesPersoData(
      cloudId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cloud_id'],
      )!,
      savedDestinationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}saved_destination_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      creeLe: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cree_le'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SavedDestinationNotesPersoTable createAlias(String alias) {
    return $SavedDestinationNotesPersoTable(attachedDatabase, alias);
  }
}

class SavedDestinationNotesPersoData extends DataClass
    implements Insertable<SavedDestinationNotesPersoData> {
  final String cloudId;

  /// Référence le cloud_id de la `saved_destinations` partagée.
  /// On ne met PAS de FK Drift ici parce que cette table peut référer
  /// un savedDestinations qui n'existe pas encore localement (pull
  /// décalé). Le sync cloud rétablit l'intégrité.
  final String savedDestinationId;

  /// UUID Supabase auth.users du propriétaire de la note.
  final String userId;
  final String? notes;
  final DateTime creeLe;
  final DateTime updatedAt;
  const SavedDestinationNotesPersoData({
    required this.cloudId,
    required this.savedDestinationId,
    required this.userId,
    this.notes,
    required this.creeLe,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cloud_id'] = Variable<String>(cloudId);
    map['saved_destination_id'] = Variable<String>(savedDestinationId);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['cree_le'] = Variable<DateTime>(creeLe);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SavedDestinationNotesPersoCompanion toCompanion(bool nullToAbsent) {
    return SavedDestinationNotesPersoCompanion(
      cloudId: Value(cloudId),
      savedDestinationId: Value(savedDestinationId),
      userId: Value(userId),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      creeLe: Value(creeLe),
      updatedAt: Value(updatedAt),
    );
  }

  factory SavedDestinationNotesPersoData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedDestinationNotesPersoData(
      cloudId: serializer.fromJson<String>(json['cloudId']),
      savedDestinationId: serializer.fromJson<String>(
        json['savedDestinationId'],
      ),
      userId: serializer.fromJson<String>(json['userId']),
      notes: serializer.fromJson<String?>(json['notes']),
      creeLe: serializer.fromJson<DateTime>(json['creeLe']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cloudId': serializer.toJson<String>(cloudId),
      'savedDestinationId': serializer.toJson<String>(savedDestinationId),
      'userId': serializer.toJson<String>(userId),
      'notes': serializer.toJson<String?>(notes),
      'creeLe': serializer.toJson<DateTime>(creeLe),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SavedDestinationNotesPersoData copyWith({
    String? cloudId,
    String? savedDestinationId,
    String? userId,
    Value<String?> notes = const Value.absent(),
    DateTime? creeLe,
    DateTime? updatedAt,
  }) => SavedDestinationNotesPersoData(
    cloudId: cloudId ?? this.cloudId,
    savedDestinationId: savedDestinationId ?? this.savedDestinationId,
    userId: userId ?? this.userId,
    notes: notes.present ? notes.value : this.notes,
    creeLe: creeLe ?? this.creeLe,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SavedDestinationNotesPersoData copyWithCompanion(
    SavedDestinationNotesPersoCompanion data,
  ) {
    return SavedDestinationNotesPersoData(
      cloudId: data.cloudId.present ? data.cloudId.value : this.cloudId,
      savedDestinationId: data.savedDestinationId.present
          ? data.savedDestinationId.value
          : this.savedDestinationId,
      userId: data.userId.present ? data.userId.value : this.userId,
      notes: data.notes.present ? data.notes.value : this.notes,
      creeLe: data.creeLe.present ? data.creeLe.value : this.creeLe,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedDestinationNotesPersoData(')
          ..write('cloudId: $cloudId, ')
          ..write('savedDestinationId: $savedDestinationId, ')
          ..write('userId: $userId, ')
          ..write('notes: $notes, ')
          ..write('creeLe: $creeLe, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    cloudId,
    savedDestinationId,
    userId,
    notes,
    creeLe,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedDestinationNotesPersoData &&
          other.cloudId == this.cloudId &&
          other.savedDestinationId == this.savedDestinationId &&
          other.userId == this.userId &&
          other.notes == this.notes &&
          other.creeLe == this.creeLe &&
          other.updatedAt == this.updatedAt);
}

class SavedDestinationNotesPersoCompanion
    extends UpdateCompanion<SavedDestinationNotesPersoData> {
  final Value<String> cloudId;
  final Value<String> savedDestinationId;
  final Value<String> userId;
  final Value<String?> notes;
  final Value<DateTime> creeLe;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SavedDestinationNotesPersoCompanion({
    this.cloudId = const Value.absent(),
    this.savedDestinationId = const Value.absent(),
    this.userId = const Value.absent(),
    this.notes = const Value.absent(),
    this.creeLe = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavedDestinationNotesPersoCompanion.insert({
    required String cloudId,
    required String savedDestinationId,
    required String userId,
    this.notes = const Value.absent(),
    this.creeLe = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : cloudId = Value(cloudId),
       savedDestinationId = Value(savedDestinationId),
       userId = Value(userId);
  static Insertable<SavedDestinationNotesPersoData> custom({
    Expression<String>? cloudId,
    Expression<String>? savedDestinationId,
    Expression<String>? userId,
    Expression<String>? notes,
    Expression<DateTime>? creeLe,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cloudId != null) 'cloud_id': cloudId,
      if (savedDestinationId != null)
        'saved_destination_id': savedDestinationId,
      if (userId != null) 'user_id': userId,
      if (notes != null) 'notes': notes,
      if (creeLe != null) 'cree_le': creeLe,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavedDestinationNotesPersoCompanion copyWith({
    Value<String>? cloudId,
    Value<String>? savedDestinationId,
    Value<String>? userId,
    Value<String?>? notes,
    Value<DateTime>? creeLe,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SavedDestinationNotesPersoCompanion(
      cloudId: cloudId ?? this.cloudId,
      savedDestinationId: savedDestinationId ?? this.savedDestinationId,
      userId: userId ?? this.userId,
      notes: notes ?? this.notes,
      creeLe: creeLe ?? this.creeLe,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cloudId.present) {
      map['cloud_id'] = Variable<String>(cloudId.value);
    }
    if (savedDestinationId.present) {
      map['saved_destination_id'] = Variable<String>(savedDestinationId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (creeLe.present) {
      map['cree_le'] = Variable<DateTime>(creeLe.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavedDestinationNotesPersoCompanion(')
          ..write('cloudId: $cloudId, ')
          ..write('savedDestinationId: $savedDestinationId, ')
          ..write('userId: $userId, ')
          ..write('notes: $notes, ')
          ..write('creeLe: $creeLe, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
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
  late final $FraisTable frais = $FraisTable(this);
  late final $TrackingCodesTable trackingCodes = $TrackingCodesTable(this);
  late final $TourneeRecurrencesTable tourneeRecurrences =
      $TourneeRecurrencesTable(this);
  late final $WorkSessionsTable workSessions = $WorkSessionsTable(this);
  late final $EntreprisesTable entreprises = $EntreprisesTable(this);
  late final $EntrepotsTable entrepots = $EntrepotsTable(this);
  late final $EntrepriseUsersTable entrepriseUsers = $EntrepriseUsersTable(
    this,
  );
  late final $EntrepotUsersTable entrepotUsers = $EntrepotUsersTable(this);
  late final $EntrepriseInvitationsTable entrepriseInvitations =
      $EntrepriseInvitationsTable(this);
  late final $SavedDestinationNotesPersoTable savedDestinationNotesPerso =
      $SavedDestinationNotesPersoTable(this);
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
    frais,
    trackingCodes,
    tourneeRecurrences,
    workSessions,
    entreprises,
    entrepots,
    entrepriseUsers,
    entrepotUsers,
    entrepriseInvitations,
    savedDestinationNotesPerso,
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
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'stops',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('tracking_codes', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tournees',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('tournee_recurrences', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'entreprises',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('entrepots', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'entreprises',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('entreprise_users', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'entrepots',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('entrepot_users', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'entreprises',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('entreprise_invitations', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'entrepots',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('entreprise_invitations', kind: UpdateKind.update)],
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

  static MultiTypedResultKey<$TourneeRecurrencesTable, List<TourneeRecurrence>>
  _tourneeRecurrencesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.tourneeRecurrences,
        aliasName: $_aliasNameGenerator(
          db.tournees.id,
          db.tourneeRecurrences.templateId,
        ),
      );

  $$TourneeRecurrencesTableProcessedTableManager get tourneeRecurrencesRefs {
    final manager = $$TourneeRecurrencesTableTableManager(
      $_db,
      $_db.tourneeRecurrences,
    ).filter((f) => f.templateId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _tourneeRecurrencesRefsTable($_db),
    );
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

  Expression<bool> tourneeRecurrencesRefs(
    Expression<bool> Function($$TourneeRecurrencesTableFilterComposer f) f,
  ) {
    final $$TourneeRecurrencesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tourneeRecurrences,
      getReferencedColumn: (t) => t.templateId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TourneeRecurrencesTableFilterComposer(
            $db: $db,
            $table: $db.tourneeRecurrences,
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

  Expression<T> tourneeRecurrencesRefs<T extends Object>(
    Expression<T> Function($$TourneeRecurrencesTableAnnotationComposer a) f,
  ) {
    final $$TourneeRecurrencesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.tourneeRecurrences,
          getReferencedColumn: (t) => t.templateId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TourneeRecurrencesTableAnnotationComposer(
                $db: $db,
                $table: $db.tourneeRecurrences,
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
          PrefetchHooks Function({bool stopsRefs, bool tourneeRecurrencesRefs})
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
          prefetchHooksCallback:
              ({stopsRefs = false, tourneeRecurrencesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (stopsRefs) db.stops,
                    if (tourneeRecurrencesRefs) db.tourneeRecurrences,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (stopsRefs)
                        await $_getPrefetchedData<
                          Tournee,
                          $TourneesTable,
                          Stop
                        >(
                          currentTable: table,
                          referencedTable: $$TourneesTableReferences
                              ._stopsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TourneesTableReferences(
                                db,
                                table,
                                p0,
                              ).stopsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.tourneeId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (tourneeRecurrencesRefs)
                        await $_getPrefetchedData<
                          Tournee,
                          $TourneesTable,
                          TourneeRecurrence
                        >(
                          currentTable: table,
                          referencedTable: $$TourneesTableReferences
                              ._tourneeRecurrencesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TourneesTableReferences(
                                db,
                                table,
                                p0,
                              ).tourneeRecurrencesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.templateId == item.id,
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
      PrefetchHooks Function({bool stopsRefs, bool tourneeRecurrencesRefs})
    >;
typedef $$StopsTableCreateCompanionBuilder =
    StopsCompanion Function({
      Value<int> id,
      required int tourneeId,
      required String adresseBrute,
      Value<String?> adresseNormalisee,
      Value<String> type,
      Value<double?> lat,
      Value<double?> lng,
      Value<int> nbColis,
      Value<String> priorite,
      Value<String?> fenetreDebut,
      Value<String?> fenetreFin,
      Value<int> dureeArretMin,
      Value<String?> notes,
      Value<String?> nomClient,
      Value<String?> telephone,
      Value<String> statutLivraison,
      Value<String?> raisonEchec,
      Value<double?> livreLat,
      Value<double?> livreLng,
      Value<DateTime?> livreLe,
      Value<int?> ordreOptimise,
      Value<bool> positionLocked,
      Value<int?> ordrePriorite,
      Value<String?> preuvePhotoPath,
      Value<int?> coequipierId,
      Value<DateTime> creeLe,
      Value<String?> cloudId,
      Value<String?> cloudPhotoPath,
      Value<DateTime> updatedAt,
      Value<String?> trackingNumbers,
      Value<String?> memoVocal,
      Value<bool> deposeSansContact,
      Value<double?> montantCod,
      Value<bool> codPaye,
      Value<String?> notationEmoji,
    });
typedef $$StopsTableUpdateCompanionBuilder =
    StopsCompanion Function({
      Value<int> id,
      Value<int> tourneeId,
      Value<String> adresseBrute,
      Value<String?> adresseNormalisee,
      Value<String> type,
      Value<double?> lat,
      Value<double?> lng,
      Value<int> nbColis,
      Value<String> priorite,
      Value<String?> fenetreDebut,
      Value<String?> fenetreFin,
      Value<int> dureeArretMin,
      Value<String?> notes,
      Value<String?> nomClient,
      Value<String?> telephone,
      Value<String> statutLivraison,
      Value<String?> raisonEchec,
      Value<double?> livreLat,
      Value<double?> livreLng,
      Value<DateTime?> livreLe,
      Value<int?> ordreOptimise,
      Value<bool> positionLocked,
      Value<int?> ordrePriorite,
      Value<String?> preuvePhotoPath,
      Value<int?> coequipierId,
      Value<DateTime> creeLe,
      Value<String?> cloudId,
      Value<String?> cloudPhotoPath,
      Value<DateTime> updatedAt,
      Value<String?> trackingNumbers,
      Value<String?> memoVocal,
      Value<bool> deposeSansContact,
      Value<double?> montantCod,
      Value<bool> codPaye,
      Value<String?> notationEmoji,
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

  static MultiTypedResultKey<$TrackingCodesTable, List<TrackingCode>>
  _trackingCodesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.trackingCodes,
    aliasName: $_aliasNameGenerator(db.stops.id, db.trackingCodes.stopId),
  );

  $$TrackingCodesTableProcessedTableManager get trackingCodesRefs {
    final manager = $$TrackingCodesTableTableManager(
      $_db,
      $_db.trackingCodes,
    ).filter((f) => f.stopId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_trackingCodesRefsTable($_db));
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

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
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

  ColumnFilters<String> get telephone => $composableBuilder(
    column: $table.telephone,
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

  ColumnFilters<bool> get positionLocked => $composableBuilder(
    column: $table.positionLocked,
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

  ColumnFilters<String> get trackingNumbers => $composableBuilder(
    column: $table.trackingNumbers,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memoVocal => $composableBuilder(
    column: $table.memoVocal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deposeSansContact => $composableBuilder(
    column: $table.deposeSansContact,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get montantCod => $composableBuilder(
    column: $table.montantCod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get codPaye => $composableBuilder(
    column: $table.codPaye,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notationEmoji => $composableBuilder(
    column: $table.notationEmoji,
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

  Expression<bool> trackingCodesRefs(
    Expression<bool> Function($$TrackingCodesTableFilterComposer f) f,
  ) {
    final $$TrackingCodesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trackingCodes,
      getReferencedColumn: (t) => t.stopId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrackingCodesTableFilterComposer(
            $db: $db,
            $table: $db.trackingCodes,
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

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
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

  ColumnOrderings<String> get telephone => $composableBuilder(
    column: $table.telephone,
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

  ColumnOrderings<bool> get positionLocked => $composableBuilder(
    column: $table.positionLocked,
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

  ColumnOrderings<String> get trackingNumbers => $composableBuilder(
    column: $table.trackingNumbers,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memoVocal => $composableBuilder(
    column: $table.memoVocal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deposeSansContact => $composableBuilder(
    column: $table.deposeSansContact,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get montantCod => $composableBuilder(
    column: $table.montantCod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get codPaye => $composableBuilder(
    column: $table.codPaye,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notationEmoji => $composableBuilder(
    column: $table.notationEmoji,
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

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

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

  GeneratedColumn<String> get telephone =>
      $composableBuilder(column: $table.telephone, builder: (column) => column);

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

  GeneratedColumn<bool> get positionLocked => $composableBuilder(
    column: $table.positionLocked,
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

  GeneratedColumn<String> get trackingNumbers => $composableBuilder(
    column: $table.trackingNumbers,
    builder: (column) => column,
  );

  GeneratedColumn<String> get memoVocal =>
      $composableBuilder(column: $table.memoVocal, builder: (column) => column);

  GeneratedColumn<bool> get deposeSansContact => $composableBuilder(
    column: $table.deposeSansContact,
    builder: (column) => column,
  );

  GeneratedColumn<double> get montantCod => $composableBuilder(
    column: $table.montantCod,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get codPaye =>
      $composableBuilder(column: $table.codPaye, builder: (column) => column);

  GeneratedColumn<String> get notationEmoji => $composableBuilder(
    column: $table.notationEmoji,
    builder: (column) => column,
  );

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

  Expression<T> trackingCodesRefs<T extends Object>(
    Expression<T> Function($$TrackingCodesTableAnnotationComposer a) f,
  ) {
    final $$TrackingCodesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trackingCodes,
      getReferencedColumn: (t) => t.stopId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrackingCodesTableAnnotationComposer(
            $db: $db,
            $table: $db.trackingCodes,
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
            bool trackingCodesRefs,
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
                Value<String> type = const Value.absent(),
                Value<double?> lat = const Value.absent(),
                Value<double?> lng = const Value.absent(),
                Value<int> nbColis = const Value.absent(),
                Value<String> priorite = const Value.absent(),
                Value<String?> fenetreDebut = const Value.absent(),
                Value<String?> fenetreFin = const Value.absent(),
                Value<int> dureeArretMin = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> nomClient = const Value.absent(),
                Value<String?> telephone = const Value.absent(),
                Value<String> statutLivraison = const Value.absent(),
                Value<String?> raisonEchec = const Value.absent(),
                Value<double?> livreLat = const Value.absent(),
                Value<double?> livreLng = const Value.absent(),
                Value<DateTime?> livreLe = const Value.absent(),
                Value<int?> ordreOptimise = const Value.absent(),
                Value<bool> positionLocked = const Value.absent(),
                Value<int?> ordrePriorite = const Value.absent(),
                Value<String?> preuvePhotoPath = const Value.absent(),
                Value<int?> coequipierId = const Value.absent(),
                Value<DateTime> creeLe = const Value.absent(),
                Value<String?> cloudId = const Value.absent(),
                Value<String?> cloudPhotoPath = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> trackingNumbers = const Value.absent(),
                Value<String?> memoVocal = const Value.absent(),
                Value<bool> deposeSansContact = const Value.absent(),
                Value<double?> montantCod = const Value.absent(),
                Value<bool> codPaye = const Value.absent(),
                Value<String?> notationEmoji = const Value.absent(),
              }) => StopsCompanion(
                id: id,
                tourneeId: tourneeId,
                adresseBrute: adresseBrute,
                adresseNormalisee: adresseNormalisee,
                type: type,
                lat: lat,
                lng: lng,
                nbColis: nbColis,
                priorite: priorite,
                fenetreDebut: fenetreDebut,
                fenetreFin: fenetreFin,
                dureeArretMin: dureeArretMin,
                notes: notes,
                nomClient: nomClient,
                telephone: telephone,
                statutLivraison: statutLivraison,
                raisonEchec: raisonEchec,
                livreLat: livreLat,
                livreLng: livreLng,
                livreLe: livreLe,
                ordreOptimise: ordreOptimise,
                positionLocked: positionLocked,
                ordrePriorite: ordrePriorite,
                preuvePhotoPath: preuvePhotoPath,
                coequipierId: coequipierId,
                creeLe: creeLe,
                cloudId: cloudId,
                cloudPhotoPath: cloudPhotoPath,
                updatedAt: updatedAt,
                trackingNumbers: trackingNumbers,
                memoVocal: memoVocal,
                deposeSansContact: deposeSansContact,
                montantCod: montantCod,
                codPaye: codPaye,
                notationEmoji: notationEmoji,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int tourneeId,
                required String adresseBrute,
                Value<String?> adresseNormalisee = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<double?> lat = const Value.absent(),
                Value<double?> lng = const Value.absent(),
                Value<int> nbColis = const Value.absent(),
                Value<String> priorite = const Value.absent(),
                Value<String?> fenetreDebut = const Value.absent(),
                Value<String?> fenetreFin = const Value.absent(),
                Value<int> dureeArretMin = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> nomClient = const Value.absent(),
                Value<String?> telephone = const Value.absent(),
                Value<String> statutLivraison = const Value.absent(),
                Value<String?> raisonEchec = const Value.absent(),
                Value<double?> livreLat = const Value.absent(),
                Value<double?> livreLng = const Value.absent(),
                Value<DateTime?> livreLe = const Value.absent(),
                Value<int?> ordreOptimise = const Value.absent(),
                Value<bool> positionLocked = const Value.absent(),
                Value<int?> ordrePriorite = const Value.absent(),
                Value<String?> preuvePhotoPath = const Value.absent(),
                Value<int?> coequipierId = const Value.absent(),
                Value<DateTime> creeLe = const Value.absent(),
                Value<String?> cloudId = const Value.absent(),
                Value<String?> cloudPhotoPath = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> trackingNumbers = const Value.absent(),
                Value<String?> memoVocal = const Value.absent(),
                Value<bool> deposeSansContact = const Value.absent(),
                Value<double?> montantCod = const Value.absent(),
                Value<bool> codPaye = const Value.absent(),
                Value<String?> notationEmoji = const Value.absent(),
              }) => StopsCompanion.insert(
                id: id,
                tourneeId: tourneeId,
                adresseBrute: adresseBrute,
                adresseNormalisee: adresseNormalisee,
                type: type,
                lat: lat,
                lng: lng,
                nbColis: nbColis,
                priorite: priorite,
                fenetreDebut: fenetreDebut,
                fenetreFin: fenetreFin,
                dureeArretMin: dureeArretMin,
                notes: notes,
                nomClient: nomClient,
                telephone: telephone,
                statutLivraison: statutLivraison,
                raisonEchec: raisonEchec,
                livreLat: livreLat,
                livreLng: livreLng,
                livreLe: livreLe,
                ordreOptimise: ordreOptimise,
                positionLocked: positionLocked,
                ordrePriorite: ordrePriorite,
                preuvePhotoPath: preuvePhotoPath,
                coequipierId: coequipierId,
                creeLe: creeLe,
                cloudId: cloudId,
                cloudPhotoPath: cloudPhotoPath,
                updatedAt: updatedAt,
                trackingNumbers: trackingNumbers,
                memoVocal: memoVocal,
                deposeSansContact: deposeSansContact,
                montantCod: montantCod,
                codPaye: codPaye,
                notationEmoji: notationEmoji,
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
                trackingCodesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (sheetsRefs) db.sheets,
                    if (stopHistoryRefs) db.stopHistory,
                    if (trackingCodesRefs) db.trackingCodes,
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
                      if (trackingCodesRefs)
                        await $_getPrefetchedData<
                          Stop,
                          $StopsTable,
                          TrackingCode
                        >(
                          currentTable: table,
                          referencedTable: $$StopsTableReferences
                              ._trackingCodesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StopsTableReferences(
                                db,
                                table,
                                p0,
                              ).trackingCodesRefs,
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
        bool trackingCodesRefs,
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
      Value<String?> telephone,
      Value<String?> cloudId,
      Value<DateTime> updatedAt,
      Value<String?> noteStationnement,
      Value<bool> isProblematique,
      Value<bool> photoObligatoire,
      Value<String?> preferencePersonnalisee,
      Value<String?> entrepriseId,
      Value<String?> entrepotId,
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
      Value<String?> telephone,
      Value<String?> cloudId,
      Value<DateTime> updatedAt,
      Value<String?> noteStationnement,
      Value<bool> isProblematique,
      Value<bool> photoObligatoire,
      Value<String?> preferencePersonnalisee,
      Value<String?> entrepriseId,
      Value<String?> entrepotId,
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

  ColumnFilters<String> get telephone => $composableBuilder(
    column: $table.telephone,
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

  ColumnFilters<String> get noteStationnement => $composableBuilder(
    column: $table.noteStationnement,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isProblematique => $composableBuilder(
    column: $table.isProblematique,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get photoObligatoire => $composableBuilder(
    column: $table.photoObligatoire,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get preferencePersonnalisee => $composableBuilder(
    column: $table.preferencePersonnalisee,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entrepriseId => $composableBuilder(
    column: $table.entrepriseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entrepotId => $composableBuilder(
    column: $table.entrepotId,
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

  ColumnOrderings<String> get telephone => $composableBuilder(
    column: $table.telephone,
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

  ColumnOrderings<String> get noteStationnement => $composableBuilder(
    column: $table.noteStationnement,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isProblematique => $composableBuilder(
    column: $table.isProblematique,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get photoObligatoire => $composableBuilder(
    column: $table.photoObligatoire,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get preferencePersonnalisee => $composableBuilder(
    column: $table.preferencePersonnalisee,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entrepriseId => $composableBuilder(
    column: $table.entrepriseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entrepotId => $composableBuilder(
    column: $table.entrepotId,
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

  GeneratedColumn<String> get telephone =>
      $composableBuilder(column: $table.telephone, builder: (column) => column);

  GeneratedColumn<String> get cloudId =>
      $composableBuilder(column: $table.cloudId, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get noteStationnement => $composableBuilder(
    column: $table.noteStationnement,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isProblematique => $composableBuilder(
    column: $table.isProblematique,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get photoObligatoire => $composableBuilder(
    column: $table.photoObligatoire,
    builder: (column) => column,
  );

  GeneratedColumn<String> get preferencePersonnalisee => $composableBuilder(
    column: $table.preferencePersonnalisee,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entrepriseId => $composableBuilder(
    column: $table.entrepriseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entrepotId => $composableBuilder(
    column: $table.entrepotId,
    builder: (column) => column,
  );
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
                Value<String?> telephone = const Value.absent(),
                Value<String?> cloudId = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> noteStationnement = const Value.absent(),
                Value<bool> isProblematique = const Value.absent(),
                Value<bool> photoObligatoire = const Value.absent(),
                Value<String?> preferencePersonnalisee = const Value.absent(),
                Value<String?> entrepriseId = const Value.absent(),
                Value<String?> entrepotId = const Value.absent(),
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
                telephone: telephone,
                cloudId: cloudId,
                updatedAt: updatedAt,
                noteStationnement: noteStationnement,
                isProblematique: isProblematique,
                photoObligatoire: photoObligatoire,
                preferencePersonnalisee: preferencePersonnalisee,
                entrepriseId: entrepriseId,
                entrepotId: entrepotId,
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
                Value<String?> telephone = const Value.absent(),
                Value<String?> cloudId = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> noteStationnement = const Value.absent(),
                Value<bool> isProblematique = const Value.absent(),
                Value<bool> photoObligatoire = const Value.absent(),
                Value<String?> preferencePersonnalisee = const Value.absent(),
                Value<String?> entrepriseId = const Value.absent(),
                Value<String?> entrepotId = const Value.absent(),
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
                telephone: telephone,
                cloudId: cloudId,
                updatedAt: updatedAt,
                noteStationnement: noteStationnement,
                isProblematique: isProblematique,
                photoObligatoire: photoObligatoire,
                preferencePersonnalisee: preferencePersonnalisee,
                entrepriseId: entrepriseId,
                entrepotId: entrepotId,
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
typedef $$FraisTableCreateCompanionBuilder =
    FraisCompanion Function({
      Value<int> id,
      required DateTime date,
      required String type,
      required int montantCentimes,
      required String libelle,
      Value<String?> notes,
      Value<int?> tourneeId,
      Value<String?> photoPath,
      Value<DateTime> creeLe,
      Value<DateTime> updatedAt,
    });
typedef $$FraisTableUpdateCompanionBuilder =
    FraisCompanion Function({
      Value<int> id,
      Value<DateTime> date,
      Value<String> type,
      Value<int> montantCentimes,
      Value<String> libelle,
      Value<String?> notes,
      Value<int?> tourneeId,
      Value<String?> photoPath,
      Value<DateTime> creeLe,
      Value<DateTime> updatedAt,
    });

class $$FraisTableFilterComposer extends Composer<_$AppDatabase, $FraisTable> {
  $$FraisTableFilterComposer({
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

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get montantCentimes => $composableBuilder(
    column: $table.montantCentimes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get libelle => $composableBuilder(
    column: $table.libelle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tourneeId => $composableBuilder(
    column: $table.tourneeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get creeLe => $composableBuilder(
    column: $table.creeLe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FraisTableOrderingComposer
    extends Composer<_$AppDatabase, $FraisTable> {
  $$FraisTableOrderingComposer({
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

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get montantCentimes => $composableBuilder(
    column: $table.montantCentimes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get libelle => $composableBuilder(
    column: $table.libelle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tourneeId => $composableBuilder(
    column: $table.tourneeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get creeLe => $composableBuilder(
    column: $table.creeLe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FraisTableAnnotationComposer
    extends Composer<_$AppDatabase, $FraisTable> {
  $$FraisTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get montantCentimes => $composableBuilder(
    column: $table.montantCentimes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get libelle =>
      $composableBuilder(column: $table.libelle, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get tourneeId =>
      $composableBuilder(column: $table.tourneeId, builder: (column) => column);

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);

  GeneratedColumn<DateTime> get creeLe =>
      $composableBuilder(column: $table.creeLe, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$FraisTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FraisTable,
          Frai,
          $$FraisTableFilterComposer,
          $$FraisTableOrderingComposer,
          $$FraisTableAnnotationComposer,
          $$FraisTableCreateCompanionBuilder,
          $$FraisTableUpdateCompanionBuilder,
          (Frai, BaseReferences<_$AppDatabase, $FraisTable, Frai>),
          Frai,
          PrefetchHooks Function()
        > {
  $$FraisTableTableManager(_$AppDatabase db, $FraisTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FraisTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FraisTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FraisTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> montantCentimes = const Value.absent(),
                Value<String> libelle = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int?> tourneeId = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                Value<DateTime> creeLe = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => FraisCompanion(
                id: id,
                date: date,
                type: type,
                montantCentimes: montantCentimes,
                libelle: libelle,
                notes: notes,
                tourneeId: tourneeId,
                photoPath: photoPath,
                creeLe: creeLe,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime date,
                required String type,
                required int montantCentimes,
                required String libelle,
                Value<String?> notes = const Value.absent(),
                Value<int?> tourneeId = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                Value<DateTime> creeLe = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => FraisCompanion.insert(
                id: id,
                date: date,
                type: type,
                montantCentimes: montantCentimes,
                libelle: libelle,
                notes: notes,
                tourneeId: tourneeId,
                photoPath: photoPath,
                creeLe: creeLe,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FraisTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FraisTable,
      Frai,
      $$FraisTableFilterComposer,
      $$FraisTableOrderingComposer,
      $$FraisTableAnnotationComposer,
      $$FraisTableCreateCompanionBuilder,
      $$FraisTableUpdateCompanionBuilder,
      (Frai, BaseReferences<_$AppDatabase, $FraisTable, Frai>),
      Frai,
      PrefetchHooks Function()
    >;
typedef $$TrackingCodesTableCreateCompanionBuilder =
    TrackingCodesCompanion Function({
      Value<int> id,
      required int stopId,
      required String code,
      Value<DateTime> createdAt,
      Value<bool> cloudPushed,
    });
typedef $$TrackingCodesTableUpdateCompanionBuilder =
    TrackingCodesCompanion Function({
      Value<int> id,
      Value<int> stopId,
      Value<String> code,
      Value<DateTime> createdAt,
      Value<bool> cloudPushed,
    });

final class $$TrackingCodesTableReferences
    extends BaseReferences<_$AppDatabase, $TrackingCodesTable, TrackingCode> {
  $$TrackingCodesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $StopsTable _stopIdTable(_$AppDatabase db) => db.stops.createAlias(
    $_aliasNameGenerator(db.trackingCodes.stopId, db.stops.id),
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

class $$TrackingCodesTableFilterComposer
    extends Composer<_$AppDatabase, $TrackingCodesTable> {
  $$TrackingCodesTableFilterComposer({
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

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get cloudPushed => $composableBuilder(
    column: $table.cloudPushed,
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

class $$TrackingCodesTableOrderingComposer
    extends Composer<_$AppDatabase, $TrackingCodesTable> {
  $$TrackingCodesTableOrderingComposer({
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

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get cloudPushed => $composableBuilder(
    column: $table.cloudPushed,
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

class $$TrackingCodesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrackingCodesTable> {
  $$TrackingCodesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get cloudPushed => $composableBuilder(
    column: $table.cloudPushed,
    builder: (column) => column,
  );

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

class $$TrackingCodesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TrackingCodesTable,
          TrackingCode,
          $$TrackingCodesTableFilterComposer,
          $$TrackingCodesTableOrderingComposer,
          $$TrackingCodesTableAnnotationComposer,
          $$TrackingCodesTableCreateCompanionBuilder,
          $$TrackingCodesTableUpdateCompanionBuilder,
          (TrackingCode, $$TrackingCodesTableReferences),
          TrackingCode,
          PrefetchHooks Function({bool stopId})
        > {
  $$TrackingCodesTableTableManager(_$AppDatabase db, $TrackingCodesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrackingCodesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrackingCodesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrackingCodesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> stopId = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> cloudPushed = const Value.absent(),
              }) => TrackingCodesCompanion(
                id: id,
                stopId: stopId,
                code: code,
                createdAt: createdAt,
                cloudPushed: cloudPushed,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int stopId,
                required String code,
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> cloudPushed = const Value.absent(),
              }) => TrackingCodesCompanion.insert(
                id: id,
                stopId: stopId,
                code: code,
                createdAt: createdAt,
                cloudPushed: cloudPushed,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TrackingCodesTableReferences(db, table, e),
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
                                referencedTable: $$TrackingCodesTableReferences
                                    ._stopIdTable(db),
                                referencedColumn: $$TrackingCodesTableReferences
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

typedef $$TrackingCodesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TrackingCodesTable,
      TrackingCode,
      $$TrackingCodesTableFilterComposer,
      $$TrackingCodesTableOrderingComposer,
      $$TrackingCodesTableAnnotationComposer,
      $$TrackingCodesTableCreateCompanionBuilder,
      $$TrackingCodesTableUpdateCompanionBuilder,
      (TrackingCode, $$TrackingCodesTableReferences),
      TrackingCode,
      PrefetchHooks Function({bool stopId})
    >;
typedef $$TourneeRecurrencesTableCreateCompanionBuilder =
    TourneeRecurrencesCompanion Function({
      Value<int> id,
      required int templateId,
      required String frequence,
      Value<int?> jourSemaine,
      Value<int?> jourMois,
      Value<bool> actif,
      Value<DateTime?> derniereGenerationLe,
      Value<DateTime> creeLe,
    });
typedef $$TourneeRecurrencesTableUpdateCompanionBuilder =
    TourneeRecurrencesCompanion Function({
      Value<int> id,
      Value<int> templateId,
      Value<String> frequence,
      Value<int?> jourSemaine,
      Value<int?> jourMois,
      Value<bool> actif,
      Value<DateTime?> derniereGenerationLe,
      Value<DateTime> creeLe,
    });

final class $$TourneeRecurrencesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $TourneeRecurrencesTable,
          TourneeRecurrence
        > {
  $$TourneeRecurrencesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TourneesTable _templateIdTable(_$AppDatabase db) =>
      db.tournees.createAlias(
        $_aliasNameGenerator(db.tourneeRecurrences.templateId, db.tournees.id),
      );

  $$TourneesTableProcessedTableManager get templateId {
    final $_column = $_itemColumn<int>('template_id')!;

    final manager = $$TourneesTableTableManager(
      $_db,
      $_db.tournees,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_templateIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TourneeRecurrencesTableFilterComposer
    extends Composer<_$AppDatabase, $TourneeRecurrencesTable> {
  $$TourneeRecurrencesTableFilterComposer({
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

  ColumnFilters<String> get frequence => $composableBuilder(
    column: $table.frequence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get jourSemaine => $composableBuilder(
    column: $table.jourSemaine,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get jourMois => $composableBuilder(
    column: $table.jourMois,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get actif => $composableBuilder(
    column: $table.actif,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get derniereGenerationLe => $composableBuilder(
    column: $table.derniereGenerationLe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get creeLe => $composableBuilder(
    column: $table.creeLe,
    builder: (column) => ColumnFilters(column),
  );

  $$TourneesTableFilterComposer get templateId {
    final $$TourneesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
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
}

class $$TourneeRecurrencesTableOrderingComposer
    extends Composer<_$AppDatabase, $TourneeRecurrencesTable> {
  $$TourneeRecurrencesTableOrderingComposer({
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

  ColumnOrderings<String> get frequence => $composableBuilder(
    column: $table.frequence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get jourSemaine => $composableBuilder(
    column: $table.jourSemaine,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get jourMois => $composableBuilder(
    column: $table.jourMois,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get actif => $composableBuilder(
    column: $table.actif,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get derniereGenerationLe => $composableBuilder(
    column: $table.derniereGenerationLe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get creeLe => $composableBuilder(
    column: $table.creeLe,
    builder: (column) => ColumnOrderings(column),
  );

  $$TourneesTableOrderingComposer get templateId {
    final $$TourneesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
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

class $$TourneeRecurrencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TourneeRecurrencesTable> {
  $$TourneeRecurrencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get frequence =>
      $composableBuilder(column: $table.frequence, builder: (column) => column);

  GeneratedColumn<int> get jourSemaine => $composableBuilder(
    column: $table.jourSemaine,
    builder: (column) => column,
  );

  GeneratedColumn<int> get jourMois =>
      $composableBuilder(column: $table.jourMois, builder: (column) => column);

  GeneratedColumn<bool> get actif =>
      $composableBuilder(column: $table.actif, builder: (column) => column);

  GeneratedColumn<DateTime> get derniereGenerationLe => $composableBuilder(
    column: $table.derniereGenerationLe,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get creeLe =>
      $composableBuilder(column: $table.creeLe, builder: (column) => column);

  $$TourneesTableAnnotationComposer get templateId {
    final $$TourneesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
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
}

class $$TourneeRecurrencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TourneeRecurrencesTable,
          TourneeRecurrence,
          $$TourneeRecurrencesTableFilterComposer,
          $$TourneeRecurrencesTableOrderingComposer,
          $$TourneeRecurrencesTableAnnotationComposer,
          $$TourneeRecurrencesTableCreateCompanionBuilder,
          $$TourneeRecurrencesTableUpdateCompanionBuilder,
          (TourneeRecurrence, $$TourneeRecurrencesTableReferences),
          TourneeRecurrence,
          PrefetchHooks Function({bool templateId})
        > {
  $$TourneeRecurrencesTableTableManager(
    _$AppDatabase db,
    $TourneeRecurrencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TourneeRecurrencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TourneeRecurrencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TourneeRecurrencesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> templateId = const Value.absent(),
                Value<String> frequence = const Value.absent(),
                Value<int?> jourSemaine = const Value.absent(),
                Value<int?> jourMois = const Value.absent(),
                Value<bool> actif = const Value.absent(),
                Value<DateTime?> derniereGenerationLe = const Value.absent(),
                Value<DateTime> creeLe = const Value.absent(),
              }) => TourneeRecurrencesCompanion(
                id: id,
                templateId: templateId,
                frequence: frequence,
                jourSemaine: jourSemaine,
                jourMois: jourMois,
                actif: actif,
                derniereGenerationLe: derniereGenerationLe,
                creeLe: creeLe,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int templateId,
                required String frequence,
                Value<int?> jourSemaine = const Value.absent(),
                Value<int?> jourMois = const Value.absent(),
                Value<bool> actif = const Value.absent(),
                Value<DateTime?> derniereGenerationLe = const Value.absent(),
                Value<DateTime> creeLe = const Value.absent(),
              }) => TourneeRecurrencesCompanion.insert(
                id: id,
                templateId: templateId,
                frequence: frequence,
                jourSemaine: jourSemaine,
                jourMois: jourMois,
                actif: actif,
                derniereGenerationLe: derniereGenerationLe,
                creeLe: creeLe,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TourneeRecurrencesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({templateId = false}) {
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
                    if (templateId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.templateId,
                                referencedTable:
                                    $$TourneeRecurrencesTableReferences
                                        ._templateIdTable(db),
                                referencedColumn:
                                    $$TourneeRecurrencesTableReferences
                                        ._templateIdTable(db)
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

typedef $$TourneeRecurrencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TourneeRecurrencesTable,
      TourneeRecurrence,
      $$TourneeRecurrencesTableFilterComposer,
      $$TourneeRecurrencesTableOrderingComposer,
      $$TourneeRecurrencesTableAnnotationComposer,
      $$TourneeRecurrencesTableCreateCompanionBuilder,
      $$TourneeRecurrencesTableUpdateCompanionBuilder,
      (TourneeRecurrence, $$TourneeRecurrencesTableReferences),
      TourneeRecurrence,
      PrefetchHooks Function({bool templateId})
    >;
typedef $$WorkSessionsTableCreateCompanionBuilder =
    WorkSessionsCompanion Function({
      Value<int> id,
      required DateTime startedAt,
      Value<DateTime?> endedAt,
      Value<String?> notes,
      Value<DateTime> creeLe,
    });
typedef $$WorkSessionsTableUpdateCompanionBuilder =
    WorkSessionsCompanion Function({
      Value<int> id,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
      Value<String?> notes,
      Value<DateTime> creeLe,
    });

class $$WorkSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $WorkSessionsTable> {
  $$WorkSessionsTableFilterComposer({
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

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get creeLe => $composableBuilder(
    column: $table.creeLe,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WorkSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkSessionsTable> {
  $$WorkSessionsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get creeLe => $composableBuilder(
    column: $table.creeLe,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkSessionsTable> {
  $$WorkSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get creeLe =>
      $composableBuilder(column: $table.creeLe, builder: (column) => column);
}

class $$WorkSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkSessionsTable,
          WorkSession,
          $$WorkSessionsTableFilterComposer,
          $$WorkSessionsTableOrderingComposer,
          $$WorkSessionsTableAnnotationComposer,
          $$WorkSessionsTableCreateCompanionBuilder,
          $$WorkSessionsTableUpdateCompanionBuilder,
          (
            WorkSession,
            BaseReferences<_$AppDatabase, $WorkSessionsTable, WorkSession>,
          ),
          WorkSession,
          PrefetchHooks Function()
        > {
  $$WorkSessionsTableTableManager(_$AppDatabase db, $WorkSessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> creeLe = const Value.absent(),
              }) => WorkSessionsCompanion(
                id: id,
                startedAt: startedAt,
                endedAt: endedAt,
                notes: notes,
                creeLe: creeLe,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> creeLe = const Value.absent(),
              }) => WorkSessionsCompanion.insert(
                id: id,
                startedAt: startedAt,
                endedAt: endedAt,
                notes: notes,
                creeLe: creeLe,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WorkSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkSessionsTable,
      WorkSession,
      $$WorkSessionsTableFilterComposer,
      $$WorkSessionsTableOrderingComposer,
      $$WorkSessionsTableAnnotationComposer,
      $$WorkSessionsTableCreateCompanionBuilder,
      $$WorkSessionsTableUpdateCompanionBuilder,
      (
        WorkSession,
        BaseReferences<_$AppDatabase, $WorkSessionsTable, WorkSession>,
      ),
      WorkSession,
      PrefetchHooks Function()
    >;
typedef $$EntreprisesTableCreateCompanionBuilder =
    EntreprisesCompanion Function({
      required String cloudId,
      required String nom,
      Value<String?> siret,
      required String createdBy,
      Value<DateTime> creeLe,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$EntreprisesTableUpdateCompanionBuilder =
    EntreprisesCompanion Function({
      Value<String> cloudId,
      Value<String> nom,
      Value<String?> siret,
      Value<String> createdBy,
      Value<DateTime> creeLe,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$EntreprisesTableReferences
    extends BaseReferences<_$AppDatabase, $EntreprisesTable, Entreprise> {
  $$EntreprisesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$EntrepotsTable, List<Entrepot>>
  _entrepotsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.entrepots,
    aliasName: $_aliasNameGenerator(
      db.entreprises.cloudId,
      db.entrepots.entrepriseId,
    ),
  );

  $$EntrepotsTableProcessedTableManager get entrepotsRefs {
    final manager = $$EntrepotsTableTableManager($_db, $_db.entrepots).filter(
      (f) =>
          f.entrepriseId.cloudId.sqlEquals($_itemColumn<String>('cloud_id')!),
    );

    final cache = $_typedResult.readTableOrNull(_entrepotsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EntrepriseUsersTable, List<EntrepriseUser>>
  _entrepriseUsersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.entrepriseUsers,
    aliasName: $_aliasNameGenerator(
      db.entreprises.cloudId,
      db.entrepriseUsers.entrepriseId,
    ),
  );

  $$EntrepriseUsersTableProcessedTableManager get entrepriseUsersRefs {
    final manager =
        $$EntrepriseUsersTableTableManager($_db, $_db.entrepriseUsers).filter(
          (f) => f.entrepriseId.cloudId.sqlEquals(
            $_itemColumn<String>('cloud_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(
      _entrepriseUsersRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $EntrepriseInvitationsTable,
    List<EntrepriseInvitation>
  >
  _entrepriseInvitationsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.entrepriseInvitations,
        aliasName: $_aliasNameGenerator(
          db.entreprises.cloudId,
          db.entrepriseInvitations.entrepriseId,
        ),
      );

  $$EntrepriseInvitationsTableProcessedTableManager
  get entrepriseInvitationsRefs {
    final manager =
        $$EntrepriseInvitationsTableTableManager(
          $_db,
          $_db.entrepriseInvitations,
        ).filter(
          (f) => f.entrepriseId.cloudId.sqlEquals(
            $_itemColumn<String>('cloud_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(
      _entrepriseInvitationsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$EntreprisesTableFilterComposer
    extends Composer<_$AppDatabase, $EntreprisesTable> {
  $$EntreprisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get cloudId => $composableBuilder(
    column: $table.cloudId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nom => $composableBuilder(
    column: $table.nom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get siret => $composableBuilder(
    column: $table.siret,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get creeLe => $composableBuilder(
    column: $table.creeLe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> entrepotsRefs(
    Expression<bool> Function($$EntrepotsTableFilterComposer f) f,
  ) {
    final $$EntrepotsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cloudId,
      referencedTable: $db.entrepots,
      getReferencedColumn: (t) => t.entrepriseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntrepotsTableFilterComposer(
            $db: $db,
            $table: $db.entrepots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> entrepriseUsersRefs(
    Expression<bool> Function($$EntrepriseUsersTableFilterComposer f) f,
  ) {
    final $$EntrepriseUsersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cloudId,
      referencedTable: $db.entrepriseUsers,
      getReferencedColumn: (t) => t.entrepriseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntrepriseUsersTableFilterComposer(
            $db: $db,
            $table: $db.entrepriseUsers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> entrepriseInvitationsRefs(
    Expression<bool> Function($$EntrepriseInvitationsTableFilterComposer f) f,
  ) {
    final $$EntrepriseInvitationsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.cloudId,
          referencedTable: $db.entrepriseInvitations,
          getReferencedColumn: (t) => t.entrepriseId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$EntrepriseInvitationsTableFilterComposer(
                $db: $db,
                $table: $db.entrepriseInvitations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$EntreprisesTableOrderingComposer
    extends Composer<_$AppDatabase, $EntreprisesTable> {
  $$EntreprisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get cloudId => $composableBuilder(
    column: $table.cloudId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nom => $composableBuilder(
    column: $table.nom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get siret => $composableBuilder(
    column: $table.siret,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get creeLe => $composableBuilder(
    column: $table.creeLe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EntreprisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EntreprisesTable> {
  $$EntreprisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get cloudId =>
      $composableBuilder(column: $table.cloudId, builder: (column) => column);

  GeneratedColumn<String> get nom =>
      $composableBuilder(column: $table.nom, builder: (column) => column);

  GeneratedColumn<String> get siret =>
      $composableBuilder(column: $table.siret, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<DateTime> get creeLe =>
      $composableBuilder(column: $table.creeLe, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> entrepotsRefs<T extends Object>(
    Expression<T> Function($$EntrepotsTableAnnotationComposer a) f,
  ) {
    final $$EntrepotsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cloudId,
      referencedTable: $db.entrepots,
      getReferencedColumn: (t) => t.entrepriseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntrepotsTableAnnotationComposer(
            $db: $db,
            $table: $db.entrepots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> entrepriseUsersRefs<T extends Object>(
    Expression<T> Function($$EntrepriseUsersTableAnnotationComposer a) f,
  ) {
    final $$EntrepriseUsersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cloudId,
      referencedTable: $db.entrepriseUsers,
      getReferencedColumn: (t) => t.entrepriseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntrepriseUsersTableAnnotationComposer(
            $db: $db,
            $table: $db.entrepriseUsers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> entrepriseInvitationsRefs<T extends Object>(
    Expression<T> Function($$EntrepriseInvitationsTableAnnotationComposer a) f,
  ) {
    final $$EntrepriseInvitationsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.cloudId,
          referencedTable: $db.entrepriseInvitations,
          getReferencedColumn: (t) => t.entrepriseId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$EntrepriseInvitationsTableAnnotationComposer(
                $db: $db,
                $table: $db.entrepriseInvitations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$EntreprisesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EntreprisesTable,
          Entreprise,
          $$EntreprisesTableFilterComposer,
          $$EntreprisesTableOrderingComposer,
          $$EntreprisesTableAnnotationComposer,
          $$EntreprisesTableCreateCompanionBuilder,
          $$EntreprisesTableUpdateCompanionBuilder,
          (Entreprise, $$EntreprisesTableReferences),
          Entreprise,
          PrefetchHooks Function({
            bool entrepotsRefs,
            bool entrepriseUsersRefs,
            bool entrepriseInvitationsRefs,
          })
        > {
  $$EntreprisesTableTableManager(_$AppDatabase db, $EntreprisesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntreprisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntreprisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntreprisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> cloudId = const Value.absent(),
                Value<String> nom = const Value.absent(),
                Value<String?> siret = const Value.absent(),
                Value<String> createdBy = const Value.absent(),
                Value<DateTime> creeLe = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntreprisesCompanion(
                cloudId: cloudId,
                nom: nom,
                siret: siret,
                createdBy: createdBy,
                creeLe: creeLe,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String cloudId,
                required String nom,
                Value<String?> siret = const Value.absent(),
                required String createdBy,
                Value<DateTime> creeLe = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntreprisesCompanion.insert(
                cloudId: cloudId,
                nom: nom,
                siret: siret,
                createdBy: createdBy,
                creeLe: creeLe,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$EntreprisesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                entrepotsRefs = false,
                entrepriseUsersRefs = false,
                entrepriseInvitationsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (entrepotsRefs) db.entrepots,
                    if (entrepriseUsersRefs) db.entrepriseUsers,
                    if (entrepriseInvitationsRefs) db.entrepriseInvitations,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (entrepotsRefs)
                        await $_getPrefetchedData<
                          Entreprise,
                          $EntreprisesTable,
                          Entrepot
                        >(
                          currentTable: table,
                          referencedTable: $$EntreprisesTableReferences
                              ._entrepotsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EntreprisesTableReferences(
                                db,
                                table,
                                p0,
                              ).entrepotsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.entrepriseId == item.cloudId,
                              ),
                          typedResults: items,
                        ),
                      if (entrepriseUsersRefs)
                        await $_getPrefetchedData<
                          Entreprise,
                          $EntreprisesTable,
                          EntrepriseUser
                        >(
                          currentTable: table,
                          referencedTable: $$EntreprisesTableReferences
                              ._entrepriseUsersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EntreprisesTableReferences(
                                db,
                                table,
                                p0,
                              ).entrepriseUsersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.entrepriseId == item.cloudId,
                              ),
                          typedResults: items,
                        ),
                      if (entrepriseInvitationsRefs)
                        await $_getPrefetchedData<
                          Entreprise,
                          $EntreprisesTable,
                          EntrepriseInvitation
                        >(
                          currentTable: table,
                          referencedTable: $$EntreprisesTableReferences
                              ._entrepriseInvitationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EntreprisesTableReferences(
                                db,
                                table,
                                p0,
                              ).entrepriseInvitationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.entrepriseId == item.cloudId,
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

typedef $$EntreprisesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EntreprisesTable,
      Entreprise,
      $$EntreprisesTableFilterComposer,
      $$EntreprisesTableOrderingComposer,
      $$EntreprisesTableAnnotationComposer,
      $$EntreprisesTableCreateCompanionBuilder,
      $$EntreprisesTableUpdateCompanionBuilder,
      (Entreprise, $$EntreprisesTableReferences),
      Entreprise,
      PrefetchHooks Function({
        bool entrepotsRefs,
        bool entrepriseUsersRefs,
        bool entrepriseInvitationsRefs,
      })
    >;
typedef $$EntrepotsTableCreateCompanionBuilder =
    EntrepotsCompanion Function({
      required String cloudId,
      required String entrepriseId,
      required String nom,
      Value<String?> adresse,
      Value<double?> lat,
      Value<double?> lng,
      Value<DateTime> creeLe,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$EntrepotsTableUpdateCompanionBuilder =
    EntrepotsCompanion Function({
      Value<String> cloudId,
      Value<String> entrepriseId,
      Value<String> nom,
      Value<String?> adresse,
      Value<double?> lat,
      Value<double?> lng,
      Value<DateTime> creeLe,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$EntrepotsTableReferences
    extends BaseReferences<_$AppDatabase, $EntrepotsTable, Entrepot> {
  $$EntrepotsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EntreprisesTable _entrepriseIdTable(_$AppDatabase db) =>
      db.entreprises.createAlias(
        $_aliasNameGenerator(db.entrepots.entrepriseId, db.entreprises.cloudId),
      );

  $$EntreprisesTableProcessedTableManager get entrepriseId {
    final $_column = $_itemColumn<String>('entreprise_id')!;

    final manager = $$EntreprisesTableTableManager(
      $_db,
      $_db.entreprises,
    ).filter((f) => f.cloudId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_entrepriseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$EntrepotUsersTable, List<EntrepotUser>>
  _entrepotUsersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.entrepotUsers,
    aliasName: $_aliasNameGenerator(
      db.entrepots.cloudId,
      db.entrepotUsers.entrepotId,
    ),
  );

  $$EntrepotUsersTableProcessedTableManager get entrepotUsersRefs {
    final manager = $$EntrepotUsersTableTableManager($_db, $_db.entrepotUsers)
        .filter(
          (f) =>
              f.entrepotId.cloudId.sqlEquals($_itemColumn<String>('cloud_id')!),
        );

    final cache = $_typedResult.readTableOrNull(_entrepotUsersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $EntrepriseInvitationsTable,
    List<EntrepriseInvitation>
  >
  _entrepriseInvitationsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.entrepriseInvitations,
        aliasName: $_aliasNameGenerator(
          db.entrepots.cloudId,
          db.entrepriseInvitations.entrepotId,
        ),
      );

  $$EntrepriseInvitationsTableProcessedTableManager
  get entrepriseInvitationsRefs {
    final manager =
        $$EntrepriseInvitationsTableTableManager(
          $_db,
          $_db.entrepriseInvitations,
        ).filter(
          (f) =>
              f.entrepotId.cloudId.sqlEquals($_itemColumn<String>('cloud_id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _entrepriseInvitationsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$EntrepotsTableFilterComposer
    extends Composer<_$AppDatabase, $EntrepotsTable> {
  $$EntrepotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get cloudId => $composableBuilder(
    column: $table.cloudId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nom => $composableBuilder(
    column: $table.nom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get adresse => $composableBuilder(
    column: $table.adresse,
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

  ColumnFilters<DateTime> get creeLe => $composableBuilder(
    column: $table.creeLe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$EntreprisesTableFilterComposer get entrepriseId {
    final $$EntreprisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entrepriseId,
      referencedTable: $db.entreprises,
      getReferencedColumn: (t) => t.cloudId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntreprisesTableFilterComposer(
            $db: $db,
            $table: $db.entreprises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> entrepotUsersRefs(
    Expression<bool> Function($$EntrepotUsersTableFilterComposer f) f,
  ) {
    final $$EntrepotUsersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cloudId,
      referencedTable: $db.entrepotUsers,
      getReferencedColumn: (t) => t.entrepotId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntrepotUsersTableFilterComposer(
            $db: $db,
            $table: $db.entrepotUsers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> entrepriseInvitationsRefs(
    Expression<bool> Function($$EntrepriseInvitationsTableFilterComposer f) f,
  ) {
    final $$EntrepriseInvitationsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.cloudId,
          referencedTable: $db.entrepriseInvitations,
          getReferencedColumn: (t) => t.entrepotId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$EntrepriseInvitationsTableFilterComposer(
                $db: $db,
                $table: $db.entrepriseInvitations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$EntrepotsTableOrderingComposer
    extends Composer<_$AppDatabase, $EntrepotsTable> {
  $$EntrepotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get cloudId => $composableBuilder(
    column: $table.cloudId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nom => $composableBuilder(
    column: $table.nom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get adresse => $composableBuilder(
    column: $table.adresse,
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

  ColumnOrderings<DateTime> get creeLe => $composableBuilder(
    column: $table.creeLe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$EntreprisesTableOrderingComposer get entrepriseId {
    final $$EntreprisesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entrepriseId,
      referencedTable: $db.entreprises,
      getReferencedColumn: (t) => t.cloudId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntreprisesTableOrderingComposer(
            $db: $db,
            $table: $db.entreprises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntrepotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EntrepotsTable> {
  $$EntrepotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get cloudId =>
      $composableBuilder(column: $table.cloudId, builder: (column) => column);

  GeneratedColumn<String> get nom =>
      $composableBuilder(column: $table.nom, builder: (column) => column);

  GeneratedColumn<String> get adresse =>
      $composableBuilder(column: $table.adresse, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lng =>
      $composableBuilder(column: $table.lng, builder: (column) => column);

  GeneratedColumn<DateTime> get creeLe =>
      $composableBuilder(column: $table.creeLe, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$EntreprisesTableAnnotationComposer get entrepriseId {
    final $$EntreprisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entrepriseId,
      referencedTable: $db.entreprises,
      getReferencedColumn: (t) => t.cloudId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntreprisesTableAnnotationComposer(
            $db: $db,
            $table: $db.entreprises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> entrepotUsersRefs<T extends Object>(
    Expression<T> Function($$EntrepotUsersTableAnnotationComposer a) f,
  ) {
    final $$EntrepotUsersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cloudId,
      referencedTable: $db.entrepotUsers,
      getReferencedColumn: (t) => t.entrepotId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntrepotUsersTableAnnotationComposer(
            $db: $db,
            $table: $db.entrepotUsers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> entrepriseInvitationsRefs<T extends Object>(
    Expression<T> Function($$EntrepriseInvitationsTableAnnotationComposer a) f,
  ) {
    final $$EntrepriseInvitationsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.cloudId,
          referencedTable: $db.entrepriseInvitations,
          getReferencedColumn: (t) => t.entrepotId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$EntrepriseInvitationsTableAnnotationComposer(
                $db: $db,
                $table: $db.entrepriseInvitations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$EntrepotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EntrepotsTable,
          Entrepot,
          $$EntrepotsTableFilterComposer,
          $$EntrepotsTableOrderingComposer,
          $$EntrepotsTableAnnotationComposer,
          $$EntrepotsTableCreateCompanionBuilder,
          $$EntrepotsTableUpdateCompanionBuilder,
          (Entrepot, $$EntrepotsTableReferences),
          Entrepot,
          PrefetchHooks Function({
            bool entrepriseId,
            bool entrepotUsersRefs,
            bool entrepriseInvitationsRefs,
          })
        > {
  $$EntrepotsTableTableManager(_$AppDatabase db, $EntrepotsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntrepotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntrepotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntrepotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> cloudId = const Value.absent(),
                Value<String> entrepriseId = const Value.absent(),
                Value<String> nom = const Value.absent(),
                Value<String?> adresse = const Value.absent(),
                Value<double?> lat = const Value.absent(),
                Value<double?> lng = const Value.absent(),
                Value<DateTime> creeLe = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntrepotsCompanion(
                cloudId: cloudId,
                entrepriseId: entrepriseId,
                nom: nom,
                adresse: adresse,
                lat: lat,
                lng: lng,
                creeLe: creeLe,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String cloudId,
                required String entrepriseId,
                required String nom,
                Value<String?> adresse = const Value.absent(),
                Value<double?> lat = const Value.absent(),
                Value<double?> lng = const Value.absent(),
                Value<DateTime> creeLe = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntrepotsCompanion.insert(
                cloudId: cloudId,
                entrepriseId: entrepriseId,
                nom: nom,
                adresse: adresse,
                lat: lat,
                lng: lng,
                creeLe: creeLe,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$EntrepotsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                entrepriseId = false,
                entrepotUsersRefs = false,
                entrepriseInvitationsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (entrepotUsersRefs) db.entrepotUsers,
                    if (entrepriseInvitationsRefs) db.entrepriseInvitations,
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
                        if (entrepriseId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.entrepriseId,
                                    referencedTable: $$EntrepotsTableReferences
                                        ._entrepriseIdTable(db),
                                    referencedColumn: $$EntrepotsTableReferences
                                        ._entrepriseIdTable(db)
                                        .cloudId,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (entrepotUsersRefs)
                        await $_getPrefetchedData<
                          Entrepot,
                          $EntrepotsTable,
                          EntrepotUser
                        >(
                          currentTable: table,
                          referencedTable: $$EntrepotsTableReferences
                              ._entrepotUsersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EntrepotsTableReferences(
                                db,
                                table,
                                p0,
                              ).entrepotUsersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.entrepotId == item.cloudId,
                              ),
                          typedResults: items,
                        ),
                      if (entrepriseInvitationsRefs)
                        await $_getPrefetchedData<
                          Entrepot,
                          $EntrepotsTable,
                          EntrepriseInvitation
                        >(
                          currentTable: table,
                          referencedTable: $$EntrepotsTableReferences
                              ._entrepriseInvitationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EntrepotsTableReferences(
                                db,
                                table,
                                p0,
                              ).entrepriseInvitationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.entrepotId == item.cloudId,
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

typedef $$EntrepotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EntrepotsTable,
      Entrepot,
      $$EntrepotsTableFilterComposer,
      $$EntrepotsTableOrderingComposer,
      $$EntrepotsTableAnnotationComposer,
      $$EntrepotsTableCreateCompanionBuilder,
      $$EntrepotsTableUpdateCompanionBuilder,
      (Entrepot, $$EntrepotsTableReferences),
      Entrepot,
      PrefetchHooks Function({
        bool entrepriseId,
        bool entrepotUsersRefs,
        bool entrepriseInvitationsRefs,
      })
    >;
typedef $$EntrepriseUsersTableCreateCompanionBuilder =
    EntrepriseUsersCompanion Function({
      required String cloudId,
      required String entrepriseId,
      required String userId,
      required String role,
      Value<String> statut,
      Value<DateTime?> revokedAt,
      Value<DateTime> creeLe,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$EntrepriseUsersTableUpdateCompanionBuilder =
    EntrepriseUsersCompanion Function({
      Value<String> cloudId,
      Value<String> entrepriseId,
      Value<String> userId,
      Value<String> role,
      Value<String> statut,
      Value<DateTime?> revokedAt,
      Value<DateTime> creeLe,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$EntrepriseUsersTableReferences
    extends
        BaseReferences<_$AppDatabase, $EntrepriseUsersTable, EntrepriseUser> {
  $$EntrepriseUsersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $EntreprisesTable _entrepriseIdTable(_$AppDatabase db) =>
      db.entreprises.createAlias(
        $_aliasNameGenerator(
          db.entrepriseUsers.entrepriseId,
          db.entreprises.cloudId,
        ),
      );

  $$EntreprisesTableProcessedTableManager get entrepriseId {
    final $_column = $_itemColumn<String>('entreprise_id')!;

    final manager = $$EntreprisesTableTableManager(
      $_db,
      $_db.entreprises,
    ).filter((f) => f.cloudId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_entrepriseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EntrepriseUsersTableFilterComposer
    extends Composer<_$AppDatabase, $EntrepriseUsersTable> {
  $$EntrepriseUsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get cloudId => $composableBuilder(
    column: $table.cloudId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get statut => $composableBuilder(
    column: $table.statut,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get revokedAt => $composableBuilder(
    column: $table.revokedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get creeLe => $composableBuilder(
    column: $table.creeLe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$EntreprisesTableFilterComposer get entrepriseId {
    final $$EntreprisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entrepriseId,
      referencedTable: $db.entreprises,
      getReferencedColumn: (t) => t.cloudId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntreprisesTableFilterComposer(
            $db: $db,
            $table: $db.entreprises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntrepriseUsersTableOrderingComposer
    extends Composer<_$AppDatabase, $EntrepriseUsersTable> {
  $$EntrepriseUsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get cloudId => $composableBuilder(
    column: $table.cloudId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get statut => $composableBuilder(
    column: $table.statut,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get revokedAt => $composableBuilder(
    column: $table.revokedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get creeLe => $composableBuilder(
    column: $table.creeLe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$EntreprisesTableOrderingComposer get entrepriseId {
    final $$EntreprisesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entrepriseId,
      referencedTable: $db.entreprises,
      getReferencedColumn: (t) => t.cloudId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntreprisesTableOrderingComposer(
            $db: $db,
            $table: $db.entreprises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntrepriseUsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $EntrepriseUsersTable> {
  $$EntrepriseUsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get cloudId =>
      $composableBuilder(column: $table.cloudId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get statut =>
      $composableBuilder(column: $table.statut, builder: (column) => column);

  GeneratedColumn<DateTime> get revokedAt =>
      $composableBuilder(column: $table.revokedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get creeLe =>
      $composableBuilder(column: $table.creeLe, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$EntreprisesTableAnnotationComposer get entrepriseId {
    final $$EntreprisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entrepriseId,
      referencedTable: $db.entreprises,
      getReferencedColumn: (t) => t.cloudId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntreprisesTableAnnotationComposer(
            $db: $db,
            $table: $db.entreprises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntrepriseUsersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EntrepriseUsersTable,
          EntrepriseUser,
          $$EntrepriseUsersTableFilterComposer,
          $$EntrepriseUsersTableOrderingComposer,
          $$EntrepriseUsersTableAnnotationComposer,
          $$EntrepriseUsersTableCreateCompanionBuilder,
          $$EntrepriseUsersTableUpdateCompanionBuilder,
          (EntrepriseUser, $$EntrepriseUsersTableReferences),
          EntrepriseUser,
          PrefetchHooks Function({bool entrepriseId})
        > {
  $$EntrepriseUsersTableTableManager(
    _$AppDatabase db,
    $EntrepriseUsersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntrepriseUsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntrepriseUsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntrepriseUsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> cloudId = const Value.absent(),
                Value<String> entrepriseId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> statut = const Value.absent(),
                Value<DateTime?> revokedAt = const Value.absent(),
                Value<DateTime> creeLe = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntrepriseUsersCompanion(
                cloudId: cloudId,
                entrepriseId: entrepriseId,
                userId: userId,
                role: role,
                statut: statut,
                revokedAt: revokedAt,
                creeLe: creeLe,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String cloudId,
                required String entrepriseId,
                required String userId,
                required String role,
                Value<String> statut = const Value.absent(),
                Value<DateTime?> revokedAt = const Value.absent(),
                Value<DateTime> creeLe = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntrepriseUsersCompanion.insert(
                cloudId: cloudId,
                entrepriseId: entrepriseId,
                userId: userId,
                role: role,
                statut: statut,
                revokedAt: revokedAt,
                creeLe: creeLe,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$EntrepriseUsersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({entrepriseId = false}) {
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
                    if (entrepriseId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.entrepriseId,
                                referencedTable:
                                    $$EntrepriseUsersTableReferences
                                        ._entrepriseIdTable(db),
                                referencedColumn:
                                    $$EntrepriseUsersTableReferences
                                        ._entrepriseIdTable(db)
                                        .cloudId,
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

typedef $$EntrepriseUsersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EntrepriseUsersTable,
      EntrepriseUser,
      $$EntrepriseUsersTableFilterComposer,
      $$EntrepriseUsersTableOrderingComposer,
      $$EntrepriseUsersTableAnnotationComposer,
      $$EntrepriseUsersTableCreateCompanionBuilder,
      $$EntrepriseUsersTableUpdateCompanionBuilder,
      (EntrepriseUser, $$EntrepriseUsersTableReferences),
      EntrepriseUser,
      PrefetchHooks Function({bool entrepriseId})
    >;
typedef $$EntrepotUsersTableCreateCompanionBuilder =
    EntrepotUsersCompanion Function({
      required String cloudId,
      required String entrepotId,
      required String userId,
      required String role,
      Value<String> statut,
      Value<DateTime?> revokedAt,
      Value<DateTime> creeLe,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$EntrepotUsersTableUpdateCompanionBuilder =
    EntrepotUsersCompanion Function({
      Value<String> cloudId,
      Value<String> entrepotId,
      Value<String> userId,
      Value<String> role,
      Value<String> statut,
      Value<DateTime?> revokedAt,
      Value<DateTime> creeLe,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$EntrepotUsersTableReferences
    extends BaseReferences<_$AppDatabase, $EntrepotUsersTable, EntrepotUser> {
  $$EntrepotUsersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $EntrepotsTable _entrepotIdTable(_$AppDatabase db) =>
      db.entrepots.createAlias(
        $_aliasNameGenerator(db.entrepotUsers.entrepotId, db.entrepots.cloudId),
      );

  $$EntrepotsTableProcessedTableManager get entrepotId {
    final $_column = $_itemColumn<String>('entrepot_id')!;

    final manager = $$EntrepotsTableTableManager(
      $_db,
      $_db.entrepots,
    ).filter((f) => f.cloudId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_entrepotIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EntrepotUsersTableFilterComposer
    extends Composer<_$AppDatabase, $EntrepotUsersTable> {
  $$EntrepotUsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get cloudId => $composableBuilder(
    column: $table.cloudId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get statut => $composableBuilder(
    column: $table.statut,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get revokedAt => $composableBuilder(
    column: $table.revokedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get creeLe => $composableBuilder(
    column: $table.creeLe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$EntrepotsTableFilterComposer get entrepotId {
    final $$EntrepotsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entrepotId,
      referencedTable: $db.entrepots,
      getReferencedColumn: (t) => t.cloudId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntrepotsTableFilterComposer(
            $db: $db,
            $table: $db.entrepots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntrepotUsersTableOrderingComposer
    extends Composer<_$AppDatabase, $EntrepotUsersTable> {
  $$EntrepotUsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get cloudId => $composableBuilder(
    column: $table.cloudId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get statut => $composableBuilder(
    column: $table.statut,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get revokedAt => $composableBuilder(
    column: $table.revokedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get creeLe => $composableBuilder(
    column: $table.creeLe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$EntrepotsTableOrderingComposer get entrepotId {
    final $$EntrepotsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entrepotId,
      referencedTable: $db.entrepots,
      getReferencedColumn: (t) => t.cloudId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntrepotsTableOrderingComposer(
            $db: $db,
            $table: $db.entrepots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntrepotUsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $EntrepotUsersTable> {
  $$EntrepotUsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get cloudId =>
      $composableBuilder(column: $table.cloudId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get statut =>
      $composableBuilder(column: $table.statut, builder: (column) => column);

  GeneratedColumn<DateTime> get revokedAt =>
      $composableBuilder(column: $table.revokedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get creeLe =>
      $composableBuilder(column: $table.creeLe, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$EntrepotsTableAnnotationComposer get entrepotId {
    final $$EntrepotsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entrepotId,
      referencedTable: $db.entrepots,
      getReferencedColumn: (t) => t.cloudId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntrepotsTableAnnotationComposer(
            $db: $db,
            $table: $db.entrepots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntrepotUsersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EntrepotUsersTable,
          EntrepotUser,
          $$EntrepotUsersTableFilterComposer,
          $$EntrepotUsersTableOrderingComposer,
          $$EntrepotUsersTableAnnotationComposer,
          $$EntrepotUsersTableCreateCompanionBuilder,
          $$EntrepotUsersTableUpdateCompanionBuilder,
          (EntrepotUser, $$EntrepotUsersTableReferences),
          EntrepotUser,
          PrefetchHooks Function({bool entrepotId})
        > {
  $$EntrepotUsersTableTableManager(_$AppDatabase db, $EntrepotUsersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntrepotUsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntrepotUsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntrepotUsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> cloudId = const Value.absent(),
                Value<String> entrepotId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> statut = const Value.absent(),
                Value<DateTime?> revokedAt = const Value.absent(),
                Value<DateTime> creeLe = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntrepotUsersCompanion(
                cloudId: cloudId,
                entrepotId: entrepotId,
                userId: userId,
                role: role,
                statut: statut,
                revokedAt: revokedAt,
                creeLe: creeLe,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String cloudId,
                required String entrepotId,
                required String userId,
                required String role,
                Value<String> statut = const Value.absent(),
                Value<DateTime?> revokedAt = const Value.absent(),
                Value<DateTime> creeLe = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntrepotUsersCompanion.insert(
                cloudId: cloudId,
                entrepotId: entrepotId,
                userId: userId,
                role: role,
                statut: statut,
                revokedAt: revokedAt,
                creeLe: creeLe,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$EntrepotUsersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({entrepotId = false}) {
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
                    if (entrepotId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.entrepotId,
                                referencedTable: $$EntrepotUsersTableReferences
                                    ._entrepotIdTable(db),
                                referencedColumn: $$EntrepotUsersTableReferences
                                    ._entrepotIdTable(db)
                                    .cloudId,
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

typedef $$EntrepotUsersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EntrepotUsersTable,
      EntrepotUser,
      $$EntrepotUsersTableFilterComposer,
      $$EntrepotUsersTableOrderingComposer,
      $$EntrepotUsersTableAnnotationComposer,
      $$EntrepotUsersTableCreateCompanionBuilder,
      $$EntrepotUsersTableUpdateCompanionBuilder,
      (EntrepotUser, $$EntrepotUsersTableReferences),
      EntrepotUser,
      PrefetchHooks Function({bool entrepotId})
    >;
typedef $$EntrepriseInvitationsTableCreateCompanionBuilder =
    EntrepriseInvitationsCompanion Function({
      required String cloudId,
      required String entrepriseId,
      Value<String?> entrepotId,
      required String email,
      required String roleTarget,
      required String invitedBy,
      Value<String> statut,
      required DateTime expiresAt,
      Value<DateTime> creeLe,
      Value<int> rowid,
    });
typedef $$EntrepriseInvitationsTableUpdateCompanionBuilder =
    EntrepriseInvitationsCompanion Function({
      Value<String> cloudId,
      Value<String> entrepriseId,
      Value<String?> entrepotId,
      Value<String> email,
      Value<String> roleTarget,
      Value<String> invitedBy,
      Value<String> statut,
      Value<DateTime> expiresAt,
      Value<DateTime> creeLe,
      Value<int> rowid,
    });

final class $$EntrepriseInvitationsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $EntrepriseInvitationsTable,
          EntrepriseInvitation
        > {
  $$EntrepriseInvitationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $EntreprisesTable _entrepriseIdTable(_$AppDatabase db) =>
      db.entreprises.createAlias(
        $_aliasNameGenerator(
          db.entrepriseInvitations.entrepriseId,
          db.entreprises.cloudId,
        ),
      );

  $$EntreprisesTableProcessedTableManager get entrepriseId {
    final $_column = $_itemColumn<String>('entreprise_id')!;

    final manager = $$EntreprisesTableTableManager(
      $_db,
      $_db.entreprises,
    ).filter((f) => f.cloudId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_entrepriseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $EntrepotsTable _entrepotIdTable(_$AppDatabase db) =>
      db.entrepots.createAlias(
        $_aliasNameGenerator(
          db.entrepriseInvitations.entrepotId,
          db.entrepots.cloudId,
        ),
      );

  $$EntrepotsTableProcessedTableManager? get entrepotId {
    final $_column = $_itemColumn<String>('entrepot_id');
    if ($_column == null) return null;
    final manager = $$EntrepotsTableTableManager(
      $_db,
      $_db.entrepots,
    ).filter((f) => f.cloudId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_entrepotIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EntrepriseInvitationsTableFilterComposer
    extends Composer<_$AppDatabase, $EntrepriseInvitationsTable> {
  $$EntrepriseInvitationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get cloudId => $composableBuilder(
    column: $table.cloudId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roleTarget => $composableBuilder(
    column: $table.roleTarget,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get invitedBy => $composableBuilder(
    column: $table.invitedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get statut => $composableBuilder(
    column: $table.statut,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get creeLe => $composableBuilder(
    column: $table.creeLe,
    builder: (column) => ColumnFilters(column),
  );

  $$EntreprisesTableFilterComposer get entrepriseId {
    final $$EntreprisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entrepriseId,
      referencedTable: $db.entreprises,
      getReferencedColumn: (t) => t.cloudId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntreprisesTableFilterComposer(
            $db: $db,
            $table: $db.entreprises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EntrepotsTableFilterComposer get entrepotId {
    final $$EntrepotsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entrepotId,
      referencedTable: $db.entrepots,
      getReferencedColumn: (t) => t.cloudId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntrepotsTableFilterComposer(
            $db: $db,
            $table: $db.entrepots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntrepriseInvitationsTableOrderingComposer
    extends Composer<_$AppDatabase, $EntrepriseInvitationsTable> {
  $$EntrepriseInvitationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get cloudId => $composableBuilder(
    column: $table.cloudId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roleTarget => $composableBuilder(
    column: $table.roleTarget,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get invitedBy => $composableBuilder(
    column: $table.invitedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get statut => $composableBuilder(
    column: $table.statut,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get creeLe => $composableBuilder(
    column: $table.creeLe,
    builder: (column) => ColumnOrderings(column),
  );

  $$EntreprisesTableOrderingComposer get entrepriseId {
    final $$EntreprisesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entrepriseId,
      referencedTable: $db.entreprises,
      getReferencedColumn: (t) => t.cloudId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntreprisesTableOrderingComposer(
            $db: $db,
            $table: $db.entreprises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EntrepotsTableOrderingComposer get entrepotId {
    final $$EntrepotsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entrepotId,
      referencedTable: $db.entrepots,
      getReferencedColumn: (t) => t.cloudId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntrepotsTableOrderingComposer(
            $db: $db,
            $table: $db.entrepots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntrepriseInvitationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EntrepriseInvitationsTable> {
  $$EntrepriseInvitationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get cloudId =>
      $composableBuilder(column: $table.cloudId, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get roleTarget => $composableBuilder(
    column: $table.roleTarget,
    builder: (column) => column,
  );

  GeneratedColumn<String> get invitedBy =>
      $composableBuilder(column: $table.invitedBy, builder: (column) => column);

  GeneratedColumn<String> get statut =>
      $composableBuilder(column: $table.statut, builder: (column) => column);

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<DateTime> get creeLe =>
      $composableBuilder(column: $table.creeLe, builder: (column) => column);

  $$EntreprisesTableAnnotationComposer get entrepriseId {
    final $$EntreprisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entrepriseId,
      referencedTable: $db.entreprises,
      getReferencedColumn: (t) => t.cloudId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntreprisesTableAnnotationComposer(
            $db: $db,
            $table: $db.entreprises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EntrepotsTableAnnotationComposer get entrepotId {
    final $$EntrepotsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entrepotId,
      referencedTable: $db.entrepots,
      getReferencedColumn: (t) => t.cloudId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntrepotsTableAnnotationComposer(
            $db: $db,
            $table: $db.entrepots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntrepriseInvitationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EntrepriseInvitationsTable,
          EntrepriseInvitation,
          $$EntrepriseInvitationsTableFilterComposer,
          $$EntrepriseInvitationsTableOrderingComposer,
          $$EntrepriseInvitationsTableAnnotationComposer,
          $$EntrepriseInvitationsTableCreateCompanionBuilder,
          $$EntrepriseInvitationsTableUpdateCompanionBuilder,
          (EntrepriseInvitation, $$EntrepriseInvitationsTableReferences),
          EntrepriseInvitation,
          PrefetchHooks Function({bool entrepriseId, bool entrepotId})
        > {
  $$EntrepriseInvitationsTableTableManager(
    _$AppDatabase db,
    $EntrepriseInvitationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntrepriseInvitationsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$EntrepriseInvitationsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$EntrepriseInvitationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> cloudId = const Value.absent(),
                Value<String> entrepriseId = const Value.absent(),
                Value<String?> entrepotId = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> roleTarget = const Value.absent(),
                Value<String> invitedBy = const Value.absent(),
                Value<String> statut = const Value.absent(),
                Value<DateTime> expiresAt = const Value.absent(),
                Value<DateTime> creeLe = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntrepriseInvitationsCompanion(
                cloudId: cloudId,
                entrepriseId: entrepriseId,
                entrepotId: entrepotId,
                email: email,
                roleTarget: roleTarget,
                invitedBy: invitedBy,
                statut: statut,
                expiresAt: expiresAt,
                creeLe: creeLe,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String cloudId,
                required String entrepriseId,
                Value<String?> entrepotId = const Value.absent(),
                required String email,
                required String roleTarget,
                required String invitedBy,
                Value<String> statut = const Value.absent(),
                required DateTime expiresAt,
                Value<DateTime> creeLe = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntrepriseInvitationsCompanion.insert(
                cloudId: cloudId,
                entrepriseId: entrepriseId,
                entrepotId: entrepotId,
                email: email,
                roleTarget: roleTarget,
                invitedBy: invitedBy,
                statut: statut,
                expiresAt: expiresAt,
                creeLe: creeLe,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$EntrepriseInvitationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({entrepriseId = false, entrepotId = false}) {
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
                    if (entrepriseId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.entrepriseId,
                                referencedTable:
                                    $$EntrepriseInvitationsTableReferences
                                        ._entrepriseIdTable(db),
                                referencedColumn:
                                    $$EntrepriseInvitationsTableReferences
                                        ._entrepriseIdTable(db)
                                        .cloudId,
                              )
                              as T;
                    }
                    if (entrepotId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.entrepotId,
                                referencedTable:
                                    $$EntrepriseInvitationsTableReferences
                                        ._entrepotIdTable(db),
                                referencedColumn:
                                    $$EntrepriseInvitationsTableReferences
                                        ._entrepotIdTable(db)
                                        .cloudId,
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

typedef $$EntrepriseInvitationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EntrepriseInvitationsTable,
      EntrepriseInvitation,
      $$EntrepriseInvitationsTableFilterComposer,
      $$EntrepriseInvitationsTableOrderingComposer,
      $$EntrepriseInvitationsTableAnnotationComposer,
      $$EntrepriseInvitationsTableCreateCompanionBuilder,
      $$EntrepriseInvitationsTableUpdateCompanionBuilder,
      (EntrepriseInvitation, $$EntrepriseInvitationsTableReferences),
      EntrepriseInvitation,
      PrefetchHooks Function({bool entrepriseId, bool entrepotId})
    >;
typedef $$SavedDestinationNotesPersoTableCreateCompanionBuilder =
    SavedDestinationNotesPersoCompanion Function({
      required String cloudId,
      required String savedDestinationId,
      required String userId,
      Value<String?> notes,
      Value<DateTime> creeLe,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$SavedDestinationNotesPersoTableUpdateCompanionBuilder =
    SavedDestinationNotesPersoCompanion Function({
      Value<String> cloudId,
      Value<String> savedDestinationId,
      Value<String> userId,
      Value<String?> notes,
      Value<DateTime> creeLe,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$SavedDestinationNotesPersoTableFilterComposer
    extends Composer<_$AppDatabase, $SavedDestinationNotesPersoTable> {
  $$SavedDestinationNotesPersoTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get cloudId => $composableBuilder(
    column: $table.cloudId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get savedDestinationId => $composableBuilder(
    column: $table.savedDestinationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get creeLe => $composableBuilder(
    column: $table.creeLe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SavedDestinationNotesPersoTableOrderingComposer
    extends Composer<_$AppDatabase, $SavedDestinationNotesPersoTable> {
  $$SavedDestinationNotesPersoTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get cloudId => $composableBuilder(
    column: $table.cloudId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get savedDestinationId => $composableBuilder(
    column: $table.savedDestinationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get creeLe => $composableBuilder(
    column: $table.creeLe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SavedDestinationNotesPersoTableAnnotationComposer
    extends Composer<_$AppDatabase, $SavedDestinationNotesPersoTable> {
  $$SavedDestinationNotesPersoTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get cloudId =>
      $composableBuilder(column: $table.cloudId, builder: (column) => column);

  GeneratedColumn<String> get savedDestinationId => $composableBuilder(
    column: $table.savedDestinationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get creeLe =>
      $composableBuilder(column: $table.creeLe, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SavedDestinationNotesPersoTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SavedDestinationNotesPersoTable,
          SavedDestinationNotesPersoData,
          $$SavedDestinationNotesPersoTableFilterComposer,
          $$SavedDestinationNotesPersoTableOrderingComposer,
          $$SavedDestinationNotesPersoTableAnnotationComposer,
          $$SavedDestinationNotesPersoTableCreateCompanionBuilder,
          $$SavedDestinationNotesPersoTableUpdateCompanionBuilder,
          (
            SavedDestinationNotesPersoData,
            BaseReferences<
              _$AppDatabase,
              $SavedDestinationNotesPersoTable,
              SavedDestinationNotesPersoData
            >,
          ),
          SavedDestinationNotesPersoData,
          PrefetchHooks Function()
        > {
  $$SavedDestinationNotesPersoTableTableManager(
    _$AppDatabase db,
    $SavedDestinationNotesPersoTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavedDestinationNotesPersoTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$SavedDestinationNotesPersoTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SavedDestinationNotesPersoTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> cloudId = const Value.absent(),
                Value<String> savedDestinationId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> creeLe = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavedDestinationNotesPersoCompanion(
                cloudId: cloudId,
                savedDestinationId: savedDestinationId,
                userId: userId,
                notes: notes,
                creeLe: creeLe,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String cloudId,
                required String savedDestinationId,
                required String userId,
                Value<String?> notes = const Value.absent(),
                Value<DateTime> creeLe = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavedDestinationNotesPersoCompanion.insert(
                cloudId: cloudId,
                savedDestinationId: savedDestinationId,
                userId: userId,
                notes: notes,
                creeLe: creeLe,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SavedDestinationNotesPersoTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SavedDestinationNotesPersoTable,
      SavedDestinationNotesPersoData,
      $$SavedDestinationNotesPersoTableFilterComposer,
      $$SavedDestinationNotesPersoTableOrderingComposer,
      $$SavedDestinationNotesPersoTableAnnotationComposer,
      $$SavedDestinationNotesPersoTableCreateCompanionBuilder,
      $$SavedDestinationNotesPersoTableUpdateCompanionBuilder,
      (
        SavedDestinationNotesPersoData,
        BaseReferences<
          _$AppDatabase,
          $SavedDestinationNotesPersoTable,
          SavedDestinationNotesPersoData
        >,
      ),
      SavedDestinationNotesPersoData,
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
  $$FraisTableTableManager get frais =>
      $$FraisTableTableManager(_db, _db.frais);
  $$TrackingCodesTableTableManager get trackingCodes =>
      $$TrackingCodesTableTableManager(_db, _db.trackingCodes);
  $$TourneeRecurrencesTableTableManager get tourneeRecurrences =>
      $$TourneeRecurrencesTableTableManager(_db, _db.tourneeRecurrences);
  $$WorkSessionsTableTableManager get workSessions =>
      $$WorkSessionsTableTableManager(_db, _db.workSessions);
  $$EntreprisesTableTableManager get entreprises =>
      $$EntreprisesTableTableManager(_db, _db.entreprises);
  $$EntrepotsTableTableManager get entrepots =>
      $$EntrepotsTableTableManager(_db, _db.entrepots);
  $$EntrepriseUsersTableTableManager get entrepriseUsers =>
      $$EntrepriseUsersTableTableManager(_db, _db.entrepriseUsers);
  $$EntrepotUsersTableTableManager get entrepotUsers =>
      $$EntrepotUsersTableTableManager(_db, _db.entrepotUsers);
  $$EntrepriseInvitationsTableTableManager get entrepriseInvitations =>
      $$EntrepriseInvitationsTableTableManager(_db, _db.entrepriseInvitations);
  $$SavedDestinationNotesPersoTableTableManager
  get savedDestinationNotesPerso =>
      $$SavedDestinationNotesPersoTableTableManager(
        _db,
        _db.savedDestinationNotesPerso,
      );
}
