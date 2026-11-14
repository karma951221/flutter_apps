import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:location/location.dart';
import 'package:permission/permission.dart';

import '../../domain/diary/location/place_lookup.dart';
import '../../domain/diary/location/place_source.dart';
import '../../domain/weather/weather_locator.dart';
import '../../domain/weather/weather_problem.dart';

/// 지금 위치를 대략(low 정확도)만 읽는다. 날씨는 동네 단위면 충분해 빠르게 얻는다.
@LazySingleton(as: WeatherLocator)
class WeatherLocationSource implements WeatherLocator {
  WeatherLocationSource(
    this._access,
    this._gateway,
    this._namer, {
    @ignoreParam this.timeout = const Duration(seconds: 8),
  });

  final LocationAccess _access;
  final LocationGateway _gateway;
  final PlaceNamer _namer;
  final Duration timeout;

  @override
  Future<WeatherFix> locate() async {
    try {
      final status = await _access.ensure();
      switch (status) {
        case LocationAccessStatus.serviceDisabled:
          return const WeatherFix.failed(WeatherProblem.locationServiceOff);
        case LocationAccessStatus.permissionDenied:
          return const WeatherFix.failed(WeatherProblem.locationDenied);
        case LocationAccessStatus.granted:
          break;
      }
      final position = await _gateway
          .getCurrentPosition(accuracy: LocationAccuracy.low, timeout: timeout)
          .timeout(timeout);
      return WeatherFix.located(position.latitude, position.longitude);
    } on Object {
      return const WeatherFix.failed(WeatherProblem.locationUnavailable);
    }
  }

  @override
  Future<String?> placeName(double lat, double lng) async {
    try {
      return switch (await _namer.nameFor(lat, lng)) {
        PlaceNamed(:final name) => name,
        PlaceNoName() || PlaceOffline() => null,
      };
    } on Object {
      return null;
    }
  }

  @override
  Future<void> resolve(WeatherProblem problem) async {
    switch (problem) {
      case WeatherProblem.locationServiceOff:
        await _access.openLocationSettings();
      case WeatherProblem.locationDenied:
        // 시스템 다이얼로그를 한 번 더 띄우고, 그래도 거부면 앱 설정으로 보낸다.
        final status = await _access.permission.requestAgain();
        if (status != PermissionStatus.granted) {
          await _access.permission.openSettings();
        }
      case WeatherProblem.locationUnavailable ||
          WeatherProblem.offline ||
          WeatherProblem.server:
        break;
    }
  }
}
