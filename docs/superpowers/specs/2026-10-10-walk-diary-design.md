# walk — 일기(스토리 · 해시태그 · 위치 · 잠금) 설계

> 작성 2026-10-10 · 상태: **설계 승인 · 구현 계획 전** · 앱 문서 [walk 허브](../../../apps/walk/docs/README.md) ·
> 진행 현황 [walk status](../../../apps/walk/docs/status.md)

## 1. 목적

Life Tool(`apps/walk`)에 **개인 일기장**을 더한다. 알람 · 걷기와 연동하지 않는 독립 기능이다.
긴 글 한 편이 아니라 인스타 스토리처럼 **짧은 기록을 여러 개** 올리고, 여행 중에는 **위치를 태깅**해
여행일기처럼 쓴다. 같은 기록을 **줄글 · 피드 · 릴스** 세 모드로 돌아본다.

로그인 · 백엔드 없음, 안드로이드만, 모든 데이터는 폰 안(drift + 앱 문서 폴더)에만 있다.

## 2. 범위

**MVP**

- 하단 탭 [알람 · 걷기 · **일기** · 설정]
- 스토리(open/closed, 다시 열기, 기본 스토리 "일상") · 기록 작성/수정 · 휴지통
- 사진 · 짧은 영상 첨부(원본 복사 후 압축) · 현재 위치 태그(장소 이름 글자 표시)
- 해시태그(별도 칩 입력칸) · 검색 [글 · 스토리 · 해시태그 · 장소] + 추천
- 보기 모드 3종: 줄글 · 피드 · 릴스
- 일기 탭 잠금(PIN 또는 패턴, 폰 인증으로 재설정, 실패 시 24시간 차단)
- 설정: 잠금 · 다시 잠기는 시간 · 휴지통 기간 · 용량 표시 · "이 폰에만 저장" 안내

**다음 단계(이 문서 범위 밖)**

1. 스토리 지도 — 스토리의 기록 좌표를 시간순 핀 + 선으로
2. 전체 지도 — 모든 기록 좌표("내가 다녀온 곳")
3. 백업 내보내기(zip) · 가져오기
4. 영상 자르기(30초 초과 영상에서 구간 선택)

## 3. 결정 기록

| 결정 | 이유 |
|---|---|
| 일기는 알람 · 걷기와 연동하지 않는 독립 기능 | 사용자 결정 — 개인 일기장 |
| 하단 탭 4개 [알람 · 걷기 · 일기 · 설정] | 사용자 결정. 자주 쓰는 기능 |
| 기록 단위는 짧은 기록 여러 개(스토리형) | 사용자 결정 — 인스타 스토리처럼 짧게 여러 개 |
| **스토리**를 직접 만들어 기록을 묶는다. 기록은 **반드시 스토리 하나**에 속한다 | 사용자 결정. 기간 · 표지 · 재생 순서가 있어 여행일기에 맞다. 해시태그만으로 묶으면 기간 · 표지가 없고 오타로 쪼개진다 |
| 기본 스토리 **"일상"** 을 앱이 만들고 닫기 · 삭제 불가(이름 · 표지만 변경) | 스토리 없는 기록을 없애 목록이 섞이지 않게 한다 |
| 스토리는 `open`/`closed`. open 은 여러 개 동시 가능, `endedAt` 없이 둘 수 있다. 닫은 스토리는 다시 열 수 있다 | 사용자 결정 |
| 작성 시 스토리 기본값 = open 중 **가장 최근에 기록을 넣은** 스토리, 선택지는 open 만 | 사용자 결정 |
| 화면은 **스토리 바**로 스토리 하나씩 본다. "전체"는 모든 기록 날짜순 + 스토리 이름 표시. 닫힌 스토리는 "보관함" | 섞임 방지(사용자 승인) |
| 해시태그는 스토리와 별개. **별도 칩 입력칸**, 본문 `#` 는 글자 그대로 | 사용자 결정 |
| 영상 포함. 클립당 **30초 이하**, 기록당 사진+영상 **최대 10개**. 30초 초과는 거절 안내 | 사용자 결정(짧은 영상). 자르기는 다음 단계 |
| 사진·영상은 **원본을 복사해 압축**한 사본만 앱 폴더에 저장. 원본은 건드리지 않는다 | 사용자 결정 |
| 글만 있는 기록 허용. 글 · 미디어 모두 없으면 저장 불가 | 기본안 |
| 위치는 **작성 순간의 현재 위치**(기록마다 끄기 가능). MVP 는 장소 이름 글자만, 좌표는 저장 | 사용자 결정. 지도는 다음 단계 |
| 시각은 수정 가능. `createdAt`(불변) 과 `occurredAt`(수정 가능) 두 필드, "올린 시각으로 되돌리기" 제공 | 사용자 결정 — 잘못 넣은 시각을 되돌릴 수 있게 |
| 미래 시각 금지 | 일기 |
| 삭제는 **휴지통**. 자동 삭제 기간 설정(1 · **7** · 30일 · 안 함), 영구 삭제는 미디어 · 태그 연결까지 **연쇄 삭제**, 테스트로 보장 | 사용자 결정 |
| 검색 4종 [글 · 스토리 · 해시태그 · 장소]. 태그 · 장소는 **별도 테이블**에 저장해 추천에 쓴다. 본문은 LIKE | 사용자 결정 |
| 잠금은 **일기 탭만**, PIN(4자리) 또는 패턴 택1 | 사용자 결정. 알람 울림 · 걷기에 영향 없음 |
| 다시 잠기는 시간: 백그라운드 경과 후, 설정에서 즉시 · 30초 · **1분** · 5분 | 사용자 결정 |
| 잊었을 때: **폰 화면 잠금 인증**으로 재설정 → 실패 시 **24시간** 해제 시도 차단(영구 잠금 아님) | 사용자 결정 |
| 폰에 화면 잠금이 있어야 일기 잠금을 켤 수 있다 | 위 재설정 경로가 항상 존재하게 |
| 데이터 암호화 없음(앱 전용 저장소 보호에만 의존) | MVP 범위. 잠금은 화면 게이트 |
| 백업 없음, 설정에 "이 폰에만 저장" 안내 | 사용자 결정(MVP) |
| 용량은 표시만, 제한 없음 | 사용자 결정 |
| **스토리 삭제** = 그 스토리의 기록을 모두 휴지통으로 보내고 스토리 행 삭제. 그 기록을 복원하면 "일상"으로 | 추천안 적용 — 사용자가 다른 안을 고르지 않음. 구현 전 변경 가능 |
| 저장은 drift(SQLite) | 정렬 · 검색 · 조인 · 연쇄 삭제가 필요. pawlog 와 같은 선택 |

