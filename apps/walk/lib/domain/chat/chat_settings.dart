import 'chat_connection.dart';
import 'chat_vendor.dart';

/// 채팅 설정 — AI 연결(키는 보안 저장소)과 데이터 전송 동의.
abstract interface class ChatSettings {
  /// 미연결이면 null. 보안 저장소를 읽지 못하면 그 항목을 지우고 null.
  Future<ChatConnection?> connection();

  /// 키가 있는가(Q5). 물어보기 탭이 쓴다.
  Future<bool> hasApiKey();

  /// 원문 키. ChatSession · ChatKeyVerifier 만 부른다.
  Future<String?> apiKey();

  /// [key] 를 trim 해 연결한다. 빈 문자열이면 ArgumentError.
  /// 보안 저장소 쓰기가 끝난 뒤에만 벤더 · 상태를 바꾼다 — 쓰기가 실패하면 기존 연결 그대로(예외는 그대로 던짐).
  /// 키를 쓴 뒤 벤더 · 상태 쓰기가 실패하면 상태를 지워(다음 읽기는 unverified) 예외를 던진다.
  Future<void> connect(ChatVendor vendor, String key, ChatKeyStatus status);

  /// 키 · 벤더 · 상태를 지운다. 동의는 그대로.
  Future<void> disconnect();

  /// 지금 저장된 키가 [forKey](trim 해 비교)일 때만 기록한다 — 확인하는 동안 키를 바꾸거나
  /// 끊었으면 지난 키의 판정을 남기지 않는다. 같은 값이면 쓰지 않는다.
  /// 키를 로그에 남기거나 예외 메시지에 담지 않는다.
  Future<void> setKeyStatus(ChatKeyStatus status, {required String forKey});

  /// 전송 안내에 동의했는가.
  bool get consented;

  Future<void> setConsented();
}
