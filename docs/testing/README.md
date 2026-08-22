# 테스트 가이드

> [문서 허브](../README.md) · [아키텍처](../architecture.md) · [개발환경](../setup.md) · [컨벤션 검사](conventions.md)

테스트는 구현 코드의 구조를 그대로 반영한다. feature 테스트는 반드시
`app/test/features/<feature>/`에 두고, 해당 구현은
`app/lib/features/<feature>/`에서 찾는다.

```text
app/lib/                         app/test/
├── core/                 →      ├── core/
├── features/
│   ├── auth/             →      ├── features/auth/
│   ├── feed/             →      ├── features/feed/
│   └── profile/          →      └── features/profile/
└── …                     →      └── convention/  # 코드베이스 전체 규칙
```

공통·교차 관심사 검사는 `test/core/`, `test/convention/`에 둔다. 특정 feature의
테스트를 공통 디렉터리에 두지 않는다.

## 실행

```bash
cd app
flutter test                 # 전체 테스트
flutter analyze              # 정적 분석
flutter test test/features/feed
flutter test test/convention
```

## 테스트 수준

- **scenario**: 입력 정규화, 정책, 저장소 호출 조합을 mock repository로 검증한다.
- **repository/mapper**: DTO와 domain 변환, `Failure`/`Result` 경계 처리를 검증한다.
- **presentation**: Bloc/Cubit은 UseCase facade를 mock하고 상태 전이를 검증한다.
- **Supabase query/RLS**: fluent query의 세부 조립은 mock보다 로컬 Supabase 통합
  테스트로 검증한다.

## Feature별 범위

- [auth](features/auth.md)
- [feed](features/feed.md)
- [profile](features/profile.md)
- [코드 컨벤션 검사](conventions.md)
