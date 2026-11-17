# walk — 대중교통 길찾기 설계

> 작성 2026-11-17 · 상태: **기획 — 사용자 승인 대기** · 앱 문서 [walk 허브](../../../apps/walk/docs/README.md) ·
> 이전 설계 [통근 ETA](2026-10-21-commute-eta-design.md)

## 1. 목적

Life Log 도구 탭에서 네이버지도 길찾기처럼 출발지 · 도착지를 고르면 대중교통 경로와 소요 시간을 본다.
개인 앱이고 무료로 쓴다(ODsay 무료 플랜). 예전 통근 탭(집 ↔ 회사, 지하철만, 실시간 판단)을 되살리되
**임의 출발 · 도착, 버스 포함, 환승 포함**으로 넓힌다.

성공: 자주 가는 두 곳 사이 경로를 세 번 이하 터치로 보고, 경로마다 총 시간 · 환승 횟수 · 도보 시간이
한눈에 비교되며, 구간별 노선 · 정류장을 펼쳐 볼 수 있다.

## 2. 범위

**한다**

- 도구 탭 넷째 상단 탭 **길찾기**
- 출발 · 도착 고르기: 현재 위치 · 집/회사 · 자주 간 곳 · 최근 · 역/정류장 검색(ODsay) · 주소 검색(기존 `geocoding`)
- ODsay `searchPubTransPathT` 로 경로(지하철 · 버스 · 지하철+버스) — 총 소요 시간순 정렬
- 결과 목록(총 시간 · 환승 · 도보 · 요금 · 노선 칩) · 상세(구간별 노선 · 승하차 · 정거장 수 · 도보)
- 같은 출발 · 도착 결과 캐시 · 역 검색 캐시(하루 한도 아끼기)
- ODsay 키를 앱 안에서 입력(물어보기 키와 같은 UX), 보안 저장소, 백업 제외
- 전국(ODsay 가 기본 전국 — 좁혀도 아낄 게 없다, 내 판단)

**안 한다**

- 서울 실시간 지하철 도착 · "탈 수 있나" 판단 · 도착 예상(통근 기능). 코드는 남긴다(§4)
- 카카오 · 네이버 장소 검색(추가 키 없음 — 사용자 결정), 상호 이름 검색
- 출발 시각 지정 · 막차 · 실시간 버스 위치 · 지도 위 경로 그리기
- 도보 · 자동차 · 자전거 길찾기

**실패로 보는 것(안티 골)**: 하루 한도를 입력 몇 번에 다 써 버림 · 키가 있는데 APK 에서 사라짐 ·
키 거부를 "경로 없음"으로 보여 원인을 모름 · 360dp 폰에서 상단 탭 라벨이 잘림.

## 3. 결정 기록

| 결정 | 근거 |
|---|---|
| 경로 API 는 ODsay 무료 플랜 | 사용자 결정(위키 기획) |
| 장소 이름 검색은 ODsay `searchStation`(역 · 정류장만) | 사용자 결정 2026-11-17 — "역이랑 정류장만 검색해도 될듯". 추가 키 없음 |
| ODsay 키는 앱 안에서 입력 · 보안 저장소 · 마스킹 · 연결 확인 · 백업 제외 | 사용자 결정 2026-11-17 — "클로드 API키처럼 … 입력하도록". 빌드 옵션을 빠뜨리면 APK 에서 키가 빠지던 문제도 없앤다 |
| `--dart-define` 키(`ODSAY_API_KEY`)는 **개발용 기본값**으로만: 저장된 키가 없고 define 이 있으면 그걸 쓴다 | 에뮬레이터 개발 편의. 실사용 APK 는 define 없이 빌드해도 된다 (내 판단) |
| 지원 지역 전국 | ODsay 가 기본 전국. 수도권 제한은 이득 없음 (내 판단) |
| 도구 상단 탭 4개는 **고정 탭 + 아이콘 위 짧은 라벨** | §6.1 비교 (내 판단, 에뮬레이터 스크린샷으로 확인) |
| 기능 폴더 이름은 `transit`, 통근 폴더 `commute` 는 그대로 두고 재사용 부분만 옮긴다 | §4 (내 판단) |

