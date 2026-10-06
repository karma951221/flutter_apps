import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';
import 'package:permission/permission.dart';
import 'package:walk/domain/alarm/entity/alarm.dart';
import 'package:walk/domain/alarm/holiday/holiday_calendar_access.dart';
import 'package:walk/domain/alarm/permission/alarm_permissions.dart';
import 'package:walk/domain/alarm/usecase/alarm_use_case.dart';
import 'package:walk/presentation/alarm/cubit/alarm_list_cubit.dart';
import 'package:walk/presentation/alarm/page/alarm_edit_page.dart';
import 'package:walk/presentation/alarm/page/alarm_list_page.dart';
import 'package:walk/presentation/alarm/widget/alarm_summary_card.dart';
import 'package:walk/presentation/alarm/widget/alarm_tile.dart';
import 'package:walk/presentation/alarm/widget/weekday_dots.dart';

class _MockUseCase extends Mock implements AlarmUseCase {}

class _MockRequester extends Mock implements PermissionRequester {}

class _MockCalendarAccess extends Mock implements HolidayCalendarAccess {}

class _MutableClock extends Clock {
  _MutableClock(this.value);
  DateTime value;
  @override
  DateTime now() => value;
}

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
    final calendar = _MockCalendarAccess();
    when(calendar.ensureIfReminding).thenAnswer((_) async {});
    getIt
      ..registerSingleton<HolidayCalendarAccess>(calendar)
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
    expect(find.text('7시간 12분 후'), findsOneWidget); // 카드만 — 반복 행은 요일 점
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

  testWidgets('켜진 알람인데 예약이 없으면(권한 거부) 배너가 카드 위, 카드는 예약 없음 · 권한 안내, 행 셋째 줄 없음', (
    tester,
  ) async {
    when(() => useCase.list()).thenAnswer((_) async => [weekday, off]);
    when(() => useCase.nextRings()).thenAnswer((_) async => {});
    when(exactAlarm.check).thenAnswer((_) async => PermissionStatus.denied);
    await pump(tester);

    final banner = find.text('알람이 울리지 않을 수 있어요');
    final card = find.byType(AlarmSummaryCard);
    expect(banner, findsOneWidget);
    expect(tester.getTopLeft(banner).dy, lessThan(tester.getTopLeft(card).dy));
    expect(
      find.descendant(of: card, matching: find.text('예약된 알람이 없어요')),
      findsOneWidget,
    );
    expect(find.descendant(of: card, matching: find.text('권한을 확인하세요')), findsOneWidget);
    expect(find.text('켜진 알람이 없어요'), findsNothing);
    expect(find.text('다음 알람'), findsNothing);
    expect(
      find.descendant(of: find.byType(AlarmTile), matching: find.textContaining('후')),
      findsNothing,
    );
  });

  testWidgets('행은 둥근 카드 — 반복은 제목 · 요약 · 요일 점, 한 번은 모래시계 줄, 행 사이 간격', (
    tester,
  ) async {
    final soon = Alarm(id: 4, hour: 1, minute: 13, oneShotAt: DateTime(2026, 9, 28, 1, 13));
    when(() => useCase.list()).thenAnswer((_) async => [weekday, off, soon]);
    // 꺼진 알람은 use case 가 키를 주지 않지만, 화면도 켜진 알람에만 남은 시간을 둔다.
    when(() => useCase.nextRings()).thenAnswer(
      (_) async => {
        1: DateTime(2026, 9, 28, 7),
        2: DateTime(2026, 9, 28, 9, 30),
        4: DateTime(2026, 9, 28, 1, 13),
      },
    );
    await pump(tester);

    final rows = find.byType(AlarmTile);
    Finder inRow(int i, Finder f) => find.descendant(of: rows.at(i), matching: f);
    expect(inRow(0, find.text('오전 7:00')), findsOneWidget);
    expect(inRow(0, find.text('출근 · 평일')), findsOneWidget);
    expect(inRow(0, find.byType(WeekdayDots)), findsOneWidget);
    expect(inRow(0, find.textContaining('후')), findsNothing);
    expect(inRow(1, find.text('오전 9:30')), findsOneWidget);
    expect(inRow(1, find.text('한 번')), findsOneWidget);
    expect(inRow(1, find.textContaining('뒤')), findsNothing);
    expect(inRow(2, find.text('한 번 · 1시간 25분 뒤')), findsOneWidget);
    expect(inRow(2, find.byIcon(Icons.hourglass_bottom)), findsOneWidget);
    final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
    expect(switches.map((s) => s.value), [true, false, true]);
    expect(
      tester.getTopLeft(rows.at(1)).dy - tester.getBottomLeft(rows.at(0)).dy,
      AppSpacing.sm,
    );
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
    expect(find.text('9시간 42분 후'), findsOneWidget);
    expect(find.text('한 번 · 9시간 42분 뒤'), findsOneWidget);
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
    expect(find.text('8시간 12분 후'), findsOneWidget);
  });

  testWidgets('스위치 저장이 실패하면 스위치가 돌아오고 오류 스낵바', (tester) async {
    when(() => useCase.list()).thenAnswer((_) async => [off]);
    when(() => useCase.toggle(2, enabled: true)).thenThrow(StateError('x'));
    await pump(tester);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    expect(find.text('알람을 저장하지 못했어요'), findsOneWidget);
    expect(find.textContaining('뒤에 울려요'), findsNothing);
  });

  testWidgets('자정 tick 에서 카드의 내일이 오늘로 바뀐다', (tester) async {
    final clock = _MutableClock(DateTime(2026, 9, 27, 23, 59)); // 일요일
    await getIt.unregister<Clock>();
    getIt.registerSingleton<Clock>(clock);
    await cubit.close();
    cubit = AlarmListCubit(useCase, permissions, clock);
    when(() => useCase.list()).thenAnswer((_) async => [weekday]);
    when(() => useCase.nextRings()).thenAnswer((_) async => {1: DateTime(2026, 9, 28, 7)});
    await pump(tester);
    expect(find.text('내일 (월) 오전 7:00 · 출근'), findsOneWidget);
    expect(find.text('7시간 1분 후'), findsOneWidget);

    clock.value = DateTime(2026, 9, 28);
    await cubit.tick();
    await tester.pump();

    expect(find.text('오늘 (월) 오전 7:00 · 출근'), findsOneWidget);
    expect(find.text('7시간 후'), findsOneWidget);
  });

  testWidgets('행을 누르면 그 알람으로 편집을 열고, 저장 결과로 이 탭에 스낵바', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    when(() => useCase.list()).thenAnswer((_) async => [weekday, off]);
    when(() => useCase.nextRings()).thenAnswer((_) async => {1: DateTime(2026, 9, 28, 7)});
    registerFallbackValue(Alarm.draft());
    when(() => useCase.save(any())).thenAnswer(
      (i) async => i.positionalArguments.single as Alarm,
    );
    await pump(tester);

    await tester.tap(find.text('오전 7:00'));
    await tester.pumpAndSettle();
    expect(find.text('알람 수정'), findsOneWidget);
    expect(find.widgetWithText(TextField, '출근'), findsOneWidget);

    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    final saved = verify(() => useCase.save(captureAny())).captured.single as Alarm;
    expect(saved.id, 1);
    expect(find.byType(AlarmEditPage), findsNothing);
    // 일요일 23:48 → 월요일 07:00. 탭 Scaffold 안에 뜬다.
    expect(
      find.descendant(
        of: find.byType(AlarmListPage),
        matching: find.widgetWithText(SnackBar, '7시간 12분 뒤에 울려요'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('꺼진 알람 행은 흐리게, 켜진 행은 그대로', (tester) async {
    when(() => useCase.list()).thenAnswer((_) async => [weekday, off]);
    await pump(tester);

    final disabled =
        Theme.of(tester.element(find.byType(AlarmListPage))).colorScheme.onSurfaceVariant;
    Color? colorOf(String text) => tester.widget<Text>(find.text(text)).style?.color;
    expect(colorOf('오전 9:30'), disabled);
    expect(colorOf('한 번'), disabled);
    expect(colorOf('오전 7:00'), isNot(disabled));
    expect(colorOf('출근 · 평일'), isNot(disabled));
  });

  testWidgets('요약 카드는 누를 수 없다', (tester) async {
    when(() => useCase.list()).thenAnswer((_) async => [weekday]);
    when(() => useCase.nextRings()).thenAnswer((_) async => {1: DateTime(2026, 9, 28, 7)});
    await pump(tester);

    final card = find.byType(AlarmSummaryCard);
    expect(
      find.descendant(
        of: card,
        matching: find.byWidgetPredicate((w) => w is InkWell || w is GestureDetector),
      ),
      findsNothing,
    );
    await tester.tap(find.text('다음 알람'));
    await tester.pumpAndSettle();
    expect(find.byType(AlarmEditPage), findsNothing);
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

  testWidgets('FAB → 종류 시트 → 한 번이면 한 번 알람 편집', (tester) async {
    when(() => useCase.list()).thenAnswer((_) async => []);
    await pump(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('어떤 알람을 만들까요'), findsOneWidget);
    await tester.tap(find.text('한 번'));
    await tester.pumpAndSettle();

    expect(find.byType(AlarmEditPage), findsOneWidget);
    expect(find.text('한 번 알람'), findsOneWidget);
    expect(find.text('0분 뒤'), findsOneWidget);
  });

  testWidgets('FAB → 종류 시트 → 반복이면 평일로 시작하는 반복 알람 편집', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    when(() => useCase.list()).thenAnswer((_) async => []);
    await pump(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('반복'));
    await tester.pumpAndSettle();

    expect(find.text('반복 알람'), findsOneWidget);
    expect(
      tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '평일')).selected,
      isTrue,
    );
  });

  testWidgets('종류 시트를 그냥 닫으면 편집을 열지 않는다', (tester) async {
    when(() => useCase.list()).thenAnswer((_) async => []);
    await pump(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.text('어떤 알람을 만들까요'), findsNothing);
    expect(find.byType(AlarmEditPage), findsNothing);
  });
}
