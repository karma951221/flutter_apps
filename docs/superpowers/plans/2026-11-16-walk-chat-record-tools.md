# walk 물어보기 기록 도구 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 물어보기 모델이 위치 기록(머문 곳 · 자주 간 곳) · 알람 설정 · 날씨 예보를 도구로 조회하게 하고, 위치가 새로 포함되므로 전송 동의를 한 번 다시 받는다.

**Architecture:** 새 도구 클래스 셋(`LocationTools` · `AlarmTools` · `WeatherTools`)을 `lib/domain/chat/tool/` 에 두고, `LifeTools` 가 생성자로 받아 `definitionsFor` 끝에 정의를 붙이고 `run` 을 위임한다. `ChatSession` 은 `LifeTools` 만 알므로 "내 기록 참고하기"(`useRecords`) 게이트를 그대로 탄다. 동의는 `SecureChatSettings` 에 범위 버전을 더해 낮으면 `consentedVendor` 가 null 을 돌려주게 한다.

**Tech Stack:** Flutter · Dart 3, injectable, freezed, mocktail, flutter_test.

**Spec:** [2026-11-16-walk-chat-record-tools-design.md](../specs/2026-11-16-walk-chat-record-tools-design.md)

## Global Constraints

- 좌표(위도 · 경도)는 어떤 도구 결과에도 넣지 않는다. 이름을 못 얻은 곳은 `place: null`.
- 실패 모양은 기존과 같게 `{"error": code}` + `isError: true` + `ToolSummary(kind, count: 0, isError: true)`.
- 날짜 입력은 `YYYY-MM-DD`(로컬), 양 끝 포함. `visited_places` 최대 31일, `frequent_places` 최대 366일, 넘으면 `to` 기준으로 자르고 `clamped: true`.
- `visited_places` 머문 곳 최대 150개(최근 것 남김, `truncated: true`). 한 번 부를 때 새 이름 조회(Geocoder) 최대 20곳.
- 동의 범위 버전: 위치 포함 = 2. 저장 키 `chat.consentScope`.
- 채팅 화면(`presentation/chat/page/`) 위젯은 건드리지 않는다. 진행 줄 문구(`widget/chat_progress_text.dart`)만 case 를 더한다.
- 생성 파일(`.freezed.dart` · `.g.dart` · `injection.config.dart` · l10n `app_localizations*.dart`)은 build_runner · `flutter gen-l10n` 으로만 갱신한다.
- 명령은 `apps/walk` 에서: `flutter test <path>`, `flutter analyze`. l10n 은 `packages/l10n` 에서 `flutter gen-l10n`.

## Review Focus

1. 위치 기록을 한 번도 켜지 않은 사용자 → `location_not_recorded`, 모델이 일기 장소로 답하도록 프롬프트가 안내(Task 2 · 5 테스트).
2. 자정을 넘긴 머묾(밤새 집) → 그 날 범위에 잘려 보이고 `end_date` 가 시작일과 다르면 함께 준다(Task 2 테스트).
3. Geocoder 오프라인 → `nameFor` 가 null 이어도 도구는 성공하고 `place: null`(Task 2 테스트).
4. 기존 동의 사용자(벤더 저장 · 범위 키 없음, 옛 `chat.consented` 포함) → 다시 동의 필요(Task 6 테스트).
5. 날씨 위치 실패 + 캐시 25시간 전 → `weather_unavailable`; 캐시 2시간 전 → 캐시로 답하고 `stale: true`(Task 4 테스트).

---

### Task 1: 도구 입력 도우미 추출 + 지도 openEnd 공유

**Files:**
- Create: `lib/domain/chat/tool/tool_input.dart`
- Create: `lib/domain/location/usecase/open_end.dart`
- Modify: `lib/domain/chat/tool/life_tools.dart`(private 도우미를 새 파일로 대체), `lib/presentation/map/cubit/map_view_cubit.dart`(`_openEnd` 판정을 새 함수로)
- Test: `test/domain/chat/tool/tool_input_test.dart`, `test/domain/location/usecase/open_end_test.dart`

**Interfaces — Produces:**
- `DateTime? parseToolDate(Object? v)`
- `class ToolRange { DateTime from; DateTime to; bool clamped; DateTime get end /* to 의 23:59:59.999 */; Map<String,Object?> get clampJson; }`
- `ToolRange? toolRange(Map<String,Object?> input, {required int maxDays})`
- `String toolDay(DateTime d)` (`YYYY-MM-DD`), `String toolTime(DateTime d)` (`HH:mm`)
- `ToolResult toolError(String code, ChatToolKind kind)`
- `DateTime? stayOpenEnd(List<LocationPoint> points, RecorderStatus status, DateTime now)` — MapViewCubit `_openEnd` 의 판정부(상태 읽기 실패 처리는 호출자). 반환은 UTC.

