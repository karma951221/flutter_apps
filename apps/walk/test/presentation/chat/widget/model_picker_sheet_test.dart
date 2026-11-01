import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/domain/chat/chat_model.dart';
import 'package:walk/domain/chat/chat_model_catalog.dart';
import 'package:walk/domain/chat/chat_model_rules.dart';
import 'package:walk/domain/chat/chat_settings.dart';
import 'package:walk/domain/chat/chat_vendor.dart';
import 'package:walk/domain/chat/usecase/chat_model_choice.dart';
import 'package:walk/presentation/chat/widget/model_picker_sheet.dart';

import '../../../support/fake_chat_key_verifier.dart';
import '../../../support/fake_chat_model_catalog.dart';
import '../../../support/fake_chat_settings.dart';

ModelInfo _m(String id, String name, int day, {bool? images}) => ModelInfo(
  id: id,
  displayName: name,
  createdAt: DateTime.utc(2026, 1, day),
  supportsImages: images,
);

const _opusId = 'claude-opus-9-9';
const _sonnetId = 'claude-sonnet-9-5';
const _haikuId = 'claude-haiku-9-1';

/// 가짜 계열(sonnet)만 빠른 출력 지원, 배수 2.
final _specs = {
  ChatVendor.anthropic: [
    FastModeSpec(pattern: RegExp(r'^claude-sonnet-'), priceFactor: 2),
  ],
  ChatVendor.openai: <FastModeSpec>[],
};

/// 2026년 1월 [day]일의 한국어 yMMMd.
String _ko(int day) =>
    DateFormat.yMMMd('ko').format(DateTime.utc(2026, 1, day));

