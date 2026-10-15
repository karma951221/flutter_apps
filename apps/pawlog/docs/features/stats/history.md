# W6 stats — 구현 기록

> [pawlog 허브](../../README.md) · [계획](plan.md) · [테스트](testing.md) · [설계](../../../../../docs/superpowers/specs/2026-10-16-pawlog-stats-design.md) · [실행 계획](../../../../../docs/superpowers/plans/2026-10-16-pawlog-stats.md)

설계 판단 · 리뷰에서 고친 것 · 검증 결과를 남긴다. 진행 상태는 [진행 현황](../../status.md)에만 적는다.
브랜치 `feat/pawlog-stats`. 태스크마다 구현 서브에이전트가 커밋하고, 리뷰 서브에이전트가 따로 읽었다.

## 단계 커밋 (2026-10-16)

| # | 커밋 | 범위 |
|---|---|---|
| ① | `deb4198` | `domain/stats` 엔티티 6 · `WalkStatsPolicy` + 단위 테스트 20 |
| ② | `e43bcd1` | `l10n` 문자열 24개(ko · en · ja) |
| ③ | `74fc881` | `StatsFormat` · `StatsState` · `StatsCubit` + 테스트 16 |
| ④ | `ac6c3bc` · `6ecb8ac` | 통계 화면 · 위젯 4 · `/stats` 경로 + 페이지 테스트 8 · 라우터 2 |
| ⑤ | `ab5e10a` | `WalkFeedCubit.weekSummary` · `WeekSummaryLine` · `onOpenStats` + 테스트 4 |

## 설계와 다르게 간 것

| 설계 | 실제 | 이유 |
|---|---|---|
| 막대를 `CustomPainter` 로 | 칸마다 위젯(`DecoratedBox`) | 칸 탭 · `Semantics` 를 위젯 단위로 붙이고 키로 테스트하기 쉽다 |
| `StatsLoaded` 에 `now` 없음 | `now` 를 싣는다 | 기간 라벨에 연도를 붙일지 정할 때 위젯이 `DateTime.now()` 를 읽지 않게 |
| — | 0건 기간의 시간은 `0분` | `WalkFormat.duration(Duration.zero)` 는 "1분 미만" 이라 기록이 있는 것처럼 읽힌다 |
| — | `PawlogSize.statsChart`(180) · `hairline`(1) | 막대 높이 · 바닥선 두께를 숫자로 적지 않으려고 |
| — | `WalkFeedState.loaded.weekSummary` 는 `@Default(PeriodSummary.empty)` | 기존 피드 테스트의 기대값을 그대로 두려고. 기존 테스트는 시계를 산책 주 밖(2026-12-01)에 두어 실제로 빈 요약을 계산한다 |

## 리뷰에서 고친 것

| 단계 | 소견 | 처리 |
|---|---|---|
| ④ | 막대의 `Semantics(excludeSemantics: true)` 가 탭 동작까지 지워 스크린리더로 누를 수 없음 (계획 코드) | `Semantics.onTap` 에 같은 토글 — 테스트가 `SemanticsAction.tap` 으로 값을 띄운다 (`6ecb8ac`) |
| ④ | "이전 주로 가면 … 다음이 켜진다" 테스트가 `stats-next` 를 보지 않음 (계획 코드) | 지금 주에서 비활성 · 이전 뒤 활성을 단언 (`6ecb8ac`) |

## 최종 리뷰에서 고친 것

브랜치 전체를 다시 읽은 최종 리뷰 소견. 같은 날 반영했다.

