# walk 테스트

> [테스트 가이드](../../../docs/testing/README.md) · [계획](plan.md) · [기록](history.md) · [진행 현황](status.md)

```bash
cd apps/walk && flutter test   # 도메인 · 데이터 · cubit · 위젯 · 경계 (2026-09-27 기준 65건)
```

백엔드가 없어 로컬 Supabase 없이 돈다. Health Connect 는 `HealthGateway` 를 mock 해서 본다
— `HealthPluginGateway`(플러그인 호출 자체)는 단위 테스트하지 않고 기기에서 확인한다.

## `apps/walk/test/` — `lib/` 와 1:1

| 파일 | 대상 | 확인 |
|---|---|---|
| `domain/entity/period_range_test.dart` | `periodRange` · `daysBetween` | 주는 월요일 시작 · 일요일에 연 이번 주 · 지난 주가 달을 넘음 · 윤년 2월 · 지난 달이 연도를 넘음 · 양 끝 포함 |
| `domain/entity/activity_period_test.dart` | `ActivityPeriod` | 합계 · 일평균은 오늘까지 지난 날로 나눔 · 거리/칼로리는 값 있는 날만, 없으면 null · `isCurrent` · 지난 기간은 전체 일수 |
| `domain/usecase/walk_use_case_test.dart` | `DefaultWalkUseCase` | 오늘 하루만 읽기 · 이번 주는 오늘까지 읽고 나머지 0보 · 지난 달 전체 · 실패 전파 |
| `data/health/health_permission_source_test.dart` | `HealthPermissionSource` | 걸음 권한 기준 granted/denied(permanentlyDenied 없음) · 세 타입 요청 · 걸음을 거부하면 기록 이력은 묻지 않음 · 설정 열기 |
| `data/repository/health_connect_activity_repository_test.dart` | `HealthConnectActivityRepository` | SDK 없음/모름/업데이트 필요 매핑 · 걸음 권한만으로 granted · **이번 세션에 한 번만 묻기** · 거부 후 다시 요청 · **동시 확인은 요청 한 번** · 모든 날 채우기 · 권한 없는 타입은 묻지 않음 · 예외 → `Err` |
| `presentation/format/walk_format_test.dart` | `WalkFormat` | `6,240` · `4.3 km` · `183 kcal` · 없으면 `–` · 주/월/요일/일 라벨 |
| `presentation/cubit/health_access_cubit_test.dart` | `HealthAccessCubit` | 확인 중(null) · 확인 결과와 `canOpenSettings` · 요청 · 설치/설정은 화면만 연다 |
| `presentation/cubit/today_activity_cubit_test.dart` | `TodayActivityCubit` | loading → loaded · failure · 새로고침은 로딩 없이 |
| `presentation/cubit/period_activity_cubit_test.dart` | `PeriodActivityCubit` | 현재 기간 · 이전 · 현재에서 다음 불가 · 새로고침은 같은 offset · 늦은 응답 버림 · 실패해도 offset 유지 |
| `presentation/widget/activity_bar_chart_test.dart` | `ActivityBarChart` | 요일 7개 · 최댓값 막대가 가장 높음 · 미래 날은 막대 없음 · 탭하면 그날 걸음 · **새로고침 뒤 선택 값 갱신** |
| `presentation/page/walk_home_page_test.dart` | `WalkHomePage` | 오늘 걸음 · km · `–` · 현재 기간 다음 버튼 꺼짐 · 월간 탭 · 권한 요청 · 설정 열기 유무 · 설치 안내 · 오늘 실패 재시도 · **복귀 시 재확인 · 새로고침** · **복귀 중 허용되면 한 번만 읽기** |
| `convention/package_boundary_test.dart` | `pubspec.yaml` | `feature_*` · `supabase_flutter` 의존 없음 |

굵은 항목은 최종 리뷰에서 고친 것의 회귀 테스트다([기록](history.md#2026-09-27--최종-리뷰에서-고친-것)).

## 테스트가 없는 것

당겨서 새로고침 · 이전 기간 넘기기(페이지 수준) · 업데이트 필요 화면 · 기간 읽기 실패 ·
오늘 막대 강조 · 월간 차트. 코드 검토로는 맞지만 테스트는 없다.

## 기기 시나리오 — 대기

실제 폰(Health Connect 에 헬스 앱 기록이 있는)에서 볼 것. 에뮬레이터는 기록이 없어 ② · ⑥ · ⑦ 만 의미가 있다.

| # | 시나리오 | 기대 | 결과 |
|---|---|---|---|
| ⓪ | 걸음 · 거리 · 활동 칼로리가 Health Connect 에 있는가 | 헬스 앱 숫자와 같음. 활동 칼로리가 없고 총 칼로리만 있으면 칼로리 타입을 다시 정한다 | 대기 |
| ① | 첫 실행 → 권한 허용 | 오늘 걸음이 헬스 앱과 같은 숫자, 권한 창은 한 번만 | 대기 |
| ② | 권한 거부 | 안내 + 권한 허용 + 설정 열기 → 풀림 | 대기 |
| ③ | 주간 · 월간 탭, ‹ 로 지난 기간 | 막대 · 합계 · 일평균이 맞고 날짜가 밀리지 않음, 현재 기간에서 › 꺼짐 | 대기 |
| ④ | 막대 선택 → 홈 → 조금 걷기 → 복귀 | 오늘 걸음 · 선택 줄 갱신 | 대기 |
| ⑤ | 거리 · 칼로리 없는 날 | `–` | 대기 |
| ⑥ | 다크 모드 | 대비 정상 | 대기 |
| ⑦ | 권한 창의 개인정보/사용 내역 링크 | 앱이 두 번 뜨거나 권한 창이 겹치지 않음 | 대기 |
