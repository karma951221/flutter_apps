# walk 알람 벨소리 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 직접 합성한 벨소리 4개를 번들하고(새 알람 기본 = 아침 차임), 기기의 음성 파일을 골라 앱 저장소로 복사해 알람음으로 쓰게 한다.

**Architecture:** 에셋은 `tool/alarm_sounds/generate.py` 가 만든 OGG. 도메인 `AlarmSound` 에 `file` 변형을 더하고, 옛 wav 경로는 `fromJson` 에서 새 소리로 옮겨 읽는다. 내 파일은 네이티브 `AlarmSoundsChannel` 의 `pickFile`(SAF `ACTION_OPEN_DOCUMENT`) → 기존 `importRingtone` 복사 · 검증 경로를 탄다.

**Tech Stack:** Flutter · freezed 3 · flutter_bloc · MethodChannel(Kotlin) · Python numpy + soundfile(libsndfile Vorbis).

**Spec:** [docs/superpowers/specs/2026-11-16-walk-alarm-ringtone-design.md](../specs/2026-11-16-walk-alarm-ringtone-design.md)

## Global Constraints

- 작업 디렉터리 `apps/walk`. 루트 `CLAUDE.md` 규칙: 공통 위젯(`AppListTile` · `AppSnackBar` · `AppButton`)과 `AppSpacing` 등 토큰만, Freezed 패턴(union = sealed + named factory), 테스트 위치 = 구현 경로 미러, 생성 파일은 `dart run build_runner build --delete-conflicting-outputs` 로만.
- 문구는 `packages/l10n/lib/l10n/app_{ko,en,ja}.arb` 세 언어 모두. 고친 뒤 `packages/l10n` 에서 `flutter gen-l10n`(기존 절차를 따른다).
- `assets/alarm/default.wav` · `chime.wav` · `rising.wav` 파일은 지우지도 이름을 바꾸지도 않는다.
- 대체음 `androidFallbackAudioPath` 는 `BundledAlarmSounds.beep` 그대로.
- `AlarmSound.fromJson` 은 절대 던지지 않고, 모르는 값은 `system`.
- 내 파일 크기 상한 30MB(`30 * 1024 * 1024` 바이트).
- TDD: 실패하는 테스트를 먼저 쓰고 실패를 확인한 뒤 구현한다.

## Review Focus

1. 옛 알람 JSON(`chime.wav` · `rising.wav` · type 없는 값)이 던지지 않고 정해진 소리로 읽힌다 — Task 2 테스트.
2. 고른 파일의 복사본이 사라진 뒤 울림 설정이 `assetAudioPath: null`(기기 기본) + 비프 대체가 된다 — Task 2 `settingsFor` 테스트.
3. 파일 선택을 취소하면 선택 · 상태가 그대로다(오류 스낵바 없음) — Task 3 큐빗 테스트.
4. 내 파일을 이미 쓰는 알람으로 화면을 열면 "내 파일" 구역에 그 이름 줄이 선택된 채 보이고, 그대로 "선택"하면 다시 복사하지 않고 같은 값을 돌려준다 — Task 3 큐빗 · 위젯 테스트.
5. 표시 이름이 없거나 확장자만 있는 파일(`.mp3`)이면 "내 파일" 기본 이름 — Task 3 Kotlin 규칙 테스트.

---

### Task 1: 벨소리 합성 스크립트와 에셋

**Files:**
- Create: `apps/walk/tool/alarm_sounds/generate.py`, `apps/walk/tool/alarm_sounds/README.md`
- Create: `apps/walk/assets/alarm/{morning,marimba,classic,birds}.ogg`, `apps/walk/assets/alarm/README.md`
- Modify: `apps/walk/lib/domain/alarm/entity/alarm_sound.dart`(`BundledAlarmSounds` 만)
- Test: `apps/walk/test/convention/alarm_assets_test.dart`

**Interfaces:**
- Produces: `BundledAlarmSounds.morning = 'assets/alarm/morning.ogg'`, `.marimba`, `.classic`, `.birds`(같은 패턴), `.beep`(그대로), `.all = [morning, marimba, classic, birds, beep]`, 그리고 `BundledAlarmSounds.legacyChime = 'assets/alarm/chime.wav'`, `legacyRising = 'assets/alarm/rising.wav'`(목록에 없음).

