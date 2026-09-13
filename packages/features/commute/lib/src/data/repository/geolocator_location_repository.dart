import 'dart:async';

import 'package:core/core.dart';
import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entity/geo_point.dart';
import '../../domain/repository/location_repository.dart';
import '../location/location_gateway.dart';

@LazySingleton(as: LocationRepository)
class GeolocatorLocationRepository implements LocationRepository {
  const GeolocatorLocationRepository(this._gateway);

  final LocationGateway _gateway;

  @override
  Future<Result<GeoPoint>> currentLocation({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      if (!await _gateway.isLocationServiceEnabled()) {
        return const Err(
          Failure.validation(failureCode: FailureCode.locationServiceDisabled),
        );
      }

      var permission = await _gateway.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await _gateway.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return const Err(
          Failure.forbidden(failureCode: FailureCode.locationPermissionDenied),
        );
      }

      final position = await _gateway.getCurrentPosition(timeout: timeout);
      return Ok(GeoPoint(lat: position.latitude, lng: position.longitude));
    } on TimeoutException {
      return const Err(
        Failure.network(failureCode: FailureCode.locationTimeout),
      );
    } catch (error) {
      return Err(Failure.unknown(message: error.toString()));
    }
  }
}
