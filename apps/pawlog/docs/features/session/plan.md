# W7 session — 계획 (화면 · 상태 · 완료 조건)

> [pawlog 허브](../../README.md) · [기획 §5](../../overview.md#5-feature-분해) · [구현 기록](history.md) · [테스트](testing.md) · [설계](../../../../../docs/superpowers/specs/2026-10-16-pawlog-pause-recovery-design.md) · [W2 tracking](../tracking/plan.md)

> 상태: 구현 완료 2026-10-17 (`5affebb`) · 에뮬레이터 PASS(거리 제외) · 진행 상태의 단일 기준은 [진행 현황](../../status.md)

## 범위

산책 **일시정지 · 재개**와 **앱 강제 종료 뒤 진행 중 산책 복구**. 결정과 구조는
[설계](../../../../../docs/superpowers/specs/2026-10-16-pawlog-pause-recovery-design.md) §1 ~ §4 가 기준이다.
경로 선을 멈춘 구간에서 끊는 것, 멈춤 중 알림 문구 바꾸기, 자동 일시정지는 범위 밖이다.

## 화면 · 상태

`ActiveWalkState.tracking(session, elapsed, locationError?)` 은 그대로 두고 `session.isPaused` 로 가른다.

| 상태 | 진행 화면 시트 | 피드 배너 |
|---|---|---|
| 추적 중 | 거리 · 시간 · 보조 버튼 "일시정지" · 주 버튼 "산책 끝내기" | 연두 점 · `walkInProgressBanner` · 경과 시간 |
| 멈춤 중 | 숫자 위 `walkPausedLabel` · 시간이 멈춤 · 보조 버튼 "계속 걷기" · 주 버튼 "산책 끝내기" | 점 없음 · `walkPausedBanner` · 멈춘 경과 시간 |
| 복구 뒤 | 위 둘 중 하나로 이어진다(멈춤 상태로 죽었으면 멈춤 중) | 같음 |
| 끝냈지만 저장 전에 죽음 | 다시 열면 피드에 저장 안 함 배너 → 저장 폼 | `walkUnsavedBanner` |

| 동작 | 결과 |
|---|---|
| "일시정지" | `ActiveWalkCubit.pause()` → `WalkUseCase.pauseWalk()` |
| "계속 걷기" | `ActiveWalkCubit.unpause()` → `WalkUseCase.unpauseWalk()` |
| 멈춤 중 "산책 끝내기" | 확인 → 멈춤을 닫고 끝낸다. 저장 폼의 시간 = 걸은 시간 |

## 문자열 (ko 템플릿 · en · ja)

| 키 | ko | en | ja |
|---|---|---|---|
| `walkPause` | 일시정지 | Pause | 一時停止 |
| `walkUnpause` | 계속 걷기 | Resume | 再開 |
| `walkPausedLabel` | 일시정지 중 | Paused | 一時停止中 |
| `walkPausedBanner` | 산책을 잠시 멈췄어요 | Walk paused | 散歩を一時停止中 |

## 완료 조건

- [ ] 설계 §6 의 단위 · 위젯 테스트
- [ ] 스키마 v1 → v2 마이그레이션 테스트(기존 행 유지)
- [ ] `flutter analyze` 0건 · `flutter test`(`apps/pawlog` · `packages/l10n`) · `flutter build apk --debug`
- [ ] 에뮬레이터:
  1. 산책 중 일시정지 → 시간이 멈추고 배너가 바뀐다 → 계속 걷기 → 시간이 이어진다
  2. 멈춤 중 끝내기 → 저장 폼 · 상세 · 피드의 시간이 멈춘 시간을 뺀 값
  3. 추적 중 `adb shell am force-stop` → 다시 열면 피드에 진행 배너, 진행 화면에서 거리 · 점이 이어진다
  4. 끝낸 뒤 저장 폼에서 강제 종료 → 다시 열면 저장 안 함 배너 → 저장된다
  5. 저장 · 버리기 뒤 강제 종료 → 다시 열어도 배너가 없다
