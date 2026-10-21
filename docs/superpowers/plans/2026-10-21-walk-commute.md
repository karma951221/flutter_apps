# walk 통근 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. 태스크마다 스펙의 해당 절을 함께 읽는다.

**Goal:** Life Tool(`apps/walk`)에 **통근** 탭을 더한다. 집 · 회사 좌표를 저장하고, 조회 버튼을 누르면 ODsay 지하철 경로 + 서울시 실시간 도착으로 첫 승차역의 다음 열차 2대(몇 분 후 · 몇 번째 전역), 걸어서 탈 수 있는지, 도착 예상 시각을 보여준다.

**Architecture:** walk 계층(`lib/{core,data,domain,presentation}`) 아래 `commute/` 기능 폴더. 도메인은 순수 Dart(엔티티 · 판단 · 도착 예상 · 경로 서명)와 인터페이스 5개(`PlaceRepository` · `RoutePreferenceRepository` · `RouteFinder` · `SubwayArrivalSource` · `AddressSearch`), 조립은 `CommuteUseCase`. 데이터는 `http` 로 ODsay · 서울 API 를 부르는 구현 2개와 `shared_preferences` 저장소, geocoding 주소 검색. 화면은 `CommuteCubit` 하나와 탭 페이지 · 시트 2개. 네트워크는 사용자가 누를 때만.

**Tech Stack:** Flutter / Dart(walk 기존 버전), flutter_bloc, freezed 3, injectable/get_it, `http`(새 의존성), shared_preferences, geocoding 5, workspace 패키지 `location` · `core` · `design_system` · `l10n`.

**Spec:** [walk 통근 설계](../specs/2026-10-21-commute-eta-design.md) — 결정(§3) · 데이터 맞추기(§5) · 화면(§6) · 계산(§7) · 키(§8) · 위험(§10)의 단일 기준.

## Global Constraints

