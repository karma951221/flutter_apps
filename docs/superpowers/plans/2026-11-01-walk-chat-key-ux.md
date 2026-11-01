# walk 물어보기 — 키 UX(키 입력 기획 ②) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 물어보기 설정에서 Claude 키를 넣으면 저장 전에 키를 확인하고(요금 경고 → 등록), 연결 행에 로고 · "연결됨" · 앞부분만 보이는 마스킹 키를 보여 주며, 물어보기 · 실패 말풍선 · 알람 권한 배너에서 설정 화면을 열면 봐야 할 행을 두 번 glow 한다. 키는 보안 저장소에만 있고 화면 쪽 코드는 원문을 읽지 않으며, 보안 저장소 파일은 Android 백업에서 빠진다.

**Architecture:** `ChatSettings` 계약을 "연결(`ChatConnection` = 벤더 · 미리보기 · 상태)" 중심으로 바꾸고 원문 키는 `ChatSession` · `ChatKeyVerifier`(모델 목록 호출로 키 확인) 둘만 읽는다. 마스킹은 domain 순수 함수, 저장 · 이전 · 읽기 실패 정리는 `SecureChatSettings`. 어댑터에 `listModels` 와 `quotaExceeded` · `modelUnavailable` 매핑을 더한다. 화면은 `ChatSettingsSection` 을 다시 그리고(키 대화상자 · 요금 경고 · 스낵바), 행 하나를 짚는 `RowHighlight` 와 벤더 로고 `ChatVendorIcon` 을 새로 둔다. 강조 열기는 `openSettings(…, highlight: true)` 한 인자로 전달한다.

**Tech Stack:** Flutter · flutter_bloc · Freezed 3 · injectable/get_it · `package:http` · `flutter_secure_storage` 11.1.1 · `flutter_svg`(새) · gen-l10n(`packages/l10n`, 기준 `app_ko.arb`).

**Spec:** [키 입력 · 멀티 벤더 기획](../specs/2026-11-01-walk-chat-key-input.md) §1~§4 · §6.1(Claude 행만) · §7.1~§7.4 중 ② 몫 · §10.1~§10.3 중 Anthropic · §11~§12 의 ② 행 · §14 ② 단계

**선행(이 계획을 실행할 때 끝나 있다고 본다):**
- [하단 탭 재구성 계획](2026-11-01-walk-nav-regroup.md) 전체 — 설정 탭 없음, `openSettings(context, SettingsTarget)`, `ChatSettingsPage` · `AlarmSettingsPage`(`AlarmPermissionTiles`), `ChatTab.onOpenSettings` · `AlarmListPage.onOpenSettings` 는 셸이 `openSettings` 로 잇는 `VoidCallback`, 도구 탭 `ToolsTab.onOpenAlarmSettings`
- [중립 계약 · 계측 · 멈춤 계획](2026-11-01-walk-chat-core.md) 전체 — `ChatVendor`(`lib/domain/chat/chat_vendor.dart`), 중립 `ChatModel { vendor; stream(ModelRequest) }`, `ChatModelErrorKind.quotaExceeded · modelUnavailable`(어댑터는 아직 안 냄, 세션은 `unknown`), `AnthropicChatModel(http.Client, ChatTrace)` · `withTimeouts`, `abortableSend`, `ChatSession(…, _usage, _ids, _trace)` · `interimModel`

각 task 를 시작할 때 위 이름이 실제 코드와 같은지 먼저 `grep` 으로 맞춘다. 다르면 실제 이름을 따르고 이 계획의 해당 줄을 고친다(인터페이스 모양은 그대로).

## Global Constraints

- 경로는 `apps/walk/` 기준. 테스트는 `test/` 아래 같은 구조(`lib/x/y.dart` ↔ `test/x/y_test.dart`).
- **저장소 전체 포맷 금지.** `dart format` 은 이 task 가 만든 · 고친 파일에만.
- **생성 파일**(`.freezed.dart` · `.g.dart` · `injection.config.dart`)은 손으로 고치지 않는다 — `cd apps/walk && dart run build_runner build --delete-conflicting-outputs`.
- Freezed(CLAUDE.md): 단일 모델은 Freezed 3 primary constructor, 변형은 `sealed class` + named factory. 분기는 `switch` 패턴 매칭(`when`/`map` 금지).
- UI 규칙(CLAUDE.md): `AppListTile` · `AppButton` · `AppSnackBar.show` · `AppConfirmDialog.show` · `AppPlaceholder` 우선. `Colors.*` · 숫자 여백 · `BorderRadius.circular(n)` 금지 — `AppSpacing` · `AppRadius` · `AppMotion` · `Theme.of(context)`. 애니메이션은 `AppMotion.enabled(context)` 가 false 면 그리지 않는다.
- 문구는 l10n 만. 새 키는 `app_ko.arb` · `app_en.arb` · `app_ja.arb` 셋 다(ko 에는 `@키` description), 그 뒤 `cd packages/l10n && flutter gen-l10n`. 벤더 이름(Claude · Anthropic)도 l10n 키로 둔다(세 언어 같은 값).
- **원문 키는 예외 · 로그 · 상태 · `toString` · prefs 어디에도 남기지 않는다.** `apiKey()` 호출처는 `ChatSession` · `ChatKeyVerifier` 둘뿐(Task 6 끝에 `grep -rn "\.apiKey()" lib` 로 확인).
- 벤더는 **Claude(`ChatVendor.anthropic`) 하나**. 벤더 시트 · 벤더 바꾸기 · 동의 벤더(④), 모델 행 · 칩 · 카탈로그 · 빠른 출력(③), GPT(④), Grok(⑤)은 범위 밖. 모델 id 는 `ChatSession.interimModel` 그대로.
- 기존 위젯 `Key` 중 `settings-chat-key`(연결 행) · `settings-chat-delete`(연결 끊기 행) · `chat-key-save` 는 이름을 유지한다(`open_settings_test` 등이 찾는다).
- 매 task 끝: `cd apps/walk && flutter analyze && flutter test` 0 오류 · 전체 통과. 커밋은 task 마다 하나.

## Review Focus

1. **원문 키가 화면 쪽에 없다(Task 1 · 5)** — `ChatSettingsCubit` · `ChatCubit` 이 `apiKey()` 를 부르지 않는다. 상태 `toString` · 미리보기에 본문 5번째 이후 글자가 없다. 입력 대화상자의 키 문자열은 cubit 메서드 인자로만 지나가고 상태에 담기지 않는다.
2. **저장 순서(Task 5)** — 확인 → (정상 · 확인 못 함) 요금 경고 → [확인]일 때만 쓰기. 잘못된 키 · 경고 [취소]는 저장소를 건드리지 않는다. 쓰기 실패 때 기존 연결이 그대로다(Task 1 `connect` 순서).
3. **백업 · 복원 짝(Task 1)** — 보안 저장소 파일만 백업에서 빠지고 prefs(`chat.vendor` · `chat.keyStatus`)는 복원될 수 있다. 키 없이 prefs 만 있으면 미연결로 정리한다. 읽기 예외도 미연결로.
4. **glow 시점(Task 4 · 6)** — push 전환이 끝난 뒤 재생, 두 번 ≈ 1.8초, 탭 · 스크롤이면 곧바로 꺼짐, 애니메이션 줄이기면 없음. ⋮ 로 평범하게 열면 없음. 알람은 조치가 필요한 첫 권한 행 하나만.
5. **오류 본문 원칙(Task 2)** — 오류 응답은 `error.type` 한 필드만 읽고(크기 · 시간 상한) 나머지는 버린다. 예외에는 enum 만.

## 구현 전 확인

live 문서 · 실기기가 필요한 항목(스펙 §10.3 중 ② 몫). 어느 것도 코드 · 단위 테스트를 막지 않게 설계했다 — 결과는 Task 7 에서 walk `history.md` 에 남긴다.

| # | 확인할 것 | 필요한 task | 막히지 않게 한 설계 |
|---|---|---|---|
| K1 | **Anthropic 브랜드 가이드(Q9, §10.3-3)** — Claude/Anthropic 로고를 앱 안 "연결 대상 표시"로 써도 되는지, 단색화 · 다크 모드 반전 허용, 최소 크기 · 여백, 공식 SVG 받을 곳 | Task 3 | `ChatVendorIcon` 은 **확인 전에는 글자 원형(모노그램 "C")** 을 그린다. 로고 경로는 `ChatVendorIcon.confirmedLogos`(`Map<ChatVendor, ChatVendorLogo>`) 한 곳 — 확인 전 값은 **빈 맵**이고 `assets/chat/vendors/` 에 파일도 넣지 않는다(pubspec 자산 항목도 확인 뒤). 확인되면 SVG 를 `assets/chat/vendors/anthropic.svg` 에 넣고 맵에 한 줄, 단색화가 허용되면 `tintable: true`. 쓸 수 없으면 모노그램을 유지하고 사용자에게 다시 묻는다(스펙 §10.3-3) |
| K2 | **Anthropic 오류 모양(§10.1 · §10.3-1)** — 크레딧 부족이 `402 billing_error` 인지 `400 invalid_request_error`(메시지로만 구분)인지, 모르는 모델이 `404 not_found_error` 인지, 오류 본문의 `error.type` 위치 | Task 2 | `error.type` 우선 · 상태 코드 보조로 매핑. 크레딧 부족이 메시지로만 구분되면 매핑하지 않고 `unknown` 그대로 둔 채(원칙상 메시지는 읽지 않음) history 에 적고 사용자에게 묻는다. 테스트는 손으로 만든 본문 |
| K3 | **`GET /v1/models`** — `limit` 상한(1000 허용 여부), 응답 필드(`data[].id` · `display_name` · `created_at` · `has_more`), 401 · 403 구분, 크레딧 0 인 키도 200 인지(§4 주의) | Task 2 | ② 는 **상태 코드만** 판정에 쓴다(2xx valid · 401/403 invalid · 그 밖 unreachable). 목록 파싱은 관대하게(빠진 필드는 건너뜀), 페이지 넘기기는 ③ |
| K4 | **보안 저장소 파일 이름(Q6)** — `flutter_secure_storage` 11.1.1 Android 기본 저장 파일. 로컬 pub cache(`FlutterSecureStorageConfig`)로 `shared_prefs/FlutterSecureStorage.xml`(데이터) · `shared_prefs/FlutterSecureKeyStorage.xml`(감싼 키)를 확인했고 `AndroidOptions.resetOnError` 기본 true. 실기기에서 `adb shell bmgr backupnow` → 재설치 → 복원 뒤 미연결로 보이는지 | Task 1 | 두 파일을 백업 규칙에서 뺀다. 복원 뒤 읽기 예외 · 키 없는 prefs 는 `SecureChatSettings` 가 미연결로 정리(단위 테스트). 기기 확인은 testing.md 기기 시나리오 "대기" |
| K5 | **재구성 · 중립 계약 실제 이름** — `ToolsTab.onOpenAlarmSettings` 를 셸이 어떻게 잇는지, `ChatTab` 앱바 `FeatureMenu(settings: chat)` 경로, `AnthropicChatModel` 생성자 · `withTimeouts` 인자, 테스트의 `implements ChatModel` 가짜 목록 | Task 2 · 6 | 각 task 의 첫 단계가 `grep` 으로 맞춘다. 인터페이스 모양은 바뀌지 않는다 |

