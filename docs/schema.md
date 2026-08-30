# 스키마 — DDL · RLS 단일 기준

> [문서 허브](README.md) · [기획](overview.md) · [아키텍처](architecture.md) · [개발환경](setup.md)

**이 문서가 스키마의 단일 기준이다.** 테이블·정책·권한이 지금 어떤 모습이어야 하는지는
여기서 확인한다. [`supabase/migrations/`](../supabase/migrations/)는 이 상태에 도달하기
위한 **실행 이력**이고, 이 문서는 도달한 **결과의 전체 모습**이다.

스키마를 바꿀 때는 반드시 셋을 함께 한다.

```bash
supabase migration new <이름>   # 1. 마이그레이션 파일 작성
supabase db reset               # 2. 전체 재적용해서 검증 (로컬 데이터 초기화됨)
                                # 3. 이 문서를 결과에 맞게 갱신
```

Studio UI에서 테이블을 직접 만들지 않는다. 이 문서와 실제 DB가 어긋나면 **이 문서가
아니라 마이그레이션을 고친다** — 실행되는 것은 마이그레이션이다.

---

## 1. 관계

```text
auth.users  (Supabase Auth 소유)
    │ 1:1  on delete cascade
    ▼
profiles ──1:N──▶ posts ──┬──1:N──▶ post_images
    │                      │
    │                      ├──1:N──▶ post_comments ──1:N──▶ post_comments (parent_id, self)
    │                      │                │
    │                      │                └──1:N──▶ comment_reactions
    │                      │
    │                      └──1:N──▶ post_reactions
    │                                       ▲
    └───────────────1:N─────────────────────┘  (반응 두 테이블의 user_id)
```

읽기 전용 뷰 `posts_with_author`(§6)가 게시물·작성자·이미지·반응·댓글 수를 한 번에
내려주고, `post_comments_visible`(§9)이 `post_comments`와 `profiles`·`posts`·
`comment_reactions`를 조인해 댓글 목록을 내려준다. 반응 두 테이블(§10)은 직접
조회하지 않고 **집계된 형태로만** 이 두 뷰를 통해 읽는다.

`reports`(§12)는 폴리모픽이라 관계도에 선이 없다. `reporter_id`만 `profiles`를
참조한다.

`blocks`(§13)도 폴리모픽은 아니지만 관계도에 선을 넣지 않았다 — `blocker_id`·
`blocked_id` 둘 다 `profiles`를 참조하는 자기 참조 관계라서 화살표로 그리면
`posts`와의 1:N과 헷갈린다. 대신 `posts_select_visible`·`post_comments_select_visible`
정책과 `post_comments_visible`(§9) 뷰가 모두 `is_blocked_with()`(§3) 하나를 불러
차단 관계를 반영한다.

앞으로 추가될 테이블(`follows`)의 계획은
[기획서 §7](overview.md)에 있다. 여기에는 **실제로 존재하는 것만** 적는다.

---

## 2. 공통 규칙

이 스키마 전체에 적용되는 규칙이다. 새 테이블을 추가할 때도 지킨다.

### RLS와 GRANT는 별개이며 둘 다 필요하다

RLS는 "**어떤 행**에 접근할 수 있는가"를, GRANT는 "**어떤 테이블·컬럼**에 접근할 수
있는가"를 정한다. GRANT를 빠뜨리면 정책이 완벽해도 이 오류가 난다.

```text
42501: permission denied for table posts
```

Supabase 대시보드로 테이블을 만들면 GRANT가 자동으로 붙어서 튜토리얼에는 거의 나오지
않는다. 마이그레이션으로 만들면 **반드시 명시해야 한다.**

### GRANT는 컬럼 단위로 최소한만 준다

`grant update (content)`처럼 쓰면 `id` · `author_id` · `created_at` · `deleted_at` 같은
컬럼은 클라이언트가 아예 건드릴 수 없다. 정책으로 막는 것보다 확실하다.

### 소유자 컬럼은 DB가 채운다

`author_id`는 `default auth.uid()`다. 앱이 값을 보내지 않으므로 위조할 경로가 없고,
INSERT 정책의 `with check`가 이중으로 막는다.

### 삭제는 소프트 삭제이고 조회 정책이 강제한다

`deleted_at`을 채워 삭제하고, **조회 정책에 `deleted_at is null`을 넣는다.** 앱 쿼리마다
필터를 붙이는 방식은 화면이 늘면 언젠가 빠뜨린다. `delete` 권한은 GRANT하지 않는다.

**삭제 실행은 `security definer` RPC 함수로만 한다.** 클라이언트가 `deleted_at`을 직접
UPDATE할 수는 없다 — 이유는 §6의 첫 항목에 있다.

### 목록 인덱스는 부분 인덱스로 만든다

조회가 항상 `deleted_at is null`이므로 인덱스도 그 조건으로 좁힌다. 커서
페이지네이션의 정렬 `(created_at desc, id desc)`과 커서 조건을 한 인덱스가 처리한다.

### 이름 규칙

자식 테이블은 `부모테이블단수_자식`으로 짓는다 (`post_images`). 화면 이름을 접두사로
쓰지 않는다. 인덱스는 `테이블_컬럼_idx`, 정책은 `테이블_동작_범위`
(`posts_select_visible`), 제약은 `테이블_내용`(`posts_content_length`).

---

## 3. 공통 함수

### `set_updated_at()`

`updated_at`을 갱신하는 트리거 함수. 이 함수를 쓰는 테이블마다 트리거를 따로 건다.

```sql
create function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;
```

### `handle_new_user()`

가입과 동시에 프로필을 만든다. `auth.users`에 트리거로 붙으므로 `security definer`가
필요하고, `search_path = ''`는 그 경우의 필수 안전장치라 모든 객체를 스키마까지 적는다.

```sql
create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, nickname)
  values (
    new.id,
    coalesce(
      nullif(new.raw_user_meta_data ->> 'nickname', ''),
      'user_' || substr(replace(new.id::text, '-', ''), 1, 8)
    )
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
```

**같은 트랜잭션에서 실행된다.** 닉네임이 제약을 위반하면 `auth.users` 삽입까지 롤백된다.
동작은 올바르지만 사용자에게는 날것의 DB 오류가 가므로, 앱이 `23514`(check_violation)와
`23505`(unique_violation)를 사용자 문구로 매핑한다.

### `delete_account()`

회원 탈퇴의 유일한 경로다. `security definer` 가 `auth.users` 를 지우고, FK 의
`on delete cascade` 사슬이 나머지를 정리한다.

```sql
create function public.delete_account()
returns void
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := (select auth.uid());
begin
  if uid is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;
  delete from auth.users where id = uid;
end;
$$;

revoke execute on function public.delete_account() from public, anon;
grant execute on function public.delete_account() to authenticated;
```

지워지는 범위: `auth.users` → `profiles` → `posts` → `post_images` ·
`post_comments` · `post_reactions`, 그리고 남의 게시물에 단 내 댓글·반응
(`author_id`/`user_id` 가 `profiles` 를 cascade 로 참조한다). `blocks`(§13)도
여기 포함된다 — `blocker_id`·`blocked_id` 둘 다 `profiles` 를 `on delete
cascade` 로 참조하므로, 탈퇴한 계정이 걸었던 차단과 그 계정을 향해 걸렸던
차단이 양방향 모두 함께 지워진다.

**Storage 는 이 함수가 지우지 않는다.** `storage.objects` 를 SQL 로 직접 지우는
것은 Storage 확장의 보호 트리거가 42501 로 막는다
("Direct deletion from storage tables is not allowed. Use the Storage API instead.").
그래서 `soft_delete_post` 와 같은 분담을 쓴다 — **앱이 탈퇴 전에 자기 경로의
객체를 Storage API 로 best-effort 삭제**하고(자기 경로 DELETE 정책은 이미 있다),
실패해도 탈퇴는 성공으로 본다. 순서가 중요하다: 계정을 먼저 지우면 세션이
사라져 Storage 삭제 정책을 통과할 수 없다.

이미 지워진 계정의 (아직 만료 전인) 토큰으로 다시 부르면 0행 삭제로 끝나는
no-op 이다 — 멱등이라 재시도에 안전하다.

검증(로컬 · PostgREST): anon 401 · 본인 204 · 게시물/댓글/반응 cascade 확인 ·
같은 이메일 재가입 성공.

### `is_blocked_with(other_id uuid) → boolean`

"나와 `other_id` 사이에 차단이 있는가"의 **유일한 정의**다. `blocks`(§13)를 직접
읽는 조건문은 이 함수 하나뿐이어야 한다 — `posts_select_visible`·
`post_comments_select_visible`(§5·§8) 정책, `post_comments_visible`(§9) 뷰,
`enforce_comment_depth()`(§8) 트리거가 모두 이 함수만 부른다. 정의가 네 곳에
흩어지면 언젠가 어긋난다.

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

**`security definer`가 없으면 기능 자체가 성립하지 않는다** — `delete_account()`
같은 방어적 선택이 아니다. `blocks_select_own` 정책(§13)은 `blocker_id =
auth.uid()`인 행만 보여준다: 내가 **건** 차단이다. "상대가 나를 차단했는가"는
내 권한으로는 읽을 수 없는 행을 봐야 하므로, `invoker`로 두면 이 조건은 항상
`false`가 되어 판정이 반쪽만 동작한다.

`stable`은 **같은 문장(statement) 안에서 결과가 바뀌지 않는다**는 보장일 뿐,
같은 인자에 대해 한 번만 평가되는 메모이제이션을 약속하지 않는다 — 실제로는
`posts_select_visible`·`post_comments_select_visible` 정책과
`post_comments_visible` 뷰 모두에서 **행마다 다시 평가된다**(2026-08-25 Task 5
검증에서 실제 REST 호출로 확인). `auth.uid()`는 세션 GUC 기반이라 `definer`
함수 안에서도 **조회자 기준**으로 동작한다 — `my_reaction`(§6)과 같은 근거다.

비로그인(`auth.uid()`가 `null`)이면 두 `or` 갈래 모두 `false`라 `exists`가
`false`를 돌려준다 — 비로그인 조회는 차단 필터의 영향을 받지 않는다.

돌려주는 값이 `boolean` 하나라 "누가 누구를 차단했는지"는 새지 않는다. "나와 이
사람 사이에 차단이 있다"는 사실만 알 수 있고, 그것도 상대의 글이 사라지는
것으로 어차피 드러난다.

### GRANT — `anon`이 반드시 `execute`를 유지해야 한다

```sql
grant execute on function public.is_blocked_with(uuid) to anon, authenticated;
```

(`20260825130000_neutral_block_message.sql`에서 추가.) 이 스키마의 다른 모든 RPC
함수는 `revoke execute on function ... from public, anon; grant execute on
function ... to authenticated` 짝을 명시적으로 쓴다(`delete_account()` 위 참고).
`is_blocked_with()`는 오늘까지 그 짝이 없었다 — PUBLIC 기본 권한으로 `anon`도
이미 실행할 수 있었을 뿐이다. 이 함수를 "강화"하려고 다른 함수들과 같은 패턴을
따라 `anon`의 실행 권한을 걷어내면, `posts_select_visible` ·
`post_comments_select_visible` 정책과 `post_comments_visible` 뷰가 **모든**
게시물·댓글 조회에서 이 함수를 부르므로 비로그인 피드가 통째로 `42501`로
죽는다. 그래서 `revoke`는 넣지 않고 `grant ... to anon, authenticated`만
명시적으로 남겼다 — 다음 사람이 "명시적이지 않다"는 이유로 `anon`을 걷어내지
않도록 `comment on function`에도 같은 경고를 남겼다.

---

## 4. `profiles`

사용자 공개 프로필. `auth.users`와 1:1. 계정 정보(이메일 · 비밀번호 해시 · 세션)는
Supabase Auth가 `auth.users`에서 소유하므로 여기에 두지 않는다.

```sql
create table public.profiles (
  id         uuid        primary key references auth.users (id) on delete cascade,
  nickname   text        not null unique,
  bio        text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint profiles_nickname_length check (char_length(nickname) between 2 and 20),
  constraint profiles_bio_length      check (bio is null or char_length(bio) <= 200)
);

-- 대소문자만 다른 닉네임 중복 차단 (Nickname / nickname)
create unique index profiles_nickname_lower_idx on public.profiles (lower(nickname));

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();
```

