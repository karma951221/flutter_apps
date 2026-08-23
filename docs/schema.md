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
profiles ──1:N──▶ posts ──1:N──▶ post_images
                    │
                    └──1:N──▶ post_images
```

읽기 전용 뷰 `posts_with_author`(§6)가 이 둘을 조인해 피드에 내려준다.

앞으로 추가될 테이블(`post_reactions` · `post_comments` · `follows` · `blocks` ·
`reports`)의 계획은 [기획서 §7](overview.md)에 있다. 여기에는 **실제로
존재하는 것만** 적는다.

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
`{user_id}/{timestamp}.webp`이며, `storage.objects`의 INSERT·UPDATE·DELETE 정책은 첫
경로 조각이 `(select auth.uid())::text`와 일치할 때만 허용한다. 따라서 앱이 경로를
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

-- 조회: 삭제되지 않은 게시물은 공개다.
-- 앱이 필터를 빠뜨릴 수 없도록 삭제행 숨김을 여기서 강제한다.
create policy "posts_select_visible"
  on public.posts
  for select
  to authenticated, anon
  using (deleted_at is null);

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
create function public.create_post_with_images(content text, images jsonb)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  author       uuid := (select auth.uid());
  new_post_id  uuid;
begin
  if author is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

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
  pr.avatar_url as author_avatar_url
from public.posts p
join public.profiles pr on pr.id = p.author_id;
```

### `security_invoker = on` 은 선택 사항이 아니다

**뷰는 기본적으로 소유자(`postgres`) 권한으로 실행된다.** 이 옵션을 빼면
`posts_select_visible`(`deleted_at is null`)이 평가되지 않아 **삭제된 게시물이 이 뷰로
그대로 새어 나온다.** §2의 "삭제행 숨김을 조회 정책이 강제한다"가 뷰 하나로 무너진다.

`on` 이면 뷰를 **조회한 세션 사용자**의 권한으로 기반 테이블의 RLS 가 그대로 평가된다.
뷰는 정책을 우회하는 통로가 아니라 조인에 붙인 이름일 뿐이다.

**앞으로 이 스키마에 추가되는 모든 뷰에 같은 규칙을 적용한다.**

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

반응 수(F5) · 댓글 수(F6) · 내 반응 상태 · 차단 필터(F7)는 앱 쿼리가 아니라 **이 뷰
안에** 넣는다. 화면마다 같은 필터를 다시 쓰면 언젠가 빠뜨린다.

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

## 8. 알아둘 함정

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
전용 함수가 필요하다.

### `alter table ... rename`은 딸린 객체 이름을 바꾸지 않는다

인덱스 · 제약 · 트리거 · 정책 이름은 옛 테이블 이름으로 남는다. rename 마이그레이션에서
`alter table ... rename constraint` · `alter trigger ... rename to` ·
`alter policy ... rename to`로 직접 맞춘다.
([20260822120000](../supabase/migrations/20260822120000_rename_posts_and_soft_delete.sql) 참고)
