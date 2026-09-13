# 통근 앱(commute) 설계 — 둘째 앱으로 패키지 경계를 시험한다

> 2026-09-13 작성 · 브랜치 `feat/monorepo` 위에서 진행 · Codex 실행 프롬프트는
> [2026-09-13-commute-app-codex-prompt.md](2026-09-13-commute-app-codex-prompt.md)

## 0. 왜 만드는가

모노레포 전환([2026-09-12-monorepo-codex-prompt.md](2026-09-12-monorepo-codex-prompt.md))은
끝났지만 `packages/features/*`는 서로 얽혀 있고, `core`·`l10n`도 트레이더 앱 지식을
품고 있다. 어디를 끊어야 하는지는 **둘째 앱을 실제로 조립해 봐야** 안다.
그래서 순서는 ① 통근 앱을 만든다 → ② 만들면서 부딪힌 것을 목록으로 쌓는다 →
③ 그 목록으로 `packages/`를 리팩터링한다. 이 문서는 ①의 설계이고 §7이 ②의 목록이다.

통근 앱은 기존 패키지 중 **`core` · `design_system` · `l10n`만** 쓴다. feature 패키지는
하나도 쓰지 않는다. 로그인 없음.

## 1. 범위와 화면

집·회사를 지하철역으로 등록해 두고, 출근/퇴근 방향으로 **지하철 / 버스 / 최적** 세
가지 소요 시간을 보여준다. 출발지는 GPS, 못 잡으면 출발 쪽 역.

### 홈 (`/`)

- 상단: 출근 ↔ 퇴근 토글. 출발지 배너 — "현 위치 기준" 또는 "집 기준 · 위치를 못
  가져왔어요"(퇴근이면 "회사 기준")
- 본문: 카드 3장 — 🚇 지하철 / 🚌 버스 / ⭐ 최적. 각각 소요 시간(분), 환승 횟수,
  한 줄 경로 요약("도보 → 2호선 → 9호선 → 도보")
- 로딩·오류(재시도)·미설정은 `AppPlaceholder`. pull-to-refresh
- AppBar 액션: 설정

### 설정 (`/settings`)

- 항목 2개: 집 역 / 회사 역 (`AppListTile`). 탭 → 역 검색 시트
- 저장은 선택 즉시. 둘 다 채워지면 홈으로 돌아갈 수 있다
- 앱 시작 시 둘 중 하나라도 비어 있으면 홈 대신 여기로 리다이렉트

### 역 검색 시트

- 텍스트 필드로 이름 필터(부분 일치), 결과 목록에서 선택. 노선 표기
- 역 목록은 패키지 내장 JSON(수도권 주요 역 수십 개). 전체 목록은 나중에 교체

### 출발지 결정 규칙

1. `LocationRepository.currentLocation(timeout: 5s)`
2. 성공 → `Origin.currentLocation(point)`
3. 실패(권한 거부·서비스 꺼짐·타임아웃·기타) → `Origin.fallbackStation(출발 쪽 역)`.
   toWork면 집, toHome이면 회사. **위치 실패는 오류가 아니라 정상 분기다** — 홈은
   결과를 보여주고 배너로 출처만 알린다

### 의도적으로 없는 것

로그인, 출발 알림, 실시간 도착 정보, 지도, 경로 상세 화면, 즐겨찾기, 최근 검색.

## 2. 도메인

### 엔티티 (`domain/entity/`, Freezed 단일 모델 — Primary Constructor)

| 이름 | 필드 |
|---|---|
| `GeoPoint` | `lat`, `lng` |
| `Station` | `id`, `name`, `lines: List<String>`, `location: GeoPoint` |
| `CommuteSettings` | `home: Station?`, `work: Station?` · `bool get isComplete` |
| `CommuteDirection` | enum `toWork`, `toHome` |
| `Origin` | sealed · `currentLocation(GeoPoint point)` / `fallbackStation(Station station)` |
| `TransitMode` | enum `subway`, `bus`, `best` |
| `TransitLegKind` | enum `walk`, `subway`, `bus` |
| `TransitLeg` | `kind`, `label`("2호선"·"146번"·"도보"), `minutes` |
| `TransitRoute` | `mode`, `duration: Duration`, `transferCount`, `legs: List<TransitLeg>` |
| `CommuteResult` | `direction`, `origin`, `destination: Station`, `routes: List<TransitRoute>`, `searchedAt: DateTime` |

`Origin`을 sealed로 두는 이유: 홈 배너가 출처를 구분해야 하는데 bool로 들고 다니면
흐려진다. 한 줄 요약은 엔티티가 아니라 presentation `CommuteFormat`이 `legs`에서 만든다.

