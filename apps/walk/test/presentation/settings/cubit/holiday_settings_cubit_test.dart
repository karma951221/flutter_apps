import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:permission/permission.dart';
import 'package:walk/domain/alarm/holiday/holiday_calendar.dart';
import 'package:walk/domain/alarm/holiday/holiday_calendar_access.dart';
import 'package:walk/domain/alarm/usecase/alarm_use_case.dart';
import 'package:walk/domain/settings/entity/app_settings.dart';
import 'package:walk/domain/settings/repository/settings_repository.dart';
import 'package:walk/presentation/settings/cubit/holiday_settings_cubit.dart';
import 'package:walk/presentation/settings/cubit/holiday_settings_state.dart';

class _MockAccess extends Mock implements HolidayCalendarAccess {}

class _MockRequester extends Mock implements PermissionRequester {}

class _MockRefresher extends Mock implements HolidayRefresher {}

class _MockUseCase extends Mock implements AlarmUseCase {}

class _MemorySettings implements SettingsRepository {
  AppSettings value = const AppSettings(stepGoal: 8000);

  @override
  AppSettings load() => value;

  @override
  Future<void> save(AppSettings settings) async => value = settings;
}

class _FakeHolidays implements HolidayCalendar {
  @override
  HolidaySource source = const HolidaySource.bundled(firstYear: 2026, lastYear: 2027);

  @override
  String? nameOf(DateTime date) => null;
}

