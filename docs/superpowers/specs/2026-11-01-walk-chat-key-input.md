# walk 물어보기 — AI 연결(키 입력 · 멀티 벤더: Claude · GPT) 개선 (수정 기획)

> **화면 재구성 먼저**: [하단 탭 재구성 · 설정 분산 설계](2026-11-01-walk-nav-regroup-design.md)(커밋 `c421e70f`)로
> **설정 탭이 없어진다.** 이 기획의 "설정"은 모두 그 설계의 **물어보기 설정 화면**(⋮ › 물어보기 설정, push 화면, 화면 전체가 일기 잠금 아래)과
> **알람 설정 화면**을 뜻한다. 재구성이 먼저 들어가고 이 기획의 ② 단계는 그 뒤다(§14).

- 날짜: 2026-11-01 (같은 날 세 번 개정: 열린 질문 Q1~Q15 결정 반영 · 멀티 벤더 범위 추가 · Grok 은 후속 단계로 · 설정 탭 삭제에 맞춤)
- 범위: 물어보기 설정 화면의 AI 연결(벤더 · 키 · 모델) · 표시 · 교체 · 삭제, 물어보기 · 알람 → 설정 화면 이동 안내(행 glow),
  물어보기 탭 모델 칩(빠른 출력 모드 포함), **벤더 중립 채팅 계약과 벤더별 어댑터**, 요청별 토큰 사용량 이벤트.
  MVP 벤더는 **Claude · GPT**. Grok 은 후속 단계(⑤)