- [ ] **Step 1:** `tool_input_test.dart` — `toolRange({'from':'2026-01-01','to':'2026-03-01'}, maxDays: 31)` → `from == DateTime(2026,1,30)`, `clamped == true`; `from` > `to` → null; `'2026-02-30'` → null; `toolDay(DateTime(2026,3,4)) == '2026-03-04'`. `open_end_test.dart` — 정지 감지 점이 마지막 + running(since 이전) → `now.toUtc()`; off → null; 마지막 점이 since−6분 → null.
- [ ] **Step 2:** 실행해 실패 확인: `flutter test test/domain/chat/tool/tool_input_test.dart test/domain/location/usecase/open_end_test.dart`
- [ ] **Step 3:** 두 파일 구현, `LifeTools` · `MapViewCubit` 이 쓰게 바꾼다(동작 변화 없음).
- [ ] **Step 4:** `flutter test test/domain/chat/tool test/domain/location test/presentation/map` 통과.
- [ ] **Step 5:** 커밋 `refactor(walk): 도구 입력 도우미 · 머문 곳 열린 끝 판정을 나눈다`

### Task 2: `LocationTools` — `visited_places` · `frequent_places`

**Files:**
- Create: `lib/domain/chat/tool/location_tools.dart`(`@lazySingleton`)
- Test: `test/domain/chat/tool/location_tools_test.dart`

**Interfaces — Consumes:** Task 1 전부, `LocationRepository`(`hasAnyPoint` · `pointsAround` · `placeName`), `LocationSync.run`, `LocationRecorder.status`, `StayNamer.nameFor`, `TrackAnalyzer().analyze`, `frequentPlaces(stays, limit: 10)`, `gridKey`, `Clock`.
**Produces:** `LocationTools(LocationRepository, LocationSync, LocationRecorder, StayNamer, Clock)`, `static const names = {'visited_places','frequent_places'}`, `List<ToolSpec> get definitions`, `Future<ToolResult> run(String name, Map<String,Object?> input)`.

동작:
- 둘 다 먼저 `sync.run()`(예외 무시), `hasAnyPoint()` false 면 `toolError('location_not_recorded', kind)`.
- `recording`: `status()` 가 running → `"on"`, off → `"off"`, blocked → `"blocked"`, 예외 → `"unknown"`.
- 이름: 머문 곳을 **최근부터** 돌며 gridKey 별로 `repo.placeName(key)` 캐시를 먼저 보고, 없으면 새 조회 20곳까지만 `namer.nameFor`. 나머지는 null.
- `visited_places` 결과: `{"stays":[{"date","start","end","end_date"?(시작일과 다를 때만),"minutes","place","ongoing"?(openEnd 로 닫힌 것만 true)}], "recording", "truncated", clamped?}`. 시각은 로컬.
- `frequent_places`: 범위를 31일 덩어리로 나눠 `pointsAround`+`analyze(clip)` 해 머문 곳을 모은다(덩어리 경계에 걸친 머묾은 둘로 셀 수 있음 — 허용). 결과 `{"places":[{"place","visits","hours"(소수 1자리),"last"(그 곳 마지막 머묾 시작일)}], "recording", clamped?}`.
- `ToolSummary(kind: ChatToolKind.visitedPlaces / frequentPlaces, count)` — Task 5 가 enum 을 더하므로 이 Task 에서 enum 두 값을 먼저 더한다(`tool_summary.dart`, `chatToolKindOf` 매핑 포함).

- [ ] **Step 1:** 테스트(mock 저장소 · 고정 Clock `2026-11-16 12:00`):
  - 점 없음 → `isError`, json `{"error":"location_not_recorded"}`.
  - 11-14 09:00~18:40 한 곳(10분 간격 점) → stays 1개, `start:'09:00'`, `end:'18:40'`, `minutes:580`, 결과 json 에 `lat`/`lng` 문자열 없음.
  - 11-13 22:00~11-14 08:00 머묾, 범위 11-13~11-14 → `date:'2026-11-13'`, `end_date:'2026-11-14'`.
  - `nameFor` null(오프라인) → `place: null`, `isError` false.
  - 서로 다른 격자 25곳, 캐시 없음 → `nameFor` 호출 20번, 가장 오래된 5곳 `place: null`.
  - 160곳 → 150개, 첫 항목이 11번째로 오래된 것, `truncated: true`.
  - 범위 40일 → `clamped: true`.
  - `frequent_places` 같은 격자 3번 + 다른 격자 1번 → 첫 항목 `visits: 3`, 좌표 없음.
