# F8 follow — 계획 (팔로우 · 맞팔 · 목록 · 팔로잉 피드)

> [문서 허브](../../README.md) · [기획 F8](../../overview.md) · [스키마](../../schema.md) · [아키텍처](../../architecture.md) · [차단 계획](../safety/plan-block.md) · [피드 계획](../feed/plan.md)

> 상태: **완료** · 작성 2026-08-30 · 검증 2026-08-30
> 진행 상태의 단일 기준은 [진행 현황](../../status.md)이다.

## 범위

사용자를 팔로우하고 해제한다. 서로 팔로우 중이면 맞팔로 표시한다. 프로필에서
팔로워 · 팔로잉 수를 보고 눌러서 목록으로 들어간다. 피드는 탭이 둘이 되고
'팔로잉' 탭은 팔로우한 사람의 글만 보여준다 — [F4](../feed/plan.md)가 3단계
범위로 남겨 둔 부분이다.

[차단](../safety/plan-block.md)처럼 **이미 동작하는 조회 경로를 건드린다.**
`blocks`에 트리거가 하나 붙고 프로필 조회가 뷰를 타게 된다. 새 테이블 하나로
끝나지 않으므로 커밋을 나눈다.

## 확정한 결정과 근거

| 항목 | 결정 | 근거 |
|---|---|---|
| 관계 방향 | **단방향.** `(follower_id, followee_id)` 복합 PK | 맞팔은 반대 방향 행이 하나 더 있는 것일 뿐이다. "맞팔" 상태를 컬럼으로 들면 두 행이 서로를 갱신해야 해서 정합성 관리 지점이 늘어난다 |
| 해제 | **행 삭제.** 소프트 삭제하지 않는다 | 팔로우에는 자식이 달리지 않는다. `blocks`(§13) · `post_reactions`(§10)와 같은 판단 |
| 자기 팔로우 | **CHECK 제약** `follows_not_self` | 컬럼 둘만 보면 판정된다. 트리거가 필요 없다 — `blocks_not_self`와 같은 자리 |
| `follower_id` | `default auth.uid()`, **INSERT GRANT를 주지 않는다** | 보내면 `42501`로 막히고 DB가 채운다. 위조 경로가 없다 — 신고 · 차단과 같은 규칙 |
| 조회 권한 | **팔로우 그래프는 공개다.** `follows_select_all`이 `anon` · `authenticated` 모두에게 열려 있다 | 남의 프로필에서도 팔로워 수와 목록이 보여야 한다. `blocks`처럼 본인 행만 열면 수·목록·맞팔 판정이 전부 `security definer` 함수를 타야 한다 |
| 차단 × 팔로우 엣지 | **차단하면 양방향 팔로우 행을 지운다** (`blocks` after insert 트리거) | [차단 계획 §F8](../safety/plan-block.md)이 F8 시점까지 미뤄 둔 결정이다. 아래 "차단과의 관계"에 대가까지 적는다 |
| 차단 상태의 팔로우 | **INSERT 정책이 거부한다** (`not is_blocked_with(followee_id)`) | 엣지를 지워도 곧바로 다시 누를 수 있으면 지운 의미가 없다 |
| 차단 사실 노출 | **엣지 삭제로 차단당한 쪽이 추론할 수 있다 — F7 결정에서 의도적으로 이탈한다** | `follows_delete_own` 이 내가 건 행만 지우므로, 내가 지우지 않았는데 사라졌다면 원인은 상대의 차단뿐이다(탈퇴는 프로필이 통째로 사라져 구별된다). 엣지를 남기면 수와 목록이 어긋나고, 수까지 필터를 태우면 "조회자마다 수가 달라진다"를 깨야 한다 — 설계 공간이 좁아 이 이탈을 받아들인다 (2026-08-30 검수) |
| 거부 문구 | **방향 중립.** "지금은 팔로우할 수 없습니다" | [차단 계획 §일반화된 규칙](../safety/plan-block.md). 거부를 보는 쪽이 차단을 건 쪽이라고 가정하면 차단 사실이 샌다 |
| 프로필 통계 | **뷰 `profile_details` 하나로** 내려받는다 | 수 둘 + 관계 둘을 화면이 네 번 조회하지 않는다 ([기획 F2](../../overview.md) "뷰 또는 RPC 하나로 묶어 내려준다") |
| 팔로잉 피드 | **뷰 `following_posts_with_author`** 를 따로 만든다 | 커서 · 컬럼 · 정렬이 `posts_with_author`와 같아서 앱은 **읽는 대상만 바꾼다**. PostgREST 에 서브쿼리를 흉내 내는 필터를 짜 넣지 않는다 |
| 목록 화면 | 팔로워 · 팔로잉 **두 화면, 뷰 둘** | 방향에 따라 "상대"가 반대쪽 컬럼이라 한 뷰로 묶으면 화면이 매번 방향을 계산해야 한다 |

