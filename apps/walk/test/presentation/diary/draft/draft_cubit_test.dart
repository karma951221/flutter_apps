import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/chat/chat_vendor.dart';
import 'package:walk/domain/chat/usecase/chat_session.dart';
import 'package:walk/domain/diary/draft/draft_context.dart';
import 'package:walk/domain/diary/draft/draft_style.dart';
import 'package:walk/domain/diary/draft/draft_writer.dart';
import 'package:walk/domain/diary/entity/entry_media.dart';
import 'package:walk/domain/diary/entity/trash_retention.dart';
import 'package:walk/domain/diary/repository/diary_preferences.dart';
import 'package:walk/presentation/diary/draft/draft_cubit.dart';
import 'package:walk/presentation/diary/draft/draft_state.dart';

import '../../../support/diary_fixtures.dart';
import '../../../support/fake_chat_settings.dart';

/// 부를 때마다 새 스트림을 열고, 받은 인자를 모은다. 테스트가 [emit] · [finish] 로 흘린다.
class _Writer implements DraftWriter {
  final calls =
      <
        ({
          DraftContext context,
          DraftStyle style,
          bool includePhotos,
          bool polish,
          List<EntryMedia> photos,
        })
      >[];
  StreamController<DraftEvent>? _current;
  var cancelled = 0;

  @override
  bool canSeePhotos = true;

  @override
  String? get draftModel => 'claude-haiku-5-5';

  @override
  Future<DraftAvailability> availability() async =>
      const DraftAvailability.ready(ChatVendor.anthropic);

  @override
  Stream<DraftEvent> write(
    DraftContext context, {
    required DraftStyle style,
    List<EntryMedia> photos = const [],
    bool includePhotos = false,
    bool polish = false,
  }) {
    calls.add((
      context: context,
      style: style,
      includePhotos: includePhotos,
      polish: polish,
      photos: photos,
    ));
    final c = StreamController<DraftEvent>(onCancel: () => cancelled++);
    _current = c;
    return c.stream;
  }

  Future<void> emit(DraftEvent event) async {
    _current!.add(event);
    await Future<void>.delayed(Duration.zero);
  }

  /// [text] 를 조각으로 흘리고 done 으로 끝낸다.
  Future<void> answer(String text) async {
    await emit(DraftEvent.delta(text));
    await emit(DraftEvent.done(text.trim()));
    await _current!.close();
    await Future<void>.delayed(Duration.zero);
  }
}

class _Prefs implements DiaryPreferences {
  @override
  DraftStyle draftStyle = DraftStyle.polite;

  @override
  bool draftIncludePhotos = false;

  final photoWrites = <bool>[];

  @override
  Future<void> setDraftIncludePhotos(bool v) async {
    photoWrites.add(v);
    draftIncludePhotos = v;
  }

  @override
  Future<void> setDraftStyle(DraftStyle v) async => draftStyle = v;

  @override
  TrashRetention get trashRetention => TrashRetention.fallback;

  @override
  Future<void> setTrashRetention(TrashRetention v) async {}
}

