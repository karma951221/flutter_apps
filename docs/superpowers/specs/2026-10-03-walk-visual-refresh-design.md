# 걷기 앱 — 시각 · 인터랙션 강화 설계

> [걷기 허브](../../../apps/walk/docs/README.md) · [걷기 진행 현황](../../../apps/walk/docs/status.md) ·
> [걷기 설계](2026-09-27-walk-app-design.md) · [알람 설계](2026-09-27-walk-alarm-design.md)

2026-10-03 브레인스토밍. 사용자 결정: 범위는 **앱 전체 톤 + 걷기 탭 집중**, 오늘 카드 중심은
**목표 링**(기본 10,000보, 설정에서 변경), 톤은 **상쾌한 초록**, 테마는 `AppTheme` 에
`seedColor` 인자, 애니메이션은 **Flutter 기본만**(새 의존성 없음). 섹션 3 과 세부 연출은
"디자인은 알아서" 위임에 따라 기본안으로 정했다.

## 1. 목표와 범위

- 목표: 밋밋한 기본 `Card` + 숫자 화면을, 진행 상태가 한눈에 보이고 만지면 반응하는 화면으로.
- 범위: `apps/walk` 의 걷기 · 알람 · 설정 탭과 셸, `packages/design_system` 의 `AppTheme` 인자 하나.
- 범위 밖: 새 화면, 알람 편집 화면 레이아웃, 울림 로직, 연속 달성일(스트릭), 위젯/알림의 목표 표시,
  trader · commute · pawlog 의 시각 변화(인자 기본값이 지금과 같다).

## 2. 테마

- `AppTheme.light({Color seedColor = AppColors.seed})` · `dark(...)` — 기본값이 지금 시드라 다른 앱은
  그대로다. design_system 테스트에 "인자 없이 부르면 기존 시드" · "넘긴 시드가 scheme 에 반영" 두 건.
- walk 시드는 `apps/walk/lib/presentation/theme/walk_theme.dart` 의 `WalkTheme.seed`
  (`Color(0xFF1D9E75)`, 청록빛 초록)와 `WalkTheme.light()/dark()`. `WalkApp` 이 이것을 쓴다.
- 화면 색은 전부 `ColorScheme` 역할로 쓴다 — 강조 카드 바탕 `primaryContainer` / 글자
  `onPrimaryContainer`, 진행 `primary`, 트랙 `primary` 의 낮은 알파 대신 `surfaceContainerHighest`.
  `Colors.*` · hex 를 화면에 적지 않는다.
- 모션 값은 `apps/walk/lib/presentation/theme/walk_motion.dart` 의 `WalkMotion`
  (`short` 200ms · `medium` 400ms · `long` 900ms · `celebrate` 1200ms, 곡선 `emphasized` =
  `Curves.easeOutCubic`). design_system 에 모션 토큰이 없어 앱 안에 둔다.
- **애니메이션 끄기 존중**: `MediaQuery.disableAnimations` 가 참이면 모든 연출은 끝 상태로 바로
  그린다(반복 애니메이션은 아예 돌지 않는다). 위젯 테스트의 `pumpAndSettle` 도 이 경로로 안정된다 —
  반복 애니메이션이 있는 화면 테스트는 `disableAnimations: true` 로 감싼다.

## 3. 목표 — 도메인 · 저장 · 상태

**도메인** (`lib/domain/walk/`)
- `StepGoal` 상수: `defaultSteps = 10000`, `min = 2000`, `max = 30000`, `step = 1000`, `clamp(int)`.
- `GoalProgress`(Freezed 단일 모델) — `steps` · `goal` 에서 `ratio`(0 이상, 1 초과 가능),
  `reached`(steps ≥ goal), `remainingSteps`(0 이상), `remainingMeters(double? distanceMeters)`
  — 오늘 거리 ÷ 오늘 걸음으로 보폭을 구해 남은 걸음에 곱한다. 걸음 0 · 거리 null 이면 null.
- `shouldCelebrate({steps, goal, today, lastCelebratedOn})` — 달성했고 마지막 축하일이 오늘이
  아니면 참. 순수 함수.

