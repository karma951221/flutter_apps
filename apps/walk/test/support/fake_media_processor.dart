import 'dart:io';

import 'package:walk/domain/diary/media/media_processor.dart';

/// 플러그인 없이 사본 파일만 쓰는 처리기. 호출을 기록하고 실패를 흉내 낸다.
class FakeMediaProcessor implements MediaProcessor {
  /// [videoDurationMs] 가 돌려줄 길이.
  int durationMs = 10000;

  /// true 면 압축 도중(사본을 쓴 뒤) 예외를 던진다.
  bool failCompress = false;

  /// true 면 길이 읽기에서 예외를 던진다.
  bool failDuration = false;

  final List<String> photoCalls = [];
  final List<String> videoCalls = [];

  @override
  Future<({int width, int height})> compressPhoto(
    File source,
    File target,
  ) async {
    photoCalls.add(source.path);
    await target.writeAsBytes([...await source.readAsBytes(), 0xFF]);
    if (failCompress) throw StateError('photo compress failed');
    return (width: 1600, height: 1200);
  }

  @override
  Future<int> videoDurationMs(File source) async {
    if (failDuration) throw StateError('duration unreadable');
    return durationMs;
  }

  @override
  Future<({int width, int height, int durationMs})> compressVideo(
    File source,
    File target,
    File thumb,
  ) async {
    videoCalls.add(source.path);
    await target.writeAsBytes([...await source.readAsBytes(), 0xFE]);
    await thumb.writeAsBytes([1, 2, 3]);
    if (failCompress) throw StateError('video compress failed');
    return (width: 1280, height: 720, durationMs: durationMs);
  }
}
