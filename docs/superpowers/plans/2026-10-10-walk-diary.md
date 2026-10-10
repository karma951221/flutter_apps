# walk 일기 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. 태스크마다 스펙의 해당 절을 함께 읽는다.

**Goal:** Life Tool(`apps/walk`)에 네 번째 탭 **일기**를 더한다 — 스토리로 묶는 짧은 기록(글 · 사진 · 30초 이하 영상 · 현재 위치 · 해시태그), 줄글/피드/릴스 보기, 검색 4종, 휴지통, PIN/패턴 잠금.

**Architecture:** walk 의 기존 계층(`lib/{core,data,domain,presentation}` 아래 기능 폴더)에 `diary/` · `lock/` 기능 폴더를 더한다. 저장은 drift(SQLite, 앱 문서 폴더의 `diary.sqlite`) + 앱 문서 폴더 `diary/` 아래 미디어 파일(상대 경로). DB 는 행만, 파일은 `MediaStore` 만 다루고, 둘을 엮는 일(영구 삭제 뒤 파일 삭제, 고아 청소, 장소 채우기)은 `DiaryUseCase` 가 한다. 잠금은 `shared_preferences` 에 salt+해시와 시도 기록을 두고, 일기 탭 위젯 트리를 `DiaryLockGate` 가 감싼다.

**Tech Stack:** Flutter 3.41 / Dart 3.11, flutter_bloc, freezed 3, injectable/get_it, drift 2.34 + drift_flutter, image_picker, flutter_image_compress, video_compress(T1 스파이크 결과에 따라 교체), video_player, geocoding, local_auth, crypto, workspace 패키지 `location`.

**Spec:** [walk 일기 설계](../specs/2026-10-10-walk-diary-design.md) — 결정 · 데이터 · 흐름 · 잠금 · 테스트(§9)의 단일 기준.

## Global Constraints

- 안드로이드만(minSdk 26). Dart 명령은 `apps/walk` 에서: `flutter test` · `flutter analyze` · 코드 생성 `dart run build_runner build --delete-conflicting-outputs`.
- **작업 트리에 다른 작업(알람 위젯 수정 · `apps/pawlog/**` · `.idea/`)이 진행 중이다.** 실행은 `superpowers:using-git-worktrees` 로 새 워크트리에서 하고, 커밋은 항상 경로 지정 `git add <경로…>`. `.idea/` · `apps/pawlog/**` 는 절대 add 하지 않는다.
- 커밋 메시지 `feat(walk): …`/`fix(walk): …`/`refactor(walk): …`/`docs(walk): …`/`chore(walk): …` 한국어 + 빈 줄 + `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- 의존 패키지: walk 는 workspace 패키지 `core` · `design_system` · `l10n` · `permission` 에 더해 이번에 `location` 을 쓴다(트레이더 `feature_*` · `supabase_flutter` 금지 — `test/convention/package_boundary_test.dart`). 한 앱 전용 코드는 앱 안에 둔다.
- l10n: `packages/l10n/lib/l10n/app_{ko,en,ja}.arb` 에 **`walkDiary*` · `walkLock*`** 접두사 키, ko 에는 `@key.description` 필수. 추가 전 `grep '"walkDiary' app_ko.arb` 로 충돌 확인. `cd packages/l10n && flutter gen-l10n` 생성물도 커밋. ARB 를 바꾸면 `cd apps/trader && flutter test test/convention` 통과.
- CLAUDE.md: UI 공통 위젯(`AppButton` · `AppListTile` · `AppPlaceholder` · `AppConfirmDialog` · `AppSnackBar` · `AppOverflowMenu` · `AppAvatar`) 우선, 색 · 여백 · 모서리는 `Theme.of(context)` · `AppSpacing` · `AppRadius` · `AppMotion`(하드코딩 금지). Freezed 는 primary constructor(단일 모델) · `sealed` + named factory(union) 두 패턴만, 분기는 `switch` 패턴 매칭. 생성 파일 직접 수정 금지. 테스트는 `lib/…` ↔ `test/…` 1:1.
- 시간 의존 코드는 `core` 의 `Clock` 주입(`RegisterModule` 이 이미 등록). id 는 `core` 의 `IdGenerator`(uuid v4) — walk `RegisterModule` 에 `Uuid` 등록이 없으면 T3 에서 추가.
- 날짜 산술은 `DateTime(y, m, d + n, h, mi)` 생성자. 휴지통 기한 · 잠금 시간처럼 **경과 시간**은 `Duration` 비교.
- 수치(스펙 그대로): 사진 긴 변 **1600px**, JPEG 품질 **85**, EXIF 제거 · 영상 최대 **720p**, 클립 **30초 이하** · 기록당 사진+영상 **최대 10개** · 태그 최대 **30자** · 휴지통 기간 **1 · 7(기본) · 30일 · 안 함** · 다시 잠그기 **즉시 · 30초 · 1분(기본) · 5분** · 잠금 실패 **5회 → 30초** · 폰 인증 실패 → **24시간** · PIN **4자리** · 패턴 **점 4개 이상** · 검색 디바운스 **300ms**.
- 기본 스토리 id 는 상수 `DiaryStory.dailyId = 'daily'`, 제목은 표시할 때 l10n(`walkDiaryDailyStoryTitle`)으로 — 사용자가 이름을 바꾸면 그 값을 쓴다(`title` 이 빈 문자열이면 l10n).
- TDD: 실패 테스트 → 실패 확인 → 최소 구현 → 통과. 바로 통과한 테스트는 구현을 잠시 되돌려(뮤테이션) 실패를 확인한다.
- 각 태스크 끝: `flutter analyze` 0 이슈 · `flutter test` 전부 통과(기준선 2026-10-08: 954 통과 · 1 skip). 네이티브 설정을 건드린 태스크는 `flutter build apk --debug` 성공.

## Review Focus

스펙이 직접 말하지 않지만 사람이 실제로 부딪힐 입력 · 상황. 각 줄의 테스트는 소유 태스크에 넣어 두었다.

1. **저장 도중 앱이 죽거나 압축이 실패** — 기록 행 없이 정식 폴더에 파일만 남거나, 행은 있는데 파일이 없으면 안 된다. 커밋 순서(파일 이동 → DB 트랜잭션, DB 실패 시 이동한 파일 되돌림)와 고아 청소로 회수 → T7 · T9 테스트.
2. **같은 태그를 대소문자 · `#` · 공백만 다르게 여러 번 입력**(`#Jeju`, `jeju`, ` 제 주 `) — 칩 하나 · 태그 행 하나 → T2 · T6 · T14 테스트.
3. **이모지 · 한글 조합 중 문자 · 매우 긴 본문(1만 자) 검색** — LIKE 가 깨지지 않고, 줄글 · 피드가 잘리지 않는다(피드 카드 본문은 6줄 접기 + "더 보기") → T6 · T13 테스트.
4. **휴지통에 있는 기록의 미디어를 표지로 지정해 둔 스토리** · **휴지통 기록이 유일한 사진인 스토리** — 표지가 깨진 이미지가 아니라 자동 표지 · 이니셜로 → T5 테스트.
5. **잠금 중 앱이 다시 시작되거나 시계가 거꾸로 감** — 잠금이 풀리지 않는다, 30초/24시간 차단이 재시작 뒤에도 유지 → T10 · T11 테스트.

---

## 단계 A — 기반(도메인 · DB)

### T1: 의존성 · 안드로이드 설정 · 플러그인 스파이크

**Files:**
- Modify: `apps/walk/pubspec.yaml`, 루트 `pubspec.lock`, `apps/walk/android/app/src/main/AndroidManifest.xml`
- Create: `docs/superpowers/specs/2026-10-10-walk-diary-design.md` 에 §11 "스파이크 결과" 절 추가(결과 기록)
- Test: `apps/walk/test/convention/package_boundary_test.dart`(갱신)

**Interfaces:**
- Produces: pubspec 의존성 — `drift: ^2.34.4` · `drift_flutter: ^0.3.1` · `path_provider: ^2.1.6` · `image_picker` · `flutter_image_compress` · `video_compress`(또는 대안) · `video_player` · `geocoding` · `local_auth` · `crypto` · `uuid`(IdGenerator 용, core 와 같은 버전) · `location: any`, dev `drift_dev: ^2.34.0`. 버전은 pawlog · core 와 맞추고 나머지는 `flutter pub add` 가 고른 최신.

- [ ] **Step 1:** `package_boundary_test.dart` 에 테스트 추가 — `location` 은 허용(`  location: any`), `feature_` · `supabase_flutter` 금지 유지. 지금은 `location` 이 없어 실패하도록 "location 을 의존한다" 단언을 쓴다.
- [ ] **Step 2:** `flutter test test/convention/package_boundary_test.dart` → FAIL 확인.
- [ ] **Step 3:** `cd apps/walk && flutter pub add drift drift_flutter path_provider image_picker flutter_image_compress video_compress video_player geocoding local_auth crypto uuid` · `flutter pub add dev:drift_dev` · pubspec 에 `location: any` 를 `permission: any` 아래 손으로 추가 · 루트에서 `flutter pub get`.
- [ ] **Step 4:** 매니페스트 — `ACCESS_FINE_LOCATION` · `ACCESS_COARSE_LOCATION` · `USE_BIOMETRIC` 권한, `<queries>` 에 `android.media.action.IMAGE_CAPTURE` · `android.media.action.VIDEO_CAPTURE`. `MainActivity` 는 이미 `FlutterFragmentActivity` 라 `local_auth` 요구를 만족한다(확인만).
- [ ] **Step 5: 스파이크(버리는 코드, 커밋하지 않음)** — `lib/main.dart` 를 잠시 바꾸지 말고 `integration_test/` 없이 `flutter run` 용 임시 파일 `lib/spike_main.dart`(커밋 금지)로 에뮬레이터(Android 17)에서 확인:
  - `video_compress` `compressVideo(path, quality: VideoQuality.Res1280x720Quality, deleteOrigin: false)` 가 25초 영상을 720p 로 만들고 `MediaInfo.duration`(ms) 을 준다 · `getFileThumbnail` 동작.
  - 실패하거나 빌드가 깨지면 `light_compressor` 로 같은 확인. 둘 다 안 되면 **원본 복사 + 길이 확인만**(압축 생략)으로 결정.
  - `flutter_image_compress.compressAndGetFile(src, dst, minWidth: 1600, minHeight: 1600, quality: 85, keepExif: false, format: CompressFormat.jpeg)` 결과의 EXIF GPS 가 없는지 `exiftool` 또는 `ExifInterface` 로 확인 · 1000px 사진은 확대되지 않는지(안 되면 T7 에서 먼저 크기를 읽고 작으면 minWidth 를 원본 크기로).
  - `local_auth` `authenticate(localizedReason:, options: AuthenticationOptions(biometricOnly: false))` 가 기기 PIN 으로 통과 · 취소 시 `false` 와 예외 코드 구분.
  - `geocoding` `placemarkFromCoordinates(37.5665, 126.9780)` 가 `ko_KR` 로케일에서 시 · 구 · 동 필드를 주는지(`locality` · `subLocality` · `thoroughfare` 중 무엇이 채워지는지 기록).
  - `lib/spike_main.dart` 삭제.
