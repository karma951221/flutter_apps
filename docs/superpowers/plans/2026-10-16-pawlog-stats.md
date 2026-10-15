# pawlog W6 stats Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** pawlog 에 주 · 월 산책 통계 화면(`/stats`)과 피드 맨 위 "이번 주" 요약 줄을 더한다.

**Architecture:** 이미 있는 `WalkUseCase.watchWalks()` 스트림을 그대로 구독하고, 도메인 순수 함수
`WalkStatsPolicy` 가 현지 시각 기준으로 기간 요약 · 막대 칸 · 연속 · 최고 기록을 계산한다. `StatsCubit` 이
그 결과를 sealed `StatsState` 로 내고, `WalkFeedCubit` 은 같은 정책으로 이번 주 요약을 상태에 싣는다.
스키마 · 저장소 · `WalkUseCase` 는 바꾸지 않는다.

**Tech Stack:** Flutter · flutter_bloc(Cubit) · freezed 3 · injectable/get_it · go_router · intl · gen-l10n ·
bloc_test · mocktail

**Spec:** [docs/superpowers/specs/2026-10-16-pawlog-stats-design.md](../specs/2026-10-16-pawlog-stats-design.md) ·
화면 · 상태 · 문자열은 [apps/pawlog/docs/features/stats/plan.md](../../../apps/pawlog/docs/features/stats/plan.md)

## Global Constraints

- 모든 날짜 계산은 기기 현지 시각. `Walk.startedAt` 은 `toLocal()` 해서 쓴다
- 산책은 **시작 시각의 현지 날짜** 하나에만 속한다(자정을 넘겨도 쪼개지 않는다)
- 주는 **월요일 00:00 시작** 7일, 월은 1일 00:00 시작. 범위는 반열린 `[start, end)`. 날짜 더하기는 `DateTime(y, m, d + n)`
- `offset` 0 = 지금 기간, 음수 = 과거. 미래(`offset > 0`)로 가지 않는다
- 지난 기간 비교는 바로 전 기간 **전체** 거리와. 지금 > 지난 → "더 걸었어요", 아니면 중립 "지난주 n km", 지난 기간 거리 0 → 숨김
- 현재 연속 일수: 오늘 산책이 없으면 어제부터 센다. 최고 기록 동률은 **최근 것**
- 연두(`accent`)는 쓰지 않는다. 막대 · 링크는 `primary`(남색)
- 화면에 `Colors.*` · 숫자 여백 · `BorderRadius.circular(n)` 금지 — `PawlogColors` · `PawlogSpacing` · `PawlogSize` · `PawlogRadius` · `PawlogMotion` · `PawlogTextStyles` · `Theme.of(context).textTheme` 만
- Freezed: 단일 모델은 primary constructor(`@override final …` + `const X({…})`), 상태는 `sealed class` + named factory. 분기는 Dart `switch` 패턴
- `.freezed.dart` · `.g.dart` · `injection.config.dart` 는 손으로 고치지 않는다 — `dart run build_runner build --delete-conflicting-outputs`
- 테스트 위치는 `lib/` 와 1:1 (`lib/domain/stats/…` ↔ `test/domain/stats/…`)
- 문자열 키는 `apps/pawlog/docs/features/stats/plan.md` "문자열" 표 그대로. ko 템플릿에만 `@` 설명, en · ja 는 값만(기존 파일 관례)
- 커밋 메시지 끝에 `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`

## Review Focus

1. **UTC 로 들어온 `startedAt`** — drift 는 UTC 로 돌려줄 수 있다. 현지 00:30 에 시작한 산책이 UTC 로 전날이어도 현지 날짜 칸에 들어가야 한다 → Task 1 "UTC 시각" 테스트
2. **연말 · 연초를 걸친 주와 해를 넘는 월 이동** — 2026-12-28 ~ 2027-01-03 주, `offset` 이 1월에서 지난해 12월로 → Task 1 범위 테스트 · Task 3 라벨 테스트
3. **보고 있던 과거 기간보다 오래된 산책이 지워짐** — `offset` 이 `earliestOffset` 으로 끌어올려져야 한다(빈 과거 기간에 갇히지 않게) → Task 3 cubit 테스트
4. **화면을 연 채 자정 · 주가 바뀜** — 다음 스트림 값에서 새 `now` 로 다시 계산 → Task 3 cubit 테스트
5. **첫 값 전에 기간 버튼을 누름 · 시계가 틀어져 미래 산책이 있음** — 로딩 중 이동은 무시, 미래 산책이 있어도 `earliestOffset` ≤ 0 → Task 3 · Task 1 테스트

---

## File Structure

| 파일 | 책임 |
|---|---|
| Create `apps/pawlog/lib/domain/stats/entity/stats_period.dart` | `enum StatsPeriod { week, month }` |
| Create `apps/pawlog/lib/domain/stats/entity/period_range.dart` | `PeriodRange(start, end)` + `contains` |
| Create `apps/pawlog/lib/domain/stats/entity/period_summary.dart` | `PeriodSummary(distanceMeters, duration, walkCount)` + `empty` |
| Create `apps/pawlog/lib/domain/stats/entity/stats_bucket.dart` | 막대 한 칸 |
| Create `apps/pawlog/lib/domain/stats/entity/period_stats.dart` | 한 기간의 요약 · 전 기간 요약 · 칸 |
| Create `apps/pawlog/lib/domain/stats/entity/walk_records.dart` | 연속 · 최고 기록 |
| Create `apps/pawlog/lib/domain/stats/policy/walk_stats_policy.dart` | 계산 순수 함수 |
| Modify `packages/l10n/lib/l10n/app_{ko,en,ja}.arb` (+ 생성 파일) | 문자열 24개 |
| Create `apps/pawlog/lib/presentation/stats/format/stats_format.dart` | 기간 · 칸 라벨, 비교 문구 |
| Create `apps/pawlog/lib/presentation/stats/cubit/stats_state.dart` · `stats_cubit.dart` | 화면 상태 |
| Modify `apps/pawlog/lib/presentation/theme/pawlog_spacing.dart` | `PawlogSize.statsChart` · `hairline` |
| Create `apps/pawlog/lib/presentation/stats/widget/period_switcher.dart` | 주 · 월 토글 + ‹ 라벨 › |
| Create `apps/pawlog/lib/presentation/stats/widget/period_summary_view.dart` | 히어로 거리 · 시간 · 횟수 · 비교 |
| Create `apps/pawlog/lib/presentation/stats/widget/distance_bar_chart.dart` | 막대(위젯으로 그림 — 탭 · `Semantics` 가 쉬워 스펙의 `CustomPainter` 대신) |
| Create `apps/pawlog/lib/presentation/stats/widget/walk_records_view.dart` | 기록 줄글 |
| Create `apps/pawlog/lib/presentation/stats/page/stats_page.dart` | 페이지 |
| Modify `apps/pawlog/lib/core/router/dogs_redirect.dart` · `app_router.dart` | `/stats` |
| Create `apps/pawlog/lib/presentation/feed/widget/week_summary_line.dart` | 피드 요약 줄 |
| Modify `apps/pawlog/lib/presentation/feed/cubit/walk_feed_{state,cubit}.dart` · `page/walk_feed_page.dart` | `weekSummary` · `onOpenStats` |
| Modify `apps/pawlog/test/support/pump_app.dart` | `theme` 인자(다크 테스트) |

---

### Task 1: 통계 엔티티와 계산 정책

**Files:**
- Create: `apps/pawlog/lib/domain/stats/entity/stats_period.dart`, `period_range.dart`, `period_summary.dart`, `stats_bucket.dart`, `period_stats.dart`, `walk_records.dart`
- Create: `apps/pawlog/lib/domain/stats/policy/walk_stats_policy.dart`
- Test: `apps/pawlog/test/domain/stats/policy/walk_stats_policy_test.dart`

**Interfaces:**
- Consumes: `Walk` (`apps/pawlog/lib/domain/walk/entity/walk.dart` — `id`, `startedAt`, `duration`, `distanceMeters`), `dog()` · `t0` 테스트 도우미 (`test/support/fakes.dart`)
- Produces:
  - `enum StatsPeriod { week, month }`
  - `PeriodRange({required DateTime start, required DateTime end})`, `bool contains(DateTime local)`
  - `PeriodSummary({required double distanceMeters, required Duration duration, required int walkCount})`, `static const PeriodSummary empty`
  - `StatsBucket({required PeriodRange range, required double distanceMeters, required int walkCount})`
  - `PeriodStats({required StatsPeriod period, required PeriodRange range, required PeriodSummary summary, required PeriodSummary previousSummary, required List<StatsBucket> buckets})`
  - `WalkRecords({required int currentStreakDays, required int longestStreakDays, Walk? farthest, Walk? longest})`, `static const WalkRecords empty`
  - `WalkStatsPolicy.periodRange(StatsPeriod, DateTime now, {int offset = 0}) → PeriodRange`
  - `WalkStatsPolicy.periodStats(List<Walk>, StatsPeriod, DateTime now, {int offset = 0}) → PeriodStats`
  - `WalkStatsPolicy.records(List<Walk>, DateTime now) → WalkRecords`
  - `WalkStatsPolicy.earliestOffset(List<Walk>, StatsPeriod, DateTime now) → int` (항상 ≤ 0)

- [ ] **Step 1: 엔티티 작성**

`apps/pawlog/lib/domain/stats/entity/stats_period.dart`:

```dart
/// 통계 화면의 기간 단위. 주는 월요일 00:00 시작이다.
enum StatsPeriod { week, month }
```

`apps/pawlog/lib/domain/stats/entity/period_range.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'period_range.freezed.dart';

/// 현지 시각의 반열린 구간 `[start, end)`.
@freezed
class PeriodRange with _$PeriodRange {
  @override
  final DateTime start;
  @override
  final DateTime end;

  const PeriodRange({required this.start, required this.end});

  /// [local] 은 현지 시각이어야 한다.
  bool contains(DateTime local) => !local.isBefore(start) && local.isBefore(end);
}
```

`apps/pawlog/lib/domain/stats/entity/period_summary.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'period_summary.freezed.dart';

/// 한 기간에 시작한 산책들의 합.
@freezed
class PeriodSummary with _$PeriodSummary {
  @override
  final double distanceMeters;
  @override
  final Duration duration;
  @override
  final int walkCount;

  const PeriodSummary({
    required this.distanceMeters,
    required this.duration,
    required this.walkCount,
  });

  static const empty = PeriodSummary(
    distanceMeters: 0,
    duration: Duration.zero,
    walkCount: 0,
  );
}
```

`apps/pawlog/lib/domain/stats/entity/stats_bucket.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import 'period_range.dart';

part 'stats_bucket.freezed.dart';

/// 막대 그래프의 한 칸 — 주 보기는 하루, 월 보기는 그 달 안의 한 주.
@freezed
class StatsBucket with _$StatsBucket {
  @override
  final PeriodRange range;
  @override
  final double distanceMeters;
  @override
  final int walkCount;

  const StatsBucket({
    required this.range,
    required this.distanceMeters,
    required this.walkCount,
  });
}
```

`apps/pawlog/lib/domain/stats/entity/period_stats.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import 'period_range.dart';
import 'period_summary.dart';
import 'stats_bucket.dart';
import 'stats_period.dart';

part 'period_stats.freezed.dart';

/// 한 기간의 통계. [previousSummary] 는 바로 전 같은 종류 기간 전체의 합이다.
@freezed
class PeriodStats with _$PeriodStats {
  @override
  final StatsPeriod period;
  @override
  final PeriodRange range;
  @override
  final PeriodSummary summary;
  @override
  final PeriodSummary previousSummary;
  @override
  final List<StatsBucket> buckets;

  const PeriodStats({
    required this.period,
    required this.range,
    required this.summary,
    required this.previousSummary,
    required this.buckets,
  });
}
```

`apps/pawlog/lib/domain/stats/entity/walk_records.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../walk/entity/walk.dart';

part 'walk_records.freezed.dart';

/// 전체 기간의 기록. 산책이 없으면 [farthest] · [longest] 가 null 이다.
@freezed
class WalkRecords with _$WalkRecords {
  @override
  final int currentStreakDays;
  @override
  final int longestStreakDays;
  @override
  final Walk? farthest;
  @override
  final Walk? longest;

  const WalkRecords({
    required this.currentStreakDays,
    required this.longestStreakDays,
    this.farthest,
    this.longest,
  });

  static const empty = WalkRecords(currentStreakDays: 0, longestStreakDays: 0);
}
```

