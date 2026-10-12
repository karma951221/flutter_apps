import 'dart:io';

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import 'package:walk/data/diary/media/file_media_store.dart';
import 'package:walk/domain/diary/diary_failure.dart';
import 'package:walk/domain/diary/entity/entry_media.dart';

import '../../../support/diary_fixtures.dart';
import '../../../support/fake_media_processor.dart';

void main() {
  late Directory sandbox;
  late Directory root;
  late FakeMediaProcessor processor;
  late FileMediaStore store;
  late File photo;
  late File video;

  final originalBytes = [10, 20, 30, 40];

  setUp(() {
    sandbox = Directory.systemTemp.createTempSync('file_media_store_test');
    root = Directory('${sandbox.path}/diary');
    processor = FakeMediaProcessor();
    store = FileMediaStore(root, const IdGenerator(Uuid()), processor);
    photo = File('${sandbox.path}/picked.jpg')..writeAsBytesSync(originalBytes);
    video = File('${sandbox.path}/picked.mp4')..writeAsBytesSync(originalBytes);
  });

  tearDown(() => sandbox.deleteSync(recursive: true));

  List<String> filesUnder(String dir) {
    final d = Directory('${root.path}/$dir');
    if (!d.existsSync()) return [];
    return [
      for (final f in d.listSync().whereType<File>())
        '$dir/${f.uri.pathSegments.last}',
    ]..sort();
  }

  group('importPhoto', () {
    test('원본은 그대로 두고 tmp/<id>.jpg 에 사본을 만든다', () async {
      final media = okValue(await store.importPhoto(photo.path));

      expect(photo.readAsBytesSync(), originalBytes);
      expect(media.kind, MediaKind.photo);
      expect(media.path, matches(RegExp(r'^tmp/[0-9a-f-]+\.jpg$')));
      expect(media.path, 'tmp/${media.id}.jpg');
      expect(media.thumbPath, isNull);
      expect(store.resolve(media.path).existsSync(), isTrue);
      expect(media.bytes, store.resolve(media.path).lengthSync());
      expect((media.width, media.height), (1600, 1200));
    });

    test('같은 원본을 두 번 가져와도 경로가 겹치지 않는다', () async {
      final a = okValue(await store.importPhoto(photo.path));
      final b = okValue(await store.importPhoto(photo.path));

      expect(a.path, isNot(b.path));
      expect(filesUnder('tmp'), hasLength(2));
    });

    test('처리기 예외 → Err(mediaProcessing), tmp 에 남는 파일 없음', () async {
      processor.failCompress = true;

      final failure = errFailure(await store.importPhoto(photo.path));

      expect(failure, isDiaryFailure(DiaryFailure.mediaProcessing.name));
      expect(filesUnder('tmp'), isEmpty);
      expect(photo.readAsBytesSync(), originalBytes);
    });
  });

  group('importVideo', () {
    test('tmp/<id>.mp4 와 tmp/<id>_thumb.jpg 를 만든다', () async {
      processor.durationMs = 12345;

      final media = okValue(await store.importVideo(video.path));

      expect(video.readAsBytesSync(), originalBytes);
      expect(media.kind, MediaKind.video);
      expect(media.path, 'tmp/${media.id}.mp4');
      expect(media.thumbPath, 'tmp/${media.id}_thumb.jpg');
      expect(media.durationMs, 12345);
      expect((media.width, media.height), (1280, 720));
      expect(media.bytes, store.resolve(media.path).lengthSync());
      expect(filesUnder('tmp'), [media.path, media.thumbPath!]..sort());
    });

    test('30초는 받는다', () async {
      processor.durationMs = 30000;

      okValue(await store.importVideo(video.path));
    });

    test('31초 → Err(videoTooLong), 압축하지 않는다', () async {
      processor.durationMs = 31000;

      final failure = errFailure(await store.importVideo(video.path));

      expect(failure, isDiaryFailure(DiaryFailure.videoTooLong.name));
      expect(processor.videoCalls, isEmpty);
      expect(filesUnder('tmp'), isEmpty);
    });

    test('길이를 읽지 못하면 Err(mediaProcessing)', () async {
      processor.failDuration = true;

      final failure = errFailure(await store.importVideo(video.path));

      expect(failure, isDiaryFailure(DiaryFailure.mediaProcessing.name));
      expect(processor.videoCalls, isEmpty);
    });

    test('압축 예외 → Err(mediaProcessing), 영상 · 썸네일 모두 지운다', () async {
      processor.failCompress = true;

      final failure = errFailure(await store.importVideo(video.path));

      expect(failure, isDiaryFailure(DiaryFailure.mediaProcessing.name));
      expect(filesUnder('tmp'), isEmpty);
    });
  });

  group('폴더를 만들 수 없을 때(파일 시스템 오류)', () {
    late FileMediaStore broken;

    setUp(() {
      // 루트 자리에 일반 파일이 있어 tmp/ 폴더를 만들 수 없다.
      final blocker = File('${sandbox.path}/blocked')..writeAsStringSync('x');
      broken = FileMediaStore(
        Directory(blocker.path),
        const IdGenerator(Uuid()),
        processor,
      );
    });

    test('사진 → 던지지 않고 Err(mediaProcessing)', () async {
      final failure = errFailure(await broken.importPhoto(photo.path));

      expect(failure, isDiaryFailure(DiaryFailure.mediaProcessing.name));
    });

    test('영상 → 던지지 않고 Err(mediaProcessing)', () async {
      final failure = errFailure(await broken.importVideo(video.path));

      expect(failure, isDiaryFailure(DiaryFailure.mediaProcessing.name));
    });
  });

  group('promote · demote', () {
    test('promote 는 tmp/ 의 파일을 media/ 로 옮기고 경로만 바꾼다', () async {
      final media = okValue(await store.importVideo(video.path));
      final bytes = store.resolve(media.path).readAsBytesSync();

      final promoted = await store.promote(media);

      expect(promoted.path, 'media/${media.id}.mp4');
      expect(promoted.thumbPath, 'media/${media.id}_thumb.jpg');
      expect(
        promoted.copyWith(path: media.path, thumbPath: media.thumbPath),
        media,
      );
      expect(store.resolve(promoted.path).readAsBytesSync(), bytes);
      expect(filesUnder('media'), [promoted.path, promoted.thumbPath!]..sort());
      expect(filesUnder('tmp'), isEmpty);
    });

    test('이미 media/ 에 있으면 그대로 돌려준다', () async {
      final promoted = await store.promote(
        okValue(await store.importPhoto(photo.path)),
      );

      expect(await store.promote(promoted), promoted);
      expect(filesUnder('media'), [promoted.path]);
    });

    test('demote 는 promote 를 되돌린다', () async {
      final media = okValue(await store.importVideo(video.path));
      final promoted = await store.promote(media);

      await store.demote(promoted);

      expect(filesUnder('media'), isEmpty);
      expect(filesUnder('tmp'), [media.path, media.thumbPath!]..sort());
    });
  });

  group('discard · deleteFiles', () {
    test('discard 는 tmp 의 사본과 썸네일을 지운다', () async {
      final a = okValue(await store.importPhoto(photo.path));
      final b = okValue(await store.importVideo(video.path));

      await store.discard([a, b]);

      expect(filesUnder('tmp'), isEmpty);
    });

    test('discard 는 media/ 에 있는 파일은 건드리지 않는다', () async {
      final saved = await store.promote(
        okValue(await store.importPhoto(photo.path)),
      );

      await store.discard([saved]);

      expect(filesUnder('media'), [saved.path]);
    });

    test('deleteFiles 는 없는 파일이 섞여도 예외 없이 나머지를 지운다', () async {
      final saved = await store.promote(
        okValue(await store.importPhoto(photo.path)),
      );

      await store.deleteFiles(['media/missing.jpg', saved.path]);

      expect(filesUnder('media'), isEmpty);
    });
  });

  group('cleanOrphans', () {
    final now = DateTime(2026, 10, 10, 12);

    File put(String relative, {DateTime? modified}) {
      final file = store.resolve(relative)
        ..createSync(recursive: true)
        ..writeAsBytesSync([1]);
      if (modified != null) file.setLastModifiedSync(modified);
      return file;
    }

    final old = now.subtract(const Duration(hours: 25));

    test('media/ 는 keep 에 있는 것만 남긴다(휴지통 기록 경로 포함)', () async {
      put('media/live.jpg', modified: old);
      put('media/trashed.jpg', modified: old);
      put('media/trashed_thumb.jpg', modified: old);
      put('media/orphan.jpg', modified: old);
      put('media/orphan_thumb.jpg', modified: old);

      await store.cleanOrphans({
        'media/live.jpg',
        'media/trashed.jpg',
        'media/trashed_thumb.jpg',
      }, now);

      expect(filesUnder('media'), [
        'media/live.jpg',
        'media/trashed.jpg',
        'media/trashed_thumb.jpg',
      ]);
    });

    test('media/ 라도 24시간 안에 바뀐 파일은 keep 에 없어도 남긴다(저장 중인 기록)', () async {
      put(
        'media/saving.jpg',
        modified: now.subtract(const Duration(hours: 23)),
      );
      put('media/stale.jpg', modified: old);

      await store.cleanOrphans({}, now);

      expect(filesUnder('media'), ['media/saving.jpg']);
    });

    test('tmp/ 는 24시간 지난 것만 지운다', () async {
      put('tmp/fresh.jpg', modified: now.subtract(const Duration(hours: 23)));
      put('tmp/stale.jpg', modified: now.subtract(const Duration(hours: 25)));

      await store.cleanOrphans({}, now);

      expect(filesUnder('tmp'), ['tmp/fresh.jpg']);
    });

    test('폴더가 아직 없어도 예외가 없다', () async {
      await store.cleanOrphans({}, now);
    });
  });
}
