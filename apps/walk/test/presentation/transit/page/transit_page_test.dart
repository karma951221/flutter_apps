import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/transit/entity/transit_path.dart';
import 'package:walk/domain/transit/entity/transit_point.dart';
import 'package:walk/domain/transit/repository/transit_key_store.dart';
import 'package:walk/domain/transit/transit_failure.dart';
import 'package:walk/domain/transit/usecase/find_transit_routes.dart';
import 'package:walk/domain/transit/usecase/transit_point_suggestions.dart';
import 'package:walk/domain/transit/usecase/verify_transit_key.dart';
import 'package:walk/presentation/settings/page/transit_settings_page.dart';
import 'package:walk/presentation/transit/cubit/transit_cubit.dart';
import 'package:walk/presentation/transit/cubit/transit_state.dart';
import 'package:walk/presentation/transit/page/transit_page.dart';
import 'package:walk/presentation/transit/page/transit_path_detail_page.dart';
import 'package:walk/presentation/transit/widget/transit_path_tile.dart';

class _MockCubit extends MockCubit<TransitState> implements TransitCubit {}

class _MockSuggestions extends Mock implements TransitPointSuggestions {}

class _MockKeyStore extends Mock implements TransitKeyStore {}

class _MockVerify extends Mock implements VerifyTransitKey {}

class _FixedClock extends Clock {
  const _FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}

final _now = DateTime(2026, 11, 17, 9, 30);

const _here = TransitPoint(
  lat: 37.5,
  lng: 126.9,
  label: '',
  source: TransitPointSource.currentLocation,
);
const _office = TransitPoint(
  lat: 37.49,
  lng: 127.02,
  label: '강남구 테헤란로',
  source: TransitPointSource.work,
);
const _home = TransitPoint(
  lat: 37.48,
  lng: 126.95,
  label: '관악구 봉천동',
  source: TransitPointSource.home,
);

const _fast = TransitPath(
  totalMinutes: 42,
  transferCount: 1,
  fare: 1500,
  legs: [
    TransitLeg.walk(minutes: 5, distanceM: 320),
    TransitLeg.subway(
      minutes: 12,
      lineName: '7호선',
      subwayCode: 7,
      start: '장승배기',
      end: '고속터미널',
      stationCount: 6,
      way: '온수',
    ),
    TransitLeg.walk(minutes: 4, distanceM: 200),
    TransitLeg.subway(
      minutes: 21,
      lineName: '신분당선',
      start: '신논현',
      end: '강남',
      stationCount: 2,
      way: '광교',
    ),
  ],
);
const _slow = TransitPath(
  totalMinutes: 47,
  transferCount: 0,
  legs: [
    TransitLeg.walk(minutes: 14, distanceM: 900),
    TransitLeg.bus(
      minutes: 33,
      busNumbers: ['740'],
      start: '봉천역',
      end: '강남역',
      stationCount: 15,
    ),
  ],
);

TransitState _state(TransitStatus status) =>
    TransitState(from: _here, to: _office, status: status);

