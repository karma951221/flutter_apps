import 'package:walk/domain/chat/api_key_mask.dart';
import 'package:walk/domain/chat/chat_connection.dart';
import 'package:walk/domain/chat/chat_settings.dart';
import 'package:walk/domain/chat/chat_vendor.dart';

/// 메모리 위 [ChatSettings]. 키 · 벤더 · 상태 · 동의를 테스트가 직접 바꾼다.
/// [connection] 은 이 셋으로 만든다.
class FakeChatSettings implements ChatSettings {
  /// 키가 있으면 anthropic · valid 로 연결된 상태.
  FakeChatSettings([this.key]);

  String? key;
  ChatVendor vendor = ChatVendor.anthropic;
  ChatKeyStatus status = ChatKeyStatus.valid;

  /// [apiKey] 가 불린 횟수 — 원문 키를 읽으면 안 되는 쪽을 확인한다.
  int apiKeyCalls = 0;

  /// null 이 아니면 키 읽기 · 연결 · 끊기가 이 오류를 던진다(보안 저장소 실패).
  Object? failWith;

  void _maybeFail() {
    final error = failWith;
    if (error != null) throw error;
  }

  @override
  Future<ChatConnection?> connection() async {
    _maybeFail();
    final k = key;
    if (k == null) return null;
    return ChatConnection(
      vendor: vendor,
      keyPreview: maskApiKey(vendor, k),
      status: status,
    );
  }

  @override
  Future<bool> hasApiKey() async {
    _maybeFail();
    return key != null;
  }

  @override
  Future<String?> apiKey() async {
    apiKeyCalls++;
    _maybeFail();
    return key;
  }

  @override
  Future<void> connect(
    ChatVendor vendor,
    String key,
    ChatKeyStatus status,
  ) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) throw ArgumentError.value(key, 'key', 'empty');
    _maybeFail();
    this.key = trimmed;
    this.vendor = vendor;
    this.status = status;
  }

  @override
  Future<void> disconnect() async {
    _maybeFail();
    key = null;
  }

  @override
  Future<void> setKeyStatus(ChatKeyStatus status) async {
    if (key != null) this.status = status;
  }

  @override
  bool consented = false;

  @override
  Future<void> setConsented() async => consented = true;
}
