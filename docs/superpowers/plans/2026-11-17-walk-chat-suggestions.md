# 물어보기 AI 추천 질문 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 빈 대화 화면의 예시 칩을 최근 질문으로 AI 가 만든 질문 4개로 바꾸고, 자동 갱신 · 새로 만들기를 단다.

**Architecture:** 도메인 `ChatSuggester`(DraftWriter 모양: 키 · 동의 확인 → `draftModelOf` 모델로 한 라운드 → 파싱 · 저장 · 사용량 기록)와 SharedPreferences 저장소, 빈 화면 전용 `ChatSuggestionsCubit`. 채팅 전송 흐름은 건드리지 않는다.

**Tech Stack:** Flutter, flutter_bloc, injectable/get_it, shared_preferences, drift, freezed.

**Spec:** `docs/superpowers/specs/2026-11-17-walk-chat-suggestions-design.md`

## Global Constraints

- 입력: 저장된 질문 최근 20개(질문 200자 자름) + askedAt, 오늘 날짜, 언어. 답 · 기록 · 첨부는 보내지 않는다.
- 생성 조건: 키 + 연결 벤더 + `consentedVendor == connectedVendor`, 저장 질문 ≥ 3, (처음) 또는 마지막 생성 뒤 새 질문 ≥ 5, 마지막 시도에서 10분 경과, 생성 중 아님. 새로 만들기는 새 질문 수 · 10분을 무시.
- 출력: 4개, 각 40자 이하, 3개 미만이면 실패. 모델 `draftModelOf`, 도구 · 생각 없음, `maxOutputTokens` 200, 사용량 `ChatUsagePurpose.chatSuggest`.
- 저장 키 `walk.chat.suggestions`(JSON), `walk.chat.suggestionsTriedAt`. 백업 대상 아님.
- 보이기: 저장 질문 0개 → 기본 3개, 저장 추천 있음 → 그 4개, 없음 → 기본 3개.
- 새 스낵바는 `AppSnackBar.show(..., type:)` 유형을 붙인다.

## Review Focus

- 모델이 번호 · 글머리표 · 따옴표를 붙여 답함 → 떼고 보인다 (Task 2 파싱 테스트).
- 저장된 JSON 이 깨졌거나 타입이 다름 → 없는 것으로 본다 (Task 1).
- 대화를 모두 지운 뒤 → 지난 추천이 아니라 기본 질문 (Task 4).
- 생성 중 화면이 닫힘(cubit close) → emit 하지 않는다 (Task 4).
- 실패가 계속될 때 화면 열 때마다 호출 → 10분 쿨다운 (Task 3).

---

### Task 1: 저장 모델 · 저장소 · 최근 질문 조회

**Files:** Create `lib/domain/chat/suggest/chat_suggestions.dart`, `lib/domain/chat/suggest/chat_suggestion_store.dart`, `lib/data/chat/prefs_chat_suggestion_store.dart`; Modify `lib/domain/chat/repository/chat_history_repository.dart`, `lib/data/chat/database/drift_chat_history_repository.dart`, 테스트 fake 4곳(`implements ChatHistoryRepository`).
**Test:** `test/data/chat/prefs_chat_suggestion_store_test.dart`, `test/data/chat/database/drift_chat_history_repository_test.dart`

**Interfaces — Produces:**
- `class ChatSuggestions { List<String> questions; DateTime generatedAt; DateTime basedOnAskedAt; }` (freezed primary constructor)
- `abstract interface class ChatSuggestionStore { ChatSuggestions? get current; Future<void> save(ChatSuggestions); DateTime? get triedAt; Future<void> setTriedAt(DateTime); }`
- `typedef RecentQuestion = ({String question, DateTime askedAt});` · `ChatHistoryRepository.recentQuestions({required int limit}) → Future<List<RecentQuestion>>` askedAt 내림차순, 대화를 가로질러.

