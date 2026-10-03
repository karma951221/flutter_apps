# W2 tracking — 구현 기록

> [pawlog 허브](../../README.md) · [계획](plan.md) · [테스트](testing.md) · [구현 리뷰](../../audits/2026-10-03-implementation-review.md)

설계 판단 · 리뷰에서 고친 것 · 검증 결과를 남긴다. 진행 상태는 [진행 현황](../../status.md)에만 적는다.
추적기 `GeolocatorWalkTracker` 는 `cdc1ac2`(단계 ④ — 리뷰 D3 을 풀려고 앞당김), 진행 화면은
`4627805`(단계 ⑤), 리뷰 반영은 `93d722b` 다.

## 2026-10-03 — 설계 판단

### 추적기는 DI 싱글턴, cubit 은 화면마다

`GeolocatorWalkTracker` 는 `@LazySingleton(as: WalkTracker)` 이고 `ActiveWalkCubit` 은
`@injectable`(페이지 `BlocProvider`)이다. 추적은 화면보다 오래 산다 — 뒤로 가기로 진행 화면을
떠나도 GPS 점은 싱글턴에 계속 쌓이고, 다시 `/walk` 에 들어오면 새 cubit 이 같은 세션을 이어
그린다. 그래서 `PopScope` 를 두지 않았다. 등록 타입이 인터페이스라 dispose 는 최상위 함수가
타입을 보고 부른다 — `WalkTracker` 에 `dispose` 를 늘리지 않았다.

### `states` 는 브로드캐스트 — cubit 이 구독 먼저, 현재값은 그다음

스펙 §2 는 "구독 즉시 현재값부터" 였지만 순수 브로드캐스트로 두고 `current` 를 따로 읽게 했다.
계획은 "`trackerState` 를 먼저 읽는다" 였는데 구현은 **구독을 먼저 걸고** 현재값을 읽는다 —
읽는 사이에 온 변화를 놓치지 않는 더 나은 순서다(리뷰 ⑤ 설계 대비). 재진입은 `tracking` →
바로 추적 화면, `finished` → `stopped` → 저장 폼이다. 저장 안 된 세션을 새 산책으로 덮지 않게
열린 질문 1 을 화면 수준에서 닫았다.

### `clear()` 는 `finished` 에서만 `idle`

`DiscardWalkScenario` 가 항상 `clear()` 를 불러 추적 중인 산책을 지울 수 있었다(리뷰 ① B2).
추적기가 `finished` 일 때만 `idle` 로 가고 그 밖에는 무시한다.

### 정책 수치

정확도 ≤ 50 m(null 통과) · 첫 점 외 이동 ≥ 2 m(`WalkTrackingPolicy`), 플랫폼 `distanceFilter` 3 m.
추적기가 `distanceBetween(직전 점, 새 점)` 을 먼저 재서 `accept` 에 넘기고, 받아들인 점 기준으로만
거리를 더한다. 첫 점도 정확도 검사를 받아 경로가 튀지 않는다. 스트림 오류는 `debugPrint` 만 하고
세션을 유지한다.

### 플랫폼 설정

| 플랫폼 | 설정 |
|---|---|
| Android | `AndroidSettings(accuracy: best, distanceFilter: 3, intervalDuration: 2s, foregroundNotificationConfig(title, text, enableWakeLock: true))` |
| iOS | `AppleSettings(accuracy: best, distanceFilter: 3, activityType: fitness, allowBackgroundLocationUpdates: true, showBackgroundLocationIndicator: true, pauseLocationUpdatesAutomatically: false)` |
| 그 밖 | `LocationSettings(accuracy: best, distanceFilter: 3)` |

알림 문구는 페이지가 l10n 으로 `TrackingNotice` 를 만들어 `start(notice)` 에 넘긴다 — cubit 은
로케일을 모른다. 권한은 통근 앱처럼 세션당 한 번만 요청한다(`_requestDeclined`).

### 종료는 `pushReplacement` 로 저장 폼에

`/walk/save` 는 최상위 경로라 `go` 는 스택을 `[/walk/save]` 하나로 바꿔 시스템 뒤로 가기가 앱을
닫는다(리뷰 V1). 진행 화면만 저장 폼으로 바꿔 끼워 피드가 아래에 남게 했다.

### 상태에 `loading` 을 더했다