### RLS

```sql
alter table public.profiles enable row level security;

-- 조회: 프로필은 공개 정보다
create policy "profiles_select_all"
  on public.profiles
  for select
  to authenticated, anon
  using (true);

-- 수정: 본인만
create policy "profiles_update_own"
  on public.profiles
  for update
  to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);
```

INSERT · DELETE 정책은 두지 않는다. 생성은 `handle_new_user()` 트리거가 전담하고,
삭제는 `auth.users` 삭제 시 `on delete cascade`로 처리된다.

`auth.uid()`를 `(select auth.uid())`로 감싸는 것은 성능 최적화다. Postgres가 행마다
재평가하지 않고 한 번만 계산한다.

### GRANT

```sql
grant select on public.profiles to anon, authenticated;
grant update (nickname, bio, avatar_url) on public.profiles to authenticated;
```

`insert` · `delete` 권한은 주지 않는다.

### Storage `avatars`

프로필 사진은 공개 읽기 `avatars` 버킷에 저장한다(객체 최대 5 MiB). 경로는
`{user_id}/{timestamp}.{webp|jpg}`이며, `storage.objects`의 INSERT·UPDATE·DELETE
정책은 첫 경로 조각이 `(select auth.uid())::text`와 일치할 때만 허용한다.
확장자가 둘인 이유는 아래 MIME 과 같다 — Android 는 WebP, 그 밖은 JPEG 으로
압축하고 실제 형식에 맞는 Content-Type 과 확장자를 함께 보낸다. 따라서 앱이 경로를
변조해 타인의 아바타를 쓰거나 덮어쓸 수 없다.

```sql
allowed_mime_types = array['image/webp', 'image/jpeg']
```

WebP 하나만 허용하지 않는 이유는 §7의 `post-images`와 같다.

---

## 5. `posts`

사용자가 작성한 공개 게시물.

```sql
create table public.posts (
  id         uuid        primary key default gen_random_uuid(),
  author_id  uuid        not null default auth.uid()
                         references public.profiles (id) on delete cascade,
  content    text        not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,

  constraint posts_content_length check (
    char_length(btrim(content)) between 1 and 500
  )
);

create trigger posts_set_updated_at
  before update on public.posts
  for each row execute function public.set_updated_at();
```

`deleted_at`이 null이면 살아있는 행이다.

### 인덱스

```sql
-- 전체 피드 커서
create index posts_created_at_idx
  on public.posts (created_at desc, id desc)
  where deleted_at is null;

-- 프로필 게시물 커서
create index posts_author_id_created_at_idx
  on public.posts (author_id, created_at desc, id desc)
  where deleted_at is null;
```

### RLS

```sql
alter table public.posts enable row level security;

-- 조회: 삭제되지 않았고, 서로 차단 관계가 아닌 게시물만 공개다.
-- 앱이 필터를 빠뜨릴 수 없도록 삭제행 숨김·차단 필터를 여기서 강제한다.
-- is_blocked_with(author_id)(§3)가 비로그인이면 항상 false 를 돌려주므로
-- 이 조건은 로그인한 조회자에게만 적용된다.
create policy "posts_select_visible"
  on public.posts
  for select
  to authenticated, anon
  using (deleted_at is null and not public.is_blocked_with(author_id));

-- 작성: 세션 사용자와 작성자가 항상 일치해야 한다
create policy "posts_insert_own"
  on public.posts
  for insert
  to authenticated
  with check ((select auth.uid()) = author_id);

-- 수정: 본인 글만
create policy "posts_update_own"
  on public.posts
  for update
  to authenticated
  using ((select auth.uid()) = author_id)
  with check ((select auth.uid()) = author_id);
```

DELETE 정책은 두지 않는다. 하드 삭제 경로 자체가 없다.

### GRANT

```sql
grant select on public.posts to anon, authenticated;
grant insert (content) on public.posts to authenticated;
grant update (content) on public.posts to authenticated;
```

`author_id`는 INSERT GRANT에서 빠져 있다. 앱이 보낼 수 없고 `default auth.uid()`로만
채워진다. `deleted_at`도 빠져 있다 — 삭제는 아래 함수로만 한다. `delete` 권한은 주지 않는다.

텍스트만 있는 게시물은 이 INSERT GRANT로 그대로 작성한다. **이미지가 있으면
`create_post_with_images()`를 쓴다** — 두 테이블에 나눠 INSERT하면 원자성이 깨진다.

### `create_post_with_images(content text, images jsonb) → uuid`

게시물과 이미지 메타데이터를 **한 트랜잭션**에 만들고 새 게시물 id를 돌려준다.

```sql
create or replace function public.create_post_with_images(content text, images jsonb)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  marker      constant text := '/object/public/post-images/';
  author      uuid := (select auth.uid());
  new_post_id uuid;
  image_item  jsonb;
  image_url   text;
  object_path text;
begin
  if author is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  -- 행을 만들기 전에 모든 url 을 본다. 하나라도 어긋나면 게시물 자체를 만들지 않는다.
  for image_item in
    select value
      from jsonb_array_elements(
        coalesce(create_post_with_images.images, '[]'::jsonb)
      )
  loop
    image_url := image_item ->> 'url';
    if image_url is null then
      raise exception 'image url required' using errcode = '22023';
    end if;

    object_path := split_part(split_part(image_url, marker, 2), '?', 1);
    if object_path = '' then
      raise exception 'image url must point to the post-images bucket'
        using errcode = '42501';
    end if;

    if split_part(object_path, '/', 1) <> author::text then
      raise exception 'image url must belong to the caller'
        using errcode = '42501';
    end if;

    if split_part(object_path, '/', 2) = '' then
      raise exception 'image url must point to an object'
        using errcode = '42501';
    end if;
  end loop;

  insert into public.posts (author_id, content)
  values (author, create_post_with_images.content)
  returning id into new_post_id;

  insert into public.post_images (post_id, url, width, height, sort_order)
  select
    new_post_id,
    item ->> 'url',
    (item ->> 'width')::integer,
    (item ->> 'height')::integer,
    (item ->> 'sort_order')::smallint
  from jsonb_array_elements(
    coalesce(create_post_with_images.images, '[]'::jsonb)
  ) as item;

  return new_post_id;
end;
$$;

revoke execute on function public.create_post_with_images(text, jsonb) from public, anon;
grant execute on function public.create_post_with_images(text, jsonb) to authenticated;
```

앱이 `posts`를 먼저 넣고 `post_images`를 뒤이어 넣으면, 중간에 실패했을 때 **이미지 없는
유령 게시물**이 남고 재시도하면 게시물이 두 번 생긴다. 두 INSERT를 함수 하나에 넣어
없앤다.

`security definer`지만 새 권한을 열지 않는다. `author_id`를 `auth.uid()`로 고정하므로
남의 이름으로 쓸 경로가 없고, 길이·장수 제약(`posts_content_length` ·
`post_images_sort_order_range` · `(post_id, sort_order)` 유니크)은 테이블에서 그대로
걸린다.

**`url`도 이 함수가 검증한다.** Storage 정책은 업로드만 막으므로(첫 경로 조각 =
`auth.uid()`), 메타데이터가 가리키는 곳까지 같은 규칙으로 묶으려면 함수가 직접 봐야 한다.
검증하지 않으면 RPC를 직접 부르는 것만으로 남의 공개 이미지나 외부 URL을 자기 게시물에
붙일 수 있다. 통과 조건은 셋이다 — `post-images` 버킷의 공개 URL일 것, 첫 경로 조각이
호출자의 id일 것, 그 뒤에 객체 이름이 있을 것.

**Storage 업로드는 이 트랜잭션 밖이다.** 앱은 이미지를 **먼저** 올리고 마지막에 이
함수를 부른다. 함수가 실패하면 올려둔 객체는 앱이 best-effort로 지운다.

### `soft_delete_post(post_id uuid) → boolean`

게시물을 삭제하는 **유일한 경로**다. 삭제된 행이 있으면 `true`, 없거나 남의 글이면
`false`를 돌려준다.

```sql
create or replace function public.soft_delete_post(post_id uuid)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  affected integer;
begin
  update public.posts
     set deleted_at = now()
   where id = post_id
     and author_id = (select auth.uid())
     and deleted_at is null;

  get diagnostics affected = row_count;

  if affected > 0 then
    delete from public.post_images as pi
     where pi.post_id = soft_delete_post.post_id;
  end if;

  return affected > 0;
end;
$$;

-- 함수는 기본적으로 PUBLIC 에 EXECUTE 가 부여된다. 먼저 회수하고 다시 준다.
revoke execute on function public.soft_delete_post(uuid) from public, anon;
grant execute on function public.soft_delete_post(uuid) to authenticated;
```

`security definer`가 RLS를 우회하므로 **함수 안의 `author_id = (select auth.uid())`가
권한 경계 그 자체다.** 이 조건을 빼면 아무나 남의 글을 지울 수 있다.

`deleted_at is null` 조건은 이미 삭제된 글을 다시 삭제해도 `deleted_at`이 갱신되지 않게
한다. 삭제 시각이 뒤로 밀리지 않는다.

**이미지 행도 같은 함수에서 지운다.** `post_images`는 `posts`를 `on delete cascade`로
참조하지만 소프트 삭제는 행을 지우지 않으므로 cascade가 돌지 않는다. 조회 정책이 가려줄
뿐 행은 영원히 남는다. `security definer`라 `post_images`의 RLS가 이 DELETE를 막지 않는다.

Storage 객체는 DB가 지울 수 없으므로 앱이 지운다. 삭제 **전에** 이미지 URL을 읽어두고
(삭제 후에는 조회 정책이 가린다), RPC가 `true`를 주면 객체를 지운다. 게시물은 이미
숨겨졌으므로 이 정리가 실패해도 삭제는 성공으로 본다.

---

## 6. `posts_with_author` (뷰)

피드 목록이 읽는 유일한 대상. 게시물에 작성자 프로필을 조인해 한 번에 내려준다.
목록을 받은 뒤 작성자를 한 명씩 조회하면 페이지당 N번의 왕복이 더 생긴다(N+1).

```sql
create view public.posts_with_author
with (security_invoker = on) as
select
  p.id,
  p.author_id,
  p.content,
  p.created_at,
  p.updated_at,
  pr.nickname   as author_nickname,
  pr.avatar_url as author_avatar_url,
  coalesce(images.items,    '[]'::jsonb) as images,
  coalesce(reactions.counts, '{}'::jsonb) as reaction_counts,
  mine.type                              as my_reaction,
  coalesce(comments.total, 0)            as comment_count
from public.posts p
join public.profiles pr on pr.id = p.author_id
left join lateral (...) images    on true   -- post_images 를 jsonb 배열로 (§7)
left join lateral (...) reactions on true   -- post_reactions 를 type 별 개수로 (§10)
left join lateral (...) mine      on true   -- 조회자의 post_reactions.type (§10)
left join lateral (...) comments  on true;  -- 살아 있는 post_comments 개수 (§8)
```

`...` 안의 실제 질의는
[`20260823180000_add_reactions.sql`](../supabase/migrations/20260823180000_add_reactions.sql)에
있다. 네 개 모두 `left join lateral` 인 이유는 같다 — 대상이 없을 때 게시물 행이
사라지면 안 되고, 각 서브쿼리가 게시물 하나만 보고 끝나야 한다.

### 집계 컬럼 셋은 N+1 을 없애기 위해 여기 있다

| 컬럼 | 타입 | 값 |
|---|---|---|
| `reaction_counts` | `jsonb` | `{"like": 3, "dislike": 1}` · 없으면 `{}` |
| `my_reaction` | `text` | 조회자가 남긴 감정 하나 · 없거나 비로그인이면 `null` |
| `comment_count` | `bigint` | 살아 있는 댓글 + 답글 전부 |

개수를 `like_count` · `dislike_count` 컬럼으로 박지 않고 `jsonb` 로 내리는 이유는,
감정 종류를 하나 더할 때 **뷰를 고치지 않기 위해서다.** 앱은 모르는 키를 무시한다.

