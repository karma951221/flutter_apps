import 'package:freezed_annotation/freezed_annotation.dart';

import 'record_mode.dart';

part 'location_point.freezed.dart';

/// 기록된 위치 한 점. 시각은 UTC 로 저장한다.
@freezed
class LocationPoint with _$LocationPoint {
  @override
  final DateTime recordedAt;

  @override
  final double lat;

  @override
  final double lng;

  @override
  final double? accuracyM;

  @override
  final RecordMode mode;

  /// 정지 감지로 위치 요청을 멈추기 직전에 남긴 점.
  @override
  final bool stillStart;

  const LocationPoint({
    required this.recordedAt,
    required this.lat,
    required this.lng,
    this.accuracyM,
    required this.mode,
    this.stillStart = false,
  });
}
