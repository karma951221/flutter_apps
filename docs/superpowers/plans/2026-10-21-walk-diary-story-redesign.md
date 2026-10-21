# Life Tool 일기 스토리식 화면 재기획 — 실행 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 일기 탭을 인스타 홈(스토리 동그라미 줄 + 피드)으로, 보기는 인스타 스토리 뷰어로, 올리기는 "사진 먼저 → 어디에 올릴지 동그라미"로 바꾼다.

**Architecture:** 데이터 계층(drift · `DiaryRepository` · `DiaryUseCase`)은 그대로 두고 `apps/walk/lib/presentation/diary/` 만 바꾼다.
뷰어의 "그룹 → 날 → 조각" 계산은 순수 함수(`presentation/diary/viewer/`)로 떼어 단위 테스트하고, 화면은 그것을 그린다.
보기 모드 3종 · 상세 · 스토리 관리 목록은 마지막 태스크에서 지운다.

**Tech Stack:** Flutter · flutter_bloc(Cubit) · freezed 3 · get_it · video_player · mocktail. 앱 경로 `apps/walk`.

**Spec:** [docs/superpowers/specs/2026-10-21-walk-diary-story-redesign-design.md](../specs/2026-10-21-walk-diary-story-redesign-design.md) (기존 설계: [2026-10-10-walk-diary-design.md](../specs/2026-10-10-walk-diary-design.md))

## Global Constraints

- CLAUDE.md 공통 위젯 · 토큰 규칙: `AppButton` · `AppSnackBar.show` · `AppPlaceholder` · `AppConfirmDialog.show` · `AppOverflowMenu` 를 쓰고 `Colors.*` · 숫자 여백 · `BorderRadius.circular(n)` 을 직접 적지 않는다(`AppColors` · `AppSpacing` · `AppRadius` · `AppMotion` · `Theme.of`).
- Freezed 는 Primary Constructor 또는 sealed union 만 쓰고, 분기는 `switch` 패턴으로 한다. 생성 파일은 `dart run build_runner build --delete-conflicting-outputs` 로만 갱신한다.
- 일기 위에 띄우는 화면은 모두 `pushDiaryRoute` 로 연다(잠금 게이트).
- 사용자에게 보이는 문자열은 `packages/l10n/lib/l10n/app_{ko,en,ja}.arb` 에 둔다(ko 기준, en · ja 도 채움). `flutter gen-l10n` 은 패키지 규칙대로 한다.
- 테스트 경로는 `lib/` 와 1:1 이다(`apps/walk/test/presentation/diary/...`).
- 시간 값(스펙 그대로): 사진 조각 5초, 글 조각 6초, 영상은 자기 길이로 한 번 재생. 지난 스토리 동그라미는 최대 10개. 탭 영역은 왼쪽 1/3 이전 · 나머지 다음.
- 각 태스크 끝: `cd apps/walk && flutter analyze` 0건, 그 태스크 테스트 통과, 커밋 하나(메시지 끝에 `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`).

## Review Focus

- 기록이 0개인 스토리 · 미디어 0개 글 기록 · 미디어 10개 기록 — 뷰어가 빈 날을 만들지 않고, 빈 스토리는 뷰어 대신 스토리 페이지를 연다(Task 1 · 2 테스트).
- 뷰어가 열린 채로 지금 기록이 휴지통으로 가거나 수정돼 날이 바뀌는 경우 — 스트림을 따라 위치를 다시 잡고, 그날이 비면 다음 날, 다 비면 닫는다(Task 3 테스트).
- 영상 파일이 없거나 초기화가 실패하는 경우 — 기존 `_Missing` 표시 뒤 사진 길이(5초)로 넘어간다. 멈춘 채 남지 않는다(Task 3 테스트).
- 뷰어 위에 수정 화면 · 시트가 얹히거나 일기가 다시 잠기는 경우 — 타이머와 영상이 멈추고, 풀리면 같은 조각에서 이어 간다(Task 3 테스트).
- "일상"(기본 스토리) — 일차 없이 날짜만 표시하고 닫기 · 삭제 메뉴가 없다(Task 3 · 5 테스트).

---

### Task 1: 뷰어 위치 계산(순수 함수)

**Files:**
- Create: `apps/walk/lib/presentation/diary/viewer/viewer_model.dart`
- Test: `apps/walk/test/presentation/diary/viewer/viewer_model_test.dart`

