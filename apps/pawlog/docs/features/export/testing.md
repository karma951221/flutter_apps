# W8 export — 테스트

> [테스트 가이드](../../../../../docs/testing/README.md) · [pawlog 허브](../../README.md) · [계획](plan.md) · [구현 기록](history.md)

```bash
cd apps/pawlog && flutter test test/domain/export test/presentation/walk test/core/router
cd packages/design_system && flutter test test/widget/app_overflow_menu_test.dart
```

W8 몫은 `apps/pawlog` 18건(`+375` → `+393`, ① 9건 · ② 9건)과 `packages/design_system` 1건이다.

| 파일 | 추가 | 확인 |
|---|---|---|
| `test/domain/export/policy/gpx_encoder_test.dart` | 9 | 점 2개 · 메모 문서 전체 · `& < > " '` 이스케이프 · 메모 null/공백이면 `<desc>` 없음 · 메모 앞뒤 공백·줄바꿈은 잘라서 `<desc>` · 제어 문자(`\u0001` 등) 제거, 탭 유지 · 점 없으면 빈 `trkseg` · 현지 시각 → UTC `Z` · 좌표 소수 6자리 · `fileName` 은 현지 시작 시각 |
| `test/presentation/walk/cubit/walk_detail_cubit_test.dart` | 5 | `exportGpx` — 불러오기 전 `failed` · 삭제 중 `failed`(공유 안 부름) · 점 없으면 `noRoute`(공유 안 부름) · `shared` 에 넘긴 파일 이름 · 내용(`GpxEncoder.encode` 같은 인자) · MIME · 공유 `Err` → `failed(failure)`. 모두 상태 그대로 |
| `test/presentation/walk/page/walk_detail_page_test.dart` | 4 | 메뉴에 수정 · 내보내기 · 삭제 순서 · 점 없으면 "경로가 없어 내보낼 수 없어요"(공유 안 부름) · 점 있으면 `.gpx` · `<trkpt` · `application/gpx+xml` 로 공유하고 스낵바 없음 · 실패면 "내보내지 못했어요" |
| `packages/design_system/test/widget/app_overflow_menu_test.dart` | 1 | 항목 `key` 가 메뉴 행에 붙어 탭하면 값이 온다 |

`test/core/router/app_router_test.dart` 는 새 생성자 인자(`MockWalkFileSharer`)만 맞췄다.

## 에뮬레이터

2026-10-17, `Medium_Phone_2`(영어). GPS 가 앱에 들어오지 않는 AVD 라, ①② 는 기존 산책에 테스트 점 5개를 sqlite 로 넣어(`adb exec-out run-as … cat` → 호스트 `sqlite3` → 되돌려 쓰기) 경로가 있는 산책을 만들어 봤다.

| # | 시나리오 | 결과 |
|---|---|---|
| ① | 경로가 있는 산책 상세 → 더보기 → GPX로 내보내기 → 공유 시트가 `pawlog-yyyy-MM-dd-HHmm.gpx` 로 뜬다 | **PASS** — "Sharing 1 file · pawlog-2026-10-17-0012.gpx". `cache/pawlog_export/` 의 파일이 계획의 GPX 형태 그대로(UTC `Z`, 소수 6자리, 메모 없어 `<desc>` 없음) |
| ② | 공유 시트를 닫는다 → 스낵바 없음, 상세 그대로 | **PASS** |
| ③ | 점 없는 산책 → GPX로 내보내기 → "경로가 없어 내보낼 수 없어요" | **PASS** — 메뉴 순서 Edit · Export GPX · Delete, 스낵바 "There's no route to export" |
| ④ | 받은 파일을 다른 앱(파일 · 지도)에서 열면 경로가 보인다 | 미실행 — AVD 에 GPX 를 여는 앱이 없다. 형태는 ① 에서 파일로 확인 |

## 2026-10-17 — 다듬기

| 파일 | 추가 | 확인 |
|---|---|---|
| `test/presentation/walk/cubit/walk_detail_cubit_test.dart` | 1 | 공유가 끝나기 전 `exportGpx()` 두 번 → 둘 다 `shared`, sharer 1회 · 끝난 뒤에는 다시 공유된다 |
