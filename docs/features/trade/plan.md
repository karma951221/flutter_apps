# F10 trade — 계획 (블라인드 리플레이 모의투자)

> [문서 허브](../../README.md) · [기획 F10](../../overview.md) · [스키마 §17](../../schema.md) · [아키텍처](../../architecture.md) · [개발환경](../../setup.md) · [피드 계획](../feed/plan.md) · [게시물 계획](../post/plan.md) · [테스트](../../testing/features/trade.md)

> 상태: **진행 중** · 작성 2026-09-08 · 설계 확정 2026-09-09
> 진행 상태의 단일 기준은 [진행 현황](../../status.md)이다.

## 범위

종목과 시점을 가린 과거 일봉 차트를 한 봉씩 넘기며 사고팔고, 판이 끝나면 채점해서
보여준다. 결과는 게시물로 피드에 올릴 수 있다.

이 기능이 [기획서 v0.4](../../overview.md)에서 이 앱의 주인공이 됐다. 다만 **소셜
쪽을 대체하지 않는다** — F1~F9는 그대로 두고, 판 결과를 나누는 자리로 쓴다.

## 확정한 결정과 근거

| 항목 | 결정 | 근거 |
|---|---|---|
| 시장 | **코인만.** Binance USDT 페어 20종목, 일봉 | 24시간 장이라 **휴장일 · 액면분할 · 배당 보정이 없다.** 주식으로 시작하면 시뮬레이터 로직보다 보정 로직을 먼저 만들게 된다. 공개 API가 키 없이 상장 이후 전 구간을 준다 |
| 시세 조달 | **받아서 seed 로 적재.** 런타임에 거래소를 부르지 않는다 | 같은 종목·같은 시작점이면 언제 돌려도 같은 봉이 나와야 채점을 신뢰할 수 있다. 오프라인으로 돌아가고 레이트 리밋도 없다 ([기획 §4.7](../../overview.md)) |
| 상태 보관 | **서버(Supabase).** 로컬 DB에 두지 않는다 | 기기를 바꿔도 기록이 남고, 공유한 결과 카드를 서버 데이터로 검증할 수 있다. 무엇보다 **심볼을 서버에만 둬야 숨김이 성립한다** |
| 종목·시작점 | **앱이 무작위로 고른다.** 사용자가 지정할 수 없다 | 고를 수 있으면 아는 구간을 고르게 되고, 그때 점수는 판단력이 아니라 암기력을 잰다 |
| 가격 표시 | **매매 시작 봉(index 59)의 종가를 100으로 정규화.** 원가격을 내려보내지 않는다 | `4261.48` 이 보이면 2017년 BTC 임을 바로 안다. 정규화는 종목·시점을 동시에 가리는 가장 싼 방법이다 |
| 숨김 강제 | **`market_candles` 에 클라이언트 GRANT 를 주지 않고, `trade_sessions.symbol` · `start_day` 에도 GRANT 를 주지 않는다** | 화면에서 가리는 것은 우회된다. `security definer` RPC 만 읽게 하면 **심볼을 내려보낼 경로 자체가 없다** ([스키마 §16 · §17](../../schema.md)) |
| 공개 시점 | **판이 끝난 뒤에만** 종목·기간을 `revealed_*` 사본으로 공개한다 | 판이 끝나면 숨길 이유가 사라지고, "무엇이었는지" 를 알아야 배우는 것이 남는다. 원본 컬럼이 아니라 사본이라 정책 하나로 "끝난 판만" 을 강제할 수 있다 |
| 한 판 길이 | 워밍업 60봉(보기만) + 진행 60봉(매매 가능) = 120봉 | 워밍업이 없으면 첫 봉에서 아무 근거 없이 사야 한다. 진행 60봉은 일봉 기준 약 2개월로, 한 판이 몇 분 안에 끝나 피드백이 빠르다 |
| 초기 자금 | 10,000 (단위 없음) | 가격이 100 으로 정규화되므로 통화 단위를 붙이면 오히려 혼란스럽다 |
| 주문 | **시장가만 · 현재 봉 종가 체결 · 롱만 · 수수료 양쪽 0.1% · 수량 소수 6자리** | 지정가·공매도·레버리지는 체결 모델을 먼저 만들어야 한다. 일봉 리플레이에서 봉 중간 체결은 추정이므로 종가로 고정한다 |
| 남은 봉 전달 | **봉마다 받는다.** RPC 응답이 `index ≤ 59 + step` 까지만 담는다 | 한 번에 주면 클라이언트가 미래를 본다. 응답 크기(최대 120봉)가 작아 매 step 전체를 다시 받는 비용은 무시할 만하다 |
| 진행 | **"다음 날" 버튼으로 수동 진행.** step 59 에서 넘기면 자동 종료 | 자동 재생은 속도 조절·일시정지가 따라온다. 수동이면 상태가 "몇 번째 봉인가" 하나다 |
| 손익 계산 위치 | **DB 가 정본, 앱은 표시용.** 채점은 `trade_settle()` 이 주문을 재생해 계산하고, 앱의 `TradeLedger` · `TradeSizing` 은 화면의 예상값만 만든다 | 결과를 위조할 수 없어야 공유 카드가 의미를 갖는다. 앱 계산은 서버 응답이 오면 덮어쓴다 |
| 결과 지표 | 수익률 · **buy&hold 대비** · 최대낙폭 · 매매 횟수. 전부 정규화 종가 기준 소수 2자리 | 수익률만 보면 상승장에서 아무나 잘한 것처럼 보인다. buy&hold 대비가 "매매가 도움이 됐는가" 를 답한다. 정규화 종가로 계산해야 사용자가 본 가격과 채점이 일치한다 |
| 종료 청산 | **자동 청산은 주문이 아니다.** `trade_orders` 에 남기지 않고 `trade_count` 에 세지 않는다 | 사용자의 판단이 아니라 시스템 동작이다. 수익률에는 청산 수수료가 반영된다 |
| 중단 · 재개 | **된다.** 상태가 서버에 있으므로 앱을 껐다 켜도 진행 중인 판을 "이어하기" 로 같은 step 에서 연다 | 사용자당 진행 중인 판은 1개(부분 유니크 인덱스)라 "어느 판" 을 물을 필요가 없다 |
| 차트 | **`CustomPainter` 로 직접 그린다.** 패키지 없음 | 필요한 것이 캔들 · 배경 두 구간 · 마커 · 눈금뿐이다. 패키지는 원가격 축 · 날짜 축 같은 **보여주면 안 되는 것** 을 기본으로 그린다 |
| 결과 카드 저장 | **게시물에 세션 id 만 건다.** 스냅샷은 `trade_sessions.revealed_*` · 결과 컬럼이 이미 불변 스냅샷이다 | 판 데이터는 끝난 뒤 바뀌지 않는다(쓰기 경로가 RPC 뿐이고 끝난 판은 RPC 가 거부). 게시물에 다시 박으면 같은 값이 두 곳에 생긴다 |
| 결과 공유 | **`posts` 에 첨부 유형이 하나 느는 형태** (`posts.trade_session_id`) | 별도 게시물 테이블을 만들면 피드 · 반응 · 댓글 · 신고 · 차단을 전부 다시 만들어야 한다 |
| 소셜 참조 방향 | trade → post 의 `domain` 만. 반대는 `TradeResultCard` 위젯 하나로 제한 | 이 경계를 지켜야 시뮬레이터를 소셜과 무관하게 테스트할 수 있다 ([아키텍처 규칙 ⑥](../../architecture.md)) |