`my_reaction` 은 `(select auth.uid())` 에 의존한다. `auth.uid()` 는 JWT 클레임을 읽는
세션 GUC 기반이라 뷰의 실행 역할과 무관하게 **조회자 기준**으로 동작한다 — §9 가
`security_invoker = off` 인데도 같은 컬럼을 내릴 수 있는 이유다.

`comment_count` 의 lateral 은 `post_comments_select_visible` 정책이 걸린
`post_comments` 를 스캔하므로, 훑는 댓글 행마다 그 정책의 `is_blocked_with()`
호출이 함께 실행된다. `is_blocked_with()` 가 `security definer` 이고
`search_path` 를 비워 SQL 인라이너 대상에서 제외되므로(§3), 이것은 상수
접기가 아니라 댓글 수만큼의 진짜 함수 호출이다 — N+1 을 없앤 이 집계 컬럼이,
차단 필터 자체는 행 단위 비용을 그대로 지불한다는 뜻이다.

### `security_invoker = on` 은 선택 사항이 아니다

**뷰는 기본적으로 소유자(`postgres`) 권한으로 실행된다.** 이 옵션을 빼면
`posts_select_visible`(`deleted_at is null`)이 평가되지 않아 **삭제된 게시물이 이 뷰로
그대로 새어 나온다.** §2의 "삭제행 숨김을 조회 정책이 강제한다"가 뷰 하나로 무너진다.

`on` 이면 뷰를 **조회한 세션 사용자**의 권한으로 기반 테이블의 RLS 가 그대로 평가된다.
뷰는 정책을 우회하는 통로가 아니라 조인에 붙인 이름일 뿐이다.

**앞으로 이 스키마에 추가되는 모든 뷰에 같은 규칙을 적용한다.** 첫 예외는
`post_comments_visible`(§9)이다 — 예외로 둔 이유는 해당 절에 있다.

### GRANT

```sql
grant select on public.posts_with_author to anon, authenticated;
```

**뷰는 기반 테이블의 GRANT 를 물려받지 않는다.** 따로 줘야 한다. 조회 전용이므로
`insert` · `update` 권한은 주지 않는다 — 게시물 작성·수정은 `posts` 에 직접 한다.

### 인덱스

따로 만들지 않는다. 뷰는 저장된 질의라 §5의
`posts_created_at_idx (created_at desc, id desc) where deleted_at is null` 를 그대로 탄다.
플래너가 `posts` 를 인덱스 순으로 훑다가 `LIMIT` 만큼만 `profiles` 를 PK 로 붙이므로
커서 페이지네이션의 비용은 조인 전과 같다.

### 앞으로 여기에 붙는 것

반응 수(F5) · 내 반응 상태 · 댓글 수(F6) · F7 차단 필터까지 **모두 붙었다.** 차단
필터는 이 뷰의 `where`가 아니라 `posts_select_visible`(§5) 정책에 넣었다 — 이
뷰가 `security_invoker = on`이라 정책을 그대로 물려받으므로, 정책 하나만 고치면
이 뷰·`posts` 직접 조회·`comment_count` 서브쿼리가 한꺼번에 덮인다. 뷰 정의
자체는 그대로다.

---

## 7. `post_images`

게시물에 붙는 공개 이미지 메타데이터다. 원본은 Storage `post-images` 버킷에 두고,
이 테이블에는 공개 URL과 레이아웃을 미리 잡기 위한 치수만 둔다.

```sql
create table public.post_images (
  id         uuid primary key default gen_random_uuid(),
  post_id    uuid not null references public.posts (id) on delete cascade,
  url        text not null,
  width      integer not null check (width > 0),
  height     integer not null check (height > 0),
  sort_order smallint not null check (sort_order between 0 and 4),
  unique (post_id, sort_order)
);

create index post_images_post_id_sort_order_idx
  on public.post_images (post_id, sort_order);
```

게시물당 최대 5장은 `sort_order 0..4` 제약과 `(post_id, sort_order)` 유니크 제약으로
DB도 강제한다. 작성자는 자기 게시물에 추가하는지를 RLS의 `exists(posts ...)`로 확인한다. 조회도
살아 있는 게시물에 속한 행만 허용하므로 소프트 삭제된 게시물의 이미지는 SDK 조회에서
보이지 않는다.

```sql
grant select on public.post_images to anon, authenticated;
grant insert (post_id, url, width, height, sort_order) on public.post_images to authenticated;
grant update (url, width, height, sort_order) on public.post_images to authenticated;
```

삽입은 `create_post_with_images()`(§5)가 하고, 소프트 삭제 때는 `soft_delete_post()`가
같은 트랜잭션에서 이 테이블의 행을 지운다.

### Storage `post-images`

공개 읽기 버킷이며 객체 최대 5 MiB, MIME은 아래 둘만 허용한다.

```sql
allowed_mime_types = array['image/webp', 'image/jpeg']
```

WebP만 허용하면 iOS에서 업로드가 전부 실패한다. `flutter_image_compress`가 iOS에서는
WebP를 **인코딩하지 못하기** 때문이다. 앱은 Android에서 WebP, 그 밖에서는 JPEG으로
압축하고 실제 형식에 맞는 Content-Type과 확장자를 함께 보낸다.

앱 경로는 `{user_id}/{uuid}/{순서}.{webp|jpg}`다. 가운데 조각은 **게시물 id가 아니라
클라이언트가 만든 UUID**다 — 업로드가 게시물 생성보다 먼저이므로 그 시점에는 게시물
id가 없다. 정책이 보는 것은 첫 조각뿐이라 문제되지 않는다.

`storage.objects`의 INSERT·UPDATE·DELETE 정책은 첫 경로 조각이
`(select auth.uid())::text`와 같을 때만 허용한다. 이 검증을 앱의 경로 생성에 맡기지
않으므로, 다른 사용자의 prefix로 업로드하거나 남의 이미지를 지울 수 없다.
메타데이터 쪽 같은 경계는 `create_post_with_images()`(§5)가 `url`을 검사해 지킨다.

```sql
create policy "post_images_storage_delete_own"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'post-images'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
```

DELETE 정책은 게시물 삭제 뒤 앱이 객체를 정리하기 위해 필요하다. 없으면 DB 행만
사라지고 이미지는 공개 URL로 계속 열린다.

`posts_with_author`는 `images` JSON 배열(URL·가로·세로·순서)을 함께 내려준다. 뷰는
계속 `security_invoker = on`이므로 게시물과 이미지의 RLS가 조회자 권한으로 적용된다.

---

## 8. `post_comments`

게시물에 달리는 댓글과 답글. **depth는 2단 고정**이다 — 답글에는 답글을 달 수 없다.
설계 근거는 [F6 계획](features/comment/plan.md)에 있다.

```sql
create table public.post_comments (
  id         uuid        primary key default gen_random_uuid(),
  post_id    uuid        not null references public.posts (id) on delete cascade,
  parent_id  uuid        references public.post_comments (id) on delete cascade,
  author_id  uuid        not null default auth.uid()
                         references public.profiles (id) on delete cascade,
  content    text        not null,
  created_at timestamptz not null default now(),
  deleted_at timestamptz,

  constraint post_comments_content_length check (
    char_length(btrim(content)) between 1 and 300
  )
);
```

`parent_id`가 `null`이면 부모(최상위) 댓글, 아니면 답글이다. 수정 기능은 없으므로
`updated_at` 컬럼도 두지 않는다.

### 인덱스

```sql
-- 부모 댓글 커서. 조회 방향이 오래된 순이라 asc 다.
-- deleted_at 부분 조건을 일부러 넣지 않는다 — 삭제된 부모도 살아 있는 답글이
-- 있으면 목록에 나와야 하므로 조회가 삭제행을 읽는다.
create index post_comments_root_idx
  on public.post_comments (post_id, created_at, id)
  where parent_id is null;

-- 답글 커서. 답글은 삭제되면 항상 숨기므로 부분 인덱스를 그대로 쓴다.
-- reply_count 서브쿼리와 "살아 있는 답글이 있는가" 검사도 이 인덱스를 탄다.
create index post_comments_reply_idx
  on public.post_comments (parent_id, created_at, id)
  where parent_id is not null and deleted_at is null;
```

`post_comments_root_idx`는 §2의 "목록 인덱스는 부분 인덱스로 만든다"의 **예외**다.
`where deleted_at is null`을 넣지 않은 이유는 `post_comments_visible`(§9)이 "삭제됐지만
살아 있는 답글이 남은 부모"를 계속 보여줘야 하기 때문이다. 뷰의 조회가 삭제된 부모
행까지 읽어야 하므로, 인덱스를 삭제행 제외로 좁히면 그 조회가 인덱스를 타지 못한다.

### `enforce_comment_depth()`

depth 2 제한과 부모 무결성(같은 게시물, 삭제되지 않은 부모), 그리고 F7 차단(게시물
작성자를 차단했거나 차단당했으면 댓글 삽입 거부)을 검사하는 트리거 함수다. CHECK
제약으로는 다른 행을 참조할 수 없어 표현할 수 없다.

차단 거부 문구는 `이 게시물에는 댓글을 달 수 없습니다`로, 방향을 밝히지 않는다.
최초 구현(`20260825120000_add_blocks.sql`)은 `차단한 사용자의 게시물에는 댓글을
달 수 없습니다`를 던졌는데, 이 예외를 실제로 보는 쪽은 차단"한" 사람이 아니라
차단"당한" 사람이다 — 차단당한 B가 A의 게시물 화면을 이미 연 상태에서 A가 B를
차단하고 B가 댓글을 등록하면 이 트리거에 걸린다. B는 아무도 차단하지 않았으므로
"차단한 사용자"는 B에게 거짓이고, 동시에 차단이 존재한다는 사실과 그 방향까지
차단당한 당사자에게 드러낸다 — 계획서의 "차단 사실 노출: 알리지 않는다"([계획
서](features/safety/plan-block.md))를 정면으로 어긴다. 적용된 마이그레이션은
고치지 않으므로 `20260825130000_neutral_block_message.sql`이 `create or
replace function`으로 문구만 바꿨다 — 나머지 네 검사는 그대로다.

```sql
create function public.enforce_comment_depth()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  post_author_id   uuid;
  parent_post_id   uuid;
  parent_parent_id uuid;
  parent_deleted   timestamptz;
begin
  select author_id into post_author_id
    from public.posts
   where id = new.post_id;

  if post_author_id is not null and public.is_blocked_with(post_author_id) then
    raise exception '이 게시물에는 댓글을 달 수 없습니다'
      using errcode = '42501';
  end if;

  if new.parent_id is null then
    return new;
  end if;

  select post_id, parent_id, deleted_at
    into parent_post_id, parent_parent_id, parent_deleted
    from public.post_comments
   where id = new.parent_id;

  if not found then
    raise exception '부모 댓글이 없습니다' using errcode = '23503';
  end if;
  if parent_parent_id is not null then
    raise exception '답글에는 답글을 달 수 없습니다' using errcode = '23514';
  end if;
  if parent_post_id <> new.post_id then
    raise exception '부모 댓글이 다른 게시물의 댓글입니다' using errcode = '23514';
  end if;
  if parent_deleted is not null then
    raise exception '삭제된 댓글에는 답글을 달 수 없습니다' using errcode = '23514';
  end if;

  return new;
end;
$$;

create trigger post_comments_enforce_depth
  before insert on public.post_comments
  for each row execute function public.enforce_comment_depth();
```

`security definer`인 이유: `authenticated`에게 `content` SELECT 권한을 주지 않으므로
(아래 GRANT 참고), `invoker`로 두면 트리거가 부모 행 자체를 읽지 못해 삽입이 막힌다.
함수 소유자(테이블 소유자) 권한으로 실행돼야 부모 행을 읽을 수 있다.

**차단 검사가 정책(`with check`)이 아니라 이 트리거에 있는 이유.** 정책 안에서
게시물 작성자를 찾으려면 `posts`를 서브쿼리로 읽어야 하는데, 그 조회는
`posts_select_visible`(§5)에 넣은 차단 필터에 먼저 걸려 행 자체가 사라진다.
그러면 작성자가 `null`로 조회되고 `is_blocked_with(null)`이 `false`가 되어
**삽입이 도리어 허용된다.** `enforce_comment_depth()`는 이미 `security definer`라
RLS를 우회하므로 이 함정이 없다 — 새 트리거를 만들지 않고 기존 트리거에 검사를
하나 얹은 이유이기도 하다.

