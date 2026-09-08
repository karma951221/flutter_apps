# F10 trade — 기록

> [문서 허브](../../README.md) · [계획](plan.md) · [스키마 §17](../../schema.md) · [테스트](../../testing/features/trade.md)

설계 판단 · 막힌 것 · 검증 결과를 남긴다. 진행 상태는 [진행 현황](../../status.md)에만 적는다.

## 2026-09-09 — 5.2 스키마 · RPC · 권한

### 숨김을 컬럼 GRANT 로 강제했다

`symbol` · `start_day` 는 어떤 role 에도 select 를 주지 않는다. RLS 정책은 행을
거르지 컬럼을 거르지 못하므로, "내 판은 보이되 심볼은 안 보인다" 는 정책으로
표현할 수 없다. 끝난 뒤의 공개는 `revealed_*` 사본 컬럼으로 한다 — 원본을 열면
"끝난 판만" 이라는 조건을 컬럼 GRANT 에 붙일 수 없어서다. 그래서 같은 값이 두
컬럼에 있는 것은 중복이 아니라 권한 경계의 표현이다 ([스키마 §17](../../schema.md)).

### 정규화와 채점은 DB 한 곳에

정규화 · 상태 조립 · 청산과 지표 계산을 헬퍼 셋(`trade_normalized_candles` ·
`trade_session_state` · `trade_settle`)에 모으고 RPC 다섯이 그것을 부른다. 함수마다
복사하면 반올림 자리 하나가 어긋나는 순간 "같은 판인데 결과가 다르다" 가 된다.
클라이언트에는 헬퍼의 execute 를 주지 않는다.

지표는 **정규화된 2자리 종가** 로 계산한다. 원가격으로 계산하면 사용자가 본 가격과
채점이 미세하게 어긋나고, 검증 스크립트가 봉으로 재계산해 맞출 수도 없다.

### 자동 청산은 주문이 아니다

종료 시 보유분 청산은 `trade_orders` 에 남기지 않고 `trade_count` 에 세지 않는다.
사용자의 판단이 아닌 시스템 동작이라서다. 수수료는 최종 현금에 반영된다.

### `create_post_with_images` 는 오버로드 대신 교체

3번째 인자 `trade_session_id uuid default null` 을 붙이면서 2-인자 함수를 **drop**
했다. 둘을 함께 두면 PostgREST 가 `{content, images}` 호출에서 후보를 고르지 못한다
(300). default 덕에 기존 호출은 그대로 동작한다.

### 뷰에 컬럼을 더할 때의 함정

`posts_with_author` 에 `trade_result` 를 **맨 끝에** 더했다(`create or replace view` 는
끝에만 더할 수 있다). `following_posts_with_author` 는 `harden_follows` 가 컬럼을
명시해 동결해 둔 뷰라 따라오지 않는다 — 같은 목록 + `trade_result` 로 다시 만들었다.

### 함수 `search_path`

프롬프트 초안은 `set search_path = public` 이었지만 저장소의 모든 함수가
`''` + `public.` 완전 수식이라 그 규약을 따랐다.

### 검증

`supabase db reset` 후 `trade_rls_check.py` 61/61, 기존 스크립트 7개
(`guest_read` 6 · `market_candles_grant` 2 · `follow_rls` 28 · `chat_rls` 84 ·
`account_summary` 3 · `follow_block_race` 4 · `chat_realtime` 4) 전부 통과.

리뷰에서 나온 것 중 미룬 것: `start_trade_session` 을 동시에 두 번 부르면 유니크
인덱스가 막되 문구가 `23505` 원문으로 샌다(앱은 버튼을 잠그므로 실제로는 닿기
어렵다). `fee_rate` · `initial_cash` 상수가 `trade_settle` · `place_trade_order` ·
테이블 default 세 곳에 있다.