## 데이터 · 권한

모양과 권한의 단일 기준은 [스키마](../../schema.md)다. 여기서는 앱 쪽 의미만 적는다.

### `market_candles` (§16, 5.1)

Binance 일봉 원시 시세. 사용자 데이터와 FK 관계가 없고 판이 **읽기만** 한다.
앱은 직접 조회하지 않는다 — 하면 `42501` 로 막히고, 그것이 의도다
(`supabase/tests/market_candles_grant_check.py`). 갱신은
`supabase/scripts/fetch_candles.py` ([개발환경 §5](../../setup.md)).

### `trade_sessions` · `trade_orders` (§17, 5.2)

- `trade_sessions` 한 행이 판 하나다. 진행 상태(`step` · `cash` · `quantity`)와
  결과 스냅샷(`revealed_*` · 지표)이 같은 행에 있고, `finished_at` 이 채워질 때
  결과가 함께 채워진다(all-or-none CHECK).
- **`symbol` · `start_day` 는 어떤 role 도 select 할 수 없다.** 끝난 뒤에는
  `revealed_symbol` · `revealed_start_day`(index 59 의 day) · `revealed_end_day` 사본으로만
  읽는다. 조회 정책은 "내 판" 과 "끝난 판(누구나, 게스트 포함)" 둘이다.
