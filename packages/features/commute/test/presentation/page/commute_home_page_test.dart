import 'dart:async';

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
  lines: ['2'],
  location: GeoPoint(lat: 37.4979, lng: 127.0276),
);

const _routes = [
  TransitRoute(
    mode: TransitMode.subway,
    duration: Duration(minutes: 42),
    transferCount: 1,
    legs: [
      TransitLeg(kind: TransitLegKind.walk, label: '도보', minutes: 4),
      TransitLeg(kind: TransitLegKind.subway, label: '2호선', minutes: 34),
      TransitLeg(kind: TransitLegKind.walk, label: '도보', minutes: 4),
    ],
  ),
  TransitRoute(
    mode: TransitMode.bus,
    duration: Duration(minutes: 48),
    transferCount: 0,
    legs: [
      TransitLeg(kind: TransitLegKind.walk, label: '도보', minutes: 3),
      TransitLeg(kind: TransitLegKind.bus, label: '146번', minutes: 42),
      TransitLeg(kind: TransitLegKind.walk, label: '도보', minutes: 3),
    ],
  ),
  TransitRoute(
    mode: TransitMode.best,
    duration: Duration(minutes: 37),
    transferCount: 1,
    legs: [
      TransitLeg(kind: TransitLegKind.walk, label: '도보', minutes: 3),
      TransitLeg(kind: TransitLegKind.bus, label: '146번', minutes: 12),
      TransitLeg(kind: TransitLegKind.subway, label: '9호선', minutes: 19),
      TransitLeg(kind: TransitLegKind.walk, label: '도보', minutes: 3),
    ],
  ),
];

CommuteResult _result(Origin origin) => CommuteResult(
  direction: CommuteDirection.toWork,
  origin: origin,
  destination: _work,
  routes: _routes,
  searchedAt: DateTime.utc(2026, 9, 13),
);

void main() {
  late _MockCommuteUseCase useCase;

  setUpAll(() => registerFallbackValue(CommuteDirection.toWork));
  setUp(() {
    useCase = _MockCommuteUseCase();
    getIt.registerFactory<CommuteHomeCubit>(() => CommuteHomeCubit(useCase));
  });
  tearDown(getIt.reset);

  Future<void> pumpHome(
    WidgetTester tester, {
    Future<void> Function()? onOpenSettings,
  }) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CommuteHomePage(onOpenSettings: onOpenSettings ?? () async {}),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('loaded는 세 모드 카드와 현 위치 배너를 보여준다', (tester) async {
    when(() => useCase.searchCommute(any())).thenAnswer(
      (_) async => Ok(
        _result(const Origin.currentLocation(GeoPoint(lat: 37.5, lng: 127))),
      ),
    );

    await pumpHome(tester);

    expect(find.byKey(const Key('commute-route-card-subway')), findsOneWidget);
    expect(find.byKey(const Key('commute-route-card-bus')), findsOneWidget);
    expect(find.byKey(const Key('commute-route-card-best')), findsOneWidget);
    expect(find.text('현 위치 기준'), findsOneWidget);
    expect(find.text('42분'), findsOneWidget);
    expect(find.text('도보 → 2호선 → 도보'), findsOneWidget);
  });

  testWidgets('위치 실패로 역을 썼으면 집 기준 배너를 보여준다', (tester) async {
    when(
      () => useCase.searchCommute(any()),
    ).thenAnswer((_) async => Ok(_result(const Origin.fallbackStation(_home))));

    await pumpHome(tester);

    expect(find.text('집 기준 · 위치를 못 가져왔어요'), findsOneWidget);
    expect(find.text('현 위치 기준'), findsNothing);
  });

  testWidgets('설정 화면이 닫히면 다시 검색한다', (tester) async {
    when(
      () => useCase.searchCommute(any()),
    ).thenAnswer((_) async => Ok(_result(const Origin.fallbackStation(_home))));
    final settingsClosed = Completer<void>();

    await pumpHome(tester, onOpenSettings: () => settingsClosed.future);
    await tester.tap(find.byKey(const Key('commute-open-settings')));
    await tester.pump();
    verify(() => useCase.searchCommute(CommuteDirection.toWork)).called(1);

    settingsClosed.complete();
    await tester.pumpAndSettle();

    verify(() => useCase.searchCommute(CommuteDirection.toWork)).called(1);
  });

  testWidgets('failure는 AppPlaceholder와 재시도를 보여준다', (tester) async {
    when(
      () => useCase.searchCommute(any()),
    ).thenAnswer((_) async => const Err(Failure.network()));

    await pumpHome(tester);

    expect(find.byType(AppPlaceholder), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    verify(() => useCase.searchCommute(CommuteDirection.toWork)).called(2);
  });
}