**저장** (`AppSettings` · `PrefsSettingsRepository`)
- `AppSettings` 에 `stepGoal`(기본 `StepGoal.defaultSteps`)와 `goalCelebratedOn`(DateTime?, 날짜만).
- prefs 키 `walk.stepGoal`(int) · `walk.goalCelebratedOn`(`yyyy-MM-dd` 문자열). 읽을 때 타입이 틀리거나
  범위 밖이면 기본값/clamp — 테마와 같이 깨진 prefs 로 죽지 않는다.
- `ThemeCubit.select` 는 `load().copyWith` 로 저장하므로 새 필드를 지우지 않는다(테스트로 고정).

**상태** (`lib/presentation/walk/cubit/`)
- `StepGoalCubit`(state = int 목표) — `ThemeCubit` 처럼 `MaterialApp` 위에 `MultiBlocProvider` 로 두어
  걷기 탭과 설정 탭이 같은 값을 본다. `select(int)` 은 clamp → 즉시 emit → 저장.
- 축하 판정은 cubit 을 두지 않고 `WalkHomePage` 가 한다: 오늘 값이 `TodayActivityLoaded` 로 올 때
  `SettingsRepository.load()` 의 `goalCelebratedOn` 으로 `shouldCelebrate` 를 보고, 참이면 카드에
  `celebrate: true` 를 넘기고 같은 프레임에 오늘 날짜를 저장한다. 같은 날 다시 열면 연출하지 않는다.

## 4. 걷기 탭

**오늘 카드 `TodayGoalCard`** (`TodayActivityCard` 교체)
- `primaryContainer` 바탕 카드. 가운데 `StepGoalRing`(CustomPainter, 두께 `AppSpacing.md`,
  끝 둥글게) 안에 걸음 수(`displaySmall`)와 `목표 10,000`(`bodySmall`). 아래 거리 · 칼로리 두 지표.
- 진입 시 링 0 → 비율, 숫자 0 → 걸음(`WalkMotion.long`). 새 값이 오면 이전 값에서 새 값까지만
  (`TweenAnimationBuilder` 의 begin 은 직전 값).
- 비율 ≥ 1: 링은 꽉 찬 원 + 카드 위 오른쪽에 `달성` 배지(`check` 아이콘). 넘친 걸음은 숫자로만.
- `celebrate` 이면 링 바깥으로 점 16개가 퍼지며 사라지는 파티클(CustomPainter, `WalkMotion.celebrate`)
  + `HapticFeedback.mediumImpact` 한 번.
- 링을 누르면 아래 한 줄이 `목표까지 2,760보 · 약 2.0km`(거리 null 이면 걸음만, 달성 시
  `목표보다 1,240보 더 걸었어요`)로 `AnimatedSwitcher` 전환, 3초 뒤 또는 다시 누르면 거리 · 칼로리로 돌아온다.
- 접근성: 링에 `Semantics(label: '오늘 7,240보, 목표 10,000보의 72%')`.
- 키: 기존 `walk-today-steps` 유지(숫자 Text), 새 `walk-goal-ring`.

**기간 전환** — `TabBar` → `SegmentedButton<PeriodKind>`(주간 | 월간). 아래 내용은
`AnimatedSwitcher`(페이드 + 아래에서 살짝 올라옴, `WalkMotion.medium`).

**막대그래프 `ActivityBarChart`**
- 높이 기준 `max(기간 최댓값, 목표)`. 목표 위치에 점선 가로선(`outline`)과 오른쪽 끝 `목표` 라벨.
- 달성일 `primary`, 미달 `primaryContainer`, 오늘은 2px `primary` 테두리, 오늘 이후는 비움(지금처럼).
- 진입 · 기간 이동 · 탭 전환마다 막대가 왼쪽부터 자란다(막대 i 는 `i × 30ms` 늦게 시작, 각
  `WalkMotion.medium`, 월간도 전체 1.3초 안에 끝나도록 지연 상한).
- 선택한 막대는 `AnimatedScale(1.06)`, 선택 줄은 `10월 2일 (목) · 8,120보 · 목표 81%`.
  누를 때 `HapticFeedback.selectionClick`.
- 기존 키(`walk-bar-selection`, `walk-bar-yyyy-MM-dd`) 유지.