- 안드로이드만. 명령은 `apps/walk` 에서: `flutter test` · `flutter analyze` · `dart run build_runner build --delete-conflicting-outputs`.
- **API 키는 아직 없다.** Task 1–8 은 키 없이 끝나야 한다(픽스처 · `MockClient` · fake). 실제 응답 확인은 Task 9.
- 네트워크 호출은 **사용자가 조회 · 경로 바꾸기를 누를 때만**. 자동 새로고침 · 타이머 호출 · 알림 · 위젯 · 출발 감지 없음.
- 판단은 **걷는 시간 기준만**: 도보 `w`(첫 지하철 구간 앞 도보 구간 합), 여유 `kStationBufferMinutes = 1`, 열차 `t`분 뒤일 때 `t >= w + 1` 이면 탈 수 있음. 뛰는 시간은 계산 · 표시하지 않는다.
- 실시간 분이 없고 정거장 수만 있으면 추정: `ceil(stationsAway × 첫 지하철 구간 sectionTime ÷ stationCount)`, `estimated = true`, 화면 "약 n분". 추정값도 판단 · 도착 예상에 쓴다.
- 경로는 지하철만(ODsay `SearchPathType=1`). 결과는 저장하지 않는다. 조회 2분 경과(`kStaleAfter = Duration(minutes: 2)`) 시 흐리게 + "다시 조회하세요".
- 탭 순서 `ShellTab { alarm, walk, diary, commute, settings }`, 기본 첫 탭 `walk` 유지. 방향 기본값: 시각 `hour < 12` → 출근, 아니면 퇴근.
- 키: `--dart-define-from-file=config/commute_keys.json`(gitignore), 키 이름 `ODSAY_API_KEY` · `SEOUL_SUBWAY_API_KEY`. 키가 비면 네트워크 없이 "키 없음" 상태.
- 의존: 트레이더 `feature_*` · `supabase_flutter` 금지(`test/convention/package_boundary_test.dart`). `apps/commute` 는 건드리지 않는다.
- l10n: `packages/l10n/lib/l10n/app_{ko,en,ja}.arb` 에 **`walkCommute*`** 접두사(기존 `commute*` 키는 다른 앱 것 — 재사용 · 수정 금지). ko 에 `@key.description` 필수. `cd packages/l10n && flutter gen-l10n` 생성물 커밋. ARB 변경 후 `cd apps/trader && flutter test test/convention` 통과.
- CLAUDE.md UI 규칙: `AppButton` · `AppPlaceholder` · `AppListTile` · `AppSnackBar` 우선, 색 · 여백 · 모서리는 `Theme.of(context)` · `AppSpacing` · `AppRadius`. Freezed 는 primary constructor(단일) · `sealed` + named factory(union)만, 분기는 `switch`. 생성 파일 직접 수정 금지. 테스트는 `lib/…` ↔ `test/…` 1:1.
- 시간은 `core` 의 `Clock` 주입(이미 `RegisterModule` 에 있음).
- 커밋 `feat(walk): …` 등 한국어 + 빈 줄 + `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. 경로 지정 `git add`.
- TDD. 각 태스크 끝: `flutter analyze` 0 · `flutter test` 전부 통과(기준선은 Task 1 시작 때 개수를 기록). 네이티브 설정을 건드린 태스크는 `flutter build apk --debug` 성공.

## Review Focus

스펙이 직접 말하지 않지만 실제로 부딪힐 상황. 각 테스트는 소유 태스크에 넣었다.

1. **환승역 · 양방향 응답** — 서울 API 는 역의 모든 노선 · 양방향 열차를 준다(신논현 = 9호선 + 신분당선). `subwayId` + 방향으로 걸러야 한다 → Task 3 `filters other lines and opposite direction`.
2. **수신 시각이 오래된 응답** — `now - recptnDt > barvlDt` 면 음수 분이 된다. 0으로 막는다 → Task 3 `clamps to zero when data is older than barvlDt`.
3. **역 이름 불일치 · 미지원 노선** — ODsay 역 이름이 서울 API 에서 0건이거나 노선 코드 매핑이 없으면 오류가 아니라 "실시간 없음"으로 경로 · 예상만 → Task 5 `realtime unavailable keeps route and eta`.
4. **집 · 회사가 너무 가깝거나 같은 좌표** — ODsay 는 오류 객체를 준다(가까운 거리 코드 등). 앱이 죽지 않고 "경로 없음" → Task 4 `error body maps to noRoute/server`.
5. **조회 중 연타 · 네트워크 끊김** — 로딩 중 두 번째 조회는 무시, 실패 후 버튼 다시 활성 → Task 6 `ignores query while loading` · `failure then retry`.

---

### Task 1: 의존성 · 키 · 네이티브 설정

**Files:**
- Modify: `apps/walk/pubspec.yaml`(dependencies 에 `http: ^1.2.0`)
- Modify: `apps/walk/.gitignore`(`/config/commute_keys.json`)
- Create: `apps/walk/config/commute_keys.example.json`
- Create: `apps/walk/lib/core/config/commute_api_keys.dart`
- Modify: `apps/walk/android/app/src/main/AndroidManifest.xml`(`android.permission.INTERNET` — 지금 main 매니페스트에 없다, `android:networkSecurityConfig="@xml/network_security_config"`)
- Create: `apps/walk/android/app/src/main/res/xml/network_security_config.xml`
- Test: `apps/walk/test/core/config/commute_api_keys_test.dart`, `apps/walk/test/convention/commute_network_config_test.dart`

**Interfaces:**
- Produces: `class CommuteApiKeys { const CommuteApiKeys({required String odsay, required String seoulSubway}); factory CommuteApiKeys.fromEnvironment(); final String odsay; final String seoulSubway; bool get isComplete; }` — `fromEnvironment` 는 `String.fromEnvironment('ODSAY_API_KEY')` · `('SEOUL_SUBWAY_API_KEY')`. `isComplete` = 둘 다 trim 후 비지 않음.

- [ ] **Step 1: 실패 테스트** — `commute_api_keys_test.dart`: `isComplete` 가 `('a','b')` true, `('', 'b')` · `('a', '  ')` false. `commute_network_config_test.dart`: 매니페스트 문자열에 `android.permission.INTERNET` 과 `@xml/network_security_config` 포함, `network_security_config.xml` 에 `<domain includeSubdomains="false">swopenapi.seoul.go.kr</domain>` 이 `cleartextTrafficPermitted="true"` 블록 안에 있음, `.gitignore` 에 `/config/commute_keys.json`.
- [ ] **Step 2: 실행해 실패 확인** — `flutter test test/core/config test/convention/commute_network_config_test.dart` → FAIL.
- [ ] **Step 3: 구현** — 위 파일들. example json 은 `{"ODSAY_API_KEY": "", "SEOUL_SUBWAY_API_KEY": ""}`. cleartext 는 `swopenapi.seoul.go.kr` 한 도메인만(base-config 는 기본값 유지). `flutter pub get`.
- [ ] **Step 4: 통과 확인** — 같은 명령 PASS, `flutter analyze` 0, `flutter build apk --debug` 성공.
- [ ] **Step 5: 커밋** — `chore(walk): 통근 API 키 주입 · http · 인터넷 권한을 준비한다`

### Task 2: 도메인 — 엔티티 · 판단 · 도착 예상 · 경로 서명

**Files:**
- Create: `apps/walk/lib/domain/commute/entity/{place.dart, commute_direction.dart, transit_route.dart, train_arrival.dart, catch_verdict.dart, commute_result.dart}`
- Create: `apps/walk/lib/domain/commute/commute_policy.dart`
- Test: `apps/walk/test/domain/commute/commute_policy_test.dart`, `apps/walk/test/domain/commute/entity/transit_route_test.dart`

**Interfaces:**
- Produces (freezed 패턴은 Global Constraints):
  - `enum PlaceKind { home, work }` · `class Place { PlaceKind kind; double lat; double lng; String label; }` + `Map<String,Object?> toJson()` / `static Place? fromJson(Object? json)`(손으로, 깨진 값은 null)
  - `enum CommuteDirection { toWork, toHome }` + `PlaceKind get origin` / `destination`, `static CommuteDirection defaultAt(DateTime now)`(`hour < 12` → toWork)
  - `sealed class RouteLeg`: `RouteLeg.walk({required int minutes})` = `WalkLeg`, `RouteLeg.subway({required int minutes, required String lineName, required int odsayLaneCode, required String startStation, required String endStation, required int wayCode, required String wayName, required int stationCount})` = `SubwayLeg`
  - `class TransitRoute { int totalMinutes; int transferCount; List<RouteLeg> legs; }` + getters `SubwayLeg? get firstSubway`, `int get walkToStationMinutes`(첫 지하철 앞 `WalkLeg` 합), `int get minutesFromBoarding`(첫 지하철 포함 이후 모든 구간 합), `String get signature`(지하철 구간마다 `'$odsayLaneCode:$startStation>$endStation'` 을 `'|'` 로)
  - `class TrainArrival { int? minutes; bool estimated; int? stationsAway; String message; String? destination; }`
  - `sealed class CatchVerdict`: `.catchFirst()` · `.catchSecond()` · `.missBoth()` · `.unknown()`
  - `enum RealtimeStatus { ok, unavailable, failed }`
  - `class CommuteResult { CommuteDirection direction; TransitRoute route; List<TransitRoute> alternatives; List<TrainArrival> arrivals; RealtimeStatus realtime; CatchVerdict verdict; DateTime eta; bool etaFromRealtime; DateTime queriedAt; }`
  - `commute_policy.dart`: `const kStationBufferMinutes = 1;` `const kStaleAfter = Duration(minutes: 2);`
    `CatchVerdict judgeCatch(List<TrainArrival> arrivals, int walkMinutes)` — 분이 null 인 열차는 건너뛰고 앞에서부터 최대 2대 기준.
    `TrainArrival? boardingTrain(List<TrainArrival> arrivals, CatchVerdict verdict)` — catchFirst → 첫 유효, catchSecond/missBoth → 둘째 유효, unknown → null.
    `DateTime estimateEta({required DateTime now, required TransitRoute route, TrainArrival? boarding})` — boarding 있으면 `now + boarding.minutes + route.minutesFromBoarding`, 없으면 `now + route.totalMinutes`.
    `TrainArrival withEstimatedMinutes(TrainArrival a, SubwayLeg leg)` — `a.minutes` 가 있거나 `stationsAway` 가 null 이거나 `leg.stationCount == 0` 이면 그대로, 아니면 `minutes = (stationsAway * leg.minutes / leg.stationCount).ceil()`, `estimated = true`.
    `bool isStale(DateTime queriedAt, DateTime now)`.

- [ ] **Step 1: 실패 테스트** — `commute_policy_test.dart`:
  - `judgeCatch([t(7), t(14)], 6)` → catchFirst (7 ≥ 6+1 경계), `([t(6), t(14)], 6)` → catchSecond, `([t(3), t(5)], 6)` → missBoth, `([t(null), t(9)], 6)` → catchFirst(분 없는 열차 건너뜀), `([], 6)` · `([t(null)], 6)` → unknown, 도보 0분 `([t(1)], 0)` → catchFirst, `([t(0)], 0)` → missBoth.
  - `estimateEta` : now 08:00, route(walk 6, subway 16, walk 3, subway 2, walk 7, total 41), boarding 7분 → 08:35(7+16+3+2+7); boarding null → 08:41.
  - `withEstimatedMinutes`: leg(minutes 16, stationCount 8), stationsAway 3 → minutes 6, estimated true; stationsAway 3, leg(minutes 10, stationCount 4) → 8 (7.5 올림); minutes 이미 4 → 그대로 estimated false.
  - `CommuteDirection.defaultAt` 11:59 → toWork, 12:00 → toHome. `isStale` 1:59 false, 2:00 true.
  `transit_route_test.dart`: 위 route 의 `walkToStationMinutes` 6, `minutesFromBoarding` 28, `signature == '7:장승배기>논현|109:신논현>강남'`; 지하철 없는 route → `firstSubway` null · `walkToStationMinutes` = 전체 도보. `Place.fromJson(Place(...).toJson())` 왕복, `fromJson('x')` · 필드 누락 → null.
- [ ] **Step 2: 실패 확인** — `flutter test test/domain/commute` → FAIL(컴파일 오류).
- [ ] **Step 3: 구현** — 엔티티 + `commute_policy.dart`, `build_runner build`.
- [ ] **Step 4: 통과 확인** — 같은 명령 PASS.
- [ ] **Step 5: 커밋** — `feat(walk): 통근 도메인 — 경로 · 열차 · 판단 · 도착 예상`

### Task 3: 데이터 — 서울 실시간 지하철 도착

**Files:**
- Create: `apps/walk/lib/domain/commute/repository/subway_arrival_source.dart`
- Create: `apps/walk/lib/domain/commute/commute_failure.dart`
- Create: `apps/walk/lib/data/commute/seoul_subway_arrival_source.dart`, `apps/walk/lib/data/commute/subway_line_codes.dart`
- Create: `apps/walk/test/fixtures/commute/seoul_arrival_jangseungbaegi.json`, `seoul_arrival_no_data.json`, `seoul_arrival_bad_key.json`
- Test: `apps/walk/test/data/commute/seoul_subway_arrival_source_test.dart`, `apps/walk/test/data/commute/subway_line_codes_test.dart`

**Interfaces:**
- Produces:
  - `sealed class CommuteFailure`(freezed): `.missingPlaces()` · `.missingKey()` · `.network()` · `.noRoute()` · `.server(String message)`
  - `abstract interface class SubwayArrivalSource { Future<List<TrainArrival>> arrivals({required String station, required int odsayLaneCode, required int wayCode}); }` — 노선 매핑 없음 → `[]`(오류 아님). 네트워크/시간 초과 → `throw CommuteFailure.network()`, 서울 오류 코드 → `throw CommuteFailure.server(message)`. 결과는 도착 순(가까운 열차 먼저) 최대 2대.
  - `int? seoulSubwayIdFor(int odsayLaneCode)` — `1..9 → 1001..1009`, `109 → 1077`(신분당), `116 → 1075`(수인분당), `104 → 1063`(경의중앙), `101 → 1065`(공항철도). 그 외 null. Task 9 에서 실제 응답으로 재확인.
  - `String normalizeStationName(String name)` — 끝의 `역` 제거, trim.
  - `SeoulSubwayArrivalSource(http.Client client, CommuteApiKeys keys, Clock clock, {Duration timeout = const Duration(seconds: 8)})`
- URL: `http://swopenapi.seoul.go.kr/api/subway/{key}/json/realtimeStationArrival/0/20/{Uri.encodeComponent(station)}`
- 응답 해석(스펙 §5, 픽스처는 서울 열린데이터광장 문서 예시 모양으로 만든다):
  - `errorMessage.code`: `INFO-000` 정상, `INFO-200` 데이터 없음 → `[]`, 그 외 → `server(errorMessage.message)`. 최상위에 `status`/`code`/`message` 만 오는 오류 모양도 `server`.
  - 거르기: `subwayId == seoulSubwayIdFor(lane)`, `updnLine` 이 `wayCode == 1 ? {'상행','내선'} : {'하행','외선'}` 안.
  - 정렬 · 정거장: `ordkey` 가 `^\d{2}(\d{3})` 이면 정거장 수 = 그 세 자리, 정렬 키 = 앞 5자리. 아니면 `arvlMsg2` 의 `[n]번째 전역` → n, `전역 도착|전역 출발|전역 진입` → 1, `당역 도착|당역 진입|당역 출발` → 0.
  - 분: `barvlDt > 0` 이면 `max(0, ((barvlDt - elapsed) / 60).ceil())`, `elapsed = clock.now() - recptnDt`(서울 현지 시각 `yyyy-MM-dd HH:mm:ss`, 파싱 실패 시 0). 아니면 `arvlMsg2` 의 `(\d+)분( \d+초)? 후` → 분(초가 있으면 올림). `arvlCd` 가 `0` · `1` 이면 0분. 그 외 null.
  - `destination` = `trainLineNm` 의 `' - '` 앞 부분(`장암행`), `message` = `arvlMsg2` 원문.