**Interfaces:**
- Produces:
  - `class ViewerSlide { final DiaryEntry entry; final EntryMedia? media; }` — `media == null` 이면 글 조각.
  - `class ViewerDay { final DateTime date; /* 자정 */ final List<ViewerSlide> slides; }`
  - `class ViewerGroup { final String id; final String title; final Story? story; final List<ViewerDay> days; }` — 모아보기 그룹은 `story == null`.
  - `ViewerGroup buildViewerGroup({required String id, required String title, Story? story, required List<DiaryEntry> entries})` — 휴지통 기록 제외, `occurredAt` 오름차순, 로컬 날짜별로 묶는다. 미디어는 기록 안 순서 그대로.
  - `class ViewerPos { final int group, day, slide; }` (값 동등성)
  - `ViewerPos? startPos(List<ViewerGroup> groups, int group, {String? entryId, bool fromStart = false})` — `entryId` 가 있으면 그 기록의 첫 조각. 없으면 `fromStart` 또는 닫힌 스토리는 첫날 첫 조각, 진행 중 스토리 · 모아보기는 마지막 날 첫 조각. 그룹에 날이 없으면 null.
  - `ViewerPos? nextPos(List<ViewerGroup> g, ViewerPos p)` / `ViewerPos? prevPos(...)` — 조각 → 날 → 다음 그룹(빈 그룹 건너뜀). 끝이면 null(닫기). `prevPos` 는 첫 그룹 첫날 첫 조각에서 null 대신 같은 위치를 돌려준다(인스타처럼 처음으로).
  - `ViewerPos? groupStep(List<ViewerGroup> g, ViewerPos p, int delta)` — 가로 스와이프. 대상 그룹의 `startPos`.
  - `int? dayNumber(ViewerGroup g, ViewerDay d)` — 스토리 `startedAt` 날짜 기준 1부터. 기본 스토리 · 모아보기면 null.

- [ ] **Step 1: 실패하는 테스트 쓰기** — 아래 테스트들:
  - `'날짜별로 묶고 기록 안 미디어마다 조각, 글 기록은 조각 하나'`: 10/6 사진 2장 기록 + 10/7 글 기록 + 10/7 영상 기록 → days 2개, slides 길이 `[2, 2]`, `days[1].slides[0].media == null`.
  - `'휴지통 기록은 빼고 빈 그룹은 날이 없다'`.
  - `'진행 중은 마지막 날, 닫힘 · fromStart 는 첫날, entryId 는 그 기록'`.
  - `'nextPos 는 날을 넘고 그룹을 넘고 끝에서 null'` · `'prevPos 는 전날 마지막 조각, 맨 처음에선 그대로'` · `'빈 그룹은 건너뛴다'`.
  - `'dayNumber: 시작 10/6 이면 10/7 은 2, 일상 · 모아보기는 null'`.
- [ ] **Step 2: 실행해 실패 확인** — `cd apps/walk && flutter test test/presentation/diary/viewer/viewer_model_test.dart` → 컴파일 실패.
- [ ] **Step 3: 구현** — 위 시그니처. 날짜 키는 `DateTime(y, m, d)`(로컬).
- [ ] **Step 4: 통과 확인** — 같은 명령, All tests passed.
- [ ] **Step 5: 커밋** — `feat(walk): 일기 스토리 뷰어의 날 · 조각 위치 계산을 더한다`

### Task 2: 스토리 동그라미 · 줄

**Files:**
- Create: `apps/walk/lib/presentation/diary/widget/story_ring.dart`, `apps/walk/lib/presentation/diary/widget/story_ring_row.dart`
- Modify: `apps/walk/lib/presentation/diary/widget/story_avatar.dart` (표지 원 `StoryCoverCircle` 재사용, 필요하면 크기 인자)
- Test: `apps/walk/test/presentation/diary/widget/story_ring_row_test.dart`