- `trade_orders` 는 체결 기록. 세션이 보이면 주문도 보인다.
- 쓰기는 전부 RPC 다. 테이블에는 `insert/update/delete` GRANT 가 없다.

### RPC 5개

| 함수 | 하는 일 | 누가 |
|---|---|---|
| `start_trade_session() → uuid` | 봉이 120개 이상인 심볼과 시작일을 무작위로 골라 판을 만든다. 진행 중인 판이 있으면 거부 | `authenticated` |
| `get_trade_session(session_id) → jsonb` | 상태. 진행 중이면 `index ≤ 59 + step` 봉만, 끝났으면 120봉 + `result` | `anon` · `authenticated` (게스트가 피드 카드에서 결과를 연다) |
| `place_trade_order(session_id, side, quantity) → jsonb` | 현재 봉 정규화 종가로 체결. 잔고 · 보유 검사 | `authenticated` |
| `advance_trade_session(session_id) → jsonb` | step + 1. 60 이 되면 close[119] 로 청산하고 종료 | `authenticated` |
| `finish_trade_session(session_id) → jsonb` | 현재 종가로 청산하고 종료 | `authenticated` |

정규화 · 상태 조립 · 채점은 내부 헬퍼(`trade_normalized_candles` ·
`trade_session_state` · `trade_settle`) 하나씩에 모여 있고, 클라이언트에는 execute
가 없다. 상태 JSON 의 모양은 [§17](../../schema.md)에 있다.

### `posts` 연결 (§5 · §6, 5.2)

`posts.trade_session_id` (nullable, `on delete set null`). 값을 넣는 경로는
`create_post_with_images(content, images, trade_session_id default null)` 뿐이고,
**내 판이면서 끝난 판** 만 받는다. 피드 뷰 둘(`posts_with_author` ·
`following_posts_with_author`)이 `trade_result jsonb` 로 결과 요약을 함께 내려주므로
카드는 N+1 없이 그려진다.

## 계산 규칙

```
WARMUP_CANDLES = 60      # index 0..59, 보기만
TRADE_STEPS    = 60      # step 0..59 매매 가능, step 60 = 종료
TOTAL_CANDLES  = 120
INITIAL_CASH   = 10000
FEE_RATE       = 0.001
```

- step s 의 현재 봉 index = 59 + s. 체결가 = 그 봉의 정규화 종가.
- 정규화: `round(x / close[59] × 100, 2)`. 그래서 매매 시작 봉의 종가는 항상 100.
- 매수: `cost = q × price`, `fee = cost × 0.001`, `cash − cost − fee ≥ 0` 이어야 한다.
  매도: `q ≤ 보유`, `proceeds = q × price`, `fee = proceeds × 0.001`.
