# 진행 현황

> [문서 허브](README.md) · [기획](overview.md) · [아키텍처](architecture.md) · [테스트 가이드](testing/README.md)

**진행 현황의 단일 기준은 이 문서다.** 단계 정의와 각 단계의 의미는
[기획서 §8](overview.md)에, 구조·규칙은 [아키텍처](architecture.md)에 있다.
이 문서는 "지금 어디까지 왔고 다음이 무엇인가"만 다루며, 자주 갱신된다.

## 단계 요약

| 단계 | 범위 | 상태 |
|------|------|------|
| 0 | 프로젝트 · 로컬 Supabase · DI · design system | **완료** |
| 1 | F1 auth · F2 profile · F3 post · F4 전체 피드 | **완료** |
| 2 | F5 reaction · F6 comment · F7 safety | **완료** |
| 3 | F8 follow · F4 팔로잉 피드 | **완료** |
| 3.5 | F9 chat (오픈 채팅) | **완료** |
| 3.6 | F9-DM (1:1 채팅) | **완료** |
| 4 | (v1.1) 재설정 SMTP · 구글 로그인 · OTP · 푸시 · 채팅 | 대기 |
| 5 | F10 trade (모의투자) — 5.1 시세 · 5.2 스키마 완료, 5.3 앱 · 5.4 공유 진행 중 | **진행 중** |


## 0단계 — 완료

- [x] Docker Desktop · Supabase CLI 확인
- [x] `flutter create --org com.karma --project-name daylog app`
- [x] 의존성 추가 ([아키텍처 §6](architecture.md))
- [x] `supabase init` → `supabase start` → 전 서비스 기동
- [x] 첫 마이그레이션 `20260820145331_init_profiles.sql` — profiles + 트리거 + RLS + GRANT
- [x] `bootstrap.dart` — Supabase 초기화, 세션을 Keychain 에 저장
- [x] `injection.dart` — get_it + injectable, 코드 생성 확인
- [x] `design_system/theme` 뼈대
- [x] 앱 → 로컬 Supabase 왕복 호출 성공 (Android 에뮬레이터)
- [x] REST 부정 테스트 — 타인 프로필 수정 차단, 닉네임 제약 동작 확인

**미완**: iOS 빌드 (Xcode 미설치 — [setup.md](setup.md) §4)

## 1단계 — 완료

- [x] **F1 auth** — 회원가입 · 로그인 · 인증 상태 유지 · 비밀번호 재설정 · 로그아웃
      ([계획](features/auth/plan.md) · [기록](features/auth/history.md))
- [x] 스키마 정합성 — `feed_posts` → `posts` rename, 소프트 삭제(`deleted_at` + RLS 강제),
      커서용 부분 인덱스 (`20260822120000_rename_posts_and_soft_delete.sql`)
- [x] 앱 feature 분리 — 게시물 CRUD는 `features/post`, 목록은 `features/feed`
- [x] 커서 페이지네이션 — `range`/offset 제거, 불투명 커서 (`feed/data/cursor/`)
- [x] **F2 profile** — 아바타 업로드·타인 프로필·프로필별 커서 목록
      ([계획](features/profile/plan.md) · [기록](features/profile/history.md))
- [x] **F3 post** — 텍스트 CRUD·소프트 삭제·이미지 첨부 (`post_images` · Storage · X3 media)
      ([계획](features/post/plan.md) · [기록](features/post/history.md))
- [x] **F4 feed** — 커서 페이지네이션 · 무한 스크롤 · 작성자 프로필 조인
      (`posts_with_author` 뷰). 팔로잉 피드는 3단계 범위다
      ([계획](features/feed/plan.md) · [기록](features/feed/history.md))

## 2단계 — 완료

- [x] **F5 reaction** — 게시물·댓글 공용 감정표현. 대상별 테이블 + `ReactionTarget` 으로
      일반화, 집계는 목록 뷰의 `jsonb`, 낙관적 업데이트는 목록을 소유한 쪽이 한다
      ([계획](features/reaction/plan.md) · [기록](features/reaction/history.md))
