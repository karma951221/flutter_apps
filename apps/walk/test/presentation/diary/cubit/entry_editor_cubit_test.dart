import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:walk/data/diary/drift_diary_repository.dart';
import 'package:walk/data/diary/media/file_media_store.dart';
import 'package:walk/data/diary/prefs_diary_preferences.dart';
import 'package:walk/domain/diary/diary_failure.dart';
import 'package:walk/domain/diary/entity/diary_entry.dart';
import 'package:walk/domain/diary/entity/entry_draft.dart';
import 'package:walk/domain/diary/entity/entry_filter.dart';
import 'package:walk/domain/diary/entity/entry_location.dart';
import 'package:walk/domain/diary/entity/entry_media.dart';
import 'package:walk/domain/diary/entity/story.dart';
import 'package:walk/domain/diary/location/place_lookup.dart';
import 'package:walk/domain/diary/location/place_source.dart';
import 'package:walk/domain/diary/usecase/diary_use_case.dart';
import 'package:walk/presentation/diary/cubit/entry_editor_cubit.dart';

import '../../../support/diary_fixtures.dart';
import '../../../support/fake_media_processor.dart';

/// 지금 위치를 [location] 으로 돌려준다. [gate] 를 주면 그것이 끝날 때까지 붙잡아 둔다.
class _FakePlaceSource implements PlaceSource {
  EntryLocation? location;
  Completer<void>? gate;

  @override
  Future<EntryLocation?> current() async {
    await gate?.future;
    return location;
  }

  @override
  Future<PlaceLookup> nameFor(double lat, double lng) async =>
      const PlaceLookup.offline();
}

/// 겹쳐 실행된 압축 수의 최댓값을 잰다.
class _OverlapProcessor extends FakeMediaProcessor {
  int _active = 0;
  int maxActive = 0;

  @override
  Future<({int width, int height})> compressPhoto(
    File source,
    File target,
  ) async {
    _active++;
    if (_active > maxActive) maxActive = _active;
    await Future<void>.delayed(const Duration(milliseconds: 5));
    try {
      return await super.compressPhoto(source, target);
    } finally {
      _active--;
    }
  }
}

/// 기록 만들기 호출 수를 센다.
class _CountingRepository extends DriftDiaryRepository {
  _CountingRepository(DiaryHarness h)
    : super(h.db, const IdGenerator(Uuid()), h.clock);

  int creates = 0;

  @override
  Future<Result<DiaryEntry>> createEntry(EntryDraft draft) {
    creates++;
    return super.createEntry(draft);
  }
}

const _aewol = EntryLocation(placeName: '애월읍', lat: 33.46, lng: 126.33);

