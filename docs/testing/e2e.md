# E2E 테스트 (Patrol)

> [테스트 가이드](README.md) · [개발환경](../setup.md) · [아키텍처](../architecture.md)

`flutter test` 로 도는 단위·위젯 테스트와 달리, E2E 는 **에뮬레이터에서 앱 전체를
실제 Supabase 에 붙여** 돌린다. 라우터 리다이렉트·세션 저장·화면 간 값 전달처럼
mock 으로는 확인되지 않는 연결을 검증한다.

## 왜 Patrol 인가

| | 순정 `integration_test` | **Patrol** | Maestro |
|---|---|---|---|
| 언어 | Dart | Dart (`integration_test` 위 래퍼) | YAML |
| 위젯 finder | `find.byKey` 등 | `$(...)` — 짧고 자동 대기 | Semantics 라벨 필요 |
| **네이티브 다이얼로그** | **불가** | 권한·알림·설정 조작 가능 | 가능 |
| 테스트 격리 | 약함 | 테스트마다 프로세스 분리 | 프로세스 분리 |

`image_picker` 를 쓰는 이상 사진 권한 다이얼로그가 뜨고, 순정 `integration_test`
로는 그 팝업을 누를 수 없다. 그래서 Patrol 을 쓴다.

## 1회 준비

```bash
dart pub global activate patrol_cli
patrol doctor          # PATH 에 patrol 이 없으면 ~/.pub-cache/bin 을 추가한다
cd app && flutter pub get
```

**`patrol doctor` 가 통과해도 JDK 가 없으면 `patrol test` 가 죽는다.** `doctor` 는
Java 를 보지 않는데, 실제 실행은 Gradle 을 거치므로 JDK 가 필요하다.

```text
Error: Failed to read Java version. Make sure you have Java installed and added to PATH
```

macOS 에 별도 JDK 가 없으면 Android Studio 의 번들 JBR 을 쓴다. `adb` 도 `doctor`
기준을 맞추려면 `ANDROID_HOME` 이 있어야 한다 (2026-08-27 실행에서 둘 다 걸렸다).

```bash
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$PATH:$HOME/.pub-cache/bin"
```

프로젝트 쪽 설정은 이미 커밋돼 있다.

- `app/pubspec.yaml` — `patrol` 의존성과 `patrol:` 섹션(앱 식별자)
- `app/android/app/build.gradle.kts` — `PatrolJUnitRunner`, orchestrator,
  `clearPackageData=true`
- `app/android/app/src/androidTest/java/com/karma/daylog/MainActivityTest.java`
  — Patrol 이 Dart 테스트를 JUnit 케이스로 펼치는 보일러플레이트. 손대지 않는다.

## 실행

E2E 는 **로컬 Supabase 와 에뮬레이터가 둘 다 떠 있어야** 한다.

```bash
cd ~/Desktop/socialapp
supabase start                      # 이미 떠 있으면 생략

cd app
patrol test                         # patrol_test/ 전체
patrol test -t patrol_test/auth_test.dart
patrol test -t patrol_test/chat_test.dart   # 실시간 왕복까지 태운다
patrol develop -t patrol_test/post_test.dart   # Hot Restart 로 테스트를 짜면서 돌린다
```

## 앱 언어는 하니스가 한국어로 고정한다

다국어가 들어오면서 앱이 기기 언어를 따라간다. 에뮬레이터는 보통 `en-US` 라
그대로 두면 앱이 영어로 뜨고, 한국어를 단언하는 E2E 가 전부 깨진다.

`launchApp()` 이 `SharedPreferences` 의 `language` 를 `ko` 로 심어 이를 막는다.
기기 locale 을 바꾸지 않는 이유는 어느 에뮬레이터에서도 같게 돌아야 해서다.
en·ja 화면을 E2E 로 확인하고 싶으면 그 값을 바꾼다.

기기를 고를 때는 `-d`:

```bash
patrol test -d emulator-5554
```

에뮬레이터를 띄우는 건 Claude Code 의 `/emulator` 슬래시 커맨드가 대신한다
(`.claude/commands/emulator.md`).

## 구조

```text
app/patrol_test/
├── helpers/app_harness.dart      # 앱 부팅, 로그인/가입 헬퍼 — 검증 로직 없음
├── auth_test.dart                # 가입 → 피드 → 로그아웃 → 로그인
├── sign_in_failure_test.dart     # 잘못된 비밀번호
└── post_test.dart                # 작성 → 피드 반영 → 삭제
```

테스트는 매 실행마다 새 계정을 만든다. 고정 계정을 쓰면 이전 실행이 남긴
게시물 때문에 다음 실행이 흔들린다. 로컬 DB 가 지저분해지면 `supabase db reset`.

### 알려진 실패 — '잘못된 비밀번호' 테스트

`sign_in_failure` 성격의 테스트(`auth_test.dart` 의 두 번째)는 **자기 단계와
단언을 전부 통과하고도** 프로세스가 아래 단언으로 죽는다.

```text
'_pendingExceptionDetails != null': A test overrode FlutterError.onError but
either failed to return it to its original state, or had unexpected additional
errors that it could not handle.
```

