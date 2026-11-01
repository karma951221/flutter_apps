# walk 물어보기 — 위키(대화 기록 · 위키 기획 2단계) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 사용자가 고른 사실만 "위키 메모"(제목 · 한 줄 요약 · 본문, `[[id]]` · `[[일기:<entryId>]]` 링크)로 `chat` DB 에 남기고, 다음 질문마다 시스템 프롬프트에 색인(제목 + 요약)만 싣고 본문은 모델이 `read_wiki` 로 필요할 때 연다. 위키는 [위키로 정리] (정리 요청 한 번 → 후보 최대 8개를 저장 / 고쳐서 저장 / 버림) · 말풍선 [위키에 추가] · 위키 화면 [추가] 세 경로로만 생기고, 위키 화면(목록 · 보기 · 편집 · 링크 넣기 · 역링크 · 흐린 링크 · 모두 지우기), 색인 크기 설정, 사용량 화면의 위키 숫자를 더한다. 임시 대화에는 위키가 한 글자도 나가지 않는다.

**Architecture:** `ChatDatabase` 를 schemaVersion 2 로 올려 `wiki_notes` 를 더하고(`source_conversation_id` 는 FK `on delete set null`), domain `WikiRepository` 뒤에 `DriftWikiRepository` 를 둔다. 색인 만들기는 순수 함수 `buildWikiIndex(notes, size)` 하나를 정책(`IndexAndReadPolicy`)과 위키 화면이 같이 쓴다. `ChatSession` 은 질문마다 `WikiContextPolicy.build` 를 불러(임시 대화면 `NoWikiPolicy`) 시스템 프롬프트를 "규약 → 위키 색인 → 오늘 날짜" 순으로 만들고, `read_wiki` 호출은 `WikiTools` 로, 나머지는 `LifeTools` 로 보낸다. 사용량 행에 색인 크기 · `read_wiki` 수를 채운다. [위키로 정리]는 세션과 따로 도는 유스케이스 `WikiDistiller`(일기 도구 없이 `read_wiki` 만, purpose `wikiDistill`)가 맡고, 결과 후보는 화면이 거른 뒤 `WikiCandidatesSheet` 에서 하나씩 처리한다.

**Tech Stack:** Flutter · drift 2.34(`drift_dev schema dump/generate`, `SchemaVerifier`, `NativeDatabase.memory()`) · flutter_bloc · Freezed 3 · injectable/get_it · shared_preferences · gen-l10n(`packages/l10n`, 기준 `app_ko.arb`) · intl.

**Spec:** [대화 기록 · 위키 기획](../specs/2026-11-01-walk-chat-history-wiki.md) **§8 2단계 전체**와 그 완료 조건 — 관련 절: 결정 D5~D8 · D9(위키 몫) · D11~D15, §1 "저장소"의 `wiki_notes`, §2 진입점 2 · 3 · [위키에 추가], §3 전부, §4 위키 행, §5, §6 의 2단계 행, §7 의 위키 파일 · 테스트.

**선행(이 계획을 실행할 때 끝나 있다고 본다 — 코드가 아직 없을 수 있으니 각 task 시작 때 `grep` 으로 실제 이름을 맞춘다. 다르면 실제 이름을 따르고 이 계획의 해당 줄을 고친다, 인터페이스 모양은 그대로):**
- [대화 기록 · 임시 대화 · 사용량 계획](2026-11-01-walk-chat-history.md)(1단계) 전체 — `ChatDatabase`(schemaVersion 1, `onUpgrade` 의 `if (from < 2)` 자리, `PRAGMA foreign_keys = ON`, `drift_schemas/chat/drift_schema_v1.json`), `Conversations` · `ChatTurns` · `ChatUsageRows`, `ChatHistoryRepository`(`turns` · `watchExists` · `delete*`), `ChatTurnRecord`(`citedEntryIds` · `stopped`) · `ChatTurnText` · `conversationTitleFrom`, `ChatUsageRepository.month` · `ChatUsageMonth` · `DriftChatUsageRepository`, `ChatHistorySettings`(`retention`) · `PrefsChatHistorySettings`, `ChatSession.resume` · `reset({temporary})` · `temporary` · `target`(`ChatTarget`) · `resumeTurns = 20`, `ChatState.conversationId` · `temporary` · `vendor` · `ChatBubble.seq`, `ChatTab` 의 `FeatureMenu(entries: …)` · `showBubbleActions` · `BubbleAction { deleteTurn }`, `ChatHistorySettingsSection` · `ChatHistorySettingsCubit`, `ChatUsagePage` · `ChatUsageCubit`, `chatVendorLabel`.
- [중립 계약 · 계측 · 멈춤 계획](2026-11-01-walk-chat-core.md) 전체 — `ChatMessage` · `AssistantPart`(`TextPart` · `ToolCallPart`) · `ToolResultPart` · `ToolSpec` · `ModelEvent`(`ModelCompleted.message/stop/usage`) · `ModelRequest` · `ChatModel.vendor/stream`, `StopKind`, `ChatUsageLog` · `ChatUsageRecord`(`questionKey` · `temporary` · `wikiIndexNotes` · `wikiIndexChars` · `readWikiCalls`) · `ChatUsagePurpose { chat, wikiDistill }`, `LifeTools.definitions: List<ToolSpec>`, `ChatSession.maxRounds = 8` · `stoppedNote`, `ChatTrace`.
- [키 UX 계획](2026-11-01-walk-chat-key-ux.md)(키 기획 ②) — `ChatSettings.apiKey()`(원문 키 읽기 허용처 목록), `walkChatVendorAnthropic` 등 벤더 이름 키. 이 계획은 ② 가 없어도 돌게 쓰되, 있으면 W4(아래 결정)를 따른다.
- 범위 밖: `search_wiki`, 위키 미리 골라 붙이기 · 모델 라우팅(스펙 "후속 후보"), 태그 · 내보내기, 프롬프트 캐시(체감 속도 기획), 답하는 중 자동 위키 제안(D6 — 하지 않음).

## Global Constraints

- 경로는 `apps/walk/` 기준. 테스트는 `test/` 아래 같은 구조(`lib/domain/chat/wiki/x.dart` ↔ `test/domain/chat/wiki/x_test.dart`, `lib/presentation/chat/wiki/…` ↔ `test/presentation/chat/wiki/…`).
- Freezed(CLAUDE.md): 단일 모델은 Freezed 3 primary constructor(`@freezed class X with _$X { @override final …; const X({…}); }`), 변형은 `sealed class` + named factory(`WikiCandidate` · `WikiLink` · `WikiDistillResult`). 분기는 `switch` 패턴 매칭(`when`/`map` 금지).
- 생성 파일(`.g.dart` · `.freezed.dart` · `injection.config.dart`)은 손으로 고치지 않는다 — `cd apps/walk && dart run build_runner build --delete-conflicting-outputs`. drift 스키마 덤프 · 마이그레이션 테스트 도우미는 `dart run drift_dev schema …` 로만 만든다.
- **저장소 전체 포맷 금지.** `dart format` 은 그 task 가 만든 · 고친 파일에만. `build_runner` 는 `apps/walk` 안에서만(다른 앱 · 패키지에서 돌리지 않는다).
- UI 규칙(CLAUDE.md): `AppListTile` · `AppOverflowMenu` · `AppPlaceholder` · `AppConfirmDialog.show` · `AppSnackBar.show` · `AppButton` 우선. `Colors.*` · 숫자 여백 · `BorderRadius.circular(n)` 금지 — `AppSpacing` · `AppRadius` · `Theme.of(context)`. 되돌릴 수 없는 삭제(메모 삭제 · 위키 모두 지우기)는 `AppConfirmDialog.show(..., isDestructive: true)` 뒤에만.
- 문구는 l10n 만. 새 키는 `app_ko.arb` · `app_en.arb` · `app_ja.arb` 셋 다(ko 에 `@키` description, "위키: …"로 시작), 그 뒤 `cd packages/l10n && flutter gen-l10n`. `commonCancel` · `commonSave` · `commonDelete` 재사용.
- **위키 제목 · 요약 · 본문, 질문 · 답 글은 로그 · 예외 · 계측 · `toString` 에 남기지 않는다**(core · 기록 계획 규칙). `WikiNote` · `WikiNoteDraft` · `WikiCandidate` · `WikiContext` 는 `toString` 을 override 해 id · 길이만 — 엔티티 테스트에 "toString 에 글 없음".
- **임시 대화에는 위키가 나가지 않는다** — 세 곳(세션이 `NoWikiPolicy` 를 고름 · 화면이 [위키로 정리] · [위키에 추가] 숨김 · 테스트가 요청 본문 확인)에서 지킨다.
- 위키 화면 · 편집 · 고르기 시트 · 색인 크기 시트는 모두 잠금 아래(`pushDiaryRoute`, 시트는 잠기면 닫힘).
- 날짜는 `Clock.now()` 의 로컬 `DateTime`(`storeDateTimeAsText: true`). 테스트는 `MutableClock`.
- 공유 파일은 한 줄씩만 고친다: `chat_session.dart`(Task 3) · `chat_tab.dart`(Task 6 · 7) · `chat_history_settings_section.dart`(Task 8) · `chat_usage_page.dart`(Task 8). `ChatSettingsSection` · 셸 · `FeatureMenu` 는 고치지 않는다.
- 매 task 끝: `cd apps/walk && flutter analyze && flutter test` 0 오류 · 전체 통과. 커밋은 task 마다 하나(`feat(walk): …`, 문서는 `docs(walk): …`).

## Review Focus

1. **임시 대화 요청에 위키가 없다(Task 3)** — `reset(temporary: true)` · `resume(…, temporary: true)` 뒤 요청의 `system` 에 `<wiki_index>` 가 없고 `tools` 에 `read_wiki` 가 없으며, 정책의 `build` 가 **불리지도 않는다**. 사용량 행의 위키 숫자는 0.
2. **시스템 프롬프트 배치(Task 3)** — 규약 → 위키 절 → 오늘 날짜가 **맨 뒤**. 위키가 비면 위키 절 · `read_wiki` 둘 다 없다. 정책이 던지면 위키 없이 답한다(질문을 실패시키지 않음).
3. **색인 상한(Task 2)** — 최근 수정 순, 개수 · 글자 수 둘 다 지킴, 넘치면 오래된 쪽부터 빠지고 "(오래된 메모 n개 생략)". 들어갈 자리가 남아도 더 오래된 짧은 메모로 건너뛰지 않는다(순서가 곧 우선순위). 설정을 바꾸면 다음 `build` 부터 반영.
4. **모델이 지어낸 링크 거르기(Task 4)** — 후보 본문의 `[[일기:id]]` 중 이 대화의 근거 id 가 아닌 것, 없는 `[[id]]` 는 빠진다. update 후보의 id 가 없는 메모면 new 로 바뀐다. 8개 상한.
5. **원문 키 읽기(Task 4)** — `WikiDistiller` 가 세 번째 `apiKey()` 호출처다(W4). 화면 · cubit 은 여전히 읽지 않는다.
6. **지워진 대상(Task 1 · 5)** — 메모 · 대화 · 일기가 지워져도 본문 글은 그대로이고, 화면은 흐린 칩, `read_wiki` 는 `not_found` / `missing`. 대화가 지워지면 `source_conversation_id` 만 null(FK set null — `foreign_keys` 가 켜져 있어야 한다).
7. **migration 1 → 2(Task 1)** — v1 DB 의 대화 · 턴 · 사용량이 그대로 남고 `wiki_notes` 가 생긴다(`SchemaVerifier`).
8. **잠금(Task 5 · 6 · 7)** — 위키 화면 · 편집 · 후보 시트는 잠금 아래. 후보 시트는 모달이라 게이트 밖이므로 **잠기면 스스로 닫힌다**(남은 후보는 버림).

