import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/chat/chat_model.dart';
import 'package:walk/domain/chat/chat_vendor.dart';

void main() {
  test('ModelRequest.toString 에 키 · system · 메시지 글이 없다', () {
    const request = ModelRequest(
      apiKey: 'sk-ant-secret-key',
      model: 'claude-opus-5-5',
      system: '비밀 시스템 프롬프트',
      messages: [
        ChatMessage.user('비밀 질문'),
        ChatMessage.assistant(parts: [AssistantPart.text('비밀 답')]),
        ChatMessage.toolResults([
          ToolResultPart(callId: 'tu_1', json: '{"secret":"도구 값"}'),
        ]),
      ],
      tools: [ToolSpec(name: 'search_diary', description: 'd', parameters: {})],
    );

    final text = request.toString();

    for (final secret in ['sk-ant', '비밀', '도구 값', 'secret']) {
      expect(text, isNot(contains(secret)), reason: secret);
    }
    expect(text, contains('claude-opus-5-5'));
    expect(text, contains('3'));
  });

  test('메시지 · 이벤트 toString 에 질문 · 답 · 도구 입력값이 없다', () {
    final values = <Object>[
      const ChatMessage.user('비밀 질문'),
      const ChatMessage.assistant(
        parts: [
          AssistantPart.text('비밀 답'),
          AssistantPart.toolCall(id: 't', name: 'n', input: {'q': '비밀 입력'}),
        ],
      ),
      const ChatMessage.toolResults([
        ToolResultPart(callId: 't', json: '비밀 결과'),
      ]),
      const ModelEvent.textDelta('비밀 답'),
      const ModelEvent.toolCallReady(id: 't', name: 'n', input: {'q': '비밀'}),
    ];
    for (final value in values) {
      expect(value.toString(), isNot(contains('비밀')));
    }
  });

  test('ToolSpec 은 값이 같으면 같다', () {
    ToolSpec spec() => const ToolSpec(
      name: 'daily_steps',
      description: '걸음',
      parameters: {
        'type': 'object',
        'properties': {
          'from': {'type': 'string'},
        },
        'required': ['from'],
      },
    );

    expect(spec(), spec());
    expect(spec().hashCode, spec().hashCode);
    expect(
      spec(),
      isNot(
        const ToolSpec(name: 'daily_steps', description: '걸음', parameters: {}),
      ),
    );
  });

  test('ChatVendor 는 anthropic · openai', () {
    expect(ChatVendor.values, [ChatVendor.anthropic, ChatVendor.openai]);
  });
}
