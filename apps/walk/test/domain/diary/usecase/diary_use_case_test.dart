import 'dart:io';

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:walk/data/diary/media/file_media_store.dart';
import 'package:walk/data/diary/prefs_diary_preferences.dart';
import 'package:walk/domain/diary/diary_failure.dart';
import 'package:walk/domain/diary/entity/diary_entry.dart';
import 'package:walk/domain/diary/entity/entry_location.dart';
import 'package:walk/domain/diary/entity/entry_media.dart';
import 'package:walk/domain/diary/entity/trash_retention.dart';
import 'package:walk/domain/diary/location/place_source.dart';
import 'package:walk/domain/diary/usecase/diary_use_case.dart';

import '../../../support/diary_fixtures.dart';
import '../../../support/fake_media_processor.dart';

/// 실제 [FileMediaStore] 에 `deleteFiles` 실패만 덧씌운다.
class _FlakyMediaStore extends FileMediaStore {
  _FlakyMediaStore(super.root, super.ids, super.processor);

  bool failDelete = false;

  @override
  Future<void> deleteFiles(Iterable<String> relativePaths) {
    if (failDelete) throw const FileSystemException('disk busy');
    return super.deleteFiles(relativePaths);
  }
}

class _FakePlaceSource implements PlaceSource {
  /// null 이면 이름을 못 찾은 것(오프라인).
  String? name;
  final List<(double, double)> asked = [];

  @override
  Future<EntryLocation?> current() async => null;

  @override
  Future<String?> nameFor(double lat, double lng) async {
    asked.add((lat, lng));
    return name;
  }
}

