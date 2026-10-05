import 'package:core/core.dart';

import '../entity/tracker_state.dart';
import '../entity/tracking_notice.dart';
import '../entity/walk_session.dart';

abstract interface class WalkTracker {
  TrackerState get current;

  /// 브로드캐스트 스트림.
  Stream<TrackerState> get states;

  Future<Result<void>> start({
    required List<String> dogIds,
    required TrackingNotice notice,
  });

  /// 위치 오류 뒤 세션을 지킨 채 위치 확인과 스트림 구독을 다시 한다.
  Future<Result<void>> resume();

  Future<Result<WalkSession>> stop();

  /// 위치 권한을 다시 허용하러 앱 설정을 연다. 권한은 세션당 한 번만 묻기 때문에
  /// 거부 뒤에는 이 길밖에 없다.
  Future<void> openAppSettings();

  /// 꺼진 위치 서비스를 켜러 위치 설정을 연다.
  Future<void> openLocationSettings();

  /// finished → idle.
  Future<void> clear();
}
