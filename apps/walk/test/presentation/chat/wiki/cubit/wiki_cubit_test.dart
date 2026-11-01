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

  setUp(() {
    settings = FakeChatHistorySettings();
  });

  tearDown(() => wiki.close());

  test('저장소 스트림을 상태로, indexedIds 는 buildWikiIndex 와 같다', () async {
    final notes = [for (final id in recentIds(60)) wikiNote(id)];
    wiki = MemoryWikiRepository(notes);
    settings.wikiIndexSize = WikiIndexSize.small;
    final cubit = WikiCubit(wiki, settings);
    addTearDown(cubit.close);
    expect(cubit.state.loading, isTrue);

    await pumpEventQueue();
    expect(cubit.state.loading, isFalse);
    expect(cubit.state.notes, notes);
    expect(cubit.state.size, WikiIndexSize.small);
    expect(
      cubit.state.indexedIds,
      buildWikiIndex(notes, WikiIndexSize.small).includedIds.toSet(),
    );
    expect(cubit.state.indexedIds, hasLength(50));

    wiki.stored = notes.take(3).toList();
    wiki.changed();
    await pumpEventQueue();
    expect(cubit.state.notes, hasLength(3));
    expect(cubit.state.indexedIds, {60, 59, 58});
  });

  test('목록을 읽지 못하면 failed', () async {
    wiki = MemoryWikiRepository()..failList = true;
    final cubit = WikiCubit(wiki, settings);
    addTearDown(cubit.close);
    await pumpEventQueue();
    expect(cubit.state.loading, isFalse);
    expect(cubit.state.failed, isTrue);
  });

  test('deleteAll 은 저장소로 넘긴다', () async {
    wiki = MemoryWikiRepository([wikiNote(2), wikiNote(1)]);
    final cubit = WikiCubit(wiki, settings);
    addTearDown(cubit.close);
    await pumpEventQueue();

    expect(await cubit.deleteAll(), 2);
    expect(wiki.deleteAllCalls, 1);
    await pumpEventQueue();
    expect(cubit.state.notes, isEmpty);
  });

  test('refreshSize 뒤 indexedIds 가 새 크기로', () async {
    final notes = [for (final id in recentIds(60)) wikiNote(id)];
    wiki = MemoryWikiRepository(notes);
    final cubit = WikiCubit(wiki, settings);
    addTearDown(cubit.close);
    await pumpEventQueue();
    expect(cubit.state.indexedIds, hasLength(60));

    settings.wikiIndexSize = WikiIndexSize.small;
    cubit.refreshSize();
    expect(cubit.state.size, WikiIndexSize.small);
    expect(cubit.state.indexedIds, hasLength(50));
    expect(cubit.state.indexedIds, isNot(contains(1)));
  });
}
