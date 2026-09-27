# walk — 만보기 앱 설계

> 작성 2026-09-27 · 상태: **검토 중** · 앱 문서 [walk 허브](../../../apps/walk/docs/README.md)

## 1. 목적

`apps/walk` 는 셋째 앱이다. 혼자 쓰는 만보기로, **오늘 걸은 걸음 수를 메인 화면에서
바로 보여주고** 주간 · 월간으로 모아서 막대그래프로 보여준다. 로그인 · 백엔드 없음.
안드로이드만 지원한다.

걸음은 앱이 세지 않는다. 폰의 헬스 앱(삼성 헬스 등)이 **Health Connect** 에 기록한 값을
읽기만 한다. 그래서 앱을 한 번도 열지 않은 날도 기록이 있고, 앱 안에 저장소 · 백그라운드
작업이 없다.

## 2. 결정 기록

| 결정 | 이유 |
|---|---|
| 데이터 출처는 Health Connect(`health` 패키지). 센서(`pedometer`) 직접 읽기는 하지 않는다 | 센서는 재부팅 후 누적값만 줘서 날짜별 기록을 앱이 백그라운드로 쌓아야 하고, 앱이 꺼진 구간은 비거나 뭉개진다. Health Connect 는 날짜별 기록을 이미 갖고 있다 |
| 안드로이드만 | 사용자 폰이 안드로이드. iOS(HealthKit)는 `ActivityRepository` 구현 하나를 더하면 된다 |
| 거리 · 칼로리는 **Health Connect 값만** 쓴다. 없으면 `–` 로 두고 계산하지 않는다 | 헬스 앱 숫자와 어긋나는 추정치를 보이지 않는다. 키 · 몸무게 설정 화면이 필요 없다 |
| 칼로리는 **활동 칼로리**(`ACTIVE_ENERGY_BURNED`) | 총 칼로리는 기초대사량을 포함해 하루 2,000kcal 이상이 돼 만보기 숫자로 어색하다. 헬스 앱이 활동 칼로리를 쓰지 않으면 비므로 첫 기기 확인에서 본다(§9) |
| 한 주는 월 ~ 일 | 사용자 확인 |
| 목표 걸음 수 없음 | v1 범위 밖. 막대 높이는 기간 안 최댓값 기준 |
| 앱 이름: 폴더 `apps/walk`, 패키지 `walk`, 표시 이름 "걷기" | 처음 제안한 `health` 는 의존할 pub 패키지 `health` 와 이름이 같아 쓸 수 없다 |
| 30일보다 오래된 기록은 `READ_HEALTH_DATA_HISTORY` 권한을 함께 요청한다 | Health Connect 는 기본적으로 권한을 받은 시점 30일 전까지만 읽게 한다. 거부하면 그 이전 기간은 0으로 보인다 |
| 라우터 없음 | 화면이 하나다. 둘째 화면이 생길 때 `go_router` 를 들인다 |
| 막대그래프는 직접 그린다(`Row` + `Container` 막대) | 막대 · 강조 · 탭 표시만 필요하고 위젯이라 테스트가 쉽다. 모자라면 그때 `fl_chart` |

## 3. 화면

한 화면 `WalkHomePage`(`/`). 위에서부터:

1. **오늘 카드** — 오늘 걸음 수를 크게(`6,240 걸음`), 그 아래 거리(`4.3 km`) · 활동
   칼로리(`182 kcal`). 없는 값은 `–`.
2. **탭** — `주간` · `월간`.
3. **기간 머리** — `‹ 9월 22일 – 28일 ›` / `‹ 2026년 9월 ›`. 이전 기간으로 넘기고, 다음
   화살표는 현재 기간에서 비활성.
4. **막대그래프** — 주간은 요일 7개, 월간은 그 달 날짜 수만큼. 오늘 막대 강조, 오늘
   이후는 빈칸. 막대를 누르면 그래프 위 한 줄에 그날 걸음 수를 표시.
5. **요약** — 기간 합계 걸음 · 일평균 걸음 · 합계 거리 · 합계 칼로리.

동작:

- 앱을 열 때와 백그라운드에서 돌아올 때(`AppLifecycleListener` resumed) 다시 읽는다.
  돌아왔을 때 날짜가 바뀌었으면 "오늘"과 현재 기간도 새 날짜로 옮긴다.
