# walk — 알람 시간대 변경 대응 설계

> 작성 2026-09-30 · 상태: **구현 중** · 앱 문서 [walk 허브](../../../apps/walk/docs/README.md) ·
> 선행 설계 [알람 · 설정 탭](2026-09-27-walk-alarm-design.md) · [남은 시간](2026-09-29-walk-alarm-remaining-time-design.md)

## 1. 문제

알람 정의는 벽시계 시각(`hour` · `minute` · 요일)으로 저장한다 — 맞다. "7시에 깨워줘"는 지금 있는
곳의 7시다. 그런데 `sync` 가 미리 걸어 둔 14일 치 예약은 AlarmManager 에 **절대 시각(epoch)** 으로
들어간다. 시간대가 바뀌면(여행 · 자동 시간대) 예약은 옛 시간대의 7시에 울린다. 지금은 앱을 열거나
복귀할 때 `sync` 가 새 시간대로 다시 걸어 바로잡지만, **앱을 열지 않고 자면 틀린 시각에 울린다.**
`alarm` 패키지(5.13.2)에는 시간대 변경 수신기가 없다.

영향 없음(확인): 서머타임은 14일 치를 `DateTime(y, m, d + n, h, mi)` 로 기기 규칙에 따라 계산하므로
맞다(G20 테스트). 사용자가 시계를 직접 바꾸는 것은 AlarmManager RTC 가 기기 시계 기준이라 맞다.

## 2. 결정

| 결정 | 이유 |
|---|---|
| `ACTION_TIMEZONE_CHANGED` 를 받는 매니페스트 수신기를 둔다 | 암시적 방송 제한의 예외 목록에 있어 앱이 꺼져 있어도 받는다 |
| 수신기는 **헤드리스 Flutter 엔진**을 띄워 기존 `AlarmUseCase.sync()` 를 한 번 돌린다 | 예약 규칙을 Kotlin 에 중복하지 않는다. 패키지 내부 저장소를 직접 고치면 패키지 버전에 묶인다 |
| `ACTION_TIME_CHANGED`(시계 수동 변경)는 받지 않는다 | §1 — 영향 없음 |
| 앱이 떠 있으면(메인 엔진이 살아 있으면) 헤드리스 엔진을 띄우지 않고 메인 엔진에 채널로 `resync` 를 요청한다 | 한 프로세스에 엔진 둘이면 `alarm` 플러그인의 네이티브 싱글턴(울림 스트림 등)이 두 번째 엔진에 붙었다가 destroy 때 떨어져, 떠 있는 앱의 울림 화면이 끊길 수 있다. 메인 isolate 에서 돌리면 목록도 바로 다시 읽는다 |

## 3. 흐름

```
시간대 변경 → TimeZoneChangedReceiver.onReceive (goAsync)
  ├ 메인 엔진 있음(MainActivity 가 configureFlutterEngine 에서 정적 참조를 두고 cleanUpFlutterEngine 에서 지운다)
  │   → MethodChannel "walk/background" 로 "resync" 호출 → 메인 isolate: AlarmUseCase.sync() → 알람 목록 load()
  │   → 응답(성공 · 실패) 또는 9초 → finish()
  └ 메인 엔진 없음
  → FlutterEngine(context) (플러그인 자동 등록)
  → Dart 진입점 alarmResyncMain() 실행
       Alarm.init() → configureDependencies() → AlarmUseCase.sync()
       → MethodChannel "walk/background" 에 "done" (성공 · 실패 모두)
  → 수신기: 엔진 destroy, pendingResult.finish()
  시간 제한: 9초 안에 "done" 이 없으면 엔진을 destroy 하고 finish (goAsync 한도 10초)
```

- Dart 진입점은 `@pragma('vm:entry-point')` 최상위 함수. 로직은 테스트 가능한 함수
  `runAlarmResync({required Future<void> Function() init, required Future<void> Function() sync, required Future<void> Function() done})`
  로 분리한다 — `init` 이나 `sync` 가 던져도 `done` 은 반드시 부르고, 예외는 삼킨다(로그만).
- `oneShotAt` 은 오프셋 없는 로컬 ISO 문자열이라 새 시간대에서 "그 지역의 같은 벽시계 시각"으로
  읽힌다 — 벽시계 의미와 맞으므로 그대로 둔다.
- 패키지 id 는 로컬 날짜 기준(`triggerIndex`)이라 시간대가 바뀌어도 같은 날의 회차는 같은 id 를
  유지하고, `sync` 는 시각만 다른 같은 id 를 다시 건다(G7 테스트로 고정됨).

## 4. 알려진 한계

- 헤드리스 실행이 9초를 넘기면 그 회차는 다음 앱 실행 때 바로잡힌다.

## 5. 테스트 (TDD)

- Dart `run_alarm_resync_test`: 순서(init → sync → done), `init` 실패 시 sync 건너뛰고 done,
  `sync` 실패 시 done, done 은 정확히 한 번.
- 메인 isolate 의 `resync` 채널 핸들러: 호출되면 sync 뒤 목록 load, sync 가 실패해도 load 하고 응답한다
  (셸 위젯 테스트 · 가짜 채널).
- Dart `alarm_use_case_test`(기존 G7 에 추가): 시간대가 바뀐 시계(같은 벽시계, 다른 오프셋)를 흉내 —
  예약된 절대 시각이 새 벽시계 07:00 과 다르면 다시 건다. 1회성 `oneShotAt` 도 새 벽시계로 걸린다.
- Kotlin 수신기는 단위 테스트하지 않는다(엔진 · 방송 의존). 에뮬레이터로 확인:
  알람을 걸고 → 앱을 종료 → 시간대 변경(`adb shell service call alarm 3 s16 Europe/Paris` 또는
  동등 명령) → `dumpsys alarm` 의 예약이 새 시간대 벽시계 시각으로 바뀌었는지, logcat 에 수신기 · done.
  앱을 띄운 채로도 한 번 — 헤드리스 엔진이 뜨지 않고 목록 카드가 바로 새 시각을 보이는지.
