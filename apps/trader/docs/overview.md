# daylog — 기획서

> [트레이더 허브](README.md) · [진행 현황](status.md) · [아키텍처](../../../docs/architecture.md) · [개발환경](../../../docs/setup.md) · [테스트 가이드](../../../docs/testing/README.md)

> 상태: **v0.4** · 작성 2026-08-20 · 갱신 2026-09-08
>
> v0.4에서 **제품의 방향을 바꿨다.** 소셜 피드 위에 **과거 시세 기반 모의투자
> 시뮬레이터(F10 trade)** 를 얹고, 그쪽을 주인공으로 세운다. 지금까지 만든 소셜
> 기능은 하나도 버리지 않는다 — 판의 결과를 나누는 자리로 쓴다. 바뀐 절은
> §1 · §2 · §3 · §4.7 · §5 · §6 · §7 · §8 · §9다. F1~F9 절은 그대로 유효하다.
>
> v0.3에서 §3·§5·§6·§8을 **지금 만들어진 것에 맞춰 동기화했다.** 채팅(F9 오픈방 +
> 1:1 DM)과 다국어를 제외 목록에서 범위 안으로 옮기고, F3의 Storage 경로와 넣지 않은
> 항목, 4단계 로드맵을 실제 결정에 맞게 고쳤다.
>
> v0.2에서 §6·§7을 자체 REST 백엔드 전제에서 **Supabase 테이블·RLS 기준으로 다시 썼다.**
> 소프트 삭제 · 커서 페이지네이션 · 테이블 명명 규칙을 확정했다 (§9).

---

## 1. 한 줄 정의

**과거 시세로 매매를 연습하고, 그 결과를 사람들과 나누는 모바일 앱.**

종목과 시점을 가린 과거 차트가 한 봉씩 흐르고, 사용자는 그 위에서 사고판다. 판이
끝나면 수익률 · buy&hold 대비 · 최대낙폭이 나오고, 그 결과를 게시물로 올려 피드에서
이야기한다. 시뮬레이터가 주인공이고, 이미 만들어 둔 소셜 기능(피드 · 팔로우 · 반응 ·
댓글 · 채팅)이 그 결과를 나누는 자리다.

## 2. 목표와 성공 기준

이 프로젝트는 **토이 프로젝트**다. 사용자 수나 성장은 목표가 아니다.

**성공 기준**: 과거 시세를 받아 적재하고, 블라인드 리플레이로 매매하고, 결과를 채점해
피드에 공유하는 흐름을 **직접 만든 백엔드 위에서 끝까지 동작하는 상태로 완성한다.**

이 기준을 명시적으로 못 박는 이유: 앱을 사용자 수로 평가하면 개인 프로젝트는 거의 반드시 실패로 끝난다. 반면 "완성"을 기준으로 하면 달성 가능하고, 배우는 것(API 설계, 인증, 권한, 쿼리, 스토리지, 배포)이 그대로 남는다.

**이미 달성한 성공 기준(v0.3까지)**: 인증 · 피드 · 이미지 업로드 · 소셜 그래프 ·
실시간 채팅을 갖춘 앱을 완성했다. 3단계까지의 결과물은 그 자체로 동작하며, F10은
그 위에 얹는 다음 목표다.

**방향을 바꾼 이유**: 소셜 피드는 완성했지만, 혼자 쓰는 토이 프로젝트에서 "글을 올리고
남의 글을 본다"는 스스로 다시 열어볼 이유가 되지 못했다. 모의투자는 혼자서도 판이
성립하고(내 판단 → 즉시 채점), 그 결과가 남에게 보여줄 만한 콘텐츠가 된다 — 이미
만든 소셜 기능이 그때 비로소 쓸 곳이 생긴다.

부차 목표: **백엔드의 인증·스키마·권한 모델을 직접 설계하고 검증하는 것**. 현재는
로컬 Supabase와 SQL 마이그레이션·RLS를 사용한다. 실제 스키마와 권한의 단일 기준은
[스키마 문서](schema.md)이고, 거기에 도달하는 실행 이력이
[`supabase/migrations/`](../../../supabase/migrations/)다.

## 3. MVP 범위

### 포함

| 영역 | 내용 |
|------|------|
| 인증 | 이메일 + 비밀번호 회원가입 / 로그인 / 로그아웃 / 자동 로그인 |
| 프로필 | 닉네임 · 자기소개 · 프로필 사진, 내 프로필 / 타인 프로필 |
| 게시물 | 텍스트 + 사진 여러 장 작성 · 수정 · 삭제 |
| 피드 | 전체 공개 피드 / 팔로잉 피드 (탭 전환) |
| 반응 | 좋아요 · 싫어요 |
| 댓글 | 댓글 + 대댓글 (**1단까지만**) |
| 소셜 | 팔로우 / 언팔로우 / 맞팔 표시 / 팔로워·팔로잉 목록 |
| 안전 | 신고 · 차단 |
| 채팅 | 공개 오픈방 · 1:1 DM (F9 — 아래 "범위를 넓힌 것") |
| 환경설정 | 화면 테마(시스템·라이트·다크) · 언어(한국어 · 영어 · 일본어) |
| 모의투자 | 과거 일봉 블라인드 리플레이 · 시장가 매매 · 결과 채점 · 결과 공유 (F10) |

### 제외 (v1 범위 밖)

구글 로그인, 이메일 OTP, 푸시 알림, 해시태그·검색, 게시물 공유, 커뮤니티/그룹,
다크모드 외 테마.

> **구글 로그인 · 이메일 OTP는 v1.1에서 재검토.** 아키텍처는 인증 방식이 추가될 수 있게 열어둔다 (§9 참조).

### 범위를 넓힌 것

처음에는 **채팅(1:1 채팅 · DM)과 다국어가 제외 목록에 있었다.** 둘 다 뒤에 범위 안으로
들였고, 위 표가 지금의 결정이다.

- **채팅** — 공개 오픈방을 먼저 만들고(F9), 방 테이블의 `type` 과 참여자 모델을
  처음부터 공용으로 잡아 **DM 을 그 위에 얹었다.** 즉 DM 은 별도 feature 가 아니라
  F9 채팅에 포함한다 ([F9 계획](features/chat/plan.md) ·
  [F9-DM 계획](features/chat/plan-dm.md), §8 참조)