## 데이터 · 권한

### 테이블

```sql
create table public.follows (
  follower_id uuid        not null default auth.uid()
                          references public.profiles (id) on delete cascade,
  followee_id uuid        not null
                          references public.profiles (id) on delete cascade,
  created_at  timestamptz not null default now(),

  constraint follows_not_self check (follower_id <> followee_id),
  primary key (follower_id, followee_id)
);

-- "누가 나를 팔로우하는가" 방향. PK 가 반대 방향만 덮는다.
create index follows_followee_idx
  on public.follows (followee_id, created_at desc, follower_id desc);
create index follows_follower_idx
  on public.follows (follower_id, created_at desc, followee_id desc);
```

복합 PK가 중복 팔로우를 막는다. 조회는 인덱스 둘이 나눠 받는다 — 팔로워 방향은
`follows_followee_idx`가(`blocks_blocked_idx`와 같은 이유), 팔로잉 방향은
`follows_follower_idx`가 받는다. PK 의 `(follower_id, followee_id)` 순서로는
목록의 `created_at desc` 커서가 인덱스를 타지 못하므로 두 인덱스 모두 정렬 키를
함께 들고 있다.

### RLS · GRANT

```sql
alter table public.follows enable row level security;

create policy "follows_select_all" on public.follows for select
  to anon, authenticated using (true);

create policy "follows_insert_own" on public.follows for insert to authenticated
  with check (
    (select auth.uid()) = follower_id
    and not public.is_blocked_with(followee_id)
  );

create policy "follows_delete_own" on public.follows for delete to authenticated
  using ((select auth.uid()) = follower_id);

grant select on public.follows to anon, authenticated;
grant insert (followee_id) on public.follows to authenticated;
grant delete on public.follows to authenticated;
```

UPDATE 정책 · 권한은 없다. 팔로우는 수정되지 않고 걸거나 푸는 것뿐이다 —
차단과 같다.

INSERT의 `with check`가 두 가지를 한 번에 본다. `follower_id` 위조는 GRANT가
1차로 막고 정책이 2차로 막는다. 차단 검사는 `is_blocked_with()`(§3)를 그대로
부른다 — **양방향**이라 내가 차단했든 상대가 나를 차단했든 같은 결과가 나온다.
그래서 거부 문구가 방향을 밝히면 안 된다.

### 차단과의 관계 — `blocks`에 트리거를 단다

```sql
create function public.drop_follows_on_block()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  delete from public.follows
   where (follower_id = new.blocker_id and followee_id = new.blocked_id)
      or (follower_id = new.blocked_id and followee_id = new.blocker_id);
  return new;
end;
$$;

create trigger blocks_drop_follows
  after insert on public.blocks
  for each row execute function public.drop_follows_on_block();
```

`security definer`가 필수다. 차단당한 쪽이 건 팔로우 행은 `follows_delete_own`이
지우지 못한다 — 그 정책은 `follower_id = auth.uid()`만 지운다.

**대가를 명시한다.** [차단 계획](../safety/plan-block.md)의 "차단에는 자식이
달리지 않는다"는 전제가 이 트리거로 깨진다. `blocks`가 `follows`에 부수 효과를
갖는 부모가 됐다. 그럼에도 지우는 쪽을 고르는 이유는, 지우지 않으면 차단한
상대가 팔로워 수에 계속 잡히고 그 수를 눌러 들어간 목록에서만 사라져 **수와
목록이 어긋나기** 때문이다. 차단을 해제해도 팔로우는 되살아나지 않는다 —
행이 지워졌으므로 다시 누르는 것은 사용자의 몫이다.

