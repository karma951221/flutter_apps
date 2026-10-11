import 'package:core/core.dart';
import 'package:drift/drift.dart';

import '../../domain/diary/entity/diary_usage.dart';
import '../../domain/diary/entity/entry_media.dart';
import '../../domain/diary/entity/named_count.dart';
import '../../domain/diary/entity/story.dart';
import '../../domain/diary/entity/tag_name.dart';
import '../../domain/diary/usecase/story_order.dart';
import 'database/diary_database.dart';
import 'database/diary_mapper.dart';

/// 태그 · 장소 · 스토리 집계와 용량. `DriftDiaryRepository` 가 위임한다.
/// 사용 횟수는 저장하지 않고 휴지통이 아닌 기록만 조인해 센다(스펙 §5).
class DiaryCountQueries {
  DiaryCountQueries(this._db);

  final DiaryDatabase _db;

  /// 집계가 다시 흘러야 하는 테이블: 추가 · 수정 · 휴지통 · 복원 · 영구 삭제.
  Set<ResultSetImplementation<dynamic, dynamic>> get _countSources => {
    _db.entries,
    _db.entryTags,
    _db.tags,
    _db.places,
  };

  Stream<List<NamedCount>> watchTagCounts(String query, int limit) =>
      _watchNamedCounts(
        'FROM tags n '
        'JOIN entry_tags et ON et.tag_id = n.id '
        'JOIN entries e ON e.id = et.entry_id',
        key: TagName.searchKey(query),
        limit: limit,
      );

  Stream<List<NamedCount>> watchPlaceCounts(String query, int limit) =>
      _watchNamedCounts(
        'FROM places n JOIN entries e ON e.place_id = n.id',
        key: query.trim(),
        limit: limit,
      );

  Stream<List<({Story story, int count})>> watchStoryMatches(
    String query,
    String dailyTitle,
  ) {
    final key = query.trim().toLowerCase();
    return _db
        .customSelect(
          'SELECT s.*, (SELECT COUNT(*) FROM entries e '
          'WHERE e.story_id = s.id AND e.deleted_at IS NULL) AS entry_count '
          'FROM stories s',
          readsFrom: {_db.stories, _db.entries},
        )
        .watch()
        .map((rows) {
          final counts = <String, int>{};
          final matched = <Story>[];
          for (final row in rows) {
            final story = storyFromRow(_db.stories.map(row.data));
            final title = story.isDefault && story.title.isEmpty
                ? dailyTitle
                : story.title;
            if (!title.toLowerCase().contains(key)) continue;
            matched.add(story);
            counts[story.id] = row.read<int>('entry_count');
          }
          final (:open, :archived) = StoryOrder.split(matched);
          return [
            for (final s in [...open, ...archived])
              (story: s, count: counts[s.id]!),
          ];
        });
  }

  Future<DiaryUsage> usage() async {
    final row = await _db
        .customSelect(
          'SELECT '
          'COALESCE(SUM(m.kind = ?), 0) AS photos, '
          'COALESCE(SUM(m.kind = ?), 0) AS videos, '
          'COALESCE(SUM(m.bytes), 0) AS bytes, '
          'COALESCE(SUM(CASE WHEN e.deleted_at IS NOT NULL '
          'THEN m.bytes ELSE 0 END), 0) AS trash_bytes '
          'FROM media m JOIN entries e ON e.id = m.entry_id',
          variables: [
            Variable.withString(MediaKind.photo.name),
            Variable.withString(MediaKind.video.name),
          ],
        )
        .getSingle();
    return DiaryUsage(
      photos: row.read<int>('photos'),
      videos: row.read<int>('videos'),
      bytes: row.read<int>('bytes'),
      trashBytes: row.read<int>('trash_bytes'),
    );
  }

  /// [from] 은 이름 테이블을 `n`, 기록을 `e` 로 조인하는 FROM 절. [key] 가
  /// 비어 있지 않으면 `n.name` 포함 일치(LIKE, ASCII 대소문자 무시).
  /// 정렬: 개수 → 최근 사용(최대 occurredAt) → 이름.
  Stream<List<NamedCount>> _watchNamedCounts(
    String from, {
    required String key,
    required int limit,
  }) {
    final filter = key.isEmpty ? '' : r"AND n.name LIKE ? ESCAPE '\' ";
    // MAX() 가 하나뿐인 집계에서 SQLite 는 맨 열(e.occurred_at)을 최댓값을 낸
    // 행에서 가져온다 — julianday 로 비교하고 저장된 값 그대로 읽는다.
    return _db
        .customSelect(
          'SELECT n.name AS name, COUNT(*) AS use_count, '
          'MAX(julianday(e.occurred_at)) AS last_used_day, '
          'e.occurred_at AS last_used_at '
          '$from '
          'WHERE e.deleted_at IS NULL $filter'
          'GROUP BY n.id '
          'ORDER BY use_count DESC, last_used_day DESC, n.name ASC '
          'LIMIT ?',
          variables: [
            if (key.isNotEmpty)
              Variable.withString('%${LikePattern.escape(key)}%'),
            Variable.withInt(limit),
          ],
          readsFrom: _countSources,
        )
        .watch()
        .map(
          (rows) => [
            for (final r in rows)
              NamedCount(
                name: r.read<String>('name'),
                count: r.read<int>('use_count'),
                lastUsedAt: r.read<DateTime>('last_used_at'),
              ),
          ],
        );
  }
}
