# 대중교통 길찾기 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** walk(Life Log) 도구 탭에 ODsay 기반 대중교통 길찾기 상단 탭을 더한다.

**Architecture:** `lib/{domain,data,presentation}/transit/` 새 기능 폴더. 도메인은 순수 Dart(엔티티 · 정렬 · 실패 · 인터페이스),
데이터는 ODsay HTTP · 보안 저장소 키 · shared_preferences 캐시/최근, 화면은 cubit 둘(길찾기 · 장소 고르기)과 페이지 셋(길찾기 · 장소 고르기 · 상세) + 키 설정 페이지.
기존 `commute` 코드는 집 · 회사 저장(`PlaceRepository`)과 주소 검색(`AddressSearch`)만 재사용한다.

**Tech Stack:** Flutter · flutter_bloc · freezed 3 · injectable/get_it · http · flutter_secure_storage · shared_preferences · `core` 패키지 `Clock`.

**Spec:** [2026-11-17-walk-transit-route-design.md](../specs/2026-11-17-walk-transit-route-design.md)

## Global Constraints

- 작업 디렉터리 `apps/walk`. 명령: `flutter test <path>` · `flutter analyze` · `dart run build_runner build --delete-conflicting-outputs`(freezed · injectable 바꾸면)
- 생성 파일(`.freezed.dart` · `.g.dart` · `injection.config.dart`)은 손대지 않고 build_runner 로 만든다
- Freezed: 단일 모델은 primary constructor(`@freezed class X with _$X { final ...; const X({...}); }`), 변형은 `sealed class` + named factory. 분기는 `switch` 패턴
- UI: `AppPlaceholder` · `AppLoading` · `AppListTile` · `AppButton.*` · `AppConfirmDialog.show` · `AppOverflowMenu` · 스낵바는 `AppSnackBar.success/error/info/warning`. 색 · 여백 · 모서리는 `AppColors` · `AppSpacing` · `AppRadius` · `Theme.of(context)` — `Colors.*` · 숫자 여백 · `BorderRadius.circular(n)` 금지
- 문구는 l10n(`packages/l10n` 의 arb, 한국어 · 영어 둘 다)에 넣는다. 키 접두사 `walkTransit`
- 테스트 위치는 구현 구조 그대로: `lib/x/transit/...` ↔ `test/x/transit/...`
- ODsay: base `https://api.odsay.com/v1/api/`, 경로 `searchPubTransPathT?SX&SY&EX&EY&SearchPathType=0&apiKey=`, 역 `searchStation?stationName=&stationClass=1,2&apiKey=`. 타임아웃 10초
- 캐시: 경로 키 = 좌표 소수 넷째 자리 반올림 쌍, **10분**. 역 검색 키 = trim + 소문자 + 공백 제거, **7일**, 최대 **100**개. 최근 장소 **10**개(`transit.recent`)
- 역 검색: **2글자 이상**, **500ms** 디바운스, IME 조합 중이면 보내지 않음, 지하철 먼저 · 정류장 다음 · 최대 **20**개
- 정렬: 총 소요 시간 ↑ → 환승 ↑ → 도보 ↑
- 키: 보안 저장소 이름 `transit.odsayKey`, 상태 prefs `transit.keyStatus`(connected · unverified · rejected). 출처 순서 저장소 → `String.fromEnvironment('ODSAY_API_KEY')` → 없음. 백업 허용 목록에 넣지 않는다
- 자주 간 곳: 최근 **30일** 머문 곳 → `frequentPlaces(limit: 5)`, 이름은 `StayNamer`/`PlaceNamer`
- 상단 탭: `ToolsSection { alarm, walk, weather, transit }`, 고정 탭 + `Tab(icon:, text:)`, 아이콘 크기 20, 라벨 넘치면 `FittedBox(fit: BoxFit.scaleDown)`
- main 머지 · 푸시 금지. 셸(`main_shell_page.dart`)과 설정 탭 구조는 다른 세션이 바꾸는 중 — 도구 탭 상단 탭과 앱 설정 한 줄 외에는 건드리지 않는다

## Review Focus

