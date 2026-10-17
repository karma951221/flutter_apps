# W7 session — 테스트

> [테스트 가이드](../../../../../docs/testing/README.md) · [pawlog 허브](../../README.md) · [계획](plan.md) · [구현 기록](history.md)

```bash
cd apps/pawlog && flutter test test/domain/tracking test/data/tracking test/data/database
cd apps/pawlog && flutter test test/presentation/tracking test/presentation/feed test/presentation/walk
cd packages/location && flutter test test/location_access_test.dart
```

W7 몫은 `apps/pawlog` 58건과 `packages/location` 3건(`+21` → `+24`)이다. `5affebb` 기준 53건(`+309` → `+362`)에 2026-10-17 오래 죽어 있던 산책 복구 5건을 더했다.

| 파일 | 추가 | 확인 |
|---|---|---|
| `test/domain/tracking/entity/walk_session_test.dart` | 7 | `elapsedAt` — 멈춤 없음 · 지난 멈춤 합 · 지금 멈춤 중(시계가 가도 고정) · 끝난 세션 · 끝났는데 `pausedAt` 이 남은 세션 · 음수 방지 · `isPaused` |
| `test/domain/walk/usecase/scenario/save_walk_scenario_test.dart` | 1 | 저장 시간이 `draft.duration`(멈춤을 뺀 값) |
| `test/presentation/walk/cubit/walk_edit_cubit_test.dart` | 1 | `toDraft().duration` = 전체 − 멈춤 |
| `test/data/tracking/geolocator_walk_tracker_test.dart` | 31 | pause · unpause 상태와 멱등 · 멈춤 중 점 버림(구독 유지) · 재개 뒤 첫 수락 점 0 m · 버려진 점은 0 m 자리를 쓰지 않음 · 멈춤 중 stop 이 멈춤을 닫음 · 위치 오류 처리 · 저장소 `begin` · `appendPoint` 순서 · `updateTiming`(재개 뒤 `pausedAt` null) · `clear` · 쓰기 실패 · 느린 `begin` 에도 순서 유지 · `restore` 7갈래(없음 · 끝남 · 진행 · 멈춤 · 서비스 꺼짐 · 권한 거부(요청 안 함) · load 실패 · 이미 시작) · 오래 죽어 있던 산책 5갈래(마지막 점 뒤 31분 → 그 점 시각에 멈춤 + `updateTiming` · 29분 → 그대로 · 점 없음 → 시작 시각에 멈춤 · 이미 멈춤 → 원래 시각 · 끝남 → 그대로) |
| `test/data/tracking/drift_active_walk_store_test.dart` | 8 | 빈 load · begin 왕복 · 점 순서 · 누적 거리 · 같은 seq 두 번(upsert) · `updateTiming` 왕복 · `pausedAt` null 되돌림 · 두 번째 begin 이 이전 것을 지움 · clear |
| `test/data/database/walk_database_migration_test.dart` | 3 | v1 SQL + `user_version 1` DB → v2 로 열면 기존 행 유지 · 새 테이블 · `user_version 2` · 저장소 동작 |
| `test/presentation/tracking/cubit/active_walk_cubit_test.dart` | 3 | pause · unpause 위임 · 추적 중이 아니면 부르지 않음 · 멈춤 중 경과 시간 고정 |
| `test/presentation/tracking/page/active_walk_page_test.dart` | 2 | "Pause"/"일시정지" → `pauseWalk` · 멈춤 중 "계속 걷기" · "일시정지 중" 라벨 · 주 버튼 하나 |
| `test/presentation/feed/page/walk_feed_page_test.dart` | 2 | 멈춤 배너 문구 · 키 · 연두 점 없음 / 진행 중은 점 있음 |
| `packages/location/test/location_access_test.dart` | 3 | `check()` — 서비스 꺼짐 · 권한 상태를 요청 없이 · 세션당 묻기 기억을 쓰지 않음 |

## 에뮬레이터

2026-10-17, `Medium_Phone_2`(영어, 콜드 부팅). GPS 가 앱에 들어오지 않아 거리 0 m([기록](history.md#에뮬레이터-qa-2026-10-17)).

| # | 시나리오 | 결과 |
|---|---|---|
| ① | 일시정지 → 시간이 멈추고 배너가 바뀐다 → 계속 걷기 → 이어진다 | **PASS** — `00:49` 에서 멈춤, "Paused" 라벨 · "Resume" 버튼, 피드 배너 "Walk paused \| 00:49"(연두 점 없음), 재개 뒤 `00:52` |
| ② | 멈춤 중 끝내기 → 저장 폼 · 상세 · 피드의 시간이 멈춘 시간을 뺀 값 | **PASS** — `01:23` 에서 멈춘 뒤 30초쯤 지나 끝내기 → 저장 폼 · 상세 `01:23`, 피드 "1 min" |
| ③ | 추적 중 강제 종료 → 다시 열면 배너, 진행 화면에서 이어진다 | **PASS(시간)** — 멈춤 중 강제 종료 → "Walk paused \| 00:49" 그대로. 진행 중 강제 종료(9초) → "Walk in progress \| 00:59"(죽은 동안을 걸은 시간으로). 거리 · 점 이어짐은 GPS 문제로 못 봄 |
| ④ | 끝낸 뒤 저장 폼에서 강제 종료 → 저장 안 함 배너 → 저장 | **PASS** — "You have an unsaved walk" → 저장 폼 `01:23` → 저장 |
| ⑤ | 저장 뒤 강제 종료 → 배너 없음 | **PASS** |

## 2026-10-17 — 다듬기

| 파일 | 추가 | 확인 |
|---|---|---|
| `test/presentation/tracking/page/active_walk_page_test.dart` | 1 | 점 없이 멈춘 세션 → `walk-active-map` 안에 "일시정지 중", "위치를 찾는 중…" 없음 |
