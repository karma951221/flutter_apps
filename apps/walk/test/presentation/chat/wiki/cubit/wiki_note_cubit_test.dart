import 'package:flutter_test/flutter_test.dart';
import 'package:walk/presentation/chat/wiki/cubit/wiki_note_cubit.dart';

import '../../../../support/fake_wiki_repository.dart';
import '../wiki_fakes.dart';

void main() {
  late MemoryWikiRepository wiki;

  tearDown(() => wiki.close());

  final source = wikiNote(
    5,
    title: '수면 패턴',
    body: '[[3]] 출근 알람으로 깬다. [[9]] 근거: [[일기:e1]] [[일기:e2]] [[일기:gone]]',
  ).copyWith(sourceConversationId: 'c1');

  test('링크된 메모 · 일기(휴지통 제외) · 역링크 · 출처 존재를 읽는다', () async {
    final alarm = wikiNote(3, title: '출근 알람', body: '관련: [[5]]');
    final other = wikiNote(4, title: '다른 메모');
    wiki = MemoryWikiRepository([source, other, alarm]);
    final e1 = wikiEntry('e1');
    final diary = EntryOnlyDiary([e1, wikiEntry('e2', trashed: true)]);
    final cubit = WikiNoteCubit(
      wiki,
      diary,
      ExistsOnlyHistory({'c1'}),
      id: 5,
    );
    addTearDown(cubit.close);
    expect(cubit.state.loading, isTrue);

    await pumpEventQueue();
    final s = cubit.state;
    expect(s.loading, isFalse);
    expect(s.note, source);
    expect(s.linkedNotes, {3: alarm});
    expect(s.linkedEntries, {'e1': e1});
    expect(s.backlinks, [alarm]);
    expect(s.sourceExists, isTrue);
    expect(s.deleted, isFalse);
  });

  test('출처 대화가 지워졌으면 sourceExists false', () async {
    wiki = MemoryWikiRepository([source]);
    final cubit = WikiNoteCubit(
      wiki,
      EntryOnlyDiary(),
      ExistsOnlyHistory(),
      id: 5,
    );
    addTearDown(cubit.close);
    await pumpEventQueue();
    expect(cubit.state.sourceExists, isFalse);
  });

  test('메모가 바뀌면 다시 읽는다', () async {
    wiki = MemoryWikiRepository([source]);
    final cubit = WikiNoteCubit(
      wiki,
      EntryOnlyDiary(),
      ExistsOnlyHistory(),
      id: 5,
    );
    addTearDown(cubit.close);
    await pumpEventQueue();
    expect(cubit.state.linkedNotes, isEmpty);

    final alarm = wikiNote(3, title: '출근 알람');
    wiki.stored = [source.copyWith(body: '[[3]] 만'), alarm];
    wiki.changed();
    await pumpEventQueue();
    expect(cubit.state.note!.body, '[[3]] 만');
    expect(cubit.state.linkedNotes, {3: alarm});
  });

  test('지워지면 deleted', () async {
    wiki = MemoryWikiRepository([source]);
    final cubit = WikiNoteCubit(
      wiki,
      EntryOnlyDiary(),
      ExistsOnlyHistory(),
      id: 5,
    );
    addTearDown(cubit.close);
    await pumpEventQueue();

    await cubit.delete();
    await pumpEventQueue();
    expect(wiki.deleted, [5]);
    expect(cubit.state.deleted, isTrue);
  });
}