- `return_pct = (최종 현금 / 10000 − 1) × 100`
- `buy_hold_return_pct = ((1 − FEE)² × close[end] / close[59] − 1) × 100` — 수수료 양쪽 포함
- `max_drawdown_pct` = step 0..end 의 평가액 곡선(그 step 의 주문을 반영한 뒤
  `cash + quantity × close[59+s]`, 종료 step 은 청산 후 현금)에서
  `max((peak − equity) / peak) × 100`, peak 초기값 10000
- `trade_count` = 주문 수
- 앱의 `TradeSizing` 은 25/50/100% 버튼과 직접 입력의 **예상** 수량을 만든다:
  `buyQuantity = floor6(cash × fraction / (price × (1 + FEE)))`. 내림이라 서버가
  잔고 부족으로 거부할 일이 없다. 서버 응답이 오면 로컬 값을 덮어쓴다.

## usecase

`features/trade` 를 새로 만든다. 규칙 ③대로 facade 는 `TradeUseCase` 하나다.

```
features/trade/
├── domain/
│   ├── trade_rules.dart                  ← 상수 · indexForStep
│   ├── entity/
│   │   ├── trade_side.dart               buy | sell
│   │   ├── trade_candle.dart             { index, open, high, low, close }  (정규화값)
│   │   ├── trade_order.dart              { step, side, quantity, price, fee }
│   │   ├── trade_result.dart             { symbol, startDay, endDay, endIndex, finalEquity, returnPct, buyHoldReturnPct, maxDrawdownPct, tradeCount }
│   │   ├── trade_session.dart            { id, userId, step, cash, quantity, isFinished, candles, orders, result? }
│   │   ├── trade_session_summary.dart    지난 판 목록 행
│   │   └── trade_result_summary.dart     게시물에 실리는 요약 (5.4)
│   ├── ledger/
│   │   ├── trade_ledger.dart             equity · returnPct (순수 함수)
│   │   └── trade_sizing.dart             buyQuantity · sellQuantity · buyCost · sellProceeds
│   ├── repository/trade_repository.dart
│   └── usecase/trade_use_case.dart + scenario/ (판 시작 · 조회 · 진행 중 판 · 주문 · 진행 · 종료 · 지난 판 목록)
├── data/
│   ├── cursor/trade_cursor.dart          (created_at, id) 불투명 커서
│   ├── dto/                              RPC jsonb · 테이블 행
│   ├── datasource/{trade_data_source,supabase_trade_data_source}.dart
│   ├── mapper/trade_session_mapper.dart
│   └── repository/trade_repository_impl.dart
└── presentation/
    ├── cubit/trade_home_cubit.dart · trade_session_cubit.dart (+ state)
    ├── format/trade_format.dart          부호 있는 %, 금액, 기간, 심볼 표기
    ├── page/trade_home_page.dart · trade_session_page.dart · trade_result_page.dart
    └── widget/trade_candle_chart.dart · trade_order_sheet.dart · trade_result_card.dart
```

| 동작 | 시그니처 |
|---|---|
| 판 시작 | `Future<Result<String>> startSession()` |
| 상태 | `Future<Result<TradeSession>> getSession(String sessionId)` |
| 진행 중 판 | `Future<Result<TradeSession?>> getActiveSession()` |
| 주문 | `Future<Result<TradeSession>> placeOrder({sessionId, side, quantity})` |
| 다음 날 | `Future<Result<TradeSession>> advance(String sessionId)` |
| 청산 종료 | `Future<Result<TradeSession>> finish(String sessionId)` |
| 지난 판 | `Future<Result<CursorPage<TradeSessionSummary>>> getPastSessions({limit, cursor})` — 내 끝난 판, 최신순 |

주문 · 진행 · 종료가 모두 **새 상태 전체** 를 돌려준다. 화면은 응답으로 상태를
통째로 교체하므로 로컬에서 잔고를 계산해 어긋날 일이 없다.

## 화면

