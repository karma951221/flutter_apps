# 설정 — 테스트 범위

> [테스트 가이드](../README.md) · [아키텍처](../../architecture.md) · [계획](../../features/settings/plan.md)

presentation 만 있는 feature 라 테스트도 화면과 cubit 뿐이다.

| 대상 | 시나리오 | 기대 결과 |
|---|---|---|
| `SettingsPage` | 목록 | 프로필 편집 · 계정 설정 · 로그아웃 세 항목을 보여준다. |
| `SettingsPage` | 상단 요약 | 세션의 닉네임과 이메일을 그대로 보여준다. |
| `SettingsPage` | 세션 없음 | 요약을 그리지 않고 목록만 남는다. |
| `SettingsPage` | 로그아웃 | 확인 다이얼로그를 거쳐야 `signOutRequested` 가 나간다. 취소하면 아무 일도 없다. |
| `AccountSettingsPage` | 회원 탈퇴 | "준비 중" 안내만 띄운다. **삭제 요청을 보내지 않는다.** |
| `ChangePasswordCubit` | 성공 | 진행 중 → 성공으로 전이하고 `AuthUseCase.updatePassword` 를 한 번 부른다. |
| `ChangePasswordCubit` | 실패 | 실패 상태로 남고 화면이 문구를 띄운다. |
| `ChangePasswordPage` | 두 칸 불일치 | 저장을 시도하지 않는다. 서버에 갔다 와서 실패하는 것보다 빠르다. |
| `ChangePasswordPage` | 길이 미달 | 저장을 시도하지 않는다 (`Validators.password`). |
| `ChangePasswordPage` | 성공 | Snackbar 로 알리고 이전 화면으로 돌아간다. |

실행:

```bash
cd app
flutter test test/features/settings
```
