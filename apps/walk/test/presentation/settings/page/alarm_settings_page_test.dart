import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';
import 'package:permission/permission.dart';
import 'package:walk/domain/alarm/holiday/holiday_calendar.dart';
import 'package:walk/domain/settings/entity/app_settings.dart';
import 'package:walk/presentation/settings/page/alarm_settings_page.dart';

import '../settings_harness.dart';

void main() {
  final h = SettingsHarness();

  setUpAll(SettingsHarness.registerFallbacks);
  setUp(h.setUp);
  tearDown(h.tearDown);

  testWidgets('열릴 때 권한 · 공휴일을 읽어 보인다', (tester) async {
    await h.pump(tester, const AlarmSettingsPage());

    verify(h.notification.check).called(1);
    expect(find.text('공휴일 미리 알림'), findsOneWidget);
    expect(find.text('내장 표 2026–2027'), findsOneWidget);
    expect(find.text('캘린더 허용 필요 ›'), findsOneWidget);
    expect(find.text('권한'), findsOneWidget);
    expect(find.text('허용됨'), findsNWidgets(2));
    expect(find.text('허용 필요 ›'), findsOneWidget);
  });

  testWidgets('공휴일 출처 행이 권한 머리보다 위', (tester) async {
    await h.pump(tester, const AlarmSettingsPage());

    double top(String text) => tester.getTopLeft(find.text(text)).dy;
    expect(top('공휴일 출처'), lessThan(top('권한')));
    expect(top('권한'), lessThan(top('알림')));
  });

  testWidgets('전체 화면 알림 행을 누르면 해당 설정을 연다', (tester) async {
    when(h.fullScreen.openSettings).thenAnswer((_) async {});
    await h.pump(tester, const AlarmSettingsPage());

    await tester.tap(find.text('전체 화면 알림'));
    verify(h.fullScreen.openSettings).called(1);
  });

  testWidgets('확인 중(null)이면 권한 상태 문구를 비운다', (tester) async {
    final pending = Completer<PermissionStatus>();
    when(h.notification.check).thenAnswer((_) => pending.future);
    await h.pump(tester, const AlarmSettingsPage());

    expect(find.text('알림'), findsOneWidget);
    for (final label in ['허용됨', '허용 필요 ›']) {
      expect(find.text(label), findsNothing, reason: label);
    }
    pending.complete(PermissionStatus.granted);
  });

  testWidgets('알림 행: 아직 물을 수 있으면(denied) 다시 묻고 상태를 다시 읽는다', (tester) async {
    when(h.notification.check).thenAnswer((_) async => PermissionStatus.denied);
    when(h.notification.requestAgain).thenAnswer((_) async {
      when(
        h.notification.check,
      ).thenAnswer((_) async => PermissionStatus.granted);
      return PermissionStatus.granted;
    });
    await h.pump(tester, const AlarmSettingsPage());
    expect(find.text('허용 필요 ›'), findsNWidgets(2));

    await tester.tap(find.text('알림'));
    await tester.pumpAndSettle();

    verify(h.notification.requestAgain).called(1);
    verifyNever(h.notification.openSettings);
    // 알림은 허용됨으로 바뀌고 정확한 알람만 허용 필요.
    expect(find.text('허용 필요 ›'), findsOneWidget);
  });

  testWidgets('알림 행: 이미 허용이면 앱 설정을 연다', (tester) async {
    when(h.notification.openSettings).thenAnswer((_) async {});
    await h.pump(tester, const AlarmSettingsPage());

    await tester.tap(find.text('알림'));
    await tester.pumpAndSettle();

    verify(h.notification.openSettings).called(1);
    verifyNever(h.notification.requestAgain);
  });

  testWidgets('정확한 알람 행을 누르면 정확한 알람 설정을 연다', (tester) async {
    when(h.exactAlarm.openSettings).thenAnswer((_) async {});
    await h.pump(tester, const AlarmSettingsPage());

    await tester.tap(find.text('정확한 알람'));
    await tester.pumpAndSettle();

    verify(h.exactAlarm.openSettings).called(1);
  });

  group('공휴일', () {
    Switch reminderSwitch(WidgetTester tester) => tester.widget<Switch>(
      find.descendant(
        of: find.byKey(const Key('settings-holiday-reminder')),
        matching: find.byType(Switch),
      ),
    );

    testWidgets('미리 알림 스위치(켬) · 출처(내장 표) · 캘린더 권한은 오류 색', (tester) async {
      await h.pump(tester, const AlarmSettingsPage());

      expect(find.text('반복 알람이 공휴일에 울리면 하루 전에 알려요'), findsOneWidget);
      expect(reminderSwitch(tester).value, isTrue);
      expect(find.text('공휴일 출처'), findsOneWidget);
      final status = tester.widget<Text>(find.text('캘린더 허용 필요 ›'));
      final scheme = Theme.of(
        tester.element(find.byType(AlarmSettingsPage)),
      ).colorScheme;
      expect(status.style?.color, scheme.error);
    });

    testWidgets('폰 캘린더에서 읽으면 그 캘린더 이름과 허용됨', (tester) async {
      h.holidays.source = const HolidaySource.device(calendarName: '대한민국의 휴일');
      when(
        h.holidayAccess.check,
      ).thenAnswer((_) async => PermissionStatus.granted);
      await h.pump(tester, const AlarmSettingsPage());

      expect(find.text('폰 캘린더: 대한민국의 휴일'), findsOneWidget);
      expect(find.text('캘린더 허용됨'), findsOneWidget);
    });

    testWidgets('이름을 모르는 폰 캘린더는 폰 캘린더만', (tester) async {
      h.holidays.source = const HolidaySource.device(calendarName: '');
      await h.pump(tester, const AlarmSettingsPage());

      expect(find.text('폰 캘린더'), findsOneWidget);
    });

    testWidgets('확인 중(null)이면 출처 · 권한 문구를 비운다', (tester) async {
      final pending = Completer<PermissionStatus>();
      when(h.holidayAccess.check).thenAnswer((_) => pending.future);
      await h.pump(tester, const AlarmSettingsPage());

      expect(find.text('공휴일 출처'), findsOneWidget);
      expect(find.textContaining('내장 표'), findsNothing);
      expect(find.textContaining('캘린더 허용'), findsNothing);
      pending.complete(PermissionStatus.denied);
    });

    testWidgets('스위치를 끄면 저장하고 알람을 맞춘다', (tester) async {
      when(() => h.settings.save(any())).thenAnswer((i) async {
        when(
          h.settings.load,
        ).thenReturn(i.positionalArguments.single as AppSettings);
      });
      await h.pump(tester, const AlarmSettingsPage());

      await tester.tap(find.text('공휴일 미리 알림'));
      await tester.pumpAndSettle();

      verify(
        () => h.settings.save(const AppSettings(holidayReminder: false)),
      ).called(1);
      verify(h.alarms.sync).called(1);
      expect(h.holiday.state.holidayReminder, isFalse);
      expect(reminderSwitch(tester).value, isFalse);
    });

    testWidgets('공휴일 출처 행을 누르면 캘린더 권한을 다시 묻는다', (tester) async {
      when(
        h.holidayAccess.requestAgain,
      ).thenAnswer((_) async => PermissionStatus.denied);
      await h.pump(tester, const AlarmSettingsPage());

      await tester.tap(find.text('공휴일 출처'));
      await tester.pumpAndSettle();

      verify(h.holidayAccess.requestAgain).called(1);
    });

    for (final locale in const [Locale('en'), Locale('ja')]) {
      testWidgets('320dp 에서 넘치지 않는다 ($locale)', (tester) async {
        h.holidays.source = const HolidaySource.device(
          calendarName: 'Holidays in South Korea',
        );
        await tester.binding.setSurfaceSize(const Size(320, 1800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MultiBlocProvider(
              providers: [
                BlocProvider.value(value: h.permissions),
                BlocProvider.value(value: h.holiday),
              ],
              child: const AlarmSettingsPage(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    }
  });
}
