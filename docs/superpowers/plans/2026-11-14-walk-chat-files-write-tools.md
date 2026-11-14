# walk 물어보기 작업 폴더 쓰기 도구 · 승인 화면(3단계) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 모델이 `write_file` · `edit_file` · `delete_file` 로 작업 폴더 `out/` 의 글 파일을 만들고 · 고치고 · 지우되, 쓰기마다 사용자가 실제 경로 · 내용을 보고 승인해야 디스크가 바뀌게 한다.

**Architecture:** domain `WorkspaceTools` 가 쓰기를 **준비(`prepareWrite` → `WritePlan`)** 와 **실행(`apply`)** 으로 나눈다. `ChatSession` 은 쓰기 호출마다 `ChatEvent.approvalRequested` 를 내고 `Completer<bool>` 을 기다리며, 세대가 바뀌면(멈춤 · 초기화 · 전환 · 실패) 거절로 끝낸다. `ChatCubit` 이 `pendingApproval` 을 상태에 두고 화면이 승인 시트를 띄운다. 벤더 어댑터는 바꾸지 않는다.

**Tech Stack:** Flutter · freezed 3 · injectable · flutter_bloc

**Spec:** [2026-11-14-walk-chat-files-write-tools-design.md](../specs/2026-11-14-walk-chat-files-write-tools-design.md)

경로는 따로 적지 않으면 `apps/walk/` 기준이다.

## Global Constraints

- 도구 이름 정확히 `write_file` · `edit_file` · `delete_file`. 입력: `write_file {path, content, overwrite?: bool}` · `edit_file {path, old_text, new_text}` · `delete_file {path}`.
- 쓰기 경로는 `out/<이름>` 만: 하위 폴더 없음, `.` 로 시작하는 이름 없음, 확장자 `md` · `txt` · `csv` · `json`(대소문자 무시), 이름 120자(코드 포인트) 이하, `AnswerFile` 금지 글자(`\ / : * ? " < > |` · 제어 문자) 없음. 아니면 `invalid_path`, `inbox/…` 는 `read_only`. 경계 밖(`..` · 절대 · 링크)은 `outside_workspace`.
- 내용 · 고친 결과 최대 100,000자(코드 포인트) → 넘으면 `too_large`.
- 오류 json `{"error":"<code>"}`: `invalid_path` · `read_only` · `outside_workspace` · `too_large` · `exists` · `not_found` · `not_text` · `no_match` · `not_unique` · `invalid_input` · `changed` · `user_declined` · `tool_failed`.
- 성공 json: write `{"path","name","chars","created"}`, edit `{"path","name","chars"}`, delete `{"path","name","deleted":true}`.
- 시스템 프롬프트(기록 켜짐, 2단계 작업 폴더 줄 바로 뒤) 정확히: `out 에 파일을 만들거나(write_file) 고치거나(edit_file) 지울(delete_file) 수 있다. 사용자가 질문에서 요청했을 때만 쓰고, 쓰기마다 사용자가 승인한다. 거절되면 같은 쓰기를 다시 시도하지 말고 답에서 알린다. inbox 의 원본은 바꾸지 않고, 고친 판은 out 에 새로 만든다.`
- 진행 줄(ko): 기다림 `승인 기다리는 중 · NAME`, 실행 `파일 저장 중 · NAME` · `파일 고치는 중 · NAME` · `파일 지우는 중 · NAME`, 거절 `거절함`. NAME 은 path 마지막 부분, 20자 넘으면 20자 + `…`.
- 승인 시트 제목(ko): `파일 만들기` · `파일 덮어쓰기` · `파일 고치기` · `파일 지우기`. 버튼: [거절] + [저장] / [고치기] / [지우기](파괴적). 드러낼 보이지 않는 글자: U+0000–U+001F(줄바꿈 `\n` · 탭 `\t` 제외) · U+007F · U+200B–U+200F · U+202A–U+202E · U+2066–U+2069 · U+FEFF → `⟨U+XXXX⟩`.
- 스낵바(ko): `NAME 에 저장했어요` + [열기], 지우기 `지웠어요`.
- 본문 담는 타입(`WritePlan` 등)은 `toString` 에 내용 없이 길이만. 트레이스에 경로 · 내용 없음.
- CLAUDE.md 규칙(공통 위젯 · 토큰 · freezed 패턴 · 생성 파일은 build_runner).
- **main 작업 트리에 다른 세션의 미커밋 변경이 있다. 이 워크트리(`.claude/worktrees/walk-chat-files-3`)에서만 작업하고 `git add <파일>` 로 골라 커밋한다.**

