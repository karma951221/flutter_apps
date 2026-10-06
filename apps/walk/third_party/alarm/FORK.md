# alarm 포크

walk 앱이 쓰는 [alarm](https://pub.dev/packages/alarm) 패키지의 포크다. 원본 저장소는
<https://github.com/gdelataillade/alarm>, 라이선스는 원본 그대로 MIT([LICENSE](LICENSE))다.

| 항목 | 값 |
|---|---|
| 기준 버전 | alarm **5.14.0** (pub.dev, sha256 `bdaafb634a957ae76a0320bdcb8909be3458383c60e2ab70a7f7c90ce8ac9a98`) |
| 복사 날짜 | 2026-10-05 |
| 복사 방법 | `~/.pub-cache/hosted/pub.dev/alarm-5.14.0` 을 그대로 복사하고 `example/` 만 지웠다 |
| 연결 | `apps/walk/pubspec.yaml` 의 `alarm: path: third_party/alarm`. 패키지 이름은 그대로 `alarm` 이라 import 는 바뀌지 않는다 |
| workspace | 루트 workspace 멤버가 **아니다**(`resolution: workspace` 없음). 포크 디렉터리에서 `flutter pub get` 하면 자기 `pubspec.lock` · `.dart_tool/` 을 만들고, 둘 다 커밋하지 않는다([.gitignore](.gitignore)) |
| 앱 analyze | `apps/walk/analysis_options.yaml` 이 `third_party/**` 를 제외한다. 포크는 원본의 `very_good_analysis` 규칙을 따른다 |

포크한 이유: 울리는 순간의 판단(소리 대체 · 무음 모드 진동 · 자동 멈춤 · 스누즈 횟수)은 패키지 네이티브
`AlarmService` 안에서만 할 수 있다. 근거는
[알람음 선택 스펙 §10](../../../../docs/superpowers/specs/2026-10-05-walk-alarm-sound-design.md).
위 연결 규칙(path 의존성 · 이 파일과 LICENSE 존재 · workspace 밖)은
`apps/walk/test/convention/package_boundary_test.dart` 가 지킨다.

## 재생성

pigeon 정의(`pigeons/alarm_api.dart`)나 `lib/model/*.dart` 의 json 모델을 바꾸면 포크 디렉터리에서 다시 만든다.

```bash
cd apps/walk/third_party/alarm
flutter pub get
dart run pigeon --input pigeons/alarm_api.dart
dart format lib/src/generated/platform_bindings.g.dart
dart run build_runner build --delete-conflicting-outputs
```

- pigeon 은 세 파일을 만든다 — `lib/src/generated/platform_bindings.g.dart`,
  `android/src/main/kotlin/com/gdelataillade/alarm/generated/FlutterBindings.g.kt`,
  `ios/alarm/Sources/alarm/generated/FlutterBindings.g.swift`.
- pigeon 의 Dart 출력은 포맷되지 않은 채 나온다. 원본 생성물은 `dart format` 을 거친 것이므로 **포맷까지 해야**
  원본과 같아진다. 포크의 SDK 하한이 `>=3.0.0` 이라 `dart format` 은 language 3.0 의 옛 줄바꿈 스타일로 맞춘다.
  `dart format .` 로 포크 전체를 돌려도 원본 파일은 바뀌지 않는다.
- build_runner 는 `json_serializable` 로 `lib/model/*.g.dart` 를 만든다(`build.yaml`). `json_serializable` 이
  `<6.10.0` 으로 묶인 이유는 `pubspec.yaml` 주석에 있다.
- 2026-10-05 확인: Flutter 3.41.7 · Dart 3.11.5, pigeon 25.5.0 · json_serializable 6.9.5 · build_runner 2.5.4 로
  위 절차를 돌리면 생성물이 원본과 **diff 0** 이다(`.dart_tool/build` 를 지운 뒤 build_runner 가 실제로 3개를 다시 씀).
  `pubspec.lock` 을 커밋하지 않으므로, 나중에 더 새 버전이 잡혀 바꾸지 않은 부분까지 생성물이 달라지면 그 도구를
  위 버전으로 `dev_dependencies` 에 고정한다.
- 필드를 더한 뒤에는 `git diff` 로 생성물 변경이 그 필드에 관한 줄뿐인지 본다.
- Dart 모델에 필드를 더하면 Kotlin `models/AlarmSettings.kt`(`fromWire` · 직렬화) 와 Swift 모델도 같이 맞춘다.
  필드는 pigeon 클래스 **끝에** 기본값과 함께 더한다(레거시 json · 이미 저장된 알람이 그대로 읽히도록).

## 테스트

```bash
# 포크 Kotlin 단위 테스트(JUnit, JVM). 먼저 apps/walk 에서 flutter pub get 이 돼 있어야
# 앱 Gradle 이 포크를 :alarm 프로젝트로 포함한다(.flutter-plugins-dependencies).
cd apps/walk/android
JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew :alarm:testDebugUnitTest
# 이미 돈 결과라 UP-TO-DATE 로 끝나면 --rerun 을 붙인다
```

- 5.14.0 그대로에서 `testDebugUnitTest: 59 tests, 0 failed, 0 skipped`. 테스트 소스가 잡히지 않아 0개가 돌면
  `android/build.gradle` 이 빌드를 실패시킨다.
- 바꾼 Kotlin 은 순수 규칙 함수로 빼서 `android/src/test/kotlin/...` 에 JUnit 테스트를 더한다. 나머지는 에뮬레이터 시나리오로 본다.
- 포크 자체의 `flutter test`(`test/`)는 돌리지 않는다. 바꾼 Dart 동작은 앱 테스트(`apps/walk/test`)에서 확인한다.
  포크 경로를 따라 `apps/walk/test/third_party/alarm/<lib 아래 경로>_test.dart` 에 둔다
  (예: `lib/model/alarm_settings.dart` ↔ `test/third_party/alarm/model/alarm_settings_test.dart`).
- 포크를 바꾼 뒤에는 `apps/walk` 에서 `flutter analyze` · `flutter test` · `flutter build apk --debug` 까지 돌린다.

## 원본 올리기

원본 새 버전을 들일 때는 그 버전을 같은 방법으로 복사하고(`example/` 제외, 이 파일 · `.gitignore` 유지)
아래 표의 변경을 다시 적용한 뒤 위 재생성 · 테스트를 돌린다.

## 바꾼 점

원본 5.14.0 과 달라진 것을 태스크마다 한 줄씩 적는다. 포크에서 바꾼 코드에는 `Fork:` 주석을 단다.

| 태스크 | 바꾼 파일 | 내용 | 이유 |
|---|---|---|---|
| W0-T2 소리 대체 | `pigeons/alarm_api.dart`(+ 생성물 3개) · `lib/model/alarm_settings.dart`(+ `.g.dart`) · `android/…/models/AlarmSettings.kt` · `android/…/services/AudioService.kt` · `android/…/alarm/AlarmService.kt` · 테스트 `android/src/test/…/services/AudioFallbackTest.kt` | `AlarmSettings.androidFallbackAudioPath`(String?, 기본 null, wire 끝에 추가 · 없는 옛 json 은 null). `AudioService.playAudio` 가 `audioCandidates(primary, fallback)` 순서(대체 경로가 null 이거나 1차와 같으면 하나)로 `prepare` · `start` 를 시도하고, 실패하면 다음 후보로 넘어간다. 모두 실패하면 원래처럼 로그만 남긴다 | 1차 소리(복사한 기기 알람음 · 시스템 기본음)가 울리는 순간 재생에 실패하면 무음이었다. [스펙 §10](../../../../docs/superpowers/specs/2026-10-05-walk-alarm-sound-design.md) |
| W1-T1 무음 모드 진동 | `pigeons/alarm_api.dart`(+ 생성물 3개) · `lib/model/alarm_settings.dart`(+ `.g.dart`) · `android/…/models/AlarmSettings.kt` · `android/…/alarm/AlarmService.kt` · `android/…/services/AudioService.kt` · `android/…/services/VibrationService.kt` · 테스트 `android/src/test/…/alarm/RingerMuteTest.kt` | `AlarmSettings.androidSilentWhenRingerMuted`(bool, 기본 false, wire 끝에 추가 · 없는 옛 json 은 false). `AlarmService.ringAlarm` 이 울리는 순간 `shouldMuteForRinger(optIn, AudioManager.ringerMode)`(켜져 있고 벨소리 모드가 NORMAL 이 아니면 참)로 판단해, 참이면 스트림 볼륨 설정 · 볼륨 강제 · 오디오 포커스를 건너뛰고 `AudioService.playAudio(muted = true)` 로 `MediaPlayer` 를 볼륨 0 으로 재생(페이드 없음)하며 `vibrate` 와 상관없이 진동한다. `VibrationService` 는 진동에 알람 용도를 붙인다(API 33+ `VibrationAttributes.USAGE_ALARM`, 26~32 `AudioAttributes.USAGE_ALARM`) | 무음 · 진동 모드에서 알람이 소리 없이 진동만 하도록. 재생을 멈추면 패키지가 "안 울림"으로 보고 알람을 지우므로 재생은 유지한다. [웨이브 1 스펙](../../../../docs/superpowers/specs/2026-10-05-walk-alarm-wave1-design.md) |
| W1 리뷰 트리거 API | `android/…/alarm/AlarmPlugin.kt` · `android/…/alarm/EngineRegistry.kt`(신규) · 테스트 `android/src/test/…/alarm/EngineRegistryTest.kt` | `AlarmPlugin.alarmTriggerApi` 를 엔진(`BinaryMessenger`)마다 따로 기억하는 `EngineRegistry` 로 바꿨다. 아직 붙어 있는 엔진 중 가장 나중에 붙은 엔진의 API 를 쓰고, `onDetachedFromEngine` 은 그 엔진의 것만 지운다(읽기 전용 프로퍼티) | 원본은 detach 때 무조건 null 로 비워서, 앱 엔진이 헤드리스 resync 엔진보다 나중에 붙은 뒤 헤드리스 엔진이 내려가면 앱 엔진이 울림 · 멈춤 · 스누즈 이벤트를 더 받지 못했다 |
