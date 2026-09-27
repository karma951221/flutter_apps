import 'dart:async';

import 'package:core/core.dart';
import 'package:injectable/injectable.dart';
import 'package:permission/permission.dart';

import '../../domain/entity/geo_point.dart';
import '../../domain/repository/location_repository.dart';
import '../location/geolocator_permission_source.dart';
import '../location/location_gateway.dart';

@LazySingleton(as: LocationRepository)
class GeolocatorLocationRepository implements LocationRepository {
  GeolocatorLocationRepository(this._gateway)
    : _permission = PermissionRequester(GeolocatorPermissionSource(_gateway));

  final LocationGateway _gateway;

  /// 세션당 한 번만 묻는다. 거부는 정상 분기라 조용히 fallback 으로 보낸다.
  final PermissionRequester _permission;

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

      if (await _permission.ensure() != PermissionStatus.granted) {
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