## Review Focus

1. 승인 시트가 떠 있는 동안 [멈춤] · 새 대화 · 대화 전환 → 쓰지 않고, 시트가 닫히고, 다음 질문이 정상 → Task 2 · 3 테스트.
2. 승인 뒤 `apply` 직전에 세대가 바뀜(승인과 멈춤이 겹침) → 쓰지 않음 → Task 2 테스트.
3. 시트가 보여 준 뒤 사용자가 작업 폴더 화면에서 그 파일을 지웠거나 다른 쓰기가 바꿈 → `changed`, 디스크 그대로 → Task 1 테스트.
4. 한 응답에 쓰기 둘 + 읽기 하나 → 읽기는 병렬로 끝나고, 쓰기 승인은 호출 순서대로 하나씩, 결과는 호출 순서 → Task 2 테스트.
5. 내용에 방향 바꾸는 글자 · 폭 없는 글자 · 아주 긴 줄 → 시트에서 드러나고 잘리지 않고 스크롤된다 → Task 4 테스트.

---

### Task 1: `Workspace.writeText` · `WritePlan` · 쓰기 도구 준비 · 실행

**Files:**
- Modify: `lib/domain/chat/workspace/workspace.dart` · `lib/data/chat/workspace/file_workspace.dart` · `lib/domain/chat/tool/workspace_tools.dart` · `lib/domain/chat/tool/tool_summary.dart`(enum · `chatToolKindOf`)
- Create: `lib/domain/chat/tool/write_plan.dart`
- Test: `test/data/chat/workspace/file_workspace_test.dart` · `test/domain/chat/tool/workspace_tools_write_test.dart`(가짜 Workspace 는 2단계 테스트 것을 재사용)

**Interfaces:**
- Produces:
  ```dart
  // Workspace
  Future<void> writeText(String path, String content, {required bool overwrite});
  // overwrite=false 이고 있으면 FileSystemException 대신 WorkspaceFileExistsException(path).
  // 같은 폴더의 `.tmp-<무작위>` 에 쓰고 rename. 경계는 _safe 와 같다.

  @freezed sealed class WritePlan {        // write_plan.dart
    const factory WritePlan.create({required String path, required String name, required String content}) = WriteCreate;
    const factory WritePlan.overwrite({required String path, required String name, required String content, required String previous}) = WriteOverwrite;
    const factory WritePlan.edit({required String path, required String name, required String oldText, required String newText, required String previous, required String content}) = WriteEdit;
    const factory WritePlan.delete({required String path, required String name, required String previous, required int sizeBytes}) = WriteDelete;
  }  // toString: 종류와 글자 수만(path · 내용은 찍지 않는다)

  // WorkspaceTools
  static const writeFileName = 'write_file', editFileName = 'edit_file', deleteFileName = 'delete_file';
  static const maxWriteChars = 100000;
  static const writeNames = {writeFileName, editFileName, deleteFileName};
  List<ToolSpec> get writeDefinitions;   // [write_file, edit_file, delete_file]
  Future<Object> prepareWrite(String name, Map<String, Object?> input); // WritePlan 또는 ToolResult(isError). 디스크를 바꾸지 않는다. 던지지 않는다
  Future<ToolResult> apply(WritePlan plan);  // 지금 내용을 다시 읽어 previous 와 다르면 changed. 던지지 않는다
  ToolResult declined(String name);          // {"error":"user_declined"}, isError
  ```
  - `ChatToolKind.writeFile` · `editFile` · `deleteFile` 와 `chatToolKindOf` 매핑. summary 는 성공 `count: 1`, 오류 `isError`. `ToolSummary` 에 거절을 구분할 `declined` 표시가 필요하면 이 태스크에서 더한다(라벨은 Task 3).
  - 지울 때도 `previous` 비교(바이트를 UTF-8 로 못 읽는 파일은 `not_text` — 지우기도 글 파일만).