- [ ] **Step 1: 실패 테스트** — `MockClient`(`package:http/testing.dart`), `Clock` fake 로:
  - `parses two nearest trains in direction` — 픽스처(장승배기, 7호선 상행 3대 · 하행 2대)에서 `wayCode 1` → 2대, 순서 · `stationsAway` · `minutes` 기대값 고정.
  - `filters other lines and opposite direction` — 같은 응답에 1077 행을 섞어도 7호선만.
  - `clamps to zero when data is older than barvlDt` — barvlDt 120, recptnDt 가 now − 5분 → minutes 0.
  - `falls back to arvlMsg2 minutes` (barvlDt 0, "3분 20초 후 (보라매)" → 4) · `stations only` ("[5]번째 전역 (상도)" → minutes null, stationsAway 5) · `전역 도착` → 1.
  - `unmapped line returns empty without calling` (lane 999 → `[]`, 요청 0회).
  - `INFO-200 → empty`, `bad key → server(message)`, `SocketException`/timeout → `network`.
  - URL 에 역 이름이 인코딩되어 들어가고 키가 경로에 들어감.
  `subway_line_codes_test.dart`: 매핑 표, `normalizeStationName('장승배기역') == '장승배기'`.
- [ ] **Step 2: 실패 확인** — `flutter test test/data/commute` → FAIL.
- [ ] **Step 3: 구현** — 위 규칙 그대로. 파싱 실패 행은 버린다(던지지 않음).
- [ ] **Step 4: 통과 확인** — PASS.
- [ ] **Step 5: 커밋** — `feat(walk): 서울 실시간 지하철 도착을 읽는다`

