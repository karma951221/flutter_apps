import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/alarm/entity/alarm.dart';
import 'package:walk/domain/alarm/entity/alarm_pause.dart';
import 'package:walk/domain/alarm/usecase/alarm_use_case.dart';
import 'package:walk/domain/chat/tool/alarm_tools.dart';
import 'package:walk/domain/chat/tool/tool_summary.dart';

class _Alarms extends Mock implements AlarmUseCase {}

void main() {
  late _Alarms alarms;
  late AlarmTools tools;

  setUp(() {
    alarms = _Alarms();
    tools = AlarmTools(alarms);
    when(() => alarms.nextRings()).thenAnswer((_) async => {});
    when(() => alarms.pause()).thenAnswer((_) async => null);
  });

  Future<Map<String, Object?>> run() async {
    final r = await tools.run();
    expect(r.isError, isFalse, reason: r.json);
    return jsonDecode(r.json) as Map<String, Object?>;
  }

  test('정의 이름은 list_alarms, 입력 없음', () {
    expect(tools.definition.name, 'list_alarms');
    expect(tools.definition.parameters['required'], isEmpty);
  });

  test('알람 설정을 시각 · 반복 · 라벨 · 다음 울림으로 준다', () async {
    when(() => alarms.list()).thenAnswer(
      (_) async => [
        Alarm(
          id: 3,
          hour: 7,
          minute: 5,
          repeat: const {Weekday.mon, Weekday.wed},
          label: '출근',
          snoozeMinutes: 5,
          snoozeLimit: 3,
          skippedAt: DateTime(2026, 11, 18, 7, 5),
        ),
      ],
    );
    when(
      () => alarms.nextRings(),
    ).thenAnswer((_) async => {3: DateTime(2026, 11, 17, 7, 5)});
    final r = await tools.run();
    expect(r.summary?.kind, ChatToolKind.alarms);
    expect(r.summary?.count, 1);
    expect(jsonDecode(r.json), {
      'alarms': [
        {
          'time': '07:05',
          'repeat': ['mon', 'wed'],
          'label': '출근',
          'enabled': true,
          'next': '2026-11-17T07:05',
          'skip_next': true,
          'snooze_minutes': 5,
          'snooze_limit': 3,
        },
      ],
      'paused': null,
    });
  });

  test('빈 라벨은 null, 꺼진 알람은 next null, 소리 · 볼륨은 보내지 않는다', () async {
    when(() => alarms.list()).thenAnswer(
      (_) async => [const Alarm(id: 1, hour: 22, minute: 0, enabled: false)],
    );
    final r = await tools.run();
    expect(r.json, isNot(contains('sound')));
    expect(r.json, isNot(contains('volume')));
    final a = ((jsonDecode(r.json) as Map)['alarms'] as List).single as Map;
    expect(a['label'], isNull);
    expect(a['repeat'], isEmpty);
    expect(a['next'], isNull);
    expect(a['enabled'], isFalse);
    expect(a['skip_next'], isFalse);
  });

  test('쉬는 기간이 있으면 paused 날짜', () async {
    when(() => alarms.list()).thenAnswer((_) async => []);
    when(() => alarms.pause()).thenAnswer(
      (_) async => AlarmPause(
        from: DateTime(2026, 11, 20),
        until: DateTime(2026, 11, 22),
      ),
    );
    expect((await run())['paused'], {
      'from': '2026-11-20',
      'until': '2026-11-22',
    });
  });

  test('목록을 못 읽으면 tool_failed', () async {
    when(() => alarms.list()).thenThrow(Exception('x'));
    final r = await tools.run();
    expect(r.isError, isTrue);
    expect(jsonDecode(r.json), {'error': 'tool_failed'});
  });
}