void main() {
  late _Writer writer;
  late _Prefs prefs;
  late FakeChatSettings settings;
  late List<String> bodies;

  setUp(() {
    writer = _Writer();
    prefs = _Prefs();
    settings = FakeChatSettings('sk-ant-test');
    bodies = [];
  });

  DraftCubit cubitOf() =>
      DraftCubit(writer, prefs, settings, onBody: bodies.add);

  DraftContext contextFor(String memo) =>
      DraftContext(memo: memo, occurredAt: DateTime(2026, 11, 15));

  void generate(DraftCubit cubit, String body, {List<EntryMedia>? photos}) =>
      cubit.generate(
        body: body,
        contextFor: contextFor,
        photos: photos ?? const [],
      );

  test('사진 보여 주기는 설정에 기억된 값으로 시작한다', () {
    prefs.draftIncludePhotos = true;

    final cubit = cubitOf();

    expect(cubit.state.includePhotos, isTrue);
    expect(cubit.state.run, const DraftRun.idle());
  });

  test('사진 보여 주기를 바꾸면 설정에 기억한다', () async {
    final cubit = cubitOf();

    await cubit.setIncludePhotos(true);

    expect(cubit.state.includePhotos, isTrue);
    expect(prefs.photoWrites, [true]);
  });

  test('consent 는 그 벤더로의 전송 동의를 기록한다', () async {
    settings.consentedVendor = null;

    await cubitOf().consent(ChatVendor.anthropic);

    expect(settings.consentedVendor, ChatVendor.anthropic);
  });

  test('글 칸의 글을 메모로, 설정의 문체로 바로 쓴다(R-A1)', () async {
    final cubit = cubitOf();

    generate(cubit, '성수동 카페');

    expect(cubit.state.run, const DraftRun.writing());
    expect(writer.calls.single.context.memo, '성수동 카페');
    expect(writer.calls.single.style, DraftStyle.polite);
    expect(writer.calls.single.polish, isFalse);
  });

  test('조각이 오는 대로 글 칸을 채운다 — 메모를 지우고 처음부터', () async {
    final cubit = cubitOf();
    generate(cubit, '카페');

    await writer.emit(const DraftEvent.delta('카페에서 '));
    expect(cubit.state.text, '카페에서 ');
    await writer.emit(const DraftEvent.delta('책을 읽었다.'));

    expect(cubit.state.text, '카페에서 책을 읽었다.');
    expect(bodies.last, '카페에서 책을 읽었다.');
  });

  test('끝나면 다듬은 초안 · done, 원래 메모와 마지막 초안을 기억한다', () async {
    final cubit = cubitOf();
    generate(cubit, '카페');

    await writer.answer(' 카페에서 책을 읽었다. ');

    expect(cubit.state.run, const DraftRun.done());
    expect(cubit.state.text, '카페에서 책을 읽었다.');
    expect(cubit.state.memo, '카페');
    expect(cubit.state.lastDraft, '카페에서 책을 읽었다.');
    expect(bodies.last, '카페에서 책을 읽었다.');
  });

  test('실패하면 글 칸을 원래 메모로 되돌리고 이유를 알린다', () async {
    final cubit = cubitOf();
    generate(cubit, '카페');

    await writer.emit(const DraftEvent.delta('카페에서'));
    await writer.emit(const DraftEvent.failed(ChatFailure.network));

    expect(cubit.state.run, const DraftRun.failed(ChatFailure.network));
    expect(cubit.state.text, '카페');
    expect(bodies.last, '카페');
    expect(cubit.state.lastDraft, isNull);
  });

  test('동의가 없다고 끝나면 원래 메모로 되돌린다', () async {
    final cubit = cubitOf();
    generate(cubit, '카페');

    await writer.emit(const DraftEvent.needsConsent());

    expect(cubit.state.run, const DraftRun.idle());
    expect(bodies.last, '카페');
  });

  test('멈추면 구독을 끊고 그때까지의 글이 남는다', () async {
    final cubit = cubitOf();
    generate(cubit, '카페');
    await writer.emit(const DraftEvent.delta('카페에서 책을'));

    await cubit.stop();

    expect(writer.cancelled, 1);
    expect(cubit.state.run, const DraftRun.idle());
    expect(cubit.state.text, '카페에서 책을');
    expect(cubit.state.lastDraft, '카페에서 책을');
  });

  test('글이 오기 전에 멈추면 원래 메모가 남는다', () async {
    final cubit = cubitOf();
    generate(cubit, '카페');

    await cubit.stop();

    expect(cubit.state.text, '카페');
    expect(bodies.last, '카페');
    expect(cubit.state.lastDraft, isNull);
  });

  test('쓰는 중에 다시 부르면 무시한다', () async {
    final cubit = cubitOf();
    generate(cubit, '카페');

    generate(cubit, '다른 글');

    expect(writer.calls, hasLength(1));
  });

  group('다시 쓰기(R-A3)', () {
    test('글 칸이 마지막 초안 그대로면 원래 메모로 다시 쓴다', () async {
      final cubit = cubitOf();
      generate(cubit, '카페');
      await writer.answer('카페에서 책을 읽었다.');

      generate(cubit, '카페에서 책을 읽었다.');

      expect(writer.calls.last.context.memo, '카페');
      expect(writer.calls.last.polish, isFalse);
    });

    test('초안을 고쳤으면 고친 글을 다듬는다', () async {
      final cubit = cubitOf();
      generate(cubit, '카페');
      await writer.answer('카페에서 책을 읽었다.');

      generate(cubit, '카페에서 책을 읽었다. 비가 왔다.');

      expect(writer.calls.last.context.memo, '카페에서 책을 읽었다. 비가 왔다.');
      expect(writer.calls.last.polish, isTrue);
    });

    test('다듬은 초안을 그대로 다시 쓰면 같은 글을 다시 다듬는다', () async {
      final cubit = cubitOf();
      generate(cubit, '카페');
      await writer.answer('카페에서 책을 읽었다.');
      generate(cubit, '고친 글');
      await writer.answer('다듬은 글.');

      generate(cubit, '다듬은 글.');

      expect(writer.calls.last.context.memo, '고친 글');
      expect(writer.calls.last.polish, isTrue);
    });

    test('다시 쓰기가 실패하면 그 직전 글로 되돌린다', () async {
      final cubit = cubitOf();
      generate(cubit, '카페');
      await writer.answer('카페에서 책을 읽었다.');
      generate(cubit, '고친 글');

      await writer.emit(const DraftEvent.failed(ChatFailure.refused));

      expect(cubit.state.text, '고친 글');
    });
  });

  test('undo 는 원래 메모로 되돌리고 다음 ✨ 는 처음 쓰기다', () async {
    final cubit = cubitOf();
    generate(cubit, '카페');
    await writer.answer('카페에서 책을 읽었다.');

    cubit.undo();

    expect(cubit.state.text, '카페');
    expect(bodies.last, '카페');
    expect(cubit.state.lastDraft, isNull);
    generate(cubit, '카페');
    expect(writer.calls.last.polish, isFalse);
  });

  test('사진 보여 주기를 켰고 사진이 있으면 사진을 보낸다', () async {
    final cubit = cubitOf();
    await cubit.setIncludePhotos(true);

    generate(cubit, '', photos: [photoMedia('p1')]);

    expect(writer.calls.single.includePhotos, isTrue);
    expect(writer.calls.single.photos, [photoMedia('p1')]);
  });

  test('사진이 없으면 켜 있어도 보내지 않는다', () async {
    final cubit = cubitOf();
    await cubit.setIncludePhotos(true);

    generate(cubit, '카페');

    expect(writer.calls.single.includePhotos, isFalse);
  });

  test('닫으면 진행 중인 요청을 끊는다', () async {
    final cubit = cubitOf();
    generate(cubit, '카페');

    await cubit.close();

    expect(writer.cancelled, 1);
  });
}
