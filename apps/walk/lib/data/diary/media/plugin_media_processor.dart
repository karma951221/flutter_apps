import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:injectable/injectable.dart';
import 'package:video_compress/video_compress.dart';

import '../../../domain/diary/entity/media_limits.dart';
import '../../../domain/diary/media/media_processor.dart';

/// [width]×[height] 를 긴 변이 [longEdge] 이하가 되게 비율대로 줄인 크기.
/// 이미 작으면 그대로(키우지 않음). 짧은 변은 내림이라 긴 변이 넘치지 않는다.
({int width, int height}) photoTargetSize(
  int width,
  int height, {
  int longEdge = MediaLimits.photoLongEdge,
}) {
  final long = math.max(width, height);
  if (long <= longEdge) return (width: width, height: height);
  int scaled(int side) => math.max(1, side * longEdge ~/ long);
  return (width: scaled(width), height: scaled(height));
}

/// `flutter_image_compress` · `video_compress` 로 사본을 만든다(스펙 §11).
@LazySingleton(as: MediaProcessor)
class PluginMediaProcessor implements MediaProcessor {
  @override
  Future<({int width, int height})> compressPhoto(
    File source,
    File target,
  ) async {
    // 플러그인의 minWidth/minHeight 는 "짧은 변" 기준으로 맞춰지고(스펙 §11),
    // EXIF 회전이 90/270 이면 둘을 맞바꾼다. 같은 값(목표 크기의 짧은 변)을
    // 둘 다에 주면 회전과 상관없이 긴 변이 1600 이하로 맞춰진다.
    final original = await _readSize(source);
    final fit = photoTargetSize(original.width, original.height);
    final shortSide = math.min(fit.width, fit.height);
    final result = await FlutterImageCompress.compressAndGetFile(
      source.path,
      target.path,
      minWidth: shortSide,
      minHeight: shortSide,
      quality: MediaLimits.photoQuality,
      format: CompressFormat.jpeg,
      keepExif: false,
      autoCorrectionAngle: true,
    );
    if (result == null) throw StateError('photo compress returned no file');
    return _readSize(target);
  }

  @override
  Future<int> videoDurationMs(File source) async {
    final info = await VideoCompress.getMediaInfo(source.path);
    final duration = info.duration;
    if (duration == null) throw StateError('video duration unknown');
    return duration.round();
  }

  /// 결과 · 썸네일은 플러그인 자기 캐시 폴더에 생기므로(스펙 §11) [target] ·
  /// [thumb] 로 복사하고, 성공하든 실패하든 캐시를 비운다.
  @override
  Future<({int width, int height, int durationMs})> compressVideo(
    File source,
    File target,
    File thumb,
  ) async {
    try {
      final info = await VideoCompress.compressVideo(
        source.path,
        quality: VideoQuality.Res1280x720Quality,
        deleteOrigin: false,
        includeAudio: true,
      );
      final path = info?.path;
      if (info == null || path == null || info.isCancel == true) {
        throw StateError('video compress returned no file');
      }
      await File(path).copy(target.path);
      final thumbnail = await VideoCompress.getFileThumbnail(target.path);
      await thumbnail.copy(thumb.path);
      return (
        width: info.width ?? 0,
        height: info.height ?? 0,
        durationMs: info.duration?.round() ?? 0,
      );
    } finally {
      await VideoCompress.deleteAllCache();
    }
  }

  /// 헤더만 읽어 크기를 얻는다(픽셀 전체를 풀지 않는다).
  static Future<({int width, int height})> _readSize(File file) async {
    final buffer = await ui.ImmutableBuffer.fromFilePath(file.path);
    try {
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      try {
        return (width: descriptor.width, height: descriptor.height);
      } finally {
        descriptor.dispose();
      }
    } finally {
      buffer.dispose();
    }
  }
}