### Task 4: 데이터 — ODsay 지하철 경로

**Files:**
- Create: `apps/walk/lib/domain/commute/repository/route_finder.dart`
- Create: `apps/walk/lib/data/commute/odsay_route_finder.dart`
- Create: `apps/walk/test/fixtures/commute/odsay_home_to_work.json`, `odsay_error_close.json`, `odsay_error_key.json`
- Test: `apps/walk/test/data/commute/odsay_route_finder_test.dart`

**Interfaces:**
- Produces:
  - `abstract interface class RouteFinder { Future<List<TransitRoute>> find({required Place from, required Place to}); }` — 경로 없음 → `throw CommuteFailure.noRoute()`, 네트워크 → `network`, 기타 오류 → `server(message)`. 결과 순서는 API 순서.
  - `OdsayRouteFinder(http.Client client, CommuteApiKeys keys, {Duration timeout = const Duration(seconds: 10)})`
- URL: `https://api.odsay.com/v1/api/searchPubTransPathT?SX={from.lng}&SY={from.lat}&EX={to.lng}&EY={to.lat}&SearchPathType=1&apiKey={Uri.encodeComponent(key)}`
- 해석: `result.path[]` → `TransitRoute(totalMinutes: info.totalTime, transferCount: 지하철 구간 수 − 1(최소 0), legs)`. `subPath[]` 의 `trafficType` 1 → `SubwayLeg(minutes: sectionTime, lineName: lane[0].name, odsayLaneCode: lane[0].subwayCode, startStation/endStation: normalizeStationName(startName/endName), wayCode, wayName: way, stationCount)`, 3 → `WalkLeg(sectionTime)`(0분 도보도 유지), 그 밖(버스 2)은 그 경로 전체를 버린다. `error` 가 객체 또는 배열 어느 모양이든 첫 항목의 `code`/`msg|message` 를 읽는다: 코드 `-98`(가까운 거리) · `-99`(검색 결과 없음) · `3`/`4`/`5`/`6`(출발 · 도착 정류장 없음 계열) → `noRoute`, 나머지 → `server`. path 0개 → `noRoute`.

