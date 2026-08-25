# F7 safety(신고·차단) — 테스트 범위

> [테스트 가이드](../README.md) · [아키텍처](../../architecture.md) · [신고 계획](../../features/safety/plan.md) · [차단 계획](../../features/safety/plan-block.md) · [스키마 §12·§13](../../schema.md)

게시물·댓글·사용자 신고 접수와 사용자 차단을 함께 담당한다. 신고 절이 먼저 있고,
차단 절이 그 뒤에 이어진다.

## 신고

| 대상 | 시나리오 | 기대 결과 |
|---|---|---|
| `ReportPolicy.normalizeDetail` | `null` | `null`로 남는다. |
| `ReportPolicy.normalizeDetail` | 빈 문자열 · 공백만 | `null`이 된다. |
| `ReportPolicy.normalizeDetail` | 앞뒤 공백이 있는 문자열 | 다듬어져 저장된다. |
| `ReportPolicy.normalizeDetail` | 최대 길이(500자) 문자열 | 그대로 유지된다. |
| `ReportTargetMapper.toPayload` | `post` · `comment` · `user` 세 변형 | 각각 `target_type` 문자열과 `target_id`로 매핑된다. |
| `SubmitReportScenario` | 앞뒤 공백이 있는 `detail` | 다듬어 저장소에 넘긴다. |
| `SubmitReportScenario` | 공백뿐인 `detail` | `null`로 정규화해 넘긴다. |
| `SubmitReportScenario` | 저장소의 `Err` | 그대로 돌려준다. |
| `ReportRepositoryImpl` | 정상 제출 | `Ok(null)`을 돌려준다. |
| `ReportRepositoryImpl` | `reports_once`(23505) | `ValidationFailure('이미 신고한 항목입니다')`로 변환된다. |
| `ReportRepositoryImpl` | 내 게시물 신고 트리거 문구(P0001) | 같은 문구의 `ValidationFailure`로 변환된다. |
| `ReportCubit` | 사유 선택 | 상태에 반영된다. |
| `ReportCubit` | 사유를 고르지 않음 | `canSubmit`이 `false`다. |
| `ReportSheet` | 열림 | 사유 5개가 모두 보인다. |
| `ReportSheet` | 사유 선택 전 | 제출 버튼이 비활성이다. |
| `ReportSheet` | 상세 설명 입력칸 | 처음부터(사유와 무관하게) 보인다. |
| `ReportSheet` | 제출 성공 | 시트가 닫히고 `show()`가 `true`를 돌려준다. |
| `ReportSheet` | 제출 실패 | 시트가 열려 있고 `Failure.message`가 보인다. |
| `ReportSheet` | 작은 화면 + 키보드로 뜬 bottom inset | `SingleChildScrollView`로 스크롤되어 제출 버튼까지 닿고 누를 수 있다. |

## 진입점(entry point) — `post_tile` · `post_comments_page` · `profile_page`

신고 시트 자체가 아니라 시트를 여는 세 진입점이 `isMine`에 따라 올바른 메뉴 항목을
그리는지를 각 feature의 위젯 테스트로 확인한다. 시트가 있는 이 문서가 자연스러운
기준이다 — 구현은 `features/post` · `features/comment` · `features/profile`에 있지만
검증 대상은 신고 진입점이라서다.

| 대상 | 시나리오 | 기대 결과 |
|---|---|---|
| `PostTile` | 내 글 | 수정 · 삭제가 뜨고 신고는 없다. |
| `PostTile` | 남의 글 | 신고가 뜨고 수정 · 삭제는 없다. |
| `PostTile` | 신고 선택 | `onReport`가 불린다. |
| `PostTile` | 콜백이 모두 `null` | 메뉴 자체가 그려지지 않는다. |
| `PostTile` | 내 글 + `onReport`도 있음 | `isMine`이 최종 판정이라 신고는 뜨지 않는다 (회귀). |
| `PostTile` | 남의 글 + `onEdit`·`onDelete`도 있음 | `isMine`이 최종 판정이라 수정 · 삭제는 뜨지 않는다 (회귀). |
| `PostCommentsPage` | 남의 댓글 메뉴 | 신고가 있다. |
| `PostCommentsPage` | 내 댓글 메뉴 | 삭제가 있고 신고는 없다. |
| `ProfilePage` | 타인 프로필 AppBar | 신고 메뉴가 있다. |
| `ProfilePage` | 내 프로필 AppBar | 메뉴가 없다. |

