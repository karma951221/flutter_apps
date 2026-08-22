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
profiles ──1:N──▶ posts
```

앞으로 추가될 테이블(`post_images` · `post_reactions` · `post_comments` · `follows` ·
`blocks` · `reports`)의 계획은 [기획서 §7](overview.md)에 있다. 여기에는 **실제로
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

### `soft_delete_post(post_id uuid) → boolean`

게시물을 삭제하는 **유일한 경로**다. 삭제된 행이 있으면 `true`, 없거나 남의 글이면
`false`를 돌려준다.

```sql
create function public.soft_delete_post(post_id uuid)
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

---

## 6. 알아둘 함정

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
