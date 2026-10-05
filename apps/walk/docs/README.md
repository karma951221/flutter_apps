# 걷기(walk) 허브

> [문서 허브](../../../docs/README.md) · [전체 진행 현황](../../../docs/status.md)

생활 도구를 모은 앱 **Life Tool** 이다(폴더 · 패키지는 `walk`). 하단 탭 [알람 · 걷기 · 설정].

- **걷기** — 오늘 걸음을 **하루 목표** 링으로 보여주고 주간 · 월간 막대그래프(목표선)로 모아 본다. 걸음 · 거리 ·
  활동 칼로리는 폰의 헬스 앱이 **Health Connect** 에 기록한 값을 읽기만 한다.
- **알람** — 기상 알람. `alarm` 패키지로 잠금 화면 위에 울리고, 14일 치를 미리 예약해 두며,
  재부팅 · 시간대 변경 뒤에도 같은 벽시계 시각에 울린다.
- **설정** — 걷기(하루 목표) · 권한 상태 · 테마 · 앱 정보.

로그인 · 백엔드 없음, 안드로이드만.

코드는 전부 `apps/walk/` 에 있다. commute 와 같이 `lib/` 바로 아래가 계층이다 —
`core/`(앱 셸: `app.dart` · `di/` · 울림 리스너 · 백그라운드 재설정) · `data/` · `domain/` ·
`presentation/`. 계층 아래에 기능 폴더(`walk/` · `alarm/` · `settings/` · `shell/`)를 둔다. 테스트도
`test/` 아래 같은 구조다.

## 실제 폰에 설치

스토어 배포 없이 APK 를 폰에 바로 깐다. release 빌드는 아직 이 맥의 디버그 키로 서명한다
(`android/app/build.gradle.kts`).

1. **빌드** — `cd apps/walk && flutter build apk --release` →
   `apps/walk/build/app/outputs/flutter-apk/app-release.apk`(약 56MB, 모든 ABI).
2. **옮기기** — 카카오톡 나와의 채팅 · 구글 드라이브 · USB 파일 전송 중 편한 것.
3. **설치** — 폰에서 파일을 연다. 처음 한 번은 그 파일을 연 앱(카카오톡 · 내 파일 · 드라이브)에
   "출처를 알 수 없는 앱 설치"를 허용한다. Play 프로텍트 경고가 뜨면 "무시하고 설치".
4. **첫 실행** — Health Connect 권한을 허용하고, 설정 탭 권한 행에서 알림 · 정확한 알람 · 전체 화면 알림이
   켜져 있는지 본다. Android 13 이하는 Play 스토어에서 Health Connect 앱을 먼저 깐다.

고친 버전도 같은 방법으로 덮어 깔면 알람 · 설정이 남는다. 다른 맥에서 빌드한 APK 는 디버그 키가 달라
덮어 깔 수 없다 — 지우고 다시 깔아야 하고 그때 알람이 사라진다.

## 문서

| 문서 | 단일 진실 소스 |
|---|---|
| [진행 현황](status.md) | 단계별 체크리스트, 다음 할 일 |
| [계획](plan.md) | 화면 · 상태 · 완료 조건 · 범위 밖 |
| [기록](history.md) | 설계 판단 · 최종 리뷰에서 고친 것 · 알려진 한계 |
| [테스트](testing.md) | 파일별 확인 범위 · 기기 시나리오 |
| [설계 — 걷기](../../../docs/superpowers/specs/2026-09-27-walk-app-design.md) | 걷기 결정 기록 · 도메인 · 데이터 · 테스트 |
| [설계 — 알람 · 설정](../../../docs/superpowers/specs/2026-09-27-walk-alarm-design.md) | 알람 결정 · 14일 선예약 sync · 화면 · 권한 |
| [설계 — 남은 시간](../../../docs/superpowers/specs/2026-09-29-walk-alarm-remaining-time-design.md) | 요약 카드 · 남은 시간 · 울림 버튼 |
| [설계 — 시간대](../../../docs/superpowers/specs/2026-09-30-walk-alarm-timezone-design.md) | 시간대 변경 수신기 · 재설정 |
| [설계 — 시각 · 인터랙션 강화](../../../docs/superpowers/specs/2026-10-03-walk-visual-refresh-design.md) | 초록 테마 · 하루 목표 링 · 달성 축하 · 목표선 그래프 · 알람 톤 · 울림 파동 |
