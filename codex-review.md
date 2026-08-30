# feed · post · profile 코드 리뷰

검토일: 2026-08-24
범위: `app/lib/features/{feed,post,profile}`, 관련 Supabase migration · 테스트 · 기능 문서

## 요약

| # | 등급 | 결함 | 위치 | 상태 |
|---|---|---|---|---|
| 1 | P1 | 첨부 이미지가 작성 usecase에서 유실된다 | `create_post_scenario.dart:34` | 고침 |
| 2 | P1 | 이미지 생성 RPC가 URL 소유권을 검증하지 않는다 | `20260823120803_harden_post_images.sql:45` | 고침 |
| 3 | P2 | 닉네임 사전 중복 확인이 화면에 연결돼 있지 않다 | `edit_profile_page.dart:185` | 고침 |
| 4 | P2 | Storage 경로 계약이 문서마다 다르다 | `docs/features/post/plan.md:24` | 고침 |
| 5 | P2 | 이미지 첨부 회귀 테스트가 문서에만 있다 | `docs/testing/features/post.md:19` | 고침 |

위치는 리뷰 시점(수정 전)의 것이다. 조치 내용은 맨 아래에 있다.

1번과 5번은 한 쌍이다. 검증할 테스트가 없어서 1번이 전체 테스트를 통과했다.

## 발견 사항

### [P1] 1. 첨부 이미지가 작성 usecase에서 유실된다

**위치** `app/lib/features/post/domain/usecase/scenario/create_post_scenario.dart:34`

**현상** `CreatePostScenario`는 본문을 정규화한 뒤 `PostDraft(content: content)`를 새로
만들어 repository에 넘긴다. 원래 draft의 `images`가 이 자리에서 빠진다.

**영향** 작성 화면에서 사진을 고르고 `PostCubit.create`까지 정상으로 흘러도 datasource는
빈 `images`를 받아 텍스트 전용 INSERT 경로를 탄다. 업로드도, `create_post_with_images`
RPC도, 피드의 이미지 표시도 전혀 실행되지 않는다. 사용자에게는 사진이 조용히 사라진 것으로
보인다.

**수정** 정규화한 본문과 기존 이미지를 함께 넘긴다
(`PostDraft(content: content, images: draft.images)`). 같은 자리에서
`PostPolicy.maxImageCount`를 검증하고, 이미지가 보존되는 회귀 테스트를 5번과 함께 만든다.

### [P1] 2. 이미지 생성 RPC가 URL 소유권을 검증하지 않는다

**위치** `supabase/migrations/20260823120803_harden_post_images.sql:45-54`

**현상** `create_post_with_images`는 `security definer`로 `post_images` 행을 만들면서
전달받은 `url`을 그대로 저장한다. 호출자가 인증 사용자인지와 새 게시물의 작성자만 확인할 뿐,
URL이 `post-images/{auth.uid()}/...`에 속하는지는 보지 않는다.

**영향** 앱 UI를 우회해 RPC를 직접 호출하면 다른 사용자의 공개 이미지 URL이나 임의의 외부
URL을 자기 게시물의 이미지 메타데이터로 붙일 수 있다. `docs/schema.md` §7이 약속한
사용자별 Storage 경로 경계가 Storage 정책에만 있고 DB 함수에는 없다.

**수정** 함수 안에서 URL을 Storage 공개 URL 형식으로 파싱해 버킷과 첫 경로 조각이
`auth.uid()`와 같은지 검증하고, 아니면 예외를 던진다. 직접 RPC 호출에 대한 허용/거부
통합 테스트를 함께 둔다.

### [P2] 3. 닉네임 사전 중복 확인이 화면에 연결돼 있지 않다

**위치** `app/lib/features/profile/presentation/page/edit_profile_page.dart:185-191`

**현상** `ProfileUseCase.isNicknameAvailable`과 datasource·repository·scenario는 모두
있지만 편집 화면도 cubit도 이를 부르지 않는다. 닉네임 `TextFormField`에 걸린 검증은
`Validators.nickname`(형식)뿐이다.

**영향** `docs/features/profile/plan.md:30`이 요구한 "디바운스 사전 확인 표시"가 없어
사용자는 저장 버튼을 누를 때까지 중복 여부를 알 수 없다. 같은 문서 45번 줄은 이 항목을
완료(`[x]`)로 적고 있어 문서도 실제와 어긋난다.

