# commute — 기록

> [문서 허브](../../README.md) · [계획](plan.md) · [설계](../../superpowers/specs/2026-09-13-commute-app-design.md) · [테스트](../../testing/features/commute.md)

설계 판단 · 막힌 것 · 검증 결과를 남긴다. 진행 상태는 [진행 현황](../../status.md)에만 적는다.

## 2026-09-13 — 설계 판단

### 둘째 앱은 기존 feature 를 하나도 쓰지 않는다

`apps/commute` 는 `core` · `design_system` · `l10n` 과 `feature_commute` 만 조립한다.
목적이 "통근 앱을 만드는 것"이 아니라 **"둘째 앱이 기반 패키지만으로 서는가"를
보는 것**이라서다. 만들며 불편했던 것은 고치지 않고
[설계 §7](../../superpowers/specs/2026-09-13-commute-app-design.md#7-리팩터링-후보--이-앱을-만들며-확인된-것)
에 쌓았다. 허용한 기존 패키지 변경은 `FailureCode` 5개 · ARB 문자열 · 루트
workspace 목록뿐이다.

### feature 는 go_router 를 모른다

기존 feature 들은 `core` 의 `Routes` 를 직접 써서 `context.push` 한다. 이 앱은
페이지가 콜백(`onOpenSettings` · `onDone`)을 받고 경로는 `apps/commute` 의 라우터가
정한다. `feature_commute` 의 pubspec 에 `go_router` 가 없고
`package_boundary_test` 가 그것을 지킨다. 어느 쪽이 나은지는 리팩터링에서 판단한다
(§7 후보 2 · 9).

### 위치 실패는 정상 분기다

권한 거부 · 서비스 꺼짐 · 타임아웃 전부 `Err` 로 돌아오지만 `SearchCommuteScenario`
는 이를 오류로 올리지 않고 출발 쪽 역으로 `Origin.fallbackStation` 을 만든다. 홈은
결과를 보여주고 배너로 출처만 알린다. `Origin` 을 sealed 로 둔 이유가 이것이다 —
bool 로 들고 다니면 배너가 "왜 역 기준인가"를 잃는다.

### `geolocator` 는 `LocationGateway` 뒤에 둔다

`Geolocator` 는 static 메서드라 mock 하기 어렵다. 플랫폼 호출 4개
(`isLocationServiceEnabled` · `checkPermission` · `requestPermission` ·
`getCurrentPosition`)를 얇은 인터페이스로 감싸 `GeolocatorLocationRepository` 는
그것만 본다. 실패 종류별 `FailureCode` 매핑을 전부 단위 테스트로 덮을 수 있다.

### 설정은 역 id 만 저장한다

`shared_preferences` 에 좌표를 넣지 않는다. 역 목록(`stations.json`)을 공공데이터
전체로 바꿔도 설정이 깨지지 않게 하려는 것이다. 복원은 `StationRepository.findById`
로 하고, 목록에서 사라진 id 는 null 로 떨어져 설정 화면이 다시 고르게 한다.

### 가짜 경로는 결정적이어야 한다

`FakeTransitRouteRepository` 는 haversine 거리 하나로 소요 · 환승 · 구간을 만든다.
난수를 쓰면 "역 쌍이 다르면 숫자도 달라진다"를 테스트로 잡을 수 없다. 구간의 분
합이 전체 소요와 같도록 `_split` 이 나머지를 앞에서부터 분배한다.

### 라우터는 cubit 을 구독하지 않는다

설정 미완성 리다이렉트는 부팅 때 `getSettings()` 를 한 번 읽어 `SettingsRedirect`
에 담고, 설정 페이지의 `onDone` 이 `markComplete()` 를 부른다. 화면이 둘뿐이라
라우터가 상태 스트림을 듣는 구조는 과하다.

## 2026-09-13 — 에뮬레이터 확인

`Medium_Phone` AVD(Android 17)에서 6단계의 4가지 시나리오를 돌렸다. 첫 실행 → 설정
리다이렉트, 역 부분 검색 · 선택 → 홈 이동, 카드 3장과 방향 토글, 위치 거부 시
집/회사 기준 배너와 결과 표시는 모두 설계대로였고 다크 모드 · 가로 회전 · 백그라운드
복귀 · 콜드 재실행에서도 문제가 없었다. 두 가지가 어긋나 고쳤다(`d1c7d8e`).

### 권한 거부 뒤 시스템 다이얼로그가 반복해서 떴다

Android 는 사용자가 한 번 거부해도 `checkPermission` 이 여전히 `denied` 를 돌려준다.
저장소가 `denied` 면 매번 `requestPermission` 을 불렀으므로 방향 토글 · 새로고침 ·
설정 복귀 때마다 시스템 권한 다이얼로그가 다시 떴다.

`GeolocatorLocationRepository` 가 **세션 안에서 거부를 기억한다**(`_requestDeclined`).
두 번째부터는 묻지 않고 바로 `locationPermissionDenied` → fallback 으로 보낸다.
사용자가 시스템 설정에서 허용하면 `checkPermission` 이 `whileInUse` 를 돌려주므로
다시 묻지 않고도 위치를 쓴다. `const` 생성자를 뗐고, 거부는 정상 분기이므로 조용히
처리한다. 앱을 다시 켜면 한 번은 다시 묻는다 — 영구 저장이 아니라 의도한 범위다.

### 역을 바꾸고 돌아와도 이전 결과가 남았다

홈 → 설정 → 집 역 변경 → 뒤로 가기를 하면 홈이 이전 역의 카드를 그대로 보여줬다.
`onOpenSettings` 가 `VoidCallback` 이라 홈이 설정이 닫힌 시점을 알 수 없었다.

`OpenSettingsCallback = Future<void> Function()` 으로 바꿨다. 앱은 `context.push` 가
돌려주는 Future 를 그대로 넘기고, 홈은 그것이 완료되면 `cubit.refresh()` 한다.
`isClosed` 로 가드해 홈이 이미 내려간 뒤에는 emit 하지 않는다. 트레이더 앱이 같은
문제를 `RouteObserver(didPopNext)` 로 푼 것과 대조되는 지점이다(§7 후보 9).

### 릴리즈 APK 로 확인했다

에뮬레이터의 `/data` 가 차서 162 MB 짜리 디버그 APK 가 설치되지 않았다. 릴리즈
arm64 APK 를 만들어 설치해 확인했다. 릴리즈라 hot reload 없이 고칠 때마다
재설치했다. 이 앱의 디버그 전용 설정(`android/app/src/debug/`)은 `flutter create`
가 만든 `INTERNET` 권한뿐이고 앱이 네트워크를 쓰지 않으므로 동작 차이는 없다.

### 고치지 않았지만 적어 둘 것

- 영어 `commuteTransferCount` 가 ICU plural 이 아니라 `"{count} transfers"` 라
  "1 transfers" 로 나온다. 기존 ARB 에 개수 문자열의 plural 규약이 없어 그대로 따랐다
  (§7 후보 7)
- `FakeTransitRouteRepository` 의 구간 라벨(`도보` · `2호선` · `146번`)이 한국어
  고정값이다. 가짜 구현이 만드는 데이터라 ARB 로 옮기지 않았다 — 실제 API 로
  바꾸면 API 가 주는 이름을 그대로 쓴다
- `OriginBanner` 는 `design_system` 에 배너 위젯이 없어 `Container` + `colorScheme` +
  `AppRadius` 로 직접 만들었다 (§7 후보 8)

### 검증

`flutter analyze` 0 · `melos run test` 전체 통과 · `apps/commute` 와 `apps/trader`
둘 다 APK 빌드 · 에뮬레이터 4 시나리오 통과.
