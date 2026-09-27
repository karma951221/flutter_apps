# 프로젝트 구조

> [문서 허브](README.md) · [기획](../apps/trader/docs/overview.md) · [진행 현황](status.md) · [개발환경](setup.md) · [테스트 가이드](testing/README.md)

> v0.2 · 2026-08-20 작성 · 2026-08-22 갱신 · [overview.md](../apps/trader/docs/overview.md)의 기술 스택 결정을 전제로 함

---

## 1. 최상위 구조

```
socialapp/
├── docs/                        # 두 앱이 함께 쓰는 문서만
│   ├── README.md                # 문서 진입점 — 앱 허브로 가는 입구
│   ├── status.md                # 모노레포 작업 · 앱별 한 줄 상태
│   ├── architecture.md          # 이 문서
│   ├── dependencies.md          # 패키지 간 실제 의존
│   ├── setup.md                 # 도구 · 앱 실행 · iOS · 공통 함정
│   ├── testing/                 # 테스트 실행·규칙·컨벤션 검사
│   └── superpowers/             # 스펙(specs/) · 실행 계획(plans/) 기록
│
├── supabase/                    # supabase init 결과 (백엔드)
│   ├── config.toml
│   ├── migrations/              # 스키마 변경 실행 이력
│   │   └── 20260820145331_init_profiles.sql
│   ├── seeds/                   # db reset 이 적재하는 seed (config.toml 의 sql_paths)
│   │   └── market_candles.sql   # ★ 생성 파일 — 직접 수정 금지
│   ├── scripts/                 # 데이터 수집 스크립트 (표준 라이브러리만)
│   │   └── fetch_candles.py     # Binance 일봉 → seeds/market_candles.sql
│   └── tests/                   # 로컬 Supabase 대상 권한·실시간 검증 스크립트
│
├── pubspec.yaml                 # pub workspace 루트 (workspace: [...])
├── melos.yaml                   # analyze · test · gen · l10n 일괄 실행
├── apps/
│   ├── trader/                  # 첫째 앱 daylog — main · bootstrap · app shell · router · DI 조립 · config · home · patrol_test
│   │   └── docs/                # 앱 문서 — README · status(★ 진행 현황) · overview · schema(★ DDL·RLS) ·
│   │                            #   setup · e2e · audits/ · features/<name>/{plan,history,testing}.md
│   └── commute/                 # 둘째 앱 통근 시간 — Supabase 없음. core · design_system · l10n · feature_commute 만 조립
│       └── docs/                # 앱 문서 — README · status · plan · history · testing
└── packages/
    ├── core/                    # error · result · pagination · validation · data 인프라 · media · di
    ├── design_system/           # theme + widget
    ├── l10n/                    # ARB + AppLocalizations + failure/validation localizations
    └── features/                # feature_<name> 패키지. lib/src/ 아래가 §2 의 3계층
        ├── auth/ post/ feed/ comment/ follow/ reaction/
        ├── profile/ chat/ safety/ settings/ preferences/ trade/
        └── commute/             # 둘째 앱 전용. feature_* 를 참조하지 않는다
```

**앱과 백엔드를 형제 폴더로 분리한다.** 나중에 자체 백엔드로 전환할 때 `server/`가 하나 더 생기면 되고, 그때 앱 코드는 손대지 않는다.

**앱은 둘이다.** `apps/trader` 가 feature 12개를 조립하는 본 앱이고, `apps/commute` 는
기반 패키지 셋(`core` · `design_system` · `l10n`)만으로 둘째 앱이 서는지 시험하는
앱이다([계획](../apps/commute/docs/plan.md)). 두 앱은 `pubspec.yaml` 의 `workspace:` 로
패키지를 이름으로 resolve 하고, 실제 의존 관계는 [의존 그래프](dependencies.md)에 있다.

