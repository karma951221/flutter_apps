# F1 auth — 테스트 범위

> [테스트 가이드](../README.md) · [계획](../../features/auth/plan.md) · [구현 기록](../../features/auth/history.md)

| 대상 | 시나리오 | 기대 결과 |
|---|---|---|
| `SupabaseErrorMapper` | `invalid_credentials` | 계정 존재 여부를 노출하지 않는 단일 문구의 `Failure`로 변환된다. |
| `SupabaseErrorMapper` | `user_already_exists` / `otp_expired` | 각각 이메일 검증 실패 / 재요청 안내 `Failure`로 변환된다. |
| `SupabaseErrorMapper` | 알 수 없는 오류 코드 | HTTP 상태 코드 기준으로 분류된다. |
| `SupabaseErrorMapper` | DB 제약 위반 (`profiles_nickname_length` · `23505` 중복) | 날것의 DB 오류가 사용자 문구 `Failure`로 변환된다. |
| `SignUpScenario` | 사용 중인 닉네임 | 가입을 시도하지 않고 실패를 반환한다. |
| `SignUpScenario` | 닉네임 사전 확인 자체가 실패 | 가입을 막지 않고 진행한다 (최종 판정은 DB 제약). |
| `AuthBloc` | 인증 스트림 이벤트 | 초기 unknown → 사용자 수신 시 authenticated, null 수신 시 unauthenticated. |
| `AuthBloc` | 스트림 오류 | 죽지 않고 unauthenticated로 떨어진다 (인증이 영구히 멈추지 않음). |
| `AuthBloc` | 로그아웃 (성공·실패 모두) | 저장소를 호출하고 unauthenticated가 된다. |
| `AuthBloc` | 사용자 갱신 요청 | 저장소에서 사용자를 다시 읽어 authenticated를 다시 낸다. 실패하면 상태를 바꾸지 않는다. |
| `SignUpCubit` | 가입 제출 | 성공 시 success로 끝나고, 진행 중 재요청은 무시한다. |
| `PasswordResetCubit` | 코드 발송 성공/실패 | 성공 시에만 코드 입력 단계로 넘어가고 이메일을 기억한다. |
| `PasswordResetCubit` | 코드 오류 / 변경 성공 / 처음으로 | 틀린 코드는 단계 유지, 변경 성공은 done, "이메일 다시 입력"은 1단계 복귀 + 오류 초기화. |
| `SignInPage` | 헤더 | 앱 이름과 한 줄 설명이 화면 위에 선다. |
| `SignInPage` | 빈 폼 제출 | cubit 을 부르지 않고 필드별 오류를 보여준다. |
| `SignInPage` | 영어 locale 에서 빈 폼 제출 | 이메일·비밀번호 검증 오류가 영어로 보인다. |
| `SignInPage` | 정상 입력 | 입력값을 그대로 cubit 에 넘긴다. |
| `SignInPage` | 제출 중 | 버튼이 로딩으로 바뀌고 회원가입·재설정 진입도 막힌다. |
| `SignInPage` | 실패 | 입력 아래에 실패 문구가 남는다. |
| `SupabaseErrorMapper` | 댓글 300자 제약 | 사용자 문구로 번역된다. |
| `SupabaseErrorMapper` | 2단 제한 트리거 문구 | 트리거가 던진 한국어를 그대로 전달한다 — 기본 문구로 덮지 않는다. |
| `SupabaseErrorMapper` | 42501 | "권한이 없거나 삭제된 대상입니다" 로 안내한다. |
| `SupabaseErrorMapper` | 정의되지 않은 감정 코드 | 감정 관련 안내로 바꾼다.

실행:

```bash
cd app
flutter test test/features/auth
```

Supabase 인증 흐름 자체(트리거 · RLS · 세션 저장)는 mock 대신 로컬 Supabase
통합 테스트와 실기기 확인으로 검증한다 ([구현 기록 · 검증](../../features/auth/history.md)).
