# Life Log 앱 백업 · 복원 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Every task is TDD (superpowers:test-driven-development): failing test first, watch it fail, then code.

**Goal:** 설정에서 앱 데이터(영역 선택)를 zip 하나로 내보내고(선택 암호화), 그 파일로 영역별 바꿔 넣기 복원 · 되돌리기를 한다.

**Architecture:** 영역마다 `BackupAreaSource`(내보내기 · 검증 · 바꿔 넣기 · 복원 후 처리)를 두고, `BackupService` 가
영역들을 모아 작업 폴더 → zip → (암호 컨테이너) 로 만들고, 반대로 풀어 검증한 뒤 되돌리기 지점을 만들고 영역을 차례로
바꾼다. 파일 저장 · 열기 · 앱 재시작은 작은 네이티브 채널이 맡는다. 복원이 끝나면 앱을 다시 시작해 prefs 를 읽어 둔
cubit 과 DB 싱글턴을 새로 만든다.

**Tech Stack:** Flutter · drift · `archive` ^4.0 · `cryptography` ^2.7 (+ `cryptography_flutter` ^2.3 앱 실행 시 가속) ·
flutter_bloc · freezed · injectable · Kotlin MethodChannel.

**Spec:** [docs/superpowers/specs/2026-11-16-walk-diary-backup-design.md](../specs/2026-11-16-walk-diary-backup-design.md)

## Global Constraints

- 루트 `CLAUDE.md` 규칙: 공통 위젯(`AppListTile` · `AppButton` · `AppConfirmDialog` · `AppSnackBar` · `AppLoading`) · 토큰만, Freezed 두 패턴, 생성 파일은 build_runner, 테스트는 `test/` 에서 `lib/` 구조 그대로.
- 다른 세션과 겹치는 파일(설정 화면 · l10n arb · 채팅 DB)은 필요한 줄만 더한다. 채팅 DB 스키마는 main 머지 뒤 실제 `schemaVersion` 을 쓴다.
- 영역 id(문자열, manifest 키): `diary` · `chat` · `wiki` · `alarm` · `settings` · `location`. 기본 체크: `location` 만 끔.
- manifest: `format = "lifelog.backup"`, `formatVersion = 1`. 파일 이름 `lifelog-backup-YYYYMMDD-HHmm.zip` / 암호화 `.lifelog`.
- 암호 컨테이너: 매직 `LLBK`, 컨테이너 버전 1, PBKDF2-HMAC-SHA256 **600,000회**, salt 16B, nonce 접두 8B, AES-256-GCM, 덩어리 **1 MiB**, nonce = 접두 ‖ 덩어리 번호(4B big-endian), AAD = 헤더 바이트 ‖ 덩어리 번호 ‖ 마지막 여부(1B). 비밀번호 8자 이상.
- 절대 담지 않는 prefs/저장소: `chat.apiKey` · `anthropic_api_key` · `chat.keyStatus` · `chat.consentedVendor` · `chat.consented` · `chat.consentScope` · `walk.lock.*` · 캐시(`walk.holidays.cache` · `weather.cache.v1` · `chat.models*`) · 네이티브 prefs 전부.
- 폴더(문서 폴더 = `app_flutter` 기준): 작업 `restore_staging/`, 되돌리기 `restore_undo/`, 진행 표시 파일 `restore_undo/in_progress.json`.
- main 머지 · 푸시 금지. 커밋은 이 브랜치에만.

## Review Focus

1. **공간 부족 · 도중 종료**: 복원 중 앱이 죽으면 다음 시작에서 되돌리기 지점으로 전부 되돌아가야 한다 → Task 6 `recovers interrupted restore on startup`.
2. **빈 앱에서 복원**(새 폰: 일기는 기본 스토리만, 알람 0개, `alarm_sounds/` 없음) → Task 3 · 5 테스트가 빈 대상 폴더 · 없는 폴더에서 시작.
3. **알람음 절대 경로**가 다른 기기 경로를 가리킴 → Task 5 `rewrites device sound path to current alarm_sounds dir`, 파일이 없으면 `AlarmSound.system()`.
4. **새 prefs 키가 생겨도 백업에 섞이지 않음** → Task 5 `settings export contains exactly the allowlist`.
5. **잠긴 일기에서 백업 우회** → Task 8 `backup rows disabled while diary locked`.

