# 디자인 시스템 적용 — 테스트

> [테스트 가이드](../../../../../docs/testing/README.md) · [pawlog 허브](../../README.md) · [디자인 시스템](../../design.md) · [계획](plan.md) · [구현 기록](history.md)

```bash
cd apps/pawlog && flutter test test/presentation/theme test/presentation/common
cd apps/pawlog && flutter test test/presentation/feed/page
cd apps/pawlog && flutter test            # 전체
```

## `test/presentation/theme/`

| 파일 | 대상 | 확인 |
|---|---|---|
| `pawlog_theme_test.dart` (11) | `PawlogTheme` · `PawlogColors` · `PawlogTextStyles` · `PawlogMotion` | 라이트 바탕 · 주 색 · 오류색 · 다크 바탕 · 다크 주 색 · 연두는 모드 공통 · 연두가 `ColorScheme` 에 없음 · 입력 테두리가 `rule` 이 아니고 바탕 · 시트와 3:1 초과(P4) · 제목 고운돋움 · 본문 Pretendard · 메모 개구 · 숫자 700 + `tabularFigures` · 모서리 4 · 12 · 20 · 알약, 주 버튼 58 · 칩 체크 없음 · 선택 바탕(P2) · 간격 토큰 · 확장이 없을 때 밝기별 기본값 · `disableAnimations` → `off` |

## `test/presentation/common/`

| 파일 | 대상 | 확인 |
|---|---|---|
| `widget/pawlog_primary_button_test.dart` (6) | `PawlogPrimaryButton` · `PawlogBottomAction` | 높이 58 · 남색 · 탭 → `onPressed` · 누르는 동안 `0.97` 에서 떼면 `1` · `onPressed: null` → 투명도 `0.4` 이고 눌러도 줄지 않음 · 로딩 전환 중(100ms)엔 라벨과 진행 표시가 함께 있고 200ms 뒤 진행 표시만, 투명도 `1`, 탭 무시 · `disableAnimations` 면 다음 프레임에 전환 끝 · `.stop` 은 먹색 |

기존 테스트에서 바꾼 것: `active_walk_page_test` 의 시작 버튼 활성 판단을 `AppButton` 에서
`PawlogPrimaryButton` 으로.

## `test/presentation/feed/page/`

| 파일 | 대상 | 바뀐 것 |
|---|---|---|
| `walk_feed_page_test.dart` (12 → 13) | `WalkFeedPage` · `WalkFeedEntry` | 빈 피드: 항목 없음 + 하단 `walk-feed-start-button` → `onStartWalk` · 추적 중 · 저장 전 빈 피드엔 시작 버튼 없음 · 항목: `Card` 없음, 달 머리 `2026년 10월` · 일 `3` · 요일 `토` · 이름 `콩이1` · 시각 `09:00` · `1.2 km` · `30분` · 메모 · **새 테스트 — 같은 날 두 기록 + 전날 하나: 첫 기록만 `walk-feed-date-*`, `showDate` / `continuesBelow` 가 (참, 참) · (거짓, 거짓) · (참, —), 달 머리 하나** · 키 `walk-feed-card-*` → `walk-feed-entry-*`, `walk-feed-fab` → `walk-feed-start-button` |

날짜 묶음 테스트는 세 항목이 한 화면에 들어오도록 `tester.view` 를 400×2400 으로 둔다 — 4:3 사진 칸
때문에 기본 800×600 에서는 둘째 항목부터 지연 생성돼 위젯을 찾을 수 없다.
