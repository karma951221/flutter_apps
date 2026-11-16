# walk 알람 벨소리 — 기본 벨소리 다시 만들기 · 내 파일에서 고르기

날짜: 2026-11-16 · 앱: `apps/walk` · 선행 스펙: [알람음 선택](2026-10-05-walk-alarm-sound-design.md)

## 1. 왜

사용자 피드백(실사용): "지금 알람에서 벨소리가 없네 / 음원을 어디서 다운 받을 수도 없고".
이어서 정한 방향: "알람벨소리를 미리 만들어서 빌드하는게 나을까? 그리고 이미 있는 음성파일을 사용하는 것도 기능 넣고 싶은데".

## 2. 진단 — 지금 왜 "벨소리가 없다"고 느끼는가

코드와 에뮬레이터(2026-11-16)로 확인한 현재 모습:

| 항목 | 현재 | 문제 |
|---|---|---|
| 알람음 선택 화면 | 있다(`AlarmSoundPage`). 시스템 기본 · 앱 소리 3개 · 기기 알람음(RingtoneManager TYPE_ALARM) | 에뮬레이터에서는 목록이 정상이다. 실제 폰 확인은 아직 안 했다([status](../../../apps/walk/docs/status.md) "실제 폰 대기") |
| 앱 소리(`assets/alarm/*.wav`) | `default.wav`(비프) · `chime.wav` · `rising.wav`, 각각 22.05kHz 모노 약 3초 합성음 | 단순한 비프라 "벨소리"로 쓸 만한 것이 사실상 없다 |
| 내 음악 · 음성 파일 | 없다. 선행 스펙 §2 에서 "사용자 음악 파일 고르기"를 범위 밖으로 뺐다 | 원하는 소리를 넣을 방법이 없다 |
| 새 알람 기본값 | `AlarmSound.system()`(기기 기본 알람음) | 기기 기본음이 없거나 재생에 실패하면 비프로 대체된다 |
| 울릴 때 대체 | 포크 `androidFallbackAudioPath = BundledAlarmSounds.beep`, 복사본이 없으면 `assetAudioPath = null`(기기 기본) | 무음으로 끝나지 않는 장치는 이미 있다 |

결론: 버그라기보다 **고를 만한 소리가 부족하고, 내 파일을 쓸 길이 없다**. 그래서 두 가지를 더한다.

## 3. 목표 · 비목표 · 반목표

- 목표
  - 앱에 **직접 합성한** 벨소리 4개를 새로 넣고 그중 하나를 새 알람의 기본으로 한다.
  - 알람음 화면에서 **기기의 음성 파일을 골라** 알람음으로 쓴다.
  - 고를 때 미리 듣기(알람 볼륨 스트림, 이미 있음)가 새 소리 · 내 파일에도 된다.
- 비목표(v1)
  - 인터넷에서 음원 내려받기(저작권 · 신뢰 문제).
  - 내 파일 구간 자르기 · 여러 파일 재생 목록 · 안 쓰는 복사본 정리.
  - 새 부가 기능(진동 패턴 고르기 등). 볼륨 · 점점 커지기(페이드) · 진동은 이미 있다(웨이브 1 · 3).
- 반목표 — 이렇게 되면 실패다
  - 고른 파일이 지워졌거나 읽을 수 없어서 알람이 **소리 없이** 끝난다.
  - 이미 걸린 회차(최대 14일)가 에셋 경로가 바뀌어 소리 없이 울린다.
  - 저작권이 불분명한 음원이 앱에 들어간다.

## 4. 접근