- [ ] **Step 1: 실패하는 컨벤션 테스트** — `alarm_assets_test.dart`: `BundledAlarmSounds.all` 의 모든 경로에 대해 `File(path).existsSync()` 이고, `.ogg` 는 처음 4바이트가 `OggS`, 크기 합계(ogg 4개) < 500 * 1024. `all.first == BundledAlarmSounds.morning`. `legacyChime` · `legacyRising` 파일도 존재.
- [ ] **Step 2: 실행해 실패 확인** — `flutter test test/convention/alarm_assets_test.dart` → 컴파일 실패(`morning` 없음).
- [ ] **Step 3: `generate.py`** — numpy 로 각 소리를 44100Hz 모노 float 로 합성해 `soundfile.write(path, data, 44100, format='OGG', subtype='VORBIS')`. 길이 3~6초, 마지막 50ms 를 0 으로 페이드(루프 튐 방지), 피크 -1dBFS 정규화, `np.random.default_rng(20261116)`. 소리 성격은 스펙 §5.1 표(아침 차임: 장3화음 상행 벨 + 감쇠 / 마림바: 짧은 감쇠의 나무 음색 멜로디 / 클래식 벨: 약 20Hz로 두드리는 금속성 배음 1초 울림 + 쉼 반복 / 새소리: 주파수가 휘는 지저귐). 실행: `python3 -m venv .venv && .venv/bin/pip install numpy soundfile && .venv/bin/python tool/alarm_sounds/generate.py` (apps/walk 에서, 출력 `assets/alarm/`). `.venv` 는 커밋하지 않는다(필요하면 `.gitignore`).
- [ ] **Step 4: README 두 개** — `tool/alarm_sounds/README.md`: 실행법, 사용 도구 버전(libsndfile 1.2.2 등 실제 값), 소리별 설계 한 줄. `assets/alarm/README.md`: 파일별 출처(ogg = 이 스크립트로 직접 생성, wav = 이전 웨이브 0 합성), 라이선스 = 저장소 라이선스, 외부 음원 없음. 상대 링크만.
- [ ] **Step 5: `BundledAlarmSounds` 갱신 후 테스트 통과 확인** — `flutter test test/convention/alarm_assets_test.dart` PASS. (`walkAlarmSoundChime/Rising` 참조하는 format 은 Task 2 에서 정리 — 이 단계에서 `flutter analyze` 가 깨지면 format 의 옛 case 를 `legacyChime` · `legacyRising` 으로 바꿔 컴파일만 맞춘다.)
- [ ] **Step 6: 미리 들어 보기** — 에뮬레이터가 있으면 `adb push` 후 재생은 Task 4 에서. 여기서는 파일 길이 · 크기만 출력해 확인.
- [ ] **Step 7: Commit** — `feat(walk): 직접 합성한 알람 벨소리 4개와 생성 스크립트를 더한다`

### Task 2: 도메인 · 스케줄러 · 이름

**Files:**
- Modify: `lib/domain/alarm/entity/alarm_sound.dart`, `lib/domain/alarm/entity/alarm.dart`(`draft()`), `lib/data/alarm/package_alarm_scheduler.dart`, `lib/data/alarm/channel_alarm_sound_source.dart`(`preview` switch 만), `lib/presentation/alarm/format/alarm_sound_format.dart`, `lib/presentation/alarm/cubit/alarm_sound_cubit.dart`(`_choiceOf` 컴파일만 — `FileAlarmSound() => AlarmSoundChoice.current(sound)` 임시), l10n arb 3개
- Test: `test/domain/alarm/entity/alarm_sound_test.dart`, `test/domain/alarm/entity/alarm_test.dart`, `test/data/alarm/package_alarm_scheduler_test.dart`, `test/data/alarm/channel_alarm_sound_source_test.dart`, `test/presentation/alarm/format/alarm_sound_format_test.dart`

**Interfaces:**
- Consumes: Task 1 `BundledAlarmSounds`.
- Produces: `const factory AlarmSound.file({required String title, required String path}) = FileAlarmSound;` JSON `{'type':'file','title':…,'path':…}`. `Alarm.draft().sound == AlarmSound.bundled(BundledAlarmSounds.morning)`. l10n 키 `walkAlarmSoundMorning` · `walkAlarmSoundMarimba` · `walkAlarmSoundClassic` · `walkAlarmSoundBirds`(ko 아침 차임 · 마림바 · 클래식 벨 · 새소리 / en Morning chime · Marimba · Classic bell · Birdsong / ja 朝のチャイム · マリンバ · クラシックベル · 鳥のさえずり). 옛 `walkAlarmSoundChime` · `walkAlarmSoundRising` 키는 지운다.