- 당겨서 새로고침.
- **일평균**은 기간 중 오늘까지 지난 날짜 수로 나눈다(미래 날짜 제외).
- **합계 거리 · 칼로리**는 값이 있는 날만 더한다. 기간에 값이 있는 날이 하나도 없으면 `–`.

### 접근 상태 (화면 전체를 대신하는 상태)

| 상태 | 표시 | 동작 |
|---|---|---|
| 확인 중 | 로딩 | — |
| Health Connect 없음 | `AppPlaceholder` "Health Connect 가 필요해요" | 설치하기 → `installHealthConnect()` (플레이스토어) |
| 업데이트 필요 | `AppPlaceholder` "Health Connect 를 업데이트해 주세요" | 업데이트하기 → 같은 호출 |
| 권한 없음 | `AppPlaceholder` "걸음 기록을 읽을 권한이 필요해요" | 권한 허용 → `requestAuthorization`. 다시 거부되면 같은 화면 유지 |
| 준비됨 | 위 화면 | — |

읽기 실패(예외)는 오늘 카드 · 탭 영역 각각에서 `AppPlaceholder` + 재시도.
데이터가 하나도 없는 날은 오류가 아니라 0보다.

## 4. 구조

commute 와 같이 `lib/` 바로 아래가 계층이다. `lib/core/` 는 앱 셸이고 workspace 패키지
`core` 와 별개다.

```
apps/walk/lib/
  main.dart
  core/          app.dart · di/
  domain/        entity/ · repository/ · usecase/
  data/          health/(HealthGateway) · repository/
  presentation/  cubit/ · page/ · widget/ · format/
apps/walk/test/  같은 구조 + convention/
```

의존 패키지: 기존 것은 `core` · `design_system` · `l10n` 만. 새로 `health`.
`feature_*` · `supabase_flutter` 는 쓰지 않는다.

## 5. 도메인 (`domain/`)

| 이름 | 종류 | 내용 |
|---|---|---|
| `DailyActivity` | Freezed 단일 | `date`(자정) · `steps` · `distanceMeters?` · `activeKcal?` |
| `ActivityPeriod` | Freezed 단일 | `kind`(week/month) · `start` · `end`(포함) · `days`(`DailyActivity` 목록, 빈 날은 0보) · 합계 · 일평균 게터 |
| `PeriodKind` | enum | `week` · `month` |
| `HealthAccess` | enum | `notInstalled` · `updateRequired` · `permissionDenied` · `granted` |
| `ActivityRepository` | 인터페이스 | `access()` · `requestAccess()` · `openInstall()` · `dailyActivities(from, to)` → `Result<List<DailyActivity>>` |
| `WalkUseCase` | facade | `access` · `requestAccess` · `openInstall` · `today(now)` · `period(kind, offset, now)` |

기간 계산(`offset` 0 = 이번 주 / 이번 달, -1 = 지난 주 / 지난 달)은 순수 함수로 두고 단위
테스트한다. 주 시작은 월요일.

접근 상태는 실패가 아니라 정상 분기라 `FailureCode` 로 만들지 않고 `HealthAccess` 로
돌려준다. 읽기 실패만 `Err(FailureCode.unknown)`. 그래서 `core` 에 손대지 않는다.

## 6. 데이터 (`data/`)

- `HealthGateway` — `health` 패키지(`Health()` 인스턴스)를 얇게 감싼 인터페이스.
  SDK 상태 · 권한 확인/요청 · 설치 · 기간 집계 읽기. commute 의 `LocationGateway` 와 같은
  이유(mock 가능성)다.
- `HealthConnectActivityRepository` — `HealthGateway` 만 본다.
  - 권한 대상: `STEPS` · `DISTANCE_DELTA` · `ACTIVE_ENERGY_BURNED` (읽기) + 기록 이력 권한.
    걸음 권한이 없으면 `permissionDenied`. 거리 · 칼로리 권한만 없으면 `granted` 로 보고
    그 값만 `null`.
  - 날짜별 합계는 하루 단위 집계로 읽는다. 여러 헬스 앱이 같은 걸음을 기록해도 Health
    Connect 집계가 중복을 걸러 준다(원시 레코드를 더하지 않는 이유).
  - 결과를 `from..to` 모든 날짜로 채운다(기록 없는 날 = 0보, 거리 · 칼로리 `null`).