**Interfaces:**
- Consumes: `StoryCoverCircle`, `StoryCoversCubit` 의 `Map<String, StoryCover>` · `coverFiles(...)`(기존 `story_bar.dart`).
- Produces:
  - `List<Story> ringOrder(List<Story> open, List<Story> archived)` — 진행 중(기록 있는 것 `lastPostedAt` 최신순, 없는 것 뒤) + 닫힘(`endedAt` 최신순, 최대 10).
  - `StoryRing({required Story story, File? cover, required VoidCallback onTap, VoidCallback? onLongPress, double size})` — 진행 중이면 `colorScheme.primary` 링, 닫힘이면 `outlineVariant` 링, 아래에 한 줄 이름.
  - `StoryRingRow({required List<Story> open, required List<Story> archived, required Map<String, File?> covers, required VoidCallback onCreate, required ValueChanged<Story> onOpen, required ValueChanged<Story> onLongPress, required VoidCallback onSeeAll, String? selectedId, bool showSeeAll = true})` — 맨 앞 `＋ 새 스토리`, 끝 `모두 보기`. `selectedId` 는 작성 화면용 체크 표시(Task 7).
- [ ] **Step 1: 실패하는 테스트** — `'＋ · 진행 중(최신순, 빈 것 뒤) · 닫힘 10개까지 · 모두 보기 순서'`(이름 텍스트의 x 좌표 순서), `'탭은 onOpen, 길게는 onLongPress, ＋ 는 onCreate'`, `'진행 중 링은 primary, 닫힘은 outlineVariant'`(링 `DecoratedBox` border 색), `'selectedId 에 체크'`.
- [ ] **Step 2: 실패 확인** — `flutter test test/presentation/diary/widget/story_ring_row_test.dart`.
- [ ] **Step 3: 구현** — 가로 `ListView`, 칸 너비 고정(토큰), `AppMotion` 없이 정적.
- [ ] **Step 4: 통과 확인.**
- [ ] **Step 5: 커밋** — `feat(walk): 인스타식 스토리 동그라미 줄을 더한다`

### Task 3: 스토리 뷰어 화면

**Files:**
- Create: `apps/walk/lib/presentation/diary/viewer/story_viewer_page.dart`, `apps/walk/lib/presentation/diary/viewer/story_progress_bar.dart`, `apps/walk/lib/presentation/diary/viewer/viewer_slide_view.dart`
- Modify: `apps/walk/lib/presentation/diary/widget/entry_media_view.dart` — `VideoSurface` 에 `loop`(기본 true) · `playing` · `onEnded` · `onReady(Duration)` 인자를 더한다(기존 호출은 그대로 동작)
- Modify: `apps/walk/lib/presentation/diary/page/entry_detail_page.dart` 의 수정 · 옮기기 · 휴지통 동작 코드를 뷰어가 쓸 수 있게 `apps/walk/lib/presentation/diary/page/entry_actions.dart` 로 뺀다(`Future<void> editEntry(BuildContext, DiaryEntry)`, `Future<void> moveEntry(BuildContext, DiaryEntry)`, `Future<bool> trashEntry(BuildContext, DiaryEntry)` — 되돌리기 스낵바 포함). 상세 페이지는 이 파일을 쓰게 바꾼다(Task 8 에서 지움).
- l10n: `walkDiaryDayNumber(n)`("{n}일차"), `walkDiaryViewerClose`.
- Test: `apps/walk/test/presentation/diary/viewer/story_viewer_page_test.dart`, `apps/walk/test/presentation/diary/page/entry_actions_test.dart`(상세 테스트에서 옮김)

**Interfaces:**
- Consumes: Task 1 전부, `MediaStore.resolve`, `pushDiaryRoute`, `DiaryRepository.watchEntries/watchStories`.
- Produces:
  - `sealed class ViewerSource` (freezed union): `ViewerSource.stories(List<String> storyIds)` — 링 순서의 스토리들, `ViewerSource.filter(EntryFilter filter, String title)` — 모아보기 그룹 하나.
  - `Future<void> openStoryViewer(BuildContext context, ViewerSource source, {int group = 0, String? entryId, bool fromStart = false})` — 페이드 전환으로 띄운다.
  - `StoryViewerPage({required ViewerSource source, int group, String? entryId, bool fromStart, VideoBuilder? videoBuilder})` — 테스트용 `videoBuilder` 주입(기존 릴스와 같은 방식).
