import 'dart:convert';

import 'package:core/core.dart';
import 'package:injectable/injectable.dart';

import '../../alarm/entity/ring_log_entry.dart';
import '../../alarm/ring_log.dart';
import '../../alarm/ring_log/ring_archive.dart';
import '../../alarm/usecase/ring_archiver.dart';
import '../../diary/entity/diary_entry.dart';
import '../../diary/entity/entry_media.dart';
import '../../diary/entity/story.dart';
import '../../diary/repository/diary_repository.dart';
import '../../walk/entity/health_access.dart';
import '../../walk/repository/activity_repository.dart';
import 'chat_image_source.dart';
import 'tool_result.dart';

/// Claude 가 사용자의 일기 · 걸음 · 기상 기록을 읽는 도구들.
@lazySingleton
class LifeTools {
  LifeTools(
    this._diary,
    this._activity,
    this._archiver,
    this._rings,
    this._images,
  );

  final DiaryRepository _diary;
  final ActivityRepository _activity;
  final RingArchiver _archiver;
  final RingArchive _rings;
  final ChatImageSource _images;

  static const _maxEntries = 50;
  static const _maxPhotos = 4;
  static const _maxDays = 366;
  static const _indexLimit = 30;

  static Map<String, Object?> _tool(
    String name,
    String description,
    Map<String, Object?> properties,
    List<String> required,
  ) => {
    'name': name,
    'description': description,
    'input_schema': {
      'type': 'object',
      'properties': properties,
      'required': required,
    },
  };

  static const _date = {'type': 'string', 'description': 'YYYY-MM-DD (로컬 날짜)'};

  List<Map<String, Object?>> get definitions => [
    _tool(
      'search_diary',
      '기간 안의 일기를 찾는다. 양 끝 날짜를 포함하고 오래된 것부터 최대 50개를 준다. '
          'query 는 본문에 포함된 글자, tag · place · story_id 는 그 조건에 맞는 것만.',
      {
        'from': _date,
        'to': _date,
        'query': {'type': 'string', 'description': '본문에 들어 있는 글자'},
        'tag': {'type': 'string', 'description': '태그 이름'},
        'place': {'type': 'string', 'description': '장소 이름'},
        'story_id': {'type': 'string', 'description': '스토리 id'},
      },
      ['from', 'to'],
    ),
    _tool(
      'view_entry_photos',
      '일기 하나의 사진(최대 4장, 영상은 썸네일)을 이미지로 본다.',
      {
        'entry_id': {'type': 'string', 'description': '일기 id'},
      },
      ['entry_id'],
    ),
    _tool(
      'list_diary_index',
      '일기의 스토리 목록과 자주 쓴 태그 · 장소(상위 30)를 본다.',
      <String, Object?>{},
      [],
    ),
    _tool(
      'daily_steps',
      '기간의 하루별 걸음 수를 본다. 양 끝 날짜를 포함한다.',
      {'from': _date, 'to': _date},
      ['from', 'to'],
    ),
    _tool(
      'wake_records',
      '기간의 알람 울림 기록(울린 시각, 스누즈 횟수, 끈 시각)을 회차별로 본다. 양 끝 날짜를 포함한다.',
      {'from': _date, 'to': _date},
      ['from', 'to'],
    ),
  ];

  Future<ToolResult> run(String name, Map<String, Object?> input) async {
    try {
      return switch (name) {
        'search_diary' => await _searchDiary(input),
        'view_entry_photos' => await _viewPhotos(input),
        'list_diary_index' => await _index(),
        'daily_steps' => await _dailySteps(input),
        'wake_records' => await _wakeRecords(input),
        _ => _error('unknown_tool'),
      };
    } catch (_) {
      return _error('tool_failed');
    }
  }

  // 도구

  Future<ToolResult> _searchDiary(Map<String, Object?> input) async {
    final range = _range(input);
    if (range == null) return _error('invalid_range');
    String? text(String key) {
      final v = input[key];
      return v is String && v.trim().isNotEmpty ? v : null;
    }

    final found = await _diary.searchEntries(
      from: range.from,
      to: _endOfDay(range.to),
      query: text('query'),
      tag: text('tag'),
      place: text('place'),
      storyId: text('story_id'),
      limit: _maxEntries + 1,
    );
    final entries = found.take(_maxEntries).toList();
    return ToolResult(
      json: jsonEncode({
        'entries': [for (final e in entries) _entryJson(e)],
        'truncated': found.length > _maxEntries,
        ..._clamp(range),
      }),
      entryIds: [for (final e in entries) e.id],
    );
  }