## 4. 구조

walk 의 기존 계층(`lib/{core,data,domain,presentation}` 아래 기능 폴더)을 따른다.

```text
domain/diary/        entity(Story · Entry · Media · Tag · Place · ViewMode) · repository 인터페이스 · usecase
domain/lock/         LockConfig · LockPolicy · LockRepository · DeviceAuth 인터페이스
data/diary/database/ drift DB · 테이블 · 매퍼
data/diary/          DriftDiaryRepository · FileMediaStore · 처리기(사진/영상) · CurrentPlaceSource
data/lock/           PrefsLockRepository · LocalAuthDeviceAuth
presentation/diary/  타임라인(스토리 바 + 보기 모드) · 작성/수정 · 스토리 관리 · 검색 · 태그/장소 모아보기 · 휴지통
presentation/lock/   잠금 게이트 · PIN 패드 · 3×3 패턴 · 잠금 설정
```

- 위치는 `packages/location`(geolocator 래퍼)을 재사용한다.
- 미디어 경로는 pawlog `FilePhotoStorage` 처럼 **루트 기준 상대 경로**로 저장한다.
- 공통 UI 는 `design_system` 위젯을 먼저 쓴다(CLAUDE.md UI 규칙). 시각 휠은 알람 탭의 `AlarmTimeWheel` 을 재사용한다.

**새 의존성** — 구현 계획 첫 단계에서 실제 동작 · 유지보수 상태를 확인한다.

| 용도 | 패키지 |
|---|---|
| DB | `drift` · `drift_flutter` · `drift_dev` |
| 사진·영상 고르기 | `image_picker` |
| 사진 압축 · EXIF 제거 | `flutter_image_compress` |
| 영상 압축 · 썸네일 | `video_compress`(대안 `light_compressor`) |
| 영상 재생 | `video_player` |
| 좌표 → 장소 이름 | `geocoding` |
| 폰 인증 | `local_auth` |
| 해시 | `crypto` |

## 5. 데이터

```text
stories     id, title, status(open|closed), startedAt, endedAt?, coverMediaId?,
            isDefault, lastPostedAt?, createdAt
entries     id, storyId(필수, FK), body, occurredAt, createdAt(불변), updatedAt,
            deletedAt?, placeId?(FK), lat?, lng?
media       id, entryId(FK, ON DELETE CASCADE), kind(photo|video), path(상대),
            thumbPath?, sortOrder, width, height, durationMs?, bytes
tags        id, name(정규화, UNIQUE), createdAt
entry_tags  entryId(FK, ON DELETE CASCADE), tagId(FK), PRIMARY KEY(entryId, tagId)
places      id, name(UNIQUE), createdAt
```

- `PRAGMA foreign_keys = ON`.
- **태그 정규화**: 앞뒤 공백 · 앞의 `#` 제거, 내부 공백 제거, 소문자. 빈 문자열 거절, 최대 30자.
- **장소**는 이름 단위로 한 행. 기록별 정확한 좌표는 `entries.lat/lng`. 다음 단계 지도는 기록 좌표를 쓴다.
- **사용 횟수**는 저장하지 않는다. `deletedAt IS NULL` 기록만 조인해 센다.
- 사용 기록이 0 인 `tags` · `places` 행은 추천 · 목록에서 숨기고, 영구 삭제(수동 · 비우기 · 자동 정리) 직후 정리한다.
- **표지**: `coverMediaId` 가 있고 그 미디어의 기록이 휴지통에 없으면 그것, 아니면 스토리의 가장 최근(`occurredAt`) 사진(영상이면 썸네일), 없으면 이니셜 색 원.
- `lastPostedAt` 은 그 스토리에 기록을 저장(새로 만들기 또는 스토리 이동)할 때 갱신한다.

