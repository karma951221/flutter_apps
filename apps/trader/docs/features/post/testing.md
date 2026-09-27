# F3 post — 테스트 범위

> [테스트 가이드](../../../../../docs/testing/README.md) · [아키텍처](../../../../../docs/architecture.md) · [기획 F3](../../overview.md)

| 대상 | 시나리오 | 기대 결과 |
|---|---|---|
| `PostMapper` | `PostDto` 변환 | snake_case 컬럼을 읽어 domain `Post`로 손실 없이 변환된다. |
| `PostMapper` | `post_images` 조인 결과 | 스네이크 케이스(`sort_order`)를 읽어 받은 순서 그대로 `PostImage`로 옮긴다. |
| `PostMapper` | 이미지 없는 게시물 | `post_images` 키가 없으면 null 이 아니라 빈 목록이 된다. |
| `Post` extra codec | 이미지·판 요약 포함 Map 왕복 | 중첩 값까지 손실 없이 복원하고 어긋난 모양은 `null`로 거부한다. |
| `PostRepositoryImpl` | 작성 성공 | 작성 결과 DTO가 domain `Post`로 변환되어 `Ok`로 반환된다. |
| `PostRepositoryImpl` | 미인증(사용자 null) | 작성·삭제 모두 인증 실패 `Failure`를 담은 `Err`로 반환된다. |
| `PostRepositoryImpl` | 소프트 삭제 | 성공은 `Ok`, 대상 없음(또는 남의 글)은 `notFound`로 반환된다. |
| `CreatePostScenario` | 본문 정규화 | 앞뒤 공백을 제거한 본문으로 저장을 요청하고, 공백뿐인 본문은 저장하지 않는다. |
| `CreatePostScenario` | 길이 검증 | DB CHECK 제약과 같은 기준(500자)에서 막고, 최대 길이는 허용한다. |
| `CreatePostScenario` | 첨부 보존 | 본문을 정규화해도 첨부 이미지 목록과 각 메타데이터가 그대로 저장소에 전달된다. |
| `CreatePostScenario` | 장수 검증 | `PostPolicy.maxImageCount`까지 허용하고, 넘으면 저장하지 않는다. |
| CRUD scenario | 단건 조회 · 삭제 | 식별자를 저장소에 위임하고, 빈 식별자는 저장소를 호출하지 않는다. |
| CRUD scenario | 수정 | 공백을 제거한 본문으로 요청하고, 빈 본문으로는 수정하지 않는다. |
| `PostCubit` | 제출 상태 | 작성 중 제출 상태를 켜고 끝나면 되돌린다. 제출 중 재요청은 usecase를 호출하지 않는다. |
| `PostCubit` | 실패 / 수정·삭제 | 실패는 상태에 남긴다. 수정과 삭제는 usecase에 위임한다. |
| `PostCubit` | 이미지 첨부 작성 | 최대 5개의 압축 완료 이미지가 `PostDraft`에 보존되어 작성 usecase에 전달된다. |
| 로컬 Supabase | 이미지 RLS·Storage RLS | 본인만 `{user_id}/{uuid}/...`에 업로드하고 해당 게시물의 메타데이터를 추가할 수 있다. |
| 로컬 Supabase | `create_post_with_images` 직접 호출 | 본인 경로의 `post-images` URL만 통과한다. 남의 경로·다른 버킷·외부 URL·객체 없는 폴더 경로는 거부한다. |
| `PostEditorPage` | 작성 / 수정 | 제목과 버튼 라벨이 구분된다 ("새 게시물·올리기" / "게시물 수정·저장"). |
| `PostEditorPage` | 수정 화면 | 사진 첨부를 그리지 않는다 — 수정은 본문만 바꾼다. |
| `PostEditorPage` | 글자 수 | 남은 글자가 50자 이하일 때만 `PostPolicy.maxContentLength` 기준으로 보인다. 그 전에는 카운터를 그리지 않는다. |
| `PostEditorPage` | 사진 추가 버튼 | 최대 장수를 라벨에 적는다 (`PostPolicy.maxImageCount`). |
| `PostEditorPage` | 빈 본문 | 저장을 시도하지 않는다. |
| `PostEditorPage` | 쓰던 내용을 두고 나가기 | 한 번 묻는다. 아무것도 쓰지 않았으면 묻지 않는다. |
| `PostEditorPage` | 저장 성공 | 결과 게시물을 들고 목록으로 돌아간다. |
| 게시물 수정 라우터 | Map extra | `PostEditorPage.post`로 복원하고 어긋난 Map은 `null`로 전달한다. |

`PostTile`의 메뉴가 `isMine`에 따라 수정·삭제/신고 중 옳은 항목만 보여주는지는 신고
진입점 테스트라 [safety 테스트 문서](../safety/testing.md)의 "진입점" 절에 있다.

실행:

```bash
cd app
flutter test test/features/post
```

`soft_delete_post()` RPC와 RLS(작성자 본인만 수정·삭제)는 로컬 Supabase 통합
테스트로 추가 검증한다 ([스키마 §5](../../schema.md)).