void main() {
  late FakeChatSettings settings;
  late FakeChatModelCatalog catalog;

  Future<void> setUpWith({Map<ChatVendor, List<FastModeSpec>>? specs}) async {
    settings = FakeChatSettings('sk-ant-test');
    catalog = FakeChatModelCatalog();
    await catalog.replace(ChatVendor.anthropic, [
      _m(_sonnetId, 'Claude Sonnet 9.5', 5),
      _m(_haikuId, 'Claude Haiku 9.1', 1, images: false),
      _m(_opusId, 'Claude Opus 9.9', 9),
    ], DateTime.utc(2026, 11));
    catalog.seen.remove(_opusId);
    getIt
      ..registerSingleton<ChatSettings>(settings)
      ..registerSingleton<ChatModelCatalog>(catalog)
      ..registerSingleton<ChatModelChoice>(
        ChatModelChoice(
          settings,
          catalog,
          FakeChatKeyVerifier(),
          const Clock(),
          fastModeSpecs: specs,
        ),
      );
  }

  tearDown(() => getIt.reset());

  /// 결과를 담는 버튼 하나. 누르면 시트를 연다.
  final results = <bool>[];

  Future<void> pumpHost(WidgetTester tester) async {
    results.clear();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async =>
                  results.add(await ModelPickerSheet.show(context)),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Finder inRow(String id, Finder matching) =>
      find.descendant(of: find.byKey(Key('model-row-$id')), matching: matching);

  testWidgets("최신순 행과 추천 · NEW · 사용 중 체크 · '사진은 못 봐요' 부제", (tester) async {
    await setUpWith();
    settings.selectedModel = _haikuId;
    await pumpHost(tester);
    await open(tester);

    expect(find.text('모델 고르기'), findsOneWidget);
    final ys = [_opusId, _sonnetId, _haikuId]
        .map((id) => tester.getTopLeft(find.byKey(Key('model-row-$id'))).dy)
        .toList();
    expect(ys[0] < ys[1] && ys[1] < ys[2], isTrue);

    expect(inRow(_opusId, find.text('Claude Opus 9.9')), findsOneWidget);
    expect(inRow(_opusId, find.text('NEW')), findsOneWidget);
    expect(inRow(_opusId, find.text(_ko(9))), findsOneWidget);
    expect(inRow(_sonnetId, find.text('추천')), findsOneWidget);
    expect(inRow(_sonnetId, find.text('NEW')), findsNothing);
    expect(inRow(_haikuId, find.byIcon(Icons.check)), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(inRow(_haikuId, find.text('${_ko(1)} · 사진은 못 봐요')), findsOneWidget);
    expect(find.textContaining('사진은 못 봐요'), findsOneWidget);
  });

  testWidgets('행을 누르면 저장하고 닫힌다(true) · 다시 열면 NEW 가 없다', (tester) async {
    await setUpWith();
    await pumpHost(tester);
    await open(tester);

    await tester.tap(find.byKey(const Key('model-row-$_opusId')));
    await tester.pumpAndSettle();

    expect(find.text('모델 고르기'), findsNothing);
    expect(results, [true]);
    expect(settings.selectedModel, _opusId);

    await open(tester);
    expect(find.text('NEW'), findsNothing);
    expect(inRow(_opusId, find.byIcon(Icons.check)), findsOneWidget);
  });

  testWidgets('같은 모델을 다시 고르면 닫히고 false', (tester) async {
    await setUpWith();
    await pumpHost(tester);
    await open(tester);

    await tester.tap(find.byKey(const Key('model-row-$_sonnetId')));
    await tester.pumpAndSettle();

    expect(find.text('모델 고르기'), findsNothing);
    expect(results, [false]);
  });

  testWidgets('지원 모델이 아니면 빠르게 답하기 스위치가 없다', (tester) async {
    await setUpWith();
    await pumpHost(tester);
    await open(tester);

    expect(find.byKey(const Key('model-fast-mode')), findsNothing);
    expect(find.text('빠르게 답하기'), findsNothing);
  });

  testWidgets("지원 모델이면 빠르게 답하기 스위치와 '약 2배' 부제", (tester) async {
    await setUpWith(specs: _specs);
    await pumpHost(tester);
    await open(tester);

    expect(find.byKey(const Key('model-fast-mode')), findsOneWidget);
    expect(find.text('빠르게 답하기'), findsOneWidget);
    expect(find.text('답이 더 빨리 나오지만 요금이 더 들어요(약 2배)'), findsOneWidget);
  });

  bool switchValue(WidgetTester tester) => tester
      .widget<SwitchListTile>(find.byKey(const Key('model-fast-mode')))
      .value;

  testWidgets('처음 켜면 요금 확인 창, [취소]면 꺼진 채', (tester) async {
    await setUpWith(specs: _specs);
    await pumpHost(tester);
    await open(tester);

    await tester.tap(find.byKey(const Key('model-fast-mode')));
    await tester.pumpAndSettle();

    expect(find.text('빠르게 답하기를 켤까요?'), findsOneWidget);
    expect(find.text('이 모드로 답할 때마다 Anthropic 요금이 약 2배 들어요.'), findsOneWidget);

    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    expect(find.text('빠르게 답하기를 켤까요?'), findsNothing);
    expect(switchValue(tester), isFalse);
    expect(settings.fastMode, isFalse);
    expect(settings.fastModeAcknowledged, isFalse);
  });

  testWidgets('[켜기]면 켜지고 다음엔 묻지 않는다', (tester) async {
    await setUpWith(specs: _specs);
    await pumpHost(tester);
    await open(tester);

    await tester.tap(find.byKey(const Key('model-fast-mode')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('켜기'));
    await tester.pumpAndSettle();

    // 스위치는 시트를 닫지 않는다.
    expect(find.text('모델 고르기'), findsOneWidget);
    expect(switchValue(tester), isTrue);
    expect(settings.fastMode, isTrue);

    // 끄기는 묻지 않는다.
    await tester.tap(find.byKey(const Key('model-fast-mode')));
    await tester.pumpAndSettle();
    expect(find.text('빠르게 답하기를 켤까요?'), findsNothing);
    expect(switchValue(tester), isFalse);

    // 다시 켜도 묻지 않는다.
    await tester.tap(find.byKey(const Key('model-fast-mode')));
    await tester.pumpAndSettle();
    expect(find.text('빠르게 답하기를 켤까요?'), findsNothing);
    expect(switchValue(tester), isTrue);

    // 바깥을 눌러 닫아도 바뀐 것이 있으면 true.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(results, [true]);
  });

  test('배수는 정수면 정수, 아니면 소수 한 자리', () {
    expect(ModelPickerSheet.formatFactor(2, 'ko'), '2');
    expect(ModelPickerSheet.formatFactor(1.5, 'en'), '1.5');
    expect(ModelPickerSheet.formatFactor(1.25, 'ko'), '1.3');
  });
}