## 로컬 Supabase로만 확인되는 것 — Step 1 (권한 경계)

[safety 계획서의 완료 조건](../../features/safety/plan.md)을 사용자 A · B 두 계정의
JWT로 REST(PostgREST)에 직접 확인했다.

- `enforce_report_target()` 트리거의 세 분기: 대상 없음 · 내 게시물 · 내 댓글이 각각
  거부되는지 (`security definer`가 `post_comments`의 `author_id`·`deleted_at`을
  읽어 판정한다)
- `reports_not_self_user` CHECK로 자기 자신을 `user`로 신고하는 것이 막히는지
- `reports_once` 유니크로 같은 대상 재신고가 `23505`로 막히는지
- 삭제된 게시물을 대상으로 한 신고가 "존재하는 대상"과 같은 방식으로 거부되는지
- `reporter_id` · `status`를 페이로드에 실어도 컬럼 GRANT가 없어 `42501`로
  거부되는지 (위조 방지가 정책이 아니라 GRANT다)
- `reports_select_own` 정책으로 남의 신고 행이 select에 섞이지 않는지
- 빈 문자열 `detail`을 REST로 직접 보내면 `reports_detail_length`(23514)로
  거부되는지 (앱 경로는 `ReportPolicy.normalizeDetail`이 `null`로 정규화해 애초에
  이 CHECK에 닿지 않는다)

실행:

```bash
cd app
flutter test test/features/safety
```

## 차단

| 대상 | 시나리오 | 기대 결과 |
|---|---|---|
| `BlockedUserDto` | `blocked_users` 뷰 한 행 JSON 파싱 | `id`·`created_at`·`nickname`·`avatar_url`을 읽는다. |
| `BlockedUserDto` | `avatar_url`이 없음 | `null`로 파싱된다. |
| `BlockedUserMapper` | DTO → domain `BlockedUser` | 그대로 옮겨진다. |
| `BlockedUserMapper` | `avatarUrl`이 없음 | `null`로 변환된다. |
| `BlockRepositoryImpl.blockUser` | 정상 차단 | `Ok(null)`을 돌려준다. |
| `BlockRepositoryImpl.blockUser` | 자기 차단(`blocks_not_self`) | `ValidationFailure`로 변환된다. |
| `BlockRepositoryImpl.blockUser` | 중복 차단(`blocks_pkey`) | `ValidationFailure`로 변환된다. |
| `BlockRepositoryImpl.blockUser` | data source의 다른 `Failure` | 변환하지 않고 그대로 반환한다. |
| `BlockRepositoryImpl.unblockUser` | 정상 해제 | `Ok(null)`을 돌려준다. |
| `BlockRepositoryImpl.getBlockedUsers` | 목록 조회 | DTO 목록을 domain `BlockedUser` 목록으로 변환한다. |
| `BlockRepositoryImpl.getBlockedUsers` | 예외 | `SupabaseErrorMapper`로 변환된다. |
| `BlockRepositoryImpl.isBlockedByMe` | 조회 | data source의 결과를 그대로 전달한다. |
| `BlockUserScenario` | 정상 | `repository.blockUser`를 그대로 호출한다. |
| `BlockUserScenario` | 저장소의 `Err` | 그대로 돌려준다. |
| `UnblockUserScenario` | 정상 | `repository.unblockUser`를 그대로 호출한다. |
| `UnblockUserScenario` | 저장소의 `Err` | 그대로 돌려준다. |
| `GetBlockedUsersScenario` | 정상 | `repository.getBlockedUsers`의 결과를 그대로 돌려준다. |
| `GetBlockedUsersScenario` | 저장소의 `Err` | 그대로 돌려준다. |
| `IsBlockedByMeScenario` | 정상 | `repository.isBlockedByMe`의 결과를 그대로 돌려준다. |
| `IsBlockedByMeScenario` | 저장소의 `Err` | 그대로 돌려준다. |
| `BlockedUsersPage` | 빈 목록 | "차단한 사용자가 없습니다" 안내를 보여준다. |
| `BlockedUsersPage` | 정상 목록 | 각 행에 닉네임과 '차단 해제' 버튼이 함께 보인다. |
| `BlockedUsersPage` | 조회 실패 | 오류와 다시 시도 버튼을 보여준다. |
| `BlockedUsersPage` | 차단 해제 성공 | 그 행이 목록에서 사라지고 성공 스낵바가 뜬다. |
| `BlockedUsersPage` | 차단 해제 실패 | 행이 그대로 남고 오류 스낵바가 뜬다. |
| `BlockActionCubit` | 상태 조회 성공 · 실패 | 내가 건 차단 여부를 담고, 실패 시 메뉴가 판단하지 못하도록 `null`과 `failure`를 담는다. |
| `BlockActionCubit` | 차단 · 차단 해제 성공 | `isBlocked`가 각각 `true` · `false`로 전환된다. |
| `BlockActionCubit` | 동작 실패 | 기존 차단 상태를 유지하고 `failure`를 전달한다. |

