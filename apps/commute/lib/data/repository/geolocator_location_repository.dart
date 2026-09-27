import 'dart:async';

import 'package:core/core.dart';
import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entity/geo_point.dart';
import '../../domain/repository/location_repository.dart';
import '../location/location_gateway.dart';

@LazySingleton(as: LocationRepository)
class GeolocatorLocationRepository implements LocationRepository {
  GeolocatorLocationRepository(this._gateway);

  final LocationGateway _gateway;

  /// 이번 세션에서 사용자가 권한 요청을 거부했는지. Android는 첫 거부 뒤에도
  /// `denied`를 돌려주므로, 기억해 두지 않으면 방향 토글·새로고침마다 시스템
  /// 다이얼로그가 다시 뜬다. 거부는 정상 분기라 조용히 fallback으로 보낸다.
  bool _requestDeclined = false;

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
      if (permission == LocationPermission.denied && !_requestDeclined) {
        permission = await _gateway.requestPermission();
        _requestDeclined =
            permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever;
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
