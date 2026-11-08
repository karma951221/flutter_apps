// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_database.dart';

// ignore_for_file: type=lint
class $LocationPointsTable extends LocationPoints
    with TableInfo<$LocationPointsTable, LocationPointRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocationPointsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
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
  static const VerificationMeta _accuracyMMeta = const VerificationMeta(
    'accuracyM',
  );
  @override
  late final GeneratedColumn<double> accuracyM = GeneratedColumn<double>(
    'accuracy_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<RecordMode, String> mode =
      GeneratedColumn<String>(
        'mode',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<RecordMode>($LocationPointsTable.$convertermode);
  static const VerificationMeta _stillStartMeta = const VerificationMeta(
    'stillStart',
  );
  @override
  late final GeneratedColumn<bool> stillStart = GeneratedColumn<bool>(
    'still_start',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("still_start" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    recordedAt,
    lat,
    lng,
    accuracyM,
    mode,
    stillStart,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'location_points';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocationPointRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
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
    if (data.containsKey('accuracy_m')) {
      context.handle(
        _accuracyMMeta,
        accuracyM.isAcceptableOrUnknown(data['accuracy_m']!, _accuracyMMeta),
      );
    }
    if (data.containsKey('still_start')) {
      context.handle(
        _stillStartMeta,
        stillStart.isAcceptableOrUnknown(data['still_start']!, _stillStartMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {recordedAt, lat, lng},
  ];
  @override
  LocationPointRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocationPointRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lng'],
      )!,
      accuracyM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}accuracy_m'],
      ),
      mode: $LocationPointsTable.$convertermode.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}mode'],
        )!,
      ),
      stillStart: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}still_start'],
      )!,
    );
  }

  @override
  $LocationPointsTable createAlias(String alias) {
    return $LocationPointsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<RecordMode, String, String> $convertermode =
      const EnumNameConverter<RecordMode>(RecordMode.values);
}

