# daylog — 에이전트 가이드

Flutter + Supabase 소셜 피드 앱(토이 프로젝트). 앱은 `app/`, 백엔드는
`supabase/`(마이그레이션·RLS), 문서는 `docs/`에 있다.

## 먼저 읽을 것

작업 전에 [docs/README.md](docs/README.md)(문서 허브)에서 필요한 문서를 찾는다.
자주 쓰는 단일 기준:

| 알고 싶은 것 | 문서 |
|---|---|
| 지금 어디까지 왔고 다음이 뭔가 | [docs/status.md](docs/status.md) |
| 기능의 의도·범위·결정 근거 | [docs/overview.md](docs/overview.md) |
| 앱 구조와 계층 규칙 | [docs/architecture.md](docs/architecture.md) |
| 테이블·RLS·GRANT의 현재 모습 | [docs/schema.md](docs/schema.md) |
| 로컬 환경 준비·재현 절차 | [docs/setup.md](docs/setup.md) |
| feature별 화면·상태·완료 조건 | `docs/features/<name>/plan.md` |
| 테스트 실행·범위 | [docs/testing/README.md](docs/testing/README.md) |
| E2E(Patrol) 설정·실행 | [docs/testing/e2e.md](docs/testing/e2e.md) |

## 작업 규칙

- **스키마 변경**: Studio UI 금지. `supabase migration new <name>`으로 SQL을 만들고,
  같은 커밋에서 [docs/schema.md](docs/schema.md)를 결과에 맞게 갱신한다
- **진행 상태 갱신**: [docs/status.md](docs/status.md)에만 적는다. 다른 문서에는
  진행 상태를 쓰지 않는다
- **feature 착수/완료**: 착수 시 `docs/features/<name>/plan.md`, 완료 시 `history.md`,
  테스트는 `docs/testing/features/<name>.md`를 함께 갱신한다
- **테스트 위치**: 구현 구조를 그대로 반영한다. `app/lib/features/<name>/` ↔
  `app/test/features/<name>/`. 특정 feature 테스트를 공통 디렉터리에 두지 않는다
- **문서 링크**: 상대 Markdown 링크만 쓴다. `app/test/convention/documentation_links_test.dart`가
  `docs/` 안의 깨진 링크를 잡는다 (이 파일은 검사 대상이 아니므로 링크를 직접 확인한다)
- **생성 파일**: `.freezed.dart`, `.g.dart`, `injection.config.dart`는 직접 수정하지 않고
  build_runner로 갱신한다

## 명령

```bash
cd app
flutter test                     # 전체 테스트
flutter analyze                  # 정적 분석
flutter test test/convention     # 컨벤션·문서 링크 검사
dart run build_runner watch --delete-conflicting-outputs   # 코드 생성 (개발 중 상시)

supabase start                   # 로컬 백엔드 기동 (프로젝트 루트)
supabase db reset                # 마이그레이션 전체 재적용 (로컬 데이터 초기화)
```

E2E는 **로컬 Supabase + 에뮬레이터**가 둘 다 떠 있어야 한다. 자세한 준비는
[docs/testing/e2e.md](docs/testing/e2e.md).

```bash
cd app
patrol test                                    # patrol_test/ 전체
patrol test -t patrol_test/auth_test.dart
patrol develop -t patrol_test/post_test.dart   # Hot Restart 로 짜면서 실행
```

에뮬레이터 기동은 `android-emulator` 스킬이 대신한다("에뮬레이터 띄워줘").

---

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
- 아바타: `AppAvatar`
- 빈 상태·오류 안내: `AppPlaceholder`
- 확인 다이얼로그: `AppConfirmDialog.show` (되돌리기 어려운 동작. 로그아웃처럼
  되돌리기 쉬운 것은 `isDestructive: false`)
- 더보기 메뉴: `AppOverflowMenu` + `AppOverflowMenuItem`
- 아이콘 + 개수 버튼: `AppCountAction`
- 인증 입력: `AuthTextField` 및 `InputDecorationTheme`

시각 토큰은 `design_system/theme/` 의 `AppColors` · `AppSpacing` · `AppRadius` 와
`Theme.of(context)` 를 쓴다. `Colors.*` · 숫자 여백 · `BorderRadius.circular(n)` 을
화면에 직접 적지 않는다.

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

분기는 생성된 `when`/`map` 대신 Dart pattern matching `switch`를 우선 사용한다.

## 로컬 Supabase 검증 스크립트

RLS·실시간처럼 mock 으로 드러나지 않는 것은 `supabase/tests/` 의 스크립트가
실제 JWT + REST/WebSocket 으로 확인한다. 스키마를 바꾸면 해당 스크립트도 함께
갱신한다.

```bash
supabase start
python3 supabase/tests/chat_rls_check.py       # 채팅 권한 경계
python3 supabase/tests/chat_realtime_check.py  # 실시간 전달 (pip install websockets)
python3 supabase/tests/guest_read_check.py     # 게스트 읽기 경계
python3 supabase/tests/account_summary_check.py  # 탈퇴 확인 개수 경계
```