차단 검사가 `new.parent_id is null` 이른 반환보다 **앞**에 있는 이유: 최상위
댓글도 게시물 작성자 차단을 봐야 한다. depth·부모 검사 네 가지는 답글에만
해당하므로 그 뒤에 그대로 남아 있다 — 하나도 잃지 않았다.

### RLS

```sql
alter table public.post_comments enable row level security;

-- ★ 여기서 post_comments 를 서브쿼리로 다시 참조하면 PostgreSQL 이 정책을 재귀로
-- 판단해 42P17 로 거부한다 (조회뿐 아니라 insert ... returning 까지 죽는다).
-- "삭제됐지만 답글이 남은 부모"를 되살리는 일은 아래 definer 뷰가 전담한다.
-- posts 는 다른 테이블이라 참조해도 재귀가 아니다 — 아래 insert 정책과 같다.
create policy "post_comments_select_visible"
  on public.post_comments for select to anon, authenticated
  using (
    deleted_at is null
    and not public.is_blocked_with(author_id)
    and exists (
      select 1 from public.posts p
       where p.id = post_comments.post_id and p.deleted_at is null
    )
  );

create policy "post_comments_insert_own"
  on public.post_comments for insert to authenticated
  with check (
    (select auth.uid()) = author_id
    and exists (
      select 1 from public.posts
      where posts.id = post_comments.post_id
        and posts.deleted_at is null
    )
  );
```

UPDATE · DELETE 정책은 두지 않는다. 수정 기능이 없고 삭제는 아래 함수 전용이다.

조회 정책의 `exists (posts …)` 는 **소프트 삭제된 게시물의 댓글**을 테이블 경로에서도
감춘다 (`20260827161417_hide_comments_of_deleted_post.sql`). 원래 정책은 부모의 생존을
보지 않았고, 앱이 `post_comments_visible`(§9) 뷰로만 읽는 덕에 화면에는 드러나지
않았을 뿐이었다 — 로그인한 사용자가 PostgREST 로 원본 테이블을 직접 조회하면 이미
삭제된 게시물의 댓글이 그대로 읽혔다(2026-08-27 검증에서 실제 JWT 로 재현). 뷰는
`security_invoker = off` 라 이 정책에 영향받지 않고, `insert ... returning` 경로도
그대로 동작한다(같은 날 확인).

INSERT 정책의 `exists (posts …)` 는 **삭제된 게시물에 댓글이 달리는 것**을 막는다. 처음에는
작성자만 확인했는데, 그러면 소프트 삭제된 게시물에 삽입이 201 로 성공했다.
유출은 아니다 — §9 의 뷰가 살아 있는 게시물만 조인하므로 그 댓글은 어디에도
보이지 않는다. 문제는 **쓰기가 조용히 성공하는 것**이다: 앱이 낙관적으로 목록에
붙이고, 새로고침하면 사라진다. 사용자에게는 댓글이 증발한 것으로 보인다.
`post_reactions_insert_own`(§10)은 처음부터 같은 검사를 하고 있었으므로 두 경로의
강도를 맞춘 것이다. 서브쿼리가 **다른 테이블**을 보므로 §11 의 42P17 과는 무관하다.

**정책 안에서 같은 테이블을 서브쿼리로 참조하면 안 된다.** 처음 시도한 정책은
"삭제됐지만 살아 있는 답글이 있는 부모는 보인다"를 `post_comments` 자신을 향한
`exists` 서브쿼리로 표현했는데, PostgreSQL이 이를 재귀로 판단해 아래 오류로
거부했다.

```text
42P17: infinite recursion detected in policy for relation "post_comments"
```

데이터의 depth(2단)와 무관하게 **구조적으로 항상 발생**한다 — 정책 평가 중 서브쿼리가
같은 테이블을 다시 스캔하면 그 스캔에도 같은 정책이 다시 걸리고, 그 정책의
서브쿼리에도 다시 걸리는 식으로 쿼리 재작성이 끝나지 않는다. 조회뿐 아니라
`insert ... returning`처럼 SELECT 정책이 함께 평가되는 모든 경로가 같이 막힌다.

그래서 이 정책은 "삭제되지 않은 행만" 이라는 좁은 규칙만 갖는다. "삭제됐지만 답글이
남은 부모를 되살리는" 일은 `post_comments_visible`(§9)이 전담한다 — 그 뷰는
`security_invoker = off`라 이 정책을 아예 거치지 않으므로 재귀 문제가 생기지 않는다.
테이블 직접 조회 경로가 뷰보다 좁아지는 것은 정보가 새는 방향이 아니라 안전한
방향이다.

### GRANT

```sql
grant select (id, post_id, parent_id, author_id, created_at, deleted_at)
  on public.post_comments to anon, authenticated;
grant insert (post_id, parent_id, content)
  on public.post_comments to authenticated;
```

`content`는 SELECT GRANT에서 빠진다. 본문에 닿는 유일한 경로가
`post_comments_visible`(§9)이고, 그 뷰가 삭제행의 본문을 `null`로 지운다. 컬럼
GRANT에서 빼면 테이블을 직접 조회해도 삭제 여부와 무관하게 본문 자체를 읽을 수
없다.

나머지 컬럼을 SELECT GRANT에 남기는 이유는 둘이다.

1. `insert ... returning id, created_at`이 동작해야 한다 (왕복 한 번으로 작성).
2. `posts_with_author`(`security_invoker = on`)에 댓글 수를 붙일 때, 그 서브쿼리가
   `post_id` · `deleted_at`을 조회자 권한으로 읽어야 한다.

### `soft_delete_post_comment(comment_id uuid) → boolean`

댓글을 삭제하는 유일한 경로다. 본인 댓글이고 아직 삭제되지 않았을 때만 `deleted_at`을
채우고 `true`를 돌려준다.

```sql
create function public.soft_delete_post_comment(comment_id uuid)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  affected integer;
begin
  update public.post_comments
     set deleted_at = now()
   where id = comment_id
     and author_id = (select auth.uid())
     and deleted_at is null;

  get diagnostics affected = row_count;
  return affected > 0;
end;
$$;

revoke execute on function public.soft_delete_post_comment(uuid) from public, anon;
grant execute on function public.soft_delete_post_comment(uuid) to authenticated;
```

`security definer`가 RLS를 우회하므로 함수 안의 `author_id = (select auth.uid())`가
권한 경계 그 자체다. 클라이언트 UPDATE로는 애초에 불가능하다 — §11의 첫 항목 참고.

---

## 9. `post_comments_visible` (뷰)

댓글 목록이 읽는 유일한 대상. 작성자 프로필을 조인하고, 삭제된 부모 댓글을 답글이
살아 있으면 계속 보여주며, 답글 수를 함께 내려준다.

```sql
create view public.post_comments_visible as
select
  c.id,
  c.post_id,
  c.parent_id,
  c.author_id,
  case when c.deleted_at is null then c.content end as content,
  c.created_at,
  c.deleted_at,
  pr.nickname   as author_nickname,
  pr.avatar_url as author_avatar_url,
  (
    select count(*)
      from public.post_comments reply
     where reply.parent_id = c.id and reply.deleted_at is null
       and not public.is_blocked_with(reply.author_id)
  ) as reply_count,
  coalesce(reactions.counts, '{}'::jsonb) as reaction_counts,
  mine.type                               as my_reaction
from public.post_comments c
join public.profiles pr on pr.id = c.author_id
join public.posts    p  on p.id = c.post_id and p.deleted_at is null
left join lateral (...) reactions on true   -- comment_reactions 를 type 별 개수로 (§10)
left join lateral (...) mine      on true   -- 조회자의 comment_reactions.type (§10)
where not public.is_blocked_with(c.author_id)
  and (
    c.deleted_at is null
    or (
      c.parent_id is null
      and exists (
        select 1 from public.post_comments reply
        where reply.parent_id = c.id and reply.deleted_at is null
          and not public.is_blocked_with(reply.author_id)
      )
    )
  );

grant select on public.post_comments_visible to anon, authenticated;
```

### `security_invoker = off`(기본값)가 이 스키마의 첫 예외다

§6에서 "앞으로 추가되는 모든 뷰에 `security_invoker = on`을 적용한다"고 했지만, 이
뷰만 기본값(off)을 그대로 둔다. `on`으로 두면 `post_comments_select_visible`(§8, `deleted_at
is null`만 봄)이 먼저 걸려 "삭제됐지만 답글이 남은 부모"를 되살릴 방법이 없고,
그렇다고 그 정책을 넓히면(§8에서 시도했다가 42P17로 실패한 것처럼) 삭제된 본문이
테이블 직접 조회로 샐 위험이 생긴다. 뷰를 소유자 권한으로 두고 뷰 정의 자체에서
가시성을 계산하는 쪽이, 재귀 없이 두 요구(부모는 살리고 본문은 가림)를 동시에
만족하는 유일한 방법이었다.

F7(`20260825120000_add_blocks.sql`)이 이 뷰를 `create or replace view` 로 다시
정의하면서 `with (security_invoker = ...)` 절을 쓰지 않았다. `create or
replace view` 는 명시하지 않은 reloption 을 리셋하므로 이 뷰는 그 순간
기본값(`off`)으로 되돌아갔다 — 마침 이 뷰가 원하는 값과 같았을 뿐인
우연이다. 형제인 `posts_with_author`(§6)는 같은 F7 커밋에서 함께 `create or
replace` 됐는데, 그쪽은 `security_invoker = on` 이 필요해서 매번 재정의할 때
`with (security_invoker = on)` 을 다시 명시한다 — 이 뷰가 `on` 을 쓰지 않는
것은 실수로 빠뜨린 게 아니라, 원하는 값이 기본값과 우연히 같아서 생략해도
결과가 맞았을 뿐이라는 뜻이다. 다음에 이 뷰를 `create or replace` 할 사람은
`off` 를 원한다는 것을 알고 생략하는 것이지, 아무것도 안 써도 된다는 뜻이
아니다.

뷰가 RLS를 우회하므로, RLS가 대신 해주던 것을 뷰 정의 안에 직접 손으로 적어야 한다.
이 두 가지가 그 부채다.

- `join public.posts p on p.id = c.post_id and p.deleted_at is null` — 게시물이
  소프트 삭제되면 그 댓글도 함께 가려야 한다. `posts_select_visible` 정책이 해주던
  일을 여기서는 join 조건으로 직접 쓴다.
- F7(차단) 필터도 **여기 손으로 적었다.** `is_blocked_with()`(§3)를 세 곳에 건다 —
  본문 `where`, `reply_count` 서브쿼리, "살아 있는 답글이 있는가" `exists`. 셋 중
  하나라도 빠지면 개수와 목록이 어긋난다: 답글 3개로 표시되는데 펼치면 1개가
  나오는 식이다. `post_comments_select_visible`(§8) 정책에 같은 필터를 넣어도 이
  뷰는 `security_invoker = off`라 그 정책을 거치지 않으므로, 뷰에도 반드시 직접
  써야 한다.

### 집계 컬럼

`reaction_counts` · `my_reaction` 의 의미와 형태는 §6과 같고, 보는 테이블만
`comment_reactions` 다. 댓글 목록 조회 한 번에 답글 수와 반응 요약이 함께 오므로
항목당 추가 조회가 없다.

삭제된 부모 댓글은 `content` 만 `null` 이 되고 `reply_count` · `reaction_counts` 는
그대로 나온다. 반응을 남길 수 있는지는 §10의 INSERT 정책이 `deleted_at is null` 로
막으므로, 앱이 삭제된 댓글에 반응 버튼을 그리지 않는 것은 UX 이고 경계는 DB 다.

### GRANT

뷰는 기반 테이블의 GRANT를 물려받지 않는다. 조회 전용이므로 `insert` · `update`
권한은 주지 않는다 — 댓글 작성은 `post_comments`에, 삭제는 `soft_delete_post_comment()`에
직접 한다.

