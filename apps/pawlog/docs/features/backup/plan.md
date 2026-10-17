# W9 backup — 계획 (결정 · 형식 · 화면 · 완료 조건)

> [pawlog 허브](../../README.md) · [구현 기록](history.md) · [테스트](testing.md) · [기획 §3](../../overview.md#3-mvpv1-범위) · [W8 export](../export/plan.md)

> 상태: 구현 완료 2026-10-17 · 에뮬레이터 ①②③ PASS · 진행 상태의 단일 기준은 [진행 현황](../../status.md)

## 범위

반려견 · 산책 · 경로 점 · 사진 **전부를 파일 하나로 내보내고, 그 파일에서 되살린다**. 로컬에만 저장하는 앱이라
앱을 지우거나 폰을 바꾸면 기록이 모두 사라졌다(walk 일기 설정의 "앱을 지우면 함께 사라져요" 와 같은 사정).
사용자의 "묻지 말고 알아서 진행" 지시로 오케스트레이터가 골랐다. 자동 백업 · 클라우드 · 암호화 · 덮어쓰기 복원은 범위 밖.

## 결정

| # | 결정 | 근거 |
|---|---|---|
| 1 | 파일은 zip(`pawlog-backup-yyyy-MM-dd.zip`) 하나: `backup.json` + `photos/<상대 경로>` | 사진을 같이 옮겨야 기록이 온전하다. zip 은 받는 쪽(드라이브 · 메일)이 그대로 보관한다 |
| 2 | `backup.json` 은 `{"format":"pawlog-backup","version":1,"exportedAt":…,"dogs":[…],"walks":[…]}`. 직렬화는 도메인 순수 함수 `BackupCodec` 이 손으로 쓴다 | 엔티티에 json 생성기를 붙이지 않는다(기존 모델이 freezed 단일 모델만 쓴다). 형식 버전을 두어 나중에 바꿀 수 있게 |
| 3 | 가져오기는 **합치기**: id 가 이미 있는 반려견 · 산책은 건너뛰고 없는 것만 넣는다. 반려견 먼저, 그다음 산책 | 같은 백업을 두 번 가져와도 겹치지 않는다. 덮어쓰기는 지금 기록을 잃게 할 수 있다 |
| 4 | 사진은 가져오는 항목이 쓰는 것만 같은 상대 경로로 쓴다. 이미 파일이 있으면 그대로 둔다 | 상대 경로는 id 기반이라 겹치지 않는다 |
| 5 | 읽을 수 없는 파일(zip 아님 · `format` 다름 · `version` 이 1보다 큼 · 필수 필드 없음)은 아무것도 쓰지 않고 실패 | 반쯤 들어간 상태를 만들지 않는다. 디코딩을 끝낸 뒤에만 쓴다 |
| 6 | 입구 둘: 피드 앱바 더보기("백업 내보내기" · "백업 가져오기"), 첫 실행 반려견 등록 화면의 텍스트 버튼 "백업에서 가져오기" | 재설치 직후가 가져오기의 주 장면인데, 그때는 `DogsRedirect` 가 등록 화면에만 둔다 |
| 7 | 첫 실행 화면에서 가져와 반려견이 1마리 이상 생기면 피드로 간다 | 등록을 건너뛴 셈이다 |
| 8 | 공유는 W8 의 `WalkFileSharer` 에 바이트 메서드를 더해 쓴다. 파일 고르기는 도메인 인터페이스 `BackupFilePicker` 뒤 `file_picker` | 플랫폼 없이 테스트한다 |
| 9 | 진행 중 산책(`active_walks`)은 백업하지 않는다 | 진행 중인 것은 기록이 아니다 |

## `backup.json` (version 1)

```json
{
  "format": "pawlog-backup",
  "version": 1,
  "exportedAt": "2026-10-17T03:00:00.000Z",
  "dogs": [
    {"id": "d1", "name": "콩이", "breed": null, "birthday": "2020-05-01", "photoPath": "ab.jpg",
     "createdAt": "…Z", "updatedAt": "…Z"}
  ],
  "walks": [
    {"id": "w1", "startedAt": "…Z", "endedAt": "…Z", "durationSeconds": 1800, "distanceMeters": 1200.5,
     "memo": "공원", "dogIds": ["d1"],
     "photos": [{"id": "p1", "path": "cd.jpg", "position": 0}],
     "createdAt": "…Z", "updatedAt": "…Z",
     "points": [{"lat": 37.5, "lng": 127.0, "recordedAt": "…Z", "accuracy": 5.0}]}
  ]
}
```

시각은 UTC ISO-8601(`toUtc().toIso8601String()`), `birthday` 는 날짜만 `yyyy-MM-dd`. `previewPoints` 는 싣지 않고
가져올 때 점으로 다시 만든다(`RoutePreview.downsample`).

## 화면

| 동작 | 결과 |
|---|---|
| 피드 더보기 → "백업 내보내기" | 공유 시트(파일 하나). 실패 → 스낵바 `walkBackupExportFailed` |
| 피드 더보기 → "백업 가져오기" | 파일 고르기 → 결과 스낵바. 고르기 취소 → 아무것도 안 함 |
| 첫 실행 등록 화면 → "백업에서 가져오기" | 같은 흐름. 반려견이 생기면 피드로 |

| 가져오기 결과 | 스낵바 |
|---|---|
| 새 항목 있음 | `walkBackupImported(dogs, walks)` "반려견 {dogs}마리 · 산책 {walks}개를 가져왔어요" |
| 새 항목 없음 | `walkBackupNothingNew` "새로 가져올 기록이 없어요" |
| 읽을 수 없음 | `walkBackupInvalid` "백업 파일을 읽지 못했어요" |
| 쓰기 실패 | `walkBackupImportFailed` "가져오지 못했어요" |

## 문자열 (ko 템플릿 · en · ja)

| 키 | ko | en | ja |
|---|---|---|---|
| `walkBackupExport` | 백업 내보내기 | Export backup | バックアップを書き出す |
| `walkBackupImport` | 백업 가져오기 | Import backup | バックアップを読み込む |
| `walkBackupImportFromFirstRun` | 백업에서 가져오기 | Restore from backup | バックアップから復元 |
| `walkBackupExportFailed` | 백업을 만들지 못했어요 | Couldn't create the backup | バックアップを作成できませんでした |
| `walkBackupImported` `{dogs}` `{walks}` (int) | 반려견 {dogs}마리 · 산책 {walks}개를 가져왔어요 | Imported {dogs, plural, =1{1 dog} other{{dogs} dogs}} · {walks, plural, =1{1 walk} other{{walks} walks}} | 犬{dogs}匹・散歩{walks}件を読み込みました |
| `walkBackupNothingNew` | 새로 가져올 기록이 없어요 | Nothing new to import | 新しく読み込む記録はありません |
| `walkBackupInvalid` | 백업 파일을 읽지 못했어요 | This isn't a readable pawlog backup | バックアップファイルを読み込めませんでした |
| `walkBackupImportFailed` | 가져오지 못했어요 | Couldn't import the backup | 読み込めませんでした |
| `walkFeedMoreTooltip` | 더보기 | More | その他 |

## 완료 조건

- [ ] 코덱 왕복 · 형식 검사 · 합치기 · 사진 쓰기 · 반쯤 쓰지 않기 테스트
- [ ] 피드 메뉴 · 첫 실행 버튼 · 라우터(가져온 뒤 피드) 테스트
- [ ] `flutter analyze` 0 · `flutter test` · `flutter build apk --debug`
- [ ] 에뮬레이터: 내보내기 → 공유 시트에 zip · 앱 데이터 지우기 → 첫 실행 화면에서 가져오기 → 피드에 기록 · 사진이 돌아온다 · 같은 파일 다시 가져오기 → "새로 가져올 기록이 없어요"
