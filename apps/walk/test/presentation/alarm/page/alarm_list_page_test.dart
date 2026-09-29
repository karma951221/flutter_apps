import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';
import 'package:permission/permission.dart';
import 'package:walk/domain/alarm/entity/alarm.dart';
import 'package:walk/domain/alarm/permission/alarm_permissions.dart';
import 'package:walk/domain/alarm/usecase/alarm_use_case.dart';
import 'package:walk/domain/clock.dart';
import 'package:walk/presentation/alarm/cubit/alarm_list_cubit.dart';
import 'package:walk/presentation/alarm/page/alarm_edit_page.dart';
import 'package:walk/presentation/alarm/page/alarm_list_page.dart';
import 'package:walk/presentation/alarm/widget/alarm_summary_card.dart';
import 'package:walk/presentation/alarm/widget/alarm_tile.dart';

class _MockUseCase extends Mock implements AlarmUseCase {}

class _MockRequester extends Mock implements PermissionRequester {}

class _FixedClock extends Clock {
  _FixedClock([DateTime? value]) : value = value ?? DateTime(2026, 9, 27, 23, 48); // 일요일
  final DateTime value;
  @override
  DateTime now() => value;
}

/// 분 경계 타이머가 부르는 [tick] 을 센다.
class _TickCountingCubit extends AlarmListCubit {
  _TickCountingCubit(super.useCase, super.permissions, super.clock);
  int ticks = 0;
  @override
  Future<void> tick() async => ticks++;
}

