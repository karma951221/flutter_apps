# Goal: socialapp을 Flutter 모노레포(pub workspace)로 재구성한다

이 레포의 `app/`(Flutter 앱 daylog, 421개 dart 파일)을 **여러 앱이 공유 패키지를 재사용하는 모노레포**로 바꾼다.
지금 앱은 `apps/trader/`로 옮기고, 공통 코드와 feature를 `packages/` 아래의 독립 Dart 패키지로 분리한다.
이번 작업에서 두 번째 앱은 만들지 않는다 — 다음 앱이 `apps/<name>/`에 들어와서 필요한 패키지만 골라 조립할 수 있는 구조를 만드는 것이 목표다.

시작 전에 `CLAUDE.md`, `docs/architecture.md`, `docs/testing/conventions.md`를 읽어라. 환경은 Flutter 3.41.7 / Dart 3.11.5(pub workspace 네이티브 지원)다. 작업은 `main`에서 새 브랜치 `feat/monorepo`를 만들어 진행한다.

## 목표 구조

```
socialapp/
├── pubspec.yaml               # pub workspace 루트 (workspace: [...])
├── melos.yaml                 # 전체 analyze / test / build_runner 일괄 실행 스크립트
├── analysis_options.yaml      # 공통 lint (각 패키지는 include: 로 참조)
├── apps/
│   └── trader/                # 지금의 app/ 을 이동. main, bootstrap, app shell, router,
│                              #   DI 조립, config, home, android/ios, patrol_test, convention 테스트
├── packages/
│   ├── core/                  # error, result, pagination, id, validation, extension,
│   │                          #   data(mapper/guard), media, network, di/register_module
│   ├── design_system/         # theme + widget
│   ├── l10n/                  # ARB + gen-l10n 산출물(AppLocalizations) + failure/validation localizations
│   └── features/
│       ├── auth/  post/  feed/  comment/  follow/  reaction/
│       ├── profile/  chat/  safety/  settings/  preferences/  trade/
│       └── (home 은 앱 셸이므로 apps/trader 에 남긴다)
├── supabase/                  # 변경 없음
└── docs/
```

### 무엇이 어디로 가는가

| 지금 (`app/lib/`) | 목적지 | 비고 |
|---|---|---|
| `main.dart`, `bootstrap.dart`, `app/**` | `apps/trader/lib/` | 앱 셸 |
| `core/config/app_config.dart` | `apps/trader/lib/config/` | Supabase URL/key는 앱마다 다를 수 있으므로 앱 소유 |
| `core/di/injection.dart`, `injection.config.dart` | `apps/trader/lib/di/` | 앱이 모듈을 조립하는 곳 |
| `core/di/register_module.dart` | `packages/core` | 서드파티 인스턴스 등록(@module)은 공유 |
| `core/l10n/failure_localizations.dart`, `validation_localizations.dart` | `packages/l10n` | `AppLocalizations`를 쓰므로 core에 두면 core→l10n 순환이 생긴다 |
| `core/{error,result,pagination,id,validation,extension,data,media,network}` | `packages/core` | |
| `design_system/**` | `packages/design_system` | |
| `l10n/**` (ARB + 생성 파일), `l10n.yaml` | `packages/l10n` | |
| `features/home/**` | `apps/trader/lib/home/` | 1개 파일. 앱 셸 |
| `features/<x>/**` (home 제외 12개) | `packages/features/<x>/lib/src/` | |
| `test/features/<x>/**` | `packages/features/<x>/test/` | 구현 구조와 테스트 구조를 1:1로 유지하는 규칙은 그대로 |
| `test/core/**`, `test/design_system/**` | 각 패키지의 `test/` | |
| `test/app/**`, `test/convention/**`, `app_*_test.dart`, `widget_test.dart`, `patrol_test/**` | `apps/trader/test/`, `apps/trader/patrol_test/` | |
| `android/`, `ios/`, 기타 플랫폼 폴더 | `apps/trader/` | |

### 패키지 규약

- 패키지 이름: `core`, `design_system`, `l10n`, feature는 `feature_<name>` (디렉터리는 `packages/features/<name>`).
  예: `packages/features/post` → `name: feature_post` → `import 'package:feature_post/feature_post.dart';`
