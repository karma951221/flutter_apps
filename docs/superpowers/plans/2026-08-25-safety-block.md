# F7 safety — 차단 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 사용자를 차단하면 서로의 게시물·댓글이 보이지 않고, 차단당한 쪽은 댓글을 달 수 없다. 차단 목록에서 해제한다.

**Architecture:** 차단 판정의 정의를 `is_blocked_with(uuid)` 함수 하나에 두고, 조회 정책 둘(`posts` · `post_comments`) · 뷰 하나(`post_comments_visible`) · 트리거 하나(`enforce_comment_depth`)가 모두 그것을 부른다. `posts_with_author` 는 `security_invoker = on` 이라 정책을 물려받으므로 손대지 않는다. 앱은 `features/safety` 에 `BlockRepository` 를 더하고 facade 는 `SafetyUseCase` 하나를 유지한다.

**Tech Stack:** Flutter · bloc/cubit · freezed 3 · json_serializable · get_it + injectable · supabase_flutter · PostgreSQL(로컬 Supabase) · mocktail · bloc_test

**스펙 (요구사항의 단일 기준):** [docs/features/safety/plan-block.md](../../../apps/trader/docs/features/safety/plan-block.md)

## Global Constraints

[신고 계획](2026-08-24-safety-report.md)의 Global Constraints 를 모두 그대로 승계한다. 이번 작업에만 해당하는 것을 더한다.

- **이번 작업은 이미 동작하는 조회 경로를 바꾼다.** 피드 · 댓글 목록 · 프로필 목록이 회귀 대상이다. **기존 테스트가 깨지면 그것이 신호다** — 통과시키려고 단언을 약화하지 말고, 왜 깨졌는지 먼저 판단한다
- **차단 판정의 정의는 `is_blocked_with()` 한 곳이다.** 정책 · 뷰 · 트리거 어디에도 `blocks` 를 직접 읽는 조건을 새로 쓰지 않는다
- **`posts_with_author` 뷰 정의를 고치지 않는다.** `security_invoker = on` 이라 `posts` 정책이 그대로 걸린다. 뷰를 고치면 필터가 두 곳이 된다
- **비로그인(`anon`) 조회는 차단 필터의 영향을 받지 않아야 한다.** `auth.uid()` 가 `null` 인 경로를 항상 확인한다
- **차단 사실을 상대에게 알리지 않는다.** 오류 문구·UI 어디에도 "차단당했습니다"가 나오면 안 된다
- **DB 값과 앱 상수 일치**: 차단 거부 문구는 트리거의 `raise` 와 `SupabaseErrorMapper` 양쪽에서 같은 문자열

**검증 명령:**

```bash
supabase db reset          # 리포지터리 루트
cd app && flutter analyze
cd app && flutter test
```

---

### Task 1: 차단 스키마 — 테이블 · 판정 함수 · 정책 변경 · 뷰 재정의

**Files:**
- Create: `supabase/migrations/20260825120000_add_blocks.sql`
- Modify: `docs/schema.md` (§1 관계, §5 `posts` RLS, §6 앞으로 붙는 것, §8 `post_comments` RLS·트리거, §9 뷰, 새 절 `blocks` · `blocked_users`)

**Interfaces:**
- Consumes: `public.profiles` · `public.posts` · `public.post_comments` · `public.enforce_comment_depth()`
- Produces: `public.blocks`, `public.is_blocked_with(uuid) → boolean`, `public.blocked_users` 뷰, 변경된 정책 2개 · 뷰 1개 · 트리거 함수 1개

**먼저 읽을 것.** 이 태스크는 기존 객체를 **재정의**한다. 아래를 그대로 읽고 시작한다.
- `supabase/migrations/20260823170000_add_post_comments.sql` — `enforce_comment_depth()` 원본과 정책
- `supabase/migrations/20260823180000_add_reactions.sql` — `post_comments_visible` 의 **최신** 정의 (반응 집계가 붙은 판)
- `docs/schema.md` §5 · §6 · §8 · §9

`create or replace view` 는 컬럼을 빼거나 순서를 바꿀 수 없다. 최신 정의를 그대로 가져와 `where` 와 두 서브쿼리에만 조건을 더한다.

