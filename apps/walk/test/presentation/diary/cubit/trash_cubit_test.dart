import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/data/diary/prefs_diary_preferences.dart';
import 'package:walk/domain/diary/entity/trash_retention.dart';
import 'package:walk/domain/diary/location/place_source.dart';
import 'package:walk/domain/diary/media/media_store.dart';
import 'package:walk/domain/diary/usecase/diary_use_case.dart';
import 'package:walk/presentation/diary/cubit/trash_cubit.dart';

import '../../../support/diary_fixtures.dart';

class _MockStore extends Mock implements MediaStore {}

class _MockPlaces extends Mock implements PlaceSource {}

void main() {
  late DiaryHarness h;
  late PrefsDiaryPreferences prefs;
  late _MockStore store;
  late TrashCubit cubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = PrefsDiaryPreferences(await SharedPreferences.getInstance());
    h = DiaryHarness();
    store = _MockStore();
    when(() => store.deleteFiles(any())).thenAnswer((_) async {});
    final useCase = DiaryUseCase(
      h.repository,
      store,
      _MockPlaces(),
      prefs,
      h.clock,
    );
    cubit = TrashCubit(h.repository, useCase, prefs, h.clock)..start();
    await pumpEventQueue();
  });

  tearDown(() async {
    await cubit.close();
    await h.close();
  });

  /// 기록을 만들어 [ago] 전에 휴지통으로 보낸 것으로 한다.
  Future<String> trashed(String body, {Duration ago = Duration.zero}) async {
    final entry = okValue(
      await h.repository.createEntry(entryDraft(body: body)),
    );
    final now = h.clock.value;
    h.clock.value = now.subtract(ago);
    await h.trashDirectly(entry.id);
    h.clock.value = now;
    await pumpEventQueue();
    return entry.id;
  }

  List<String> bodies() => [for (final i in cubit.state.items) i.entry.body];

  test('처음에는 비어 있고 읽는 중이 아니다', () {
    expect(cubit.state.items, isEmpty);
    expect(cubit.state.loading, isFalse);
  });

  test('휴지통에 간 시각 최신순', () async {
    await trashed('오래된', ago: const Duration(days: 3));
    await trashed('최근', ago: const Duration(days: 1));
    await trashed('중간', ago: const Duration(days: 2));

    expect(bodies(), ['최근', '중간', '오래된']);
  });

  test('살아 있는 기록은 보이지 않는다', () async {
    okValue(await h.repository.createEntry(entryDraft(body: '살아있음')));
    await trashed('버림');

    expect(bodies(), ['버림']);
  });

  group('남은 일수', () {
    test('7일 보관, 2일 전 삭제 → 5', () async {
      await trashed('a', ago: const Duration(days: 2));
      expect(cubit.state.items.single.daysLeft, 5);
    });

    test('하루가 안 찬 남은 시간은 올림', () async {
      await trashed('a', ago: const Duration(hours: 36));
      // 남은 5.5일 → 6.
      expect(cubit.state.items.single.daysLeft, 6);
    });

    test('기한이 지났으면 0 아래로 내려가지 않는다', () async {
      await trashed('a', ago: const Duration(days: 9));
      expect(cubit.state.items.single.daysLeft, 0);
    });

    test('안 함이면 표시 없음(null)', () async {
      await prefs.setTrashRetention(TrashRetention.never);
      await trashed('a', ago: const Duration(days: 40));
      expect(cubit.state.items.single.daysLeft, isNull);
    });

    test('30일 보관을 따른다', () async {
      await prefs.setTrashRetention(TrashRetention.day30);
      await trashed('a', ago: const Duration(days: 10));
      expect(cubit.state.items.single.daysLeft, 20);
    });
  });

  test('복원하면 휴지통에서 빠진다', () async {
    final id = await trashed('a');
    await cubit.restore(id);
    await pumpEventQueue();

    expect(cubit.state.items, isEmpty);
    expect(cubit.state.actionFailed, isFalse);
    expect(okValue(await h.repository.entry(id)).isTrashed, isFalse);
  });

  test('영구 삭제하면 기록이 사라지고 파일을 지운다', () async {
    final entry = okValue(
      await h.repository.createEntry(
        entryDraft(body: 'a', media: [photoMedia('p1')]),
      ),
    );
    await h.trashDirectly(entry.id);
    await trashed('b');

    await cubit.purge(entry.id);
    await pumpEventQueue();

    expect(bodies(), ['b']);
    verify(() => store.deleteFiles(any())).called(1);
    expect(
      errFailure(await h.repository.entry(entry.id)),
      isA<NotFoundFailure>(),
    );
  });

  test('비우기는 휴지통만 지운다', () async {
    final alive = okValue(
      await h.repository.createEntry(entryDraft(body: '살아')),
    );
    await trashed('a');
    await trashed('b');

    await cubit.emptyAll();
    await pumpEventQueue();

    expect(cubit.state.items, isEmpty);
    expect(okValue(await h.repository.entry(alive.id)).body, '살아');
  });

  test('없는 기록을 복원하면 actionFailed, 다음 동작에서 비운다', () async {
    final id = await trashed('a');
    await cubit.purge(id);
    await cubit.restore(id);
    expect(cubit.state.actionFailed, isTrue);

    await trashed('b');
    await cubit.emptyAll();
    expect(cubit.state.actionFailed, isFalse);
  });
}
