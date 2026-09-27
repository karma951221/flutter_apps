# F7 safety — 계획 (차단)

> [트레이더 허브](../../README.md) · [기획 F7](../../overview.md) · [스키마](../../schema.md) · [아키텍처](../../../../../docs/architecture.md) · [신고 계획](plan.md)

> 상태: **완료.** ·
> 작성 2026-08-25 · 검증 2026-08-25
> 진행 상태의 단일 기준은 [진행 현황](../../status.md)이다.

## 범위

사용자를 차단한다. 차단하면 **서로의 게시물과 댓글이 보이지 않고**, 차단당한 쪽은
차단한 쪽의 게시물에 댓글을 달 수 없다. 차단 목록에서 해제한다.

[신고](plan.md)와 달리 이번에는 **이미 동작하는 조회 경로를 건드린다.** `posts` ·
`post_comments` 의 조회 정책과 `post_comments_visible` 뷰가 대상이다. 신고가 새 테이블
하나로 끝났던 것과 회귀 위험이 다르고, 그래서 커밋을 나눴다.

## 확정한 결정과 근거

| 항목 | 결정 | 근거 |
|---|---|---|
| 가시성 방향 | **양방향.** A가 B를 차단하면 둘 다 서로를 못 본다 | 단방향이면 차단당한 쪽이 계속 읽고 반응할 수 있다 — 사람들이 차단하는 이유가 바로 그것을 멈추려는 것이다. 스토어 심사도 이쪽을 기대한다 |
| 차단 사실 노출 | **알리지 않는다.** 차단당한 쪽에는 상대의 글이 그냥 없는 것처럼 보인다 | "당신은 차단당했습니다"는 보복의 방아쇠다. 조용히 사라지는 편이 안전하다 |
| 필터를 두는 곳 | **`posts` · `post_comments` 의 조회 정책(RLS).** 뷰의 `where`가 아니다 | `posts_with_author`는 `security_invoker = on`이라 정책을 그대로 물려받는다. 정책에 두면 **뷰와 테이블 직접 조회가 한 번에** 막힌다. 뷰에만 쓰면 테이블 경로가 샌다 |
| `post_comments_visible` | **뷰 정의에 직접 쓴다** | 이 뷰만 `security_invoker = off`라 RLS를 우회한다 ([스키마 §9](../../schema.md)). 정책이 해주던 일을 손으로 적어야 하는 기존 부채와 같은 자리다 |
| 판정 함수 | **`is_blocked_with(uuid)` 하나** | "차단됐는가"의 정의가 네 곳(정책 둘·뷰·트리거)에 흩어지면 언젠가 어긋난다. 정의는 한 곳이다 |
| 함수 권한 | **`security definer`여야 한다** | `blocks`의 조회 정책은 내가 **건** 차단만 보여준다. "상대가 나를 차단했는가"는 내가 읽을 수 없는 행이라 invoker로는 판정 자체가 불가능하다 |
| 상호작용 차단 | **댓글 삽입까지 막는다.** 감정표현에는 별도 정책을 걸지 않는다 | 댓글은 상대가 읽는 내용을 만든다 — 실제 괴롭힘 경로다. 감정표현은 집계 숫자 하나라 읽을 내용이 없고, 보이지도 않는 글에 반응하려면 id를 따로 알아야 한다. **다만 실제로는 감정표현도 함께 막힌다** — `post_reactions_insert_own`·`comment_reactions_insert_own`(스키마 §10)의 `with check` 안 `exists` 서브쿼리가 차단 필터가 걸린 `posts`·`post_comments` 를 그대로 읽기 때문이다(2026-08-25 Task 5 검증, 스키마 §10에 기록). 의도한 부작용이지 버그가 아니다 — 별도 정책을 새로 만들 필요가 없다는 뜻으로 읽는다 |
| `profiles` 필터 | **걸지 않는다** | 차단 목록 화면이 차단한 사용자의 닉네임·아바타를 보여줘야 한다. 프로필까지 가리면 **내가 누구를 차단했는지 나도 못 본다** |
| 차단한 사람의 프로필 | **열린다. 게시물만 비어 보인다** | 프로필을 404로 만들면 차단 해제 경로가 사라진다. 대신 AppBar 메뉴가 '차단'에서 '차단 해제'로 바뀐다 |
| 자기 차단 | **CHECK로 막는다** | `blocker_id <> blocked_id`. 컬럼 둘만 보면 판정된다 — 트리거를 쓸 이유가 없다 |
| 중복 차단 | **복합 PK `(blocker_id, blocked_id)`** | 별도 unique 제약이 필요 없고, "내가 차단한 사람들" 조회 인덱스가 공짜로 생긴다 |
| 차단 해제 | **행 삭제** | 차단에는 자식이 달리지 않는다. 소프트 삭제의 이유가 없다 — [감정표현](../reaction/plan.md)과 같은 판단이다 |
| 차단 후 피드 | **그 작성자의 항목을 목록에서 걷어낸다** | 다시 읽으면 스크롤 위치가 사라진다. `FeedCubit.applyCommentCount` 와 같은 결이다 |
| 진입점 | **프로필 · 게시물 메뉴** 둘 | 댓글에서 차단하려면 작성자 프로필을 거치면 된다. 세 번째 진입점의 값이 그 한 단계보다 작다 |
| 확인 절차 | **차단은 확인 다이얼로그, 해제는 즉시** | 차단은 상대의 글이 통째로 사라지는 되돌리기 어려운 동작이다. 해제는 되돌리기 쉽다 |

