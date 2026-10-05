# walk — 알람음 선택 설계

> 작성 2026-10-05 · 상태: **설계 승인** · 앱 문서 [walk 허브](../../../apps/walk/docs/README.md) ·
> 선행 설계 [기상 알람](2026-09-27-walk-alarm-design.md)

## 1. 목적

v1 알람은 모든 알람이 앱 에셋 비프음(`assets/alarm/default.wav`) 하나로 울린다.
알람마다 소리를 고를 수 있게 한다. 기본은 **기기의 시스템 기본 알람음**이고,
사용자가 고르면 앱 내장음이나 기기 알람음 중 하나로 울린다.

## 2. 결정 기록

| 결정 | 이유 |
|---|---|
| 기본음은 시스템 기본 알람음. 소리 정보가 없는 기존 알람도 시스템 기본으로 읽는다 | 사용자 결정. 기존 알람은 비프음 → 시스템 기본음으로 바뀐다 |
| 고를 수 있는 것: 시스템 기본 · 앱 내장음 · 기기 알람음 목록 | 사용자 결정(내장 + 시스템 둘 다) |
| 알람마다 따로 정한다(편집 화면의 한 줄) | 사용자 결정. 진동과 같은 자리 |
| 고르는 화면은 앱 안 목록(미리 듣기 포함). 안드로이드 기본 선택 창은 쓰지 않는다 | 사용자 결정. 내장음과 기기음을 한 화면에 두고 디자인을 맞춘다 |
| 내장음은 합성음 3개 — 기존 비프 + 차임 + 점점 빨라지는 비프. 스크립트로 만들고 스크립트도 남긴다 | 사용자 결정. 저작권 문제 없음 |
| 기기 알람음은 **고르는 순간 앱 저장소로 복사**하고 그 파일 경로로 울린다 | `alarm` 5.13.2 의 `AudioService` 는 `null`(기기 기본) · `assets/…` · 절대 경로만 재생하고 `content://` 는 못 읽는다. 패키지를 고치지 않아도 되고, 원본이 지워져도 울린다 |
| 복사본이 없으면 시스템 기본음으로 울린다 | 알람이 소리 없이 울리거나 실패하면 안 된다 |
| 범위 밖: 사용자 음악 파일 고르기 · 볼륨/페이드 설정 · 안 쓰는 복사본 정리 | YAGNI. 필요해지면 따로 |

## 3. 도메인

`lib/domain/alarm/entity/alarm_sound.dart` — Freezed union.

```dart
@freezed
sealed class AlarmSound with _$AlarmSound {
  /// 기기의 기본 알람음.
  const factory AlarmSound.system() = SystemAlarmSound;
  /// 앱 에셋. [asset] 은 `assets/alarm/…`.
  const factory AlarmSound.bundled(String asset) = BundledAlarmSound;
  /// 기기 알람음을 앱 저장소로 복사한 것. [path] 는 절대 경로.
  const factory AlarmSound.device({required String title, required String path}) = DeviceAlarmSound;
}
```

- `Alarm` 에 `final AlarmSound sound;`(기본 `AlarmSound.system()`)를 더한다.
- JSON: `'sound': {'type': 'system'}` · `{'type': 'bundled', 'asset': …}` ·
  `{'type': 'device', 'title': …, 'path': …}`. 키가 없거나 형식을 모르면 `system`.
- 내장음 목록은 도메인 상수 `BundledAlarmSounds.all`(에셋 경로 3개)로 둔다.
  표시 이름은 presentation 의 l10n 이 에셋 경로로 고른다.

## 4. 데이터

### 4.1 스케줄러

`PackageAlarmScheduler.settingsFor` 가 `alarm.sound` 로 `assetAudioPath` 를 정한다.

| sound | assetAudioPath |
|---|---|
| `system` | `null` |
| `bundled(asset)` | `asset` |
| `device(path)` | 파일이 있으면 `path`, 없으면 `null` |

파일 존재 확인은 주입 가능한 함수(`bool Function(String path)`, 기본 `File(path).existsSync()`)로
둬서 단위 테스트에서 바꾼다. `assetAudioPath` 상수는 없앤다.

저장 시 `AlarmUseCase.save` 가 이 알람의 예약을 모두 지우고 다시 걸므로 소리를 바꾸면
다음 울림부터 새 소리다. use case 변경은 없다.

### 4.2 기기 알람음 소스

도메인 인터페이스 `lib/domain/alarm/sound/alarm_sound_source.dart`:

```dart
typedef DeviceRingtone = ({String title, String uri});

abstract interface class AlarmSoundSource {
  /// 기기 알람음 목록(RingtoneManager TYPE_ALARM).
  Future<List<DeviceRingtone>> deviceRingtones();
  /// 미리 듣기. 이미 재생 중이면 바꿔 튼다. 알람 볼륨(USAGE_ALARM)으로 반복 재생.
  Future<void> preview(AlarmSound sound, {String? uri});
  Future<void> stopPreview();
  /// 기기 알람음을 앱 저장소에 복사하고 [AlarmSound.device] 를 돌려준다.
  Future<AlarmSound> import(DeviceRingtone ringtone);
}
```

