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

### 판이 끝나면 `pushReplacement`, 홈 새로고침은 RouteObserver 가 한다

go_router 는 **교체된** imperative 라우트의 `push` future 를 완료하지 않는다.
그래서 홈이 `await router.push(session)` 뒤에 `refresh()` 하는 구조에서
`pushReplacement` 로 결과 화면에 넘어가면 새로고침이 영원히 돌지 않았다 — 끝난 판이
"이어하기" 로 남고 시작 버튼이 숨었다. 처음에는 `canPop()` 이면 `pop()` 후
`push(result)` 로 우회했는데, 두 전환이 같은 프레임에 겹쳐 앱바가 잠깐 둘로 보였다.

지금은 **원인 쪽을 고쳤다.** 새로고침을 push future 에서 떼어 `RouteObserver` 로
옮기고(`app/router/route_observer.dart`), 세션 화면은 언제나 `pushReplacement` 한다.
홈은 얹은 화면으로 들어갈 때 플래그를 세우고 `didPopNext` 에서만 다시 읽는다 —
탭 본문이라 셸 라우트를 구독하므로, 플래그가 남의 pop 을 걸러 준다. 전환은 한 번이고,
세션 화면이 결과 뒤에 남지 않는 성질도 그대로다. 판을 끝내지 않고 뒤로 나와도
같은 경로로 갱신된다.

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

## 2026-09-09 — 5.4 결과 공유

### 요약 엔티티는 trade 가, DTO 는 각자

`TradeResultSummary` 는 `features/trade/domain` 에 두고 post 가 `Post.tradeResult` 로
품는다(도메인 참조는 허용). 전송 형식은 post 와 feed 가 각각 `post_trade_result_dto` ·
`feed_trade_result_dto` 를 갖는다 — 모양이 같아도 data 계층은 feature 를 넘지 않는다는
규칙 ⑥ 때문이다. 대신 피드 뷰의 `trade_result` jsonb 와 게시물 단건 조회의 PostgREST
임베드 별칭이 **같은 여덟 키** 를 만들도록 맞춰, 카드 위젯은 하나다
([스키마 §5](../../schema.md)).

### 세션 id 는 초안에 실린다

`PostUseCase.createPost` 에 인자를 더하지 않고 `PostDraft.tradeSessionId` 로 넘긴다.
use case 가 이미 초안 하나를 받고, 시나리오가 초안을 보존해야 하므로 값이 두 곳에
생기는 것을 피했다. 세션이 붙은 초안은 이미지가 없어도 `create_post_with_images` RPC
로 간다 — `trade_session_id` 는 insert GRANT 에 없어 직접 넣으면 `42501` 이다.

### 공유 버튼은 서버가 준 `user_id` 로 판정

결과 화면은 화면이 받은 요약이 아니라 RPC 상태의 `session.userId` 를 `AuthBloc` 의
사용자와 비교한다. 위조한 요약으로 남의 판에 공유 버튼을 띄울 수 없다. 게스트는
`AuthUnauthenticated` 라 버튼이 없고, `AuthBloc` 이 라우터 위에 있어 `/explore` 에서
들어와도 예외가 없다.

### 유일한 역방향 참조

`PostTile` 과 게시물 작성 화면이 `trade/presentation/widget/trade_result_card.dart` 를
import 한다. [아키텍처 규칙 ⑥](../../architecture.md)에 예외로 적었다.

### 최종 리뷰 (2026-09-09)

브랜치 전체를 다시 봤다. 코드 결함으로 남은 Critical · Important 는 없었고, 검토자가
`psql` 로 세 판의 지표를 독립 재계산해 저장값과 일치함을 확인했다. 지적 중 고친 것:
ja `postTradeAttached` 문구 · en `tradeCardCount` 복수형 · en "Buy & hold" 통일 ·
`_returnColor` 네 곳 중복을 `TradeFormat.returnColor` 로 · `floorQuantity` 의 무한
입력 가드 · y 눈금 라벨 소수 자리 · `select=*` 도 `42501` 임을 스크립트에 추가.
결정으로 남긴 것: 끝난 판은 공유 여부와 무관하게 공개 — 이유와 좁히는 대안은
[계획](plan.md)의 데이터 · 권한 절.

미룬 것(동작에 영향 없음): `start_trade_session` 동시 호출 시 `23505` 원문 노출 ·
수수료율 상수가 세 곳 · 주문 시트의 0/파싱 불가 입력 안내 · 차트 `Semantics` ·
새로고침이 전체 스피너 · 공유 후 피드 미갱신(다음 새로고침에 보인다).

## 2026-09-09 — 후속 4건

에뮬레이터 검증에서 나온 것과 리뷰가 남긴 것을 정리했다.

### 공유한 글이 목록에 바로 보이게 — 생성 이벤트 스트림

작성 화면을 **결과 화면에서** 띄우면 홈 셸 안의 `FeedCubit` 은 새 글을 모른다.
반환값으로 목록에 넣는 기존 경로는 피드 화면이 직접 띄웠을 때만 동작한다.
그래서 `PostUseCase` 가 만들어진 게시물을 broadcast 하고, `FeedUseCase` 가 그
스트림을 그대로 다시 노출한다(presentation 은 자기 feature 의 facade 만 주입받는다 —
규칙 ③). `FeedCubit.watchCreatedPosts(author)` 가 구독해 맨 위에 붙이고,
`prependPost` 를 게시물 id 기준 **멱등** 으로 바꿔 두 경로가 겹쳐도 한 번만 붙는다.
프로필은 내 프로필일 때만 구독하고, 닉네임·아바타를 바꾸면 새 값으로 다시 구독한다.

### 공유하기의 `extra` 는 JSON 호환 Map

go_router 는 `extra` 를 `json.encoder` 로 인코딩하지 못하면 경고를 내고, 프로세스가
복원될 때 값을 버린다. `TradeResultSummary` 를 그대로 넘기는 대신 `toMap()` /
`fromMap()` 을 두고 뷰의 여덟 키와 같은 모양으로 넘긴다. `fromMap` 은 모양이 어긋나면
null 을 돌려주므로, 낡은 `extra` 로 화면이 깨지지 않는다.

### FAB 의 `heroTag`

`feed_page` 와 `chat_room_list_page` 의 `FloatingActionButton.extended` 가 홈 셸의
`IndexedStack` 에 함께 살아 있어 라우트 전환마다 Hero 태그 충돌 단언이 났다(F10 과
무관한 기존 결함). 각각 `feed-compose` · `chat-create` 를 준다.
