# theme 테스트 (다크모드)

> [테스트 가이드](../README.md) · [계획](../../features/theme/plan.md) · [기록](../../features/theme/history.md)

```bash
cd app
flutter test test/features/theme
```

## 단위 · 위젯

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
| 앱 수준 (`test/app_theme_mode_test.dart`) | cubit emit | `MaterialApp.themeMode` 가 따라 바뀐다 |

## 알아둘 것

- 앱 수준 테스트는 `DaylogApp` 전체가 아니라 같은 배선을 복제한 최소 하니스를
  쓴다 — 실제 앱은 라우터·Supabase 초기화가 필요해서다. `app.dart` 에서
  `themeMode:` 를 빼는 회귀는 이 테스트가 못 잡는다 ([기록](../../features/theme/history.md)).
- OS 다크 전환(시스템 모드)은 기존 `MaterialApp` 동작이라 따로 테스트하지 않는다.
