# Design system

화면은 Flutter 기본 위젯을 직접 꾸미기보다 아래 공통 진입점을 우선 사용한다. 공통 모양은 `theme/app_theme.dart`에서 관리하고, 화면별 차이는 위젯 인자로만 추가한다.

| 용도 | 사용할 것 | 현재 적용 |
| --- | --- | --- |
| 주요 동작 버튼 | `AppButton.primary` | 로그인, 회원가입, 비밀번호 재설정 |
| 보조 동작 버튼 | `AppButton.secondary` | 회원가입 이동 |
| 낮은 우선순위 동작 | `AppButton.text` | 비밀번호 찾기, 이전 단계 |
| 입력 | `AuthTextField` + `InputDecorationTheme` | 인증 화면 전체 |
| 일시 알림 | `AppSnackBar.show` | 다음 기능 화면에서 사용 준비 |
| 목록 행 | `AppListTile` + `ListTileTheme` | 다음 목록 화면에서 사용 준비 |
| 간격 · 색상 | `AppSpacing`, `AppColors` | 인증 화면 전체 |

예를 들어 기본 버튼 스타일을 유지하면서 화면별로 높이만 바꾸려면 다음처럼 `style`만 전달한다.

```dart
AppButton.primary(
  label: '저장',
  onPressed: save,
  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
)
```
