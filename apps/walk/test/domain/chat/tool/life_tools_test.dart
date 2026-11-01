import 'dart:convert';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/alarm/entity/alarm_trigger.dart';
import 'package:walk/domain/alarm/entity/archived_ring.dart';
import 'package:walk/domain/alarm/entity/ring_log_entry.dart';
import 'package:walk/domain/alarm/ring_log/ring_archive.dart';
import 'package:walk/domain/alarm/usecase/ring_archiver.dart';
import 'package:walk/domain/chat/chat_model.dart';
import 'package:walk/domain/chat/tool/chat_image_source.dart';
import 'package:walk/domain/chat/tool/life_tools.dart';
import 'package:walk/domain/chat/tool/tool_result.dart';
import 'package:walk/domain/chat/tool/tool_summary.dart';
import 'package:walk/domain/diary/entity/diary_entry.dart';
import 'package:walk/domain/diary/entity/entry_location.dart';
import 'package:walk/domain/diary/entity/entry_media.dart';
import 'package:walk/domain/diary/entity/story.dart';
import 'package:walk/domain/diary/repository/diary_repository.dart';
import 'package:walk/domain/walk/entity/daily_activity.dart';
import 'package:walk/domain/walk/entity/health_access.dart';
import 'package:walk/domain/walk/repository/activity_repository.dart';

class _Diary extends Mock implements DiaryRepository {}

class _Activity extends Mock implements ActivityRepository {}

class _Archiver extends Mock implements RingArchiver {}

class _Rings extends Mock implements RingArchive {}

class _Images implements ChatImageSource {
  @override
  Future<ToolImage?> load(EntryMedia media) async =>
      ToolImage(mediaType: 'image/jpeg', bytes: Uint8List.fromList([1]));
}

DiaryEntry _entry(
  String id, {
  String storyId = 'daily',
  List<EntryMedia> media = const [],
  String body = '본문',
}) => DiaryEntry(
  id: id,
  storyId: storyId,
  body: body,
  occurredAt: DateTime(2026, 10, 3, 9, 5),
  createdAt: DateTime(2026, 10, 3, 9, 5),
  updatedAt: DateTime(2026, 10, 3, 9, 5),
  location: const EntryLocation(placeName: '공원'),
  media: media,
  tags: const ['산책'],
);

Story _story(String id, String title) => Story(
  id: id,
  title: title,
  status: StoryStatus.open,
  startedAt: DateTime(2026),
  createdAt: DateTime(2026),
);

EntryMedia _photo(int i) => EntryMedia(
  id: 'p$i',
  kind: MediaKind.photo,
  path: 'media/p$i.jpg',
  width: 1,
  height: 1,
  bytes: 1,
);