- [x] **F6 comment** — 2단 댓글. 제한은 트리거, 조회는 `post_comments_visible`
      (`security_invoker = off` 예외), 오래된 순 커서, 댓글 화면과 답글 지연 로딩
      ([계획](features/comment/plan.md) · [기록](features/comment/history.md))
- [x] **F7 safety (신고)** — 폴리모픽 `reports` 한 테이블, FK 대신 대상 검증 트리거,
      게시물·댓글·프로필 세 진입점과 사유 시트
      ([계획](features/safety/plan.md) · [기록](features/safety/history.md))
- [x] **F7 safety (차단)** — `blocks` 테이블 + `is_blocked_with()` 판정 함수로
      `posts` · `post_comments` 조회 정책과 `post_comments_visible` 뷰를 양방향으로
      막는다. 사용자 A · B 의 실제 JWT로 12개 완료 조건을 REST 로 확인했다.
      프로필 AppBar의 차단/차단 해제 메뉴까지 완료했다 — 게시물 메뉴의 차단 진입점과
      차단 목록 화면을 포함한다
      ([계획](features/safety/plan-block.md) · [기록](features/safety/history.md) ·
      [테스트](testing/features/safety.md))

## UI — 2026-08-24

- [x] 인증 화면 개편 — 공통 뼈대(`AuthScaffold` · `AuthHeader`), 비밀번호 토글,
      제출 중 잠금 ([기록](features/auth/history.md))
- [x] 홈 셸과 하단 내비게이션(홈 · 프로필 · 설정) — 탭 본문은 `IndexedStack` 으로
      살려 둔다 ([아키텍처 3-2](architecture.md))
- [x] 피드 조회 화면 — 빈 상태·실패 안내, 목록 끝 꼬리표 ([기록](features/feed/history.md))
- [x] 게시물 작성·수정 화면 — 글자 수, 사진 최대 장수, 나가기 확인
      ([기록](features/post/history.md))
- [x] 설정 — 프로필 편집 진입 · 계정 설정(비밀번호 변경) · 로그아웃
      ([계획](features/settings/plan.md))
- [x] **회원 탈퇴** — `delete_account()` cascade + 앱의 Storage best-effort 정리
      ([계획](features/settings/plan.md) · [스키마 §3](schema.md))
- [x] **다크모드** — 시스템·라이트·다크 3상태, `shared_preferences` 저장,
      `ThemeCubit` 전역 제공, 설정 → 화면 테마
      ([계획](features/preferences/plan-theme.md) · [기록](features/preferences/history.md))

## 다국어 — 완료

시스템 · 한국어 · 영어 · 일본어를 지원한다. 화면 문자열뿐 아니라 폼 검증,
앱이 식별할 수 있는 오류와 날짜 표기까지 선택 언어를 따른다
([계획](features/preferences/plan-language.md) ·
[기록](features/preferences/history.md) ·
[테스트](testing/features/preferences.md)).

- [x] feature 개명 — `PreferencesUseCase` 로 facade 통합, 저장소는 관심사별 유지
- [x] gen-l10n 기반 — `l10n.yaml`, ARB 3개(template `ko`), `AppLocalizations`
- [x] `MaterialApp` 배선 — `locale`(시스템은 `null`) · delegates ·
      미지원 기기 언어는 `localeResolutionCallback` 이 영어로 떨어뜨린다
- [x] 설정에 '언어' 행과 라디오 4개. 언어 이름은 각 언어의 자기 표기로 고정
- [x] 화면 문자열 전면 추출 — 인증 · 피드 · 게시물 · 댓글 · 채팅 · 프로필 · 안전 · 설정
- [x] `FailureCode` — domain/data 는 locale 을 모르고 presentation 이 번역
- [x] `ValidationError` — `Validators` 는 enum, 화면 경계에서 번역
- [x] DB 트리거 문구 → `FailureCode` 매핑 (마이그레이션 없이 mapper 에서)
- [x] 날짜 표기 — `intl DateFormat` + 현재 locale. 한국어 형식은 기존과 동일
- [x] en·ja 설정 화면 스모크 · 영어 폼 오류 · 오류 3단계 fallback 테스트

