import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/chat/api_key_mask.dart';
import 'package:walk/domain/chat/chat_vendor.dart';

void main() {
  String body(int length) =>
      List.generate(length, (i) => 'Ab3xQRSTuvwz'[i % 12]).join();

  group('maskApiKey', () {
    test('Claude 키는 접두사 + 4글자 + 점 4개', () {
      final key = 'sk-ant-api03-${body(90)}';

      expect(maskApiKey(ChatVendor.anthropic, key), 'sk-ant-api03-Ab3x••••');
    });

    test('점 개수는 키 길이와 무관하게 4개', () {
      for (final key in [body(20), 'sk-ant-api03-${body(107)}']) {
        final masked = maskApiKey(ChatVendor.anthropic, key);
        expect(masked, endsWith(apiKeyMaskDots));
        expect('•'.allMatches(masked).length, 4);
      }
    });

    test('본문 5번째 이후 글자는 없다', () {
      final masked = maskApiKey(
        ChatVendor.anthropic,
        'sk-ant-api03-Ab3xQRSTuvwz',
      );

      expect(masked, isNot(contains('Q')));
      expect(masked, isNot(contains('QRST')));
    });

    test('접두사가 안 맞으면 앞 4글자 + 점', () {
      expect(maskApiKey(ChatVendor.anthropic, 'abcdefghijkl'), 'abcd••••');
      expect(
        maskApiKey(ChatVendor.anthropic, 'sk-ant-admin01-QRST'),
        'sk-a••••',
      );
    });

    test('8글자 미만이면 점만', () {
      expect(maskApiKey(ChatVendor.anthropic, 'abc'), '••••');
    });

    test('접두사 뒤 본문이 4글자 미만이면 접두사 + 점', () {
      expect(
        maskApiKey(ChatVendor.anthropic, 'sk-ant-api03-ab'),
        'sk-ant-api03-••••',
      );
    });

    test('openai 접두사도 가장 긴 것부터', () {
      expect(
        maskApiKey(ChatVendor.openai, 'sk-proj-Ab3xyzQRSTuvwz'),
        'sk-proj-Ab3x••••',
      );
      expect(
        maskApiKey(ChatVendor.openai, 'sk-svcacct-Ab3xyzQRST'),
        'sk-svcacct-Ab3x••••',
      );
    });
  });

  test('vendorOfKey', () {
    expect(vendorOfKey('sk-ant-api03-${body(40)}'), ChatVendor.anthropic);
    expect(vendorOfKey('sk-proj-${body(40)}'), ChatVendor.openai);
    expect(vendorOfKey('sk-svcacct-${body(40)}'), ChatVendor.openai);
    expect(vendorOfKey('sk-abc${body(40)}'), ChatVendor.openai);
    expect(vendorOfKey('sk-admin-${body(40)}'), isNull);
    expect(vendorOfKey('sk-ant-admin01-${body(40)}'), isNull);
    expect(vendorOfKey('xai-${body(40)}'), isNull);
    expect(vendorOfKey(''), isNull);
  });

  test('chatKeyPrefixHint', () {
    expect(chatKeyPrefixHint(ChatVendor.anthropic), 'sk-ant-');
  });
}
