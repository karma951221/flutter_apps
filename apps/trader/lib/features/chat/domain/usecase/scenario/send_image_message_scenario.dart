import 'package:core/core.dart';
import '../../entity/chat_image_draft.dart';
import '../../repository/chat_repository.dart';

/// 사진 메시지를 보낸다.
///
/// 업로드와 메시지 삽입 둘로 나뉘는 흐름이라 저장소가 순서를 소유한다 —
/// 업로드가 먼저다. 여기서 검증할 domain 규칙은 없다(장수 제한도, 본문도
/// 없다). 그래도 scenario 를 두는 것은 나머지 동작과 진입 모양을 맞춰
/// facade 가 한 겹으로 보이게 하기 위해서다.
class SendImageMessageScenario {
  const SendImageMessageScenario(this._repository);

  final ChatRepository _repository;

  Future<Result<void>> call({
    required String id,
    required String roomId,
    required ChatImageDraft image,
  }) => _repository.sendImageMessage(id: id, roomId: roomId, image: image);
}