- [ ] **Step 1: 실패 테스트** — `parses subway path legs`(픽스처: 장승배기→강남 경로 2개, 첫 경로 = 도보 6 · 7호선 16(8역, wayCode 1) · 도보 3 · 신분당선 2(1역) · 도보 7, total 41 — 각 필드 기대값), `drops paths with bus legs`, `error body maps to noRoute/server`(가까운 거리 픽스처 → noRoute, 키 오류 픽스처 → server 메시지), `empty path → noRoute`, 쿼리 파라미터 SX=lng · SY=lat 순서 확인, 타임아웃 → network.
- [ ] **Step 2: 실패 확인** — FAIL.
- [ ] **Step 3: 구현**.
- [ ] **Step 4: 통과 확인** — PASS.
- [ ] **Step 5: 커밋** — `feat(walk): ODsay 로 지하철 경로를 찾는다`

### Task 5: 데이터 · 도메인 — 장소 · 경로 선호 저장, 주소 검색, CommuteUseCase

**Files:**
- Create: `apps/walk/lib/domain/commute/repository/{place_repository.dart, route_preference_repository.dart, address_search.dart}`
- Create: `apps/walk/lib/data/commute/{prefs_place_repository.dart, prefs_route_preference_repository.dart, geocoding_address_search.dart}`
- Create: `apps/walk/lib/domain/commute/usecase/commute_use_case.dart`
- Modify: `apps/walk/lib/core/di/register_module.dart`(`http.Client` · `CommuteApiKeys.fromEnvironment()` 등록)
- Test: `apps/walk/test/data/commute/{prefs_place_repository_test.dart, prefs_route_preference_repository_test.dart, geocoding_address_search_test.dart}`, `apps/walk/test/domain/commute/usecase/commute_use_case_test.dart`

**Interfaces:**
- Consumes: Task 2 엔티티 · 정책, Task 3 `SubwayArrivalSource` · `CommuteFailure`, Task 4 `RouteFinder`, diary 의 `PlaceSource`(`current()` → `EntryLocation?{placeName, lat, lng}`) · `PlaceNamer`.
- Produces:
  - `PlaceRepository { Place? load(PlaceKind kind); Future<void> save(Place place); }` — 키 `commute.place.home` / `commute.place.work`(json 문자열). 깨진 값 → null.
  - `RoutePreferenceRepository { String? load(CommuteDirection d); Future<void> save(CommuteDirection d, String signature); }` — 키 `commute.route.toWork` / `commute.route.toHome`.
  - `class PlaceCandidate { double lat; double lng; String label; }`(freezed 단일) · `AddressSearch { Future<List<PlaceCandidate>> search(String query); }` — `GeocodingAddressSearch(PlaceNamer namer, {LocationsLookup? locations, Duration timeout = const Duration(seconds: 8)})`: `Geocoding().locationFromAddress(query, locale: …)` 최대 5개, 라벨은 `namer.nameFor` 의 이름, 없으면 `query`. 예외 · 시간 초과 · 0건 → `[]`. 빈 query → 호출 없이 `[]`.
  - `@lazySingleton class CommuteUseCase(PlaceRepository places, RoutePreferenceRepository prefs, RouteFinder routes, SubwayArrivalSource arrivals, CommuteApiKeys keys, Clock clock)`:
    - `Place? place(PlaceKind kind)` · `Future<void> savePlace(Place place)`
    - `Future<CommuteResult> query(CommuteDirection direction)` — 순서: 키 미완 → `throw missingKey`; 출발 · 도착 장소 하나라도 없으면 `missingPlaces`; `routes.find`; 저장된 서명과 같은 경로가 있으면 그것, 없으면 첫 경로 = `route`, 나머지 = `alternatives`; `_realtime(route)`; 판단 · 도착 예상.
    - `Future<CommuteResult> selectRoute(CommuteResult current, TransitRoute route)` — 서명 저장. 새 경로의 `firstSubway` 의 (역, 노선, wayCode)가 현재와 같으면 기존 `arrivals` 를 그대로 두고 판단 · 도착 예상만 새 경로로 다시 계산(호출 없음), 다르면 실시간 1회. `queriedAt` 은 실시간을 다시 부른 경우만 갱신.
    - `_realtime`: `firstSubway` null 또는 `seoulSubwayIdFor` null → `unavailable`, `[]`. `arrivals.arrivals(...)` 가 `[]` → `unavailable`. 던지면(CommuteFailure 포함) → `failed`, `[]`(경로 결과는 살린다). 받은 열차에 `withEstimatedMinutes` 적용.
    - 판단: `judgeCatch(arrivals, route.walkToStationMinutes)`, `eta = estimateEta(now, route, boardingTrain(...))`, `etaFromRealtime = boarding != null`.

