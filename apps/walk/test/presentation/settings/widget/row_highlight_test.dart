import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/presentation/settings/widget/row_highlight.dart';

const _glow = Key('row-highlight-glow');
const _push = Key('push');

/// 바꿀 수 있는 재생 입력.
typedef _Config = ({bool play, int token});

void main() {
  late ValueNotifier<_Config> config;
  late int taps;

  setUp(() {
    config = ValueNotifier((play: true, token: 0));
    taps = 0;
  });
  tearDown(() => config.dispose());

  /// 버튼으로 [RowHighlight] 가 든 목록 화면을 push 한다. 전환은 끝내지 않는다.
  Future<void> pushPage(
    WidgetTester tester, {
    bool disableAnimations = false,
    String? announce,
    int rowsBefore = 3,
  }) async {
    Widget page(BuildContext _) => Scaffold(
      body: ListView(
        children: [
          for (var i = 0; i < rowsBefore; i++)
            AppListTile(key: Key('other-$i'), title: Text('다른 행 $i')),
          ValueListenableBuilder<_Config>(
            valueListenable: config,
            builder: (_, c, _) => RowHighlight(
              play: c.play,
              replayToken: c.token,
              announce: announce,
              child: AppListTile(title: const Text('키'), onTap: () => taps++),
            ),
          ),
          for (var i = rowsBefore; i < rowsBefore + 27; i++)
            AppListTile(key: Key('other-$i'), title: Text('다른 행 $i')),
        ],
      ),
    );
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  key: _push,
                  onPressed: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute<void>(builder: page)),
                  child: const Text('열기'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(_push));
    await tester.pump(Duration.zero);
  }

  double opacity(WidgetTester tester) => tester
      .widget<FadeTransition>(find.byKey(_glow, skipOffstage: false))
      .opacity
      .value;

  /// 행을 담은 라우트.
  ModalRoute<Object?> route(WidgetTester tester) => ModalRoute.of(
    tester.element(find.byType(RowHighlight, skipOffstage: false)),
  )!;

  /// push 전환이 끝나는 프레임까지 조금씩 흘린 뒤, 재생이 시작되는 다음 프레임 하나.
  Future<void> finishTransition(WidgetTester tester) async {
    final animation = route(tester).animation!;
    while (!animation.isCompleted) {
      await tester.pump(const Duration(milliseconds: 10));
    }
    await tester.pump();
  }

  Future<void> expectStaysOff(WidgetTester tester, Duration total) async {
    const step = Duration(milliseconds: 100);
    for (var t = Duration.zero; t < total; t += step) {
      await tester.pump(step);
      expect(opacity(tester), 0);
    }
  }

  testWidgets('play 가 true 면 push 전환이 끝난 뒤 재생한다', (tester) async {
    await pushPage(tester);
    expect(opacity(tester), 0);

    await tester.pump(route(tester).transitionDuration ~/ 3);
    expect(route(tester).animation!.isCompleted, isFalse);
    expect(opacity(tester), 0);

    await finishTransition(tester);
    await tester.pump(AppMotion.medium);
    expect(opacity(tester), greaterThan(0.95));
  });

  testWidgets('두 번 깜빡이고 1.8초 뒤 꺼진다', (tester) async {
    await pushPage(tester);
    await finishTransition(tester);

    expect(RowHighlight.cycle, const Duration(milliseconds: 900));
    await tester.pump(const Duration(milliseconds: 900));
    expect(opacity(tester), lessThan(0.05));
    await tester.pump(AppMotion.medium);
    expect(opacity(tester), greaterThan(0.95));
    await tester.pump(const Duration(milliseconds: 650));
    expect(opacity(tester), 0);
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('play 가 false 면 재생하지 않는다', (tester) async {
    config.value = (play: false, token: 0);
    await pushPage(tester);
    await finishTransition(tester);

    await expectStaysOff(tester, const Duration(seconds: 2));
  });

  testWidgets('play 가 false → true 로 바뀌면 한 번 재생한다', (tester) async {
    config.value = (play: false, token: 0);
    await pushPage(tester);
    await finishTransition(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(opacity(tester), 0);

    config.value = (play: true, token: 0);
    await tester.pump();
    await tester.pump();
    await tester.pump(AppMotion.medium);
    expect(opacity(tester), greaterThan(0.95));

    await tester.pump(RowHighlight.cycle * RowHighlight.repeats);
    expect(opacity(tester), 0);
    await expectStaysOff(tester, const Duration(seconds: 1));
  });

  testWidgets('재생 중 play 가 true → false 로 바뀌면 지금 값에서 꺼 내린다', (tester) async {
    await pushPage(tester);
    await finishTransition(tester);
    await tester.pump(AppMotion.medium);
    expect(opacity(tester), greaterThan(0.95));

    config.value = (play: false, token: 0);
    await tester.pump();
    // 곧바로 0 이 되지 않고 내려간다.
    await tester.pump(AppMotion.medium ~/ 2);
    final mid = opacity(tester);
    expect(mid, greaterThan(0));
    expect(mid, lessThan(0.95));
    await tester.pump(AppMotion.medium);
    expect(opacity(tester), 0);

    // 두 번째 깜빡임도 오지 않는다.
    await expectStaysOff(tester, RowHighlight.cycle * RowHighlight.repeats);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('재생 전에 play 가 false 로 바뀌면 재생하지 않는다', (tester) async {
    await pushPage(tester);
    // push 전환 중 — 재생은 아직 예약 상태.
    await tester.pump(route(tester).transitionDuration ~/ 3);
    config.value = (play: false, token: 0);
    await tester.pump();

    await finishTransition(tester);
    await expectStaysOff(tester, const Duration(seconds: 2));
  });

  testWidgets('replayToken 이 바뀌면 다시 재생한다', (tester) async {
    await pushPage(tester);
    await finishTransition(tester);
    await tester.pump(RowHighlight.cycle * RowHighlight.repeats);
    await tester.pump(const Duration(milliseconds: 100));
    expect(opacity(tester), 0);

    config.value = (play: true, token: 1);
    await tester.pump();
    await tester.pump();
    await tester.pump(AppMotion.medium);
    expect(opacity(tester), greaterThan(0.95));
  });

  testWidgets('애니메이션 줄이기면 그리지 않는다', (tester) async {
    await pushPage(tester, disableAnimations: true);
    for (var i = 0; i < 25; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(_glow), findsNothing);
    }
    expect(find.text('키'), findsOneWidget);
  });

  testWidgets('재생 중 행을 누르면 곧바로 꺼진다', (tester) async {
    await pushPage(tester);
    await finishTransition(tester);
    await tester.pump(AppMotion.medium);
    expect(opacity(tester), greaterThan(0.95));

    await tester.tap(find.text('키'));
    await tester.pump();
    await tester.pump(AppMotion.medium);
    expect(opacity(tester), 0);
    expect(taps, 1);

    await expectStaysOff(tester, const Duration(seconds: 2));
  });

  testWidgets('재생 중 스크롤하면 곧바로 꺼진다', (tester) async {
    await pushPage(tester);
    await finishTransition(tester);
    await tester.pump(AppMotion.medium);
    expect(opacity(tester), greaterThan(0.95));

    await tester.drag(find.byKey(const Key('other-5')), const Offset(0, -40));
    await tester.pump();
    await tester.pump(AppMotion.medium);
    expect(opacity(tester), 0);

    await expectStaysOff(tester, const Duration(seconds: 2));
  });

  // ListView 는 화면 가까이(cacheExtent) 행만 만든다. 행이 만들어져 있어야 짚을 수 있다.
  testWidgets('행이 화면 밖이면 먼저 보이게 스크롤한 뒤 재생한다', (tester) async {
    await pushPage(tester, rowsBefore: 11);
    expect(
      tester.getRect(find.text('키', skipOffstage: false)).top,
      greaterThan(600),
    );

    await finishTransition(tester);
    // 스크롤(medium)이 끝난 뒤에 켜진다 — 스크롤 동안은 꺼져 있다.
    var peak = 0.0;
    for (var t = 0; t < 600; t += 50) {
      await tester.pump(const Duration(milliseconds: 50));
      final o = opacity(tester);
      if (o > 0) {
        final rect = tester.getRect(find.text('키'));
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(rect.bottom, lessThanOrEqualTo(600));
      }
      if (o > peak) peak = o;
    }
    expect(peak, greaterThan(0.95));
  });

  testWidgets('애니메이션 줄이기여도 화면 밖 행은 보이게 스크롤한다', (tester) async {
    await pushPage(tester, rowsBefore: 11, disableAnimations: true);
    await tester.pumpAndSettle();

    final rect = tester.getRect(find.text('키'));
    expect(rect.bottom, lessThanOrEqualTo(600));
    expect(find.byKey(_glow, skipOffstage: false), findsNothing);
  });

  testWidgets('announce 가 있으면 재생 시작에 한 번 읽는다', (tester) async {
    await pushPage(tester, announce: '키');
    await finishTransition(tester);
    await tester.pumpAndSettle();

    final announcements = tester.takeAnnouncements();
    expect(announcements, hasLength(1));
    expect(announcements.single.message, '키');
  });

  testWidgets('announce 가 없으면 읽지 않는다', (tester) async {
    await pushPage(tester);
    await finishTransition(tester);
    await tester.pumpAndSettle();

    expect(tester.takeAnnouncements(), isEmpty);
  });
}
