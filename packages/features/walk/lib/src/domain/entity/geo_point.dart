import 'package:freezed_annotation/freezed_annotation.dart';

part 'geo_point.freezed.dart';

@freezed
class GeoPoint with _$GeoPoint {
  @override
  final double lat;
  @override
  final double lng;

  const GeoPoint({required this.lat, required this.lng});
}
