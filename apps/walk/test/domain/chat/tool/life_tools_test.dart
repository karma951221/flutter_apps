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
import 'package:walk/domain/chat/tool/chat_image_source.dart';
import 'package:walk/domain/chat/tool/life_tools.dart';
import 'package:walk/domain/chat/tool/tool_result.dart';
import 'package:walk/domain/diary/entity/diary_entry.dart';
import 'package:walk/domain/diary/entity/entry_location.dart';
import 'package:walk/domain/diary/entity/entry_media.dart';
import 'package:walk/domain/diary/repository/diary_repository.dart';
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
  List<EntryMedia> media = const [],
  String body = '본문',
}) => DiaryEntry(
  id: id,
  storyId: 'daily',
  body: body,
  occurredAt: DateTime(2026, 10, 3, 9, 5),
  createdAt: DateTime(2026, 10, 3, 9, 5),
  updatedAt: DateTime(2026, 10, 3, 9, 5),
  location: const EntryLocation(placeName: '공원'),
  media: media,
  tags: const ['산책'],
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

  test('definitions 에 다섯 도구가 있고 각자 input_schema 가 object 다', () {
    final defs = tools.definitions;
    expect(defs.map((d) => d['name']), [
      'search_diary',
      'view_entry_photos',
      'list_diary_index',
      'daily_steps',
      'wake_records',
    ]);
    for (final d in defs) {
      expect((d['input_schema']! as Map)['type'], 'object');
      expect(d['description'], isNotEmpty);
    }
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
}