- [ ] **Step 1: 테이블과 판정 함수**

[스펙](../../../apps/trader/docs/features/safety/plan-block.md)의 `blocks` DDL · `blocks_blocked_idx` · `is_blocked_with()` 를 그대로 쓴다. 함수는 `language sql` · `stable` · `security definer` · `set search_path = ''` 넷을 모두 갖춰야 한다.

- [ ] **Step 2: 조회 정책 둘을 바꾼다**

```sql
alter policy "posts_select_visible" on public.posts
  using (deleted_at is null and not public.is_blocked_with(author_id));

alter policy "post_comments_select_visible" on public.post_comments
  using (deleted_at is null and not public.is_blocked_with(author_id));
```

정책 이름이 다르면 실제 이름을 쓴다 — 위 두 마이그레이션에서 확인한다.

- [ ] **Step 3: `post_comments_visible` 재정의**

최신 정의를 가져와 세 곳에 조건을 넣는다 ([스펙](../../../apps/trader/docs/features/safety/plan-block.md)의 표).

1. 본문 `where` 의 `c.deleted_at is null` 갈래와 부모 되살리기 갈래를 **모두** 감싸도록 `and not public.is_blocked_with(c.author_id)` 를 건다
2. `reply_count` 서브쿼리에 `and not public.is_blocked_with(reply.author_id)`
3. "살아 있는 답글이 있는가" `exists` 에도 같은 조건

**셋 중 하나라도 빠지면 개수와 목록이 어긋난다.** 답글 3개로 표시되는데 펼치면 1개가 나오는 식이다.

- [ ] **Step 4: `enforce_comment_depth()` 에 차단 검사 추가**

원본을 `create or replace` 하고, **부모 검사보다 먼저** 게시물 작성자 검사를 넣는다. `new.post_id` 의 작성자가 나와 차단 관계면 거부한다.

```text
차단한 사용자의 게시물에는 댓글을 달 수 없습니다
```

정책이 아니라 트리거인 이유는 [스펙](../../../apps/trader/docs/features/safety/plan-block.md)에 있다 — 정책 안에서 `posts` 를 읽으면 방금 넣은 차단 필터에 걸려 행이 사라지고, `is_blocked_with(null)` 이 `false` 라 삽입이 도리어 허용된다. 주석으로 이 함정을 남긴다.

기존 검사 네 가지(부모 존재 · 답글의 답글 · 같은 게시물 · 삭제된 부모)를 **하나도 잃지 않는다.**

- [ ] **Step 5: `blocked_users` 뷰 · RLS · GRANT**

[스펙](../../../apps/trader/docs/features/safety/plan-block.md) 그대로. 뷰는 `security_invoker = on` 이라 `where` 가 필요 없다 — 정책이 걸러 준다.

- [ ] **Step 6: 적용과 검증**

`supabase db reset` 후 `docker exec -u postgres supabase_db_socialapp psql -U postgres -d postgres` 로 확인한다.

| 확인 | 기대 |
|---|---|
| `\d public.blocks` | 복합 PK · `blocks_not_self` · `blocks_blocked_idx` |
| `\df public.is_blocked_with` | `stable` · `security definer` |
| `\d+ public.posts` · `post_comments` | 두 정책의 `using` 에 `is_blocked_with` 가 보인다 |
| `\d+ public.post_comments_visible` | 세 곳 모두에 조건이 들어갔다 |
| 자기 차단 | `23514` (`blocks_not_self`) |
| 중복 차단 | `23505` (PK) |

**앱 테스트가 깨지지 않는지도 본다** — `cd app && flutter test`. 깨지면 이 태스크의 회귀다.

- [ ] **Step 7: `docs/schema.md` 갱신 · 커밋**

§5 · §8 의 RLS 절에 바뀐 `using` 을 반영하고, §6 "앞으로 여기에 붙는 것"에서 차단 필터를 **붙었다**로 옮기되 정책에 넣었으므로 뷰는 그대로임을 적는다. §9 의 "F7 차단 필터가 붙을 자리" 부채를 해소된 것으로 고친다. 새 절로 `blocks` 와 `blocked_users` 를 더한다. `is_blocked_with()` 는 §3 공통 함수에 넣는다.

