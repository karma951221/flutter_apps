# 내 기록에 묻는 채팅 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Life Tool(walk)의 통근 탭 자리에 채팅 탭을 넣는다. Claude 가 도구로 일기 · 걸음 · 기상 기록을 찾아 근거 있게 답한다. 기상 기록은 앱 DB 에 오래 남긴다.

**Architecture:** 기상 기록은 네이티브 `RingLog`(200줄)를 앱이 열릴 때 · 돌아올 때 새 drift DB(`ring_archive`)로 옮겨 담는다(`RingArchiver`). 채팅은 `ChatSession`(domain)이 도구 사용 루프를 돈다. Claude 호출은 `ChatModel` 인터페이스 뒤의 `AnthropicChatModel`(data, `http` + SSE)이 하고, 도구는 `LifeTools`(domain)가 기존 저장소를 읽어 실행한다. 화면은 `ChatCubit` + `ChatTab` 이고, 일기 잠금 게이트 아래에 둔다.

**Tech Stack:** Flutter, flutter_bloc(Cubit), freezed 3, injectable/get_it, drift, http, flutter_secure_storage(새로 추가), Anthropic Messages API(raw HTTP, 스트리밍).

**Spec:** [docs/superpowers/specs/2026-10-27-walk-life-chat-design.md](../specs/2026-10-27-walk-life-chat-design.md)

## Global Constraints

- 작업 디렉터리: `apps/walk`. 명령은 거기서 실행한다(`flutter test`, `flutter analyze`, `dart run build_runner build --delete-conflicting-outputs`).
- 계층: `lib/{data,domain,presentation}/<feature>/` ↔ `test/{data,domain,presentation}/<feature>/`. 새 feature 이름은 `chat`.
- Freezed 는 [CLAUDE.md](../../../CLAUDE.md)의 두 패턴만 쓴다(단일 모델 = primary constructor, 변형 = `sealed` + named factory). 분기는 `switch`.
- UI 는 `design_system` 공통 위젯과 토큰만 쓴다(`AppButton` · `AppPlaceholder` · `AppSnackBar` · `AppListTile` · `AppConfirmDialog` · `AppSpacing` · `AppRadius` · `Theme.of`). `Colors.*`, 숫자 여백, `BorderRadius.circular(n)` 은 쓰지 않는다.
- 문구는 `packages/l10n/lib/l10n/app_ko.arb`(템플릿) · `app_en.arb` · `app_ja.arb` 에 `walkChat…` 키로 넣는다. 그다음 `cd packages/l10n && flutter gen-l10n` 을 실행한다.
- 생성 파일(`.freezed.dart` · `.g.dart` · `injection.config.dart`)은 build_runner 로만 갱신한다.
- Anthropic 요청에 들어가는 값:
  - 엔드포인트 `POST https://api.anthropic.com/v1/messages`
  - 헤더 `x-api-key: <키>`, `anthropic-version: 2026-10-21`, `anthropic-beta: server-side-fallback-2026-07-01`, `content-type: application/json`
  - 본문 `model: "claude-opus-5-5"`, `max_tokens: 16000`, `stream: true`, `output_config: {"effort": "low"}`, `fallbacks: "default"`, `tool_choice` 는 보내지 않는다(기본 auto)
  - `temperature` · `top_p` · `top_k` · `thinking` 은 보내지 않는다
- 응답의 `thinking` 블록(서명 포함)은 **그대로** 다음 요청에 되돌려 보낸다. 기록을 고치지 않고 덧붙이기만 한다.
- API 키는 `flutter_secure_storage` 에만 둔다. SharedPreferences · 로그 · 예외 메시지 · 상태 객체 `toString` 에 키가 나오면 안 된다.
- 커밋은 이 작업이 만든 경로만 `git add` 한다. 작업 트리에 이미 있던 알람 쪽 수정분은 건드리지 않는다.
- 커밋 메시지는 `feat(walk): …` / `test(walk): …` / `docs(walk): …` 형식에 한국어로 쓰고, 끝에 `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` 를 붙인다.

## Review Focus

1. **키가 틀렸거나 만료됨(401)** → 답 대신 "키를 확인해 주세요" 안내가 나오고, 설정에서 키를 고친 뒤 같은 대화를 이어서 물을 수 있다. → Task 7(실패 시 대화 되돌림) · Task 8(안내 문구) 테스트
2. **답을 받는 도중 네트워크가 끊김** → 이미 흘러나온 글자는 실패로 표시되고, 대화 기록(messages)은 이번 질문 전으로 되돌아간다. 다음 질문 요청이 400 을 받지 않는다. → Task 7 테스트
3. **"내 일기 전부 보여줘"처럼 넓은 질문** → 한 번에 50개까지만 돌려주고 `truncated: true` 를 붙인다. 기간은 366일을 넘지 않게 자른다. 요청이 터지지 않는다. → Task 6 테스트
4. **답이 흘러나오는 중에 일기가 다시 잠김** → 잠긴 동안 대화 내용이 트리에 없고, 풀면 대화가 그대로 있다. → Task 8 테스트
5. **인용한 기록을 그 뒤에 휴지통으로 보냄 · 지움** → 그 칩은 빠지고 나머지 칩은 보인다. 크래시가 나지 않는다. → Task 8 테스트