## 기기 QA 목록(이 계획의 task 를 막지 않는다)

Task 9 가 walk `testing.md` "물어보기 기기 시나리오"에 "대기"로 옮긴다. 판정은 사용량 화면의 위키 숫자 · 디버그 빌드 `ChatTrace` 로 한다.

| # | 확인 | 스펙 완료 조건 |
|---|---|---|
| W-QA1 | 실제 키로 "출근 알람은 '출근' 라벨이야"가 든 대화 → [위키로 정리] → 후보 저장 → [새 대화] → "출근 알람 몇 시에 울렸어?" 에 라벨 설명 없이 답한다. `read_wiki` 를 불렀는지 사용량 · 계측으로 확인 | 저장한 위키를 다음 대화에서 모델이 쓴다 |
| W-QA2 | "안녕" · "고마워" 같은 일상 질문 5번 — 사용량 화면 "read_wiki 를 부른 질문" 비율이 오르지 않는다 | 일상 질문엔 `read_wiki` 를 부르지 않는다 |
| W-QA3 | 링크가 있는 메모 둘([[a]] → [[b]], b 에 `[[일기:…]]`)을 두고 b 내용을 묻는다 — 모델이 a → b 를 열고, 일기 날짜로 `search_diary` 를 부른다(계측의 도구 순서) | 링크를 따라 열고 일기 날짜로 원본을 찾는다 |
| W-QA4 | [위키로 정리] 후보가 8개 이하이고, 근거 일기가 있는 대화면 후보 본문에 `[[일기:…]]` 칩이 붙어 나온다 | 후보 8개 · 근거 일기 링크 |
| W-QA5 | thinking 이 켜진 모델에서 [위키로 정리] 요청이 400 없이 끝나고 JSON 이 파싱된다(코드 펜스로 감싸 와도) | 정리 요청 동작 |
| W-QA6 | 메모 200개(디버그 시드) · 기본 크기에서 질문 1번의 입력 토큰이 위키 0개 때보다 대략 색인 글자 수만큼만 는다 | 색인 상한 체감 |

---

### Task 1: 위키 엔티티 · 링크 파서 · `wiki_notes`(migration 2) · `DriftWikiRepository`

**Files:**
- Create: `lib/domain/chat/entity/wiki_note.dart` — `WikiNote` · `WikiNoteDraft` · `WikiCandidate` · `WikiLink` · `WikiSegment` · 파서 · 상한 상수
- Create: `lib/domain/chat/repository/wiki_repository.dart`
- Modify: `lib/data/chat/database/chat_tables.dart` — `WikiNotes`
- Modify: `lib/data/chat/database/chat_database.dart` — `tables: [..., WikiNotes]`, `schemaVersion => 2`, `onUpgrade` 의 `if (from < 2) await m.createTable(wikiNotes);`
- Create: `lib/data/chat/database/drift_wiki_repository.dart`
- Create: `drift_schemas/chat/drift_schema_v2.json` — `cd apps/walk && dart run drift_dev schema dump lib/data/chat/database/chat_database.dart drift_schemas/chat/`
- Create: `test/data/chat/database/generated/` — `cd apps/walk && dart run drift_dev schema generate drift_schemas/chat/ test/data/chat/database/generated/`(v1 · v2 도우미, 손으로 고치지 않음)
- Modify: `test/data/chat/database/chat_database_test.dart` — `schemaVersion 은 1` → `2`
- Test: `test/domain/chat/entity/wiki_note_test.dart` · `test/data/chat/database/chat_database_migration_test.dart` · `test/data/chat/database/drift_wiki_repository_test.dart`

**Interfaces:**
- Produces (`wiki_note.dart`):
  ```dart
  /// 위키 메모 하나(D5). id 는 모델에게 보이는 짧은 정수 — [[12]].
  @freezed
  class WikiNote with _$WikiNote {
    // id(int) · title · summary · body · sourceConversationId(String?) · createdAt · updatedAt
  }

  /// 저장소에 넘기는 새 내용 / 고친 내용. 저장소가 trim · 한 줄 요약 · 상한 자르기를 한다.
  @freezed
  class WikiNoteDraft with _$WikiNoteDraft {
    // title · summary · body · sourceConversationId(String?)
  }

  /// [위키로 정리] 후보(D6).
  @freezed
  sealed class WikiCandidate with _$WikiCandidate {
    const factory WikiCandidate.create({required String title, required String summary, required String body}) = WikiCreateCandidate;
    const factory WikiCandidate.update({required int id, required String title, required String summary, required String body}) = WikiUpdateCandidate;
  }

  @freezed
  sealed class WikiLink with _$WikiLink {
    const factory WikiLink.note(int id) = WikiNoteLink;          // [[12]]
    const factory WikiLink.diary(String entryId) = WikiDiaryLink; // [[일기:<entryId>]]
  }

  /// 본문을 글 조각과 링크 조각으로 나눈 것. 화면(링크 칩)이 쓴다.
  @freezed
  sealed class WikiSegment with _$WikiSegment {
    const factory WikiSegment.text(String text) = WikiTextSegment;
    const factory WikiSegment.link(WikiLink link, String raw) = WikiLinkSegment;
  }

  const wikiTitleMax = 60;
  const wikiSummaryMax = 120;
  const wikiBodyMax = 4000;

  /// `[[숫자]]` · `[[일기:id]]`(id 는 공백 · `]` 없는 글자). 그 밖의 `[[…]]` 는 글로 둔다.
  List<WikiSegment> parseWikiBody(String body);
  /// 본문의 링크(나온 순서, 중복 제거).
  List<WikiLink> wikiLinksIn(String body);
  /// [keep] 이 false 인 링크 조각을 본문에서 지운다(앞뒤 공백 하나로 정리). Task 4 의 거르기.
  String stripWikiLinks(String body, bool Function(WikiLink link) keep);
  /// 링크 넣기 시트가 쓰는 문자열.
  String wikiNoteLinkText(int id);            // '[[12]]'
  String wikiDiaryLinkText(String entryId);   // '[[일기:abc]]'
  ```
  `WikiNote` · `WikiNoteDraft` · `WikiCandidate` 는 `toString` override — `WikiNote(id: 3, titleLength: 5, bodyLength: 80)` 모양.
- Produces (`wiki_repository.dart`):
  ```dart
  abstract interface class WikiRepository {
    /// updatedAt 최근 순(같으면 id 큰 순). 바뀔 때마다 다시 낸다.
    Stream<List<WikiNote>> notes();
    /// 한 번 읽기 — 색인 · 정리 요청용. notes() 와 같은 순서.
    Future<List<WikiNote>> all();
    Stream<WikiNote?> watchNote(int id);
    /// 있는 것만, [ids] 순서 유지.
    Future<List<WikiNote>> byIds(List<int> ids);
    Future<int> count();
    /// 새 id. createdAt = updatedAt = now.
    Future<int> create(WikiNoteDraft draft);
    /// updatedAt = now. sourceConversationId 는 draft 가 null 이면 기존 값을 둔다. 없는 id 면 StateError.
    Future<void> update(int id, WikiNoteDraft draft);
    Future<void> delete(int id);
    /// 지운 수. 대화 · 사용량은 지우지 않는다.
    Future<int> deleteAll();
    /// 본문에 [[id]] 가 든 메모(자기 자신 제외), updatedAt 최근 순.
    Future<List<WikiNote>> backlinks(int id);
  }
  ```
- Produces (테이블 `WikiNotes`, 스펙 §1 그대로): `id` autoIncrement · `title` · `summary` · `body` · `sourceConversationId` text nullable `references(Conversations, #id, onDelete: KeyAction.setNull)` · `createdAt` · `updatedAt`. 인덱스 `updatedAt`.
- 저장 정리(`create` · `update` 공통): title · summary 는 trim, summary 의 줄바꿈 · 연속 공백 → 공백 하나, 각자 상한에서 grapheme 단위로 자름. body 는 trim 만, `wikiBodyMax` 에서 자름. title 이나 summary 가 비면 `ArgumentError`(화면이 먼저 막는다).
- `backlinks` 는 `body LIKE '%[[<id>]]%'` 로 좁힌 뒤 `wikiLinksIn` 으로 다시 확인.
- Consumes: 1단계 `ChatDatabase` · `Conversations` · `ChatHistoryRepository`, `Clock`.

- [ ] **Step 1: 실패하는 테스트**
  - `wiki_note_test.dart`: `[[12]] 와 [[일기:a1-b2]] 를 링크로, 나머지는 글로 나눈다` · `[[abc]] · [[일기:]] · [[ 3 ]] 는 글로 둔다` · `wikiLinksIn 은 순서대로 중복 없이` · `stripWikiLinks 는 keep 이 false 인 링크만 지우고 공백을 정리한다` · `wikiNoteLinkText · wikiDiaryLinkText 를 parseWikiBody 가 되읽는다`(왕복) · `toString 에 제목 · 요약 · 본문이 없다`(세 클래스).
  - `chat_database_migration_test.dart`(`SchemaVerifier(GeneratedHelper())`): `v1 → v2 가 스키마 v2 와 같다`(`validateDatabaseSchema`) · `v1 의 대화 · 턴 · 사용량 행이 v2 에 그대로 남는다`(v1 도우미 DB 에 한 행씩 넣고 `migrateAndValidate` 뒤 읽기).
  - `drift_wiki_repository_test.dart`(메모리 DB · `MutableClock`):
    - `create 는 1부터 id 를 주고 notes 는 updatedAt 최근 순`.
    - `update 는 updatedAt 만 바꾸고 순서가 맨 앞으로` · `update 의 source 가 null 이면 기존 출처를 둔다` · `없는 id 를 update 하면 StateError`.
    - `요약의 줄바꿈은 공백 하나, 제목 · 요약 · 본문은 상한에서 자른다` · `빈 제목 · 요약은 ArgumentError`.
    - `대화를 지우면 그 대화를 출처로 둔 메모의 sourceConversationId 만 null`(1단계 `ChatHistoryRepository.delete` · `deleteOlderThan` 둘 다).
    - `deleteAll 은 메모만 지우고 대화 · chat_usage 는 남긴다` · `지운 수를 돌려준다`.
    - `backlinks 는 [[3]] 을 가진 메모만 — [[33]] · [[일기:3]] · 자기 자신은 아니다`.
    - `byIds 는 있는 것만 순서대로` · `watchNote 는 지우면 null`.
- [ ] **Step 2: 실행해 실패 확인** — `cd apps/walk && flutter test test/domain/chat/entity/wiki_note_test.dart test/data/chat/database` → FAIL.
- [ ] **Step 3: 구현** — 위 Interfaces. build_runner → 스키마 덤프(v2) → `schema generate`(Files 의 두 명령).
- [ ] **Step 4: 통과 확인** — `cd apps/walk && flutter analyze && flutter test` → PASS.
- [ ] **Step 5: 커밋** — `feat(walk): 위키 메모 테이블(chat DB v2)과 링크 파서 · 위키 저장소`

### Task 2: 색인 크기 설정 · `buildWikiIndex` · `WikiContextPolicy` · `read_wiki`

**Files:**
- Modify: `lib/domain/chat/chat_history_settings.dart` — `WikiIndexSize` · `wikiIndexSize` · `setWikiIndexSize`
- Modify: `lib/data/chat/prefs_chat_history_settings.dart`
- Create: `lib/domain/chat/wiki/wiki_index.dart` — `WikiIndex` · `buildWikiIndex`
- Create: `lib/domain/chat/wiki/wiki_context_policy.dart` — `WikiContext` · `WikiContextPolicy` · `IndexAndReadPolicy` · `NoWikiPolicy`
- Create: `lib/domain/chat/tool/wiki_tools.dart` — `WikiTools`
- Test: `test/data/chat/prefs_chat_history_settings_test.dart`(더함) · `test/domain/chat/wiki/wiki_index_test.dart` · `test/domain/chat/wiki/wiki_context_policy_test.dart` · `test/domain/chat/tool/wiki_tools_test.dart`