```
feat(db): 차단 테이블과 양방향 가시성 필터를 만든다
```

**Verification:**
- [ ] `supabase db reset` 이 오류 없이 끝난다
- [ ] Step 6 의 표를 모두 확인하고 결과를 report 에 적었다
- [ ] `cd app && flutter test` 가 여전히 통과한다
- [ ] `cd app && flutter test test/convention` 이 통과한다

---

### Task 2: `features/safety` — 차단 domain · data · DI

**Files:**
- Create: `app/lib/features/safety/domain/entity/blocked_user.dart`
- Create: `app/lib/features/safety/domain/repository/block_repository.dart`
- Create: `app/lib/features/safety/domain/usecase/scenario/{block_user,unblock_user,get_blocked_users,is_blocked}_scenario.dart`
- Create: `app/lib/features/safety/data/dto/blocked_user_dto.dart`
- Create: `app/lib/features/safety/data/datasource/{block_data_source,supabase_block_data_source}.dart`
- Create: `app/lib/features/safety/data/mapper/blocked_user_mapper.dart`
- Create: `app/lib/features/safety/data/repository/{block_repository_impl,block_repository_error_handler}.dart`
- Modify: `app/lib/features/safety/domain/usecase/safety_use_case.dart`
- Modify: `app/lib/core/data/mapper/supabase_error_mapper.dart`
- Create/Modify: 대응하는 `app/test/features/safety/...` 전부

**Interfaces:**
- Consumes: Task 1 의 `blocks` · `blocked_users`
- Produces: `SafetyUseCase.blockUser` · `unblockUser` · `getBlockedUsers` · `isBlocked`

- [ ] **Step 1: domain**

`BlockedUser` 는 Freezed Primary Constructor: `{ String id, String nickname, String? avatarUrl, DateTime blockedAt }`.

`BlockRepository` 는 네 메서드다 ([스펙](../../../apps/trader/docs/features/safety/plan-block.md)의 표). **`ReportRepository` 를 건드리지 않는다** — 저장소는 테이블 하나의 관심사를 담당한다.

시나리오 넷은 각각 얇다. `@injectable` 을 붙이지 않는 일반 클래스다.

- [ ] **Step 2: `SafetyUseCase` 확장**

기존 `submit` 을 유지한 채 넷을 더한다. 생성자는 이제 `ReportRepository` 와 `BlockRepository` 둘을 받는다.

- [ ] **Step 3: data**

`supabase_block_data_source.dart`:

| 동작 | 질의 |
|---|---|
| 차단 | `insert into blocks {blocked_id}` — `blocker_id` 는 보내지 않는다 (GRANT 에 없다) |
| 해제 | `delete from blocks where blocked_id = ?` — `blocker_id` 조건은 정책이 건다 |
| 목록 | `select * from blocked_users order by created_at desc` |
| 상태 | `select blocked_id from blocks where blocked_id = ?` 의 존재 여부 |

`blocked_user_dto.dart` 는 json_serializable 을 쓰고, 컬럼은 `id` · `nickname` · `avatar_url` · `created_at` 이다. mapper 가 `blockedAt` 으로 옮긴다. 기존 `profile` · `feed` 의 DTO·mapper 모양을 따른다.

- [ ] **Step 4: `SupabaseErrorMapper` 에 차단 문구 등록**

`_reportTargetMessages` 옆에 트리거 문구 목록을 더한다.

```dart
  /// `enforce_comment_depth()` 가 차단 때 던지는 문구.
  static const _blockMessages = ['차단한 사용자의 게시물에는 댓글을 달 수 없습니다'];
```

`blocks_not_self` (자기 차단) 와 PK 중복(이미 차단함)도 등록한다. 중복 차단 문구는
**사용자에게 보여줄 일이 거의 없다** — UI 가 이미 '차단 해제'를 그리고 있을 테니 —
그래도 등록해 둔다.

- [ ] **Step 5: 코드 생성 · 테스트**

