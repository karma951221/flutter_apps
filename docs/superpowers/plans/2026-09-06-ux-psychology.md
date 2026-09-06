# UX 심리학 리뷰 반영 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** [UX 심리학 6원칙 리뷰](../../../ux-psychology-review.md) 의 발견 1~7 을 앱에 반영한다 — 서버 스키마 변경 없이, 화면·ARB·라우터·settings 의 작은 data 계층만 더한다.

**Architecture:** 각 Task 는 feature 하나에 닫힌다 (feed · auth · post · profile · settings · router). 새 backend 객체는 없다 — 게시물·댓글 개수는 기존 테이블에 `count` 를 던지고, 비로그인 열람은 이미 `anon` 에 열린 `posts_with_author` 를 그대로 읽는다. 라우터 redirect 는 순수 함수로 뽑아 단위 테스트한다.

**Tech Stack:** Flutter(bloc·freezed·get_it/injectable·go_router·gen-l10n) + Supabase(postgrest count, 기존 RLS/GRANT).

**Spec:** [`ux-psychology-review.md`](../../../ux-psychology-review.md) (발견 사항 · 제안 · 하지 말 것). 충돌 시 이 계획의 "확정한 결정" 이 우선한다 — 사용자가 "임의로 결정해서 다 반영" 을 지시했다.

## 확정한 결정 (리뷰의 "결정이 필요한 것" 에 대한 답)

| 리뷰 항목 | 결정 |
|---|---|
| 4. 게스트 피드 | **기본 진입은 로그인 화면 그대로.** 로그인 화면에 "먼저 둘러보기" 텍스트 버튼 → 읽기 전용 `/explore`. 모든 상호작용은 가입 안내 시트로 보낸다. Patrol E2E 와 라우터 게이트는 그대로다 |
| 5. 가입 직후 프로필 꾸미기 | **1안만.** 가입 화면에서 인증되면 redirect 가 `/profile/setup` 으로 보낸다. 기존 `EditProfilePage` 를 `isSetup` 모드로 재사용. "나중에" 로 건너뛴다 |
| 7. 글자 수 카운터 | 남은 글자 **50자 이하일 때만** 보인다. 색 경고는 기존 20자 유지. `minLines` 6 → 3 |
| 1. 완성도 카드 "첫 팔로우" | 탭 동작 없음 (셸 탭 전환 인프라를 만들지 않는다). 나머지 셋은 탭하면 이동 |
| 8. `0 팔로워` 앵커 | 작업 없음 — 완성도 카드가 대체한다 |
| 브랜치 | `feat/ux-psychology` (main 에서 분기, 이미 만들어져 있다) |

## Global Constraints

- 사용자에게 보이는 새 문자열은 **ARB 세 벌(ko·en·ja)** 로만 만든다. 화면에 하드코딩 금지. template 은 `app/lib/l10n/app_ko.arb` 이고 **ko 의 모든 키는 `@key` 에 `description` 이 있어야 한다** (`test/convention/arb_description_convention_test.dart`). en·ja 에는 `@` 메타를 두지 않는다
- ARB 를 바꾸면 `cd app && flutter gen-l10n` 을 돌려 `AppLocalizations` 를 갱신한다 (빌드 시 자동이지만 테스트 전에 명시적으로 돌린다)
- UI 는 공통 위젯(`AppButton`·`AppSnackBar`·`AppAvatar`·`AppPlaceholder`·`AppConfirmDialog`·`AppListTile`)과 `AppSpacing`·`AppRadius` 토큰만 쓴다. `Colors.*`·숫자 여백·`BorderRadius.circular(n)` 직접 사용 금지
- Freezed 는 Primary Constructor 패턴(단일 모델) 또는 sealed union 패턴만. 분기는 Dart `switch` 우선
- `.freezed.dart`·`.g.dart`·`injection.config.dart` 는 직접 수정하지 않고 `cd app && dart run build_runner build --delete-conflicting-outputs` 로 갱신
- 테스트 위치는 구현 미러링: `app/lib/features/<f>/…` ↔ `app/test/features/<f>/…`. 위젯 테스트는 `MaterialApp(locale: ko, AppTheme.light(), AppLocalizations delegates)` + `getIt.registerFactory` + `tearDown(getIt.reset)` 패턴을 따른다 (`test/features/settings/presentation/page/account_settings_page_test.dart` 가 가장 짧은 원본)
- Supabase SDK 타입은 `data/` 밖으로 내보내지 않는다 (아키텍처 규칙 ①). Repository 는 `RepositoryErrorHandler.guard` 로 예외를 `Result` 로 바꾼다 (규칙 ④)
- 스키마 변경 없음. 마이그레이션을 만들지 않는다
- 진행 상태는 `docs/status.md` 에만 적는다 (마지막 Task 에서 한 번)
- 커밋 메시지는 한국어 현재형 `type(scope): …한다` 형식, 끝에 `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`
- 모든 Flutter 명령은 `app/` 에서 실행한다. 각 Task 끝에 `flutter analyze` 무결함 + 해당 feature 테스트 통과 + `flutter test test/convention` 통과

---

### Task 1: 팔로잉 탭 빈 상태에 "사람 둘러보기" 행동

**Files:**
- Modify: `app/lib/features/feed/presentation/page/feed_page.dart` (`_FeedViewState.build` · `_FeedList` · `_empty`)
- Modify: `app/lib/l10n/app_ko.arb`, `app/lib/l10n/app_en.arb`, `app/lib/l10n/app_ja.arb`
- Test: `app/test/features/feed/presentation/page/feed_page_test.dart`
- Docs: `docs/features/feed/plan.md` (화면 상태 표), `docs/testing/features/feed.md` (표)

**Interfaces:**
- Consumes: `FeedCubit.load()` / `loadFollowing()` (탭 리스너가 이미 부른다), `AppPlaceholder(actionLabel, onAction)`
- Produces: ARB 키 `feedFollowingEmptyAction`

- [ ] **Step 1: ARB 키 추가** — 세 파일의 `feedFollowingEmptyDescription` 바로 아래에 넣는다.

`app_ko.arb`:
```json
  "feedFollowingEmptyAction": "사람 둘러보기",
  "@feedFollowingEmptyAction": {
    "description": "팔로잉 탭이 비어 있을 때의 행동 버튼. 누르면 전체 탭으로 옮긴다"
  },
```
`app_en.arb`: `"feedFollowingEmptyAction": "Browse everyone",`
`app_ja.arb`: `"feedFollowingEmptyAction": "みんなの投稿を見る",`

Run: `cd app && flutter gen-l10n`

- [ ] **Step 2: 실패하는 테스트 작성** — `feed_page_test.dart` 의 `main()` 안, 마지막 `testWidgets` 뒤에 추가:

```dart
  testWidgets('팔로잉 탭이 비어 있으면 사람 둘러보기로 전체 탭에 보낸다', (tester) async {
    when(
      () => feedUseCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        authorId: any(named: 'authorId'),
        source: FeedSource.all,
      ),
    ).thenAnswer(
      (_) async => Ok(CursorPage<FeedPost>(items: [_item('1', 'other', '이웃')])),
    );
    when(
      () => feedUseCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        authorId: any(named: 'authorId'),
        source: FeedSource.following,
      ),
    ).thenAnswer((_) async => const Ok(CursorPage<FeedPost>(items: [])));

    await pumpPage(tester);
    await tester.tap(find.text('팔로잉'));
    await tester.pumpAndSettle();

    expect(find.text('팔로우한 사람이 없습니다'), findsOneWidget);
    expect(find.text('사람 둘러보기'), findsOneWidget);

    await tester.tap(find.text('사람 둘러보기'));
    await tester.pumpAndSettle();

    final tabBar = tester.widget<TabBar>(find.byType(TabBar));
    expect(tabBar.controller!.index, 0);
    expect(find.text('기록 1'), findsOneWidget);
  });
```

- [ ] **Step 3: 실패 확인**

Run: `cd app && flutter test test/features/feed/presentation/page/feed_page_test.dart`
Expected: FAIL — `사람 둘러보기` 를 찾지 못한다.

- [ ] **Step 4: 구현** — `feed_page.dart`

`_FeedViewState.build` 의 `FeedStatus.loaded => _FeedList(...)` 에 인자 하나 추가:
```dart
          FeedStatus.loaded => _FeedList(
            items: state.items,
            currentUserId: currentAuthor?.id ?? '',
            isLoadingMore: state.isLoadingMore,
            canLoadMore: state.canLoadMore,
            isFollowingTab: _isFollowingTab,
            onCompose: () => _compose(context, currentAuthor),
            // 탭을 옮기면 리스너가 load() 를 부른다 — 여기서 다시 읽지 않는다.
            onBrowseAll: () => _tabController.animateTo(0),
          ),
```

`_FeedList` 에 필드·생성자 인자 추가:
```dart
  const _FeedList({
    required this.items,
    required this.currentUserId,
    required this.isLoadingMore,
    required this.canLoadMore,
    required this.isFollowingTab,
    required this.onCompose,
    required this.onBrowseAll,
  });
  …
  final VoidCallback onCompose;

  /// 팔로잉 탭이 비어 있을 때 전체 탭으로 보내는 행동. 빈 화면이 막다른 길이
  /// 되지 않게 한다 (ux-psychology-review.md 2번).
  final VoidCallback onBrowseAll;
```

`_empty` 의 팔로잉 분기:
```dart
                  ? AppPlaceholder(
                      icon: Icons.people_outline,
                      message: l10n.feedFollowingEmptyMessage,
                      description: l10n.feedFollowingEmptyDescription,
                      actionLabel: l10n.feedFollowingEmptyAction,
                      onAction: onBrowseAll,
                    )
```

- [ ] **Step 5: 통과 확인**

Run: `cd app && flutter test test/features/feed && flutter analyze && flutter test test/convention`
Expected: 전부 PASS.

- [ ] **Step 6: 문서** — `docs/features/feed/plan.md` 화면 상태 표의 "비어 있음" 행 아래에 한 행:
```
| 비어 있음 (팔로잉) | 팔로잉 탭 · 항목 0개 | "팔로우한 사람이 없습니다" + "사람 둘러보기" 버튼 → 전체 탭으로 이동 |
```
`docs/testing/features/feed.md` 표의 `HomeShellPage` 행 앞에:
```
| `FeedPage` | 팔로잉 탭 빈 상태 | "사람 둘러보기" 를 누르면 전체 탭으로 옮기고 전체 피드를 읽는다. |
```

- [ ] **Step 7: Commit**
```bash
git add app/lib/features/feed app/lib/l10n docs/features/feed/plan.md docs/testing/features/feed.md
git commit -m "feat(feed): 팔로잉 빈 상태에 사람 둘러보기 행동을 붙인다"
```

---

### Task 2: 가입 폼 autofill 힌트 + 닉네임 제안값

**Files:**
- Modify: `app/lib/features/auth/presentation/widget/auth_text_field.dart` (`onChanged` 인자 추가)
- Modify: `app/lib/features/auth/presentation/page/sign_up_page.dart`
- Create: `app/test/features/auth/presentation/page/sign_up_page_test.dart`
- Docs: `docs/features/auth/plan.md` (입력 검증 절), `docs/testing/features/auth.md` (표)

