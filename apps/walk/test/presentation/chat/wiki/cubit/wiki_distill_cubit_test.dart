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
