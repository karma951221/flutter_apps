# W7 session — 구현 기록

> [pawlog 허브](../../README.md) · [계획](plan.md) · [테스트](testing.md) · [설계](../../../../../docs/superpowers/specs/2026-10-16-pawlog-pause-recovery-design.md) · [실행 계획](../../../../../docs/superpowers/plans/2026-10-16-pawlog-pause-recovery.md)

설계 판단 · 리뷰에서 고친 것 · 검증 결과를 남긴다. 진행 상태는 [진행 현황](../../status.md)에만 적는다.
브랜치 `feat/pawlog-session`. 사용자가 "묻지 말고 알아서 진행" 이라고 해서, 이 작업은 오케스트레이터가 고르고
스펙 · 계획도 스스로 승인했다. 태스크마다 구현 서브에이전트가 커밋하고 리뷰 서브에이전트가 따로 읽었다.

## 단계 커밋 (2026-10-16 ~ 17)

| # | 커밋 | 범위 |
|---|---|---|
| ① | `ffb6dfd` | `WalkSession.pausedDuration` · `pausedAt` · `elapsedAt`, `WalkDraft.duration` — 저장 시간 = 걸은 시간 |
| ② | `c8929e3` | 추적기 `pause` · `unpause`, 멈춤 중 점 버림, 재개 뒤 첫 점 0 m, `WalkUseCase.pauseWalk` · `unpauseWalk` |
| ③ | `3210f23` | 진행 화면 보조 버튼 · "일시정지 중" · 피드 배너 멈춤 문구, 문자열 4개 |
| ④ | `b7bf501` | drift 스키마 v2(`active_walks` · `active_walk_points`) · `DriftActiveWalkStore` · 마이그레이션 테스트 |
| ⑤ | `7419b14` · `5affebb` | 추적기가 세션을 직렬 큐로 써 두고 `restore()`, `bootstrap` 이 시작 때 부름 · 리뷰 수정 |

## 판단 (설계에 없던 것)

| 판단 | 이유 |
|---|---|
| 재개 뒤 "첫 점 0 m" 은 정책이 **받아들인** 첫 점에 쓴다. 판정은 실제 거리로 | 2 m 미만 점을 거르는 규칙을 그대로 두려고. 그 점이 버려지면 다음 수락 점이 0 m 가 되어 최대 2 m 정도를 덜 셀 수 있다 |
| 복구 뒤 첫 점은 실제 거리를 더한다(건너뛰지 않는다) | 앱이 죽은 동안을 걸은 시간으로 세는 설계 §1 #6 과 맞춘다 — 그동안 실제로 걸었을 가능성이 크다 |
| `begin` 은 머리 행만 쓰고 점은 `appendPoint` 로만 | 새 세션은 점이 없다. 인터페이스 문서에 적었다 |
| 복구는 위치 권한을 **묻지 않고 확인만** 한다(`LocationAccess.check()` 를 `packages/location` 에 추가) | `runApp` 전에 권한 대화상자가 뜨면 첫 화면이 막히고, 그 사이 액티비티가 다시 만들어지면 응답이 사라져 스플래시에 멈출 수 있다. 거부면 `locationError` 로 되살리고 배너 · 진행 화면의 "다시 시도" 가 그때 묻는다 |
| 점 `seq` 는 upsert 로 쓴다 | 앞선 쓰기가 실패했을 때 복구 뒤 번호가 겹쳐도 기본 키 오류로 뒤 점이 모두 막히지 않게 |
| `bootstrap` 의 `restore()` 는 try/catch 로 감싼다 | 복구 실패가 앱 시작을 막으면 안 된다 |

## 리뷰에서 고친 것

| 단계 | 소견 | 처리 |
|---|---|---|
| ⑤ | 복구가 `runApp` 전에 권한을 요청할 수 있음(첫 프레임 막힘 · 드물게 영구 대기 · 세션당 한 번 묻기 소모) | 확인만 하는 `LocationAccess.check()` 로 (`5affebb`) |
| ⑤ | `getIt` 해석 · `restore()` 오류가 시작을 막을 수 있음 | `bootstrap` try/catch (`5affebb`) |

## 넘기는 것 (리뷰 Minor)

- 일시정지 · 재개 연타 방지 가드가 없다 — 추적기가 멱등이라 같은 상태 쓰기가 한 번 더 될 뿐
- 보조 버튼만큼 진행 화면 시트가 높아졌다 — 작은 화면에서 지도 영역이 줄어든다
- 저장소 `clear` · `begin` 실패는 로그만 남긴다. 드물게 다음 실행에 지난 스냅샷이 되살아날 수 있다(설계대로)
- `LocationAccess.check` 와 `ensure` 가 서비스 · 권한 매핑을 중복한다
- 저장 직후 몇 ms 안에 앱이 죽으면 같은 산책이 두 번 저장될 수 있다
- 앱이 죽어 있던 시간에 상한이 없다 — 밤새 두면 14시간 산책이 된다
- 첫 위치를 받기 전에 멈추면 "위치 찾는 중" 이 남는다
- 테스트 빈 곳: 재개 뒤 2 m 미만 점 거절, 멈춤 + 위치 오류 동시, 유스케이스 위임, `updateTiming` 의 `pausedAt` null 은 추적기 테스트로만

## 에뮬레이터 QA (2026-10-17)

`Medium_Phone_2`(영어). `-no-snapshot-load` 콜드 부팅으로 Google Play 서비스 위치 서비스가 죽는 문제는 사라졌다.
그래도 geolocator 는 "location service disabled" 를 낸다 — logcat 에 네트워크 위치 동의(NLP consent)를 읽는 줄이 있고,
fused 경로가 Google 위치 정확도 동의를 요구하는 것으로 보인다. 동의는 사용자 몫이라 켜지 않았다. 그래서 거리는 늘 0 m 이고,
시간 · 멈춤 · 복구만 확인했다. 결과는 [테스트 — 에뮬레이터](testing.md#에뮬레이터).
