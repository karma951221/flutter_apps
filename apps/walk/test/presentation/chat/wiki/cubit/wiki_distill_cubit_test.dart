import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/chat/chat_vendor.dart';
import 'package:walk/domain/chat/entity/conversation.dart';
import 'package:walk/domain/chat/entity/wiki_note.dart';
import 'package:walk/domain/chat/usecase/chat_session.dart';
import 'package:walk/domain/chat/usecase/wiki_distiller.dart';
import 'package:walk/presentation/chat/wiki/cubit/wiki_distill_cubit.dart';
import 'package:walk/presentation/chat/wiki/cubit/wiki_distill_state.dart';

import '../../../../support/fake_wiki_repository.dart';
import '../wiki_fakes.dart';

class _MockDistiller extends Mock implements WikiDistiller {}

ChatTurnRecord turn(List<String> cited) => ChatTurnRecord(
  conversationId: 'c1',
  seq: 1,
  question: '요즘 몇 시에 일어나?',
  answer: '7시',
  citedEntryIds: cited,
  stopped: false,
  vendor: ChatVendor.anthropic,
  model: 'claude-x',
  askedAt: DateTime(2026, 11, 1),
);

void main() {
  late _MockDistiller distiller;
  late MemoryWikiRepository wiki;
  late ExistsOnlyHistory history;
  late EntryOnlyDiary diary;

  const created = WikiCandidate.create(
    title: '기상 시간',
    summary: '평일 7시',
    body: '평일엔 7시 [[일기:e1]]',
  );
  const updated = WikiCandidate.update(
    id: 3,
    title: '수면',
    summary: '늦게 잔다',
    body: '자정 넘어 잔다',
  );

  setUp(() {
    distiller = _MockDistiller();
    wiki = MemoryWikiRepository([wikiNote(3, body: '예전 본문')]);
    history = ExistsOnlyHistory(
      {'c1'},
      {
        'c1': [
          turn(['e1', 'e2', 'e1']),
        ],
      },
    );
    diary = EntryOnlyDiary([wikiEntry('e1'), wikiEntry('e2', trashed: true)]);
  });

  tearDown(() => wiki.close());

  void distills(WikiDistillResult result) => when(
    () => distiller.distill(
      conversationId: any(named: 'conversationId'),
      target: any(named: 'target'),
    ),
  ).thenAnswer((_) async => result);

  WikiDistillCubit build() {
    final cubit = WikiDistillCubit(
      distiller,
      wiki,
      history,
      diary,
      conversationId: 'c1',
      target: claudeTarget,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  Future<WikiDistillReady> ready(WikiDistillCubit cubit) async {
    final state = await cubit.stream.firstWhere(
      (s) => s is! WikiDistillLoading,
    );
    return state as WikiDistillReady;
  }

  test('생성하면 loading 뒤 ready(후보)', () async {
    distills(const WikiDistillResult.candidates([created]));
    final cubit = build();
    expect(cubit.state, const WikiDistillState.loading());

    final state = await ready(cubit);
    expect(state.items.single.candidate, created);
    expect(state.items.single.status, CandidateStatus.pending);
    expect(state.items.single.current, isNull);
    // 근거 일기는 살아 있는 것만, 순서대로 한 번씩.
    expect(state.citedEntryIds, ['e1', 'e2']);
    expect(state.entries.keys, ['e1']);
    verify(
      () => distiller.distill(conversationId: 'c1', target: claudeTarget),
    ).called(1);
  });

  test('update 후보는 지금 메모를 current 로', () async {
    distills(const WikiDistillResult.candidates([updated]));
    final state = await ready(build());
    expect(state.items.single.current?.id, 3);
    expect(state.items.single.current?.body, '예전 본문');
    expect(state.notes.keys, [3]);
  });

  test('그새 지워진 메모를 고치는 후보는 새 메모 후보로', () async {
    distills(
      const WikiDistillResult.candidates([
        WikiCandidate.update(id: 9, title: '없는', summary: '요약', body: '본문'),
      ]),
    );
    final state = await ready(build());
    expect(
      state.items.single.candidate,
      const WikiCandidate.create(title: '없는', summary: '요약', body: '본문'),
    );
    expect(state.items.single.current, isNull);
  });

  test('후보 본문 · 지금 본문이 가리키는 살아 있는 일기도 entries 에', () async {
    wiki.stored = [wikiNote(3, body: '예전 [[일기:e3]]')];
    diary.entries['e3'] = wikiEntry('e3');
    diary.entries['e4'] = wikiEntry('e4');
    distills(
      const WikiDistillResult.candidates([
        WikiCandidate.create(title: 't', summary: 's', body: '[[일기:e4]]'),
        updated,
      ]),
    );
    final state = await ready(build());
    expect(state.entries.keys.toSet(), {'e1', 'e3', 'e4'});
    // 일기 고르기 위쪽은 대화의 근거만.
    expect(state.citedEntryIds, ['e1', 'e2']);
  });

  test('저장 중인 카드는 discard · markSaved 를 받지 않는다', () async {
    distills(const WikiDistillResult.candidates([created]));
    final cubit = build();
    await ready(cubit);

    final saving = cubit.save(0);
    cubit
      ..discard(0)
      ..markSaved(0);
    expect(
      (cubit.state as WikiDistillReady).items.single.status,
      CandidateStatus.pending,
    );
    await saving;
    expect(
      (cubit.state as WikiDistillReady).items.single.status,
      CandidateStatus.saved,
    );
    expect(wiki.created, hasLength(1));
  });

  test('save(create) 는 출처를 이 대화로 create', () async {
    distills(const WikiDistillResult.candidates([created, updated]));
    final cubit = build();
    await ready(cubit);

    await cubit.save(0);
    expect(wiki.created, [
      const WikiNoteDraft(
        title: '기상 시간',
        summary: '평일 7시',
        body: '평일엔 7시 [[일기:e1]]',
        sourceConversationId: 'c1',
      ),
    ]);
    expect(wiki.updated, isEmpty);
    final items = (cubit.state as WikiDistillReady).items;
    expect(items[0].status, CandidateStatus.saved);
    expect(items[1].status, CandidateStatus.pending);
    expect(cubit.savedCount, 1);
  });

  test('save(update) 는 그 id 로 update', () async {
    distills(const WikiDistillResult.candidates([updated]));
    final cubit = build();
    await ready(cubit);

    await cubit.save(0);
    expect(wiki.created, isEmpty);
    expect(wiki.updated, [
      (3, const WikiNoteDraft(title: '수면', summary: '늦게 잔다', body: '자정 넘어 잔다')),
    ]);
    expect(
      (cubit.state as WikiDistillReady).items.single.status,
      CandidateStatus.saved,
    );
  });

  test('저장이 실패하면 던지고 후보는 그대로', () async {
    distills(const WikiDistillResult.candidates([created]));
    final cubit = build();
    await ready(cubit);
    wiki.failWrites = true;

    await expectLater(cubit.save(0), throwsA(isA<StateError>()));
    expect(
      (cubit.state as WikiDistillReady).items.single.status,
      CandidateStatus.pending,
    );
  });

  test('discard · markSaved 는 상태만', () async {
    distills(const WikiDistillResult.candidates([created, updated]));
    final cubit = build();
    await ready(cubit);

    cubit
      ..discard(0)
      ..markSaved(1);
    final items = (cubit.state as WikiDistillReady).items;
    expect(items.map((i) => i.status), [
      CandidateStatus.discarded,
      CandidateStatus.saved,
    ]);
    expect(wiki.created, isEmpty);
    expect(wiki.updated, isEmpty);
    expect(cubit.savedCount, 1);
  });

  test('모두 처리하면 allHandled', () async {
    distills(const WikiDistillResult.candidates([created, updated]));
    final cubit = build();
    await ready(cubit);
    expect(cubit.allHandled, isFalse);

    cubit.discard(0);
    expect(cubit.allHandled, isFalse);
    await cubit.save(1);
    expect(cubit.allHandled, isTrue);
  });

  test('failed · unparsable 을 그대로', () async {
    distills(const WikiDistillResult.failed(ChatFailure.noKey));
    final failed = build();
    expect(
      await failed.stream.first,
      const WikiDistillState.failed(ChatFailure.noKey),
    );

    distills(const WikiDistillResult.unparsable());
    final unparsable = build();
    expect(await unparsable.stream.first, const WikiDistillState.unparsable());
  });

  test('loading 중에 닫으면 distiller.cancel', () async {
    final pending = Completer<WikiDistillResult>();
    when(
      () => distiller.distill(
        conversationId: any(named: 'conversationId'),
        target: any(named: 'target'),
      ),
    ).thenAnswer((_) => pending.future);
    final cubit = build();
    await cubit.close();
    verify(() => distiller.cancel()).called(1);
    pending.complete(const WikiDistillResult.cancelled());
  });

  test('toString 에 후보 글이 없다', () async {
    distills(const WikiDistillResult.candidates([created, updated]));
    final state = await ready(build());
    final text = state.toString();
    for (final secret in ['기상 시간', '평일엔 7시', '자정 넘어', '예전 본문', '한강']) {
      expect(text, isNot(contains(secret)));
    }
  });
}
