import 'dart:convert';

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/chat/tool/location_tools.dart';
import 'package:walk/domain/chat/tool/tool_summary.dart';
import 'package:walk/domain/location/entity/location_point.dart';
import 'package:walk/domain/location/entity/record_mode.dart';
import 'package:walk/domain/location/recorder/location_recorder.dart';
import 'package:walk/domain/location/recorder/recorder_status.dart';
import 'package:walk/domain/location/repository/location_repository.dart';
import 'package:walk/domain/location/usecase/location_sync.dart';
import 'package:walk/domain/location/usecase/stay_namer.dart';

class _Repo extends Mock implements LocationRepository {}

class _Sync extends Mock implements LocationSync {}

class _Recorder extends Mock implements LocationRecorder {}

class _Namer extends Mock implements StayNamer {}

class _FixedClock extends Clock {
  const _FixedClock(this.value);
  final DateTime value;
  @override
  DateTime now() => value;
}

/// [at](로컬)부터 [minutes] 분 동안 10분 간격 점(같은 자리).
List<LocationPoint> _stay(
  DateTime at,
  int minutes, {
  double lat = 37.5,
  double lng = 127.0,
}) => [
  for (var m = 0; m <= minutes; m += 10)
    LocationPoint(
      recordedAt: at.add(Duration(minutes: m)).toUtc(),
      lat: lat,
      lng: lng,
      mode: RecordMode.normal,
    ),
];