**Interfaces:**
- Produces (`chat_history_settings.dart` 에 더함):
  ```dart
  /// 위키 색인 상한(D14). maxNotes 가 null 이면 개수 제한 없음.
  enum WikiIndexSize {
    small(50, 2000), standard(150, 6000), large(300, 12000), all(null, 30000);
    const WikiIndexSize(this.maxNotes, this.maxChars);
    final int? maxNotes; final int maxChars;
    static const fallback = WikiIndexSize.standard;
  }
  // ChatHistorySettings 에 더함
  WikiIndexSize get wikiIndexSize;
  Future<void> setWikiIndexSize(WikiIndexSize value);
  ```
  prefs 키 `walk.chat.wikiIndexSize`, enum 이름 문자열, 모르는 값이면 `fallback`(retention 과 같은 패턴).
- Produces (`wiki_index.dart`):
  ```dart
  @freezed
  class WikiIndex with _$WikiIndex {
    // lines(String — <wiki_index> 안쪽, 생략 줄 포함) · includedIds(List<int>) · omitted(int) · chars(int = lines.length)
  }
  /// [notes] 는 updatedAt 최근 순. 한 줄 = '[[id]] 제목 — 요약'. 앞에서부터 개수 < maxNotes 이고
  /// (지금 글자 + 줄 + 줄바꿈) <= maxChars 인 동안 넣고, 처음 안 맞는 메모에서 멈춘다(뒤의 짧은 메모로 건너뛰지 않음).
  /// omitted > 0 이면 끝 줄 '(오래된 메모 n개 생략)'(이 줄은 상한 계산 밖).
  WikiIndex buildWikiIndex(List<WikiNote> notes, WikiIndexSize size);
  ```
- Produces (`wiki_context_policy.dart`):
  ```dart
  /// 이번 질문에 붙일 위키. system 이 null 이면 위키 절 없음.
  @freezed
  class WikiContext with _$WikiContext {
    // systemSection(String?) · tools(List<ToolSpec>) · indexNotes(int) · indexChars(int)
    static const none = WikiContext(systemSection: null, tools: [], indexNotes: 0, indexChars: 0);
  }

  abstract interface class WikiContextPolicy {
    /// 이번 질문에 붙일 시스템 프롬프트 조각과 도구 정의(D8). question 은 후속 "미리 골라 붙이기" 자리.
    Future<WikiContext> build({required String question});
  }

  /// 기본: 색인만 시스템 프롬프트에, 본문은 read_wiki 로(D7). 메모가 0 개면 WikiContext.none.
  @LazySingleton(as: WikiContextPolicy)
  class IndexAndReadPolicy implements WikiContextPolicy {
    IndexAndReadPolicy(this._wiki, this._settings);   // WikiRepository · ChatHistorySettings
  }

  /// 임시 대화 · 위키 없음.
  class NoWikiPolicy implements WikiContextPolicy { const NoWikiPolicy(); }
  ```
  `systemSection`(스펙 §3 그대로):
  ```
  사용자가 정리해 둔 위키가 있다. 아래는 색인(id · 제목 · 한 줄 요약)이다.
  질문에 도움이 될 때만 read_wiki 로 본문을 열고, 본문의 [[id]] 링크를 따라 더 열 수 있다.
  본문의 [[일기:<id>]] 는 일기 기록이다 — read_wiki 가 날짜를 주니 원본이 필요하면 그 날짜로 search_diary 를 부른다.
  위키와 기록 도구로 찾은 내용이 다르면 기록을 우선하고 다르다고 말한다.
  <wiki_index>
  …buildWikiIndex 의 lines…
  </wiki_index>
  ```
  `indexNotes = includedIds.length`, `indexChars = index.chars`. `tools = [WikiTools.spec]`.
- Produces (`wiki_tools.dart`):
  ```dart
  @lazySingleton
  class WikiTools {
    WikiTools(this._wiki, this._diary);   // WikiRepository · DiaryRepository
    static const readWikiName = 'read_wiki';
    static const maxIdsPerCall = 5;
    /// name read_wiki, parameters {type: object, properties: {ids: {type: array, items: {type: integer}, description}}, required: [ids]}.
    static const ToolSpec spec;
    /// input['ids'] — 정수 · 숫자 문자열 · "3,7" 문자열을 받아 앞 5개만. 결과는 entryIds 없음(인용 칩 아님).
    Future<ToolResult> readWiki(Map<String, Object?> input);
  }
  ```
  결과 JSON: `{"notes": [ {id, title, summary, body, links: [{id, title} | {id, missing: true}], diary: [{entry_id, date: 'yyyy-MM-dd'} | {entry_id, missing: true}], updated: 'yyyy-MM-dd'} | {id, error: "not_found"} ], "skipped": [6번째 이후 id]}`(`skipped` 는 있을 때만). ids 가 비거나 모양이 틀리면 `isError: true`, `{"error":"invalid_ids"}`. 일기 날짜는 `DiaryRepository.entry(id)` 가 `Ok` 이고 `!isTrashed` 일 때만, 아니면 `missing`.
- Consumes: Task 1 `WikiRepository` · `wikiLinksIn`, 1단계 `ChatHistorySettings`, core `ToolSpec` · 기존 `ToolResult` · `DiaryRepository`.

- [ ] **Step 1: 실패하는 테스트**
  - `prefs_chat_history_settings_test.dart`: `색인 크기는 처음엔 standard` · `저장한 값을 읽는다` · `모르는 값이면 standard`.
  - `wiki_index_test.dart`: `한 줄은 [[id]] 제목 — 요약, 최근 순` · `standard 는 150개에서 멈추고 '(오래된 메모 n개 생략)'` · `글자 상한(6,000)에 먼저 닿으면 거기서 멈춘다` · `small · large · all 의 개수 · 글자 상한`(all 은 1,000개여도 개수 제한 없이 30,000자에서) · `안 맞는 메모 뒤의 짧은 메모로 건너뛰지 않는다` · `생략이 없으면 생략 줄도 없다` · `빈 목록은 빈 lines · omitted 0`.
  - `wiki_context_policy_test.dart`(가짜 저장소 · 설정): `메모가 없으면 none(위키 절 · 도구 없음)` · `있으면 절에 <wiki_index> 와 read_wiki 안내, tools 는 read_wiki 하나` · `indexNotes · indexChars 가 buildWikiIndex 와 같다` · `설정을 small 로 바꾸면 다음 build 부터 50개` · `NoWikiPolicy 는 저장소를 읽지 않고 none`.
  - `wiki_tools_test.dart`: `ids 의 메모를 id · 제목 · 요약 · 본문 · updated 와 함께 준다` · `없는 id 는 {id, error: not_found}` · `6개를 주면 앞 5개만 읽고 skipped 에 나머지` · `"3,7" · ["3"] 도 받는다` · `빈 ids · 숫자 아님은 isError invalid_ids` · `본문 링크 — 있는 메모는 {id, title}, 지워진 메모는 {id, missing: true}` · `일기 링크 — 있으면 날짜, 휴지통 · 없음이면 missing` · `entryIds 는 비어 있다` · `spec 이름은 read_wiki, ids 는 integer 배열이고 required`.
- [ ] **Step 2: 실행해 실패 확인** — `cd apps/walk && flutter test test/data/chat test/domain/chat/wiki test/domain/chat/tool/wiki_tools_test.dart` → FAIL.
- [ ] **Step 3: 구현** — 위 Interfaces. `chat_model.dart` 의 `ToolSpec` doc("공통 부분집합: object · string · integer · enum · required")에 `array(items 하나)` 를 더한다(W3). build_runner.
- [ ] **Step 4: 통과 확인** — `cd apps/walk && flutter analyze && flutter test` → PASS.
- [ ] **Step 5: 커밋** — `feat(walk): 위키 색인 크기 설정 · 색인 정책 · read_wiki 도구`

### Task 3: 세션 — 질문마다 위키 정책 · 프롬프트 배치 · `read_wiki` 실행 · 사용량 위키 숫자

**Files:**
- Modify: `lib/domain/chat/usecase/chat_session.dart`
- Modify: `test/support/` 의 세션 생성 도우미(있으면) — 가짜 정책 · `WikiTools` 인자 더하기
- Test: `test/domain/chat/usecase/chat_session_test.dart`

**Interfaces:**
- Produces:
  ```dart
  // 생성자 끝에 둘을 더한다(1단계 · core 가 더한 인자 순서는 그대로).
  ChatSession(…, this._wiki, this._wikiTools);
  final WikiContextPolicy _wiki;
  final WikiTools _wikiTools;
  ```
- 규칙:
  - `_run` 에서 키 확인 뒤 한 번: `final wiki = _temporary ? WikiContext.none : await _safeBuild(question);` — `_safeBuild` 는 정책이 던지면 `WikiContext.none`(질문은 계속). `stale()` 확인.
  - `system = _systemPrompt(wiki.systemSection)` — 순서: **규약**(지금 문장들에서 날짜 문장을 뺀 것) → `\n\n` + 위키 절(있을 때) → `\n\n오늘은 $today, 시간대는 … 이다.` **맨 뒤**. 규약 문장 "찾은 기록에 근거해서만 답한다"는 "찾은 기록과 위키에 근거해서만"으로(위키가 있을 때만 — 없으면 지금 문장 그대로).
  - `tools = [..._tools.definitions, ...wiki.tools]` — 질문 동안 고정.
  - 도구 실행: `ToolCallPart(name: WikiTools.readWikiName)` 이고 `wiki.tools.isNotEmpty` 면 `_wikiTools.readWiki(input)`, 아니면 지금처럼 `_tools.run(name, input)`(위키가 없는데 모델이 `read_wiki` 를 부르면 `LifeTools` 의 "모르는 도구" 오류 결과 그대로). `ChatEvent.toolStarted(name)` 은 그대로 낸다.
  - 사용량: 라운드마다 `wikiIndexNotes: wiki.indexNotes, wikiIndexChars: wiki.indexChars, readWikiCalls: <그 라운드 completed.message 의 read_wiki ToolCallPart 수>`.
  - `read_wiki` 도 `maxRounds = 8` 안에서 센다(따로 세지 않음).
  - 클래스 doc 에 "질문마다 WikiContextPolicy 로 위키 색인 · read_wiki 를 붙인다 — 임시 대화는 붙이지 않는다" 한 줄.
- Consumes: Task 2 `WikiContextPolicy` · `WikiContext` · `WikiTools`, 1단계 `_temporary`, core `ChatUsageRecord`.

- [ ] **Step 1: 실패하는 테스트** — `chat_session_test.dart`(가짜 정책: 받은 question 기록 · 돌려줄 `WikiContext` 지정 · 던지기 옵션, `WikiTools` 는 mocktail):
  - `위키가 있으면 system 에 위키 절이, tools 끝에 read_wiki 가 붙는다`.
  - `system 의 마지막 줄은 오늘 날짜이고 위키 절은 그 앞`.
  - `정책이 none 이면 위키 절 · read_wiki 가 없고 system 은 지금 문장과 같다`.
  - `임시 대화(reset · resume temporary: true)는 정책을 부르지 않고 system · tools 에 위키가 없다`(`verifyNever` + 요청 본문 `contains('<wiki_index>')` false) — 스펙 완료 조건 "임시 대화 요청에는 색인 · read_wiki 가 없다".
  - `정책이 던지면 위키 없이 답이 끝난다`.
  - `정책은 질문마다 한 번, 그 질문의 글로 부른다`(2라운드여도 1번).
  - `read_wiki 호출은 WikiTools 로, search_diary 는 LifeTools 로 간다`.
  - `사용량 행에 색인 수 · 글자 수가 라운드마다, readWikiCalls 는 그 라운드의 read_wiki 호출 수`(1라운드 read_wiki 2개 → 2, 2라운드 답 → 0).
  - `read_wiki 를 8라운드 내내 부르면 tooManySteps`.
  - `위키가 없을 때 모델이 read_wiki 를 부르면 WikiTools 를 부르지 않는다`.