- [ ] **Step 6:** 결과를 스펙 §11 에 표로(패키지 · 버전 · 동작 · 선택 · 우회) 적는다. 대안 패키지로 바꿨으면 pubspec 도 바꾼다.
- [ ] **Step 7:** `flutter analyze` · `flutter test` · `flutter build apk --debug`.
- [ ] **Step 8: Commit**
```bash
git add apps/walk/pubspec.yaml pubspec.lock apps/walk/android/app/src/main/AndroidManifest.xml apps/walk/test/convention/package_boundary_test.dart docs/superpowers/specs/2026-10-10-walk-diary-design.md
git commit -m "chore(walk): 일기에 쓸 의존성과 권한을 더하고 플러그인 동작을 확인한다

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### T2: 도메인 엔티티 · 규칙

**Files:**
- Create: `apps/walk/lib/domain/diary/entity/story.dart` · `diary_entry.dart` · `entry_media.dart` · `entry_location.dart` · `entry_draft.dart` · `named_count.dart` · `diary_view_mode.dart` · `entry_filter.dart` · `tag_name.dart` · `media_limits.dart` · `trash_retention.dart` · `diary_usage.dart` (각 `.freezed.dart` 생성)
- Create: `apps/walk/lib/domain/diary/diary_failure.dart`(FailureCode 대신 앱 안 enum)
- Test: `apps/walk/test/domain/diary/entity/tag_name_test.dart` · `entry_time_test.dart` · `story_test.dart` · `media_limits_test.dart` · `trash_retention_test.dart`

**Interfaces (Produces):**
```dart
// story.dart
enum StoryStatus { open, closed }
@freezed
class Story with _$Story {
  static const dailyId = 'daily';
  final String id; final String title; final StoryStatus status;
  final DateTime startedAt; final DateTime? endedAt;
  final String? coverMediaId; final DateTime? lastPostedAt; final DateTime createdAt;
  const Story({required this.id, required this.title, required this.status, required this.startedAt,
    this.endedAt, this.coverMediaId, this.lastPostedAt, required this.createdAt});
  bool get isDefault => id == dailyId;
  bool get isOpen => status == StoryStatus.open;
  /// [at] 이 이 스토리의 기간에 드는지. endedAt 이 없으면 startedAt 이후 전부.
  bool covers(DateTime at);
  /// 닫기 · 다시 열기 규칙. 위반이면 Err(Failure.validation(failureCode: null, field: DiaryFailure.x.name)).
  Result<Story> close(DateTime at);   // 기본 스토리 · at < startedAt 거절
  Result<Story> reopen();              // endedAt = null, status = open
}
// entry_media.dart
enum MediaKind { photo, video }
@freezed class EntryMedia with _$EntryMedia {
  final String id; final MediaKind kind; final String path; final String? thumbPath;
  final int width; final int height; final int? durationMs; final int bytes;
  const EntryMedia({required this.id, required this.kind, required this.path, this.thumbPath,
    required this.width, required this.height, this.durationMs, required this.bytes});
}
// entry_location.dart — 좌표만(오프라인) · 이름만(직접 입력) · 둘 다
@freezed class EntryLocation with _$EntryLocation {
  final String? placeName; final double? lat; final double? lng;
  const EntryLocation({this.placeName, this.lat, this.lng});
  bool get hasCoordinates => lat != null && lng != null;
}
// diary_entry.dart
@freezed class DiaryEntry with _$DiaryEntry {
  final String id; final String storyId; final String body;
  final DateTime occurredAt; final DateTime createdAt; final DateTime updatedAt; final DateTime? deletedAt;
  final EntryLocation? location; final List<EntryMedia> media; final List<String> tags; // tags 는 정규화된 이름, 입력 순
  const DiaryEntry({...});
  bool get isTrashed => deletedAt != null;
  bool get timeEdited => occurredAt != createdAt;
}
// entry_draft.dart — 작성/수정 입력
@freezed class EntryDraft with _$EntryDraft {
  final String storyId; final String body; final DateTime occurredAt;
  final EntryLocation? location; final List<EntryMedia> media; final List<String> tags;
  const EntryDraft({...});
  /// 빈 기록(글 trim 후 빈 문자열 + 미디어 0) · 미래 시각 · 미디어 > 10 · 영상 > 30초 를 검사.
  Result<EntryDraft> validate(DateTime now);
}
// tag_name.dart
abstract final class TagName {
  static const maxLength = 30;
  /// 앞뒤 공백 · 앞의 '#'(여러 개) 제거, 모든 공백 제거, toLowerCase. 빈 문자열 · 30자 초과면 null.
  static String? normalize(String raw);
}
// media_limits.dart
abstract final class MediaLimits {
  static const maxItems = 10; static const maxVideo = Duration(seconds: 30);
  static const photoLongEdge = 1600; static const photoQuality = 85;
  static bool canAdd(int current, int adding) => current + adding <= maxItems;
  static bool videoAllowed(Duration length) => length <= maxVideo;
}
// trash_retention.dart
enum TrashRetention { day1(Duration(days: 1)), day7(Duration(days: 7)), day30(Duration(days: 30)), never(null);
  const TrashRetention(this.period); final Duration? period;
  static const fallback = TrashRetention.day7;
  /// 기한이 지났는지: deletedAt + period <= now. never 면 항상 false.
  bool expired(DateTime deletedAt, DateTime now); }
// named_count.dart
@freezed class NamedCount with _$NamedCount { final String name; final int count; final DateTime lastUsedAt; const NamedCount({...}); }
// diary_view_mode.dart
enum DiaryViewMode { prose, feed, reels }
// entry_filter.dart
@freezed sealed class EntryFilter with _$EntryFilter {
  const factory EntryFilter.all() = AllEntries;
  const factory EntryFilter.story(String storyId) = StoryEntries;
  const factory EntryFilter.tag(String name) = TagEntries;
  const factory EntryFilter.place(String name) = PlaceEntries;
  const factory EntryFilter.body(String query) = BodyEntries;
}
// diary_usage.dart
@freezed class DiaryUsage with _$DiaryUsage { final int photos; final int videos; final int bytes; final int trashBytes; const DiaryUsage({...}); }
// diary_failure.dart — Failure.validation(field: DiaryFailure.x.name) 로 실어 보낸다
enum DiaryFailure { emptyEntry, futureTime, tooManyMedia, videoTooLong, defaultStoryLocked, endBeforeStart, storyClosed, notFound, mediaProcessing }
```

- [ ] **Step 1: 실패 테스트** — 스펙 §9.2 의 domain 줄 그대로:
  - `tag_name_test`: `'  #Jeju '`→`'jeju'` · `'##제 주'`→`'제주'` · `'#'`→null · `''`→null · 30자 OK · 31자 null · `'#JEJU'`와 `'jeju'` 같은 값 · 이모지 `'#🍊귤'`→`'🍊귤'`.
  - `entry_time_test`: `EntryDraft.validate` — now 와 같은 시각 OK · now+1초 `futureTime` · 빈 글+미디어 0 `emptyEntry` · 공백만 글 `emptyEntry` · 미디어만 있으면 OK · 11개 `tooManyMedia` · 영상 30_001ms `videoTooLong` · 30_000ms OK. `DiaryEntry.timeEdited` true/false.
  - `story_test`: `close(at)` → status closed, endedAt=at · 기본 스토리 `defaultStoryLocked` · at<startedAt `endBeforeStart` · `reopen` → endedAt null · `covers`(경계 포함: startedAt == at true, endedAt == at true, endedAt 다음 1초 false, endedAt 없음은 미래 전부 true).
  - `media_limits_test`: `canAdd(9,1)` true · `canAdd(10,1)` false · `canAdd(3,8)` false · 30초 true · 30.001초 false.
  - `trash_retention_test`: day7 — 6일 23:59:59 false · 정확히 7일 true · never 는 1000일도 false.
- [ ] **Step 2:** `flutter test test/domain/diary` → FAIL(컴파일 오류).
- [ ] **Step 3:** 엔티티 구현 → `dart run build_runner build --delete-conflicting-outputs`.
- [ ] **Step 4:** `flutter test test/domain/diary` → PASS. 바로 통과한 줄은 뮤테이션 확인.
- [ ] **Step 5: Commit** `feat(walk): 일기 도메인 엔티티와 규칙을 더한다` — `apps/walk/lib/domain/diary apps/walk/test/domain/diary`.

### T3: drift DB · 스키마 · 시드 · DI

**Files:**
- Create: `apps/walk/lib/data/diary/database/tables.dart` · `diary_database.dart`(+`.g.dart`)
- Modify: `apps/walk/lib/core/di/register_module.dart` (+ `injection.config.dart` 재생성)
- Test: `apps/walk/test/data/diary/database/diary_database_test.dart`

**Interfaces:**
- Produces:
```dart
// tables.dart — 컬럼 이름은 스펙 §5 와 같다(snake_case 는 drift 기본 변환)
class Stories extends Table { TextColumn get id => text()(); TextColumn get title => text()();
  TextColumn get status => textEnum<StoryStatus>()(); DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()(); TextColumn get coverMediaId => text().nullable()();
  DateTimeColumn get lastPostedAt => dateTime().nullable()(); DateTimeColumn get createdAt => dateTime()();
  @override Set<Column> get primaryKey => {id}; }