- **다국어** — 시스템 · 한국어 · 영어 · 일본어를 지원한다. 화면 문자열뿐 아니라 폼
  검증 · 앱이 식별하는 오류 · 날짜 표기까지 선택 언어를 따르며, 소유는
  `features/preferences` 다 ([언어 계획](features/preferences/plan-language.md))
- **모의투자(F10)** — v0.4에서 들어왔고, 범위를 넓힌 정도가 아니라 **제품의 주인공을
  바꿨다.** 소셜 기능을 걷어내는 대신 결과를 나누는 자리로 다시 쓴다. 판 결과는
  `posts` 에 첨부 유형 하나가 늘어나는 형태로 붙으므로, 피드 · 반응 · 댓글 · 팔로우는
  손대지 않는다 ([F10 계획](features/trade/plan.md), §6 · §8 참조)

### 범위에 대한 솔직한 평가

이 범위는 엄밀히 말해 "MVP"가 아니라 **작은 인스타그램 + 트레이딩 시뮬레이터**다.
기능 간 결합도가 낮아 단계별로 쪼개면 완주 가능하지만, 한 번에 다 만들려 하면 중간에
멈춘다. §8의 단계 구분을 반드시 지킬 것.

앞부분(F1~F9)은 이미 완주했으므로 지금 지켜야 할 것은 **F10을 5.1~5.4로 쪼갠
순서**다. 특히 시뮬레이터가 혼자 돌아가기 전에 결과 공유부터 만들지 않는다 — 공유할
결과가 없는 공유 화면은 검증할 수 없다.

## 4. 기술 스택

### 4.1 확정

| 영역 | 선택 | 비고 |
|------|------|------|
| 앱 | **Flutter** | |
| 상태관리 | **bloc** | |
| 모델 · 불변객체 | **freezed** + json_serializable | |
| 의존성 주입 | **get_it + injectable** | |
| 로컬 DB | **drift** | 2단계 이후 도입 — §4.2 |
| 토큰 · 비밀 저장 | **flutter_secure_storage** | Supabase 세션 저장소로 연결 — §4.3 |
| 단순 설정 | shared_preferences | 테마, 마지막 탭 등 |
| 이미지 | image_picker + flutter_image_compress | 압축 필수 — §4.5 |
| 코드 생성 | **build_runner** | freezed · injectable · drift 공용 |
| 백엔드 | **Supabase** | 개발은 로컬 Docker — §4.4 |
| DB | PostgreSQL (Supabase) | |
| 스토리지 | Supabase Storage | §4.5 |

### 4.2 로컬 DB는 drift 하나만

Hive와 Isar는 **원 개발자가 유지보수를 중단**한 상태다 (각각 `hive_ce`, `isar_community` 커뮤니티 포크로 명맥 유지). 토이 프로젝트에서 유지보수 리스크를 떠안을 이유가 없다. drift는 활발히 유지보수되고, build_runner 기반이라 코드 생성 파이프라인이 통일되며, Supabase(Postgres)와 같은 SQL 모델이라 인지 부담이 낮다.

**도입 시점은 2단계 이후.** 1단계에서 로컬 DB가 필요한 곳은 "오프라인 피드 캐시"뿐이고, 이는 앱 완성의 필수 조건이 아니다. 역할별로 하나씩만 쓴다:

- 토큰 · 비밀 → `flutter_secure_storage`
- 단순 키-값 설정 → `shared_preferences`
- 구조화된 캐시 → `drift` (2단계~)

### 4.3 Supabase 세션은 secure storage로 옮긴다

`supabase_flutter`는 기본적으로 세션(access/refresh token)을 **SharedPreferences에 평문으로** 저장한다. 토큰은 비밀이므로 `Supabase.initialize`에 커스텀 `LocalStorage` 구현을 넘겨 `flutter_secure_storage`를 쓰게 한다. 0단계에서 처리할 것.

### 4.4 로컬 Docker 개발환경

`supabase init` → `supabase start`로 Postgres · Auth(GoTrue) · Storage · Realtime · Studio가 로컬 컨테이너로 뜬다. 이 선택의 실질적 이득:

- **스키마 변경이 SQL 마이그레이션 파일로 버전 관리된다** (`supabase migration new`). RLS 정책도 SQL로 직접 작성하게 되므로, "백엔드를 배운다"는 부차 목표가 상당 부분 충족된다
- **로컬 메일함이 함께 뜬다** (Inbucket/Mailpit). 회원가입 확인 메일과 **비밀번호 재설정 메일을 SMTP 설정 없이 로컬에서 테스트할 수 있다** → §9 #2 참조
- 인터넷 없이 개발 가능, 무료 프로젝트 일시정지 문제 없음, 데이터 날려도 무해

**주의**: 컨테이너 여러 개가 떠서 **2~4GB RAM**을 쓴다. Docker Desktop을 켜둔 채 작업하게 되므로 발열·배터리를 감안할 것.

### 4.5 이미지: 압축은 타협 불가

Supabase 무료 티어는 스토리지 1GB, 전송량 월 5GB다. 원본 2MB 사진을 그대로 쓰면 금방 소진되지만, **긴 변 1080px · WebP · 품질 80으로 압축하면 약 150KB**가 되어 전송량 5GB로 3만 회 조회를 감당한다. 토이 프로젝트 규모에선 충분하다.

전송량이 실제로 문제가 되면 그때 **Cloudflare R2**(egress 과금 없음)로 옮긴다. 미리 하지 않는다 — 통합 편의(RLS 연동, signed URL)를 잃는 대가가 더 크다.

### 4.6 build_runner 부하

freezed · injectable · drift가 모두 build_runner를 쓴다. 파일이 늘면 전체 빌드가 느려지므로 개발 중에는 watch 모드를 상시 켜둔다:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

### 4.7 시세 데이터는 받아서 넣어둔다 — 런타임에 외부를 부르지 않는다

모의투자의 재료인 과거 일봉은 **Binance 공개 klines API**(키 없음)로 한 번 받아
`supabase/seeds/market_candles.sql` 로 떨어뜨리고, `supabase db reset` 이 마이그레이션
뒤에 적재한다. 앱은 실행 중에 거래소를 부르지 않는다.