---

### Task 1: 연결 계약 · 마스킹 · 보안 저장 · 백업 제외

스펙 §2 · §7.1 · §7.2(② 몫) · Q3 · Q5 · Q6. 화면 변화는 최소(키 행 오른쪽 글자가 `…abcd` → 마스킹 미리보기). 화면 다시 그리기는 Task 5.

**Files:**
- Create: `lib/domain/chat/chat_connection.dart` — `ChatKeyStatus` · `ChatConnection`
- Create: `lib/domain/chat/api_key_mask.dart` — `maskApiKey` · `vendorOfKey` · `chatKeyPrefixHint`
- Modify: `lib/domain/chat/chat_settings.dart` — 계약 교체
- Modify: `lib/data/chat/secure_chat_settings.dart` — 새 저장 키 · 이전 · 읽기 실패 정리
- Modify: `lib/presentation/settings/cubit/chat_settings_cubit.dart` · `chat_settings_state.dart` — `connection()` · `connect` · `disconnect` 로 옮김(동작은 지금과 같음: 저장 → 다시 읽기). 상태 `keyHint` → `connection`
- Modify: `lib/presentation/settings/widget/chat_settings_section.dart` — 행 오른쪽 글자만 `state.connection?.keyPreview` 로(나머지는 Task 5)
- Modify: `lib/presentation/chat/cubit/chat_cubit.dart` — `refresh()` 가 `hasApiKey()` (Q5)
- Create: `android/app/src/main/res/xml/backup_rules.xml` · `android/app/src/main/res/xml/data_extraction_rules.xml`
- Modify: `android/app/src/main/AndroidManifest.xml` — `<application>` 에 `android:fullBackupContent="@xml/backup_rules"` · `android:dataExtractionRules="@xml/data_extraction_rules"`
- Modify: `test/support/fake_chat_settings.dart` — 새 계약
- Test: `test/domain/chat/api_key_mask_test.dart`(새) · `test/domain/chat/chat_connection_test.dart`(새) · `test/data/chat/secure_chat_settings_test.dart` · `test/presentation/settings/cubit/chat_settings_cubit_test.dart` · `test/presentation/settings/widget/chat_settings_section_test.dart`(기대 글자만) · `test/presentation/chat/cubit/chat_cubit_test.dart`

**Interfaces:**
- Produces (`chat_connection.dart`):
  ```dart
  enum ChatKeyStatus { unverified, valid, invalid }

  /// 화면에 보여도 되는 연결 정보. 원문 키는 없다.
  @freezed
  class ChatConnection with _$ChatConnection {
    @override
    final ChatVendor vendor;
    /// [maskApiKey] 결과. 본문 앞 4글자 뒤는 늘 `••••`.
    @override
    final String keyPreview;
    @override
    final ChatKeyStatus status;
    const ChatConnection({required this.vendor, required this.keyPreview, required this.status});
  }
  ```
- Produces (`api_key_mask.dart`):
  ```dart
  /// 미리보기 끝에 붙는 점. 길이를 드러내지 않게 늘 4개.
  const apiKeyMaskDots = '••••';

  /// 벤더 공개 접두사 + 본문 앞 4글자 + `••••`(Q3). 접두사가 안 맞으면 앞 8글자 + `••••`,
  /// 8글자 미만이면 `••••`. 접두사 뒤 본문이 4글자 미만이면 접두사 + `••••`.
  String maskApiKey(ChatVendor vendor, String key);

  /// 키 모양으로 벤더를 짐작한다. 모르면 null.
  /// anthropic: `^sk-ant-api\d+-`(그 밖의 `sk-ant-` 는 null — 관리 키 등).
  /// openai: `sk-proj-` · `sk-svcacct-` · `sk-`(옛 형식) — `sk-ant-` · `sk-admin-` 는 아님.
  /// 가장 긴 접두사부터 맞춘다.
  ChatVendor? vendorOfKey(String key);

  /// 입력 안내에 보일 그 벤더 접두사(anthropic → `sk-ant-`).
  String chatKeyPrefixHint(ChatVendor vendor);
  ```
  접두사 표는 이 파일의 `const` 한 곳(④ 가 openai 접두사를 그대로 쓴다).
- Produces (`chat_settings.dart`):
  ```dart
  abstract interface class ChatSettings {
    /// 미연결이면 null. 보안 저장소를 읽지 못하면 그 항목을 지우고 null.
    Future<ChatConnection?> connection();
    /// 키가 있는가(Q5). 물어보기 탭이 쓴다.
    Future<bool> hasApiKey();
    /// 원문 키. ChatSession · ChatKeyVerifier 만 부른다.
    Future<String?> apiKey();
    /// [key] 를 trim 해 연결한다. 빈 문자열이면 ArgumentError.
    /// 보안 저장소 쓰기가 끝난 뒤에만 벤더 · 상태를 바꾼다 — 쓰기가 실패하면 기존 연결 그대로(예외는 그대로 던짐).
    Future<void> connect(ChatVendor vendor, String key, ChatKeyStatus status);
    /// 키 · 벤더 · 상태를 지운다. 동의는 그대로.
    Future<void> disconnect();
    /// 연결돼 있을 때만 기록. 같은 값이면 쓰지 않는다.
    Future<void> setKeyStatus(ChatKeyStatus status);

    bool get consented;           // ④ 에서 consentedVendor 로
    Future<void> setConsented();
  }
  ```
  `saveApiKey` · `deleteApiKey` 는 없앤다.
- Produces (`SecureChatSettings`) — 저장 위치(스펙 §7.2):
  | 값 | 저장소 | 키 |
  |---|---|---|
  | 원문 키 | 보안 저장소 | `chat.apiKey`(상수 `apiKeyName`) |
  | 옛 키 | 보안 저장소 | `anthropic_api_key`(상수 `legacyApiKeyName`) — 이전 뒤 지움 |
  | 벤더 · 상태 | prefs | `chat.vendor`(enum name) · `chat.keyStatus`(enum name) |
  | 동의 | prefs | `chat.consented`(그대로) |
  규칙:
  - **이전**(첫 접근 때 한 번, `Future` 메모): `chat.apiKey` 가 없고 `anthropic_api_key` 가 있으면 → `chat.apiKey` 에 쓰기 → prefs `vendor = anthropic`, `keyStatus = unverified` → 옛 키 삭제. 쓰기가 실패하면 옛 키를 남기고 다음 접근 때 다시.
  - **읽기 정리**: 보안 저장소 읽기가 던지면 `chat.apiKey` 삭제 시도(실패는 삼킴) + prefs 벤더 · 상태 삭제 → 미연결. 키가 없는데 prefs 만 있으면(백업 복원) prefs 를 지운다. 키는 있는데 prefs 벤더가 없으면 `vendorOfKey(key) ?? anthropic` · `unverified` 로 채운다.
  - `connection()` 미리보기는 `maskApiKey(vendor, key)` — 미리보기를 prefs 에 따로 저장하지 않는다.
- Produces (`ChatSettingsCubit`, 임시 — Task 5 에서 다시 씀): `load()` 는 `connection()`, `save(key)` 는 `connect(ChatVendor.anthropic, key, ChatKeyStatus.unverified)`, `delete()` 는 `disconnect()`. 상태:
  ```dart
  @freezed
  class ChatSettingsState with _$ChatSettingsState {
    @override final bool loading;
    @override final ChatConnection? connection;
    const ChatSettingsState({this.loading = true, this.connection});
  }
  ```
- Produces (Android): 두 xml 모두 `domain="sharedpref"` 로 `FlutterSecureStorage.xml` · `FlutterSecureKeyStorage.xml` 을 `<exclude>`. `backup_rules.xml` 은 `<full-backup-content>`, `data_extraction_rules.xml` 은 `<data-extraction-rules>` 의 `<cloud-backup>` · `<device-transfer>` 둘 다. 다른 데이터의 백업 정책은 그대로(`allowBackup` 은 건드리지 않는다). minSdk 26 이라 두 속성 모두 둔다(API 31+ 는 `dataExtractionRules`).