### 안드로이드 설정

- `minSdk` 26 이상, `MainActivity` 는 `FlutterFragmentActivity` 를 상속.
- `AndroidManifest.xml`: `READ_STEPS` · `READ_DISTANCE` · `READ_ACTIVE_CALORIES_BURNED` ·
  `READ_HEALTH_DATA_HISTORY` 권한, Health Connect 패키지 `<queries>`, 권한 이유
  (`ACTION_SHOW_PERMISSIONS_RATIONALE`) intent-filter 와 `VIEW_PERMISSION_USAGE`
  activity-alias. 이유 intent 는 앱을 그냥 연다 — 권한이 없으면 홈이 무엇을 읽는지 안내한다.

## 7. 표현 (`presentation/`)

| cubit | 상태 | 역할 |
|---|---|---|
| `HealthAccessCubit` | `HealthAccess?`(null = 확인 중) | 시작 · resumed 때 확인, 설치 · 권한 요청 |
| `TodayActivityCubit` | loading / loaded(`DailyActivity`) / failure | 오늘 카드 |
| `PeriodActivityCubit` | offset · loading / loaded(`ActivityPeriod`) / failure | 탭 하나당 하나(kind 고정). 이전 · 다음 · 새로고침. 늦게 온 이전 요청 응답은 버린다 |

cubit 은 DI 에 등록하지 않고 페이지가 `getIt<WalkUseCase>()` 로 만든다. 선택한 막대는
`ActivityBarChart` 의 위젯 상태다.

위젯: `TodayActivityCard` · `PeriodHeader` · `ActivityBarChart` · `PeriodSummary`.
숫자 포맷(`6,240` · `4.3 km` · `–`)은 `format/walk_format.dart` 한 곳.
UI 는 `design_system` 의 위젯 · 토큰만 쓴다(CLAUDE.md 공통 위젯 규칙). 문자열은 commute
처럼 `l10n` ARB 에 `walk` 접두사로 넣는다.

## 8. 테스트

| 계층 | 확인 |
|---|---|
| domain | 기간 계산 — 주 시작 월요일 · 일요일에 연 이번 주 · 월말(28/29/30/31일) · offset 음수. `ActivityPeriod` 합계 · 일평균(미래 제외) · 거리/칼로리 전부 null → null |
| data | `HealthGateway` mock 으로 SDK 상태 → `HealthAccess` 매핑 · 걸음 권한만/전부 거부 · 기록 없는 날 0 채움 · 거리 없을 때 null · 예외 → `Err` |
| presentation | cubit(`bloc_test`) — 접근 상태 전이 · 이전/다음 · 현재 기간에서 다음 불가 · 늦은 응답 무시 · 날짜 바뀐 뒤 resumed. 위젯 — 접근 상태별 `AppPlaceholder` · 오늘 카드 `–` 표시 · 막대 탭 표시 |
| convention | `package_boundary_test` — `feature_*` · `supabase_flutter` 의존 없음 |
| 기기 | 에뮬레이터 + 실제 폰 시나리오(§9) |

## 9. 기기 확인 (구현 첫 단계와 마지막 단계)

**첫 단계 — 실제 폰에서 데이터부터 본다.** 앱 뼈대가 뜨면 사용자 폰에서 걸음 · 거리 ·
활동 칼로리가 Health Connect 에 실제로 있는지 확인한다. 활동 칼로리가 비어 있고 총
칼로리만 있으면 §2 칼로리 결정을 다시 묻는다.

**마지막 단계 — 시나리오.** 에뮬레이터(Health Connect 에 테스트 데이터를 넣어서)와 실제 폰:
① 첫 실행 권한 요청 → 허용 → 오늘 걸음 표시 ② 권한 거부 → 안내 → 재시도
③ 주간 · 월간 탭 전환과 이전 기간 넘기기 ④ 백그라운드 복귀 시 갱신 ⑤ 거리 · 칼로리 없는
날 `–` ⑥ 다크 모드.

## 10. 범위 밖

목표 걸음 수 · 연간 보기 · 알림 · 홈 화면 위젯 · 키/몸무게 기반 추정 · iOS · 걸음을 앱이
직접 세기 · 기록 쓰기.
