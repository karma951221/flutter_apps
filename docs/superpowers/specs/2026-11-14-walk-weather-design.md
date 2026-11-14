# 도구 › 날씨 — 설계

> [걷기 허브](../../../apps/walk/docs/README.md) · [걷기 진행 현황](../../../apps/walk/docs/status.md)

## 의도

나가기 직전 "오늘 오후에 비 오나?"를 검색하지 않고 앱을 열어 한눈에 본다. 실사용에서 도구 탭을
가장 자주 열기 때문에 도구 탭 안에 둔다(2026-11-14 첫 탭을 도구로 옮겼다). 화면은 안드로이드 기본
날씨 앱처럼 위에서 아래로 훑는 구성 — 지금 날씨 → 시간별 → 일별.

## 목표 · 비목표 · 반목표

- **목표**
  - 열자마자 "비가 오는지, 언제 오는지"가 첫 화면 위쪽에 보인다.
  - 지금 위치 기준. 열 때 · 당겨서 새로고침 때 다시 읽는다.
  - 오프라인이거나 위치를 못 얻어도 마지막으로 받은 예보를 시각과 함께 보인다.
- **비목표(이번엔 안 함)**
  - 저장한 장소(집 · 회사) · 장소 검색 · 여러 장소 전환.
  - 날씨 알림(비 예보 푸시) · 홈 화면 위젯 · 알람 울림 화면에 날씨 넣기.
  - 미세먼지 · 자외선 · 꽃가루.
  - 물어보기의 날씨 도구화.
- **반목표(되면 실패)**
  - 키 발급 · 결제 등록이 있어야 동작한다(통근 탭이 키 발급에서 멈춰 있다).
  - 열 때마다 권한 창이 뜨거나, 위치를 기다리느라 빈 화면이 오래 간다.
  - 기본 날씨 앱의 브랜드 · 캐릭터 · 아이콘을 그대로 베낀다(배치만 참고, 그림은 Material 아이콘).

## 출처: Open-Meteo

| 방식 | 장점 | 단점 | 판정 |
|---|---|---|---|
| **Open-Meteo Forecast API** | 키 · 결제 없음, HTTPS, 좌표 하나로 지금 · 시간별 · 일별을 한 번에 | 한국 정확도는 기상청 원본보다 낮을 수 있음 | **채택** |
| 기상청 단기예보(공공데이터포털) | 한국에서 가장 정확 | 키 발급, 위경도 → 격자 변환, 발표 시각 계산, 3일까지만 | 나중 교체 후보 |
| Google Weather API(Maps Platform) | 기본 날씨 앱과 같은 계열 | 결제 계정 · 키, 사용량 과금 | 제외 |
| 기본 날씨 앱에서 읽기 | — | 공개 통로(API · ContentProvider)가 없다 | 불가 |
| 물어보기(AI 웹 검색) 재사용 | 이미 있음 | 매번 비용 · 지연, 화면용 구조화 데이터가 아님 | 제외 |

출처는 도메인 인터페이스 뒤에 숨겨 기상청 등으로 바꿀 수 있게 한다.

요청(한 번, `https://api.open-meteo.com/v1/forecast`):

- `latitude`, `longitude`, `timezone=auto`, `forecast_days=7`
- `current=temperature_2m,apparent_temperature,weather_code,is_day,relative_humidity_2m,wind_speed_10m,precipitation`
- `hourly=temperature_2m,precipitation_probability,precipitation,weather_code,is_day`
- `daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,precipitation_sum,sunrise,sunset`
- `wind_speed_unit=ms`. 모델은 기본(`best_match`) — 강수확률이 함께 오는 기본 모델을 쓴다.

평문 http 가 아니므로 `network_security_config.xml` 은 그대로 둔다.

## 화면

도구 상단 탭에 넷째 **날씨**를 더한다: `ToolsSection { alarm, walk, map, weather }`.
앱바 ⋮ 는 [앱 설정]만(날씨 설정 화면은 이번에 없다 — `FeatureMenu` 의 기능 설정을 끈다).
일기 잠금과 무관하다(위치 기록이 아니라 지금 위치 한 번을 읽는다).

