# pawlog 통계 설계 — 쌓인 산책을 주 · 월로 돌아본다

> 2026-10-16 작성 · 기획서는 [pawlog 기획서](../../../apps/pawlog/docs/overview.md) · 화면 · 상태 ·
> 문자열 · 완료 조건은 [W6 stats 계획](../../../apps/pawlog/docs/features/stats/plan.md) ·
> 디자인 규칙은 [pawlog 디자인 시스템](../../../apps/pawlog/docs/design.md) · 앱 설계는
> [pawlog 설계](2026-10-03-walk-app-design.md)

## 0. 왜 만드는가

v1(W1~W4)은 산책을 쌓고 한 건씩 돌아보는 데서 끝난다. 기록이 쌓일수록 "이번 주에 얼마나
걸었나", "며칠째 이어 걷고 있나" 가 궁금해지는데, 지금은 피드를 손가락으로 세어야 한다.
기획서 §3 이 v1 밖으로 뺐던 "통계 대시보드" 중 **로컬 데이터만으로 되는 부분**을 W6 stats 로
얹는다. 로그인 · 서버 · 스키마 변경은 없다.

사용자가 고른 범위(2026-10-16):

| 포함 | 제외 (이번에 안 함) |
|---|---|
| 기간 요약 — 이번 주 · 이번 달 총 거리 · 시간 · 횟수, 지난 기간과 비교 | 강아지별 누적 |
| 막대 그래프 — 주 보기 요일별, 월 보기 주별 거리 | 목표 설정 · 달성 표시 |
| 연속 기록 · 최고 기록 — 연속 산책 일수, 최장 연속, 가장 먼 · 가장 오래 걸은 산책 | 달력 히트맵 · 시간대별 분포 · 내보내기 |
| 진입점 — 피드 맨 위 "이번 주" 요약 줄 → 통계 화면 | 앱바 통계 아이콘 · 하단 탭 |

## 1. 계산 방식 — 메모리에서, 순수 함수로

**결정: 이미 있는 `watchWalks()` 스트림을 구독해 Dart 순수 함수(`WalkStatsPolicy`)로 계산한다.**

| 안 | 장점 | 단점 | 판단 |
|---|---|---|---|
| A. 메모리 계산 | 저장소 인터페이스가 그대로. 저장 · 수정 · 삭제가 drift `watch()` 로 바로 반영. 순수 함수라 테스트가 쉽다. 현지 시각 경계를 Dart `DateTime` 으로 자른다 | 산책 전체를 메모리에 올린다 | **채택.** 1인 로컬 앱이라 수천 건까지 비용이 없다. 피드가 이미 전체를 올린다 |
| B. drift SQL 집계 | 데이터가 매우 많아도 빠르다 | 시각이 UTC ISO 텍스트라 현지 주 · 월 경계를 SQL 에서 자르기 번거롭다. `WalkRepository` 에 메서드가 는다 | 지금은 과하다. v2 서버 집계 때 다시 본다 |
| C. 집계 테이블 | 읽기가 가장 싸다 | 스키마 v2 · 갱신 동기화 비용 | YAGNI |

`watchWalks()` 의 `Walk` 는 `startedAt` · `duration` · `distanceMeters` 를 이미 갖고 있어 경로 점
(`walk_points`)을 읽지 않는다.

## 2. 규칙

모든 날짜 계산은 **기기 현지 시각**이다. `Walk.startedAt` 은 `toLocal()` 해서 쓴다.

