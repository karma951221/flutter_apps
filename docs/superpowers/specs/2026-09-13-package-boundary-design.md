# 패키지 경계 리팩터링 설계 — 둘째 앱이 알려준 6가지를 푼다

> 2026-09-13 · 브랜치 `refactor/package-boundary` · 근거는 [의존 그래프](../../dependencies.md)와
> [통근 앱 설계 §7](2026-09-13-commute-app-design.md#7-리팩터링-후보--이-앱을-만들며-확인된-것)

## 0. 왜 하는가

`apps/commute` 를 만들며 확인한 것: 기반 패키지 셋(`core` · `l10n` · `design_system`)이
"공통"이 아니라 **트레이더 앱의 인프라**였고, feature 12개는 pubspec 에 보이는 것보다
훨씬 질기게 얽혀 있었다(라우팅 · 세션 · 화면 조립). 이 작업은 §7 의 후보 1~6 을 전부
푼다. 6단계 에뮬레이터 확인이 더한 7~9(ICU 복수형 규약 · 배너 공통 위젯 · "얹은 화면이
걷히면 새로고침" 패턴)는 경계가 아니라 공통 위젯·규약의 빈자리라 **이 작업 밖**이다 —
9번은 #2 의 Navigator 가 `Future` 를 돌려주는 설계의 근거로만 쓴다. 기능 변화는 없다 —
두 앱의 동작은 리팩터링 전과 같아야 한다.

## 1. 목표 구조

```
packages/
  core/            Result · Failure · FailureCode(열린 타입) · 페이지네이션 · 검증 · 확장 ·
                   get_it · appRouteObserver · SharedPreferences·Uuid 등록          (의존 없음)
  core_media/      ImagePickerService · ImageStorage 인터페이스 · 압축                (→ core)
  core_supabase/   SupabaseClient·FlutterSecureStorage 등록 · SupabaseErrorMapper(규칙 등록형) ·
                   RepositoryErrorHandler · SecureSupabaseStorage · SupabaseImageStorage
                                                                                    (→ core_media, core)
  core_session/    AppUser · SessionCubit(읽기 전용 투영)                           (→ 없음, flutter_bloc)
  design_system/   자체 ARB(DesignSystemLocalizations) — l10n 의존 제거             (→ core)
  l10n/            common · validation · 공통 failure 문자열 + FailureMessageRegistry (→ core)
  features/<x>/    자체 ARB(`<X>Localizations`) · 자체 FailureCode 상수 · 자체 mapper 규칙 ·
                   `<X>Navigator` · `<X>Moderation` 인터페이스
apps/trader/       Routes · go_router · Navigator/Moderation 구현체 · ProfilePage 조립 ·
                   mapper 규칙과 failure 문구 등록 · localization delegate 조립
apps/commute/      변화 최소 — delegate 조립과 core 의존만 바뀐다
```

의존 방향(단방향, 순환 금지):

```
apps → features → { core_session, core_supabase, core_media, design_system, l10n } → core
```

feature 간 의존은 **도메인 타입을 공유하는 쌍만** 남긴다:
`post → reaction, trade` · `comment → post, reaction` · `feed → post, reaction, trade` ·
`profile → follow` · `settings → auth, preferences` · `chat → (없음)`.
`auth` 는 `settings` 만 의존한다. `safety` 는 어떤 feature 도 의존하지 않는다.

## 2. 후보별 설계

### #1 core 분리 (→ core · core_media · core_supabase)

이동 목록:

| 지금 `core/src/` | 목적지 |
|---|---|
| `di/register_module.dart` 의 `secureStorage` · `supabaseClient` | `core_supabase/src/di/register_module.dart` (`@module`) |
| `di/register_module.dart` 의 `uuid` · `sharedPreferences` | `core` 에 남는다 |
| `data/mapper/supabase_error_mapper.dart` | `core_supabase/src/mapper/` |
| `data/repository/repository_error_handler.dart` | `core_supabase/src/repository/` |
| `network/secure_supabase_storage.dart` | `core_supabase/src/session/` |
| `media/image_picker_service.dart` · `media/image_storage.dart` | `core_media/src/` |
| `media/supabase_image_storage.dart` | `core_supabase/src/storage/` |
| 나머지 전부 | `core` 에 남는다 |

- `core/pubspec.yaml` 에서 `supabase_flutter` · `flutter_secure_storage` · `image_picker` ·
  `flutter_image_compress` 를 뺀다. `injectable` · `get_it` · `shared_preferences` · `uuid` ·
  `intl` · `freezed_annotation` 은 남는다
- 각 새 패키지는 자체 `@InjectableInit.microPackage` 를 가진다 (`CoreMediaPackageModule`,
  `CoreSupabasePackageModule`). `apps/trader/di/injection.dart` 가 셋을 모두 등록하고
  `apps/commute` 는 `CorePackageModule` 만 등록한다
- feature 의 data 계층은 `package:core_supabase/core_supabase.dart` 를 import 한다
  (`RepositoryErrorHandler` · `SupabaseClient`). `feature_commute` 는 import 하지 않는다
- 검증: `apps/commute/test/convention/package_boundary_test.dart` 에 "`core/pubspec.yaml` 에
  `supabase_flutter` · `image_picker` · `flutter_image_compress` · `flutter_secure_storage` 가
  없다" · "`feature_commute` 가 `core_supabase` · `core_media` 를 의존하지 않는다" 추가

### #5 세션 읽기 모델 (→ core_session)

- `AppUser` 를 `feature_auth/domain/entity` 에서 `core_session/src/app_user.dart` 로 옮긴다.
  `feature_auth` 는 `core_session` 을 의존하고 같은 타입을 쓴다 (re-export 하지 않는다)
- `SessionCubit extends Cubit<AppUser?>` — 메서드는 `update(AppUser? user)` 하나.
  **진실의 원천은 `AuthBloc` 그대로**고 `SessionCubit` 은 투영이다. `apps/trader/app.dart` 가
  `BlocListener<AuthBloc, AuthState>` 로 `AuthAuthenticated(user)` → `update(user)`,
  그 외 → `update(null)` 을 흘려 넣고 `MultiBlocProvider` 에 둘 다 올린다
- 소비자 9파일 중 `settings` 를 제외한 8곳(chat 3 · comment 1 · feed 1 · profile 2 · trade 1)은
  `context.watch<AuthBloc>().state` 분기를 `context.watch<SessionCubit>().state` (`AppUser?`)
  로 바꾼다. `edit_profile_page` 의 `userRefreshRequested` 는 auth 이벤트라 이 단계에서는
  profile 이 auth 를 계속 의존한다. #2 에서 푼다 — `EditProfilePage` 는 저장 성공 시 바뀐
  `Profile` 을 `Navigator.pop` 결과로 돌려주고(setup 모드는 `ProfileNavigator.openHome`),
  이동을 시작한 쪽의 앱 Navigator 구현(`SettingsNavigator.openProfileEdit` · ProfilePage)이
  결과를 받아 `AuthBloc` 에 `userRefreshRequested` 를 넣는다. profile 의 `feature_auth`
  제거는 #6 에서 `ProfilePage` 가 앱으로 올라간 뒤 완료된다
- pubspec: chat · comment · feed · trade 에서 `feature_auth` 제거, 다섯 feature 에 `core_session` 추가
- 테스트: 위 8곳의 위젯 테스트가 `AuthBloc` mock 대신 `SessionCubit` 을 제공한다.
  `core_session/test/session_cubit_test.dart` 는 `bloc_test` 로 `update` 만 확인한다

### #2 내비게이션 결합 해제 (→ feature별 Navigator + 앱 구현)

- `core/src/navigation/routes.dart` 를 `apps/trader/lib/app/router/routes.dart` 로 옮긴다.
  `appRouteObserver` 는 go_router 와 무관하므로 `core` 에 남는다
- feature 마다 `lib/src/presentation/navigation/<x>_navigator.dart` 에 **그 feature 가
  바깥으로 나가는 이동만** 추상 클래스로 선언한다. 반환값이 있는 이동은 그대로 `Future` 로
  돌려받는다:

  ```dart
  abstract class FeedNavigator {
    Future<Post?> openPostEditor(BuildContext context, Post post);
    Future<int?> openComments(BuildContext context, String postId, int commentCount);
    void openProfile(BuildContext context, String userId);
    void openTradeResult(BuildContext context, String sessionId);
  }
  ```

  선언 대상(지금 `context.push/go` 가 있는 곳): auth(signUp · passwordReset · explore),
  chat(explore → room), feed(위), follow(profile), profile(edit · followers · followings ·
  tradeResult · home), settings(profileEdit · account · blocked · changePassword),
  trade(share → post editor)
- 구현은 `apps/trader/lib/app/router/navigators/` 에 `@LazySingleton(as: FeedNavigator)` 로
  두고 go_router 로 이동한다. feature 는 `getIt<FeedNavigator>()` 로 받는다 — 페이지 생성자에
  넣지 않는다(테스트는 `getIt.registerSingleton<FeedNavigator>(mock)`)
- feature 안의 `context.pop(...)` 은 `Navigator.of(context).pop(...)` 으로 바꾼다.
  라우트 파라미터(`:postId` 등)는 이미 앱 라우터가 읽어 생성자로 넘기고 있으므로 변화 없다
- pubspec: feature 12개 전부에서 `go_router` 제거. 검증: `package_boundary_test` 에
  "`packages/features/*/pubspec.yaml` 어디에도 `go_router` 가 없다" · "`packages/features/*/lib`
  에 `Routes.` 문자열이 없다" 추가
- `apps/commute` 는 이미 콜백 방식이라 손대지 않는다

### #3 l10n 분리 (→ 패키지별 ARB)

- feature 12개 + `design_system` 이 각각 `l10n.yaml` + `lib/l10n/{<x>_ko,en,ja}.arb` 를 갖는다.
  템플릿은 ko, `output-class` 는 `ChatLocalizations` · `DesignSystemLocalizations` 식,
  `synthetic-package: false`, 생성 파일은 커밋한다(지금 `l10n` 과 같은 방식)
- 키 이동 기준은 접두어다: `chat*` → chat, `trade*` → trade, `commute*` → commute,
  `avatar*` → design_system, `feedEndOfList` · `commonCancel` · `commonMoreActions` 는
  design_system 이 자체 키로 복제하고 `l10n` 에서는 **삭제하지 않는다**(feature 도 쓴다).
  `home*` · `guest*` · `explore*` 처럼 앱 셸 문자열은 `apps/trader/lib/l10n/` 의
  `TraderLocalizations` 로 간다. `common*` · `validation*` · 공통 `failure*`(§#4 의 공통 코드에
  대응하는 것) 만 `l10n` 에 남는다
- 접두어가 소유자와 다른 키(예: `feed*` 인데 profile 만 쓰는 키)는 **쓰는 쪽**으로 옮긴다.
  두 feature 가 함께 쓰는 키는 각자 복제한다 — 문자열 중복이 패키지 결합보다 싸다
- 호출부: `AppLocalizations.of(context).chatXxx` → `ChatLocalizations.of(context).xxx`.
  키 이름에서 접두어를 뗀다(`chatRoomTitle` → `roomTitle`). `common*` 은 그대로
- 앱은 delegate 를 모아 등록한다. `apps/trader/lib/app/localizations.dart` 에
  `traderLocalizationsDelegates` (`AppLocalizations` + `DesignSystemLocalizations` +
  feature 12개 + `TraderLocalizations`) 를 두고 `MaterialApp.localizationsDelegates` 에 준다.
  `apps/commute` 는 `AppLocalizations` + `DesignSystemLocalizations` + `CommuteLocalizations`
- `design_system/pubspec.yaml` 에서 `l10n` 제거
- 테스트: 각 feature 의 위젯 테스트는 `AppLocalizations.localizationsDelegates` 대신
  `<X>Localizations.localizationsDelegates` 와 `DesignSystemLocalizations.delegate` 를
  함께 준다(feature 마다 `test/helper/localizations.dart` 하나). `apps/trader/test/convention/`
  의 `arb_description_convention_test` 는 저장소 안의 모든 `*_ko.arb` 를 훑도록 바꾸고,
  ko/en/ja 키 집합 일치 검사도 ARB 세트마다 돈다
- `melos.yaml` 의 `l10n` 스크립트는 `l10n.yaml` 이 있는 모든 패키지에서 `flutter gen-l10n`
  을 돌린다

### #4 FailureCode 를 feature 로

- `FailureCode` 를 enum 에서 **값 클래스**로 바꾼다:

  ```dart
  final class FailureCode {
    final String key;             // 'post.contentLength' — 디버그 표기와 registry 키
    const FailureCode(this.key);
    // == · hashCode 는 key 기준
  }
  ```

  `Failure.failureCode` 필드 이름과 타입 이름은 유지한다 — 호출부 `failure.failureCode`
  는 바뀌지 않는다
- 상수 소유:
  - `core` — `CommonFailureCodes`: networkUnavailable · invalidData · duplicateValue ·
    constraintViolation · referencedTargetMissing · forbiddenOrDeleted · targetNotFound ·
    rateLimited · authenticationRequired · operationInProgress
  - `core_supabase` — `SupabaseAuthFailureCodes`: invalidCredentials · signInFailed ·
    signUpFailed · emailAlreadyRegistered · weakPassword · samePassword · otpExpired
    (Supabase `AuthException` 코드에서 나오므로 feature 가 아니라 인프라 소유)
  - 나머지는 각 feature 의 `lib/src/domain/error/<x>_failure_codes.dart`
    (`PostFailureCodes.contentLength` …). 열거값 → 소유자 매핑은 이름 접두어를 따른다
- `SupabaseErrorMapper` 는 **규칙 등록형**이 된다:

  ```dart
  final class SupabaseErrorRule {
    const SupabaseErrorRule.constraint(String name, Failure Function() failure);  // 제약·인덱스 이름 포함
    const SupabaseErrorRule.message(String text, Failure Function() failure);     // 트리거 raise 문구 일치
  }
  abstract final class SupabaseErrorMapper {
    static void registerRules(Iterable<SupabaseErrorRule> rules);
    static void resetRules();   // 테스트용
    static Failure map(Object error);
  }
  ```

  공통 코드(23505 · 23514 · 23503 · 42501 · PGRST116 · Auth 코드 · 네트워크)는 mapper 가
  직접 안다. feature 전용 제약 이름과 트리거 문구는 각 feature 의
  `lib/src/data/error/<x>_error_rules.dart` 가 `const postErrorRules = [...]` 로 선언하고,
  `apps/trader/lib/di/injection.dart` 가 `configureDependencies()` 안에서 모두 등록한다.
  feature 의 repository 테스트는 `setUp` 에서 자기 규칙을 등록한다
- 문구 번역도 같은 모양이다. `l10n` 에 `FailureMessageRegistry` 를 둔다:

  ```dart
  typedef FailureMessageBuilder = String Function(BuildContext context);
  abstract final class FailureMessageRegistry {
    static void register(Map<FailureCode, FailureMessageBuilder> messages);
    static String? resolve(FailureCode code, BuildContext context);
  }
  ```

  `Failure.localizedMessage(context)` 는 registry → `message` → 종류별 기본 문구 순으로
  떨어진다(지금과 같은 3단계). 각 feature 는 `lib/src/presentation/error/<x>_failure_messages.dart`
  에 `Map<FailureCode, FailureMessageBuilder>` 를 두고 자기 `<X>Localizations` 로 번역한다.
  앱이 `configureDependencies()` 에서 전부 등록한다. 공통 · Supabase auth 코드는 `l10n` 이
  직접 등록한다(`registerCommonFailureMessages()`)
- 검증: `apps/trader/test/convention/trigger_message_mapping_test.dart` 는 feature 12개의
  규칙을 전부 모아 "마이그레이션의 모든 한국어 raise 문구가 어떤 규칙에든 있다" 를 유지한다.
  새 컨벤션 테스트 하나 — "선언된 모든 `FailureCode` 상수는 registry 에 문구가 있다"
  (feature 의 상수 파일과 문구 파일을 함께 import 해 집합을 비교)

### #6 화면 조립을 앱으로 (→ ProfilePage 이동 + Moderation 슬롯)

**ProfilePage.** `feature_profile/presentation/page/profile_page.dart` 를
`apps/trader/lib/screens/profile/profile_page.dart` 로 옮긴다. `feature_profile` 에 남는 것:
`ProfileCubit` · `ProfileHeader` 등 프로필 자체 위젯 · `EditProfilePage` · `FollowRelation`
을 품는 `ProfileDetails`. 옮긴 뒤 `feature_profile` 의 feature 의존은 `follow` 하나다.
`_FollowStats` · `_FollowButton` 은 follow 가 소유해야 할 위젯이므로 `feature_follow`
로 옮긴다(`FollowStats` · `FollowButton` 공개).

**Moderation 슬롯.** feed · comment · chat 이 `ReportSheet` · `ReportTarget` ·
`BlockActionCubit` 을 직접 쓰는 것을 인터페이스로 바꾼다. Navigator 와 같은 방식이다:

```dart
abstract class FeedModeration {
  /// 신고 시트를 열고 접수됐는지 돌려준다. 스낵바는 호출한 쪽이 띄운다.
  Future<bool> reportPost(BuildContext context, String postId);
  /// 확인 다이얼로그 → 차단. 성공 여부를 돌려주고 목록 반영은 호출한 쪽이 한다.
  Future<bool> blockUser(BuildContext context, {required String userId, required String nickname});
}
abstract class CommentModeration { Future<bool> reportComment(BuildContext, String commentId); }
abstract class ChatModeration  { Future<bool> reportMessage(BuildContext, String messageId); }
```

구현은 `apps/trader/lib/app/moderation/` 에 `@LazySingleton(as: FeedModeration)` 등으로
두고 `feature_safety` 를 쓴다. `PostTileActions.report` 는 `FeedModeration` 을 통해 간다.
pubspec: feed · comment · chat 에서 `feature_safety` 제거.

**reaction 은 남긴다.** `ReactionSummary` · `ReactionTarget` · `ReactionType` 은 `Post` ·
`PostComment` 엔티티와 cubit 의 낙관적 갱신에 들어 있는 도메인 타입이고, `ReactionBar` 는
그 타입을 그리는 위젯이다. 슬롯으로 빼면 엔티티에서 타입을 지워야 하는데 그건 기능을
바꾸는 일이다. `post → reaction` · `comment → reaction` · `feed → reaction` 은
[의존 그래프 §3-②](../../dependencies.md) 의 "진짜 공유 도메인 타입"으로 남긴다.
`post → trade`(`TradeResultSummary`) 도 같은 이유로 남긴다.

## 3. 순서와 검증

한 브랜치 `refactor/package-boundary` 에서 아래 순서로 간다. 후보 하나가 커밋 1~3개다.

| 순서 | 후보 | 먼저 와야 하는 이유 |
|---|---|---|
| 1 | #1 core 분리 | 다른 것과 독립. 가장 기계적 |
| 2 | #5 세션 | 독립. #6 의 전제(profile 의 auth 의존 제거) |
| 3 | #2 내비게이션 | 독립. #6 의 전제(ProfilePage 이동 시 Navigator 가 있어야) |
| 4 | #3 l10n 분리 | #4 의 전제(feature 문구를 feature ARB 에 두려면) |
| 5 | #4 FailureCode | #3 뒤 |
| 6 | #6 조립 | #2 · #5 뒤 |
| 7 | 문서 | `architecture.md` · `dependencies.md` 다시 그리기 · `status.md`. 모노레포 전환 때 못 고친 `app/` 경로(`CLAUDE.md` · `testing/README.md` · `testing/conventions.md` · `testing/e2e.md`)도 이때 `apps/trader` · `packages/` 로 바로잡는다 |

단계마다 통과시킬 것:

```bash
melos run analyze && melos run test
(cd apps/trader && flutter build apk --debug)
(cd apps/commute && flutter build apk --debug)
```

`package_boundary_test` 는 단계마다 불변식을 하나씩 더한다(§2 각 항목의 "검증").
마지막에 에뮬레이터로 trader 의 주요 흐름(로그인 → 피드 → 프로필 → 채팅 → 판 → 공유)과
commute 의 4 시나리오를 한 번 훑는다. Patrol E2E 는 로컬 Supabase 가 떠 있으면 돌린다.

## 4. 하지 않는 것

- 기능 · 화면 · 스키마 변경. `supabase/` 는 손대지 않는다
- reaction · trade 도메인 타입 의존 제거 (§2-#6)
- `AuthBloc` 재설계 — `SessionCubit` 은 투영일 뿐이다
- `apps/commute` 의 콜백 방식을 Navigator 로 바꾸는 것 (화면 2개라 그대로 둔다)
- ARB 문자열의 번역 품질 손질 — 키만 옮긴다

## 5. 완료 조건

- §1 의 의존 방향이 `package_boundary_test` 로 강제된다: feature 에 `go_router` ·
  `supabase_flutter` 없음, `feature_auth` 는 settings 만, `feature_safety` 는 아무도,
  `core` 에 Supabase · 이미지 · secure storage 없음, `design_system` 에 `l10n` 없음
- `profile` 의 전이 의존이 8 → 1(follow)
- `dependencies.md` §6 스크립트 결과가 §1 의 그래프와 같다
- 두 앱이 빌드되고 에뮬레이터 확인을 통과한다. 테스트 수는 줄지 않는다