## 4. 기존 통근 코드 진단

| 코드 | 처리 |
|---|---|
| `OdsayRouteFinder` 호출 · 오류 분류(네트워크 · TLS · 비 2xx · 해석 실패 · 경로 없음 코드) | **옮겨 넓힌다** → `data/transit/odsay_transit_client.dart`. 버스(`trafficType 2`) 구간을 버리지 않고 해석, `info.payment` · 정류장 이름 · 버스 번호 추가, 키 거부 코드를 따로 분류 |
| `TransitRoute` · `RouteLeg`(walk · subway) | **새 엔티티로 대체** — `transit/entity/transit_path.dart` 에 `walk · subway · bus` 구간. 통근 엔티티는 실시간 판단 필드(`wayCode` · `odsayLaneCode`)에 묶여 있어 그대로 두고 쓰지 않는다 |
| `CommuteFailure` | `TransitFailure`(아래 §5) 새로. `keyRejected` · `quotaExceeded` 를 더한다 |
| `Place` · `PrefsPlaceRepository`(집/회사) | **재사용** — 같은 저장 키(`commute.place.home/work`)를 읽어 길찾기의 집 · 회사 후보로 쓴다. 이미 설정한 값이 있으면 이어진다 |
| `GeocodingAddressSearch` · `AddressSearch` | **재사용**(주소 검색) |
| `PlaceSetupSheet` 의 "현재 위치로 정하기" 흐름 | 위치 얻는 부분만 참고, 시트는 새로 |
| 서울 실시간 · `commute_policy` · `CommuteCubit` · `CommuteTab` · 위젯 · `CommuteApiKeys` 의 서울 키 | **쓰지 않음**. 삭제는 이번 범위가 아니다 — 후속 정리 후보로 status 에 남긴다 |
| `CommuteApiKeys.fromEnvironment` | ODsay 키 기본값 읽기로만 쓴다(§8) |

## 5. 구조 · 데이터

`lib/{domain,data,presentation}/transit/` (계층 규칙은 [architecture](../../architecture.md) · walk 관례 그대로).

**도메인**

- `TransitPoint` — `{lat, lng, label, source}`. `source`: `currentLocation · home · work · frequent · recent · station · address`
- `TransitPath` — `{totalMinutes, transferCount, walkMinutes, fare?, legs}`. `walkMinutes` 는 도보 구간 합
- `TransitLeg` (sealed) — `walk(minutes, distanceM)` · `subway(minutes, lineName, lineColorKey, start, end, stationCount, way)` ·
  `bus(minutes, busNumbers[], start, end, stationCount)` (같은 구간을 여러 버스가 다니면 번호 여럿)
- `StationHit` — `{name, kind: subway|bus, lat, lng, detail}`(detail: 노선 이름 또는 `arsID` · 구 이름)
- `TransitFailure` (sealed) — `missingKey · keyRejected(message) · quotaExceeded · network · noRoute · tooClose · server(message)`
- 인터페이스: `TransitRouteSource.find(from, to)` · `StationSearch.search(query)` · `TransitKeyStore`(read · save · delete · status)
- 유스케이스 `FindTransitRoutes` — 캐시 확인 → 소스 호출 → **총 소요 시간 오름차순, 같으면 환승 적은 순, 그다음 도보 적은 순** 정렬

**캐시** (`TransitCache`, 메모리 + shared_preferences)

