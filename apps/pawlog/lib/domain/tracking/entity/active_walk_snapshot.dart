import 'package:freezed_annotation/freezed_annotation.dart';

import 'tracking_notice.dart';
import 'walk_session.dart';

part 'active_walk_snapshot.freezed.dart';

/// 앱이 죽기 전 써 둔 진행 중 산책. [notice] 는 복구 때 같은 알림 문구를 다시 띄우려고 남긴다.
@freezed
class ActiveWalkSnapshot with _$ActiveWalkSnapshot {
  @override
  final WalkSession session;
  @override
  final TrackingNotice notice;

  const ActiveWalkSnapshot({required this.session, required this.notice});
}
