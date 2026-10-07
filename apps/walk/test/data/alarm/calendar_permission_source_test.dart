import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission/permission.dart';
import 'package:walk/data/alarm/calendar_permission_source.dart';
import 'package:walk/domain/alarm/holiday/holiday_calendar.dart';
import 'package:walk/domain/alarm/holiday/holiday_calendar_access.dart';
import 'package:walk/domain/settings/entity/app_settings.dart';
import 'package:walk/domain/settings/repository/settings_repository.dart';

class _Refresher implements HolidayRefresher {
  final forced = <bool>[];

  @override
  Future<void> refresh({bool force = false}) async => forced.add(force);
}

class _Settings implements SettingsRepository {
  @override
  AppSettings load() => const AppSettings();

  @override
  Future<void> save(AppSettings settings) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(CalendarPermissionSource.channelName);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<String> calls;

  void answer(Object? status) {
    calls = [];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      return call.method == 'openSettings' ? null : status;
    });
  }

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('네이티브 상태 이름을 공용 상태로 바꾼다', () async {
    for (final (name, status) in [
      ('granted', PermissionStatus.granted),
      ('denied', PermissionStatus.denied),
      ('permanentlyDenied', PermissionStatus.permanentlyDenied),
    ]) {
      answer(name);
      expect(await CalendarPermissionSource().check(), status, reason: name);
    }
  });

  test('모르는 값 · null 은 거부로 본다', () async {
    answer('restricted');
    expect(await CalendarPermissionSource().check(), PermissionStatus.denied);
    answer(null);
    expect(await CalendarPermissionSource().check(), PermissionStatus.denied);
  });

  test('request 는 네이티브 요청(읽기 권한 대화상자) 결과를 돌려준다', () async {
    answer('granted');

    final status = await CalendarPermissionSource().request();

    expect(calls, ['request']);
    expect(status, PermissionStatus.granted);
  });

  test('openSettings 는 앱 설정을 연다', () async {
    answer('denied');
    await CalendarPermissionSource().openSettings();
    expect(calls, ['openSettings']);
  });

  test('채널이 없으면 거부로 보고 던지지 않는다', () async {
    final source = CalendarPermissionSource();
    expect(await source.check(), PermissionStatus.denied);
    expect(await source.request(), PermissionStatus.denied);
    await source.openSettings();
  });

  test('거부 상태에서 다시 묻고 허용되면 공휴일 캐시를 새로 읽는다(설정 탭 출처 행)', () async {
    calls = [];
    var granted = false;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      if (call.method == 'request') granted = true;
      return granted ? 'granted' : 'denied';
    });
    final refresher = _Refresher();
    final access = HolidayCalendarAccess(
      calendar: PermissionRequester(CalendarPermissionSource()),
      refresher: refresher,
      settings: _Settings(),
    );

    expect(await access.requestAgain(), PermissionStatus.granted);

    expect(calls, ['check', 'request']);
    expect(refresher.forced, [true]);
  });
}