- [ ] 테스트: 저장 → 다시 읽기 왕복, 깨진 JSON · 빈 questions · 문자열 아닌 값 → null. drift: 두 대화의 턴이 askedAt 내림차순으로 limit 만큼.
- [ ] 실패 확인 → 구현 → 통과 → 커밋.

### Task 2: 프롬프트 · 파싱

**Files:** Create `lib/domain/chat/suggest/suggest_prompt.dart`; Test `test/domain/chat/suggest/suggest_prompt_test.dart`
**Produces:** `SuggestPrompt.system(String locale) → String`, `SuggestPrompt.user(List<RecentQuestion>, DateTime today) → String`, `SuggestPrompt.parse(String) → List<String>`(최대 4).

- [ ] 테스트: `"1. 어제 뭐 했지?\n- \"지난주 걸음 수는?\"\n\n• 이번 달 일찍 일어난 날?\n4) x"` 에서 표지 제거, 40자 초과 · 빈 줄 · 중복 제거, 5줄이면 4개. user 글에 질문이 200자로 잘리고 날짜가 들어간다.
- [ ] 실패 → 구현 → 통과 → 커밋.

### Task 3: ChatSuggester

**Files:** Create `lib/domain/chat/suggest/chat_suggester.dart`; Modify `lib/domain/chat/chat_usage_log.dart`(enum `chatSuggest`), `lib/presentation/settings/page/chat_usage_page.dart`(라벨), l10n arb 3개; Test `test/domain/chat/suggest/chat_suggester_test.dart`
**Consumes:** Task 1 · 2. **Produces:**
- `enum SuggestOutcome { generated, skipped, failed }`
- `ChatSuggester.canGenerate() → Future<bool>`(키 · 동의 · 질문 ≥ 3)
- `ChatSuggester.refreshIfDue() → Future<SuggestOutcome>` · `ChatSuggester.refresh() → Future<SuggestOutcome>`(강제)
- `ChatSuggester.hasQuestions() → Future<bool>`

- [ ] 테스트: 키 없음 · 동의 다름 → skipped, 요청 없음. 질문 2개 → skipped. 처음 3개 → generated · 저장 · 사용량(purpose chatSuggest, 초안 모델) · 요청 maxOutputTokens 200 · tools 빈 목록 · thinking false. 마지막 생성 뒤 새 질문 4개 → skipped, 5개 → generated. 실패 뒤 10분 안 → skipped(강제 refresh 는 부름). 파싱 3개 미만 → failed, 저장 유지. 모델 오류 → failed.
- [ ] 실패 → 구현 → 통과 → 커밋.

### Task 4: 화면

**Files:** Create `lib/presentation/chat/cubit/chat_suggestions_cubit.dart`(+state); Modify `lib/presentation/chat/widget/chat_examples.dart`, `lib/presentation/chat/page/chat_tab.dart`(`_Conversation`), `test/presentation/chat/page/chat_tab_test.dart` · `test/presentation/shell/page/main_shell_page_test.dart`(getIt 등록); Test `test/presentation/chat/cubit/chat_suggestions_cubit_test.dart`, `test/presentation/chat/widget/chat_examples_test.dart`
**Produces:** state `{List<String>? ai, bool canRefresh, bool refreshing}`; `load()` → 저장된 것 보이고 `refreshIfDue` 뒤 갱신; `refresh() → Future<bool>`.

- [ ] 테스트: 질문 0개면 ai null(기본 칩). 저장 추천 있으면 4칩 + ↻. 새로 만들기 실패 → 스낵바(type error). close 뒤 emit 없음.
- [ ] 실패 → 구현 → 통과 → 커밋.

### Task 5: 문서 · 검증

- [ ] `flutter analyze` 0, `flutter test` 통과, `test/convention`.
- [ ] `apps/walk/docs/status.md` 갱신, 관련 기능 문서(물어보기 문서)에 추천 질문 한 단락.
- [ ] 커밋.
