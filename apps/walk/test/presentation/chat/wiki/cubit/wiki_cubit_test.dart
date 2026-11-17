import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/chat/chat_history_settings.dart';
import 'package:walk/domain/chat/wiki/wiki_index.dart';
import 'package:walk/presentation/chat/wiki/cubit/wiki_cubit.dart';

import '../../../../support/fake_chat_history.dart';
import '../../../../support/fake_wiki_repository.dart';
import '../wiki_fakes.dart';

void main() {
  late MemoryWikiRepository wiki;
  late FakeChatHistorySettings settings;

  /// 최근 순 메모 [n] 개(id 가 클수록 최근).
  List<int> recentIds(int n) => [for (var id = n; id >= 1; id--) id];

  const debounce = Duration(milliseconds: 5);

  WikiCubit make({int pageSize = 30}) {
    final cubit = WikiCubit(
      wiki,
      settings,
      pageSize: pageSize,
      debounce: debounce,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  /// 디바운스가 지나고 새 구독이 첫 값을 낼 때까지.
  Future<void> settle() async {
    await Future<void>.delayed(debounce * 2);
    await pumpEventQueue();
  }

  setUp(() {
    settings = FakeChatHistorySettings();
  });

  tearDown(() => wiki.close());

  test('첫 쪽만 읽고, 색인 표시는 전체 기준 buildWikiIndex 와 같다', () async {
    final notes = [for (final id in recentIds(60)) wikiNote(id)];
    wiki = MemoryWikiRepository(notes);
    settings.wikiIndexSize = WikiIndexSize.small;
    final cubit = make(pageSize: 20);
    expect(cubit.state.loading, isTrue);

    await pumpEventQueue();
    final full = buildWikiIndex(notes, WikiIndexSize.small);
    expect(cubit.state.loading, isFalse);
    expect(cubit.state.notes, notes.take(20).toList());
    expect(cubit.state.hasMore, isTrue);
    expect(cubit.state.total, 60);
    expect(cubit.state.size, WikiIndexSize.small);
    expect(cubit.state.indexedIds, full.includedIds.toSet());
    expect(cubit.state.indexChars, full.chars);
    expect(cubit.state.notIndexed, 10);
    // 색인 쪽은 색인 창만큼만 읽는다.
    expect(
      wiki.watchNotesCalls,
      contains(('', wikiIndexWindow(WikiIndexSize.small))),
    );

    wiki.stored = notes.take(3).toList();
    wiki.changed();
    await pumpEventQueue();
    expect(cubit.state.notes, hasLength(3));
    expect(cubit.state.hasMore, isFalse);
    expect(cubit.state.indexedIds, {60, 59, 58});
    expect(cubit.state.notIndexed, 0);
  });

  test('loadMore 는 다음 쪽까지 늘리고, 끝이면 아무것도 하지 않는다', () async {
    wiki = MemoryWikiRepository([for (final id in recentIds(25)) wikiNote(id)]);
    final cubit = make(pageSize: 10);
    await pumpEventQueue();
    expect(cubit.state.notes, hasLength(10));

    cubit.loadMore();
    expect(cubit.state.loadingMore, isTrue);
    await pumpEventQueue();
    expect(cubit.state.loadingMore, isFalse);
    expect(cubit.state.notes, hasLength(20));
    expect(cubit.state.hasMore, isTrue);

    cubit.loadMore();
    await pumpEventQueue();
    expect(cubit.state.notes, hasLength(25));
    expect(cubit.state.hasMore, isFalse);

    final calls = wiki.watchNotesCalls.length;
    cubit.loadMore();
    await pumpEventQueue();
    expect(wiki.watchNotesCalls, hasLength(calls));
  });

  test('loadMore 를 겹쳐 불러도 한 쪽만 는다', () async {
    wiki = MemoryWikiRepository([for (final id in recentIds(40)) wikiNote(id)]);
    final cubit = make(pageSize: 10);
    await pumpEventQueue();

    cubit
      ..loadMore()
      ..loadMore();
    await pumpEventQueue();

    expect(cubit.state.notes, hasLength(20));
  });

  test('setQuery 는 디바운스 뒤 첫 쪽부터 찾고, 지우면 전체로 돌아온다', () async {
    wiki = MemoryWikiRepository([
      wikiNote(3, title: '출근 알람'),
      wikiNote(2, title: '수면', body: '알람 없이'),
      wikiNote(1, title: '산책'),
    ]);
    final cubit = make(pageSize: 10);
    await pumpEventQueue();

    cubit.setQuery('알람');
    expect(cubit.state.query, '알람');
    await pumpEventQueue();
    // 디바운스 전에는 아직 전체.
    expect(cubit.state.notes, hasLength(3));

    await settle();
    expect(cubit.state.searched, '알람');
    expect([for (final n in cubit.state.notes) n.id], [3, 2]);
    expect(cubit.state.total, 3);

    cubit.setQuery('없는말');
    await settle();
    expect(cubit.state.notes, isEmpty);
    expect(cubit.state.noResults, isTrue);

    cubit.setQuery('  ');
    await settle();
    expect(cubit.state.searched, '');
    expect(cubit.state.notes, hasLength(3));
    expect(cubit.state.noResults, isFalse);
  });

  test('검색을 바꾸면 늘려 둔 쪽 수는 처음으로', () async {
    wiki = MemoryWikiRepository([
      for (final id in recentIds(30)) wikiNote(id, title: '메모 $id'),
    ]);
    final cubit = make(pageSize: 10);
    await pumpEventQueue();
    cubit.loadMore();
    await pumpEventQueue();
    expect(cubit.state.notes, hasLength(20));

    cubit.setQuery('메모');
    await settle();

    expect(cubit.state.notes, hasLength(10));
    expect(wiki.watchNotesCalls.last, ('메모', 11));
  });

  test('목록을 읽지 못하면 failed', () async {
    wiki = MemoryWikiRepository()..failList = true;
    final cubit = make();
    await pumpEventQueue();
    expect(cubit.state.loading, isFalse);
    expect(cubit.state.failed, isTrue);
  });

  test('deleteAll 은 저장소로 넘긴다', () async {
    wiki = MemoryWikiRepository([wikiNote(2), wikiNote(1)]);
    final cubit = make();
    await pumpEventQueue();

    expect(await cubit.deleteAll(), 2);
    expect(wiki.deleteAllCalls, 1);
    await pumpEventQueue();
    expect(cubit.state.notes, isEmpty);
    expect(cubit.state.total, 0);
  });

  test('refreshSize 뒤 indexedIds 가 새 크기로', () async {
    final notes = [for (final id in recentIds(60)) wikiNote(id)];
    wiki = MemoryWikiRepository(notes);
    final cubit = make();
    await pumpEventQueue();
    expect(cubit.state.indexedIds, hasLength(60));

    settings.wikiIndexSize = WikiIndexSize.small;
    cubit.refreshSize();
    expect(cubit.state.size, WikiIndexSize.small);
    await pumpEventQueue();
    expect(cubit.state.indexedIds, hasLength(50));
    expect(cubit.state.indexedIds, isNot(contains(1)));
    expect(
      cubit.state.indexChars,
      buildWikiIndex(notes, WikiIndexSize.small).chars,
    );
  });
}