### 5.1 삭제 · 휴지통

- 삭제 = `deletedAt` 설정. 행 · 파일은 그대로. 모든 목록 · 검색 · 추천 · 개수에서 숨긴다.
- 복원 = `deletedAt` 비움. id · 시각 · 스토리 · 장소 · 좌표 · 미디어(순서 · 경로 · 파일)는 삭제 전과 같다. `updatedAt` 은 바꾸지 않는다.
  원래 스토리가 삭제됐으면 "일상"으로 복원한다.
- 영구 삭제 = **한 트랜잭션**에서 `entries` 행 삭제(→ `media` · `entry_tags` 연쇄) + 쓰지 않는 `tags` · `places` 정리.
  **커밋 뒤** 파일(원본 크기 · 썸네일)을 지운다. 파일 삭제 실패는 무시하고 고아 청소가 회수한다.
  트랜잭션이 실패하면 파일을 건드리지 않는다.
- 자동 정리: 일기 탭 진입 시 `deletedAt + 기간 <= now` 인 기록을 영구 삭제. "안 함"이면 건너뛴다.
- 고아 청소: 앱 시작 시 미디어 폴더에서 `media` 에 없는 파일(휴지통 기록의 파일은 행이 있으므로 제외)과 오래된 임시 파일을 지운다.
- 스토리 삭제: 그 스토리의 기록을 모두 휴지통으로 보내고 스토리 행을 지운다. 기본 스토리는 거절.
  기록이 지워진 스토리 id 를 가리킬 수 없으므로(FK) 삭제 시점에 기록의 `storyId` 를 "일상"으로 옮긴다 — 복원하면 "일상"이다(위 복원 규칙과 같은 결과).

## 6. 화면 · 흐름

### 6.1 일기 탭

```text
┌───────────────────────────────┐
│ 일기                    🔍  ⋮  │   ⋮ = 스토리 관리 · 휴지통
│ (전체)(일상)(제주 여행)(출장) │+│   스토리 바: open 을 lastPostedAt 순, 끝에 보관함
│───────────────────────────────│
│ 제주 여행 · 10/7~ · 진행 중     │
│ [줄글 | 피드 | 릴스]            │
│   선택한 스토리의 기록만          │
│                          (＋) │
└───────────────────────────────┘
```

- 앱을 열면 마지막으로 보던 스토리와 보기 모드를 복원한다(prefs).
- **줄글**: 날짜 제목 아래 기록 글이 이어지고 미디어는 작은 썸네일.
- **피드**: 카드 세로 목록. 카드마다 미디어 좌우 넘김 + 글 · 위치 · 태그.
- **릴스**: 전체 화면. 세로로 다음 기록, 가로로 같은 기록의 다음 미디어. 영상 자동 재생, 글은 하단 오버레이.
- 보기 모드는 타임라인 · 스토리 · 태그 모아보기 · 장소 모아보기 모두에 같다.

### 6.2 작성 · 수정

```text
✕  새 기록                올리기
🕒 지금 · 10월 10일 (토) 오후 3:24  ›
📍 제주시 애월읍              ✕
📖 스토리: 제주 여행           ›
[사진·영상 추가]
본문
# 태그 칩 입력(추천)
```

- **시각**: 누르면 날짜 → 시각(알람 휠). 미래 불가. `occurredAt ≠ createdAt` 이면 "올린 시각으로 되돌리기".
- 시각을 바꾸면: 과거면 현재 위치를 빼고 **장소 이름 직접 입력**(추천 사용, 좌표 없음).
  바꾼 시각이 open 스토리 기간에 들면 그 스토리를 제안(여럿이면 `lastPostedAt` 최신), 없으면 "일상".
- **위치**: 진입 시 현재 위치를 구해 장소 이름을 붙인다. 권한 거부 · 실패면 위치 없음(오류 아님).
  오프라인이면 좌표만 저장하고, 일기 탭 진입 시 이름이 없는 기록(휴지통 제외)을 채운다.
- **미디어**: 고르면 바로 임시 폴더에 압축본을 만든다. 저장 시 정식 폴더로 옮기고, 취소하면 임시본을 지운다.
  수정 중 뺀 미디어의 파일은 저장 시 지운다. 사진: 긴 변 1600px(작으면 그대로), JPEG 85, EXIF 제거.
  영상: 최대 720p, 30초 초과 거절, 썸네일 생성.
- **태그**: 칩 입력, 기존 태그 추천, 중복 칩 무시.
- 저장 중 중복 탭 무시.

### 6.3 스토리 관리

- 만들기: 제목 · 시작일(기본 오늘, 과거 가능) · 종료일(선택). 종료일을 넣으면 closed 로 만든다.
- 지난 기간으로 만들면 그 기간의 "일상" 기록을 골라 옮기도록 제안한다.
- 닫기(`endedAt` = 지금 또는 선택일) · 다시 열기(`endedAt` 비움) · 이름 · 표지 변경 · 삭제(§5.1).

### 6.4 검색

- 상단 🔍. 입력칸 하나 + 탭 **[글 · 스토리 · 해시태그 · 장소]**. 입력 디바운스 300ms.
- 스토리 · 태그 · 장소: 입력 중 **추천**(포함 일치, 사용 횟수 → 최근 사용 순, 개수 표시). 입력 전엔 상위 N개.
  고르면 스토리는 그 스토리로 이동, 태그 · 장소는 스토리를 넘나드는 모아보기(보기 모드 3종).
