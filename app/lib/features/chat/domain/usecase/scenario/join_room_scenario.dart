import '../../../../../core/error/failure.dart';
import '../../../../../core/result/result.dart';
import '../../chat_policy.dart';
import '../../repository/chat_repository.dart';

/// 방에 들어간다.
///
/// 방별 닉네임을 여기서 정규화한다. 화면은 기본값으로 프로필 닉네임을 채워
/// 주지만, 사용자가 지우고 공백만 남길 수 있으므로 빈 값은 여기서 막는다.
/// 재입장인지 첫 입장인지는 앱이 구분하지 않는다 — 저장소가 upsert 로 처리한다.
class JoinRoomScenario {
  const JoinRoomScenario(this._repository);

  final ChatRepository _repository;

  Future<Result<void>> call({
    required String roomId,
    required String nickname,
  }) {
    final trimmed = nickname.trim();
    if (trimmed.length < ChatPolicy.nicknameMinLength) {
      return Future.value(
        const Err(
          Failure.validation(
            message: '방에서 쓸 이름은 ${ChatPolicy.nicknameMinLength}자 이상이어야 합니다',
            field: 'nickname',
          ),
        ),
      );
    }
    if (trimmed.length > ChatPolicy.nicknameMaxLength) {
      return Future.value(
        const Err(
          Failure.validation(
            message: '방에서 쓸 이름은 ${ChatPolicy.nicknameMaxLength}자 이하여야 합니다',
            field: 'nickname',
          ),
        ),
      );
    }

    return _repository.joinRoom(roomId: roomId, nickname: trimmed);
  }
}
