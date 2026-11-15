import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/presentation/diary/widget/time_row.dart';

void main() {
  final now = DateTime(2026, 11, 15, 18);
  late List<DateTime> picked;

  setUp(() => picked = []);

  Future<void> pump(
    WidgetTester tester, {
    DateTime? photoTakenAt,
    DateTime? occurredAt,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: TimeRow(
          occurredAt: occurredAt ?? now,
          edited: false,
          isEditing: false,
          now: now,
          photoTakenAt: photoTakenAt,
          onPick: picked.add,
          onRevert: () {},
        ),
      ),
    ),
  );

  testWidgets('사진 촬영 시각이 3시간 넘게 다르면 "찍은 시각으로" 칩, 누르면 그 시각', (tester) async {
    final taken = DateTime(2026, 11, 14, 15, 20);
    await pump(tester, photoTakenAt: taken);

    await tester.tap(find.text('찍은 시각으로(어제 오후 3:20)'));
    await tester.pump();

    expect(picked, [taken]);
  });

  testWidgets('3시간 안이거나 촬영 시각이 없으면 칩이 없다', (tester) async {
    await pump(tester, photoTakenAt: DateTime(2026, 11, 15, 16));
    expect(find.textContaining('찍은 시각으로'), findsNothing);

    await pump(tester);
    expect(find.textContaining('찍은 시각으로'), findsNothing);
  });

  testWidgets('이미 그 시각이면 칩이 없다', (tester) async {
    final taken = DateTime(2026, 11, 14, 15, 20);
    await pump(tester, photoTakenAt: taken, occurredAt: taken);

    expect(find.textContaining('찍은 시각으로'), findsNothing);
  });
}
