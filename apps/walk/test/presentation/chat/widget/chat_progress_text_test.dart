import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/domain/chat/tool/tool_summary.dart';
import 'package:walk/presentation/chat/cubit/chat_progress.dart';
import 'package:walk/presentation/chat/widget/chat_progress_text.dart';

void main() {
  late AppLocalizations ko;
  late AppLocalizations en;

  setUpAll(() async {
    await initializeDateFormatting('ko');
    await initializeDateFormatting('en');
    ko = await AppLocalizations.delegate.load(const Locale('ko'));
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  ChatProgressStep tool(
    ChatToolKind kind, {
    DateTime? from,
    DateTime? to,
    String? query,
    String? name,
    ToolSummary? result,
  }) => ChatProgressStep.tool(
    callId: 'c1',
    kind: kind,
    input: ToolInputSummary(
      kind: kind,
      from: from,
      to: to,
      query: query,
      name: name,
    ),
    result: result,
  );

  group('도구 단계는 라벨(기간)', () {
    test('search_diary 6/1~6/7', () {
      final step = tool(
        ChatToolKind.searchDiary,
        from: DateTime(2026, 6, 1),
        to: DateTime(2026, 6, 7),
      );
      expect(chatProgressStepText(ko, 'ko', step), '일기 찾는 중(6월 1일~6월 7일)');
      expect(
        chatProgressStepText(en, 'en', step),
        'Searching diary (Jun 1–Jun 7)',
      );
    });

    test('같은 날이면 날짜 하나', () {
      final step = tool(
        ChatToolKind.wakeRecords,
        from: DateTime(2026, 6, 1),
        to: DateTime(2026, 6, 1),
      );
      expect(chatProgressStepText(ko, 'ko', step), '알람 기록 보는 중(6월 1일)');
    });

    test("검색어면 '바다'", () {
      final step = tool(ChatToolKind.searchDiary, query: '바다');
      expect(chatProgressStepText(ko, 'ko', step), "일기 찾는 중('바다')");
      expect(chatProgressStepText(en, 'en', step), 'Searching diary ("바다")');
    });

    test("웹 검색은 '웹 검색 중('검색어')', 결과 문구 없음", () {
      final step = tool(ChatToolKind.webSearch, query: '오늘 날씨');
      expect(chatProgressStepText(ko, 'ko', step), "웹 검색 중('오늘 날씨')");
      expect(
        chatProgressStepText(en, 'en', step),
        'Searching the web ("오늘 날씨")',
      );
      expect(
        chatProgressStepText(ko, 'ko', tool(ChatToolKind.webSearch)),
        '웹 검색 중',
      );
      final searched = tool(
        ChatToolKind.webSearch,
        query: '오늘 날씨',
        result: const ToolSummary(kind: ChatToolKind.webSearch, count: 3),
      );
      expect(chatProgressTimelineText(ko, 'ko', searched), "웹 검색 중('오늘 날씨')");
    });

    test('걸음은 날 수', () {
      final step = tool(
        ChatToolKind.dailySteps,
        from: DateTime(2026, 10, 25),
        to: DateTime(2026, 10, 31),
      );
      expect(chatProgressStepText(ko, 'ko', step), '걸음 수 보는 중(7일)');
      expect(chatProgressStepText(en, 'en', step), 'Checking steps (7 days)');
    });

    test('작업 폴더 — 보는 중 · 파일 개수, 파일 읽는 중 · 이름', () {
      expect(
        chatProgressStepText(ko, 'ko', tool(ChatToolKind.listFiles)),
        '작업 폴더 보는 중',
      );
      expect(
        chatProgressStepText(en, 'en', tool(ChatToolKind.listFiles)),
        'Viewing workspace',
      );
      final listed = tool(
        ChatToolKind.listFiles,
        result: const ToolSummary(kind: ChatToolKind.listFiles, count: 3),
      );
      expect(chatProgressStepText(ko, 'ko', listed), '파일 3개');
      expect(chatProgressStepText(en, 'en', listed), '3 files');
      expect(chatProgressTimelineText(ko, 'ko', listed), '작업 폴더 보는 중 — 파일 3개');
      final reading = tool(ChatToolKind.readFile, name: '메모.md');
      expect(chatProgressStepText(ko, 'ko', reading), '파일 읽는 중 · 메모.md');
      expect(chatProgressStepText(en, 'en', reading), 'Reading file · 메모.md');
      expect(
        chatProgressStepText(ko, 'ko', tool(ChatToolKind.readFile)),
        '파일 읽는 중',
      );
      // 읽은 뒤에도 이름 라벨 그대로 — 개수 문구 없음.
      final read = tool(
        ChatToolKind.readFile,
        name: '${'가' * 20}…',
        result: const ToolSummary(kind: ChatToolKind.readFile, count: 1),
      );
      expect(chatProgressStepText(ko, 'ko', read), '파일 읽는 중 · ${'가' * 20}…');
      expect(
        chatProgressTimelineText(ko, 'ko', read),
        '파일 읽는 중 · ${'가' * 20}…',
      );
    });

    test('입력이 없으면 라벨만 — 위키 · 기타 포함', () {
      expect(
        chatProgressStepText(
          ko,
          'ko',
          const ChatProgressStep.tool(
            callId: 'c',
            kind: ChatToolKind.viewPhotos,
          ),
        ),
        '사진 보는 중',
      );
      expect(
        chatProgressStepText(ko, 'ko', tool(ChatToolKind.wiki)),
        '위키 읽는 중',
      );
      expect(
        chatProgressStepText(ko, 'ko', tool(ChatToolKind.other)),
        '기록 보는 중',
      );
    });
  });

  test('결과가 있으면 결과 문구, 0개면 찾은 기록 없음, 오류면 라벨', () {
    expect(
      chatProgressStepText(
        ko,
        'ko',
        tool(
          ChatToolKind.searchDiary,
          result: const ToolSummary(kind: ChatToolKind.searchDiary, count: 5),
        ),
      ),
      '일기 5개 찾음',
    );
    expect(
      chatProgressStepText(
        en,
        'en',
        tool(
          ChatToolKind.viewPhotos,
          result: const ToolSummary(kind: ChatToolKind.viewPhotos, count: 1),
        ),
      ),
      '1 photo',
    );
    expect(
      chatProgressStepText(
        ko,
        'ko',
        tool(
          ChatToolKind.dailySteps,
          result: const ToolSummary(kind: ChatToolKind.dailySteps, count: 0),
        ),
      ),
      '찾은 기록 없음',
    );
    expect(
      chatProgressStepText(
        ko,
        'ko',
        tool(
          ChatToolKind.wakeRecords,
          result: const ToolSummary(
            kind: ChatToolKind.wakeRecords,
            count: 0,
            isError: true,
          ),
        ),
      ),
      '알람 기록 보는 중',
    );
  });

  test('단계 문구 — 보내는 중 · 생각 · 노트 · 답 쓰는 중 · 멈춤', () {
    expect(
      chatProgressStepText(ko, 'ko', const ChatProgressStep.sending()),
      '보내는 중',
    );
    expect(
      chatProgressStepText(ko, 'ko', const ChatProgressStep.thinking()),
      '생각하는 중',
    );
    expect(
      chatProgressStepText(ko, 'ko', const ChatProgressStep.note('볼게요')),
      '볼게요',
    );
    expect(
      chatProgressStepText(ko, 'ko', const ChatProgressStep.writing()),
      '답 쓰는 중',
    );
    expect(
      chatProgressStepText(ko, 'ko', const ChatProgressStep.stopped()),
      '멈춤',
    );
  });

  test('펼친 목록 — 도구는 라벨 — 결과, 끝은 답 쓰기', () {
    final step = tool(
      ChatToolKind.wakeRecords,
      from: DateTime(2026, 10, 25),
      to: DateTime(2026, 10, 31),
      result: const ToolSummary(kind: ChatToolKind.wakeRecords, count: 7),
    );
    expect(
      chatProgressTimelineText(ko, 'ko', step),
      '알람 기록 보는 중(10월 25일~10월 31일) — 기상 기록 7회',
    );
    expect(
      chatProgressTimelineText(ko, 'ko', const ChatProgressStep.writing()),
      '답 쓰기',
    );
  });

  group('요약', () {
    final start = DateTime(2026, 11, 1);
    ChatProgressStep call(String id) =>
        ChatProgressStep.tool(callId: id, kind: ChatToolKind.searchDiary);

    test("도구 3번 9초 → '기록 3번 찾아봄 · 9초'", () {
      final progress = ChatProgress(
        startedAt: start,
        steps: [
          call('a'),
          call('b'),
          call('c'),
          const ChatProgressStep.writing(),
        ],
        elapsedSeconds: 9,
        running: false,
      );
      expect(chatProgressSummaryText(ko, progress), '기록 3번 찾아봄 · 9초');
      expect(
        chatProgressSummaryText(en, progress),
        'Checked records 3 times · 9s',
      );
    });

    test("도구 0번 → '9초'", () {
      final progress = ChatProgress(
        startedAt: start,
        steps: const [ChatProgressStep.writing()],
        elapsedSeconds: 9,
        running: false,
      );
      expect(chatProgressSummaryText(ko, progress), '9초');
    });

    test("멈춤 → '멈춤 · 기록 1번 찾아봄 · 4초'", () {
      final progress = ChatProgress(
        startedAt: start,
        steps: [call('a'), const ChatProgressStep.stopped()],
        elapsedSeconds: 4,
        running: false,
      );
      expect(chatProgressSummaryText(ko, progress), '멈춤 · 기록 1번 찾아봄 · 4초');
    });
  });
}