---

### Task 1: 기상 기록 보관소

**Files:**
- Create: `lib/domain/alarm/entity/archived_ring.dart`
- Create: `lib/domain/alarm/ring_log/ring_archive.dart`
- Create: `lib/domain/alarm/usecase/ring_archiver.dart`
- Create: `lib/data/alarm/archive/ring_archive_database.dart`
- Create: `lib/data/alarm/archive/drift_ring_archive.dart`
- Modify: `lib/core/di/register_module.dart` (DB 등록, `diaryDatabase` 옆)
- Test: `test/data/alarm/archive/drift_ring_archive_test.dart`, `test/domain/alarm/usecase/ring_archiver_test.dart`

**Interfaces:**
- Produces:
  - `ArchivedRing({required RingLogEntry entry, String? label, int? hour, int? minute})`: freezed primary constructor. `label` · `hour` · `minute` 는 옮겨 담을 때 그 알람의 값(지운 알람이면 null).
  - `abstract interface class RingArchive { Future<void> saveAll(List<ArchivedRing> rings); Future<List<ArchivedRing>> read({required DateTime from, required DateTime to}); }`
    - `saveAll` 은 같은 `(at, packageId, kind)` 가 이미 있으면 건너뛴다. 처음 적힌 라벨이 남는다.
    - `read` 는 `from` 이상 `to` 이하를 오래된 것부터 돌려준다.
  - `@lazySingleton class RingArchiver { RingArchiver(RingLogSource ringLog, RingArchive archive, AlarmUseCase alarms); Future<void> archive(); }`
    - `archive()` 는 `ringLog.read(since: DateTime.fromMillisecondsSinceEpoch(0))` 전부를 `alarms.list()` 의 알람(`alarmIdOf(entry.packageId)` 로 찾음)과 짝지어 `saveAll` 한다.
    - 동시에 부르면 한 번에 하나씩 돈다(뒤 호출은 앞 호출이 끝난 뒤 실행). 예외는 호출자에게 던진다.
  - `RingArchiveDatabase(QueryExecutor e)`, 테이블 `ArchivedRings`(at dateTime, packageId int, kind textEnum<RingLogKind>, label text nullable, hour int nullable, minute int nullable), PK `{at, packageId, kind}`, `storeDateTimeAsText: true`, schemaVersion 1.
  - `@LazySingleton(as: RingArchive) class DriftRingArchive`
  - RegisterModule: `@LazySingleton(dispose: …) RingArchiveDatabase ringArchiveDatabase() => RingArchiveDatabase(driftDatabase(name: 'ring_archive'));`

- [ ] **Step 1: 실패하는 테스트 작성** — `drift_ring_archive_test.dart` (`NativeDatabase.memory()`)
  - `saveAll 뒤 read 는 기간 안의 것만 오래된 순으로 돌려준다`: 1일 · 2일 · 3일 기록을 저장하고 `read(from: 2일 0시, to: 3일 0시)` → 2일 것 하나.
  - `같은 (at, packageId, kind) 를 두 번 저장하면 하나만 남고 처음 라벨을 유지한다`: label '출근' 저장 → 같은 키로 label '바뀜' 저장 → read 결과 1개, label '출근'.
  - `지운 알람(라벨 null)도 저장된다`.
- [ ] **Step 2: 실패하는 테스트 작성** — `ring_archiver_test.dart` (mocktail 로 `RingLogSource` · `AlarmUseCase`, 가짜 `RingArchive` 는 메모리 리스트)
  - `네이티브 기록을 알람 라벨 · 시각과 함께 옮긴다`: 알람 id 3(label '출근', 7:00)의 packageId 회차 `stopped` → 저장된 ArchivedRing 의 label '출근', hour 7, minute 0.
  - `알람이 없으면 label · hour · minute 이 null`.
  - `동시에 두 번 부르면 차례로 돈다`: 첫 `read` 를 Completer 로 붙잡고 두 번째 호출 → 첫 호출이 끝나기 전 `read` 는 1번만 불렸다.
- [ ] **Step 3: 테스트를 돌려 실패 확인** — `flutter test test/data/alarm/archive test/domain/alarm/usecase/ring_archiver_test.dart` → 컴파일 실패(없는 타입)
- [ ] **Step 4: 위 Interfaces 대로 구현하고 `dart run build_runner build --delete-conflicting-outputs` 실행.** `RingArchiver` 의 직렬화는 `AlarmUseCase._serial` 과 같은 `_tail` 패턴을 쓴다.
- [ ] **Step 5: 테스트 통과 확인** — 같은 명령 → PASS
- [ ] **Step 6: 커밋** — `feat(walk): 알람 울림 기록을 앱 DB 에 오래 남기는 보관소`

### Task 2: 알람 울림 기록 화면이 보관소를 읽고, 셸이 옮겨 담기를 부른다