| 소견 | 처리 | 덮는 테스트 |
|---|---|---|
| pawlog 허브에 W6 줄이 없고, 기획서 §5 영역 목록에 `stats` 가 빠졌으며 W6 줄에 착수일(진행 상태)이 적혀 있었다 | 허브 표에 W6 줄 · §5 영역에 `stats` · W6 줄은 상태 없는 설명만 | 문서 링크 검사 |
| 피드 요약 줄은 스트림 값이 올 때만 다시 계산해, 피드를 연 채 주가 바뀌면 지난주 숫자가 남았다 | `WalkFeedCubit.refreshWeekSummary()` — 캐시한 목록을 지금 시각으로 다시 계산해 `loaded` 를 낸다(목록 없음 · loaded 아님 · 닫힘이면 아무것도 안 함). 피드 화면이 `AppLifecycleListener(onResume:)` 로 부른다 | cubit 2 · 페이지 1 |
| 차이가 반올림해 0 m 면 "지난주보다 0 m 더 걸었어요" | `(current - previous).round() >= 1` 일 때만 '더 걸었어요', 아니면 지난 기간 합 | 표기 1 (`800.4` vs `800` → `지난주 800 m`) |
| 거리 없는 산책뿐이면 "가장 먼 산책 0 m" 줄이 뜬다(에뮬레이터 ③에서 본 그 줄) | `farthest.distanceMeters < 1` 이면 줄을 숨긴다 | 페이지 1 |
| `WeekSummaryLine` 이 스크린리더에 버튼으로 읽히지 않는다 | `Semantics(button: true)` 로 감쌌다. 키 `walk-feed-week-summary` 는 그대로 | 페이지 1 (`isButton` · `hasTapAction`) |
| `stats_cubit` · `stats_format` 과 그 테스트가 `dart format` 을 거치지 않았다 | 포맷 · `if` 한 줄 문에 중괄호 | `flutter analyze` 0 |

## 넘기는 것 (리뷰 Minor)

- UTC 시각 테스트는 테스트 기기 시간대가 UTC 면 아무것도 증명하지 않는다(이 개발 기기는 KST)
- 1월 → 지난해 12월 `earliestOffset` · 월 칸, 과거 기간(`offset ≠ 0`)의 `previousSummary` 테스트가 없다
- 운영에서는 시계가 움직여 한계에서 `showPrevious` 가 같은 내용을 다시 낸다 — 화살표가 꺼져 있어 무해
- `offset` 은 지금 기준이라, 과거 기간을 보는 채로 주가 바뀌면 한 칸 밀린다(설계대로)
- 올해가 아닌 주는 양 끝에 연도가 붙는다(`2025년 10월 13일 – 2025년 10월 19일`)
- 기록 줄 값 열이 화살표 유무로 들쭉날쭉하다 · `_RecordRow` 는 `AppListTile` 이 아니라 `rule` 선 줄글
- 피드를 앞에 띄운 채 주가 바뀌면 다음 스트림 값이나 앱 복귀 전까지 지난주 요약이 남는다(복귀 때만 다시 계산)
- 0 인 칸을 탭하면 값(`0 m`)이 바닥선이 아니라 칸 맨 위에 뜬다 — 에뮬레이터에서 봄

## 에뮬레이터 QA (2026-10-16)

`Medium_Phone_2`(Android, 영어), 새로 설치. 결과는 [테스트 — 에뮬레이터](testing.md#에뮬레이터).

- 이 AVD 에서는 `adb emu geo fix` 를 넣어도 geolocator 가 "The location service on the device is disabled" 를 냈다.
  기기 위치는 켜져 있고 `gps` 의 마지막 위치도 갱신됐다. 새 AVD 에 Google 위치 정확도 동의가 없어서로 보인다.
  동의는 사용자 몫이라 켜지 않았고, 통계는 **거리 0 m 산책 두 건**으로 확인했다
- 위치 서비스 꺼짐 오류 뒤 위치를 켜고 "Try again" 을 눌러도 앱이 위치 요청을 다시 등록하지 않았다
  (`dumpsys location` 에 pawlog 요청 없음). W2 tracking 의 다시 시도 경로라 이 범위 밖 — 따로 본다
- 기존 `Medium_Phone` AVD 는 저장 공간 부족(설치 실패) · 화면 잠금 PIN 으로 쓰지 않았다