1. **키 거부를 경로 없음으로 보이는 것** — ODsay 가 키 오류를 HTTP 200 + `error` 로 줄 때도 `keyRejected` 여야 한다 → Task 2 테스트 `key error with 200 is keyRejected`
2. **역 검색이 한도를 갉아먹는 것** — 빠른 타이핑 · 같은 검색어 반복 · 한글 조합 중 입력 → Task 6 테스트(디바운스 · 캐시 · composing)
3. **늦게 온 응답이 새 결과를 덮는 것** — 출발/도착을 바꾼 뒤 앞 요청이 늦게 끝남 → Task 6 `stale response ignored`
4. **위치 권한 없음 · 위치 기록 꺼짐** — 현재 위치 실패는 출발 칸 안 안내, 자주 간 곳 섹션은 숨김(오류 아님) → Task 5 · Task 6 테스트
5. **좁은 폭 · 큰 글씨에서 상단 탭 잘림** — 360dp · textScale 1.3 → Task 9 위젯 테스트(overflow 없음)

---

### Task 1: 도메인 — 엔티티 · 실패 · 정렬

**Files:**
- Create: `lib/domain/transit/entity/transit_point.dart`, `transit_path.dart`, `station_hit.dart`, `lib/domain/transit/transit_failure.dart`, `lib/domain/transit/transit_sort.dart`
- Create: `lib/domain/transit/repository/transit_route_source.dart`, `station_search.dart`, `transit_key_store.dart`, `transit_cache.dart`, `recent_points.dart`
- Test: `test/domain/transit/entity/transit_path_test.dart`, `test/domain/transit/transit_sort_test.dart`, `test/domain/transit/entity/transit_point_test.dart`

**Interfaces — Produces:**
- `enum TransitPointSource { currentLocation, home, work, frequent, recent, station, address }`
- `TransitPoint({double lat, double lng, String label, TransitPointSource source})` + `toJson()` / `static TransitPoint? fromJson(Object?)` + `String get cacheKey` (`lat.toStringAsFixed(4),lng.toStringAsFixed(4)`)
- `sealed TransitLeg`: `walk({int minutes, int distanceM})`=`TransitWalkLeg` · `subway({int minutes, String lineName, int? subwayCode, String start, String end, int stationCount, String way})`=`TransitSubwayLeg` · `bus({int minutes, List<String> busNumbers, String start, String end, int stationCount})`=`TransitBusLeg`
- `TransitPath({int totalMinutes, int transferCount, int? fare, List<TransitLeg> legs})` + `int get walkMinutes` (도보 구간 합)
- `enum StationKind { subway, bus }`; `StationHit({String name, StationKind kind, double lat, double lng, String detail})` + `toJson/fromJson`
- `sealed TransitFailure`: `missingKey()` · `keyRejected(String message)` · `quotaExceeded()` · `network()` · `noRoute()` · `tooClose()` · `server(String message)` (`implements Exception`)
- `List<TransitPath> sortTransitPaths(Iterable<TransitPath>)`
- `abstract interface class TransitRouteSource { Future<List<TransitPath>> find({required TransitPoint from, required TransitPoint to, required String apiKey}); }`
- `abstract interface class StationSearch { Future<List<StationHit>> search(String query, {required String apiKey}); }`
- `enum TransitKeyStatus { connected, unverified, rejected }`; `abstract interface class TransitKeyStore { Future<String?> read(); Future<void> save(String key, TransitKeyStatus status); Future<void> delete(); Future<TransitKeyStatus?> status(); Future<void> setStatus(TransitKeyStatus s); }`
- `abstract interface class TransitCache { ({List<TransitPath> paths, DateTime fetchedAt})? routes(String key); void putRoutes(String key, List<TransitPath> paths); Future<List<StationHit>?> stations(String query); Future<void> putStations(String query, List<StationHit> hits); }`
- `abstract interface class RecentPoints { Future<List<TransitPoint>> load(); Future<void> add(TransitPoint p); }`

- [ ] **Step 1: 실패하는 테스트** — `walkMinutes sums walk legs only`(walk 5 + subway 12 + walk 3 → 8) · `sortTransitPaths orders by total then transfers then walk`(42/1/9, 42/0/14, 47/0/3, 42/0/9 → [42/0/9, 42/0/14, 42/1/9, 47/0/3]) · `TransitPoint fromJson rejects broken` · `cacheKey rounds to 4 decimals`(37.123456 → `37.1235`) · `StationHit json roundtrip`
- [ ] **Step 2: 실행해 실패 확인** — `flutter test test/domain/transit` → 컴파일 실패
- [ ] **Step 3: 구현 + build_runner**
- [ ] **Step 4: 통과 확인** — `flutter test test/domain/transit` PASS
- [ ] **Step 5: 커밋** `feat(walk): 길찾기 도메인 — 경로 · 장소 · 실패 · 정렬`