**기간 요약 `PeriodSummary`** — 맨 위 `달성 4/7일`(오늘 이후 제외한 지난 날 기준) 강조 줄,
아래 2×2 지표 타일(아이콘 + 값 + 라벨: 총 걸음 · 일평균 · 거리 · 칼로리). 타일은 앱 안 `_MetricTile`.

**로딩** — 오늘 카드 · 기간 영역 자리에 같은 크기의 `WalkSkeleton`(둥근 사각 + 좌→우 shimmer,
`surfaceContainerHighest` 위 `surfaceContainerLow` 띠). 애니메이션 끄기면 정지 상태.

## 5. 알람 · 설정 · 셸

- **셸**: `NavigationDestination` 에 `selectedIcon`(filled 아이콘). 본문은 `IndexedStack` 상태 유지를
  그대로 두고 탭 전환 페이드는 넣지 않는다(`AnimatedSwitcher` 는 탭 상태를 버린다).
- **요약 카드 `AlarmSummaryCard`**: `primaryContainer` 바탕으로 걷기 카드와 맞춤. 남은 시간 텍스트는
  값이 바뀔 때 위로 밀리며 교체(`AnimatedSwitcher` + `SlideTransition`). 키 유지.
- **`AlarmTile`**: 꺼진 알람은 시각 · 요일 글자만 `onSurfaceVariant`. 스위치 토글 시 `selectionClick`.
- **울림 화면**: 배경 `primaryContainer`, 알람 아이콘 뒤로 동심원 3개가 2.4초 주기로 퍼지는
  `RingingRipple`(반복, 애니메이션 끄기면 정지). 시각 · 라벨 · 버튼 · 동작은 그대로.
- **설정 탭**: 맨 위 `걷기` 섹션 + `하루 목표` 행(`AppListTile`, 값 `10,000보`). 누르면 바텀시트에
  큰 숫자 미리보기 + `Slider`(2,000~30,000, 1,000 단위) + `저장` 버튼(`AppButton.primary`).
  저장하면 `StepGoalCubit.select` → 걷기 탭 링이 새 비율로 다시 움직인다. 섹션 헤더는
  `primary` 색 `labelLarge` 로 통일.

## 6. 문자열

`packages/l10n` 의 ko · en · ja ARB 에 `walkGoal*` 키를 추가한다(목표 n보, 목표까지, 더 걸었어요,
달성, 달성 n/m일, 하루 목표, 저장, 링 접근성 문구, 일평균 등 기존에 없는 것만).

## 7. 테스트

TDD. 위치는 구현 구조를 따른다(`test/domain/walk/…`, `test/presentation/walk/…` 등).

| 대상 | 확인 |
|---|---|
| `GoalProgress` · `StepGoal.clamp` · `shouldCelebrate` | 경계(0보, 목표 정확히, 초과, 거리 null, 범위 밖 목표, 어제 축하 / 오늘 축하) |
| `PrefsSettingsRepository` | 목표 · 축하일 왕복, 깨진 타입 · 범위 밖 → 기본/clamp, 테마 저장이 목표를 지우지 않음 |
| `StepGoalCubit` | 초기값 load, select clamp + 저장 |
| `AppTheme` | 기본 시드 유지, 넘긴 시드 반영 |
| `TodayGoalCard` | 걸음 · 목표 문구, 링 Semantics 비율, 달성 배지, 링 탭 → 남은 양 문구(거리 있음/없음/달성) |
| 축하 | 처음 달성 → 연출 + 날짜 저장, 같은 날 재진입 → 연출 없음 |
| `ActivityBarChart` | 목표선 존재, 달성일/미달일 색, 기존 선택 동작 + 목표 % 문구 |
| `PeriodSummary` | 달성 n/m일(미래 제외), 네 타일 값 |
| 설정 목표 시트 | 행 값 표시, 슬라이더 이동 후 저장 → cubit 값 · 행 갱신 |
| 기존 테스트 | 키 유지로 그대로 통과. 반복 애니메이션 화면은 `disableAnimations` 로 감싼다 |

검증: `flutter analyze` 0 · `apps/walk` 와 `packages/design_system` `flutter test` 통과 ·
디버그 APK 빌드 · 에뮬레이터 스크린샷(걷기 탭 라이트/다크, 달성 상태, 설정 시트, 울림 화면).
