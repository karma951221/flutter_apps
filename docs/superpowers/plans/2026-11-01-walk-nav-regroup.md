# walk 하단 탭 재구성 · 설정 분산 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 하단 탭을 일기 · 물어보기 · 도구(알람 | 걷기) 3개로 줄이고, 설정 탭을 기능별 설정 화면 + 앱 설정으로 나누며, 일기 앱바를 스크롤에 따라 숨긴다.

**Architecture:** 설정 탭(`SettingsPage`)의 블록을 기능별 push 화면 5개로 쪼개고, 셸 소유 cubit 을 `BlocProvider.value` 로 넘기는 `openSettings` 하나로 연다. 각 탭 앱바의 ⋮ 는 walk 전용 `FeatureMenu`(공통 `AppOverflowMenu` 감쌈)로 끝 두 항목을 고정한다. 알람 · 걷기 화면은 자기 AppBar 를 버리고 새 `ToolsTab` 의 AppBar + TabBar 아래로 들어간다.

**Tech Stack:** Flutter · flutter_bloc · gen-l10n(`packages/l10n`, 기준 `app_ko.arb`) · 공통 `design_system`.

**Spec:** [docs/superpowers/specs/2026-11-01-walk-nav-regroup-design.md](../specs/2026-11-01-walk-nav-regroup-design.md)

## Global Constraints

- 경로는 `apps/walk/` 기준. 테스트는 `test/` 아래 같은 구조(`lib/presentation/x/` ↔ `test/presentation/x/`).
- UI 규칙(CLAUDE.md): `AppListTile` · `AppOverflowMenu` · `AppPlaceholder` 등 공통 위젯 우선, `Colors.*` · 숫자 여백 · `BorderRadius.circular(n)` 금지 — `AppSpacing` · `AppMotion` · `Theme.of(context)`.
- 문구는 l10n 만. 새 키는 `app_ko.arb` · `app_en.arb` · `app_ja.arb` 셋 다, 그 뒤 `cd packages/l10n && flutter gen-l10n`.
- 생성 파일(`.freezed.dart` · `.g.dart` · `injection.config.dart`)은 손으로 고치지 않는다.
- 기존 위젯 `Key`(`settings-step-goal`, `settings-holiday-reminder`, `settings-holiday-source`, `settings-diary-lock`, `settings-diary-relock`, `settings-diary-retention`, `settings-diary-storage`)는 그대로 둔다.
- `ChatSettingsSection` 내부는 고치지 않는다(다른 세션이 키 입력 기획으로 고칠 예정). 화면 안에 넣기만 한다.
- 매 task 끝: `cd apps/walk && flutter analyze && flutter test` 통과.

## Review Focus

1. 설정 화면에서 돌아오면 알람 권한 배너 · 알람 목록이 다시 읽힌다(셸 `didPopNext` → `_refresh`). 설정 화면을 셸 `Navigator` 위로 push 해야 이게 유지된다 → Task 1 테스트.
2. 일기가 잠긴 동안 앱 설정 › 일기 설정 · 물어보기 설정은 잠금 화면을 거친다(`pushDiaryRoute`) → Task 1 테스트.
3. 일기에서 앱바가 숨은 채 다른 탭에 갔다 오면 앱바가 다시 보인다 → Task 4 테스트.
4. 홈 위젯 · 알람 울림으로 열리면 도구 탭의 **알람** 상단 탭이 보인다(걷기를 보고 있었어도) → Task 3 테스트.
5. 걷기 화면의 `active`(보일 때 다시 읽기 · 축하 1회)는 도구 탭 + 걷기 상단 탭일 때만 참 → Task 2 테스트.

---

### Task 1: 설정 화면 다섯 개와 `openSettings`

**Files:**
- Create: `lib/presentation/settings/widget/settings_widgets.dart` — `SettingsSectionHeader`, `SettingsPermissionTile`, `settingsStatusLabel`, `settingsHealthLabel`(지금 `settings_page.dart` 의 `_SectionHeader` · `_PermissionTile` · `_statusLabel` · `_healthLabel` 을 공개로 옮김)
- Create: `lib/presentation/settings/widget/lock_settings_section.dart` — `LockSettingsSection`(잠금 · 다시 잠그기 행 + 설명 "일기와 물어보기를 함께 잠급니다")
- Create: `lib/presentation/settings/widget/diary_storage_section.dart` — `DiaryStorageSection`(휴지통 보관 기간 · 저장 공간 · 로컬 안내)
- Delete: `lib/presentation/settings/widget/diary_settings_section.dart`(위 둘로 나뉨)
- Create: `lib/presentation/settings/page/{app,alarm,walk,diary,chat}_settings_page.dart`
- Create: `lib/presentation/settings/open_settings.dart`
- Modify: `lib/presentation/settings/page/settings_page.dart` — 새 섹션을 쓰도록(Task 3 에서 삭제)
- Modify: `packages/l10n/lib/l10n/app_{ko,en,ja}.arb`
- Test: `test/presentation/settings/page/{app,alarm,walk}_settings_page_test.dart`, `test/presentation/settings/open_settings_test.dart`, `test/presentation/settings/widget/lock_settings_section_test.dart`

