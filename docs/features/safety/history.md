# F7 safety(신고) — 구현 기록

> [문서 허브](../../README.md) · [계획](plan.md) · [스키마 §12](../../schema.md) · [테스트](../../testing/features/safety.md)

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

## 검증

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