### Task 2: ODsay 클라이언트 — 경로 · 역 검색 · 오류 분류

**Files:**
- Create: `lib/data/transit/odsay_transit_client.dart` (`@LazySingleton(as: TransitRouteSource)` + `StationSearch` 둘 다 구현하는 클래스 하나, `as:` 는 하나만 되므로 `TransitRouteSource` 로 등록하고 `StationSearch` 는 register_module 이나 별도 `@LazySingleton(as: StationSearch)` 얇은 위임 클래스로 — 구현자가 고른다)
- Create fixtures: `test/fixtures/transit/odsay_path_mixed.json`(지하철+버스+도보, 버스 구간 lane 2개), `odsay_path_bus_only.json`, `odsay_error_key.json`(기존 `fixtures/commute/odsay_error_key.json` 형식), `odsay_error_close.json`(code `-98`), `odsay_error_no_route.json`(`-99`), `odsay_error_quota.json`(msg 에 `LimitExceeded`), `odsay_station.json`(stationClass 1 · 2 섞어서)
- Test: `test/data/transit/odsay_transit_client_test.dart`

**Interfaces:** Consumes Task 1. 생성자 `OdsayTransitClient(http.Client client, {@ignoreParam Duration timeout = const Duration(seconds: 10)})` — 키는 호출 인자로 받는다.

ODsay 매핑: `subPath.trafficType` 1 → subway(`lane[0].name`, `lane[0].subwayCode`, `way`), 2 → bus(`lane[*].busNo`), 3 → walk(`sectionTime`, `distance`). `info.totalTime` · `info.payment`(없으면 null). 환승 = 비도보 구간 수 − 1(최소 0). 오류: `error`(Map 또는 List 첫 원소)의 `code`/`msg`: `-98` → tooClose, `-99`·`3`·`4`·`5`·`6` → noRoute, msg 에 `ApiKeyAuthFailed` 또는 code `500` 이고 msg 에 `ApiKey` → keyRejected(msg), msg 에 `LimitExceeded` 또는 `초과` → quotaExceeded, 나머지 → server(msg). 예외 처리 · 비 2xx · 전부 해석 실패 → `server('parse')` 는 `OdsayRouteFinder` 와 같은 규칙. 역 검색: `result.station[]` → `StationHit(name: stationName, kind: stationClass==2 ? subway : bus, lat: y, lng: x, detail: subway면 laneName, bus면 arsID + ' · ' + gu)`, 지하철 먼저 · 최대 20.

- [ ] **Step 1: 실패하는 테스트** — `parses mixed path into walk/subway/bus legs`(버스 번호 두 개) · `transferCount counts non-walk legs minus one` · `fare null when payment missing` · `key error with 200 is keyRejected` · `-98 is tooClose` · `-99 is noRoute` · `quota message is quotaExceeded` · `socket/timeout/TLS → network` · `non-2xx without error body → server('HTTP 503')` · `all paths unparsable → server('parse')` · `station search maps class 2 to subway first and caps 20` · `apiKey is url-encoded in query`(가짜 `MockClient` 로 요청 URI 확인)
- [ ] **Step 2: 실패 확인** — `flutter test test/data/transit/odsay_transit_client_test.dart`
- [ ] **Step 3: 구현** (`OdsayRouteFinder` 의 예외 · 응답 처리 골격을 옮긴다)
- [ ] **Step 4: 통과 확인**
- [ ] **Step 5: 커밋** `feat(walk): ODsay 대중교통 경로 · 역 검색 클라이언트`

### Task 3: 키 저장소 · 캐시 · 최근 — 데이터

**Files:**
- Create: `lib/data/transit/secure_transit_key_store.dart`(`@LazySingleton(as: TransitKeyStore)`, `FlutterSecureStorage` + `SharedPreferences`), `lib/data/transit/prefs_transit_cache.dart`(`@LazySingleton(as: TransitCache)`, 경로는 메모리, 역은 prefs `transit.stationCache` JSON), `lib/data/transit/prefs_recent_points.dart`(`@LazySingleton(as: RecentPoints)`)
- Create: `lib/domain/transit/usecase/transit_api_key.dart` — `class TransitApiKey { TransitApiKey(TransitKeyStore store, {@ignoreParam String? fallback}); Future<String?> current(); }` (fallback 기본값 `CommuteApiKeys.fromEnvironment().odsay`, 빈 문자열은 없음 취급)
- Modify: `lib/domain/backup/restore_notice.dart`(값 `transitKeyNeeded` 추가), 복원 후 안내를 모으는 곳(`chat_backup_area.dart` 의 `RestoreNotice.apiKeyNeeded` 패턴 — 구현자가 알맞은 area 또는 `settings_backup_area.dart` 에서 키가 없으면 더한다), 안내 문구 l10n
- Test: `test/data/transit/secure_transit_key_store_test.dart`, `prefs_transit_cache_test.dart`, `prefs_recent_points_test.dart`, `test/domain/transit/usecase/transit_api_key_test.dart`, 기존 `test/data/backup/area/settings_backup_area_test.dart` 에 한 건

