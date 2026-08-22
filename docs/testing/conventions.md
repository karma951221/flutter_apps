# 코드 컨벤션 검사

> [테스트 가이드](README.md) · [아키텍처](../architecture.md)

`app/test/convention/freezed_constructor_convention_test.dart`는 생성 파일을 제외한
`app/lib/` 전체를 스캔한다.

- 단일 Freezed 모델은 `const ClassName(...)` canonical constructor를 선언해야 한다.
- 단일 모델은 `const factory ClassName`을 사용하면 안 된다.
- 여러 변형이 필요한 sealed union은 named `const factory ClassName.case(...)`를
  사용해야 한다.
- `CursorPage<T>` 처럼 타입 매개변수를 가진 모델도 같은 규칙을 따른다.

실행:

```bash
cd app
flutter test test/convention/freezed_constructor_convention_test.dart
```

새 Freezed 모델을 추가하거나 생성자 형태를 바꿀 때는 이 테스트도 함께 통과해야 한다.
