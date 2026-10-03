# 걷기 앱 시각 · 인터랙션 강화 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 걷기 앱(Life Tool)에 초록 톤 테마, 하루 목표 링, 애니메이션 그래프, 다듬은 알람 · 설정 · 셸을 입힌다.

**Architecture:** 공유 `AppTheme` 에 `seedColor` 인자만 더하고, 나머지(시드 · 모션 값 · 목표 도메인 · 위젯)는 전부 `apps/walk` 안에 둔다. 목표는 기존 `AppSettings`/`PrefsSettingsRepository` 에 필드 둘을 더해 저장하고, 앱 전역 `StepGoalCubit` 이 걷기 · 설정 탭에 같은 값을 준다. 애니메이션은 Flutter 기본(`TweenAnimationBuilder` · `AnimatedSwitcher` · `CustomPainter` · `AnimationController`)만 쓴다.

**Tech Stack:** Flutter 3 / Dart 3.11, flutter_bloc, freezed 3, shared_preferences, injectable/get_it, mocktail, bloc_test.

**Spec:** [docs/superpowers/specs/2026-10-03-walk-visual-refresh-design.md](../specs/2026-10-03-walk-visual-refresh-design.md) — 실행자는 스펙과 이 계획을 함께 읽는다.

## Global Constraints

- 새 의존성 추가 금지(pubspec 변경 없음).
- 화면에 `Colors.*` · hex · 숫자 여백 · `BorderRadius.circular(n)` 금지 — `Theme.of(context).colorScheme` · `AppSpacing` · `AppRadius` 사용. 공통 위젯(`AppButton` · `AppListTile` · `AppPlaceholder` · `AppSnackBar`)이 있으면 그것을 쓴다(CLAUDE.md UI 규칙).
- walk 전용 코드는 `apps/walk` 안에. 공유 패키지 변경은 `AppTheme` 인자(Task 1)와 l10n 키(Task 3)뿐.
- Freezed 는 Primary Constructor 패턴(기존 `AppSettings` 처럼 `@override final` 필드 + const 생성자). 분기는 `switch` 패턴.
- `.freezed.dart` · `.g.dart` · `injection.config.dart` 는 `dart run build_runner build --delete-conflicting-outputs` 로만 갱신(`apps/walk` 에서).
- l10n 생성 파일은 `packages/l10n` 에서 `flutter gen-l10n` 으로만 갱신.
- 모든 연출은 `MediaQuery.of(context).disableAnimations` 가 참이면 끝 상태로 즉시 그리고, 반복 애니메이션은 돌리지 않는다.
- 기존 위젯 키(`walk-today-steps`, `walk-bar-selection`, `walk-bar-yyyy-MM-dd`, `alarm-summary-remaining`, `alarm-summary-when`) 유지.
- 테스트 위치는 구현 구조를 그대로 따른다(`lib/x/y.dart` ↔ `test/x/y_test.dart`).
- 커밋 메시지는 한국어 conventional(`feat(walk): …`), 끝에 `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- 각 Task 끝: `apps/walk` 에서 `flutter analyze` 0 issue, `flutter test` 전부 통과.

## File Structure

| 파일 | 책임 |
|---|---|
| `packages/design_system/lib/src/theme/app_theme.dart` (수정) | `seedColor` 인자 |
| `apps/walk/lib/presentation/theme/walk_theme.dart` (신규) | walk 시드 · light/dark |
| `apps/walk/lib/presentation/theme/walk_motion.dart` (신규) | 시간 · 곡선 상수, `animationsOff(context)` |
| `apps/walk/lib/domain/walk/entity/step_goal.dart` (신규) | 목표 범위 상수 · clamp |
| `apps/walk/lib/domain/walk/entity/goal_progress.dart` (신규) | 비율 · 달성 · 남은 양 · `shouldCelebrate` |
| `apps/walk/lib/domain/settings/entity/app_settings.dart` (수정) | `stepGoal` · `goalCelebratedOn` |
| `apps/walk/lib/data/settings/prefs_settings_repository.dart` (수정) | 새 키 읽기/쓰기 |
| `apps/walk/lib/presentation/walk/cubit/step_goal_cubit.dart` (신규) | 앱 전역 목표 상태 |
| `apps/walk/lib/presentation/walk/widget/step_goal_ring.dart` (신규) | 링 painter + 애니메이션 |
| `apps/walk/lib/presentation/walk/widget/goal_celebration.dart` (신규) | 파티클 1회 연출 |
| `apps/walk/lib/presentation/walk/widget/today_goal_card.dart` (신규, `today_activity_card.dart` 삭제) | 오늘 카드 |
| `apps/walk/lib/presentation/walk/widget/walk_skeleton.dart` (신규) | shimmer 자리표시 |
| `apps/walk/lib/presentation/walk/widget/activity_bar_chart.dart` (수정) | 목표선 · 성장 · 색 |
| `apps/walk/lib/presentation/walk/widget/period_summary.dart` (수정) | 달성 n/m · 타일 |
| `apps/walk/lib/presentation/walk/widget/period_section.dart` · `page/walk_home_page.dart` (수정) | 조립 · 세그먼트 · 축하 판정 |
| `apps/walk/lib/presentation/settings/widget/step_goal_sheet.dart` (신규) | 목표 바텀시트 |
| `apps/walk/lib/presentation/settings/page/settings_page.dart` (수정) | 걷기 섹션 · 헤더 색 |
| `apps/walk/lib/presentation/alarm/widget/ringing_ripple.dart` (신규) | 울림 파동 |
| 알람 요약 · 타일 · 울림 화면 · 셸 (수정) | 톤 맞춤 |

---

### Task 1: 초록 테마와 모션 토대

**Files:**
- Modify: `packages/design_system/lib/src/theme/app_theme.dart`
- Test: `packages/design_system/test/theme/app_theme_test.dart` (없으면 생성)
- Create: `apps/walk/lib/presentation/theme/walk_theme.dart`, `apps/walk/lib/presentation/theme/walk_motion.dart`
- Modify: `apps/walk/lib/core/app.dart` (`AppTheme.light()` → `WalkTheme.light()`, dark 동일)
- Test: `apps/walk/test/presentation/theme/walk_theme_test.dart`

**Interfaces:**
- Produces: `AppTheme.light({Color seedColor = AppColors.seed})`, `AppTheme.dark({Color seedColor = AppColors.seed})`; `WalkTheme.seed`, `WalkTheme.light()`, `WalkTheme.dark()`; `WalkMotion.short/medium/long/celebrate` (`Duration`), `WalkMotion.emphasized` (`Curve`), `WalkMotion.off(BuildContext) → bool`.

- [ ] **Step 1: 실패 테스트**

```dart
// packages/design_system/test/theme/app_theme_test.dart
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('인자 없이 부르면 기존 시드로 만든다', () {
    final expected = ColorScheme.fromSeed(seedColor: AppColors.seed);
    expect(AppTheme.light().colorScheme.primary, expected.primary);
  });

  test('넘긴 시드가 scheme 에 반영된다', () {
    const seed = Color(0xFF1D9E75);
    final expected = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark);
    expect(AppTheme.dark(seedColor: seed).colorScheme.primary, expected.primary);
  });
}
```

```dart
// apps/walk/test/presentation/theme/walk_theme_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/presentation/theme/walk_motion.dart';
import 'package:walk/presentation/theme/walk_theme.dart';