| 안 | 내용 | 판단 |
|---|---|---|
| A. 기본 벨소리 번들 | 스크립트로 합성한 음원을 에셋으로 넣는다 | **채택**. 저작권 걱정이 없고 어느 폰에서나 같다 |
| B. 내 파일 고르기 — 앱 저장소로 복사 | 문서 선택기로 고른 뒤 바로 `app_flutter/alarm_sounds/` 로 복사하고 그 경로로 울린다 | **채택**. 기기 알람음과 같은 길(`importRingtone`)을 탄다. 원본이 지워지거나 권한이 사라져도 울리고, 포크가 `content://` 를 못 읽는 제약도 피한다 |
| B'. 내 파일 고르기 — URI 만 보관 | 영구 URI 권한(`takePersistableUriPermission`)으로 원본을 직접 재생 | 버림. 포크 `AudioService` 가 `content://` 를 못 읽어 포크를 또 고쳐야 하고, 원본 이동 · 삭제 · SD 카드 분리 · 권한 회수 때 울리는 순간에야 실패한다 |
| C. 외부 CC0 음원 | freesound 등에서 받아 넣는다 | 버림(기본안). 합성으로 충분하고 출처 관리가 필요 없다. 쓰게 되면 `assets/alarm/LICENSES.md` 에 출처 · 라이선스를 남긴다 |
| D. 인터넷 내려받기 | 앱에서 음원 검색 · 다운로드 | 범위 밖(§3) |

시스템 벨소리 목록(기기 알람음 구역)은 **그대로 둔다** — 이미 있고 에뮬레이터에서 동작한다.

## 5. 기본 벨소리 번들

### 5.1 소리 목록

| 키(`BundledAlarmSounds`) | 파일 | 이름(ko / en / ja) | 성격 |
|---|---|---|---|
| `morning`(**새 기본**) | `assets/alarm/morning.ogg` | 아침 차임 / Morning chime / 朝のチャイム | 맑은 벨 아르페지오(장3화음 위로), 부드러운 감쇠 |
| `marimba` | `assets/alarm/marimba.ogg` | 마림바 / Marimba / マリンバ | 나무 타악기풍 짧은 멜로디 |
| `classic` | `assets/alarm/classic.ogg` | 클래식 벨 / Classic bell / クラシックベル | 탁상 자명종처럼 빠르게 두드리는 금속 벨 |
| `birds` | `assets/alarm/birds.ogg` | 새소리 / Birdsong / 鳥のさえずり | 주파수가 휘는 짧은 지저귐 여러 개 |
| `beep`(유지) | `assets/alarm/default.wav` | 비프 / Beep / ビープ | 기존 그대로 |

- 형식: OGG Vorbis, 모노 44.1kHz(또는 22.05kHz), 한 번에 3~6초짜리 **루프**(끝과 처음이 이어져도 튀지 않게 끝을 0 으로 감쇠).
  합계 목표 500KB 이하.
- 기존 `chime.wav` · `rising.wav` 는 **목록에서 빼되 파일은 남긴다**. 이미 저장된 알람과 이미 걸린 회차가 그 경로를 가리키기 때문이다.
  - 저장된 알람: `AlarmSound.fromJson` 에서 `assets/alarm/chime.wav` → `morning`, `assets/alarm/rising.wav` → `classic` 으로 옮겨 읽는다.
    (예약 지문이 바뀌어 다음 sync 때 새 소리로 다시 걸린다.)
  - 이미 걸린 회차는 남겨 둔 wav 로 울린다. 파일 삭제는 다음 버전에서 한다(이 스펙 범위 밖).
- `default.wav`(비프)는 이름 · 경로를 바꾸지 않는다(선행 스펙 §10 "기존 비프음 파일 이름 그대로" 결정 유지).

### 5.2 기본값 · 대체음

- **새 알람의 기본 소리**: `AlarmSound.bundled(BundledAlarmSounds.morning)`. 기존 알람은 저장된 값을 그대로 쓴다(`system` 이면 계속 시스템 기본).
  - `fromJson` 의 "모르는 값이면 `system`" 규칙은 유지한다 — 옛 알람이 갑자기 다른 소리로 바뀌지 않게.
- **울릴 때 대체음**(`androidFallbackAudioPath`): 비프 그대로 둔다. 이미 검증된 wav 이고, 대체음은 "무엇이든 울린다"가 목적이다.