- [ ] **Step 2: 실패하는 정책 테스트 작성**

`apps/pawlog/test/domain/stats/policy/walk_stats_policy_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pawlog/domain/stats/entity/period_range.dart';
import 'package:pawlog/domain/stats/entity/stats_period.dart';
import 'package:pawlog/domain/stats/entity/walk_records.dart';
import 'package:pawlog/domain/stats/policy/walk_stats_policy.dart';
import 'package:pawlog/domain/walk/entity/walk.dart';

import '../../../support/fakes.dart';

Walk _walk(
  String id,
  DateTime startedAt, {
  double meters = 1000,
  Duration duration = const Duration(minutes: 30),
}) => Walk(
  id: id,
  startedAt: startedAt,
  endedAt: startedAt.add(duration),
  duration: duration,
  distanceMeters: meters,
  dogs: [dog('1')],
  photos: const [],
  previewPoints: const [],
  createdAt: startedAt,
  updatedAt: startedAt,
);

PeriodRange _range(DateTime start, DateTime end) =>
    PeriodRange(start: start, end: end);

void main() {
  // 2026-10-16 은 금요일. 그 주는 10-12(월) ~ 10-18(일).
  final now = DateTime(2026, 10, 16, 15);

  group('periodRange', () {
    test('주는 월요일 00:00 부터 7일이다', () {
      expect(
        WalkStatsPolicy.periodRange(StatsPeriod.week, now),
        _range(DateTime(2026, 10, 12), DateTime(2026, 10, 19)),
      );
    });

    test('일요일 23:59 는 같은 주, 월요일 00:00 은 다음 주다', () {
      expect(
        WalkStatsPolicy.periodRange(
          StatsPeriod.week,
          DateTime(2026, 10, 18, 23, 59),
        ).start,
        DateTime(2026, 10, 12),
      );
      expect(
        WalkStatsPolicy.periodRange(StatsPeriod.week, DateTime(2026, 10, 19)).start,
        DateTime(2026, 10, 19),
      );
    });

    test('offset -1 은 바로 전 주다', () {
      expect(
        WalkStatsPolicy.periodRange(StatsPeriod.week, now, offset: -1),
        _range(DateTime(2026, 10, 5), DateTime(2026, 10, 12)),
      );
    });

    test('연말 · 연초를 걸친 주', () {
      expect(
        WalkStatsPolicy.periodRange(StatsPeriod.week, DateTime(2027, 1, 1, 8)),
        _range(DateTime(2026, 12, 28), DateTime(2027, 1, 4)),
      );
    });

    test('월은 1일부터 다음 달 1일 전까지, offset 은 해를 넘는다', () {
      expect(
        WalkStatsPolicy.periodRange(StatsPeriod.month, now),
        _range(DateTime(2026, 10), DateTime(2026, 11)),
      );
      expect(
        WalkStatsPolicy.periodRange(StatsPeriod.month, now, offset: -10),
        _range(DateTime(2025, 12), DateTime(2026, 1)),
      );
    });
  });

  group('periodStats', () {
    final walks = [
      _walk('b', DateTime(2026, 10, 16, 8), meters: 2500, duration: const Duration(minutes: 45)),
      _walk('a', DateTime(2026, 10, 12, 7)),
      _walk('p', DateTime(2026, 10, 5, 7), meters: 800, duration: const Duration(minutes: 20)),
    ];

    test('이번 주 합과 지난주 전체 합', () {
      final stats = WalkStatsPolicy.periodStats(walks, StatsPeriod.week, now);

      expect(stats.period, StatsPeriod.week);
      expect(stats.summary.distanceMeters, 3500);
      expect(stats.summary.duration, const Duration(minutes: 75));
      expect(stats.summary.walkCount, 2);
      expect(stats.previousSummary.distanceMeters, 800);
      expect(stats.previousSummary.walkCount, 1);
    });

    test('주 보기는 월 ~ 일 7칸이다', () {
      final stats = WalkStatsPolicy.periodStats(walks, StatsPeriod.week, now);

      expect(stats.buckets, hasLength(7));
      expect(stats.buckets.first.range.start, DateTime(2026, 10, 12));
      expect(stats.buckets.first.distanceMeters, 1000);
      expect(stats.buckets[4].distanceMeters, 2500); // 금요일
      expect(stats.buckets[1].distanceMeters, 0);
    });

    test('자정을 넘긴 산책은 시작한 날에만 들어간다', () {
      final late = [
        _walk('n', DateTime(2026, 10, 18, 23, 50), duration: const Duration(minutes: 40)),
      ];

      final thisWeek = WalkStatsPolicy.periodStats(late, StatsPeriod.week, now);
      final nextWeek = WalkStatsPolicy.periodStats(
        late,
        StatsPeriod.week,
        DateTime(2026, 10, 19, 9),
      );

      expect(thisWeek.buckets[6].walkCount, 1);
      expect(nextWeek.summary.walkCount, 0);
    });

    test('UTC 로 들어온 시작 시각도 현지 날짜 칸에 들어간다', () {
      final utc = [_walk('u', DateTime(2026, 10, 12, 0, 30).toUtc())];

      final stats = WalkStatsPolicy.periodStats(utc, StatsPeriod.week, now);

      expect(stats.buckets.first.walkCount, 1);
    });

    test('월 보기는 월요일 시작 주마다 한 칸, 첫 · 끝 칸은 달로 자른다', () {
      final october = WalkStatsPolicy.periodStats(const [], StatsPeriod.month, now);

      expect([for (final b in october.buckets) b.range.start.day], [1, 5, 12, 19, 26]);
      expect(october.buckets.last.range.end, DateTime(2026, 11));
      // 2027-02-01 은 월요일, 28일 → 4칸. 2026-11-01 은 일요일, 30일 → 6칸.
      expect(
        WalkStatsPolicy.periodStats(const [], StatsPeriod.month, DateTime(2027, 2, 10)).buckets,
        hasLength(4),
      );
      expect(
        WalkStatsPolicy.periodStats(const [], StatsPeriod.month, DateTime(2026, 11, 10)).buckets,
        hasLength(6),
      );
    });

    test('월 칸에 거리가 합쳐진다', () {
      final stats = WalkStatsPolicy.periodStats(walks, StatsPeriod.month, now);

      expect(stats.summary.distanceMeters, 4300);
      expect(stats.buckets[1].distanceMeters, 800); // 5–11
      expect(stats.buckets[2].distanceMeters, 3500); // 12–18
    });
  });

  group('records', () {
    test('산책이 없으면 비어 있다', () {
      expect(WalkStatsPolicy.records(const [], now), WalkRecords.empty);
    });

    test('오늘까지 이어진 연속 일수', () {
      final walks = [
        _walk('c', DateTime(2026, 10, 16, 7)),
        _walk('b', DateTime(2026, 10, 15, 7)),
        _walk('a', DateTime(2026, 10, 14, 7)),
      ];

      expect(WalkStatsPolicy.records(walks, now).currentStreakDays, 3);
    });

    test('오늘 아직 산책이 없으면 어제부터 센다', () {
      final walks = [
        _walk('b', DateTime(2026, 10, 15, 7)),
        _walk('a', DateTime(2026, 10, 14, 7)),
      ];

      expect(WalkStatsPolicy.records(walks, now).currentStreakDays, 2);
    });

    test('어제도 없으면 0 이다', () {
      final walks = [_walk('a', DateTime(2026, 10, 13, 7))];

      expect(WalkStatsPolicy.records(walks, now).currentStreakDays, 0);
    });

    test('최장 연속은 하루 여러 건을 하루로 센다', () {
      final walks = [
        _walk('e', DateTime(2026, 10, 10, 7)),
        _walk('d', DateTime(2026, 10, 3, 18)),
        _walk('c', DateTime(2026, 10, 3, 7)),
        _walk('b', DateTime(2026, 10, 2, 7)),
        _walk('a', DateTime(2026, 10, 1, 7)),
      ];

      expect(WalkStatsPolicy.records(walks, now).longestStreakDays, 3);
    });

    test('가장 먼 · 가장 오래 걸은 산책, 같으면 최근 것', () {
      final older = _walk('old', DateTime(2026, 10, 1, 7), meters: 3000);
      final newer = _walk('new', DateTime(2026, 10, 9, 7), meters: 3000);
      final long = _walk(
        'long',
        DateTime(2026, 10, 2, 7),
        meters: 500,
        duration: const Duration(hours: 2),
      );

      // 피드 순서가 아니어도 최근 것을 고른다.
      final records = WalkStatsPolicy.records([older, long, newer], now);

      expect(records.farthest?.id, 'new');
      expect(records.longest?.id, 'long');
    });
  });

  group('earliestOffset', () {
    final walks = [
      _walk('b', DateTime(2026, 10, 16, 7)),
      _walk('a', DateTime(2026, 9, 30, 7)), // 9-28 주, 9월
    ];

    test('가장 오래된 산책이 든 기간까지', () {
      expect(WalkStatsPolicy.earliestOffset(walks, StatsPeriod.week, now), -2);
      expect(WalkStatsPolicy.earliestOffset(walks, StatsPeriod.month, now), -1);
    });

    test('산책이 없으면 0', () {
      expect(WalkStatsPolicy.earliestOffset(const [], StatsPeriod.week, now), 0);
    });

    test('시계가 틀어져 미래 산책만 있어도 0 보다 크지 않다', () {
      final future = [_walk('f', DateTime(2026, 11, 20, 7))];

      expect(WalkStatsPolicy.earliestOffset(future, StatsPeriod.week, now), 0);
      expect(WalkStatsPolicy.earliestOffset(future, StatsPeriod.month, now), 0);
    });
  });
}
```

- [ ] **Step 3: 테스트가 실패하는지 확인**

Run: `cd apps/pawlog && flutter test test/domain/stats/policy/walk_stats_policy_test.dart`
Expected: FAIL — `walk_stats_policy.dart` 가 없어 컴파일 오류.

- [ ] **Step 4: 정책 구현**

`apps/pawlog/lib/domain/stats/policy/walk_stats_policy.dart`:

