import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/domain/weather/entity/forecast.dart';
import 'package:walk/domain/weather/entity/weather_condition.dart';
import 'package:walk/domain/weather/rain_summary.dart';
import 'package:walk/domain/weather/weather_problem.dart';
import 'package:walk/presentation/weather/format/weather_format.dart';

const _kst = Duration(hours: 9);

/// 예보 지역 벽시계 (2026-11-14 + [day]일) [hour]시 의 UTC 절대 시각.
DateTime at(int hour, {int day = 0, Duration offset = _kst}) =>
    DateTime.utc(2026, 11, 14 + day, hour).subtract(offset);

Forecast forecast({Duration offset = _kst}) => Forecast(
  utcOffset: offset,
  current: CurrentWeather(
    time: at(10, offset: offset),
    temperature: 12,
    apparentTemperature: 10,
    condition: WeatherCondition.cloudy,
    isDay: true,
    humidity: 82,
    windSpeed: 3,
    precipitation: 0,
  ),
  hourly: const [],
  daily: const [],
);

void main() {
  final l10n = lookupAppLocalizations(const Locale('ko'));
  setUpAll(() => initializeDateFormatting('ko'));

  group('시각 라벨 — 예보 지역 기준', () {
    test('15시 → 오후 3시', () {
      expect(WeatherFormat.time(l10n, forecast(), at(15), at(10)), '오후 3시');
    });

    test('내일 05시 → 내일 오전 5시', () {
      expect(
        WeatherFormat.time(l10n, forecast(), at(5, day: 1), at(22)),
        '내일 오전 5시',
      );
    });

    test('기기와 다른 시간대여도 예보 지역의 날짜로 오늘을 가른다', () {
      const ny = Duration(hours: -5);
      final f = forecast(offset: ny);
      // UTC 로는 이미 다음 날이지만 뉴욕은 아직 오늘 밤 11시다.
      expect(
        WeatherFormat.time(l10n, f, at(23, offset: ny), at(22, offset: ny)),
        '오후 11시',
      );
      expect(WeatherFormat.clock(f, at(7, offset: ny)), '07:00');
    });
  });

  group('비 요약 문구', () {
    test('RainLater 문구', () {
      final copy = WeatherFormat.rain(
        l10n,
        forecast(),
        RainSummary.later(
          startsAt: at(15),
          snow: false,
          maxProbability: 70,
          totalMm: 4,
        ),
        at(10),
      );
      expect(copy.title, '오후 3시쯤부터 비가 와요');
      expect(copy.subtitle, '최대 70% · 4mm');
    });

    test('RainNow 그침/안 그침', () {
      final stops = WeatherFormat.rain(
        l10n,
        forecast(),
        RainSummary.now(
          stopsAt: at(17),
          snow: false,
          maxProbability: 80,
          totalMm: 1.7,
        ),
        at(10),
      );
      expect(stops.title, '지금 비가 와요 · 오후 5시쯤 그쳐요');
      expect(stops.subtitle, '최대 80% · 1.7mm');

      final late = WeatherFormat.rain(
        l10n,
        forecast(),
        const RainSummary.now(snow: false, maxProbability: 90, totalMm: 12.34),
        at(10),
      );
      expect(late.title, '지금 비가 와요 · 오늘 밤 이후에 그쳐요');
      expect(late.subtitle, '최대 90% · 12mm');
    });

    test('NoRain', () {
      final copy = WeatherFormat.rain(
        l10n,
        forecast(),
        const RainSummary.none(maxProbability: 20),
        at(10),
      );
      expect(copy.title, '오늘은 비 소식이 없어요');
      expect(copy.subtitle, '최대 강수확률 20%');
    });

    test('눈', () {
      final later = WeatherFormat.rain(
        l10n,
        forecast(),
        RainSummary.later(
          startsAt: at(5, day: 1),
          snow: true,
          maxProbability: 60,
          totalMm: 0,
        ),
        at(22),
      );
      expect(later.title, '내일 오전 5시쯤부터 눈이 와요');
      // 강수량이 0 이면 mm 를 적지 않는다.
      expect(later.subtitle, '최대 강수확률 60%');

      final now = WeatherFormat.rain(
        l10n,
        forecast(),
        const RainSummary.now(snow: true, maxProbability: 60, totalMm: 0.4),
        at(10),
      );
      expect(now.title, '지금 눈이 와요 · 오늘 밤 이후에 그쳐요');
    });
  });

  group('상태 아이콘 · 라벨', () {
    test('밤 clear → 달 아이콘', () {
      expect(
        WeatherFormat.icon(WeatherCondition.clear, isDay: false),
        Icons.nightlight_round,
      );
      expect(
        WeatherFormat.icon(WeatherCondition.partlyCloudy, isDay: false),
        Icons.nights_stay,
      );
      expect(
        WeatherFormat.icon(WeatherCondition.clear, isDay: true),
        isNot(Icons.nightlight_round),
      );
      // 비는 밤에도 같은 아이콘.
      expect(
        WeatherFormat.icon(WeatherCondition.rain, isDay: false),
        WeatherFormat.icon(WeatherCondition.rain, isDay: true),
      );
    });

    test('라벨', () {
      expect(WeatherFormat.condition(l10n, WeatherCondition.clear), '맑음');
      expect(
        WeatherFormat.condition(l10n, WeatherCondition.partlyCloudy),
        '구름 조금',
      );
      expect(WeatherFormat.condition(l10n, WeatherCondition.unknown), '알 수 없음');
    });

    test('기온 · 확률', () {
      expect(WeatherFormat.temperature(12.4), '12°');
      expect(WeatherFormat.temperature(-0.4), '0°');
      expect(WeatherFormat.probability(70), '70%');
      expect(WeatherFormat.probability(null), '–');
    });
  });

  group('문제 줄', () {
    final fetchedAt = at(7);

    test('stale — 몇 시간 전 어느 장소 예보인지', () {
      expect(
        WeatherFormat.problem(
          l10n,
          WeatherProblem.locationUnavailable,
          stale: true,
          placeName: '망원동',
          fetchedAt: fetchedAt,
          now: at(10),
        ),
        '위치를 못 읽어 3시간 전 망원동 예보예요',
      );
      expect(
        WeatherFormat.problem(
          l10n,
          WeatherProblem.offline,
          stale: true,
          placeName: null,
          fetchedAt: at(9).add(const Duration(minutes: 35)),
          now: at(10),
        ),
        '인터넷에 연결되지 않아 25분 전 마지막 위치 예보예요',
      );
    });

    test('stale 아님 — 위치 실패, 마지막 위치로 새 예보', () {
      expect(
        WeatherFormat.problem(
          l10n,
          WeatherProblem.locationDenied,
          stale: false,
          placeName: '망원동',
          fetchedAt: at(10),
          now: at(10),
        ),
        '위치 권한이 없어 마지막 위치(망원동)의 예보예요',
      );
      expect(
        WeatherFormat.problem(
          l10n,
          WeatherProblem.locationServiceOff,
          stale: false,
          placeName: null,
          fetchedAt: at(10),
          now: at(10),
        ),
        '위치가 꺼져 있어 마지막 위치의 예보예요',
      );
    });
  });
}