---

### Task 1: 의존성 · 암호 컨테이너

**Files:**
- Modify: `apps/walk/pubspec.yaml` (`archive: ^4.0.0`, `cryptography: ^2.7.0`, `cryptography_flutter: ^2.3.2`)
- Create: `apps/walk/lib/data/backup/crypto/backup_cipher.dart`
- Test: `apps/walk/test/data/backup/crypto/backup_cipher_test.dart`

**Interfaces:**
- Produces:
  - `enum BackupFileKind { zip, encrypted, unknown }` · `Future<BackupFileKind> sniffBackupFile(File f)` (첫 4바이트 `PK\x03\x04` / `LLBK`)
  - `class BackupCipher { BackupCipher({int iterations = 600000}); Future<void> encrypt(File plain, File out, String password); Future<void> decrypt(File sealed, File out, String password); }` — 실패 시 `BackupCipherException(BackupCipherError.wrongPasswordOrCorrupt | notEncrypted)`.

- [ ] **Step 1: 실패하는 테스트** — `iterations: 1000` 으로:
  - `round trips 0 B, 1 B, exactly 1 MiB, 2.5 MiB` → 바이트 같음
  - `wrong password fails with wrongPasswordOrCorrupt`
  - `flipped byte in second chunk fails` · `truncated last chunk fails` · `swapped chunks fail`
  - `header records iterations and salt; two encryptions differ` (salt 무작위)
  - `sniffBackupFile` 세 경우
- [ ] **Step 2:** `flutter test test/data/backup/crypto` → FAIL(없는 파일)
- [ ] **Step 3: 구현** — `cryptography` 의 `Pbkdf2(macAlgorithm: Hmac.sha256(), iterations, bits: 256)` · `AesGcm.with256bits()`. 파일은 `RandomAccessFile` 로 1 MiB 씩 읽고 쓴다(전체를 메모리에 올리지 않음). 마지막 덩어리 플래그로 잘라내기를 잡는다(빈 평문도 마지막 덩어리 1개). 앱 시작 시 `FlutterCryptography.enable()` 는 Task 8 에서.
- [ ] **Step 4:** 테스트 PASS
- [ ] **Step 5:** 커밋 `feat(walk): 백업 파일 암호 컨테이너를 더한다`

### Task 2: manifest · zip 쓰기/읽기

**Files:**
- Create: `apps/walk/lib/domain/backup/backup_area_id.dart` (`enum BackupAreaId { diary, chat, wiki, alarm, settings, location }`, `bool get defaultSelected => this != location`)
- Create: `apps/walk/lib/domain/backup/backup_manifest.dart` (Freezed 단일 모델 + `fromJson`/`toJson` 손으로)
- Create: `apps/walk/lib/domain/backup/backup_failure.dart`
- Create: `apps/walk/lib/data/backup/archive/backup_archive.dart`
- Test: `apps/walk/test/domain/backup/backup_manifest_test.dart`, `apps/walk/test/data/backup/archive/backup_archive_test.dart`

