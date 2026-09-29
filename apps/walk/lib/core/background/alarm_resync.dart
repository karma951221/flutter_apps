import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 네이티브 시간대 변경 수신기(`TimeZoneChangedReceiver`) ↔ Dart. 메인 엔진은 `resync` 를
/// 받고(셸), 헤드리스 엔진(`alarmResyncMain`)은 끝나면 `done` 을 보낸다.
const backgroundChannel = MethodChannel('walk/background');

/// 시간대가 바뀌어 앱 밖(헤드리스 엔진)에서 알람 예약을 다시 맞춘다.
///
/// [init] 이 실패하면 [sync] 는 건너뛴다. 어느 쪽이 실패해도 [done] 은 한 번 부른다 —
/// 네이티브 수신기가 그 신호로 엔진을 내리고 방송 처리를 끝낸다. 예외는 삼킨다(로그만).
Future<void> runAlarmResync({
  required Future<void> Function() init,
  required Future<void> Function() sync,
  required Future<void> Function() done,
}) async {
  try {
    await init();
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
