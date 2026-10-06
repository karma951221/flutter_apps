import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:l10n/l10n.dart';

import '../../domain/alarm/entity/alarm.dart';
import '../../domain/alarm/entity/alarm_reminder.dart';
import '../../domain/alarm/scheduler/reminder_scheduler.dart';

/// 네이티브 미리 알림(`walk/reminders`, 웨이브 3 스펙 §4.1)으로 건다. 시각은 epoch millis.
///
/// 채널 약속:
/// - `scheduled` → `[{id: int, at: int, ringAt: int}]`(걸렸거나 떠 있는 것, 울릴 시각 전). 띄운 항목은
///   알림이 닫혀도(`dismiss` · 밀어 지우기) 울릴 시각까지 저장소에 남겨(`shown=true`) 계속 돌려준다 —
///   빠지면 Dart 가 다시 걸어 같은 알림이 또 뜬다. 저장소에서 지우는 것은 `cancel` 과 울릴 시각이
///   지났을 때뿐이다.
/// - `schedule` ← [argumentsFor] 의 맵. `actions` 의 `action` 은 `skip`(Dart `skipOccurrence(packageId)`) ·
///   `dismiss`(알림만 닫는다. 저장 항목은 남긴다)
/// - `cancel` ← `{id: int}`(예약과 떠 있는 알림 모두)
///
/// 문구는 예약이 화면 밖에서도 일어나므로 `PackageAlarmScheduler` 처럼 기기 언어로 Dart 가 만든다.
/// 채널이 없으면(테스트 · 네이티브 미연결) 빈 맵 · 무시.
@LazySingleton(as: ReminderScheduler)
class ChannelReminderScheduler implements ReminderScheduler {
  const ChannelReminderScheduler();

  static const channelName = 'walk/reminders';
  static const _channel = MethodChannel(channelName);

  @override
  Future<Map<int, ScheduledReminder>> scheduled() async {
    final List<Object?>? rows;
    try {
      rows = await _channel.invokeMethod<List<Object?>>('scheduled');
    } on MissingPluginException {
      return {};
    }
    return {
      for (final row in rows ?? const [])
        if (row case {'id': final int id, 'at': final int at, 'ringAt': final int ringAt})
          id: (
            at: DateTime.fromMillisecondsSinceEpoch(at),
            ringAt: DateTime.fromMillisecondsSinceEpoch(ringAt),
          ),
    };
  }

  @override
  Future<void> schedule(AlarmReminder reminder, Alarm alarm) async =>
      _invoke('schedule', await prepareArguments(reminder, alarm, _l10n()));

  /// [argumentsFor] 를 부르기 전에 그 언어의 날짜 기호를 올린다. 헤드리스 엔진(하루 sync · 미리 알림
  /// 버튼)에는 기호를 올려 줄 `MaterialApp` 이 없어, 빠뜨리면 대체 문구(`07:00` · `10/9`)가 저장돼
  /// 시각이 같은 동안 메인 엔진 sync 도 다시 걸지 않는다.
  static Future<Map<String, Object?>> prepareArguments(
    AlarmReminder reminder,
    Alarm alarm,
    AppLocalizations l10n,
  ) async {
    try {
      await initializeDateFormatting(l10n.localeName);
    } on Object {
      // 기호가 없는 언어면 argumentsFor 가 대체 문구를 쓴다.
    }
    return argumentsFor(reminder, alarm, l10n);
  }

  @override
  Future<void> cancel(int reminderId) => _invoke('cancel', {'id': reminderId});

  Future<void> _invoke(String method, Object? arguments) async {
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } on MissingPluginException {
      // 네이티브가 없으면 미리 알림 없이 지낸다.
    }
  }

  /// `schedule` 인자. 영어 · 일본어 공휴일 본문은 이름을 쓰지 않는다(번역표가 없다 — ARB 가 정한다).
  static Map<String, Object?> argumentsFor(
    AlarmReminder reminder,
    Alarm alarm,
    AppLocalizations l10n,
  ) {
    final locale = l10n.localeName;
    final time = _format(() => DateFormat.jm(locale).format(reminder.ringAt), () {
      final at = reminder.ringAt;
      return '${_two(at.hour)}:${_two(at.minute)}';
    });
    final (title, body, actions) = switch (reminder.kind) {
      ReminderKind.soon => (
        l10n.walkReminderSoonTitle,
        l10n.walkReminderSoonBody(
          time,
          alarm.label.isEmpty ? l10n.walkAlarmDefaultTitle : alarm.label,
        ),
        [_action('skip', l10n.walkReminderTurnOffOnce)],
      ),
      ReminderKind.holiday => (
        l10n.walkReminderHolidayTitle,
        _holidayBody(reminder, l10n, time),
        [_action('skip', l10n.walkReminderSkip), _action('dismiss', l10n.walkReminderRing)],
      ),
    };
    return {
      'id': reminder.id,
      'packageId': reminder.packageId,
      'alarmId': reminder.alarmId,
      'kind': reminder.kind.name,
      'at': reminder.at.millisecondsSinceEpoch,
      'ringAt': reminder.ringAt.millisecondsSinceEpoch,
      'title': title,
      'body': body,
      'actions': actions,
    };
  }

  static String _holidayBody(AlarmReminder reminder, AppLocalizations l10n, String time) {
    final at = reminder.ringAt;
    final date = _format(
      () => DateFormat.MMMd(l10n.localeName).format(at),
      () => '${at.month}/${at.day}',
    );
    return switch (reminder.holidayName) {
      final name? when name.isNotEmpty => l10n.walkReminderHolidayBody(date, name, time),
      _ => l10n.walkReminderHolidayBodyNoName(date, time),
    };
  }

  static Map<String, String> _action(String action, String label) => {
    'action': action,
    'label': label,
  };

  /// 날짜 기호가 아직 없으면(로컬라이제이션 로드 전 · 헤드리스) [fallback].
  static String _format(String Function() format, String Function() fallback) {
    try {
      return format();
    } on Object {
      return fallback();
    }
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  static AppLocalizations _l10n() => lookupAppLocalizations(
    basicLocaleListResolution(
      PlatformDispatcher.instance.locales,
      AppLocalizations.supportedLocales,
    ),
  );
}
