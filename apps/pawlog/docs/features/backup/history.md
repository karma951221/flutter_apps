# W9 backup — 구현 기록

> [pawlog 허브](../../README.md) · [계획](plan.md) · [테스트](testing.md) · [실행 계획](../../../../../docs/superpowers/plans/2026-10-17-pawlog-backup.md)

설계 판단 · 리뷰에서 고친 것 · 검증 결과를 남긴다. 진행 상태는 [진행 현황](../../status.md)에만 적는다.
브랜치 `feat/pawlog-backup`. "묻지 말고 알아서 진행" 지시로 오케스트레이터가 고르고 계획을 스스로 승인했다.
태스크마다 구현 서브에이전트가 커밋하고 리뷰 서브에이전트가 따로 읽었다.

## 단계 커밋 (2026-10-17)

| # | 커밋 | 범위 |
|---|---|---|
| ① | `592f04d` · `199d17d` · `b3f5ee1` | `BackupData` · `BackupCodec`(json v1), 겹친 id 거부, 읽은 시각은 현지 시각 |
| ② | `3e12e96` · `c4dc94d` | `BackupArchive`(zip) · `PhotoStorage.write` · `WalkFileSharer.shareBytes` · `BackupFilePicker`(file_picker), 경로 검사 강화 |
| ③ | `68eb630` · `a4b0dae` | `ExportBackupScenario` · `ImportBackupScenario` · `BackupImportResult`, 사진을 먼저 쓰기 |
| ④ | `9b5a587` | 피드 더보기 · 첫 실행 "백업에서 가져오기" · 라우터 · 문자열 9개 |

## 판단 (계획에 없던 것)

| 판단 | 이유 |
|---|---|
| 백업 안에 같은 id 가 둘 이상이면(반려견 · 산책 · 사진) 읽지 않는다 | 하나를 조용히 고르면 어느 것이 들어갔는지 알 수 없다 |
| 읽은 시각은 `toLocal()` 로 돌려준다(쓰기는 UTC `Z`) | drift 에서 읽은 값과 같은 모양이라 비교 · 표시가 같다 |
| 시간대 없는 시각은 거부한다 | 기기마다 다른 순간이 된다 |
| 사진 경로는 `isSafePhotoPath` 로 — 빈 조각 · `.` · `..` · 절대 경로 · 역슬래시 탈출 · 드라이브 접두사 · NUL 거부. zip 풀기 · `backup.json` 읽기(반려견 `photoPath` · 산책 사진 `path`) · `write` 세 곳에서 거르고, `FilePhotoStorage.remove` 도 위험 경로면 아무것도 지우지 않는다(`resolve` 는 검사 없이 붙이기만 한다) | 백업 파일은 밖에서 온다. DB 에 들어간 경로는 나중에 반려견 삭제 등에서 `remove` 로 쓰인다 |
| `PhotoStorage.write` 는 임시 파일에 쓰고 옮긴다 · 있으면 건너뛴다 | 쓰다 죽어도 반쪽 파일이 "있다" 로 남지 않게 |
| 가져오기는 **모든 존재 확인 → 새 항목의 사진 → 반려견 → 산책** 순서 | 사진 쓰기가 엔티티 뒤에 있으면, 실패 뒤 다시 가져와도 "새 기록 없음" 이라 사진을 영영 못 쓴다 |
| 쓰기는 트랜잭션이 아니다 — 중간 실패면 쓴 것은 남고 결과는 실패. 다시 가져오면 합치기로 나머지만 들어간다 | 반려견 · 산책 · 파일을 한 트랜잭션으로 묶을 수 없다. 산책 한 건(산책 + 점)은 이미 DB 트랜잭션이다 |
| 내보내기 · 가져오기 중 다시 누르기는 무시 | 공유 시트 · 파일 고르기가 두 번 뜨지 않게 |
| file_picker 13 에 `withData` 가 없어 고른 뒤 파일을 읽는다 | 플러그인 API |

## 리뷰에서 고친 것

| 단계 | 소견 | 처리 |
|---|---|---|
| ① | 겹친 id 를 조용히 덮어씀 | 읽지 않음 (`199d17d`) |
| ① | 읽은 시각이 UTC 라 기존 엔티티와 `==` 가 어긋남 | 현지 시각 (`b3f5ee1`) |
| ② | 경로 검사가 드라이브 · 빈 조각 · `.` · NUL 을 놓침, 깨진 zip 의 `RangeError` 등이 새어 나감 | 검사 강화 · 모든 오류를 `Err` 로, 쓰기 원자화 (`c4dc94d`) |
| ③ | 사진 쓰기 실패가 되돌릴 수 없음 | 사진 먼저 (`a4b0dae`) |
| 최종 | `backup.json` 의 사진 경로를 검사하지 않아 `../pawlog.sqlite` 같은 값이 DB 에 들어가고 나중 `remove` 가 사진 폴더 밖을 지울 수 있음 | `BackupCodec.decode` 가 위험 경로면 invalid · `FilePhotoStorage.remove` 도 위험 경로 무시 |
| 최종 | 첫 실행 화면에서 일부만 들어가고 실패(`failed` · `imported(0, k)`)하거나 `nothingNew` 인데 반려견이 이미 있으면 등록 화면에 갇힘 | `DogEditCubit.importBackup()` 이 `({result, hasDogs})` 를 돌려주고(취소 · invalid 외에는 `getDogs()` 로 확인) 페이지는 `hasDogs` 면 `onImported`. 스낵바 문구는 그대로 |
| 최종 | 첫 실행 가져오기 중에도 가져오기 버튼 · 저장이 눌림 | 페이지 `_importing` 동안 둘 다 비활성 · 버튼 라벨 자리에 진행 표시. cubit `save()` 도 가져오는 중이면 무시. 피드는 기존 중복 방지로 충분해 그대로 |
| 최종 | 제공자마다 zip MIME 이 달라 `FileType.custom(zip)` 에서 백업이 안 보일 수 있음 | `FileType.any` 로 고르고 zip 이 아니면 `unpack` 이 invalid |
| 최종 | file_picker 가 앱 캐시에 남긴 백업 복사본 | 읽은 뒤 `finally` 에서 `FilePicker.clearTemporaryFiles()` (best-effort, 던지지 않음) |

## 넘기는 것

- zip 크기 · 항목 수 상한이 없다 — 사용자가 고른 로컬 파일이라 받아들인다
- `backup.json` 도 크기 상한이 없다 — 같은 이유로 받아들인다
- 날짜만 있는 시각(`2026-10-03`)은 시간대 검사를 통과한다 · 음수 시간 · 범위 밖 좌표는 검사하지 않는다(손으로 고친 파일만 해당)
- 백업 파일 암호화 · 자동 백업 · 덮어쓰기 복원은 범위 밖
- 2026-10-17: 백업 zip 묶기 · 풀기(`BackupArchive`)와 json 인코딩 · 디코딩(`BackupCodec`, 시나리오에서)을 `Isolate.run` 으로 UI isolate 밖에서 한다. `BackupArchiveCodec.pack` · `unpack` 은 `Future` 를 돌려주고 `unpack` 은 isolate 안팎 어디서든 던지지 않고 `Err`

## 에뮬레이터 QA (2026-10-17)

결과는 [테스트 — 에뮬레이터](testing.md#에뮬레이터).
