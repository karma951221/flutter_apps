# F7 safety(신고·차단) — 구현 기록

> [트레이더 허브](../../README.md) · [신고 계획](plan.md) · [차단 계획](plan-block.md) · [스키마 §12·§13](../../schema.md) · [테스트](testing.md)

## 2026-08-24 — 폴리모픽 신고와 대상 검증 트리거

`reports` 테이블, `enforce_report_target()` 트리거, `safety` 도메인/데이터 계층,
공통 오버플로 메뉴, 신고 시트, 세 진입점(게시물 · 댓글 · 프로필)을 계획대로 만들었다.
아래는 구현하면서 계획과 달라진 것과 그 이유다.

### `RadioListTile(groupValue:)` 대신 `RadioGroup`

계획서의 시트 구성 예시는 `RadioListTile`에 `groupValue`를 직접 주는 모양을 가정했다.
이 프로젝트가 쓰는 Flutter 버전에서는 그 방식이 deprecated라, 실제 구현은 사유
목록 전체를 `RadioGroup<ReportReason>`으로 감싸고 각 `RadioListTile`은 `value`만
갖는 형태로 썼다 (`app/lib/features/safety/presentation/widget/report_sheet.dart`).
동작은 계획과 같다 — 선택된 사유가 상태에 반영되고 제출 전에는 버튼이 잠긴다.

### 성공 Snackbar는 시트가 아니라 호출한 화면이 띄운다

`ReportSheet.show`는 접수 여부를 `Future<bool>`로 돌려준다. 시트 자신의
`BuildContext`로 `AppSnackBar.show`를 부르면, 시트가 닫히는 순간 그 context도
함께 사라져 스낵바가 뜨지 않거나 예외가 난다. 그래서 시트는 `Navigator.pop(true)`로
성공만 알리고, 스낵바는 실제 호출부인 `feed_page` · `profile_page` · `post_comments_page`가
자신의 context로 띄운다 (`post_tile` · `comment_tile`은 콜백을 올려보내는 위젯일 뿐
스낵바를 직접 띄우지 않는다). 계획서는 "성공하면 시트를 닫고
`AppSnackBar.show`"라고만 적어 이 책임 분리를 명시하지 않았다.

### `security definer`의 근거 문구를 바로잡았다

마이그레이션 주석과 스키마 문서, 이 feature의 계획서 모두 "`post_comments`가
`content` 컬럼에 SELECT를 주지 않으므로 invoker로는 대상 행을 읽지 못한다"는
이유로 `security definer`를 정당화했다. 검수에서 이 근거가 틀렸다는 지적이 나왔다 —
트리거가 실제로 읽는 컬럼은 `author_id`와 `deleted_at` 뿐이고, 둘 다
`grant select (id, post_id, parent_id, author_id, created_at, deleted_at)`로
GRANT돼 있으며 `post_comments_select_visible` 정책(`deleted_at is null`) 아래
살아 있는 댓글에 대해서는 invoker 권한으로도 읽힌다. `security definer`는 미래에
GRANT가 바뀌어도 트리거가 계속 옳게 동작한다는 방어적 설계로는 여전히 정당하지만,
"content를 못 읽어서"라는 근거는 사실이 아니었다. [스키마 §12](../../schema.md)와
[계획](plan.md)의 문구를 고쳤다. 적용된 마이그레이션
(`supabase/migrations/20260824140000_add_reports.sql`)의 주석은 고치지 않았다 —
이미 적용된 마이그레이션 파일은 손대지 않는다는 규칙이라, 그 주석이 옛 근거를
그대로 담고 있다는 점을 스키마 문서에 남겼다.

## 2026-08-25 — facade 이름을 `ReportUseCase`에서 `SafetyUseCase`로 바꿨다