- [ ] **Step 1: 실패하는 테스트**
  - `api_key_mask_test.dart`:
    - `Claude 키는 접두사 + 4글자 + 점 4개` — `maskApiKey(anthropic, 'sk-ant-api03-Ab3xYZ…(90자)')` → `'sk-ant-api03-Ab3x••••'`.
    - `점 개수는 키 길이와 무관하게 4개` — 20자 · 120자 키 모두 `endsWith('••••')` 이고 `'•'` 개수 4.
    - `본문 5번째 이후 글자는 없다` — 본문 `Ab3xQRST…` 에서 `'Q'` · `'QRST'` 미포함.
    - `접두사가 안 맞으면 앞 8글자 + 점` — `maskApiKey(anthropic, 'abcdefghijkl')` → `'abcdefgh••••'`.
    - `8글자 미만이면 점만` — `'abc'` → `'••••'`.
    - `접두사 뒤 본문이 4글자 미만이면 접두사 + 점` — `'sk-ant-api03-ab'` → `'sk-ant-api03-••••'`.
    - `openai 접두사도 가장 긴 것부터` — `maskApiKey(openai, 'sk-proj-Ab3xyz…')` → `'sk-proj-Ab3x••••'`.
    - `vendorOfKey` — `sk-ant-api03-…` → anthropic · `sk-proj-…` · `sk-svcacct-…` · `sk-abc…` → openai · `sk-admin-…` → null · `sk-ant-admin01-…` → null · `xai-…` · `''` → null.
    - `chatKeyPrefixHint(anthropic) == 'sk-ant-'`.
  - `chat_connection_test.dart`: `toString 에 미리보기 외 키 글자가 없다`(마스킹된 값만 들어감을 고정) · `값이 같으면 같다`.
  - `secure_chat_settings_test.dart`(mocktail `_MockSecure` 그대로, 기존 테스트는 새 계약으로 옮김):
    - `connect 는 trim 한 키를 chat.apiKey 에만 쓰고 prefs 에 벤더 · 상태를 쓴다` — prefs 어느 값에도 키 문자열 없음.
    - `connect 쓰기가 실패하면 벤더 · 상태가 그대로이고 예외를 던진다`(기존 연결 유지).
    - `빈 키로 connect 하면 ArgumentError`.
    - `connection 은 미리보기 · 벤더 · 상태를 주고 원문이 없다` — `toString` 에 키 본문 5번째 이후 없음.
    - `옛 anthropic_api_key 를 chat.apiKey 로 옮기고 지운다` — 쓰기 → 삭제 순서(`verifyInOrder`), 결과 `unverified · anthropic`.
    - `이전 쓰기가 실패하면 옛 키를 지우지 않는다`.
    - `읽기가 던지면 항목을 지우고 미연결` — `connection()` null, `hasApiKey()` false, `chat.vendor` 없음.
    - `키 없이 prefs 만 남아 있으면(복원) 미연결로 정리한다`.
    - `키는 있는데 벤더가 없으면 키 모양으로 채우고 unverified`.
    - `disconnect 는 키 · 벤더 · 상태를 지우고 동의는 남긴다`.
    - `setKeyStatus 는 연결돼 있을 때만, 같은 값이면 prefs 를 쓰지 않는다`.
    - 기존 `동의` 테스트 그대로.
  - `chat_settings_cubit_test.dart`(기존을 옮김): `키가 있으면 마스킹 미리보기가 보인다`(`'sk-ant-api03-xyz1••••'`) · `상태 toString 에 원문이 없다` · `저장하면 연결이 생기고 끊으면 사라진다` · `읽다 실패해도 loading 이 끝나고 미연결` · 새: `apiKey() 를 부르지 않는다`(가짜의 `apiKeyCalls == 0`).
  - `chat_cubit_test.dart`: `refresh 는 hasApiKey 만 본다`(가짜 `apiKeyCalls == 0`, 키 있음/없음 → `ready`/`noKey`).
  - `chat_settings_section_test.dart`: 기대 글자 `'…1234'` → 마스킹 미리보기(키는 `sk-ant-api03-xyz1234…` 로). 나머지 그대로.
- [ ] **Step 2: 실행해 실패 확인** — `cd apps/walk && flutter test test/domain/chat test/data/chat test/presentation/settings test/presentation/chat` → 컴파일 오류로 FAIL.
- [ ] **Step 3: 구현** — 위 Interfaces. `FakeChatSettings` 는 `connection` · `status` · `vendor` 필드를 테스트가 직접 바꾸고, `apiKeyCalls` 를 센다(`FakeChatSettings([String? key])` 생성자는 유지 — 키가 있으면 `anthropic` · `valid`). 다른 테스트의 `FakeChatSettings` 사용처(`app_test` · `settings_harness` · 셸 테스트)가 컴파일되는지 확인. build_runner.
- [ ] **Step 4: Android 백업 규칙** — 두 xml + manifest 두 속성. `cd apps/walk && flutter build apk --debug` 로 manifest 병합 오류가 없는지 한 번 확인(테스트는 아님).
- [ ] **Step 5: 통과 확인** — `cd apps/walk && flutter analyze && flutter test` → PASS.
- [ ] **Step 6: 커밋** — `feat(walk): 물어보기 키를 연결 정보로 다루고 앞부분만 보이게 가린다`

### Task 2: 키 확인 호출 · 새 실패 종류 · 키 상태 기록

스펙 §4 · §7.3 · §10.1(Anthropic 열) · §10.2 · Q1. 중립 계약 계획이 미룬 `listModels` · `quotaExceeded` · `modelUnavailable` 매핑 · 문구를 여기서 한다. 화면 변화: 새 실패 문구 두 개뿐.

**Files:**
- Modify: `lib/domain/chat/chat_model.dart` — `ChatModel.listModels` · `ModelListResult` · `ModelInfo`
- Modify: `lib/data/chat/anthropic_chat_model.dart` — `listModels`, 오류 매핑(`error.type` 만 읽기)
- Create: `lib/domain/chat/usecase/chat_key_verifier.dart`
- Modify: `lib/domain/chat/usecase/chat_session.dart` — `ChatFailure.quotaExceeded · modelUnavailable`, `_failureOf`, 키 상태 기록
- Modify: `lib/presentation/chat/widget/chat_failure_text.dart`
- Modify: `packages/l10n/lib/l10n/app_{ko,en,ja}.arb`
- Modify: 테스트의 모든 `implements ChatModel` 가짜(`grep -rn "implements ChatModel" test` — 지금 `chat_session_test.dart` 의 `_FakeModel` · `_GatedModel` · `_CompleterModel`, 중립 계약 계획이 더한 것 포함)에 `listModels`
- Test: `test/data/chat/anthropic_chat_model_test.dart` · `test/domain/chat/usecase/chat_key_verifier_test.dart`(새) · `test/domain/chat/usecase/chat_session_test.dart` · `test/presentation/chat/widget/chat_failure_text_test.dart`(없으면 새)

**Interfaces:**
- Produces (`chat_model.dart`에 더함 — 스펙 §8.2 모양 그대로, 중립 계약 계획은 이것을 ② 로 넘겼다):
  ```dart
  @freezed
  class ModelInfo with _$ModelInfo {
    @override final String id;
    @override final String displayName;      // 없으면 id
    @override final DateTime? createdAt;
    @override final bool? supportsTools;     // 모르면 null
    @override final bool? supportsImages;
    @override final bool supportsFastMode;   // ② 에서는 늘 false(③)
    @override final List<String> aliases;
    const ModelInfo({required this.id, required this.displayName, this.createdAt,
        this.supportsTools, this.supportsImages, this.supportsFastMode = false, this.aliases = const []});
  }

  @freezed
  sealed class ModelListResult with _$ModelListResult {
    const factory ModelListResult.ok(List<ModelInfo> models) = ModelListOk;
    const factory ModelListResult.invalidKey() = ModelListInvalidKey;
    const factory ModelListResult.unreachable() = ModelListUnreachable;
  }

  abstract interface class ChatModel {
    ChatVendor get vendor;
    Stream<ModelEvent> stream(ModelRequest request);
    /// 키 확인 겸 목록(§4 · §6.3). 예외를 던지지 않는다 — 실패는 결과 값.
    Future<ModelListResult> listModels(String apiKey);
  }
  ```
- Produces (`AnthropicChatModel.listModels`):
  - `GET https://api.anthropic.com/v1/models?limit=1000`, 헤더는 `stream` 과 같은 `x-api-key` · `anthropic-version` 상수. 시간 상한 `listTimeout`(기본 10초, `withTimeouts(…, listTimeout:)` 로 바꿀 수 있게).
  - 2xx → `data` 배열에서 `id`(String 아니면 건너뜀) · `display_name`(없으면 id) · `created_at`(`DateTime.tryParse`) → `ModelInfo(supportsTools: true, supportsImages: true)`(스펙 §10.1 "Claude 목록 전부 채팅 · 도구 · 이미지"). 본문이 JSON 이 아니거나 `data` 가 없으면 `ok(const [])`(키는 맞다).
  - 401 · 403 → `invalidKey()`. 그 밖 상태 · `SocketException` · `ClientException` · `TimeoutException` → `unreachable()`. 오류 본문은 읽지 않고 버린다(`drain`).
- Produces (스트림 오류 매핑 — §10.2 원칙: 오류 본문은 `error.type` 하나만):
  ```dart
  /// 오류 응답에서 error.type 만 꺼낸다. 16KB · 2초를 넘거나 JSON 이 아니면 null. 나머지는 버린다.
  static Future<String?> _errorType(http.StreamedResponse response);

  static ChatModelErrorKind _kindFor(int status, String? type) => switch ((status, type)) {
    (_, 'authentication_error' || 'permission_error') || (401 || 403, _) => invalidKey,
    (_, 'billing_error') || (402, _) => quotaExceeded,            // K2
    (_, 'not_found_error') || (404, _) => modelUnavailable,
    (_, 'rate_limit_error') || (429, _) => rateLimited,
    (_, 'overloaded_error') || (529, _) => overloaded,
    _ => server,
  };
  ```
  (패턴은 Dart 문법에 맞게 풀어 쓴다 — 우선순위: `error.type` → 상태 코드.)
- Produces (`chat_key_verifier.dart`):
  ```dart
  /// 키 확인(모델 목록 호출). 원문 키를 읽는 두 곳 중 하나.
  @injectable
  class ChatKeyVerifier {
    ChatKeyVerifier(this._model, this._settings);

    static const timeout = Duration(seconds: 10);

    /// 저장 전 확인. 던지지 않는다 — 예외 · [timeout] 초과는 unreachable.
    /// [vendor] 가 모델 어댑터의 벤더와 다르면 ArgumentError(② 는 Claude 하나, ④ 에서 레지스트리로).
    Future<ModelListResult> verify(ChatVendor vendor, String key);

    /// 저장된 연결이 unverified 면 저장된 키로 확인해 valid/invalid 를 기록한다(§4 끝 줄).
    /// 기록한 새 상태, 아무것도 안 했으면 null. 동시에 불리면 진행 중인 확인을 같이 기다린다.
    Future<ChatKeyStatus?> recheckIfUnverified();
  }
  ```
  ② 는 목록 내용을 버린다(캐시는 ③). 결과 값을 그대로 돌려줘 ③ 이 받아 쓰게 한다.
