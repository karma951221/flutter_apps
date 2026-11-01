import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/chat/api_key_mask.dart';
import 'package:walk/domain/chat/chat_connection.dart';
import 'package:walk/domain/chat/chat_vendor.dart';

void main() {
  const key = 'sk-ant-api03-Ab3xQRSTuvwzSECRET';

  ChatConnection connection() => ChatConnection(
    vendor: ChatVendor.anthropic,
    keyPreview: maskApiKey(ChatVendor.anthropic, key),
    status: ChatKeyStatus.valid,
  );

  test('toString 에 미리보기 외 키 글자가 없다', () {
    final text = connection().toString();

    expect(text, contains('sk-ant-api03-Ab3x••••'));
    expect(text, isNot(contains('QRST')));
    expect(text, isNot(contains('SECRET')));
  });

  test('값이 같으면 같다', () {
    expect(connection(), connection());
    expect(connection().hashCode, connection().hashCode);
    expect(
      connection(),
      isNot(
        ChatConnection(
          vendor: ChatVendor.anthropic,
          keyPreview: maskApiKey(ChatVendor.anthropic, key),
          status: ChatKeyStatus.invalid,
        ),
      ),
    );
  });
}
