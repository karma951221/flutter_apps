import 'package:core/core.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../domain/diary/diary_failure.dart';
import '../../domain/diary/entity/diary_entry.dart';
import '../../domain/diary/entity/entry_draft.dart';
import '../../domain/diary/entity/entry_filter.dart';
import '../../domain/diary/entity/entry_location.dart';
import '../../domain/diary/entity/story.dart';
import '../../domain/diary/entity/tag_name.dart';
import '../../domain/diary/repository/diary_repository.dart';
import 'database/diary_database.dart';
import 'database/diary_mapper.dart';

@LazySingleton(as: DiaryRepository)
class DriftDiaryRepository implements DiaryRepository {
  DriftDiaryRepository(this._db, this._ids, this._clock);

  final DiaryDatabase _db;
  final IdGenerator _ids;
  final Clock _clock;

  // ---------------------------------------------------------------- 스토리

  @override
  Stream<List<Story>> watchStories() =>
      (_db.select(_db.stories)..orderBy([(s) => OrderingTerm.asc(s.createdAt)]))
          .watch()
          .map((rows) => [for (final r in rows) storyFromRow(r)]);

  @override
  Future<Result<Story>> createStory({
    required String title,
    required DateTime startedAt,
    DateTime? endedAt,
  }) => _guard(() async {
    if (endedAt != null && endedAt.isBefore(startedAt)) {
      return Err(DiaryFailure.endBeforeStart.toFailure());
    }
    final story = Story(
      id: _ids.newId(),
      title: title,
      status: endedAt == null ? StoryStatus.open : StoryStatus.closed,
      startedAt: startedAt,
      endedAt: endedAt,
      createdAt: _clock.now(),
    );
    await _db
        .into(_db.stories)
        .insert(
          StoriesCompanion.insert(
            id: story.id,
            title: story.title,
            status: story.status,
            startedAt: story.startedAt,
            endedAt: Value(story.endedAt),
            createdAt: story.createdAt,
          ),
        );
    return Ok(story);
  });

  @override
  Future<Result<Story>> updateStory(Story story) => _guard(() async {
    if (story.isDefault && !story.isOpen) {
      return Err(DiaryFailure.defaultStoryLocked.toFailure());
    }
    final written =
        await (_db.update(
          _db.stories,
        )..where((s) => s.id.equals(story.id))).write(
          StoriesCompanion(
            title: Value(story.title),
            status: Value(story.status),
            endedAt: Value(story.endedAt),
            coverMediaId: Value(story.coverMediaId),
          ),
        );
    if (written == 0) return const Err(Failure.notFound());
    return Ok(storyFromRow((await _storyRow(story.id))!));
  });

  // ------------------------------------------------------------------ 기록

  @override
  Stream<List<DiaryEntry>> watchEntries(EntryFilter filter) {
    final (where, args) = switch (filter) {
      AllEntries() => ('', <Variable>[]),
      StoryEntries(:final storyId) => (
        'AND e.story_id = ?',
        [Variable.withString(storyId)],
      ),
      TagEntries(:final name) => (
        'AND EXISTS (SELECT 1 FROM entry_tags et '
            'JOIN tags t ON t.id = et.tag_id '
            'WHERE et.entry_id = e.id AND t.name = ?)',
        [Variable.withString(TagName.normalize(name) ?? name)],
      ),
      PlaceEntries(:final name) => (
        'AND EXISTS (SELECT 1 FROM places p '
            'WHERE p.id = e.place_id AND p.name = ?)',
        [Variable.withString(name)],
      ),
      BodyEntries(:final query) => (
        r"AND e.body LIKE ? ESCAPE '\'",
        [Variable.withString('%${LikePattern.escape(query)}%')],
      ),
    };
    // 미디어 · 태그 · 장소만 바뀌어도 다시 흐르도록 조립에 쓰는 테이블을 모두 구독한다.
    return _db
        .customSelect(
          'SELECT e.* FROM entries e '
          'WHERE e.deleted_at IS NULL $where '
          'ORDER BY julianday(e.occurred_at) DESC, '
          'julianday(e.created_at) DESC',
          variables: args,
          readsFrom: {
            _db.entries,
            _db.media,
            _db.entryTags,
            _db.tags,
            _db.places,
          },
        )
        .watch()
        .asyncMap(
          (rows) => _assemble([for (final r in rows) _db.entries.map(r.data)]),
        );
  }

