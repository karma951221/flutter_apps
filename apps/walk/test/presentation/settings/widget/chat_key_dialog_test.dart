import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/domain/chat/chat_connection.dart';
import 'package:walk/domain/chat/chat_model.dart';
import 'package:walk/domain/chat/chat_vendor.dart';
import 'package:walk/domain/chat/usecase/chat_model_choice.dart';
import 'package:walk/presentation/settings/cubit/chat_settings_cubit.dart';
import 'package:walk/presentation/settings/widget/chat_key_dialog.dart';

import '../../../support/fake_chat_key_verifier.dart';
import '../../../support/fake_chat_model_catalog.dart';
import '../../../support/fake_chat_settings.dart';

const _input = Key('chat-key-input');
const _save = Key('chat-key-save');
const _visibility = Key('chat-key-visibility');
const _goodKey = 'sk-ant-api03-abcd5678';

/// 연결(쓰기)이 [gate] 가 끝날 때까지 기다리는 설정 — 쓰는 동안의 화면 확인용.
class _SlowWriteSettings extends FakeChatSettings {
  final gate = Completer<void>();

  @override
  Future<void> connect(
    ChatVendor vendor,
    String key,
    ChatKeyStatus status,
  ) async {
    await gate.future;
    return super.connect(vendor, key, status);
  }
}

