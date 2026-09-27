# F3 post — 구현 기록

> [트레이더 허브](../../README.md) · [아키텍처](../../../../../docs/architecture.md) · [스키마](../../schema.md) · [post 테스트 범위](testing.md)

> 2026-08-22 · feed 에서 게시물 CRUD 분리 · 소프트 삭제 · 커서 페이지네이션 전환

## 배경

이전 구현은 `features/feed` 하나가 목록 조회와 게시물 CRUD 를 모두 들고 있었고,
DB 는 `feed_posts` 테이블에 하드 삭제, 페이지네이션은 `range()` 기반 offset 이었다.
기획서가 못 박아둔 세 가지(소프트 삭제, 커서 페이지네이션, 명명 규칙)와 어긋난
상태였다. 이미지·반응·댓글이 붙기 전에 맞췄다.

## 설계 판단

### 테이블 이름은 `posts` — 화면 이름을 접두사로 쓰지 않는다

`feed_posts` 를 유지하면 자식 테이블이 `feed_post_comments` 가 된다. 같은 게시물이
피드·프로필·상세 화면에 모두 나타나므로 엔티티 이름이 특정 화면에 묶이면 안 된다.
자식은 **부모 테이블 이름(단수) + 자식** 규칙을 따른다 — `post_images`,
`post_reactions`, `post_comments`.

이 규칙이 확장성 걱정도 함께 푼다. 나중에 다른 엔티티에 댓글이 붙으면
`photo_comments` 를 **추가**하면 되고 기존 테이블은 손대지 않는다. 폴리모픽
(`target_type` + `target_id`)은 FK 와 RLS 를 포기하는 대가가 있어 `reports` 에만 쓴다.

### post 와 feed 는 domain entity 를 공유하고 DTO 는 따로 갖는다

feed 는 `features/post/domain/entity/post.dart` 를 그대로 쓴다. 같은 게시물을 두 벌로
표현하지 않기 위해서다 (feature 간 참조는 domain 까지 허용).

DTO 는 각자 만들었다. 지금은 모양이 같지만 피드는 곧 작성자 프로필과 반응·댓글 수를
조인해 받게 되고 단건 조회는 그렇지 않다. 지금 합치면 그때 되돌려야 한다.

### 목록 갱신은 재조회가 아니라 반영

작성·수정·삭제마다 피드를 다시 읽으면 스크롤 위치와 읽던 자리가 사라진다.
`PostCubit` 이 결과를 `Result` 로 돌려주고, 화면이 `FeedCubit.prependPost` /
`replacePost` / `removePost` 로 목록에 반영한다.

### 커서는 불투명 문자열

domain 과 presentation 은 커서 형식을 모른다. `(created_at, id)` 를 base64 로 감싸는
일은 `features/feed/data/cursor/` 안에서 끝난다. 백엔드가 커서 표현을 바꿔도 바깥
계층이 영향을 받지 않는다.

`limit + 1` 을 요청해 다음 페이지 존재 여부를 판단한다. 전체 개수를 세는 COUNT
쿼리가 필요 없다. **다음 커서는 잘라낸 항목이 아니라 실제로 돌려주는 마지막 항목
기준으로 만든다.** 잘못하면 페이지 경계에서 한 건이 조용히 사라진다.

---

## 겪은 문제

### 소프트 삭제를 클라이언트 UPDATE 로 할 수 없다

처음에는 `grant update (content, deleted_at)` 을 주고 앱이 `deleted_at` 을 직접
채우게 만들었다. REST 로 시험하니 막혔다.

```text
42501: new row violates row-level security policy for table "posts"
```

**PostgreSQL 은 UPDATE 의 SELECT 정책을 새 행에도 적용한다.** 조회 정책이
`deleted_at is null` 이므로, `deleted_at` 을 채우는 순간 새 행이 자기 조회 정책에
걸려 UPDATE 자체가 거부된다.

처음에는 PostgREST 가 내부적으로 붙이는 `RETURNING` 때문이라고 봤는데, psql 에서
`RETURNING` 없는 순수 UPDATE 를 돌려도 똑같이 실패했다. 조회 정책을 `using (true)`
로 바꾸면 통과하는 것으로 원인을 확정했다 (PostgreSQL 17.6).

두 가지 선택지가 있었다.

1. 조회 정책을 느슨하게 — `deleted_at is null or auth.uid() = author_id`.
   그러면 **작성자에게는 자기 삭제 글이 피드에 계속 보인다.** "DB 가 강제한다"는
   성질을 잃는다
2. `security definer` 함수로 삭제 경로를 하나만 연다

2번을 택했다. `soft_delete_post(post_id)` 하나만 열고 `deleted_at` 의 UPDATE 권한은
주지 않는다. 덤으로 **작성자가 자기 글의 `deleted_at` 을 null 로 되돌리는 경로**도
함께 막혔다.

`security definer` 가 RLS 를 우회하므로 함수 안의 `author_id = (select auth.uid())`
가 권한 경계 그 자체다. 이 조건을 빼면 아무나 남의 글을 지운다.

이 제약은 소프트 삭제를 쓰는 모든 테이블에 똑같이 적용된다. `post_comments` 도
전용 함수가 필요하다.

### `alter table ... rename` 은 딸린 객체 이름을 바꾸지 않는다