목록 뷰의 차단 필터는 트리거가 있어도 **함께 유지한다.** 트리거는 차단 시점의
엣지만 지우고, `is_blocked_with()`는 조회 시점의 관계를 본다 — 두 사람이 제3자의
목록에 함께 나타나는 경우는 트리거가 덮지 못한다.

### 뷰 넷

`profiles`에는 조회 정책이 없고([차단 계획](../safety/plan-block.md)의 의도적
선택), `follows`는 전체 공개다. 그래서 아래 뷰는 모두 `security_invoker = on`
이면 되고, 차단 필터는 **손으로 적는다.** 차단 계획이 예고한 부채가 바로
이 자리다 — 아래 테이블에 정책을 얹는 방식이 여기서는 통하지 않는다.

| 뷰 | 쓰는 곳 | 핵심 |
|---|---|---|
| `profile_details` | 프로필 화면 | `profiles` + 팔로워 수 · 팔로잉 수 · `is_following` · `is_followed_by` |
| `user_followers` | 팔로워 목록 | `user_id`(팔로우당하는 쪽) 기준, 상대 프로필과 `created_at` |
| `user_followings` | 팔로잉 목록 | `user_id`(팔로우하는 쪽) 기준, 상대 프로필과 `created_at` |
| `following_posts_with_author` | 팔로잉 피드 | `posts_with_author`를 내 `follows`로 좁힌 것 |

**이 필터는 보안 통제가 아니라 화면 필터다.** `follows` 와 `profiles` 가 둘 다
전체 공개라, `follows` 를 직접 조회하면서 `profiles` 를 임베드하면 뷰가 가린
것과 같은 형태(닉네임 · 아바타)를 REST 한 번으로 꺼낼 수 있다. "팔로우 그래프는
공개다"가 확정 결정인 이상 권한 상승은 아니지만, "차단한 사용자끼리 서로 보이지
않아야 한다"가 요구되면 이 구조로는 만족할 수 없다 (2026-08-30 검수).

수 둘은 차단 필터를 **타지 않는다.** 내가 차단한 사람이 남의 팔로워 수에서
빠지면 조회자마다 수가 달라지고, 목록의 행 수와도 어긋난다. 목록 뷰에만
필터를 걸어 "차단한 상대는 목록에 보이지 않는다"까지만 만든다. 트리거가 나와
상대 사이의 엣지는 이미 지웠으므로, 필터가 실제로 일하는 경우는 제3자의
목록에서 차단 상대를 만나는 때다.

`following_posts_with_author`는 `posts_with_author`(§6)를 그대로 감싼다. 그
뷰가 이미 `security_invoker = on`이라 삭제 · 차단 필터를 정책에서 물려받으므로,
여기서 다시 쓰지 않는다.

## usecase

`features/follow`를 새로 만든다. 규칙 ③대로 facade는 `FollowUseCase` 하나다.

```
features/follow/
├── domain/
│   ├── entity/
│   │   ├── follow_user.dart          { id, nickname, avatarUrl, followedAt }
│   │   └── follow_relation.dart      { isFollowing, isFollowedBy } → isMutual
│   ├── repository/follow_repository.dart
│   └── usecase/
│       ├── follow_use_case.dart
│       └── scenario/
│           ├── follow_user_scenario.dart
│           ├── unfollow_user_scenario.dart
│           ├── get_followers_scenario.dart
│           └── get_followings_scenario.dart
├── data/
│   ├── cursor/follow_cursor.dart     ← (created_at, id) 불투명 커서
│   ├── dto/follow_user_dto.dart
│   ├── datasource/{follow_data_source,supabase_follow_data_source}.dart
│   ├── mapper/follow_user_mapper.dart
│   └── repository/follow_repository_impl.dart
└── presentation/
    ├── cubit/
    │   ├── follow_action_cubit.dart  ← 프로필의 팔로우 버튼(낙관적)
    │   ├── follow_list_cubit.dart    ← 목록 화면(커서)
    │   └── follow_list_state.dart
    └── page/follow_list_page.dart    ← 팔로워 · 팔로잉 공용, 방향만 다르다
```

