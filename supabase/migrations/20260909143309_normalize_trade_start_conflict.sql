-- 진행 중 판 확인과 INSERT 사이에 다른 요청이 끼어들면 부분 유니크 인덱스가
-- 마지막 방어선이다. 그 23505 원문도 선행 검사와 같은 사용자 문구로 바꾼다.
create or replace function public.start_trade_session()
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid        uuid := (select auth.uid());
  v_symbol     text;
  v_start_day  date;
  v_count      int;
  v_session_id uuid;
begin
  if v_uid is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  if exists (
    select 1 from public.trade_sessions ts
     where ts.user_id = v_uid and ts.finished_at is null
  ) then
    raise exception '진행 중인 판이 있습니다';
  end if;

  select mc.symbol into v_symbol
    from public.market_candles mc
   group by mc.symbol
  having count(*) >= 120
   order by random()
   limit 1;

  if v_symbol is null then
    raise exception 'candle window incomplete';
  end if;

  select span.min_day + floor(random() * (span.max_day - span.min_day - 119 + 1))::int
    into v_start_day
    from (
      select min(mc.day) as min_day, max(mc.day) as max_day
        from public.market_candles mc
       where mc.symbol = v_symbol
    ) span;

  select count(*) into v_count
    from public.market_candles mc
   where mc.symbol = v_symbol
     and mc.day between v_start_day and v_start_day + 119;

  if v_count <> 120 then
    raise exception 'candle window incomplete';
  end if;

  begin
    insert into public.trade_sessions (user_id, symbol, start_day)
    values (v_uid, v_symbol, v_start_day)
    returning id into v_session_id;
  exception
    when unique_violation then
      raise exception '진행 중인 판이 있습니다';
  end;

  return v_session_id;
end;
$$;

comment on function public.start_trade_session() is
  '새 판을 시작하고 id 를 돌려준다. 동시 호출의 유니크 충돌도 진행 중인 판 오류로 돌려준다.';

revoke execute on function public.start_trade_session() from public, anon;
grant execute on function public.start_trade_session() to authenticated;