- 동작(스펙 §3.2): 스트림으로 그룹을 만들고 위치를 기록 id 로 붙잡아 갱신 시 다시 찾는다. 조각 길이만큼 `AnimationController` 를 돌리고 끝나면 `nextPos`, null 이면 `Navigator.pop`. 탭(왼쪽 1/3 이전) · 길게 누르기 멈춤(머리 · 글 숨김) · `PageView` 가로 그룹 넘김 · 아래로 드래그 닫기. `RouteAware`/`TickerMode` 와 `AppLifecycleListener` 로 얹힘 · 백그라운드 멈춤. 다크 테마(`WalkTheme.dark()`).
- [ ] **Step 1: 실패하는 테스트** (가짜 저장소 스트림 + 가짜 videoBuilder):
  - `'진행 중 스토리는 마지막 날 첫 조각, 머리에 이름 · n일차 · 날짜'`
  - `'5초 뒤 다음 조각, 그날 끝이면 다음 날, 마지막이면 닫힌다'` (`pump(Duration(seconds: 5))`)
  - `'글 조각은 6초, 영상은 onReady 길이 뒤 onEnded 로 넘어간다'`
  - `'오른쪽 탭 다음 · 왼쪽 1/3 탭 이전 · 길게 누르면 멈추고 글이 숨는다'`
  - `'가로로 넘기면 다음 스토리의 시작 위치'` · `'아래로 끌면 닫힌다'`
  - `'⋮ 휴지통 → 스낵바, 다음 조각으로, 그날이 비면 다음 날'`
  - `'위에 화면이 얹히면 멈추고 걷히면 같은 조각에서 이어 간다'`
  - `'영상 실패면 5초 뒤 넘어간다'` · `'일상은 일차 없이 날짜만'`
  - `'모아보기 소스는 #이름 머리, 가로로 넘길 그룹 없음'`
- [ ] **Step 2: 실패 확인** — `flutter test test/presentation/diary/viewer/`.
- [ ] **Step 3: 구현** — 위 인터페이스. 진행 막대는 `StoryProgressBar(count, index, progress: Animation<double>)`.
- [ ] **Step 4: 통과 확인** — 뷰어 · `entry_actions` · 기존 `entry_detail_page_test` · `view_modes_test` 모두 통과.
- [ ] **Step 5: 커밋** — `feat(walk): 인스타식 일기 스토리 뷰어를 더한다`

### Task 4: 스토리 페이지 + 기록 그리드 + 모든 스토리

**Files:**
- Create: `apps/walk/lib/presentation/diary/widget/entry_grid.dart` — `EntryGrid({required List<DiaryEntry> entries, required ValueChanged<DiaryEntry> onOpen})`(3열 정사각, 최신 위, 영상 ▶ · 여러 장 겹침 아이콘 · 글 타일). 슬리버로도 쓸 수 있게 `SliverEntryGrid` 를 함께 둔다.
- Create: `apps/walk/lib/presentation/diary/page/story_page.dart` — `Future<void> openStoryPage(BuildContext, String storyId)`. 머리(큰 표지 원 · 이름 · 기간 · 기록 n · 사진 n · `▶ 처음부터 보기`) + `SliverEntryGrid`. ⋮ = 이름 · 표지 · 닫기/다시 열기 · 삭제(기존 `StoryManageCubit` 메서드와 `story_manage_page.dart` 의 시트 · 다이얼로그 코드를 옮김). 삭제가 성공하면 pop.
- Create: `apps/walk/lib/presentation/diary/page/all_stories_page.dart` — `Future<void> openAllStories(BuildContext)`. 앱바 ＋(기존 `story_form_sheet` 만들기 흐름, 지난 기간이면 일상 옮기기 제안 그대로) + "진행 중" · "지난 스토리" 2열 카드. 카드를 누르면 `openStoryPage`.
- Delete: `apps/walk/lib/presentation/diary/page/story_manage_page.dart` 와 그 테스트. 동작 테스트는 아래 새 테스트로 옮긴다.
- l10n: `walkDiaryAllStories`, `walkDiaryPlayFromStart`, `walkDiaryStoryStats(entries, photos)`, `walkDiaryOngoing`, `walkDiaryPastStories`, `walkDiaryNewStory`, `walkDiarySeeAll`.
- Test: `test/presentation/diary/widget/entry_grid_test.dart`, `test/presentation/diary/page/story_page_test.dart`, `test/presentation/diary/page/all_stories_page_test.dart`

