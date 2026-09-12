import 'package:core/core.dart';
import '../../chat_policy.dart';
import '../../entity/chat_room.dart';
import '../../repository/chat_repository.dart';

/// 방을 만들기 전 입력을 다듬고 검증한다.
///
/// 정원은 화면이 슬라이더로 주더라도 여기서 한 번 더 가둔다 — DB 의
/// `chat_rooms_limit_range` 와 같은 값이고, 범위를 벗어난 값으로 왕복해
/// 실패하는 것보다 낫다.
class CreateRoomScenario {
  const CreateRoomScenario(this._repository);

  final ChatRepository _repository;

  Future<Result<ChatRoom>> call({
    required String title,
    String? description,
    int memberLimit = ChatPolicy.memberLimitDefault,
  }) {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      return Future.value(
        const Err(
          Failure.validation(
            message: '방 이름을 입력하세요',
            field: 'title',
            failureCode: FailureCode.roomTitleRequired,
          ),
        ),
      );
    }
    if (trimmedTitle.length > ChatPolicy.roomTitleMaxLength) {
      return Future.value(
        const Err(
          Failure.validation(
            message: '방 이름은 ${ChatPolicy.roomTitleMaxLength}자 이하여야 합니다',
            field: 'title',
            failureCode: FailureCode.roomTitleTooLong,
          ),
        ),
      );
    }

    // 빈 소개는 빈 문자열이 아니라 null 로 보낸다. DB 의 desc 제약은 null 을
    // 허용하고, 빈 문자열이 저장되면 "소개 없음"과 "소개가 빈 칸"이 갈린다.
    final trimmedDescription = description?.trim();
    final normalizedDescription =
        (trimmedDescription == null || trimmedDescription.isEmpty)
        ? null
        : trimmedDescription;
    if (normalizedDescription != null &&
        normalizedDescription.length > ChatPolicy.roomDescriptionMaxLength) {
      return Future.value(
        const Err(
          Failure.validation(
            message: '소개는 ${ChatPolicy.roomDescriptionMaxLength}자 이하여야 합니다',
            field: 'description',
            failureCode: FailureCode.roomDescriptionTooLong,
          ),
        ),
      );
    }

    if (memberLimit < ChatPolicy.memberLimitMin ||
        memberLimit > ChatPolicy.memberLimitMax) {
      return Future.value(
        const Err(
          Failure.validation(
            message:
                '정원은 ${ChatPolicy.memberLimitMin}명 이상 '
                '${ChatPolicy.memberLimitMax}명 이하여야 합니다',
            field: 'memberLimit',
            failureCode: FailureCode.roomMemberLimitInvalid,
          ),
        ),
      );
    }

    return _repository.createRoom(
      title: trimmedTitle,
      description: normalizedDescription,
      memberLimit: memberLimit,
    );
  }
}
