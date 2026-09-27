import 'package:freezed_annotation/freezed_annotation.dart';

import 'geo_point.dart';
import 'station.dart';

part 'origin.freezed.dart';

@freezed
sealed class Origin with _$Origin {
  const factory Origin.currentLocation(GeoPoint point) = CurrentLocationOrigin;
  const factory Origin.fallbackStation(Station station) = FallbackStationOrigin;
}
