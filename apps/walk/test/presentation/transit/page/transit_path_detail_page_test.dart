import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/domain/transit/entity/transit_path.dart';
import 'package:walk/presentation/transit/page/transit_path_detail_page.dart';

const _path = TransitPath(
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
    TransitLeg.walk(minutes: 3, distanceM: 150),
    TransitLeg.bus(
      minutes: 18,
      busNumbers: ['740', '151'],
      start: '강남역',
      end: '시청',
      stationCount: 9,
    ),
    TransitLeg.walk(minutes: 4, distanceM: 250),
  ],
);

void main() {
  testWidgets('요약 · 구간 타임라인(도보 · 지하철 · 환승 도보 · 버스)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const TransitPathDetailPage(path: _path),
      ),
    );

    expect(find.text('42분'), findsOneWidget);
    expect(find.text('환승 1 · 도보 12분 · 1,500원'), findsOneWidget);
    expect(find.text('도보 5분(320m)'), findsOneWidget);
    expect(find.text('7호선 장승배기 → 고속터미널'), findsOneWidget);
    expect(find.text('6개 역 · 12분 · 온수 방면'), findsOneWidget);
    expect(find.text('환승 도보 3분'), findsOneWidget);
    expect(find.text('740 · 151 강남역 → 시청'), findsOneWidget);
    expect(find.text('9개 정류장 · 18분'), findsOneWidget);
    expect(find.text('도보 4분(250m)'), findsOneWidget);
  });
}
