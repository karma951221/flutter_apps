# F7 safety — 계획 (신고)

> [문서 허브](../../README.md) · [기획 F7](../../overview.md) · [스키마](../../schema.md) · [아키텍처](../../architecture.md)

> 상태: **완료 (신고)** · 작성 2026-08-24 · 검증 2026-08-25 ([구현 기록](history.md))
> 진행 상태의 단일 기준은 [진행 현황](../../status.md)이다.

## 범위

부적절한 **게시물 · 댓글 · 사용자**를 신고한다. 신고는 접수만 되고, 처리는 MVP에서
Studio 직접 조회로 한다 ([기획 F7](../../overview.md)).

**차단은 이번 범위가 아니다.** 기획 F7은 신고와 차단을 묶어 두었지만, 차단은 모든 조회
경로(`posts_with_author` · `post_comments_visible`)에 양방향 필터를 넣어야 해서 이미
동작하는 두 뷰를 건드린다. 신고는 새 테이블 하나로 끝나므로 회귀 위험이 다르다. 차단은
이 feature 안에 이어서 붙인다 — 그래서 폴더 이름이 `report`가 아니라 `safety`다.

## 확정한 결정과 근거

| 항목 | 결정 | 근거 |
|---|---|---|
| 대상 | **게시물 · 댓글 · 사용자** 셋 | 기획 그대로. 신고는 처음부터 세 종류를 다 받으므로 폴리모픽이 값을 한다 |
| 폴리모픽 | `target_type` + `target_id`, **FK 없음** | [기획 §7](../../overview.md)이 정한 유일한 예외 지점이다. FK를 포기하는 대가를 트리거가 메운다 |
| 사유 | **고정 목록 5개** (`spam` · `abuse` · `sexual` · `violence` · `other`) | 심사 가이드라인이 기대하는 범주를 덮으면서 시트가 한 화면에 들어간다. 운영이 Studio 조회라 집계 가능한 형태가 중요하다 |
| 상세 설명 | **선택 입력** `detail`, 항상 노출 | 사유만으로는 맥락이 안 남는다. '기타'일 때만 펼치면 스팸을 고른 사람이 설명을 못 남긴다 |
| 빈 상세 설명 | **`null`로 저장하고 빈 문자열은 DB가 거부** | `''`와 `null`이 섞이면 `where detail is not null`이 빈 행까지 끌고 온다. 저장 가능한 상태를 하나로 줄인다 |
| 상태 | **3개** (`pending` · `resolved` · `rejected`) | 운영이 Studio 직접 조회라 '검토 중'을 누가 언제 옮길지가 없다. 아무도 쓰지 않는 값을 만들지 않는다 |
| 중복 신고 | **1인 1회**, `unique (reporter_id, target_type, target_id)` | 대상별 신고자 수가 곧 신고 건수가 되어 운영 집계가 단순해진다 |
| 자기 신고 | **UI에서 가리고 트리거로도 막는다** | UI는 UX, 경계는 서버다. 다른 feature(댓글 길이·2단 제한)와 같은 원칙 |
| 신고 취소 | **없음** | `update` · `delete` 권한을 아예 주지 않는다. 필요해지면 정책과 GRANT를 더하는 마이그레이션 하나다 |
| 신고 *건수* 제한 | **없음** | `reports_once`는 같은 대상 재신고만 막는다. 한 사용자가 피드의 모든 게시물을 각각 한 번씩 신고하는 것은 막지 않는다. 운영이 Studio 직접 조회라 신고 대량 발생 자체가 눈에 띄고, 폴리모픽 대상 셋을 넘나드는 속도 제한은 스키마가 한 단계 더 복잡해진다. 남용이 실제로 보이면 시간창 기반 제한을 별도 마이그레이션으로 더한다 |
| 신고 후 화면 | **Snackbar만.** 목록은 그대로 | 대상을 숨기는 것은 차단의 일이다. 신고에 숨김을 겸하게 하면 두 기능의 경계가 섞인다 |

## 데이터 · 권한

확정된 스키마의 단일 기준은 [스키마 문서](../../schema.md)다. 아래는 마이그레이션
`20260824140000_add_reports.sql`에 담을 의도이며, 적용 후 스키마 문서를 같은 커밋에서
갱신한다.

