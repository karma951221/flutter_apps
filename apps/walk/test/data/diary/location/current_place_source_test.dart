import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:location/location.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/data/diary/location/current_place_source.dart';
import 'package:walk/domain/diary/entity/entry_location.dart';
import 'package:walk/domain/diary/location/place_lookup.dart';
import 'package:walk/domain/diary/location/place_source.dart';

class _MockAccess extends Mock implements LocationAccess {}

class _MockGateway extends Mock implements LocationGateway {}

class _FakeNamer implements PlaceNamer {
  _FakeNamer(this.result);
  PlaceLookup result;
  final calls = <(double, double)>[];

  @override
  Future<PlaceLookup> nameFor(double lat, double lng) async {
    calls.add((lat, lng));
    return result;
  }
}

Position _position(double lat, double lng) => Position(
  latitude: lat,
  longitude: lng,
  timestamp: DateTime(2026, 10, 10),
  accuracy: 5,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

void main() {
  late _MockAccess access;
  late _MockGateway gateway;
  late _FakeNamer namer;
  late CurrentPlaceSource source;

  Future<Position> getPosition() => gateway.getCurrentPosition(
    accuracy: any(named: 'accuracy'),
    timeout: any(named: 'timeout'),
  );

  setUpAll(() {
    registerFallbackValue(LocationAccuracy.high);
    registerFallbackValue(Duration.zero);
  });

  setUp(() {
    access = _MockAccess();
    gateway = _MockGateway();
    namer = _FakeNamer(const PlaceLookup.named('애월읍'));
    when(
      () => access.ensure(),
    ).thenAnswer((_) async => LocationAccessStatus.granted);
    when(getPosition).thenAnswer((_) async => _position(33.46, 126.33));
    source = CurrentPlaceSource(
      access,
      gateway,
      namer,
      timeout: const Duration(milliseconds: 50),
    );
  });

  test('권한이 있으면 좌표와 이름을 돌려준다', () async {
    expect(
      await source.current(),
      const EntryLocation(placeName: '애월읍', lat: 33.46, lng: 126.33),
    );
    expect(namer.calls, [(33.46, 126.33)]);
  });

  test('위치 서비스 꺼짐 → null(오류 아님), 위치는 읽지 않는다', () async {
    when(
      () => access.ensure(),
    ).thenAnswer((_) async => LocationAccessStatus.serviceDisabled);

    expect(await source.current(), isNull);
    verifyNever(getPosition);
  });

  test('권한 거부 → null', () async {
    when(
      () => access.ensure(),
    ).thenAnswer((_) async => LocationAccessStatus.permissionDenied);

    expect(await source.current(), isNull);
    verifyNever(getPosition);
  });

  test('위치 읽기가 예외를 던지면 null', () async {
    when(getPosition).thenThrow(TimeoutException('gps'));

    expect(await source.current(), isNull);
  });

  test('위치가 끝나지 않으면 타임아웃 뒤 null', () async {
    when(getPosition).thenAnswer((_) => Completer<Position>().future);

    expect(await source.current(), isNull);
  });

  test('이름을 못 얻으면(namer null) 좌표만 돌려준다', () async {
    namer.result = const PlaceLookup.offline();

    final location = await source.current();

    expect(location, const EntryLocation(lat: 33.46, lng: 126.33));
    expect(location!.hasCoordinates, isTrue);
  });

  test('nameFor 는 namer 에 위임한다', () async {
    expect(await source.nameFor(1, 2), const PlaceLookup.named('애월읍'));
    expect(namer.calls, [(1.0, 2.0)]);
  });
}
