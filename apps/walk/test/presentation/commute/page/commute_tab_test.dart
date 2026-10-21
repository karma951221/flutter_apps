import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/commute/commute_failure.dart';
import 'package:walk/domain/commute/entity/catch_verdict.dart';
import 'package:walk/domain/commute/entity/commute_direction.dart';
import 'package:walk/domain/commute/entity/commute_result.dart';
import 'package:walk/domain/commute/entity/place.dart';
import 'package:walk/domain/commute/entity/train_arrival.dart';
import 'package:walk/domain/commute/entity/transit_route.dart';
import 'package:walk/presentation/commute/cubit/commute_cubit.dart';
import 'package:walk/presentation/commute/cubit/commute_state.dart';
import 'package:walk/presentation/commute/page/commute_tab.dart';

import '../../../support/diary_fixtures.dart';

class _MockCubit extends MockCubit<CommuteState> implements CommuteCubit {}

final _now = DateTime(2026, 10, 21, 8, 11);

const _home = Place(
  kind: PlaceKind.home,
  lat: 37.5,
  lng: 126.9,
  label: '동작구 상도동',
);
const _work = Place(
  kind: PlaceKind.work,
  lat: 37.5,
  lng: 127.0,
  label: '강남구 역삼동',
);

const _route = TransitRoute(
  totalMinutes: 41,
  transferCount: 1,
  legs: [
    RouteLeg.walk(minutes: 6),
    RouteLeg.subway(
      minutes: 16,
      lineName: '7호선',
      odsayLaneCode: 7,
      startStation: '장승배기',
      endStation: '논현',
      wayCode: 1,
      wayName: '장암 방면',
      stationCount: 8,
    ),
    RouteLeg.walk(minutes: 3),
    RouteLeg.subway(
      minutes: 2,
      lineName: '신분당선',
      odsayLaneCode: 109,
      startStation: '신논현',
      endStation: '강남',
      wayCode: 2,
      wayName: '광교 방면',
      stationCount: 1,
    ),
    RouteLeg.walk(minutes: 7),
  ],
);

CommuteResult _result({
  RealtimeStatus realtime = RealtimeStatus.ok,
  bool etaFromRealtime = true,
  List<TransitRoute> alternatives = const [_route],
  DateTime? queriedAt,
}) => CommuteResult(
  direction: CommuteDirection.toWork,
  route: _route,
  alternatives: alternatives,
  arrivals: realtime == RealtimeStatus.ok
      ? const [
          TrainArrival(minutes: 8, stationsAway: 3, message: '[3]번째 전역'),
          TrainArrival(minutes: 15, stationsAway: 7, message: '[7]번째 전역'),
        ]
      : const [],
  realtime: realtime,
  verdict: realtime == RealtimeStatus.ok
      ? const CatchVerdict.catchFirst()
      : const CatchVerdict.unknown(),
  eta: DateTime(2026, 10, 21, 8, 35),
  etaFromRealtime: etaFromRealtime,
  queriedAt: queriedAt ?? _now,
);

CommuteState _state({
  Place? home = _home,
  Place? work = _work,
  CommuteStatus status = const CommuteStatus.idle(),
}) => CommuteState(
  direction: CommuteDirection.toWork,
  home: home,
  work: work,
  status: status,
);

