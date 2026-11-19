import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/domain/chat/chat_vendor.dart';
import 'package:walk/presentation/chat/widget/chat_settings_sheet.dart';
import 'package:walk/presentation/chat/widget/model_chip.dart';

void main() {
  const sonnet = ModelChipData(
    vendor: ChatVendor.anthropic,
    label: 'Claude Sonnet 9.5',
  );

  Future<void> pump(
    WidgetTester tester, {
    ModelChipData model = sonnet,
    bool useRecords = true,
    bool enabled = true,
    VoidCallback? onPickModel,
    ValueChanged<bool>? onUseRecordsChanged,
    VoidCallback? onOpenSettings,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ChatSettingsSheet(
          model: model,
          useRecords: useRecords,
          enabled: enabled,
          onPickModel: onPickModel ?? () {},
          onUseRecordsChanged: onUseRecordsChanged ?? (_) {},
          onOpenSettings: onOpenSettings ?? () {},
        ),
      ),
    ),
  );

  testWidgets('제목 · 모델 행(벤더 아이콘 · 이름) · 내 기록 스위치 · 물어보기 설정 행', (tester) async {
    await pump(tester);

    expect(find.text('대화 설정'), findsOneWidget);
    expect(find.text('모델'), findsOneWidget);
    expect(find.text('Claude Sonnet 9.5'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
    expect(find.text('내 기록 참고'), findsOneWidget);
    expect(find.text('물어보기 설정'), findsOneWidget);
    expect(find.byKey(const Key('chat-settings-model-dot')), findsNothing);
    expect(find.byIcon(Icons.bolt), findsNothing);
  });

  testWidgets('행을 누르면 각 콜백', (tester) async {
    var picked = 0;
    var opened = 0;
    final changed = <bool>[];
    await pump(
      tester,
      onPickModel: () => picked++,
      onUseRecordsChanged: changed.add,
      onOpenSettings: () => opened++,
    );

    await tester.tap(find.byKey(const Key('chat-settings-model')));
    await tester.tap(find.byKey(const Key('chat-settings-use-records')));
    await tester.tap(find.byKey(const Key('chat-settings-open')));

    expect(picked, 1);
    expect(changed, [false]);
    expect(opened, 1);
  });

  testWidgets('꺼짐이면 설명이 바뀐다', (tester) async {
    await pump(tester, useRecords: false);

    expect(find.text('내 기록 없이 답해요'), findsOneWidget);
    expect(
      tester
          .widget<Switch>(find.byKey(const Key('chat-settings-use-records')))
          .value,
      isFalse,
    );
  });

  testWidgets('안 본 새 모델이면 모델 행에 점, 빠른 출력이면 번개', (tester) async {
    await pump(
      tester,
      model: const ModelChipData(
        vendor: ChatVendor.openai,
        label: 'GPT 9',
        hasNewer: true,
        fastMode: true,
      ),
    );

    expect(find.byKey(const Key('chat-settings-model-dot')), findsOneWidget);
    expect(find.byIcon(Icons.bolt), findsOneWidget);
  });

  testWidgets('enabled 가 false 면 모델 · 스위치가 꺼지고 설정 행은 켜져 있다', (tester) async {
    var picked = 0;
    final changed = <bool>[];
    var opened = 0;
    await pump(
      tester,
      enabled: false,
      onPickModel: () => picked++,
      onUseRecordsChanged: changed.add,
      onOpenSettings: () => opened++,
    );

    await tester.tap(find.byKey(const Key('chat-settings-model')));
    await tester.tap(find.byKey(const Key('chat-settings-use-records')));
    await tester.tap(find.byKey(const Key('chat-settings-open')));

    expect(picked, 0);
    expect(changed, isEmpty);
    expect(opened, 1);
  });
}
