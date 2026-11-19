import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/transit/repository/station_search.dart';
import 'package:walk/domain/transit/repository/transit_key_store.dart';
import 'package:walk/domain/transit/transit_failure.dart';
import 'package:walk/domain/transit/usecase/verify_transit_key.dart';
import 'package:walk/presentation/settings/page/settings_tab.dart';
import 'package:walk/presentation/settings/page/transit_settings_page.dart';

import '../../../domain/transit/usecase/fakes.dart';
import '../settings_harness.dart';

void main() {
  // 원인 원문 — 실패 영역(transit-failure-cause) 안의 글자. 골라 복사할 수 있게 그린다.
  Finder cause(String text) => find.descendant(
    of: find.byKey(const Key('transit-failure-cause')),
    matching: find.text(text, findRichText: true),
  );

  final h = SettingsHarness();
  late FakeKeyStore store;
  late FakeStationSearch remote;

  setUpAll(SettingsHarness.registerFallbacks);
  setUp(() async {
    await h.setUp();
    store = FakeKeyStore();
    remote = FakeStationSearch();
    getIt
      ..registerSingleton<TransitKeyStore>(store)
      ..registerSingleton<StationSearch>(remote)
      ..registerSingleton<VerifyTransitKey>(VerifyTransitKey(remote, store));
  });
  tearDown(h.tearDown);

  Future<void> enterAndSave(WidgetTester tester, String key) async {
    await tester.enterText(find.byKey(const Key('transit-key-input')), key);
    await tester.pump();
    await tester.tap(find.byKey(const Key('transit-key-save')));
    await tester.pumpAndSettle();
  }

  testWidgets('saved key is masked', (tester) async {
    store
      ..key = 'abcd1234efgh5678'
      ..savedStatus = TransitKeyStatus.connected;
    await h.pump(tester, const TransitSettingsPage());

    expect(find.text('abcd••••'), findsOneWidget);
    expect(find.text('연결됨'), findsOneWidget);
    expect(find.textContaining('efgh'), findsNothing);
    expect(find.textContaining('com.karma.walk'), findsOneWidget);
  });

  testWidgets('save connects and shows a snackbar', (tester) async {
    await h.pump(tester, const TransitSettingsPage());

    await enterAndSave(tester, 'abcd1234efgh5678');

    expect(store.savedStatus, TransitKeyStatus.connected);
    expect(find.text('길찾기 키를 연결했어요'), findsOneWidget);
    expect(find.text('abcd••••'), findsOneWidget);
  });

  testWidgets('rejected shows summary, console hint and selectable cause', (
    tester,
  ) async {
    remote.error = const TransitFailure.keyRejected(
      'code 500 · [ApiKeyAuthFailed] ApiKey authentication failed.',
    );
    await h.pump(tester, const TransitSettingsPage());

    await enterAndSave(tester, 'abcd1234efgh5678');

    final area = find.byKey(const Key('transit-key-failure'));
    expect(area, findsOneWidget);
    expect(
      find.descendant(of: area, matching: find.text('ODsay 가 키를 받지 않았어요')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: area,
        matching: find.textContaining('ODsay 콘솔(lab.odsay.com)'),
      ),
      findsOneWidget,
    );
    expect(
      cause('code 500 · [ApiKeyAuthFailed] ApiKey authentication failed.'),
      findsOneWidget,
    );
    expect(store.saveCalls, 0);
  });

  testWidgets('quota failure shows its cause instead of a generic snackbar', (
    tester,
  ) async {
    remote.error = const TransitFailure.quotaExceeded(
      'code -1 · LimitExceeded',
    );
    await h.pump(tester, const TransitSettingsPage());

    await enterAndSave(tester, 'abcd1234efgh5678');

    expect(find.text('오늘 무료 한도를 다 썼어요'), findsOneWidget);
    expect(cause('code -1 · LimitExceeded'), findsOneWidget);
  });

  testWidgets('storage failure shows runtime type and message', (tester) async {
    store.saveError = StateError('keystore locked');
    await h.pump(tester, const TransitSettingsPage());

    await enterAndSave(tester, 'abcd1234efgh5678');

    expect(
      find.descendant(
        of: find.byKey(const Key('transit-key-failure')),
        matching: find.text('키를 저장하지 못했어요'),
      ),
      findsOneWidget,
    );
    expect(cause('StateError: Bad state: keystore locked'), findsOneWidget);
  });

  testWidgets('editing the input clears the failure area', (tester) async {
    remote.error = const TransitFailure.keyRejected('apiKey 인증 실패');
    await h.pump(tester, const TransitSettingsPage());
    await enterAndSave(tester, 'abcd1234efgh5678');
    expect(find.text('apiKey 인증 실패'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('transit-key-input')),
      'abcd1234efgh567',
    );
    await tester.pump();

    expect(find.text('apiKey 인증 실패'), findsNothing);
    expect(find.byKey(const Key('transit-key-failure')), findsNothing);
  });

  testWidgets('network asks then saves unverified', (tester) async {
    remote.error = const TransitFailure.network();
    await h.pump(tester, const TransitSettingsPage());

    await enterAndSave(tester, 'abcd1234efgh5678');
    expect(find.text('확인 못 했어요'), findsOneWidget);
    expect(store.saveCalls, 0);

    await tester.tap(find.text('그래도 저장'));
    await tester.pumpAndSettle();

    expect(store.savedStatus, TransitKeyStatus.unverified);
    expect(find.text('확인 전'), findsOneWidget);
  });

  testWidgets('non-key server error (code -8) asks with cause, not rejected', (
    tester,
  ) async {
    remote.error = const TransitFailure.server(
      'HTTP 200 · code -8 · stationClass의 형식이 잘못되었습니다.',
    );
    await h.pump(tester, const TransitSettingsPage());

    await enterAndSave(tester, 'abcd1234efgh5678');
    expect(find.text('확인 못 했어요'), findsOneWidget);
    expect(find.textContaining('code -8'), findsWidgets);
    expect(store.saveCalls, 0);

    await tester.tap(find.text('그래도 저장'));
    await tester.pumpAndSettle();

    expect(store.savedStatus, TransitKeyStatus.unverified);
  });

  testWidgets('network then cancel saves nothing and keeps the cause', (
    tester,
  ) async {
    remote.error = const TransitFailure.network(
      'SocketException: Failed host lookup',
    );
    await h.pump(tester, const TransitSettingsPage());

    await enterAndSave(tester, 'abcd1234efgh5678');
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.textContaining('SocketException: Failed host lookup'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    expect(store.saveCalls, 0);
    expect(find.text('ODsay 에 연결하지 못했어요'), findsOneWidget);
    expect(cause('SocketException: Failed host lookup'), findsOneWidget);
  });

  testWidgets('delete asks and clears', (tester) async {
    store
      ..key = 'abcd1234efgh5678'
      ..savedStatus = TransitKeyStatus.connected;
    await h.pump(tester, const TransitSettingsPage());

    await tester.tap(find.byKey(const Key('transit-key-delete')));
    await tester.pumpAndSettle();
    expect(store.key, isNotNull);

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('키 삭제'),
      ),
    );
    await tester.pumpAndSettle();

    expect(store.key, isNull);
    expect(find.text('abcd••••'), findsNothing);
    expect(find.byKey(const Key('transit-key-delete')), findsNothing);
  });

  testWidgets('설정 탭 › 연결에 길찾기 키 행이 있고 누르면 키 설정', (tester) async {
    await h.pump(tester, const SettingsTab(active: true));

    final row = find.byKey(const Key('settings-open-transit'));
    expect(row, findsOneWidget);
    await tester.ensureVisible(row);
    await tester.tap(row);
    await tester.pumpAndSettle();

    expect(find.byType(TransitSettingsPage), findsOneWidget);
  });
}