  @override
  Future<Result<DiaryEntry>> entry(String id) => _guard(() async {
    final found = await _entryOrNull(id);
    return found == null ? const Err(Failure.notFound()) : Ok(found);
  });

  @override
  Future<Result<DiaryEntry>> createEntry(EntryDraft draft) => _guard(() async {
    final now = _clock.now();
    if (draft.validate(now) case Err(:final failure)) return Err(failure);
    final id = _ids.newId();
    final failure = await _db.transaction(() async {
      final storyFailure = await _checkTargetStory(draft.storyId);
      if (storyFailure != null) return storyFailure;
      await _db
          .into(_db.entries)
          .insert(
            EntriesCompanion.insert(
              id: id,
              storyId: draft.storyId,
              body: draft.body,
              occurredAt: draft.occurredAt,
              createdAt: now,
              updatedAt: now,
              placeId: Value(await _placeId(draft.location, now)),
              lat: Value(draft.location?.lat),
              lng: Value(draft.location?.lng),
            ),
          );
      await _insertChildren(id, draft, now);
      await _markPosted(draft.storyId, now);
      return null;
    });
    if (failure != null) return Err(failure);
    return Ok((await _entryOrNull(id))!);
  });

  @override
  Future<Result<DiaryEntry>> updateEntry(String id, EntryDraft draft) => _guard(
    () async {
      final now = _clock.now();
      if (draft.validate(now) case Err(:final failure)) return Err(failure);
      final failure = await _db.transaction(() async {
        final row = await (_db.select(
          _db.entries,
        )..where((e) => e.id.equals(id))).getSingleOrNull();
        if (row == null) return const Failure.notFound();
        final moving = row.storyId != draft.storyId;
        if (moving) {
          final storyFailure = await _checkTargetStory(draft.storyId);
          if (storyFailure != null) return storyFailure;
        }
        await (_db.update(_db.entries)..where((e) => e.id.equals(id))).write(
          EntriesCompanion(
            storyId: Value(draft.storyId),
            body: Value(draft.body),
            occurredAt: Value(draft.occurredAt),
            updatedAt: Value(now),
            placeId: Value(await _placeId(draft.location, now)),
            lat: Value(draft.location?.lat),
            lng: Value(draft.location?.lng),
          ),
        );
        // 미디어 · 태그는 지우고 draft 순서대로 다시 넣는다(미디어 id 는 draft 의 것).
        await (_db.delete(_db.media)..where((m) => m.entryId.equals(id))).go();
        await (_db.delete(
          _db.entryTags,
        )..where((t) => t.entryId.equals(id))).go();
        await _insertChildren(id, draft, now);
        if (moving) await _markPosted(draft.storyId, now);
        return null;
      });
      if (failure != null) return Err(failure);
      return Ok((await _entryOrNull(id))!);
    },
  );

  @override
  Future<Result<void>> moveEntries(List<String> ids, String storyId) =>
      _guard(() async {
        final failure = await _db.transaction(() async {
          final storyFailure = await _checkTargetStory(storyId);
          if (storyFailure != null) return storyFailure;
          await (_db.update(_db.entries)..where((e) => e.id.isIn(ids))).write(
            EntriesCompanion(storyId: Value(storyId)),
          );
          await _markPosted(storyId, _clock.now());
          return null;
        });
        return failure == null ? const Ok(null) : Err(failure);
      });

  @override
  Future<List<DiaryEntry>> entriesBetween(
    DateTime from,
    DateTime to, {
    required String storyId,
  }) async {
    final rows =
        await (_db.select(_db.entries)
              ..where(
                (e) =>
                    e.deletedAt.isNull() &
                    e.storyId.equals(storyId) &
                    e.occurredAt.julianday.isBetween(
                      Variable(from).julianday,
                      Variable(to).julianday,
                    ),
              )
              ..orderBy([
                (e) => OrderingTerm.desc(e.occurredAt.julianday),
                (e) => OrderingTerm.desc(e.createdAt.julianday),
              ]))
            .get();
    return _assemble(rows);
  }

  // ------------------------------------------------------------------ 내부

  /// SQLite 예외를 `Failure.unknown` 으로 바꾼다.
  Future<Result<T>> _guard<T>(Future<Result<T>> Function() body) async {
    try {
      return await body();
    } catch (error) {
      return Err(Failure.unknown(message: error.toString()));
    }
  }

  Future<StoryRow?> _storyRow(String id) => (_db.select(
    _db.stories,
  )..where((s) => s.id.equals(id))).getSingleOrNull();