**Interfaces:**
- Consumes: `Validators.nickname(String?)` → `ValidationError?`, `Validators.nicknameMaxLength`, `SignUpCubit.submit({email, password, nickname})`
- Produces: `AuthTextField.onChanged: ValueChanged<String>?`

- [ ] **Step 1: 실패하는 테스트 작성** — 새 파일 `sign_up_page_test.dart`:

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:daylog/core/di/injection.dart';
import 'package:daylog/design_system/theme/app_theme.dart';
import 'package:daylog/features/auth/presentation/cubit/sign_up_cubit.dart';
import 'package:daylog/features/auth/presentation/cubit/submit_state.dart';
import 'package:daylog/features/auth/presentation/page/sign_up_page.dart';
import 'package:daylog/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSignUpCubit extends MockCubit<SubmitState> implements SignUpCubit {}

void main() {
  late _MockSignUpCubit cubit;

  setUp(() {
    cubit = _MockSignUpCubit();
    whenListen(
      cubit,
      const Stream<SubmitState>.empty(),
      initialState: const SubmitState.idle(),
    );
    getIt.registerFactory<SignUpCubit>(() => cubit);
  });

  tearDown(getIt.reset);

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SignUpPage(),
      ),
    );
    await tester.pump();
  }

  String nicknameText(WidgetTester tester) => tester
      .widget<TextFormField>(find.byKey(const Key('signUp.nickname')))
      .controller!
      .text;

  testWidgets('가입 폼은 자동 완성 그룹 안에 있다', (tester) async {
    await pumpPage(tester);
    expect(find.byType(AutofillGroup), findsOneWidget);
  });

  testWidgets('이메일에서 벗어나면 로컬 파트를 닉네임 제안값으로 채운다', (tester) async {
    await pumpPage(tester);

    await tester.enterText(
      find.byKey(const Key('signUp.email')),
      'karma951221@example.test',
    );
    await tester.tap(find.byKey(const Key('signUp.nickname')));
    await tester.pump();

    expect(nicknameText(tester), 'karma951221');
  });

  testWidgets('사용자가 닉네임을 이미 적었으면 덮어쓰지 않는다', (tester) async {
    await pumpPage(tester);

    await tester.enterText(find.byKey(const Key('signUp.nickname')), '내이름');
    await tester.enterText(
      find.byKey(const Key('signUp.email')),
      'karma951221@example.test',
    );
    await tester.tap(find.byKey(const Key('signUp.password')));
    await tester.pump();

    expect(nicknameText(tester), '내이름');
  });

  testWidgets('닉네임을 지운 뒤에는 다시 제안하지 않는다', (tester) async {
    await pumpPage(tester);

    await tester.enterText(find.byKey(const Key('signUp.nickname')), '내이름');
    await tester.enterText(find.byKey(const Key('signUp.nickname')), '');
    await tester.enterText(
      find.byKey(const Key('signUp.email')),
      'karma951221@example.test',
    );
    await tester.tap(find.byKey(const Key('signUp.password')));
    await tester.pump();

    expect(nicknameText(tester), '');
  });

  testWidgets('규칙에 맞지 않는 로컬 파트는 제안하지 않는다', (tester) async {
    await pumpPage(tester);

    // 1자 — 닉네임 최소 길이(2) 미만.
    await tester.enterText(find.byKey(const Key('signUp.email')), 'a@example.test');
    await tester.tap(find.byKey(const Key('signUp.nickname')));
    await tester.pump();

    expect(nicknameText(tester), '');
  });

  testWidgets('제안값은 최대 길이로 잘라 넣는다', (tester) async {
    await pumpPage(tester);

    await tester.enterText(
      find.byKey(const Key('signUp.email')),
      'abcdefghijklmnopqrstuvwxyz@example.test',
    );
    await tester.tap(find.byKey(const Key('signUp.nickname')));
    await tester.pump();

    expect(nicknameText(tester), 'abcdefghijklmnopqrst');
  });
}
```

- [ ] **Step 2: 실패 확인**

Run: `cd app && flutter test test/features/auth/presentation/page/sign_up_page_test.dart`
Expected: FAIL — `AutofillGroup` 없음, 닉네임이 비어 있음.

- [ ] **Step 3: `AuthTextField` 에 `onChanged` 추가** — `auth_text_field.dart`

생성자와 필드:
```dart
    this.onSubmitted,
    this.onChanged,
    super.key,
  });
  …
  final VoidCallback? onSubmitted;

  /// 사용자가 직접 입력할 때만 불린다. 컨트롤러 값을 코드로 바꿀 때는 불리지
  /// 않으므로 "사용자가 손댔는가" 를 구분하는 데 쓴다.
  final ValueChanged<String>? onChanged;
```
`TextFormField(` 에 `onChanged: widget.onChanged,` 한 줄 추가.

- [ ] **Step 4: `SignUpPage` 구현** — `sign_up_page.dart`

상태 필드에 추가:
```dart
  final _emailFocus = FocusNode();
  …
  /// 사용자가 닉네임 칸에 손댔는가. 손댔으면 제안값으로 덮어쓰지 않는다 —
  /// 지운 것도 결정이다.
  bool _nicknameEdited = false;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(_onEmailFocusChanged);
  }
```
`dispose` 에 `_emailFocus..removeListener(_onEmailFocusChanged)..dispose();` 추가 (기존 dispose 목록에 넣는다).

메서드 둘:
```dart
  void _onEmailFocusChanged() {
    if (!_emailFocus.hasFocus) _suggestNickname();
  }

  /// 이메일 로컬 파트를 닉네임 제안값으로 넣는다.
  ///
  /// 기본값은 추천으로 읽히므로 규칙(2~20자)에 맞을 때만 채우고, 사용자가
  /// 닉네임 칸에 손댔거나 이미 값이 있으면 아무것도 하지 않는다
  /// (ux-psychology-review.md 3번).
  void _suggestNickname() {
    if (_nicknameEdited || _nickname.text.isNotEmpty) return;
    final local = _email.text.trim().split('@').first;
    final candidate = local.length > Validators.nicknameMaxLength
        ? local.substring(0, Validators.nicknameMaxLength)
        : local;
    if (Validators.nickname(candidate) != null) return;
    _nickname.text = candidate;
  }