void main() {
  late Directory sandbox;
  late DiaryHarness h;
  late _FlakyMediaStore media;
  late _FakePlaceSource places;
  late PrefsDiaryPreferences prefs;
  late DiaryUseCase useCase;
  late File pickedPhoto;
  late File pickedVideo;

  setUp(() async {
    sandbox = Directory.systemTemp.createTempSync('diary_use_case_test');
    h = DiaryHarness();
    media = _FlakyMediaStore(
      Directory('${sandbox.path}/diary'),
      const IdGenerator(Uuid()),
      FakeMediaProcessor(),
    );
    places = _FakePlaceSource();
    SharedPreferences.setMockInitialValues({});
    prefs = PrefsDiaryPreferences(await SharedPreferences.getInstance());
    useCase = DiaryUseCase(h.repository, media, places, prefs, h.clock);
    pickedPhoto = File('${sandbox.path}/picked.jpg')
      ..writeAsBytesSync([1, 2, 3]);
    pickedVideo = File('${sandbox.path}/picked.mp4')
      ..writeAsBytesSync([4, 5, 6]);
  });

  tearDown(() async {
    await h.close();
    sandbox.deleteSync(recursive: true);
  });

  List<String> filesUnder(String dir) {
    final d = Directory('${sandbox.path}/diary/$dir');
    if (!d.existsSync()) return [];
    return [
      for (final f in d.listSync().whereType<File>())
        '$dir/${f.uri.pathSegments.last}',
    ]..sort();
  }

  /// 기록이 가진 파일(원본 + 썸네일)의 상대 경로.
  List<String> filesOf(DiaryEntry entry) => [
    for (final m in entry.media) ...[m.path, ?m.thumbPath],
  ]..sort();

  Future<EntryMedia> newPhoto() async =>
      okValue(await media.importPhoto(pickedPhoto.path));

  Future<EntryMedia> newVideo() async =>
      okValue(await media.importVideo(pickedVideo.path));

  /// 사진 2 + 영상 1 기록.
  Future<DiaryEntry> saveRich({String body = '여행'}) async => okValue(
    await useCase.save(
      entryDraft(
        body: body,
        media: [await newPhoto(), await newPhoto(), await newVideo()],
      ),
    ),
  );

  /// 남아 있는 파일의 수정 시각을 [h.clock] 기준 25시간 전으로 돌린다.
  void ageAllFiles() {
    final old = h.clock.now().subtract(const Duration(hours: 25));
    for (final dir in ['media', 'tmp']) {
      for (final path in filesUnder(dir)) {
        media.resolve(path).setLastModifiedSync(old);
      }
    }
  }

  group('save', () {
    test('새 미디어를 media/ 로 옮겨 저장하고 tmp 는 비운다', () async {
      final entry = await saveRich();

      expect(entry.media, hasLength(3));
      for (final m in entry.media) {
        expect(m.path, startsWith('media/'));
        expect(media.resolve(m.path).lengthSync(), greaterThan(0));
      }
      expect(entry.media.last.thumbPath, startsWith('media/'));
      expect(filesUnder('media'), filesOf(entry));
      expect(filesUnder('tmp'), isEmpty);
      expect(okValue(await h.repository.entry(entry.id)).media, entry.media);
    });

    test('DB 저장이 실패하면(닫힌 스토리) 옮긴 파일을 tmp 로 되돌린다', () async {
      final closed = okValue(
        await h.repository.createStory(
          title: '지난 여행',
          startedAt: DateTime(2026, 9, 1),
          endedAt: DateTime(2026, 9, 3),
        ),
      );
      final draftMedia = [await newPhoto(), await newVideo()];
      final tmpBefore = filesUnder('tmp');

      final failure = errFailure(
        await useCase.save(entryDraft(storyId: closed.id, media: draftMedia)),
      );

      expect(failure, isDiaryFailure(DiaryFailure.storyClosed.name));
      expect(filesUnder('media'), isEmpty);
      expect(filesUnder('tmp'), tmpBefore);
      expect(await h.repository.allMediaPaths(), isEmpty);
    });

    test('규칙 위반(미래 시각)이면 파일을 옮기지 않는다', () async {
      final draftMedia = [await newPhoto()];

      final failure = errFailure(
        await useCase.save(
          entryDraft(
            occurredAt: h.clock.now().add(const Duration(minutes: 1)),
            media: draftMedia,
          ),
        ),
      );

      expect(failure, isDiaryFailure(DiaryFailure.futureTime.name));
      expect(filesUnder('media'), isEmpty);
      expect(filesUnder('tmp'), [draftMedia.single.path]);
    });

    test('수정에서 뺀 미디어 파일은 저장이 성공한 뒤에 지운다', () async {
      final entry = await saveRich();
      final [keep, drop, video] = entry.media;
      final added = await newPhoto();

      final edited = okValue(
        await useCase.save(
          entryDraft(body: '고침', media: [keep, video, added]),
          editingId: entry.id,
        ),
      );

      expect(edited.media.map((m) => m.id), [keep.id, video.id, added.id]);
      expect(edited.media.last.path, startsWith('media/'));
      expect(media.resolve(drop.path).existsSync(), isFalse);
      expect(filesUnder('media'), filesOf(edited));
      expect(filesUnder('tmp'), isEmpty);
    });

    test('수정 저장이 실패하면 뺀 미디어 파일은 남고 새 미디어는 tmp 로 돌아간다', () async {
      final entry = await saveRich();
      final closed = okValue(
        await h.repository.createStory(
          title: '지난 여행',
          startedAt: DateTime(2026, 9, 1),
          endedAt: DateTime(2026, 9, 3),
        ),
      );
      final added = await newPhoto();

      errFailure(
        await useCase.save(
          entryDraft(storyId: closed.id, media: [entry.media.first, added]),
          editingId: entry.id,
        ),
      );

      expect(filesUnder('media'), filesOf(entry));
      expect(filesUnder('tmp'), [added.path]);
      expect(okValue(await h.repository.entry(entry.id)).media, entry.media);
    });

    test('cancelDraft 는 tmp 사본을 모두 지운다', () async {
      final draftMedia = [await newPhoto(), await newVideo()];

      await useCase.cancelDraft(draftMedia);

      expect(filesUnder('tmp'), isEmpty);
    });
  });

  group('휴지통 · 영구 삭제', () {
    test('휴지통에 넣어도 파일은 그대로, 복원하면 같은 경로의 파일이 열린다', () async {
      final entry = await saveRich();

      okValue(await useCase.trash(entry.id));
      expect(filesUnder('media'), filesOf(entry));

      final restored = okValue(await useCase.restore(entry.id));
      expect(restored.deletedAt, isNull);
      expect(restored.media, entry.media);
      for (final path in filesOf(restored)) {
        expect(media.resolve(path).lengthSync(), greaterThan(0));
      }
    });

    test('사진 2 + 영상 1 기록 purge → 그 파일(썸네일 포함) 0, 다른 기록 파일 유지', () async {
      final gone = await saveRich();
      final other = await saveRich(body: '다른 날');
      okValue(await useCase.trash(gone.id));

      okValue(await useCase.purge([gone.id]));

      expect(filesUnder('media'), filesOf(other));
      expect(errFailure(await h.repository.entry(gone.id)), isA<Failure>());
    });

    test('살아 있는 기록을 purge 하면 아무 파일도 지우지 않는다', () async {
      final entry = await saveRich();

      okValue(await useCase.purge([entry.id]));

      expect(filesUnder('media'), filesOf(entry));
    });

    test('emptyTrash 는 휴지통 기록 여럿의 파일을 모두 지운다', () async {
      final a = await saveRich(body: 'a');
      final b = await saveRich(body: 'b');
      final live = await saveRich(body: 'live');
      okValue(await useCase.trash(a.id));
      okValue(await useCase.trash(b.id));

      okValue(await useCase.emptyTrash());

      expect(filesUnder('media'), filesOf(live));
      expect(await h.repository.watchTrash().first, isEmpty);
    });

    test('파일 삭제가 던져도 purge 는 Ok, 다음 cleanOrphans 가 회수한다', () async {
      final gone = await saveRich();
      final other = await saveRich(body: '다른 날');
      okValue(await useCase.trash(gone.id));
      media.failDelete = true;

      okValue(await useCase.purge([gone.id]));

      expect(errFailure(await h.repository.entry(gone.id)), isA<Failure>());
      expect(
        filesUnder('media'),
        [...filesOf(gone), ...filesOf(other)]..sort(),
      );

      media.failDelete = false;
      ageAllFiles();
      await useCase.cleanOrphans();

      expect(filesUnder('media'), filesOf(other));
    });

    test('스토리 삭제는 기록을 휴지통으로 보내고 파일은 남긴다', () async {
      final story = okValue(
        await h.repository.createStory(
          title: '제주',
          startedAt: DateTime(2026, 9, 1),
        ),
      );
      final entry = okValue(
        await useCase.save(
          entryDraft(storyId: story.id, media: [await newPhoto()]),
        ),
      );

      okValue(await useCase.deleteStory(story.id));

      expect(okValue(await h.repository.entry(entry.id)).isTrashed, isTrue);
      expect(filesUnder('media'), filesOf(entry));
    });
  });

  group('maintain', () {
    test('7일: 6일 23:59:59 지난 휴지통은 남기고 7일 지나면 파일까지 지운다', () async {
      final entry = await saveRich();
      okValue(await useCase.trash(entry.id));

      h.clock.advance(const Duration(days: 7) - const Duration(seconds: 1));
      await useCase.maintain();
      expect(okValue(await h.repository.entry(entry.id)).isTrashed, isTrue);
      expect(filesUnder('media'), filesOf(entry));

      h.clock.advance(const Duration(seconds: 1));
      await useCase.maintain();
      expect(errFailure(await h.repository.entry(entry.id)), isA<Failure>());
      expect(filesUnder('media'), isEmpty);
    });

    test('"안 함" 이면 오래된 휴지통도 지우지 않는다', () async {
      await prefs.setTrashRetention(TrashRetention.never);
      final entry = await saveRich();
      okValue(await useCase.trash(entry.id));

      h.clock.advance(const Duration(days: 400));
      await useCase.maintain();

      expect(okValue(await h.repository.entry(entry.id)).isTrashed, isTrue);
      expect(filesUnder('media'), filesOf(entry));
    });

    test('좌표만 있는 기록의 장소 이름을 채운다', () async {
      final entry = okValue(
        await useCase.save(
          entryDraft(location: const EntryLocation(lat: 33.46, lng: 126.31)),
        ),
      );
      places.name = '애월읍';

      await useCase.maintain();

      expect(places.asked, [(33.46, 126.31)]);
      final filled = okValue(await h.repository.entry(entry.id));
      expect(filled.location?.placeName, '애월읍');
      expect(await h.repository.entriesMissingPlaceName(), isEmpty);
    });

    test('이름을 못 찾으면(오프라인) 다음에 다시 시도한다', () async {
      final entry = okValue(
        await useCase.save(
          entryDraft(location: const EntryLocation(lat: 33.46, lng: 126.31)),
        ),
      );

      await useCase.maintain();

      expect((await h.repository.entriesMissingPlaceName()).map((e) => e.id), [
        entry.id,
      ]);

      places.name = '애월읍';
      await useCase.maintain();
      expect(
        okValue(await h.repository.entry(entry.id)).location?.placeName,
        '애월읍',
      );
    });
  });

  group('cleanOrphans', () {
    test('살아 있는 · 휴지통 기록 파일은 남기고 오래된 고아만 지운다', () async {
      final live = await saveRich(body: 'live');
      final trashed = await saveRich(body: 'trashed');
      okValue(await useCase.trash(trashed.id));
      media.resolve('media/orphan.jpg').writeAsBytesSync([9]);
      media.resolve('media/orphan_thumb.jpg').writeAsBytesSync([9]);
      ageAllFiles();

      await useCase.cleanOrphans();

      expect(
        filesUnder('media'),
        [...filesOf(live), ...filesOf(trashed)]..sort(),
      );
    });

    test('방금 옮긴(저장 중인) media/ 파일은 DB 에 없어도 남긴다', () async {
      final promoted = await media.promote(await newPhoto());
      media
          .resolve(promoted.path)
          .setLastModifiedSync(
            h.clock.now().subtract(const Duration(hours: 1)),
          );

      await useCase.cleanOrphans();

      expect(filesUnder('media'), [promoted.path]);
    });
  });
}
