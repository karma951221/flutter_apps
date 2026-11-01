import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:walk/data/chat/anthropic_chat_model.dart';
import 'package:walk/data/chat/chat_model_registry.dart';
import 'package:walk/data/chat/openai_chat_model.dart';
import 'package:walk/domain/chat/chat_trace.dart';
import 'package:walk/domain/chat/chat_vendor.dart';

void main() {
  final client = MockClient((_) async => http.Response('', 200));
  final anthropic = AnthropicChatModel(client, const NoopChatTrace());
  final openai = OpenAiChatModel(client, const NoopChatTrace());
  final registry = VendorChatModelRegistry(anthropic, openai);

  test('anthropic 은 AnthropicChatModel', () {
    final model = registry.of(ChatVendor.anthropic);
    expect(model, isA<AnthropicChatModel>());
    expect(identical(model, anthropic), isTrue);
  });

  test('openai 는 OpenAiChatModel', () {
    final model = registry.of(ChatVendor.openai);
    expect(model, isA<OpenAiChatModel>());
    expect(identical(model, openai), isTrue);
  });

  test('벤더마다 어댑터의 vendor 가 같다', () {
    for (final vendor in ChatVendor.values) {
      expect(registry.of(vendor).vendor, vendor);
    }
  });
}
