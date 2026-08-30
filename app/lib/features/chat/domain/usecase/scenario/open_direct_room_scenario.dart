import '../../../../../core/result/result.dart';
import '../../repository/chat_repository.dart';

/// 상대와의 DM 방을 연다 (없으면 만든다).
///
/// 검증할 입력이 없다 — RPC `open_direct_room` 이 차단 여부까지 전부 판정한다.
class OpenDirectRoomScenario {
  const OpenDirectRoomScenario(this._repository);

  final ChatRepository _repository;

  Future<Result<String>> call(String partnerId) =>
      _repository.openDirectRoom(partnerId);
}