- 각 패키지는 `pubspec.yaml`, `analysis_options.yaml`(`include: ../../analysis_options.yaml` 또는 `../../../`), `lib/<package_name>.dart`(barrel, `src/` 아래의 public 파일을 export), `lib/src/…`, `test/`를 가진다.
- 모든 패키지는 `publish_to: none`, `resolution: workspace`. 앱과 패키지의 상호 참조는 workspace 안에서 이름으로 resolve 한다(path 의존 대신). `environment.sdk`는 루트와 동일하게 `^3.11.5`.
- 의존 방향은 단방향만 허용한다:
  `apps → features → l10n → core`, `features → design_system → core`(design_system이 core를 안 써도 되면 의존 자체를 넣지 않는다).
  feature 간 의존은 지금 코드에 실제로 있는 것만 pubspec에 적는다: `feed → follow, reaction` / `follow → safety` / `profile → follow, safety` / `post → trade`. 새로운 feature 간 의존을 만들지 마라. 순환이 생기면 멈추고 보고하라.
- import 규칙: **패키지 경계를 넘을 때만 `package:` import**, 패키지 내부는 지금처럼 상대경로를 유지한다. 앱은 feature의 barrel만 import한다(`package:feature_post/src/...` 금지).
- 각 패키지의 pubspec에는 그 패키지가 **실제로 import하는** 서드파티 의존만 적는다. 버전은 지금 `app/pubspec.yaml`과 동일하게 맞춘다. 루트 pubspec에는 `workspace:` 목록만 둔다(공통 dev_dependencies 불필요).

### DI (injectable micro-package)

- `core`와 각 feature 패키지는 `@InjectableInit.microPackage()`를 단 `lib/src/di/<package_name>.module.dart` 진입 파일을 가지고, build_runner가 `<package_name>.module.dart`의 `initMicroPackage` 를 생성한다. barrel에서 export한다.
- `apps/trader/lib/di/injection.dart`의 `@InjectableInit`에 `externalPackageModulesBefore: [ExternalModule(CorePackageModule), ExternalModule(FeatureAuthPackageModule), …]`로 모든 패키지 모듈을 나열한다. `@preResolve`(SharedPreferences)는 core 모듈 안에서 처리되어야 하므로 `getIt.init()`을 `await`하는 지금 흐름을 유지한다.
- 앱 코드가 `getIt`을 직접 참조하는 곳이 feature 안에 있으면(`core/di/injection.dart` import), feature가 앱을 참조할 수 없으므로 `GetIt.instance`를 core에서 export하는 `getIt`으로 대체한다(`packages/core/lib/src/di/get_it.dart`).

### l10n

- `packages/l10n/l10n.yaml`: `arb-dir: lib/l10n`, `output-dir: lib/l10n`, `template-arb-file: app_ko.arb`, `output-class: AppLocalizations`, `nullable-getter: false`, `synthetic-package: false`. 생성 파일은 지금처럼 커밋한다.
- feature/앱은 `package:l10n/l10n.dart`로 `AppLocalizations`와 `failure/validation localizations`를 받는다.
- `test/convention/arb_description_convention_test.dart`는 ARB 경로를 `packages/l10n/lib/l10n`으로 바꿔서 `apps/trader/test/convention`에 남긴다.

### 코드 생성

- `.freezed.dart`, `.g.dart`, `*.module.dart`, `injection.config.dart`는 손으로 고치지 않고 각 패키지에서 `dart run build_runner build --delete-conflicting-outputs`로 다시 만든다. `melos run gen`이 전체 패키지를 순회하도록 melos 스크립트를 만든다.
- melos 스크립트: `analyze`(모든 패키지 `flutter analyze`), `test`(모든 패키지 `flutter test`), `gen`(build_runner가 있는 패키지만), `l10n`(`packages/l10n`에서 `flutter gen-l10n`).

## 진행 순서 — 단계마다 검증하고 커밋한다

각 단계 끝에 **반드시** 아래를 통과시킨 뒤 커밋한다. 통과하지 않으면 다음 단계로 가지 않는다.