**Interfaces:**
- Produces:
  - `BackupManifest { String format; int formatVersion; String appVersion; DateTime createdAt; Map<BackupAreaId, AreaManifest> areas; List<ManifestFile> files; }`, `AreaManifest { Map<String,int> schema; Map<String,int> counts; }`, `ManifestFile { String path; int bytes; String sha256; }`. 모르는 영역 키는 읽을 때 버린다.
  - `enum BackupFailure { notBackup, newerFormat, newerAreaSchema, wrongPasswordOrCorrupt, integrity, noSpace, cancelled, io }` → `Failure toFailure()` (기존 `DiaryFailure.toFailure` 패턴).
  - `class BackupArchive { Future<void> pack(Directory staging, BackupManifest manifestWithoutFiles, File out); Future<BackupManifest> unpack(File zip, Directory into); }` — `pack` 은 staging 아래 모든 파일의 bytes · sha256 을 채워 `manifest.json` 을 맨 앞에 쓰고, `.jpg/.mp4/.m4a/.mp3/.ogg/.wav` 는 store, 나머지 deflate. `unpack` 은 `format` · `formatVersion`(>1 이면 `newerFormat`) · 경로 탈출(`..`, 절대 경로 → `integrity`) · 모든 파일 sha256 · manifest 에 없는 파일(→ `integrity`)을 검사하고 실패면 `into` 를 지우고 `BackupException(BackupFailure)` 를 던진다.

- [ ] **Step 1: 실패하는 테스트** — `manifest json round trip`, `unknown area key ignored`; `pack then unpack restores files byte-equal`, `tampered file → integrity`, `zip-slip entry → integrity`, `formatVersion 2 → newerFormat`, `not a lifelog zip → notBackup`, `failed unpack leaves no staging dir`.
- [ ] **Step 2:** FAIL 확인
- [ ] **Step 3: 구현** — `archive` 4 의 `ZipFileEncoder`(파일 스트림) / `ZipDecoder().decodeStream(InputFileStream)`. sha256 은 `crypto` 의 `sha256.bind(file.openRead())`.
- [ ] **Step 4:** PASS
- [ ] **Step 5:** 커밋 `feat(walk): 백업 manifest 와 zip 읽기 · 쓰기를 더한다`

### Task 3: 영역 포트 · 일기 영역

**Files:**
- Create: `apps/walk/lib/domain/backup/backup_area_source.dart`
- Create: `apps/walk/lib/data/backup/area/drift_rows.dart` (drift 테이블 ↔ JSON 행 공용 도우미)
- Create: `apps/walk/lib/data/backup/area/diary_backup_area.dart`
- Create: `apps/walk/lib/data/backup/area/dir_swap.dart` (폴더 바꿔 넣기)
- Test: `apps/walk/test/data/backup/area/diary_backup_area_test.dart`, `apps/walk/test/data/backup/area/dir_swap_test.dart`

**Interfaces:**
- Produces:
  ```dart
  abstract interface class BackupAreaSource {
    BackupAreaId get id;
    Map<String, int> get schema;              // 예: {'diary': 1}
    Future<Map<String, int>> counts();        // 시트 표시용
    Future<int> estimatedBytes();             // 공간 검사용
    Future<Map<String, int>> export(Directory root); // root/<id>/ 에 쓴다, counts 반환
    Future<void> validate(Directory root);    // 참조 무결성, 실패 시 BackupException(integrity)
    Future<void> replace(Directory root);     // 지금 데이터를 root/<id>/ 것으로. 영역 안에서 원자적
    Future<void> afterRestore();              // 기본 no-op
  }
  ```
  - `Future<void> swapDirectory(Directory current, Directory incoming, Future<void> Function() commit)` — `current`→`current.old`, `incoming`→`current`, `commit()`(DB 트랜잭션) 실패 시 되돌리고 rethrow, 성공 시 `.old` 삭제. `current` 가 없어도 동작.
  - `DiaryBackupArea(DiaryDatabase db, @Named('diaryRoot') Directory diaryRoot, DiaryPreferences prefs)` — 파일: `diary/data.json`(6 테이블), `diary/media/…`, `diary/prefs.json`(`walk.diary.trashRetention` · `walk.diary.draft.style` · `walk.diary.draft.includePhotos`). `replace` 는 한 트랜잭션에서 `entryTags, media, entries, tags, places, stories` 순 삭제 · 역순 삽입, 기본 스토리 없으면 `Story.dailyId` 로 만든다.