- 상태: ① 구현됨 · ② 구현됨(키 UX — 2026-11-02, [기록](../../../apps/walk/docs/history.md#2026-11--물어보기-키-ux키-기획-)). ③ · ④ 구현됨(모델 칩 · GPT — 2026-11-02, [기록](../../../apps/walk/docs/history.md#2026-11--물어보기-모델-칩--gpt키-기획---) · 구현 전 확인은 대기). ⑤ 는 기획만
- 관련: [물어보기 설계](2026-10-27-walk-life-chat-design.md) ·
  [대화 기록 · 위키 기획](2026-11-01-walk-chat-history-wiki.md)(§8 중립 계약 · §9 사용량 이벤트를 참조, 사용량 저장을 맡음) ·
  [체감 속도 기획](2026-11-01-walk-chat-streaming-ux.md)(진행 이벤트 · 중단을 정함, §8.2 의 자리 표시) ·
  [화면 재구성 설계](2026-11-01-walk-nav-regroup-design.md)(설정 탭 삭제 · 설정 push 화면 · 앱바 ⋮) ·
  [walk 계획](../../../apps/walk/docs/plan.md) · [walk 상태](../../../apps/walk/docs/status.md)

사용자가 써보며 말한 불편 세 가지에서 시작했다.

1. 키를 넣어도 화면이 거의 안 바뀌어서 저장됐는지 모르겠다.
2. 키가 안전한 저장소에 있는가. 저장한 뒤에는 앞부분만 보이고 뒷부분은 아예 드러나지 않아야 한다.
3. 물어보기에서 설정으로 넘어가도 어느 섹션을 봐야 하는지 눈에 안 띈다. 해당 섹션을 glow 로 짚어 주고 싶다.
   (설정 탭이 없어진 뒤에는 "바로 그 설정 화면을 열고, 봐야 할 행을 glow" 로 바뀐다 — §3.)

그 뒤 범위가 **멀티 벤더** 로 넓어졌다(§5~§10). 구현 단계는 §14.

경로는 모두 `apps/walk/` 기준이다. "(확인 필요)" 는 구현 때 그 벤더의 현재 문서로 다시 확인할 항목이다 — 한데 모은 목록은 §10.3.

---

## 결정

| # | 질문 | 결정 |
|---|---|---|
| Q1 | 저장 시 키 확인 | **한다.** 벤더 모델 목록 호출로 확인. **정상 키면 등록 전에 요금 경고 확인 창**("이 API 를 쓰면 ○○ 에 요금이 청구될 수 있어요") — [확인]을 눌러야 등록. 잘못된 키는 저장 안 함 |
| Q2 | 알람 권한 배너 → 권한 강조 | **넣는다** — 설정 탭이 없어졌으므로 **알람 설정 화면을 push 하고 권한 행을 glow** |
| Q3 | 마스킹 | **벤더별 공개 접두사 + 본문 4글자 + `••••`(고정)** |
| Q4 | 키 없음으로 왔을 때 입력 대화상자 자동 표시 | **안 띄운다** |
| Q5 | 물어보기 탭은 원문 대신 `hasApiKey()` | **바꾼다** |
| Q6 | 보안 저장소 파일 Android 백업 제외 | **뺀다** |
| Q7 | glow 반복 | **두 번 ≈ 2초.** 대상은 섹션이 아니라 **행 하나**(물어보기 설정의 연결 행 · 알람 설정의 권한 행) |
| Q8 | "확인 못 함"으로 저장할 때도 요금 경고 | **띄운다** |
| Q9 | 벤더 아이콘 | **공식 로고(SVG 자산).** 각 벤더 브랜드 가이드 확인을 구현 전 확인 항목에(§10.3), 자산 위치와 `ChatVendorIcon` 한 곳에서 관리 |
| Q10 | 도구 · 이미지 미지원 모델 | **도구 미지원은 목록에서 제외. 이미지 미지원은 남기고 "사진은 못 봐요" 표시 + 사진 도구를 빼고 보냄** |
| Q11 | 추천 계열 | **Claude 는 Sonnet 계열, GPT 는 플래그십** |
| Q12 | 벤더 범위 | **MVP 는 Claude + GPT.** Grok 은 후속 단계 — 벤더 선택 화면에 보이지 않는다. 후속 단계에서 xAI 문서를 확인한 뒤 OpenAI 어댑터 재사용 여부를 정한다 |
| Q13 | 사용량 저장 | **대화 기록 · 위키 기획이 맡는다**(테이블 · 보관 · 보기 화면). 이 기획은 계약 · 이벤트만 |
| Q14 | 대화 중 모델 · 벤더를 바꾸면 | **이어 간다** |
| Q15 | 구현 순서 | **단계로 나눈다** — ① 중립 계약 + Claude 어댑터 이전(동작 그대로) → ② 키 UX · 마스킹 · 저장 시 확인 · 경고 · glow → ③ 모델 목록 · 칩 → ④ GPT 어댑터 · 벤더 바꾸기 · 재동의 → ⑤ Grok(후속) |
| — | 벤더 연결 | **한 번에 하나만.** 설정에서 언제든 바꿀 수 있고, 바꾸면 기존 키를 지우고 교체(확인 창) |
| — | 연결 표시 | **물어보기 설정 화면**에 **벤더 아이콘 + "연결됨"** |
| — | 설정 위치 | 설정 탭 삭제([재구성 설계](2026-11-01-walk-nav-regroup-design.md)). 물어보기 [설정 열기] · 실패 말풍선 [설정 열기] → **물어보기 설정 화면 push**, 알람 권한 배너 → **알람 설정 화면 push**. 재구성이 먼저 |
| — | 전송 동의 | **벤더를 바꿀 때만** 다시 받는다. 문구에 "연결한 벤더로 질문 · 기록 · 위키가 전송" 명시 |
| — | 모델 | 앱은 모델 id 를 고정하지 않는다. 목록에서 채팅용만 남기고, 기본값 = **추천 계열의 최신 모델**(GPT 는 날짜 없는 별칭 우선). 설정 열 때 · 하루 1회 갱신, 고른 모델이 사라지면 기본으로 |
| — | 모델 칩 | 물어보기 탭 상단 칩에서 모델을 고른다(저장). 최신순, 처음 보는 모델 NEW, 사용 중보다 새 모델이 있으면 칩에 작은 점 |
| — | 빠른 출력 모드 | **모델 칩의 선택지**(체감 속도 기획에서 옴). 지원하는 벤더 · 모델에서만 켜기/끄기, 요금이 더 든다는 안내 포함. ⚠️ 재구성 설계는 "둔다면 물어보기 설정 화면"을 제안했으나 **위치가 다름 — 사용자 결정(칩) 우선** |
| — | 서버 저장 | 모든 벤더 요청에 서버 쪽 대화 저장을 끄는 옵션을 명시적으로 넣는다(없는 벤더는 없음을 적어 둔다) |
| — | 구조 | domain 에 벤더 중립 메시지 · 도구 · 이벤트, 벤더별 어댑터가 변환. 벤더 전용 데이터(thinking 서명 등)는 어댑터 안에. 시스템 프롬프트 · 도구 5개는 공통 |
| — | 사용량 | 요청마다 토큰 사용량(입력 · 출력 · 캐시)을 중립 이벤트에 담아 기기에 기록할 수 있게 |
| — | 진행 · 중단 | 진행 노트 · 중단(멈춤) 이벤트의 내용은 [체감 속도 기획](2026-11-01-walk-chat-streaming-ux.md)이 정한다. 이 기획은 중립 이벤트에 자리만 표시(§8.2) |

---

## 0. 지금 코드 요약

| 역할 | 위치 |
|---|---|
| 키 저장 계약 | `lib/domain/chat/chat_settings.dart` — `apiKey()` · `saveApiKey()` · `deleteApiKey()` · `consented` |
| 저장 구현 | `lib/data/chat/secure_chat_settings.dart` — 키는 `FlutterSecureStorage`(`anthropic_api_key`), 동의만 `SharedPreferences`(`chat.consented`) |
| 보안 저장소 주입 | `lib/core/di/register_module.dart:98` — `const FlutterSecureStorage()` 기본 옵션. 잠금 파일 기준 `flutter_secure_storage` 11.1.1 |
| 모델 계약 | `lib/domain/chat/chat_model.dart` — `ModelEvent.completed(content: List<Map>, stopReason: String)` 가 **Anthropic content 블록 JSON 을 그대로** 담는다(`:9-13`). `stream(messages:, tools:)` 도 Anthropic 모양 Map |
| 모델 구현 | `lib/data/chat/anthropic_chat_model.dart` — 모델 id `claude-opus-5-5` · `effort: low` · `fallbacks` 베타가 코드에 고정(`:41-54`) |
| 대화 루프 | `lib/domain/chat/usecase/chat_session.dart` — `_messages` 가 Anthropic 메시지 Map, `stopReason == 'tool_use'` · `'refusal'` 분기(`:119-136`), `tool_result` 블록을 직접 만든다(`:170-185`) |
| 도구 정의 | `lib/domain/chat/tool/life_tools.dart:47-58` — `input_schema` 키(Anthropic 모양) |
| 설정 섹션 | `lib/presentation/settings/cubit/chat_settings_cubit.dart` · `chat_settings_state.dart` · `widget/chat_settings_section.dart` |
| 설정 탭 | `lib/presentation/settings/page/settings_page.dart` — 한 `ListView`: 걷기 · 알람 · 일기 · **채팅** · 권한 · 테마. **재구성에서 삭제**되고 `ChatSettingsSection` 은 물어보기 설정 화면, 권한 행(알림 · 정확한 알람 · 전체 화면)은 알람 설정 화면으로 간다 |
| 셸 | `lib/presentation/shell/page/main_shell_page.dart` — `IndexedStack` 5탭, `ChatTab(onOpenSettings: () => _select(ShellTab.settings))` |
| 물어보기 탭 | `lib/presentation/chat/page/chat_tab.dart` · `cubit/chat_cubit.dart` · `widget/chat_consent_view.dart` |
| 잘못된 키 판정 | `anthropic_chat_model.dart:77-78` — 401 · 403 → `invalidKey` → `ChatFailure.invalidKey`(`chat_session.dart:191`) |
| 자산 · SVG | `pubspec.yaml:61-62` 자산은 `assets/alarm/` 뿐. `flutter_svg` 의존성 없음 |

---

## 1. 저장해도 화면이 안 바뀌는 것 같다

### 1.1 지금 동작과 원인

- [저장]이 입력값을 돌려주며 **바로 닫힌다**(`chat_settings_section.dart:158`) → `cubit.save(key)`(`:34`). 성공은 아무것도 알리지 않고 실패만 `AppSnackBar` 오류(`:35`).
- 저장 뒤 바뀌는 것은 키 행 오른쪽 끝 글자 "키 넣기" → `…abcd`(`:89`)와 부제 "바꾸기"(`:88`), "키 삭제" 행(`:92-98`)뿐이다. 작은 글자 하나라 알아채기 어렵다.
- 저장 중 표시가 없다(`chat_settings_cubit.dart:29-38` 은 `loading` 을 올리지 않는다).
- 입력칸이 `obscureText: true`(`chat_settings_section.dart:144`)이고 보기 토글이 없다.
- 키가 맞는지 저장 때 확인하지 않는다. 틀린 키도 첫 질문을 보낸 뒤에야 말풍선 "키를 확인해 주세요"로 드러난다.

### 1.2 바꿀 동작

화면 상태는 §6.1(벤더 기준 상태 표)에 둔다. 입력 대화상자는 벤더 하나에 대해 다음처럼 동작한다.

- 제목 "○○ API 키 넣기"(벤더 이름). 입력칸에 보기/숨기기 토글(`suffixIcon`), 기본 숨김. 열 때 **늘 빈 칸**(바꾸기에서도 이전 키를 채우지 않는다).
- 접두사 검사(§10.1 의 벤더별 접두사): trim 뒤 비었거나 그 벤더 접두사가 아니면 [저장]을 끄고 입력칸 아래 안내. 다른 벤더 접두사로 보이면 "Claude 키 같아요" 처럼 짚어 준다. 길이는 보지 않는다.
- [저장] → 대화상자를 **닫지 않고** 확인(§4)하는 동안 로딩(`AppButton.primary(isLoading:)`, 입력칸 · 취소 비활성). 결과:
  - **정상 키** → 요금 경고 확인 창(`AppConfirmDialog.show`, `isDestructive: false`) "이 API 를 쓰면 ○○ 에 요금이 청구될 수 있어요. 등록할까요?" → [확인]이면 보안 저장소에 쓰고 대화상자를 닫은 뒤 `AppSnackBar`(success) "○○ 에 연결했어요". [취소]면 아무것도 저장하지 않고 입력 대화상자로 돌아간다(입력값 유지).
  - **잘못된 키**(벤더별 인증 오류, §10.1) → 저장하지 않고 대화상자를 연 채 입력칸 오류 "이 키로는 연결되지 않아요"(입력값 유지).
  - **확인 못 함**(네트워크 · 429 · 5xx) → **같은 요금 경고 창(Q8)** → [확인]이면 "확인 전"으로 저장 후 닫고 `AppSnackBar`(info) "키를 저장했어요. 연결되면 확인할게요".
  - **저장소 쓰기 실패** → 닫지 않고 `AppSnackBar` error(지금 문구 `walkChatSettingsSaveFailed`).
- 성공 뒤 연결 행에 glow 를 한 번(§3 의 같은 위젯). "여기가 바뀌었다"를 눈으로 잇는다.
- 연결 끊기(키 삭제)는 지금처럼 `AppConfirmDialog.show`(되돌리기 어려움) 뒤 지우고, 성공하면 `AppSnackBar`(info) "연결을 끊었어요"를 더한다(지금은 실패만 알림, `chat_settings_section.dart:56-57`).

---

## 2. 안전한 저장소 · 마스킹

### 2.1 사실 확인 (지금 코드)

| 질문 | 답 | 근거 |
|---|---|---|
| 보안 저장소를 쓰나 | **예.** 키는 `FlutterSecureStorage` 에만, `SharedPreferences` 에는 동의 여부만 | `secure_chat_settings.dart:7` · `:28` · `:38`, 테스트 `test/data/chat/secure_chat_settings_test.dart:31` |
| 옵션 | 기본(`const FlutterSecureStorage()`). Android 는 플러그인 기본 암호화(Keystore 키로 감싼 AES), 앱 전용 저장소 | `register_module.dart:98` |
| 화면에 무엇이 보이나 | **뒤 4글자** `…abcd` — 원하는 "앞부분만"과 반대 | `chat_settings_cubit.dart:40-44`, 테스트 `chat_settings_cubit_test.dart:7` |
| 원문이 상태에 남나 | 상태에는 없다. 다만 `load()` 가 **원문 전체를 cubit 메모리로 읽어** 힌트를 만든다 | `chat_settings_cubit.dart:13-21`, 테스트 `chat_settings_cubit_test.dart:16`(toString 에 키 없음) |
| 원문이 입력칸에 다시 채워지나 | 아니다(빈 컨트롤러) | `chat_settings_section.dart:129` |
| 로그 · 예외 | 남지 않는다. `print`/`debugPrint`/`log` 없음, 모델 예외는 종류 enum 만, 응답 본문을 읽지 않음 | `anthropic_chat_model.dart:10` · `:59-63` |
| 물어보기 탭 | 키 존재만 본다(null 여부)지만 원문을 읽는다 | `chat_cubit.dart:35-49` |
| 백업 | `AndroidManifest.xml` `<application>` 에 `allowBackup` · `dataExtractionRules` 지정 없음 → 백업 허용. 복원된 암호문은 새 기기에서 못 풀어 읽기가 예외 → 지금은 조용히 "키 없음" | `android/app/src/main/AndroidManifest.xml:24`, `chat_settings_cubit.dart:17-19` |

정리: 저장은 이미 안전한 저장소다. 고칠 것은 (a) 마스킹 방향, (b) presentation 이 원문을 읽지 않게, (c) 백업 복원 때의 조용한 실패.

### 2.2 바꿀 동작

- **마스킹(Q3)** — 데이터 계층이 만든 미리보기만 위로 올린다. 규칙: 그 벤더의 **공개 접두사**(§10.1, 가장 긴 것부터 맞춤) + 본문 앞 **4글자** + `••••`(점 4개 고정, 길이를 드러내지 않음). 예: `sk-ant-api03-Ab3x••••` · `sk-proj-Ab3x••••`. 접두사가 맞지 않으면 앞 8글자 + `••••`, 8글자 미만이면 `••••`. 순수 함수 `maskApiKey(ChatVendor, String)` 로 두고 단위 테스트.
- **계약(Q5)** — 설정 쪽은 `connection()`(벤더 · 미리보기 · 상태, §7.1)만 읽는다. 물어보기 탭은 `hasApiKey()`. 원문을 읽는 곳은 대화 루프(`ChatSession`)와 모델 목록 갱신(§6.3) 둘뿐이고 둘 다 domain/data 안이다.
- 미리보기를 prefs 에 따로 저장하지 않는다 — 보안 저장소가 유일한 원본.
- 상태 `toString` 에 원문 없음 테스트를 유지 · 확장(미리보기에도 본문 5번째 이후 글자 없음).
- **백업(Q6)** — `AndroidManifest.xml` 에 `android:fullBackupContent` · `android:dataExtractionRules` 로 `FlutterSecureStorage` 저장 파일만 백업에서 뺀다(다른 데이터의 백업 정책은 그대로). 그래도 읽기 예외가 나면 `SecureChatSettings` 가 그 항목을 지우고 미연결로 돌아간다.

---

## 3. 물어보기 → 설정 이동 때 강조

### 3.1 지금 동작과 원인

- 키가 없으면 `AppPlaceholder` 의 [설정 열기] 버튼(`chat_tab.dart:124-129`) → 셸 `_select(ShellTab.settings)`(`main_shell_page.dart:241`)로 탭만 바꾼다.
- 채팅 섹션은 걷기 · 알람 · 일기 아래(`settings_page.dart:101-102`)라 대부분 첫 화면 밖이고, `IndexedStack` 이라 스크롤 위치는 마지막 그대로다.
- **잘못된 키**일 때는 설정으로 가는 버튼이 없다(`chat_bubble_view.dart:82-88` 은 문구만).
- 알람 권한 배너도 같은 `_select`(`main_shell_page.dart:236`) — 같은 문제.

[재구성 설계](2026-11-01-walk-nav-regroup-design.md)가 설정 탭을 없애고 기능별 설정을 push 화면으로 나누므로, "어느 섹션까지 스크롤할지"라는 문제는 사라진다. 남는 문제는 "화면을 열었을 때 어느 행을 봐야 하는지"다.

### 3.2 바꿀 동작

**이동 경로** — 모두 탭 전환이 아니라 **화면 push**(재구성 설계 §4).

- 미연결: `AppPlaceholder` [설정 열기] → **물어보기 설정 화면** push + 연결 행 glow.
- 잘못된 키 · 요금 부족(§7.3 `invalidKey` · `noKey` · `quotaExceeded`): 실패 말풍선 문구 아래 [설정 열기] 버튼(`AppButton.text`) → 같은 이동. 다른 실패에는 두지 않는다.
- 알람 권한 배너(Q2) → **알람 설정 화면** push + 권한 행 glow. 돌아오면 배너 상태를 다시 읽는 지금 동작은 재구성 설계가 지킨다.
- ⋮ › "물어보기 설정"(또는 앱 설정 › 기능별 설정)으로 평범하게 열면 glow 없음.
- 대화 중 인증 오류를 받으면 키 상태를 `invalid` 로 기록(§7.1) → 화면이 열리며 연결 행이 glow 하는 순간 "키를 확인해 주세요"가 같이 보인다.
- 물어보기 설정 화면은 화면 전체가 일기 잠금 아래다(재구성 설계 §6). 물어보기 탭 안의 [설정 열기]는 이미 잠금이 풀린 상태에서만 보이므로 잠금 화면을 거치지 않는다.

**강조를 전달하는 방법**

- `ChatTab.onOpenSettings` · `AlarmListPage.onOpenSettings` 는 `VoidCallback` 그대로. **셸이 "그 설정 화면을 강조와 함께 push" 하는 콜백을 넘긴다** — 탭 위젯은 설정 화면 구조를 몰라도 된다.
- 설정 화면은 생성자 인자 하나로 강조 여부를 받는다: 물어보기 설정 `highlightConnection: bool`, 알람 설정 `highlightPermissions: bool`(이름 · 화면 파일 이름은 재구성 builder 판단을 따른다). 기본 false.
- 화면이 첫 프레임을 그린 뒤(`addPostFrameCallback`, push 전환이 끝난 뒤 — `ModalRoute.of(context)?.animation` 완료를 기다림) 해당 행의 glow 를 한 번 재생한다. 행은 설정 화면 첫 화면 안에 있으므로 스크롤이 필요 없다. 혹시 화면 밖이면 그 행 하나만 `Scrollable.ensureVisible`.
- 물어보기 설정은 `ChatSettingsSection` 을 재사용하므로 강조 인자를 섹션까지 내린다(`ChatSettingsSection(highlightConnection:)`) — 섹션 내부 변경은 이 기획 ② 단계가 한다(재구성은 섹션을 재사용만 한다).

**glow 모양 · 길이(Q7)**

- 위젯 `RowHighlight`(새, `lib/presentation/settings/widget/row_highlight.dart`) — **행 하나**(`AppListTile`)를 감싸고, 생성 인자 `play: bool` 이 true 면 위 시점에 한 번 재생.
- 모양: 행 뒤 둥근 사각형(`AppRadius.sm`, 좌우 `AppSpacing.sm` 안쪽) 배경 `colorScheme.primary` 투명도 0 → 0.12 → 0, 테두리 `colorScheme.primary` 1.5px 투명도 0 → 0.6 → 0. 크기 · 위치는 움직이지 않는다.
- 시간: 한 번 = 켜짐 `AppMotion.medium` → 유지 `AppMotion.long` → 꺼짐 `AppMotion.medium` (= 900ms), **두 번 ≈ 1.8초**. 기존 토큰만 조합(`TweenSequence` 가중치).
- 사용자가 그 행을 탭하거나 화면을 스크롤하면 곧바로 꺼짐 구간으로.
- '애니메이션 줄이기'(`AppMotion.enabled(context) == false`): glow 없음. 상태 문구가 안내를 대신한다.
- 접근성: 재생 시작 때 `SemanticsService.announce` 로 행 제목을 한 번.
- 같은 위젯을 §1.2 의 "저장 성공 뒤 연결 행 glow"에도 쓴다.
- 위치: 쓰는 곳이 walk 설정 화면들뿐이라 walk 설정 폴더에 둔다(규칙 4). 다른 앱에서도 쓰면 `design_system/widget/` 으로 승격.

---

## 4. 저장 시 키 확인 (Q1 · Q8)

- 각 벤더의 모델 목록 호출(§10.1)로 확인한다. 같은 호출이 §6.3 의 모델 목록도 채운다 — 한 번 호출로 두 가지.
- 판정: 인증 오류 → `invalid`(저장 안 함) · 2xx → `valid` · 그 밖(네트워크 · 429 · 5xx · 타임아웃 10초) → `unreachable`. `valid` · `unreachable` 둘 다 요금 경고 창을 거쳐 등록한다.
- 응답은 목록 JSON 만 읽는다(모델 id · 만든 시각 · 표시 이름 · 능력 필드). 오류 응답은 `error.type` · `error.code` 만 읽는다(§10.2).
- 주의: 모델 목록은 **크레딧이 없어도** 성공할 수 있다. "연결됨"은 키가 맞다는 뜻이지 결제가 돼 있다는 뜻은 아니다 — 대화 중 요금 부족은 `quotaExceeded` 로 따로 알린다(§7.3).
- "확인 전"으로 저장한 키는 물어보기 탭이 처음 열릴 때 같은 호출로 다시 확인한다(§6.3).

---

## 5. 멀티 벤더 — 흐름

MVP 벤더는 Claude · GPT(Q12). 아래 흐름은 벤더 수와 무관하게 쓰여 있고, ⑤ 단계에서 Grok 을 벤더 시트에 더하면 그대로 동작한다.

### 5.1 연결 (미연결 → 연결됨)

물어보기 설정 화면 [AI 연결하기] → 벤더 고르기 시트(Claude · GPT — 로고 + 이름 + 한 줄 설명 "Anthropic" · "OpenAI") → §1.2 키 대화상자 → 확인 → 요금 경고 → 저장 → 첫 질문 때 전송 동의(§5.3).

### 5.2 벤더 바꾸기 (연결됨 → 다른 벤더)

[다른 AI 로 바꾸기] → 벤더 시트(지금 벤더는 체크, 고를 수 없음) → 새 벤더 키 대화상자 → **새 키를 먼저 확인**(기존 키는 이 시점까지 그대로) → 확인 창 하나로 묶는다:

> **GPT 로 바꿀까요?**
> 이 API 를 쓰면 OpenAI 에 요금이 청구될 수 있어요. 지금 연결된 Claude 키는 이 폰에서 지워지고, 다음 질문 때 전송 동의를 다시 받아요. 지금 대화는 GPT 로 이어져요.
> [취소] [바꾸기]

- [바꾸기] → 새 키 쓰기 · 벤더 · 상태 · 모델 캐시 교체 · 기존 키 삭제를 **한 동작**으로(§7.1 `connect`). 새 키 쓰기가 실패하면 기존 연결을 그대로 둔다.
- **지금 대화는 이어 간다(Q14).** 다음 질문 전에 새 벤더 동의를 받고, 이전 턴은 §8.4 의 넘김 규칙으로 새 벤더에 보낸다.
- 같은 벤더의 키만 바꾸는 [키 바꾸기]는 §1.2 그대로(요금 경고 포함, 동의는 다시 받지 않음).

### 5.3 전송 동의

- 동의를 bool 이 아니라 **동의한 벤더**로 저장한다(`chat.consentedVendor`). 연결 벤더 ≠ 동의 벤더면 `needsConsent`. 같은 벤더 키 교체 · 모델 변경 · 빠른 출력 모드로는 다시 묻지 않는다.
- 문구(`walkChatConsentNotice` · 설정 안내문 `walkChatSettingsNotice` 를 벤더 자리표시자로): "질문과, 답에 필요한 일기 · 사진 · 걸음 · 기상 기록 · 위키가 **연결한 AI(○○)** 로 전송돼요. 키는 이 폰의 보안 저장소에만 있어요." 벤더를 바꿔 대화를 이어 갈 때는 "지금 대화의 이전 내용도 ○○ 로 보내져요" 한 줄을 더한다. 위키는 대화 기록 기획이 들어오면 맞는 말이 된다 — 두 기획이 같이 들어가지 않으면 이 낱말만 빼서 낸다.
- 이전(마이그레이션): 기존 `chat.consented == true` → `chat.consentedVendor = anthropic`.

---

## 6. 멀티 벤더 — 화면

### 6.1 물어보기 설정 화면 — AI 연결 상태 표

물어보기 설정 화면(재구성 설계의 push 화면)이 `ChatSettingsSection` 을 그대로 쓰고, 이 표는 그 섹션 안의 모습이다.

섹션 머리글 "AI 연결"(구현: 섹션 머리글 없음 — 행 제목과 겹침). 첫 행이 연결 행이고 그 아래 동작 행들.

| 상태 | 연결 행 (leading · 제목 · 부제 · 오른쪽) | 아래 행 |
|---|---|---|
| 미연결 | 플러그 아이콘 · "AI 연결" · "Claude · GPT 중 하나의 키를 넣으면 물어보기를 쓸 수 있어요" · "연결하기"(primary) | 안내문 |
| 연결됨 (`valid`) | **벤더 로고** · 벤더 이름 · 마스킹 키(고정폭) · 체크 + **"연결됨"** | 모델 행(현재 모델 표시 이름 + 빠른 출력이면 표시, 탭하면 §6.2 시트) · 키 바꾸기 · 다른 AI 로 바꾸기 · 연결 끊기 · 안내문 |
| 확인 전 (`unverified`) | 벤더 로고 · 벤더 이름 · 마스킹 키 · "확인 전"(onSurfaceVariant) | 〃 (모델 목록이 없으면 모델 행은 "목록을 받지 못했어요 · 다시 시도") |
| 잘못된 키 (`invalid`) | 벤더 로고 · 벤더 이름 · 마스킹 키 · 경고 + "키를 확인해 주세요"(error) | 〃 |
| 읽는 중 | 지금처럼 행 비활성 | — |

- 벤더 로고는 `ChatVendorIcon(vendor, size:)` 한 곳에서 그린다(Q9). 자산은 `assets/chat/vendors/{anthropic,openai}.svg`, 그리기는 `flutter_svg`(새 의존성). 단색 로고면 `ColorFilter` 로 `colorScheme.onSurface` 를 입혀 라이트 · 다크 모두 맞춘다 — 색을 바꿔도 되는지는 브랜드 가이드 확인 항목(§10.3). 로고를 읽지 못하면 벤더 이름 첫 글자 원형으로 대신 그린다.
- 물어보기 설정 화면이 **열릴 때** 모델 목록이 하루 넘게 묵었으면 갱신(§6.3).

### 6.2 물어보기 탭 모델 칩

- 위치: 앱바 아래 한 줄(대화 위), 왼쪽 정렬. `ready` 일 때만. 칩 = 벤더 로고(작게) + 모델 표시 이름 + 빠른 출력이 켜져 있으면 번개 아이콘 + `▾`. 사용 중보다 새 모델이 있고 아직 안 봤으면 칩 오른쪽 위에 작은 점(`colorScheme.primary`).
- 탭 → 바텀시트 "모델 고르기":
  - 목록 **최신순**(만든 시각 내림차순; 시각이 없으면 벤더 목록 순서).
  - 행 = 표시 이름 · 만든 날짜 · 배지들: **추천**(기본값) · **NEW**(처음 보는 id) · 사용 중 체크. 이미지 입력을 못 받는 모델은 부제 "사진은 못 봐요"(§6.4).
  - 고르면 저장(`chat.model`)하고 시트를 닫는다. 답하는 중(`busy`)에는 칩 비활성.
  - 시트를 열면 보이는 id 를 모두 "본 것"으로 기록 → NEW · 점이 사라진다.
  - **빠른 출력 모드** — 목록 아래 스위치 행 "빠르게 답하기" + 부제 "답이 더 빨리 나오지만 요금이 더 들어요(약 ○배)". 지금 고른 모델이 지원할 때만 보인다(§10.1 · §10.3). 처음 켤 때 한 번 `AppConfirmDialog`(`isDestructive: false`)로 요금 안내를 확인받는다. 값은 `chat.fastMode`(bool)에 저장. 지원하지 않는 모델로 바꾸면 스위치가 사라지고 요청에 넣지 않는다(값은 남아 지원 모델로 돌아오면 다시 켜진다). 기본 끔.
- 대화 중 모델을 바꾸면 다음 질문부터 새 모델이고 **대화는 이어 간다(Q14)** — §8.4 넘김 규칙.
- 물어보기 설정 화면의 모델 행도 같은 시트를 연다.
- 위치 메모: [재구성 설계](2026-11-01-walk-nav-regroup-design.md)는 빠른 출력을 "둔다면 물어보기 설정 화면"으로 제안했다. **위치가 다름 — 사용자 결정(모델 칩의 선택지) 우선.** 설정 화면 모델 행은 켜짐 여부를 보여 주기만 한다.

### 6.3 모델 목록 · 기본값 · 갱신

**받기** — §10.1 의 목록 호출. 결과를 prefs 에 캐시(`chat.models` = id · 표시 이름 · 만든 시각 · 능력, `chat.models.fetchedAt`). 원문 키는 이 호출 안에서만 쓴다.

**거르기(채팅용만)** — 벤더마다 앱이 가진 규칙(§10.1):
1. 벤더가 능력 정보를 주면 그걸로.
2. 아니면 **허용 계열 패턴**에 맞는 것만 남기고, **제외 낱말**(embedding · tts · whisper · transcribe · audio · realtime · image · dall-e · moderation · search · codex · instruct 등)이 들어간 id 를 뺀다.
3. **도구 호출을 못 하는 모델은 목록에서 뺀다(Q10).** 모든 답이 도구(일기 검색 등)에 기대므로 고를 이유가 없다.

**기본값(추천 계열의 최신, Q11)** — 앱 코드에는 모델 id 가 아니라 **계열 규칙**만 둔다.

| 벤더 | 추천 계열 | 최신 고르기 |
|---|---|---|
| Claude | `claude-sonnet-*` | 목록이 최신순이므로 계열에 맞는 첫 항목 |
| GPT | 플래그십 `gpt-<숫자>` (`-mini` · `-nano` · `-pro` 등 접미 없는 것) | 계열 안에서 만든 시각이 가장 늦은 묶음을 고르고, 그 묶음 안에서 **날짜 없는 별칭**(`-YYYY-MM-DD` 없는 id) 우선 |
| Grok (⑤ 후속) | 플래그십 `grok-<숫자>` | 같은 규칙. 벤더가 별칭 목록을 주면 그 별칭 우선 |

계열에 맞는 게 하나도 없으면 거른 목록의 가장 최신 모델.

**갱신 시점** — 키 확인 때 · 물어보기 설정 화면이 열릴 때 · 물어보기 탭이 보일 때, 각각 `fetchedAt` 이 24시간 넘었으면. 실패는 조용히(캐시 유지).

**고른 모델이 사라지면** — 갱신한 목록에 `chat.model` 이 없으면 기본값으로 되돌리고, 다음에 물어보기 탭이 보일 때 `AppSnackBar`(info) "고른 모델이 없어져 추천 모델로 바꿨어요" 한 번. 대화 중 모델 없음 오류(`modelUnavailable`)를 받아도 목록을 갱신하고 같은 처리 후 실패 말풍선 "모델을 바꿨어요. 다시 물어봐 주세요".

**모델 목록이 아예 없을 때** — "확인 전"으로 저장했고 아직 한 번도 목록을 못 받았으면 모델을 정할 수 없다(id 를 고정하지 않으므로). 물어보기 탭에 새 상태 `ChatAccess.noModels`: `AppPlaceholder`("모델 목록을 받지 못했어요" + [다시 시도]). 다시 시도가 성공하면 그 응답이 키 확인도 겸한다(`unverified → valid`, 인증 오류면 `invalid` + [설정 열기]).

**NEW · 점** — 본 id 집합(`chat.models.seen`). 처음 목록을 받을 때는 전부 본 것으로(모두 NEW 가 되지 않게). 점 = 지금 모델보다 만든 시각이 늦고 아직 안 본 모델이 있음.

### 6.4 이미지 입력을 못 받는 모델 (Q10)

- 목록에 남기되 부제 "사진은 못 봐요".
- 그 모델로 대화할 때는 `view_photos` 도구를 **도구 정의에서 뺀다**. 시스템 프롬프트는 공통이므로 "사진 도구가 없으면 사진은 볼 수 없다고 답한다" 한 줄을 공통 프롬프트에 둔다.
- 이미 보낸 사진이 있는 대화를 이 모델로 이어 가면 이전 턴의 사진은 빼고 보낸다(§8.4).
- 능력 정보가 없는 벤더는 계열 표(앱 코드)에 "이미지 입력 가능" 여부를 둔다. 모르면 가능하다고 보고, 요청이 이미지 때문에 400 을 받으면 그 모델을 "사진 못 봄"으로 캐시에 기록하고 사진 없이 한 번 다시 보낸다(확인 필요: 벤더별 오류 모양).

---

## 7. 데이터 · 상태

### 7.1 `ChatSettings` 계약 (domain)

```dart
enum ChatVendor { anthropic, openai }   // ⑤ 에서 xai 추가
enum ChatKeyStatus { unverified, valid, invalid }

/// 화면에 보여도 되는 연결 정보. 원문 키는 없다.
class ChatConnection { ChatVendor vendor; String keyPreview; ChatKeyStatus status; }

abstract interface class ChatSettings {
  Future<ChatConnection?> connection();          // 미연결이면 null
  Future<bool> hasApiKey();                      // Q5
  Future<String?> apiKey();                      // ChatSession · 모델 목록 갱신만
  /// 새 키로 연결(같은 벤더 교체 · 벤더 바꾸기 공통). 쓰기가 끝난 뒤에만 기존 키를 지운다.
  Future<void> connect(ChatVendor vendor, String key, ChatKeyStatus status);
  Future<void> disconnect();
  Future<void> setKeyStatus(ChatKeyStatus status);

  ChatVendor? get consentedVendor;               // bool consented 대신
  Future<void> setConsented(ChatVendor vendor);

  String? get selectedModel;                     // 모델 id
  Future<void> selectModel(String id);
  bool get fastMode;
  Future<void> setFastMode(bool on);
}
```

모델 목록 캐시 · 본 id 는 `ChatModelCatalog`(새 domain 계약, data 구현 `PrefsChatModelCatalog`)로 따로 둔다 — `refresh()` · `models` · `defaultModel` · `markSeen()` · `hasUnseenNewer(current)` · `supportsFastMode(id)`.

### 7.2 저장 위치

| 값 | 저장소 | 키 |
|---|---|---|
| API 키 | 보안 저장소 | `chat.apiKey` (벤더 하나뿐이라 하나). 기존 `anthropic_api_key` 는 첫 읽기 때 옮기고 지운다 |
| 벤더 · 키 상태 · 동의 벤더 · 고른 모델 · 빠른 출력 | prefs | `chat.vendor` · `chat.keyStatus` · `chat.consentedVendor` · `chat.model` · `chat.fastMode` |
| 모델 목록 캐시 · 갱신 시각 · 본 id | prefs | `chat.models` · `chat.models.fetchedAt` · `chat.models.seen` |

이전: `anthropic_api_key` 가 있으면 `vendor = anthropic`, `keyStatus = unverified`, `consented == true` 면 `consentedVendor = anthropic`.

### 7.3 실패 종류

`ChatFailure` 에 더한다: `quotaExceeded`(결제 · 크레딧 부족 — 키는 맞음) · `modelUnavailable`(모델 없음 · 권한 없음) · `noModels`. 벤더별 매핑은 §10.1. `invalidKey` 를 받으면 `setKeyStatus(invalid)`, 질문이 성공하면 `setKeyStatus(valid)`.

### 7.4 상태 클래스

- `ChatSettingsState`: `loading` · `connection`(ChatConnection?) · `model`(표시 이름) · `fastMode` · `modelsUnavailable`. 원문 없음.
- `ChatState`: `access` 에 `noModels` 추가, `vendor` · `model`(칩 표시) · `fastMode` · `fastModeAvailable` · `hasNewerModel`.

---

## 8. 벤더 중립 채팅 계약 (이 기획이 소유)

대화 기록 · 위키 기획과 체감 속도 기획은 이 절의 형식을 참조한다.

### 8.1 지금 문제

`ChatModel` · `ChatSession` · `LifeTools` 가 Anthropic JSON 을 공유한다 — `content` 블록 리스트(`chat_model.dart:9-13`), `stop_reason` 문자열 분기(`chat_session.dart:119-136`), `tool_result` 블록 조립(`:170-185`), 도구 정의의 `input_schema`(`life_tools.dart:49`). 벤더를 더하려면 domain 이 벤더 모양을 몰라야 한다.

### 8.2 domain 형식

`lib/domain/chat/chat_model.dart` 를 다시 쓴다(Freezed 규칙: 변형은 sealed union, 단일은 primary constructor).

```dart
/// 대화 한 줄.
sealed class ChatMessage {
  const factory ChatMessage.user(String text) = UserMessage;
  /// 모델 한 턴. [vendorState] 는 어댑터만 읽는 불투명 값(thinking 서명 · 암호화 reasoning 등).
  const factory ChatMessage.assistant({
    required List<AssistantPart> parts,
    VendorTurnState? vendorState,
  }) = AssistantMessage;
  const factory ChatMessage.toolResults(List<ToolResultPart> results) = ToolResultsMessage;
}

sealed class AssistantPart {
  const factory AssistantPart.text(String text) = TextPart;
  const factory AssistantPart.toolCall({required String id, required String name,
      required Map<String, Object?> input}) = ToolCallPart;
}

class ToolResultPart { String callId; String json; bool isError; List<ToolImage> images; }

/// 도구 정의. JSON Schema 는 벤더 공통 부분집합(object · string · integer · enum · required)만.
class ToolSpec { String name; String description; Map<String, Object?> parameters; }

/// 어댑터 전용. domain 은 만들지도 읽지도 않고 들고만 다닌다. 저장(대화 기록)하지 않는다.
abstract interface class VendorTurnState { ChatVendor get vendor; String get model; }

enum StopKind { endTurn, toolUse, refusal, maxTokens, other }

class TokenUsage {
  int inputTokens; int outputTokens;
  int cacheReadTokens; int cacheWriteTokens;   // 벤더가 안 주면 0
  int? reasoningTokens;                         // 주는 벤더만
}

sealed class ModelEvent {
  const factory ModelEvent.textDelta(String text) = ModelTextDelta;

  // ── 진행 이벤트 자리 ── 이름 · 모양 · 내는 조건은 체감 속도 기획 §5 가 정한다.
  //   thinking()                       생각 구간 시작(내용 없음)
  //   progress(String text)            사용자에게 보일 진행 노트. 못 주는 벤더는 0개
  //   toolCallStarted(id, name)        도구 호출 블록 열림(입력 완성 전)
  //   toolCallReady(id, name, input)   입력 완성
  // 이 기획의 어댑터(§8.3)는 위 이벤트를 "벤더가 주면 낸다"는 자리만 둔다.

  const factory ModelEvent.completed({
    required AssistantMessage message,
    required StopKind stop,
    required TokenUsage? usage,      // 벤더가 안 주거나 못 읽으면 null. 사용량은 여기 한 곳(별도 usage 이벤트 없음)
  }) = ModelCompleted;
}

class ModelRequest {
  String apiKey; String model; bool fastMode;
  String system; List<ChatMessage> messages; List<ToolSpec> tools;
}

abstract interface class ChatModel {
  ChatVendor get vendor;
  /// 실패는 ChatModelException.
  /// ── 중단 자리 ── 구독을 cancel 하면 어댑터는 진행 중인 HTTP 요청을 닫는다(요청 취소).
  /// 멈춤 버튼 · 부분 답 처리 등 흐름은 체감 속도 기획이 정한다.
  Stream<ModelEvent> stream(ModelRequest request);
  Future<ModelListResult> listModels(String apiKey);      // 키 확인 겸 목록 (§4 · §6.3)
}

sealed class ModelListResult {
  const factory ModelListResult.ok(List<ModelInfo> models) = ModelListOk;
  const factory ModelListResult.invalidKey() = ModelListInvalidKey;
  const factory ModelListResult.unreachable() = ModelListUnreachable;
}

class ModelInfo { String id; String displayName; DateTime? createdAt;
  bool? supportsTools; bool? supportsImages; bool supportsFastMode; List<String> aliases; }
```

`ChatModelErrorKind` 에 `quotaExceeded` · `modelUnavailable` 를 더한다.

체감 속도 기획 §5 가 제안한 별도 `usage(...)` 이벤트는 `completed.usage` 로 합친다(라운드 끝에 한 번만 확정되므로). 그쪽과 맞출 지점.

### 8.3 어댑터

| 어댑터 | 파일 | 하는 일 |
|---|---|---|
| `AnthropicChatModel` | `lib/data/chat/anthropic_chat_model.dart` (고침) | 중립 → Messages API. `vendorState` = 그 턴의 원본 content 블록(thinking · 서명 포함). `ToolSpec` → `input_schema`. 이미지는 `tool_result` content 안에. `fastMode` 면 그 모델의 빠른 출력 옵션(확인 필요) |
| `OpenAiChatModel` | `lib/data/chat/openai_chat_model.dart` (새) | 중립 → Responses API. `store: false` + `include: ["reasoning.encrypted_content"]`, `vendorState` = 그 턴의 reasoning 항목(암호화 내용). `previous_response_id` 는 쓰지 않는다(서버 저장이 꺼져 있으므로 매번 전체를 보낸다). `ToolSpec` → `{type: function, name, parameters}`. 도구 결과 이미지는 `function_call_output` 이 이미지를 받으면 거기, 아니면 뒤따르는 user 입력에(확인 필요). `fastMode` 면 빠른 처리 옵션(확인 필요) |
| xAI (⑤ 후속) | 미정 | xAI 문서 확인 후 `OpenAiChatModel` 을 base URL · 벤더만 바꿔 재사용할지, Chat Completions 어댑터를 따로 둘지 정한다(Q12) |

- 벤더 선택은 `ChatModelRegistry`(data): `ChatVendor` → `ChatModel`. `ChatSession` 은 `settings.connection().vendor` 로 고른다.
- 공통: 예외에 키 · 본문 없음. 오류 응답은 `error.type` · `error.code` 만(§10.2). SSE 파서는 벤더마다 따로(이벤트 이름이 다르다) — 줄 나누기 · 대기 시간 처리만 공용 헬퍼(`sse_lines.dart`)로.
- 구독이 cancel 되면 진행 중인 요청을 닫는다(`http.Client` 요청 중단). 각 어댑터 테스트에 "cancel 하면 응답 스트림 구독이 끊긴다"를 둔다.
- 진행 이벤트(§8.2 자리)는 체감 속도 기획이 정한 대로, 벤더가 주는 것만 낸다.
- 벤더별 생각 수준(Anthropic `output_config.effort` · OpenAI `reasoning.effort`)은 어댑터가 "낮음"으로 맞춘다. 모델이 그 파라미터를 받지 않으면 빼야 한다(확인 필요 — 받지 않는 모델에 보내면 400).
- 지금 Anthropic 요청의 `anthropic-beta: server-side-fallback-…` · `fallbacks: 'default'` 는 어댑터 안에 그대로 둔다.

### 8.4 `ChatSession` · `LifeTools` 변화

- `_messages` 를 `List<ChatMessage>` 로. `stopReason` 문자열 분기 → `StopKind` switch. `_toolResult` Map 조립 → `ToolResultPart`.
- 시스템 프롬프트와 도구 5개는 그대로 공통. `LifeTools.definitions` 가 `List<ToolSpec>` 을 돌려준다(`input_schema` → `parameters`). 사진 못 보는 모델이면 `view_photos` 를 뺀 목록(§6.4).
- 요청마다 `ModelRequest.model = settings.selectedModel ?? catalog.defaultModel`, `fastMode = settings.fastMode && catalog.supportsFastMode(model)`.
- 실패 · 끊김 때 그 질문의 메시지를 되돌리는 지금 규칙은 그대로.
- **넘김 규칙(Q14 — 대화 중 모델 · 벤더 바꾸기)** — 어댑터가 요청을 만들 때 턴마다 판단한다:
  - 같은 벤더 · 같은 모델의 턴: `vendorState` 원본 그대로.
  - 같은 벤더 · 다른 모델의 턴: `vendorState` 를 빼고 글 · 도구 호출 · 도구 결과만 다시 만든다(확인 필요 — 빼도 받아 주는지).
  - **다른 벤더의 턴**: 글만 남긴다 — 도구 호출 · 도구 결과 · 사진을 빼고, user/assistant 글을 차례로 보낸다(대화 기록 기획의 "글만으로 다시 만들기"와 같은 모양). 도구 호출 id 형식 · 이전 결과 이미지가 벤더마다 달라 그대로 옮기지 않는다. 필요한 기록은 새 벤더가 도구로 다시 읽는다.
  - 사진 못 보는 모델이면 이전 턴의 사진을 뺀다. 사진 한도는 보낸 사진만 센다.

---

## 9. 토큰 사용량 (계약 · 이벤트만, Q13)

- 매 요청(도구 라운드 하나 = 요청 하나)의 `ModelCompleted.usage` 를 `ChatSession` 이 사용량 기록에 넘긴다. 실패 · 취소된 요청은 usage 를 못 받으므로 기록하지 않는다.
- 기록 한 건(`ChatUsageRecord`, domain): `at` · `vendor` · `model` · `fastMode` · `purpose`(`chat` · `wiki` — 위키 라우터가 쓴다) · `round` · `inputTokens` · `outputTokens` · `cacheReadTokens` · `cacheWriteTokens` · `reasoningTokens?`. 질문 · 답 글은 담지 않는다.
- 계약 `ChatUsageLog.record(ChatUsageRecord)` 는 이 기획이 정의하고, **저장 구현(테이블 · 보관 · 보기 화면)은 [대화 기록 · 위키 기획](2026-11-01-walk-chat-history-wiki.md)이 맡는다.** 그 기획이 늦으면 이 기획은 아무것도 하지 않는 구현(`NoopChatUsageLog`)으로 들어간다.
- 벤더별 사용량 위치(§10.1, 확인 필요): Anthropic `message_start.message.usage`(입력 · 캐시 쓰기/읽기) + `message_delta.usage.output_tokens` · OpenAI Responses `response.completed` 의 `response.usage`(`input_tokens` · `input_tokens_details.cached_tokens` · `output_tokens` · `output_tokens_details.reasoning_tokens`). OpenAI 는 캐시 쓰기 토큰을 따로 주지 않으므로 0.

---

## 10. 벤더별 차이

### 10.1 비교표

MVP 는 Claude · GPT. Grok 열은 ⑤ 단계 준비용 메모다. 모두 구현 직전에 각 벤더의 현재 API 문서로 재확인한다(§10.3).

| 항목 | Claude (Anthropic) | GPT (OpenAI) | Grok (xAI, ⑤ 후속) |
|---|---|---|---|
| 기본 URL · 인증 | `https://api.anthropic.com/v1` · `x-api-key` + `anthropic-version` | `https://api.openai.com/v1` · `Authorization: Bearer` | `https://api.x.ai/v1` · `Authorization: Bearer` |
| 키 공개 접두사(마스킹 · 검사) | `sk-ant-api03-`(`sk-ant-<종류><번호>-` 모양) | `sk-proj-` · `sk-svcacct-` · `sk-`(옛 형식). `sk-admin-` 은 관리 키라 거절 | `xai-` |
| 확인 · 목록 | `GET /v1/models?limit=1000` | `GET /v1/models` | `GET /v1/models`, 능력 정보는 `GET /v1/language-models`(확인 필요) |
| 목록 정렬 | 최신순(`created_at` 내림차순) | 순서 보장 없음 → `created`(유닉스 초)로 정렬 | 확인 필요 → `created` 로 정렬 |
| 표시 이름 | `display_name` | 없음 → id | 없음 → id |
| 별칭 | 날짜 없는 별칭 · 스냅샷이 목록에 함께 올 수 있음(확인 필요) | 날짜 없는 별칭과 `-YYYY-MM-DD` 스냅샷이 함께 → 별칭 우선 | `aliases` 필드(확인 필요) → 별칭 우선 |
| 채팅용 거르기 | 목록 전부 채팅 모델(현재). 도구 · 이미지 모두 지원 | 능력 정보 없음 → 계열 패턴 + 제외 낱말(embedding · tts · whisper · transcribe · audio · realtime · image · dall-e · moderation · search · codex · instruct · babbage · davinci) | 언어 모델 목록의 입출력 모달리티로(이미지 생성 모델 제외), 없으면 계열 패턴 |
| 채팅 엔드포인트 | `POST /v1/messages`(SSE) | `POST /v1/responses`(SSE) | `/v1/responses` 또는 `/v1/chat/completions`(확인 필요) |
| 벤더 전용 턴 데이터 | thinking 블록 + `signature` — 도구 루프 안에서 그대로 돌려줘야 함 | 무상태 + 추론 모델이면 reasoning 항목의 `encrypted_content` 를 돌려줘야 함 | 확인 필요 |
| 서버 대화 저장 끄기 | 요청 단위 옵션 없음 — Messages API 는 대화를 서버에 보관해 다시 불러오는 기능이 없다. 어댑터 주석과 테스트로 "보낼 옵션 없음"을 명시(확인 필요: 새 옵션 생겼는지) | **`store: false`** (Responses 는 기본 true 라 반드시 명시) | `store: false`(확인 필요: 기본값 · 필드 이름) |
| 인증 오류 | 401 `authentication_error` · 403 `permission_error` | 401 `invalid_api_key` · 403(지원 안 되는 지역 · 프로젝트 권한) | 400 또는 401(확인 필요 — 예전에 400 + "Incorrect API key") |
| 요금 부족 → `quotaExceeded` | 400 `invalid_request_error` + 크레딧 부족(확인 필요 — `error.type`/`code` 만으로 구분되는지) | **429 + `insufficient_quota`** (속도 제한 429 와 `code` 로 구분) | 확인 필요 |
| 속도 제한 · 과부하 | 429 · 529 `overloaded_error` | 429 `rate_limit_exceeded` · 503 | 확인 필요 |
| 모델 없음 → `modelUnavailable` | 404 `not_found_error` | 404 `model_not_found` | 확인 필요 |
| 사용량 | `message_start` 의 usage(입력 · `cache_creation_input_tokens` · `cache_read_input_tokens`) + `message_delta` 의 `output_tokens` | `response.completed` 의 `usage`(`cached_tokens` · `reasoning_tokens` 포함) | 확인 필요 |
| 생각 수준 | `output_config.effort: low`(지금 코드) | `reasoning.effort: low`(추론 모델만) | 확인 필요 |
| 도구 결과 이미지 | `tool_result` content 안 `image` 블록(지금 코드) | `function_call_output` 의 이미지 입력(확인 필요) — 안 되면 다음 user 입력에 `input_image` | 확인 필요 |
| 빠른 출력 모드 | fast mode — 체감 속도 기획 기준 Opus 5.5 · research preview · 가격 2배(확인 필요: 요청 필드 · 지원 모델 · Sonnet 지원 여부). 추천 계열이 Sonnet 이므로 지원 모델을 고를 때만 스위치가 보일 수 있다 | 우선 처리 등급(`service_tier: "priority"` 류, 확인 필요: 이름 · 지원 모델 · 가격 배수) | 확인 필요 |
| 프롬프트 캐시 | 명시적 `cache_control`(체감 속도 기획이 다룸) | 자동 | 확인 필요 |
| 로고 | Anthropic/Claude 로고 — 브랜드 가이드 확인 | OpenAI 로고 — 브랜드 가이드 확인 | xAI/Grok 로고 — ⑤ 에서 |

### 10.2 오류 본문 원칙과의 충돌

지금 원칙은 "오류 응답 본문을 읽지 않는다"(`anthropic_chat_model.dart:61`). OpenAI 의 `insufficient_quota` 와 속도 제한은 같은 429 라 **오류 `code`/`type` 한 필드는 읽어야** 구분된다. 원칙을 "오류 본문은 `error.type` · `error.code` 만 읽고, 메시지 문자열 · 나머지는 버린다 · 예외에는 enum 만"으로 고친다.

### 10.3 구현 전에 확인할 것

단계(§14)마다 해당 항목을 먼저 확인하고, 결과를 walk `history.md` 에 남긴다.

1. **Anthropic** (①~③) — `/v1/models` 정렬 · 페이지 크기 상한 · 별칭/스냅샷 표기, 크레딧 부족 오류 모양, 요청 단위 저장 옵션이 새로 생겼는지, 다른 모델이 만든 thinking 블록을 빼고 보내도 되는지, **fast mode 요청 필드 · 지원 모델(Sonnet 포함 여부) · 가격 배수**
2. **OpenAI** (④) — Responses `store` 기본값, `include: reasoning.encrypted_content` 요구 조건, `function_call_output` 이미지 지원, `reasoning.effort` 를 받지 않는 모델, 목록 제외 낱말 최신화, 키 접두사 종류, **빠른 처리 등급 이름 · 지원 모델 · 가격 배수**
3. **브랜드 가이드(Q9)** (②) — Anthropic · OpenAI 로고를 앱 안 "연결 대상 표시"로 쓸 수 있는지, 색 바꾸기(단색 · 다크 모드 반전) · 크기 · 여백 규칙, 받아 쓸 공식 자산 위치. 쓸 수 없으면 글자 원형으로 대신하고 결정을 다시 묻는다
4. **벤더 공통** — 도구 정의 JSON Schema 에서 지금 5개 도구가 쓰는 키워드가 모두 받아들여지는지, SSE 이벤트 이름, 다른 벤더 대화 이력을 글로만 넘길 때 문제없는지
5. **xAI** (⑤) — 인증 오류 상태 코드, `/v1/language-models` 필드(모달리티 · 별칭), Responses API 지원 범위(`store` · 스트림 이벤트 · 도구 · 이미지 · usage), 요금 부족 · 모델 없음 오류, 생각 수준 파라미터, 빠른 출력 지원, 로고 가이드 → OpenAI 어댑터 재사용 여부 결정

---

## 11. 바꿀 파일

단계 표시 ①~⑤ = §14.

| 파일 | 변경 | 단계 |
|---|---|---|
| `lib/domain/chat/chat_model.dart` | §8.2 중립 형식으로 다시 씀 · 오류 종류 추가 · 진행 이벤트 · 중단 자리 | ① (`listModels` ②) |
| `lib/domain/chat/usecase/chat_session.dart` | 중립 메시지 · `StopKind` · 사용량 기록 | ① |
| 〃 | 키 상태 기록 | ② |
| 〃 | 모델 · 빠른 출력 선택 · 사진 못 보는 모델에서 도구 빼기 · 넘김 규칙 | ③ · ④ |
| `lib/domain/chat/tool/life_tools.dart` · `tool_result.dart` | `List<ToolSpec>` | ① |
| `lib/domain/chat/chat_usage_log.dart` (새) | `ChatUsageRecord` · `ChatUsageLog` | ① |
| `lib/data/chat/noop_chat_usage_log.dart` (새) | 대화 기록 기획 전까지 | ① |
| `lib/data/chat/anthropic_chat_model.dart` | 중립 변환 · `vendorState` · usage · cancel 시 요청 닫기 | ① |
| 〃 | `listModels` | ② |
| 〃 | 모델 id 고정 제거 · fast mode | ③ |
| `lib/data/chat/sse_lines.dart` (새) | SSE 줄 · 대기 시간 공용 | ① |
| `lib/domain/chat/chat_settings.dart` | §7.1 계약 · `ChatVendor` · `ChatKeyStatus` · `ChatConnection` | ② (모델 · 빠른 출력 ③, 동의 벤더 ④) |
| `lib/domain/chat/api_key_mask.dart` (새) | `maskApiKey` · 벤더별 접두사 · `vendorOfKey` | ② |
| `lib/data/chat/secure_chat_settings.dart` | §7.2 저장 · 이전 · 원자적 `connect` · 읽기 예외 처리 | ② · ③ · ④ |
| `lib/presentation/settings/cubit/chat_settings_cubit.dart` · `chat_settings_state.dart` | §7.4 · 연결 · 끊기 · 저장 결과 | ② (바꾸기 ④) |
| `lib/presentation/settings/widget/chat_settings_section.dart` | §6.1 상태 표 · 키 대화상자(§1.2) · 요금 경고 · 스낵바 · 연결 행 glow(`highlightConnection` 인자). 재구성은 이 섹션을 물어보기 설정 화면에서 재사용만 하고 내부는 이 기획이 바꾼다 | ② (모델 행 ③, 바꾸기 확인 ④) |
| `lib/presentation/chat/widget/chat_vendor_icon.dart` (새) | 벤더 로고(Q9), 설정 · 칩 공용 | ② |
| `assets/chat/vendors/*.svg` (새) · `pubspec.yaml` | 로고 자산 · `flutter_svg` 의존성 · 자산 경로 | ② |
| `lib/presentation/settings/widget/row_highlight.dart` (새) | 행 하나 glow | ② |
| 물어보기 설정 화면(재구성이 만듦, 예: `lib/presentation/settings/page/chat_settings_page.dart` — 이름은 재구성 builder 판단) | `highlightConnection` 인자를 받아 섹션에 넘김 | ② (열릴 때 목록 갱신 ③) |
| 알람 설정 화면(재구성이 만듦) | `highlightPermissions` 인자 · 권한 행을 `RowHighlight` 로 감쌈 | ② |
| `lib/presentation/settings/page/settings_page.dart` | **재구성에서 삭제** — 이 기획은 손대지 않는다 | — |
| `lib/presentation/shell/page/main_shell_page.dart` | 재구성이 넘기는 "설정 화면 push" 콜백에 강조 인자(`highlightConnection` · `highlightPermissions: true`)를 더함. `onOpenSettings` 는 `VoidCallback` 그대로 | ② (재구성 뒤) |
| `lib/presentation/chat/widget/chat_bubble_view.dart` · `chat_failure_text.dart` | 실패 말풍선 [설정 열기] · 새 실패 문구 | ② |
| `lib/presentation/chat/cubit/chat_cubit.dart` · `chat_state.dart` · `page/chat_tab.dart` | `hasApiKey` | ② |
| 〃 | 모델 칩 · `noModels` · 사라진 모델 안내 | ③ |
| 〃 | 벤더별 동의 | ④ |
| `android/app/src/main/AndroidManifest.xml` + `res/xml/` 백업 규칙 (새) | Q6 | ② |
| `lib/domain/chat/chat_model_catalog.dart` (새) | 목록 캐시 · 기본값 · 본 id · 빠른 출력 지원 계약 + 계열 규칙 | ③ |
| `lib/data/chat/prefs_chat_model_catalog.dart` (새) | 캐시 · 24시간 갱신 · 사라진 모델 복귀 | ③ |
| `lib/presentation/chat/widget/model_chip.dart` · `model_picker_sheet.dart` (새) | §6.2 (빠른 출력 스위치 포함) | ③ |
| `lib/data/chat/openai_chat_model.dart` (새) | §8.3 | ④ |
| `lib/data/chat/chat_model_registry.dart` (새) | 벤더 → 어댑터 | ④ |
| `lib/presentation/settings/widget/vendor_picker_sheet.dart` (새) | 벤더 고르기(Claude · GPT) | ④ |
| `lib/presentation/chat/widget/chat_consent_view.dart` | 벤더 이름 · 이어지는 대화 문구 | ④ |
| `packages/l10n/lib/l10n/app_{ko,en,ja}.arb` | 단계마다 그 단계 문구 | ②~④ |
| `apps/walk/docs/plan.md` · `history.md` · `testing.md` · `status.md` | 단계마다(진행 상태는 `status.md` 에만) | ①~④ |

생성 파일은 build_runner 로.

## 12. 테스트

`test/` 는 `lib/` 구조 그대로. 가짜: `test/support/fake_chat_settings.dart` 확장, `fake_chat_model.dart`(중립 이벤트를 흘리는) · `fake_chat_model_catalog.dart` 새로. 벤더 응답은 `test/fixtures/chat/{anthropic,openai}/*.sse|json`(키 없이 손으로 만든 것 — 실제 응답을 녹화하면 교체).

| 파일 | 내용 | 단계 |
|---|---|---|
| `test/domain/chat/usecase/chat_session_test.dart` | 중립 이벤트로 도구 루프 · `StopKind` 분기 · 라운드마다 usage 기록, 실패 요청은 기록 안 함 · `vendorState` 를 건드리지 않고 다음 요청에 그대로 · **기존 테스트가 그대로 통과(동작 불변)** | ① |
| 〃 | 인증 오류 → `invalid`, 성공 → `valid` | ② |
| 〃 | 선택 모델/기본 모델 · 빠른 출력 전달(지원 안 하면 false) · 사진 못 보는 모델이면 `view_photos` 없음 · 이전 사진 뺌 | ③ |
| 〃 | 넘김 규칙: 같은 모델은 원본 · 다른 모델은 `vendorState` 없이 · 다른 벤더 턴은 글만 | ③ · ④ |
| `test/domain/chat/tool/life_tools_test.dart` | `definitions` 가 `ToolSpec`(이름 · 스키마 그대로) | ① |
| `test/data/chat/anthropic_chat_model_test.dart` | 중립 ↔ Messages 변환 · thinking 서명이 `vendorState` 로 왕복 · usage 파싱 · cancel 하면 요청이 닫힘 · 요청에 저장 관련 필드 없음 | ① |
| 〃 | `listModels`(200/401/403/네트워크) | ② |
| 〃 | 요청 모델 id 가 `ModelRequest.model` · fast mode 필드 | ③ |
| `test/data/chat/sse_lines_test.dart` (새) | 여러 줄 data · 대기 시간 | ① |
| `test/domain/chat/api_key_mask_test.dart` (새) | 벤더별 접두사 + 4글자 + `••••` · 접두사 불일치 · 짧은 키 · 점 개수 고정 · 본문 5번째 이후 없음 · `vendorOfKey` · `sk-admin-` 거절 | ② |
| `test/data/chat/secure_chat_settings_test.dart` | `connection()` 에 원문 없음 · `connect` 가 새 키를 쓴 뒤에만 기존을 지움(쓰기 실패 시 기존 유지) · 옛 `anthropic_api_key` · `chat.consented` 이전 · 읽기 예외면 지우고 미연결 | ② (동의 벤더 ④) |
| `test/presentation/settings/cubit/chat_settings_cubit_test.dart` | `apiKey()` 를 부르지 않음 · 저장 결과(정상 · 확인 못 함 → 경고 대기 · 잘못 · 쓰기 실패) · 끊기 · toString 에 원문 없음 | ② (바꾸기 ④) |
| `test/presentation/settings/widget/chat_settings_section_test.dart` | §6.1 상태 표 각 줄(로고 · "연결됨") · 키 대화상자(토글 · 접두사 · 다른 벤더 키 안내 · 로딩 · 인라인 오류) · 요금 경고: 정상 · 확인 못 함 모두 뜸, [취소]면 저장 안 함, [확인]이면 저장 + 스낵바 · 끊기 스낵바 | ② (벤더 바꾸기 확인 창 ④) |
| `test/presentation/chat/widget/chat_vendor_icon_test.dart` (새) | 벤더마다 자산 경로 · 자산을 못 읽으면 글자 원형 | ② |
| `test/presentation/settings/widget/row_highlight_test.dart` (새) | `play: true` 면 push 전환 뒤 재생 · 두 번 · 총 길이 · `false` 면 없음 · 애니메이션 줄이기면 없음 · 탭하면 꺼짐 | ② |
| 물어보기 설정 · 알람 설정 화면 테스트(재구성이 만든 파일 옆) | 강조 인자 true 면 연결 행 · 권한 행 glow, 기본은 없음 | ② |
| `test/presentation/chat/page/chat_tab_test.dart` | 실패 말풍선 [설정 열기] (`invalidKey` · `noKey` · `quotaExceeded` 만) | ② |
| 〃 | `noModels` + 다시 시도 · 사라진 모델 스낵바 · 모델 칩 표시 | ③ |
| 〃 | 벤더 바뀌면 동의 다시 · 대화는 남음 | ④ |
| `test/presentation/shell/page/main_shell_page_test.dart` | 물어보기 [설정 열기] → 물어보기 설정 화면이 강조와 함께 열림 · 알람 배너 → 알람 설정 화면 권한 행 강조 · ⋮ 로 열면 강조 없음(재구성 테스트 위에 덧붙임) | ② |
| `test/data/chat/prefs_chat_model_catalog_test.dart` (새) | 거르기(도구 미지원 제외) · 최신순 · 추천 계열 최신(Claude Sonnet · GPT 별칭 우선) · 계열 없음 → 최신 · 24시간 · 사라진 모델 → 기본 · 첫 목록은 모두 본 것 · NEW · 더 새 모델 점 · 빠른 출력 지원 판정 | ③ |
| `test/presentation/chat/widget/model_chip_test.dart` · `model_picker_sheet_test.dart` (새) | 최신순 · 추천 · NEW · 사용 중 · 사진 못 봄 · 고르면 저장 · 열면 NEW 사라짐 · 점 · busy 면 비활성 · 빠른 출력 스위치는 지원 모델에서만, 처음 켤 때 요금 안내 확인, 번개 표시 | ③ |
| `test/data/chat/openai_chat_model_test.dart` (새) | 요청에 `store: false` · `include` 항상 · 도구 정의 변환 · 함수 호출/결과 왕복 · encrypted reasoning 왕복 · usage · cancel · 429 `insufficient_quota` vs 속도 제한 · 401 · 404 · `listModels` 거르기 입력 | ④ |
| `test/presentation/settings/widget/vendor_picker_sheet_test.dart` (새) | Claude · GPT 만 보임(Grok 없음) · 지금 벤더 체크 · 고를 수 없음 | ④ |

## 13. 완료 조건 (MVP = ①~④)

- [ ] ① 뒤: 중립 계약으로 바꿔도 기존 물어보기 테스트 · 기기 동작이 그대로이고, 요청마다 usage 가 `ChatUsageLog` 로 넘어간다
- [ ] 키를 저장하면 확인 → 요금 경고(확인 못 함일 때도) → 등록 순서로 진행되고, 연결 행에 벤더 로고 · "연결됨" · 마스킹 키(`sk-ant-api03-Ab3x••••`)가 보인다
- [ ] 원문 키는 설정 · 물어보기 화면 쪽 코드와 상태 · 로그에 없다(`apiKey()` 호출처는 `ChatSession` · 목록 갱신 둘)
- [ ] 물어보기 [설정 열기] · 실패 말풍선 [설정 열기] → 물어보기 설정 화면이 열리고 연결 행이 두 번 glow, 알람 권한 배너 → 알람 설정 화면 권한 행이 두 번 glow. ⋮ 로 열면 glow 없음, 애니메이션 줄이기면 glow 없음
- [ ] 모델 칩에서 최신순 목록 · 추천(Claude Sonnet 최신 · GPT 플래그십 별칭) · NEW · 새 모델 점이 보이고 고른 모델이 저장된다. 고른 모델이 사라지면 추천으로 돌아가며 한 번 알린다
- [ ] 빠른 출력 스위치가 지원 모델에서만 보이고, 켤 때 요금 안내를 확인받는다
- [ ] Claude · GPT 각각 연결 · 질문 → 도구 호출 → 답 · 사진 보기(가능한 모델) · 잘못된 키 · 요금 부족 메시지가 동작한다
- [ ] 벤더를 바꾸면 기존 키가 지워지고 다음 질문 때 동의를 다시 받으며, 대화는 이어진다. 같은 벤더 키 교체 · 모델 변경으로는 다시 묻지 않는다
- [ ] OpenAI 요청에 `store: false` 가 늘 들어가고, Anthropic 어댑터에는 "해당 옵션 없음"이 주석 · 테스트로 남아 있다
- [ ] 벤더 시트에 Grok 이 보이지 않는다
- [ ] `flutter analyze` 0 · walk 전체 테스트 통과 · 에뮬레이터에서 Claude · GPT 실제 키로 확인
- [ ] §10.3 확인 결과를 walk `history.md` 에 남긴다
- [ ] walk `plan.md` · `history.md` · `testing.md` · `status.md` 를 단계마다 갱신

## 14. 구현 단계 (Q15)

**순서: 화면 재구성 → 이 기획.** [재구성 설계](2026-11-01-walk-nav-regroup-design.md)(설정 탭 삭제 · 설정 push 화면 · 앱바 ⋮)가 먼저 들어간다.
①은 화면을 건드리지 않아 재구성과 나란히 해도 되지만, **② 부터는 재구성이 들어간 뒤**에 한다. 겹치는 파일:

| 파일 | 재구성이 하는 일 | 이 기획이 그 뒤에 하는 일 |
|---|---|---|
| `lib/presentation/shell/page/main_shell_page.dart` | 탭 3개 · `ShellTab.settings` 삭제 · `onOpenSettings` 를 "설정 화면 push" 로 | push 할 때 강조 인자 넘기기(②) |
| `lib/presentation/chat/page/chat_tab.dart` | 앱바 = [새 대화] + ⋮(물어보기 설정 · 앱 설정) | 앱바 아래 모델 칩(③) · `noModels` 상태(③) · 실패 말풍선 [설정 열기] 연결(②) |
| `lib/presentation/settings/page/settings_page.dart` | **삭제** | 없음(이 기획은 새로 만들어진 물어보기 · 알람 설정 화면만 고친다) |
| `lib/presentation/settings/widget/chat_settings_section.dart` | 물어보기 설정 화면 안에서 재사용만 | 내부 전부(②~④) |
| `lib/presentation/alarm/page/alarm_list_page.dart` · 알람 설정 화면 | 권한 배너 → 알람 설정 push · 권한 행 이동 | 권한 행 `RowHighlight`(②) |

| 단계 | 내용 | 끝나면 보이는 것 | 먼저 맞출 것 |
|---|---|---|---|
| ① 중립 계약 + Claude 어댑터 이전 **(구현됨)** | §8 형식 · `AnthropicChatModel` 변환 · `LifeTools` → `ToolSpec` · usage 이벤트 · cancel 자리 · `NoopChatUsageLog`. 모델 id 는 아직 지금 값 그대로 | 화면 변화 없음(동작 그대로) | 대화 기록 기획 · 체감 속도 기획과 이벤트 이름(§8.2) |
| ② 키 UX **(구현됨 2026-11-02)** | §1~§4 · 마스킹 · 저장 시 확인 · 요금 경고 · 행 glow · 설정 화면 강조 열기 · 로고 · 백업 제외 · 실패 말풍선 [설정 열기]. 벤더는 Claude 하나 | 불편 1~3 해결 | **화면 재구성이 먼저 들어가 있어야 한다** · 브랜드 가이드(§10.3-3) |
| ③ 모델 목록 · 칩 | §6.2~§6.4 · 카탈로그 · 모델 id 고정 제거 · 빠른 출력 스위치 | 모델 칩 | fast mode 필드(§10.3-1) |
| ④ GPT | `OpenAiChatModel` · 레지스트리 · 벤더 시트 · 벤더 바꾸기 · 재동의 · 넘김 규칙 | 벤더 선택 | §10.3-2 · §10.3-4 |
| ⑤ Grok (후속) | xAI 문서 확인 → 어댑터 재사용 여부 결정 → 벤더 시트에 추가 · 로고 | Grok 연결 | §10.3-5 |

---

## 열린 질문

없음.
