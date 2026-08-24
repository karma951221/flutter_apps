-- 회원 탈퇴. 계정과 계정에 딸린 모든 행을 한 트랜잭션에 지운다.
--
-- 삭제 경로는 이 함수 하나다. 클라이언트에 auth.users 나 profiles 의 DELETE
-- 권한을 주지 않는다 — security definer 함수 안의 auth.uid() 가 권한 경계다.
--
-- 지워지는 범위 (FK on delete cascade 사슬):
--   auth.users → profiles → posts → post_images · post_comments · post_reactions
--                          → post_comments(내가 단 댓글) → comment_reactions
-- 남의 게시물에 단 내 댓글·반응도 author_id/user_id 가 profiles 를 cascade 로
-- 참조하므로 함께 지워진다.
--
-- ★ Storage 는 여기서 지우지 않는다. storage.objects 를 SQL 로 직접 지우는 것은
-- Storage 확장의 보호 트리거가 42501 로 막는다("Use the Storage API instead").
-- 그래서 soft_delete_post 와 같은 분담을 쓴다 — 객체 정리는 **앱이 탈퇴 전에
-- Storage API 로 best-effort** 수행하고(자기 경로 삭제 정책은 이미 있다),
-- 정리가 실패해도 탈퇴는 성공으로 본다. 남는 객체는 운영 배치의 몫이다.
create function public.delete_account()
returns void
language plpgsql
security definer
set search_path = ''
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

comment on function public.delete_account() is
  '세션 사용자의 계정을 지운다. 프로필·게시물·댓글·반응은 cascade 로 함께 지워진다.';

revoke execute on function public.delete_account() from public, anon;
grant execute on function public.delete_account() to authenticated;