이렇게 하는 이유:

- **판이 재현된다.** 같은 종목·같은 시작점이면 언제 돌려도 같은 봉이 나온다. 런타임에
  거래소를 부르면 응답이 달라질 때 채점 결과를 신뢰할 수 없다
- **오프라인·무료다.** 로컬 Supabase만 떠 있으면 되고, 레이트 리밋도 키도 없다
- **숨김이 성립한다.** 원가격과 심볼이 서버에만 있으므로 클라이언트가 볼 길이 없다
  (§6 F10 · [스키마 §16](schema.md))

거래소 선택은 Binance다. 키 없이 요청당 1000봉을 주고, 상장 이후 전 구간이 한 번에
받아지며, 24시간 장이라 **휴장일 · 액면분할 · 배당 보정이 없다** — 시뮬레이터 로직에서
예외 처리가 통째로 사라진다. 국내에서 `api.binance.com` 이 막히면 시장 데이터 전용
미러 `data-api.binance.vision` 이 같은 스키마로 열려 있다.

갱신은 월 1회 수동이다. 자동화하지 않는다 ([개발환경 §4](setup.md)).

## 5. Feature 분해

| # | Feature | 역할 | 단계 |
|---|---------|------|------|
| F1 | **auth** | 회원가입 · 로그인 · 토큰 · 세션 유지 | 1 |
| F2 | **profile** | 프로필 조회 · 수정 · 프로필 사진 | 1 |
| F3 | **post** | 게시물 작성 · 수정 · 삭제 · 상세 | 1 |
| F4 | **feed** | 전체 피드 · 팔로잉 피드 · 페이지네이션 | 1 / 3 |
| F5 | **reaction** | 좋아요 · 싫어요 | 2 |
| F6 | **comment** | 댓글 · 대댓글 1단 | 2 |
| F7 | **safety** | 신고 · 차단 | 2 |
| F8 | **follow** | 팔로우 · 맞팔 · 목록 | 3 |
| F9 | **chat** | 공개 오픈방 · 1:1 DM · 실시간 전달 | 3.5 / 3.6 |
| F10 | **trade** | 시세 적재 · 블라인드 리플레이 · 매매 · 채점 · 결과 공유 | 5 |

### 교차 관심사 (특정 feature 소유 아님)

| # | 이름 | 역할 |
|---|------|------|
| X1 | **app shell** | 라우팅 · 탭 네비게이션 · DI 조립 · 인증 게이트 · 스플래시 |
| X2 | **backend client** | Supabase 클라이언트 구성 · 세션 저장소 · 에러 → `Failure` 매핑 |
| X3 | **media** | 이미지 선택 · 압축 · Storage 업로드 |
| X4 | **design system** | 테마 · 색상 토큰 · 공통 위젯 (버튼, 아바타, 빈 상태, 에러 상태) |

F3와 F4는 데이터가 같은 테이블(`posts`)을 쓰지만 앱 코드에서는 분리한다.
`features/post`가 게시물 CRUD와 게시물 카드 위젯을, `features/feed`가 목록 조회와
탭·무한 스크롤을 소유한다. feed는 post의 `domain` 계층만 참조한다.

**F10은 소셜 쪽을 참조하지 않는다.** 판 · 주문 · 채점은 `features/trade` 안에서
끝나고, 결과를 게시물로 올리는 지점에서만 F3의 `domain` 을 부른다. 반대 방향(피드가
trade 를 참조)은 결과 카드 위젯 하나로 제한한다 — 이 경계를 지켜야 시뮬레이터를
소셜과 무관하게 테스트할 수 있다.

---

## 6. Feature별 개발 항목

각 항목은 **앱**과 **데이터·권한**으로 나눠 적는다. 백엔드는 별도 서버가 아니라
**Supabase의 테이블 · RLS 정책 · Storage 버킷 · 필요할 때의 Postgres 함수**다. 앱은
`supabase_flutter` SDK로 직접 접근하며, **권한 판단은 전부 DB의 RLS가 한다.** 앱이
보내는 조건은 UX일 뿐 보안 경계가 아니다.

이 문서는 **의도**를 적는다. 실제 테이블·정책·권한의 단일 기준은
[스키마 문서](schema.md)다. feature별 상세 설계는 `docs/features/<name>/plan.md`에서
확정한다.

아래에는 처음 범위(F1~F8)만 적는다. 뒤에 들어온 **F9 채팅(오픈방 · DM)** 의 의도와
데이터·권한은 [F9 계획](features/chat/plan.md) · [F9-DM 계획](features/chat/plan-dm.md)
과 [스키마 §14](schema.md)가 기준이다.

> 자체 백엔드로 전환할 때 쓸 REST 시그니처 초안은 §9 「자체 백엔드 전환 메모」에 남겨뒀다.

### 공통 규칙

- **삭제는 전부 소프트 삭제**다. `deleted_at`을 채우고, **조회 정책(RLS)에
  `deleted_at is null`을 넣어 DB가 강제한다.** 앱 쿼리마다 필터를 붙이는 방식은
  언젠가 빠뜨린다. `delete` 권한은 GRANT하지 않는다
- **목록은 전부 커서 페이지네이션**이다. `(created_at desc, id desc)` 복합 커서를 쓴다.
  `range`/`OFFSET`은 스크롤 중 새 글이 올라오면 항목이 중복되거나 건너뛰어진다
- 소프트 삭제 대상 테이블의 커서 인덱스는 `where deleted_at is null` **부분 인덱스**로 만든다
- 조회 정책이 삭제행을 가리므로, 소프트 삭제 UPDATE에 `.select()`를 붙이면 RETURNING이
  정책에 걸려 빈 결과가 된다. 삭제 API는 값을 반환하지 않는다

---

### F1. auth — 인증

**사용자 스토리**
- 이메일과 비밀번호로 가입하고, 가입 시 닉네임을 정한다
- 로그인하면 앱을 껐다 켜도 로그인 상태가 유지된다
- 로그아웃하면 저장된 세션이 지워진다

