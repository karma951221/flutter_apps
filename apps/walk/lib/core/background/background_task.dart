import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 네이티브 공용 실행기(`BackgroundDispatcher` — 시간대 변경 수신기 · 하루 한 번 작업 · 미리 알림
/// 액션) ↔ Dart. 메인 엔진은 `resync` · `reminderAction` 을 받고(셸), 헤드리스 엔진
/// (`alarmResyncMain` · `alarmReminderActionMain`)은 끝나면 `done`(bool: 성공 여부)을 보낸다.
const backgroundChannel = MethodChannel('walk/background');

/// 앱 밖(헤드리스 엔진)에서 한 가지 일을 한다.
///
/// [init] 이 실패하면 [task] 를 건너뛴다. 어느 쪽이 실패해도 [done] 은 한 번 부른다(성공했으면
/// `true`) — 네이티브가 그 신호로 엔진을 내리고 방송 처리를 끝낸다(미리 알림 액션은 실패면 알림을
/// 남긴다). 예외는 삼킨다(로그만).
Future<void> runBackgroundTask({
  required Future<void> Function() init,
  required Future<void> Function() task,
  required Future<void> Function(bool ok) done,
}) async {
  var ok = false;
  try {
    await init();
    await task();
    ok = true;
  } on Object catch (e, s) {
    debugPrint('background task failed: $e\n$s');
  }
  try {
    await done(ok);
  } on Object catch (e) {
    debugPrint('background task done failed: $e');
  }
}

/// 알람 예약을 다시 맞추는 일(시간대가 바뀌었거나 하루 한 번 작업).
///
/// [sync] 앞에 [refreshHolidays] 로 공휴일 캐시를 갱신한다 — 앱을 오래 열지 않아도 하루 한 번
/// 작업이 폰 캘린더를 다시 읽게(웨이브 3 스펙 §2). 갱신이 실패해도 [sync] 는 한다(지난 캐시 · 내장 표).
Future<void> Function() resyncTask({
  required Future<void> Function() refreshHolidays,
  required Future<void> Function() sync,
}) => () async {
  try {
    await refreshHolidays();
  } on Object catch (e) {
    debugPrint('holiday refresh failed: $e');
  }
  await sync();
};

/// 미리 알림 액션 진입점 인자(`["skip", "<packageId>"]`, 네이티브 `ReminderActionReceiver`)의
/// packageId. 다른 모양이면 [FormatException].
int reminderActionPackageId(List<String> args) {
  if (args case ['skip', final id]) {
    if (int.tryParse(id) case final packageId?) return packageId;
  }
  throw FormatException('bad reminder action args', args.toString());
}
