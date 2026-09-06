# F4 feed — 테스트 범위

> [테스트 가이드](../README.md) · [아키텍처](../../architecture.md) · [계획](../../features/feed/plan.md) · [구현 기록](../../features/feed/history.md) · [피드 화면](../../../app/lib/features/feed/presentation/page/feed_page.dart)

목록 조회만 담당한다. 게시물 변경은 [post](post.md)가, 감정 계산은
[reaction](reaction.md)이, 댓글은 [comment](comment.md)가 맡는다. 여기서는 그
결과가 목록 항목에 실려 오고 반영되는지만 본다.

| 대상 | 시나리오 | 기대 결과 |
|---|---|---|
| `FeedCursor` | 인코딩 → 디코딩 왕복 | 커서가 손실 없이 복원되고, 로컬 시각은 UTC로 정규화된다. |
| `FeedCursor` | null · 빈 문자열 | 첫 페이지로 해석된다. |
| `FeedCursor` | 깨진 커서 · 구분자 없음 · 빈 id | validation 실패로 거부된다. 내부 형식은 밖으로 드러나지 않는다. |
| `FeedPostMapper` | `FeedPostDto` 변환 | 게시물은 post domain의 `Post`로, 작성자는 `PostAuthor`로 나뉘어 `FeedPost`가 된다. |
| `FeedPostMapper` | 아바타 없는 작성자 | 닉네임은 그대로, `avatarUrl`만 null이 된다. |
| `FeedPostMapper` | 뷰 응답 JSON 역직렬화 | `author_nickname` · `author_avatar_url` 스네이크 케이스 컬럼을 읽는다. |
| `FeedPostMapper` | 커서 생성 | 정렬 기준(`created_at`, `id`)으로 만들어진다. |
| `FeedPostMapper` | 반응 집계·댓글 수 | 뷰의 `reaction_counts` · `my_reaction` · `comment_count` 가 항목에 실려 온다. 항목마다 다시 조회하지 않는다. |
| `FeedPostMapper` | 반응이 없는 게시물 | 집계는 비고 `my_reaction` 은 null 이며 댓글 수는 0 이다. |
| `FeedRepositoryImpl` | 페이지 조회 | 다음 페이지 유무를 알기 위해 `limit + 1`개를 요청하고, 초과분은 잘라 다음 커서를 만든다. |
| `FeedRepositoryImpl` | 작성자 동봉 | 항목마다 작성자가 함께 오고, 목록을 받은 뒤 추가 조회를 하지 않는다 (N+1 방지). |
| `FeedRepositoryImpl` | 마지막 페이지 | 요청 개수 이하(빈 결과 포함)면 다음 커서 없이 마지막 페이지로 반환한다. |
| `FeedRepositoryImpl` | 받은 커서 / 깨진 커서 | 해석해 데이터 원천에 넘긴다 / `Err`로 반환한다. |
| `GetFeedPostsScenario` | 입력 검증 | 첫 페이지는 커서 없이, 받은 커서는 그대로 위임. 허용 범위 밖 개수와 공백 커서는 저장소를 호출하지 않는다. |
| `GetFeedPostsScenario` | 작성자 필터 | `authorId` 를 그대로 저장소에 넘기고, 지정하지 않으면 null 로 요청한다. 커서와 함께 와도 둘 다 넘어간다. |
| `DefaultFeedUseCase` | 시나리오 위임 | 개수·커서·작성자가 시나리오를 거쳐 저장소까지 그대로 전달된다. |
| `FeedCubit` | 첫 조회 / 실패 | 결과와 다음 커서를 상태에 담는다 / 실패 상태로 남긴다. |
| `FeedCubit` | 더 불러오기 | 직전 커서로 요청해 이어 붙이고, 마지막 페이지에서는 요청하지 않는다. 이어 붙인 항목도 자기 작성자를 들고 온다. |
| `PostTileActions` | 피드 · 프로필 공용 | 수정 · 댓글 이동 · 감정 · 신고 · 삭제 다섯 흐름을 두 화면이 같은 코드로 쓴다. 두 화면의 위젯 테스트가 각각 이 경로를 지난다. |
| `PostTileActions.confirmDelete` | 삭제 확인 | `AppConfirmDialog`(destructive)를 거쳐야 삭제하고, 성공하면 `removePost` + 스낵바로 이어진다. |
| `FeedCubit` | 목록 반영 (prepend/replace/remove) | 작성·수정·삭제 결과를 재조회 없이 반영하고, 목록을 읽기 전의 반영 요청은 무시한다. |
| `FeedCubit` | 수정 시 작성자 유지 | 게시물 내용만 바뀌고 작성자 표시는 그대로다. 수정 화면은 작성자를 알 필요가 없다. |
| `FeedCubit` | 없는 id 반영 | 목록이 변하지 않는다. |
| `FeedCubit` | 반응 반영 (`applyReaction`) | 해당 항목의 반응만 바뀌고 다른 항목과 작성자 표시는 그대로다. 낙관적 업데이트와 실패 복원이 같은 메서드를 쓴다. |
| `FeedCubit` | 댓글 수 반영 (`applyCommentCount`) | 댓글 화면에서 돌아올 때 목록을 다시 읽지 않고 해당 항목의 수만 바꾼다. |
| `FeedCubit` | 목록을 읽기 전의 반응 반영 | 무시한다 (상태 전이가 없다). |
| `FeedCubit` | 작성자 필터 조회 (`loadForAuthor`) | 첫 페이지와 다음 페이지 모두 그 작성자로 요청한다. 새로고침해도 필터가 남는다. |
| `FeedCubit` | 전체 피드 복귀 (`load`) | 작성자 필터를 지우고, 이후 새로고침도 필터 없이 요청한다. |
| `SupabaseErrorMapper` | `posts_content_length` 위반 | 500자 초과 저장이 사용자 문구로 번역된다 (rename 이후 제약 이름 회귀). |
| `FeedPage` | 팔로잉 탭 빈 상태 | "사람 둘러보기" 를 누르면 전체 탭으로 옮기고 전체 피드를 읽는다. |
| `HomeShellPage` | 하단 내비게이션 | 홈 · 프로필 · 설정 세 곳을 보여주고, 탭을 옮기면 그 화면이 앞으로 나온다. |
| `HomeShellPage` | 탭 왕복 | 목록을 다시 읽지 않는다 — `IndexedStack` 이 탭 본문을 살려 둔다.
| `GuestFeedPage` | 목록 / 빈 상태 | 전체 피드를 읽기 전용으로 그리고(더보기 메뉴 없음), 비어 있으면 작성 버튼 대신 "회원가입" 을 둬 가입 안내 시트로 잇는다. |
| `GuestFeedPage` | 게시물 탭 | 가입 안내 시트가 뜨고 회원가입은 `/sign-up` 으로 push, 로그인은 `/sign-in` 으로 go 한다. |
| 로컬 Supabase (`guest_read_check.py`) | anon 읽기·쓰기 | 앱과 같은 컬럼 목록으로 `posts_with_author` 를 읽어 200 과 행 모양(`images` 는 목록, `my_reaction` 은 없음)을 보고, `profiles` 도 200 이며, 게시물·반응 쓰기는 401/403 이다. |

