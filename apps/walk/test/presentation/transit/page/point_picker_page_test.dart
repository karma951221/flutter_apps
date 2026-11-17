import 'package:bloc_test/bloc_test.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/commute/entity/place.dart';
import 'package:walk/domain/commute/repository/address_search.dart';
import 'package:walk/domain/transit/entity/station_hit.dart';
import 'package:walk/domain/transit/entity/transit_point.dart';
import 'package:walk/domain/transit/transit_failure.dart';
import 'package:walk/domain/transit/usecase/transit_point_suggestions.dart';
import 'package:walk/presentation/transit/cubit/point_picker_cubit.dart';
import 'package:walk/presentation/transit/cubit/point_picker_state.dart';
import 'package:walk/presentation/transit/page/point_picker_page.dart';

class _MockCubit extends MockCubit<PointPickerState>
    implements PointPickerCubit {}

class _MockSuggestions extends Mock implements TransitPointSuggestions {}

const _home = TransitPoint(
  lat: 37.48,
  lng: 126.95,
  label: '관악구 봉천동',
  source: TransitPointSource.home,
);
const _recent = TransitPoint(
  lat: 37.55,
  lng: 126.97,
  label: '서울역',
  source: TransitPointSource.station,
);
const _chosen = TransitPoint(
  lat: 37.56,
  lng: 126.98,
  label: '시청',
  source: TransitPointSource.station,
);

void main() {
  late _MockCubit cubit;
  late _MockSuggestions suggestions;
  TransitPoint? result;

  setUpAll(() {
    registerFallbackValue(PlaceKind.home);
    registerFallbackValue(_home);
  });
  setUp(() {
    cubit = _MockCubit();
    suggestions = _MockSuggestions();
    result = null;
    when(() => cubit.load()).thenAnswer((_) async {});
    when(() => cubit.searchAddress()).thenAnswer((_) async {});
    when(() => cubit.submitted(any())).thenReturn(null);
    when(
      () => cubit.queryChanged(any(), composing: any(named: 'composing')),
    ).thenReturn(null);
    when(() => suggestions.saveAs(any(), any())).thenAnswer((_) async {});
  });

  /// 버튼으로 picker 를 띄우고, 닫히며 돌려준 값을 [result] 에 담는다.
  Future<void> open(
    WidgetTester tester,
    PointPickerState state, {
    TransitPoint? current,
  }) async {
    when(() => cubit.state).thenReturn(state);
    // 가짜 cubit 은 stream 으로 알리지 않는다 — 새 상태를 보이려면 트리를 새로 만든다.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await Navigator.of(context).push<TransitPoint>(
                MaterialPageRoute(
                  builder: (_) => BlocProvider<PointPickerCubit>.value(
                    value: cubit,
                    child: PointPickerView(
                      suggestions: suggestions,
                      current: current,
                      locate: () async => null,
                    ),
                  ),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('picker hides frequent when empty', (tester) async {
    await open(
      tester,
      const PointPickerState(
        suggestions: TransitSuggestions(home: _home, recent: [_recent]),
      ),
    );

    expect(find.text('현재 위치'), findsOneWidget);
    expect(find.text('집'), findsOneWidget);
    expect(find.text('회사 정하기'), findsOneWidget);
    expect(find.text('자주 간 곳'), findsNothing);
    expect(find.text('최근'), findsOneWidget);
    expect(find.text('서울역'), findsOneWidget);
  });

  testWidgets('frequent without a name shows fallback', (tester) async {
    await open(
      tester,
      const PointPickerState(
        suggestions: TransitSuggestions(
          frequent: [
            TransitPoint(
              lat: 37.5,
              lng: 127,
              label: '',
              source: TransitPointSource.frequent,
            ),
          ],
        ),
      ),
    );

    // 섹션 제목 + 이름 없는 행.
    expect(find.text('자주 간 곳'), findsNWidgets(2));
  });

  testWidgets('picker station tap returns point', (tester) async {
    await open(
      tester,
      const PointPickerState(
        query: '강남',
        stations: [
          StationHit(
            name: '강남역',
            kind: StationKind.subway,
            lat: 37.498,
            lng: 127.028,
            detail: '2호선 · 신분당선',
          ),
        ],
      ),
    );

    expect(find.text('2호선 · 신분당선'), findsOneWidget);
    expect(find.text('주소로 찾기: "강남"'), findsOneWidget);

    await tester.tap(find.text('강남역'));
    await tester.pumpAndSettle();

    expect(
      result,
      const TransitPoint(
        lat: 37.498,
        lng: 127.028,
        label: '강남역',
        source: TransitPointSource.station,
      ),
    );
  });

  testWidgets('address row searches, address result returns point', (
    tester,
  ) async {
    await open(tester, const PointPickerState(query: '강남대로 396'));
    await tester.tap(find.text('주소로 찾기: "강남대로 396"'));
    verify(() => cubit.searchAddress()).called(1);

    await open(
      tester,
      const PointPickerState(
        query: '강남대로 396',
        addresses: [PlaceCandidate(lat: 37.4, lng: 127.1, label: '강남대로 396')],
      ),
    );
    await tester.tap(find.text('강남대로 396'));
    await tester.pumpAndSettle();
    expect(result?.source, TransitPointSource.address);
    expect(result?.lat, 37.4);
  });

  testWidgets('keyboard search action searches stations, not addresses', (
    tester,
  ) async {
    await open(tester, const PointPickerState());
    await tester.enterText(find.byType(TextField), '강남역');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();

    verify(() => cubit.submitted('강남역')).called(1);
    verifyNever(() => cubit.searchAddress());
  });

  testWidgets('long-press home saves current choice', (tester) async {
    await open(
      tester,
      const PointPickerState(suggestions: TransitSuggestions(home: _home)),
      current: _chosen,
    );

    await tester.longPress(find.text('집'));
    await tester.pumpAndSettle();

    verify(() => suggestions.saveAs(PlaceKind.home, _chosen)).called(1);
    verify(() => cubit.load()).called(1);
    expect(find.text('지금 고른 곳을 집으로 저장했어요'), findsOneWidget);
  });

  testWidgets('station failure retry re-runs the query', (tester) async {
    await open(
      tester,
      const PointPickerState(
        query: '강남',
        stationFailure: TransitFailure.network(),
      ),
    );
    clearInteractions(cubit);

    await tester.tap(find.text('다시 시도'));
    verify(() => cubit.queryChanged('강남')).called(1);
  });

  testWidgets('long-press home saves current location as "현재 위치"', (
    tester,
  ) async {
    await open(
      tester,
      const PointPickerState(suggestions: TransitSuggestions(home: _home)),
      current: const TransitPoint(
        lat: 37.5,
        lng: 126.9,
        label: '',
        source: TransitPointSource.currentLocation,
      ),
    );

    await tester.longPress(find.text('집'));
    await tester.pumpAndSettle();

    verify(
      () => suggestions.saveAs(
        PlaceKind.home,
        const TransitPoint(
          lat: 37.5,
          lng: 126.9,
          label: '현재 위치',
          source: TransitPointSource.currentLocation,
        ),
      ),
    ).called(1);
  });
}
