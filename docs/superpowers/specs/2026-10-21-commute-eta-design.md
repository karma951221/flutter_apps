# walk — 통근(경로 · 실시간 지하철 · 도착 예상) 설계

> 작성 2026-10-21 · 상태: **구현 완료(코드) · 키 · 기기 확인 대기** · 앱 문서 [walk 허브](../../../apps/walk/docs/README.md) ·
> 진행 현황 [walk status](../../../apps/walk/docs/status.md)

## 1. 목적

Life Tool(`apps/walk`)에 **통근** 탭을 더한다. 집과 회사 위치를 저장해 두고, 집을 나서기 직전
조회 버튼을 한 번 누르면 네이버 지도처럼 **최적 경로**와 **첫 승차역에 다음 열차가 몇 분 뒤 · 몇 정거장 전에
있는지**, 그리고 그 열차를 탈 때의 **회사 도착 예상 시각**을 보여준다.

사용자의 실제 아침: 출근 1시간 전에 일어나 15분 안에 준비하고 나선다. 집 → (도보) 장승배기역 → 7호선 →
논현 → (도보 환승) 신논현 → 신분당선 → 강남 → (도보) 메리츠타워. 현관에서 네이버 지도를 열어 장승배기역에
7호선이 언제 오는지 보고 **역까지 뛸지 걸을지** 정한다. 이 확인을 네이버 지도가 아니라 Life Tool 에서 하고 싶다.

로그인 · 백엔드 없음, 안드로이드만, 사용자 혼자 무료 한도 안에서 쓴다. 기존 `apps/commute`(v1, 가짜 경로 ·
역 30개)는 건드리지 않는다. 데이터 이전도 없다(walk 에는 통근 데이터가 없었다).

## 2. 범위

**MVP**

- 하단 탭 [알람 · 걷기 · 일기 · **통근** · 설정]
- 장소 2개: **집 · 회사**(좌표 + 표시용 주소). 현재 위치로 지정 또는 주소 검색
- 방향 2개: **출근(집→회사) · 퇴근(회사→집)**
- **조회 버튼을 누를 때만** 네트워크를 쓴다 — ODsay 길찾기 1회 + 서울시 실시간 지하철 도착 1회
- 경로는 **지하철만**(ODsay `SearchPathType=1`). 후보 여러 개 중 하나를 고를 수 있고, 고른 경로를 방향별로 기억
- 결과: 경로 요약(노선 · 환승 · 총 시간) · 첫 승차역 다음 열차 2대(몇 분 후 · 몇 번째 전역) ·
  걸어서 탈 수 있는지 판단 · 회사 도착 예상 시각 · 조회 시각

**다음 단계(이 문서 범위 밖, 구조만 막지 않는다)**

1. 버스 포함 경로(`SearchPathType=0`) + 서울 버스 도착정보 API 로 버스 실시간
2. 환승역 실시간(가는 도중 재조회 시 둘째 구간 도착 표시)
3. 장소 추가(헬스장 등) · 임의 출발지(현재 위치) 조회

**하지 않을 것(비목표 · 반목표)**

- 자동 새로고침 · 주기 호출 · 알림 · 홈 위젯 · 지오펜스/Wi-Fi 기반 출발 감지 — 사용자 결정: "조회버튼 눌렀을 때만"
- 지도 화면, 경로 선 그리기
- 자동차 경로
- 사용자가 직접 넣은 숫자로 정확해 보이는 값을 만드는 것 — 도착 예상은 API 구간 시간에서만 계산한다
- 서버 · 키 프록시(혼자 쓰는 사이드로드 APK)

## 3. 결정 기록

