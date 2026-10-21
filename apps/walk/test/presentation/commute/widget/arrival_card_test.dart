import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/domain/commute/entity/commute_result.dart';
import 'package:walk/domain/commute/entity/train_arrival.dart';
import 'package:walk/domain/commute/entity/transit_route.dart';
import 'package:walk/presentation/commute/widget/arrival_card.dart';

const _leg = SubwayLeg(
  minutes: 16,
  lineName: '7호선',
  odsayLaneCode: 7,
  startStation: '장승배기',
  endStation: '논현',
  wayCode: 1,
  wayName: '장암 방면',
  stationCount: 8,
);

Future<void> _pump(
  WidgetTester tester, {
  List<TrainArrival> arrivals = const [],
  RealtimeStatus realtime = RealtimeStatus.ok,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ArrivalCard(
          leg: _leg,
          arrivals: arrivals,
          realtime: realtime,
          walkMinutes: 6,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('역 · 노선 · 방면과 역까지 도보 분', (tester) async {
    await _pump(tester);
    expect(find.text('장승배기 · 7호선 장암 방면'), findsOneWidget);
    expect(find.text('역까지 도보 6분'), findsOneWidget);
  });

  testWidgets('실시간 분과 몇 번째 전역을 한 줄로', (tester) async {
    await _pump(
      tester,
      arrivals: const [
        TrainArrival(minutes: 4, stationsAway: 3, message: '[3]번째 전역'),
        TrainArrival(minutes: 11, stationsAway: 7, message: '[7]번째 전역'),
      ],
    );
    expect(find.text('4분 후 · 3번째 전역'), findsOneWidget);
    expect(find.text('11분 후 · 7번째 전역'), findsOneWidget);
  });

  testWidgets('추정값은 약 n분 후', (tester) async {
    await _pump(
      tester,
      arrivals: const [
        TrainArrival(minutes: 6, estimated: true, message: '[3]번째 전역'),
      ],
    );
    expect(find.text('약 6분 후'), findsOneWidget);
  });

  testWidgets('0분이면 곧 도착', (tester) async {
    await _pump(
      tester,
      arrivals: const [TrainArrival(minutes: 0, message: '장승배기 도착')],
    );
    expect(find.text('곧 도착'), findsOneWidget);
  });

  testWidgets('분을 모르면 원문 메시지', (tester) async {
    await _pump(tester, arrivals: const [TrainArrival(message: '장암행 운행 대기')]);
    expect(find.text('장암행 운행 대기'), findsOneWidget);
  });

  testWidgets('열차는 최대 두 줄', (tester) async {
    await _pump(
      tester,
      arrivals: const [
        TrainArrival(minutes: 2, message: 'a'),
        TrainArrival(minutes: 9, message: 'b'),
        TrainArrival(minutes: 15, message: 'c'),
      ],
    );
    expect(find.text('15분 후'), findsNothing);
  });

  testWidgets('실시간 미지원 · 실패 문구', (tester) async {
    await _pump(tester, realtime: RealtimeStatus.unavailable);
    expect(find.text('실시간 정보 없음'), findsOneWidget);

    await _pump(tester, realtime: RealtimeStatus.failed);
    expect(find.text('실시간을 불러오지 못했어요'), findsOneWidget);
  });

  testWidgets('실시간은 정상인데 열차가 없으면 실시간 정보 없음', (tester) async {
    await _pump(tester);
    expect(find.text('실시간 정보 없음'), findsOneWidget);
  });

  testWidgets('영어는 1일 때 단수형', (tester) async {
    final en = lookupAppLocalizations(const Locale('en'));
    expect(en.walkCommuteTrainStationsAway(1), '1 stop away');
    expect(en.walkCommuteTrainStationsAway(3), '3 stops away');
    expect(en.walkCommuteSummary(30, 1), '30 min total · 1 transfer');
    expect(en.walkCommuteSummary(30, 2), '30 min total · 2 transfers');
    expect(en.walkCommuteAlternatives(1), '1 other route');
    expect(en.walkCommuteAlternatives(2), '2 other routes');
    expect(en.walkCommuteToHome, 'Going home');
  });
}
