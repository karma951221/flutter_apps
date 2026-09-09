# trade 테스트

> [테스트 가이드](../README.md) · [계획](../../features/trade/plan.md) · [진행 현황](../../status.md)

```bash
cd app && flutter test test/features/trade
```

권한 경계와 채점은 프로젝트 루트에서, `supabase start` 후에 돌린다.

```bash
python3 supabase/tests/market_candles_grant_check.py   # 시세 테이블 직접 조회 차단
python3 supabase/tests/trade_rls_check.py              # 판 권한 경계 · 정규화 · 채점
python3 supabase/tests/trade_start_race_check.py       # 동시 판 시작 오류 정규화
```

## 단위 · 위젯

| 대상 | 경우 | 확인 |
|---|---|---|
| `TradeLedger` | 평가액 · 수익률 | 현금 0 · 보유 0 · 1.5배 · 절반의 경계값 |
| `TradeSizing` | 6자리 내림 | 음수 → 0, 이진 오차(0.29 × 1e6)도 의도한 자리로 내림 |
| `TradeSizing` | 100% 매수 | 수수료를 포함해도 총액이 현금을 넘지 않는다 (25 · 50% 도) |
| `TradeSizing` | 100% 매도 | 보유량을 그대로 돌려준다 — 내림 오차 없음 |
| 시나리오 | 빈 id · 0/NaN 수량 · 범위 밖 개수 | 저장소를 부르지 않고 `ValidationFailure` |
| DTO 넷 | `trade_session_state()` JSON | 정수로 온 숫자를 double 로 받고, candles/orders 가 없으면 빈 목록 |
| 매퍼 | 진행 중 · 끝남 · 도중 종료 | `result` null 여부, `endIndex = 59 + step` |
| `TradeCursor` | 왕복 · null · 깨진 값 | `FollowCursor` 와 같은 규칙 |
| `TradeRepositoryImpl` | 페이지 판정 | 한 개를 더 요청하고 잘라낸 뒤 마지막 항목으로 커서를 만든다 |
| `TradeRepositoryImpl` | 진행 중 판 | 없으면 `Ok(null)`, 있으면 그 id 로 상태를 읽는다 |
| `SupabaseTradeDataSource` | 비로그인 | 시작 · 주문 · 진행 · 종료 · 목록은 거부, `getSession` 은 게스트도 부른다 |
| `TradeHomeCubit` | 진행 중 있음/없음 · 실패 · 다음 페이지 · 시작 잠금 | 새로고침 경합에서 늦은 페이지를 버린다 |
| `TradeSessionCubit` | 주문 · 진행 · 종료 | 성공하면 서버 세션으로 통째로 교체, 실패하면 `loaded` 유지 + `Err`, 진행 중 연타는 `operationInProgress` |
| `TradeFormat` | 부호 · 자리수 | `+12.34%` · `−5.10%`(U+2212) · `0.00%`, 금액 `#,##0.00`, 수량 6자리 뒤 0 제거, `USDT` 접미 제거 |
| `TradeCandleChart` | 마커 · 경계 · 눈금 · 접근성 | 주문마다 마커 하나(매수는 저가 아래, 매도는 고가 위), 워밍업 경계 = plot 폭의 60/120, 봉이 60개여도 슬롯은 120, 눈금 3~4개, 빈 봉도 예외 없이 그린다, 스크린 리더에는 공개 봉 수·전체 봉 수·현재가를 한 이미지 설명으로 알린다 |
| `TradeOrderSheet` | 프리셋 · 전환 · 입력 오류 · 초과 | 25% 미리보기가 `TradeSizing` 과 같다, 금액↔수량 전환, 빈 입력은 조용히 잠기고 0·깨진 숫자는 이유를 보인다, 쉼표 소수점을 점으로 정규화한다, 잔고 초과면 확인이 잠긴다 |
| `TradeHomePage` | 이어하기 · 시작 · 빈 상태 · 지난 판 | 시작 성공 시 목록을 다시 읽는 사이 화면이 바뀌어도 판으로 들어간다 |
| `TradeSessionPage` | 지표 · 시트 · 진행 · 잠금 · 종료 | **심볼 · 날짜를 그리지 않는다(부정 단언)**, 끝나면 결과로 넘어가고 진행 화면은 스택에 남지 않는다, 홈에서 들어간 판을 끝내고 나오면 홈이 다시 읽는다 |
| `TradeResultPage` | 지표 4개 · 판정 · 미종료 | 보유 대비 한 줄, 끝나지 않은 판은 안내 |
| `HomeShellPage` | 탭 5개 | 투자가 첫 탭, 채팅 배지가 채팅 탭을 따라간다 |
| `resolveAuthRedirect` | 열린 경로 | `/trade/:id/result` 는 게스트도 로그인 사용자도 리다이렉트 없이 연다 |
| `TradeResultCard` | 값 · 탭 | 종목 · 기간 · 부호 있는 수익률 · 보유 대비 · 최대낙폭 · 매매 N회, `onTap` 이 있을 때만 눌린다 |
| `PostTile` (post) | 카드 유무 | `tradeResult` 가 있으면 본문 아래 카드, 없으면 그대로. 탭이 세션 id 를 돌려준다 |
| `PostEditorPage` (post) | 미리보기 | 결과 요약이 오면 카드와 안내를 보여주고 `create(tradeSessionId:)` 로 넘긴다 |
| `PostDto` · `FeedPostDto` (post · feed) | `trade_result` | null / 채움 둘 다 파싱하고 매퍼가 `Post.tradeResult` 를 채운다 |
| `SupabasePostDataSource` (post) | 경로 | 세션이 붙으면 이미지가 없어도 RPC, 아니면 직접 insert |
| `TradeResultPage` | 공유하기 | 내 판이면 버튼이 보이고 요약을 `extra` 로 넘긴다. 남의 판 · 게스트는 없다 |
| `GuestFeedPage` (feed) | 카드 | 게스트 피드에도 카드가 보인다 |