- [ ] **Step 1: 실패 테스트** — 저장소: `SharedPreferences.setMockInitialValues` 로 왕복 · 깨진 json null · 방향별 서명 분리. 주소 검색: 주입한 `locations` · fake namer 로 라벨 채움 · 이름 없음 → query · 예외 → `[]` · 빈 query 호출 0회. 유스케이스(fake 4종 + 고정 Clock 08:00):
  - `missing key throws before any call`, `missing work place throws missingPlaces`
  - `prefers saved signature over first route`
  - `realtime unavailable keeps route and eta` — 매핑 없는 노선 → `realtime == unavailable`, `eta == 08:41`, `etaFromRealtime false`
  - `realtime failure keeps route` — arrivals 가 `network` 던짐 → `failed`, 결과 반환
  - `estimates minutes from stations` — 첫 지하철 구간 16분 · 8역, 도보 6분. 열차 2대 분 null · stationsAway 3 · 7 → minutes 6 · 14, 둘 다 estimated, 판단 catchSecond(6 < 7, 14 ≥ 7), eta = 08:00 + 14 + 28 = 08:42
  - `selectRoute same first station does not call arrivals`, `selectRoute different station calls once and saves signature`
- [ ] **Step 2: 실패 확인** — FAIL.
- [ ] **Step 3: 구현** — 저장소는 `@LazySingleton(as: …)`, `GeocodingAddressSearch` · `OdsayRouteFinder` · `SeoulSubwayArrivalSource` 도 `@LazySingleton(as: …)`. `RegisterModule` 에 `@lazySingleton http.Client get httpClient => http.Client();` · `@lazySingleton CommuteApiKeys get commuteApiKeys => CommuteApiKeys.fromEnvironment();`. `build_runner build`.
- [ ] **Step 4: 통과 확인** — `flutter test test/data/commute test/domain/commute` PASS, `flutter test test/core/app_test.dart`(DI 그래프) PASS.
- [ ] **Step 5: 커밋** — `feat(walk): 통근 장소 · 경로 선호 저장과 조회 유스케이스`

### Task 6: 화면 상태 — CommuteCubit

**Files:**
- Create: `apps/walk/lib/presentation/commute/cubit/{commute_cubit.dart, commute_state.dart}`
- Test: `apps/walk/test/presentation/commute/cubit/commute_cubit_test.dart`

**Interfaces:**
- Consumes: `CommuteUseCase`, `PlaceSource`(현재 위치), `AddressSearch`, `Clock`.
- Produces:
  - `class CommuteState { CommuteDirection direction; Place? home; Place? work; CommuteStatus status; bool locating; }`
  - `sealed class CommuteStatus`: `.idle()` · `.loading()` · `.loaded(CommuteResult result)` · `.failure(CommuteFailure failure)`
  - `CommuteCubit(CommuteUseCase useCase, PlaceSource placeSource, AddressSearch search, Clock clock)` — 생성 시 장소 읽고 `direction = CommuteDirection.defaultAt(now)`.
    `void setDirection(CommuteDirection d)`(결과를 idle 로 비움) · `Future<void> query()` · `Future<void> selectRoute(TransitRoute route)` · `Future<bool> useCurrentLocation(PlaceKind kind)`(`PlaceSource.current()` null → false, 라벨 = placeName ?? `'lat, lng'` 소수 5자리) · `Future<List<PlaceCandidate>> searchAddress(String q)` · `Future<void> choosePlace(PlaceKind kind, PlaceCandidate c)`.

- [ ] **Step 1: 실패 테스트**(bloc_test + mocktail):
  - 초기 방향 08:00 → toWork, 13:00 → toHome; 저장된 장소를 읽음
  - `query emits loading then loaded`, `CommuteFailure → failure`, 그 밖의 예외 → `failure(server(''))` 로 감쌈
  - `ignores query while loading` — 완료 전 두 번째 `query()` 는 유스케이스 호출 1회
  - `failure then retry` — 실패 뒤 `query()` 가 다시 호출됨
  - `setDirection clears result`, `useCurrentLocation null → false and no save`, `choosePlace saves and updates state`
