-- =============================================================================
-- 모의투자(F10) 5.2 — 판(trade_sessions) · 주문(trade_orders) · RPC 5개
--
-- 규칙은 하나다: **판이 끝나기 전에는 종목과 날짜가 어떤 경로로도 클라이언트에
-- 내려가지 않는다.** market_candles(§16)가 GRANT 자체를 주지 않아 원시 시세를
-- 숨긴 것과 같은 방식으로, 여기서는 `symbol` · `start_day` 두 컬럼에만 GRANT 를
-- 주지 않는다. 정책은 "어떤 행"을, GRANT 는 "어떤 컬럼"을 막는다(§2) — 정책만으로는
-- 내 판의 내 행에서 심볼을 읽는 것을 막을 수 없다.
--
-- 쓰기 경로도 GRANT 로만 닫는다. insert · update · delete 를 어떤 role 에도 주지
-- 않으므로 판의 상태를 바꾸는 길은 아래 security definer RPC 5개뿐이다.
--
-- 결과의 전체 모습은 docs/schema.md §17 을 본다.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. 테이블
-- -----------------------------------------------------------------------------
create table public.trade_sessions (
  id           uuid        primary key default gen_random_uuid(),
  user_id      uuid        not null default auth.uid()
                           references public.profiles (id) on delete cascade,
  -- 숨김 컬럼. 클라이언트 GRANT 없음. 끝나기 전엔 어떤 경로로도 내려가지 않는다.
  symbol       text        not null,
  start_day    date        not null,          -- index 0 의 day
  step         int         not null default 0 check (step between 0 and 60),
  cash         numeric     not null default 10000 check (cash >= 0),
  quantity     numeric     not null default 0 check (quantity >= 0),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  finished_at  timestamptz,
  -- 결과 스냅샷. finished_at 이 채워질 때 함께 채워지고 그 전엔 전부 null.
  revealed_symbol      text,
  revealed_start_day   date,                  -- 매매 시작 봉(index 59)의 day
  revealed_end_day     date,                  -- 종료 봉의 day
  final_equity         numeric,
  return_pct           numeric,
  buy_hold_return_pct  numeric,
  max_drawdown_pct     numeric,
  trade_count          int,
  constraint trade_sessions_result_all_or_none check (
    (finished_at is null) = (revealed_symbol is null)
  )
);

-- 사용자당 진행 중인 판은 하나다. 애플리케이션 조건문이 아니라 부분 유니크가 강제한다.
create unique index trade_sessions_active_one_per_user
  on public.trade_sessions (user_id) where finished_at is null;

-- 내 판 목록 커서 (created_at desc, id desc). §2 의 목록 인덱스 규칙과 같은 모양이다.
create index trade_sessions_user_idx
  on public.trade_sessions (user_id, created_at desc, id desc);

create trigger trade_sessions_set_updated_at
  before update on public.trade_sessions
  for each row execute function public.set_updated_at();

comment on table public.trade_sessions is
  '모의투자 한 판. symbol · start_day 는 GRANT 를 주지 않아 끝나기 전엔 어떤 role 도 읽을 수 없고, 끝나면 revealed_* 사본으로만 읽는다.';

create table public.trade_orders (
  id          uuid        primary key default gen_random_uuid(),
  session_id  uuid        not null references public.trade_sessions (id) on delete cascade,
  step        int         not null check (step between 0 and 59),
  side        text        not null check (side in ('buy', 'sell')),
  quantity    numeric     not null check (quantity > 0),
  price       numeric     not null check (price > 0),   -- 정규화 체결가
  fee         numeric     not null check (fee >= 0),
  created_at  timestamptz not null default now()
);

-- 재생(평가액 곡선)과 상태 JSON 이 모두 (step, created_at) 순으로 읽는다.
create index trade_orders_session_idx on public.trade_orders (session_id, step, created_at);

comment on table public.trade_orders is
  '판 안에서 체결된 주문. price 는 정규화 종가다. 종료 시 청산은 주문이 아니므로 여기 남지 않는다.';

-- -----------------------------------------------------------------------------
-- 2. RLS · GRANT
-- -----------------------------------------------------------------------------
alter table public.trade_sessions enable row level security;
alter table public.trade_orders enable row level security;