미리 듣기에서 `system` 은 기본 알람음, `bundled` 는 에셋, 기기 알람음은 `uri` 로 튼다
(아직 복사 전이므로).

구현 `lib/data/alarm/channel_alarm_sound_source.dart` — `MethodChannel('walk/alarm_sounds')`.

### 4.3 네이티브 (`AlarmSoundsChannel.kt`)

`MainActivity` 가 채널을 등록하고 처리는 별도 파일 `AlarmSoundsChannel.kt` 에 둔다.

| 메서드 | 인자 | 동작 |
|---|---|---|
| `list` | — | `RingtoneManager(TYPE_ALARM)` 커서 → `[{title, uri}]` |
| `preview` | `{kind: system\|asset\|uri, value}` | `MediaPlayer` 하나를 재사용. `USAGE_ALARM`, `isLooping = true`. 에셋은 `FlutterLoader.getLookupKeyForAsset` → `assets.openFd` |
| `stopPreview` | — | 멈추고 해제 |
| `import` | `{uri}` | `contentResolver.openInputStream` → `filesDir.parent/app_flutter/alarm_sounds/<uri 해시>.<확장자>` 로 복사, 절대 경로 반환. 같은 uri 는 덮어쓴다. 확장자는 `getType` MIME 으로, 모르면 `ogg` |

`app_flutter` 는 `alarm` 패키지가 상대 경로를 붙이는 기준 폴더와 같다(절대 경로로 넘기므로
필수는 아님). 액티비티가 내려가면(`onPause` 아님, `cleanUpFlutterEngine`) 미리 듣기를 해제한다.
실패는 `result.error`.

## 5. 화면

### 5.1 편집 화면

`AlarmEditPage` 의 진동 줄 위에 `AppListTile(title: 알람음, subtitle: <현재 이름>, trailing: chevron)`.
누르면 `AlarmSoundPage` 를 push 하고, 돌려받은 `AlarmSound` 로 `AlarmEditCubit.setSound` 를 부른다.

이름: `system` → "시스템 기본", `bundled` → l10n 내장음 이름, `device` → `title`.

### 5.2 알람음 선택 화면

`lib/presentation/alarm/page/alarm_sound_page.dart` + `AlarmSoundCubit`.

- 구역 세 개: **시스템 기본** 한 줄 · **앱 소리** 3줄 · **기기 알람음** 목록.
- 줄을 누르면 선택 표시(라디오 모양 trailing)가 옮겨 가고 미리 듣기가 시작된다.
- 아래 `AppButton.primary("선택")` — 기기 알람음이면 `import` 후, 아니면 바로 결과를 돌려주며 닫는다.
  import 중에는 버튼 로딩. 실패하면 `AppSnackBar`(오류)를 띄우고 화면에 남는다.
- 화면을 닫으면(선택이든 뒤로가기든) 미리 듣기를 멈춘다(`cubit.close` 에서 `stopPreview`).
- 기기 목록 읽기 실패 · 빈 목록이면 그 구역에 `AppPlaceholder` 문구 한 줄. 나머지 구역은 그대로 쓴다.
- 처음 선택 표시: 현재 알람의 소리. `device` 는 같은 제목의 기기 항목에 표시하고,
  목록에 없으면(원본 삭제) 표시 없이 둔 채 그대로 "선택" 하면 기존 값을 돌려준다.

상태(Freezed): `selected`(선택한 항목 — `system` · `bundled(asset)` · `deviceUri(DeviceRingtone)` · `current(AlarmSound)`) ·
`ringtones`(로딩/목록/실패) · `importing`.

## 6. 내장음

`apps/walk/tool/generate_alarm_sounds.py`(표준 라이브러리만) 가 22.05kHz 모노 16bit WAV 를 만든다.

| 파일 | 소리 |
|---|---|
| `assets/alarm/beep.wav` | 기존 `default.wav` 이름만 바꿈 |
| `assets/alarm/chime.wav` | 부드러운 2음 차임(감쇠 사인, 3초) |
| `assets/alarm/rising.wav` | 간격이 점점 짧아지는 비프(3초) |

`loopAudio: true` 라 3초 단위로 반복된다.

## 7. l10n

`walkAlarmSound`(알람음) · `walkAlarmSoundSystem`(시스템 기본) · `walkAlarmSoundBundledSection`(앱 소리) ·
`walkAlarmSoundDeviceSection`(기기 알람음) · `walkAlarmSoundBeep` · `walkAlarmSoundChime` ·
`walkAlarmSoundRising` · `walkAlarmSoundSelect`(선택) · `walkAlarmSoundDeviceUnavailable` ·
`walkAlarmSoundImportFailed`. ko · en · ja.

## 8. 테스트