| 결정 | 이유 |
|---|---|
| 새 앱이 아니라 Life Tool(`apps/walk`)에 탭으로 넣는다 | 사용자 결정. `apps/commute` 는 손대지 않는다 |
| 출발 감지 없이 **수동 조회만**. 조회 시에만 API 호출 | 사용자 결정. 배터리 · 권한 · 호출 수 문제가 사라진다 |
| 장소(집 · 회사)를 **좌표**로 저장하고 경로는 매 조회 때 API 로 찾는다 | 사용자 결정(장소를 저장해 두고 그 사이를 조회). 환승을 손으로 등록하면 "반쪽 앱"이라는 사용자 지적 → 길찾기 API 도입 |
| 경로 API = **ODsay LAB** `searchPubTransPathT` | 역 ID · 상하행(`wayCode`) · 구간별 시간을 줘서 실시간 API 와 맞추기 쉽다. 다음 단계 버스 실시간에 정류장 ID 가 필요한데 카카오 `publictraffic` 은 이름만 준다. 네이버 클라우드는 대중교통 경로 API 가 없다. (내 판단, 사용자는 무료 · 혼자 사용만 조건으로 줌) |
| 실시간 = **서울시 실시간 지하철 도착정보** `realtimeStationArrival` | 사용자 결정(MVP) |
| MVP 경로는 **지하철만** | 사용자 결정. 버스는 다음 단계 |
| 실시간은 **첫 승차역만** | 실시간 API 는 지금 그 역으로 다가오는 열차만 보여줘 20분 뒤 환승역 열차는 아직 없다. 네이버 지도도 같은 방식 |
| 도착 예상 = 첫 열차 도착 시각 + 그 뒤 ODsay 구간 시간 합 | 환승 대기는 ODsay 값 그대로(예상치). 화면에 "예상" 표기 |
| 판단은 **걷는 것 기준만**. 도보 `w` = ODsay 첫 도보 구간 시간, 역 안 여유 1분. 열차 `t`분 뒤일 때 `t ≥ w+1` 이면 탈 수 있음, 아니면 놓침 → 다음 열차로 같은 판단. 뛰는 시간은 계산 · 표시하지 않는다 | 사용자 결정("기본적으로 걷는 걸로"). 여유 1분은 상수로 두고 실제 사용 후 조정 |
| 출발지는 저장한 장소 좌표(조회 시 GPS 안 씀) | 현관에서 누른다. 조회에 위치 권한이 필요 없다. 위치 권한은 "현재 위치로 지정"에서만 |
| 경로 후보 중 고른 것을 방향별로 기억(노선 + 승하차역 서명). 다음 조회에 같은 서명이 있으면 그것을 기본으로 | 내 판단. ODsay 1순위가 사용자 실제 경로(7호선→신분당선)와 다를 수 있다 |
| 저장은 `shared_preferences`(장소 2개 · 고른 경로 서명 2개) | 작은 값. `PrefsSettingsRepository` 와 같은 방식. drift 불필요 |
| 결과는 저장하지 않는다(캐시 없음). 탭을 다시 열면 마지막 결과를 메모리에서만 보여주고 "n분 전 조회" 표시 | 낡은 실시간 값이 진짜처럼 보이지 않게 |
| API 키는 `--dart-define-from-file`(gitignore 된 json)로 주입, 앱에 들어간다 | 혼자 쓰는 사이드로드 APK. 키가 비어 있으면 탭에 "키 없음" 안내 |
| 실시간에 분이 없으면 정거장 수 × 역간 평균 시간으로 추정, "약 n분" 표기 | 사용자 결정(추천안). 사용자 입력이 아니라 API 값에서 나온 추정이라 비목표와 충돌하지 않는다 |
| 경로 API 대체 순서: ODsay 안드로이드 키 → ODsay 다른 플랫폼 키(서버 · 웹) → 카카오 `publictraffic`(developers.kakao.com 공식 문서 API) | 내 판단 |
| 완료 상태는 "코드 완료 · 기기 확인 대기". 실제 출근길 비교는 사용자가 한다 | 기존 walk 기능과 같은 관례 |
| HTTP 는 `http` 패키지 | walk 에 HTTP 클라이언트가 없다. 호출 2종 · GET 만이라 가벼운 쪽 (내 판단) |

## 4. 구조

walk 의 계층(`lib/{core,data,domain,presentation}` 아래 기능 폴더)을 따른다.

```text
domain/commute/   entity(Place · PlaceKind · CommuteDirection · TransitRoute · RouteLeg · TrainArrival · CatchVerdict · CommuteResult)
                  repository 인터페이스(PlaceRepository · RouteFinder · SubwayArrivalSource · RoutePreferenceRepository)
                  usecase(CommuteUseCase: 조회 · 판단 · 도착 예상 계산), CatchPolicy(순수 함수)
data/commute/     PrefsPlaceRepository · PrefsRoutePreferenceRepository
                  OdsayRouteFinder(+ 응답 파서) · SeoulSubwayArrivalSource(+ 응답 파서 · 노선 코드 매핑)
                  AddressResolver(geocoding: 주소 ↔ 좌표)
core/config/      CommuteApiKeys(String.fromEnvironment)
presentation/commute/  통근 탭 · 장소 설정 시트 · 결과 카드 · 경로 후보 시트
```

