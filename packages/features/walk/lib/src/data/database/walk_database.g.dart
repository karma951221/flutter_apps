// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'walk_database.dart';

// ignore_for_file: type=lint
class $DogsTable extends Dogs with TableInfo<$DogsTable, DogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
  static const VerificationMeta _breedMeta = const VerificationMeta('breed');
  @override
  late final GeneratedColumn<String> breed = GeneratedColumn<String>(
    'breed',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _birthdayMeta = const VerificationMeta(
    'birthday',
  );
  @override
  late final GeneratedColumn<String> birthday = GeneratedColumn<String>(
    'birthday',
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
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
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
  List<GeneratedColumn> get $columns => [
    id,
    name,
    breed,
    birthday,
    photoPath,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dogs';
  @override
  VerificationContext validateIntegrity(
    Insertable<DogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('breed')) {
      context.handle(
        _breedMeta,
        breed.isAcceptableOrUnknown(data['breed']!, _breedMeta),
      );
    }
    if (data.containsKey('birthday')) {
      context.handle(
        _birthdayMeta,
        birthday.isAcceptableOrUnknown(data['birthday']!, _birthdayMeta),
      );
    }
    if (data.containsKey('photo_path')) {
      context.handle(
        _photoPathMeta,
        photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DogRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      breed: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}breed'],
      ),
      birthday: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}birthday'],
      ),
      photoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_path'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DogsTable createAlias(String alias) {
    return $DogsTable(attachedDatabase, alias);
  }
}

class DogRow extends DataClass implements Insertable<DogRow> {
  final String id;
  final String name;
  final String? breed;

