# 전체 기획 · UX 반영 코드 리뷰

검토일: 2026-09-06

기준: `main`의 `fcc2117..9471277` 변경과 현재 코드·기획 문서

범위: 가입/온보딩, 게스트 피드, 프로필 완성도, 게시물 작성, 탈퇴 확인, 관련 테스트·문서

별도 브랜치 `refactor/melos-packages-wanderer`는 현재 `main`에 합쳐지지 않은 설계 문서만
있어 이번 코드 리뷰 범위에서 제외했다.

## 요약

| # | 등급 | 발견 | 대표 위치 | 상태 |
|---|---|---|---|---|
| 1 | P1 | 프로필 꾸미기 요청 중 뒤로가면 닫힌 Cubit이 응답을 emit한다 | `edit_profile_page.dart:193` | 고침 |
| 2 | P2 | 사진 가로 스크롤도 피드 다음 페이지 요청을 일으킨다 | `guest_feed_page.dart:76` | 고침 |
| 3 | P2 | 가입 닉네임의 디바운스 중복 확인이 계획에만 있다 | `docs/features/auth/plan.md:37` | 고침 |
| 4 | P2 | 기획 단일 기준이 현재 제품·스키마와 여러 곳에서 충돌한다 | `docs/overview.md:44` | 고침 |

위치는 리뷰 시점(수정 전)의 것이다. 조치 내용은 맨 아래에 있다.

## 발견 사항

### [P1] 1. 프로필 꾸미기 요청 중 뒤로가면 닫힌 Cubit이 응답을 emit한다

**위치** `app/lib/features/profile/presentation/page/edit_profile_page.dart:193-197`,
`app/lib/features/profile/presentation/cubit/profile_cubit.dart:31-40,90-100`

setup 모드의 `PopScope`는 거부된 모든 pop을 즉시 `context.go(Routes.home)`으로 바꾼다.
따라서 첫 프로필 조회 중 시스템 뒤로가기를 누르거나, 저장 중 시스템 뒤로가기를 누르면
`BlocProvider`가 `ProfileCubit`을 먼저 닫는다. 그러나 `load()`와 `save()`는 `await` 뒤에
`isClosed` 확인 없이 `emit`한다. 응답이 도착하면 bloc 9.2가
`StateError('Cannot emit new states after calling close')`를 던진다. 저장 요청은 화면을
떠난 뒤에도 계속돼 성공 여부를 사용자에게 알릴 수도 없다.

현재 시스템 뒤로가기 테스트는 `pumpAndSettle()`로 조회를 끝낸 다음 pop하므로 이 경계를
검증하지 않는다.

**제안** 저장 중에는 setup pop을 홈 이동으로 바꾸지 말고 막거나 확인을 받는다. 아울러
`ProfileCubit.load/save`의 모든 비동기 경계 뒤에 `isClosed` 가드를 두고, `Completer`로
요청을 보류한 상태에서 `handlePopRoute()` 후 응답을 완료하는 회귀 테스트를 추가한다.

### [P2] 2. 사진 가로 스크롤도 피드 다음 페이지 요청을 일으킨다

**위치** `app/lib/features/feed/presentation/page/guest_feed_page.dart:76-84`,
`app/lib/features/feed/presentation/page/feed_page.dart:204-211`,
`app/lib/features/profile/presentation/page/profile_page.dart:215-227`,
`app/lib/features/post/presentation/widget/post_tile.dart:225-239`

세 화면의 `NotificationListener<ScrollNotification>`는 축이나 notification depth를 보지
않고 `extentAfter < 240`만 검사한다. 여러 장의 사진은 `PostTile` 안에서 별도 가로
`ListView`로 그려지고, 그 스크롤 알림도 바깥 listener까지 버블링한다. 사용자가 화면
상단에서 사진 캐러셀의 끝으로 가로 스크롤하면 세로 목록 끝에 오지 않았는데도
`FeedCubit.loadMore()`가 실행된다. 반복하면 읽지 않을 다음 페이지를 계속 당겨 올 수 있다.

**제안** 세 listener가 세로 최상위 목록 알림만 처리하도록
`notification.metrics.axis == Axis.vertical`과 적절한 `depth` 조건을 공통화한다. 다중
이미지 게시물을 가로 드래그한 뒤 feed usecase 호출 수가 늘지 않는 위젯 테스트를 둔다.

### [P2] 3. 가입 닉네임의 디바운스 중복 확인이 계획에만 있다

**위치** `docs/features/auth/plan.md:37`,
`app/lib/features/auth/presentation/page/sign_up_page.dart:141-153`,
`app/lib/features/auth/domain/usecase/scenario/sign_up_scenario.dart:18-31`

auth 계획은 회원가입 닉네임 중복을 "디바운스 사전 확인 + 가입 시 DB 제약"으로
정의한다. 실제 가입 화면은 길이 검증과 이메일 기반 제안만 하며, 중복 확인 상태나
디바운스 호출이 없다. `isNicknameAvailable`은 제출 후 `SignUpScenario` 안에서 한 번
호출되므로 사용자는 가입 버튼을 누른 뒤에야 중복을 알 수 있다. 테스트 범위도 scenario의
제출 시 확인만 다루고 화면 계약은 검증하지 않는다.

**제안** profile 편집의 `NicknameCheck` 패턴을 가입 화면에 연결해 확인 중/가능/중복을
표시하거나, 제출 시 확인만 의도한 것이라면 plan에서 "디바운스" 약속을 제거해 구현과
테스트 범위를 맞춘다.