- [ ] **Step 2: 실행해 실패 확인** — `cd apps/walk && flutter test test/domain/chat/usecase/chat_session_test.dart` → FAIL.
- [ ] **Step 3: 구현** — 위 규칙. build_runner(`injection.config.dart`).
- [ ] **Step 4: 통과 확인** — `cd apps/walk && flutter analyze && flutter test` → PASS(기존 "시스템 프롬프트에 오늘 날짜" 테스트는 그대로 통과해야 한다).
- [ ] **Step 5: 커밋** — `feat(walk): 물어보기가 질문마다 위키 색인을 싣고 read_wiki 로 본문을 연다`

### Task 4: `WikiDistiller` — [위키로 정리] 요청 · 후보 파싱 · 거르기

**Files:**
- Create: `lib/domain/chat/usecase/wiki_distiller.dart` — `WikiDistiller` · `WikiDistillResult`
- Test: `test/domain/chat/usecase/wiki_distiller_test.dart`

**Interfaces:**
- Produces:
  ```dart
  @freezed
  sealed class WikiDistillResult with _$WikiDistillResult {
    /// 걸러진 후보(0~8개). 0 개면 화면이 "남길 내용이 없어요".
    const factory WikiDistillResult.candidates(List<WikiCandidate> candidates) = WikiDistillCandidates;
    /// 키 없음 · 잘못된 키 · 네트워크 등 — 물어보기와 같은 실패 종류.
    const factory WikiDistillResult.failed(ChatFailure failure) = WikiDistillFailed;
    /// 응답을 JSON 후보로 읽지 못함 → "정리하지 못했어요".
    const factory WikiDistillResult.unparsable() = WikiDistillUnparsable;
  }

  @lazySingleton
  class WikiDistiller {
    WikiDistiller(this._model, this._settings, this._history, this._wiki, this._wikiTools,
        this._diary, this._usage, this._ids, this._clock);
    static const maxCandidates = 8;
    static const maxRounds = 4;
    /// [target] 은 지금 고른 벤더 · 모델(D6) — 화면이 ChatSession.target 을 넘긴다.
    Future<WikiDistillResult> distill({required String conversationId, required ChatTarget target});
  }
  ```
- 요청 만들기:
  - 턴: `_history.turns(conversationId)` 의 마지막 `ChatSession.resumeTurns`(20)개. 메시지 하나(user)로 묶는다 — 턴마다 `질문: …\n답: …`(멈춘 턴은 답 뒤 `ChatSession.stoppedNote`), 근거가 있으면 다음 줄 `[근거 일기: <id>(yyyy-MM-dd), …]`. 날짜는 `DiaryRepository.entry` 가 `Ok` · `!isTrashed` 인 것만(나머지 id 는 줄에서 뺀다). 이 근거 id 들의 합집합이 `allowedEntryIds`.
  - system: 지시문(스펙 §3 "[위키로 정리] 흐름" 3 그대로 + 출력 형식) + `IndexAndReadPolicy` 와 같은 `buildWikiIndex(await _wiki.all(), _settings.wikiIndexSize)` 색인 절(메모가 없으면 "(아직 메모 없음)") + 오늘 날짜. 출력 형식: `{"candidates":[{"action":"new"|"update","id":<update 일 때>,"title":"…","summary":"한 줄","body":"…"}]}` 만, 다른 글 없이.
  - tools: 메모가 있을 때만 `[WikiTools.spec]`. 일기 도구는 **싣지 않는다**.
  - 키는 `_settings.apiKey()`(W4). 없으면 `failed(noKey)`.
  - 라운드: `ModelRequest(model: target.model, …)` 로 `_model.stream`. `toolUse` 면 `read_wiki` 만 실행(다른 이름은 오류 결과), 최대 4라운드 넘으면 `failed(tooManySteps)`. `refusal` → `failed(refused)`. 사용량은 라운드마다 `purpose: wikiDistill`, `questionKey` 한 번 새로, `temporary: false`, 위키 숫자(색인 수 · 글자 · read_wiki 수) — 기다리지 않고 오류를 삼킨다(core P10).
  - `ChatModelException` → 세션과 같은 매핑으로 `failed`.
- 파싱 · 거르기:
  - 최종 글에서 첫 `{` ~ 마지막 `}` 를 잘라 `jsonDecode`(코드 펜스 · 앞뒤 말 허용). 실패 · `candidates` 가 리스트가 아님 → `unparsable()`.
  - 항목마다: title · summary 가 문자열이고 trim 해서 비지 않아야(아니면 그 항목만 버림). body 없으면 빈 글.
  - `action == "update"` 이고 `id` 가 지금 있는 메모면 `.update`, 아니면 `.create`.
  - body 에서 `stripWikiLinks(body, keep)` — `WikiDiaryLink` 는 `allowedEntryIds` 에 있을 때만, `WikiNoteLink` 는 지금 있는 메모 id 일 때만.
  - 앞 8개만.
- Consumes: core `ChatModel` · `ModelRequest` · `ChatUsageLog`, 1단계 `ChatHistoryRepository.turns` · `ChatTarget` · `resumeTurns` · `stoppedNote`, Task 1 · 2.

- [ ] **Step 1: 실패하는 테스트** — `wiki_distiller_test.dart`(가짜 `ChatModel` 이 받은 `ModelRequest` 를 모으고 정해 둔 이벤트를 냄):
  - `요청 user 글에 턴마다 질문 · 답과 근거 일기 id(날짜) 줄이 있다` · `휴지통 일기 id 는 근거 줄에서 빠진다` · `멈춘 턴은 stoppedNote 가 붙는다` · `25턴이면 마지막 20턴만`.
  - `tools 에 일기 도구가 없다 — 메모가 있으면 read_wiki 하나, 없으면 빈 목록`.
  - `system 에 지금 위키 색인과 출력 형식이 있다` · `model 은 target.model`.
  - `키가 없으면 failed(noKey), 모델을 부르지 않는다`.
  - `JSON 후보를 읽는다 — 코드 펜스 · 앞뒤 말이 있어도` · `new 와 update`.
  - `없는 메모 id 의 update 는 create 로` · `제목 · 요약이 빈 항목은 버린다`.
  - `9개면 앞 8개만`.
  - `근거가 아닌 [[일기:x]] 와 없는 [[99]] 는 본문에서 빠진다`(근거 id · 있는 메모 링크는 남음).
  - `JSON 이 아니면 unparsable` · `candidates 가 비면 candidates([])`.
  - `모델이 read_wiki 를 부르면 실행해 결과를 다음 요청에 싣는다` · `4라운드를 넘기면 failed(tooManySteps)` · `refusal 은 failed(refused)` · `invalidKey 예외는 failed(invalidKey)`.
  - `사용량은 라운드마다 purpose wikiDistill · 같은 questionKey · temporary false`.
- [ ] **Step 2: 실행해 실패 확인** — `cd apps/walk && flutter test test/domain/chat/usecase/wiki_distiller_test.dart` → FAIL.
- [ ] **Step 3: 구현** — 위 규칙. build_runner.
- [ ] **Step 4: 통과 확인** — `cd apps/walk && flutter analyze && flutter test` → PASS. `grep -rn "\.apiKey()" lib` 결과가 `ChatSession` · `ChatKeyVerifier`(② 가 있으면) · `WikiDistiller` 뿐인지 확인.
- [ ] **Step 5: 커밋** — `feat(walk): 대화에서 위키 후보를 뽑는 정리 요청(WikiDistiller)`

### Task 5: 위키 목록 · 메모 보기 — 링크 칩 · 흐린 링크 · 역링크 · 삭제 · 모두 지우기

**Files:**
- Create: `lib/presentation/chat/wiki/cubit/wiki_cubit.dart` · `wiki_state.dart`(+ `.freezed.dart`)
- Create: `lib/presentation/chat/wiki/cubit/wiki_note_cubit.dart` · `wiki_note_state.dart`(+ `.freezed.dart`)
- Create: `lib/presentation/chat/wiki/page/wiki_page.dart`
- Create: `lib/presentation/chat/wiki/page/wiki_note_page.dart`
- Create: `lib/presentation/chat/wiki/widget/wiki_link_text.dart`
- Create: `lib/presentation/chat/wiki/open_wiki.dart` — 잠금 아래 라우트 도우미
- Modify: `packages/l10n/lib/l10n/app_{ko,en,ja}.arb`
- Test: `test/presentation/chat/wiki/cubit/wiki_cubit_test.dart` · `wiki_note_cubit_test.dart` · `test/presentation/chat/wiki/page/wiki_page_test.dart` · `wiki_note_page_test.dart` · `test/presentation/chat/wiki/widget/wiki_link_text_test.dart`

**Interfaces:**
- Produces:
  ```dart
  @freezed class WikiState with _$WikiState { /* loading(true) · notes(List<WikiNote>) · indexedIds(Set<int>) · size(WikiIndexSize) */ }
  class WikiCubit extends Cubit<WikiState> {
    WikiCubit(this._wiki, this._settings);   // notes() 구독, 매번 buildWikiIndex 로 indexedIds
    Future<int> deleteAll();
    void refreshSize();                       // 색인 크기 시트에서 돌아온 뒤
  }

  /// 본문 링크를 그리는 데 필요한 것을 미리 읽어 둔 상태.
  @freezed class WikiNoteState with _$WikiNoteState {
    /* loading · note(WikiNote?) · linkedNotes(Map<int, WikiNote>) · linkedEntries(Map<String, DiaryEntry> — 휴지통 제외) ·
       backlinks(List<WikiNote>) · sourceExists(bool) · deleted(bool) */
  }
  class WikiNoteCubit extends Cubit<WikiNoteState> {
    WikiNoteCubit(this._wiki, this._diary, this._history, {required int id});   // watchNote 구독 → 링크 · 역링크 · 출처 다시 읽기
    Future<void> delete();
  }

  /// 본문을 글 + 링크 칩으로. 메모 칩은 제목, 일기 칩은 CitedEntryChip.label 모양.
  /// 대상이 없으면 흐린(onSurface 38%) 비활성 칩 '지워진 메모' · '지워진 일기'.
  class WikiLinkText extends StatelessWidget {
    const WikiLinkText({required this.body, required this.notes, required this.entries,
        required this.onOpenNote, required this.onOpenEntry, super.key});
  }

  /// 위키 화면에서 [대화 보기]를 고르면 그 대화 id 로 끝난다 — 여는 쪽(ChatTab)이 cubit.open 한다.
  Future<String?> openWikiPage(BuildContext context);                       // pushDiaryRoute<String>(WikiPage)
  Future<String?> openWikiNote(BuildContext context, int id);               // pushDiaryRoute<String>(WikiNotePage)
  ```
- `WikiPage`:
  - 앱바: 제목 `walkChatWikiTitle`, `AppOverflowMenu([walkChatWikiDeleteAll])`(메모가 없으면 빈 items). [추가] 아이콘은 Task 6 이 더한다(이 task 에는 없음).
  - 맨 위 안내 한 줄(bodySmall · onSurfaceVariant): `walkChatWikiNotice(vendor)` — 벤더는 `chatVendorLabel(l10n, ChatSession.target.vendor)`(cubit 이 아닌 `getIt<ChatSession>().target` 한 번 읽기).
  - 색인에 안 실린 메모가 있으면 안내 아래 `AppListTile(key: Key('wiki-not-indexed'), title: walkChatWikiNotIndexed(n))` — 누르면 Task 8 의 색인 크기 시트(이 task 에선 행만, 탭 동작은 Task 8).
  - 행 `AppListTile(key: Key('wiki-note-<id>'), title: 제목, subtitle: '요약\n수정일', trailing: 색인 밖이면 Icon(Icons.visibility_off_outlined, semanticLabel: walkChatWikiNotIndexedRow))` → `openWikiNote`. 그 결과가 대화 id 면 `Navigator.pop(context, id)` 로 위로 넘긴다.
  - 빈 상태 `AppPlaceholder(icon: Icons.menu_book_outlined, message: walkChatWikiEmpty)`.
  - 모두 지우기 → `AppConfirmDialog.show(title: walkChatWikiDeleteAllTitle, content: walkChatWikiDeleteAllBody(count), confirmLabel: walkChatWikiDeleteAllConfirm, isDestructive: true)` → `deleteAll`.
