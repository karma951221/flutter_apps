# 로컬 개발환경 — 트레이더

> [트레이더 허브](README.md) · [공통 개발환경](../../../docs/setup.md) · [스키마](schema.md) · [E2E](e2e.md)

> 0단계에서 실제로 구축·검증한 내용. 도구 버전 · 앱 실행 · iOS 는 [공통 개발환경](../../../docs/setup.md)에 있고,
> 이 문서는 트레이더에만 필요한 백엔드 절차를 다룬다.

## 1. 백엔드 기동

```bash
cd ~/Desktop/socialapp
supabase start
```

첫 실행은 Docker 이미지를 수 GB 받으므로 오래 걸린다. 기동 후 접속 정보:

| 서비스 | 주소 |
|--------|------|
| API | http://127.0.0.1:54321 |
| DB | postgresql://postgres:postgres@127.0.0.1:54322/postgres |
| Studio | http://127.0.0.1:54323 |
| **Mailpit (메일함)** | http://127.0.0.1:54324 |

Mailpit에서 회원가입 확인 메일과 비밀번호 재설정 메일을 볼 수 있다. **SMTP 설정 없이 메일 플로우 전체를 개발·테스트할 수 있다.**

앱 단위 테스트와 코드 컨벤션 검사는 [테스트 가이드](../../../docs/testing/README.md)를 따른다.

## 2. 스키마 변경

Studio UI에서 테이블을 직접 만들지 않는다. 반드시 마이그레이션으로 하고,
[스키마 문서](schema.md)를 같은 커밋에서 갱신한다.

```bash
supabase migration new <이름>     # SQL 파일 생성
supabase db reset                 # 전체 재적용 (로컬 데이터 초기화됨)
```

## 3. 원격 환경 주입

Supabase 주소와 키는 `--dart-define` 없이도 로컬 기본값이 들어간다 ([app_config.dart](../lib/config/app_config.dart)). 원격 환경을 붙일 때만 주입한다:

```bash
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=...
```

## 4. 일봉 시세 seed 갱신

모의투자용 Binance 일봉은 월 1회 수동으로 전체 재수집한다. 프로젝트 루트에서 아래
명령을 실행하면 생성 seed를 덮어쓰고, 마이그레이션 뒤 로컬 DB에 다시 적재한다.

```bash
python3 supabase/scripts/fetch_candles.py
supabase db reset
```

생성 파일 `supabase/seeds/market_candles.sql`은 커밋하되 직접 수정하지 않는다.
부분 수집으로 확인할 때만 `--symbols BTC,ETH`를 쓰고, 별도 결과가 필요하면
`--out <path>`를 함께 쓴다. 기본 실행은 지정된 20개 USDT 페어를 모두 갱신한다.

---

## 겪은 함정 (재발 방지)

### RLS 정책만으로는 부족하다 — GRANT가 별도로 필요하다

RLS는 "**어떤 행**에 접근할 수 있는가"만 정한다. "**테이블 자체**에 접근할 수 있는가"는 `GRANT`가 정한다. 둘 다 있어야 한다.

Supabase 대시보드로 테이블을 만들면 GRANT가 자동으로 붙어서 튜토리얼에는 거의 안 나온다. 마이그레이션으로 직접 만들면 **반드시 명시해야 하고**, 빠뜨리면 정책이 완벽해도 이 오류가 난다:

```
42501: permission denied for table profiles
```

```sql
grant select on public.profiles to anon, authenticated;
grant update (nickname, bio, avatar_url) on public.profiles to authenticated;
```

컬럼 단위로 UPDATE를 주면 `id`·`created_at` 같은 걸 클라이언트가 건드릴 수 없다. 권장 패턴.

### Android 에뮬레이터는 127.0.0.1로 호스트를 못 본다

`10.0.2.2`를 써야 한다. [app_config.dart](../lib/config/app_config.dart)에서 플랫폼별로 분기한다.

### Android는 평문 HTTP를 차단한다 (API 28+)

로컬 Supabase는 `http://`라 그대로는 연결되지 않는다. **디버그 빌드에만** 예외를 준다 — `android/app/src/debug/` 아래에 있으므로 릴리즈 빌드는 영향을 받지 않는다.

- `android/app/src/debug/res/xml/network_security_config.xml`
- `android/app/src/debug/AndroidManifest.xml`

### `anonKey`는 deprecated — `publishableKey`를 쓴다

supabase_flutter 2.17 기준. 키 형식도 JWT에서 `sb_publishable_...`로 바뀌었다.

### flutter_secure_storage 11에서 `encryptedSharedPreferences` 옵션이 사라졌다

기본값이 이미 AES-GCM + RSA OAEP라 옵션 자체가 제거됐다. 예전 예제를 그대로 쓰면 컴파일 에러가 난다.

### 닉네임 제약 위반이 회원가입 전체를 실패시킨다

`handle_new_user()` 트리거가 같은 트랜잭션에서 돌기 때문에, 닉네임이 CHECK 제약을 위반하면 `auth.users` 삽입까지 롤백된다. 동작은 올바르지만 **사용자에게는 날것의 DB 오류가 노출된다.**

→ F1(auth)에서 처리할 것: 앱에서 닉네임을 먼저 검증하고, `23514`(check_violation)·`23505`(unique_violation)를 사용자 친화적 메시지로 매핑한다.
