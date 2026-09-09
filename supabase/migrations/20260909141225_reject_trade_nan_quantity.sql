-- PostgreSQL numeric 은 NaN 을 값으로 받아들이고, NaN <= 0 이 false 라서 기존
-- 양수 검사를 통과한다. PostgREST 도 JSON 문자열 "NaN" 을 numeric 인자로
-- 변환하므로 RPC 경계에서 명시적으로 거부한다.
create or replace function public.place_trade_order(
  session_id uuid,
  side text,
  quantity numeric
)
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

  if v_quantity is null
     or v_quantity = 'NaN'::numeric
     or v_quantity <= 0 then
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
  '현재 봉의 정규화 종가로 매수·매도한다. NaN·0 이하 수량과 잔고·보유 초과는 거절한다.';

revoke execute on function public.place_trade_order(uuid, text, numeric)
  from public, anon;
grant execute on function public.place_trade_order(uuid, text, numeric)
  to authenticated;