- `WikiNotePage`:
  - 앱바: 제목(메모 제목), `AppOverflowMenu([삭제])`([편집] 아이콘은 Task 6 이 더한다) → `AppConfirmDialog(walkChatWikiNoteDeleteTitle · Body, isDestructive)` → `delete()` → pop.
  - 본문: 요약(titleSmall) · `WikiLinkText` · 수정일 · `sourceExists` 면 `AppButton.text(walkChatWikiOpenConversation)` → `Navigator.pop(context, sourceConversationId)`.
  - "이 메모를 가리키는 메모" 헤더(`SettingsSectionHeader` 재사용 대신 titleSmall `Text` — 설정 위젯을 채팅에서 가져오지 않는다) 아래 역링크 `AppListTile` 들 → `openWikiNote`.
  - 메모 칩 → `openWikiNote`(결과를 위로 넘김), 일기 칩 → `openStoryViewer(context, ViewerSource.entries([그 본문의 살아 있는 일기 id들], walkChatWikiDiaryTitle), entryId: …)`.
  - 메모가 사라지면(`deleted`) pop.
- Consumes: Task 1 · 2, `DiaryRepository.entry`, `CitedEntryChip.label`, `openStoryViewer` · `ViewerSource.entries`, `pushDiaryRoute`, 1단계 `chatVendorLabel` · `ChatSession.target`.

**l10n 새 키**:
| 키 | ko | en | ja |
|---|---|---|---|
| `walkChatWikiTitle` | 위키 | Wiki | Wiki |
| `walkChatWikiEmpty` | 대화에서 [위키로 정리]를 누르면 남길 내용을 골라 저장할 수 있어요 | Tap [Save to wiki] in a conversation to pick what to keep | 会話で[Wikiに整理]を押すと、残したい内容を選んで保存できます |
| `walkChatWikiNotice` | 위키 색인(제목 · 요약)은 질문할 때마다, 본문은 모델이 필요할 때 {vendor}로 보내져요. 임시 대화에는 보내지 않아요. | The wiki index (titles and summaries) is sent to {vendor} with every question, and note bodies only when the model needs them. Nothing is sent in temporary chats. | Wikiの索引（タイトル・要約）は質問のたびに、本文はモデルが必要なときに{vendor}へ送信されます。一時的な会話では送信しません。 |
| `walkChatWikiNotIndexed` | 색인에 안 실린 메모 {count}개 · 색인 크기 바꾸기 | `{count, plural, =1{1 note isn't in the index} other{{count} notes aren't in the index}} · Change index size` | 索引に含まれていないメモ{count}件・索引サイズを変更 |
| `walkChatWikiNotIndexedRow` | 색인에 안 실림 | Not in index | 索引外 |
| `walkChatWikiAdd` | 메모 추가 | Add note | メモを追加 |
| `walkChatWikiDeleteAll` | 위키 모두 지우기 | Delete entire wiki | Wikiをすべて削除 |
| `walkChatWikiDeleteAllTitle` | 위키를 모두 지울까요? | Delete the entire wiki? | Wikiをすべて削除しますか？ |
| `walkChatWikiDeleteAllBody` | 메모 {count}개를 지워요. 대화와 사용량 기록은 남아요. | `{count, plural, =1{1 note will be deleted.} other{{count} notes will be deleted.}} Conversations and usage records are kept.` | メモ{count}件を削除します。会話と使用量の記録は残ります。 |
| `walkChatWikiDeleteAllConfirm` | 모두 지우기 | Delete all | すべて削除 |
| `walkChatWikiNoteDeleteTitle` | 이 메모를 지울까요? | Delete this note? | このメモを削除しますか？ |
| `walkChatWikiNoteDeleteBody` | 다른 메모의 링크는 '지워진 메모'로 남아요. | Links from other notes will show as "Deleted note". | 他のメモのリンクは「削除されたメモ」として残ります。 |
| `walkChatWikiBacklinks` | 이 메모를 가리키는 메모 | Notes linking here | このメモを参照しているメモ |
| `walkChatWikiOpenConversation` | 대화 보기 | View conversation | 会話を見る |
| `walkChatWikiDeletedNote` | 지워진 메모 | Deleted note | 削除されたメモ |
| `walkChatWikiDeletedEntry` | 지워진 일기 | Deleted entry | 削除された日記 |
| `walkChatWikiDiaryTitle` | 위키의 일기 | Entries in this note | このメモの日記 |
| `walkChatWikiUpdated` | {date} 수정 | Edited {date} | {date} 更新 |

`vendor` · `date` 는 `String`, `count` 는 `int`. en · ja 의 버튼 이름은 Task 6 · 7 의 `walkChatWikiAddFromBubble` · `walkChatWikiDistill` 값과 맞춘다.

- [ ] **Step 1: 실패하는 테스트**
  - `wiki_cubit_test.dart`: `저장소 스트림을 상태로, indexedIds 는 buildWikiIndex 와 같다` · `deleteAll 은 저장소로 넘긴다` · `refreshSize 뒤 indexedIds 가 새 크기로`.
  - `wiki_note_cubit_test.dart`: `링크된 메모 · 일기(휴지통 제외) · 역링크 · 출처 존재를 읽는다` · `메모가 바뀌면 다시 읽는다` · `지워지면 deleted`.
  - `wiki_link_text_test.dart`: `[[3]] 은 메모 제목 칩, 누르면 onOpenNote(3)` · `[[일기:e1]] 은 날짜 · 본문 앞부분 칩` · `없는 메모 · 일기는 '지워진 메모' · '지워진 일기' 흐린 칩이고 눌러도 아무 일 없다`(`onPressed == null`) · `링크가 아닌 글은 그대로`.
  - `wiki_page_test.dart`(가짜 저장소 · `DiaryLockCubit` mock, `openWikiPage` 로 연 하네스): `최근 순 행 — 제목 · 요약` · `빈 상태 문구` · `벤더 이름이 든 안내` · `색인 밖 메모가 있으면 'n개' 행과 행 표시`(크기 small · 메모 51개) · `모두 지우기는 확인 뒤에만, 취소면 그대로` · `메모가 없으면 ⋮ 항목 없음` · `잠겨 있으면 목록이 트리에 없다`.
  - `wiki_note_page_test.dart`: `요약 · 본문 칩 · 역링크가 보인다` · `메모 칩을 누르면 그 메모 화면` · `삭제는 확인 뒤에만, 확인하면 닫힌다` · `출처 대화가 있으면 [대화 보기] → 그 id 로 끝나 위키 화면까지 넘어간다` · `출처가 지워졌으면 [대화 보기] 없음`.
- [ ] **Step 2: 실행해 실패 확인** — `cd apps/walk && flutter test test/presentation/chat/wiki` → FAIL.
- [ ] **Step 3: 구현** — 위 Interfaces · 화면. build_runner.
- [ ] **Step 4: l10n** — 세 arb, `cd packages/l10n && flutter gen-l10n`.
- [ ] **Step 5: 통과 확인** — `cd apps/walk && flutter analyze && flutter test` → PASS.
- [ ] **Step 6: 커밋** — `feat(walk): 위키 목록 · 메모 보기(링크 칩 · 역링크 · 흐린 링크 · 모두 지우기)`

### Task 6: 메모 편집 · 링크 넣기 시트 · [위키에 추가] · ⋮ [위키]

**Files:**
- Create: `lib/presentation/chat/wiki/cubit/wiki_edit_cubit.dart` · `wiki_edit_state.dart`(+ `.freezed.dart`)
- Create: `lib/presentation/chat/wiki/page/wiki_note_edit_page.dart`
- Create: `lib/presentation/chat/wiki/widget/wiki_note_picker_sheet.dart`
- Create: `lib/presentation/chat/wiki/widget/diary_entry_picker_sheet.dart`
- Modify: `lib/presentation/chat/wiki/open_wiki.dart` — `openWikiEditor`
- Modify: `lib/presentation/chat/wiki/page/wiki_page.dart` · `wiki_note_page.dart` — [추가] · [편집] 연결
- Modify: `lib/presentation/chat/widget/bubble_actions_sheet.dart` — `BubbleAction.addToWiki`, `showBubbleActions(context, {bool canAddToWiki})`
- Modify: `lib/presentation/chat/page/chat_tab.dart` — ⋮ entries 에 [위키], 길게 누르기 시트에 [위키에 추가]
- Modify: `packages/l10n/lib/l10n/app_{ko,en,ja}.arb`
- Test: `test/presentation/chat/wiki/cubit/wiki_edit_cubit_test.dart` · `test/presentation/chat/wiki/page/wiki_note_edit_page_test.dart` · `test/presentation/chat/wiki/widget/wiki_note_picker_sheet_test.dart` · `diary_entry_picker_sheet_test.dart` · `test/presentation/chat/page/chat_tab_test.dart`(더함)

**Interfaces:**
- Produces:
  ```dart
  /// 편집 화면을 여는 값. id 가 null 이면 새 메모.
  @freezed class WikiEditSeed with _$WikiEditSeed {
    /* id(int?) · title · summary · body · sourceConversationId(String?) · suggestedEntryIds(List<String>) */
    static WikiEditSeed fromNote(WikiNote note);
    /// [위키에 추가] — 제목 = conversationTitleFrom(질문), 요약 = 말풍선 글 첫 줄(wikiSummaryMax 에서 자름),
    /// 본문 = 말풍선 글 전체, 출처 = 지금 대화, 근거 일기 = 그 턴의 인용 id.
    static WikiEditSeed fromBubble({required String question, required String text,
        required String? conversationId, required List<String> citedEntryIds});
  }
  @freezed class WikiEditState with _$WikiEditState { /* seed · saving · error(WikiEditError?) */ }
  enum WikiEditError { emptyTitle, emptySummary, saveFailed }
  class WikiEditCubit extends Cubit<WikiEditState> {
    WikiEditCubit(this._wiki, {required WikiEditSeed seed});
    /// 성공하면 메모 id. 제목 · 요약이 비면 error 만 두고 null.
    Future<int?> save({required String title, required String summary, required String body});
  }

  /// 저장하면 메모 id, 취소면 null. pushDiaryRoute 의 scope 에 cubit 을 둬 잠겼다 풀려도 쓰던 글이 남는다.
  Future<int?> openWikiEditor(BuildContext context, WikiEditSeed seed);

  /// 메모 고르기(제목 · 요약 포함 검색, 대소문자 무시). 고른 id 또는 null. [exclude] 는 지금 메모.
  Future<int?> showWikiNotePicker(BuildContext context, {int? exclude});

  /// 일기 고르기. 위쪽 = [suggested] (출처 대화의 근거 일기, 휴지통 제외), 아래 = 날짜를 골라
  /// DiaryRepository.searchEntries(from: 그날 00:00, to: 그날 끝) 결과. 고른 entryId 또는 null.
  Future<String?> showDiaryEntryPicker(BuildContext context, {required List<String> suggested});
  ```