## 데이터 · 권한

확정된 스키마의 단일 기준은 [스키마 문서](../../schema.md)다. 아래는 마이그레이션
`20260825120000_add_blocks.sql`에 담을 의도다.

### 테이블

```sql
create table public.blocks (
  blocker_id uuid        not null default auth.uid()
                         references public.profiles (id) on delete cascade,
  blocked_id uuid        not null
                         references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),

  constraint blocks_not_self check (blocker_id <> blocked_id),
  primary key (blocker_id, blocked_id)
);

-- "누가 나를 차단했는가" 방향. PK 가 반대 방향만 덮으므로 따로 필요하다.
create index blocks_blocked_idx on public.blocks (blocked_id);
```

복합 PK가 중복 차단을 막고 "내가 차단한 사람들" 조회를 덮는다. 양방향 판정이 반대
방향도 읽으므로 `blocks_blocked_idx` 가 있어야 한다 — 이것이 없으면 모든 게시물 조회가
`blocks` 전체 스캔을 탄다.

### 판정 함수 `is_blocked_with(other_id uuid) → boolean`

차단 여부의 **유일한 정의**다. 조회 정책 둘, 뷰 하나, 트리거 하나가 모두 이 함수를 부른다.

```sql
create function public.is_blocked_with(other_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
      from public.blocks b
     where (b.blocker_id = (select auth.uid()) and b.blocked_id = other_id)
        or (b.blocker_id = other_id and b.blocked_id = (select auth.uid()))
  );
$$;
```

**`security definer`가 필수다.** `blocks` 의 조회 정책은 `blocker_id = auth.uid()` 인 행만
보여준다 — 내가 **건** 차단이다. 두 번째 조건("상대가 나를 차단했는가")은 내 권한으로는
읽을 수 없는 행을 봐야 하므로 invoker로는 언제나 `false` 가 나온다. 이것은
[신고 트리거](plan.md)의 `security definer` 와 성격이 다르다. 그쪽은 방어적 선택이었고,
이쪽은 **없으면 기능이 성립하지 않는다.**

돌려주는 값이 `boolean` 하나라 "누가 누구를 차단했는지"는 새지 않는다. "나와 이 사람
사이에 차단이 있다"는 사실만 알 수 있고, 그것은 상대의 글이 사라지는 것으로 어차피
드러난다.

`stable` 은 **같은 문장(statement) 안에서 결과가 바뀌지 않는다**는 보장일 뿐,
같은 인자에 대해 한 번만 평가되는 메모이제이션을 약속하지 않는다 — 실제로는 두
조회 정책과 뷰 모두에서 **행마다 다시 평가된다.** `auth.uid()` 는 세션 GUC 기반이라
definer 함수 안에서도 **조회자 기준**으로 동작한다 —
[스키마 §6](../../schema.md)의 `my_reaction` 과 같은 근거다.

