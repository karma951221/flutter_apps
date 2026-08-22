# F4 feed — 테스트 범위

> [테스트 가이드](../README.md) · [아키텍처](../../architecture.md) · [피드 화면](../../../app/lib/features/feed/presentation/page/feed_page.dart)

| 계층 | 검증 대상 |
|---|---|
| data/mapper | `FeedPostDto`에서 `FeedPost`로의 필드 보존 변환 |
| domain/scenario | 생성·수정 본문 정규화와 길이 검증 |
| domain/scenario | 목록/단건 조회, 삭제의 입력 검증과 repository 위임 |

실행:

```bash
cd app
flutter test test/features/feed
```

Supabase의 피드 작성·수정·삭제 RLS 정책은 로컬 Supabase 통합 테스트로 추가 검증한다.
