import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/domain/transit/entity/transit_path.dart';
import 'package:walk/presentation/transit/widget/line_chip.dart';
import 'package:walk/presentation/transit/widget/transit_path_tile.dart';

const _subwayBus = TransitPath(
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
    TransitLeg.bus(
      minutes: 21,
      busNumbers: ['740', '151'],
      start: '강남역',
      end: '시청',
      stationCount: 9,
    ),
  ],
);

Future<void> _pump(WidgetTester tester, TransitPath path) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.light(),
    locale: const Locale('ko'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: TransitPathTile(path: path, onTap: () {}),
    ),
  ),
);

void main() {
  testWidgets('총 분 · 환승 · 도보 · 요금 · 노선 칩', (tester) async {
    await _pump(tester, _subwayBus);

    expect(find.text('42분'), findsOneWidget);
    expect(find.text('환승 1 · 도보 9분 · 1,500원'), findsOneWidget);
    expect(find.byType(LineChip), findsNWidgets(2));
    expect(find.text('7호선'), findsOneWidget);
    expect(find.text('740 · 151'), findsOneWidget);
  });

  testWidgets('fare omitted when null', (tester) async {
    await _pump(
      tester,
      const TransitPath(
        totalMinutes: 75,
        transferCount: 0,
        legs: [
          TransitLeg.walk(minutes: 14, distanceM: 900),
          TransitLeg.bus(
            minutes: 61,
            busNumbers: ['740'],
            start: '가',
            end: '나',
            stationCount: 20,
          ),
        ],
      ),
    );

    expect(find.text('1시간 15분'), findsOneWidget);
    expect(find.text('환승 0 · 도보 14분'), findsOneWidget);
    expect(find.textContaining('원'), findsNothing);
  });

  testWidgets('exact hours drop the minutes', (tester) async {
    await _pump(
      tester,
      const TransitPath(
        totalMinutes: 60,
        transferCount: 0,
        legs: [TransitLeg.walk(minutes: 60, distanceM: 4000)],
      ),
    );

    expect(find.text('1시간'), findsOneWidget);
  });
}