- 경로: 키 = 출발 · 도착 좌표를 소수 넷째 자리(약 10m)로 반올림한 쌍. **10분** 유지. 결과 화면에 "n분 전 결과 · 새로고침" 표시, 새로고침은 캐시를 건너뛴다
- 역 검색: 키 = 정규화한 검색어. **7일** 유지(역 이름은 거의 안 바뀐다), 최대 100개
- 최근 장소: 고른 출발 · 도착 최근 10개(shared_preferences `transit.recent`) — 다시 검색할 일을 줄인다
- 캐시 · 최근은 백업 허용 목록에 넣지 않는다(캐시는 버려도 되는 값, 최근은 기기마다 다를 수 있음 — 내 판단)

**역 · 정류장 검색 호출 아끼기**: 2글자 이상 · 입력 멈춘 뒤 **500ms** 디바운스 · 같은 검색어는 캐시 ·
조합 중인 한글(IME composing)일 때는 보내지 않는다. 결과는 지하철역 먼저, 그다음 정류장, 최대 20개.

**ODsay 호출** (둘 다 GET, `apiKey` 쿼리)

- `searchPubTransPathT?SX&SY&EX&EY&SearchPathType=0`(0 = 지하철+버스 모두)
- `searchStation?stationName=…&stationClass=1,2`
- 오류 분류: 키 인증 실패(`ApiKeyAuthFailed` 류 메시지 · 코드) → `keyRejected` · 한도 초과 → `quotaExceeded` ·
  `-98/-99/3/4/5/6` → `noRoute`(가까움 코드는 `tooClose`) · 나머지 → `server`. 실제 코드 · 문구는 실키로 녹화해 확정한다(§9)

## 6. 화면 · 흐름

### 6.1 도구 상단 탭 4개

| 안 | 장점 | 단점 |
|---|---|---|
| **A. 고정 탭 + 아이콘 위 라벨**(`Tab(icon, text)`) | 네 개가 한 번에 보임, 지금 구조 그대로 | 탭 높이가 72dp 로 커짐 |
| B. 스크롤 탭(`isScrollable`) | 라벨 길어도 안 잘림 | 넷째가 화면 밖으로 밀릴 수 있어 있는지 모름 |
| C. 아이콘만 세그먼트 | 가장 좁음 | 무슨 도구인지 아이콘만으로 모호(걷기 · 길찾기) |
| D. 도구 첫 화면 카드 그리드 | 도구가 더 늘어도 됨 | 알람까지 한 단계 더, 위젯 진입 · 상단 탭 기억 다시 짜야 함 |

**기본안 A.** 라벨은 알람 · 걷기 · 날씨 · 길찾기(최대 3자, 영어 Alarm · Walk · Weather · Transit). 360dp 폭에서
탭 하나가 90dp 이고, 큰 글씨(textScale 1.3)에서도 "길찾기"는 들어간다. 라벨은 한 줄 · 말줄임 없이
`FittedBox(scaleDown)` 로 넘칠 때만 줄인다. 탭 높이가 늘어 생기는 세로 손실은 아이콘 크기 20 으로 줄인다.
에뮬레이터 360×640 · 기본 글씨 / 가장 큰 글씨 스크린샷 두 장으로 확인한다. 안 들어가면 B 로 바꾼다.

### 6.2 길찾기 화면

```
┌ 도구 앱바 ─────────────── ⋮ ┐   ⋮: 길찾기 키 설정 · 앱 설정
│ 알람  걷기  날씨  [길찾기]   │
├──────────────────────────────┤
│ ● 출발  현재 위치          ⇅ │   ⇅ 출발 · 도착 바꾸기
│ ● 도착  회사                 │
│ [집] [회사] [헬스장] [최근…] │   빠른 칩: 집 · 회사 · 자주 간 곳 상위 3
├──────────────────────────────┤
│ 3분 전 결과 · 새로고침       │
│ 42분   환승 1 · 도보 9분 · 1,500원 │
│ [7] ─ [신분당]               │   노선 칩(지하철 색 · 버스 번호)
│ 47분   환승 0 · 도보 14분     │
│ [740]                        │
└──────────────────────────────┘
```

