import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:location/location.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/data/weather/weather_location_source.dart';
import 'package:walk/domain/diary/location/place_lookup.dart';
import 'package:walk/domain/diary/location/place_source.dart';
import 'package:walk/domain/weather/weather_locator.dart';
import 'package:walk/domain/weather/weather_problem.dart';

class _MockGateway extends Mock implements LocationGateway {}

class _FakeNamer implements PlaceNamer {
  PlaceLookup result = const PlaceLookup.noName();
  Object? error;

  @override
  Future<PlaceLookup> nameFor(double lat, double lng) async {
    if (error != null) throw error!;
    return result;
  }
}

Position _position(double lat, double lng) => Position(
  latitude: lat,
  longitude: lng,
  timestamp: DateTime(2026, 11, 14),
  accuracy: 5,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

void main() {
  late _MockGateway gateway;
  late _FakeNamer namer;
  late WeatherLocationSource source;

  Future<Position> getPosition() => gateway.getCurrentPosition(
    accuracy: any(named: 'accuracy'),
    timeout: any(named: 'timeout'),
  );

  setUpAll(() {
    registerFallbackValue(LocationAccuracy.low);
    registerFallbackValue(Duration.zero);
  });

  setUp(() {
    gateway = _MockGateway();
    namer = _FakeNamer();
    when(() => gateway.isLocationServiceEnabled()).thenAnswer((_) async => true);
    when(
      () => gateway.checkPermission(),
    ).thenAnswer((_) async => LocationPermission.whileInUse);
    when(() => gateway.openAppSettings()).thenAnswer((_) async => true);
    when(() => gateway.openLocationSettings()).thenAnswer((_) async => true);
    source = WeatherLocationSource(LocationAccess(gateway), gateway, namer);
  });

  group('locate', () {
    test('서비스 꺼짐 → failed(locationServiceOff)', () async {
      when(
        () => gateway.isLocationServiceEnabled(),
      ).thenAnswer((_) async => false);

      final fix = await source.locate();

      expect(fix, const WeatherFix.failed(WeatherProblem.locationServiceOff));
    });

    test('권한 거부 → failed(locationDenied)', () async {
      when(
        () => gateway.checkPermission(),
      ).thenAnswer((_) async => LocationPermission.deniedForever);

      final fix = await source.locate();

      expect(fix, const WeatherFix.failed(WeatherProblem.locationDenied));
    });

    test('getCurrentPosition 은 LocationAccuracy.low, 8초로 부른다', () async {
      when(getPosition).thenAnswer((_) async => _position(33.5, 126.5));

      final fix = await source.locate();

      expect(fix, const WeatherFix.located(33.5, 126.5));
      verify(
        () => gateway.getCurrentPosition(
          accuracy: LocationAccuracy.low,
          timeout: const Duration(seconds: 8),
        ),
      ).called(1);
    });

    test('시간 초과 → failed(locationUnavailable)', () async {
      source = WeatherLocationSource(
        LocationAccess(gateway),
        gateway,
        namer,
        timeout: const Duration(milliseconds: 10),
      );
      when(getPosition).thenAnswer((_) => Completer<Position>().future);

      final fix = await source.locate();

      expect(fix, const WeatherFix.failed(WeatherProblem.locationUnavailable));
    });

    test('예외 → failed(locationUnavailable)', () async {
      when(getPosition).thenThrow(Exception('boom'));

      final fix = await source.locate();

      expect(fix, const WeatherFix.failed(WeatherProblem.locationUnavailable));
    });
  });

  group('placeName', () {
    test('PlaceNamed → 이름', () async {
      namer.result = const PlaceLookup.named('애월읍');

      expect(await source.placeName(1, 2), '애월읍');
    });

    test('PlaceNoName · PlaceOffline · 예외 → null', () async {
      namer.result = const PlaceLookup.noName();
      expect(await source.placeName(1, 2), isNull);

      namer.result = const PlaceLookup.offline();
      expect(await source.placeName(1, 2), isNull);

      namer.error = Exception('boom');
      expect(await source.placeName(1, 2), isNull);
    });
  });

  group('resolve', () {
    test('locationDenied → 다시 요청, 그래도 거부면 설정 열기', () async {
      when(
        () => gateway.requestPermission(),
      ).thenAnswer((_) async => LocationPermission.denied);

      await source.resolve(WeatherProblem.locationDenied);

      verify(() => gateway.requestPermission()).called(1);
      verify(() => gateway.openAppSettings()).called(1);
    });

    test('locationDenied → 다시 요청해 허용되면 설정은 열지 않는다', () async {
      when(
        () => gateway.requestPermission(),
      ).thenAnswer((_) async => LocationPermission.whileInUse);

      await source.resolve(WeatherProblem.locationDenied);

      verify(() => gateway.requestPermission()).called(1);
      verifyNever(() => gateway.openAppSettings());
    });

    test('locationServiceOff → 위치 설정 열기', () async {
      await source.resolve(WeatherProblem.locationServiceOff);

      verify(() => gateway.openLocationSettings()).called(1);
    });

    test('나머지는 아무것도 하지 않는다', () async {
      await source.resolve(WeatherProblem.locationUnavailable);
      await source.resolve(WeatherProblem.offline);
      await source.resolve(WeatherProblem.server);

      verifyNever(() => gateway.requestPermission());
      verifyNever(() => gateway.openAppSettings());
      verifyNever(() => gateway.openLocationSettings());
    });
  });
}