- 글: `body LIKE '%q%' ESCAPE '\'` — 사용자 입력의 `%` · `_` · `\` 는 이스케이프. 결과는 `occurredAt` 최신순, 일치 부분 강조.
- 작성 화면의 태그 · 장소 입력도 같은 추천 쿼리를 쓴다.
- 모아보기 · 추천은 DB 변경 스트림을 구독해 추가 · 삭제 · 복원을 바로 반영한다.

### 6.5 휴지통

- 목록(남은 일수 표시) · 복원 · 영구 삭제 · 비우기. 모두 확인 다이얼로그(`AppConfirmDialog`).

## 7. 잠금

- 설정에서 켠다. 폰 화면 잠금이 없으면 켤 수 없다고 안내한다.
- 등록: PIN 4자리 또는 패턴(점 4개 이상, 건너뛴 가운데 점 자동 포함) 두 번 입력.
  저장은 랜덤 salt + 반복 해시(SHA-256 반복). 원문은 어디에도 저장하지 않는다.
- 끄기 · 방식 변경은 현재 PIN · 패턴 확인 뒤.
- 상태: 앱 시작 시 잠김. 해제 후 백그라운드로 간 시각을 기억하고, 돌아왔을 때 다시 잠기는 시간을 넘겼으면 잠근다.
  미디어 선택 · 카메라로 나간 동안은 예외. 시계가 거꾸로 가면 잠근다.
- 잠긴 동안 기록 위젯은 **트리에 없다**(덮어 가리는 것이 아님).
- 실패: 5회 틀리면 30초 차단(이후 횟수 초기화) → "잊어버렸어요" → 폰 인증(`local_auth`, 기기 PIN 허용)
  → 성공하면 새 PIN · 패턴 등록, **실패하면 24시간 모든 해제 시도 차단**. 사용자가 인증 창을 닫으면 실패로 치지 않는다.
  실패 횟수 · 차단 해제 시각은 재시작해도 유지한다.
- prefs 가 깨져 읽을 수 없으면 잠금을 끄지 않고 잠긴 채 폰 인증 재설정으로 유도한다.
- 알람 울림 화면은 일기 잠금과 무관하게 뜬다.
- **한계**: 데이터는 암호화하지 않는다. 기기 시계를 앞으로 돌리면 24시간 차단을 우회할 수 있다. 토이 프로젝트에서 받아들이는 위험이다.

## 8. 설정 탭 추가 항목

- 일기 잠금(켜기 · 방식 · 변경) · 다시 잠기는 시간 · 휴지통 자동 삭제 기간
- 용량: "사용 중 1.2GB (사진 340장 · 영상 52개, 휴지통 80MB 포함)"
- 안내: "기록은 이 폰에만 저장돼요. 앱을 지우면 함께 사라져요."

## 9. 테스트

경로는 `lib/` 와 1:1(`apps/walk/test/...`). 완료 시 `apps/walk/docs/testing.md` 에 같은 표 형식으로 옮긴다.

### 9.1 테스트 대역

| 대역 | 대신하는 것 | 이유 |
|---|---|---|
| `NativeDatabase.memory()` | drift DB | 쿼리 · 제약 · 트랜잭션 · FK 연쇄를 진짜 SQLite 로 |
| 임시 디렉터리 | 앱 문서 폴더 | 파일 생성 · 삭제를 실제로 |
| `FakeMediaProcessor` | 압축 플러그인 | 정해진 크기 · 길이의 결과 파일 작성, 실패 주입 |
| `Clock` 주입 | 현재 시각 | 휴지통 기한 · 다시 잠그기 · 24시간 · 미래 금지 |
| `FakeDeviceAuth` | `local_auth` | 성공 · 실패 · 취소 · 화면 잠금 없음 |
| `FakeLocationGateway` · `FakeGeocoder` | 위치 · 역지오코딩 | 권한 거부 · 오프라인 · 이름 없음 |

### 9.2 도메인

| 파일 | 대상 | 확인 |
|---|---|---|
| `domain/diary/entity/tag_name_test.dart` | 태그 정규화 | 공백 · `#` 제거 · 소문자 · 내부 공백 제거 · 빈 문자열 거절 · 최대 길이 |
| `domain/diary/entity/entry_time_test.dart` | 기록 시각 | 처음 `occurredAt == createdAt` · 미래 거절 · 되돌리기는 `createdAt` 으로 · 수정해도 `createdAt` 불변 |
| `domain/diary/entity/story_test.dart` | 스토리 상태 | 닫으면 `endedAt` · 다시 열면 비움 · 기본 스토리 닫기 · 삭제 거절 · `endedAt < startedAt` 거절 |
| `domain/diary/entity/media_limits_test.dart` | 첨부 제한 | 10개 허용 · 11개째 거절 · 30초 허용 · 30.001초 거절 · 사진+영상 합산 |
| `domain/diary/usecase/default_story_test.dart` | 기본 스토리 | `lastPostedAt` 최신 open · closed 제외 · 기록 없으면 "일상" · 동시각이면 최근 생성 |
| `domain/diary/usecase/story_suggestion_test.dart` | 시각 변경 시 제안 | 기간 안 open · 여럿이면 `lastPostedAt` 최신 · `endedAt` 없음은 시작 이후 전부 · 없으면 "일상" |
| `domain/lock/lock_policy_test.dart` | 잠금 규칙 | 4회 실패 차단 없음 · 5회째 30초 · 30초 뒤 횟수 초기화 · 폰 인증 실패 → 24시간 · 취소는 실패 아님 · 24시간 동안 PIN · 폰 인증 모두 거절 · 성공하면 횟수 0 |
| `domain/lock/relock_timer_test.dart` | 다시 잠그기 | 즉시 · 30초 · 1분 · 5분 경계(29.999초 열림 / 30초 잠김) · 미디어 선택 중 무시 · 시계 역행이면 잠김 |