커서 페이지네이션에서 가장 깨지기 쉬운 곳은 **경계**다. 다음 커서를 잘라낸 항목
기준으로 만들면 한 건이 건너뛰어진다. `created_at` 이 같은 항목이 여러 개일 때
`id` tie-break 가 없으면 중복이 생긴다. 두 경우 모두 테스트로 고정했다.

실행:

```bash
cd app
flutter test test/features/feed
```

`SupabaseErrorMapper` 는 공용 data 인프라라 테스트가
`test/features/auth/data/mapper/` 에 있다.

## mock 으로 확인되지 않는 것

아래 둘은 로컬 Supabase 로 확인해야 한다.

- **커서 필터 조립** — PostgREST 의 `or(...)` 문자열은 mock 을 통과한다. `created_at`
  이 같은 게시물을 여러 개 넣고 끊어 읽어야 경계 동작이 드러난다.
- **`posts_with_author` 의 `security_invoker`** — 뷰가 기반 테이블의 RLS 를 그대로
  따르는지. 소프트 삭제한 게시물이 피드 조회에서 실제로 빠지는지 확인한다. 이 옵션이
  빠지면 삭제된 글이 그대로 보이는데, 앱 테스트로는 절대 잡히지 않는다
  ([구현 기록](../../features/feed/history.md)).