**데이터·권한**
- 계정(이메일 · 비밀번호 해시 · 세션 · refresh 토큰)은 **Supabase Auth(GoTrue)가
  `auth.users`에서 관리한다.** 비밀번호 해싱 · JWT 발급 · refresh 회전은 GoTrue의
  몫이므로 우리가 만들지 않는다. `users` · `refresh_tokens` 테이블을 직접 두지 않는 이유다
- 가입 시 `auth.users`에 트리거 `on_auth_user_created`(security definer)가 붙어
  `public.profiles` 행을 같은 트랜잭션에서 생성한다. 닉네임은 `signUp`의
  `raw_user_meta_data`로 전달한다
- 비밀번호 재설정은 **메일 링크가 아니라 6자리 코드**를 보낸다
  (`supabase/templates/recovery.html` + `config.toml`의 recovery 템플릿).
  앱이 `verifyOTP(type: recovery)`로 검증하므로 **딥링크 설정이 통째로 필요 없다**

**앱 개발**
- 로그인 / 회원가입 화면, 입력 검증 (이메일 형식, 비밀번호 최소 길이, 닉네임 길이)
- 세션 저장소를 `flutter_secure_storage`로 교체 (SDK 기본값인 SharedPreferences 금지 — §4.3)
- 앱 시작 시 저장된 세션 복구 → 라우터의 인증 게이트에서 분기
- **토큰 첨부와 401 재시도는 SDK가 처리한다.** dio 인터셉터를 직접 만들지 않는다
- `AuthRepository` 인터페이스로 격리 (v1.1의 구글 로그인 · OTP 대비)

**주의**
- 로그인 실패 시 "이메일이 없음"과 "비밀번호 틀림"을 **구분하지 않는다** (계정 존재 여부 노출 방지)
- 트리거가 같은 트랜잭션에서 돌기 때문에 **닉네임 제약 위반이 가입 전체를 롤백시킨다.**
  `23514`(check_violation) · `23505`(unique_violation)를 사용자 문구로 매핑한다
- `enable_confirmations`는 꺼져 있다. 가입 즉시 세션이 발급된다. 운영 전 재검토
- 배포용 SMTP는 미연결 상태다. 로컬은 Mailpit으로 동작한다

---

### F2. profile — 프로필

**사용자 스토리**
- 내 닉네임 · 자기소개 · 프로필 사진을 수정한다
- 다른 사람의 프로필과 그 사람이 쓴 글 목록을 본다

**데이터·권한**
- `profiles` — `id`(PK, `auth.users` FK, on delete cascade), `nickname`, `bio`,
  `avatar_url`, `created_at`, `updated_at`
- 닉네임은 **DB 유니크 제약 + `lower(nickname)` 유니크 인덱스**로 강제한다
  (대소문자만 다른 중복 차단). 길이 CHECK 2~20자, bio 200자
- RLS — 조회는 전체 공개, 수정은 본인만. INSERT 정책은 두지 않는다 (트리거 전담)
- GRANT는 **컬럼 단위**로 준다: `grant update (nickname, bio, avatar_url)`.
  `id` · `created_at`은 클라이언트가 건드릴 수 없다
- 아바타는 Storage 버킷 `avatars`. 경로는 `{user_id}/...`로 두고 **본인 경로만 쓰기
  가능하도록 Storage RLS를 건다**
- 게시물 수 · (3단계) 팔로워 · 팔로잉 수 · `isFollowing`은 매번 클라이언트가 여러 번
  조회하지 않도록 **뷰 또는 RPC 함수 하나로 묶어 내려준다**

**앱 개발**
- 내 프로필 화면 / 타인 프로필 화면 (같은 위젯, 소유 여부로 분기)
- 프로필 편집 화면, 닉네임 중복 확인(디바운스)
- 프로필 사진 선택 → 압축 → 업로드 (X3 재사용)
- 프로필 내 게시물 목록 (커서 페이지네이션)

**주의**
- 앱의 닉네임 중복 확인은 UX일 뿐 경쟁 조건을 막지 못한다. 최종 판정은 DB 제약이다

---

### F3. post — 게시물

**사용자 스토리**
- 글과 사진 여러 장을 함께 올린다. 사진 순서는 내가 정한 대로 유지된다
- 내 글을 수정하거나 삭제한다

**데이터·권한**
- `posts` — `id`, `author_id`, `content`, `created_at`, `updated_at`, `deleted_at`
- `author_id`는 **`default auth.uid()`로 DB가 채운다.** 앱이 보내지 않으므로 위조할 수 없다.
  INSERT 정책의 `with check ((select auth.uid()) = author_id)`가 이중으로 막는다
- `content` CHECK **1~500자** (공백 trim 기준)
- `post_images` — `id`, `post_id`(FK), `url`, `width`, `height`, `sort_order`.
  게시물당 **최대 5장**
- RLS — 조회 `deleted_at is null`, 작성/수정/삭제는 작성자 본인만.
  `delete` 권한은 GRANT하지 않고 `deleted_at` UPDATE로만 삭제한다
- Storage 버킷 `post-images`, 경로 `{user_id}/{uuid}/{순서}.{webp|jpg}`.
  가운데 조각은 **게시물 id가 아니라 클라이언트가 만든 UUID**다 — 업로드가 게시물
  생성보다 먼저라 그 시점에는 게시물 id가 없다. Storage RLS와
  `create_post_with_images()` 는 **첫 조각이 로그인 사용자와 같은지**로 판정한다
  ([스키마](schema.md) · [F3 계획](features/post/plan.md))

**앱 개발**
- 작성 화면: 텍스트 입력 + 이미지 다중 선택 + 개별 삭제 (선택한 순서가 표시 순서다)
- 이미지 종횡비 처리 — **`width`/`height`를 저장하므로 앱은 로딩 전에 자리를 확보할 수
  있다** (레이아웃 점프 방지)

**범위 밖 / 후속**

아래 셋은 처음 적어 뒀지만 **넣지 않았다.** 없어도 "글과 사진을 올린다"가 성립했고,
빠진 자리는 다른 것이 메웠다.

- **이미지 순서 변경(드래그)** — 선택한 순서를 그대로 `sort_order` 로 저장하고 피드
  카드가 그 순서로 보여준다. 재정렬은 기존 첨부를 편집하는 화면이 생길 때 함께 온다