- [ ] **Step 1: 실패 테스트**
  - `writeText`: 새로 쓰기 · 덮어쓰기 · `overwrite:false` 에 있으면 예외 · `../x` · 절대 경로 · 밖 링크 → `WorkspacePathException`, 쓰기 뒤 `.tmp-` 파일 없음, `list` 에 임시 파일 안 보임.
  - `prepareWrite`: 경로 규칙 표의 각 줄(하위 폴더 `out/a/b.md` · `out/.x.md` · `out/x.pdf` · `out/a:b.md` · 121자 이름 → `invalid_path`, `inbox/x.md` → `read_only`, `../x.md` → `outside_workspace`), 100,001자 → `too_large`, 있는데 overwrite 없음 → `exists`, overwrite → `WriteOverwrite`(previous 채움), edit 한 번 → `WriteEdit`(content 는 바꾼 결과), 0번 `no_match`, 2번 `not_unique`, 빈 old_text `invalid_input`, 없는 파일 edit/delete → `not_found`. 모든 경우 디스크 불변.
  - `apply`: create · overwrite · edit · delete 성공 json, 준비 뒤 파일이 바뀌면 `changed` 이고 디스크 그대로, create 준비 뒤 파일이 생기면 `exists`. Workspace 가 던져도 `apply` 는 던지지 않음(`tool_failed`).
  - `WritePlan.toString` 에 content · previous 문자열이 없다.
- [ ] **Step 2:** FAIL 확인.
- [ ] **Step 3:** 구현 + build_runner.
- [ ] **Step 4:** PASS, `flutter analyze` 0.
- [ ] **Step 5: Commit** `feat(walk): 작업 폴더 쓰기 도구 준비 · 실행(write · edit · delete)`

### Task 2: 세션 — 승인 기다리기

**Files:**
- Modify: `lib/domain/chat/usecase/chat_session.dart`(`ChatEvent` · `_toolsFor` · `StopKind.toolUse` 가지 ≈680 · `stop` · `reset` · 시스템 프롬프트) · 세션의 `inputSummary`(쓰기 도구 NAME)
- Test: `test/domain/chat/usecase/chat_session_write_tools_test.dart` · 시스템 프롬프트 테스트 갱신

**Interfaces:**
- Consumes: Task 1.
- Produces:
  ```dart
  const factory ChatEvent.approvalRequested({required String callId, required WritePlan plan}) = ChatApprovalRequested;
  // 기다림이 승인 없이 끝났음을 큐빗이 알 수 있게:
  const factory ChatEvent.approvalClosed({required String callId}) = ChatApprovalClosed;
  void decide(String callId, bool approved);   // ChatSession. 기다리는 callId 가 아니면 무시
  ```
  - 기록 켜짐 도구 목록 = LifeTools → 위키 → 읽기 둘 → 쓰기 셋. 꺼짐: 없음, 불리면 `_recordsOffJson`(prepare 도 하지 않음).
  - toolUse: 쓰기 아닌 호출은 지금처럼 바로 병렬. 쓰기 호출은 호출 순서대로 하나씩 `prepareWrite` → (계획이면) `approvalRequested` 를 yield 하고 Completer 대기 → `approvalClosed` → 승인이고 `!stale()` 면 `apply`, 아니면 `declined`. 그다음 그 호출의 `toolFinished`. 결과 모음은 호출 순서. 쓰기 결과는 `_cappedText` 등을 거치지 않는다.
  - `stop()` · `reset()` · 세대가 바뀌는 모든 곳에서 기다리는 Completer 를 `false` 로 끝낸다. `stale()` 이면 `apply` 하지 않고 반환.
  - 기다리는 동안 라운드/스트림 타임아웃은 재지 않는다(지금 타임아웃이 도구 실행 구간에 걸려 있으면 승인 대기를 빼낸다).
  - 트레이스 `toolEnd` 에 쓰기는 `{'tool': name, 'approved': bool}` 만.
  - 시스템 프롬프트: Global Constraints 의 줄을 작업 폴더 줄 바로 뒤(기록 켜짐만).
