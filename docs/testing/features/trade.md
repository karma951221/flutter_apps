# trade 테스트

> [테스트 가이드](../README.md) · [계획](../../features/trade/plan.md) · [진행 현황](../../status.md)

```bash
cd app && flutter test test/features/trade
```

권한 경계와 채점은 프로젝트 루트에서, `supabase start` 후에 돌린다.

```bash
python3 supabase/tests/market_candles_grant_check.py   # 시세 테이블 직접 조회 차단
python3 supabase/tests/trade_rls_check.py              # 판 권한 경계 · 정규화 · 채점
```

## 단위 · 위젯

5.3 에서 채운다. 대상은 [계획의 usecase 절](../../features/trade/plan.md)의 구조를
그대로 미러링한다 — `domain/ledger/` 순수 함수, cubit 둘, 화면 셋, 차트 painter.

## 권한 경계 · 채점 (`supabase/tests/trade_rls_check.py`)

실제 JWT + REST 로 61건을 확인한다. mock 으로는 드러나지 않는 것들이다.

- **숨김** — `trade_sessions` 를 `select=symbol` · `select=start_day` 로 읽으면 본인도
  `42501`. 같은 요청에서 `id,step,cash` 는 읽힌다(컬럼 단위 GRANT 임을 확인)
- **한 판 규칙** — 진행 중인 판이 있으면 두 번째 `start_trade_session` 이 거부된다
- **남의 판** — B 가 A 의 진행 중 판에 `get/place/advance/finish` → 전부
  `판을 찾을 수 없습니다`. 게스트의 `get` 도 거부. B 에게 A 의 `trade_orders` 는 0행
- **봉 공개 범위** — 진행 중 판의 `candles` 가 정확히 `60 + step` 개이고, 각 봉에
  `i,o,h,l,c` 키만 있다. `candles[59].c == 100`
- **주문 거부** — 잔고 초과 매수 · 보유 초과 매도 · 0 수량이 각각의 문구로 거부된다.
  끝난 판에 주문 · 진행 · 종료 → `이미 끝난 판입니다`
- **손계산** — step 0 에 `buy 10` → `cash 8999 · fee 1 · price 100`. `advance` 59번 →
  step 59, 119봉. 60번째 → `finished`, 120봉, `end_index 119`. 스크립트가 받은 봉으로
  `return_pct` · `buy_hold_return_pct` · `max_drawdown_pct` · `final_equity` 를
  `Decimal` 로 직접 계산해 DB 값과 소수 2자리 일치
- **청산 종료** — step 3 에서 `finish` → `end_index 62`, `trade_count 0`, `return_pct 0`,
  buy&hold 는 `c[62]/c[59]` 로 계산 일치
- **공개** — 끝난 판은 게스트도 `get` 할 수 있고 `result.symbol` 이 `USDT` 로 끝나며
  날짜가 `YYYY-MM-DD` 다. 게스트도 `trade_orders` 를 읽는다
- **게시물** — 내 끝난 판으로 `create_post_with_images` 성공, 기존 2-인자 호출도 성공.
  남의 판 · 내 진행 중 판 → `끝난 판만 공유할 수 있습니다`
- **피드 뷰** — 게스트가 `posts_with_author` 에서 `trade_result` 를 읽는다. 판이 없는
  게시물은 `null`. `following_posts_with_author` 도 같은 값을 준다
- **탈퇴** — 계정을 지우면 판이 cascade 로 사라진다

## 알아둘 것

- 위젯 테스트는 `locale: Locale('ko')` 를 고정한다. `ko` 가 ARB template 이라
  원문이 곧 기대값이다
- 세션 화면 테스트는 "심볼 · 날짜 · 원가격이 없다" 를 **부정 단언** 으로 지킨다 —
  화면 텍스트에 `USDT` 와 `20xx-` 패턴이 없어야 한다
