# Goal: 둘째 앱 `apps/commute`(통근 시간 앱)를 만든다

이 레포는 Flutter pub workspace 모노레포다(`apps/trader` + `packages/*`). 여기에
**두 번째 앱 `apps/commute`와 feature 패키지 `packages/features/commute`를 추가한다.**
집·회사를 지하철역으로 등록하고, 출근/퇴근 방향으로 지하철·버스·최적 소요 시간을
보여주는 앱이다. 로그인 없음. 외부 API 없음 — 경로 탐색은 **인터페이스만 두고 가짜
구현**을 쓴다.

이 앱의 숨은 목적은 `packages/`의 경계를 시험하는 것이다. 그래서 기존 패키지는
**`core` · `design_system` · `l10n`만** 쓰고 `feature_*`는 하나도 쓰지 않는다. 만들다가
"기존 패키지가 이래서 불편하다"를 발견하면 **고치지 말고** 설계 문서 §7 표에 한 줄
추가한다.

시작 전에 반드시 읽어라:

1. [`docs/superpowers/specs/2026-09-13-commute-app-design.md`](2026-09-13-commute-app-design.md)
   — **이 작업의 단일 설계 기준.** 엔티티·인터페이스·가짜 구현 규칙·Cubit·라우팅·
   테스트가 전부 거기 있다. 이 프롬프트는 순서와 규약만 말한다
2. `CLAUDE.md` — UI 공통 위젯 규칙, Freezed 규칙, 테스트 위치 규칙
3. `docs/architecture.md`, `docs/testing/conventions.md`
4. 관례를 베낄 기준 feature: `packages/features/trade` (usecase facade + scenario,
   `Result<T>`, injectable micro module, 테스트 구조)
5. 앱 셸 기준: `apps/trader/lib/{main,bootstrap}.dart`, `app/app.dart`,
   `app/router/app_router.dart`, `di/injection.dart`

환경: Flutter 3.41.7 / Dart 3.11.5. 브랜치는 `feat/monorepo`에서 `feat/commute-app`을
만들어 진행한다.

## 목표 구조

```
socialapp/
├── pubspec.yaml                       # workspace 에 apps/commute, packages/features/commute 추가
├── apps/
│   ├── trader/                        # 변경 없음
│   └── commute/                       # 새 앱 (org com.karma, project name commute)
│       ├── lib/{main,bootstrap}.dart
│       ├── lib/app/app.dart
│       ├── lib/app/router/{app_router,settings_redirect}.dart
│       ├── lib/di/injection.dart      # externalPackageModulesBefore: [Core, FeatureCommute]
│       ├── android/ ios/              # 위치 권한 선언
│       └── test/
│           ├── app/router/…
│           └── convention/package_boundary_test.dart
├── packages/features/commute/         # name: feature_commute
│   ├── assets/stations.json
│   ├── lib/feature_commute.dart       # barrel
│   ├── lib/src/{domain,data,presentation,di}/…
│   └── test/                          # lib/src 와 1:1
└── docs/
    ├── features/commute/plan.md
    ├── testing/features/commute.md
    └── superpowers/specs/2026-09-13-commute-app-design.md   # §7 표에 발견 추가
```

## 규약

- 패키지 규약은 모노레포 프롬프트와 같다: `publish_to: none`, `resolution: workspace`,
  `environment.sdk: ^3.11.5`, `analysis_options.yaml`은 루트를 `include:`, 패키지 경계를
  넘을 때만 `package:` import, 내부는 상대경로, 앱은 barrel만 import
- `feature_commute`의 `dependencies`에 허용되는 것: `core`, `design_system`, `l10n`,
  `flutter`, `flutter_bloc`, `freezed_annotation`, `injectable`, `json_annotation`,
  `shared_preferences`, `geolocator`, `intl`(필요 시). **`feature_*`, `supabase_flutter`,
  `go_router`는 금지**다 — `package_boundary_test`가 이걸 검사한다
- `geolocator`는 pub.dev 최신 안정 버전을 `^`로 적는다. 나머지 서드파티 버전은
  `apps/trader/pubspec.yaml`과 동일하게
- Freezed: 단일 모델은 Primary Constructor, 상태는 `sealed class` + named factory.
  분기는 `switch` 패턴 매칭 (`when`/`map` 금지)
- UI: `AppButton`·`AppListTile`·`AppPlaceholder`·`AppSnackBar`·`AppConfirmDialog`를
  쓰고 `Colors.*`·숫자 여백·`BorderRadius.circular(n)`을 화면에 직접 쓰지 않는다
- 문자열: `packages/l10n/lib/l10n/app_{ko,en,ja}.arb`에 `commute` 접두어로 추가.
  `app_ko.arb`의 모든 키에 `@key.description`을 채운다(컨벤션 테스트). 추가 후
  `melos run l10n`으로 생성 파일을 갱신하고 커밋한다
- `FailureCode` 5개는 `packages/core`의 enum 끝에 추가하고, `packages/l10n`의
  `FailureLocalizations` switch와 ARB 3개에 대응 문자열을 넣는다
- 생성 파일(`.freezed.dart`, `.g.dart`, `*.module.dart`, `injection.config.dart`)은
  손으로 고치지 않는다. `melos run gen`