```dart
import 'dart:math' as math;

import '../../walk/entity/walk.dart';
import '../entity/period_range.dart';
import '../entity/period_stats.dart';
import '../entity/period_summary.dart';
import '../entity/stats_bucket.dart';
import '../entity/stats_period.dart';
import '../entity/walk_records.dart';

/// 산책 목록에서 기간 통계와 기록을 계산한다. 상태가 없고 시계를 직접 읽지 않는다.
///
/// 모든 날짜는 현지 시각이고, 산책은 시작 시각의 현지 날짜 하나에만 속한다.
/// 날짜 더하기는 `DateTime(y, m, d + n)` 으로 해서 서머타임이 있어도 자정이 밀리지 않는다.
abstract final class WalkStatsPolicy {
  static PeriodRange periodRange(
    StatsPeriod period,
    DateTime now, {
    int offset = 0,
  }) {
    final local = now.toLocal();
    switch (period) {
      case StatsPeriod.week:
        final start = DateTime(
          local.year,
          local.month,
          local.day - (local.weekday - DateTime.monday) + 7 * offset,
        );
        return PeriodRange(start: start, end: _addDays(start, 7));
      case StatsPeriod.month:
        final start = DateTime(local.year, local.month + offset);
        return PeriodRange(start: start, end: DateTime(start.year, start.month + 1));
    }
  }

  static PeriodStats periodStats(
    List<Walk> walks,
    StatsPeriod period,
    DateTime now, {
    int offset = 0,
  }) {
    final range = periodRange(period, now, offset: offset);
    return PeriodStats(
      period: period,
      range: range,
      summary: _summarize(walks, range),
      previousSummary: _summarize(
        walks,
        periodRange(period, now, offset: offset - 1),
      ),
      buckets: [
        for (final bucket in _bucketRanges(period, range))
          _bucket(walks, bucket),
      ],
    );
  }

  static WalkRecords records(List<Walk> walks, DateTime now) {
    if (walks.isEmpty) return WalkRecords.empty;

    final days = {for (final walk in walks) _day(walk.startedAt.toLocal())};
    final today = _day(now.toLocal());
    // 오늘 아직 안 걸었으면 어제부터 — 아침에 연속이 0 으로 꺼지지 않게.
    var cursor = days.contains(today) ? today : _addDays(today, -1);
    var current = 0;
    while (days.contains(cursor)) {
      current++;
      cursor = _addDays(cursor, -1);
    }

    final sorted = days.toList()..sort();
    var longestStreak = 0;
    var run = 0;
    DateTime? previous;
    for (final day in sorted) {
      run = previous != null && _addDays(previous, 1) == day ? run + 1 : 1;
      longestStreak = math.max(longestStreak, run);
      previous = day;
    }

    // 최근 것부터 보며 더 클 때만 바꾸면 동률은 최근 것이 남는다.
    final recentFirst = [...walks]
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    Walk? farthest;
    Walk? longest;
    for (final walk in recentFirst) {
      if (farthest == null || walk.distanceMeters > farthest.distanceMeters) {
        farthest = walk;
      }
      if (longest == null || walk.duration > longest.duration) {
        longest = walk;
      }
    }

    return WalkRecords(
      currentStreakDays: current,
      longestStreakDays: longestStreak,
      farthest: farthest,
      longest: longest,
    );
  }

  /// 가장 오래된 산책이 든 기간의 offset. 산책이 없거나 모두 미래면 0.
  static int earliestOffset(
    List<Walk> walks,
    StatsPeriod period,
    DateTime now,
  ) {
    if (walks.isEmpty) return 0;
    final earliest = walks
        .map((walk) => walk.startedAt.toLocal())
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final current = periodRange(period, now).start;
    final target = periodRange(period, earliest).start;
    final offset = switch (period) {
      StatsPeriod.week => -(_daysBetween(target, current) ~/ 7),
      StatsPeriod.month =>
        (target.year - current.year) * 12 + target.month - current.month,
    };
    return math.min(0, offset);
  }

  static List<PeriodRange> _bucketRanges(StatsPeriod period, PeriodRange range) {
    switch (period) {
      case StatsPeriod.week:
        return [
          for (var i = 0; i < 7; i++)
            PeriodRange(
              start: _addDays(range.start, i),
              end: _addDays(range.start, i + 1),
            ),
        ];
      case StatsPeriod.month:
        final buckets = <PeriodRange>[];
        var start = range.start;
        while (start.isBefore(range.end)) {
          // 다음 월요일까지. 월요일(1)이면 7일, 일요일(7)이면 1일.
          var end = _addDays(start, 8 - start.weekday);
          if (end.isAfter(range.end)) end = range.end;
          buckets.add(PeriodRange(start: start, end: end));
          start = end;
        }
        return buckets;
    }
  }

  static PeriodSummary _summarize(List<Walk> walks, PeriodRange range) {
    var distance = 0.0;
    var duration = Duration.zero;
    var count = 0;
    for (final walk in walks) {
      if (!range.contains(walk.startedAt.toLocal())) continue;
      distance += walk.distanceMeters;
      duration += walk.duration;
      count++;
    }
    return PeriodSummary(
      distanceMeters: distance,
      duration: duration,
      walkCount: count,
    );
  }

  static StatsBucket _bucket(List<Walk> walks, PeriodRange range) {
    final summary = _summarize(walks, range);
    return StatsBucket(
      range: range,
      distanceMeters: summary.distanceMeters,
      walkCount: summary.walkCount,
    );
  }

  static DateTime _day(DateTime local) =>
      DateTime(local.year, local.month, local.day);

  static DateTime _addDays(DateTime day, int days) =>
      DateTime(day.year, day.month, day.day + days);

  /// 서머타임과 무관한 날짜 차이.
  static int _daysBetween(DateTime from, DateTime to) => DateTime.utc(
    to.year,
    to.month,
    to.day,
  ).difference(DateTime.utc(from.year, from.month, from.day)).inDays;
}
```

- [ ] **Step 5: 코드 생성 후 테스트 통과 확인**

Run: `cd apps/pawlog && dart run build_runner build --delete-conflicting-outputs && flutter test test/domain/stats`
Expected: PASS (모든 테스트)

- [ ] **Step 6: 분석 · 커밋**

Run: `cd apps/pawlog && flutter analyze` → `No issues found!`

```bash
git add apps/pawlog/lib/domain/stats apps/pawlog/test/domain/stats
git commit -m "feat(pawlog): 산책 통계 계산 정책을 추가한다

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: 통계 문자열

**Files:**
- Modify: `packages/l10n/lib/l10n/app_ko.arb`, `app_en.arb`, `app_ja.arb`
- Regenerate: `packages/l10n/lib/l10n/app_localizations*.dart`

**Interfaces:**
- Produces (`AppLocalizations`): `walkStatsTitle` · `walkStatsWeek` · `walkStatsMonth` · `walkStatsPreviousTooltip` · `walkStatsNextTooltip` · `walkStatsDistanceLabel` · `walkStatsDurationLabel` · `walkStatsCountLabel` · `walkStatsCountValue(int count)` · `walkStatsMoreThanLastWeek(String distance)` · `walkStatsLastWeek(String distance)` · `walkStatsMoreThanLastMonth(String distance)` · `walkStatsLastMonth(String distance)` · `walkStatsBarSemantics(String label, String distance)` · `walkStatsRecordsTitle` · `walkStatsCurrentStreak` · `walkStatsLongestStreak` · `walkStatsDays(int count)` · `walkStatsFarthestWalk` · `walkStatsLongestWalk` · `walkStatsEmptyTitle` · `walkStatsEmptyMessage` · `walkFeedWeekSummary(String distance, int count)` · `walkFeedWeekSummaryEmpty`

- [ ] **Step 1: ARB 에 키 추가**

세 파일 모두 마지막 `}` 앞에 넣는다(앞 항목 뒤에 쉼표). 스크래치 스크립트로 넣어도 된다 — JSON 순서를 지키도록 `json.load(object_pairs_hook=OrderedDict)` → 추가 → `json.dump(ensure_ascii=False, indent=2)` 후 파일 끝 줄바꿈을 원래대로 맞춘다. 넣은 뒤 `git diff --stat` 가 세 파일의 추가만 보여야 한다(기존 줄이 다시 포맷되면 손으로 넣는다).

`app_ko.arb`:

```json
  "walkStatsTitle": "산책 통계",
  "@walkStatsTitle": { "description": "통계 화면 앱바 제목" },
  "walkStatsWeek": "주",
  "@walkStatsWeek": { "description": "통계 기간 토글 — 주" },
  "walkStatsMonth": "월",
  "@walkStatsMonth": { "description": "통계 기간 토글 — 월" },
  "walkStatsPreviousTooltip": "이전 기간",
  "@walkStatsPreviousTooltip": { "description": "통계 이전 기간 버튼 툴팁" },
  "walkStatsNextTooltip": "다음 기간",
  "@walkStatsNextTooltip": { "description": "통계 다음 기간 버튼 툴팁" },
  "walkStatsDistanceLabel": "걸은 거리",
  "@walkStatsDistanceLabel": { "description": "통계 요약 — 총 거리 라벨" },
  "walkStatsDurationLabel": "걸은 시간",
  "@walkStatsDurationLabel": { "description": "통계 요약 — 총 시간 라벨" },
  "walkStatsCountLabel": "산책",
  "@walkStatsCountLabel": { "description": "통계 요약 — 산책 횟수 라벨" },
  "walkStatsCountValue": "{count}번",
  "@walkStatsCountValue": {
    "description": "통계 요약 — 산책 횟수 값",
    "placeholders": { "count": { "type": "int" } }
  },
  "walkStatsMoreThanLastWeek": "지난주보다 {distance} 더 걸었어요",
  "@walkStatsMoreThanLastWeek": {
    "description": "이번 기간이 지난주보다 길 때. distance 는 차이(WalkFormat.distance)",
    "placeholders": { "distance": { "type": "String" } }
  },
  "walkStatsLastWeek": "지난주 {distance}",
  "@walkStatsLastWeek": {
    "description": "이번 기간이 지난주보다 길지 않을 때 중립 비교. distance 는 지난주 합",
    "placeholders": { "distance": { "type": "String" } }
  },
  "walkStatsMoreThanLastMonth": "지난달보다 {distance} 더 걸었어요",
  "@walkStatsMoreThanLastMonth": {
    "description": "이번 기간이 지난달보다 길 때. distance 는 차이",
    "placeholders": { "distance": { "type": "String" } }
  },
  "walkStatsLastMonth": "지난달 {distance}",
  "@walkStatsLastMonth": {
    "description": "이번 기간이 지난달보다 길지 않을 때 중립 비교. distance 는 지난달 합",
    "placeholders": { "distance": { "type": "String" } }
  },
  "walkStatsBarSemantics": "{label} {distance}",
  "@walkStatsBarSemantics": {
    "description": "막대 한 칸의 접근성 라벨. label 은 요일 또는 일 범위",
    "placeholders": { "label": { "type": "String" }, "distance": { "type": "String" } }
  },
  "walkStatsRecordsTitle": "기록",
  "@walkStatsRecordsTitle": { "description": "통계 화면 기록 절 제목" },
  "walkStatsCurrentStreak": "연속 산책",
  "@walkStatsCurrentStreak": { "description": "지금 이어지고 있는 연속 산책 일수 라벨" },
  "walkStatsLongestStreak": "최장 연속",
  "@walkStatsLongestStreak": { "description": "가장 길게 이어진 연속 산책 일수 라벨" },
  "walkStatsDays": "{count}일",
  "@walkStatsDays": {
    "description": "연속 일수 값",
    "placeholders": { "count": { "type": "int" } }
  },
  "walkStatsFarthestWalk": "가장 먼 산책",
  "@walkStatsFarthestWalk": { "description": "거리가 가장 긴 산책 라벨" },
  "walkStatsLongestWalk": "가장 오래 걸은 산책",
  "@walkStatsLongestWalk": { "description": "시간이 가장 긴 산책 라벨" },
  "walkStatsEmptyTitle": "아직 통계가 없어요",
  "@walkStatsEmptyTitle": { "description": "산책이 하나도 없을 때 통계 화면 안내 제목" },
  "walkStatsEmptyMessage": "산책을 기록하면 여기에 쌓여요",
  "@walkStatsEmptyMessage": { "description": "산책이 하나도 없을 때 통계 화면 안내 본문" },
  "walkFeedWeekSummary": "이번 주 {distance} · {count}번",
  "@walkFeedWeekSummary": {
    "description": "피드 맨 위 이번 주 요약 줄. 탭하면 통계",
    "placeholders": { "distance": { "type": "String" }, "count": { "type": "int" } }
  },
  "walkFeedWeekSummaryEmpty": "이번 주는 아직 산책 전이에요",
  "@walkFeedWeekSummaryEmpty": { "description": "이번 주 산책이 0건일 때 피드 요약 줄" }
```

`app_en.arb`:

```json
  "walkStatsTitle": "Walk stats",
  "walkStatsWeek": "Week",
  "walkStatsMonth": "Month",
  "walkStatsPreviousTooltip": "Previous",
  "walkStatsNextTooltip": "Next",
  "walkStatsDistanceLabel": "Distance",
  "walkStatsDurationLabel": "Time",
  "walkStatsCountLabel": "Walks",
  "walkStatsCountValue": "{count, plural, =1{1 walk} other{{count} walks}}",
  "walkStatsMoreThanLastWeek": "{distance} more than last week",
  "walkStatsLastWeek": "Last week {distance}",
  "walkStatsMoreThanLastMonth": "{distance} more than last month",
  "walkStatsLastMonth": "Last month {distance}",
  "walkStatsBarSemantics": "{label} {distance}",
  "walkStatsRecordsTitle": "Records",
  "walkStatsCurrentStreak": "Current streak",
  "walkStatsLongestStreak": "Longest streak",
  "walkStatsDays": "{count, plural, =1{1 day} other{{count} days}}",
  "walkStatsFarthestWalk": "Farthest walk",
  "walkStatsLongestWalk": "Longest walk",
  "walkStatsEmptyTitle": "No stats yet",
  "walkStatsEmptyMessage": "Your walks will add up here",
  "walkFeedWeekSummary": "This week {distance} · {count, plural, =1{1 walk} other{{count} walks}}",
  "walkFeedWeekSummaryEmpty": "No walks yet this week"