**Files:**
- Modify: `lib/domain/alarm/ring_log.dart` (`ringLogGroups` 입력 · `RingLogGroup.archivedLabel`)
- Modify: `lib/presentation/alarm/cubit/alarm_history_cubit.dart`
- Modify: `lib/presentation/alarm/page/alarm_history_page.dart` (cubit 생성 인자, 라벨 표시)
- Modify: `lib/presentation/shell/page/main_shell_page.dart` (시작 · resumed 에서 `RingArchiver.archive()`)
- Test: `test/domain/alarm/ring_log_test.dart`, `test/presentation/alarm/cubit/alarm_history_cubit_test.dart`, `test/presentation/alarm/page/alarm_history_page_test.dart`, `test/presentation/shell/page/main_shell_page_test.dart` — 이 중 이미 있는 파일은 고친다

**Interfaces:**
- Consumes: Task 1 의 `ArchivedRing`, `RingArchive.read`, `RingArchiver.archive`
- Produces:
  - `List<RingLogGroup> ringLogGroups(List<ArchivedRing> rings, List<Alarm> alarms)`: 묶는 규칙은 지금과 같다.
  - `RingLogGroup` 에 `final String? archivedLabel;` 를 더한다. 회차 안에서 null 이 아닌 마지막 `label` 이다.
  - `AlarmHistoryCubit(RingArchiver archiver, RingArchive archive, AlarmUseCase useCase, Clock clock)`
    - `load()` 는 먼저 `archiver.archive()` 를 부른다. 실패하면 무시하고 계속한다.
    - 그다음 `archive.read(from: 오늘 0시 - 30일, to: now)` 를 읽는다.
    - 알람의 지난 `skippedAt` 으로 만드는 건너뛰기 항목은 지금처럼 더하되, `ArchivedRing(entry: …, label: alarm.label, hour: alarm.hour, minute: alarm.minute)` 로 감싼다.
  - 화면의 라벨은 `group.alarm?.label ?? group.archivedLabel` 이다. 둘 다 비면 지금의 "지운 알람" 표시를 쓴다.

- [ ] **Step 1: 실패하는 테스트 작성**
  - ring_log_test: `지운 알람의 회차는 archivedLabel 로 라벨을 가진다` — alarms 가 빈 목록이고 rings 의 label 이 '출근'이면, group.alarm 은 null 이고 group.archivedLabel 은 '출근'.
  - alarm_history_cubit_test: `보관소에서 30일치를 읽는다` — 가짜 archive 에 40일 전 · 10일 전 기록 → groups 에 10일 전 것만 있다.
  - alarm_history_cubit_test: `옮겨 담기가 실패해도 보관소 내용을 보인다` — archiver.archive() 가 throw → state loaded.
  - main_shell_page_test: `시작할 때와 앱이 돌아올 때 울림 기록을 옮겨 담는다` — RingArchiver mock 의 `archive()` 가 시작 때 1번, `AppLifecycleState.resumed` 뒤 1번 더 불린다.
- [ ] **Step 2: 실패 확인** — `flutter test test/domain/alarm/ring_log_test.dart test/presentation/alarm test/presentation/shell` → FAIL
- [ ] **Step 3: 구현.** 기존 `ringLogGroups` 호출자와 테스트를 새 시그니처에 맞춘다. 셸은 `unawaited(getIt<RingArchiver>().archive().catchError((Object _) {}))` 로 부른다. 부르는 곳은 기존 `_alarmUseCase.sync` 를 시작 · 복귀 때 부르는 지점 옆이다.
- [ ] **Step 4: 통과 확인** — 같은 명령 → PASS
- [ ] **Step 5: 커밋** — `feat(walk): 알람 울림 기록 화면이 오래 남긴 기록을 읽는다`

### Task 3: 스토리를 가리지 않는 일기 기간 검색

**Files:**
- Modify: `lib/domain/diary/repository/diary_repository.dart`
- Modify: `lib/data/diary/drift_diary_repository.dart`
- Test: `test/data/diary/drift_diary_repository_test.dart`(있으면 그 파일에 그룹 추가)

**Interfaces:**
- Produces:
  ```dart
  /// [from] ~ [to](양 끝 포함)에 든 기록(휴지통 제외, 모든 스토리), occurredAt 오름차순, 최대 [limit]개.
  /// [query] 본문 포함 일치(대소문자 무시) · [tag] `TagName.searchKey` 로 다듬은 이름 일치 ·
  /// [place] trim 한 장소 이름 일치 · [storyId] 그 스토리만. null 이면 조건 없음.
  Future<List<DiaryEntry>> searchEntries({
    required DateTime from,
    required DateTime to,
    String? query,
    String? tag,
    String? place,
    String? storyId,
    int limit = 50,
  });
  ```
  미디어 · 태그 · 장소를 채운 완전한 `DiaryEntry` 를 돌려준다(`watchEntries` 와 같은 매퍼).

- [ ] **Step 1: 실패하는 테스트 작성** (`test/support/diary_fixtures.dart` 의 메모리 DB 사용)
  - `여러 스토리의 기록을 기간으로 찾고 오래된 순으로 준다`
  - `휴지통 기록은 빠진다`
  - `query · tag · place · storyId 를 각각 걸러낸다`: 조건마다 1개만 맞는 기록 세트
  - `limit 을 넘지 않는다`: 5개 저장, limit 3 → 3개(가장 오래된 3개)
