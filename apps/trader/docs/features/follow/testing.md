# follow 테스트

> [테스트 가이드](../../../../../docs/testing/README.md) · [계획](plan.md) · [진행 현황](../../status.md)

```bash
cd app && flutter test test/features/follow
```

권한 경계와 동시성은 프로젝트 루트에서, `supabase start` 후에 돌린다.

```bash
python3 supabase/tests/follow_rls_check.py
python3 supabase/tests/follow_block_race_check.py
```

## 단위 · 위젯

| 대상 | 경우 | 확인 |
|---|---|---|
| `FollowCursor` | 왕복 | 인코딩한 커서를 그대로 되돌린다 |
| `FollowCursor` | null · 빈 문자열 | 첫 페이지를 뜻하는 null 이다 |
| `FollowCursor` | 지역 시각 | UTC 로 실어 보낸다 |
| `FollowCursor` | 깨진 값 · 구분자 없음 | `ValidationFailure` 를 던진다 |
| 시나리오 | 팔로우 · 해제 | 저장소로 그대로 넘어간다 |
| 시나리오 | 방향 | 팔로워는 팔로워 조회만, 팔로잉은 팔로잉 조회만 부른다 |
| 시나리오 | 빈 사용자 id · 범위 밖 개수 · 공백 커서 | 저장소를 부르지 않고 `ValidationFailure` |
| `FollowRepositoryImpl` | 페이지 판정 | 한 개를 더 요청하고, 넘치면 잘라내며 커서는 잘라낸 뒤 마지막 항목이다 |
| `FollowRepositoryImpl` | 커서 | 받은 문자열을 해석해 넘기고, 깨졌으면 `Err` 로 돌려준다 |
| `FollowActionCubit` | seed | 프로필 조회 결과(관계 · 팔로워 수)를 그대로 심는다 |
| `FollowActionCubit` | 팔로우 · 해제 | 버튼과 팔로워 수가 **함께** 먼저 움직인다 |
| `FollowActionCubit` | 실패 | 누르기 전 값으로 되돌리고 실패를 남긴다 |
| `FollowActionCubit` | 연타 | 진행 중이면 다시 부르지 않는다 |
| `FollowActionCubit` | 경계 | 팔로워 수가 0 아래로 내려가지 않는다 |
| `FollowListCubit` | 방향 | 방향에 맞는 조회만 부른다 |
| `FollowListCubit` | 페이지 | 다음 커서를 이어 붙이고, 없으면 더 읽지 않는다 |
| `FollowListPage` | 목록 · 빈 상태 | 방향에 따라 제목과 빈 안내가 달라진다 |
| `FollowListPage` | 실패 | 다시 시도로 복구된다 |
| `ProfilePage` | 남의 프로필 | 팔로우 버튼과 팔로워 · 팔로잉 수가 보인다 |
| `ProfilePage` | 상태 3가지 | 팔로우 / 팔로잉 / 맞팔로우 |
| `ProfilePage` | 낙관적 갱신 | 누르면 수가 먼저 늘고, 실패하면 되돌리며 오류를 알린다 |
| `ProfilePage` | 내 프로필 | 팔로우 버튼이 없고 수만 보인다 |
| `ProfilePage` | 차단한 상대 | 팔로우 버튼을 그리지 않는다 |
| `FeedPage` | 탭 | 전체 · 팔로잉 두 탭을 보여주고, 옮기면 팔로잉 소스로 다시 읽는다 |
| `FeedCubit` | 소스 | 팔로잉을 본 뒤에도 프로필 목록은 전체 소스로 읽는다 |
| `FeedCubit` | **탭 전환 경합** | 앞 소스의 늦은 첫 페이지·다음 페이지 응답을 버린다 |
| `FeedCubit` | 팔로잉 탭 작성 | 내 글은 팔로잉 목록에 넣지 않는다 (자기 팔로우가 없으므로 새로고침하면 사라진다) |
| `FeedPage` | 팔로잉 탭 실패 | '다시 시도'가 전체가 아니라 팔로잉을 다시 읽는다 |
| `FollowListCubit` | **새로고침 경합** | 뒤늦게 온 다음 페이지를 붙이지 않고 버린다 |
| `ProfilePage` | 같은 프로필 재조회 | 팔로워 수와 버튼이 새 값으로 갱신된다 |
| 시나리오 | 빈 사용자 식별자 | 팔로우·해제도 저장소를 부르지 않는다 |
| `SupabaseFollowDataSource` | 지울 행이 없는 해제 | 성공으로 둔다 — 트리거가 상대의 차단만으로도 행을 지운다 |

## 권한 경계 (`supabase/tests/follow_rls_check.py`)

실제 JWT + REST 로 28건을 확인한다. mock 으로는 드러나지 않는 것들이다.

- 팔로우 · 중복(PK 충돌) · 자기 팔로우(CHECK) · `follower_id` 위조(GRANT 없음)
- 조회는 공개다 — 제3자도 비로그인도 그래프를 읽는다
- 남의 팔로우 행은 지워지지 않는다 (`follows_delete_own`)
- `profile_details` — 수는 조회자와 무관하고 관계 둘은 조회자 기준이다.
  비로그인은 수만 보고 관계는 false 다
- 목록 뷰의 방향이 서로 반대다
- 팔로잉 피드는 팔로우한 사람의 글만, 전체 피드는 둘 다
- **차단** — 차단하면 양방향 엣지가 사라지고, 차단 상태에서는 양쪽 모두
  팔로우가 거부된다. 차단한 상대는 제3자의 목록에서도 가려지지만 같은 목록이
  다른 사람 눈에는 그대로다. 팔로워 수는 차단과 무관하게 같다
- 탈퇴하면 그 사람의 팔로우 행이 cascade 로 사라진다

## 동시성 (`supabase/tests/follow_block_race_check.py`)

psql 세션 둘로 트랜잭션을 겹친다. REST 로는 재현되지 않는 결함이다.

- 팔로우가 열려 있는 중에 차단해도 엣지가 남지 않는다
- 차단이 열려 있는 중에 건 팔로우는 방향 중립 문구로 거부된다
- 거부된 뒤에도 엣지가 남지 않는다
- 차단이 없으면 팔로우는 그대로 된다

락과 가드를 빼면 4건이 모두 실패한다 — 검사가 공허하지 않음을 그렇게 확인했다.

## 알아둘 것

- 위젯 테스트는 `locale: Locale('ko')` 를 고정한다. `ko` 가 ARB template 이라
  원문이 곧 기대값이다 ([다국어 계획](../preferences/plan-language.md))
- '팔로잉' 문구는 프로필에서 **버튼과 수 라벨 두 곳**에 나온다. 단언할 때
  `findsNWidgets(2)` 로 세는 이유다
- `FeedSource` 가 `getFeedPosts` 의 새 인자라, 피드를 mock 하는 테스트는
  `registerFallbackValue(FeedSource.all)` 이 필요하다
