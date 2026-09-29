import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/core/alarm_ring_listener.dart';

void main() {
  late StreamController<Set<int>> ringing;
  late GlobalKey<NavigatorState> key;
  late AlarmRingListener listener;

  setUp(() {
    ringing = StreamController<Set<int>>();
    key = GlobalKey<NavigatorState>();
    listener = AlarmRingListener(
      navigatorKey: key,
      ringing: ringing.stream,
      routeFor: (id) => MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('ring $id'),
          ),
        ),
      ),
    )..start();
  });
  tearDown(() async {
    await listener.dispose();
    await ringing.close();
  });

  Future<void> pumpApp(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(navigatorKey: key, home: const Text('home')),
  );

  testWidgets('울리기 시작하면 한 번만 띄우고, 밖에서 끄면 걷는다', (tester) async {
    await pumpApp(tester);

    ringing.add({312});
    await tester.pumpAndSettle();
    expect(find.text('ring 312'), findsOneWidget);

    ringing.add({312});
    await tester.pumpAndSettle();
    expect(find.text('ring 312'), findsOneWidget);

    ringing.add({});
    await tester.pumpAndSettle();
    expect(find.text('ring 312'), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('화면에서 먼저 닫으면 끝났다는 값이 와도 더 닫지 않는다', (tester) async {
    await pumpApp(tester);
    ringing.add({312});
    await tester.pumpAndSettle();

    await tester.tap(find.text('ring 312'));
    await tester.pumpAndSettle();
    ringing.add({});
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('같은 회차가 다시 울리면(스누즈 뒤) 다시 띄운다', (tester) async {
    await pumpApp(tester);
    ringing
      ..add({312})
      ..add({});
    await tester.pumpAndSettle();
    ringing.add({312});
    await tester.pumpAndSettle();

    expect(find.text('ring 312'), findsOneWidget);
  });

  testWidgets('가려진 울림 화면이 끝나면 그것만 걷는다', (tester) async {
    await pumpApp(tester);
    ringing.add({100});
    await tester.pumpAndSettle();
    ringing.add({100, 200});
    await tester.pumpAndSettle();

    ringing.add({200});
    await tester.pumpAndSettle();
    expect(find.text('ring 200').hitTestable(), findsOneWidget);

    // 100 이 남아 있었다면 200 을 닫은 뒤 드러난다.
    ringing.add({});
    await tester.pumpAndSettle();
    expect(find.text('home').hitTestable(), findsOneWidget);
    expect(find.textContaining('ring').hitTestable(), findsNothing);
  });

  testWidgets('내비게이터가 생기기 전 값은 첫 프레임 뒤에 반영한다', (tester) async {
    ringing.add({7});
    await tester.pump();
    await pumpApp(tester);
    await tester.pumpAndSettle();

    expect(find.text('ring 7'), findsOneWidget);
  });

  testWidgets('첫 프레임 전에 울림이 시작됐다 끝났으면 화면을 띄우지 않는다', (tester) async {
    ringing
      ..add({7})
      ..add({});
    await tester.pump();
    await pumpApp(tester);
    await tester.pumpAndSettle();

    expect(find.text('ring 7'), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('start 를 두 번 해도 한 번만 구독한다', (tester) async {
    await pumpApp(tester);

    // 단일 구독 스트림이라 두 번 구독하면 StateError 가 난다.
    listener.start();
    ringing.add({312});
    await tester.pumpAndSettle();

    expect(find.text('ring 312'), findsOneWidget);
  });

  testWidgets('dispose 뒤에는 새 울림에 반응하지 않는다', (tester) async {
    await pumpApp(tester);
    unawaited(listener.dispose());
    await tester.pump();

    ringing.add({312});
    await tester.pumpAndSettle();

    expect(find.text('ring 312'), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });
}