---

## 10. `post_reactions` · `comment_reactions`

게시물과 댓글에 남기는 감정이다. **대상별 테이블 두 개**이고 모양이 같다. 폴리모픽
단일 테이블(`target_type` + `target_id`)을 쓰지 않는 이유는 FK·cascade 를 잃고 RLS 가
`target_type` 분기투성이가 되기 때문이다 — 근거는
[F5 계획](features/reaction/plan.md)에 있다.

```sql
create table public.post_reactions (
  user_id    uuid        not null default auth.uid()
                         references public.profiles (id) on delete cascade,
  post_id    uuid        not null references public.posts (id) on delete cascade,
  type       text        not null,
  created_at timestamptz not null default now(),

  primary key (user_id, post_id),
  constraint post_reactions_type_valid check (type in ('like', 'dislike'))
);

create index post_reactions_post_id_type_idx
  on public.post_reactions (post_id, type);
```

`comment_reactions` 는 `post_id` → `comment_id`(`references public.post_comments`)만
바뀌고 나머지가 같다. 인덱스는 `(comment_id, type)`, CHECK 이름은
`comment_reactions_type_valid` 다.

- **PK `(user_id, 대상_id)`** 가 "대상당 감정 하나"를 강제한다. 좋아요 상태에서
  싫어요를 누르면 좋아요가 해제된다는 규칙이 이 PK 위에서 성립한다.
- **취소는 행 삭제**다. 반응에는 자식이 달리지 않으므로 소프트 삭제(§2)의 이유가 없다.
  이 스키마에서 `delete` GRANT 를 주는 유일한 테이블 둘이다.
- **`created_at` 은 정렬·표시에 쓰지 않는다.** 전환(upsert)에서 갱신되지 않는 것이
  문제가 되지 않는 이유다.
- 개수는 §6 · §9 의 뷰가 집계한다. 비정규화 카운트 컬럼은 성능 문제가 **관측된 뒤에**
  한다.

### RLS

```sql
-- 조회: 개수는 공개 정보다
create policy "post_reactions_select_all"
  on public.post_reactions for select to anon, authenticated using (true);

-- 삽입: 본인 것만, 그리고 살아 있는 대상에만
create policy "post_reactions_insert_own"
  on public.post_reactions for insert to authenticated
  with check (
    (select auth.uid()) = user_id
    and exists (select 1 from public.posts
                 where posts.id = post_reactions.post_id
                   and posts.deleted_at is null)
  );

-- 수정: with check 를 INSERT 와 같은 강도로 맞춘다 (아래 GRANT 참고)
create policy "post_reactions_update_own"
  on public.post_reactions for update to authenticated
  using ((select auth.uid()) = user_id)
  with check (
    (select auth.uid()) = user_id
    and exists (select 1 from public.posts
                 where posts.id = post_reactions.post_id
                   and posts.deleted_at is null)
  );

create policy "post_reactions_delete_own"
  on public.post_reactions for delete to authenticated
  using ((select auth.uid()) = user_id);
```

`comment_reactions` 의 `exists` 는 `post_comments` 를 보고 `deleted_at is null` 을
확인한다. **삭제된 게시물·댓글에는 반응을 남길 수 없고, 그 판단은 앱이 아니라 DB 가
한다.**

**F7 차단(§13)의 부작용:** 이 `exists` 서브쿼리는 `posts`·`post_comments` 를 그대로
조회하므로 `posts_select_visible`·`post_comments_select_visible` 정책(§5·§8, 둘 다
`is_blocked_with()`를 건다)의 적용을 그대로 받는다. 그 결과 **차단 관계에서는
감정표현 삽입도 함께 막힌다** — [차단 계획](features/safety/plan-block.md)은
"상호작용 차단은 댓글 삽입까지만, 감정표현은 막지 않는다"고 결정했지만, 실제로는
차단된 대상의 글이 `exists`에 아예 잡히지 않아 반응 삽입이 `42501`로 거부된다.
2026-08-25 Task 5 검증에서 REST로 확인했다(B가 차단한 A의 게시물에 좋아요 삽입 →
`403`, `new row violates row-level security policy for table "post_reactions"`).
사용자가 볼 수 있는 문제는 아니다 — 애초에 보이지 않는 글에는 반응할 UI 자체가
없다. 다만 스펙보다 DB 가 더 엄격해진 것이라 다음에 이 자리를 보는 사람이 버그로
오인하지 않도록 남긴다.

정책 안에서 다른 테이블(`posts` · `post_comments`)을 참조하는 것은 §11의 42P17 과
무관하다. 재귀로 판정되는 것은 **정책이 걸린 그 테이블 자신**을 다시 참조할 때다.

### GRANT — `update` 에 대상 id 가 들어가는 이유

```sql
grant select                 on public.post_reactions to anon, authenticated;
grant insert (post_id, type) on public.post_reactions to authenticated;
grant update (post_id, type) on public.post_reactions to authenticated;
grant delete                 on public.post_reactions to authenticated;
```

전환(좋아요 → 싫어요)은 **upsert 한 번**이다. 삭제 후 삽입은 왕복이 둘이고 중간 상태가
보인다. 그런데 PostgREST 는 `on conflict ... do update set` 에 **페이로드의 모든 컬럼**을
넣는다. `{post_id, type}` 을 보내면 실제로 실행되는 것은 이것이다.

```sql
set post_id = excluded.post_id, type = excluded.type
```

`type` 만 GRANT 하면 전환이 42501 로 막힌다. 그래서 `post_id` 에도 UPDATE 를 준다.

**그 대가로 UPDATE 정책의 `with check` 를 INSERT 와 같은 강도로 맞춰야 한다.** 그러지
않으면 `post_id` 를 바꿔 살아 있는 게시물의 반응을 **삭제된 게시물로 옮기는** 경로가
열린다. 두 정책의 `with check` 가 글자 그대로 같은 이유다.

`user_id` 는 INSERT 목록에 없다. `default auth.uid()` 로만 채워지므로 위조 경로가 없다.

### 검증한 것 (로컬 Supabase · PostgREST 경유)

`psql` 로는 GRANT 와 upsert 의 상호작용이 드러나지 않는다. REST 로 확인했다.

| 요청 | 결과 |
|---|---|
| `Prefer: resolution=merge-duplicates` 로 첫 `like` | `201` |
| 같은 방식으로 `dislike` 전환 | `200` (42501 아님) |
| `posts_with_author` 조회 | `{"dislike": 1}` · `my_reaction: "dislike"` |
| `delete ?post_id=eq.<id>` 로 취소 | `204` |
| `type: "love"` 삽입 | `400` (check_violation) |

---

## 11. 알아둘 함정

### 소프트 삭제를 UPDATE로 하면 42501로 거부된다

**PostgreSQL은 UPDATE의 SELECT 정책을 *새 행*에도 적용한다.** `deleted_at`을 채우면
새 행이 `posts_select_visible`(`deleted_at is null`)에 걸리므로 UPDATE 자체가 실패한다.

```text
42501: new row violates row-level security policy for table "posts"
```

`RETURNING`이나 PostgREST의 `Prefer: return=` 설정과는 **무관하다.** RETURNING 없는
순수 UPDATE도 똑같이 거부된다 (PostgreSQL 17.6에서 확인).

그래서 소프트 삭제는 `security definer` 함수 `soft_delete_post()`로만 한다. 조회 정책을
느슨하게 푸는 방법(`deleted_at is null or auth.uid() = author_id`)도 있지만, 그러면
작성자에게는 자기 삭제 글이 피드에 계속 보이므로 "DB가 강제한다"는 성질을 잃는다.

이 제약은 앞으로 소프트 삭제를 쓰는 모든 테이블에 똑같이 적용된다. `post_comments`도
전용 함수 `soft_delete_post_comment()`(§8)가 필요했다.

### `alter table ... rename`은 딸린 객체 이름을 바꾸지 않는다

인덱스 · 제약 · 트리거 · 정책 이름은 옛 테이블 이름으로 남는다. rename 마이그레이션에서
`alter table ... rename constraint` · `alter trigger ... rename to` ·
`alter policy ... rename to`로 직접 맞춘다.
([20260822120000](../supabase/migrations/20260822120000_rename_posts_and_soft_delete.sql) 참고)

### RLS 정책 안에서 정책이 걸린 테이블을 서브쿼리로 다시 참조하면 42P17이 난다

`post_comments`의 조회 정책을 처음 설계할 때 "삭제됐지만 답글이 남은 부모는 보인다"를
`post_comments` 자신을 향한 `exists` 서브쿼리로 넣었더니, 데이터양·depth와 무관하게
매번 아래 오류로 거부됐다.

```text
42P17: infinite recursion detected in policy for relation "post_comments"
```