```bash
melos run analyze          # (1단계 이전에는 cd apps/trader && flutter analyze)
melos run test             # (1단계 이전에는 cd apps/trader && flutter test)
cd apps/trader && flutter build apk --debug   # 실제로 빌드되는지
```

1. **워크스페이스 + 앱 이동.** 루트 `pubspec.yaml`(workspace), `melos.yaml`, 루트 `analysis_options.yaml`을 만들고 `git mv app apps/trader`. 앱 pubspec에 `resolution: workspace` 추가. 코드는 손대지 않는다. 검증·커밋.
2. **`core` 추출.** `packages/core` 생성, 위 표의 파일 이동, `register_module` 포함. 앱·feature의 core 참조를 `package:core/core.dart`로 바꾼다. `app_config`는 앱에 남긴다. core의 테스트 이동. 검증·커밋.
3. **`design_system` 추출.** 같은 방식. 검증·커밋.
4. **`l10n` 추출.** ARB·생성 파일·`l10n.yaml`·`failure/validation localizations` 이동. 앱 pubspec의 `flutter.generate: true` 제거, `flutter_localizations` 의존은 l10n 패키지와 앱 둘 다에 둔다. `flutter gen-l10n` 재실행. 검증·커밋.
5. **feature 추출 — 리프부터 하나씩, 하나당 한 커밋.** 순서: `safety → reaction → follow → trade → auth → comment → chat → preferences → settings → feed → profile → post`.
   각 feature마다: 패키지 생성 → `lib/src`로 이동 → barrel 작성 → 경계 넘는 import를 `package:`로 변환 → micro-package DI 파일 추가 → 테스트 이동 → build_runner → 앱 `injection.dart`에 모듈 등록 → 검증 → 커밋.
6. **home 이동.** `features/home` → `apps/trader/lib/home/`. 검증·커밋.
7. **최종 DI 정리.** 앱 `injection.dart`가 모든 모듈을 나열하는지, 앱 `injection.config.dart`에 feature 클래스가 직접 등록되지 않았는지(모두 micro-package로 들어가야 함) 확인. `flutter build apk --debug`. 커밋.
8. **문서 갱신.** `docs/architecture.md`(§1 최상위 구조, §2 Flutter 내부 구조를 새 구조로), `CLAUDE.md`(명령 섹션의 `cd app` → melos 명령, UI 규칙의 `app/lib/design_system` 경로, 테스트 위치 규칙의 경로), `docs/setup.md`, `docs/testing/README.md`·`conventions.md`·`e2e.md`의 경로. `documentation_links_test`가 통과해야 한다. 커밋.

## 하지 말 것

- 동작 변경. 이 작업은 순수 구조 이동이다. 위젯·로직·테스트 내용을 고치지 마라. 테스트가 깨지면 이동 과정의 실수이지 테스트를 고칠 이유가 아니다.
- `post → trade` 의존 끊기, feature별 ARB 분리, 두 번째 앱 스캐폴딩 — 모두 범위 밖이다.
- `supabase/` 변경.
- 생성 파일 수동 편집.
- 한 커밋에 여러 feature 추출. 되돌리기 쉽도록 feature당 한 커밋을 지킨다.
- 커밋 메시지는 이 레포의 관례(`refactor(scope): …` 한글 서술)를 따른다.

## 완료 조건

- `melos run analyze`, `melos run test`가 전부 통과하고 `apps/trader`가 `flutter build apk --debug`로 빌드된다.
- `apps/trader/lib` 안에 feature 구현 코드가 없다(app shell, router, config, di, home, bootstrap만).
- `packages/**`의 어떤 파일도 `apps/`를 import하지 않는다(`grep -r "apps/" packages/`가 비어 있다).
- `packages/**`에서 상대경로로 다른 패키지에 도달하는 import가 없다(`grep -rE "import '(\.\./)+\.\./" packages/`가 패키지 경계를 넘는 결과를 내지 않는다).
- `docs/architecture.md`와 `CLAUDE.md`가 새 구조를 설명하고, `documentation_links_test`가 통과한다.
- 작업이 끝나면 각 단계의 커밋 해시와, 이동 중 판단이 필요했던 지점(예: 예상 밖의 feature 간 의존, 순환)을 목록으로 보고하라.
