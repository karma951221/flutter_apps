-- =============================================================================
-- 0단계: 프로필 테이블 + RLS
--
-- 계정 자체(이메일/비밀번호/세션)는 Supabase Auth가 auth.users에서 관리한다.
-- 여기서는 공개 프로필 정보만 다룬다.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- profiles
-- -----------------------------------------------------------------------------
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

comment on table public.profiles is '사용자 공개 프로필. auth.users와 1:1.';

-- 닉네임 대소문자 무시 유니크 (Nickname / nickname 동시 등록 방지)
create unique index profiles_nickname_lower_idx on public.profiles (lower(nickname));

-- -----------------------------------------------------------------------------
-- updated_at 자동 갱신
-- -----------------------------------------------------------------------------
create function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- -----------------------------------------------------------------------------
-- 회원가입 시 프로필 자동 생성
--
-- 앱이 signUp 시 metadata로 nickname을 넘긴다. 없으면 임시 닉네임을 부여한다.
-- security definer: auth.users 트리거에서 public.profiles에 쓰기 위해 필요.
-- search_path = '' 는 security definer 함수의 필수 안전장치이므로
-- 모든 객체를 스키마까지 명시한다.
-- -----------------------------------------------------------------------------
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

-- -----------------------------------------------------------------------------
-- RLS
--
-- auth.uid() 를 (select auth.uid()) 로 감싸는 것은 성능 최적화다.
-- 이렇게 하면 Postgres가 행마다 재평가하지 않고 한 번만 계산한다.
-- -----------------------------------------------------------------------------
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

-- INSERT 정책은 두지 않는다.
-- 프로필 생성은 handle_new_user() 트리거(security definer)만 담당한다.
-- DELETE 정책도 두지 않는다. 계정 삭제 시 on delete cascade로 함께 지워진다.

-- -----------------------------------------------------------------------------
-- 테이블 권한 (GRANT)
--
-- RLS 정책은 "어떤 행에 접근할 수 있는가"만 정한다.
-- "테이블에 접근할 수 있는가" 자체는 GRANT 가 따로 정한다. 둘 다 필요하다.
-- 이걸 빠뜨리면 정책이 맞아도 42501 permission denied 가 난다.
-- -----------------------------------------------------------------------------
grant select on public.profiles to anon, authenticated;

-- 수정 가능한 컬럼을 명시적으로 제한한다.
-- id / created_at / updated_at 은 클라이언트가 건드릴 수 없다.
grant update (nickname, bio, avatar_url) on public.profiles to authenticated;

-- insert / delete 권한은 주지 않는다.
--   insert : handle_new_user() 트리거(security definer)만 수행
--   delete : auth.users 삭제 시 on delete cascade 로 처리