- [ ] **Step 1: 실패하는 테스트** (`DiaryHarness` 재사용, 임시 폴더 2개=기기 A · B):
  - `round trip: A export → B replace → all six tables row-equal and media bytes equal` (휴지통 기록 · 동영상+썸네일 포함)
  - `replace into empty device keeps daily story`
  - `validate rejects entry pointing to missing story / media pointing to missing entry`
  - `export skips diary/tmp/`
  - dir_swap: `commit failure restores original dir`, `missing current dir ok`, `leaves no .old on success`
- [ ] **Step 2:** FAIL 확인
- [ ] **Step 3: 구현** — `drift_rows.dart`: `Future<List<Map<String,Object?>>> dumpTable(GeneratedDatabase db, TableInfo t)` = `customSelect('SELECT * FROM ${t.actualTableName}')` 의 `data`; 삽입은 `customInsert` 로 컬럼 그대로(`storeDateTimeAsText` 라 문자열 그대로 옮겨진다). 일기 prefs 는 `SharedPreferences` 를 직접 받는 대신 `PrefsSnapshot`(Task 5) 을 쓰면 겹치니, 이 Task 에서는 `diary/prefs.json` 을 `SharedPreferences` 직접 읽기/쓰기로 하고 Task 5 에서 공용 도우미로 뽑는다.
- [ ] **Step 4:** PASS
- [ ] **Step 5:** 커밋 `feat(walk): 일기 백업 영역을 더한다`

### Task 4: 대화 · 위키 영역

**Files:**
- Create: `apps/walk/lib/data/backup/area/chat_backup_area.dart`, `apps/walk/lib/data/backup/area/wiki_backup_area.dart`
- Test: `apps/walk/test/data/backup/area/chat_backup_area_test.dart`, `apps/walk/test/data/backup/area/wiki_backup_area_test.dart`

**Interfaces:**
- Consumes: `BackupAreaSource` · `drift_rows.dart` · `swapDirectory` (Task 3)
- Produces: `ChatBackupArea(ChatDatabase db, Workspace root dir, SharedPreferences)` — main 머지 뒤 `chat_tables.dart` 의 **위키를 뺀 모든 테이블**(대화 · 턴 · 사용량 + 머지로 생긴 테이블이 있으면 그 성격을 보고 판단, 동의 · 키 관련은 빼기) · `workspace/` 폴더 · prefs `walk.chat.retention` · `walk.chat.useRecords`. `WikiBackupArea(ChatDatabase db, SharedPreferences)` — `wiki_notes`(정수 id 유지) · `walk.chat.wikiIndexSize`. schema 둘 다 `{'chat': db.schemaVersion}`.

- [ ] **Step 1: 실패하는 테스트**
  - `chat round trip incl. attachments json and workspace files`
  - `wiki round trip keeps integer ids and autoincrement continues after max id`
  - `wiki restore nulls sourceConversationId whose conversation is absent`
  - `chat replace leaves wiki_notes untouched` · `wiki replace leaves conversations untouched`
  - `chat replace nulls wiki sourceConversationId pointing to removed conversations` (FK `setNull` 이 트랜잭션 안에서 동작하는지 확인)
- [ ] **Step 2:** FAIL 확인
- [ ] **Step 3: 구현** — 위키 삽입 뒤 `sqlite_sequence` 를 최대 id 로 맞춘다(테스트가 잡음).
- [ ] **Step 4:** PASS
- [ ] **Step 5:** 커밋 `feat(walk): 물어보기 대화 · 위키 백업 영역을 더한다`

### Task 5: 알람 · 설정 · 위치 영역

**Files:**
- Create: `apps/walk/lib/data/backup/area/prefs_snapshot.dart` (허용 목록 prefs ↔ `{key:{type,value}}`; Task 3 의 일기 prefs 도 이걸로 바꾼다)
- Create: `apps/walk/lib/data/backup/area/alarm_backup_area.dart`, `settings_backup_area.dart`, `location_backup_area.dart`
- Test: 같은 이름 `_test.dart` 3개 + `prefs_snapshot_test.dart`

