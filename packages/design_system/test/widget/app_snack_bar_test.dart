import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../theme/app_theme_contrast_test.dart' show contrast;

void main() {
  /// [show] 를 눌러 스낵바를 띄울 수 있는 앱을 그린다.
  Future<void> pumpApp(
    WidgetTester tester,
    void Function(BuildContext context) show, {
    ThemeData? theme,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? AppTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => show(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  SnackBar snackBar(WidgetTester tester) =>
      tester.widget<SnackBar>(find.byType(SnackBar));

  AppStatusColors statusColors(WidgetTester tester) =>
      AppStatusColors.of(tester.element(find.byType(SnackBar)));

  group('유형', () {
    const icons = {
      AppSnackBarType.info: Icons.info_outline,
      AppSnackBarType.success: Icons.check_circle_outline,
      AppSnackBarType.warning: Icons.warning_amber_rounded,
      AppSnackBarType.error: Icons.error_outline,
    };

    for (final type in AppSnackBarType.values) {
      testWidgets('$type — 고유 아이콘과 유형 색으로 그린다', (tester) async {
        await pumpApp(
          tester,
          (context) => AppSnackBar.show(context, message: '안내', type: type),
        );

        final colors = statusColors(tester).forStatus(type);
        expect(snackBar(tester).backgroundColor, colors.background);
        final icon = tester.widget<Icon>(
          find.descendant(
            of: find.byType(SnackBar),
            matching: find.byIcon(icons[type]!),
          ),
        );
        expect(icon.color, colors.foreground);
        final text = tester.widget<Text>(find.text('안내'));
        expect(text.style?.color, colors.foreground);
      });
    }

    testWidgets('유형을 안 주면 info 다(하위 호환)', (tester) async {
      await pumpApp(
        tester,
        (context) => AppSnackBar.show(context, message: '안내'),
      );

      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(
        snackBar(tester).backgroundColor,
        statusColors(tester).info.background,
      );
    });

    testWidgets('편의 메서드는 해당 유형으로 띄운다', (tester) async {
      final calls = <(AppSnackBarType, void Function(BuildContext))>[
        (AppSnackBarType.info, (c) => AppSnackBar.info(c, message: 'm')),
        (AppSnackBarType.success, (c) => AppSnackBar.success(c, message: 'm')),
        (AppSnackBarType.warning, (c) => AppSnackBar.warning(c, message: 'm')),
        (AppSnackBarType.error, (c) => AppSnackBar.error(c, message: 'm')),
      ];
      for (final (type, call) in calls) {
        await pumpApp(tester, call);
        expect(
          snackBar(tester).backgroundColor,
          statusColors(tester).forStatus(type).background,
          reason: '$type',
        );
      }
    });

    test('네 유형의 배경색은 테마마다 서로 다르다', () {
      for (final theme in [AppTheme.light(), AppTheme.dark()]) {
        final colors = theme.extension<AppStatusColors>()!;
        final backgrounds = AppSnackBarType.values
            .map((t) => colors.forStatus(t).background)
            .toSet();
        expect(backgrounds, hasLength(4));
      }
    });

    test('네 유형 모두 라이트 · 다크에서 글자 대비 AA(4.5:1)를 넘는다', () {
      for (final (name, theme) in [
        ('light', AppTheme.light()),
        ('dark', AppTheme.dark()),
        // walk 처럼 시드를 바꿔도 유지돼야 한다.
        ('walk light', AppTheme.light(seedColor: const Color(0xFF1D9E75))),
        ('walk dark', AppTheme.dark(seedColor: const Color(0xFF1D9E75))),
      ]) {
        final colors = theme.extension<AppStatusColors>()!;
        for (final type in AppSnackBarType.values) {
          final c = colors.forStatus(type);
          expect(
            contrast(c.foreground, c.background),
            greaterThan(4.5),
            reason: '$name $type',
          );
        }
      }
    });

    testWidgets('AppStatusColors 확장이 없는 테마에서도 색을 정한다', (tester) async {
      await pumpApp(
        tester,
        (context) => AppSnackBar.error(context, message: '안내'),
        theme: ThemeData(useMaterial3: true),
      );
      expect(snackBar(tester).backgroundColor, isNotNull);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });

  group('닫기', () {
    testWidgets('오른쪽 끝의 X 를 누르면 닫힌다', (tester) async {
      await pumpApp(
        tester,
        (context) => AppSnackBar.show(context, message: '안내'),
      );

      expect(snackBar(tester).showCloseIcon, isTrue);
      final close = find.byIcon(Icons.close);
      expect(close, findsOneWidget);
      expect(
        tester.getCenter(close).dx,
        greaterThan(tester.getCenter(find.text('안내')).dx),
      );

      await tester.tap(close);
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('X 아이콘은 유형 글자색을 따른다', (tester) async {
      await pumpApp(
        tester,
        (context) => AppSnackBar.success(context, message: '안내'),
      );
      expect(
        snackBar(tester).closeIconColor,
        statusColors(tester).success.foreground,
      );
    });

    testWidgets('좌우로 밀어서 닫는다', (tester) async {
      await pumpApp(
        tester,
        (context) => AppSnackBar.show(context, message: '안내'),
      );

      expect(snackBar(tester).dismissDirection, DismissDirection.horizontal);

      await tester.drag(find.text('안내'), const Offset(-600, 0));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('오른쪽으로 밀어도 닫힌다', (tester) async {
      await pumpApp(
        tester,
        (context) => AppSnackBar.show(context, message: '안내'),
      );

      await tester.drag(find.text('안내'), const Offset(600, 0));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('액션이 있어도 메시지 · 액션 · X 가 겹치지 않고 차례로 놓인다', (tester) async {
      var undone = false;
      await pumpApp(
        tester,
        (context) => AppSnackBar.success(
          context,
          message: '기록을 휴지통으로 옮겼어요',
          actionLabel: '되돌리기',
          onAction: () => undone = true,
        ),
      );

      final message = tester.getRect(find.text('기록을 휴지통으로 옮겼어요'));
      final action = tester.getRect(find.text('되돌리기'));
      final close = tester.getRect(find.byIcon(Icons.close));
      expect(message.right, lessThanOrEqualTo(action.left));
      expect(action.right, lessThanOrEqualTo(close.left));

      final actionWidget = tester.widget<SnackBarAction>(
        find.byType(SnackBarAction),
      );
      expect(actionWidget.textColor, statusColors(tester).success.foreground);

      await tester.tap(find.text('되돌리기'));
      await tester.pumpAndSettle();
      expect(undone, isTrue);
      expect(find.byType(SnackBar), findsNothing);
    });
  });
}
