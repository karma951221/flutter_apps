import 'package:core/core.dart';
import '../../chat_policy.dart';
import '../../repository/chat_repository.dart';

/// 텍스트 메시지를 보낸다.
///
/// [id] 는 호출부(bloc)가 이미 만들어 낙관적 버블에 쓰고 있는 값이다. 여기서
/// 새로 만들면 화면의 버블과 서버의 행이 다른 id 를 갖게 되어, 실시간으로
/// 되돌아온 내 메시지가 중복으로 쌓인다.
class SendMessageScenario {
  const SendMessageScenario(this._repository);

  final ChatRepository _repository;

  Future<Result<void>> call({
    required String id,
    required String roomId,
    required String content,
  }) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      return Future.value(
        const Err(
          Failure.validation(
            message: '보낼 내용을 입력하세요',
            field: 'content',
            failureCode: FailureCode.messageContentRequired,
          ),
        ),
      );
    }
    if (trimmed.length > ChatPolicy.messageMaxLength) {
      return Future.value(
        const Err(
          Failure.validation(
            message: '메시지는 ${ChatPolicy.messageMaxLength}자 이하여야 합니다',
            field: 'content',
            failureCode: FailureCode.messageTooLong,
          ),
        ),
      );
    }

    return _repository.sendMessage(id: id, roomId: roomId, content: trimmed);
  }
}
