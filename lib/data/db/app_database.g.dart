// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $OsmWaysTable extends OsmWays with TableInfo<$OsmWaysTable, OsmWay> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OsmWaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _highwayMeta =
      const VerificationMeta('highway');
  @override
  late final GeneratedColumn<String> highway = GeneratedColumn<String>(
      'highway', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sacScaleMeta =
      const VerificationMeta('sacScale');
  @override
  late final GeneratedColumn<String> sacScale = GeneratedColumn<String>(
      'sac_scale', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _trailVisibilityMeta =
      const VerificationMeta('trailVisibility');
  @override
  late final GeneratedColumn<String> trailVisibility = GeneratedColumn<String>(
      'trail_visibility', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _surfaceMeta =
      const VerificationMeta('surface');
  @override
  late final GeneratedColumn<String> surface = GeneratedColumn<String>(
      'surface', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _informalMeta =
      const VerificationMeta('informal');
  @override
  late final GeneratedColumn<bool> informal = GeneratedColumn<bool>(
      'informal', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("informal" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _tagsJsonMeta =
      const VerificationMeta('tagsJson');
  @override
  late final GeneratedColumn<String> tagsJson = GeneratedColumn<String>(
      'tags_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _geomJsonMeta =
      const VerificationMeta('geomJson');
  @override
  late final GeneratedColumn<String> geomJson = GeneratedColumn<String>(
      'geom_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nodeIdsJsonMeta =
      const VerificationMeta('nodeIdsJson');
  @override
  late final GeneratedColumn<String> nodeIdsJson = GeneratedColumn<String>(
      'node_ids_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _firstNodeIdMeta =
      const VerificationMeta('firstNodeId');
  @override
  late final GeneratedColumn<int> firstNodeId = GeneratedColumn<int>(
      'first_node_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _lastNodeIdMeta =
      const VerificationMeta('lastNodeId');
  @override
  late final GeneratedColumn<int> lastNodeId = GeneratedColumn<int>(
      'last_node_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _lengthMMeta =
      const VerificationMeta('lengthM');
  @override
  late final GeneratedColumn<double> lengthM = GeneratedColumn<double>(
      'length_m', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _minLatMeta = const VerificationMeta('minLat');
  @override
  late final GeneratedColumn<double> minLat = GeneratedColumn<double>(
      'min_lat', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _minLonMeta = const VerificationMeta('minLon');
  @override
  late final GeneratedColumn<double> minLon = GeneratedColumn<double>(
      'min_lon', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _maxLatMeta = const VerificationMeta('maxLat');
  @override
  late final GeneratedColumn<double> maxLat = GeneratedColumn<double>(
      'max_lat', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _maxLonMeta = const VerificationMeta('maxLon');
  @override
  late final GeneratedColumn<double> maxLon = GeneratedColumn<double>(
      'max_lon', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _usfsNameMeta =
      const VerificationMeta('usfsName');
  @override
  late final GeneratedColumn<String> usfsName = GeneratedColumn<String>(
      'usfs_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _usfsNumberMeta =
      const VerificationMeta('usfsNumber');
  @override
  late final GeneratedColumn<String> usfsNumber = GeneratedColumn<String>(
      'usfs_number', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        highway,
        sacScale,
        trailVisibility,
        surface,
        informal,
        tagsJson,
        geomJson,
        nodeIdsJson,
        firstNodeId,
        lastNodeId,
        lengthM,
        minLat,
        minLon,
        maxLat,
        maxLon,
        usfsName,
        usfsNumber
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'osm_ways';
  @override
  VerificationContext validateIntegrity(Insertable<OsmWay> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    if (data.containsKey('highway')) {
      context.handle(_highwayMeta,
          highway.isAcceptableOrUnknown(data['highway']!, _highwayMeta));
    } else if (isInserting) {
      context.missing(_highwayMeta);
    }
    if (data.containsKey('sac_scale')) {
      context.handle(_sacScaleMeta,
          sacScale.isAcceptableOrUnknown(data['sac_scale']!, _sacScaleMeta));
    }
    if (data.containsKey('trail_visibility')) {
      context.handle(
          _trailVisibilityMeta,
          trailVisibility.isAcceptableOrUnknown(
              data['trail_visibility']!, _trailVisibilityMeta));
    }
    if (data.containsKey('surface')) {
      context.handle(_surfaceMeta,
          surface.isAcceptableOrUnknown(data['surface']!, _surfaceMeta));
    }
    if (data.containsKey('informal')) {
      context.handle(_informalMeta,
          informal.isAcceptableOrUnknown(data['informal']!, _informalMeta));
    }
    if (data.containsKey('tags_json')) {
      context.handle(_tagsJsonMeta,
          tagsJson.isAcceptableOrUnknown(data['tags_json']!, _tagsJsonMeta));
    } else if (isInserting) {
      context.missing(_tagsJsonMeta);
    }
    if (data.containsKey('geom_json')) {
      context.handle(_geomJsonMeta,
          geomJson.isAcceptableOrUnknown(data['geom_json']!, _geomJsonMeta));
    } else if (isInserting) {
      context.missing(_geomJsonMeta);
    }
    if (data.containsKey('node_ids_json')) {
      context.handle(
          _nodeIdsJsonMeta,
          nodeIdsJson.isAcceptableOrUnknown(
              data['node_ids_json']!, _nodeIdsJsonMeta));
    }
    if (data.containsKey('first_node_id')) {
      context.handle(
          _firstNodeIdMeta,
          firstNodeId.isAcceptableOrUnknown(
              data['first_node_id']!, _firstNodeIdMeta));
    } else if (isInserting) {
      context.missing(_firstNodeIdMeta);
    }
    if (data.containsKey('last_node_id')) {
      context.handle(
          _lastNodeIdMeta,
          lastNodeId.isAcceptableOrUnknown(
              data['last_node_id']!, _lastNodeIdMeta));
    } else if (isInserting) {
      context.missing(_lastNodeIdMeta);
    }
    if (data.containsKey('length_m')) {
      context.handle(_lengthMMeta,
          lengthM.isAcceptableOrUnknown(data['length_m']!, _lengthMMeta));
    } else if (isInserting) {
      context.missing(_lengthMMeta);
    }
    if (data.containsKey('min_lat')) {
      context.handle(_minLatMeta,
          minLat.isAcceptableOrUnknown(data['min_lat']!, _minLatMeta));
    } else if (isInserting) {
      context.missing(_minLatMeta);
    }
    if (data.containsKey('min_lon')) {
      context.handle(_minLonMeta,
          minLon.isAcceptableOrUnknown(data['min_lon']!, _minLonMeta));
    } else if (isInserting) {
      context.missing(_minLonMeta);
    }
    if (data.containsKey('max_lat')) {
      context.handle(_maxLatMeta,
          maxLat.isAcceptableOrUnknown(data['max_lat']!, _maxLatMeta));
    } else if (isInserting) {
      context.missing(_maxLatMeta);
    }
    if (data.containsKey('max_lon')) {
      context.handle(_maxLonMeta,
          maxLon.isAcceptableOrUnknown(data['max_lon']!, _maxLonMeta));
    } else if (isInserting) {
      context.missing(_maxLonMeta);
    }
    if (data.containsKey('usfs_name')) {
      context.handle(_usfsNameMeta,
          usfsName.isAcceptableOrUnknown(data['usfs_name']!, _usfsNameMeta));
    }
    if (data.containsKey('usfs_number')) {
      context.handle(
          _usfsNumberMeta,
          usfsNumber.isAcceptableOrUnknown(
              data['usfs_number']!, _usfsNumberMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OsmWay map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OsmWay(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name']),
      highway: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}highway'])!,
      sacScale: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sac_scale']),
      trailVisibility: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}trail_visibility']),
      surface: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}surface']),
      informal: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}informal'])!,
      tagsJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tags_json'])!,
      geomJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}geom_json'])!,
      nodeIdsJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}node_ids_json'])!,
      firstNodeId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}first_node_id'])!,
      lastNodeId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_node_id'])!,
      lengthM: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}length_m'])!,
      minLat: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}min_lat'])!,
      minLon: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}min_lon'])!,
      maxLat: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}max_lat'])!,
      maxLon: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}max_lon'])!,
      usfsName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}usfs_name']),
      usfsNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}usfs_number']),
    );
  }

  @override
  $OsmWaysTable createAlias(String alias) {
    return $OsmWaysTable(attachedDatabase, alias);
  }
}

class OsmWay extends DataClass implements Insertable<OsmWay> {
  final int id;
  final String? name;
  final String highway;
  final String? sacScale;
  final String? trailVisibility;
  final String? surface;
  final bool informal;
  final String tagsJson;
  final String geomJson;
  final String nodeIdsJson;
  final int firstNodeId;
  final int lastNodeId;
  final double lengthM;
  final double minLat;
  final double minLon;
  final double maxLat;
  final double maxLon;
  final String? usfsName;
  final String? usfsNumber;
  const OsmWay(
      {required this.id,
      this.name,
      required this.highway,
      this.sacScale,
      this.trailVisibility,
      this.surface,
      required this.informal,
      required this.tagsJson,
      required this.geomJson,
      required this.nodeIdsJson,
      required this.firstNodeId,
      required this.lastNodeId,
      required this.lengthM,
      required this.minLat,
      required this.minLon,
      required this.maxLat,
      required this.maxLon,
      this.usfsName,
      this.usfsNumber});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    map['highway'] = Variable<String>(highway);
    if (!nullToAbsent || sacScale != null) {
      map['sac_scale'] = Variable<String>(sacScale);
    }
    if (!nullToAbsent || trailVisibility != null) {
      map['trail_visibility'] = Variable<String>(trailVisibility);
    }
    if (!nullToAbsent || surface != null) {
      map['surface'] = Variable<String>(surface);
    }
    map['informal'] = Variable<bool>(informal);
    map['tags_json'] = Variable<String>(tagsJson);
    map['geom_json'] = Variable<String>(geomJson);
    map['node_ids_json'] = Variable<String>(nodeIdsJson);
    map['first_node_id'] = Variable<int>(firstNodeId);
    map['last_node_id'] = Variable<int>(lastNodeId);
    map['length_m'] = Variable<double>(lengthM);
    map['min_lat'] = Variable<double>(minLat);
    map['min_lon'] = Variable<double>(minLon);
    map['max_lat'] = Variable<double>(maxLat);
    map['max_lon'] = Variable<double>(maxLon);
    if (!nullToAbsent || usfsName != null) {
      map['usfs_name'] = Variable<String>(usfsName);
    }
    if (!nullToAbsent || usfsNumber != null) {
      map['usfs_number'] = Variable<String>(usfsNumber);
    }
    return map;
  }

  OsmWaysCompanion toCompanion(bool nullToAbsent) {
    return OsmWaysCompanion(
      id: Value(id),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      highway: Value(highway),
      sacScale: sacScale == null && nullToAbsent
          ? const Value.absent()
          : Value(sacScale),
      trailVisibility: trailVisibility == null && nullToAbsent
          ? const Value.absent()
          : Value(trailVisibility),
      surface: surface == null && nullToAbsent
          ? const Value.absent()
          : Value(surface),
      informal: Value(informal),
      tagsJson: Value(tagsJson),
      geomJson: Value(geomJson),
      nodeIdsJson: Value(nodeIdsJson),
      firstNodeId: Value(firstNodeId),
      lastNodeId: Value(lastNodeId),
      lengthM: Value(lengthM),
      minLat: Value(minLat),
      minLon: Value(minLon),
      maxLat: Value(maxLat),
      maxLon: Value(maxLon),
      usfsName: usfsName == null && nullToAbsent
          ? const Value.absent()
          : Value(usfsName),
      usfsNumber: usfsNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(usfsNumber),
    );
  }

  factory OsmWay.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OsmWay(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String?>(json['name']),
      highway: serializer.fromJson<String>(json['highway']),
      sacScale: serializer.fromJson<String?>(json['sacScale']),
      trailVisibility: serializer.fromJson<String?>(json['trailVisibility']),
      surface: serializer.fromJson<String?>(json['surface']),
      informal: serializer.fromJson<bool>(json['informal']),
      tagsJson: serializer.fromJson<String>(json['tagsJson']),
      geomJson: serializer.fromJson<String>(json['geomJson']),
      nodeIdsJson: serializer.fromJson<String>(json['nodeIdsJson']),
      firstNodeId: serializer.fromJson<int>(json['firstNodeId']),
      lastNodeId: serializer.fromJson<int>(json['lastNodeId']),
      lengthM: serializer.fromJson<double>(json['lengthM']),
      minLat: serializer.fromJson<double>(json['minLat']),
      minLon: serializer.fromJson<double>(json['minLon']),
      maxLat: serializer.fromJson<double>(json['maxLat']),
      maxLon: serializer.fromJson<double>(json['maxLon']),
      usfsName: serializer.fromJson<String?>(json['usfsName']),
      usfsNumber: serializer.fromJson<String?>(json['usfsNumber']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String?>(name),
      'highway': serializer.toJson<String>(highway),
      'sacScale': serializer.toJson<String?>(sacScale),
      'trailVisibility': serializer.toJson<String?>(trailVisibility),
      'surface': serializer.toJson<String?>(surface),
      'informal': serializer.toJson<bool>(informal),
      'tagsJson': serializer.toJson<String>(tagsJson),
      'geomJson': serializer.toJson<String>(geomJson),
      'nodeIdsJson': serializer.toJson<String>(nodeIdsJson),
      'firstNodeId': serializer.toJson<int>(firstNodeId),
      'lastNodeId': serializer.toJson<int>(lastNodeId),
      'lengthM': serializer.toJson<double>(lengthM),
      'minLat': serializer.toJson<double>(minLat),
      'minLon': serializer.toJson<double>(minLon),
      'maxLat': serializer.toJson<double>(maxLat),
      'maxLon': serializer.toJson<double>(maxLon),
      'usfsName': serializer.toJson<String?>(usfsName),
      'usfsNumber': serializer.toJson<String?>(usfsNumber),
    };
  }

  OsmWay copyWith(
          {int? id,
          Value<String?> name = const Value.absent(),
          String? highway,
          Value<String?> sacScale = const Value.absent(),
          Value<String?> trailVisibility = const Value.absent(),
          Value<String?> surface = const Value.absent(),
          bool? informal,
          String? tagsJson,
          String? geomJson,
          String? nodeIdsJson,
          int? firstNodeId,
          int? lastNodeId,
          double? lengthM,
          double? minLat,
          double? minLon,
          double? maxLat,
          double? maxLon,
          Value<String?> usfsName = const Value.absent(),
          Value<String?> usfsNumber = const Value.absent()}) =>
      OsmWay(
        id: id ?? this.id,
        name: name.present ? name.value : this.name,
        highway: highway ?? this.highway,
        sacScale: sacScale.present ? sacScale.value : this.sacScale,
        trailVisibility: trailVisibility.present
            ? trailVisibility.value
            : this.trailVisibility,
        surface: surface.present ? surface.value : this.surface,
        informal: informal ?? this.informal,
        tagsJson: tagsJson ?? this.tagsJson,
        geomJson: geomJson ?? this.geomJson,
        nodeIdsJson: nodeIdsJson ?? this.nodeIdsJson,
        firstNodeId: firstNodeId ?? this.firstNodeId,
        lastNodeId: lastNodeId ?? this.lastNodeId,
        lengthM: lengthM ?? this.lengthM,
        minLat: minLat ?? this.minLat,
        minLon: minLon ?? this.minLon,
        maxLat: maxLat ?? this.maxLat,
        maxLon: maxLon ?? this.maxLon,
        usfsName: usfsName.present ? usfsName.value : this.usfsName,
        usfsNumber: usfsNumber.present ? usfsNumber.value : this.usfsNumber,
      );
  OsmWay copyWithCompanion(OsmWaysCompanion data) {
    return OsmWay(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      highway: data.highway.present ? data.highway.value : this.highway,
      sacScale: data.sacScale.present ? data.sacScale.value : this.sacScale,
      trailVisibility: data.trailVisibility.present
          ? data.trailVisibility.value
          : this.trailVisibility,
      surface: data.surface.present ? data.surface.value : this.surface,
      informal: data.informal.present ? data.informal.value : this.informal,
      tagsJson: data.tagsJson.present ? data.tagsJson.value : this.tagsJson,
      geomJson: data.geomJson.present ? data.geomJson.value : this.geomJson,
      nodeIdsJson:
          data.nodeIdsJson.present ? data.nodeIdsJson.value : this.nodeIdsJson,
      firstNodeId:
          data.firstNodeId.present ? data.firstNodeId.value : this.firstNodeId,
      lastNodeId:
          data.lastNodeId.present ? data.lastNodeId.value : this.lastNodeId,
      lengthM: data.lengthM.present ? data.lengthM.value : this.lengthM,
      minLat: data.minLat.present ? data.minLat.value : this.minLat,
      minLon: data.minLon.present ? data.minLon.value : this.minLon,
      maxLat: data.maxLat.present ? data.maxLat.value : this.maxLat,
      maxLon: data.maxLon.present ? data.maxLon.value : this.maxLon,
      usfsName: data.usfsName.present ? data.usfsName.value : this.usfsName,
      usfsNumber:
          data.usfsNumber.present ? data.usfsNumber.value : this.usfsNumber,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OsmWay(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('highway: $highway, ')
          ..write('sacScale: $sacScale, ')
          ..write('trailVisibility: $trailVisibility, ')
          ..write('surface: $surface, ')
          ..write('informal: $informal, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('geomJson: $geomJson, ')
          ..write('nodeIdsJson: $nodeIdsJson, ')
          ..write('firstNodeId: $firstNodeId, ')
          ..write('lastNodeId: $lastNodeId, ')
          ..write('lengthM: $lengthM, ')
          ..write('minLat: $minLat, ')
          ..write('minLon: $minLon, ')
          ..write('maxLat: $maxLat, ')
          ..write('maxLon: $maxLon, ')
          ..write('usfsName: $usfsName, ')
          ..write('usfsNumber: $usfsNumber')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      highway,
      sacScale,
      trailVisibility,
      surface,
      informal,
      tagsJson,
      geomJson,
      nodeIdsJson,
      firstNodeId,
      lastNodeId,
      lengthM,
      minLat,
      minLon,
      maxLat,
      maxLon,
      usfsName,
      usfsNumber);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OsmWay &&
          other.id == this.id &&
          other.name == this.name &&
          other.highway == this.highway &&
          other.sacScale == this.sacScale &&
          other.trailVisibility == this.trailVisibility &&
          other.surface == this.surface &&
          other.informal == this.informal &&
          other.tagsJson == this.tagsJson &&
          other.geomJson == this.geomJson &&
          other.nodeIdsJson == this.nodeIdsJson &&
          other.firstNodeId == this.firstNodeId &&
          other.lastNodeId == this.lastNodeId &&
          other.lengthM == this.lengthM &&
          other.minLat == this.minLat &&
          other.minLon == this.minLon &&
          other.maxLat == this.maxLat &&
          other.maxLon == this.maxLon &&
          other.usfsName == this.usfsName &&
          other.usfsNumber == this.usfsNumber);
}

class OsmWaysCompanion extends UpdateCompanion<OsmWay> {
  final Value<int> id;
  final Value<String?> name;
  final Value<String> highway;
  final Value<String?> sacScale;
  final Value<String?> trailVisibility;
  final Value<String?> surface;
  final Value<bool> informal;
  final Value<String> tagsJson;
  final Value<String> geomJson;
  final Value<String> nodeIdsJson;
  final Value<int> firstNodeId;
  final Value<int> lastNodeId;
  final Value<double> lengthM;
  final Value<double> minLat;
  final Value<double> minLon;
  final Value<double> maxLat;
  final Value<double> maxLon;
  final Value<String?> usfsName;
  final Value<String?> usfsNumber;
  const OsmWaysCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.highway = const Value.absent(),
    this.sacScale = const Value.absent(),
    this.trailVisibility = const Value.absent(),
    this.surface = const Value.absent(),
    this.informal = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.geomJson = const Value.absent(),
    this.nodeIdsJson = const Value.absent(),
    this.firstNodeId = const Value.absent(),
    this.lastNodeId = const Value.absent(),
    this.lengthM = const Value.absent(),
    this.minLat = const Value.absent(),
    this.minLon = const Value.absent(),
    this.maxLat = const Value.absent(),
    this.maxLon = const Value.absent(),
    this.usfsName = const Value.absent(),
    this.usfsNumber = const Value.absent(),
  });
  OsmWaysCompanion.insert({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    required String highway,
    this.sacScale = const Value.absent(),
    this.trailVisibility = const Value.absent(),
    this.surface = const Value.absent(),
    this.informal = const Value.absent(),
    required String tagsJson,
    required String geomJson,
    this.nodeIdsJson = const Value.absent(),
    required int firstNodeId,
    required int lastNodeId,
    required double lengthM,
    required double minLat,
    required double minLon,
    required double maxLat,
    required double maxLon,
    this.usfsName = const Value.absent(),
    this.usfsNumber = const Value.absent(),
  })  : highway = Value(highway),
        tagsJson = Value(tagsJson),
        geomJson = Value(geomJson),
        firstNodeId = Value(firstNodeId),
        lastNodeId = Value(lastNodeId),
        lengthM = Value(lengthM),
        minLat = Value(minLat),
        minLon = Value(minLon),
        maxLat = Value(maxLat),
        maxLon = Value(maxLon);
  static Insertable<OsmWay> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? highway,
    Expression<String>? sacScale,
    Expression<String>? trailVisibility,
    Expression<String>? surface,
    Expression<bool>? informal,
    Expression<String>? tagsJson,
    Expression<String>? geomJson,
    Expression<String>? nodeIdsJson,
    Expression<int>? firstNodeId,
    Expression<int>? lastNodeId,
    Expression<double>? lengthM,
    Expression<double>? minLat,
    Expression<double>? minLon,
    Expression<double>? maxLat,
    Expression<double>? maxLon,
    Expression<String>? usfsName,
    Expression<String>? usfsNumber,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (highway != null) 'highway': highway,
      if (sacScale != null) 'sac_scale': sacScale,
      if (trailVisibility != null) 'trail_visibility': trailVisibility,
      if (surface != null) 'surface': surface,
      if (informal != null) 'informal': informal,
      if (tagsJson != null) 'tags_json': tagsJson,
      if (geomJson != null) 'geom_json': geomJson,
      if (nodeIdsJson != null) 'node_ids_json': nodeIdsJson,
      if (firstNodeId != null) 'first_node_id': firstNodeId,
      if (lastNodeId != null) 'last_node_id': lastNodeId,
      if (lengthM != null) 'length_m': lengthM,
      if (minLat != null) 'min_lat': minLat,
      if (minLon != null) 'min_lon': minLon,
      if (maxLat != null) 'max_lat': maxLat,
      if (maxLon != null) 'max_lon': maxLon,
      if (usfsName != null) 'usfs_name': usfsName,
      if (usfsNumber != null) 'usfs_number': usfsNumber,
    });
  }

  OsmWaysCompanion copyWith(
      {Value<int>? id,
      Value<String?>? name,
      Value<String>? highway,
      Value<String?>? sacScale,
      Value<String?>? trailVisibility,
      Value<String?>? surface,
      Value<bool>? informal,
      Value<String>? tagsJson,
      Value<String>? geomJson,
      Value<String>? nodeIdsJson,
      Value<int>? firstNodeId,
      Value<int>? lastNodeId,
      Value<double>? lengthM,
      Value<double>? minLat,
      Value<double>? minLon,
      Value<double>? maxLat,
      Value<double>? maxLon,
      Value<String?>? usfsName,
      Value<String?>? usfsNumber}) {
    return OsmWaysCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      highway: highway ?? this.highway,
      sacScale: sacScale ?? this.sacScale,
      trailVisibility: trailVisibility ?? this.trailVisibility,
      surface: surface ?? this.surface,
      informal: informal ?? this.informal,
      tagsJson: tagsJson ?? this.tagsJson,
      geomJson: geomJson ?? this.geomJson,
      nodeIdsJson: nodeIdsJson ?? this.nodeIdsJson,
      firstNodeId: firstNodeId ?? this.firstNodeId,
      lastNodeId: lastNodeId ?? this.lastNodeId,
      lengthM: lengthM ?? this.lengthM,
      minLat: minLat ?? this.minLat,
      minLon: minLon ?? this.minLon,
      maxLat: maxLat ?? this.maxLat,
      maxLon: maxLon ?? this.maxLon,
      usfsName: usfsName ?? this.usfsName,
      usfsNumber: usfsNumber ?? this.usfsNumber,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (highway.present) {
      map['highway'] = Variable<String>(highway.value);
    }
    if (sacScale.present) {
      map['sac_scale'] = Variable<String>(sacScale.value);
    }
    if (trailVisibility.present) {
      map['trail_visibility'] = Variable<String>(trailVisibility.value);
    }
    if (surface.present) {
      map['surface'] = Variable<String>(surface.value);
    }
    if (informal.present) {
      map['informal'] = Variable<bool>(informal.value);
    }
    if (tagsJson.present) {
      map['tags_json'] = Variable<String>(tagsJson.value);
    }
    if (geomJson.present) {
      map['geom_json'] = Variable<String>(geomJson.value);
    }
    if (nodeIdsJson.present) {
      map['node_ids_json'] = Variable<String>(nodeIdsJson.value);
    }
    if (firstNodeId.present) {
      map['first_node_id'] = Variable<int>(firstNodeId.value);
    }
    if (lastNodeId.present) {
      map['last_node_id'] = Variable<int>(lastNodeId.value);
    }
    if (lengthM.present) {
      map['length_m'] = Variable<double>(lengthM.value);
    }
    if (minLat.present) {
      map['min_lat'] = Variable<double>(minLat.value);
    }
    if (minLon.present) {
      map['min_lon'] = Variable<double>(minLon.value);
    }
    if (maxLat.present) {
      map['max_lat'] = Variable<double>(maxLat.value);
    }
    if (maxLon.present) {
      map['max_lon'] = Variable<double>(maxLon.value);
    }
    if (usfsName.present) {
      map['usfs_name'] = Variable<String>(usfsName.value);
    }
    if (usfsNumber.present) {
      map['usfs_number'] = Variable<String>(usfsNumber.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OsmWaysCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('highway: $highway, ')
          ..write('sacScale: $sacScale, ')
          ..write('trailVisibility: $trailVisibility, ')
          ..write('surface: $surface, ')
          ..write('informal: $informal, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('geomJson: $geomJson, ')
          ..write('nodeIdsJson: $nodeIdsJson, ')
          ..write('firstNodeId: $firstNodeId, ')
          ..write('lastNodeId: $lastNodeId, ')
          ..write('lengthM: $lengthM, ')
          ..write('minLat: $minLat, ')
          ..write('minLon: $minLon, ')
          ..write('maxLat: $maxLat, ')
          ..write('maxLon: $maxLon, ')
          ..write('usfsName: $usfsName, ')
          ..write('usfsNumber: $usfsNumber')
          ..write(')'))
        .toString();
  }
}

class $OsmNodesTable extends OsmNodes with TableInfo<$OsmNodesTable, OsmNode> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OsmNodesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
      'lat', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _lonMeta = const VerificationMeta('lon');
  @override
  late final GeneratedColumn<double> lon = GeneratedColumn<double>(
      'lon', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, lat, lon];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'osm_nodes';
  @override
  VerificationContext validateIntegrity(Insertable<OsmNode> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('lat')) {
      context.handle(
          _latMeta, lat.isAcceptableOrUnknown(data['lat']!, _latMeta));
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lon')) {
      context.handle(
          _lonMeta, lon.isAcceptableOrUnknown(data['lon']!, _lonMeta));
    } else if (isInserting) {
      context.missing(_lonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OsmNode map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OsmNode(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      lat: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}lat'])!,
      lon: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}lon'])!,
    );
  }

  @override
  $OsmNodesTable createAlias(String alias) {
    return $OsmNodesTable(attachedDatabase, alias);
  }
}

class OsmNode extends DataClass implements Insertable<OsmNode> {
  final int id;
  final double lat;
  final double lon;
  const OsmNode({required this.id, required this.lat, required this.lon});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['lat'] = Variable<double>(lat);
    map['lon'] = Variable<double>(lon);
    return map;
  }

  OsmNodesCompanion toCompanion(bool nullToAbsent) {
    return OsmNodesCompanion(
      id: Value(id),
      lat: Value(lat),
      lon: Value(lon),
    );
  }

  factory OsmNode.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OsmNode(
      id: serializer.fromJson<int>(json['id']),
      lat: serializer.fromJson<double>(json['lat']),
      lon: serializer.fromJson<double>(json['lon']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'lat': serializer.toJson<double>(lat),
      'lon': serializer.toJson<double>(lon),
    };
  }

  OsmNode copyWith({int? id, double? lat, double? lon}) => OsmNode(
        id: id ?? this.id,
        lat: lat ?? this.lat,
        lon: lon ?? this.lon,
      );
  OsmNode copyWithCompanion(OsmNodesCompanion data) {
    return OsmNode(
      id: data.id.present ? data.id.value : this.id,
      lat: data.lat.present ? data.lat.value : this.lat,
      lon: data.lon.present ? data.lon.value : this.lon,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OsmNode(')
          ..write('id: $id, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, lat, lon);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OsmNode &&
          other.id == this.id &&
          other.lat == this.lat &&
          other.lon == this.lon);
}

class OsmNodesCompanion extends UpdateCompanion<OsmNode> {
  final Value<int> id;
  final Value<double> lat;
  final Value<double> lon;
  const OsmNodesCompanion({
    this.id = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
  });
  OsmNodesCompanion.insert({
    this.id = const Value.absent(),
    required double lat,
    required double lon,
  })  : lat = Value(lat),
        lon = Value(lon);
  static Insertable<OsmNode> custom({
    Expression<int>? id,
    Expression<double>? lat,
    Expression<double>? lon,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
    });
  }

  OsmNodesCompanion copyWith(
      {Value<int>? id, Value<double>? lat, Value<double>? lon}) {
    return OsmNodesCompanion(
      id: id ?? this.id,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lon.present) {
      map['lon'] = Variable<double>(lon.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OsmNodesCompanion(')
          ..write('id: $id, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon')
          ..write(')'))
        .toString();
  }
}

class $OsmRelationsTable extends OsmRelations
    with TableInfo<$OsmRelationsTable, OsmRelation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OsmRelationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _networkMeta =
      const VerificationMeta('network');
  @override
  late final GeneratedColumn<String> network = GeneratedColumn<String>(
      'network', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tagsJsonMeta =
      const VerificationMeta('tagsJson');
  @override
  late final GeneratedColumn<String> tagsJson = GeneratedColumn<String>(
      'tags_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _memberWayIdsJsonMeta =
      const VerificationMeta('memberWayIdsJson');
  @override
  late final GeneratedColumn<String> memberWayIdsJson = GeneratedColumn<String>(
      'member_way_ids_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, network, tagsJson, memberWayIdsJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'osm_relations';
  @override
  VerificationContext validateIntegrity(Insertable<OsmRelation> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    if (data.containsKey('network')) {
      context.handle(_networkMeta,
          network.isAcceptableOrUnknown(data['network']!, _networkMeta));
    }
    if (data.containsKey('tags_json')) {
      context.handle(_tagsJsonMeta,
          tagsJson.isAcceptableOrUnknown(data['tags_json']!, _tagsJsonMeta));
    } else if (isInserting) {
      context.missing(_tagsJsonMeta);
    }
    if (data.containsKey('member_way_ids_json')) {
      context.handle(
          _memberWayIdsJsonMeta,
          memberWayIdsJson.isAcceptableOrUnknown(
              data['member_way_ids_json']!, _memberWayIdsJsonMeta));
    } else if (isInserting) {
      context.missing(_memberWayIdsJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OsmRelation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OsmRelation(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name']),
      network: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}network']),
      tagsJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tags_json'])!,
      memberWayIdsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}member_way_ids_json'])!,
    );
  }

  @override
  $OsmRelationsTable createAlias(String alias) {
    return $OsmRelationsTable(attachedDatabase, alias);
  }
}

class OsmRelation extends DataClass implements Insertable<OsmRelation> {
  final int id;
  final String? name;
  final String? network;
  final String tagsJson;
  final String memberWayIdsJson;
  const OsmRelation(
      {required this.id,
      this.name,
      this.network,
      required this.tagsJson,
      required this.memberWayIdsJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || network != null) {
      map['network'] = Variable<String>(network);
    }
    map['tags_json'] = Variable<String>(tagsJson);
    map['member_way_ids_json'] = Variable<String>(memberWayIdsJson);
    return map;
  }

  OsmRelationsCompanion toCompanion(bool nullToAbsent) {
    return OsmRelationsCompanion(
      id: Value(id),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      network: network == null && nullToAbsent
          ? const Value.absent()
          : Value(network),
      tagsJson: Value(tagsJson),
      memberWayIdsJson: Value(memberWayIdsJson),
    );
  }

  factory OsmRelation.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OsmRelation(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String?>(json['name']),
      network: serializer.fromJson<String?>(json['network']),
      tagsJson: serializer.fromJson<String>(json['tagsJson']),
      memberWayIdsJson: serializer.fromJson<String>(json['memberWayIdsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String?>(name),
      'network': serializer.toJson<String?>(network),
      'tagsJson': serializer.toJson<String>(tagsJson),
      'memberWayIdsJson': serializer.toJson<String>(memberWayIdsJson),
    };
  }

  OsmRelation copyWith(
          {int? id,
          Value<String?> name = const Value.absent(),
          Value<String?> network = const Value.absent(),
          String? tagsJson,
          String? memberWayIdsJson}) =>
      OsmRelation(
        id: id ?? this.id,
        name: name.present ? name.value : this.name,
        network: network.present ? network.value : this.network,
        tagsJson: tagsJson ?? this.tagsJson,
        memberWayIdsJson: memberWayIdsJson ?? this.memberWayIdsJson,
      );
  OsmRelation copyWithCompanion(OsmRelationsCompanion data) {
    return OsmRelation(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      network: data.network.present ? data.network.value : this.network,
      tagsJson: data.tagsJson.present ? data.tagsJson.value : this.tagsJson,
      memberWayIdsJson: data.memberWayIdsJson.present
          ? data.memberWayIdsJson.value
          : this.memberWayIdsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OsmRelation(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('network: $network, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('memberWayIdsJson: $memberWayIdsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, network, tagsJson, memberWayIdsJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OsmRelation &&
          other.id == this.id &&
          other.name == this.name &&
          other.network == this.network &&
          other.tagsJson == this.tagsJson &&
          other.memberWayIdsJson == this.memberWayIdsJson);
}

class OsmRelationsCompanion extends UpdateCompanion<OsmRelation> {
  final Value<int> id;
  final Value<String?> name;
  final Value<String?> network;
  final Value<String> tagsJson;
  final Value<String> memberWayIdsJson;
  const OsmRelationsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.network = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.memberWayIdsJson = const Value.absent(),
  });
  OsmRelationsCompanion.insert({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.network = const Value.absent(),
    required String tagsJson,
    required String memberWayIdsJson,
  })  : tagsJson = Value(tagsJson),
        memberWayIdsJson = Value(memberWayIdsJson);
  static Insertable<OsmRelation> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? network,
    Expression<String>? tagsJson,
    Expression<String>? memberWayIdsJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (network != null) 'network': network,
      if (tagsJson != null) 'tags_json': tagsJson,
      if (memberWayIdsJson != null) 'member_way_ids_json': memberWayIdsJson,
    });
  }

  OsmRelationsCompanion copyWith(
      {Value<int>? id,
      Value<String?>? name,
      Value<String?>? network,
      Value<String>? tagsJson,
      Value<String>? memberWayIdsJson}) {
    return OsmRelationsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      network: network ?? this.network,
      tagsJson: tagsJson ?? this.tagsJson,
      memberWayIdsJson: memberWayIdsJson ?? this.memberWayIdsJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (network.present) {
      map['network'] = Variable<String>(network.value);
    }
    if (tagsJson.present) {
      map['tags_json'] = Variable<String>(tagsJson.value);
    }
    if (memberWayIdsJson.present) {
      map['member_way_ids_json'] = Variable<String>(memberWayIdsJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OsmRelationsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('network: $network, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('memberWayIdsJson: $memberWayIdsJson')
          ..write(')'))
        .toString();
  }
}

class $PoisTable extends Pois with TableInfo<$PoisTable, Poi> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PoisTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
      'lat', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _lonMeta = const VerificationMeta('lon');
  @override
  late final GeneratedColumn<double> lon = GeneratedColumn<double>(
      'lon', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _tagsJsonMeta =
      const VerificationMeta('tagsJson');
  @override
  late final GeneratedColumn<String> tagsJson = GeneratedColumn<String>(
      'tags_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, kind, name, lat, lon, tagsJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pois';
  @override
  VerificationContext validateIntegrity(Insertable<Poi> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    if (data.containsKey('lat')) {
      context.handle(
          _latMeta, lat.isAcceptableOrUnknown(data['lat']!, _latMeta));
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lon')) {
      context.handle(
          _lonMeta, lon.isAcceptableOrUnknown(data['lon']!, _lonMeta));
    } else if (isInserting) {
      context.missing(_lonMeta);
    }
    if (data.containsKey('tags_json')) {
      context.handle(_tagsJsonMeta,
          tagsJson.isAcceptableOrUnknown(data['tags_json']!, _tagsJsonMeta));
    } else if (isInserting) {
      context.missing(_tagsJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Poi map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Poi(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name']),
      lat: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}lat'])!,
      lon: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}lon'])!,
      tagsJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tags_json'])!,
    );
  }

  @override
  $PoisTable createAlias(String alias) {
    return $PoisTable(attachedDatabase, alias);
  }
}

class Poi extends DataClass implements Insertable<Poi> {
  final String id;
  final String kind;
  final String? name;
  final double lat;
  final double lon;
  final String tagsJson;
  const Poi(
      {required this.id,
      required this.kind,
      this.name,
      required this.lat,
      required this.lon,
      required this.tagsJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    map['lat'] = Variable<double>(lat);
    map['lon'] = Variable<double>(lon);
    map['tags_json'] = Variable<String>(tagsJson);
    return map;
  }

  PoisCompanion toCompanion(bool nullToAbsent) {
    return PoisCompanion(
      id: Value(id),
      kind: Value(kind),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      lat: Value(lat),
      lon: Value(lon),
      tagsJson: Value(tagsJson),
    );
  }

  factory Poi.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Poi(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      name: serializer.fromJson<String?>(json['name']),
      lat: serializer.fromJson<double>(json['lat']),
      lon: serializer.fromJson<double>(json['lon']),
      tagsJson: serializer.fromJson<String>(json['tagsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'name': serializer.toJson<String?>(name),
      'lat': serializer.toJson<double>(lat),
      'lon': serializer.toJson<double>(lon),
      'tagsJson': serializer.toJson<String>(tagsJson),
    };
  }

  Poi copyWith(
          {String? id,
          String? kind,
          Value<String?> name = const Value.absent(),
          double? lat,
          double? lon,
          String? tagsJson}) =>
      Poi(
        id: id ?? this.id,
        kind: kind ?? this.kind,
        name: name.present ? name.value : this.name,
        lat: lat ?? this.lat,
        lon: lon ?? this.lon,
        tagsJson: tagsJson ?? this.tagsJson,
      );
  Poi copyWithCompanion(PoisCompanion data) {
    return Poi(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      name: data.name.present ? data.name.value : this.name,
      lat: data.lat.present ? data.lat.value : this.lat,
      lon: data.lon.present ? data.lon.value : this.lon,
      tagsJson: data.tagsJson.present ? data.tagsJson.value : this.tagsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Poi(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('name: $name, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('tagsJson: $tagsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, kind, name, lat, lon, tagsJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Poi &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.name == this.name &&
          other.lat == this.lat &&
          other.lon == this.lon &&
          other.tagsJson == this.tagsJson);
}

class PoisCompanion extends UpdateCompanion<Poi> {
  final Value<String> id;
  final Value<String> kind;
  final Value<String?> name;
  final Value<double> lat;
  final Value<double> lon;
  final Value<String> tagsJson;
  final Value<int> rowid;
  const PoisCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.name = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PoisCompanion.insert({
    required String id,
    required String kind,
    this.name = const Value.absent(),
    required double lat,
    required double lon,
    required String tagsJson,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        kind = Value(kind),
        lat = Value(lat),
        lon = Value(lon),
        tagsJson = Value(tagsJson);
  static Insertable<Poi> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<String>? name,
    Expression<double>? lat,
    Expression<double>? lon,
    Expression<String>? tagsJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (name != null) 'name': name,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      if (tagsJson != null) 'tags_json': tagsJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PoisCompanion copyWith(
      {Value<String>? id,
      Value<String>? kind,
      Value<String?>? name,
      Value<double>? lat,
      Value<double>? lon,
      Value<String>? tagsJson,
      Value<int>? rowid}) {
    return PoisCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      name: name ?? this.name,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      tagsJson: tagsJson ?? this.tagsJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lon.present) {
      map['lon'] = Variable<double>(lon.value);
    }
    if (tagsJson.present) {
      map['tags_json'] = Variable<String>(tagsJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PoisCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('name: $name, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CacheCellsTable extends CacheCells
    with TableInfo<$CacheCellsTable, CacheCell> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CacheCellsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cellKeyMeta =
      const VerificationMeta('cellKey');
  @override
  late final GeneratedColumn<String> cellKey = GeneratedColumn<String>(
      'cell_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _datasetMeta =
      const VerificationMeta('dataset');
  @override
  late final GeneratedColumn<String> dataset = GeneratedColumn<String>(
      'dataset', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fetchedAtMeta =
      const VerificationMeta('fetchedAt');
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
      'fetched_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [cellKey, dataset, fetchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cache_cells';
  @override
  VerificationContext validateIntegrity(Insertable<CacheCell> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cell_key')) {
      context.handle(_cellKeyMeta,
          cellKey.isAcceptableOrUnknown(data['cell_key']!, _cellKeyMeta));
    } else if (isInserting) {
      context.missing(_cellKeyMeta);
    }
    if (data.containsKey('dataset')) {
      context.handle(_datasetMeta,
          dataset.isAcceptableOrUnknown(data['dataset']!, _datasetMeta));
    } else if (isInserting) {
      context.missing(_datasetMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(_fetchedAtMeta,
          fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta));
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cellKey, dataset};
  @override
  CacheCell map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CacheCell(
      cellKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cell_key'])!,
      dataset: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}dataset'])!,
      fetchedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}fetched_at'])!,
    );
  }

  @override
  $CacheCellsTable createAlias(String alias) {
    return $CacheCellsTable(attachedDatabase, alias);
  }
}

class CacheCell extends DataClass implements Insertable<CacheCell> {
  final String cellKey;
  final String dataset;
  final DateTime fetchedAt;
  const CacheCell(
      {required this.cellKey, required this.dataset, required this.fetchedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cell_key'] = Variable<String>(cellKey);
    map['dataset'] = Variable<String>(dataset);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  CacheCellsCompanion toCompanion(bool nullToAbsent) {
    return CacheCellsCompanion(
      cellKey: Value(cellKey),
      dataset: Value(dataset),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory CacheCell.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CacheCell(
      cellKey: serializer.fromJson<String>(json['cellKey']),
      dataset: serializer.fromJson<String>(json['dataset']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cellKey': serializer.toJson<String>(cellKey),
      'dataset': serializer.toJson<String>(dataset),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  CacheCell copyWith({String? cellKey, String? dataset, DateTime? fetchedAt}) =>
      CacheCell(
        cellKey: cellKey ?? this.cellKey,
        dataset: dataset ?? this.dataset,
        fetchedAt: fetchedAt ?? this.fetchedAt,
      );
  CacheCell copyWithCompanion(CacheCellsCompanion data) {
    return CacheCell(
      cellKey: data.cellKey.present ? data.cellKey.value : this.cellKey,
      dataset: data.dataset.present ? data.dataset.value : this.dataset,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CacheCell(')
          ..write('cellKey: $cellKey, ')
          ..write('dataset: $dataset, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(cellKey, dataset, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CacheCell &&
          other.cellKey == this.cellKey &&
          other.dataset == this.dataset &&
          other.fetchedAt == this.fetchedAt);
}

class CacheCellsCompanion extends UpdateCompanion<CacheCell> {
  final Value<String> cellKey;
  final Value<String> dataset;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const CacheCellsCompanion({
    this.cellKey = const Value.absent(),
    this.dataset = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CacheCellsCompanion.insert({
    required String cellKey,
    required String dataset,
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  })  : cellKey = Value(cellKey),
        dataset = Value(dataset),
        fetchedAt = Value(fetchedAt);
  static Insertable<CacheCell> custom({
    Expression<String>? cellKey,
    Expression<String>? dataset,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cellKey != null) 'cell_key': cellKey,
      if (dataset != null) 'dataset': dataset,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CacheCellsCompanion copyWith(
      {Value<String>? cellKey,
      Value<String>? dataset,
      Value<DateTime>? fetchedAt,
      Value<int>? rowid}) {
    return CacheCellsCompanion(
      cellKey: cellKey ?? this.cellKey,
      dataset: dataset ?? this.dataset,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cellKey.present) {
      map['cell_key'] = Variable<String>(cellKey.value);
    }
    if (dataset.present) {
      map['dataset'] = Variable<String>(dataset.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CacheCellsCompanion(')
          ..write('cellKey: $cellKey, ')
          ..write('dataset: $dataset, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UsfsRoadsTable extends UsfsRoads
    with TableInfo<$UsfsRoadsTable, UsfsRoad> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsfsRoadsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _routeIdMeta =
      const VerificationMeta('routeId');
  @override
  late final GeneratedColumn<String> routeId = GeneratedColumn<String>(
      'route_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<String> number = GeneratedColumn<String>(
      'number', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _symbolMeta = const VerificationMeta('symbol');
  @override
  late final GeneratedColumn<int> symbol = GeneratedColumn<int>(
      'symbol', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _symbolNameMeta =
      const VerificationMeta('symbolName');
  @override
  late final GeneratedColumn<String> symbolName = GeneratedColumn<String>(
      'symbol_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _seasonalMeta =
      const VerificationMeta('seasonal');
  @override
  late final GeneratedColumn<bool> seasonal = GeneratedColumn<bool>(
      'seasonal', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("seasonal" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _surfaceMeta =
      const VerificationMeta('surface');
  @override
  late final GeneratedColumn<String> surface = GeneratedColumn<String>(
      'surface', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _maintLevelMeta =
      const VerificationMeta('maintLevel');
  @override
  late final GeneratedColumn<String> maintLevel = GeneratedColumn<String>(
      'maint_level', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _accessJsonMeta =
      const VerificationMeta('accessJson');
  @override
  late final GeneratedColumn<String> accessJson = GeneratedColumn<String>(
      'access_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _lengthMiMeta =
      const VerificationMeta('lengthMi');
  @override
  late final GeneratedColumn<double> lengthMi = GeneratedColumn<double>(
      'length_mi', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _geomJsonMeta =
      const VerificationMeta('geomJson');
  @override
  late final GeneratedColumn<String> geomJson = GeneratedColumn<String>(
      'geom_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _minLatMeta = const VerificationMeta('minLat');
  @override
  late final GeneratedColumn<double> minLat = GeneratedColumn<double>(
      'min_lat', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _minLonMeta = const VerificationMeta('minLon');
  @override
  late final GeneratedColumn<double> minLon = GeneratedColumn<double>(
      'min_lon', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _maxLatMeta = const VerificationMeta('maxLat');
  @override
  late final GeneratedColumn<double> maxLat = GeneratedColumn<double>(
      'max_lat', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _maxLonMeta = const VerificationMeta('maxLon');
  @override
  late final GeneratedColumn<double> maxLon = GeneratedColumn<double>(
      'max_lon', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        routeId,
        number,
        name,
        kind,
        symbol,
        symbolName,
        seasonal,
        surface,
        maintLevel,
        accessJson,
        lengthMi,
        geomJson,
        minLat,
        minLon,
        maxLat,
        maxLon
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'usfs_roads';
  @override
  VerificationContext validateIntegrity(Insertable<UsfsRoad> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('route_id')) {
      context.handle(_routeIdMeta,
          routeId.isAcceptableOrUnknown(data['route_id']!, _routeIdMeta));
    } else if (isInserting) {
      context.missing(_routeIdMeta);
    }
    if (data.containsKey('number')) {
      context.handle(_numberMeta,
          number.isAcceptableOrUnknown(data['number']!, _numberMeta));
    } else if (isInserting) {
      context.missing(_numberMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('symbol')) {
      context.handle(_symbolMeta,
          symbol.isAcceptableOrUnknown(data['symbol']!, _symbolMeta));
    } else if (isInserting) {
      context.missing(_symbolMeta);
    }
    if (data.containsKey('symbol_name')) {
      context.handle(
          _symbolNameMeta,
          symbolName.isAcceptableOrUnknown(
              data['symbol_name']!, _symbolNameMeta));
    }
    if (data.containsKey('seasonal')) {
      context.handle(_seasonalMeta,
          seasonal.isAcceptableOrUnknown(data['seasonal']!, _seasonalMeta));
    }
    if (data.containsKey('surface')) {
      context.handle(_surfaceMeta,
          surface.isAcceptableOrUnknown(data['surface']!, _surfaceMeta));
    }
    if (data.containsKey('maint_level')) {
      context.handle(
          _maintLevelMeta,
          maintLevel.isAcceptableOrUnknown(
              data['maint_level']!, _maintLevelMeta));
    }
    if (data.containsKey('access_json')) {
      context.handle(
          _accessJsonMeta,
          accessJson.isAcceptableOrUnknown(
              data['access_json']!, _accessJsonMeta));
    }
    if (data.containsKey('length_mi')) {
      context.handle(_lengthMiMeta,
          lengthMi.isAcceptableOrUnknown(data['length_mi']!, _lengthMiMeta));
    }
    if (data.containsKey('geom_json')) {
      context.handle(_geomJsonMeta,
          geomJson.isAcceptableOrUnknown(data['geom_json']!, _geomJsonMeta));
    } else if (isInserting) {
      context.missing(_geomJsonMeta);
    }
    if (data.containsKey('min_lat')) {
      context.handle(_minLatMeta,
          minLat.isAcceptableOrUnknown(data['min_lat']!, _minLatMeta));
    } else if (isInserting) {
      context.missing(_minLatMeta);
    }
    if (data.containsKey('min_lon')) {
      context.handle(_minLonMeta,
          minLon.isAcceptableOrUnknown(data['min_lon']!, _minLonMeta));
    } else if (isInserting) {
      context.missing(_minLonMeta);
    }
    if (data.containsKey('max_lat')) {
      context.handle(_maxLatMeta,
          maxLat.isAcceptableOrUnknown(data['max_lat']!, _maxLatMeta));
    } else if (isInserting) {
      context.missing(_maxLatMeta);
    }
    if (data.containsKey('max_lon')) {
      context.handle(_maxLonMeta,
          maxLon.isAcceptableOrUnknown(data['max_lon']!, _maxLonMeta));
    } else if (isInserting) {
      context.missing(_maxLonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UsfsRoad map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UsfsRoad(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      routeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}route_id'])!,
      number: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}number'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name']),
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      symbol: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}symbol'])!,
      symbolName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}symbol_name']),
      seasonal: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}seasonal'])!,
      surface: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}surface']),
      maintLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}maint_level']),
      accessJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}access_json'])!,
      lengthMi: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}length_mi']),
      geomJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}geom_json'])!,
      minLat: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}min_lat'])!,
      minLon: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}min_lon'])!,
      maxLat: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}max_lat'])!,
      maxLon: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}max_lon'])!,
    );
  }

  @override
  $UsfsRoadsTable createAlias(String alias) {
    return $UsfsRoadsTable(attachedDatabase, alias);
  }
}

class UsfsRoad extends DataClass implements Insertable<UsfsRoad> {
  final String id;
  final String routeId;
  final String number;
  final String? name;
  final String kind;
  final int symbol;
  final String? symbolName;
  final bool seasonal;
  final String? surface;
  final String? maintLevel;
  final String accessJson;
  final double? lengthMi;
  final String geomJson;
  final double minLat;
  final double minLon;
  final double maxLat;
  final double maxLon;
  const UsfsRoad(
      {required this.id,
      required this.routeId,
      required this.number,
      this.name,
      required this.kind,
      required this.symbol,
      this.symbolName,
      required this.seasonal,
      this.surface,
      this.maintLevel,
      required this.accessJson,
      this.lengthMi,
      required this.geomJson,
      required this.minLat,
      required this.minLon,
      required this.maxLat,
      required this.maxLon});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['route_id'] = Variable<String>(routeId);
    map['number'] = Variable<String>(number);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    map['kind'] = Variable<String>(kind);
    map['symbol'] = Variable<int>(symbol);
    if (!nullToAbsent || symbolName != null) {
      map['symbol_name'] = Variable<String>(symbolName);
    }
    map['seasonal'] = Variable<bool>(seasonal);
    if (!nullToAbsent || surface != null) {
      map['surface'] = Variable<String>(surface);
    }
    if (!nullToAbsent || maintLevel != null) {
      map['maint_level'] = Variable<String>(maintLevel);
    }
    map['access_json'] = Variable<String>(accessJson);
    if (!nullToAbsent || lengthMi != null) {
      map['length_mi'] = Variable<double>(lengthMi);
    }
    map['geom_json'] = Variable<String>(geomJson);
    map['min_lat'] = Variable<double>(minLat);
    map['min_lon'] = Variable<double>(minLon);
    map['max_lat'] = Variable<double>(maxLat);
    map['max_lon'] = Variable<double>(maxLon);
    return map;
  }

  UsfsRoadsCompanion toCompanion(bool nullToAbsent) {
    return UsfsRoadsCompanion(
      id: Value(id),
      routeId: Value(routeId),
      number: Value(number),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      kind: Value(kind),
      symbol: Value(symbol),
      symbolName: symbolName == null && nullToAbsent
          ? const Value.absent()
          : Value(symbolName),
      seasonal: Value(seasonal),
      surface: surface == null && nullToAbsent
          ? const Value.absent()
          : Value(surface),
      maintLevel: maintLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(maintLevel),
      accessJson: Value(accessJson),
      lengthMi: lengthMi == null && nullToAbsent
          ? const Value.absent()
          : Value(lengthMi),
      geomJson: Value(geomJson),
      minLat: Value(minLat),
      minLon: Value(minLon),
      maxLat: Value(maxLat),
      maxLon: Value(maxLon),
    );
  }

  factory UsfsRoad.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UsfsRoad(
      id: serializer.fromJson<String>(json['id']),
      routeId: serializer.fromJson<String>(json['routeId']),
      number: serializer.fromJson<String>(json['number']),
      name: serializer.fromJson<String?>(json['name']),
      kind: serializer.fromJson<String>(json['kind']),
      symbol: serializer.fromJson<int>(json['symbol']),
      symbolName: serializer.fromJson<String?>(json['symbolName']),
      seasonal: serializer.fromJson<bool>(json['seasonal']),
      surface: serializer.fromJson<String?>(json['surface']),
      maintLevel: serializer.fromJson<String?>(json['maintLevel']),
      accessJson: serializer.fromJson<String>(json['accessJson']),
      lengthMi: serializer.fromJson<double?>(json['lengthMi']),
      geomJson: serializer.fromJson<String>(json['geomJson']),
      minLat: serializer.fromJson<double>(json['minLat']),
      minLon: serializer.fromJson<double>(json['minLon']),
      maxLat: serializer.fromJson<double>(json['maxLat']),
      maxLon: serializer.fromJson<double>(json['maxLon']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'routeId': serializer.toJson<String>(routeId),
      'number': serializer.toJson<String>(number),
      'name': serializer.toJson<String?>(name),
      'kind': serializer.toJson<String>(kind),
      'symbol': serializer.toJson<int>(symbol),
      'symbolName': serializer.toJson<String?>(symbolName),
      'seasonal': serializer.toJson<bool>(seasonal),
      'surface': serializer.toJson<String?>(surface),
      'maintLevel': serializer.toJson<String?>(maintLevel),
      'accessJson': serializer.toJson<String>(accessJson),
      'lengthMi': serializer.toJson<double?>(lengthMi),
      'geomJson': serializer.toJson<String>(geomJson),
      'minLat': serializer.toJson<double>(minLat),
      'minLon': serializer.toJson<double>(minLon),
      'maxLat': serializer.toJson<double>(maxLat),
      'maxLon': serializer.toJson<double>(maxLon),
    };
  }

  UsfsRoad copyWith(
          {String? id,
          String? routeId,
          String? number,
          Value<String?> name = const Value.absent(),
          String? kind,
          int? symbol,
          Value<String?> symbolName = const Value.absent(),
          bool? seasonal,
          Value<String?> surface = const Value.absent(),
          Value<String?> maintLevel = const Value.absent(),
          String? accessJson,
          Value<double?> lengthMi = const Value.absent(),
          String? geomJson,
          double? minLat,
          double? minLon,
          double? maxLat,
          double? maxLon}) =>
      UsfsRoad(
        id: id ?? this.id,
        routeId: routeId ?? this.routeId,
        number: number ?? this.number,
        name: name.present ? name.value : this.name,
        kind: kind ?? this.kind,
        symbol: symbol ?? this.symbol,
        symbolName: symbolName.present ? symbolName.value : this.symbolName,
        seasonal: seasonal ?? this.seasonal,
        surface: surface.present ? surface.value : this.surface,
        maintLevel: maintLevel.present ? maintLevel.value : this.maintLevel,
        accessJson: accessJson ?? this.accessJson,
        lengthMi: lengthMi.present ? lengthMi.value : this.lengthMi,
        geomJson: geomJson ?? this.geomJson,
        minLat: minLat ?? this.minLat,
        minLon: minLon ?? this.minLon,
        maxLat: maxLat ?? this.maxLat,
        maxLon: maxLon ?? this.maxLon,
      );
  UsfsRoad copyWithCompanion(UsfsRoadsCompanion data) {
    return UsfsRoad(
      id: data.id.present ? data.id.value : this.id,
      routeId: data.routeId.present ? data.routeId.value : this.routeId,
      number: data.number.present ? data.number.value : this.number,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      symbol: data.symbol.present ? data.symbol.value : this.symbol,
      symbolName:
          data.symbolName.present ? data.symbolName.value : this.symbolName,
      seasonal: data.seasonal.present ? data.seasonal.value : this.seasonal,
      surface: data.surface.present ? data.surface.value : this.surface,
      maintLevel:
          data.maintLevel.present ? data.maintLevel.value : this.maintLevel,
      accessJson:
          data.accessJson.present ? data.accessJson.value : this.accessJson,
      lengthMi: data.lengthMi.present ? data.lengthMi.value : this.lengthMi,
      geomJson: data.geomJson.present ? data.geomJson.value : this.geomJson,
      minLat: data.minLat.present ? data.minLat.value : this.minLat,
      minLon: data.minLon.present ? data.minLon.value : this.minLon,
      maxLat: data.maxLat.present ? data.maxLat.value : this.maxLat,
      maxLon: data.maxLon.present ? data.maxLon.value : this.maxLon,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UsfsRoad(')
          ..write('id: $id, ')
          ..write('routeId: $routeId, ')
          ..write('number: $number, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('symbol: $symbol, ')
          ..write('symbolName: $symbolName, ')
          ..write('seasonal: $seasonal, ')
          ..write('surface: $surface, ')
          ..write('maintLevel: $maintLevel, ')
          ..write('accessJson: $accessJson, ')
          ..write('lengthMi: $lengthMi, ')
          ..write('geomJson: $geomJson, ')
          ..write('minLat: $minLat, ')
          ..write('minLon: $minLon, ')
          ..write('maxLat: $maxLat, ')
          ..write('maxLon: $maxLon')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      routeId,
      number,
      name,
      kind,
      symbol,
      symbolName,
      seasonal,
      surface,
      maintLevel,
      accessJson,
      lengthMi,
      geomJson,
      minLat,
      minLon,
      maxLat,
      maxLon);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UsfsRoad &&
          other.id == this.id &&
          other.routeId == this.routeId &&
          other.number == this.number &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.symbol == this.symbol &&
          other.symbolName == this.symbolName &&
          other.seasonal == this.seasonal &&
          other.surface == this.surface &&
          other.maintLevel == this.maintLevel &&
          other.accessJson == this.accessJson &&
          other.lengthMi == this.lengthMi &&
          other.geomJson == this.geomJson &&
          other.minLat == this.minLat &&
          other.minLon == this.minLon &&
          other.maxLat == this.maxLat &&
          other.maxLon == this.maxLon);
}

class UsfsRoadsCompanion extends UpdateCompanion<UsfsRoad> {
  final Value<String> id;
  final Value<String> routeId;
  final Value<String> number;
  final Value<String?> name;
  final Value<String> kind;
  final Value<int> symbol;
  final Value<String?> symbolName;
  final Value<bool> seasonal;
  final Value<String?> surface;
  final Value<String?> maintLevel;
  final Value<String> accessJson;
  final Value<double?> lengthMi;
  final Value<String> geomJson;
  final Value<double> minLat;
  final Value<double> minLon;
  final Value<double> maxLat;
  final Value<double> maxLon;
  final Value<int> rowid;
  const UsfsRoadsCompanion({
    this.id = const Value.absent(),
    this.routeId = const Value.absent(),
    this.number = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.symbol = const Value.absent(),
    this.symbolName = const Value.absent(),
    this.seasonal = const Value.absent(),
    this.surface = const Value.absent(),
    this.maintLevel = const Value.absent(),
    this.accessJson = const Value.absent(),
    this.lengthMi = const Value.absent(),
    this.geomJson = const Value.absent(),
    this.minLat = const Value.absent(),
    this.minLon = const Value.absent(),
    this.maxLat = const Value.absent(),
    this.maxLon = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsfsRoadsCompanion.insert({
    required String id,
    required String routeId,
    required String number,
    this.name = const Value.absent(),
    required String kind,
    required int symbol,
    this.symbolName = const Value.absent(),
    this.seasonal = const Value.absent(),
    this.surface = const Value.absent(),
    this.maintLevel = const Value.absent(),
    this.accessJson = const Value.absent(),
    this.lengthMi = const Value.absent(),
    required String geomJson,
    required double minLat,
    required double minLon,
    required double maxLat,
    required double maxLon,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        routeId = Value(routeId),
        number = Value(number),
        kind = Value(kind),
        symbol = Value(symbol),
        geomJson = Value(geomJson),
        minLat = Value(minLat),
        minLon = Value(minLon),
        maxLat = Value(maxLat),
        maxLon = Value(maxLon);
  static Insertable<UsfsRoad> custom({
    Expression<String>? id,
    Expression<String>? routeId,
    Expression<String>? number,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<int>? symbol,
    Expression<String>? symbolName,
    Expression<bool>? seasonal,
    Expression<String>? surface,
    Expression<String>? maintLevel,
    Expression<String>? accessJson,
    Expression<double>? lengthMi,
    Expression<String>? geomJson,
    Expression<double>? minLat,
    Expression<double>? minLon,
    Expression<double>? maxLat,
    Expression<double>? maxLon,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (routeId != null) 'route_id': routeId,
      if (number != null) 'number': number,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (symbol != null) 'symbol': symbol,
      if (symbolName != null) 'symbol_name': symbolName,
      if (seasonal != null) 'seasonal': seasonal,
      if (surface != null) 'surface': surface,
      if (maintLevel != null) 'maint_level': maintLevel,
      if (accessJson != null) 'access_json': accessJson,
      if (lengthMi != null) 'length_mi': lengthMi,
      if (geomJson != null) 'geom_json': geomJson,
      if (minLat != null) 'min_lat': minLat,
      if (minLon != null) 'min_lon': minLon,
      if (maxLat != null) 'max_lat': maxLat,
      if (maxLon != null) 'max_lon': maxLon,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsfsRoadsCompanion copyWith(
      {Value<String>? id,
      Value<String>? routeId,
      Value<String>? number,
      Value<String?>? name,
      Value<String>? kind,
      Value<int>? symbol,
      Value<String?>? symbolName,
      Value<bool>? seasonal,
      Value<String?>? surface,
      Value<String?>? maintLevel,
      Value<String>? accessJson,
      Value<double?>? lengthMi,
      Value<String>? geomJson,
      Value<double>? minLat,
      Value<double>? minLon,
      Value<double>? maxLat,
      Value<double>? maxLon,
      Value<int>? rowid}) {
    return UsfsRoadsCompanion(
      id: id ?? this.id,
      routeId: routeId ?? this.routeId,
      number: number ?? this.number,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      symbol: symbol ?? this.symbol,
      symbolName: symbolName ?? this.symbolName,
      seasonal: seasonal ?? this.seasonal,
      surface: surface ?? this.surface,
      maintLevel: maintLevel ?? this.maintLevel,
      accessJson: accessJson ?? this.accessJson,
      lengthMi: lengthMi ?? this.lengthMi,
      geomJson: geomJson ?? this.geomJson,
      minLat: minLat ?? this.minLat,
      minLon: minLon ?? this.minLon,
      maxLat: maxLat ?? this.maxLat,
      maxLon: maxLon ?? this.maxLon,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (routeId.present) {
      map['route_id'] = Variable<String>(routeId.value);
    }
    if (number.present) {
      map['number'] = Variable<String>(number.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (symbol.present) {
      map['symbol'] = Variable<int>(symbol.value);
    }
    if (symbolName.present) {
      map['symbol_name'] = Variable<String>(symbolName.value);
    }
    if (seasonal.present) {
      map['seasonal'] = Variable<bool>(seasonal.value);
    }
    if (surface.present) {
      map['surface'] = Variable<String>(surface.value);
    }
    if (maintLevel.present) {
      map['maint_level'] = Variable<String>(maintLevel.value);
    }
    if (accessJson.present) {
      map['access_json'] = Variable<String>(accessJson.value);
    }
    if (lengthMi.present) {
      map['length_mi'] = Variable<double>(lengthMi.value);
    }
    if (geomJson.present) {
      map['geom_json'] = Variable<String>(geomJson.value);
    }
    if (minLat.present) {
      map['min_lat'] = Variable<double>(minLat.value);
    }
    if (minLon.present) {
      map['min_lon'] = Variable<double>(minLon.value);
    }
    if (maxLat.present) {
      map['max_lat'] = Variable<double>(maxLat.value);
    }
    if (maxLon.present) {
      map['max_lon'] = Variable<double>(maxLon.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsfsRoadsCompanion(')
          ..write('id: $id, ')
          ..write('routeId: $routeId, ')
          ..write('number: $number, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('symbol: $symbol, ')
          ..write('symbolName: $symbolName, ')
          ..write('seasonal: $seasonal, ')
          ..write('surface: $surface, ')
          ..write('maintLevel: $maintLevel, ')
          ..write('accessJson: $accessJson, ')
          ..write('lengthMi: $lengthMi, ')
          ..write('geomJson: $geomJson, ')
          ..write('minLat: $minLat, ')
          ..write('minLon: $minLon, ')
          ..write('maxLat: $maxLat, ')
          ..write('maxLon: $maxLon, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RoutesTable extends Routes with TableInfo<$RoutesTable, Route> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoutesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _geomJsonMeta =
      const VerificationMeta('geomJson');
  @override
  late final GeneratedColumn<String> geomJson = GeneratedColumn<String>(
      'geom_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _distanceMMeta =
      const VerificationMeta('distanceM');
  @override
  late final GeneratedColumn<double> distanceM = GeneratedColumn<double>(
      'distance_m', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _gainMMeta = const VerificationMeta('gainM');
  @override
  late final GeneratedColumn<double> gainM = GeneratedColumn<double>(
      'gain_m', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _lossMMeta = const VerificationMeta('lossM');
  @override
  late final GeneratedColumn<double> lossM = GeneratedColumn<double>(
      'loss_m', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _maxElevMMeta =
      const VerificationMeta('maxElevM');
  @override
  late final GeneratedColumn<double> maxElevM = GeneratedColumn<double>(
      'max_elev_m', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _minElevMMeta =
      const VerificationMeta('minElevM');
  @override
  late final GeneratedColumn<double> minElevM = GeneratedColumn<double>(
      'min_elev_m', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        createdAt,
        updatedAt,
        geomJson,
        distanceM,
        gainM,
        lossM,
        maxElevM,
        minElevM,
        notes
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'routes';
  @override
  VerificationContext validateIntegrity(Insertable<Route> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('geom_json')) {
      context.handle(_geomJsonMeta,
          geomJson.isAcceptableOrUnknown(data['geom_json']!, _geomJsonMeta));
    } else if (isInserting) {
      context.missing(_geomJsonMeta);
    }
    if (data.containsKey('distance_m')) {
      context.handle(_distanceMMeta,
          distanceM.isAcceptableOrUnknown(data['distance_m']!, _distanceMMeta));
    } else if (isInserting) {
      context.missing(_distanceMMeta);
    }
    if (data.containsKey('gain_m')) {
      context.handle(
          _gainMMeta, gainM.isAcceptableOrUnknown(data['gain_m']!, _gainMMeta));
    } else if (isInserting) {
      context.missing(_gainMMeta);
    }
    if (data.containsKey('loss_m')) {
      context.handle(
          _lossMMeta, lossM.isAcceptableOrUnknown(data['loss_m']!, _lossMMeta));
    } else if (isInserting) {
      context.missing(_lossMMeta);
    }
    if (data.containsKey('max_elev_m')) {
      context.handle(_maxElevMMeta,
          maxElevM.isAcceptableOrUnknown(data['max_elev_m']!, _maxElevMMeta));
    } else if (isInserting) {
      context.missing(_maxElevMMeta);
    }
    if (data.containsKey('min_elev_m')) {
      context.handle(_minElevMMeta,
          minElevM.isAcceptableOrUnknown(data['min_elev_m']!, _minElevMMeta));
    } else if (isInserting) {
      context.missing(_minElevMMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Route map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Route(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      geomJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}geom_json'])!,
      distanceM: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}distance_m'])!,
      gainM: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}gain_m'])!,
      lossM: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}loss_m'])!,
      maxElevM: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}max_elev_m'])!,
      minElevM: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}min_elev_m'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
    );
  }

  @override
  $RoutesTable createAlias(String alias) {
    return $RoutesTable(attachedDatabase, alias);
  }
}

class Route extends DataClass implements Insertable<Route> {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String geomJson;
  final double distanceM;
  final double gainM;
  final double lossM;
  final double maxElevM;
  final double minElevM;
  final String? notes;
  const Route(
      {required this.id,
      required this.name,
      required this.createdAt,
      required this.updatedAt,
      required this.geomJson,
      required this.distanceM,
      required this.gainM,
      required this.lossM,
      required this.maxElevM,
      required this.minElevM,
      this.notes});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['geom_json'] = Variable<String>(geomJson);
    map['distance_m'] = Variable<double>(distanceM);
    map['gain_m'] = Variable<double>(gainM);
    map['loss_m'] = Variable<double>(lossM);
    map['max_elev_m'] = Variable<double>(maxElevM);
    map['min_elev_m'] = Variable<double>(minElevM);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  RoutesCompanion toCompanion(bool nullToAbsent) {
    return RoutesCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      geomJson: Value(geomJson),
      distanceM: Value(distanceM),
      gainM: Value(gainM),
      lossM: Value(lossM),
      maxElevM: Value(maxElevM),
      minElevM: Value(minElevM),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
    );
  }

  factory Route.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Route(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      geomJson: serializer.fromJson<String>(json['geomJson']),
      distanceM: serializer.fromJson<double>(json['distanceM']),
      gainM: serializer.fromJson<double>(json['gainM']),
      lossM: serializer.fromJson<double>(json['lossM']),
      maxElevM: serializer.fromJson<double>(json['maxElevM']),
      minElevM: serializer.fromJson<double>(json['minElevM']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'geomJson': serializer.toJson<String>(geomJson),
      'distanceM': serializer.toJson<double>(distanceM),
      'gainM': serializer.toJson<double>(gainM),
      'lossM': serializer.toJson<double>(lossM),
      'maxElevM': serializer.toJson<double>(maxElevM),
      'minElevM': serializer.toJson<double>(minElevM),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  Route copyWith(
          {String? id,
          String? name,
          DateTime? createdAt,
          DateTime? updatedAt,
          String? geomJson,
          double? distanceM,
          double? gainM,
          double? lossM,
          double? maxElevM,
          double? minElevM,
          Value<String?> notes = const Value.absent()}) =>
      Route(
        id: id ?? this.id,
        name: name ?? this.name,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        geomJson: geomJson ?? this.geomJson,
        distanceM: distanceM ?? this.distanceM,
        gainM: gainM ?? this.gainM,
        lossM: lossM ?? this.lossM,
        maxElevM: maxElevM ?? this.maxElevM,
        minElevM: minElevM ?? this.minElevM,
        notes: notes.present ? notes.value : this.notes,
      );
  Route copyWithCompanion(RoutesCompanion data) {
    return Route(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      geomJson: data.geomJson.present ? data.geomJson.value : this.geomJson,
      distanceM: data.distanceM.present ? data.distanceM.value : this.distanceM,
      gainM: data.gainM.present ? data.gainM.value : this.gainM,
      lossM: data.lossM.present ? data.lossM.value : this.lossM,
      maxElevM: data.maxElevM.present ? data.maxElevM.value : this.maxElevM,
      minElevM: data.minElevM.present ? data.minElevM.value : this.minElevM,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Route(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('geomJson: $geomJson, ')
          ..write('distanceM: $distanceM, ')
          ..write('gainM: $gainM, ')
          ..write('lossM: $lossM, ')
          ..write('maxElevM: $maxElevM, ')
          ..write('minElevM: $minElevM, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, createdAt, updatedAt, geomJson,
      distanceM, gainM, lossM, maxElevM, minElevM, notes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Route &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.geomJson == this.geomJson &&
          other.distanceM == this.distanceM &&
          other.gainM == this.gainM &&
          other.lossM == this.lossM &&
          other.maxElevM == this.maxElevM &&
          other.minElevM == this.minElevM &&
          other.notes == this.notes);
}

class RoutesCompanion extends UpdateCompanion<Route> {
  final Value<String> id;
  final Value<String> name;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> geomJson;
  final Value<double> distanceM;
  final Value<double> gainM;
  final Value<double> lossM;
  final Value<double> maxElevM;
  final Value<double> minElevM;
  final Value<String?> notes;
  final Value<int> rowid;
  const RoutesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.geomJson = const Value.absent(),
    this.distanceM = const Value.absent(),
    this.gainM = const Value.absent(),
    this.lossM = const Value.absent(),
    this.maxElevM = const Value.absent(),
    this.minElevM = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RoutesCompanion.insert({
    required String id,
    required String name,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String geomJson,
    required double distanceM,
    required double gainM,
    required double lossM,
    required double maxElevM,
    required double minElevM,
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt),
        geomJson = Value(geomJson),
        distanceM = Value(distanceM),
        gainM = Value(gainM),
        lossM = Value(lossM),
        maxElevM = Value(maxElevM),
        minElevM = Value(minElevM);
  static Insertable<Route> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? geomJson,
    Expression<double>? distanceM,
    Expression<double>? gainM,
    Expression<double>? lossM,
    Expression<double>? maxElevM,
    Expression<double>? minElevM,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (geomJson != null) 'geom_json': geomJson,
      if (distanceM != null) 'distance_m': distanceM,
      if (gainM != null) 'gain_m': gainM,
      if (lossM != null) 'loss_m': lossM,
      if (maxElevM != null) 'max_elev_m': maxElevM,
      if (minElevM != null) 'min_elev_m': minElevM,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RoutesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<String>? geomJson,
      Value<double>? distanceM,
      Value<double>? gainM,
      Value<double>? lossM,
      Value<double>? maxElevM,
      Value<double>? minElevM,
      Value<String?>? notes,
      Value<int>? rowid}) {
    return RoutesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      geomJson: geomJson ?? this.geomJson,
      distanceM: distanceM ?? this.distanceM,
      gainM: gainM ?? this.gainM,
      lossM: lossM ?? this.lossM,
      maxElevM: maxElevM ?? this.maxElevM,
      minElevM: minElevM ?? this.minElevM,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (geomJson.present) {
      map['geom_json'] = Variable<String>(geomJson.value);
    }
    if (distanceM.present) {
      map['distance_m'] = Variable<double>(distanceM.value);
    }
    if (gainM.present) {
      map['gain_m'] = Variable<double>(gainM.value);
    }
    if (lossM.present) {
      map['loss_m'] = Variable<double>(lossM.value);
    }
    if (maxElevM.present) {
      map['max_elev_m'] = Variable<double>(maxElevM.value);
    }
    if (minElevM.present) {
      map['min_elev_m'] = Variable<double>(minElevM.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoutesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('geomJson: $geomJson, ')
          ..write('distanceM: $distanceM, ')
          ..write('gainM: $gainM, ')
          ..write('lossM: $lossM, ')
          ..write('maxElevM: $maxElevM, ')
          ..write('minElevM: $minElevM, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RouteWaypointsTable extends RouteWaypoints
    with TableInfo<$RouteWaypointsTable, RouteWaypoint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RouteWaypointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _routeIdMeta =
      const VerificationMeta('routeId');
  @override
  late final GeneratedColumn<String> routeId = GeneratedColumn<String>(
      'route_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES routes (id)'));
  static const VerificationMeta _ordinalMeta =
      const VerificationMeta('ordinal');
  @override
  late final GeneratedColumn<int> ordinal = GeneratedColumn<int>(
      'ordinal', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
      'lat', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _lonMeta = const VerificationMeta('lon');
  @override
  late final GeneratedColumn<double> lon = GeneratedColumn<double>(
      'lon', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
      'label', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [routeId, ordinal, lat, lon, label];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'route_waypoints';
  @override
  VerificationContext validateIntegrity(Insertable<RouteWaypoint> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('route_id')) {
      context.handle(_routeIdMeta,
          routeId.isAcceptableOrUnknown(data['route_id']!, _routeIdMeta));
    } else if (isInserting) {
      context.missing(_routeIdMeta);
    }
    if (data.containsKey('ordinal')) {
      context.handle(_ordinalMeta,
          ordinal.isAcceptableOrUnknown(data['ordinal']!, _ordinalMeta));
    } else if (isInserting) {
      context.missing(_ordinalMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
          _latMeta, lat.isAcceptableOrUnknown(data['lat']!, _latMeta));
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lon')) {
      context.handle(
          _lonMeta, lon.isAcceptableOrUnknown(data['lon']!, _lonMeta));
    } else if (isInserting) {
      context.missing(_lonMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
          _labelMeta, label.isAcceptableOrUnknown(data['label']!, _labelMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {routeId, ordinal};
  @override
  RouteWaypoint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RouteWaypoint(
      routeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}route_id'])!,
      ordinal: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}ordinal'])!,
      lat: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}lat'])!,
      lon: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}lon'])!,
      label: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}label']),
    );
  }

  @override
  $RouteWaypointsTable createAlias(String alias) {
    return $RouteWaypointsTable(attachedDatabase, alias);
  }
}

class RouteWaypoint extends DataClass implements Insertable<RouteWaypoint> {
  final String routeId;
  final int ordinal;
  final double lat;
  final double lon;
  final String? label;
  const RouteWaypoint(
      {required this.routeId,
      required this.ordinal,
      required this.lat,
      required this.lon,
      this.label});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['route_id'] = Variable<String>(routeId);
    map['ordinal'] = Variable<int>(ordinal);
    map['lat'] = Variable<double>(lat);
    map['lon'] = Variable<double>(lon);
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    return map;
  }

  RouteWaypointsCompanion toCompanion(bool nullToAbsent) {
    return RouteWaypointsCompanion(
      routeId: Value(routeId),
      ordinal: Value(ordinal),
      lat: Value(lat),
      lon: Value(lon),
      label:
          label == null && nullToAbsent ? const Value.absent() : Value(label),
    );
  }

  factory RouteWaypoint.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RouteWaypoint(
      routeId: serializer.fromJson<String>(json['routeId']),
      ordinal: serializer.fromJson<int>(json['ordinal']),
      lat: serializer.fromJson<double>(json['lat']),
      lon: serializer.fromJson<double>(json['lon']),
      label: serializer.fromJson<String?>(json['label']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'routeId': serializer.toJson<String>(routeId),
      'ordinal': serializer.toJson<int>(ordinal),
      'lat': serializer.toJson<double>(lat),
      'lon': serializer.toJson<double>(lon),
      'label': serializer.toJson<String?>(label),
    };
  }

  RouteWaypoint copyWith(
          {String? routeId,
          int? ordinal,
          double? lat,
          double? lon,
          Value<String?> label = const Value.absent()}) =>
      RouteWaypoint(
        routeId: routeId ?? this.routeId,
        ordinal: ordinal ?? this.ordinal,
        lat: lat ?? this.lat,
        lon: lon ?? this.lon,
        label: label.present ? label.value : this.label,
      );
  RouteWaypoint copyWithCompanion(RouteWaypointsCompanion data) {
    return RouteWaypoint(
      routeId: data.routeId.present ? data.routeId.value : this.routeId,
      ordinal: data.ordinal.present ? data.ordinal.value : this.ordinal,
      lat: data.lat.present ? data.lat.value : this.lat,
      lon: data.lon.present ? data.lon.value : this.lon,
      label: data.label.present ? data.label.value : this.label,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RouteWaypoint(')
          ..write('routeId: $routeId, ')
          ..write('ordinal: $ordinal, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('label: $label')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(routeId, ordinal, lat, lon, label);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RouteWaypoint &&
          other.routeId == this.routeId &&
          other.ordinal == this.ordinal &&
          other.lat == this.lat &&
          other.lon == this.lon &&
          other.label == this.label);
}

class RouteWaypointsCompanion extends UpdateCompanion<RouteWaypoint> {
  final Value<String> routeId;
  final Value<int> ordinal;
  final Value<double> lat;
  final Value<double> lon;
  final Value<String?> label;
  final Value<int> rowid;
  const RouteWaypointsCompanion({
    this.routeId = const Value.absent(),
    this.ordinal = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
    this.label = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RouteWaypointsCompanion.insert({
    required String routeId,
    required int ordinal,
    required double lat,
    required double lon,
    this.label = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : routeId = Value(routeId),
        ordinal = Value(ordinal),
        lat = Value(lat),
        lon = Value(lon);
  static Insertable<RouteWaypoint> custom({
    Expression<String>? routeId,
    Expression<int>? ordinal,
    Expression<double>? lat,
    Expression<double>? lon,
    Expression<String>? label,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (routeId != null) 'route_id': routeId,
      if (ordinal != null) 'ordinal': ordinal,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      if (label != null) 'label': label,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RouteWaypointsCompanion copyWith(
      {Value<String>? routeId,
      Value<int>? ordinal,
      Value<double>? lat,
      Value<double>? lon,
      Value<String?>? label,
      Value<int>? rowid}) {
    return RouteWaypointsCompanion(
      routeId: routeId ?? this.routeId,
      ordinal: ordinal ?? this.ordinal,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      label: label ?? this.label,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (routeId.present) {
      map['route_id'] = Variable<String>(routeId.value);
    }
    if (ordinal.present) {
      map['ordinal'] = Variable<int>(ordinal.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lon.present) {
      map['lon'] = Variable<double>(lon.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RouteWaypointsCompanion(')
          ..write('routeId: $routeId, ')
          ..write('ordinal: $ordinal, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('label: $label, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TracksTable extends Tracks with TableInfo<$TracksTable, Track> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TracksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _startedAtMeta =
      const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
      'started_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endedAtMeta =
      const VerificationMeta('endedAt');
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
      'ended_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _distanceMMeta =
      const VerificationMeta('distanceM');
  @override
  late final GeneratedColumn<double> distanceM = GeneratedColumn<double>(
      'distance_m', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _movingSecondsMeta =
      const VerificationMeta('movingSeconds');
  @override
  late final GeneratedColumn<int> movingSeconds = GeneratedColumn<int>(
      'moving_seconds', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _totalSecondsMeta =
      const VerificationMeta('totalSeconds');
  @override
  late final GeneratedColumn<int> totalSeconds = GeneratedColumn<int>(
      'total_seconds', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _gainMMeta = const VerificationMeta('gainM');
  @override
  late final GeneratedColumn<double> gainM = GeneratedColumn<double>(
      'gain_m', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lossMMeta = const VerificationMeta('lossM');
  @override
  late final GeneratedColumn<double> lossM = GeneratedColumn<double>(
      'loss_m', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _packWeightKgMeta =
      const VerificationMeta('packWeightKg');
  @override
  late final GeneratedColumn<double> packWeightKg = GeneratedColumn<double>(
      'pack_weight_kg', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _caloriesMeta =
      const VerificationMeta('calories');
  @override
  late final GeneratedColumn<double> calories = GeneratedColumn<double>(
      'calories', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _linkedRouteIdMeta =
      const VerificationMeta('linkedRouteId');
  @override
  late final GeneratedColumn<String> linkedRouteId = GeneratedColumn<String>(
      'linked_route_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastModifiedMeta =
      const VerificationMeta('lastModified');
  @override
  late final GeneratedColumn<DateTime> lastModified = GeneratedColumn<DateTime>(
      'last_modified', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _batteryStartPctMeta =
      const VerificationMeta('batteryStartPct');
  @override
  late final GeneratedColumn<int> batteryStartPct = GeneratedColumn<int>(
      'battery_start_pct', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _batteryEndPctMeta =
      const VerificationMeta('batteryEndPct');
  @override
  late final GeneratedColumn<int> batteryEndPct = GeneratedColumn<int>(
      'battery_end_pct', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        startedAt,
        endedAt,
        distanceM,
        movingSeconds,
        totalSeconds,
        gainM,
        lossM,
        packWeightKg,
        calories,
        linkedRouteId,
        lastModified,
        batteryStartPct,
        batteryEndPct
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tracks';
  @override
  VerificationContext validateIntegrity(Insertable<Track> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(_startedAtMeta,
          startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(_endedAtMeta,
          endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta));
    }
    if (data.containsKey('distance_m')) {
      context.handle(_distanceMMeta,
          distanceM.isAcceptableOrUnknown(data['distance_m']!, _distanceMMeta));
    }
    if (data.containsKey('moving_seconds')) {
      context.handle(
          _movingSecondsMeta,
          movingSeconds.isAcceptableOrUnknown(
              data['moving_seconds']!, _movingSecondsMeta));
    }
    if (data.containsKey('total_seconds')) {
      context.handle(
          _totalSecondsMeta,
          totalSeconds.isAcceptableOrUnknown(
              data['total_seconds']!, _totalSecondsMeta));
    }
    if (data.containsKey('gain_m')) {
      context.handle(
          _gainMMeta, gainM.isAcceptableOrUnknown(data['gain_m']!, _gainMMeta));
    }
    if (data.containsKey('loss_m')) {
      context.handle(
          _lossMMeta, lossM.isAcceptableOrUnknown(data['loss_m']!, _lossMMeta));
    }
    if (data.containsKey('pack_weight_kg')) {
      context.handle(
          _packWeightKgMeta,
          packWeightKg.isAcceptableOrUnknown(
              data['pack_weight_kg']!, _packWeightKgMeta));
    }
    if (data.containsKey('calories')) {
      context.handle(_caloriesMeta,
          calories.isAcceptableOrUnknown(data['calories']!, _caloriesMeta));
    }
    if (data.containsKey('linked_route_id')) {
      context.handle(
          _linkedRouteIdMeta,
          linkedRouteId.isAcceptableOrUnknown(
              data['linked_route_id']!, _linkedRouteIdMeta));
    }
    if (data.containsKey('last_modified')) {
      context.handle(
          _lastModifiedMeta,
          lastModified.isAcceptableOrUnknown(
              data['last_modified']!, _lastModifiedMeta));
    }
    if (data.containsKey('battery_start_pct')) {
      context.handle(
          _batteryStartPctMeta,
          batteryStartPct.isAcceptableOrUnknown(
              data['battery_start_pct']!, _batteryStartPctMeta));
    }
    if (data.containsKey('battery_end_pct')) {
      context.handle(
          _batteryEndPctMeta,
          batteryEndPct.isAcceptableOrUnknown(
              data['battery_end_pct']!, _batteryEndPctMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Track map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Track(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      startedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}started_at'])!,
      endedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}ended_at']),
      distanceM: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}distance_m'])!,
      movingSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}moving_seconds'])!,
      totalSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_seconds'])!,
      gainM: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}gain_m'])!,
      lossM: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}loss_m'])!,
      packWeightKg: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}pack_weight_kg']),
      calories: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}calories']),
      linkedRouteId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}linked_route_id']),
      lastModified: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_modified'])!,
      batteryStartPct: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}battery_start_pct']),
      batteryEndPct: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}battery_end_pct']),
    );
  }

  @override
  $TracksTable createAlias(String alias) {
    return $TracksTable(attachedDatabase, alias);
  }
}

class Track extends DataClass implements Insertable<Track> {
  final String id;
  final String name;
  final DateTime startedAt;
  final DateTime? endedAt;
  final double distanceM;
  final int movingSeconds;
  final int totalSeconds;
  final double gainM;
  final double lossM;
  final double? packWeightKg;
  final double? calories;
  final String? linkedRouteId;
  final DateTime lastModified;
  final int? batteryStartPct;
  final int? batteryEndPct;
  const Track(
      {required this.id,
      required this.name,
      required this.startedAt,
      this.endedAt,
      required this.distanceM,
      required this.movingSeconds,
      required this.totalSeconds,
      required this.gainM,
      required this.lossM,
      this.packWeightKg,
      this.calories,
      this.linkedRouteId,
      required this.lastModified,
      this.batteryStartPct,
      this.batteryEndPct});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['distance_m'] = Variable<double>(distanceM);
    map['moving_seconds'] = Variable<int>(movingSeconds);
    map['total_seconds'] = Variable<int>(totalSeconds);
    map['gain_m'] = Variable<double>(gainM);
    map['loss_m'] = Variable<double>(lossM);
    if (!nullToAbsent || packWeightKg != null) {
      map['pack_weight_kg'] = Variable<double>(packWeightKg);
    }
    if (!nullToAbsent || calories != null) {
      map['calories'] = Variable<double>(calories);
    }
    if (!nullToAbsent || linkedRouteId != null) {
      map['linked_route_id'] = Variable<String>(linkedRouteId);
    }
    map['last_modified'] = Variable<DateTime>(lastModified);
    if (!nullToAbsent || batteryStartPct != null) {
      map['battery_start_pct'] = Variable<int>(batteryStartPct);
    }
    if (!nullToAbsent || batteryEndPct != null) {
      map['battery_end_pct'] = Variable<int>(batteryEndPct);
    }
    return map;
  }

  TracksCompanion toCompanion(bool nullToAbsent) {
    return TracksCompanion(
      id: Value(id),
      name: Value(name),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      distanceM: Value(distanceM),
      movingSeconds: Value(movingSeconds),
      totalSeconds: Value(totalSeconds),
      gainM: Value(gainM),
      lossM: Value(lossM),
      packWeightKg: packWeightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(packWeightKg),
      calories: calories == null && nullToAbsent
          ? const Value.absent()
          : Value(calories),
      linkedRouteId: linkedRouteId == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedRouteId),
      lastModified: Value(lastModified),
      batteryStartPct: batteryStartPct == null && nullToAbsent
          ? const Value.absent()
          : Value(batteryStartPct),
      batteryEndPct: batteryEndPct == null && nullToAbsent
          ? const Value.absent()
          : Value(batteryEndPct),
    );
  }

  factory Track.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Track(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      distanceM: serializer.fromJson<double>(json['distanceM']),
      movingSeconds: serializer.fromJson<int>(json['movingSeconds']),
      totalSeconds: serializer.fromJson<int>(json['totalSeconds']),
      gainM: serializer.fromJson<double>(json['gainM']),
      lossM: serializer.fromJson<double>(json['lossM']),
      packWeightKg: serializer.fromJson<double?>(json['packWeightKg']),
      calories: serializer.fromJson<double?>(json['calories']),
      linkedRouteId: serializer.fromJson<String?>(json['linkedRouteId']),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
      batteryStartPct: serializer.fromJson<int?>(json['batteryStartPct']),
      batteryEndPct: serializer.fromJson<int?>(json['batteryEndPct']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'distanceM': serializer.toJson<double>(distanceM),
      'movingSeconds': serializer.toJson<int>(movingSeconds),
      'totalSeconds': serializer.toJson<int>(totalSeconds),
      'gainM': serializer.toJson<double>(gainM),
      'lossM': serializer.toJson<double>(lossM),
      'packWeightKg': serializer.toJson<double?>(packWeightKg),
      'calories': serializer.toJson<double?>(calories),
      'linkedRouteId': serializer.toJson<String?>(linkedRouteId),
      'lastModified': serializer.toJson<DateTime>(lastModified),
      'batteryStartPct': serializer.toJson<int?>(batteryStartPct),
      'batteryEndPct': serializer.toJson<int?>(batteryEndPct),
    };
  }

  Track copyWith(
          {String? id,
          String? name,
          DateTime? startedAt,
          Value<DateTime?> endedAt = const Value.absent(),
          double? distanceM,
          int? movingSeconds,
          int? totalSeconds,
          double? gainM,
          double? lossM,
          Value<double?> packWeightKg = const Value.absent(),
          Value<double?> calories = const Value.absent(),
          Value<String?> linkedRouteId = const Value.absent(),
          DateTime? lastModified,
          Value<int?> batteryStartPct = const Value.absent(),
          Value<int?> batteryEndPct = const Value.absent()}) =>
      Track(
        id: id ?? this.id,
        name: name ?? this.name,
        startedAt: startedAt ?? this.startedAt,
        endedAt: endedAt.present ? endedAt.value : this.endedAt,
        distanceM: distanceM ?? this.distanceM,
        movingSeconds: movingSeconds ?? this.movingSeconds,
        totalSeconds: totalSeconds ?? this.totalSeconds,
        gainM: gainM ?? this.gainM,
        lossM: lossM ?? this.lossM,
        packWeightKg:
            packWeightKg.present ? packWeightKg.value : this.packWeightKg,
        calories: calories.present ? calories.value : this.calories,
        linkedRouteId:
            linkedRouteId.present ? linkedRouteId.value : this.linkedRouteId,
        lastModified: lastModified ?? this.lastModified,
        batteryStartPct: batteryStartPct.present
            ? batteryStartPct.value
            : this.batteryStartPct,
        batteryEndPct:
            batteryEndPct.present ? batteryEndPct.value : this.batteryEndPct,
      );
  Track copyWithCompanion(TracksCompanion data) {
    return Track(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      distanceM: data.distanceM.present ? data.distanceM.value : this.distanceM,
      movingSeconds: data.movingSeconds.present
          ? data.movingSeconds.value
          : this.movingSeconds,
      totalSeconds: data.totalSeconds.present
          ? data.totalSeconds.value
          : this.totalSeconds,
      gainM: data.gainM.present ? data.gainM.value : this.gainM,
      lossM: data.lossM.present ? data.lossM.value : this.lossM,
      packWeightKg: data.packWeightKg.present
          ? data.packWeightKg.value
          : this.packWeightKg,
      calories: data.calories.present ? data.calories.value : this.calories,
      linkedRouteId: data.linkedRouteId.present
          ? data.linkedRouteId.value
          : this.linkedRouteId,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
      batteryStartPct: data.batteryStartPct.present
          ? data.batteryStartPct.value
          : this.batteryStartPct,
      batteryEndPct: data.batteryEndPct.present
          ? data.batteryEndPct.value
          : this.batteryEndPct,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Track(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('distanceM: $distanceM, ')
          ..write('movingSeconds: $movingSeconds, ')
          ..write('totalSeconds: $totalSeconds, ')
          ..write('gainM: $gainM, ')
          ..write('lossM: $lossM, ')
          ..write('packWeightKg: $packWeightKg, ')
          ..write('calories: $calories, ')
          ..write('linkedRouteId: $linkedRouteId, ')
          ..write('lastModified: $lastModified, ')
          ..write('batteryStartPct: $batteryStartPct, ')
          ..write('batteryEndPct: $batteryEndPct')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      startedAt,
      endedAt,
      distanceM,
      movingSeconds,
      totalSeconds,
      gainM,
      lossM,
      packWeightKg,
      calories,
      linkedRouteId,
      lastModified,
      batteryStartPct,
      batteryEndPct);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Track &&
          other.id == this.id &&
          other.name == this.name &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.distanceM == this.distanceM &&
          other.movingSeconds == this.movingSeconds &&
          other.totalSeconds == this.totalSeconds &&
          other.gainM == this.gainM &&
          other.lossM == this.lossM &&
          other.packWeightKg == this.packWeightKg &&
          other.calories == this.calories &&
          other.linkedRouteId == this.linkedRouteId &&
          other.lastModified == this.lastModified &&
          other.batteryStartPct == this.batteryStartPct &&
          other.batteryEndPct == this.batteryEndPct);
}

class TracksCompanion extends UpdateCompanion<Track> {
  final Value<String> id;
  final Value<String> name;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<double> distanceM;
  final Value<int> movingSeconds;
  final Value<int> totalSeconds;
  final Value<double> gainM;
  final Value<double> lossM;
  final Value<double?> packWeightKg;
  final Value<double?> calories;
  final Value<String?> linkedRouteId;
  final Value<DateTime> lastModified;
  final Value<int?> batteryStartPct;
  final Value<int?> batteryEndPct;
  final Value<int> rowid;
  const TracksCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.distanceM = const Value.absent(),
    this.movingSeconds = const Value.absent(),
    this.totalSeconds = const Value.absent(),
    this.gainM = const Value.absent(),
    this.lossM = const Value.absent(),
    this.packWeightKg = const Value.absent(),
    this.calories = const Value.absent(),
    this.linkedRouteId = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.batteryStartPct = const Value.absent(),
    this.batteryEndPct = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TracksCompanion.insert({
    required String id,
    required String name,
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    this.distanceM = const Value.absent(),
    this.movingSeconds = const Value.absent(),
    this.totalSeconds = const Value.absent(),
    this.gainM = const Value.absent(),
    this.lossM = const Value.absent(),
    this.packWeightKg = const Value.absent(),
    this.calories = const Value.absent(),
    this.linkedRouteId = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.batteryStartPct = const Value.absent(),
    this.batteryEndPct = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        startedAt = Value(startedAt);
  static Insertable<Track> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<double>? distanceM,
    Expression<int>? movingSeconds,
    Expression<int>? totalSeconds,
    Expression<double>? gainM,
    Expression<double>? lossM,
    Expression<double>? packWeightKg,
    Expression<double>? calories,
    Expression<String>? linkedRouteId,
    Expression<DateTime>? lastModified,
    Expression<int>? batteryStartPct,
    Expression<int>? batteryEndPct,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (distanceM != null) 'distance_m': distanceM,
      if (movingSeconds != null) 'moving_seconds': movingSeconds,
      if (totalSeconds != null) 'total_seconds': totalSeconds,
      if (gainM != null) 'gain_m': gainM,
      if (lossM != null) 'loss_m': lossM,
      if (packWeightKg != null) 'pack_weight_kg': packWeightKg,
      if (calories != null) 'calories': calories,
      if (linkedRouteId != null) 'linked_route_id': linkedRouteId,
      if (lastModified != null) 'last_modified': lastModified,
      if (batteryStartPct != null) 'battery_start_pct': batteryStartPct,
      if (batteryEndPct != null) 'battery_end_pct': batteryEndPct,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TracksCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<DateTime>? startedAt,
      Value<DateTime?>? endedAt,
      Value<double>? distanceM,
      Value<int>? movingSeconds,
      Value<int>? totalSeconds,
      Value<double>? gainM,
      Value<double>? lossM,
      Value<double?>? packWeightKg,
      Value<double?>? calories,
      Value<String?>? linkedRouteId,
      Value<DateTime>? lastModified,
      Value<int?>? batteryStartPct,
      Value<int?>? batteryEndPct,
      Value<int>? rowid}) {
    return TracksCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      distanceM: distanceM ?? this.distanceM,
      movingSeconds: movingSeconds ?? this.movingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      gainM: gainM ?? this.gainM,
      lossM: lossM ?? this.lossM,
      packWeightKg: packWeightKg ?? this.packWeightKg,
      calories: calories ?? this.calories,
      linkedRouteId: linkedRouteId ?? this.linkedRouteId,
      lastModified: lastModified ?? this.lastModified,
      batteryStartPct: batteryStartPct ?? this.batteryStartPct,
      batteryEndPct: batteryEndPct ?? this.batteryEndPct,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (distanceM.present) {
      map['distance_m'] = Variable<double>(distanceM.value);
    }
    if (movingSeconds.present) {
      map['moving_seconds'] = Variable<int>(movingSeconds.value);
    }
    if (totalSeconds.present) {
      map['total_seconds'] = Variable<int>(totalSeconds.value);
    }
    if (gainM.present) {
      map['gain_m'] = Variable<double>(gainM.value);
    }
    if (lossM.present) {
      map['loss_m'] = Variable<double>(lossM.value);
    }
    if (packWeightKg.present) {
      map['pack_weight_kg'] = Variable<double>(packWeightKg.value);
    }
    if (calories.present) {
      map['calories'] = Variable<double>(calories.value);
    }
    if (linkedRouteId.present) {
      map['linked_route_id'] = Variable<String>(linkedRouteId.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(lastModified.value);
    }
    if (batteryStartPct.present) {
      map['battery_start_pct'] = Variable<int>(batteryStartPct.value);
    }
    if (batteryEndPct.present) {
      map['battery_end_pct'] = Variable<int>(batteryEndPct.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TracksCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('distanceM: $distanceM, ')
          ..write('movingSeconds: $movingSeconds, ')
          ..write('totalSeconds: $totalSeconds, ')
          ..write('gainM: $gainM, ')
          ..write('lossM: $lossM, ')
          ..write('packWeightKg: $packWeightKg, ')
          ..write('calories: $calories, ')
          ..write('linkedRouteId: $linkedRouteId, ')
          ..write('lastModified: $lastModified, ')
          ..write('batteryStartPct: $batteryStartPct, ')
          ..write('batteryEndPct: $batteryEndPct, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TrackPointsTable extends TrackPoints
    with TableInfo<$TrackPointsTable, TrackPoint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrackPointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _trackIdMeta =
      const VerificationMeta('trackId');
  @override
  late final GeneratedColumn<String> trackId = GeneratedColumn<String>(
      'track_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES tracks (id)'));
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
      'seq', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _tMeta = const VerificationMeta('t');
  @override
  late final GeneratedColumn<DateTime> t = GeneratedColumn<DateTime>(
      't', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
      'lat', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _lonMeta = const VerificationMeta('lon');
  @override
  late final GeneratedColumn<double> lon = GeneratedColumn<double>(
      'lon', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _gpsAltMMeta =
      const VerificationMeta('gpsAltM');
  @override
  late final GeneratedColumn<double> gpsAltM = GeneratedColumn<double>(
      'gps_alt_m', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _demAltMMeta =
      const VerificationMeta('demAltM');
  @override
  late final GeneratedColumn<double> demAltM = GeneratedColumn<double>(
      'dem_alt_m', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _accuracyMMeta =
      const VerificationMeta('accuracyM');
  @override
  late final GeneratedColumn<double> accuracyM = GeneratedColumn<double>(
      'accuracy_m', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _speedMpsMeta =
      const VerificationMeta('speedMps');
  @override
  late final GeneratedColumn<double> speedMps = GeneratedColumn<double>(
      'speed_mps', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [trackId, seq, t, lat, lon, gpsAltM, demAltM, accuracyM, speedMps];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'track_points';
  @override
  VerificationContext validateIntegrity(Insertable<TrackPoint> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('track_id')) {
      context.handle(_trackIdMeta,
          trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta));
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
          _seqMeta, seq.isAcceptableOrUnknown(data['seq']!, _seqMeta));
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    if (data.containsKey('t')) {
      context.handle(_tMeta, t.isAcceptableOrUnknown(data['t']!, _tMeta));
    } else if (isInserting) {
      context.missing(_tMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
          _latMeta, lat.isAcceptableOrUnknown(data['lat']!, _latMeta));
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lon')) {
      context.handle(
          _lonMeta, lon.isAcceptableOrUnknown(data['lon']!, _lonMeta));
    } else if (isInserting) {
      context.missing(_lonMeta);
    }
    if (data.containsKey('gps_alt_m')) {
      context.handle(_gpsAltMMeta,
          gpsAltM.isAcceptableOrUnknown(data['gps_alt_m']!, _gpsAltMMeta));
    }
    if (data.containsKey('dem_alt_m')) {
      context.handle(_demAltMMeta,
          demAltM.isAcceptableOrUnknown(data['dem_alt_m']!, _demAltMMeta));
    }
    if (data.containsKey('accuracy_m')) {
      context.handle(_accuracyMMeta,
          accuracyM.isAcceptableOrUnknown(data['accuracy_m']!, _accuracyMMeta));
    }
    if (data.containsKey('speed_mps')) {
      context.handle(_speedMpsMeta,
          speedMps.isAcceptableOrUnknown(data['speed_mps']!, _speedMpsMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {trackId, seq};
  @override
  TrackPoint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrackPoint(
      trackId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}track_id'])!,
      seq: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}seq'])!,
      t: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}t'])!,
      lat: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}lat'])!,
      lon: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}lon'])!,
      gpsAltM: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}gps_alt_m']),
      demAltM: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}dem_alt_m']),
      accuracyM: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}accuracy_m']),
      speedMps: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}speed_mps']),
    );
  }

  @override
  $TrackPointsTable createAlias(String alias) {
    return $TrackPointsTable(attachedDatabase, alias);
  }
}

class TrackPoint extends DataClass implements Insertable<TrackPoint> {
  final String trackId;
  final int seq;
  final DateTime t;
  final double lat;
  final double lon;
  final double? gpsAltM;
  final double? demAltM;
  final double? accuracyM;
  final double? speedMps;
  const TrackPoint(
      {required this.trackId,
      required this.seq,
      required this.t,
      required this.lat,
      required this.lon,
      this.gpsAltM,
      this.demAltM,
      this.accuracyM,
      this.speedMps});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['track_id'] = Variable<String>(trackId);
    map['seq'] = Variable<int>(seq);
    map['t'] = Variable<DateTime>(t);
    map['lat'] = Variable<double>(lat);
    map['lon'] = Variable<double>(lon);
    if (!nullToAbsent || gpsAltM != null) {
      map['gps_alt_m'] = Variable<double>(gpsAltM);
    }
    if (!nullToAbsent || demAltM != null) {
      map['dem_alt_m'] = Variable<double>(demAltM);
    }
    if (!nullToAbsent || accuracyM != null) {
      map['accuracy_m'] = Variable<double>(accuracyM);
    }
    if (!nullToAbsent || speedMps != null) {
      map['speed_mps'] = Variable<double>(speedMps);
    }
    return map;
  }

  TrackPointsCompanion toCompanion(bool nullToAbsent) {
    return TrackPointsCompanion(
      trackId: Value(trackId),
      seq: Value(seq),
      t: Value(t),
      lat: Value(lat),
      lon: Value(lon),
      gpsAltM: gpsAltM == null && nullToAbsent
          ? const Value.absent()
          : Value(gpsAltM),
      demAltM: demAltM == null && nullToAbsent
          ? const Value.absent()
          : Value(demAltM),
      accuracyM: accuracyM == null && nullToAbsent
          ? const Value.absent()
          : Value(accuracyM),
      speedMps: speedMps == null && nullToAbsent
          ? const Value.absent()
          : Value(speedMps),
    );
  }

  factory TrackPoint.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrackPoint(
      trackId: serializer.fromJson<String>(json['trackId']),
      seq: serializer.fromJson<int>(json['seq']),
      t: serializer.fromJson<DateTime>(json['t']),
      lat: serializer.fromJson<double>(json['lat']),
      lon: serializer.fromJson<double>(json['lon']),
      gpsAltM: serializer.fromJson<double?>(json['gpsAltM']),
      demAltM: serializer.fromJson<double?>(json['demAltM']),
      accuracyM: serializer.fromJson<double?>(json['accuracyM']),
      speedMps: serializer.fromJson<double?>(json['speedMps']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'trackId': serializer.toJson<String>(trackId),
      'seq': serializer.toJson<int>(seq),
      't': serializer.toJson<DateTime>(t),
      'lat': serializer.toJson<double>(lat),
      'lon': serializer.toJson<double>(lon),
      'gpsAltM': serializer.toJson<double?>(gpsAltM),
      'demAltM': serializer.toJson<double?>(demAltM),
      'accuracyM': serializer.toJson<double?>(accuracyM),
      'speedMps': serializer.toJson<double?>(speedMps),
    };
  }

  TrackPoint copyWith(
          {String? trackId,
          int? seq,
          DateTime? t,
          double? lat,
          double? lon,
          Value<double?> gpsAltM = const Value.absent(),
          Value<double?> demAltM = const Value.absent(),
          Value<double?> accuracyM = const Value.absent(),
          Value<double?> speedMps = const Value.absent()}) =>
      TrackPoint(
        trackId: trackId ?? this.trackId,
        seq: seq ?? this.seq,
        t: t ?? this.t,
        lat: lat ?? this.lat,
        lon: lon ?? this.lon,
        gpsAltM: gpsAltM.present ? gpsAltM.value : this.gpsAltM,
        demAltM: demAltM.present ? demAltM.value : this.demAltM,
        accuracyM: accuracyM.present ? accuracyM.value : this.accuracyM,
        speedMps: speedMps.present ? speedMps.value : this.speedMps,
      );
  TrackPoint copyWithCompanion(TrackPointsCompanion data) {
    return TrackPoint(
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      seq: data.seq.present ? data.seq.value : this.seq,
      t: data.t.present ? data.t.value : this.t,
      lat: data.lat.present ? data.lat.value : this.lat,
      lon: data.lon.present ? data.lon.value : this.lon,
      gpsAltM: data.gpsAltM.present ? data.gpsAltM.value : this.gpsAltM,
      demAltM: data.demAltM.present ? data.demAltM.value : this.demAltM,
      accuracyM: data.accuracyM.present ? data.accuracyM.value : this.accuracyM,
      speedMps: data.speedMps.present ? data.speedMps.value : this.speedMps,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrackPoint(')
          ..write('trackId: $trackId, ')
          ..write('seq: $seq, ')
          ..write('t: $t, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('gpsAltM: $gpsAltM, ')
          ..write('demAltM: $demAltM, ')
          ..write('accuracyM: $accuracyM, ')
          ..write('speedMps: $speedMps')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      trackId, seq, t, lat, lon, gpsAltM, demAltM, accuracyM, speedMps);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrackPoint &&
          other.trackId == this.trackId &&
          other.seq == this.seq &&
          other.t == this.t &&
          other.lat == this.lat &&
          other.lon == this.lon &&
          other.gpsAltM == this.gpsAltM &&
          other.demAltM == this.demAltM &&
          other.accuracyM == this.accuracyM &&
          other.speedMps == this.speedMps);
}

class TrackPointsCompanion extends UpdateCompanion<TrackPoint> {
  final Value<String> trackId;
  final Value<int> seq;
  final Value<DateTime> t;
  final Value<double> lat;
  final Value<double> lon;
  final Value<double?> gpsAltM;
  final Value<double?> demAltM;
  final Value<double?> accuracyM;
  final Value<double?> speedMps;
  final Value<int> rowid;
  const TrackPointsCompanion({
    this.trackId = const Value.absent(),
    this.seq = const Value.absent(),
    this.t = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
    this.gpsAltM = const Value.absent(),
    this.demAltM = const Value.absent(),
    this.accuracyM = const Value.absent(),
    this.speedMps = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TrackPointsCompanion.insert({
    required String trackId,
    required int seq,
    required DateTime t,
    required double lat,
    required double lon,
    this.gpsAltM = const Value.absent(),
    this.demAltM = const Value.absent(),
    this.accuracyM = const Value.absent(),
    this.speedMps = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : trackId = Value(trackId),
        seq = Value(seq),
        t = Value(t),
        lat = Value(lat),
        lon = Value(lon);
  static Insertable<TrackPoint> custom({
    Expression<String>? trackId,
    Expression<int>? seq,
    Expression<DateTime>? t,
    Expression<double>? lat,
    Expression<double>? lon,
    Expression<double>? gpsAltM,
    Expression<double>? demAltM,
    Expression<double>? accuracyM,
    Expression<double>? speedMps,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (trackId != null) 'track_id': trackId,
      if (seq != null) 'seq': seq,
      if (t != null) 't': t,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      if (gpsAltM != null) 'gps_alt_m': gpsAltM,
      if (demAltM != null) 'dem_alt_m': demAltM,
      if (accuracyM != null) 'accuracy_m': accuracyM,
      if (speedMps != null) 'speed_mps': speedMps,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TrackPointsCompanion copyWith(
      {Value<String>? trackId,
      Value<int>? seq,
      Value<DateTime>? t,
      Value<double>? lat,
      Value<double>? lon,
      Value<double?>? gpsAltM,
      Value<double?>? demAltM,
      Value<double?>? accuracyM,
      Value<double?>? speedMps,
      Value<int>? rowid}) {
    return TrackPointsCompanion(
      trackId: trackId ?? this.trackId,
      seq: seq ?? this.seq,
      t: t ?? this.t,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      gpsAltM: gpsAltM ?? this.gpsAltM,
      demAltM: demAltM ?? this.demAltM,
      accuracyM: accuracyM ?? this.accuracyM,
      speedMps: speedMps ?? this.speedMps,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (trackId.present) {
      map['track_id'] = Variable<String>(trackId.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (t.present) {
      map['t'] = Variable<DateTime>(t.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lon.present) {
      map['lon'] = Variable<double>(lon.value);
    }
    if (gpsAltM.present) {
      map['gps_alt_m'] = Variable<double>(gpsAltM.value);
    }
    if (demAltM.present) {
      map['dem_alt_m'] = Variable<double>(demAltM.value);
    }
    if (accuracyM.present) {
      map['accuracy_m'] = Variable<double>(accuracyM.value);
    }
    if (speedMps.present) {
      map['speed_mps'] = Variable<double>(speedMps.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrackPointsCompanion(')
          ..write('trackId: $trackId, ')
          ..write('seq: $seq, ')
          ..write('t: $t, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('gpsAltM: $gpsAltM, ')
          ..write('demAltM: $demAltM, ')
          ..write('accuracyM: $accuracyM, ')
          ..write('speedMps: $speedMps, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OfflineRegionsTable extends OfflineRegions
    with TableInfo<$OfflineRegionsTable, OfflineRegion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OfflineRegionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _minLatMeta = const VerificationMeta('minLat');
  @override
  late final GeneratedColumn<double> minLat = GeneratedColumn<double>(
      'min_lat', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _minLonMeta = const VerificationMeta('minLon');
  @override
  late final GeneratedColumn<double> minLon = GeneratedColumn<double>(
      'min_lon', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _maxLatMeta = const VerificationMeta('maxLat');
  @override
  late final GeneratedColumn<double> maxLat = GeneratedColumn<double>(
      'max_lat', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _maxLonMeta = const VerificationMeta('maxLon');
  @override
  late final GeneratedColumn<double> maxLon = GeneratedColumn<double>(
      'max_lon', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _maplibreRegionIdMeta =
      const VerificationMeta('maplibreRegionId');
  @override
  late final GeneratedColumn<int> maplibreRegionId = GeneratedColumn<int>(
      'maplibre_region_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _styleKeyMeta =
      const VerificationMeta('styleKey');
  @override
  late final GeneratedColumn<String> styleKey = GeneratedColumn<String>(
      'style_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _minZoomMeta =
      const VerificationMeta('minZoom');
  @override
  late final GeneratedColumn<int> minZoom = GeneratedColumn<int>(
      'min_zoom', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _maxZoomMeta =
      const VerificationMeta('maxZoom');
  @override
  late final GeneratedColumn<int> maxZoom = GeneratedColumn<int>(
      'max_zoom', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
      'status', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _tileCountMeta =
      const VerificationMeta('tileCount');
  @override
  late final GeneratedColumn<int> tileCount = GeneratedColumn<int>(
      'tile_count', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _bytesMeta = const VerificationMeta('bytes');
  @override
  late final GeneratedColumn<int> bytes = GeneratedColumn<int>(
      'bytes', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _overlayKeysMeta =
      const VerificationMeta('overlayKeys');
  @override
  late final GeneratedColumn<String> overlayKeys = GeneratedColumn<String>(
      'overlay_keys', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        minLat,
        minLon,
        maxLat,
        maxLon,
        maplibreRegionId,
        styleKey,
        minZoom,
        maxZoom,
        createdAt,
        status,
        tileCount,
        bytes,
        overlayKeys
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'offline_regions';
  @override
  VerificationContext validateIntegrity(Insertable<OfflineRegion> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('min_lat')) {
      context.handle(_minLatMeta,
          minLat.isAcceptableOrUnknown(data['min_lat']!, _minLatMeta));
    } else if (isInserting) {
      context.missing(_minLatMeta);
    }
    if (data.containsKey('min_lon')) {
      context.handle(_minLonMeta,
          minLon.isAcceptableOrUnknown(data['min_lon']!, _minLonMeta));
    } else if (isInserting) {
      context.missing(_minLonMeta);
    }
    if (data.containsKey('max_lat')) {
      context.handle(_maxLatMeta,
          maxLat.isAcceptableOrUnknown(data['max_lat']!, _maxLatMeta));
    } else if (isInserting) {
      context.missing(_maxLatMeta);
    }
    if (data.containsKey('max_lon')) {
      context.handle(_maxLonMeta,
          maxLon.isAcceptableOrUnknown(data['max_lon']!, _maxLonMeta));
    } else if (isInserting) {
      context.missing(_maxLonMeta);
    }
    if (data.containsKey('maplibre_region_id')) {
      context.handle(
          _maplibreRegionIdMeta,
          maplibreRegionId.isAcceptableOrUnknown(
              data['maplibre_region_id']!, _maplibreRegionIdMeta));
    }
    if (data.containsKey('style_key')) {
      context.handle(_styleKeyMeta,
          styleKey.isAcceptableOrUnknown(data['style_key']!, _styleKeyMeta));
    } else if (isInserting) {
      context.missing(_styleKeyMeta);
    }
    if (data.containsKey('min_zoom')) {
      context.handle(_minZoomMeta,
          minZoom.isAcceptableOrUnknown(data['min_zoom']!, _minZoomMeta));
    } else if (isInserting) {
      context.missing(_minZoomMeta);
    }
    if (data.containsKey('max_zoom')) {
      context.handle(_maxZoomMeta,
          maxZoom.isAcceptableOrUnknown(data['max_zoom']!, _maxZoomMeta));
    } else if (isInserting) {
      context.missing(_maxZoomMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('tile_count')) {
      context.handle(_tileCountMeta,
          tileCount.isAcceptableOrUnknown(data['tile_count']!, _tileCountMeta));
    }
    if (data.containsKey('bytes')) {
      context.handle(
          _bytesMeta, bytes.isAcceptableOrUnknown(data['bytes']!, _bytesMeta));
    }
    if (data.containsKey('overlay_keys')) {
      context.handle(
          _overlayKeysMeta,
          overlayKeys.isAcceptableOrUnknown(
              data['overlay_keys']!, _overlayKeysMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OfflineRegion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OfflineRegion(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      minLat: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}min_lat'])!,
      minLon: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}min_lon'])!,
      maxLat: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}max_lat'])!,
      maxLon: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}max_lon'])!,
      maplibreRegionId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}maplibre_region_id']),
      styleKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}style_key'])!,
      minZoom: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}min_zoom'])!,
      maxZoom: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}max_zoom'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}status'])!,
      tileCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tile_count']),
      bytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}bytes']),
      overlayKeys: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}overlay_keys'])!,
    );
  }

  @override
  $OfflineRegionsTable createAlias(String alias) {
    return $OfflineRegionsTable(attachedDatabase, alias);
  }
}

class OfflineRegion extends DataClass implements Insertable<OfflineRegion> {
  final String id;
  final String name;
  final double minLat;
  final double minLon;
  final double maxLat;
  final double maxLon;
  final int? maplibreRegionId;
  final String styleKey;
  final int minZoom;
  final int maxZoom;
  final DateTime createdAt;
  final int status;
  final int? tileCount;
  final int? bytes;
  final String overlayKeys;
  const OfflineRegion(
      {required this.id,
      required this.name,
      required this.minLat,
      required this.minLon,
      required this.maxLat,
      required this.maxLon,
      this.maplibreRegionId,
      required this.styleKey,
      required this.minZoom,
      required this.maxZoom,
      required this.createdAt,
      required this.status,
      this.tileCount,
      this.bytes,
      required this.overlayKeys});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['min_lat'] = Variable<double>(minLat);
    map['min_lon'] = Variable<double>(minLon);
    map['max_lat'] = Variable<double>(maxLat);
    map['max_lon'] = Variable<double>(maxLon);
    if (!nullToAbsent || maplibreRegionId != null) {
      map['maplibre_region_id'] = Variable<int>(maplibreRegionId);
    }
    map['style_key'] = Variable<String>(styleKey);
    map['min_zoom'] = Variable<int>(minZoom);
    map['max_zoom'] = Variable<int>(maxZoom);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['status'] = Variable<int>(status);
    if (!nullToAbsent || tileCount != null) {
      map['tile_count'] = Variable<int>(tileCount);
    }
    if (!nullToAbsent || bytes != null) {
      map['bytes'] = Variable<int>(bytes);
    }
    map['overlay_keys'] = Variable<String>(overlayKeys);
    return map;
  }

  OfflineRegionsCompanion toCompanion(bool nullToAbsent) {
    return OfflineRegionsCompanion(
      id: Value(id),
      name: Value(name),
      minLat: Value(minLat),
      minLon: Value(minLon),
      maxLat: Value(maxLat),
      maxLon: Value(maxLon),
      maplibreRegionId: maplibreRegionId == null && nullToAbsent
          ? const Value.absent()
          : Value(maplibreRegionId),
      styleKey: Value(styleKey),
      minZoom: Value(minZoom),
      maxZoom: Value(maxZoom),
      createdAt: Value(createdAt),
      status: Value(status),
      tileCount: tileCount == null && nullToAbsent
          ? const Value.absent()
          : Value(tileCount),
      bytes:
          bytes == null && nullToAbsent ? const Value.absent() : Value(bytes),
      overlayKeys: Value(overlayKeys),
    );
  }

  factory OfflineRegion.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OfflineRegion(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      minLat: serializer.fromJson<double>(json['minLat']),
      minLon: serializer.fromJson<double>(json['minLon']),
      maxLat: serializer.fromJson<double>(json['maxLat']),
      maxLon: serializer.fromJson<double>(json['maxLon']),
      maplibreRegionId: serializer.fromJson<int?>(json['maplibreRegionId']),
      styleKey: serializer.fromJson<String>(json['styleKey']),
      minZoom: serializer.fromJson<int>(json['minZoom']),
      maxZoom: serializer.fromJson<int>(json['maxZoom']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      status: serializer.fromJson<int>(json['status']),
      tileCount: serializer.fromJson<int?>(json['tileCount']),
      bytes: serializer.fromJson<int?>(json['bytes']),
      overlayKeys: serializer.fromJson<String>(json['overlayKeys']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'minLat': serializer.toJson<double>(minLat),
      'minLon': serializer.toJson<double>(minLon),
      'maxLat': serializer.toJson<double>(maxLat),
      'maxLon': serializer.toJson<double>(maxLon),
      'maplibreRegionId': serializer.toJson<int?>(maplibreRegionId),
      'styleKey': serializer.toJson<String>(styleKey),
      'minZoom': serializer.toJson<int>(minZoom),
      'maxZoom': serializer.toJson<int>(maxZoom),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'status': serializer.toJson<int>(status),
      'tileCount': serializer.toJson<int?>(tileCount),
      'bytes': serializer.toJson<int?>(bytes),
      'overlayKeys': serializer.toJson<String>(overlayKeys),
    };
  }

  OfflineRegion copyWith(
          {String? id,
          String? name,
          double? minLat,
          double? minLon,
          double? maxLat,
          double? maxLon,
          Value<int?> maplibreRegionId = const Value.absent(),
          String? styleKey,
          int? minZoom,
          int? maxZoom,
          DateTime? createdAt,
          int? status,
          Value<int?> tileCount = const Value.absent(),
          Value<int?> bytes = const Value.absent(),
          String? overlayKeys}) =>
      OfflineRegion(
        id: id ?? this.id,
        name: name ?? this.name,
        minLat: minLat ?? this.minLat,
        minLon: minLon ?? this.minLon,
        maxLat: maxLat ?? this.maxLat,
        maxLon: maxLon ?? this.maxLon,
        maplibreRegionId: maplibreRegionId.present
            ? maplibreRegionId.value
            : this.maplibreRegionId,
        styleKey: styleKey ?? this.styleKey,
        minZoom: minZoom ?? this.minZoom,
        maxZoom: maxZoom ?? this.maxZoom,
        createdAt: createdAt ?? this.createdAt,
        status: status ?? this.status,
        tileCount: tileCount.present ? tileCount.value : this.tileCount,
        bytes: bytes.present ? bytes.value : this.bytes,
        overlayKeys: overlayKeys ?? this.overlayKeys,
      );
  OfflineRegion copyWithCompanion(OfflineRegionsCompanion data) {
    return OfflineRegion(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      minLat: data.minLat.present ? data.minLat.value : this.minLat,
      minLon: data.minLon.present ? data.minLon.value : this.minLon,
      maxLat: data.maxLat.present ? data.maxLat.value : this.maxLat,
      maxLon: data.maxLon.present ? data.maxLon.value : this.maxLon,
      maplibreRegionId: data.maplibreRegionId.present
          ? data.maplibreRegionId.value
          : this.maplibreRegionId,
      styleKey: data.styleKey.present ? data.styleKey.value : this.styleKey,
      minZoom: data.minZoom.present ? data.minZoom.value : this.minZoom,
      maxZoom: data.maxZoom.present ? data.maxZoom.value : this.maxZoom,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      status: data.status.present ? data.status.value : this.status,
      tileCount: data.tileCount.present ? data.tileCount.value : this.tileCount,
      bytes: data.bytes.present ? data.bytes.value : this.bytes,
      overlayKeys:
          data.overlayKeys.present ? data.overlayKeys.value : this.overlayKeys,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OfflineRegion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('minLat: $minLat, ')
          ..write('minLon: $minLon, ')
          ..write('maxLat: $maxLat, ')
          ..write('maxLon: $maxLon, ')
          ..write('maplibreRegionId: $maplibreRegionId, ')
          ..write('styleKey: $styleKey, ')
          ..write('minZoom: $minZoom, ')
          ..write('maxZoom: $maxZoom, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status, ')
          ..write('tileCount: $tileCount, ')
          ..write('bytes: $bytes, ')
          ..write('overlayKeys: $overlayKeys')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      minLat,
      minLon,
      maxLat,
      maxLon,
      maplibreRegionId,
      styleKey,
      minZoom,
      maxZoom,
      createdAt,
      status,
      tileCount,
      bytes,
      overlayKeys);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OfflineRegion &&
          other.id == this.id &&
          other.name == this.name &&
          other.minLat == this.minLat &&
          other.minLon == this.minLon &&
          other.maxLat == this.maxLat &&
          other.maxLon == this.maxLon &&
          other.maplibreRegionId == this.maplibreRegionId &&
          other.styleKey == this.styleKey &&
          other.minZoom == this.minZoom &&
          other.maxZoom == this.maxZoom &&
          other.createdAt == this.createdAt &&
          other.status == this.status &&
          other.tileCount == this.tileCount &&
          other.bytes == this.bytes &&
          other.overlayKeys == this.overlayKeys);
}

class OfflineRegionsCompanion extends UpdateCompanion<OfflineRegion> {
  final Value<String> id;
  final Value<String> name;
  final Value<double> minLat;
  final Value<double> minLon;
  final Value<double> maxLat;
  final Value<double> maxLon;
  final Value<int?> maplibreRegionId;
  final Value<String> styleKey;
  final Value<int> minZoom;
  final Value<int> maxZoom;
  final Value<DateTime> createdAt;
  final Value<int> status;
  final Value<int?> tileCount;
  final Value<int?> bytes;
  final Value<String> overlayKeys;
  final Value<int> rowid;
  const OfflineRegionsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.minLat = const Value.absent(),
    this.minLon = const Value.absent(),
    this.maxLat = const Value.absent(),
    this.maxLon = const Value.absent(),
    this.maplibreRegionId = const Value.absent(),
    this.styleKey = const Value.absent(),
    this.minZoom = const Value.absent(),
    this.maxZoom = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.status = const Value.absent(),
    this.tileCount = const Value.absent(),
    this.bytes = const Value.absent(),
    this.overlayKeys = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OfflineRegionsCompanion.insert({
    required String id,
    required String name,
    required double minLat,
    required double minLon,
    required double maxLat,
    required double maxLon,
    this.maplibreRegionId = const Value.absent(),
    required String styleKey,
    required int minZoom,
    required int maxZoom,
    required DateTime createdAt,
    required int status,
    this.tileCount = const Value.absent(),
    this.bytes = const Value.absent(),
    this.overlayKeys = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        minLat = Value(minLat),
        minLon = Value(minLon),
        maxLat = Value(maxLat),
        maxLon = Value(maxLon),
        styleKey = Value(styleKey),
        minZoom = Value(minZoom),
        maxZoom = Value(maxZoom),
        createdAt = Value(createdAt),
        status = Value(status);
  static Insertable<OfflineRegion> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<double>? minLat,
    Expression<double>? minLon,
    Expression<double>? maxLat,
    Expression<double>? maxLon,
    Expression<int>? maplibreRegionId,
    Expression<String>? styleKey,
    Expression<int>? minZoom,
    Expression<int>? maxZoom,
    Expression<DateTime>? createdAt,
    Expression<int>? status,
    Expression<int>? tileCount,
    Expression<int>? bytes,
    Expression<String>? overlayKeys,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (minLat != null) 'min_lat': minLat,
      if (minLon != null) 'min_lon': minLon,
      if (maxLat != null) 'max_lat': maxLat,
      if (maxLon != null) 'max_lon': maxLon,
      if (maplibreRegionId != null) 'maplibre_region_id': maplibreRegionId,
      if (styleKey != null) 'style_key': styleKey,
      if (minZoom != null) 'min_zoom': minZoom,
      if (maxZoom != null) 'max_zoom': maxZoom,
      if (createdAt != null) 'created_at': createdAt,
      if (status != null) 'status': status,
      if (tileCount != null) 'tile_count': tileCount,
      if (bytes != null) 'bytes': bytes,
      if (overlayKeys != null) 'overlay_keys': overlayKeys,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OfflineRegionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<double>? minLat,
      Value<double>? minLon,
      Value<double>? maxLat,
      Value<double>? maxLon,
      Value<int?>? maplibreRegionId,
      Value<String>? styleKey,
      Value<int>? minZoom,
      Value<int>? maxZoom,
      Value<DateTime>? createdAt,
      Value<int>? status,
      Value<int?>? tileCount,
      Value<int?>? bytes,
      Value<String>? overlayKeys,
      Value<int>? rowid}) {
    return OfflineRegionsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      minLat: minLat ?? this.minLat,
      minLon: minLon ?? this.minLon,
      maxLat: maxLat ?? this.maxLat,
      maxLon: maxLon ?? this.maxLon,
      maplibreRegionId: maplibreRegionId ?? this.maplibreRegionId,
      styleKey: styleKey ?? this.styleKey,
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      tileCount: tileCount ?? this.tileCount,
      bytes: bytes ?? this.bytes,
      overlayKeys: overlayKeys ?? this.overlayKeys,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (minLat.present) {
      map['min_lat'] = Variable<double>(minLat.value);
    }
    if (minLon.present) {
      map['min_lon'] = Variable<double>(minLon.value);
    }
    if (maxLat.present) {
      map['max_lat'] = Variable<double>(maxLat.value);
    }
    if (maxLon.present) {
      map['max_lon'] = Variable<double>(maxLon.value);
    }
    if (maplibreRegionId.present) {
      map['maplibre_region_id'] = Variable<int>(maplibreRegionId.value);
    }
    if (styleKey.present) {
      map['style_key'] = Variable<String>(styleKey.value);
    }
    if (minZoom.present) {
      map['min_zoom'] = Variable<int>(minZoom.value);
    }
    if (maxZoom.present) {
      map['max_zoom'] = Variable<int>(maxZoom.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (tileCount.present) {
      map['tile_count'] = Variable<int>(tileCount.value);
    }
    if (bytes.present) {
      map['bytes'] = Variable<int>(bytes.value);
    }
    if (overlayKeys.present) {
      map['overlay_keys'] = Variable<String>(overlayKeys.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OfflineRegionsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('minLat: $minLat, ')
          ..write('minLon: $minLon, ')
          ..write('maxLat: $maxLat, ')
          ..write('maxLon: $maxLon, ')
          ..write('maplibreRegionId: $maplibreRegionId, ')
          ..write('styleKey: $styleKey, ')
          ..write('minZoom: $minZoom, ')
          ..write('maxZoom: $maxZoom, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status, ')
          ..write('tileCount: $tileCount, ')
          ..write('bytes: $bytes, ')
          ..write('overlayKeys: $overlayKeys, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConditionsCacheTable extends ConditionsCache
    with TableInfo<$ConditionsCacheTable, ConditionsCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConditionsCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bodyJsonMeta =
      const VerificationMeta('bodyJson');
  @override
  late final GeneratedColumn<String> bodyJson = GeneratedColumn<String>(
      'body_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fetchedAtMeta =
      const VerificationMeta('fetchedAt');
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
      'fetched_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, bodyJson, fetchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'conditions_cache';
  @override
  VerificationContext validateIntegrity(
      Insertable<ConditionsCacheData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('body_json')) {
      context.handle(_bodyJsonMeta,
          bodyJson.isAcceptableOrUnknown(data['body_json']!, _bodyJsonMeta));
    } else if (isInserting) {
      context.missing(_bodyJsonMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(_fetchedAtMeta,
          fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta));
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  ConditionsCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConditionsCacheData(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      bodyJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}body_json'])!,
      fetchedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}fetched_at'])!,
    );
  }

  @override
  $ConditionsCacheTable createAlias(String alias) {
    return $ConditionsCacheTable(attachedDatabase, alias);
  }
}

class ConditionsCacheData extends DataClass
    implements Insertable<ConditionsCacheData> {
  final String key;
  final String bodyJson;
  final DateTime fetchedAt;
  const ConditionsCacheData(
      {required this.key, required this.bodyJson, required this.fetchedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['body_json'] = Variable<String>(bodyJson);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  ConditionsCacheCompanion toCompanion(bool nullToAbsent) {
    return ConditionsCacheCompanion(
      key: Value(key),
      bodyJson: Value(bodyJson),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory ConditionsCacheData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConditionsCacheData(
      key: serializer.fromJson<String>(json['key']),
      bodyJson: serializer.fromJson<String>(json['bodyJson']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'bodyJson': serializer.toJson<String>(bodyJson),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  ConditionsCacheData copyWith(
          {String? key, String? bodyJson, DateTime? fetchedAt}) =>
      ConditionsCacheData(
        key: key ?? this.key,
        bodyJson: bodyJson ?? this.bodyJson,
        fetchedAt: fetchedAt ?? this.fetchedAt,
      );
  ConditionsCacheData copyWithCompanion(ConditionsCacheCompanion data) {
    return ConditionsCacheData(
      key: data.key.present ? data.key.value : this.key,
      bodyJson: data.bodyJson.present ? data.bodyJson.value : this.bodyJson,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConditionsCacheData(')
          ..write('key: $key, ')
          ..write('bodyJson: $bodyJson, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, bodyJson, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConditionsCacheData &&
          other.key == this.key &&
          other.bodyJson == this.bodyJson &&
          other.fetchedAt == this.fetchedAt);
}

class ConditionsCacheCompanion extends UpdateCompanion<ConditionsCacheData> {
  final Value<String> key;
  final Value<String> bodyJson;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const ConditionsCacheCompanion({
    this.key = const Value.absent(),
    this.bodyJson = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConditionsCacheCompanion.insert({
    required String key,
    required String bodyJson,
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        bodyJson = Value(bodyJson),
        fetchedAt = Value(fetchedAt);
  static Insertable<ConditionsCacheData> custom({
    Expression<String>? key,
    Expression<String>? bodyJson,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (bodyJson != null) 'body_json': bodyJson,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConditionsCacheCompanion copyWith(
      {Value<String>? key,
      Value<String>? bodyJson,
      Value<DateTime>? fetchedAt,
      Value<int>? rowid}) {
    return ConditionsCacheCompanion(
      key: key ?? this.key,
      bodyJson: bodyJson ?? this.bodyJson,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (bodyJson.present) {
      map['body_json'] = Variable<String>(bodyJson.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConditionsCacheCompanion(')
          ..write('key: $key, ')
          ..write('bodyJson: $bodyJson, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TombstonesTable extends Tombstones
    with TableInfo<$TombstonesTable, Tombstone> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TombstonesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entityTypeMeta =
      const VerificationMeta('entityType');
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
      'entity_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityIdMeta =
      const VerificationMeta('entityId');
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
      'entity_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [entityType, entityId, deletedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tombstones';
  @override
  VerificationContext validateIntegrity(Insertable<Tombstone> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entity_type')) {
      context.handle(
          _entityTypeMeta,
          entityType.isAcceptableOrUnknown(
              data['entity_type']!, _entityTypeMeta));
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(_entityIdMeta,
          entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta));
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    } else if (isInserting) {
      context.missing(_deletedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entityType, entityId};
  @override
  Tombstone map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tombstone(
      entityType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_type'])!,
      entityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_id'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at'])!,
    );
  }

  @override
  $TombstonesTable createAlias(String alias) {
    return $TombstonesTable(attachedDatabase, alias);
  }
}

class Tombstone extends DataClass implements Insertable<Tombstone> {
  final String entityType;
  final String entityId;
  final DateTime deletedAt;
  const Tombstone(
      {required this.entityType,
      required this.entityId,
      required this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['deleted_at'] = Variable<DateTime>(deletedAt);
    return map;
  }

  TombstonesCompanion toCompanion(bool nullToAbsent) {
    return TombstonesCompanion(
      entityType: Value(entityType),
      entityId: Value(entityId),
      deletedAt: Value(deletedAt),
    );
  }

  factory Tombstone.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tombstone(
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      deletedAt: serializer.fromJson<DateTime>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'deletedAt': serializer.toJson<DateTime>(deletedAt),
    };
  }

  Tombstone copyWith(
          {String? entityType, String? entityId, DateTime? deletedAt}) =>
      Tombstone(
        entityType: entityType ?? this.entityType,
        entityId: entityId ?? this.entityId,
        deletedAt: deletedAt ?? this.deletedAt,
      );
  Tombstone copyWithCompanion(TombstonesCompanion data) {
    return Tombstone(
      entityType:
          data.entityType.present ? data.entityType.value : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tombstone(')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(entityType, entityId, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tombstone &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.deletedAt == this.deletedAt);
}

class TombstonesCompanion extends UpdateCompanion<Tombstone> {
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<DateTime> deletedAt;
  final Value<int> rowid;
  const TombstonesCompanion({
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TombstonesCompanion.insert({
    required String entityType,
    required String entityId,
    required DateTime deletedAt,
    this.rowid = const Value.absent(),
  })  : entityType = Value(entityType),
        entityId = Value(entityId),
        deletedAt = Value(deletedAt);
  static Insertable<Tombstone> custom({
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TombstonesCompanion copyWith(
      {Value<String>? entityType,
      Value<String>? entityId,
      Value<DateTime>? deletedAt,
      Value<int>? rowid}) {
    return TombstonesCompanion(
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TombstonesCompanion(')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FavoriteTrailsTable extends FavoriteTrails
    with TableInfo<$FavoriteTrailsTable, FavoriteTrail> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoriteTrailsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _trailIdMeta =
      const VerificationMeta('trailId');
  @override
  late final GeneratedColumn<String> trailId = GeneratedColumn<String>(
      'trail_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _centerLatMeta =
      const VerificationMeta('centerLat');
  @override
  late final GeneratedColumn<double> centerLat = GeneratedColumn<double>(
      'center_lat', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _centerLonMeta =
      const VerificationMeta('centerLon');
  @override
  late final GeneratedColumn<double> centerLon = GeneratedColumn<double>(
      'center_lon', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _lengthMMeta =
      const VerificationMeta('lengthM');
  @override
  late final GeneratedColumn<double> lengthM = GeneratedColumn<double>(
      'length_m', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _savedAtMeta =
      const VerificationMeta('savedAt');
  @override
  late final GeneratedColumn<DateTime> savedAt = GeneratedColumn<DateTime>(
      'saved_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [trailId, name, centerLat, centerLon, lengthM, savedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorite_trails';
  @override
  VerificationContext validateIntegrity(Insertable<FavoriteTrail> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('trail_id')) {
      context.handle(_trailIdMeta,
          trailId.isAcceptableOrUnknown(data['trail_id']!, _trailIdMeta));
    } else if (isInserting) {
      context.missing(_trailIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('center_lat')) {
      context.handle(_centerLatMeta,
          centerLat.isAcceptableOrUnknown(data['center_lat']!, _centerLatMeta));
    } else if (isInserting) {
      context.missing(_centerLatMeta);
    }
    if (data.containsKey('center_lon')) {
      context.handle(_centerLonMeta,
          centerLon.isAcceptableOrUnknown(data['center_lon']!, _centerLonMeta));
    } else if (isInserting) {
      context.missing(_centerLonMeta);
    }
    if (data.containsKey('length_m')) {
      context.handle(_lengthMMeta,
          lengthM.isAcceptableOrUnknown(data['length_m']!, _lengthMMeta));
    }
    if (data.containsKey('saved_at')) {
      context.handle(_savedAtMeta,
          savedAt.isAcceptableOrUnknown(data['saved_at']!, _savedAtMeta));
    } else if (isInserting) {
      context.missing(_savedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {trailId};
  @override
  FavoriteTrail map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FavoriteTrail(
      trailId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}trail_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      centerLat: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}center_lat'])!,
      centerLon: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}center_lon'])!,
      lengthM: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}length_m']),
      savedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}saved_at'])!,
    );
  }

  @override
  $FavoriteTrailsTable createAlias(String alias) {
    return $FavoriteTrailsTable(attachedDatabase, alias);
  }
}

class FavoriteTrail extends DataClass implements Insertable<FavoriteTrail> {
  final String trailId;
  final String name;
  final double centerLat;
  final double centerLon;
  final double? lengthM;
  final DateTime savedAt;
  const FavoriteTrail(
      {required this.trailId,
      required this.name,
      required this.centerLat,
      required this.centerLon,
      this.lengthM,
      required this.savedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['trail_id'] = Variable<String>(trailId);
    map['name'] = Variable<String>(name);
    map['center_lat'] = Variable<double>(centerLat);
    map['center_lon'] = Variable<double>(centerLon);
    if (!nullToAbsent || lengthM != null) {
      map['length_m'] = Variable<double>(lengthM);
    }
    map['saved_at'] = Variable<DateTime>(savedAt);
    return map;
  }

  FavoriteTrailsCompanion toCompanion(bool nullToAbsent) {
    return FavoriteTrailsCompanion(
      trailId: Value(trailId),
      name: Value(name),
      centerLat: Value(centerLat),
      centerLon: Value(centerLon),
      lengthM: lengthM == null && nullToAbsent
          ? const Value.absent()
          : Value(lengthM),
      savedAt: Value(savedAt),
    );
  }

  factory FavoriteTrail.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FavoriteTrail(
      trailId: serializer.fromJson<String>(json['trailId']),
      name: serializer.fromJson<String>(json['name']),
      centerLat: serializer.fromJson<double>(json['centerLat']),
      centerLon: serializer.fromJson<double>(json['centerLon']),
      lengthM: serializer.fromJson<double?>(json['lengthM']),
      savedAt: serializer.fromJson<DateTime>(json['savedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'trailId': serializer.toJson<String>(trailId),
      'name': serializer.toJson<String>(name),
      'centerLat': serializer.toJson<double>(centerLat),
      'centerLon': serializer.toJson<double>(centerLon),
      'lengthM': serializer.toJson<double?>(lengthM),
      'savedAt': serializer.toJson<DateTime>(savedAt),
    };
  }

  FavoriteTrail copyWith(
          {String? trailId,
          String? name,
          double? centerLat,
          double? centerLon,
          Value<double?> lengthM = const Value.absent(),
          DateTime? savedAt}) =>
      FavoriteTrail(
        trailId: trailId ?? this.trailId,
        name: name ?? this.name,
        centerLat: centerLat ?? this.centerLat,
        centerLon: centerLon ?? this.centerLon,
        lengthM: lengthM.present ? lengthM.value : this.lengthM,
        savedAt: savedAt ?? this.savedAt,
      );
  FavoriteTrail copyWithCompanion(FavoriteTrailsCompanion data) {
    return FavoriteTrail(
      trailId: data.trailId.present ? data.trailId.value : this.trailId,
      name: data.name.present ? data.name.value : this.name,
      centerLat: data.centerLat.present ? data.centerLat.value : this.centerLat,
      centerLon: data.centerLon.present ? data.centerLon.value : this.centerLon,
      lengthM: data.lengthM.present ? data.lengthM.value : this.lengthM,
      savedAt: data.savedAt.present ? data.savedAt.value : this.savedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteTrail(')
          ..write('trailId: $trailId, ')
          ..write('name: $name, ')
          ..write('centerLat: $centerLat, ')
          ..write('centerLon: $centerLon, ')
          ..write('lengthM: $lengthM, ')
          ..write('savedAt: $savedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(trailId, name, centerLat, centerLon, lengthM, savedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FavoriteTrail &&
          other.trailId == this.trailId &&
          other.name == this.name &&
          other.centerLat == this.centerLat &&
          other.centerLon == this.centerLon &&
          other.lengthM == this.lengthM &&
          other.savedAt == this.savedAt);
}

class FavoriteTrailsCompanion extends UpdateCompanion<FavoriteTrail> {
  final Value<String> trailId;
  final Value<String> name;
  final Value<double> centerLat;
  final Value<double> centerLon;
  final Value<double?> lengthM;
  final Value<DateTime> savedAt;
  final Value<int> rowid;
  const FavoriteTrailsCompanion({
    this.trailId = const Value.absent(),
    this.name = const Value.absent(),
    this.centerLat = const Value.absent(),
    this.centerLon = const Value.absent(),
    this.lengthM = const Value.absent(),
    this.savedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FavoriteTrailsCompanion.insert({
    required String trailId,
    required String name,
    required double centerLat,
    required double centerLon,
    this.lengthM = const Value.absent(),
    required DateTime savedAt,
    this.rowid = const Value.absent(),
  })  : trailId = Value(trailId),
        name = Value(name),
        centerLat = Value(centerLat),
        centerLon = Value(centerLon),
        savedAt = Value(savedAt);
  static Insertable<FavoriteTrail> custom({
    Expression<String>? trailId,
    Expression<String>? name,
    Expression<double>? centerLat,
    Expression<double>? centerLon,
    Expression<double>? lengthM,
    Expression<DateTime>? savedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (trailId != null) 'trail_id': trailId,
      if (name != null) 'name': name,
      if (centerLat != null) 'center_lat': centerLat,
      if (centerLon != null) 'center_lon': centerLon,
      if (lengthM != null) 'length_m': lengthM,
      if (savedAt != null) 'saved_at': savedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FavoriteTrailsCompanion copyWith(
      {Value<String>? trailId,
      Value<String>? name,
      Value<double>? centerLat,
      Value<double>? centerLon,
      Value<double?>? lengthM,
      Value<DateTime>? savedAt,
      Value<int>? rowid}) {
    return FavoriteTrailsCompanion(
      trailId: trailId ?? this.trailId,
      name: name ?? this.name,
      centerLat: centerLat ?? this.centerLat,
      centerLon: centerLon ?? this.centerLon,
      lengthM: lengthM ?? this.lengthM,
      savedAt: savedAt ?? this.savedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (trailId.present) {
      map['trail_id'] = Variable<String>(trailId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (centerLat.present) {
      map['center_lat'] = Variable<double>(centerLat.value);
    }
    if (centerLon.present) {
      map['center_lon'] = Variable<double>(centerLon.value);
    }
    if (lengthM.present) {
      map['length_m'] = Variable<double>(lengthM.value);
    }
    if (savedAt.present) {
      map['saved_at'] = Variable<DateTime>(savedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteTrailsCompanion(')
          ..write('trailId: $trailId, ')
          ..write('name: $name, ')
          ..write('centerLat: $centerLat, ')
          ..write('centerLon: $centerLon, ')
          ..write('lengthM: $lengthM, ')
          ..write('savedAt: $savedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserWaypointsTable extends UserWaypoints
    with TableInfo<$UserWaypointsTable, UserWaypoint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserWaypointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
      'lat', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _lonMeta = const VerificationMeta('lon');
  @override
  late final GeneratedColumn<double> lon = GeneratedColumn<double>(
      'lon', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _routeIdMeta =
      const VerificationMeta('routeId');
  @override
  late final GeneratedColumn<String> routeId = GeneratedColumn<String>(
      'route_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES routes (id)'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, kind, name, note, lat, lon, routeId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_waypoints';
  @override
  VerificationContext validateIntegrity(Insertable<UserWaypoint> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('lat')) {
      context.handle(
          _latMeta, lat.isAcceptableOrUnknown(data['lat']!, _latMeta));
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lon')) {
      context.handle(
          _lonMeta, lon.isAcceptableOrUnknown(data['lon']!, _lonMeta));
    } else if (isInserting) {
      context.missing(_lonMeta);
    }
    if (data.containsKey('route_id')) {
      context.handle(_routeIdMeta,
          routeId.isAcceptableOrUnknown(data['route_id']!, _routeIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserWaypoint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserWaypoint(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name']),
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      lat: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}lat'])!,
      lon: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}lon'])!,
      routeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}route_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $UserWaypointsTable createAlias(String alias) {
    return $UserWaypointsTable(attachedDatabase, alias);
  }
}

class UserWaypoint extends DataClass implements Insertable<UserWaypoint> {
  final String id;
  final String kind;
  final String? name;
  final String? note;
  final double lat;
  final double lon;
  final String? routeId;
  final DateTime createdAt;
  const UserWaypoint(
      {required this.id,
      required this.kind,
      this.name,
      this.note,
      required this.lat,
      required this.lon,
      this.routeId,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['lat'] = Variable<double>(lat);
    map['lon'] = Variable<double>(lon);
    if (!nullToAbsent || routeId != null) {
      map['route_id'] = Variable<String>(routeId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  UserWaypointsCompanion toCompanion(bool nullToAbsent) {
    return UserWaypointsCompanion(
      id: Value(id),
      kind: Value(kind),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      lat: Value(lat),
      lon: Value(lon),
      routeId: routeId == null && nullToAbsent
          ? const Value.absent()
          : Value(routeId),
      createdAt: Value(createdAt),
    );
  }

  factory UserWaypoint.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserWaypoint(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      name: serializer.fromJson<String?>(json['name']),
      note: serializer.fromJson<String?>(json['note']),
      lat: serializer.fromJson<double>(json['lat']),
      lon: serializer.fromJson<double>(json['lon']),
      routeId: serializer.fromJson<String?>(json['routeId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'name': serializer.toJson<String?>(name),
      'note': serializer.toJson<String?>(note),
      'lat': serializer.toJson<double>(lat),
      'lon': serializer.toJson<double>(lon),
      'routeId': serializer.toJson<String?>(routeId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  UserWaypoint copyWith(
          {String? id,
          String? kind,
          Value<String?> name = const Value.absent(),
          Value<String?> note = const Value.absent(),
          double? lat,
          double? lon,
          Value<String?> routeId = const Value.absent(),
          DateTime? createdAt}) =>
      UserWaypoint(
        id: id ?? this.id,
        kind: kind ?? this.kind,
        name: name.present ? name.value : this.name,
        note: note.present ? note.value : this.note,
        lat: lat ?? this.lat,
        lon: lon ?? this.lon,
        routeId: routeId.present ? routeId.value : this.routeId,
        createdAt: createdAt ?? this.createdAt,
      );
  UserWaypoint copyWithCompanion(UserWaypointsCompanion data) {
    return UserWaypoint(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      name: data.name.present ? data.name.value : this.name,
      note: data.note.present ? data.note.value : this.note,
      lat: data.lat.present ? data.lat.value : this.lat,
      lon: data.lon.present ? data.lon.value : this.lon,
      routeId: data.routeId.present ? data.routeId.value : this.routeId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserWaypoint(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('name: $name, ')
          ..write('note: $note, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('routeId: $routeId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, kind, name, note, lat, lon, routeId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserWaypoint &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.name == this.name &&
          other.note == this.note &&
          other.lat == this.lat &&
          other.lon == this.lon &&
          other.routeId == this.routeId &&
          other.createdAt == this.createdAt);
}

class UserWaypointsCompanion extends UpdateCompanion<UserWaypoint> {
  final Value<String> id;
  final Value<String> kind;
  final Value<String?> name;
  final Value<String?> note;
  final Value<double> lat;
  final Value<double> lon;
  final Value<String?> routeId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const UserWaypointsCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.name = const Value.absent(),
    this.note = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
    this.routeId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserWaypointsCompanion.insert({
    required String id,
    required String kind,
    this.name = const Value.absent(),
    this.note = const Value.absent(),
    required double lat,
    required double lon,
    this.routeId = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        kind = Value(kind),
        lat = Value(lat),
        lon = Value(lon),
        createdAt = Value(createdAt);
  static Insertable<UserWaypoint> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<String>? name,
    Expression<String>? note,
    Expression<double>? lat,
    Expression<double>? lon,
    Expression<String>? routeId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (name != null) 'name': name,
      if (note != null) 'note': note,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      if (routeId != null) 'route_id': routeId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserWaypointsCompanion copyWith(
      {Value<String>? id,
      Value<String>? kind,
      Value<String?>? name,
      Value<String?>? note,
      Value<double>? lat,
      Value<double>? lon,
      Value<String?>? routeId,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return UserWaypointsCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      name: name ?? this.name,
      note: note ?? this.note,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      routeId: routeId ?? this.routeId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lon.present) {
      map['lon'] = Variable<double>(lon.value);
    }
    if (routeId.present) {
      map['route_id'] = Variable<String>(routeId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserWaypointsCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('name: $name, ')
          ..write('note: $note, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('routeId: $routeId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CustomThemesTable extends CustomThemes
    with TableInfo<$CustomThemesTable, CustomTheme> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomThemesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isDarkMeta = const VerificationMeta('isDark');
  @override
  late final GeneratedColumn<bool> isDark = GeneratedColumn<bool>(
      'is_dark', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_dark" IN (0, 1))'));
  static const VerificationMeta _accentMeta = const VerificationMeta('accent');
  @override
  late final GeneratedColumn<int> accent = GeneratedColumn<int>(
      'accent', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _backgroundMeta =
      const VerificationMeta('background');
  @override
  late final GeneratedColumn<int> background = GeneratedColumn<int>(
      'background', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _surfaceMeta =
      const VerificationMeta('surface');
  @override
  late final GeneratedColumn<int> surface = GeneratedColumn<int>(
      'surface', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _raisedMeta = const VerificationMeta('raised');
  @override
  late final GeneratedColumn<int> raised = GeneratedColumn<int>(
      'raised', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _outlineMeta =
      const VerificationMeta('outline');
  @override
  late final GeneratedColumn<int> outline = GeneratedColumn<int>(
      'outline', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _textPrimaryMeta =
      const VerificationMeta('textPrimary');
  @override
  late final GeneratedColumn<int> textPrimary = GeneratedColumn<int>(
      'text_primary', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _textSecondaryMeta =
      const VerificationMeta('textSecondary');
  @override
  late final GeneratedColumn<int> textSecondary = GeneratedColumn<int>(
      'text_secondary', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _routeMeta = const VerificationMeta('route');
  @override
  late final GeneratedColumn<int> route = GeneratedColumn<int>(
      'route', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _trackMeta = const VerificationMeta('track');
  @override
  late final GeneratedColumn<int> track = GeneratedColumn<int>(
      'track', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        isDark,
        accent,
        background,
        surface,
        raised,
        outline,
        textPrimary,
        textSecondary,
        route,
        track,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'custom_themes';
  @override
  VerificationContext validateIntegrity(Insertable<CustomTheme> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('is_dark')) {
      context.handle(_isDarkMeta,
          isDark.isAcceptableOrUnknown(data['is_dark']!, _isDarkMeta));
    } else if (isInserting) {
      context.missing(_isDarkMeta);
    }
    if (data.containsKey('accent')) {
      context.handle(_accentMeta,
          accent.isAcceptableOrUnknown(data['accent']!, _accentMeta));
    } else if (isInserting) {
      context.missing(_accentMeta);
    }
    if (data.containsKey('background')) {
      context.handle(
          _backgroundMeta,
          background.isAcceptableOrUnknown(
              data['background']!, _backgroundMeta));
    } else if (isInserting) {
      context.missing(_backgroundMeta);
    }
    if (data.containsKey('surface')) {
      context.handle(_surfaceMeta,
          surface.isAcceptableOrUnknown(data['surface']!, _surfaceMeta));
    } else if (isInserting) {
      context.missing(_surfaceMeta);
    }
    if (data.containsKey('raised')) {
      context.handle(_raisedMeta,
          raised.isAcceptableOrUnknown(data['raised']!, _raisedMeta));
    } else if (isInserting) {
      context.missing(_raisedMeta);
    }
    if (data.containsKey('outline')) {
      context.handle(_outlineMeta,
          outline.isAcceptableOrUnknown(data['outline']!, _outlineMeta));
    } else if (isInserting) {
      context.missing(_outlineMeta);
    }
    if (data.containsKey('text_primary')) {
      context.handle(
          _textPrimaryMeta,
          textPrimary.isAcceptableOrUnknown(
              data['text_primary']!, _textPrimaryMeta));
    } else if (isInserting) {
      context.missing(_textPrimaryMeta);
    }
    if (data.containsKey('text_secondary')) {
      context.handle(
          _textSecondaryMeta,
          textSecondary.isAcceptableOrUnknown(
              data['text_secondary']!, _textSecondaryMeta));
    } else if (isInserting) {
      context.missing(_textSecondaryMeta);
    }
    if (data.containsKey('route')) {
      context.handle(
          _routeMeta, route.isAcceptableOrUnknown(data['route']!, _routeMeta));
    } else if (isInserting) {
      context.missing(_routeMeta);
    }
    if (data.containsKey('track')) {
      context.handle(
          _trackMeta, track.isAcceptableOrUnknown(data['track']!, _trackMeta));
    } else if (isInserting) {
      context.missing(_trackMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomTheme map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomTheme(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      isDark: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_dark'])!,
      accent: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}accent'])!,
      background: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}background'])!,
      surface: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}surface'])!,
      raised: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}raised'])!,
      outline: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}outline'])!,
      textPrimary: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}text_primary'])!,
      textSecondary: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}text_secondary'])!,
      route: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}route'])!,
      track: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}track'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $CustomThemesTable createAlias(String alias) {
    return $CustomThemesTable(attachedDatabase, alias);
  }
}

class CustomTheme extends DataClass implements Insertable<CustomTheme> {
  final String id;
  final String name;
  final bool isDark;
  final int accent;
  final int background;
  final int surface;
  final int raised;
  final int outline;
  final int textPrimary;
  final int textSecondary;
  final int route;
  final int track;
  final DateTime createdAt;
  const CustomTheme(
      {required this.id,
      required this.name,
      required this.isDark,
      required this.accent,
      required this.background,
      required this.surface,
      required this.raised,
      required this.outline,
      required this.textPrimary,
      required this.textSecondary,
      required this.route,
      required this.track,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['is_dark'] = Variable<bool>(isDark);
    map['accent'] = Variable<int>(accent);
    map['background'] = Variable<int>(background);
    map['surface'] = Variable<int>(surface);
    map['raised'] = Variable<int>(raised);
    map['outline'] = Variable<int>(outline);
    map['text_primary'] = Variable<int>(textPrimary);
    map['text_secondary'] = Variable<int>(textSecondary);
    map['route'] = Variable<int>(route);
    map['track'] = Variable<int>(track);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CustomThemesCompanion toCompanion(bool nullToAbsent) {
    return CustomThemesCompanion(
      id: Value(id),
      name: Value(name),
      isDark: Value(isDark),
      accent: Value(accent),
      background: Value(background),
      surface: Value(surface),
      raised: Value(raised),
      outline: Value(outline),
      textPrimary: Value(textPrimary),
      textSecondary: Value(textSecondary),
      route: Value(route),
      track: Value(track),
      createdAt: Value(createdAt),
    );
  }

  factory CustomTheme.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomTheme(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      isDark: serializer.fromJson<bool>(json['isDark']),
      accent: serializer.fromJson<int>(json['accent']),
      background: serializer.fromJson<int>(json['background']),
      surface: serializer.fromJson<int>(json['surface']),
      raised: serializer.fromJson<int>(json['raised']),
      outline: serializer.fromJson<int>(json['outline']),
      textPrimary: serializer.fromJson<int>(json['textPrimary']),
      textSecondary: serializer.fromJson<int>(json['textSecondary']),
      route: serializer.fromJson<int>(json['route']),
      track: serializer.fromJson<int>(json['track']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'isDark': serializer.toJson<bool>(isDark),
      'accent': serializer.toJson<int>(accent),
      'background': serializer.toJson<int>(background),
      'surface': serializer.toJson<int>(surface),
      'raised': serializer.toJson<int>(raised),
      'outline': serializer.toJson<int>(outline),
      'textPrimary': serializer.toJson<int>(textPrimary),
      'textSecondary': serializer.toJson<int>(textSecondary),
      'route': serializer.toJson<int>(route),
      'track': serializer.toJson<int>(track),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CustomTheme copyWith(
          {String? id,
          String? name,
          bool? isDark,
          int? accent,
          int? background,
          int? surface,
          int? raised,
          int? outline,
          int? textPrimary,
          int? textSecondary,
          int? route,
          int? track,
          DateTime? createdAt}) =>
      CustomTheme(
        id: id ?? this.id,
        name: name ?? this.name,
        isDark: isDark ?? this.isDark,
        accent: accent ?? this.accent,
        background: background ?? this.background,
        surface: surface ?? this.surface,
        raised: raised ?? this.raised,
        outline: outline ?? this.outline,
        textPrimary: textPrimary ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        route: route ?? this.route,
        track: track ?? this.track,
        createdAt: createdAt ?? this.createdAt,
      );
  CustomTheme copyWithCompanion(CustomThemesCompanion data) {
    return CustomTheme(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      isDark: data.isDark.present ? data.isDark.value : this.isDark,
      accent: data.accent.present ? data.accent.value : this.accent,
      background:
          data.background.present ? data.background.value : this.background,
      surface: data.surface.present ? data.surface.value : this.surface,
      raised: data.raised.present ? data.raised.value : this.raised,
      outline: data.outline.present ? data.outline.value : this.outline,
      textPrimary:
          data.textPrimary.present ? data.textPrimary.value : this.textPrimary,
      textSecondary: data.textSecondary.present
          ? data.textSecondary.value
          : this.textSecondary,
      route: data.route.present ? data.route.value : this.route,
      track: data.track.present ? data.track.value : this.track,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomTheme(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('isDark: $isDark, ')
          ..write('accent: $accent, ')
          ..write('background: $background, ')
          ..write('surface: $surface, ')
          ..write('raised: $raised, ')
          ..write('outline: $outline, ')
          ..write('textPrimary: $textPrimary, ')
          ..write('textSecondary: $textSecondary, ')
          ..write('route: $route, ')
          ..write('track: $track, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, isDark, accent, background, surface,
      raised, outline, textPrimary, textSecondary, route, track, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomTheme &&
          other.id == this.id &&
          other.name == this.name &&
          other.isDark == this.isDark &&
          other.accent == this.accent &&
          other.background == this.background &&
          other.surface == this.surface &&
          other.raised == this.raised &&
          other.outline == this.outline &&
          other.textPrimary == this.textPrimary &&
          other.textSecondary == this.textSecondary &&
          other.route == this.route &&
          other.track == this.track &&
          other.createdAt == this.createdAt);
}

class CustomThemesCompanion extends UpdateCompanion<CustomTheme> {
  final Value<String> id;
  final Value<String> name;
  final Value<bool> isDark;
  final Value<int> accent;
  final Value<int> background;
  final Value<int> surface;
  final Value<int> raised;
  final Value<int> outline;
  final Value<int> textPrimary;
  final Value<int> textSecondary;
  final Value<int> route;
  final Value<int> track;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const CustomThemesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.isDark = const Value.absent(),
    this.accent = const Value.absent(),
    this.background = const Value.absent(),
    this.surface = const Value.absent(),
    this.raised = const Value.absent(),
    this.outline = const Value.absent(),
    this.textPrimary = const Value.absent(),
    this.textSecondary = const Value.absent(),
    this.route = const Value.absent(),
    this.track = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomThemesCompanion.insert({
    required String id,
    required String name,
    required bool isDark,
    required int accent,
    required int background,
    required int surface,
    required int raised,
    required int outline,
    required int textPrimary,
    required int textSecondary,
    required int route,
    required int track,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        isDark = Value(isDark),
        accent = Value(accent),
        background = Value(background),
        surface = Value(surface),
        raised = Value(raised),
        outline = Value(outline),
        textPrimary = Value(textPrimary),
        textSecondary = Value(textSecondary),
        route = Value(route),
        track = Value(track),
        createdAt = Value(createdAt);
  static Insertable<CustomTheme> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<bool>? isDark,
    Expression<int>? accent,
    Expression<int>? background,
    Expression<int>? surface,
    Expression<int>? raised,
    Expression<int>? outline,
    Expression<int>? textPrimary,
    Expression<int>? textSecondary,
    Expression<int>? route,
    Expression<int>? track,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (isDark != null) 'is_dark': isDark,
      if (accent != null) 'accent': accent,
      if (background != null) 'background': background,
      if (surface != null) 'surface': surface,
      if (raised != null) 'raised': raised,
      if (outline != null) 'outline': outline,
      if (textPrimary != null) 'text_primary': textPrimary,
      if (textSecondary != null) 'text_secondary': textSecondary,
      if (route != null) 'route': route,
      if (track != null) 'track': track,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomThemesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<bool>? isDark,
      Value<int>? accent,
      Value<int>? background,
      Value<int>? surface,
      Value<int>? raised,
      Value<int>? outline,
      Value<int>? textPrimary,
      Value<int>? textSecondary,
      Value<int>? route,
      Value<int>? track,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return CustomThemesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      isDark: isDark ?? this.isDark,
      accent: accent ?? this.accent,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      raised: raised ?? this.raised,
      outline: outline ?? this.outline,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      route: route ?? this.route,
      track: track ?? this.track,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isDark.present) {
      map['is_dark'] = Variable<bool>(isDark.value);
    }
    if (accent.present) {
      map['accent'] = Variable<int>(accent.value);
    }
    if (background.present) {
      map['background'] = Variable<int>(background.value);
    }
    if (surface.present) {
      map['surface'] = Variable<int>(surface.value);
    }
    if (raised.present) {
      map['raised'] = Variable<int>(raised.value);
    }
    if (outline.present) {
      map['outline'] = Variable<int>(outline.value);
    }
    if (textPrimary.present) {
      map['text_primary'] = Variable<int>(textPrimary.value);
    }
    if (textSecondary.present) {
      map['text_secondary'] = Variable<int>(textSecondary.value);
    }
    if (route.present) {
      map['route'] = Variable<int>(route.value);
    }
    if (track.present) {
      map['track'] = Variable<int>(track.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomThemesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('isDark: $isDark, ')
          ..write('accent: $accent, ')
          ..write('background: $background, ')
          ..write('surface: $surface, ')
          ..write('raised: $raised, ')
          ..write('outline: $outline, ')
          ..write('textPrimary: $textPrimary, ')
          ..write('textSecondary: $textSecondary, ')
          ..write('route: $route, ')
          ..write('track: $track, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $OsmWaysTable osmWays = $OsmWaysTable(this);
  late final $OsmNodesTable osmNodes = $OsmNodesTable(this);
  late final $OsmRelationsTable osmRelations = $OsmRelationsTable(this);
  late final $PoisTable pois = $PoisTable(this);
  late final $CacheCellsTable cacheCells = $CacheCellsTable(this);
  late final $UsfsRoadsTable usfsRoads = $UsfsRoadsTable(this);
  late final $RoutesTable routes = $RoutesTable(this);
  late final $RouteWaypointsTable routeWaypoints = $RouteWaypointsTable(this);
  late final $TracksTable tracks = $TracksTable(this);
  late final $TrackPointsTable trackPoints = $TrackPointsTable(this);
  late final $OfflineRegionsTable offlineRegions = $OfflineRegionsTable(this);
  late final $ConditionsCacheTable conditionsCache =
      $ConditionsCacheTable(this);
  late final $TombstonesTable tombstones = $TombstonesTable(this);
  late final $FavoriteTrailsTable favoriteTrails = $FavoriteTrailsTable(this);
  late final $UserWaypointsTable userWaypoints = $UserWaypointsTable(this);
  late final $CustomThemesTable customThemes = $CustomThemesTable(this);
  late final Index idxWaysBbox = Index('idx_ways_bbox',
      'CREATE INDEX idx_ways_bbox ON osm_ways (min_lat, max_lat, min_lon, max_lon)');
  late final Index idxPoisLatlon = Index(
      'idx_pois_latlon', 'CREATE INDEX idx_pois_latlon ON pois (lat, lon)');
  late final Index idxRoadsBbox = Index('idx_roads_bbox',
      'CREATE INDEX idx_roads_bbox ON usfs_roads (min_lat, max_lat, min_lon, max_lon)');
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        osmWays,
        osmNodes,
        osmRelations,
        pois,
        cacheCells,
        usfsRoads,
        routes,
        routeWaypoints,
        tracks,
        trackPoints,
        offlineRegions,
        conditionsCache,
        tombstones,
        favoriteTrails,
        userWaypoints,
        customThemes,
        idxWaysBbox,
        idxPoisLatlon,
        idxRoadsBbox
      ];
}

typedef $$OsmWaysTableCreateCompanionBuilder = OsmWaysCompanion Function({
  Value<int> id,
  Value<String?> name,
  required String highway,
  Value<String?> sacScale,
  Value<String?> trailVisibility,
  Value<String?> surface,
  Value<bool> informal,
  required String tagsJson,
  required String geomJson,
  Value<String> nodeIdsJson,
  required int firstNodeId,
  required int lastNodeId,
  required double lengthM,
  required double minLat,
  required double minLon,
  required double maxLat,
  required double maxLon,
  Value<String?> usfsName,
  Value<String?> usfsNumber,
});
typedef $$OsmWaysTableUpdateCompanionBuilder = OsmWaysCompanion Function({
  Value<int> id,
  Value<String?> name,
  Value<String> highway,
  Value<String?> sacScale,
  Value<String?> trailVisibility,
  Value<String?> surface,
  Value<bool> informal,
  Value<String> tagsJson,
  Value<String> geomJson,
  Value<String> nodeIdsJson,
  Value<int> firstNodeId,
  Value<int> lastNodeId,
  Value<double> lengthM,
  Value<double> minLat,
  Value<double> minLon,
  Value<double> maxLat,
  Value<double> maxLon,
  Value<String?> usfsName,
  Value<String?> usfsNumber,
});

class $$OsmWaysTableFilterComposer
    extends Composer<_$AppDatabase, $OsmWaysTable> {
  $$OsmWaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get highway => $composableBuilder(
      column: $table.highway, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sacScale => $composableBuilder(
      column: $table.sacScale, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get trailVisibility => $composableBuilder(
      column: $table.trailVisibility,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get surface => $composableBuilder(
      column: $table.surface, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get informal => $composableBuilder(
      column: $table.informal, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tagsJson => $composableBuilder(
      column: $table.tagsJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get geomJson => $composableBuilder(
      column: $table.geomJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nodeIdsJson => $composableBuilder(
      column: $table.nodeIdsJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get firstNodeId => $composableBuilder(
      column: $table.firstNodeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastNodeId => $composableBuilder(
      column: $table.lastNodeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get lengthM => $composableBuilder(
      column: $table.lengthM, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get minLat => $composableBuilder(
      column: $table.minLat, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get minLon => $composableBuilder(
      column: $table.minLon, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get maxLat => $composableBuilder(
      column: $table.maxLat, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get maxLon => $composableBuilder(
      column: $table.maxLon, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get usfsName => $composableBuilder(
      column: $table.usfsName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get usfsNumber => $composableBuilder(
      column: $table.usfsNumber, builder: (column) => ColumnFilters(column));
}

class $$OsmWaysTableOrderingComposer
    extends Composer<_$AppDatabase, $OsmWaysTable> {
  $$OsmWaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get highway => $composableBuilder(
      column: $table.highway, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sacScale => $composableBuilder(
      column: $table.sacScale, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get trailVisibility => $composableBuilder(
      column: $table.trailVisibility,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get surface => $composableBuilder(
      column: $table.surface, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get informal => $composableBuilder(
      column: $table.informal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tagsJson => $composableBuilder(
      column: $table.tagsJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get geomJson => $composableBuilder(
      column: $table.geomJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nodeIdsJson => $composableBuilder(
      column: $table.nodeIdsJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get firstNodeId => $composableBuilder(
      column: $table.firstNodeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastNodeId => $composableBuilder(
      column: $table.lastNodeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get lengthM => $composableBuilder(
      column: $table.lengthM, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get minLat => $composableBuilder(
      column: $table.minLat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get minLon => $composableBuilder(
      column: $table.minLon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get maxLat => $composableBuilder(
      column: $table.maxLat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get maxLon => $composableBuilder(
      column: $table.maxLon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get usfsName => $composableBuilder(
      column: $table.usfsName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get usfsNumber => $composableBuilder(
      column: $table.usfsNumber, builder: (column) => ColumnOrderings(column));
}

class $$OsmWaysTableAnnotationComposer
    extends Composer<_$AppDatabase, $OsmWaysTable> {
  $$OsmWaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get highway =>
      $composableBuilder(column: $table.highway, builder: (column) => column);

  GeneratedColumn<String> get sacScale =>
      $composableBuilder(column: $table.sacScale, builder: (column) => column);

  GeneratedColumn<String> get trailVisibility => $composableBuilder(
      column: $table.trailVisibility, builder: (column) => column);

  GeneratedColumn<String> get surface =>
      $composableBuilder(column: $table.surface, builder: (column) => column);

  GeneratedColumn<bool> get informal =>
      $composableBuilder(column: $table.informal, builder: (column) => column);

  GeneratedColumn<String> get tagsJson =>
      $composableBuilder(column: $table.tagsJson, builder: (column) => column);

  GeneratedColumn<String> get geomJson =>
      $composableBuilder(column: $table.geomJson, builder: (column) => column);

  GeneratedColumn<String> get nodeIdsJson => $composableBuilder(
      column: $table.nodeIdsJson, builder: (column) => column);

  GeneratedColumn<int> get firstNodeId => $composableBuilder(
      column: $table.firstNodeId, builder: (column) => column);

  GeneratedColumn<int> get lastNodeId => $composableBuilder(
      column: $table.lastNodeId, builder: (column) => column);

  GeneratedColumn<double> get lengthM =>
      $composableBuilder(column: $table.lengthM, builder: (column) => column);

  GeneratedColumn<double> get minLat =>
      $composableBuilder(column: $table.minLat, builder: (column) => column);

  GeneratedColumn<double> get minLon =>
      $composableBuilder(column: $table.minLon, builder: (column) => column);

  GeneratedColumn<double> get maxLat =>
      $composableBuilder(column: $table.maxLat, builder: (column) => column);

  GeneratedColumn<double> get maxLon =>
      $composableBuilder(column: $table.maxLon, builder: (column) => column);

  GeneratedColumn<String> get usfsName =>
      $composableBuilder(column: $table.usfsName, builder: (column) => column);

  GeneratedColumn<String> get usfsNumber => $composableBuilder(
      column: $table.usfsNumber, builder: (column) => column);
}

class $$OsmWaysTableTableManager extends RootTableManager<
    _$AppDatabase,
    $OsmWaysTable,
    OsmWay,
    $$OsmWaysTableFilterComposer,
    $$OsmWaysTableOrderingComposer,
    $$OsmWaysTableAnnotationComposer,
    $$OsmWaysTableCreateCompanionBuilder,
    $$OsmWaysTableUpdateCompanionBuilder,
    (OsmWay, BaseReferences<_$AppDatabase, $OsmWaysTable, OsmWay>),
    OsmWay,
    PrefetchHooks Function()> {
  $$OsmWaysTableTableManager(_$AppDatabase db, $OsmWaysTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OsmWaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OsmWaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OsmWaysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> name = const Value.absent(),
            Value<String> highway = const Value.absent(),
            Value<String?> sacScale = const Value.absent(),
            Value<String?> trailVisibility = const Value.absent(),
            Value<String?> surface = const Value.absent(),
            Value<bool> informal = const Value.absent(),
            Value<String> tagsJson = const Value.absent(),
            Value<String> geomJson = const Value.absent(),
            Value<String> nodeIdsJson = const Value.absent(),
            Value<int> firstNodeId = const Value.absent(),
            Value<int> lastNodeId = const Value.absent(),
            Value<double> lengthM = const Value.absent(),
            Value<double> minLat = const Value.absent(),
            Value<double> minLon = const Value.absent(),
            Value<double> maxLat = const Value.absent(),
            Value<double> maxLon = const Value.absent(),
            Value<String?> usfsName = const Value.absent(),
            Value<String?> usfsNumber = const Value.absent(),
          }) =>
              OsmWaysCompanion(
            id: id,
            name: name,
            highway: highway,
            sacScale: sacScale,
            trailVisibility: trailVisibility,
            surface: surface,
            informal: informal,
            tagsJson: tagsJson,
            geomJson: geomJson,
            nodeIdsJson: nodeIdsJson,
            firstNodeId: firstNodeId,
            lastNodeId: lastNodeId,
            lengthM: lengthM,
            minLat: minLat,
            minLon: minLon,
            maxLat: maxLat,
            maxLon: maxLon,
            usfsName: usfsName,
            usfsNumber: usfsNumber,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> name = const Value.absent(),
            required String highway,
            Value<String?> sacScale = const Value.absent(),
            Value<String?> trailVisibility = const Value.absent(),
            Value<String?> surface = const Value.absent(),
            Value<bool> informal = const Value.absent(),
            required String tagsJson,
            required String geomJson,
            Value<String> nodeIdsJson = const Value.absent(),
            required int firstNodeId,
            required int lastNodeId,
            required double lengthM,
            required double minLat,
            required double minLon,
            required double maxLat,
            required double maxLon,
            Value<String?> usfsName = const Value.absent(),
            Value<String?> usfsNumber = const Value.absent(),
          }) =>
              OsmWaysCompanion.insert(
            id: id,
            name: name,
            highway: highway,
            sacScale: sacScale,
            trailVisibility: trailVisibility,
            surface: surface,
            informal: informal,
            tagsJson: tagsJson,
            geomJson: geomJson,
            nodeIdsJson: nodeIdsJson,
            firstNodeId: firstNodeId,
            lastNodeId: lastNodeId,
            lengthM: lengthM,
            minLat: minLat,
            minLon: minLon,
            maxLat: maxLat,
            maxLon: maxLon,
            usfsName: usfsName,
            usfsNumber: usfsNumber,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$OsmWaysTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $OsmWaysTable,
    OsmWay,
    $$OsmWaysTableFilterComposer,
    $$OsmWaysTableOrderingComposer,
    $$OsmWaysTableAnnotationComposer,
    $$OsmWaysTableCreateCompanionBuilder,
    $$OsmWaysTableUpdateCompanionBuilder,
    (OsmWay, BaseReferences<_$AppDatabase, $OsmWaysTable, OsmWay>),
    OsmWay,
    PrefetchHooks Function()>;
typedef $$OsmNodesTableCreateCompanionBuilder = OsmNodesCompanion Function({
  Value<int> id,
  required double lat,
  required double lon,
});
typedef $$OsmNodesTableUpdateCompanionBuilder = OsmNodesCompanion Function({
  Value<int> id,
  Value<double> lat,
  Value<double> lon,
});

class $$OsmNodesTableFilterComposer
    extends Composer<_$AppDatabase, $OsmNodesTable> {
  $$OsmNodesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get lat => $composableBuilder(
      column: $table.lat, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get lon => $composableBuilder(
      column: $table.lon, builder: (column) => ColumnFilters(column));
}

class $$OsmNodesTableOrderingComposer
    extends Composer<_$AppDatabase, $OsmNodesTable> {
  $$OsmNodesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get lat => $composableBuilder(
      column: $table.lat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get lon => $composableBuilder(
      column: $table.lon, builder: (column) => ColumnOrderings(column));
}

class $$OsmNodesTableAnnotationComposer
    extends Composer<_$AppDatabase, $OsmNodesTable> {
  $$OsmNodesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lon =>
      $composableBuilder(column: $table.lon, builder: (column) => column);
}

class $$OsmNodesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $OsmNodesTable,
    OsmNode,
    $$OsmNodesTableFilterComposer,
    $$OsmNodesTableOrderingComposer,
    $$OsmNodesTableAnnotationComposer,
    $$OsmNodesTableCreateCompanionBuilder,
    $$OsmNodesTableUpdateCompanionBuilder,
    (OsmNode, BaseReferences<_$AppDatabase, $OsmNodesTable, OsmNode>),
    OsmNode,
    PrefetchHooks Function()> {
  $$OsmNodesTableTableManager(_$AppDatabase db, $OsmNodesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OsmNodesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OsmNodesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OsmNodesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<double> lat = const Value.absent(),
            Value<double> lon = const Value.absent(),
          }) =>
              OsmNodesCompanion(
            id: id,
            lat: lat,
            lon: lon,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required double lat,
            required double lon,
          }) =>
              OsmNodesCompanion.insert(
            id: id,
            lat: lat,
            lon: lon,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$OsmNodesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $OsmNodesTable,
    OsmNode,
    $$OsmNodesTableFilterComposer,
    $$OsmNodesTableOrderingComposer,
    $$OsmNodesTableAnnotationComposer,
    $$OsmNodesTableCreateCompanionBuilder,
    $$OsmNodesTableUpdateCompanionBuilder,
    (OsmNode, BaseReferences<_$AppDatabase, $OsmNodesTable, OsmNode>),
    OsmNode,
    PrefetchHooks Function()>;
typedef $$OsmRelationsTableCreateCompanionBuilder = OsmRelationsCompanion
    Function({
  Value<int> id,
  Value<String?> name,
  Value<String?> network,
  required String tagsJson,
  required String memberWayIdsJson,
});
typedef $$OsmRelationsTableUpdateCompanionBuilder = OsmRelationsCompanion
    Function({
  Value<int> id,
  Value<String?> name,
  Value<String?> network,
  Value<String> tagsJson,
  Value<String> memberWayIdsJson,
});

class $$OsmRelationsTableFilterComposer
    extends Composer<_$AppDatabase, $OsmRelationsTable> {
  $$OsmRelationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get network => $composableBuilder(
      column: $table.network, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tagsJson => $composableBuilder(
      column: $table.tagsJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get memberWayIdsJson => $composableBuilder(
      column: $table.memberWayIdsJson,
      builder: (column) => ColumnFilters(column));
}

class $$OsmRelationsTableOrderingComposer
    extends Composer<_$AppDatabase, $OsmRelationsTable> {
  $$OsmRelationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get network => $composableBuilder(
      column: $table.network, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tagsJson => $composableBuilder(
      column: $table.tagsJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get memberWayIdsJson => $composableBuilder(
      column: $table.memberWayIdsJson,
      builder: (column) => ColumnOrderings(column));
}

class $$OsmRelationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OsmRelationsTable> {
  $$OsmRelationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get network =>
      $composableBuilder(column: $table.network, builder: (column) => column);

  GeneratedColumn<String> get tagsJson =>
      $composableBuilder(column: $table.tagsJson, builder: (column) => column);

  GeneratedColumn<String> get memberWayIdsJson => $composableBuilder(
      column: $table.memberWayIdsJson, builder: (column) => column);
}

class $$OsmRelationsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $OsmRelationsTable,
    OsmRelation,
    $$OsmRelationsTableFilterComposer,
    $$OsmRelationsTableOrderingComposer,
    $$OsmRelationsTableAnnotationComposer,
    $$OsmRelationsTableCreateCompanionBuilder,
    $$OsmRelationsTableUpdateCompanionBuilder,
    (
      OsmRelation,
      BaseReferences<_$AppDatabase, $OsmRelationsTable, OsmRelation>
    ),
    OsmRelation,
    PrefetchHooks Function()> {
  $$OsmRelationsTableTableManager(_$AppDatabase db, $OsmRelationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OsmRelationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OsmRelationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OsmRelationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> name = const Value.absent(),
            Value<String?> network = const Value.absent(),
            Value<String> tagsJson = const Value.absent(),
            Value<String> memberWayIdsJson = const Value.absent(),
          }) =>
              OsmRelationsCompanion(
            id: id,
            name: name,
            network: network,
            tagsJson: tagsJson,
            memberWayIdsJson: memberWayIdsJson,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> name = const Value.absent(),
            Value<String?> network = const Value.absent(),
            required String tagsJson,
            required String memberWayIdsJson,
          }) =>
              OsmRelationsCompanion.insert(
            id: id,
            name: name,
            network: network,
            tagsJson: tagsJson,
            memberWayIdsJson: memberWayIdsJson,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$OsmRelationsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $OsmRelationsTable,
    OsmRelation,
    $$OsmRelationsTableFilterComposer,
    $$OsmRelationsTableOrderingComposer,
    $$OsmRelationsTableAnnotationComposer,
    $$OsmRelationsTableCreateCompanionBuilder,
    $$OsmRelationsTableUpdateCompanionBuilder,
    (
      OsmRelation,
      BaseReferences<_$AppDatabase, $OsmRelationsTable, OsmRelation>
    ),
    OsmRelation,
    PrefetchHooks Function()>;
typedef $$PoisTableCreateCompanionBuilder = PoisCompanion Function({
  required String id,
  required String kind,
  Value<String?> name,
  required double lat,
  required double lon,
  required String tagsJson,
  Value<int> rowid,
});
typedef $$PoisTableUpdateCompanionBuilder = PoisCompanion Function({
  Value<String> id,
  Value<String> kind,
  Value<String?> name,
  Value<double> lat,
  Value<double> lon,
  Value<String> tagsJson,
  Value<int> rowid,
});

class $$PoisTableFilterComposer extends Composer<_$AppDatabase, $PoisTable> {
  $$PoisTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get lat => $composableBuilder(
      column: $table.lat, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get lon => $composableBuilder(
      column: $table.lon, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tagsJson => $composableBuilder(
      column: $table.tagsJson, builder: (column) => ColumnFilters(column));
}

class $$PoisTableOrderingComposer extends Composer<_$AppDatabase, $PoisTable> {
  $$PoisTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get lat => $composableBuilder(
      column: $table.lat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get lon => $composableBuilder(
      column: $table.lon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tagsJson => $composableBuilder(
      column: $table.tagsJson, builder: (column) => ColumnOrderings(column));
}

class $$PoisTableAnnotationComposer
    extends Composer<_$AppDatabase, $PoisTable> {
  $$PoisTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lon =>
      $composableBuilder(column: $table.lon, builder: (column) => column);

  GeneratedColumn<String> get tagsJson =>
      $composableBuilder(column: $table.tagsJson, builder: (column) => column);
}

class $$PoisTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PoisTable,
    Poi,
    $$PoisTableFilterComposer,
    $$PoisTableOrderingComposer,
    $$PoisTableAnnotationComposer,
    $$PoisTableCreateCompanionBuilder,
    $$PoisTableUpdateCompanionBuilder,
    (Poi, BaseReferences<_$AppDatabase, $PoisTable, Poi>),
    Poi,
    PrefetchHooks Function()> {
  $$PoisTableTableManager(_$AppDatabase db, $PoisTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PoisTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PoisTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PoisTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<String?> name = const Value.absent(),
            Value<double> lat = const Value.absent(),
            Value<double> lon = const Value.absent(),
            Value<String> tagsJson = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PoisCompanion(
            id: id,
            kind: kind,
            name: name,
            lat: lat,
            lon: lon,
            tagsJson: tagsJson,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String kind,
            Value<String?> name = const Value.absent(),
            required double lat,
            required double lon,
            required String tagsJson,
            Value<int> rowid = const Value.absent(),
          }) =>
              PoisCompanion.insert(
            id: id,
            kind: kind,
            name: name,
            lat: lat,
            lon: lon,
            tagsJson: tagsJson,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PoisTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PoisTable,
    Poi,
    $$PoisTableFilterComposer,
    $$PoisTableOrderingComposer,
    $$PoisTableAnnotationComposer,
    $$PoisTableCreateCompanionBuilder,
    $$PoisTableUpdateCompanionBuilder,
    (Poi, BaseReferences<_$AppDatabase, $PoisTable, Poi>),
    Poi,
    PrefetchHooks Function()>;
typedef $$CacheCellsTableCreateCompanionBuilder = CacheCellsCompanion Function({
  required String cellKey,
  required String dataset,
  required DateTime fetchedAt,
  Value<int> rowid,
});
typedef $$CacheCellsTableUpdateCompanionBuilder = CacheCellsCompanion Function({
  Value<String> cellKey,
  Value<String> dataset,
  Value<DateTime> fetchedAt,
  Value<int> rowid,
});

class $$CacheCellsTableFilterComposer
    extends Composer<_$AppDatabase, $CacheCellsTable> {
  $$CacheCellsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get cellKey => $composableBuilder(
      column: $table.cellKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dataset => $composableBuilder(
      column: $table.dataset, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
      column: $table.fetchedAt, builder: (column) => ColumnFilters(column));
}

class $$CacheCellsTableOrderingComposer
    extends Composer<_$AppDatabase, $CacheCellsTable> {
  $$CacheCellsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get cellKey => $composableBuilder(
      column: $table.cellKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dataset => $composableBuilder(
      column: $table.dataset, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
      column: $table.fetchedAt, builder: (column) => ColumnOrderings(column));
}

class $$CacheCellsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CacheCellsTable> {
  $$CacheCellsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get cellKey =>
      $composableBuilder(column: $table.cellKey, builder: (column) => column);

  GeneratedColumn<String> get dataset =>
      $composableBuilder(column: $table.dataset, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$CacheCellsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CacheCellsTable,
    CacheCell,
    $$CacheCellsTableFilterComposer,
    $$CacheCellsTableOrderingComposer,
    $$CacheCellsTableAnnotationComposer,
    $$CacheCellsTableCreateCompanionBuilder,
    $$CacheCellsTableUpdateCompanionBuilder,
    (CacheCell, BaseReferences<_$AppDatabase, $CacheCellsTable, CacheCell>),
    CacheCell,
    PrefetchHooks Function()> {
  $$CacheCellsTableTableManager(_$AppDatabase db, $CacheCellsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CacheCellsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CacheCellsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CacheCellsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> cellKey = const Value.absent(),
            Value<String> dataset = const Value.absent(),
            Value<DateTime> fetchedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CacheCellsCompanion(
            cellKey: cellKey,
            dataset: dataset,
            fetchedAt: fetchedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String cellKey,
            required String dataset,
            required DateTime fetchedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              CacheCellsCompanion.insert(
            cellKey: cellKey,
            dataset: dataset,
            fetchedAt: fetchedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CacheCellsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CacheCellsTable,
    CacheCell,
    $$CacheCellsTableFilterComposer,
    $$CacheCellsTableOrderingComposer,
    $$CacheCellsTableAnnotationComposer,
    $$CacheCellsTableCreateCompanionBuilder,
    $$CacheCellsTableUpdateCompanionBuilder,
    (CacheCell, BaseReferences<_$AppDatabase, $CacheCellsTable, CacheCell>),
    CacheCell,
    PrefetchHooks Function()>;
typedef $$UsfsRoadsTableCreateCompanionBuilder = UsfsRoadsCompanion Function({
  required String id,
  required String routeId,
  required String number,
  Value<String?> name,
  required String kind,
  required int symbol,
  Value<String?> symbolName,
  Value<bool> seasonal,
  Value<String?> surface,
  Value<String?> maintLevel,
  Value<String> accessJson,
  Value<double?> lengthMi,
  required String geomJson,
  required double minLat,
  required double minLon,
  required double maxLat,
  required double maxLon,
  Value<int> rowid,
});
typedef $$UsfsRoadsTableUpdateCompanionBuilder = UsfsRoadsCompanion Function({
  Value<String> id,
  Value<String> routeId,
  Value<String> number,
  Value<String?> name,
  Value<String> kind,
  Value<int> symbol,
  Value<String?> symbolName,
  Value<bool> seasonal,
  Value<String?> surface,
  Value<String?> maintLevel,
  Value<String> accessJson,
  Value<double?> lengthMi,
  Value<String> geomJson,
  Value<double> minLat,
  Value<double> minLon,
  Value<double> maxLat,
  Value<double> maxLon,
  Value<int> rowid,
});

class $$UsfsRoadsTableFilterComposer
    extends Composer<_$AppDatabase, $UsfsRoadsTable> {
  $$UsfsRoadsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get routeId => $composableBuilder(
      column: $table.routeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get number => $composableBuilder(
      column: $table.number, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get symbol => $composableBuilder(
      column: $table.symbol, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get symbolName => $composableBuilder(
      column: $table.symbolName, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get seasonal => $composableBuilder(
      column: $table.seasonal, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get surface => $composableBuilder(
      column: $table.surface, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get maintLevel => $composableBuilder(
      column: $table.maintLevel, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get accessJson => $composableBuilder(
      column: $table.accessJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get lengthMi => $composableBuilder(
      column: $table.lengthMi, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get geomJson => $composableBuilder(
      column: $table.geomJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get minLat => $composableBuilder(
      column: $table.minLat, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get minLon => $composableBuilder(
      column: $table.minLon, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get maxLat => $composableBuilder(
      column: $table.maxLat, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get maxLon => $composableBuilder(
      column: $table.maxLon, builder: (column) => ColumnFilters(column));
}

class $$UsfsRoadsTableOrderingComposer
    extends Composer<_$AppDatabase, $UsfsRoadsTable> {
  $$UsfsRoadsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get routeId => $composableBuilder(
      column: $table.routeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get number => $composableBuilder(
      column: $table.number, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get symbol => $composableBuilder(
      column: $table.symbol, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get symbolName => $composableBuilder(
      column: $table.symbolName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get seasonal => $composableBuilder(
      column: $table.seasonal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get surface => $composableBuilder(
      column: $table.surface, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get maintLevel => $composableBuilder(
      column: $table.maintLevel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get accessJson => $composableBuilder(
      column: $table.accessJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get lengthMi => $composableBuilder(
      column: $table.lengthMi, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get geomJson => $composableBuilder(
      column: $table.geomJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get minLat => $composableBuilder(
      column: $table.minLat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get minLon => $composableBuilder(
      column: $table.minLon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get maxLat => $composableBuilder(
      column: $table.maxLat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get maxLon => $composableBuilder(
      column: $table.maxLon, builder: (column) => ColumnOrderings(column));
}

class $$UsfsRoadsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsfsRoadsTable> {
  $$UsfsRoadsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get routeId =>
      $composableBuilder(column: $table.routeId, builder: (column) => column);

  GeneratedColumn<String> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get symbol =>
      $composableBuilder(column: $table.symbol, builder: (column) => column);

  GeneratedColumn<String> get symbolName => $composableBuilder(
      column: $table.symbolName, builder: (column) => column);

  GeneratedColumn<bool> get seasonal =>
      $composableBuilder(column: $table.seasonal, builder: (column) => column);

  GeneratedColumn<String> get surface =>
      $composableBuilder(column: $table.surface, builder: (column) => column);

  GeneratedColumn<String> get maintLevel => $composableBuilder(
      column: $table.maintLevel, builder: (column) => column);

  GeneratedColumn<String> get accessJson => $composableBuilder(
      column: $table.accessJson, builder: (column) => column);

  GeneratedColumn<double> get lengthMi =>
      $composableBuilder(column: $table.lengthMi, builder: (column) => column);

  GeneratedColumn<String> get geomJson =>
      $composableBuilder(column: $table.geomJson, builder: (column) => column);

  GeneratedColumn<double> get minLat =>
      $composableBuilder(column: $table.minLat, builder: (column) => column);

  GeneratedColumn<double> get minLon =>
      $composableBuilder(column: $table.minLon, builder: (column) => column);

  GeneratedColumn<double> get maxLat =>
      $composableBuilder(column: $table.maxLat, builder: (column) => column);

  GeneratedColumn<double> get maxLon =>
      $composableBuilder(column: $table.maxLon, builder: (column) => column);
}

class $$UsfsRoadsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UsfsRoadsTable,
    UsfsRoad,
    $$UsfsRoadsTableFilterComposer,
    $$UsfsRoadsTableOrderingComposer,
    $$UsfsRoadsTableAnnotationComposer,
    $$UsfsRoadsTableCreateCompanionBuilder,
    $$UsfsRoadsTableUpdateCompanionBuilder,
    (UsfsRoad, BaseReferences<_$AppDatabase, $UsfsRoadsTable, UsfsRoad>),
    UsfsRoad,
    PrefetchHooks Function()> {
  $$UsfsRoadsTableTableManager(_$AppDatabase db, $UsfsRoadsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsfsRoadsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsfsRoadsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsfsRoadsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> routeId = const Value.absent(),
            Value<String> number = const Value.absent(),
            Value<String?> name = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<int> symbol = const Value.absent(),
            Value<String?> symbolName = const Value.absent(),
            Value<bool> seasonal = const Value.absent(),
            Value<String?> surface = const Value.absent(),
            Value<String?> maintLevel = const Value.absent(),
            Value<String> accessJson = const Value.absent(),
            Value<double?> lengthMi = const Value.absent(),
            Value<String> geomJson = const Value.absent(),
            Value<double> minLat = const Value.absent(),
            Value<double> minLon = const Value.absent(),
            Value<double> maxLat = const Value.absent(),
            Value<double> maxLon = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UsfsRoadsCompanion(
            id: id,
            routeId: routeId,
            number: number,
            name: name,
            kind: kind,
            symbol: symbol,
            symbolName: symbolName,
            seasonal: seasonal,
            surface: surface,
            maintLevel: maintLevel,
            accessJson: accessJson,
            lengthMi: lengthMi,
            geomJson: geomJson,
            minLat: minLat,
            minLon: minLon,
            maxLat: maxLat,
            maxLon: maxLon,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String routeId,
            required String number,
            Value<String?> name = const Value.absent(),
            required String kind,
            required int symbol,
            Value<String?> symbolName = const Value.absent(),
            Value<bool> seasonal = const Value.absent(),
            Value<String?> surface = const Value.absent(),
            Value<String?> maintLevel = const Value.absent(),
            Value<String> accessJson = const Value.absent(),
            Value<double?> lengthMi = const Value.absent(),
            required String geomJson,
            required double minLat,
            required double minLon,
            required double maxLat,
            required double maxLon,
            Value<int> rowid = const Value.absent(),
          }) =>
              UsfsRoadsCompanion.insert(
            id: id,
            routeId: routeId,
            number: number,
            name: name,
            kind: kind,
            symbol: symbol,
            symbolName: symbolName,
            seasonal: seasonal,
            surface: surface,
            maintLevel: maintLevel,
            accessJson: accessJson,
            lengthMi: lengthMi,
            geomJson: geomJson,
            minLat: minLat,
            minLon: minLon,
            maxLat: maxLat,
            maxLon: maxLon,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UsfsRoadsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UsfsRoadsTable,
    UsfsRoad,
    $$UsfsRoadsTableFilterComposer,
    $$UsfsRoadsTableOrderingComposer,
    $$UsfsRoadsTableAnnotationComposer,
    $$UsfsRoadsTableCreateCompanionBuilder,
    $$UsfsRoadsTableUpdateCompanionBuilder,
    (UsfsRoad, BaseReferences<_$AppDatabase, $UsfsRoadsTable, UsfsRoad>),
    UsfsRoad,
    PrefetchHooks Function()>;
typedef $$RoutesTableCreateCompanionBuilder = RoutesCompanion Function({
  required String id,
  required String name,
  required DateTime createdAt,
  required DateTime updatedAt,
  required String geomJson,
  required double distanceM,
  required double gainM,
  required double lossM,
  required double maxElevM,
  required double minElevM,
  Value<String?> notes,
  Value<int> rowid,
});
typedef $$RoutesTableUpdateCompanionBuilder = RoutesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String> geomJson,
  Value<double> distanceM,
  Value<double> gainM,
  Value<double> lossM,
  Value<double> maxElevM,
  Value<double> minElevM,
  Value<String?> notes,
  Value<int> rowid,
});

final class $$RoutesTableReferences
    extends BaseReferences<_$AppDatabase, $RoutesTable, Route> {
  $$RoutesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$RouteWaypointsTable, List<RouteWaypoint>>
      _routeWaypointsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.routeWaypoints,
              aliasName: $_aliasNameGenerator(
                  db.routes.id, db.routeWaypoints.routeId));

  $$RouteWaypointsTableProcessedTableManager get routeWaypointsRefs {
    final manager = $$RouteWaypointsTableTableManager($_db, $_db.routeWaypoints)
        .filter((f) => f.routeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_routeWaypointsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$UserWaypointsTable, List<UserWaypoint>>
      _userWaypointsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.userWaypoints,
              aliasName:
                  $_aliasNameGenerator(db.routes.id, db.userWaypoints.routeId));

  $$UserWaypointsTableProcessedTableManager get userWaypointsRefs {
    final manager = $$UserWaypointsTableTableManager($_db, $_db.userWaypoints)
        .filter((f) => f.routeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_userWaypointsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$RoutesTableFilterComposer
    extends Composer<_$AppDatabase, $RoutesTable> {
  $$RoutesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get geomJson => $composableBuilder(
      column: $table.geomJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get distanceM => $composableBuilder(
      column: $table.distanceM, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get gainM => $composableBuilder(
      column: $table.gainM, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get lossM => $composableBuilder(
      column: $table.lossM, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get maxElevM => $composableBuilder(
      column: $table.maxElevM, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get minElevM => $composableBuilder(
      column: $table.minElevM, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  Expression<bool> routeWaypointsRefs(
      Expression<bool> Function($$RouteWaypointsTableFilterComposer f) f) {
    final $$RouteWaypointsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.routeWaypoints,
        getReferencedColumn: (t) => t.routeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RouteWaypointsTableFilterComposer(
              $db: $db,
              $table: $db.routeWaypoints,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> userWaypointsRefs(
      Expression<bool> Function($$UserWaypointsTableFilterComposer f) f) {
    final $$UserWaypointsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.userWaypoints,
        getReferencedColumn: (t) => t.routeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UserWaypointsTableFilterComposer(
              $db: $db,
              $table: $db.userWaypoints,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$RoutesTableOrderingComposer
    extends Composer<_$AppDatabase, $RoutesTable> {
  $$RoutesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get geomJson => $composableBuilder(
      column: $table.geomJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get distanceM => $composableBuilder(
      column: $table.distanceM, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get gainM => $composableBuilder(
      column: $table.gainM, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get lossM => $composableBuilder(
      column: $table.lossM, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get maxElevM => $composableBuilder(
      column: $table.maxElevM, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get minElevM => $composableBuilder(
      column: $table.minElevM, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));
}

class $$RoutesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RoutesTable> {
  $$RoutesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get geomJson =>
      $composableBuilder(column: $table.geomJson, builder: (column) => column);

  GeneratedColumn<double> get distanceM =>
      $composableBuilder(column: $table.distanceM, builder: (column) => column);

  GeneratedColumn<double> get gainM =>
      $composableBuilder(column: $table.gainM, builder: (column) => column);

  GeneratedColumn<double> get lossM =>
      $composableBuilder(column: $table.lossM, builder: (column) => column);

  GeneratedColumn<double> get maxElevM =>
      $composableBuilder(column: $table.maxElevM, builder: (column) => column);

  GeneratedColumn<double> get minElevM =>
      $composableBuilder(column: $table.minElevM, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  Expression<T> routeWaypointsRefs<T extends Object>(
      Expression<T> Function($$RouteWaypointsTableAnnotationComposer a) f) {
    final $$RouteWaypointsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.routeWaypoints,
        getReferencedColumn: (t) => t.routeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RouteWaypointsTableAnnotationComposer(
              $db: $db,
              $table: $db.routeWaypoints,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> userWaypointsRefs<T extends Object>(
      Expression<T> Function($$UserWaypointsTableAnnotationComposer a) f) {
    final $$UserWaypointsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.userWaypoints,
        getReferencedColumn: (t) => t.routeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UserWaypointsTableAnnotationComposer(
              $db: $db,
              $table: $db.userWaypoints,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$RoutesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RoutesTable,
    Route,
    $$RoutesTableFilterComposer,
    $$RoutesTableOrderingComposer,
    $$RoutesTableAnnotationComposer,
    $$RoutesTableCreateCompanionBuilder,
    $$RoutesTableUpdateCompanionBuilder,
    (Route, $$RoutesTableReferences),
    Route,
    PrefetchHooks Function({bool routeWaypointsRefs, bool userWaypointsRefs})> {
  $$RoutesTableTableManager(_$AppDatabase db, $RoutesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RoutesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RoutesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RoutesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<String> geomJson = const Value.absent(),
            Value<double> distanceM = const Value.absent(),
            Value<double> gainM = const Value.absent(),
            Value<double> lossM = const Value.absent(),
            Value<double> maxElevM = const Value.absent(),
            Value<double> minElevM = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RoutesCompanion(
            id: id,
            name: name,
            createdAt: createdAt,
            updatedAt: updatedAt,
            geomJson: geomJson,
            distanceM: distanceM,
            gainM: gainM,
            lossM: lossM,
            maxElevM: maxElevM,
            minElevM: minElevM,
            notes: notes,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required DateTime createdAt,
            required DateTime updatedAt,
            required String geomJson,
            required double distanceM,
            required double gainM,
            required double lossM,
            required double maxElevM,
            required double minElevM,
            Value<String?> notes = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RoutesCompanion.insert(
            id: id,
            name: name,
            createdAt: createdAt,
            updatedAt: updatedAt,
            geomJson: geomJson,
            distanceM: distanceM,
            gainM: gainM,
            lossM: lossM,
            maxElevM: maxElevM,
            minElevM: minElevM,
            notes: notes,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$RoutesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {routeWaypointsRefs = false, userWaypointsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (routeWaypointsRefs) db.routeWaypoints,
                if (userWaypointsRefs) db.userWaypoints
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (routeWaypointsRefs)
                    await $_getPrefetchedData<Route, $RoutesTable,
                            RouteWaypoint>(
                        currentTable: table,
                        referencedTable: $$RoutesTableReferences
                            ._routeWaypointsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$RoutesTableReferences(db, table, p0)
                                .routeWaypointsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.routeId == item.id),
                        typedResults: items),
                  if (userWaypointsRefs)
                    await $_getPrefetchedData<Route, $RoutesTable,
                            UserWaypoint>(
                        currentTable: table,
                        referencedTable:
                            $$RoutesTableReferences._userWaypointsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$RoutesTableReferences(db, table, p0)
                                .userWaypointsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.routeId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$RoutesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RoutesTable,
    Route,
    $$RoutesTableFilterComposer,
    $$RoutesTableOrderingComposer,
    $$RoutesTableAnnotationComposer,
    $$RoutesTableCreateCompanionBuilder,
    $$RoutesTableUpdateCompanionBuilder,
    (Route, $$RoutesTableReferences),
    Route,
    PrefetchHooks Function({bool routeWaypointsRefs, bool userWaypointsRefs})>;
typedef $$RouteWaypointsTableCreateCompanionBuilder = RouteWaypointsCompanion
    Function({
  required String routeId,
  required int ordinal,
  required double lat,
  required double lon,
  Value<String?> label,
  Value<int> rowid,
});
typedef $$RouteWaypointsTableUpdateCompanionBuilder = RouteWaypointsCompanion
    Function({
  Value<String> routeId,
  Value<int> ordinal,
  Value<double> lat,
  Value<double> lon,
  Value<String?> label,
  Value<int> rowid,
});

final class $$RouteWaypointsTableReferences
    extends BaseReferences<_$AppDatabase, $RouteWaypointsTable, RouteWaypoint> {
  $$RouteWaypointsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $RoutesTable _routeIdTable(_$AppDatabase db) => db.routes.createAlias(
      $_aliasNameGenerator(db.routeWaypoints.routeId, db.routes.id));

  $$RoutesTableProcessedTableManager get routeId {
    final $_column = $_itemColumn<String>('route_id')!;

    final manager = $$RoutesTableTableManager($_db, $_db.routes)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_routeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$RouteWaypointsTableFilterComposer
    extends Composer<_$AppDatabase, $RouteWaypointsTable> {
  $$RouteWaypointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get ordinal => $composableBuilder(
      column: $table.ordinal, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get lat => $composableBuilder(
      column: $table.lat, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get lon => $composableBuilder(
      column: $table.lon, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnFilters(column));

  $$RoutesTableFilterComposer get routeId {
    final $$RoutesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.routeId,
        referencedTable: $db.routes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RoutesTableFilterComposer(
              $db: $db,
              $table: $db.routes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RouteWaypointsTableOrderingComposer
    extends Composer<_$AppDatabase, $RouteWaypointsTable> {
  $$RouteWaypointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get ordinal => $composableBuilder(
      column: $table.ordinal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get lat => $composableBuilder(
      column: $table.lat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get lon => $composableBuilder(
      column: $table.lon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnOrderings(column));

  $$RoutesTableOrderingComposer get routeId {
    final $$RoutesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.routeId,
        referencedTable: $db.routes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RoutesTableOrderingComposer(
              $db: $db,
              $table: $db.routes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RouteWaypointsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RouteWaypointsTable> {
  $$RouteWaypointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get ordinal =>
      $composableBuilder(column: $table.ordinal, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lon =>
      $composableBuilder(column: $table.lon, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  $$RoutesTableAnnotationComposer get routeId {
    final $$RoutesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.routeId,
        referencedTable: $db.routes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RoutesTableAnnotationComposer(
              $db: $db,
              $table: $db.routes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RouteWaypointsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RouteWaypointsTable,
    RouteWaypoint,
    $$RouteWaypointsTableFilterComposer,
    $$RouteWaypointsTableOrderingComposer,
    $$RouteWaypointsTableAnnotationComposer,
    $$RouteWaypointsTableCreateCompanionBuilder,
    $$RouteWaypointsTableUpdateCompanionBuilder,
    (RouteWaypoint, $$RouteWaypointsTableReferences),
    RouteWaypoint,
    PrefetchHooks Function({bool routeId})> {
  $$RouteWaypointsTableTableManager(
      _$AppDatabase db, $RouteWaypointsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RouteWaypointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RouteWaypointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RouteWaypointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> routeId = const Value.absent(),
            Value<int> ordinal = const Value.absent(),
            Value<double> lat = const Value.absent(),
            Value<double> lon = const Value.absent(),
            Value<String?> label = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RouteWaypointsCompanion(
            routeId: routeId,
            ordinal: ordinal,
            lat: lat,
            lon: lon,
            label: label,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String routeId,
            required int ordinal,
            required double lat,
            required double lon,
            Value<String?> label = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RouteWaypointsCompanion.insert(
            routeId: routeId,
            ordinal: ordinal,
            lat: lat,
            lon: lon,
            label: label,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$RouteWaypointsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({routeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (routeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.routeId,
                    referencedTable:
                        $$RouteWaypointsTableReferences._routeIdTable(db),
                    referencedColumn:
                        $$RouteWaypointsTableReferences._routeIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$RouteWaypointsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RouteWaypointsTable,
    RouteWaypoint,
    $$RouteWaypointsTableFilterComposer,
    $$RouteWaypointsTableOrderingComposer,
    $$RouteWaypointsTableAnnotationComposer,
    $$RouteWaypointsTableCreateCompanionBuilder,
    $$RouteWaypointsTableUpdateCompanionBuilder,
    (RouteWaypoint, $$RouteWaypointsTableReferences),
    RouteWaypoint,
    PrefetchHooks Function({bool routeId})>;
typedef $$TracksTableCreateCompanionBuilder = TracksCompanion Function({
  required String id,
  required String name,
  required DateTime startedAt,
  Value<DateTime?> endedAt,
  Value<double> distanceM,
  Value<int> movingSeconds,
  Value<int> totalSeconds,
  Value<double> gainM,
  Value<double> lossM,
  Value<double?> packWeightKg,
  Value<double?> calories,
  Value<String?> linkedRouteId,
  Value<DateTime> lastModified,
  Value<int?> batteryStartPct,
  Value<int?> batteryEndPct,
  Value<int> rowid,
});
typedef $$TracksTableUpdateCompanionBuilder = TracksCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<DateTime> startedAt,
  Value<DateTime?> endedAt,
  Value<double> distanceM,
  Value<int> movingSeconds,
  Value<int> totalSeconds,
  Value<double> gainM,
  Value<double> lossM,
  Value<double?> packWeightKg,
  Value<double?> calories,
  Value<String?> linkedRouteId,
  Value<DateTime> lastModified,
  Value<int?> batteryStartPct,
  Value<int?> batteryEndPct,
  Value<int> rowid,
});

final class $$TracksTableReferences
    extends BaseReferences<_$AppDatabase, $TracksTable, Track> {
  $$TracksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TrackPointsTable, List<TrackPoint>>
      _trackPointsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.trackPoints,
              aliasName:
                  $_aliasNameGenerator(db.tracks.id, db.trackPoints.trackId));

  $$TrackPointsTableProcessedTableManager get trackPointsRefs {
    final manager = $$TrackPointsTableTableManager($_db, $_db.trackPoints)
        .filter((f) => f.trackId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_trackPointsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$TracksTableFilterComposer
    extends Composer<_$AppDatabase, $TracksTable> {
  $$TracksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
      column: $table.endedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get distanceM => $composableBuilder(
      column: $table.distanceM, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get movingSeconds => $composableBuilder(
      column: $table.movingSeconds, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalSeconds => $composableBuilder(
      column: $table.totalSeconds, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get gainM => $composableBuilder(
      column: $table.gainM, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get lossM => $composableBuilder(
      column: $table.lossM, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get packWeightKg => $composableBuilder(
      column: $table.packWeightKg, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get calories => $composableBuilder(
      column: $table.calories, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get linkedRouteId => $composableBuilder(
      column: $table.linkedRouteId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastModified => $composableBuilder(
      column: $table.lastModified, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get batteryStartPct => $composableBuilder(
      column: $table.batteryStartPct,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get batteryEndPct => $composableBuilder(
      column: $table.batteryEndPct, builder: (column) => ColumnFilters(column));

  Expression<bool> trackPointsRefs(
      Expression<bool> Function($$TrackPointsTableFilterComposer f) f) {
    final $$TrackPointsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.trackPoints,
        getReferencedColumn: (t) => t.trackId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TrackPointsTableFilterComposer(
              $db: $db,
              $table: $db.trackPoints,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TracksTableOrderingComposer
    extends Composer<_$AppDatabase, $TracksTable> {
  $$TracksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
      column: $table.endedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get distanceM => $composableBuilder(
      column: $table.distanceM, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get movingSeconds => $composableBuilder(
      column: $table.movingSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalSeconds => $composableBuilder(
      column: $table.totalSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get gainM => $composableBuilder(
      column: $table.gainM, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get lossM => $composableBuilder(
      column: $table.lossM, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get packWeightKg => $composableBuilder(
      column: $table.packWeightKg,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get calories => $composableBuilder(
      column: $table.calories, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get linkedRouteId => $composableBuilder(
      column: $table.linkedRouteId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastModified => $composableBuilder(
      column: $table.lastModified,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get batteryStartPct => $composableBuilder(
      column: $table.batteryStartPct,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get batteryEndPct => $composableBuilder(
      column: $table.batteryEndPct,
      builder: (column) => ColumnOrderings(column));
}

class $$TracksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TracksTable> {
  $$TracksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<double> get distanceM =>
      $composableBuilder(column: $table.distanceM, builder: (column) => column);

  GeneratedColumn<int> get movingSeconds => $composableBuilder(
      column: $table.movingSeconds, builder: (column) => column);

  GeneratedColumn<int> get totalSeconds => $composableBuilder(
      column: $table.totalSeconds, builder: (column) => column);

  GeneratedColumn<double> get gainM =>
      $composableBuilder(column: $table.gainM, builder: (column) => column);

  GeneratedColumn<double> get lossM =>
      $composableBuilder(column: $table.lossM, builder: (column) => column);

  GeneratedColumn<double> get packWeightKg => $composableBuilder(
      column: $table.packWeightKg, builder: (column) => column);

  GeneratedColumn<double> get calories =>
      $composableBuilder(column: $table.calories, builder: (column) => column);

  GeneratedColumn<String> get linkedRouteId => $composableBuilder(
      column: $table.linkedRouteId, builder: (column) => column);

  GeneratedColumn<DateTime> get lastModified => $composableBuilder(
      column: $table.lastModified, builder: (column) => column);

  GeneratedColumn<int> get batteryStartPct => $composableBuilder(
      column: $table.batteryStartPct, builder: (column) => column);

  GeneratedColumn<int> get batteryEndPct => $composableBuilder(
      column: $table.batteryEndPct, builder: (column) => column);

  Expression<T> trackPointsRefs<T extends Object>(
      Expression<T> Function($$TrackPointsTableAnnotationComposer a) f) {
    final $$TrackPointsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.trackPoints,
        getReferencedColumn: (t) => t.trackId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TrackPointsTableAnnotationComposer(
              $db: $db,
              $table: $db.trackPoints,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TracksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TracksTable,
    Track,
    $$TracksTableFilterComposer,
    $$TracksTableOrderingComposer,
    $$TracksTableAnnotationComposer,
    $$TracksTableCreateCompanionBuilder,
    $$TracksTableUpdateCompanionBuilder,
    (Track, $$TracksTableReferences),
    Track,
    PrefetchHooks Function({bool trackPointsRefs})> {
  $$TracksTableTableManager(_$AppDatabase db, $TracksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TracksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TracksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TracksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<DateTime> startedAt = const Value.absent(),
            Value<DateTime?> endedAt = const Value.absent(),
            Value<double> distanceM = const Value.absent(),
            Value<int> movingSeconds = const Value.absent(),
            Value<int> totalSeconds = const Value.absent(),
            Value<double> gainM = const Value.absent(),
            Value<double> lossM = const Value.absent(),
            Value<double?> packWeightKg = const Value.absent(),
            Value<double?> calories = const Value.absent(),
            Value<String?> linkedRouteId = const Value.absent(),
            Value<DateTime> lastModified = const Value.absent(),
            Value<int?> batteryStartPct = const Value.absent(),
            Value<int?> batteryEndPct = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TracksCompanion(
            id: id,
            name: name,
            startedAt: startedAt,
            endedAt: endedAt,
            distanceM: distanceM,
            movingSeconds: movingSeconds,
            totalSeconds: totalSeconds,
            gainM: gainM,
            lossM: lossM,
            packWeightKg: packWeightKg,
            calories: calories,
            linkedRouteId: linkedRouteId,
            lastModified: lastModified,
            batteryStartPct: batteryStartPct,
            batteryEndPct: batteryEndPct,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required DateTime startedAt,
            Value<DateTime?> endedAt = const Value.absent(),
            Value<double> distanceM = const Value.absent(),
            Value<int> movingSeconds = const Value.absent(),
            Value<int> totalSeconds = const Value.absent(),
            Value<double> gainM = const Value.absent(),
            Value<double> lossM = const Value.absent(),
            Value<double?> packWeightKg = const Value.absent(),
            Value<double?> calories = const Value.absent(),
            Value<String?> linkedRouteId = const Value.absent(),
            Value<DateTime> lastModified = const Value.absent(),
            Value<int?> batteryStartPct = const Value.absent(),
            Value<int?> batteryEndPct = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TracksCompanion.insert(
            id: id,
            name: name,
            startedAt: startedAt,
            endedAt: endedAt,
            distanceM: distanceM,
            movingSeconds: movingSeconds,
            totalSeconds: totalSeconds,
            gainM: gainM,
            lossM: lossM,
            packWeightKg: packWeightKg,
            calories: calories,
            linkedRouteId: linkedRouteId,
            lastModified: lastModified,
            batteryStartPct: batteryStartPct,
            batteryEndPct: batteryEndPct,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$TracksTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({trackPointsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (trackPointsRefs) db.trackPoints],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (trackPointsRefs)
                    await $_getPrefetchedData<Track, $TracksTable, TrackPoint>(
                        currentTable: table,
                        referencedTable:
                            $$TracksTableReferences._trackPointsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$TracksTableReferences(db, table, p0)
                                .trackPointsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.trackId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$TracksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TracksTable,
    Track,
    $$TracksTableFilterComposer,
    $$TracksTableOrderingComposer,
    $$TracksTableAnnotationComposer,
    $$TracksTableCreateCompanionBuilder,
    $$TracksTableUpdateCompanionBuilder,
    (Track, $$TracksTableReferences),
    Track,
    PrefetchHooks Function({bool trackPointsRefs})>;
typedef $$TrackPointsTableCreateCompanionBuilder = TrackPointsCompanion
    Function({
  required String trackId,
  required int seq,
  required DateTime t,
  required double lat,
  required double lon,
  Value<double?> gpsAltM,
  Value<double?> demAltM,
  Value<double?> accuracyM,
  Value<double?> speedMps,
  Value<int> rowid,
});
typedef $$TrackPointsTableUpdateCompanionBuilder = TrackPointsCompanion
    Function({
  Value<String> trackId,
  Value<int> seq,
  Value<DateTime> t,
  Value<double> lat,
  Value<double> lon,
  Value<double?> gpsAltM,
  Value<double?> demAltM,
  Value<double?> accuracyM,
  Value<double?> speedMps,
  Value<int> rowid,
});

final class $$TrackPointsTableReferences
    extends BaseReferences<_$AppDatabase, $TrackPointsTable, TrackPoint> {
  $$TrackPointsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TracksTable _trackIdTable(_$AppDatabase db) => db.tracks
      .createAlias($_aliasNameGenerator(db.trackPoints.trackId, db.tracks.id));

  $$TracksTableProcessedTableManager get trackId {
    final $_column = $_itemColumn<String>('track_id')!;

    final manager = $$TracksTableTableManager($_db, $_db.tracks)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_trackIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$TrackPointsTableFilterComposer
    extends Composer<_$AppDatabase, $TrackPointsTable> {
  $$TrackPointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get seq => $composableBuilder(
      column: $table.seq, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get t => $composableBuilder(
      column: $table.t, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get lat => $composableBuilder(
      column: $table.lat, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get lon => $composableBuilder(
      column: $table.lon, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get gpsAltM => $composableBuilder(
      column: $table.gpsAltM, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get demAltM => $composableBuilder(
      column: $table.demAltM, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get accuracyM => $composableBuilder(
      column: $table.accuracyM, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get speedMps => $composableBuilder(
      column: $table.speedMps, builder: (column) => ColumnFilters(column));

  $$TracksTableFilterComposer get trackId {
    final $$TracksTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.trackId,
        referencedTable: $db.tracks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TracksTableFilterComposer(
              $db: $db,
              $table: $db.tracks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TrackPointsTableOrderingComposer
    extends Composer<_$AppDatabase, $TrackPointsTable> {
  $$TrackPointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get seq => $composableBuilder(
      column: $table.seq, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get t => $composableBuilder(
      column: $table.t, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get lat => $composableBuilder(
      column: $table.lat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get lon => $composableBuilder(
      column: $table.lon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get gpsAltM => $composableBuilder(
      column: $table.gpsAltM, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get demAltM => $composableBuilder(
      column: $table.demAltM, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get accuracyM => $composableBuilder(
      column: $table.accuracyM, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get speedMps => $composableBuilder(
      column: $table.speedMps, builder: (column) => ColumnOrderings(column));

  $$TracksTableOrderingComposer get trackId {
    final $$TracksTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.trackId,
        referencedTable: $db.tracks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TracksTableOrderingComposer(
              $db: $db,
              $table: $db.tracks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TrackPointsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrackPointsTable> {
  $$TrackPointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<DateTime> get t =>
      $composableBuilder(column: $table.t, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lon =>
      $composableBuilder(column: $table.lon, builder: (column) => column);

  GeneratedColumn<double> get gpsAltM =>
      $composableBuilder(column: $table.gpsAltM, builder: (column) => column);

  GeneratedColumn<double> get demAltM =>
      $composableBuilder(column: $table.demAltM, builder: (column) => column);

  GeneratedColumn<double> get accuracyM =>
      $composableBuilder(column: $table.accuracyM, builder: (column) => column);

  GeneratedColumn<double> get speedMps =>
      $composableBuilder(column: $table.speedMps, builder: (column) => column);

  $$TracksTableAnnotationComposer get trackId {
    final $$TracksTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.trackId,
        referencedTable: $db.tracks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TracksTableAnnotationComposer(
              $db: $db,
              $table: $db.tracks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TrackPointsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TrackPointsTable,
    TrackPoint,
    $$TrackPointsTableFilterComposer,
    $$TrackPointsTableOrderingComposer,
    $$TrackPointsTableAnnotationComposer,
    $$TrackPointsTableCreateCompanionBuilder,
    $$TrackPointsTableUpdateCompanionBuilder,
    (TrackPoint, $$TrackPointsTableReferences),
    TrackPoint,
    PrefetchHooks Function({bool trackId})> {
  $$TrackPointsTableTableManager(_$AppDatabase db, $TrackPointsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrackPointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrackPointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrackPointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> trackId = const Value.absent(),
            Value<int> seq = const Value.absent(),
            Value<DateTime> t = const Value.absent(),
            Value<double> lat = const Value.absent(),
            Value<double> lon = const Value.absent(),
            Value<double?> gpsAltM = const Value.absent(),
            Value<double?> demAltM = const Value.absent(),
            Value<double?> accuracyM = const Value.absent(),
            Value<double?> speedMps = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TrackPointsCompanion(
            trackId: trackId,
            seq: seq,
            t: t,
            lat: lat,
            lon: lon,
            gpsAltM: gpsAltM,
            demAltM: demAltM,
            accuracyM: accuracyM,
            speedMps: speedMps,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String trackId,
            required int seq,
            required DateTime t,
            required double lat,
            required double lon,
            Value<double?> gpsAltM = const Value.absent(),
            Value<double?> demAltM = const Value.absent(),
            Value<double?> accuracyM = const Value.absent(),
            Value<double?> speedMps = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TrackPointsCompanion.insert(
            trackId: trackId,
            seq: seq,
            t: t,
            lat: lat,
            lon: lon,
            gpsAltM: gpsAltM,
            demAltM: demAltM,
            accuracyM: accuracyM,
            speedMps: speedMps,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$TrackPointsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({trackId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (trackId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.trackId,
                    referencedTable:
                        $$TrackPointsTableReferences._trackIdTable(db),
                    referencedColumn:
                        $$TrackPointsTableReferences._trackIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$TrackPointsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TrackPointsTable,
    TrackPoint,
    $$TrackPointsTableFilterComposer,
    $$TrackPointsTableOrderingComposer,
    $$TrackPointsTableAnnotationComposer,
    $$TrackPointsTableCreateCompanionBuilder,
    $$TrackPointsTableUpdateCompanionBuilder,
    (TrackPoint, $$TrackPointsTableReferences),
    TrackPoint,
    PrefetchHooks Function({bool trackId})>;
typedef $$OfflineRegionsTableCreateCompanionBuilder = OfflineRegionsCompanion
    Function({
  required String id,
  required String name,
  required double minLat,
  required double minLon,
  required double maxLat,
  required double maxLon,
  Value<int?> maplibreRegionId,
  required String styleKey,
  required int minZoom,
  required int maxZoom,
  required DateTime createdAt,
  required int status,
  Value<int?> tileCount,
  Value<int?> bytes,
  Value<String> overlayKeys,
  Value<int> rowid,
});
typedef $$OfflineRegionsTableUpdateCompanionBuilder = OfflineRegionsCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<double> minLat,
  Value<double> minLon,
  Value<double> maxLat,
  Value<double> maxLon,
  Value<int?> maplibreRegionId,
  Value<String> styleKey,
  Value<int> minZoom,
  Value<int> maxZoom,
  Value<DateTime> createdAt,
  Value<int> status,
  Value<int?> tileCount,
  Value<int?> bytes,
  Value<String> overlayKeys,
  Value<int> rowid,
});

class $$OfflineRegionsTableFilterComposer
    extends Composer<_$AppDatabase, $OfflineRegionsTable> {
  $$OfflineRegionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get minLat => $composableBuilder(
      column: $table.minLat, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get minLon => $composableBuilder(
      column: $table.minLon, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get maxLat => $composableBuilder(
      column: $table.maxLat, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get maxLon => $composableBuilder(
      column: $table.maxLon, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get maplibreRegionId => $composableBuilder(
      column: $table.maplibreRegionId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get styleKey => $composableBuilder(
      column: $table.styleKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get minZoom => $composableBuilder(
      column: $table.minZoom, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get maxZoom => $composableBuilder(
      column: $table.maxZoom, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get tileCount => $composableBuilder(
      column: $table.tileCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get bytes => $composableBuilder(
      column: $table.bytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get overlayKeys => $composableBuilder(
      column: $table.overlayKeys, builder: (column) => ColumnFilters(column));
}

class $$OfflineRegionsTableOrderingComposer
    extends Composer<_$AppDatabase, $OfflineRegionsTable> {
  $$OfflineRegionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get minLat => $composableBuilder(
      column: $table.minLat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get minLon => $composableBuilder(
      column: $table.minLon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get maxLat => $composableBuilder(
      column: $table.maxLat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get maxLon => $composableBuilder(
      column: $table.maxLon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get maplibreRegionId => $composableBuilder(
      column: $table.maplibreRegionId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get styleKey => $composableBuilder(
      column: $table.styleKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get minZoom => $composableBuilder(
      column: $table.minZoom, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get maxZoom => $composableBuilder(
      column: $table.maxZoom, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get tileCount => $composableBuilder(
      column: $table.tileCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get bytes => $composableBuilder(
      column: $table.bytes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get overlayKeys => $composableBuilder(
      column: $table.overlayKeys, builder: (column) => ColumnOrderings(column));
}

class $$OfflineRegionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OfflineRegionsTable> {
  $$OfflineRegionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get minLat =>
      $composableBuilder(column: $table.minLat, builder: (column) => column);

  GeneratedColumn<double> get minLon =>
      $composableBuilder(column: $table.minLon, builder: (column) => column);

  GeneratedColumn<double> get maxLat =>
      $composableBuilder(column: $table.maxLat, builder: (column) => column);

  GeneratedColumn<double> get maxLon =>
      $composableBuilder(column: $table.maxLon, builder: (column) => column);

  GeneratedColumn<int> get maplibreRegionId => $composableBuilder(
      column: $table.maplibreRegionId, builder: (column) => column);

  GeneratedColumn<String> get styleKey =>
      $composableBuilder(column: $table.styleKey, builder: (column) => column);

  GeneratedColumn<int> get minZoom =>
      $composableBuilder(column: $table.minZoom, builder: (column) => column);

  GeneratedColumn<int> get maxZoom =>
      $composableBuilder(column: $table.maxZoom, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get tileCount =>
      $composableBuilder(column: $table.tileCount, builder: (column) => column);

  GeneratedColumn<int> get bytes =>
      $composableBuilder(column: $table.bytes, builder: (column) => column);

  GeneratedColumn<String> get overlayKeys => $composableBuilder(
      column: $table.overlayKeys, builder: (column) => column);
}

class $$OfflineRegionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $OfflineRegionsTable,
    OfflineRegion,
    $$OfflineRegionsTableFilterComposer,
    $$OfflineRegionsTableOrderingComposer,
    $$OfflineRegionsTableAnnotationComposer,
    $$OfflineRegionsTableCreateCompanionBuilder,
    $$OfflineRegionsTableUpdateCompanionBuilder,
    (
      OfflineRegion,
      BaseReferences<_$AppDatabase, $OfflineRegionsTable, OfflineRegion>
    ),
    OfflineRegion,
    PrefetchHooks Function()> {
  $$OfflineRegionsTableTableManager(
      _$AppDatabase db, $OfflineRegionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OfflineRegionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OfflineRegionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OfflineRegionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<double> minLat = const Value.absent(),
            Value<double> minLon = const Value.absent(),
            Value<double> maxLat = const Value.absent(),
            Value<double> maxLon = const Value.absent(),
            Value<int?> maplibreRegionId = const Value.absent(),
            Value<String> styleKey = const Value.absent(),
            Value<int> minZoom = const Value.absent(),
            Value<int> maxZoom = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> status = const Value.absent(),
            Value<int?> tileCount = const Value.absent(),
            Value<int?> bytes = const Value.absent(),
            Value<String> overlayKeys = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OfflineRegionsCompanion(
            id: id,
            name: name,
            minLat: minLat,
            minLon: minLon,
            maxLat: maxLat,
            maxLon: maxLon,
            maplibreRegionId: maplibreRegionId,
            styleKey: styleKey,
            minZoom: minZoom,
            maxZoom: maxZoom,
            createdAt: createdAt,
            status: status,
            tileCount: tileCount,
            bytes: bytes,
            overlayKeys: overlayKeys,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required double minLat,
            required double minLon,
            required double maxLat,
            required double maxLon,
            Value<int?> maplibreRegionId = const Value.absent(),
            required String styleKey,
            required int minZoom,
            required int maxZoom,
            required DateTime createdAt,
            required int status,
            Value<int?> tileCount = const Value.absent(),
            Value<int?> bytes = const Value.absent(),
            Value<String> overlayKeys = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OfflineRegionsCompanion.insert(
            id: id,
            name: name,
            minLat: minLat,
            minLon: minLon,
            maxLat: maxLat,
            maxLon: maxLon,
            maplibreRegionId: maplibreRegionId,
            styleKey: styleKey,
            minZoom: minZoom,
            maxZoom: maxZoom,
            createdAt: createdAt,
            status: status,
            tileCount: tileCount,
            bytes: bytes,
            overlayKeys: overlayKeys,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$OfflineRegionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $OfflineRegionsTable,
    OfflineRegion,
    $$OfflineRegionsTableFilterComposer,
    $$OfflineRegionsTableOrderingComposer,
    $$OfflineRegionsTableAnnotationComposer,
    $$OfflineRegionsTableCreateCompanionBuilder,
    $$OfflineRegionsTableUpdateCompanionBuilder,
    (
      OfflineRegion,
      BaseReferences<_$AppDatabase, $OfflineRegionsTable, OfflineRegion>
    ),
    OfflineRegion,
    PrefetchHooks Function()>;
typedef $$ConditionsCacheTableCreateCompanionBuilder = ConditionsCacheCompanion
    Function({
  required String key,
  required String bodyJson,
  required DateTime fetchedAt,
  Value<int> rowid,
});
typedef $$ConditionsCacheTableUpdateCompanionBuilder = ConditionsCacheCompanion
    Function({
  Value<String> key,
  Value<String> bodyJson,
  Value<DateTime> fetchedAt,
  Value<int> rowid,
});

class $$ConditionsCacheTableFilterComposer
    extends Composer<_$AppDatabase, $ConditionsCacheTable> {
  $$ConditionsCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bodyJson => $composableBuilder(
      column: $table.bodyJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
      column: $table.fetchedAt, builder: (column) => ColumnFilters(column));
}

class $$ConditionsCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $ConditionsCacheTable> {
  $$ConditionsCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bodyJson => $composableBuilder(
      column: $table.bodyJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
      column: $table.fetchedAt, builder: (column) => ColumnOrderings(column));
}

class $$ConditionsCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConditionsCacheTable> {
  $$ConditionsCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get bodyJson =>
      $composableBuilder(column: $table.bodyJson, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$ConditionsCacheTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ConditionsCacheTable,
    ConditionsCacheData,
    $$ConditionsCacheTableFilterComposer,
    $$ConditionsCacheTableOrderingComposer,
    $$ConditionsCacheTableAnnotationComposer,
    $$ConditionsCacheTableCreateCompanionBuilder,
    $$ConditionsCacheTableUpdateCompanionBuilder,
    (
      ConditionsCacheData,
      BaseReferences<_$AppDatabase, $ConditionsCacheTable, ConditionsCacheData>
    ),
    ConditionsCacheData,
    PrefetchHooks Function()> {
  $$ConditionsCacheTableTableManager(
      _$AppDatabase db, $ConditionsCacheTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConditionsCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConditionsCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConditionsCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> bodyJson = const Value.absent(),
            Value<DateTime> fetchedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ConditionsCacheCompanion(
            key: key,
            bodyJson: bodyJson,
            fetchedAt: fetchedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String bodyJson,
            required DateTime fetchedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ConditionsCacheCompanion.insert(
            key: key,
            bodyJson: bodyJson,
            fetchedAt: fetchedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ConditionsCacheTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ConditionsCacheTable,
    ConditionsCacheData,
    $$ConditionsCacheTableFilterComposer,
    $$ConditionsCacheTableOrderingComposer,
    $$ConditionsCacheTableAnnotationComposer,
    $$ConditionsCacheTableCreateCompanionBuilder,
    $$ConditionsCacheTableUpdateCompanionBuilder,
    (
      ConditionsCacheData,
      BaseReferences<_$AppDatabase, $ConditionsCacheTable, ConditionsCacheData>
    ),
    ConditionsCacheData,
    PrefetchHooks Function()>;
typedef $$TombstonesTableCreateCompanionBuilder = TombstonesCompanion Function({
  required String entityType,
  required String entityId,
  required DateTime deletedAt,
  Value<int> rowid,
});
typedef $$TombstonesTableUpdateCompanionBuilder = TombstonesCompanion Function({
  Value<String> entityType,
  Value<String> entityId,
  Value<DateTime> deletedAt,
  Value<int> rowid,
});

class $$TombstonesTableFilterComposer
    extends Composer<_$AppDatabase, $TombstonesTable> {
  $$TombstonesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));
}

class $$TombstonesTableOrderingComposer
    extends Composer<_$AppDatabase, $TombstonesTable> {
  $$TombstonesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$TombstonesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TombstonesTable> {
  $$TombstonesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$TombstonesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TombstonesTable,
    Tombstone,
    $$TombstonesTableFilterComposer,
    $$TombstonesTableOrderingComposer,
    $$TombstonesTableAnnotationComposer,
    $$TombstonesTableCreateCompanionBuilder,
    $$TombstonesTableUpdateCompanionBuilder,
    (Tombstone, BaseReferences<_$AppDatabase, $TombstonesTable, Tombstone>),
    Tombstone,
    PrefetchHooks Function()> {
  $$TombstonesTableTableManager(_$AppDatabase db, $TombstonesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TombstonesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TombstonesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TombstonesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> entityType = const Value.absent(),
            Value<String> entityId = const Value.absent(),
            Value<DateTime> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TombstonesCompanion(
            entityType: entityType,
            entityId: entityId,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String entityType,
            required String entityId,
            required DateTime deletedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              TombstonesCompanion.insert(
            entityType: entityType,
            entityId: entityId,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TombstonesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TombstonesTable,
    Tombstone,
    $$TombstonesTableFilterComposer,
    $$TombstonesTableOrderingComposer,
    $$TombstonesTableAnnotationComposer,
    $$TombstonesTableCreateCompanionBuilder,
    $$TombstonesTableUpdateCompanionBuilder,
    (Tombstone, BaseReferences<_$AppDatabase, $TombstonesTable, Tombstone>),
    Tombstone,
    PrefetchHooks Function()>;
typedef $$FavoriteTrailsTableCreateCompanionBuilder = FavoriteTrailsCompanion
    Function({
  required String trailId,
  required String name,
  required double centerLat,
  required double centerLon,
  Value<double?> lengthM,
  required DateTime savedAt,
  Value<int> rowid,
});
typedef $$FavoriteTrailsTableUpdateCompanionBuilder = FavoriteTrailsCompanion
    Function({
  Value<String> trailId,
  Value<String> name,
  Value<double> centerLat,
  Value<double> centerLon,
  Value<double?> lengthM,
  Value<DateTime> savedAt,
  Value<int> rowid,
});

class $$FavoriteTrailsTableFilterComposer
    extends Composer<_$AppDatabase, $FavoriteTrailsTable> {
  $$FavoriteTrailsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get trailId => $composableBuilder(
      column: $table.trailId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get centerLat => $composableBuilder(
      column: $table.centerLat, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get centerLon => $composableBuilder(
      column: $table.centerLon, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get lengthM => $composableBuilder(
      column: $table.lengthM, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get savedAt => $composableBuilder(
      column: $table.savedAt, builder: (column) => ColumnFilters(column));
}

class $$FavoriteTrailsTableOrderingComposer
    extends Composer<_$AppDatabase, $FavoriteTrailsTable> {
  $$FavoriteTrailsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get trailId => $composableBuilder(
      column: $table.trailId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get centerLat => $composableBuilder(
      column: $table.centerLat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get centerLon => $composableBuilder(
      column: $table.centerLon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get lengthM => $composableBuilder(
      column: $table.lengthM, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get savedAt => $composableBuilder(
      column: $table.savedAt, builder: (column) => ColumnOrderings(column));
}

class $$FavoriteTrailsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FavoriteTrailsTable> {
  $$FavoriteTrailsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get trailId =>
      $composableBuilder(column: $table.trailId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get centerLat =>
      $composableBuilder(column: $table.centerLat, builder: (column) => column);

  GeneratedColumn<double> get centerLon =>
      $composableBuilder(column: $table.centerLon, builder: (column) => column);

  GeneratedColumn<double> get lengthM =>
      $composableBuilder(column: $table.lengthM, builder: (column) => column);

  GeneratedColumn<DateTime> get savedAt =>
      $composableBuilder(column: $table.savedAt, builder: (column) => column);
}

class $$FavoriteTrailsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FavoriteTrailsTable,
    FavoriteTrail,
    $$FavoriteTrailsTableFilterComposer,
    $$FavoriteTrailsTableOrderingComposer,
    $$FavoriteTrailsTableAnnotationComposer,
    $$FavoriteTrailsTableCreateCompanionBuilder,
    $$FavoriteTrailsTableUpdateCompanionBuilder,
    (
      FavoriteTrail,
      BaseReferences<_$AppDatabase, $FavoriteTrailsTable, FavoriteTrail>
    ),
    FavoriteTrail,
    PrefetchHooks Function()> {
  $$FavoriteTrailsTableTableManager(
      _$AppDatabase db, $FavoriteTrailsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoriteTrailsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavoriteTrailsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavoriteTrailsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> trailId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<double> centerLat = const Value.absent(),
            Value<double> centerLon = const Value.absent(),
            Value<double?> lengthM = const Value.absent(),
            Value<DateTime> savedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FavoriteTrailsCompanion(
            trailId: trailId,
            name: name,
            centerLat: centerLat,
            centerLon: centerLon,
            lengthM: lengthM,
            savedAt: savedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String trailId,
            required String name,
            required double centerLat,
            required double centerLon,
            Value<double?> lengthM = const Value.absent(),
            required DateTime savedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              FavoriteTrailsCompanion.insert(
            trailId: trailId,
            name: name,
            centerLat: centerLat,
            centerLon: centerLon,
            lengthM: lengthM,
            savedAt: savedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FavoriteTrailsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FavoriteTrailsTable,
    FavoriteTrail,
    $$FavoriteTrailsTableFilterComposer,
    $$FavoriteTrailsTableOrderingComposer,
    $$FavoriteTrailsTableAnnotationComposer,
    $$FavoriteTrailsTableCreateCompanionBuilder,
    $$FavoriteTrailsTableUpdateCompanionBuilder,
    (
      FavoriteTrail,
      BaseReferences<_$AppDatabase, $FavoriteTrailsTable, FavoriteTrail>
    ),
    FavoriteTrail,
    PrefetchHooks Function()>;
typedef $$UserWaypointsTableCreateCompanionBuilder = UserWaypointsCompanion
    Function({
  required String id,
  required String kind,
  Value<String?> name,
  Value<String?> note,
  required double lat,
  required double lon,
  Value<String?> routeId,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$UserWaypointsTableUpdateCompanionBuilder = UserWaypointsCompanion
    Function({
  Value<String> id,
  Value<String> kind,
  Value<String?> name,
  Value<String?> note,
  Value<double> lat,
  Value<double> lon,
  Value<String?> routeId,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$UserWaypointsTableReferences
    extends BaseReferences<_$AppDatabase, $UserWaypointsTable, UserWaypoint> {
  $$UserWaypointsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $RoutesTable _routeIdTable(_$AppDatabase db) => db.routes.createAlias(
      $_aliasNameGenerator(db.userWaypoints.routeId, db.routes.id));

  $$RoutesTableProcessedTableManager? get routeId {
    final $_column = $_itemColumn<String>('route_id');
    if ($_column == null) return null;
    final manager = $$RoutesTableTableManager($_db, $_db.routes)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_routeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$UserWaypointsTableFilterComposer
    extends Composer<_$AppDatabase, $UserWaypointsTable> {
  $$UserWaypointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get lat => $composableBuilder(
      column: $table.lat, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get lon => $composableBuilder(
      column: $table.lon, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$RoutesTableFilterComposer get routeId {
    final $$RoutesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.routeId,
        referencedTable: $db.routes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RoutesTableFilterComposer(
              $db: $db,
              $table: $db.routes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$UserWaypointsTableOrderingComposer
    extends Composer<_$AppDatabase, $UserWaypointsTable> {
  $$UserWaypointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get lat => $composableBuilder(
      column: $table.lat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get lon => $composableBuilder(
      column: $table.lon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$RoutesTableOrderingComposer get routeId {
    final $$RoutesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.routeId,
        referencedTable: $db.routes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RoutesTableOrderingComposer(
              $db: $db,
              $table: $db.routes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$UserWaypointsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserWaypointsTable> {
  $$UserWaypointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lon =>
      $composableBuilder(column: $table.lon, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$RoutesTableAnnotationComposer get routeId {
    final $$RoutesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.routeId,
        referencedTable: $db.routes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RoutesTableAnnotationComposer(
              $db: $db,
              $table: $db.routes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$UserWaypointsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UserWaypointsTable,
    UserWaypoint,
    $$UserWaypointsTableFilterComposer,
    $$UserWaypointsTableOrderingComposer,
    $$UserWaypointsTableAnnotationComposer,
    $$UserWaypointsTableCreateCompanionBuilder,
    $$UserWaypointsTableUpdateCompanionBuilder,
    (UserWaypoint, $$UserWaypointsTableReferences),
    UserWaypoint,
    PrefetchHooks Function({bool routeId})> {
  $$UserWaypointsTableTableManager(_$AppDatabase db, $UserWaypointsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserWaypointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserWaypointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserWaypointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<String?> name = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<double> lat = const Value.absent(),
            Value<double> lon = const Value.absent(),
            Value<String?> routeId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UserWaypointsCompanion(
            id: id,
            kind: kind,
            name: name,
            note: note,
            lat: lat,
            lon: lon,
            routeId: routeId,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String kind,
            Value<String?> name = const Value.absent(),
            Value<String?> note = const Value.absent(),
            required double lat,
            required double lon,
            Value<String?> routeId = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              UserWaypointsCompanion.insert(
            id: id,
            kind: kind,
            name: name,
            note: note,
            lat: lat,
            lon: lon,
            routeId: routeId,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$UserWaypointsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({routeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (routeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.routeId,
                    referencedTable:
                        $$UserWaypointsTableReferences._routeIdTable(db),
                    referencedColumn:
                        $$UserWaypointsTableReferences._routeIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$UserWaypointsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UserWaypointsTable,
    UserWaypoint,
    $$UserWaypointsTableFilterComposer,
    $$UserWaypointsTableOrderingComposer,
    $$UserWaypointsTableAnnotationComposer,
    $$UserWaypointsTableCreateCompanionBuilder,
    $$UserWaypointsTableUpdateCompanionBuilder,
    (UserWaypoint, $$UserWaypointsTableReferences),
    UserWaypoint,
    PrefetchHooks Function({bool routeId})>;
typedef $$CustomThemesTableCreateCompanionBuilder = CustomThemesCompanion
    Function({
  required String id,
  required String name,
  required bool isDark,
  required int accent,
  required int background,
  required int surface,
  required int raised,
  required int outline,
  required int textPrimary,
  required int textSecondary,
  required int route,
  required int track,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$CustomThemesTableUpdateCompanionBuilder = CustomThemesCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<bool> isDark,
  Value<int> accent,
  Value<int> background,
  Value<int> surface,
  Value<int> raised,
  Value<int> outline,
  Value<int> textPrimary,
  Value<int> textSecondary,
  Value<int> route,
  Value<int> track,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$CustomThemesTableFilterComposer
    extends Composer<_$AppDatabase, $CustomThemesTable> {
  $$CustomThemesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDark => $composableBuilder(
      column: $table.isDark, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get accent => $composableBuilder(
      column: $table.accent, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get background => $composableBuilder(
      column: $table.background, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get surface => $composableBuilder(
      column: $table.surface, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get raised => $composableBuilder(
      column: $table.raised, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get outline => $composableBuilder(
      column: $table.outline, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get textPrimary => $composableBuilder(
      column: $table.textPrimary, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get textSecondary => $composableBuilder(
      column: $table.textSecondary, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get route => $composableBuilder(
      column: $table.route, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get track => $composableBuilder(
      column: $table.track, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$CustomThemesTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomThemesTable> {
  $$CustomThemesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDark => $composableBuilder(
      column: $table.isDark, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get accent => $composableBuilder(
      column: $table.accent, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get background => $composableBuilder(
      column: $table.background, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get surface => $composableBuilder(
      column: $table.surface, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get raised => $composableBuilder(
      column: $table.raised, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get outline => $composableBuilder(
      column: $table.outline, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get textPrimary => $composableBuilder(
      column: $table.textPrimary, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get textSecondary => $composableBuilder(
      column: $table.textSecondary,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get route => $composableBuilder(
      column: $table.route, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get track => $composableBuilder(
      column: $table.track, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$CustomThemesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomThemesTable> {
  $$CustomThemesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get isDark =>
      $composableBuilder(column: $table.isDark, builder: (column) => column);

  GeneratedColumn<int> get accent =>
      $composableBuilder(column: $table.accent, builder: (column) => column);

  GeneratedColumn<int> get background => $composableBuilder(
      column: $table.background, builder: (column) => column);

  GeneratedColumn<int> get surface =>
      $composableBuilder(column: $table.surface, builder: (column) => column);

  GeneratedColumn<int> get raised =>
      $composableBuilder(column: $table.raised, builder: (column) => column);

  GeneratedColumn<int> get outline =>
      $composableBuilder(column: $table.outline, builder: (column) => column);

  GeneratedColumn<int> get textPrimary => $composableBuilder(
      column: $table.textPrimary, builder: (column) => column);

  GeneratedColumn<int> get textSecondary => $composableBuilder(
      column: $table.textSecondary, builder: (column) => column);

  GeneratedColumn<int> get route =>
      $composableBuilder(column: $table.route, builder: (column) => column);

  GeneratedColumn<int> get track =>
      $composableBuilder(column: $table.track, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$CustomThemesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CustomThemesTable,
    CustomTheme,
    $$CustomThemesTableFilterComposer,
    $$CustomThemesTableOrderingComposer,
    $$CustomThemesTableAnnotationComposer,
    $$CustomThemesTableCreateCompanionBuilder,
    $$CustomThemesTableUpdateCompanionBuilder,
    (
      CustomTheme,
      BaseReferences<_$AppDatabase, $CustomThemesTable, CustomTheme>
    ),
    CustomTheme,
    PrefetchHooks Function()> {
  $$CustomThemesTableTableManager(_$AppDatabase db, $CustomThemesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomThemesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomThemesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomThemesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<bool> isDark = const Value.absent(),
            Value<int> accent = const Value.absent(),
            Value<int> background = const Value.absent(),
            Value<int> surface = const Value.absent(),
            Value<int> raised = const Value.absent(),
            Value<int> outline = const Value.absent(),
            Value<int> textPrimary = const Value.absent(),
            Value<int> textSecondary = const Value.absent(),
            Value<int> route = const Value.absent(),
            Value<int> track = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CustomThemesCompanion(
            id: id,
            name: name,
            isDark: isDark,
            accent: accent,
            background: background,
            surface: surface,
            raised: raised,
            outline: outline,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            route: route,
            track: track,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required bool isDark,
            required int accent,
            required int background,
            required int surface,
            required int raised,
            required int outline,
            required int textPrimary,
            required int textSecondary,
            required int route,
            required int track,
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              CustomThemesCompanion.insert(
            id: id,
            name: name,
            isDark: isDark,
            accent: accent,
            background: background,
            surface: surface,
            raised: raised,
            outline: outline,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            route: route,
            track: track,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CustomThemesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CustomThemesTable,
    CustomTheme,
    $$CustomThemesTableFilterComposer,
    $$CustomThemesTableOrderingComposer,
    $$CustomThemesTableAnnotationComposer,
    $$CustomThemesTableCreateCompanionBuilder,
    $$CustomThemesTableUpdateCompanionBuilder,
    (
      CustomTheme,
      BaseReferences<_$AppDatabase, $CustomThemesTable, CustomTheme>
    ),
    CustomTheme,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$OsmWaysTableTableManager get osmWays =>
      $$OsmWaysTableTableManager(_db, _db.osmWays);
  $$OsmNodesTableTableManager get osmNodes =>
      $$OsmNodesTableTableManager(_db, _db.osmNodes);
  $$OsmRelationsTableTableManager get osmRelations =>
      $$OsmRelationsTableTableManager(_db, _db.osmRelations);
  $$PoisTableTableManager get pois => $$PoisTableTableManager(_db, _db.pois);
  $$CacheCellsTableTableManager get cacheCells =>
      $$CacheCellsTableTableManager(_db, _db.cacheCells);
  $$UsfsRoadsTableTableManager get usfsRoads =>
      $$UsfsRoadsTableTableManager(_db, _db.usfsRoads);
  $$RoutesTableTableManager get routes =>
      $$RoutesTableTableManager(_db, _db.routes);
  $$RouteWaypointsTableTableManager get routeWaypoints =>
      $$RouteWaypointsTableTableManager(_db, _db.routeWaypoints);
  $$TracksTableTableManager get tracks =>
      $$TracksTableTableManager(_db, _db.tracks);
  $$TrackPointsTableTableManager get trackPoints =>
      $$TrackPointsTableTableManager(_db, _db.trackPoints);
  $$OfflineRegionsTableTableManager get offlineRegions =>
      $$OfflineRegionsTableTableManager(_db, _db.offlineRegions);
  $$ConditionsCacheTableTableManager get conditionsCache =>
      $$ConditionsCacheTableTableManager(_db, _db.conditionsCache);
  $$TombstonesTableTableManager get tombstones =>
      $$TombstonesTableTableManager(_db, _db.tombstones);
  $$FavoriteTrailsTableTableManager get favoriteTrails =>
      $$FavoriteTrailsTableTableManager(_db, _db.favoriteTrails);
  $$UserWaypointsTableTableManager get userWaypoints =>
      $$UserWaypointsTableTableManager(_db, _db.userWaypoints);
  $$CustomThemesTableTableManager get customThemes =>
      $$CustomThemesTableTableManager(_db, _db.customThemes);
}