### 조회 정책 변경 — 여기가 회귀 위험의 중심이다

```sql
alter policy "posts_select_visible" on public.posts
  using (deleted_at is null and not public.is_blocked_with(author_id));

alter policy "post_comments_select_visible" on public.post_comments
  using (deleted_at is null and not public.is_blocked_with(author_id));
```

비로그인(`anon`)이면 `auth.uid()` 가 `null` 이라 `exists` 가 `false` → 필터가 통과된다.
차단은 로그인한 사용자 사이의 관계이므로 이 동작이 맞다.

**`posts` 정책을 고치면 `posts_with_author` 도 함께 막힌다** — 그 뷰가
`security_invoker = on` 이기 때문이다 ([스키마 §6](../../schema.md)). 뷰의 `where` 에
쓰지 않는 이유가 이것이다. 정책에 두면 뷰·테이블 직접 조회·`comment_count` 서브쿼리가
한꺼번에 덮인다.

`post_comments` 정책을 고치면 `posts_with_author` 의 `comment_count` 도 차단된 사람의
댓글을 세지 않는다. 목록에 보이는 개수와 실제로 열리는 목록이 어긋나지 않는다.

### `post_comments_visible` — 손으로 써야 하는 자리

이 뷰만 `security_invoker = off` 라 위 정책이 평가되지 않는다
([스키마 §9](../../schema.md)가 예고한 부채다). 세 곳에 조건을 넣는다.

| 자리 | 조건 |
|---|---|
| 본문 `where` | `and not public.is_blocked_with(c.author_id)` |
| `reply_count` 서브쿼리 | 차단된 사람의 답글은 세지 않는다 |
| "살아 있는 답글이 있는가" `exists` | 차단된 사람의 답글만 남은 부모는 되살리지 않는다 |

셋을 다 넣지 않으면 **개수와 목록이 어긋난다** — 답글 3개라고 표시되는데 펼치면 1개가
나오는 식이다.

### 댓글 삽입 차단 — 기존 트리거에 얹는다

`enforce_comment_depth()` 는 이미 `security definer` 이고 이미 대상 게시물을 읽는다.
새 트리거를 만들지 않고 여기에 검사를 하나 더한다.

```text
이 게시물에는 댓글을 달 수 없습니다
```

**정책(`with check`)으로 하지 않는 이유가 있다.** 정책 안에서 게시물 작성자를 찾으려면
`posts` 를 서브쿼리로 읽어야 하는데, 그 조회에 방금 넣은 차단 필터가 걸려 행이 사라진다.
그러면 `is_blocked_with(null)` 이 `false` 가 되어 **삽입이 도리어 허용된다.** definer
트리거는 정책을 우회하므로 이 함정이 없다.

**문구는 방향을 밝히지 않는다.** 최초 구현은 `차단한 사용자의 게시물에는 댓글을
달 수 없습니다`를 썼는데, 이 예외를 실제로 보는 사람은 차단"한" 쪽이 아니라
차단"당한" 쪽이다 — B가 A의 게시물 화면을 이미 열어 둔 상태에서 A가 B를 차단하고,
B가 등록을 누르는 시점에 이 트리거가 걸린다. B는 아무도 차단하지 않았으므로
"차단한 사용자"는 B에게 거짓이고, 동시에 위 표의 "차단 사실 노출: 알리지
않는다"를 정면으로 어긴다 — 감정표현 경로가 일반 `42501`로 아무것도 드러내지
않는 것과 달리, 댓글 경로만 트리거가 직접 지어낸 문구로 방향까지 새고 있었다.
`20260825130000_neutral_block_message.sql`이 문구를 위 방향 중립 문장으로 바꿨다
(적용된 마이그레이션은 고치지 않으므로 `create or replace function`으로).

`SupabaseErrorMapper._reportTargetMessages` 옆에 차단 문구 목록을 더한다.

### 차단 목록 뷰 `blocked_users`

차단 목록 화면이 읽는 유일한 대상이다.

```sql
create view public.blocked_users
with (security_invoker = on) as
select
  b.blocked_id  as id,
  b.created_at,
  pr.nickname,
  pr.avatar_url
from public.blocks b
join public.profiles pr on pr.id = b.blocked_id;
```