**Interfaces:**
- Produces:
  - `Future<Map<String,Object?>> dumpPrefs(SharedPreferences p, Set<String> keys)` · `Future<void> restorePrefs(SharedPreferences p, Set<String> keys, Map json)` (목록 키를 먼저 지우고 쓴다; 타입 `bool|int|double|string|stringList`).
  - `AlarmBackupArea(SharedPreferences, RingArchiveDatabase, Directory alarmSoundsDir, AlarmUseCase)` — prefs `walk.alarms` · `walk.holidayReminder` · `walk.pauseFrom` · `walk.pauseUntil`, `alarm/sounds/`, `alarm/ring_archive.json`. `replace` 는 `walk.alarms` 의 `device`/`file` 소리 경로를 `<alarmSoundsDir>/<파일 이름>` 으로 다시 쓰고, 파일이 없으면 `AlarmSound.system()` 으로 바꾼다(JSON 은 기존 알람 저장소의 직렬화 함수를 거친다). `afterRestore` = `alarmUseCase.sync()`. `alarmSoundsDir` = `getDir("flutter")/alarm_sounds` = 문서 폴더 + `alarm_sounds` (DI 에 `@Named('alarmSoundsRoot')` 추가).
  - `SettingsBackupArea(SharedPreferences)` — 허용 목록: `walk.themeMode` · `walk.stepGoal` · `walk.map.style` · `walk.location.retention` · `chat.vendor` · `chat.model` · `chat.fastMode` · `chat.fastMode.ack` · `commute.place.home` · `commute.place.work`. 머지 뒤 새 키가 있으면 성격을 보고 넣거나 뺀다.
  - `LocationBackupArea(LocationDatabase)` — 모든 테이블. `afterRestore` no-op(서비스 상태는 건드리지 않음).

- [ ] **Step 1: 실패하는 테스트**
  - `settings export contains exactly the allowlist` (secret · lock · cache 키를 심어도 안 나옴)
  - `restorePrefs removes allowlisted keys absent from backup`
  - `alarm round trip`, `rewrites device sound path to current alarm_sounds dir`, `missing sound file falls back to system`, `afterRestore calls sync once` (mocktail)
  - `restore into device without alarm_sounds dir`
  - `location round trip`
- [ ] **Step 2:** FAIL 확인
- [ ] **Step 3: 구현**
- [ ] **Step 4:** PASS
- [ ] **Step 5:** 커밋 `feat(walk): 알람 · 설정 · 위치 백업 영역을 더한다`

### Task 6: BackupService — 내보내기 · 검사 · 복원 · 되돌리기 · 시작 복구

**Files:**
- Create: `apps/walk/lib/domain/backup/backup_service.dart` (인터페이스 + 결과 모델), `apps/walk/lib/data/backup/default_backup_service.dart`
- Create: `apps/walk/lib/domain/backup/backup_preferences.dart` + `apps/walk/lib/data/backup/prefs_backup_preferences.dart` (`walk.backup.lastAt`)
- Modify: `apps/walk/lib/core/di/register_module.dart` (영역 목록 `List<BackupAreaSource>` 등록, `@Named('appDocs')`)
- Test: `apps/walk/test/data/backup/default_backup_service_test.dart`

**Interfaces:**
- Consumes: Task 1–5 전부
- Produces:
  ```dart
  abstract interface class BackupService {
    Future<Map<BackupAreaId, AreaPreview>> preview();                         // counts + bytes
    Future<Result<File>> export(Set<BackupAreaId> areas, {String? password}); // 캐시의 완성 파일
    Future<Result<InspectedBackup>> inspect(File file, {String? password});   // staging 에 풀고 검증
    Future<Result<void>> restore(InspectedBackup b, Set<BackupAreaId> areas);
    Future<bool> hasUndoPoint();
    Future<Result<void>> undo();
    Future<void> recoverIfInterrupted();                                       // 앱 시작 때
    Future<void> discard(InspectedBackup b);                                   // staging 지우기
  }
  ```
  `InspectedBackup { BackupManifest manifest; Directory staging; Map<BackupAreaId, AreaAvailability> areas; }`, `enum AreaAvailability { ok, newerSchema }`.
