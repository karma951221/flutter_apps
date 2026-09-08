# 설정 — 계획 (화면 · 범위)

> [문서 허브](../../README.md) · [기획](../../overview.md) · [아키텍처](../../architecture.md) · [테스트](../../testing/features/settings.md)

> 상태: **완료** · 작성 2026-08-24 · 갱신 2026-09-06
> 진행 상태의 단일 기준은 [진행 현황](../../status.md)이다.

## 범위

앱을 쓰는 데 필요한 관리 동작을 한곳에 모은다. 프로필 편집으로 보내고, 계정 자체를
다루는 동작(비밀번호 변경 · 회원 탈퇴)을 두고, 로그아웃한다.

이 feature 는 거의 **presentation 만 있다.** 도메인 능력은 이미 auth 와 profile 이
갖고 있고, 설정 화면은 그것들을 모아 보여주는 자리다. 예외는 탈퇴 확인에 넣을
게시물·댓글 개수 조회 하나뿐이다 (아래 "이 feature 가 소유하는 data").

## 확정한 결정과 근거

| 항목 | 결정 | 근거 |
|---|---|---|
| feature 위치 | `features/settings` 를 새로 만든다 | 화면의 주인이 auth 도 profile 도 아니다. 두 곳 중 하나에 끼워 넣으면 그 feature 가 "설정 화면도 갖고 있는" 상태가 된다 |
| 계층 | presentation 위주 | 도메인 능력을 다시 만들지 않는다. `AuthUseCase.updatePassword` 를 그대로 쓴다. 탈퇴 확인의 개수 조회만 이 feature 가 domain·data 를 갖는다 |
| 프로필 편집 | 설정에서 **보내기만** 한다 | 편집 화면과 상태는 profile feature 가 소유한다 ([규칙 ⑥](../../architecture.md)) |
| 비밀번호 변경 | 지금 비밀번호를 **다시 묻지 않는다** | 로그인한 세션으로만 들어오는 화면이고 Supabase 의 교체가 세션을 근거로 동작한다. 세션 없이 바꾸는 경로는 auth 의 재설정(코드 검증)이 맡는다 |
| 회원 탈퇴 | **즉시 삭제**, 유예 기간 없음 | 토이 프로젝트에 복구 창구(고객센터)가 없어 유예 기간이 의미를 갖지 못한다. 삭제 경로는 DB 함수 `delete_account()` 하나다 ([스키마 §3](../../schema.md)) |
| 탈퇴 확인 | 지워질 것을 나열한 다이얼로그 한 번 | 비밀번호 재입력은 이 화면까지 오는 데 이미 세션이 필요해 검증 가치가 없다. 대신 무엇이 지워지는지 구체적으로 보여준다 |
| Storage 정리 | 앱이 탈퇴 **전에** best-effort | DB 가 storage.objects 를 지울 수 없다(보호 트리거). 계정을 먼저 지우면 세션이 사라져 삭제 정책을 통과할 수 없으므로 순서가 반대다 |
| 로그아웃 위치 | 피드 AppBar 에서 **설정으로 옮김** | 하단 내비게이션이 생기면서 화면 밖으로 나가는 동작은 설정에 모으는 편이 찾기 쉽다 |

## 화면

| 경로 | 화면 | 내용 |
|---|---|---|
| `/settings` | `SettingsPage` | 세션 요약(아바타·닉네임·이메일) + 프로필 편집 · 계정 설정 · 화면 테마 · 언어 · 차단한 사용자 · 로그아웃 |
| `/settings/account` | `AccountSettingsPage` | 비밀번호 변경 · 회원 탈퇴 |
| `/settings/account/password` | `ChangePasswordPage` | 새 비밀번호 · 확인 두 칸 |

`SettingsPage` 는 하단 내비게이션의 **다섯 번째(마지막) 탭** 본문이기도 하다
(투자 · 홈 · 채팅 · 프로필 · 설정). 셸 구조는
[아키텍처의 내비게이션 절](../../architecture.md)에 있다.

### 상태

