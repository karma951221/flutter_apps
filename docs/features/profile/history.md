# F2 profile — 구현 기록

> [문서 허브](../../README.md) · [계획](plan.md) · [스키마](../../schema.md) · [테스트](../../testing/features/profile.md)

## 2026-08-23 — 아바타와 타인 프로필

공통 X3 media 처리로 갤러리에서 사진을 고르고, 긴 변 1080px·WebP·품질 80으로
압축한 뒤 `avatars/{user_id}/`에 올린다. 업로더는 현재 인증 사용자의 ID로 경로를
직접 만들며, Storage RLS도 같은 첫 경로 조각을 검사한다. 공개 버킷 URL만
`profiles.avatar_url`에 저장해 `AppAvatar`와 피드가 같은 값을 표시한다.

`/users/:userId`는 내 프로필과 같은 화면을 재사용한다. 피드의 타인 게시물 탭이 이
경로로 연결되며, 본인이 아닐 때는 프로필 편집 UI를 렌더링하지 않는다. 목록 조회는
기존 `posts_with_author` 커서 규칙에 `author_id` 필터를 더해 재사용했으므로 전체
피드와 프로필 목록의 페이지 경계 규칙이 일치한다.

## 검증

- `flutter analyze` 통과
- `flutter test test/features/profile test/features/feed test/features/post test/convention` 통과
- Storage와 RLS의 실제 거부/허용은 로컬 Supabase 재적용 후 통합 확인이 필요하다.
