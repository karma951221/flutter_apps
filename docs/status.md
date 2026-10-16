# 진행 현황 — 전체

> [문서 허브](README.md) · [아키텍처](architecture.md) · [의존 그래프](dependencies.md)

모노레포 공통 작업과 앱별 한 줄 상태만 둔다. 앱의 세부 진행은 각 앱의 `status.md`가
단일 기준이다.

## 앱

| 앱 | 상태 | 진행 현황 |
|---|---|---|
| trader (daylog) | 0~3.6단계 · 5단계(F10 모의투자) 완료, 4단계(v1.1) 대기 | [트레이더 진행 현황](../apps/trader/docs/status.md) |
| commute (통근) | v1(패키지 경계 시험) 완료 | [통근 진행 현황](../apps/commute/docs/status.md) |
| walk (걷기) | v1 코드 완료, 기기 확인 대기 | [걷기 진행 현황](../apps/walk/docs/status.md) |
| pawlog (강아지 산책) | v1 구현 완료(W1~W4), W6 stats · W7 session · W8 export 완료(2026-10-16 ~ 17), W5 social(v2) 미정 | [pawlog 진행 현황](../apps/pawlog/docs/status.md) |

## 모노레포

- [x] **모노레포 전환** — `apps/` · `packages/` pub workspace + melos
      ([프롬프트](superpowers/specs/2026-09-12-monorepo-codex-prompt.md))
- [x] **문서 앱별 재배치** — 앱 문서는 `apps/<app>/docs/`, 공통 문서만 `docs/` (2026-09-27)
- [x] **permission 패키지** — 권한 상태 · 세션당 1회 요청 정책, commute 적용 · walk 는 구현 때 적용 ([설계](superpowers/specs/2026-09-27-permission-package-design.md)) (2026-09-27)
- [x] **공통 위젯 애니메이션** — `AppMotion` 토큰과 `AppCountAction` · `AppButton` · `AppPlaceholder` · `AppListFooter` · `AppAvatar` 의 선택 애니메이션(기본 꺼짐, 애니메이션 끄기 설정 존중). 화면별로 켜는 일은 남음 ([설계](superpowers/specs/2026-10-07-design-system-animations-design.md)) (2026-10-07)

### 패키지 경계 리팩터링

둘째 앱이 알려준 [설계 §7](superpowers/specs/2026-09-13-commute-app-design.md#7-리팩터링-후보--이-앱을-만들며-확인된-것)
의 후보 목록을 푼다. pawlog 가 더한 후보(`LocationGateway` 두 벌 등)는
[pawlog 설계 §7](superpowers/specs/2026-10-03-walk-app-design.md#7-리팩터링-후보--이-앱을-만들며-확인된-것)에 있다. 설계 문서 `superpowers/specs/2026-09-13-package-boundary-design.md` 는
아직 쓰지 않았다. 브랜치 `refactor/package-boundary` 에서 작은 것부터 푼다.

- [x] **`feature_walk` → `apps/pawlog`** — pawlog 만 쓰는 코드를 앱 안 `lib/{core,data,domain,presentation}`
      (영역 dog · walk · tracking · feed · photo)로 옮기고 `packages/features/walk` 를 지웠다.
      마이크로 패키지 DI 는 앱 DI 로 합쳤다 (`edc71b9`, 2026-10-04)
- [x] **`Clock` → `core`** — pawlog 설계 §7 #4. walk 의 `Clock` 을 `core` 로 올리고 pawlog 의
      `DateTime Function() now` 주입을 바꿨다. walk 는 `CorePackageModule` 을 쓰지 않아 직접 등록한다
      (§7 #6 으로 새로 적음) (`c84ee4c`, 2026-10-04)
- [x] **`packages/location`** — pawlog 설계 §7 #1. commute · pawlog 의 `LocationGateway` 두 벌을 합치고
      서비스 → 권한 확인(`LocationAccess`)을 `permission` 의 `PermissionRequester` 위에 둔다. pawlog 도
      이제 `permission` 을 거친다 (`e908c25`, 2026-10-04)
- [ ] 통근 설계 §7 의 후보(core 의 Supabase 결합 · `Routes` · l10n 분리 · `FailureCode` 등)와
      pawlog 설계 §7 #2 · #3 · #5 · #6 — 남음

검증(2026-10-04, `e908c25`): `flutter analyze` 0건 · `flutter test` 통과 — `core` +65 · `location` +20 ·
`permission` +9 · `apps/walk` +349(건너뜀 1) · `apps/commute` +45 · `apps/pawlog` +186 · `apps/trader` +34.