  Future<ToolResult> _viewPhotos(Map<String, Object?> input) async {
    final id = input['entry_id'];
    if (id is! String) return _error('invalid_input');
    final result = await _diary.entry(id);
    final DiaryEntry entry;
    switch (result) {
      case Ok(:final value):
        entry = value;
      case Err():
        return _error('not_found');
    }
    final images = <ToolImage>[];
    for (final m in entry.media) {
      if (images.length >= _maxPhotos) break;
      final source = switch (m.kind) {
        MediaKind.photo => m,
        MediaKind.video =>
          m.thumbPath == null
              ? null
              : EntryMedia(
                  id: m.id,
                  kind: MediaKind.photo,
                  path: m.thumbPath!,
                  width: m.width,
                  height: m.height,
                  bytes: 0,
                ),
      };
      if (source == null) continue;
      final image = await _images.load(source);
      if (image != null) images.add(image);
    }
    return ToolResult(
      json: jsonEncode({
        'entry_id': entry.id,
        'shown': images.length,
        'total': entry.media.length,
      }),
      images: images,
      entryIds: [entry.id],
    );
  }

  Future<ToolResult> _index() async {
    final stories = await _diary.watchStoryMatches('', dailyTitle: '일상').first;
    final tags = await _diary.watchTagCounts(limit: _indexLimit).first;
    final places = await _diary.watchPlaceCounts(limit: _indexLimit).first;
    return ToolResult(
      json: jsonEncode({
        'stories': [
          for (final s in stories)
            {
              'id': s.story.id,
              'title': s.story.id == Story.dailyId ? '일상' : s.story.title,
              'started': _day(s.story.startedAt),
              'ended': s.story.endedAt == null ? null : _day(s.story.endedAt!),
              'entries': s.count,
            },
        ],
        'tags': [
          for (final t in tags) {'name': t.name, 'count': t.count},
        ],
        'places': [
          for (final p in places) {'name': p.name, 'count': p.count},
        ],
      }),
    );
  }

  Future<ToolResult> _dailySteps(Map<String, Object?> input) async {
    final range = _range(input);
    if (range == null) return _error('invalid_range');
    if (await _activity.access() != HealthAccess.granted) {
      return _error('health_connect_unavailable');
    }
    final result = await _activity.dailyActivities(range.from, range.to);
    return switch (result) {
      Ok(:final value) => ToolResult(
        json: jsonEncode({
          'days': [
            for (final d in value) {'date': _day(d.date), 'steps': d.steps},
          ],
          ..._clamp(range),
        }),
      ),
      Err() => _error('health_connect_unavailable'),
    };
  }

  Future<ToolResult> _wakeRecords(Map<String, Object?> input) async {
    final range = _range(input);
    if (range == null) return _error('invalid_range');
    try {
      await _archiver.archive();
    } catch (_) {
      // 옮겨 담기 실패는 이미 쌓인 기록을 읽는 데 지장이 없다.
    }
    final read = await _rings.read(
      from: range.from,
      to: DateTime(range.to.year, range.to.month, range.to.day + 1),
    );
    final groups = ringLogGroups(read, []);
    return ToolResult(
      json: jsonEncode({
        'rings': [
          for (final g in groups)
            {
              'date': _day(g.at),
              'alarm': g.archivedLabel,
              'rang_at': g.rangAt == null ? null : _time(g.rangAt!),
              'ended_at': g.endedAt == null ? null : _time(g.endedAt!),
              'end': switch (g.end) {
                RingLogKind.stopped => 'stopped',
                RingLogKind.autoStopped => 'autoStopped',
                _ => null,
              },
              'snoozes': g.snoozes,
              'skipped': g.skipped,
            },
        ],
        ..._clamp(range),
      }),
    );
  }

  // 도우미

  Map<String, Object?> _entryJson(DiaryEntry e) => {
    'id': e.id,
    'at': '${_day(e.occurredAt)}T${_time(e.occurredAt)}',
    'story': e.storyId,
    'place': e.location?.placeName,
    'tags': e.tags,
    'text': e.body,
    'photos': e.media.where((m) => m.kind == MediaKind.photo).length,
    'videos': e.media.where((m) => m.kind == MediaKind.video).length,
  };

  static ToolResult _error(String code) =>
      ToolResult(json: jsonEncode({'error': code}), isError: true);

  static Map<String, Object?> _clamp(_Range r) =>
      r.clamped ? {'clamped': true} : {};

  static final _datePattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  static DateTime? _parse(Object? v) {
    if (v is! String) return null;
    final m = _datePattern.firstMatch(v.trim());
    if (m == null) return null;
    final y = int.parse(m[1]!), mo = int.parse(m[2]!), d = int.parse(m[3]!);
    final date = DateTime(y, mo, d);
    return date.year == y && date.month == mo && date.day == d ? date : null;
  }

  static _Range? _range(Map<String, Object?> input) {
    var from = _parse(input['from']);
    final to = _parse(input['to']);
    if (from == null || to == null || from.isAfter(to)) return null;
    final days =
        DateTime.utc(
          to.year,
          to.month,
          to.day,
        ).difference(DateTime.utc(from.year, from.month, from.day)).inDays +
        1;
    final clamped = days > _maxDays;
    if (clamped) from = DateTime(to.year, to.month, to.day - (_maxDays - 1));
    return _Range(from, to, clamped);
  }

  static DateTime _endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

  static String _two(int n) => n.toString().padLeft(2, '0');
  static String _day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}';
  static String _time(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';
}

class _Range {
  const _Range(this.from, this.to, this.clamped);
  final DateTime from;
  final DateTime to;
  final bool clamped;
}