### 9.3 데이터 — DB

| 파일 | 대상 | 확인 |
|---|---|---|
| `data/diary/database/diary_database_test.dart` | 스키마 · 시드 | 첫 실행에 "일상" 하나 · 다시 열어도 하나 · `foreign_keys` 켜짐 · `tags.name` · `places.name` UNIQUE |
| `data/diary/drift_diary_repository_entry_test.dart` | 기록 CRUD | 미디어 순서 유지 · 태그 · 장소 기존 행 재사용 · `lastPostedAt` 갱신 · 수정 시 `updatedAt` 만 바뀌고 `createdAt` 그대로 · `occurredAt` 정렬 · 스토리 이동 |
| `data/diary/drift_diary_repository_story_test.dart` | 스토리 | 생성 · 닫기 · 다시 열기 · 스토리 바 순서 · 보관함 · 표지 지정/자동 · 표지 미디어의 기록이 휴지통이면 자동 표지 · **스토리 삭제 = 기록 전부 휴지통 + 스토리 행 삭제** · 기본 스토리 삭제 거절 |
| `data/diary/drift_diary_repository_trash_test.dart` | 휴지통 · 연쇄 삭제 | 삭제 = `deletedAt` 만, 행 · 파일 그대로 · 타임라인 · 스토리 · 태그 · 장소 · 검색에서 숨김 · **영구 삭제 → `media` 0 · `entry_tags` 0 · 원본 크기 · 썸네일 파일 0** · 다른 기록의 파일 · 공유 태그 유지 · 비우기 · 자동 정리(기한 직전 남음 / 직후 삭제 / "안 함" / 1 · 7 · 30일) · 파일 삭제 실패해도 DB 커밋 → 고아 청소가 회수 · 트랜잭션 실패면 파일 그대로 |
| `data/diary/drift_diary_repository_trash_restore_test.dart` | 휴지통 → 복원 | 아래 §9.3.1 |
| `data/diary/drift_diary_repository_tag_sync_test.dart` | 해시태그 반영 | 아래 §9.3.2 |
| `data/diary/drift_diary_repository_place_sync_test.dart` | 장소 반영 | 아래 §9.3.3 |
| `data/diary/drift_diary_repository_search_test.dart` | 검색 | 본문 LIKE 부분 일치 · 대소문자 · **`%` · `_` · `\` 가 글자 그대로** · 휴지통 제외 · `occurredAt` 최신순 · 스토리 제목 · 태그 · 장소 결과는 스토리를 넘나듦 |
| `data/diary/drift_diary_repository_suggest_test.dart` | 추천 | 포함 일치 · 사용 횟수 → 최근 사용 · 휴지통 제외 횟수 · 0개 숨김 · 빈 입력이면 상위 N · 개수 값 |
| `data/diary/drift_diary_repository_place_fill_test.dart` | 장소 지연 채우기 | 좌표만 있는 기록 목록(휴지통 제외) · 채울 때 기존 `places` 재사용 · 같은 이름 하나로 |
| `data/diary/drift_diary_repository_usage_test.dart` | 용량 | 사진 · 영상 개수 · 바이트 합 · 휴지통 분 따로 |

#### 9.3.1 휴지통 → 복원

| 시나리오 | 확인 |
|---|---|
| 사진 2 + 영상 1 기록 삭제 | `media` 행 3개 그대로 · 원본 크기 3 + 썸네일 파일 그대로 · 경로 불변 |
| 복원 | 같은 id · 본문 · `occurredAt` · `createdAt` · 스토리 · 장소 · 좌표 동일 · **미디어 3개의 순서 · 종류 · 크기 · 길이 · 경로 동일** · 파일이 열림(길이 > 0) · `deletedAt` null |
| 복원 후 반영 | 원래 스토리 타임라인의 `occurredAt` 자리에 다시 · "전체"에도 · 검색 결과에 다시 |
| 표지 사진의 기록 삭제 → 복원 | 삭제 중 자동 표지 → 복원하면 지정 표지로 |
| 삭제된 동안 고아 청소 | 휴지통 기록의 파일은 지우지 않음 |
| 기한 경과(자동 영구 삭제) 뒤 복원 | `notFound` |
| 삭제된 동안 원래 스토리가 닫힘 → 복원 | 닫힌 스토리로 복원, 보관함에서 보임 |
| 삭제된 동안 원래 스토리가 삭제됨 → 복원 | "일상"으로 복원 |
| 삭제 · 복원 | `updatedAt` 불변 |

#### 9.3.2 해시태그 반영

| 시나리오 | 확인 |
|---|---|
| `#제주` 기록 1개 추가 | 목록 `#제주 1` · 모아보기에 그 기록 |
| 다른 스토리에 `#제주` 추가 | `#제주 2` · 모아보기에 두 스토리 기록이 `occurredAt` 순 |
| 하나를 휴지통으로 | `#제주 1` · 모아보기에서 사라짐 · 추천 순서 재계산 |
| 마지막 하나도 휴지통으로 | 목록 · 추천에서 사라짐 · `tags` 행은 남음 |
| 하나 복원 | `#제주 1` · 같은 `tags.id`(새 행 없음) |
| 수정으로 `#제주` → `#부산` | `#제주` -1 · `#부산` +1 · 옛 `entry_tags` 없음 |
| 영구 삭제 | `entry_tags` 삭제 · 다른 기록이 쓰는 태그 유지 · 쓰는 기록 없는 `tags` 행 정리 |
| 휴지통 기록만 가진 태그로 검색 | 결과 0 · 추천 없음 |

