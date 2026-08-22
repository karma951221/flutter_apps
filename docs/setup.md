# 로컬 개발환경

> [문서 허브](README.md) · [아키텍처](architecture.md) · [테스트 가이드](testing/README.md)

> 0단계에서 실제로 구축·검증한 내용. 새 머신에서 재현할 때 이 문서를 따른다.

## 사전 요구

| 도구 | 확인된 버전 | 비고 |
|------|------------|------|
| Flutter | 3.41.7 (stable) | |
| Dart | 3.11.5 | |
| Docker Desktop | 29.4.0 | Supabase 로컬 스택 구동에 필요 |
| Supabase CLI | 2.115.0 | `brew install supabase/tap/supabase` |
| Android SDK | 36.1.0 | 에뮬레이터 필요 |
| **Xcode** | **미설치** | **iOS 빌드 불가 — §4 참조** |

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

앱 단위 테스트와 코드 컨벤션 검사는 [테스트 가이드](testing/README.md)를 따른다.

## 2. 스키마 변경

Studio UI에서 테이블을 직접 만들지 않는다. 반드시 마이그레이션으로 한다.

```bash
supabase migration new <이름>     # SQL 파일 생성
supabase db reset                 # 전체 재적용 (로컬 데이터 초기화됨)
```

## 3. 앱 실행

```bash
cd ~/Desktop/socialapp/app
flutter run -d emulator-5554
```

Supabase 주소와 키는 `--dart-define` 없이도 로컬 기본값이 들어간다 ([app_config.dart](../app/lib/core/config/app_config.dart)). 원격 환경을 붙일 때만 주입한다:

```bash
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=...
```

코드 생성은 개발 중 watch 모드로 켜둔다:

```bash
dart run build_runner watch
```

## 4. iOS 빌드는 아직 불가

현재 머신에 **Command Line Tools만 설치**돼 있고 전체 Xcode가 없다. iOS 시뮬레이터를 쓰려면:

1. App Store에서 Xcode 설치
2. `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`
3. `sudo xcodebuild -runFirstLaunch`
4. `sudo gem install cocoapods` (또는 `brew install cocoapods`)

2~4번은 관리자 비밀번호가 필요하므로 직접 실행해야 한다.

MVP는 Android로 개발해도 무방하다. 다만 **F1(auth) 완료 시점에는 iOS에서도 한 번 돌려보는 게 좋다** — Keychain 동작과 세션 유지가 플랫폼별로 다르게 실패할 수 있는 영역이다.

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

`10.0.2.2`를 써야 한다. [app_config.dart](../app/lib/core/config/app_config.dart)에서 플랫폼별로 분기한다.

### Android는 평문 HTTP를 차단한다 (API 28+)

로컬 Supabase는 `http://`라 그대로는 연결되지 않는다. **디버그 빌드에만** 예외를 준다 — `android/app/src/debug/` 아래에 있으므로 릴리즈 빌드는 영향을 받지 않는다.

- `android/app/src/debug/res/xml/network_security_config.xml`
- `android/app/src/debug/AndroidManifest.xml`

### 브로드캐스트 스트림을 `await for` 로 소비하면 이벤트가 유실된다

`onAuthStateChange` 같은 브로드캐스트 스트림을 `await for` + 비동기 본문으로 소비하면,
본문이 `await` 하는 동안 구독이 일시정지되고 그 사이 도착한 이벤트가 **버퍼링 없이 버려진다.**
회원가입 직후의 `signedIn` 이벤트가 이렇게 사라져 화면이 넘어가지 않았다.
콜백 방식 `listen()` 을 쓴다. 상세는 [F1 기록](features/auth/history.md), 자동화
테스트 범위는 [auth 테스트](testing/features/auth.md)를 확인한다.

### 단일 구독 StreamController 는 리스너가 없으면 `close()` 가 완료되지 않는다

테스트 `tearDown` 이 타임아웃으로 죽는 원인이 된다. `.broadcast()` 를 쓴다.

### Android SDK `android-37` 디렉터리 이름 불일치

`flutter_secure_storage` 11.0.0 이 `compileSdk = 37` 을 요구해서 앱 전체가 37로 올라가는데,
SDK 에는 `platforms/android-37.0` 만 설치돼 있고 Gradle 은 `platforms/android-37` 을 찾는다.

```
Failed to find target with hash string 'android-37' in: ~/Library/Android/sdk
```

cmdline-tools 가 없어 sdkmanager 로 받을 수 없었으므로 심볼릭 링크로 해결했다:

```bash
ln -sfn ~/Library/Android/sdk/platforms/android-37.0 ~/Library/Android/sdk/platforms/android-37
```

`android-37.0/build.prop` 의 `ro.build.version.sdk=37` 로 동일 API 임을 확인했다.
정공법은 cmdline-tools 를 설치하고 `sdkmanager "platforms;android-37"` 로 받는 것이다.

### `anonKey`는 deprecated — `publishableKey`를 쓴다

supabase_flutter 2.17 기준. 키 형식도 JWT에서 `sb_publishable_...`로 바뀌었다.

### flutter_secure_storage 11에서 `encryptedSharedPreferences` 옵션이 사라졌다

기본값이 이미 AES-GCM + RSA OAEP라 옵션 자체가 제거됐다. 예전 예제를 그대로 쓰면 컴파일 에러가 난다.

### 닉네임 제약 위반이 회원가입 전체를 실패시킨다

`handle_new_user()` 트리거가 같은 트랜잭션에서 돌기 때문에, 닉네임이 CHECK 제약을 위반하면 `auth.users` 삽입까지 롤백된다. 동작은 올바르지만 **사용자에게는 날것의 DB 오류가 노출된다.**

→ F1(auth)에서 처리할 것: 앱에서 닉네임을 먼저 검증하고, `23514`(check_violation)·`23505`(unique_violation)를 사용자 친화적 메시지로 매핑한다.