**Interfaces:** Consumes Task 1 저장 인터페이스. `PrefsTransitCache(SharedPreferences prefs, Clock clock)`.

- [ ] **Step 1: 실패하는 테스트** — 키: `save/read/delete` · `status persisted in prefs` · 출처 순서 `store beats fallback` · `fallback used when store empty` · `blank fallback is null`. 캐시: `routes expire after 10 minutes`(가짜 Clock) · `stations expire after 7 days` · `station cache keeps newest 100` · `query normalized (trim, lowercase, no spaces)`. 최근: `keeps 10 newest, dedupes by cacheKey`. 백업: `transit keys are not in backup allow-list` · 복원 뒤 키 없으면 `transitKeyNeeded`
- [ ] **Step 2: 실패 확인**
- [ ] **Step 3: 구현 + build_runner**
- [ ] **Step 4: 통과 확인** — `flutter test test/data/transit test/domain/transit test/data/backup`
- [ ] **Step 5: 커밋** `feat(walk): 길찾기 키 보안 저장 · 캐시 · 최근 장소`

### Task 4: 유스케이스 — 경로 찾기 · 역 검색 · 키 확인

**Files:**
- Create: `lib/domain/transit/usecase/find_transit_routes.dart`, `search_stations.dart`, `verify_transit_key.dart`
- Test: `test/domain/transit/usecase/{find_transit_routes,search_stations,verify_transit_key}_test.dart`

**Interfaces — Produces:**
- `FindTransitRoutes(TransitRouteSource, TransitCache, TransitApiKey, TransitKeyStore, Clock)`; `Future<TransitRoutesResult> call(TransitPoint from, TransitPoint to, {bool refresh = false})`; `TransitRoutesResult({List<TransitPath> paths, DateTime fetchedAt, bool fromCache})`. 키 없으면 `TransitFailure.missingKey` 던짐. 성공하면 키 상태 `connected`, `keyRejected` 면 `rejected` 로 기록. 결과는 `sortTransitPaths`
- `SearchStations(StationSearch, TransitCache, TransitApiKey)`; `Future<List<StationHit>> call(String query)` — 정규화 2글자 미만이면 호출 없이 `[]`, 캐시 우선
- `VerifyTransitKey(StationSearch, TransitKeyStore)`; `Future<TransitKeyStatus> call(String key, {bool saveIfUnverified = false})` — `search('서울역', apiKey: key)` 1회. 성공 → 저장 · connected. keyRejected → 저장 안 함 · 예외 그대로. network → `saveIfUnverified` 면 unverified 로 저장, 아니면 예외

- [ ] **Step 1: 실패하는 테스트** — `same pair within 10 minutes uses cache (source called once)` · `refresh skips cache` · `missing key throws missingKey without calling source` · `keyRejected marks status rejected` · `success marks connected` · `results sorted` · 역: `1 char → no call` · `cached query → no call` · 키 확인: `rejected key is not saved` · `network with saveIfUnverified saves unverified`
- [ ] **Step 2–4: 실패 확인 → 구현 → 통과**
- [ ] **Step 5: 커밋** `feat(walk): 길찾기 유스케이스 — 캐시 경로 · 역 검색 · 키 확인`

### Task 5: 출발 · 도착 후보 — 현재 위치 · 집/회사 · 자주 간 곳 · 최근

**Files:**
- Create: `lib/domain/transit/usecase/transit_point_suggestions.dart`
- Test: `test/domain/transit/usecase/transit_point_suggestions_test.dart`

