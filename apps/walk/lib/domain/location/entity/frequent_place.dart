import 'package:freezed_annotation/freezed_annotation.dart';

part 'frequent_place.freezed.dart';

/// 자주 간 곳. [gridKey] 격자(소수 3자리) 단위로 묶는다.
@freezed
class FrequentPlace with _$FrequentPlace {
  @override
  final String gridKey;

  @override
  final double lat;

  @override
  final double lng;

  @override
  final int visits;

  @override
  final Duration total;

  const FrequentPlace({
    required this.gridKey,
    required this.lat,
    required this.lng,
    required this.visits,
    required this.total,
  });
}