```
📍 서울 마포구 망원동            ← 장소 이름(없으면 "현재 위치")
        12°  흐림                ← 지금: 큰 기온 + 하늘 상태 아이콘
   체감 10° · 최고 14° 최저 8°
┌──────────────────────────────┐
│ ☔ 오후 3시쯤부터 비가 와요     │ ← 비 요약 한 줄(아래 규칙)
│    최대 70% · 4mm             │
└──────────────────────────────┘
 시간별 (가로 스크롤, 지금부터 24시간)
 지금  15시  16시  17시  18시 …
 ☁     🌧    🌧    🌦    ☁
 12°   13°   12°   11°   10°
 10%   70%   80%   40%   20%       ← 강수확률, 비 시간대만 강조색
 일별 (7일)
 오늘   🌧 70%   8° ━━━━━ 14°
 내일   ☀  0%    6° ━━━ 12°
 …
 습도 82% · 바람 3m/s · 일출 07:02 · 일몰 17:22
 14:02 갱신 · Open-Meteo           ← 갱신 시각과 출처 표기
```

- 당겨서 새로고침.
- 날씨 코드(WMO) → Material 아이콘 + 짧은 한국어 설명(맑음 · 구름 조금 · 흐림 · 안개 · 이슬비 ·
  비 · 소나기 · 눈 · 뇌우). 밤이면(`is_day=0`) 맑음 · 구름 조금은 달 아이콘.
- 색 · 여백 · 글자는 `design_system` 토큰. 빈 · 오류 상태는 `AppPlaceholder`.

### 비 요약 한 줄 규칙

지금부터 오늘 자정까지(자정이 6시간 안이면 지금부터 12시간)의 시간별을 본다. "비 시간"은
강수확률 ≥ 50% 또는 강수량 ≥ 0.1mm 인 시간이다(눈 코드면 "눈").

- 지금 비 시간이면: "지금 비가 와요 · ○시쯤 그쳐요"(창 안에서 그치는 시간이 없으면 "그치는 시간: 오늘 밤 이후")
- 창 안 첫 비 시간이 있으면: "○○ ○시쯤부터 비가 와요"(오전/오후 · 내일 표기) + 최대 확률 · 합계 강수량
- 없으면: "오늘은 비 소식이 없어요" + 창 안 최대 강수확률

## 상태

`WeatherCubit` (Freezed union):

- `loading` — 처음 열 때, 쓸 수 있는 캐시도 없을 때만. 캐시가 있으면 그 예보를 먼저 보이고 뒤에서 다시 읽는다.
- `loaded(forecast, place, fetchedAt, refreshing, problem?)` — `problem` 은 이번 갱신 실패 이유
  (`WeatherProblem`: 위치 서비스 꺼짐 · 위치 권한 없음 · 위치 못 얻음 · 오프라인 · 서버 오류). 예보는 남기고
  위에 한 줄로 알린다 — 예: "위치를 못 읽어 3시간 전 망원동 예보예요".
- `empty(problem)` — 쓸 수 있는 캐시도 없고 실패. 권한 없음이면 '권한 허용' 버튼 — `LocationAccess.permission`
  으로 다시 요청 · 설정 열기, 위치 서비스 꺼짐이면 '위치 켜기' 버튼 — `openLocationSettings`, 나머지는 '다시 시도'.

`fetchedAt` 은 **성공한** 응답을 받은 시각이다. 화면의 "14:02 갱신"과 10분 규칙이 이 값을 쓴다.

다시 읽는 때: 날씨 상단 탭이 보이게 될 때 · 보이는 상태에서 앱 복귀 · 당겨서 새로고침. 탭 전환 · 복귀로는
마지막 **성공**이 10분 안이면 다시 부르지 않는다. 실패한 시도는 막지 않는다(다음 전환 · 복귀에 다시 부른다).
당겨서는 항상 부른다. 이 규칙은 cubit 안에 둔다(시각은 `Clock`).

보임 신호는 걷기 · 지도와 같은 방식이다: `ToolsTab` 이 `active && section == ToolsSection.weather` 를
`WeatherPage(active:)` 로 넘기고, 페이지가 false → true 로 바뀔 때 cubit 에 알린다. `TabBarView` 의
`_KeepAlive` 로 페이지와 cubit 은 앱이 떠 있는 동안 하나다. 앱 복귀는 셸의 기존 `_onResume` 이 이미 셸
위에 얹힌 화면이 걷힐 때 `active` 를 다시 켜므로, 복귀도 셸에서 지도처럼(`_refreshMap`) 보이는 경우에만
cubit 의 `resumed()` 를 부른다 — 새 `WidgetsBindingObserver` 를 걸지 않는다. cubit 은 셸이 아니라 날씨
페이지가 만든다(`BlocProvider.create`); 셸은 지도 cubit 처럼 잡아 두었다가 복귀 때 부른다.

### 캐시

