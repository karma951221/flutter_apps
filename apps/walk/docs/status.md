# 진행 현황 — 걷기

> [걷기 허브](README.md) · [계획](plan.md) · [설계](../../../docs/superpowers/specs/2026-09-27-walk-app-design.md) · [전체 진행 현황](../../../docs/status.md)

**걷기 앱 진행 현황의 단일 기준은 이 문서다.** 다른 문서에는 진행 상태를 적지 않는다.

## 단계 요약

| 단계 | 범위 | 상태 |
|------|------|------|
| v1 | 오늘 걸음 · 주간/월간 막대그래프 · 거리/칼로리 (Health Connect) | **코드 완료 · 기기 확인 대기** |
| 알람 · 설정 | 하단 탭 셸 · 기상 알람 · 설정 탭 · 남은 시간/요약 카드. 앱 표시 이름 "Life Tool" | **코드 완료 · 에뮬레이터 확인 · 실제 폰 대기** |

## v1

- [x] **0 설계** — 브레인스토밍, [설계 문서](../../../docs/superpowers/specs/2026-09-27-walk-app-design.md) (2026-09-27)
- [x] **0 폴더 뼈대** — `flutter create`(android), workspace 등록, 계층 폴더
- [ ] **1 실제 폰 데이터 확인** — Health Connect 권한 · 걸음/거리/활동 칼로리가 실제로 있는지 ([설계 §9](../../../docs/superpowers/specs/2026-09-27-walk-app-design.md#9-기기-확인-구현-첫-단계와-마지막-단계))
- [x] **2 도메인** — 엔티티 · 기간 계산 · `ActivityRepository` · `WalkUseCase`
- [x] **3 데이터** — `HealthGateway` · `HealthConnectActivityRepository` · 안드로이드 매니페스트
- [x] **4 접근 상태 화면** — `HealthAccessCubit` · 설치/업데이트/권한 안내
- [x] **5 오늘 카드** — `TodayActivityCubit` · `TodayActivityCard`
- [x] **6 주간 · 월간 탭** — `PeriodActivityCubit` · 막대그래프 · 요약
- [ ] **7 기기 시나리오** — 에뮬레이터 + 실제 폰
- [x] **8 문서** — `history.md` · `testing.md` · 이 문서

커밋: `11d509b` 의존성 · 안드로이드 · gateway → `85c38f3` 도메인 → `fcbce26` 권한 source · 저장소 →
`f2d909d` 문자열 · 포맷 → `73a6afa` cubit → `7718543` 화면 → `2882562` 최종 리뷰 수정.
검증(2026-09-27): `flutter analyze` 0 · `flutter test` 65건 통과 · 디버그 APK 빌드.
판단과 고친 것은 [기록](history.md), 테스트 범위는 [테스트](testing.md).

## 알람 · 설정

설계: [알람 · 설정 탭](../../../docs/superpowers/specs/2026-09-27-walk-alarm-design.md) ·
[남은 시간 · 요약 카드 · 울림 버튼](../../../docs/superpowers/specs/2026-09-29-walk-alarm-remaining-time-design.md) ·
[실행 계획](../../../docs/superpowers/plans/2026-09-27-walk-alarm.md)

- [x] **T1 이동** — 걷기 코드를 `walk/` 하위로 (`4286521`)
- [x] **T2 도메인 · 데이터** — `alarm` 패키지 · 14일 선예약 sync · 권한 source · 설정 저장소 (`1abfee2` `09b5e93` `ff0b12c`)
- [x] **T3 화면** — 하단 탭 셸 · 알람 목록/편집/울림 · 설정 탭 (`b666694` `26f42df`)
- [x] **다듬기** — 표시 이름 Life Tool (`386ff21`) · 요일 한 줄 (`0b42a0c`)
- [x] **남은 시간** — 실제 예약 기준 다음 울림 · 요약 카드 · 매분 경계 갱신 · 울림 버튼 문구 · 현지화 알림 본문 (`a614ec5` `e31fd7c` `ad1a38a`), 끄기 직후 1회성 스위치 경합 수정 (`b7fe392`)
- [x] **에뮬레이터 확인** (Android 17, 2026-09-27 · 09-30) — 잠금 상태 전체 화면 울림 · 재부팅 후 예약 복원 · 사용 중 헤드업 알림 두 버튼 · 알림 스누즈 후 1회성 유지 · 매분 갱신 · 끄기 후 스위치
- [ ] **실제 폰 확인** — PIN 잠금 위 울림 화면
- [ ] **문서** — `plan.md` · `history.md` · `testing.md` · `README.md` 에 알람 · 설정 반영 (지금은 걷기 v1 기준)

- [x] **테스트 보강(TDD 변형, 2026-09-30)** — 스펙 기준 빈 곳 25개(G1~G25)를 기능별 서브에이전트 4개가
  채웠다. 먼저 실패한 테스트 = 버그 11건 수정(1회성이 울리는 순간 꺼짐 · 꺼진 알람의 5분 안 예약이 울림 ·
  꺼진 알람 스누즈 재예약 · 알림에서 끈 뒤 sync 없음 · sync 실패 시 목록 미갱신 · 권한 예외 시 저장 실패로
  보이고 중복 저장 · 목록 읽기 실패 시 무한 로딩 · 저장+재읽기 실패 시 낙관적 상태 잔류 · 깨진 prefs 로 탭 먹통 ·
  테마 prefs 타입 오류 크래시 · 남은 시간 1초 미만 자투리 버림), 예약 없음 카드 문구(사용자 결정) 추가.
  바로 통과한 테스트는 전부 뮤테이션으로 실패를 확인했다. 병합 `30700c4`.

- [x] **시간대 변경 대응(TDD, 2026-09-30)** — [설계](../../../docs/superpowers/specs/2026-09-30-walk-alarm-timezone-design.md).
  `TIMEZONE_CHANGED` 수신기 → 앱이 떠 있으면 메인 엔진에 `resync`(`timeZoneChanged` = 전체 재설정 → sync → 목록),
  아니면 헤드리스 엔진(`Alarm.init` → sync). 에뮬레이터에서 서울↔파리 양방향 · 앱 종료/전면 두 경우 모두
  예약이 같은 벽시계 시각으로 옮겨짐 확인 (`214b6f0`).

검증(2026-09-30, 시간대 대응 뒤): `flutter test` 278건 통과(1 skip).
이전 검증(2026-09-30): `flutter analyze` 0 · `flutter test` 268건 통과(1건 skip — KST 에선 DST 테스트가 스스로 건너뜀) · 디버그 APK 빌드.

## 다음 할 일

- 알람 작은 개선 후보 — 앱이 앞에 있을 때 울림 화면과 헤드업 알림이 함께 뜬다 · 울릴 때 시스템
  볼륨 패널이 뜬다(`VolumeSettings.showSystemUI`).

- 1 · 7단계 — 실제 폰에서 [기기 시나리오](testing.md#기기-시나리오--대기) ⓪~⑦.
  ⓪ 에서 활동 칼로리가 비면 칼로리 타입을 다시 정한다.
- `packages/permission` 은 다른 세션 작업으로 아직 커밋 전이다. walk 는 그것에 의존하므로
  그 커밋이 들어가야 깨끗한 체크아웃에서 빌드된다.
