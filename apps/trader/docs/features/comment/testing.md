# F6 comment — 테스트 범위

> [테스트 가이드](../../../../../docs/testing/README.md) · [아키텍처](../../../../../docs/architecture.md) · [계획](plan.md) · [스키마 §8·§9](../../schema.md)

댓글·답글의 조회·작성·삭제를 담당한다. 감정 계산은 [reaction](../reaction/testing.md)이 맡고,
여기서는 그 요약이 목록 항목에 실려 오는지만 본다.

| 대상 | 시나리오 | 기대 결과 |
|---|---|---|
| `CommentCursor` | 인코딩 → 디코딩 왕복 | 커서가 손실 없이 복원된다. |
| `CommentCursor` | null · 빈 문자열 | 첫 페이지로 해석된다. |
| `CommentCursor` | 깨진 커서 | validation 실패로 거부된다. 내부 형식은 밖으로 드러나지 않는다. |
| `PostCommentDto` | 뷰 한 행 변환 | 작성자는 `PostAuthor` 로, 감정은 `ReactionSummary` 로 나뉘어 `PostComment` 가 된다. |
| `PostCommentDto` | 삭제된 댓글 | `content` 가 null 이고 `isDeleted` 가 참이다. 본문을 지우는 것은 앱이 아니라 뷰다. |
| `PostCommentDto` | 답글 | `parentId` 가 있고 `isReply` 가 참이다. |
| `PostCommentDto` | 뷰 응답 JSON 역직렬화 | `author_nickname` · `reply_count` · `reaction_counts` · `my_reaction` 스네이크 케이스 컬럼을 읽는다. |
| `PostCommentDto` | 커서 생성 | 정렬 기준(`created_at`, `id`)으로 만들어진다. |
| `CommentRepositoryImpl` | 페이지 조회 | 다음 페이지 유무를 알기 위해 `limit + 1` 개를 요청하고, 초과분은 잘라 다음 커서를 만든다. |
| `CommentRepositoryImpl` | 다음 커서의 기준 | **잘라낸 뒤 실제로 돌려주는 마지막 항목**으로 만든다. 잘라낸 항목 기준이면 한 건이 건너뛰어진다. |
| `CommentRepositoryImpl` | 받은 커서 / 깨진 커서 | 해석해 데이터 원천에 넘긴다 / `Err` 로 반환한다. |
| `CommentRepositoryImpl` | 답글 페이지 | 부모 목록과 같은 규칙으로 나뉜다. 두 조회는 같은 뷰를 읽고 좁히는 조건만 다르다. |
| `CommentRepositoryImpl` | 작성 | 서버가 준 `id` · `created_at` 에 화면이 아는 작성자·본문을 붙여 돌려준다. 방금 쓴 댓글을 다시 조회하지 않는다 (왕복 한 번). |
| `CommentRepositoryImpl` | 답글 작성 | `parentId` 를 그대로 들고 온다. |
| `CommentRepositoryImpl` | 비로그인 작성·삭제 | 인증 실패(`Err`)다. data source 가 null 을 주는 것이 그 신호다. |
| `CommentRepositoryImpl` | 남의 댓글 삭제 | `Ok(false)` 다. 예외가 아니라 "지워진 행이 없음"이다. |
| `GetCommentsScenario` | 허용 범위 밖 개수 · 공백 커서 | 저장소를 호출하지 않고 validation 실패로 막는다. |
| `GetCommentsScenario` | 정상 범위 | 그대로 저장소에 위임한다. |
| `GetRepliesScenario` | 부모 id 조회 | `parentId` 를 그대로 넘긴다. 검증 규칙은 부모 목록과 같다. |
| `AddCommentScenario` | 앞뒤 공백 | 다듬어 저장한다. |
| `AddCommentScenario` | 공백뿐인 본문 · 300자 초과 | 저장하지 않는다. 최종 판정은 DB CHECK 지만 왕복 전에 막는다. |
| `AddCommentScenario` | 정확히 300자 | 저장한다 — 경계값이 DB CHECK(`between 1 and 300`)와 같아야 한다. |
| `AddCommentScenario` | 답글 | `parentId` 를 그대로 넘긴다. 2단 제한의 최종 판정은 DB 트리거다. |
| `DeleteCommentScenario` | 빈 id | 요청 자체를 막는다. |
| `DeleteCommentScenario` | 저장소 결과 | `true`/`false` 를 그대로 돌려준다. |
| `CommentCubit` | 첫 조회 / 실패 | 결과와 다음 커서를 담는다 / 실패 상태로 남는다. |
| `CommentCubit` | 더 불러오기 | 직전 커서로 요청해 이어 붙인다. |
| `CommentCubit` | 답글 펼치기 | **처음 펼칠 때 한 번만** 읽는다. 접었다 펴도 다시 읽지 않는다. |
| `CommentCubit` | 댓글 작성 | 목록 끝에 붙고 `countDelta` 가 하나 는다 (오래된 순이라 새 것의 자리가 끝이다). |
| `CommentCubit` | 답글 작성 | 부모의 `replyCount` 가 오르고 답글 목록이 함께 펼쳐진다. |
| `CommentCubit` | 답글 없는 댓글 삭제 | 목록에서 빠진다. |
| `CommentCubit` | 답글 있는 댓글 삭제 | 본문만 사라지고 자리는 남는다 — 서버 뷰의 판단을 앱이 미리 그린다. |
| `CommentCubit` | 답글 삭제 | 부모의 `replyCount` 가 하나 준다. |
| `CommentCubit` | 남의 댓글 삭제(`false`) | 목록을 건드리지 않는다. |
| `PostCommentsPage` | 빈 목록 | 첫 댓글을 권하는 안내를 보여준다. |
| `PostCommentsPage` | 삭제된 부모 | 본문 자리에 안내만 남고 답글 버튼을 그리지 않는다. |
| `PostCommentsPage` | 답글 펼치기 | 버튼을 누르기 전에는 답글을 읽지 않는다. |
| `PostCommentsPage` | 답글 버튼 | 입력줄이 답글 대상을 표시한다. |
| `PostCommentsPage` | 등록 | 입력한 본문이 저장되고 목록 끝에 붙는다. |

`CommentTile`의 메뉴가 `isMine`에 따라 삭제/신고 중 옳은 항목만 보여주는지는 신고
진입점 테스트라 [safety 테스트 문서](../safety/testing.md)의 "진입점" 절에 있다.

## 로컬 Supabase 로만 확인되는 것

이 feature 에서 가장 위험한 것들은 mock 으로 드러나지 않는다.
[comment 계획서의 검증 항목](plan.md)을 따른다.

- 답글에 답글을 다는 삽입, 다른 게시물의 댓글을 `parent_id` 로 지정한 삽입을
  **트리거**가 거부하는지
- 삭제된 댓글의 본문을 **어떤 경로로도** 읽을 수 없는지 (뷰는 null, 테이블 직접
  조회는 `content` GRANT 가 없어 42501)
- `created_at` 이 같은 댓글이 여럿일 때 asc 커서에 중복·누락이 없는지
- `insert ... returning id, created_at` 이 컬럼 단위 GRANT 와 충돌하지 않는지
- **삭제된 게시물에 댓글·답글 삽입이 거부되는지** (403 — 정책이 막는다)

실행:

```bash
cd app
flutter test test/features/comment
```