- Produces (`chat_session.dart`):
  ```dart
  enum ChatFailure { noKey, invalidKey, quotaExceeded, modelUnavailable, rateLimited, overloaded, network, refused, tooManySteps, unknown }
  ```
  `_failureOf`: `quotaExceeded` → `ChatFailure.quotaExceeded`, `modelUnavailable` → `ChatFailure.modelUnavailable`(중립 계약 계획의 임시 `unknown` 을 바꿈). 키 상태(§7.3): `invalidKey` 실패를 낼 때 `setKeyStatus(invalid)`, 질문이 `finished` 로 끝날 때 `setKeyStatus(valid)` — 둘 다 기다리지 않고 오류를 삼킨다(`unawaited(Future.sync(…).catchError((Object _) {}))`, 사용량 기록과 같은 모양). `stale()` 이면 기록하지 않는다.

**l10n 새 키**(ko / en / ja):
| 키 | ko | en | ja |
|---|---|---|---|
| `walkChatFailureQuotaExceeded` | 크레딧이 부족해요. 결제 상태를 확인해 주세요 | You're out of credits. Check your billing | クレジットが不足しています。請求状況を確認してください |
| `walkChatFailureModelUnavailable` | 지금 모델을 쓸 수 없어요. 잠시 뒤 다시 물어봐 주세요 | This model isn't available right now. Try again later | 現在このモデルは使えません。しばらくしてからもう一度質問してください |

`@` description: "채팅 실패 말풍선: 결제 · 크레딧 부족(키는 맞음)" · "채팅 실패 말풍선: 모델 없음 · 권한 없음. ③ 에서 '모델을 바꿨어요' 로 바뀜".

- [ ] **Step 1: 실패하는 테스트**
  - `anthropic_chat_model_test.dart`(가짜 `http.Client` — 지금 파일 방식):
    - `listModels 200 은 ok 이고 id · 표시 이름 · 만든 시각을 읽는다` — `{"data":[{"id":"claude-sonnet-x","display_name":"Claude Sonnet X","created_at":"2026-10-01T00:00:00Z"}],"has_more":false}`.
    - `listModels 는 GET /v1/models?limit=1000 에 키 헤더를 싣는다` — 요청 URL · 메서드 · `x-api-key` · `anthropic-version`.
    - `listModels 401 · 403 은 invalidKey` · `500 · 429 · 529 는 unreachable` · `SocketException · 시간 초과는 unreachable`(`listTimeout: 10ms`).
    - `listModels 200 인데 본문이 JSON 이 아니면 ok(빈 목록)` · `id 가 없는 항목은 건너뛴다`.
    - `stream 오류: error.type billing_error 는 quotaExceeded` · `402 는 quotaExceeded` · `not_found_error · 404 는 modelUnavailable` · `400 invalid_request_error 는 server` · `401 은 본문 없이도 invalidKey`.
    - `오류 본문의 message 는 예외에 없다` — 본문 `{"error":{"type":"billing_error","message":"sk-ant-secret …"}}` → `ChatModelException.toString()` 에 `secret` · `message` 없음.
    - `오류 본문이 16KB 를 넘으면 type 을 읽지 않고 상태 코드로 판정한다`.
  - `chat_key_verifier_test.dart`(가짜 모델 · `FakeChatSettings`):
    - `verify 는 모델 결과를 그대로 준다`(ok · invalidKey · unreachable).
    - `verify 는 모델이 던지거나 10초를 넘기면 unreachable` — `fakeAsync` 로 시간 진행.
    - `verify 는 다른 벤더면 ArgumentError`.
    - `recheckIfUnverified: unverified + ok → valid 기록` · `+ invalidKey → invalid` · `+ unreachable → 그대로, null` · `valid · invalid · 미연결이면 모델을 부르지 않고 null` · `동시에 두 번 불러도 모델은 한 번`.
  - `chat_session_test.dart`:
    - `quotaExceeded · modelUnavailable 예외는 같은 이름의 ChatFailure` — 기존 오류 매핑 그룹에 두 줄.
    - `invalidKey 로 실패하면 키 상태를 invalid 로 기록한다` · `질문이 끝나면 valid 로 기록한다` · `상태 기록이 던져도 답은 그대로` · `리셋된 질문은 기록하지 않는다`.
  - `chat_failure_text_test.dart`: 새 두 값의 ko 문구.
- [ ] **Step 2: 실행해 실패 확인** — `cd apps/walk && flutter test test/data/chat test/domain/chat test/presentation/chat` → FAIL.
- [ ] **Step 3: 구현** — 위 Interfaces. 가짜 `ChatModel` 에 `listModels` 추가(`ok(const [])` 반환). `chat_failure_text.dart` 의 switch 에 두 줄. build_runner(Freezed · `injection.config.dart`).
- [ ] **Step 4: l10n** — 세 arb 에 키 추가, `cd packages/l10n && flutter gen-l10n`.
- [ ] **Step 5: 통과 확인** — `cd apps/walk && flutter analyze && flutter test` → PASS.
- [ ] **Step 6: 커밋** — `feat(walk): 물어보기 키 확인 호출과 크레딧 부족 · 모델 없음 실패를 더한다`

### Task 3: 벤더 로고 `ChatVendorIcon`

스펙 §6.1 · Q9 · §10.3-3. 다른 task 와 파일이 겹치지 않는다(Task 1 · 2 와 병렬 가능). 구현 전 확인 **K1** 이 끝나지 않았으면 모노그램만으로 끝낸다.

**Files:**
- Create: `lib/presentation/chat/widget/chat_vendor_icon.dart` — `ChatVendorIcon` · `ChatVendorLogo` · `chatVendorName`
- Modify: `apps/walk/pubspec.yaml` — `flutter_svg: ^2.3.0`(pub cache 에 2.3.0 있음) → 저장소 루트에서 `flutter pub get`. K1 이 확인되면 `assets: - assets/chat/vendors/` 와 `assets/chat/vendors/anthropic.svg`
- Modify: `packages/l10n/lib/l10n/app_{ko,en,ja}.arb`
- Test: `test/presentation/chat/widget/chat_vendor_icon_test.dart`(새)

**Interfaces:**
- Produces:
  ```dart
  /// 공식 로고 자산 하나. 브랜드 가이드 확인(K1)을 마친 것만 [ChatVendorIcon.confirmedLogos] 에 넣는다.
  final class ChatVendorLogo {
    const ChatVendorLogo(this.assetPath, {this.tintable = false});
    final String assetPath;        // 예: 'assets/chat/vendors/anthropic.svg'
    /// 가이드가 단색화를 허용하면 true — colorScheme.onSurface 로 칠해 라이트 · 다크 모두 맞춘다.
    final bool tintable;
  }

  /// 벤더 로고(Q9). 설정 연결 행 · ③ 의 모델 칩이 같이 쓴다.
  /// 로고가 확인 전이거나 자산을 읽지 못하면 벤더 이름 첫 글자 원형(모노그램).
  class ChatVendorIcon extends StatelessWidget {
    const ChatVendorIcon(this.vendor, {this.size, super.key});
    final ChatVendor vendor;
    /// null 이면 IconTheme.of(context).size.
    final double? size;

    /// K1 확인 전에는 비어 있다. 확인 뒤 한 줄씩 더한다.
    static const Map<ChatVendor, ChatVendorLogo> confirmedLogos = {};
  }

  /// 벤더 표시 이름(제품) · 회사 이름. 요금 경고 · 연결 행 · 스낵바가 쓴다.
  String chatVendorName(AppLocalizations l10n, ChatVendor vendor);     // anthropic → 'Claude'
  String chatVendorCompany(AppLocalizations l10n, ChatVendor vendor);  // anthropic → 'Anthropic'
  ```
  `openai` 는 ④ 범위지만 enum 에 이미 있으므로 switch 를 채운다(이름 'GPT' · 'OpenAI' 키도 이 task 에서 넣음 — `vendorOfKey` 가 "GPT 키 같아요"에 쓴다).
- 모노그램: `SizedBox.square(size)` 안 `DecoratedBox(shape: circle, color: colorScheme.secondaryContainer)` + 가운데 `Text(chatVendorName(...)[0])`(`labelLarge`, `onSecondaryContainer`, 글자 크기는 `size * 0.5` 를 `TextStyle.fontSize` 로 — 아이콘 크기에 비례하는 계산이라 토큰 예외). `Semantics(label: chatVendorName)`, 안쪽 `ExcludeSemantics`.
- 로고: `SvgPicture.asset(logo.assetPath, width: size, height: size, colorFilter: logo.tintable ? ColorFilter.mode(onSurface, BlendMode.srcIn) : null, errorBuilder: (_, _, _) => 모노그램)`. 자산 번들은 `DefaultAssetBundle.of(context)` 를 쓴다(테스트에서 바꿀 수 있게).
- 테스트용 주입: `ChatVendorIcon` 에 `@visibleForTesting this.logos` 인자(기본 `confirmedLogos`)를 둬서 테스트가 맵을 넘긴다.

**l10n 새 키**(ko / en / ja 같은 값):
| 키 | ko | en | ja |
|---|---|---|---|
| `walkChatVendorClaude` | Claude | Claude | Claude |
| `walkChatVendorAnthropic` | Anthropic | Anthropic | Anthropic |
| `walkChatVendorGpt` | GPT | GPT | GPT |
| `walkChatVendorOpenAi` | OpenAI | OpenAI | OpenAI |