| 화면 | 경로 | 내용 |
|---|---|---|
| 홈 탭 **투자** | `/` 첫 번째 탭 | 진행 중이면 "이어하기" 카드(step/60 · 평가액), 없으면 "새 판 시작". 아래 내 지난 판 목록(종목 · 기간 · 수익률, 커서 페이지네이션). 빈 상태 `AppPlaceholder` |
| `TradeSessionPage` | `/trade/:sessionId` | 위 차트(워밍업 · 매매 구간 배경 구분, 주문 ▲▼), 가운데 현금 · 보유 · 평가액 · 현재 수익률, 아래 매수 · 매도 → 바텀시트, 전체 폭 "다음 날". 더보기 → "청산하고 끝내기"(`AppConfirmDialog`, destructive). 끝나면 결과 화면으로 `pushReplacement` |
| `TradeResultPage` | `/trade/:sessionId/result` | 공개된 종목 · 기간, 지표 카드 4개, 수익률 vs buy&hold 한 줄, 120봉 차트 + 마커, 공유하기(5.4, 내 판일 때만). **끝난 판이면 누구나, 게스트도 연다** |

- 홈 탭 순서는 투자 · 피드 · 채팅 · 프로필 · 설정 ([아키텍처 3-2](../../architecture.md)).
- 주문 시트: 25% / 50% / 100% + 직접 입력(매수는 금액 또는 수량, 매도는 수량).
  예상 체결 수량 · 수수료 · 잔여 현금(매도는 수령액 · 수수료 · 잔여 수량)을 시트 안에
  보여준다. 잔고 · 보유를 넘으면 확인이 잠긴다.
- **세션 화면 어디에도 종목 · 날짜 · 거래량 · 원가격이 없다.** x 축은 `D−59 … D0 … D+60`
  상대 표기, y 축은 정규화 가격이다.
- 결과 화면은 인증 리다이렉트를 타지 않는 **열린 경로** 다 — `publicRoutes`(로그인
  사용자를 홈으로 돌려보냄)와 다르다.

## 상태

- `TradeHomeCubit` — `loading | loaded(active?, past, nextCursor, isLoadingMore, isStarting) | failure`.
  `load` 가 진행 중 판과 지난 판 첫 페이지를 함께 읽는다. `start` 는 잠갔다가 id 를
  돌려주고 화면이 이동한다.
- `TradeSessionCubit` — `loading | loaded(session, isSubmitting) | failure`. `placeOrder` ·
  `advance` · `finish` 는 `isSubmitting` 으로 연타를 막고 `Result` 를 돌려준다(화면이
  스낵바). 성공하면 서버가 준 세션으로 통째로 교체한다. 결과 화면도 이 cubit 의
  `load` 를 쓴다.
- cubit 은 화면 수명과 함께 산다(`BlocProvider`). 홈 탭은 세션 · 결과 화면에서
  돌아올 때 `refresh` 한다.

## 오류

| 상황 | 처리 |
|---|---|
| 진행 중인 판이 있는데 시작 | `진행 중인 판이 있습니다` → `FailureCode.tradeSessionAlreadyActive` |
| 남의 진행 중 판 · 없는 id | `판을 찾을 수 없습니다` → `tradeSessionNotFound`. 존재 여부를 밝히지 않는다 |
| 끝난 판에 주문 · 진행 | `이미 끝난 판입니다` → `tradeSessionFinished` |
| 잔고 · 보유 초과 | `잔고가 부족합니다` · `보유 수량이 부족합니다`. 시트가 먼저 잠그므로 방어선이다 |
| 0 이하 수량 | `수량은 0보다 커야 합니다` → `tradeQuantityInvalid` (scenario 가 먼저 거른다) |
| 끝나지 않았거나 남의 판으로 게시물 작성 | `끝난 판만 공유할 수 있습니다` → `tradeSessionNotShareable` |
| 비로그인 | 결과 화면 외의 경로는 라우트가 막는다. 데이터 계층은 `authenticationRequired` 로 방어 |

## 단계

[기획 §8](../../overview.md)의 5단계를 그대로 따른다.