**Interfaces:**
- Produces:
  ```dart
  enum SettingsTarget { app, diary, chat, alarm, walk }
  Future<void> openSettings(BuildContext context, SettingsTarget target);
  ```
  `context` 위에 셸의 `SettingsPermissionsCubit` · `HolidaySettingsCubit` · `DiaryLockCubit` · `DiarySettingsCubit` 가 있어야 한다. 넷을 `BlocProvider.value` 로 새 라우트에 다시 건다(`ThemeCubit` · `StepGoalCubit` 은 앱 위라 그대로 보인다). `diary` · `chat` 은 `pushDiaryRoute(context, page: …, scope: …)` 로(잠금 게이트), 나머지는 `MaterialPageRoute`. 같은 `Navigator.of(context)` 에 push 한다 — 셸 `didPopNext` 가 돌아올 때 다시 읽게.
- 화면 내용(스펙 §4 표):
  - `AlarmSettingsPage`: 공휴일 미리 알림 · 공휴일 출처 행, 권한 헤더 아래 알림 · 정확한 알람 · 전체 화면.
  - `WalkSettingsPage`: 걸음 목표, Health Connect 권한.
  - `DiarySettingsPage`: `DiaryStorageSection`.
  - `ChatSettingsPage`: `ChatSettingsSection()` 하나.
  - `AppSettingsPage`: `LockSettingsSection`, 테마(지금 라디오 그대로), "기능별 설정" 헤더 아래 일기 · 물어보기 · 알람 · 걷기 설정 행(`Key('app-settings-open-<target.name>')`, 누르면 `openSettings`).
- 각 화면은 `initState` 에서 필요한 cubit 을 읽는다(`DiarySettingsCubit.load()` — 지금 `active` 인자가 하던 일). `active` 인자는 없앤다.
- 잠금 행 동작은 지금 그대로: 잠금 행은 `LockSetupPage` 가 스스로 비밀을 확인, 다시 잠그기는 잠긴 동안 비활성(스펙 §6 의 "풀린 상태에서만"은 이것으로 충족).

**l10n 새 키**(ko / en / ja):
| 키 | ko | en | ja |
|---|---|---|---|
| `walkAppSettingsTitle` | 앱 설정 | App settings | アプリ設定 |
| `walkAlarmSettingsTitle` | 알람 설정 | Alarm settings | アラーム設定 |
| `walkWalkSettingsTitle` | 걷기 설정 | Walking settings | ウォーキング設定 |
| `walkDiarySettingsTitle` | 일기 설정 | Diary settings | 日記設定 |
| `walkChatSettingsTitle` | 물어보기 설정 | Ask settings | 質問の設定 |
| `walkAppSettingsLock` | 잠금 | Lock | ロック |
| `walkAppSettingsLockDescription` | 일기와 물어보기를 함께 잠급니다 | Locks Diary and Ask together | 日記と質問をまとめてロックします |
| `walkAppSettingsDisplay` | 화면 | Display | 表示 |
| `walkAppSettingsFeatures` | 기능별 설정 | Feature settings | 機能別の設定 |

`walkDiarySettingsLock` 값은 "잠금"으로 바꾼다(en "Lock", ja "ロック"). en · ja 의 `walkShellTabChat` 기존 번역과 어긋나면 그 번역어에 맞춰 `walkChatSettingsTitle` 을 고친다.

- [ ] **Step 1: 실패하는 테스트** — `open_settings_test.dart`: 셸 cubit 네 개를 fake/mocktail 로 제공한 `MaterialApp` 에서
  - `openSettings(ctx, SettingsTarget.alarm)` → `find.byKey(Key('settings-holiday-reminder'))` 하나, `find.text(<알림 권한 제목>)` 하나, Health Connect 제목 없음.
  - `walk` → `settings-step-goal` 과 Health Connect 제목 있음, 공휴일 행 없음.
  - `diary` 를 `DiaryLockCubit` 이 잠긴 상태에서 → 잠금 화면(`DiaryLockGate` 의 잠금 UI)이 보이고 `settings-diary-retention` 없음.
  - `app` → `settings-diary-lock` · `settings-diary-relock` 와 테마 라디오 3개, `app-settings-open-diary|chat|alarm|walk` 네 행.
  - `app` 에서 `app-settings-open-alarm` 탭 → 알람 설정 화면, 뒤로가기 → 앱 설정으로.