- **업로드 진행률 · 실패 시 재시도** — 저장 중에는 버튼을 잠그고 실패는 오류 문구로
  알리는 것으로 갈음했다. 사진 다섯 장이 압축 뒤 150KB 남짓(§4.5)이라 진행률을 볼
  만큼 길지 않다
- **게시물 상세 화면 · 이미지 캐러셀** — 상세 화면 자체를 만들지 않았다. 댓글은
  전용 화면으로 열고 이미지는 피드 카드에서 본다. 캐러셀은 상세 화면과 함께 온다
  ([F3 기록](features/post/history.md))

**주의**
- 업로드는 성공했는데 게시물 생성이 실패하면 **고아 이미지**가 남는다. MVP에서는 방치하고
  나중에 정리 작업으로 처리한다 (완벽한 트랜잭션은 과설계)
- 앱 코드에서 **게시물 CRUD는 `features/post`, 목록 조회는 `features/feed`가 소유한다.**
  게시물 카드 위젯은 `features/post/presentation/widget/`에 둔다

---

### F4. feed — 피드

**사용자 스토리**
- 앱을 열면 최신 글이 시간순으로 보인다
- 탭을 바꿔 팔로우한 사람들의 글만 본다
- 아래로 내리면 계속 불러오고, 당겨서 새로고침한다

**데이터·권한**
- 전체 피드 — `posts`를 `created_at desc, id desc` 정렬, `deleted_at is null`
- 커서 조건은 `created_at < c.created_at or (created_at = c.created_at and id < c.id)`.
  앱은 커서를 **불투명 문자열**로만 다루고 해석은 data 계층에서 끝낸다
- 팔로잉 피드 — `follows` 조인으로 팔로우 대상만 (3단계)
- 반응 수 · 댓글 수 · **내 반응 상태**는 게시물마다 따로 조회하지 않는다.
  **뷰 또는 RPC 함수로 한 번에 내려준다** (N+1 방지)
- 차단한 사용자의 게시물 제외 (F7 완료 후) — **차단 필터는 공통 뷰/함수 안에 넣어
  쿼리마다 다시 쓰지 않게 한다**

**앱 개발**
- 탭 2개 (전체 / 팔로잉)
- 무한 스크롤 + 당겨서 새로고침
- 빈 상태 / 로딩 / 에러 상태 UI

---

### F5. reaction — 감정표현

**사용자 스토리**
- 게시물에 좋아요 또는 싫어요를 누른다. 다시 누르면 취소된다
- 좋아요를 누른 상태에서 싫어요를 누르면 좋아요가 해제된다

**데이터·권한**
- `post_reactions` — `user_id`, `post_id`, `type`(`like` | `dislike`), `created_at`.
  **PK `(user_id, post_id)`** — 한 사용자는 게시물당 반응 하나
- 좋아요 ↔ 싫어요 전환은 **upsert 하나로 처리한다** (삭제 후 삽입이 아니다)
- RLS — 조회 전체 공개, 삽입·수정·삭제는 `user_id`가 본인일 때만.
  `user_id`는 `default auth.uid()`
- 반응은 소프트 삭제하지 않는다. 취소는 행 삭제다 (참조하는 자식이 없다)

**앱 개발**
- 좋아요 / 싫어요 버튼, 선택 상태 표시
- **낙관적 업데이트** — 탭 즉시 UI 반영, 실패 시 롤백

**주의 — 카운트 집계 방식**

- **(a) 실시간 `COUNT(*)` + 인덱스** — 단순, 정확. **MVP는 이걸로 시작한다**
- **(b) `posts.like_count` 비정규화 컬럼 + 트리거** — 빠르지만 정합성 관리 필요

성능 문제가 실제로 관측되기 전에 (b)로 가지 않는다. YAGNI.

**싫어요 정책 (확정: 공개)**

좋아요와 동일하게 **개수를 공개한다.** 다수가 특정 글에 몰릴 때 괴롭힘 수단이 될 수
있다는 위험은 인지한 상태의 선택이다.

다만 운영 중 문제가 관측되면 **백엔드 변경 없이 되돌릴 수 있게** 만든다:
- 조회 응답은 `dislikeCount`를 **항상** 포함한다
- **노출 여부는 앱이 판단한다** (원격 설정 또는 앱 업데이트로 전환)

---

### F6. comment — 댓글

**사용자 스토리**
- 게시물에 댓글을 단다
- 댓글에 답글을 단다 (답글의 답글은 없다)
- 내 댓글을 삭제한다

**데이터·권한**
- `post_comments` — `id`, `post_id`(FK), `author_id`, `parent_id`(FK, self, nullable),
  `content`, `created_at`, `deleted_at`
- **DB는 무한 depth를 담을 수 있게 두고, 1단 제한은 앱과 정책에서만 건다.** 나중에
  다단계로 바꾸고 싶어져도 마이그레이션이 필요 없다
- `parent_id`가 이미 자식 댓글이면 거부한다 — CHECK로는 표현할 수 없으므로
  **트리거 또는 삽입용 RPC 함수**로 막는다 (앱 검증만으로는 우회된다)
- 소프트 삭제. **자식이 있으면 목록에는 남기고 "삭제된 댓글입니다"로 표시한다** —
  조회 정책에서 삭제행을 완전히 가리면 자식이 고아가 되므로, 댓글 조회는
  `deleted_at is null or 자식이 있음` 조건을 쓰는 **전용 뷰**로 내려준다
- 대댓글은 **부모 댓글 기준으로 오래된 순 정렬** (전체 최신순이면 대화 흐름이 깨진다)

**앱 개발**
- 댓글 목록 (부모 아래 자식 들여쓰기), 커서 페이지네이션
- 입력창, 답글 모드 표시 ("○○님에게 답글")
- 댓글 수 표시

---

### F7. safety — 신고 · 차단

> **이 feature는 선택이 아니다.** Apple App Store 심사 가이드라인 1.2는 사용자 생성
> 콘텐츠 앱에 신고 기능 · 차단 기능 · 신고 대응을 요구한다. 없으면 리젝된다. Google Play도 동일.

**사용자 스토리**
- 부적절한 게시물이나 댓글을 신고한다
- 특정 사용자를 차단하면 그 사람의 글과 댓글이 더 이상 보이지 않는다
- 차단 목록에서 차단을 해제한다