```

`build` 의 폼: `Form(` 을 `AutofillGroup(child: Form(…))` 으로 감싼다 (`sign_in_page.dart:72` 와 같은 모양). 필드 인자:
- 이메일: `focusNode: _emailFocus,` · `autofillHints: const [AutofillHints.email],`
- 닉네임: `onChanged: (_) => _nicknameEdited = true,`
- 비밀번호·비밀번호 확인: `autofillHints: const [AutofillHints.newPassword],`

- [ ] **Step 5: 통과 확인**

Run: `cd app && flutter test test/features/auth && flutter analyze`
Expected: PASS. 기존 `sign_in_page_test` 도 그대로 통과한다.

- [ ] **Step 6: 문서** — `docs/features/auth/plan.md` "입력 검증" 목록 끝에:
```
- 닉네임 제안값: 이메일 칸을 벗어날 때 닉네임이 비어 있고 사용자가 손대지 않았으면
  로컬 파트(`@` 앞)를 2~20자 규칙에 맞을 때만 채운다. 비밀번호 두 칸은
  `AutofillHints.newPassword`, 이메일은 `AutofillHints.email`
```
`docs/testing/features/auth.md` 표의 `SignInPage` 행들 뒤에:
```
| `SignUpPage` | 자동 완성 | 폼이 `AutofillGroup` 안에 있다. |
| `SignUpPage` | 닉네임 제안값 | 이메일에서 벗어나면 로컬 파트를 닉네임에 채운다. 사용자가 손댔거나(지운 것 포함) 규칙에 어긋나면 채우지 않고, 20자를 넘으면 잘라 넣는다. |
```

- [ ] **Step 7: Commit**
```bash
git add app/lib/features/auth app/test/features/auth docs/features/auth/plan.md docs/testing/features/auth.md
git commit -m "feat(auth): 가입 폼에 자동 완성 힌트와 닉네임 제안값을 넣는다"
```

---

### Task 3: 글자 수 카운터는 상한에 가까울 때만

**Files:**
- Modify: `app/lib/features/post/presentation/page/post_editor_page.dart` (`TextFormField.minLines`, `_ContentCounter`)
- Test: `app/test/features/post/presentation/page/post_editor_page_test.dart` (기존 '글자 수는 정책 상수를 기준으로 센다' 교체)
- Docs: `docs/testing/features/post.md` (표), `docs/features/post/plan.md` (화면과 상태 표)

**Interfaces:**
- Consumes: `PostPolicy.maxContentLength` (500)
- Produces: `_ContentCounter.visibleThreshold = 50`

- [ ] **Step 1: 테스트 교체** — `post_editor_page_test.dart` 의 `'글자 수는 정책 상수를 기준으로 센다'` 테스트를 아래 둘로 바꾼다:

```dart
  testWidgets('글자 수는 상한에 가까워지기 전에는 보이지 않는다', (tester) async {
    await pumpEditor(tester);

    await tester.enterText(find.byType(TextFormField), '오늘의 기록');
    await tester.pump();

    expect(
      find.textContaining('/ ${PostPolicy.maxContentLength}'),
      findsNothing,
    );
  });

  testWidgets('남은 글자가 50자 이하가 되면 정책 상수를 기준으로 센다', (tester) async {
    await pumpEditor(tester);

    final nearLimit = 'ㄱ' * (PostPolicy.maxContentLength - 50);
    await tester.enterText(find.byType(TextFormField), nearLimit);
    await tester.pump();

    expect(
      find.text('${nearLimit.length} / ${PostPolicy.maxContentLength}'),
      findsOneWidget,
    );
  });
```

- [ ] **Step 2: 실패 확인**

Run: `cd app && flutter test test/features/post/presentation/page/post_editor_page_test.dart`
Expected: 첫 테스트 FAIL (`6 / 500` 이 보인다).

- [ ] **Step 3: 구현** — `_ContentCounter`:

```dart
class _ContentCounter extends StatelessWidget {
  const _ContentCounter({required this.length});

  /// 이 값 이하로 남았을 때부터 카운터를 그린다.
  ///
  /// 처음부터 `0 / 500` 을 보여주면 500 이 기대 길이로 읽힌다 — 첫 숫자가
  /// 기준이 된다 (ux-psychology-review.md 7번). 짧은 글이 정상인 피드에서는
  /// 상한이 가까워졌을 때만 알리면 된다.
  static const visibleThreshold = 50;

  static const _warningThreshold = 20;

  final int length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = PostPolicy.maxContentLength - length;
    if (remaining > visibleThreshold) return const SizedBox.shrink();
    final isWarning = remaining <= _warningThreshold;
    // 아래는 기존 코드 그대로 (Align + Text)
```
`TextFormField` 의 `minLines: 6,` → `minLines: 3,`.

- [ ] **Step 4: 통과 확인**

Run: `cd app && flutter test test/features/post && flutter analyze`
Expected: PASS.

- [ ] **Step 5: 문서** — `docs/testing/features/post.md` 의 `PostEditorPage | 글자 수` 행을:
```
| `PostEditorPage` | 글자 수 | 남은 글자가 50자 이하일 때만 `PostPolicy.maxContentLength` 기준으로 보인다. 그 전에는 카운터를 그리지 않는다. |
```
`docs/features/post/plan.md` "화면과 상태" 표의 작성 행 완료 조건 끝에 ` 글자 수는 남은 글자 50자 이하일 때만 보인다.` 를 덧붙인다.

- [ ] **Step 6: Commit**
```bash
git add app/lib/features/post app/test/features/post docs/testing/features/post.md docs/features/post/plan.md
git commit -m "feat(post): 글자 수 카운터를 상한 50자 이내에서만 보여준다"
```

---

### Task 4: 프로필 완성도 카드

**Files:**
- Create: `app/lib/features/profile/presentation/widget/profile_completion_card.dart`
- Modify: `app/lib/features/profile/presentation/page/profile_page.dart` (`_ProfileView.build` 의 slivers)
- Modify: ARB 3벌
- Create: `app/test/features/profile/presentation/widget/profile_completion_card_test.dart`
- Modify: `app/test/features/profile/presentation/page/profile_page_test.dart`
- Docs: `docs/features/profile/plan.md` (화면별 상태 표), `docs/testing/features/profile.md` (표)

**Interfaces:**
- Consumes: `Profile(avatarUrl, bio, followingCount)`, `FeedState(status, items)`, `AppListTile(leading, title, trailing, onTap)`, `Routes.profileEdit`, `Routes.postCompose`
- Produces: `ProfileCompletionCard({required Profile profile, required bool hasPost, required VoidCallback onEditProfile, required VoidCallback onWritePost})` — 다섯 항목이 전부 끝나면 `SizedBox.shrink()` 를 그린다

- [ ] **Step 1: ARB 키 추가** — `profileBioEmpty` 아래에.

`app_ko.arb`:
```json
  "profileCompletionTitle": "프로필 완성 {percent}%",
  "@profileCompletionTitle": {
    "description": "내 프로필의 완성도 카드 제목. percent 는 0~100 정수",
    "placeholders": {
      "percent": {
        "type": "int"
      }
    }
  },
  "profileCompletionNickname": "닉네임 정하기",
  "@profileCompletionNickname": {
    "description": "완성도 카드 항목. 가입 때 이미 끝났으므로 항상 완료로 표시된다"
  },
  "profileCompletionAvatar": "프로필 사진 올리기",
  "@profileCompletionAvatar": {
    "description": "완성도 카드 항목. 누르면 프로필 편집으로 간다"
  },
  "profileCompletionBio": "자기소개 쓰기",
  "@profileCompletionBio": {
    "description": "완성도 카드 항목. 누르면 프로필 편집으로 간다"
  },
  "profileCompletionFirstPost": "첫 게시물 남기기",
  "@profileCompletionFirstPost": {
    "description": "완성도 카드 항목. 누르면 게시물 작성으로 간다"
  },
  "profileCompletionFirstFollow": "마음에 드는 사람 팔로우하기",
  "@profileCompletionFirstFollow": {
    "description": "완성도 카드 항목. 홈 피드에서 하는 일이라 누를 수 없다"
  },
```
`app_en.arb`:
```json
  "profileCompletionTitle": "Profile {percent}% complete",
  "profileCompletionNickname": "Pick a nickname",
  "profileCompletionAvatar": "Add a profile photo",
  "profileCompletionBio": "Write a bio",
  "profileCompletionFirstPost": "Write your first post",
  "profileCompletionFirstFollow": "Follow someone you like",
```
`app_ja.arb`:
```json
  "profileCompletionTitle": "プロフィール完成度 {percent}%",
  "profileCompletionNickname": "ニックネームを決める",
  "profileCompletionAvatar": "プロフィール写真を追加",
  "profileCompletionBio": "自己紹介を書く",
  "profileCompletionFirstPost": "最初の投稿を書く",
  "profileCompletionFirstFollow": "気になる人をフォロー",
```
Run: `cd app && flutter gen-l10n`

- [ ] **Step 2: 위젯 테스트 작성** — `profile_completion_card_test.dart`:

```dart
import 'package:daylog/design_system/theme/app_theme.dart';
import 'package:daylog/features/profile/domain/entity/profile.dart';
import 'package:daylog/features/profile/presentation/widget/profile_completion_card.dart';
import 'package:daylog/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Profile _profile({String? avatarUrl, String? bio, int followingCount = 0}) =>
    Profile(
      id: 'me',
      nickname: '카르마',
      avatarUrl: avatarUrl,
      bio: bio,
      createdAt: DateTime.utc(2026, 9, 6),
      updatedAt: DateTime.utc(2026, 9, 6),
      followingCount: followingCount,
    );

void main() {
  Future<void> pumpCard(
    WidgetTester tester, {
    required Profile profile,
    bool hasPost = false,
    VoidCallback? onEditProfile,
    VoidCallback? onWritePost,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ProfileCompletionCard(
            profile: profile,
            hasPost: hasPost,
            onEditProfile: onEditProfile ?? () {},
            onWritePost: onWritePost ?? () {},
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('새 프로필은 닉네임 하나로 20% 에서 시작한다', (tester) async {
    await pumpCard(tester, profile: _profile());

    expect(find.text('프로필 완성 20%'), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, closeTo(0.2, 0.001));
    expect(find.text('닉네임 정하기'), findsOneWidget);
    expect(find.text('프로필 사진 올리기'), findsOneWidget);
    expect(find.text('자기소개 쓰기'), findsOneWidget);
    expect(find.text('첫 게시물 남기기'), findsOneWidget);
    expect(find.text('마음에 드는 사람 팔로우하기'), findsOneWidget);
  });

  testWidgets('끝난 항목은 체크로, 남은 항목은 빈 원으로 그린다', (tester) async {
    await pumpCard(
      tester,
      profile: _profile(avatarUrl: 'https://x/a.webp', followingCount: 2),
      hasPost: true,
    );

    expect(find.text('프로필 완성 80%'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNWidgets(4));
    expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
  });

  testWidgets('사진·자기소개는 프로필 편집으로, 첫 게시물은 작성으로 보낸다', (tester) async {
    var editTaps = 0;
    var writeTaps = 0;
    await pumpCard(
      tester,
      profile: _profile(),
      onEditProfile: () => editTaps++,
      onWritePost: () => writeTaps++,
    );

    await tester.tap(find.text('프로필 사진 올리기'));
    await tester.tap(find.text('자기소개 쓰기'));
    await tester.tap(find.text('첫 게시물 남기기'));
    // 팔로우 항목과 이미 끝난 닉네임 항목은 눌러도 아무 일도 없다.
    await tester.tap(find.text('마음에 드는 사람 팔로우하기'));
    await tester.tap(find.text('닉네임 정하기'));

    expect(editTaps, 2);
    expect(writeTaps, 1);
  });

  testWidgets('다섯 항목이 모두 끝나면 카드를 그리지 않는다', (tester) async {
    await pumpCard(
      tester,
      profile: _profile(
        avatarUrl: 'https://x/a.webp',
        bio: '안녕',
        followingCount: 1,
      ),
      hasPost: true,
    );

    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.textContaining('프로필 완성'), findsNothing);
  });
}
```

- [ ] **Step 3: 실패 확인**

Run: `cd app && flutter test test/features/profile/presentation/widget/profile_completion_card_test.dart`
Expected: FAIL — 파일이 없어 컴파일 오류.

- [ ] **Step 4: 위젯 구현** — `profile_completion_card.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../../design_system/theme/app_radius.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/widget/app_list_tile.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entity/profile.dart';

/// 내 프로필 상단의 완성도 카드.
///
/// 닉네임은 가입 때 이미 정했으므로 언제나 첫 칸이 채워진 채로 시작한다 —
/// 0% 에서 시작하는 진행률은 동기가 되지 않는다 (목표 구배,
/// ux-psychology-review.md 1번). 근거 없는 칸은 채우지 않는다: 다섯 항목
/// 모두 앱이 이미 아는 값으로 판정한다.
///
/// 다섯 항목이 전부 끝나면 아무것도 그리지 않는다.
class ProfileCompletionCard extends StatelessWidget {
  const ProfileCompletionCard({
    required this.profile,
    required this.hasPost,
    required this.onEditProfile,
    required this.onWritePost,
    super.key,
  });

  final Profile profile;

  /// 게시물 목록 첫 페이지가 비어 있지 않은가. 목록을 소유한 화면이 준다.
  final bool hasPost;

  final VoidCallback onEditProfile;
  final VoidCallback onWritePost;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final steps = <_CompletionStep>[
      _CompletionStep(label: l10n.profileCompletionNickname, isDone: true),
      _CompletionStep(
        label: l10n.profileCompletionAvatar,
        isDone: profile.avatarUrl != null,
        onTap: onEditProfile,
      ),
      _CompletionStep(
        label: l10n.profileCompletionBio,
        isDone: profile.bio?.trim().isNotEmpty ?? false,
        onTap: onEditProfile,
      ),
      _CompletionStep(
        label: l10n.profileCompletionFirstPost,
        isDone: hasPost,
        onTap: onWritePost,
      ),
      _CompletionStep(
        label: l10n.profileCompletionFirstFollow,
        isDone: profile.followingCount > 0,
      ),
    ];
    final done = steps.where((step) => step.isDone).length;
    if (done == steps.length) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final progress = done / steps.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: AppRadius.lgAll,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.profileCompletionTitle((progress * 100).round()),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    LinearProgressIndicator(value: progress),
                  ],
                ),
              ),
              for (final step in steps)
                AppListTile(
                  leading: Icon(
                    step.isDone
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: step.isDone ? scheme.primary : scheme.outline,
                  ),
                  title: Text(step.label),
                  trailing: step.isDone || step.onTap == null
                      ? null
                      : const Icon(Icons.chevron_right),
                  onTap: step.isDone ? null : step.onTap,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompletionStep {
  const _CompletionStep({required this.label, required this.isDone, this.onTap});

  final String label;
  final bool isDone;

  /// 없으면 이 화면에서 할 수 있는 일이 아니다 (팔로우는 홈 피드에서 한다).
  final VoidCallback? onTap;
}
```

`AppRadius.lgAll` 은 `app_radius.dart` 에 이미 있는 `BorderRadius` 상수다. `surfaceContainerLow` 는 Material 3 `ColorScheme` 의 표준 토큰이다 (`post_tile.dart` 가 `surfaceContainerHighest` 를 같은 방식으로 쓴다).

- [ ] **Step 5: 위젯 테스트 통과 확인**

Run: `cd app && flutter test test/features/profile/presentation/widget/profile_completion_card_test.dart`
Expected: PASS.

- [ ] **Step 6: 프로필 화면 테스트 추가** — `profile_page_test.dart` 의 `main()` 끝에:

```dart
  testWidgets('내 프로필은 완성도 카드를 20% 로 시작한다', (tester) async {
    when(profileUseCase.getMyProfile)
        .thenAnswer((_) async => Ok(_profile('me', '카르마')));
    when(
      () => feedUseCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        authorId: any(named: 'authorId'),
        source: any(named: 'source'),
      ),
    ).thenAnswer((_) async => const Ok(CursorPage<FeedPost>(items: [])));

    await pumpPage(tester);
    await tester.pumpAndSettle();

    expect(find.text('프로필 완성 20%'), findsOneWidget);
  });

  testWidgets('타인 프로필에는 완성도 카드가 없다', (tester) async {
    when(() => profileUseCase.getProfile('other'))
        .thenAnswer((_) async => Ok(_profile('other', '이웃')));
    when(
      () => feedUseCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        authorId: any(named: 'authorId'),
        source: any(named: 'source'),
      ),
    ).thenAnswer((_) async => const Ok(CursorPage<FeedPost>(items: [])));

    await pumpPage(tester, userId: 'other');
    await tester.pumpAndSettle();

    expect(find.textContaining('프로필 완성'), findsNothing);
  });
```
`pumpPage` 의 정확한 시그니처와 stub 이름은 파일 상단(`pumpPage(WidgetTester tester, {String? userId})`)을 따른다. 기존 테스트가 `getMyProfile` 을 어떻게 stub 하는지 보고 같은 형태로 맞춘다.

- [ ] **Step 7: 프로필 화면에 카드 삽입** — `profile_page.dart` 의 `slivers:` 안, 헤더 `SliverToBoxAdapter` 와 게시물 제목 `SliverToBoxAdapter(child: Padding(... Text(l10n.profilePostsTitle)))` **사이**에:

```dart
                    // 내 프로필에만. 첫 게시물 여부는 목록을 소유한 FeedCubit 이
                    // 알고, 목록을 읽는 중에는 깜빡임을 피하려 그리지 않는다.
                    if (isMine)
                      SliverToBoxAdapter(
                        child: BlocBuilder<FeedCubit, FeedState>(
                          builder: (context, feedState) =>
                              feedState.status != FeedStatus.loaded
                              ? const SizedBox.shrink()
                              : Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.lg,
                                  ),
                                  child: ProfileCompletionCard(
                                    profile: profile,
                                    hasPost: feedState.items.isNotEmpty,
                                    onEditProfile: () async {
                                      await context.push(Routes.profileEdit);
                                      if (context.mounted) {
                                        context.read<ProfileCubit>().load();
                                      }
                                    },
                                    onWritePost: () async {
                                      final feed = context.read<FeedCubit>();
                                      final created = await context.push<Post>(
                                        Routes.postCompose,
                                      );
                                      if (created != null) await feed.refresh();
                                    },
                                  ),
                                ),
                        ),
                      ),
