# W9 backup — 테스트

> [테스트 가이드](../../../../../docs/testing/README.md) · [pawlog 허브](../../README.md) · [계획](plan.md) · [구현 기록](history.md)

```bash
cd apps/pawlog && flutter test test/domain/backup test/data/backup test/domain/photo test/data/photo
cd apps/pawlog && flutter test test/presentation/backup test/presentation/feed test/presentation/dog test/core/router
```

W9 몫은 `apps/pawlog` 98건(`+393` → `+491`, 2026-10-17 `9b5a587` 기준)이다.

| 파일 | 확인 |
|---|---|
| `test/domain/backup/policy/backup_codec_test.dart` | 왕복(`==`) · 키 이름 · UTC 쓰기 · 현지 시각 읽기 · 다른 시간대 같은 순간 · `birthday` · 다른 format · version 2 · 깨진 json · 필드 누락 · 타입 오류 · 없는 dogId · 겹친 id(반려견 · 산책 · 사진) · 시간대 없는 시각 · previewPoints 재구성 |
| `test/data/backup/backup_archive_test.dart` | zip 왕복(사진 바이트) · 항목 이름 · zip 아님 · `backup.json` 없음 · 경로 탈출(`..` · 역슬래시 · 절대) · 잘린 zip |
| `test/domain/photo/repository/photo_storage_test.dart` | `isSafePhotoPath` 13가지 |
| `test/data/photo/file_photo_storage_test.dart` | `write` 쓰기 · 있으면 안 덮음 · 위험 경로 거부(루트 밖에 아무것도 없음) · `.tmp` 안 남음 |
| `test/domain/backup/usecase/scenario/export_backup_scenario_test.dart` | 전체 수집 · 없는 사진 파일 빠짐 · 현지 날짜 파일 이름 · zip mime · 읽기 · 공유 실패 |
| `test/domain/backup/usecase/scenario/import_backup_scenario_test.dart` | 취소 · invalid 에서 쓰기 없음 · 새 항목 · 일부만 새것 · 같은 백업 두 번(상태 있는 stub) → nothingNew · 사진 → 반려견 → 산책 순서 · 새 항목 사진만 · 사진 쓰기 실패 뒤 다시 가져오기 · 존재 확인 실패 |
| `test/presentation/backup/backup_messages_test.dart` | 결과 → 스낵바 문구 |
| `test/presentation/feed/…`, `test/presentation/dog/…` | 피드 더보기 두 항목 · 결과 스낵바 · 취소 무반응 · 진행 중 다시 누르기 무시 · 첫 실행에서만 버튼 · 가져오면 `onImported` |
| `test/core/router/app_router_test.dart` | 반려견 0 → `/dogs/new` 에서 가져오기 → `/` 피드, 그 뒤 리다이렉트 안 됨 |

## 에뮬레이터

2026-10-17, `Medium_Phone_2`(영어).

| # | 시나리오 | 결과 |
|---|---|---|
| ① | 피드 더보기 → 백업 내보내기 → 공유 시트에 zip | **PASS** — "Sharing 1 file · pawlog-backup-2026-10-17.zip", zip 안 `backup.json` 형식 확인 |
| ② | 앱 데이터 지우기(`pm clear`) → 첫 실행 등록 화면 "Restore from backup" → 파일 고르기 → 피드에 기록 | **PASS** — Kong · 320 m 산책이 돌아오고 피드로 감. 상세에서 경로 · `01:23` 그대로 |
| ③ | 같은 파일 다시 가져오기 | **PASS** — "Nothing new to import" |
| ④ | 사진이 돌아온다 | 미실행 — 이 AVD 의 기록에 사진이 없다. 단위 테스트가 덮는다 |