void main() {
  late FakeChatSettings settings;
  late FakeChatKeyVerifier verifier;
  late ChatSettingsCubit cubit;

  /// 대화상자가 닫히며 돌려준 값. 아직 안 닫혔으면 [open] 그대로.
  late Object? result;
  const open = #open;

  setUp(() async {
    settings = FakeChatSettings();
    verifier = FakeChatKeyVerifier();
    cubit = ChatSettingsCubit(
      settings,
      verifier,
      ChatModelChoice(
        settings,
        FakeChatModelCatalog(),
        verifier,
        const Clock(),
      ),
    );
    await cubit.load();
    result = open;
  });
  tearDown(() => cubit.close());

  Future<void> show(
    WidgetTester tester, {
    ChatVendor vendor = ChatVendor.anthropic,
    ChatVendor? switchingFrom,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider.value(
          value: cubit,
          child: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await ChatKeyDialog.show(
                    context,
                    vendor: vendor,
                    switchingFrom: switchingFrom,
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  TextField field(WidgetTester tester) =>
      tester.widget<TextField>(find.byKey(_input));

  bool saveEnabled(WidgetTester tester) =>
      tester
          .widget<FilledButton>(
            find.descendant(
              of: find.byKey(_save),
              matching: find.byType(FilledButton),
            ),
          )
          .onPressed !=
      null;

  Future<void> enterAndSave(WidgetTester tester, String text) async {
    await tester.enterText(find.byKey(_input), text);
    await tester.pump();
    await tester.tap(find.byKey(_save));
    await tester.pumpAndSettle();
  }

  testWidgets('열 때 입력칸이 비어 있고 가려져 있다', (tester) async {
    settings.key = 'sk-ant-api03-old00000';
    await show(tester);

    expect(find.text('Claude API 키 넣기'), findsOneWidget);
    expect(field(tester).controller!.text, isEmpty);
    expect(field(tester).obscureText, isTrue);
    expect(field(tester).autocorrect, isFalse);
    expect(field(tester).enableSuggestions, isFalse);
    expect(field(tester).decoration?.hintText, 'sk-ant-…');
  });

  testWidgets('보기 버튼을 누르면 보이고 다시 누르면 가린다', (tester) async {
    await show(tester);

    expect(find.byTooltip('키 보기'), findsOneWidget);
    await tester.tap(find.byKey(_visibility));
    await tester.pump();
    expect(field(tester).obscureText, isFalse);
    expect(find.byTooltip('키 숨기기'), findsOneWidget);

    await tester.tap(find.byKey(_visibility));
    await tester.pump();
    expect(field(tester).obscureText, isTrue);
  });

  testWidgets('비었으면 저장이 꺼져 있다', (tester) async {
    await show(tester);
    expect(saveEnabled(tester), isFalse);

    await tester.enterText(find.byKey(_input), '   ');
    await tester.pump();
    expect(saveEnabled(tester), isFalse);
    expect(field(tester).decoration?.errorText, isNull);
  });

  testWidgets("sk-proj- 키면 'GPT 키 같아요'와 저장 꺼짐", (tester) async {
    await show(tester);
    await tester.enterText(find.byKey(_input), 'sk-proj-abcd1234');
    await tester.pump();

    expect(find.text('GPT 키 같아요'), findsOneWidget);
    expect(saveEnabled(tester), isFalse);
  });

  testWidgets("접두사가 다르면 'Claude 키는 sk-ant- 로 시작해요'", (tester) async {
    await show(tester);
    await tester.enterText(find.byKey(_input), 'abcdefgh1234');
    await tester.pump();

    expect(find.text('Claude 키는 sk-ant- 로 시작해요'), findsOneWidget);
    expect(saveEnabled(tester), isFalse);

    await tester.enterText(find.byKey(_input), '  $_goodKey ');
    await tester.pump();
    expect(find.text('Claude 키는 sk-ant- 로 시작해요'), findsNothing);
    expect(saveEnabled(tester), isTrue);
  });

  testWidgets('저장을 누르면 확인하는 동안 로딩이고 입력칸 · 취소가 꺼진다', (tester) async {
    final pending = verifier.pending = Completer<ModelListResult>();
    await show(tester);
    await tester.enterText(find.byKey(_input), _goodKey);
    await tester.pump();
    await tester.tap(find.byKey(_save));
    await tester.pump();

    expect(
      find.descendant(
        of: find.byKey(_save),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    expect(field(tester).enabled, isFalse);
    final cancel = tester.widget<TextButton>(
      find.ancestor(of: find.text('취소'), matching: find.byType(TextButton)),
    );
    expect(cancel.onPressed, isNull);
    expect(
      tester.widget<PopScope<Object?>>(find.byType(PopScope<Object?>)).canPop,
      isFalse,
    );

    pending.complete(const ModelListResult.invalidKey());
    await tester.pumpAndSettle();
    expect(field(tester).enabled, isNot(false));
  });

  testWidgets("잘못된 키면 닫히지 않고 '이 키로는 연결되지 않아요', 입력값이 남고 저장소에 쓰지 않는다", (
    tester,
  ) async {
    verifier.result = const ModelListResult.invalidKey();
    await show(tester);
    await enterAndSave(tester, _goodKey);

    expect(find.byType(ChatKeyDialog), findsOneWidget);
    expect(find.text('이 키로는 연결되지 않아요'), findsOneWidget);
    expect(field(tester).controller!.text, _goodKey);
    expect(settings.key, isNull);
    expect(result, open);

    // 글을 고치면 오류 문구를 지운다.
    await tester.enterText(find.byKey(_input), '${_goodKey}9');
    await tester.pump();
    expect(find.text('이 키로는 연결되지 않아요'), findsNothing);
  });

  testWidgets('정상 키면 요금 경고가 뜨고 [확인]이면 저장 후 connected 로 닫힌다', (tester) async {
    await show(tester);
    await enterAndSave(tester, _goodKey);

    expect(find.text('Claude 키를 등록할까요?'), findsOneWidget);
    expect(find.textContaining('Anthropic 에 요금이 청구될 수 있어요'), findsOneWidget);
    expect(settings.key, isNull);

    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(find.byType(ChatKeyDialog), findsNothing);
    expect(result, ChatKeyDialogResult.connected);
    expect(settings.key, _goodKey);
    expect(settings.status, ChatKeyStatus.valid);
  });

  testWidgets('확인 못 함이어도 요금 경고가 뜨고 [확인]이면 unverified 로 저장, savedUnverified', (
    tester,
  ) async {
    verifier.result = const ModelListResult.unreachable();
    await show(tester);
    await enterAndSave(tester, _goodKey);

    expect(find.text('Claude 키를 등록할까요?'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(result, ChatKeyDialogResult.savedUnverified);
    expect(settings.key, _goodKey);
    expect(settings.status, ChatKeyStatus.unverified);
  });

  testWidgets('요금 경고 [취소]면 저장하지 않고 입력 대화상자로 돌아온다(입력값 유지)', (tester) async {
    await show(tester);
    await enterAndSave(tester, _goodKey);

    await tester.tap(find.text('취소').last);
    await tester.pumpAndSettle();

    expect(find.text('Claude 키를 등록할까요?'), findsNothing);
    expect(find.byType(ChatKeyDialog), findsOneWidget);
    expect(field(tester).controller!.text, _goodKey);
    expect(field(tester).enabled, isNot(false));
    expect(settings.key, isNull);
    expect(result, open);
  });

  testWidgets("쓰기가 실패하면 닫지 않고 스낵바와 입력칸 오류 '키를 저장하지 못했어요'", (tester) async {
    await show(tester);
    await enterAndSave(tester, _goodKey);
    settings.failWith = Exception('keystore');

    await tester.tap(find.text('확인'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(ChatKeyDialog), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SnackBar),
        matching: find.text('키를 저장하지 못했어요'),
      ),
      findsOneWidget,
    );
    expect(field(tester).decoration?.errorText, '키를 저장하지 못했어요');
    expect(field(tester).controller!.text, _goodKey);
    expect(field(tester).enabled, isNot(false));
    expect(result, open);

    await tester.enterText(find.byKey(_input), '${_goodKey}9');
    await tester.pump();
    expect(field(tester).decoration?.errorText, isNull);
  });

  testWidgets('쓰는 동안에도 저장 · 취소 · 입력칸 · 뒤로가 꺼진다', (tester) async {
    final slow = _SlowWriteSettings();
    await cubit.close();
    cubit = ChatSettingsCubit(
      slow,
      verifier,
      ChatModelChoice(slow, FakeChatModelCatalog(), verifier, const Clock()),
    );
    await cubit.load();
    await show(tester);
    await enterAndSave(tester, _goodKey);

    await tester.tap(find.text('확인'));
    // 요금 경고가 다 닫힐 때까지(쓰기는 gate 에 걸려 있다).
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(
      find.descendant(
        of: find.byKey(_save),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    expect(field(tester).enabled, isFalse);
    expect(
      tester
          .widget<TextButton>(
            find.ancestor(
              of: find.text('취소'),
              matching: find.byType(TextButton),
            ),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester.widget<PopScope<Object?>>(find.byType(PopScope<Object?>)).canPop,
      isFalse,
    );

    slow.gate.complete();
    await tester.pumpAndSettle();
    expect(result, ChatKeyDialogResult.connected);
    expect(slow.key, _goodKey);
  });

  testWidgets('저장을 두 번 눌러도 확인은 한 번만 한다', (tester) async {
    final pending = verifier.pending = Completer<ModelListResult>();
    await show(tester);
    await tester.enterText(find.byKey(_input), _goodKey);
    await tester.pump();

    await tester.tap(find.byKey(_save));
    await tester.tap(find.byKey(_save), warnIfMissed: false);
    await tester.pump();
    await tester.tap(find.byKey(_save), warnIfMissed: false);
    await tester.pump();

    expect(verifier.calls, hasLength(1));
    pending.complete(const ModelListResult.invalidKey());
    await tester.pumpAndSettle();
  });

  for (final typing in [
    's',
    'sk-',
    'sk-ant',
    'sk-ant-',
    'sk-ant-api',
    'sk-ant-api03',
  ]) {
    testWidgets("'$typing' 처럼 Claude 키를 치는 중이면 안내가 없고 저장은 꺼져 있다", (
      tester,
    ) async {
      await show(tester);
      await tester.enterText(find.byKey(_input), typing);
      await tester.pump();

      expect(field(tester).decoration?.errorText, isNull);
      expect(saveEnabled(tester), isFalse);
    });
  }

  testWidgets("sk-ant- 관리 키면 'API 키가 아니에요' 안내와 저장 꺼짐", (tester) async {
    await show(tester);
    await tester.enterText(find.byKey(_input), 'sk-ant-admin01-x');
    await tester.pump();

    expect(
      field(tester).decoration?.errorText,
      'API 키가 아니에요. Console 의 API Keys 에서 만든 키를 넣어 주세요',
    );
    expect(saveEnabled(tester), isFalse);
  });

  testWidgets("옛 형식 sk- 키도 'GPT 키 같아요'", (tester) async {
    await show(tester);
    await tester.enterText(find.byKey(_input), 'sk-abc123def456');
    await tester.pump();

    expect(field(tester).decoration?.errorText, 'GPT 키 같아요');
    expect(saveEnabled(tester), isFalse);
  });

  testWidgets('취소하면 null 로 닫힌다', (tester) async {
    await show(tester);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    expect(find.byType(ChatKeyDialog), findsNothing);
    expect(result, isNull);
    expect(verifier.calls, isEmpty);
  });

  group('벤더 바꾸기', () {
    const gptKey = 'sk-proj-abcd5678';

    setUp(() => settings.key = _goodKey);

    testWidgets(
      "switchingFrom 이 있으면 요금 경고 대신 '{GPT} 로 바꿀까요?' 한 창, 본문에 OpenAI · Claude · '이어져요'",
      (tester) async {
        await show(
          tester,
          vendor: ChatVendor.openai,
          switchingFrom: ChatVendor.anthropic,
        );
        await enterAndSave(tester, gptKey);

        expect(find.text('GPT 로 바꿀까요?'), findsOneWidget);
        expect(find.text('GPT 키를 등록할까요?'), findsNothing);
        expect(find.textContaining('OpenAI 에 요금이'), findsOneWidget);
        expect(find.textContaining('지금 연결된 Claude 키는'), findsOneWidget);
        expect(find.textContaining('GPT 로 이어져요'), findsOneWidget);
        expect(verifier.calls.single, (ChatVendor.openai, gptKey));
      },
    );

    testWidgets('[취소]면 아무것도 바뀌지 않고 입력 대화상자로', (tester) async {
      await show(
        tester,
        vendor: ChatVendor.openai,
        switchingFrom: ChatVendor.anthropic,
      );
      await enterAndSave(tester, gptKey);

      await tester.tap(find.text('취소').last);
      await tester.pumpAndSettle();

      expect(find.text('GPT 로 바꿀까요?'), findsNothing);
      expect(find.byType(ChatKeyDialog), findsOneWidget);
      expect(field(tester).controller!.text, gptKey);
      expect(settings.key, _goodKey);
      expect(settings.vendor, ChatVendor.anthropic);
      expect(result, open);
    });

    testWidgets('[바꾸기]면 switched 로 닫힌다', (tester) async {
      await show(
        tester,
        vendor: ChatVendor.openai,
        switchingFrom: ChatVendor.anthropic,
      );
      await enterAndSave(tester, gptKey);

      await tester.tap(find.text('바꾸기'));
      await tester.pumpAndSettle();

      expect(find.byType(ChatKeyDialog), findsNothing);
      expect(result, ChatKeyDialogResult.switched);
      expect(settings.vendor, ChatVendor.openai);
      expect(settings.key, gptKey);
      expect(settings.status, ChatKeyStatus.valid);
    });

    testWidgets('확인 못 함으로 바꾸면 switchedUnverified', (tester) async {
      verifier.result = const ModelListResult.unreachable();
      await show(
        tester,
        vendor: ChatVendor.openai,
        switchingFrom: ChatVendor.anthropic,
      );
      await enterAndSave(tester, gptKey);

      await tester.tap(find.text('바꾸기'));
      await tester.pumpAndSettle();

      expect(result, ChatKeyDialogResult.switchedUnverified);
      expect(settings.vendor, ChatVendor.openai);
      expect(settings.status, ChatKeyStatus.unverified);
    });
  });

  testWidgets("GPT 키 대화상자는 sk- 힌트, sk-ant- 키면 'Claude 키 같아요'", (tester) async {
    await show(tester, vendor: ChatVendor.openai);

    expect(find.text('GPT API 키 넣기'), findsOneWidget);
    expect(field(tester).decoration?.hintText, 'sk-…');

    await tester.enterText(find.byKey(_input), _goodKey);
    await tester.pump();

    expect(field(tester).decoration?.errorText, 'Claude 키 같아요');
    expect(saveEnabled(tester), isFalse);
  });
}