### 테이블

```sql
create table public.reports (
  id          uuid        primary key default gen_random_uuid(),
  reporter_id uuid        not null default auth.uid()
                          references public.profiles (id) on delete cascade,
  target_type text        not null,
  target_id   uuid        not null,
  reason      text        not null,
  detail      text,
  status      text        not null default 'pending',
  created_at  timestamptz not null default now(),

  constraint reports_target_type_valid check (
    target_type in ('post', 'comment', 'user')
  ),
  constraint reports_reason_valid check (
    reason in ('spam', 'abuse', 'sexual', 'violence', 'other')
  ),
  constraint reports_status_valid check (
    status in ('pending', 'resolved', 'rejected')
  ),
  constraint reports_detail_length check (
    detail is null or char_length(btrim(detail)) between 1 and 500
  ),
  constraint reports_not_self_user check (
    not (target_type = 'user' and reporter_id = target_id)
  ),
  constraint reports_once unique (reporter_id, target_type, target_id)
);
```

`text` + `check`는 `post_reactions_type_valid`와 같은 방식이다. 이 스키마는 enum 타입을
쓰지 않는다 — 값이 늘 때 `alter type`이 아니라 제약 교체로 끝난다.

`reports_detail_length`가 "빈 문자열이 저장되는 상태"를 없앤다. `detail`은 **`null`이거나,
공백을 걷어내고 1자 이상**이다. 앱도 짝을 맞춰 빈 입력에는 `null`을 보내므로 정상 경로에서
이 제약에 걸릴 일은 없다. 제약은 안전망이다.

`reports_not_self_user`는 컬럼 두 개만 보면 판정되는 유일한 자기 신고라 CHECK로 막는다.
게시물·댓글은 작성자를 알려면 다른 테이블을 읽어야 하므로 트리거가 맡는다.

### 인덱스 — 운영 조회용이다

```sql
create index reports_target_idx on public.reports (target_type, target_id);
create index reports_status_created_at_idx
  on public.reports (status, created_at desc);
```

앱에는 목록 화면이 없다. 두 인덱스는 Studio에서 "이 게시물이 몇 번 신고됐나"와
"미처리 신고를 오래된 순으로"를 보기 위한 것이다. `unique (reporter_id, ...)` 제약의
인덱스가 신고자 기준 조회를 덮으므로 따로 만들지 않는다.

### 대상 검증 트리거 `enforce_report_target()`

폴리모픽이라 FK가 없다. FK가 해주던 일(존재하는 대상인가)과 정책이 못 하는 일(내 것이
아닌가)을 BEFORE INSERT 트리거가 함께 본다.

| `target_type` | 검사 |
|---|---|
| `post` | `posts`에 있고 `deleted_at is null`. `author_id`가 신고자면 거부 |
| `comment` | `post_comments`에 있고 `deleted_at is null`. `author_id`가 신고자면 거부 |
| `user` | `profiles`에 존재. 자기 자신은 `reports_not_self_user`가 이미 막았다 |

**`security definer`에 `set search_path = ''`가 필요하다.** 트리거가 읽는 컬럼은
`author_id`와 `deleted_at` 뿐이라 실제로는 `post_comments`의 컬럼 GRANT와
`post_comments_select_visible` 정책만으로도 invoker 권한으로 읽힌다 — "`content`를
못 읽어서"는 아니다. `security definer`는 미래에 컬럼 GRANT가 바뀌어도 이 트리거가
계속 옳게 동작하게 하는 방어적 설계로 둔다. `handle_new_user()`와 같은 형태이고,
모든 객체를 스키마까지 적는다. 자세한 경위는 [구현 기록](history.md)에 있다.

거부 문구는 `enforce_comment_depth()`처럼 **사용자에게 그대로 보여줄 한국어**로 던진다.

```text
신고할 대상이 없습니다
내 게시물은 신고할 수 없습니다
내 댓글은 신고할 수 없습니다
```

`SupabaseErrorMapper._constraintFrom`에 이 문구들과 `reports_once`(중복 신고),
`reports_detail_length`(설명 길이)를 등록한다. 등록하지 않으면 `23505` · `23514`의
기본 문구로 덮여 원인이 사라진다.

### RLS