## 에뮬레이터 (2026-09-09)

로컬 Supabase + `Medium_Phone` AVD 에서 13개 항목을 실제로 돌렸다 — 새 판 → 매수
50% → 다음 날 ×3 → 매도 100% → 앱 강제 종료 후 이어하기 → 끝까지 → 결과 →
지난 판 목록 → 두 번째 판을 청산하고 끝내기 → 재실행 후 목록 유지 → 지난 판 열기.
세션 화면 스크린샷 16장 모두에 심볼 · 날짜 · 원가격 · 거래량이 없고, 결과 화면에만
있다. 기록은 [history](../../features/trade/history.md).

5.4 도 같은 방식으로 8개 항목을 돌렸다 — A 의 결과 화면 공유하기 → 미리보기 카드 →
게시 → 피드 · 프로필의 카드 → 카드 탭으로 결과 열기 → B 로 로그인해 반응 · 댓글 →
B 에게는 공유하기가 없다 → 게스트 피드에서 카드가 보이고 결과가 열린다 → 결과 없는
글은 그대로다. 발견: 공유 직후 피드는 당겨서 새로고침해야 새 글이 보인다.

## 권한 경계 · 채점 (`supabase/tests/trade_rls_check.py`)

실제 JWT + REST 로 64건을 확인한다. mock 으로는 드러나지 않는 것들이다.

- **숨김** — `trade_sessions` 를 `select=symbol` · `select=start_day` · `select=*` 로
  읽으면 본인도 `42501`. 같은 요청에서 `id,step,cash` 는 읽힌다(컬럼 단위 GRANT 임을 확인)
- **한 판 규칙** — 진행 중인 판이 있으면 두 번째 `start_trade_session` 이 거부된다
- **동시 시작** — psql 트랜잭션 둘을 겹치면 한 판만 남고, 뒤의 호출은
  `23505` 원문 대신 `진행 중인 판이 있습니다`로 거부된다
- **남의 판** — B 가 A 의 진행 중 판에 `get/place/advance/finish` → 전부
  `판을 찾을 수 없습니다`. 게스트의 `get` 도 거부. B 에게 A 의 `trade_orders` 는 0행
- **봉 공개 범위** — 진행 중 판의 `candles` 가 정확히 `60 + step` 개이고, 각 봉에
  `i,o,h,l,c` 키만 있다. `candles[59].c == 100`
- **주문 거부** — 잔고 초과 매수 · 보유 초과 매도 · 0 · `NaN` 수량이
  각각의 문구로 거부된다. `NaN` 거부 뒤 상태와 주문이 바뀌지 않는다
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
