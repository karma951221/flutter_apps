# W6 stats — 계획 (화면 · 상태 · 완료 조건)

> [pawlog 허브](../../README.md) · [기획 §5](../../overview.md#5-feature-분해) · [구현 기록](history.md) · [테스트](testing.md) · [설계](../../../../../docs/superpowers/specs/2026-10-16-pawlog-stats-design.md) · [디자인 시스템](../../design.md)

> 상태: 구현 완료 2026-10-16 (`ab5e10a`) · 에뮬레이터 일부(GPS 없이 0 m 산책으로) · 진행 상태의 단일 기준은 [진행 현황](../../status.md)

## 범위

쌓인 산책을 **주 · 월 단위로 돌아보는 통계 화면**과, 피드 맨 위의 **"이번 주" 요약 줄**이다.
기간 요약(거리 · 시간 · 횟수 + 지난 기간 비교), 거리 막대 그래프, 연속 · 최고 기록을 보인다.
계산 규칙(주 시작 · 자정 넘긴 산책 · 연속 일수 · 동률)과 구조는 [설계](../../../../../docs/superpowers/specs/2026-10-16-pawlog-stats-design.md)
§2 · §3 이 기준이다. 강아지별 누적 · 목표 · 달력 히트맵은 범위 밖이다.

| 이미 있는 것 (W6 가 쓰기만 한다) | 위치 |
|---|---|
| `watchWalks()` — `started_at` 내림차순, drift `watch()` 로 저장 · 수정 · 삭제가 흐른다 | `WalkUseCase` |
| `Walk(startedAt, duration, distanceMeters, …)` | `lib/domain/walk/entity/walk.dart` |
| `WalkFormat.distance` · `WalkFormat.duration` | `lib/presentation/walk/format/walk_format.dart` |
| `Clock` · `FakeClock` | `packages/core` |
| `AppPlaceholder` | `design_system` |
| `PawlogColors` · `PawlogTextStyles` · `PawlogSpacing` · `PawlogRadius` · `PawlogMotion` | `lib/presentation/theme/` |

스키마 · 저장소 · `WalkUseCase` 는 바꾸지 않는다.

## 화면 목록

| 화면 | 경로 | 진입 경로 |
|---|---|---|
| 통계 `StatsPage` | `/stats` | 피드 요약 줄 탭 |
| 피드 요약 줄 `WeekSummaryLine` | `/` 안 | 산책이 1건 이상일 때 타임라인 맨 위(배너 아래) |

콜백: `StatsPage({onOpenWalk(id)})` → 앱 셸 `push(PawlogPaths.walk(id))`.
`WalkFeedPage` 에 `onOpenStats` 를 더하고 앱 셸이 `push(PawlogPaths.stats)` 로 잇는다.

## 화면 상태 — `StatsState` (sealed)

| 상태 | 조건 | UI |
|---|---|---|
| `loading` | `start()` 직후 첫 `watchWalks` 값 전 | 중앙 진행 표시 |
| `loaded(isEmpty: true, …)` | 스트림 `Ok([])` | 토글 · 기간 줄 없이 `AppPlaceholder(message: walkStatsEmptyTitle, description: walkStatsEmptyMessage)` |
| `loaded(stats, records, offset, canShowPrevious, canShowNext, isEmpty: false)` | 스트림 `Ok` 1건 이상 | 토글 `[주 \| 월]` · `‹ 기간 라벨 ›` · 요약 · 막대 · 기록 |
| `failure(failure)` | 스트림 `Err` | `AppPlaceholder(message: failure.localizedMessage(context), actionLabel: commonRetry, onAction: retry)` |

| 동작 | 결과 |
|---|---|
| 토글 `주` / `월` | `selectPeriod` — `offset` 0 으로 |
| `‹` | `showPrevious` — 가장 오래된 산책이 든 기간까지. 거기서 비활성(투명도 0.4) |
| `›` | `showNext` — 지금 기간(`offset` 0)에서 비활성 |
| 막대 탭 | 그 칸 위에 거리 값. 다른 칸 탭 → 옮김, 같은 칸 다시 탭 → 숨김. 기간 · 토글이 바뀌면 숨김 |
| 기록 "가장 먼 산책" · "가장 오래 걸은 산책" 탭 | `onOpenWalk(id)` |

`WalkFeedState.loaded` 에 `weekSummary: PeriodSummary` 를 더한다(`WalkFeedCubit` 이 `Clock` 으로 계산).

## 화면 구성

| 영역 | 내용 |
|---|---|
| 앱바 | 제목 `walkStatsTitle` |
| 기간 | 알약 토글(`walkStatsWeek` · `walkStatsMonth`) 아래 `‹ 라벨 ›`. 주 라벨: 같은 해 `10월 13일 – 19일`, 달이 걸치면 `9월 29일 – 10월 5일`, 다른 해면 연도 붙임. 월 라벨 `2026년 10월` (`intl` `DateFormat`, 로케일별) |
| 요약 | 거리 히어로(44) + 라벨 `walkStatsDistanceLabel` · 시간(`walkStatsDurationLabel`) · 횟수(`walkStatsCountLabel`, 값 `walkStatsCountValue`). 비교 문구 한 줄 |
| 막대 | 주 7칸(요일 `DateFormat.E`) · 월 4~6칸(`1–4` 처럼 일 범위). 탭 값 · `Semantics` 는 `walkStatsBarSemantics` |
| 기록 | 제목 `walkStatsRecordsTitle`. `walkStatsCurrentStreak` · `walkStatsLongestStreak`(값 `walkStatsDays`) · `walkStatsFarthestWalk` · `walkStatsLongestWalk`(값 + 날짜, 탭 → 상세) |
| 피드 요약 줄 | 이번 주 1건 이상 `walkFeedWeekSummary`, 0건 `walkFeedWeekSummaryEmpty`. 끝에 `chevron_right`, 남색 |

비교 문구: 지난 기간 거리 0 → 숨김. 지금 > 지난 → `walkStatsMoreThanLastWeek` / `walkStatsMoreThanLastMonth`.
그 밖 → `walkStatsLastWeek` / `walkStatsLastMonth`.

## 문자열 (ko 템플릿 · en · ja)

| 키 | ko | en | ja |
|---|---|---|---|
| `walkStatsTitle` | 산책 통계 | Walk stats | 散歩の記録 |
| `walkStatsWeek` | 주 | Week | 週 |
| `walkStatsMonth` | 월 | Month | 月 |
| `walkStatsPreviousTooltip` | 이전 기간 | Previous | 前の期間 |
| `walkStatsNextTooltip` | 다음 기간 | Next | 次の期間 |
| `walkStatsDistanceLabel` | 걸은 거리 | Distance | 距離 |
| `walkStatsDurationLabel` | 걸은 시간 | Time | 時間 |
| `walkStatsCountLabel` | 산책 | Walks | 散歩 |
| `walkStatsCountValue` `{count}` | {count}번 | {count, plural, =1{1 walk} other{{count} walks}} | {count}回 |
| `walkStatsMoreThanLastWeek` `{distance}` | 지난주보다 {distance} 더 걸었어요 | {distance} more than last week | 先週より{distance}多く歩きました |
| `walkStatsLastWeek` `{distance}` | 지난주 {distance} | Last week {distance} | 先週 {distance} |
| `walkStatsMoreThanLastMonth` `{distance}` | 지난달보다 {distance} 더 걸었어요 | {distance} more than last month | 先月より{distance}多く歩きました |
| `walkStatsLastMonth` `{distance}` | 지난달 {distance} | Last month {distance} | 先月 {distance} |
| `walkStatsBarSemantics` `{label}` `{distance}` | {label} {distance} | {label} {distance} | {label} {distance} |
| `walkStatsRecordsTitle` | 기록 | Records | 記録 |
| `walkStatsCurrentStreak` | 연속 산책 | Current streak | 連続散歩 |
| `walkStatsLongestStreak` | 최장 연속 | Longest streak | 最長連続 |
| `walkStatsDays` `{count}` | {count}일 | {count, plural, =1{1 day} other{{count} days}} | {count}日 |
| `walkStatsFarthestWalk` | 가장 먼 산책 | Farthest walk | いちばん遠い散歩 |
| `walkStatsLongestWalk` | 가장 오래 걸은 산책 | Longest walk | いちばん長い散歩 |
| `walkStatsEmptyTitle` | 아직 통계가 없어요 | No stats yet | まだ記録がありません |
| `walkStatsEmptyMessage` | 산책을 기록하면 여기에 쌓여요 | Your walks will add up here | 散歩を記録するとここに積み上がります |
| `walkFeedWeekSummary` `{distance}` `{count}` | 이번 주 {distance} · {count}번 | This week {distance} · {count, plural, =1{1 walk} other{{count} walks}} | 今週 {distance}・{count}回 |
| `walkFeedWeekSummaryEmpty` | 이번 주는 아직 산책 전이에요 | No walks yet this week | 今週はまだ散歩していません |

모든 키에 `@` 설명을 단다.

## 완료 조건

- [ ] `WalkStatsPolicy` 단위 테스트 — 설계 §6 의 경계 전부
- [ ] `StatsCubit` · `WalkFeedCubit.weekSummary` 테스트
- [ ] `StatsPage` · `WeekSummaryLine` 위젯 테스트(라이트 · 다크), 라우터 `/stats`
- [ ] `flutter analyze` 0건 · `flutter test`(`apps/pawlog` · `packages/l10n`) 통과 · `flutter build apk --debug`
- [ ] 화면에 `Colors.*` · 숫자 여백 · `BorderRadius.circular(n)` 없음(테마 토큰만)
- [ ] 에뮬레이터:
  1. 산책 저장 직후 피드 요약 줄의 거리 · 횟수가 바로 바뀐다
  2. 요약 줄 탭 → 통계, 주 ↔ 월 전환, `‹` 로 지난 기간, 가장 오래된 기간에서 `‹` 비활성
  3. 막대 탭 → 값, 기록 "가장 먼 산책" 탭 → 상세
  4. 산책을 모두 지우면 통계 빈 안내 · 피드 요약 줄 사라짐
  5. 다크 모드