```
import 추가: `import '../../../post/domain/entity/post.dart';` 와 `import '../widget/profile_completion_card.dart';`.

- [ ] **Step 8: 통과 확인**

Run: `cd app && flutter test test/features/profile test/features/home && flutter analyze && flutter test test/convention`
Expected: PASS. `home_shell_page_test` 가 프로필 탭을 그리므로 함께 돌린다.

- [ ] **Step 9: 문서** — `docs/features/profile/plan.md` "화면별 상태" 표에:
```
| 프로필 (내) | 완성도 카드 | 닉네임·사진·자기소개·첫 게시물·첫 팔로우 다섯 칸. 닉네임은 항상 완료라 20% 에서 시작한다. 다섯 개가 끝나면 사라진다 |
```
`docs/testing/features/profile.md` 표에:
```
| `ProfileCompletionCard` | 새 프로필 / 일부 완료 / 전부 완료 | 20% 로 시작하고, 끝난 항목은 체크·남은 항목은 빈 원이며, 전부 끝나면 그리지 않는다. 사진·자기소개는 편집으로, 첫 게시물은 작성으로 보낸다. |
| `ProfilePage` | 완성도 카드 | 내 프로필에만 그린다. 타인 프로필에는 없다. |
```

- [ ] **Step 10: Commit**
```bash
git add app/lib/features/profile app/lib/l10n app/test/features/profile docs/features/profile/plan.md docs/testing/features/profile.md
git commit -m "feat(profile): 내 프로필에 20% 에서 시작하는 완성도 카드를 붙인다"
```

---

### Task 5: 탈퇴 확인에 실제 게시물·댓글 개수

**Files:**
- Create: `app/lib/features/settings/domain/entity/account_content_summary.dart`
- Create: `app/lib/features/settings/domain/repository/account_repository.dart`
- Create: `app/lib/features/settings/domain/usecase/scenario/get_my_content_summary_scenario.dart`
- Create: `app/lib/features/settings/domain/usecase/account_use_case.dart`
- Create: `app/lib/features/settings/data/datasource/account_data_source.dart`
- Create: `app/lib/features/settings/data/datasource/supabase_account_data_source.dart`
- Create: `app/lib/features/settings/data/repository/account_repository_impl.dart`
- Modify: `app/lib/features/settings/presentation/page/account_settings_page.dart` (`_confirmDelete`)
- Modify: ARB 3벌
- Create: `app/test/features/settings/data/repository/account_repository_impl_test.dart`
- Modify: `app/test/features/settings/presentation/page/account_settings_page_test.dart`
- Docs: `docs/features/settings/plan.md` (상태 절), `docs/testing/features/settings.md` (표)

**Interfaces:**
- Consumes: `RepositoryErrorHandler.guard`, `Failure.auth(code: 'not_authenticated', failureCode: FailureCode.authenticationRequired)`, `SupabaseClient` (DI 등록됨), postgrest `from(table).count(CountOption.exact)` → `PostgrestFilterBuilder<int>` (필터 체이닝 가능, 최종 `await` 가 `int`)
- Produces:
  - `AccountContentSummary({required int postCount, required int commentCount})`
  - `AccountDataSource.myContentSummary() → Future<({int postCount, int commentCount})?>` (세션 없으면 null)
  - `AccountRepository.myContentSummary() → Future<Result<AccountContentSummary>>`
  - `AccountUseCase.myContentSummary() → Future<Result<AccountContentSummary>>` (`@LazySingleton(as: AccountUseCase)`)
  - ARB `accountDeleteConfirmMessageCounted(int postCount, int commentCount)`

- [ ] **Step 1: ARB 키** — `accountDeleteConfirmMessage` 아래에.

`app_ko.arb`:
```json
  "accountDeleteConfirmMessageCounted": "계정과 함께 아래가 모두 삭제되며 되돌릴 수 없습니다.\n\n· 프로필과 프로필 사진\n· 작성한 게시물 {postCount}개와 사진\n· 남긴 댓글 {commentCount}개와 감정표현",
  "@accountDeleteConfirmMessageCounted": {
    "description": "탈퇴 확인 본문. 실제 게시물·댓글 개수를 넣은 판. 개수 조회에 실패하면 accountDeleteConfirmMessage 를 쓴다",
    "placeholders": {
      "postCount": {
        "type": "int"
      },
      "commentCount": {
        "type": "int"
      }
    }
  },
```
`app_en.arb`: `"accountDeleteConfirmMessageCounted": "The following will be permanently deleted with your account:\n\n• Profile and profile photo\n• {postCount} posts and their photos\n• {commentCount} comments and reactions",`
`app_ja.arb`: `"accountDeleteConfirmMessageCounted": "アカウントとともに以下がすべて削除され、元に戻せません。\n\n・プロフィールとプロフィール写真\n・投稿 {postCount}件と写真\n・コメント {commentCount}件とリアクション",`

Run: `cd app && flutter gen-l10n`

- [ ] **Step 2: domain 파일**

`account_content_summary.dart`:
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'account_content_summary.freezed.dart';

/// 탈퇴 확인에 보여줄 "잃게 될 것" 의 개수.
///
/// 종류만 나열하면 심리적 무게가 없다 — 이름과 숫자여야 한다
/// (손실 회피, ux-psychology-review.md 6번). 정보이지 압박이 아니므로
/// 이 값으로 버튼 문구를 바꾸지 않는다.
@freezed
class AccountContentSummary with _$AccountContentSummary {
  @override
  final int postCount;
  @override
  final int commentCount;

  const AccountContentSummary({
    required this.postCount,
    required this.commentCount,
  });
}
```

`account_repository.dart`:
```dart
import '../../../../core/result/result.dart';
import '../entity/account_content_summary.dart';

/// 계정 단위의 조회. 탈퇴처럼 계정 자체에 손대는 흐름이 쓴다.
abstract interface class AccountRepository {
  /// 로그인한 사용자가 남긴 게시물·댓글 개수 (소프트 삭제 제외).
  Future<Result<AccountContentSummary>> myContentSummary();
}
```

`scenario/get_my_content_summary_scenario.dart`:
```dart
import '../../../../../core/result/result.dart';
import '../../entity/account_content_summary.dart';
import '../../repository/account_repository.dart';

class GetMyContentSummaryScenario {
  const GetMyContentSummaryScenario(this._repository);

  final AccountRepository _repository;

  Future<Result<AccountContentSummary>> call() =>
      _repository.myContentSummary();
}
```

`account_use_case.dart`:
```dart
import 'package:injectable/injectable.dart';

import '../../../../core/result/result.dart';
import '../entity/account_content_summary.dart';
import '../repository/account_repository.dart';
import 'scenario/get_my_content_summary_scenario.dart';

/// settings feature 의 presentation 진입점 (계정 단위 조회).
///
/// 탈퇴 실행 자체는 세션을 없애는 일이라 `AuthUseCase.deleteAccount` 에 남아
/// 있다. 여기는 그 앞에서 보여줄 것을 읽는다.
abstract interface class AccountUseCase {
  Future<Result<AccountContentSummary>> myContentSummary();
}

@LazySingleton(as: AccountUseCase)
class DefaultAccountUseCase implements AccountUseCase {
  DefaultAccountUseCase(this._repository);

  final AccountRepository _repository;

  @override
  Future<Result<AccountContentSummary>> myContentSummary() =>
      GetMyContentSummaryScenario(_repository)();
}
```

- [ ] **Step 3: data 파일**

`account_data_source.dart`:
```dart
/// 계정 단위 조회의 원천. 세션이 없으면 null 을 돌려준다 — 판정은 repository 가 한다.
abstract interface class AccountDataSource {
  Future<({int postCount, int commentCount})?> myContentSummary();
}
```

`supabase_account_data_source.dart`:
```dart
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'account_data_source.dart';

@LazySingleton(as: AccountDataSource)
class SupabaseAccountDataSource implements AccountDataSource {
  SupabaseAccountDataSource(this._client);

  final SupabaseClient _client;

  /// HEAD 요청 두 번. 행을 받지 않고 `Content-Range` 의 개수만 읽는다.
  /// 소프트 삭제된 행은 RLS 가 이미 숨기지만, 정책이 바뀌어도 개수가 흔들리지
  /// 않도록 `deleted_at is null` 을 명시한다.
  @override
  Future<({int postCount, int commentCount})?> myContentSummary() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final postCount = await _client
        .from('posts')
        .count(CountOption.exact)
        .eq('author_id', userId)
        .isFilter('deleted_at', null);
    final commentCount = await _client
        .from('post_comments')
        .count(CountOption.exact)
        .eq('author_id', userId)
        .isFilter('deleted_at', null);
    return (postCount: postCount, commentCount: commentCount);
  }
}
```

