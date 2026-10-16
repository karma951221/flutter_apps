# pawlog W9 backup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax.

**Goal:** 모든 반려견 · 산책 · 경로 · 사진을 zip 하나로 내보내고, 그 파일에서 합쳐 되살린다.

**Architecture:** 도메인 순수 함수 `BackupCodec`(json ↔ `BackupData`), 데이터 계층 `BackupArchive`(zip ↔ json + 파일들, `archive` 패키지),
시나리오 `ExportBackupScenario` · `ImportBackupScenario` 가 기존 `DogRepository` · `WalkRepository` · `PhotoStorage` 와
`WalkFileSharer`(바이트 공유 추가) · 새 `BackupFilePicker`(`file_picker`) 를 묶는다. 화면은 피드 앱바 더보기와 첫 실행 등록 화면.

**Spec:** [apps/pawlog/docs/features/backup/plan.md](../../../apps/pawlog/docs/features/backup/plan.md) — 결정 · 형식 · 문자열이 모두 여기 있다.

## Global Constraints

- `backup.json` 형식 · 키 이름 · 시각(UTC ISO-8601) · `birthday` `yyyy-MM-dd` 는 feature plan 그대로. `format` 은 `pawlog-backup`, `version` 1
- 가져오기는 합치기 — 있는 id 는 건너뛴다. 반려견 먼저. 디코딩 · 검증을 끝낸 뒤에만 쓴다(반쯤 쓰지 않기)
- 사진은 가져온 항목의 것만, 같은 상대 경로로, 파일이 이미 있으면 건너뛴다
- `previewPoints` 는 가져올 때 `RoutePreview.downsample(points)` 로 다시 만든다
- 도메인은 Flutter · 플러그인 import 금지(`archive` · `file_picker` · `share_plus` · `path_provider` 는 `lib/data/` 만)
- 화면 토큰 규칙 · 공통 위젯(`AppOverflowMenu` · `AppSnackBar` · `AppButton.text`) · Freezed 패턴 · `switch` 패턴 — 루트 CLAUDE.md
- 생성 파일은 build_runner · gen-l10n. 테스트는 `lib/` 와 1:1. 커밋 끝 `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`

## Review Focus

1. **같은 백업을 두 번 가져오기** — 두 번째는 아무것도 쓰지 않고 `nothingNew` → Task 3 테스트
2. **반쯤 쓰지 않기** — 깨진 json · 다른 format · 높은 version · 누락 필드 · 산책이 백업에 없는 반려견 id 를 가리킴 → 아무것도 안 쓰고 `invalid` → Task 1 · 3 테스트
3. **재설치 첫 실행에서 가져오기** — 등록 화면에서 가져오면 `DogsRedirect` 가 풀리고 피드로 간다 → Task 4 라우터 테스트
4. **사진 경로 탈출** — zip 안의 `photos/../../x` 같은 경로를 쓰지 않는다(상대 경로에 `..` · 절대 경로면 invalid) → Task 2 테스트
5. **시간대** — 내보낸 시각을 다른 시간대 기기에서 가져와도 같은 순간(UTC 로 저장 · 비교) → Task 1 테스트

---

### Task 1: `BackupData` · `BackupCodec`

**Files:** Create `apps/pawlog/lib/domain/backup/entity/backup_data.dart`, `apps/pawlog/lib/domain/backup/policy/backup_codec.dart`; Test `apps/pawlog/test/domain/backup/policy/backup_codec_test.dart`

**Interfaces (Produces):**
- `BackupWalk({required Walk walk, required List<WalkTrackPoint> points})` (Freezed). `walk.previewPoints` 는 디코딩 때 `RoutePreview.downsample(points)`
- `BackupData({required DateTime exportedAt, required List<Dog> dogs, required List<BackupWalk> walks})` (Freezed)
- `abstract final class BackupCodec { static const format = 'pawlog-backup'; static const version = 1; static String encode(BackupData data); static Result<BackupData> decode(String json); }`
  — `decode` 는 던지지 않고 실패를 `Err(Failure.validation(failureCode: FailureCode.unknown))` 같은 값으로 돌려준다(코드는 `packages/core` 의 기존 코드 중 맞는 것; 없으면 `Failure.unknown(message: …)`). `walk.dogs` 는 `dogIds` 를 같은 백업의 `dogs` 에서 찾아 채운다 — 없는 id 가 있으면 실패
