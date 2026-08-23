# 프로젝트 구조

> [문서 허브](README.md) · [기획](overview.md) · [진행 현황](status.md) · [개발환경](setup.md) · [테스트 가이드](testing/README.md)

> v0.2 · 2026-08-20 작성 · 2026-08-22 갱신 · [overview.md](overview.md)의 기술 스택 결정을 전제로 함

---

## 1. 최상위 구조

```
socialapp/
├── docs/
│   ├── README.md                # 문서 진입점
│   ├── overview.md              # 기획서 (목표·범위·결정과 근거)
│   ├── status.md                # ★ 진행 현황의 단일 기준 (자주 갱신)
│   ├── schema.md                # ★ 테이블·RLS·GRANT의 단일 기준
│   ├── architecture.md          # 이 문서
│   ├── setup.md                 # 개발환경
│   ├── testing/                 # 테스트 실행·규칙·feature별 범위
│   │   ├── README.md
│   │   ├── conventions.md
│   │   └── features/
│   │       └── <feature>.md
│   └── features/
│       └── <feature>/
│           ├── plan.md          # 사전 — 화면·상태·완료 조건 (feature 착수 시 작성)
│           └── history.md       # 사후 — 설계 판단·버그·검증 기록
│
├── supabase/                    # supabase init 결과 (백엔드)
│   ├── config.toml
│   ├── migrations/              # 스키마 변경 실행 이력
│   │   └── 20260820145331_init_profiles.sql
│   └── seed.sql                 # 로컬 개발용 더미 데이터
│
└── app/                         # Flutter 앱
    ├── pubspec.yaml
    ├── lib/
    └── test/
```

**앱과 백엔드를 형제 폴더로 분리한다.** 나중에 자체 백엔드로 전환할 때 `server/`가 하나 더 생기면 되고, 그때 앱 코드는 손대지 않는다.

**스키마의 단일 기준은 [스키마 문서](schema.md)다.** 테이블·정책·권한이 지금 어떤 모습이어야 하는지는 거기서 확인하고, `supabase/migrations/`는 그 상태에 도달하는 실행 이력으로 읽는다.

Studio UI에서 테이블을 직접 만들지 않는다. 반드시 `supabase migration new <name>`으로 SQL 파일을 만들어 커밋하고, **같은 커밋에서 스키마 문서를 갱신한다.** 이걸 지키지 않으면 로컬과 운영 스키마가 갈라진다.

---

## 2. Flutter 내부 구조

**feature-first + 3계층**을 쓴다. domain 안에는 presentation의 진입점을
단순화하는 usecase facade를 둔다.

```
lib/
├── main.dart                    # 진입점 (얇게)
├── bootstrap.dart               # 초기화: Supabase, DI, 전역 에러 핸들러
│
├── app/                         # X1 app shell
│   ├── app.dart                 # MaterialApp + 테마 + 라우터 연결
│   ├── router/
│   │   ├── app_router.dart
│   │   └── auth_guard.dart      # 미인증 → 로그인으로 리다이렉트
│   └── app_bloc_observer.dart   # bloc 전역 로깅
│
├── core/                        # 교차 관심사 (feature에 속하지 않는 것)
│   ├── di/
│   │   ├── injection.dart       # get_it + injectable 설정
│   │   ├── injection.config.dart        # 생성됨
│   │   └── register_module.dart # 서드파티 인스턴스 등록 (@module)
│   ├── network/
│   │   ├── supabase_client_provider.dart
│   │   └── secure_supabase_storage.dart # 세션을 secure storage에 저장
│   ├── error/
│   │   ├── failure.dart         # freezed sealed — 앱 전체의 에러 타입
│   │   └── error_mapper.dart    # PostgrestException/AuthException → Failure
│   ├── result/
│   │   └── result.dart          # Result<T> (성공/실패)
│   ├── pagination/
│   │   └── cursor_page.dart     # CursorPage<T> — 커서는 불투명 문자열
│   ├── media/                   # X3
│   │   ├── image_picker_service.dart
│   │   ├── image_compressor.dart        # 1080px / WebP / q80
│   │   └── image_uploader.dart          # Supabase Storage 업로드
│   ├── storage/
│   │   ├── secure_storage.dart
│   │   └── app_preferences.dart
│   └── extension/
│
├── design_system/               # X4
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── app_colors.dart
│   │   ├── app_typography.dart
│   │   └── app_spacing.dart
│   └── widget/
│       ├── app_button.dart
│       ├── app_avatar.dart
│       ├── empty_view.dart
│       ├── error_view.dart
│       └── loading_view.dart
│
└── features/
    ├── auth/
    │   ├── domain/
    │   │   ├── entity/app_user.dart          # freezed, 순수 Dart
    │   │   └── repository/auth_repository.dart   # ★ 추상 인터페이스
    │   │   └── usecase/
    │   │       ├── auth_usecase.dart          # ★ presentation이 주입받는 facade
    │   │       └── scenario/                  # 사용자 동작별 구현
    │   ├── data/
    │   │   ├── datasource/                   # SDK/원격 데이터 접근
    │   │   ├── dto/app_user_dto.dart          # freezed + json_serializable
    │   │   ├── mapper/app_user_mapper.dart    # DTO ↔ Entity
    │   │   └── repository/supabase_auth_repository.dart  # 조합·구현체
    │   └── presentation/
    │       ├── bloc/
    │       │   ├── auth_bloc.dart
    │       │   ├── auth_event.dart           # freezed sealed
    │       │   └── auth_state.dart           # freezed sealed
    │       ├── page/
    │       │   ├── sign_in_page.dart
    │       │   └── sign_up_page.dart
    │       └── widget/
    │
    ├── profile/    (동일 구조)
    ├── post/
    ├── feed/
    ├── reaction/
    ├── comment/
    ├── follow/
    └── safety/
```

