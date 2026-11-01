import 'dart:convert';

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/chat/tool/tool_summary.dart';
import 'package:walk/domain/chat/tool/wiki_tools.dart';
import 'package:walk/domain/diary/entity/diary_entry.dart';
import 'package:walk/domain/diary/repository/diary_repository.dart';

import '../../../support/fake_wiki_repository.dart';

class _Diary extends Mock implements DiaryRepository {}

DiaryEntry _entry(String id, {DateTime? deletedAt}) => DiaryEntry(
  id: id,
  storyId: 'daily',
  body: '본문',
  occurredAt: DateTime(2026, 10, 3, 23, 30),
  createdAt: DateTime(2026, 10, 3),
  updatedAt: DateTime(2026, 10, 3),
  deletedAt: deletedAt,
  media: const [],
  tags: const [],
);

Map<String, dynamic> _json(String s) => jsonDecode(s) as Map<String, dynamic>;

void main() {
  late FakeWikiRepository wiki;
  late _Diary diary;
  late WikiTools tools;

  setUp(() {
    wiki = FakeWikiRepository([
      for (var id = 1; id <= 8; id++)
        wikiNote(id, updatedAt: DateTime(2026, 10, id, 22)),
    ]);
    diary = _Diary();
    when(
      () => diary.entry(any()),
    ).thenAnswer((_) async => const Err(Failure.notFound()));
    tools = WikiTools(wiki, diary);
  });

  test('ids 의 메모를 id · 제목 · 요약 · 본문 · updated 와 함께 준다', () async {
    wiki.stored = [
      wikiNote(
        3,
        title: '출근 알람',
        summary: '라벨이 출근',
        body: '평일 7시',
        updatedAt: DateTime(2026, 10, 5, 23, 59),
      ),
    ];

    final r = await tools.readWiki({
      'ids': [3],
    });

    expect(r.isError, isFalse);
    expect(_json(r.json), {
      'notes': [
        {
          'id': 3,
          'title': '출근 알람',
          'summary': '라벨이 출근',
          'body': '평일 7시',
          'links': <Object?>[],
          'diary': <Object?>[],
          'updated': '2026-10-05',
        },
      ],
    });
    expect(r.summary, const ToolSummary(kind: ChatToolKind.wiki, count: 1));
  });

  test('없는 id 는 {id, error: not_found}', () async {
    final r = await tools.readWiki({
      'ids': [2, 99],
    });

    final notes = _json(r.json)['notes'] as List;
    expect((notes[0] as Map)['id'], 2);
    expect(notes[1], {'id': 99, 'error': 'not_found'});
    expect(r.isError, isFalse);
    expect(r.summary?.count, 1);
  });

  test('6개를 주면 앞 5개만 읽고 skipped 에 나머지', () async {
    final r = await tools.readWiki({
      'ids': [1, 2, 3, 4, 5, 6, 7],
    });

    final json = _json(r.json);
    expect(
      [for (final n in json['notes'] as List) (n as Map)['id']],
      [1, 2, 3, 4, 5],
    );
    expect(json['skipped'], [6, 7]);
    expect(WikiTools.maxIdsPerCall, 5);
  });

  test('skipped 는 넘칠 때만', () async {
    final r = await tools.readWiki({
      'ids': [1],
    });
    expect(_json(r.json).containsKey('skipped'), isFalse);
  });

  test('"3,7" · ["3"] 도 받는다', () async {
    final csv = await tools.readWiki({'ids': '3,7'});
    expect([for (final n in _json(csv.json)['notes'] as List) n['id']], [3, 7]);

    final strings = await tools.readWiki({
      'ids': ['3'],
    });
    expect(
      [for (final n in _json(strings.json)['notes'] as List) n['id']],
      [3],
    );

    final single = await tools.readWiki({'ids': 4});
    expect([for (final n in _json(single.json)['notes'] as List) n['id']], [4]);
  });

  test('빈 ids · 숫자 아님은 isError invalid_ids', () async {
    for (final input in <Map<String, Object?>>[
      {'ids': <Object?>[]},
      {},
      {'ids': 'abc'},
      {
        'ids': ['x'],
      },
      {
        'ids': [1.5],
      },
      {'ids': ''},
      {
        'ids': [
          {'id': 1},
        ],
      },
    ]) {
      final r = await tools.readWiki(input);
      expect(r.isError, isTrue, reason: '$input');
      expect(_json(r.json), {'error': 'invalid_ids'}, reason: '$input');
      expect(r.summary?.isError, isTrue);
      expect(r.summary?.kind, ChatToolKind.wiki);
    }
  });

  test('본문 링크 — 있는 메모는 {id, title}, 지워진 메모는 {id, missing: true}', () async {
    wiki.stored = [
      wikiNote(1, body: '[[2]] 와 [[42]] 참고, 다시 [[2]]'),
      wikiNote(2, title: '산책 코스'),
    ];

    final r = await tools.readWiki({
      'ids': [1],
    });

    final note = (_json(r.json)['notes'] as List).single as Map;
    expect(note['links'], [
      {'id': 2, 'title': '산책 코스'},
      {'id': 42, 'missing': true},
    ]);
  });

  test('일기 링크 — 있으면 날짜, 휴지통 · 없음이면 missing', () async {
    wiki.stored = [wikiNote(1, body: '[[일기:a]] [[일기:b]] [[일기:c]]')];
    when(() => diary.entry('a')).thenAnswer((_) async => Ok(_entry('a')));
    when(() => diary.entry('b')).thenAnswer(
      (_) async => Ok(_entry('b', deletedAt: DateTime(2026, 10, 4))),
    );

    final r = await tools.readWiki({
      'ids': [1],
    });

    final note = (_json(r.json)['notes'] as List).single as Map;
    expect(note['diary'], [
      {'entry_id': 'a', 'date': '2026-10-03'},
      {'entry_id': 'b', 'missing': true},
      {'entry_id': 'c', 'missing': true},
    ]);
  });

  test('entryIds 는 비어 있다', () async {
    wiki.stored = [wikiNote(1, body: '[[일기:a]]')];
    when(() => diary.entry('a')).thenAnswer((_) async => Ok(_entry('a')));

    final r = await tools.readWiki({
      'ids': [1],
    });

    expect(r.entryIds, isEmpty);
    expect(r.images, isEmpty);
  });

  test('spec 이름은 read_wiki, ids 는 integer 배열이고 required', () {
    expect(WikiTools.readWikiName, 'read_wiki');
    expect(WikiTools.spec.name, 'read_wiki');
    final params = WikiTools.spec.parameters;
    expect(params['type'], 'object');
    final ids = (params['properties']! as Map)['ids'] as Map;
    expect(ids['type'], 'array');
    expect(ids['items'], {'type': 'integer'});
    expect(ids['description'], isA<String>());
    expect(params['required'], ['ids']);
  });

  test('read_wiki 이름은 ChatToolKind.wiki', () {
    expect(chatToolKindOf('read_wiki'), ChatToolKind.wiki);
  });
}
