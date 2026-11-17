import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 네이티브 공용 실행기(`BackgroundDispatcher` — 시간대 변경 수신기 · 하루 한 번 작업 · 미리 알림
/// 액션) ↔ Dart. 메인 엔진은 `resync` · `reminderAction` 을 받고(셸) `awaitIdle` 을 부르며
/// ([awaitBackgroundIdle]), 헤드리스 엔진(`alarmResyncMain` · `alarmReminderActionMain`)은 끝나면
/// `done`(bool: 성공 여부)을 보낸다.
const backgroundChannel = MethodChannel('walk/background');

/// [awaitBackgroundIdle] 이 네이티브 응답을 기다리는 한도. 헤드리스 일은 보통 1–2초 안에 끝난다.
const backgroundIdleTimeout = Duration(seconds: 10);

/// 네이티브 `BackgroundDispatcher` 가 헤드리스 엔진에서 돌리는 일(미리 알림 [이번만 끄기] 등)이
/// 끝날 때까지 기다린다(`walk/background` 의 `awaitIdle` — 돌고 있으면 끝날 때, 아니면 바로 응답).
/// 셸이 시작 · 복귀 sync 앞에 부른다 — 헤드리스가 `skippedAt` 을 쓰기 직전 저장소를 읽고 sync 하면
/// 건너뛴 회차를 다시 건다. 끝나면 sync 가 저장소를 디스크에서 다시 읽는다(`PrefsAlarmRepository.load`).
///
/// [timeout] 안에 답이 없거나 채널이 없거나 오류면 그냥 끝난다(던지지 않는다) — 기다림이 sync 를
/// 막지는 않는다.
Future<void> awaitBackgroundIdle({Duration timeout = backgroundIdleTimeout}) async {
  try {
    await backgroundChannel.invokeMethod<void>('awaitIdle').timeout(timeout);
  } on TimeoutException {
    debugPrint('background awaitIdle timed out');
  } on MissingPluginException {
    // 네이티브가 없다(테스트 · 다른 플랫폼).
  } on PlatformException catch (e) {
    debugPrint('background awaitIdle failed: $e');
  }
}

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

/// 알람 예약을 다시 맞추는 일(시간대가 바뀌었거나 하루 한 번 작업 · 미리 알림 액션의 건너뛰기).
///
/// [sync] 앞에 [refreshHolidays] 로 공휴일 캐시를 갱신한다 — 앱을 오래 열지 않아도 하루 한 번
/// 작업이 폰 캘린더를 다시 읽고, 캘린더 권한이 회수됐으면 앱과 같이 내장 표로 판단하게(웨이브 3 스펙 §2).
/// 갱신이 실패해도 [sync] 는 한다(지난 캐시 · 내장 표).
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