  /// 기록을 새로 두거나 옮겨 갈 스토리: 없으면 notFound, 닫혔으면 storyClosed.
  Future<Failure?> _checkTargetStory(String storyId) async {
    final story = await _storyRow(storyId);
    if (story == null) return const Failure.notFound();
    if (story.status == StoryStatus.closed) {
      return DiaryFailure.storyClosed.toFailure();
    }
    return null;
  }

  Future<void> _markPosted(String storyId, DateTime now) =>
      (_db.update(_db.stories)..where((s) => s.id.equals(storyId))).write(
        StoriesCompanion(lastPostedAt: Value(now)),
      );

  /// 장소 이름이 있으면 같은 이름 행을 재사용(없으면 만든다)하고 그 id.
  Future<String?> _placeId(EntryLocation? location, DateTime now) async {
    final name = location?.placeName?.trim();
    if (name == null || name.isEmpty) return null;
    await _db
        .into(_db.places)
        .insert(
          PlacesCompanion.insert(id: _ids.newId(), name: name, createdAt: now),
          mode: InsertMode.insertOrIgnore,
        );
    final row = await (_db.select(
      _db.places,
    )..where((p) => p.name.equals(name))).getSingle();
    return row.id;
  }

  /// 미디어(draft 순서) · 태그(정규화 · 중복 제거, 입력 순)를 넣는다.
  Future<void> _insertChildren(
    String entryId,
    EntryDraft draft,
    DateTime now,
  ) async {
    await _db.batch((b) {
      b.insertAll(_db.media, [
        for (var i = 0; i < draft.media.length; i++)
          mediaToCompanion(entryId, i, draft.media[i]),
      ]);
    });
    final names = <String>{
      for (final raw in draft.tags) ?TagName.normalize(raw),
    };
    for (final name in names) {
      await _db
          .into(_db.tags)
          .insert(
            TagsCompanion.insert(id: _ids.newId(), name: name, createdAt: now),
            mode: InsertMode.insertOrIgnore,
          );
      final tag = await (_db.select(
        _db.tags,
      )..where((t) => t.name.equals(name))).getSingle();
      // entry_tags 의 rowid 가 입력 순서를 기억한다.
      await _db
          .into(_db.entryTags)
          .insert(EntryTagsCompanion.insert(entryId: entryId, tagId: tag.id));
    }
  }

  Future<DiaryEntry?> _entryOrNull(String id) async {
    final row = await (_db.select(
      _db.entries,
    )..where((e) => e.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return (await _assemble([row])).single;
  }

  /// 기록 행들에 미디어(sortOrder 순) · 태그(입력 순) · 장소 이름을 붙인다.
  /// 행 순서는 그대로 둔다.
  Future<List<DiaryEntry>> _assemble(List<EntryRow> rows) async {
    if (rows.isEmpty) return const [];
    final ids = [for (final r in rows) r.id];

    final mediaRows =
        await (_db.select(_db.media)
              ..where((m) => m.entryId.isIn(ids))
              ..orderBy([(m) => OrderingTerm.asc(m.sortOrder)]))
            .get();
    final mediaByEntry = <String, List<MediaRow>>{};
    for (final m in mediaRows) {
      (mediaByEntry[m.entryId] ??= []).add(m);
    }

    final tagRows = await _db
        .customSelect(
          'SELECT et.entry_id AS entry_id, t.name AS name '
          'FROM entry_tags et JOIN tags t ON t.id = et.tag_id '
          'WHERE et.entry_id IN (${List.filled(ids.length, '?').join(', ')}) '
          'ORDER BY et.rowid',
          variables: [for (final id in ids) Variable.withString(id)],
        )
        .get();
    final tagsByEntry = <String, List<String>>{};
    for (final t in tagRows) {
      (tagsByEntry[t.read<String>('entry_id')] ??= []).add(
        t.read<String>('name'),
      );
    }

    final placeIds = {for (final r in rows) ?r.placeId};
    final placeNames = placeIds.isEmpty
        ? const <String, String>{}
        : {
            for (final p in await (_db.select(
              _db.places,
            )..where((p) => p.id.isIn(placeIds))).get())
              p.id: p.name,
          };

    return [
      for (final r in rows)
        entryFromRow(
          r,
          media: [for (final m in mediaByEntry[r.id] ?? []) mediaFromRow(m)],
          tags: tagsByEntry[r.id] ?? const [],
          placeName: placeNames[r.placeId],
        ),
    ];
  }
}
