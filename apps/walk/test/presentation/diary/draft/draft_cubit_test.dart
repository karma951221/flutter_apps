import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/chat/chat_vendor.dart';
import 'package:walk/domain/chat/usecase/chat_session.dart';
import 'package:walk/domain/diary/draft/draft_context.dart';
import 'package:walk/domain/diary/draft/draft_style.dart';
import 'package:walk/domain/diary/draft/draft_writer.dart';
import 'package:walk/domain/diary/repository/diary_preferences.dart';
import 'package:walk/presentation/diary/draft/draft_cubit.dart';
import 'package:walk/presentation/diary/draft/draft_state.dart';

import '../../../support/diary_fixtures.dart';
import '../../../support/fake_chat_settings.dart';

class _Writer extends Mock implements DraftWriter {}

class _Prefs extends Mock implements DiaryPreferences {}

final _context = DraftContext(memo: '산책', occurredAt: DateTime(2026, 11, 15));

void main() {
  late _Writer writer;
  late _Prefs prefs;
  late FakeChatSettings settings;

  setUpAll(() {
    registerFallbackValue(_context);
    registerFallbackValue(DraftStyle.diary);
  });

  setUp(() {
    writer = _Writer();
    prefs = _Prefs();
    settings = FakeChatSettings('sk-ant-test');
    when(() => prefs.draftStyle).thenReturn(DraftStyle.polite);
    when(() => prefs.draftIncludePhotos).thenReturn(true);
    when(writer.availability).thenAnswer(
      (_) async => const DraftAvailability.ready(ChatVendor.anthropic),
    );
  });

  DraftCubit cubitOf() => DraftCubit(writer, prefs, settings);

  void answer(Future<DraftResult> Function() result) => when(
    () => writer.write(
      any(),
      style: any(named: 'style'),
      photos: any(named: 'photos'),
      includePhotos: any(named: 'includePhotos'),
    ),
  ).thenAnswer((_) => result());

  test('설정의 기본 문체 · 사진 기본값으로 시작하고 키 상태는 아직 모른다', () {
    final cubit = cubitOf();

    expect(cubit.state.style, DraftStyle.polite);
    expect(cubit.state.includePhotos, isTrue);
    expect(cubit.state.availability, isNull);
    expect(cubit.state.run, const DraftRun.idle());
  });

  test('load 는 키 · 동의 상태를 읽는다', () async {
    final cubit = cubitOf();

    await cubit.load();

    expect(
      cubit.state.availability,
      const DraftAvailability.ready(ChatVendor.anthropic),
    );
  });

  test('문체 · 사진을 바꿔도 설정에는 쓰지 않는다', () {
    final cubit = cubitOf();

    cubit
      ..setStyle(DraftStyle.memo)
      ..setIncludePhotos(false);

    expect(cubit.state.style, DraftStyle.memo);
    expect(cubit.state.includePhotos, isFalse);
    verifyNever(() => prefs.setDraftStyle(any()));
    verifyNever(() => prefs.setDraftIncludePhotos(any()));
  });

  test('write: 고른 문체 · 사진 스위치로 부르고 글을 done 으로', () async {
    answer(() async => const DraftResult.text('산책했다.'));
    final photos = [photoMedia('p1')];
    final cubit = cubitOf()..setStyle(DraftStyle.sns);

    await cubit.write(_context, photos);

    expect(cubit.state.run, const DraftRun.done('산책했다.'));
    verify(
      () => writer.write(
        _context,
        style: DraftStyle.sns,
        photos: photos,
        includePhotos: true,
      ),
    ).called(1);
  });

  test('사진이 없으면 스위치가 켜져 있어도 includePhotos 는 false', () async {
    answer(() async => const DraftResult.text('글'));
    final cubit = cubitOf();

    await cubit.write(_context, const []);

    verify(
      () => writer.write(
        _context,
        style: DraftStyle.polite,
        photos: const [],
        includePhotos: false,
      ),
    ).called(1);
  });

  test('쓰는 동안은 writing, 두 번 눌러도 한 번만 부른다', () async {
    final pending = Completer<DraftResult>();
    answer(() => pending.future);
    final cubit = cubitOf();

    final first = cubit.write(_context, const []);
    expect(cubit.state.run, const DraftRun.writing());
    await cubit.write(_context, const []);
    pending.complete(const DraftResult.text('글'));
    await first;

    verify(
      () => writer.write(
        any(),
        style: any(named: 'style'),
        photos: any(named: 'photos'),
        includePhotos: any(named: 'includePhotos'),
      ),
    ).called(1);
  });

  test('실패면 failed(이유)', () async {
    answer(() async => const DraftResult.failed(ChatFailure.network));
    final cubit = cubitOf();

    await cubit.write(_context, const []);

    expect(cubit.state.run, const DraftRun.failed(ChatFailure.network));
  });

  test('키가 없어 실패하면 키 상태를 다시 읽는다', () async {
    answer(() async => const DraftResult.failed(ChatFailure.noKey));
    when(
      writer.availability,
    ).thenAnswer((_) async => const DraftAvailability.noKey());
    final cubit = cubitOf();

    await cubit.write(_context, const []);

    expect(cubit.state.availability, const DraftAvailability.noKey());
  });

  test('동의가 필요하다고 돌아오면 idle 로 두고 키 상태를 다시 읽는다', () async {
    answer(() async => const DraftResult.needsConsent());
    when(writer.availability).thenAnswer(
      (_) async => const DraftAvailability.needsConsent(ChatVendor.openai),
    );
    final cubit = cubitOf();

    await cubit.write(_context, const []);

    expect(cubit.state.run, const DraftRun.idle());
    expect(
      cubit.state.availability,
      const DraftAvailability.needsConsent(ChatVendor.openai),
    );
  });

  test('멈추면 writer 를 멈추고 cancelled 는 idle', () async {
    final pending = Completer<DraftResult>();
    answer(() => pending.future);
    when(writer.cancel).thenAnswer((_) {
      if (!pending.isCompleted) pending.complete(const DraftResult.cancelled());
    });
    final cubit = cubitOf();

    final run = cubit.write(_context, const []);
    cubit.stop();
    await run;

    verify(writer.cancel).called(1);
    expect(cubit.state.run, const DraftRun.idle());
  });

  test('consent: 지금 벤더에 동의를 기록하고 ready 로', () async {
    settings.consentedVendor = null;
    when(writer.availability).thenAnswer(
      (_) async => const DraftAvailability.needsConsent(ChatVendor.anthropic),
    );
    final cubit = cubitOf();
    await cubit.load();
    when(writer.availability).thenAnswer(
      (_) async => const DraftAvailability.ready(ChatVendor.anthropic),
    );

    await cubit.consent();

    expect(settings.consentedVendor, ChatVendor.anthropic);
    expect(
      cubit.state.availability,
      const DraftAvailability.ready(ChatVendor.anthropic),
    );
  });

  test('쓰는 중에 닫으면 writer 를 멈춘다', () async {
    final pending = Completer<DraftResult>();
    answer(() => pending.future);
    when(writer.cancel).thenAnswer((_) {});
    final cubit = cubitOf();

    unawaited(cubit.write(_context, const []));
    await cubit.close();

    verify(writer.cancel).called(1);
    pending.complete(const DraftResult.cancelled());
  });
}
