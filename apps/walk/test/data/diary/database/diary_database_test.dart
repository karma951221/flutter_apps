import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/data/diary/database/diary_database.dart';
import 'package:walk/domain/diary/entity/entry_media.dart';
import 'package:walk/domain/diary/entity/story.dart';

void main() {
  final fixed = DateTime(2026, 10, 10, 9);
  late QueryExecutor executor;
  late DiaryDatabase db;

  setUp(() {
    executor = NativeDatabase.memory();
    db = DiaryDatabase(executor, now: () => fixed);
  });
  tearDown(() => db.close());

  Future<void> insertEntry(String id, {String storyId = 'daily'}) =>
      db.into(db.entries).insert(
        EntriesCompanion.insert(
          id: id,
          storyId: storyId,
          body: 'b',
          occurredAt: fixed,
          createdAt: fixed,
          updatedAt: fixed,
        ),
      );

  test('처음 열면 기본 스토리 daily 한 행이 생긴다', () async {
    final rows = await db.select(db.stories).get();
    expect(rows, hasLength(1));
    expect(rows.single.id, Story.dailyId);
    expect(rows.single.status, StoryStatus.open);
    expect(rows.single.title, '');
    expect(rows.single.startedAt, fixed);
    expect(rows.single.createdAt, fixed);
  });

  // 같은 executor 는 다시 열리지 않으므로 파일 DB 를 닫았다가 다시 연다.
  group('파일 DB 를 다시 열 때', () {
    late Directory dir;
    late File file;
    setUp(() {
      dir = Directory.systemTemp.createTempSync('diary_db_test');
      file = File('${dir.path}/diary.sqlite');
    });
    tearDown(() => dir.deleteSync(recursive: true));

    test('기본 스토리는 한 행으로 유지된다', () async {
      final first = DiaryDatabase(NativeDatabase(file), now: () => fixed);
      await first.select(first.stories).get();
      await first.close();
      final second = DiaryDatabase(NativeDatabase(file), now: () => fixed);
      addTearDown(second.close);
      expect(await second.select(second.stories).get(), hasLength(1));
    });

    test('daily 를 지우고 다시 열면 되살아난다', () async {
      final first = DiaryDatabase(NativeDatabase(file), now: () => fixed);
      await first.select(first.stories).get();
      await first.delete(first.stories).go();
      await first.close();
      final second = DiaryDatabase(NativeDatabase(file), now: () => fixed);
      addTearDown(second.close);
      final rows = await second.select(second.stories).get();
      expect(rows.map((r) => r.id), [Story.dailyId]);
    });
  });

  test('foreign_keys 가 켜져 있다', () async {
    final row = await db.customSelect('PRAGMA foreign_keys').getSingle();
    expect(row.data.values.single, 1);
  });

  test('tags.name 중복은 예외', () async {
    Future<void> add(String id) => db.into(db.tags).insert(
      TagsCompanion.insert(id: id, name: 'jeju', createdAt: fixed),
    );
    await add('1');
    await expectLater(add('2'), throwsA(isA<Exception>()));
  });

  test('places.name 중복은 예외', () async {
    Future<void> add(String id) => db.into(db.places).insert(
      PlacesCompanion.insert(id: id, name: '제주', createdAt: fixed),
    );
    await add('1');
    await expectLater(add('2'), throwsA(isA<Exception>()));
  });

  test('기록을 지우면 media · entry_tags 가 연쇄로 지워진다', () async {
    await insertEntry('e1');
    await db.into(db.tags).insert(
      TagsCompanion.insert(id: 't1', name: 'a', createdAt: fixed),
    );
    await db.into(db.entryTags).insert(
      EntryTagsCompanion.insert(entryId: 'e1', tagId: 't1'),
    );
    await db.into(db.media).insert(
      MediaCompanion.insert(
        id: 'm1',
        entryId: 'e1',
        kind: MediaKind.photo,
        path: 'p',
        sortOrder: 0,
        width: 1,
        height: 1,
        bytes: 1,
      ),
    );
    await (db.delete(db.entries)..where((e) => e.id.equals('e1'))).go();
    expect(await db.select(db.media).get(), isEmpty);
    expect(await db.select(db.entryTags).get(), isEmpty);
    expect(await db.select(db.tags).get(), hasLength(1));
  });

  test('없는 storyId 로 기록을 넣으면 FK 예외', () async {
    await expectLater(
      insertEntry('e1', storyId: 'nope'),
      throwsA(isA<Exception>()),
    );
  });
}
