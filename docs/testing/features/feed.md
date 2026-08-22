# F4 feed — 테스트 범위

> [테스트 가이드](../README.md) · [아키텍처](../../architecture.md) · [피드 화면](../../../app/lib/features/feed/presentation/page/feed_page.dart)

목록 조회만 담당한다. 게시물 변경은 [post](post.md)가 맡는다.

| 계층 | 검증 대상 |
|---|---|
| data/cursor | 커서 왕복, UTC 정규화, 내부 형식 비노출, 깨진 커서 거부 |
| data/mapper | `FeedPostDto` → post domain 의 `Post`, 커서 생성 |
| data/repository | `limit + 1` 요청, 페이지 자르기, 다음 커서 계산, 마지막 페이지 판정 |
| domain/scenario | 조회 개수 범위와 커서 입력 검증 |
| presentation/cubit | 첫 조회·이어붙이기·종료 조건, 목록 반영(prepend/replace/remove) |

커서 페이지네이션에서 가장 깨지기 쉬운 곳은 **경계**다. 다음 커서를 잘라낸 항목
기준으로 만들면 한 건이 건너뛰어진다. `created_at` 이 같은 항목이 여러 개일 때
`id` tie-break 가 없으면 중복이 생긴다. 두 경우 모두 테스트로 고정했다.

실행:

```bash
cd app
flutter test test/features/feed
```

PostgREST 의 `or(...)` 커서 필터 조립은 mock 으로 검증되지 않는다. 로컬 Supabase 에
`created_at` 이 같은 게시물을 넣고 끊어 읽는 통합 확인이 필요하다.