void main() {
  setUpAll(() => registerFallbackValue(DateTime(2000)));

  late _Repo repo;
  late _Sync sync;
  late _Recorder recorder;
  late _Namer namer;
  late LocationTools tools;
  var points = <LocationPoint>[];

  setUp(() {
    repo = _Repo();
    sync = _Sync();
    recorder = _Recorder();
    namer = _Namer();
    points = [];
    when(() => sync.run()).thenAnswer((_) async => 0);
    when(
      () => recorder.status(),
    ).thenAnswer((_) async => const RecorderStatus.off());
    when(() => repo.hasAnyPoint()).thenAnswer((_) async => points.isNotEmpty);
    when(() => repo.pointsAround(any(), any())).thenAnswer((inv) async {
      final from = inv.positionalArguments[0] as DateTime;
      final to = inv.positionalArguments[1] as DateTime;
      return [
        for (final p in points)
          if (!p.recordedAt.isBefore(from) && !p.recordedAt.isAfter(to)) p,
      ];
    });
    when(() => repo.placeName(any())).thenAnswer((_) async => null);
    when(() => namer.nameFor(any(), any())).thenAnswer((_) async => '회사');
    tools = LocationTools(
      repo,
      sync,
      recorder,
      namer,
      _FixedClock(DateTime(2026, 11, 16, 12)),
    );
  });

  Future<Map<String, Object?>> visited(String from, String to) async {
    final r = await tools.run('visited_places', {'from': from, 'to': to});
    expect(r.isError, isFalse, reason: r.json);
    return jsonDecode(r.json) as Map<String, Object?>;
  }

  test('정의는 visited_places · frequent_places', () {
    expect(
      [for (final d in tools.definitions) d.name],
      ['visited_places', 'frequent_places'],
    );
  });

  test('위치 점이 하나도 없으면 location_not_recorded', () async {
    for (final name in ['visited_places', 'frequent_places']) {
      final r = await tools.run(name, {
        'from': '2026-11-01',
        'to': '2026-11-16',
      });
      expect(r.isError, isTrue);
      expect(jsonDecode(r.json), {'error': 'location_not_recorded'});
    }
  });

  test('먼저 네이티브 기록을 수거한다', () async {
    points = _stay(DateTime(2026, 11, 14, 9), 60);
    await visited('2026-11-14', '2026-11-14');
    verify(() => sync.run()).called(1);
  });

  test('머문 곳을 로컬 시각 · 분 · 이름으로 주고 좌표는 넣지 않는다', () async {
    points = _stay(DateTime(2026, 11, 14, 9), 580);
    final r = await tools.run('visited_places', {
      'from': '2026-11-14',
      'to': '2026-11-14',
    });
    expect(r.json, isNot(contains('lat')));
    expect(r.json, isNot(contains('37.5')));
    expect(r.summary?.kind, ChatToolKind.visitedPlaces);
    expect(r.summary?.count, 1);
    final json = jsonDecode(r.json) as Map<String, Object?>;
    expect(json['stays'], [
      {
        'date': '2026-11-14',
        'start': '09:00',
        'end': '18:40',
        'minutes': 580,
        'place': '회사',
      },
    ]);
    expect(json['recording'], 'off');
    expect(json['truncated'], isFalse);
  });

  test('자정을 넘긴 머묾은 end_date 를 함께 준다', () async {
    points = _stay(DateTime(2026, 11, 13, 22), 600);
    final json = await visited('2026-11-13', '2026-11-14');
    final stay = (json['stays']! as List).single as Map;
    expect(stay['date'], '2026-11-13');
    expect(stay['end_date'], '2026-11-14');
    expect(stay['end'], '08:00');
  });

  test('이름을 못 얻으면 place 는 null 이고 도구는 성공한다', () async {
    when(() => namer.nameFor(any(), any())).thenAnswer((_) async => null);
    points = _stay(DateTime(2026, 11, 14, 9), 60);
    final json = await visited('2026-11-14', '2026-11-14');
    expect(((json['stays']! as List).single as Map)['place'], isNull);
  });

  test('캐시에 있는 이름은 새로 묻지 않는다', () async {
    when(() => repo.placeName(any())).thenAnswer((_) async => '집');
    points = _stay(DateTime(2026, 11, 14, 9), 60);
    final json = await visited('2026-11-14', '2026-11-14');
    expect(((json['stays']! as List).single as Map)['place'], '집');
    verifyNever(() => namer.nameFor(any(), any()));
  });

  test('새 이름 조회는 최근 것부터 20곳까지만', () async {
    points = [
      for (var i = 0; i < 25; i++)
        ..._stay(
          DateTime(2026, 11, 14, 0, 0).add(Duration(minutes: 30 * i)),
          10,
          lat: 37 + i * 0.01,
        ),
    ];
    final json = await visited('2026-11-14', '2026-11-14');
    final stays = json['stays']! as List;
    expect(stays, hasLength(25));
    verify(() => namer.nameFor(any(), any())).called(20);
    expect([
      for (final s in stays.take(5)) (s as Map)['place'],
    ], everyElement(isNull));
    expect([
      for (final s in stays.skip(5)) (s as Map)['place'],
    ], everyElement('회사'));
  });

  test('머문 곳이 150개를 넘으면 최근 150개와 truncated', () async {
    points = [
      for (var i = 0; i < 160; i++)
        ..._stay(
          DateTime(2026, 11, 1).add(Duration(minutes: 30 * i)),
          10,
          lat: 37 + (i % 2) * 0.01,
        ),
    ];
    final json = await visited('2026-11-01', '2026-11-16');
    final stays = json['stays']! as List;
    expect(stays, hasLength(150));
    expect(json['truncated'], isTrue);
    // 가장 오래된 10개가 빠졌다 — 첫 항목은 11번째(i = 10, 11-01 05:00).
    expect((stays.first as Map)['start'], '05:00');
  });

  test('31일을 넘는 범위는 잘리고 clamped', () async {
    points = _stay(DateTime(2026, 11, 14, 9), 60);
    final json = await visited('2026-09-01', '2026-11-16');
    expect(json['clamped'], isTrue);
  });

  test('날짜가 틀리면 invalid_range', () async {
    points = _stay(DateTime(2026, 11, 14, 9), 60);
    final r = await tools.run('visited_places', {
      'from': '2026-11-15',
      'to': '2026-11-14',
    });
    expect(jsonDecode(r.json), {'error': 'invalid_range'});
  });

  test('기록 상태: running → on, blocked → blocked, 실패 → unknown', () async {
    points = _stay(DateTime(2026, 11, 14, 9), 60);
    when(() => recorder.status()).thenAnswer(
      (_) async =>
          const RecorderStatus.running(RecordMode.normal, stillDetection: true),
    );
    expect((await visited('2026-11-14', '2026-11-14'))['recording'], 'on');
    when(
      () => recorder.status(),
    ).thenAnswer((_) async => const RecorderStatus.blocked(RecordMode.normal));
    expect((await visited('2026-11-14', '2026-11-14'))['recording'], 'blocked');
    when(() => recorder.status()).thenThrow(Exception('x'));
    expect((await visited('2026-11-14', '2026-11-14'))['recording'], 'unknown');
  });

  test('수거가 실패해도 저장된 점으로 답한다', () async {
    when(() => sync.run()).thenThrow(Exception('x'));
    points = _stay(DateTime(2026, 11, 14, 9), 60);
    final json = await visited('2026-11-14', '2026-11-14');
    expect(json['stays'], hasLength(1));
  });

  test('frequent_places: 방문 횟수 순 · 시간 · 마지막 날, 좌표 없음', () async {
    points = [
      ..._stay(DateTime(2026, 11, 10, 9), 120),
      ..._stay(DateTime(2026, 11, 11, 9), 60),
      ..._stay(DateTime(2026, 11, 12, 9), 60),
      ..._stay(DateTime(2026, 11, 12, 15), 30, lat: 37.6),
    ];
    when(() => namer.nameFor(37.6, any())).thenAnswer((_) async => '카페');
    final r = await tools.run('frequent_places', {
      'from': '2026-11-01',
      'to': '2026-11-16',
    });
    expect(r.isError, isFalse, reason: r.json);
    expect(r.json, isNot(contains('lat')));
    expect(r.summary?.kind, ChatToolKind.frequentPlaces);
    final places = (jsonDecode(r.json) as Map)['places'] as List;
    expect(places.first, {
      'place': '회사',
      'visits': 3,
      'hours': 4.0,
      'last': '2026-11-12',
    });
    expect(places[1], {
      'place': '카페',
      'visits': 1,
      'hours': 0.5,
      'last': '2026-11-12',
    });
  });

  test('frequent_places 는 31일 덩어리로 나눠 읽는다', () async {
    points = _stay(DateTime(2026, 11, 14, 9), 60);
    await tools.run('frequent_places', {
      'from': '2026-01-01',
      'to': '2026-11-16',
    });
    // 320일 → 31일 덩어리 11개.
    verify(() => repo.pointsAround(any(), any())).called(11);
  });
}
