# W6 stats — 테스트

> [테스트 가이드](../../../../../docs/testing/README.md) · [pawlog 허브](../../README.md) · [계획](plan.md) · [구현 기록](history.md)

```bash
cd apps/pawlog && flutter test test/domain/stats
cd apps/pawlog && flutter test test/presentation/stats
cd apps/pawlog && flutter test test/presentation/feed test/core/router
```

W6 몫은 56건이다(2026-10-16, 최종 리뷰 반영 뒤): 정책 20 · 표기 9 · cubit 8 · 페이지 9 · 라우터 2 · 피드 8.
`apps/pawlog` 전체 `+309`(W6 전 `+253`, `ab5e10a` 기준 `+303`).

## `test/domain/stats/`

| 파일 | 대상 | 확인 |
|---|---|---|
| `policy/walk_stats_policy_test.dart` (20) | `WalkStatsPolicy` | 주는 월요일 00:00 부터 · 일요일 23:59 와 월요일 00:00 경계 · `offset -1` · 연말 · 연초를 걸친 주 · 월 범위와 해를 넘는 `offset` · 이번 주 합과 지난주 전체 합 · 주 7칸 · 자정을 넘긴 산책은 시작한 날만 · UTC 로 들어온 시각도 현지 칸 · 월 칸 4 · 5 · 6 · 월 칸 거리 합 · 기록 0건 · 연속(오늘까지 · 오늘 없음 → 어제부터 · 어제도 없음 → 0) · 최장 연속(하루 여러 건은 하루) · 가장 먼 · 오래 걸은 산책 동률은 최근 것 · `earliestOffset`(주 -2 · 월 -1 · 0건 0 · 미래 산책만 있어도 0) |

## `test/presentation/stats/`

| 파일 | 대상 | 확인 |
|---|---|---|
| `format/stats_format_test.dart` (9) | `StatsFormat` | 같은 달 주 `10월 12일 – 18일` · 달이 걸친 주 · 올해가 아닌 주에 연도 · 월 `2026년 10월` · 칸 라벨(요일 · `26–31` · 하루 `1`) · 비교(지난 기간 0 → 숨김 · 더 → 차이 · 같거나 덜 → 지난 합 · 반올림해 0 m 인 차이(`800.4` vs `800`) → `지난주 800 m`) |
| `cubit/stats_cubit_test.dart` (8) | `StatsCubit` | 첫 값 → 이번 주 · 이전은 가장 오래된 주에서, 다음은 지금에서 멈춤 · 월로 바꾸면 `offset` 0 · 오래된 산책이 지워지면 `offset` 을 끌어올림 · 화면을 연 채 주가 바뀌면 다음 값에서 새 주 · 첫 값 전 이동 무시 · 0건 `isEmpty` · 오류 → `failure` → `retry` 재구독 |
| `page/stats_page_test.dart` (9) | `StatsPage` | 요약 · 비교 · 막대 7칸, 카드 없음 · 막대 탭 → 값, 다시 탭 → 숨김 · 스크린리더 탭 동작(`SemanticsAction.tap`) · 이전 주 → 지난주, `stats-next` 비활성 → 활성 · 월 → 이번 달 · 5칸 · 기록 탭 → `onOpenWalk('b')` · 거리 0 m 산책뿐이면 '가장 먼 산책' 줄 없음 · 0건 → `AppPlaceholder` 만 · 다크 테마 |

## 피드 · 라우터

| 파일 | 추가 | 확인 |
|---|---|---|
| `test/presentation/feed/cubit/walk_feed_cubit_test.dart` | 3 | 이번 주 요약을 시계 기준으로 싣고 추적 상태가 바뀌어도 유지 · `refreshWeekSummary` — 시계가 다음 주 월요일로 가면 캐시한 목록으로 빈 요약(재구독 없음) · 목록 전이면 아무것도 안 냄 |
| `test/presentation/feed/page/walk_feed_page_test.dart` | 5 | 요약 줄 `이번 주 1.2 km · 1번` → `onOpenStats` · 스크린리더에 버튼(`isButton` · 탭 동작) · 앱 복귀(`resumed`) 뒤 다음 주면 `이번 주는 아직 산책 전이에요` · 이번 주 0건 문구 · 빈 피드에는 줄 없음 |
| `test/core/router/app_router_test.dart` | 2 | `/stats` → `StatsPage` · 반려견 0마리면 `/stats` 도 `/dogs/new` |

## 에뮬레이터

2026-10-16, `Medium_Phone_2`(영어). GPS 가 앱에 들어오지 않아 거리 0 m 산책 두 건으로 봤다([기록](history.md#에뮬레이터-qa-2026-10-16)).

| # | 시나리오 | 결과 |
|---|---|---|
| ① | 산책 저장 직후 피드 요약 줄이 바로 바뀐다 | **PASS** — 저장 뒤 `This week 0 m · 1 walk` → 두 번째 저장 뒤 `2 walks`. 거리가 늘어나는 것은 GPS 문제로 못 봄 |
| ② | 요약 줄 → 통계, 주 ↔ 월, `‹` 로 지난 기간, 가장 오래된 기간에서 `‹` 비활성 | **일부** — 진입 · `Oct 12 – 18` · 월 `October 2026` 5칸(`1–4` … `26–31`) · 이번 기간만 있어 `‹` `›` 모두 비활성 PASS. 지난 기간 이동은 과거 산책이 없어 못 봄(위젯 테스트가 덮음) |
| ③ | 막대 탭 → 값, 기록 "가장 먼 산책" → 상세 | **PASS** — 값 `0 m` 이 뜸(칸 위쪽에 — 기록 "넘기는 것"), 상세로 이동. 최종 리뷰 뒤로는 0 m 산책뿐이면 이 기록 줄을 숨긴다 |
| ④ | 산책을 모두 지우면 통계 빈 안내 · 피드 요약 줄 사라짐 | **일부** — 피드 요약 줄 사라짐 PASS. 빈 피드에는 진입점이 없어 통계 빈 안내는 위젯 테스트로만 |
| ⑤ | 다크 모드 | **PASS** — 토글 · 숫자 · 바닥선 · 기록 줄 |
