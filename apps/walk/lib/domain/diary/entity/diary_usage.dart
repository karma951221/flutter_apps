import 'package:freezed_annotation/freezed_annotation.dart';

part 'diary_usage.freezed.dart';

/// 일기가 차지하는 저장 공간.
@freezed
class DiaryUsage with _$DiaryUsage {
  @override
  final int photos;

  @override
  final int videos;

  @override
  final int bytes;

  /// 그중 휴지통에 있는 기록의 몫.
  @override
  final int trashBytes;

  const DiaryUsage({
    required this.photos,
    required this.videos,
    required this.bytes,
    required this.trashBytes,
  });
}