- 커밋 메시지는 레포 관례(`feat(commute): …` 한글 서술)

## 진행 순서 — 단계마다 검증하고 커밋한다

각 단계 끝에 아래를 통과시킨 뒤 커밋한다. 통과하지 않으면 다음 단계로 가지 않는다.

```bash
melos run analyze
melos run test
cd apps/commute && flutter build apk --debug    # 3단계부터
```

1. **패키지 뼈대 + 도메인.** `packages/features/commute` 생성(pubspec, analysis_options,
   barrel, `di/feature_commute.dart`). 루트 `pubspec.yaml` workspace에 추가. 설계 §2의
   엔티티·인터페이스·`CommuteUseCase`·시나리오 4개. `core`에 `FailureCode` 5개 추가,
   `l10n`에 대응 문자열. **`SearchCommuteScenario` 테스트를 먼저 쓰고 통과시킨다**
   (mocktail로 repository 4개 mock). 검증·커밋
2. **데이터 구현.** `FakeTransitRouteRepository`(설계 §3의 표 그대로),
   `AssetStationRepository` + `assets/stations.json`(장승배기·강남 포함 30개 내외),
   `PrefsCommuteSettingsRepository`, `GeolocatorLocationRepository`(+ `LocationGateway`
   인터페이스로 플랫폼 호출을 감싼다). 각각 테스트. micro module에 등록하고
   `melos run gen`. 검증·커밋
3. **앱 뼈대.** `flutter create --org com.karma --project-name commute --platforms android,ios apps/commute`
   후 기본 `lib/`·`test/`·README를 지우고 `resolution: workspace` 추가. `bootstrap`
   (Supabase 없음) · `CommuteApp` · `injection.dart`(`CorePackageModule`,
   `FeatureCommutePackageModule`) · 라우터(`/`, `/settings`, settings redirect). 이 시점엔
   페이지 대신 `Placeholder` 위젯을 붙여도 된다. Android/iOS 위치 권한 선언.
   `package_boundary_test` 작성. **`flutter build apk --debug`가 돌아야 한다.** 검증·커밋
4. **설정 화면.** `CommuteSettingsCubit`, `StationSearchCubit`, `CommuteSettingsPage`,
   `StationSearchSheet`. Cubit은 `bloc_test`, 페이지는 위젯 테스트. 라우터에 연결.
   검증·커밋
5. **홈 화면.** `CommuteHomeCubit`, `CommuteHomePage`, `DirectionToggle`, `OriginBanner`,
   `TransitRouteCard`, `CommuteFormat`. 테스트(설계 §6). 라우터에 연결, 설정 완료 →
   홈 이동. 검증·커밋
6. **에뮬레이터 확인.** 앱을 실제로 띄워 ① 첫 실행이 설정으로 가는지 ② 역 검색·선택이
   되는지 ③ 홈에 카드 3장이 뜨는지 ④ 위치 권한을 거부했을 때 "집 기준" 배너가 뜨고
   결과가 나오는지 확인한다. 어긋나면 고치고 검증·커밋
7. **문서.** `docs/features/commute/plan.md`(화면·상태·완료 조건 — 설계 문서를 요약해
   링크), `docs/testing/features/commute.md`, `docs/status.md`(둘째 앱 착수·완료),
   `docs/architecture.md` §1에 `apps/commute`, `docs/setup.md`에 실행 명령
   (`cd apps/commute && flutter run`). `docs/superpowers/specs/2026-09-13-commute-app-design.md`
   §7 표에 작업 중 발견한 항목 추가. `documentation_links_test` 통과. 커밋

## 하지 말 것

- **기존 패키지 리팩터링.** `core`·`l10n`·`design_system`·`feature_*`의 구조를 바꾸지
  마라. 허용되는 변경은 `FailureCode` 추가, ARB 문자열 추가, 루트 workspace 목록
  추가뿐이다. 불편한 점은 설계 문서 §7에 적는다
- 실제 경로 API 연동, API 키, 네트워크 호출. `TransitRouteRepository` 구현은 가짜 하나뿐
- 로그인·Supabase·알림·지도·경로 상세. 설계 §1 "의도적으로 없는 것"
- `feature_commute`가 `go_router`나 `core`의 `Routes`를 쓰는 것. 페이지는 콜백을 받는다
- `apps/trader`의 동작 변경. trader의 테스트가 깨지면 ARB나 `FailureCode` 변경 실수다
- `supabase/` 변경
- 한 커밋에 여러 단계

## 완료 조건

- `melos run analyze`, `melos run test` 전부 통과. `apps/commute`와 `apps/trader` 둘 다
  `flutter build apk --debug`로 빌드된다
- `packages/features/commute/pubspec.yaml`에 `feature_`·`supabase_flutter`·`go_router`가
  없다 (`package_boundary_test` 통과)
- `grep -r "go_router\|package:feature_" packages/features/commute/lib`가 비어 있다
- 에뮬레이터에서 6단계의 4가지 시나리오가 확인됐다
- 설계 문서 §7에 작업 중 발견한 항목이 추가돼 있다(없으면 "추가 없음"이라고 보고)
- 작업이 끝나면 각 단계의 커밋 해시와, 설계와 다르게 결정한 지점(있다면 이유와 함께)을
  목록으로 보고하라