#### 9.3.3 장소 반영

| 시나리오 | 확인 |
|---|---|
| "애월읍" 기록 추가 → 같은 장소 하나 더 | `places` 행 1 · `애월읍 2` · 모아보기 2개 |
| 하나 휴지통 → 복원 | `애월읍 1` → `애월읍 2` · 같은 `places.id` · 좌표 그대로 |
| 모두 휴지통 | 목록 · 추천에서 숨김 · 행은 남음 |
| 수정으로 장소 변경 · 제거 | 이전 -1 · 새 +1 · 위치 끄면 `placeId` · `lat` · `lng` 모두 null |
| 오프라인 기록에 이름이 나중에 채워짐 | 그때부터 +1 · 같은 이름 장소와 합쳐짐 |
| 휴지통의 오프라인 기록 | 채우기 대상 제외(복원하면 다시 대상) |
| 영구 삭제 | 쓰는 기록 없는 `places` 행 정리 · 다른 기록이 쓰는 장소 유지 |

### 9.4 데이터 — 미디어 · 위치 · 잠금

| 파일 | 대상 | 확인 |
|---|---|---|
| `data/diary/media/file_media_store_test.dart` | `FileMediaStore` | 원본 바이트 그대로 · 결과는 상대 경로 · 임시 → 정식 이동 · 취소 시 임시본 삭제 · 처리 실패 시 `Err` + 임시 정리 · id 로 충돌 없음 · 고아 청소는 DB 에 없는 파일만 |
| `data/diary/media/image_compress_processor_test.dart` | 사진 처리 인자 | 긴 변 1600 · 품질 85 · EXIF 제거 옵션이 호출에 전달(mock 채널) · 작은 사진 확대 안 함 |
| `data/diary/media/video_compress_processor_test.dart` | 영상 처리 인자 | 720p · 길이 메타로 30초 초과 거절 · 썸네일 |
| `data/diary/location/current_place_source_test.dart` | 현재 위치 → 장소 | 권한 없음 → 위치 없음(오류 아님) · 오프라인 → 좌표만 · 이름 조합(시 · 구 · 동) · 타임아웃 |
| `data/lock/prefs_lock_repository_test.dart` | 잠금 저장 | 원문 PIN 이 prefs 어디에도 없음 · 같은 PIN 도 salt 로 해시 다름 · 검증 성공/실패 · 패턴 순서 구분 · 실패 횟수 · 차단 해제 시각 재시작 후 유지 · 깨진 prefs → 잠금 유지 + 재설정 유도 |
| `data/lock/local_auth_device_auth_test.dart` | 폰 인증 매핑 | 화면 잠금 없음 · 성공 · 실패 · 취소 · 기기 잠김 |

### 9.5 화면 — cubit

| 파일 | 대상 | 확인 |
|---|---|---|
| `presentation/diary/cubit/diary_timeline_cubit_test.dart` | 타임라인 | 마지막 스토리 복원 · 전환 · "전체" · 보기 모드 저장/복원 · 저장 · 삭제 · 복원 후 갱신 · 늦은 응답 버림 |
| `presentation/diary/cubit/entry_editor_cubit_test.dart` | 작성 · 수정 | 기본 스토리 · 과거 시각이면 위치 빼고 직접 입력 · 스토리 제안 · 되돌리기 · 11개째 거절 · 31초 거절 · 중복 칩 무시 · 빈 기록 저장 불가 · 중복 탭 무시 · 취소 시 임시 정리 · 뺀 미디어는 저장 시에만 삭제 |
| `presentation/diary/cubit/diary_search_cubit_test.dart` | 검색 | 탭 4개 · 디바운스 · 추천 vs 결과 · 빈 입력 · 늦은 응답 버림 · **추천이 떠 있는 동안 삭제 · 복원하면 개수 갱신** |
| `presentation/diary/cubit/tag_feed_cubit_test.dart` · `place_feed_cubit_test.dart` | 모아보기 | 열린 상태에서 추가 · 삭제 · 복원 시 목록 · 개수 갱신(변경 스트림) · 마지막이 사라지면 빈 상태 |
| `presentation/diary/cubit/trash_cubit_test.dart` | 휴지통 | 목록 · 복원 · 영구 삭제 · 비우기 · 남은 일수 |
| `presentation/lock/cubit/diary_lock_cubit_test.dart` | 잠금 게이트 | 꺼짐 → 열림 · 시작 시 잠김 · 해제 · 백그라운드 경과 → 잠김 · 미디어 선택 예외 · 30초 · 24시간 차단 상태와 남은 시간 · 폰 인증 성공 → 재설정 |
| `presentation/lock/cubit/lock_setup_cubit_test.dart` | 잠금 등록 | 화면 잠금 없으면 불가 · 두 번 불일치 · 패턴 3점 거절 · 방식 변경 · 끄기는 확인 후 |