- [ ] **Step 1: 실패 테스트**
  - 기록 켜짐 요청의 tools 끝이 `write_file, edit_file, delete_file`; 꺼짐이면 없음, 지난 턴을 보고 불러도 `prepareWrite` 안 불림.
  - 승인 → `approvalRequested` 다음 `decide(id, true)` → apply 됨, 다음 요청의 tool_result json 이 성공. 거절 → apply 안 됨, `user_declined`.
  - 기다리는 중 `stop()` → apply 안 됨, 스트림이 끝남, 다음 `ask` 정상. `reset()` 도 같음.
  - `decide(id, true)` 와 같은 틱에 `stop()` → apply 안 됨.
  - 쓰기 둘 + 읽기 하나: 읽기 `toolFinished` 가 첫 승인 전에 나오고, 두 번째 `approvalRequested` 는 첫 `decide` 뒤에 나오며, tool_result 순서 = 호출 순서.
  - prepare 오류(`invalid_path`)는 승인 이벤트 없이 바로 결과.
  - 엉뚱한 callId 로 `decide` → 무시, 계속 기다림.
  - 시스템 프롬프트: 쓰기 줄이 작업 폴더 줄 바로 뒤, 꺼짐에 없음.
- [ ] **Step 2:** FAIL. **Step 3:** 구현 + build_runner. **Step 4:** PASS, analyze 0.
- [ ] **Step 5: Commit** `feat(walk): 쓰기 도구는 승인을 기다린다`

### Task 3: 큐빗 · 진행 줄 · 작업 폴더 새로 고침

**Files:**
- Modify: `lib/presentation/chat/cubit/chat_state.dart`(`pendingApproval`) · `chat_cubit.dart`(이벤트 처리 ≈951 · `approve`/`decline` · stop · 대화 전환 · 초기화) · `lib/presentation/chat/widget/chat_progress_text.dart` · l10n(ko/en/ja) · `lib/presentation/chat/workspace/cubit/workspace_cubit.dart`(새로 고침 신호) · 신호를 나를 domain 쪽 작은 타입(예: `WorkspaceChanges` 싱글턴 스트림, `Workspace` 를 쓰는 쪽에서 `apply` 성공 뒤 알림)
- Test: `test/presentation/chat/cubit/chat_cubit_approval_test.dart` · `test/presentation/chat/widget/chat_progress_text_test.dart` · `test/presentation/chat/workspace/cubit/workspace_cubit_test.dart`

**Interfaces:**
- Consumes: Task 2 이벤트 · `decide`.
- Produces:
  ```dart
  // ChatState
  final PendingApproval? pendingApproval;     // @freezed class PendingApproval { String callId; WritePlan plan; }
  // ChatCubit
  void approve();   // pendingApproval 이 있으면 session.decide(id, true), 상태 비움. 두 번째 호출은 무시
  void decline();   // decide(id, false), 상태 비움
  ```
  - `approvalRequested` → `pendingApproval` 설정, 진행 줄 `승인 기다리는 중 · NAME`. `approvalClosed` · `failed` · `finished` · stop · 대화 전환 · 새 대화 → `pendingApproval = null`.
  - 진행 줄 라벨(Global Constraints). 거절 결과는 `거절함`.
  - apply 성공(write · edit) 뒤 큐빗이 한 번 알릴 일회성 효과(스낵바용) — 지금 큐빗의 일회성 효과 방식(있으면 그 방식, 없으면 상태의 `savedFile` 같은 nonce 필드)을 따른다. 지우기는 `지웠어요`.
  - 작업 폴더 화면이 열려 있으면 쓰기 성공 뒤 목록을 다시 읽는다.