- 경로 · 실시간 소스는 인터페이스 뒤에 둔다. ODsay 키가 안드로이드 앱에서 막히면(§10) 카카오
  `publictraffic` 구현으로 바꿀 수 있어야 한다.
- 위치는 `packages/location`(geolocator 래퍼)을 재사용한다. 주소 변환은 이미 쓰는 `geocoding`.
- 공통 UI 는 `design_system` 위젯을 먼저 쓴다(CLAUDE.md UI 규칙). 문자열은 `packages/l10n` ARB.
- `ShellTab` enum 에 `commute` 를 `settings` 앞에 추가한다. 기본 첫 탭(`walk`)은 그대로.

## 5. 데이터

```text
Place          kind(home|work) · lat · lng · label(표시 주소, 예: "동작구 상도동 …")
TransitRoute   totalMinutes · transferCount · legs[] · signature
RouteLeg       walk(minutes) | subway(minutes · lineName · odsayLaneCode · startStation · endStation ·
               startStationId · wayCode(1 상행 / 2 하행) · wayName("장암 방면") · stationCount)
TrainArrival   minutes(보정 후 · nullable) · estimated · stationsAway(nullable) · message(원문 arvlMsg2) · trainLineNm · receivedAt
CommuteResult  direction · route · alternatives[] · arrivals[≤2] · verdict · etaAt · queriedAt
```

**API → 도메인 맞추기**

- 승차역: ODsay 첫 지하철 구간의 `startName` 을 서울 API 역 이름으로 쓴다("역" 접미사 제거).
- 노선: ODsay `subwayCode` → 서울 API `subwayId` 매핑 표(예: 7호선 → `1007`, 신분당선 → `1077`).
  표에 없는 노선(서울 API 미지원)은 실시간 없이 경로 · 시간표 기반 예상만 보여준다.
- 방향: ODsay `wayCode` 1/2 ↔ 서울 `updnLine` 상행/하행(2호선은 내선/외선). 맞지 않으면
  `trainLineNm` 의 "…방면"과 ODsay `way` 를 비교한다. 첫 구현 단계에서 7호선 · 신분당선 실제 응답으로 확정한다.
- 몇 분 후: `barvlDt`(초)가 0보다 크면 그것에서 `recptnDt` 이후 경과를 뺀다. 0이면 `arvlMsg2` 의 "n분 m초 후"를
  파싱한다. 둘 다 없고 정거장 수만 있으면 **정거장 수 × 역간 평균 시간**(ODsay 첫 지하철 구간
  `sectionTime ÷ stationCount`)으로 추정하고 `TrainArrival.estimated = true` 로 둔다. 화면은 "약 4분".
  판단 · 도착 예상은 추정값으로도 계산한다(사용자 결정). "전역 도착"은 1정거장, "당역 도착"은 0분.
  정거장 수도 없으면 분을 비우고 원문 메시지만 보여주며, 그 열차는 판단에서 뺀다.
- 몇 정거장 전: `arvlMsg2` 의 "[n]번째 전역" · "전역 도착/출발" · "당역 도착" 을 파싱한다. 실패하면 비운다.

**저장 키(shared_preferences)**: `commute.place.home` · `commute.place.work`(json) ·
`commute.route.toWork` · `commute.route.toHome`(경로 서명 문자열).

## 6. 화면 · 흐름

### 6.1 통근 탭

- 위: 방향 토글 **[출근 | 퇴근]**. 시각으로 기본값을 고른다(정오 전 출근, 이후 퇴근 — 내 판단).
- 그 아래 장소 줄: "집 동작구 … → 회사 강남구 …", 누르면 장소 설정 시트.
- 큰 **조회** 버튼(`AppButton.primary`, 로딩 표시).
- 결과 카드
  - **판단 배너**: 걸어가면 탈 수 있어요(초록) · 걸어서는 이번 열차를 놓쳐요 — 다음 열차 기준(회색)
  - **장승배기 · 7호선 장암 방면**: 다음 열차 `4분 후 · 3번째 전역`, 그다음 `11분 후 · 7번째 전역`.
    역까지 도보 6분
  - **도착 예상 8:52**(예상) · 총 41분 · 환승 1회
  - 경로 줄: `도보 6 → 7호선 장승배기→논현 16 → 도보 3 → 신분당선 신논현→강남 2 → 도보 7` · "다른 경로 n개"
  - "08:11 조회" — 2분 넘으면 흐리게 "다시 조회하세요"
- 상태: 장소 미설정(설정 안내 `AppPlaceholder`) · 키 없음 · 네트워크 오류 · 경로 없음 · 실시간 없음(경로 · 예상만)

