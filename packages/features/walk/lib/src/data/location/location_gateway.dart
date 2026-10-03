import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entity/geo_point.dart';

/// geolocator 정적 API 를 감싸 테스트가 대체할 수 있게 한다.
abstract interface class LocationGateway {
  Future<bool> isLocationServiceEnabled();

  Future<LocationPermission> checkPermission();

  Future<LocationPermission> requestPermission();

  Stream<Position> positionStream(LocationSettings settings);

  double distanceBetween(GeoPoint a, GeoPoint b);
}

@LazySingleton(as: LocationGateway)
class GeolocatorGateway implements LocationGateway {
  @override
  Future<bool> isLocationServiceEnabled() =>
      Geolocator.isLocationServiceEnabled();

  @override
  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();

  @override
  Future<LocationPermission> requestPermission() =>
      Geolocator.requestPermission();

  @override
  Stream<Position> positionStream(LocationSettings settings) =>
      Geolocator.getPositionStream(locationSettings: settings);

  @override
  double distanceBetween(GeoPoint a, GeoPoint b) =>
      Geolocator.distanceBetween(a.lat, a.lng, b.lat, b.lng);
}
