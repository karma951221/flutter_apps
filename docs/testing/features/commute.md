# commute 테스트

> [테스트 가이드](../README.md) · [계획](../../features/commute/plan.md) · [기록](../../features/commute/history.md) · [진행 현황](../../status.md)

```bash
cd packages/features/commute && flutter test   # feature 패키지 (도메인 · 데이터 · cubit · 위젯)
cd apps/commute && flutter test                 # 앱 셸 (라우터 · 패키지 경계)
```

Supabase 가 없으므로 권한 경계 스크립트는 없다. 두 명령 모두 로컬 Supabase 없이 돈다
(2026-09-13 기준 40건 · 4건).

## `packages/features/commute/test/` — 구현과 1:1

| 파일 | 대상 | 확인 |
|---|---|---|
| `domain/usecase/scenario/search_commute_scenario_test.dart` | `SearchCommuteScenario` | 설정 미완성 → `commuteNotConfigured` · GPS 성공 → `Origin.currentLocation` · GPS 실패 시 출근은 집, 퇴근은 회사로 fallback · 경로 검색 실패는 그대로 전파. 목적지가 방향에 맞는지 함께 본다 (repository 4개 mock) |
| `data/repository/fake_transit_route_repository_test.dart` | `FakeTransitRouteRepository` | subway · bus · best 순서로 3개 · 같은 입력은 같은 출력 · 거리가 멀수록 모든 모드가 오래 걸림 · 각 leg 의 분 합 = `duration` |
| `data/repository/asset_station_repository_test.dart` | `AssetStationRepository` | 공백 제거 부분 일치 · 영문 대소문자 무시 · 빈 질의는 자산을 읽지 않고 빈 목록 · 없는 id 는 null 이고 자산은 한 번만 읽는다 (`AssetBundle` 을 가짜로 주입) |
| `data/repository/prefs_commute_settings_repository_test.dart` | `PrefsCommuteSettingsRepository` | 역 id 만 저장하고 `StationRepository` 로 복원 · 키가 없으면 빈 설정 · 목록에 없는 id 는 null |
| `data/repository/geolocator_location_repository_test.dart` | `GeolocatorLocationRepository` (`LocationGateway` mock) | 허용 → `GeoPoint` · 서비스 꺼짐 → `locationServiceDisabled` · 거부 → 한 번 요청 후 `locationPermissionDenied` · **같은 세션에서 거부하면 다시 요청하지 않는다** · **거부 뒤 설정에서 허용하면 묻지 않고 위치 반환** · 영구 거부는 요청 없음 · `TimeoutException` → `locationTimeout` · 그 밖 예외 → `unknown` |
| `presentation/cubit/commute_home_cubit_test.dart` | `CommuteHomeCubit` | 기본 출근 방향 검색 → `loading` · `loaded` · 방향 전환은 즉시 재검색 · 실패해도 방향 보존 · 앞 방향의 늦은 응답이 새 방향 결과를 덮지 않는다 |
| `presentation/cubit/commute_settings_cubit_test.dart` | `CommuteSettingsCubit` | 읽어서 `loaded` · 집 역을 고르면 기존 회사 역을 보존해 저장 · 저장 실패 → `failure` |
| `presentation/cubit/station_search_cubit_test.dart` | `StationSearchCubit` | 300ms 뒤 검색 · 새 질의가 이전 디바운스를 취소 · 빈 질의는 검색 없이 `idle` |
| `presentation/page/commute_home_page_test.dart` | `CommuteHomePage` | `loaded` → 카드 3장 + "현 위치 기준" 배너 · 위치 실패면 "집 기준" 배너 · **설정이 닫히면 다시 검색한다**(`onOpenSettings` 의 Future 완료 시점) · `failure` → `AppPlaceholder` + 재시도 |
| `presentation/page/commute_settings_page_test.dart` | `CommuteSettingsPage` | 역을 고르면 즉시 저장 · 집 · 회사가 모두 정해지면 `onDone` 을 한 번만 부른다 |

## `apps/commute/test/`

| 파일 | 대상 | 확인 |
|---|---|---|
| `app/router/settings_redirect_test.dart` | `SettingsRedirect` | 미완성이면 홈 → `/settings` · 완성이면 홈 · 설정 모두 허용 · `markComplete()` 뒤 홈 허용 |
| `convention/package_boundary_test.dart` | `packages/features/commute/pubspec.yaml` | 아래 불변식 |

### `package_boundary_test` 의 불변식

`feature_commute` 의 `dependencies:` 블록(`dev_dependencies:` 앞까지)에 대해:

1. `feature_` 로 시작하는 의존이 없다 — 기존 feature 를 하나도 끌어오지 않는다
2. `supabase_flutter:` 가 없다 — 백엔드 없이 선다
3. `go_router:` 가 없다 — 이동은 콜백으로 받고 경로는 앱이 정한다

이 셋이 "둘째 앱은 `core` · `design_system` · `l10n` 만으로 조립된다"는 실험의
전제다. 어기면 [설계 §7](../../superpowers/specs/2026-09-13-commute-app-design.md#7-리팩터링-후보--이-앱을-만들며-확인된-것)
의 데이터가 오염된다.

## 에뮬레이터 (2026-09-13)

`Medium_Phone` AVD(Android 17)에서 릴리즈 arm64 APK 로 4가지를 확인했다
(`/data` 가 차서 디버그 APK 는 설치되지 않았다 — [기록](../../features/commute/history.md)).

| # | 시나리오 | 결과 |
|---|---|---|
| ① | 첫 실행이 홈 대신 설정으로 간다 | 통과 |
| ② | 역 이름 일부로 검색 → 결과에서 선택 → 집 · 회사가 채워지면 홈으로 이동 | 통과 |
| ③ | 홈에 지하철 · 버스 · 최적 카드 3장, 출근 ↔ 퇴근 토글로 재검색 | 통과 |
| ④ | 위치 권한 거부 → "집 기준"(퇴근이면 "회사 기준") 배너와 함께 결과 표시 | 통과 |

추가로 다크 모드 · 가로 회전 · 백그라운드 복귀 · 콜드 재실행(설정 유지)을 확인했다.
그 과정에서 찾은 두 결함(권한 거부 뒤 다이얼로그 반복, 설정 복귀 후 이전 결과
잔존)은 `d1c7d8e` 로 고쳤고 위 표의 굵은 항목이 그 회귀 테스트다.

## 알아둘 것

- 위젯 테스트는 `locale: Locale('ko')` 를 고정한다. `ko` 가 ARB template 이라
  원문이 곧 기대값이다
- 홈 · 설정 페이지 테스트는 `getIt` 에 mock `CommuteUseCase` 와 cubit factory 를
  등록하고 `tearDown` 에서 `getIt.reset` 한다 — 페이지가 `BlocProvider` 안에서
  `getIt<...Cubit>()` 을 부르기 때문이다
- `package_boundary_test` 는 `Directory.current.parent.parent` 로 workspace 루트를
  찾는다. `apps/commute` 에서 실행해야 한다
