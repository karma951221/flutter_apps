# W5 social — 테스트

> [테스트 가이드](../../../../../docs/testing/README.md) · [pawlog 허브](../../README.md) · [계획](plan.md) · [구현 기록](history.md)

```bash
cd apps/pawlog && flutter test test/core/supabase test/data/social test/domain/social test/presentation/social
cd apps/pawlog && flutter test test/presentation/walk/cubit/walk_share_cubit_test.dart test/presentation/walk/page/walk_detail_page_test.dart

# 로컬 Supabase 가 떠 있어야 한다(supabase start). 평소에는 건너뛴다
cd apps/pawlog && flutter test --run-skipped -t integration

# RLS · RPC 경계 (실제 JWT + REST)
python3 supabase/tests/walk_posts_rls_check.py
```

`apps/pawlog` 전체는 `+739`(건너뜀 2 — 통합)이다(2026-10-18 `e4a005c`, W5 전 `+562`). 통합 5건 · RLS 스크립트 53/53.

| 파일 | 건수 | 확인 |
|---|---|---|
| `core/supabase/supabase_initializer_test.dart` | 3 | 초기화 성공 → available, 던지면 unavailable(앱은 뜬다) |
| `core/supabase/timeout_http_client_test.dart` | 4 | 끝나지 않는 요청 → 10초 뒤 `TimeoutException` · 빠른 응답 통과 · `close` 전달 · `TimeoutException` → `networkUnavailable` |
| `data/social/supabase_auth_gateway_test.dart` | 5 | 가입은 닉네임을 메타데이터로 · 세션 없는 가입 → `signUpFailed` · 로그인 · 사용자 변화 스트림 · 현재 사용자 |
| `data/social/supabase_auth_repository_test.dart` | 10 | 프로필 닉네임으로 세션 · 틀린 자격 → `invalidCredentials` · 프로필 실패에도 로그인 · 닉네임 사전 확인(대소문자 무시) · 경합 유일 위반 → `nicknameTaken` · 로그아웃 · 세션 스트림 |
| `data/social/supabase_community_gateway_test.dart` | 8 | RPC 인자 · 반환 · 보기 정렬과 커서 `or` 필터 · 내 글 찾기 · 좋아요 insert(`post_id` 만) · delete · 현재 사용자 |
| `data/social/supabase_community_repository_test.dart` | 20 | 행 → `WalkPost`(UTC → 현지) · limit+1 로 다음 페이지 · 커서 · 이미 누른 좋아요 · 없는 공유 취소는 Ok · 로그인 필요 |
| `data/social/unavailable_*_repository_test.dart` | 1 · 1 | 쓸 수 없음 저장소는 서버 없이 실패를 돌려준다 |
| `data/social/walk_post_cursor_test.dart` | 4 | 마이크로초 · UTC 왕복 · 현지 시각 · null · 깨진 커서 → `feedCursorInvalid` |
| `domain/social/entity/walk_post_draft_test.dart` | 5 | 산책 → 공유 초안 · 경로 감추기 · 트랙 없으면 미리보기 점 · 메모 500자 · 반려견 이름 30자 · 10마리 |
| `domain/social/policy/route_privacy_test.dart` | 11 | 누적 앞뒤 150 m(경계 포함) · **집 앞 왕복은 모두 버림** · **중간에 집 앞을 지나간 점 버림** · 300 m 이하 빈 목록 · 64점 상한 · 하버사인 |
| `domain/social/usecase/social_use_case_test.dart` | 12 | 로그인 없이 공유 · 공유 취소 · 좋아요 → `authenticationRequired` · `walkNotFound` · 반려견 없으면 `walkDogRequired` · 공유 여부는 로그아웃이면 false · 둘러보기는 로그인 없이 |
| `presentation/social/cubit/auth_cubit_test.dart` | 5 | 로그인 · 가입 성공 · 실패 · 닉네임 겹침 · 보내는 중 두 번째 무시 |
| `presentation/social/cubit/community_cubit_test.dart` | 22 | 첫 페이지 · 더 읽기 · **실패 뒤 스크롤 재요청 막음 · `retryLoadMore` · 새로고침이 풀어 줌** · **응답 없는 읽기가 10초 뒤 실패로 끝남(fake_async)** · 세션 변화 · 낙관적 좋아요 |
| `presentation/social/page/community_page_test.dart` | 14 | 줄글 목록 · 하트 · 빈 목록 · 실패 · 쓸 수 없음 · 더 읽기 · **더 읽기 실패 스낵바 한 번 · "다시 시도"** · 새로고침 · 로그인 · 로그아웃 메뉴 |
| `presentation/social/page/sign_in_page_test.dart` | 9 | 로그인 · 가입 전환 · 닉네임 2~20자 · 이메일 형식 · 성공 콜백 · 자격 실패 스낵바 · 닉네임 겹침 안내 |
| `presentation/walk/cubit/walk_share_cubit_test.dart` | 20 | 공유 여부 · **읽기 실패 → 숨김, 로그인 변화 · 다시 열기에 다시 읽음** · 토글 · **보내는 사이 로그인 변화는 덮어쓰지 않음** · `unshareForDelete` 5 |
| `presentation/walk/page/walk_detail_page_test.dart` 중 W5 | 11 | 공유 항목 위치 · 라벨 · 로그인 이동 · 쓸 수 없음 · **읽기 실패면 숨김** · **공유한 산책 삭제: 공유 취소 → 삭제 · 취소 실패에도 삭제 + 스낵바 · 로그아웃이면 서버 안 부름** |
| `data/social/supabase_*_integration_test.dart`(통합) | 3 · 2 | 로컬 Supabase 에서 가입 → 로그아웃 → 로그인 · 대소문자만 다른 닉네임 · 틀린 비밀번호, 공유 → 보임 → 좋아요 → 공유 취소 → 사라짐 · 커서 페이지가 겹치지 않음 |

`packages/core` 의 `supabase_error_mapper_test.dart` 에 시간 제한 → network, gotrue 가 감싼 요청 실패(상태 코드 없음) → network ·
있으면 server 를 더했다(`+69`). `packages/l10n` `+10`.

## 에뮬레이터

2026-10-18, Android 에뮬레이터 + 로컬 Supabase(`10.0.2.2:54321`).

| # | 시나리오 | 결과 |
|---|---|---|
| ① | 로그인 없이 모두의 산책 둘러보기 | **PASS** — 빈 목록 안내 |
| ② | 가입 → 돌아오기 | **PASS** — 모두의 산책으로 돌아온다 |
| ③ | 상세 "모두에게 공유" | **PASS** — DB 에 행이 생김. 320 m 산책이라 경로가 다 잘려 `route_preview` null(의도한 결과) |
| ④ | 공유 뒤 더보기 | **PASS** — "Stop sharing" 으로 바뀜 |
| ⑤ | 모두의 산책에 보임 | **PASS** |
| ⑥ | 좋아요 | **PASS** — 0 → 1 |
| ⑦ | 공유 취소 | **PASS** — 목록이 빈다 |
| ⑧ | 로그아웃 | **PASS** — 더보기가 "Sign in" |
| ⑨ | 내 수첩(피드) | **PASS** — 로컬 기록 그대로 |
| ⑩ | API 컨테이너를 멈추고 앱 실행 | **PASS** — 앱이 뜬다. 이때 모두의 산책 스피너가 끝없이 돌던 것을 찾아 시간 제한으로 고쳤다(`e4a005c`) |