`security_invoker = on` 이라 `blocks_select_own` 정책이 그대로 걸린다 — 뷰에 `where` 를
쓰지 않아도 **내가 건 차단만** 나온다. [스키마 §6](../../schema.md)의 기본 규칙이고,
`post_comments_visible` 같은 예외를 만들 이유가 없다.

목록은 커서를 쓰지 않는다. 차단 목록이 수백 개가 되는 사용자는 이 앱의 대상이 아니고,
그렇게 되면 그때 커서를 붙인다.

### RLS · GRANT

```sql
alter table public.blocks enable row level security;

create policy "blocks_select_own" on public.blocks for select to authenticated
  using ((select auth.uid()) = blocker_id);
create policy "blocks_insert_own" on public.blocks for insert to authenticated
  with check ((select auth.uid()) = blocker_id);
create policy "blocks_delete_own" on public.blocks for delete to authenticated
  using ((select auth.uid()) = blocker_id);

grant select, delete on public.blocks to authenticated;
grant insert (blocked_id) on public.blocks to authenticated;
grant select on public.blocked_users to authenticated;
```

`blocker_id` 에 INSERT를 주지 않는 것이 위조를 막는 방법이다 — `default auth.uid()` 가
채운다. [신고](plan.md)와 같은 규칙이다.

UPDATE 정책·권한은 없다. 차단은 수정되지 않고 걸거나 푸는 것뿐이다.

## usecase

`features/safety` 에 이어 붙인다. 신고와 같은 폴더를 쓰되 파일은 나뉜다.

```
features/safety/
├── domain/
│   ├── entity/blocked_user.dart          { id, nickname, avatarUrl, blockedAt }
│   ├── repository/block_repository.dart
│   └── usecase/
│       ├── safety_use_case.dart          ← 신고 + 차단을 함께 여는 facade
│       └── scenario/
│           ├── submit_report_scenario.dart      (기존)
│           ├── block_user_scenario.dart
│           ├── unblock_user_scenario.dart
│           ├── get_blocked_users_scenario.dart
│           └── is_blocked_by_me_scenario.dart
├── data/
│   ├── dto/blocked_user_dto.dart
│   ├── datasource/{block_data_source,supabase_block_data_source}.dart
│   ├── mapper/blocked_user_mapper.dart
│   └── repository/{block_repository_impl,block_repository_error_handler}.dart
└── presentation/
    └── cubit/block_action_cubit.dart      ← feed_page · profile_page 의 차단
                                              호출을 소유(2026-08-25 전체 브랜치
                                              검토, ReportCubit 과 같은 자리)
```

**`ReportRepository` 를 재사용하지 않고 `BlockRepository` 를 새로 둔다.** 저장소는
테이블 하나의 관심사를 담당한다 — `reports` 와 `blocks` 는 다른 테이블이고, 하나로
묶으면 신고만 쓰는 화면이 차단 코드까지 끌고 온다. facade 는 규칙 ③ 대로 여전히
`SafetyUseCase` 하나다.

| 동작 | 시그니처 |
|---|---|
| 차단 | `Future<Result<void>> blockUser(String userId)` |
| 해제 | `Future<Result<void>> unblockUser(String userId)` |
| 목록 | `Future<Result<List<BlockedUser>>> getBlockedUsers()` |
| 상태 확인 | `Future<Result<bool>> isBlockedByMe(String userId)` |

`isBlockedByMe` 는 `is_blocked_with()` 를 부르지 않는다. **내가 건 차단만** 알면 되므로
`blocks` 를 직접 읽는다 — 프로필 메뉴가 '차단'과 '차단 해제' 중 무엇을 그릴지 정하는
용도다. 상대가 나를 차단한 경우에는 애초에 그 프로필의 게시물이 비어 있다.

## 화면