검증한 것(2026-08-30):

- 세 ARB 의 **키 집합이 서로 같다.** en·ja 에 한국어가 남은 값도, ko 와 글자까지
  같은 값도 없다 (개수는 feature 마다 늘어나므로 적지 않는다 —
  `test/convention/` 이 대신 지킨다)
- 사용자에게 보이는 문자열 중 하드코딩된 한국어는 없다. `lib/` 의 문자열
  리터럴을 훑으면 ARB · DB 매칭 키 · `Failure.message` 진단 fallback ·
  언어 자기표기(`한국어`)만 남는다
- `Failure` 생성 지점 중 `failureCode` 가 없는 곳은 7곳이고 전부
  **분류되지 않은 서버 오류**를 원문 그대로 올리는 fallback 경로다
  (`supabase_error_mapper` 6 · `repository_error_handler` 1). 의도한 설계다
- Patrol E2E 가 단언하는 한국어 문구는 전부 ARB 의 ko 값과 일치한다.
  다국어 이행이 E2E 를 다시 깨뜨리지는 않았다

## 검수 — 2026-08-24

만든 기능 전체를 로컬 Supabase 로 훑고 결함 3건을 고쳤다
([검수 기록](testing/audit-2026-08-24.md)).

- [x] 권한 경계 · 경계값 · 커서 · 소프트 삭제 전파 · 탈퇴 cascade 확인
- [x] `flutter build apk --debug` 성공
- [x] 고침: 삭제된 게시물에 댓글 삽입 허용 · 트리거 문구 유실 · 프로필 탭 갱신 누락
- [x] Patrol E2E 실행 — 2026-08-27 에 처음 돌렸다. 3건 중 2건 통과, 1건은 단계를
      모두 통과하고도 프로세스가 죽는다 ([검수 기록](testing/audit-2026-08-27.md))

## 코드 리뷰 — 2026-08-24

feed · post · profile 을 외부 리뷰(`codex-review.md`)로 훑고 지적 5건을 고쳤다.

- [x] P1 첨부 이미지 유실 — `CreatePostScenario` 가 본문만 담은 draft 를 새로 만들어
      사진이 저장 경로에 닿지 않았다. 장수 검증과 회귀 테스트를 함께 넣었다
- [x] P1 이미지 URL 소유 경계 — `create_post_with_images()` 가 `url` 이 호출자의
      `post-images` 경로인지 검증한다 (`20260824142714_verify_post_image_urls.sql`)
- [x] P2 닉네임 사전 중복 확인 — 편집 화면이 디바운스 후 확인 결과를 입력창에 표시한다
- [x] P2 Storage 경로 계약 — 계획·테스트 문서를 실제 경로(`{user_id}/{uuid}/{순서}`)에 맞췄다
- [x] P2 이미지 첨부 회귀 테스트 — 문서에만 있던 검증을 cubit·scenario 테스트로 채웠다

## 코드 리뷰 — 2026-08-27

저장소 전체를 문서 정합성 · UI 공통 규칙 · 중복 · 아키텍처 네 축으로 훑고
지적 17건을 고쳤다. 이어서 미검증 항목을 로컬 Supabase · 에뮬레이터로 실제로 돌려
확인했고, 그 과정에서 결함 1건을 더 찾았다 ([검수 기록](testing/audit-2026-08-27.md)).
테스트 390 → 427건.

- [x] P1 개명 누락 — `features/theme` → `preferences` 개명이 문서를 하나도 갱신하지
      않아 `docs/features/theme/` 와 `testing/features/theme.md` 가 없는 경로를
      가리켰다. 문서를 옮기고 "이름 범위" 결정에 개명 사실을 반영했다
- [x] P1 깨진 테스트 명령 — `flutter test test/features/theme` 가 실제로 실패했다
      (`preferences` 로 고치고 두 명령 모두 실행해 확인)
- [x] P1 다국어 진행 상태 — status 에 항목이 없어 plan 의 체크박스에만 있었다.
      이 문서에 옮기고 테스트 문서(`testing/features/preferences.md`)를 만들었다