| 규칙 | 내용 |
|---|---|
| 산책이 속하는 날 | **시작 시각의 현지 날짜.** 23:50 에 시작해 00:20 에 끝난 산책은 시작한 날 하나에만 넣는다(거리 · 시간을 쪼개지 않는다) |
| 주 | **월요일 00:00 시작**, 7일. 로케일과 무관하게 고정(가정 — 바꾸려면 이 줄과 `periodRange` 만 고친다) |
| 월 | 1일 00:00 시작, 다음 달 1일 00:00 전까지 |
| 기간 범위 | 반열린 구간 `[start, end)`. 날짜 더하기는 `DateTime(y, m, d + n)` 으로 해서 서머타임이 있는 지역에서도 자정이 밀리지 않는다 |
| 기간 이동 | `offset` 0 = 지금 기간, -1 = 바로 전 기간 … 미래(`offset > 0`)로는 가지 않는다 |
| 지난 기간 비교 | 바로 전 같은 종류 기간의 **전체** 합과 비교한다(지금 주가 수요일이어도 지난주 7일 전체). 지금 기간 거리가 더 길면 "지난주보다 Δ 더 걸었어요", 아니면 중립 문구 "지난주 n km". 지난 기간이 0 이면 문구를 숨긴다 — 주 초반에 "덜 걸었어요" 를 보이지 않으려는 것 |
| 막대 — 주 | 월 ~ 일 7칸. 칸 = 그날 시작한 산책의 거리 합 |
| 막대 — 월 | 그 달에 걸친 **월요일 시작 주**마다 한 칸(4 ~ 6칸). 첫 · 마지막 칸은 달 범위로 자른다. 예: 2026년 10월(1일이 목요일) → `1–4` · `5–11` · `12–18` · `19–25` · `26–31` |
| 막대 높이 | 그 기간 칸 중 최댓값 기준 비율. 모두 0 이면 바닥선만 |
| 현재 연속 일수 | 산책한 날(하루 1건 이상)을 오늘부터 하루씩 거꾸로 센다. **오늘 산책이 아직 없으면 어제부터 센다** — 아침에 앱을 열었을 때 연속이 0 으로 꺼지지 않게. 어제도 없으면 0 |
| 최장 연속 일수 | 전체 기간에서 산책한 날이 이어진 가장 긴 구간 |
| 가장 먼 · 가장 오래 걸은 산책 | 전체 기간 `distanceMeters` · `duration` 최댓값. 같으면 **최근 것**(피드 순서와 같은 `startedAt` 내림차순 첫 번째) |
| 이전 기간 버튼 | 가장 오래된 산책이 든 기간까지만 간다. 산책이 0건이면 앞뒤 모두 비활성 |
| "지금" | `core` 의 `Clock` 에서 읽는다. 계산할 때마다 다시 읽으므로 화면을 연 채 자정을 넘기면 다음 갱신(스트림 · 기간 이동)에서 새 날짜로 계산한다 |

## 3. 구조

`lib/{domain,presentation}/stats/` 를 새 영역으로 둔다(기획서 §5 의 영역 목록에 `stats` 추가).
데이터 계층은 손대지 않는다.

```
domain/stats/
  entity/stats_period.dart       enum StatsPeriod { week, month }
  entity/period_range.dart       PeriodRange(start, end)               — [start, end)
  entity/period_summary.dart     PeriodSummary(distanceMeters, duration, walkCount)
  entity/stats_bucket.dart       StatsBucket(range, distanceMeters, walkCount)
  entity/period_stats.dart       PeriodStats(period, range, summary, previousSummary, buckets)
  entity/walk_records.dart       WalkRecords(currentStreakDays, longestStreakDays, farthest?, longest?)
  policy/walk_stats_policy.dart  순수 함수 묶음 (아래)

presentation/stats/
  cubit/stats_cubit.dart · stats_state.dart
  page/stats_page.dart
  widget/period_switcher.dart     [주 | 월] 알약 토글 + ‹ 기간 라벨 ›
  widget/period_summary_view.dart 히어로 거리 + 시간 · 횟수 + 비교 문구
  widget/distance_bar_chart.dart  CustomPainter 막대
  widget/walk_records_view.dart   기록 줄글 목록
  format/stats_format.dart        기간 라벨 · 막대 라벨

presentation/feed/widget/week_summary_line.dart   피드 맨 위 요약 줄
```

엔티티는 Freezed 3 primary constructor(단일 불변 모델) 패턴, `WalkRecords.farthest` · `longest` 는
`Walk?` 를 그대로 든다(상세로 갈 `id` 와 날짜를 함께 쓰려고).

`WalkStatsPolicy` (상태 없음, `abstract final class` 정적 메서드):

| 메서드 | 반환 |
|---|---|
| `periodRange(StatsPeriod period, DateTime now, {int offset = 0})` | `PeriodRange` |
| `periodStats(List<Walk> walks, StatsPeriod period, DateTime now, {int offset = 0})` | `PeriodStats` — 요약 · 전 기간 요약 · 칸 |
| `records(List<Walk> walks, DateTime now)` | `WalkRecords` |
| `earliestOffset(List<Walk> walks, StatsPeriod period, DateTime now)` | `int` — 이전 버튼을 끌 기준. 0건이면 0 |