```

`app_ja.arb`:

```json
  "walkStatsTitle": "散歩の記録",
  "walkStatsWeek": "週",
  "walkStatsMonth": "月",
  "walkStatsPreviousTooltip": "前の期間",
  "walkStatsNextTooltip": "次の期間",
  "walkStatsDistanceLabel": "距離",
  "walkStatsDurationLabel": "時間",
  "walkStatsCountLabel": "散歩",
  "walkStatsCountValue": "{count}回",
  "walkStatsMoreThanLastWeek": "先週より{distance}多く歩きました",
  "walkStatsLastWeek": "先週 {distance}",
  "walkStatsMoreThanLastMonth": "先月より{distance}多く歩きました",
  "walkStatsLastMonth": "先月 {distance}",
  "walkStatsBarSemantics": "{label} {distance}",
  "walkStatsRecordsTitle": "記録",
  "walkStatsCurrentStreak": "連続散歩",
  "walkStatsLongestStreak": "最長連続",
  "walkStatsDays": "{count}日",
  "walkStatsFarthestWalk": "いちばん遠い散歩",
  "walkStatsLongestWalk": "いちばん長い散歩",
  "walkStatsEmptyTitle": "まだ記録がありません",
  "walkStatsEmptyMessage": "散歩を記録するとここに積み上がります",
  "walkFeedWeekSummary": "今週 {distance}・{count}回",
  "walkFeedWeekSummaryEmpty": "今週はまだ散歩していません"
```

- [ ] **Step 2: 생성 · 검증**

Run: `cd packages/l10n && flutter gen-l10n && flutter analyze && flutter test`
Expected: 생성 경고 없음(번역 누락 `untranslated` 메시지 없음), analyze 0건, 테스트 통과(`+10`).

Run: `grep -c "walkStats\|walkFeedWeekSummary" lib/l10n/app_localizations.dart`
Expected: 24 개 이상(게터 · 메서드 선언).

- [ ] **Step 3: 커밋**

```bash
git add packages/l10n/lib/l10n
git commit -m "feat(l10n): 산책 통계 문자열을 추가한다

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: 통계 표기와 `StatsCubit`

**Files:**
- Create: `apps/pawlog/lib/presentation/stats/format/stats_format.dart`
- Create: `apps/pawlog/lib/presentation/stats/cubit/stats_state.dart`, `stats_cubit.dart`
- Test: `apps/pawlog/test/presentation/stats/format/stats_format_test.dart`
- Test: `apps/pawlog/test/presentation/stats/cubit/stats_cubit_test.dart`

**Interfaces:**
- Consumes: Task 1 의 엔티티 · `WalkStatsPolicy`, Task 2 의 문자열, `WalkFormat.distance(AppLocalizations, double)` · `WalkFormat.duration(AppLocalizations, Duration)`, `WalkUseCase.watchWalks() → Stream<Result<List<Walk>>>`, `Clock.now()`, 테스트의 `MockWalkUseCase` (`test/support/mock_walk_use_case.dart`) · `FakeClock` (`test/support/fakes.dart`)
- Produces:
  - `StatsFormat.rangeLabel(String locale, StatsPeriod period, PeriodRange range, DateTime now) → String`
  - `StatsFormat.bucketLabel(String locale, StatsPeriod period, PeriodRange range) → String`
  - `StatsFormat.comparison(AppLocalizations l10n, PeriodStats stats) → String?`
  - `sealed StatsState`: `StatsState.loading()` = `StatsLoading`, `StatsState.loaded({required PeriodStats stats, required WalkRecords records, required int offset, required bool canShowPrevious, required bool canShowNext, required bool isEmpty, required DateTime now})` = `StatsLoaded`, `StatsState.failure(Failure failure)` = `StatsFailure`
  - `StatsCubit(WalkUseCase useCase, Clock clock)` — `start()`, `retry()`, `selectPeriod(StatsPeriod)`, `showPrevious()`, `showNext()`

- [ ] **Step 1: 실패하는 표기 테스트**

`apps/pawlog/test/presentation/stats/format/stats_format_test.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:l10n/l10n.dart';
import 'package:pawlog/domain/stats/entity/period_range.dart';
import 'package:pawlog/domain/stats/entity/period_stats.dart';
import 'package:pawlog/domain/stats/entity/period_summary.dart';
import 'package:pawlog/domain/stats/entity/stats_period.dart';
import 'package:pawlog/presentation/stats/format/stats_format.dart';

PeriodSummary _km(double meters) => PeriodSummary(
  distanceMeters: meters,
  duration: Duration.zero,
  walkCount: meters == 0 ? 0 : 1,
);

PeriodStats _stats(StatsPeriod period, double current, double previous) =>
    PeriodStats(
      period: period,
      range: PeriodRange(start: DateTime(2026, 10, 12), end: DateTime(2026, 10, 19)),
      summary: _km(current),
      previousSummary: _km(previous),
      buckets: const [],
    );

void main() {
  setUpAll(() => initializeDateFormatting('ko'));
  final l10n = lookupAppLocalizations(const Locale('ko'));
  final now = DateTime(2026, 10, 16);

  group('rangeLabel', () {
    test('같은 달 주', () {
      expect(
        StatsFormat.rangeLabel(
          'ko',
          StatsPeriod.week,
          PeriodRange(start: DateTime(2026, 10, 12), end: DateTime(2026, 10, 19)),
          now,
        ),
        '10월 12일 – 18일',
      );
    });

    test('달이 걸친 주', () {
      expect(
        StatsFormat.rangeLabel(
          'ko',
          StatsPeriod.week,
          PeriodRange(start: DateTime(2026, 9, 28), end: DateTime(2026, 10, 5)),
          now,
        ),
        '9월 28일 – 10월 4일',
      );
    });

    test('올해가 아닌 주는 연도를 붙인다', () {
      expect(
        StatsFormat.rangeLabel(
          'ko',
          StatsPeriod.week,
          PeriodRange(start: DateTime(2026, 12, 28), end: DateTime(2027, 1, 4)),
          now,
        ),
        '2026년 12월 28일 – 2027년 1월 3일',
      );
    });

    test('월', () {
      expect(
        StatsFormat.rangeLabel(
          'ko',
          StatsPeriod.month,
          PeriodRange(start: DateTime(2026, 10), end: DateTime(2026, 11)),
          now,
        ),
        '2026년 10월',
      );
    });
  });

  test('bucketLabel — 주는 요일, 월은 일 범위', () {
    expect(
      StatsFormat.bucketLabel(
        'ko',
        StatsPeriod.week,
        PeriodRange(start: DateTime(2026, 10, 12), end: DateTime(2026, 10, 13)),
      ),
      '월',
    );
    expect(
      StatsFormat.bucketLabel(
        'ko',
        StatsPeriod.month,
        PeriodRange(start: DateTime(2026, 10, 26), end: DateTime(2026, 11)),
      ),
      '26–31',
    );
    expect(
      StatsFormat.bucketLabel(
        'ko',
        StatsPeriod.month,
        PeriodRange(start: DateTime(2026, 11, 1), end: DateTime(2026, 11, 2)),
      ),
      '1',
    );
  });

  group('comparison', () {
    test('지난 기간이 0 이면 숨긴다', () {
      expect(StatsFormat.comparison(l10n, _stats(StatsPeriod.week, 3500, 0)), isNull);
    });

    test('더 걸었으면 차이를 말한다', () {
      expect(
        StatsFormat.comparison(l10n, _stats(StatsPeriod.week, 3500, 800)),
        '지난주보다 2.7 km 더 걸었어요',
      );
      expect(
        StatsFormat.comparison(l10n, _stats(StatsPeriod.month, 3500, 800)),
        '지난달보다 2.7 km 더 걸었어요',
      );
    });

    test('같거나 덜 걸었으면 지난 기간 합만 말한다', () {
      expect(
        StatsFormat.comparison(l10n, _stats(StatsPeriod.week, 500, 8400)),
        '지난주 8.4 km',
      );
      expect(
        StatsFormat.comparison(l10n, _stats(StatsPeriod.month, 800, 800)),
        '지난달 800 m',
      );
    });
  });
}
```

Run: `cd apps/pawlog && flutter test test/presentation/stats/format/stats_format_test.dart`
Expected: FAIL — `stats_format.dart` 없음.

- [ ] **Step 2: 표기 구현**

`apps/pawlog/lib/presentation/stats/format/stats_format.dart`:

```dart
import 'package:intl/intl.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/stats/entity/period_range.dart';
import '../../../domain/stats/entity/period_stats.dart';
import '../../../domain/stats/entity/stats_period.dart';
import '../../walk/format/walk_format.dart';

/// 통계 화면의 기간 · 칸 라벨과 비교 문구. 위젯 없이 로케일만 받는 순수 함수다.
abstract final class StatsFormat {
  /// 주: `10월 12일 – 18일`, 달이 걸치면 `9월 28일 – 10월 4일`, 올해가 아니면 연도를 붙인다.
  /// 월: `2026년 10월`.
  static String rangeLabel(
    String locale,
    StatsPeriod period,
    PeriodRange range,
    DateTime now,
  ) {
    switch (period) {
      case StatsPeriod.month:
        return DateFormat.yMMMM(locale).format(range.start);
      case StatsPeriod.week:
        final first = range.start;
        final last = _lastDay(range);
        final thisYear = first.year == now.year && last.year == now.year;
        final full = thisYear
            ? DateFormat.MMMd(locale)
            : DateFormat.yMMMd(locale);
        final sameMonth = first.year == last.year && first.month == last.month;
        final end = sameMonth && thisYear ? DateFormat.d(locale) : full;
        return '${full.format(first)} – ${end.format(last)}';
    }
  }

  /// 주 보기는 요일(`월`), 월 보기는 일 범위(`26–31`, 하루면 `1`).
  static String bucketLabel(
    String locale,
    StatsPeriod period,
    PeriodRange range,
  ) {
    switch (period) {
      case StatsPeriod.week:
        return DateFormat.E(locale).format(range.start);
      case StatsPeriod.month:
        final first = range.start.day;
        final last = _lastDay(range).day;
        return first == last ? '$first' : '$first–$last';
    }
  }

  /// 지난 기간 거리가 0 이면 null. 이번이 더 길면 차이를, 아니면 지난 기간 합만 말한다 —
  /// 주 초반에 '덜 걸었어요' 를 보이지 않으려는 것.
  static String? comparison(AppLocalizations l10n, PeriodStats stats) {
    final previous = stats.previousSummary.distanceMeters;
    if (previous <= 0) return null;
    final current = stats.summary.distanceMeters;
    final isWeek = stats.period == StatsPeriod.week;
    if (current > previous) {
      final diff = WalkFormat.distance(l10n, current - previous);
      return isWeek
          ? l10n.walkStatsMoreThanLastWeek(diff)
          : l10n.walkStatsMoreThanLastMonth(diff);
    }
    final total = WalkFormat.distance(l10n, previous);
    return isWeek ? l10n.walkStatsLastWeek(total) : l10n.walkStatsLastMonth(total);
  }

  static DateTime _lastDay(PeriodRange range) =>
      DateTime(range.end.year, range.end.month, range.end.day - 1);
}
```

Run: `cd apps/pawlog && flutter test test/presentation/stats/format/stats_format_test.dart`
Expected: PASS. (`intl` 의 ko 패턴이 `10월 12일` · `2026년 12월 28일` 과 다르게 나오면 테스트의 기대 문자열이 아니라 실제 `DateFormat` 출력을 확인해 기대값을 그 출력으로 맞추고, 그 사실을 커밋 메시지에 적는다 — 패턴은 intl 이 정한다.)

- [ ] **Step 3: 상태와 cubit 작성**

`apps/pawlog/lib/presentation/stats/cubit/stats_state.dart`:

```dart
import 'package:core/core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/stats/entity/period_stats.dart';
import '../../../domain/stats/entity/walk_records.dart';

part 'stats_state.freezed.dart';

@freezed
sealed class StatsState with _$StatsState {
  /// `start()` 직후 첫 `watchWalks` 값 전.
  const factory StatsState.loading() = StatsLoading;

  /// [offset] 0 = 지금 기간. [isEmpty] 는 산책이 하나도 없을 때. [now] 는 계산에 쓴 시각 —
  /// 기간 라벨의 연도 표기를 정한다.
  const factory StatsState.loaded({
    required PeriodStats stats,
    required WalkRecords records,
    required int offset,
    required bool canShowPrevious,
    required bool canShowNext,
    required bool isEmpty,
    required DateTime now,
  }) = StatsLoaded;

  const factory StatsState.failure(Failure failure) = StatsFailure;
}
```