- [ ] **Step 2:** `flutter test test/domain/chat/tool/location_tools_test.dart` 실패 확인.
- [ ] **Step 3:** 구현.
- [ ] **Step 4:** 통과 확인.
- [ ] **Step 5:** 커밋 `feat(walk): 물어보기가 머문 곳 · 자주 간 곳을 조회한다`

### Task 3: `AlarmTools` — `list_alarms`

**Files:** Create `lib/domain/chat/tool/alarm_tools.dart`(`@lazySingleton`), Test `test/domain/chat/tool/alarm_tools_test.dart`, Modify `tool_summary.dart`(`ChatToolKind.alarms`, `'list_alarms'`).

**Produces:** `AlarmTools(AlarmUseCase)`, `static const name = 'list_alarms'`, `ToolSpec get definition`, `Future<ToolResult> run()`.

결과: `{"alarms":[{"time":"07:00","repeat":["mon",…] (Weekday.name, 비면 빈 배열),"label":null|"…","enabled","next":"2026-11-17T07:00"|null(nextRings[id]),"skip_next":skippedAt!=null,"snooze_minutes","snooze_limit"}],"paused":{"from","until"}|null}`. 소리 · 볼륨 · 페이드는 넣지 않는다.

- [ ] **Step 1:** 테스트: 반복 알람(월 · 수, 라벨 '출근', next 있음) → 위 모양 그대로; 빈 라벨 → `label: null`; `sound` 관련 키 없음; `pause()` 있으면 `paused` 날짜; `list()` 예외 → `tool_failed`.
- [ ] **Step 2 ~ 5:** 실패 확인 → 구현 → 통과 → 커밋 `feat(walk): 물어보기가 알람 설정을 조회한다`

### Task 4: `WeatherTools` — `weather_forecast`

**Files:** Create `lib/domain/chat/tool/weather_tools.dart`(`@lazySingleton`), Test `test/domain/chat/tool/weather_tools_test.dart`, Modify `tool_summary.dart`(`ChatToolKind.weather`, `'weather_forecast'`).

**Produces:** `WeatherTools(WeatherRepository, WeatherLocator, WeatherCache, Clock)`, `static const name = 'weather_forecast'`, `ToolSpec get definition`, `Future<ToolResult> run()`.

흐름(날씨 탭 규칙과 같은 값 — `WeatherCubit.freshFor`(10분) · `cacheMaxAge`(24시간)을 domain 상수로 옮기지 말고 같은 값을 상수로 둔다):
1. 캐시가 10분 안 → 캐시 사용.
2. 아니면 `locate()`; located → `fetch` → `placeName`(예외는 null) → `cache.write(CachedForecast(...))` → 사용.
3. 위치 실패 · fetch 예외 → 캐시가 24시간 안이면 사용 + `stale: true`, 아니면 `weather_unavailable`.

결과: `{"place","fetched_at":"YYYY-MM-DDTHH:mm","stale"?,"current":{"temp","feels_like","condition"(enum name),"humidity","wind","precipitation"},"hourly":[지금 이후 최대 24칸 {"time","temp","pop","precipitation","condition"}],"daily":[최대 7 {"date","condition","max","min","pop","precipitation"}]}`. 좌표 없음.

- [ ] **Step 1:** 테스트: 캐시 5분 전 → `fetch` 안 부름; 캐시 없음 + located → `fetch` · `write` 호출, json 에 `lat` 없음; 위치 실패 + 캐시 2시간 전 → `stale: true`; 위치 실패 + 캐시 25시간 전 → `weather_unavailable`; fetch 예외 + 캐시 없음 → `weather_unavailable`.
- [ ] **Step 2 ~ 5:** 실패 확인 → 구현 → 통과 → 커밋 `feat(walk): 물어보기가 날씨 예보를 조회한다`

### Task 5: `LifeTools` 연결 · 프롬프트 · 진행 줄

**Files:** Modify `lib/domain/chat/tool/life_tools.dart`, `lib/domain/chat/usecase/chat_session.dart`(`_recordRules` 만), `lib/presentation/chat/widget/chat_progress_text.dart`, `packages/l10n/lib/l10n/app_{ko,en,ja}.arb`; 생성: `injection.config.dart`, l10n. Test: `test/domain/chat/tool/life_tools_test.dart`, `test/domain/chat/tool/tool_summary_test.dart`, `test/domain/chat/usecase/chat_session_test.dart`, 진행 줄 위젯 테스트(있으면 그 파일).