**Interfaces:**
- Consumes: Task 3 `openStoryViewer(ViewerSource.stories([id]), fromStart: true / entryId:)`, `StoryManageCubit`, `StoryCoversCubit`.
- Produces: `openStoryPage(BuildContext, String storyId)`, `openAllStories(BuildContext)`, `EntryGrid` / `SliverEntryGrid`.
- [ ] **Step 1: 실패하는 테스트** — 그리드: `'최신 위 3열, 영상 ▶, 여러 장 아이콘, 글 타일, 탭 onOpen'`. 스토리 페이지: `'머리 통계 · 처음부터 보기 → 뷰어 fromStart'`, `'칸 탭 → 뷰어 그 기록'`, `'⋮ 이름 바꾸기 · 닫기 · 다시 열기 · 삭제(확인 → pop)'`, `'일상은 닫기 · 삭제 없음'`. 모든 스토리: `'진행 중 · 지난 구역 카드, 탭 → 스토리 페이지'`, `'＋ 만들기 · 지난 기간이면 일상 옮기기 제안'`(기존 story_manage 테스트에서 옮김).
- [ ] **Step 2: 실패 확인.**
- [ ] **Step 3: 구현.**
- [ ] **Step 4: 통과 확인** — `flutter test test/presentation/diary/`.
- [ ] **Step 5: 커밋** — `feat(walk): 스토리 페이지와 모든 스토리 화면을 더하고 스토리 관리 목록을 대신한다`

### Task 5: 일기 탭 = 동그라미 줄 + 피드

**Files:**
- Modify: `apps/walk/lib/presentation/diary/page/diary_tab.dart` — `_Timeline` 을 앱바(일기 🔍 ⋮) + `StoryRingRow` + 피드로 바꾼다. 보기 모드 분기 · `StoryHeader` · 릴스 오버레이를 없앤다. ⋮ 은 "모든 스토리 · 휴지통"이다.
- Modify: `apps/walk/lib/presentation/diary/cubit/diary_timeline_cubit.dart` + `diary_timeline_state.dart` — `selectedStoryId` · `viewMode` 를 빼고 항상 `EntryFilter.all()` 을 구독한다(`openStories` · `archived` · `entries` · `loading` · `failed` 만).
- Modify: `apps/walk/lib/presentation/diary/widget/feed_view.dart` — 카드 머리를 `StoryCoverCircle`(작게) · 스토리 이름 · 장소 · ⋮(Task 3 `entry_actions`)로 바꾸고, `onOpenStory(Story)` 를 받는다. 미디어 칸은 4:5 + `1/n` 표시이고 영상은 썸네일 + ▶ 로 자동재생하지 않는다.
- Test: `apps/walk/test/presentation/diary/page/diary_tab_test.dart`(보기 모드 · 릴스 · 스토리 고르기 그룹은 지우고 새로 씀), `apps/walk/test/presentation/diary/cubit/diary_timeline_cubit_test.dart`, `apps/walk/test/presentation/diary/widget/feed_view_test.dart`(또는 기존 `view_modes_test.dart` 의 피드 부분)

**Interfaces:**
- Consumes: Task 2 `StoryRingRow`, Task 3 `openStoryViewer` · `entry_actions`, Task 4 `openStoryPage` · `openAllStories`(⋮ 모든 스토리 · ＋새 스토리는 `openAllStories` 의 만들기 흐름 또는 `story_form_sheet` 직접).
- [ ] **Step 1: 실패하는 테스트** — `'앱바 · 동그라미 줄 · 모든 스토리 기록 피드(최신순), 보기 모드 토글 없음'`, `'동그라미 탭 → 뷰어(그 스토리, 진행 중이면 마지막 날)'`, `'기록 없는 스토리 탭 → 스토리 페이지'`, `'카드 탭 → 뷰어 그 기록', '카드 머리 탭 → 스토리 페이지'`, `'⋮ 모든 스토리 · 휴지통'`, `'잠긴 동안 ＋ 숨김'`(기존 유지), `'피드 영상은 자동재생하지 않는다'`.
- [ ] **Step 2: 실패 확인** — `flutter test test/presentation/diary/page/diary_tab_test.dart test/presentation/diary/cubit/`.
- [ ] **Step 3: 구현.** `build_runner` 로 state 재생성.
- [ ] **Step 4: 통과 확인.**
- [ ] **Step 5: 커밋** — `feat(walk): 일기 탭을 스토리 동그라미 줄과 피드로 바꾼다`

### Task 6: 태그 · 장소 모아보기를 그리드로

