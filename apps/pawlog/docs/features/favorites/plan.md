# W10 favorites — 계획 (결정 · 화면 · 완료 조건)

> [pawlog 허브](../../README.md) · [구현 기록](history.md) · [테스트](testing.md) · [기획 §3](../../overview.md#3-mvpv1-범위) · [W4 feed](../feed/plan.md)

> 상태: 구현 완료 2026-10-17 · 에뮬레이터 PASS · 진행 상태의 단일 기준은 [진행 현황](../../status.md)

## 범위

산책에 **별(즐겨찾기)** 을 달고, 피드에서 **즐겨찾기만 모아 본다**. 기획서 §3 이 v1 밖으로 뺀 "코스 즐겨찾기 · 추천" 의
가장 가벼운 조각이다. "묻지 말고 알아서 진행" 지시로 오케스트레이터가 골랐다. 코스(경로)를 따로 저장해 다시 따라 걷기,
추천, 통계 필터는 범위 밖.

## 결정

| # | 결정 | 근거 |
|---|---|---|
| 1 | `walks.is_favorite` 불리언(기본 false) 열 — drift 스키마 **v2 → v3**, `onUpgrade` `from < 3` 에서 `addColumn` | 산책 한 건의 속성이다. 별도 테이블은 과하다 |
| 2 | `Walk.isFavorite`(기본 false). 저장 폼 · 수정 폼은 건드리지 않는다 — 별은 상세에서만 바꾼다 | 기록을 다 쓴 뒤 고르는 동작이다 |
| 3 | 상세 앱바 더보기 왼쪽에 별 아이콘 버튼(꽉 찬 별 / 빈 별, 남색). 누르면 바로 바뀌고 피드에도 스트림으로 흐른다 | 주 버튼 규칙 밖의 작은 토글. 연두는 쓰지 않는다 |
| 4 | 피드 항목: 즐겨찾기면 시각 옆에 작은 별(남색) | 줄글 수첩 모양을 해치지 않는 표시 |
| 5 | 피드 앱바 더보기에 "즐겨찾기만 보기" ↔ "모든 산책 보기" 토글. 필터는 화면 상태(앱을 다시 열면 전체) | 설정 저장까지는 필요 없다 |
| 6 | 즐겨찾기 필터 중 결과가 0건이면 `AppPlaceholder` "즐겨찾기한 산책이 없어요 / 산책 상세에서 별을 눌러 보세요". 이번 주 요약 줄 · 통계는 필터와 무관하게 전체 | 요약은 "이번 주에 얼마나 걸었나" 다 |
| 7 | 백업 json 에 `isFavorite` 를 쓴다. **version 은 1 그대로**, 읽을 때 없으면 false | 예전 백업도 그대로 읽힌다(뒤로 호환) |

## 문자열 (ko 템플릿 · en · ja)

| 키 | ko | en | ja |
|---|---|---|---|
| `walkFavoriteAdd` | 즐겨찾기에 추가 | Add to favorites | お気に入りに追加 |
| `walkFavoriteRemove` | 즐겨찾기에서 빼기 | Remove from favorites | お気に入りから外す |
| `walkFeedShowFavorites` | 즐겨찾기만 보기 | Show favorites only | お気に入りだけ表示 |
| `walkFeedShowAll` | 모든 산책 보기 | Show all walks | すべての散歩を表示 |
| `walkFeedFavoritesEmptyTitle` | 즐겨찾기한 산책이 없어요 | No favorite walks yet | お気に入りの散歩はまだありません |
| `walkFeedFavoritesEmptyMessage` | 산책 상세에서 별을 눌러 보세요 | Tap the star on a walk to add it | 散歩の詳細で星をタップしてください |

## 완료 조건

- [ ] 마이그레이션 v2 → v3(기존 행 false) · 저장소 `setFavorite` · 백업 코덱(있음 · 없음) 테스트
- [ ] 상세 별 토글 · 피드 별 표시 · 필터 · 빈 필터 안내 테스트
- [ ] `flutter analyze` 0 · `flutter test` · `flutter build apk --debug`
- [ ] 에뮬레이터: 상세에서 별 → 피드에 별 → 즐겨찾기만 보기 → 별 해제하면 목록에서 빠지고 빈 안내 → 모든 산책 보기