**데이터·권한**
- `reports` — `id`, `reporter_id`, `target_type`(`post` | `comment` | `user`),
  `target_id`, `reason`, `status`, `created_at`.
  **여기만 폴리모픽이다** — 신고는 처음부터 세 종류를 다 받으므로 FK를 포기할 이유가 있다
- `blocks` — `blocker_id`, `blocked_id`, `created_at`, PK `(blocker_id, blocked_id)`
- RLS — 신고는 삽입만 허용하고 **조회는 본인 것만**. 차단 목록도 본인 것만
- 차단은 **양방향 숨김**: 내가 차단하면 상대도 내 글을 못 본다
- **모든 조회 경로에 차단 필터가 걸려야 한다** (피드 · 댓글 · 프로필). 쿼리마다 붙이면
  언젠가 빠뜨리므로 **공통 뷰 또는 RPC 함수 안에 넣어 강제한다**

**앱 개발**
- 게시물 · 댓글 · 프로필의 더보기 메뉴 → 신고 / 차단
- 신고 사유 선택 시트
- 설정 화면의 차단 목록 관리

**주의**
- MVP에서 신고 처리 운영은 **Studio에서 DB 직접 조회**로 한다. 관리자 화면은 과설계

---

### F8. follow — 팔로우

**사용자 스토리**
- 다른 사용자를 팔로우하고 해제한다
- 내 팔로워 / 팔로잉 목록을 본다
- 서로 팔로우 중이면 "맞팔로우"로 표시된다

**데이터·권한**
- `follows` — `follower_id`, `followee_id`, `created_at`, PK `(follower_id, followee_id)`
- `follower_id`는 `default auth.uid()`, INSERT 정책으로 본인만 삽입 가능
- **자기 자신 팔로우는 CHECK 제약으로 거부한다** (`follower_id <> followee_id`)
- 프로필 조회 응답에 `isFollowing` · `isFollowedBy`를 포함해 맞팔을 판정한다
- 팔로우 해제는 행 삭제다 (소프트 삭제하지 않는다)

**앱 개발**
- 팔로우 버튼 (상태 3가지: 팔로우 / 팔로잉 / 맞팔로우), 낙관적 업데이트
- 팔로워 · 팔로잉 목록 화면 (커서 페이지네이션)
- 완료 후 F4의 팔로잉 피드 활성화

### F10. trade — 모의투자

v0.4에서 들어온 이 앱의 주인공이다. 아래는 **확정된 것만** 적는다. 스키마 세부와
화면 구성은 설계 중이며, 확정되는 대로 [F10 계획](features/trade/plan.md)이 단일
기준이 된다.

**사용자 스토리**
- "시작"을 누르면 종목과 시점을 알 수 없는 과거 차트가 나온다
- 한 봉씩 넘기며 사고팔고, 남은 봉이 없으면 판이 끝난다
- 결과(수익률 · buy&hold 대비 · 최대낙폭 · 매매 횟수)와 **가려져 있던 종목·기간**을 본다
- 결과를 게시물로 올려 피드에서 이야기한다

**확정된 규칙**

| 항목 | 값 |
|---|---|
| 시장 | 코인만 (Binance USDT 페어 20종목). 주식은 범위 밖 |
| 봉 단위 | 일봉 |
| 한 판 | 워밍업 60봉(보기만) + 진행 60봉(매매 가능) |
| 종목·시작점 | **앱이 무작위로 고른다.** 사용자가 지정할 수 없다 |
| 가격 표시 | 시작점을 100으로 정규화. 원가격을 보여주지 않는다 |
| 초기 자금 | 10,000 (정규화 가격이므로 단위 없음) |
| 주문 | 시장가만 · 현재 봉 종가 체결 · 롱만(공매도 없음) · 수수료 0.1% |
| 진행 | "다음 날" 버튼으로 수동 진행 (자동 재생은 후속) |
| 종료 | 60봉 소진 또는 "청산하고 끝내기" |
| 결과 공개 | 판이 끝난 뒤에만 종목·기간을 공개한다 |

**블라인드가 이 기능의 핵심이다**

"투자감각을 키운다"는 목적은 사용자가 **미래를 모를 때만** 성립한다. 종목과 날짜가
보이면 "2021년 11월 BTC"라는 기억으로 점수를 만들 수 있고, 그 점수는 판단력이 아니라
암기력을 잰다. 그래서 숨김을 화면에서 가리는 수준으로 두지 않고 **권한으로 강제한다** —
`market_candles` 는 `anon` · `authenticated` 에 GRANT가 없고, 판을 시작하는
`security definer` RPC 만 정규화한 값을 내려준다 ([스키마 §16](schema.md)).
클라이언트에는 심볼을 내려보낼 경로 자체가 없다.

같은 이유로 종목·시작점 선택을 사용자에게 주지 않는다. 고를 수 있으면 아는 구간을
고르게 된다.

**데이터·권한** — 확정된 것

- `market_candles` — Binance 일봉 원시 시세. `(symbol, day)` PK, 클라이언트 GRANT 없음
  ([스키마 §16](schema.md))
- 판과 주문은 서버에 남긴다. 기기를 바꿔도 기록이 유지되고, 결과 카드가 서버 데이터로
  검증되기 때문이다
- 결과 공유는 **`posts` 에 첨부 유형이 하나 느는 형태**다. 별도 게시물 테이블을 만들지
  않는다 — 피드 · 반응 · 댓글 · 신고 · 차단이 그대로 적용되어야 한다

**확정한 곳**

판 · 주문 테이블의 모양, RPC 시그니처, 화면 구성과 상태 모델, 손익 계산의 위치(DB 가
정본)는 [F10 계획](features/trade/plan.md)이 단일 기준이다. 스키마는
[스키마 §17](schema.md).

**범위 밖**

실시간 시세 · 주식 · 공매도 · 지정가/스탑 주문 · 레버리지 · 리더보드 · 여러 종목
동시 보유. 리더보드는 판이 쌓인 뒤에 다시 본다.

---

## 7. 데이터 모델

계정 정보는 Supabase Auth가 소유하므로 우리가 만드는 것은 `public` 스키마의 아래
테이블뿐이다.