- [ ] **Step 1: 실패하는 테스트** — `chat_vendor_icon_test.dart`:
  - `확인된 로고가 없으면 모노그램 C 를 그리고 SvgPicture 가 없다`.
  - `size 를 주지 않으면 IconTheme 크기` — `IconTheme(data: IconThemeData(size: 32))` 아래 `tester.getSize == Size(32, 32)`.
  - `로고가 있으면 SvgPicture 를 그 경로로 그린다` — `logos: {anthropic: ChatVendorLogo('assets/chat/vendors/anthropic.svg')}` + `DefaultAssetBundle(bundle: _FakeBundle({'…anthropic.svg': '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1 1"/>'}))` → `SvgPicture` 하나.
  - `자산을 읽지 못하면 모노그램으로` — 빈 `_FakeBundle` → `pumpAndSettle` 뒤 모노그램 'C'.
  - `tintable 이면 onSurface 로 칠한다` — `SvgPicture.colorFilter == ColorFilter.mode(scheme.onSurface, BlendMode.srcIn)`. 아니면 null.
  - `시맨틱 라벨은 벤더 이름` — `find.bySemanticsLabel('Claude')`.
  - `chatVendorName · chatVendorCompany` 두 벤더.
- [ ] **Step 2: 실행해 실패 확인** — `flutter test test/presentation/chat/widget/chat_vendor_icon_test.dart` → FAIL.
- [ ] **Step 3: 구현** — 위 Interfaces. `pubspec.yaml` 에 `flutter_svg` 추가, 루트에서 `flutter pub get`. K1 이 끝났다면 자산 · pubspec 자산 항목 · 맵 한 줄도.
- [ ] **Step 4: l10n** — 세 arb, `cd packages/l10n && flutter gen-l10n`.
- [ ] **Step 5: 통과 확인** — `cd apps/walk && flutter analyze && flutter test` → PASS.
- [ ] **Step 6: 커밋** — `feat(walk): 물어보기 벤더 로고 위젯(확인 전에는 글자 원형)`

### Task 4: 행 하나 glow `RowHighlight`

스펙 §3.2 "glow 모양 · 길이" · Q7. 다른 task 와 파일이 겹치지 않는다(Task 1~3 과 병렬 가능).

**Files:**
- Create: `lib/presentation/settings/widget/row_highlight.dart`
- Test: `test/presentation/settings/widget/row_highlight_test.dart`(새)

**Interfaces:**
- Produces:
  ```dart
  /// 행 하나(AppListTile)를 감싸 "여기를 보세요"를 두 번 짚는다.
  ///
  /// 재생 조건: [play] 가 처음부터 true 이거나 false → true 로 바뀌면 한 번, [replayToken] 이 바뀔 때마다 한 번.
  /// 재생은 둘러싼 라우트의 push 전환이 끝난 뒤(ModalRoute.animation 완료) 다음 프레임에 시작한다.
  /// 애니메이션 줄이기(AppMotion.enabled == false)면 그리지 않는다.
  class RowHighlight extends StatefulWidget {
    const RowHighlight({required this.child, this.play = false, this.replayToken = 0, this.announce, super.key});
    final Widget child;
    final bool play;
    final int replayToken;
    /// 재생을 시작할 때 SemanticsService.announce 로 한 번 읽을 글(보통 행 제목). null 이면 읽지 않음.
    final String? announce;

    /// 한 번 = 켜짐 medium → 유지 long → 꺼짐 medium(= 900ms). 두 번 반복.
    static const repeats = 2;
    static Duration get cycle => AppMotion.medium + AppMotion.long + AppMotion.medium;
  }
  ```
- 그리기: `Stack(children: [Positioned.fill(child: IgnorePointer(child: Padding(horizontal: AppSpacing.sm, child: FadeTransition(key: Key('row-highlight-glow'), opacity: t, child: DecoratedBox(borderRadius: AppRadius.smAll, color: primary.withValues(alpha: .12), border: Border.all(color: primary.withValues(alpha: .6), width: 1.5)))))), child])`. 불투명도 0.12 · 0.6 · 테두리 1.5 는 스펙 값이라 이 파일의 이름 있는 `static const` 로(토큰에 없는 시각 상수 — 예외 사유를 주석에). 크기 · 위치는 움직이지 않는다.
- `t` 는 `AnimationController(duration: cycle * repeats)` + `TweenSequence` 한 주기(0→1 가중치 medium, 1 유지 long, 1→0 medium)를 `repeats` 번 이어 붙인 것. 곡선 `AppMotion.standard`.
- 끄기: 재생 중 `Listener(onPointerDown:)` 로 행을 누르거나, `Scrollable.maybeOf(context)?.position` 이 움직이면(리스너) 지금 값에서 0 으로 `AppMotion.medium` 동안 내리고 멈춘다.
- 행이 화면 밖이면 재생 직전에 `Scrollable.ensureVisible(context, duration: AppMotion.medium)`(애니메이션 줄이기면 `Duration.zero`).

- [ ] **Step 1: 실패하는 테스트** — `row_highlight_test.dart`(`MaterialApp` 에서 버튼으로 `RowHighlight` 를 담은 화면을 push, `opacity()` = `tester.widget<FadeTransition>(find.byKey(Key('row-highlight-glow'))).opacity.value`):
  - `play 가 true 면 push 전환이 끝난 뒤 재생한다` — push 직후 `pump(Duration.zero)` → 0, 전환 시간만큼 pump 한 뒤 `pump(AppMotion.medium)` → 1 에 가까움(>0.95).
  - `두 번 깜빡이고 1.8초 뒤 꺼진다` — 시작 뒤 900ms → <0.05, 900+250ms → >0.95, 1800ms → 0, 이후 `hasRunningAnimations` false.
  - `play 가 false 면 재생하지 않는다` — 2초 동안 늘 0.
  - `play 가 false → true 로 바뀌면 한 번 재생한다` · `replayToken 이 바뀌면 다시 재생한다`.
  - `애니메이션 줄이기면 그리지 않는다` — `MediaQuery(disableAnimations: true)` 아래 늘 0(또는 glow 위젯 없음).
  - `재생 중 행을 누르면 곧바로 꺼진다` — 켜진 상태에서 탭 → `pump(AppMotion.medium)` 뒤 0, 이후 다시 켜지지 않음. 자식의 `onTap` 은 그대로 불림.
  - `재생 중 스크롤하면 곧바로 꺼진다` — `ListView` 안에서 `drag` → 0.
  - `announce 가 있으면 재생 시작에 한 번 읽는다` — `tester.takeAnnouncements()`(또는 `SystemChannels.accessibility` 가짜)로 한 건.
- [ ] **Step 2: 실행해 실패 확인** — `flutter test test/presentation/settings/widget/row_highlight_test.dart` → FAIL.
- [ ] **Step 3: 구현** — 위 Interfaces.
- [ ] **Step 4: 통과 확인** — `cd apps/walk && flutter analyze && flutter test` → PASS.
- [ ] **Step 5: 커밋** — `feat(walk): 설정 행 하나를 두 번 짚는 RowHighlight`

### Task 5: 물어보기 설정 — 연결 행 · 키 대화상자 · 요금 경고

스펙 §1.2 · §6.1(Claude 행) · Q1 · Q4 · Q8. 선행: Task 1~4.

**Files:**
- Modify: `lib/presentation/settings/cubit/chat_settings_cubit.dart` · `chat_settings_state.dart`
- Modify: `lib/presentation/settings/widget/chat_settings_section.dart` — 다시 씀(`highlightConnection` 인자)
- Create: `lib/presentation/settings/widget/chat_key_dialog.dart` — 키 입력 대화상자(지금 `_KeyDialog` 를 옮겨 키움)
- Modify: `lib/presentation/settings/page/chat_settings_page.dart` — `highlightConnection` 인자를 섹션에 넘김
- Modify: `packages/l10n/lib/l10n/app_{ko,en,ja}.arb`
- Modify: `getIt<ChatKeyVerifier>` 를 쓰는 테스트 하네스(`test/presentation/settings/settings_harness.dart` · `test/core/app_test.dart` · 셸 테스트 등 `registerSingleton<ChatSettings>` 를 하는 곳 — `grep -rn "registerSingleton<ChatSettings>" test`)에 가짜 verifier 등록
- Create: `test/support/fake_chat_key_verifier.dart`
- Test: `test/presentation/settings/cubit/chat_settings_cubit_test.dart` · `test/presentation/settings/widget/chat_settings_section_test.dart` · `test/presentation/settings/widget/chat_key_dialog_test.dart`(새) · `test/presentation/settings/page/chat_settings_page_test.dart`(새)

**Interfaces:**
- Produces (cubit):
  ```dart
  /// 저장 전 확인 결과.
  enum ChatKeyCheck { valid, invalid, unreachable }

  class ChatSettingsCubit extends Cubit<ChatSettingsState> {
    ChatSettingsCubit(this._settings, this._verifier);

    /// ② 는 Claude 하나. ④ 가 벤더 시트에서 고른 값으로 바꾼다.
    static const vendor = ChatVendor.anthropic;

    Future<void> load();                                  // connection() — apiKey() 는 부르지 않는다
    /// 입력한 키를 확인만 한다(저장 안 함). trim 해서 보낸다.
    Future<ChatKeyCheck> check(String key);
    /// [check] 결과로 등록한다. valid → ChatKeyStatus.valid, unreachable → unverified, invalid 면 ArgumentError.
    /// 쓰지 못하면 false(기존 연결 그대로). 성공하면 다시 읽는다.
    Future<bool> connect(String key, ChatKeyCheck check);
    /// 끊지 못하면 false.
    Future<bool> disconnect();
  }
  ```
  상태는 Task 1 그대로(`loading` · `connection`). 키 문자열은 상태에 담지 않는다.