**Files:**
- Modify: `apps/walk/lib/presentation/diary/page/filtered_entries_page.dart` — 보기 모드 · 릴스 오버레이(커밋 `e9e3249`)를 걷어내고 머리 `기록 n개` + `▶ 보기` + `SliverEntryGrid` 로 바꾼다. `▶ 보기` = `openStoryViewer(ViewerSource.filter(filter, title), fromStart: true)`, 칸을 누르면 `entryId:`.
- Modify: `apps/walk/lib/presentation/diary/cubit/filtered_entries_cubit.dart` + state — `viewMode` · `DiaryPreferences` 의존을 뺀다.
- Test: `test/presentation/diary/page/filtered_entries_page_test.dart`, `test/presentation/diary/cubit/filtered_entries_cubit_test.dart`
- [ ] **Step 1: 실패하는 테스트** — `'태그: 제목 · 개수 · 그리드'`(기존 수정), `'▶ 보기 → 모아보기 소스 뷰어'`, `'칸 탭 → 그 기록부터'`. 보기 모드 · 릴스 테스트는 지운다.
- [ ] **Step 2 ~ 4: 실패 확인 → 구현 → 통과.**
- [ ] **Step 5: 커밋** — `feat(walk): 태그 · 장소 모아보기를 그리드와 뷰어로 바꾼다`

### Task 7: 올리기 — ＋ 시트와 작성 화면 배치

**Files:**
- Modify: `apps/walk/lib/presentation/diary/page/diary_tab.dart` 의 ＋ — 시트(앨범에서 · 카메라 · 영상 촬영 · 글만 쓰기)를 먼저 띄운다. 미디어를 고르면 `openEntryEditor(context, initialPick: source)` 로, 글만이면 `openEntryEditor(context)` 로 간다. 시트를 닫으면 아무것도 하지 않는다. 시트 항목은 `media_strip.dart` 의 고르기 시트를 공용 `showMediaSourceSheet(BuildContext, {bool textOnly = false}) -> Future<MediaSourceChoice?>` 로 빼서 함께 쓴다.
- Modify: `apps/walk/lib/presentation/diary/page/entry_editor_page.dart` — `openEntryEditor(BuildContext, {String? editingId, MediaSource? initialPick})`. 처음 열 때 `initialPick` 이 있으면 그 고르기를 바로 실행한다(잠금 예외 `MediaPickGuard` 그대로). 배치(스펙 §3.6): 큰 미디어 미리보기 `PageView`(마지막 칸 ＋, 길게 눌러 빼기) → "어디에 올릴까요?" `StoryRingRow(selectedId:, showSeeAll: false)`(새 기록은 진행 중만, 수정은 닫힘 포함; ＋새 → `story_form_sheet` 로 만들고 `setStory`) → 글 → 태그 → 장소 → 시각. 올린 뒤 `AppSnackBar.show` `walkDiaryPostedTo(title)`.
- Modify: `apps/walk/lib/presentation/diary/widget/media_strip.dart` → 큰 미리보기로 바꾸거나 `media_preview_pager.dart` 를 새로 만들고 `media_strip.dart` 를 지운다(쓰는 곳이 작성 화면뿐이면).
- Delete: `apps/walk/lib/presentation/diary/widget/story_picker_sheet.dart`(동그라미 줄이 대신; 다른 사용처가 없을 때).
- l10n: `walkDiaryWhereToPost`, `walkDiaryTextOnly`, `walkDiaryPostedTo(title)`.
- Test: `test/presentation/diary/page/entry_editor_page_test.dart`, `test/presentation/diary/page/diary_tab_test.dart`(＋ 시트)

**Interfaces:**
- Consumes: Task 2 `StoryRingRow`, 기존 `EntryEditorCubit`(`setStory` · `save` · `cancel` · 미디어 추가/제거 메서드 그대로).
- [ ] **Step 1: 실패하는 테스트** — `'＋ → 시트 4항목, 닫으면 아무 화면도 안 뜸'`, `'앨범에서 → 작성 화면이 열리며 고르기가 한 번 실행'`, `'글만 쓰기 → 미디어 없이 작성 화면'`, `'어디에 올릴까요 줄: 제안 스토리 체크, 탭하면 setStory, 새 기록엔 닫힌 스토리 없음'`, `'＋새 → 만들기 시트 → 만든 스토리 선택'`, `'올리면 스낵바 "제주 여행에 올렸어요"'`, `'수정은 기존 값 · 닫힌 스토리도 줄에'`. 기존 저장 · 시각 · 장소 · 태그 · 임시 사본 테스트는 유지(찾는 위젯만 고침).
- [ ] **Step 2 ~ 4: 실패 확인 → 구현 → 통과** — `flutter test test/presentation/diary/page/entry_editor_page_test.dart test/presentation/diary/page/diary_tab_test.dart`.
- [ ] **Step 5: 커밋** — `feat(walk): 올리기를 사진 먼저 · 스토리 동그라미 고르기로 바꾼다`

