# F3 post — 테스트 범위

> [테스트 가이드](../README.md) · [아키텍처](../../architecture.md) · [스키마](../../schema.md)

게시물 자체의 작성·수정·삭제를 담당한다. 목록 조회는 [feed](feed.md)가 맡는다.

| 계층 | 검증 대상 |
|---|---|
| data/mapper | `PostDto` → `Post` 필드 보존, snake_case 컬럼명 매핑 |
| data/repository | 미인증(`null`)을 인증 실패로, 삭제 실패(`false`)를 `notFound`로 변환 |
| domain/scenario | 본문 정규화와 길이 검증, 빈 식별자 차단, 저장소 위임 |
| presentation/cubit | 제출 상태 전이, 중복 제출 차단, usecase 위임 |

본문 길이 검증은 `PostPolicy.maxContentLength`를 기준으로 한다. 이 값은
[스키마](../../schema.md)의 `posts_content_length` CHECK 와 같아야 한다.

실행:

```bash
cd app
flutter test test/features/post
```

`SupabasePostDataSource`의 fluent query 와 `soft_delete_post` RPC 는 mock 대신 로컬
Supabase 통합 테스트로 검증한다.