`test/`는 `lib/`의 구조를 그대로 미러링한다. 실제 매핑과 실행 명령은
[테스트 가이드](testing/README.md)를 단일 기준으로 삼는다.

---

## 3. 지켜야 할 규칙 6개

나머지는 자유롭게 하되, 이 여섯은 지킨다.

### ① Supabase 타입은 `data/` 밖으로 나가지 않는다

`PostgrestException`, `Session`, `User` 같은 Supabase SDK 타입이 `domain/`이나 `presentation/`에 등장하면 안 된다. DTO ↔ Entity 변환은 `data/mapper/`에서 끝낸다.

**이 규칙 하나가 "나중에 자체 백엔드로 교체" 가능성을 실제로 보장한다.** 다른 모든 설계보다 이게 중요하다. 어기면 교체 비용이 앱 전체 재작성이 된다.

### ② Repository는 인터페이스로 선언하고 구현체를 주입한다

```dart
// domain/repository/auth_repository.dart
abstract interface class AuthRepository {
  Future<Result<AppUser>> signUp({required String email, required String password});
  Future<Result<AppUser>> signIn({required String email, required String password});
  Future<void> signOut();
  Stream<AppUser?> authStateChanges();
}

// data/repository/supabase_auth_repository.dart
@LazySingleton(as: AuthRepository)
class SupabaseAuthRepository implements AuthRepository { ... }
```

Repository 구현체는 UseCase facade에만 주입한다. Bloc/Cubit은 UseCase facade
인터페이스만 알고, 테스트에서는 이를 가짜로 바꾼다.

### ③ Presentation은 feature별 UseCase facade 하나만 주입받는다

Bloc/Cubit이 Repository를 직접 호출하지 않는다. feature마다 `AuthUseCase`,
`ProfileUseCase`처럼 **한 개의 facade**만 주입받고, 사용자 동작별 구현은
`domain/usecase/scenario/`에 분리한다.

```text
Bloc/Cubit → AuthUseCase (DI 1회) → scenario/sign_in_scenario.dart
                                  → AuthRepository → Supabase 구현체
```

- facade만 DI 등록한다. scenario는 `@injectable`을 붙이지 않는 일반 Dart 클래스다.
- facade는 Repository 하나를 주입받고 scenario에 전달한다. 따라서 Bloc 생성자와 DI
  구성이 기능 수만큼 늘어나지 않는다.
- scenario에는 여러 저장소 호출 조합, 정책, 입력 정규화, 보상 처리처럼 해당 사용자
  동작의 흐름을 둔다. 단순 위임으로 시작해도 이후 확장 위치가 일관된다.
- 테스트는 Bloc에서는 facade를 mock하고, 정책이 있는 scenario는 별도 단위 테스트한다.
  테스트 수준·위치는 [테스트 가이드](testing/README.md)를 따른다.

### ④ Supabase 오류는 data 계층에서 앱 오류로 변환한다

Repository 구현체가 `try/catch`로 Supabase 예외를 잡아 `Failure`와 `Result<T>`로
변환한다. UseCase/scenario는 Supabase 타입을 알지 않으며, 기능 정책에 따른 Result
처리만 한다. 이 경계를 지켜야 백엔드 구현을 교체해도 domain/presentation을 바꾸지
않는다.

### ⑤ 의존 방향은 안쪽으로만

```
presentation ──▶ domain ◀── data
```

domain의 entity와 scenario는 Flutter·Supabase SDK에 의존하지 않는다. `presentation`이
`data`를 직접 참조하지 않는다. `data/repository`는 datasource를 통해 데이터에 접근하고,
SDK 타입은 datasource와 공용 data 인프라 안에서만 다룬다.

### ⑥ feature 간 참조는 최소로

feature끼리 필요하면 **`domain` 계층만** 참조한다. `data`끼리는 참조하지 않는다 — DTO가 필요하면 각자 만든다. 위젯을 공유해야 하면 소유자가 명확한 쪽에 두고 import한다. 애매하면 `design_system/widget/`으로 올린다.

**post와 feed의 경계가 이 규칙의 기준 예시다.**