- [ ] **Step 2: 실행해 실패 확인** — `cd apps/walk && flutter test test/presentation/settings` → `openSettings` 미정의로 FAIL.
- [ ] **Step 3: 구현** — 위 파일들. `settings_page.dart` 는 새 섹션 · 공용 위젯으로 바꿔 지금 테스트(`settings_page_test.dart`)가 계속 통과하게.
- [ ] **Step 4: l10n** — 세 arb 에 키 추가 · 값 변경, `cd packages/l10n && flutter gen-l10n`.
- [ ] **Step 5: 통과 확인** — `cd apps/walk && flutter analyze && flutter test` → 모두 PASS.
- [ ] **Step 6: 커밋** — `feat(walk): 설정을 기능별 화면과 앱 설정으로 나눈다`

### Task 2: `FeatureMenu` 와 도구 탭

**Files:**
- Create: `lib/presentation/shell/widget/feature_menu.dart`
- Create: `lib/presentation/shell/page/tools_tab.dart`
- Modify: `lib/presentation/alarm/page/alarm_list_page.dart` — `Scaffold.appBar` 제거, 쉬기 동작을 공개 위젯 `AlarmPauseAction` 으로, 기록 열기를 `openAlarmHistory(BuildContext)` 로 꺼냄. `onOpenSettings` 인자는 그대로.
- Modify: `lib/presentation/walk/page/walk_home_page.dart` — `Scaffold.appBar` 제거.
- Modify: arb 세 개 — `walkShellTabTools`(도구 / Tools / ツール), `walkToolsTabAlarm`(알람 / Alarm / アラーム), `walkToolsTabWalk`(걷기 / Walking / ウォーキング) — 기존 `walkShellTabAlarm` · `walkShellTabWalk` 값을 쓰면 새 키를 만들지 말 것.
- Test: `test/presentation/shell/widget/feature_menu_test.dart`, `test/presentation/shell/page/tools_tab_test.dart`; 알람 · 걷기 페이지 테스트에서 AppBar 를 찾던 부분 수정.

**Interfaces:**
- Consumes: `SettingsTarget`, `openSettings` (Task 1).
- Produces:
  ```dart
  class FeatureMenuEntry {
    const FeatureMenuEntry({required this.label, required this.onTap, this.icon, this.key});
  }
  class FeatureMenu extends StatelessWidget {
    const FeatureMenu({required this.settings, this.entries = const [], this.showFeatureSettings = true, super.key});
    final SettingsTarget settings;           // "○○ 설정"이 여는 곳
    final List<FeatureMenuEntry> entries;    // 위쪽 화면별 항목
    final bool showFeatureSettings;          // false 면 "앱 설정"만(잠긴 동안)
  }
  enum ToolsSection { alarm, walk }
  class ToolsTab extends StatefulWidget {
    const ToolsTab({required this.active, required this.section, required this.onSectionChanged, required this.onOpenAlarmSettings, super.key});
    final bool active;
    final ToolsSection section;               // 셸이 소유(Task 3)
    final ValueChanged<ToolsSection> onSectionChanged;
    final VoidCallback onOpenAlarmSettings;   // AlarmListPage.onOpenSettings 로 넘김
  }
  ```
- `FeatureMenu` 는 `AppOverflowMenu` 로 그린다. 항목 순서: `entries` → (`showFeatureSettings` 면) 해당 설정(`Key('menu-settings-<settings.name>')`) → 앱 설정(`Key('menu-settings-app')`). 구분선은 `AppOverflowMenu` 가 지원하지 않으면 생략(스펙의 ─ 는 시각 보조).
- `ToolsTab`: `Scaffold(appBar: AppBar(title: 도구, actions: …, bottom: TabBar(알람, 걷기)), body: TabBarView([AlarmListPage, WalkHomePage]))`. `TabController` 는 `section` 과 동기(밖에서 바뀌면 `animateTo`, 사용자가 바꾸면 `onSectionChanged`). actions: 알람이면 `AlarmPauseAction` + `FeatureMenu(settings: alarm, entries: [알람 기록 → openAlarmHistory])`, 걷기면 `FeatureMenu(settings: walk)`. `WalkHomePage(active: active && section == walk)`.

