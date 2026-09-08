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

## 2026-09-09 — 5.3 앱

### 결과 화면은 "열린 경로" 다

`publicRoutes` 는 비로그인 전용이라 로그인 사용자가 들어오면 홈으로 돌려보낸다.
결과 화면은 게스트도 로그인 사용자도 그대로 열려야 하므로 `Routes.openRoutes`
(정규식 `^/trade/[^/]+/result$`)를 따로 두고 `resolveAuthRedirect` 가 그 경로는
손대지 않는다. `AuthUnknown` 은 여전히 splash 로 간다.

### 서버 응답으로 상태를 통째로 교체한다

주문 · 진행 · 종료 RPC 가 새 상태 전체를 돌려주므로 `TradeSessionCubit` 은 응답으로
`loaded` 를 갈아끼운다. 앱의 `TradeLedger` · `TradeSizing` 은 시트의 미리보기와
카드 표시만 맡는다 — 서버와 반올림이 어긋나도 다음 응답에서 덮인다.

### 상태 emit 이 호출한 위젯을 언마운트한다

`TradeHomeCubit.start()` 가 성공 뒤 목록을 다시 읽으며 `loading` 을 emit 하면
시작 버튼이 있던 트리가 통째로 사라진다. `await` 뒤에 `context.mounted` 로 가드하면
이동 코드가 그냥 건너뛰어진다 — 위젯 테스트는 mock future 가 프레임 전에 끝나서
잡지 못했다. 라우터와 cubit 을 `await` 전에 잡고 `cubit.isClosed` 로 가드했고,
테스트는 `Completer` 로 재조회를 열어 둔 채 프레임을 펌프한다.

### 판이 끝나면 `pushReplacement` 가 아니라 pop 뒤 push

계획은 `pushReplacement` 였다. 그런데 go_router 는 교체된 imperative 라우트의
`push` future 를 완료하지 않아, 홈이 `await router.push(...)` 뒤에 하는 `refresh()`
가 영원히 돌지 않는다 — 끝난 판이 "이어하기" 로 남고 시작 버튼이 숨는다.
`canPop()` 이면 `pop()` 후 `push(result)`, 링크로 곧장 연 판(스택 바닥)만
`pushReplacement` 다. 결과 화면 뒤에 살아 있는 매매 화면이 남지 않는 성질은
그대로다. 대가: pop 과 push 가 같은 프레임에 겹쳐 전환 순간에 앱바가 잠깐 둘로
보인다 — 다듬을 후보.

### 차트는 슬롯 120개 고정

봉이 60개뿐이어도 x 축은 120 슬롯이라 왼쪽 절반만 채워지고 판이 진행되며
오른쪽으로 자란다. 스크롤이 없고, 남은 날이 얼마나 되는지가 그림으로 보인다.
x 라벨은 `D−59 · D0 · D+60` 뿐이다.

### 검증

`flutter analyze` 0 · `flutter test` 811 통과. 에뮬레이터에서 13개 항목 전부 통과
([테스트 문서](../../testing/features/trade.md)). 미룬 것: 종료 전환 시 앱바 겹침,
`_returnColor` 두 페이지 중복, 주문 시트의 0/파싱 불가 입력 안내 없음, 쉼표 입력
무시. 5.3 과 무관한 기존 결함 하나를 봤다 — 가입 직후 셸 전환에서 `feed_page` 와
`chat_room_list_page` 의 `FloatingActionButton.extended` 가 `heroTag` 없이 충돌
단언을 낸다(한 번 재현).
