import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';
import 'package:permission/permission.dart';
import 'package:walk/domain/alarm/entity/alarm.dart';
import 'package:walk/domain/alarm/entity/alarm_trigger.dart';
import 'package:walk/domain/alarm/permission/alarm_permissions.dart';
import 'package:walk/domain/alarm/usecase/alarm_use_case.dart';
import 'package:walk/domain/clock.dart';
import 'package:walk/presentation/alarm/cubit/alarm_list_cubit.dart';
import 'package:walk/presentation/alarm/page/alarm_edit_page.dart';
import 'package:walk/presentation/alarm/page/alarm_list_page.dart';

class _MockUseCase extends Mock implements AlarmUseCase {}

class _MockRequester extends Mock implements PermissionRequester {}

class _FixedClock extends Clock {
  @override
  DateTime now() => DateTime(2026, 9, 27, 23, 48);
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
    when(() => useCase.next()).thenAnswer((_) async => null);
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

  testWidgets('비면 안내를 보이고 머리는 숨긴다', (tester) async {
    when(() => useCase.list()).thenAnswer((_) async => []);
    await pump(tester);

    expect(find.text('알람이 없어요'), findsOneWidget);
    expect(find.textContaining('다음 알람까지'), findsNothing);
    expect(find.text('알람이 울리지 않을 수 있어요'), findsNothing);
  });

  testWidgets('행은 시각 · 라벨 · 반복 요약 · 스위치, 머리는 남은 시간', (tester) async {
    when(() => useCase.list()).thenAnswer((_) async => [weekday, off]);
    when(() => useCase.next()).thenAnswer(
      (_) async => AlarmTrigger(packageId: 100, alarmId: 1, at: DateTime(2026, 9, 28, 7)),
    );
    await pump(tester);

    expect(find.text('다음 알람까지 7시간 12분'), findsOneWidget);
    expect(find.text('오전 7:00'), findsOneWidget);
    expect(find.text('출근 · 평일'), findsOneWidget);
    expect(find.text('오전 9:30'), findsOneWidget);
    expect(find.text('1회'), findsOneWidget);
    final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
    expect(switches.map((s) => s.value), [true, false]);
  });

  testWidgets('켜면 use case 를 부르고 남은 시간 스낵바를 띄운다', (tester) async {
    when(() => useCase.list()).thenAnswer((_) async => [off]);
    when(() => useCase.toggle(2, enabled: true)).thenAnswer(
      (_) async => off.copyWith(enabled: true, oneShotAt: DateTime(2026, 9, 28, 9, 30)),
    );
    await pump(tester);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    verify(() => useCase.toggle(2, enabled: true)).called(1);
    verify(notification.ensure).called(1);
    expect(find.text('9시간 42분 뒤에 울려요'), findsOneWidget);
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