void main() {
  late _MockCubit cubit;
  late _MockSuggestions suggestions;

  setUpAll(() => registerFallbackValue(_here));
  setUp(() {
    cubit = _MockCubit();
    suggestions = _MockSuggestions();
    when(
      () => suggestions.load(),
    ).thenAnswer((_) async => const TransitSuggestions());
    when(() => cubit.fillEmpty(any())).thenAnswer((_) async {});
  });
  tearDown(() => getIt.reset());

  Future<void> pump(WidgetTester tester, TransitState state) async {
    when(() => cubit.state).thenReturn(state);
    // 가짜 cubit 은 stream 으로 알리지 않는다 — 새 상태를 보이려면 트리를 새로 만든다.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BlocProvider<TransitCubit>.value(
            value: cubit,
            child: TransitView(
              suggestions: suggestions,
              clock: _FixedClock(_now),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpFailure(WidgetTester tester, TransitFailure failure) =>
      pump(tester, _state(TransitStatus.failure(failure)));

  testWidgets('출발 · 도착 칸 — 현재 위치 · 저장 이름', (tester) async {
    await pump(tester, _state(const TransitStatus.idle()));

    expect(find.text('현재 위치'), findsOneWidget);
    expect(find.text('강남구 테헤란로'), findsOneWidget);
  });

  testWidgets('missing key shows placeholder with settings button', (
    tester,
  ) async {
    await pumpFailure(tester, const TransitFailure.missingKey());

    expect(find.byType(AppPlaceholder), findsOneWidget);
    expect(find.text('길찾기 키가 필요해요'), findsOneWidget);
    expect(find.text('키 설정'), findsOneWidget);
  });

  testWidgets('keyRejected shows message', (tester) async {
    await pumpFailure(
      tester,
      const TransitFailure.keyRejected('ApiKeyAuthFailed'),
    );

    expect(find.text('ODsay 가 키를 받지 않았어요'), findsOneWidget);
    expect(find.text('ApiKeyAuthFailed'), findsOneWidget);
    expect(find.text('키 설정'), findsOneWidget);
  });

  testWidgets('quota/tooClose/noRoute/network copy', (tester) async {
    await pumpFailure(tester, const TransitFailure.quotaExceeded());
    expect(find.text('오늘 무료 한도를 다 썼어요'), findsOneWidget);
    expect(find.text('키 설정'), findsNothing);

    await pumpFailure(tester, const TransitFailure.tooClose());
    expect(find.text('걸어서 가는 거리예요'), findsOneWidget);

    await pumpFailure(tester, const TransitFailure.noRoute());
    expect(find.text('대중교통 경로가 없어요'), findsOneWidget);

    await pumpFailure(tester, const TransitFailure.network());
    expect(find.text('인터넷 연결을 확인해 주세요'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);

    await pumpFailure(tester, const TransitFailure.server('HTTP 500'));
    expect(find.text('길을 찾지 못했어요'), findsOneWidget);
    expect(find.text('HTTP 500'), findsOneWidget);
  });

  testWidgets('loading shows AppLoading', (tester) async {
    when(() => cubit.state).thenReturn(_state(const TransitStatus.loading()));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<TransitCubit>.value(
          value: cubit,
          child: TransitView(
            suggestions: suggestions,
            clock: _FixedClock(_now),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(AppLoading), findsOneWidget);
  });

  testWidgets('loaded lists paths in order with transfer/walk/fare', (
    tester,
  ) async {
    await pump(
      tester,
      _state(
        TransitStatus.loaded(
          TransitRoutesResult(
            paths: const [_fast, _slow],
            fetchedAt: _now.subtract(const Duration(minutes: 3)),
            fromCache: true,
          ),
        ),
      ),
    );

    expect(find.text('3분 전 결과'), findsOneWidget);
    expect(find.text('새로고침'), findsOneWidget);
    expect(find.text('환승 · 배차 대기 시간은 빠질 수 있어요'), findsOneWidget);
    final tiles = find.byType(TransitPathTile);
    expect(tiles, findsNWidgets(2));
    expect(tester.widget<TransitPathTile>(tiles.at(0)).path, _fast);
    expect(tester.widget<TransitPathTile>(tiles.at(1)).path, _slow);
    expect(find.text('환승 1 · 도보 9분 · 1,500원'), findsOneWidget);
    expect(find.text('환승 0 · 도보 14분'), findsOneWidget);
    expect(find.text('신분당선'), findsOneWidget);
    expect(find.text('740'), findsOneWidget);
  });

  testWidgets('refresh calls cubit.refresh', (tester) async {
    when(() => cubit.refresh()).thenReturn(null);
    await pump(
      tester,
      _state(
        TransitStatus.loaded(
          TransitRoutesResult(
            paths: const [_fast],
            fetchedAt: _now,
            fromCache: false,
          ),
        ),
      ),
    );

    expect(find.text('방금 받은 결과'), findsOneWidget);
    await tester.tap(find.text('새로고침'));
    verify(() => cubit.refresh()).called(1);
  });

  testWidgets('tap path opens detail with legs', (tester) async {
    await pump(
      tester,
      _state(
        TransitStatus.loaded(
          TransitRoutesResult(
            paths: const [_fast, _slow],
            fetchedAt: _now,
            fromCache: false,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TransitPathTile).first);
    await tester.pumpAndSettle();

    expect(find.byType(TransitPathDetailPage), findsOneWidget);
    expect(find.text('7호선 장승배기 → 고속터미널'), findsOneWidget);
    expect(find.text('환승 도보 4분'), findsOneWidget);
  });

  testWidgets('quick chip fills empty field', (tester) async {
    when(() => suggestions.load()).thenAnswer(
      (_) async => const TransitSuggestions(
        home: _home,
        frequent: [
          TransitPoint(
            lat: 37.51,
            lng: 127.0,
            label: '헬스장',
            source: TransitPointSource.frequent,
          ),
        ],
      ),
    );
    await pump(tester, const TransitState(from: _here));

    expect(find.widgetWithText(ActionChip, '집'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, '헬스장'), findsOneWidget);
    // 회사는 정해 두지 않아 칩이 없다.
    expect(find.widgetWithText(ActionChip, '회사'), findsNothing);

    await tester.tap(find.widgetWithText(ActionChip, '집'));
    verify(() => cubit.fillEmpty(_home)).called(1);
  });

  testWidgets('location failed shows hint in from field', (tester) async {
    await pump(tester, const TransitState(locationFailed: true));

    expect(find.text('현재 위치를 못 찾았어요 · 눌러서 고르기'), findsOneWidget);
  });

  testWidgets('idle asks for the empty field — from first', (tester) async {
    await pump(tester, const TransitState(to: _office));
    expect(find.text('출발을 골라 주세요'), findsOneWidget);

    await pump(tester, const TransitState(from: _here));
    expect(find.text('도착을 골라 주세요'), findsOneWidget);
  });

  testWidgets('키 설정 opens TransitSettingsPage and re-queries on return', (
    tester,
  ) async {
    final store = _MockKeyStore();
    when(() => store.read()).thenAnswer((_) async => null);
    getIt
      ..registerSingleton<TransitKeyStore>(store)
      ..registerSingleton<VerifyTransitKey>(_MockVerify());
    when(() => cubit.refresh()).thenReturn(null);
    await pumpFailure(tester, const TransitFailure.missingKey());

    await tester.tap(find.text('키 설정'));
    await tester.pumpAndSettle();
    expect(find.byType(TransitSettingsPage), findsOneWidget);
    verifyNever(() => cubit.refresh());

    Navigator.of(tester.element(find.byType(TransitSettingsPage))).pop();
    await tester.pumpAndSettle();
    expect(find.byType(TransitSettingsPage), findsNothing);
    verify(() => cubit.refresh()).called(1);
  });
}
