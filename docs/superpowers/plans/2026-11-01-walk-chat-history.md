# walk 물어보기 — 대화 기록 · 임시 대화 · 사용량 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 물어보기 대화를 기기의 `chat` DB 에 턴마다 저장(끝난 턴 · 글이 온 멈춘 턴)해 목록에서 열고 · 이름 바꾸고 · 지우고 · 이어가게 하고(벤더 · 모델을 바꿔도 글로 다시 채워 이어감), 아무것도 남기지 않는 임시 대화(배너 · `FLAG_SECURE` · 사용량은 숫자만)를 더하며, 요청마다의 토큰 사용량을 저장해 물어보기 설정 › 사용량 화면에서 보이고, 오래된 대화를 보관 기간에 따라 지운다.

**Architecture:** 새 drift DB `ChatDatabase`(`driftDatabase(name: 'chat')`, schemaVersion 1: `conversations` · `chat_turns` · `chat_usage`)를 domain 인터페이스 `ChatHistoryRepository` · `ChatUsageRepository` 와 중립 계약의 `ChatUsageLog` 뒤에 둔다(`DriftChatUsageLog` 가 `NoopChatUsageLog` 를 대신). 세션은 저장소를 모른다 — `ChatSession.resume(turns, temporary:)` 로 글만의 문맥을 다시 채우고, 벤더 · 모델이 바뀌면 스스로 메모리 문맥을 글로 접는다. 저장 · 열기 · 턴 지우기 · 임시 대화는 `ChatCubit` 이 하고, 화면(`ChatHistoryPage` · 배너 · 길게 누르기 시트 · `ChatUsagePage` · `ChatHistorySettingsSection`)은 재구성이 만든 앱바 `FeatureMenu` 와 `ChatSettingsPage` 에 끼운다. 보관 · 13개월 정리는 `ChatHistoryPruner` 를 셸의 시작 · 복귀 훅에서 부른다.

**Tech Stack:** Flutter · drift 2.34(`drift_flutter`, `NativeDatabase.memory()` 테스트) · flutter_bloc · Freezed 3 · injectable/get_it · shared_preferences · `MethodChannel`(Kotlin `MainActivity`) · gen-l10n(`packages/l10n`, 기준 `app_ko.arb`) · intl.

**Spec:** [대화 기록 · 위키 기획](../specs/2026-11-01-walk-chat-history-wiki.md) **§8 1단계 전체**와 그 완료 조건(관련 절: 결정 D1~D4 · D9 · D10 · D13 · D16~D19, §1 · §2 · §4 · §5 · §6 · §7 의 1단계 몫).
- 선행 ①: [하단 탭 재구성 계획](2026-11-01-walk-nav-regroup.md) — 설정 탭 없음, `openSettings(context, SettingsTarget.chat)` 가 `pushDiaryRoute` 로 여는 `ChatSettingsPage`, 물어보기 앱바 = [새 대화] + `FeatureMenu(settings: SettingsTarget.chat, entries: …)`.
- 선행 ②: [중립 계약 · 계측 · 멈춤 계획](2026-11-01-walk-chat-core.md) — `ChatMessage` · `AssistantPart` · `VendorTurnState` · `ChatVendor` · `ModelRequest`, `ChatUsageLog` · `ChatUsageRecord`(기록 기획 필드 포함) · `ChatUsagePurpose` · `NoopChatUsageLog`, `ChatSession.stop()` · `ChatStopResult` · `ChatSession.stoppedNote` · `ChatSession.interimModel`, `ChatBubble.stopped`, `ChatCubit.stop()`, `ChatTrace`.
- 키 UX(키 기획 ②)는 들어왔을 수도, 안 들어왔을 수도 있다 — 이 계획은 기대지 않는다(아래 P3 · P4).
- 범위 밖: 위키 전부(2단계 — `wiki_notes` · `WikiContextPolicy` · `read_wiki` · [위키로 정리] · [위키에 추가] · 색인 크기 · 위키 모두 지우기 · 사용량의 위키 숫자). 단 DB 는 migration 2 로 `wiki_notes` 를 더할 수 있게 준비한다(Task 1).

## Global Constraints

- 경로는 `apps/walk/` 기준. 테스트는 `test/` 아래 같은 구조(`lib/data/chat/database/x.dart` ↔ `test/data/chat/database/x_test.dart`).
- Freezed(CLAUDE.md): 단일 모델은 Freezed 3 primary constructor(`@freezed class X with _$X { @override final …; const X({…}); }`), 변형은 `sealed class` + named factory. 분기는 `switch` 패턴 매칭(`when`/`map` 금지).
- 생성 파일(`.g.dart` · `.freezed.dart` · `injection.config.dart`)은 손으로 고치지 않는다 — `cd apps/walk && dart run build_runner build --delete-conflicting-outputs`.
- **저장소 전체 포맷 금지.** `dart format` 은 그 task 가 만든 · 고친 파일에만.
- UI 규칙(CLAUDE.md): `AppListTile` · `AppOverflowMenu` · `AppPlaceholder` · `AppConfirmDialog.show` · `AppSnackBar.show` · `AppButton` 우선. `Colors.*` · 숫자 여백 · `BorderRadius.circular(n)` 금지 — `AppSpacing` · `AppRadius` · `Theme.of(context)`. 되돌릴 수 없는 삭제는 모두 `AppConfirmDialog.show(..., isDestructive: true)` 뒤에만.
- 문구는 l10n 만. 새 키는 `app_ko.arb` · `app_en.arb` · `app_ja.arb` 셋 다(`@키` description 포함), 그 뒤 `cd packages/l10n && flutter gen-l10n`. 이미 있는 `commonCancel` · `commonSave` · `commonDelete` 는 재사용한다.
- **질문 · 답 글은 로그 · 예외 메시지 · 계측 · `toString` 에 남기지 않는다**(core 계획 규칙). 새 엔티티의 Freezed `toString` 이 글을 찍으므로 `Conversation` · `ChatTurnRecord` · `ChatTurnDraft` · `ChatTurnText` 는 `toString` 을 override 해 id · seq · 길이만 보인다 — 각 엔티티 테스트에 "toString 에 글 없음".
- 날짜는 늘 `Clock.now()` 의 **로컬** `DateTime` 으로 쓴다(`storeDateTimeAsText: true` — UTC 와 섞으면 문자열 비교가 틀린다). 테스트는 `test/support/diary_fixtures.dart` 의 `MutableClock` 을 쓴다.
- 임시 대화는 `conversations` · `chat_turns` 에 **한 행도** 쓰지 않는다 — 세 곳(cubit · 저장소 호출 · 테스트)에서 지킨다.
- 셸 · `ChatSettingsPage` 는 재구성 소유다. 이 계획은 셸에 한 줄(정리 호출), `ChatSettingsPage` 에 한 줄(섹션 끼우기)만 더한다. `ChatSettingsSection` 내부는 고치지 않는다.
- 매 task 끝: `cd apps/walk && flutter analyze && flutter test` 0 오류 · 전체 통과. 커밋은 task 마다 하나(`feat(walk): …`, 문서는 `docs(walk): …`).

## Review Focus

1. **임시 대화는 아무것도 안 남긴다(Task 5 · 7)** — `startTemporary` 뒤 답이 끝나도, 멈춰도, 턴을 지워도 `ChatHistoryRepository` 의 쓰기 메서드가 한 번도 불리지 않는다(mocktail `verifyNever`). 사용량 행은 `temporary: true` 로 남는다.
2. **이어가기 문맥은 글만(Task 4)** — `resume` 뒤 요청의 `messages` 에 `vendorState` · `ToolResultsMessage` · 이미지가 없고, 멈춘 턴은 `'$answer\n${ChatSession.stoppedNote}'`, 최근 20턴만, 사진 수 0. 벤더 · 모델이 바뀌면 다음 `ask` 전에 메모리 문맥이 같은 모양으로 접힌다.
3. **저장 순서 · 경쟁(Task 5)** — 첫 저장 턴에서 대화 행이 생기고 그 id 를 이후 턴이 쓴다. 저장은 직렬(앞 저장이 끝나기 전 다음 턴이 끝나도 seq 순서 유지). [새 대화] · 다른 대화 열기 · 멈춤 직후에 늦게 끝난 저장이 새 대화에 섞이지 않는다(세대 확인).
4. **지금 열린 대화가 밖에서 지워지면(Task 5)** — 목록 · 물어보기 설정 · 보관 정리 어느 쪽에서 지워져도 탭은 빈 새 대화가 된다(`watchExists`). 정리는 열린 대화를 건너뛴다(`OpenConversation`).
5. **잠금(Task 6 · 7 · 8)** — 대화 목록 · 사용량 화면은 `pushDiaryRoute`, 잠겨 있으면 잠금 화면이 먼저. 잠긴 동안 ⋮ 는 "앱 설정"만.
6. **`FLAG_SECURE` 켜고 끄기(Task 7)** — 임시 대화 + 물어보기 탭이 보일 때만 켜짐. 다른 탭 · [새 대화] · 지난 대화 열기 · dispose 에서 꺼짐. 같은 값을 연달아 보내지 않는다.
7. **migration 준비(Task 1)** — `foreign_keys` 가 켜져 cascade 가 실제로 돈다. v1 스키마 덤프가 커밋돼 2단계가 `wiki_notes` migration 테스트를 만들 수 있다.

## 기기 QA 목록(이 계획의 task 를 막지 않는다)

Task 9 가 walk `testing.md` "물어보기 기기 시나리오"에 "대기"로 옮긴다.

| # | 확인 | 완료 조건 |
|---|---|---|
| H1 | 실제 키로 질문 → 앱 강제 종료 → 다시 켜 목록에서 열기 → "아까 뭐라고 했지?" 에 앞 대화를 안다 | 지난 대화 이어가기(기기에서 실제 키로) |
| H2 | thinking 이 켜진 모델에 글만의 지난 assistant 턴(멈춘 턴 포함)을 보내도 400 이 없다 — core 계획 C4 와 같은 질문, 결과를 함께 적는다 | 멈춘 답이 다음 문맥에 들어간다 |
| H3 | 대화 중 모델 · 벤더를 바꾼 뒤 이어 묻기 — 키 기획 ③ · ④ 가 들어온 뒤에만 가능. 그 전에는 단위 테스트(Task 4)로 갈음하고 "대기(③ · ④ 후)" | 모델 바꿔도 이어감 |
| H4 | 임시 대화에서 스크린샷 · 화면 녹화가 막히고 최근 앱 썸네일이 가려진다. 일기 탭으로 가거나 [새 대화]면 다시 찍힌다 | `FLAG_SECURE` |
| H5 | 보관 30일로 두고 기기 날짜를 31일 뒤로 → 앱 복귀 → 그 대화가 목록에서 사라짐(열려 있던 대화는 남음) | 보관 기간 자동 삭제 |
| H6 | 이어간 대화에서 사진 질문 12장 넘게 — 한도가 0부터 다시 세고 안내 문구가 새 힌트 | 사진 한도 0부터 |

