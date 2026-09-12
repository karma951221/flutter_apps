import 'package:core/core.dart';
import '../../repository/chat_repository.dart';

/// 읽음 시각을 갱신한다.
///
/// 방을 보고 있는 동안 메시지가 올 때마다 부르므로 디바운스는 호출부(bloc)가
/// 한다 — 그 시점을 아는 것이 화면이기 때문이다. 여기서는 미래 시각으로 밀어
/// 두는 것만 막는다: 기기 시계가 앞서 있으면 아직 오지 않은 메시지까지 읽은
/// 것으로 표시되어 안읽음이 영영 0 이 된다.
class MarkReadScenario {
  const MarkReadScenario(this._repository);

  final ChatRepository _repository;

  Future<Result<void>> call({required String roomId, required DateTime at}) {
    final now = DateTime.now();
    final safe = at.isAfter(now) ? now : at;
    return _repository.markRead(roomId: roomId, at: safe);
  }
}
