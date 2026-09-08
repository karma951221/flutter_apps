-- 원시 시세와 심볼은 클라이언트에 노출하지 않는다. anon/authenticated GRANT와
-- RLS 정책을 의도적으로 두지 않고, 후속 security definer RPC만 읽게 한다.
create table public.market_candles (
  symbol text    not null,
  day    date    not null,
  open   numeric not null,
  high   numeric not null,
  low    numeric not null,
  close  numeric not null,
  volume numeric not null,
  primary key (symbol, day),
  constraint market_candles_ohlc check (
    high >= greatest(open, close) and low <= least(open, close)
  ),
  constraint market_candles_volume check (volume >= 0)
);

alter table public.market_candles enable row level security;

-- Supabase의 기본 권한 처리로 붙을 수 있는 비조회 권한까지 모두 제거한다.
revoke all privileges on public.market_candles from anon, authenticated;

-- seed 검증과 운영 작업은 service_role만 직접 조회한다.
grant select on public.market_candles to service_role;

comment on table public.market_candles is
  '일봉 원시 시세. 종목 숨김을 권한으로 보장하기 위해 클라이언트 GRANT와 RLS 정책 없이 security definer RPC로만 읽는다.';
