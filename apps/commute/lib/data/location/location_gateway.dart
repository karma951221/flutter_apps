import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';

abstract interface class LocationGateway {
  Future<bool> isLocationServiceEnabled();

  Future<LocationPermission> checkPermission();

  Future<LocationPermission> requestPermission();

  Future<Position> getCurrentPosition({required Duration timeout});

  Future<bool> openAppSettings();
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
  Future<Position> getCurrentPosition({required Duration timeout}) =>
      Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeout,
        ),
      );

  @override
  Future<bool> openAppSettings() => Geolocator.openAppSettings();
}