### [P2] 4. 기획 단일 기준이 현재 제품·스키마와 여러 곳에서 충돌한다

**위치** `docs/overview.md:5,44-46,244-249,458-470`

문서 허브는 `overview.md`를 제품 목표·범위·결정 근거의 단일 기준으로 지정하지만,
현재 문서는 8월 22일 v0.2 상태에 머물러 있다.

- 46줄은 1:1 채팅/DM과 다국어를 v1 범위 밖이라고 쓰지만 둘 다 현재 완료 상태다.
- 244줄은 게시물 이미지 경로를 `{user_id}/{post_id}/...`로 정의하지만 구현과
  `schema.md`의 계약은 `{user_id}/{uuid}/{순서}`다.
- 247~249줄은 이미지 순서 드래그, 업로드 진행률/재시도, 게시물 상세·캐러셀을 앱 개발
  범위로 적지만 현재 구현하지 않았고 `status.md`는 F3를 완료로 닫았다.
- 464줄은 1:1 DM을 4단계 미래 범위로 두고, 바로 아래 설명도 아직 DM이 붙기 전처럼
  서술한다. 현재는 3.6단계 완료다.

이 상태에서는 새 기획이나 리팩터링이 overview를 기준으로 삼을 때 이미 폐기된 Storage
경로나 끝난 기능을 다시 설계하게 된다.

**제안** 현재 결정을 overview에 반영하고, 구현하지 않기로 한 F3 항목은 명시적인 범위
밖/후속 항목으로 옮긴다. 진행 체크는 기존 규칙대로 `status.md`에만 남긴다. 함께 보이는
작은 드리프트(`profile/plan.md`의 중복 문장과 프로필 로그아웃 표기,
`settings/plan.md`의 세 번째 탭·무상태 표기)도 같은 정리에서 맞춘다.

## 확인 결과

- `cd app && flutter analyze` — 통과
- `cd app && flutter test` — 통과 (616 tests)
- `cd app && flutter test test/convention` — 통과 (4 tests)
- `python3 supabase/tests/guest_read_check.py` — 통과 (6/6)
- `python3 supabase/tests/account_summary_check.py` — 통과 (3/3)

정적 분석·단위 테스트와 새 Supabase 경계 검사는 모두 통과했다. 1번은 비동기 요청이
끝나기 전에 화면을 닫는 수명 경계, 2번은 중첩 스크롤 알림이라 현재 테스트 범위 밖이다.

## 조치 내용 — 2026-09-06

1. **닫힌 Cubit emit** — `ProfileCubit.load/save` 가 `await` 뒤에 `isClosed` 를 확인한다.
   setup 모드 `PopScope` 는 저장 중이면 홈으로 보내지 않고 pop 을 그대로 막는다
   ("계속" 이 로딩 상태라 저장 중임이 보이고, 끝나면 listener 가 홈으로 보낸다).
   `Completer` 로 응답을 보류한 채 `close()` / `handlePopRoute()` 후 완료하는 회귀
   테스트 4건(cubit 2 · 화면 2). 수정 전에는 넷 다 `Cannot emit new states after
   calling close` 로 실패했다.
2. **가로 스크롤의 다음 페이지 요청** — `FeedLoadMoreListener`
   (`features/feed/presentation/widget/`)가 `depth == 0 && axis == vertical` 인 알림만
   본다. 세 화면이 인라인 listener 대신 이 위젯을 쓰고, `canLoadMore · isLoadingMore`
   판단은 화면마다 상태를 읽는 시점이 달라 콜백 쪽에 남겼다. 위젯 테스트 3건과
   게스트 피드 회귀 테스트(8장 사진 게시물을 가로로 끝까지 끌어도 `getFeedPosts` 1회).
   수정 전에는 4회였다.
3. **가입 닉네임 디바운스 확인** — 계획대로 구현했다. `NicknameCheck` 와 400ms 상수를
   `core/validation/nickname_check.dart` 로 올려 auth · profile 이 공유한다.
   `AuthUseCase.isNicknameAvailable` + `CheckNicknameAvailabilityScenario` 추가,
   `SignUpCubit` 은 `SignUpState(submit, nicknameCheck)` 두 축을 갖는다(늦게 온 확인
   결과가 제출 중 상태를 지우지 않게). `AuthTextField` 에 `helperText · helperColor ·
   suffixIcon` 을 더해 확인 중/가능/중복을 표시하고, 이메일 제안값도 같이 확인한다.
   문구는 프로필 편집의 l10n 키를 그대로 쓴다. E2E 셀렉터 `signUp.nickname` 유지.
4. **기획 문서 드리프트** — `overview.md` 를 v0.3 으로 올렸다. 채팅(F9) · DM · 다국어를
   범위 안으로, Storage 경로를 `{user_id}/{uuid}/{순서}` 로, F3 의 드래그 순서 ·
   진행률/재시도 · 상세/캐러셀은 "범위 밖 / 후속" 으로 옮겼고 로드맵에 3.5 · 3.6 단계를
   적었다. `profile/plan.md` 중복 문장과 로그아웃 표기, `settings/plan.md` 의 탭 순서와
   `AccountSettingsPage` 상태 표기, `schema.md` 의 "앞으로 추가될 `follows`" 문장도 맞췄다.

남긴 것: overview 에 F9 절이 없다(포인터만 둠), settings · preferences 의 F 번호,
§4 의 drift 도입 언급은 결정이 필요해 손대지 않았다.

재확인: `flutter analyze` 무결함 · `flutter test` 637 통과 · `flutter test test/convention`
4 통과.