---

### Task 1: `chat` DB 와 대화 기록 저장소

**Files:**
- Create: `lib/domain/chat/entity/conversation.dart` — `Conversation` · `ChatTurnRecord` · `ChatTurnDraft` · `ChatTurnText` · `conversationTitleFrom`
- Create: `lib/domain/chat/repository/chat_history_repository.dart`
- Create: `lib/data/chat/database/chat_tables.dart` — `Conversations` · `ChatTurns` · `ChatUsageRows`(테이블 이름 `chat_usage` — 쓰기 · 읽기는 Task 2)
- Create: `lib/data/chat/database/chat_database.dart`(+ `.g.dart`)
- Create: `lib/data/chat/database/drift_chat_history_repository.dart`
- Create: `drift_schemas/chat/drift_schema_v1.json` — `cd apps/walk && dart run drift_dev schema dump lib/data/chat/database/chat_database.dart drift_schemas/chat/`
- Modify: `lib/core/di/register_module.dart` — `ChatDatabase` 등록 · dispose
- Test: `test/domain/chat/entity/conversation_test.dart` · `test/data/chat/database/chat_database_test.dart` · `test/data/chat/database/drift_chat_history_repository_test.dart`

**Interfaces:**
- Produces (`conversation.dart`):
  ```dart
  /// 목록 한 줄. [turnCount] 는 저장된 턴 수.
  @freezed
  class Conversation with _$Conversation {
    // id · title · titleEdited · createdAt · updatedAt · turnCount
  }

  /// 저장된 턴 하나(보이는 글만 — D1).
  @freezed
  class ChatTurnRecord with _$ChatTurnRecord {
    // conversationId · seq · question · answer · citedEntryIds(List<String>) · stopped · vendor(ChatVendor) · model · askedAt
    ChatTurnText get text => ChatTurnText(question: question, answer: answer, stopped: stopped);
  }

  /// cubit 이 저장소에 넘기는 새 턴.
  @freezed
  class ChatTurnDraft with _$ChatTurnDraft {
    // question · answer · citedEntryIds · stopped(기본 false) · vendor · model
  }

  /// 세션이 문맥을 다시 채울 때 쓰는 글만의 턴(Task 4).
  @freezed
  class ChatTurnText with _$ChatTurnText {
    // question · answer · stopped(기본 false)
  }

  /// appendTurn 이 돌려주는 저장 위치.
  typedef ChatTurnRef = ({String conversationId, int seq});

  const conversationTitleMax = 30;

  /// 첫 질문의 앞 30자(공백 · 줄바꿈 묶음은 공백 하나, trim, 글자는 grapheme 단위). 넘치면 끝에 '…'.
  String conversationTitleFrom(String question);
  ```
  네 클래스 모두 `toString` override — 글 필드 대신 `Conversation(id: …, turns: 3)` · `ChatTurnRecord(conversationId: …, seq: 2, answerLength: 120, stopped: false)` 모양.
- Produces (`chat_history_repository.dart`):
  ```dart
  abstract interface class ChatHistoryRepository {
    /// updatedAt 최근 순. 바뀔 때마다 다시 낸다.
    Stream<List<Conversation>> conversations();
    /// 그 대화가 있는 동안 true, 지워지면 false 를 낸다(중복 값은 내지 않는다).
    Stream<bool> watchExists(String id);
    Future<int> count();
    /// seq 오름차순. 없는 대화면 빈 목록.
    Future<List<ChatTurnRecord>> turns(String conversationId);
    /// [conversationId] 가 null 이면 대화 행을 새로 만들고(id = IdGenerator, title = conversationTitleFrom(question))
    /// 그 id 와 seq 1 을 돌려준다. 있으면 seq = max(seq)+1, updatedAt = now. 주어진 id 의 행이 없으면 StateError.
    /// askedAt · createdAt · updatedAt 은 Clock.now(). 한 트랜잭션.
    Future<ChatTurnRef> appendTurn({String? conversationId, required ChatTurnDraft turn});
    /// trim 한 [title] 로 바꾸고 titleEdited = true. 빈 문자열이면 아무것도 안 한다. updatedAt 은 그대로.
    Future<void> rename(String id, String title);
    /// 턴 하나를 지운다. 남은 턴이 0 이면 대화도 지운다. titleEdited 가 아니고 지운 턴이 첫 턴이면
    /// 새 첫 턴의 질문으로 제목을 다시 만든다. updatedAt 은 그대로.
    Future<void> deleteTurn(String id, int seq);
    Future<void> delete(String id);
    /// 지운 대화 수. 사용량은 지우지 않는다.
    Future<int> deleteAll();
    /// updatedAt < [cutoff] 인 대화를 지운다. [except] 는 건너뛴다. 지운 수.
    Future<int> deleteOlderThan(DateTime cutoff, {String? except});
  }
  ```
- Produces (테이블, 스펙 §1 "저장소" 그대로 + 아래 차이):
  - `Conversations`: `id` text pk · `title` · `titleEdited` bool default false · `createdAt` · `updatedAt`.
  - `ChatTurns`: `conversationId` text `references(Conversations, #id, onDelete: KeyAction.cascade)` · `seq` int · `question` · `answer` · `citedEntryIds` text(JSON 배열 — `TypeConverter<List<String>, String>`) · `stopped` bool default false · `vendor` `textEnum<ChatVendor>()` · `model` · `askedAt`. pk `{conversationId, seq}`.
  - `ChatUsageRows`(`tableName => 'chat_usage'`): `id` autoIncrement · `at` · `questionKey` · `vendor` textEnum · `model` · `fastMode` bool default false · `purpose` `textEnum<ChatUsagePurpose>()` · `round` · `temporary` bool · `inputTokens` · `outputTokens` · `cacheReadTokens` · `cacheWriteTokens` · `reasoningTokens` nullable · `wikiIndexNotes` · `wikiIndexChars` · `readWikiCalls`(셋 다 default 0). 인덱스 `at`.
- Produces (`chat_database.dart`):
  ```dart
  @DriftDatabase(tables: [Conversations, ChatTurns, ChatUsageRows])
  class ChatDatabase extends _$ChatDatabase {
    ChatDatabase(super.e);
    /// 1: conversations · chat_turns · chat_usage. 2(위키 단계): wiki_notes 를 더한다 —
    /// onUpgrade 의 `if (from < 2)` 자리와 drift_schemas/chat/ 의 v1 덤프로 migration 테스트를 만든다.
    @override int get schemaVersion => 1;
    @override DriftDatabaseOptions get options => const DriftDatabaseOptions(storeDateTimeAsText: true);
    @override MigrationStrategy get migration => MigrationStrategy(
      onCreate: (m) => m.createAll(),
      onUpgrade: (m, from, to) async {
        // 2단계: if (from < 2) await m.createTable(wikiNotes);
      },
      beforeOpen: (_) => customStatement('PRAGMA foreign_keys = ON'),
    );
  }
  ```
- Produces (DI, `register_module.dart`):
  ```dart
  FutureOr<void> disposeChatDatabase(ChatDatabase db) => db.close();
  /// 물어보기 대화 · 사용량(2단계에 위키). 일기 DB 와 따로 — 백업 · 휴지통 · 스키마 버전과 엮이지 않게.
  @LazySingleton(dispose: disposeChatDatabase)
  ChatDatabase chatDatabase() => ChatDatabase(driftDatabase(name: 'chat'));
  ```
  `DriftChatHistoryRepository(ChatDatabase db, IdGenerator ids, Clock clock)` 는 `@LazySingleton(as: ChatHistoryRepository)`.
- Consumes: `ChatVendor`(core Task 2) · `ChatUsagePurpose`(core Task 3) · `IdGenerator` · `Clock`(있음).

- [ ] **Step 1: 실패하는 테스트**
  - `conversation_test.dart`: `제목은 첫 질문의 앞 30자이고 넘치면 …` · `줄바꿈 · 연속 공백은 공백 하나로` · `30자 이하면 그대로, … 없음` · `이모지 · 한글 조합을 글자 중간에서 자르지 않는다`(grapheme) · `toString 에 질문 · 답 글이 없다`(네 클래스).
  - `chat_database_test.dart`(`ChatDatabase(NativeDatabase.memory())`): `foreign_keys 가 켜져 있다`(`PRAGMA foreign_keys` = 1) · `대화를 지우면 턴이 cascade 로 지워진다` · `chat_usage 테이블 이름은 chat_usage 다` · `schemaVersion 은 1`.
  - `drift_chat_history_repository_test.dart`(메모리 DB · `MutableClock` · 순번 id 를 주는 가짜 `IdGenerator`):
    - `첫 appendTurn 은 대화를 만들고 id 를 돌려준다 — 제목은 첫 질문에서`.
    - `같은 id 로 다시 쓰면 seq 가 1 · 2 로 늘고 updatedAt 이 바뀐다`.
    - `없는 id 로 appendTurn 하면 StateError 이고 아무것도 생기지 않는다`.
    - `turns 는 seq 순 — 질문 · 답 · 인용 id · stopped · vendor · model · askedAt 이 그대로 돌아온다`(stopped true 한 턴 포함).
    - `conversations 는 updatedAt 최근 순이고 turnCount 를 준다`, `쓰면 스트림이 다시 낸다`.
    - `rename 은 titleEdited 를 켜고 updatedAt 은 그대로` · `빈 이름은 무시`.
    - `deleteTurn — 첫 턴을 지우면 자동 제목이 새 첫 질문으로` · `titleEdited 면 제목 그대로` · `마지막 턴을 지우면 대화도 사라진다`.
    - `delete · deleteAll 은 턴까지 지우고 chat_usage 는 남긴다`(usage 행 하나를 직접 insert 해 둠) · `deleteAll 은 지운 수를 돌려준다`.
    - `deleteOlderThan 은 기준보다 오래된 것만 지우고 except 는 남긴다`.
    - `watchExists 는 true 를 내고 지우면 false 를 낸다`.