-- Supabase 기본 권한 처리로 붙을 수 있는 권한까지 모두 회수하고 필요한 것만 다시 준다.
revoke all privileges on public.trade_sessions from anon, authenticated;
revoke all privileges on public.trade_orders from anon, authenticated;

-- symbol · start_day 는 어떤 role 에도 주지 않는다. insert/update/delete 도 없다 — 쓰기는 RPC 뿐.
grant select (id, user_id, step, cash, quantity, created_at, updated_at, finished_at,
              revealed_symbol, revealed_start_day, revealed_end_day,
              final_equity, return_pct, buy_hold_return_pct, max_drawdown_pct, trade_count)
  on public.trade_sessions to anon, authenticated;
grant select on public.trade_orders to anon, authenticated;

create policy "trade_sessions_select_own" on public.trade_sessions for select
  to authenticated using ((select auth.uid()) = user_id);

-- 끝난 판은 공개다 — 게시물에 붙은 결과를 게스트도 열어야 한다.
create policy "trade_sessions_select_finished" on public.trade_sessions for select
  to anon, authenticated using (finished_at is not null);

-- 세션이 내 것이거나 끝난 세션이면 주문도 보인다. 다른 테이블 참조라 §11 의 42P17 은 아니다.
create policy "trade_orders_select_visible" on public.trade_orders for select
  to anon, authenticated using (
    exists (select 1 from public.trade_sessions s
             where s.id = trade_orders.session_id
               and (s.user_id = (select auth.uid()) or s.finished_at is not null))
  );

-- -----------------------------------------------------------------------------
-- 3. 내부 헬퍼 — 클라이언트 execute 없음
--
-- 셋 다 security definer 다. market_candles 를 읽고(§16 은 GRANT 가 없다)
-- trade_sessions 의 숨김 컬럼을 만지므로, 어떤 role 에도 execute 를 주지 않는다.
-- 아래 RPC 5개(역시 definer)만 부른다.
-- -----------------------------------------------------------------------------

-- 판의 봉을 정규화해서 돌려준다. index 59 의 원종가를 100 으로 맞추고 소수 2자리로
-- 반올림한다. 원가격 · 거래량은 어떤 형태로도 반환하지 않는다.
create function public.trade_normalized_candles(p_session_id uuid)
returns table (i int, day date, o numeric, h numeric, l numeric, c numeric)
language sql
stable
security definer
set search_path = ''
as $$
  with s as (
    select ts.symbol, ts.start_day
      from public.trade_sessions ts
     where ts.id = p_session_id
  ),
  w as (
    select
      (row_number() over (order by mc.day) - 1)::int as idx,
      mc.day  as cday,
      mc.open as copen, mc.high as chigh, mc.low as clow, mc.close as cclose
    from public.market_candles mc
    join s on mc.symbol = s.symbol
   where mc.day between s.start_day and s.start_day + 119
  ),
  base as (
    select w.cclose as value from w where w.idx = 59
  )
  select
    w.idx,
    w.cday,
    round(w.copen  / base.value * 100, 2),
    round(w.chigh  / base.value * 100, 2),
    round(w.clow   / base.value * 100, 2),
    round(w.cclose / base.value * 100, 2)
  from w cross join base
  order by w.idx;
$$;

comment on function public.trade_normalized_candles(uuid) is
  '판의 봉 120개를 index 59 의 종가 = 100 으로 정규화해서 돌려준다. 내부 전용 — execute 는 어떤 role 에도 주지 않는다.';

revoke execute on function public.trade_normalized_candles(uuid)
  from public, anon, authenticated;

