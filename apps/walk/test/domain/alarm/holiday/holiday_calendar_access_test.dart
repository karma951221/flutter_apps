import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:permission/permission.dart';
import 'package:walk/domain/alarm/holiday/holiday_calendar.dart';
import 'package:walk/domain/alarm/holiday/holiday_calendar_access.dart';
import 'package:walk/domain/settings/entity/app_settings.dart';
import 'package:walk/domain/settings/repository/settings_repository.dart';

class _MockRequester extends Mock implements PermissionRequester {}

class _FakeRefresher implements HolidayRefresher {
  final calls = <bool>[];

  @override
  Future<void> refresh({bool force = false}) async => calls.add(force);
}

class _MemorySettings implements SettingsRepository {
  AppSettings value = const AppSettings();

  @override
  AppSettings load() => value;

  @override
  Future<void> save(AppSettings settings) async => value = settings;
}

void main() {
  late _MockRequester calendar;
  late _FakeRefresher refresher;
  late _MemorySettings settings;
  late HolidayCalendarAccess access;

  setUp(() {
    calendar = _MockRequester();
    refresher = _FakeRefresher();
    settings = _MemorySettings();
    access = HolidayCalendarAccess(calendar: calendar, refresher: refresher, settings: settings);
  });

  test('ensure 로 새로 허용되면 그 자리에서 폰 캘린더를 다시 읽는다(force)', () async {
    when(calendar.check).thenAnswer((_) async => PermissionStatus.denied);
    when(calendar.ensure).thenAnswer((_) async => PermissionStatus.granted);

    expect(await access.ensure(), PermissionStatus.granted);
    expect(refresher.calls, [true]);
  });

  test('이미 허용이었으면 다시 읽지 않는다', () async {
    when(calendar.check).thenAnswer((_) async => PermissionStatus.granted);
    when(calendar.ensure).thenAnswer((_) async => PermissionStatus.granted);

    await access.ensure();
    expect(refresher.calls, isEmpty);
  });

  test('거부하면 다시 읽지 않는다(내장 표 그대로)', () async {
    when(calendar.check).thenAnswer((_) async => PermissionStatus.denied);
    when(calendar.ensure).thenAnswer((_) async => PermissionStatus.denied);

    expect(await access.ensure(), PermissionStatus.denied);
    expect(refresher.calls, isEmpty);
  });

  test('check 는 요청기 상태 그대로', () async {
    when(calendar.check).thenAnswer((_) async => PermissionStatus.permanentlyDenied);
    expect(await access.check(), PermissionStatus.permanentlyDenied);
  });

  group('ensureIfReminding (알람 저장 때)', () {
    test('공휴일 미리 알림이 켜져 있으면 묻는다', () async {
      when(calendar.check).thenAnswer((_) async => PermissionStatus.denied);
      when(calendar.ensure).thenAnswer((_) async => PermissionStatus.granted);

      await access.ensureIfReminding();

      verify(calendar.ensure).called(1);
      expect(refresher.calls, [true]);
    });

    test('꺼져 있으면 묻지 않는다', () async {
      settings.value = const AppSettings(holidayReminder: false);

      await access.ensureIfReminding();

      verifyNever(calendar.ensure);
      verifyNever(calendar.check);
    });
  });
}