- [ ] **Step 2: 실행해 실패 확인** — `cd apps/walk && flutter test test/domain/chat/entity test/data/chat/database` → 파일 없음으로 FAIL.
- [ ] **Step 3: 구현** — 위 Interfaces. build_runner. 그 뒤 스키마 덤프(Files 의 명령)로 `drift_schemas/chat/drift_schema_v1.json` 을 만든다.
- [ ] **Step 4: 통과 확인** — `cd apps/walk && flutter analyze && flutter test` → PASS.
- [ ] **Step 5: 커밋** — `feat(walk): 물어보기 대화를 저장할 chat DB 와 기록 저장소`

### Task 2: 사용량 저장 `DriftChatUsageLog` · 읽기 저장소

**Files:**
- Create: `lib/domain/chat/entity/chat_usage_summary.dart` — `ChatUsageTotals` · `ChatUsageModelRow` · `ChatUsageMonth`
- Create: `lib/domain/chat/repository/chat_usage_repository.dart`
- Create: `lib/data/chat/database/drift_chat_usage_log.dart` — `DriftChatUsageLog`(쓰기) · `DriftChatUsageRepository`(읽기 · 지우기)
- Delete: `lib/data/chat/noop_chat_usage_log.dart`(core Task 3) — `grep -rn NoopChatUsageLog lib test` 가 0 이 되게. 테스트가 쓰던 곳은 `test/support/fake_chat_usage_log.dart` 로.
- Test: `test/data/chat/database/drift_chat_usage_log_test.dart`

**Interfaces:**
- Produces:
  ```dart
  @freezed class ChatUsageTotals with _$ChatUsageTotals { /* questions · inputTokens · outputTokens · cacheReadTokens */ }
  /// 벤더 · 모델 · 쓰임별 한 줄. purpose 가 wikiDistill 이면 화면이 "위키 정리" 줄로 따로 보인다.
  @freezed class ChatUsageModelRow with _$ChatUsageModelRow { /* vendor · model · purpose · questions · inputTokens · outputTokens */ }
  @freezed class ChatUsageMonth with _$ChatUsageMonth { /* year · month · totals · rows(입력 토큰 많은 순) */ }

  abstract interface class ChatUsageRepository {
    /// 로컬 [DateTime(year, month)] 이상 [DateTime(year, month + 1)] 미만.
    /// questions = 서로 다른 questionKey 수(purpose == chat 만), 토큰은 모든 purpose 합(임시 대화 포함).
    Future<ChatUsageMonth> month(int year, int month);
    /// at < [cutoff] 행을 지운다. 지운 수.
    Future<int> deleteOlderThan(DateTime cutoff);
    Future<void> deleteAll();
  }
  ```
- Produces (data):
  ```dart
  /// ChatUsageRecord 한 건 = chat_usage 한 행. 내용 · 대화 id 는 담지 않는다.
  @LazySingleton(as: ChatUsageLog)
  class DriftChatUsageLog implements ChatUsageLog { DriftChatUsageLog(ChatDatabase db); }

  @LazySingleton(as: ChatUsageRepository)
  class DriftChatUsageRepository implements ChatUsageRepository { DriftChatUsageRepository(ChatDatabase db); }
  ```
- Consumes: `ChatUsageLog` · `ChatUsageRecord`(core Task 3 — 필드 `at · questionKey · vendor · model · fastMode · purpose · round · temporary · inputTokens · outputTokens · cacheReadTokens · cacheWriteTokens · reasoningTokens? · wikiIndexNotes · wikiIndexChars · readWikiCalls`), `ChatUsageRows`(Task 1).

- [ ] **Step 1: 실패하는 테스트** — `drift_chat_usage_log_test.dart`(메모리 DB):
  - `record 는 필드를 빠짐없이 한 행으로 쓴다` — reasoningTokens null · 값 둘 다.
  - `month 는 그 달만 센다 — 앞뒤 달 경계(1일 00:00 포함, 다음 달 1일 00:00 제외)`.
  - `질문 수는 같은 questionKey 의 라운드를 하나로 센다` — 질문 2개(라운드 3 · 1) → questions 2, 토큰은 4행 합.
  - `rows 는 벤더 · 모델 · purpose 로 묶는다` — anthropic/opus · openai/gpt · anthropic/opus wikiDistill 세 줄, wikiDistill 줄은 totals.questions 에 들어가지 않는다.
  - `임시 대화 행도 합계에 들어간다`.
  - `빈 달은 0 과 빈 rows`.
  - `deleteOlderThan 은 기준 전만 지우고 수를 돌려준다` · `deleteAll 은 대화를 지우지 않는다`(대화 하나를 만들어 둠).
- [ ] **Step 2: 실행해 실패 확인** — `cd apps/walk && flutter test test/data/chat/database/drift_chat_usage_log_test.dart` → FAIL.
- [ ] **Step 3: 구현** — 집계는 drift `selectOnly` + `countDistinct` · `sum` 이나 `customSelect` 중 편한 쪽. Noop 삭제 뒤 build_runner(`injection.config.dart` 에서 `ChatUsageLog` → `DriftChatUsageLog`).
- [ ] **Step 4: 통과 확인** — `cd apps/walk && flutter analyze && flutter test` → PASS(세션 테스트는 가짜 기록기를 쓰므로 그대로).
- [ ] **Step 5: 커밋** — `feat(walk): 물어보기 사용량을 chat DB 에 저장하고 달별로 묶어 읽는다`

### Task 3: 보관 기간 설정 · 정리(`ChatHistoryPruner`)

**Files:**
- Create: `lib/domain/chat/chat_history_settings.dart` — `ChatRetention` · `ChatHistorySettings`
- Create: `lib/data/chat/prefs_chat_history_settings.dart`
- Create: `lib/domain/chat/usecase/open_conversation.dart`
- Create: `lib/domain/chat/usecase/chat_history_pruner.dart`
- Modify: `lib/presentation/shell/page/main_shell_page.dart` — `_refresh` 끝, `RingArchiver` 줄 옆에 한 줄
- Modify: `test/presentation/shell/page/main_shell_page_test.dart` 의 getIt 준비 — 가짜 `ChatHistoryPruner` 등록(mocktail, `prune()` → `Future.value()`)
- Test: `test/data/chat/prefs_chat_history_settings_test.dart` · `test/domain/chat/usecase/chat_history_pruner_test.dart` · 셸 테스트 한 건

**Interfaces:**
- Produces:
  ```dart
  /// 오래된 대화 자동 삭제(D10). 위키 · 사용량과 무관.
  enum ChatRetention {
    never(null), day30(Duration(days: 30)), day90(Duration(days: 90));
    const ChatRetention(this.period);
    final Duration? period;
    static const fallback = ChatRetention.never;
  }

  /// 대화 · 위키 설정. 2단계가 wikiIndexSize 를 더한다. ChatSettings(키 · 동의)와 따로 둔다.
  abstract interface class ChatHistorySettings {
    ChatRetention get retention;
    Future<void> setRetention(ChatRetention value);
  }

  /// 지금 탭에 열린 저장 대화 id. ChatCubit 이 쓰고 ChatHistoryPruner 가 읽는다.
  @lazySingleton
  class OpenConversation { String? id; }

  @lazySingleton
  class ChatHistoryPruner {
    ChatHistoryPruner(this._history, this._usage, this._settings, this._open, this._clock);
    /// 사용량 보관: 이번 달 + 지난 12개월(지난해 같은 달까지).
    static const usageMonths = 13;
    /// 보관 기간이 지난 대화(열린 대화 제외)와 13개월 전 사용량을 지운다. 겹쳐 부르면 차례로.
    /// 한쪽이 던져도 다른 쪽은 한다. 던지지 않는다.
    Future<void> prune();
  }
  ```
  `PrefsChatHistorySettings` — `@LazySingleton(as: ChatHistorySettings)`, 키 `walk.chat.retention`, enum 이름 문자열, 모르는 값 · 다른 타입이면 `fallback`(`PrefsDiaryPreferences` 와 같은 `_prefs.get` 패턴).
  정리 기준: 대화 `cutoff = now - retention.period`(never 면 건너뜀) · `except: _open.id`. 사용량 `cutoff = DateTime(now.year, now.month - (usageMonths - 1))`(그 달 1일 00:00).
- 셸 한 줄:
  ```dart
  // 보관 기간이 지난 대화 · 13개월 지난 사용량을 지운다. 화면을 막지 않는다.
  unawaited(getIt<ChatHistoryPruner>().prune());
  ```
- Consumes: `ChatHistoryRepository.deleteOlderThan`(Task 1) · `ChatUsageRepository.deleteOlderThan`(Task 2).

- [ ] **Step 1: 실패하는 테스트**
  - `prefs_chat_history_settings_test.dart`: `처음엔 never` · `저장한 값을 읽는다` · `모르는 이름 · 숫자 값이면 never`.
  - `chat_history_pruner_test.dart`(가짜 저장소 둘 — 받은 cutoff · except 를 기록):
    - `never 면 대화를 지우지 않는다(사용량은 정리)`.
    - `30일이면 now - 30일 을 cutoff 로` · `90일이면 now - 90일` — 실제 메모리 DB 로 한 건 더: 31일 전 대화는 사라지고 29일 전은 남는다.
    - `열린 대화는 except 로 넘긴다`.
    - `사용량 cutoff 는 12개월 전 그 달 1일` — now 2026-11-15 → 2025-11-01, now 2026-01-03 → 2025-01-01.
    - `대화 정리가 던져도 사용량은 정리하고, prune 은 던지지 않는다`.
    - `겹쳐 부르면 차례로 돈다`.
  - `main_shell_page_test.dart`: `시작하면 대화 정리를 부른다`(`verify(() => pruner.prune()).called(greaterThanOrEqualTo(1))`).
