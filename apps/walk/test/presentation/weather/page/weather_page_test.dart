import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/weather/entity/forecast.dart';
import 'package:walk/domain/weather/entity/weather_condition.dart';
import 'package:walk/domain/weather/weather_problem.dart';
import 'package:walk/presentation/weather/cubit/weather_cubit.dart';
import 'package:walk/presentation/weather/cubit/weather_state.dart';
import 'package:walk/presentation/weather/page/weather_page.dart';
import 'package:walk/presentation/weather/widget/daily_list.dart';
import 'package:walk/presentation/weather/widget/hourly_strip.dart';

class _MockCubit extends MockCubit<WeatherState> implements WeatherCubit {}

class _FixedClock extends Clock {
  const _FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}

const _kst = Duration(hours: 9);

/// 예보 지역 벽시계 (2026-11-14 + [day]일) [hour]시 의 UTC 절대 시각.
DateTime at(int hour, {int day = 0}) =>
    DateTime.utc(2026, 11, 14 + day, hour).subtract(_kst);

final _now = at(10).add(const Duration(minutes: 20));

/// 오늘 15 · 16시에 비가 오는 이틀치 예보.
final _forecast = Forecast(
  utcOffset: _kst,
  current: CurrentWeather(
    time: at(10),
    temperature: 12.3,
    apparentTemperature: 10,
    condition: WeatherCondition.cloudy,
    isDay: true,
    humidity: 82,
    windSpeed: 3,
    precipitation: 0,
  ),
  hourly: [
    for (var i = 0; i < 48; i++)
      HourlyWeather(
        time: at(0).add(Duration(hours: i)),
        temperature: 10,
        precipitationProbability: switch (i) {
          15 => 70,
          16 => 80,
          20 => null,
          _ => 10,
        },
        precipitation: switch (i) {
          15 => 0.5,
          16 => 1.2,
          _ => 0,
        },
        condition: i == 15 || i == 16
            ? WeatherCondition.rain
            : WeatherCondition.cloudy,
        isDay: i % 24 >= 7 && i % 24 < 18,
      ),
  ],
  daily: [
    for (var d = 0; d < 7; d++)
      DailyWeather(
        date: at(0, day: d),
        condition: WeatherCondition.rain,
        tempMax: 14.0 + d,
        tempMin: 8.0 - d,
        precipitationProbabilityMax: 70,
        precipitationSum: 4,
        sunrise: at(7, day: d).add(const Duration(minutes: 2)),
        sunset: at(17, day: d).add(const Duration(minutes: 22)),
      ),
  ],
);

WeatherState _loaded({
  String? placeName = '망원동',
  DateTime? fetchedAt,
  bool stale = false,
  WeatherProblem? problem,
}) => WeatherState.loaded(
  forecast: _forecast,
  placeName: placeName,
  fetchedAt: fetchedAt ?? at(10).add(const Duration(minutes: 2)),
  stale: stale,
  problem: problem,
);

