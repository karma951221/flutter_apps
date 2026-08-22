# 소셜 피드 앱 — 기획서 초안

> [문서 허브](README.md) · [아키텍처](architecture.md) · [개발환경](setup.md) · [테스트 가이드](testing/README.md)

> 상태: **초안 v0.1** · 작성 2026-08-20 · 아직 확정 아님, 검토 후 수정 전제

---

## 1. 한 줄 정의

사용자가 글과 사진을 올리고, 서로 팔로우하며, 반응과 댓글로 소통하는 **모바일 소셜 피드 앱**.

## 2. 목표와 성공 기준

이 프로젝트는 **토이 프로젝트**다. 사용자 수나 성장은 목표가 아니다.

**성공 기준**: 인증 · 피드 · 이미지 업로드 · 소셜 그래프를 갖춘 앱을, **직접 만든 백엔드 위에서, 끝까지 동작하는 상태로 완성한다.**

이 기준을 명시적으로 못 박는 이유: 소셜앱을 사용자 수로 평가하면 개인 프로젝트는 거의 반드시 실패로 끝난다. 반면 "완성"을 기준으로 하면 달성 가능하고, 배우는 것(API 설계, 인증, 권한, 쿼리, 스토리지, 배포)이 그대로 남는다.

부차 목표: **백엔드의 인증·스키마·권한 모델을 직접 설계하고 검증하는 것**. 현재는
로컬 Supabase와 SQL 마이그레이션·RLS를 사용한다. 실제 스키마와 권한의 단일 기준은
[`supabase/migrations/`](../supabase/migrations/)이다.

## 3. MVP 범위

### 포함

| 영역 | 내용 |
|------|------|
| 인증 | 이메일 + 비밀번호 회원가입 / 로그인 / 로그아웃 / 자동 로그인 |
| 프로필 | 닉네임 · 자기소개 · 프로필 사진, 내 프로필 / 타인 프로필 |
| 게시물 | 텍스트 + 사진 여러 장 작성 · 수정 · 삭제 |
| 피드 | 전체 공개 피드 / 팔로잉 피드 (탭 전환) |
| 반응 | 좋아요 · 싫어요 |
| 댓글 | 댓글 + 대댓글 (**1단까지만**) |
| 소셜 | 팔로우 / 언팔로우 / 맞팔 표시 / 팔로워·팔로잉 목록 |
| 안전 | 신고 · 차단 |

### 제외 (v1 범위 밖)

구글 로그인, 이메일 OTP, 1:1 채팅, 푸시 알림, 해시태그·검색, 게시물 공유, DM, 커뮤니티/그룹, 다크모드 외 테마, 다국어.

> **구글 로그인 · 이메일 OTP는 v1.1에서 재검토.** 아키텍처는 인증 방식이 추가될 수 있게 열어둔다 (§9 참조).

### 범위에 대한 솔직한 평가

이 범위는 엄밀히 말해 "MVP"가 아니라 **작은 인스타그램**이다. 기능 간 결합도가 낮아 단계별로 쪼개면 완주 가능하지만, 한 번에 다 만들려 하면 중간에 멈춘다. §8의 단계 구분을 반드시 지킬 것.

## 4. 기술 스택

### 4.1 확정

| 영역 | 선택 | 비고 |
|------|------|------|
| 앱 | **Flutter** | |
| 상태관리 | **bloc** | |
| 모델 · 불변객체 | **freezed** + json_serializable | |
| 의존성 주입 | **get_it + injectable** | |
| 로컬 DB | **drift** | 2단계 이후 도입 — §4.2 |
| 토큰 · 비밀 저장 | **flutter_secure_storage** | Supabase 세션 저장소로 연결 — §4.3 |
| 단순 설정 | shared_preferences | 테마, 마지막 탭 등 |
| 이미지 | image_picker + flutter_image_compress | 압축 필수 — §4.5 |
| 코드 생성 | **build_runner** | freezed · injectable · drift 공용 |
| 백엔드 | **Supabase** | 개발은 로컬 Docker — §4.4 |
| DB | PostgreSQL (Supabase) | |
| 스토리지 | Supabase Storage | §4.5 |

