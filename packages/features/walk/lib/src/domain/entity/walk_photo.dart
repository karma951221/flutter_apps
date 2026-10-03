import 'package:freezed_annotation/freezed_annotation.dart';

part 'walk_photo.freezed.dart';

/// [path] 는 앱 문서 폴더 기준 상대 경로다.
@freezed
class WalkPhoto with _$WalkPhoto {
  @override
  final String id;
  @override
  final String path;
  @override
  final int position;

  const WalkPhoto({
    required this.id,
    required this.path,
    required this.position,
  });
}
