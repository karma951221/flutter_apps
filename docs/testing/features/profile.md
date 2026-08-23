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
| `ProfileCubit.load` | userId 없음 / 있음 | `getMyProfile` 로 내 프로필을, `getProfile(userId)` 로 해당 사용자의 프로필을 읽는다. 서로를 대신 호출하지 않는다. |
| `ProfileCubit.load` | 조회 실패 (본인 · 타인) | 로딩을 끄고 `failure` 만 남긴다. 프로필은 null 로 둔다. |
| `ProfileCubit.save` | 수정 성공 | `ProfileUpdate` 가 usecase 에 그대로 전달되고 결과 프로필이 상태에 담긴다. |
| `ProfilePage` | 내 프로필 | 편집 버튼이 보이고, 내 id 로 게시물을 읽는다. |
| `ProfilePage` | `/users/:id` | 타인 화면에는 편집 버튼이 없고 해당 작성자의 게시물만 커서로 읽는다. 내 프로필은 조회하지 않는다. |
| `ProfilePage` | 프로필 조회 실패 | 다시 시도 버튼을 보여주고, 주인을 모르므로 게시물은 읽지 않는다. |
| `ImageUploader.objectPathFromPublicUrl` (`test/core/media/`) | 아바타 공개 URL · 쿼리 · 퍼센트 인코딩 · 다른 버킷 | 자기 버킷의 객체 경로만 뽑아내고, 그 밖의 URL 은 null 이라 삭제를 시도하지 않는다. |
| Storage RLS (통합) | 다른 사용자 UUID prefix로 `avatars` 업로드 | 403으로 거부된다. |
| Storage RLS (통합) | 자기 UUID prefix로 WebP 업로드 | 허용되고 공개 URL이 프로필에 저장된다. |

실행:

```bash
cd app
flutter test test/features/profile
```

`SupabaseProfileDataSource`의 fluent query 조립과 RLS는 SupabaseClient mock 대신 로컬
Supabase 통합 테스트로 검증한다.
