# F2 profile — 테스트 범위

> [테스트 가이드](../README.md) · [아키텍처](../../architecture.md) · [프로필 화면](../../../app/lib/features/profile/presentation/page/profile_page.dart)

| 대상 | 시나리오 | 기대 결과 |
|---|---|---|
| `ProfileDtoMapper` | profiles 행 DTO 변환 | ID, 닉네임, 자기소개, 아바타 URL, 생성·수정 시각이 손실 없이 `Profile`로 변환된다. |
| `ProfileRepositoryImpl.getProfile` | 타인 프로필 조회 성공 | datasource의 `ProfileDto`가 domain `Profile`을 담은 `Ok`로 반환된다. |
| `ProfileRepositoryErrorHandler` | datasource가 `Failure`를 발생 | 이미 앱 오류인 `Failure`를 다시 매핑하지 않고 `Err`로 그대로 반환한다. |
| `ProfileRepositoryErrorHandler` | Supabase 권한 오류 (`42501`) | Supabase 예외가 권한 오류 `Failure`를 담은 `Err`로 변환된다. |
| `ProfileRepositoryImpl.getMyProfile` | 현재 로그인 사용자가 없음 | `not_authenticated` 인증 오류를 담은 `Err`가 반환된다. |
| `ProfileRepositoryImpl.updateMyProfile` | 수정 성공 | `ProfileUpdate`가 datasource에 그대로 전달되고, 반환 DTO는 `Profile`로 변환된다. |
| `ProfileRepositoryImpl.isNicknameAvailable` | 닉네임 중복 | datasource의 사용 가능 여부가 변경 없이 `Ok<bool>`로 반환된다. |

실행:

```bash
cd app
flutter test test/features/profile
```

`SupabaseProfileDataSource`의 fluent query 조립과 RLS는 SupabaseClient mock 대신 로컬
Supabase 통합 테스트로 검증한다.