테스트 본문이 끝난 **뒤에** 로그인 실패 경로에서 비동기 오류가 하나 더 올라오는
모양이다. 확인한 것:

- 화면 동작 자체는 정상이다 — `FailureText` 가 뜨고 화면은 로그인에 남는다.
- 파일을 나눠도 그대로다. Patrol 은 `patrol_test/` 전체를 **하나의 번들**로
  묶으므로, 파일을 갈라도 프로세스마다 나머지 테스트를 건너뛰는 구조는 같다.
- 나머지 두 테스트(`auth_test` 첫 번째 · `post_test`)는 통과한다.

이 테스트는 **실패로 집계되지도 않는다.** 프로세스가 죽어 결과를 돌려주지 못하므로
요약에는 `Successful: 2 / Failed: 0` 으로 나오고 종료 코드만 1 이다. CI 에 걸 때는
숫자가 아니라 **종료 코드를 본다.**

2026-08-27 검수에서 처음 E2E 를 돌려 보고 발견했다. 원인은 아직 못 짚었다
([검수 기록](audit-2026-08-27.md)).

## 셀렉터 규칙

화면 문구로 위젯을 찾으면 문구를 다듬을 때마다 테스트가 깨진다. E2E 가 집는
입력 필드에는 `Key` 를 단다.

```dart
AuthTextField(key: const Key('signIn.email'), ...)
```

```dart
await $(const Key('signIn.email')).enterText(email);
```

현재 키: `signIn.email`, `signIn.password`, `signUp.email`, `signUp.nickname`,
`signUp.password`, `signUp.passwordConfirm`, `postEditor.content`.

버튼은 라벨이 곧 사양이라 텍스트로 찾아도 된다. 단 **같은 문구가 AppBar 제목과
버튼에 동시에 있으면 finder 가 2개를 잡아 실패한다** (로그인 화면의 '로그인').
이럴 때는 위젯 타입으로 좁힌다 — `$(FilledButton)`.

## 겪은 함정 (재발 방지)

### `pumpAndSettle` 은 스플래시에서 타임아웃한다

[SplashPage](../../app/lib/features/auth/presentation/page/splash_page.dart) 의
`CircularProgressIndicator` 는 끝나지 않는 애니메이션이다. settle 은 "대기 중인
프레임이 없을 때"를 기다리므로 영원히 오지 않는다.

```dart
await $.pumpWidget(const DaylogApp());
await $.waitUntilVisible($(const Key('signIn.email')));   // pumpAndSettle 대신
```

### 앱 부팅을 `bootstrap()` 으로 하면 안 된다

`bootstrap()` 은 `runApp` 을 부른다. 테스트는 자기가 pump 해야 하므로
준비 단계만 떼어낸 `initializeApp()` 을 쓴다
([bootstrap.dart](../../app/lib/bootstrap.dart)).

`Supabase.initialize` 는 프로세스당 한 번만 가능하고, `configureDependencies()`
는 두 번 부르면 GetIt 중복 등록으로 터진다. 그래서 헬퍼가 `getIt.reset()` 을
먼저 부른다.

### 이전 테스트의 세션이 다음 테스트로 샌다

세션은 Keychain/EncryptedSharedPreferences 에 저장되므로 앱을 다시 띄워도 남는다.
`clearPackageData=true` 로 테스트마다 앱 데이터를 지우고, 헬퍼에서도 한 번 더
`signOut` 한다. 세션이 없을 때 `signOut()` 은 예외를 던지므로 삼켜야 한다.

### 에뮬레이터는 `127.0.0.1` 로 호스트를 못 본다

`10.0.2.2` 를 쓴다. 이미
[app_config.dart](../../app/lib/core/config/app_config.dart) 가 분기한다.
E2E 도 같은 경로를 타므로 별도 `--dart-define` 이 필요 없다.

### orchestrator 버전 때문에 빌드가 멈출 수 있다

`androidx.test:orchestrator` 를 `1.6.1` 로 올린다
(`app/android/app/build.gradle.kts`).

## 네이티브 다이얼로그를 다룰 때

프로필 사진처럼 `image_picker` 를 쓰는 흐름을 테스트할 때만 필요하다.

```dart
await $('사진 선택').tap();
await $.native.grantPermissionWhenInUse();   // 시스템 권한 팝업
```

`$.native` 로 알림 확인, 앱 백그라운드 전환, 설정 토글도 할 수 있다.

## 화면이 바뀌면 함께 고쳐야 하는 곳 (2026-08-24)

E2E 는 화면의 문구와 자리에 직접 붙는다. UI 개편 때 아래를 함께 고쳤다.

- **로그아웃이 피드 AppBar 에서 설정 탭으로 옮겨졌다.** `auth_test.dart` 는 이제
  하단 내비게이션의 `설정` → `로그아웃` → 확인 다이얼로그를 거친다
- **작성 버튼 라벨이 `게시하기` → `올리기` 로 바뀌었다** (`post_test.dart`)

키(`signIn.email` · `postEditor.content` 같은 `Key`)로 잡는 셀렉터는 문구가 바뀌어도
살아남는다. 새 화면을 만들 때 **누를 곳과 입력할 곳에는 `Key` 를 남긴다.**