### 4.2 로컬 DB는 drift 하나만

Hive와 Isar는 **원 개발자가 유지보수를 중단**한 상태다 (각각 `hive_ce`, `isar_community` 커뮤니티 포크로 명맥 유지). 토이 프로젝트에서 유지보수 리스크를 떠안을 이유가 없다. drift는 활발히 유지보수되고, build_runner 기반이라 코드 생성 파이프라인이 통일되며, Supabase(Postgres)와 같은 SQL 모델이라 인지 부담이 낮다.

**도입 시점은 2단계 이후.** 1단계에서 로컬 DB가 필요한 곳은 "오프라인 피드 캐시"뿐이고, 이는 앱 완성의 필수 조건이 아니다. 역할별로 하나씩만 쓴다:

- 토큰 · 비밀 → `flutter_secure_storage`
- 단순 키-값 설정 → `shared_preferences`
- 구조화된 캐시 → `drift` (2단계~)

### 4.3 Supabase 세션은 secure storage로 옮긴다

`supabase_flutter`는 기본적으로 세션(access/refresh token)을 **SharedPreferences에 평문으로** 저장한다. 토큰은 비밀이므로 `Supabase.initialize`에 커스텀 `LocalStorage` 구현을 넘겨 `flutter_secure_storage`를 쓰게 한다. 0단계에서 처리할 것.

### 4.4 로컬 Docker 개발환경

`supabase init` → `supabase start`로 Postgres · Auth(GoTrue) · Storage · Realtime · Studio가 로컬 컨테이너로 뜬다. 이 선택의 실질적 이득:

- **스키마 변경이 SQL 마이그레이션 파일로 버전 관리된다** (`supabase migration new`). RLS 정책도 SQL로 직접 작성하게 되므로, "백엔드를 배운다"는 부차 목표가 상당 부분 충족된다
- **로컬 메일함이 함께 뜬다** (Inbucket/Mailpit). 회원가입 확인 메일과 **비밀번호 재설정 메일을 SMTP 설정 없이 로컬에서 테스트할 수 있다** → §9 #2 참조
- 인터넷 없이 개발 가능, 무료 프로젝트 일시정지 문제 없음, 데이터 날려도 무해

**주의**: 컨테이너 여러 개가 떠서 **2~4GB RAM**을 쓴다. Docker Desktop을 켜둔 채 작업하게 되므로 발열·배터리를 감안할 것.

### 4.5 이미지: 압축은 타협 불가

Supabase 무료 티어는 스토리지 1GB, 전송량 월 5GB다. 원본 2MB 사진을 그대로 쓰면 금방 소진되지만, **긴 변 1080px · WebP · 품질 80으로 압축하면 약 150KB**가 되어 전송량 5GB로 3만 회 조회를 감당한다. 토이 프로젝트 규모에선 충분하다.

전송량이 실제로 문제가 되면 그때 **Cloudflare R2**(egress 과금 없음)로 옮긴다. 미리 하지 않는다 — 통합 편의(RLS 연동, signed URL)를 잃는 대가가 더 크다.

### 4.6 build_runner 부하

freezed · injectable · drift가 모두 build_runner를 쓴다. 파일이 늘면 전체 빌드가 느려지므로 개발 중에는 watch 모드를 상시 켜둔다:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

## 5. Feature 분해

| # | Feature | 역할 | 단계 |
|---|---------|------|------|
| F1 | **auth** | 회원가입 · 로그인 · 토큰 · 세션 유지 | 1 |
| F2 | **profile** | 프로필 조회 · 수정 · 프로필 사진 | 1 |
| F3 | **post** | 게시물 작성 · 수정 · 삭제 · 상세 | 1 |
| F4 | **feed** | 전체 피드 · 팔로잉 피드 · 페이지네이션 | 1 / 3 |
| F5 | **reaction** | 좋아요 · 싫어요 | 2 |
| F6 | **comment** | 댓글 · 대댓글 1단 | 2 |
| F7 | **safety** | 신고 · 차단 | 2 |
| F8 | **follow** | 팔로우 · 맞팔 · 목록 | 3 |

