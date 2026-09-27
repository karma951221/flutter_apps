import 'package:geolocator/geolocator.dart';
import 'package:permission/permission.dart';

import 'location_gateway.dart';

class GeolocatorPermissionSource implements PermissionSource {
  GeolocatorPermissionSource(this._gateway);

  final LocationGateway _gateway;

  @override
  Future<PermissionStatus> check() async =>
      _map(await _gateway.checkPermission());

  @override
  Future<PermissionStatus> request() async =>
      _map(await _gateway.requestPermission());

  @override
  Future<void> openSettings() => _gateway.openAppSettings();

  static PermissionStatus _map(LocationPermission permission) =>
      switch (permission) {
        LocationPermission.always ||
        LocationPermission.whileInUse => PermissionStatus.granted,
        LocationPermission.deniedForever =>
          PermissionStatus.permanentlyDenied,
        LocationPermission.denied ||
        LocationPermission.unableToDetermine => PermissionStatus.denied,
      };
}
