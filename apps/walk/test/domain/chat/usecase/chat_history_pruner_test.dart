import 'dart:async';

import 'package:core/core.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import 'package:walk/data/chat/database/chat_database.dart';
import 'package:walk/data/chat/database/drift_chat_history_repository.dart';
import 'package:walk/domain/chat/chat_history_settings.dart';
import 'package:walk/domain/chat/chat_vendor.dart';
import 'package:walk/domain/chat/entity/chat_usage_summary.dart';
import 'package:walk/domain/chat/entity/conversation.dart';
import 'package:walk/domain/chat/repository/chat_history_repository.dart';
import 'package:walk/domain/chat/repository/chat_usage_repository.dart';
import 'package:walk/domain/chat/usecase/chat_history_pruner.dart';
import 'package:walk/domain/chat/usecase/open_conversation.dart';

import '../../../support/diary_fixtures.dart' show MutableClock;

class _MemorySettings implements ChatHistorySettings {
  _MemorySettings(this._retention);

  ChatRetention _retention;

  /// 설정하면 retention 을 읽을 때 한 번 던진다.
  Object? readError;

  @override
  ChatRetention get retention {
    final error = readError;
    if (error != null) {
      readError = null;
      throw error;
    }
    return _retention;
  }

  set retention(ChatRetention value) => _retention = value;

  @override
  Future<void> setRetention(ChatRetention value) async => _retention = value;

  @override
  WikiIndexSize get wikiIndexSize => WikiIndexSize.fallback;

  @override
  bool get useRecords => true;

  @override
  Future<void> setUseRecords(bool value) async {}

  @override
  Future<void> setWikiIndexSize(WikiIndexSize value) async {}
}

/// deleteOlderThan 에 받은 값만 기록한다. 나머지는 쓰지 않는다.
class _RecordingHistory implements ChatHistoryRepository {
  final calls = <(DateTime, String?)>[];
  Object? error;

  /// 설정하면 deleteOlderThan 이 이 future 를 기다린다.
  Completer<void>? gate;
  var running = 0;
  var maxRunning = 0;

  @override
  Future<int> deleteOlderThan(DateTime cutoff, {String? except}) async {
    running++;
    maxRunning = running > maxRunning ? running : maxRunning;
    try {
      calls.add((cutoff, except));
      if (gate != null) await gate!.future;
      if (error != null) throw error!;
      return 0;
    } finally {
      running--;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingUsage implements ChatUsageRepository {
  final cutoffs = <DateTime>[];
  Object? error;

  @override
  Future<int> deleteOlderThan(DateTime cutoff) async {
    cutoffs.add(cutoff);
    if (error != null) throw error!;
    return 0;
  }

  @override
  Future<ChatUsageMonth> month(int year, int month) =>
      throw UnimplementedError();

  @override
  Future<void> deleteAll() => throw UnimplementedError();
}

class _SeqIds extends IdGenerator {
  _SeqIds() : super(const Uuid());

  int _n = 0;

  @override
  String newId() => 'c${++_n}';
}

const _draft = ChatTurnDraft(
  question: 'q',
  answer: 'a',
  citedEntryIds: [],
  stopped: false,
  vendor: ChatVendor.anthropic,
  model: 'claude-test',
);

void main() {
  final now = DateTime(2026, 11, 15, 10);
  late _RecordingHistory history;
  late _RecordingUsage usage;
  late _MemorySettings settings;
  late OpenConversation open;
  late MutableClock clock;

  ChatHistoryPruner pruner() =>
      ChatHistoryPruner(history, usage, settings, open, clock);

  setUp(() {
    history = _RecordingHistory();
    usage = _RecordingUsage();
    settings = _MemorySettings(ChatRetention.never);
    open = OpenConversation();
    clock = MutableClock(now);
  });

  test('never 면 대화를 지우지 않는다(사용량은 정리)', () async {
    await pruner().prune();

    expect(history.calls, isEmpty);
    expect(usage.cutoffs, [DateTime(2025, 11)]);
  });

  test('30일이면 now - 30일 을 cutoff 로', () async {
    settings.retention = ChatRetention.day30;

    await pruner().prune();

    expect(history.calls.single.$1, now.subtract(const Duration(days: 30)));
  });

  test('90일이면 now - 90일', () async {
    settings.retention = ChatRetention.day90;

    await pruner().prune();

    expect(history.calls.single.$1, now.subtract(const Duration(days: 90)));
  });

  test('30일 — 실제 DB 에서 31일 전 대화는 사라지고 29일 전은 남는다', () async {
    final db = ChatDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = DriftChatHistoryRepository(db, _SeqIds(), clock);
    clock.value = now.subtract(const Duration(days: 31));
    final old = await repo.appendTurn(turn: _draft);
    clock.value = now.subtract(const Duration(days: 29));
    final recent = await repo.appendTurn(turn: _draft);
    clock.value = now;
    settings.retention = ChatRetention.day30;

    await ChatHistoryPruner(repo, usage, settings, open, clock).prune();

    expect(await repo.turns(old.conversationId), isEmpty);
    expect(await repo.turns(recent.conversationId), hasLength(1));
    expect(await repo.count(), 1);
  });

  test('열린 대화는 except 로 넘긴다', () async {
    settings.retention = ChatRetention.day30;
    open.id = 'open-1';

    await pruner().prune();

    expect(history.calls.single.$2, 'open-1');
  });

  test('사용량 cutoff 는 12개월 전 그 달 1일', () async {
    await pruner().prune();
    clock.value = DateTime(2026, 1, 3, 8);
    await pruner().prune();

    expect(usage.cutoffs, [DateTime(2025, 11), DateTime(2025)]);
  });

  test('대화 정리가 던져도 사용량은 정리하고, prune 은 던지지 않는다', () async {
    settings.retention = ChatRetention.day30;
    history.error = StateError('db');

    await expectLater(pruner().prune(), completes);

    expect(usage.cutoffs, hasLength(1));
  });

  test('사용량 정리가 던져도 prune 은 던지지 않는다', () async {
    settings.retention = ChatRetention.day30;
    usage.error = StateError('db');

    await expectLater(pruner().prune(), completes);

    expect(history.calls, hasLength(1));
  });

  test('겹쳐 부르면 차례로 돈다', () async {
    settings.retention = ChatRetention.day30;
    history.gate = Completer<void>();
    final p = pruner();

    final first = p.prune();
    final second = p.prune();
    await pumpEventQueue();
    expect(history.calls, hasLength(1));

    history.gate!.complete();
    await Future.wait([first, second]);

    expect(history.calls, hasLength(2));
    expect(history.maxRunning, 1);
  });

  test('설정 읽기가 던져도 prune 은 던지지 않고 다음 호출은 돈다', () async {
    settings
      ..retention = ChatRetention.day30
      ..readError = StateError('prefs');
    final p = pruner();

    await expectLater(p.prune(), completes);
    expect(history.calls, isEmpty);

    await expectLater(p.prune(), completes);
    expect(history.calls, hasLength(1));
    expect(usage.cutoffs, hasLength(1));
  });
}