void main() {
  late Directory sandbox;
  late DiaryHarness h;
  late _CountingRepository repo;
  late _OverlapProcessor processor;
  late FileMediaStore media;
  late _FakePlaceSource places;
  late DiaryUseCase useCase;
  late File pickedPhoto;
  late File pickedVideo;
  late List<EntryEditorCubit> cubits;

  setUp(() async {
    sandbox = Directory.systemTemp.createTempSync('entry_editor_cubit_test');
    h = DiaryHarness();
    repo = _CountingRepository(h);
    processor = _OverlapProcessor();
    media = FileMediaStore(
      Directory('${sandbox.path}/diary'),
      const IdGenerator(Uuid()),
      processor,
    );
    places = _FakePlaceSource()..location = _aewol;
    SharedPreferences.setMockInitialValues({});
    final prefs = PrefsDiaryPreferences(await SharedPreferences.getInstance());
    useCase = DiaryUseCase(repo, media, places, prefs, h.clock);
    pickedPhoto = File('${sandbox.path}/picked.jpg')
      ..writeAsBytesSync([1, 2, 3]);
    pickedVideo = File('${sandbox.path}/picked.mp4')
      ..writeAsBytesSync([4, 5, 6]);
    cubits = [];
  });

  tearDown(() async {
    for (final c in cubits) {
      await c.close();
    }
    await h.close();
    sandbox.deleteSync(recursive: true);
  });

  EntryEditorCubit newCubit() {
    final c = EntryEditorCubit(useCase, repo, media, places, h.clock);
    cubits.add(c);
    return c;
  }

  Future<EntryEditorCubit> started() async {
    final c = newCubit();
    await c.startNew();
    return c;
  }

  List<String> filesUnder(String dir) {
    final d = Directory('${sandbox.path}/diary/$dir');
    if (!d.existsSync()) return [];
    return [
      for (final f in d.listSync().whereType<File>())
        '$dir/${f.uri.pathSegments.last}',
    ]..sort();
  }

  ({String path, MediaKind kind}) photo() =>
      (path: pickedPhoto.path, kind: MediaKind.photo);

  ({String path, MediaKind kind}) video() =>
      (path: pickedVideo.path, kind: MediaKind.video);

  /// 10월 7일부터 진행 중인 '제주 여행'. 기본 스토리('일상')가 더 최근에 쓰였다.
  Future<Story> jejuTrip() async {
    final jeju = okValue(
      await h.repository.createStory(
        title: '제주 여행',
        startedAt: DateTime(2026, 10, 7),
      ),
    );
    h.clock.advance(const Duration(minutes: 1));
    okValue(await h.repository.createEntry(entryDraft(occurredAt: diaryT0)));
    h.clock.advance(const Duration(minutes: 1));
    return jeju;
  }

  group('새 기록', () {
    test('기본 스토리는 최근에 쓴 열린 스토리, 시각은 지금, 위치는 지금 위치', () async {
      final jeju = okValue(
        await h.repository.createStory(
          title: '제주 여행',
          startedAt: DateTime(2026, 10, 7),
        ),
      );
      h.clock.advance(const Duration(minutes: 1));
      okValue(await h.repository.createEntry(entryDraft(storyId: jeju.id)));
      h.clock.advance(const Duration(minutes: 1));

      final c = await started();

      expect(c.state.editingId, isNull);
      expect(c.state.draft.storyId, jeju.id);
      expect(c.state.draft.occurredAt, h.clock.now());
      expect(c.state.createdAt, h.clock.now());
      expect(c.state.draft.location, _aewol);
      expect(c.state.locating, isFalse);
      expect(c.state.manualPlace, isFalse);
      expect(
        c.state.openStories.map((s) => s.id),
        containsAll([jeju.id, Story.dailyId]),
      );
    });

    test('기록이 없으면 기본 스토리는 일상', () async {
      final c = await started();

      expect(c.state.draft.storyId, Story.dailyId);
    });

    test('위치를 못 구하면 오류 없이 장소 직접 입력', () async {
      places.location = null;

      final c = await started();

      expect(c.state.draft.location, isNull);
      expect(c.state.manualPlace, isTrue);
      expect(c.state.error, isNull);
    });
  });

  group('시각', () {
    test('초가 있는 시각에 열고 같은 분을 고르면 바꾼 것이 아니다 — 위치 · 지금 유지', () async {
      h.clock.value = DateTime(2026, 10, 10, 15, 24, 37, 500);
      final c = await started();
      final opened = c.state.createdAt;
      expect(opened, DateTime(2026, 10, 10, 15, 24, 37, 500));

      c.setTime(DateTime(2026, 10, 10, 15, 24));

      expect(c.state.timeEdited, isFalse);
      expect(c.state.draft.occurredAt, opened);
      expect(c.state.draft.location, _aewol);
      expect(c.state.manualPlace, isFalse);

      c.setTime(DateTime(2026, 10, 10, 15, 23));
      expect(c.state.timeEdited, isTrue);
      expect(c.state.draft.location, isNull);
    });

    test('과거로 바꾸면 지금 위치를 빼고 장소를 직접 입력한다', () async {
      final c = await started();

      c.setTime(DateTime(2026, 10, 9, 18));

      expect(c.state.draft.occurredAt, DateTime(2026, 10, 9, 18));
      expect(c.state.draft.location, isNull);
      expect(c.state.manualPlace, isTrue);
    });

    test('미래 시각은 무시한다', () async {
      final c = await started();
      final before = c.state;

      c.setTime(h.clock.now().add(const Duration(minutes: 1)));

      expect(c.state, before);
    });

    test('바꾼 시각이 제주 여행 기간이면 그 스토리를, 아니면 일상을 제안한다', () async {
      final jeju = await jejuTrip();
      final c = await started();
      expect(c.state.draft.storyId, Story.dailyId);

      c.setTime(DateTime(2026, 10, 8, 12));
      expect(c.state.draft.storyId, jeju.id);

      c.setTime(DateTime(2026, 10, 6, 12));
      expect(c.state.draft.storyId, Story.dailyId);
    });

    test('되돌리기는 열었던 시각으로', () async {
      final c = await started();
      final opened = c.state.createdAt;

      c.setTime(DateTime(2026, 10, 9, 18));
      c.revertTime();

      expect(c.state.draft.occurredAt, opened);
    });

    test('위치를 찾는 동안 시각을 과거로 바꾸면 늦게 온 위치를 버린다', () async {
      final gate = Completer<void>();
      places.gate = gate;
      final c = newCubit();
      final starting = c.startNew();
      await pumpEventQueue();
      expect(c.state.locating, isTrue);

      c.setTime(DateTime(2026, 10, 9, 18));
      gate.complete();
      await starting;

      expect(c.state.draft.location, isNull);
      expect(c.state.manualPlace, isTrue);
      expect(c.state.locating, isFalse);
    });
  });

  group('태그 · 장소', () {
    test("'#Jeju' 다음 'jeju ' 를 넣어도 칩은 하나", () async {
      final c = await started();

      c.addTag('#Jeju');
      c.addTag('jeju ');
      c.addTag('   ');

      expect(c.state.draft.tags, ['jeju']);
    });

    test('칩 삭제', () async {
      final c = await started();
      c
        ..addTag('제주')
        ..addTag('바다');

      c.removeTag('제주');

      expect(c.state.draft.tags, ['바다']);
    });

    test('위치 빼기 → 위치 없음 + 직접 입력, 이름을 넣으면 좌표 없는 장소', () async {
      final c = await started();

      c.clearLocation();
      expect(c.state.draft.location, isNull);
      expect(c.state.manualPlace, isTrue);

      c.setPlaceName('  협재 해변 ');
      expect(c.state.draft.location, const EntryLocation(placeName: '협재 해변'));

      c.setPlaceName(' ');
      expect(c.state.draft.location, isNull);
    });
  });

  group('미디어', () {
    test('11개를 고르면 10개만 넣고 tooManyMedia', () async {
      final c = await started();

      await c.addMedia(List.generate(11, (_) => photo()));

      expect(c.state.draft.media, hasLength(10));
      expect(c.state.newMedia, hasLength(10));
      expect(c.state.error, DiaryFailure.tooManyMedia);
      expect(processor.photoCalls, hasLength(10));
    });

    test('한 번에 하나씩 차례로 가져온다', () async {
      final c = await started();

      await c.addMedia([photo(), photo(), photo()]);

      expect(processor.maxActive, 1);
      expect(c.state.draft.media, hasLength(3));
    });

    test('31초 영상은 거절하고 videoTooLong', () async {
      processor.durationMs = 31000;
      final c = await started();

      await c.addMedia([video(), photo()]);

      expect(c.state.draft.media.map((m) => m.kind), [MediaKind.photo]);
      expect(c.state.error, DiaryFailure.videoTooLong);
    });

    test('같은 오류가 이어져도 매번 새 상태로 알린다', () async {
      processor.durationMs = 31000;
      final c = await started();
      final errors = <DiaryFailure?>[];
      final sub = c.stream.listen((s) => errors.add(s.error));
      addTearDown(sub.cancel);

      await c.addMedia([video()]);
      await c.addMedia([video()]);
      await pumpEventQueue();

      // 화면은 오류가 없던 상태에서 생길 때 알린다.
      var shown = 0;
      for (var i = 0; i < errors.length; i++) {
        final before = i == 0 ? null : errors[i - 1];
        if (before == null && errors[i] == DiaryFailure.videoTooLong) shown++;
      }
      expect(shown, 2);
    });

    test('새로 넣은 미디어를 빼면 그 임시 사본을 지운다', () async {
      final c = await started();
      await c.addMedia([photo(), photo()]);
      final [first, second] = c.state.draft.media;

      c.removeMedia(first.id);
      await pumpEventQueue();

      expect(c.state.draft.media, [second]);
      expect(c.state.newMedia, [second]);
      expect(filesUnder('tmp'), [second.path]);
    });

    test('순서 바꾸기: from 의 미디어가 to 자리로 간다', () async {
      final c = await started();
      await c.addMedia([photo(), photo(), photo()]);
      final [a, b, cc] = c.state.draft.media;

      c.reorderMedia(0, 2);

      expect(c.state.draft.media, [b, cc, a]);
    });
  });

  group('저장 · 취소', () {
    test('빈 기록은 저장하지 않고 emptyEntry', () async {
      final c = await started();

      await c.save();

      expect(c.state.error, DiaryFailure.emptyEntry);
      expect(c.state.saved, isFalse);
      expect(c.state.saving, isFalse);
    });

    test('저장 중 두 번 눌러도 한 번만 저장한다', () async {
      final c = await started();
      c.setBody('바다');

      await Future.wait([c.save(), c.save()]);

      expect(repo.creates, 1);
      expect(c.state.saved, isTrue);
      final saved = await h.repository
          .watchEntries(const EntryFilter.all())
          .first;
      expect(saved.map((e) => e.body), ['바다']);
      expect(saved.single.location, _aewol);
    });

    test('취소하면 새로 넣은 미디어의 임시 사본을 지운다', () async {
      final c = await started();
      await c.addMedia([photo(), video()]);
      expect(filesUnder('tmp'), hasLength(3));

      await c.cancel();

      expect(filesUnder('tmp'), isEmpty);
    });

    test('수정에서 뺀 미디어 파일은 저장이 성공한 뒤에만 지운다', () async {
      final setup = await started();
      setup.setBody('여행');
      await setup.addMedia([photo(), photo()]);
      await setup.save();
      final entry =
          (await h.repository.watchEntries(const EntryFilter.all()).first)
              .single;
      final [keep, drop] = entry.media;

      // 빼고 취소 → 그대로.
      final cancelled = newCubit();
      await cancelled.startEdit(entry.id);
      cancelled.removeMedia(drop.id);
      await pumpEventQueue();
      expect(media.resolve(drop.path).existsSync(), isTrue);
      await cancelled.cancel();
      expect(media.resolve(drop.path).existsSync(), isTrue);

      // 빼고 저장 실패(빈 기록) → 그대로.
      final failing = newCubit();
      await failing.startEdit(entry.id);
      failing
        ..setBody('')
        ..removeMedia(keep.id)
        ..removeMedia(drop.id);
      await failing.save();
      expect(failing.state.error, DiaryFailure.emptyEntry);
      expect(media.resolve(drop.path).existsSync(), isTrue);

      // 빼고 저장 → 지운다.
      final editing = newCubit();
      await editing.startEdit(entry.id);
      expect(editing.state.editingId, entry.id);
      expect(editing.state.createdAt, entry.createdAt);
      expect(editing.state.draft.media, entry.media);
      editing.removeMedia(drop.id);
      await editing.save();

      expect(editing.state.saved, isTrue);
      expect(media.resolve(drop.path).existsSync(), isFalse);
      expect(media.resolve(keep.path).existsSync(), isTrue);
    });

    test('없는 기록을 고치려 하면 notFound', () async {
      final c = newCubit();

      await c.startEdit('missing');

      expect(c.state.error, DiaryFailure.notFound);
    });
  });
}