| 동작 | 시그니처 |
|---|---|
| 팔로우 | `Future<Result<void>> followUser(String userId)` |
| 해제 | `Future<Result<void>> unfollowUser(String userId)` |
| 팔로워 | `Future<Result<CursorPage<FollowUser>>> getFollowers({required String userId, String? cursor})` |
| 팔로잉 | `Future<Result<CursorPage<FollowUser>>> getFollowings({required String userId, String? cursor})` |

관계 조회 시나리오는 두지 않는다. `is_following` · `is_followed_by`는
`profile_details`가 프로필과 함께 내려주므로 화면이 따로 물을 이유가 없다 —
`isBlockedByMe`가 별도 시나리오인 것과 다른 점이다(차단은 프로필 조회에
들어 있지 않다).

## 화면

| 화면 | 변경 |
|---|---|
| `profile_page` | 헤더에 팔로워 · 팔로잉 수(누르면 목록). 남의 프로필이면 팔로우 버튼 3상태 — 팔로우 / 팔로잉 / 맞팔로우 |
| **신규** `follow_list_page` | `/profile/:id/followers` · `/profile/:id/followings`. 커서 무한 스크롤, 행은 `AppListTile` |
| `feed_page` | 탭 2개(전체 / 팔로잉). 팔로잉 탭의 빈 상태는 "팔로우한 사람이 없다" 안내 |

팔로우 버튼은 `AppButton`의 기존 인자로 해결한다 — 팔로우는 `primary`,
팔로잉 · 맞팔로우는 `secondary`다. 새 공용 위젯을 만들지 않는다(UI 규칙 ④).

낙관적 업데이트는 `FollowActionCubit`이 소유한다. 누르는 즉시 상태와 팔로워
수를 바꾸고 실패하면 되돌린 뒤 오류 스낵바를 띄운다 — `ReactionBar`가 이미
쓰는 방식이고, 목록을 소유한 쪽이 낙관적 갱신을 한다는 F5의 결정과 같다.

## 오류

| 상황 | 처리 |
|---|---|
| 차단 관계에서 팔로우 | 정책 거부(`42501`) → `FailureCode.followBlocked` → **방향 중립 문구** |
| 자기 팔로우 | CHECK 위반. 화면이 애초에 버튼을 그리지 않으므로 방어선이다 |
| 중복 팔로우 | PK 충돌 → `duplicateValue`. 낙관적 상태가 이미 '팔로잉'이라 사용자에게는 드러나지 않는다 |
| 비로그인 | 라우트가 막는다. 데이터 계층은 `authenticationRequired`로 방어한다 |

## 완료 조건

- [x] 남의 프로필에서 팔로우 · 해제가 되고 버튼이 3상태로 바뀐다
- [x] 팔로워 · 팔로잉 수가 프로필에 보이고 눌러서 목록으로 들어간다
- [x] 목록이 커서로 이어 읽힌다 (경계에서 중복 · 누락이 없다)
- [x] 피드 '팔로잉' 탭이 팔로우한 사람의 글만 보여준다
- [x] 자기 자신은 팔로우할 수 없다 (CHECK, `23514`)
- [x] `follower_id` 를 위조한 삽입이 거부된다 (GRANT · 정책, `42501`)
- [x] 남의 팔로우 행을 지울 수 없다 (`follows_delete_own`, 0행 삭제)
- [x] 차단하면 양방향 팔로우 행이 사라지고, 차단 상태에서는 팔로우가 거부된다
- [x] 거부 문구가 방향을 밝히지 않는다 (`FailureCode.followBlocked`)
- [x] 차단한 상대는 제3자의 팔로워 · 팔로잉 목록에도 보이지 않는다

## 테스트

단위 · 위젯은 [테스트 문서](../../testing/features/follow.md)에, 권한 경계는
`supabase/tests/follow_rls_check.py`에 둔다. RLS · 트리거는 mock 으로 드러나지
않으므로 실제 JWT + REST 로 확인한다 — 채팅과 같은 방식이다.

## v1 범위 밖

- 팔로우 알림 (4단계 푸시와 함께)
- 비공개 계정 · 팔로우 요청 승인
- 추천 팔로우 · 팔로잉 수 기준 정렬
