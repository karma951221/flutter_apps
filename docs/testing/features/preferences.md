# preferences 테스트 (다크모드 · 언어)

> [테스트 가이드](../README.md) · [다크모드 계획](../../features/preferences/plan-theme.md) ·
> [언어 계획](../../features/preferences/plan-language.md) ·
> [기록](../../features/preferences/history.md)

```bash
cd app
flutter test test/features/preferences
```

앱 수준 배선(`MaterialApp` 의 `themeMode` · `locale`)은 feature 폴더 밖에 있다.

```bash
cd app
flutter test test/app_theme_mode_test.dart test/app_locale_test.dart
```

## 다크모드

| 대상 | 시나리오 | 기대 |
|---|---|---|
| `AppThemeMode.fromCode` | `'system'` · `'light'` · `'dark'` | 각 모드 |
| `AppThemeMode.fromCode` | 모르는 값 · `null` | `system` — 저장이 깨져도 앱이 죽지 않는다 |
| `ThemeRepositoryImpl` | 저장 → 읽기 왕복 (`setMockInitialValues`) | 같은 값 |
| `ThemeRepositoryImpl` | 저장값 없음 | `system` |
| `ThemeCubit` | 생성 직후 | 초기 상태 = 저장값 (첫 프레임 무깜빡임의 근거) |
| `ThemeCubit.setMode` | 다른 값 | emit 후 저장 — 순서까지 검증 |
| `ThemeCubit.setMode` | 같은 값 | **no-op** — emit 도 저장도 없음 |
| `SettingsPage` | '화면 테마' 행 | 현재 모드 라벨이 subtitle 에 보인다 |
| `SettingsPage` | 행 탭 | 다이얼로그에 라디오 3개 |
| `SettingsPage` | 선택 | cubit 호출 + 다이얼로그 닫힘 |
| `SettingsPage` | 다이얼로그를 그냥 닫음 | 테마가 그대로다 |
| 앱 수준 (`test/app_theme_mode_test.dart`) | cubit emit | `MaterialApp.themeMode` 가 따라 바뀐다 |

## 언어

| 대상 | 시나리오 | 기대 |
|---|---|---|
| `AppLanguage.fromCode` | `'system'` · `'ko'` · `'en'` · `'ja'` | 각 언어 |
| `AppLanguage.fromCode` | 모르는 값 · `null` | `system` — 테마와 같은 결 |
| `LanguageRepositoryImpl` | 저장 → 읽기 왕복 | 같은 값. 저장값 없으면 `system` |
| `LanguageCubit` | 생성 직후 | 초기 상태 = 저장값 (첫 프레임부터 옳은 언어) |
| `LanguageCubit.setLanguage` | 다른 값 / 같은 값 | emit 후 저장 / **no-op** |
| `SettingsPage` | '언어' 행 | 현재 언어 라벨이 subtitle 에 보이고, 화면 테마 바로 아래에 있다 |
| `SettingsPage` | 행 탭 | 다이얼로그에 라디오 4개. 고르면 즉시 적용되고 닫힌다 |
| `SettingsPage` | 다이얼로그를 그냥 닫음 | 언어가 그대로다 |
| `SettingsPage` | 언어 이름 표기 | 화면 언어가 영어여도 '한국어' · '日本語' 는 자기 표기 그대로다 |
| `SettingsPage` | `en` 으로 뜸 | 설정 화면 문자열이 영어다 |
| 앱 수준 (`test/app_locale_test.dart`) | cubit emit | `MaterialApp.locale` 이 따라 바뀐다. 시스템은 `null` |
| 앱 수준 (`resolveAppLocale`) | 미지원 기기 언어 | 한국어가 아니라 **영어**로 떨어진다 |

## 알아둘 것

- 앱 수준 테스트는 `DaylogApp` 전체가 아니라 같은 배선을 복제한 최소 하니스를
  쓴다 — 실제 앱은 라우터·Supabase 초기화가 필요해서다. `app.dart` 에서
  `themeMode:` 나 `locale:` 을 빼는 회귀는 이 테스트가 못 잡는다
  ([기록](../../features/preferences/history.md)).
- OS 다크 전환(시스템 모드)은 기존 `MaterialApp` 동작이라 따로 테스트하지 않는다.
- 위젯 테스트 하니스는 delegates 와 `locale: Locale('ko')` 를 고정한다. ko 가 ARB
  template 언어라 기존 한국어 단언이 곧 기대값이다
  ([언어 계획의 "테스트 이행"](../../features/preferences/plan-language.md)).