```
auth.users       (Supabase Auth 소유 — 이메일 · 비밀번호 해시 · 세션 · refresh 토큰)

profiles         id(PK, FK auth.users), nickname(unique), bio, avatar_url,
                 created_at, updated_at
posts            id, author_id(FK profiles), content, created_at, updated_at, deleted_at
post_images      id, post_id(FK), url, width, height, sort_order
post_reactions   user_id(FK), post_id(FK), type(like|dislike), created_at
                 PK(user_id, post_id)
post_comments    id, post_id(FK), author_id(FK), parent_id(FK, self, null),
                 content, created_at, deleted_at
follows          follower_id(FK), followee_id(FK), created_at
                 PK(follower_id, followee_id)
blocks           blocker_id(FK), blocked_id(FK), created_at
                 PK(blocker_id, blocked_id)
reports          id, reporter_id(FK), target_type, target_id, reason,
                 status, created_at
```

채팅(`chat_rooms` · `chat_participants` · `chat_messages`)은 이 표를 쓸 때 범위 밖이던
F9 에서 뒤에 더해졌다. 모양은 [스키마 §14](schema.md)를 본다.

모의투자(F10)의 `market_candles` 도 이 표에 없다 — 사용자 데이터와 FK 관계가 없는
독립 시세 테이블이라 관계도에 넣지 않는다. 모양과 **GRANT를 주지 않는 이유**는
[스키마 §16](schema.md)에 있다. 판·주문 테이블은 아직 없다(5.2단계).

### 명명 규칙

**자식 테이블은 `부모테이블단수_자식` 으로 짓는다** — `post_images`, `post_reactions`,
`post_comments`. 이렇게 하면 `comments` 같은 일반 명사가 전역 이름을 선점하지 않으므로,
나중에 다른 엔티티에 댓글이 붙어도 `photo_comments`를 **추가**하면 끝이다. 기존 테이블은
손대지 않는다.

`feed_`처럼 화면 이름을 접두사로 쓰지 않는다. 같은 게시물이 피드 · 프로필 · 상세 화면에
모두 나타나므로 엔티티 이름이 특정 화면에 묶이면 안 된다.

폴리모픽(`target_type` + `target_id`)은 `reports`에만 쓴다. FK와 RLS를 포기하는 대가가
있으므로, 두 번째 부모가 실제로 생기기 전에는 도입하지 않는다.

### 필수 인덱스

- `posts(created_at desc, id desc) where deleted_at is null` — 전체 피드 커서
- `posts(author_id, created_at desc, id desc) where deleted_at is null` — 프로필 게시물
- `post_comments(post_id, parent_id, created_at)` — 댓글 조회
- `post_reactions(post_id, type)` — 반응 집계
- `follows(follower_id)` / `follows(followee_id)` — 양방향 조회

### 설계 원칙

- **삭제는 전부 소프트 삭제**이고, 조회 정책(RLS)이 `deleted_at is null`을 강제한다.
  단, 자식이 달릴 수 있는 `post_comments`는 전용 뷰로 예외를 만든다 (F6)
- 소유자 컬럼(`author_id` · `user_id` · `follower_id`)은 **`default auth.uid()`**로
  DB가 채운다. 앱이 보내지 않으므로 위조 경로가 없다
- GRANT는 **컬럼 단위**로 최소한만 준다. RLS(어떤 행)와 GRANT(어떤 테이블·컬럼)는
  별개이며 **둘 다 있어야 한다**
- 비밀번호는 Supabase Auth가 해시로만 보관한다. 우리 테이블에는 어떤 형태로도 두지 않는다
---

## 8. 개발 단계

각 단계가 끝날 때마다 **실제로 동작하는 앱**이 나온다. 중간에 멈춰도 손에 뭔가 남는다.

| 단계 | 범위 | 완료 시점의 상태 |
|------|------|-----------------|
| **0** | Flutter 프로젝트 · Supabase 로컬 Docker · 첫 SQL 마이그레이션 · X2 api client · X4 design system · 배포 파이프라인 | 로컬 Supabase와 앱이 왕복 통신 |
| **1** | F1 auth · F2 profile · F3 post · F4 전체 피드 (+ X1, X3) | **앱이 실제로 돌아간다.** 가입하고 글 쓰고 남의 글을 본다 |
| **2** | F5 reaction · F6 comment · **F7 safety** | **스토어 배포 가능한 상태** |
| **3** | F8 follow · F4 팔로잉 피드 | **소셜앱 완성** — MVP 종료 |
| **3.5** | F9 chat — 공개 오픈방 (개설 · 탐색 · 실시간 · 안읽음) | 앱 안에서 실시간 대화가 된다 |
| **3.6** | F9-DM — 1:1 DM (`type='direct'`) | 프로필에서 바로 1:1 대화를 건다 |
| **4** | (v1.1) 비밀번호 재설정 SMTP · 구글 로그인 · 이메일 OTP · 푸시 알림 | 확장 |
| **5.1** | F10 — 일봉 수집 스크립트 · `market_candles` · seed 적재 | `supabase db reset` 하나로 20종목 시세가 올라온다 |
| **5.2** | F10 — 판 · 주문 테이블 · 판 시작/채점 RPC · RLS | 심볼을 숨긴 채 판을 만들고 채점하는 것이 DB에서 검증된다 |
| **5.3** | F10 — 시뮬레이터 화면 (차트 · 다음 봉 · 매매 · 결과) | **혼자서 판을 끝까지 돌릴 수 있다** |
| **5.4** | F10 — 결과 카드 게시물 · 피드 표시 | 판 결과를 피드에 올리고 반응·댓글이 붙는다 |

> **채팅은 이 표보다 먼저 들어왔다.** 4단계의 "채팅"은 원래 1:1 DM 한 줄이었는데,
> 그 자리를 **공개 오픈방(F9)** 이 먼저 채웠다(3.5단계) — 방 테이블의 `type` 과
> 참여자 모델을 처음부터 공용으로 잡아 둔 덕에, DM 은 그 위에 마이그레이션 하나와
> 화면 몇 개로 붙었다(3.6단계). 그래서 **DM 은 4단계에 남아 있지 않다 — 별도 feature
> 가 아니라 F9 채팅에 포함한다.** 근거와 범위는 [F9 계획](features/chat/plan.md) ·
> [F9-DM 계획](features/chat/plan-dm.md), 지금 어디까지 왔는지는
> [진행 현황](status.md)이 기준이다.

