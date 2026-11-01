import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/domain/chat/chat_connection.dart';
import 'package:walk/domain/chat/chat_model.dart';
import 'package:walk/domain/chat/chat_model_catalog.dart';
import 'package:walk/domain/chat/chat_model_rules.dart';
import 'package:walk/domain/chat/chat_settings.dart';
import 'package:walk/domain/chat/chat_vendor.dart';
import 'package:walk/domain/chat/usecase/chat_key_verifier.dart';
import 'package:walk/domain/chat/usecase/chat_model_choice.dart';
import 'package:walk/presentation/settings/widget/chat_settings_section.dart';

import '../../../support/fake_chat_key_verifier.dart';
import '../../../support/fake_chat_model_catalog.dart';
import '../../../support/fake_chat_settings.dart';

const _row = Key('settings-chat-key');
const _change = Key('settings-chat-change-key');
const _delete = Key('settings-chat-delete');
const _switch = Key('settings-chat-switch-vendor');
const _glow = Key('row-highlight-glow');
const _savedKey = 'sk-ant-api03-xyz1234';
const _typedKey = 'sk-ant-api03-abcd5678';
const _model = Key('settings-chat-model');
const _sonnet = ModelInfo(
  id: 'claude-sonnet-9-5',
  displayName: 'Claude Sonnet 9.5',
);
const _opus = ModelInfo(id: 'claude-opus-9-9', displayName: 'Claude Opus 9.9');

/// 연결 정보를 끝내 돌려주지 않는 설정 — 읽는 중 모습.
class _LoadingSettings extends FakeChatSettings {
  final _never = Completer<ChatConnection?>();

  @override
  Future<ChatConnection?> connection() => _never.future;
}

