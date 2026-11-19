# walk UI 가이드 — 화면 조립 기준

화면마다 같은 역할의 틀을 다르게 쌓아 "feature별로 통일감이 없다"는 실기기 QA(2026-11)에서
정한 기준이다. 토큰 · 공통 위젯 규칙은 루트 [CLAUDE.md](../../../CLAUDE.md)의 'UI 공통 위젯
규칙'을 따르고, 여기서는 **조립 방식**만 정한다.

## 테마

`WalkTheme`(`lib/presentation/theme/walk_theme.dart`)이 공유 `AppTheme` 위에 걷기 앱에서만
컴포넌트 테마를 얹는다. 공유 테마에 넣으면 트레이더 · pawlog 모양이 바뀌기 때문이다.

| 컴포넌트 | 값 |
|---|---|
| 바텀시트 | 손잡이 켬, 바탕 `surfaceContainerLow`, 위 모서리 `AppRadius.lg`(`appSheetShape`) |
| 카드 | elevation 0, `surfaceContainerLow`, `AppRadius.lgAll` |
| 다이얼로그 | `surfaceContainerHigh`, `AppRadius.lgAll` |
| 칩 | `AppRadius.smAll` |
| 스위치 | 켜짐에 체크 아이콘 |

## 틀별 기준

| 틀 | 쓰는 것 | 기준 |
|---|---|---|
| 시트 | `showAppSheet` + `AppSheetScaffold` | 손잡이 · 제목 `titleLarge` 왼쪽 정렬 · 좌우 `AppSpacing.lg`. 설명은 bodySmall · onSurfaceVariant. 높이는 '내용만큼'(기본)과 '끌기형'(`.draggable`, 긴 목록) 두 가지. 아래 버튼은 `primaryAction` · `secondaryAction` |
| 모달 아닌 시트 | `AppSheetHandle` + `appSheetShape` | 지도 위 `MapSheet` 처럼 직접 그리는 시트도 손잡이 · 모서리를 테마와 맞춘다 |
| 섹션 머리 | `AppSectionHeader` | `titleSmall` · primary, 여백 `(md, lg, md, xs)`. 묶음이 둘 이상이면 모든 묶음에 단다. 묶음 사이 `Divider` 는 두지 않는다 |
| 선택 행 | `AppSelectTile` | 오른쪽 체크, primary 색 |
| 스위치 행 | `AppSwitchTile` | 행 어디를 눌러도 바뀐다. `SwitchListTile` · `AppListTile + Switch` 는 쓰지 않는다 |
| 로딩 | `AppLoading` | 페이지 · 시트 단위는 모두. 대개 금방 끝나는 로컬 읽기는 `AppLoading(delayed: true)`. 버튼 안 · 썸네일 같은 작은 자리만 예외 |
| 빈 상태 · 오류 | `AppPlaceholder` | 늘 아이콘. 행동은 `actionLabel` · `onAction` 으로만 |
| 카드 | `Card` | 모양은 테마가 정한다. 화면에서 `shape` · `elevation` · `color` 를 다시 주지 않는다 |
| 안내 띠 | `AppBanner` | `tone: info / warning / error`, 행동 하나까지 |
| 보조 설명 | `AppFootnote` | bodySmall · onSurfaceVariant, 여백 `(md, xs, md, md)` |
| 상태 글자 | `StatusLabel`(walk) | labelLarge, 됨 primary · 보통 onSurfaceVariant · 조치 필요 error |
| 가린 키 입력 | `ObscuredKeyField` | 눈 아이콘으로 보기 · 가리기, 자동 고침 끔 |
| 다이얼로그 버튼 | `AppButton` | 확정 `primary(compact: true)`, 취소 `text(compact: true)`. 되돌리기 어려운 확인은 `AppConfirmDialog` |
| 상단 바 글자 버튼 | `AppButton.text(compact: true)` | `minimumSize: Size.zero` 같은 우회는 쓰지 않는다 |
| 파괴적 행 | `AppListTile` | 아이콘 · 제목 모두 `colorScheme.error` (⋮ 메뉴 `isDestructive` 와 같은 색) |
| 아이콘 | — | 테두리형(`_outlined`) 우선. 같은 역할에 꽉 찬 아이콘과 섞지 않는다 |
| 기능 탭 ⋮ | `FeatureMenu` | 도구 탭의 기능도 화면별 항목 + "○○ 설정" 한 모양 |
| 탭 안 전환 | `SegmentedButton` | 탭바를 두 줄로 겹치지 않는다 |