- [ ] **Step 1: 실패하는 테스트**
  - `feature_menu_test`: 열면 항목 순서가 entries → `menu-settings-diary` → `menu-settings-app`; `showFeatureSettings: false` 면 `menu-settings-app` 하나; `menu-settings-alarm` 탭 → 알람 설정 화면 push.
  - `tools_tab_test`: 처음 알람 목록 + 쉬기 아이콘; "걷기" 탭 탭 → `onSectionChanged(ToolsSection.walk)`, 쉬기 아이콘 사라짐; 셸이 `section: alarm` 으로 다시 그리면 알람으로 돌아감; `active: true, section: walk` 일 때만 `WalkHomePage.active` 참(walk 페이지를 찾아 `active` 확인).
- [ ] **Step 2: 실행해 실패 확인** — `flutter test test/presentation/shell` → FAIL.
- [ ] **Step 3: 구현.**
- [ ] **Step 4: 통과 확인** — `flutter analyze && flutter test` → PASS(셸은 아직 옛 5탭이라 알람 · 걷기 탭에 앱바가 없는 상태가 잠시 생긴다 — Task 3 에서 셸이 `ToolsTab` 을 쓰면 해소. 셸 테스트 중 앱바 제목을 찾던 것이 깨지면 Task 3 으로 미루지 말고 여기서 고친다).
- [ ] **Step 5: 커밋** — `feat(walk): 알람 · 걷기를 묶는 도구 탭과 기능 메뉴`

### Task 3: 셸 3탭 · 설정 탭 제거 · 일기/물어보기 메뉴

**Files:**
- Modify: `lib/presentation/shell/page/main_shell_page.dart`
- Modify: `lib/presentation/diary/page/diary_tab.dart` — `_DiaryMenu` 를 `FeatureMenu(settings: diary, entries: [모든 스토리, 휴지통])` 로. 잠긴 동안 `FeatureMenu(settings: diary, showFeatureSettings: false)`(지금은 잠기면 actions 가 비어 있음 — ⋮ 는 남긴다).
- Modify: `lib/presentation/chat/page/chat_tab.dart` — actions: 풀렸으면 `[_NewConversationAction(), FeatureMenu(settings: chat)]`, 잠겼으면 `[FeatureMenu(settings: chat, showFeatureSettings: false)]`.
- Delete: `lib/presentation/settings/page/settings_page.dart`, `test/presentation/settings/page/settings_page_test.dart`(그 테스트의 항목 검사는 Task 1 테스트로 옮겨졌는지 확인 후)
- Modify: arb 세 개 — `walkShellTabSettings` 제거(다른 참조 없음 확인), `walkShellTabAlarm` · `walkShellTabWalk` 는 Task 2 가 쓰면 유지.
- Test: `test/presentation/shell/page/main_shell_page_test.dart`, `test/presentation/diary/page/diary_tab_test.dart`, `test/presentation/chat/page/chat_tab_test.dart`

**Interfaces:**
- Consumes: `openSettings`, `SettingsTarget` (Task 1); `ToolsTab`, `ToolsSection`, `FeatureMenu` (Task 2).
- `enum ShellTab { diary, chat, tools }`, 첫 값 `diary`. 셸 상태에 `ToolsSection _toolsSection = ToolsSection.alarm`.
- 홈 위젯으로 열림(`_openFromHomeWidget`) → `_tab = tools; _toolsSection = alarm`.
- `AlarmListPage.onOpenSettings` · `ChatTab.onOpenSettings` 에 `() => openSettings(context, SettingsTarget.alarm|chat)` 를 넘긴다(셸 `MultiBlocProvider` **아래** context — `Builder` 로).
- 하단 탭: 일기(`Icons.menu_book_outlined`/`menu_book`) · 물어보기(지금 아이콘) · 도구(`Icons.handyman_outlined`/`handyman`). FAB 은 `_tab == diary` 일 때 그대로.

- [ ] **Step 1: 셸 테스트를 새 동작으로 고친다(실패하게)**
  - '첫 탭은 일기, 시작할 때 예약을 동기화한다'
  - '하단 탭은 일기 · 물어보기 · 도구 셋이다'
  - '홈 화면 위젯을 눌러 열면 도구 탭의 알람으로 시작한다' — 걷기 상단 탭을 보고 있다가 위젯으로 복귀해도 알람.
  - '물어보기 [설정 열기] → 물어보기 설정 화면' (옛 '설정 탭으로 바꾼다' 대체)
  - '알람 권한 배너 → 알람 설정 화면, 돌아오면 권한을 다시 읽는다' (옛 '복귀하면 설정 권한 행을 다시 읽는다' · '설정 탭 알람 섹션' 테스트를 알람 설정 화면 기준으로)
  - '걸음 목표를 낮춰 달성해도 걷기를 열 때 한 번만 축하한다' — 설정 탭 대신 걷기 설정 화면에서 목표를 바꿈
  - 일기 탭: 잠긴 동안 ⋮ 에 `menu-settings-app` 만; 풀리면 `menu-settings-diary` 도. 물어보기도 같은 검사.