void main() {
  const weekday = Alarm(
    id: 1,
    hour: 7,
    minute: 0,
    label: '출근',
    repeat: {Weekday.mon, Weekday.tue, Weekday.wed, Weekday.thu, Weekday.fri},
  );
  const off = Alarm(id: 2, hour: 9, minute: 30, enabled: false);
  late _MockUseCase useCase;
  late _MockRequester notification;
  late _MockRequester exactAlarm;
  late AlarmPermissions permissions;
  late AlarmListCubit cubit;

  setUp(() {
    useCase = _MockUseCase();
    notification = _MockRequester();
    exactAlarm = _MockRequester();
    permissions = AlarmPermissions(
      notification: notification,
      exactAlarm: exactAlarm,
      fullScreenIntent: _MockRequester(),
    );
    for (final r in [notification, exactAlarm]) {
      when(r.check).thenAnswer((_) async => PermissionStatus.granted);
      when(r.ensure).thenAnswer((_) async => PermissionStatus.granted);
    }
    when(() => useCase.nextRings()).thenAnswer((_) async => {});
    getIt
      ..registerSingleton<AlarmUseCase>(useCase)
      ..registerSingleton<AlarmPermissions>(permissions)
      ..registerSingleton<Clock>(_FixedClock());
    cubit = AlarmListCubit(useCase, permissions, _FixedClock());
  });
  tearDown(() async {
    await cubit.close();
    await getIt.reset();
  });

  Future<void> pump(WidgetTester tester, {VoidCallback? onOpenSettings}) async {
    await cubit.load();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider.value(
          value: cubit,
          child: AlarmListPage(onOpenSettings: onOpenSettings ?? () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('알람이 없으면 안내만 보이고 요약 카드는 숨긴다', (tester) async {
    when(() => useCase.list()).thenAnswer((_) async => []);
    await pump(tester);

    expect(find.text('알람이 없어요'), findsOneWidget);
    expect(find.byType(AlarmSummaryCard), findsNothing);
    expect(find.text('알람이 울리지 않을 수 있어요'), findsNothing);
  });

  testWidgets('요약 카드는 가장 먼저 울릴 알람의 남은 시간 · 날 · 시각 · 라벨', (tester) async {
    when(() => useCase.list()).thenAnswer((_) async => [weekday, off]);
    when(() => useCase.nextRings()).thenAnswer((_) async => {1: DateTime(2026, 9, 28, 7)});
    await pump(tester);

    expect(find.text('다음 알람'), findsOneWidget);
    expect(find.text('7시간 12분 후'), findsNWidgets(2)); // 카드 · 행
    expect(find.text('내일 (월) 오전 7:00 · 출근'), findsOneWidget);
  });

  testWidgets('시각이 같으면 id 가 작은 알람의 라벨, 라벨이 없으면 생략', (tester) async {
    final at = DateTime(2026, 9, 28, 7);
    when(() => useCase.list()).thenAnswer(
      (_) async => [
        const Alarm(id: 3, hour: 7, minute: 0, label: '셋'),
        const Alarm(id: 2, hour: 7, minute: 0),
      ],
    );
    when(() => useCase.nextRings()).thenAnswer((_) async => {3: at, 2: at});
    await pump(tester);

    expect(find.text('내일 (월) 오전 7:00'), findsOneWidget);
  });

  testWidgets('알람이 모두 꺼져 있으면 카드에 한 줄만', (tester) async {
    when(() => useCase.list()).thenAnswer((_) async => [off]);
    await pump(tester);

    expect(find.text('켜진 알람이 없어요'), findsOneWidget);
    expect(find.text('다음 알람'), findsNothing);
  });

  testWidgets('행은 시각 · 라벨 · 반복 요약 · 스위치, 켜진 알람만 남은 시간', (tester) async {
    when(() => useCase.list()).thenAnswer((_) async => [weekday, off]);
    // 꺼진 알람은 use case 가 키를 주지 않지만, 화면도 켜진 알람에만 셋째 줄을 둔다.
    when(() => useCase.nextRings()).thenAnswer(
      (_) async => {1: DateTime(2026, 9, 28, 7), 2: DateTime(2026, 9, 28, 9, 30)},
    );
    await pump(tester);

    expect(find.text('오전 7:00'), findsOneWidget);
    expect(find.text('출근 · 평일'), findsOneWidget);
    expect(find.text('오전 9:30'), findsOneWidget);
    expect(find.text('1회'), findsOneWidget);
    final rows = find.byType(AlarmTile);
    expect(find.descendant(of: rows.first, matching: find.text('7시간 12분 후')), findsOneWidget);
    expect(find.descendant(of: rows.last, matching: find.textContaining('후')), findsNothing);
    final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
    expect(switches.map((s) => s.value), [true, false]);
  });

  testWidgets('켜면 use case 를 부르고 스낵바를 띄우며 카드 · 행 시간이 함께 바뀐다', (tester) async {
    final on = off.copyWith(enabled: true, oneShotAt: DateTime(2026, 9, 28, 9, 30));
    when(() => useCase.list()).thenAnswer((_) async => [off]);
    when(() => useCase.toggle(2, enabled: true)).thenAnswer((_) async {
      when(() => useCase.list()).thenAnswer((_) async => [on]);
      when(() => useCase.nextRings()).thenAnswer((_) async => {2: DateTime(2026, 9, 28, 9, 30)});
      return on;
    });
    await pump(tester);
    expect(find.text('켜진 알람이 없어요'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    verify(() => useCase.toggle(2, enabled: true)).called(1);
    verify(notification.ensure).called(1);
    expect(find.text('9시간 42분 뒤에 울려요'), findsOneWidget);
    expect(find.text('켜진 알람이 없어요'), findsNothing);
    expect(find.text('9시간 42분 후'), findsNWidgets(2));
    expect(find.text('내일 (월) 오전 9:30'), findsOneWidget);
  });

  testWidgets('끄면 카드가 다음 알람으로 넘어가고 그 행의 남은 시간이 사라진다', (tester) async {
    const late = Alarm(id: 3, hour: 8, minute: 0, label: '회의', repeat: {Weekday.mon});
    when(() => useCase.list()).thenAnswer((_) async => [weekday, late]);
    when(() => useCase.nextRings()).thenAnswer(
      (_) async => {1: DateTime(2026, 9, 28, 7), 3: DateTime(2026, 9, 28, 8)},
    );
    when(() => useCase.toggle(1, enabled: false)).thenAnswer((_) async {
      when(() => useCase.list()).thenAnswer((_) async => [weekday.copyWith(enabled: false), late]);
      when(() => useCase.nextRings()).thenAnswer((_) async => {3: DateTime(2026, 9, 28, 8)});
      return weekday.copyWith(enabled: false);
    });
    await pump(tester);
    expect(find.text('내일 (월) 오전 7:00 · 출근'), findsOneWidget);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    expect(find.text('내일 (월) 오전 8:00 · 회의'), findsOneWidget);
    expect(find.text('7시간 12분 후'), findsNothing);
    expect(find.text('8시간 12분 후'), findsNWidgets(2));
  });

  group('분 경계 타이머', () {
    late _TickCountingCubit spy;
    late ValueNotifier<bool> visible;

    Future<void> pumpSpy(WidgetTester tester) async {
      await getIt.unregister<Clock>();
      final clock = _FixedClock(DateTime(2026, 9, 27, 23, 48, 20));
      getIt.registerSingleton<Clock>(clock);
      when(() => useCase.list()).thenAnswer((_) async => [weekday]);
      spy = _TickCountingCubit(useCase, permissions, clock);
      await spy.load();
      visible = ValueNotifier(true);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BlocProvider<AlarmListCubit>.value(
            value: spy,
            child: ValueListenableBuilder(
              valueListenable: visible,
              builder: (_, enabled, child) => TickerMode(enabled: enabled, child: child!),
              child: AlarmListPage(onOpenSettings: () {}),
            ),
          ),
        ),
      );
    }

    tearDown(() async {
      await spy.close();
      visible.dispose();
    });

    testWidgets('다음 분 0초에 한 번, 그 뒤 1분마다 tick', (tester) async {
      await pumpSpy(tester);
      expect(spy.ticks, 0);

      await tester.pump(const Duration(seconds: 39));
      expect(spy.ticks, 0);
      await tester.pump(const Duration(seconds: 1)); // 23:49:00
      expect(spy.ticks, 1);
      await tester.pump(const Duration(seconds: 59));
      expect(spy.ticks, 1);
      await tester.pump(const Duration(seconds: 1)); // 23:50:00
      expect(spy.ticks, 2);
      await tester.pump(const Duration(minutes: 3));
      expect(spy.ticks, 5);
    });

    testWidgets('가려져 있으면 건너뛰고, 다시 보이면 바로 tick', (tester) async {
      await pumpSpy(tester);
      visible.value = false;
      await tester.pump();

      await tester.pump(const Duration(minutes: 2));
      expect(spy.ticks, 0);

      visible.value = true;
      await tester.pump();
      expect(spy.ticks, 1);
      await tester.pump(const Duration(minutes: 1));
      expect(spy.ticks, 2);
    });
  });

  testWidgets('목록을 읽지 못하면 계속 돌지 않고 오류 안내, 다시 시도하면 다시 읽는다', (tester) async {
    when(() => useCase.list()).thenThrow(const FormatException('corrupt'));
    await pump(tester);

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('알람을 불러오지 못했어요'), findsOneWidget);

    when(() => useCase.list()).thenAnswer((_) async => [weekday]);
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(find.text('알람을 불러오지 못했어요'), findsNothing);
    expect(find.text('출근 · 평일'), findsOneWidget);
  });

  testWidgets('권한이 없으면 경고 배너, 누르면 설정 탭으로', (tester) async {
    when(() => useCase.list()).thenAnswer((_) async => [weekday]);
    when(exactAlarm.check).thenAnswer((_) async => PermissionStatus.denied);
    var opened = false;
    await pump(tester, onOpenSettings: () => opened = true);

    await tester.tap(find.text('알람이 울리지 않을 수 있어요'));
    expect(opened, isTrue);
  });

  testWidgets('FAB 는 새 알람 편집을 연다', (tester) async {
    when(() => useCase.list()).thenAnswer((_) async => []);
    await pump(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.byType(AlarmEditPage), findsOneWidget);
    expect(find.text('새 알람'), findsOneWidget);
  });
}
