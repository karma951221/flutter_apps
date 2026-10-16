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

  /// 지난 실행이 써 둔 세션을 되살린다. idle 일 때만 한다. 진행 중이면 위치를
  /// 다시 확인해 구독하고(실패는 `locationError` 로 싣는다), 끝난 세션이면
  /// finished 로 둔다. 남은 게 없거나 읽기가 실패하면 idle 그대로다.
  Future<void> restore();

  /// 위치 오류 뒤 세션을 지킨 채 위치 확인과 스트림 구독을 다시 한다.
  Future<Result<void>> resume();

  /// 세션을 지킨 채 멈춘다. 위치 스트림은 끊지 않고 들어오는 점을 버린다.
  /// 이미 멈춤 중이면 아무것도 하지 않는다. 추적 중이 아니면 walkNotFound.
  Future<Result<void>> pause();

  /// 멈춤을 닫아 그 길이를 `pausedDuration` 에 더한다. 재개 뒤 첫 점은 거리를
  /// 더하지 않는다. 진행 중이면 아무것도 하지 않는다. 추적 중이 아니면 walkNotFound.
  Future<Result<void>> unpause();

  Future<Result<WalkSession>> stop();

  /// 위치 권한을 다시 허용하러 앱 설정을 연다. 권한은 세션당 한 번만 묻기 때문에
  /// 거부 뒤에는 이 길밖에 없다.
  Future<void> openAppSettings();

  /// 꺼진 위치 서비스를 켜러 위치 설정을 연다.
  Future<void> openLocationSettings();

  /// finished → idle.
  Future<void> clear();
}
