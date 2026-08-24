import 'package:daylog/design_system/theme/app_theme.dart';
import 'package:daylog/design_system/widget/app_list_tile.dart';
import 'package:daylog/features/settings/presentation/page/account_settings_page.dart';
import 'package:daylog/features/settings/presentation/page/change_password_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const AccountSettingsPage()),
    );
    await tester.pump();
  }

  testWidgets('계정 설정은 비밀번호 변경과 회원 탈퇴 두 항목을 보여준다', (tester) async {
    await pumpPage(tester);

    expect(find.text('계정 설정'), findsOneWidget);
    expect(find.byType(AppListTile), findsNWidgets(2));
    expect(find.text('비밀번호 변경'), findsOneWidget);
    expect(find.text('회원 탈퇴'), findsOneWidget);
  });

  testWidgets('회원 탈퇴는 준비 중 안내만 띄우고 아무것도 지우지 않는다', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('회원 탈퇴'));
    await tester.pumpAndSettle();

    expect(find.text('준비 중입니다'), findsOneWidget);
    // 안내를 닫아도 화면은 그대로다. 탈퇴로 이어지는 경로가 없다.
    await tester.tap(find.widgetWithText(TextButton, '확인'));
    await tester.pumpAndSettle();

    expect(find.text('준비 중입니다'), findsNothing);
    expect(find.byType(AccountSettingsPage), findsOneWidget);
    expect(find.byType(ChangePasswordPage), findsNothing);
  });
}