- 편집 화면 `WikiNoteEditPage`:
  - 앱바: 제목 `walkChatWikiEditTitle`(새 메모면 `walkChatWikiNewTitle`), 액션 `AppButton.text(commonSave, key: Key('wiki-edit-save'))`.
  - 칸 셋 — `TextField`(테마 `InputDecorationTheme`): 제목(`maxLength: wikiTitleMax`), 한 줄 요약(`maxLength: wikiSummaryMax`, `maxLines: 1`), 본문(`maxLength: wikiBodyMax`, 여러 줄). 비어 저장하면 칸 아래 오류 문구.
  - 본문 칸 아래 두 버튼 `AppButton.secondary` — [메모 링크] (`Key('wiki-edit-link-note')`) · [일기 링크] (`Key('wiki-edit-link-entry')`): 고른 값을 본문 커서 자리에 `wikiNoteLinkText` · `wikiDiaryLinkText` 로 넣는다(선택 영역이 있으면 바꿔 넣음).
  - 일기 고르기의 `suggested` = seed 의 `suggestedEntryIds` + 출처 대화가 있으면 그 대화 턴들의 인용 id(중복 제거).
  - 저장 성공 → `AppSnackBar.show(walkChatWikiSaved)` 후 pop(id).
- 진입:
  - `WikiPage` 앱바에 `IconButton(key: Key('wiki-add'), Icons.add, tooltip: walkChatWikiAdd)` → `openWikiEditor(context, WikiEditSeed(빈 값))`. `WikiNotePage` 앱바에 `IconButton(key: Key('wiki-note-edit'), Icons.edit_outlined, tooltip: walkChatWikiEditTitle)` → `fromNote`.
  - `ChatTab` ⋮: 1단계 entries 를 `[대화 목록, 위키(Key('chat-menu-wiki'), Icons.menu_book_outlined), (Task 7 자리), 임시 대화로 시작]` 순으로. [위키] → `final id = await openWikiPage(context); if (id != null) await _cubit.open(id);`
  - 말풍선 길게 누르기: `showBubbleActions(context, canAddToWiki: !state.temporary && !bubble.failure 아님 && text.trim().isNotEmpty)` → `addToWiki` 면 그 턴(질문 · 답 말풍선 쌍)으로 `WikiEditSeed.fromBubble`(질문 말풍선을 누르면 text = 질문, 답이면 답) → `openWikiEditor`. 요청 없음.
- Consumes: Task 1 · 5, `DiaryRepository.searchEntries` · `entry`, 1단계 `ChatHistoryRepository.turns` · `conversationTitleFrom` · `showBubbleActions` · `ChatState`.

**l10n 새 키**:
| 키 | ko | en | ja |
|---|---|---|---|
| `walkChatWikiNewTitle` | 새 메모 | New note | 新しいメモ |
| `walkChatWikiEditTitle` | 메모 편집 | Edit note | メモを編集 |
| `walkChatWikiFieldTitle` | 제목 | Title | タイトル |
| `walkChatWikiFieldSummary` | 한 줄 요약 | One-line summary | 一行要約 |
| `walkChatWikiFieldSummaryHelp` | 질문할 때마다 모델에게 보여요 | Shown to the model with every question | 質問のたびにモデルに表示されます |
| `walkChatWikiFieldBody` | 본문 | Body | 本文 |
| `walkChatWikiErrorEmptyTitle` | 제목을 적어 주세요 | Enter a title | タイトルを入力してください |
| `walkChatWikiErrorEmptySummary` | 한 줄 요약을 적어 주세요 | Enter a summary | 要約を入力してください |
| `walkChatWikiErrorSave` | 저장하지 못했어요 | Couldn't save | 保存できませんでした |
| `walkChatWikiLinkNote` | 메모 링크 | Link note | メモをリンク |
| `walkChatWikiLinkEntry` | 일기 링크 | Link entry | 日記をリンク |
| `walkChatWikiPickNoteTitle` | 메모 고르기 | Choose a note | メモを選ぶ |
| `walkChatWikiPickNoteSearch` | 제목으로 찾기 | Search by title | タイトルで検索 |
| `walkChatWikiPickEntryTitle` | 일기 고르기 | Choose an entry | 日記を選ぶ |
| `walkChatWikiPickEntrySuggested` | 이 대화의 근거 일기 | Entries cited in this conversation | この会話の根拠の日記 |
| `walkChatWikiPickEntryByDate` | 날짜로 찾기 | Find by date | 日付で探す |
| `walkChatWikiPickEntryNone` | 그날 기록이 없어요 | No entries that day | その日の記録はありません |
| `walkChatWikiSaved` | 위키에 저장했어요 | Saved to wiki | Wikiに保存しました |
| `walkChatWikiAddFromBubble` | 위키에 추가 | Add to wiki | Wikiに追加 |

- [ ] **Step 1: 실패하는 테스트**
  - `wiki_edit_cubit_test.dart`: `새 메모 save 는 create, 기존은 update` · `제목 · 요약이 비면 error 만, 저장소를 부르지 않는다` · `저장소가 던지면 saveFailed` · `fromBubble 은 제목 · 첫 줄 요약 · 본문 · 출처 · 인용 id 를 채운다`(긴 첫 줄은 120자에서 자름).
  - `wiki_note_edit_page_test.dart`: `seed 값이 칸에 채워진다` · `빈 제목으로 저장하면 오류 문구` · `[메모 링크] → 고르면 커서 자리에 [[id]]` · `[일기 링크] → 근거 일기를 고르면 [[일기:id]]` · `저장하면 pop(id)` · `잠겼다 풀려도 쓰던 글이 남는다`(scope).
  - `wiki_note_picker_sheet_test.dart`: `제목 검색으로 좁힌다` · `지금 메모는 빠진다` · `행을 누르면 그 id`.
  - `diary_entry_picker_sheet_test.dart`: `위쪽에 근거 일기(휴지통 제외)` · `날짜를 고르면 그날 기록` · `없으면 빈 안내`.
  - `chat_tab_test.dart`: `⋮ 순서는 대화 목록 · 위키 · 임시 대화로 시작 · 물어보기 설정 · 앱 설정`(키 순서) · `[위키] → 위키 화면, [대화 보기]로 끝나면 그 대화가 열린다` · `답 말풍선 길게 누르기 → [위키에 추가] → 답 글이 채워진 편집 화면` · `임시 대화에선 시트에 [위키에 추가]가 없다` · `실패 말풍선엔 [위키에 추가]가 없다`.
- [ ] **Step 2: 실행해 실패 확인** — `cd apps/walk && flutter test test/presentation/chat` → FAIL.
- [ ] **Step 3: 구현** — 위 Interfaces · 화면. build_runner.
- [ ] **Step 4: l10n** — 세 arb, `cd packages/l10n && flutter gen-l10n`.
- [ ] **Step 5: 통과 확인** — `cd apps/walk && flutter analyze && flutter test` → PASS.
- [ ] **Step 6: 커밋** — `feat(walk): 위키 메모 편집 · 메모 · 일기 링크 넣기 · 말풍선 [위키에 추가]`

### Task 7: [위키로 정리] — ⋮ 항목 · 후보 시트

**Files:**
- Create: `lib/presentation/chat/wiki/cubit/wiki_distill_cubit.dart` · `wiki_distill_state.dart`(+ `.freezed.dart`)
- Create: `lib/presentation/chat/wiki/widget/wiki_candidates_sheet.dart`
- Modify: `lib/presentation/chat/page/chat_tab.dart` — ⋮ [위키로 정리]
- Modify: `packages/l10n/lib/l10n/app_{ko,en,ja}.arb`
- Test: `test/presentation/chat/wiki/cubit/wiki_distill_cubit_test.dart` · `test/presentation/chat/wiki/widget/wiki_candidates_sheet_test.dart` · `test/presentation/chat/page/chat_tab_test.dart`(더함)

**Interfaces:**
- Produces:
  ```dart
  enum CandidateStatus { pending, saved, discarded }
  @freezed class CandidateItem with _$CandidateItem { /* candidate(WikiCandidate) · current(WikiNote? — update 일 때 지금 메모) · status */ }

  @freezed
  sealed class WikiDistillState with _$WikiDistillState {
    const factory WikiDistillState.loading() = WikiDistillLoading;
    const factory WikiDistillState.ready(List<CandidateItem> items) = WikiDistillReady;   // 빈 목록이면 "남길 내용이 없어요"
    const factory WikiDistillState.failed(ChatFailure failure) = WikiDistillFailedState;
    const factory WikiDistillState.unparsable() = WikiDistillUnparsableState;
  }

  class WikiDistillCubit extends Cubit<WikiDistillState> {
    WikiDistillCubit(this._distiller, this._wiki, {required String conversationId, required ChatTarget target});  // 생성 때 distill
    /// [저장] — create 는 출처 = conversationId, update 는 출처 그대로.
    Future<void> save(int index);
    /// [고쳐서 저장] 이 저장을 끝냈을 때.
    void markSaved(int index);
    void discard(int index);
    bool get allHandled;
  }

  /// 모달 시트. 다 처리하거나 닫으면 끝(남은 후보는 버림). 잠기면 스스로 닫힌다.
  Future<void> showWikiCandidatesSheet(BuildContext context, {required String conversationId, required ChatTarget target});
  ```
- 시트(`DraggableScrollableSheet` + 공통 위젯):
  - loading: 가운데 `CircularProgressIndicator` + `walkChatWikiDistilling`.
  - ready 빈 목록: `AppPlaceholder(icon: Icons.menu_book_outlined, message: walkChatWikiDistillNone)`.
  - failed: `ChatFailureText` 와 같은 문구(1단계 · ② 의 실패 문구 함수 재사용) · unparsable: `walkChatWikiDistillUnparsable`. 둘 다 [닫기].
  - 카드(`Card` + `AppSpacing`, key `Key('wiki-candidate-<index>')`): 라벨 `walkChatWikiCandidateNew` / `walkChatWikiCandidateUpdate`, 제목 · 요약 · 본문(`WikiLinkText`, 칩은 누를 수 없게 — 시트 위에서 다른 화면을 열지 않는다). update 는 "지금" 본문을 위에, "바뀔 내용"을 아래에(폰 폭이라 나란히 대신 위아래).
  - 버튼: `AppButton.primary(commonSave)` · `AppButton.secondary(walkChatWikiCandidateEdit)` → `openWikiEditor(context, seed)`(create 는 출처 = 대화 · `suggestedEntryIds` = 대화의 근거 id, update 는 `id` 채움) → id 가 오면 `markSaved` · `AppButton.text(walkChatWikiCandidateDiscard)`. 처리된 카드는 "저장함" / "버림" 한 줄로 접힌다.
  - `allHandled` 가 되면 `AppSnackBar.show(walkChatWikiDistillDone(savedCount))` 후 닫는다.
  - `BlocListener<DiaryLockCubit>`: 잠기면 `Navigator.pop`.
- ⋮ 항목: `if (state.conversationId != null && !state.temporary && !state.busy && access == ready) FeatureMenuEntry(key: Key('chat-menu-distill'), icon: Icons.auto_awesome_outlined, label: walkChatWikiDistill, onTap: () => showWikiCandidatesSheet(context, conversationId: …, target: getIt<ChatSession>().target))` — [위키] 바로 아래, [임시 대화로 시작] 위.
- Consumes: Task 4 `WikiDistiller` · `WikiDistillResult`, Task 5 `WikiLinkText`, Task 6 `openWikiEditor` · `WikiEditSeed`, 1단계 `ChatTarget` · `ChatState`.