### 교차 관심사 (특정 feature 소유 아님)

| # | 이름 | 역할 |
|---|------|------|
| X1 | **app shell** | 라우팅 · 탭 네비게이션 · DI 조립 · 인증 게이트 · 스플래시 |
| X2 | **api client** | dio 설정 · 토큰 인터셉터 · 401 재시도 · 에러 → Failure 매핑 |
| X3 | **media** | 이미지 선택 · 압축 · presign 요청 · 업로드 · 진행률 |
| X4 | **design system** | 테마 · 색상 토큰 · 공통 위젯 (버튼, 아바타, 빈 상태, 에러 상태) |

---

## 6. Feature별 개발 항목

각 항목은 **앱**과 **서버**로 나눠 적는다. 서버 API는 시그니처 수준이며 상세는 각 feature의 `implementation.md`에서 확정한다.

### F1. auth — 인증

**사용자 스토리**
- 이메일과 비밀번호로 가입하고, 가입 시 닉네임을 정한다
- 로그인하면 앱을 껐다 켜도 로그인 상태가 유지된다
- 로그아웃하면 저장된 토큰이 지워진다

**서버 개발**
- `POST /auth/signup` — 이메일 중복 확인, 비밀번호 해싱(**bcrypt 또는 argon2, 평문 저장 절대 금지**), 프로필 동시 생성
- `POST /auth/login` — 자격 검증 → access token + refresh token 발급
- `POST /auth/refresh` — refresh token으로 access token 재발급, refresh 회전(rotation)
- `POST /auth/logout` — refresh token 무효화
- `GET /me` — 현재 사용자 정보
- JWT 검증 미들웨어 (이후 모든 보호 API가 사용)

**앱 개발**
- 로그인 / 회원가입 화면, 입력 검증 (이메일 형식, 비밀번호 최소 길이)
- 토큰을 `flutter_secure_storage`에 저장 (SharedPreferences 금지)
- 앱 시작 시 저장된 토큰으로 세션 복구 → 인증 게이트에서 분기
- dio 인터셉터: access token 자동 첨부, **401 → refresh → 원요청 1회 재시도**
- `AuthRepository` 인터페이스로 격리 (v1.1의 구글 로그인 · OTP 대비)

**주의**
- **비밀번호 재설정이 MVP에 없다.** 비밀번호를 잊으면 계정 복구가 불가능하다. 의도된 제외이며 v1.1 최우선 항목이다 (SMTP + 도메인 필요)
- 로그인 실패 시 "이메일이 없음"과 "비밀번호 틀림"을 **구분하지 않는다** (계정 존재 여부 노출 방지)
- 리프레시 토큰 동시 요청 시 중복 갱신 방지 (뮤텍스 or 단일 비행 처리)

---

### F2. profile — 프로필

**사용자 스토리**
- 내 닉네임 · 자기소개 · 프로필 사진을 수정한다
- 다른 사람의 프로필과 그 사람이 쓴 글 목록을 본다

**서버 개발**
- `GET /users/:id` — 프로필 + 게시물 수 + (3단계) 팔로워·팔로잉 수 + 내가 팔로우 중인지
- `PATCH /me/profile` — 닉네임 · 자기소개 · 아바타 URL
- `GET /users/check-nickname?value=` — 중복 확인
- `GET /users/:id/posts?cursor=` — 해당 사용자의 게시물

**앱 개발**
- 내 프로필 화면 / 타인 프로필 화면 (같은 위젯, 소유 여부로 분기)
- 프로필 편집 화면, 닉네임 중복 확인(디바운스)
- 프로필 사진 선택 → 압축 → 업로드 (X3 재사용)
- 프로필 내 게시물 그리드

**주의**
- 닉네임은 **DB 유니크 제약**으로 강제한다. 앱의 중복 확인은 UX일 뿐 경쟁 조건을 막지 못한다

---

### F3. post — 게시물

**사용자 스토리**
- 글과 사진 여러 장을 함께 올린다. 사진 순서는 내가 정한 대로 유지된다
- 내 글을 수정하거나 삭제한다

