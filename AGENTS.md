# UI 공통 위젯 규칙

새 화면이나 기존 화면을 수정할 때 UI 일관성을 위해 아래 규칙을 따른다.

1. 버튼, Snackbar, 타일, 로딩·빈·오류 상태 등 재사용 가능한 UI는 먼저 `app/lib/design_system/widget/`에 같은 역할의 공통 위젯이 있는지 확인한다.
2. 공통 위젯이 있으면 Flutter 기본 위젯을 화면에서 직접 꾸미지 않고, 해당 공통 위젯을 직접 사용한다.
3. 화면·feature에만 필요한 변형은 공통 위젯을 상속하거나 감싸서 만든 feature 전용 위젯으로 제공한다. 이때 공통 스타일은 유지하고, 라벨·콜백·상태·필요한 인자만 변경한다.
4. 변형이 `style` 등의 기존 인자로 해결되면 새 위젯을 만들지 않는다. 반복 사용되거나 새 화면에도 공통으로 쓸 모양일 때만 `design_system/widget/`으로 승격한다.
5. 색상, 여백, 타이포그래피, 모서리 등 시각 토큰은 직접 하드코딩하지 않고 `app/lib/design_system/theme/`의 토큰과 `AppTheme`을 사용한다.

현재 공통 진입점:

- 버튼: `AppButton.primary`, `AppButton.secondary`, `AppButton.text`
- Snackbar: `AppSnackBar.show`
- 목록 행: `AppListTile`
- 인증 입력: `AuthTextField` 및 `InputDecorationTheme`

예외로 Flutter 기본 위젯을 직접 사용해야 한다면, 기존 공통 위젯으로 표현할 수 없는 이유가 있어야 하며 재사용 가능성을 함께 검토한다.

# Freezed 규칙

Freezed 모델은 아래 두 패턴만 사용한다.

1. 단일 불변 모델: Freezed 3 Primary Constructor(= canonical constructor) 패턴을 사용한다.

   ```dart
   @freezed
   class Profile with _$Profile {
     final String id;

     const Profile({required this.id});
   }
   ```

2. 상태·이벤트처럼 여러 변형이 필요한 모델: `sealed class`와 named `factory`를 사용하는 union 패턴을 쓴다. `SubmitState`가 기준 예시다.

   ```dart
   @freezed
   sealed class SubmitState with _$SubmitState {
     const factory SubmitState.idle() = SubmitIdle;
     const factory SubmitState.inProgress() = SubmitInProgress;
     const factory SubmitState.failure(Failure failure) = SubmitFailure;
   }
   ```

분기는 생성된 `when`/`map` 대신 Dart pattern matching `switch`를 우선 사용한다. `.freezed.dart`, `.g.dart`, `injection.config.dart`는 생성 파일이므로 직접 수정하지 않고 build_runner로 갱신한다.