`apps/pawlog/lib/presentation/stats/cubit/stats_cubit.dart`:

```dart
import 'dart:async';
import 'dart:math' as math;

import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../domain/stats/entity/stats_period.dart';
import '../../../domain/stats/policy/walk_stats_policy.dart';
import '../../../domain/walk/entity/walk.dart';
import '../../../domain/walk/usecase/walk_use_case.dart';
import 'stats_state.dart';

/// 통계 화면. 산책 스트림이 바뀌거나 기간을 옮길 때마다 [Clock] 의 지금으로 다시 계산한다 —
/// 화면을 연 채 자정을 넘기면 다음 갱신에서 새 날짜가 된다.
@injectable
class StatsCubit extends Cubit<StatsState> {
  StatsCubit(this._useCase, this._clock) : super(const StatsState.loading());

  final WalkUseCase _useCase;
  final Clock _clock;

  StreamSubscription<Result<List<Walk>>>? _subscription;
  List<Walk>? _walks;
  StatsPeriod _period = StatsPeriod.week;
  int _offset = 0;

  Future<void> start() => _watch();

  Future<void> retry() => _watch();

  /// 기간 종류를 바꾸면 지금 기간으로 돌아온다.
  void selectPeriod(StatsPeriod period) {
    if (state is! StatsLoaded || period == _period) return;
    _period = period;
    _offset = 0;
    _emitLoaded();
  }

  void showPrevious() {
    if (state is! StatsLoaded) return;
    _offset--;
    _emitLoaded();
  }

  void showNext() {
    if (state is! StatsLoaded) return;
    _offset++;
    _emitLoaded();
  }

  Future<void> _watch() async {
    // 위젯 테스트의 가짜 비동기에서 끝난 스트림의 cancel 을 기다리면 멈추므로 기다리지 않는다.
    unawaited(_subscription?.cancel());
    if (isClosed) return;

    _walks = null;
    emit(const StatsState.loading());
    _subscription = _useCase.watchWalks().listen(_onWalks);
  }

  void _onWalks(Result<List<Walk>> result) {
    if (isClosed) return;
    switch (result) {
      case Ok(value: final walks):
        _walks = walks;
        _emitLoaded();
      case Err(:final failure):
        _walks = null;
        emit(StatsState.failure(failure));
    }
  }

  void _emitLoaded() {
    final walks = _walks;
    if (walks == null || isClosed) return;
    final now = _clock.now();
    final earliest = WalkStatsPolicy.earliestOffset(walks, _period, now);
    // 미래로는 가지 않고, 삭제로 오래된 산책이 사라지면 남은 가장 오래된 기간으로 끌어올린다.
    _offset = math.max(earliest, math.min(0, _offset));
    emit(
      StatsState.loaded(
        stats: WalkStatsPolicy.periodStats(walks, _period, now, offset: _offset),
        records: WalkStatsPolicy.records(walks, now),
        offset: _offset,
        canShowPrevious: _offset > earliest,
        canShowNext: _offset < 0,
        isEmpty: walks.isEmpty,
        now: now,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
```

- [ ] **Step 4: 실패하는 cubit 테스트**

`apps/pawlog/test/presentation/stats/cubit/stats_cubit_test.dart`:

```dart
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pawlog/domain/stats/entity/stats_period.dart';
import 'package:pawlog/domain/walk/entity/walk.dart';
import 'package:pawlog/presentation/stats/cubit/stats_cubit.dart';
import 'package:pawlog/presentation/stats/cubit/stats_state.dart';

import '../../../support/fakes.dart';
import '../../../support/mock_walk_use_case.dart';

Walk _walk(String id, DateTime startedAt, {double meters = 1000}) => Walk(
  id: id,
  startedAt: startedAt,
  endedAt: startedAt.add(const Duration(minutes: 30)),
  duration: const Duration(minutes: 30),
  distanceMeters: meters,
  dogs: [dog('1')],
  photos: const [],
  previewPoints: const [],
  createdAt: startedAt,
  updatedAt: startedAt,
);

Matcher _loaded({
  int? offset,
  bool? canShowPrevious,
  bool? canShowNext,
  bool? isEmpty,
  StatsPeriod? period,
  int? walkCount,
}) {
  var matcher = isA<StatsLoaded>();
  if (offset != null) matcher = matcher.having((s) => s.offset, 'offset', offset);
  if (canShowPrevious != null) {
    matcher = matcher.having((s) => s.canShowPrevious, 'canShowPrevious', canShowPrevious);
  }
  if (canShowNext != null) {
    matcher = matcher.having((s) => s.canShowNext, 'canShowNext', canShowNext);
  }
  if (isEmpty != null) matcher = matcher.having((s) => s.isEmpty, 'isEmpty', isEmpty);
  if (period != null) {
    matcher = matcher.having((s) => s.stats.period, 'period', period);
  }
  if (walkCount != null) {
    matcher = matcher.having((s) => s.stats.summary.walkCount, 'walkCount', walkCount);
  }
  return matcher;
}

void main() {
  late MockWalkUseCase useCase;
  late StreamController<Result<List<Walk>>> walks;
  late DateTime now;

  final today = _walk('b', DateTime(2026, 10, 16, 8));
  final twoWeeksAgo = _walk('a', DateTime(2026, 9, 30, 8)); // 9-28 주

  setUp(() {
    useCase = MockWalkUseCase();
    walks = StreamController<Result<List<Walk>>>();
    now = DateTime(2026, 10, 16, 15);
    when(() => useCase.watchWalks()).thenAnswer((_) => walks.stream);
  });
  tearDown(() => walks.close());

  StatsCubit build() => StatsCubit(useCase, FakeClock(() => now));

  blocTest<StatsCubit, StatsState>(
    '첫 값이 오면 이번 주로 loaded, 다음은 비활성',
    build: build,
    act: (cubit) async {
      await cubit.start();
      walks.add(Ok([today, twoWeeksAgo]));
    },
    expect: () => [
      const StatsState.loading(),
      _loaded(offset: 0, canShowPrevious: true, canShowNext: false, isEmpty: false, walkCount: 1),
    ],
  );

  blocTest<StatsCubit, StatsState>(
    '이전은 가장 오래된 산책이 든 주에서 멈추고, 다음은 지금에서 멈춘다',
    build: build,
    act: (cubit) async {
      await cubit.start();
      walks.add(Ok([today, twoWeeksAgo]));
      await Future<void>.delayed(Duration.zero);
      cubit
        ..showPrevious()
        ..showPrevious()
        ..showPrevious() // 더는 못 간다 — 같은 상태라 내지 않는다
        ..showNext()
        ..showNext()
        ..showNext(); // 더는 못 간다
    },
    expect: () => [
      const StatsState.loading(),
      _loaded(offset: 0),
      _loaded(offset: -1, canShowPrevious: true, canShowNext: true),
      _loaded(offset: -2, canShowPrevious: false, canShowNext: true, walkCount: 1),
      _loaded(offset: -1),
      _loaded(offset: 0, canShowNext: false),
    ],
  );

  blocTest<StatsCubit, StatsState>(
    '월로 바꾸면 offset 0 으로 돌아온다',
    build: build,
    act: (cubit) async {
      await cubit.start();
      walks.add(Ok([today, twoWeeksAgo]));
      await Future<void>.delayed(Duration.zero);
      cubit
        ..showPrevious()
        ..selectPeriod(StatsPeriod.month);
    },
    expect: () => [
      const StatsState.loading(),
      _loaded(offset: 0, period: StatsPeriod.week),
      _loaded(offset: -1, period: StatsPeriod.week),
      _loaded(offset: 0, period: StatsPeriod.month, canShowPrevious: true),
    ],
  );

  blocTest<StatsCubit, StatsState>(
    '보던 과거 기간보다 오래된 산책이 지워지면 남은 가장 오래된 기간으로 끌어올린다',
    build: build,
    act: (cubit) async {
      await cubit.start();
      walks.add(Ok([today, twoWeeksAgo]));
      await Future<void>.delayed(Duration.zero);
      cubit
        ..showPrevious()
        ..showPrevious();
      walks.add(Ok([today]));
    },
    expect: () => [
      const StatsState.loading(),
      _loaded(offset: 0),
      _loaded(offset: -1),
      _loaded(offset: -2),
      _loaded(offset: 0, canShowPrevious: false, canShowNext: false),
    ],
  );

  blocTest<StatsCubit, StatsState>(
    '화면을 연 채 주가 바뀌면 다음 스트림 값에서 새 주로 계산한다',
    build: build,
    act: (cubit) async {
      await cubit.start();
      walks.add(Ok([today]));
      await Future<void>.delayed(Duration.zero);
      now = DateTime(2026, 10, 19, 0, 1); // 다음 주 월요일
      walks.add(Ok([today]));
    },
    expect: () => [
      const StatsState.loading(),
      _loaded(offset: 0, walkCount: 1),
      _loaded(offset: 0, walkCount: 0, canShowPrevious: true),
    ],
  );

  blocTest<StatsCubit, StatsState>(
    '첫 값 전의 기간 이동은 무시한다',
    build: build,
    act: (cubit) async {
      await cubit.start();
      cubit
        ..showPrevious()
        ..selectPeriod(StatsPeriod.month);
      walks.add(Ok([today]));
    },
    expect: () => [
      const StatsState.loading(),
      _loaded(offset: 0, period: StatsPeriod.week),
    ],
  );

  blocTest<StatsCubit, StatsState>(
    '산책이 없으면 isEmpty, 앞뒤 모두 비활성',
    build: build,
    act: (cubit) async {
      await cubit.start();
      walks.add(const Ok([]));
    },
    expect: () => [
      const StatsState.loading(),
      _loaded(isEmpty: true, canShowPrevious: false, canShowNext: false),
    ],
  );

  blocTest<StatsCubit, StatsState>(
    '스트림 오류는 failure, retry 는 다시 구독한다',
    build: build,
    act: (cubit) async {
      await cubit.start();
      walks.add(const Err(Failure.unknown()));
      await Future<void>.delayed(Duration.zero);
      await walks.close();
      walks = StreamController<Result<List<Walk>>>();
      await cubit.retry();
      walks.add(Ok([today]));
    },
    expect: () => [
      const StatsState.loading(),
      isA<StatsFailure>(),
      const StatsState.loading(),
      _loaded(walkCount: 1),
    ],
  );
}
```

Run: `cd apps/pawlog && dart run build_runner build --delete-conflicting-outputs && flutter test test/presentation/stats/cubit`
Expected: 처음엔 생성 전이라 FAIL, 생성 뒤 PASS.

- [ ] **Step 5: 분석 · 커밋**

Run: `cd apps/pawlog && flutter analyze && flutter test test/presentation/stats test/domain/stats`
Expected: 0건 · PASS. `lib/core/di/injection.config.dart` 에 `StatsCubit` 등록이 생겼는지 `grep -n StatsCubit lib/core/di/injection.config.dart` 로 확인.