void main() {
  const bundled = HolidaySource.bundled(firstYear: 2026, lastYear: 2027);
  const device = HolidaySource.device(calendarName: '대한민국의 휴일');
  late _MemorySettings settings;
  late _FakeHolidays holidays;
  late _MockAccess access;
  late _MockRequester requester;
  late _MockRefresher refresher;
  late _MockUseCase alarms;
  late StreamController<void> refreshed;

  HolidaySettingsCubit build() => HolidaySettingsCubit(settings, holidays, access, alarms);

  setUp(() {
    settings = _MemorySettings();
    holidays = _FakeHolidays();
    access = _MockAccess();
    requester = _MockRequester();
    refresher = _MockRefresher();
    alarms = _MockUseCase();
    refreshed = StreamController<void>.broadcast();
    when(() => refresher.refreshed).thenAnswer((_) => refreshed.stream);
    when(() => access.calendar).thenReturn(requester);
    when(() => access.refresher).thenReturn(refresher);
    when(access.check).thenAnswer((_) async => PermissionStatus.denied);
    when(access.ensure).thenAnswer((_) async => PermissionStatus.denied);
    when(requester.openSettings).thenAnswer((_) async {});
    when(() => refresher.refresh(force: any(named: 'force'))).thenAnswer((_) async {});
    when(alarms.sync).thenAnswer((_) async {});
  });

  test('처음은 저장된 설정 · 출처와 권한은 확인 중(null)', () {
    settings.value = const AppSettings(holidayReminder: false);
    expect(build().state, const HolidaySettingsState(holidayReminder: false));
  });

  blocTest<HolidaySettingsCubit, HolidaySettingsState>(
    'check 는 설정 · 지금 출처 · 캘린더 권한을 읽는다',
    build: build,
    act: (cubit) => cubit.check(),
    expect: () => const [
      HolidaySettingsState(source: bundled, calendar: PermissionStatus.denied),
    ],
  );

  blocTest<HolidaySettingsCubit, HolidaySettingsState>(
    '공휴일 캐시가 새로 쓰이면(앱 시작 · 하루 sync) 확인을 기다리지 않고 출처를 다시 읽는다',
    build: build,
    seed: () => const HolidaySettingsState(source: bundled, calendar: PermissionStatus.granted),
    act: (cubit) async {
      holidays.source = device;
      refreshed.add(null);
      await pumpEventQueue();
    },
    expect: () => const [
      HolidaySettingsState(source: device, calendar: PermissionStatus.granted),
    ],
  );

  test('닫으면 캐시 갱신 구독을 끊는다', () async {
    final cubit = build();
    expect(refreshed.hasListener, isTrue);
    await cubit.close();
    expect(refreshed.hasListener, isFalse);
  });

  blocTest<HolidaySettingsCubit, HolidaySettingsState>(
    '권한 확인이 실패해도 출처는 보인다',
    build: () {
      when(access.check).thenThrow(StateError('plugin'));
      return build();
    },
    act: (cubit) => cubit.check(),
    expect: () => const [HolidaySettingsState(source: bundled)],
  );

  blocTest<HolidaySettingsCubit, HolidaySettingsState>(
    '시스템 설정에서 허용하고 돌아오면(check) 캘린더를 다시 읽고 알람을 맞춘다',
    build: build,
    seed: () => const HolidaySettingsState(source: bundled, calendar: PermissionStatus.denied),
    act: (cubit) {
      when(access.check).thenAnswer((_) async => PermissionStatus.granted);
      when(() => refresher.refresh(force: true)).thenAnswer((_) async => holidays.source = device);
      return cubit.check();
    },
    expect: () => const [
      HolidaySettingsState(source: device, calendar: PermissionStatus.granted),
    ],
    verify: (_) => verifyInOrder([() => refresher.refresh(force: true), alarms.sync]),
  );

  blocTest<HolidaySettingsCubit, HolidaySettingsState>(
    '처음 확인(이전 상태 모름)에서 허용이면 다시 읽지 않는다',
    build: () {
      when(access.check).thenAnswer((_) async => PermissionStatus.granted);
      return build();
    },
    act: (cubit) => cubit.check(),
    verify: (_) {
      verifyNever(() => refresher.refresh(force: any(named: 'force')));
      verifyNever(alarms.sync);
    },
  );

  blocTest<HolidaySettingsCubit, HolidaySettingsState>(
    '끄면 저장하고(다른 설정은 그대로) 알람을 맞추며 권한은 묻지 않는다',
    build: build,
    seed: () => const HolidaySettingsState(source: bundled, calendar: PermissionStatus.denied),
    act: (cubit) => cubit.setHolidayReminder(false),
    expect: () => const [
      HolidaySettingsState(
        holidayReminder: false,
        source: bundled,
        calendar: PermissionStatus.denied,
      ),
    ],
    verify: (_) {
      expect(settings.value, const AppSettings(stepGoal: 8000, holidayReminder: false));
      verify(alarms.sync).called(1);
      verifyNever(access.ensure);
    },
  );

  blocTest<HolidaySettingsCubit, HolidaySettingsState>(
    '켜면 저장 → 캘린더 권한을 묻고 → 알람을 맞춘 뒤 출처를 다시 읽는다',
    build: () {
      settings.value = const AppSettings(holidayReminder: false);
      when(access.ensure).thenAnswer((_) async {
        holidays.source = device;
        return PermissionStatus.granted;
      });
      when(access.check).thenAnswer((_) async => PermissionStatus.granted);
      return build();
    },
    seed: () => const HolidaySettingsState(
      holidayReminder: false,
      source: bundled,
      calendar: PermissionStatus.denied,
    ),
    act: (cubit) => cubit.setHolidayReminder(true),
    expect: () => const [
      HolidaySettingsState(source: bundled, calendar: PermissionStatus.denied),
      HolidaySettingsState(source: bundled, calendar: PermissionStatus.granted),
      HolidaySettingsState(source: device, calendar: PermissionStatus.granted),
    ],
    verify: (_) {
      expect(settings.value.holidayReminder, isTrue);
      verify(access.ensure).called(1);
      verify(alarms.sync).called(1);
      // ensure 가 이미 다시 읽었다.
      verifyNever(() => refresher.refresh(force: any(named: 'force')));
    },
  );

  blocTest<HolidaySettingsCubit, HolidaySettingsState>(
    '권한 묻기 · 알람 맞추기가 실패해도 설정은 바뀐다',
    build: () {
      settings.value = const AppSettings(holidayReminder: false);
      when(access.ensure).thenThrow(StateError('plugin'));
      when(alarms.sync).thenThrow(StateError('scheduler'));
      return build();
    },
    act: (cubit) => cubit.setHolidayReminder(true),
    verify: (cubit) {
      expect(settings.value.holidayReminder, isTrue);
      expect(cubit.state.holidayReminder, isTrue);
    },
  );

  group('공휴일 출처 행', () {
    blocTest<HolidaySettingsCubit, HolidaySettingsState>(
      '권한이 거부 상태면 바로 다시 묻고, 허용되면 알람을 맞춘 뒤 출처를 다시 읽는다',
      build: () {
        when(access.requestAgain).thenAnswer((_) async {
          holidays.source = device;
          when(access.check).thenAnswer((_) async => PermissionStatus.granted);
          return PermissionStatus.granted;
        });
        return build();
      },
      seed: () => const HolidaySettingsState(source: bundled, calendar: PermissionStatus.denied),
      act: (cubit) => cubit.openCalendar(),
      expect: () => const [
        HolidaySettingsState(source: bundled, calendar: PermissionStatus.granted),
        HolidaySettingsState(source: device, calendar: PermissionStatus.granted),
      ],
      verify: (_) {
        verify(alarms.sync).called(1);
        verifyNever(requester.openSettings);
        // requestAgain 이 이미 다시 읽었다.
        verifyNever(() => refresher.refresh(force: any(named: 'force')));
      },
    );

    blocTest<HolidaySettingsCubit, HolidaySettingsState>(
      '영구 거부 · 허용이면 앱 설정을 연다(돌아오면 check 가 읽는다)',
      build: () {
        when(access.check).thenAnswer((_) async => PermissionStatus.permanentlyDenied);
        return build();
      },
      act: (cubit) => cubit.openCalendar(),
      verify: (_) {
        verify(requester.openSettings).called(1);
        verifyNever(access.requestAgain);
      },
    );
  });
}
