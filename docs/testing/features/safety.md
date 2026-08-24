# F7 safety(신고) — 테스트 범위

> [테스트 가이드](../README.md) · [아키텍처](../../architecture.md) · [계획](../../features/safety/plan.md) · [스키마 §12](../../schema.md)

게시물·댓글·사용자 신고 접수를 담당한다. 차단은 이 feature의 범위가 아니다
([계획](../../features/safety/plan.md)의 "범위" 참고).

| 대상 | 시나리오 | 기대 결과 |
|---|---|---|
| `ReportPolicy.normalizeDetail` | `null` | `null`로 남는다. |
| `ReportPolicy.normalizeDetail` | 빈 문자열 · 공백만 | `null`이 된다. |
| `ReportPolicy.normalizeDetail` | 앞뒤 공백이 있는 문자열 | 다듬어져 저장된다. |
| `ReportPolicy.normalizeDetail` | 최대 길이(500자) 문자열 | 그대로 유지된다. |
| `ReportTargetMapper.toPayload` | `post` · `comment` · `user` 세 변형 | 각각 `target_type` 문자열과 `target_id`로 매핑된다. |
| `SubmitReportScenario` | 앞뒤 공백이 있는 `detail` | 다듬어 저장소에 넘긴다. |
| `SubmitReportScenario` | 공백뿐인 `detail` | `null`로 정규화해 넘긴다. |
| `SubmitReportScenario` | 저장소의 `Err` | 그대로 돌려준다. |
| `ReportRepositoryImpl` | 정상 제출 | `Ok(null)`을 돌려준다. |
| `ReportRepositoryImpl` | `reports_once`(23505) | `ValidationFailure('이미 신고한 항목입니다')`로 변환된다. |
| `ReportRepositoryImpl` | 내 게시물 신고 트리거 문구(P0001) | 같은 문구의 `ValidationFailure`로 변환된다. |
| `ReportCubit` | 사유 선택 | 상태에 반영된다. |
| `ReportCubit` | 사유를 고르지 않음 | `canSubmit`이 `false`다. |
| `ReportSheet` | 열림 | 사유 5개가 모두 보인다. |
| `ReportSheet` | 사유 선택 전 | 제출 버튼이 비활성이다. |
| `ReportSheet` | 상세 설명 입력칸 | 처음부터(사유와 무관하게) 보인다. |
| `ReportSheet` | 제출 성공 | 시트가 닫히고 `show()`가 `true`를 돌려준다. |
| `ReportSheet` | 제출 실패 | 시트가 열려 있고 `Failure.message`가 보인다. |
| `ReportSheet` | 작은 화면 + 키보드로 뜬 bottom inset | `SingleChildScrollView`로 스크롤되어 제출 버튼까지 닿고 누를 수 있다. |

## 진입점(entry point) — `post_tile` · `post_comments_page` · `profile_page`

신고 시트 자체가 아니라 시트를 여는 세 진입점이 `isMine`에 따라 올바른 메뉴 항목을
그리는지를 각 feature의 위젯 테스트로 확인한다. 시트가 있는 이 문서가 자연스러운
기준이다 — 구현은 `features/post` · `features/comment` · `features/profile`에 있지만
검증 대상은 신고 진입점이라서다.

| 대상 | 시나리오 | 기대 결과 |
|---|---|---|
| `PostTile` | 내 글 | 수정 · 삭제가 뜨고 신고는 없다. |
| `PostTile` | 남의 글 | 신고가 뜨고 수정 · 삭제는 없다. |
| `PostTile` | 신고 선택 | `onReport`가 불린다. |
| `PostTile` | 콜백이 모두 `null` | 메뉴 자체가 그려지지 않는다. |
| `PostTile` | 내 글 + `onReport`도 있음 | `isMine`이 최종 판정이라 신고는 뜨지 않는다 (회귀). |
| `PostTile` | 남의 글 + `onEdit`·`onDelete`도 있음 | `isMine`이 최종 판정이라 수정 · 삭제는 뜨지 않는다 (회귀). |
| `PostCommentsPage` | 남의 댓글 메뉴 | 신고가 있다. |
| `PostCommentsPage` | 내 댓글 메뉴 | 삭제가 있고 신고는 없다. |
| `ProfilePage` | 타인 프로필 AppBar | 신고 메뉴가 있다. |
| `ProfilePage` | 내 프로필 AppBar | 메뉴가 없다. |

## 로컬 Supabase로만 확인되는 것 — Step 1 (권한 경계)

[safety 계획서의 완료 조건](../../features/safety/plan.md)을 사용자 A · B 두 계정의
JWT로 REST(PostgREST)에 직접 확인했다.

- `enforce_report_target()` 트리거의 세 분기: 대상 없음 · 내 게시물 · 내 댓글이 각각
  거부되는지 (`security definer`가 `post_comments`의 `author_id`·`deleted_at`을
  읽어 판정한다)
- `reports_not_self_user` CHECK로 자기 자신을 `user`로 신고하는 것이 막히는지
- `reports_once` 유니크로 같은 대상 재신고가 `23505`로 막히는지
- 삭제된 게시물을 대상으로 한 신고가 "존재하는 대상"과 같은 방식으로 거부되는지
- `reporter_id` · `status`를 페이로드에 실어도 컬럼 GRANT가 없어 `42501`로
  거부되는지 (위조 방지가 정책이 아니라 GRANT다)
- `reports_select_own` 정책으로 남의 신고 행이 select에 섞이지 않는지
- 빈 문자열 `detail`을 REST로 직접 보내면 `reports_detail_length`(23514)로
  거부되는지 (앱 경로는 `ReportPolicy.normalizeDetail`이 `null`로 정규화해 애초에
  이 CHECK에 닿지 않는다)

실행:

```bash
cd app
flutter test test/features/safety
```