- Produces (대화상자):
  ```dart
  /// 대화상자가 닫힌 이유. 취소면 null.
  enum ChatKeyDialogResult { connected, savedUnverified }

  class ChatKeyDialog extends StatefulWidget {
    const ChatKeyDialog({required this.vendor, super.key});
    final ChatVendor vendor;
    /// [context] 위의 ChatSettingsCubit 을 BlocProvider.value 로 넘겨 띄운다.
    static Future<ChatKeyDialogResult?> show(BuildContext context, {required ChatVendor vendor});
  }
  ```
  동작(스펙 §1.2):
  - `AlertDialog` 제목 `walkChatKeyDialogTitle(chatVendorName)`. 입력칸 `Key('chat-key-input')` — 늘 빈 칸으로 열림, `obscureText` 기본 true, `suffixIcon` 보기/숨기기 `IconButton(key: Key('chat-key-visibility'), tooltip: 보기 · 숨기기)`, `autocorrect: false` · `enableSuggestions: false`, 힌트 `'${chatKeyPrefixHint(vendor)}…'`.
  - 접두사 검사(trim 뒤): 비었으면 [저장] 끔(안내 없음). `vendorOfKey(text)` 가 다른 벤더면 [저장] 끄고 `helperText`/`errorText` "{GPT} 키 같아요". 이 벤더가 아니면 [저장] 끄고 "{Claude} 키는 sk-ant- 로 시작해요". 길이는 보지 않는다.
  - [저장] `AppButton.primary(key: Key('chat-key-save'), isLoading: checking)` → `cubit.check(text)` 동안 입력칸 · [취소] 비활성, `PopScope(canPop: !checking)`.
    - `invalid` → 닫지 않고 입력칸 `errorText` "이 키로는 연결되지 않아요"(입력값 유지). 글을 고치면 오류 문구를 지운다.
    - `valid` · `unreachable` → 요금 경고 `AppConfirmDialog.show(title: walkChatCostWarningTitle(name), content: walkChatCostWarningBody(company), confirmLabel: walkChatCostWarningConfirm, isDestructive: false)`. [취소] → 입력 대화상자로(입력값 유지, 아무것도 안 씀). [확인] → `cubit.connect(text, check)`: 성공이면 `pop(valid ? connected : savedUnverified)`, 실패면 닫지 않고 `AppSnackBar.show(walkChatSettingsSaveFailed, type: error)`.
- Produces (섹션):
  ```dart
  class ChatSettingsSection extends StatelessWidget {
    const ChatSettingsSection({this.highlightConnection = false, super.key});
    /// true 면 화면이 열린 뒤 연결 행을 두 번 glow(§3.2).
    final bool highlightConnection;
  }
  ```
  `BlocProvider(create: (_) => ChatSettingsCubit(getIt<ChatSettings>(), getIt<ChatKeyVerifier>())..load())`. 안쪽 뷰는 `StatefulWidget` — 저장 성공 때 올리는 `_replay` 를 들고 있다.
  화면(스펙 §6.1 의 Claude 부분):
  | 상태 | 연결 행 `Key('settings-chat-key')` — `RowHighlight(play: highlightConnection, replayToken: _replay, announce: 행 제목)` 로 감쌈 | 아래 행 |
  |---|---|---|
  | 읽는 중 | 미연결 모양, `onTap: null` | — |
  | 미연결 | `Icons.power_outlined` · `walkChatConnectTitle` · `walkChatConnectDescription` · 오른쪽 `walkChatConnectAction`(`labelLarge`, `colorScheme.primary`). 탭 → 대화상자 | 안내문 |
  | `valid` | `ChatVendorIcon(vendor)` · `chatVendorName` · `keyPreview` · 오른쪽 `Icons.check_circle_outline` + `walkChatKeyStatusValid`(primary) | 키 바꾸기 `Key('settings-chat-change-key')` · 연결 끊기 `Key('settings-chat-delete')` · 안내문 |
  | `unverified` | 같음 · 오른쪽 `walkChatKeyStatusUnverified`(onSurfaceVariant) | 〃 |
  | `invalid` | 같음 · 오른쪽 `Icons.error_outline` + `walkChatKeyStatusInvalid`(error) | 〃 |
  연결됨 상태에서 연결 행 · 키 바꾸기 탭 → 같은 대화상자(Q4: 자동으로 띄우지 않는다). 결과 `connected` → `AppSnackBar`(success) `walkChatConnected(name)`, `savedUnverified` → `AppSnackBar`(info) `walkChatSavedUnverified`, 둘 다 `_replay++`. 연결 끊기 → 지금처럼 `AppConfirmDialog.show`(되돌리기 어려움, 기본 `isDestructive: true`) → 성공이면 `AppSnackBar`(info) `walkChatDisconnected`, 실패면 지금 error 스낵바. 머리글은 지금 `Padding + Text` 대신 `SettingsSectionHeader(l10n.walkChatSettings)`. 미리보기 글자는 고정폭 없이 `bodyMedium`(타이포 토큰에 고정폭이 없음).
- Produces (`ChatSettingsPage({this.highlightConnection = false, super.key})`) — `ChatSettingsSection(highlightConnection: highlightConnection)`.

**l10n**(ko / en / ja). 값 바꿈:
| 키 | ko | en | ja |
|---|---|---|---|
| `walkChatSettings` | AI 연결 | AI connection | AI 接続 |
| `walkChatSettingsChange` | 키 바꾸기 | Change key | キーを変更 |
| `walkChatSettingsDelete` | 연결 끊기 | Disconnect | 接続を解除 |
| `walkChatSettingsDeleteTitle` | 연결을 끊을까요? | Disconnect? | 接続を解除しますか？ |
| `walkChatSettingsDeleteBody` | 이 폰에 저장된 키가 지워져요. 다시 쓰려면 키를 새로 넣어야 해요. (그대로) | (그대로) | (그대로) |
| `walkChatSettingsKeyDialogTitle` | {vendor} API 키 넣기 | Enter {vendor} API key | {vendor} の API キーを入力 |

`walkChatSettingsKeyDialogTitle` 은 자리표시자 `vendor`(String)가 생긴다. `walkChatSettingsKey` · `walkChatSettingsAddKey` 는 참조가 없어지면 세 arb 에서 지운다(`grep -rn` 으로 0 확인).

새 키:
| 키 | ko | en | ja |
|---|---|---|---|
| `walkChatConnectTitle` | AI 연결 | Connect AI | AI を接続 |
| `walkChatConnectDescription` | Claude API 키를 넣으면 물어보기를 쓸 수 있어요 | Add a Claude API key to use Ask | Claude の API キーを入れると質問を使えます |
| `walkChatConnectAction` | 연결하기 | Connect | 接続する |
| `walkChatKeyStatusValid` | 연결됨 | Connected | 接続済み |
| `walkChatKeyStatusUnverified` | 확인 전 | Not verified | 未確認 |
| `walkChatKeyStatusInvalid` | 키를 확인해 주세요 | Check your key | キーを確認してください |
| `walkChatKeyShow` | 키 보기 | Show key | キーを表示 |
| `walkChatKeyHide` | 키 숨기기 | Hide key | キーを隠す |
| `walkChatKeyWrongPrefix` | {vendor} 키는 {prefix} 로 시작해요 | {vendor} keys start with {prefix} | {vendor} のキーは {prefix} で始まります |
| `walkChatKeyOtherVendor` | {vendor} 키 같아요 | This looks like a {vendor} key | {vendor} のキーのようです |
| `walkChatKeyInvalid` | 이 키로는 연결되지 않아요 | This key couldn't connect | このキーでは接続できません |
| `walkChatCostWarningTitle` | {vendor} 키를 등록할까요? | Add this {vendor} key? | {vendor} のキーを登録しますか？ |
| `walkChatCostWarningBody` | 이 API 를 쓰면 {company} 에 요금이 청구될 수 있어요. | Using this API may incur charges from {company}. | この API を使うと {company} から料金が請求されることがあります。 |
| `walkChatCostWarningConfirm` | 확인 | OK | OK |
| `walkChatConnected` | {vendor} 에 연결했어요 | Connected to {vendor} | {vendor} に接続しました |
| `walkChatSavedUnverified` | 키를 저장했어요. 연결되면 확인할게요 | Key saved. We'll verify it once you're online | キーを保存しました。接続できたら確認します |
| `walkChatDisconnected` | 연결을 끊었어요 | Disconnected | 接続を解除しました |

`walkChatConnectDescription` 은 ④ 에서 "Claude · GPT 중 하나의 키를…"로 바뀐다(description 에 적음). en · ja 의 "물어보기" 번역어가 재구성 계획의 `walkShellTabChat`/`walkChatSettingsTitle` 과 다르면 그쪽에 맞춘다.

- [ ] **Step 1: 실패하는 테스트**
  - `chat_settings_cubit_test.dart`(가짜 verifier):
    - `check 는 trim 한 키로 verify 하고 결과를 ChatKeyCheck 로 바꾼다`(ok → valid · invalidKey → invalid · unreachable → unreachable) · `check 는 저장소를 건드리지 않는다`.
    - `connect(valid) 는 valid 로, connect(unreachable) 는 unverified 로 저장하고 다시 읽는다` · `connect(invalid) 는 ArgumentError`.
    - `쓰기 실패면 false 이고 기존 연결 그대로` · `disconnect 성공 · 실패`.
    - `apiKey() 를 부르지 않는다` · `상태 toString 에 원문이 없다`(입력한 키로 connect 한 뒤에도).
  - `chat_key_dialog_test.dart`(cubit 은 실제 + 가짜 settings · verifier, verifier 결과를 `Completer` 로 붙잡을 수 있게):
    - `열 때 입력칸이 비어 있고 가려져 있다` · `보기 버튼을 누르면 보이고 다시 누르면 가린다`.
    - `비었으면 저장이 꺼져 있다` · `sk-proj- 키면 'GPT 키 같아요'와 저장 꺼짐` · `접두사가 다르면 'Claude 키는 sk-ant- 로 시작해요'`.
    - `저장을 누르면 확인하는 동안 로딩이고 입력칸 · 취소가 꺼진다`(Completer 를 끝내기 전).
    - `잘못된 키면 닫히지 않고 '이 키로는 연결되지 않아요', 입력값이 남고 저장소에 쓰지 않는다`.
    - `정상 키면 요금 경고가 뜨고 [확인]이면 저장 후 connected 로 닫힌다` — 경고 본문에 'Anthropic 에 요금이 청구될 수 있어요'.
    - `확인 못 함이어도 요금 경고가 뜨고 [확인]이면 unverified 로 저장, savedUnverified`(Q8).
    - `요금 경고 [취소]면 저장하지 않고 입력 대화상자로 돌아온다(입력값 유지)`.
    - `쓰기가 실패하면 닫지 않고 '키를 저장하지 못했어요'`.
  - `chat_settings_section_test.dart`(기존을 새 모습으로 옮김):
    - `미연결이면 'AI 연결' · 설명 · '연결하기'가 보이고 키 바꾸기 · 연결 끊기 행이 없다`.
    - `valid 면 모노그램 C · 'Claude' · 마스킹 키 · '연결됨'` · `unverified 면 '확인 전'` · `invalid 면 '키를 확인해 주세요'(오류 색)`.
    - `키를 넣어 정상이면 '…Claude 에 연결했어요' 스낵바와 연결 행 glow 가 한 번 재생된다`(glow 불투명도 > 0 을 한 번 관찰).
    - `확인 못 함으로 저장하면 info 스낵바 '키를 저장했어요. 연결되면 확인할게요'와 '확인 전'`.
    - `연결 끊기를 확인하면 지우고 '연결을 끊었어요'` · 기존 `저장 · 지우기 실패 스낵바` 두 건 유지.
    - `highlightConnection 이 true 면 열린 뒤 연결 행이 glow, 기본은 없다`.
    - `읽는 중에는 연결 행을 누를 수 없다`.
  - `chat_settings_page_test.dart`(새): `highlightConnection 을 섹션에 넘긴다`(`tester.widget<ChatSettingsSection>(…).highlightConnection`).
