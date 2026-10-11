import 'package:core/core.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../domain/diary/diary_failure.dart';
import '../../domain/diary/entity/diary_entry.dart';
import '../../domain/diary/entity/diary_usage.dart';
import '../../domain/diary/entity/entry_draft.dart';
import '../../domain/diary/entity/entry_filter.dart';
import '../../domain/diary/entity/entry_location.dart';
import '../../domain/diary/entity/named_count.dart';
import '../../domain/diary/entity/story.dart';
import '../../domain/diary/entity/tag_name.dart';
import '../../domain/diary/repository/diary_repository.dart';
import 'database/diary_database.dart';
import 'database/diary_mapper.dart';
import 'diary_count_queries.dart';

@LazySingleton(as: DiaryRepository)
class DriftDiaryRepository implements DiaryRepository {
  DriftDiaryRepository(this._db, this._ids, this._clock)
    : _counts = DiaryCountQueries(_db);

  final DiaryDatabase _db;
  final IdGenerator _ids;
  final Clock _clock;
  final DiaryCountQueries _counts;

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

  @override
  Future<Result<void>> deleteStory(String id) => _guard(() async {
    if (id == Story.dailyId) {
      return Err(DiaryFailure.defaultStoryLocked.toFailure());
    }
    final failure = await _db.transaction(() async {
      if (await _storyRow(id) == null) return const Failure.notFound();
      await (_db.update(_db.entries)
            ..where((e) => e.storyId.equals(id) & e.deletedAt.isNull()))
          .write(EntriesCompanion(deletedAt: Value(_clock.now())));
      // 스토리 행을 지우려면 FK 상 기록이 다른 스토리를 가리켜야 한다 → '일상'.
      await (_db.update(_db.entries)..where((e) => e.storyId.equals(id))).write(
        const EntriesCompanion(storyId: Value(Story.dailyId)),
      );
      await (_db.delete(_db.stories)..where((s) => s.id.equals(id))).go();
      return null;
    });
    return failure == null ? const Ok(null) : Err(failure);
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
        [Variable.withString(TagName.searchKey(name))],
      ),
      // 저장할 때처럼 trim 한 이름으로 찾는다.
      PlaceEntries(:final name) => (
        'AND EXISTS (SELECT 1 FROM places p '
            'WHERE p.id = e.place_id AND p.name = ?)',
        [Variable.withString(name.trim())],
      ),
      BodyEntries(:final query) => (
        r"AND e.body LIKE ? ESCAPE '\'",
        [Variable.withString('%${LikePattern.escape(query)}%')],
      ),
    };
    return _watchAssembled(
      'SELECT e.* FROM entries e '
      'WHERE e.deleted_at IS NULL $where '
      'ORDER BY julianday(e.occurred_at) DESC, '
      'julianday(e.created_at) DESC',
      args,
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
        // 휴지통 기록은 복원하기 전까지 읽기만 한다.
        if (row == null || row.deletedAt != null) {
          return const Failure.notFound();
        }
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
          final moved =
              await (_db.update(_db.entries)
                    ..where((e) => e.id.isIn(ids) & e.deletedAt.isNull()))
                  .write(EntriesCompanion(storyId: Value(storyId)));
          if (moved > 0) await _markPosted(storyId, _clock.now());
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

  // ---------------------------------------------------------------- 휴지통

  @override
  Future<Result<void>> trashEntry(String id) => _guard(() async {
    final written =
        await (_db.update(_db.entries)
              ..where((e) => e.id.equals(id) & e.deletedAt.isNull()))
            .write(EntriesCompanion(deletedAt: Value(_clock.now())));
    // 0 이면 없거나 이미 휴지통(처음 deletedAt 유지).
    if (written == 0 && await _entryOrNull(id) == null) {
      return const Err(Failure.notFound());
    }
    return const Ok(null);
  });

  @override
  Future<Result<DiaryEntry>> restoreEntry(String id) => _guard(() async {
    final written =
        await (_db.update(_db.entries)..where((e) => e.id.equals(id))).write(
          const EntriesCompanion(deletedAt: Value(null)),
        );
    if (written == 0) return const Err(Failure.notFound());
    return Ok((await _entryOrNull(id))!);
  });

  @override
  Stream<List<DiaryEntry>> watchTrash() => _watchAssembled(
    'SELECT e.* FROM entries e '
    'WHERE e.deleted_at IS NOT NULL '
    'ORDER BY julianday(e.deleted_at) DESC, julianday(e.created_at) DESC',
    const [],
  );

  @override
  Future<Result<List<String>>> purgeEntries(List<String> ids) => ids.isEmpty
      ? Future.value(const Ok([]))
      : _purgeTrashed((e) => e.id.isIn(ids));

  @override
  Future<Result<List<String>>> purgeTrashedBefore(DateTime deletedBefore) =>
      _purgeTrashed(
        (e) => e.deletedAt.julianday.isSmallerOrEqual(
          Variable(deletedBefore).julianday,
        ),
      );

  @override
  Future<Result<List<String>>> purgeAllTrash() =>
      _purgeTrashed((_) => const Constant(true));

  @override
  Future<Set<String>> allMediaPaths() async => {
    for (final m in await _db.select(_db.media).get()) ...[
      m.path,
      ?m.thumbPath,
    ],
  };

  // ----------------------------------------------------- 모아보기 · 추천

  @override
  Stream<List<NamedCount>> watchTagCounts({
    String query = '',
    int limit = 20,
  }) => _counts.watchTagCounts(query, limit);

  @override
  Future<List<DiaryEntry>> entriesMissingPlaceName() async {
    final rows =
        await (_db.select(_db.entries)
              ..where(
                (e) =>
                    e.deletedAt.isNull() &
                    e.placeId.isNull() &
                    e.lat.isNotNull() &
                    e.lng.isNotNull(),
              )
              ..orderBy([(e) => OrderingTerm.asc(e.createdAt.julianday)]))
            .get();
    return _assemble(rows);
  }

  @override
  Future<Result<void>> fillPlaceName(String entryId, String name) =>
      _guard(() async {
        return _db.transaction<Result<void>>(() async {
          final row = await (_db.select(
            _db.entries,
          )..where((e) => e.id.equals(entryId))).getSingleOrNull();
          if (row == null) return const Err(Failure.notFound());
          if (row.placeId != null) return const Ok(null);
          final placeId = await _placeId(
            EntryLocation(placeName: name),
            _clock.now(),
          );
          if (placeId == null) return const Ok(null);
          await (_db.update(_db.entries)..where((e) => e.id.equals(entryId)))
              .write(EntriesCompanion(placeId: Value(placeId)));
          return const Ok(null);
        });
      });

  @override
  Stream<List<NamedCount>> watchPlaceCounts({
    String query = '',
    int limit = 20,
  }) => _counts.watchPlaceCounts(query, limit);

  @override
  Stream<List<({Story story, int count})>> watchStoryMatches(
    String query, {
    required String dailyTitle,
  }) => _counts.watchStoryMatches(query, dailyTitle);

  @override
  Future<DiaryUsage> usage() => _counts.usage();

  // ------------------------------------------------------------------ 내부

  /// 기록 행을 고르는 SQL 을 구독해 조립한 기록으로 내보낸다. 미디어 · 태그 ·
  /// 장소만 바뀌어도 다시 흐르도록 조립에 쓰는 테이블을 모두 구독한다.
  Stream<List<DiaryEntry>> _watchAssembled(String sql, List<Variable> args) =>
      _db
          .customSelect(
            sql,
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
            (rows) =>
                _assemble([for (final r in rows) _db.entries.map(r.data)]),
          );

  /// 휴지통 기록 중 [which] 에 맞는 것을 한 트랜잭션에서 영구 삭제하고,
  /// 지워진 미디어 파일의 상대 경로(원본 · 썸네일)를 돌려준다. 파일은 건드리지 않는다.
  Future<Result<List<String>>> _purgeTrashed(
    Expression<bool> Function($EntriesTable e) which,
  ) => _guard(() async {
    final paths = await _db.transaction(() async {
      final targets = _db.selectOnly(_db.entries)
        ..addColumns([_db.entries.id])
        ..where(_db.entries.deletedAt.isNotNull() & which(_db.entries));
      final mediaRows = await (_db.select(
        _db.media,
      )..where((m) => m.entryId.isInQuery(targets))).get();

      // 표지 정리는 미디어 행이 연쇄 삭제되기 전에 한다.
      final targetMedia = _db.selectOnly(_db.media)
        ..addColumns([_db.media.id])
        ..where(_db.media.entryId.isInQuery(targets));
      await (_db.update(_db.stories)
            ..where((s) => s.coverMediaId.isInQuery(targetMedia)))
          .write(const StoriesCompanion(coverMediaId: Value(null)));

      // media · entry_tags 는 ON DELETE CASCADE 로 함께 지워진다.
      await (_db.delete(
        _db.entries,
      )..where((e) => e.deletedAt.isNotNull() & which(e))).go();

      // 휴지통에 남은 기록이 쓰는 행은 남는다(복원 시 같은 id).
      await _db.customUpdate(
        'DELETE FROM tags WHERE id NOT IN (SELECT tag_id FROM entry_tags)',
        updates: {_db.tags},
        updateKind: UpdateKind.delete,
      );
      await _db.customUpdate(
        'DELETE FROM places WHERE id NOT IN '
        '(SELECT place_id FROM entries WHERE place_id IS NOT NULL)',
        updates: {_db.places},
        updateKind: UpdateKind.delete,
      );
      return [
        for (final m in mediaRows) ...[m.path, ?m.thumbPath],
      ];
    });
    return Ok(paths);
  });

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
