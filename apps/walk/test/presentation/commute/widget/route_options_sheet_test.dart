import 'package:bloc_test/bloc_test.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/commute/entity/catch_verdict.dart';
import 'package:walk/domain/commute/entity/commute_direction.dart';
import 'package:walk/domain/commute/entity/commute_result.dart';
import 'package:walk/domain/commute/entity/transit_route.dart';
import 'package:walk/presentation/commute/cubit/commute_cubit.dart';
import 'package:walk/presentation/commute/cubit/commute_state.dart';
import 'package:walk/presentation/commute/widget/route_options_sheet.dart';

class _MockCubit extends MockCubit<CommuteState> implements CommuteCubit {}

TransitRoute _route(int total, String line) => TransitRoute(
  totalMinutes: total,
  transferCount: 0,
  legs: [
    const RouteLeg.walk(minutes: 5),
    RouteLeg.subway(
      minutes: total - 5,
      lineName: line,
      odsayLaneCode: 1,
      startStation: '가',
      endStation: '나',
      wayCode: 1,
      wayName: '방면',
      stationCount: 5,
    ),
  ],
);

void main() {
  late _MockCubit cubit;
  final current = _route(41, '7호선');
  final fast = _route(30, '2호선');
  final slow = _route(55, '9호선');

  late CommuteResult result;

  setUpAll(() => registerFallbackValue(current));

  setUp(() {
    cubit = _MockCubit();
    when(() => cubit.selectRoute(any())).thenAnswer((_) async {});
    result = CommuteResult(
      direction: CommuteDirection.toWork,
      route: current,
      alternatives: [slow, fast],
      arrivals: const [],
      realtime: RealtimeStatus.unavailable,
      verdict: const CatchVerdict.unknown(),
      eta: DateTime(2026, 10, 21, 9),
      etaFromRealtime: false,
      queriedAt: DateTime(2026, 10, 21, 8),
    );
  });

  Future<void> open(WidgetTester tester) async {
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
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () => showRouteOptionsSheet(context, result),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('총 분 오름차순으로 나열한다', (tester) async {
    await open(tester);
    expect(find.text('경로 선택'), findsOneWidget);
    final tops = [
      30,
      41,
      55,
    ].map((m) => tester.getTopLeft(find.text('총 $m분 · 환승 0회')).dy).toList();
    expect(tops, [...tops]..sort());
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('현재 경로에만 체크 표시', (tester) async {
    await open(tester);
    final check = tester.getCenter(find.byIcon(Icons.check)).dy;
    final currentRow = tester.getCenter(find.text('총 41분 · 환승 0회')).dy;
    expect((check - currentRow).abs(), lessThan(40));
  });

  testWidgets('누르면 selectRoute 하고 닫힌다', (tester) async {
    await open(tester);
    await tester.tap(find.text('총 30분 · 환승 0회'));
    await tester.pumpAndSettle();
    verify(() => cubit.selectRoute(fast)).called(1);
    expect(find.text('경로 선택'), findsNothing);
  });
}
