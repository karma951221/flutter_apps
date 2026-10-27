import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_settings_state.freezed.dart';

/// 설정 탭 "채팅" 섹션. 키 자체는 들지 않고 마지막 4자 힌트만 둔다.
@freezed
class ChatSettingsState with _$ChatSettingsState {
  @override
  final bool loading;

  /// `…abcd`. 키가 없으면 null.
  @override
  final String? keyHint;

  const ChatSettingsState({this.loading = true, this.keyHint});
}