**Interfaces — Produces:** `TransitPointSuggestions(PlaceRepository places, RecentPoints recent, LocationRepository locations, StayNamer namer, LocationRecorder recorder, Clock clock)` (위치 의존은 `location_tools.dart` 의 `_stays` 계산을 그대로 따른다 — `pointsAround` → `TrackAnalyzer().analyze` → `frequentPlaces(limit: 5)`, 이름은 `StayNamer`); `Future<TransitSuggestions> load()`; `TransitSuggestions({TransitPoint? home, TransitPoint? work, List<TransitPoint> frequent, List<TransitPoint> recent})`. `Future<void> saveAs(PlaceKind kind, TransitPoint p)` → 기존 `PlaceRepository` 저장. 현재 위치는 cubit 이 `PlaceSource.current()` 로 따로 얻는다.

- [ ] **Step 1: 실패하는 테스트** — `home/work from commute PlaceRepository` · `frequent top 5 from last 30 days with names` · `recorder off or no points → empty frequent (no throw)` · `location repo throws → empty frequent` · `saveAs home persists via PlaceRepository`
- [ ] **Step 2–4**
- [ ] **Step 5: 커밋** `feat(walk): 길찾기 출발 · 도착 후보`

### Task 6: cubit 둘 — 길찾기 · 장소 고르기

**Files:**
- Create: `lib/presentation/transit/cubit/transit_cubit.dart`, `transit_state.dart`, `point_picker_cubit.dart`, `point_picker_state.dart`
- Test: `test/presentation/transit/cubit/{transit_cubit,point_picker_cubit}_test.dart`

**Interfaces — Produces:**
- `TransitState({TransitPoint? from, TransitPoint? to, bool locating, bool locationFailed, TransitStatus status})`; `sealed TransitStatus`: `idle` · `loading` · `loaded(TransitRoutesResult)` · `failure(TransitFailure)`
- `TransitCubit(FindTransitRoutes, PlaceSource, RecentPoints)`: `start()`(출발 = 현재 위치 시도) · `setFrom(TransitPoint)` · `setTo(TransitPoint)` · `fillEmpty(TransitPoint)`(빈 칸, 둘 다 차 있으면 도착) · `swap()` · `refresh()`. 둘 다 차면 자동 조회. 고른 점은 `RecentPoints.add`(현재 위치 제외). 요청마다 세대 번호 — 늦게 온 앞 요청 결과는 버린다. 알 수 없는 예외 → `server(runtimeType)`
- `PointPickerState({String query, bool searching, List<StationHit> stations, List<PlaceCandidate> addresses, bool addressSearching, TransitSuggestions? suggestions})`
- `PointPickerCubit(SearchStations, AddressSearch, TransitPointSuggestions, {@ignoreParam Duration debounce = const Duration(milliseconds: 500)})`: `load()` · `queryChanged(String text, {bool composing = false})` · `searchAddress()`(사용자가 누를 때만) · `close()` 시 타이머 취소

- [ ] **Step 1: 실패하는 테스트** — transit: `both filled triggers find` · `fillEmpty fills from then to then replaces to` · `swap re-queries` · `stale response ignored`(첫 요청 Completer 를 나중에 완료) · `location failure sets locationFailed, from stays null` · `failure state carries TransitFailure` · `recent added except currentLocation`. picker(`fake_async`): `typing within 500ms calls search once` · `composing does not call` · `1 char does not call` · `address search only on demand` · `close cancels pending debounce`
- [ ] **Step 2–4**
- [ ] **Step 5: 커밋** `feat(walk): 길찾기 · 장소 고르기 cubit`

### Task 7: 길찾기 키 설정 화면

**Files:**
- Create: `lib/presentation/settings/page/transit_settings_page.dart`, `lib/presentation/transit/cubit/transit_key_cubit.dart`(+ state)
- Modify: `lib/presentation/settings/page/app_settings_page.dart`(한 줄: 길찾기 → 이 페이지), l10n arb
- Test: `test/presentation/settings/page/transit_settings_page_test.dart`, `test/presentation/transit/cubit/transit_key_cubit_test.dart`

`chat_settings_page.dart` 의 키 입력 · 마스킹(`domain/chat/api_key_mask.dart` 재사용) · 상태 표시 패턴을 따른다. 저장 → `VerifyTransitKey`; connected → `AppSnackBar.success`; keyRejected → 저장 안 함 + 원문 오류를 화면에; network → `AppConfirmDialog.show(isDestructive: false)` "확인 못 했어요. 그래도 저장할까요?" → yes 면 `saveIfUnverified`. 삭제 → `AppConfirmDialog.show`. 발급 안내(lab.odsay.com · Android · `com.karma.walk`).