`account_repository_impl.dart`:
```dart
import 'package:injectable/injectable.dart';

import '../../../../core/data/repository/repository_error_handler.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/failure_code.dart';
import '../../../../core/result/result.dart';
import '../../domain/entity/account_content_summary.dart';
import '../../domain/repository/account_repository.dart';
import '../datasource/account_data_source.dart';

@LazySingleton(as: AccountRepository)
class AccountRepositoryImpl
    with RepositoryErrorHandler
    implements AccountRepository {
  AccountRepositoryImpl(this._dataSource);

  final AccountDataSource _dataSource;

  @override
  Future<Result<AccountContentSummary>> myContentSummary() => guard(() async {
    final summary = await _dataSource.myContentSummary();
    if (summary == null) {
      throw const Failure.auth(
        message: '로그인이 필요합니다',
        code: 'not_authenticated',
        failureCode: FailureCode.authenticationRequired,
      );
    }
    return AccountContentSummary(
      postCount: summary.postCount,
      commentCount: summary.commentCount,
    );
  });
}
```

Run: `cd app && dart run build_runner build --delete-conflicting-outputs` (freezed + injectable 갱신. `injection.config.dart` 에 `AccountDataSource`·`AccountRepository`·`AccountUseCase` 등록이 생겨야 한다.)

- [ ] **Step 4: repository 테스트** — `account_repository_impl_test.dart`:

```dart
import 'package:daylog/core/error/failure.dart';
import 'package:daylog/core/result/result.dart';
import 'package:daylog/features/settings/data/datasource/account_data_source.dart';
import 'package:daylog/features/settings/data/repository/account_repository_impl.dart';
import 'package:daylog/features/settings/domain/entity/account_content_summary.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAccountDataSource extends Mock implements AccountDataSource {}

void main() {
  late _MockAccountDataSource dataSource;
  late AccountRepositoryImpl repository;

  setUp(() {
    dataSource = _MockAccountDataSource();
    repository = AccountRepositoryImpl(dataSource);
  });

  test('개수 두 개를 그대로 담아 돌려준다', () async {
    when(dataSource.myContentSummary)
        .thenAnswer((_) async => (postCount: 14, commentCount: 37));

    final result = await repository.myContentSummary();

    expect(
      result,
      const Ok(AccountContentSummary(postCount: 14, commentCount: 37)),
    );
  });

  test('세션이 없으면 인증 실패로 돌려준다', () async {
    when(dataSource.myContentSummary).thenAnswer((_) async => null);

    final result = await repository.myContentSummary();

    expect(result, isA<Err<AccountContentSummary>>());
    final failure = (result as Err<AccountContentSummary>).failure;
    expect(failure, isA<AuthFailure>());
  });
}
```
`Err` 의 필드 이름이 `failure` 가 아니면 `core/result/result.dart` 를 열어 실제 이름으로 맞춘다.

Run: `cd app && flutter test test/features/settings/data`
Expected: PASS.

- [ ] **Step 5: 화면 테스트 갱신** — `account_settings_page_test.dart`

import 추가:
```dart
import 'package:daylog/features/settings/domain/entity/account_content_summary.dart';
import 'package:daylog/features/settings/domain/usecase/account_use_case.dart';
```
mock 클래스와 setUp:
```dart
class _MockAccountUseCase extends Mock implements AccountUseCase {}
…
  late _MockAccountUseCase accountUseCase;

  setUp(() {
    useCase = _MockAuthUseCase();
    accountUseCase = _MockAccountUseCase();
    when(accountUseCase.myContentSummary).thenAnswer(
      (_) async =>
          const Ok(AccountContentSummary(postCount: 14, commentCount: 37)),
    );
    getIt
      ..registerFactory<DeleteAccountCubit>(() => DeleteAccountCubit(useCase))
      // 확인 다이얼로그를 열 때 화면이 직접 꺼내 쓴다.
      ..registerSingleton<AccountUseCase>(accountUseCase);
  });
```
기존 `'탈퇴는 지워질 것을 보여주는 확인을 거쳐야 실행된다'` 의 `find.textContaining('작성한 게시물과 사진')` 을 `find.textContaining('작성한 게시물 14개와 사진')` 으로 바꾸고 바로 아래에 `expect(find.textContaining('남긴 댓글 37개'), findsOneWidget);` 를 더한다.

새 테스트:
```dart
  testWidgets('개수 조회에 실패해도 종류만 적은 확인으로 탈퇴할 수 있다', (tester) async {
    when(accountUseCase.myContentSummary)
        .thenAnswer((_) async => const Err(Failure.network()));
    when(() => useCase.deleteAccount()).thenAnswer((_) async => const Ok(null));

    await pumpPage(tester);
    await tester.tap(find.text('회원 탈퇴'));
    await tester.pumpAndSettle();

    expect(find.textContaining('작성한 게시물과 사진'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '탈퇴'));
    await tester.pumpAndSettle();
    verify(() => useCase.deleteAccount()).called(1);
  });
```

Run: `cd app && flutter test test/features/settings/presentation/page/account_settings_page_test.dart`
Expected: FAIL — 아직 화면이 개수를 넣지 않는다.

- [ ] **Step 6: 화면 구현** — `account_settings_page.dart` 의 `_confirmDelete`:

```dart
  Future<void> _confirmDelete(BuildContext context) async {
    final cubit = context.read<DeleteAccountCubit>();
    final l10n = AppLocalizations.of(context);

    // 잃게 될 것을 이름과 숫자로 보여준다. 조회가 실패하면 종류만 적은 문구로
    // 물러선다 — 개수를 못 읽었다고 탈퇴를 막을 이유는 없다.
    final summary = await getIt<AccountUseCase>().myContentSummary();
    if (!context.mounted) return;
    final content = switch (summary) {
      Ok(:final value) => l10n.accountDeleteConfirmMessageCounted(
        value.postCount,
        value.commentCount,
      ),
      Err() => l10n.accountDeleteConfirmMessage,
    };

    final confirmed = await AppConfirmDialog.show(
      context,
      title: l10n.accountDeleteConfirmTitle,
      content: content,
      confirmLabel: l10n.accountDeleteConfirmAction,
    );
    if (!confirmed) return;
    await cubit.submit();
  }
```
import 추가: `core/di/injection.dart`, `core/result/result.dart`, `../../domain/usecase/account_use_case.dart`. `Ok(:final value)` 패턴의 필드 이름은 `result.dart` 의 실제 이름을 따른다 (`profile_page.dart` 의 `case Ok(value: final roomId)` 참고).

- [ ] **Step 7: 통과 확인**

Run: `cd app && flutter test test/features/settings && flutter analyze && flutter test test/convention`
Expected: PASS.

- [ ] **Step 8: 문서** — `docs/features/settings/plan.md` "상태" 절 목록에:
```
- 탈퇴 확인은 열기 전에 `AccountUseCase.myContentSummary` 로 내 게시물·댓글 개수를
  읽어 본문에 넣는다. 조회에 실패하면 종류만 적은 문구로 물러선다. 개수는 정보이지
  압박이 아니다 — 버튼 문구는 바꾸지 않는다
```
같은 문서 "이 화면이 빌려 쓰는 것" 절 앞에 절 하나:
```
## 이 feature 가 소유하는 data

`AccountRepository.myContentSummary()` 하나. `posts` · `post_comments` 에
`count` HEAD 요청 두 번(`author_id = 나`, `deleted_at is null`)이다. 새 테이블·뷰는 없다.
```
`docs/testing/features/settings.md` 첫 문장 "presentation 만 있는 feature 라…" 를 "탈퇴 확인의 개수 조회만 data 계층이 있다." 로 고치고 표에:
```
| `AccountSettingsPage` | 탈퇴 확인 본문 | 게시물·댓글 개수를 넣어 보여준다. 조회가 실패하면 종류만 적은 문구로 탈퇴를 진행한다. |
| `AccountRepositoryImpl` | 개수 조회 / 세션 없음 | 두 개수를 `AccountContentSummary` 로 담는다 / 인증 실패 `Failure` 를 낸다. |
```

- [ ] **Step 9: Commit**
```bash
git add app/lib/features/settings app/lib/core/di/injection.config.dart app/lib/l10n app/test/features/settings docs/features/settings/plan.md docs/testing/features/settings.md
git commit -m "feat(settings): 탈퇴 확인에 실제 게시물·댓글 개수를 넣는다"
```

---

### Task 6: 가입 직후 프로필 꾸미기 (redirect + 편집 화면 setup 모드)

**Files:**
- Create: `app/lib/app/router/auth_redirect.dart`
- Modify: `app/lib/app/router/app_router.dart` (redirect 본문 교체, 라우트 추가)
- Modify: `app/lib/app/router/routes.dart`
- Modify: `app/lib/features/profile/presentation/page/edit_profile_page.dart`
- Modify: `app/patrol_test/helpers/app_harness.dart` (`signUpNewAccount`)
- Modify: ARB 3벌
- Create: `app/test/app/router/auth_redirect_test.dart`
- Modify: `app/test/features/profile/presentation/page/edit_profile_page_test.dart`
- Docs: `docs/features/auth/plan.md` (화면 목록 · 흐름), `docs/features/profile/plan.md` (화면 목록), `docs/testing/features/auth.md`, `docs/testing/features/profile.md`

**Interfaces:**
- Consumes: `AuthState` (unknown/authenticated/unauthenticated), `Routes.publicRoutes`, `EditProfilePage` 의 저장 성공 신호(`didFinishSaving && failure == null`)
- Produces:
  - `String? resolveAuthRedirect({required AuthState authState, required String location})`
  - `Routes.profileSetup = '/profile/setup'`
  - `EditProfilePage({bool isSetup = false})`
  - ARB `profileSetupTitle` · `profileSetupDescription` · `profileSetupSkip` · `profileSetupContinue`

- [ ] **Step 1: ARB** — `profileEditTitle` 아래에.

`app_ko.arb`:
```json
  "profileSetupTitle": "프로필 꾸미기",
  "@profileSetupTitle": {
    "description": "가입 직후 한 번 보이는 프로필 편집 화면의 제목"
  },
  "profileSetupDescription": "사진과 한 줄 소개로 이웃에게 나를 알려보세요. 나중에 설정에서 바꿀 수 있습니다.",
  "@profileSetupDescription": {
    "description": "프로필 꾸미기 화면 상단의 안내 한 문장"
  },
  "profileSetupSkip": "나중에",
  "@profileSetupSkip": {
    "description": "프로필 꾸미기를 건너뛰고 홈으로 가는 AppBar 버튼"
  },
  "profileSetupContinue": "계속",
  "@profileSetupContinue": {
    "description": "프로필 꾸미기 화면의 저장 버튼. '가입'이 아니라 '계속' — 내가 만든 것을 들고 넘어간다는 뜻"
  },
```
`app_en.arb`:
```json
  "profileSetupTitle": "Set up your profile",
  "profileSetupDescription": "A photo and a short bio help neighbors know you. You can change them later in Settings.",
  "profileSetupSkip": "Later",
  "profileSetupContinue": "Continue",
```
`app_ja.arb`:
```json
  "profileSetupTitle": "プロフィールを整える",
  "profileSetupDescription": "写真とひとこと紹介で、ご近所に自分を知ってもらいましょう。あとで設定から変更できます。",
  "profileSetupSkip": "あとで",
  "profileSetupContinue": "続ける",
```
Run: `cd app && flutter gen-l10n`

