# W10 favorites — 테스트

> [테스트 가이드](../../../../../docs/testing/README.md) · [pawlog 허브](../../README.md) · [계획](plan.md) · [구현 기록](history.md)

```bash
cd apps/pawlog && flutter test test/data/database test/data/walk test/domain/backup test/domain/walk
cd apps/pawlog && flutter test test/presentation/walk test/presentation/feed
```

W10 몫은 `apps/pawlog` 28건(`+507` → `+535`, 2026-10-17 `70908f2` 기준)이다.

| 영역 | 확인 |
|---|---|
| 마이그레이션 | v1 → v3 · v2 → v3(실제 v2 SQL 픽스처) — 기존 행 `isFavorite == false`, `setFavorite` 동작, `user_version 3` |
| 저장소 | `setFavorite` 켜고 끄기(`findById` · `watchAll`) · `updatedAt` 그대로 · 없는 id → `walkNotFound` · `update` 가 별을 지킴 · `insert` 가 별을 씀 |
| 매퍼 · 수정 시나리오 | 별이 엔티티로 · 수정 결과가 별을 지킴 |
| 백업 코덱 | 별 왕복 · 필드 없는 예전 json → false · `"yes"` → 읽지 못함 |
| 상세 | 별 아이콘 · 툴팁 두 상태 · 누르면 `setWalkFavorite(id, true)` · 실패 → 스낵바, 별 그대로 · 진행 중 다시 누르기 무시 |
| 피드 | 즐겨찾기 산책에만 별 · 필터 켜기 · 끄기, 메뉴 문구 전환 · 즐겨찾기 0건이면 안내(요약 줄은 남음) |

## 에뮬레이터

2026-10-17, `Medium_Phone_2`(영어).

| # | 시나리오 | 결과 |
|---|---|---|
| ① | 즐겨찾기 없이 "Show favorites only" → 안내 | **PASS** — "No favorite walks yet / Tap the star on a walk to add it", 요약 줄 · 시작 버튼 그대로 |
| ② | 상세 별 → 피드 카드에 별 | **PASS** — "Add to favorites" → "Remove from favorites", 카드 시각 옆 별 |
| ③ | 필터 중 별 해제 → 목록에서 빠지고 안내 | **PASS** |
| ④ | "Show all walks" 로 돌아온다 | **PASS** |