```bash
git add apps/pawlog/lib/presentation/stats apps/pawlog/test/presentation/stats apps/pawlog/lib/core/di/injection.config.dart
git commit -m "feat(pawlog): 통계 상태와 기간 · 비교 표기를 추가한다

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: 통계 화면과 `/stats` 경로

**Files:**
- Modify: `apps/pawlog/lib/presentation/theme/pawlog_spacing.dart` (`PawlogSize` 끝에 토큰 2개)
- Create: `apps/pawlog/lib/presentation/stats/widget/period_switcher.dart`, `period_summary_view.dart`, `distance_bar_chart.dart`, `walk_records_view.dart`
- Create: `apps/pawlog/lib/presentation/stats/page/stats_page.dart`
- Modify: `apps/pawlog/lib/core/router/dogs_redirect.dart` (`PawlogPaths.stats`), `apps/pawlog/lib/core/router/app_router.dart`
- Modify: `apps/pawlog/test/support/pump_app.dart` (`theme` 인자)
- Test: `apps/pawlog/test/presentation/stats/page/stats_page_test.dart`
- Test: `apps/pawlog/test/core/router/app_router_test.dart` (케이스 2개)

**Interfaces:**
- Consumes: Task 3 의 `StatsCubit` · `StatsState` · `StatsFormat`, Task 1 의 엔티티, `PawlogColors.of` · `PawlogTextStyles.of`(`numberHero`, `number`) · `PawlogSpacing` · `PawlogSize` · `PawlogRadius` · `PawlogMotion`, `AppPlaceholder`, `getIt`
- Produces: `StatsPage({required ValueChanged<String> onOpenWalk})`, `PawlogPaths.stats = '/stats'`, 키 `stats-period-week` · `stats-period-month` · `stats-previous` · `stats-next` · `stats-range-label` · `stats-total-distance` · `stats-total-duration` · `stats-total-count` · `stats-comparison` · `stats-bar-<i>` · `stats-bar-value` · `stats-record-current-streak` · `stats-record-longest-streak` · `stats-record-farthest` · `stats-record-longest` · `stats-retry`

- [ ] **Step 1: 토큰 · 테스트 도우미**

`apps/pawlog/lib/presentation/theme/pawlog_spacing.dart` 의 `PawlogSize` 마지막(`handleHeight` 뒤)에:

```dart

  /// 통계 막대 그래프 전체 높이(값 표시 · 칸 라벨 포함).
  static const statsChart = 180.0;

  /// 구분선 · 0 인 막대의 바닥선 두께.
  static const hairline = 1.0;
```

`apps/pawlog/test/support/pump_app.dart` — `pumpApp` 에 `ThemeData? theme` 인자를 더하고 `theme: theme ?? PawlogTheme.light(),` 로 바꾼다:

```dart
Future<void> pumpApp(
  WidgetTester tester,
  Widget home, {
  bool disableAnimations = false,
  ThemeData? theme,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? PawlogTheme.light(),
```

(나머지는 그대로.)

- [ ] **Step 2: 실패하는 페이지 테스트**

`apps/pawlog/test/presentation/stats/page/stats_page_test.dart`:

```dart
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pawlog/domain/walk/entity/walk.dart';
import 'package:pawlog/presentation/stats/cubit/stats_cubit.dart';
import 'package:pawlog/presentation/stats/page/stats_page.dart';
import 'package:pawlog/presentation/theme/pawlog_theme.dart';

import '../../../support/fakes.dart';
import '../../../support/mock_walk_use_case.dart';
import '../../../support/pump_app.dart';

Walk _walk(
  String id,
  DateTime startedAt, {
  double meters = 1000,
  Duration duration = const Duration(minutes: 30),
}) => Walk(
  id: id,
  startedAt: startedAt,
  endedAt: startedAt.add(duration),
  duration: duration,
  distanceMeters: meters,
  dogs: [dog('1')],
  photos: const [],
  previewPoints: const [],
  createdAt: startedAt,
  updatedAt: startedAt,
);

void main() {
  late MockWalkUseCase useCase;

  // 금요일. 이번 주 a(월 1 km) · b(금 2.5 km), 지난주 p(800 m).
  final now = DateTime(2026, 10, 16, 15);
  final walks = [
    _walk('b', DateTime(2026, 10, 16, 8), meters: 2500, duration: const Duration(minutes: 45)),
    _walk('a', DateTime(2026, 10, 12, 7)),
    _walk('p', DateTime(2026, 10, 5, 7), meters: 800, duration: const Duration(minutes: 20)),
  ];

  setUp(() {
    useCase = MockWalkUseCase();
    when(() => useCase.watchWalks()).thenAnswer((_) => Stream.value(Ok(walks)));
    getIt.registerFactory<StatsCubit>(
      () => StatsCubit(useCase, FakeClock.fixed(now)),
    );
  });
  tearDown(getIt.reset);

  Future<void> pump(
    WidgetTester tester, {
    ValueChanged<String>? onOpenWalk,
    ThemeData? theme,
  }) => pumpApp(
    tester,
    StatsPage(onOpenWalk: onOpenWalk ?? (_) {}),
    theme: theme,
  );

  String text(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(Key(key))).data!;

  testWidgets('이번 주 요약 · 비교 · 막대 7칸이 보인다', (tester) async {
    await pump(tester);

    expect(find.text('산책 통계'), findsOneWidget);
    expect(text(tester, 'stats-range-label'), '10월 12일 – 18일');
    expect(text(tester, 'stats-total-distance'), '3.5 km');
    expect(text(tester, 'stats-total-duration'), '1시간 15분');
    expect(text(tester, 'stats-total-count'), '2번');
    expect(text(tester, 'stats-comparison'), '지난주보다 2.7 km 더 걸었어요');
    for (var i = 0; i < 7; i++) {
      expect(find.byKey(Key('stats-bar-$i')), findsOneWidget);
    }
    expect(find.byKey(const Key('stats-bar-7')), findsNothing);
    expect(find.byType(Card), findsNothing);
  });

  testWidgets('막대를 탭하면 값이 뜨고 다시 탭하면 사라진다', (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const Key('stats-bar-4')));
    await tester.pump();
    expect(text(tester, 'stats-bar-value'), '2.5 km');

    await tester.tap(find.byKey(const Key('stats-bar-4')));
    await tester.pump();
    expect(find.byKey(const Key('stats-bar-value')), findsNothing);
  });

  testWidgets('이전 주로 가면 지난주가 보이고 다음이 켜진다', (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const Key('stats-previous')));
    await tester.pumpAndSettle();

    expect(text(tester, 'stats-range-label'), '10월 5일 – 11일');
    expect(text(tester, 'stats-total-distance'), '800 m');
    expect(find.byKey(const Key('stats-comparison')), findsNothing); // 그 전 주는 0
  });

  testWidgets('월로 바꾸면 이번 달 · 주별 칸이 보인다', (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const Key('stats-period-month')));
    await tester.pumpAndSettle();

    expect(text(tester, 'stats-range-label'), '2026년 10월');
    expect(text(tester, 'stats-total-distance'), '4.3 km');
    expect(find.byKey(const Key('stats-bar-4')), findsOneWidget); // 26–31
    expect(find.byKey(const Key('stats-bar-5')), findsNothing);
  });

  testWidgets('기록 — 연속 · 최장 · 가장 먼 산책을 탭하면 상세로', (tester) async {
    String? opened;
    await pump(tester, onOpenWalk: (id) => opened = id);

    await tester.scrollUntilVisible(
      find.byKey(const Key('stats-record-longest')),
      200,
    );
    expect(find.text('연속 산책'), findsOneWidget);
    expect(find.text('1일'), findsWidgets);
    await tester.tap(find.byKey(const Key('stats-record-farthest')));
    expect(opened, 'b');
  });

  testWidgets('산책이 없으면 안내 한 장만 보인다', (tester) async {
    when(() => useCase.watchWalks()).thenAnswer((_) => Stream.value(const Ok([])));

    await pump(tester);

    expect(find.byType(AppPlaceholder), findsOneWidget);
    expect(find.text('아직 통계가 없어요'), findsOneWidget);
    expect(find.byKey(const Key('stats-period-week')), findsNothing);
  });

  testWidgets('다크 테마에서도 그려진다', (tester) async {
    await pump(tester, theme: PawlogTheme.dark());

    expect(text(tester, 'stats-total-distance'), '3.5 km');
    expect(tester.takeException(), isNull);
  });
}
```

Run: `cd apps/pawlog && flutter test test/presentation/stats/page/stats_page_test.dart`
Expected: FAIL — `stats_page.dart` 없음.

- [ ] **Step 3: 위젯 구현**

`apps/pawlog/lib/presentation/stats/widget/period_switcher.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/stats/entity/period_range.dart';
import '../../../domain/stats/entity/stats_period.dart';
import '../../theme/pawlog_theme.dart';
import '../format/stats_format.dart';

/// `[주 | 월]` 알약 토글과 그 아래 `‹ 기간 라벨 ›` 한 줄.
class PeriodSwitcher extends StatelessWidget {
  const PeriodSwitcher({
    required this.period,
    required this.range,
    required this.now,
    required this.canShowPrevious,
    required this.canShowNext,
    required this.onSelect,
    required this.onPrevious,
    required this.onNext,
    super.key,
  });

  final StatsPeriod period;
  final PeriodRange range;
  final DateTime now;
  final bool canShowPrevious;
  final bool canShowNext;
  final ValueChanged<StatsPeriod> onSelect;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = PawlogColors.of(context);
    final theme = Theme.of(context);

    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: PawlogRadius.fullAll,
            border: Border.all(color: colors.rule),
          ),
          child: Padding(
            padding: const EdgeInsets.all(PawlogSpacing.xs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (value, label) in [
                  (StatsPeriod.week, l10n.walkStatsWeek),
                  (StatsPeriod.month, l10n.walkStatsMonth),
                ])
                  _Segment(
                    key: Key('stats-period-${value.name}'),
                    label: label,
                    selected: value == period,
                    onTap: () => onSelect(value),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: PawlogSpacing.md),
        Row(
          children: [
            _Arrow(
              key: const Key('stats-previous'),
              icon: Icons.chevron_left,
              tooltip: l10n.walkStatsPreviousTooltip,
              enabled: canShowPrevious,
              onPressed: onPrevious,
            ),
            Expanded(
              child: Text(
                StatsFormat.rangeLabel(l10n.localeName, period, range, now),
                key: const Key('stats-range-label'),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
            ),
            _Arrow(
              key: const Key('stats-next'),
              icon: Icons.chevron_right,
              tooltip: l10n.walkStatsNextTooltip,
              enabled: canShowNext,
              onPressed: onNext,
            ),
          ],
        ),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = PawlogColors.of(context);
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: AnimatedContainer(
          duration: PawlogMotion.off(context) ? Duration.zero : PawlogMotion.state,
          curve: PawlogMotion.move,
          decoration: BoxDecoration(
            color: selected ? colors.primary : null,
            borderRadius: PawlogRadius.fullAll,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: PawlogSpacing.lg,
            vertical: PawlogSpacing.sm,
          ),
          child: Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              color: selected ? colors.onPrimary : colors.text,
            ),
          ),
        ),
      ),
    );
  }
}

/// 비활성은 주 버튼 비활성과 같은 투명도로 흐리게 남긴다.
class _Arrow extends StatelessWidget {
  const _Arrow({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = PawlogColors.of(context);
    return Opacity(
      opacity: enabled ? 1 : PawlogMotion.disabledOpacity,
      child: IconButton(
        icon: Icon(icon),
        color: colors.primary,
        disabledColor: colors.primary,
        tooltip: tooltip,
        onPressed: enabled ? onPressed : null,
      ),
    );
  }
}
```

`apps/pawlog/lib/presentation/stats/widget/period_summary_view.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/stats/entity/period_stats.dart';
import '../../theme/pawlog_theme.dart';
import '../../walk/format/walk_format.dart';
import '../format/stats_format.dart';

/// 기간 요약 — 거리 히어로 숫자 하나 + 시간 · 횟수, 그리고 지난 기간 비교 한 줄.
class PeriodSummaryView extends StatelessWidget {
  const PeriodSummaryView({required this.stats, super.key});

  final PeriodStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = PawlogColors.of(context);
    final styles = PawlogTextStyles.of(context);
    final theme = Theme.of(context);
    final summary = stats.summary;
    final comparison = StatsFormat.comparison(l10n, stats);
    final label = theme.textTheme.labelMedium?.copyWith(color: colors.textMuted);
    // 0건 기간의 시간은 '1분 미만' 이 아니라 0분이다.
    final duration = summary.walkCount == 0
        ? l10n.walkDurationMinutes(0)
        : WalkFormat.duration(l10n, summary.duration);

