import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/chat/tool/tool_summary.dart';

void main() {
  test('chatToolKindOf 는 아홉 이름과 그 밖을 나눈다', () {
    expect(chatToolKindOf('search_diary'), ChatToolKind.searchDiary);
    expect(chatToolKindOf('view_entry_photos'), ChatToolKind.viewPhotos);
    expect(chatToolKindOf('list_diary_index'), ChatToolKind.diaryIndex);
    expect(chatToolKindOf('daily_steps'), ChatToolKind.dailySteps);
    expect(chatToolKindOf('wake_records'), ChatToolKind.wakeRecords);
    expect(chatToolKindOf('read_wiki'), ChatToolKind.wiki);
    expect(chatToolKindOf('web_search'), ChatToolKind.webSearch);
    expect(chatToolKindOf('list_files'), ChatToolKind.listFiles);
    expect(chatToolKindOf('read_file'), ChatToolKind.readFile);
    expect(chatToolKindOf('nope'), ChatToolKind.other);
  });

  test('ToolInputSummary.toString 에 검색어가 없다', () {
    final s = ToolInputSummary(
      kind: ChatToolKind.searchDiary,
      from: DateTime(2026, 10, 1),
      to: DateTime(2026, 10, 5),
      query: '비밀검색어',
    );
    expect(s.toString(), isNot(contains('비밀검색어')));
    expect(s.toString(), contains('searchDiary'));
  });
}