### 인터페이스 (`domain/repository/`) — 나중에 갈아끼우는 자리

```dart
abstract interface class TransitRouteRepository {
  Future<Result<List<TransitRoute>>> search({
    required GeoPoint origin,
    required GeoPoint destination,
  });
}

abstract interface class LocationRepository {
  Future<Result<GeoPoint>> currentLocation({Duration timeout});
}

abstract interface class StationRepository {
  Future<Result<List<Station>>> search(String query);
  Future<Result<Station?>> findById(String id);
}

abstract interface class CommuteSettingsRepository {
  Future<Result<CommuteSettings>> load();
  Future<Result<void>> save(CommuteSettings settings);
}
```

### Usecase facade + 시나리오 (`domain/usecase/`)

```dart
abstract interface class CommuteUseCase {
  Future<Result<CommuteSettings>> getSettings();
  Future<Result<void>> saveSettings(CommuteSettings settings);
  Future<Result<List<Station>>> searchStations(String query);
  Future<Result<CommuteResult>> searchCommute(CommuteDirection direction);
}
```

시나리오: `GetCommuteSettingsScenario`, `SaveCommuteSettingsScenario`,
`SearchStationsScenario`, `SearchCommuteScenario`. 핵심은 마지막 하나:

1. 설정 로드 → `isComplete`가 아니면 `Err(commuteNotConfigured)`
2. 방향으로 목적지·출발 쪽 역 결정
3. 출발지 결정 규칙(§1) 적용
4. `TransitRouteRepository.search` → `CommuteResult`. 실패는 그대로 전파

### 실패 코드

`core`의 `FailureCode`에 추가: `commuteNotConfigured`, `locationPermissionDenied`,
`locationServiceDisabled`, `locationTimeout`, `routeSearchFailed`. `l10n`의
`FailureLocalizations` switch가 exhaustive라 ARB 3개(ko·en·ja)에 문자열도 함께 넣는다.
(→ §7 후보 4)

## 3. 데이터 구현 (`data/`)

| 인터페이스 | 지금 | 나중 |
|---|---|---|
| `TransitRouteRepository` | `FakeTransitRouteRepository` | ODsay 등 무료 대중교통 API |
| `LocationRepository` | `GeolocatorLocationRepository` (`geolocator`) | — |
| `StationRepository` | `AssetStationRepository` (`assets/stations.json`) | 공공데이터 전체 역 |
| `CommuteSettingsRepository` | `PrefsCommuteSettingsRepository` (`shared_preferences`) | — |

### FakeTransitRouteRepository

외부 호출 없이 **결정적**으로 계산한다. 역 쌍이 다르면 숫자도 달라져야 한다.
`d` = haversine 거리(km).

| 모드 | 소요(분, 반올림) | 환승 | legs |
|---|---|---|---|
| subway | `8 + 3.0·d` | `d<4 → 0`, `d<10 → 1`, 그 외 2 | 도보 4 → 지하철(환승 수+1개, 균등 분배) → 도보 4 |
| bus | `5 + 4.5·d` | `d<6 → 0`, 그 외 1 | 도보 3 → 버스(…) → 도보 3 |
| best | `6 + 2.7·d` | 1 | 도보 3 → 버스 → 지하철 → 도보 3 |

지하철 leg 라벨은 `"2호선"`, `"9호선"`처럼 임의 고정값, 버스는 `"146번"` 같은 고정값.
반환 순서는 subway, bus, best. 항상 `Ok`.

### GeolocatorLocationRepository

`Geolocator.isLocationServiceEnabled` → `checkPermission`/`requestPermission` →
`getCurrentPosition(timeLimit)`. 각 실패를 `Failure`로 구분:
서비스 꺼짐 → `locationServiceDisabled`, 거부/영구 거부 → `locationPermissionDenied`,
`TimeoutException` → `locationTimeout`, 기타 → `UnknownFailure`.
예외를 밖으로 던지지 않는다.

### AssetStationRepository

`rootBundle.loadString('packages/feature_commute/assets/stations.json')`을 한 번만 읽어
캐시. `search`는 공백 제거 후 부분 일치(대소문자 무시), 빈 질의는 빈 목록.
JSON 형식:

```json
[{"id": "0222", "name": "강남", "lines": ["2", "신분당"], "lat": 37.4979, "lng": 127.0276}]
```

초기 목록은 수도권 주요 역 30개 내외. **장승배기·강남은 반드시 포함**, 1~9호선
주요 환승역 위주.

### PrefsCommuteSettingsRepository

키 `commute.home_station_id`, `commute.work_station_id`에 역 id만 저장.
`load`는 id → `StationRepository.findById`로 복원(없는 id는 null 처리). **좌표는
저장하지 않는다** — 역 목록을 교체해도 설정이 깨지지 않게.

