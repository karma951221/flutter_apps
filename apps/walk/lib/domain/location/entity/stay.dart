import 'package:freezed_annotation/freezed_annotation.dart';

part 'stay.freezed.dart';

/// 한 곳에 머문 시간(반경 안 일정 시간 이상). 좌표는 점들의 평균.
@freezed
class Stay with _$Stay {
  @override
  final DateTime start;

  @override
  final DateTime end;

  @override
  final double lat;

  @override
  final double lng;

  @override
  final int pointCount;

  const Stay({
    required this.start,
    required this.end,
    required this.lat,
    required this.lng,
    required this.pointCount,
  });

  Duration get duration => end.difference(start);
}