- [ ] **Step 1: 실패하는 테스트**
  - `alarm_sound_test`: `file` JSON 왕복; `fromJson({'type':'bundled','asset':'assets/alarm/chime.wav'}) == bundled(morning)`; `…rising.wav` → `bundled(classic)`; `default.wav` → `bundled(beep)` 그대로; `{'type':'file'}`(path 없음) → `system`.
  - `alarm_test`: `Alarm.draft().sound == AlarmSound.bundled(BundledAlarmSounds.morning)`; `const Alarm(hour: 7, minute: 0).sound == AlarmSound.system()`(그대로); 3종 → 4종 왕복.
  - `package_alarm_scheduler_test`: `file` + `fileExists: (_) => true` → `assetAudioPath == path`; `false` → `null`, `androidFallbackAudioPath == BundledAlarmSounds.beep`; `signatureFor` 가 같은 path 의 `device` 와 `file` 에서 서로 다르다.
  - `channel_alarm_sound_source_test`: `preview(AlarmSound.file(...))` 가 `{'kind':'uri','value': Uri.file(path).toString()}` 을 보낸다.
  - `alarm_sound_format_test`: 새 4개 이름(ko), `file` → title.
- [ ] **Step 2: 실패 확인** — `flutter test test/domain/alarm test/data/alarm test/presentation/alarm/format` → 컴파일 실패.
- [ ] **Step 3: 구현** — 위 Interfaces 대로. `fromJson` 의 옛 경로 옮기기는 `bundled` 분기 안에서 `legacyChime → morning`, `legacyRising → classic`. 스케줄러 지문 `'file:$path'`. `build_runner` 재생성, `flutter gen-l10n`.
- [ ] **Step 4: 통과 확인** — 위 명령 PASS, `flutter analyze` 0.
- [ ] **Step 5: Commit** — `feat(walk): 새 알람 기본을 아침 차임으로 하고 내 파일 알람음 모델을 더한다`

### Task 3: 내 파일에서 고르기 — 채널 · 큐빗 · 화면

**Files:**
- Modify: `android/app/src/main/kotlin/com/karma/walk/AlarmSoundsChannel.kt`, `MainActivity.kt`(액티비티 결과 연결)
- Create: `android/app/src/main/kotlin/com/karma/walk/AlarmFileRules.kt`, 테스트 `android/app/src/test/kotlin/com/karma/walk/AlarmFileRulesTest.kt`(기존 앱 Kotlin 테스트 위치를 따른다)
- Modify: `lib/domain/alarm/sound/alarm_sound_source.dart`, `lib/data/alarm/channel_alarm_sound_source.dart`, `lib/presentation/alarm/cubit/alarm_sound_{cubit,state}.dart`, `lib/presentation/alarm/page/alarm_sound_page.dart`, l10n arb 3개
- Test: `test/data/alarm/channel_alarm_sound_source_test.dart`, `test/presentation/alarm/cubit/alarm_sound_cubit_test.dart`, `test/presentation/alarm/page/alarm_sound_page_test.dart`

