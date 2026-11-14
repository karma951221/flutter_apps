# 도구 › 날씨 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** walk 앱 도구 탭에 넷째 상단 탭 **날씨**를 넣어, 지금 위치의 "오늘 비 오나 · 언제"와 시간별 · 일별 예보를 한눈에 보인다.

**Architecture:** 앱 전용 `lib/{domain,data,presentation}/weather/`. 출처(Open-Meteo)는 `WeatherRepository` 뒤에 숨기고, 위치는 날씨 전용 `WeatherLocator`, 마지막 성공 한 벌은 `WeatherCache`(shared_preferences). `WeatherCubit` 이 캐시 먼저 · 위치 · 요청 · 10분 규칙을 맡고, 셸이 지도 cubit 처럼 만들어 복귀 때 부른다.

**Tech Stack:** Flutter, flutter_bloc, freezed 3, injectable/get_it, http(`MockClient`), shared_preferences, mocktail, `packages/location`(`LocationAccess` · `LocationGateway`), l10n arb(ko · en · ja).

**Spec:** [2026-11-14-walk-weather-design.md](../specs/2026-11-14-walk-weather-design.md)

## Global Constraints

- 모든 명령은 `apps/walk` 에서. 테스트는 `lib/<layer>/weather/` ↔ `test/<layer>/weather/` 미러.
- 요청 URL: `https://api.open-meteo.com/v1/forecast`, 파라미터는 스펙 [출처](../specs/2026-11-14-walk-weather-design.md#출처-open-meteo) 그대로(`timezone=auto`, `forecast_days=7`, `wind_speed_unit=ms`, current · hourly · daily 필드 목록).
- `network_security_config.xml` · `packages/location` · 일기의 `PlaceSource` 는 고치지 않는다.
- 다른 세션이 작업 중: `track_map.dart` · `map_style.dart` · `map_tab_test.dart` · 지도 모양 l10n 키는 건드리지 않는다. arb 는 새 키만 **추가**한다.
- Freezed 는 CLAUDE.md 두 패턴만(단일 = primary constructor, 변형 = sealed union). 분기는 `switch`.
- UI 는 `design_system` 토큰 · 공통 위젯(`AppPlaceholder` · `AppButton` · `AppSnackBar`). `Colors.*` · 숫자 여백 · `BorderRadius.circular(n)` 금지.
- 시각: 엔티티의 시각은 모두 **UTC 절대 시각**. 지역 벽시계는 `Forecast.utcOffset` 으로 계산. "지금"은 `Clock.now()`.
- 생성 파일은 `dart run build_runner build --delete-conflicting-outputs` 로만. l10n 은 `cd ../../packages/l10n && flutter gen-l10n`(템플릿은 `app_ko.arb`).
- 커밋 메시지 `feat(walk): …` / `test(walk): …`, 끝에 `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. 작업 트리에 남의 미커밋 변경이 있으니 **자기 파일만** `git add`.

## Review Focus

1. **자정 근처 · 시간대가 다른 예보** — 23시에 열거나 기기 시간대와 예보 시간대가 다를 때 "오늘/내일 · 오후 3시"가 예보 장소 기준으로 맞아야 한다 → Task 1 테스트.
2. **응답에 `precipitation_probability` 가 null 인 시간** — 확률 없음은 0 으로 보지 말고 강수량만으로 판정, 화면엔 "–" → Task 1 · 2 테스트.
3. **새로고침 중복** — 당겨서 새로고침과 탭 전환이 겹쳐도 요청은 한 번 → Task 5 테스트.
4. **이름이 예보보다 늦게 오거나 실패** — 예보는 먼저 보이고 이름은 나중에, 실패면 "현재 위치" → Task 5 테스트.
5. **캐시 JSON 이 깨졌거나 옛 형식** — 앱이 죽지 않고 캐시 없음으로 → Task 4 테스트.

---

### Task 1: 도메인 — 예보 엔티티 · 날씨 상태 · 비 요약

**Files:**
- Create: `lib/domain/weather/entity/forecast.dart` (Freezed: `Forecast`, `CurrentWeather`, `HourlyWeather`, `DailyWeather`)
- Create: `lib/domain/weather/entity/weather_condition.dart`
- Create: `lib/domain/weather/rain_summary.dart`
- Test: `test/domain/weather/entity/weather_condition_test.dart`, `test/domain/weather/rain_summary_test.dart`

**Interfaces — Produces:**
- `enum WeatherCondition { clear, partlyCloudy, cloudy, fog, drizzle, rain, showers, snow, thunderstorm, unknown }` + `static WeatherCondition fromWmo(int code)`:
  0→clear · 1,2→partlyCloudy · 3→cloudy · 45,48→fog · 51–57→drizzle · 61–67→rain · 71–77,85,86→snow · 80–82→showers · 95–99→thunderstorm · 그 밖→unknown.
- `Forecast({required Duration utcOffset, required CurrentWeather current, required List<HourlyWeather> hourly, required List<DailyWeather> daily})` + `DateTime wallClock(DateTime instant)` = `instant.toUtc().add(utcOffset)` (필드가 지역 벽시계인 UTC DateTime).
- `CurrentWeather({time, temperature, apparentTemperature, condition, isDay, humidity(int), windSpeed(double m/s), precipitation(double mm)})`
- `HourlyWeather({DateTime time, double temperature, int? precipitationProbability, double precipitation, WeatherCondition condition, bool isDay})`
- `DailyWeather({DateTime date /* 지역 자정의 UTC 시각 */, WeatherCondition condition, double tempMax, double tempMin, int? precipitationProbabilityMax, double precipitationSum, DateTime? sunrise, DateTime? sunset})`
- `RainSummary` sealed union:
  `RainSummary.now({DateTime? stopsAt, required bool snow, required int maxProbability, required double totalMm}) = RainNow` ·
  `RainSummary.later({required DateTime startsAt, required bool snow, required int maxProbability, required double totalMm}) = RainLater` ·
  `RainSummary.none({required int maxProbability}) = NoRain`
- `RainSummary summarizeRain(Forecast forecast, DateTime now)`

**규칙(스펙 그대로):** 창 = `now` 가 속한 시간부터, 예보 지역 기준 다음 자정 전까지. 자정까지 6시간 미만이면 `now` 부터 12시간. 비 시간 = `precipitationProbability ≥ 50` 또는 `precipitation ≥ 0.1`. `snow` = 그 비 구간 첫 시간의 condition 이 snow. `maxProbability`(null 은 0) · `totalMm` 은 창 안 비 시간들 기준(`none` 은 창 전체 최대 확률). `stopsAt` = 지금 비 구간 뒤 창 안 첫 비 아닌 시간, 없으면 null.

- [ ] **Step 1: 실패하는 테스트 작성** — `rain_summary_test.dart`. 예보 픽스처는 테스트 안 헬퍼 `forecast(offset: Duration(hours: 9), hours: [...])` 로 만든다. 케이스:
  - `'오후부터 비'`: now = 지역 10:20, 15시 70%·0.5mm, 16시 80%·1.2mm → `RainLater(startsAt: 지역 15:00 의 UTC, snow: false, maxProbability: 80, totalMm: 1.7)`
  - `'지금 비, 17시에 그침'`: 10시 60%, 11–16시 비, 17시 10% → `RainNow(stopsAt: 17:00)`
  - `'지금 비, 창 안에서 안 그침'` → `RainNow(stopsAt: null)`
  - `'비 없음'`: 최대 30% → `NoRain(maxProbability: 30)`
  - `'확률 null 이어도 강수량 0.2mm 면 비'`(Review Focus 2) → `RainLater`
  - `'눈'`: 첫 비 시간 condition snow → `snow: true`
  - `'자정 6시간 전 → 12시간 창'`: now = 지역 19:00, 다음날 05시 비 → `RainLater(startsAt: 다음날 05:00)`; now = 지역 17:00, 다음날 05시 비 → `NoRain`
  - `'기기 시간대와 무관'`(Review Focus 1): utcOffset −5h 예보에서 지역 날짜 경계로 창이 잘리는지
  - `weather_condition_test.dart`: 위 매핑의 경계값(0,1,2,3,45,51,57,61,67,71,77,80,82,85,86,95,99,100).
- [ ] **Step 2: 실패 확인** — `flutter test test/domain/weather` → 컴파일 에러로 FAIL.
- [ ] **Step 3: 구현** — 위 Interfaces 대로. `build_runner build`.
- [ ] **Step 4: 통과 확인** — `flutter test test/domain/weather` → PASS.
- [ ] **Step 5: 커밋** — `feat(walk): 날씨 예보 엔티티와 비 요약`

### Task 2: Open-Meteo 저장소

**Files:**
- Create: `lib/domain/weather/repository/weather_repository.dart`
- Create: `lib/domain/weather/weather_problem.dart`
- Create: `lib/data/weather/open_meteo_weather_repository.dart`
- Create: `test/fixtures/weather/open_meteo_seoul.json` (실제 응답 녹화)
- Test: `test/data/weather/open_meteo_weather_repository_test.dart`

**Interfaces:**
- Consumes: Task 1 엔티티 · `WeatherCondition.fromWmo`.
- Produces:
  - `enum WeatherProblem { locationServiceOff, locationDenied, locationUnavailable, offline, server }`
  - `class WeatherFailure implements Exception { const WeatherFailure(this.problem); final WeatherProblem problem; }`
  - `class FetchedForecast { final Forecast forecast; final String payload; }` (Freezed 단일 모델)
  - `abstract interface class WeatherRepository { Future<FetchedForecast> fetch(double lat, double lng); Forecast decode(String payload); }` — `payload` 는 출처가 정하는 불투명 문자열(여기선 응답 본문). 캐시가 저장했다가 `decode` 로 되살린다.
  - `@LazySingleton(as: WeatherRepository) class OpenMeteoWeatherRepository(http.Client client, {@ignoreParam Duration timeout = const Duration(seconds: 10)})`

- [ ] **Step 1: 픽스처 녹화** — 서울 시청 좌표로 한 번:
  `curl -s 'https://api.open-meteo.com/v1/forecast?latitude=37.5665&longitude=126.978&timezone=auto&forecast_days=7&wind_speed_unit=ms&current=temperature_2m,apparent_temperature,weather_code,is_day,relative_humidity_2m,wind_speed_10m,precipitation&hourly=temperature_2m,precipitation_probability,precipitation,weather_code,is_day&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,precipitation_sum,sunrise,sunset' > test/fixtures/weather/open_meteo_seoul.json`
- [ ] **Step 2: 실패하는 테스트** (`MockClient`, `OdsayRouteFinder` 테스트와 같은 모양):
  - `'요청 URL 에 스펙의 파라미터가 모두 있다'` — `uri.queryParameters` 의 latitude · longitude · timezone=auto · forecast_days=7 · wind_speed_unit=ms · current/hourly/daily 필드 목록.
  - `'픽스처를 엔티티로 바꾼다'` — `utcOffset == Duration(hours: 9)`, `hourly.length == 168`, `daily.length == 7`, 첫 hourly 의 `time` 이 응답 `hourly.time[0]` 을 −9h 한 UTC, current 값들, `payload == 본문`.
  - `'decode(payload) 는 fetch 와 같은 Forecast'`.
  - `'precipitation_probability 가 null 인 칸은 null'`(Review Focus 2) — 픽스처 사본에서 한 칸을 null 로.
  - `'필드가 빠지면 WeatherFailure(server)'`, `'HTTP 500 → server'`, `'SocketException · TimeoutException · ClientException → offline'`.
- [ ] **Step 3: 실패 확인** — `flutter test test/data/weather/open_meteo_weather_repository_test.dart` FAIL.
- [ ] **Step 4: 구현** — 지역 시각 문자열(`"2026-11-14T15:00"`)은 `DateTime.parse('${s}Z').subtract(utcOffset)`; `utc_offset_seconds` 로 offset. 예외 변환은 `OdsayRouteFinder` 와 같은 갈래. `build_runner build`.
- [ ] **Step 5: 통과 확인** — 같은 명령 PASS.
- [ ] **Step 6: 커밋** — `feat(walk): Open-Meteo 날씨 저장소`

### Task 3: 날씨 위치

**Files:**
- Create: `lib/domain/weather/weather_locator.dart`
- Create: `lib/data/weather/weather_location_source.dart`
- Test: `test/data/weather/weather_location_source_test.dart`

**Interfaces:**
- Consumes: `WeatherProblem`(Task 2); `LocationAccess`, `LocationGateway`(packages/location, DI 등록됨); `PlaceNamer`(`lib/domain/diary/location/place_source.dart`, DI 등록됨).
- Produces:
  - `WeatherFix` sealed union: `WeatherFix.located(double lat, double lng) = WeatherLocated` · `WeatherFix.failed(WeatherProblem problem) = WeatherNoFix`
  - `abstract interface class WeatherLocator { Future<WeatherFix> locate(); Future<String?> placeName(double lat, double lng); Future<void> resolve(WeatherProblem problem); }`
  - `@LazySingleton(as: WeatherLocator) class WeatherLocationSource(LocationAccess access, LocationGateway gateway, PlaceNamer namer, {@ignoreParam Duration timeout = const Duration(seconds: 8)})`

- [ ] **Step 1: 실패하는 테스트** (mocktail 로 gateway · namer, `LocationAccess` 는 진짜에 가짜 gateway):
  - `'서비스 꺼짐 → failed(locationServiceOff)'`, `'권한 거부 → failed(locationDenied)'`
  - `'getCurrentPosition 은 LocationAccuracy.low, 8초로 부른다'` → `located(lat, lng)`
  - `'시간 초과 · 예외 → failed(locationUnavailable)'`
  - `'placeName: PlaceNamed → 이름, PlaceNoName · PlaceOffline · 예외 → null'`
  - `'resolve(locationDenied) → access.permission.requestAgain(), 그래도 거부면 openSettings()'`, `'resolve(locationServiceOff) → access.openLocationSettings()'`, 나머지는 아무것도 안 함.
- [ ] **Step 2: 실패 확인** — `flutter test test/data/weather/weather_location_source_test.dart` FAIL.
- [ ] **Step 3: 구현** · `build_runner build`.
- [ ] **Step 4: 통과 확인** PASS.
- [ ] **Step 5: 커밋** — `feat(walk): 날씨용 지금 위치`

### Task 4: 캐시

**Files:**
- Create: `lib/domain/weather/weather_cache.dart`
- Create: `lib/data/weather/prefs_weather_cache.dart`
- Test: `test/data/weather/prefs_weather_cache_test.dart`

**Interfaces — Produces:**
- `CachedForecast({required String payload, required double lat, required double lng, String? placeName, required DateTime fetchedAt})` (Freezed 단일)
- `abstract interface class WeatherCache { Future<CachedForecast?> read(); Future<void> write(CachedForecast value); }`
- `@LazySingleton(as: WeatherCache) class PrefsWeatherCache(SharedPreferences prefs)` — 키 `weather.cache.v1`, 값은 JSON 한 줄(`PrefsLocationPreferences` 와 같은 prefs 타입).

- [ ] **Step 1: 실패하는 테스트** — `'쓰고 읽으면 같다'`(fetchedAt UTC 보존), `'비어 있으면 null'`, `'깨진 JSON · 필드 빠짐 → null 이고 던지지 않는다'`(Review Focus 5).
- [ ] **Step 2–4:** 실패 확인 → 구현 · `build_runner` → `flutter test test/data/weather/prefs_weather_cache_test.dart` PASS.
- [ ] **Step 5: 커밋** — `feat(walk): 날씨 마지막 예보 캐시`

### Task 5: WeatherCubit

**Files:**
- Create: `lib/presentation/weather/cubit/weather_state.dart`, `lib/presentation/weather/cubit/weather_cubit.dart`
- Test: `test/presentation/weather/cubit/weather_cubit_test.dart`

**Interfaces:**
- Consumes: `WeatherRepository`, `WeatherLocator`, `WeatherCache`, `Clock`, `WeatherProblem`, `WeatherFix`.
- Produces:
  - `WeatherState` sealed union:
    `WeatherState.loading() = WeatherLoading` ·
    `WeatherState.loaded({required Forecast forecast, String? placeName, required DateTime fetchedAt, @Default(false) bool refreshing, @Default(false) bool stale, WeatherProblem? problem}) = WeatherLoaded` ·
    `WeatherState.empty(WeatherProblem problem) = WeatherEmpty`
    (`stale` = 이번 요청이 실패해 캐시 예보를 보이는 중. `problem` = 이번 갱신에서 생긴 문제 — 위치 실패 뒤 캐시 좌표로 새 예보를 받았으면 `stale: false, problem: 위치 문제`.)
  - `@injectable class WeatherCubit extends Cubit<WeatherState>`:
    `Future<void> shown()` · `Future<void> resumed()` (둘 다 10분 규칙 적용) · `Future<void> refresh()` (항상) · `Future<void> resolve(WeatherProblem problem)` (locator.resolve 뒤 refresh)
  - 상수 `static const freshFor = Duration(minutes: 10)`, `static const cacheMaxAge = Duration(hours: 24)`.

**흐름(스펙 [상태](../specs/2026-11-14-walk-weather-design.md#상태) · [캐시](../specs/2026-11-14-walk-weather-design.md#캐시)):**
1. 아직 아무 예보도 없으면 캐시를 읽는다. `now − fetchedAt ≤ 24h` 면 `loaded(decode(payload), refreshing: true)`.
2. `shown`/`resumed` 이고 마지막 **성공**(`fetchedAt`)이 10분 안이면 여기서 끝(refreshing 끔).
3. `locate()`. 실패면 유효 캐시 좌표로 대신 요청하고 `problem` 을 기억, 캐시도 없으면 `empty(problem)`.
4. 좌표가 새로 잡히면 `placeName` 을 요청과 **동시에** 시작한다. 예보를 먼저 내보내고, 이름이 오면 같은 좌표일 때 `placeName` 만 바꿔 다시 내보내고 캐시도 고친다. 이름 실패 → null(화면은 "현재 위치"). 위치 실패로 캐시 좌표를 쓰면 이름도 캐시 것.
5. 성공 → 캐시 쓰기 → `loaded(fresh, fetchedAt: now, problem: 위치 문제 or null)`. `WeatherFailure` → 캐시가 있으면 `loaded(캐시, stale: true, problem)`, 없으면 `empty(problem)`.
6. 진행 중에 다시 불리면 같은 Future 를 돌려준다(요청 한 번).

- [ ] **Step 1: 실패하는 테스트** (mocktail 가짜 넷 + 고정 `Clock`, `bloc_test`):
  - `'캐시 없음 + 성공 → loading 뒤 loaded, 캐시에 쓴다'`
  - `'유효 캐시 → 캐시 예보를 refreshing 으로 먼저, 그다음 새 예보'`
  - `'25시간 된 캐시는 버리고 loading 부터'`
  - `'shown: 5분 전 성공이면 요청하지 않는다'` · `'refresh 는 5분 전이어도 요청한다'`
  - `'요청 실패 뒤 shown 은 10분 안이라도 다시 요청한다'`(실패는 막지 않는다)
  - `'위치 거부 + 캐시 → 캐시 좌표로 요청, problem: locationDenied, placeName 은 캐시 것'`
  - `'위치 거부 + 캐시 없음 → empty(locationDenied)'`
  - `'오프라인 + 캐시 → loaded(stale: true, problem: offline)'`
  - `'이름이 예보보다 늦게 오면 예보 먼저, 이름은 나중에'` · `'이름 실패 → placeName null'`(Review Focus 4)
  - `'refresh 와 shown 이 겹쳐도 fetch 는 한 번'`(Review Focus 3)
  - `'resolve(locationDenied) → locator.resolve 뒤 refresh'`
- [ ] **Step 2–4:** 실패 확인 → 구현 · `build_runner` → `flutter test test/presentation/weather/cubit` PASS.
- [ ] **Step 5: 커밋** — `feat(walk): 날씨 cubit`

### Task 6: 날씨 화면 · 문구

**Files:**
- Create: `lib/presentation/weather/format/weather_format.dart` — condition → (아이콘, l10n 라벨), 밤이면 clear · partlyCloudy 는 달 아이콘(`Icons.nightlight_round` · `Icons.nights_stay`); 시각 라벨("오후 3시", 오늘/내일 접두); `RainSummary` → 제목 · 부제 문자열.
- Create: `lib/presentation/weather/page/weather_page.dart` — `WeatherPage({required bool active})`. 셸 위의 `WeatherCubit` 을 읽는다. 처음 `active` 일 때와 false → true 일 때 `cubit.shown()`. `RefreshIndicator` → `cubit.refresh()`.
- Create: `lib/presentation/weather/widget/` — `weather_now_header.dart`(장소 · 큰 기온 · 상태 · 체감 · 최고/최저), `rain_summary_card.dart`, `hourly_strip.dart`(지금부터 24칸 가로 스크롤, 비 시간 강수확률은 강조색, null 확률은 "–"), `daily_list.dart`(7일, 최저–최고 막대), `weather_details_row.dart`(습도 · 바람 · 일출 · 일몰), `weather_problem_banner.dart`, `weather_footer.dart`("14:02 갱신 · Open-Meteo").
- Modify: `packages/l10n/lib/l10n/app_{ko,en,ja}.arb` — `walkToolsTabWeather` 와 `walkWeather*` 키 추가(설명 `@` 항목 포함), gen-l10n.
- Test: `test/presentation/weather/format/weather_format_test.dart`, `test/presentation/weather/page/weather_page_test.dart`

**고정 문구(ko, 스펙에서):** 탭 "날씨" · "현재 위치" · "{time}쯤부터 비가 와요"(눈이면 "눈이 와요") · "지금 비가 와요 · {time}쯤 그쳐요" · 안 그치면 "지금 비가 와요 · 오늘 밤 이후에 그쳐요" · "오늘은 비 소식이 없어요" · 부제 "최대 {p}% · {mm}mm" / "최대 강수확률 {p}%" · 상태 라벨 맑음 · 구름 조금 · 흐림 · 안개 · 이슬비 · 비 · 소나기 · 눈 · 뇌우 · 알 수 없음 · 문제 줄 예 "위치를 못 읽어 {hours}시간 전 {place} 예보예요" · 빈 상태 버튼 '권한 허용' · '위치 켜기' · '다시 시도' · 꼬리 "{time} 갱신 · Open-Meteo". en · ja 는 같은 뜻으로.

- [ ] **Step 1: 실패하는 테스트**
  - format: `'15시 → 오후 3시'`, `'내일 05시 → 내일 오전 5시'`(Review Focus 1, 예보 지역 기준), `'RainLater 문구'` · `'RainNow 그침/안 그침'` · `'NoRain'` · `'눈'`, `'밤 clear → 달 아이콘'`.
  - page(가짜 `WeatherCubit` 상태 주입): `'loaded → 장소 · 기온 · 비 요약 · 시간별 24칸 · 일별 7행 · Open-Meteo 표기'`, `'placeName null → 현재 위치'`, `'stale + problem → 문제 줄'`, `'empty(locationDenied) → 권한 허용 누르면 resolve(locationDenied)'`, `'empty(offline) → 다시 시도 누르면 refresh'`, `'당기면 refresh'`, `'active false→true 에서만 shown'`.
- [ ] **Step 2–4:** 실패 확인 → 구현(공통 위젯 · 토큰) → `flutter test test/presentation/weather` PASS, `flutter analyze` 0.
- [ ] **Step 5: 커밋** — `feat(walk): 날씨 화면`

### Task 7: 도구 탭 · 셸 연결과 문서

**Files:**
- Modify: `lib/presentation/shell/page/tools_tab.dart` — `enum ToolsSection { alarm, walk, map, weather }`; 탭 `Tab(text: l10n.walkToolsTabWeather)`; 본문 `_KeepAlive(child: WeatherPage(active: widget.active && widget.section == ToolsSection.weather))`; 앱바 actions `ToolsSection.weather => [const FeatureMenu(settings: SettingsTarget.app, showFeatureSettings: false)]`; 클래스 주석에 날씨 추가.
- Modify: `lib/presentation/shell/page/main_shell_page.dart` — `MultiBlocProvider` 에 `BlocProvider(create: (_) => _weather = getIt<WeatherCubit>())`; `_onResume` 에서 `_refreshWeather()` = 도구 · 날씨 · `!_covered` 일 때 `unawaited(_weather?.resumed())`.
- Test: `test/presentation/shell/page/main_shell_page_test.dart`, `test/presentation/shell/page/tools_tab_test.dart`
- Modify docs: `apps/walk/docs/plan.md`(도구 상단 탭 [알람 · 걷기 · 지도 · 날씨]), `apps/walk/docs/README.md`(한 줄), `apps/walk/docs/status.md`(날씨 섹션: 체크 · 검증 결과 · 기기 확인 대기), `apps/walk/docs/history.md`(2026-11-14 날씨 — 출처 결정 · 위치 분리 · 캐시 규칙), `apps/walk/docs/testing.md`(날씨 기기 시나리오 W-1~W-4: 처음 열기 권한 · 비 오는 날 요약 확인 · 비행기 모드에서 캐시 · 위치 끄기).

- [ ] **Step 1: 실패하는 테스트** — 셸 테스트의 `pump` 에 `WeatherCubit` 가짜를 getIt 에 등록하고:
  - `'도구 상단 탭은 알람 · 걷기 · 지도 · 날씨'`
  - `'날씨 상단 탭을 누르면 WeatherPage 가 보이고 shown 이 불린다'`
  - `'날씨 탭 ⋮ 는 앱 설정만'`
  - `'날씨를 보던 중 복귀하면 resumed 를 부른다'` · `'다른 상단 탭을 보던 중 복귀하면 부르지 않는다'`
- [ ] **Step 2–4:** 실패 확인 → 구현 → `flutter test` 전체 PASS, `flutter analyze` 0, `cd ../trader && flutter test test/convention/documentation_links_test.dart` PASS.
- [ ] **Step 5: 커밋** — `feat(walk): 도구 탭에 날씨` (코드 · 테스트 · 문서 함께)
