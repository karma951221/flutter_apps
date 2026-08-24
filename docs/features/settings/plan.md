# 설정 — 계획 (화면 · 범위)

> [문서 허브](../../README.md) · [기획](../../overview.md) · [아키텍처](../../architecture.md) · [테스트](../../testing/features/settings.md)

> 상태: **완료** · 작성 2026-08-24 · 진행 상태의 단일 기준은 [진행 현황](../../status.md)이다.

## 범위

앱을 쓰는 데 필요한 관리 동작을 한곳에 모은다. 프로필 편집으로 보내고, 계정 자체를
다루는 동작(비밀번호 변경 · 회원 탈퇴)을 두고, 로그아웃한다.

이 feature 에는 **presentation 만 있다.** 도메인 능력은 이미 auth 와 profile 이
갖고 있고, 설정 화면은 그것들을 모아 보여주는 자리다. 새 usecase 를 만들지 않았다.

## 확정한 결정과 근거

| 항목 | 결정 | 근거 |
|---|---|---|
| feature 위치 | `features/settings` 를 새로 만든다 | 화면의 주인이 auth 도 profile 도 아니다. 두 곳 중 하나에 끼워 넣으면 그 feature 가 "설정 화면도 갖고 있는" 상태가 된다 |
| 계층 | presentation 만 | 도메인 능력을 다시 만들지 않는다. `AuthUseCase.updatePassword` 를 그대로 쓴다 |
| 프로필 편집 | 설정에서 **보내기만** 한다 | 편집 화면과 상태는 profile feature 가 소유한다 ([규칙 ⑥](../../architecture.md)) |
| 비밀번호 변경 | 지금 비밀번호를 **다시 묻지 않는다** | 로그인한 세션으로만 들어오는 화면이고 Supabase 의 교체가 세션을 근거로 동작한다. 세션 없이 바꾸는 경로는 auth 의 재설정(코드 검증)이 맡는다 |
| 회원 탈퇴 | 항목은 두고 **"준비 중" 안내만** | 되돌릴 수 없는 동작이라 정책(데이터 정리 범위·유예 기간)이 정해지기 전에는 어떤 삭제 코드도 두지 않는다. 항목을 감추면 탈퇴 경로가 없다고 오해한 사용자가 계정을 방치한다 |
| 로그아웃 위치 | 피드 AppBar 에서 **설정으로 옮김** | 하단 내비게이션이 생기면서 화면 밖으로 나가는 동작은 설정에 모으는 편이 찾기 쉽다 |

## 화면

| 경로 | 화면 | 내용 |
|---|---|---|
| `/settings` | `SettingsPage` | 세션 요약(아바타·닉네임·이메일) + 프로필 편집 · 계정 설정 · 로그아웃 |
| `/settings/account` | `AccountSettingsPage` | 비밀번호 변경 · 회원 탈퇴(준비 중) |
| `/settings/account/password` | `ChangePasswordPage` | 새 비밀번호 · 확인 두 칸 |

`SettingsPage` 는 하단 내비게이션의 세 번째 탭 본문이기도 하다. 셸 구조는
[아키텍처의 내비게이션 절](../../architecture.md)에 있다.

### 상태

- `SettingsPage` · `AccountSettingsPage` 는 상태를 갖지 않는다. 세션 요약은
  `AuthBloc` 의 값을 그대로 읽는다.
- `ChangePasswordPage` 만 `ChangePasswordCubit` 을 갖는다. 길이·일치 검증은 화면에서
  끝내고(서버 왕복 전에 막는다), 저장은 `AuthUseCase.updatePassword` 한 번이다.
- 로그아웃은 확인 다이얼로그 뒤 `AuthEvent.signOutRequested` 를 보낸다. 로그인
  화면으로 되돌리는 일은 라우터의 redirect 가 한다 — 화면이 직접 이동하지 않는다.

## 완료 조건

- [x] 설정에서 프로필 편집 · 계정 설정 · 로그아웃으로 갈 수 있다
- [x] 로그아웃은 확인을 거쳐야 실행된다
- [x] 비밀번호를 바꾸고, 두 칸이 어긋나면 저장을 시도하지 않는다
- [x] 회원 탈퇴는 안내만 하고 아무것도 지우지 않는다

## 범위 밖

- **회원 탈퇴 실제 구현** — Supabase Auth 사용자 삭제와 데이터 정리(게시물·댓글·반응·
  Storage 객체) 정책이 필요하다. `soft_delete_post` 처럼 `security definer` 함수 하나로
  묶을지, 유예 기간을 둘지 함께 정한다
- 알림 설정 · 테마 전환 · 언어 — 각각 저장할 곳(로컬 or 서버)을 먼저 정해야 한다
- 차단 목록 관리 — F7 이 생긴 뒤 이 화면에 붙인다