- [ ] **Step 2: redirect 순수 함수 테스트** — `test/app/router/auth_redirect_test.dart`:

```dart
import 'package:daylog/app/router/auth_redirect.dart';
import 'package:daylog/app/router/routes.dart';
import 'package:daylog/features/auth/domain/entity/app_user.dart';
import 'package:daylog/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';

const _me = AppUser(id: 'me', email: 'me@example.test', nickname: '카르마');

void main() {
  String? redirect(AuthState state, String location) =>
      resolveAuthRedirect(authState: state, location: location);

  test('세션을 읽는 중에는 스플래시에 머문다', () {
    expect(redirect(const AuthState.unknown(), Routes.splash), isNull);
    expect(redirect(const AuthState.unknown(), Routes.home), Routes.splash);
  });

  test('미인증은 공개 경로만 허용하고 나머지는 로그인으로 보낸다', () {
    expect(redirect(const AuthState.unauthenticated(), Routes.signIn), isNull);
    expect(redirect(const AuthState.unauthenticated(), Routes.signUp), isNull);
    expect(redirect(const AuthState.unauthenticated(), Routes.home), Routes.signIn);
    expect(
      redirect(const AuthState.unauthenticated(), Routes.profileSetup),
      Routes.signIn,
    );
  });

  test('가입 화면에서 인증되면 홈이 아니라 프로필 꾸미기로 간다', () {
    expect(
      redirect(const AuthState.authenticated(_me), Routes.signUp),
      Routes.profileSetup,
    );
  });

  test('로그인·스플래시에서 인증되면 홈으로 가고, 보호 경로는 그대로 둔다', () {
    expect(redirect(const AuthState.authenticated(_me), Routes.signIn), Routes.home);
    expect(redirect(const AuthState.authenticated(_me), Routes.splash), Routes.home);
    expect(redirect(const AuthState.authenticated(_me), Routes.home), isNull);
    expect(redirect(const AuthState.authenticated(_me), Routes.profileSetup), isNull);
  });
}
```

Run: `cd app && flutter test test/app/router/auth_redirect_test.dart`
Expected: FAIL — 파일 없음.

- [ ] **Step 3: redirect 함수와 라우트**

`routes.dart` — `profileEdit` 아래에:
```dart
  /// 가입 직후 한 번 지나가는 프로필 꾸미기. 보호 경로다.
  static const profileSetup = '/profile/setup';
```

`auth_redirect.dart`:
```dart
import '../../features/auth/presentation/bloc/auth_state.dart';
import 'routes.dart';

/// 인증 상태와 현재 위치로 갈 곳을 정한다. null 이면 그대로 둔다.
///
/// `GoRouter.redirect` 에서 뽑아낸 순수 함수다 — 화면 빌더와 DI 없이 표만
/// 검사할 수 있다.
///
/// 가입 화면에서 인증되면 홈이 아니라 프로필 꾸미기로 보낸다. 가입 직후의
/// 빈 홈에는 사용자 것이 하나도 없다 (ux-psychology-review.md 5번). 가입
/// 화면에서 인증 상태가 되는 경로는 가입 성공뿐이므로 위치가 곧 신호다.
String? resolveAuthRedirect({
  required AuthState authState,
  required String location,
}) {
  final isPublic = Routes.publicRoutes.contains(location);
  return switch (authState) {
    AuthUnknown() => location == Routes.splash ? null : Routes.splash,
    AuthUnauthenticated() => isPublic ? null : Routes.signIn,
    AuthAuthenticated() when location == Routes.signUp => Routes.profileSetup,
    AuthAuthenticated() =>
      (isPublic || location == Routes.splash) ? Routes.home : null,
  };
}
```

`app_router.dart` — `redirect:` 본문을:
```dart
    redirect: (context, state) => resolveAuthRedirect(
      authState: authBloc.state,
      location: state.matchedLocation,
    ),
```
로 바꾸고 (`import 'auth_redirect.dart';`), `Routes.profileEdit` 라우트 아래에:
```dart
      GoRoute(
        path: Routes.profileSetup,
        builder: (_, _) => const EditProfilePage(isSetup: true),
      ),
```

Run: `cd app && flutter test test/app/router/auth_redirect_test.dart`
Expected: PASS.

- [ ] **Step 4: 편집 화면 테스트** — `edit_profile_page_test.dart` 에 추가. 파일 상단 import 에 `package:go_router/go_router.dart` 와 `package:daylog/app/router/routes.dart` 를 더한다.

```dart
  /// setup 모드는 저장·건너뛰기 뒤 홈으로 `go` 하므로 라우터가 필요하다.
  Future<GoRouter> pumpSetup(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: Routes.profileSetup,
      routes: [
        GoRoute(
          path: Routes.home,
          builder: (_, _) => const Scaffold(body: Text('홈')),
        ),
        GoRoute(
          path: Routes.profileSetup,
          builder: (_, _) => const EditProfilePage(isSetup: true),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
        builder: (context, child) =>
            BlocProvider<AuthBloc>.value(value: authBloc, child: child!),
      ),
    );
    await tester.pump();
    return router;
  }

  testWidgets('프로필 꾸미기 모드는 제목·안내·나중에·계속을 보여주고 뒤로가기가 없다', (tester) async {
    await pumpSetup(tester);

    expect(find.text('프로필 꾸미기'), findsOneWidget);
    expect(find.textContaining('이웃에게 나를 알려보세요'), findsOneWidget);
    expect(find.text('나중에'), findsOneWidget);
    expect(find.text('계속'), findsOneWidget);
    expect(find.text('저장'), findsNothing);
    expect(find.byType(BackButton), findsNothing);
    // 나중에는 계속 아래의 텍스트 버튼이다 (AppBar 가 아니다).
    expect(find.widgetWithText(TextButton, '나중에'), findsOneWidget);
  });

  testWidgets('나중에를 누르면 저장 없이 홈으로 간다', (tester) async {
    final router = await pumpSetup(tester);

    await tester.tap(find.text('나중에'));
    await tester.pumpAndSettle();

    expect(router.state.matchedLocation, Routes.home);
    verifyNever(
      () => useCase.updateMyProfile(any(), newAvatar: any(named: 'newAvatar')),
    );
  });

  testWidgets('계속을 누르면 저장한 뒤 홈으로 간다', (tester) async {
    when(
      () => useCase.updateMyProfile(any(), newAvatar: any(named: 'newAvatar')),
    ).thenAnswer((_) async => Ok(_profile));
    final router = await pumpSetup(tester);

    await tester.enterText(find.byType(TextFormField).last, '오늘도 기록');
    await tester.tap(find.text('계속'));
    await tester.pumpAndSettle();

    verify(
      () => useCase.updateMyProfile(any(), newAvatar: any(named: 'newAvatar')),
    ).called(1);
    expect(router.state.matchedLocation, Routes.home);
  });
```
`main()` 첫 줄에 `setUpAll(() => registerFallbackValue(const ProfileUpdate(nickname: '')));` 를 두고 `package:daylog/features/profile/domain/entity/profile_update.dart` 를 import 한다 (`updateMyProfile` 의 `any()` 가 `ProfileUpdate` 를 요구한다). go_router 17.5 의 `router.state.matchedLocation` 이 현재 위치다.

Run: `cd app && flutter test test/features/profile/presentation/page/edit_profile_page_test.dart`
Expected: FAIL — `isSetup` 인자 없음.

- [ ] **Step 5: 편집 화면 구현** — `edit_profile_page.dart`

```dart
class EditProfilePage extends StatelessWidget {
  const EditProfilePage({this.isSetup = false, super.key});

  /// 가입 직후 한 번 지나가는 모드. 제목·버튼이 바뀌고, 저장하거나 건너뛰면
  /// 홈으로 간다. 뒤로 갈 곳(가입 화면)은 redirect 가 이미 치웠으므로 뒤로가기를
  /// 그리지 않는다. "나중에" 는 AppBar 가 아니라 "계속" 아래에 둔다 —
  /// 테마의 `TextButton` 최소 너비가 `Size.fromHeight` 라 AppBar 의 Row 안에서는
  /// 폭이 무한대가 된다.
  final bool isSetup;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<ProfileCubit>()..load(),
    child: _EditProfileView(isSetup: isSetup),
  );
}

class _EditProfileView extends StatefulWidget {
  const _EditProfileView({required this.isSetup});

  final bool isSetup;
  …
```
`build` 안:
- `appBar: AppBar(title: Text(widget.isSetup ? l10n.profileSetupTitle : l10n.profileEditTitle), automaticallyImplyLeading: !widget.isSetup)`
- `listener` 의 저장 성공 분기 끝에: `if (widget.isSetup) context.go(Routes.home);` (스낵바를 띄운 뒤).
- `ListView` children 맨 앞에:
```dart
                  if (widget.isSetup) ...[
                    Text(
                      l10n.profileSetupDescription,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
```
(`final theme = Theme.of(context);` 를 builder 안에 둔다.)
- 저장 버튼: `label: widget.isSetup ? l10n.profileSetupContinue : l10n.commonSave,`
- 저장 버튼 바로 아래(ListView children 마지막):
```dart
                  if (widget.isSetup) ...[
                    const SizedBox(height: AppSpacing.sm),
                    AppButton.text(
                      label: l10n.profileSetupSkip,
                      onPressed: isBusy ? null : () => context.go(Routes.home),
                    ),
                  ],
```
- import: `package:go_router/go_router.dart`, `../../../../app/router/routes.dart`.

Run: `cd app && flutter test test/features/profile test/app && flutter analyze`
Expected: PASS.

- [ ] **Step 6: Patrol 헬퍼** — `app_harness.dart` 의 `signUpNewAccount` 에서 `await $('가입하기').tap();` 다음 줄을:
```dart
  // 가입 직후에는 프로필 꾸미기가 한 번 뜬다. E2E 는 건너뛴다 — 프로필
  // 편집 자체는 위젯 테스트가 본다.
  await $.waitUntilVisible($('나중에'), timeout: kWait);
  await $('나중에').tap();
  await waitForFeed($);
```
헬퍼 doc 주석의 "피드까지 들어간다" 를 "프로필 꾸미기를 건너뛰고 피드까지 들어간다" 로 고친다. (에뮬레이터·로컬 Supabase 가 없으면 실행하지 않고, 결과 보고에 "Patrol 미실행" 을 적는다.)

- [ ] **Step 7: 문서**

