# 진행 현황

> [문서 허브](README.md) · [기획](overview.md) · [아키텍처](architecture.md) · [테스트 가이드](testing/README.md)

**진행 현황의 단일 기준은 이 문서다.** 단계 정의와 각 단계의 의미는
[기획서 §8](overview.md)에, 구조·규칙은 [아키텍처](architecture.md)에 있다.
이 문서는 "지금 어디까지 왔고 다음이 무엇인가"만 다루며, 자주 갱신된다.

## 단계 요약

| 단계 | 범위 | 상태 |
|------|------|------|
| 0 | 프로젝트 · 로컬 Supabase · DI · design system | **완료** |
| 1 | F1 auth · F2 profile · F3 post · F4 전체 피드 | **진행 중** |
| 2 | F5 reaction · F6 comment · F7 safety | **진행 중** |
| 3 | F8 follow · F4 팔로잉 피드 | 대기 |
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

## 1단계 — 진행 중

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

## 2단계 — 진행 중

- [x] **F5 reaction** — 게시물·댓글 공용 감정표현. 대상별 테이블 + `ReactionTarget` 으로
      일반화, 집계는 목록 뷰의 `jsonb`, 낙관적 업데이트는 목록을 소유한 쪽이 한다
      ([계획](features/reaction/plan.md) · [기록](features/reaction/history.md))
- [x] **F6 comment** — 2단 댓글. 제한은 트리거, 조회는 `post_comments_visible`
      (`security_invoker = off` 예외), 오래된 순 커서, 댓글 화면과 답글 지연 로딩
      ([계획](features/comment/plan.md) · [기록](features/comment/history.md))
- [ ] **F7 safety** — 신고 · 차단

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

## 다음 할 일

1. 로컬 Supabase 통합 확인 — avatar와 post-images Storage RLS(타인 경로 쓰기 거부),
   `created_at` 이 같은 게시물의 끊어 읽기,
   소프트 삭제한 글이 `posts_with_author` 에서 빠지는지
   ([feed 기록 · 검증](features/feed/history.md))
3. F7 safety 착수 — **차단 필터를 `posts_with_author` 와 `post_comments_visible`
   양쪽에 손으로 넣어야 한다** ([comment 기록](features/comment/history.md))

## 문서 규칙

- feature를 시작할 때 `docs/features/<name>/plan.md`(화면·상태·완료 조건)를 먼저 쓰고,
  완료하면 `history.md`(설계 판단 · 버그 · 검증 결과)를 남긴다
- 이 문서의 체크박스가 진행 현황의 유일한 기준이다. 다른 문서에는 진행 상태를 적지 않는다