**서버 개발**
- `POST /uploads/presign` — 업로드용 임시 URL 발급 (개수 · content-type 검증)
- `POST /posts` — 본문 + 이미지 목록(url, width, height, sort_order)
- `GET /posts/:id`
- `PATCH /posts/:id` — **작성자 본인만**
- `DELETE /posts/:id` — **소프트 삭제** (`deleted_at`), 댓글·반응 보존
- 권한 체크: 모든 수정/삭제에서 `author_id == 현재 사용자` 검증

**앱 개발**
- 작성 화면: 텍스트 입력 + 이미지 다중 선택 + 순서 변경(드래그) + 개별 삭제
- 업로드 진행률 표시, 실패 시 재시도
- 게시물 상세 화면, 이미지 캐러셀 (인디케이터)
- 이미지 종횡비 처리 — **서버가 width/height를 저장하므로 앱은 로딩 전에 자리를 확보할 수 있다** (레이아웃 점프 방지)

**주의**
- 이미지 **최대 5장** (확정)
- 업로드는 성공했는데 게시물 생성이 실패하면 **고아 이미지**가 남는다. MVP에서는 방치하고, 나중에 정리 작업으로 처리 (완벽한 트랜잭션은 과설계)
- 본문 **최대 2000자** (확정)

---

### F4. feed — 피드

**사용자 스토리**
- 앱을 열면 최신 글이 시간순으로 보인다
- 탭을 바꿔 팔로우한 사람들의 글만 본다
- 아래로 내리면 계속 불러오고, 당겨서 새로고침한다

**서버 개발**
- `GET /feed/public?cursor=&limit=` — 최신순
- `GET /feed/following?cursor=&limit=` — 팔로우 대상만 (3단계)
- 응답에 각 게시물의 반응 수 · 댓글 수 · **내 반응 상태**를 포함 (N+1 쿼리 방지)
- 차단한 사용자의 게시물 제외 (F7 완료 후)

**앱 개발**
- 탭 2개 (전체 / 팔로잉)
- 무한 스크롤 + 당겨서 새로고침
- 게시물 카드 위젯 (F5·F6와 공유)
- 빈 상태 / 로딩 / 에러 상태 UI

**주의 — 커서 페이지네이션을 쓸 것**
`OFFSET` 기반 페이지네이션은 스크롤 중 새 글이 올라오면 **항목이 중복되거나 건너뛰어진다.** `(created_at, id)` 복합 커서를 쓴다. 이건 나중에 고치기 어려우므로 처음부터 제대로 한다.

---

### F5. reaction — 감정표현

**사용자 스토리**
- 게시물에 좋아요 또는 싫어요를 누른다. 다시 누르면 취소된다
- 좋아요를 누른 상태에서 싫어요를 누르면 좋아요가 해제된다

**서버 개발**
- `PUT /posts/:id/reaction` — body `{type: "like"|"dislike"}`, upsert
- `DELETE /posts/:id/reaction` — 취소
- 유니크 제약 `(user_id, post_id)` — **한 사용자는 게시물당 반응 하나**

**앱 개발**
- 좋아요 / 싫어요 버튼, 선택 상태 표시
- **낙관적 업데이트** — 탭 즉시 UI 반영, 실패 시 롤백

**주의 — 카운트 집계 방식**
매 조회마다 `COUNT(*)`를 하면 게시물이 늘수록 느려진다. 두 가지 방법:

- **(a) 실시간 COUNT + 인덱스** — 단순, 정확. **MVP는 이걸로 시작한다**
- **(b) `posts.like_count` 비정규화 컬럼 + 트리거** — 빠르지만 정합성 관리 필요

성능 문제가 실제로 관측되기 전에 (b)로 가지 않는다. YAGNI.

**싫어요 정책 (확정: 공개)**

좋아요와 동일하게 **개수를 공개한다.** 다수가 특정 글에 몰릴 때 괴롭힘 수단이 될 수 있다는 위험은 인지한 상태의 선택이다.