검수에서 아키텍처 규칙 ③(presentation은 feature별 facade 하나만 주입받고,
그 facade는 feature 이름을 따른다)과 어긋난다는 지적이 나왔다. 폴더 이름은
`safety`인데 facade는 `ReportUseCase`였다 — 차단(blocking)이 이 폴더에
이어 붙으면 `ReportUseCase.block()`처럼 읽혀 혼동을 준다. `ReportUseCase` →
`SafetyUseCase`, `DefaultReportUseCase` → `DefaultSafetyUseCase`로 이름과
파일(`report_use_case.dart` → `safety_use_case.dart`)을 바꿨다.
`ReportRepository` · `ReportDataSource` · `ReportTarget` · `ReportReason` ·
`ReportPolicy` · `ReportState` · `ReportCubit` · `ReportSheet`는 신고
고유의 이름이라 그대로 뒀다 — 차단이 붙으면 그 옆에 형제로 늘어날 이름들이다.

## 검증 (신고)

[테스트 문서](testing.md)에 단위 · 위젯 테스트 범위가 있다.
로컬 Supabase에 사용자 A · B 두 계정의 JWT로 확인한 권한 경계(트리거 세 분기,
중복 신고, 위조 방지, 조회 격리)는 이 feature의 완료 조건 확인 작업 기록에 있다 —
결과 표는 아래 "검증" 절 요약과 계획서의 완료 조건 체크박스를 참고한다.

| 확인 | 결과 |
|---|---|
| 내 게시물 신고 | `400` · `내 게시물은 신고할 수 없습니다` |
| 내 댓글 신고 | `400` · `내 댓글은 신고할 수 없습니다` |
| 자기 사용자 신고 | `400` · `23514`(`reports_not_self_user`) |
| 중복 신고 | 1회차 `201`, 2회차 `409` · `23505`(`reports_once`) |
| 삭제된 게시물 신고 | `400` · `신고할 대상이 없습니다` |
| 없는 `target_id` | `400` · `신고할 대상이 없습니다` |
| `reporter_id` 위조 | `403` · `42501` |
| `status` 위조 | `403` · `42501` |
| 남의 신고 조회 | 본인 신고만 보임 (B의 select 결과에 A의 행이 없음) |
| 빈 상세 설명(REST 직접) | `400` · `23514`(`reports_detail_length`) |

모두 계획대로 동작해 별도로 고친 것은 없다.

## 2026-08-25 — 차단(F7 blocking) Task 1~5

`blocks` 테이블 · `is_blocked_with()` 판정 함수 · `posts`/`post_comments` 조회
정책 재정의 · `post_comments_visible` 재정의 · `enforce_comment_depth()` 트리거
확장 · `BlockRepository` 도메인/데이터 계층 · 게시물 메뉴 차단 진입점(Task 3a) ·
차단 목록 화면(Task 4)까지 계획대로 만들었다. 아래는 계획과 달라진 것이다 —
계획을 그대로 옮기지 않는다.

### Task 3b(프로필 AppBar 차단/차단 해제 메뉴)를 미뤘다

[차단 계획](plan-block.md)의 화면 표는 `profile_page`의 AppBar 메뉴에도 차단 /
차단 해제 항목을 넣기로 했다. 이 작업 도중 저장소에는 **다른 workstream**이
`profile_cubit.dart` · `profile_state.dart` · `profile_state.freezed.dart` ·
`edit_profile_page.dart`에 이미 미커밋 변경을 올려 둔 상태였다 — 닉네임 중복 확인
기능으로 보인다. `profile_state.freezed.dart`는 **생성 파일**이라 `ProfileState`에
`isBlocked` 필드를 하나 추가하는 것만으로도 그 workstream이 아직 커밋하지 않은
필드 변경과 뒤섞인 새 코드가 통째로 재생성된다 — 두 workstream의 변경을 파일
단위로 분리할 방법이 없다. `git add -p`로 hunk를 나눠도 생성 파일은 소스가 아니라
빌드 결과물이라 의미 있는 hunk 경계가 없다.

그래서 AppBar 메뉴 항목(차단 / 차단 해제, `ProfileState.isBlocked` 추가)은 **Task
3b로 미뤘다** — 다른 workstream이 그 파일들을 커밋한 뒤에 붙인다. 대신
게시물 메뉴 진입점(Task 3a, `post_tile`의 '이 사용자 차단')은 이 workstream이
건드리지 않는 `post_tile.dart` · `feed_page.dart` · `profile_page.dart`(게시물
목록의 `PostTile` 콜백만, AppBar는 아님)에 붙어 있어 그대로 완성했다. 즉 **차단
자체(DB · 진입점 하나 · 목록 화면)는 끝났고, 프로필 화면에서 상대를 차단하는
두 번째 진입점만 남았다.**

