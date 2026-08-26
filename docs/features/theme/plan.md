# theme — 계획 (다크모드)

> [문서 허브](../../README.md) · [아키텍처](../../architecture.md) · [설정 계획](../settings/plan.md)

> 상태: **완료** · 작성 2026-08-26 · 구현 2026-08-26 ([구현 기록](history.md))
> 진행 상태의 단일 기준은 [진행 현황](../../status.md)이다.

## 범위

화면 테마(시스템 · 라이트 · 다크)를 사용자가 고르고, 선택이 기기에 남아 재시작 후에도
유지된다. 설정 탭에 진입점이 붙는다.

**테마 자체는 이미 있다.** `AppTheme.light()` · `dark()` 가 둘 다 구현돼 있고
`MaterialApp` 에 `theme` · `darkTheme` 로 배선돼 있어, 지금도 OS 설정을 따라 다크가
뜬다. 하드코딩된 색도 없다 — `Colors.*` 직접 사용 0건, 전부 `AppColors` 토큰이나
`Theme.of(context).colorScheme` 경유다(사전 조사 2026-08-26). 이번 작업은
**`themeMode` 를 사용자가 제어하게 만드는 것**이다: 저장소 + 전역 상태 + 설정 UI.

## 확정한 결정과 근거

| 항목 | 결정 | 근거 |
|---|---|---|
| 선택지 | **3상태** — 시스템 · 라이트 · 다크 (사용자 확정 2026-08-26) | 2상태 스위치는 "OS 따라가기"를 없앤다. 기본값이 시스템이면 지금 동작이 그대로 유지되고, 밤에 OS 가 다크로 바뀌는 연동도 살아 있다 |
| 기본값 | **시스템** | 저장된 값이 없으면 지금과 똑같이 동작한다. 업데이트가 기존 사용자의 화면을 바꾸지 않는다 |
| feature 위치 | **`features/theme` 신설** | settings 는 의도적으로 presentation 만 갖는 feature 다 ([설정 계획](../settings/plan.md)). 테마는 저장소(domain·data)가 필요하므로 거기 끼우면 그 결정이 깨진다. 설정 화면은 auth·profile 을 쓰듯 theme 의 cubit 을 **쓰기만** 한다 (규칙 ⑥) |
| 저장소 | **`shared_preferences`** | 이미 의존성에 있고(미사용) 기기 로컬 설정에 맞는 도구다. 테마는 민감정보가 아니므로 Keychain(`flutter_secure_storage`)을 쓸 이유가 없고, 서버(Supabase)에 두면 기기마다 다르게 쓰고 싶은 사용자를 막는다 |
| 저장 형식 | 키 `theme_mode`, 값 `'system'` · `'light'` · `'dark'` | 문자열 코드는 `ReactionType.code` 와 같은 방식이다. 모르는 값이나 없는 값은 시스템으로 읽는다 — 값이 늘거나 저장이 깨져도 앱이 죽지 않는다 |
| domain 타입 | **자체 enum `AppThemeMode`** (system·light·dark) | Flutter 의 `ThemeMode` 를 domain 에 두면 domain 이 material 에 묶인다. 매핑은 presentation 이 한다 — `ReportTarget` → `target_type` 매핑과 같은 결이다 |
| 상태 관리 | **`ThemeCubit`**, 앱 루트(`DaylogApp`)에서 제공 | `MaterialApp.themeMode` 가 소비자라 라우터·탭보다 위에 있어야 한다. `AuthBloc` 과 같은 자리다 |
| 첫 프레임 | **깜빡임 없음** — DI 가 `SharedPreferences` 를 `@preResolve` 로 미리 들고, cubit 이 생성자에서 동기로 읽는다 | `SharedPreferences` 는 `getInstance()` 이후 메모리 캐시라 읽기가 동기다. cubit 초기 상태가 곧 저장값이므로 "라이트로 떴다가 다크로 바뀌는" 프레임이 없다 |
| 저장 실패 | **무시하고 상태만 바꾼다** | 화면 전환은 즉시 일어나야 한다. 저장이 실패하면 다음 실행에 이전 값으로 뜰 뿐이고, 그것을 오류로 알리는 것이 사용자에게 더 성가시다 |
| UI 형태 | 설정 행 '화면 테마' + **선택 다이얼로그**(라디오 3개) | 행의 subtitle 이 현재 값을 보여주고, 탭하면 다이얼로그에서 고른다. 고르는 즉시 적용되고 닫힌다. 신고 시트의 `RadioGroup` 패턴을 따른다 |

## 구조