void main() {
  test('walk 테마는 초록 시드다', () {
    expect(
      WalkTheme.light().colorScheme.primary,
      ColorScheme.fromSeed(seedColor: WalkTheme.seed).primary,
    );
  });

  testWidgets('애니메이션 끄기를 읽는다', (tester) async {
    late bool off;
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: Builder(builder: (context) { off = WalkMotion.off(context); return const SizedBox(); }),
    ));
    expect(off, isTrue);
  });
}
```

- [ ] **Step 2: 실패 확인** — `cd packages/design_system && flutter test test/theme/app_theme_test.dart` → 컴파일 에러(`seedColor` 없음). `cd apps/walk && flutter test test/presentation/theme` → import 에러.

- [ ] **Step 3: 구현**

`app_theme.dart`: `light({Color seedColor = AppColors.seed}) => _base(Brightness.light, seedColor)`, `dark` 동일, `_base(Brightness brightness, Color seedColor)` 에서 `ColorScheme.fromSeed(seedColor: seedColor, ...)`.

```dart
// apps/walk/lib/presentation/theme/walk_theme.dart
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// 걷기 앱 톤 — 청록빛 초록. 다른 앱과 공유하지 않으므로 design_system 이 아니라 여기 둔다.
abstract final class WalkTheme {
  static const seed = Color(0xFF1D9E75);

  static ThemeData light() => AppTheme.light(seedColor: seed);
  static ThemeData dark() => AppTheme.dark(seedColor: seed);
}
```

```dart
// apps/walk/lib/presentation/theme/walk_motion.dart
import 'package:flutter/animation.dart';
import 'package:flutter/widgets.dart';

/// 걷기 앱 연출 시간 · 곡선. design_system 에 모션 토큰이 없어 앱 안에 둔다.
abstract final class WalkMotion {
  static const short = Duration(milliseconds: 200);
  static const medium = Duration(milliseconds: 400);
  static const long = Duration(milliseconds: 900);
  static const celebrate = Duration(milliseconds: 1200);
  static const emphasized = Curves.easeOutCubic;

