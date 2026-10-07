import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/alarm/entity/alarm.dart';
import 'package:walk/domain/alarm/entity/alarm_trigger.dart';
import 'package:walk/domain/alarm/entity/ring_log_entry.dart';
import 'package:walk/domain/alarm/ring_log/ring_log_source.dart';
import 'package:walk/domain/alarm/usecase/alarm_use_case.dart';
import 'package:walk/presentation/alarm/page/alarm_history_page.dart';

class _MockUseCase extends Mock implements AlarmUseCase {}

class _MockRingLog extends Mock implements RingLogSource {}

class _FixedClock extends Clock {
  _FixedClock(this.value);
  final DateTime value;
  @override
  DateTime now() => value;
}

void main() {
  // 2026-10-07 수요일 정오.
  final now = DateTime(2026, 10, 7, 12);
  const work = Alarm(id: 1, hour: 7, minute: 0, label: '출근', repeat: {Weekday.wed});
  const plain = Alarm(id: 2, hour: 6, minute: 30, repeat: {Weekday.tue});
  late _MockUseCase useCase;
  late _MockRingLog ringLog;

  RingLogEntry entry(int alarmId, DateTime at, RingLogKind kind) =>
      RingLogEntry(at: at, packageId: packageId(alarmId, triggerIndex(at)), kind: kind);

  setUp(() {
    useCase = _MockUseCase();
    ringLog = _MockRingLog();
    when(() => useCase.list()).thenAnswer((_) async => [work, plain]);
    when(() => ringLog.read(since: any(named: 'since'))).thenAnswer((_) async => []);
    getIt
      ..registerSingleton<AlarmUseCase>(useCase)
      ..registerSingleton<RingLogSource>(ringLog)
      ..registerSingleton<Clock>(_FixedClock(now));
  });
  tearDown(getIt.reset);

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const AlarmHistoryPage(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('날짜 머리 아래 회차마다 시각 · 라벨과 울림 · 스누즈 · 끔 한 줄', (tester) async {
    when(() => ringLog.read(since: any(named: 'since'))).thenAnswer(
      (_) async => [
        entry(2, DateTime(2026, 10, 6, 6, 30), RingLogKind.rang),
        entry(2, DateTime(2026, 10, 6, 6, 40), RingLogKind.autoStopped),
        entry(1, DateTime(2026, 10, 7, 7), RingLogKind.rang),
        entry(1, DateTime(2026, 10, 7, 7, 1), RingLogKind.snoozed),
        entry(1, DateTime(2026, 10, 7, 7, 6), RingLogKind.rang),
        entry(1, DateTime(2026, 10, 7, 7, 7), RingLogKind.snoozed),
        entry(1, DateTime(2026, 10, 7, 7, 12), RingLogKind.stopped),
      ],
    );
    await pump(tester);

    expect(find.text('울림 기록'), findsOneWidget);
    expect(find.text('오늘 (수)'), findsOneWidget);
    expect(find.text('오전 7:00 · 출근'), findsOneWidget);
    expect(find.text('오전 7:00 울림 · 스누즈 2번 · 오전 7:12 끔'), findsOneWidget);
    // 라벨 없는 알람은 시각만 · 자동 멈춤.
    expect(find.text('10월 6일 (화)'), findsOneWidget);
    expect(find.text('오전 6:30'), findsOneWidget);
    expect(find.text('오전 6:30 울림 · 오전 6:40 자동 멈춤'), findsOneWidget);
    // 최근 날짜가 위.
    expect(
      tester.getTopLeft(find.text('오늘 (수)')).dy,
      lessThan(tester.getTopLeft(find.text('10월 6일 (화)')).dy),
    );
  });

  testWidgets('건너뛴 회차 · 지운 알람', (tester) async {
    when(() => ringLog.read(since: any(named: 'since'))).thenAnswer(
      (_) async => [
        entry(1, DateTime(2026, 10, 7, 7), RingLogKind.skipped),
        entry(9, DateTime(2026, 10, 7, 8), RingLogKind.rang),
      ],
    );
    await pump(tester);

    expect(find.text('오전 7:00 · 출근'), findsOneWidget);
    expect(find.text('건너뜀'), findsOneWidget);
    expect(find.text('오전 8:00 · 지운 알람'), findsOneWidget);
    expect(find.text('오전 8:00 울림'), findsOneWidget);
  });

  testWidgets('기록이 없으면 빈 상태', (tester) async {
    await pump(tester);

    expect(find.byType(AppPlaceholder), findsOneWidget);
    expect(find.text('아직 기록이 없어요'), findsOneWidget);
  });

  testWidgets('읽기에 실패하면 오류 안내와 다시 시도', (tester) async {
    when(() => ringLog.read(since: any(named: 'since'))).thenThrow(StateError('실패'));
    await pump(tester);

    expect(find.text('기록을 불러오지 못했어요'), findsOneWidget);

    when(() => ringLog.read(since: any(named: 'since'))).thenAnswer((_) async => []);
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(find.text('아직 기록이 없어요'), findsOneWidget);
  });
}