- [ ] **Step 2: 실행해 실패 확인** — `cd apps/walk && flutter test test/data/chat test/domain/chat/usecase/chat_history_pruner_test.dart test/presentation/shell` → FAIL.
- [ ] **Step 3: 구현** — 위 Interfaces. build_runner.
- [ ] **Step 4: 통과 확인** — `cd apps/walk && flutter analyze && flutter test` → PASS.
- [ ] **Step 5: 커밋** — `feat(walk): 물어보기 대화 보관 기간과 시작 · 복귀 때 정리`

### Task 4: 세션 — 글로 이어가기 · 임시 대화 표시 · 벤더/모델 변경

**Files:**
- Modify: `lib/domain/chat/usecase/chat_session.dart`
- Test: `test/domain/chat/usecase/chat_session_test.dart`

**Interfaces:**
- Produces:
  ```dart
  /// 지금 질문에 쓸 벤더 · 모델. ② · ③ 이 설정 · 카탈로그에서 읽도록 이 getter 만 바꾼다.
  typedef ChatTarget = ({ChatVendor vendor, String model});

  // ChatSession 에 더함
  /// 지난 대화를 이어갈 때 문맥에 싣는 최근 턴 수.
  static const resumeTurns = 20;

  /// 지금(다음 질문)의 벤더 · 모델. 지금은 (vendor: _model.vendor, model: interimModel).
  ChatTarget get target;

  /// 임시 대화인가. 사용량 기록의 temporary 로 간다.
  bool get temporary;

  /// reset 처럼 세대를 올리고 진행 중인 라운드를 끊은 뒤, [turns] 의 마지막 resumeTurns 개로 문맥을 글로 채운다.
  /// 턴마다 ChatMessage.user(question) → ChatMessage.assistant(parts: [AssistantPart.text(answer)], vendorState: null).
  /// stopped 면 answer 뒤에 '\n$stoppedNote'. answer 가 trim 해서 비면 그 턴은 싣지 않는다. 사진 수는 0.
  void resume(List<ChatTurnText> turns, {required bool temporary});

  /// 지금 시그니처에 temporary 를 더한다(기본 false).
  void reset({bool temporary = false});
  ```
  - 내부: `ChatTarget? _contextTarget` — 메모리 문맥(`vendorState` 포함)을 만든 벤더 · 모델. 라운드가 `completed` 로 끝날 때 그 요청의 target 으로 둔다. `reset` · `resume` 은 null(글만의 문맥은 어디로든 보낼 수 있다).
  - `ask` 시작에서(동기로, `_busy = true` 뒤 `_run` 전) `final t = target; if (_contextTarget != null && _contextTarget != t) _foldToText();` — `_messages` 를 질문 단위로 묶어(UserMessage 하나 + 다음 UserMessage 전까지의 AssistantMessage 들) 그 묶음의 모든 `TextPart` 글을 이어 하나의 글만 assistant 로 바꾼다(`ToolResultsMessage` · `ToolCallPart` · `vendorState` 버림, 글이 비면 묶음째 버림). `_imagesSent = 0`, `_contextTarget = null`. 멈춘 턴은 이미 `'글\n$stoppedNote'` 텍스트이므로 그대로 남는다.
  - 사용량 기록의 `temporary: _temporary`(core Task 3 의 false 고정을 바꿈), `vendor`/`model` 은 그 요청의 target.
  - `_photoLimitJson` 의 hint → `"대화를 다시 열거나 새 대화를 시작하면 다시 사진을 볼 수 있어요"`.
  - 클래스 doc: "메모리의 지금 대화는 고치지 않는다 · 저장 · 복원 · 벤더 교체는 글만" 한 줄로 기존 "지난 메시지는 고치지 않는다" 주석을 바꾼다.
- Consumes: core `stoppedNote` · `interimModel` · `_cancelRound()` · `ChatUsageRecord`, Task 1 `ChatTurnText`.
- **core 가 정의하지 않아 여기서 더하는 것:** `ChatTarget`/`target`, `temporary`, `reset({temporary})`, `resume`, `_contextTarget` 접기. 키 기획 ② 가 먼저 들어와 같은 역할의 "지금 벤더 · 모델" 접근자를 만들었으면 `target` 은 그것을 감싸기만 한다.

- [ ] **Step 1: 실패하는 테스트** — `chat_session_test.dart`(core 의 `_FakeModel` 에 `vendor` 를 바꿀 수 있게 `var vendor = ChatVendor.anthropic` 를 더한다):
  - `resume 뒤 첫 요청의 messages 는 user · assistant 글만이고 그 뒤 새 질문` — `vendorState == null`, `ToolResultsMessage` 없음, parts 는 `TextPart` 하나.
  - `멈춘 턴은 답 뒤에 stoppedNote 줄을 붙인다`.
  - `25턴을 넘기면 마지막 20턴만 싣는다`.
  - `답이 빈 턴은 싣지 않는다`.
  - `resume 뒤 사진 수는 0부터 센다` — 12장을 보낸 대화 → resume → 사진 도구가 다시 12장까지 성공.
  - `사진 한도 안내는 '대화를 다시 열거나 새 대화를 시작하면…'`.
  - `답하는 중 resume 하면 그 질문은 조용히 멈추고 모델 구독이 취소된다`(core `진행 중 reset` 과 같은 모양).
  - `resume(temporary: true) · reset(temporary: true) 뒤 사용량 기록은 temporary true` · `reset() 뒤엔 false`.
  - `벤더가 바뀌면 다음 ask 전에 메모리 문맥을 글로 접는다` — 1번 질문(도구 1회 + 답, `vendorState` 있음) → `model.vendor = openai` → 2번 질문 요청의 messages 가 `[user(q1), assistant(text(도구 전 글 + 답 글)), user(q2)]`, vendorState · 도구 결과 없음, 사용량 기록 vendor 는 openai.
  - `벤더 · 모델이 그대로면 문맥을 접지 않는다` — 2번 요청에 1번의 `AssistantMessage` 가 `identical`.
  - `멈춘 턴이 있는 문맥을 접어도 멈춤 표시가 남는다`.
  - `target 은 모델 vendor 와 interimModel`.
- [ ] **Step 2: 실행해 실패 확인** — `cd apps/walk && flutter test test/domain/chat/usecase/chat_session_test.dart` → FAIL.
- [ ] **Step 3: 구현** — 위 규칙. build_runner 가 필요하면 돌린다.
- [ ] **Step 4: 통과 확인** — `cd apps/walk && flutter analyze && flutter test` → PASS(기존 세션 · cubit 테스트 포함 — `reset` 의 이름 있는 인자는 기존 호출을 깨지 않는다).
- [ ] **Step 5: 커밋** — `feat(walk): 물어보기 세션이 저장된 글로 대화를 이어가고 벤더가 바뀌면 문맥을 글로 접는다`

### Task 5: `ChatCubit` — 턴 저장 · 열기 · 임시 대화 · 턴 지우기

**Files:**
- Modify: `lib/presentation/chat/cubit/chat_state.dart` — `ChatBubble.seq` · `ChatState.conversationId` · `temporary` · `vendor`
- Modify: `lib/presentation/chat/cubit/chat_cubit.dart`
- Modify: `lib/presentation/chat/page/chat_tab.dart` — `ChatCubit(...)` 생성 인자에 `getIt<ChatHistoryRepository>()` · `getIt<OpenConversation>()` **만**(화면은 Task 7)
- Modify: `test/presentation/chat/page/chat_tab_test.dart` 의 getIt 준비 — 가짜 `ChatHistoryRepository` · `OpenConversation` 등록만
- Test: `test/presentation/chat/cubit/chat_cubit_test.dart`

**Interfaces:**
- Produces (상태):
  ```dart
  // ChatBubble 에 더함
  /// 저장된 턴의 seq. 저장 전 · 임시 대화 · 실패한 말풍선은 null. 한 턴의 질문 · 답 말풍선이 같은 값.
  @override final int? seq;

  // ChatState 에 더함
  /// 지금 열린 저장 대화. 첫 턴을 저장하기 전 · 임시 대화면 null.
  @override final String? conversationId;
  /// 임시 대화 중(D4).
  @override final bool temporary;          // 기본 false
  /// 배너에 쓰는 지금 벤더. refresh 때 세션 target 에서 읽는다.
  @override final ChatVendor vendor;       // 기본 ChatVendor.anthropic
  ```
- Produces (cubit):
  ```dart
  ChatCubit(this._session, this._settings, this._diary, this._trace, this._history, this._open,
      {void Function(VoidCallback) schedulePostFrame = _addPostFrame});

  /// 저장된 대화를 연다. 답하는 중이면 끊는다(newConversation 과 같은 규칙). 임시 대화였으면 사라진다.
  /// 말풍선 · 근거 칩(휴지통 · 없는 기록 빼고) · stopped · seq 를 복원하고 세션을 resume(temporary: false).
  /// 그 대화가 없으면(사이에 지워짐) 빈 새 대화.
  Future<void> open(String conversationId);

  /// 지금 대화를 닫고 빈 임시 대화를 연다 — session.reset(temporary: true).
  void startTemporary();

  /// [userIndex] 는 지울 턴의 질문 말풍선 index. 답하는 중이면 무시.
  /// - seq 가 있으면: 저장소 deleteTurn → 남은 턴으로 open 과 같은 복원(말풍선 · 세션 resume). 대화가 사라졌으면 빈 새 대화.
  /// - 임시 대화 · 저장 전(seq null): 그 두 말풍선을 빼고, 실패 아닌 남은 쌍으로 session.resume(temporary: state.temporary).
  /// - 실패 말풍선 쌍: 화면에서만 뺀다(세션은 이미 되돌렸다).
  Future<void> deleteTurn(int userIndex);
  ```
  `newConversation()` 은 `session.reset()`(temporary false) · `conversationId: null` · `temporary: false`.