### 6.2 장소 설정 시트

- 집 · 회사 각각: **현재 위치로 지정**(위치 권한 요청) 또는 **주소 검색**(geocoding, 결과 목록에서 선택)
- 저장 시 표시 주소를 역지오코딩으로 채운다. 실패하면 좌표 문자열.

### 6.3 경로 후보 시트

- ODsay 후보를 총 시간순으로 나열(노선 칩 · 환승 · 시간). 고르면 그 경로로 결과를 다시 계산하고, 첫 승차역이
  바뀌었으면 실시간만 한 번 더 부른다(사용자 동작이므로 "누를 때만" 원칙 안). 고른 서명은 방향별로 저장.

## 7. 계산 규칙

- 출발 시각 = 조회 시각 `now`.
- 승차 열차 = 판단이 "놓침"이 아닌 첫 열차. 두 대 모두 놓치면 둘째 열차 기준으로 예상하되 배너로 알린다.
- 도착 예상 = `now + 열차까지 분 + (첫 지하철 구간 이후 모든 구간 분의 합)`.
- 실시간이 없으면 도착 예상 = `now + ODsay totalTime`, "실시간 없음" 표기.

## 8. 키 · 권한

**키는 아직 없다(2026-10-21).** 구현 계획 첫 단계에 발급 절차를 넣는다. 키가 오기 전에는 공식 문서 예시 응답으로
만든 픽스처로 파서 · 도메인을 먼저 만들고, 키가 오면 실제 응답을 녹화해 픽스처를 바꾸고 §10 항목을 확정한다.

- 서울 열린데이터광장(data.seoul.go.kr): 로그인 → 인증키 신청 → **실시간 지하철 인증키**(일반 키와 별개)
- ODsay LAB(lab.odsay.com): 가입 → 애플리케이션 등록 → 플랫폼 Android, 패키지명 `com.karma.walk`

- 키 2개: `ODSAY_API_KEY` · `SEOUL_SUBWAY_API_KEY`. `apps/walk/config/keys.json`(gitignore) +
  `keys.example.json`(커밋). 실행 · 빌드 명령에 `--dart-define-from-file` 을 붙이도록 walk 문서에 적는다.
- 서울 실시간 API(`swopenapi.seoul.go.kr`)가 http 만 받으면 해당 도메인에 한해 cleartext 를 허용한다
  (`network_security_config.xml`).
- 새 권한 없음(`INTERNET` 은 release 매니페스트에 있는지 확인, 위치 권한은 이미 있다).

## 9. 테스트

- 도메인: `CatchPolicy`(경계값 — 정확히 w+1, 0분, 도보 0분, 두 대 모두 놓침) · 도착 예상 계산 · 경로 서명 · 기본 경로 선택
- 데이터: ODsay · 서울 응답 **실제 json 픽스처**(장승배기 → 강남, 첫 구현 단계에서 녹화) 파서 테스트,
  `arvlMsg2` 변형 파싱, `barvlDt` 0 처리, 노선 코드 · 방향 매핑, 키 없음 · HTTP 오류 · 빈 결과
- cubit: 장소 미설정 → 조회 불가, 조회 성공 · 실시간 실패 시 경로만, 경로 바꾸기 시 실시간 재호출 여부
- 위젯: 판단 배너 3종 · 낡은 결과 표시
- 기기: 실제 폰에서 출근 · 퇴근 각 1회, 네이버 지도와 열차 도착 분 비교

## 10. 위험 · 확인할 것 (구현 계획 첫 단계)

1. **ODsay 키가 안드로이드 앱의 REST 호출에서 동작하는지** — ODsay 키는 플랫폼(서버 IP · 안드로이드 · 웹 URI)별
   등록이다. 막히면 카카오 `publictraffic` 으로 `RouteFinder` 구현을 바꾼다(정류장 ID 가 없어 다음 단계 버스 실시간이 어려워지는 대가).
2. ODsay 무료 한도와 `searchPubTransPathT` 응답 필드(`wayCode` · `startID` · `subwayCode`)를 실제 응답으로 확인.
3. 서울 실시간 API 의 7호선 · 신분당선 `barvlDt` 가 실제로 채워지는지, `updnLine` 과 ODsay `wayCode` 의 대응.
4. 서울 API https 지원 여부(→ §8 cleartext).
5. 안드로이드 `geocoding` 의 한국어 주소 · 건물명("메리츠타워") 검색 품질. 나쁘면 "현재 위치로 지정"을 주 경로로 안내.
