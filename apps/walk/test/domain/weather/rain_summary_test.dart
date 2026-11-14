import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/weather/entity/forecast.dart';
import 'package:walk/domain/weather/entity/weather_condition.dart';
import 'package:walk/domain/weather/rain_summary.dart';

const _kst = Duration(hours: 9);

/// 지역 벽시계 (2026-11-14 + [day]일) [hour]시 의 UTC 절대 시각.
DateTime at(int hour, {int day = 0, Duration offset = _kst}) =>
    DateTime.utc(2026, 11, 14 + day, hour).subtract(offset);

HourlyWeather h(
  int hour, {
  int day = 0,
  int? prob = 0,
  double mm = 0,
  WeatherCondition condition = WeatherCondition.cloudy,
  Duration offset = _kst,
}) => HourlyWeather(
  time: at(hour, day: day, offset: offset),
  temperature: 10,
  precipitationProbability: prob,
  precipitation: mm,
  condition: condition,
  isDay: true,
);

Forecast forecast({
  Duration offset = _kst,
  required List<HourlyWeather> hours,
}) => Forecast(
  utcOffset: offset,
  current: CurrentWeather(
    time: at(0, offset: offset),
    temperature: 10,
    apparentTemperature: 9,
    condition: WeatherCondition.cloudy,
    isDay: true,
    humidity: 50,
    windSpeed: 1,
    precipitation: 0,
  ),
  hourly: hours,
  daily: const [],
);

/// 지역 0~23시 마른 시간 + [overrides] 로 덮어쓴 시간들.
List<HourlyWeather> day(
  Map<int, HourlyWeather> overrides, {
  int dayOffset = 0,
  Duration offset = _kst,
}) => [
  for (var i = 0; i < 24; i++)
    overrides[i] ?? h(i, day: dayOffset, offset: offset),
];

void main() {
  test('오후부터 비', () {
    final f = forecast(
      hours: day({15: h(15, prob: 70, mm: 0.5), 16: h(16, prob: 80, mm: 1.2)}),
    );
    final r = summarizeRain(f, at(10).add(const Duration(minutes: 20)));
    expect(r, isA<RainLater>());
    final later = r as RainLater;
    expect(later.startsAt, at(15));
    expect(later.snow, false);
    expect(later.maxProbability, 80);
    expect(later.totalMm, closeTo(1.7, 1e-9));
  });

  test('지금 비, 17시에 그침', () {
    final f = forecast(
      hours: day({
        10: h(10, prob: 60),
        for (var i = 11; i <= 16; i++) i: h(i, prob: 70, mm: 0.3),
        17: h(17, prob: 10),
      }),
    );
    final r = summarizeRain(f, at(10).add(const Duration(minutes: 20)));
    expect(r, isA<RainNow>());
    expect((r as RainNow).stopsAt, at(17));
    expect(r.maxProbability, 70);
  });

  test('지금 비, 창 안에서 안 그침', () {
    final f = forecast(
      hours: day({for (var i = 10; i < 24; i++) i: h(i, prob: 90, mm: 1)}),
    );
    final r = summarizeRain(f, at(10));
    expect(r, isA<RainNow>());
    expect((r as RainNow).stopsAt, isNull);
  });

  test('비 없음', () {
    final f = forecast(
      hours: day({14: h(14, prob: 30), 15: h(15, prob: 49, mm: 0.09)}),
    );
    final r = summarizeRain(f, at(10));
    expect(r, const RainSummary.none(maxProbability: 49));
  });

  test('확률 null 이어도 강수량 0.2mm 면 비', () {
    final f = forecast(hours: day({15: h(15, prob: null, mm: 0.2)}));
    final r = summarizeRain(f, at(10));
    expect(r, isA<RainLater>());
    expect((r as RainLater).maxProbability, 0);
    expect(r.totalMm, closeTo(0.2, 1e-9));
  });

  test('눈', () {
    final f = forecast(
      hours: day({
        15: h(15, prob: 70, mm: 0.5, condition: WeatherCondition.snow),
        16: h(16, prob: 70, mm: 0.5, condition: WeatherCondition.rain),
      }),
    );
    final r = summarizeRain(f, at(10)) as RainLater;
    expect(r.snow, true);
  });

  group('자정 6시간 전 → 12시간 창', () {
    final hours = [
      ...day({}),
      ...day({5: h(5, day: 1, prob: 80, mm: 1)}, dayOffset: 1),
    ];

    test('지역 19:00 이면 다음날 05시까지 본다', () {
      final r = summarizeRain(forecast(hours: hours), at(19));
      expect(r, isA<RainLater>());
      expect((r as RainLater).startsAt, at(5, day: 1));
    });

    test('지역 17:00 이면 자정까지만 본다', () {
      final r = summarizeRain(forecast(hours: hours), at(17));
      expect(r, isA<NoRain>());
    });

    test('지역 18:00 은 6시간 남아 자정까지', () {
      final r = summarizeRain(forecast(hours: hours), at(18));
      expect(r, isA<NoRain>());
    });
  });

  test('기기 시간대와 무관 — 예보 지역(-5h) 날짜 경계로 자른다', () {
    const off = Duration(hours: -5);
    // 지역 17:00 → 자정까지 7시간이라 자정에서 끊긴다. 다음날 01시 비는 제외.
    final hours = [
      ...day({}, offset: off),
      ...day(
        {1: h(1, day: 1, prob: 90, mm: 2, offset: off)},
        dayOffset: 1,
        offset: off,
      ),
    ];
    final f = forecast(offset: off, hours: hours);
    expect(summarizeRain(f, at(17, offset: off)), isA<NoRain>());
    // 지역 20:00 → 12시간 창이라 다음날 01시 비가 잡힌다.
    final r = summarizeRain(f, at(20, offset: off));
    expect((r as RainLater).startsAt, at(1, day: 1, offset: off));
  });
}