- [ ] **Step 2: 실행해 실패 확인** — `cd apps/walk && flutter test test/presentation/settings` → FAIL.
- [ ] **Step 3: 구현** — 위 Interfaces. 하네스들에 `FakeChatKeyVerifier`(결과를 테스트가 정함, 기본 `ok(const [])`, 호출 기록) 등록. build_runner.
- [ ] **Step 4: l10n** — 값 바꿈 · 새 키 · 안 쓰는 키 삭제, `cd packages/l10n && flutter gen-l10n`.
- [ ] **Step 5: 통과 확인** — `cd apps/walk && flutter analyze && flutter test` → PASS(`open_settings_test` 의 `settings-chat-key` 검사 포함).
- [ ] **Step 6: 커밋** — `feat(walk): 물어보기 설정에서 키를 확인 · 요금 경고 뒤 등록하고 연결 상태를 보인다`

### Task 6: 강조 열기 · 실패 말풍선 [설정 열기] · 돌아오면 다시 읽기

스펙 §3 · §4 끝 줄 · Q2 · Q5 · Q7. 선행: Task 2 · 4 · 5. 시작할 때 K5(재구성 셸 · `ToolsTab` 실제 이름)를 `grep` 으로 맞춘다.

**Files:**
- Modify: `lib/presentation/settings/open_settings.dart` — `highlight` 인자
- Modify: `lib/presentation/settings/page/alarm_settings_page.dart` — `highlightPermissions` · `AlarmPermissionTiles(highlight:)`
- Modify: `lib/presentation/shell/page/main_shell_page.dart` — 물어보기 [설정 열기] · 알람 권한 배너 콜백에 `highlight: true`(⋮ · 앱 설정에서 여는 길은 그대로 false)
- Modify: `lib/presentation/chat/page/chat_tab.dart` — 말풍선에 `onOpenSettings` 전달 · 설정 화면에서 돌아오면 다시 읽기(`RouteAware`)
- Modify: `lib/presentation/chat/widget/chat_bubble_view.dart` — 실패 문구 아래 [설정 열기]
- Modify: `lib/presentation/chat/cubit/chat_cubit.dart` — `ChatKeyVerifier` 를 받아 `refresh()` 에서 확인 전 키 다시 확인
- Modify: `lib/presentation/alarm/widget/alarm_permission_banner.dart` — doc 주석("설정 탭으로 간다" → "알람 설정 화면을 열고 권한 행을 짚는다")
- Test: `test/presentation/settings/open_settings_test.dart` · `test/presentation/settings/page/alarm_settings_page_test.dart` · `test/presentation/shell/page/main_shell_page_test.dart` · `test/presentation/chat/page/chat_tab_test.dart` · `test/presentation/chat/widget/chat_bubble_view_test.dart`(중립 계약 계획이 만들었으면 거기에, 없으면 새) · `test/presentation/chat/cubit/chat_cubit_test.dart`

**Interfaces:**
- Produces:
  ```dart
  /// [highlight] 가 true 면 열린 화면이 봐야 할 행을 glow 한다 — chat: 연결 행, alarm: 조치가 필요한 첫 권한 행.
  /// 다른 target 에서는 무시한다.
  Future<void> openSettings(BuildContext context, SettingsTarget target, {bool highlight = false});
  ```
  `SettingsTarget.chat => pushLocked(ChatSettingsPage(highlightConnection: highlight))`, `SettingsTarget.alarm => push(AlarmSettingsPage(highlightPermissions: highlight))`.
- Produces (알람):
  ```dart
  class AlarmSettingsPage extends StatefulWidget {
    const AlarmSettingsPage({this.highlightPermissions = false, super.key});
    final bool highlightPermissions;
  }
  class AlarmPermissionTiles extends StatelessWidget {
    const AlarmPermissionTiles({this.highlight = false, super.key});
    /// true 면 조치가 필요한(needs action) 첫 행 하나를 RowHighlight(play: true) 로. 순서: 알림 → 정확한 알람 → 전체 화면.
    /// 상태를 아직 못 읽었으면 play false 로 두었다가 읽히면 true(RowHighlight 가 false → true 에서 재생). 모두 허용이면 없음.
    final bool highlight;
  }
  ```
  `SettingsPermissionTile` 에 `Key('settings-permission-notification|exact-alarm|full-screen')` 를 단다(테스트가 행을 찾게 — 기존 키 없음).
- 셸(재구성 뒤 모양에 맞춰): `ChatTab(onOpenSettings: () => openSettings(ctx, SettingsTarget.chat, highlight: true))`, 알람 권한 배너로 가는 콜백(`ToolsTab.onOpenAlarmSettings` → `AlarmListPage.onOpenSettings`)에 `() => openSettings(ctx, SettingsTarget.alarm, highlight: true)`. `FeatureMenu` · 앱 설정의 "기능별 설정" 행은 고치지 않는다(강조 없음). 콜백 타입은 `VoidCallback` 그대로(스펙 §3.2).
- 물어보기 탭:
  - `ChatBubbleView({…, this.onOpenSettings})` — `final VoidCallback? onOpenSettings;`. `failure` 가 `noKey` · `invalidKey` · `quotaExceeded` 이고 콜백이 있으면 실패 문구 아래(`AppSpacing.xs`) `AppButton.text(key: Key('chat-bubble-open-settings'), label: l10n.walkChatOpenSettings, onPressed: onOpenSettings)`. 다른 실패에는 없음.
  - `_BubbleList` · `_ChatBody` 가 `onOpenSettings` 를 말풍선까지 넘긴다.
  - **돌아오면 다시 읽기**: `_ChatTabState` 가 `RouteAware` 로 `appRouteObserver` 에 구독(셸 · `StoryViewerPage` 와 같은 방식, `didChangeDependencies` 에서 subscribe · `dispose` 에서 unsubscribe). `didPopNext` 에서 `widget.active` 면 `_cubit.refresh()`. 이 경로는 [설정 열기] · 실패 말풍선 · ⋮ › 물어보기 설정 · 앱 설정 모두를 덮는다(지금은 탭이 다시 보일 때만 읽는다 — 설정이 push 화면이 되며 생긴 빈틈).
- `ChatCubit(this._session, this._settings, this._diary, this._trace, this._verifier, {…})`(중립 계약 계획의 생성자 뒤에 `ChatKeyVerifier` 를 더함 — 실제 순서는 그때 코드에 맞춤). `refresh()`: `hasApiKey()` 로 access 를 정한 뒤 `ready` 면 `unawaited(_verifier.recheckIfUnverified().catchError((Object _) => null))`(§4 "확인 전 키는 물어보기 탭이 열릴 때 다시 확인"). 결과는 화면에 쓰지 않는다(설정 화면이 상태를 보여 줌). `chat_tab.dart` 의 생성에 `getIt<ChatKeyVerifier>()`.

- [ ] **Step 1: 실패하는 테스트**
  - `open_settings_test.dart`:
    - `chat 을 highlight 로 열면 연결 행이 glow 한다` · `highlight 없이 열면 glow 가 없다`(glow 불투명도를 2초 동안 관찰).
    - `alarm 을 highlight 로 열면 거부된 첫 권한 행만 glow` — 알림 허용 · 정확한 알람 거부 → `settings-permission-exact-alarm` 안의 glow 만 > 0.
    - `alarm 권한이 모두 허용이면 highlight 여도 glow 없음`.
    - `walk · app · diary 는 highlight 를 무시한다`(던지지 않음).
  - `alarm_settings_page_test.dart`: `권한을 읽기 전 열려도 읽힌 뒤 거부된 행이 glow` · `highlightPermissions 기본 false`.
  - `chat_bubble_view_test.dart`: `invalidKey · noKey · quotaExceeded 실패면 [설정 열기], 누르면 콜백` · `network · modelUnavailable · unknown 등에는 없다` · `콜백이 null 이면 없다`.
  - `chat_tab_test.dart`:
    - `잘못된 키로 실패하면 말풍선의 [설정 열기]가 onOpenSettings 를 부른다`.
    - `설정 화면에서 돌아오면 키 상태를 다시 읽는다` — `appRouteObserver` 를 단 `MaterialApp` 에서 noKey 로 시작 → 위에 빈 라우트 push → 가짜 settings 에 키 넣기 → pop → `ready`(동의 있음) 화면.
    - `탭이 보이지 않을 때 돌아오면 다시 읽지 않는다`(`active: false` → 가짜 `hasApiKeyCalls` 변화 없음).
  - `chat_cubit_test.dart`: `refresh 가 ready 면 확인 전 키 재확인을 부른다` · `noKey 면 부르지 않는다` · `재확인이 던져도 refresh 는 끝난다`.
  - `main_shell_page_test.dart`(재구성 테스트에 덧붙임):
    - `물어보기 [설정 열기] → 물어보기 설정 화면이 열리고 연결 행이 glow`.
    - `알람 권한 배너 → 알람 설정 화면의 거부된 권한 행이 glow, 돌아오면 권한을 다시 읽는다`(재구성 테스트의 뒷부분 유지).
    - `⋮ › 물어보기 설정으로 열면 glow 가 없다`.