`dart run build_runner build --delete-conflicting-outputs`.

테스트는 시나리오 넷, mapper, repository(성공·실패 매핑), DTO 를 덮는다. 기존
`test/features/safety/` 와 `test/features/profile/data/` 의 모양을 따른다.

- [ ] **Step 6: 커밋** — `feat(safety): 차단 domain 과 data 계층을 만든다`

**Verification:**
- [ ] `flutter analyze` 무경고 · `flutter test` 전체 통과
- [ ] `injection.config.dart` 에 `BlockDataSource` · `BlockRepository` 등록
- [ ] `domain/` 에 Supabase 타입이 없다
- [ ] `ReportRepository` 가 바뀌지 않았다

---

### Task 3: 진입점 — 프로필 · 게시물 메뉴, 피드 반영

**Files:**
- Modify: `app/lib/features/profile/presentation/cubit/{profile_cubit,profile_state}.dart`
- Modify: `app/lib/features/profile/presentation/page/profile_page.dart`
- Modify: `app/lib/features/post/presentation/widget/post_tile.dart`
- Modify: `app/lib/features/feed/presentation/page/feed_page.dart`
- Modify: `app/lib/features/feed/presentation/cubit/feed_cubit.dart`
- Modify: 대응 테스트

**주의:** `profile_cubit.dart` · `profile_state.dart` 는 **다른 작업 흐름이 최근에 고친 파일이다.** 디스크의 현재 상태를 읽고 그 위에 얹는다.

- [ ] **Step 1: `ProfileState.isBlocked`**

타인 프로필을 열 때 `isBlocked` 를 함께 읽는다. 내 프로필이면 언제나 `false` 이고 조회하지 않는다.

- [ ] **Step 2: 프로필 AppBar 메뉴**

신고 옆에 차단 / 차단 해제를 둔다. `isBlocked` 로 라벨이 갈린다. 차단은 destructive.

차단은 `AlertDialog` 확인을 거친다 — `account_settings_page` 의 탈퇴 확인과 같은 모양이다. 해제는 즉시 실행한다.

성공하면 `AppSnackBar.show` 로 알리고 `isBlocked` 를 뒤집는다. 차단했으면 그 프로필의 게시물 목록도 다시 읽는다 (이제 비어야 한다).

- [ ] **Step 3: `PostTile` 에 차단 항목**

남의 글 메뉴에 '이 사용자 차단' 을 더한다. `onBlock` 콜백은 `!isMine && onBlock != null` 로 막는다 — 신고 항목과 같은 방어다.

- [ ] **Step 4: `FeedCubit.removeAuthor(String authorId)`**

그 작성자의 항목을 목록에서 걷어낸다. 다시 읽지 않는다 — 스크롤 위치가 사라진다.

피드와 프로필 목록의 `onBlock` 이 확인 다이얼로그 → 차단 → `removeAuthor` → Snackbar 순으로 흐른다.

- [ ] **Step 5: 테스트**

| 파일 | 검증 |
|---|---|
| `post_tile_test.dart` | 남의 글에 차단이 뜬다 · 내 글에는 `onBlock` 이 있어도 안 뜬다 |
| `feed_cubit_test.dart` | `removeAuthor` 가 그 작성자 항목만 걷어낸다 |
| `profile_page_test.dart` | `isBlocked` 에 따라 라벨이 갈린다 · 내 프로필엔 없다 |
| `profile_cubit_test.dart` | 타인 프로필 로드 시 `isBlocked` 를 함께 읽는다 |

- [ ] **Step 6: 커밋** — `feat(safety): 프로필과 게시물에 차단 진입점을 붙인다`

**Verification:**
- [ ] `flutter analyze` 무경고 · `flutter test` 전체 통과
- [ ] 내 프로필·내 글에 차단이 보이지 않는다
- [ ] 차단 확인 다이얼로그가 있고 해제는 없다

---

### Task 4: 차단 목록 화면