`docs/features/auth/plan.md` 화면 목록 아래 문단 뒤에:
```
가입 성공은 홈이 아니라 **프로필 꾸미기**(`/profile/setup`, profile feature 의
편집 화면 setup 모드)로 간다. 가입 화면에서 인증 상태가 되는 경로는 가입 성공뿐이라
redirect 가 위치로 판단한다 (`app/router/auth_redirect.dart`). 로그인·스플래시에서
인증되면 홈이다.
```
같은 문서 "흐름" 절의 mermaid `L --> SU[회원가입] -->|성공 → AuthBloc| H` 를
`L --> SU[회원가입] -->|성공 → AuthBloc| PS[프로필 꾸미기] -->|저장 · 나중에| H` 로.

`docs/features/profile/plan.md` 화면 목록 표에:
```
| 프로필 꾸미기 | 편집 화면의 setup 모드. 제목 "프로필 꾸미기", 안내 한 문장, "나중에"(AppBar) · "계속"(저장). 둘 다 홈으로 간다. 뒤로가기 없음 | 가입 성공 직후 redirect (`/profile/setup`) |
```
`docs/testing/features/auth.md` 표에:
```
| `resolveAuthRedirect` | 상태 × 위치 | unknown 은 스플래시, 미인증은 공개 경로만, 가입 화면에서 인증되면 프로필 꾸미기, 그 밖의 공개 경로에서 인증되면 홈. |
```
`docs/testing/features/profile.md` 표에:
```
| `EditProfilePage` | setup 모드 | 제목·안내·나중에·계속을 보여주고 뒤로가기가 없다. 나중에는 저장 없이, 계속은 저장 뒤 홈으로 간다. |
```

- [ ] **Step 8: Commit**
```bash
git add app/lib/app/router app/lib/features/profile app/lib/l10n app/patrol_test/helpers app/test/app app/test/features/profile docs/features/auth/plan.md docs/features/profile/plan.md docs/testing/features/auth.md docs/testing/features/profile.md
git commit -m "feat(profile): 가입 직후 프로필 꾸미기로 보내고 나중에로 건너뛸 수 있게 한다"
```

---

### Task 7: 로그인 화면의 "먼저 둘러보기" → 읽기 전용 게스트 피드

**Files:**
- Create: `app/lib/features/feed/presentation/page/guest_feed_page.dart`
- Modify: `app/lib/app/router/routes.dart` (`explore`, `publicRoutes`), `app/lib/app/router/app_router.dart` (라우트)
- Modify: `app/lib/features/auth/presentation/page/sign_in_page.dart`
- Modify: ARB 3벌
- Create: `app/test/features/feed/presentation/page/guest_feed_page_test.dart`
- Modify: `app/test/features/auth/presentation/page/sign_in_page_test.dart`, `app/test/app/router/auth_redirect_test.dart`
- Create: `supabase/tests/guest_read_check.py`
- Docs: `docs/features/feed/plan.md` (화면 목록), `docs/features/auth/plan.md` (화면 목록), `docs/testing/features/feed.md`, `docs/testing/features/auth.md`, `docs/testing/README.md` 는 손대지 않는다

**Interfaces:**
- Consumes: `FeedCubit.load()/refresh()/loadMore()`, `FeedState`, `PostTile(post, author, isMine:false, onTap, onReaction, onComment, reactions, commentCount)`, `FeedListFooter(isLoadingMore, canLoadMore)`, `AppPlaceholder`, `Routes.signUp`/`signIn`
- Produces: `Routes.explore = '/explore'` (공개), `GuestFeedPage`, ARB `authBrowseFirst` · `guestFeedTitle` · `guestPromptTitle` · `guestPromptDescription`

- [ ] **Step 1: ARB**

`app_ko.arb` — `authSignUp` 아래에:
```json
  "authBrowseFirst": "먼저 둘러보기",
  "@authBrowseFirst": {
    "description": "로그인 화면 맨 아래. 가입 없이 전체 피드를 읽기 전용으로 본다"
  },
```
`feedEndOfList` 아래에:
```json
  "guestFeedTitle": "둘러보기",
  "@guestFeedTitle": {
    "description": "비로그인 읽기 전용 피드의 AppBar 제목"
  },
  "guestPromptTitle": "가입하면 반응과 댓글을 남길 수 있어요",
  "@guestPromptTitle": {
    "description": "게스트가 반응·댓글·게시물을 누를 때 뜨는 시트 제목"
  },
  "guestPromptDescription": "이메일과 닉네임만 있으면 됩니다.",
  "@guestPromptDescription": {
    "description": "게스트 안내 시트의 한 줄 설명. 가입 버튼과 로그인 버튼이 아래에 온다"
  },
```
`app_en.arb`: `"authBrowseFirst": "Browse first",` · `"guestFeedTitle": "Browse",` · `"guestPromptTitle": "Sign up to react and comment",` · `"guestPromptDescription": "All you need is an email and a nickname.",`
`app_ja.arb`: `"authBrowseFirst": "まず見てみる",` · `"guestFeedTitle": "見てみる",` · `"guestPromptTitle": "登録するとリアクションやコメントができます",` · `"guestPromptDescription": "メールアドレスとニックネームだけで始められます。",`

Run: `cd app && flutter gen-l10n`

- [ ] **Step 2: redirect 테스트 확장** — `auth_redirect_test.dart` 의 미인증 테스트에 두 줄, 인증 테스트에 한 줄:
```dart
    expect(redirect(const AuthState.unauthenticated(), Routes.explore), isNull);
    …
    expect(redirect(const AuthState.authenticated(_me), Routes.explore), Routes.home);
```

- [ ] **Step 3: 게스트 화면 테스트** — `guest_feed_page_test.dart`:

```dart
import 'package:daylog/app/router/routes.dart';
import 'package:daylog/core/di/injection.dart';
import 'package:daylog/core/pagination/cursor_page.dart';
import 'package:daylog/core/result/result.dart';
import 'package:daylog/design_system/theme/app_theme.dart';
import 'package:daylog/features/feed/domain/entity/feed_post.dart';
import 'package:daylog/features/feed/domain/entity/feed_source.dart';
import 'package:daylog/features/feed/domain/usecase/feed_use_case.dart';
import 'package:daylog/features/feed/presentation/cubit/feed_cubit.dart';
import 'package:daylog/features/feed/presentation/page/guest_feed_page.dart';
import 'package:daylog/features/post/domain/entity/post.dart';
import 'package:daylog/features/post/domain/entity/post_author.dart';
import 'package:daylog/features/reaction/domain/usecase/reaction_use_case.dart';
import 'package:daylog/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockFeedUseCase extends Mock implements FeedUseCase {}

class _MockReactionUseCase extends Mock implements ReactionUseCase {}

FeedPost _item(String id) => FeedPost(
  post: Post(
    id: id,
    authorId: 'other',
    content: '기록 $id',
    createdAt: DateTime.utc(2026, 9, 6, 9),
    updatedAt: DateTime.utc(2026, 9, 6, 9),
  ),
  author: const PostAuthor(id: 'other', nickname: '이웃'),
);

void main() {
  setUpAll(() => registerFallbackValue(FeedSource.all));

  late _MockFeedUseCase feedUseCase;

  setUp(() {
    feedUseCase = _MockFeedUseCase();
    when(
      () => feedUseCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        authorId: any(named: 'authorId'),
        source: any(named: 'source'),
      ),
    ).thenAnswer(
      (_) async => Ok(CursorPage<FeedPost>(items: [_item('1'), _item('2')])),
    );
    getIt.registerFactory<FeedCubit>(
      () => FeedCubit(feedUseCase, _MockReactionUseCase()),
    );
  });

  tearDown(getIt.reset);

  Future<GoRouter> pumpPage(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: Routes.explore,
      routes: [
        GoRoute(
          path: Routes.explore,
          builder: (_, _) => const GuestFeedPage(),
        ),
        GoRoute(
          path: Routes.signUp,
          builder: (_, _) => const Scaffold(body: Text('가입 화면')),
        ),
        GoRoute(
          path: Routes.signIn,
          builder: (_, _) => const Scaffold(body: Text('로그인 화면')),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('전체 피드를 읽기 전용으로 보여준다', (tester) async {
    await pumpPage(tester);

    expect(find.text('둘러보기'), findsOneWidget);
    expect(find.text('기록 1'), findsOneWidget);
    expect(find.text('기록 2'), findsOneWidget);
    // 더보기(신고·차단·수정·삭제) 메뉴가 없다.
    expect(find.byIcon(Icons.more_vert), findsNothing);
    verify(
      () => feedUseCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        authorId: any(named: 'authorId'),
        source: FeedSource.all,
      ),
    ).called(1);
  });

  testWidgets('게시물을 누르면 가입 안내 시트가 뜨고 회원가입으로 간다', (tester) async {
    final router = await pumpPage(tester);

    await tester.tap(find.text('기록 1'));
    await tester.pumpAndSettle();

    expect(find.text('가입하면 반응과 댓글을 남길 수 있어요'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '회원가입'));
    await tester.pumpAndSettle();

    expect(router.state.matchedLocation, Routes.signUp);
  });

  testWidgets('안내 시트의 로그인은 로그인 화면으로 간다', (tester) async {
    final router = await pumpPage(tester);

    await tester.tap(find.text('기록 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '로그인'));
    await tester.pumpAndSettle();

    expect(router.state.matchedLocation, Routes.signIn);
  });

  testWidgets('게시물이 없으면 빈 안내를 보여준다', (tester) async {
    when(
      () => feedUseCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        authorId: any(named: 'authorId'),
        source: any(named: 'source'),
      ),
    ).thenAnswer((_) async => const Ok(CursorPage<FeedPost>(items: [])));

    await pumpPage(tester);

    expect(find.text('아직 게시물이 없습니다'), findsOneWidget);
    expect(find.text('첫 게시물 쓰기'), findsNothing);
  });
}
```
`AppButton.primary` 가 `FilledButton` 을, `AppButton.text` 가 `TextButton` 을 그린다 (`sign_in_page_test` 가 같은 finder 를 쓴다). `PostTile` 의 반응 줄이 `ReactionBar` 를 그리므로 반응 버튼 탭 테스트는 두지 않는다 — `onTap` 경로 하나로 시트를 검증한다.

Run: `cd app && flutter test test/features/feed/presentation/page/guest_feed_page_test.dart`
Expected: FAIL — 파일 없음.

- [ ] **Step 4: 라우트와 화면**

`routes.dart`:
```dart
  /// 비로그인 읽기 전용 피드. 로그인 화면의 "먼저 둘러보기" 로 들어온다.
  static const explore = '/explore';
  …
  static const publicRoutes = {signIn, signUp, passwordReset, explore};
```

`app_router.dart` — `Routes.passwordReset` 라우트 아래에:
```dart
      GoRoute(path: Routes.explore, builder: (_, _) => const GuestFeedPage()),
```
(import `../../features/feed/presentation/page/guest_feed_page.dart`)

