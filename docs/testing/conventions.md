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

## ARB description

`app/test/convention/arb_description_convention_test.dart`는 gen-l10n 템플릿인
`app/lib/l10n/app_ko.arb` 하나만 스캔한다.

- `@`로 시작하지 않는 모든 키는 짝이 되는 `@key`에 비어 있지 않은 `description`을
  가져야 한다.
- `@key` 메타데이터는 템플릿에만 둔다. `app_en.arb`·`app_ja.arb`는 검사하지 않는다.
- 빠진 키 이름을 실패 메시지에 그대로 적는다.

description 은 번역자가 그 문구의 쓰임새를 아는 유일한 단서다. 특히 `failure*` 키는
어떤 도메인 오류에 붙는지 모르면 en·ja 로 옮길 수 없다.

## 트리거 문구 매핑

`app/test/convention/trigger_message_mapping_test.dart`는
`supabase/migrations/*.sql`에서 한글이 든 예외 문구를 모두 뽑아
`app/lib/core/data/mapper/supabase_error_mapper.dart`에 있는지 확인한다.

- `raise exception '...'`과 `using message = '...'` 두 형태를 모두 읽는다.
- mapper 는 문구를 `static const` 맵(`_commentDepthMessages`·`_reportTargetMessages`·
  `_blockMessages`·`_roomCapacityMessages`)에 담는다. 테스트는 mapper 를 실행하지 않고
  원문을 부분 문자열로 확인한다.
- 폐기된 문구는 테스트 안의 `_supersededMessages` 상수에 문자열 하나씩 적는다. 지금은
  `20260825130000_neutral_block_message.sql`이 갈아끼운
  '차단한 사용자의 게시물에는 댓글을 달 수 없습니다' 하나뿐이다.

mapper 가 문구를 모르면 23514·23503 의 기본 문구("입력값이 조건을 만족하지 않습니다")로
덮여 원인이 사라지고, 매핑되지 않은 한국어 원문이 en·ja 사용자에게 그대로 샌다.

실행:

```bash
cd app
flutter test test/convention
```

트리거의 `raise` 문구를 추가·변경하면 mapper 와 이 테스트가 함께 통과해야 한다.
