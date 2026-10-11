import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_image_compress_common/flutter_image_compress_common.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_compress/video_compress.dart';
import 'package:walk/data/diary/media/plugin_media_processor.dart';

const _imageChannel = MethodChannel('flutter_image_compress');
const _videoChannel = MethodChannel('video_compress');

/// [width]×[height] PNG 를 [file] 에 쓴다. 크기 읽기는 실제 디코더를 거친다.
Future<File> writeImage(File file, int width, int height) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint(),
  );
  final image = await recorder.endRecording().toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return file.writeAsBytes(data!.buffer.asUint8List());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  group('photoTargetSize: 긴 변 1600 이하, 키우지 않음', () {
    for (final (source, expected) in [
      ((4000, 3000), (1600, 1200)), // 가로
      ((3000, 4000), (1200, 1600)), // 세로
      ((4000, 4000), (1600, 1600)), // 정사각
      ((1000, 800), (1000, 800)), // 이미 작음
      ((800, 1000), (800, 1000)), // 이미 작은 세로
      ((1600, 900), (1600, 900)), // 경계
      ((4000, 2251), (1600, 900)), // 나누어떨어지지 않음 → 짧은 변 내림
      ((9000, 1000), (1600, 177)), // 파노라마
    ]) {
      test('$source → $expected', () {
        final fit = photoTargetSize(source.$1, source.$2);
        expect((fit.width, fit.height), expected);
        expect(
          fit.width > fit.height ? fit.width : fit.height,
          lessThanOrEqualTo(1600),
        );
      });
    }
  });

  group('compressPhoto', () {
    late Directory sandbox;
    late List<dynamic> calls;

    setUp(() {
      sandbox = Directory.systemTemp.createTempSync('plugin_media_photo');
      calls = [];
      FlutterImageCompressPlatform.instance = FlutterImageCompressCommon();
      messenger.setMockMethodCallHandler(_imageChannel, (call) async {
        expect(call.method, 'compressWithFileAndGetFile');
        final args = call.arguments as List<dynamic>;
        calls.add(args);
        // 결과는 일부러 다른 크기로 써서, 돌려주는 크기가 결과 파일에서 읽은 값인지 본다.
        await writeImage(File(args[4] as String), 16, 12);
        return args[4];
      });
    });

    tearDown(() {
      messenger.setMockMethodCallHandler(_imageChannel, null);
      sandbox.deleteSync(recursive: true);
    });

    Future<List<dynamic>> compress(int width, int height) async {
      final source = await writeImage(
        File('${sandbox.path}/source.png'),
        width,
        height,
      );
      final target = File('${sandbox.path}/out.jpg');
      final size = await PluginMediaProcessor().compressPhoto(source, target);
      expect((size.width, size.height), (16, 12));
      expect(calls, hasLength(1));
      return calls.single as List<dynamic>;
    }

    test('JPEG 85 · EXIF 제거 · 회전 보정으로 부른다', () async {
      final args = await compress(3200, 2400);

      // [path, minWidth, minHeight, quality, targetPath, rotate, autoCorrectionAngle, format, keepExif, ...]
      expect(args[0], '${sandbox.path}/source.png');
      expect(args[3], 85);
      expect(args[4], '${sandbox.path}/out.jpg');
      expect(args[6], isTrue);
      expect(args[7], CompressFormat.jpeg.index);
      expect(args[8], isFalse);
    });

    test('가로 3200×2400 → 짧은 변 목표 1200 (긴 변 1600)', () async {
      final args = await compress(3200, 2400);

      expect((args[1], args[2]), (1200, 1200));
    });

    test('세로 2400×3200 → 짧은 변 목표 1200 (긴 변 1600)', () async {
      final args = await compress(2400, 3200);

      expect((args[1], args[2]), (1200, 1200));
    });

    test('1000×800 원본은 키우지 않는다(짧은 변 목표 = 원본 짧은 변)', () async {
      final args = await compress(1000, 800);

      expect((args[1], args[2]), (800, 800));
    });

    test('플러그인이 null 을 돌려주면 예외', () async {
      messenger.setMockMethodCallHandler(_imageChannel, (_) async => null);
      final source = await writeImage(File('${sandbox.path}/s.png'), 10, 10);

      await expectLater(
        PluginMediaProcessor().compressPhoto(
          source,
          File('${sandbox.path}/out.jpg'),
        ),
        throwsA(anything),
      );
    });
  });

  group('video', () {
    late Directory sandbox;
    late Directory cache;
    late List<MethodCall> calls;

    final originalDebugPrint = debugPrint;

    setUp(() {
      // 플러그인이 진행률 구독 안내를 debugPrint 로 찍는다 — 테스트 출력에서 뺀다.
      debugPrint = (_, {wrapWidth}) {};
      addTearDown(() => debugPrint = originalDebugPrint);
      sandbox = Directory.systemTemp.createTempSync('plugin_media_video');
      cache = Directory('${sandbox.path}/plugin_cache')..createSync();
      calls = [];
      messenger.setMockMethodCallHandler(_videoChannel, (call) async {
        calls.add(call);
        final args = call.arguments as Map<Object?, Object?>?;
        switch (call.method) {
          case 'getMediaInfo':
            return jsonEncode({'path': args!['path'], 'duration': 19942.0});
          case 'compressVideo':
            final out = File('${cache.path}/out.mp4')
              ..writeAsBytesSync([7, 7, 7]);
            return jsonEncode({
              'path': out.path,
              'width': 1280,
              'height': 576,
              'duration': 19942.0,
              'filesize': 3,
              'isCancel': false,
            });
          case 'getFileThumbnail':
            return (File('${cache.path}/out.jpg')..writeAsBytesSync([9])).path;
          case 'deleteAllCache':
            cache.deleteSync(recursive: true);
            return true;
        }
        return null;
      });
    });

    tearDown(() {
      messenger.setMockMethodCallHandler(_videoChannel, null);
      sandbox.deleteSync(recursive: true);
    });

    test('videoDurationMs 는 getMediaInfo 의 duration(ms) 을 반올림한다', () async {
      final ms = await PluginMediaProcessor().videoDurationMs(
        File('${sandbox.path}/in.mp4'),
      );

      expect(ms, 19942);
      expect(calls.single.method, 'getMediaInfo');
    });

    test('videoDurationMs 는 정보를 못 읽으면 예외', () async {
      messenger.setMockMethodCallHandler(_videoChannel, (_) async => null);

      await expectLater(
        PluginMediaProcessor().videoDurationMs(File('${sandbox.path}/x.mp4')),
        throwsA(anything),
      );
    });

    test('compressVideo 는 720p 로 압축해 결과 · 썸네일을 옮기고 캐시를 비운다', () async {
      final source = File('${sandbox.path}/in.mp4')..writeAsBytesSync([1]);
      final target = File('${sandbox.path}/tmp/v.mp4')
        ..parent.createSync(recursive: true);
      final thumb = File('${sandbox.path}/tmp/v_thumb.jpg');

      final result = await PluginMediaProcessor().compressVideo(
        source,
        target,
        thumb,
      );

      expect(result, (width: 1280, height: 576, durationMs: 19942));
      expect(target.readAsBytesSync(), [7, 7, 7]);
      expect(thumb.readAsBytesSync(), [9]);
      expect(source.readAsBytesSync(), [1]);
      expect(cache.existsSync(), isFalse);

      final compress = calls.firstWhere((c) => c.method == 'compressVideo');
      final args = compress.arguments as Map<Object?, Object?>;
      expect(args['path'], source.path);
      expect(args['quality'], VideoQuality.Res1280x720Quality.index);
      expect(args['deleteOrigin'], isFalse);
      final thumbCall = calls.firstWhere((c) => c.method == 'getFileThumbnail');
      expect((thumbCall.arguments as Map)['path'], target.path);
      expect(calls.last.method, 'deleteAllCache');
    });

    test('동시에 두 번 불러도 차례로 처리해 둘 다 성공한다', () async {
      // 플러그인은 압축 중 두 번째 호출을 바로 StateError 로 거절하고, 캐시 비우기는
      // 진행 중인 결과까지 지운다. 처리기가 줄을 세워야 둘 다 산다.
      final gates = [Completer<void>(), Completer<void>()];
      var started = 0;
      messenger.setMockMethodCallHandler(_videoChannel, (call) async {
        calls.add(call);
        final args = call.arguments as Map<Object?, Object?>?;
        switch (call.method) {
          case 'compressVideo':
            final n = started++;
            cache.createSync(recursive: true);
            final out = File('${cache.path}/out$n.mp4')..writeAsBytesSync([n]);
            await gates[n].future;
            return jsonEncode({
              'path': out.path,
              'width': 1280,
              'height': 720,
              'duration': 1000.0,
            });
          case 'getFileThumbnail':
            final name = (args!['path'] as String).split('/').last;
            return (File(
              '${cache.path}/$name.jpg',
            )..writeAsBytesSync([9])).path;
          case 'deleteAllCache':
            if (cache.existsSync()) cache.deleteSync(recursive: true);
            return true;
        }
        return null;
      });
      final source = File('${sandbox.path}/in.mp4')..writeAsBytesSync([1]);
      File out(String name) => File('${sandbox.path}/$name');

      final first = PluginMediaProcessor().compressVideo(
        source,
        out('a.mp4'),
        out('a.jpg'),
      );
      final second = PluginMediaProcessor().compressVideo(
        source,
        out('b.mp4'),
        out('b.jpg'),
      );
      await pumpEventQueue();
      expect(started, 1, reason: '두 번째는 첫 번째가 끝날 때까지 기다린다');
      gates[0].complete();
      await first;
      await pumpEventQueue();
      gates[1].complete();
      await second;

      expect(out('a.mp4').readAsBytesSync(), [0]);
      expect(out('b.mp4').readAsBytesSync(), [1]);
      expect(out('a.jpg').existsSync() && out('b.jpg').existsSync(), isTrue);
      expect(
        [for (final c in calls) c.method],
        [
          'compressVideo',
          'getFileThumbnail',
          'deleteAllCache',
          'compressVideo',
          'getFileThumbnail',
          'deleteAllCache',
        ],
      );
    });

    test('앞 호출이 실패해도 다음 호출은 처리된다', () async {
      var n = 0;
      messenger.setMockMethodCallHandler(_videoChannel, (call) async {
        switch (call.method) {
          case 'compressVideo':
            if (n++ == 0) return null; // 첫 번째는 실패
            cache.createSync(recursive: true);
            final out = File('${cache.path}/ok.mp4')..writeAsBytesSync([5]);
            return jsonEncode({'path': out.path, 'duration': 1000.0});
          case 'getFileThumbnail':
            return (File('${cache.path}/ok.jpg')..writeAsBytesSync([9])).path;
          case 'deleteAllCache':
            return true;
        }
        return null;
      });
      final source = File('${sandbox.path}/in.mp4')..writeAsBytesSync([1]);

      final first = PluginMediaProcessor().compressVideo(
        source,
        File('${sandbox.path}/a.mp4'),
        File('${sandbox.path}/a.jpg'),
      );
      final second = PluginMediaProcessor().compressVideo(
        source,
        File('${sandbox.path}/b.mp4'),
        File('${sandbox.path}/b.jpg'),
      );

      await expectLater(first, throwsA(anything));
      await second;
      expect(File('${sandbox.path}/b.mp4').readAsBytesSync(), [5]);
    });

    test('압축이 실패해도(null) 캐시를 비우고 예외', () async {
      messenger.setMockMethodCallHandler(_videoChannel, (call) async {
        calls.add(call);
        return call.method == 'deleteAllCache' ? true : null;
      });
      final source = File('${sandbox.path}/in.mp4')..writeAsBytesSync([1]);

      await expectLater(
        PluginMediaProcessor().compressVideo(
          source,
          File('${sandbox.path}/v.mp4'),
          File('${sandbox.path}/v_thumb.jpg'),
        ),
        throwsA(anything),
      );
      expect(calls.last.method, 'deleteAllCache');
    });
  });
}