- 동작: `restore` = (1) `restore_undo/` 를 비우고 고른 영역을 그곳에 `export` (2) `in_progress.json`(영역 목록) 쓰기 (3) 영역마다 `validate` → `replace` (4) 하나라도 실패하면 이미 바꾼 영역을 `restore_undo/` 로 `replace` 하고 `Err` (5) 성공하면 `in_progress.json` 지우고 영역마다 `afterRestore`, staging 삭제. `undo` = `restore_undo/` 를 같은 순서로 replace(되돌리기 전 지점은 만들지 않음) 후 undo 폴더 삭제. `recoverIfInterrupted` = `in_progress.json` 이 있으면 그 영역들을 undo 로 replace 하고 표시 파일 · staging 삭제. 여유 공간 검사는 `estimatedBytes` 합 × 1(내보내기) / 백업 크기 × 2(복원)와 비교 — 여유 공간 읽기는 주입 함수 `Future<int?> Function() freeBytes`(null 이면 건너뜀).

- [ ] **Step 1: 실패하는 테스트** (가짜 영역 + 실제 일기 영역 섞어서)
  - `full export → wipe → inspect → restore round trip, encrypted and plain` (모든 실제 영역 6개, 메모리 DB)
  - `restoring subset leaves other areas untouched`
  - `failure in second area rolls back first area`
  - `recovers interrupted restore on startup`
  - `undo returns to pre-restore state`; `hasUndoPoint` 전이
  - `newer area schema marks area newerSchema and restore refuses it`
  - `wrong password → wrongPasswordOrCorrupt, data untouched`
  - `backup contains no secret keys` (전체 zip 을 풀어 모든 JSON 에서 `apiKey` · `walk.lock` · `consented` · `keyStatus` 문자열이 없음)
  - `noSpace when freeBytes too small`
  - `lastAt written only on successful export`
- [ ] **Step 2:** FAIL 확인
- [ ] **Step 3: 구현** — 압축 · 해시 · 암호화는 `Isolate.run`(테스트에서는 그대로 실행돼도 됨).
- [ ] **Step 4:** PASS
- [ ] **Step 5:** 커밋 `feat(walk): 백업 서비스로 내보내기 · 복원 · 되돌리기를 묶는다`

### Task 7: 네이티브 파일 채널 · 재시작 · 자동 백업 규칙

**Files:**
- Create: `apps/walk/android/app/src/main/kotlin/com/karma/walk/BackupFileChannel.kt` (+ `MainActivity` 등록)
- Create: `apps/walk/lib/data/backup/channel_backup_files.dart` (+ `domain/backup/backup_files.dart` 인터페이스)
- Modify: `apps/walk/android/app/src/main/res/xml/backup_rules.xml`, `data_extraction_rules.xml`
- Modify: `apps/walk/lib/main.dart` (`recoverIfInterrupted` 를 `configureDependencies` 뒤, `runApp` 전에; `FlutterCryptography.enable()`)
- Test: `apps/walk/test/data/backup/channel_backup_files_test.dart` (MethodChannel mock), Kotlin JUnit 은 복사 함수 하나(`copyStream`)만

**Interfaces:**
- Produces: `abstract interface class BackupFiles { Future<bool> saveAs(File source, String suggestedName); Future<File?> open(); Future<void> restartApp(); }` — 채널 `com.karma.walk/backup_file`, 메서드 `saveAs{path,name,mime}` → `ACTION_CREATE_DOCUMENT` 후 스트림 복사(취소면 false), `open` → `ACTION_OPEN_DOCUMENT`(`*/*`) 후 캐시 `backup_import/` 로 스트림 복사해 경로 반환, `restart` → 런처 인텐트 `makeRestartActivityTask` 후 `Runtime.getRuntime().exit(0)`.
- 규칙: §7 그대로 — cloud(둘 다)에서 `root` 도메인 `app_flutter/diary/` · `app_flutter/workspace/` · `app_flutter/restore_staging/` · `app_flutter/restore_undo/`, device-transfer 에서 `restore_*` 둘만. 기존 주석 형식을 따른다.