### 진입점(entry point) — `post_tile`

Task 3a에서 게시물 메뉴에 붙인 차단 진입점이다. 신고 진입점과 같은 파일
(`post_tile_test.dart`)에서 함께 검증한다 — `isMine`이 신고·차단·수정·삭제 중
무엇을 그릴지 정하는 같은 판정이라서다.

| 대상 | 시나리오 | 기대 결과 |
|---|---|---|
| `PostTile` | 남의 글 | 신고와 함께 '이 사용자 차단'이 뜬다. |
| `PostTile` | 내 글 + `onBlock`도 있음 | `isMine`이 최종 판정이라 '이 사용자 차단'은 뜨지 않는다 (회귀). |
| `PostTile` | 차단 선택 | `onBlock`이 불린다. |

### 진입점(entry point) — `profile_page`

| 대상 | 시나리오 | 기대 결과 |
|---|---|---|
| `ProfilePage` | 타인 프로필 AppBar + 차단 상태 | '차단' 또는 '차단 해제' 중 하나와 신고가 보인다. |
| `ProfilePage` | 내 프로필 AppBar | 차단 관련 메뉴가 없다. |
| `ProfilePage` | 상태 조회 실패 | 차단 관련 메뉴를 숨기고 신고는 남긴다. |
| `ProfilePage` | 차단 · 차단 해제 선택 | 확인 뒤 실행하고 성공하면 프로필 게시물 목록을 다시 읽는다. |

## 로컬 Supabase로만 확인되는 것 — 차단 (2026-08-25, Task 5)

[차단 계획서의 완료 조건 12개](../../features/safety/plan-block.md)를 사용자 A·B
두 계정의 JWT로 REST(PostgREST)에 직접 확인했다. `postgres` 슈퍼유저 세션은 RLS를
우회하므로 이 검증에는 쓰지 않았다 — 정리(cleanup)에만 썼다.

