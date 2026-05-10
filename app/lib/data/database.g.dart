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
    creeLe,
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
      creeLe: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cree_le'],
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
  final DateTime creeLe;
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
    required this.creeLe,
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
    map['cree_le'] = Variable<DateTime>(creeLe);
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
      creeLe: Value(creeLe),
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
      creeLe: serializer.fromJson<DateTime>(json['creeLe']),
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
      'creeLe': serializer.toJson<DateTime>(creeLe),
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
    DateTime? creeLe,
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
    creeLe: creeLe ?? this.creeLe,
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
      creeLe: data.creeLe.present ? data.creeLe.value : this.creeLe,
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
          ..write('creeLe: $creeLe')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
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
    creeLe,
  );
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
          other.creeLe == this.creeLe);
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
  final Value<DateTime> creeLe;
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
    this.creeLe = const Value.absent(),
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
    this.creeLe = const Value.absent(),
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
    Expression<DateTime>? creeLe,
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
      if (creeLe != null) 'cree_le': creeLe,
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
    Value<DateTime>? creeLe,
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
      creeLe: creeLe ?? this.creeLe,
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
    if (creeLe.present) {
      map['cree_le'] = Variable<DateTime>(creeLe.value);
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
          ..write('creeLe: $creeLe')
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
    ordreOptimise,
    creeLe,
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
    if (data.containsKey('ordre_optimise')) {
      context.handle(
        _ordreOptimiseMeta,
        ordreOptimise.isAcceptableOrUnknown(
          data['ordre_optimise']!,
          _ordreOptimiseMeta,
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
      ordreOptimise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ordre_optimise'],
      ),
      creeLe: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cree_le'],
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
  final int? ordreOptimise;
  final DateTime creeLe;
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
    this.ordreOptimise,
    required this.creeLe,
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
    if (!nullToAbsent || ordreOptimise != null) {
      map['ordre_optimise'] = Variable<int>(ordreOptimise);
    }
    map['cree_le'] = Variable<DateTime>(creeLe);
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
      ordreOptimise: ordreOptimise == null && nullToAbsent
          ? const Value.absent()
          : Value(ordreOptimise),
      creeLe: Value(creeLe),
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
      ordreOptimise: serializer.fromJson<int?>(json['ordreOptimise']),
      creeLe: serializer.fromJson<DateTime>(json['creeLe']),
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
      'ordreOptimise': serializer.toJson<int?>(ordreOptimise),
      'creeLe': serializer.toJson<DateTime>(creeLe),
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
    Value<int?> ordreOptimise = const Value.absent(),
    DateTime? creeLe,
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
    ordreOptimise: ordreOptimise.present
        ? ordreOptimise.value
        : this.ordreOptimise,
    creeLe: creeLe ?? this.creeLe,
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
      ordreOptimise: data.ordreOptimise.present
          ? data.ordreOptimise.value
          : this.ordreOptimise,
      creeLe: data.creeLe.present ? data.creeLe.value : this.creeLe,
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
          ..write('ordreOptimise: $ordreOptimise, ')
          ..write('creeLe: $creeLe')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
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
    ordreOptimise,
    creeLe,
  );
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
          other.ordreOptimise == this.ordreOptimise &&
          other.creeLe == this.creeLe);
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
  final Value<int?> ordreOptimise;
  final Value<DateTime> creeLe;
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
    this.ordreOptimise = const Value.absent(),
    this.creeLe = const Value.absent(),
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
    this.ordreOptimise = const Value.absent(),
    this.creeLe = const Value.absent(),
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
    Expression<int>? ordreOptimise,
    Expression<DateTime>? creeLe,
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
      if (ordreOptimise != null) 'ordre_optimise': ordreOptimise,
      if (creeLe != null) 'cree_le': creeLe,
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
    Value<int?>? ordreOptimise,
    Value<DateTime>? creeLe,
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
      ordreOptimise: ordreOptimise ?? this.ordreOptimise,
      creeLe: creeLe ?? this.creeLe,
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
    if (ordreOptimise.present) {
      map['ordre_optimise'] = Variable<int>(ordreOptimise.value);
    }
    if (creeLe.present) {
      map['cree_le'] = Variable<DateTime>(creeLe.value);
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
          ..write('ordreOptimise: $ordreOptimise, ')
          ..write('creeLe: $creeLe')
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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TourneesTable tournees = $TourneesTable(this);
  late final $StopsTable stops = $StopsTable(this);
  late final $ParametresTable parametres = $ParametresTable(this);
  late final $SheetsTable sheets = $SheetsTable(this);
  late final $GeocodeCacheTable geocodeCache = $GeocodeCacheTable(this);
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
      Value<DateTime> creeLe,
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
      Value<DateTime> creeLe,
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

  ColumnFilters<DateTime> get creeLe => $composableBuilder(
    column: $table.creeLe,
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

  ColumnOrderings<DateTime> get creeLe => $composableBuilder(
    column: $table.creeLe,
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

  GeneratedColumn<DateTime> get creeLe =>
      $composableBuilder(column: $table.creeLe, builder: (column) => column);

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
                Value<DateTime> creeLe = const Value.absent(),
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
                creeLe: creeLe,
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
                Value<DateTime> creeLe = const Value.absent(),
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
                creeLe: creeLe,
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
      Value<int?> ordreOptimise,
      Value<DateTime> creeLe,
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
      Value<int?> ordreOptimise,
      Value<DateTime> creeLe,
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

  ColumnFilters<int> get ordreOptimise => $composableBuilder(
    column: $table.ordreOptimise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get creeLe => $composableBuilder(
    column: $table.creeLe,
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

  ColumnOrderings<int> get ordreOptimise => $composableBuilder(
    column: $table.ordreOptimise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get creeLe => $composableBuilder(
    column: $table.creeLe,
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

  GeneratedColumn<int> get ordreOptimise => $composableBuilder(
    column: $table.ordreOptimise,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get creeLe =>
      $composableBuilder(column: $table.creeLe, builder: (column) => column);

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
          PrefetchHooks Function({bool tourneeId, bool sheetsRefs})
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
                Value<int?> ordreOptimise = const Value.absent(),
                Value<DateTime> creeLe = const Value.absent(),
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
                ordreOptimise: ordreOptimise,
                creeLe: creeLe,
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
                Value<int?> ordreOptimise = const Value.absent(),
                Value<DateTime> creeLe = const Value.absent(),
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
                ordreOptimise: ordreOptimise,
                creeLe: creeLe,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$StopsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({tourneeId = false, sheetsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (sheetsRefs) db.sheets],
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
                      referencedTable: $$StopsTableReferences._sheetsRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$StopsTableReferences(db, table, p0).sheetsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.stopId == item.id),
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
      PrefetchHooks Function({bool tourneeId, bool sheetsRefs})
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
}
