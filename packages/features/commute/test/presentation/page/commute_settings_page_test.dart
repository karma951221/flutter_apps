import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_commute/feature_commute.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';

class _MockCommuteUseCase extends Mock implements CommuteUseCase {}

const _home = Station(
  id: '0750',
  name: '장승배기',
  lines: ['7'],
  location: GeoPoint(lat: 37.5048, lng: 126.9392),
);

const _work = Station(
  id: '0222',
  name: '강남',
  lines: ['2', '신분당'],
  location: GeoPoint(lat: 37.4979, lng: 127.0276),
);

void main() {
  late _MockCommuteUseCase useCase;

  setUpAll(() => registerFallbackValue(const CommuteSettings()));
  setUp(() {
    useCase = _MockCommuteUseCase();
    getIt
      ..registerFactory<CommuteSettingsCubit>(
        () => CommuteSettingsCubit(useCase),
      )
      ..registerFactory<StationSearchCubit>(() => StationSearchCubit(useCase));
    when(
      () => useCase.getSettings(),
    ).thenAnswer((_) async => const Ok(CommuteSettings()));
    when(
      () => useCase.saveSettings(any()),
    ).thenAnswer((_) async => const Ok(null));
    when(() => useCase.searchStations(any())).thenAnswer((invocation) async {
      final query = invocation.positionalArguments.single as String;
      return Ok([if (query == '장승배기') _home else _work]);
    });
  });

  tearDown(getIt.reset);

  Future<void> pumpPage(WidgetTester tester, {VoidCallback? onDone}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CommuteSettingsPage(onDone: onDone),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pickStation(
    WidgetTester tester, {
    required Key tileKey,
    required String query,
    required String stationId,
  }) async {
    await tester.tap(find.byKey(tileKey));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('commute-station-search-field')),
      query,
    );
    await tester.pump(const Duration(milliseconds: 301));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('commute-station-result-$stationId')));
    await tester.pumpAndSettle();
  }

  testWidgets('역을 선택하면 즉시 설정을 저장한다', (tester) async {
    await pumpPage(tester);

    await pickStation(
      tester,
      tileKey: const Key('commute-home-station-tile'),
      query: '장승배기',
      stationId: _home.id,
    );

    expect(find.text('장승배기'), findsOneWidget);
    verify(
      () => useCase.saveSettings(const CommuteSettings(home: _home)),
    ).called(1);
  });

  testWidgets('집과 회사가 모두 정해지면 완료 콜백을 한 번 부른다', (tester) async {
    var doneCount = 0;
    await pumpPage(tester, onDone: () => doneCount++);

    await pickStation(
      tester,
      tileKey: const Key('commute-home-station-tile'),
      query: '장승배기',
      stationId: _home.id,
    );
    expect(doneCount, 0);

    await pickStation(
      tester,
      tileKey: const Key('commute-work-station-tile'),
      query: '강남',
      stationId: _work.id,
    );

    expect(doneCount, 1);
    verify(
      () =>
          useCase.saveSettings(const CommuteSettings(home: _home, work: _work)),
    ).called(1);
  });
}