### 5.3 합성 스크립트

- 위치: `apps/walk/tool/alarm_sounds/generate.py`(+ 같은 폴더 `README.md`: 실행법 · 각 소리 설계 · 라이선스 "직접 생성, 저장소 라이선스를 따름").
- numpy 로 파형을 만들고 OGG 로 쓴다. 이 맥에는 sox · ffmpeg · oggenc 가 없으므로 인코더는 구현자가 정한다
  (예: `pip install soundfile` 의 libsndfile Vorbis, 또는 `brew install ffmpeg`). README 에 쓴 도구와 버전을 남긴다.
- 같은 입력이면 같은 출력이 나오게 난수는 고정 seed.
- 에셋 폴더에 `assets/alarm/README.md` 를 두어 각 파일의 출처(= 이 스크립트)와 라이선스를 적는다.

## 6. 내 파일에서 고르기

### 6.1 흐름

1. 알람음 화면 맨 아래에 **"내 파일"** 구역. 줄 하나: "파일에서 고르기…"(아이콘 `Icons.audio_file`). 이미 내 파일을 쓰는 알람이면 그 파일 이름 줄이 선택된 채로 위에 보인다.
2. 누르면 네이티브 문서 선택기(`ACTION_OPEN_DOCUMENT`, `CATEGORY_OPENABLE`, MIME `audio/*`)가 뜬다.
   권한 요청은 필요 없다(SAF). 영구 URI 권한은 받지 않는다 — 곧바로 복사하므로.
3. 고르면 즉시 앱 저장소로 복사 · 검증(`MediaPlayer.prepare`)하고, 성공하면 그 줄이 선택되며 미리 듣기가 시작된다.
   - 복사는 기존 `importRingtone(uri)` 를 그대로 쓴다(임시 파일 → 검증 → 교체). 복사 중에는 기존 `importing` 상태(선택 버튼 로딩).
   - 이름은 `OpenableColumns.DISPLAY_NAME` 에서 확장자를 뺀 것. 없으면 "내 파일".
4. 취소하면 아무것도 바뀌지 않는다. 실패(읽기 불가 · 형식 불가 · 너무 큼)면 `AppSnackBar` 오류 하나: "이 파일은 알람음으로 쓸 수 없어요".
5. "선택"을 누르면 결과로 돌려준다(기존 화면 규칙과 같다).

### 6.2 크기 제한

- 30MB 초과면 복사 전에 거절한다(`OpenableColumns.SIZE`, 모르면 복사하며 세다가 넘으면 중단). 긴 음악 한 곡(MP3 ~10MB)은 넉넉히 들어간다.

### 6.3 모델

- `AlarmSound` 에 변형 하나를 더한다: `AlarmSound.file({required String title, required String path})` — JSON `{'type':'file','title':…,'path':…}`.
  - `device` 와 저장 · 재생 방식은 같지만, 화면에서 "기기 알람음 목록"이 아니라 "내 파일" 구역에 보여야 하고
    기기 목록과 제목으로 맞추는 로직(`CurrentSoundChoice`)에 섞이면 안 되므로 따로 둔다.
  - 스케줄러: `device` 와 같이 `fileExists(path) ? path : null`. 지문은 `'file:$path'`.
  - 미리 듣기: `('uri', Uri.file(path))`.
- `AlarmSoundSource` 에 `Future<AlarmSound?> pickFile()` 을 더한다(취소면 null, 실패면 `AlarmSoundException`). 채널 메서드 `pickFile`.
- 복사본 이름은 기존처럼 uri 의 SHA-1 앞 16자. 같은 파일을 다시 고르면 같은 복사본을 덮어쓴다.

### 6.4 울릴 때 — 무음 방지

순서대로 시도한다(이미 있는 장치를 그대로 쓴다):

1. 복사본이 있으면 그 경로, 없으면(`fileExists` 거짓) `null` = 기기 기본 알람음.
2. 1이 재생에 실패하면 포크 대체음(비프).