> **5단계는 4단계를 기다리지 않는다.** 4단계(v1.1 확장)는 계속 대기 상태이고,
> v0.4의 방향 전환에 따라 **F10이 먼저 간다.** 4단계 항목은 없어도 앱이 성립하지만,
> F10은 지금 이 앱이 무엇인가를 정하는 기능이다.

**0단계를 건너뛰지 말 것.** 배포 파이프라인을 마지막에 만들면 "내 컴퓨터에선 되는데" 상태로 몇 주를 보내게 된다.

**5단계는 5.1 → 5.4 순서를 지킬 것.** 각 단계 끝에서 손에 남는 것이 있다: 5.1이면
데이터, 5.2면 검증 가능한 권한 경계, 5.3이면 **혼자 놀 수 있는 완성된 게임**, 5.4면
공유다. 5.3까지만 해도 제품으로서 성립하므로, 공유를 먼저 만들려는 유혹을 피한다.

---

## 9. 확정 사항

| 항목 | 값 |
|------|-----|
| 앱 이름 | **daylog** |
| org | **karma** → 패키지 ID `com.karma.daylog` |
| 프로젝트 위치 | `~/Desktop/socialapp` |
| 싫어요 | **개수 공개** (전환 가능하게 설계 — F5) |
| 이미지 | 게시물당 **최대 5장** |
| 본문 | 최대 **500자** (DB CHECK 기준) |
| 백엔드 | **Supabase** (개발은 로컬 Docker). 앱이 SDK로 직접 접근, 권한은 RLS |
| 로컬 DB | **drift**, 2단계 이후 도입 |
| 비밀번호 재설정 | 기능은 MVP에 포함, **배포용 SMTP 연결만 배포 시점으로 연기** |
| 삭제 | **전부 소프트 삭제** (`deleted_at`), 조회 RLS가 강제 |
| 목록 | **전부 커서 페이지네이션** (`created_at desc, id desc`) |
| 테이블 명명 | 자식 테이블은 `부모테이블단수_자식` (`post_comments`). 화면 이름 접두사 금지 |
| 시세 시장 | **코인만** (Binance USDT 페어 20종목, 일봉). 주식은 범위 밖 |
| 시세 조달 | 받아서 seed로 적재. **런타임에 거래소를 부르지 않는다** (§4.7) |
| 판 구성 | 워밍업 60봉 + 진행 60봉, 초기 자금 10,000, 시장가·롱만, 수수료 0.1% |
| 종목 숨김 | 앱이 무작위 선택 · 시작점 100 정규화 · **GRANT 없음으로 강제** (§6 F10) |
| 결과 공유 | `posts` 의 첨부 유형으로 붙인다. 별도 게시물 테이블을 만들지 않는다 |

프로젝트 생성 명령:

```bash
flutter create --org com.karma --project-name daylog .
```

### 남은 판단

- **F10의 스키마·화면 설계** — 판·주문 테이블, RPC 시그니처, 손익 계산 위치(앱 vs DB),
  화면 구성. 설계 중이며 [F10 계획](features/trade/plan.md)에서 확정한다
- **차트 렌더링 방법** — 캔들 차트를 패키지로 그릴지 `CustomPainter` 로 직접 그릴지.
  5.3에서 정한다
- **자체 백엔드 전환 시점** — MVP(3단계) 완주 후 검토. 그때를 대비해 각 Repository를
  인터페이스로 격리하고, Supabase SDK 타입이 `data/` 밖으로 나가지 않게 막는다
  ([아키텍처](../../../docs/architecture.md) 규칙 ①)
- **아이콘 · 스플래시** — 0단계 이후 아무 때나
- **원격 Supabase 프로젝트 · 배포 파이프라인** — 현재 전부 로컬 Docker 기준이다
- **iOS 검증** — Xcode 미설치 상태 ([개발환경](../../../docs/setup.md) §2)

### 자체 백엔드 전환 메모

초기 기획서는 백엔드를 직접 만드는 전제로 REST 시그니처를 적어뒀다. 지금은 Supabase를
쓰므로 §6은 테이블·RLS 기준으로 다시 썼고, 그때의 시그니처 초안만 여기 남긴다.
**현재 앱에는 이런 엔드포인트가 없다.** 전환 시점에 출발점으로만 쓴다.

```text
auth      POST /auth/signup · /auth/login · /auth/refresh · /auth/logout · GET /me
profile   GET /users/:id · PATCH /me/profile · GET /users/check-nickname
          GET /users/:id/posts?cursor=
post      POST /uploads/presign · POST /posts · GET /posts/:id
          PATCH /posts/:id · DELETE /posts/:id
feed      GET /feed/public?cursor=&limit= · GET /feed/following?cursor=&limit=
reaction  PUT /posts/:id/reaction · DELETE /posts/:id/reaction
comment   POST /posts/:id/comments · GET /posts/:id/comments?cursor=
          DELETE /comments/:id
safety    POST /reports · PUT|DELETE /users/:id/block · GET /me/blocks
follow    PUT|DELETE /users/:id/follow
          GET /users/:id/followers?cursor= · GET /users/:id/followings?cursor=
```

전환할 때 Supabase가 대신 해주던 것들을 직접 만들어야 한다: 비밀번호 해싱(bcrypt 또는
argon2), JWT 발급·검증 미들웨어, refresh 토큰 회전과 무효화(`refresh_tokens` 테이블),
그리고 **RLS로 표현하던 권한 규칙 전부를 애플리케이션 코드로 옮기는 일**. 마지막 항목이
가장 크고, 빠뜨리기도 가장 쉽다.

## 10. 진행 현황과 다음 할 일

이 문서에는 진행 상태를 적지 않는다. 단계별 체크리스트와 다음 할 일은
**[진행 현황](status.md)이 단일 기준**이다.

feature마다 화면·상태·완료 조건은 `docs/features/<name>/plan.md`에 착수 전에 쓰고,
구현 기록은 같은 폴더의 `history.md`에, 테스트 범위와 실행 방법은
`docs/testing/features/<name>.md`에 남긴다.
