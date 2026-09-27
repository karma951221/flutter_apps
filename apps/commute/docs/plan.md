# commute — 계획 (통근 시간, 둘째 앱)

> [통근 허브](README.md) · [설계](../../../docs/superpowers/specs/2026-09-13-commute-app-design.md) · [의존 그래프](../../../docs/dependencies.md) · [아키텍처](../../../docs/architecture.md) · [개발환경](../../../docs/setup.md) · [테스트](testing.md) · [기록](history.md)

> 상태: **완료** · 작성 2026-09-13 · 검증 2026-09-13
> 진행 상태의 단일 기준은 [진행 현황](status.md)이다.

## 목적

`apps/commute` 는 트레이더와 무관한 **둘째 앱**이다. 집·회사를 지하철역으로 등록해
두고 출근/퇴근 방향으로 지하철 · 버스 · 최적 세 가지 소요 시간을 보여준다. 로그인
없음, 외부 API 없음, Supabase 없음.

숨은 목적은 **`packages/` 의 경계를 시험하는 것**이다. 그래서 기존 패키지 중
`core` · `design_system` · `l10n` 만 쓰고 `feature_*` 는 하나도 쓰지 않는다. 만들며
부딪힌 불편은 고치지 않고 [설계 §7](../../../docs/superpowers/specs/2026-09-13-commute-app-design.md#7-리팩터링-후보--이-앱을-만들며-확인된-것)
표에 쌓아 두었고, 그 목록이 다음 리팩터링의 입력이다.

설계의 단일 기준은 [설계 문서](../../../docs/superpowers/specs/2026-09-13-commute-app-design.md)다.
이 문서는 그것을 요약하고 구현이 실제로 어떤 모양인지 적는다.

## 화면

| 화면 | 경로 | 내용 |
|---|---|---|
| 홈 `CommuteHomePage` | `/` | 상단 출근 ↔ 퇴근 토글(`DirectionToggle`), 출발지 배너(`OriginBanner`), 카드 3장(`TransitRouteCard` — 지하철 · 버스 · 최적, 각각 소요 분 · 환승 횟수 · 한 줄 경로). pull-to-refresh. AppBar 액션 → 설정 |
| 설정 `CommuteSettingsPage` | `/settings` | 집 역 · 회사 역 `AppListTile` 두 줄. 탭 → 역 검색 시트. 저장은 선택 즉시. 둘 다 채워지는 순간 `onDone` 을 한 번 부른다 |
| 역 검색 시트 `StationSearchSheet` | (모달) | 텍스트 필드로 부분 일치 검색, 결과 행에 노선 표기. 선택한 `Station` 을 `pop` 으로 돌려준다 |

- 앱 시작 시 집 · 회사 중 하나라도 비어 있으면 홈 대신 `/settings` 로 리다이렉트한다
  (`SettingsRedirect`). 부팅 때 `CommuteUseCase.getSettings()` 를 한 번 읽어 결정하고,
  설정 페이지가 완성되면 `markComplete()` 후 홈으로 보낸다. 라우터는 cubit 을
  구독하지 않는다.
- 홈의 로딩 · 오류(재시도) · 미설정(설정하기)은 `AppPlaceholder` 다. 미설정은
  `FailureCode.commuteNotConfigured` 로 구분한다.

### 출발지 결정 규칙

1. `LocationRepository.currentLocation(timeout: 5s)`
2. 성공 → `Origin.currentLocation(point)` → 배너 "현 위치 기준"
3. 실패(권한 거부 · 서비스 꺼짐 · 타임아웃 · 기타) → `Origin.fallbackStation(출발 쪽 역)`.
   toWork 면 집, toHome 이면 회사 → 배너 "집 기준 · 위치를 못 가져왔어요"(퇴근이면
   "회사 기준")

**위치 실패는 오류가 아니라 정상 분기다.** 홈은 결과를 보여주고 배너로 출처만 알린다.

### 의도적으로 없는 것

로그인 · 출발 알림 · 실시간 도착 정보 · 지도 · 경로 상세 · 즐겨찾기 · 최근 검색.

## 도메인 (`packages/features/commute/lib/src/domain/`)

엔티티는 Freezed 단일 모델(Primary Constructor)이고 `Origin` 만 sealed 다 — 홈 배너가
출처를 구분해야 하는데 bool 로 들고 다니면 흐려진다.

| 이름 | 역할 |
|---|---|
| `GeoPoint` · `Station` · `CommuteSettings` | 좌표 · 역(id · 이름 · 노선 · 좌표) · 집/회사 설정(`isComplete`) |
| `CommuteDirection` · `TransitMode` · `TransitLegKind` | enum — 방향 · 카드 모드 · 구간 종류 |
| `Origin` | sealed — `currentLocation(point)` / `fallbackStation(station)` |
| `TransitLeg` · `TransitRoute` · `CommuteResult` | 구간 · 경로(모드 · 소요 · 환승 · 구간들) · 검색 결과(방향 · 출발지 · 목적지 · 경로 3개 · 시각) |

인터페이스 4개는 나중에 갈아끼우는 자리다: `TransitRouteRepository` ·
`LocationRepository` · `StationRepository` · `CommuteSettingsRepository`.

`CommuteUseCase` facade 하나를 presentation 이 주입받고(`DefaultCommuteUseCase`),
시나리오 4개가 동작을 나눈다 — `GetCommuteSettings` · `SaveCommuteSettings` ·
`SearchStations` · `SearchCommute`. 핵심은 `SearchCommuteScenario` 다:

1. 설정 로드 → `isComplete` 가 아니면 `Err(commuteNotConfigured)`
2. 방향으로 목적지 · 출발 쪽 역 결정
3. 출발지 결정 규칙 적용
4. `TransitRouteRepository.search` → `CommuteResult`. 실패는 그대로 전파

`FailureCode` 5개를 `core` 에 더했다 — `commuteNotConfigured` ·
`locationPermissionDenied` · `locationServiceDisabled` · `locationTimeout` ·
`routeSearchFailed`. `l10n` 의 switch 가 exhaustive 라 ARB 3개에 문자열도 함께 넣었다.

## 데이터 (`data/`)

| 인터페이스 | 구현 | 비고 |
|---|---|---|
| `TransitRouteRepository` | `FakeTransitRouteRepository` | 외부 호출 없이 haversine 거리로 **결정적** 계산. 모드별 공식과 환승 규칙은 [설계 §3](../../../docs/superpowers/specs/2026-09-13-commute-app-design.md#3-데이터-구현-data). 순서는 subway · bus · best, 항상 `Ok` |
| `StationRepository` | `AssetStationRepository` | `assets/stations.json` 30개(장승배기 · 강남 포함, 1~9호선 환승역 위주)를 한 번만 읽어 캐시. 공백 제거 · 대소문자 무시 부분 일치, 빈 질의는 빈 목록 |
| `CommuteSettingsRepository` | `PrefsCommuteSettingsRepository` | `shared_preferences` 에 **역 id 만** 저장(`commute.home_station_id` · `commute.work_station_id`). `load` 는 `StationRepository.findById` 로 복원, 없는 id 는 null |
| `LocationRepository` | `GeolocatorLocationRepository` | `geolocator` 호출은 `LocationGateway` 인터페이스(`GeolocatorGateway`)로 감싸 테스트에서 mock 한다. 서비스 꺼짐 · 거부 · 타임아웃 · 기타를 `FailureCode` 로 구분하고 예외를 밖으로 던지지 않는다. **세션 안에서 한 번 거부하면 다시 묻지 않는다** ([기록](history.md)) |

## Presentation (`presentation/`)

| Cubit | State (sealed) | 동작 |
|---|---|---|
| `CommuteHomeCubit` | `initial(direction)` / `loading(direction)` / `loaded(direction, result)` / `failure(direction, failure)` | `load()` · `setDirection(d)`(즉시 재검색) · `refresh()`. generation 카운터로 늦은 응답을 버린다 |
| `CommuteSettingsCubit` | `loading` / `loaded(settings)` / `failure(failure)` | `load()` · `setHome(station)` · `setWork(station)` — 저장 후 `loaded` 갱신 |
| `StationSearchCubit` | `idle` / `searching(query)` / `results(query, stations)` / `failure(failure)` | `search(query)` — 300ms 디바운스, 빈 질의는 `idle` |

`direction` 을 홈의 모든 상태에 두는 이유: 로딩 · 실패 중에도 토글이 현재 방향을
보여야 한다.

페이지 · 위젯: `CommuteHomePage` · `CommuteSettingsPage` · `DirectionToggle` ·
`OriginBanner` · `TransitRouteCard` · `StationSearchSheet` · `CommuteFormat`
(`Duration → "42분"`, `legs → "도보 → 2호선 → 도보"`, 모드 라벨).

**feature 는 go_router 를 모른다.** 이동은 콜백으로 받고 경로는 앱이 정한다:

- `CommuteHomePage({required OpenSettingsCallback onOpenSettings})` —
  `typedef OpenSettingsCallback = Future<void> Function()`. 설정이 닫힐 때 완료되는
  Future 를 돌려받아 홈이 그때 다시 검색한다. 앱은 `context.push` 의 Future 를 그대로
  넘긴다
- `CommuteSettingsPage({VoidCallback? onDone})`

기존 feature 들이 `core` 의 `Routes` 를 직접 쓰는 것과 다른 선택이고, 이 앱에서
대조 실험한 것이다. 문자열은 공유 `l10n` 의 ARB 3개에 `commute` 접두어로 넣었다.

## DI · 앱 셸

- `feature_commute` 는 `@InjectableInit.microPackage` 로 `FeatureCommutePackageModule`
  을 만든다. 저장소 4개 · `CommuteUseCase` 는 lazySingleton, cubit 3개는 factory.
  `SharedPreferences` 는 `CorePackageModule` 이 `@preResolve` 로 준다
- `apps/commute/lib/di/injection.dart` 가 `externalPackageModulesBefore: [Core, FeatureCommute]`
  로 조립한다. `bootstrap` 은 `ensureInitialized → configureDependencies → runApp` 뿐이고
  Supabase 초기화가 없다
- `CommuteApp` 은 `MaterialApp.router` + `AppTheme.light/dark` + `ThemeMode.system` +
  `AppLocalizations`. 라우터는 `/` · `/settings` 둘이고 `SettingsRedirect` 가 미설정을
  막는다
- 플랫폼 권한: Android `ACCESS_FINE_LOCATION` · `ACCESS_COARSE_LOCATION`, iOS
  `NSLocationWhenInUseUsageDescription`

`feature_commute` 의 pubspec 에 허용되는 것은 `core` · `design_system` · `l10n` 과
서드파티(`flutter_bloc` · `freezed_annotation` · `injectable` · `json_annotation` ·
`shared_preferences` · `geolocator` · `intl`)뿐이다. `feature_*` · `supabase_flutter` ·
`go_router` 는 금지이고 `apps/commute/test/convention/package_boundary_test.dart` 가
검사한다.

## 완료 조건

- [x] `melos run analyze` · `melos run test` 전부 통과. `apps/commute` 와 `apps/trader`
      둘 다 `flutter build apk` 로 빌드된다
- [x] `packages/features/commute/pubspec.yaml` 에 `feature_` · `supabase_flutter` ·
      `go_router` 가 없다 (`package_boundary_test` 통과)
- [x] `grep -r "go_router\|package:feature_" packages/features/commute/lib` 가 비어 있다
- [x] 에뮬레이터에서 4가지 시나리오 확인 — ① 첫 실행이 설정으로 간다 ② 역 부분
      검색 · 선택이 된다 ③ 홈에 카드 3장이 뜬다 ④ 위치 권한을 거부하면 "집 기준"
      배너와 함께 결과가 나온다 ([테스트](testing.md))
- [x] 설계 §7 에 작업 중 발견한 항목이 추가돼 있다 (7 · 8 · 9)
- [x] `documentation_links_test` 통과

## 테스트

단위 · 위젯 · 라우터 · 경계 검사는 [테스트 문서](testing.md)에
있다. Supabase 가 없으므로 RLS 검증 스크립트는 없다.

## 범위 밖

실제 경로 API(ODsay 등) 연동 · 공공데이터 전체 역 목록 · 출발 알림 · 실시간 도착 ·
지도 · 경로 상세. `TransitRouteRepository` · `StationRepository` 의 구현만 갈아끼우면
되도록 인터페이스 자리만 두었다.