`packages/features/commute` 는 **`Routes` 대신 콜백을 받는다** — 페이지가
`onOpenSettings` · `onDone` 을 인자로 받고 경로는 `apps/commute` 의 라우터가 정한다.
기존 feature 들이 `core` 의 `Routes` 로 `context.push` 하는 것과 다른 선택이고, 어느
쪽으로 통일할지는 패키지 경계 리팩터링에서 결정한다
([설계 §7](superpowers/specs/2026-09-13-commute-app-design.md#7-리팩터링-후보--이-앱을-만들며-확인된-것)).

**스키마의 단일 기준은 [스키마 문서](../apps/trader/docs/schema.md)다.** 테이블·정책·권한이 지금 어떤 모습이어야 하는지는 거기서 확인하고, `supabase/migrations/`는 그 상태에 도달하는 실행 이력으로 읽는다.

Studio UI에서 테이블을 직접 만들지 않는다. 반드시 `supabase migration new <name>`으로 SQL 파일을 만들어 커밋하고, **같은 커밋에서 스키마 문서를 갱신한다.** 이걸 지키지 않으면 로컬과 운영 스키마가 갈라진다.

`seeds/` 의 파일은 **스크립트가 만든 산출물이지 손으로 쓰는 데이터가 아니다.** 시세를
고치려면 `scripts/fetch_candles.py` 를 다시 돌려 seed 를 덮어쓴다
([트레이더 개발환경 §4](../apps/trader/docs/setup.md)).

---

## 2. Flutter 내부 구조

**feature-first + 3계층**을 쓴다. domain 안에는 presentation의 진입점을
단순화하는 usecase facade를 둔다.

> 아래 트리는 모노레포 전환(2026-09-12) 전의 단일 앱 배치다. 지금은 `app/` · `core/` ·
> `design_system/` · `l10n/` 이 각각 `apps/trader/lib` · `packages/core` ·
> `packages/design_system` · `packages/l10n` 으로, `features/<x>/` 가
> `packages/features/<x>/lib/src/` 로 옮겨졌다(§1). 계층과 규칙은 그대로다.

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
│   ├── config/app_config.dart   # 환경값
│   ├── di/
│   │   ├── injection.dart       # get_it + injectable 설정
│   │   ├── injection.config.dart        # 생성됨
│   │   └── register_module.dart # 서드파티 인스턴스 등록 (@module)
│   ├── network/
│   │   └── secure_supabase_storage.dart # 세션을 secure storage에 저장
│   ├── data/                    # 공용 data 인프라 (SDK 타입이 여기서 끝난다)
│   │   ├── mapper/supabase_error_mapper.dart  # Supabase 예외 → Failure
│   │   ├── repository/repository_error_handler.dart  # guard: 예외 → Result (규칙 ④)
│   │   └── nickname_match.dart  # 닉네임 중복 확인의 매칭 규칙
│   ├── error/failure.dart       # freezed sealed — 앱 전체의 에러 타입
│   ├── result/result.dart       # Result<T> (성공/실패)
│   ├── pagination/cursor_page.dart  # CursorPage<T> — 커서는 불투명 문자열
│   ├── id/id_generator.dart     # 앱이 먼저 알아야 하는 uuid (Storage 경로용)
│   ├── validation/validators.dart   # 입력 검증 (DB 제약과 값을 맞춘다)
│   ├── media/                   # X3
│   │   ├── image_picker_service.dart     # 선택 + 압축 (1080px / q80,
│   │   │                                 #  Android WebP · 그 밖 JPEG)
│   │   ├── image_storage.dart            # 이미지 저장소 계약 (SDK 타입 없음)
│   │   └── supabase_image_storage.dart   # 위 계약의 Supabase Storage 구현
│   └── extension/date_time_format.dart   # 목록의 날짜 표기
│
├── l10n/                        # gen-l10n 산출물 (ARB + AppLocalizations, 생성됨)
│
├── design_system/               # X4
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── app_colors.dart
│   │   ├── app_spacing.dart
│   │   └── app_radius.dart
│   └── widget/
│       ├── app_button.dart
│       ├── app_avatar.dart
│       ├── app_list_tile.dart
│       ├── app_snack_bar.dart
│       ├── app_placeholder.dart     # 빈 상태·오류 안내
│       ├── app_confirm_dialog.dart  # 되돌리기 어려운 동작의 확인
│       ├── app_overflow_menu.dart   # 더보기 메뉴
│       └── app_count_action.dart    # 아이콘 + 개수 버튼
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
    ├── chat/
    ├── safety/
    └── trade/      (동일 구조 + domain/ledger/ 순수 계산 · presentation/format/ 표기)
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

기준은 **계층별로 다르다.**

| 계층 | 다른 feature 를 참조해도 되나 |
|---|---|
| `domain` | **된다.** feed 가 post 의 `Post` 엔티티를 그대로 쓰는 식 |
| `presentation` | **된다 — 읽어 쓰기만.** 소유자가 명확한 위젯(`PostTile`)과 전역 cubit(`ThemeCubit` · `LanguageCubit`)을 import 한다. 남의 상태를 대신 소유하지는 않는다 |
| `data` | **안 된다.** DTO 가 필요하면 각자 만든다. 공용이 필요하면 `core/data/` 로 올린다 |

위젯을 공유해야 하면 소유자가 명확한 쪽에 두고 import한다. 애매하면
`design_system/widget/`으로 올린다.

`presentation` 을 막지 않는 이유: 설정 화면이 `ThemeCubit` 을, 프로필 화면이
`FeedCubit` 과 `PostTile` 을 쓰는 것이 이 앱의 기본 구성이다. "domain 만"으로
적어 두면 규칙이 코드와 어긋나고, 어긋난 규칙은 판단 기준이 되지 못한다
(2026-08-27 리뷰에서 문구를 실제 기준으로 고쳤다).

**허용된 역방향 참조는 하나뿐이다.** `features/post` 의 `PostTile` 과 게시물 작성
화면이 `features/trade/presentation/widget/trade_result_card.dart` 를 import 해
판 결과 카드를 그린다. trade → post 는 `domain` 만 참조하고, post → trade 는 이
카드(와 그 입력인 `TradeResultSummary` 엔티티)로 제한한다 —
[F10 계획](../apps/trader/docs/features/trade/plan.md).

**post와 feed의 경계가 이 규칙의 기준 예시다.**

| | 소유 |
|---|---|
| `features/post` | `Post` · `PostAuthor` 엔티티, 작성·수정·삭제, 에디터 화면, `PostTile` 위젯 |
| `features/feed` | 목록 조회, 커서 페이지네이션, 무한 스크롤, 피드 화면, `FeedPost` 엔티티 |

feed는 post의 `domain/entity/post.dart`를 그대로 쓴다. 같은 게시물을 두 벌로 표현하지 않기 위해서다. 목록 항목은 `FeedPost = Post + PostAuthor`로 **감싸고**, `Post`에 작성자 필드를 더하지 않는다 — 작성자 프로필이 필요 없는 에디터 화면까지 그 값을 채워야 하기 때문이다.

**DTO는 각자 갖는다.** 피드는 작성자를 조인한 뷰(`posts_with_author`)를 읽고 앞으로 반응·댓글 수 컬럼이 여기에만 더해지지만, 게시물 단건 조회는 그렇지 않다. 지금 모양이 비슷하다고 합치면 그때 되돌려야 한다.

목록 상태는 feed가, 게시물 변경은 post가 소유한다. 화면은 변경 결과를 `FeedCubit.prependPost` / `replacePost` / `removePost`로 목록에 반영한다. 변경할 때마다 전체를 다시 읽으면 스크롤 위치가 사라진다.

---

## 3-2. 홈은 셸이고, 그 위에 화면을 얹는다

로그인 뒤의 기본 화면(`/`)은 하단 내비게이션을 가진 **셸**이다(`features/home`).
탭은 다섯이고 각 탭 본문은 해당 feature 가 소유한 화면을 그대로 쓴다. 첫 탭이
투자인 이유는 [기획 v0.4](../apps/trader/docs/overview.md)에서 모의투자가 이 앱의 주인공이 됐기 때문이다.

| 탭 | 본문 | 소유 |
|---|---|---|
| 투자 | `TradeHomePage` | `features/trade` |
| 홈 | `FeedPage` | `features/feed` |
| 채팅 | `ChatRoomListPage` | `features/chat` |
| 프로필 | `ProfilePage`(세션 사용자) | `features/profile` |
| 설정 | `SettingsPage` | `features/settings` |

- **탭 본문은 `IndexedStack` 으로 살려 둔다.** 탭을 오갈 때 피드의 스크롤 위치와
  커서로 읽어 둔 페이지를 잃지 않기 위해서다. 탭마다 화면을 다시 만들면 목록이
  매번 첫 페이지로 돌아간다.
- **탭 안에서 더 깊이 들어가는 화면은 셸 위에 push 한다** — 게시물 작성·수정,
  댓글, 프로필 편집, 계정 설정. 탭마다 독립된 내비게이션 스택을 두지 않는다.
- go_router 의 `StatefulShellRoute` 를 쓰지 않는다. 탭이 다섯뿐이라 얻는 것보다
  구조가 늘어난다. **탭별 딥링크가 필요해지면 그때 셸 라우트로 옮긴다.**
- **탭 배지가 필요한 상태는 셸이 소유한다.** 채팅의 안읽음 합계가 그렇다 —
  탭 본문이 자기 cubit 을 만들면 그 화면에 있을 때만 숫자를 알게 된다.
  셸이 `ChatRoomListCubit` 을 만들어 내려주고 목록 화면은 읽어 쓰기만 한다.
- 화면 밖으로 나가는 동작(로그아웃)은 목록 화면의 AppBar 가 아니라 설정 탭에 둔다.

경로 상수는 `app/lib/app/router/routes.dart` 한 곳에만 적는다. 인증 게이트(리다이렉트)는
`app_router.dart` 의 `redirect` 하나가 전담한다 — 화면이 각자 "로그인했나?"를 묻지
않는다.

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

DB 쪽 인덱스와 정렬 조건은 [스키마](../apps/trader/docs/schema.md)를 따른다.

---

## 4. bloc 사용 지침

- **이벤트가 여러 개인 화면은 Bloc**, 상태 전환이 단순한 화면은 **Cubit**. 섞어 써도 된다. 로그인 폼에 Bloc은 과하다
- 상태는 freezed **sealed class**로 만든다 — `Initial` / `Loading` / `Loaded` / `Error`. 컴파일러가 분기 누락을 잡아준다
- Bloc은 화면 수명과 함께 산다. `BlocProvider`로 페이지에서 생성하고, DI에는
  **Repository 구현체와 feature별 UseCase facade**만 등록한다 (Bloc을 싱글톤으로 등록하지 말 것)
- 낙관적 업데이트(좋아요, 팔로우)는 Bloc 안에서 처리하고 실패 시 이전 상태로 롤백한다

---

## 5. 멀티패키지(melos)를 쓰지 않는 이유

> 2026-09-12 에 뒤집혔다. 둘째 앱이 생기면서 pub workspace + melos 로 옮겼다(§1).
> 아래는 단일 앱 시절의 판단이고, "앱이 둘 이상 되면 그때 추출한다"는 조건이 그대로
> 실행된 것이다.

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
[setup.md](setup.md) 참조. 스키마의 현재 모습은 [schema.md](../apps/trader/docs/schema.md)를 본다.