`WalkUseCase` 는 바꾸지 않는다 — cubit 이 `watchWalks()` 를 받아 policy 를 부른다. 정책을 도메인
순수 함수로 두는 선례는 `domain/walk/policy/route_preview.dart` 다.

### 3.1 `StatsCubit`

```dart
@injectable
class StatsCubit extends Cubit<StatsState> {
  StatsCubit(this._useCase, this._clock);
  Future<void> start();          // watchWalks 구독
  Future<void> retry();
  void selectPeriod(StatsPeriod period);  // offset 0 으로 되돌린다
  void showPrevious();           // offset - 1, earliestOffset 아래로는 안 간다
  void showNext();               // offset + 1, 0 위로는 안 간다
}

@freezed
sealed class StatsState with _$StatsState {
  const factory StatsState.loading() = StatsLoading;
  const factory StatsState.loaded({
    required PeriodStats stats,
    required WalkRecords records,
    required int offset,
    required bool canShowPrevious,
    required bool canShowNext,
    required bool isEmpty,          // 산책 0건
  }) = StatsLoaded;
  const factory StatsState.failure(Failure failure) = StatsFailure;
}
```

스트림 값이 올 때마다, 그리고 `selectPeriod` · `showPrevious` · `showNext` 마다 마지막 `walks` 로
다시 계산해 `loaded` 를 낸다. 구독 · 취소는 `WalkFeedCubit` 과 같은 방식(취소를 기다리지 않음 —
위젯 테스트의 가짜 비동기)을 따른다.

### 3.2 피드 요약 줄

`WalkFeedCubit` 이 `Clock` 을 함께 받아, `_onWalks` 에서
`WalkStatsPolicy.periodStats(walks, week, now).summary` 를 계산해 `WalkFeedLoaded.weekSummary` 로
싣는다. 별도 cubit · 스트림을 두지 않는다. `WalkFeedPage` 에 `onOpenStats` 콜백을 더하고, 앱 셸이
`push(PawlogPaths.stats)` 로 잇는다. 페이지는 경로를 모른다(기존 콜백 규칙).

### 3.3 라우팅

`PawlogPaths.stats = '/stats'`, 최상위 `GoRoute`. `StatsPage({onOpenWalk})` → 앱 셸이
`push(PawlogPaths.walk(id))`. 반려견 0마리면 다른 경로처럼 `DogsRedirect` 가 등록 화면으로 보낸다.

## 4. 화면 디자인

[디자인 시스템](../../../apps/pawlog/docs/design.md)을 따른다. 통계 화면은 **Read** 표면이다.

- 앱바 제목은 고운돋움 `title`. 바탕 `paper`, 구분은 `rule` 1px 선. 카드 · 그림자 없음
- 상단: 알약 토글 `[주 | 월]`(선택 칸 `primary` 바탕 · `on-primary` 글자) 아래 `‹ 라벨 ›` 한 줄.
  비활성 화살표는 투명도 0.4(주 버튼 비활성 규칙과 같은 값)
- 요약: 거리 `number-hero`(44) 한 개 + 그 아래 시간 · 횟수 `number`(20) 둘. 라벨은 `label` muted.
  비교 문구는 `body` muted 한 줄
- 막대: `primary` 막대, 막대 위 모서리는 폭이 좁아 `photo`(4). 0 인 칸은 `rule` 바닥선만. 칸 아래
  라벨(요일 또는 `1–4`) `label` muted. **연두는 쓰지 않는다**(연두는 경로 · 진행 중 · 목표 달성
  전용이고, 목표는 이번 범위가 아니다). 막대를 탭하면 그 칸 위에 거리 값이 `label` 로 뜨고, 다른
  칸을 탭하면 옮겨 가고 같은 칸을 다시 탭하면 사라진다. 칸마다 `Semantics(label: '<칸 라벨> <거리>')`
- 기록: 제목 `title` + 네 줄 줄글(`label` 이름 · `number` 값). 가장 먼 · 오래 걸은 산책 줄은 날짜를
  덧붙이고 탭하면 상세. 산책이 없으면 기록 절을 숨긴다
