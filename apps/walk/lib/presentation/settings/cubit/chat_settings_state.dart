import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/chat/chat_connection.dart';
import '../../chat/widget/model_chip.dart';

part 'chat_settings_state.freezed.dart';

/// 물어보기 설정의 연결 행 · 모델 행. 원문 키는 들지 않고 가린 미리보기만 둔다.
@freezed
class ChatSettingsState with _$ChatSettingsState {
  @override
  final bool loading;

  /// 미연결이면 null.
  @override
  final ChatConnection? connection;

  /// 지금 모델(모델 행 부제). 미연결 · 목록 없음이면 null.
  @override
  final ModelChipData? model;

  /// 빠른 출력이 요청에 실린다(켜 둠 · 지금 모델이 지원). 모델 행은 보여 주기만 한다.
  @override
  final bool fastMode;

  /// 연결됐는데 모델 목록을 받지 못했다 — 모델 행이 "목록을 받지 못했어요 · 다시 시도".
  @override
  final bool modelsUnavailable;

  const ChatSettingsState({
    this.loading = true,
    this.connection,
    this.model,
    this.fastMode = false,
    this.modelsUnavailable = false,
  });
}
