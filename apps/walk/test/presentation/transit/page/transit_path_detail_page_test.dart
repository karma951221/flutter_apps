import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/domain/transit/entity/transit_path.dart';
import 'package:walk/presentation/transit/page/transit_path_detail_page.dart';
import 'package:walk/presentation/transit/widget/transit_path_tile.dart';

const _path = TransitPath(
  totalMinutes: 42,
  transferCount: 1,
  fare: 1500,
  legs: [
    TransitLeg.walk(minutes: 5, distanceM: 320),
    // 0분 도보(같은 역 출구 등)는 타임라인에서 뺀다.
    TransitLeg.walk(minutes: 0, distanceM: 40),
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

Future<void> _pump(WidgetTester tester, {String locale = 'ko'}) =>
    tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const TransitPathDetailPage(path: _path),
      ),
    );

void main() {
  testWidgets('요약 · 구간 타임라인(도보 · 지하철 · 환승 도보 · 버스)', (tester) async {
    await _pump(tester);

    expect(find.text('42분'), findsOneWidget);
    expect(find.text('환승 1 · 도보 12분 · 1,500원'), findsOneWidget);
    expect(find.text('도보 5분(320m)'), findsOneWidget);
    expect(find.text('7호선 장승배기 → 고속터미널'), findsOneWidget);
    expect(find.text('6개 역 · 12분 · 온수 방면'), findsOneWidget);
    expect(find.text('환승 도보 3분'), findsOneWidget);
    expect(find.text('740 · 151 강남역 → 시청'), findsOneWidget);
    expect(find.text('9개 정류장 · 18분'), findsOneWidget);
    expect(find.text('도보 4분(250m)'), findsOneWidget);
    expect(find.text('도보 0분(40m)'), findsNothing);
    expect(find.byIcon(Icons.directions_walk_outlined), findsNWidgets(3));
  });

  testWidgets('en uses plural counts', (tester) async {
    await _pump(tester, locale: 'en');

    expect(find.text('Transfers 1'), findsNothing);
    expect(find.text('1 transfer · Walk 12 min · ₩1,500'), findsOneWidget);
    expect(find.text('6 stations · 12 min · toward 온수'), findsOneWidget);
    expect(find.text('9 stops · 18 min'), findsOneWidget);
  });

  testWidgets('총 시간은 목록 행과 같은 글자 크기', (tester) async {
    await _pump(tester);
    final theme = Theme.of(tester.element(find.byType(TransitPathDetailPage)));
    final total = tester.widget<Text>(
      find.text(
        TransitPathTile.total(
          AppLocalizations.of(
            tester.element(find.byType(TransitPathDetailPage)),
          ),
          _path.totalMinutes,
        ),
      ),
    );
    expect(total.style, TransitPathTile.totalStyle(theme));
  });
}
