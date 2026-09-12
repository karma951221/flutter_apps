import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:core/core.dart';
import '../../domain/chat_policy.dart';
import '../../domain/entity/chat_room.dart';
import '../../domain/usecase/chat_use_case.dart';

/// 방 만들기 제출 상태.
///
/// 성공하면 만들어진 방을 들고 있어야 한다 — 화면이 곧바로 그 방으로 들어가기
/// 때문이다. 그래서 공용 `SubmitState` 를 쓰지 않고 여기 전용 상태를 둔다.
sealed class CreateRoomState {
  const CreateRoomState();
}

class CreateRoomIdle extends CreateRoomState {
  const CreateRoomIdle();
}

class CreateRoomInProgress extends CreateRoomState {
  const CreateRoomInProgress();
}

class CreateRoomSuccess extends CreateRoomState {
  const CreateRoomSuccess(this.room);
  final ChatRoom room;
}

class CreateRoomFailure extends CreateRoomState {
  const CreateRoomFailure(this.failure);
  final Failure failure;
}

@injectable
class CreateRoomCubit extends Cubit<CreateRoomState> {
  CreateRoomCubit(this._useCase) : super(const CreateRoomIdle());

  final ChatUseCase _useCase;

  /// 방을 만들고, 만든 사람을 그 방에 넣는다.
  ///
  /// 개설과 입장은 분리된 두 호출이다 — 트리거로 묶지 않은 이유는 개설자의
  /// 방 닉네임을 사용자가 정할 수 있어야 하기 때문이다(계획서 "정체성").
  /// 입장이 실패하면 방은 이미 만들어져 있으므로 성공으로 보고하지 않는다.
  Future<void> submit({
    required String title,
    String? description,
    required int memberLimit,
    required String nickname,
  }) async {
    if (state is CreateRoomInProgress) return;
    emit(const CreateRoomInProgress());

    final created = await _useCase.createRoom(
      title: title,
      description: description,
      memberLimit: memberLimit,
    );
    if (isClosed) return;

    switch (created) {
      case Err<ChatRoom>(:final failure):
        emit(CreateRoomFailure(failure));
      case Ok<ChatRoom>(:final value):
        final joined = await _useCase.joinRoom(
          roomId: value.id,
          nickname: nickname,
        );
        if (isClosed) return;
        emit(
          joined.when(
            ok: (_) => CreateRoomSuccess(value),
            err: CreateRoomFailure.new,
          ),
        );
    }
  }

  /// 화면이 슬라이더로 주는 값을 정책 범위로 가둔다.
  static int clampMemberLimit(int value) => value.clamp(
    ChatPolicy.memberLimitMin,
    ChatPolicy.memberLimitMax,
  );
}
