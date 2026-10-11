import 'package:drift/drift.dart';

import '../../../domain/diary/entity/entry_media.dart';
import '../../../domain/diary/entity/story.dart';

@DataClassName('StoryRow')
class Stories extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get status => textEnum<StoryStatus>()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  TextColumn get coverMediaId => text().nullable()();
  DateTimeColumn get lastPostedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('PlaceRow')
class Places extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().unique()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('TagRow')
class Tags extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().unique()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('EntryRow')
@TableIndex(name: 'entries_story_occurred', columns: {#storyId, #occurredAt})
@TableIndex(name: 'entries_deleted_at', columns: {#deletedAt})
class Entries extends Table {
  TextColumn get id => text()();
  TextColumn get storyId => text().references(Stories, #id)();
  TextColumn get body => text()();
  DateTimeColumn get occurredAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get placeId =>
      text().nullable().references(Places, #id, onDelete: KeyAction.setNull)();
  RealColumn get lat => real().nullable()();
  RealColumn get lng => real().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('MediaRow')
@TableIndex(name: 'media_entry_sort', columns: {#entryId, #sortOrder})
class Media extends Table {
  TextColumn get id => text()();
  TextColumn get entryId =>
      text().references(Entries, #id, onDelete: KeyAction.cascade)();
  TextColumn get kind => textEnum<MediaKind>()();
  TextColumn get path => text()();
  TextColumn get thumbPath => text().nullable()();
  IntColumn get sortOrder => integer()();
  IntColumn get width => integer()();
  IntColumn get height => integer()();
  IntColumn get durationMs => integer().nullable()();
  IntColumn get bytes => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('EntryTagRow')
@TableIndex(name: 'entry_tags_tag', columns: {#tagId})
class EntryTags extends Table {
  TextColumn get entryId =>
      text().references(Entries, #id, onDelete: KeyAction.cascade)();
  TextColumn get tagId =>
      text().references(Tags, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column<Object>> get primaryKey => {entryId, tagId};
}
