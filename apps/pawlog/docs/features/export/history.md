# W8 export — 구현 기록

> [pawlog 허브](../../README.md) · [계획](plan.md) · [테스트](testing.md)

설계 판단과 계획에서 달라진 것을 남긴다. 진행 상태는 [진행 현황](../../status.md)에만 적는다.
브랜치 `feat/pawlog-export`. 사용자가 "묻지 말고 알아서 진행" 이라고 해서 범위와 결정은 오케스트레이터가 골랐다.

## 단계 커밋 (2026-10-17)

| # | 커밋 | 범위 |
|---|---|---|
| ① | `fb4bf8a` | `GpxEncoder.encode` · `fileName`(도메인 순수 함수), `WalkFileSharer` 경계와 `share_plus` 구현 |
| ② | `3a5b648` | 상세 더보기 "GPX로 내보내기", `WalkDetailCubit.exportGpx()` · `WalkExportResult`, 문자열 3개 |

## 결정 (만든 그대로)

| 계획 # | 만든 모습 |
|---|---|
| 1 | 더보기 메뉴 수정 · **GPX로 내보내기** · 삭제 순서. 아이콘 `Icons.ios_share_outlined`, 키 `walk-detail-export` |
| 4 | 경로 점이 없어도 항목은 그대로. 누르면 `walkExportNoRoute` 스낵바(info), 공유는 부르지 않는다 |
| 6 | 트랙 이름 = `walk.dogs` 이름을 `, ` 로 이은 것, `<desc>` = 메모, 파일 이름 `GpxEncoder.fileName(walk.startedAt)`, MIME `application/gpx+xml`(`WalkDetailCubit.gpxMimeType`) |

## 판단 (계획에 없던 것)

| 판단 | 이유 |
|---|---|
| `exportGpx()` 는 상태를 바꾸지 않고 `Future<WalkExportResult>` 만 돌려준다. `WalkExportResult` 는 Freezed union(`shared` · `noRoute` · `failed(Failure)`) | 스낵바는 한 번 쓰고 버리는 결과라 `WalkDetailState` 에 넣으면 listener 중복 판정만 늘어난다 |
| `WalkDetailLoaded` 가 아니면(로딩 · 삭제 중) `failed(Failure.unknown())` | 메뉴가 `WalkDetailLoaded` 에서만 열리므로 실제로는 닿지 않는 방어 분기 |
| 실패 스낵바는 `AppSnackBarType.error`, 경로 없음은 `info` | 경로 없음은 오류가 아니라 안내다 |
| `AppOverflowMenuItem` 에 선택 인자 `key` 를 더해 `PopupMenuItem` 에 붙인다(`packages/design_system`) | 계획이 메뉴 항목 키를 정했는데 공통 항목에 키를 둘 자리가 없었다. 기존 호출부는 그대로 |
| 공유 시트에서 취소해도 `shared` | `share_plus` 결과를 보지 않는다. 계획 "공유 · 취소 모두 아무것도 안 띄움" 과 같다 |
