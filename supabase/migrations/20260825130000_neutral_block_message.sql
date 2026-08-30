-- F7 차단 — 댓글 삽입 거부 문구를 방향 중립으로 바꾼다.
-- 설계 근거는 docs/features/safety/plan-block.md · docs/features/safety/history.md 에 있다.
--
-- 20260825120000_add_blocks.sql:179 의 enforce_comment_depth() 는
-- '차단한 사용자의 게시물에는 댓글을 달 수 없습니다' 를 던졌다. 이 문구는
-- 차단"한" 쪽(A) 시점으로 쓰여 있는데, 실제로 이 예외를 보는 것은 차단"당한"
-- 쪽(B)이다 — B가 A의 게시물 화면을 이미 열어 둔 상태에서 A가 차단하고, B가
-- 댓글을 등록하려 하면 이 트리거에 걸린다. B는 아무도 차단하지 않았으므로
-- "당신이 차단한 사용자"라는 말 자체가 틀렸고, 동시에 "차단이 있다"는 사실과
-- "누가 걸었는지" 방향까지 차단당한 당사자에게 드러낸다.
--
-- 계획서의 중심 결정("차단 사실 노출: 알리지 않는다 — '당신은 차단당했습니다'는
-- 보복의 방아쇠다")이 지키려던 것이 정확히 이것이다. 감정표현 경로는
-- post_reactions_insert_own · comment_reactions_insert_own 의 with check 가
-- 차단 필터가 걸린 posts · post_comments 를 그대로 읽다가 행이 그냥 안 보여
-- 일반 42501 로 떨어지므로(스키마 §10) 원래도 새지 않았다 — 댓글 경로만
-- 트리거가 직접 만든 문구로 새고 있었다.
--
-- 고침: 문구를 방향 중립으로 바꾼다 — '이 게시물에는 댓글을 달 수 없습니다'.
-- 두 당사자 모두에게 참이고, 누가 차단했는지도 밝히지 않는다.
--
-- 적용된 마이그레이션은 고치지 않는다는 규칙이라, 아래는 그 파일의
-- enforce_comment_depth() 정의를 그대로 가져와 이 문자열 하나만 바꾼 재정의다.
-- 나머지 검사 네 가지(게시물 작성자 차단 여부는 그대로, 부모 존재·답글의
-- 답글·같은 게시물·삭제된 부모)는 손대지 않았다.
create or replace function public.enforce_comment_depth()
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

-- -----------------------------------------------------------------------------
-- is_blocked_with() 에 anon 이 execute 권한을 유지해야 한다는 경고를 남긴다
-- (FIX 4c). 오늘은 PUBLIC 기본 권한으로 anon 도 이미 실행할 수 있지만, 이
-- 스키마의 모든 RPC 함수는 revoke ... from public, anon; grant ... to
-- authenticated 짝을 명시적으로 쓴다(예: delete_account, 스키마 §3). 그
-- 패턴을 그대로 따라 "강화"하면 비로그인 피드가 42501 로 죽는다 —
-- posts_select_visible · post_comments_select_visible 정책이 모든 조회에서
-- 이 함수를 부르기 때문이다. 그래서 여기서는 explicit revoke 를 하지 않고,
-- anon 권한을 명시적으로 grant 만 해 둔다(PUBLIC 권한이 이미 주므로 동작은
-- 바뀌지 않는다) — 다음에 이 함수를 만지는 사람이 "명시적이지 않다"는
-- 이유로 anon 을 걷어내지 않도록.
-- -----------------------------------------------------------------------------
grant execute on function public.is_blocked_with(uuid) to anon, authenticated;

comment on function public.is_blocked_with(uuid) is
  'blocks 의 양방향 판정. anon 은 반드시 execute 권한을 유지해야 한다 — '
  'posts_select_visible · post_comments_select_visible 정책(비로그인 조회 포함 '
  '모든 게시물 조회)과 post_comments_visible 뷰가 이 함수를 부른다. anon 의 '
  'execute 를 걷어내면 비로그인 피드가 42501 로 죽는다. 비로그인(auth.uid() '
  'null)이면 exists 의 두 갈래가 모두 false 라 필터는 항상 통과된다 — 이 '
  '함수 자체가 비로그인 조회를 막지 않는다. '
  'stable 은 같은 문장(statement) 안에서 결과가 바뀌지 않는다는 보장일 뿐, '
  '같은 인자에 대해 한 번만 평가되는 메모이제이션을 약속하지 않는다 — 이 '
  '함수는 security definer 이고 search_path 를 비워 SQL 인라이너 대상에서 '
  '제외되므로, posts_select_visible · post_comments_select_visible 정책과 '
  'post_comments_visible 뷰 모두에서 실제로 행마다 다시 호출된다(2026-08-25 '
  'Task 5 검증). "같은 인자면 한 번만 평가된다"는 설명은 틀렸다 — '
  '20260825120000_add_blocks.sql 의 주석이 이 틀린 설명을 담고 있으나 그 '
  '파일은 적용된 마이그레이션이라 고치지 않는다(docs/features/safety/plan-block.md, '
  'docs/schema.md §3 이 올바른 설명의 단일 기준이다).';
