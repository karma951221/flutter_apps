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
| 3 | F8 follow · F4 팔로잉 피드 | 대기 — **다음 차례** |
| 3.5 | F9 chat (오픈 채팅) | **완료** |
| 4 | (v1.1) 재설정 SMTP · 구글 로그인 · OTP · 푸시 · 채팅 | 대기 |

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

## 다국어 — 진행 중

`features/theme` 를 `features/preferences` 로 개명하고 gen-l10n 기반을 깔았다.
화면 문자열 전면 추출이 남아 있다
([계획](features/preferences/plan-language.md) ·
[기록](features/preferences/history.md) ·
[테스트](testing/features/preferences.md)).

- [x] feature 개명 — `PreferencesUseCase` 로 facade 통합, 저장소는 관심사별 유지
- [x] gen-l10n 기반 — `l10n.yaml`, ARB 3개(template `ko`), `AppLocalizations`
- [x] `MaterialApp` 배선 — `locale`(시스템은 `null`) · delegates ·
      미지원 기기 언어는 `localeResolutionCallback` 이 영어로 떨어뜨린다
- [x] 설정에 '언어' 행과 라디오 4개. 언어 이름은 각 언어의 자기 표기로 고정
- [x] 화면 문자열 추출 — 설정 · 피드 · 게시물 · 댓글 · 인증(일부)
- [ ] 화면 문자열 추출 — 프로필 · 안전(신고·차단) · 계정 설정 · 홈 셸의 남은 한국어
- [ ] `FailureCode` — `Failure` 에 코드를 더하고 presentation 이 번역
- [ ] `ValidationError` — `Validators` 가 문자열 대신 enum 을 돌려준다
- [ ] DB 트리거 문구 → `FailureCode` 매핑 (마이그레이션 없이 mapper 에서)
- [ ] 날짜 표기를 `intl` 의 `DateFormat` 으로 (지금은
      `core/extension/date_time_format.dart` 한곳에 모아 둔 한국식 고정 형식)
- [ ] en·ja 대표 화면 스모크 테스트

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

## 다음 할 일

우선순위 순이다. 1·2는 이미 만든 것을 마무리하는 일이고, 3부터가 새 기능이다.

### 1. 다국어 마무리 (남은 범위)

화면 문자열 추출이 절반쯤 왔다. 남은 항목은 위 "다국어 — 진행 중" 절의
체크박스가 기준이며, 손대는 순서는 이렇게 잡는 게 낫다.

1. 남은 화면의 한국어 추출 — 프로필 · 안전(신고·차단) · 계정 설정 · 홈 셸.
   방식은 이미 끝낸 설정 · 피드 · 게시물 · 댓글 화면과 같다
   (`AppLocalizations.of(context)` + `app_ko.arb` 를 template 으로 3개 ARB 동시 갱신)
2. `FailureCode` — `Failure` 에 코드를 더하고 presentation 이 번역한다.
   지금은 data 계층이 한국어 문장을 만들어 올려서 화면이 번역할 여지가 없다
3. `ValidationError` — `Validators` 가 문자열 대신 enum 을 돌려준다
4. DB 트리거 문구 → `FailureCode` 매핑. 마이그레이션 없이
   `core/data/mapper/supabase_error_mapper.dart` 에서 받는다
5. 날짜 표기를 `intl` 의 `DateFormat` 으로.
   지금은 `core/extension/date_time_format.dart` 한곳에 한국식 고정 형식이 모여 있다
6. en · ja 대표 화면 스모크 테스트

### 2. E2E 잔여 1건

'잘못된 비밀번호' 테스트가 자기 단계·단언을 전부 통과하고도 프로세스가
`_pendingExceptionDetails` 단언으로 죽는다. 본문이 끝난 뒤 로그인 실패 경로에서
비동기 오류가 하나 더 올라오는 모양이고, 원인은 아직 못 짚었다
([검수 기록 §5](testing/audit-2026-08-27.md)).

### 3. 3단계 — F8 follow · F4 팔로잉 피드

아직 계획서가 없다. 착수할 때 `docs/features/follow/plan.md` 를 먼저 쓴다
(이 문서 맨 아래 "문서 규칙"). 기획 의도는 [기획서](overview.md) 에 있다.
설계 시 참고할 것:

- 팔로우 관계는 `blocks` 와 같은 자기참조 방향 테이블 꼴이 된다.
  차단이 `is_blocked_with()` 판정 함수 하나로 `posts` · `post_comments` 정책을
  양방향으로 막은 방식을 그대로 참고할 수 있다 ([스키마](schema.md))
- 팔로잉 피드는 새 화면이 아니라 기존 `features/feed` 의 두 번째 소스다.
  커서 계약(`feed/data/cursor/`)과 `posts_with_author` 뷰를 재사용하고,
  차단 필터가 이미 정책 쪽에 있으므로 앱은 조건만 바꾸면 된다
- 프로필 화면에 팔로우 버튼과 팔로워/팔로잉 수가 붙는다.
  게시물 액션은 `PostTileActions` 로 이미 한 벌이므로 거기에 얹는다

### 4. 그 밖에 남은 것

- iOS 빌드 — Xcode 미설치라 한 번도 못 돌렸다 ([setup.md](setup.md) §4)
- 4단계(v1.1) — 재설정 SMTP · 구글 로그인 · OTP · 푸시. 아직 대기다

## 인계 메모 — 2026-08-30

`feat/f7-safety-account` 를 `main` 에 병합해 여기까지를 한 줄기로 만들었다.
이 시점의 `main` 상태:

- `flutter analyze` 무결함, `flutter test` 499건 통과
- 마이그레이션은 `20260828101500_add_chat.sql` 까지 적용된 상태가 기준이다.
  받은 직후에는 프로젝트 루트에서 `supabase start` 후 `supabase db reset` 을 한 번 돌린다
- 로컬 검증 스크립트는 `supabase/tests/` 에 있다 (채팅 권한 경계 · 실시간)
- Patrol E2E 는 로컬 Supabase + 에뮬레이터가 둘 다 떠 있어야 한다
  ([E2E 가이드](testing/e2e.md))

작업 규칙은 [CLAUDE.md](../CLAUDE.md) 와 [아키텍처](architecture.md) 에 있고,
진행 상태는 다른 문서에 적지 않고 이 문서에만 적는다.

## 문서 규칙

- feature를 시작할 때 `docs/features/<name>/plan.md`(화면·상태·완료 조건)를 먼저 쓰고,
  완료하면 `history.md`(설계 판단 · 버그 · 검증 결과)를 남긴다
- 이 문서의 체크박스가 진행 현황의 유일한 기준이다. 다른 문서에는 진행 상태를 적지 않는다
