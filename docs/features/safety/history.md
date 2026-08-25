# F7 safety(신고·차단) — 구현 기록

> [문서 허브](../../README.md) · [신고 계획](plan.md) · [차단 계획](plan-block.md) · [스키마 §12·§13](../../schema.md) · [테스트](../../testing/features/safety.md)

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

[테스트 문서](../../testing/features/safety.md)에 단위 · 위젯 테스트 범위가 있다.
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

[테스트 문서](../../testing/features/safety.md)의 "차단" 절에 단위 · 위젯 테스트
범위와 Task 5의 DB 검증 결과 표(12개 완료 조건 전부 + 감정표현 부작용 1건)가
있다. 요약:

| 확인 | 결과 |
|---|---|
| A → B 차단 후 A의 피드에서 B가 사라짐 | `[]` |
| **B의 JWT로 본 A(양방향)** | `[]` |
| `comment_count`와 실제 목록 | 3 → 1, 목록도 1건 — 일치 |
| 답글만 차단된 부모 댓글 | 되살아나지 않고 완전히 사라짐 |
| B가 A의 글에 댓글 삽입 | `403` · "차단한 사용자의 게시물에는 댓글을 달 수 없습니다" |
| 자기 차단 / 중복 차단 / `blocker_id` 위조 | `23514` / `23505` / `42501` |
| 남의 차단 목록 조회 | `[]` |
| 차단 해제 | 양쪽·개수·되살아난 댓글 모두 원복 |
| 차단한 사용자 프로필 | 여전히 열림(화면의 메뉴 전환은 Task 3b) |
| 비로그인 조회 | 영향 없음 |
| (부작용) 감정표현 삽입 | 차단 상태에서 `403`(RLS) — 스펙 대비 DB가 더 엄격, [스키마 §10](../../schema.md)에 기록 |

모두 계획대로 동작해 스키마·트리거·정책은 고칠 것이 없었다. 문서 오류 두 건만
고쳤다 — `is_blocked_with()`의 `stable` 설명 과장(스키마 §3·계획서)과, 감정표현
차단 부작용이 스펙에 반영되지 않은 것(스키마 §10·계획서).