- [ ] **Step 2: 실패 확인** — `flutter test test/data/diary` → FAIL
- [ ] **Step 3: 구현**
- [ ] **Step 4: 통과 확인** — `flutter test test/data/diary test/presentation/diary` → PASS
- [ ] **Step 5: 커밋** — `feat(walk): 일기 저장소에 스토리를 가리지 않는 기간 검색을 더한다`

### Task 4: 채팅 설정 — API 키 · 전송 동의, 설정 탭 섹션

**Files:**
- Modify: `pubspec.yaml` (`flutter_secure_storage: ^9.2.4`. 해석이 안 되면 최신 안정판으로 정하고 계획 메모에 남긴다)
- Create: `lib/domain/chat/chat_settings.dart`
- Create: `lib/data/chat/secure_chat_settings.dart`
- Modify: `lib/core/di/register_module.dart` (`FlutterSecureStorage get secureStorage => const FlutterSecureStorage();`)
- Create: `lib/presentation/settings/cubit/chat_settings_cubit.dart` + `chat_settings_state.dart`
- Create: `lib/presentation/settings/widget/chat_settings_section.dart`
- Modify: `lib/presentation/settings/page/settings_page.dart` (일기 섹션 다음에 `ChatSettingsSection`)
- Modify: `packages/l10n/lib/l10n/app_{ko,en,ja}.arb`
- Test: `test/data/chat/secure_chat_settings_test.dart`, `test/presentation/settings/cubit/chat_settings_cubit_test.dart`, `test/presentation/settings/widget/chat_settings_section_test.dart`

**Interfaces:**
- Produces:
  ```dart
  abstract interface class ChatSettings {
    Future<String?> apiKey();            // 저장 안 했거나 빈 문자열이면 null
    Future<void> saveApiKey(String key); // trim 해서 저장. 빈 문자열이면 deleteApiKey 와 같다
    Future<void> deleteApiKey();
    bool get consented;                  // 전송 안내에 동의했는지 (SharedPreferences 'chat.consented')
    Future<void> setConsented();
  }
  ```
  - `@LazySingleton(as: ChatSettings) class SecureChatSettings(FlutterSecureStorage, SharedPreferences)`: 보안 저장소 키 이름은 `anthropic_api_key`.
  - `ChatSettingsCubit(ChatSettings)`: 상태는 `ChatSettingsState({required bool loading, String? keyHint})` 이다. `keyHint` 는 키 마지막 4자 앞에 `…` 를 붙인 값이고, 키가 없으면 null. 메서드는 `load()` · `save(String)` · `delete()`.
  - 섹션 UI: 제목 행, 키 행(없으면 "키 넣기", 있으면 `…abcd` + 바꾸기), 삭제(`AppConfirmDialog.show`), 전송 안내 한 줄. 키 입력은 다이얼로그 안의 가려진(`obscureText`) 입력칸이다.

- [ ] **Step 1: 실패하는 테스트 작성**
  - secure_chat_settings_test(FlutterSecureStorage mock, `SharedPreferences.setMockInitialValues`): `키를 trim 해 보안 저장소에만 쓴다` — prefs 의 어떤 값에도 키 문자열이 없다. `빈 키 저장은 삭제와 같다`. `동의는 prefs 에 남는다`.
  - chat_settings_cubit_test: `키가 있으면 마지막 4자만 힌트로 보인다` — 'sk-ant-xyz1234' → keyHint '…1234'. `상태 toString 에 전체 키가 없다`.
  - chat_settings_section_test: `키가 없으면 키 넣기 행을 보이고, 입력해 저장하면 힌트가 보인다`.
- [ ] **Step 2: 실패 확인** — `flutter test test/data/chat test/presentation/settings` → FAIL
- [ ] **Step 3: 구현 + `flutter pub get` + build_runner + `flutter gen-l10n`(packages/l10n)**
- [ ] **Step 4: 통과 확인** — 같은 명령 + `flutter test test/presentation/settings/page` → PASS
- [ ] **Step 5: 커밋** — `feat(walk): 채팅용 API 키와 전송 동의를 설정에서 관리한다`

### Task 5: Claude 스트리밍 클라이언트

**Files:**
- Create: `lib/domain/chat/chat_model.dart`
- Create: `lib/data/chat/anthropic_chat_model.dart`
- Test: `test/data/chat/anthropic_chat_model_test.dart`

