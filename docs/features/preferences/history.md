# preferences — 구현 기록

> [다크모드 계획](plan-theme.md) · [언어 계획](plan-language.md) · [테스트](../../testing/features/preferences.md)

계획과 달라진 것과 그 이유만 적는다.

## 다크모드 — 2026-08-26 (commit `cb7472d`)

### 계획에 없던 변경 두 가지

**`configureDependencies()` 가 `await getIt.init()` 으로 바뀌었다.** 계획은 "부트스트랩
변경 없음"이라고 했지만, `@preResolve` 를 쓰는 순간 생성된 `init` 의 반환이
`Future<GetIt>` 이 된다. await 없이 두면 첫 화면이 `SharedPreferences` 등록보다 먼저
그것을 요구하는 경쟁이 생긴다. 호출부 세 곳(bootstrap 두 경로 · Patrol 하니스)이
이미 전부 await 하고 있어 외부 동작은 그대로다 — 리뷰가 세 호출부를 확인했다.

**`home_shell_page_test.dart` 에 `ThemeCubit` 제공이 추가됐다.** 설정 탭이 이제
`ThemeCubit` 을 읽으므로 홈 셸 테스트의 하니스에도 프로덕션(`app.dart`)과 같은
모양으로 넣어야 했다.

### 계획대로였지만 적어둘 것

- **scenario 디렉터리가 없다.** facade 가 repository 로 바로 위임한다 — 정책도,
  저장소 조합도 없는 feature 라 scenario 를 만들면 빈 통과 계층만 는다.
- **첫 프레임 무깜빡임**은 계획의 기제 그대로 성립한다: `@preResolve` 로
  `SharedPreferences` 가 DI 시점에 준비되고, cubit 생성자가 `super()` 초기화식에서
  동기로 읽으므로 `MaterialApp` 의 첫 build 가 이미 저장된 모드다. 리뷰가 경로
  전체를 추적해 확인했다.

### 부수 발견

`AppColors.like` · `dislike` 가 **어디에서도 쓰이지 않는다** (lib · test 0건).
반응 UI 는 `AppCountAction` 이 `colorScheme` 파생 색으로 그린다. 죽은 토큰이라
다크 대비 문제도 없다 — 지울지는 별도 판단으로 남긴다.

> **2026-08-27 정정.** 위에서 "`like`(다크 표면 대비 ~3.5:1)는 WCAG AA 에 걸린다"고
> 적었는데 **테마를 거꾸로 봤다.** 실측하면 반대다 — `like` 는 라이트에서 3.28:1
> (AA 미달), 다크에서는 5.38:1 로 통과한다. `~3.5` 는 라이트 값이었다.
> `dislike` 는 양쪽 다 미달이다(라이트 4.29 · 다크 4.11). 셋 다 큰 글자·아이콘
> 기준(3:1)은 넘는다. 수치는
> `test/design_system/theme/app_theme_contrast_test.dart` 가 고정한다.

## 개명 — 2026-08-27 (commit `ccf6542` + 후속)

`features/theme` → `features/preferences`. [다크모드 계획](plan-theme.md)의
"이름 범위" 행이 예고한 개명 기준("두 번째 로컬 설정이 기획에 실리는 시점")이
언어 설정으로 발동했다.

- `ThemeUseCase` 를 `PreferencesUseCase` 로 합쳤다. 저장소는 관심사별
  (`ThemeRepository` · `LanguageRepository`)로 남긴다 — 잡화점 저장소를 피한다는
  원래 근거가 facade 통합으로는 깨지지 않는다.
- **개명 커밋이 문서를 하나도 갱신하지 않았다.** `docs/features/theme/` 가 없는
  경로를 가리킨 채로 남았고, `docs/testing/features/theme.md` 의
  `flutter test test/features/theme` 는 실제로 실패했다. 2026-08-27 리뷰가 잡아
  이 폴더로 옮기면서 함께 고쳤다 — feature 를 개명할 때 `docs/features/<name>/`
  와 `docs/testing/features/<name>.md` 를 같은 커밋에서 옮긴다.

## 표시 이름을 domain 에서 걷어냈다 — 2026-08-27

`AppThemeMode.label` 이 한국어 문자열을 들고 있었다. 다국어가 들어오면서 라벨은
ARB 에서 와야 하므로 presentation 확장 `AppThemeModeX.label(context)` 로 옮겼다.
domain 은 저장 형식인 `code` 만 안다 — `AppLanguage` 도 같은 모양이다.
