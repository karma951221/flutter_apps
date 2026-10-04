import 'dart:async';

import 'package:core/core.dart';
import 'package:injectable/injectable.dart';
import 'package:location/location.dart';

import '../../domain/entity/geo_point.dart';
import '../../domain/repository/location_repository.dart';

@LazySingleton(as: LocationRepository)
class GeolocatorLocationRepository implements LocationRepository {
  GeolocatorLocationRepository(this._gateway)
    : _access = LocationAccess(_gateway);

  final LocationGateway _gateway;

  /// 세션당 한 번만 묻는다. 거부는 정상 분기라 조용히 fallback 으로 보낸다.
  final LocationAccess _access;

  @override
  Future<Result<GeoPoint>> currentLocation({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      switch (await _access.ensure()) {
        case LocationAccessStatus.serviceDisabled:
          return const Err(
            Failure.validation(
              failureCode: FailureCode.locationServiceDisabled,
            ),
          );
        case LocationAccessStatus.permissionDenied:
          return const Err(
            Failure.forbidden(
              failureCode: FailureCode.locationPermissionDenied,
            ),
          );
        case LocationAccessStatus.granted:
          break;
      }

      final position = await _gateway.getCurrentPosition(
        accuracy: LocationAccuracy.high,
        timeout: timeout,
      );
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