| 화면 | 변경 |
|---|---|
| `profile_page` | AppBar 메뉴에 차단 / 차단 해제 추가 (신고 옆). `BlockActionCubit`이 내가 건 차단 상태를 소유 |
| `post_tile` | 남의 글 메뉴에 '이 사용자 차단' 추가 |
| `feed_page` · 프로필 목록 | 차단 성공 시 그 작성자의 항목을 목록에서 걷어낸다 |
| `settings_page` | '차단한 사용자' 행 추가 → `/settings/blocked` |
| **신규** `blocked_users_page` | 차단 목록. 각 행에 '차단 해제' |

새 라우트는 `/settings/blocked` 하나다.

차단 확인 다이얼로그는 `account_settings_page` 의 탈퇴 확인과 같은 모양을 쓴다 —
`AlertDialog` 에 destructive 색 확인 버튼. 이 모양이 `feed_page` · `profile_page`
(차단, 완전히 동일한 코드) · `account_settings_page`(탈퇴) 세 곳에 반복되길래
`design_system/widget/app_confirm_dialog.dart`(`AppConfirmDialog.show`)로
승격했다(2026-08-25 전체 브랜치 검토, CLAUDE.md 규칙 4의 "반복 사용" 기준).

차단 호출 자체(`getIt<SafetyUseCase>().blockUser(...)`)는 위젯이 직접 부르지
않는다 — `BlockActionCubit`이 부른다(2026-08-25 전체 브랜치 검토, 아키텍처
규칙 ③). 화면은 확인 다이얼로그를 띄우고, `BlockActionCubit.block()`을 부르고,
성공하면 자신의 목록(`FeedCubit.removeAuthor` / `refresh()`)을 갱신하고
스낵바를 띄우는 것까지만 한다 — `ReportCubit`/`ReportSheet`가 신고에서 하는
역할과 같다.

~~`BlockedUsersPage` 는 로딩·빈 상태·오류를 화면 안에 직접 만든 위젯으로 그린다~~
→ **2026-08-27 갱신: `AppPlaceholder` 를 쓴다.**

원래 근거는 "로딩·빈·오류를 쓰는 다른 화면들이 이미 각자 다른 모양을 쓰고 있어서
하나 더 지어 봐야 공통화되는 것이 없다" 였다. 그 뒤로 같은 모양이 넷
(`FeedPlaceholder` · `_ProfileLoadError` · `_BlockedUsersError` · `_CommentError`)
이 됐고, 승격 기준("반복 사용되거나 새 화면에도 공통으로 쓸 모양")을 넘겼다.
가장 완성도 높던 `FeedPlaceholder` 를 `design_system/widget/app_placeholder.dart`
로 올리고 나머지 셋을 지웠다. 빈 상태 문구는 "차단한 사용자가 없습니다".

## 완료 조건

Task 5(2026-08-25)에서 사용자 A·B 의 실제 JWT로 REST(PostgREST)에 직접 확인했다.
전체 결과 표는 [테스트 문서](testing.md)와
[구현 기록](history.md)에 있다.

- [x] A가 B를 차단하면 A의 피드에서 B의 게시물이 사라진다 (A의 JWT로 B의 게시물 조회 → `[]`)
- [x] **B의 피드에서도 A의 게시물이 사라진다** (양방향) (B의 JWT로 A의 게시물 조회 → `[]`)
- [x] 차단된 사용자의 댓글이 댓글 목록에서 사라지고 `comment_count` 에서도 빠진다 (`comment_count` 3→1, 실제 목록도 1건으로 일치)
- [x] 차단된 사용자의 답글만 남은 부모 댓글은 되살아나지 않는다 (차단 전 `reply_count:1`로 되살아나던 부모가 차단 후 목록에서 완전히 사라짐)
- [x] B가 A의 게시물에 댓글을 다는 삽입이 DB에서 거부된다 (`403`, "이 게시물에는 댓글을 달 수 없습니다" — 최종 검토에서 방향 중립 문구로 교체, 아래 검증 참고)
- [x] 자기 자신 차단이 DB에서 거부된다 (`400`, `23514 blocks_not_self`)
- [x] 같은 사람을 두 번 차단하는 삽입이 거부된다 (`409`, `23505 blocks_pkey`)
- [x] `blocker_id` 를 위조한 삽입이 거부된다 (`403`, `42501`, INSERT GRANT 없음)
- [x] 남의 차단 목록은 조회되지 않는다 (B가 `blocks` 조회 → `[]`, `blocks_select_own`)
- [x] 차단 해제하면 양쪽 모두 다시 보인다 (delete 후 양쪽 JWT 재조회로 확인, `comment_count` 도 3으로 복구)
- [x] 차단한 사용자의 프로필은 여전히 열리고 메뉴가 '차단 해제'로 바뀐다 (DB: 차단 상태에서도 `profiles` 행이 그대로 조회됨, 화면은 `BlockActionCubit.isBlocked`로 메뉴를 전환)
- [x] 비로그인 조회가 차단 필터의 영향을 받지 않는다 (anon 키로 A·B 게시물 동시 조회 → 둘 다 보임, 차단이 걸린 상태에서 확인)