**l10n 새 키**:
| 키 | ko | en | ja |
|---|---|---|---|
| `walkChatWikiDistill` | 위키로 정리 | Save to wiki | Wikiに整理 |
| `walkChatWikiDistilling` | 이 대화에서 남길 내용을 고르는 중… | Picking what to keep from this conversation… | この会話から残す内容を選んでいます… |
| `walkChatWikiDistillNone` | 남길 만한 내용을 찾지 못했어요 | Nothing worth keeping was found | 残す内容が見つかりませんでした |
| `walkChatWikiDistillUnparsable` | 정리하지 못했어요. 다시 해 보세요 | Couldn't summarize. Try again | 整理できませんでした。もう一度お試しください |
| `walkChatWikiDistillDone` | 메모 {count}개를 저장했어요 | `{count, plural, =0{No notes saved} =1{Saved 1 note} other{Saved {count} notes}}` | メモを{count}件保存しました |
| `walkChatWikiCandidateNew` | 새 메모 | New note | 新しいメモ |
| `walkChatWikiCandidateUpdate` | [[{id}]] 고치기 | Update [[{id}]] | [[{id}]]を更新 |
| `walkChatWikiCandidateCurrent` | 지금 | Current | 現在 |
| `walkChatWikiCandidateProposed` | 바뀔 내용 | Proposed | 変更後 |
| `walkChatWikiCandidateEdit` | 고쳐서 저장 | Edit and save | 編集して保存 |
| `walkChatWikiCandidateDiscard` | 버림 | Discard | 破棄 |
| `walkChatWikiCandidateSavedLabel` | 저장함 | Saved | 保存済み |
| `walkChatWikiCandidateDiscardedLabel` | 버림 | Discarded | 破棄済み |

`count` · `id` 는 `int`.

- [ ] **Step 1: 실패하는 테스트**
  - `wiki_distill_cubit_test.dart`(mocktail `WikiDistiller`): `생성하면 loading 뒤 ready(후보)` · `update 후보는 지금 메모를 current 로` · `save(create) 는 출처를 이 대화로 create` · `save(update) 는 그 id 로 update` · `discard · markSaved 는 상태만` · `모두 처리하면 allHandled` · `failed · unparsable 을 그대로`.
  - `wiki_candidates_sheet_test.dart`: `카드마다 저장 · 고쳐서 저장 · 버림` · `[저장]한 것만 저장소에 남고 [버림]은 아무것도 안 쓴다` · `닫으면 남은 후보는 저장되지 않는다` · `update 카드에 지금 · 바뀔 내용이 둘 다` · `빈 후보면 안내` · `unparsable 이면 '정리하지 못했어요'` · `[고쳐서 저장] → 편집 화면이 후보 값으로 열리고 저장하면 카드가 '저장함'` · `잠기면 시트가 닫힌다`.
  - `chat_tab_test.dart`: `저장된 대화가 열려 있으면 ⋮ 에 [위키로 정리]가 [위키]와 [임시 대화로 시작] 사이에` · `빈 대화 · 임시 대화 · 답하는 중 · 키 없음이면 없다` · `누르면 후보 시트` — 스펙 완료 조건 "[위키로 정리]를 누르기 전에는 위키가 생기지 않는다"는 `답이 끝나도 WikiRepository.create 를 부르지 않는다`(`verifyNever`)로 함께 확인.
- [ ] **Step 2: 실행해 실패 확인** — `cd apps/walk && flutter test test/presentation/chat` → FAIL.
- [ ] **Step 3: 구현** — 위 Interfaces · 시트. build_runner.
- [ ] **Step 4: l10n** — 세 arb, `cd packages/l10n && flutter gen-l10n`.
- [ ] **Step 5: 통과 확인** — `cd apps/walk && flutter analyze && flutter test` → PASS.
- [ ] **Step 6: 커밋** — `feat(walk): 물어보기 ⋮ [위키로 정리]와 후보 시트(저장 · 고쳐서 저장 · 버림)`

### Task 8: 물어보기 설정 — 색인 크기 · 위키 모두 지우기 · 사용량의 위키 숫자 · 안내 문구

**Files:**
- Create: `lib/presentation/settings/widget/wiki_index_size_sheet.dart`
- Modify: `lib/presentation/settings/cubit/chat_history_settings_cubit.dart` · `chat_history_settings_state.dart` — `wikiIndexSize` · `wikiCount` · `wikiIndexChars`, `setWikiIndexSize` · `deleteAllWiki`
- Modify: `lib/presentation/settings/widget/chat_history_settings_section.dart` — 두 행
- Modify: `lib/presentation/chat/wiki/page/wiki_page.dart` — "색인에 안 실린 메모" 행 → 시트, 돌아오면 `refreshSize`
- Modify: `lib/domain/chat/entity/chat_usage_summary.dart` — `ChatUsageWikiStats`, `ChatUsageMonth.wiki`
- Modify: `lib/data/chat/database/drift_chat_usage_log.dart` — `DriftChatUsageRepository.month` 가 위키 숫자도
- Modify: `lib/presentation/settings/page/chat_usage_page.dart` — 위키 절
- Modify: `packages/l10n/lib/l10n/app_{ko,en,ja}.arb` — 새 키 + 기존 값 둘 고침(아래)
- Test: `test/presentation/settings/cubit/chat_history_settings_cubit_test.dart` · `test/presentation/settings/widget/chat_history_settings_section_test.dart` · `test/presentation/settings/widget/wiki_index_size_sheet_test.dart` · `test/data/chat/database/drift_chat_usage_log_test.dart` · `test/presentation/settings/page/chat_usage_page_test.dart`(모두 더함)

**Interfaces:**
- Produces:
  ```dart
  /// 고른 크기 또는 null. 위쪽에 "지금 위키 n개 · 색인 약 m자"(지금 크기 기준).
  Future<WikiIndexSize?> showWikiIndexSizeSheet(BuildContext context,
      {required WikiIndexSize current, required int noteCount, required int indexChars});

  // ChatHistorySettingsCubit 에 더함
  Future<void> setWikiIndexSize(WikiIndexSize value);
  Future<int> deleteAllWiki();      // 뒤에 wikiCount · wikiIndexChars 다시 읽기

  /// 그 달 purpose == chat · temporary == false 질문 기준.
  @freezed class ChatUsageWikiStats with _$ChatUsageWikiStats {
    // questions · avgIndexNotes(double) · avgIndexChars(double) · questionsWithReadWiki(int)
  }
  // ChatUsageMonth 에 `final ChatUsageWikiStats wiki;` 더함
  ```
  집계: questionKey 별로 묶어 색인 수 · 글자 수는 그 질문의 `round = 1` 행 값, `read_wiki` 는 그 질문 행들의 `readWikiCalls` 합이 1 이상이면 1. 평균은 질문 수로 나눔(0 이면 0).
- 섹션(1단계 섹션의 [대화 모두 지우기] 아래):
  - `AppListTile(key: Key('chat-history-wiki-size'), leading: Icons.format_list_numbered_outlined, title: walkChatWikiIndexSize, trailing: Text(<단계 이름>))` → 시트 → `setWikiIndexSize`.
  - `AppListTile(key: Key('chat-history-wiki-delete-all'), leading: Icons.delete_sweep_outlined, title: walkChatWikiDeleteAll, enabled: wikiCount > 0)` → Task 5 와 같은 확인 문구 → `deleteAllWiki`.
- 시트: 네 단계 라디오(`RadioListTile` 대신 `AppListTile` + 선택 표시 — `DiaryStorageSection._pickRetention` 과 같은 모양), 각 행 subtitle `walkChatWikiIndexSizeDetail(notes, chars)`(all 은 `walkChatWikiIndexSizeAllDetail(chars)`) + 안내(작게 · 크게 · 모두).
- 사용량 화면: 모델별 표 아래 `walkChatUsageWiki` 헤더, 두 줄 `AppListTile` — `walkChatUsageWikiIndexAvg`(trailing `walkChatUsageWikiIndexAvgValue(notes, chars)`) · `walkChatUsageWikiReadRatio`(trailing `walkChatUsageWikiReadRatioValue(count, questions)` — "12 / 40" 모양). 질문이 0 이면 절을 숨긴다.
- **기존 값 고침(ko · en · ja 셋 다):**
  - `walkChatHistoryDeleteAllBody` — "대화 {count}개를 지워요. 위키와 사용량 기록은 남아요."(1단계 P8 이 미뤄 둔 "위키는 남습니다"). en "… Your wiki and usage records are kept." ja "…Wikiと使用量の記録は残ります。"
  - `walkChatConsentNotice`(동의 문구, D11) — 끝에 한 문장 더: "정리해 둔 위키의 제목 · 요약도 질문마다 함께 보내져요."(en "Titles and summaries from your wiki are also sent with each question." ja "整理したWikiのタイトル・要約も質問ごとに送信されます。"). ② 가 이 키를 `{vendor}` 자리표시자로 바꿨으면 그 문장 뒤에 붙인다.

**l10n 새 키**:
| 키 | ko | en | ja |
|---|---|---|---|
| `walkChatWikiIndexSize` | 위키 색인 크기 | Wiki index size | Wiki索引のサイズ |
| `walkChatWikiIndexSizeSmall` | 작게 | Small | 小 |
| `walkChatWikiIndexSizeStandard` | 기본 | Default | 標準 |
| `walkChatWikiIndexSizeLarge` | 크게 | Large | 大 |
| `walkChatWikiIndexSizeAll` | 모두 | All | すべて |
| `walkChatWikiIndexSizeDetail` | 최근 {notes}개 · {chars}자까지 | Up to {notes} recent notes · {chars} characters | 最近の{notes}件・{chars}文字まで |
| `walkChatWikiIndexSizeAllDetail` | 개수 제한 없음 · {chars}자까지 | No note limit · up to {chars} characters | 件数制限なし・{chars}文字まで |
| `walkChatWikiIndexSizeSmallNote` | 질문마다 보내는 양이 가장 적어요 | Sends the least with each question | 質問ごとの送信量が最も少ない |
| `walkChatWikiIndexSizeLargeNote` | 메모가 많을 때. 질문마다 토큰이 늘어요 | For many notes. Uses more tokens per question | メモが多いとき。質問ごとのトークンが増えます |
| `walkChatWikiIndexSizeAllNote` | 안전 상한을 넘는 부분은 잘려요 | Anything past the safety limit is cut off | 安全上限を超えた分は省かれます |
| `walkChatWikiIndexSizeCurrent` | 지금 위키 {count}개 · 색인 약 {chars}자 | Wiki now: {count} notes · index about {chars} characters | 現在のWiki {count}件・索引 約{chars}文字 |
| `walkChatUsageWiki` | 위키 | Wiki | Wiki |
| `walkChatUsageWikiIndexAvg` | 질문당 평균 색인 | Average index per question | 質問あたりの平均索引 |
| `walkChatUsageWikiIndexAvgValue` | {notes}개 · {chars}자 | {notes} notes · {chars} chars | {notes}件・{chars}文字 |
| `walkChatUsageWikiReadRatio` | read_wiki 를 부른 질문 | Questions that opened wiki notes | Wikiを開いた質問 |
| `walkChatUsageWikiReadRatioValue` | {count} / {questions} | {count} / {questions} | {count} / {questions} |

숫자 자리표시자는 `NumberFormat` 으로 만든 `String`(1단계 `walkChatUsageModelLine` 과 같게), `walkChatWikiIndexSizeCurrent` 의 `count` 만 `int`.