**Interfaces:**
- Produces:
  ```dart
  @freezed
  sealed class ModelEvent with _$ModelEvent {
    const factory ModelEvent.textDelta(String text) = ModelTextDelta;
    /// 한 응답의 완성된 content 블록들(API JSON 그대로, thinking 서명 포함)과 stop_reason.
    const factory ModelEvent.completed({
      required List<Map<String, Object?>> content,
      required String stopReason,
    }) = ModelCompleted;
  }

  enum ChatModelErrorKind { invalidKey, rateLimited, overloaded, network, server }

  class ChatModelException implements Exception {
    const ChatModelException(this.kind);
    final ChatModelErrorKind kind;
  }

  abstract interface class ChatModel {
    /// 실패는 스트림 오류 [ChatModelException] 으로 낸다.
    Stream<ModelEvent> stream({
      required String apiKey,
      required String system,
      required List<Map<String, Object?>> messages,
      required List<Map<String, Object?>> tools,
    });
  }
  ```
  - `@LazySingleton(as: ChatModel) class AnthropicChatModel(http.Client)`: 요청 헤더 · 본문은 Global Constraints 의 값과 같다.
  - SSE 를 블록 단위로 쌓는다.
    - `content_block_start` 의 `content_block` 을 복사해 둔다.
    - `text_delta` 는 `text` 에, `thinking_delta` 는 `thinking` 에 덧붙인다. `signature_delta` 는 `signature` 에 넣는다.
    - `input_json_delta` 는 문자열 버퍼에 모았다가 `content_block_stop` 에서 `jsonDecode` 해 `input` 에 넣는다. 빈 버퍼면 `{}`.
    - `message_delta.delta.stop_reason` 이 stop_reason 이다. `message_stop` 에서 `completed` 를 낸다.
    - 모르는 블록 타입은 시작 때 받은 그대로 둔다.
  - 오류 매핑:
    - HTTP 401 · 403 → `invalidKey`
    - 429 → `rateLimited`
    - 529 · SSE `event: error` 의 `overloaded_error` → `overloaded`
    - `SocketException` · `http.ClientException` · 스트림 중간 끊김 → `network`
    - 그 밖의 비 2xx · 다른 SSE error → `server`
  - 예외에 응답 본문이나 키를 담지 않는다.

- [ ] **Step 1: 실패하는 테스트 작성** (`http.testing` 의 `MockClient.streaming`)
  - `요청에 정해진 헤더와 본문 필드를 담는다`: anthropic-version `2026-10-21`, model `claude-opus-5-5`, `fallbacks` `"default"`, `output_config.effort` `"low"`, `stream` true. `temperature` · `thinking` · `tool_choice` 키가 없다.
  - `text_delta 를 차례로 흘리고 completed 에 전체 text 블록을 담는다`
  - `thinking 블록을 서명과 함께 그대로 돌려준다`
  - `조각난 input_json_delta 를 모아 tool_use.input 으로 만든다`: `{"fr` + `om":"2026-10-01"}` → `{'from': '2026-10-01'}`
  - `401 은 invalidKey, 429 는 rateLimited, 529 는 overloaded`
  - `본문 중간에 연결이 끊기면 network`: 스트림 컨트롤러가 `addError(http.ClientException('x'))`
- [ ] **Step 2: 실패 확인** — `flutter test test/data/chat/anthropic_chat_model_test.dart` → FAIL
- [ ] **Step 3: 구현 + build_runner**
- [ ] **Step 4: 통과 확인** — 같은 명령 → PASS
- [ ] **Step 5: 커밋** — `feat(walk): Claude Messages API 스트리밍 클라이언트`

### Task 6: 기록 도구(LifeTools)

**Files:**
- Create: `lib/domain/chat/tool/tool_result.dart`
- Create: `lib/domain/chat/tool/chat_image_source.dart`
- Create: `lib/domain/chat/tool/life_tools.dart`
- Create: `lib/data/chat/compressed_chat_image_source.dart`
- Test: `test/domain/chat/tool/life_tools_test.dart`

**Interfaces:**
- Consumes:
  - Task 3 `DiaryRepository.searchEntries` · `entry` · `watchStories` · `watchTagCounts` · `watchPlaceCounts`
  - `ActivityRepository.access` · `dailyActivities`
  - Task 1 `RingArchiver.archive` · `RingArchive.read`
  - Task 2 `ringLogGroups`
  - `MediaStore.resolve`
- Produces:
  ```dart
  @freezed class ToolImage with _$ToolImage { final String mediaType; final Uint8List bytes; const ToolImage({required this.mediaType, required this.bytes}); }
  @freezed class ToolResult with _$ToolResult {
    final String json;              // tool_result 의 text 내용
    final List<ToolImage> images;   // tool_result 에 이미지 블록으로 붙는다
    final List<String> entryIds;    // 이 결과에 나온 일기 id(인용 칩 후보)
    final bool isError;
    const ToolResult({required this.json, this.images = const [], this.entryIds = const [], this.isError = false});
  }
  abstract interface class ChatImageSource { Future<ToolImage?> load(EntryMedia media); } // 실패하면 null
  @lazySingleton class LifeTools {
    LifeTools(DiaryRepository diary, ActivityRepository activity, RingArchiver archiver, RingArchive rings, ChatImageSource images);
    List<Map<String, Object?>> get definitions; // Anthropic tools 배열 그대로 (name · description · input_schema)
    Future<ToolResult> run(String name, Map<String, Object?> input);
  }
  ```
