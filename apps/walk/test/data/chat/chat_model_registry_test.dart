import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:walk/data/chat/anthropic_chat_model.dart';
import 'package:walk/data/chat/chat_model_registry.dart';
import 'package:walk/domain/chat/chat_trace.dart';
import 'package:walk/domain/chat/chat_vendor.dart';

void main() {
  final anthropic = AnthropicChatModel(
    MockClient((_) async => http.Response('', 200)),
    const NoopChatTrace(),
  );

  test('anthropic 은 AnthropicChatModel', () {
    final model = VendorChatModelRegistry(anthropic).of(ChatVendor.anthropic);
    expect(model, isA<AnthropicChatModel>());
    expect(identical(model, anthropic), isTrue);
  });

  test('openai 는 아직 UnsupportedError', () {
    expect(
      () => VendorChatModelRegistry(anthropic).of(ChatVendor.openai),
      throwsUnsupportedError,
    );
  });
}