### `BlockedUsersPage`가 `AppButton.text`를 `IntrinsicWidth`로 감쌌다

`AppListTile.trailing`에 `AppButton.text`('차단 해제')를 그대로 넣으면 레이아웃
예외가 났다 — `AppListTile`의 `trailing` 슬롯이 고정 폭을 기대하는데
`AppButton.text`가 내부적으로 무한 폭(`Row`+`Expanded` 계열)을 요구해 제약이
풀리는 상황이었다. 버튼을 새로 만들지 않고 `IntrinsicWidth`로 감싸 버튼이 필요한
만큼만 폭을 요구하도록 했다 (`app/lib/features/safety/presentation/page/blocked_users_page.dart`).
`AppListTile`·`AppButton` 자체는 고치지 않았다 — 이 조합 하나에서만 나는 문제라
공통 위젯을 바꾸는 것은 과했다.

## 검증 (차단)

[테스트 문서](testing.md)의 "차단" 절에 단위 · 위젯 테스트
범위와 Task 5의 DB 검증 결과 표(12개 완료 조건 전부 + 감정표현 부작용 1건)가
있다. 요약:

| 확인 | 결과 |
|---|---|
| A → B 차단 후 A의 피드에서 B가 사라짐 | `[]` |
| **B의 JWT로 본 A(양방향)** | `[]` |
| `comment_count`와 실제 목록 | 3 → 1, 목록도 1건 — 일치 |
| 답글만 차단된 부모 댓글 | 되살아나지 않고 완전히 사라짐 |
| B가 A의 글에 댓글 삽입 | `403` · "이 게시물에는 댓글을 달 수 없습니다" (최종 검토에서 방향 중립 문구로 교체, 아래 참고) |
| 자기 차단 / 중복 차단 / `blocker_id` 위조 | `23514` / `23505` / `42501` |
| 남의 차단 목록 조회 | `[]` |
| 차단 해제 | 양쪽·개수·되살아난 댓글 모두 원복 |
| 차단한 사용자 프로필 | 여전히 열림(화면의 메뉴 전환은 Task 3b) |
| 비로그인 조회 | 영향 없음 |
| (부작용) 감정표현 삽입 | 차단 상태에서 `403`(RLS) — 스펙 대비 DB가 더 엄격, [스키마 §10](../../schema.md)에 기록 |

모두 계획대로 동작해 스키마·트리거·정책은 고칠 것이 없었다. 문서 오류 두 건만
고쳤다 — `is_blocked_with()`의 `stable` 설명 과장(스키마 §3·계획서)과, 감정표현
차단 부작용이 스펙에 반영되지 않은 것(스키마 §10·계획서).

## 2026-08-25 — 최종 전체 브랜치 검토: 차단 사실 노출 문구를 방향 중립으로 고쳤다

전체 브랜치 검토에서 `enforce_comment_depth()`가 던지는 차단 거부 문구
(`차단한 사용자의 게시물에는 댓글을 달 수 없습니다`)가 이 feature의 중심
프라이버시 결정("차단 사실 노출: 알리지 않는다" — [계획서](plan-block.md))을
어긴다는 지적이 나왔다.

**왜 새는지.** 이 예외를 실제로 보는 사람은 차단"한" 사람(A)이 아니라
차단"당한" 사람(B)이다. B가 A의 게시물 댓글 화면을 이미 연 상태에서 A가 B를
차단하면, B가 그 화면에서 등록을 누르는 순간 이 트리거가 걸린다. 그런데 B는
아무도 차단하지 않았다 — "차단한 사용자"라는 말이 B에게는 거짓이고, 동시에
① 차단 관계가 존재한다는 사실과 ② 누가 걸었는지 방향까지 B에게 드러낸다.
계획서가 막으려던 "당신은 차단당했습니다"류의 보복 방아쇠와 본질이 같다.
감정표현 경로(`post_reactions_insert_own`·`comment_reactions_insert_own`)는
차단 필터가 걸린 `posts`·`post_comments`를 서브쿼리로 읽다가 행이 안 보여
일반 `42501`로 떨어지므로 원래도 새지 않았다 — 트리거가 직접 문구를 짓는
댓글 경로만 새고 있었다.