- 도구. 날짜 입력은 `YYYY-MM-DD`(로컬)이고, 기간은 양 끝을 포함한다.

  | name | input | 결과 JSON |
  |---|---|---|
  | `search_diary` | `from`, `to`, `query?`, `tag?`, `place?`, `story_id?` | `{"entries":[{"id","at":"YYYY-MM-DDTHH:mm","story","place","tags":[],"text","photos":n,"videos":n}],"truncated":bool}`. limit 50. 51개를 읽어 넘치면 50개와 `truncated: true` |
  | `view_entry_photos` | `entry_id` | `{"entry_id","shown":n,"total":n}`. 이미지는 사진 최대 4장이고, 영상이면 `thumbPath` 로 만든 썸네일. `entryIds` 에 그 id |
  | `list_diary_index` | 없음 | `{"stories":[{"id","title","started","ended","entries"}],"tags":[{"name","count"}],"places":[{"name","count"}]}`. 태그 · 장소는 상위 30. 기본 스토리 제목은 `"일상"` |
  | `daily_steps` | `from`, `to` | `{"days":[{"date","steps"}]}`. 접근이 `granted` 가 아니면 `isError` 와 `{"error":"health_connect_unavailable"}` |
  | `wake_records` | `from`, `to` | 먼저 `archiver.archive()` 를 부른다(실패는 무시). 그다음 `ringLogGroups(rings.read(from 0시, to+1일 0시), [])` 를 회차별로 낸다: `{"rings":[{"date","alarm","rang_at","ended_at","end":"stopped"/"autoStopped"/null,"snoozes","skipped"}]}`. `alarm` 은 archivedLabel 이고, 시각은 `HH:mm` |

  - 공통:
    - `from > to` 이거나 날짜 형식이 틀리면 `isError` + `{"error":"invalid_range"}`.
    - 기간이 366일을 넘으면 `to` 기준 최근 366일로 자르고 `"clamped": true`.
    - 모르는 name 은 `{"error":"unknown_tool"}`.
  - `search_diary` 의 `entryIds` 는 돌려준 기록 id 전부다.
  - `CompressedChatImageSource(MediaStore)`(@LazySingleton(as: ChatImageSource)): `FlutterImageCompress.compressWithFile(file, minWidth: 1024, minHeight: 1024, quality: 80, format: CompressFormat.jpeg)` → `image/jpeg`. 플러그인이라 단위 테스트는 하지 않는다.

- [ ] **Step 1: 실패하는 테스트 작성** (mocktail 저장소 · 가짜 ChatImageSource · 가짜 RingArchive)
  - `definitions 에 다섯 도구가 있고 각자 input_schema 가 object 다`
  - `search_diary 는 기록을 JSON 으로 주고 entryIds 를 채운다`
  - `search_diary 가 50개를 넘으면 50개와 truncated true` (Review Focus 3)
  - `366일을 넘는 기간은 잘리고 clamped true` (Review Focus 3)
  - `날짜가 거꾸로면 invalid_range 오류`
  - `view_entry_photos 는 사진을 최대 4장 이미지로 붙인다`: 사진 6장 기록 → images 4, total 6
  - `Health Connect 를 못 쓰면 daily_steps 는 오류 결과`
  - `wake_records 는 옮겨 담은 뒤 회차별 일어난 시각을 준다`: archive() 호출을 검증하고, `stopped` 7:12 → `"ended_at":"07:12"`
  - `모르는 도구는 unknown_tool`
- [ ] **Step 2: 실패 확인** — `flutter test test/domain/chat/tool` → FAIL
- [ ] **Step 3: 구현 + build_runner**
- [ ] **Step 4: 통과 확인** — 같은 명령 → PASS
- [ ] **Step 5: 커밋** — `feat(walk): 채팅이 일기 · 걸음 · 기상 기록을 찾는 도구`

### Task 7: 대화 세션(도구 사용 루프)

**Files:**
- Create: `lib/domain/chat/usecase/chat_session.dart`
- Test: `test/domain/chat/usecase/chat_session_test.dart`

**Interfaces:**
- Consumes: Task 4 `ChatSettings.apiKey`, Task 5 `ChatModel` · `ModelEvent` · `ChatModelException`, Task 6 `LifeTools`, `Clock`
- Produces:
  ```dart
  enum ChatFailure { noKey, invalidKey, rateLimited, overloaded, network, refused, tooManySteps, unknown }

  @freezed
  sealed class ChatEvent with _$ChatEvent {
    const factory ChatEvent.text(String delta) = ChatText;
    const factory ChatEvent.toolStarted(String toolName) = ChatToolStarted;
    const factory ChatEvent.finished({required List<String> citedEntryIds}) = ChatFinished;
    const factory ChatEvent.failed(ChatFailure failure) = ChatFailed;
  }

  @lazySingleton
  class ChatSession {
    ChatSession(ChatModel model, LifeTools tools, ChatSettings settings, Clock clock);
    Stream<ChatEvent> ask(String question); // 한 번에 하나. 진행 중에 부르면 StateError
    void reset();                           // 대화 비우기
    static const maxRounds = 8;
  }
  ```
- 루프:
  1. 키가 없으면 `failed(noKey)`.
  2. user 메시지를 덧붙이고 `model.stream` 을 부른다. `textDelta` 는 `text` 로 흘린다.
  3. `completed` 가 오면 assistant 메시지(`content` 그대로)를 덧붙인다.
  4. `stopReason == 'tool_use'` 이면 content 의 `tool_use` 블록을 순서대로 실행한다. 블록마다 `toolStarted(name)` 을 낸다.
  5. 결과 전부를 **user 메시지 하나**에 담는다. 각 `tool_result` 는 `tool_use_id` · `is_error` 를 갖고, content 는 `[{type: text, text: json}, …images as {type: image, source: {type: base64, media_type, data}}]` 이다. 그리고 다음 라운드로 간다.
  6. 그 밖의 stop_reason(`end_turn` · `max_tokens` 등)이면 `finished(citedEntryIds)` 를 낸다. citedEntryIds 는 이번 질문의 도구 결과 entryIds 를 처음 나온 순서로 중복 없이 모은 것이다.
  7. `refusal` 은 `failed(refused)`, 라운드가 `maxRounds` 를 넘으면 `failed(tooManySteps)`.
  8. `ChatModelException` 은 kind 를 같은 이름의 `ChatFailure` 로 바꾸고, 그 밖의 예외는 `unknown` 이다.
  9. **실패하면 이번 질문에서 덧붙인 메시지를 모두 되돌린다** — 다음 질문이 망가진 기록을 보내지 않게.