  /// 시스템 "애니메이션 제거" — 참이면 연출은 끝 상태로 바로 그리고 반복은 돌리지 않는다.
  static bool off(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}
```

`app.dart`: `theme: WalkTheme.light(), darkTheme: WalkTheme.dark()` 와 import.

- [ ] **Step 4: 통과 확인** — 두 패키지 테스트 + `apps/walk` 전체 `flutter test`, `flutter analyze`.
- [ ] **Step 5: 커밋** — `feat(walk): 초록 시드 테마와 모션 상수를 더한다` (design_system 변경 포함).

---

### Task 2: 하루 목표 — 도메인 · 저장 · cubit

**Files:**
- Create: `apps/walk/lib/domain/walk/entity/step_goal.dart`, `apps/walk/lib/domain/walk/entity/goal_progress.dart`
- Modify: `apps/walk/lib/domain/settings/entity/app_settings.dart`, `apps/walk/lib/data/settings/prefs_settings_repository.dart`
- Create: `apps/walk/lib/presentation/walk/cubit/step_goal_cubit.dart`
- Modify: `apps/walk/lib/core/app.dart` (`MultiBlocProvider` 로 `ThemeCubit` 과 `StepGoalCubit` 제공, dispose 에서 close)
- Test: `apps/walk/test/domain/walk/entity/goal_progress_test.dart`, `apps/walk/test/data/settings/prefs_settings_repository_test.dart`(기존 파일에 추가), `apps/walk/test/presentation/walk/cubit/step_goal_cubit_test.dart`, `apps/walk/test/presentation/settings/cubit/theme_cubit_test.dart`(기존에 1건 추가, 없으면 생성)

**Interfaces:**
- Produces:
  - `abstract final class StepGoal { static const defaultSteps = 10000, min = 2000, max = 30000, step = 1000; static int clamp(int value); }` — clamp 는 범위 안으로 자르고 `step` 단위로 반올림.
  - `class GoalProgress { final int steps; final int goal; double get ratio; bool get reached; int get remainingSteps; int get overSteps; double? remainingMeters(double? distanceMeters); }` (Freezed 단일 모델)
  - `bool shouldCelebrate({required int steps, required int goal, required DateTime today, DateTime? lastCelebratedOn})`
  - `AppSettings({themeMode, int stepGoal = StepGoal.defaultSteps, DateTime? goalCelebratedOn})`
  - `PrefsSettingsRepository.stepGoalKey = 'walk.stepGoal'`, `goalCelebratedOnKey = 'walk.goalCelebratedOn'`
  - `class StepGoalCubit extends Cubit<int> { StepGoalCubit(SettingsRepository); Future<void> select(int goal); }`

- [ ] **Step 1: 실패 테스트 — 도메인**

```dart
// apps/walk/test/domain/walk/entity/goal_progress_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/walk/entity/goal_progress.dart';
import 'package:walk/domain/walk/entity/step_goal.dart';

void main() {
  group('StepGoal.clamp', () {
    test('범위 밖은 끝값으로', () {
      expect(StepGoal.clamp(500), StepGoal.min);
      expect(StepGoal.clamp(99999), StepGoal.max);
    });
    test('1,000 단위로 반올림', () => expect(StepGoal.clamp(7499), 7000));
  });

  group('GoalProgress', () {
    test('0보', () {
      const p = GoalProgress(steps: 0, goal: 10000);
      expect(p.ratio, 0);
      expect(p.reached, isFalse);
      expect(p.remainingSteps, 10000);
      expect(p.remainingMeters(null), isNull);
      expect(p.remainingMeters(0), isNull);
    });
    test('정확히 목표면 달성, 남은 0', () {
      const p = GoalProgress(steps: 10000, goal: 10000);
      expect(p.reached, isTrue);
      expect(p.remainingSteps, 0);
      expect(p.overSteps, 0);
    });
    test('초과는 비율 1 초과 · overSteps', () {
      const p = GoalProgress(steps: 12500, goal: 10000);
      expect(p.ratio, 1.25);
      expect(p.overSteps, 2500);
    });
    test('남은 거리는 오늘 보폭으로', () {
      const p = GoalProgress(steps: 5000, goal: 10000);
      expect(p.remainingMeters(3500), closeTo(3500, 0.001)); // 0.7m × 5000
    });
  });

  group('shouldCelebrate', () {
    final today = DateTime(2026, 10, 3);
    test('달성 + 축하 기록 없음', () =>
        expect(shouldCelebrate(steps: 10000, goal: 10000, today: today), isTrue));
    test('어제 축하했으면 오늘 다시', () => expect(
        shouldCelebrate(steps: 10000, goal: 10000, today: today, lastCelebratedOn: DateTime(2026, 10, 2)),
        isTrue));
    test('오늘 이미 축하', () => expect(
        shouldCelebrate(steps: 20000, goal: 10000, today: today, lastCelebratedOn: today),
        isFalse));
    test('미달', () => expect(shouldCelebrate(steps: 9999, goal: 10000, today: today), isFalse));
  });
}
```

- [ ] **Step 2: 실패 확인** — `flutter test test/domain/walk/entity/goal_progress_test.dart` → import 에러.

- [ ] **Step 3: 구현 — 도메인**

```dart
// step_goal.dart
/// 하루 걸음 목표의 범위. 설정 슬라이더와 저장소 clamp 가 같은 값을 쓴다.
abstract final class StepGoal {
  static const defaultSteps = 10000;
  static const min = 2000;
  static const max = 30000;
  static const step = 1000;

  static int clamp(int value) =>
      ((value.clamp(min, max) / step).round() * step).clamp(min, max);
}
```

```dart
// goal_progress.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'goal_progress.freezed.dart';

/// 오늘 걸음과 목표의 관계. 비율은 1 을 넘을 수 있다(링은 1 에서 멈추고 숫자만 넘친다).
@freezed
class GoalProgress with _$GoalProgress {
  @override
  final int steps;
  @override
  final int goal;

  const GoalProgress({required this.steps, required this.goal});

  double get ratio => goal <= 0 ? 0 : steps / goal;
  bool get reached => steps >= goal;
  int get remainingSteps => reached ? 0 : goal - steps;
  int get overSteps => reached ? steps - goal : 0;

