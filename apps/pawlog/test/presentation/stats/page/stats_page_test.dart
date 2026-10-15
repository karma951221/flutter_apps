import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pawlog/domain/walk/entity/walk.dart';
import 'package:pawlog/presentation/stats/cubit/stats_cubit.dart';
import 'package:pawlog/presentation/stats/page/stats_page.dart';
import 'package:pawlog/presentation/theme/pawlog_theme.dart';

import '../../../support/fakes.dart';
import '../../../support/mock_walk_use_case.dart';
import '../../../support/pump_app.dart';

Walk _walk(
  String id,
  DateTime startedAt, {
  double meters = 1000,
  Duration duration = const Duration(minutes: 30),
}) => Walk(
  id: id,
  startedAt: startedAt,
  endedAt: startedAt.add(duration),
  duration: duration,
  distanceMeters: meters,
  dogs: [dog('1')],
  photos: const [],
  previewPoints: const [],
  createdAt: startedAt,
  updatedAt: startedAt,
);

void main() {
  late MockWalkUseCase useCase;

  // 금요일. 이번 주 a(월 1 km) · b(금 2.5 km), 지난주 p(800 m).
  final now = DateTime(2026, 10, 16, 15);
  final walks = [
    _walk(
      'b',
      DateTime(2026, 10, 16, 8),
      meters: 2500,
      duration: const Duration(minutes: 45),
    ),
    _walk('a', DateTime(2026, 10, 12, 7)),
    _walk(
      'p',
      DateTime(2026, 10, 5, 7),
      meters: 800,
      duration: const Duration(minutes: 20),
    ),
  ];

  setUp(() {
    useCase = MockWalkUseCase();
    when(() => useCase.watchWalks()).thenAnswer((_) => Stream.value(Ok(walks)));
    getIt.registerFactory<StatsCubit>(
      () => StatsCubit(useCase, FakeClock.fixed(now)),
    );
  });
  tearDown(getIt.reset);

  Future<void> pump(
    WidgetTester tester, {
    ValueChanged<String>? onOpenWalk,
    ThemeData? theme,
  }) => pumpApp(
    tester,
    StatsPage(onOpenWalk: onOpenWalk ?? (_) {}),
    theme: theme,
  );

  String text(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(Key(key))).data!;

  testWidgets('이번 주 요약 · 비교 · 막대 7칸이 보인다', (tester) async {
    await pump(tester);

    expect(find.text('산책 통계'), findsOneWidget);
    expect(text(tester, 'stats-range-label'), '10월 12일 – 18일');
    expect(text(tester, 'stats-total-distance'), '3.5 km');
    expect(text(tester, 'stats-total-duration'), '1시간 15분');
    expect(text(tester, 'stats-total-count'), '2번');
    expect(text(tester, 'stats-comparison'), '지난주보다 2.7 km 더 걸었어요');
    for (var i = 0; i < 7; i++) {
      expect(find.byKey(Key('stats-bar-$i')), findsOneWidget);
    }
    expect(find.byKey(const Key('stats-bar-7')), findsNothing);
    expect(find.byType(Card), findsNothing);
  });

  testWidgets('막대를 탭하면 값이 뜨고 다시 탭하면 사라진다', (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const Key('stats-bar-4')));
    await tester.pump();
    expect(text(tester, 'stats-bar-value'), '2.5 km');

    await tester.tap(find.byKey(const Key('stats-bar-4')));
    await tester.pump();
    expect(find.byKey(const Key('stats-bar-value')), findsNothing);
  });

  testWidgets('스크린리더로 막대를 누르면 값이 뜬다', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester);

    final node = tester.getSemantics(find.byKey(const Key('stats-bar-4')));
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

    node.owner!.performAction(node.id, SemanticsAction.tap);
    await tester.pump();
    expect(text(tester, 'stats-bar-value'), '2.5 km');
    handle.dispose();
  });

  testWidgets('이전 주로 가면 지난주가 보이고 다음이 켜진다', (tester) async {
    IconButton next() => tester.widget<IconButton>(
      find.descendant(
        of: find.byKey(const Key('stats-next')),
        matching: find.byType(IconButton),
      ),
    );
    await pump(tester);
    expect(next().onPressed, isNull); // 이번 주에서는 다음이 꺼져 있다

    await tester.tap(find.byKey(const Key('stats-previous')));
    await tester.pumpAndSettle();

    expect(next().onPressed, isNotNull);
    expect(text(tester, 'stats-range-label'), '10월 5일 – 11일');
    expect(text(tester, 'stats-total-distance'), '800 m');
    expect(find.byKey(const Key('stats-comparison')), findsNothing); // 그 전 주는 0
  });

  testWidgets('월로 바꾸면 이번 달 · 주별 칸이 보인다', (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const Key('stats-period-month')));
    await tester.pumpAndSettle();

    expect(text(tester, 'stats-range-label'), '2026년 10월');
    expect(text(tester, 'stats-total-distance'), '4.3 km');
    expect(find.byKey(const Key('stats-bar-4')), findsOneWidget); // 26–31
    expect(find.byKey(const Key('stats-bar-5')), findsNothing);
  });

  testWidgets('기록 — 연속 · 최장 · 가장 먼 산책을 탭하면 상세로', (tester) async {
    String? opened;
    await pump(tester, onOpenWalk: (id) => opened = id);

    await tester.scrollUntilVisible(
      find.byKey(const Key('stats-record-longest')),
      200,
    );
    expect(find.text('연속 산책'), findsOneWidget);
    expect(find.text('1일'), findsWidgets);
    await tester.tap(find.byKey(const Key('stats-record-farthest')));
    expect(opened, 'b');
  });

  testWidgets('거리 없는 산책뿐이면 가장 먼 산책 줄을 숨긴다', (tester) async {
    when(() => useCase.watchWalks()).thenAnswer(
      (_) =>
          Stream.value(Ok([_walk('z', DateTime(2026, 10, 16, 8), meters: 0)])),
    );

    await pump(tester);
    await tester.scrollUntilVisible(
      find.byKey(const Key('stats-record-longest')),
      200,
    );

    expect(find.byKey(const Key('stats-record-farthest')), findsNothing);
    expect(find.text('가장 먼 산책'), findsNothing);
  });

  testWidgets('산책이 없으면 안내 한 장만 보인다', (tester) async {
    when(
      () => useCase.watchWalks(),
    ).thenAnswer((_) => Stream.value(const Ok([])));

    await pump(tester);

    expect(find.byType(AppPlaceholder), findsOneWidget);
    expect(find.text('아직 통계가 없어요'), findsOneWidget);
    expect(find.byKey(const Key('stats-period-week')), findsNothing);
  });

  testWidgets('다크 테마에서도 그려진다', (tester) async {
    await pump(tester, theme: PawlogTheme.dark());

    expect(text(tester, 'stats-total-distance'), '3.5 km');
    expect(tester.takeException(), isNull);
  });
}