### 9.6 화면 — 위젯

| 파일 | 대상 | 확인 |
|---|---|---|
| `presentation/diary/page/diary_tab_test.dart` | 일기 탭 | **잠긴 동안 기록 위젯이 트리에 없음** · 해제 → 타임라인 · 스토리 바 순서 · 보관함 |
| `presentation/diary/widget/view_modes_test.dart` | 줄글 · 피드 · 릴스 | 같은 데이터로 세 모드 렌더 · 피드 좌우 넘김 · 릴스 세로 페이지 + 가로 미디어 · "전체"만 스토리 이름 · 위치 · 태그 표시 · 미디어 없는 기록 |
| `presentation/diary/page/entry_editor_page_test.dart` | 작성 화면 | "지금" ↔ 날짜 · 되돌리기는 다를 때만 · 스토리 선택지 open 만 · 칩 추가/삭제 · 추천 · 위치 끄기 |
| `presentation/diary/page/diary_search_page_test.dart` | 검색 화면 | 탭 전환 · 추천 개수 · 본문 강조 |
| `presentation/lock/widget/pin_pad_test.dart` | PIN 패드 | 4자리 제출 · 지우기 · 차단 중 비활성 + 남은 시간 · 점 표시 |
| `presentation/lock/widget/pattern_lock_test.dart` | 패턴 | 드래그 연결 · 건너뛴 가운데 점 포함(1→3 이면 2) · 재방문 무시 · 3점 이하 오류 |
| `presentation/shell/page/main_shell_page_test.dart`(갱신) | 셸 | 탭 4개 · 순서 · 알람 울림은 일기 잠금과 무관 |
| `presentation/settings/page/settings_page_test.dart`(갱신) | 설정 | 잠금 행 · 다시 잠기는 시간 · 휴지통 기간 · 용량 · 안내 |

### 9.7 기기 시나리오(에뮬레이터 · 실제 폰)

| 시나리오 | 기대 |
|---|---|
| 갤러리 사진 3장 첨부 → 저장 | 사본 긴 변 ≤ 1600px · EXIF GPS 없음 · 갤러리 원본 그대로 |
| 40초 영상 첨부 / 25초 영상 첨부 | 거절 안내 / 720p 압축 · 릴스에서 재생 |
| 비행기 모드 기록 → 연결 후 일기 탭 | 장소 이름 없음 → 채워짐 |
| 잠금(1분) → 홈 → 50초 / 70초 뒤 복귀 | 열림 / 잠김 |
| 즉시 설정에서 사진 고르는 중 3분 | 잠기지 않음 |
| 폰 인증 실패 → 앱 재시작 | 24시간 차단 유지 |
| 삭제 → 휴지통 1일 → 시계 다음 날 → 일기 탭 | 행 · 파일 모두 사라짐 |
| 삭제 → 복원 | 사진 · 영상이 피드 · 릴스에서 그대로 보이고 재생 |
| 일기 잠금 중 알람 울림 | 울림 화면 정상 |

## 10. 위험 · 확인할 것

- `video_compress` 유지보수 상태와 Android 최신 버전 동작 — 계획 첫 단계 스파이크. 안 되면 `light_compressor` 또는 길이 · 해상도 제한만 두고 원본 복사.
- `geocoding` 은 Android `Geocoder` 를 써서 네트워크 · 기기 지원이 필요하다. 이름이 없을 수 있다.
- `local_auth` 는 `FlutterFragmentActivity` 가 필요하다 — 알람 울림 Activity 와 충돌하지 않는지 확인.
- 미디어 선택으로 나갔다 오는 동안 잠금 예외를 정확히 판단(선택 시작/끝 플래그).
- 사진 · 영상이 많아질 때 피드 · 릴스 메모리(썸네일 사용, 화면 밖 영상 컨트롤러 해제).

## 11. 스파이크 결과

> 2026-10-12 · T1 · 에뮬레이터 `Medium_Phone`(Android 17, google_apis_playstore arm64) 에서 버리는 앱(`lib/spike_main.dart`, 커밋 안 함)으로 확인.
> **기기** = 에뮬레이터에서 실제로 돌려 본 것, **소스** = `~/.pub-cache` 의 플러그인 소스 · pub.dev 메타데이터로만 확인한 것(T19 실제 폰에서 다시 본다).

