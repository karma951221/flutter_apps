import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/chat/chat_history_settings.dart';
import 'package:walk/domain/chat/tool/wiki_tools.dart';
import 'package:walk/domain/chat/wiki/wiki_context_policy.dart';
import 'package:walk/domain/chat/wiki/wiki_index.dart';

import '../../../support/fake_chat_history.dart';
import '../../../support/fake_wiki_repository.dart';

void main() {
  late FakeWikiRepository wiki;
  late FakeChatHistorySettings settings;
  late IndexAndReadPolicy policy;

  setUp(() {
    wiki = FakeWikiRepository();
    settings = FakeChatHistorySettings();
    policy = IndexAndReadPolicy(wiki, settings);
  });

  test('메모가 없으면 none(위키 절 · 도구 없음)', () async {
    final context = await policy.build(question: '안녕');

    expect(context, WikiContext.none);
    expect(context.systemSection, isNull);
    expect(context.tools, isEmpty);
  });

  test('있으면 절에 <wiki_index> 와 read_wiki 안내, tools 는 read_wiki 하나', () async {
    wiki.stored = [
      wikiNote(7, title: '출근 알람', summary: '라벨이 출근인 알람'),
      wikiNote(3),
    ];

    final context = await policy.build(question: '알람');

    expect(
      context.systemSection,
      '사용자가 정리해 둔 위키가 있다. 아래는 색인(id · 제목 · 한 줄 요약)이다.\n'
      '질문에 도움이 될 때만 read_wiki 로 본문을 열고, 본문의 [[id]] 링크를 따라 더 열 수 있다.\n'
      '본문의 [[일기:<id>]] 는 일기 기록이다 — read_wiki 가 날짜를 주니 원본이 필요하면 그 날짜로 search_diary 를 부른다.\n'
      '위키와 기록 도구로 찾은 내용이 다르면 기록을 우선하고 다르다고 말한다.\n'
      '<wiki_index>\n'
      '[[7]] 출근 알람 — 라벨이 출근인 알람\n'
      '[[3]] 메모3 — 요약3\n'
      '</wiki_index>',
    );
    expect(context.tools, [WikiTools.spec]);
    expect(context.tools.single.name, 'read_wiki');
  });

  test('indexNotes · indexChars 가 buildWikiIndex 와 같다', () async {
    wiki.stored = [for (var id = 200; id >= 1; id--) wikiNote(id)];

    final context = await policy.build(question: 'q');
    final index = buildWikiIndex(wiki.stored, WikiIndexSize.standard);

    expect(context.indexNotes, index.includedIds.length);
    expect(context.indexNotes, 150);
    expect(context.indexChars, index.chars);
  });

  test('설정을 small 로 바꾸면 다음 build 부터 50개', () async {
    wiki.stored = [for (var id = 80; id >= 1; id--) wikiNote(id)];

    expect((await policy.build(question: 'q')).indexNotes, 80);

    await settings.setWikiIndexSize(WikiIndexSize.small);

    final context = await policy.build(question: 'q');
    expect(context.indexNotes, 50);
    expect(context.systemSection, contains('(오래된 메모 30개 생략)'));
  });

  test('NoWikiPolicy 는 저장소를 읽지 않고 none', () async {
    wiki.stored = [wikiNote(1)];

    final context = await const NoWikiPolicy().build(question: 'q');

    expect(context, WikiContext.none);
    expect(wiki.allCalls, 0);
  });
}