-- 앱이 보는 판의 전체 상태. 진행 중이면 보이는 봉(i <= 59 + step)만, 끝났으면 120개
-- 전부와 결과를 함께 담는다. 숫자는 jsonb number 로 내린다(문자열 아님).
create function public.trade_session_state(p_session_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_session   public.trade_sessions;
  v_visible   int;
  v_end_index int;
  v_candles   jsonb;
  v_orders    jsonb;
  v_result    jsonb;
begin
  select * into v_session
    from public.trade_sessions ts
   where ts.id = p_session_id;

  if not found then
    return null;
  end if;

  -- 끝난 판은 120개 전부 공개한다. 진행 중이면 현재 봉까지만 — 미래 봉이 새면 게임이 끝난다.
  v_end_index := least(59 + v_session.step, 119);
  v_visible := case when v_session.finished_at is not null then 119 else v_end_index end;

  select coalesce(
           jsonb_agg(
             jsonb_build_object('i', nc.i, 'o', nc.o, 'h', nc.h, 'l', nc.l, 'c', nc.c)
             order by nc.i
           ),
           '[]'::jsonb
         )
    into v_candles
    from public.trade_normalized_candles(p_session_id) nc
   where nc.i <= v_visible;

  select coalesce(
           jsonb_agg(
             jsonb_build_object(
               'step', o.step, 'side', o.side, 'quantity', o.quantity,
               'price', o.price, 'fee', o.fee
             )
             order by o.step, o.created_at
           ),
           '[]'::jsonb
         )
    into v_orders
    from public.trade_orders o
   where o.session_id = p_session_id;

  if v_session.finished_at is not null then
    v_result := jsonb_build_object(
      'symbol',              v_session.revealed_symbol,
      'start_day',           to_char(v_session.revealed_start_day, 'YYYY-MM-DD'),
      'end_day',             to_char(v_session.revealed_end_day, 'YYYY-MM-DD'),
      'end_index',           v_end_index,
      'final_equity',        v_session.final_equity,
      'return_pct',          v_session.return_pct,
      'buy_hold_return_pct', v_session.buy_hold_return_pct,
      'max_drawdown_pct',    v_session.max_drawdown_pct,
      'trade_count',         v_session.trade_count
    );
  end if;

  -- user_id 는 GRANT 된 컬럼이다. 결과 화면이 "내 판인가"를 이것으로 판정한다.
  return jsonb_build_object(
    'id',       v_session.id,
    'user_id',  v_session.user_id,
    'step',     v_session.step,
    'cash',     v_session.cash,
    'quantity', v_session.quantity,
    'finished', v_session.finished_at is not null,
    'candles',  v_candles,
    'orders',   v_orders,
    'result',   v_result
  );
end;
$$;

comment on function public.trade_session_state(uuid) is
  '판의 상태를 jsonb 로 만든다. 진행 중이면 보이는 봉까지만, 끝났으면 봉 전부와 결과를 담는다. 내부 전용.';

revoke execute on function public.trade_session_state(uuid)
  from public, anon, authenticated;

-- 판을 종료 상태로 만든다. 호출자가 이미 `for update` 로 잠근 세션에만 쓴다.
--
-- step 은 건드리지 않는다 — advance 가 60 으로 올린 뒤 부르고, finish 는 현재 step
-- 그대로 끝낸다. 청산은 주문이 아니므로 trade_orders 에 넣지 않고 trade_count 에도
-- 세지 않는다.
create function public.trade_settle(p_session_id uuid, p_end_index int)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  fee_rate     constant numeric := 0.001;
  initial_cash constant numeric := 10000;

  v_session   public.trade_sessions;
  v_close     numeric[];   -- v_close[i + 1] = index i 의 정규화 종가
  v_day       date[];      -- v_day[i + 1]   = index i 의 day
  v_end_close numeric;
  v_cash      numeric;
  v_quantity  numeric;
  v_proceeds  numeric;
  v_fee       numeric;
  v_end_step  int;
  v_equity    numeric;
  v_peak      numeric := initial_cash;
  v_drawdown  numeric := 0;
  v_order     record;
begin
  select * into v_session
    from public.trade_sessions ts
   where ts.id = p_session_id;

  select array_agg(nc.c order by nc.i), array_agg(nc.day order by nc.i)
    into v_close, v_day
    from public.trade_normalized_candles(p_session_id) nc;

  v_end_close := v_close[p_end_index + 1];
  v_end_step  := p_end_index - 59;

  -- (1) 보유분 청산. 종료 봉의 정규화 종가로 판다.
  v_cash     := v_session.cash;
  v_quantity := v_session.quantity;
  if v_quantity > 0 then
    v_proceeds := v_quantity * v_end_close;
    v_fee      := v_proceeds * fee_rate;
    v_cash     := v_cash + v_proceeds - v_fee;
    v_quantity := 0;
  end if;

  -- (2) 주문을 재생해 평가액 곡선을 만든다. 최대 61회 루프다.
  --     각 step 의 평가액은 그 step 의 주문을 모두 반영한 뒤 cash + quantity × close,
  --     종료 step 은 청산 후 현금이다. 주문 행의 price · fee 를 그대로 쓴다.
  declare
    r_cash     numeric := initial_cash;
    r_quantity numeric := 0;
  begin
    for v_step in 0 .. v_end_step loop
      for v_order in
        select o.side, o.quantity, o.price, o.fee
          from public.trade_orders o
         where o.session_id = p_session_id and o.step = v_step
         order by o.created_at
      loop
        if v_order.side = 'buy' then
          r_cash     := r_cash - v_order.quantity * v_order.price - v_order.fee;
          r_quantity := r_quantity + v_order.quantity;
        else
          r_cash     := r_cash + v_order.quantity * v_order.price - v_order.fee;
          r_quantity := r_quantity - v_order.quantity;
        end if;
      end loop;

      if v_step = v_end_step then
        v_equity := v_cash;   -- 청산 후 현금
      else
        v_equity := r_cash + r_quantity * v_close[59 + v_step + 1];
      end if;

      v_peak := greatest(v_peak, v_equity);
      if v_peak > 0 then
        v_drawdown := greatest(v_drawdown, (v_peak - v_equity) / v_peak);
      end if;
    end loop;
  end;

  -- (3) · (4) 지표를 계산하고 결과 스냅샷을 채운다.
  update public.trade_sessions ts
     set cash                = v_cash,
         quantity            = 0,
         finished_at         = now(),
         revealed_symbol     = v_session.symbol,
         revealed_start_day  = v_day[60],
         revealed_end_day    = v_day[p_end_index + 1],
         final_equity        = round(v_cash, 2),
         return_pct          = round((v_cash / initial_cash - 1) * 100, 2),
         buy_hold_return_pct = round(
           ((1 - fee_rate) * (1 - fee_rate) * v_end_close / v_close[60] - 1) * 100, 2
         ),
         max_drawdown_pct    = round(v_drawdown * 100, 2),
         trade_count         = (
           select count(*) from public.trade_orders o where o.session_id = p_session_id
         )
   where ts.id = p_session_id;
end;
$$;

comment on function public.trade_settle(uuid, int) is
  '판을 종료한다. 보유분을 종료 봉 종가로 청산하고 지표 넷과 revealed_* 를 채운다. 내부 전용 — 호출자가 세션을 잠근 뒤에만 부른다.';

revoke execute on function public.trade_settle(uuid, int)
  from public, anon, authenticated;

-- -----------------------------------------------------------------------------
-- 4. RPC 5개
--
-- 파라미터 이름이 곧 PostgREST 의 JSON 키다. 본문에서는 지역 변수로 옮기거나
-- `함수명.파라미터` 로 수식해 컬럼 이름과의 충돌을 피한다.
-- -----------------------------------------------------------------------------

-- 새 판을 시작한다. 종목과 시작일은 서버가 뽑고 클라이언트에는 id 만 준다.
create function public.start_trade_session()
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

  -- 시세에 구멍이 있으면 120봉이 안 나온다. 반쪽짜리 판을 만들지 않는다.
  select count(*) into v_count
    from public.market_candles mc
   where mc.symbol = v_symbol
     and mc.day between v_start_day and v_start_day + 119;

  if v_count <> 120 then
    raise exception 'candle window incomplete';
  end if;

  insert into public.trade_sessions (user_id, symbol, start_day)
  values (v_uid, v_symbol, v_start_day)
  returning id into v_session_id;

  return v_session_id;
end;
$$;

comment on function public.start_trade_session() is
  '새 판을 시작하고 id 를 돌려준다. 종목·시작일은 서버가 무작위로 뽑고 끝나기 전엔 내려가지 않는다.';

revoke execute on function public.start_trade_session() from public, anon;
grant execute on function public.start_trade_session() to authenticated;

-- 판의 상태를 읽는다. 내 판이거나 끝난 판만 보인다.
--
-- 게스트도 부를 수 있다 — 게시물에 붙은 결과를 열어야 하기 때문이다. 남의 진행 중
-- 판과 없는 id 는 같은 문구로 거절한다(존재 여부를 밝히지 않는다).
create function public.get_trade_session(session_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_session_id uuid := get_trade_session.session_id;
  v_visible    boolean;
begin
  select (ts.user_id = (select auth.uid()) or ts.finished_at is not null)
    into v_visible
    from public.trade_sessions ts
   where ts.id = v_session_id;

  if v_visible is not true then
    raise exception '판을 찾을 수 없습니다';
  end if;

  return public.trade_session_state(v_session_id);
end;
$$;

comment on function public.get_trade_session(uuid) is
  '판의 상태를 돌려준다. 내 판이거나 끝난 판만 보이고, 나머지는 존재 여부를 밝히지 않는 같은 문구로 거절한다.';

revoke execute on function public.get_trade_session(uuid) from public;
grant execute on function public.get_trade_session(uuid) to anon, authenticated;

-- 현재 봉의 정규화 종가로 사고 판다.
create function public.place_trade_order(session_id uuid, side text, quantity numeric)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  fee_rate constant numeric := 0.001;

  v_session_id   uuid    := place_trade_order.session_id;
  v_side         text    := place_trade_order.side;
  v_quantity     numeric := round(place_trade_order.quantity, 6);
  v_session      public.trade_sessions;
  v_price        numeric;
  v_amount       numeric;
  v_fee          numeric;
  v_new_cash     numeric;
  v_new_quantity numeric;
begin
  -- 같은 판에 대한 동시 주문을 직렬화한다. 잔고 검사와 갱신 사이가 벌어지면 안 된다.
  select * into v_session
    from public.trade_sessions ts
   where ts.id = v_session_id
     and ts.user_id = (select auth.uid())
   for update;

  if not found then
    raise exception '판을 찾을 수 없습니다';
  end if;

  if v_session.finished_at is not null then
    raise exception '이미 끝난 판입니다';
  end if;

  if v_quantity is null or v_quantity <= 0 then
    raise exception '수량은 0보다 커야 합니다';
  end if;

  if v_side is null or v_side not in ('buy', 'sell') then
    raise exception 'invalid side' using errcode = '22023';
  end if;

  select nc.c into v_price
    from public.trade_normalized_candles(v_session_id) nc
   where nc.i = 59 + v_session.step;

  v_amount := v_quantity * v_price;
  v_fee    := v_amount * fee_rate;

  if v_side = 'buy' then
    if v_session.cash - v_amount - v_fee < 0 then
      raise exception '잔고가 부족합니다';
    end if;
    v_new_cash     := v_session.cash - v_amount - v_fee;
    v_new_quantity := v_session.quantity + v_quantity;
  else
    if v_quantity > v_session.quantity then
      raise exception '보유 수량이 부족합니다';
    end if;
    v_new_cash     := v_session.cash + v_amount - v_fee;
    v_new_quantity := v_session.quantity - v_quantity;
  end if;

  update public.trade_sessions ts
     set cash = v_new_cash, quantity = v_new_quantity
   where ts.id = v_session_id;

  insert into public.trade_orders (session_id, step, side, quantity, price, fee)
  values (v_session_id, v_session.step, v_side, v_quantity, v_price, v_fee);

  return public.trade_session_state(v_session_id);
end;
$$;

comment on function public.place_trade_order(uuid, text, numeric) is
  '현재 봉의 정규화 종가로 매수·매도한다. 수수료는 양쪽 0.1% 이고 잔고·보유 초과는 거절한다.';

revoke execute on function public.place_trade_order(uuid, text, numeric) from public, anon;
grant execute on function public.place_trade_order(uuid, text, numeric) to authenticated;

-- 한 봉 앞으로 간다. step 이 60 이 되면 마지막 봉(index 119)을 공개하고 자동 종료한다.
create function public.advance_trade_session(session_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_session_id uuid := advance_trade_session.session_id;
  v_session    public.trade_sessions;
  v_step       int;
begin
  select * into v_session
    from public.trade_sessions ts
   where ts.id = v_session_id
     and ts.user_id = (select auth.uid())
   for update;

  if not found then
    raise exception '판을 찾을 수 없습니다';
  end if;

  if v_session.finished_at is not null then
    raise exception '이미 끝난 판입니다';
  end if;

  v_step := v_session.step + 1;

  update public.trade_sessions ts
     set step = v_step
   where ts.id = v_session_id;

  if v_step = 60 then
    perform public.trade_settle(v_session_id, 119);
  end if;

  return public.trade_session_state(v_session_id);
end;
$$;

comment on function public.advance_trade_session(uuid) is
  '판을 한 봉 앞으로 옮긴다. step 이 60 이면 index 119 를 공개하고 청산·종료한다.';

revoke execute on function public.advance_trade_session(uuid) from public, anon;
grant execute on function public.advance_trade_session(uuid) to authenticated;

-- 아무 step 에서나 현재 봉의 종가로 청산하고 끝낸다.
create function public.finish_trade_session(session_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_session_id uuid := finish_trade_session.session_id;
  v_session    public.trade_sessions;
begin
  select * into v_session
    from public.trade_sessions ts
   where ts.id = v_session_id
     and ts.user_id = (select auth.uid())
   for update;

  if not found then
    raise exception '판을 찾을 수 없습니다';
  end if;

  if v_session.finished_at is not null then
    raise exception '이미 끝난 판입니다';
  end if;

  perform public.trade_settle(v_session_id, 59 + v_session.step);

  return public.trade_session_state(v_session_id);
end;
$$;

comment on function public.finish_trade_session(uuid) is
  '판을 지금 끝낸다. 현재 봉(index 59 + step)의 종가로 청산하고 결과를 공개한다.';

revoke execute on function public.finish_trade_session(uuid) from public, anon;
grant execute on function public.finish_trade_session(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- 5. posts 연결
-- -----------------------------------------------------------------------------

-- 게시물에 끝난 판을 붙인다. 판이 지워져도 게시물은 남는다(결과 카드만 사라진다).
alter table public.posts
  add column trade_session_id uuid references public.trade_sessions (id) on delete set null;

-- FK 의 on delete set null 이 훑는 자리다.
create index posts_trade_session_idx
  on public.posts (trade_session_id)
  where trade_session_id is not null;

-- posts 의 select GRANT 는 테이블 단위라 이 컬럼이 자동으로 포함된다.
-- insert · update GRANT 는 컬럼을 지정하므로 자동으로 빠진다 — 이것이 의도다.
-- 판을 붙이는 길은 아래 create_post_with_images() 하나뿐이다.

-- 오버로드로 두면 PostgREST 가 2-인자 호출에서 후보를 고르지 못한다(300 Multiple Choices).
-- 그래서 기존 함수를 지우고 3-인자(기본값 있는)로 다시 만든다. `{content, images}` 호출은
-- 기본값 덕분에 그대로 동작한다.
drop function public.create_post_with_images(text, jsonb);

create function public.create_post_with_images(
  content text,
  images jsonb,
  trade_session_id uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  -- 공개 URL 의 버킷 경계. 앱의 ImageStorage.objectPathFromPublicUrl 과 같은 표식을 본다.
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

    -- 표식이 없으면 split_part 가 빈 문자열을 준다 — 외부 URL 이거나 다른 버킷이다.
    object_path := split_part(split_part(image_url, marker, 2), '?', 1);
    if object_path = '' then
      raise exception 'image url must point to the post-images bucket'
        using errcode = '42501';
    end if;

    -- Storage 정책과 같은 규칙: 첫 경로 조각이 곧 소유자다.
    if split_part(object_path, '/', 1) <> author::text then
      raise exception 'image url must belong to the caller'
        using errcode = '42501';
    end if;

    -- `{user_id}/...` 로 끝나면 사용자 폴더 자체를 가리킨 것이다.
    if split_part(object_path, '/', 2) = '' then
      raise exception 'image url must point to an object'
        using errcode = '42501';
    end if;
  end loop;

  -- 끝난 내 판만 붙일 수 있다. 진행 중인 판을 붙이면 결과가 나오기 전에 종목이 샌다.
  -- 한 판을 여러 게시물에 붙이는 것은 막지 않는다.
  if create_post_with_images.trade_session_id is not null
     and not exists (
       select 1 from public.trade_sessions ts
        where ts.id = create_post_with_images.trade_session_id
          and ts.user_id = author
          and ts.finished_at is not null
     ) then
    raise exception '끝난 판만 공유할 수 있습니다' using errcode = '42501';
  end if;

  insert into public.posts (author_id, content, trade_session_id)
  values (author, create_post_with_images.content, create_post_with_images.trade_session_id)
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

comment on function public.create_post_with_images(text, jsonb, uuid) is
  '게시물과 이미지 메타데이터를 한 트랜잭션에 만든다. url 은 호출자 소유의 post-images 객체여야 하고, trade_session_id 는 끝난 내 판이어야 한다. 새 게시물 id 를 돌려준다.';

revoke execute on function public.create_post_with_images(text, jsonb, uuid)
  from public, anon;
grant execute on function public.create_post_with_images(text, jsonb, uuid)
  to authenticated;

-- -----------------------------------------------------------------------------
-- 6. 피드 뷰 둘에 trade_result 를 붙인다
--
-- create or replace view 는 컬럼을 뒤에 덧붙이는 것만 허용한다. 기존 목록과 순서를
-- 그대로 두고 맨 끝에 하나를 더한다.
--
-- security_invoker = on 이라 lateral 은 조회자 권한으로 trade_sessions 를 읽는다 —
-- 게스트는 trade_sessions_select_finished 정책과 위의 컬럼 GRANT 로 revealed_* 만
-- 읽는다. symbol · start_day 는 GRANT 가 없어 이 경로로도 나갈 수 없다.
-- -----------------------------------------------------------------------------
create or replace view public.posts_with_author
with (security_invoker = on) as
select
  p.id,
  p.author_id,
  p.content,
  p.created_at,
  p.updated_at,
  pr.nickname as author_nickname,
  pr.avatar_url as author_avatar_url,
  coalesce(images.items, '[]'::jsonb) as images,
  coalesce(reactions.counts, '{}'::jsonb) as reaction_counts,
  mine.type as my_reaction,
  coalesce(comments.total, 0) as comment_count,
  trade.result as trade_result
from public.posts p
join public.profiles pr on pr.id = p.author_id
left join lateral (
  select jsonb_agg(
    jsonb_build_object(
      'id', pi.id,
      'url', pi.url,
      'width', pi.width,
      'height', pi.height,
      'sort_order', pi.sort_order
    ) order by pi.sort_order
  ) as items
  from public.post_images pi
  where pi.post_id = p.id
) images on true
left join lateral (
  select jsonb_object_agg(grouped.type, grouped.total) as counts
  from (
    select r.type, count(*) as total
    from public.post_reactions r
    where r.post_id = p.id
    group by r.type
  ) grouped
) reactions on true
left join lateral (
  select r.type
  from public.post_reactions r
  where r.post_id = p.id and r.user_id = (select auth.uid())
) mine on true
left join lateral (
  select count(*) as total
  from public.post_comments c
  where c.post_id = p.id and c.deleted_at is null
) comments on true
left join lateral (
  select jsonb_build_object(
    'session_id',          s.id,
    'symbol',              s.revealed_symbol,
    'start_day',           s.revealed_start_day,
    'end_day',             s.revealed_end_day,
    'return_pct',          s.return_pct,
    'buy_hold_return_pct', s.buy_hold_return_pct,
    'max_drawdown_pct',    s.max_drawdown_pct,
    'trade_count',         s.trade_count
  ) as result
  from public.trade_sessions s
  where s.id = p.trade_session_id and s.finished_at is not null
) trade on true;

-- 20260830150000_harden_follows.sql 이 컬럼을 명시해 동결했다. 같은 목록에 한 줄을 더한다.
create or replace view public.following_posts_with_author
with (security_invoker = on) as
select
  p.id,
  p.author_id,
  p.content,
  p.created_at,
  p.updated_at,
  p.author_nickname,
  p.author_avatar_url,
  p.images,
  p.reaction_counts,
  p.my_reaction,
  p.comment_count,
  p.trade_result
from public.posts_with_author p
join public.follows f
  on f.followee_id = p.author_id
 and f.follower_id = (select auth.uid());

-- 뷰의 GRANT 는 테이블 단위라 새 컬럼이 자동으로 포함된다. 그래도 명시해 둔다.
grant select on public.posts_with_author           to anon, authenticated;
grant select on public.following_posts_with_author to authenticated;
