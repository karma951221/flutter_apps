import 'package:freezed_annotation/freezed_annotation.dart';

import 'entity/alarm.dart';
import 'upcoming_triggers.dart';

part 'one_shot_draft.freezed.dart';

/// 한 번 알람 화면의 더하기 버튼 — 큰 것부터.
const oneShotSteps = [
  Duration(hours: 1),
  Duration(minutes: 10),
  Duration(minutes: 5),
  Duration(minutes: 1),
];

/// 상대 모드("얼마 뒤")의 상한. 넘게 더하면 이 값에 멈춘다.
const oneShotMaxOffset = Duration(hours: 23, minutes: 59);

/// 한 번 알람의 울릴 시각을 정하는 중인 값.
///
/// 상대 모드(`fixedAt == null`)는 "지금부터 [offset] 뒤" — 시간이 흘러도 N 뒤는 그대로이고
/// 울릴 시각만 움직인다. 고정 모드는 시각 휠로 정한 [fixedAt] 이다. 버튼은 모드에 맞는 쪽에 더한다.
@freezed
class OneShotDraft with _$OneShotDraft {
  /// 상대 모드의 "얼마 뒤".
  @override
  final Duration offset;

  /// 고정 모드의 울릴 시각. null 이면 상대 모드.
  @override
  final DateTime? fixedAt;

  const OneShotDraft({this.offset = Duration.zero, this.fixedAt});

  /// 기존 알람을 열 때 — `oneShotAt` 이 미래면 그 시각으로 고정, 아니면 상대 모드 0.
  /// (Freezed 가 factory 를 union 으로 오해하지 않게 static 으로 둔다.)
  static OneShotDraft fromAlarm(Alarm alarm, DateTime now) {
    final at = alarm.oneShotAt;
    return at != null && at.isAfter(now) ? OneShotDraft(fixedAt: at) : const OneShotDraft();
  }

  OneShotDraft add(Duration step) {
    final at = fixedAt;
    if (at != null) {
      // 벽시계 산술 — 생성자가 자정 · 월말을 넘긴다.
      return OneShotDraft(
        offset: offset,
        fixedAt: DateTime(
          at.year,
          at.month,
          at.day,
          at.hour,
          at.minute + step.inMinutes,
          at.second,
        ),
      );
    }
    final next = offset + step;
    return OneShotDraft(offset: next > oneShotMaxOffset ? oneShotMaxOffset : next);
  }

  OneShotDraft reset() => const OneShotDraft();

  /// [hour]:[minute] 로 고정한다 — 지금 뒤에 처음 오는 그 시각(초 0).
  OneShotDraft fixAt(int hour, int minute, DateTime now) =>
      OneShotDraft(fixedAt: nextOccurrence(hour, minute, now));

  DateTime ringAt(DateTime now) => fixedAt ?? now.add(offset);

  /// 울릴 때까지. 지났으면 0.
  Duration remaining(DateTime now) {
    final left = ringAt(now).difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  /// 1분 미만이면 저장하지 않는다(0분 알람 방지).
  bool canSave(DateTime now) => remaining(now) >= const Duration(minutes: 1);
}
