# walk 알람 · 설정 탭 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development. 태스크마다 스펙을 함께 읽는다.

**Goal:** `apps/walk` 를 하단 탭 [알람 · 걷기 · 설정] 앱으로 바꾼다. 알람은 `alarm` 패키지로 울리는 기상 알람, 설정은 권한 모아보기 · 테마 · 앱 정보.

**Spec:** [walk 알람 설계](../specs/2026-09-27-walk-alarm-design.md) — 결정 · 도메인 · 동기화 · 화면 · 권한 · 테스트의 단일 기준.

## Global Constraints

- 안드로이드만. 명령은 `apps/walk` 에서. 코드 생성 `dart run build_runner build --delete-conflicting-outputs`.
- 의존 패키지는 `core` · `design_system` · `l10n` · `permission` 만(`test/convention/package_boundary_test.dart`).
- CLAUDE.md 의 UI 공통 위젯 규칙 · Freezed 규칙 · 테스트 위치 규칙(lib ↔ test 1:1)을 따른다.
- 문자열은 `packages/l10n/lib/l10n/app_{ko,en,ja}.arb` 에 `walkAlarm*` · `walkSettings*` · `walkShell*` 접두사. `flutter gen-l10n` 은 l10n 패키지 방식대로.
- 날짜 산술은 `DateTime(y, m, d + n, h, mi)` 생성자. `Duration` 더하기로 날짜를 넘기지 않는다(스누즈 5분은 예외).
- 시간 의존 코드는 기존 `domain/clock.dart` 의 `Clock` 을 주입받는다.
- 커밋은 경로 지정: `git add <경로> && git commit -m "…" -- <경로>`. 메시지는 기존 스타일(`feat(walk): …` 한국어) + 끝에 `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. `.idea/` 는 절대 add 하지 않는다.
- 각 태스크 끝: `flutter analyze` 0 이슈 · `flutter test` 전부 통과.

## 태스크

### T1 — 기존 코드를 `walk/` 하위로 이동 (이동만)
- `lib/domain/{entity,repository,usecase}` → `lib/domain/walk/…`, `lib/data/{health,repository}` → `lib/data/walk/…`, `lib/presentation/{cubit,page,widget,format}` → `lib/presentation/walk/…`. `domain/clock.dart` · `core/` 는 그대로.
- `test/` 도 같은 구조로. import 수정, `injection.config.dart` 재생성.
- 커밋: `refactor(walk): 걷기 코드를 walk/ 하위 폴더로 옮긴다`

### T2 — 알람 도메인 · 데이터 · 안드로이드 설정
- 의존성 추가(스펙 §3), 매니페스트(alarm README 요구 항목 + §7 권한), 표시 이름 "걷기·알람", 기본 알람음 에셋.
- `main.dart` 에서 `await Alarm.init()`.
- 스펙 §4 · §5 · §7 의 domain/alarm, domain/settings, data/alarm, data/settings, data/app_info 전부 + DI 등록 + 테스트(§8).
- 커밋 여러 개 가능: 의존성·안드로이드 / 도메인 / 데이터.

### T3 — 셸 · 설정 탭 · 알람 화면
- 스펙 §6 전부: `MainShellPage`, `SettingsPage`(+ 테마 → `MaterialApp.themeMode`), `AlarmListPage` · `AlarmEditPage` · `AlarmRingingPage`, `core/alarm_ring_listener.dart`(전역 navigatorKey), resumed 시 sync · 권한 재확인.
- l10n 문자열(ko · en · ja), cubit bloc_test, 페이지 위젯 테스트.
- 커밋 여러 개 가능: 셸·설정 / 알람 화면.

### T4 — 리뷰 · 문서
- 리뷰 서브에이전트 → 판정 → 수정.
- `apps/walk/docs/{plan,status,history,testing,README}.md` 갱신, 디버그 APK 빌드, 기기 확인(§9)은 사용자와.
