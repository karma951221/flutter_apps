import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/presentation/settings/page/alarm_settings_page.dart';

import '../settings_harness.dart';

void main() {
  final h = SettingsHarness();

  setUpAll(SettingsHarness.registerFallbacks);
  setUp(h.setUp);
  tearDown(h.tearDown);

  testWidgets('열릴 때 권한 · 공휴일을 읽어 보인다', (tester) async {
    await h.pump(tester, const AlarmSettingsPage());

    verify(h.notification.check).called(1);
    expect(find.text('공휴일 미리 알림'), findsOneWidget);
    expect(find.text('내장 표 2026–2027'), findsOneWidget);
    expect(find.text('캘린더 허용 필요 ›'), findsOneWidget);
    expect(find.text('권한'), findsOneWidget);
    expect(find.text('허용됨'), findsNWidgets(2));
    expect(find.text('허용 필요 ›'), findsOneWidget);
  });

  testWidgets('공휴일 출처 행이 권한 머리보다 위', (tester) async {
    await h.pump(tester, const AlarmSettingsPage());

    double top(String text) => tester.getTopLeft(find.text(text)).dy;
    expect(top('공휴일 출처'), lessThan(top('권한')));
    expect(top('권한'), lessThan(top('알림')));
  });

  testWidgets('전체 화면 알림 행을 누르면 해당 설정을 연다', (tester) async {
    when(h.fullScreen.openSettings).thenAnswer((_) async {});
    await h.pump(tester, const AlarmSettingsPage());

    await tester.tap(find.text('전체 화면 알림'));
    verify(h.fullScreen.openSettings).called(1);
  });
}
