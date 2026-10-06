import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 네이티브 공용 실행기(`AlarmResync` — 시간대 변경 수신기 · 하루 한 번 작업) ↔ Dart.
/// 메인 엔진은 `resync` 를 받고(셸), 헤드리스 엔진(`alarmResyncMain`)은 끝나면 `done` 을 보낸다.
const backgroundChannel = MethodChannel('walk/background');

/// 앱 밖(헤드리스 엔진)에서 알람 예약을 다시 맞춘다 — 시간대가 바뀌었거나 하루 한 번 작업.
///
/// [sync] 앞에 [refreshHolidays] 로 공휴일 캐시를 갱신한다 — 앱을 오래 열지 않아도 하루 한 번
/// 작업이 폰 캘린더를 다시 읽게(웨이브 3 스펙 §2). 갱신이 실패해도 [sync] 는 한다(지난 캐시 · 내장 표).
/// [init] 이 실패하면 둘 다 건너뛴다. 어느 쪽이 실패해도 [done] 은 한 번 부른다 —
/// 네이티브 수신기가 그 신호로 엔진을 내리고 방송 처리를 끝낸다. 예외는 삼킨다(로그만).
Future<void> runAlarmResync({
  required Future<void> Function() init,
  required Future<void> Function() refreshHolidays,
  required Future<void> Function() sync,
  required Future<void> Function() done,
}) async {
  try {
    await init();
    try {
      await refreshHolidays();
    } on Object catch (e) {
      debugPrint('holiday refresh failed: $e');
    }
    await sync();
  } on Object catch (e, s) {
    debugPrint('alarm resync failed: $e\n$s');
  }
  try {
    await done();
  } on Object catch (e) {
    debugPrint('alarm resync done failed: $e');
  }
}