| 패키지 · 버전 | 확인한 동작 | 근거 | 선택 | 우회 · 구현 메모 |
|---|---|---|---|---|
| `video_compress` 3.1.4 (pub.dev 마지막 배포 2025-02-13) | 1080×2400 · 19.9초 · 51MB 화면 녹화 → `Res1280x720Quality` 로 **1280×576 · 8MB**, `MediaInfo.duration` = 19942.0(ms, double), 원본 유지(`deleteOrigin: false`), 에뮬레이터에서 약 30초. `getFileThumbnail` 정상(jpg 13KB) | 기기 | **채택** (`light_compressor` 불필요) | 해상도는 **긴 변 1280** 기준(비율 유지)이라 "최대 720p" 를 만족. 결과 · 썸네일이 **외부 앱 폴더**(`Android/data/<pkg>/files/video_compress/`)에 생기므로 T7 은 앱 문서 폴더로 옮기고 `VideoCompress.deleteAllCache()` 로 비운다. 길이 판단은 압축 전 `getMediaInfo(path).duration`(ms) 으로. 동시 압축은 `StateError` — 한 번에 하나씩. 빌드 classpath AGP 8.1.1 · compileSdk 34 지만 `flutter build apk --debug` 통과 |
| `flutter_image_compress` 2.5.1 | GPS · Make 가 든 4000×3000 JPEG → EXIF 태그 **0개**(`keepExif: false`). 1000×750 은 **확대 안 됨**(그대로). 단 `minWidth: 1600, minHeight: 1600` 은 **짧은 변**을 1600 에 맞춘다: 4000×3000 → **2133×1600**, 3000×4000 → 1600×2133 | 기기(결과 파일을 꺼내 Pillow 로 EXIF · 크기 확인) · 소스(`calcScale = max(1, min(w/minW, h/minH))`) | 채택 | **긴 변 1600** 을 지키려면 T7 에서 원본 크기를 먼저 읽어 `minWidth`/`minHeight` 를 비율대로 준다: 가로가 길면 `minWidth: 1600, minHeight: (1600*h/w).round()`, 세로가 길면 반대. 긴 변이 1600 이하면 그대로(확대 없음은 플러그인이 보장) |
| `local_auth` 3.0.2 (`local_auth_android` 2.0.8) | 기기 PIN 으로 `authenticate(localizedReason:, biometricOnly: false)` → `true`. 틀린 PIN 은 시스템 화면이 그대로 남고 Dart 쪽 결과 없음. **취소(뒤로) → `false` 가 아니라 `LocalAuthException(code: userCanceled)` 를 던진다**. `isDeviceSupported()` = 화면 잠금 있으면 true | 기기 · 소스 | 채택 | 3.x 는 `AuthenticationOptions` 가 없어졌다 — `biometricOnly` · `sensitiveTransaction` · `persistAcrossBackgrounding` 이 `authenticate` 의 이름 인자. 결과 분류: `true` 성공 / `userCanceled` · `systemCanceled` · `timeout` 취소(실패 횟수에 안 셈) / `noCredentialsSet` 화면 잠금 없음 / `temporaryLockout` · `biometricLockout` 폰 쪽 차단 / 그 밖 오류. `false` 반환은 Android 에서 사실상 나오지 않지만 실패로 처리. `MainActivity` 는 이미 `FlutterFragmentActivity`, 알람 울림도 같은 Activity 라 충돌 없음 |
| `geocoding` 5.0.0 (`geocoding_android` 5.0.2) | `isPresent()` = true. `placemarkFromCoordinates(37.5665, 126.9780, locale: ko_KR)` 는 에뮬레이터 망이 검증되지 않은 상태에서 **15분 넘게 완료되지 않았다**(오류도 없음) | 기기(응답 없음) · 소스 | 채택 | 5.x 는 `Geocoding()` 인스턴스 API. **생성자 `locale` 인자는 내부에서 버려지므로**(소스) 호출마다 `locale:` 을 넘긴다. Android 13+ 는 `GeocodeListener` 비동기라 백엔드가 응답하지 않으면 Future 가 끝나지 않는다 → T8 은 반드시 `.timeout(...)` 으로 감싸고 실패 시 장소 이름 없이 좌표만 저장. `Placemark` 필드: `name` · `street` · `country` · `administrativeArea`(시) · `subAdministrativeArea` · `locality` · `subLocality`(구/동) · `thoroughfare`(도로·동) · `subThoroughfare`. **어느 필드가 채워지는지는 미확인 → T19 실제 폰에서 기록** |
| `image_picker` 1.2.4 | 카메라 촬영용 `<queries>` (`IMAGE_CAPTURE` · `VIDEO_CAPTURE`) 추가, 빌드 통과 | 소스 · 빌드 | 채택 | 고르기 화면은 T19 기기 시나리오에서 |
| `video_player` 2.11.1 | 빌드 통과 | 빌드 | 채택 | 최신 2.14.1 은 현재 SDK 제약으로 해석기가 2.11.1 을 골랐다 |
| `drift` 2.34.4 · `drift_flutter` 0.3.1 · `drift_dev` 2.34.0 · `path_provider` 2.1.6 · `crypto` 3.0.7 · `uuid` 4.6.0(제약 `^4.5.1`, core 와 같음) | pawlog · core 와 같은 제약 | — | 채택 | — |