| | 소유 |
|---|---|
| `features/post` | `Post` · `PostAuthor` 엔티티, 작성·수정·삭제, 에디터 화면, `PostTile` 위젯 |
| `features/feed` | 목록 조회, 커서 페이지네이션, 무한 스크롤, 피드 화면, `FeedPost` 엔티티 |

feed는 post의 `domain/entity/post.dart`를 그대로 쓴다. 같은 게시물을 두 벌로 표현하지 않기 위해서다. 목록 항목은 `FeedPost = Post + PostAuthor`로 **감싸고**, `Post`에 작성자 필드를 더하지 않는다 — 작성자 프로필이 필요 없는 에디터 화면까지 그 값을 채워야 하기 때문이다.

**DTO는 각자 갖는다.** 피드는 작성자를 조인한 뷰(`posts_with_author`)를 읽고 앞으로 반응·댓글 수 컬럼이 여기에만 더해지지만, 게시물 단건 조회는 그렇지 않다. 지금 모양이 비슷하다고 합치면 그때 되돌려야 한다.

목록 상태는 feed가, 게시물 변경은 post가 소유한다. 화면은 변경 결과를 `FeedCubit.prependPost` / `replacePost` / `removePost`로 목록에 반영한다. 변경할 때마다 전체를 다시 읽으면 스크롤 위치가 사라진다.

---

## 3-1. 목록은 커서 페이지네이션으로 만든다

`OFFSET`은 스크롤 도중 새 글이 올라오면 항목이 밀려서 중복되거나 건너뛰어진다.
`(created_at desc, id desc)` 복합 커서를 쓴다.

- domain과 presentation은 커서를 **불투명 문자열**로만 다룬다. 형식을 아는 곳은
  `features/<feature>/data/cursor/`뿐이다
- repository가 `limit + 1`개를 요청해 다음 페이지 존재 여부를 판단한다. 전체 개수를
  세는 COUNT 쿼리가 필요 없다
- 다음 커서는 **잘라낸 뒤 실제로 돌려주는 마지막 항목** 기준으로 만든다. 잘라낸
  항목으로 만들면 한 건이 건너뛰어진다
- `created_at`이 같은 항목이 여러 개일 수 있으므로 `id` tie-break를 반드시 넣는다

DB 쪽 인덱스와 정렬 조건은 [스키마](schema.md)를 따른다.

---

## 4. bloc 사용 지침

- **이벤트가 여러 개인 화면은 Bloc**, 상태 전환이 단순한 화면은 **Cubit**. 섞어 써도 된다. 로그인 폼에 Bloc은 과하다
- 상태는 freezed **sealed class**로 만든다 — `Initial` / `Loading` / `Loaded` / `Error`. 컴파일러가 분기 누락을 잡아준다
- Bloc은 화면 수명과 함께 산다. `BlocProvider`로 페이지에서 생성하고, DI에는
  **Repository 구현체와 feature별 UseCase facade**만 등록한다 (Bloc을 싱글톤으로 등록하지 말 것)
- 낙관적 업데이트(좋아요, 팔로우)는 Bloc 안에서 처리하고 실패 시 이전 상태로 롤백한다

---

## 5. 멀티패키지(melos)를 쓰지 않는 이유

앱이 하나뿐이고 혼자 개발한다. melos 멀티패키지의 이점(빌드 격리, 팀 간 경계)은 이 조건에서 발생하지 않는 반면, **패키지마다 build_runner를 돌려야 해서 코드 생성이 느려지고 의존성 관리가 번거로워진다.**

`features/` 폴더 분리만으로 경계는 충분히 잡힌다. 앱이 둘 이상 되거나 코드를 재사용할 일이 생기면 그때 패키지로 추출한다 — 지금 구조라면 추출 비용이 낮다.

---

## 6. 의존성

```bash
# 상태관리 · 모델
flutter pub add flutter_bloc bloc equatable
flutter pub add freezed_annotation json_annotation

# DI
flutter pub add get_it injectable

# 백엔드 · 저장
flutter pub add supabase_flutter
flutter pub add flutter_secure_storage shared_preferences

# 이미지
flutter pub add image_picker flutter_image_compress cached_network_image

# 라우팅
flutter pub add go_router

# 개발 의존성
flutter pub add --dev build_runner freezed json_serializable injectable_generator
flutter pub add --dev bloc_test mocktail
```

버전은 고정하지 않고 `pub add`가 해석한 최신을 쓴다.

**drift는 2단계에서 추가한다** (`drift`, `drift_flutter`, `drift_dev`). 1단계에는 로컬 DB가 필요 없다.

코드 생성은 개발 중 watch 모드를 상시 켜둔다:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

---

## 7. 진행 현황

이 문서는 구조와 규칙만 다룬다. 단계별 체크리스트와 다음 할 일은
**[진행 현황](status.md)이 단일 기준**이다. 세부 구축 절차와 겪은 함정은
[setup.md](setup.md) 참조. 스키마의 현재 모습은 [schema.md](schema.md)를 본다.
