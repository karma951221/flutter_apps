import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/chat/tool/tool_result.dart';
import 'package:walk/domain/chat/tool/tool_summary.dart';

void main() {
  test('toString 은 json 내용 없이 길이 · isError · kind 만', () {
    final r = ToolResult(
      json: '{"body":"비밀 일기 본문"}',
      images: [
        ToolImage(mediaType: 'image/jpeg', bytes: Uint8List.fromList([1])),
      ],
      entryIds: const ['e1'],
      summary: const ToolSummary(kind: ChatToolKind.wiki, count: 1),
    );

    final text = r.toString();
    expect(text, isNot(contains('비밀')));
    expect(text, isNot(contains('body')));
    expect(text, isNot(contains('e1')));
    expect(text, contains('jsonLength: ${r.json.length}'));
    expect(text, contains('isError: false'));
    expect(text, contains('wiki'));
    expect(text, contains('images: 1'));
  });
}
