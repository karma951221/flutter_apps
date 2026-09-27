# settings — 구현 기록

> [계획](plan.md) · [테스트](testing.md)

이 문서는 2026-08-27 리뷰에서 **소급 작성했다.** feature 는 2026-08-24 에 완료로
표시됐는데 `history.md` 가 없었다 (CLAUDE.md 의 "완료 시 `history.md`"). 커밋에서
읽어낼 수 있는 설계 판단만 적는다 — 당시의 시행착오까지 복원하지는 않았다.

## 설정 · 계정 설정 화면 — 2026-08-24 (commit `060a054`)

- **domain·data 를 만들지 않았다.** 계획대로 presentation 만 둔다. 비밀번호 변경은
  `AuthUseCase.updatePassword` 를 그대로 쓴다 — 설정이 자기 usecase 를 갖는 순간
  "설정도 도메인을 가진 feature" 가 되고, auth 와 능력이 두 벌이 된다.
- **로그아웃이 피드 AppBar 에서 옮겨 왔다.** 하단 내비게이션이 생기면서 화면 밖으로
  나가는 동작을 설정에 모았다 ([아키텍처 3-2](../../../../../docs/architecture.md)).

## 회원 탈퇴 — 2026-08-24 (commit `94ccbdc`)

- **Storage 정리가 계정 삭제보다 먼저다.** 계정을 먼저 지우면 세션이 사라져 Storage
  삭제 정책을 통과할 수 없다. DB 함수는 `storage.objects` 를 지울 수 없어서
  (보호 트리거) 앱이 best-effort 로 치운다.
- 실패해도 탈퇴를 막지 않는다. 남은 객체는 어떤 행과도 이어지지 않아 노출되지 않는다.

## 설정에 붙은 남의 화면들 — 2026-08-25 · 08-26

행은 늘었지만 계층은 늘지 않았다. 셋 다 다른 feature 가 소유하고 설정은 진입점만
갖는다 (규칙 ⑥) — 자세한 것은 [계획의 "이 화면이 빌려 쓰는 것"](plan.md)에 있다.

| 행 | 커밋 | 소유 |
|---|---|---|
| 차단한 사용자 | `72cff42` · `ae7e30c` | `features/safety` |
| 화면 테마 | `cb7472d` | `features/preferences` |
| 언어 | `ccf6542` | `features/preferences` |

## 로그아웃 확인 다이얼로그 — 2026-08-27

`AppConfirmDialog` 로 옮겼다. 다만 **destructive 로 칠하지 않는다**
(`isDestructive: false`) — 다시 로그인하면 그만인 동작까지 error 색으로 칠하면
정말 되돌릴 수 없는 삭제·탈퇴와 구분이 사라진다. 탈퇴는 그대로 destructive 다.

## 탈퇴 확인에 실제 개수 — 2026-09-06

[리뷰](../../../../../ux-psychology-review.md) 6번. 종류만 나열하면 무게가 없다 — 이름과
숫자여야 한다. 이 feature 의 첫 domain/data 조각인 `AccountUseCase.myContentSummary()`
가 게시물·댓글 개수를 세고, 다이얼로그 본문이 "작성한 게시물 14개와 사진 · 남긴 댓글
37개와 감정표현" 이 된다. 개수는 정보이지 압박이 아니라 버튼 문구는 바꾸지 않았다.

겪은 것: `post_comments` 는 컬럼 단위 GRANT(`content` 제외)라 bare `count()`(HEAD,
`select=*`) 가 42501 로 죽는다 — mock 테스트는 전부 통과했고 리뷰어가 로컬 스택으로
잡았다. 댓글은 `post_comments_visible` 뷰(전체 select grant)로 센다. 조회에 실패하면
종류만 적은 문구로 물러서되, 네트워크 오류가 아니면 debug 모드에서 로그를 남긴다.
개수를 읽는 동안 탈퇴 행을 비활성해 두 번 눌러 다이얼로그가 겹치지 않게 했고, 두
count 는 `Future.wait` 로 병렬이다. en 은 ICU plural.