- 시스템 프롬프트(정해진 문구, `clock.now()` 로 채움):
  ```
  너는 사용자의 개인 기록 앱 Life Tool 안의 도우미다. 오늘은 {yyyy-MM-dd (E)}, 시간대는 {timeZoneName} 이다.
  사용자의 일기 · 걸음 수 · 알람 기상 기록을 도구로 찾아보고, 찾은 기록에 근거해서만 답한다.
  기록에서 찾지 못한 것은 추측하지 말고 "기록에서 찾지 못했어요"라고 말한다.
  날짜는 사용자의 말("지난주", "어제")을 오늘 기준으로 바꿔 도구에 넘긴다.
  한국어로, 마크다운 없이 짧은 평문으로 답한다.
  ```

- [ ] **Step 1: 실패하는 테스트 작성** (가짜 ChatModel 이 라운드마다 준비된 이벤트를 흘리고, 받은 messages 를 기록한다)
  - `도구 없이 끝나면 text 를 흘리고 finished`
  - `tool_use 면 도구를 실행해 tool_result 를 user 메시지 하나로 보내고 다음 라운드로 간다`: 두 번째 요청의 마지막 메시지가 role user, tool_result 2개, tool_use_id 일치
  - `이미지가 있는 결과는 base64 image 블록을 붙인다`
  - `assistant content(thinking 포함)를 바꾸지 않고 다음 요청에 보낸다`
  - `citedEntryIds 는 중복 없이 처음 나온 순서`
  - `키가 없으면 noKey 이고 모델을 부르지 않는다`
  - `401 이면 invalidKey 이고 대화가 질문 전으로 돌아간다. 키를 고친 다음 질문의 messages 는 [이전 대화…, 새 질문] 이다` (Review Focus 1)
  - `스트림 중간에 network 오류면 failed(network) 이고 messages 가 질문 전으로 돌아간다` (Review Focus 2)
  - `refusal 은 refused`, `8라운드를 넘기면 tooManySteps`
  - `시스템 프롬프트에 오늘 날짜가 들어간다`: 고정 Clock 2026-10-27 → `2026-10-27` 포함
- [ ] **Step 2: 실패 확인** — `flutter test test/domain/chat/usecase` → FAIL
- [ ] **Step 3: 구현 + build_runner**
- [ ] **Step 4: 통과 확인** — 같은 명령 → PASS
- [ ] **Step 5: 커밋** — `feat(walk): 기록 도구를 쓰는 채팅 세션`

### Task 8: 채팅 탭 화면과 셸 연결(통근 탭 자리)

**Files:**
- Create: `lib/presentation/chat/cubit/chat_cubit.dart` + `chat_state.dart`
- Create: `lib/presentation/chat/page/chat_tab.dart`
- Create: `lib/presentation/chat/widget/` (말풍선 · 입력칸 · 인용 칩 · 동의 안내. 파일은 역할별로 나눈다)
- Modify: `lib/presentation/shell/page/main_shell_page.dart` (`ShellTab { alarm, walk, diary, chat, settings }`. `CommuteTab` import · 목적지를 제거한다)
- Modify: `packages/l10n/lib/l10n/app_{ko,en,ja}.arb` (`walkShellTabChat`: 물어보기 / Ask / 質問, 그 밖의 `walkChat…`)
- Test: `test/presentation/chat/cubit/chat_cubit_test.dart`, `test/presentation/chat/page/chat_tab_test.dart`, `test/presentation/shell/page/main_shell_page_test.dart`

**Interfaces:**
- Consumes: Task 7 `ChatSession` · `ChatEvent` · `ChatFailure`, Task 4 `ChatSettings`, `DiaryRepository.entry`, `DiaryLockGate`, `pushDiaryRoute`
- Produces:
  ```dart
  enum ChatAccess { checking, noKey, needsConsent, ready }
  enum ChatRole { user, assistant }
  @freezed class ChatBubble with _$ChatBubble {
    final ChatRole role; final String text;
    final List<DiaryEntry> cited;   // 휴지통 · 없는 기록은 뺀다
    final ChatFailure? failure;
    const ChatBubble({required this.role, required this.text, this.cited = const [], this.failure});
  }
  @freezed class ChatState with _$ChatState {
    final ChatAccess access; final List<ChatBubble> bubbles; final bool busy; final String? activeTool;
    const ChatState({required this.access, this.bubbles = const [], this.busy = false, this.activeTool});
  }
  class ChatCubit extends Cubit<ChatState> {
    ChatCubit(ChatSession session, ChatSettings settings, DiaryRepository diary);
    Future<void> refresh();        // 키 · 동의 상태를 다시 읽는다 (탭이 active 가 될 때)
    Future<void> consent();
    Future<void> send(String question); // 빈 문자열 · busy 면 무시
    void newConversation();        // session.reset + bubbles 비움
  }
  ```
