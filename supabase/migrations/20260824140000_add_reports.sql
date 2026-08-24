-- F7 신고. 폴리모픽 대상(게시물·댓글·사용자) 한 테이블.
-- 설계 근거는 docs/features/safety/plan.md 에 있다.

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
    target_type in ('post', 'comment', 'user')
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

-- 둘 다 운영(Studio) 조회용이다. 앱에는 신고 목록 화면이 없다.
create index reports_target_idx on public.reports (target_type, target_id);
create index reports_status_created_at_idx
  on public.reports (status, created_at desc);

-- 폴리모픽이라 FK 가 없다. FK 가 해주던 일(존재하는 대상인가)과 정책이 못 하는
-- 일(내 것이 아닌가)을 트리거가 함께 본다.
--
-- security definer 가 필요하다: post_comments 는 content 컬럼에 SELECT 를 주지
-- 않으므로(docs/features/comment/plan.md) invoker 로 두면 대상 행을 읽지 못한다.
-- search_path = '' 는 definer 함수의 필수 안전장치라 모든 객체를 스키마까지 적는다.
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

alter table public.reports enable row level security;

-- 조회: 본인 신고만. 남이 무엇을 신고했는지는 누구도 볼 수 없다.
create policy "reports_select_own"
  on public.reports for select to authenticated
  using ((select auth.uid()) = reporter_id);

-- 삽입: 본인 것만.
create policy "reports_insert_own"
  on public.reports for insert to authenticated
  with check ((select auth.uid()) = reporter_id);

-- UPDATE · DELETE 정책은 두지 않는다. 신고는 취소되지 않고,
-- status 변경은 service_role 의 일이다.

-- reporter_id 와 status 에 INSERT 를 주지 않는 것이 위조를 막는 방법이다.
-- reporter_id 는 default auth.uid() 가 채우고 status 는 항상 pending 으로 시작한다.
grant select on public.reports to authenticated;
grant insert (target_type, target_id, reason, detail)
  on public.reports to authenticated;