- 마지막 성공 한 벌(응답 JSON · 좌표 · 장소 이름 · `fetchedAt`)만 둔다.
- **위치를 얻었으면 캐시 좌표와 상관없이 그 위치로 읽는다.** 캐시는 처음 그리기와, 위치나 네트워크가 실패했을
  때만 쓴다. 그래서 다른 도시로 옮겨 가도 위치만 얻으면 그곳 예보로 바뀐다.
- `fetchedAt` 이 **24시간**보다 오래된 캐시는 쓰지 않는다(시간별 띠가 거의 지난 시간이 된다) — `empty` 로 간다.
- 캐시를 보이는 동안 위 `problem` 줄에 몇 시간 전 · 어느 장소 예보인지 적는다.

## 위치

일기의 `PlaceSource.current()` 는 실패 이유를 모두 `null` 로 합치고 정확도 high · 10초라 날씨에 맞지
않는다. 일기 쪽 계약은 바꾸지 않고, 날씨 전용 `WeatherLocationSource`(data/weather)를 DI 의
`LocationAccess` · `LocationGateway` · `PlaceNamer` 로 만든다.

- `LocationAccess.ensure()` 로 상태를 받아 실패 이유를 구분해 돌려준다(위 `WeatherProblem`).
- 좌표는 `getCurrentPosition(accuracy: LocationAccuracy.low, timeout: 8초)` — 날씨에는 수 km 정확도로
  충분하고 네트워크 위치가 빨리 온다. `packages/location` 의 게이트웨이는 고치지 않는다
  (`getLastKnownPosition` 을 더하면 다른 앱 · 테스트의 구현체가 함께 바뀐다).
- 장소 이름(`PlaceNamer`, 네트워크)은 예보 요청을 막지 않는다 — 예보와 동시에 부르고, 늦게 오면 이름만
  나중에 채운다. 이름이 없으면 "현재 위치".

## 시각

예보는 그 좌표의 시간대로 본다. 응답의 `utc_offset_seconds` 로 `hourly.time` 등 지역 시각 문자열을 절대
시각(UTC `DateTime`)으로 바꿔 엔티티에 넣고, 엔티티에 `utcOffset` 을 함께 둔다. "지금"은 `Clock`(절대 시각),
"오늘 자정" · 화면의 "15시" · "오늘/내일"은 예보 좌표의 지역 시각으로 계산한다. 기기 시간대와 예보 좌표
시간대가 같은 평소에는 차이가 없고, 다를 때(여행 · 오래된 캐시)도 그 장소 기준으로 맞게 보인다.

## 구조

`lib/{domain,data,presentation}/weather/` (앱 전용 — packages 에 두지 않는다).

- `domain/weather/entity/` — `Forecast`(current · hourly · daily), `HourlyWeather`, `DailyWeather`,
  `WeatherCondition`(WMO 코드 묶음 enum).
- `domain/weather/repository/weather_repository.dart` — `Future<Forecast> forecast(double lat, double lng)`.
- `domain/weather/rain_summary.dart` — 위 규칙의 순수 함수. 시각은 `Clock` 으로.
- `data/weather/open_meteo_weather_repository.dart` — 등록된 `http.Client`. 응답 JSON → 엔티티.
- `data/weather/weather_location_source.dart` — 아래 [위치](#위치).
- `data/weather/prefs_weather_cache.dart` — 마지막 응답 JSON · 좌표 · 장소 이름 · 받은 시각을
  `shared_preferences` 에 한 벌.
- `presentation/weather/{cubit,page,widget,format}/`.
- 셸 · `ToolsTab` 연결, l10n 키(ko · en · ja).

## 테스트

- `rain_summary` 경계(지금 비 · 오후부터 · 내일 · 없음 · 눈 · 자정 근처 창 · 기기와 다른 시간대).
- Open-Meteo 파서 — 녹화한 실제 응답 픽스처 1개 + 결측 필드.
- `WeatherLocationSource` — 서비스 꺼짐 · 권한 없음 · 시간 초과를 구분, 이름 조회가 좌표를 막지 않음.
- cubit — 캐시 먼저 · 실패 시 캐시 유지 · 위치 실패 시 마지막 좌표 · 24시간 지난 캐시 버림 · 10분 규칙
  (성공 기준, 실패 뒤엔 다시 부름).
- 위젯 — 상단 탭 넷, 날씨 탭 ⋮ 는 앱 설정만, 빈 · 오류 상태.
- 기기: 에뮬레이터에서 실제 응답으로 한 번.

## 빌더에게 맡기는 것

- 아이콘 매핑의 세부, 시간별 셀 폭, 일별 막대의 그리기 방식(토큰 안에서).
- 픽스처 녹화 좌표(서울 시청 근처 고정).