- 출발 · 도착이 다 차면 자동 조회한다(같은 쌍은 캐시). 기본 출발은 현재 위치, 도착은 비어 있음
- 빠른 칩을 누르면 **비어 있는 칸**(없으면 도착)을 채운다
- 상태: 키 없음(`AppPlaceholder` + [키 입력] → 키 설정) · 위치 권한 없음/실패(출발 칸 안에 안내) · 조회 중(`AppLoading`) ·
  경로 없음 · 너무 가까움("걸어서 가는 거리") · 키 거부("ODsay 가 키를 받지 않았어요" + 원문 메시지 + [키 설정]) ·
  한도 초과("오늘 무료 한도를 다 썼어요") · 네트워크 · 서버 오류(원문) — 모두 `AppPlaceholder`

### 6.3 장소 고르기 화면(출발 · 도착 칸을 누르면 전체 화면)

```
[← ] [역 · 정류장 · 주소 검색      ]
 ◎ 현재 위치
 ⌂ 집 · 회사          (없으면 "집 정하기")
 ★ 자주 간 곳 (최근 30일 상위 5, 이름은 기존 PlaceNamer)
 ↺ 최근
── 검색 결과 ──
 🚇 강남역  2호선 · 신분당선
 🚌 강남역.강남CGV  23-123
 📍 주소로 찾기: "강남대로 396"   (역 결과가 없거나 맨 아래 한 줄)
```

- 자주 간 곳: 위치 기록의 머문 곳 → `frequentPlaces` (지도와 같은 계산). 위치 기록이 꺼져 있으면 섹션 숨김
- 집 · 회사 길게 누르기 → "지금 고른 곳을 집/회사로" 저장(기존 저장 키)
- 주소 검색은 사용자가 그 줄을 눌렀을 때만 돈다(ODsay 한도와 무관)

### 6.4 경로 상세(결과 행을 누르면)

맨 위에 총 시간 · 환승 · 도보 · 요금, 아래에 구간을 세로 타임라인으로:
`도보 5분(320m)` → `7호선 장승배기 → 고속터미널 · 6개 역 · 12분 · 온수 방면` → `환승 도보 3분` → … 버스는 번호들 · 정류장 · 정거장 수.

## 7. 키 설정

물어보기 키 UX(`chat_settings_page`)를 본뜬 **길찾기 설정** 화면(`transit_settings_page`):

- 키 입력(가림 · 붙여넣기) → 저장 전 확인 호출 1회(`searchStation?stationName=서울역`) → 성공이면 저장 · "연결됨",
  키 거부면 저장하지 않고 원문 오류를 보인다. 네트워크 실패면 "확인 못 함 — 그래도 저장" 선택
- 저장된 키는 앞 4자 · 뒤 4자만 보이게 마스킹, [삭제]
- 상태 줄: 연결됨 / 확인 안 됨 / 거부됨(마지막 호출 결과로 갱신)
- 보안 저장소 `flutter_secure_storage`, 키 이름 `transit.odsay_key`. 백업 허용 목록에 넣지 않고, 복원 뒤 키가 없으면
  기존 `RestoreNotice` 처럼 "길찾기 키를 다시 넣어 주세요"를 더한다
- 진입점: 길찾기 화면 ⋮ · 키 없음 안내 버튼 · 앱 설정(`app_settings_page`)의 한 줄. main 은 그사이 하단 설정 탭을 없앴으므로(`51728262`) 구현 전 최신 main 을 받아 그때의 앱 설정 진입에 한 줄만 더한다
- 안내 문구에 발급처 링크(lab.odsay.com), "Android · 패키지 com.karma.walk 로 등록한 키"

## 8. 키 출처 순서

`보안 저장소 키` → 없으면 `String.fromEnvironment('ODSAY_API_KEY')`(개발용) → 없으면 `missingKey`.
README 의 통근 키 절차를 "길찾기 키"로 바꾸고, 실사용 APK 는 define 없이 빌드해 앱에서 입력하는 것을 기본으로 적는다.