    Widget figure(String name, String value, Key key) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: label),
        Text(value, key: key, style: styles.number),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.walkStatsDistanceLabel, style: label),
        Text(
          WalkFormat.distance(l10n, summary.distanceMeters),
          key: const Key('stats-total-distance'),
          style: styles.numberHero,
        ),
        if (comparison != null) ...[
          const SizedBox(height: PawlogSpacing.xs),
          Text(
            comparison,
            key: const Key('stats-comparison'),
            style: theme.textTheme.bodyLarge?.copyWith(color: colors.textMuted),
          ),
        ],
        const SizedBox(height: PawlogSpacing.lg),
        Row(
          children: [
            Expanded(
              child: figure(
                l10n.walkStatsDurationLabel,
                duration,
                const Key('stats-total-duration'),
              ),
            ),
            Expanded(
              child: figure(
                l10n.walkStatsCountLabel,
                l10n.walkStatsCountValue(summary.walkCount),
                const Key('stats-total-count'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
```

`apps/pawlog/lib/presentation/stats/widget/distance_bar_chart.dart`:

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/stats/entity/stats_bucket.dart';
import '../../../domain/stats/entity/stats_period.dart';
import '../../theme/pawlog_theme.dart';
import '../../walk/format/walk_format.dart';
import '../format/stats_format.dart';

/// 거리 막대. 남색 막대, 0 인 칸은 바닥선만 — 연두는 쓰지 않는다(design.md Colors).
///
/// 막대가 자라는 연출은 없다 — 앱의 연출은 경로 그리기 하나다. 칸을 탭하면 그 위에 값이 뜨고,
/// 다른 칸을 탭하면 옮겨 가고, 같은 칸을 다시 탭하면 사라진다.
class DistanceBarChart extends StatefulWidget {
  const DistanceBarChart({
    required this.period,
    required this.buckets,
    super.key,
  });

  final StatsPeriod period;
  final List<StatsBucket> buckets;

  @override
  State<DistanceBarChart> createState() => _DistanceBarChartState();
}

class _DistanceBarChartState extends State<DistanceBarChart> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final maxDistance = widget.buckets.fold<double>(
      0,
      (max, bucket) => math.max(max, bucket.distanceMeters),
    );
    return SizedBox(
      height: PawlogSize.statsChart,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < widget.buckets.length; i++)
            Expanded(child: _bar(context, i, maxDistance)),
        ],
      ),
    );
  }

  Widget _bar(BuildContext context, int index, double maxDistance) {
    final l10n = AppLocalizations.of(context);
    final colors = PawlogColors.of(context);
    final theme = Theme.of(context);
    final bucket = widget.buckets[index];
    final label = StatsFormat.bucketLabel(
      l10n.localeName,
      widget.period,
      bucket.range,
    );
    final distance = WalkFormat.distance(l10n, bucket.distanceMeters);
    final fraction = maxDistance == 0 ? 0.0 : bucket.distanceMeters / maxDistance;
    final selected = _selected == index;
    final labelStyle = theme.textTheme.labelMedium?.copyWith(
      color: colors.textMuted,
    );

    return Semantics(
      label: l10n.walkStatsBarSemantics(label, distance),
      button: true,
      selected: selected,
      excludeSemantics: true,
      child: GestureDetector(
        key: Key('stats-bar-$index'),
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _selected = selected ? null : index),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: PawlogSpacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: PawlogSpacing.lg,
                child: selected
                    ? FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          distance,
                          key: const Key('stats-bar-value'),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.primary,
                          ),
                        ),
                      )
                    : null,
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => Align(
                    alignment: Alignment.bottomCenter,
                    child: fraction == 0
                        ? SizedBox(
                            height: PawlogSize.hairline,
                            width: double.infinity,
                            child: ColoredBox(color: colors.rule),
                          )
                        : SizedBox(
                            // 아주 짧은 산책도 보이도록 바닥선 두 배는 남긴다.
                            height: math.max(
                              constraints.maxHeight * fraction,
                              PawlogSize.hairline * 2,
                            ),
                            width: double.infinity,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: colors.primary,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(PawlogRadius.photo),
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: PawlogSpacing.sm),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label, style: labelStyle, maxLines: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

`apps/pawlog/lib/presentation/stats/widget/walk_records_view.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/stats/entity/walk_records.dart';
import '../../../domain/walk/entity/walk.dart';
import '../../theme/pawlog_theme.dart';
import '../../walk/format/walk_format.dart';

/// 전체 기간의 기록 — 카드 없이 `rule` 선으로 나눈 줄글. 산책 두 줄은 탭하면 상세로 간다.
class WalkRecordsView extends StatelessWidget {
  const WalkRecordsView({
    required this.records,
    required this.onOpenWalk,
    super.key,
  });

  final WalkRecords records;
  final ValueChanged<String> onOpenWalk;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final farthest = records.farthest;
    final longest = records.longest;
    String date(Walk walk) =>
        DateFormat.yMMMd(l10n.localeName).format(walk.startedAt.toLocal());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.walkStatsRecordsTitle, style: theme.textTheme.titleLarge),
        const SizedBox(height: PawlogSpacing.sm),
        _RecordRow(
          key: const Key('stats-record-current-streak'),
          label: l10n.walkStatsCurrentStreak,
          value: l10n.walkStatsDays(records.currentStreakDays),
        ),
        _RecordRow(
          key: const Key('stats-record-longest-streak'),
          label: l10n.walkStatsLongestStreak,
          value: l10n.walkStatsDays(records.longestStreakDays),
        ),
        if (farthest != null)
          _RecordRow(
            key: const Key('stats-record-farthest'),
            label: l10n.walkStatsFarthestWalk,
            detail: date(farthest),
            value: WalkFormat.distance(l10n, farthest.distanceMeters),
            onTap: () => onOpenWalk(farthest.id),
          ),
        if (longest != null)
          _RecordRow(
            key: const Key('stats-record-longest'),
            label: l10n.walkStatsLongestWalk,
            detail: date(longest),
            value: WalkFormat.duration(l10n, longest.duration),
            onTap: () => onOpenWalk(longest.id),
          ),
      ],
    );
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({
    required this.label,
    required this.value,
    this.detail,
    this.onTap,
    super.key,
  });

  final String label;
  final String value;
  final String? detail;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = PawlogColors.of(context);
    final styles = PawlogTextStyles.of(context);
    final theme = Theme.of(context);
    final detail = this.detail;

    return InkWell(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.rule)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: PawlogSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                    if (detail != null)
                      Text(detail, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Text(value, style: styles.number),
              if (onTap != null)
                Icon(Icons.chevron_right, color: colors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
```

`apps/pawlog/lib/presentation/stats/page/stats_page.dart`:

```dart
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../theme/pawlog_theme.dart';
import '../cubit/stats_cubit.dart';
import '../cubit/stats_state.dart';
import '../widget/distance_bar_chart.dart';
import '../widget/period_summary_view.dart';
import '../widget/period_switcher.dart';
import '../widget/walk_records_view.dart';

/// 주 · 월 산책 통계. 라우팅은 모르고 상세로 가는 콜백만 받는다.
class StatsPage extends StatelessWidget {
  const StatsPage({required this.onOpenWalk, super.key});

  final ValueChanged<String> onOpenWalk;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<StatsCubit>()..start(),
    child: _StatsView(onOpenWalk: onOpenWalk),
  );
}

class _StatsView extends StatelessWidget {
  const _StatsView({required this.onOpenWalk});

  final ValueChanged<String> onOpenWalk;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<StatsCubit>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.walkStatsTitle)),
      body: SafeArea(
        child: BlocBuilder<StatsCubit, StatsState>(
          builder: (context, state) => switch (state) {
            StatsLoading() => const Center(child: CircularProgressIndicator()),
            StatsFailure(:final failure) => Center(
              child: AppPlaceholder(
                message: failure.localizedMessage(context),
                actionLabel: l10n.commonRetry,
                actionKey: const Key('stats-retry'),
                onAction: cubit.retry,
              ),
            ),
            StatsLoaded(isEmpty: true) => Center(
              child: AppPlaceholder(
                message: l10n.walkStatsEmptyTitle,
                description: l10n.walkStatsEmptyMessage,
              ),
            ),
            StatsLoaded(
              :final stats,
              :final records,
              :final canShowPrevious,
              :final canShowNext,
              :final now,
            ) =>
              ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: PawlogSize.gutter,
                  vertical: PawlogSpacing.lg,
                ),
                children: [
                  PeriodSwitcher(
                    period: stats.period,
                    range: stats.range,
                    now: now,
                    canShowPrevious: canShowPrevious,
                    canShowNext: canShowNext,
                    onSelect: cubit.selectPeriod,
                    onPrevious: cubit.showPrevious,
                    onNext: cubit.showNext,
                  ),
                  const SizedBox(height: PawlogSpacing.xl),
                  // 기간이 바뀌면 키가 바뀌어 막대 선택도 풀린다.
                  AnimatedSwitcher(
                    duration: PawlogMotion.off(context)
                        ? Duration.zero
                        : PawlogMotion.state,
                    child: Column(
                      key: ValueKey((stats.period, stats.range.start)),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PeriodSummaryView(stats: stats),
                        const SizedBox(height: PawlogSpacing.xl),
                        DistanceBarChart(
                          period: stats.period,
                          buckets: stats.buckets,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: PawlogSpacing.xxl),
                  WalkRecordsView(records: records, onOpenWalk: onOpenWalk),
                ],
              ),
          },
        ),
      ),
    );
  }
}
```

`failure.localizedMessage` 의 import 는 피드 페이지(`lib/presentation/feed/page/walk_feed_page.dart`)와 같다 — 그 파일의 import 세트(`core` · `design_system` · `l10n`)로 컴파일되지 않으면 피드 페이지 import 를 그대로 따른다.

- [ ] **Step 4: 페이지 테스트 통과 확인**

Run: `cd apps/pawlog && flutter test test/presentation/stats/page/stats_page_test.dart`
Expected: PASS. `'1일'` 은 연속 · 최장 두 줄 모두라 `findsWidgets` 다.

- [ ] **Step 5: 경로 — 실패하는 라우터 테스트**

`apps/pawlog/test/core/router/app_router_test.dart`:
- import 에 `package:pawlog/presentation/stats/cubit/stats_cubit.dart` · `package:pawlog/presentation/stats/page/stats_page.dart` 추가
- `setUp` 의 `getIt` 캐스케이드에 `..registerFactory<StatsCubit>(() => StatsCubit(useCase, const Clock()))` 추가
- 케이스 추가:

```dart
  testWidgets('/stats 로 가면 통계 화면이 뜬다', (tester) async {
    final router = await pumpRouter(tester);

    router.go('/stats');
    await tester.pumpAndSettle();

    expect(find.byType(StatsPage), findsOneWidget);
    expect(path(router), '/stats');
    await dispose(tester);
  });

  testWidgets('반려견이 없으면 /stats 도 /dogs/new 로 간다', (tester) async {
    final router = await pumpRouter(tester, hasDogs: false);

    router.go('/stats');
    await tester.pumpAndSettle();

    expect(find.byType(DogEditPage), findsOneWidget);
    expect(path(router), '/dogs/new');
    await dispose(tester);
  });
```

Run: `cd apps/pawlog && flutter test test/core/router/app_router_test.dart`
Expected: 첫 케이스 FAIL(경로 없음).

- [ ] **Step 6: 경로 추가**

`apps/pawlog/lib/core/router/dogs_redirect.dart` 의 `PawlogPaths` 에 `newDog` 다음 줄:

```dart
  static const stats = '/stats';
```

`apps/pawlog/lib/core/router/app_router.dart`: import `'../../presentation/stats/page/stats_page.dart';` 를 더하고, `routes:` 의 `PawlogPaths.dogs` `GoRoute` 앞에:

```dart
      GoRoute(
        path: PawlogPaths.stats,
        builder: (context, _) => StatsPage(
          onOpenWalk: (id) => context.push(PawlogPaths.walk(id)),
        ),
      ),
```

Run: `cd apps/pawlog && flutter test test/core/router test/presentation/stats`
Expected: PASS.

- [ ] **Step 7: 분석 · 토큰 검사 · 커밋**

Run: `cd apps/pawlog && flutter analyze && grep -rnE "Colors\.|BorderRadius\.circular|EdgeInsets\.(all|symmetric|only)\([^P)]*[0-9]" lib/presentation/stats`
Expected: analyze 0건, grep 결과 없음.

```bash
git add apps/pawlog/lib/presentation/stats apps/pawlog/lib/presentation/theme/pawlog_spacing.dart apps/pawlog/lib/core/router apps/pawlog/test/presentation/stats apps/pawlog/test/core/router/app_router_test.dart apps/pawlog/test/support/pump_app.dart
git commit -m "feat(pawlog): 주 · 월 산책 통계 화면을 추가한다

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: 피드 맨 위 이번 주 요약 줄

