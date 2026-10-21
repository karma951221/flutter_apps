import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission/permission.dart';

import '../../../domain/alarm/holiday/holiday_calendar.dart';
import '../../../domain/alarm/holiday/holiday_calendar_access.dart';
import '../../../domain/alarm/usecase/alarm_use_case.dart';
import '../../../domain/settings/repository/settings_repository.dart';
import 'holiday_settings_state.dart';

/// 설정 탭 "알람" 섹션(웨이브 3 스펙 §3.4 · §5). 셸이 소유하고, 시작 · 복귀 때 [check] 한다.
///
/// 공휴일 미리 알림을 바꾸면 알람을 다시 맞춘다(sync 가 미리 알림을 걸거나 지운다). 캘린더
/// 권한을 새로 받으면 오늘 이미 읽은 캐시(내장 표)를 버리고 폰 캘린더를 다시 읽은 뒤 맞춘다.
class HolidaySettingsCubit extends Cubit<HolidaySettingsState> {
  HolidaySettingsCubit(
    this._settings,
    this._holidays,
    this._access,
    this._alarms,
  ) : super(
        HolidaySettingsState(holidayReminder: _settings.load().holidayReminder),
      ) {
    // 시작 · 하루 sync 의 캐시 갱신이 check 보다 늦게 끝나도 출처가 옛것으로 남지 않게 한다.
    _refreshed = _access.refresher.refreshed.listen((_) {
      if (!isClosed) emit(state.copyWith(source: _holidays.source));
    });
  }

  final SettingsRepository _settings;
  final HolidayCalendar _holidays;
  final HolidayCalendarAccess _access;
  final AlarmUseCase _alarms;
  late final StreamSubscription<void> _refreshed;

  @override
  Future<void> close() async {
    await _refreshed.cancel();
    return super.close();
  }

  /// 던지지 않는다. 시스템 설정에서 캘린더를 허용하고 돌아왔으면(앞서 허용 아님 → 지금 허용)
  /// 캘린더를 다시 읽고 알람을 맞춘다.
  Future<void> check() async {
    final before = state.calendar;
    PermissionStatus? calendar;
    try {
      calendar = await _access.check();
    } on Object {
      calendar = null;
    }
    if (before != null &&
        before != PermissionStatus.granted &&
        calendar == PermissionStatus.granted) {
      await _access.refresher.refresh(force: true);
      await _syncQuietly();
    }
    if (isClosed) return;
    emit(
      HolidaySettingsState(
        holidayReminder: _settings.load().holidayReminder,
        source: _holidays.source,
        calendar: calendar,
      ),
    );
  }

  /// 스위치. 바로 반영해 저장하고, 켰으면 캘린더 권한을 묻는다(거부하면 내장 표). 알람을 맞춘다.
  Future<void> setHolidayReminder(bool on) async {
    if (on == state.holidayReminder) return;
    emit(state.copyWith(holidayReminder: on));
    await _settings.save(_settings.load().copyWith(holidayReminder: on));
    if (on) {
      try {
        // 새로 허용되면 ensure 가 캘린더를 다시 읽는다 — check 가 또 읽지 않게 상태에 둔다.
        final calendar = await _access.ensure();
        if (!isClosed) emit(state.copyWith(calendar: calendar));
      } on Object {
        // 권한을 못 물어도 내장 표로 알린다.
      }
    }
    await _syncQuietly();
    await check();
  }

  /// 공휴일 출처 행. 거부 상태면 바로 다시 묻고(허용되면 알람을 맞춘다), 영구 거부 · 허용이면
  /// 앱 설정을 연다 — 돌아오면 셸의 복귀가 [check] 한다.
  Future<void> openCalendar() async {
    if (await _access.check() == PermissionStatus.denied) {
      final calendar = await _access.requestAgain();
      if (calendar == PermissionStatus.granted) {
        if (!isClosed) emit(state.copyWith(calendar: calendar));
        await _syncQuietly();
      }
    } else {
      await _access.calendar.openSettings();
    }
    await check();
  }

  Future<void> _syncQuietly() async {
    try {
      await _alarms.sync();
    } on Object {
      // 다음 복귀 · 하루 sync 에서 다시 맞춘다.
    }
  }
}