원본 파일이 지워져도 복사본으로 울리므로 영향이 없다. 복사본이 사라진 경우(앱 데이터 정리 등)는 위 규칙대로 기기 기본음 → 비프.

## 7. 화면 변화 요약

```
알람음
  ◉ 시스템 기본
 앱 소리
  ○ 아침 차임      ← 새 알람 기본
  ○ 마림바
  ○ 클래식 벨
  ○ 새소리
  ○ 비프
 기기 알람음
  ○ Argon …
 내 파일
  ○ wake_up_song   ← 고른 파일이 있을 때만
  ♪ 파일에서 고르기…
 [ 선택 ]
```

- 줄을 누르면 지금처럼 바로 미리 듣기. 공통 위젯(`AppListTile` · `AppSnackBar` · `AppPlaceholder`)과 토큰만 쓴다.
- 문구는 `packages/l10n` 의 ko · en · ja 세 언어에 더한다.

## 8. 테스트 · 확인

- Dart 단위: `AlarmSound` JSON(새 변형 · 옛 wav 경로 옮겨 읽기 · 모르는 값 → system), `Alarm` 기본 소리,
  `settingsFor`(file 변형 · 파일 없음 → null · 지문), `AlarmSoundFormat` 이름, `AlarmSoundCubit`(pickFile 성공 · 취소 · 실패),
  화면 위젯 테스트(내 파일 구역 · 새 소리 목록). 위치는 `test/` 아래 구현 경로 그대로.
- 컨벤션: `pubspec.yaml` 에셋 목록에 있는 `BundledAlarmSounds.all` 파일이 실제로 있는지 보는 테스트.
- Kotlin: 크기 제한 · 표시 이름 다듬기 같은 순수 규칙은 함수로 빼서 JUnit.
- 에뮬레이터: 새 소리 미리 듣기, 내 파일(에뮬레이터에 `adb push` 한 mp3) 고르기 → 1분 뒤 알람이 그 소리로 울림,
  복사본을 지운 뒤 울림이 무음이 아님을 확인.
- 완료 조건: `flutter analyze` 0, 테스트 통과, 문서(README · plan · status · history · testing) 갱신, 브랜치 커밋.

## 9. 구현자에게 남긴 것

- 각 소리의 정확한 음정 · 길이 · 엔벨로프(§5.1 성격 안에서), OGG 인코더 선택.
- 문서 선택기를 `MainActivity` 의 `registerForActivityResult` 로 받을지 `onActivityResult` 로 받을지.
- "파일에서 고르기" 줄의 정확한 아이콘 · 보조 문구.

## 10. 결정 기록

| 결정 | 근거 |
|---|---|
| 번들 음원은 직접 합성(외부 음원 안 씀) | 저작권 걱정 없음. 생성 스크립트를 남겨 다시 만들 수 있다 |
| 내 파일은 고르는 즉시 복사(URI 보관 안 함) | 원본 삭제 · 권한 회수에도 울린다. 포크가 `content://` 를 못 읽는 제약을 피하고 기존 복사 · 검증 코드를 재사용한다 |
| 새 알람 기본 = 아침 차임, 기존 알람은 그대로 | 사용자가 처음 만드는 알람부터 "벨소리"가 있게. 이미 쓰던 알람 소리를 몰래 바꾸지 않는다 |
| 옛 `chime.wav` · `rising.wav` 는 새 소리로 옮겨 읽되 파일은 남김 | 이미 걸린 회차가 무음이 되지 않게 |
| 대체음은 비프 유지 | 검증된 wav. 바꾸면 모든 예약 지문이 바뀌어 다시 걸린다 |
| 시스템 벨소리 목록 유지 · 진동/페이드 새로 안 만듦 | 이미 있다. v1 을 작게 |
| `AlarmSound.file` 변형을 따로 둠 | 화면 구역이 다르고 기기 목록 제목 매칭과 섞이지 않게 |