다만 운영 중 문제가 관측되면 **서버 변경 없이 되돌릴 수 있게** 만든다:
- API는 `dislikeCount`를 **항상** 응답에 포함한다
- **노출 여부는 앱이 판단한다** (원격 설정 또는 앱 업데이트로 전환)

이렇게 해두면 정책 변경이 앱 쪽 조건문 하나로 끝난다.

---

### F6. comment — 댓글

**사용자 스토리**
- 게시물에 댓글을 단다
- 댓글에 답글을 단다 (답글의 답글은 없다)
- 내 댓글을 삭제한다

**서버 개발**
- `POST /posts/:id/comments` — body `{content, parentId?}`
- `GET /posts/:id/comments?cursor=` — 부모 댓글 + 자식 댓글 함께
- `DELETE /comments/:id` — 소프트 삭제, **자식이 있으면 "삭제된 댓글입니다"로 표시**
- `parent_id`가 이미 자식 댓글이면 **거부** (2단 초과 방지)

**앱 개발**
- 댓글 목록 (부모 아래 자식 들여쓰기)
- 입력창, 답글 모드 표시 ("○○님에게 답글")
- 댓글 수 표시

**주의**
- **DB는 무한 depth를 담을 수 있게 설계하고, 제한은 앱과 API에서만 건다.** 나중에 다단계로 바꾸고 싶어져도 마이그레이션이 필요 없다
- 대댓글은 **부모 댓글 기준으로 최신순 정렬** (전체 최신순이면 대화 흐름이 깨진다)

---

### F7. safety — 신고 · 차단

> **이 feature는 선택이 아니다.** Apple App Store 심사 가이드라인 1.2는 사용자 생성 콘텐츠 앱에 신고 기능 · 차단 기능 · 신고 대응을 요구한다. 없으면 리젝된다. Google Play도 동일.

**사용자 스토리**
- 부적절한 게시물이나 댓글을 신고한다
- 특정 사용자를 차단하면 그 사람의 글과 댓글이 더 이상 보이지 않는다
- 차단 목록에서 차단을 해제한다

**서버 개발**
- `POST /reports` — `{targetType: post|comment|user, targetId, reason}`
- `PUT /users/:id/block` / `DELETE /users/:id/block`
- `GET /me/blocks` — 차단 목록
- **모든 조회 쿼리에 차단 필터 적용** — 피드, 댓글, 프로필, 검색
- 차단은 **양방향 숨김**: 내가 차단하면 상대도 내 글을 못 본다

**앱 개발**
- 게시물 · 댓글 · 프로필의 더보기 메뉴 → 신고 / 차단
- 신고 사유 선택 시트
- 설정 화면의 차단 목록 관리

**주의**
- MVP에서 신고 처리 운영은 **DB 직접 조회**로 한다. 관리자 화면은 과설계
- 차단 필터를 쿼리마다 빠뜨리기 쉽다. **공통 쿼리 헬퍼로 만들어 강제할 것**

---

### F8. follow — 팔로우

**사용자 스토리**
- 다른 사용자를 팔로우하고 해제한다
- 내 팔로워 / 팔로잉 목록을 본다
- 서로 팔로우 중이면 "맞팔로우"로 표시된다

**서버 개발**
- `PUT /users/:id/follow` / `DELETE /users/:id/follow`
- `GET /users/:id/followers?cursor=` / `GET /users/:id/followings?cursor=`
- 자기 자신 팔로우 **거부**
- 프로필 응답에 `isFollowing` · `isFollowedBy` 포함 → 맞팔 판정
- `follows` 유니크 제약 `(follower_id, followee_id)`

**앱 개발**
- 팔로우 버튼 (상태 3가지: 팔로우 / 팔로잉 / 맞팔로우), 낙관적 업데이트
- 팔로워 · 팔로잉 목록 화면
- 완료 후 F4의 팔로잉 피드 활성화

---

## 7. 데이터 모델

