import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/chat/entity/wiki_note.dart';
import 'package:walk/presentation/chat/wiki/cubit/wiki_edit_cubit.dart';
import 'package:walk/presentation/chat/wiki/cubit/wiki_edit_state.dart';

import '../../../../support/fake_wiki_repository.dart';
import '../wiki_fakes.dart';

void main() {
  late MemoryWikiRepository wiki;

  tearDown(() => wiki.close());

  const empty = WikiEditSeed(title: '', summary: '', body: '');

  test('새 메모 save 는 create, 기존은 update', () async {
    wiki = MemoryWikiRepository([wikiNote(3)]);
    final fresh = WikiEditCubit(
      wiki,
      seed: empty.copyWith(sourceConversationId: 'c1'),
    );
    addTearDown(fresh.close);
    final id = await fresh.save(title: ' 수면 ', summary: '7시 기상', body: '본문');
    expect(id, 4);
    expect(wiki.created, [
      const WikiNoteDraft(
        title: '수면',
        summary: '7시 기상',
        body: '본문',
        sourceConversationId: 'c1',
      ),
    ]);
    expect(fresh.state.saving, isFalse);
    expect(fresh.state.error, isNull);

    final existing = WikiEditCubit(
      wiki,
      seed: WikiEditSeed.fromNote(wikiNote(3)),
    );
    addTearDown(existing.close);
    expect(await existing.save(title: '새 제목', summary: '새 요약', body: ''), 3);
    expect(wiki.updated.single.$1, 3);
    expect(wiki.updated.single.$2.title, '새 제목');
    expect(wiki.created, hasLength(1));
  });

  test('제목 · 요약이 비면 error 만, 저장소를 부르지 않는다', () async {
    wiki = MemoryWikiRepository();
    final cubit = WikiEditCubit(wiki, seed: empty);
    addTearDown(cubit.close);

    expect(await cubit.save(title: '  ', summary: '요약', body: ''), isNull);
    expect(cubit.state.error, WikiEditError.emptyTitle);
    expect(await cubit.save(title: '제목', summary: ' \n', body: ''), isNull);
    expect(cubit.state.error, WikiEditError.emptySummary);
    expect(wiki.created, isEmpty);
    expect(wiki.updated, isEmpty);
  });

  test('저장소가 던지면 saveFailed', () async {
    wiki = MemoryWikiRepository()..failWrites = true;
    final cubit = WikiEditCubit(wiki, seed: empty);
    addTearDown(cubit.close);

    expect(await cubit.save(title: '제목', summary: '요약', body: ''), isNull);
    expect(cubit.state.error, WikiEditError.saveFailed);
    expect(cubit.state.saving, isFalse);
  });

  test('changed 는 쓰던 글을 seed 에 남기고 오류를 지운다', () async {
    wiki = MemoryWikiRepository();
    final cubit = WikiEditCubit(wiki, seed: empty);
    addTearDown(cubit.close);
    await cubit.save(title: '', summary: '', body: '');
    expect(cubit.state.error, WikiEditError.emptyTitle);

    cubit.changed(title: '수면', body: '본문');
    expect(cubit.state.seed.title, '수면');
    expect(cubit.state.seed.body, '본문');
    expect(cubit.state.seed.summary, '');
    expect(cubit.state.error, isNull);
  });

  test('fromBubble 은 제목 · 첫 줄 요약 · 본문 · 출처 · 인용 id 를 채운다', () {
    final seed = WikiEditSeed.fromBubble(
      question: '요즘   몇 시에\n일어나?',
      text: '  평일엔 7시쯤 일어나요.\n주말엔 늦어요.  ',
      conversationId: 'c1',
      citedEntryIds: ['e1', 'e2'],
    );
    expect(seed.id, isNull);
    expect(seed.title, '요즘 몇 시에 일어나?');
    expect(seed.summary, '평일엔 7시쯤 일어나요.');
    expect(seed.body, '평일엔 7시쯤 일어나요.\n주말엔 늦어요.');
    expect(seed.sourceConversationId, 'c1');
    expect(seed.suggestedEntryIds, ['e1', 'e2']);

    final long = WikiEditSeed.fromBubble(
      question: '질문',
      text: '${'가' * 130}\n둘째 줄',
      conversationId: null,
      citedEntryIds: const [],
    );
    expect(long.summary, '가' * wikiSummaryMax);
    expect(long.sourceConversationId, isNull);
  });

  test('fromNote 는 메모 값을 그대로, toString 에 글이 없다', () {
    final note = wikiNote(
      7,
      title: '비밀 제목',
      summary: '비밀 요약',
      body: '비밀 본문',
    ).copyWith(sourceConversationId: 'c2');
    final seed = WikiEditSeed.fromNote(note);
    expect(seed.id, 7);
    expect(seed.title, '비밀 제목');
    expect(seed.summary, '비밀 요약');
    expect(seed.body, '비밀 본문');
    expect(seed.sourceConversationId, 'c2');
    expect(seed.suggestedEntryIds, isEmpty);
    final state = WikiEditState(seed: seed);
    expect(state.toString(), isNot(contains('비밀')));
  });
}