- 산책 0건: 요약 · 막대 · 기록 대신 `AppPlaceholder` 한 장(행동 버튼 없음 — 시작은 피드에서)
- 피드 요약 줄: 타임라인 위, 배너 아래. `body` 텍스트 + 끝에 `chevron_right`, 글자는 `primary`
  (누를 수 있는 것은 남색). 이번 주 0건이면 "이번 주는 아직 산책 전이에요". 피드가 빈 상태(산책
  0건)면 줄 자체를 숨긴다
- 모션: 기간 · 토글 전환은 `PawlogMotion` 상태 전환(200ms) 크로스페이드 하나. 막대가 자라는
  연출은 하지 않는다 — 앱의 연출은 경로 그리기 하나에 몰아준다는 규칙. 애니메이션 줄이기면 바로 바꾼다

## 5. 오류 · 경계

| 경우 | 처리 |
|---|---|
| `watchWalks()` 가 `Err` | `failure` → `AppPlaceholder` + 다시 시도(피드와 같은 문구 · 동작) |
| 산책 0건 | `loaded(isEmpty: true)` → 빈 안내. 피드 요약 줄 숨김 |
| 산책 저장 · 삭제 · 수정 | drift `watch()` 로 다시 계산. 최고 기록 산책을 지우면 다음 것으로 바뀐다 |
| 보고 있던 과거 기간이 삭제로 `earliestOffset` 보다 앞이 됨 | `offset` 을 `earliestOffset` 으로 끌어올린다 |
| 거리 0 m 산책(GPS 가 안 잡힌 짧은 산책) | 횟수 · 시간 · 연속 일수에는 넣고 거리 합에는 0 으로 들어간다 |
| 다국어 | 요일 · 기간 라벨은 `intl` `DateFormat` 을 로케일로 만든다. 문자열은 `l10n` ARB 3개(ko 템플릿 + en · ja), 키는 `walkStats*` · `walkFeedWeekSummary*` |

## 6. 테스트

| 층 | 대상 | 확인 |
|---|---|---|
| 단위 | `WalkStatsPolicy` | 주 · 월 경계(월요일 00:00, 일요일 23:59, 말일), 자정을 넘긴 산책, 월 칸 수(4 · 5 · 6), 전 기간 요약, 연속 일수(오늘 있음 · 오늘 없고 어제 있음 · 끊김 · 0건), 최장 연속, 최고 기록 동률, `earliestOffset` |
| 단위 | `StatsCubit` | 첫 값 → `loaded`, 토글 시 offset 0, 이전 · 다음 한계, 스트림 갱신 반영, 삭제로 offset 끌어올림, `Err` → `failure` → `retry` |
| 단위 | `WalkFeedCubit` | `weekSummary` 가 `FakeClock` 기준으로 계산된다 |
| 위젯 | `StatsPage` | 요약 숫자 · 비교 문구 노출 규칙, 막대 탭 값 표시, 기록 탭 → `onOpenWalk`, 빈 상태, 다크 테마 |
| 위젯 | `WeekSummaryLine` · `WalkFeedPage` | 줄 노출 · 0건 문구 · 빈 피드에서 숨김 · 탭 → `onOpenStats` |
| 라우터 | `app_router` | `/stats` 진입, 반려견 0마리 리다이렉트 |
| 에뮬레이터 | [W6 계획 완료 조건](../../../apps/pawlog/docs/features/stats/plan.md#완료-조건) | 저장 직후 요약 줄 · 통계 갱신, 주 · 월 전환, 다크 |

## 7. 단계 커밋

| # | 커밋 | 범위 |
|---|---|---|
| ① | `feat(pawlog): 산책 통계 계산 정책을 추가한다` | `domain/stats` 엔티티 · `WalkStatsPolicy` + 단위 테스트 |
| ② | `feat(l10n): 산책 통계 문자열을 추가한다` | ARB 3개 |
| ③ | `feat(pawlog): 주 · 월 산책 통계 화면을 추가한다` | `StatsCubit` · `StatsPage` · 위젯 · `/stats` 경로 + 테스트 |
| ④ | `feat(pawlog): 피드 맨 위에 이번 주 요약 줄을 둔다` | `WalkFeedCubit.weekSummary` · `WeekSummaryLine` · `onOpenStats` + 테스트 |
| ⑤ | `docs(pawlog): …` | stats `history.md` · `testing.md`, 진행 현황, 허브 행, 기획서 §3 · §5 |