  /// 오늘 거리 ÷ 오늘 걸음을 보폭으로 남은 걸음에 곱한다. 걸음 0 · 거리 없음 · 0m 이면 null.
  double? remainingMeters(double? distanceMeters) {
    if (steps == 0 || distanceMeters == null || distanceMeters <= 0) return null;
    return remainingSteps * distanceMeters / steps;
  }
}

/// 달성했고 오늘 아직 축하하지 않았으면 참. 날짜는 자정 기준으로 비교한다.
bool shouldCelebrate({
  required int steps,
  required int goal,
  required DateTime today,
  DateTime? lastCelebratedOn,
}) {
  if (steps < goal) return false;
  if (lastCelebratedOn == null) return true;
  // domain 은 Flutter(DateUtils)에 기대지 않는다.
  return lastCelebratedOn.year != today.year ||
      lastCelebratedOn.month != today.month ||
      lastCelebratedOn.day != today.day;
}
```

- [ ] **Step 4: 통과 확인** — build_runner 후 테스트.

- [ ] **Step 5: 실패 테스트 — 저장 · cubit**

기존 `test/data/settings/prefs_settings_repository_test.dart` 에 추가(파일의 기존 setUp 패턴 — `SharedPreferences.setMockInitialValues` — 을 따른다):

```dart
test('목표 · 축하일 왕복', () async {
  await repo.save(AppSettings(stepGoal: 8000, goalCelebratedOn: DateTime(2026, 10, 3)));
  final s = repo.load();
  expect(s.stepGoal, 8000);
  expect(s.goalCelebratedOn, DateTime(2026, 10, 3));
});
test('저장값이 없으면 기본 목표 · 축하일 없음', () {
  expect(repo.load().stepGoal, StepGoal.defaultSteps);
  expect(repo.load().goalCelebratedOn, isNull);
});
test('깨진 타입 · 범위 밖은 기본/clamp', () async {
  SharedPreferences.setMockInitialValues({
    PrefsSettingsRepository.stepGoalKey: 'x',
    PrefsSettingsRepository.goalCelebratedOnKey: 42,
  });
  final broken = PrefsSettingsRepository(await SharedPreferences.getInstance());
  expect(broken.load().stepGoal, StepGoal.defaultSteps);
  expect(broken.load().goalCelebratedOn, isNull);

  SharedPreferences.setMockInitialValues({PrefsSettingsRepository.stepGoalKey: 99999});
  final big = PrefsSettingsRepository(await SharedPreferences.getInstance());
  expect(big.load().stepGoal, StepGoal.max);
});
test('축하일 null 저장은 키를 지운다', () async {
  await repo.save(AppSettings(goalCelebratedOn: DateTime(2026, 10, 3)));
  await repo.save(const AppSettings());
  expect(repo.load().goalCelebratedOn, isNull);
});
```

`theme_cubit_test.dart` 에: 목표 8000 저장 후 `ThemeCubit.select(dark)` → `repo.load().stepGoal == 8000`.

```dart
// test/presentation/walk/cubit/step_goal_cubit_test.dart
// fake SettingsRepository(메모리) 로:
// - 초기 state == load().stepGoal
// - select(7499) → emits [7000], 저장된 stepGoal 7000, 다른 필드(themeMode) 유지
// - select(현재값) → emit 없음
```
(fake 는 `class _MemorySettings implements SettingsRepository { AppSettings value; ... }` 로 같은 파일에 둔다.)

- [ ] **Step 6: 실패 확인** → **Step 7: 구현**

`AppSettings` 에 필드 추가(Primary Constructor, `@override final int stepGoal; @override final DateTime? goalCelebratedOn;`, 기본값 `StepGoal.defaultSteps`). `PrefsSettingsRepository.load`: `_prefs.get(stepGoalKey)` 가 `int` 면 `StepGoal.clamp`, 아니면 기본; `goalCelebratedOnKey` 가 `String` 이면 `DateTime.tryParse`, 아니면 null. `save`: `setInt(stepGoalKey, …)`, 축하일이 있으면 `setString(…, 'yyyy-MM-dd')`(intl 없이 `toIso8601String().substring(0, 10)`), null 이면 `remove`.

```dart
// step_goal_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/settings/repository/settings_repository.dart';
import '../../../domain/walk/entity/step_goal.dart';

/// 하루 걸음 목표. `MaterialApp` 위에 두어 걷기 탭과 설정 탭이 같은 값을 본다.
class StepGoalCubit extends Cubit<int> {
  StepGoalCubit(this._repository) : super(_repository.load().stepGoal);

  final SettingsRepository _repository;