계획 표에 없던 초기 상태다. `load()` 가 추적기와 반려견을 읽는 동안 필요하다. `starting` 도
`dogs` · `selectedIds` 를 들어 실패 시 그대로 `failure` 로 넘긴다.

### `retry()` 는 알림 문구를 기억한다

`start(notice)` 가 `_notice` 를 기억해, 선택이 남은 `failure` 의 재시도는 같은 문구로 다시
시작한다. 선택이 빈 `failure`(반려견 조회 · `stop` 실패)는 `load()` 로 추적 상태부터 다시 읽는다.
권한 거부면 `walkLocationDeniedHint` 를 함께 보인다 — 이번 세션에는 다시 묻지 않기 때문이다.

### 경과 시간은 다시 계산한다

`tracking` 일 때만 1초 `Timer.periodic` 이 `session.elapsedAt(now())` 를 다시 계산한다(틱 누적
금지). `stopped` · `failure` · `close()` 에서 취소하고, `stopped` 는 구독과 `stop()` 결과 중 먼저
온 쪽만 낸다.

## 리뷰에서 고친 것

| id | 내용 | 커밋 |
|---|---|---|
| D3 | `WalkTracker` 등록처가 없어 `WalkUseCase` 를 만들 수 없던 것을 실제 추적기를 앞당겨 해소 | `cdc1ac2` |
| B2 | `clear()` 가 `finished` 에서만 `idle` | `cdc1ac2` |
| T4 | 추적 중이 아닐 때 `stop` 의 실패 종류를 `validation` → `notFound(walkNotFound)` | `93d722b` |
| V1 | `onStopped` 를 `go` → `pushReplacement(saveWalk)` | `93d722b` |
| V2 | 0마리 안내에서 등록하고 돌아와도 그대로이던 것을 `getDogs()` 대신 `watchDogs()` 구독으로([feed 기록](../feed/history.md)) | `d5f95b0` |

## 고치지 않았지만 적어 둘 것

- **Android 정확도가 계획과 다르다** — 계획 `high`, 구현 `best` + 2초 간격. 배터리 차이라 실기기에서 정한다
- `walk-active-retry` 키는 `b4abf9c` 에서 붙였다(`AppPlaceholder.actionKey`). 페이지 테스트도
  문구 대신 그 키를 누른다
- `POST_NOTIFICATIONS` 런타임 요청을 하지 않는다(계획 · 스펙 §5 결정). Android 13+ 에서는 알림이
  기본 거부라 알림만 안 보이고 추적은 돈다 — 에뮬레이터 ③ 의 기대값을 이에 맞춰야 한다(리뷰 S5)
- **iOS 는 미검증** — 빌드도 기기 확인도 하지 않았다. SwiftPM · iOS 15 템플릿도 처음이다(리뷰 ③ I1)
- OSM 출처에 `©` 가 빠졌다(V5) · `CameraFit` 에 `maxZoom` 이 없다(⑤ I3) · `WalkFormat.duration` 은
  60분이면 `1시간 0분`, 1분 미만이면 `0분`(⑤ I2) · 크기에 여백 토큰(V3)
- 앱이 죽으면 진행 중 산책은 사라진다(점은 메모리에만) — 계획의 범위 밖
- **테스트 공백**: 추적기의 권한 await 뒤 경합 가드 · 요청 후 허용 경로 · `catch` → `unknown` ·
  `dispose`, `stop` 실패의 Failure **종류**(테스트는 코드만 본다), cubit 의 스트림으로 온 새 점
  (타이머 중복 없음), `stopped` 뒤 `pendingTimers`, 페이지의 서비스 꺼짐, `RouteMap` 추종 · `CameraFit`

## 검증

- `93d722b` 스냅숏에서 `feature_walk` `flutter analyze` 0건 · `flutter test` `+150`(W2 몫 39건 —
  추적기 12 · cubit 11 · 포맷 7 · 페이지 9), `apps/pawlog` `+5`
- 리뷰어가 `4627805` 를 따로 꺼내 `+104` · analyze 0건을 확인했다
- **에뮬레이터 확인은 아직 하지 않았다 (이 환경에 Android SDK 없음).** GPX 재생 · 백그라운드 30초 ·
  재진입 · 권한 거부는 [테스트](testing.md#에뮬레이터)에 미실행으로 남겼다. AGP 9 디버그 빌드도
  아직 돌리지 않았다