| # | 확인 | 방법 | 실제 결과 |
|---|---|---|---|
| 1 | A가 B를 차단하면 A의 피드에서 B의 게시물이 사라진다 | A의 JWT로 B의 게시물을 `posts_with_author`에서 조회 | `[]` |
| 2 | **B의 피드에서도 A의 게시물이 사라진다(양방향)** | **B의 JWT**로 A의 게시물을 `posts_with_author`에서 조회 | `[]` |
| 3 | 차단된 사용자의 댓글이 목록에서 사라지고 `comment_count`에서도 빠진다 | A의 게시물에 B가 댓글 2개·A가 1개 작성 → 차단 전 `comment_count:3` → 차단 후 A의 JWT로 재조회 | `comment_count:1`, 실제 `post_comments_visible` 목록도 A의 댓글 1건만 반환 — 개수와 목록 일치 |
| 4 | 답글만 남은 부모 댓글은 되살아나지 않는다 | A가 부모 댓글 작성 → B가 답글 작성 → A가 부모를 소프트 삭제(`soft_delete_post_comment`) → 차단 전 목록엔 부모가 `content:null, reply_count:1`로 되살아남 → A가 B를 차단한 뒤 재조회 | 부모 행이 목록에서 완전히 사라짐(빈 배열 아님, 해당 부모 id 자체가 없음) |
| 5 | B가 A의 게시물에 댓글을 다는 삽입이 거부된다 | B의 JWT로 A의 게시물에 `post_comments` 삽입 | `403`, `{"code":"42501","message":"이 게시물에는 댓글을 달 수 없습니다"}` (원래 문구 `차단한 사용자의 게시물에는 댓글을 달 수 없습니다`는 이 예외를 실제로 보는 B에게 방향이 거꾸로였고 차단 사실까지 드러냈다 — 최종 검토에서 `20260825130000_neutral_block_message.sql`로 방향 중립 문구로 교체) |
| 6 | 자기 자신 차단이 거부된다 | A의 JWT로 `blocked_id=A자신` 삽입 | `400`, `{"code":"23514", message: blocks_not_self 위반}` |
| 7 | 같은 사람 중복 차단이 거부된다 | A가 B를 이미 차단한 상태에서 다시 삽입 | `409`, `{"code":"23505", message: blocks_pkey 위반}` |
| 8 | `blocker_id` 위조가 거부된다 | B의 JWT로 `{"blocker_id":"<A의 id>","blocked_id":"<B의 id>"}` 삽입 | `403`, `{"code":"42501","message":"permission denied for table blocks"}` (INSERT GRANT가 `blocked_id`컬럼에만 있다) |
| 9 | 남의 차단 목록은 조회되지 않는다 | B의 JWT로 `blocks` 테이블 전체 select | `[]` (`blocks_select_own`이 `blocker_id = auth.uid()`만 보여준다 — A가 건 차단 행은 B에게 보이지 않는다) |
| 10 | 차단 해제하면 양쪽 모두 다시 보인다 | A가 `DELETE /blocks?blocked_id=eq.B`로 해제 → 양쪽 JWT로 서로의 게시물 재조회, `comment_count` 재조회, 되살아난 부모 댓글 재조회 | 양쪽 게시물 모두 다시 보임, `comment_count` 3으로 복구, 부모 댓글이 `content:null, reply_count:1`로 다시 보임 |
| 11 | 차단한 사용자의 프로필은 여전히 열린다 | 차단 상태에서 A의 JWT로 `profiles?id=eq.B` 조회 | `[{"id":..., "nickname":"user_..."}]` — 정상 조회. AppBar 메뉴 전환은 위젯 테스트로 확인한다. |
| 12 | 비로그인 조회가 차단 필터의 영향을 받지 않는다 | 차단이 걸린 상태에서 `apikey`만 쓰고 `Authorization` 없이 (anon) A·B의 게시물을 함께 조회 | 둘 다 보임 |
| 참고 | 감정표현 삽입도 차단의 영향을 받는다(스펙 대비 DB가 더 엄격, [스키마 §10](../../schema.md) 참고) | B의 JWT로 차단된 A의 게시물에 `post_reactions` 삽입 | `403`, `new row violates row-level security policy for table "post_reactions"` |

### 환경 · JWT 획득

- `supabase status`(저장소 루트) → `API_URL=http://127.0.0.1:54321`.
- anon key로 `/auth/v1/token?grant_type=password`를 사용자 A·B 계정으로 각각
  호출해 `access_token`을 받았다(로컬은 이메일 확인 없이 즉시 로그인된다).
- 이후 모든 `/rest/v1/...` 호출은 `apikey: <anon key>` + `Authorization: Bearer
  <access_token>`으로 A 또는 B로 인증해 보냈다.
- `content` 컬럼에 SELECT GRANT가 없어(§8) `post_comments` 삽입은
  `Prefer: return=minimal`로 하고 `post_comments_visible` 뷰로 id를 다시 읽었다 —
  신고 검증(task-6-report)과 같은 요령이다.

### 정리(cleanup)

검증에 쓴 모든 데이터를 `postgres` 슈퍼유저 세션으로 삭제했다.

```sql
delete from public.blocks where blocker_id in (
  select id from auth.users where email in ('safety-a-t5@example.com','safety-b-t5@example.com')
) or blocked_id in (
  select id from auth.users where email in ('safety-a-t5@example.com','safety-b-t5@example.com')
);
delete from public.post_reactions where post_id in (select id from public.posts where content like 'safety task5%');
delete from public.post_comments where content like 'safety t5%';
delete from public.posts where content like 'safety task5%';
delete from auth.users where email in ('safety-a-t5@example.com','safety-b-t5@example.com');
```

삭제 후 재확인: `auth.users`에 두 테스트 이메일 0건, `posts`에 `safety task5%` 0건,
`post_comments`에 `safety t5%` 0건, `blocks` 0건. `auth.users` 삭제가 `profiles`
(FK `on delete cascade`)·`posts`·`post_comments`·`blocks`를 함께 정리한다. 로컬
DB에는 이 세션이 만든 데이터가 남아 있지 않다.

실행:

```bash
cd app
flutter test test/features/safety
```