## 4. Presentation

### Cubit

| Cubit | State (sealed) | 동작 |
|---|---|---|
| `CommuteHomeCubit` | `initial(direction)` / `loading(direction)` / `loaded(direction, result)` / `failure(direction, failure)` | `load()`, `setDirection(d)`(즉시 재검색), `refresh()` |
| `CommuteSettingsCubit` | `loading` / `loaded(settings)` / `failure(failure)` | `load()`, `setHome(station)`, `setWork(station)` — 저장 후 `loaded` 갱신 |
| `StationSearchCubit` | `idle` / `searching(query)` / `results(query, stations)` / `failure(failure)` | `search(query)` — 300ms 디바운스 |

`direction`을 모든 홈 상태에 두는 이유: 로딩·실패 중에도 토글이 현재 방향을 보여야
한다.

### 페이지·위젯

- `CommuteHomePage({required VoidCallback onOpenSettings})`
- `CommuteSettingsPage({VoidCallback? onDone})`
- `DirectionToggle`, `OriginBanner`, `TransitRouteCard`, `StationSearchSheet`
  (`showModalBottomSheet`, 선택한 `Station`을 반환)
- `CommuteFormat` — `Duration → "42분"`, `legs → "도보 → 2호선 → 도보"`, 모드 라벨

**feature는 go_router를 모른다.** 이동은 콜백으로 받고 경로는 앱이 정한다. 기존
feature들이 `core`의 `Routes`를 직접 쓰는 것과 다른 선택이며, 이 앱에서 시험한다.

UI 규칙은 [CLAUDE.md](../../../CLAUDE.md)를 따른다 — `AppButton`·`AppListTile`·
`AppPlaceholder`·`AppSnackBar`, 토큰은 `AppColors`·`AppSpacing`·`AppRadius`.

### 문자열

공유 `l10n`의 `app_ko.arb`·`app_en.arb`·`app_ja.arb`에 `commute` 접두어로 추가.
`arb_description_convention_test`가 요구하는 `@key.description`을 채운다. (→ §7 후보 3)

## 5. DI · 앱 셸

### `feature_commute` micro module

`lib/src/di/feature_commute.dart`(`@InjectableInit.microPackage`) →
`feature_commute.module.dart` 생성. 등록:

- `TransitRouteRepository → FakeTransitRouteRepository` (lazySingleton)
- `LocationRepository → GeolocatorLocationRepository` (lazySingleton)
- `StationRepository → AssetStationRepository` (lazySingleton)
- `CommuteSettingsRepository → PrefsCommuteSettingsRepository(SharedPreferences, StationRepository)` (lazySingleton)
- `CommuteUseCase → DefaultCommuteUseCase` (lazySingleton)
- Cubit 3개 (factory)

`SharedPreferences`는 `CorePackageModule`이 `@preResolve`로 준다.

### `apps/commute`

```
apps/commute/
├── pubspec.yaml         # core, design_system, l10n, feature_commute + flutter_bloc, go_router, injectable, get_it, flutter_localizations
├── lib/
│   ├── main.dart
│   ├── bootstrap.dart   # ensureInitialized → configureDependencies → runApp. Supabase.initialize 없음
│   ├── app/
│   │   ├── app.dart     # CommuteApp: MaterialApp.router, AppTheme.light/dark, themeMode: system, AppLocalizations
│   │   └── router/
│   │       ├── app_router.dart      # '/' → CommuteHomePage, '/settings' → CommuteSettingsPage
│   │       └── settings_redirect.dart  # 설정 미완성이면 '/settings'
│   └── di/injection.dart            # externalPackageModulesBefore: [Core, FeatureCommute]
├── android/ ios/        # flutter create 산출물. 위치 권한 선언
└── test/
```

리다이렉트는 부팅 시 `CommuteUseCase.getSettings()`를 한 번 읽어 결정하고, 설정 페이지에서
완성되면 홈으로 보낸다. 라우터가 Cubit을 구독하지 않는다(단순하게).

플랫폼 권한: Android `ACCESS_FINE_LOCATION`·`ACCESS_COARSE_LOCATION`, iOS
`NSLocationWhenInUseUsageDescription`.

## 6. 테스트

구조는 구현을 그대로 반영한다(`packages/features/commute/lib/src/**` ↔ `test/**`).

### feature_commute

- `SearchCommuteScenario`: 미설정 → `Err(commuteNotConfigured)` · GPS 성공 →
  `Origin.currentLocation` · GPS 실패 → toWork는 집, toHome은 회사로 fallback ·
  경로 실패 전파 · 목적지가 방향에 맞음