```sql
alter table public.reports enable row level security;

-- 조회: 본인 신고만. 남이 무엇을 신고했는지는 누구도 볼 수 없다
create policy "reports_select_own"
  on public.reports for select to authenticated
  using ((select auth.uid()) = reporter_id);

-- 삽입: 본인 것만
create policy "reports_insert_own"
  on public.reports for insert to authenticated
  with check ((select auth.uid()) = reporter_id);
```

UPDATE · DELETE 정책은 두지 않는다. 신고는 취소되지 않고, `status` 변경은 Studio
(`service_role`)의 일이다.

### GRANT

```sql
grant select on public.reports to authenticated;
grant insert (target_type, target_id, reason, detail)
  on public.reports to authenticated;
```

`reporter_id` · `status`에 INSERT를 **주지 않는 것**이 위조를 막는 방법이다.
`reporter_id`는 `default auth.uid()`로 DB가 채우고, `status`는 항상 `pending`으로
시작한다. 정책으로 막는 것보다 확실하다 — [스키마 §2](../../schema.md)의 규칙 그대로다.

`anon`에는 아무 권한도 주지 않는다. 신고는 로그인한 사용자만 한다.

## usecase

```
features/safety/
├── domain/
│   ├── entity/report_target.dart     sealed: post(id) / comment(id) / user(id)
│   ├── entity/report_reason.dart     enum 5개 + 화면 라벨
│   ├── report_policy.dart            detail 최대 500자 · trim · 빈 값은 null
│   ├── repository/report_repository.dart
│   └── usecase/
│       ├── safety_use_case.dart      ← presentation이 주입받는 facade
│       └── scenario/submit_report_scenario.dart
└── data/
    ├── datasource/{report_data_source,supabase_report_data_source}.dart
    ├── mapper/report_target_mapper.dart   ← target_type 문자열을 아는 유일한 곳
    └── repository/{report_repository_impl,report_repository_error_handler}.dart
```

| 동작 | 시그니처 |
|---|---|
| 신고 | `Future<Result<void>> submitReport(ReportTarget target, {required ReportReason reason, String? detail})` |

**쓰기 전용 feature다.** `select`는 본인 것만 열려 있지만 화면이 쓰지 않으므로 DTO도
커서도 목록 조회도 없다. 시나리오가 하나뿐이어도 facade(`SafetyUseCase`)를 두는 것은
다른 feature와 같은 모양을 유지하기 위해서다 — 차단이 붙으면 여기에 시나리오가 는다.

`ReportTarget`은 [`ReactionTarget`](../reaction/plan.md)과 같은 축이다. 대상이 늘면
변형 하나와 mapper 한 줄만 늘고, domain과 presentation의 나머지는 그대로다. 다만
`ReactionTarget`과 달리 변형이 셋이고, DB가 폴리모픽이라 `'post'` · `'comment'` ·
`'user'` 문자열을 아는 곳은 `report_target_mapper` 하나뿐이다.

`report_policy.dart`의 길이 검증과 빈 값 정규화는 UX이고 **최종 판정은 DB의 CHECK다.**
자기 신고를 UI에서 가리는 것도 UX이고, 경계는 트리거다.

## 화면

새 화면(라우트)은 없다. 기존 세 곳에 진입점이 붙고, 시트가 하나 뜬다.

| 화면 | 지금 | 바뀐 뒤 |
|---|---|---|
| `post_tile` | 내 글일 때만 `PopupMenuButton` (수정 · 삭제) | 항상 메뉴. 내 글이면 수정 · 삭제, 남의 글이면 신고 |
| `comment_tile` | 내 댓글일 때 삭제 `IconButton` | 같은 자리에 메뉴. 내 댓글이면 삭제, 남의 댓글이면 신고. 삭제된 댓글은 메뉴 없음 |
| `profile_page` | 메뉴 없음 | **타인 프로필**의 AppBar에 메뉴 → 신고 |

세 곳이 같은 모양을 쓰므로 `design_system/widget/app_overflow_menu.dart`로 올린다
([CLAUDE.md 규칙 4](../../../CLAUDE.md)의 "반복 사용" 조건). 아이콘 · 툴팁 · 모양은
공통이고 항목만 각자 넘긴다.

