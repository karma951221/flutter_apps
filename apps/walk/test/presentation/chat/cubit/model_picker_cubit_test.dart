import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/chat/chat_model.dart';
import 'package:walk/domain/chat/chat_model_rules.dart';
import 'package:walk/domain/chat/chat_vendor.dart';
import 'package:walk/domain/chat/usecase/chat_model_choice.dart';
import 'package:walk/presentation/chat/cubit/model_picker_cubit.dart';

import '../../../support/fake_chat_key_verifier.dart';
import '../../../support/fake_chat_model_catalog.dart';
import '../../../support/fake_chat_settings.dart';

ModelInfo _m(String id, int day, {bool? images}) => ModelInfo(
  id: id,
  displayName: id,
  createdAt: DateTime.utc(2026, 1, day),
  supportsImages: images,
);

final _opus = _m('claude-opus-9-9', 9);
final _sonnet = _m('claude-sonnet-9-5', 5);
final _haiku = _m('claude-haiku-9-1', 1, images: false);

/// 가짜 계열(sonnet)만 빠른 출력 지원, 배수 2.
final _specs = {
  ChatVendor.anthropic: [
    FastModeSpec(pattern: RegExp(r'^claude-sonnet-'), priceFactor: 2),
  ],
  ChatVendor.openai: <FastModeSpec>[],
};

void main() {
  late FakeChatSettings settings;
  late FakeChatModelCatalog catalog;
  late ModelPickerCubit cubit;

  ModelPickerCubit build({Map<ChatVendor, List<FastModeSpec>>? specs}) {
    final choice = ChatModelChoice(
      settings,
      catalog,
      FakeChatKeyVerifier(),
      const Clock(),
      fastModeSpecs: specs,
    );
    return ModelPickerCubit(choice, catalog, settings);
  }

  setUp(() async {
    settings = FakeChatSettings('sk-ant-test');
    catalog = FakeChatModelCatalog();
    // 처음 받을 때는 모두 본 것 — haiku 만 안 본 것으로 되돌린다.
    await catalog.replace(ChatVendor.anthropic, [
      _haiku,
      _opus,
      _sonnet,
    ], DateTime.utc(2026, 11));
    catalog.seen.remove('claude-opus-9-9');
    cubit = build(specs: _specs);
  });

  tearDown(() => cubit.close());

  test('행은 최신순이고 추천 · NEW · 사용 중 · 사진 못 봄이 맞다', () async {
    settings.selectedModel = 'claude-haiku-9-1';

    await cubit.load();

    final rows = cubit.state.rows;
    expect(rows.map((r) => r.id), [
      'claude-opus-9-9',
      'claude-sonnet-9-5',
      'claude-haiku-9-1',
    ]);
    expect(rows.map((r) => r.recommended), [false, true, false]);
    expect(rows.map((r) => r.isNew), [true, false, false]);
    expect(rows.map((r) => r.inUse), [false, false, true]);
    expect(rows.map((r) => r.noImages), [false, false, true]);
    expect(rows.first.createdAt, DateTime.utc(2026, 1, 9));
    expect(rows.first.label, 'claude-opus-9-9');
    expect(cubit.state.company, ChatVendor.anthropic);
  });

  test('load 뒤 markAllSeen 이 불린다(행의 isNew 는 load 때 값)', () async {
    await cubit.load();

    expect(cubit.state.rows.first.isNew, isTrue);
    expect(catalog.isNew('claude-opus-9-9'), isFalse);
  });

  test('select 는 저장', () async {
    await cubit.load();

    await cubit.select('claude-opus-9-9');

    expect(settings.selectedModel, 'claude-opus-9-9');
    expect(cubit.state.changed, isTrue);
  });

  test('추천 모델을 고르면 null 로 저장(추천을 따라간다)', () async {
    settings.selectedModel = 'claude-opus-9-9';
    await cubit.load();

    await cubit.select('claude-sonnet-9-5');

    expect(settings.selectedModel, isNull);
  });

  test('지금 모델이 지원하면 빠른 출력 · 배수, 아니면 없음', () async {
    await cubit.load();
    expect(cubit.state.fastModeAvailable, isTrue);
    expect(cubit.state.fastModeFactor, 2);

    final plain = build();
    addTearDown(plain.close);
    await plain.load();
    expect(plain.state.fastModeAvailable, isFalse);
    expect(plain.state.fastModeFactor, isNull);
  });

  test('처음 켜면 needsAck, 확인 뒤 켜짐', () async {
    await cubit.load();

    expect(await cubit.toggleFastMode(true), FastModeToggle.needsAck);
    expect(settings.fastMode, isFalse);
    expect(cubit.state.fastMode, isFalse);

    await cubit.confirmFastMode();

    expect(settings.fastModeAcknowledged, isTrue);
    expect(settings.fastMode, isTrue);
    expect(cubit.state.fastMode, isTrue);
    expect(cubit.state.changed, isTrue);
  });

  test('ack 가 있으면 바로 켜짐', () async {
    settings.fastModeAcknowledged = true;
    await cubit.load();

    expect(await cubit.toggleFastMode(true), FastModeToggle.done);

    expect(settings.fastMode, isTrue);
    expect(cubit.state.fastMode, isTrue);
  });

  test('끄기는 바로', () async {
    settings.fastMode = true;
    await cubit.load();
    expect(cubit.state.fastMode, isTrue);

    expect(await cubit.toggleFastMode(false), FastModeToggle.done);

    expect(settings.fastMode, isFalse);
    expect(cubit.state.fastMode, isFalse);
  });
}
