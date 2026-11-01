// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ring_archive_database.dart';

// ignore_for_file: type=lint
class $ArchivedRingsTable extends ArchivedRings
    with TableInfo<$ArchivedRingsTable, ArchivedRingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ArchivedRingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _packageIdMeta = const VerificationMeta(
    'packageId',
  );
  @override
  late final GeneratedColumn<int> packageId = GeneratedColumn<int>(
    'package_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<RingLogKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<RingLogKind>($ArchivedRingsTable.$converterkind);
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hourMeta = const VerificationMeta('hour');
  @override
  late final GeneratedColumn<int> hour = GeneratedColumn<int>(
    'hour',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _minuteMeta = const VerificationMeta('minute');
  @override
  late final GeneratedColumn<int> minute = GeneratedColumn<int>(
    'minute',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    at,
    packageId,
    kind,
    label,
    hour,
    minute,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'archived_rings';
  @override
  VerificationContext validateIntegrity(
    Insertable<ArchivedRingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('package_id')) {
      context.handle(
        _packageIdMeta,
        packageId.isAcceptableOrUnknown(data['package_id']!, _packageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_packageIdMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    if (data.containsKey('hour')) {
      context.handle(
        _hourMeta,
        hour.isAcceptableOrUnknown(data['hour']!, _hourMeta),
      );
    }
    if (data.containsKey('minute')) {
      context.handle(
        _minuteMeta,
        minute.isAcceptableOrUnknown(data['minute']!, _minuteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {at, packageId, kind};
  @override
  ArchivedRingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ArchivedRingRow(
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
      packageId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}package_id'],
      )!,
      kind: $ArchivedRingsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      ),
      hour: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hour'],
      ),
      minute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minute'],
      ),
    );
  }

  @override
  $ArchivedRingsTable createAlias(String alias) {
    return $ArchivedRingsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<RingLogKind, String, String> $converterkind =
      const EnumNameConverter<RingLogKind>(RingLogKind.values);
}

class ArchivedRingRow extends DataClass implements Insertable<ArchivedRingRow> {
  final DateTime at;
  final int packageId;
  final RingLogKind kind;
  final String? label;
  final int? hour;
  final int? minute;
  const ArchivedRingRow({
    required this.at,
    required this.packageId,
    required this.kind,
    this.label,
    this.hour,
    this.minute,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['at'] = Variable<DateTime>(at);
    map['package_id'] = Variable<int>(packageId);
    {
      map['kind'] = Variable<String>(
        $ArchivedRingsTable.$converterkind.toSql(kind),
      );
    }
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    if (!nullToAbsent || hour != null) {
      map['hour'] = Variable<int>(hour);
    }
    if (!nullToAbsent || minute != null) {
      map['minute'] = Variable<int>(minute);
    }
    return map;
  }

  ArchivedRingsCompanion toCompanion(bool nullToAbsent) {
    return ArchivedRingsCompanion(
      at: Value(at),
      packageId: Value(packageId),
      kind: Value(kind),
      label: label == null && nullToAbsent
          ? const Value.absent()
          : Value(label),
      hour: hour == null && nullToAbsent ? const Value.absent() : Value(hour),
      minute: minute == null && nullToAbsent
          ? const Value.absent()
          : Value(minute),
    );
  }

  factory ArchivedRingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ArchivedRingRow(
      at: serializer.fromJson<DateTime>(json['at']),
      packageId: serializer.fromJson<int>(json['packageId']),
      kind: $ArchivedRingsTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      label: serializer.fromJson<String?>(json['label']),
      hour: serializer.fromJson<int?>(json['hour']),
      minute: serializer.fromJson<int?>(json['minute']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'at': serializer.toJson<DateTime>(at),
      'packageId': serializer.toJson<int>(packageId),
      'kind': serializer.toJson<String>(
        $ArchivedRingsTable.$converterkind.toJson(kind),
      ),
      'label': serializer.toJson<String?>(label),
      'hour': serializer.toJson<int?>(hour),
      'minute': serializer.toJson<int?>(minute),
    };
  }

  ArchivedRingRow copyWith({
    DateTime? at,
    int? packageId,
    RingLogKind? kind,
    Value<String?> label = const Value.absent(),
    Value<int?> hour = const Value.absent(),
    Value<int?> minute = const Value.absent(),
  }) => ArchivedRingRow(
    at: at ?? this.at,
    packageId: packageId ?? this.packageId,
    kind: kind ?? this.kind,
    label: label.present ? label.value : this.label,
    hour: hour.present ? hour.value : this.hour,
    minute: minute.present ? minute.value : this.minute,
  );
  ArchivedRingRow copyWithCompanion(ArchivedRingsCompanion data) {
    return ArchivedRingRow(
      at: data.at.present ? data.at.value : this.at,
      packageId: data.packageId.present ? data.packageId.value : this.packageId,
      kind: data.kind.present ? data.kind.value : this.kind,
      label: data.label.present ? data.label.value : this.label,
      hour: data.hour.present ? data.hour.value : this.hour,
      minute: data.minute.present ? data.minute.value : this.minute,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ArchivedRingRow(')
          ..write('at: $at, ')
          ..write('packageId: $packageId, ')
          ..write('kind: $kind, ')
          ..write('label: $label, ')
          ..write('hour: $hour, ')
          ..write('minute: $minute')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(at, packageId, kind, label, hour, minute);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ArchivedRingRow &&
          other.at == this.at &&
          other.packageId == this.packageId &&
          other.kind == this.kind &&
          other.label == this.label &&
          other.hour == this.hour &&
          other.minute == this.minute);
}

class ArchivedRingsCompanion extends UpdateCompanion<ArchivedRingRow> {
  final Value<DateTime> at;
  final Value<int> packageId;
  final Value<RingLogKind> kind;
  final Value<String?> label;
  final Value<int?> hour;
  final Value<int?> minute;
  final Value<int> rowid;
  const ArchivedRingsCompanion({
    this.at = const Value.absent(),
    this.packageId = const Value.absent(),
    this.kind = const Value.absent(),
    this.label = const Value.absent(),
    this.hour = const Value.absent(),
    this.minute = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ArchivedRingsCompanion.insert({
    required DateTime at,
    required int packageId,
    required RingLogKind kind,
    this.label = const Value.absent(),
    this.hour = const Value.absent(),
    this.minute = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : at = Value(at),
       packageId = Value(packageId),
       kind = Value(kind);
  static Insertable<ArchivedRingRow> custom({
    Expression<DateTime>? at,
    Expression<int>? packageId,
    Expression<String>? kind,
    Expression<String>? label,
    Expression<int>? hour,
    Expression<int>? minute,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (at != null) 'at': at,
      if (packageId != null) 'package_id': packageId,
      if (kind != null) 'kind': kind,
      if (label != null) 'label': label,
      if (hour != null) 'hour': hour,
      if (minute != null) 'minute': minute,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ArchivedRingsCompanion copyWith({
    Value<DateTime>? at,
    Value<int>? packageId,
    Value<RingLogKind>? kind,
    Value<String?>? label,
    Value<int?>? hour,
    Value<int?>? minute,
    Value<int>? rowid,
  }) {
    return ArchivedRingsCompanion(
      at: at ?? this.at,
      packageId: packageId ?? this.packageId,
      kind: kind ?? this.kind,
      label: label ?? this.label,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (packageId.present) {
      map['package_id'] = Variable<int>(packageId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $ArchivedRingsTable.$converterkind.toSql(kind.value),
      );
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (hour.present) {
      map['hour'] = Variable<int>(hour.value);
    }
    if (minute.present) {
      map['minute'] = Variable<int>(minute.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ArchivedRingsCompanion(')
          ..write('at: $at, ')
          ..write('packageId: $packageId, ')
          ..write('kind: $kind, ')
          ..write('label: $label, ')
          ..write('hour: $hour, ')
          ..write('minute: $minute, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$RingArchiveDatabase extends GeneratedDatabase {
  _$RingArchiveDatabase(QueryExecutor e) : super(e);
  $RingArchiveDatabaseManager get managers => $RingArchiveDatabaseManager(this);
  late final $ArchivedRingsTable archivedRings = $ArchivedRingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [archivedRings];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$ArchivedRingsTableCreateCompanionBuilder =
    ArchivedRingsCompanion Function({
      required DateTime at,
      required int packageId,
      required RingLogKind kind,
      Value<String?> label,
      Value<int?> hour,
      Value<int?> minute,
      Value<int> rowid,
    });
typedef $$ArchivedRingsTableUpdateCompanionBuilder =
    ArchivedRingsCompanion Function({
      Value<DateTime> at,
      Value<int> packageId,
      Value<RingLogKind> kind,
      Value<String?> label,
      Value<int?> hour,
      Value<int?> minute,
      Value<int> rowid,
    });

class $$ArchivedRingsTableFilterComposer
    extends Composer<_$RingArchiveDatabase, $ArchivedRingsTable> {
  $$ArchivedRingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get packageId => $composableBuilder(
    column: $table.packageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<RingLogKind, RingLogKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hour => $composableBuilder(
    column: $table.hour,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minute => $composableBuilder(
    column: $table.minute,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ArchivedRingsTableOrderingComposer
    extends Composer<_$RingArchiveDatabase, $ArchivedRingsTable> {
  $$ArchivedRingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get packageId => $composableBuilder(
    column: $table.packageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hour => $composableBuilder(
    column: $table.hour,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minute => $composableBuilder(
    column: $table.minute,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ArchivedRingsTableAnnotationComposer
    extends Composer<_$RingArchiveDatabase, $ArchivedRingsTable> {
  $$ArchivedRingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<int> get packageId =>
      $composableBuilder(column: $table.packageId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<RingLogKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<int> get hour =>
      $composableBuilder(column: $table.hour, builder: (column) => column);

  GeneratedColumn<int> get minute =>
      $composableBuilder(column: $table.minute, builder: (column) => column);
}

class $$ArchivedRingsTableTableManager
    extends
        RootTableManager<
          _$RingArchiveDatabase,
          $ArchivedRingsTable,
          ArchivedRingRow,
          $$ArchivedRingsTableFilterComposer,
          $$ArchivedRingsTableOrderingComposer,
          $$ArchivedRingsTableAnnotationComposer,
          $$ArchivedRingsTableCreateCompanionBuilder,
          $$ArchivedRingsTableUpdateCompanionBuilder,
          (
            ArchivedRingRow,
            BaseReferences<
              _$RingArchiveDatabase,
              $ArchivedRingsTable,
              ArchivedRingRow
            >,
          ),
          ArchivedRingRow,
          PrefetchHooks Function()
        > {
  $$ArchivedRingsTableTableManager(
    _$RingArchiveDatabase db,
    $ArchivedRingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ArchivedRingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ArchivedRingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ArchivedRingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> at = const Value.absent(),
                Value<int> packageId = const Value.absent(),
                Value<RingLogKind> kind = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<int?> hour = const Value.absent(),
                Value<int?> minute = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ArchivedRingsCompanion(
                at: at,
                packageId: packageId,
                kind: kind,
                label: label,
                hour: hour,
                minute: minute,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required DateTime at,
                required int packageId,
                required RingLogKind kind,
                Value<String?> label = const Value.absent(),
                Value<int?> hour = const Value.absent(),
                Value<int?> minute = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ArchivedRingsCompanion.insert(
                at: at,
                packageId: packageId,
                kind: kind,
                label: label,
                hour: hour,
                minute: minute,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ArchivedRingsTableProcessedTableManager =
    ProcessedTableManager<
      _$RingArchiveDatabase,
      $ArchivedRingsTable,
      ArchivedRingRow,
      $$ArchivedRingsTableFilterComposer,
      $$ArchivedRingsTableOrderingComposer,
      $$ArchivedRingsTableAnnotationComposer,
      $$ArchivedRingsTableCreateCompanionBuilder,
      $$ArchivedRingsTableUpdateCompanionBuilder,
      (
        ArchivedRingRow,
        BaseReferences<
          _$RingArchiveDatabase,
          $ArchivedRingsTable,
          ArchivedRingRow
        >,
      ),
      ArchivedRingRow,
      PrefetchHooks Function()
    >;

class $RingArchiveDatabaseManager {
  final _$RingArchiveDatabase _db;
  $RingArchiveDatabaseManager(this._db);
  $$ArchivedRingsTableTableManager get archivedRings =>
      $$ArchivedRingsTableTableManager(_db, _db.archivedRings);
}