- [ ] **Step 2: 실패 확인** — FAIL.
- [ ] **Step 3: 구현** — `build_runner build`.
- [ ] **Step 4: 통과 확인** — PASS.
- [ ] **Step 5: 커밋** — `feat(walk): 통근 탭 cubit`

### Task 7: 문자열 · 통근 탭 화면 · 셸 연결

**Files:**
- Modify: `packages/l10n/lib/l10n/app_{ko,en,ja}.arb` + gen-l10n 산출물
- Create: `apps/walk/lib/presentation/commute/page/commute_tab.dart`
- Create: `apps/walk/lib/presentation/commute/widget/{verdict_banner.dart, arrival_card.dart, route_summary.dart, place_row.dart}`
- Modify: `apps/walk/lib/presentation/shell/page/main_shell_page.dart`(enum · `IndexedStack` · `NavigationDestination`)
- Test: `apps/walk/test/presentation/commute/page/commute_tab_test.dart`, `apps/walk/test/presentation/commute/widget/{verdict_banner_test.dart, arrival_card_test.dart}`, `apps/walk/test/presentation/shell/…`(기존 셸 테스트의 탭 개수 · 순서 갱신)

**Interfaces:**
- Consumes: `CommuteCubit` / `CommuteState`, 정책의 `isStale`.
- Produces: `CommuteTab({required bool active})` — 셸이 cubit 을 만들지 않고 탭이 `BlocProvider(create: CommuteCubit(getIt…))` 로 소유. `ShellTab.commute`.
- 문구(ko 원문, en · ja 는 같은 뜻으로): 탭 `통근` · 방향 `출근` / `퇴근` · 버튼 `조회` · 배너 `걸어가면 탈 수 있어요` / `걸어서는 이번 열차를 놓쳐요 — 다음 열차 기준` / `걸어서는 두 열차 모두 어려워요` · 열차 `{minutes}분 후` / `약 {minutes}분 후` / `{n}번째 전역` / `곧 도착` · `역까지 도보 {minutes}분` · `도착 예상 {time}` + `(예상)` · `총 {minutes}분 · 환승 {count}회` · `다른 경로 {count}개` · `{time} 조회` · `다시 조회하세요` · `실시간 정보 없음` · `실시간을 불러오지 못했어요` · 상태 `집과 회사를 먼저 정해 주세요` / `API 키가 없어요 — config/commute_keys.json` / `네트워크에 연결할 수 없어요` / `이 구간의 지하철 경로가 없어요` / `서버 오류: {message}` · 장소 `집` / `회사` / `정하기`.
- 화면(스펙 §6.1): 방향 `SegmentedButton` · 장소 줄(누르면 Task 8 시트) · `AppButton.primary(조회, 로딩)` · 결과(배너 → 첫 승차역 카드(역 · 노선 · `wayName` 방면, 열차 최대 2줄, 도보 분) → 도착 예상 · 총 시간 · 환승 → 구간 줄 `도보 6 → 7호선 장승배기→논현 16 → …` → `다른 경로 n개`(alternatives 비면 숨김) → 조회 시각). 상태 오류는 `AppPlaceholder`. `active` 동안만 `Timer.periodic(30s)` 로 setState 해 낡음 표시를 갱신(네트워크 호출 아님).

- [ ] **Step 1: ARB 추가 · gen-l10n** — `grep '"walkCommute' app_ko.arb` 0건 확인 후 추가, `cd packages/l10n && flutter gen-l10n`, `cd apps/trader && flutter test test/convention` PASS.
- [ ] **Step 2: 실패 위젯 테스트** — `verdict_banner_test`: 4 판단별 문구(unknown 은 배너 없음). `arrival_card_test`: `estimated` → `약 6분 후`, minutes 0 → `곧 도착`, stationsAway 3 → `3번째 전역`, minutes null → 원문 메시지. `commute_tab_test`(mock cubit): 장소 없음 placeholder, loaded 결과의 핵심 문구(도착 예상 08:35 · 역까지 도보 6분), `queriedAt` 이 2분 전이면 `다시 조회하세요`, `realtime == unavailable` → `실시간 정보 없음` + `(예상)`, failure 별 문구. 셸 테스트: 5번째 탭 라벨 `통근` 이 `설정` 앞.
- [ ] **Step 3: 실패 확인** — FAIL.
- [ ] **Step 4: 구현**.
- [ ] **Step 5: 통과 확인** — `flutter test test/presentation` PASS, `flutter analyze` 0.
- [ ] **Step 6: 커밋** — `feat(walk): 통근 탭 화면을 셸에 붙인다`

### Task 8: 장소 설정 시트 · 경로 후보 시트

**Files:**
- Create: `apps/walk/lib/presentation/commute/widget/{place_setup_sheet.dart, route_options_sheet.dart}`
- Modify: `packages/l10n/lib/l10n/app_{ko,en,ja}.arb` + 산출물(`현재 위치로` · `주소 검색` · `검색 결과가 없어요` · `위치를 가져오지 못했어요` · `경로 선택`)
- Modify: `apps/walk/lib/presentation/commute/page/commute_tab.dart`(장소 줄 · `다른 경로` 탭 연결)
- Test: `apps/walk/test/presentation/commute/widget/{place_setup_sheet_test.dart, route_options_sheet_test.dart}`