void main() {
  late FakeChatSettings settings;
  late FakeChatKeyVerifier verifier;
  late FakeChatModelCatalog catalog;

  setUp(() {
    settings = FakeChatSettings();
    verifier = FakeChatKeyVerifier();
    catalog = FakeChatModelCatalog();
    getIt
      ..registerSingleton<ChatSettings>(settings)
      ..registerSingleton<ChatKeyVerifier>(verifier)
      ..registerSingleton<ChatModelCatalog>(catalog)
      ..registerSingleton<ChatModelChoice>(
        ChatModelChoice(
          settings,
          catalog,
          verifier,
          const Clock(),
          fastModeSpecs: {
            ChatVendor.anthropic: [
              FastModeSpec(pattern: RegExp('sonnet'), priceFactor: 2),
            ],
          },
        ),
      );
  });
  tearDown(() => getIt.reset());

  Future<void> pump(
    WidgetTester tester, {
    bool highlightConnection = false,
    bool settle = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChatSettingsSection(
              highlightConnection: highlightConnection,
            ),
          ),
        ),
      ),
    );
    if (settle) await tester.pumpAndSettle();
  }

  double glow(WidgetTester tester) =>
      tester.widget<FadeTransition>(find.byKey(_glow)).opacity.value;

  /// [duration] 동안 잘게 넘기며 본 glow 불투명도의 최댓값.
  Future<double> peakGlow(
    WidgetTester tester, {
    Duration duration = const Duration(seconds: 3),
  }) async {
    var peak = glow(tester);
    const step = Duration(milliseconds: 50);
    for (var t = Duration.zero; t < duration; t += step) {
      await tester.pump(step);
      if (glow(tester) > peak) peak = glow(tester);
    }
    return peak;
  }

  Color? colorOf(WidgetTester tester, String text) =>
      tester.widget<Text>(find.text(text)).style?.color;

  ThemeData theme(WidgetTester tester) =>
      Theme.of(tester.element(find.byKey(_row)));

  /// 연결 행 → 벤더 시트에서 Claude → 키를 넣어 저장 · 요금 경고 [확인]까지.
  Future<void> connectThroughDialog(WidgetTester tester) async {
    await tester.tap(find.byKey(_row));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('vendor-row-anthropic')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('chat-key-input')), _typedKey);
    await tester.pump();
    await tester.tap(find.byKey(const Key('chat-key-save')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('확인'));
    await tester.pump();
    await tester.pump();
  }

  testWidgets("미연결이면 'AI 연결' · 설명 · '연결하기'가 보이고 키 바꾸기 · 연결 끊기 행이 없다", (
    tester,
  ) async {
    await pump(tester);

    expect(
      find.descendant(of: find.byKey(_row), matching: find.text('AI 연결')),
      findsOneWidget,
    );
    expect(
      find.text('Claude · GPT 중 하나의 키를 넣으면 물어보기를 쓸 수 있어요'),
      findsOneWidget,
    );
    expect(find.text('연결하기'), findsOneWidget);
    expect(colorOf(tester, '연결하기'), theme(tester).colorScheme.primary);
    expect(find.byIcon(Icons.power_outlined), findsOneWidget);
    expect(find.byKey(_change), findsNothing);
    expect(find.byKey(_delete), findsNothing);
    expect(find.byKey(_switch), findsNothing);
    // 보낼 곳이 정해지지 않았다 — 전송 안내는 연결된 뒤에.
    expect(find.textContaining('전송돼요'), findsNothing);
  });

  testWidgets("섹션 머리글을 따로 두지 않는다 — 'AI 연결'은 연결 행 제목 하나", (tester) async {
    await pump(tester);

    expect(find.text('AI 연결'), findsOneWidget);
    expect(find.text('채팅'), findsNothing);
  });

  testWidgets("valid 면 모노그램 C · 'Claude' · 마스킹 키 · '연결됨'", (tester) async {
    settings.key = _savedKey;
    await pump(tester);

    expect(find.text('C'), findsOneWidget);
    expect(find.text('Claude'), findsOneWidget);
    expect(find.text('sk-ant-api03-xyz1••••'), findsOneWidget);
    expect(find.text('연결됨'), findsOneWidget);
    expect(colorOf(tester, '연결됨'), theme(tester).colorScheme.primary);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    expect(find.byKey(_change), findsOneWidget);
    expect(find.byKey(_delete), findsOneWidget);
    expect(find.textContaining('연결한 AI(Claude)로 전송돼요'), findsOneWidget);
  });

  testWidgets("unverified 면 '확인 전'", (tester) async {
    settings
      ..key = _savedKey
      ..status = ChatKeyStatus.unverified;
    await pump(tester);

    expect(find.text('확인 전'), findsOneWidget);
    expect(colorOf(tester, '확인 전'), theme(tester).colorScheme.onSurfaceVariant);
    expect(find.text('연결됨'), findsNothing);
  });

  testWidgets("invalid 면 '키를 확인해 주세요'(오류 색)", (tester) async {
    settings
      ..key = _savedKey
      ..status = ChatKeyStatus.invalid;
    await pump(tester);

    expect(find.text('키를 확인해 주세요'), findsOneWidget);
    expect(colorOf(tester, '키를 확인해 주세요'), theme(tester).colorScheme.error);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets("키를 넣어 정상이면 '…Claude 에 연결했어요' 스낵바와 연결 행 glow 가 한 번 재생된다", (
    tester,
  ) async {
    await pump(tester);
    expect(glow(tester), 0);

    await connectThroughDialog(tester);

    expect(find.text('Claude 에 연결했어요'), findsOneWidget);
    expect(
      tester.widget<SnackBar>(find.byType(SnackBar)).backgroundColor,
      theme(tester).colorScheme.primaryContainer,
    );
    expect(await peakGlow(tester), greaterThan(0));
    await tester.pumpAndSettle();
    expect(glow(tester), 0);
    expect(find.text('연결됨'), findsOneWidget);
    expect(find.text('sk-ant-api03-abcd••••'), findsOneWidget);
    expect(settings.key, _typedKey);
  });

  testWidgets("확인 못 함으로 저장하면 info 스낵바 '키를 저장했어요. 연결되면 확인할게요'와 '확인 전'", (
    tester,
  ) async {
    verifier.result = const ModelListResult.unreachable();
    await pump(tester);

    await connectThroughDialog(tester);

    expect(find.text('키를 저장했어요. 연결되면 확인할게요'), findsOneWidget);
    expect(
      tester.widget<SnackBar>(find.byType(SnackBar)).backgroundColor,
      isNull,
    );
    await tester.pumpAndSettle();
    expect(find.text('확인 전'), findsOneWidget);
    expect(settings.status, ChatKeyStatus.unverified);
  });

  testWidgets('연결됨에서 키 바꾸기를 누르면 같은 대화상자가 빈 칸으로 열린다', (tester) async {
    settings.key = _savedKey;
    await pump(tester);

    await tester.tap(find.byKey(_change));
    await tester.pumpAndSettle();

    expect(find.text('Claude API 키 넣기'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('chat-key-input')))
          .controller!
          .text,
      isEmpty,
    );
  });

  testWidgets("연결 끊기를 확인하면 지우고 '연결을 끊었어요'", (tester) async {
    settings.key = _savedKey;
    await pump(tester);

    await tester.tap(find.byKey(_delete));
    await tester.pumpAndSettle();
    expect(find.text('연결을 끊을까요?'), findsOneWidget);
    await tester.tap(find.text('연결 끊기').last);
    await tester.pump();
    await tester.pump();

    expect(find.text('연결을 끊었어요'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(settings.key, isNull);
    expect(find.text('연결하기'), findsOneWidget);
  });

  testWidgets('키를 저장하지 못하면 스낵바로 알린다', (tester) async {
    await pump(tester);
    settings.failWith = Exception('keystore');

    await connectThroughDialog(tester);

    expect(
      find.descendant(
        of: find.byType(SnackBar),
        matching: find.text('키를 저장하지 못했어요'),
      ),
      findsOneWidget,
    );
    expect(settings.key, isNull);
  });

  testWidgets('키를 지우지 못해도 스낵바로 알린다', (tester) async {
    settings.key = _savedKey;
    await pump(tester);
    settings.failWith = Exception('keystore');

    await tester.tap(find.byKey(_delete));
    await tester.pumpAndSettle();
    await tester.tap(find.text('연결 끊기').last);
    await tester.pump();
    await tester.pump();

    expect(find.text('연결을 끊지 못했어요'), findsOneWidget);
    expect(find.text('sk-ant-api03-xyz1••••'), findsOneWidget);
  });

  testWidgets('highlightConnection 이 true 면 열린 뒤 연결 행이 glow', (tester) async {
    await pump(tester, highlightConnection: true, settle: false);

    expect(await peakGlow(tester), greaterThan(0));
  });

  testWidgets('highlightConnection 기본은 glow 가 없다', (tester) async {
    await pump(tester, settle: false);

    expect(await peakGlow(tester), 0);
  });

  testWidgets('glow 는 연결 행 뒤에 깔리고 행이 불투명한 바탕을 칠하지 않는다', (tester) async {
    await pump(tester);

    final tile = tester.widget<ListTile>(
      find.descendant(of: find.byKey(_row), matching: find.byType(ListTile)),
    );
    expect(tile.tileColor, isNull);
    expect(
      ListTileTheme.of(tester.element(find.byKey(_row))).tileColor,
      isNull,
    );
    // RowHighlight 의 Stack 은 glow 를 먼저(아래), 행을 나중(위)에 그린다.
    final stack = tester.widget<Stack>(
      find.ancestor(of: find.byKey(_glow), matching: find.byType(Stack)).first,
    );
    expect(stack.children.first, isA<Positioned>());
  });

  testWidgets("읽는 중에는 연결 행이 제목만 보이고 누를 수 없다 — '연결하기'를 미리 보이지 않는다", (
    tester,
  ) async {
    getIt
      ..unregister<ChatSettings>()
      ..registerSingleton<ChatSettings>(_LoadingSettings());
    await pump(tester, settle: false);
    await tester.pump();

    final tile = tester.widget<ListTile>(
      find.descendant(of: find.byKey(_row), matching: find.byType(ListTile)),
    );
    expect(tile.onTap, isNull);
    expect(tile.subtitle, isNull);
    expect(tile.trailing, isNull);
    expect(find.text('AI 연결'), findsOneWidget);
    expect(find.text('연결하기'), findsNothing);
  });
  group('모델 행', () {
    String? subtitleOf(WidgetTester tester) {
      final tile = tester.widget<ListTile>(
        find.descendant(
          of: find.byKey(_model),
          matching: find.byType(ListTile),
        ),
      );
      return (tile.subtitle as Text?)?.data;
    }

    testWidgets('연결되면 모델 행에 지금 모델 이름', (tester) async {
      settings.key = _savedKey;
      await catalog.replace(ChatVendor.anthropic, [_sonnet], DateTime.now());
      await pump(tester);

      expect(find.byKey(_model), findsOneWidget);
      expect(
        find.descendant(of: find.byKey(_model), matching: find.text('모델')),
        findsOneWidget,
      );
      expect(subtitleOf(tester), 'Claude Sonnet 9.5');
      // 연결 행 바로 아래.
      expect(
        tester.getRect(find.byKey(_model)).top,
        tester.getRect(find.byKey(_row)).bottom,
      );
    });

    testWidgets("빠른 출력이면 '이름 · 빠르게'", (tester) async {
      settings
        ..key = _savedKey
        ..fastMode = true;
      await catalog.replace(ChatVendor.anthropic, [_sonnet], DateTime.now());
      await pump(tester);

      expect(subtitleOf(tester), 'Claude Sonnet 9.5 · 빠르게');
    });

    testWidgets("목록이 없으면 '목록을 받지 못했어요 · 다시 시도', 누르면 다시 받음", (tester) async {
      settings
        ..key = _savedKey
        ..status = ChatKeyStatus.unverified;
      verifier.stored = (
        ChatVendor.anthropic,
        const ModelListResult.unreachable(),
      );
      await pump(tester);

      expect(subtitleOf(tester), '목록을 받지 못했어요 · 다시 시도');
      final before = verifier.fetchStoredCalls;

      verifier.stored = (
        ChatVendor.anthropic,
        const ModelListResult.ok([_sonnet]),
      );
      await tester.tap(find.byKey(_model));
      await tester.pumpAndSettle();

      expect(verifier.fetchStoredCalls, before + 1);
      expect(subtitleOf(tester), 'Claude Sonnet 9.5');
    });

    testWidgets('미연결이면 모델 행 없음', (tester) async {
      await pump(tester);

      expect(find.byKey(_model), findsNothing);
    });

    testWidgets('모델 행 → 시트, 고르면 행이 바뀐다', (tester) async {
      settings.key = _savedKey;
      await catalog.replace(ChatVendor.anthropic, [
        _sonnet,
        _opus,
      ], DateTime.now());
      await pump(tester);

      await tester.tap(find.byKey(_model));
      await tester.pumpAndSettle();
      expect(find.text('모델 고르기'), findsOneWidget);

      await tester.tap(find.byKey(Key('model-row-${_opus.id}')));
      await tester.pumpAndSettle();

      expect(subtitleOf(tester), 'Claude Opus 9.9');
    });
  });

  group('벤더', () {
    const gptKey = 'sk-proj-abcdEFGH5678';

    testWidgets("미연결 [연결하기] → 벤더 시트 → GPT → 'GPT API 키 넣기'", (tester) async {
      await pump(tester);

      await tester.tap(find.byKey(_row));
      await tester.pumpAndSettle();
      expect(find.text('AI 고르기'), findsOneWidget);

      await tester.tap(find.byKey(const Key('vendor-row-openai')));
      await tester.pumpAndSettle();

      expect(find.text('GPT API 키 넣기'), findsOneWidget);
    });

    testWidgets("연결됨이면 '다른 AI 로 바꾸기' 행", (tester) async {
      settings.key = _savedKey;
      await pump(tester);

      expect(
        find.descendant(
          of: find.byKey(_switch),
          matching: find.text('다른 AI 로 바꾸기'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(_switch));
      await tester.pumpAndSettle();
      // 지금 벤더는 체크 · 누를 수 없다.
      expect(
        find.descendant(
          of: find.byKey(const Key('vendor-row-anthropic')),
          matching: find.byIcon(Icons.check),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      "바꾸면 'GPT 로 바꿨어요' 스낵바 · 연결 행 모노그램 G · 'GPT' · sk-proj-…•••• · glow",
      (tester) async {
        settings.key = _savedKey;
        await pump(tester);
        expect(glow(tester), 0);

        await tester.tap(find.byKey(_switch));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('vendor-row-openai')));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(const Key('chat-key-input')), gptKey);
        await tester.pump();
        await tester.tap(find.byKey(const Key('chat-key-save')));
        await tester.pumpAndSettle();
        expect(find.text('GPT 로 바꿀까요?'), findsOneWidget);
        await tester.tap(find.text('바꾸기'));
        await tester.pump();
        await tester.pump();

        expect(find.text('GPT 로 바꿨어요'), findsOneWidget);
        expect(
          tester.widget<SnackBar>(find.byType(SnackBar)).backgroundColor,
          theme(tester).colorScheme.primaryContainer,
        );
        expect(await peakGlow(tester), greaterThan(0));
        await tester.pumpAndSettle();
        expect(
          find.descendant(of: find.byKey(_row), matching: find.text('G')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: find.byKey(_row), matching: find.text('GPT')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(_row),
            matching: find.textContaining(RegExp(r'^sk-proj-.*••••$')),
          ),
          findsOneWidget,
        );
        expect(settings.vendor, ChatVendor.openai);
        expect(find.textContaining('연결한 AI(GPT)로 전송돼요'), findsOneWidget);
      },
    );
  });
}
