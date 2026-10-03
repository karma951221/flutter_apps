import 'package:freezed_annotation/freezed_annotation.dart';

import 'dog.dart';
import 'geo_point.dart';
import 'walk_photo.dart';

part 'walk.freezed.dart';

/// 목록용 산책 기록. 전체 경로는 싣지 않고 [previewPoints] 만 둔다.
@freezed
class Walk with _$Walk {
  @override
  final String id;
  @override
  final DateTime startedAt;
  @override
  final DateTime endedAt;
  @override
  final Duration duration;
  @override
  final double distanceMeters;
  @override
  final String? memo;
  @override
  final List<Dog> dogs;
  @override
  final List<WalkPhoto> photos;
  @override
  final List<GeoPoint> previewPoints;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  const Walk({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.duration,
    required this.distanceMeters,
    this.memo,
    required this.dogs,
    required this.photos,
    required this.previewPoints,
    required this.createdAt,
    required this.updatedAt,
  });
}