**Interfaces:**
- Consumes: `CommuteCubit.useCurrentLocation` · `searchAddress` · `choosePlace` · `selectRoute`.
- Produces: `Future<void> showPlaceSetupSheet(BuildContext context, PlaceKind kind)` · `Future<void> showRouteOptionsSheet(BuildContext context, CommuteResult result)`.
- 장소 시트(스펙 §6.2): 제목(집/회사) · 현재 라벨 · `AppButton.secondary(현재 위치로)`(실패 시 `AppSnackBar`) · 검색 입력(제출 시 검색, 결과 `AppListTile` 목록 · 0건 문구) · 고르면 저장하고 닫힘.
- 경로 시트(스펙 §6.3): `route` + `alternatives` 를 `totalMinutes` 오름차순, 각 행 = 노선 이름들 · 환승 · 총 분, 현재 경로 표시. 고르면 `selectRoute` 후 닫힘.

- [ ] **Step 1: 실패 위젯 테스트** — 장소: 현재 위치 성공 → 시트 닫힘, 실패 → 스낵바; 검색 결과 2건 표시 · 탭 → `choosePlace` 호출; 0건 문구. 경로: 총 분 순 정렬, 현재 경로 체크 표시, 탭 → `selectRoute(route)`.
- [ ] **Step 2: 실패 확인** — FAIL.
- [ ] **Step 3: 구현**.
- [ ] **Step 4: 통과 확인** — PASS, `flutter analyze` 0, 전체 `flutter test` PASS.
- [ ] **Step 5: 커밋** — `feat(walk): 통근 장소 설정과 경로 고르기`

### Task 9: 키 발급 · 실제 응답 확인 · 문서 (사용자 참여)

키는 사용자가 발급한다(스펙 §8). 키가 아직 없으면 Step 1 에서 멈추고 **Step 6(문서)만** 진행해 상태를 "코드 완료 · 키 · 기기 확인 대기"로 남긴다.

**Files:**
- Modify: `apps/walk/test/fixtures/commute/*.json`(실제 응답으로 교체, 키 · 개인 좌표는 지운다)
- Modify(필요 시): `subway_line_codes.dart` · 파서 · 관련 테스트
- Modify: `apps/walk/docs/{status.md, history.md, testing.md, README.md}`, `CLAUDE.md`(walk 앱 설명에 통근 탭), `docs/superpowers/specs/2026-10-21-commute-eta-design.md`(상태 줄)

- [ ] **Step 1: 키 발급 안내** — 사용자에게: 서울 열린데이터광장(data.seoul.go.kr) → 인증키 신청 → **실시간 지하철 인증키**; ODsay LAB(lab.odsay.com) → 애플리케이션 등록 → 플랫폼 Android, 패키지 `com.karma.walk`. `apps/walk/config/commute_keys.json` 에 넣는다.
- [ ] **Step 2: 실제 호출 녹화** — 맥에서 `curl` 로 장승배기 실시간 1회, ODsay 장승배기 근처 → 강남역 근처 1회. 확인할 것(스펙 §10): `barvlDt` 가 7호선 · 신분당선에서 채워지는지, `ordkey` 형식, `updnLine` ↔ ODsay `wayCode`(장승배기→논현 = 장암 방면) 대응, ODsay `subwayCode`(신분당선 109 여부), `way` 값, 서울 API https 지원 여부.
- [ ] **Step 3: ODsay 키가 앱(Android 키)에서 동작하는지** — `flutter run --dart-define-from-file=config/commute_keys.json` 로 에뮬레이터에서 조회. 막히면 순서대로: ODsay 서버 · 웹 키 시도 → 안 되면 카카오 `publictraffic` 로 `RouteFinder` 구현을 교체하는 새 태스크를 이 계획에 추가하고 사용자에게 알린다.
- [ ] **Step 4: 다른 결과를 반영** — 픽스처 교체, 어긋난 매핑 · 파서 규칙과 테스트 수정, `flutter test` PASS.
- [ ] **Step 5: 에뮬레이터 시나리오** — 장소 미설정 안내 → 현재 위치/주소로 집 · 회사 설정 → 출근 조회 → 다른 경로 고르기 → 탭 재진입 후 같은 경로 기본 → 퇴근 조회 → 비행기 모드 조회 오류 → 2분 뒤 낡음 표시.
- [ ] **Step 6: 문서** — `status.md` 에 "통근" 단계 행 · 체크리스트(실제 폰 출근길 비교는 사용자 몫으로 미완), `history.md` 에 판단 · 고친 것, `testing.md` 에 테스트 범위, `README.md` 에 통근 탭 설명과 `--dart-define-from-file=config/commute_keys.json` 실행 · 빌드 명령, `CLAUDE.md` walk 설명에 통근 한 줄, 스펙 상태 줄 갱신. `cd apps/trader && flutter test test/convention`(문서 링크) PASS.
- [ ] **Step 7: 커밋** — `docs(walk): 통근 구현 기록 · 테스트 · 현황을 남긴다`(코드 수정이 있었으면 그 전에 `fix(walk): …` 따로)