- **저장 규칙**:
  - `send` 에서 질문 글 · `_session.target` 을 잡아 둔다.
  - `ChatFinished` → 지금처럼 `_resolve` · `_end` 뒤, `state.temporary` 가 아니고 답 글(마지막 말풍선 text)이 trim 해서 비지 않았으면 `ChatTurnDraft(question, answer, citedEntryIds: event.citedEntryIds, stopped: false, vendor, model)` 저장.
  - `stop()` 의 `ChatStopKept(:text, :citedEntryIds)` → 같은 규칙으로 `stopped: true`, `answer: text`. `ChatStopDropped` · `ChatStopIdle` · 실패 → 저장 안 함.
  - 저장은 `_saveTail` 로 직렬. 돌아온 `ChatTurnRef` 의 `conversationId` 를 상태로, `seq` 를 그 턴의 질문 · 답 두 말풍선에 붙인다.
  - 저장 시작 시의 `_generation` 을 들고, 끝났을 때 세대가 바뀌었으면(새 대화 · 다른 대화 열기 · 임시 시작) `conversationId` · seq 를 화면에 붙이지 않는다(행은 이미 써졌으니 목록에는 있다).
  - 저장이 던지면 조용히 넘어간다(말풍선은 화면에 남음, 다음 턴이 다시 시도). `send` 가 돌려준 Future 는 저장 시도까지 끝난 뒤 완료된다(테스트가 기다릴 수 있게).
  - `conversationId` 가 바뀔 때마다 `_open.id = conversationId`, 그리고 `_history.watchExists(id)` 를 구독해 false 가 오면 `newConversation()`(Review Focus 4). close 때 구독 해제 · `_open.id = null`.
  - `refresh()` 에서 `vendor: _session.target.vendor` 도 emit.
- Consumes: Task 1 `ChatHistoryRepository` · `ChatTurnDraft` · `ChatTurnRecord`, Task 3 `OpenConversation`, Task 4 `resume` · `reset(temporary:)` · `target`, core `ChatStopResult` · `ChatBubble.stopped`.

- [ ] **Step 1: 실패하는 테스트** — `chat_cubit_test.dart`(지금 파일처럼 mocktail `_MockSession` + `_MockHistory`):
  - `답이 끝나면 첫 턴에서 대화를 만들고 conversationId · 두 말풍선 seq 가 생긴다` — `appendTurn(conversationId: null, turn: 질문 · 답 · 인용 id · stopped false · vendor · model)`.
  - `두 번째 턴은 같은 conversationId 로 저장한다`.
  - `글이 온 뒤 멈추면 stopped true 로 저장한다` · `글 없이 멈추면 저장하지 않는다` · `실패한 질문은 저장하지 않는다` · `답 글이 비면 저장하지 않는다`.
  - `임시 대화는 끝 · 멈춤 · 턴 지우기 어디서도 저장소에 쓰지 않는다`(`verifyNever` appendTurn · deleteTurn · delete).
  - `저장이 던져도 답은 끝나고 busy false`.
  - `저장이 끝나기 전에 새 대화를 시작하면 conversationId 가 붙지 않는다`(`Completer` 로 저장을 붙잡음).
  - `open 은 말풍선 · 근거 칩 · stopped · seq 를 복원하고 session.resume(turns 의 text, temporary: false)` — 휴지통 인용은 빠진다.
  - `답하는 중 open 하면 끊고 연다` · `임시 대화 중 open 하면 temporary false`.
  - `없는 대화를 open 하면 빈 새 대화`.
  - `startTemporary 는 말풍선을 비우고 temporary true, session.reset(temporary: true)` · `newConversation 은 temporary false`.
  - `deleteTurn(저장된 턴) 은 deleteTurn 뒤 남은 턴으로 resume 하고 말풍선을 다시 그린다` · `마지막 턴이면 빈 새 대화`.
  - `deleteTurn(임시 대화) 은 화면에서 빼고 남은 쌍으로 resume(temporary: true)` · `실패 쌍은 화면에서만 뺀다(resume 안 부름)` · `답하는 중이면 무시`.
  - `열린 대화가 밖에서 지워지면(watchExists false) 빈 새 대화가 된다`.
  - `conversationId 가 바뀌면 OpenConversation.id 도, close 하면 null`.
  - `refresh 는 세션 target 의 vendor 를 state 에 둔다`.
- [ ] **Step 2: 실행해 실패 확인** — `cd apps/walk && flutter test test/presentation/chat/cubit` → FAIL.
- [ ] **Step 3: 구현** — 위 Interfaces · 규칙. build_runner(`chat_state.freezed.dart`).
- [ ] **Step 4: 통과 확인** — `cd apps/walk && flutter analyze && flutter test` → PASS(`chat_tab_test` 는 getIt 등록만 더해 그대로 통과).
- [ ] **Step 5: 커밋** — `feat(walk): 물어보기 턴을 끝날 때마다 저장하고 지난 대화 · 임시 대화를 연다`

### Task 6: 대화 목록 화면 `ChatHistoryPage`

**Files:**
- Create: `lib/presentation/chat/cubit/chat_history_cubit.dart` · `chat_history_state.dart`(+ `.freezed.dart`)
- Create: `lib/presentation/chat/page/chat_history_page.dart`
- Create: `lib/presentation/chat/widget/rename_conversation_dialog.dart`
- Modify: `packages/l10n/lib/l10n/app_{ko,en,ja}.arb`
- Test: `test/presentation/chat/cubit/chat_history_cubit_test.dart` · `test/presentation/chat/page/chat_history_page_test.dart`

**Interfaces:**
- Produces:
  ```dart
  @freezed
  class ChatHistoryState with _$ChatHistoryState { /* loading(기본 true) · conversations(List<Conversation>) */ }

  class ChatHistoryCubit extends Cubit<ChatHistoryState> {
    ChatHistoryCubit(this._history);      // 생성 때 conversations() 구독
    Future<void> rename(String id, String title);
    Future<void> delete(String id);
    Future<int> deleteAll();
  }

  /// 저장된 대화 목록. 행을 누르면 그 id 로 pop 한다 — 여는 쪽(ChatTab)이 cubit.open 한다.
  /// pushDiaryRoute<String> 로 연다(잠금 아래).
  class ChatHistoryPage extends StatelessWidget { const ChatHistoryPage({super.key}); }

  /// 지금 이름을 채운 입력 다이얼로그. 저장이면 trim 한 글, 취소 · 빈 글이면 null.
  Future<String?> showRenameConversationDialog(BuildContext context, {required String current});
  ```
- 화면:
  - `Scaffold(appBar: AppBar(title: walkChatHistoryTitle, actions: [AppOverflowMenu(items: [모두 지우기 — 목록이 비면 items 빈 목록])]))`.
  - 행 `AppListTile(key: Key('chat-history-<id>'), title: Text(title, maxLines: 1, overflow: ellipsis), subtitle: Text('<시각> · walkChatHistoryTurns(turnCount)'), trailing: AppOverflowMenu(items: [이름 바꾸기, 삭제(destructive)]), onTap: () => Navigator.pop(context, id))`. 시각은 오늘이면 `DateFormat.Hm(locale)`, 아니면 `DateFormat.yMMMd(locale)`(오늘 판단은 `getIt<Clock>().now()`).
  - 삭제 → `AppConfirmDialog.show(title: walkChatHistoryDeleteTitle, content: walkChatHistoryDeleteBody, confirmLabel: commonDelete)` 뒤 `cubit.delete`.
  - 모두 지우기 → `AppConfirmDialog.show(title: walkChatHistoryDeleteAllTitle, content: walkChatHistoryDeleteAllBody(count), confirmLabel: walkChatHistoryDeleteAllConfirm)` 뒤 `cubit.deleteAll`.
  - 로딩: 가운데 `CircularProgressIndicator`. 빈 상태: `AppPlaceholder(icon: Icons.forum_outlined, message: walkChatHistoryEmpty)`.
  - 이름 바꾸기 다이얼로그: `AlertDialog` + `TextField`(테마 `InputDecorationTheme`, `maxLength: 60`, autofocus) + `AppButton.text(commonCancel)` · `AppButton.text(commonSave)`. 공통 위젯에 입력 다이얼로그가 없어 이 feature 에 둔다(재사용 가능성: 위키 2단계 메모 제목 — 그때 승격 검토).

**l10n 새 키**:
| 키 | ko | en | ja |
|---|---|---|---|
| `walkChatHistoryTitle` | 대화 목록 | Conversations | 会話一覧 |
| `walkChatHistoryEmpty` | 저장된 대화가 없어요 | No saved conversations | 保存された会話はありません |
| `walkChatHistoryTurns` | 질문 {count}개 | `{count, plural, =1{1 question} other{{count} questions}}` | 質問{count}件 |
| `walkChatHistoryRename` | 이름 바꾸기 | Rename | 名前を変更 |
| `walkChatHistoryRenameHint` | 대화 이름 | Conversation name | 会話の名前 |
| `walkChatHistoryDeleteTitle` | 이 대화를 지울까요? | Delete this conversation? | この会話を削除しますか？ |
| `walkChatHistoryDeleteBody` | 질문과 답이 이 폰에서 지워져요. | The questions and answers will be removed from this phone. | 質問と回答がこの端末から削除されます。 |
| `walkChatHistoryDeleteAll` | 대화 모두 지우기 | Delete all conversations | すべての会話を削除 |
| `walkChatHistoryDeleteAllTitle` | 대화를 모두 지울까요? | Delete all conversations? | すべての会話を削除しますか？ |
| `walkChatHistoryDeleteAllBody` | 대화 {count}개를 지워요. 사용량 기록은 남아요. | `{count, plural, =1{1 conversation will be deleted.} other{{count} conversations will be deleted.}} Usage records are kept.` | {count}件の会話を削除します。使用量の記録は残ります。 |
| `walkChatHistoryDeleteAllConfirm` | 모두 지우기 | Delete all | すべて削除 |

`count` placeholder 는 `int`. description 은 "대화 목록: …" 로 시작.

- [ ] **Step 1: 실패하는 테스트**
  - `chat_history_cubit_test.dart`: `저장소 스트림을 그대로 상태로(loading false)` · `rename · delete · deleteAll 은 저장소로 넘긴다`.
  - `chat_history_page_test.dart`(가짜 저장소 + `DiaryLockCubit` mock, `pushDiaryRoute<String>` 로 연 하네스):
    - `최근 순 행 — 제목 · 오늘이면 시:분 · 질문 n개`.
    - `행을 누르면 그 id 로 pop 한다`(하네스가 받은 결과 확인).
    - `삭제는 확인 다이얼로그 뒤에만 — 취소면 그대로, 확인이면 사라진다`.
    - `이름 바꾸기 — 지금 이름이 채워진 칸, 저장하면 목록 제목이 바뀐다`.
    - `모두 지우기는 '대화 n개' 확인 뒤에만, 목록이 비면 메뉴가 없다`.
    - `빈 목록이면 '저장된 대화가 없어요'`.
    - `잠겨 있으면 목록이 트리에 없고 잠금 화면이 보인다`.