## 9. 위험 · 확인할 것

1. **Android 플랫폼 키가 Dart `http` 호출에서 통하는지 미확인.** ODsay 의 Android 키 검증 방식(패키지 · 서명)과 일반
   REST 호출이 맞지 않으면 거부된다. 거부되면 `keyRejected` 로 원문을 보이고, 사용자는 ODsay 에 **서버(IP) · 웹(URI) 키**를
   추가 발급해 넣어 본다. 그래도 안 되면 후속으로 카카오 `publictraffic` 등 대안을 다시 기획(이번 범위 밖)
2. 무료 플랜 하루 한도와 한도 초과 응답 형식 — 실키로 확인 후 `quotaExceeded` 분류 확정
3. `searchStation` 응답 필드(`stationClass` · `x/y` · `laneName` · `arsID`) — 문서 기준 픽스처로 먼저 만들고 실응답으로 교체
4. testing 문서 기기 시나리오(사용자 몫 포함): 키 입력 → 연결 확인 결과 → 역 검색 → 경로 조회 → 상세 → 새로고침 →
   비행기 모드 → 키 삭제 후 안내. 거부되면 화면의 오류 원문을 그대로 알려 주기

## 10. 테스트

- ODsay · 위치 · 시계 · 보안 저장소는 가짜. 픽스처 `test/fixtures/transit/*.json`(문서 기준 수작업 → 실응답 교체)
- 도메인: 정렬 규칙 · 도보 합 · 캐시 키 반올림 · 만료 · 최근 10개
- 데이터: 경로 파싱(지하철 · 버스 · 혼합 · 여러 버스 번호 · 요금 없음) · 오류 분류(키 거부 · 한도 · 경로 없음 · 가까움 · 네트워크 · 비 2xx · 해석 실패) · 역 검색 파싱 · 키 저장소 출처 순서
- 화면: 상태별 화면 · 빠른 칩 채우기 · 바꾸기 · 디바운스(가짜 시계, 500ms 안 재입력은 1회 호출) · 2글자 미만 호출 없음 · 키 설정 확인 흐름 · 도구 탭 4개(360dp · textScale 1.3 에서 overflow 없음 위젯 테스트)
- 백업: 허용 목록에 키 · 캐시가 없음

## 11. 검토에서 정한 것 (내 판단)

- **실키 확인은 구현 뒤.** 키 값은 사용자만 갖고 앱에서 직접 넣는다. 구현은 가짜로 끝내고, Android 키 거부 여부는 사용자가
  기기에서 §9-4 시나리오로 확인한다. 거부되면 서버 · 웹 키로 바꿔 넣어 보는데, 그 키들은 쿼리 `apiKey` 만으로 동작하는 방식이라
  헤더 추가 없이 같은 코드로 시도할 수 있다. 그래도 안 되면 대안 기획은 후속
- **통근 코드는 새 키 저장소를 읽지 않는다.** 화면에서 닿지 않는 코드라 건드리지 않는다
- **좌표:** `searchStation` 은 `x/y`, 기존 주소 검색 `PlaceCandidate` 는 `lat/lng` 를 준다 — 별도 지오코딩 없음
- **복원 안내:** `RestoreNotice` 는 enum 이라 `transitKeyNeeded` 값 하나와 문구만 더한다
- **소요 시간 표시:** ODsay `totalTime` 을 그대로 쓰고, 목록 위에 "환승 · 배차 대기 시간은 빠질 수 있어요" 한 줄을 둔다.
  정렬은 §5 규칙(총 시간 → 환승 → 도보)만, `pathType` 은 노선 칩 아이콘에만 쓴다

## 12. 빌더에게 남기는 것

위젯 세부 배치 · 문구 · 노선 색 매핑 표 · l10n 키 이름 · cubit 분할(화면 cubit 하나 + 장소 고르기 cubit 하나 권장)은 구현하면서 정한다.