- `Walk` 의 `dogs` · `photos` 는 기존 엔티티(`Dog` · `WalkPhoto`)

- [ ] 실패하는 테스트: 왕복(반려견 2 · 산책 2 · 점 · 사진 · 메모 null 포함)이 같은 값(시각은 `isAtSameMomentAs`) · `birthday` 날짜 · UTC 문자열 · 다른 format · version 2 · 깨진 json · 필수 필드 누락 · 모르는 dogId → `Err` · previewPoints 재구성 · 현지 시각으로 만든 값도 같은 순간으로 돌아온다
- [ ] 구현 · `dart run build_runner build --delete-conflicting-outputs` · analyze · test · 커밋 `feat(pawlog): 백업 json 코덱을 추가한다`

### Task 2: 데이터 경계 — zip · 사진 쓰기 · 바이트 공유 · 파일 고르기

**Files:** Create `apps/pawlog/lib/data/backup/backup_archive.dart`, `apps/pawlog/lib/domain/backup/repository/backup_file_picker.dart`, `apps/pawlog/lib/data/backup/file_picker_backup_file_picker.dart`; Modify `apps/pawlog/lib/domain/photo/repository/photo_storage.dart` · `apps/pawlog/lib/data/photo/file_photo_storage.dart`, `apps/pawlog/lib/domain/export/repository/walk_file_sharer.dart` · `apps/pawlog/lib/data/export/share_plus_walk_file_sharer.dart`; Tests `apps/pawlog/test/data/backup/backup_archive_test.dart`, `apps/pawlog/test/data/photo/file_photo_storage_test.dart`

**Interfaces (Produces):**
- `class BackupArchive { const BackupArchive(); Uint8List pack({required String json, required Map<String, Uint8List> photos}); Result<({String json, Map<String, Uint8List> photos})> unpack(Uint8List bytes); }` — `@lazySingleton`. 항목 `backup.json` 과 `photos/<상대 경로>`. `unpack` 은 zip 이 아니거나 `backup.json` 이 없거나 사진 경로가 `..` · `/` 로 시작하면 `Err`. (domain 이 쓰도록 `abstract interface class BackupArchiveCodec` 를 domain/backup/repository 에 두고 이 클래스가 구현한다 — 이름 `BackupArchiveCodec`, 같은 두 메서드)
- `PhotoStorage.write(String relativePath, Uint8List bytes) → Future<Result<void>>` — 이미 있으면 덮어쓰지 않고 `Ok`. `relativePath` 에 `..` 나 `/` 시작이면 `Err`
- `WalkFileSharer.shareBytes({required String fileName, required Uint8List bytes, required String mimeType}) → Future<Result<void>>` — W8 구현처럼 임시 폴더에 쓰고 공유
- `abstract interface class BackupFilePicker { Future<Result<Uint8List?>> pick(); }` — 취소면 `Ok(null)`. 구현 `@LazySingleton(as: BackupFilePicker)` 은 `file_picker` 로 zip 하나(`FileType.custom`, `allowedExtensions: ['zip']`, `withData: true`)
- `flutter pub add archive file_picker` (apps/pawlog)

- [ ] 실패하는 테스트: `BackupArchive` 왕복(사진 2장 바이트 동일) · zip 아님 · `backup.json` 없음 · `photos/../evil` → `Err` · `FilePhotoStorage.write`(임시 디렉터리 루트, 기존 테스트 방식) 쓰기 · 있으면 안 덮음 · `..` 거부
- [ ] 구현 · build_runner · analyze · test · `flutter build apk --debug` · 커밋 `feat(pawlog): 백업 zip 과 사진 쓰기 · 바이트 공유 · 파일 고르기 경계를 추가한다`

### Task 3: 내보내기 · 가져오기 시나리오

**Files:** Create `apps/pawlog/lib/domain/backup/usecase/scenario/export_backup_scenario.dart`, `import_backup_scenario.dart`, `apps/pawlog/lib/domain/backup/entity/backup_import_result.dart`; Modify `apps/pawlog/lib/domain/walk/usecase/walk_use_case.dart`; Tests under `apps/pawlog/test/domain/backup/usecase/scenario/`

