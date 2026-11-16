import 'dart:io';

import 'backup_area_id.dart';

/// 백업 한 영역(일기 · 대화 · …). 파일은 모두 `root/<id.name>/` 아래에 둔다.
abstract interface class BackupAreaSource {
  BackupAreaId get id;

  /// 이 영역이 담는 저장소마다의 스키마 버전. 예: `{'diary': 1}`.
  Map<String, int> get schema;

  /// 백업 시트에 보여 줄 개수. 예: `{'entries': 120, 'media': 210}`.
  Future<Map<String, int>> counts();

  /// 내보내기에 드는 대략의 바이트 수(여유 공간 검사용).
  Future<int> estimatedBytes();

  /// 지금 데이터를 `root/<id>/` 에 쓰고 [counts] 와 같은 개수를 돌려준다.
  Future<Map<String, int>> export(Directory root);

  /// `root/<id>/` 의 참조 무결성을 확인한다. 깨졌으면
  /// `BackupException(BackupFailure.integrity)` 를 던진다.
  Future<void> validate(Directory root);

  /// 지금 데이터를 `root/<id>/` 의 것으로 바꾼다. 영역 안에서는 원자적이다 —
  /// 실패하면 바꾸기 전 그대로 남는다.
  Future<void> replace(Directory root);

  /// 모든 영역 복원이 끝난 뒤 한 번 부른다(예: 알람 다시 예약). 할 일이 없으면 no-op.
  Future<void> afterRestore();
}