- [ ] **Step 1: 실패 테스트**
  - 이벤트 → 상태에 pendingApproval, `approve()` → 가짜 세션에 `decide(id,true)` 한 번, 두 번 눌러도 한 번. `decline()` → false.
  - 기다리는 중 `stop()` · 대화 전환 → pendingApproval null.
  - 진행 줄 라벨 다섯 개 + NAME 20자 줄임.
  - 쓰기 성공 신호 → workspace 큐빗이 다시 읽음.
- [ ] **Step 2:** FAIL. **Step 3:** 구현 + build_runner. **Step 4:** PASS, analyze 0.
- [ ] **Step 5: Commit** `feat(walk): 승인 대기 상태 · 쓰기 진행 줄`

### Task 4: 승인 시트

**Files:**
- Create: `lib/presentation/chat/workspace/widget/write_approval_sheet.dart` · `lib/presentation/chat/workspace/format/reveal_invisible.dart`(`String revealInvisible(String)`)
- Modify: `lib/presentation/chat/page/`(물어보기 화면 — `pendingApproval` 이 생기면 시트를 띄우고, 사라지면 닫는 BlocListener) · l10n
- Test: `test/presentation/chat/workspace/widget/write_approval_sheet_test.dart` · `test/presentation/chat/workspace/format/reveal_invisible_test.dart`

**Interfaces:**
- Consumes: Task 3 `pendingApproval` · `approve` · `decline`, Task 1 `WritePlan`.
- Produces: `WriteApprovalSheet(plan: WritePlan, onApprove, onDecline)` 와 띄우는 함수. 시트 결과 null(밖 누름 · 뒤로) = 거절.
  - 머리: 제목(Global Constraints) · 실제 상대 경로 그대로 · 크기(만들기 · 덮어쓰기 · 고치기는 새 내용 UTF-8 바이트, 지우기는 `sizeBytes`) · `Claude 가 이 파일을 만들려고 해요` 류 한 줄. 덮어쓰기는 `지금 내용 N자를 바꿔요`.
  - 본문: 고정폭 `SelectableText`, 렌더링 없음, `revealInvisible` 적용, 시트 안에서 세로 스크롤(긴 줄은 줄바꿈 — 잘리지 않음). 고치기는 `지울 부분` · `넣을 부분` 두 상자 + 위에 바뀌는 곳 앞뒤 한 줄 맥락. 지우기는 앞 20줄.
  - 버튼은 `AppButton`, 지우기는 파괴적 스타일, 승인 버튼은 한 번만.
  - 스낵바는 `AppSnackBar.show`, [열기]는 1단계 작업 폴더 보기 화면(`workspace_file_view_page`).
- [ ] **Step 1: 실패 테스트**
  - `revealInvisible('a‮b​c\n\td')` == `'a⟨U+202E⟩b⟨U+200B⟩c\n\td'`; `\u0007` → `⟨U+0007⟩`; 보통 한글 · 이모지 그대로.
  - 만들기 시트: 제목 · 경로 문자열 그대로 · 내용 보임 · [저장] → onApprove 한 번(두 번 탭해도). 밖 누름 → onDecline.
  - 고치기 시트: 두 상자에 old/new 그대로. 지우기: [지우기] 버튼.
  - 마크다운 `# 제목` · `[a](http://x)` 이 글자 그대로 보인다(링크 위젯 없음).
  - 5,000줄 내용 → 시트가 넘치지 않고(오버플로 없음) 스크롤된다.
  - 화면: `pendingApproval` 생기면 시트 열림, 사라지면 닫힘.
- [ ] **Step 2:** FAIL. **Step 3:** 구현. **Step 4:** `flutter test` 전체 PASS, analyze 0.
- [ ] **Step 5: Commit** `feat(walk): 쓰기 승인 시트`

### Task 5: 문서

- [ ] `apps/walk/docs/history.md`(3단계 결정 · 구현 중 정한 것) · `testing.md`(표 행 · 기기 시나리오 W-QA) · `status.md`(3단계 줄) · `plan.md` 물어보기 절 · 스펙 상태 줄. `flutter test test/convention` · trader 문서 링크 테스트 PASS.
- [ ] Commit `docs(walk): 작업 폴더 쓰기 도구 3단계 기록`