**고침.** 문구를 방향 중립인 `이 게시물에는 댓글을 달 수 없습니다`로 바꿨다 —
누가 차단했는지와 무관하게 두 당사자 모두에게 참이고, 차단 여부 자체를
암시하지 않는다(원래도 로그인 상태에서 댓글을 못 다는 다른 이유들과 구분되지
않는 문구다). 적용된 마이그레이션(`20260825120000_add_blocks.sql`)은 고치지
않는다는 규칙이라, 새 마이그레이션
`supabase/migrations/20260825130000_neutral_block_message.sql`이
`create or replace function public.enforce_comment_depth()`로 이 문자열 하나만
바꿨다 — 나머지 네 검사(게시물 작성자 차단 여부는 유지, 부모 존재·답글의
답글·같은 게시물·삭제된 부모)는 그대로다.

같은 마이그레이션에서 두 가지를 더 고쳤다.

- `is_blocked_with(uuid)`에 `grant execute ... to anon, authenticated`를
  명시적으로 추가하고 `comment on function`으로 `anon`이 반드시 이 권한을
  유지해야 하는 이유(비로그인 피드가 이 함수를 통해 걸러진다)를 남겼다 —
  [스키마 §3](../../schema.md)에 같은 경고를 옮겨 적었다.
- `20260825120000_add_blocks.sql`의 주석이 `stable`을 "같은 인자에 대해 한
  번만 평가된다"고 설명한 부분은 이미 `d529678`에서 계획서·스키마 문서 쪽은
  고쳤지만, 다음 사람이 실제로 보는 것은 마이그레이션 파일의 주석이다.
  `comment on function public.is_blocked_with(uuid)`로 올바른 설명(행마다
  재평가된다)을 DB 객체 자체에 남겨, 문서를 안 읽어도 `\df+`나 `\dd`로 바로
  보이게 했다.

`SupabaseErrorMapper._blockMessages`와 그 테스트, [계획서](plan-block.md),
[테스트 문서](testing.md)도 같은 문구로 갱신했다.

## 2026-08-25 — 같은 전체 브랜치 검토: `FeedCubit.loadMore()` 가 차단된 작성자를 되살리던 버그를 고쳤다

`removeAuthor()`가 걷어낸 작성자가 `loadMore()` 이후 다시 나타날 수 있었다.
원인은 둘이었다.

- `loadMore()`가 요청을 보내기 **전**의 `state`를 `final current`로 캡처해
  두고, 응답이 온 뒤 그 캡처 위에 병합했다. 요청이 떠 있는 동안 `removeAuthor`
  가 실행되면 그 변경은 캡처된 스냅샷에 없으므로, 병합 시 사라졌다.
- `loadMore()`의 요청 자체가 차단이 걸리기 **전**에 이미 서버로 나갔을 수
  있다 — 그러면 서버(양방향 차단 필터)가 아직 반영하지 못한 그 작성자의
  글이 응답 페이지에 그대로 실려 온다. 첫 번째를 고쳐도 이 경로는 남는다.

`FeedCubit`에 `_hiddenAuthorIds`(걷어낸 작성자 id 집합)를 추가했다.
`removeAuthor`가 여기 채우고, `_load()`(새로 불러오기)가 비운다 — 그 순간부터는
서버가 이미 걸러 주므로 클라이언트가 따로 들고 있을 이유가 없다. `loadMore()`는
캡처해 둔 `current`가 아니라 응답이 온 시점의 최신 `state`에 병합하고, 들어오는
페이지도 `_hiddenAuthorIds`로 한 번 더 거른다. 두 메커니즘을 각각 재현하는
테스트를 `feed_cubit_test.dart`에 추가했다(`Completer`로 응답 타이밍을
붙들어 두고 그 사이에 `removeAuthor`를 호출하는 방식).