void main() {
  late _Diary diary;
  late _Activity activity;
  late _Archiver archiver;
  late _Rings rings;
  late LifeTools tools;

  setUpAll(() {
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    diary = _Diary();
    activity = _Activity();
    archiver = _Archiver();
    rings = _Rings();
    when(
      () => diary.watchStoryMatches('', dailyTitle: any(named: 'dailyTitle')),
    ).thenAnswer(
      (_) => Stream.value([
        (story: _story('daily', ''), count: 1),
        (story: _story('trip', '제주 여행'), count: 1),
      ]),
    );
    when(() => archiver.archive()).thenAnswer((_) async {});
    tools = LifeTools(diary, activity, archiver, rings, _Images());
  });

  void stubSearch(List<DiaryEntry> entries) {
    when(
      () => diary.searchEntries(
        from: any(named: 'from'),
        to: any(named: 'to'),
        query: any(named: 'query'),
        tag: any(named: 'tag'),
        place: any(named: 'place'),
        storyId: any(named: 'storyId'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => entries);
  }

  Map<String, Object?> decode(ToolResult r) =>
      jsonDecode(r.json) as Map<String, Object?>;

  test('definitions 는 ToolSpec 다섯 개이고 parameters 가 object 다', () {
    final List<ToolSpec> defs = tools.definitions;
    expect(defs.map((d) => d.name), [
      'search_diary',
      'view_entry_photos',
      'list_diary_index',
      'daily_steps',
      'wake_records',
    ]);
    for (final d in defs) {
      expect(d.parameters['type'], 'object');
      expect(d.parameters['properties'], isA<Map>());
      expect(d.description, isNotEmpty);
    }
    expect(defs.map((d) => d.parameters['required']), [
      ['from', 'to'],
      ['entry_id'],
      <String>[],
      ['from', 'to'],
      ['from', 'to'],
    ]);
  });

  test('definitionsFor(images: false) 에 view_entry_photos 가 없고 나머지 넷은 같다', () {
    final all = tools.definitionsFor(images: true);
    final noImages = tools.definitionsFor(images: false);

    expect(all, tools.definitions);
    expect(noImages.map((d) => d.name), [
      'search_diary',
      'list_diary_index',
      'daily_steps',
      'wake_records',
    ]);
    expect(noImages, [
      for (final d in all)
        if (d.name != 'view_entry_photos') d,
    ]);
  });

  test('search_diary 는 기록을 JSON 으로 주고 entryIds 를 채운다', () async {
    stubSearch([
      _entry('a', media: [_photo(1)]),
    ]);
    final r = await tools.run('search_diary', {
      'from': '2026-10-01',
      'to': '2026-10-05',
    });
    expect(r.isError, isFalse);
    expect(r.entryIds, ['a']);
    final json = decode(r);
    expect(json['truncated'], false);
    final e = (json['entries']! as List).single as Map;
    expect(e['at'], '2026-10-03T09:05');
    expect(e['place'], '공원');
    expect(e['photos'], 1);
    expect(e['videos'], 0);
    expect(e['text'], '본문');
    verify(
      () => diary.searchEntries(
        from: DateTime(2026, 10, 1),
        to: DateTime(2026, 10, 5, 23, 59, 59, 999),
        query: null,
        tag: null,
        place: null,
        storyId: null,
        limit: 51,
      ),
    ).called(1);
  });

  test('search_diary 는 스토리 제목을 준다(기본 스토리는 일상)', () async {
    stubSearch([_entry('a'), _entry('b', storyId: 'trip')]);
    final r = await tools.run('search_diary', {
      'from': '2026-10-01',
      'to': '2026-10-05',
    });
    final entries = decode(r)['entries']! as List;
    expect([for (final e in entries) (e as Map)['story']], ['일상', '제주 여행']);
    verify(
      () => diary.watchStoryMatches('', dailyTitle: any(named: 'dailyTitle')),
    ).called(1);
  });

  test('search_diary 가 50개를 넘으면 50개와 truncated true', () async {
    stubSearch([for (var i = 0; i < 51; i++) _entry('e$i')]);
    final r = await tools.run('search_diary', {
      'from': '2026-10-01',
      'to': '2026-10-05',
    });
    final json = decode(r);
    expect((json['entries']! as List), hasLength(50));
    expect(json['truncated'], true);
    expect(r.entryIds, hasLength(50));
  });

  test('366일을 넘는 기간은 잘리고 clamped true', () async {
    stubSearch([]);
    final r = await tools.run('search_diary', {
      'from': '2020-01-01',
      'to': '2026-10-05',
    });
    expect(decode(r)['clamped'], true);
    verify(
      () => diary.searchEntries(
        from: DateTime(2025, 10, 5),
        to: any(named: 'to'),
        query: null,
        tag: null,
        place: null,
        storyId: null,
        limit: 51,
      ),
    ).called(1);
  });

  test('날짜가 거꾸로면 invalid_range 오류', () async {
    final r = await tools.run('daily_steps', {
      'from': '2026-10-05',
      'to': '2026-10-01',
    });
    expect(r.isError, isTrue);
    expect(decode(r), {'error': 'invalid_range'});
    final bad = await tools.run('search_diary', {
      'from': '10/01',
      'to': '2026-10-01',
    });
    expect(decode(bad), {'error': 'invalid_range'});
  });

  test('view_entry_photos 는 사진을 최대 4장 이미지로 붙인다', () async {
    when(() => diary.entry('a')).thenAnswer(
      (_) async =>
          Ok(_entry('a', media: [for (var i = 0; i < 6; i++) _photo(i)])),
    );
    final r = await tools.run('view_entry_photos', {'entry_id': 'a'});
    expect(r.images, hasLength(4));
    expect(decode(r), {'entry_id': 'a', 'shown': 4, 'total': 6});
    expect(r.entryIds, ['a']);
  });

  test('Health Connect 를 못 쓰면 daily_steps 는 오류 결과', () async {
    when(
      () => activity.access(),
    ).thenAnswer((_) async => HealthAccess.permissionDenied);
    final r = await tools.run('daily_steps', {
      'from': '2026-10-01',
      'to': '2026-10-02',
    });
    expect(r.isError, isTrue);
    expect(decode(r), {'error': 'health_connect_unavailable'});
  });

  test('wake_records 는 옮겨 담은 뒤 회차별 일어난 시각을 준다', () async {
    final pkg = packageId(5, triggerIndex(DateTime(2026, 10, 3)));
    when(
      () => rings.read(
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer(
      (_) async => [
        ArchivedRing(
          entry: RingLogEntry(
            at: DateTime(2026, 10, 3, 7),
            packageId: pkg,
            kind: RingLogKind.rang,
          ),
          label: '출근',
        ),
        ArchivedRing(
          entry: RingLogEntry(
            at: DateTime(2026, 10, 3, 7, 12),
            packageId: pkg,
            kind: RingLogKind.stopped,
          ),
          label: '출근',
        ),
      ],
    );
    final r = await tools.run('wake_records', {
      'from': '2026-10-03',
      'to': '2026-10-03',
    });
    verify(() => archiver.archive()).called(1);
    verify(
      () => rings.read(from: DateTime(2026, 10, 3), to: DateTime(2026, 10, 4)),
    ).called(1);
    final ring = (decode(r)['rings']! as List).single as Map;
    expect(ring['ended_at'], '07:12');
    expect(ring['rang_at'], '07:00');
    expect(ring['end'], 'stopped');
    expect(ring['alarm'], '출근');
    expect(ring['date'], '2026-10-03');
  });

  test('모르는 도구는 unknown_tool', () async {
    final r = await tools.run('nope', {});
    expect(r.isError, isTrue);
    expect(decode(r), {'error': 'unknown_tool'});
  });

  group('summary', () {
    test('search_diary 는 보낸 일기 수를 센다', () async {
      stubSearch([for (var i = 0; i < 5; i++) _entry('e$i')]);
      final r = await tools.run('search_diary', {
        'from': '2026-10-01',
        'to': '2026-10-05',
      });
      expect(r.summary?.kind, ChatToolKind.searchDiary);
      expect(r.summary?.count, 5);
      expect(r.summary?.isError, isFalse);
    });

    test('search_diary 가 50개를 넘어도 보낸 50개를 센다', () async {
      stubSearch([for (var i = 0; i < 51; i++) _entry('e$i')]);
      final r = await tools.run('search_diary', {
        'from': '2026-10-01',
        'to': '2026-10-05',
      });
      expect(r.summary?.count, 50);
    });

    test('0개면 count 0 이고 isError 아님', () async {
      stubSearch([]);
      final r = await tools.run('search_diary', {
        'from': '2026-10-01',
        'to': '2026-10-05',
      });
      expect(r.summary?.count, 0);
      expect(r.summary?.isError, isFalse);
    });

    test('view_entry_photos 는 붙인 사진 수', () async {
      when(
        () => diary.entry('a'),
      ).thenAnswer((_) async => Ok(_entry('a', media: [_photo(1), _photo(2)])));
      final r = await tools.run('view_entry_photos', {'entry_id': 'a'});
      expect(r.summary?.kind, ChatToolKind.viewPhotos);
      expect(r.summary?.count, 2);
    });

    test('list_diary_index 는 스토리 수', () async {
      when(
        () => diary.watchStoryMatches('', dailyTitle: any(named: 'dailyTitle')),
      ).thenAnswer(
        (_) => Stream.value([
          for (var i = 0; i < 4; i++) (story: _story('s$i', 't$i'), count: 1),
        ]),
      );
      when(
        () => diary.watchTagCounts(limit: any(named: 'limit')),
      ).thenAnswer((_) => Stream.value([]));
      when(
        () => diary.watchPlaceCounts(limit: any(named: 'limit')),
      ).thenAnswer((_) => Stream.value([]));
      final r = await tools.run('list_diary_index', {});
      expect(r.summary?.kind, ChatToolKind.diaryIndex);
      expect(r.summary?.count, 4);
    });

    test('daily_steps 는 날 수', () async {
      when(
        () => activity.access(),
      ).thenAnswer((_) async => HealthAccess.granted);
      when(() => activity.dailyActivities(any(), any())).thenAnswer(
        (_) async => Ok([
          for (var i = 1; i <= 7; i++)
            DailyActivity(date: DateTime(2026, 10, i), steps: 100),
        ]),
      );
      final r = await tools.run('daily_steps', {
        'from': '2026-10-01',
        'to': '2026-10-07',
      });
      expect(r.summary?.kind, ChatToolKind.dailySteps);
      expect(r.summary?.count, 7);
    });

    test('wake_records 는 회차 수', () async {
      when(
        () => rings.read(
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer(
        (_) async => [
          for (var d = 1; d <= 3; d++)
            ArchivedRing(
              entry: RingLogEntry(
                at: DateTime(2026, 10, d, 7),
                packageId: packageId(5, triggerIndex(DateTime(2026, 10, d))),
                kind: RingLogKind.rang,
              ),
              label: '출근',
            ),
        ],
      );
      final r = await tools.run('wake_records', {
        'from': '2026-10-01',
        'to': '2026-10-03',
      });
      expect(r.summary?.kind, ChatToolKind.wakeRecords);
      expect(r.summary?.count, 3);
    });

    test('잘못된 기간이면 isError', () async {
      final r = await tools.run('search_diary', {
        'from': '2026-10-05',
        'to': '2026-10-01',
      });
      expect(r.summary?.isError, isTrue);
      expect(r.summary?.count, 0);
      expect(r.summary?.kind, ChatToolKind.searchDiary);
    });

    test('모르는 도구의 오류 요약은 other', () async {
      final r = await tools.run('nope', {});
      expect(r.summary?.kind, ChatToolKind.other);
      expect(r.summary?.isError, isTrue);
    });
  });

  group('inputSummary', () {
    test('from · to 를 날짜로, query 를 trim 해 20자로 자른다', () {
      final s = tools.inputSummary('search_diary', {
        'from': '2026-10-01',
        'to': '2026-10-05',
        'query': '  ${'가' * 25}  ',
      });
      expect(s.kind, ChatToolKind.searchDiary);
      expect(s.from, DateTime(2026, 10, 1));
      expect(s.to, DateTime(2026, 10, 5));
      expect(s.query, '${'가' * 20}…');
      expect(tools.inputSummary('search_diary', {'query': ' 짧음 '}).query, '짧음');
    });

    test('날짜가 잘못이면 from · to 가 null', () {
      final s = tools.inputSummary('daily_steps', {
        'from': '2026-13-45',
        'to': 3,
      });
      expect(s.from, isNull);
      expect(s.to, isNull);
    });

    test('search_diary 가 아니면 query 가 null', () {
      final s = tools.inputSummary('daily_steps', {
        'from': '2026-10-01',
        'to': '2026-10-05',
        'query': '글자',
      });
      expect(s.query, isNull);
      expect(s.kind, ChatToolKind.dailySteps);
    });
  });
}
