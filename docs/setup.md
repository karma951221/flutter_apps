# 로컬 개발환경 — 공통

> [문서 허브](README.md) · [아키텍처](architecture.md) · [테스트 가이드](testing/README.md)

> 두 앱이 함께 쓰는 도구와 실행 절차. 앱별 절차는 각 앱 문서에 있다 —
> [트레이더 개발환경](../apps/trader/docs/setup.md)(Supabase · 스키마 변경 · 시세 seed) ·
> [통근 허브](../apps/commute/docs/README.md)(Supabase 없음).

## 사전 요구

| 도구 | 확인된 버전 | 비고 |
|------|------------|------|
| Flutter | 3.41.7 (stable) | |
| Dart | 3.11.5 | |
| Docker Desktop | 29.4.0 | 트레이더 앱의 Supabase 로컬 스택에 필요 |
| Supabase CLI | 2.115.0 | `brew install supabase/tap/supabase` (트레이더만) |
| Android SDK | 36.1.0 | 에뮬레이터 필요 |
| **Xcode** | **미설치** | **iOS 빌드 불가 — §4 참조** |

## 1. 앱 실행

트레이더는 로컬 Supabase 가 먼저 떠 있어야 한다 ([트레이더 개발환경 §1](../apps/trader/docs/setup.md#1-백엔드-기동)).

```bash
cd ~/Desktop/socialapp/apps/trader
flutter run -d emulator-5554
```

통근 앱([계획](../apps/commute/docs/plan.md))은 **Supabase 가 필요 없다** — 바로 띄운다.
위치 권한을 물으면 거부해도 된다(역 기준으로 동작한다).

```bash
cd ~/Desktop/socialapp/apps/commute
flutter run -d emulator-5554
```

코드 생성은 개발 중 watch 모드로 켜둔다:

```bash
dart run build_runner watch
```

## 2. iOS 빌드는 아직 불가

현재 머신에 **Command Line Tools만 설치**돼 있고 전체 Xcode가 없다. iOS 시뮬레이터를 쓰려면:

1. App Store에서 Xcode 설치
2. `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`
3. `sudo xcodebuild -runFirstLaunch`
4. `sudo gem install cocoapods` (또는 `brew install cocoapods`)

2~4번은 관리자 비밀번호가 필요하므로 직접 실행해야 한다.

MVP는 Android로 개발해도 무방하다. 다만 **F1(auth) 완료 시점에는 iOS에서도 한 번 돌려보는 게 좋다** — Keychain 동작과 세션 유지가 플랫폼별로 다르게 실패할 수 있는 영역이다.

---

## 겪은 함정 (재발 방지)

### 브로드캐스트 스트림을 `await for` 로 소비하면 이벤트가 유실된다

`onAuthStateChange` 같은 브로드캐스트 스트림을 `await for` + 비동기 본문으로 소비하면,
본문이 `await` 하는 동안 구독이 일시정지되고 그 사이 도착한 이벤트가 **버퍼링 없이 버려진다.**
회원가입 직후의 `signedIn` 이벤트가 이렇게 사라져 화면이 넘어가지 않았다.
콜백 방식 `listen()` 을 쓴다. 상세는 [F1 기록](../apps/trader/docs/features/auth/history.md), 자동화
테스트 범위는 [auth 테스트](../apps/trader/docs/features/auth/testing.md)를 확인한다.

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