- [ ] **Step 2: 실행해 실패 확인** — `cd apps/walk && flutter test test/presentation/settings test/presentation/chat test/presentation/shell` → FAIL.
- [ ] **Step 3: 구현** — 위 Interfaces. `grep -rn "\.apiKey()" lib` 결과가 `chat_session.dart` · `chat_key_verifier.dart` 둘뿐인지 확인.
- [ ] **Step 4: 통과 확인** — `cd apps/walk && flutter analyze && flutter test` → PASS.
- [ ] **Step 5: 커밋** — `feat(walk): 물어보기 · 알람 배너에서 설정을 열면 봐야 할 행을 짚는다`

### Task 7: 문서

CLAUDE.md "진행 상태는 status.md 에만" · feature 완료 시 history · testing 갱신. 스펙 §10.3 "확인 결과를 history 에".

**Files:**
- Modify: `apps/walk/docs/status.md` · `apps/walk/docs/history.md` · `apps/walk/docs/testing.md` · `apps/walk/docs/plan.md`
- Modify: `docs/superpowers/specs/2026-11-01-walk-chat-key-input.md` — 머리 "상태"를 "② 구현됨(…)"으로 한 줄, 그 밖 본문은 고치지 않는다(아래 "결정"과 어긋나는 곳은 history 에만 적는다)

- [ ] **Step 1: `status.md`** — "물어보기" 절 체크 항목:
  - `[x]` 키 UX(키 기획 ②): 저장 시 키 확인 · 요금 경고(확인 못 함 포함) · 마스킹 미리보기 · 연결 상태(연결됨 · 확인 전 · 키 확인) · 연결 행 glow · 강조 열기(물어보기 · 실패 말풍선 · 알람 배너) · 크레딧 부족 · 모델 없음 문구 · 보안 저장소 백업 제외
  - `[ ]` Anthropic 로고 자산(K1 결과에 따라 — 확인 전이면 "모노그램으로 대신 중")
  - `[ ]` 기기 확인: 실제 키로 연결 · 잘못된 키 · 비행기 모드 저장(확인 전 → 다음 탭 열 때 연결됨) · 백업 복원 뒤 미연결(K4)
  - 검증 줄: `flutter analyze` 0 · `flutter test` N건 통과(실행해 숫자). "다음 할 일"에 키 기획 ③(모델 목록 · 칩).
- [ ] **Step 2: `history.md`** — 새 절 `## 2026-11-xx — 물어보기 키 UX(키 기획 ②)`: 아래 "결정" 표(이유 포함), 구현 전 확인 K1~K5 결과(날짜 · 출처, 못 한 것은 "대기"), 막힌 것.
- [ ] **Step 3: `testing.md`** — "물어보기" 표에 행 추가 · 수정: `domain/chat/api_key_mask_test` · `chat_connection_test` · `usecase/chat_key_verifier_test` · `data/chat/secure_chat_settings_test`(이전 · 읽기 정리 · 원자적 connect) · `anthropic_chat_model_test`(listModels · 오류 type 매핑) · `presentation/chat/widget/chat_vendor_icon_test` · `chat_bubble_view_test`([설정 열기]) · `presentation/settings/widget/row_highlight_test` · `chat_key_dialog_test` · `chat_settings_section_test` · `page/chat_settings_page_test`. 맨 위 건수 갱신. "물어보기 기기 시나리오"에 위 Step 1 의 기기 확인 네 가지를 "대기"로.
- [ ] **Step 4: `plan.md`** — "물어보기 (채팅)" 절: 연결 = 벤더 하나(지금 Claude) · 키는 보안 저장소 `chat.apiKey` 에만(백업 제외) · 화면은 `벤더 접두사 + 4글자 + ••••` 만 · 저장 전 `GET /v1/models` 로 확인 → 요금 경고 → 등록 · 설정을 열 때 봐야 할 행 glow. "Claude 와 주고받는 형식"에 오류 매핑 한 줄(`error.type` 만 읽음: billing → 크레딧 부족, not_found → 모델 없음).
- [ ] **Step 5: 링크 검사** — `cd apps/trader && flutter test test/convention` → PASS.
- [ ] **Step 6: 커밋** — `docs(walk): 물어보기 키 UX 반영`

---

## 결정

이 계획을 쓰며 정한 것(스펙끼리 어긋나거나 스펙이 비워 둔 곳). Task 7 이 `history.md` 로 옮긴다.

| # | 결정 | 이유 |
|---|---|---|
| D1 | ② 에서는 벤더 시트 없이 [연결하기]가 곧바로 Claude 키 대화상자를 연다. 미연결 설명은 "Claude API 키를 넣으면…"(④ 에서 "Claude · GPT 중 하나…"로) | 스펙 §5.1 의 벤더 시트는 ④ 범위. 한 벤더뿐인 시트는 단계만 하나 늘린다 |
| D2 | `ChatSettings` 는 §7.1 중 ② 몫(`connection` · `hasApiKey` · `apiKey` · `connect` · `disconnect` · `setKeyStatus`)만. `consented` 는 bool 그대로, `selectedModel` · `fastMode` 는 ③, `consentedVendor` 는 ④ | 단계마다 계약을 그 단계가 쓰는 만큼만 넓힌다. 저장 키 이전도 ② 몫(`anthropic_api_key` → `chat.apiKey`)만 |
| D3 | `ChatConnection` · `ChatKeyStatus` 는 `chat_settings.dart` 가 아니라 `lib/domain/chat/chat_connection.dart` | 중립 계약 계획이 `ChatVendor` 를 따로 둔 것(P7)과 맞춤. 테스트 · 화면이 계약 전체를 끌어오지 않게 |
| D4 | 키 확인은 새 domain 유스케이스 `ChatKeyVerifier`(10초 상한 · 예외 → unreachable · 확인 전 재확인)로 한 곳에 | 스펙은 "모델 목록 호출로 확인"만 정했다. 원문 키를 읽는 곳을 `ChatSession` · 이것 둘로 묶고(스펙 §2.2 의 "모델 목록 갱신"), ③ 의 카탈로그 갱신 · ④ 의 벤더 레지스트리가 같은 자리에 붙는다 |
| D5 | ② 의 `listModels` 는 판정만 쓰고 목록은 버린다(캐시 · 페이지 넘기기 · 기본 모델은 ③) | 스펙 §4 "한 번 호출로 두 가지"의 두 번째는 ③ 이 카탈로그를 만들 때 붙인다 |
| D6 | 저장 전 확인 결과를 화면 쪽 enum `ChatKeyCheck`(valid · invalid · unreachable)로 줄이고, 키 문자열은 cubit 메서드 인자로만 지나간다 | 대화상자 → 경고 → 저장 사이에 원문을 상태(`toString` 에 찍힘)로 들고 있지 않기 위해 |
| D7 | 마스킹 접두사: Anthropic 은 `sk-ant-api<숫자>-` 정규식, `sk-ant-` 의 다른 종류(관리 키 등)는 "Claude 키 아님" | 스펙 §10.1 "`sk-ant-<종류><번호>-` 모양" + OpenAI 옛 `sk-` 접두사와 겹치지 않게. 본문 4글자 미만이면 접두사 + `••••`(스펙이 비워 둔 경우 — 짧은 키를 통째로 보이지 않게) |
| D8 | 모델 없음 문구는 ② 에서 "지금 모델을 쓸 수 없어요. 잠시 뒤…", ③ 에서 "모델을 바꿨어요. 다시 물어봐 주세요"로 바꾼다 | 스펙 §6.3 문구는 카탈로그가 기본 모델로 되돌린다는 전제(③). ② 는 모델 id 가 고정이라 바꿔 줄 수 없다 |
| D9 | Anthropic 오류 매핑은 `error.type` 우선 · 상태 코드 보조, 본문은 16KB · 2초 상한으로 `type` 한 필드만 | 스펙 §10.2 원칙 고침을 Anthropic 에도 적용. 크레딧 부족 모양이 확인 안 됐으므로(K2) `billing_error` · 402 둘 다 받는다 |
| D10 | 알람 권한 glow 대상은 "조치가 필요한 첫 권한 행 하나"(알림 → 정확한 알람 → 전체 화면) | Q7 "행 하나"인데 알람 권한 행은 셋이다. 배너가 뜨는 이유인 거부된 행을 짚는 게 맞다 |
| D11 | `RowHighlight` 는 `play`(첫 진입) 외에 `replayToken`(저장 성공 뒤 다시) 인자를 둔다. `play` 가 false → true 로 바뀌어도 재생 | 스펙 §1.2 "성공 뒤 연결 행 glow" 와 §3.2 "`play: bool`" 을 한 위젯으로. 알람 권한 상태가 늦게 읽혀도 짚을 수 있게 |
| D12 | 물어보기 탭은 `RouteAware`(`appRouteObserver`)의 `didPopNext` 로 설정에서 돌아올 때 다시 읽는다. `onOpenSettings` 는 `VoidCallback` 그대로 | 설정이 push 화면이 되며 탭 전환이 없어져 지금의 "보일 때 다시 읽기"가 불리지 않는다. 콜백을 `Future` 로 바꾸면 ⋮ 경로를 못 덮고 스펙 §3.2("`VoidCallback` 그대로")와도 어긋난다 |
| D13 | 로고는 K1 확인 전까지 모노그램. 자산 경로 · 단색화 여부는 `ChatVendorIcon.confirmedLogos` 한 곳, 자산 파일과 pubspec 항목은 확인 뒤에만 | Q9 "공식 로고"와 §10.3-3 "가이드 확인 먼저"를 둘 다 지키면서 코드가 막히지 않게. 확인 안 된 로고를 커밋하지 않는다 |
| D14 | 연결 행 미리보기는 고정폭 글꼴 없이 `bodyMedium` | 스펙 §6.1 "(고정폭)"을 따르려면 글꼴 이름을 하드코딩해야 하는데 타이포 토큰에 고정폭이 없다. 필요하면 토큰을 먼저 만든다 |
| D15 | 연결 끊기 확인 창은 `isDestructive: true`(기본) 그대로, 요금 경고만 `false` | 키를 지우면 다시 넣어야 하므로 되돌리기 어렵다(CLAUDE.md). 요금 경고는 진행을 확인하는 창(스펙 §1.2) |