다른 mutator(`removePost`·`prependPost`·`replacePost`·`applyReaction`·
`applyCommentCount`)는 손대지 않았다 — 이들은 await 사이에 끼는 지점이
없어 같은 stale-snapshot 문제가 없다. `refresh()`가 `loadMore()`와 동시에
실행될 때의 별도 경합(`_generation` 카운터로 고칠 종류)도 이번 범위 밖이라
그대로 뒀다 — 차단과 무관한 pre-existing 이슈다.

## 2026-08-25 — 같은 전체 브랜치 검토: 차단 호출이 위젯에서 곧바로 나가던 것을 `BlockActionCubit`으로 옮겼다

`feed_page.dart` · `profile_page.dart`가 각각 위젯 메서드 안에서
`getIt<SafetyUseCase>().blockUser(authorId)`를 직접 불렀다 — 아키텍처 규칙
③(presentation은 Bloc/Cubit을 거쳐 facade에 닿는다)을 어겼고, 신고가 이미
`ReportCubit`으로 이 규칙을 지키고 있는 것과도 어긋났다. 같은 로직이 두 화면에
그대로 복제돼 있었고, 전역 `getIt`을 오버라이드하지 않고는 위젯 테스트도 쓸 수
없었다.

`ReportCubit`/`ReportSheet`를 모델로 `BlockActionCubit`
(`app/lib/features/safety/presentation/cubit/block_action_cubit.dart`) +
`BlockActionState`를 새로 만들었다. `block(userId)` 하나와 진행 중 상태만
가지고, `BuildContext`는 알지 못한다 — 목록 반영(`FeedCubit.removeAuthor` /
`refresh()`)과 스낵바는 여전히 호출한 화면이 갖는다. 두 화면 모두
`MultiBlocProvider`에 `BlockActionCubit`을 추가하고 `context.read`로 부르도록
바꿨다.

이전에는 불가능했던 위젯 테스트를 새로 만들었다 —
`app/test/features/feed/presentation/page/feed_page_test.dart`(이 경로에
테스트 파일이 아예 없었다). 확인 다이얼로그 → 차단 → 목록 제거 → 성공
스낵바 흐름, 다이얼로그를 취소하면 차단이 호출되지 않는다는 것, 실패하면
목록이 그대로 남고 오류 스낵바가 뜬다는 것 세 가지를 검증한다.
`profile_page_test.dart`도 새 `BlockActionCubit` 의존성을 `getIt`에 등록하도록
갱신했다(그 화면의 차단 흐름 자체에 대한 새 테스트는 이번에 추가하지 않았다 —
요구된 범위는 최소 feed 화면 하나였다).

차단 확인 다이얼로그(`AlertDialog` + 취소 + destructive 확인 버튼)가
`feed_page` · `profile_page`(차단, 완전히 동일한 코드) · `account_settings_page`
(탈퇴, 제목·본문·라벨만 다른 같은 모양) 세 곳에 있었다. CLAUDE.md 규칙 4의
"반복 사용되거나 새 화면에도 공통으로 쓸 모양"에 해당한다고 판단해
`design_system/widget/app_confirm_dialog.dart`로 승격했다(`AppConfirmDialog.show`).
세 곳 모두 이걸 쓰도록 바꿨다. 게시물 삭제 확인 다이얼로그(`feed_page` ·
`profile_page`에도 동일하게 중복돼 있다)는 이번 지적 대상이 아니라서 건드리지
않았다 — 별도로 정리할 만하지만 이번 커밋의 범위는 아니라고 판단했다.

## 2026-08-25 — 같은 전체 브랜치 검토: `isBlocked` → `isBlockedByMe`, `unblockUser` 비대칭 수정

`BlockRepository.isBlocked` · `BlockDataSource.isBlocked` ·
`SafetyUseCase.isBlocked`가 양방향처럼 읽히는 이름을 쓰고 있었지만 실제로는
"내가 이 사람을 차단했는가"만 답한다 — 상대가 나를 차단한 경우는 이 메서드로
알 수 없다(그 판정은 `is_blocked_with()`가 DB에서만 한다). 호출부가 하나뿐인
지금 이름을 고쳤다 — `isBlockedByMe`. `IsBlockedScenario` →
`IsBlockedByMeScenario`로 클래스와 파일(`is_blocked_scenario.dart` →
`is_blocked_by_me_scenario.dart`)도 함께 바꿨다. `repository` · `datasource` ·
`impl` · `SafetyUseCase` · 관련 테스트 전부와 계획서·테스트 문서의 표기도
갱신했다.