void main() {
  late _MockCubit cubit;
  late MutableClock clock;
  late List<PlaceKind> edited;
  late int routesShown;

  setUp(() {
    cubit = _MockCubit();
    when(() => cubit.query()).thenAnswer((_) async {});
    clock = MutableClock(_now);
    getIt.registerSingleton<Clock>(clock);
    edited = [];
    routesShown = 0;
  });
  tearDown(getIt.reset);

  Future<void> pump(
    WidgetTester tester,
    CommuteState state, {
    bool active = true,
  }) async {
    when(() => cubit.state).thenReturn(state);
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<CommuteCubit>.value(
          value: cubit,
          child: CommuteView(
            active: active,
            onEditPlace: edited.add,
            onShowRoutes: () => routesShown++,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('집 · 회사가 없으면 먼저 정하라는 안내', (tester) async {
    await pump(tester, _state(home: null));

    expect(find.text('집과 회사를 먼저 정해 주세요'), findsOneWidget);
    expect(find.text('정하기'), findsOneWidget);
  });

  testWidgets('장소 줄: 출근은 집 → 회사, 누르면 그 장소를 고치는 훅을 부른다', (tester) async {
    await pump(tester, _state());

    expect(find.text('동작구 상도동'), findsOneWidget);
    expect(find.text('강남구 역삼동'), findsOneWidget);
    await tester.tap(find.text('강남구 역삼동'));
    expect(edited, [PlaceKind.work]);
  });

  testWidgets('방향 토글: 퇴근을 누르면 setDirection(toHome)', (tester) async {
    await pump(tester, _state());

    await tester.tap(find.text('퇴근'));
    verify(() => cubit.setDirection(CommuteDirection.toHome)).called(1);
  });

  testWidgets('조회를 누르면 query', (tester) async {
    await pump(tester, _state());
    await tester.tap(find.text('조회'));
    verify(() => cubit.query()).called(1);
  });

  testWidgets('로딩 중에는 조회 버튼이 로딩을 보이고 눌리지 않는다', (tester) async {
    await pump(tester, _state(status: const CommuteStatus.loading()));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('조회'), findsNothing);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('결과: 배너 · 열차 · 도착 예상 · 총 시간 · 구간 줄 · 다른 경로 · 조회 시각', (
    tester,
  ) async {
    await pump(tester, _state(status: CommuteStatus.loaded(_result())));

    expect(find.text('걸어가면 탈 수 있어요'), findsOneWidget);
    expect(find.text('장승배기 · 7호선 장암 방면'), findsOneWidget);
    expect(find.text('8분 후 · 3번째 전역'), findsOneWidget);
    expect(find.text('역까지 도보 6분'), findsOneWidget);
    expect(find.text('도착 예상 08:35'), findsOneWidget);
    expect(find.text('(예상)'), findsNothing);
    expect(find.text('총 41분 · 환승 1회'), findsOneWidget);
    expect(
      find.text('도보 6 → 7호선 장승배기→논현 16 → 도보 3 → 신분당선 신논현→강남 2 → 도보 7'),
      findsOneWidget,
    );
    expect(find.text('08:11 조회'), findsOneWidget);
    expect(find.text('다시 조회하세요'), findsNothing);

    await tester.tap(find.text('다른 경로 1개'));
    expect(routesShown, 1);
  });

  testWidgets('다른 경로가 없으면 다른 경로 줄을 숨긴다', (tester) async {
    await pump(
      tester,
      _state(status: CommuteStatus.loaded(_result(alternatives: const []))),
    );

    expect(find.textContaining('다른 경로'), findsNothing);
  });

  testWidgets('조회한 지 2분이 지나면 다시 조회하세요', (tester) async {
    await pump(
      tester,
      _state(
        status: CommuteStatus.loaded(
          _result(queriedAt: _now.subtract(const Duration(minutes: 2))),
        ),
      ),
    );

    expect(find.text('다시 조회하세요'), findsOneWidget);
  });

  testWidgets('탭이 보이는 동안 30초마다 낡음 표시를 다시 그린다', (tester) async {
    await pump(tester, _state(status: CommuteStatus.loaded(_result())));
    expect(find.text('다시 조회하세요'), findsNothing);

    clock.advance(const Duration(minutes: 2));
    await tester.pump(const Duration(seconds: 30));
    expect(find.text('다시 조회하세요'), findsOneWidget);
  });

  testWidgets('탭이 가려져 있으면 다시 그리지 않는다', (tester) async {
    await pump(
      tester,
      _state(status: CommuteStatus.loaded(_result())),
      active: false,
    );

    clock.advance(const Duration(minutes: 2));
    await tester.pump(const Duration(seconds: 30));
    expect(find.text('다시 조회하세요'), findsNothing);
  });

  testWidgets('실시간이 없으면 실시간 정보 없음 + (예상)', (tester) async {
    await pump(
      tester,
      _state(
        status: CommuteStatus.loaded(
          _result(realtime: RealtimeStatus.unavailable, etaFromRealtime: false),
        ),
      ),
    );

    expect(find.text('실시간 정보 없음'), findsOneWidget);
    expect(find.text('(예상)'), findsOneWidget);
    expect(find.text('도착 예상 08:35'), findsOneWidget);
  });

  for (final (failure, text) in [
    (const CommuteFailure.missingPlaces(), '집과 회사를 먼저 정해 주세요'),
    (
      const CommuteFailure.missingKey(),
      'API 키가 없어요 — config/commute_keys.json',
    ),
    (const CommuteFailure.network(), '네트워크에 연결할 수 없어요'),
    (const CommuteFailure.noRoute(), '이 구간의 지하철 경로가 없어요'),
    (const CommuteFailure.server('500'), '서버 오류: 500'),
  ]) {
    testWidgets('실패 문구: $text', (tester) async {
      await pump(tester, _state(status: CommuteStatus.failure(failure)));

      expect(find.text(text), findsOneWidget);
      // 실패 뒤에도 다시 조회할 수 있다.
      await tester.tap(find.text('조회'));
      verify(() => cubit.query()).called(1);
    });
  }
}
