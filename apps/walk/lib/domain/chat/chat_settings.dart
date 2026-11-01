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

  /// 키 · 벤더 · 상태 · 고른 모델을 지운다. 동의(벤더) · 빠른 출력은 그대로.
  Future<void> disconnect();

  /// 지금 저장된 키가 [forKey](trim 해 비교)일 때만 기록한다 — 확인하는 동안 키를 바꾸거나
  /// 끊었으면 지난 키의 판정을 남기지 않는다. 같은 값이면 쓰지 않는다.
  /// 키를 로그에 남기거나 예외 메시지에 담지 않는다.
  Future<void> setKeyStatus(ChatKeyStatus status, {required String forKey});

  /// 연결된 벤더(prefs, 동기). 미연결이면 null. ChatSession.target 이 쓴다 — 키 존재는 보장하지 않는다(hasApiKey 로 확인).
  ChatVendor? get connectedVendor;

  /// 고른 모델 id(`chat.model`). 없으면 null(= 추천).
  /// [connect] 가 다른 벤더로 바뀌거나 [disconnect] 하면 지워진다.
  String? get selectedModel;

  Future<void> selectModel(String? id);

  /// 빠른 출력(`chat.fastMode`, 기본 false). 모델이 지원하지 않으면 값은 남고 요청에만 안 실린다.
  bool get fastMode;

  Future<void> setFastMode(bool on);

  /// 빠른 출력 요금 안내를 확인했는가(`chat.fastMode.ack`). 처음 켤 때 한 번만 묻는다.
  bool get fastModeAcknowledged;

  Future<void> acknowledgeFastMode();

  /// 전송에 동의한 벤더(`chat.consentedVendor`). 연결 벤더와 다르면 needsConsent.
  /// [disconnect] 해도 남는다 — 같은 벤더로 다시 연결하면 묻지 않는다.
  ChatVendor? get consentedVendor;

  Future<void> setConsented(ChatVendor vendor);
}