- [ ] **Step 1: 실패하는 테스트**
  - `chat_history_settings_cubit_test.dart`: `load 는 색인 크기 · 위키 수 · 지금 색인 글자 수도` · `setWikiIndexSize 는 저장하고 상태를 바꾼다` · `deleteAllWiki 뒤 위키 수 0, 대화 수는 그대로`.
  - `chat_history_settings_section_test.dart`: `색인 크기 행에 지금 단계, 눌러 '크게'를 고르면 저장된다` · `위키 모두 지우기는 '메모 n개' 확인 뒤에만, 취소면 그대로` · `위키가 없으면 그 행이 꺼진다` · `대화 모두 지우기 문구에 '위키와 사용량 기록은 남아요'`.
  - `wiki_index_size_sheet_test.dart`: `네 단계와 상한 문구, 지금 단계 표시` · `지금 위키 n개 · 색인 약 m자` · `고르면 그 값으로 닫힌다`.
  - `drift_chat_usage_log_test.dart`: `위키 숫자 — 질문별 1라운드 색인 값의 평균, read_wiki 를 한 번이라도 부른 질문 수` · `wikiDistill · 임시 대화 행은 위키 숫자에서 빠진다` · `질문이 없으면 0`.
  - `chat_usage_page_test.dart`: `위키 절에 평균 색인 · 'n / m'` · `질문이 없으면 위키 절이 없다`.
  - `wiki_page_test.dart`(더함): `'색인에 안 실린 메모' 행을 누르면 크기 시트, '크게'를 고르면 행이 사라진다`.
- [ ] **Step 2: 실행해 실패 확인** — `cd apps/walk && flutter test test/presentation/settings test/data/chat test/presentation/chat/wiki` → FAIL.
- [ ] **Step 3: 구현** — 위 Interfaces. build_runner.
- [ ] **Step 4: l10n** — 세 arb(새 키 + 두 값 고침), `cd packages/l10n && flutter gen-l10n`.
- [ ] **Step 5: 통과 확인** — `cd apps/walk && flutter analyze && flutter test` → PASS.
- [ ] **Step 6: 커밋** — `feat(walk): 물어보기 설정에 위키 색인 크기 · 위키 모두 지우기, 사용량에 위키 숫자`

### Task 9: 문서

스펙 "문서 갱신(구현 때)" 의 2단계 몫 + CLAUDE.md(진행 상태는 `status.md` 에만, 완료 시 history · testing 함께).

**Files:**
- Modify: `apps/walk/docs/status.md` · `apps/walk/docs/history.md` · `apps/walk/docs/testing.md` · `apps/walk/docs/plan.md`
- Modify: `docs/superpowers/specs/2026-11-01-walk-chat-history-wiki.md` — 머리 상태 "1 · 2단계 구현됨(기기 QA 대기)", §3 "다음 대화에서 어떻게 참고하나" 의 위키 절 예시에 `[[일기:<id>]]` 안내 문장(W2), `WikiNotePage` 이름 표에 `WikiNoteEditPage`(W6)
- Modify: `docs/superpowers/specs/2026-10-27-walk-life-chat-design.md` — "이후(위키로 가는 길)"에 "2단계로 구현됨" 한 줄

- [ ] **Step 1: `status.md`** — "물어보기" 절에 체크 항목:
  - `[x]` `wiki_notes`(chat DB v2) · 위키 화면(목록 · 보기 · 편집 · 메모 / 일기 링크 · 역링크 · 흐린 링크 · 모두 지우기)
  - `[x]` `WikiContextPolicy`(색인 주입) · `read_wiki` · 색인 크기 설정 · 임시 대화 위키 없음
  - `[x]` [위키로 정리] + 후보 시트 · [위키에 추가] · 사용량의 위키 숫자
  - `[ ]` 기기 QA W-QA1~6 · 후속 판단(`search_wiki` · 미리 골라 붙이기 · 라우팅 — 사용량 숫자를 보고)
  - 1단계의 `[ ] 2단계 위키` 줄은 `[x]` 로. 검증 줄: `flutter analyze` 0 · `flutter test` N건(실행해서 숫자를 적는다).
- [ ] **Step 2: `history.md`** — 새 절 `## 2026-11-xx — 물어보기 위키(2단계)`: 아래 "결정" 표(W1~W10, 이유 포함), 구현 중 바뀐 것, 막힌 것.
- [ ] **Step 3: `testing.md`** — "물어보기" 표에 행 추가: `domain/chat/entity/wiki_note_test` · `data/chat/database/chat_database_migration_test` · `drift_wiki_repository_test` · `domain/chat/wiki/wiki_index_test` · `wiki_context_policy_test` · `domain/chat/tool/wiki_tools_test` · `chat_session_test`(위키 정책 · 임시 대화 · 사용량 숫자) · `wiki_distiller_test` · `presentation/chat/wiki/**`(cubit 넷 · 화면 셋 · 위젯 넷) · `chat_tab_test`(⋮ · [위키에 추가]) · `settings/…`(색인 크기 · 위키 모두 지우기 · 사용량 위키 절). 맨 위 건수 갱신. "물어보기 기기 시나리오"에 W-QA1~6 을 "대기"로(위 기기 QA 목록 그대로).
- [ ] **Step 4: `plan.md`** — "규약" 절의 "나에 대한 메모 · LLM 위키는 아직 안 함" 문단을 위키 설명으로 바꿈(사용자가 누를 때만 생김 · 시스템 프롬프트엔 색인만 · 본문은 `read_wiki` · `WikiContextPolicy` 교체 가능 · 임시 대화엔 없음), 화면 표에 위키 · 메모 · 편집 행, 물어보기 설정 행에 색인 크기 · 위키 모두 지우기.
- [ ] **Step 5: 링크 검사** — `cd apps/trader && flutter test test/convention` → PASS.
- [ ] **Step 6: 커밋** — `docs(walk): 물어보기 위키(2단계) 반영`

---

## 완료 조건 ↔ task

| 스펙 완료 조건(2단계) | 어디서 확인 |
|---|---|
| [위키로 정리] 전에는 위키가 안 생기고, 후보는 [저장] · [고쳐서 저장]한 것만 남음 | Task 7 시트 · chat_tab 테스트(`verifyNever` create) |
| 저장한 위키를 다음 대화에서 모델이 쓴다 — `read_wiki` 기록으로 | Task 3 테스트(색인 · 도구 · 사용량 숫자) + W-QA1 |
| 일상 질문엔 `read_wiki` 를 안 부른다 — 사용량 기록으로 | Task 8 사용량 위키 절 + W-QA2 |
| 본문 `[[id]]` · `[[일기:id]]` 가 칩, 누르면 열림, 지워진 대상은 흐리게 | Task 5 `wiki_link_text_test` · `wiki_note_page_test` |
| 모델이 링크를 따라 열고 일기 날짜로 원본을 찾는다 | Task 2 `wiki_tools_test`(links · diary 날짜) + W-QA3 |
| 후보 8개 이하 · 근거 일기 링크 | Task 4 테스트 + W-QA4 |
| 임시 대화 요청에 색인 · `read_wiki` 없음(요청 본문 확인) | Task 3 테스트 |
| 색인 상한 · 생략 표시 · 설정 바꾸면 다음 질문부터 | Task 2 `wiki_index_test` · `wiki_context_policy_test`, Task 8 시트 |
| 위키 화면은 잠금 아래, 모두 지우기 세 곳이 각각 동작 | Task 5 · 7 잠금 테스트, 위키 화면(Task 5) · 물어보기 설정(Task 8) · 대화 목록 문구(Task 8 — 대화 모두 지우기가 위키를 남김) |

## 결정

이 계획을 쓰며 정한 것(스펙끼리 어긋나거나 스펙이 비워 둔 곳). Task 9 가 `history.md` 로 옮긴다.

| # | 결정 | 이유 |
|---|---|---|
| W1 | 색인은 순수 함수 `buildWikiIndex` 하나로 만들고 정책 · 위키 화면("색인에 안 실린 메모") · 정리 요청 · 크기 시트가 같이 쓴다. 넘치면 처음 안 맞는 메모에서 멈춘다(뒤의 짧은 메모로 건너뛰지 않음) | 화면 표시와 실제로 보낸 색인이 어긋나지 않게. "최근 수정 순"이 곧 우선순위라는 스펙 뜻을 지킨다 |
| W2 | 위키 절에 "`[[일기:<id>]]` 는 read_wiki 가 날짜를 주니 그 날짜로 search_diary" 한 문장을 더한다 | 스펙의 "일기 링크의 날짜로 원본을 다시 찾는다"(완료 조건)를 모델이 알 길이 프롬프트밖에 없다 |
| W3 | `read_wiki` 의 `ids` 는 정수 **배열**로 두고, core `ToolSpec` doc 의 공통 부분집합에 `array` 를 더한다. 실행은 숫자 문자열 · "3,7" 도 받는다 | 스펙이 `{ids: [3, 7]}` 모양. Anthropic · OpenAI 모두 배열 스키마를 받는다. 모델이 모양을 틀려도 실패시키지 않게 |
| W4 | `WikiDistiller` 가 `ChatSettings.apiKey()` 의 세 번째 호출처다(키 UX 계획의 "ChatSession · ChatKeyVerifier 둘뿐" 규칙을 셋으로). 화면 쪽은 여전히 안 읽는다 | 정리 요청은 세션 대화와 따로 도는 요청이라 세션을 거치면 세션 상태(세대 · busy)를 건드린다. domain 유스케이스이므로 규칙의 뜻(화면이 키를 모름)은 지켜진다 |
| W5 | 정리 요청은 대화를 user 메시지 **하나**의 글로 묶어 보낸다(턴을 user/assistant 로 되풀이하지 않음). 턴은 최근 20(`resumeTurns`), 근거 일기 줄은 휴지통 · 없는 일기를 뺀 id(날짜) | "대화를 이어가는" 요청이 아니라 "이 글에서 뽑아라"는 요청이다. 근거 줄의 id 만 허용 목록이 되므로 지운 일기가 링크로 새로 들어가지 않는다 |
| W6 | 편집은 `WikiNotePage` 안 모드가 아니라 별도 `WikiNoteEditPage`(스펙 이름 표의 "WikiNotePage(보기 · 편집)"을 두 화면으로). 쓰던 글은 `pushDiaryRoute` 의 `scope` 에 둔 cubit 이 든다 | [추가] · [위키에 추가] · [고쳐서 저장] 세 곳이 보기 화면 없이 편집만 연다. 잠겼다 풀려도 글이 남는다 |
| W7 | 상한: 제목 60 · 요약 120(한 줄) · 본문 4,000자. 저장소가 자르고 화면은 `maxLength` 로 막는다 | 스펙에 없음. 색인 한 줄이 짧아야 6,000자에 150개가 든다(평균 40자 안팎) |
| W8 | update 후보의 id 가 없는 메모면 create 로 바꾸고, update 를 저장해도 출처(`source_conversation_id`)는 원래 값을 둔다 | 모델이 지어낸 id 를 버리지 않고 살린다. 출처는 "처음 만든 대화"라는 뜻으로 고정 |
| W9 | 후보 시트는 모달이라 잠금 게이트 밖이므로 `DiaryLockCubit` 이 잠기면 스스로 닫는다(남은 후보 버림) | 스펙 §5 "위키는 일기보다 더 압축된 개인 정보" — 잠긴 화면 위에 후보가 남으면 안 된다. 보류 목록이 없다는 D6 와도 맞다 |
| W10 | 사용량 위키 숫자는 그 달 `purpose == chat` · `temporary == false` 질문만, 색인 크기는 질문의 1라운드 값, `read_wiki` 비율은 "한 번이라도 부른 질문 / 질문" | 임시 대화 · 정리 요청은 색인이 0 이거나 성격이 달라 평균을 흐린다. 라운드마다 같은 색인을 싣으므로 1라운드 값이 질문의 색인 크기다 |
| W11 | 정책이 던지면 위키 없이 답한다 · 위키가 없는데 모델이 `read_wiki` 를 부르면 `LifeTools` 의 "모르는 도구" 오류 결과로 돌려준다 | 위키는 덧붙이는 기능이라 질문을 실패시키지 않는다. 도구 목록에 없는 이름은 지금 규칙 그대로 |
| W12 | `read_wiki` 결과는 `entryIds` 를 비운다(인용 칩을 만들지 않는다) | 모델은 일기 원본을 본 것이 아니라 id · 날짜만 받았다. 원본을 `search_diary` 로 읽으면 그때 칩이 붙는다 |