  /// 날짜만 담는 `yyyy-MM-dd`. 시각 컬럼처럼 ISO 전체를 쓰면 시간대에 따라 하루가 밀린다.
  final String? birthday;
  final String? photoPath;
  final DateTime createdAt;
  final DateTime updatedAt;
  const DogRow({
    required this.id,
    required this.name,
    this.breed,
    this.birthday,
    this.photoPath,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || breed != null) {
      map['breed'] = Variable<String>(breed);
    }
    if (!nullToAbsent || birthday != null) {
      map['birthday'] = Variable<String>(birthday);
    }
    if (!nullToAbsent || photoPath != null) {
      map['photo_path'] = Variable<String>(photoPath);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DogsCompanion toCompanion(bool nullToAbsent) {
    return DogsCompanion(
      id: Value(id),
      name: Value(name),
      breed: breed == null && nullToAbsent
          ? const Value.absent()
          : Value(breed),
      birthday: birthday == null && nullToAbsent
          ? const Value.absent()
          : Value(birthday),
      photoPath: photoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoPath),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DogRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      breed: serializer.fromJson<String?>(json['breed']),
      birthday: serializer.fromJson<String?>(json['birthday']),
      photoPath: serializer.fromJson<String?>(json['photoPath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'breed': serializer.toJson<String?>(breed),
      'birthday': serializer.toJson<String?>(birthday),
      'photoPath': serializer.toJson<String?>(photoPath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DogRow copyWith({
    String? id,
    String? name,
    Value<String?> breed = const Value.absent(),
    Value<String?> birthday = const Value.absent(),
    Value<String?> photoPath = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => DogRow(
    id: id ?? this.id,
    name: name ?? this.name,
    breed: breed.present ? breed.value : this.breed,
    birthday: birthday.present ? birthday.value : this.birthday,
    photoPath: photoPath.present ? photoPath.value : this.photoPath,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DogRow copyWithCompanion(DogsCompanion data) {
    return DogRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      breed: data.breed.present ? data.breed.value : this.breed,
      birthday: data.birthday.present ? data.birthday.value : this.birthday,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DogRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('breed: $breed, ')
          ..write('birthday: $birthday, ')
          ..write('photoPath: $photoPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, breed, birthday, photoPath, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DogRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.breed == this.breed &&
          other.birthday == this.birthday &&
          other.photoPath == this.photoPath &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DogsCompanion extends UpdateCompanion<DogRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> breed;
  final Value<String?> birthday;
  final Value<String?> photoPath;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DogsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.breed = const Value.absent(),
    this.birthday = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DogsCompanion.insert({
    required String id,
    required String name,
    this.breed = const Value.absent(),
    this.birthday = const Value.absent(),
    this.photoPath = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<DogRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? breed,
    Expression<String>? birthday,
    Expression<String>? photoPath,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (breed != null) 'breed': breed,
      if (birthday != null) 'birthday': birthday,
      if (photoPath != null) 'photo_path': photoPath,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DogsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? breed,
    Value<String?>? birthday,
    Value<String?>? photoPath,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return DogsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      breed: breed ?? this.breed,
      birthday: birthday ?? this.birthday,
      photoPath: photoPath ?? this.photoPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (breed.present) {
      map['breed'] = Variable<String>(breed.value);
    }
    if (birthday.present) {
      map['birthday'] = Variable<String>(birthday.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
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
    return (StringBuffer('DogsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('breed: $breed, ')
          ..write('birthday: $birthday, ')
          ..write('photoPath: $photoPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WalksTable extends Walks with TableInfo<$WalksTable, WalkRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WalksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _distanceMetersMeta = const VerificationMeta(
    'distanceMeters',
  );
  @override
  late final GeneratedColumn<double> distanceMeters = GeneratedColumn<double>(
    'distance_meters',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  @override
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
    'memo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _routePreviewMeta = const VerificationMeta(
    'routePreview',
  );
  @override
  late final GeneratedColumn<String> routePreview = GeneratedColumn<String>(
    'route_preview',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  List<GeneratedColumn> get $columns => [
    id,
    startedAt,
    endedAt,
    durationSeconds,
    distanceMeters,
    memo,
    routePreview,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'walks';
  @override
  VerificationContext validateIntegrity(
    Insertable<WalkRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
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
    } else if (isInserting) {
      context.missing(_endedAtMeta);
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationSecondsMeta);
    }
    if (data.containsKey('distance_meters')) {
      context.handle(
        _distanceMetersMeta,
        distanceMeters.isAcceptableOrUnknown(
          data['distance_meters']!,
          _distanceMetersMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_distanceMetersMeta);
    }
    if (data.containsKey('memo')) {
      context.handle(
        _memoMeta,
        memo.isAcceptableOrUnknown(data['memo']!, _memoMeta),
      );
    }
    if (data.containsKey('route_preview')) {
      context.handle(
        _routePreviewMeta,
        routePreview.isAcceptableOrUnknown(
          data['route_preview']!,
          _routePreviewMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WalkRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WalkRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      )!,
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      )!,
      distanceMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance_meters'],
      )!,
      memo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memo'],
      ),
      routePreview: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}route_preview'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $WalksTable createAlias(String alias) {
    return $WalksTable(attachedDatabase, alias);
  }
}

class WalkRow extends DataClass implements Insertable<WalkRow> {
  final String id;
  final DateTime startedAt;
  final DateTime endedAt;
  final int durationSeconds;
  final double distanceMeters;
  final String? memo;
  final String? routePreview;
  final DateTime createdAt;
  final DateTime updatedAt;
  const WalkRow({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.durationSeconds,
    required this.distanceMeters,
    this.memo,
    this.routePreview,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['started_at'] = Variable<DateTime>(startedAt);
    map['ended_at'] = Variable<DateTime>(endedAt);
    map['duration_seconds'] = Variable<int>(durationSeconds);
    map['distance_meters'] = Variable<double>(distanceMeters);
    if (!nullToAbsent || memo != null) {
      map['memo'] = Variable<String>(memo);
    }
    if (!nullToAbsent || routePreview != null) {
      map['route_preview'] = Variable<String>(routePreview);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  WalksCompanion toCompanion(bool nullToAbsent) {
    return WalksCompanion(
      id: Value(id),
      startedAt: Value(startedAt),
      endedAt: Value(endedAt),
      durationSeconds: Value(durationSeconds),
      distanceMeters: Value(distanceMeters),
      memo: memo == null && nullToAbsent ? const Value.absent() : Value(memo),
      routePreview: routePreview == null && nullToAbsent
          ? const Value.absent()
          : Value(routePreview),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory WalkRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WalkRow(
      id: serializer.fromJson<String>(json['id']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime>(json['endedAt']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      distanceMeters: serializer.fromJson<double>(json['distanceMeters']),
      memo: serializer.fromJson<String?>(json['memo']),
      routePreview: serializer.fromJson<String?>(json['routePreview']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime>(endedAt),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'distanceMeters': serializer.toJson<double>(distanceMeters),
      'memo': serializer.toJson<String?>(memo),
      'routePreview': serializer.toJson<String?>(routePreview),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  WalkRow copyWith({
    String? id,
    DateTime? startedAt,
    DateTime? endedAt,
    int? durationSeconds,
    double? distanceMeters,
    Value<String?> memo = const Value.absent(),
    Value<String?> routePreview = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => WalkRow(
    id: id ?? this.id,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt ?? this.endedAt,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    distanceMeters: distanceMeters ?? this.distanceMeters,
    memo: memo.present ? memo.value : this.memo,
    routePreview: routePreview.present ? routePreview.value : this.routePreview,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  WalkRow copyWithCompanion(WalksCompanion data) {
    return WalkRow(
      id: data.id.present ? data.id.value : this.id,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      distanceMeters: data.distanceMeters.present
          ? data.distanceMeters.value
          : this.distanceMeters,
      memo: data.memo.present ? data.memo.value : this.memo,
      routePreview: data.routePreview.present
          ? data.routePreview.value
          : this.routePreview,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WalkRow(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('memo: $memo, ')
          ..write('routePreview: $routePreview, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    startedAt,
    endedAt,
    durationSeconds,
    distanceMeters,
    memo,
    routePreview,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WalkRow &&
          other.id == this.id &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.durationSeconds == this.durationSeconds &&
          other.distanceMeters == this.distanceMeters &&
          other.memo == this.memo &&
          other.routePreview == this.routePreview &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class WalksCompanion extends UpdateCompanion<WalkRow> {
  final Value<String> id;
  final Value<DateTime> startedAt;
  final Value<DateTime> endedAt;
  final Value<int> durationSeconds;
  final Value<double> distanceMeters;
  final Value<String?> memo;
  final Value<String?> routePreview;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const WalksCompanion({
    this.id = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.distanceMeters = const Value.absent(),
    this.memo = const Value.absent(),
    this.routePreview = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WalksCompanion.insert({
    required String id,
    required DateTime startedAt,
    required DateTime endedAt,
    required int durationSeconds,
    required double distanceMeters,
    this.memo = const Value.absent(),
    this.routePreview = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       startedAt = Value(startedAt),
       endedAt = Value(endedAt),
       durationSeconds = Value(durationSeconds),
       distanceMeters = Value(distanceMeters),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<WalkRow> custom({
    Expression<String>? id,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<int>? durationSeconds,
    Expression<double>? distanceMeters,
    Expression<String>? memo,
    Expression<String>? routePreview,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (distanceMeters != null) 'distance_meters': distanceMeters,
      if (memo != null) 'memo': memo,
      if (routePreview != null) 'route_preview': routePreview,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WalksCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? startedAt,
    Value<DateTime>? endedAt,
    Value<int>? durationSeconds,
    Value<double>? distanceMeters,
    Value<String?>? memo,
    Value<String?>? routePreview,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return WalksCompanion(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      memo: memo ?? this.memo,
      routePreview: routePreview ?? this.routePreview,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (distanceMeters.present) {
      map['distance_meters'] = Variable<double>(distanceMeters.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (routePreview.present) {
      map['route_preview'] = Variable<String>(routePreview.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
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
    return (StringBuffer('WalksCompanion(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('memo: $memo, ')
          ..write('routePreview: $routePreview, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WalkDogsTable extends WalkDogs
    with TableInfo<$WalkDogsTable, WalkDogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WalkDogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _walkIdMeta = const VerificationMeta('walkId');
  @override
  late final GeneratedColumn<String> walkId = GeneratedColumn<String>(
    'walk_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES walks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _dogIdMeta = const VerificationMeta('dogId');
  @override
  late final GeneratedColumn<String> dogId = GeneratedColumn<String>(
    'dog_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES dogs (id) ON DELETE CASCADE',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [walkId, dogId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'walk_dogs';
  @override
  VerificationContext validateIntegrity(
    Insertable<WalkDogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('walk_id')) {
      context.handle(
        _walkIdMeta,
        walkId.isAcceptableOrUnknown(data['walk_id']!, _walkIdMeta),
      );
    } else if (isInserting) {
      context.missing(_walkIdMeta);
    }
    if (data.containsKey('dog_id')) {
      context.handle(
        _dogIdMeta,
        dogId.isAcceptableOrUnknown(data['dog_id']!, _dogIdMeta),
      );
    } else if (isInserting) {
      context.missing(_dogIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {walkId, dogId};
  @override
  WalkDogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WalkDogRow(
      walkId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}walk_id'],
      )!,
      dogId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dog_id'],
      )!,
    );
  }

  @override
  $WalkDogsTable createAlias(String alias) {
    return $WalkDogsTable(attachedDatabase, alias);
  }
}

class WalkDogRow extends DataClass implements Insertable<WalkDogRow> {
  final String walkId;
  final String dogId;
  const WalkDogRow({required this.walkId, required this.dogId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['walk_id'] = Variable<String>(walkId);
    map['dog_id'] = Variable<String>(dogId);
    return map;
  }

  WalkDogsCompanion toCompanion(bool nullToAbsent) {
    return WalkDogsCompanion(walkId: Value(walkId), dogId: Value(dogId));
  }

  factory WalkDogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WalkDogRow(
      walkId: serializer.fromJson<String>(json['walkId']),
      dogId: serializer.fromJson<String>(json['dogId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'walkId': serializer.toJson<String>(walkId),
      'dogId': serializer.toJson<String>(dogId),
    };
  }

  WalkDogRow copyWith({String? walkId, String? dogId}) =>
      WalkDogRow(walkId: walkId ?? this.walkId, dogId: dogId ?? this.dogId);
  WalkDogRow copyWithCompanion(WalkDogsCompanion data) {
    return WalkDogRow(
      walkId: data.walkId.present ? data.walkId.value : this.walkId,
      dogId: data.dogId.present ? data.dogId.value : this.dogId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WalkDogRow(')
          ..write('walkId: $walkId, ')
          ..write('dogId: $dogId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(walkId, dogId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WalkDogRow &&
          other.walkId == this.walkId &&
          other.dogId == this.dogId);
}

class WalkDogsCompanion extends UpdateCompanion<WalkDogRow> {
  final Value<String> walkId;
  final Value<String> dogId;
  final Value<int> rowid;
  const WalkDogsCompanion({
    this.walkId = const Value.absent(),
    this.dogId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WalkDogsCompanion.insert({
    required String walkId,
    required String dogId,
    this.rowid = const Value.absent(),
  }) : walkId = Value(walkId),
       dogId = Value(dogId);
  static Insertable<WalkDogRow> custom({
    Expression<String>? walkId,
    Expression<String>? dogId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (walkId != null) 'walk_id': walkId,
      if (dogId != null) 'dog_id': dogId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WalkDogsCompanion copyWith({
    Value<String>? walkId,
    Value<String>? dogId,
    Value<int>? rowid,
  }) {
    return WalkDogsCompanion(
      walkId: walkId ?? this.walkId,
      dogId: dogId ?? this.dogId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (walkId.present) {
      map['walk_id'] = Variable<String>(walkId.value);
    }
    if (dogId.present) {
      map['dog_id'] = Variable<String>(dogId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WalkDogsCompanion(')
          ..write('walkId: $walkId, ')
          ..write('dogId: $dogId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WalkPointsTable extends WalkPoints
    with TableInfo<$WalkPointsTable, WalkPointRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WalkPointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _walkIdMeta = const VerificationMeta('walkId');
  @override
  late final GeneratedColumn<String> walkId = GeneratedColumn<String>(
    'walk_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES walks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  static const VerificationMeta _accuracyMeta = const VerificationMeta(
    'accuracy',
  );
  @override
  late final GeneratedColumn<double> accuracy = GeneratedColumn<double>(
    'accuracy',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    walkId,
    seq,
    lat,
    lng,
    recordedAt,
    accuracy,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'walk_points';
  @override
  VerificationContext validateIntegrity(
    Insertable<WalkPointRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('walk_id')) {
      context.handle(
        _walkIdMeta,
        walkId.isAcceptableOrUnknown(data['walk_id']!, _walkIdMeta),
      );
    } else if (isInserting) {
      context.missing(_walkIdMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    } else if (isInserting) {
      context.missing(_seqMeta);
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
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('accuracy')) {
      context.handle(
        _accuracyMeta,
        accuracy.isAcceptableOrUnknown(data['accuracy']!, _accuracyMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {walkId, seq};
  @override
  WalkPointRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WalkPointRow(
      walkId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}walk_id'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lng'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      accuracy: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}accuracy'],
      ),
    );
  }

  @override
  $WalkPointsTable createAlias(String alias) {
    return $WalkPointsTable(attachedDatabase, alias);
  }
}

class WalkPointRow extends DataClass implements Insertable<WalkPointRow> {
  final String walkId;
  final int seq;
  final double lat;
  final double lng;
  final DateTime recordedAt;
  final double? accuracy;
  const WalkPointRow({
    required this.walkId,
    required this.seq,
    required this.lat,
    required this.lng,
    required this.recordedAt,
    this.accuracy,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['walk_id'] = Variable<String>(walkId);
    map['seq'] = Variable<int>(seq);
    map['lat'] = Variable<double>(lat);
    map['lng'] = Variable<double>(lng);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    if (!nullToAbsent || accuracy != null) {
      map['accuracy'] = Variable<double>(accuracy);
    }
    return map;
  }

  WalkPointsCompanion toCompanion(bool nullToAbsent) {
    return WalkPointsCompanion(
      walkId: Value(walkId),
      seq: Value(seq),
      lat: Value(lat),
      lng: Value(lng),
      recordedAt: Value(recordedAt),
      accuracy: accuracy == null && nullToAbsent
          ? const Value.absent()
          : Value(accuracy),
    );
  }

  factory WalkPointRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WalkPointRow(
      walkId: serializer.fromJson<String>(json['walkId']),
      seq: serializer.fromJson<int>(json['seq']),
      lat: serializer.fromJson<double>(json['lat']),
      lng: serializer.fromJson<double>(json['lng']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      accuracy: serializer.fromJson<double?>(json['accuracy']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'walkId': serializer.toJson<String>(walkId),
      'seq': serializer.toJson<int>(seq),
      'lat': serializer.toJson<double>(lat),
      'lng': serializer.toJson<double>(lng),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'accuracy': serializer.toJson<double?>(accuracy),
    };
  }

  WalkPointRow copyWith({
    String? walkId,
    int? seq,
    double? lat,
    double? lng,
    DateTime? recordedAt,
    Value<double?> accuracy = const Value.absent(),
  }) => WalkPointRow(
    walkId: walkId ?? this.walkId,
    seq: seq ?? this.seq,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    recordedAt: recordedAt ?? this.recordedAt,
    accuracy: accuracy.present ? accuracy.value : this.accuracy,
  );
  WalkPointRow copyWithCompanion(WalkPointsCompanion data) {
    return WalkPointRow(
      walkId: data.walkId.present ? data.walkId.value : this.walkId,
      seq: data.seq.present ? data.seq.value : this.seq,
      lat: data.lat.present ? data.lat.value : this.lat,
      lng: data.lng.present ? data.lng.value : this.lng,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      accuracy: data.accuracy.present ? data.accuracy.value : this.accuracy,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WalkPointRow(')
          ..write('walkId: $walkId, ')
          ..write('seq: $seq, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('accuracy: $accuracy')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(walkId, seq, lat, lng, recordedAt, accuracy);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WalkPointRow &&
          other.walkId == this.walkId &&
          other.seq == this.seq &&
          other.lat == this.lat &&
          other.lng == this.lng &&
          other.recordedAt == this.recordedAt &&
          other.accuracy == this.accuracy);
}

class WalkPointsCompanion extends UpdateCompanion<WalkPointRow> {
  final Value<String> walkId;
  final Value<int> seq;
  final Value<double> lat;
  final Value<double> lng;
  final Value<DateTime> recordedAt;
  final Value<double?> accuracy;
  final Value<int> rowid;
  const WalkPointsCompanion({
    this.walkId = const Value.absent(),
    this.seq = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.accuracy = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WalkPointsCompanion.insert({
    required String walkId,
    required int seq,
    required double lat,
    required double lng,
    required DateTime recordedAt,
    this.accuracy = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : walkId = Value(walkId),
       seq = Value(seq),
       lat = Value(lat),
       lng = Value(lng),
       recordedAt = Value(recordedAt);
  static Insertable<WalkPointRow> custom({
    Expression<String>? walkId,
    Expression<int>? seq,
    Expression<double>? lat,
    Expression<double>? lng,
    Expression<DateTime>? recordedAt,
    Expression<double>? accuracy,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (walkId != null) 'walk_id': walkId,
      if (seq != null) 'seq': seq,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (accuracy != null) 'accuracy': accuracy,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WalkPointsCompanion copyWith({
    Value<String>? walkId,
    Value<int>? seq,
    Value<double>? lat,
    Value<double>? lng,
    Value<DateTime>? recordedAt,
    Value<double?>? accuracy,
    Value<int>? rowid,
  }) {
    return WalkPointsCompanion(
      walkId: walkId ?? this.walkId,
      seq: seq ?? this.seq,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      recordedAt: recordedAt ?? this.recordedAt,
      accuracy: accuracy ?? this.accuracy,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (walkId.present) {
      map['walk_id'] = Variable<String>(walkId.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lng.present) {
      map['lng'] = Variable<double>(lng.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (accuracy.present) {
      map['accuracy'] = Variable<double>(accuracy.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WalkPointsCompanion(')
          ..write('walkId: $walkId, ')
          ..write('seq: $seq, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('accuracy: $accuracy, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WalkPhotosTable extends WalkPhotos
    with TableInfo<$WalkPhotosTable, WalkPhotoRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WalkPhotosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _walkIdMeta = const VerificationMeta('walkId');
  @override
  late final GeneratedColumn<String> walkId = GeneratedColumn<String>(
    'walk_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES walks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, walkId, path, position, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'walk_photos';
  @override
  VerificationContext validateIntegrity(
    Insertable<WalkPhotoRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('walk_id')) {
      context.handle(
        _walkIdMeta,
        walkId.isAcceptableOrUnknown(data['walk_id']!, _walkIdMeta),
      );
    } else if (isInserting) {
      context.missing(_walkIdMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WalkPhotoRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WalkPhotoRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      walkId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}walk_id'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $WalkPhotosTable createAlias(String alias) {
    return $WalkPhotosTable(attachedDatabase, alias);
  }
}

class WalkPhotoRow extends DataClass implements Insertable<WalkPhotoRow> {
  final String id;
  final String walkId;
  final String path;
  final int position;
  final DateTime createdAt;
  const WalkPhotoRow({
    required this.id,
    required this.walkId,
    required this.path,
    required this.position,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['walk_id'] = Variable<String>(walkId);
    map['path'] = Variable<String>(path);
    map['position'] = Variable<int>(position);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  WalkPhotosCompanion toCompanion(bool nullToAbsent) {
    return WalkPhotosCompanion(
      id: Value(id),
      walkId: Value(walkId),
      path: Value(path),
      position: Value(position),
      createdAt: Value(createdAt),
    );
  }

  factory WalkPhotoRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WalkPhotoRow(
      id: serializer.fromJson<String>(json['id']),
      walkId: serializer.fromJson<String>(json['walkId']),
      path: serializer.fromJson<String>(json['path']),
      position: serializer.fromJson<int>(json['position']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'walkId': serializer.toJson<String>(walkId),
      'path': serializer.toJson<String>(path),
      'position': serializer.toJson<int>(position),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  WalkPhotoRow copyWith({
    String? id,
    String? walkId,
    String? path,
    int? position,
    DateTime? createdAt,
  }) => WalkPhotoRow(
    id: id ?? this.id,
    walkId: walkId ?? this.walkId,
    path: path ?? this.path,
    position: position ?? this.position,
    createdAt: createdAt ?? this.createdAt,
  );
  WalkPhotoRow copyWithCompanion(WalkPhotosCompanion data) {
    return WalkPhotoRow(
      id: data.id.present ? data.id.value : this.id,
      walkId: data.walkId.present ? data.walkId.value : this.walkId,
      path: data.path.present ? data.path.value : this.path,
      position: data.position.present ? data.position.value : this.position,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WalkPhotoRow(')
          ..write('id: $id, ')
          ..write('walkId: $walkId, ')
          ..write('path: $path, ')
          ..write('position: $position, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, walkId, path, position, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WalkPhotoRow &&
          other.id == this.id &&
          other.walkId == this.walkId &&
          other.path == this.path &&
          other.position == this.position &&
          other.createdAt == this.createdAt);
}

class WalkPhotosCompanion extends UpdateCompanion<WalkPhotoRow> {
  final Value<String> id;
  final Value<String> walkId;
  final Value<String> path;
  final Value<int> position;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const WalkPhotosCompanion({
    this.id = const Value.absent(),
    this.walkId = const Value.absent(),
    this.path = const Value.absent(),
    this.position = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WalkPhotosCompanion.insert({
    required String id,
    required String walkId,
    required String path,
    required int position,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       walkId = Value(walkId),
       path = Value(path),
       position = Value(position),
       createdAt = Value(createdAt);
  static Insertable<WalkPhotoRow> custom({
    Expression<String>? id,
    Expression<String>? walkId,
    Expression<String>? path,
    Expression<int>? position,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (walkId != null) 'walk_id': walkId,
      if (path != null) 'path': path,
      if (position != null) 'position': position,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WalkPhotosCompanion copyWith({
    Value<String>? id,
    Value<String>? walkId,
    Value<String>? path,
    Value<int>? position,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return WalkPhotosCompanion(
      id: id ?? this.id,
      walkId: walkId ?? this.walkId,
      path: path ?? this.path,
      position: position ?? this.position,
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
    if (walkId.present) {
      map['walk_id'] = Variable<String>(walkId.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
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
    return (StringBuffer('WalkPhotosCompanion(')
          ..write('id: $id, ')
          ..write('walkId: $walkId, ')
          ..write('path: $path, ')
          ..write('position: $position, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$WalkDatabase extends GeneratedDatabase {
  _$WalkDatabase(QueryExecutor e) : super(e);
  $WalkDatabaseManager get managers => $WalkDatabaseManager(this);
  late final $DogsTable dogs = $DogsTable(this);
  late final $WalksTable walks = $WalksTable(this);
  late final $WalkDogsTable walkDogs = $WalkDogsTable(this);
  late final $WalkPointsTable walkPoints = $WalkPointsTable(this);
  late final $WalkPhotosTable walkPhotos = $WalkPhotosTable(this);
  late final Index walksStartedAt = Index(
    'walks_started_at',
    'CREATE INDEX walks_started_at ON walks (started_at)',
  );
  late final Index walkPhotosWalkId = Index(
    'walk_photos_walk_id',
    'CREATE INDEX walk_photos_walk_id ON walk_photos (walk_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    dogs,
    walks,
    walkDogs,
    walkPoints,
    walkPhotos,
    walksStartedAt,
    walkPhotosWalkId,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'walks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('walk_dogs', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'dogs',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('walk_dogs', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'walks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('walk_points', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'walks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('walk_photos', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$DogsTableCreateCompanionBuilder =
    DogsCompanion Function({
      required String id,
      required String name,
      Value<String?> breed,
      Value<String?> birthday,
      Value<String?> photoPath,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$DogsTableUpdateCompanionBuilder =
    DogsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> breed,
      Value<String?> birthday,
      Value<String?> photoPath,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$DogsTableReferences
    extends BaseReferences<_$WalkDatabase, $DogsTable, DogRow> {
  $$DogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$WalkDogsTable, List<WalkDogRow>>
  _walkDogsRefsTable(_$WalkDatabase db) => MultiTypedResultKey.fromTable(
    db.walkDogs,
    aliasName: 'dogs__id__walk_dogs__dog_id',
  );

  $$WalkDogsTableProcessedTableManager get walkDogsRefs {
    final manager = $$WalkDogsTableTableManager(
      $_db,
      $_db.walkDogs,
    ).filter((f) => f.dogId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_walkDogsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DogsTableFilterComposer extends Composer<_$WalkDatabase, $DogsTable> {
  $$DogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get breed => $composableBuilder(
    column: $table.breed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get birthday => $composableBuilder(
    column: $table.birthday,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> walkDogsRefs(
    Expression<bool> Function($$WalkDogsTableFilterComposer f) f,
  ) {
    final $$WalkDogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.walkDogs,
      getReferencedColumn: (t) => t.dogId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalkDogsTableFilterComposer(
            $db: $db,
            $table: $db.walkDogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DogsTableOrderingComposer extends Composer<_$WalkDatabase, $DogsTable> {
  $$DogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get breed => $composableBuilder(
    column: $table.breed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get birthday => $composableBuilder(
    column: $table.birthday,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DogsTableAnnotationComposer
    extends Composer<_$WalkDatabase, $DogsTable> {
  $$DogsTableAnnotationComposer({
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

  GeneratedColumn<String> get breed =>
      $composableBuilder(column: $table.breed, builder: (column) => column);

  GeneratedColumn<String> get birthday =>
      $composableBuilder(column: $table.birthday, builder: (column) => column);

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> walkDogsRefs<T extends Object>(
    Expression<T> Function($$WalkDogsTableAnnotationComposer a) f,
  ) {
    final $$WalkDogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.walkDogs,
      getReferencedColumn: (t) => t.dogId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalkDogsTableAnnotationComposer(
            $db: $db,
            $table: $db.walkDogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DogsTableTableManager
    extends
        RootTableManager<
          _$WalkDatabase,
          $DogsTable,
          DogRow,
          $$DogsTableFilterComposer,
          $$DogsTableOrderingComposer,
          $$DogsTableAnnotationComposer,
          $$DogsTableCreateCompanionBuilder,
          $$DogsTableUpdateCompanionBuilder,
          (DogRow, $$DogsTableReferences),
          DogRow,
          PrefetchHooks Function({bool walkDogsRefs})
        > {
  $$DogsTableTableManager(_$WalkDatabase db, $DogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> breed = const Value.absent(),
                Value<String?> birthday = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DogsCompanion(
                id: id,
                name: name,
                breed: breed,
                birthday: birthday,
                photoPath: photoPath,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> breed = const Value.absent(),
                Value<String?> birthday = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => DogsCompanion.insert(
                id: id,
                name: name,
                breed: breed,
                birthday: birthday,
                photoPath: photoPath,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$DogsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({walkDogsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (walkDogsRefs) db.walkDogs],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (walkDogsRefs)
                    await $_getPrefetchedData<DogRow, $DogsTable, WalkDogRow>(
                      currentTable: table,
                      referencedTable: $$DogsTableReferences._walkDogsRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$DogsTableReferences(db, table, p0).walkDogsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.dogId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$DogsTableProcessedTableManager =
    ProcessedTableManager<
      _$WalkDatabase,
      $DogsTable,
      DogRow,
      $$DogsTableFilterComposer,
      $$DogsTableOrderingComposer,
      $$DogsTableAnnotationComposer,
      $$DogsTableCreateCompanionBuilder,
      $$DogsTableUpdateCompanionBuilder,
      (DogRow, $$DogsTableReferences),
      DogRow,
      PrefetchHooks Function({bool walkDogsRefs})
    >;
typedef $$WalksTableCreateCompanionBuilder =
    WalksCompanion Function({
      required String id,
      required DateTime startedAt,
      required DateTime endedAt,
      required int durationSeconds,
      required double distanceMeters,
      Value<String?> memo,
      Value<String?> routePreview,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$WalksTableUpdateCompanionBuilder =
    WalksCompanion Function({
      Value<String> id,
      Value<DateTime> startedAt,
      Value<DateTime> endedAt,
      Value<int> durationSeconds,
      Value<double> distanceMeters,
      Value<String?> memo,
      Value<String?> routePreview,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$WalksTableReferences
    extends BaseReferences<_$WalkDatabase, $WalksTable, WalkRow> {
  $$WalksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$WalkDogsTable, List<WalkDogRow>>
  _walkDogsRefsTable(_$WalkDatabase db) => MultiTypedResultKey.fromTable(
    db.walkDogs,
    aliasName: 'walks__id__walk_dogs__walk_id',
  );

  $$WalkDogsTableProcessedTableManager get walkDogsRefs {
    final manager = $$WalkDogsTableTableManager(
      $_db,
      $_db.walkDogs,
    ).filter((f) => f.walkId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_walkDogsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$WalkPointsTable, List<WalkPointRow>>
  _walkPointsRefsTable(_$WalkDatabase db) => MultiTypedResultKey.fromTable(
    db.walkPoints,
    aliasName: 'walks__id__walk_points__walk_id',
  );

  $$WalkPointsTableProcessedTableManager get walkPointsRefs {
    final manager = $$WalkPointsTableTableManager(
      $_db,
      $_db.walkPoints,
    ).filter((f) => f.walkId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_walkPointsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$WalkPhotosTable, List<WalkPhotoRow>>
  _walkPhotosRefsTable(_$WalkDatabase db) => MultiTypedResultKey.fromTable(
    db.walkPhotos,
    aliasName: 'walks__id__walk_photos__walk_id',
  );

  $$WalkPhotosTableProcessedTableManager get walkPhotosRefs {
    final manager = $$WalkPhotosTableTableManager(
      $_db,
      $_db.walkPhotos,
    ).filter((f) => f.walkId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_walkPhotosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WalksTableFilterComposer extends Composer<_$WalkDatabase, $WalksTable> {
  $$WalksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
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

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get routePreview => $composableBuilder(
    column: $table.routePreview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> walkDogsRefs(
    Expression<bool> Function($$WalkDogsTableFilterComposer f) f,
  ) {
    final $$WalkDogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.walkDogs,
      getReferencedColumn: (t) => t.walkId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalkDogsTableFilterComposer(
            $db: $db,
            $table: $db.walkDogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> walkPointsRefs(
    Expression<bool> Function($$WalkPointsTableFilterComposer f) f,
  ) {
    final $$WalkPointsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.walkPoints,
      getReferencedColumn: (t) => t.walkId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalkPointsTableFilterComposer(
            $db: $db,
            $table: $db.walkPoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> walkPhotosRefs(
    Expression<bool> Function($$WalkPhotosTableFilterComposer f) f,
  ) {
    final $$WalkPhotosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.walkPhotos,
      getReferencedColumn: (t) => t.walkId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalkPhotosTableFilterComposer(
            $db: $db,
            $table: $db.walkPhotos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WalksTableOrderingComposer
    extends Composer<_$WalkDatabase, $WalksTable> {
  $$WalksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
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

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get routePreview => $composableBuilder(
    column: $table.routePreview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WalksTableAnnotationComposer
    extends Composer<_$WalkDatabase, $WalksTable> {
  $$WalksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => column,
  );

  GeneratedColumn<String> get memo =>
      $composableBuilder(column: $table.memo, builder: (column) => column);

  GeneratedColumn<String> get routePreview => $composableBuilder(
    column: $table.routePreview,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> walkDogsRefs<T extends Object>(
    Expression<T> Function($$WalkDogsTableAnnotationComposer a) f,
  ) {
    final $$WalkDogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.walkDogs,
      getReferencedColumn: (t) => t.walkId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalkDogsTableAnnotationComposer(
            $db: $db,
            $table: $db.walkDogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> walkPointsRefs<T extends Object>(
    Expression<T> Function($$WalkPointsTableAnnotationComposer a) f,
  ) {
    final $$WalkPointsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.walkPoints,
      getReferencedColumn: (t) => t.walkId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalkPointsTableAnnotationComposer(
            $db: $db,
            $table: $db.walkPoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> walkPhotosRefs<T extends Object>(
    Expression<T> Function($$WalkPhotosTableAnnotationComposer a) f,
  ) {
    final $$WalkPhotosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.walkPhotos,
      getReferencedColumn: (t) => t.walkId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalkPhotosTableAnnotationComposer(
            $db: $db,
            $table: $db.walkPhotos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WalksTableTableManager
    extends
        RootTableManager<
          _$WalkDatabase,
          $WalksTable,
          WalkRow,
          $$WalksTableFilterComposer,
          $$WalksTableOrderingComposer,
          $$WalksTableAnnotationComposer,
          $$WalksTableCreateCompanionBuilder,
          $$WalksTableUpdateCompanionBuilder,
          (WalkRow, $$WalksTableReferences),
          WalkRow,
          PrefetchHooks Function({
            bool walkDogsRefs,
            bool walkPointsRefs,
            bool walkPhotosRefs,
          })
        > {
  $$WalksTableTableManager(_$WalkDatabase db, $WalksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WalksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WalksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WalksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime> endedAt = const Value.absent(),
                Value<int> durationSeconds = const Value.absent(),
                Value<double> distanceMeters = const Value.absent(),
                Value<String?> memo = const Value.absent(),
                Value<String?> routePreview = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WalksCompanion(
                id: id,
                startedAt: startedAt,
                endedAt: endedAt,
                durationSeconds: durationSeconds,
                distanceMeters: distanceMeters,
                memo: memo,
                routePreview: routePreview,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime startedAt,
                required DateTime endedAt,
                required int durationSeconds,
                required double distanceMeters,
                Value<String?> memo = const Value.absent(),
                Value<String?> routePreview = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => WalksCompanion.insert(
                id: id,
                startedAt: startedAt,
                endedAt: endedAt,
                durationSeconds: durationSeconds,
                distanceMeters: distanceMeters,
                memo: memo,
                routePreview: routePreview,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$WalksTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                walkDogsRefs = false,
                walkPointsRefs = false,
                walkPhotosRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (walkDogsRefs) db.walkDogs,
                    if (walkPointsRefs) db.walkPoints,
                    if (walkPhotosRefs) db.walkPhotos,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (walkDogsRefs)
                        await $_getPrefetchedData<
                          WalkRow,
                          $WalksTable,
                          WalkDogRow
                        >(
                          currentTable: table,
                          referencedTable: $$WalksTableReferences
                              ._walkDogsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WalksTableReferences(
                                db,
                                table,
                                p0,
                              ).walkDogsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.walkId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (walkPointsRefs)
                        await $_getPrefetchedData<
                          WalkRow,
                          $WalksTable,
                          WalkPointRow
                        >(
                          currentTable: table,
                          referencedTable: $$WalksTableReferences
                              ._walkPointsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WalksTableReferences(
                                db,
                                table,
                                p0,
                              ).walkPointsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.walkId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (walkPhotosRefs)
                        await $_getPrefetchedData<
                          WalkRow,
                          $WalksTable,
                          WalkPhotoRow
                        >(
                          currentTable: table,
                          referencedTable: $$WalksTableReferences
                              ._walkPhotosRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WalksTableReferences(
                                db,
                                table,
                                p0,
                              ).walkPhotosRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.walkId == item.id,
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

typedef $$WalksTableProcessedTableManager =
    ProcessedTableManager<
      _$WalkDatabase,
      $WalksTable,
      WalkRow,
      $$WalksTableFilterComposer,
      $$WalksTableOrderingComposer,
      $$WalksTableAnnotationComposer,
      $$WalksTableCreateCompanionBuilder,
      $$WalksTableUpdateCompanionBuilder,
      (WalkRow, $$WalksTableReferences),
      WalkRow,
      PrefetchHooks Function({
        bool walkDogsRefs,
        bool walkPointsRefs,
        bool walkPhotosRefs,
      })
    >;
typedef $$WalkDogsTableCreateCompanionBuilder =
    WalkDogsCompanion Function({
      required String walkId,
      required String dogId,
      Value<int> rowid,
    });
typedef $$WalkDogsTableUpdateCompanionBuilder =
    WalkDogsCompanion Function({
      Value<String> walkId,
      Value<String> dogId,
      Value<int> rowid,
    });

final class $$WalkDogsTableReferences
    extends BaseReferences<_$WalkDatabase, $WalkDogsTable, WalkDogRow> {
  $$WalkDogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WalksTable _walkIdTable(_$WalkDatabase db) =>
      db.walks.createAlias('walk_dogs__walk_id__walks__id');

  $$WalksTableProcessedTableManager get walkId {
    final $_column = $_itemColumn<String>('walk_id')!;

    final manager = $$WalksTableTableManager(
      $_db,
      $_db.walks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_walkIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $DogsTable _dogIdTable(_$WalkDatabase db) =>
      db.dogs.createAlias('walk_dogs__dog_id__dogs__id');

  $$DogsTableProcessedTableManager get dogId {
    final $_column = $_itemColumn<String>('dog_id')!;

    final manager = $$DogsTableTableManager(
      $_db,
      $_db.dogs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_dogIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$WalkDogsTableFilterComposer
    extends Composer<_$WalkDatabase, $WalkDogsTable> {
  $$WalkDogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$WalksTableFilterComposer get walkId {
    final $$WalksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.walkId,
      referencedTable: $db.walks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalksTableFilterComposer(
            $db: $db,
            $table: $db.walks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DogsTableFilterComposer get dogId {
    final $$DogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dogId,
      referencedTable: $db.dogs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DogsTableFilterComposer(
            $db: $db,
            $table: $db.dogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WalkDogsTableOrderingComposer
    extends Composer<_$WalkDatabase, $WalkDogsTable> {
  $$WalkDogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$WalksTableOrderingComposer get walkId {
    final $$WalksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.walkId,
      referencedTable: $db.walks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalksTableOrderingComposer(
            $db: $db,
            $table: $db.walks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DogsTableOrderingComposer get dogId {
    final $$DogsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dogId,
      referencedTable: $db.dogs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DogsTableOrderingComposer(
            $db: $db,
            $table: $db.dogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WalkDogsTableAnnotationComposer
    extends Composer<_$WalkDatabase, $WalkDogsTable> {
  $$WalkDogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$WalksTableAnnotationComposer get walkId {
    final $$WalksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.walkId,
      referencedTable: $db.walks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalksTableAnnotationComposer(
            $db: $db,
            $table: $db.walks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DogsTableAnnotationComposer get dogId {
    final $$DogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dogId,
      referencedTable: $db.dogs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DogsTableAnnotationComposer(
            $db: $db,
            $table: $db.dogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WalkDogsTableTableManager
    extends
        RootTableManager<
          _$WalkDatabase,
          $WalkDogsTable,
          WalkDogRow,
          $$WalkDogsTableFilterComposer,
          $$WalkDogsTableOrderingComposer,
          $$WalkDogsTableAnnotationComposer,
          $$WalkDogsTableCreateCompanionBuilder,
          $$WalkDogsTableUpdateCompanionBuilder,
          (WalkDogRow, $$WalkDogsTableReferences),
          WalkDogRow,
          PrefetchHooks Function({bool walkId, bool dogId})
        > {
  $$WalkDogsTableTableManager(_$WalkDatabase db, $WalkDogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WalkDogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WalkDogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WalkDogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> walkId = const Value.absent(),
                Value<String> dogId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) =>
                  WalkDogsCompanion(walkId: walkId, dogId: dogId, rowid: rowid),
          createCompanionCallback:
              ({
                required String walkId,
                required String dogId,
                Value<int> rowid = const Value.absent(),
              }) => WalkDogsCompanion.insert(
                walkId: walkId,
                dogId: dogId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WalkDogsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({walkId = false, dogId = false}) {
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
                    if (walkId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.walkId,
                                referencedTable: $$WalkDogsTableReferences
                                    ._walkIdTable(db),
                                referencedColumn: $$WalkDogsTableReferences
                                    ._walkIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (dogId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.dogId,
                                referencedTable: $$WalkDogsTableReferences
                                    ._dogIdTable(db),
                                referencedColumn: $$WalkDogsTableReferences
                                    ._dogIdTable(db)
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

typedef $$WalkDogsTableProcessedTableManager =
    ProcessedTableManager<
      _$WalkDatabase,
      $WalkDogsTable,
      WalkDogRow,
      $$WalkDogsTableFilterComposer,
      $$WalkDogsTableOrderingComposer,
      $$WalkDogsTableAnnotationComposer,
      $$WalkDogsTableCreateCompanionBuilder,
      $$WalkDogsTableUpdateCompanionBuilder,
      (WalkDogRow, $$WalkDogsTableReferences),
      WalkDogRow,
      PrefetchHooks Function({bool walkId, bool dogId})
    >;
typedef $$WalkPointsTableCreateCompanionBuilder =
    WalkPointsCompanion Function({
      required String walkId,
      required int seq,
      required double lat,
      required double lng,
      required DateTime recordedAt,
      Value<double?> accuracy,
      Value<int> rowid,
    });
typedef $$WalkPointsTableUpdateCompanionBuilder =
    WalkPointsCompanion Function({
      Value<String> walkId,
      Value<int> seq,
      Value<double> lat,
      Value<double> lng,
      Value<DateTime> recordedAt,
      Value<double?> accuracy,
      Value<int> rowid,
    });

final class $$WalkPointsTableReferences
    extends BaseReferences<_$WalkDatabase, $WalkPointsTable, WalkPointRow> {
  $$WalkPointsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WalksTable _walkIdTable(_$WalkDatabase db) =>
      db.walks.createAlias('walk_points__walk_id__walks__id');

  $$WalksTableProcessedTableManager get walkId {
    final $_column = $_itemColumn<String>('walk_id')!;

    final manager = $$WalksTableTableManager(
      $_db,
      $_db.walks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_walkIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$WalkPointsTableFilterComposer
    extends Composer<_$WalkDatabase, $WalkPointsTable> {
  $$WalkPointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
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

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get accuracy => $composableBuilder(
    column: $table.accuracy,
    builder: (column) => ColumnFilters(column),
  );

  $$WalksTableFilterComposer get walkId {
    final $$WalksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.walkId,
      referencedTable: $db.walks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalksTableFilterComposer(
            $db: $db,
            $table: $db.walks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WalkPointsTableOrderingComposer
    extends Composer<_$WalkDatabase, $WalkPointsTable> {
  $$WalkPointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
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

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get accuracy => $composableBuilder(
    column: $table.accuracy,
    builder: (column) => ColumnOrderings(column),
  );

  $$WalksTableOrderingComposer get walkId {
    final $$WalksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.walkId,
      referencedTable: $db.walks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalksTableOrderingComposer(
            $db: $db,
            $table: $db.walks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WalkPointsTableAnnotationComposer
    extends Composer<_$WalkDatabase, $WalkPointsTable> {
  $$WalkPointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lng =>
      $composableBuilder(column: $table.lng, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<double> get accuracy =>
      $composableBuilder(column: $table.accuracy, builder: (column) => column);

  $$WalksTableAnnotationComposer get walkId {
    final $$WalksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.walkId,
      referencedTable: $db.walks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalksTableAnnotationComposer(
            $db: $db,
            $table: $db.walks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WalkPointsTableTableManager
    extends
        RootTableManager<
          _$WalkDatabase,
          $WalkPointsTable,
          WalkPointRow,
          $$WalkPointsTableFilterComposer,
          $$WalkPointsTableOrderingComposer,
          $$WalkPointsTableAnnotationComposer,
          $$WalkPointsTableCreateCompanionBuilder,
          $$WalkPointsTableUpdateCompanionBuilder,
          (WalkPointRow, $$WalkPointsTableReferences),
          WalkPointRow,
          PrefetchHooks Function({bool walkId})
        > {
  $$WalkPointsTableTableManager(_$WalkDatabase db, $WalkPointsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WalkPointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WalkPointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WalkPointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> walkId = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<double> lat = const Value.absent(),
                Value<double> lng = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<double?> accuracy = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WalkPointsCompanion(
                walkId: walkId,
                seq: seq,
                lat: lat,
                lng: lng,
                recordedAt: recordedAt,
                accuracy: accuracy,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String walkId,
                required int seq,
                required double lat,
                required double lng,
                required DateTime recordedAt,
                Value<double?> accuracy = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WalkPointsCompanion.insert(
                walkId: walkId,
                seq: seq,
                lat: lat,
                lng: lng,
                recordedAt: recordedAt,
                accuracy: accuracy,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WalkPointsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({walkId = false}) {
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
                    if (walkId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.walkId,
                                referencedTable: $$WalkPointsTableReferences
                                    ._walkIdTable(db),
                                referencedColumn: $$WalkPointsTableReferences
                                    ._walkIdTable(db)
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

typedef $$WalkPointsTableProcessedTableManager =
    ProcessedTableManager<
      _$WalkDatabase,
      $WalkPointsTable,
      WalkPointRow,
      $$WalkPointsTableFilterComposer,
      $$WalkPointsTableOrderingComposer,
      $$WalkPointsTableAnnotationComposer,
      $$WalkPointsTableCreateCompanionBuilder,
      $$WalkPointsTableUpdateCompanionBuilder,
      (WalkPointRow, $$WalkPointsTableReferences),
      WalkPointRow,
      PrefetchHooks Function({bool walkId})
    >;
typedef $$WalkPhotosTableCreateCompanionBuilder =
    WalkPhotosCompanion Function({
      required String id,
      required String walkId,
      required String path,
      required int position,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$WalkPhotosTableUpdateCompanionBuilder =
    WalkPhotosCompanion Function({
      Value<String> id,
      Value<String> walkId,
      Value<String> path,
      Value<int> position,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$WalkPhotosTableReferences
    extends BaseReferences<_$WalkDatabase, $WalkPhotosTable, WalkPhotoRow> {
  $$WalkPhotosTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WalksTable _walkIdTable(_$WalkDatabase db) =>
      db.walks.createAlias('walk_photos__walk_id__walks__id');

  $$WalksTableProcessedTableManager get walkId {
    final $_column = $_itemColumn<String>('walk_id')!;

    final manager = $$WalksTableTableManager(
      $_db,
      $_db.walks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_walkIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$WalkPhotosTableFilterComposer
    extends Composer<_$WalkDatabase, $WalkPhotosTable> {
  $$WalkPhotosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$WalksTableFilterComposer get walkId {
    final $$WalksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.walkId,
      referencedTable: $db.walks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalksTableFilterComposer(
            $db: $db,
            $table: $db.walks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WalkPhotosTableOrderingComposer
    extends Composer<_$WalkDatabase, $WalkPhotosTable> {
  $$WalkPhotosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$WalksTableOrderingComposer get walkId {
    final $$WalksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.walkId,
      referencedTable: $db.walks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalksTableOrderingComposer(
            $db: $db,
            $table: $db.walks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WalkPhotosTableAnnotationComposer
    extends Composer<_$WalkDatabase, $WalkPhotosTable> {
  $$WalkPhotosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$WalksTableAnnotationComposer get walkId {
    final $$WalksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.walkId,
      referencedTable: $db.walks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalksTableAnnotationComposer(
            $db: $db,
            $table: $db.walks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WalkPhotosTableTableManager
    extends
        RootTableManager<
          _$WalkDatabase,
          $WalkPhotosTable,
          WalkPhotoRow,
          $$WalkPhotosTableFilterComposer,
          $$WalkPhotosTableOrderingComposer,
          $$WalkPhotosTableAnnotationComposer,
          $$WalkPhotosTableCreateCompanionBuilder,
          $$WalkPhotosTableUpdateCompanionBuilder,
          (WalkPhotoRow, $$WalkPhotosTableReferences),
          WalkPhotoRow,
          PrefetchHooks Function({bool walkId})
        > {
  $$WalkPhotosTableTableManager(_$WalkDatabase db, $WalkPhotosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WalkPhotosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WalkPhotosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WalkPhotosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> walkId = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WalkPhotosCompanion(
                id: id,
                walkId: walkId,
                path: path,
                position: position,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String walkId,
                required String path,
                required int position,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => WalkPhotosCompanion.insert(
                id: id,
                walkId: walkId,
                path: path,
                position: position,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WalkPhotosTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({walkId = false}) {
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
                    if (walkId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.walkId,
                                referencedTable: $$WalkPhotosTableReferences
                                    ._walkIdTable(db),
                                referencedColumn: $$WalkPhotosTableReferences
                                    ._walkIdTable(db)
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

typedef $$WalkPhotosTableProcessedTableManager =
    ProcessedTableManager<
      _$WalkDatabase,
      $WalkPhotosTable,
      WalkPhotoRow,
      $$WalkPhotosTableFilterComposer,
      $$WalkPhotosTableOrderingComposer,
      $$WalkPhotosTableAnnotationComposer,
      $$WalkPhotosTableCreateCompanionBuilder,
      $$WalkPhotosTableUpdateCompanionBuilder,
      (WalkPhotoRow, $$WalkPhotosTableReferences),
      WalkPhotoRow,
      PrefetchHooks Function({bool walkId})
    >;

class $WalkDatabaseManager {
  final _$WalkDatabase _db;
  $WalkDatabaseManager(this._db);
  $$DogsTableTableManager get dogs => $$DogsTableTableManager(_db, _db.dogs);
  $$WalksTableTableManager get walks =>
      $$WalksTableTableManager(_db, _db.walks);
  $$WalkDogsTableTableManager get walkDogs =>
      $$WalkDogsTableTableManager(_db, _db.walkDogs);
  $$WalkPointsTableTableManager get walkPoints =>
      $$WalkPointsTableTableManager(_db, _db.walkPoints);
  $$WalkPhotosTableTableManager get walkPhotos =>
      $$WalkPhotosTableTableManager(_db, _db.walkPhotos);
}
