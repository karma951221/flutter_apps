import 'package:daylog/design_system/widget/app_confirm_dialog.dart';
import 'package:l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// 다이얼로그를 띄운다. 돌려주는 리스트에 결과가 담기므로, 버튼을 누른 뒤
  /// `result.single` 로 확인한다 (닫히기 전에는 비어 있다).
  Future<List<bool>> pumpAndOpen(
    WidgetTester tester, {
    Locale locale = const Locale('ko'),
    String? cancelLabel,
    bool isDestructive = true,
  }) async {
    final result = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async => result.add(
                await AppConfirmDialog.show(
                  context,
                  title: '지울까요?',
                  content: '되돌릴 수 없습니다.',
                  confirmLabel: '삭제',
                  cancelLabel: cancelLabel,
                  isDestructive: isDestructive,
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return result;
  }

  TextButton buttonWithLabel(WidgetTester tester, String label) =>
      tester.widget<TextButton>(
        find.ancestor(of: find.text(label), matching: find.byType(TextButton)),
      );

  testWidgets('취소 라벨을 안 넘기면 현재 언어의 취소를 쓴다', (tester) async {
    await pumpAndOpen(tester);
    expect(find.text('취소'), findsOneWidget);
  });

  testWidgets('언어를 바꾸면 취소 라벨도 따라 바뀐다', (tester) async {
    // 예전에는 한국어가 위젯의 기본값으로 박혀 있어 en 화면에서도 '취소'가 남았다.
    await pumpAndOpen(tester, locale: const Locale('en'));
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('취소'), findsNothing);
  });

  testWidgets('취소 라벨을 넘기면 그것을 쓴다', (tester) async {
    await pumpAndOpen(tester, cancelLabel: '계속 쓰기');
    expect(find.text('계속 쓰기'), findsOneWidget);
    expect(find.text('취소'), findsNothing);
  });

  testWidgets('기본은 destructive — 확인 버튼이 error 색이다', (tester) async {
    await pumpAndOpen(tester);
    final scheme = Theme.of(tester.element(find.text('삭제'))).colorScheme;
    final color = buttonWithLabel(
      tester,
      '삭제',
    ).style?.foregroundColor?.resolve(<WidgetState>{});
    expect(color, scheme.error);
  });

  testWidgets('isDestructive:false 는 확인 버튼을 기본 색으로 둔다', (tester) async {
    await pumpAndOpen(tester, isDestructive: false);
    expect(buttonWithLabel(tester, '삭제').style?.foregroundColor, isNull);
  });

  testWidgets('확인을 누르면 true 를 돌려주고 닫힌다', (tester) async {
    final result = await pumpAndOpen(tester);
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();

    expect(result.single, isTrue);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('취소를 누르면 false 다', (tester) async {
    final result = await pumpAndOpen(tester);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    expect(result.single, isFalse);
  });

  testWidgets('바깥을 눌러 닫아도 false 다', (tester) async {
    final result = await pumpAndOpen(tester);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(result.single, isFalse);
  });
}