- [x] P1 설정 계획 역행 — 이미 출시된 회원 탈퇴·테마·언어·차단 목록이
      "준비 중 / 범위 밖"으로 남아 있었다
- [x] P1 destructive 확인 다이얼로그 — 게시물·댓글 삭제가 `AppConfirmDialog` 를
      우회해 **가장 되돌리기 어려운 삭제만 error 색을 못 받고** 있었다.
      네 곳을 공용 다이얼로그로 모으고 `isDestructive` 를 더했다
- [x] P2 feed · profile 중복 — 수정·댓글·감정·신고·삭제 다섯 흐름이 두 벌이었고
      다국어 이행이 한쪽만 옮겨 이미 갈라져 있었다 (`PostTileActions` 로 통합)
- [x] P2 `RepositoryErrorHandler` 7벌 + auth 의 여덟 번째 사본 — auth 만
      `on Failure` 통과가 빠져 있었다. `core/data/repository/` 하나로 합쳤다
- [x] P2 상태 위젯 4벌 — `AppPlaceholder` 로 승격 (`design_system/widget/`)
- [x] P2 닉네임 `ilike` 와일드카드 — `a_ice` 가 `alice` 에 매칭돼 **비어 있는
      닉네임을 "이미 사용 중"으로 막았다**. 로컬 Supabase 로 재현하고
      `core/data/nickname_match.dart` 로 고쳤다 ([검증](testing/audit-2026-08-27.md))
- [x] P2 공용 위젯의 한국어 기본값 — `AppConfirmDialog` 의 취소,
      `AppOverflowMenu` 의 툴팁이 언어를 따라가지 않았다
- [x] P2 날짜 자리맞춤 중복 — `core/extension/date_time_format.dart` 로 모았다
- [x] P3 죽은 화면 — `auth/.../home_page.dart` 가 라우터·테스트 어디에도 없는데
      다국어 이행이 거기에 ARB 키 3개를 새로 만들고 있었다. 화면과 키를 지웠다
- [x] P3 문서 드리프트 — `schema.md` 의 avatar 경로, `architecture.md` 의
      디렉터리 트리와 규칙 ⑥ 문구, `plan-block.md` 의 상태 위젯 근거
- [x] P3 모서리 토큰 — `BorderRadius.circular(8)` 3곳 → `AppRadius`
- [x] CLAUDE.md 의 공통 위젯 목록 — `AppPlaceholder` · `AppConfirmDialog` ·
      `AppOverflowMenu` · `AppCountAction` 넷이 빠져 있었다. 시각 토큰 문단도 더했다

### 검증에서 새로 찾은 것

- [x] **삭제된 게시물의 댓글이 테이블 경로로 샜다** — `post_comments_select_visible`
      이 부모 게시물의 생존을 보지 않아, 앱이 쓰는 뷰에서는 사라지지만 PostgREST 로
      원본 테이블을 직접 조회하면 읽혔다. 2026-08-24 검수가 **뷰만** 확인해서 놓친
      축이다. `20260827161417_hide_comments_of_deleted_post.sql` 로 막았다
- [x] **다국어가 Patrol E2E 를 깨뜨리고 있었다** — 앱이 기기 언어를 따라가는데
      에뮬레이터가 `en-US` 라 영어로 뜨고 한국어 단언이 전부 실패했다.
      `launchApp()` 이 저장값을 `ko` 로 심는다
- [x] 리뷰가 틀렸던 것 2건 정정 — `_displayDate` 는 형식이 서로 달라 "완전히 동일"이
      아니었다(자리맞춤만 공유). 다크 대비 관찰은 테마가 거꾸로였다
      (`like` 는 라이트 3.28 이 미달이고 다크 5.38 은 통과)

## 3단계 — 완료