- `SettingsPage` 는 자기 상태를 갖지 않는다. 세션 요약은 `AuthBloc` 의 값을 그대로
  읽고, 테마·언어 행은 앱 루트가 만든 `ThemeCubit` · `LanguageCubit` 을 읽어 쓴다
  (여기서 새로 만들지 않는다).
- `AccountSettingsPage` 는 `DeleteAccountCubit` 을 만들어 탈퇴 실행만 소유한다.
  확인 다이얼로그와 그 앞의 개수 조회는 화면이 하고, cubit 이 불렸다는 것은 이미
  확인을 거쳤다는 뜻이다. 성공은 듣지 않는다 — 세션이 사라지면 라우터가 로그인
  화면으로 보낸다.
- `ChangePasswordPage` 만 `ChangePasswordCubit` 을 갖는다. 길이·일치 검증은 화면에서
  끝내고(서버 왕복 전에 막는다), 저장은 `AuthUseCase.updatePassword` 한 번이다.
- 로그아웃은 확인 다이얼로그 뒤 `AuthEvent.signOutRequested` 를 보낸다. 로그인
  화면으로 되돌리는 일은 라우터의 redirect 가 한다 — 화면이 직접 이동하지 않는다.
- 탈퇴 확인은 열기 전에 `AccountUseCase.myContentSummary` 로 내 게시물·댓글 개수를
  읽어 본문에 넣는다. 조회에 실패하면 종류만 적은 문구로 물러선다. 개수는 정보이지
  압박이 아니다 — 버튼 문구는 바꾸지 않는다

## 완료 조건

- [x] 설정에서 프로필 편집 · 계정 설정 · 로그아웃으로 갈 수 있다
- [x] 로그아웃은 확인을 거쳐야 실행된다
- [x] 비밀번호를 바꾸고, 두 칸이 어긋나면 저장을 시도하지 않는다
- [x] 회원 탈퇴가 계정·프로필·게시물·댓글·반응을 지우고, 같은 이메일로 재가입할 수 있다
- [x] 탈퇴는 지워질 것을 보여주는 확인을 거쳐야 실행된다

## 이 feature 가 소유하는 data

`AccountRepository.myContentSummary()` 하나. `posts` 와 `post_comments_visible` 에
`count` HEAD 요청 두 번(`author_id = 나`, `deleted_at is null`)을 함께 던진다.
새 테이블·뷰는 없다.

댓글을 `post_comments` 가 아니라 뷰로 세는 이유: 테이블 쪽 SELECT GRANT 는
`content` 를 뺀 컬럼 목록이라([스키마 §8](../../schema.md)), `select` 파라미터가
없는 count HEAD 요청이 `select=*` 로 평가돼 42501 로 거부된다.
`post_comments_visible`(§9)은 뷰 전체에 `grant select` 가 걸려 있고 `author_id` ·
`deleted_at` 을 그대로 내려준다. 뷰는 삭제된 게시물의 댓글과 차단 관계의 행을
이미 제외하므로, 세는 값은 "지금 남에게 보이는 내 댓글" 이다.

## 이 화면이 빌려 쓰는 것

설정 탭은 행을 늘리되 계층은 늘리지 않는다. 아래 셋은 **다른 feature 가 소유한
상태·화면**이고 설정은 진입점만 갖는다 (규칙 ⑥).

| 행 | 소유 | 문서 |
|---|---|---|
| 화면 테마 | `features/preferences` 의 `ThemeCubit` | [다크모드 계획](../preferences/plan-theme.md) |
| 언어 | `features/preferences` 의 `LanguageCubit` | [언어 계획](../preferences/plan-language.md) |
| 차단한 사용자 | `features/safety` 의 `BlockedUsersPage` (`/settings/blocked`) | [차단 계획](../safety/plan-block.md) |

## 범위 밖

- 탈퇴 유예 기간 · 탈퇴 사유 수집 — 필요해지면 `DeleteAccountScenario` 에 흐름을 더한다
- 알림 설정 — 저장할 곳(로컬 or 서버)을 먼저 정해야 한다

> ~~테마 전환 · 언어~~ 와 ~~차단 목록 관리~~ 는 이 목록에 있었지만 전부
> 구현됐다. 위의 "이 화면이 빌려 쓰는 것" 표로 옮겼다 (2026-08-27 갱신).