- [ ] **Step 2: 실행해 실패 확인** — `cd apps/walk && flutter test test/presentation/chat` → FAIL.
- [ ] **Step 3: 구현** — 위 Interfaces · 화면. build_runner.
- [ ] **Step 4: l10n** — 세 arb 에 키 추가, `cd packages/l10n && flutter gen-l10n`.
- [ ] **Step 5: 통과 확인** — `cd apps/walk && flutter analyze && flutter test` → PASS.
- [ ] **Step 6: 커밋** — `feat(walk): 물어보기 대화 목록 — 열기 · 이름 바꾸기 · 삭제 · 모두 지우기`

### Task 7: 물어보기 탭 — ⋮ 항목 · 임시 대화 배너 · `FLAG_SECURE` · 턴 지우기

**Files:**
- Create: `lib/domain/chat/secure_window.dart` — `SecureWindow`
- Create: `lib/data/chat/channel_secure_window.dart`
- Modify: `android/app/src/main/kotlin/com/karma/walk/MainActivity.kt` — 채널 `com.karma.walk/secure_window`
- Create: `lib/presentation/chat/widget/temporary_chat_banner.dart`
- Create: `lib/presentation/chat/widget/bubble_actions_sheet.dart`
- Create: `lib/presentation/chat/widget/chat_vendor_label.dart`
- Modify: `lib/presentation/chat/widget/chat_bubble_view.dart` — `onLongPress`
- Modify: `lib/presentation/chat/page/chat_tab.dart` — 앱바 ⋮ entries · [새 대화] 조건 · 배너 · 시트 · 보안 창
- Modify: `packages/l10n/lib/l10n/app_{ko,en,ja}.arb`
- Test: `test/data/chat/channel_secure_window_test.dart` · `test/presentation/chat/widget/temporary_chat_banner_test.dart` · `test/presentation/chat/page/chat_tab_test.dart` · `test/support/fake_secure_window.dart`(새, 받은 값을 모음)

**Interfaces:**
- Produces:
  ```dart
  /// 창 캡처 차단(안드로이드 FLAG_SECURE). 임시 대화가 보이는 동안만 켠다.
  abstract interface class SecureWindow { Future<void> setSecure(bool on); }

  /// MainActivity 채널. 안드로이드가 아니면(MissingPluginException) · PlatformException 이면 조용히 넘어간다.
  @LazySingleton(as: SecureWindow)
  class ChannelSecureWindow implements SecureWindow {
    static const channel = MethodChannel('com.karma.walk/secure_window');
    // invokeMethod<void>('setSecure', on)
  }

  /// 입력칸 위 한 줄 배너. Key('chat-temporary-banner').
  class TemporaryChatBanner extends StatelessWidget { const TemporaryChatBanner({required this.vendor, super.key}); final ChatVendor vendor; }

  enum BubbleAction { deleteTurn }          // 2단계가 addToWiki 를 더한다
  /// 말풍선 길게 누르기 시트(showModalBottomSheet + AppListTile). 닫으면 null.
  Future<BubbleAction?> showBubbleActions(BuildContext context);

  /// 벤더 표시 이름. 키 기획 ② 가 같은 역할 함수를 이미 만들었으면 그것을 쓰고 이 파일은 만들지 않는다.
  String chatVendorLabel(AppLocalizations l10n, ChatVendor vendor);

  // ChatBubbleView 에 더함
  final VoidCallback? onLongPress;          // GestureDetector(onLongPress) 로 말풍선을 감싼다
  ```
- Kotlin(`MainActivity.configureFlutterEngine` 안, 다른 채널 옆):
  ```kotlin
  // 물어보기 임시 대화: 보이는 동안 스크린샷 · 녹화 · 최근 앱 썸네일을 막는다.
  MethodChannel(messenger, "com.karma.walk/secure_window").setMethodCallHandler { call, result ->
      if (call.method != "setSecure") { result.notImplemented(); return@setMethodCallHandler }
      if (call.arguments == true) window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
      else window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
      result.success(null)
  }
  ```
- `chat_tab.dart`:
  - actions(재구성 모양 유지): 풀렸으면 `[_NewConversationAction(), FeatureMenu(settings: SettingsTarget.chat, entries: [대화 목록(Key('chat-menu-history'), Icons.history), if (access == ready) 임시 대화로 시작(Key('chat-menu-temporary'), Icons.visibility_off_outlined)])]`, 잠겼으면 재구성 그대로(`showFeatureSettings: false`, entries 없음). entries 는 `FeatureMenu` 의 끝 두 항목(물어보기 설정 · 앱 설정) **위**에 그려진다(재구성 규칙).
  - [대화 목록] → `final id = await pushDiaryRoute<String>(context, page: (_) => const ChatHistoryPage()); if (id != null) await _cubit.open(id);`
  - [임시 대화로 시작] → `_cubit.startTemporary()`.
  - `_NewConversationAction` 표시 조건: `ready && (bubbles.isNotEmpty || temporary)`.
  - `_ChatBody` ready 열: `if (state.temporary) TemporaryChatBanner(vendor: state.vendor)` 를 `ChatInput` 바로 위에.
  - `_BubbleList`: `busy` 가 아니면 말풍선 `onLongPress` → `showBubbleActions` → `deleteTurn` 이면 `AppConfirmDialog.show(title: walkChatTurnDeleteTitle, content: walkChatTurnDeleteBody, confirmLabel: commonDelete)` → `cubit.deleteTurn(userIndex)`(답 말풍선이면 index - 1).
  - 보안 창: State 에 `bool _secureOn = false`, `void _syncSecure()` — `want = widget.active && _cubit.state.temporary`, 다르면 `_secure.setSecure(want)`. `didUpdateWidget`(active 변화) · `BlocListener(listenWhen: temporary 변화)` 에서 부르고, `dispose` 에서 켜져 있으면 끈다. 잠겨 있어도 · 위에 화면이 push 돼도 켠 채 둔다(스펙 §2).
- 배너 모양: `Container(color: colorScheme.surfaceContainerHighest, padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm), Row(Icon(Icons.visibility_off_outlined, size: bodySmall 크기), SizedBox(width: AppSpacing.sm), Expanded(Text(walkChatTemporaryBanner(vendor), style: bodySmall · onSurfaceVariant))))`.

**l10n 새 키**:
| 키 | ko | en | ja |
|---|---|---|---|
| `walkChatTemporaryStart` | 임시 대화로 시작 | Start temporary chat | 一時的な会話を始める |
| `walkChatTemporaryBanner` | 임시 대화 · 이 폰에 저장되지 않아요. 질문과 찾은 기록은 {vendor}에 전송되고, 그곳의 보관 정책은 앱이 정할 수 없어요. | Temporary chat · Not saved on this phone. Your questions and the records found are sent to {vendor}, and the app can't control how long they keep them. | 一時的な会話・この端末には保存されません。質問と見つかった記録は{vendor}に送信され、その保存方針はアプリでは決められません。 |
| `walkChatTurnDelete` | 이 질문과 답 지우기 | Delete this question and answer | この質問と回答を削除 |
| `walkChatTurnDeleteTitle` | 이 질문과 답을 지울까요? | Delete this question and answer? | この質問と回答を削除しますか？ |
| `walkChatTurnDeleteBody` | 이 대화에서 빠지고, 다음 질문의 문맥에도 들어가지 않아요. | It will be removed from this conversation and won't be used as context for later questions. | この会話から削除され、次の質問の文脈にも使われません。 |
| `walkChatVendorAnthropic` | Anthropic | Anthropic | Anthropic |
| `walkChatVendorOpenai` | OpenAI | OpenAI | OpenAI |

`walkChatTemporaryBanner` 의 `vendor` 는 `String`. ⋮ [대화 목록] 라벨은 Task 6 의 `walkChatHistoryTitle` 을 쓴다. 벤더 이름 키는 ② 에 같은 키가 있으면 만들지 않는다.

- [ ] **Step 1: 실패하는 테스트**
  - `channel_secure_window_test.dart`(`TestDefaultBinaryMessengerBinding` mock handler): `setSecure(true/false) 는 setSecure 를 그 값으로 부른다` · `핸들러가 없거나 PlatformException 이어도 던지지 않는다`.
  - `temporary_chat_banner_test.dart`: `벤더 이름이 든 안내를 보인다`(anthropic → 'Anthropic').
  - `chat_tab_test.dart`(재구성이 바꾼 앱바 테스트는 그대로 두고 더한다; getIt 에 가짜 `ChatHistoryRepository` · `SecureWindow` · `OpenConversation`):
    - `⋮ 순서는 대화 목록 · 임시 대화로 시작 · 물어보기 설정 · 앱 설정`(키 순서로 확인) · `잠긴 동안 ⋮ 에는 앱 설정만`.
    - `키가 없으면 임시 대화로 시작이 없다`.
    - `대화 목록에서 행을 고르면 그 대화가 열린다`(가짜 저장소 대화 하나, 행 탭 → 말풍선 복원).
    - `잠긴 채 대화 목록을 열 수 없다`(⋮ 에 항목 없음) — 그리고 목록 화면이 떠 있는 중 잠기면 목록이 트리에서 빠진다.
    - `임시 대화로 시작하면 배너가 보이고 [새 대화]를 누르면 배너가 사라진다`.
    - `임시 대화 + 탭이 보이면 setSecure(true), 탭이 안 보이게 되면 false, [새 대화]면 false, dispose 면 false` · `일반 대화에서는 setSecure 를 부르지 않는다` · `같은 값을 두 번 보내지 않는다`.
    - `말풍선을 길게 누르면 시트 → 지우기 → 확인 뒤에만 턴이 사라진다`(취소면 그대로) · `답하는 중엔 시트가 뜨지 않는다`.
- [ ] **Step 2: 실행해 실패 확인** — `cd apps/walk && flutter test test/data/chat test/presentation/chat` → FAIL.
- [ ] **Step 3: 구현** — 위 Interfaces · Kotlin. build_runner. `./gradlew` 빌드까지는 요구하지 않지만 `flutter build apk --debug` 가 되는지 한 번 확인(가능하면).
- [ ] **Step 4: l10n** — 세 arb, `cd packages/l10n && flutter gen-l10n`.
- [ ] **Step 5: 통과 확인** — `cd apps/walk && flutter analyze && flutter test` → PASS.
- [ ] **Step 6: 커밋** — `feat(walk): 물어보기 ⋮ 에 대화 목록 · 임시 대화, 임시 대화 배너와 화면 캡처 차단, 턴 지우기`

