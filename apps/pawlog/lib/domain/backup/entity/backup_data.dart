import 'package:freezed_annotation/freezed_annotation.dart';

import '../../dog/entity/dog.dart';
import '../../walk/entity/walk.dart';
import '../../walk/entity/walk_track_point.dart';

part 'backup_data.freezed.dart';

/// 백업 한 건에 담긴 산책. [walk] 의 `previewPoints` 는 [points] 로 만든 값이다.
@freezed
class BackupWalk with _$BackupWalk {
  @override
  final Walk walk;
  @override
  final List<WalkTrackPoint> points;

  const BackupWalk({required this.walk, required this.points});
}

/// `backup.json` 하나의 내용. 진행 중 산책은 담지 않는다.
@freezed
class BackupData with _$BackupData {
  @override
  final DateTime exportedAt;
  @override
  final List<Dog> dogs;
  @override
  final List<BackupWalk> walks;

  const BackupData({
    required this.exportedAt,
    required this.dogs,
    required this.walks,
  });
}