class Places extends Table { TextColumn id; TextColumn name unique; DateTimeColumn createdAt; pk id }
class Tags extends Table { TextColumn id; TextColumn name unique; DateTimeColumn createdAt; pk id }
class Entries extends Table { TextColumn id; TextColumn storyId references(Stories, #id)(); TextColumn body;
  DateTimeColumn occurredAt; DateTimeColumn createdAt; DateTimeColumn updatedAt; DateTimeColumn deletedAt nullable;
  TextColumn placeId nullable references(Places, #id, onDelete: KeyAction.setNull)(); RealColumn lat nullable; RealColumn lng nullable; pk id }
class Media extends Table { TextColumn id; TextColumn entryId references(Entries, #id, onDelete: KeyAction.cascade)();
  TextColumn kind textEnum<MediaKind>(); TextColumn path; TextColumn thumbPath nullable; IntColumn sortOrder;
  IntColumn width; IntColumn height; IntColumn durationMs nullable; IntColumn bytes; pk id }
class EntryTags extends Table { TextColumn entryId references(Entries, #id, onDelete: KeyAction.cascade)();
  TextColumn tagId references(Tags, #id, onDelete: KeyAction.cascade)(); pk {entryId, tagId} }
// 인덱스: entries(story_id, occurred_at), entries(deleted_at), media(entry_id, sort_order), entry_tags(tag_id)

// diary_database.dart
@DriftDatabase(tables: [Stories, Places, Tags, Entries, Media, EntryTags])
class DiaryDatabase extends _$DiaryDatabase {
  DiaryDatabase(super.executor, {required DateTime Function() now});
  int get schemaVersion => 1;
  // options: storeDateTimeAsText: true (pawlog 와 같음)
  // migration: onCreate → createAll + 인덱스 + 기본 스토리 insert(id 'daily', title '', open, startedAt=createdAt=now())
  //            beforeOpen → PRAGMA foreign_keys = ON, 그리고 기본 스토리가 없으면 insertOrIgnore (지워진 경우 복구)
}

// register_module.dart 에 추가
FutureOr<void> disposeDiaryDatabase(DiaryDatabase db) => db.close();
@LazySingleton(dispose: disposeDiaryDatabase)
DiaryDatabase diaryDatabase(Clock clock) => DiaryDatabase(driftDatabase(name: 'diary'), now: clock.now);
@preResolve @Named('diaryRoot') Future<Directory> get diaryRoot async => Directory('${(await getApplicationDocumentsDirectory()).path}/diary');
@lazySingleton Uuid get uuid => const Uuid();        // IdGenerator 가 요구 — 이미 등록돼 있으면 생략
@lazySingleton LocationGateway get locationGateway => const GeolocatorGateway();
```
(injectable 모듈의 인자 있는 메서드 provider 가 생성에 실패하면, getter 로 두고 `DiaryDatabase(driftDatabase(name: 'diary'), now: DateTime.now)` 를 넘긴다. 테스트는 언제나 고정 함수를 넘긴다.)

- [ ] **Step 1: 실패 테스트**(`NativeDatabase.memory()`):
  - 처음 열면 stories 에 `daily` 한 행(status open, title '') · 같은 executor 로 두 번째 `DiaryDatabase` 를 열어도 한 행 · `PRAGMA foreign_keys` 결과 1 · tags.name 중복 insert 는 예외 · places.name 중복 insert 는 예외 · entries 를 지우면 media · entry_tags 행이 연쇄로 지워진다 · 없는 storyId 로 entries insert 는 FK 예외 · `daily` 행을 직접 delete 한 뒤 다시 열면(beforeOpen) 다시 생긴다.
- [ ] **Step 2:** `flutter test test/data/diary/database` → FAIL.
- [ ] **Step 3:** 테이블 · DB · 모듈 구현 → build_runner.
- [ ] **Step 4:** PASS 확인 + `flutter test`(DI 가 앱 테스트를 깨지 않는지 — 테스트에서 `getIt` 을 쓰는 곳이 `diaryRoot` preResolve 때문에 `path_provider` 를 부르지 않는지 확인. 깨지면 해당 테스트 setUp 에 `PathProviderPlatform` mock 을 넣는다).
- [ ] **Step 5: Commit** `feat(walk): 일기 drift DB 와 기본 스토리를 만든다`.

### T4: 저장소 — 스토리 · 기록 CRUD

**Files:**
- Create: `apps/walk/lib/domain/diary/repository/diary_repository.dart` · `apps/walk/lib/domain/diary/usecase/story_order.dart` · `apps/walk/lib/data/diary/drift_diary_repository.dart` · `apps/walk/lib/data/diary/database/diary_mapper.dart`
- Test: `apps/walk/test/data/diary/drift_diary_repository_entry_test.dart` · `drift_diary_repository_story_test.dart` · `apps/walk/test/domain/diary/usecase/story_order_test.dart` · `apps/walk/test/support/diary_fixtures.dart`(테스트 공용 빌더)

**Interfaces:**
- Consumes: T2 엔티티, T3 `DiaryDatabase`, `IdGenerator`, `Clock`.
- Produces (전체 인터페이스 — T5 · T6 가 나머지 메서드를 구현한다. 이 태스크에서 T5/T6 메서드는 `UnimplementedError` 가 아니라 **아예 선언하지 않고**, 각 태스크가 인터페이스에 추가한다):
```dart
abstract interface class DiaryRepository {
  // 스토리
  Stream<List<Story>> watchStories();                       // 전체(닫힌 것 포함). 정렬은 StoryOrder 가 한다
  Future<Result<Story>> createStory({required String title, required DateTime startedAt, DateTime? endedAt});
  Future<Result<Story>> updateStory(Story story);           // 이름 · 상태 · endedAt · coverMediaId 저장
  // 기록
  Stream<List<DiaryEntry>> watchEntries(EntryFilter filter); // 휴지통 제외, occurredAt 내림차순, 같으면 createdAt 내림차순
  Future<Result<DiaryEntry>> entry(String id);               // 휴지통 포함
  Future<Result<DiaryEntry>> createEntry(EntryDraft draft);  // id · createdAt=updatedAt=now. 스토리 lastPostedAt=now
  Future<Result<DiaryEntry>> updateEntry(String id, EntryDraft draft); // updatedAt=now, createdAt 불변. 스토리가 바뀌면 새 스토리 lastPostedAt=now
  Future<Result<void>> moveEntries(List<String> ids, String storyId);
  Future<List<DiaryEntry>> entriesBetween(DateTime from, DateTime to, {required String storyId}); // 지난 기간 스토리 만들 때 '일상' 기록 제안
}
// 스토리 바 순서 — 순수 함수(domain/diary/usecase/story_order.dart)
abstract final class StoryOrder {
  /// open: 기본 스토리 포함, lastPostedAt 내림차순(null 은 createdAt 으로), 같으면 createdAt 내림차순.
  /// closed: endedAt 내림차순(보관함).
  static ({List<Story> open, List<Story> archived}) split(List<Story> stories);
}
```
- 쓰기는 모두 `transaction` 안에서. 태그 · 장소는 이름으로 `insertOrIgnore` 후 id 조회(기존 행 재사용). 미디어는 기록 수정 시 **기존 media 행을 지우고 draft 순서대로 다시 insert**(같은 id 유지 — draft 의 `EntryMedia.id` 사용). 파일은 건드리지 않는다.
- 실패는 `Err(Failure.validation(field: DiaryFailure.x.name))` · 없는 id 는 `Err(Failure.notFound())` · SQLite 예외는 `Err(Failure.unknown(message: e.toString()))`.
- 닫힌 스토리로 새 기록 저장 · 이동은 `storyClosed`(기존 기록 수정에서 스토리를 바꾸지 않은 경우는 허용).

- [ ] **Step 1: 실패 테스트**(스펙 §9.3 entry · story 줄):
  - entry: 미디어 3개 순서 유지 · 태그 `['jeju','food']` 저장 → 같은 태그로 두 번째 기록 저장 시 tags 행 수 2 그대로 · 장소 '애월읍' 두 기록 → places 행 1 · 저장 시 해당 스토리 `lastPostedAt` = now · 수정하면 `updatedAt` 만 바뀌고 `createdAt` 그대로 · `occurredAt` 을 과거로 바꾸면 `watchEntries(story)` 순서가 바뀐다 · 스토리 이동 시 새 스토리 lastPostedAt 갱신 · 닫힌 스토리에 새 기록 `storyClosed` · 없는 id 수정 `notFound` · 이모지/1만 자 본문 왕복(Review Focus 3).
  - story: 생성(endedAt 있으면 closed) · `updateStory` 로 닫기/다시 열기/이름 변경 · `StoryOrder.split`(open 3개의 lastPostedAt 순 · null 은 createdAt · closed 는 보관함 endedAt 순) · `entriesBetween` 은 휴지통 제외 · 해당 스토리만.
  - `watchEntries` 가 저장 · 수정 뒤 새 값을 내보낸다(스트림 두 번째 이벤트).
- [ ] **Step 2:** FAIL 확인.
- [ ] **Step 3:** 구현(매퍼: 행 → 엔티티, 기록은 media(sortOrder 순) · tags(이름) · place(이름)를 조인해 조립. `watchEntries` 는 entries · media · entry_tags · tags · places 테이블 변경을 모두 구독하도록 `customSelect(..., readsFrom: {...}).watch()` 또는 join 쿼리 `.watch()` 후 asyncMap).
- [ ] **Step 4:** PASS + 뮤테이션.
- [ ] **Step 5: Commit** `feat(walk): 일기 스토리와 기록을 저장한다`.

### T5: 휴지통 · 복원 · 영구 삭제 · 스토리 삭제 · 표지

**Files:**
- Modify: `diary_repository.dart` · `drift_diary_repository.dart`
- Create: `apps/walk/lib/domain/diary/usecase/story_cover.dart`
- Test: `apps/walk/test/data/diary/drift_diary_repository_trash_test.dart` · `drift_diary_repository_trash_restore_test.dart` · `apps/walk/test/domain/diary/usecase/story_cover_test.dart`

**Interfaces (Produces, 인터페이스에 추가):**
```dart
Future<Result<void>> trashEntry(String id);                 // deletedAt = now. updatedAt 불변
Future<Result<DiaryEntry>> restoreEntry(String id);         // deletedAt = null. 스토리가 없으면 storyId = 'daily'. updatedAt 불변. 영구 삭제됐으면 notFound
Stream<List<DiaryEntry>> watchTrash();                      // deletedAt 내림차순
/// 영구 삭제. 한 트랜잭션: entries delete(→ media · entry_tags 연쇄) + 쓰는 기록 없는 tags · places 정리
/// + 지워진 미디어를 표지로 둔 스토리의 coverMediaId = null. 지워진 파일의 상대 경로(path · thumbPath)를 돌려준다.
Future<Result<List<String>>> purgeEntries(List<String> ids);
Future<Result<List<String>>> purgeTrashedBefore(DateTime deletedBefore); // deletedAt <= deletedBefore
Future<Result<List<String>>> purgeAllTrash();
/// 스토리 삭제: 기록 전부 deletedAt=now 후 스토리 행 삭제(기록의 storyId 는 FK 때문에 'daily' 로 옮기지 않고
/// 남겨 둘 수 없으므로 — **storyId 를 'daily' 로 바꾸고 원래 스토리 id 는 버린다**. 복원하면 '일상').
/// 기본 스토리면 defaultStoryLocked.
Future<Result<void>> deleteStory(String id);
/// DB 가 아는 모든 미디어 경로(휴지통 포함). 고아 청소용.
Future<Set<String>> allMediaPaths();
// story_cover.dart
sealed class StoryCover { } // CoverMedia(EntryMedia media) | CoverInitial(String title)
abstract final class StoryCoverRule {
  /// coverMediaId 가 살아 있는(휴지통 아닌) 기록의 미디어면 그것, 아니면 occurredAt 최신 기록의 첫 photo,
  /// 없으면 첫 video(썸네일), 없으면 CoverInitial.
  static StoryCover pick(Story story, List<DiaryEntry> liveEntries);
}
```
(스펙 §5.1 은 "원래 스토리가 삭제됐으면 복원 시 일상으로"라고 적었다. FK 제약상 스토리 삭제 시점에 storyId 를 'daily' 로 옮기는 것으로 같은 결과를 낸다 — 이 결정을 스펙 §5.1 에 한 줄 덧붙인다.)

- [ ] **Step 1: 실패 테스트** — 스펙 §9.3 trash 줄과 §9.3.1 표의 **DB 부분** 전부:
  - trash: 삭제 후 행 · media 행 그대로 · `watchEntries(all/story/tag/place/body)` 모두에서 빠짐 · `watchTrash` 에 나타남 · `purgeEntries` 뒤 entries · media · entry_tags 행 0 · 반환 경로에 path 와 thumbPath 모두 · 다른 기록의 media 행 · 공유 태그 행 유지 · `purgeAllTrash` 여러 개 · `purgeTrashedBefore` 경계(같은 시각 포함) · 트랜잭션 중 예외(테스트 전용으로 `purgeEntries` 에 존재하지 않는 id 섞기는 정상 처리, 대신 `DiaryDatabase` 를 닫은 뒤 호출 → `Err`, 반환 경로 없음).
  - restore(§9.3.1): 사진2+영상1 삭제 → 복원 시 같은 id · 본문 · occurredAt · createdAt · storyId · 장소 · 좌표 · 미디어 3개 순서/종류/크기/길이/경로 동일 · deletedAt null · updatedAt 불변 · 원래 스토리 `watchEntries` 의 occurredAt 자리 · `all` · body 검색에 다시 · 삭제된 동안 원래 스토리를 닫으면 닫힌 스토리로 복원 · 원래 스토리를 `deleteStory` 하면 '일상'으로 복원 · purge 후 restore `notFound`.
  - deleteStory: 기록 2개가 휴지통으로 · storyId 'daily' · 스토리 행 없음 · 기본 스토리 거절.
  - story_cover(Review Focus 4): 지정 표지 사용 · 지정 표지의 기록이 휴지통이면 자동(최신 사진) · 사진 없고 영상만이면 영상 · 미디어 없으면 이니셜 · 휴지통 기록이 유일한 사진이면 이니셜 · 지정 미디어가 purge 되면 coverMediaId null(DB 테스트).
- [ ] **Step 2:** FAIL.
- [ ] **Step 3:** 구현. 쓰지 않는 태그 정리 SQL: `DELETE FROM tags WHERE id NOT IN (SELECT tag_id FROM entry_tags)`, 장소: `DELETE FROM places WHERE id NOT IN (SELECT place_id FROM entries WHERE place_id IS NOT NULL)` — 휴지통 기록이 쓰는 행은 남는다(복원 시 같은 id).
- [ ] **Step 4:** PASS + 뮤테이션. 스펙 §5.1 한 줄 갱신.
- [ ] **Step 5: Commit** `feat(walk): 일기 휴지통 · 복원 · 영구 삭제를 더한다`.

### T6: 태그 · 장소 집계 · 추천 · 검색

**Files:**
- Modify: `diary_repository.dart` · `drift_diary_repository.dart`
- Create: `apps/walk/lib/data/diary/database/like_escape.dart`(또는 `core` 의 `like_pattern.dart` 재사용 — 먼저 읽어 보고 `%` · `_` · `\` 이스케이프 + `ESCAPE '\'` 를 지원하면 그것을 쓴다)
- Test: `drift_diary_repository_tag_sync_test.dart` · `drift_diary_repository_place_sync_test.dart` · `drift_diary_repository_search_test.dart` · `drift_diary_repository_suggest_test.dart` · `drift_diary_repository_usage_test.dart`

**Interfaces (Produces, 인터페이스에 추가):**
```dart
/// 쓰는 기록(휴지통 제외)이 1 이상인 것만. query 는 정규화 후 포함 일치(태그는 TagName.normalize, 장소는 trim).
/// 정렬: count 내림차순 → lastUsedAt(쓰는 기록의 최대 occurredAt) 내림차순 → name 오름차순. 빈 query 면 상위 [limit].
Stream<List<NamedCount>> watchTagCounts({String query = '', int limit = 20});
Stream<List<NamedCount>> watchPlaceCounts({String query = '', int limit = 20});
/// 스토리 제목 포함 일치(대소문자 무시) + 휴지통 제외 기록 수. 기본 스토리는 title 이 '' 이므로
/// l10n 이름으로 찾을 수 있게 [dailyTitle] 을 받는다. 정렬은 StoryOrder 와 같다.
Stream<List<({Story story, int count})>> watchStoryMatches(String query, {required String dailyTitle});
Future<DiaryUsage> usage();
```
- `EntryFilter.tag/place/body` 는 T4 `watchEntries` 에 이미 들어온 필터 — 이 태스크에서 쿼리를 완성한다: body 는 `body LIKE ? ESCAPE '\'`(이스케이프한 `%q%`), SQLite LIKE 는 ASCII 만 대소문자 무시이므로 그 이상은 하지 않는다.
- 모든 집계 스트림은 entries · entry_tags · tags · places 변경에 다시 내보낸다(추가 · 수정 · 삭제 · 복원 · 영구 삭제 즉시 반영).

- [ ] **Step 1: 실패 테스트** — 스펙 §9.3.2 · §9.3.3 표 전체 + search · suggest · usage 줄:
  - tag_sync: 표 8행 그대로(`#제주` 1 → 2 → 휴지통 1 → 0(목록에서 사라짐, tags 행 남음) → 복원 1(같은 tags.id) · `#제주`→`#부산` 교체 시 -1/+1 · 영구 삭제 시 entry_tags 삭제와 쓰지 않는 tags 정리 · 휴지통 기록만 가진 태그 검색 0). **각 단계는 같은 `watchTagCounts` 구독의 연속 이벤트로 검증**(스트림이 반영하는지).
  - place_sync: 표 7행 그대로(오프라인 기록 이름 채우기 행은 T8 의 `fillPlaceName` 이 생긴 뒤 T8 에서 추가 — 여기서는 6행).
  - search: 부분 일치 · ASCII 대소문자 무시 · `100%` · `a_b` · `c:\dir` 이 글자 그대로만 매치 · 휴지통 제외 · occurredAt 최신순 · 한글 · 이모지 검색 · 태그 · 장소 필터가 스토리를 넘나듦 · 스토리 제목 검색(기본 스토리는 dailyTitle '일상' 으로 찾힘).
  - suggest: `'제'` → `제주(3)` `제천(1)` 순 · 같은 count 는 lastUsedAt 최신 먼저 · 빈 query 상위 N · `'#JE'` 입력이 `jeju` 와 매치(정규화) · Review Focus 2.
  - usage: 사진/영상 개수 · bytes 합 · 휴지통 기록 bytes 는 trashBytes 로 따로(합계에도 포함).
- [ ] **Step 2:** FAIL.
- [ ] **Step 3:** 구현(`customSelect` + `readsFrom`).
- [ ] **Step 4:** PASS + 뮤테이션.
- [ ] **Step 5: Commit** `feat(walk): 일기 태그 · 장소 집계와 검색을 더한다`.

---

## 단계 B — 미디어 · 위치 · 유스케이스

### T7: 미디어 저장 · 압축

**Files:**
- Create: `apps/walk/lib/domain/diary/media/media_store.dart` · `media_processor.dart`
- Create: `apps/walk/lib/data/diary/media/file_media_store.dart` · `plugin_media_processor.dart`
- Test: `apps/walk/test/data/diary/media/file_media_store_test.dart` · `plugin_media_processor_test.dart` · `apps/walk/test/support/fake_media_processor.dart`

**Interfaces (Produces):**
```dart
// media_processor.dart (domain)
abstract interface class MediaProcessor {
  /// [source] 를 [target] 에 긴 변 1600 · JPEG 85 · EXIF 제거로 쓴다. 원본보다 키우지 않는다.
  Future<({int width, int height})> compressPhoto(File source, File target);
  /// 길이 확인(ms). 읽지 못하면 예외.
  Future<int> videoDurationMs(File source);
  /// 720p 로 [target] 에 쓰고 썸네일을 [thumb] 에 쓴다.
  Future<({int width, int height, int durationMs})> compressVideo(File source, File target, File thumb);
}
// media_store.dart (domain)
abstract interface class MediaStore {
  /// 원본을 읽기만 하고 압축 사본을 tmp/<id>.jpg 에 만든다. EntryMedia.path = 'tmp/<id>.jpg'.
  Future<Result<EntryMedia>> importPhoto(String sourcePath);
  /// 길이 > 30초면 Err(videoTooLong) — 압축 전에 확인. path 'tmp/<id>.mp4', thumbPath 'tmp/<id>_thumb.jpg'.
  Future<Result<EntryMedia>> importVideo(String sourcePath);
  /// tmp/ → media/ 로 옮긴 EntryMedia(경로만 바뀜). 이미 media/ 면 그대로.
  Future<EntryMedia> promote(EntryMedia media);
  /// promote 를 되돌린다(DB 저장 실패 시): media/ → tmp/.
  Future<void> demote(EntryMedia media);
  Future<void> discard(Iterable<EntryMedia> media);           // tmp 파일 삭제(path · thumbPath)
  Future<void> deleteFiles(Iterable<String> relativePaths);   // best-effort, 예외 삼킴
  File resolve(String relativePath);
  /// media/ 아래 [keep] 에 없는 파일, tmp/ 아래 [now] 기준 24시간 지난 파일을 지운다.
  Future<void> cleanOrphans(Set<String> keep, DateTime now);
}
```
- `FileMediaStore(@Named('diaryRoot') Directory root, IdGenerator ids, MediaProcessor processor)`. 처리 중 예외는 `Err(Failure.validation(field: DiaryFailure.mediaProcessing.name))` + 부분 파일 삭제.
- `PluginMediaProcessor`: T1 스파이크로 정한 패키지. 작은 사진은 먼저 `decodeImageFromList` 없이 `flutter_image_compress` 의 `minWidth/minHeight` 를 원본 크기와 1600 중 작은 값으로(스파이크 결과에 따름).

- [ ] **Step 1: 실패 테스트**(임시 디렉터리 + `FakeMediaProcessor`):
  - store: 원본 파일 바이트가 import 전후 같음 · 결과 path 가 `tmp/` 상대 경로 · `promote` 후 `media/` 에 있고 tmp 에 없음 · `demote` 원복 · `discard` 로 tmp 삭제(썸네일 포함) · 처리기 예외 → `Err(mediaProcessing)` + tmp 에 남은 파일 0 · 31초 영상 → `Err(videoTooLong)` 이고 `compressVideo` 호출 안 됨 · id 두 번 import 해도 경로 충돌 없음 · `cleanOrphans`: keep 에 있는 media 파일 유지 / 없는 것 삭제 / tmp 23시간 유지 · 25시간 삭제 · 휴지통 기록 경로(keep 에 포함)는 유지.
  - processor(mock MethodChannel, `flutter_image_compress` · 영상 플러그인 채널 이름은 스파이크에서 확인): 사진 호출 인자에 1600 · 85 · keepExif false · jpeg · 1000px 원본이면 1000 으로.
- [ ] **Step 2:** FAIL.
- [ ] **Step 3:** 구현 + DI(`@LazySingleton(as: MediaStore)`, `@LazySingleton(as: MediaProcessor)`).
- [ ] **Step 4:** PASS + 뮤테이션.
- [ ] **Step 5: Commit** `feat(walk): 일기 사진 · 영상을 압축 사본으로 저장한다`.

### T8: 현재 위치 · 장소 이름

**Files:**
- Create: `apps/walk/lib/domain/diary/location/place_source.dart` · `apps/walk/lib/data/diary/location/current_place_source.dart` · `geocoding_place_namer.dart`
- Modify: `diary_repository.dart` · `drift_diary_repository.dart`(장소 채우기)
- Test: `apps/walk/test/data/diary/location/current_place_source_test.dart` · `apps/walk/test/data/diary/drift_diary_repository_place_fill_test.dart` · `drift_diary_repository_place_sync_test.dart`(오프라인 행 추가)

**Interfaces (Produces):**
```dart
abstract interface class PlaceNamer { Future<String?> nameFor(double lat, double lng); } // 실패 · 네트워크 없음 → null
abstract interface class PlaceSource {
  /// 위치 서비스 꺼짐 · 권한 거부 · 10초 타임아웃 → null(오류 아님). 좌표는 있고 이름이 없으면 placeName null.
  Future<EntryLocation?> current();
  Future<String?> nameFor(double lat, double lng);
}
// 장소 이름 조합: [locality, subLocality, thoroughfare] 중 비지 않은 앞의 두 개를 공백으로(스파이크 결과로 필드 확정).
// 저장소 추가
Future<List<DiaryEntry>> entriesMissingPlaceName();  // 좌표 있고 placeId null, 휴지통 제외
Future<Result<void>> fillPlaceName(String entryId, String name); // places 재사용
```
- `CurrentPlaceSource(LocationAccess access, LocationGateway gateway, PlaceNamer namer)` — `LocationAccess` 는 `@lazySingleton` 모듈 getter 로 하나만(권한 세션 기억).

- [ ] **Step 1: 실패 테스트** — 스펙 §9.4 위치 줄 + §9.3.3 오프라인 두 행: 서비스 꺼짐 null · 권한 거부 null · 타임아웃 null · namer null → 좌표만 · 이름 조합 · 채우기 대상은 휴지통 제외(복원하면 다시 대상) · 채우면 같은 이름 장소와 합쳐짐 · 채운 순간 `watchPlaceCounts` +1.
- [ ] **Step 2:** FAIL. **Step 3:** 구현 + DI. **Step 4:** PASS + 뮤테이션.
- [ ] **Step 5: Commit** `feat(walk): 일기에 현재 위치와 장소 이름을 붙인다`.

### T9: 일기 유스케이스 · 설정 저장

**Files:**
- Create: `apps/walk/lib/domain/diary/usecase/diary_use_case.dart` · `story_suggestion.dart` · `apps/walk/lib/domain/diary/repository/diary_preferences.dart` · `apps/walk/lib/data/diary/prefs_diary_preferences.dart`
- Test: `apps/walk/test/domain/diary/usecase/diary_use_case_test.dart` · `story_suggestion_test.dart`(스펙 §9.2 의 `default_story_test` 내용도 여기 — lib 1:1) · `apps/walk/test/data/diary/prefs_diary_preferences_test.dart`

**Interfaces (Produces):**
```dart
// diary_preferences.dart
abstract interface class DiaryPreferences {
  TrashRetention get trashRetention; Future<void> setTrashRetention(TrashRetention v);
  String? get lastViewedStoryId; Future<void> setLastViewedStoryId(String? id); // null = '전체'
  DiaryViewMode get viewMode; Future<void> setViewMode(DiaryViewMode v);
}
// prefs 키: 'walk.diary.trashRetention' · 'walk.diary.lastViewedStory' · 'walk.diary.viewMode'. 깨진 값 → 기본값.

// story_suggestion.dart — 순수
abstract final class StorySuggestion {
  /// 작성 기본값: open 중 lastPostedAt 최신(null 은 createdAt), 없으면 'daily'.
  static String defaultFor(List<Story> stories);
  /// 시각 변경 제안: covers(at) 인 open 스토리 중 기본 스토리를 뺀 것의 lastPostedAt 최신, 없으면 'daily'.
  static String forTime(List<Story> stories, DateTime at);
}

// diary_use_case.dart
@lazySingleton
class DiaryUseCase {
  DiaryUseCase(DiaryRepository repo, MediaStore media, PlaceSource places, DiaryPreferences prefs, Clock clock);
  /// draft.validate(now) → 새 미디어 promote → create/update → 실패 시 promote 한 것 demote.
  /// 수정이면 기존에 있었는데 draft 에 없는 미디어의 파일을 **DB 저장 성공 뒤** 지운다.
  Future<Result<DiaryEntry>> save(EntryDraft draft, {String? editingId});
  Future<void> cancelDraft(List<EntryMedia> newMedia);   // tmp 정리
  Future<Result<void>> trash(String id);
  Future<Result<DiaryEntry>> restore(String id);
  Future<Result<void>> purge(List<String> ids);          // repo.purgeEntries → media.deleteFiles(경로)
  Future<Result<void>> emptyTrash();
  Future<Result<void>> deleteStory(String id);
  /// 일기 탭 진입 시: 기한 지난 휴지통 영구 삭제(+파일) → 장소 이름 채우기(네트워크 실패면 다음에).
  Future<void> maintain();
  /// 앱 시작 시: media.cleanOrphans(repo.allMediaPaths(), now).
  Future<void> cleanOrphans();
}
```

- [ ] **Step 1: 실패 테스트**(실제 drift 메모리 DB + 실제 `FileMediaStore`(임시 디렉터리) + `FakeMediaProcessor` + 고정 Clock — **파일이 실제로 지워지는지는 여기서 본다**):
  - story_suggestion(`defaultFor` · `forTime`): 스펙 §9.2 의 default_story · story_suggestion 두 줄 그대로.
  - use case 연쇄 삭제(스펙 §9.3 trash 파일 부분): 사진2+영상1 기록 purge → `media/` 아래 파일 0(썸네일 포함) · 다른 기록 파일 유지 · emptyTrash 여러 개 · `maintain` 이 day7 기한 지난 것만 지움(6일 23:59:59 남음, 7일 지움) · never 면 안 지움 · `deleteFiles` 가 던져도 purge 는 Ok, 다음 `cleanOrphans` 가 회수.
  - restore 후 파일이 열림(길이 > 0) · 피드에 쓸 경로가 그대로(§9.3.1 파일 부분).
  - save: 새 미디어 promote 됨 · DB 실패(닫힌 스토리) 시 promote 한 파일이 tmp 로 돌아감(Review Focus 1) · 수정 중 뺀 미디어 파일은 저장 성공 뒤에만 삭제 · 취소(`cancelDraft`) 시 tmp 0.
  - prefs: 기본값 · 왕복 · 깨진 타입(`int` 자리에 `String`) → 기본값.
- [ ] **Step 2:** FAIL. **Step 3:** 구현 + DI. **Step 4:** PASS + 뮤테이션.
- [ ] **Step 5: Commit** `feat(walk): 일기 저장 · 휴지통 정리 흐름을 묶는다`.

---

## 단계 C — 잠금

### T10: 잠금 도메인 · 저장

**Files:**
- Create: `apps/walk/lib/domain/lock/lock_config.dart` · `lock_attempts.dart` · `lock_policy.dart` · `relock_timer.dart` · `lock_repository.dart` · `device_auth.dart`
- Create: `apps/walk/lib/data/lock/prefs_lock_repository.dart` · `local_auth_device_auth.dart` · `secret_hasher.dart`
- Test: `apps/walk/test/domain/lock/lock_policy_test.dart` · `relock_timer_test.dart` · `apps/walk/test/data/lock/prefs_lock_repository_test.dart` · `secret_hasher_test.dart` · `local_auth_device_auth_test.dart`

**Interfaces (Produces):**
```dart
enum LockMethod { pin, pattern }
enum RelockDelay { immediate(Duration.zero), seconds30(Duration(seconds: 30)), minute1(Duration(minutes: 1)), minutes5(Duration(minutes: 5));
  const RelockDelay(this.duration); final Duration duration; static const fallback = RelockDelay.minute1; }
@freezed class LockConfig with _$LockConfig { final bool enabled; final LockMethod method; final RelockDelay relockDelay;
  const LockConfig({this.enabled = false, this.method = LockMethod.pin, this.relockDelay = RelockDelay.fallback}); }
@freezed class LockAttempts with _$LockAttempts { final int failures; final DateTime? blockedUntil; final bool longBlock;
  const LockAttempts({this.failures = 0, this.blockedUntil, this.longBlock = false}); }
abstract final class LockPolicy {
  static const maxFailures = 5; static const shortBlock = Duration(seconds: 30); static const longBlock = Duration(hours: 24);
  static LockAttempts wrongSecret(LockAttempts a, DateTime now);   // 5회째 blockedUntil=now+30s, failures=0
  static LockAttempts deviceAuthFailed(DateTime now);              // blockedUntil=now+24h, longBlock=true
  static LockAttempts success();                                   // 초기화
  /// 차단 중이면 남은 시간. now < blockedUntil 만 차단. 시계가 blockedUntil-기간 보다 앞으로 거꾸로 가면 남은 시간을 전체 기간으로 본다(보수적).
  static Duration? remaining(LockAttempts a, DateTime now);
}
abstract final class RelockTimer {
  /// pausedAt 이 없으면 false. pickingMedia 면 false. now < pausedAt(시계 역행) 이면 true. now - pausedAt >= delay 면 true.
  static bool shouldLock({required DateTime? pausedAt, required DateTime now, required RelockDelay delay, required bool pickingMedia});
}
// secret: PIN 은 '1234', 패턴은 점 인덱스(0~8)를 '-' 로 이은 '0-1-2-5'.
abstract final class PatternRule {
  static const minDots = 4;
  /// 드래그로 지난 점 목록에 건너뛴 가운데 점을 끼워 넣는다(이미 쓴 점이면 넣지 않음). 0→2 이면 1 포함.
  static List<int> withSkipped(List<int> dots);
}
abstract interface class LockRepository {
  /// 깨진 prefs(해시 · salt 중 하나만 있음, 타입 오류) → enabled=true 로 돌려 잠금을 유지한다.
  LockConfig loadConfig(); Future<void> saveConfig(LockConfig c);
  Future<void> setSecret(LockMethod m, String secret); bool verify(String secret); bool get hasSecret;
  LockAttempts loadAttempts(); Future<void> saveAttempts(LockAttempts a);
  Future<void> clearSecret();
}
enum DeviceAuthResult { success, failed, canceled, unavailable, lockedOut }
abstract interface class DeviceAuth { Future<bool> hasScreenLock(); Future<DeviceAuthResult> authenticate(String reason); }
// secret_hasher.dart: salt 16바이트(Random.secure) base64, 해시 = sha256 를 10,000번 반복(salt + secret 시작). 비교는 상수 시간.
// prefs 키: 'walk.lock.enabled' · 'walk.lock.method' · 'walk.lock.relock' · 'walk.lock.salt' · 'walk.lock.hash' · 'walk.lock.failures' · 'walk.lock.blockedUntil' · 'walk.lock.longBlock'
```

- [ ] **Step 1: 실패 테스트** — 스펙 §9.2 잠금 두 줄 · §9.4 잠금 두 줄:
  - policy: 4회 실패 차단 없음 · 5회째 30초 · 30초 뒤 `remaining` null 이고 failures 0 · 폰 인증 실패 → 24시간 · 24시간 - 1초 차단, 24시간 해제 · 성공하면 초기화 · 시계가 차단 시작 전으로 가면 전체 기간(Review Focus 5).
  - relock: immediate 는 0초에도 true · 30초: 29.999초 false / 30초 true · 1분 · 5분 경계 · pickingMedia 면 10분이어도 false · pausedAt null false · 역행 true.
  - pattern: `withSkipped([0,2])` → `[0,1,2]` · `[0,8]` → `[0,4,8]` · `[1,0,2]`(1 이미 사용) → `[1,0,2]` · `[3,5]` → `[3,4,5]`.
  - prefs: 원문 '1234' 가 prefs 어떤 값에도 없음 · 같은 PIN 두 번 setSecret 하면 해시가 다름 · verify 성공/실패 · 패턴 '0-1-2-5' ≠ '5-2-1-0' · 시도 기록이 새 인스턴스(재시작)에서도 유지 · hash 만 있고 salt 없음 → `loadConfig().enabled == true` 이고 `verify` 는 항상 false(재설정 유도).
  - device auth(mock `local_auth` 채널): canCheckBiometrics/isDeviceSupported false → `hasScreenLock` false · 성공 · false 반환 → failed · `PlatformException(code: 'NotAvailable')` → unavailable · `'LockedOut'`/`'PermanentlyLockedOut'` → lockedOut · 사용자 취소 코드 → canceled(스파이크에서 확인한 코드).
- [ ] **Step 2:** FAIL. **Step 3:** 구현 + DI. **Step 4:** PASS + 뮤테이션.
- [ ] **Step 5: Commit** `feat(walk): 일기 잠금 규칙과 저장을 더한다`.

### T11: 잠금 화면 · 게이트

**Files:**
- Create: `apps/walk/lib/presentation/lock/cubit/diary_lock_cubit.dart`(+state) · `lock_setup_cubit.dart`(+state)
- Create: `apps/walk/lib/presentation/lock/widget/pin_pad.dart` · `pattern_lock.dart` · `diary_lock_gate.dart` · `apps/walk/lib/presentation/lock/page/lock_setup_page.dart` · `apps/walk/lib/presentation/lock/media_pick_guard.dart`
- Modify: ARB 3개(`walkLock*`)
- Test: 각 파일 대응 `test/presentation/lock/...`

**Interfaces (Produces):**
```dart
@freezed sealed class DiaryLockState with _$DiaryLockState {
  const factory DiaryLockState.unlocked() = LockUnlocked;
  const factory DiaryLockState.locked({required LockMethod method, Duration? blockedFor, @Default(false) bool longBlock, @Default(false) bool wrong}) = LockLocked;
  const factory DiaryLockState.resetting() = LockResetting;   // 폰 인증 성공 → 새 비밀 등록 화면
}
class DiaryLockCubit extends Cubit<DiaryLockState> {
  DiaryLockCubit(LockRepository repo, DeviceAuth auth, Clock clock, MediaPickGuard guard);
  void start();                         // 잠금 꺼짐 → unlocked, 켜짐 → locked
  Future<void> submit(String secret);
  Future<void> forgot(String reason);   // DeviceAuth → success: resetting / failed: 24h / canceled: 그대로
  void onPaused(); void onResumed();    // RelockTimer
  void tick();                          // 차단 남은 시간 갱신(1초 Timer 는 위젯이)
  Future<void> finishReset(LockMethod method, String secret);
}
/// 미디어 선택 · 카메라로 나가는 동안 true. image_picker 호출부가 run 으로 감싼다.
@lazySingleton class MediaPickGuard { bool get active; Future<T> run<T>(Future<T> Function() pick); }
/// child 는 unlocked 일 때만 build 한다(트리에서 아예 뺀다).
class DiaryLockGate extends StatelessWidget { const DiaryLockGate({required this.child}); }
class PinPad extends StatelessWidget { const PinPad({required this.onCompleted, this.enabled = true, this.error = false}); } // 4자리
class PatternLock extends StatefulWidget { const PatternLock({required this.onCompleted, this.enabled = true}); } // List<int> 콜백(withSkipped 적용 후)
```
- `lock_setup_cubit`: `hasScreenLock` false → `needsScreenLock` 상태 · 첫 입력 → 확인 입력 → 불일치 오류 · 패턴 3점 이하 거절 · 끄기 · 방식 변경은 현재 비밀 확인 뒤.

- [ ] **Step 1: 실패 테스트** — 스펙 §9.5 잠금 두 줄 · §9.6 PIN · 패턴 줄:
  - lock cubit(bloc_test): 꺼짐 unlocked · 시작 locked · 맞으면 unlocked · 틀리면 wrong · 5회째 blockedFor 30초 · 차단 중 submit 무시 · forgot 성공 resetting / 실패 longBlock 24h / 취소 locked 유지 · paused → resumed(1분 설정, 70초 뒤 locked, 50초 뒤 unlocked) · guard.active 동안 paused → resumed(3분) unlocked · **재시작(새 cubit + 같은 prefs) 시 차단 유지**(Review Focus 5).
  - pin pad: 4번째 숫자에서 onCompleted('1234') · 지우기 · enabled false 면 탭 무시 · 점 4개 표시.
  - pattern: 드래그 0→1→2→5 → `[0,1,2,5]` · 0→2 드래그 → `[0,1,2]` · 같은 점 재방문 무시 · 3점이면 onCompleted 안 부르고 오류 표시.
  - gate: locked 상태에서 `find.byKey(childKey)` 없음 · unlocked 에서 있음.
- [ ] **Step 2:** FAIL. **Step 3:** 구현 + l10n(`walkLockTitle` · `walkLockWrong` · `walkLockBlocked`(남은 초 placeholder) · `walkLockBlockedLong`(남은 시간) · `walkLockForgot` · `walkLockDeviceReason` · `walkLockSetupPin` · `walkLockSetupPattern` · `walkLockSetupConfirm` · `walkLockSetupMismatch` · `walkLockSetupTooShort` · `walkLockNeedsScreenLock`) → gen-l10n → trader convention. **Step 4:** PASS + 뮤테이션.
- [ ] **Step 5: Commit** `feat(walk): 일기 잠금 화면과 PIN · 패턴 입력을 더한다`.

---

## 단계 D — 화면

### T12: 셸 4탭 · 일기 탭 · 타임라인 cubit · 스토리 바

**Files:**
- Modify: `apps/walk/lib/presentation/shell/page/main_shell_page.dart`(`ShellTab { alarm, walk, diary, settings }`, `IndexedStack` 에 `DiaryTab`, 아이콘 `Icons.book_outlined`/`Icons.book`) · `test/presentation/shell/page/main_shell_page_test.dart`
- Create: `apps/walk/lib/presentation/diary/page/diary_tab.dart` · `apps/walk/lib/presentation/diary/cubit/diary_timeline_cubit.dart`(+state) · `apps/walk/lib/presentation/diary/widget/story_bar.dart` · `story_avatar.dart`
- Modify: ARB(`walkShellTabDiary` · `walkDiaryDailyStoryTitle`='일상' · `walkDiaryAll`='전체' · `walkDiaryArchive`='보관함' · `walkDiaryEmpty`)
- Test: `test/presentation/diary/page/diary_tab_test.dart` · `test/presentation/diary/cubit/diary_timeline_cubit_test.dart` · `test/presentation/diary/widget/story_bar_test.dart`

**Interfaces (Produces):**
```dart
@freezed class DiaryTimelineState with _$DiaryTimelineState {
  final List<Story> openStories; final List<Story> archived; final String? selectedStoryId; // null = 전체
  final DiaryViewMode viewMode; final List<DiaryEntry> entries; final bool loading;
  const DiaryTimelineState({...});
}
class DiaryTimelineCubit extends Cubit<DiaryTimelineState> {
  DiaryTimelineCubit(DiaryRepository repo, DiaryPreferences prefs);
  void start();                      // 마지막 스토리 · 모드 복원(지워진 스토리면 '전체'), stories · entries 구독
  void selectStory(String? storyId); // 이전 entries 구독 취소 후 새 필터 구독(늦은 이벤트 버림)
  void setViewMode(DiaryViewMode m);
}
/// 탭 진입(active false→true)마다 DiaryUseCase.maintain(). 잠금 게이트 안쪽에 타임라인.
class DiaryTab extends StatefulWidget { const DiaryTab({required this.active}); }
```
- 셸: 앱 시작 시 `DiaryUseCase.cleanOrphans()` 한 번(기다리지 않음, 예외 삼킴). `AppLifecycleListener` 의 `onPause`/`onResume` 을 `DiaryLockCubit` 에 전달. **알람 울림 화면은 셸 바깥 navigator 라 게이트와 무관**(테스트로 확인).

- [ ] **Step 1: 실패 테스트** — 스펙 §9.5 타임라인 줄 · §9.6 일기 탭 · 셸 줄:
  - cubit: 마지막 스토리 복원 · 지워진 스토리 id 면 전체 · 전환 · 전체 · 모드 저장/복원 · 저장 · 삭제 · 복원 후 entries 갱신(스트림) · 스토리 전환 직후 옛 스트림의 늦은 이벤트 무시.
  - 탭: 잠김 동안 타임라인 위젯 없음 · 해제 후 스토리 바 순서(open lastPostedAt 순, 끝에 보관함) · 기본 스토리 이름 '일상' · 빈 상태 `AppPlaceholder` · 탭이 active 될 때 `maintain` 호출 1회.
  - 셸: 탭 4개 순서 · 일기 잠금 중 알람 울림 라우트 push 시 울림 화면 보임.
- [ ] **Step 2:** FAIL. **Step 3:** 구현 + l10n. **Step 4:** PASS + 뮤테이션.
- [ ] **Step 5: Commit** `feat(walk): 하단 탭에 일기를 더하고 스토리 바로 기록을 본다`.

### T13: 보기 모드 3종

**Files:**
- Create: `apps/walk/lib/presentation/diary/widget/view_mode_switch.dart` · `prose_view.dart` · `feed_view.dart` · `reels_view.dart` · `entry_media_view.dart`(사진 `Image.file` cacheWidth · 영상 썸네일 + `video_player`) · `entry_meta.dart`(시각 · 위치 · 태그 · 스토리 이름)
- Create: `apps/walk/lib/presentation/diary/format/diary_format.dart`(날짜 머리 · 시각 · "지금")
- Test: `test/presentation/diary/widget/view_modes_test.dart` · `test/presentation/diary/format/diary_format_test.dart`

**Interfaces (Produces):**
```dart
class DiaryEntriesView extends StatelessWidget {
  const DiaryEntriesView({required this.mode, required this.entries, required this.showStoryName,
    required this.storyTitles /* Map<String,String> */, required this.onOpen /* (DiaryEntry) */});
} // mode 로 ProseView · FeedView · ReelsView 중 하나
```
- 줄글: 날짜 머리(같은 날 묶음) + 글 + 썸네일 줄. 피드: 카드, 미디어 `PageView` 좌우, 본문 6줄 접기 + "더 보기"(Review Focus 3). 릴스: 세로 `PageView` · 가로 미디어 `PageView` · 영상은 보이는 페이지만 재생, 화면 밖 컨트롤러 dispose · 글 하단 오버레이.
- `video_player` 는 테스트에서 위젯 주입(`EntryMediaView` 가 `VideoSurfaceBuilder` 를 받아 테스트는 가짜 위젯).

- [ ] **Step 1: 실패 테스트** — 스펙 §9.6 보기 모드 줄: 같은 entries 로 세 모드가 각자 핵심 위젯을 그림 · 피드 좌우 넘김으로 2번째 미디어 · 릴스 세로 넘김으로 다음 기록 · 가로로 다음 미디어 · showStoryName 일 때만 스토리 이름 · 위치 '📍 애월읍' · 태그 칩 · 미디어 없는 기록 · 1만 자 본문이 피드에서 접히고 "더 보기"로 펼침 · 릴스에서 화면 밖으로 넘긴 영상 surface 가 dispose 됨 · format(오늘 · 어제 · 올해 · 지난해 날짜 머리, ko).
- [ ] **Step 2:** FAIL. **Step 3:** 구현 + l10n. **Step 4:** PASS + 뮤테이션.
- [ ] **Step 5: Commit** `feat(walk): 일기를 줄글 · 피드 · 릴스로 본다`.

### T14: 작성 · 수정 화면

**Files:**
- Create: `apps/walk/lib/presentation/diary/cubit/entry_editor_cubit.dart`(+state) · `apps/walk/lib/presentation/diary/page/entry_editor_page.dart` · `apps/walk/lib/presentation/diary/widget/time_row.dart` · `story_picker_sheet.dart` · `tag_chip_input.dart` · `place_input.dart` · `media_strip.dart`
- Create: `apps/walk/lib/presentation/diary/media_picker.dart`(image_picker 래퍼, `MediaPickGuard.run` 사용)
- Test: `test/presentation/diary/cubit/entry_editor_cubit_test.dart` · `test/presentation/diary/page/entry_editor_page_test.dart` · `test/presentation/diary/widget/tag_chip_input_test.dart`

**Interfaces (Produces):**
```dart
@freezed class EntryEditorState with _$EntryEditorState {
  final String? editingId; final EntryDraft draft; final DateTime createdAt; // 새 기록이면 열린 시각
  final List<Story> openStories; final bool locating; final bool manualPlace; final bool saving;
  final List<EntryMedia> newMedia; final DiaryFailure? error; final bool saved;
  const EntryEditorState({...});
}
class EntryEditorCubit extends Cubit<EntryEditorState> {
  EntryEditorCubit(DiaryUseCase useCase, DiaryRepository repo, MediaStore media, PlaceSource places, Clock clock);
  Future<void> startNew();                   // 기본 스토리(StorySuggestion.defaultFor), 시각 now, 위치 조회
  Future<void> startEdit(String entryId);
  void setTime(DateTime at);                 // 미래면 무시. 과거로 바뀌면 위치 제거 + manualPlace, 스토리 제안
  void revertTime();                         // occurredAt = createdAt
  void setStory(String storyId); void setBody(String body);
  void addTag(String raw); void removeTag(String name);   // TagName.normalize, 중복 무시
  void setPlaceName(String? name); void clearLocation();
  Future<void> addMedia(List<({String path, MediaKind kind})> picked); // MediaLimits 초과분 거절 + error
  void removeMedia(String mediaId); void reorderMedia(int from, int to);
  Future<void> save(); Future<void> cancel();
}
```
- 시각 선택: `showDatePicker`(lastDate: today) → 시각은 `AlarmTimeWheel` 재사용(바텀시트). 오늘을 고르면 지금 이후 시각은 휠에서 막는다.
- 태그 · 장소 입력 추천은 `repo.watchTagCounts(query:)` · `watchPlaceCounts(query:)`.

- [ ] **Step 1: 실패 테스트** — 스펙 §9.5 작성 줄 · §9.6 작성 화면 줄 + Review Focus 2:
  - cubit: 기본 스토리 · 과거 시각 → 위치 제거 + manualPlace · 시각이 '제주 여행' 기간이면 그 스토리 제안 · 되돌리기 · 11개째 거절(10개만 추가되고 error tooManyMedia) · 31초 영상 거절 · `'#Jeju'` 후 `'jeju '` 추가 시 칩 1개 · 빈 기록 저장 불가(emptyEntry) · 저장 중 save 두 번 → 저장 1번 · 취소 → tmp 정리(`MediaStore.discard` 호출) · 수정에서 뺀 미디어는 save 성공 뒤에만 파일 삭제.
  - page: 시각 행 '지금' ↔ 날짜 문구 · 되돌리기 버튼은 다를 때만 · 스토리 시트에 open 만 · 칩 추가/삭제 · 추천 탭 → 칩 · 위치 ✕ → 사라짐 · 과거 시각이면 장소 직접 입력칸.
- [ ] **Step 2:** FAIL. **Step 3:** 구현 + l10n. **Step 4:** PASS + 뮤테이션.
- [ ] **Step 5: Commit** `feat(walk): 일기 기록을 쓰고 고친다`.

### T15: 기록 상세 · 스토리 관리

**Files:**
- Create: `apps/walk/lib/presentation/diary/page/entry_detail_page.dart`(보기 + ⋮ 수정 · 삭제) · `story_manage_page.dart`(목록 · 만들기 · 닫기 · 다시 열기 · 이름 · 표지 · 삭제) · `story_form_sheet.dart` · `apps/walk/lib/presentation/diary/cubit/story_manage_cubit.dart`(+state)
- Test: 대응 테스트

**Interfaces (Produces):**
```dart
class StoryManageCubit extends Cubit<StoryManageState> {
  StoryManageCubit(DiaryRepository repo, DiaryUseCase useCase, Clock clock);
  Future<void> create({required String title, required DateTime startedAt, DateTime? endedAt});
  Future<List<DiaryEntry>> dailyEntriesIn(DateTime from, DateTime to); // 지난 기간 → '일상' 기록 제안
  Future<void> moveIn(List<String> entryIds, String storyId);
  Future<void> close(String id, {DateTime? at}); Future<void> reopen(String id);
  Future<void> rename(String id, String title); Future<void> setCover(String id, String? mediaId);
  Future<void> delete(String id); // AppConfirmDialog(isDestructive) 는 화면이
}
```

- [ ] **Step 1: 실패 테스트:** 만들기(종료일 있으면 보관함) · 지난 기간 생성 시 그 기간 '일상' 기록 목록 · 선택 이동 · 닫기 · 다시 열기 · 기본 스토리 메뉴에 닫기 · 삭제 없음 · 삭제 확인 후 기록이 휴지통으로 · 상세에서 삭제 → 확인 → 휴지통 + 스낵바(`AppSnackBar`) · 표지 선택 시트에 그 스토리 사진만.
- [ ] **Step 2:** FAIL. **Step 3:** 구현 + l10n. **Step 4:** PASS + 뮤테이션.
- [ ] **Step 5: Commit** `feat(walk): 일기 스토리를 만들고 닫고 지운다`.

### T16: 검색 · 태그/장소 모아보기

**Files:**
- Create: `apps/walk/lib/presentation/diary/cubit/diary_search_cubit.dart`(+state) · `tag_feed_cubit.dart` · `place_feed_cubit.dart` · `apps/walk/lib/presentation/diary/page/diary_search_page.dart` · `filtered_entries_page.dart` · `apps/walk/lib/presentation/diary/widget/highlighted_text.dart`
- Test: 대응 테스트

**Interfaces (Produces):**
```dart
enum SearchScope { body, story, tag, place }
class DiarySearchCubit extends Cubit<DiarySearchState> {
  DiarySearchCubit(DiaryRepository repo, {required String dailyTitle, Duration debounce = const Duration(milliseconds: 300)});
  void setScope(SearchScope s); void setQuery(String q);
} // state: scope, query, suggestions(List<NamedCount>) | stories(List<({Story story, int count})>) | bodyResults(List<DiaryEntry>)
/// 태그 · 장소 공통 — EntryFilter 를 받아 구독
class FilteredEntriesCubit extends Cubit<FilteredEntriesState> { FilteredEntriesCubit(DiaryRepository repo, EntryFilter filter, DiaryPreferences prefs); }
```
(스펙 §9.5 의 `tag_feed_cubit` · `place_feed_cubit` 은 같은 동작이라 `FilteredEntriesCubit` 하나와 `test/presentation/diary/cubit/filtered_entries_cubit_test.dart` 하나로 합친다 — 테스트는 tag 와 place 두 그룹으로.)

- [ ] **Step 1: 실패 테스트** — 스펙 §9.5 검색 · 모아보기 · §9.6 검색 화면:
  - search cubit(fakeAsync): 탭 4개 · 299ms 에는 조회 안 함, 300ms 에 1번 · 빠른 연속 입력은 마지막만 · 빈 입력 상위 N · 추천이 떠 있는 동안 기록을 휴지통으로 보내면 개수 감소 · 복원하면 증가 · 늦은 응답 버림.
  - filtered(tag/place 각각): 열린 상태에서 추가 → +1 · 휴지통 → -1 · 복원 → +1 · 마지막이 사라지면 빈 상태.
  - page: 탭 전환 · 추천 행의 개수 표시 · 본문 결과 일치 부분 `TextSpan` 굵게 · 스토리 항목 탭 → 타임라인 그 스토리 선택(콜백).
- [ ] **Step 2:** FAIL. **Step 3:** 구현 + l10n. **Step 4:** PASS + 뮤테이션.
- [ ] **Step 5: Commit** `feat(walk): 일기 글 · 스토리 · 태그 · 장소를 검색한다`.

### T17: 휴지통 화면

**Files:**
- Create: `apps/walk/lib/presentation/diary/cubit/trash_cubit.dart`(+state) · `apps/walk/lib/presentation/diary/page/trash_page.dart`
- Test: 대응 테스트

**Interfaces (Produces):**
```dart
class TrashCubit extends Cubit<TrashState> {
  TrashCubit(DiaryRepository repo, DiaryUseCase useCase, DiaryPreferences prefs, Clock clock);
  Future<void> restore(String id); Future<void> purge(String id); Future<void> emptyAll();
} // state.items: List<({DiaryEntry entry, int? daysLeft})> — never 면 null
```
- [ ] **Step 1: 실패 테스트:** 목록 deletedAt 최신순 · 남은 일수(day7, 2일 전 삭제 → 5) · never 면 표시 없음 · 복원 · 영구 삭제(확인 다이얼로그 후) · 비우기 · 빈 상태.
- [ ] **Step 2:** FAIL. **Step 3:** 구현 + l10n. **Step 4:** PASS + 뮤테이션.
- [ ] **Step 5: Commit** `feat(walk): 일기 휴지통 화면을 더한다`.

### T18: 설정 탭 항목

**Files:**
- Modify: `apps/walk/lib/presentation/settings/page/settings_page.dart` · `test/presentation/settings/page/settings_page_test.dart`
- Create: `apps/walk/lib/presentation/settings/cubit/diary_settings_cubit.dart`(+state) · `apps/walk/lib/presentation/settings/widget/diary_settings_section.dart`
- Test: `test/presentation/settings/cubit/diary_settings_cubit_test.dart`

**Interfaces (Produces):**
```dart
class DiarySettingsCubit extends Cubit<DiarySettingsState> {
  DiarySettingsCubit(LockRepository lock, DiaryPreferences prefs, DiaryRepository repo);
  Future<void> load();   // lock config · retention · usage
  Future<void> setRelockDelay(RelockDelay d); Future<void> setRetention(TrashRetention r);
} // 잠금 켜기/끄기 · 방식 변경은 LockSetupPage(T11) 로 push
```
- [ ] **Step 1: 실패 테스트:** 일기 섹션의 잠금 행(꺼짐/PIN/패턴) · 다시 잠기는 시간 4개 선택 · 휴지통 기간 4개 선택 · 용량 문구(`1.2GB` · 사진/영상 수 · 휴지통 분) · "이 폰에만 저장" 안내 문구 · 잠금 행 탭 → `LockSetupPage`.
- [ ] **Step 2:** FAIL. **Step 3:** 구현 + l10n. **Step 4:** PASS + 뮤테이션.
- [ ] **Step 5: Commit** `feat(walk): 설정에 일기 잠금 · 휴지통 · 용량 항목을 더한다`.

### T19: 리뷰 · 문서 · 기기 확인

**Files:**
- Modify: `apps/walk/docs/{README,plan,status,history,testing}.md`, 스펙 상태 줄(`설계 승인 · 구현 계획 전` → `구현 완료 · 기기 확인 대기`)

- [ ] **Step 1:** 전체 브랜치 리뷰(정확성 · 스펙 준수 · 테스트 품질 · 연쇄 삭제 · 잠금 우회) → 판정 → 수정 커밋.
- [ ] **Step 2:** `apps/walk/docs/testing.md` 에 스펙 §9 표를 실제 파일 · 건수로 옮긴다("일기" · "잠금" 절). `plan.md` · `README.md` 에 일기 탭, `status.md` 에 "일기" 단계 표와 체크리스트(진행 상태는 status 에만), `history.md` 에 판단 · 스파이크 결과.
- [ ] **Step 3:** `cd apps/trader && flutter test test/convention/documentation_links_test.dart` 통과.
- [ ] **Step 4:** `flutter analyze` · `flutter test`(건수 기록) · `flutter build apk --debug`.
- [ ] **Step 5:** 에뮬레이터 시나리오(스펙 §9.7 9개)를 사용자와 함께 — 결과를 `testing.md` 기기 표와 `status.md` 에.
- [ ] **Step 6: Commit** `docs(walk): 일기 기능을 현황 · 테스트 문서에 싣는다`.
