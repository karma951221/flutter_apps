// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_database.dart';

// ignore_for_file: type=lint
class $ConversationsTable extends Conversations
    with TableInfo<$ConversationsTable, ConversationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConversationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleEditedMeta = const VerificationMeta(
    'titleEdited',
  );
  @override
  late final GeneratedColumn<bool> titleEdited = GeneratedColumn<bool>(
    'title_edited',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("title_edited" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    title,
    titleEdited,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'conversations';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConversationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('title_edited')) {
      context.handle(
        _titleEditedMeta,
        titleEdited.isAcceptableOrUnknown(
          data['title_edited']!,
          _titleEditedMeta,
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
  ConversationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConversationRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      titleEdited: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}title_edited'],
      )!,
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
  $ConversationsTable createAlias(String alias) {
    return $ConversationsTable(attachedDatabase, alias);
  }
}

class ConversationRow extends DataClass implements Insertable<ConversationRow> {
  final String id;
  final String title;
  final bool titleEdited;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ConversationRow({
    required this.id,
    required this.title,
    required this.titleEdited,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['title_edited'] = Variable<bool>(titleEdited);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ConversationsCompanion toCompanion(bool nullToAbsent) {
    return ConversationsCompanion(
      id: Value(id),
      title: Value(title),
      titleEdited: Value(titleEdited),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ConversationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConversationRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      titleEdited: serializer.fromJson<bool>(json['titleEdited']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'titleEdited': serializer.toJson<bool>(titleEdited),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ConversationRow copyWith({
    String? id,
    String? title,
    bool? titleEdited,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ConversationRow(
    id: id ?? this.id,
    title: title ?? this.title,
    titleEdited: titleEdited ?? this.titleEdited,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ConversationRow copyWithCompanion(ConversationsCompanion data) {
    return ConversationRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      titleEdited: data.titleEdited.present
          ? data.titleEdited.value
          : this.titleEdited,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConversationRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('titleEdited: $titleEdited, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, titleEdited, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConversationRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.titleEdited == this.titleEdited &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ConversationsCompanion extends UpdateCompanion<ConversationRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<bool> titleEdited;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ConversationsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.titleEdited = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConversationsCompanion.insert({
    required String id,
    required String title,
    this.titleEdited = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ConversationRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<bool>? titleEdited,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (titleEdited != null) 'title_edited': titleEdited,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConversationsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<bool>? titleEdited,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ConversationsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      titleEdited: titleEdited ?? this.titleEdited,
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
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (titleEdited.present) {
      map['title_edited'] = Variable<bool>(titleEdited.value);
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
    return (StringBuffer('ConversationsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('titleEdited: $titleEdited, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChatTurnsTable extends ChatTurns
    with TableInfo<$ChatTurnsTable, ChatTurnRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatTurnsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _conversationIdMeta = const VerificationMeta(
    'conversationId',
  );
  @override
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
    'conversation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES conversations (id) ON DELETE CASCADE',
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
  static const VerificationMeta _questionMeta = const VerificationMeta(
    'question',
  );
  @override
  late final GeneratedColumn<String> question = GeneratedColumn<String>(
    'question',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _answerMeta = const VerificationMeta('answer');
  @override
  late final GeneratedColumn<String> answer = GeneratedColumn<String>(
    'answer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String>
  citedEntryIds = GeneratedColumn<String>(
    'cited_entry_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<List<String>>($ChatTurnsTable.$convertercitedEntryIds);
  static const VerificationMeta _stoppedMeta = const VerificationMeta(
    'stopped',
  );
  @override
  late final GeneratedColumn<bool> stopped = GeneratedColumn<bool>(
    'stopped',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("stopped" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<ChatVendor, String> vendor =
      GeneratedColumn<String>(
        'vendor',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ChatVendor>($ChatTurnsTable.$convertervendor);
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _askedAtMeta = const VerificationMeta(
    'askedAt',
  );
  @override
  late final GeneratedColumn<DateTime> askedAt = GeneratedColumn<DateTime>(
    'asked_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    conversationId,
    seq,
    question,
    answer,
    citedEntryIds,
    stopped,
    vendor,
    model,
    askedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chat_turns';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChatTurnRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('conversation_id')) {
      context.handle(
        _conversationIdMeta,
        conversationId.isAcceptableOrUnknown(
          data['conversation_id']!,
          _conversationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    if (data.containsKey('question')) {
      context.handle(
        _questionMeta,
        question.isAcceptableOrUnknown(data['question']!, _questionMeta),
      );
    } else if (isInserting) {
      context.missing(_questionMeta);
    }
    if (data.containsKey('answer')) {
      context.handle(
        _answerMeta,
        answer.isAcceptableOrUnknown(data['answer']!, _answerMeta),
      );
    } else if (isInserting) {
      context.missing(_answerMeta);
    }
    if (data.containsKey('stopped')) {
      context.handle(
        _stoppedMeta,
        stopped.isAcceptableOrUnknown(data['stopped']!, _stoppedMeta),
      );
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    } else if (isInserting) {
      context.missing(_modelMeta);
    }
    if (data.containsKey('asked_at')) {
      context.handle(
        _askedAtMeta,
        askedAt.isAcceptableOrUnknown(data['asked_at']!, _askedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_askedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {conversationId, seq};
  @override
  ChatTurnRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChatTurnRow(
      conversationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conversation_id'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      question: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question'],
      )!,
      answer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answer'],
      )!,
      citedEntryIds: $ChatTurnsTable.$convertercitedEntryIds.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}cited_entry_ids'],
        )!,
      ),
      stopped: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}stopped'],
      )!,
      vendor: $ChatTurnsTable.$convertervendor.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}vendor'],
        )!,
      ),
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      )!,
      askedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}asked_at'],
      )!,
    );
  }

  @override
  $ChatTurnsTable createAlias(String alias) {
    return $ChatTurnsTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $convertercitedEntryIds =
      const StringListConverter();
  static JsonTypeConverter2<ChatVendor, String, String> $convertervendor =
      const EnumNameConverter<ChatVendor>(ChatVendor.values);
}

class ChatTurnRow extends DataClass implements Insertable<ChatTurnRow> {
  final String conversationId;
  final int seq;
  final String question;
  final String answer;
  final List<String> citedEntryIds;
  final bool stopped;
  final ChatVendor vendor;
  final String model;
  final DateTime askedAt;
  const ChatTurnRow({
    required this.conversationId,
    required this.seq,
    required this.question,
    required this.answer,
    required this.citedEntryIds,
    required this.stopped,
    required this.vendor,
    required this.model,
    required this.askedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['conversation_id'] = Variable<String>(conversationId);
    map['seq'] = Variable<int>(seq);
    map['question'] = Variable<String>(question);
    map['answer'] = Variable<String>(answer);
    {
      map['cited_entry_ids'] = Variable<String>(
        $ChatTurnsTable.$convertercitedEntryIds.toSql(citedEntryIds),
      );
    }
    map['stopped'] = Variable<bool>(stopped);
    {
      map['vendor'] = Variable<String>(
        $ChatTurnsTable.$convertervendor.toSql(vendor),
      );
    }
    map['model'] = Variable<String>(model);
    map['asked_at'] = Variable<DateTime>(askedAt);
    return map;
  }

  ChatTurnsCompanion toCompanion(bool nullToAbsent) {
    return ChatTurnsCompanion(
      conversationId: Value(conversationId),
      seq: Value(seq),
      question: Value(question),
      answer: Value(answer),
      citedEntryIds: Value(citedEntryIds),
      stopped: Value(stopped),
      vendor: Value(vendor),
      model: Value(model),
      askedAt: Value(askedAt),
    );
  }

  factory ChatTurnRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChatTurnRow(
      conversationId: serializer.fromJson<String>(json['conversationId']),
      seq: serializer.fromJson<int>(json['seq']),
      question: serializer.fromJson<String>(json['question']),
      answer: serializer.fromJson<String>(json['answer']),
      citedEntryIds: serializer.fromJson<List<String>>(json['citedEntryIds']),
      stopped: serializer.fromJson<bool>(json['stopped']),
      vendor: $ChatTurnsTable.$convertervendor.fromJson(
        serializer.fromJson<String>(json['vendor']),
      ),
      model: serializer.fromJson<String>(json['model']),
      askedAt: serializer.fromJson<DateTime>(json['askedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'conversationId': serializer.toJson<String>(conversationId),
      'seq': serializer.toJson<int>(seq),
      'question': serializer.toJson<String>(question),
      'answer': serializer.toJson<String>(answer),
      'citedEntryIds': serializer.toJson<List<String>>(citedEntryIds),
      'stopped': serializer.toJson<bool>(stopped),
      'vendor': serializer.toJson<String>(
        $ChatTurnsTable.$convertervendor.toJson(vendor),
      ),
      'model': serializer.toJson<String>(model),
      'askedAt': serializer.toJson<DateTime>(askedAt),
    };
  }

  ChatTurnRow copyWith({
    String? conversationId,
    int? seq,
    String? question,
    String? answer,
    List<String>? citedEntryIds,
    bool? stopped,
    ChatVendor? vendor,
    String? model,
    DateTime? askedAt,
  }) => ChatTurnRow(
    conversationId: conversationId ?? this.conversationId,
    seq: seq ?? this.seq,
    question: question ?? this.question,
    answer: answer ?? this.answer,
    citedEntryIds: citedEntryIds ?? this.citedEntryIds,
    stopped: stopped ?? this.stopped,
    vendor: vendor ?? this.vendor,
    model: model ?? this.model,
    askedAt: askedAt ?? this.askedAt,
  );
  ChatTurnRow copyWithCompanion(ChatTurnsCompanion data) {
    return ChatTurnRow(
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      seq: data.seq.present ? data.seq.value : this.seq,
      question: data.question.present ? data.question.value : this.question,
      answer: data.answer.present ? data.answer.value : this.answer,
      citedEntryIds: data.citedEntryIds.present
          ? data.citedEntryIds.value
          : this.citedEntryIds,
      stopped: data.stopped.present ? data.stopped.value : this.stopped,
      vendor: data.vendor.present ? data.vendor.value : this.vendor,
      model: data.model.present ? data.model.value : this.model,
      askedAt: data.askedAt.present ? data.askedAt.value : this.askedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChatTurnRow(')
          ..write('conversationId: $conversationId, ')
          ..write('seq: $seq, ')
          ..write('question: $question, ')
          ..write('answer: $answer, ')
          ..write('citedEntryIds: $citedEntryIds, ')
          ..write('stopped: $stopped, ')
          ..write('vendor: $vendor, ')
          ..write('model: $model, ')
          ..write('askedAt: $askedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    conversationId,
    seq,
    question,
    answer,
    citedEntryIds,
    stopped,
    vendor,
    model,
    askedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatTurnRow &&
          other.conversationId == this.conversationId &&
          other.seq == this.seq &&
          other.question == this.question &&
          other.answer == this.answer &&
          other.citedEntryIds == this.citedEntryIds &&
          other.stopped == this.stopped &&
          other.vendor == this.vendor &&
          other.model == this.model &&
          other.askedAt == this.askedAt);
}

class ChatTurnsCompanion extends UpdateCompanion<ChatTurnRow> {
  final Value<String> conversationId;
  final Value<int> seq;
  final Value<String> question;
  final Value<String> answer;
  final Value<List<String>> citedEntryIds;
  final Value<bool> stopped;
  final Value<ChatVendor> vendor;
  final Value<String> model;
  final Value<DateTime> askedAt;
  final Value<int> rowid;
  const ChatTurnsCompanion({
    this.conversationId = const Value.absent(),
    this.seq = const Value.absent(),
    this.question = const Value.absent(),
    this.answer = const Value.absent(),
    this.citedEntryIds = const Value.absent(),
    this.stopped = const Value.absent(),
    this.vendor = const Value.absent(),
    this.model = const Value.absent(),
    this.askedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChatTurnsCompanion.insert({
    required String conversationId,
    required int seq,
    required String question,
    required String answer,
    required List<String> citedEntryIds,
    this.stopped = const Value.absent(),
    required ChatVendor vendor,
    required String model,
    required DateTime askedAt,
    this.rowid = const Value.absent(),
  }) : conversationId = Value(conversationId),
       seq = Value(seq),
       question = Value(question),
       answer = Value(answer),
       citedEntryIds = Value(citedEntryIds),
       vendor = Value(vendor),
       model = Value(model),
       askedAt = Value(askedAt);
  static Insertable<ChatTurnRow> custom({
    Expression<String>? conversationId,
    Expression<int>? seq,
    Expression<String>? question,
    Expression<String>? answer,
    Expression<String>? citedEntryIds,
    Expression<bool>? stopped,
    Expression<String>? vendor,
    Expression<String>? model,
    Expression<DateTime>? askedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (conversationId != null) 'conversation_id': conversationId,
      if (seq != null) 'seq': seq,
      if (question != null) 'question': question,
      if (answer != null) 'answer': answer,
      if (citedEntryIds != null) 'cited_entry_ids': citedEntryIds,
      if (stopped != null) 'stopped': stopped,
      if (vendor != null) 'vendor': vendor,
      if (model != null) 'model': model,
      if (askedAt != null) 'asked_at': askedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChatTurnsCompanion copyWith({
    Value<String>? conversationId,
    Value<int>? seq,
    Value<String>? question,
    Value<String>? answer,
    Value<List<String>>? citedEntryIds,
    Value<bool>? stopped,
    Value<ChatVendor>? vendor,
    Value<String>? model,
    Value<DateTime>? askedAt,
    Value<int>? rowid,
  }) {
    return ChatTurnsCompanion(
      conversationId: conversationId ?? this.conversationId,
      seq: seq ?? this.seq,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      citedEntryIds: citedEntryIds ?? this.citedEntryIds,
      stopped: stopped ?? this.stopped,
      vendor: vendor ?? this.vendor,
      model: model ?? this.model,
      askedAt: askedAt ?? this.askedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (question.present) {
      map['question'] = Variable<String>(question.value);
    }
    if (answer.present) {
      map['answer'] = Variable<String>(answer.value);
    }
    if (citedEntryIds.present) {
      map['cited_entry_ids'] = Variable<String>(
        $ChatTurnsTable.$convertercitedEntryIds.toSql(citedEntryIds.value),
      );
    }
    if (stopped.present) {
      map['stopped'] = Variable<bool>(stopped.value);
    }
    if (vendor.present) {
      map['vendor'] = Variable<String>(
        $ChatTurnsTable.$convertervendor.toSql(vendor.value),
      );
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (askedAt.present) {
      map['asked_at'] = Variable<DateTime>(askedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatTurnsCompanion(')
          ..write('conversationId: $conversationId, ')
          ..write('seq: $seq, ')
          ..write('question: $question, ')
          ..write('answer: $answer, ')
          ..write('citedEntryIds: $citedEntryIds, ')
          ..write('stopped: $stopped, ')
          ..write('vendor: $vendor, ')
          ..write('model: $model, ')
          ..write('askedAt: $askedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChatUsageRowsTable extends ChatUsageRows
    with TableInfo<$ChatUsageRowsTable, ChatUsageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatUsageRowsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _questionKeyMeta = const VerificationMeta(
    'questionKey',
  );
  @override
  late final GeneratedColumn<String> questionKey = GeneratedColumn<String>(
    'question_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ChatVendor, String> vendor =
      GeneratedColumn<String>(
        'vendor',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ChatVendor>($ChatUsageRowsTable.$convertervendor);
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fastModeMeta = const VerificationMeta(
    'fastMode',
  );
  @override
  late final GeneratedColumn<bool> fastMode = GeneratedColumn<bool>(
    'fast_mode',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("fast_mode" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<ChatUsagePurpose, String>
  purpose = GeneratedColumn<String>(
    'purpose',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<ChatUsagePurpose>($ChatUsageRowsTable.$converterpurpose);
  static const VerificationMeta _roundMeta = const VerificationMeta('round');
  @override
  late final GeneratedColumn<int> round = GeneratedColumn<int>(
    'round',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _temporaryMeta = const VerificationMeta(
    'temporary',
  );
  @override
  late final GeneratedColumn<bool> temporary = GeneratedColumn<bool>(
    'temporary',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("temporary" IN (0, 1))',
    ),
  );
  static const VerificationMeta _inputTokensMeta = const VerificationMeta(
    'inputTokens',
  );
  @override
  late final GeneratedColumn<int> inputTokens = GeneratedColumn<int>(
    'input_tokens',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _outputTokensMeta = const VerificationMeta(
    'outputTokens',
  );
  @override
  late final GeneratedColumn<int> outputTokens = GeneratedColumn<int>(
    'output_tokens',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cacheReadTokensMeta = const VerificationMeta(
    'cacheReadTokens',
  );
  @override
  late final GeneratedColumn<int> cacheReadTokens = GeneratedColumn<int>(
    'cache_read_tokens',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cacheWriteTokensMeta = const VerificationMeta(
    'cacheWriteTokens',
  );
  @override
  late final GeneratedColumn<int> cacheWriteTokens = GeneratedColumn<int>(
    'cache_write_tokens',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasoningTokensMeta = const VerificationMeta(
    'reasoningTokens',
  );
  @override
  late final GeneratedColumn<int> reasoningTokens = GeneratedColumn<int>(
    'reasoning_tokens',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wikiIndexNotesMeta = const VerificationMeta(
    'wikiIndexNotes',
  );
  @override
  late final GeneratedColumn<int> wikiIndexNotes = GeneratedColumn<int>(
    'wiki_index_notes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _wikiIndexCharsMeta = const VerificationMeta(
    'wikiIndexChars',
  );
  @override
  late final GeneratedColumn<int> wikiIndexChars = GeneratedColumn<int>(
    'wiki_index_chars',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _readWikiCallsMeta = const VerificationMeta(
    'readWikiCalls',
  );
  @override
  late final GeneratedColumn<int> readWikiCalls = GeneratedColumn<int>(
    'read_wiki_calls',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    at,
    questionKey,
    vendor,
    model,
    fastMode,
    purpose,
    round,
    temporary,
    inputTokens,
    outputTokens,
    cacheReadTokens,
    cacheWriteTokens,
    reasoningTokens,
    wikiIndexNotes,
    wikiIndexChars,
    readWikiCalls,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chat_usage';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChatUsageRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('question_key')) {
      context.handle(
        _questionKeyMeta,
        questionKey.isAcceptableOrUnknown(
          data['question_key']!,
          _questionKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_questionKeyMeta);
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    } else if (isInserting) {
      context.missing(_modelMeta);
    }
    if (data.containsKey('fast_mode')) {
      context.handle(
        _fastModeMeta,
        fastMode.isAcceptableOrUnknown(data['fast_mode']!, _fastModeMeta),
      );
    }
    if (data.containsKey('round')) {
      context.handle(
        _roundMeta,
        round.isAcceptableOrUnknown(data['round']!, _roundMeta),
      );
    } else if (isInserting) {
      context.missing(_roundMeta);
    }
    if (data.containsKey('temporary')) {
      context.handle(
        _temporaryMeta,
        temporary.isAcceptableOrUnknown(data['temporary']!, _temporaryMeta),
      );
    } else if (isInserting) {
      context.missing(_temporaryMeta);
    }
    if (data.containsKey('input_tokens')) {
      context.handle(
        _inputTokensMeta,
        inputTokens.isAcceptableOrUnknown(
          data['input_tokens']!,
          _inputTokensMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_inputTokensMeta);
    }
    if (data.containsKey('output_tokens')) {
      context.handle(
        _outputTokensMeta,
        outputTokens.isAcceptableOrUnknown(
          data['output_tokens']!,
          _outputTokensMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_outputTokensMeta);
    }
    if (data.containsKey('cache_read_tokens')) {
      context.handle(
        _cacheReadTokensMeta,
        cacheReadTokens.isAcceptableOrUnknown(
          data['cache_read_tokens']!,
          _cacheReadTokensMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cacheReadTokensMeta);
    }
    if (data.containsKey('cache_write_tokens')) {
      context.handle(
        _cacheWriteTokensMeta,
        cacheWriteTokens.isAcceptableOrUnknown(
          data['cache_write_tokens']!,
          _cacheWriteTokensMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cacheWriteTokensMeta);
    }
    if (data.containsKey('reasoning_tokens')) {
      context.handle(
        _reasoningTokensMeta,
        reasoningTokens.isAcceptableOrUnknown(
          data['reasoning_tokens']!,
          _reasoningTokensMeta,
        ),
      );
    }
    if (data.containsKey('wiki_index_notes')) {
      context.handle(
        _wikiIndexNotesMeta,
        wikiIndexNotes.isAcceptableOrUnknown(
          data['wiki_index_notes']!,
          _wikiIndexNotesMeta,
        ),
      );
    }
    if (data.containsKey('wiki_index_chars')) {
      context.handle(
        _wikiIndexCharsMeta,
        wikiIndexChars.isAcceptableOrUnknown(
          data['wiki_index_chars']!,
          _wikiIndexCharsMeta,
        ),
      );
    }
    if (data.containsKey('read_wiki_calls')) {
      context.handle(
        _readWikiCallsMeta,
        readWikiCalls.isAcceptableOrUnknown(
          data['read_wiki_calls']!,
          _readWikiCallsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChatUsageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChatUsageRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
      questionKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_key'],
      )!,
      vendor: $ChatUsageRowsTable.$convertervendor.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}vendor'],
        )!,
      ),
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      )!,
      fastMode: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}fast_mode'],
      )!,
      purpose: $ChatUsageRowsTable.$converterpurpose.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}purpose'],
        )!,
      ),
      round: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}round'],
      )!,
      temporary: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}temporary'],
      )!,
      inputTokens: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}input_tokens'],
      )!,
      outputTokens: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}output_tokens'],
      )!,
      cacheReadTokens: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cache_read_tokens'],
      )!,
      cacheWriteTokens: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cache_write_tokens'],
      )!,
      reasoningTokens: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reasoning_tokens'],
      ),
      wikiIndexNotes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wiki_index_notes'],
      )!,
      wikiIndexChars: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wiki_index_chars'],
      )!,
      readWikiCalls: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}read_wiki_calls'],
      )!,
    );
  }

  @override
  $ChatUsageRowsTable createAlias(String alias) {
    return $ChatUsageRowsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ChatVendor, String, String> $convertervendor =
      const EnumNameConverter<ChatVendor>(ChatVendor.values);
  static JsonTypeConverter2<ChatUsagePurpose, String, String>
  $converterpurpose = const EnumNameConverter<ChatUsagePurpose>(
    ChatUsagePurpose.values,
  );
}

class ChatUsageRow extends DataClass implements Insertable<ChatUsageRow> {
  final int id;
  final DateTime at;
  final String questionKey;
  final ChatVendor vendor;
  final String model;
  final bool fastMode;
  final ChatUsagePurpose purpose;
  final int round;
  final bool temporary;
  final int inputTokens;
  final int outputTokens;
  final int cacheReadTokens;
  final int cacheWriteTokens;
  final int? reasoningTokens;
  final int wikiIndexNotes;
  final int wikiIndexChars;
  final int readWikiCalls;
  const ChatUsageRow({
    required this.id,
    required this.at,
    required this.questionKey,
    required this.vendor,
    required this.model,
    required this.fastMode,
    required this.purpose,
    required this.round,
    required this.temporary,
    required this.inputTokens,
    required this.outputTokens,
    required this.cacheReadTokens,
    required this.cacheWriteTokens,
    this.reasoningTokens,
    required this.wikiIndexNotes,
    required this.wikiIndexChars,
    required this.readWikiCalls,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['at'] = Variable<DateTime>(at);
    map['question_key'] = Variable<String>(questionKey);
    {
      map['vendor'] = Variable<String>(
        $ChatUsageRowsTable.$convertervendor.toSql(vendor),
      );
    }
    map['model'] = Variable<String>(model);
    map['fast_mode'] = Variable<bool>(fastMode);
    {
      map['purpose'] = Variable<String>(
        $ChatUsageRowsTable.$converterpurpose.toSql(purpose),
      );
    }
    map['round'] = Variable<int>(round);
    map['temporary'] = Variable<bool>(temporary);
    map['input_tokens'] = Variable<int>(inputTokens);
    map['output_tokens'] = Variable<int>(outputTokens);
    map['cache_read_tokens'] = Variable<int>(cacheReadTokens);
    map['cache_write_tokens'] = Variable<int>(cacheWriteTokens);
    if (!nullToAbsent || reasoningTokens != null) {
      map['reasoning_tokens'] = Variable<int>(reasoningTokens);
    }
    map['wiki_index_notes'] = Variable<int>(wikiIndexNotes);
    map['wiki_index_chars'] = Variable<int>(wikiIndexChars);
    map['read_wiki_calls'] = Variable<int>(readWikiCalls);
    return map;
  }

  ChatUsageRowsCompanion toCompanion(bool nullToAbsent) {
    return ChatUsageRowsCompanion(
      id: Value(id),
      at: Value(at),
      questionKey: Value(questionKey),
      vendor: Value(vendor),
      model: Value(model),
      fastMode: Value(fastMode),
      purpose: Value(purpose),
      round: Value(round),
      temporary: Value(temporary),
      inputTokens: Value(inputTokens),
      outputTokens: Value(outputTokens),
      cacheReadTokens: Value(cacheReadTokens),
      cacheWriteTokens: Value(cacheWriteTokens),
      reasoningTokens: reasoningTokens == null && nullToAbsent
          ? const Value.absent()
          : Value(reasoningTokens),
      wikiIndexNotes: Value(wikiIndexNotes),
      wikiIndexChars: Value(wikiIndexChars),
      readWikiCalls: Value(readWikiCalls),
    );
  }

  factory ChatUsageRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChatUsageRow(
      id: serializer.fromJson<int>(json['id']),
      at: serializer.fromJson<DateTime>(json['at']),
      questionKey: serializer.fromJson<String>(json['questionKey']),
      vendor: $ChatUsageRowsTable.$convertervendor.fromJson(
        serializer.fromJson<String>(json['vendor']),
      ),
      model: serializer.fromJson<String>(json['model']),
      fastMode: serializer.fromJson<bool>(json['fastMode']),
      purpose: $ChatUsageRowsTable.$converterpurpose.fromJson(
        serializer.fromJson<String>(json['purpose']),
      ),
      round: serializer.fromJson<int>(json['round']),
      temporary: serializer.fromJson<bool>(json['temporary']),
      inputTokens: serializer.fromJson<int>(json['inputTokens']),
      outputTokens: serializer.fromJson<int>(json['outputTokens']),
      cacheReadTokens: serializer.fromJson<int>(json['cacheReadTokens']),
      cacheWriteTokens: serializer.fromJson<int>(json['cacheWriteTokens']),
      reasoningTokens: serializer.fromJson<int?>(json['reasoningTokens']),
      wikiIndexNotes: serializer.fromJson<int>(json['wikiIndexNotes']),
      wikiIndexChars: serializer.fromJson<int>(json['wikiIndexChars']),
      readWikiCalls: serializer.fromJson<int>(json['readWikiCalls']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'at': serializer.toJson<DateTime>(at),
      'questionKey': serializer.toJson<String>(questionKey),
      'vendor': serializer.toJson<String>(
        $ChatUsageRowsTable.$convertervendor.toJson(vendor),
      ),
      'model': serializer.toJson<String>(model),
      'fastMode': serializer.toJson<bool>(fastMode),
      'purpose': serializer.toJson<String>(
        $ChatUsageRowsTable.$converterpurpose.toJson(purpose),
      ),
      'round': serializer.toJson<int>(round),
      'temporary': serializer.toJson<bool>(temporary),
      'inputTokens': serializer.toJson<int>(inputTokens),
      'outputTokens': serializer.toJson<int>(outputTokens),
      'cacheReadTokens': serializer.toJson<int>(cacheReadTokens),
      'cacheWriteTokens': serializer.toJson<int>(cacheWriteTokens),
      'reasoningTokens': serializer.toJson<int?>(reasoningTokens),
      'wikiIndexNotes': serializer.toJson<int>(wikiIndexNotes),
      'wikiIndexChars': serializer.toJson<int>(wikiIndexChars),
      'readWikiCalls': serializer.toJson<int>(readWikiCalls),
    };
  }

  ChatUsageRow copyWith({
    int? id,
    DateTime? at,
    String? questionKey,
    ChatVendor? vendor,
    String? model,
    bool? fastMode,
    ChatUsagePurpose? purpose,
    int? round,
    bool? temporary,
    int? inputTokens,
    int? outputTokens,
    int? cacheReadTokens,
    int? cacheWriteTokens,
    Value<int?> reasoningTokens = const Value.absent(),
    int? wikiIndexNotes,
    int? wikiIndexChars,
    int? readWikiCalls,
  }) => ChatUsageRow(
    id: id ?? this.id,
    at: at ?? this.at,
    questionKey: questionKey ?? this.questionKey,
    vendor: vendor ?? this.vendor,
    model: model ?? this.model,
    fastMode: fastMode ?? this.fastMode,
    purpose: purpose ?? this.purpose,
    round: round ?? this.round,
    temporary: temporary ?? this.temporary,
    inputTokens: inputTokens ?? this.inputTokens,
    outputTokens: outputTokens ?? this.outputTokens,
    cacheReadTokens: cacheReadTokens ?? this.cacheReadTokens,
    cacheWriteTokens: cacheWriteTokens ?? this.cacheWriteTokens,
    reasoningTokens: reasoningTokens.present
        ? reasoningTokens.value
        : this.reasoningTokens,
    wikiIndexNotes: wikiIndexNotes ?? this.wikiIndexNotes,
    wikiIndexChars: wikiIndexChars ?? this.wikiIndexChars,
    readWikiCalls: readWikiCalls ?? this.readWikiCalls,
  );
  ChatUsageRow copyWithCompanion(ChatUsageRowsCompanion data) {
    return ChatUsageRow(
      id: data.id.present ? data.id.value : this.id,
      at: data.at.present ? data.at.value : this.at,
      questionKey: data.questionKey.present
          ? data.questionKey.value
          : this.questionKey,
      vendor: data.vendor.present ? data.vendor.value : this.vendor,
      model: data.model.present ? data.model.value : this.model,
      fastMode: data.fastMode.present ? data.fastMode.value : this.fastMode,
      purpose: data.purpose.present ? data.purpose.value : this.purpose,
      round: data.round.present ? data.round.value : this.round,
      temporary: data.temporary.present ? data.temporary.value : this.temporary,
      inputTokens: data.inputTokens.present
          ? data.inputTokens.value
          : this.inputTokens,
      outputTokens: data.outputTokens.present
          ? data.outputTokens.value
          : this.outputTokens,
      cacheReadTokens: data.cacheReadTokens.present
          ? data.cacheReadTokens.value
          : this.cacheReadTokens,
      cacheWriteTokens: data.cacheWriteTokens.present
          ? data.cacheWriteTokens.value
          : this.cacheWriteTokens,
      reasoningTokens: data.reasoningTokens.present
          ? data.reasoningTokens.value
          : this.reasoningTokens,
      wikiIndexNotes: data.wikiIndexNotes.present
          ? data.wikiIndexNotes.value
          : this.wikiIndexNotes,
      wikiIndexChars: data.wikiIndexChars.present
          ? data.wikiIndexChars.value
          : this.wikiIndexChars,
      readWikiCalls: data.readWikiCalls.present
          ? data.readWikiCalls.value
          : this.readWikiCalls,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChatUsageRow(')
          ..write('id: $id, ')
          ..write('at: $at, ')
          ..write('questionKey: $questionKey, ')
          ..write('vendor: $vendor, ')
          ..write('model: $model, ')
          ..write('fastMode: $fastMode, ')
          ..write('purpose: $purpose, ')
          ..write('round: $round, ')
          ..write('temporary: $temporary, ')
          ..write('inputTokens: $inputTokens, ')
          ..write('outputTokens: $outputTokens, ')
          ..write('cacheReadTokens: $cacheReadTokens, ')
          ..write('cacheWriteTokens: $cacheWriteTokens, ')
          ..write('reasoningTokens: $reasoningTokens, ')
          ..write('wikiIndexNotes: $wikiIndexNotes, ')
          ..write('wikiIndexChars: $wikiIndexChars, ')
          ..write('readWikiCalls: $readWikiCalls')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    at,
    questionKey,
    vendor,
    model,
    fastMode,
    purpose,
    round,
    temporary,
    inputTokens,
    outputTokens,
    cacheReadTokens,
    cacheWriteTokens,
    reasoningTokens,
    wikiIndexNotes,
    wikiIndexChars,
    readWikiCalls,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatUsageRow &&
          other.id == this.id &&
          other.at == this.at &&
          other.questionKey == this.questionKey &&
          other.vendor == this.vendor &&
          other.model == this.model &&
          other.fastMode == this.fastMode &&
          other.purpose == this.purpose &&
          other.round == this.round &&
          other.temporary == this.temporary &&
          other.inputTokens == this.inputTokens &&
          other.outputTokens == this.outputTokens &&
          other.cacheReadTokens == this.cacheReadTokens &&
          other.cacheWriteTokens == this.cacheWriteTokens &&
          other.reasoningTokens == this.reasoningTokens &&
          other.wikiIndexNotes == this.wikiIndexNotes &&
          other.wikiIndexChars == this.wikiIndexChars &&
          other.readWikiCalls == this.readWikiCalls);
}

class ChatUsageRowsCompanion extends UpdateCompanion<ChatUsageRow> {
  final Value<int> id;
  final Value<DateTime> at;
  final Value<String> questionKey;
  final Value<ChatVendor> vendor;
  final Value<String> model;
  final Value<bool> fastMode;
  final Value<ChatUsagePurpose> purpose;
  final Value<int> round;
  final Value<bool> temporary;
  final Value<int> inputTokens;
  final Value<int> outputTokens;
  final Value<int> cacheReadTokens;
  final Value<int> cacheWriteTokens;
  final Value<int?> reasoningTokens;
  final Value<int> wikiIndexNotes;
  final Value<int> wikiIndexChars;
  final Value<int> readWikiCalls;
  const ChatUsageRowsCompanion({
    this.id = const Value.absent(),
    this.at = const Value.absent(),
    this.questionKey = const Value.absent(),
    this.vendor = const Value.absent(),
    this.model = const Value.absent(),
    this.fastMode = const Value.absent(),
    this.purpose = const Value.absent(),
    this.round = const Value.absent(),
    this.temporary = const Value.absent(),
    this.inputTokens = const Value.absent(),
    this.outputTokens = const Value.absent(),
    this.cacheReadTokens = const Value.absent(),
    this.cacheWriteTokens = const Value.absent(),
    this.reasoningTokens = const Value.absent(),
    this.wikiIndexNotes = const Value.absent(),
    this.wikiIndexChars = const Value.absent(),
    this.readWikiCalls = const Value.absent(),
  });
  ChatUsageRowsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime at,
    required String questionKey,
    required ChatVendor vendor,
    required String model,
    this.fastMode = const Value.absent(),
    required ChatUsagePurpose purpose,
    required int round,
    required bool temporary,
    required int inputTokens,
    required int outputTokens,
    required int cacheReadTokens,
    required int cacheWriteTokens,
    this.reasoningTokens = const Value.absent(),
    this.wikiIndexNotes = const Value.absent(),
    this.wikiIndexChars = const Value.absent(),
    this.readWikiCalls = const Value.absent(),
  }) : at = Value(at),
       questionKey = Value(questionKey),
       vendor = Value(vendor),
       model = Value(model),
       purpose = Value(purpose),
       round = Value(round),
       temporary = Value(temporary),
       inputTokens = Value(inputTokens),
       outputTokens = Value(outputTokens),
       cacheReadTokens = Value(cacheReadTokens),
       cacheWriteTokens = Value(cacheWriteTokens);
  static Insertable<ChatUsageRow> custom({
    Expression<int>? id,
    Expression<DateTime>? at,
    Expression<String>? questionKey,
    Expression<String>? vendor,
    Expression<String>? model,
    Expression<bool>? fastMode,
    Expression<String>? purpose,
    Expression<int>? round,
    Expression<bool>? temporary,
    Expression<int>? inputTokens,
    Expression<int>? outputTokens,
    Expression<int>? cacheReadTokens,
    Expression<int>? cacheWriteTokens,
    Expression<int>? reasoningTokens,
    Expression<int>? wikiIndexNotes,
    Expression<int>? wikiIndexChars,
    Expression<int>? readWikiCalls,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (at != null) 'at': at,
      if (questionKey != null) 'question_key': questionKey,
      if (vendor != null) 'vendor': vendor,
      if (model != null) 'model': model,
      if (fastMode != null) 'fast_mode': fastMode,
      if (purpose != null) 'purpose': purpose,
      if (round != null) 'round': round,
      if (temporary != null) 'temporary': temporary,
      if (inputTokens != null) 'input_tokens': inputTokens,
      if (outputTokens != null) 'output_tokens': outputTokens,
      if (cacheReadTokens != null) 'cache_read_tokens': cacheReadTokens,
      if (cacheWriteTokens != null) 'cache_write_tokens': cacheWriteTokens,
      if (reasoningTokens != null) 'reasoning_tokens': reasoningTokens,
      if (wikiIndexNotes != null) 'wiki_index_notes': wikiIndexNotes,
      if (wikiIndexChars != null) 'wiki_index_chars': wikiIndexChars,
      if (readWikiCalls != null) 'read_wiki_calls': readWikiCalls,
    });
  }

  ChatUsageRowsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? at,
    Value<String>? questionKey,
    Value<ChatVendor>? vendor,
    Value<String>? model,
    Value<bool>? fastMode,
    Value<ChatUsagePurpose>? purpose,
    Value<int>? round,
    Value<bool>? temporary,
    Value<int>? inputTokens,
    Value<int>? outputTokens,
    Value<int>? cacheReadTokens,
    Value<int>? cacheWriteTokens,
    Value<int?>? reasoningTokens,
    Value<int>? wikiIndexNotes,
    Value<int>? wikiIndexChars,
    Value<int>? readWikiCalls,
  }) {
    return ChatUsageRowsCompanion(
      id: id ?? this.id,
      at: at ?? this.at,
      questionKey: questionKey ?? this.questionKey,
      vendor: vendor ?? this.vendor,
      model: model ?? this.model,
      fastMode: fastMode ?? this.fastMode,
      purpose: purpose ?? this.purpose,
      round: round ?? this.round,
      temporary: temporary ?? this.temporary,
      inputTokens: inputTokens ?? this.inputTokens,
      outputTokens: outputTokens ?? this.outputTokens,
      cacheReadTokens: cacheReadTokens ?? this.cacheReadTokens,
      cacheWriteTokens: cacheWriteTokens ?? this.cacheWriteTokens,
      reasoningTokens: reasoningTokens ?? this.reasoningTokens,
      wikiIndexNotes: wikiIndexNotes ?? this.wikiIndexNotes,
      wikiIndexChars: wikiIndexChars ?? this.wikiIndexChars,
      readWikiCalls: readWikiCalls ?? this.readWikiCalls,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (questionKey.present) {
      map['question_key'] = Variable<String>(questionKey.value);
    }
    if (vendor.present) {
      map['vendor'] = Variable<String>(
        $ChatUsageRowsTable.$convertervendor.toSql(vendor.value),
      );
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (fastMode.present) {
      map['fast_mode'] = Variable<bool>(fastMode.value);
    }
    if (purpose.present) {
      map['purpose'] = Variable<String>(
        $ChatUsageRowsTable.$converterpurpose.toSql(purpose.value),
      );
    }
    if (round.present) {
      map['round'] = Variable<int>(round.value);
    }
    if (temporary.present) {
      map['temporary'] = Variable<bool>(temporary.value);
    }
    if (inputTokens.present) {
      map['input_tokens'] = Variable<int>(inputTokens.value);
    }
    if (outputTokens.present) {
      map['output_tokens'] = Variable<int>(outputTokens.value);
    }
    if (cacheReadTokens.present) {
      map['cache_read_tokens'] = Variable<int>(cacheReadTokens.value);
    }
    if (cacheWriteTokens.present) {
      map['cache_write_tokens'] = Variable<int>(cacheWriteTokens.value);
    }
    if (reasoningTokens.present) {
      map['reasoning_tokens'] = Variable<int>(reasoningTokens.value);
    }
    if (wikiIndexNotes.present) {
      map['wiki_index_notes'] = Variable<int>(wikiIndexNotes.value);
    }
    if (wikiIndexChars.present) {
      map['wiki_index_chars'] = Variable<int>(wikiIndexChars.value);
    }
    if (readWikiCalls.present) {
      map['read_wiki_calls'] = Variable<int>(readWikiCalls.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatUsageRowsCompanion(')
          ..write('id: $id, ')
          ..write('at: $at, ')
          ..write('questionKey: $questionKey, ')
          ..write('vendor: $vendor, ')
          ..write('model: $model, ')
          ..write('fastMode: $fastMode, ')
          ..write('purpose: $purpose, ')
          ..write('round: $round, ')
          ..write('temporary: $temporary, ')
          ..write('inputTokens: $inputTokens, ')
          ..write('outputTokens: $outputTokens, ')
          ..write('cacheReadTokens: $cacheReadTokens, ')
          ..write('cacheWriteTokens: $cacheWriteTokens, ')
          ..write('reasoningTokens: $reasoningTokens, ')
          ..write('wikiIndexNotes: $wikiIndexNotes, ')
          ..write('wikiIndexChars: $wikiIndexChars, ')
          ..write('readWikiCalls: $readWikiCalls')
          ..write(')'))
        .toString();
  }
}

abstract class _$ChatDatabase extends GeneratedDatabase {
  _$ChatDatabase(QueryExecutor e) : super(e);
  $ChatDatabaseManager get managers => $ChatDatabaseManager(this);
  late final $ConversationsTable conversations = $ConversationsTable(this);
  late final $ChatTurnsTable chatTurns = $ChatTurnsTable(this);
  late final $ChatUsageRowsTable chatUsageRows = $ChatUsageRowsTable(this);
  late final Index chatUsageAt = Index(
    'chat_usage_at',
    'CREATE INDEX chat_usage_at ON chat_usage (at)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    conversations,
    chatTurns,
    chatUsageRows,
    chatUsageAt,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'conversations',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('chat_turns', kind: UpdateKind.delete)],
    ),
  ]);
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$ConversationsTableCreateCompanionBuilder =
    ConversationsCompanion Function({
      required String id,
      required String title,
      Value<bool> titleEdited,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ConversationsTableUpdateCompanionBuilder =
    ConversationsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<bool> titleEdited,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$ConversationsTableReferences
    extends
        BaseReferences<_$ChatDatabase, $ConversationsTable, ConversationRow> {
  $$ConversationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$ChatTurnsTable, List<ChatTurnRow>>
  _chatTurnsRefsTable(_$ChatDatabase db) => MultiTypedResultKey.fromTable(
    db.chatTurns,
    aliasName: 'conversations__id__chat_turns__conversation_id',
  );

  $$ChatTurnsTableProcessedTableManager get chatTurnsRefs {
    final manager = $$ChatTurnsTableTableManager(
      $_db,
      $_db.chatTurns,
    ).filter((f) => f.conversationId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_chatTurnsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ConversationsTableFilterComposer
    extends Composer<_$ChatDatabase, $ConversationsTable> {
  $$ConversationsTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get titleEdited => $composableBuilder(
    column: $table.titleEdited,
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

  Expression<bool> chatTurnsRefs(
    Expression<bool> Function($$ChatTurnsTableFilterComposer f) f,
  ) {
    final $$ChatTurnsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chatTurns,
      getReferencedColumn: (t) => t.conversationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChatTurnsTableFilterComposer(
            $db: $db,
            $table: $db.chatTurns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ConversationsTableOrderingComposer
    extends Composer<_$ChatDatabase, $ConversationsTable> {
  $$ConversationsTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get titleEdited => $composableBuilder(
    column: $table.titleEdited,
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

class $$ConversationsTableAnnotationComposer
    extends Composer<_$ChatDatabase, $ConversationsTable> {
  $$ConversationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<bool> get titleEdited => $composableBuilder(
    column: $table.titleEdited,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> chatTurnsRefs<T extends Object>(
    Expression<T> Function($$ChatTurnsTableAnnotationComposer a) f,
  ) {
    final $$ChatTurnsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chatTurns,
      getReferencedColumn: (t) => t.conversationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChatTurnsTableAnnotationComposer(
            $db: $db,
            $table: $db.chatTurns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ConversationsTableTableManager
    extends
        RootTableManager<
          _$ChatDatabase,
          $ConversationsTable,
          ConversationRow,
          $$ConversationsTableFilterComposer,
          $$ConversationsTableOrderingComposer,
          $$ConversationsTableAnnotationComposer,
          $$ConversationsTableCreateCompanionBuilder,
          $$ConversationsTableUpdateCompanionBuilder,
          (ConversationRow, $$ConversationsTableReferences),
          ConversationRow,
          PrefetchHooks Function({bool chatTurnsRefs})
        > {
  $$ConversationsTableTableManager(_$ChatDatabase db, $ConversationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConversationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConversationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConversationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<bool> titleEdited = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConversationsCompanion(
                id: id,
                title: title,
                titleEdited: titleEdited,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<bool> titleEdited = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ConversationsCompanion.insert(
                id: id,
                title: title,
                titleEdited: titleEdited,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ConversationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({chatTurnsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (chatTurnsRefs) db.chatTurns],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (chatTurnsRefs)
                    await $_getPrefetchedData<
                      ConversationRow,
                      $ConversationsTable,
                      ChatTurnRow
                    >(
                      currentTable: table,
                      referencedTable: $$ConversationsTableReferences
                          ._chatTurnsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ConversationsTableReferences(
                            db,
                            table,
                            p0,
                          ).chatTurnsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.conversationId == item.id,
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

typedef $$ConversationsTableProcessedTableManager =
    ProcessedTableManager<
      _$ChatDatabase,
      $ConversationsTable,
      ConversationRow,
      $$ConversationsTableFilterComposer,
      $$ConversationsTableOrderingComposer,
      $$ConversationsTableAnnotationComposer,
      $$ConversationsTableCreateCompanionBuilder,
      $$ConversationsTableUpdateCompanionBuilder,
      (ConversationRow, $$ConversationsTableReferences),
      ConversationRow,
      PrefetchHooks Function({bool chatTurnsRefs})
    >;
typedef $$ChatTurnsTableCreateCompanionBuilder =
    ChatTurnsCompanion Function({
      required String conversationId,
      required int seq,
      required String question,
      required String answer,
      required List<String> citedEntryIds,
      Value<bool> stopped,
      required ChatVendor vendor,
      required String model,
      required DateTime askedAt,
      Value<int> rowid,
    });
typedef $$ChatTurnsTableUpdateCompanionBuilder =
    ChatTurnsCompanion Function({
      Value<String> conversationId,
      Value<int> seq,
      Value<String> question,
      Value<String> answer,
      Value<List<String>> citedEntryIds,
      Value<bool> stopped,
      Value<ChatVendor> vendor,
      Value<String> model,
      Value<DateTime> askedAt,
      Value<int> rowid,
    });

final class $$ChatTurnsTableReferences
    extends BaseReferences<_$ChatDatabase, $ChatTurnsTable, ChatTurnRow> {
  $$ChatTurnsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ConversationsTable _conversationIdTable(_$ChatDatabase db) => db
      .conversations
      .createAlias('chat_turns__conversation_id__conversations__id');

  $$ConversationsTableProcessedTableManager get conversationId {
    final $_column = $_itemColumn<String>('conversation_id')!;

    final manager = $$ConversationsTableTableManager(
      $_db,
      $_db.conversations,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_conversationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ChatTurnsTableFilterComposer
    extends Composer<_$ChatDatabase, $ChatTurnsTable> {
  $$ChatTurnsTableFilterComposer({
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

  ColumnFilters<String> get question => $composableBuilder(
    column: $table.question,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get answer => $composableBuilder(
    column: $table.answer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get citedEntryIds => $composableBuilder(
    column: $table.citedEntryIds,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get stopped => $composableBuilder(
    column: $table.stopped,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ChatVendor, ChatVendor, String> get vendor =>
      $composableBuilder(
        column: $table.vendor,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get askedAt => $composableBuilder(
    column: $table.askedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ConversationsTableFilterComposer get conversationId {
    final $$ConversationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.conversationId,
      referencedTable: $db.conversations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConversationsTableFilterComposer(
            $db: $db,
            $table: $db.conversations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChatTurnsTableOrderingComposer
    extends Composer<_$ChatDatabase, $ChatTurnsTable> {
  $$ChatTurnsTableOrderingComposer({
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

  ColumnOrderings<String> get question => $composableBuilder(
    column: $table.question,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get answer => $composableBuilder(
    column: $table.answer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get citedEntryIds => $composableBuilder(
    column: $table.citedEntryIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get stopped => $composableBuilder(
    column: $table.stopped,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vendor => $composableBuilder(
    column: $table.vendor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get askedAt => $composableBuilder(
    column: $table.askedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ConversationsTableOrderingComposer get conversationId {
    final $$ConversationsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.conversationId,
      referencedTable: $db.conversations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConversationsTableOrderingComposer(
            $db: $db,
            $table: $db.conversations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChatTurnsTableAnnotationComposer
    extends Composer<_$ChatDatabase, $ChatTurnsTable> {
  $$ChatTurnsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get question =>
      $composableBuilder(column: $table.question, builder: (column) => column);

  GeneratedColumn<String> get answer =>
      $composableBuilder(column: $table.answer, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get citedEntryIds =>
      $composableBuilder(
        column: $table.citedEntryIds,
        builder: (column) => column,
      );

  GeneratedColumn<bool> get stopped =>
      $composableBuilder(column: $table.stopped, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ChatVendor, String> get vendor =>
      $composableBuilder(column: $table.vendor, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<DateTime> get askedAt =>
      $composableBuilder(column: $table.askedAt, builder: (column) => column);

  $$ConversationsTableAnnotationComposer get conversationId {
    final $$ConversationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.conversationId,
      referencedTable: $db.conversations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConversationsTableAnnotationComposer(
            $db: $db,
            $table: $db.conversations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChatTurnsTableTableManager
    extends
        RootTableManager<
          _$ChatDatabase,
          $ChatTurnsTable,
          ChatTurnRow,
          $$ChatTurnsTableFilterComposer,
          $$ChatTurnsTableOrderingComposer,
          $$ChatTurnsTableAnnotationComposer,
          $$ChatTurnsTableCreateCompanionBuilder,
          $$ChatTurnsTableUpdateCompanionBuilder,
          (ChatTurnRow, $$ChatTurnsTableReferences),
          ChatTurnRow,
          PrefetchHooks Function({bool conversationId})
        > {
  $$ChatTurnsTableTableManager(_$ChatDatabase db, $ChatTurnsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChatTurnsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChatTurnsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChatTurnsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> conversationId = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<String> question = const Value.absent(),
                Value<String> answer = const Value.absent(),
                Value<List<String>> citedEntryIds = const Value.absent(),
                Value<bool> stopped = const Value.absent(),
                Value<ChatVendor> vendor = const Value.absent(),
                Value<String> model = const Value.absent(),
                Value<DateTime> askedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChatTurnsCompanion(
                conversationId: conversationId,
                seq: seq,
                question: question,
                answer: answer,
                citedEntryIds: citedEntryIds,
                stopped: stopped,
                vendor: vendor,
                model: model,
                askedAt: askedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String conversationId,
                required int seq,
                required String question,
                required String answer,
                required List<String> citedEntryIds,
                Value<bool> stopped = const Value.absent(),
                required ChatVendor vendor,
                required String model,
                required DateTime askedAt,
                Value<int> rowid = const Value.absent(),
              }) => ChatTurnsCompanion.insert(
                conversationId: conversationId,
                seq: seq,
                question: question,
                answer: answer,
                citedEntryIds: citedEntryIds,
                stopped: stopped,
                vendor: vendor,
                model: model,
                askedAt: askedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ChatTurnsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({conversationId = false}) {
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
                    if (conversationId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.conversationId,
                                referencedTable: $$ChatTurnsTableReferences
                                    ._conversationIdTable(db),
                                referencedColumn: $$ChatTurnsTableReferences
                                    ._conversationIdTable(db)
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

typedef $$ChatTurnsTableProcessedTableManager =
    ProcessedTableManager<
      _$ChatDatabase,
      $ChatTurnsTable,
      ChatTurnRow,
      $$ChatTurnsTableFilterComposer,
      $$ChatTurnsTableOrderingComposer,
      $$ChatTurnsTableAnnotationComposer,
      $$ChatTurnsTableCreateCompanionBuilder,
      $$ChatTurnsTableUpdateCompanionBuilder,
      (ChatTurnRow, $$ChatTurnsTableReferences),
      ChatTurnRow,
      PrefetchHooks Function({bool conversationId})
    >;
typedef $$ChatUsageRowsTableCreateCompanionBuilder =
    ChatUsageRowsCompanion Function({
      Value<int> id,
      required DateTime at,
      required String questionKey,
      required ChatVendor vendor,
      required String model,
      Value<bool> fastMode,
      required ChatUsagePurpose purpose,
      required int round,
      required bool temporary,
      required int inputTokens,
      required int outputTokens,
      required int cacheReadTokens,
      required int cacheWriteTokens,
      Value<int?> reasoningTokens,
      Value<int> wikiIndexNotes,
      Value<int> wikiIndexChars,
      Value<int> readWikiCalls,
    });
typedef $$ChatUsageRowsTableUpdateCompanionBuilder =
    ChatUsageRowsCompanion Function({
      Value<int> id,
      Value<DateTime> at,
      Value<String> questionKey,
      Value<ChatVendor> vendor,
      Value<String> model,
      Value<bool> fastMode,
      Value<ChatUsagePurpose> purpose,
      Value<int> round,
      Value<bool> temporary,
      Value<int> inputTokens,
      Value<int> outputTokens,
      Value<int> cacheReadTokens,
      Value<int> cacheWriteTokens,
      Value<int?> reasoningTokens,
      Value<int> wikiIndexNotes,
      Value<int> wikiIndexChars,
      Value<int> readWikiCalls,
    });

class $$ChatUsageRowsTableFilterComposer
    extends Composer<_$ChatDatabase, $ChatUsageRowsTable> {
  $$ChatUsageRowsTableFilterComposer({
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

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get questionKey => $composableBuilder(
    column: $table.questionKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ChatVendor, ChatVendor, String> get vendor =>
      $composableBuilder(
        column: $table.vendor,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get fastMode => $composableBuilder(
    column: $table.fastMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ChatUsagePurpose, ChatUsagePurpose, String>
  get purpose => $composableBuilder(
    column: $table.purpose,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get round => $composableBuilder(
    column: $table.round,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get temporary => $composableBuilder(
    column: $table.temporary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get inputTokens => $composableBuilder(
    column: $table.inputTokens,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get outputTokens => $composableBuilder(
    column: $table.outputTokens,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cacheReadTokens => $composableBuilder(
    column: $table.cacheReadTokens,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cacheWriteTokens => $composableBuilder(
    column: $table.cacheWriteTokens,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reasoningTokens => $composableBuilder(
    column: $table.reasoningTokens,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wikiIndexNotes => $composableBuilder(
    column: $table.wikiIndexNotes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wikiIndexChars => $composableBuilder(
    column: $table.wikiIndexChars,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get readWikiCalls => $composableBuilder(
    column: $table.readWikiCalls,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChatUsageRowsTableOrderingComposer
    extends Composer<_$ChatDatabase, $ChatUsageRowsTable> {
  $$ChatUsageRowsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get questionKey => $composableBuilder(
    column: $table.questionKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vendor => $composableBuilder(
    column: $table.vendor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get fastMode => $composableBuilder(
    column: $table.fastMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get purpose => $composableBuilder(
    column: $table.purpose,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get round => $composableBuilder(
    column: $table.round,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get temporary => $composableBuilder(
    column: $table.temporary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get inputTokens => $composableBuilder(
    column: $table.inputTokens,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get outputTokens => $composableBuilder(
    column: $table.outputTokens,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cacheReadTokens => $composableBuilder(
    column: $table.cacheReadTokens,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cacheWriteTokens => $composableBuilder(
    column: $table.cacheWriteTokens,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reasoningTokens => $composableBuilder(
    column: $table.reasoningTokens,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wikiIndexNotes => $composableBuilder(
    column: $table.wikiIndexNotes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wikiIndexChars => $composableBuilder(
    column: $table.wikiIndexChars,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get readWikiCalls => $composableBuilder(
    column: $table.readWikiCalls,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChatUsageRowsTableAnnotationComposer
    extends Composer<_$ChatDatabase, $ChatUsageRowsTable> {
  $$ChatUsageRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<String> get questionKey => $composableBuilder(
    column: $table.questionKey,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ChatVendor, String> get vendor =>
      $composableBuilder(column: $table.vendor, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<bool> get fastMode =>
      $composableBuilder(column: $table.fastMode, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ChatUsagePurpose, String> get purpose =>
      $composableBuilder(column: $table.purpose, builder: (column) => column);

  GeneratedColumn<int> get round =>
      $composableBuilder(column: $table.round, builder: (column) => column);

  GeneratedColumn<bool> get temporary =>
      $composableBuilder(column: $table.temporary, builder: (column) => column);

  GeneratedColumn<int> get inputTokens => $composableBuilder(
    column: $table.inputTokens,
    builder: (column) => column,
  );

  GeneratedColumn<int> get outputTokens => $composableBuilder(
    column: $table.outputTokens,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cacheReadTokens => $composableBuilder(
    column: $table.cacheReadTokens,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cacheWriteTokens => $composableBuilder(
    column: $table.cacheWriteTokens,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reasoningTokens => $composableBuilder(
    column: $table.reasoningTokens,
    builder: (column) => column,
  );

  GeneratedColumn<int> get wikiIndexNotes => $composableBuilder(
    column: $table.wikiIndexNotes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get wikiIndexChars => $composableBuilder(
    column: $table.wikiIndexChars,
    builder: (column) => column,
  );

  GeneratedColumn<int> get readWikiCalls => $composableBuilder(
    column: $table.readWikiCalls,
    builder: (column) => column,
  );
}

class $$ChatUsageRowsTableTableManager
    extends
        RootTableManager<
          _$ChatDatabase,
          $ChatUsageRowsTable,
          ChatUsageRow,
          $$ChatUsageRowsTableFilterComposer,
          $$ChatUsageRowsTableOrderingComposer,
          $$ChatUsageRowsTableAnnotationComposer,
          $$ChatUsageRowsTableCreateCompanionBuilder,
          $$ChatUsageRowsTableUpdateCompanionBuilder,
          (
            ChatUsageRow,
            BaseReferences<_$ChatDatabase, $ChatUsageRowsTable, ChatUsageRow>,
          ),
          ChatUsageRow,
          PrefetchHooks Function()
        > {
  $$ChatUsageRowsTableTableManager(_$ChatDatabase db, $ChatUsageRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChatUsageRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChatUsageRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChatUsageRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<String> questionKey = const Value.absent(),
                Value<ChatVendor> vendor = const Value.absent(),
                Value<String> model = const Value.absent(),
                Value<bool> fastMode = const Value.absent(),
                Value<ChatUsagePurpose> purpose = const Value.absent(),
                Value<int> round = const Value.absent(),
                Value<bool> temporary = const Value.absent(),
                Value<int> inputTokens = const Value.absent(),
                Value<int> outputTokens = const Value.absent(),
                Value<int> cacheReadTokens = const Value.absent(),
                Value<int> cacheWriteTokens = const Value.absent(),
                Value<int?> reasoningTokens = const Value.absent(),
                Value<int> wikiIndexNotes = const Value.absent(),
                Value<int> wikiIndexChars = const Value.absent(),
                Value<int> readWikiCalls = const Value.absent(),
              }) => ChatUsageRowsCompanion(
                id: id,
                at: at,
                questionKey: questionKey,
                vendor: vendor,
                model: model,
                fastMode: fastMode,
                purpose: purpose,
                round: round,
                temporary: temporary,
                inputTokens: inputTokens,
                outputTokens: outputTokens,
                cacheReadTokens: cacheReadTokens,
                cacheWriteTokens: cacheWriteTokens,
                reasoningTokens: reasoningTokens,
                wikiIndexNotes: wikiIndexNotes,
                wikiIndexChars: wikiIndexChars,
                readWikiCalls: readWikiCalls,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime at,
                required String questionKey,
                required ChatVendor vendor,
                required String model,
                Value<bool> fastMode = const Value.absent(),
                required ChatUsagePurpose purpose,
                required int round,
                required bool temporary,
                required int inputTokens,
                required int outputTokens,
                required int cacheReadTokens,
                required int cacheWriteTokens,
                Value<int?> reasoningTokens = const Value.absent(),
                Value<int> wikiIndexNotes = const Value.absent(),
                Value<int> wikiIndexChars = const Value.absent(),
                Value<int> readWikiCalls = const Value.absent(),
              }) => ChatUsageRowsCompanion.insert(
                id: id,
                at: at,
                questionKey: questionKey,
                vendor: vendor,
                model: model,
                fastMode: fastMode,
                purpose: purpose,
                round: round,
                temporary: temporary,
                inputTokens: inputTokens,
                outputTokens: outputTokens,
                cacheReadTokens: cacheReadTokens,
                cacheWriteTokens: cacheWriteTokens,
                reasoningTokens: reasoningTokens,
                wikiIndexNotes: wikiIndexNotes,
                wikiIndexChars: wikiIndexChars,
                readWikiCalls: readWikiCalls,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChatUsageRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$ChatDatabase,
      $ChatUsageRowsTable,
      ChatUsageRow,
      $$ChatUsageRowsTableFilterComposer,
      $$ChatUsageRowsTableOrderingComposer,
      $$ChatUsageRowsTableAnnotationComposer,
      $$ChatUsageRowsTableCreateCompanionBuilder,
      $$ChatUsageRowsTableUpdateCompanionBuilder,
      (
        ChatUsageRow,
        BaseReferences<_$ChatDatabase, $ChatUsageRowsTable, ChatUsageRow>,
      ),
      ChatUsageRow,
      PrefetchHooks Function()
    >;

class $ChatDatabaseManager {
  final _$ChatDatabase _db;
  $ChatDatabaseManager(this._db);
  $$ConversationsTableTableManager get conversations =>
      $$ConversationsTableTableManager(_db, _db.conversations);
  $$ChatTurnsTableTableManager get chatTurns =>
      $$ChatTurnsTableTableManager(_db, _db.chatTurns);
  $$ChatUsageRowsTableTableManager get chatUsageRows =>
      $$ChatUsageRowsTableTableManager(_db, _db.chatUsageRows);
}