## F8(팔로우) 이 다시 도출하지 않도록 남기는 결정 (2026-08-25 전체 브랜치 검토)

F8이 착수될 때 이 feature를 다시 읽지 않고 같은 함정을 다시 밟지 않도록, 세
가지를 여기 기록해 둔다.

### 차단이 팔로우 엣지에 하는 일 — 오늘은 아무것도 하지 않는다(의도적 보류)

오늘 `blocks`에는 `follows`를 건드리는 트리거가 없다. F8이 그대로 붙으면
A가 B를 차단해도 B는 여전히 A의 팔로워 목록에 남고, 팔로워 수에도 잡힌다.
대부분의 서비스는 차단 시 양방향 팔로우 엣지를 지운다 — **이 결정을 F8
착수 시점까지 미룬다**는 것을 지금 명시적으로 결정해 둔다. 미루는 이유는
두 가지다.

1. F8이 아직 설계되지 않아 `follows`의 실제 모양(단방향 PK인지, 소프트
   삭제를 쓰는지)을 모른다 — 지금 정하면 틀린 가정 위에 정하는 것이다.
2. 만약 차단이 팔로우 엣지를 지우기로 하면, `blocks`에 `after insert`
   트리거를 다는 것이 된다. 이 feature의 "차단 해제는 행 삭제, 차단에는
   **자식이 달리지 않는다**"(위 결정표, `post_reactions`와 같은 판단 근거)라는
   전제가 그 순간 깨진다 — `blocks`가 `follows`에 부수 효과를 갖는 부모가
   되기 때문이다. F8이 이 트레이드오프를 명시적으로 인지하고 결정해야 한다.

### 팔로우 목록 조회 경로는 차단 필터를 자동으로 물려받지 않는다

오늘 차단이 가리는 모든 것(`posts` · `post_comments`)은 정책이 걸린 테이블을
거친다. F8의 팔로워/팔로잉 목록은 `follows` → `profiles`로 조인하는데,
`profiles`는 **의도적으로** 조회 정책을 걸지 않는다(위 결정표 "`profiles`
필터: 걸지 않는다" — 차단 목록 화면이 차단한 사용자의 닉네임을 보여줘야
해서다). 즉 `posts_select_visible`처럼 아래 테이블에 필터를 얹는 방식이
여기서는 통하지 않는다 — `follows` 쪽에 손으로 `is_blocked_with()`를 걸어야
한다. `post_comments_visible`(§9)이 이미 지고 있는 것과 같은 부채이고, F8이
이걸 잊으면 차단한 상대가 서로의 팔로워 목록에 계속 나타난다.

### 일반화된 규칙: DB 쪽 차단 거부는 방향을 밝히지 않는다

이번 검토에서 고친 [댓글 삽입 거부 문구](history.md#2026-08-25-같은-전체-브랜치-검토-차단-사실-노출-문구를-방향-중립으로-고쳤다)가
보여준 함정이 F8에도 그대로 있다. F8이 팔로우 삽입에 차단 검사를 건다면
(차단한/차단당한 상대를 팔로우할 수 없게 막는 경우), 그 거부 메시지는 반드시
방향 중립이어야 한다 — 거부를 실제로 보는 쪽이 항상 차단을 "건" 쪽이라고
가정하면 안 된다. "당신이 차단한 사용자입니다" 류의 문구는 이 feature의
중심 결정("차단 사실 노출: 알리지 않는다")을 다시 어긴다.