- [ ] **Step 1: 실패하는 테스트** — `saved key is masked` · `rejected shows server message and does not save` · `network asks then saves unverified` · `delete asks and clears` · `app settings has transit row`
- [ ] **Step 2–4**
- [ ] **Step 5: 커밋** `feat(walk): 길찾기 ODsay 키 설정`

### Task 8: 길찾기 화면 · 장소 고르기 · 상세

**Files:**
- Create: `lib/presentation/transit/page/transit_page.dart`, `point_picker_page.dart`, `transit_path_detail_page.dart`; `lib/presentation/transit/widget/{point_fields,quick_point_chips,transit_path_tile,line_chip,transit_failure_view,leg_timeline}.dart`
- Modify: l10n arb
- Test: `test/presentation/transit/page/{transit_page,point_picker_page,transit_path_detail_page}_test.dart`, `test/presentation/transit/widget/transit_path_tile_test.dart`

스펙 §6.2–6.4 그림대로. 결과 행: 총 분 · "환승 n · 도보 n분 · 1,500원"(요금 없으면 생략) · 노선 칩(지하철 이름 · 버스 번호). 목록 위 "n분 전 결과 · 새로고침", 그 아래 "환승 · 배차 대기 시간은 빠질 수 있어요". 실패별 `AppPlaceholder`(missingKey · keyRejected 는 [키 설정] 버튼 → `TransitSettingsPage`). `⋮` 는 `AppOverflowMenu`: 길찾기 키 설정 · 앱 설정. 장소 고르기: 검색 필드, 현재 위치 · 집/회사(길게 눌러 지금 고른 곳으로 저장) · 자주 간 곳(없으면 숨김) · 최근 · 역 결과 · "주소로 찾기" 행.

- [ ] **Step 1: 실패하는 테스트** — `missing key shows placeholder with settings button` · `keyRejected shows message` · `quota/tooClose/noRoute/network copy` · `loaded lists paths in order with transfer/walk/fare` · `tap path opens detail with legs` · `quick chip fills empty field` · `picker hides frequent when empty` · `picker station tap returns point` · `fare omitted when null`
- [ ] **Step 2–4**
- [ ] **Step 5: 커밋** `feat(walk): 길찾기 화면 · 장소 고르기 · 경로 상세`

### Task 9: 도구 탭 넷째 상단 탭

**Files:**
- Modify: `lib/presentation/shell/page/tools_tab.dart`(enum `transit` 추가, `Tab(icon:, text:)` 넷, 길찾기 섹션 앱바 ⋮), 셸이 enum 을 저장 · 복원하면 그 부분만, l10n(`walkToolsTabTransit`)
- Test: `test/presentation/shell/page/tools_tab_test.dart`(없으면 만들기), 기존 `main_shell_page_test.dart` 탭 개수 기대값

- [ ] **Step 1: 실패하는 테스트** — `four tabs with icons` · `transit tab shows TransitPage` · `no overflow at 360x640 textScale 1.3`(`tester.view.physicalSize` · `MediaQuery(textScaler: TextScaler.linear(1.3))`, `tester.takeException()` 이 null)
- [ ] **Step 2–4**
- [ ] **Step 5: 커밋** `feat(walk): 도구 탭에 길찾기 상단 탭`

### Task 10: 문서 · 검증 · 에뮬레이터

**Files:** `apps/walk/docs/{status,history,testing,README,plan}.md`, 스펙 상태 줄

- [ ] `flutter analyze` 0 · `flutter test` 전부 통과 · `flutter test test/convention`
- [ ] 에뮬레이터(키 없이): 도구 › 길찾기 → 키 없음 안내 → 키 설정 화면, 장소 고르기, 360dp 기본/가장 큰 글씨 상단 탭 스크린샷 → 공유 노트 폴더
- [ ] status: 길찾기 섹션(완료 항목 · 남은 것: 실키 확인 · 픽스처 교체 · 통근 코드 정리 후보 · 새 설정 탭 진입점). history: 결정 · 리뷰 수정. testing: 표 + 기기 시나리오(키 입력 → 확인 결과 → 역 검색 → 조회 → 상세 → 새로고침 → 비행기 모드 → 키 삭제; Android 키 거부 시 화면 원문을 알려 주고 서버 · 웹 키로 재시도). README: 통근 키 절차 → 길찾기 키(앱에서 입력, define 은 개발용)
- [ ] 커밋 `docs(walk): 길찾기를 기록한다`