- `FakeTransitRouteRepository`: 모드 3개 순서, 같은 입력 → 같은 출력, 거리가 멀수록
  오래 걸림, legs의 minutes 합이 duration과 일치
- `AssetStationRepository`: 부분 일치·공백·대소문자, 빈 질의, `findById` 미존재
- `PrefsCommuteSettingsRepository`: 왕복, 없는 키 → 빈 설정, 없는 역 id → null
- `GeolocatorLocationRepository`: `geolocator`를 직접 mock하기 어려우므로 플랫폼 호출을
  감싼 얇은 `LocationGateway` 인터페이스를 두고 그것을 mock — 실패 종류별 `FailureCode`
- Cubit 3개: `bloc_test` + `mocktail`
- 위젯: 홈 `loaded` → 카드 3장 · `failure` → `AppPlaceholder` + 재시도 · 배너가
  `Origin`에 따라 다름 · 설정 페이지 선택 → 저장 호출

### apps/commute

- 라우터: 설정 미완성 → `/settings`, 완성 → `/`
- `test/convention/package_boundary_test.dart`: `packages/features/commute/pubspec.yaml`에
  `feature_` 접두 의존이 없고 `supabase_flutter`·`go_router`가 없음을 검사

### 문서

`docs/features/commute/plan.md`, `docs/testing/features/commute.md`, `docs/status.md`,
`docs/architecture.md`(§1에 `apps/commute`), `docs/setup.md`(실행 명령).
`documentation_links_test`가 통과해야 한다.

## 7. 리팩터링 후보 — 이 앱을 만들며 확인된 것

여기 적힌 것은 **지금 고치지 않는다.** 앱을 완성한 뒤 별도 작업으로 다룬다.
Codex는 작업 중 새로 발견한 항목을 이 목록 끝에 추가한다.

| # | 발견 | 근거 |
|---|---|---|
| 1 | `core`가 `supabase_flutter`·`image_picker`·`flutter_image_compress`·`flutter_secure_storage`에 의존하고 `CorePackageModule`이 `SupabaseClient`를 등록한다 | 통근 앱은 Supabase도 이미지도 안 쓰는데 전부 딸려온다. `core`는 "공통"이 아니라 "트레이더 인프라" |
| 2 | `core`의 `Routes`에 트레이더 앱 전체 경로가 있고, feature들이 다른 feature의 경로로 직접 `context.push`한다(19곳) | 둘째 앱이 쓰지 않는 기능의 경로 체계를 물려받는다. 통근 앱은 feature가 콜백을 받는 방식으로 대조 실험 |
| 3 | `l10n`이 단일 ARB고 `design_system → l10n` 의존이 있다 | 버튼 하나 쓰려고 트레이더 문자열 전부를 들고 온다. 통근 문자열도 같은 ARB에 들어간다 |
| 4 | `core`의 `FailureCode` enum이 feature 전용 코드(post·comment·report…)를 품고, `l10n`의 switch가 exhaustive다 | feature 하나 추가할 때마다 `core`와 `l10n`을 같이 고친다 |
| 5 | `feature_auth`를 쓰는 6곳 중 5곳은 로그인 기능이 아니라 `AuthBloc`에서 현재 사용자만 읽는다 | 세션 읽기 모델을 `core`로 내리면 엣지 대부분이 사라진다 (통근 앱과 무관하지만 앞선 분석에서 확인) |
| 6 | `feature_profile`이 chat·feed·follow·post·safety를 직접 조립한다 | 화면 조립은 app 레이어의 일 |
| 7 | `l10n`에 개수 문자열의 ICU plural 규약이 없다. 둘째 앱도 그 패턴을 물려받아 영어 `commuteTransferCount`가 `"{count} transfers"`("1 transfers")다 | 앱마다 plural을 다시 배우게 된다. 공유 plural 헬퍼나 ARB 규약 하나면 막을 수 있다 |
| 8 | `design_system`에 배너·인라인 안내 위젯이 없다. `OriginBanner`는 `Container` + `colorScheme` + `AppRadius`로 직접 만들었다 | 둘째 앱이 첫째 앱의 모양을 다시 구현하는 전형적인 경우. 공용 위젯으로 승격할 후보 |
| 9 | `core`·`design_system` 어디에도 "push한 화면이 닫히면 새로고침" 패턴이 없다. 트레이더는 `RouteObserver(didPopNext)`로, 통근은 자체 `OpenSettingsCallback = Future<void> Function()` 계약으로 각자 풀었다 | 콜백 vs `Routes` 실험의 데이터 포인트. 이동 방식을 통일할 때 이 패턴도 함께 정한다 |