정책이 걸린 테이블을 정책 표현식 안에서 다시 스캔하면, 그 스캔에도 같은 정책이 다시
걸리고 그 정책의 서브쿼리에도 또 걸리는 식으로 쿼리 재작성이 끝나지 않는다. `select`
뿐 아니라 `insert ... returning`처럼 SELECT 정책이 함께 평가되는 모든 경로가 같이
막힌다. 해법은 **자기 자신을 참조하지 않는 것**이고, 예외적인 가시성 규칙("삭제됐지만
답글이 남은 부모는 보인다")은 RLS를 우회하는 `security_invoker = off` 뷰 쪽으로
넘기는 것이다 — 자세한 내용과 근거는 §8·§9에 있다.

**다른 테이블 참조는 재귀가 아니다.** `post_comments` 정책이 `posts`를 `exists`로
보는 것은 안전하며, INSERT 정책이 처음부터 그렇게 하고 있었다. 조회 정책도
2026-08-27에 같은 방식으로 부모 생존을 보게 했다(§8).

### `security_invoker = on`이 아닌 뷰, 부분 인덱스가 아닌 목록 인덱스도 있다

§6은 "앞으로 추가되는 모든 뷰에 `security_invoker = on`을 적용한다"고 했고, §2는
"목록 인덱스는 부분 인덱스로 만든다"고 했다. `post_comments`(§8) · `post_comments_visible`(§9)가
이 두 규칙에 각각 첫 예외를 만든다.

- `post_comments_visible`은 `security_invoker = off`(기본값)다. 삭제된 부모를 답글이
  살아 있을 때 되살리는 일과, RLS 자기참조로 인한 42P17을 동시에 피하는 유일한
  방법이 뷰를 소유자 권한으로 두는 것이었다.
- `post_comments_root_idx`는 `deleted_at is null` 조건이 없는 전체 인덱스다. 위와
  같은 이유로, 삭제된 부모 행도 조회가 읽어야 하기 때문이다.

두 예외 모두 일반 규칙을 어기는 것이 아니라, "왜 이 테이블만 다른가"를 §8·§9에 각각
근거와 함께 적어 두었다. 새 테이블에 이 규칙들을 복사할 때는 이 두 예외를 먼저 확인한다.

---

## 12. `reports`

F7 신고. **게시물 · 댓글 · 사용자** 세 종류를 한 테이블로 받는 폴리모픽 테이블이다.
설계 근거는 [F7 계획](features/safety/plan.md)에 있다.

```sql
create table public.reports (
  id          uuid        primary key default gen_random_uuid(),
  reporter_id uuid        not null default auth.uid()
                          references public.profiles (id) on delete cascade,
  target_type text        not null,
  target_id   uuid        not null,
  reason      text        not null,
  detail      text,
  status      text        not null default 'pending',
  created_at  timestamptz not null default now(),

  constraint reports_target_type_valid check (
    target_type in ('post', 'comment', 'user', 'chat_message')
  ),
  constraint reports_reason_valid check (
    reason in ('spam', 'abuse', 'sexual', 'violence', 'other')
  ),
  constraint reports_status_valid check (
    status in ('pending', 'resolved', 'rejected')
  ),
  -- 빈 문자열이 저장되는 상태를 없앤다. null 이거나, 공백을 걷어내고 1자 이상이다.
  constraint reports_detail_length check (
    detail is null or char_length(btrim(detail)) between 1 and 500
  ),
  -- 컬럼 둘만 보면 판정되는 유일한 자기 신고. 나머지는 트리거가 본다.
  constraint reports_not_self_user check (
    not (target_type = 'user' and reporter_id = target_id)
  ),
  -- 1인 1회. 대상별 신고자 수가 곧 신고 건수가 된다.
  constraint reports_once unique (reporter_id, target_type, target_id)
);
```

**`target_type` + `target_id`, FK 없음.** `post_reactions` · `comment_reactions`(§10)와
달리 대상별로 테이블을 나누지 않는다. 신고는 처음부터 세 종류를 다 받으므로 폴리모픽이
값을 한다 — FK를 포기하는 대가는 아래 트리거가 메운다.

**회원 탈퇴 시 비대칭이 있다.** `reporter_id`에는 `on delete cascade`가 있어 탈퇴한
사용자가 **낸** 신고는 함께 지워진다. 하지만 `target_id`는 폴리모픽이라 FK 자체가 없으므로,
탈퇴한 사용자가 **대상**이 된 신고(`target_type = 'user'`이거나, 그 사용자가 쓴 게시물·
댓글을 겨눈 신고)는 지워지지 않고 가리키는 곳 없는 `target_id`로 남는다. 직관과
반대다 — "내가 신고한 기록은 남고 나를 신고한 기록은 사라질 것" 같지만 실제로는 그
반대다. Studio 조회에서 대상을 못 찾는 신고 행이 있다면 이 경로일 가능성이 크다.

### 제약 6개의 의미

| 제약 | 의미 |
|---|---|
| `reports_target_type_valid` | 대상은 `post` · `comment` · `user` 셋뿐이다 |
| `reports_reason_valid` | 사유는 고정 목록 5개(`spam` · `abuse` · `sexual` · `violence` · `other`)뿐이다 |
| `reports_status_valid` | 상태는 `pending` · `resolved` · `rejected` 셋뿐이다. '검토 중'을 두지 않는 이유는 운영이 Studio 직접 조회라 누가 언제 옮길지가 없어서다 |
| `reports_detail_length` | `detail`은 `null`이거나, 공백을 걷어내고 1자 이상 500자 이하다. `''`과 `null`이 섞이면 `where detail is not null`이 빈 행까지 끌고 오므로, 저장 가능한 "빈 상태"를 하나로 줄인다 |
| `reports_not_self_user` | `target_type = 'user'`이고 대상이 자기 자신이면 거부한다. 컬럼 두 개만 보면 판정되는 유일한 자기 신고라 CHECK로 막는다. 게시물·댓글은 작성자를 알려면 다른 테이블을 읽어야 하므로 아래 트리거가 맡는다 |
| `reports_once` | `(reporter_id, target_type, target_id)` 유니크. 1인 1회이므로 대상별 신고자 수가 곧 신고 건수가 된다 |

### 인덱스 — 운영 조회용이다

```sql
create index reports_target_idx on public.reports (target_type, target_id);
create index reports_status_created_at_idx
  on public.reports (status, created_at desc);
```

앱에는 신고 목록 화면이 없다. 두 인덱스는 Studio에서 "이 게시물이 몇 번 신고됐나"와
"미처리 신고를 오래된 순으로"를 보기 위한 것이다. `reports_once`의 인덱스가 신고자
기준 조회를 덮으므로 따로 만들지 않는다.

### `enforce_report_target()`

폴리모픽이라 FK가 없다. FK가 해주던 일(존재하는 대상인가)과 정책이 못 하는 일(내 것이
아닌가)을 BEFORE INSERT 트리거가 함께 본다.

```sql
create function public.enforce_report_target()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_author uuid;
begin
  if new.target_type = 'post' then
    select author_id into target_author
      from public.posts
     where id = new.target_id and deleted_at is null;
    if not found then
      raise exception '신고할 대상이 없습니다';
    end if;
    if target_author = new.reporter_id then
      raise exception '내 게시물은 신고할 수 없습니다';
    end if;

  elsif new.target_type = 'comment' then
    select author_id into target_author
      from public.post_comments
     where id = new.target_id and deleted_at is null;
    if not found then
      raise exception '신고할 대상이 없습니다';
    end if;
    if target_author = new.reporter_id then
      raise exception '내 댓글은 신고할 수 없습니다';
    end if;

  elsif new.target_type = 'user' then
    perform 1 from public.profiles where id = new.target_id;
    if not found then
      raise exception '신고할 대상이 없습니다';
    end if;
  end if;

  return new;
end;
$$;

create trigger reports_enforce_target
  before insert on public.reports
  for each row execute function public.enforce_report_target();
```

**`security definer`에 `set search_path = ''`가 필요하다.** 트리거가 읽는 컬럼은
`author_id`와 `deleted_at` 뿐이고, 둘 다 `post_comments`의 컬럼 GRANT(§8)와
`post_comments_select_visible` 정책(§8, `deleted_at is null`) 아래 살아 있는 댓글에
대해서는 `invoker` 권한으로도 읽힌다 — "`content`를 SELECT로 주지 않아서"는 이
함수를 definer로 둔 이유가 아니다. 대신 미래에 컬럼 GRANT가 바뀌어도 이 트리거가
계속 옳게 동작하도록 하는 방어적 설계로 definer를 둔다. `enforce_comment_depth()`(§8) ·
`handle_new_user()`(§3)와 같은 형태이고, `search_path = ''`는 definer 함수의 필수
안전장치라 모든 객체를 스키마까지 적는다.

적용된 마이그레이션(`20260824140000_add_reports.sql`)의 주석은 "`content` 컬럼에
SELECT를 주지 않으므로"라는 옛 근거를 그대로 담고 있다 — 이미 적용된 마이그레이션은
고치지 않는다는 규칙이라 주석만 남고 이 문서가 바로잡은 근거를 대신 따른다.

트리거가 하는 검사는 대상 종류별로 다르다.

| `target_type` | 검사 |
|---|---|
| `post` | `posts`에 있고 `deleted_at is null`인가. `author_id`가 신고자면 거부한다 |
| `comment` | `post_comments`에 있고 `deleted_at is null`인가. `author_id`가 신고자면 거부한다 |
| `user` | `profiles`에 존재하는가. 자기 자신 여부는 `reports_not_self_user`가 이미 막았다 |

거부 문구는 `enforce_comment_depth()`(§8)처럼 사용자에게 그대로 보여줄 한국어로
던진다: `신고할 대상이 없습니다` · `내 게시물은 신고할 수 없습니다` ·
`내 댓글은 신고할 수 없습니다`. 앱이 이 문구들을 화면 메시지로 그대로 매핑하므로
문구 자체가 인터페이스다.

### RLS

```sql
alter table public.reports enable row level security;

-- 조회: 본인 신고만. 남이 무엇을 신고했는지는 누구도 볼 수 없다.
create policy "reports_select_own"
  on public.reports for select to authenticated
  using ((select auth.uid()) = reporter_id);

-- 삽입: 본인 것만.
create policy "reports_insert_own"
  on public.reports for insert to authenticated
  with check ((select auth.uid()) = reporter_id);
```

UPDATE · DELETE 정책은 두지 않는다. 신고는 취소되지 않고, `status` 변경은
`service_role`(Studio)의 일이다.

### GRANT

```sql
grant select on public.reports to authenticated;
grant insert (target_type, target_id, reason, detail)
  on public.reports to authenticated;
```

`reporter_id`와 `status`에 INSERT를 **주지 않는 것**이 위조를 막는 방법이다.
`reporter_id`는 `default auth.uid()`가 채우고 `status`는 항상 `pending`으로
시작한다 — §2의 "GRANT는 컬럼 단위로 최소한만 준다"와 "소유자 컬럼은 DB가 채운다"를
그대로 따르는 사례다.

`anon`에는 아무 권한도 주지 않는다. 신고는 로그인한 사용자만 한다.

---

## 13. `blocks` · `blocked_users`(뷰)

F7 차단. 설계 근거는 [계획](features/safety/plan-block.md)에 있다. 신고와 달리 이
테이블 자체는 새 관심사를 더하지 않는다 — 어렵고 위험한 부분은 이미 동작하던
`posts`·`post_comments`의 조회 정책과 `post_comments_visible`(§9) 뷰를 §5·§8·§9에서
재정의한 것이다. 이 절은 그 판정의 근거가 되는 테이블과, 차단 목록 화면이 읽는
뷰만 담는다.

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

복합 PK `(blocker_id, blocked_id)`가 중복 차단을 막고 "내가 차단한 사람들" 조회를
덮는다 — 별도 `unique` 제약이 필요 없다. `is_blocked_with()`(§3)의 양방향 판정이
반대 방향도 읽으므로 `blocks_blocked_idx`가 없으면 모든 게시물 조회가 `blocks`
전체 스캔을 탄다.

자기 차단은 `blocks_not_self` CHECK 하나로 막는다 — 컬럼 둘만 보면 판정되므로
트리거가 필요 없다. 차단 해제는 행 삭제다. 차단에는 자식이 달리지 않으므로
소프트 삭제의 이유가 없다 — `post_reactions`(§10)와 같은 판단이다.

### RLS

```sql
alter table public.blocks enable row level security;

create policy "blocks_select_own" on public.blocks for select to authenticated
  using ((select auth.uid()) = blocker_id);
create policy "blocks_insert_own" on public.blocks for insert to authenticated
  with check ((select auth.uid()) = blocker_id);
create policy "blocks_delete_own" on public.blocks for delete to authenticated
  using ((select auth.uid()) = blocker_id);
```

조회 정책이 **내가 건** 차단만 보여준다 — "상대가 나를 차단했는가"는 이 정책으로는
알 수 없다. 그래서 `is_blocked_with()`가 `security definer`여야 한다(§3). UPDATE
정책·권한은 없다. 차단은 수정되지 않고 걸거나 푸는 것뿐이다.

### GRANT

```sql
grant select, delete on public.blocks to authenticated;
grant insert (blocked_id) on public.blocks to authenticated;
```

`blocker_id`에 INSERT를 주지 않는 것이 위조를 막는 방법이다 — `default auth.uid()`가
채운다. `reports`(§12)와 같은 규칙이다. `anon`에는 아무 권한도 주지 않는다.

### `blocked_users`(뷰)

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

grant select on public.blocked_users to authenticated;
```

`security_invoker = on`이라 `blocks_select_own` 정책이 그대로 걸린다 — 뷰에
`where`를 쓰지 않아도 **내가 건 차단만** 나온다. §6의 기본 규칙이고,
`post_comments_visible`(§9) 같은 예외를 만들 이유가 없다. `profiles`는 필터를
걸지 않는다 — 차단 목록 화면이 차단한 사용자의 닉네임·아바타를 보여줘야 하고,
프로필까지 가리면 내가 누구를 차단했는지 나도 볼 수 없다.

목록은 커서를 쓰지 않는다. 차단 목록이 수백 개가 되는 사용자는 이 앱의 대상이
아니다.

### 검증한 것 (로컬 Supabase · psql, `auth.uid()`를 `set request.jwt.claims`로 대체)

| 확인 | SQLSTATE |
|---|---|
| 자기 차단 삽입 | `23514` (`blocks_not_self`) |
| 같은 사람 중복 차단 삽입 | `23505` (`blocks_pkey`) |
| A가 B를 차단한 뒤 A로 조회 | B의 게시물이 목록에서 사라짐 |
| A가 B를 차단한 뒤 B로 조회 | A의 게시물도 사라짐(양방향) |
| B가 차단한 A의 게시물에 댓글 삽입 | `42501`, "이 게시물에는 댓글을 달 수 없습니다"(`20260825130000_neutral_block_message.sql`로 방향 중립 문구로 교체됨 — 원래 문구는 차단당한 쪽에 방향을 드러냈다) |
| 비로그인(`anon`, `auth.uid()` null) 조회 | 차단 관계와 무관하게 둘 다 보임 |
| 차단 해제(행 삭제) 후 재조회 | 양쪽 모두 다시 보임 |

---

## 14. 채팅 — `chat_rooms` · `chat_participants` · `chat_messages`

F9 오픈 채팅. 설계 근거는 [계획](features/chat/plan.md)에 있다.

이 절에서 앞 절들과 다른 점은 **읽기 권한이 사람이 아니라 방에 붙는다**는 것이다.
게시물·댓글은 "공개이되 차단한 사람의 것만 가린다"였지만, 메시지는 그 방의 참여자가
아니면 존재 자체가 보이지 않는다. 그 판정을 `is_room_member()`(§3 과 같은 모양의
security definer 함수) 하나로 모았다.

### 테이블

```sql
create table public.chat_rooms (
  id           uuid        primary key default gen_random_uuid(),
  type         text        not null default 'open',
  title        text,
  description  text,
  created_by   uuid        default auth.uid()
                           references public.profiles (id) on delete set null,
  member_limit int         not null default 100,
  direct_key   text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  deleted_at   timestamptz,

  constraint chat_rooms_type_valid  check (type in ('open', 'direct')),
  constraint chat_rooms_direct_key_unique unique (direct_key),
  constraint chat_rooms_title_len   check (
       (type = 'open'   and title is not null
                        and char_length(btrim(title)) between 1 and 30)
    or (type = 'direct' and title is null)
  ),
  constraint chat_rooms_desc_len    check (description is null or char_length(description) <= 200),
  constraint chat_rooms_limit_range check (
       (type = 'open'   and member_limit between 2 and 500)
    or (type = 'direct' and member_limit = 2)
  ),
  constraint chat_rooms_direct_key_shape check (
       (type = 'open'   and direct_key is null)
    or (type = 'direct' and direct_key is not null)
  )
);

create table public.chat_participants (
  room_id      uuid        not null references public.chat_rooms (id) on delete cascade,
  user_id      uuid        not null default auth.uid()
                           references public.profiles (id) on delete cascade,
  nickname     text        not null,
  joined_at    timestamptz not null default now(),
  last_read_at timestamptz not null default now(),
  left_at      timestamptz,

  primary key (room_id, user_id),
  constraint chat_participants_nickname_len check (char_length(btrim(nickname)) between 2 and 20)
);

create table public.chat_messages (
  id           uuid        primary key default gen_random_uuid(),
  room_id      uuid        not null references public.chat_rooms (id) on delete cascade,
  sender_id    uuid        default auth.uid()
                           references public.profiles (id) on delete cascade,
  type         text        not null default 'text',
  content      text,
  image_path   text,
  system_event text,
  created_at   timestamptz not null default now(),
  deleted_at   timestamptz,

  constraint chat_messages_type_valid check (type in ('text', 'image', 'system')),
  constraint chat_messages_shape check (
       (type = 'text'   and sender_id is not null and content is not null
                        and char_length(btrim(content)) between 1 and 1000
                        and image_path is null and system_event is null)
    or (type = 'image'  and sender_id is not null and image_path is not null
                        and content is null and system_event is null)
    or (type = 'system' and sender_id is null and system_event in ('join', 'leave')
                        and content is not null and image_path is null)
  )
);
```

`type` 은 `'open'`(그룹) · `'direct'`(1:1 DM) 둘이다. F9-DM(설계 근거
[계획](features/chat/plan-dm.md))부터 `'direct'` 가 실제로 쓰인다. **DM 방이 생기는
경로는 `open_direct_room()` 하나뿐이다** — `chat_rooms` 의 INSERT 정책은 여전히
`type = 'open'` 만 허용하므로 앱이 직접 `insert` 로 direct 방을 만들 수 없다.

`title` · `member_limit` · `direct_key` 세 제약을 전부 `type` 별로 갈랐다. open 은
제목 필수·1~30자·정원 2~500·`direct_key` null, direct 는 제목 null·정원 정확히
2·`direct_key` not null. **`direct_key` 는 컬럼 unique 제약이다** — 부분 인덱스가
아닌 이유는 `open_direct_room()` 의 `on conflict (direct_key)` 가 성립하려면 유니크
"제약"이 있어야 하기 때문이다. open 방은 `direct_key` 가 null 이고 null 끼리는
충돌하지 않으므로 open 방끼리는 이 제약의 영향을 받지 않는다.

**`chat_messages.image_path` 는 URL 이 아니라 객체 경로다.** `chat-images` 가 비공개
버킷이라 공개 URL 이 존재하지 않는다 — 앱은 경로를 저장하고 화면에 띄울 때 서명
URL 을 만든다. `post_images.url`(진짜 공개 URL)과 이름을 구분한 이유가 이것이다.

`chat_messages.sender_id` 의 `default auth.uid()` 는 필수다. INSERT GRANT 에서 빠져
있어 앱이 값을 넣을 수 없으므로, 기본값이 없으면 `null` 로 들어가 삽입 정책
(`sender_id = auth.uid()`)이 **언제나** 실패한다. 시스템 메시지를 만드는 트리거는
`null` 을 명시해 이 기본값을 덮는다.

`created_by` 는 `on delete set null` 이다 — 개설자가 탈퇴해도 방은 남는다. cascade 로
두면 남은 사람들의 대화가 통째로 사라진다.

**나가기는 행 삭제가 아니라 `left_at`** 이다. 참여자 행을 지우면 그 사람이 남긴
메시지가 이름을 잃는다. 재입장은 `left_at` 을 `null` 로 되돌리는 upsert 다.

### 인덱스

```sql
create index chat_messages_room_created_idx
  on public.chat_messages (room_id, created_at desc, id desc)
  where deleted_at is null;

create index chat_participants_user_idx
  on public.chat_participants (user_id) where left_at is null;

create index chat_rooms_open_activity_idx
  on public.chat_rooms (created_at desc, id desc)
  where deleted_at is null and type = 'open';
```

### `is_room_member(room_id uuid) → boolean`

정책 안에서 `chat_participants` 를 직접 서브쿼리하면 그 테이블 자신의 정책이 다시
평가되어 무한 재귀(`42P17`)가 난다(§11). `is_blocked_with()` 와 같은 모양으로
security definer 함수에 가둔다.

**`EXECUTE` 를 회수하지 않는다.** `chat_rooms` 의 조회 정책이 `anon` 에게도 평가되고
그 안에서 이 함수를 부르므로, `anon` 의 실행 권한을 뺏으면 조회 자체가 실패한다
(§3 의 경고와 같은 함정).

### RLS

| 대상 | select | insert | update |
|---|---|---|---|
| `chat_rooms` | `deleted_at is null and (type = 'open' or (type = 'direct' and is_room_member(id)))` (anon 포함) | `type = 'open'` · 로그인 | 없음 |
| `chat_participants` | `is_room_member(room_id)` **or** `user_id = auth.uid()` | 본인 행 · 살아 있는 공개방 | `user_id = auth.uid()` |
| `chat_messages` | `deleted_at is null and is_room_member(room_id) and not is_blocked_with(sender_id)` | `sender_id = auth.uid()` · `type in ('text','image')` · `is_room_member` | 없음 (함수로만) |

`chat_rooms` 의 select 정책은 `chat_rooms_select_open` 에서 `chat_rooms_select_visible`
로 이름과 조건이 바뀌었다(F9-DM). direct 분기는 `is_room_member(id)` 로 판정하므로
멤버가 아니면 존재 자체가 보이지 않는다 — `open_chat_rooms` 뷰는 이미
`type = 'open'` 으로 좁혀져 있어 손대지 않았고, DM 은 탐색에 노출되지 않는다. `anon`
은 direct 분기가 항상 false 라 기존과 동일하게 동작한다.

참여자 select 에 `user_id = auth.uid()` 를 or 로 붙인 이유: 나간 뒤에는
`is_room_member` 가 false 라 **자기 행조차 못 읽는다.** 그러면 앱이 "처음 들어가는
방"과 "다시 들어가는 방"을 구분할 수 없어 upsert 가 성립하지 않는다. update 정책이
`is_room_member` 를 보지 않는 것도 같은 이유다 — 나간 사람이 다시 들어오려면 자기
행을 고칠 수 있어야 한다.

**차단은 select 정책의 `not is_blocked_with(sender_id)` 한 줄로 끝난다.** Postgres
Changes 가 구독자마다 이 정책을 다시 평가하므로 히스토리에서도 실시간에서도 오지
않는다. 시스템 메시지는 `sender_id` 가 null 이고 `is_blocked_with(null)` 이 false 라
그대로 통과한다.

### GRANT

```sql
grant insert (type, title, description, member_limit) on public.chat_rooms to authenticated;
grant insert (room_id, nickname) on public.chat_participants to authenticated;
grant update (nickname, last_read_at, left_at) on public.chat_participants to authenticated;
grant insert (id, room_id, type, content, image_path) on public.chat_messages to authenticated;
```

`created_by` · `user_id` · `sender_id` 에 INSERT 를 주지 않는 것이 위조를 막는
방법이다 — 전부 `default auth.uid()` 가 채운다. `reports` · `blocks` 와 같은 규칙이다.

**`chat_messages.id` 에 INSERT 를 주는 것은 의도다.** 앱이 메시지 uuid 를 먼저 만들어
낙관적 버블을 띄우고, 실시간으로 되돌아온 자기 메시지를 그 id 로 중복 제거한다.
PK 가 위조를 막는다 — 남의 id 를 쓰면 충돌한다.

`DELETE` 는 어디에도 주지 않는다. 메시지 소프트 삭제는
`soft_delete_chat_message(message_id uuid) → boolean` 으로만 한다 — 조회 정책이 삭제행을
가려 `UPDATE ... RETURNING` 이 `42501` 로 막히는 함정(§11)을 게시물·댓글과 같은
방식으로 피한다.

### `open_direct_room(partner_id uuid) → uuid` (F9-DM)

**DM 방이 생기는 경로는 이 함수 하나뿐이다.** security definer 인 이유:
방 + 참여자 2행이 원자적이어야 하고, 상대 참여자 행은 클라이언트 INSERT 정책
(`user_id = auth.uid()`)으로 넣을 수 없다. `chat_rooms` 의 INSERT 정책은 이 함수
도입 후에도 계속 `type = 'open'` 만 허용한다.

1. 비로그인이면 `42501`. `partner_id = caller` 면 `23514`
   (`자기 자신과는 대화할 수 없습니다`)
2. 상대 프로필이 없거나 `is_blocked_with(partner_id)` 면 **같은 문구**
   `대화를 시작할 수 없습니다`(`42501`) — 상대가 없는 것과 차단을 구분해 노출하지
   않는다
3. `direct_key := least(caller, partner_id) || ':' || greatest(caller, partner_id)`.
   `insert into chat_rooms (...) values ('direct', null, 2, key) on conflict
   (direct_key) do nothing returning id` — 행이 안 생기면(동시 호출에서 진 쪽)
   `direct_key` 로 이미 만들어진 방을 다시 select 한다. **동시성은 유니크 제약이
   판정**하고 함수는 진 쪽을 구제할 뿐이다
4. 참여자 upsert. **내 행**은 `on conflict (room_id, user_id) do update set
   left_at = null` — 없으면 만들고 나갔던 방이면 되돌린다. **상대 행**은
   `do nothing` — 없을 때만 만들고 상대의 나가기 상태는 건드리지 않는다. 자동
   재등장은 상대가 실제로 메시지를 보냈을 때(`enforce_direct_message()`) 일어난다
5. 같은 두 사람이 몇 번을 불러도, 어느 쪽이 부르든 같은 방 id 를 돌려준다(멱등)

`revoke execute ... from public, anon` + `grant execute ... to authenticated` —
`soft_delete_chat_message()` 와 같은 짝.

### `enforce_direct_message()` (트리거, `chat_messages` before insert, F9-DM)

direct 방의 메시지 전송에서만 동작한다(open 방과 시스템 메시지는 이른 반환).
수신 숨김은 기존 select 정책(`not is_blocked_with(sender_id)`)이 이미 하므로, 이
트리거는 **전송 자체를 거부**한다 — 1:1 에서 전송만 허용하면 허공에 말하는
상황이 되기 때문이다. 상대와 차단 관계면 `42501`, 문구는 `enforce_comment_depth()`
전례대로 방향 중립인 `메시지를 보낼 수 없습니다`.

차단이 아니면 **카톡식 자동 재등장**을 한다 — 상대의 `left_at` 이 채워져 있으면
`null` 로 되돌린다. 이 UPDATE 는 `enforce_room_capacity()` · `emit_membership_
system_message()` 두 트리거를 다시 지나지만, 정원 검사는 2인 방에서 항상
통과하고 시스템 메시지는 아래 direct 억제 분기에 걸려 나오지 않는다.

### 트리거 셋

- `enforce_room_capacity()` — 참여자 insert 와 **재입장 update** 에서 `member_limit` 검사
- `emit_membership_system_message()` — 입장 · 퇴장 · 재입장에 `type='system'` 메시지 삽입.
  문구가 아니라 `system_event` 키(`'join'` · `'leave'`)를 저장하고 `content` 에는 그
  시점의 닉네임을 스냅샷으로 남긴다. **문장은 앱의 ARB 가 만든다** — DB 에 한국어를
  넣으면 다국어 이행에 갚을 빚이 하나 더 생긴다. **direct 방이면 이른 반환한다
  (F9-DM)** — 1:1 에서 입퇴장 문구는 어색하고, "나갔습니다"는 나가기 사실을
  상대에게 노출한다
- `verify_chat_image_path()` — `image_path` 가 `{room_id}/{sender_id}/{객체}` 인지 검증.
  Storage 정책은 업로드만 막으므로 메시지 행이 가리키는 곳까지 같은 규칙으로 묶으려면
  여기서 봐야 한다 (`verify_post_image_urls` 와 같은 이유)
- `enforce_direct_message()` — direct 방 전용, 위 절 참고 (F9-DM)

### 뷰 둘

`my_chat_rooms` 는 `security_invoker = on` 이다. 내가 멤버인 방만 다루므로 호출자의
RLS 로 충분하고, 안읽음 수(`created_at > last_read_at and sender_id is distinct from
auth.uid()`)에서 차단한 상대의 메시지가 자동으로 빠진다.

**F9-DM 에서 끝에 `partner_id` · `partner_nickname` · `partner_avatar_url` 세 컬럼을
더했다** (direct 가 아니면 전부 null). 상대는 `chat_participants` 를 `room_id` 로
자기 자신이 아닌 행을 찾는 lateral join 으로 구하고(`r.type = 'direct'` 일 때만
평가), 그 `user_id` 로 `profiles` 를 조인해 닉네임·아바타를 붙인다. 상대 참여자
행은 내가 멤버인 방이므로 `is_room_member` 정책으로 읽히고, **상대가 나간 뒤에도
표시가 유지된다** — 지우는 것은 참여자 행이 아니라 `left_at` 뿐이기 때문이다.
`create or replace view` 는 명시하지 않은 reloption 을 리셋하므로, 이 변경에서도
`with (security_invoker = on)` 을 다시 명시해야 한다(§9 의 함정).

**`open_chat_rooms` 는 `security_invoker = off` 다 — 이 스키마의 두 번째 예외다.**
탐색 화면은 아직 참여하지 않은 사람이 보는데, 참여자 수를 세려면
`chat_participants` 를 읽어야 하고 그 정책은 `is_room_member` 다. 호출자 권한으로는
모든 방이 0명으로 보인다. 정책이 평가되지 않으므로 뷰의 `where` 로 직접 좁힌다
(`deleted_at is null and type = 'open'`) — 이 줄이 빠지면 삭제된 방과 나중에 붙을
DM 방까지 탐색에 노출된다. 내보내는 것은 집계 수 하나뿐이고 참여자 신원은 나가지
않는다. 첫 예외는 `post_comments_visible`(§9)이고 그 절의 주의사항이 그대로 적용된다.

### 실시간 발행

```sql
alter publication supabase_realtime add table public.chat_messages;
```

이 한 줄이 빠지면 구독이 **조용히 아무것도 받지 않는다.** 오류도 나지 않는다.

### Storage `chat-images`

**비공개** 버킷(5 MiB, `image/webp` · `image/jpeg`). 경로는
`{room_id}/{user_id}/{message_id}.{webp|jpg}` 다 — 읽기 권한이 방 단위라 첫 조각이
room_id 여야 정책이 `is_room_member` 로 판정할 수 있다. `post-images` 의
`{user_id}/...` 와 순서가 다른 이유가 이것이다.

- select: `is_room_member((storage.foldername(name))[1]::uuid)`
- insert: 위 조건 **그리고** `(storage.foldername(name))[2] = auth.uid()::text`
- update · delete: 정책 없음

### 신고 대상 확장

`reports_target_type_valid` 에 `'chat_message'` 를 더하고 `enforce_report_target()` 에
분기 하나를 넣었다(§12). 테이블은 새로 만들지 않는다. 시스템 메시지(`sender_id` null)는
신고 대상이 아니다.

### 검증한 것 (로컬 Supabase · 실제 JWT + REST)

`supabase/tests/chat_rls_check.py` 52건, `supabase/tests/chat_realtime_check.py` 4건이
모두 통과한다(2026-08-28). 항목은 [테스트 문서](testing/features/chat.md)에 있다.

## 15. `follows` · 팔로우 뷰 넷

F8 팔로우. 설계 근거는 [계획](features/follow/plan.md)에 있다. 단방향 엣지 하나로
팔로우 · 맞팔 · 목록 · 팔로잉 피드를 모두 만든다
(`20260830090000_add_follows.sql`).

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

create index follows_followee_idx
  on public.follows (followee_id, created_at desc, follower_id desc);
create index follows_follower_idx
  on public.follows (follower_id, created_at desc, followee_id desc);
```

복합 PK가 중복 팔로우를 막는다. 맞팔은 반대 방향 행이 하나 더 있는 것일 뿐이라
상태를 따로 저장하지 않는다. 해제는 행 삭제다 — 팔로우에는 자식이 달리지 않으므로
`blocks`(§13) · `post_reactions`(§10)와 같은 판단이다. 인덱스가 둘인 이유는 목록이
방향마다 `created_at desc` 커서를 타기 때문이다. PK 만으로는 팔로워 방향(누가 나를
팔로우하는가)이 전체 스캔이 된다.

### RLS · GRANT

```sql
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

**조회가 전체 공개인 것이 `blocks`(§13)와 갈리는 지점이다.** 남의 프로필에서도
팔로워 수와 목록이 보여야 하는데, 본인 행만 열면 수 · 목록 · 맞팔 판정이 전부
`security definer` 함수를 타야 한다. `follower_id` 에 INSERT 를 주지 않는 것이
위조를 막는 방법인 것은 신고 · 차단과 같다. UPDATE 정책 · 권한은 없다.

INSERT 의 `with check` 가 차단 검사를 함께 한다. `is_blocked_with()`(§3)는
**양방향**이라 어느 쪽이 차단했든 같은 결과가 나온다 — 그래서 앱의 거부 문구는
방향을 밝히지 않는다(`FailureCode.followBlocked`).

### `blocks` 에 붙은 트리거 — 차단이 팔로우 엣지를 지운다

```sql
create trigger blocks_drop_follows
  after insert on public.blocks
  for each row execute function public.drop_follows_on_block();
```

`drop_follows_on_block()` 은 `security definer` 다. 차단당한 쪽이 건 팔로우 행은
`follows_delete_own` 으로는 지울 수 없기 때문이다.

**이 트리거로 §13의 전제가 하나 깨진다** — "차단에는 자식이 달리지 않는다"가
더 이상 참이 아니고, `blocks` 가 `follows` 에 부수 효과를 갖는 부모가 됐다. 그럼에도
지우는 쪽을 고른 이유는 지우지 않으면 차단한 상대가 팔로워 **수**에는 남고
목록에서만 사라져 둘이 어긋나기 때문이다. 차단을 해제해도 팔로우는 되살아나지
않는다.

### 뷰 넷

| 뷰 | 읽는 곳 | 내용 |
|---|---|---|
| `profile_details` | 프로필 화면 | `profiles` + `follower_count` · `following_count` · `is_following` · `is_followed_by` |
| `user_followers` | 팔로워 목록 | `user_id`(팔로우당하는 쪽) 기준. 상대 프로필과 `created_at` |
| `user_followings` | 팔로잉 목록 | `user_id`(팔로우하는 쪽) 기준 |
| `following_posts_with_author` | 팔로잉 피드 | `posts_with_author`(§6)를 내 `follows` 로 좁힌 것 |

넷 다 `security_invoker = on` 이다. `profiles` 에는 조회 정책이 없고(§1, 차단 목록이
차단한 사용자의 닉네임을 보여줘야 해서 의도적으로 두지 않았다) `follows` 는 전체
공개라 그것으로 충분하다.

**목록 뷰 둘에만 차단 필터를 손으로 적는다** (`where not is_blocked_with(...)`).
`posts`(§5)처럼 아래 테이블의 정책에 얹는 방식이 여기서는 통하지 않는다 —
`profiles` 에 정책이 없기 때문이다. `post_comments_visible`(§9)이 지고 있는 것과 같은
부채다. 트리거가 있어도 필터를 함께 두는 이유는, 트리거가 차단 시점의 엣지만 지우고
**제3자의 목록**에서 만나는 경우는 덮지 못하기 때문이다.

수 둘은 필터를 타지 않는다. 내가 차단한 사람이 남의 팔로워 수에서 빠지면 조회자마다
수가 달라진다.

`following_posts_with_author` 는 감싸는 뷰라 삭제 · 차단 필터를 다시 쓰지 않는다 —
`posts_with_author` 가 `security_invoker = on` 이라 `posts_select_visible` 을 그대로
물려받는다. 비로그인은 `auth.uid()` 가 null 이라 0행이 나온다.

### 검수에서 굳힌 것 (`20260830150000_harden_follows.sql`)

- **팔로우 × 차단 동시성.** 정책의 `is_blocked_with()` 검사와 `blocks` 트리거는
  둘 다 "상대가 이미 커밋했다"를 전제한다. 두 트랜잭션이 겹치면 전제가 깨져
  엣지가 살아남고, `blocks` PK 때문에 재차단으로도 복구되지 않았다.
  `follow_pair_lock()` advisory 락을 양쪽 경로가 잡고, `follows` 에
  `follows_guard_block` BEFORE INSERT 가드를 더해 닫았다
- **`following_posts_with_author` 의 `select p.*`.** Postgres 가 뷰 생성 시점의
  컬럼으로 동결하므로 `posts_with_author` 에 컬럼이 늘어도 따라가지 않는다.
  앱은 두 뷰에 같은 컬럼 문자열을 쓰기 때문에, 그 시점에 팔로잉 피드만 400 이
  된다. 컬럼을 명시해 **두 뷰를 함께 고쳐야 한다는 사실이 드러나게** 했다 —
  `posts_with_author` 컬럼을 바꾸면 이 뷰도 `create or replace` 한다

### 알려진 한계 (고치지 않았다)

- **팔로잉 피드가 페이지마다 팔로이 전체 글을 펼친 뒤 정렬한다.** 감싸는 뷰라
  `posts_created_at_idx` 의 정렬을 못 쓴다. 팔로이 506명 · 후보 1,010건에서
  0.6ms → 11.5ms (19배). 고치려면 "먼저 자르고 나중에 붙이는" RPC 로 조회
  경로를 바꿔야 해서 앱 커서 계약까지 번진다
- **목록 뷰의 차단 필터는 화면 필터이지 보안 통제가 아니다** — `follows` 직접
  조회 + `profiles` 임베드로 우회된다 ([계획](features/follow/plan.md))
- **커서의 `or(...)` 형태가 인덱스 조건이 아니라 필터로 떨어진다.** 팔로워
  5,001명 · 3,000번째 커서에서 3,001행을 버린다(행 비교 문법이면 0행).
  PostgREST 에 행 비교가 없어 앱 코드로는 못 고치고, 같은 형태가 피드에도 있다
- **`profile_details` 는 단일 프로필 전용이다.** 행마다 서브쿼리 넷을 돌리므로
  목록 조회에 쓰지 않는다

### 검증한 것 (로컬 Supabase · 실제 JWT + REST)

`supabase/tests/follow_rls_check.py` 28건과
`supabase/tests/follow_block_race_check.py` 4건이 모두 통과한다(2026-08-30).
뒤쪽은 psql 세션 둘로 트랜잭션을 겹쳐 위 동시성 결함을 재현·확인한다. 항목은
[테스트 문서](testing/features/follow.md)에 있다.