class LocationPointRow extends DataClass
    implements Insertable<LocationPointRow> {
  final int id;
  final DateTime recordedAt;
  final double lat;
  final double lng;
  final double? accuracyM;
  final RecordMode mode;
  final bool stillStart;
  const LocationPointRow({
    required this.id,
    required this.recordedAt,
    required this.lat,
    required this.lng,
    this.accuracyM,
    required this.mode,
    required this.stillStart,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['lat'] = Variable<double>(lat);
    map['lng'] = Variable<double>(lng);
    if (!nullToAbsent || accuracyM != null) {
      map['accuracy_m'] = Variable<double>(accuracyM);
    }
    {
      map['mode'] = Variable<String>(
        $LocationPointsTable.$convertermode.toSql(mode),
      );
    }
    map['still_start'] = Variable<bool>(stillStart);
    return map;
  }

  LocationPointsCompanion toCompanion(bool nullToAbsent) {
    return LocationPointsCompanion(
      id: Value(id),
      recordedAt: Value(recordedAt),
      lat: Value(lat),
      lng: Value(lng),
      accuracyM: accuracyM == null && nullToAbsent
          ? const Value.absent()
          : Value(accuracyM),
      mode: Value(mode),
      stillStart: Value(stillStart),
    );
  }

  factory LocationPointRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocationPointRow(
      id: serializer.fromJson<int>(json['id']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      lat: serializer.fromJson<double>(json['lat']),
      lng: serializer.fromJson<double>(json['lng']),
      accuracyM: serializer.fromJson<double?>(json['accuracyM']),
      mode: $LocationPointsTable.$convertermode.fromJson(
        serializer.fromJson<String>(json['mode']),
      ),
      stillStart: serializer.fromJson<bool>(json['stillStart']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'lat': serializer.toJson<double>(lat),
      'lng': serializer.toJson<double>(lng),
      'accuracyM': serializer.toJson<double?>(accuracyM),
      'mode': serializer.toJson<String>(
        $LocationPointsTable.$convertermode.toJson(mode),
      ),
      'stillStart': serializer.toJson<bool>(stillStart),
    };
  }

  LocationPointRow copyWith({
    int? id,
    DateTime? recordedAt,
    double? lat,
    double? lng,
    Value<double?> accuracyM = const Value.absent(),
    RecordMode? mode,
    bool? stillStart,
  }) => LocationPointRow(
    id: id ?? this.id,
    recordedAt: recordedAt ?? this.recordedAt,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    accuracyM: accuracyM.present ? accuracyM.value : this.accuracyM,
    mode: mode ?? this.mode,
    stillStart: stillStart ?? this.stillStart,
  );
  LocationPointRow copyWithCompanion(LocationPointsCompanion data) {
    return LocationPointRow(
      id: data.id.present ? data.id.value : this.id,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      lat: data.lat.present ? data.lat.value : this.lat,
      lng: data.lng.present ? data.lng.value : this.lng,
      accuracyM: data.accuracyM.present ? data.accuracyM.value : this.accuracyM,
      mode: data.mode.present ? data.mode.value : this.mode,
      stillStart: data.stillStart.present
          ? data.stillStart.value
          : this.stillStart,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocationPointRow(')
          ..write('id: $id, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('accuracyM: $accuracyM, ')
          ..write('mode: $mode, ')
          ..write('stillStart: $stillStart')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, recordedAt, lat, lng, accuracyM, mode, stillStart);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocationPointRow &&
          other.id == this.id &&
          other.recordedAt == this.recordedAt &&
          other.lat == this.lat &&
          other.lng == this.lng &&
          other.accuracyM == this.accuracyM &&
          other.mode == this.mode &&
          other.stillStart == this.stillStart);
}

class LocationPointsCompanion extends UpdateCompanion<LocationPointRow> {
  final Value<int> id;
  final Value<DateTime> recordedAt;
  final Value<double> lat;
  final Value<double> lng;
  final Value<double?> accuracyM;
  final Value<RecordMode> mode;
  final Value<bool> stillStart;
  const LocationPointsCompanion({
    this.id = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.accuracyM = const Value.absent(),
    this.mode = const Value.absent(),
    this.stillStart = const Value.absent(),
  });
  LocationPointsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime recordedAt,
    required double lat,
    required double lng,
    this.accuracyM = const Value.absent(),
    required RecordMode mode,
    this.stillStart = const Value.absent(),
  }) : recordedAt = Value(recordedAt),
       lat = Value(lat),
       lng = Value(lng),
       mode = Value(mode);
  static Insertable<LocationPointRow> custom({
    Expression<int>? id,
    Expression<DateTime>? recordedAt,
    Expression<double>? lat,
    Expression<double>? lng,
    Expression<double>? accuracyM,
    Expression<String>? mode,
    Expression<bool>? stillStart,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (accuracyM != null) 'accuracy_m': accuracyM,
      if (mode != null) 'mode': mode,
      if (stillStart != null) 'still_start': stillStart,
    });
  }

  LocationPointsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? recordedAt,
    Value<double>? lat,
    Value<double>? lng,
    Value<double?>? accuracyM,
    Value<RecordMode>? mode,
    Value<bool>? stillStart,
  }) {
    return LocationPointsCompanion(
      id: id ?? this.id,
      recordedAt: recordedAt ?? this.recordedAt,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      accuracyM: accuracyM ?? this.accuracyM,
      mode: mode ?? this.mode,
      stillStart: stillStart ?? this.stillStart,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lng.present) {
      map['lng'] = Variable<double>(lng.value);
    }
    if (accuracyM.present) {
      map['accuracy_m'] = Variable<double>(accuracyM.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(
        $LocationPointsTable.$convertermode.toSql(mode.value),
      );
    }
    if (stillStart.present) {
      map['still_start'] = Variable<bool>(stillStart.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocationPointsCompanion(')
          ..write('id: $id, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('accuracyM: $accuracyM, ')
          ..write('mode: $mode, ')
          ..write('stillStart: $stillStart')
          ..write(')'))
        .toString();
  }
}

class $PlaceNamesTable extends PlaceNames
    with TableInfo<$PlaceNamesTable, PlaceNameRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaceNamesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _gridKeyMeta = const VerificationMeta(
    'gridKey',
  );
  @override
  late final GeneratedColumn<String> gridKey = GeneratedColumn<String>(
    'grid_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [gridKey, name, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'place_names';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaceNameRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('grid_key')) {
      context.handle(
        _gridKeyMeta,
        gridKey.isAcceptableOrUnknown(data['grid_key']!, _gridKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_gridKeyMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {gridKey};
  @override
  PlaceNameRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaceNameRow(
      gridKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grid_key'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PlaceNamesTable createAlias(String alias) {
    return $PlaceNamesTable(attachedDatabase, alias);
  }
}

class PlaceNameRow extends DataClass implements Insertable<PlaceNameRow> {
  final String gridKey;
  final String name;
  final DateTime updatedAt;
  const PlaceNameRow({
    required this.gridKey,
    required this.name,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['grid_key'] = Variable<String>(gridKey);
    map['name'] = Variable<String>(name);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PlaceNamesCompanion toCompanion(bool nullToAbsent) {
    return PlaceNamesCompanion(
      gridKey: Value(gridKey),
      name: Value(name),
      updatedAt: Value(updatedAt),
    );
  }

  factory PlaceNameRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaceNameRow(
      gridKey: serializer.fromJson<String>(json['gridKey']),
      name: serializer.fromJson<String>(json['name']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'gridKey': serializer.toJson<String>(gridKey),
      'name': serializer.toJson<String>(name),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PlaceNameRow copyWith({String? gridKey, String? name, DateTime? updatedAt}) =>
      PlaceNameRow(
        gridKey: gridKey ?? this.gridKey,
        name: name ?? this.name,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  PlaceNameRow copyWithCompanion(PlaceNamesCompanion data) {
    return PlaceNameRow(
      gridKey: data.gridKey.present ? data.gridKey.value : this.gridKey,
      name: data.name.present ? data.name.value : this.name,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaceNameRow(')
          ..write('gridKey: $gridKey, ')
          ..write('name: $name, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(gridKey, name, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaceNameRow &&
          other.gridKey == this.gridKey &&
          other.name == this.name &&
          other.updatedAt == this.updatedAt);
}

class PlaceNamesCompanion extends UpdateCompanion<PlaceNameRow> {
  final Value<String> gridKey;
  final Value<String> name;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PlaceNamesCompanion({
    this.gridKey = const Value.absent(),
    this.name = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlaceNamesCompanion.insert({
    required String gridKey,
    required String name,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : gridKey = Value(gridKey),
       name = Value(name),
       updatedAt = Value(updatedAt);
  static Insertable<PlaceNameRow> custom({
    Expression<String>? gridKey,
    Expression<String>? name,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (gridKey != null) 'grid_key': gridKey,
      if (name != null) 'name': name,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlaceNamesCompanion copyWith({
    Value<String>? gridKey,
    Value<String>? name,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return PlaceNamesCompanion(
      gridKey: gridKey ?? this.gridKey,
      name: name ?? this.name,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (gridKey.present) {
      map['grid_key'] = Variable<String>(gridKey.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
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
    return (StringBuffer('PlaceNamesCompanion(')
          ..write('gridKey: $gridKey, ')
          ..write('name: $name, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$LocationDatabase extends GeneratedDatabase {
  _$LocationDatabase(QueryExecutor e) : super(e);
  $LocationDatabaseManager get managers => $LocationDatabaseManager(this);
  late final $LocationPointsTable locationPoints = $LocationPointsTable(this);
  late final $PlaceNamesTable placeNames = $PlaceNamesTable(this);
  late final Index locationPointsRecordedAt = Index(
    'location_points_recorded_at',
    'CREATE INDEX location_points_recorded_at ON location_points (recorded_at)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    locationPoints,
    placeNames,
    locationPointsRecordedAt,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$LocationPointsTableCreateCompanionBuilder =
    LocationPointsCompanion Function({
      Value<int> id,
      required DateTime recordedAt,
      required double lat,
      required double lng,
      Value<double?> accuracyM,
      required RecordMode mode,
      Value<bool> stillStart,
    });
typedef $$LocationPointsTableUpdateCompanionBuilder =
    LocationPointsCompanion Function({
      Value<int> id,
      Value<DateTime> recordedAt,
      Value<double> lat,
      Value<double> lng,
      Value<double?> accuracyM,
      Value<RecordMode> mode,
      Value<bool> stillStart,
    });

class $$LocationPointsTableFilterComposer
    extends Composer<_$LocationDatabase, $LocationPointsTable> {
  $$LocationPointsTableFilterComposer({
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

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
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

  ColumnFilters<double> get accuracyM => $composableBuilder(
    column: $table.accuracyM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<RecordMode, RecordMode, String> get mode =>
      $composableBuilder(
        column: $table.mode,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get stillStart => $composableBuilder(
    column: $table.stillStart,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocationPointsTableOrderingComposer
    extends Composer<_$LocationDatabase, $LocationPointsTable> {
  $$LocationPointsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
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

  ColumnOrderings<double> get accuracyM => $composableBuilder(
    column: $table.accuracyM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get stillStart => $composableBuilder(
    column: $table.stillStart,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocationPointsTableAnnotationComposer
    extends Composer<_$LocationDatabase, $LocationPointsTable> {
  $$LocationPointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lng =>
      $composableBuilder(column: $table.lng, builder: (column) => column);

  GeneratedColumn<double> get accuracyM =>
      $composableBuilder(column: $table.accuracyM, builder: (column) => column);

  GeneratedColumnWithTypeConverter<RecordMode, String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<bool> get stillStart => $composableBuilder(
    column: $table.stillStart,
    builder: (column) => column,
  );
}

class $$LocationPointsTableTableManager
    extends
        RootTableManager<
          _$LocationDatabase,
          $LocationPointsTable,
          LocationPointRow,
          $$LocationPointsTableFilterComposer,
          $$LocationPointsTableOrderingComposer,
          $$LocationPointsTableAnnotationComposer,
          $$LocationPointsTableCreateCompanionBuilder,
          $$LocationPointsTableUpdateCompanionBuilder,
          (
            LocationPointRow,
            BaseReferences<
              _$LocationDatabase,
              $LocationPointsTable,
              LocationPointRow
            >,
          ),
          LocationPointRow,
          PrefetchHooks Function()
        > {
  $$LocationPointsTableTableManager(
    _$LocationDatabase db,
    $LocationPointsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocationPointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocationPointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocationPointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<double> lat = const Value.absent(),
                Value<double> lng = const Value.absent(),
                Value<double?> accuracyM = const Value.absent(),
                Value<RecordMode> mode = const Value.absent(),
                Value<bool> stillStart = const Value.absent(),
              }) => LocationPointsCompanion(
                id: id,
                recordedAt: recordedAt,
                lat: lat,
                lng: lng,
                accuracyM: accuracyM,
                mode: mode,
                stillStart: stillStart,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime recordedAt,
                required double lat,
                required double lng,
                Value<double?> accuracyM = const Value.absent(),
                required RecordMode mode,
                Value<bool> stillStart = const Value.absent(),
              }) => LocationPointsCompanion.insert(
                id: id,
                recordedAt: recordedAt,
                lat: lat,
                lng: lng,
                accuracyM: accuracyM,
                mode: mode,
                stillStart: stillStart,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocationPointsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocationDatabase,
      $LocationPointsTable,
      LocationPointRow,
      $$LocationPointsTableFilterComposer,
      $$LocationPointsTableOrderingComposer,
      $$LocationPointsTableAnnotationComposer,
      $$LocationPointsTableCreateCompanionBuilder,
      $$LocationPointsTableUpdateCompanionBuilder,
      (
        LocationPointRow,
        BaseReferences<
          _$LocationDatabase,
          $LocationPointsTable,
          LocationPointRow
        >,
      ),
      LocationPointRow,
      PrefetchHooks Function()
    >;
typedef $$PlaceNamesTableCreateCompanionBuilder =
    PlaceNamesCompanion Function({
      required String gridKey,
      required String name,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$PlaceNamesTableUpdateCompanionBuilder =
    PlaceNamesCompanion Function({
      Value<String> gridKey,
      Value<String> name,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$PlaceNamesTableFilterComposer
    extends Composer<_$LocationDatabase, $PlaceNamesTable> {
  $$PlaceNamesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get gridKey => $composableBuilder(
    column: $table.gridKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlaceNamesTableOrderingComposer
    extends Composer<_$LocationDatabase, $PlaceNamesTable> {
  $$PlaceNamesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get gridKey => $composableBuilder(
    column: $table.gridKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlaceNamesTableAnnotationComposer
    extends Composer<_$LocationDatabase, $PlaceNamesTable> {
  $$PlaceNamesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get gridKey =>
      $composableBuilder(column: $table.gridKey, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PlaceNamesTableTableManager
    extends
        RootTableManager<
          _$LocationDatabase,
          $PlaceNamesTable,
          PlaceNameRow,
          $$PlaceNamesTableFilterComposer,
          $$PlaceNamesTableOrderingComposer,
          $$PlaceNamesTableAnnotationComposer,
          $$PlaceNamesTableCreateCompanionBuilder,
          $$PlaceNamesTableUpdateCompanionBuilder,
          (
            PlaceNameRow,
            BaseReferences<_$LocationDatabase, $PlaceNamesTable, PlaceNameRow>,
          ),
          PlaceNameRow,
          PrefetchHooks Function()
        > {
  $$PlaceNamesTableTableManager(_$LocationDatabase db, $PlaceNamesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaceNamesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaceNamesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaceNamesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> gridKey = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaceNamesCompanion(
                gridKey: gridKey,
                name: name,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String gridKey,
                required String name,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => PlaceNamesCompanion.insert(
                gridKey: gridKey,
                name: name,
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

typedef $$PlaceNamesTableProcessedTableManager =
    ProcessedTableManager<
      _$LocationDatabase,
      $PlaceNamesTable,
      PlaceNameRow,
      $$PlaceNamesTableFilterComposer,
      $$PlaceNamesTableOrderingComposer,
      $$PlaceNamesTableAnnotationComposer,
      $$PlaceNamesTableCreateCompanionBuilder,
      $$PlaceNamesTableUpdateCompanionBuilder,
      (
        PlaceNameRow,
        BaseReferences<_$LocationDatabase, $PlaceNamesTable, PlaceNameRow>,
      ),
      PlaceNameRow,
      PrefetchHooks Function()
    >;

class $LocationDatabaseManager {
  final _$LocationDatabase _db;
  $LocationDatabaseManager(this._db);
  $$LocationPointsTableTableManager get locationPoints =>
      $$LocationPointsTableTableManager(_db, _db.locationPoints);
  $$PlaceNamesTableTableManager get placeNames =>
      $$PlaceNamesTableTableManager(_db, _db.placeNames);
}