**Files:**
- Create: `apps/pawlog/lib/presentation/feed/widget/week_summary_line.dart`
- Modify: `apps/pawlog/lib/presentation/feed/cubit/walk_feed_state.dart`, `walk_feed_cubit.dart`
- Modify: `apps/pawlog/lib/presentation/feed/page/walk_feed_page.dart`
- Modify: `apps/pawlog/lib/core/router/app_router.dart`
- Test: `apps/pawlog/test/presentation/feed/cubit/walk_feed_cubit_test.dart`, `apps/pawlog/test/presentation/feed/page/walk_feed_page_test.dart`, `apps/pawlog/test/core/router/app_router_test.dart`

**Interfaces:**
- Consumes: `WalkStatsPolicy.periodStats` · `PeriodSummary` · `StatsPeriod` (Task 1), `walkFeedWeekSummary` · `walkFeedWeekSummaryEmpty` (Task 2), `PawlogPaths.stats` (Task 4)
- Produces: `WalkFeedState.loaded({required List<Walk> walks, required TrackerState tracker, @Default(PeriodSummary.empty) PeriodSummary weekSummary})`, `WalkFeedCubit(WalkUseCase useCase, Clock clock)`, `WalkFeedPage({…, required VoidCallback onOpenStats})`, `WeekSummaryLine({required PeriodSummary summary, required VoidCallback onTap})`, 키 `walk-feed-week-summary`

- [ ] **Step 1: 기존 테스트를 새 생성자에 맞추고 실패하는 테스트 추가**

`test/presentation/feed/cubit/walk_feed_cubit_test.dart`:
- 모든 `WalkFeedCubit(useCase)` 를 `WalkFeedCubit(useCase, clock)` 으로 바꾸고, `main()` 맨 위에 `final clock = FakeClock.fixed(DateTime(2026, 12, 1));` — `walk()` 의 `t0`(2026-10-03)가 이번 주 밖이라 기존 기대값의 `weekSummary` 가 기본값 `PeriodSummary.empty` 와 같다
- import `package:pawlog/domain/stats/entity/period_summary.dart`
- 케이스 추가:

```dart
  blocTest<WalkFeedCubit, WalkFeedState>(
    '이번 주 요약을 시계 기준으로 싣고, 추적 상태가 바뀌어도 유지한다',
    setUp: () => when(
      () => useCase.watchWalks(),
    ).thenAnswer((_) {
      Future<void>.delayed(
        const Duration(milliseconds: 5),
        () => trackerController.add(TrackerState.tracking(session)),
      );
      return Stream.value(Ok([walk()]));
    }),
    // t0 = 2026-10-03(토) 09:00 → 같은 주의 일요일
    build: () => WalkFeedCubit(useCase, FakeClock.fixed(DateTime(2026, 10, 4, 12))),
    act: (cubit) async {
      await cubit.start();
      await Future<void>.delayed(const Duration(milliseconds: 20));
    },
    expect: () {
      const summary = PeriodSummary(
        distanceMeters: 1200,
        duration: Duration(minutes: 30),
        walkCount: 1,
      );
      return [
        const WalkFeedState.loading(),
        WalkFeedState.loaded(
          walks: [walk()],
          tracker: const TrackerState.idle(),
          weekSummary: summary,
        ),
        WalkFeedState.loaded(
          walks: [walk()],
          tracker: TrackerState.tracking(session),
          weekSummary: summary,
        ),
      ];
    },
  );
```

`test/presentation/feed/page/walk_feed_page_test.dart`:
- `getIt.registerFactory<WalkFeedCubit>(() => WalkFeedCubit(useCase))` → `WalkFeedCubit(useCase, FakeClock.fixed(DateTime(2026, 10, 3, 12)))` (`_walk` 의 기본 `t0` 와 같은 주)
- `pump` 에 `VoidCallback? onOpenStats` 인자, `WalkFeedPage(…, onOpenStats: onOpenStats ?? () {})`
- 케이스 추가:

```dart
  testWidgets('타임라인 위에 이번 주 요약 줄, 탭하면 통계로', (tester) async {
    var opened = 0;
    await pump(tester, onOpenStats: () => opened++);

    expect(find.text('이번 주 1.2 km · 1번'), findsOneWidget);
    await tester.tap(find.byKey(const Key('walk-feed-week-summary')));
    expect(opened, 1);
  });

  testWidgets('이번 주 산책이 없으면 아직 전이라고 말한다', (tester) async {
    when(() => useCase.watchWalks()).thenAnswer(
      (_) => Stream.value(Ok([_walk('old', startedAt: DateTime(2026, 9, 1, 9))])),
    );

    await pump(tester);

    expect(find.text('이번 주는 아직 산책 전이에요'), findsOneWidget);
  });

  testWidgets('빈 피드에는 요약 줄이 없다', (tester) async {
    when(() => useCase.watchWalks()).thenAnswer((_) => Stream.value(const Ok([])));

    await pump(tester);

    expect(find.byKey(const Key('walk-feed-week-summary')), findsNothing);
  });
```

`test/core/router/app_router_test.dart`: `WalkFeedCubit(useCase)` → `WalkFeedCubit(useCase, const Clock())`.

Run: `cd apps/pawlog && flutter test test/presentation/feed test/core/router`
Expected: FAIL — 생성자 인자 · `weekSummary` · `onOpenStats` 가 없어 컴파일 오류.

- [ ] **Step 2: 상태 · cubit**

`apps/pawlog/lib/presentation/feed/cubit/walk_feed_state.dart` — import `'../../../domain/stats/entity/period_summary.dart';`, `loaded` 를:

```dart
  /// [walks] 는 최신순. [tracker] 로 배너 · FAB 를 정한다. [weekSummary] 는 맨 위 요약 줄.
  const factory WalkFeedState.loaded({
    required List<Walk> walks,
    required TrackerState tracker,
    @Default(PeriodSummary.empty) PeriodSummary weekSummary,
  }) = WalkFeedLoaded;
```

`apps/pawlog/lib/presentation/feed/cubit/walk_feed_cubit.dart`:
- import `'../../../domain/stats/entity/period_summary.dart';` · `'../../../domain/stats/entity/stats_period.dart';` · `'../../../domain/stats/policy/walk_stats_policy.dart';`
- 생성자 `WalkFeedCubit(this._useCase, this._clock) : super(const WalkFeedState.loading());`, 필드 `final Clock _clock;` · `PeriodSummary _weekSummary = PeriodSummary.empty;`
- `_onWalks` 의 `Ok` 분기:

```dart
      case Ok(value: final walks):
        _walks = walks;
        _weekSummary = WalkStatsPolicy.periodStats(
          walks,
          StatsPeriod.week,
          _clock.now(),
        ).summary;
        emit(
          WalkFeedState.loaded(
            walks: walks,
            tracker: _tracker,
            weekSummary: _weekSummary,
          ),
        );
```

- `_onTracker` 의 emit:

```dart
    emit(
      WalkFeedState.loaded(
        walks: walks,
        tracker: tracker,
        weekSummary: _weekSummary,
      ),
    );
```

- [ ] **Step 3: 요약 줄 위젯 · 페이지 · 라우터**

`apps/pawlog/lib/presentation/feed/widget/week_summary_line.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/stats/entity/period_summary.dart';
import '../../theme/pawlog_theme.dart';
import '../../walk/format/walk_format.dart';

/// 피드 타임라인 위의 '이번 주' 한 줄. 누를 수 있는 것이라 남색 글자에 화살표.
class WeekSummaryLine extends StatelessWidget {
  const WeekSummaryLine({
    required this.summary,
    required this.onTap,
    super.key,
  });

  final PeriodSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = PawlogColors.of(context);
    final theme = Theme.of(context);
    final text = summary.walkCount == 0
        ? l10n.walkFeedWeekSummaryEmpty
        : l10n.walkFeedWeekSummary(
            WalkFormat.distance(l10n, summary.distanceMeters),
            summary.walkCount,
          );

    return InkWell(
      key: const Key('walk-feed-week-summary'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: PawlogSize.gutter,
          vertical: PawlogSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.primary,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: colors.primary),
          ],
        ),
      ),
    );
  }
}
```

`apps/pawlog/lib/presentation/feed/page/walk_feed_page.dart`:
- import `'../widget/week_summary_line.dart';`
- `WalkFeedPage` · `_WalkFeedView` 둘 다에 `required this.onOpenStats` 와 `final VoidCallback onOpenStats;`, `WalkFeedPage.build` 에서 `_WalkFeedView(…, onOpenStats: onOpenStats)` 로 넘긴다
- `WalkFeedLoaded(:final walks, :final tracker)` → `WalkFeedLoaded(:final walks, :final tracker, :final weekSummary)`
- `Column` children 에서 `_banner(tracker),` 바로 다음 줄:

```dart
                if (walks.isNotEmpty)
                  WeekSummaryLine(summary: weekSummary, onTap: onOpenStats),
```

`apps/pawlog/lib/core/router/app_router.dart` 의 피드 `GoRoute` builder 에 `onOpenStats: () => context.push(PawlogPaths.stats),` 를 `onOpenDogs` 다음에 더한다.

- [ ] **Step 4: 생성 · 테스트 통과**

Run: `cd apps/pawlog && dart run build_runner build --delete-conflicting-outputs && flutter test`
Expected: 전체 PASS(기존 `+253` + 새 테스트). `injection.config.dart` 의 `WalkFeedCubit` 가 `gh<Clock>()` 을 받는지 확인.

- [ ] **Step 5: 분석 · 커밋**

Run: `cd apps/pawlog && flutter analyze` → 0건

```bash
git add apps/pawlog/lib/presentation/feed apps/pawlog/lib/core apps/pawlog/test/presentation/feed apps/pawlog/test/core/router/app_router_test.dart
git commit -m "feat(pawlog): 피드 맨 위에 이번 주 요약 줄을 둔다

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: 검증 · 문서

**Files:**
- Create: `apps/pawlog/docs/features/stats/history.md`, `apps/pawlog/docs/features/stats/testing.md`
- Modify: `apps/pawlog/docs/features/stats/plan.md` (상태 줄), `apps/pawlog/docs/status.md`, `apps/pawlog/docs/README.md` (W6 행만 추가 — 기존 미커밋 `design.md` 행은 사용자 것이니 스테이징하지 않는다; README 를 커밋해야 하면 사용자에게 먼저 묻는다), `apps/pawlog/docs/overview.md` §5 교차 관심사 표는 그대로
- Modify: `docs/status.md` 의 pawlog 행

- [ ] **Step 1: 전체 검증**

```bash
cd apps/pawlog && flutter analyze && flutter test && flutter build apk --debug
cd ../../packages/l10n && flutter analyze && flutter test
cd ../../apps/trader && flutter test test/convention
```

Expected: analyze 0건 · 모두 PASS · APK 빌드 성공. 실패하면 고치고 다시 — 결과 숫자를 기록해 둔다.

- [ ] **Step 2: 에뮬레이터 확인** (`anthropic-skills:android-emulator` 스킬)

[plan.md 완료 조건](../../../apps/pawlog/docs/features/stats/plan.md#완료-조건)의 다섯 시나리오. 산책은 기존 QA 처럼 `adb emu geo fix` 로 경로를 흘려 2~3건 만든다. 시나리오별 PASS/FAIL 과 고친 것을 적는다. 환경이 없으면 "미실행" 으로 남긴다.

- [ ] **Step 3: 문서**

- `history.md`: 단계 커밋 표(①~⑤ 해시), 스펙과 다르게 간 것 — 막대를 `CustomPainter` 대신 위젯으로(탭 · Semantics), `StatsLoaded.now` 추가(기간 라벨 연도), 0건 기간 시간 `0분`, `PawlogSize.statsChart` · `hairline`
- `testing.md`: 단위 · 위젯 · 라우터 테스트 목록과 수, "에뮬레이터" 표(시나리오 ① ~ ⑤)
- `plan.md` 상태 줄: `구현 완료 2026-10-16 (<마지막 커밋>) · 에뮬레이터 <결과>`
- `apps/pawlog/docs/status.md`: 단계 요약 행 상태, "W6 stats" 절 체크박스와 검증 숫자
- `docs/status.md` pawlog 행: `… W6 stats 완료`

Run: `cd apps/trader && flutter test test/convention` → PASS

- [ ] **Step 4: 커밋**

```bash
git add apps/pawlog/docs/features/stats apps/pawlog/docs/status.md docs/status.md
git commit -m "docs(pawlog): W6 stats 구현 기록과 테스트를 남긴다

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
