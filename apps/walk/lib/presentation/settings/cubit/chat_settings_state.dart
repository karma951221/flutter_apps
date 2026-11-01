import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/chat/chat_connection.dart';

part 'chat_settings_state.freezed.dart';

/// 물어보기 설정의 연결 행. 원문 키는 들지 않고 가린 미리보기만 둔다.
@freezed
class ChatSettingsState with _$ChatSettingsState {
  @override
  final bool loading;

  /// 미연결이면 null.
  @override
  final ChatConnection? connection;

  const ChatSettingsState({this.loading = true, this.connection});
}
