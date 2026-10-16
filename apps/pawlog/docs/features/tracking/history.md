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

## 2026-10-04 — 에뮬레이터 QA

Android 17 에뮬레이터(`Medium_Phone`)에서 [테스트](testing.md#에뮬레이터)의 시나리오를 돌리며 찾은 것을 고쳤다.

### `WAKE_LOCK` 권한 (`1b97e83`)

`ForegroundNotificationConfig(enableWakeLock: true)` 인데 매니페스트에 `WAKE_LOCK` 이 없어 위치
스트림을 여는 순간 `SecurityException` 이 났고 점이 하나도 들어오지 않았다. 권한을 선언했다.
mock 테스트로는 드러나지 않는 종류다.

### 지도마다 새 `TileProvider` (`e0594d9`)

`TileProvider` 를 `lazySingleton` 으로 등록했는데 flutter_map 8.3 의 `TileLayer` 는 사라질 때
`tileProvider.dispose()` 를 부르고, `NetworkTileProvider` 는 그때 스스로 만든 http client 를 닫는다.
첫 지도가 닫힌 뒤의 지도 — 진행 화면 재진입, 산책 상세([record](../record/history.md)) — 가 모두
회색이었다. `@injectable`(factory)로 바꾸고, `RouteMap` 은 `State` 에서 한 번만 받아 다시 그려도
바꾸지 않는다(바뀐 provider 는 `TileLayer` 가 dispose 하지 않는다). 테스트의 `RouteMap.tileProvider`
· `getIt` stub 자리는 그대로다.

### 스트림 오류를 화면에 (`0c1c07b`)

"정책 수치" 의 "스트림 오류는 `debugPrint` 만" 을 바꿨다. 오류가 나도 산책은 끊지 않되
`TrackerState.tracking(session, locationError:)` 에 싣는다 — `LocationServiceDisabledException` →
`locationServiceDisabled`, `PermissionDeniedException` → `locationPermissionDenied`, 그 밖은 새
`FailureCode.locationStreamFailed`(ARB 3개에 `failureLocationStreamFailed`). 다음 위치가 들어오면
(정책이 버린 점이라도) 지운다. 추적기에 `resume()` 을 두어 세션을 지킨 채 위치 확인과 구독을 다시
하고, 진행 화면은 오류를 `AppPlaceholder` + 다시 시도(`resumeTracking`)로 보인다. 점이 없으면 지도
자리에, 경로가 있으면 지도 아래에 두고 종료 버튼은 늘 남긴다. `location` 패키지가 두 예외를 함께
내보낸다.

### 설정 열기 (`2d6fc8b`)

권한 거부 안내가 "설정에서 허용한 뒤 다시 시도" 라면서 다시 시도만 있었고, 권한은 세션당 한 번만
묻기 때문에 다시 시도로는 풀리지 않았다. 권한 거부는 "설정 열기"(`LocationAccess.permission.openSettings`),
서비스 꺼짐은 "위치 설정 열기" 를 다시 시도 아래 `AppButton.text` 로 둔다. 서비스 꺼짐을 위해
`location` 게이트웨이에 `openLocationSettings`(geolocator 의 같은 이름)를 더하고 `LocationAccess` 가
넘긴다. `WalkTracker` · `WalkUseCase` 에 `openAppSettings` · `openLocationSettings`, cubit 은
`openSettings(failure)` 로 고른다. 시작 실패와 추적 중 위치 오류가 같은 위젯(`_LocationProblem`)을 쓴다.
`AppPlaceholder` 는 행동이 하나라 feature 안에서 감쌌다.

## 검증

- `93d722b` 스냅숏에서 `feature_walk` `flutter analyze` 0건 · `flutter test` `+150`(W2 몫 39건 —
  추적기 12 · cubit 11 · 포맷 7 · 페이지 9), `apps/pawlog` `+5`
- 리뷰어가 `4627805` 를 따로 꺼내 `+104` · analyze 0건을 확인했다
- **에뮬레이터 확인은 아직 하지 않았다 (이 환경에 Android SDK 없음).** GPX 재생 · 백그라운드 30초 ·
  재진입 · 권한 거부는 [테스트](testing.md#에뮬레이터)에 미실행으로 남겼다. AGP 9 디버그 빌드도
  아직 돌리지 않았다

## 2026-10-17 — 알림 권한 요청

**무엇** — 산책을 시작할 때(`GeolocatorWalkTracker.start`) 위치 확인을 통과한 뒤, 구독하기 전에 알림
권한을 묻는다. `permission_handler` 의 `Permission.notification` 을 `PermissionSource` 로 바꾸는
`NotificationPermissionSource`(`lib/data/tracking/`, walk 앱의 상태 매핑을 옮겨 왔다)를 두고,
`RegisterModule` 이 `@Named('notificationPermission')` `PermissionRequester` 싱글턴으로 등록해 추적기
네 번째 인자로 넘긴다.

**왜** — 매니페스트에 `POST_NOTIFICATIONS` 를 선언만 하고 요청하지 않아 Android 13+ 에서는 "산책 중"
포그라운드 알림이 기본으로 숨었다. [구현 리뷰](../../audits/2026-10-03-implementation-review.md) S5 로
남아 있던 일이다.

**동작** — 앱 세션당 한 번만 묻는다. 기억은 `PermissionRequester` 가 가진다(거부하면 같은 세션의 다음
`start` 는 묻지 않는다). 결과는 산책을 막지 않는다 — 허용 · 거부 · 영구 거부 모두 그대로 추적하고, 확인 ·
요청이 던지면 `debugPrint` 만 남긴다. 위치 확인이 실패하면 묻지 않고, 화면 밖에서 도는 `restore()` 와
위치 오류 뒤 `resume()` 은 묻지 않는다. Android 12 이하 · iOS 는 `permission_handler` 가 허용으로 답해
따로 할 일이 없다.
