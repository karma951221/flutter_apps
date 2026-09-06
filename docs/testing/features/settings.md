# 설정 — 테스트 범위

> [테스트 가이드](../README.md) · [아키텍처](../../architecture.md) · [계획](../../features/settings/plan.md)

탈퇴 확인의 개수 조회만 data 계층이 있다. 나머지는 화면과 cubit 뿐이다.

| 대상 | 시나리오 | 기대 결과 |
|---|---|---|
| `SettingsPage` | 목록 | 프로필 편집 · 계정 설정 · 화면 테마 · 언어 · 차단한 사용자 · 로그아웃 여섯 항목을 보여준다. |
| `SettingsPage` | 화면 테마 · 언어 | 다른 feature 가 소유한 상태를 읽어 쓰기만 한다. 표는 [preferences](preferences.md) 에 있다. |
| `SettingsPage` | 상단 요약 | 세션의 닉네임과 이메일을 그대로 보여준다. |
| `SettingsPage` | 세션 없음 | 요약을 그리지 않고 목록만 남는다. |
| `SettingsPage` | 로그아웃 | 확인 다이얼로그(`AppConfirmDialog`, destructive 아님)를 거쳐야 `signOutRequested` 가 나간다. 취소하면 아무 일도 없다. |
| `AccountSettingsPage` | 회원 탈퇴 | 지워질 것을 나열한 확인을 거쳐야 실행된다. 다이얼로그를 띄우거나 취소한 것만으로는 아무것도 지우지 않는다. |
| `AccountSettingsPage` | 탈퇴 실패 | Snackbar 로 알리고 화면에 남는다. |
| `AccountSettingsPage` | 탈퇴 확인 본문 | 게시물·댓글 개수를 넣어 보여준다. 조회가 실패하면 종류만 적은 문구로 탈퇴를 진행한다. |
| `AccountRepositoryImpl` | 개수 조회 / 세션 없음 | 두 개수를 `AccountContentSummary` 로 담는다 / 인증 실패 `Failure` 를 낸다. |
| `DeleteAccountCubit` | 성공 | 진행 중 상태로 남는다 — 세션이 사라져 화면째로 없어지므로 되돌리지 않는다. |
| `DeleteAccountCubit` | 실패 / 중복 호출 | 실패 상태로 남는다 / 진행 중에는 다시 부르지 않는다. |
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

## 로컬 Supabase 로만 확인되는 것

탈퇴의 cascade 범위와 권한 경계는 mock 으로 드러나지 않는다.
[스키마 §3의 `delete_account()`](../../schema.md) 검증 항목을 따른다 — anon 거부,
본인 204, 게시물·댓글·반응 정리, 같은 이메일 재가입.
