# F1 auth — 테스트 범위

> [테스트 가이드](../README.md) · [구현 기록](../../features/auth/history.md)

| 계층 | 검증 대상 |
|---|---|
| core/data | Supabase 인증·DB 오류를 `Failure`로 변환 |
| domain/scenario | 닉네임 중복 확인과 가입 흐름 |
| presentation/bloc | 인증 스트림, 로그아웃 상태 전이 |
| presentation/cubit | 가입·로그인 제출과 비밀번호 재설정 상태 전이 |

실행:

```bash
cd app
flutter test test/features/auth
```