- `LifeTools(diary, activity, archiver, rings, images, location, alarms, weather)` — 끝에 셋을 더한다. `_all` 끝에 `location.definitions`, `alarms.definition`, `weather.definition`. `run` 은 이름으로 위임.
- `daily_steps` 설명: "걷기 탭의 하루별 걸음 수를 본다. 양 끝 날짜를 포함한다."
- `_recordRules` 의 목록: `'일기 · 위치 기록(머문 곳) · 걸음 수 · 알람(설정 · 기상 기록) · 날씨 예보'`(위키면 끝에 `' · 위키'`), 그리고 한 줄 추가: `'어디 갔는지는 위치 기록 도구로 찾고, 위치 기록이 없으면 일기 장소로 답하며 그렇다고 밝힌다. 지난 날씨는 기록이 없다.\n'`.
- l10n: `walkChatToolVisitedPlaces` "머문 곳 보는 중", `walkChatToolFrequentPlaces` "자주 간 곳 보는 중", `walkChatToolAlarms` "알람 보는 중", `walkChatToolWeather` "날씨 보는 중" (en/ja 도 번역).

- [ ] **Step 1:** 테스트: `definitionsFor(images: true)` 이름 끝 4개가 `visited_places, frequent_places, list_alarms, weather_forecast`; `images: false` 도 넷 포함; `run('list_alarms', {})` 가 `AlarmTools.run` 결과를 그대로; `chatToolKindOf` 네 이름 매핑; 기록 켠 시스템 프롬프트에 `'위치 기록(머문 곳)'` · `'일기 장소로 답하며'` 포함, 기록 끈 프롬프트에는 없음.
- [ ] **Step 2 ~ 4:** 실패 확인 → 구현(`dart run build_runner build --delete-conflicting-outputs`, `flutter gen-l10n`) → `flutter test test/domain/chat test/presentation/chat` 통과.
- [ ] **Step 5:** 커밋 `feat(walk): 기록 참고 질문에 위치 · 알람 · 날씨 도구를 붙인다`

### Task 6: 동의 범위 버전 · 안내 문구

**Files:** Modify `lib/data/chat/secure_chat_settings.dart`, `packages/l10n/lib/l10n/app_{ko,en,ja}.arb`(`walkChatConsentNotice` · `walkChatSettingsNotice`). Test `test/data/chat/secure_chat_settings_test.dart`.

- `static const consentScopeKey = 'chat.consentScope'`, `static const consentScope = 2`.
- `consentedVendor`: 옛 키 정리는 그대로 하되, `(getInt(consentScopeKey) ?? 1) < consentScope` 면 null. `setConsented` 는 벤더와 함께 범위 2를 쓴다.
- 문구 ko: "질문과, 답에 필요한 일기 · 사진 · 위치 기록(머문 곳 이름 · 시간) · 걸음 · 알람 · 기상 기록이 연결한 AI({vendor})로 전송돼요. …"(뒷부분 그대로). en/ja 같은 뜻.

- [ ] **Step 1:** 테스트: 벤더만 저장(범위 키 없음) → null; 옛 `chat.consented: true` → null(그리고 옛 키는 지워짐); `setConsented(openai)` 뒤 → `openai`; 범위 1 저장 → null. 기존 테스트 중 옛 동의가 anthropic 으로 옮겨진다는 기대는 새 결정에 맞게 고친다.
- [ ] **Step 2 ~ 4:** 실패 확인 → 구현 → `flutter test test/data/chat test/presentation/chat test/domain/diary` 통과.
- [ ] **Step 5:** 커밋 `feat(walk): 위치가 더해진 전송 범위로 한 번 다시 동의를 받는다`

### Task 7: 검증 · 문서

- [ ] `flutter analyze` 0 · `flutter test` 전체 통과 · `apps/trader` 에서 `flutter test test/convention`.
- [ ] `apps/walk/docs/status.md`(물어보기 절에 항목 · 검증 수치), `history.md`, `testing.md`(기기 시나리오: 위치 기록 켠 폰에서 "지난주 어디 갔어?" · 위치 기록 끈 상태 · "내 알람 몇 시야?" · "내일 비 와?" · 재동의 화면) 갱신.
- [ ] 에뮬레이터: 가짜 위치(`adb emu geo fix`)로 점을 쌓고 질문 → 답 확인. 실제 키가 없으면 그 사실을 status 에 남긴다.
- [ ] 커밋 `docs(walk): 물어보기 기록 도구를 기록한다`