### Task 8: 물어보기 설정 — 대화 기록 섹션 · 사용량 화면

**Files:**
- Create: `lib/presentation/settings/cubit/chat_history_settings_cubit.dart` · `chat_history_settings_state.dart`(+ `.freezed.dart`)
- Create: `lib/presentation/settings/widget/chat_history_settings_section.dart`
- Create: `lib/presentation/settings/cubit/chat_usage_cubit.dart` · `chat_usage_state.dart`(+ `.freezed.dart`)
- Create: `lib/presentation/settings/page/chat_usage_page.dart`
- Modify: `lib/presentation/settings/page/chat_settings_page.dart` — `ListView(children: [ChatSettingsSection(), ChatHistorySettingsSection()])` **한 줄**
- Modify: `packages/l10n/lib/l10n/app_{ko,en,ja}.arb`
- Test: `test/presentation/settings/cubit/chat_history_settings_cubit_test.dart` · `test/presentation/settings/cubit/chat_usage_cubit_test.dart` · `test/presentation/settings/widget/chat_history_settings_section_test.dart` · `test/presentation/settings/page/chat_usage_page_test.dart` · `test/presentation/settings/open_settings_test.dart`(한 건)

**Interfaces:**
- Produces:
  ```dart
  @freezed class ChatHistorySettingsState with _$ChatHistorySettingsState { /* retention(기본 fallback) · conversationCount(기본 0) */ }
  class ChatHistorySettingsCubit extends Cubit<ChatHistorySettingsState> {
    ChatHistorySettingsCubit(this._settings, this._history);
    Future<void> load();                         // retention · count()
    Future<void> setRetention(ChatRetention value);
    Future<int> deleteAllConversations();        // 뒤에 count 다시 읽기
  }

  /// 물어보기 설정 화면에서 ChatSettingsSection 아래. 2단계가 위키 색인 크기 · 위키 모두 지우기 행을 더한다.
  class ChatHistorySettingsSection extends StatelessWidget { const ChatHistorySettingsSection({super.key}); }

  @freezed class ChatUsageState with _$ChatUsageState { /* year · month · usage(ChatUsageMonth?) · loading */ }
  class ChatUsageCubit extends Cubit<ChatUsageState> {
    ChatUsageCubit(this._usage, this._clock);    // 처음은 이번 달
    Future<void> load();
    Future<void> previousMonth();                // 이번 달 - 12 까지(보관 13개월)
    Future<void> nextMonth();                    // 이번 달까지
    bool get canGoBack; bool get canGoForward;
    Future<void> clear();                        // deleteAll 뒤 load
  }

  class ChatUsagePage extends StatelessWidget { const ChatUsagePage({super.key}); }
  ```
- 섹션(`SettingsSectionHeader(walkChatHistorySettingsHeader)` 아래, Task 1 재구성의 공용 위젯):
  - `AppListTile(key: Key('chat-history-retention'), leading: Icons.auto_delete_outlined, title: walkChatHistoryRetention, trailing: 현재 값)` → 고르기 다이얼로그(`DiaryStorageSection._pickRetention` 과 같은 모양의 라디오). 아래 bodySmall 안내 `walkChatHistoryRetentionNote`.
  - `AppListTile(key: Key('chat-history-usage'), leading: Icons.bar_chart_outlined, title: walkChatUsageTitle)` → `pushDiaryRoute(context, page: (_) => const ChatUsagePage())`.
  - `AppListTile(key: Key('chat-history-delete-all'), leading: Icons.delete_sweep_outlined, title: walkChatHistoryDeleteAll, enabled: count > 0)` → Task 6 과 같은 확인 문구(`walkChatHistoryDeleteAllTitle` · `Body(count)` · `Confirm`) 뒤 삭제.
  - cubit 은 섹션이 `BlocProvider(create: getIt …..load())` 로 소유(`ChatSettingsSection` 과 같은 패턴).
- 사용량 화면:
  - 앱바: 제목 `walkChatUsageTitle`, `AppOverflowMenu([walkChatUsageClear])` → `AppConfirmDialog(walkChatUsageClearTitle · Body · confirm commonDelete)` → `clear()`.
  - 달 줄: `IconButton(chevron_left, tooltip: walkChatUsagePrevMonth, onPressed: canGoBack ? … : null)` · `DateFormat.yMMMM(locale)` · `IconButton(chevron_right, tooltip: walkChatUsageNextMonth)`.
  - 합계 네 줄 `AppListTile`(질문 · 입력 · 출력 · 캐시 읽기, trailing 은 `NumberFormat.decimalPattern(locale)`).
  - `SettingsSectionHeader(walkChatUsageByModel)` 아래 rows: `AppListTile(title: '${chatVendorLabel} · ${model}'(wikiDistill 이면 뒤에 ' · ' + walkChatUsageWikiDistill), subtitle: walkChatUsageModelLine(questions, input, output))`.
  - 비면 `AppPlaceholder(icon: Icons.bar_chart_outlined, message: walkChatUsageEmpty)`(달 줄은 남김).
  - 맨 아래 bodySmall `walkChatUsageCostNote`. 금액은 보이지 않는다.

**l10n 새 키**:
| 키 | ko | en | ja |
|---|---|---|---|
| `walkChatHistorySettingsHeader` | 대화 기록 | Conversation history | 会話の記録 |
| `walkChatHistoryRetention` | 대화 보관 기간 | Keep conversations | 会話の保存期間 |
| `walkChatHistoryRetentionNever` | 지우지 않음 | Forever | 削除しない |
| `walkChatHistoryRetention30d` | 30일 | 30 days | 30日 |
| `walkChatHistoryRetention90d` | 90일 | 90 days | 90日 |
| `walkChatHistoryRetentionNote` | 보관 기간이 지난 대화는 다음에 앱을 열 때 지워져요. 사용량 기록은 13개월 동안 남아요. | Conversations older than this are deleted the next time you open the app. Usage records are kept for 13 months. | 保存期間を過ぎた会話は次にアプリを開いたときに削除されます。使用量の記録は13か月残ります。 |
| `walkChatUsageTitle` | 사용량 | Usage | 使用量 |
| `walkChatUsagePrevMonth` | 지난 달 | Previous month | 前の月 |
| `walkChatUsageNextMonth` | 다음 달 | Next month | 次の月 |
| `walkChatUsageQuestions` | 질문 | Questions | 質問 |
| `walkChatUsageInput` | 입력 토큰 | Input tokens | 入力トークン |
| `walkChatUsageOutput` | 출력 토큰 | Output tokens | 出力トークン |
| `walkChatUsageCacheRead` | 캐시 읽기 토큰 | Cached input tokens | キャッシュ読み取りトークン |
| `walkChatUsageByModel` | 모델별 | By model | モデル別 |
| `walkChatUsageWikiDistill` | 위키 정리 | Wiki summary | Wiki整理 |
| `walkChatUsageModelLine` | 질문 {questions} · 입력 {input} · 출력 {output} | {questions} questions · {input} in · {output} out | 質問 {questions} · 入力 {input} · 出力 {output} |
| `walkChatUsageEmpty` | 이 달에는 사용 기록이 없어요 | No usage this month | この月の使用記録はありません |
| `walkChatUsageCostNote` | 요금은 각 벤더 콘솔에서 확인하세요. 임시 대화도 숫자만 함께 세요. | Check charges in each provider's console. Temporary chats are counted too (numbers only). | 料金は各ベンダーのコンソールで確認してください。一時的な会話も数値のみ集計します。 |
| `walkChatUsageClear` | 사용량 기록 지우기 | Clear usage records | 使用量の記録を削除 |
| `walkChatUsageClearTitle` | 사용량 기록을 모두 지울까요? | Clear all usage records? | 使用量の記録をすべて削除しますか？ |
| `walkChatUsageClearBody` | 토큰 숫자 기록만 지워지고 대화는 남아요. | Only token counts are removed. Conversations stay. | トークン数の記録だけが削除され、会話は残ります。 |

`walkChatUsageModelLine` placeholder 셋은 `String`(이미 `NumberFormat` 으로 만든 글).

- [ ] **Step 1: 실패하는 테스트**
  - `chat_history_settings_cubit_test.dart`: `load 는 보관 기간과 대화 수` · `setRetention 은 저장하고 상태를 바꾼다` · `deleteAllConversations 뒤 수는 0`.
  - `chat_usage_cubit_test.dart`(`MutableClock` 2026-11-15): `처음은 2026-11` · `previousMonth 는 10월을 읽는다` · `2025-11 에서 더 뒤로 못 간다`(canGoBack false) · `이번 달에서 앞으로 못 간다` · `1월에서 previousMonth 는 지난해 12월` · `clear 는 deleteAll 뒤 다시 읽는다`.
  - `chat_history_settings_section_test.dart`: `보관 기간 행에 지금 값, 눌러 30일을 고르면 저장된다` · `대화 모두 지우기는 '대화 n개' 확인 뒤에만, 취소면 그대로` · `대화가 없으면 모두 지우기 행이 꺼진다` · `사용량 행을 누르면 사용량 화면`.
  - `chat_usage_page_test.dart`: `이번 달 합계 네 줄과 모델별 줄(1,234 처럼 자리 구분)` · `wikiDistill 줄은 '위키 정리'가 붙는다` · `‹ 를 누르면 지난 달 숫자` · `빈 달이면 빈 안내와 달 줄` · `금액 문구 없이 콘솔 안내 한 줄` · `사용량 기록 지우기는 확인 뒤에만`.
  - `open_settings_test.dart`: `물어보기 설정에 키 섹션 아래 대화 기록 섹션이 있다`(`settings` 의 기존 키 섹션 위젯 다음에 `chat-history-retention`) · `잠긴 채 열면 대화 기록 행이 없다`.
- [ ] **Step 2: 실행해 실패 확인** — `cd apps/walk && flutter test test/presentation/settings` → FAIL.
- [ ] **Step 3: 구현** — 위 Interfaces · 화면. build_runner.
- [ ] **Step 4: l10n** — 세 arb, `cd packages/l10n && flutter gen-l10n`.
- [ ] **Step 5: 통과 확인** — `cd apps/walk && flutter analyze && flutter test` → PASS.
- [ ] **Step 6: 커밋** — `feat(walk): 물어보기 설정에 대화 보관 기간 · 사용량 · 대화 모두 지우기`

