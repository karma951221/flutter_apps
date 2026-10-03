import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/domain/alarm/entity/alarm.dart';
import 'package:walk/presentation/alarm/widget/alarm_tile.dart';

Widget _app(Alarm alarm, {ValueChanged<bool>? onToggle, VoidCallback? onTap}) =>
    MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: AlarmTile(
          alarm: alarm,
          onTap: onTap ?? () {},
          onToggle: onToggle ?? (_) {},
        ),
      ),
    );

void main() {
  testWidgets('꺼진 알람의 시각 · 요일 글자는 onSurfaceVariant, 켜진 알람은 기본색', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const Alarm(
          id: 1,
          hour: 7,
          minute: 0,
          enabled: false,
          repeat: {Weekday.mon},
        ),
      ),
    );
    final scheme = Theme.of(tester.element(find.byType(AlarmTile))).colorScheme;
    expect(
      tester.widget<Text>(find.text('오전 7:00')).style?.color,
      scheme.onSurfaceVariant,
    );
    expect(
      tester.widget<Text>(find.text('월')).style?.color,
      scheme.onSurfaceVariant,
    );

    await tester.pumpWidget(
      _app(const Alarm(id: 1, hour: 7, minute: 0, repeat: {Weekday.mon})),
    );
    expect(tester.widget<Text>(find.text('오전 7:00')).style?.color, isNot(scheme.onSurfaceVariant));
    expect(tester.widget<Text>(find.text('월')).style?.color, isNull);
  });

  testWidgets('꺼져도 행 탭은 동작한다', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _app(
        const Alarm(id: 1, hour: 7, minute: 0, enabled: false),
        onTap: () => taps++,
      ),
    );
    await tester.tap(find.text('오전 7:00'));
    expect(taps, 1);
  });

  testWidgets('스위치를 누르면 햅틱 후 onToggle', (tester) async {
    final haptics = <String?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add(call.arguments as String?);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    bool? toggled;
    await tester.pumpWidget(
      _app(
        const Alarm(id: 1, hour: 7, minute: 0),
        onToggle: (v) => toggled = v,
      ),
    );

    await tester.tap(find.byType(Switch));

    expect(toggled, isFalse);
    expect(haptics, ['HapticFeedbackType.selectionClick']);
  });
}