- [ ] **Step 2: 실행해 실패 확인** — `flutter test test/presentation/shell test/presentation/diary/page/diary_tab_test.dart test/presentation/chat` → FAIL.
- [ ] **Step 3: 구현.** 남은 `SettingsPage` · `walkShellTabSettings` 참조를 `grep -rn` 으로 0 개 확인.
- [ ] **Step 4: 통과 확인** — `flutter analyze && flutter test` → PASS.
- [ ] **Step 5: 커밋** — `feat(walk): 하단 탭을 일기 · 물어보기 · 도구로 줄이고 설정 탭을 없앤다`

### Task 4: 일기 앱바 — 스크롤하면 숨기

**Files:**
- Modify: `lib/presentation/diary/page/diary_tab.dart`
- Test: `test/presentation/diary/page/diary_tab_test.dart`

**Interfaces:**
- 일기 탭 `Scaffold` 의 `appBar` 를 없애고 `body: NestedScrollView(key: _scroll, floatHeaderSlivers: true, headerSliverBuilder: (_, _) => [SliverAppBar(title, actions, floating: true, snap: AppMotion.enabled(context), pinned: false)], body: DiaryLockGate(...))`. `FeedView` 의 `ListView.builder` 는 자기 controller 가 없어야 `NestedScrollView` 와 맞물린다(지금 없음 — 넣지 말 것). `_scroll` 은 `GlobalKey<NestedScrollViewState>`.
- 펼치기: `DiaryTab.active` 가 거짓→참이 될 때와 `DiaryLockCubit` 이 `LockUnlocked` 가 아닌 상태로 바뀔 때 `_scroll.currentState?.outerController.jumpTo(0)`(붙어 있을 때만).
- 애니메이션 줄이기면 `snap: false`(손가락을 따라오기만, 튀어나오는 전환 없음).

- [ ] **Step 1: 실패하는 테스트** — 기록 30개를 채운 일기 탭에서
  - 아래로 600px 끌기 → 앱바 제목(`walkShellTabDiary`) 이 화면에서 사라짐(`tester.getTopLeft(...).dy < 0` 또는 `findsNothing` hitTestable).
  - 위로 50px 끌기 + `pumpAndSettle` → 제목이 다시 보임.
  - 내린 뒤 `active: false` → `active: true` 로 다시 그리면 제목 보임.
  - `MediaQuery(disableAnimations: true)` 에서 `SliverAppBar.snap == false`.
- [ ] **Step 2: 실행해 실패 확인** — `flutter test test/presentation/diary/page/diary_tab_test.dart` → FAIL.
- [ ] **Step 3: 구현.** 일기 화면에서 push 하는 화면(검색 등)은 손대지 않는다.
- [ ] **Step 4: 통과 확인** — `flutter analyze && flutter test` → PASS.
- [ ] **Step 5: 커밋** — `feat(walk): 일기 앱바를 스크롤에 따라 숨긴다`

### Task 5: 문서

**Files:**
- Modify: `apps/walk/docs/plan.md` — 탭 구성(일기 · 물어보기 · 도구), 첫 화면, 설정 위치, "범위 밖"에서 해당 줄 정리.
- Modify: `apps/walk/docs/status.md` — 이번 작업 완료 기록(진행 상태는 여기에만).
- Modify: `apps/walk/docs/history.md` · `apps/walk/docs/testing.md` — 완료 기록 · 새 테스트 범위.
- Modify: `CLAUDE.md` 의 walk 소개 — "알람 · 걷기(Health Connect) · 일기 · 채팅(Claude API) 탭" → "일기 · 물어보기(Claude API) · 도구(알람 · 걷기 Health Connect) 탭".
- Modify: `docs/superpowers/specs/2026-11-01-walk-nav-regroup-design.md` §6 — 잠금 행 동작을 실제 구현(잠금 행은 자체 비밀 확인, 다시 잠그기는 잠긴 동안 비활성)에 맞춰 한 줄 고침. 상태를 "구현됨"으로.

- [ ] **Step 1: 고친다.**
- [ ] **Step 2: 링크 검사** — `cd apps/trader && flutter test test/convention` → PASS.
- [ ] **Step 3: 커밋** — `docs(walk): 하단 탭 재구성 · 설정 분산을 문서에 반영`