- [ ] **Step 1: 실패하는 테스트** — 채널 인자 · 반환 매핑, 취소(null) 처리.
- [ ] **Step 2:** FAIL 확인
- [ ] **Step 3: 구현**
- [ ] **Step 4:** PASS + `cd apps/walk/android && ./gradlew :app:testDebugUnitTest` PASS
- [ ] **Step 5:** 커밋 `feat(walk): 백업 파일 저장 · 열기 채널과 자동 백업 규칙을 더한다`

### Task 8: 화면 — 백업 페이지 · 내보내기 시트 · 복원 흐름

**Files:**
- Create: `apps/walk/lib/presentation/backup/cubit/backup_cubit.dart`, `backup_state.dart` (freezed union)
- Create: `apps/walk/lib/presentation/backup/page/backup_page.dart`, `widget/export_sheet.dart`, `widget/restore_areas_sheet.dart`, `widget/backup_password_dialog.dart`
- Modify: `apps/walk/lib/presentation/settings/open_settings.dart` (`SettingsTarget.backup`), `page/app_settings_page.dart` (행 하나)
- Modify: l10n arb(ko · en) — 필요한 키만
- Test: `apps/walk/test/presentation/backup/cubit/backup_cubit_test.dart`, `page/backup_page_test.dart`, `widget/export_sheet_test.dart`

**Interfaces:**
- Consumes: `BackupService` · `BackupFiles` · `BackupPreferences` · `DiaryLockCubit`
- Produces: `BackupState` = `idle(lastAt, hasUndo)` · `working(step, progress?)` · `exported(bytes)` · `inspected(InspectedBackup)` · `restored()` · `failed(BackupFailure)`. 복원 성공 뒤 결과 다이얼로그(알람 권한 · 위치 기록 꺼짐 · API 키 다시 입력 안내 중 해당 줄) → [다시 시작] = `BackupFiles.restartApp()`.

- [ ] **Step 1: 실패하는 테스트**
  - cubit: export 성공/취소/실패 전이, inspect → restore → restored, `lastAt` 표시 · 30일 넘으면 stale
  - export sheet: `location unchecked by default`, `save disabled when nothing checked`, `encryption on by default; save disabled until passwords match (≥8) and forget-ack checked`, `warning shown when location checked and encryption off`
  - restore sheet: `newerSchema area greyed with update hint`
  - page: `backup rows disabled while diary locked`, `undo row only when undo point exists`
- [ ] **Step 2:** FAIL 확인
- [ ] **Step 3: 구현** — 복원 확인은 `AppConfirmDialog.show(isDestructive: true)`. 진행은 `AppLoading` + 단계 문구를 막는 전체 화면.
- [ ] **Step 4:** PASS
- [ ] **Step 5:** 커밋 `feat(walk): 설정에 백업 화면을 더한다`

### Task 9: 검증 · 문서

**Files:**
- Modify: `apps/walk/docs/status.md` · `history.md` · `testing.md` (기기 시나리오 BK-1~BK-4 추가)

- [ ] **Step 1:** `cd apps/walk && flutter analyze` → `No issues found!`; `flutter test` 전체 PASS; `flutter test test/convention` PASS(문서 링크는 `apps/trader/test/convention`).
- [ ] **Step 2: 에뮬레이터** (`android-emulator` 스킬): 일기 사진 2 · 위키 1 · 알람 1 만들기 → 암호화 내보내기(다운로드) → `adb shell pm clear com.karma.walk` → 복원 → 재시작 뒤 피드 사진 · 위키 · 알람 다음 울림 확인. 결과를 testing.md 에.
- [ ] **Step 3:** 문서 갱신 후 커밋 `docs(walk): 앱 백업 · 복원을 기록한다`
