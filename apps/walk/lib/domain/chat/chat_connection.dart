import 'package:freezed_annotation/freezed_annotation.dart';

import 'chat_vendor.dart';

part 'chat_connection.freezed.dart';

/// 키 확인 결과. 저장만 하고 아직 확인 못 했으면 unverified.
enum ChatKeyStatus { unverified, valid, invalid }

/// 화면에 보여도 되는 연결 정보. 원문 키는 없다.
@freezed
class ChatConnection with _$ChatConnection {
  @override
  final ChatVendor vendor;

  /// [maskApiKey] 결과. 본문 앞 4글자 뒤는 늘 `••••`.
  @override
  final String keyPreview;
  @override
  final ChatKeyStatus status;

  const ChatConnection({
    required this.vendor,
    required this.keyPreview,
    required this.status,
  });
}