| 대상 | 내용 |
|---|---|
| `alarm_test.dart` | sound JSON 왕복 3종 · 키 없음/모르는 type → system |
| `package_alarm_scheduler_test.dart` | sound 별 `assetAudioPath` · 복사본 없음 → null |
| `channel_alarm_sound_source_test.dart` | 채널 인자/응답 매핑(mock MethodChannel) |
| `alarm_sound_cubit_test.dart` | 초기 선택 · 탭 → preview · 선택(내장/기기 import/실패) · close → stopPreview |
| `alarm_sound_page_test.dart` | 세 구역 표시 · 목록 실패 placeholder · 선택 결과 pop |
| `alarm_edit_page_test.dart` · `alarm_edit_cubit_test.dart` | 알람음 줄 이름 · setSound 저장 |

네이티브(목록 · 복사 · 실제 재생)는 실제 기기에서 확인한다: 기기 알람음 하나를 골라 1분 뒤 알람이
그 소리로 울리는지, 원본을 못 읽는 경우 시스템 기본으로 울리는지.

## 9. 문서

완료 시 [walk plan](../../../apps/walk/docs/plan.md) 의 후보에서 "알람음 선택"을 빼고
[walk status](../../../apps/walk/docs/status.md) 를 갱신한다.

## 10. 추가 결정 (2026-10-05, 고도화 백로그 반영)

[알람 고도화 백로그](2026-10-05-walk-alarm-upgrade-backlog-design.md) 를 진행하며 스파이크로 확인한 사실과
사용자 결정을 반영한다. 아래가 §2 ~ §8 과 어긋나면 이 절이 우선한다.

| 결정 | 이유 |
|---|---|
| `alarm` 패키지(실제 해석 버전 **5.14.0**, 루트 `pubspec.lock`)를 `apps/walk/third_party/alarm/` 에 복사해 path 의존성으로 쓴다(포크). 루트 workspace 멤버로 넣지 않는다 | 사용자 결정. 울리는 순간의 판단(무음 모드 · 자동 멈춤 · 스누즈 횟수 · 소리 대체)은 패키지 네이티브 `AlarmService` 안에서만 할 수 있다. MIT 라이선스 유지, 바꾼 점은 `third_party/alarm/FORK.md` 에 적는다 |
| 기존 비프음 파일 이름 `assets/alarm/default.wav` 를 **그대로 둔다**(§6 의 `beep.wav` 이름 바꾸기 취소). 화면 이름은 "비프" | 이미 걸린 회차(최대 14일)는 옛 경로로 울린다. 이름을 바꾸면 그 회차가 소리 없이 울린다 |
| **설정 지문(signature)으로 다시 걸기**: 패키지에 거는 회차의 `payload` 를 `'<alarmId>|<signature>'` 로 하고, `AlarmScheduler.scheduled()` 가 `packageId → (at, signature)` 를 돌려준다. `_sync` 는 시각이 같아도 지문이 다르면 다시 건다. 옛 payload(`'<alarmId>'`)는 지문 불일치로 보고 한 번 다시 건다 | `_sync` 는 시각만 비교해 소리 · 진동 같은 설정 변경이 이미 걸린 회차에 반영되지 않았다. 웨이브 1 · 3 의 새 설정도 같은 장치를 쓴다 |
| 지문은 `PackageAlarmScheduler` 가 `settingsFor` 결과 중 울림에 영향을 주는 값(소리 경로 · 진동 · 볼륨 · 제목 등)을 정해진 순서로 이어 붙인 문자열의 해시(`fnv1a32` hex)로 만든다. 문구(l10n) 변경은 지문에 넣지 않는다 | 결정적이고 짧다. 로캘이 바뀔 때마다 전부 다시 걸 필요는 없다 |
| 포크 네이티브에 **소리 대체**를 넣는다: `AlarmSettings.androidFallbackAudioPath`(String?). `AudioService.playAudio` 가 1차 경로(null 이면 시스템 기본 알람음)로 재생에 실패하면 이 경로로 다시 재생한다. 앱은 항상 `assets/alarm/default.wav` 를 넘긴다 | §2 의 "복사본이 없으면 시스템 기본음"은 예약 시점에만 판단돼, 울릴 때 실패하면 무음이었다. 시스템 기본음도 기기에서 "없음"이면 무음일 수 있다 |
| `settingsFor` 의 파일 존재 확인은 생성자 주입이 아니라 정적 메서드 인자 `{bool Function(String) fileExists = _exists}` 로 둔다 | `PackageAlarmScheduler` 는 인자 없는 생성자로 DI 등록돼 있다. 함수 타입 생성자 인자는 injectable 이 풀지 못한다 |
| `import` 는 복사 뒤 네이티브 `MediaPlayer.prepare()` 로 복사본을 검증하고, 실패하면 파일을 지우고 오류를 돌려준다 | 코덱 문제로 울릴 때 실패하는 파일을 미리 막는다 |

포크 범위(웨이브 0): 복사 · path 의존성 · `analysis_options.yaml` 의 `third_party/**` 제외 · pigeon/json 재생성 절차를
`FORK.md` 에 적기 · `androidFallbackAudioPath`. 다른 웨이브가 같은 방식으로 필드를 더한다
(웨이브 1 무음 모드, 웨이브 3 자동 멈춤 · 스누즈 횟수).
