# W5 social — 계획 (결정 · 스키마 · 화면 · 완료 조건)

> [pawlog 허브](../../README.md) · [기획 W5](../../overview.md#w5-social--소셜-v2-별도-기획) · [트레이더 스키마](../../../../trader/docs/schema.md) · [아키텍처](../../../../../docs/architecture.md)

> 상태: **완료** 2026-10-18(착수 2026-10-17) — [구현 기록](history.md) · [테스트](testing.md) · 진행 상태의 단일 기준은 [진행 현황](../../status.md)

## 범위

pawlog 의 v2 첫 조각. **원하는 산책 한 건을 골라 모두에게 공유하고, 다른 사람의 공유 산책을 둘러보고 좋아요를 누른다.**
기록은 여전히 기기에 먼저 저장되고(로컬 우선), 로그인은 공유 · 좋아요를 할 때만 필요하다. 사용자가 "끝날 때까지 묻지 말고
알아서" 라고 해서 범위 · 결정은 오케스트레이터가 정했다(아래 표 — 바꾸고 싶으면 여기만 고치면 된다).

범위 밖(이번에 안 함): 사진 공유 · 댓글 · 팔로우 · 프로필 화면 · 내 기록 전체 동기화 · 다른 기기 복원(→ W9 백업) ·
신고 · 차단 · 계정 삭제 화면(트레이더 앱의 계정과 같은 계정이다 — 삭제는 트레이더 앱에서) · 푸시 알림.

## 결정

| # | 결정 | 근거 |
|---|---|---|
| 1 | **트레이더와 같은 Supabase 프로젝트 · 같은 계정**(`auth.users` · `profiles` 공유). 닉네임 규칙(2~20자 · 대소문자 무시 유일)도 그대로 | 한 사람이 daylog 앱들을 한 계정으로 쓴다. 별도 프로젝트는 운영 비용만 는다 |
| 2 | 새 테이블은 `walk_` 접두사: `walk_posts` · `walk_post_likes`, 보기 `walk_posts_with_author` | 트레이더의 `posts` 와 섞이지 않는다(트레이더 피드 · 프로필이 `posts` 를 읽는다) |
| 3 | **공유는 한 건씩, 고를 때만**. 기본은 비공개(공유 안 됨). 상세 더보기 "모두에게 공유" / 공유된 산책은 "공유 취소" | 산책 기록은 사적이다. 일괄 동기화는 범위 밖 |
| 4 | 공유 내용: 반려견 이름들 · 시작 시각 · 걸은 시간 · 거리 · 메모 · **경로 미리보기(앞뒤 150 m 잘라 냄)**. 사진은 올리지 않는다 | 경로 시작 · 끝은 대개 집이다. 150 m 를 자르면 집 위치가 드러나지 않는다. 남은 경로가 2점 미만이면 경로 없이 공유 |
| 5 | 같은 산책은 한 번만 공유된다: `(author_id, local_walk_id)` 유일. 공유 취소는 soft delete(`deleted_at`), 다시 공유하면 그 행을 되살린다(RPC) | 두 번 눌러도 겹치지 않는다. 트레이더의 soft delete 관례 |
| 6 | **둘러보기는 로그인 없이**(anon select). 좋아요 · 공유는 로그인 필요 → 로그인 화면 | 트레이더의 "먼저 둘러보기" 와 같은 방향 |
| 7 | 로그인 화면은 pawlog 안에 직접 만든다(이메일 · 비밀번호, 가입 시 닉네임). `feature_auth` 는 쓰지 않는다 | `feature_auth` 화면은 core `Routes` 로 트레이더 경로를 직접 부른다. 앱 전용 코드는 앱 안에 둔다(메모리 규칙) |
| 8 | Supabase 초기화는 트레이더처럼 `--dart-define` `SUPABASE_URL` · `SUPABASE_PUBLISHABLE_KEY`, 없으면 로컬(안드로이드 `10.0.2.2:54321`). `SupabaseClient` 는 pawlog `RegisterModule` 에 등록(core 모듈 안 씀). **초기화 실패해도 앱은 뜬다** — 로컬 기능은 그대로, 모두의 산책만 오류 안내 | 로컬 우선 앱이 서버 때문에 못 뜨면 안 된다 |
| 9 | "모두의 산책" 화면 `/community`: 피드 앱바 아이콘(사람들)으로 들어간다. 최신순, 커서(`created_at desc, id desc`) 20개씩 | 내 수첩(피드)과 분리. 피드는 계속 내 기록만 |
| 10 | 카드: 작성자 닉네임 · 날짜 · 반려견 이름 · 거리 · 시간 · 경로 그림(기존 `RouteSketch`) · 메모 · 좋아요(하트 + 수). 수첩과 같은 줄글 모양(카드 없음) | design.md |
| 11 | 좋아요는 낙관적 갱신(누르면 바로 바뀌고 실패하면 되돌리고 스낵바) | 네트워크 왕복을 기다리지 않는다 |
| 12 | 로그아웃: 모두의 산책 앱바 더보기 "로그아웃". 로그아웃해도 로컬 기록은 그대로 | |

## 스키마 (새 마이그레이션 — 단일 기준은 [트레이더 스키마](../../../../trader/docs/schema.md) 에 새 절로 싣는다)

```sql
create table public.walk_posts (
  id               uuid primary key default gen_random_uuid(),
  author_id        uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  local_walk_id    uuid not null,
  started_at       timestamptz not null,
  duration_seconds integer not null check (duration_seconds >= 0),
  distance_meters  double precision not null check (distance_meters >= 0),
  dog_names        text[] not null check (cardinality(dog_names) between 1 and 10),
  memo             text check (char_length(memo) <= 500),
  route_preview    jsonb check (route_preview is null or jsonb_array_length(route_preview) <= 64),
  created_at       timestamptz not null default now(),
  deleted_at       timestamptz,
  unique (author_id, local_walk_id)
);
create index walk_posts_created_at_idx on public.walk_posts (created_at desc, id desc) where deleted_at is null;

create table public.walk_post_likes (
  post_id    uuid not null references public.walk_posts(id) on delete cascade,
  user_id    uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);
```

- RLS: `walk_posts` select(anon · authenticated) `deleted_at is null` · insert 본인(`author_id = auth.uid()`) · update · delete 직접 금지(RPC 로만).
  `walk_post_likes` select 모두 · insert · delete 본인, 지운 글엔 좋아요 못 함
- RPC `publish_walk_post(p_local_walk_id, p_started_at, p_duration_seconds, p_distance_meters, p_dog_names, p_memo, p_route_preview) returns uuid` —
  같은 `(auth.uid(), local_walk_id)` 가 있으면 내용을 갱신하고 `deleted_at` 을 지운다(upsert). security invoker 가 아닌 definer 면 `auth.uid()` 검사
- RPC `unpublish_walk_post(p_local_walk_id)` — 본인 것의 `deleted_at = now()`
- 보기 `walk_posts_with_author` (security_invoker): 글 + `author_nickname` · `author_avatar_url` · `like_count` · `liked_by_me`
- GRANT: 트레이더 관례대로 열 단위. anon 은 보기 select 만
- 검증 스크립트 `supabase/tests/walk_posts_rls_check.py`

## 화면

| 화면 | 경로 | 내용 |
|---|---|---|
| 모두의 산책 | `/community` | 목록 · 당겨서 새로고침 · 끝까지 내리면 더 읽기 · 하트. 빈 목록 "아직 공유된 산책이 없어요". 서버 오류 → 안내 + 다시 시도. 앱바 더보기: 로그인했으면 "로그아웃", 아니면 "로그인" |
| 로그인 | `/sign-in` | 이메일 · 비밀번호 · "로그인" · "가입하기" 전환(가입은 닉네임 추가). 성공하면 이전 화면으로 돌아간다(돌아갈 곳 `from` 쿼리) |
| 상세 | (기존) | 더보기 "모두에게 공유" ↔ "공유 취소". 로그인 안 했으면 로그인 → 돌아와서 다시 누른다 |

## 문자열 (ko · en · ja) — 키는 `walkSocial*`

| 키 | ko | en | ja |
|---|---|---|---|
| `walkSocialTitle` | 모두의 산책 | Community walks | みんなの散歩 |
| `walkSocialOpenTooltip` | 모두의 산책 | Community walks | みんなの散歩 |
| `walkSocialEmpty` | 아직 공유된 산책이 없어요 | No shared walks yet | まだ共有された散歩はありません |
| `walkSocialLoadFailed` | 모두의 산책을 불러오지 못했어요 | Couldn't load community walks | みんなの散歩を読み込めませんでした |
| `walkSocialShare` | 모두에게 공유 | Share with everyone | みんなに共有 |
| `walkSocialUnshare` | 공유 취소 | Stop sharing | 共有をやめる |
| `walkSocialShared` | 공유했어요 | Shared | 共有しました |
| `walkSocialUnshared` | 공유를 취소했어요 | No longer shared | 共有をやめました |
| `walkSocialShareFailed` | 공유하지 못했어요 | Couldn't share the walk | 共有できませんでした |
| `walkSocialLikeTooltip` | 좋아요 | Like | いいね |
| `walkSocialSignIn` | 로그인 | Sign in | ログイン |
| `walkSocialSignUp` | 가입하기 | Sign up | 登録 |
| `walkSocialSignOut` | 로그아웃 | Sign out | ログアウト |
| `walkSocialEmail` | 이메일 | Email | メール |
| `walkSocialPassword` | 비밀번호 | Password | パスワード |
| `walkSocialNickname` | 닉네임 | Nickname | ニックネーム |
| `walkSocialSwitchToSignUp` | 처음이면 가입하기 | New here? Sign up | 初めての方は登録 |
| `walkSocialSwitchToSignIn` | 이미 계정이 있으면 로그인 | Have an account? Sign in | アカウントをお持ちの方はログイン |
| `walkSocialSignInRequired` | 로그인하면 공유하고 좋아요를 누를 수 있어요 | Sign in to share and like walks | ログインすると共有やいいねができます |
| `walkSocialAuthFailed` | 로그인하지 못했어요. 이메일과 비밀번호를 확인해 주세요 | Couldn't sign in. Check your email and password | ログインできませんでした。メールとパスワードを確認してください |
| `walkSocialNicknameTaken` | 이미 쓰는 닉네임이에요 | That nickname is taken | そのニックネームは使われています |

## 완료 조건

- [x] 마이그레이션 · `schema.md` 새 절 · RLS 스크립트(로컬 `supabase db reset` 뒤 통과)
- [x] 경로 앞뒤 잘라 내기 정책 · 저장소(Supabase, 모의) · 로그인 · 모두의 산책 · 공유 테스트
- [x] Supabase 가 없어도 앱이 뜨고 로컬 기능이 그대로(테스트 + 에뮬레이터)
- [x] `flutter analyze` 0 · `flutter test` · `flutter build apk --debug` · 패키지 경계 테스트 갱신
- [x] 에뮬레이터(로컬 Supabase): 가입 → 산책 공유 → 모두의 산책에 보임(경로 앞뒤 잘림) → 좋아요 → 공유 취소 → 사라짐 → 로그아웃 뒤 둘러보기
