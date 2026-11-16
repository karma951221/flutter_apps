import 'dart:convert';

import 'package:injectable/injectable.dart';

import '../../alarm/entity/alarm.dart';
import '../../alarm/usecase/alarm_use_case.dart';
import '../chat_model.dart';
import 'tool_input.dart';
import 'tool_result.dart';
import 'tool_summary.dart';

/// 물어보기 모델이 지금 알람 설정을 읽는 도구. 소리 · 볼륨 같은 기기 세부는 보내지 않는다.
@lazySingleton
class AlarmTools {
  AlarmTools(this._alarms);

  final AlarmUseCase _alarms;

  static const name = 'list_alarms';

  ToolSpec get definition => const ToolSpec(
    name: name,
    description:
        '지금 알람 설정(시각 · 반복 요일 · 라벨 · 켜짐 · 다음 울림 · 다음 1회 건너뜀 · 스누즈)과 '
        '모든 알람을 쉬는 기간을 본다. 반복이 비면 1회성이다.',
    parameters: {'type': 'object', 'properties': {}, 'required': []},
  );

  Future<ToolResult> run() async {
    try {
      final list = await _alarms.list();
      final next = await _alarms.nextRings();
      final pause = await _alarms.pause();
      return ToolResult(
        json: jsonEncode({
          'alarms': [for (final a in list) _alarmJson(a, next[a.id])],
          'paused': pause == null
              ? null
              : {'from': toolDay(pause.from), 'until': toolDay(pause.until)},
        }),
        summary: ToolSummary(kind: ChatToolKind.alarms, count: list.length),
      );
    } catch (_) {
      return toolError('tool_failed', ChatToolKind.alarms);
    }
  }

  static Map<String, Object?> _alarmJson(Alarm a, DateTime? next) => {
    'time':
        '${a.hour.toString().padLeft(2, '0')}:${a.minute.toString().padLeft(2, '0')}',
    'repeat': [
      for (final d in Weekday.values)
        if (a.repeat.contains(d)) d.name,
    ],
    'label': a.label.trim().isEmpty ? null : a.label,
    'enabled': a.enabled,
    'next': next == null ? null : '${toolDay(next)}T${toolTime(next)}',
    'skip_next': a.skippedAt != null,
    'snooze_minutes': a.snoozeMinutes,
    'snooze_limit': a.snoozeLimit,
  };
}