- [x] **F8 follow** — 단방향 `follows` 엣지 하나로 팔로우 · 맞팔 · 목록을 만든다.
      복합 PK 가 중복을, CHECK 가 자기 팔로우를 막고, `follower_id` 는
      `default auth.uid()` + INSERT GRANT 없음으로 위조를 막는다.
      조회는 전체 공개다 — 남의 프로필에서도 수와 목록이 보여야 한다
      ([계획](features/follow/plan.md) · [기록](features/follow/history.md) ·
      [테스트](testing/features/follow.md) · [스키마 §15](schema.md))
- [x] **차단 × 팔로우** — F7 이 F8 시점까지 미뤄 둔 결정을 닫았다. `blocks` 의
      `after insert` 트리거가 양방향 엣지를 지우고, 차단 상태의 팔로우는 INSERT
      정책이 거부한다. 거부 문구는 방향 중립이다. 대가("차단에는 자식이 달리지
      않는다"는 전제가 깨진다)를 마이그레이션 · 스키마 · 기록에 적었다
- [x] **F4 팔로잉 피드** — 피드에 탭 둘(전체 · 팔로잉). 새 화면이 아니라 같은
      목록의 두 번째 소스다 — `following_posts_with_author` 뷰가
      `posts_with_author` 를 감싸므로 커서 · 컬럼 · 정렬이 그대로고 앱은
      `FeedSource` 로 읽는 대상만 바꾼다
- [x] 프로필에 팔로워 · 팔로잉 수와 팔로우 버튼(3상태, 낙관적 갱신).
      수와 관계는 `profile_details` 뷰가 프로필과 함께 한 번에 내려준다
- [x] 권한 경계 28건을 실제 JWT + REST 로 확인 (`supabase/tests/follow_rls_check.py`)
- [x] **검수 — 2026-08-30.** 서브에이전트 넷(다국어 정합성 · 번역 품질 ·
      F8 데이터 · F8 앱)으로 훑고 결함을 고쳤다. 앱 P1 둘(탭 전환 시 소스 간
      응답 교차, 팔로우 버튼이 한 번만 심어짐)과 DB P2 둘(팔로우 × 차단
      동시성, 뷰 컬럼 동결)이 실질 결함이었다
      ([기록](features/follow/history.md) · `20260830150000_harden_follows.sql`)
- [x] 동시성 4건을 psql 세션 둘로 확인 (`supabase/tests/follow_block_race_check.py`)

## 3.5단계 — F9 채팅 (완료)

- [x] **F9 chat (오픈 채팅)** — 공개방 개설 · 탐색 · 입장(방별 닉네임) · 실시간
      텍스트/사진 · 안읽음 배지 · 입퇴장 시스템 메시지 · 신고/차단 연동.
      실시간은 Postgres Changes 구독이고 차단은 select 정책 한 줄로 끝난다
      ([계획](features/chat/plan.md) · [기록](features/chat/history.md) ·
      [테스트](testing/features/chat.md) · [스키마 §14](schema.md))
- [x] 하단 탭이 넷이 됐다 — 홈 · 채팅 · 프로필 · 설정
- [x] 권한 경계 52건 · 실시간 4건을 실제 JWT + REST/WebSocket 으로 확인
      (`supabase/tests/chat_rls_check.py` · `chat_realtime_check.py`)
- [x] `reports` 에 `chat_message` 대상 추가 — 테이블을 새로 만들지 않았다
- [x] Patrol E2E 1건 — 방 개설 → 전송 → **실시간 확정**까지 에뮬레이터에서 통과

## 3.6단계 — F9-DM (완료)

- [x] **F9-DM (1:1 채팅)** — F9 가 자리만 남긴 `type='direct'` 를 채운다.
      새 테이블 없이 `direct_key` + RPC + 트리거 분기로 얹고, 화면은 기존
      채팅 화면의 direct 분기다. 타인 프로필에서 DM 시작, 목록·방 화면의 상대
      프로필 표시, 나가기 + 자동 재등장, 차단 연동(시작·전송 거부·수신 숨김)까지
      확인했다 ([계획](features/chat/plan-dm.md) · [기록](features/chat/history.md) ·
      [테스트](testing/features/chat.md))
- [x] 권한 경계 78건(F9 52 + DM 26)을 실제 JWT + REST 로 확인
      (`supabase/tests/chat_rls_check.py`)
- [x] `flutter analyze` 무결 · `flutter test` 582건 전체 통과

두 기기 간 DM 실시간 왕복은 별도로 재현하지 않았다 — 메커니즘(Postgres Changes +
RLS 재평가)은 F9 의 기존 검증이 이미 확인했고 방 `type` 을 분기하지 않는다
([완료 조건](features/chat/plan-dm.md) 참고).

참고: "내 주변 유저 익명 채팅방" 아이디어는 위험성 우려로 **보류**했다
(2026-08-30). DM 을 먼저 만들고 재검토한다.

## 다음 할 일

MVP 범위(0~3.6단계)는 모두 닫혔다. 남은 것은 품질 하나와 v1.1 이다.

### 1. E2E 잔여 1건

'잘못된 비밀번호' 테스트가 자기 단계·단언을 전부 통과하고도 프로세스가
`_pendingExceptionDetails` 단언으로 죽는다. 본문이 끝난 뒤 로그인 실패 경로에서
비동기 오류가 하나 더 올라오는 모양이고, 원인은 아직 못 짚었다
([검수 기록 §5](testing/audit-2026-08-27.md)).

**auth 전용이 아니다.** `chat_test` 도 방에서 뒤로 나가는 단계를 넣었더니
본문이 끝난 뒤 같은 모양으로 죽어서, 그 단계를 빼고 실시간 왕복까지만 확인하도록
줄여 둔 상태다 (`patrol_test/chat_test.dart` 주석). 화면 전환·해제 뒤에 남은
비동기 작업이 공통 원인일 가능성이 높다. 후보를 하나 적어 둔다 — 21개
cubit·bloc 중 `isClosed` 가드가 있는 것은 13개고, `SignInCubit` 을 비롯한
auth 쪽 8개는 `await` 뒤에 가드 없이 `emit` 한다. 다만 이 테스트에서는
실패 문구가 뜬 **뒤에** 죽으므로 확인된 원인은 아니다. 재현에는 로컬 Supabase
와 에뮬레이터가 둘 다 필요하다.

### 2. F8 이 남긴 것

- **팔로우 알림**은 4단계 푸시와 함께 간다. 비공개 계정 · 팔로우 요청 승인,
  추천 팔로우는 v1 범위 밖이다 ([계획](features/follow/plan.md))
- 탭을 옮기면 피드를 다시 읽는다(스크롤 위치 초기화). `FeedCubit` 하나를 탭 둘이
  공유하기로 한 대가이고, 문제가 되면 탭별 cubit 으로 나누는 것이 정공법이다
  ([기록](features/follow/history.md))

### 3. 그 밖에 남은 것

- iOS 빌드 — Xcode 미설치라 한 번도 못 돌렸다 ([setup.md](setup.md) §4)
- 4단계(v1.1) — 재설정 SMTP · 구글 로그인 · OTP · 푸시. 아직 대기다

## 5단계 — F10 trade (모의투자) — 진행 중

방향 전환(v0.4)에 따라 4단계보다 먼저 간다. 결정과 화면은 [계획](features/trade/plan.md),
설계 판단은 [기록](features/trade/history.md), 테스트는 [테스트 문서](testing/features/trade.md).

- [x] **5.1 시세 적재** — `fetch_candles.py` · `market_candles` · seed. 클라이언트 GRANT 없음
      ([스키마 §16](schema.md))
- [x] **5.2 스키마 · RPC · 권한** — `trade_sessions` · `trade_orders` · RPC 5개 ·
      `posts.trade_session_id` · 피드 뷰의 `trade_result`. `symbol` · `start_day` 는
      어떤 role 도 읽지 못한다. `trade_rls_check.py` 61건과 기존 스크립트 7개 전부 통과
      ([스키마 §17](schema.md))
- [ ] **5.3 앱** — `features/trade` · 홈 탭 "투자" · 세션 · 결과 화면 · 차트
- [ ] **5.4 결과 공유** — 결과 카드 게시물 · 피드 카드 · 게스트 열람

## UX 심리학 리뷰 반영 — 2026-09-06

[리뷰](../ux-psychology-review.md) 의 8개 발견 중 7개를 반영했다 (8번은 1번이 대체).
계획은 [2026-09-06-ux-psychology](superpowers/plans/2026-09-06-ux-psychology.md).
브랜치 `feat/ux-psychology`.

- [x] 팔로잉 빈 상태 "사람 둘러보기" (feed)
- [x] 가입 폼 autofill 힌트 · 닉네임 제안값 (auth)
- [x] 글자 수 카운터 50자 이내에서만 (post)
- [x] 프로필 완성도 카드 20% 시작 (profile)
- [x] 탈퇴 확인에 실제 개수 (settings — `AccountUseCase` 신설, 댓글은 `post_comments_visible` 로)
- [x] 가입 직후 프로필 꾸미기 · "나중에" (`resolveAuthRedirect` + 편집 화면 setup 모드)
- [x] 로그인 화면 "먼저 둘러보기" → 읽기 전용 게스트 피드 `/explore` (스키마 변경 없음)

검증: `flutter analyze` 무결함, `flutter test` 615 통과,
`python3 supabase/tests/guest_read_check.py` 5/5. Patrol E2E 는 돌리지 않았다 —
`signUpNewAccount` 헬퍼가 "나중에" 를 누르도록 바꿨으니 다음 E2E 실행 때 확인한다.

- 최종 리뷰(2026-09-06) 후 반영: anon 읽기 검사가 앱과 같은 컬럼을 조회 · 탈퇴 개수 경계 스크립트 신설 · 완성도 카드는 남은 항목만 나열 · 게스트 빈 상태에 가입 진입
- 전체 기획·UX 코드 리뷰(2026-09-06, [리뷰](../codex-review.md)) 4건 반영: 프로필
  꾸미기 저장·조회 중 뒤로가기의 닫힌 cubit emit 차단 · `FeedLoadMoreListener` 로
  가로 사진 스크롤이 다음 페이지를 당기지 않게 · 가입 화면 닉네임 디바운스 사전 확인
  (`NicknameCheck` 를 `core/validation` 으로 공유) · `overview.md` v0.3 동기화.
  `flutter test` 637 통과

남은 것:

- 게스트에게 댓글 읽기 전용 화면을 열지는 않았다 (DB 는 anon 에 열려 있다). 리뷰 4번의 "가림 없이" 원칙에 더 충실하려면 후속 과제다

## 인계 메모 — 2026-08-30

`feat/f7-safety-account` 를 `main` 에 병합해 여기까지를 한 줄기로 만들었고,
이어서 다국어 마무리와 F8 팔로우를 `main` 에 올렸다. 브랜치는 `main` 하나뿐이다.
이 시점의 `main` 상태:

- `flutter analyze` 무결함, `flutter test` 548건 통과
- 마이그레이션은 `20260830090000_add_follows.sql` 까지 적용된 상태가 기준이다.
  받은 직후에는 프로젝트 루트에서 `supabase start` 후 `supabase db reset` 을 한 번 돌린다
- 로컬 검증 스크립트는 `supabase/tests/` 에 있다 (채팅 권한 경계 · 실시간 ·
  팔로우 권한 경계). 스키마를 바꾸면 함께 갱신한다
- Patrol E2E 는 로컬 Supabase + 에뮬레이터가 둘 다 떠 있어야 한다
  ([E2E 가이드](testing/e2e.md))

작업 규칙은 [CLAUDE.md](../CLAUDE.md) 와 [아키텍처](architecture.md) 에 있고,
진행 상태는 다른 문서에 적지 않고 이 문서에만 적는다.

## 문서 규칙

- feature를 시작할 때 `docs/features/<name>/plan.md`(화면·상태·완료 조건)를 먼저 쓰고,
  완료하면 `history.md`(설계 판단 · 버그 · 검증 결과)를 남긴다
- 이 문서의 체크박스가 진행 현황의 유일한 기준이다. 다른 문서에는 진행 상태를 적지 않는다