| 단계 | 범위 | 끝났을 때 |
|---|---|---|
| **5.1** | 수집 스크립트 · `market_candles` · seed 적재 | `supabase db reset` 하나로 20종목 시세가 올라온다 |
| **5.2** | 판 · 주문 테이블 · RPC 5개 · RLS · `posts` 연결 · 검증 스크립트 | 심볼을 숨긴 채 판을 만들고 채점하는 것이 REST 로 검증된다 |
| **5.3** | `features/trade` · 홈 탭 · 화면 3개 · 차트 | **혼자서 판을 끝까지 돌린다** |
| **5.4** | 결과 공유 게시물 · 피드 카드 · 결과 화면 공개 열람 | 판 결과를 올리고 반응 · 댓글이 붙는다 |

**5.3 까지만 해도 제품으로 성립한다.** 공유(5.4)를 먼저 만들지 않는다.

## 완료 조건

### 5.1 — 시세 적재

- [x] `supabase/scripts/fetch_candles.py` 가 표준 라이브러리만으로 Binance 일봉을 받는다
- [x] 20종목 각각 120봉 이상, 날짜가 하루도 빠지지 않는다
- [x] `supabase db reset` 이 마이그레이션 뒤 seed 를 적재한다
- [x] `anon` · `authenticated` 의 `market_candles` 조회가 `42501` 로 막힌다

### 5.2 — 스키마 · RPC · 권한

- [x] `trade_sessions.symbol` · `start_day` 를 본인도 읽지 못한다 (`42501`)
- [x] 진행 중인 판이 있으면 두 번째 시작이 거부된다
- [x] 남의 진행 중 판은 조회 · 주문 · 진행 · 종료 전부 거부된다. 게스트도 마찬가지
- [x] 진행 중 판의 봉이 정확히 `60 + step` 개이고 `close[59] = 100`, 원가격 · 거래량 · 날짜 키가 없다
- [x] 잔고 초과 매수 · 보유 초과 매도 · 0 수량이 거부된다
- [x] step 59 에서 넘기면 자동 종료 — 120봉과 결과가 채워진다
- [x] 매수 1회 → 끝까지의 `return_pct` · `buy_hold_return_pct` · `max_drawdown_pct` 를
      스크립트가 봉으로 직접 계산해 소수 2자리까지 일치한다
- [x] 끝난 판은 게스트도 읽고 `result.symbol` 이 있다. 피드 뷰의 `trade_result` 가 채워진다
- [x] 남의 판 · 끝나지 않은 판으로는 게시물을 만들 수 없다
- [x] 기존 검증 스크립트 전부가 여전히 통과한다

### 5.3 — 앱

- [x] 새 판 → 매수 → 진행 → 매도 → 끝까지 → 결과 화면. 앱을 껐다 켜도 지난 판 목록에 남는다
- [x] 진행 중 앱을 껐다 켜면 "이어하기" 로 같은 step 에서 재개된다
- [x] 세션 화면 어디에도 심볼 · 날짜 · 원가격이 없다 (스크린샷)
- [x] `flutter analyze` 0 · `flutter test` 전체 통과

### 5.4 — 결과 공유

- [ ] 결과 화면 → 공유하기 → 게시물 → 피드 카드 → 다른 계정에서 반응 · 댓글
- [ ] 게스트 피드에서도 카드가 보이고, 탭하면 결과 화면이 열린다

## 테스트

단위 · 위젯은 [테스트 문서](../../testing/features/trade.md)에, 권한 경계와 채점은
`supabase/tests/trade_rls_check.py` 에 둔다. RLS · 정규화 · 채점은 mock 으로
드러나지 않으므로 실제 JWT + REST 로 확인한다 — 팔로우 · 채팅과 같은 방식이다.

## v1 범위 밖

실시간 시세 · 주식 · 공매도 · 지정가/스탑 · 레버리지 · 리더보드 · 자동 재생 ·
여러 종목 동시 보유 · 판 이어서 여러 판 비교. 리더보드는 판이 쌓인 뒤에 다시 본다.
