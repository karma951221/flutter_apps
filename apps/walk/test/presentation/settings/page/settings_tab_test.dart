import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/chat/chat_vendor.dart';
import 'package:walk/domain/location/entity/record_mode.dart';
import 'package:walk/domain/location/recorder/recorder_status.dart';
import 'package:walk/domain/profile/profile.dart';
import 'package:walk/domain/settings/entity/app_settings.dart';
import 'package:walk/presentation/diary/media_picker.dart';
import 'package:walk/presentation/lock/widget/lock_secret_input.dart';
import 'package:walk/presentation/profile/page/profile_page.dart';
import 'package:walk/presentation/settings/page/alarm_settings_page.dart';
import 'package:walk/presentation/settings/page/chat_settings_page.dart';
import 'package:walk/presentation/settings/page/map_settings_page.dart';
import 'package:walk/presentation/settings/page/settings_tab.dart';

import '../settings_harness.dart';

class _MockPicker extends Mock implements MediaPicker {}

void main() {
  final h = SettingsHarness();

  setUpAll(SettingsHarness.registerFallbacks);
  setUp(h.setUp);
  tearDown(h.tearDown);

  Future<void> pump(WidgetTester tester) =>
      h.pump(tester, const SettingsTab(active: true));

  double top(WidgetTester tester, Finder f) => tester.getTopLeft(f).dy;
  Finder row(String name) => find.byKey(Key('settings-$name'));

  testWidgets('제목 · 섹션 순서: 프로필 → 화면 → 잠금 → 데이터 → 연결 → 위치 → 기능별 → 앱 정보', (
    tester,
  ) async {
    await pump(tester);

    expect(find.widgetWithText(AppBar, '설정'), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsNothing);
    final order = [
      row('profile'),
      find.text('화면'),
      row('diary-lock'),
      row('open-backup'),
      row('open-chat'),
      row('open-map'),
      row('open-diary'),
      row('open-alarm'),
      row('open-walk'),
      row('licenses'),
    ];
    for (var i = 0; i < order.length - 1; i++) {
      expect(
        top(tester, order[i]),
        lessThan(top(tester, order[i + 1])),
        reason: '$i',
      );
    }
    expect(find.text('API 키 · 연결'), findsOneWidget);
    expect(find.text('앱 정보'), findsOneWidget);
  });

  testWidgets('프로필이 없으면 "프로필 만들기", 있으면 이름 · 소개', (tester) async {
    await pump(tester);
    expect(find.text('프로필 만들기'), findsOneWidget);

    h.profileRepo.profile = const Profile(name: '하늘', bio: '걷는 사람');
    h.profile.load();
    await tester.pumpAndSettle();
    expect(find.text('하늘'), findsOneWidget);
    expect(find.text('걷는 사람'), findsOneWidget);
  });

  testWidgets('프로필 행을 누르면 편집 화면', (tester) async {
    getIt.registerSingleton<MediaPicker>(_MockPicker());
    await pump(tester);
    await tester.tap(row('profile'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfilePage), findsOneWidget);
  });

  testWidgets('AI 연결 부제는 연결 상태', (tester) async {
    await pump(tester);
    expect(
      find.descendant(of: row('open-chat'), matching: find.text('연결 안 됨')),
      findsOneWidget,
    );

    h.chatSettings
      ..key = 'sk-ant-1234567890'
      ..vendor = ChatVendor.anthropic;
    await h.connections.load();
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: row('open-chat'), matching: find.text('Claude')),
      findsOneWidget,
    );
  });

  testWidgets('위치 기록 부제는 기록 상태(자세히 기록 포함)', (tester) async {
    await pump(tester);
    expect(
      find.descendant(of: row('open-map'), matching: find.text('꺼짐')),
      findsOneWidget,
    );

    when(h.locationRecorder.status).thenAnswer(
      (_) async =>
          const RecorderStatus.running(RecordMode.dense, stillDetection: true),
    );
    await h.mapRecord.load();
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: row('open-map'), matching: find.text('켜짐 · 자세히 기록')),
      findsOneWidget,
    );
  });

  testWidgets('테마를 고르면 저장한다', (tester) async {
    await pump(tester);

    await tester.tap(find.text('다크'));
    await tester.pumpAndSettle();

    expect(h.theme.state, AppThemeMode.dark);
    verify(
      () => h.settings.save(const AppSettings(themeMode: AppThemeMode.dark)),
    ).called(1);
  });

  testWidgets('알람 설정은 바로 열리고, 돌아오면 설정 탭', (tester) async {
    await pump(tester);

    await tester.tap(row('open-alarm'));
    await tester.pumpAndSettle();
    expect(find.byType(AlarmSettingsPage), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsTab), findsOneWidget);
  });

  testWidgets('잠겨 있으면 AI 연결 · 위치 기록은 잠금 화면을 거친다', (tester) async {
    await h.lockWithPin();
    await pump(tester);

    await tester.tap(row('open-chat'));
    await tester.pumpAndSettle();
    expect(find.byType(LockSecretInput), findsOneWidget);
    expect(find.byType(ChatSettingsPage), findsNothing);

    await h.diaryLock.submit('1234');
    await tester.pumpAndSettle();
    expect(find.byType(ChatSettingsPage), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(row('open-map'));
    await tester.pumpAndSettle();
    expect(find.byType(MapSettingsPage), findsOneWidget);
  });

  testWidgets('다시 보이면 잠금 · 연결 상태를 다시 읽는다', (tester) async {
    await pump(tester);
    h.chatSettings.key = 'sk-ant-1234567890';
    await h.pump(tester, const SettingsTab(active: false));
    await h.pump(tester, const SettingsTab(active: true));
    expect(
      find.descendant(of: row('open-chat'), matching: find.text('Claude')),
      findsOneWidget,
    );
  });

  testWidgets('오픈소스 라이선스', (tester) async {
    await pump(tester);
    await tester.ensureVisible(row('licenses'));
    await tester.tap(row('licenses'));
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
  });
}