`unblockUser()`가 바로 위 `blockUser()`와 달리 로그인 여부를 확인하지 않고,
삭제 결과도 확인하지 않았다 — 지울 행이 없어도(이미 해제됐거나 애초에 차단한
적 없는 대상) 조용히 `Ok`가 나가 성공 스낵바가 떴다. 오늘은 이 경로가 인증
가드가 걸린 라우트에서만 열려 실제로 닿지 않지만, 이웃 메서드와의 비대칭이라
`blockUser()`와 같은 로그인 가드를 추가하고 `.delete().select().single()`로
바꿔 0행이면 `PGRST116`(→ `Failure.notFound`)이 나가도록 했다.

## 2026-08-25 — 같은 전체 브랜치 검토: F8(팔로우)을 위한 결정표를 남겼다

차단이 팔로우 관계에 아직 손대지 않는다는 것, 팔로우 목록 조회 경로는
차단 필터를 자동으로 물려받지 않는다는 것, "DB 쪽 차단 거부는 방향을 밝히지
않는다"는 원칙을 F8이 그대로 재도출하지 않도록 [계획서](plan-block.md)에 세
항목을 적어 뒀다. 자세한 내용은 계획서의 "F8 follow-up" 절을 본다.

## 2026-08-25 — Task 3b: 프로필 메뉴에 차단을 붙였다

타인 프로필 AppBar 메뉴에 `차단` 또는 `차단 해제` 하나와 기존 `신고`를 함께
표시했다. 프로필이 실제로 로드된 뒤 그 id로 `isBlockedByMe`를 조회하므로, 라우트
파라미터가 아니라 화면에 표시 중인 사용자를 대상으로 동작한다. 상태는
`ProfileState`가 아니라 `BlockActionCubit`이 소유한다. 닉네임 중복 확인 workstream이
`profile_cubit.dart`·`profile_state.dart`·생성된 Freezed 파일을 이미 수정 중이어서
그 경로에 상태를 추가하면 생성 파일 hunk가 섞인다. 더 근본적으로 차단·해제 호출을
이미 소유한 Cubit이 메뉴 전환 상태까지 가지는 편이 응집돼 있다.

`isBlocked`는 `bool?`로 뒀다. `null`은 아직 조회하지 않았거나 조회에 실패해 모르는
상태이며, 이때는 차단 관련 메뉴를 표시하지 않는다. `false`와 구분하지 않으면 이미
차단한 사용자에게 다시 '차단'을 권할 수 있다. 조회는 오직 `isBlockedByMe`만 써서
상대가 나를 차단했는지는 화면에 드러내지 않는다.

차단은 기존 게시물 메뉴와 같은 확인 다이얼로그를 재사용한다. 차단 해제는
[계획서](plan-block.md) "확인 절차" 결정(차단은 확인, 해제는 즉시)대로 확인
없이 바로 실행한다 — 최초 구현은 실수로 해제에도 확인 다이얼로그를 넣었었는데,
차단 목록 화면(`blocked_users_page`)의 즉시 해제 동작과 어긋나고 스펙에도
없어 리뷰에서 걷어냈다(2026-08-26). 성공 후에는 프로필 게시물 피드를 새로
읽고 스낵바를 보이며, 진행 중에는 메뉴 자체가 열리지 않는다(`AppOverflowMenu.
enabled`가 `PopupMenuButton.enabled`로 이어진다 — 같은 리뷰에서 `onSelected`
만 잠그던 것을 고쳤다, 메뉴가 열리기만 하고 반응이 없는 상태를 막는다). AppBar
차단과 게시물 목록 차단 두 진입점이 같은 확인·호출·새로고침·스낵바 흐름을
쓰도록 `_confirmAndBlock` 헬퍼 하나로 합쳤다(`profile_page.dart`). Cubit 단위
테스트와 프로필 위젯 테스트로 상태 전환, 실패 시 숨김, 확인 뒤 실행, 취소하면
호출되지 않는 것, 해제 뒤 재조회, 차단 성공 후 메뉴 재전환까지 확인했다.