`comment_tile`의 삭제는 아이콘 한 번에서 메뉴 한 단계 뒤로 물러난다. 세 진입점의 모양을
맞추는 값이 그 한 단계보다 크고, 삭제가 되돌릴 수 없는 동작이라 한 단계 뒤에 두는 편이
안전하다.

### `ReportSheet`

`showModalBottomSheet` 하나다.

| 구성 | 하는 일 |
|---|---|
| 사유 5개 | 라디오 목록. 선택 전에는 제출 버튼이 잠긴다 |
| 상세 설명 | **항상 보이는 선택 입력.** 500자 카운터. 비면 `null`로 보낸다 |
| 제출 | `AppButton.primary`. 제출 중에는 시트 전체가 잠긴다 |

`ReportCubit`이 시트의 상태(선택된 사유 · 제출 중 · 실패)를 소유한다. auth의
`SubmitState`는 그 feature 전용이므로 재사용하지 않고 `ReportState`를 따로 둔다.

성공하면 시트를 닫고 `AppSnackBar.show`로 "신고가 접수되었습니다". 실패하면 시트를
열어 둔 채 `Failure.message`를 보여준다 — 중복 신고나 삭제된 대상이 여기로 온다.

## 다른 feature에 미치는 변경

| 대상 | 변경 |
|---|---|
| `design_system` | `AppOverflowMenu` 추가 |
| `features/post` | `PostTile`이 남의 글에도 메뉴를 그린다. `onReport` 콜백 추가 |
| `features/comment` | `CommentTile`의 삭제 아이콘 → 메뉴. `onReport` 콜백 추가 |
| `features/profile` | 타인 프로필 AppBar에 메뉴 추가 |
| `features/feed` | `feed_page`가 safety를 import하고 `_report` 메서드를 갖는다. `PostTile`에 넘기던 `onEdit`·`onDelete`가 `isMine` 게이트를 탄다 |
| `core/data/mapper` | `SupabaseErrorMapper`에 신고 관련 문구 · 제약 등록 |
| [스키마 문서](../../schema.md) | `reports` 테이블 · 트리거 · 정책 절 추가 |

기존 뷰(`posts_with_author` · `post_comments_visible`)와 조회 경로는 **건드리지 않는다.**
차단이 붙을 때 비로소 두 뷰가 바뀐다.

## 완료 조건

- [x] 남의 게시물 · 댓글 · 프로필에서 신고 시트를 열고 접수한다 (위젯 테스트로 확인 —
      `ReportSheet` 제출 성공 경로)
- [x] 내 게시물 · 내 댓글에는 신고 메뉴가 보이지 않는다 (`post_tile` · `comment_tile`
      위젯 테스트로 확인)
- [x] 내 게시물 · 내 댓글 · 내 프로필 신고 삽입이 DB에서 거부된다 (로컬 Supabase 확인 —
      게시물 · 댓글은 `400` · 트리거 문구(`P0001`), 프로필은 `400` · `23514`
      (`reports_not_self_user`))
- [x] 같은 대상을 두 번 신고하면 "이미 신고한 항목입니다"가 뜬다 (로컬 Supabase 확인 —
      `23505` → `ReportRepositoryImpl`이 같은 문구로 변환)
- [x] 삭제된 게시물 · 댓글을 대상으로 한 신고 삽입이 거부된다 (로컬 Supabase 확인 —
      삭제된 게시물로 확인. 댓글도 트리거가 같은 조건절을 쓴다)
- [x] 존재하지 않는 `target_id`로 보낸 신고가 거부된다 (로컬 Supabase 확인 —
      `신고할 대상이 없습니다`)
- [x] 상세 설명을 비우면 `detail`이 `null`로 저장되고, 공백만 넣어도 `null`이거나
      거부된다 (앱 경로는 `ReportPolicy.normalizeDetail`이 `null`로 정규화 —
      단위 테스트. REST로 빈 문자열을 직접 보내면 `23514`로 거부 — 로컬 Supabase 확인)
- [x] `reporter_id` · `status`를 페이로드에 실어도 위조되지 않는다 (로컬 Supabase 확인 —
      둘 다 `42501`, 컬럼 GRANT가 없어서 막힌다)
- [x] 남의 신고는 조회되지 않는다 (로컬 Supabase 확인 — B의 select 결과에 A의 신고 없음)