인덱스·제약·트리거·정책 이름이 `feed_posts_` 로 남는다. 그대로 두면 다음
마이그레이션에서 대상을 찾기 어려워지므로 `alter table ... rename constraint`,
`alter trigger ... rename to`, `alter policy ... rename to` 로 직접 맞췄다.

### 함수는 기본적으로 PUBLIC 에 EXECUTE 가 열려 있다

`create function` 만 하면 `anon` 도 호출할 수 있다. `revoke execute ... from public,
anon` 을 먼저 하고 `authenticated` 에만 부여했다.

### `input text` 로 한글을 넣을 수 없다

에뮬레이터 확인 중 `adb shell input text` 에 한글을 주면 NullPointerException 이
난다. ASCII 로만 입력했다. 한글 입력이 필요하면 IME 를 거치거나 클립보드를 쓴다.

---

## 검증

로컬 Supabase 에 REST 로 확인한 것:

- 작성 시 `author_id` 미전송 → DB `default auth.uid()` 로 채워짐
- `author_id` 위조 시도 → 403
- `deleted_at` 직접 UPDATE → 42501 차단
- 하드 DELETE → 권한 없음
- 남의 글 삭제 → `false`, 대상 글은 그대로 보임
- 본인 글 삭제 → `true`, 작성자에게도 안 보임, DB 행은 잔존
- 재삭제 → `false` (삭제 시각이 뒤로 밀리지 않음)
- 비로그인 RPC 호출 → 401
- **커서 페이징** — `created_at` 이 동일한 게시물 3건을 넣고 2건씩 끊어 읽어도
  중복·누락 없음. offset 이었다면 깨지는 자리다

Android 에뮬레이터에서 확인한 것:

- 로그인 → 피드가 커서 순서대로 표시
- 삭제 → 목록에서 사라지고 DB 행은 `deleted_at` 만 채워짐 (재조회 없음)
- 작성 → 목록 맨 앞에 즉시 반영 (재조회 없음)
- 본문 카운터가 500자 기준으로 표시

자동화 테스트 범위는 [post 테스트](testing.md)와
[feed 테스트](../feed/testing.md)를 단일 기준으로 삼는다.

## 이미지 첨부 (2026-08-23)

`post_images`와 공개 Storage 버킷 `post-images`를 추가했다. 작성 화면은 최대 5장을
선택해 긴 변 1080px, WebP, 품질 80으로 준비하고 미리보기에서 개별 제거할 수 있다.
게시물을 먼저 만든 뒤 `{user_id}/{post_id}/{sort_order}.webp`에 올리고 URL·치수·순서를
메타데이터로 저장한다. 따라서 작성 실패 뒤 Storage 객체가 고아가 될 수 있다는 기획의
MVP 트레이드오프는 그대로다.

피드 뷰는 이미지 메타데이터를 JSON 배열로 함께 내려주며, `PostTile`이 저장 순서대로
보인다. 수정 화면에서 기존 첨부 이미지를 재정렬·삭제하는 기능과 상세 캐러셀은 후속
상세 화면 범위로 남긴다.

## 2026-08-24 — 작성·수정 화면 개편

작성과 수정이 한 화면을 쓴다는 구조는 그대로 두고, 다른 점을 화면에 드러냈다.

- 제목과 버튼 라벨을 구분한다 — "새 게시물 / 올리기" · "게시물 수정 / 저장"
- 사진 첨부는 **작성에만** 그린다. 수정은 본문만 바꾸므로(`update_post_scenario`)
  첨부 버튼을 그리면 저장되지 않을 동작을 권하는 셈이다
- 최대 장수를 화면이 다시 적지 않는다. `PostPolicy.maxImageCount` 를 새로 두고
  DB 의 `post_images_sort_order_range`(0..4)와 같은 값임을 주석으로 묶었다
- 글자 수를 직접 그린다. 기본 카운터는 "얼마 안 남았다"를 색으로 말하지 못한다
- 쓰던 내용을 두고 나가려 하면 `PopScope` 로 한 번 묻는다. 아무것도 쓰지 않았으면
  묻지 않는다 — 잘못 들어왔다 나가는 흔한 경우까지 붙잡으면 성가시다
- 저장 중에는 나갈 수 없다. 화면이 사라진 뒤 결과가 오면 돌려줄 곳이 없다

`PostTile` 은 사진이 **한 장일 때 가로를 채우고 원본 비율을 지킨다.** 목록에는 한 장
짜리가 대부분인데 정사각형으로 자르면 세로 사진이 크게 상한다. 여러 장일 때는 카드
높이를 예측 가능하게 두는 쪽이 중요해서 정사각 썸네일 가로 스크롤을 유지했다.
치수는 목록 조회가 함께 내려주므로 이미지를 받기 전에 자리를 잡을 수 있다.

## 2026-09-06 — 글자 수 카운터는 상한 50자 이내에서만

[리뷰](../../../../../ux-psychology-review.md) 7번. 처음부터 `0 / 500` 을 보여주면 500 이 기대
길이로 읽힌다 — 첫 숫자가 기준이 된다. 남은 글자가 50 이하일 때부터 그리고, 색 경고
임계(20)는 그대로다. `minLines` 도 6 → 3. 검증: `post_editor_page_test` 두 경계(보이지
않음 · 450자에서 보임).