void main() {
  late _MockCubit cubit;

  setUpAll(() => registerFallbackValue(WeatherProblem.offline));
  setUp(() {
    cubit = _MockCubit();
    getIt.registerSingleton<Clock>(_FixedClock(_now));
    when(() => cubit.shown()).thenAnswer((_) async {});
    when(() => cubit.refresh()).thenAnswer((_) async {});
    when(() => cubit.resolve(any())).thenAnswer((_) async {});
  });
  tearDown(() => getIt.reset());

  Future<void> pump(
    WidgetTester tester,
    WeatherState state, {
    bool active = true,
    Size size = const Size(800, 2400),
  }) async {
    when(() => cubit.state).thenReturn(state);
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BlocProvider<WeatherCubit>.value(
            value: cubit,
            child: WeatherPage(active: active),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('loaded → 장소 · 기온 · 비 요약 · 시간별 24칸 · 일별 7행 · Open-Meteo 표기', (
    tester,
  ) async {
    await pump(tester, _loaded());

    expect(find.text('망원동'), findsOneWidget);
    expect(find.text('12°'), findsOneWidget);
    expect(find.text('흐림'), findsOneWidget);
    expect(find.text('체감 10° · 최고 14° 최저 8°'), findsOneWidget);
    expect(find.text('오후 3시쯤부터 비가 와요'), findsOneWidget);
    expect(find.text('최대 80% · 1.7mm'), findsOneWidget);
    expect(find.byType(HourlyCell), findsNWidgets(24));
    expect(find.text('지금'), findsOneWidget);
    // 강수확률을 모르는 20시는 "–".
    expect(find.text('–'), findsOneWidget);
    expect(find.byType(DailyRow), findsNWidgets(7));
    expect(find.text('오늘'), findsOneWidget);
    expect(find.text('내일'), findsOneWidget);
    expect(find.text('습도 82% · 바람 3m/s · 일출 07:02 · 일몰 17:22'), findsOneWidget);
    expect(find.text('10:02 갱신 · Open-Meteo'), findsOneWidget);
  });

  testWidgets('비 시간의 강수확률은 강조색', (tester) async {
    await pump(tester, _loaded());

    final primary = Theme.of(
      tester.element(find.text('70%').first),
    ).colorScheme.primary;
    final rainy = tester.widget<Text>(
      find.descendant(of: find.byType(HourlyCell), matching: find.text('80%')),
    );
    final dry = tester.widget<Text>(
      find
          .descendant(of: find.byType(HourlyCell), matching: find.text('10%'))
          .first,
    );
    expect(rainy.style?.color, primary);
    expect(dry.style?.color, isNot(primary));
  });

  testWidgets('폰 폭에서도 넘치지 않는다', (tester) async {
    await pump(
      tester,
      _loaded(
        placeName: '서울특별시 마포구 망원동 아주 긴 장소 이름',
        fetchedAt: _now.subtract(const Duration(hours: 3)),
        stale: true,
        problem: WeatherProblem.offline,
      ),
      size: const Size(360, 780),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('placeName null → 현재 위치', (tester) async {
    await pump(tester, _loaded(placeName: null));

    expect(find.text('현재 위치'), findsOneWidget);
  });

  testWidgets('stale + problem → 문제 줄', (tester) async {
    await pump(
      tester,
      _loaded(
        fetchedAt: _now.subtract(const Duration(hours: 3, minutes: 5)),
        stale: true,
        problem: WeatherProblem.locationUnavailable,
      ),
    );

    expect(find.text('위치를 못 읽어 3시간 전 망원동 예보예요'), findsOneWidget);
  });

  testWidgets('문제가 없으면 문제 줄이 없다', (tester) async {
    await pump(tester, _loaded());

    expect(find.textContaining('예보예요'), findsNothing);
  });

  testWidgets('empty(locationDenied) → 권한 허용 누르면 resolve(locationDenied)', (
    tester,
  ) async {
    await pump(tester, const WeatherState.empty(WeatherProblem.locationDenied));

    expect(find.text('위치 권한이 필요해요'), findsOneWidget);
    await tester.tap(find.text('권한 허용'));
    verify(() => cubit.resolve(WeatherProblem.locationDenied)).called(1);
  });

  testWidgets('empty(locationServiceOff) → 위치 켜기 누르면 resolve', (tester) async {
    await pump(
      tester,
      const WeatherState.empty(WeatherProblem.locationServiceOff),
    );

    await tester.tap(find.text('위치 켜기'));
    verify(() => cubit.resolve(WeatherProblem.locationServiceOff)).called(1);
  });

  testWidgets('empty(offline) → 다시 시도 누르면 refresh', (tester) async {
    await pump(tester, const WeatherState.empty(WeatherProblem.offline));

    expect(find.text('인터넷에 연결되지 않았어요'), findsOneWidget);
    await tester.tap(find.text('다시 시도'));
    verify(() => cubit.refresh()).called(1);
  });

  testWidgets('loading → 진행 표시', (tester) async {
    when(() => cubit.state).thenReturn(const WeatherState.loading());
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<WeatherCubit>.value(
          value: cubit,
          child: const WeatherPage(active: true),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('당기면 refresh', (tester) async {
    await pump(tester, _loaded());

    await tester.fling(find.text('망원동'), const Offset(0, 1000), 1000);
    await tester.pumpAndSettle();
    verify(() => cubit.refresh()).called(1);
  });

  testWidgets('빈 상태에서도 당기면 refresh', (tester) async {
    await pump(tester, const WeatherState.empty(WeatherProblem.server));

    await tester.fling(find.text('날씨를 받아 오지 못했어요'), const Offset(0, 1000), 1000);
    await tester.pumpAndSettle();
    verify(() => cubit.refresh()).called(1);
  });

  testWidgets('처음 active 면 shown 한 번', (tester) async {
    await pump(tester, _loaded());

    verify(() => cubit.shown()).called(1);
  });

  testWidgets('active false→true 에서만 shown', (tester) async {
    await pump(tester, _loaded(), active: false);
    verifyNever(() => cubit.shown());

    await pump(tester, _loaded(), active: true);
    verify(() => cubit.shown()).called(1);

    // true 그대로 다시 그려도 부르지 않는다.
    await pump(tester, _loaded(), active: true);
    verifyNever(() => cubit.shown());

    await pump(tester, _loaded(), active: false);
    await pump(tester, _loaded(), active: true);
    verify(() => cubit.shown()).called(1);
  });
}