### Task 9: 문서

스펙 "문서 갱신(구현 때)" 의 1단계 몫 + CLAUDE.md(진행 상태는 `status.md` 에만, 완료 시 history · testing 함께).

**Files:**
- Modify: `apps/walk/docs/status.md` · `apps/walk/docs/history.md` · `apps/walk/docs/testing.md` · `apps/walk/docs/plan.md`
- Modify: `docs/superpowers/specs/2026-10-27-walk-life-chat-design.md` — "빌더에게 맡기는 것"의 대화 저장 방식 · "이후(위키로 가는 길)"에 기록 기획 링크 한 줄씩
- Modify: `docs/superpowers/specs/2026-11-01-walk-chat-history-wiki.md` — 머리 상태를 "1단계 구현됨 · 2단계 기획"으로, §1 "이어서 대화하기"의 멈춘 턴 표시 문구를 `ChatSession.stoppedNote`('(사용자가 여기서 멈춤)')로 맞춤

- [ ] **Step 1: `status.md`** — 단계 요약 표 "물어보기" 행 범위에 "대화 기록 · 임시 대화 · 사용량(1단계)" 추가, "물어보기" 절에 체크 항목:
  - `[x]` `chat` DB(`conversations` · `chat_turns` · `chat_usage`) · 턴 끝 저장(멈춘 턴 포함) · 목록(열기 · 이름 바꾸기 · 삭제 · 모두 지우기)
  - `[x]` 이어가기(`resume`, 최근 20턴 · 사진 0부터 · 벤더/모델 변경 시 글로 접기) · 턴 지우기
  - `[x]` 임시 대화(배너 · `FLAG_SECURE` · 사용량 숫자만) · 보관 기간 자동 삭제 · 사용량 화면 · 물어보기 설정 행
  - `[ ]` 기기 QA H1~H6(H3 은 키 기획 ③ · ④ 뒤)
  - `[ ]` 2단계 위키
  - 검증 줄: `flutter analyze` 0 · `flutter test` N건 통과(실행해서 숫자를 적는다).
- [ ] **Step 2: `history.md`** — 새 절 `## 2026-11-xx — 물어보기 대화 기록 · 임시 대화 · 사용량`: 아래 "결정" 표(P1~P10, 이유 포함), 구현 중 바뀐 것, 막힌 것.
- [ ] **Step 3: `testing.md`** — "물어보기 — 채팅 · 기상 기록 보관" 표에 행 추가: `domain/chat/entity/conversation_test` · `data/chat/database/chat_database_test` · `drift_chat_history_repository_test` · `drift_chat_usage_log_test` · `data/chat/prefs_chat_history_settings_test` · `data/chat/channel_secure_window_test` · `domain/chat/usecase/chat_history_pruner_test` · `chat_session_test`(resume · 접기 · temporary) · `chat_cubit_test`(저장 · 열기 · 임시 · 턴 지우기) · `chat_history_cubit_test` · `chat_history_page_test` · `temporary_chat_banner_test` · `chat_tab_test`(⋮ · 배너 · 보안 창 · 시트) · `settings/…/chat_history_settings_*` · `chat_usage_*`. 맨 위 건수 갱신. "물어보기 기기 시나리오"에 H1~H6 을 "대기"로(위 기기 QA 목록 그대로).
- [ ] **Step 4: `plan.md`** — "범위 밖"의 "대화 저장 · 여러 대화" 삭제(일기 쓰기 도구 · 이미지 첨부는 남김), 물어보기 절의 "대화는 메모리에만 있고 저장하지 않는다" → 저장 규칙(보이는 글만 · 끝난 턴과 글이 온 멈춘 턴 · 실패 제외 · 임시 대화는 저장 안 함)으로, 사진 한도 문장에 "이어간 대화는 0부터", 화면 표에 대화 목록 · 사용량 행 추가. "규약"의 "나에 대한 메모 · LLM 위키는 아직 안 함" 문단은 **그대로**(2단계에서 바꿈).
- [ ] **Step 5: 링크 검사** — `cd apps/trader && flutter test test/convention` → PASS.
- [ ] **Step 6: 커밋** — `docs(walk): 물어보기 대화 기록 · 임시 대화 · 사용량 반영`

---

## 완료 조건 ↔ task

| 스펙 완료 조건(1단계) | 어디서 확인 |
|---|---|
| 끝난 답이 목록에 생기고 다시 켜도 남음, 실패는 저장 안 함 | Task 1 저장소 · Task 5 cubit 테스트, 재시작은 H1 |
| 멈춘 답 '멈춤' 저장 · 복원 · 다음 문맥, 글 없이 멈추면 안 남음 | Task 4 · 5 테스트, 모델 쪽은 H2 |
| 지난 대화 열면 말풍선 · 근거 칩 복원, 이어 물으면 앞 대화를 안다 | Task 5 · 7 테스트 + H1 |
| 모델 · 벤더를 바꿔도 이어 물음 | Task 4 테스트 + H3 |
| 이어간 대화의 사진 한도 0부터 | Task 4 테스트 + H6 |
| 삭제 · 모두 지우기(목록 · 물어보기 설정)는 확인 뒤에만 | Task 6 · 7 · 8 테스트 |
| ⋮ 에 [대화 목록] · [임시 대화로 시작]이 끝 두 항목 위, 잠긴 동안 "앱 설정"만 | Task 7 테스트 |
| 물어보기 설정의 대화 행 · 사용량 화면은 잠금이 풀려야 보임 | Task 8 `open_settings_test` |
| 임시 대화는 아무것도 안 남기고 배너가 보임 | Task 5 · 7 테스트 |
| 임시 대화가 보이는 동안 캡처 차단, 다른 탭 · 일반 대화에선 풀림 | Task 7 테스트(채널 호출) + H4 |
| 보관 30일이면 31일 지난 대화가 다음 시작 때 사라짐 | Task 3 테스트 + H5 |
| 목록 · 지난 대화는 잠금 아래에서만 | Task 6 · 7 테스트 |
| 요청마다 `chat_usage` 한 행(임시는 숫자만), 사용량 화면에 이번 달 합계 · 모델별 | Task 2 · 4 · 8 테스트 |

## 결정

이 계획을 쓰며 정한 것(스펙끼리 어긋나거나 스펙이 비워 둔 곳). Task 9 가 `history.md` 로 옮긴다.

| # | 결정 | 이유 |
|---|---|---|
| P1 | 멈춘 턴 문맥 표시는 core 의 `ChatSession.stoppedNote = '(사용자가 여기서 멈춤)'` 를 그대로 쓴다(스펙 §1 의 "(사용자가 답을 중간에 멈춤)" 대신) | core 계획 P3 가 이미 한 상수로 맞췄다. 지금 대화의 멈춤과 지난 대화 복원이 같은 글이어야 접기 · resume 결과가 같다 |
| P2 | 벤더 · 모델이 바뀌면 **세션이** 메모리 문맥을 글로 접는다(`_contextTarget` 비교, `ask` 시작 때). 스펙의 "cubit 이 말풍선 · 저장 턴으로 다시 채우기"를 대신한다 | 일반 · 임시 대화가 한 경로, 결과는 같은 글만의 문맥. cubit 이 언제 벤더가 바뀌었는지 알 필요가 없고 세션 단위 테스트로 고정된다 |
| P3 | 지금 벤더 · 모델은 세션의 `ChatTarget get target`(지금은 `(_model.vendor, interimModel)`) 하나로 읽는다 | core 에 "지금 모델" 접근자가 없다. 키 기획 ② · ③ 이 이 getter 만 바꾸면 턴 기록 · 사용량 · 접기가 따라온다 |
| P4 | 배너 벤더 이름은 `chatVendorLabel` + l10n 키 `walkChatVendorAnthropic` · `walkChatVendorOpenai`. ② 에 같은 것이 있으면 그것을 쓴다 | 키 UX(②)에 기대지 않는다는 전제. 고유명이라 세 언어 값이 같다 |
| P5 | `DriftChatUsageLog`(쓰기) 와 `DriftChatUsageRepository`(읽기 · 지우기)를 한 파일의 두 클래스로 나눈다(스펙은 한 클래스) | injectable 이 한 인스턴스를 두 인터페이스로 등록하는 우회가 필요 없다. 둘 다 상태 없이 같은 DB 를 쓴다 |
| P6 | `chat_usage` 에 `fast_mode` 열을 더한다 | core `ChatUsageRecord.fastMode` 가 있다 — 기록을 버리지 않는다 |
| P7 | 열린 대화가 밖에서 지워진 것은 cubit 이 `watchExists` 로 알아채 빈 새 대화가 된다. 정리는 `OpenConversation`(싱글턴 id 하나)으로 열린 대화를 건너뛴다 | 목록 · 물어보기 설정 · 보관 정리 세 곳의 삭제를 셸 · 라우트 반환값 없이 한 규칙으로 처리 |
| P8 | 대화 모두 지우기 확인 문구는 1단계에서 "사용량 기록은 남아요"(스펙의 "위키는 남습니다"는 2단계에서 더함) | 1단계엔 위키가 없어 그 문장이 오해를 부른다 |
| P9 | 답 글이 빈 끝난 턴은 저장 · resume 하지 않는다. 저장 실패는 조용히 넘긴다(화면엔 남고 다음 턴이 다시 시도) | 빈 assistant text 블록은 벤더가 거절한다. 저장 실패 안내는 스펙에 없고, 답 흐름을 막지 않는 쪽(core P10 과 같은 태도) |
| P10 | 사용량 보관 13개월 = 이번 달 + 지난 12개월(`DateTime(now.year, now.month - 12)` 이전 삭제), 사용량 화면도 그 범위만 넘긴다. 자동 제목 다시 쓰기는 "첫 턴을 지웠고 이름을 안 바꿨을 때"만, 이름 바꾸기 · 턴 지우기는 `updatedAt` 을 바꾸지 않는다 | 스펙의 "지난해 같은 달까지 비교" · "title_edited 면 자동 제목으로 덮지 않음"을 구체화. 목록 순서 · 보관 기준은 대화가 실제로 이어진 때 |
