import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/chat/chat_settings.dart';
import '../../../domain/chat/chat_vendor.dart';

part 'connection_status_cubit.freezed.dart';

/// 설정 탭 "API 키 · 연결" 절이 보이는 연결 상태. 키 원문은 없다.
///
/// 외부 서비스가 늘면(길찾기 ODsay 키 등) 여기에 필드를 더하고 [ConnectionStatusCubit.load] 에서 읽는다.
@freezed
class ConnectionStatus with _$ConnectionStatus {
  /// 물어보기에 연결된 벤더. 키가 없으면 null.
  @override
  final ChatVendor? ai;

  /// 한 번이라도 읽었는지. 읽기 전에는 부제를 비운다.
  @override
  final bool loaded;

  const ConnectionStatus({this.ai, this.loaded = false});
}

/// 셸이 하나 두고 설정 탭이 보일 때 다시 읽는다.
class ConnectionStatusCubit extends Cubit<ConnectionStatus> {
  ConnectionStatusCubit(this._chat) : super(const ConnectionStatus());

  final ChatSettings _chat;

  Future<void> load() async {
    ChatVendor? ai;
    try {
      ai = (await _chat.connection())?.vendor;
    } on Object {
      // 보안 저장소를 못 읽으면 연결 안 됨으로 보인다 — 물어보기 설정 화면이 자세히 알린다.
      ai = null;
    }
    if (!isClosed) emit(ConnectionStatus(ai: ai, loaded: true));
  }
}