  Future<void> select(int goal) async {
    final next = StepGoal.clamp(goal);
    if (next == state) return;
    emit(next);
    await _repository.save(_repository.load().copyWith(stepGoal: next));
  }
}
```

`app.dart`: `late final _goal = StepGoalCubit(getIt<SettingsRepository>());`, `BlocProvider.value(value: _theme)` → `MultiBlocProvider(providers: [BlocProvider.value(value: _theme), BlocProvider.value(value: _goal)], …)`, dispose 에서 `_goal.close()`.

- [ ] **Step 8: 통과 확인** — build_runner, 전체 테스트, analyze.
- [ ] **Step 9: 커밋** — `feat(walk): 하루 걸음 목표를 저장하고 앱 전역으로 제공한다`.

---

### Task 3: 문자열

**Files:** Modify `packages/l10n/lib/l10n/app_{ko,en,ja}.arb`, 재생성 `app_localizations*.dart`.

**Interfaces — Produces (키 · ko 값 · placeholder):**

| 키 | ko | 인자 |
|---|---|---|
| `walkGoalOf` | `목표 {goal}` | goal: String |
| `walkGoalRemaining` | `목표까지 {steps}` | steps: String (이미 `walkStepsCount` 로 포맷한 값) |
| `walkGoalRemainingWithDistance` | `목표까지 {steps} · 약 {distance}` | steps, distance: String |
| `walkGoalExceeded` | `목표보다 {steps} 더 걸었어요` | steps: String |
| `walkGoalReached` | `달성` | — |
| `walkGoalDaysReached` | `달성 {reached}/{total}일` | reached, total: int |
| `walkGoalOfPercent` | `목표 {percent}%` | percent: int |
| `walkGoalRingSemantics` | `오늘 {steps}, 목표 {goal}의 {percent}%` | steps, goal: String, percent: int |
| `walkGoalLine` | `목표` | — |
| `walkSettingsWalk` | `걷기` | — |
| `walkSettingsStepGoal` | `하루 목표` | — |
| `walkSettingsStepGoalSave` | `저장` | — |

en: `Goal {goal}` · `{steps} to go` · `{steps} to go · about {distance}` · `{steps} past your goal` · `Done` · `Goal met {reached}/{total} days` · `{percent}% of goal` · `{steps} today, {percent}% of {goal} goal` · `Goal` · `Walking` · `Daily goal` · `Save`.
ja: `目標 {goal}` · `目標まで {steps}` · `目標まで {steps} · 約 {distance}` · `目標より {steps} 多く歩きました` · `達成` · `達成 {reached}/{total}日` · `目標の {percent}%` · `今日 {steps}、目標 {goal} の {percent}%` · `目標` · `ウォーキング` · `1日の目標` · `保存`.

- [ ] **Step 1:** 세 ARB 에 기존 `walkStepsCount` 형식(`@key` description · placeholders)을 따라 추가.
- [ ] **Step 2:** `cd packages/l10n && flutter gen-l10n`.
- [ ] **Step 3:** `packages/l10n` 테스트 · `apps/walk` analyze 통과.
- [ ] **Step 4: 커밋** — `feat(l10n): 걷기 목표 문자열을 더한다`.

---

### Task 4: 오늘 목표 카드 · 링 · 축하 · 스켈레톤 · 홈 조립

**Files:**
- Create: `lib/presentation/walk/widget/step_goal_ring.dart`, `goal_celebration.dart`, `today_goal_card.dart`, `walk_skeleton.dart`
- Delete: `lib/presentation/walk/widget/today_activity_card.dart` (+ 그 테스트가 있으면 `today_goal_card_test.dart` 로 옮겨 갱신)
- Modify: `lib/presentation/walk/page/walk_home_page.dart`
- Test: `test/presentation/walk/widget/today_goal_card_test.dart`, `test/presentation/walk/widget/step_goal_ring_test.dart`, `test/presentation/walk/page/walk_home_page_test.dart`(갱신)

**Interfaces:**
- Consumes: `GoalProgress`, `shouldCelebrate`, `StepGoalCubit`(context 의 `BlocBuilder<StepGoalCubit, int>`), `SettingsRepository`(getIt), `WalkMotion`, Task 3 문자열.
- Produces:
  - `StepGoalRing({required double ratio, required Widget child, double size = AppSpacing.xl * 6})` — 진입 시 0→ratio, 이후 이전 ratio→새 ratio. `Key('walk-goal-ring')` 는 카드가 감싸는 `GestureDetector` 에 둔다.
  - `GoalCelebration({required bool play, required Widget child})` — `play` 가 참으로 처음 들어온 순간 1회 파티클 + `HapticFeedback.mediumImpact()`.
  - `TodayGoalCard({required DailyActivity activity, required int goal, bool celebrate = false})`
  - `WalkSkeleton({required double height})`

- [ ] **Step 1: 실패 테스트** (모든 pump 는 `MediaQuery(data: MediaQueryData(disableAnimations: true))` + `MaterialApp(localizationsDelegates/supportedLocales, locale: Locale('ko'))` 로 감싸는 `_pump` 헬퍼):

```dart
// today_goal_card_test.dart 핵심 케이스
testWidgets('걸음 · 목표 문구와 링 접근성 비율', (tester) async {
  await _pump(tester, TodayGoalCard(
    activity: DailyActivity(date: DateTime(2026, 10, 3), steps: 7240, distanceMeters: 5068, activeKcal: 212),
    goal: 10000,
  ));
  expect(find.byKey(const Key('walk-today-steps')), findsOneWidget);
  expect(find.text('7,240 걸음'), findsOneWidget);
  expect(find.text('목표 10,000 걸음'), findsOneWidget);
  expect(find.bySemanticsLabel(RegExp('72%')), findsOneWidget);
  expect(find.text('달성'), findsNothing);
});

testWidgets('링을 누르면 남은 걸음 · 거리, 다시 누르면 지표로', (tester) async {
  // 7240보 / 5068m → 보폭 0.7m, 남은 2760보 ≈ 1.9km
  ...
  await tester.tap(find.byKey(const Key('walk-goal-ring')));
  await tester.pumpAndSettle();
  expect(find.textContaining('목표까지 2,760 걸음'), findsOneWidget);
  expect(find.textContaining('약 1.9'), findsOneWidget);
  await tester.tap(find.byKey(const Key('walk-goal-ring')));
  await tester.pumpAndSettle();
  expect(find.textContaining('목표까지'), findsNothing);
});

testWidgets('거리가 없으면 남은 걸음만', ...);           // distanceMeters: null → '목표까지 2,760 걸음' 만, '약' 없음
testWidgets('달성이면 배지와 초과 문구', ...);             // steps 12500 → '달성' 배지, 탭하면 '목표보다 2,500 걸음 더 걸었어요'
testWidgets('3초 뒤 지표로 돌아온다', ...);               // 탭 → pump(Duration(seconds: 3)) → pumpAndSettle → '목표까지' 없음
```

```dart
// walk_home_page_test.dart 에 추가 (기존 mock 구성 + getIt 에 메모리 SettingsRepository 등록 + StepGoalCubit 을 BlocProvider 로)
testWidgets('처음 달성하면 축하 날짜를 저장하고, 같은 날 다시 열면 연출하지 않는다', ...);
// today() 가 steps 10000(목표 10000) 반환 → 첫 pump 후 settings.load().goalCelebratedOn == 오늘(자정)
// find.byType(GoalCelebration) 의 play == true.
// 같은 settings 로 위젯을 새로 만들어 pump → play == false.
testWidgets('목표를 바꾸면 카드 목표 문구가 바뀐다', ...); // StepGoalCubit.select(8000) → '목표 8,000 걸음'
testWidgets('주간 | 월간 세그먼트로 전환', ...);          // find.byType(SegmentedButton<PeriodKind>), '월간' 탭 → month cubit 결과 표시
```

`step_goal_ring_test.dart`: 애니메이션 켠 상태에서 ratio 0.5 pump → `pump(WalkMotion.long ~/ 2)` 시점 painter 의 진행이 0 과 0.5 사이, `pumpAndSettle` 뒤 0.5; ratio 를 0.8 로 바꿔 다시 pump 한 첫 프레임에 진행이 0.5 근처(0 부터가 아님) — painter 는 `@visibleForTesting double get progress` 로 노출.

- [ ] **Step 2: 실패 확인**

- [ ] **Step 3: 구현 지침**
  - `StepGoalRing`: `TweenAnimationBuilder<double>(tween: Tween(begin: _previous, end: ratio.clamp(0, 1)), duration: off ? Duration.zero : WalkMotion.long, curve: WalkMotion.emphasized, onEnd: () => _previous = ratio.clamp(0,1))` — StatefulWidget 이 `_previous` 를 들고 `didUpdateWidget` 에서 직전 끝값을 begin 으로. Painter: 트랙 `colorScheme.surfaceContainerHighest`(카드 바탕 위에서 보이도록 `onPrimaryContainer` 의 낮은 알파가 아니라 scheme 역할만 사용 — 대비가 약하면 `surface`), 진행 `colorScheme.primary`, `strokeWidth: AppSpacing.md`, `StrokeCap.round`, 12시 방향 시작. ratio ≥ 1 이면 끝 캡 없는 완전한 원.
  - 숫자 카운트업: 같은 `TweenAnimationBuilder<int>`(IntTween) 로 `walk-today-steps` Text 를 그린다. 최종 프레임 문자열이 기존과 같아야 기존 테스트가 통과한다.
  - `GoalCelebration`: `AnimationController(duration: WalkMotion.celebrate)`, `didUpdateWidget`/`initState` 에서 `play && !_played` 일 때 `forward(from: 0)` + 햅틱, 끄기 모드면 햅틱만. Painter: 16개 점, 각도 `2π·i/16`, 반지름 `ring 반지름 → +AppSpacing.xl` 로 이동, 알파 1→0, 색 `primary`/`tertiary` 번갈아.
  - `TodayGoalCard`: `Card(color: scheme.primaryContainer, margin: EdgeInsets.zero)` + `Padding(AppSpacing.lg)`. 위 오른쪽 `달성` 배지는 `reached` 일 때만(`AnimatedScale` 등장, 아이콘 `Icons.check_circle`, 글자 `labelLarge`, 색 `onPrimaryContainer`). 가운데 `GestureDetector(key: Key('walk-goal-ring'), onTap: _toggle)` → `GoalCelebration` → `StepGoalRing` 안 `Column(걸음 Text, walkGoalOf Text)`. 아래 `AnimatedSwitcher(duration: WalkMotion.short)` 로 지표 행(거리 · 칼로리, 기존 `_Metric`) ↔ 남은 양 한 줄. 남은 양 표시 중 `Timer(Duration(seconds: 3))` 로 복귀, dispose 에서 cancel. 남은 거리 포맷은 `WalkFormat.distance`. 글자색은 `onPrimaryContainer`(보조는 같은 색 `withValues(alpha: .72)` 대신 `textTheme.bodySmall` + `onPrimaryContainer` 유지).
  - `WalkSkeleton`: `AnimationController(duration: Duration(milliseconds: 1400))..repeat()` (끄기 모드면 repeat 안 함), `ShaderMask` 대신 `DecoratedBox` 의 `LinearGradient`(색 `surfaceContainerHighest` ↔ `surfaceContainerLow`, `GradientTransform` 으로 x 이동), 모서리 `AppRadius.md`(없으면 있는 토큰 중 카드에 맞는 것).
  - `WalkHomePage`:
    - 로딩: `TodayActivityLoading` → `WalkSkeleton(height: AppSpacing.xl * 9)`.
    - `TodayActivityLoaded` 를 `BlocConsumer` 로 바꿔 listener 에서 축하 판정: `final settings = getIt<SettingsRepository>(); final s = settings.load(); final today = DateUtils.dateOnly(activity.date);` → `shouldCelebrate(...)` 참이면 `setState(() => _celebrate = true)` 와 `settings.save(s.copyWith(goalCelebratedOn: today))`. 목표는 `context.watch<StepGoalCubit>().state` (목표가 바뀌어 새로 달성해도 같은 판정을 `BlocListener<StepGoalCubit,int>` 에서 한 번 더 한다).
    - `DefaultTabController + TabBar` → `SegmentedButton<PeriodKind>(segments: [week, month], selected: {_kind}, onSelectionChanged: (s) => setState(() => _kind = s.first), showSelectedIcon: false)` 를 `Center` 로.
    - `PeriodSection` 을 `AnimatedSwitcher(duration: WalkMotion.medium, transitionBuilder: 페이드 + SlideTransition(Offset(0, 0.04)→0))` 로 감싼다(키는 기존 `ValueKey(_kind)`).
- [ ] **Step 4: 통과 확인** — 전체 테스트, analyze.
- [ ] **Step 5: 커밋** — `feat(walk): 오늘 카드를 목표 링과 달성 연출로 바꾼다`.

---

### Task 5: 막대그래프 목표선 · 성장 · 기간 요약

**Files:**
- Modify: `lib/presentation/walk/widget/activity_bar_chart.dart`, `period_summary.dart`, `period_section.dart`(목표 전달)
- Test: `test/presentation/walk/widget/activity_bar_chart_test.dart`(갱신), `test/presentation/walk/widget/period_summary_test.dart`

**Interfaces:**
- Consumes: `StepGoalCubit`(PeriodSection 에서 `context.watch`), `WalkMotion`, `walkGoalLine` · `walkGoalOfPercent` · `walkGoalDaysReached`.
- Produces: `ActivityBarChart({required ActivityPeriod period, required int goal})`, `PeriodSummary({required ActivityPeriod period, required int goal})`, 키 `walk-goal-line`, `walk-goal-days`.

- [ ] **Step 1: 실패 테스트**

```dart
// activity_bar_chart_test.dart 추가
testWidgets('목표선이 있고, 높이 기준은 max(최댓값, 목표)', (tester) async {
  // days 최댓값 4000, goal 8000 → 4000 인 막대의 높이 == 차트 높이 × 0.5
  ...
  expect(find.byKey(const Key('walk-goal-line')), findsOneWidget);
  final bar = tester.getSize(find.byKey(const Key('walk-bar-2026-09-21')));
  expect(bar.height, closeTo(ActivityBarChart.chartHeight * 0.5, 1));
});
testWidgets('달성일은 primary, 미달일은 primaryContainer', ...); // BoxDecoration.color 비교
testWidgets('선택 줄에 목표 % 가 붙는다', ...);                 // 8120/10000 → '… · 8,120 걸음 · 목표 81%'
```
(`_chartHeight` 를 `@visibleForTesting static const chartHeight` 로 공개.)

```dart
// period_summary_test.dart
testWidgets('달성 n/m일 — 오늘 이후는 세지 않는다', ...);
// 주간, today = 수요일, 월 12000 · 화 3000 · 수 10000 · 목~일 0, goal 10000 → '달성 2/3일'
testWidgets('네 지표 타일', ...); // 총 걸음 · 일평균 · 거리 · 칼로리 라벨과 값
```

- [ ] **Step 2: 실패 확인**
- [ ] **Step 3: 구현 지침**
  - 차트: `Stack` 안에 막대 `Row` 와 목표선. 목표선은 `Positioned(bottom: chartHeight × goal/scale)` 의 `CustomPaint`(점선, `outline`, 1px) + 오른쪽 끝 `walkGoalLine` 라벨(`labelSmall`, `outline`). `scale = max(maxSteps, goal)`.
  - 성장: 차트를 `StatefulWidget` 의 `AnimationController(duration: 기간 막대 수에 따라 WalkMotion.medium + 지연)` 하나로 돌리고 막대 i 는 `Interval(start_i, end_i, curve: WalkMotion.emphasized)` — `start_i = min(i × 30ms, 900ms) / total`. `period.start` 가 바뀌거나 새로 만들어질 때 `forward(from: 0)`. 끄기 모드면 `value = 1`. 막대 높이 = 목표 높이 × 진행.
  - 색: `day.steps >= goal ? primary : primaryContainer`; 오늘은 `Border.all(color: primary, width: 2)`(`AppSpacing` 에 2px 토큰이 없으면 `BorderSide` 기본 width 상수를 파일 상수로 둔다); 선택은 `AnimatedScale(scale: 1.06, duration: WalkMotion.short)`, 탭 시 `HapticFeedback.selectionClick()`.
  - 선택 줄 끝에 ` · ${l10n.walkGoalOfPercent((steps * 100 / goal).round())}`.
  - `PeriodSummary`: 위 `walkGoalDaysReached(reached, elapsed)` (`Key('walk-goal-days')`, `titleMedium`, `primary`), 아래 `GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: NeverScrollableScrollPhysics(), childAspectRatio: 2.4)` 대신 `Row`×2 + `Expanded` 로 2×2 `_MetricTile`(아이콘 `directions_walk` · `calendar_today` · `straighten` · `local_fire_department`, 바탕 `surfaceContainerLow`, 모서리 `AppRadius` 토큰, 값 `titleMedium`, 라벨 `bodySmall`+`onSurfaceVariant`).
- [ ] **Step 4: 통과 확인** → **Step 5: 커밋** — `feat(walk): 그래프에 목표선과 막대 성장 연출을 더한다`.

---

### Task 6: 설정 — 하루 목표 시트

**Files:**
- Create: `lib/presentation/settings/widget/step_goal_sheet.dart`
- Modify: `lib/presentation/settings/page/settings_page.dart`
- Test: `test/presentation/settings/widget/step_goal_sheet_test.dart`, `test/presentation/settings/page/settings_page_test.dart`(갱신)

**Interfaces:**
- Consumes: `StepGoalCubit`, `StepGoal`, `walkSettingsWalk` · `walkSettingsStepGoal` · `walkSettingsStepGoalSave` · `walkStepsCount`.
- Produces: `StepGoalSheet.show(BuildContext context, {required int initial}) → Future<int?>`; 키 `settings-step-goal`(행), `step-goal-slider`, `step-goal-save`.

- [ ] **Step 1: 실패 테스트**

```dart
testWidgets('걷기 섹션의 하루 목표 행이 현재 목표를 보여준다', ...); // '10,000 걸음'
testWidgets('슬라이더를 옮기고 저장하면 cubit 과 행이 바뀐다', (tester) async {
  ...
  await tester.tap(find.byKey(const Key('settings-step-goal')));
  await tester.pumpAndSettle();
  final slider = tester.widget<Slider>(find.byKey(const Key('step-goal-slider')));
  slider.onChanged!(8000);
  await tester.pump();
  expect(find.text('8,000 걸음'), findsWidgets); // 시트 미리보기
  await tester.tap(find.byKey(const Key('step-goal-save')));
  await tester.pumpAndSettle();
  expect(goalCubit.state, 8000);
  expect(find.text('8,000 걸음'), findsOneWidget); // 행
});
testWidgets('저장하지 않고 닫으면 그대로', ...);
```

- [ ] **Step 2: 실패 확인**
- [ ] **Step 3: 구현** — `showModalBottomSheet<int>(showDragHandle: true, …)`; 내용: 큰 숫자(`displaySmall`, `primary`, `walkStepsCount`), `Slider(min: StepGoal.min, max: StepGoal.max, divisions: (max-min)/step, value)`, 값 바뀔 때 `HapticFeedback.selectionClick()`, 하단 `AppButton.primary(label: walkSettingsStepGoalSave, onPressed: () => Navigator.pop(context, value))`. `settings_page.dart`: 맨 위 `_SectionHeader(l10n.walkSettingsWalk)` + `AppListTile(key: Key('settings-step-goal'), leading: Icon(Icons.flag_outlined), title: walkSettingsStepGoal, trailing: Text(walkStepsCount(...)), onTap: … select)`. `_SectionHeader` 는 `labelLarge` + `colorScheme.primary`.
- [ ] **Step 4: 통과 확인** → **Step 5: 커밋** — `feat(walk): 설정에서 하루 목표를 바꾼다`.

---

### Task 7: 알람 · 울림 · 셸 톤 맞춤

**Files:**
- Create: `lib/presentation/alarm/widget/ringing_ripple.dart`
- Modify: `lib/presentation/alarm/widget/alarm_summary_card.dart`, `alarm_tile.dart`, `lib/presentation/alarm/page/alarm_ringing_page.dart`, `lib/presentation/shell/page/main_shell_page.dart`
- Test: 각 기존 테스트 갱신 + `test/presentation/alarm/widget/ringing_ripple_test.dart`

**Interfaces:**
- Consumes: `WalkMotion`.
- Produces: `RingingRipple({required Widget child})`.

- [ ] **Step 1: 실패 테스트**
  - `ringing_ripple_test`: 켠 상태에서 `pump(Duration(milliseconds: 600))` 두 번 사이 painter `phase` 가 변한다; `disableAnimations: true` 면 `tester.hasRunningAnimations == false`.
  - `alarm_summary_card_test`: `Card.color == scheme.primaryContainer`; `now` 를 1분 늘려 다시 pump 하면 `AnimatedSwitcher` 아래 새 남은 시간 텍스트(키 `alarm-summary-remaining` 은 마지막 child 에) 확인.
  - `alarm_tile_test`: 꺼진 알람의 시각 Text 색 == `onSurfaceVariant`, 켜진 알람은 기본색.
  - `main_shell_page_test`: 아이콘 쌍 — 알람 `icon: Icons.alarm_outlined` / `selectedIcon: Icons.alarm`, 설정 `Icons.settings_outlined` / `Icons.settings`, 걷기는 outlined 변형이 없어 `Icons.directions_walk` 하나(indicator 로 구분). 각 `NavigationDestination` 의 `icon` · `selectedIcon` 을 확인한다.
- [ ] **Step 2: 실패 확인**
- [ ] **Step 3: 구현**
  - `RingingRipple`: `AnimationController(duration: Duration(milliseconds: 2400))..repeat()`(끄기 모드면 시작 안 함), painter 는 위상 `(t + k/3) % 1` 인 원 3개, 반지름 `child 반지름 → +AppSpacing.xl * 3`, 알파 `.35 → 0`, 색 `primary`.
  - 울림 화면: `Scaffold(backgroundColor: scheme.primaryContainer)`, 아이콘을 `RingingRipple` 로 감싸고 시각 · 라벨 글자색 `onPrimaryContainer`. 버튼 · 동작 그대로. 기존 `alarm_ringing_page_test` 의 `pumpAndSettle` 은 `disableAnimations: true` 헬퍼로 감싼다.
  - 요약 카드: `Card(color: primaryContainer)`, 글자 `onPrimaryContainer`(남은 시간은 `primary` 대신 `onPrimaryContainer` 굵게), 남은 시간 Text 를 `AnimatedSwitcher(duration: WalkMotion.short, transitionBuilder: SlideTransition(아래→위) + Fade)` 로, child key 는 `ValueKey(문자열)` 이고 Text 자체 key 는 기존 유지.
  - 타일: 꺼짐이면 시각 · 요일 Text 에 `color: onSurfaceVariant`; `onToggle` 감싸서 `HapticFeedback.selectionClick()` 후 호출.
  - 셸: `selectedIcon` 지정(위 쌍). `IndexedStack` 유지, 탭 전환 페이드 없음(스펙 §5).
- [ ] **Step 4: 통과 확인** → **Step 5: 커밋** — `feat(walk): 알람 · 울림 · 셸을 초록 톤으로 맞춘다`.

---

### Task 8: 기기 확인과 문서

- [ ] **Step 1:** `cd apps/walk && flutter analyze && flutter test` · `cd packages/design_system && flutter test` · `cd apps/trader && flutter test test/convention` · `cd apps/walk && flutter build apk --debug`.
- [ ] **Step 2:** 에뮬레이터(`android-emulator` 스킬)에서 앱 실행, 스크린샷: 걷기 탭 라이트/다크, 링 탭 남은 양, 달성 상태(목표를 2,000 으로 낮춰 확인), 설정 목표 시트, 알람 탭, 울림 화면(테스트 알람 1분 뒤). 스크린샷은 스크래치패드에 둔다.
- [ ] **Step 3:** 문서 — `apps/walk/docs/status.md` 에 "시각 강화" 단계와 커밋 · 검증 결과, `plan.md` 에 목표 · 화면 변화, `history.md` 에 판단(셸 페이드 생략 이유, 축하 하루 1회, 보폭 추정), `testing.md` 에 새 테스트 파일 범위, `README.md` 설계 표에 이 스펙 링크.
- [ ] **Step 4: 커밋** — `docs(walk): 시각 · 인터랙션 강화를 문서에 반영한다`.
