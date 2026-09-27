# F2 profile — 구현 기록

> [트레이더 허브](../../README.md) · [계획](plan.md) · [스키마](../../schema.md) · [테스트](testing.md)

## 2026-08-23 — 아바타와 타인 프로필

공통 X3 media 처리로 갤러리에서 사진을 고르고, 긴 변 1080px·WebP·품질 80으로
압축한 뒤 `avatars/{user_id}/`에 올린다. 업로더는 현재 인증 사용자의 ID로 경로를
직접 만들며, Storage RLS도 같은 첫 경로 조각을 검사한다. 공개 버킷 URL만
`profiles.avatar_url`에 저장해 `AppAvatar`와 피드가 같은 값을 표시한다.

`/users/:userId`는 내 프로필과 같은 화면을 재사용한다. 피드의 타인 게시물 탭이 이
경로로 연결되며, 본인이 아닐 때는 프로필 편집 UI를 렌더링하지 않는다. 목록 조회는
기존 `posts_with_author` 커서 규칙에 `author_id` 필터를 더해 재사용했으므로 전체
피드와 프로필 목록의 페이지 경계 규칙이 일치한다.

## 2026-08-23 — 아바타 저장 흐름을 scenario 로 옮김

편집 화면이 `ImageUploader` 를 직접 꺼내 쓰면서 업로드 → 프로필 갱신 → 실패 시
새 객체 되돌리기 → 성공 시 옛 객체 삭제까지 위젯 안에서 조합하고 있었다. 여러
저장소 호출과 보상 처리는 [규칙 ③](../../../../../docs/architecture.md#-presentation은-feature별-usecase-facade-하나만-주입받는다)
이 말하는 scenario 의 자리다. 또 업로더가 던지는 `StorageException` 이 그대로
presentation 까지 올라와 [규칙 ①](../../../../../docs/architecture.md#-supabase-타입은-data-밖으로-나가지-않는다)
도 깨져 있었다.

- `core/media/image_uploader.dart` 를 계약(`ImageStorage`)과 구현
  (`SupabaseImageStorage`)으로 나눴다. 구현이 실패를 `Failure` 로 바꿔 던지므로
  SDK 예외는 core 의 data 인프라 밖으로 나가지 않는다.
- 순서와 보상은 `UpdateAvatarScenario` 가 소유한다. Storage 능력은
  `ProfileRepository.uploadAvatar` / `removeAvatar` 로만 닿는다 — domain 이 버킷
  이름이나 공개 URL 규칙을 알 이유가 없고, 예외→`Failure` 변환도 data 계층에
  남아야 하기 때문이다.
- 편집 화면은 `ProfileCubit` 하나만 주입받는다. 화면에서 보이는 동작(고를 때는
  올리지 않음 · 저장 때 업로드 · 실패 시 롤백 · 성공 시 옛 이미지 삭제 · 저장 후
  사용자 스냅샷 갱신)은 그대로다.
- 게시물 데이터소스에 복사돼 있던 공개 URL → 객체 경로 변환과 업로드/삭제 코드도
  같은 `ImageStorage` 로 합쳤다. 테스트가 있는 쪽으로 모은 것이다.

## 검증

- `flutter analyze` 통과
- `flutter test` 전체 통과 (아바타 흐름 이관 후 128개)
- Storage와 RLS의 실제 거부/허용은 로컬 Supabase 재적용 후 통합 확인이 필요하다.

## 2026-09-06 — UX 심리학 리뷰 반영 (완성도 카드 · 프로필 꾸미기)

[리뷰](../../../../../ux-psychology-review.md) 1번·5번.

- 내 프로필 헤더 아래 `ProfileCompletionCard`. 닉네임·사진·자기소개·첫 게시물·첫 팔로우
  다섯 칸이고 닉네임은 가입 때 정했으므로 **항상 20% 에서 시작한다.** 근거 없는 칸은
  채우지 않는다 — 전부 앱이 이미 아는 값(`Profile` · 프로필 화면의 `FeedCubit`)으로
  판정한다. 다섯 개가 끝나면 사라진다. "첫 팔로우" 는 홈에서 하는 일이라 탭 동작이 없다
- 알려진 열화: 카드가 첫 화면을 채워 내 게시물이 스크롤 아래로 밀린다(의도한 유도이지만
  접힘형 변형이 후보). 목록을 다시 읽는 동안(`status == loading`) 카드가 잠깐 사라진다.
  `BlocBuilder` 에 `buildWhen` 이 없다
- 편집 화면에 `isSetup` 모드. 제목 "프로필 꾸미기", 안내 한 문장, "계속"(저장 후 홈),
  "나중에"(저장 없이 홈). "나중에" 는 AppBar 가 아니라 "계속" 아래에 둔다 — 테마의
  `TextButton` 최소 너비가 `Size.fromHeight` 라 AppBar 의 Row 안에서는 폭이 무한대가
  된다. 뒤로가기는 없고 시스템 뒤로가기는 `PopScope` 로 홈에 보낸다. 조회에 실패하면
  재시도와 "나중에" 가 남는다 — 리뷰에서 컨트롤 없는 빈 화면이 잡혀 더한 것이다

검증: `flutter test test/features/profile` 62 통과.
