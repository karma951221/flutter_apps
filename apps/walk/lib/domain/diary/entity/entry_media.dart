import 'package:freezed_annotation/freezed_annotation.dart';

part 'entry_media.freezed.dart';

enum MediaKind { photo, video }

@freezed
class EntryMedia with _$EntryMedia {
  @override
  final String id;

  @override
  final MediaKind kind;

  /// 앱 전용 폴더 안 상대 경로.
  @override
  final String path;

  @override
  final String? thumbPath;

  @override
  final int width;

  @override
  final int height;

  /// 영상일 때만.
  @override
  final int? durationMs;

  @override
  final int bytes;

  const EntryMedia({
    required this.id,
    required this.kind,
    required this.path,
    this.thumbPath,
    required this.width,
    required this.height,
    this.durationMs,
    required this.bytes,
  });
}