**Interfaces (Produces):**
- `sealed BackupImportResult`: `imported(int dogs, int walks)` · `nothingNew()` · `cancelled()` · `invalid()` · `failed(Failure)` (Freezed union)
- `WalkUseCase.exportBackup() → Future<Result<void>>` — 모든 반려견(`getAll`) · 모든 산책(`watchAll().first`) · 각 `getTrack` · 반려견 · 산책 사진 바이트(`resolve(path).readAsBytes()`, 없는 파일은 건너뜀) → `BackupCodec.encode` → `BackupArchiveCodec.pack` → `shareBytes(fileName: 'pawlog-backup-yyyy-MM-dd.zip'(현지 오늘, `Clock`), mimeType: 'application/zip')`
- `WalkUseCase.importBackup() → Future<BackupImportResult>` — `pick` → null 이면 `cancelled` → `unpack` · `decode` 실패면 `invalid`(아무것도 안 씀) → 없는 반려견 `upsert` → 없는 산책 `insert(walk, points)` → 그 항목들의 사진만 `write` → 0/0 이면 `nothingNew`, 아니면 `imported`. 쓰기 중 실패는 `failed`
- `findById` 로 존재 확인(`DogRepository.findById` · `WalkRepository.findById`)

- [ ] 실패하는 테스트(mocktail): 내보내기가 encode 한 json · 사진 맵 · 파일 이름 · mime 으로 공유 / 없는 사진 파일은 빠짐 · 가져오기 6갈래(취소 · invalid 에서 repo 쓰기 없음 · 새 2/3 · 일부만 새것 · 두 번째 가져오기 nothingNew · upsert 실패 → failed) · 반려견이 산책보다 먼저 쓰임(`verifyInOrder`) · 가져온 항목의 사진만 write
- [ ] 구현 · DI 재생성 · analyze · test · 커밋 `feat(pawlog): 백업을 내보내고 합쳐서 가져오는 시나리오를 추가한다`

### Task 4: 화면 · 문자열 · 라우터

**Files:** Modify `packages/l10n/lib/l10n/app_{ko,en,ja}.arb`, `apps/pawlog/lib/presentation/feed/page/walk_feed_page.dart`, `apps/pawlog/lib/presentation/feed/cubit/walk_feed_cubit.dart`, `apps/pawlog/lib/presentation/dog/page/dog_edit_page.dart`, `apps/pawlog/lib/core/router/app_router.dart`; Tests feed page · dog edit page · router

**Interfaces:**
- 문자열 9개(feature plan 표)
- `WalkFeedCubit.exportBackup() → Future<Result<void>>`, `importBackup() → Future<BackupImportResult>` (상태를 바꾸지 않는다 — 가져온 산책은 스트림으로 들어온다)
- 피드 앱바: 기존 반려견 아이콘 옆에 `AppOverflowMenu`(tooltip `walkFeedMoreTooltip`, 키 `walk-feed-more`) 항목 `walk-feed-backup-export` · `walk-feed-backup-import`
- 페이지는 cubit 만 본다. `DogEditCubit.importBackup() → Future<BackupImportResult>` 를 더하고, `DogEditPage({…, bool showImportBackup = false, VoidCallback? onImported})`.
  `showImportBackup` 이면 폼 아래 `AppButton.text(key: Key('dog-edit-import-backup'), label: walkBackupImportFromFirstRun)` 를 보인다. 결과가 `imported` 이고 dogs ≥ 1 이면 `onImported?.call()`
- 라우터: `/dogs/new` 는 `showImportBackup: !dogsRedirect.hasDogs`, `onImported: () { dogsRedirect.markHasDogs(); context.go(PawlogPaths.feed); }`
- 결과 → 스낵바는 feature plan 표 그대로(`cancelled` 는 아무것도 안 함). 공통 매핑 함수 하나(`presentation/backup/backup_messages.dart`)를 두 화면이 쓴다

- [ ] 실패하는 테스트: 피드 메뉴 두 항목 · 내보내기 실패 스낵바 · 가져오기 결과 4종 스낵바 · 취소 무반응 / 첫 실행 등록 화면 버튼 보임 · 수정 화면엔 없음 · imported → `onImported` / 라우터: 반려견 0 → `/dogs/new` 에서 가져오기 성공 → `/` 피드
- [ ] 구현 · gen-l10n · build_runner · analyze · test · apk · convention · 커밋 `feat(pawlog): 피드와 첫 실행 화면에서 백업을 내보내고 가져온다`

### Task 5: 검증 · 문서 (오케스트레이터)
- [ ] 전체 검증, 에뮬레이터(feature plan 완료 조건), `history.md` · `testing.md` · status · README W9 행 · overview §3 · §5