`guest_feed_page.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/failure_localizations.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/widget/app_button.dart';
import '../../../../design_system/widget/app_placeholder.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../post/presentation/widget/post_tile.dart';
import '../cubit/feed_cubit.dart';
import '../cubit/feed_state.dart';
import '../widget/feed_list_footer.dart';

/// 비로그인 읽기 전용 피드.
///
/// 가입 전에 앱이 주는 것이 문장 하나뿐이었다 (상호성,
/// ux-psychology-review.md 4번). 전체 피드는 DB 가 이미 `anon` 에 열어 두었으므로
/// 라우터만 열면 된다. 블러·가림 없이 실제 내용을 그대로 보여주고, 반응·댓글·
/// 게시물 탭은 가입 안내 시트로 보낸다.
///
/// 기본 진입은 여전히 로그인 화면이다 — 이 화면은 로그인 화면의 "먼저 둘러보기"
/// 로만 들어온다.
class GuestFeedPage extends StatelessWidget {
  const GuestFeedPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<FeedCubit>()..load(),
    child: const _GuestFeedView(),
  );
}

class _GuestFeedView extends StatelessWidget {
  const _GuestFeedView();

  /// 목록 맨 아래 여백. 피드 화면과 달리 FAB 이 없지만 꼬리표가 화면 끝에
  /// 붙지 않게 한 칸 둔다.
  static const _bottomPadding = AppSpacing.xl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.guestFeedTitle)),
      body: BlocBuilder<FeedCubit, FeedState>(
        builder: (context, state) => switch (state.status) {
          FeedStatus.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          FeedStatus.failure => Center(
            child: AppPlaceholder(
              icon: Icons.cloud_off_outlined,
              message:
                  state.failure?.localizedMessage(context) ??
                  l10n.feedLoadFailed,
              description: l10n.feedLoadFailedDescription,
              actionLabel: l10n.commonRetry,
              onAction: () => context.read<FeedCubit>().refresh(),
            ),
          ),
          FeedStatus.loaded when state.items.isEmpty => Center(
            child: AppPlaceholder(
              icon: Icons.edit_note_outlined,
              message: l10n.feedEmptyMessage,
            ),
          ),
          FeedStatus.loaded => RefreshIndicator(
            onRefresh: () => context.read<FeedCubit>().refresh(),
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification.metrics.extentAfter < 240 &&
                    !state.isLoadingMore &&
                    state.canLoadMore) {
                  context.read<FeedCubit>().loadMore();
                }
                return false;
              },
              child: ListView.builder(
                padding: const EdgeInsets.only(
                  top: AppSpacing.sm,
                  bottom: _bottomPadding,
                ),
                itemCount: state.items.length + 1,
                itemBuilder: (context, index) {
                  if (index == state.items.length) {
                    return FeedListFooter(
                      isLoadingMore: state.isLoadingMore,
                      canLoadMore: state.canLoadMore,
                    );
                  }
                  final item = state.items[index];
                  return PostTile(
                    post: item.post,
                    author: item.author,
                    isMine: false,
                    reactions: item.reactions,
                    commentCount: item.commentCount,
                    onTap: () => _promptSignUp(context),
                    onReaction: (_) => _promptSignUp(context),
                    onComment: () => _promptSignUp(context),
                  );
                },
              ),
            ),
          ),
        },
      ),
    );
  }

  /// 무엇을 하려 했든 같은 안내다 — "가입하면 할 수 있다".
  Future<void> _promptSignUp(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final router = GoRouter.of(context);
    final action = await showModalBottomSheet<_GuestAction>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.guestPromptTitle,
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.guestPromptDescription,
                style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton.primary(
                label: l10n.authSignUp,
                onPressed: () =>
                    Navigator.of(sheetContext).pop(_GuestAction.signUp),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton.text(
                label: l10n.authSignIn,
                onPressed: () =>
                    Navigator.of(sheetContext).pop(_GuestAction.signIn),
              ),
            ],
          ),
        ),
      ),
    );
    switch (action) {
      case _GuestAction.signUp:
        router.push(Routes.signUp);
      case _GuestAction.signIn:
        router.go(Routes.signIn);
      case null:
        break;
    }
  }
}

enum _GuestAction { signUp, signIn }
```

`sign_in_page.dart` — 회원가입 `AppButton.secondary` 아래에:
```dart
                  const SizedBox(height: AppSpacing.sm),
                  AppButton.text(
                    label: l10n.authBrowseFirst,
                    onPressed: busy
                        ? null
                        : () => context.push(Routes.explore),
                  ),
```

`sign_in_page_test.dart` 의 헤더 테스트에 `expect(find.text('먼저 둘러보기'), findsOneWidget);` 한 줄 추가.

- [ ] **Step 5: 통과 확인**

Run: `cd app && flutter test test/features/feed test/features/auth test/app && flutter analyze && flutter test test/convention`
Expected: PASS.

- [ ] **Step 6: 로컬 Supabase 확인 스크립트** — `supabase/tests/guest_read_check.py`:

```python
#!/usr/bin/env python3
"""비로그인(anon) 이 게스트 피드를 읽을 수 있고, 쓰기는 전부 막히는지 REST 로 확인한다.

docs/features/feed/plan.md 의 게스트 피드 완료 조건. 스키마 변경 없이 기존
GRANT/RLS 만으로 성립해야 한다 — 이 스크립트가 깨지면 누군가 anon 권한을 걷어낸 것이다.
"""
import json
import urllib.error
import urllib.request

BASE = "http://127.0.0.1:54321"
ANON = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"

results = []


def call(method, path, body=None):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(f"{BASE}{path}", data=data, method=method)
    req.add_header("apikey", ANON)
    req.add_header("Authorization", f"Bearer {ANON}")
    req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req) as r:
            raw = r.read().decode()
            return r.status, (json.loads(raw) if raw.strip() else None)
    except urllib.error.HTTPError as e:
        raw = e.read().decode()
        try:
            return e.code, json.loads(raw)
        except json.JSONDecodeError:
            return e.code, raw


def check(name, ok, detail=""):
    results.append((ok, name, detail))
    print(f"{'PASS' if ok else 'FAIL'}  {name}" + (f"  — {detail}" if detail else ""))


status, body = call("GET", "/rest/v1/posts_with_author?select=id,author_nickname&limit=3")
check("anon 이 posts_with_author 를 읽는다", status == 200, f"status={status}")

status, body = call("GET", "/rest/v1/profiles?select=id,nickname&limit=1")
check("anon 이 profiles 를 읽는다", status == 200, f"status={status}")

status, body = call("POST", "/rest/v1/posts", {"content": "guest"})
check("anon 은 게시물을 쓰지 못한다", status in (401, 403), f"status={status}")

status, body = call("POST", "/rest/v1/post_reactions", {"post_id": "00000000-0000-0000-0000-000000000000", "type": "like"})
check("anon 은 반응을 남기지 못한다", status in (400, 401, 403), f"status={status}")

status, body = call("GET", "/rest/v1/following_posts_with_author?select=id&limit=1")
check("anon 의 팔로잉 피드는 비어 있거나 거부된다", status in (200, 401, 403) and (status != 200 or body == []), f"status={status} body={body}")

failed = [r for r in results if not r[0]]
print(f"\n{len(results) - len(failed)}/{len(results)} passed")
raise SystemExit(1 if failed else 0)
```
Run (로컬 Supabase 가 떠 있을 때만): `python3 supabase/tests/guest_read_check.py`
Expected: 전부 PASS. 떠 있지 않으면 실행하지 않고 결과 보고에 "guest_read_check 미실행" 을 적는다. `following_posts_with_author` 의 실제 응답이 예상과 다르면 스키마 문서 §follow 를 읽고 기대값을 사실에 맞춘다 — 뷰를 고치지는 않는다.

- [ ] **Step 7: 문서**

`docs/features/feed/plan.md` 화면 목록 표에:
```
| 둘러보기 (게스트) | 비로그인 읽기 전용 전체 피드. 반응·댓글·게시물 탭은 가입 안내 시트 → 회원가입 / 로그인 | 로그인 화면의 "먼저 둘러보기" (`/explore`, 공개 경로) |
```
`docs/features/auth/plan.md` 로그인 행의 역할에 ` · 둘러보기 진입` 을 더한다.
`docs/testing/features/feed.md` 표에:
```
| `GuestFeedPage` | 목록 / 빈 상태 | 전체 피드를 읽기 전용으로 그리고(더보기 메뉴 없음), 비어 있으면 작성 버튼 없는 빈 안내를 보여준다. |
| `GuestFeedPage` | 게시물 탭 | 가입 안내 시트가 뜨고 회원가입은 `/sign-up` 으로 push, 로그인은 `/sign-in` 으로 go 한다. |
| 로컬 Supabase (`guest_read_check.py`) | anon 읽기·쓰기 | `posts_with_author`·`profiles` 는 200, 게시물·반응 쓰기는 거부된다. |
```
`docs/testing/features/auth.md` `SignInPage | 헤더` 행 기대 결과 끝에 ` 맨 아래에 "먼저 둘러보기" 가 있다.` 를 더한다.
`CLAUDE.md` 의 "로컬 Supabase 검증 스크립트" 코드 블록에 `python3 supabase/tests/guest_read_check.py    # 게스트 읽기 경계` 한 줄 추가.

- [ ] **Step 8: Commit**
```bash
git add app/lib app/test app/lib/l10n supabase/tests/guest_read_check.py docs/features/feed/plan.md docs/features/auth/plan.md docs/testing/features/feed.md docs/testing/features/auth.md CLAUDE.md
git commit -m "feat(feed): 로그인 화면에서 먼저 둘러보기로 읽기 전용 게스트 피드를 연다"
```

---

### Task 8: 전체 검증 · history · status (오케스트레이터가 직접)

**Files:**
- Modify: `docs/features/{feed,auth,post,profile,settings}/history.md` (각 "2026-09-06 — UX 심리학 리뷰 반영" 절)
- Modify: `docs/status.md` (UI 절 아래 새 절)
- Modify: `ux-psychology-review.md` (요약 표에 "상태" 열 추가 → 반영됨/보류)

- [ ] **Step 1: 전체 실행**

Run: `cd app && flutter analyze && flutter test && flutter test test/convention`
Expected: 무결함, 전부 PASS.

- [ ] **Step 2: history** — 각 feature `history.md` 끝에 절 하나. 내용은 "무엇을 · 왜(리뷰 번호) · 검증" 세 줄. status 에 절 하나:
```
## UX 심리학 리뷰 반영 — 2026-09-06

[리뷰](../ux-psychology-review.md) 의 8개 발견 중 7개를 반영했다 (8번은 1번이 대체).

- [x] 팔로잉 빈 상태 "사람 둘러보기" (feed)
- [x] 가입 폼 autofill 힌트 · 닉네임 제안값 (auth)
- [x] 글자 수 카운터 50자 이내에서만 (post)
- [x] 프로필 완성도 카드 20% 시작 (profile)
- [x] 탈퇴 확인에 실제 개수 (settings — `AccountUseCase` 신설)
- [x] 가입 직후 프로필 꾸미기 · "나중에" (router redirect + 편집 화면 setup 모드)
- [x] 로그인 화면 "먼저 둘러보기" → 읽기 전용 게스트 피드 `/explore` (스키마 변경 없음)
```

- [ ] **Step 3: Commit**
```bash
git add docs ux-psychology-review.md
git commit -m "docs(ux): UX 심리학 리뷰 반영 기록과 진행 상태를 남긴다"
```
