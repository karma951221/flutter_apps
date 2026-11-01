import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/chat/entity/chat_usage_summary.dart';
import 'package:walk/presentation/settings/cubit/chat_usage_cubit.dart';

import '../../../support/diary_fixtures.dart';
import '../../../support/fake_chat_history.dart';

ChatUsageMonth _month(int year, int month, int questions) => ChatUsageMonth(
  year: year,
  month: month,
  totals: ChatUsageTotals(
    questions: questions,
    inputTokens: 10,
    outputTokens: 5,
    cacheReadTokens: 0,
  ),
  rows: const [],
);

void main() {
  late MutableClock clock;
  late FakeChatUsageRepository usage;
  late ChatUsageCubit cubit;

  setUp(() {
    clock = MutableClock(DateTime(2026, 11, 15));
    usage = FakeChatUsageRepository({
      (2026, 11): _month(2026, 11, 4),
      (2026, 10): _month(2026, 10, 2),
    });
    cubit = ChatUsageCubit(usage, clock);
  });
  tearDown(() => cubit.close());

  test('처음은 2026-11', () async {
    await cubit.load();

    expect((cubit.state.year, cubit.state.month), (2026, 11));
    expect(cubit.state.usage?.totals.questions, 4);
    expect(cubit.state.loading, isFalse);
  });

  test('previousMonth 는 10월을 읽는다', () async {
    await cubit.load();
    await cubit.previousMonth();

    expect((cubit.state.year, cubit.state.month), (2026, 10));
    expect(cubit.state.usage?.totals.questions, 2);
    expect(usage.reads.last, (2026, 10));
  });

  test('2025-11 에서 더 뒤로 못 간다', () async {
    await cubit.load();
    for (var i = 0; i < 12; i++) {
      expect(cubit.canGoBack, isTrue, reason: '$i');
      await cubit.previousMonth();
    }

    expect((cubit.state.year, cubit.state.month), (2025, 11));
    expect(cubit.canGoBack, isFalse);
    await cubit.previousMonth();
    expect((cubit.state.year, cubit.state.month), (2025, 11));
  });

  test('이번 달에서 앞으로 못 간다', () async {
    await cubit.load();

    expect(cubit.canGoForward, isFalse);
    await cubit.nextMonth();
    expect((cubit.state.year, cubit.state.month), (2026, 11));

    await cubit.previousMonth();
    expect(cubit.canGoForward, isTrue);
    await cubit.nextMonth();
    expect((cubit.state.year, cubit.state.month), (2026, 11));
  });

  test('1월에서 previousMonth 는 지난해 12월', () async {
    clock.value = DateTime(2027, 1, 5);
    final january = ChatUsageCubit(usage, clock);
    addTearDown(january.close);
    await january.load();

    await january.previousMonth();

    expect((january.state.year, january.state.month), (2026, 12));
  });

  test('clear 는 deleteAll 뒤 다시 읽는다', () async {
    await cubit.load();
    final readsBefore = usage.reads.length;

    await cubit.clear();

    expect(usage.deleteAllCalls, 1);
    expect(usage.reads.length, readsBefore + 1);
    expect(cubit.state.usage?.totals.questions, 0);
  });

  test('읽기가 실패하면 로딩을 멈춘다', () async {
    final failing = ChatUsageCubit(_FailingUsage(), clock);
    addTearDown(failing.close);

    await failing.load();

    expect(failing.state.loading, isFalse);
    expect(failing.state.usage, isNull);
  });
}

class _FailingUsage extends FakeChatUsageRepository {
  @override
  Future<ChatUsageMonth> month(int year, int month) async =>
      throw StateError('read failed');
}