**Interfaces:**
- Consumes: Task 2 `AlarmSound.file` / `FileAlarmSound`.
- Produces:
  - `AlarmSoundSource.pickFile(): Future<AlarmSound?>` — 취소면 null, 실패면 `AlarmSoundException`. 채널 메서드 `pickFile` 은 `{'title': String, 'path': String}` 또는 null 을 돌려준다(취소). 오류 코드 `too_large` · `failed`.
  - Kotlin 순수 규칙 `object AlarmFileRules { const val MAX_BYTES = 30L * 1024 * 1024; fun isTooLarge(size: Long?): Boolean; fun titleOf(displayName: String?, fallback: String): String }` — `titleOf` 는 마지막 `.` 뒤 확장자를 떼고 공백을 다듬으며, 결과가 비면 `fallback`. fallback 은 Dart 가 채널 인자 `fallbackTitle` 로 넘긴 l10n "내 파일".
  - `AlarmSoundChoice.file(FileAlarmSound sound)` = `FileSoundChoice`; `AlarmSoundState.myFile: FileAlarmSound?`(초기 소리가 file 이면 그것); `AlarmSoundCubit.pickFile(): Future<PickFileResult>` 에서 `enum PickFileResult { picked, cancelled, failed }`.
  - l10n: `walkAlarmSoundFileSection`(내 파일 / My files / マイファイル), `walkAlarmSoundPickFile`(파일에서 고르기 / Choose a file / ファイルから選ぶ), `walkAlarmSoundFileDefaultTitle`(내 파일 / My file / マイファイル), `walkAlarmSoundFileFailed`(이 파일은 알람음으로 쓸 수 없어요 / This file can't be used as an alarm sound / このファイルはアラーム音に使えません).

- [ ] **Step 1: 실패하는 테스트**
  - Kotlin `AlarmFileRulesTest`: `isTooLarge(30MB) == false`, `isTooLarge(30MB+1) == true`, `isTooLarge(null) == false`; `titleOf("wake up.mp3","내 파일") == "wake up"`, `titleOf(".mp3", f) == f`, `titleOf(null, f) == f`, `titleOf("  a.b.ogg ", f) == "a.b"`.
  - 채널 소스: 모의 핸들러가 `{'title':'t','path':'/p'}` → `AlarmSound.file(title:'t', path:'/p')`; null → null; `PlatformException` → `AlarmSoundException`; 인자에 `fallbackTitle` 이 있다(소스는 생성 시 받거나 메서드 인자로 받는다 — `pickFile({required String fallbackTitle})` 로 둔다).
  - 큐빗: 성공 → `myFile` 설정 · `selected == AlarmSoundChoice.file(..)` · `preview` 호출 · 결과 `picked`; 취소 → 상태 그대로 · `cancelled`; 예외 → 상태 그대로 · `failed`; 초기 소리가 file 이면 `myFile` 과 `selected` 가 그 값, `confirm()` 이 `import` 없이 같은 값; 복사 중 `importing == true`.
  - 페이지: "내 파일" 구역과 "파일에서 고르기" 줄이 보인다; `myFile` 이 있으면 그 title 줄이 선택 상태; 실패 시 `walkAlarmSoundFileFailed` 스낵바; 새 소리 5개 이름이 보인다.
- [ ] **Step 2: 실패 확인** — `flutter test test/data/alarm test/presentation/alarm` 컴파일 실패, `cd android && JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew :app:testDebugUnitTest` 실패.
- [ ] **Step 3: Kotlin** — `pickFile`: 액티비티에서 `Intent(ACTION_OPEN_DOCUMENT).addCategory(CATEGORY_OPENABLE).setType("audio/*")`. 결과 uri 가 없으면 `success(null)`. 있으면 워커 스레드에서 `OpenableColumns` 로 이름 · 크기 → `isTooLarge` 면 `error("too_large")`, 아니면 기존 `importRingtone(uri)`(복사 중 크기 초과 시 중단하도록 `copyTo` 를 상한 있는 복사로 바꾼다) → `{'title','path'}`. 영구 URI 권한은 받지 않는다. 채널이 `applicationContext` 로 만들어지므로 액티비티 결과는 `MainActivity` 가 받아 채널에 넘긴다(`registerForActivityResult(OpenDocument())` 권장, `FlutterFragmentActivity` 다).
- [ ] **Step 4: Dart** — 위 Interfaces 대로 소스 · 상태 · 큐빗 · 화면. 화면: 기기 알람음 구역 뒤 `_SectionTitle(walkAlarmSoundFileSection)`, `myFile` 이 있으면 `_SoundRow(title, AlarmSoundChoice.file(myFile))`, 그 아래 `AppListTile(leading: Icon(Icons.audio_file), title: walkAlarmSoundPickFile, onTap: importing ? null : _pickFile)`. `_pickFile` 은 `failed` 면 `AppSnackBar.show(type: error)`. `build_runner`, `gen-l10n`.
- [ ] **Step 5: 통과 확인** — Dart · Kotlin 테스트 PASS, `flutter analyze` 0.
- [ ] **Step 6: Commit** — `feat(walk): 기기의 음성 파일을 골라 알람음으로 쓴다`

### Task 4: 검증 · 문서

**Files:**
- Modify: `apps/walk/docs/{README,plan,status,history,testing}.md`(해당 위치), 선행 스펙 링크 확인

- [ ] **Step 1:** `flutter analyze`(0) · `flutter test`(전체 통과) · `flutter build apk --debug` · 앱 Kotlin 테스트.
- [ ] **Step 2: 에뮬레이터** — 앱 설치 → 알람음 화면에서 새 소리 4개 미리 듣기(소리 출력은 `adb shell dumpsys audio` 의 활성 플레이어 / `dumpsys media.audio_flinger` 로 확인) → 1~2분 뒤 알람을 아침 차임으로 걸어 울림 확인 → `adb push` 한 mp3 를 내 파일로 골라 울림 확인 → 복사본(`app_flutter/alarm_sounds/…`) 을 `run-as` 로 지운 뒤 울려 무음이 아님(기기 기본음) 확인.
- [ ] **Step 3: 문서** — status(진행), history(결정 · 커밋), testing(새 테스트 · 에뮬레이터 시나리오), plan/README 의 알람음 설명. `flutter test test/convention`(apps/trader 의 문서 링크 테스트 포함).
- [ ] **Step 4: Commit** — `docs(walk): 알람 벨소리 번들 · 내 파일 고르기를 기록한다`