```
features/theme/
├── domain/
│   ├── entity/app_theme_mode.dart       enum 3개 + code + label + fromCode
│   ├── repository/theme_repository.dart
│   └── usecase/theme_use_case.dart      ← facade (규칙 ③)
├── data/
│   ├── datasource/{theme_data_source,preferences_theme_data_source}.dart
│   └── repository/theme_repository_impl.dart
└── presentation/
    └── cubit/theme_cubit.dart              상태 클래스 없음 — Cubit<AppThemeMode>
```

| 동작 | 시그니처 |
|---|---|
| 현재 값 | `AppThemeMode loadThemeMode()` — **동기.** 메모리 캐시 읽기라 Future 를 씌울 이유가 없다 |
| 저장 | `Future<void> saveThemeMode(AppThemeMode mode)` |

`Result` 를 쓰지 않는다. 이 저장소는 실패를 사용자에게 보고하지 않기로 결정했고
(위 표), 네트워크도 권한 경계도 없다. error handler mixin 도 없다 — Supabase 예외가
발생하지 않는 경로다.

`SharedPreferences` 인스턴스는 `core/di/register_module.dart` 에 `@module` +
`@preResolve` 로 등록한다. `@preResolve` 는 생성된 `init` 의 반환을 `Future` 로
바꾸므로 `configureDependencies()` 안에서 `await getIt.init()` 이 필요하다 —
호출부 세 곳이 이미 전부 await 하고 있어 외부 동작은 그대로다
([구현 기록](history.md)).

### `ThemeCubit`

- `@injectable`. `ThemeUseCase` 하나만 주입 (규칙 ③). `BuildContext` 없음
- 초기 상태 = 생성자에서 `loadThemeMode()` 동기 호출
- `setMode(AppThemeMode mode)` — 상태 emit 후 저장. 같은 값이면 아무것도 안 한다
- 상태는 `AppThemeMode` 값 하나 — Freezed 를 씌울 필드가 없으므로 상태 클래스 없이
  `Cubit<AppThemeMode>` 로 둔다

### 배선

`DaylogApp` 의 `BlocProvider` 에 `ThemeCubit` 을 더하고, `MaterialApp.router` 를
`BlocBuilder<ThemeCubit, AppThemeMode>` 로 감싸 `themeMode` 에 매핑을 넘긴다.
`AppThemeMode` → `ThemeMode` 매핑은 이 파일(또는 cubit 옆 확장)이 갖는다 —
material 타입을 아는 곳은 presentation 뿐이다.

### 설정 UI

`settings_page.dart` 의 '계정 설정' 아래, '차단한 사용자' 위에 `AppListTile` 행
'화면 테마'를 더한다. subtitle 은 현재 모드의 label (시스템 설정 · 라이트 · 다크).
탭하면 `AlertDialog` 에 `RadioGroup<AppThemeMode>` 3개 — 고르면 즉시
`ThemeCubit.setMode` 하고 닫는다. 취소 버튼은 두지 않는다(바깥 탭으로 닫으면 그대로).

## 테스트

| 파일 | 검증 |
|---|---|
| `domain/entity/app_theme_mode_test.dart` | `fromCode` — 세 코드 · 모르는 값 · null → system |
| `data/repository/theme_repository_impl_test.dart` | `SharedPreferences.setMockInitialValues` 로 저장·복원 왕복, 값 없음 → system |
| `presentation/cubit/theme_cubit_test.dart` | 초기 상태가 저장값 · `setMode` 가 emit 후 저장 · 같은 값은 no-op |
| `settings_page_test.dart` (기존 수정) | '화면 테마' 행이 보인다 · 다이얼로그에 3개 · 선택 시 cubit 호출 |
| `app` 수준 | `themeMode` 가 cubit 상태를 따라 바뀐다 (기존 `widget_test.dart` 옆) |

`AppColors.like` · `dislike` 가 다크 배경에서 읽히는지 구현 중 확인한다 — 고정
브랜드 색이라 양쪽 테마에서 같은 값인데, 대비가 무너지면 이 계획을 갱신하고 다크용
변형을 논의한다.

## 완료 조건

- [x] 설정 → 화면 테마에서 시스템 · 라이트 · 다크를 고를 수 있다
- [x] 선택이 즉시 전체 화면에 적용된다
- [x] 앱을 재시작해도 선택이 유지된다
- [x] 저장값이 없으면(첫 실행·업데이트 직후) 시스템을 따른다
- [x] 시스템 모드에서 OS 다크 전환이 앱에 반영된다
- [x] 첫 프레임부터 저장된 테마로 뜬다 (라이트 깜빡임 없음)