### Task 8: 검색 연결 · 옛 화면 지우기

**Files:**
- Modify: `apps/walk/lib/presentation/diary/page/diary_search_page.dart` — 글 결과는 `openStoryViewer(ViewerSource.stories([entry.storyId]), entryId: entry.id)`, 스토리 결과는 `openStoryPage`. 지금은 스토리 id 를 pop 으로 돌려주는데, 일기 탭에 "고른 스토리"가 없으니 바로 연다.
- Delete: `presentation/diary/page/entry_detail_page.dart`, `widget/prose_view.dart`, `widget/reels_view.dart`, `widget/view_mode_switch.dart`, `widget/diary_entries_view.dart`, `widget/story_header.dart`, `widget/story_bar.dart`(쓰는 `coverFiles` 는 `story_ring_row.dart` 로 옮김), `domain/diary/entity/diary_view_mode.dart`, 그리고 각 테스트.
- Modify: `domain/diary/repository/diary_preferences.dart` · `data/diary/prefs_diary_preferences.dart` — `viewMode` · `lastViewedStoryId` 를 지운다(저장된 키는 읽지 않을 뿐 지우지 않음). 테스트도 고친다.
- Modify: `packages/l10n` ARB — 쓰지 않는 일기 키(보기 모드 이름 · 보관함 시트 · 상세 전용)를 지운다. `grep -rn "<key>" apps packages` 로 사용처가 0 인 것만 지운다.
- Test: `test/presentation/diary/page/diary_search_page_test.dart`, 그리고 `flutter test` 전체.
- [ ] **Step 1: 실패하는 테스트** — `'글 결과 탭 → 그 기록부터 뷰어'`, `'스토리 결과 탭 → 스토리 페이지'`.
- [ ] **Step 2: 실패 확인.**
- [ ] **Step 3: 구현 + 지우기.** `dart run build_runner build --delete-conflicting-outputs`.
- [ ] **Step 4: 전체 확인** — `cd apps/walk && flutter analyze` 0건, `flutter test` 전체 통과, `cd ../trader && flutter test test/convention`(문서 링크).
- [ ] **Step 5: 커밋** — `refactor(walk): 검색을 뷰어 · 스토리 페이지로 잇고 보기 모드 · 상세 · 스토리 관리 화면을 지운다`

### Task 9: 기기 확인 · 문서

**Files:**
- Modify: `apps/walk/docs/status.md`(일기 절: "화면 재기획" 행과 커밋들), `apps/walk/docs/history.md`(2026-10-21 재기획 판단: 스펙 §1 · 이 계획의 판단 — 하루 단위 막대, 진행 중은 마지막 날부터, 피드 영상 자동재생 안 함, 본 것 표시 없음), `apps/walk/docs/testing.md`(새 테스트 표 · 지운 테스트 · 기기 시나리오 D2 · D8 · D15 기대 문구를 뷰어 기준으로 바꾸고 결과는 "재확인 대기"), `apps/walk/docs/plan.md` 의 일기 화면 설명이 있으면 같은 내용으로.
- [ ] **Step 1: 디버그 APK** — `cd apps/walk && flutter build apk --debug` 후 `adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-debug.apk`(에뮬레이터 화면 잠금이 풀려 있을 때). 탭 → 동그라미 → 뷰어 자동 넘김 · 탭 · 스와이프 · 닫기, ＋ → 앨범 → 작성 → 올리기, 스토리 페이지 · 모든 스토리 · 모아보기를 스크린샷으로 확인한다. 어색한 것은 TDD 로 고치고 커밋 하나씩 남긴다.
- [ ] **Step 2: 문서 갱신** — 위 파일들.
- [ ] **Step 3: 최종 확인** — `flutter analyze` 0건 · `flutter test` 전체 통과 · 문서 링크 테스트 통과.
- [ ] **Step 4: 커밋** — `docs(walk): 일기 스토리식 재기획을 현황 · 기록 · 테스트 문서에 싣는다`