**Files:**
- Create: `app/lib/features/safety/presentation/cubit/{blocked_users_cubit,blocked_users_state}.dart`
- Create: `app/lib/features/safety/presentation/page/blocked_users_page.dart`
- Modify: `app/lib/app/router/routes.dart` · 라우터 등록 파일
- Modify: `app/lib/features/settings/presentation/page/settings_page.dart`
- Create: `app/test/features/safety/presentation/{cubit,page}/...`

- [ ] **Step 1: 라우트**

`Routes.blockedUsers = '/settings/blocked'`. `accountSettings` 와 같은 방식으로 등록한다.

- [ ] **Step 2: 설정 진입점**

`settings_page.dart` 의 '계정 설정' 아래에 `AppListTile` 로 '차단한 사용자' 를 더한다. 기존 행들과 같은 모양이다.

- [ ] **Step 3: cubit · 화면**

`BlockedUsersState` 는 `{ status, items, failure }` 다. 커서는 없다 ([스펙](../../../apps/trader/docs/features/safety/plan-block.md)).

화면은 `AppBar('차단한 사용자')` + 목록이다. 각 행은 `AppListTile` 에 `AppAvatar` · 닉네임 · '차단 해제' 버튼(`AppButton.text`). 해제하면 그 행을 목록에서 걷어내고 Snackbar 를 띄운다.

로딩 · 빈 상태 · 오류는 `design_system` 의 공통 상태 위젯을 쓴다. **먼저 `design_system/widget/` 에 무엇이 있는지 확인하고** 없으면 기존 화면(피드·댓글)이 쓰는 것과 같은 방식을 따른다. 빈 상태 문구는 '차단한 사용자가 없습니다'.

- [ ] **Step 4: 테스트**

cubit 상태 전이(로드 · 해제 · 실패)와 화면(빈 상태 · 목록 · 해제 탭)을 덮는다.

- [ ] **Step 5: 커밋** — `feat(safety): 차단 목록 화면을 만든다`

**Verification:**
- [ ] `flutter analyze` 무경고 · `flutter test` 전체 통과
- [ ] 공통 위젯과 테마 토큰만 쓴다

---

### Task 5: 실제 DB 로 완료 조건 확인 · 문서

**Files:**
- Modify: `docs/features/safety/history.md` · `plan-block.md` · `docs/testing/features/safety.md` · `docs/status.md`

- [ ] **Step 1: 완료 조건 12개를 실제 DB 로 확인**

[스펙](../../../apps/trader/docs/features/safety/plan-block.md)의 완료 조건을 사용자 A·B 의 실제 JWT 로 확인한다. `docs/testing/audit-2026-08-24.md` 와 `.superpowers/sdd/2026-08-24-safety-report/task-6-report.md` 가 방법의 기준이다.

**양방향이 이 태스크의 핵심이다.** A가 B를 차단한 뒤 **B의 시야**에서도 A가 사라지는지를 B의 JWT 로 직접 확인한다. 한쪽만 보고 넘어가면 이 기능의 요점을 검증하지 않은 것이다.

`comment_count` 와 실제 댓글 목록의 개수가 일치하는지, 답글만 남은 부모가 되살아나지 않는지도 실제 데이터로 확인한다.

비로그인(`anon` 키) 조회가 영향을 받지 않는지도 본다.

**기대와 다르면 그 자리에서 고친다.**

- [ ] **Step 2~4: 문서**

`docs/testing/features/safety.md` 에 차단 절을 더하고, `history.md` 에 차단 구현에서 **계획과 달라진 것**을 적는다. `plan-block.md` 의 상태 줄과 완료 조건 체크박스를 채운다.

`docs/status.md` 의 `- [ ] **F7 safety (차단)**` 줄을 완료로 바꾼다. **이 파일은 다른 작업 흐름과 겹칠 수 있으므로 `git add -p` 로 자기 hunk 만 담는다.**

- [ ] **Step 5: 커밋** — `docs(safety): 차단 구현 결과를 문서에 반영한다`

**Verification:**
- [ ] Step 1 의 12개를 모두 실제로 확인하고 결과를 report 에 표로 적었다
- [ ] 양방향을 B의 JWT 로 직접 확인했다
- [ ] `flutter test` 전체 · `test/convention` 통과
