# 테스트 가이드

> [문서 허브](../README.md) · [아키텍처](../architecture.md) · [개발환경](../setup.md) · [E2E](e2e.md) · [컨벤션 검사](conventions.md)

테스트는 구현 코드의 구조를 그대로 반영한다. feature 테스트는 반드시
`app/test/features/<feature>/`에 두고, 해당 구현은
`app/lib/features/<feature>/`에서 찾는다.

```text
app/lib/                         app/test/
├── core/                 →      ├── core/
├── features/
│   ├── auth/             →      ├── features/auth/
│   ├── feed/             →      ├── features/feed/
│   ├── post/             →      ├── features/post/
│   ├── profile/          →      ├── features/profile/
│   ├── reaction/         →      ├── features/reaction/
│   ├── comment/          →      ├── features/comment/
│   ├── safety/           →      ├── features/safety/
│   ├── home/             →      ├── features/home/
│   └── settings/         →      └── features/settings/
└── …                     →      └── convention/  # 코드베이스 전체 규칙
```

공통·교차 관심사 검사는 `test/core/`, `test/convention/`에 둔다. 특정 feature의
테스트를 공통 디렉터리에 두지 않는다.

## 실행

```bash
cd app
flutter test                 # 전체 테스트
flutter analyze              # 정적 분석
flutter test test/features/post
flutter test test/convention
```

E2E는 에뮬레이터와 로컬 Supabase가 필요하므로 별도로 돈다. [E2E 테스트](e2e.md) 참고.

```bash
cd app
patrol test
```

## 테스트 수준

- **scenario**: 입력 정규화, 정책, 저장소 호출 조합을 mock repository로 검증한다.
- **repository/mapper**: DTO와 domain 변환, `Failure`/`Result` 경계 처리를 검증한다.
- **presentation**: Bloc/Cubit은 UseCase facade를 mock하고 상태 전이를 검증한다.
- **Supabase query/RLS**: fluent query의 세부 조립은 mock보다 로컬 Supabase 통합
  테스트로 검증한다.
- **E2E**: 라우터 리다이렉트, 세션 유지, 화면 간 값 전달처럼 mock으로는 확인되지
  않는 연결을 실제 앱·실제 Supabase로 검증한다. `app/patrol_test/`에 둔다.

## Feature별 범위

feature 문서는 **대상 · 시나리오 · 기대 결과** 표 형식으로 통일한다. 테스트를
추가·변경하면 해당 문서의 표를 같은 커밋에서 갱신한다.

- [auth](features/auth.md)
- [profile](features/profile.md)
- [post](features/post.md)
- [feed](features/feed.md)
- [reaction](features/reaction.md)
- [comment](features/comment.md)
- [safety](features/safety.md)
- [settings](features/settings.md)
- [검수 기록 (2026-08-24)](audit-2026-08-24.md)
- [코드 컨벤션 검사](conventions.md)
- [E2E 테스트 (Patrol)](e2e.md)
