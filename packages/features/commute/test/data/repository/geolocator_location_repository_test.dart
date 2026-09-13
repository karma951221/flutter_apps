import 'dart:async';

import 'package:core/core.dart';
import 'package:feature_commute/feature_commute.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';

class _MockLocationGateway extends Mock implements LocationGateway {}

const _timeout = Duration(seconds: 5);
final _position = Position(
  longitude: 127.0276,
  latitude: 37.4979,
  timestamp: DateTime.utc(2026, 9, 13),
  accuracy: 1,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

void main() {
  late _MockLocationGateway gateway;
  late GeolocatorLocationRepository repository;

  setUp(() {
    gateway = _MockLocationGateway();
    repository = GeolocatorLocationRepository(gateway);
  });

  void stubServiceAndPermission() {
    when(
      () => gateway.isLocationServiceEnabled(),
    ).thenAnswer((_) async => true);
    when(
      () => gateway.checkPermission(),
    ).thenAnswer((_) async => LocationPermission.whileInUse);
  }

  test('허용된 현재 위치를 GeoPoint로 반환한다', () async {
    stubServiceAndPermission();
    when(
      () => gateway.getCurrentPosition(timeout: _timeout),
    ).thenAnswer((_) async => _position);

    final result = await repository.currentLocation(timeout: _timeout);

    expect(
      (result as Ok<GeoPoint>).value,
      const GeoPoint(lat: 37.4979, lng: 127.0276),
    );
  });

  test('위치 서비스가 꺼져 있으면 구분된 실패를 반환한다', () async {
    when(
      () => gateway.isLocationServiceEnabled(),
    ).thenAnswer((_) async => false);

    final result = await repository.currentLocation(timeout: _timeout);

    _expectFailure(result, FailureCode.locationServiceDisabled);
    verifyNever(() => gateway.checkPermission());
  });

  test('거부 상태는 한 번 요청하고 다시 거부되면 권한 실패다', () async {
    when(
      () => gateway.isLocationServiceEnabled(),
    ).thenAnswer((_) async => true);
    when(
      () => gateway.checkPermission(),
    ).thenAnswer((_) async => LocationPermission.denied);
    when(
      () => gateway.requestPermission(),
    ).thenAnswer((_) async => LocationPermission.denied);

    final result = await repository.currentLocation(timeout: _timeout);

    _expectFailure(result, FailureCode.locationPermissionDenied);
    verify(() => gateway.requestPermission()).called(1);
  });

  test('영구 거부 상태는 다시 요청하지 않는다', () async {
    when(
      () => gateway.isLocationServiceEnabled(),
    ).thenAnswer((_) async => true);
    when(
      () => gateway.checkPermission(),
    ).thenAnswer((_) async => LocationPermission.deniedForever);

    final result = await repository.currentLocation(timeout: _timeout);

    _expectFailure(result, FailureCode.locationPermissionDenied);
    verifyNever(() => gateway.requestPermission());
  });

  test('위치 조회 제한 시간 초과를 구분한다', () async {
    stubServiceAndPermission();
    when(
      () => gateway.getCurrentPosition(timeout: _timeout),
    ).thenThrow(TimeoutException('timeout'));

    final result = await repository.currentLocation(timeout: _timeout);

    _expectFailure(result, FailureCode.locationTimeout);
  });

  test('그 밖의 플랫폼 예외는 unknown으로 감싼다', () async {
    stubServiceAndPermission();
    when(
      () => gateway.getCurrentPosition(timeout: _timeout),
    ).thenThrow(StateError('platform'));

    final result = await repository.currentLocation(timeout: _timeout);

    expect((result as Err<GeoPoint>).failure, isA<UnknownFailure>());
  });
}

void _expectFailure(Result<GeoPoint> result, FailureCode code) {
  expect(result, isA<Err<GeoPoint>>());
  expect((result as Err<GeoPoint>).failure.failureCode, code);
}