- `ChatTab({required bool active})` 은 StatefulWidget 이다.
  - cubit 은 **게이트 바깥(이 위젯 State)**에서 만든다. 다시 잠겨도 대화가 남게 하기 위해서다.
  - `active` 가 true 로 바뀔 때 `refresh()` 를 부른다.
  - 본문은 `DiaryLockGate(dismissPopups: active, child: …)` 로 감싼다.
  - 상태별 화면:
    - `noKey`: `AppPlaceholder`("설정에서 키를 넣어 주세요" + 버튼 → `onOpenSettings`). `ChatTab` 에 `VoidCallback onOpenSettings` 를 받는다. 셸이 `_select(ShellTab.settings)` 를 넘긴다.
    - `needsConsent`: 전송 안내 문구와 [동의하고 시작] `AppButton.primary`.
    - `ready`, 대화가 비었을 때: 예시 질문 칩 3개("어제 뭐 했어?", "지난주에 뭐 먹었지?", "요즘 몇 시에 일어나?"). 누르면 바로 `send`.
    - `ready`, 대화가 있을 때: 말풍선 목록(아래로 자동 스크롤) + 입력칸. 앱바에 [새 대화].
  - `busy` 동안 입력칸 전송 버튼을 끄고, `activeTool` 이 있으면 "기록을 찾는 중…" 한 줄을 보인다.
  - 실패 말풍선은 이미 받은 글 아래에 `ChatFailure` 별 문구를 보인다(invalidKey 는 "키를 확인해 주세요").
  - 인용 칩: 날짜(`M월 d일`) + 본문 앞 20자. 사진이 있으면 썸네일도 붙인다. 누르면 그 칩 목록을 스토리 뷰어로 연다. 연 기록이 첫 장이고, `pushDiaryRoute` 를 쓴다(`FilteredEntriesPage` 가 뷰어를 여는 방식을 그대로 따른다).

- [ ] **Step 1: 실패하는 테스트 작성**
  - chat_cubit_test:
    - `키가 없으면 noKey, 동의 전이면 needsConsent, 둘 다면 ready`
    - `send 는 user 말풍선과 흘러나오는 assistant 말풍선을 만들고 끝나면 busy false`
    - `인용 기록 중 휴지통 · 없는 것은 뺀다` (Review Focus 5): `entry()` 가 trashed 1 · notFound 1 · 정상 1 → cited 1
    - `실패하면 assistant 말풍선에 failure 가 붙는다`
    - `newConversation 은 session.reset 을 부르고 비운다`
  - chat_tab_test:
    - `잠겨 있으면 대화 내용이 트리에 없고, 풀면 그대로 있다` (Review Focus 4): 말풍선 텍스트 find → 잠금 상태 emit → findsNothing → 해제 → findsOneWidget
    - `키가 없으면 설정으로 가는 버튼을 보인다`
    - `예시 질문 칩을 누르면 질문을 보낸다`
  - main_shell_page_test: `하단 탭은 알람 · 걷기 · 일기 · 물어보기 · 설정이고 통근은 없다`. 기존 통근 탭 관련 셸 테스트는 지운다(통근 위젯 자체의 테스트는 그대로 둔다).
- [ ] **Step 2: 실패 확인** — `flutter test test/presentation/chat test/presentation/shell` → FAIL
- [ ] **Step 3: 구현 + build_runner + `flutter gen-l10n`(packages/l10n)**
- [ ] **Step 4: 통과 확인** — `flutter test` (walk 전체) → PASS, `flutter analyze` → No issues
- [ ] **Step 5: 커밋** — `feat(walk): 통근 탭 자리에 내 기록에 묻는 채팅 탭`

### Task 9: 문서 갱신과 최종 확인

**Files:**
- Modify: `apps/walk/docs/plan.md` (목적 · 화면 표: 채팅 탭과 기상 기록 보관 추가, 통근 탭은 셸에서 빠졌다고 적기, 설계 링크에 이 스펙 추가)
- Modify: `apps/walk/docs/status.md` (진행 상태: 채팅 탭 · 기상 기록 보관 완료, 실기기 확인은 남음)
- Modify: `apps/walk/docs/history.md`, `apps/walk/docs/testing.md` (이번 작업과 테스트 범위)
- Modify: `CLAUDE.md` 첫 단락의 walk 설명 — "알람 · 걷기(Health Connect) · 일기 · 채팅(Claude API) 탭". 통근 코드는 남아 있으나 탭에서 빠졌다고 적는다
- Test: `apps/trader/test/convention/documentation_links_test.dart`

- [ ] **Step 1: 문서 수정**
- [ ] **Step 2: 링크 검사** — `cd apps/trader && flutter test test/convention/documentation_links_test.dart` → PASS
- [ ] **Step 3: 전체 확인** — `cd apps/walk && flutter analyze && flutter test` → No issues, All tests passed
- [ ] **Step 4: 커밋** — `docs(walk): 채팅 탭과 기상 기록 보관을 문서에 반영`