**수정** 닉네임 입력 변경을 디바운스해 현재 닉네임과 다른 값만 확인하고, 확인 중 · 사용 가능 ·
중복 상태를 입력창에 표시한다. DB unique 제약이 최종 판정이라는 점은 그대로 둔다.

### [P2] 4. Storage 경로 계약이 문서마다 다르다

**위치** `docs/features/post/plan.md:24`, `docs/testing/features/post.md:20`,
`app/lib/features/post/data/datasource/supabase_post_data_source.dart:63-80`

**현상** 구현은 게시물 id와 무관한 UUID folder를 만들어
`{user_id}/{folder}/{index}.{extension}`에 올린다. `docs/schema.md:594`는 이 설계를
그대로 적고 이유("게시물 id가 아니다")까지 밝혀 놓았지만, F3 plan과 테스트 범위 문서는
여전히 `{user_id}/{post_id}/{sort_order}.webp`를 요구한다.

**영향** 같은 계약을 말하는 문서가 세 벌인데 둘이 낡았다. 다음 사람이 어느 쪽을 기준으로
읽느냐에 따라 2번의 수정 방향이 갈린다.

**수정** 현재 folder 기반 설계를 정본으로 삼고 `docs/features/post/plan.md`와
`docs/testing/features/post.md`를 `docs/schema.md` 문구에 맞춘다.

### [P2] 5. 이미지 첨부 회귀 테스트가 문서에만 있다

**위치** `docs/testing/features/post.md:19`, `app/test/features/post/`

**현상** 테스트 범위 문서는 `PostCubit`이 최대 5개의 압축 완료 이미지를 `PostDraft`에
보존한다고 명시하지만, cubit·scenario 테스트 어디에도 그 검증이 없다.

**영향** 1번 결함이 99개 테스트를 모두 통과했다. 문서에 적힌 범위와 실제 범위가 벌어져
있어 테스트 통과가 근거로 쓰이지 못한다.

**수정** cubit 테스트는 `create(images: ...)`가 usecase에 같은 목록을 넘기는지,
scenario 테스트는 정규화 뒤에도 이미지 목록과 각 메타데이터가 유지되는지, 경계 테스트는
5장 허용 · 6장 거부를 검증한다.

## 확인 결과

- `cd app && flutter test test/features/feed test/features/post test/features/profile` — 통과 (99 tests)
- `cd app && flutter analyze` — 문제 없음

정적 분석과 단위 테스트는 통과한다. 다만 이미지 첨부의 입력 보존(1번)과 Storage · RPC
소유 경계(2번)는 현재 테스트 범위 밖이라 통과가 아무것도 보증하지 않는다.

## 조치

다섯 건 모두 고쳤다. 진행 현황은 `docs/status.md` 의 "코드 리뷰 — 2026-08-24" 절에 적었다.

| # | 조치 |
|---|---|
| 1 | `CreatePostScenario` 가 정규화한 본문과 원래 `images` 를 함께 넘긴다. 같은 자리에서 `PostPolicy.maxImageCount` 를 검증한다 |
| 2 | `20260824142714_verify_post_image_urls.sql` — `create_post_with_images()` 가 `url` 을 `post-images` 버킷·호출자 경로·객체 이름 세 조건으로 검증한다. `docs/schema.md` §5·§7 갱신 |
| 3 | `NicknameCheck` union + `ProfileCubit.checkNickname` (400ms 디바운스, 늦은 응답 무시). 편집 화면이 확인 중 / 사용 가능 / 중복을 입력창에 표시한다 |
| 4 | `docs/features/post/plan.md` · `docs/testing/features/post.md` 를 실제 경로(`{user_id}/{uuid}/{순서}`)와 `docs/schema.md` 문구에 맞췄다 |
| 5 | scenario 테스트 2건(첨부 보존 · 장수 경계), cubit 테스트 1건(목록 전달), 편집 화면 위젯 테스트 3건을 추가하고 테스트 범위 문서를 실제와 맞췄다 |

검증:

- `cd app && flutter test` — 통과 (272 tests, 리뷰 시점 대비 +13)
- `cd app && flutter analyze` — 문제 없음
- 2번 마이그레이션은 로컬 DB 에 적용해 여섯 경우(본인 경로 · 남의 경로 · 외부 URL ·
  다른 버킷 · 폴더만 · 이미지 없음)를 직접 확인했다