```
users            id, email(unique), password_hash, created_at
profiles         user_id(PK,FK), nickname(unique), bio, avatar_url, updated_at
posts            id, author_id(FK), content, created_at, updated_at, deleted_at
post_images      id, post_id(FK), url, width, height, sort_order
reactions        user_id(FK), post_id(FK), type(like|dislike), created_at
                 PK(user_id, post_id)
comments         id, post_id(FK), author_id(FK), parent_id(FK,null),
                 content, created_at, deleted_at
follows          follower_id(FK), followee_id(FK), created_at
                 PK(follower_id, followee_id)
blocks           blocker_id(FK), blocked_id(FK), created_at
                 PK(blocker_id, blocked_id)
reports          id, reporter_id(FK), target_type, target_id, reason,
                 status, created_at
refresh_tokens   id, user_id(FK), token_hash, expires_at, revoked_at
```

**필수 인덱스**
- `posts(created_at DESC, id DESC)` — 전체 피드 커서
- `posts(author_id, created_at DESC)` — 프로필 게시물
- `comments(post_id, parent_id, created_at)` — 댓글 조회
- `reactions(post_id, type)` — 반응 집계
- `follows(follower_id)` / `follows(followee_id)` — 양방향 조회

**설계 원칙**
- 삭제는 전부 **소프트 삭제**. 댓글·반응의 참조 무결성이 깨지지 않는다
- `users`와 `profiles`를 분리한다. 인증 정보(민감)와 공개 정보(자주 조회)의 수명주기가 다르다
- 비밀번호는 **해시만 저장**. 로그에도 남기지 않는다

---

## 8. 개발 단계

각 단계가 끝날 때마다 **실제로 동작하는 앱**이 나온다. 중간에 멈춰도 손에 뭔가 남는다.

| 단계 | 범위 | 완료 시점의 상태 |
|------|------|-----------------|
| **0** | Flutter 프로젝트 · Supabase 로컬 Docker · 첫 SQL 마이그레이션 · X2 api client · X4 design system · 배포 파이프라인 | 로컬 Supabase와 앱이 왕복 통신 |
| **1** | F1 auth · F2 profile · F3 post · F4 전체 피드 (+ X1, X3) | **앱이 실제로 돌아간다.** 가입하고 글 쓰고 남의 글을 본다 |
| **2** | F5 reaction · F6 comment · **F7 safety** | **스토어 배포 가능한 상태** |
| **3** | F8 follow · F4 팔로잉 피드 | **소셜앱 완성** — MVP 종료 |
| **4** | (v1.1) 비밀번호 재설정 · 구글 로그인 · 이메일 OTP · 푸시 알림 · 채팅 | 확장 |

**0단계를 건너뛰지 말 것.** 배포 파이프라인을 마지막에 만들면 "내 컴퓨터에선 되는데" 상태로 몇 주를 보내게 된다.

---

## 9. 확정 사항

| 항목 | 값 |
|------|-----|
| 앱 이름 | **daylog** |
| org | **karma** → 패키지 ID `com.karma.daylog` |
| 프로젝트 위치 | `~/Desktop/socialapp` |
| 싫어요 | **개수 공개** (전환 가능하게 설계 — F5) |
| 이미지 | 게시물당 **최대 5장** |
| 본문 | 최대 **2000자** |
| 백엔드 | **Supabase** (개발은 로컬 Docker) |
| 로컬 DB | **drift**, 2단계 이후 도입 |
| 비밀번호 재설정 | 기능은 MVP에 포함, **배포용 SMTP 연결만 배포 시점으로 연기** |

프로젝트 생성 명령:

```bash
flutter create --org com.karma --project-name daylog .
```

### 남은 판단

- **자체 백엔드 전환 시점** — MVP(3단계) 완주 후 검토. 그때를 대비해 X2 api client와 각 Repository를 인터페이스로 격리해둔다
- **아이콘 · 스플래시** — 0단계 이후 아무 때나

## 10. 다음 할 일

1. 0단계 착수 — `flutter create` · Supabase 로컬 Docker 기동 · 첫 SQL 마이그레이션
2. F1(auth)부터 feature 문서 작성 — 구현 기록은 `docs/features/<name>/`에, 테스트 범위와 실행 방법은 `docs/testing/features/<name>.md`에 작성
