import 'package:core/core.dart';
import 'package:daylog/design_system/theme/app_theme.dart';
import 'package:daylog/features/post/domain/entity/post.dart';
import 'package:daylog/features/post/domain/entity/post_draft.dart';
import 'package:daylog/features/post/domain/entity/post_update.dart';
import 'package:daylog/features/post/domain/post_policy.dart';
import 'package:daylog/features/post/domain/usecase/post_use_case.dart';
import 'package:daylog/features/post/presentation/cubit/post_cubit.dart';
import 'package:daylog/features/post/presentation/page/post_editor_page.dart';
import 'package:daylog/features/trade/domain/entity/trade_result_summary.dart';
import 'package:daylog/features/trade/presentation/widget/trade_result_card.dart';
import 'package:l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockPostUseCase extends Mock implements PostUseCase {}

TradeResultSummary _summary() => TradeResultSummary(
  sessionId: 'session-1',
  symbol: 'BTCUSDT',
  startDay: DateTime.utc(2021, 11),
  endDay: DateTime.utc(2022, 1, 29),
  returnPct: 12.34,
  buyHoldReturnPct: 3,
  maxDrawdownPct: 8,
  tradeCount: 4,
);

Post _post(String content) => Post(
  id: 'post-1',
  authorId: 'me',
  content: content,
  createdAt: DateTime.utc(2026, 8, 24, 9),
  updatedAt: DateTime.utc(2026, 8, 24, 9),
);

void main() {
  late _MockPostUseCase useCase;

  setUpAll(() {
    registerFallbackValue(const PostDraft(content: '_'));
    registerFallbackValue(const PostUpdate(content: '_'));
  });

  setUp(() => useCase = _MockPostUseCase());

  /// 편집 화면은 go_router 의 `pop(결과)` 로 목록에 게시물을 돌려준다.
  /// 그래서 테스트도 라우터 위에서 띄우고, 돌아갈 화면을 하나 둔다.
  Future<void> pumpEditor(
    WidgetTester tester, {
    Post? post,
    TradeResultSummary? tradeResult,
  }) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Center(child: Text('목록'))),
          routes: [
            GoRoute(
              path: 'editor',
              builder: (_, _) => BlocProvider(
                create: (_) => PostCubit(useCase),
                child: PostEditorPage(post: post, tradeResult: tradeResult),
              ),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light(),
        // ko 가 ARB template 언어라 원문이 곧 기대값이다 (계획서).
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    router.push('/editor');
    await tester.pumpAndSettle();
  }

  testWidgets('작성과 수정은 제목과 버튼 라벨로 구분된다', (tester) async {
    await pumpEditor(tester);
    expect(find.text('새 게시물'), findsOneWidget);
    expect(find.text('올리기'), findsOneWidget);

    await pumpEditor(tester, post: _post('예전 기록'));
    expect(find.text('게시물 수정'), findsOneWidget);
    expect(find.text('저장'), findsOneWidget);
  });

  testWidgets('글자 수는 상한에 가까워지기 전에는 보이지 않는다', (tester) async {
    await pumpEditor(tester);

    await tester.enterText(find.byType(TextFormField), '오늘의 기록');
    await tester.pump();

    expect(
      find.textContaining('/ ${PostPolicy.maxContentLength}'),
      findsNothing,
    );
  });

  testWidgets('남은 글자가 50자 이하가 되면 정책 상수를 기준으로 센다', (tester) async {
    await pumpEditor(tester);

    final nearLimit = 'ㄱ' * (PostPolicy.maxContentLength - 50);
    await tester.enterText(find.byType(TextFormField), nearLimit);
    await tester.pump();

    expect(
      find.text('${nearLimit.length} / ${PostPolicy.maxContentLength}'),
      findsOneWidget,
    );
  });

  testWidgets('수정 화면은 사진 첨부를 보여주지 않는다', (tester) async {
    // 수정은 본문만 바꾼다. 첨부 버튼을 그리면 저장되지 않을 동작을 권하는 셈이다.
    await pumpEditor(tester, post: _post('예전 기록'));

    expect(find.byKey(const Key('postEditor.addImages')), findsNothing);
  });

  testWidgets('사진 추가 버튼은 최대 장수를 라벨에 적는다', (tester) async {
    await pumpEditor(tester);

    expect(find.text('사진 추가 (0/${PostPolicy.maxImageCount})'), findsOneWidget);
  });

  testWidgets('빈 본문은 저장을 시도하지 않는다', (tester) async {
    await pumpEditor(tester);

    await tester.tap(find.text('올리기'));
    await tester.pump();

    expect(find.text('게시물 내용을 입력하세요.'), findsOneWidget);
    verifyNever(() => useCase.createPost(any()));
  });

  testWidgets('쓰던 내용을 두고 나가려 하면 한 번 묻는다', (tester) async {
    await pumpEditor(tester);
    await tester.enterText(find.byType(TextFormField), '쓰던 내용');
    await tester.pump();

    // 시스템 뒤로 가기와 같은 경로다.
    final route = ModalRoute.of(tester.element(find.byType(PostEditorPage)))!;
    route.navigator!.maybePop();
    await tester.pumpAndSettle();

    expect(find.text('작성 중인 내용을 버릴까요?'), findsOneWidget);
  });

  testWidgets('아무것도 쓰지 않았으면 묻지 않고 나간다', (tester) async {
    await pumpEditor(tester);

    final route = ModalRoute.of(tester.element(find.byType(PostEditorPage)))!;
    route.navigator!.maybePop();
    await tester.pumpAndSettle();

    expect(find.text('작성 중인 내용을 버릴까요?'), findsNothing);
  });

  testWidgets('저장에 성공하면 결과 게시물을 들고 돌아간다', (tester) async {
    when(
      () => useCase.createPost(any()),
    ).thenAnswer((_) async => Ok(_post('새 기록')));

    await pumpEditor(tester);
    await tester.enterText(find.byType(TextFormField), '새 기록');
    await tester.tap(find.text('올리기'));
    await tester.pumpAndSettle();

    verify(() => useCase.createPost(any())).called(1);
    // 결과를 들고 목록으로 돌아간다.
    expect(find.text('목록'), findsOneWidget);
  });

  testWidgets('공유로 들어오면 결과 카드와 안내를 본문 위에 보여준다', (tester) async {
    await pumpEditor(tester, tradeResult: _summary());

    expect(find.byType(TradeResultCard), findsOneWidget);
    expect(find.text('BTC · 2021-11-01 ~ 2022-01-29'), findsOneWidget);
    expect(find.text('+12.34%'), findsOneWidget);
    expect(find.text('판 결과가 함께 올라갑니다'), findsOneWidget);

    // 미리보기다. 눌러서 어딘가로 가지 않는다.
    final inkWell = tester.widget<InkWell>(
      find.descendant(
        of: find.byType(TradeResultCard),
        matching: find.byType(InkWell),
      ),
    );
    expect(inkWell.onTap, isNull);
  });

  testWidgets('그냥 들어온 작성 화면에는 결과 카드가 없다', (tester) async {
    await pumpEditor(tester);

    expect(find.byType(TradeResultCard), findsNothing);
    expect(find.text('판 결과가 함께 올라갑니다'), findsNothing);
  });

  testWidgets('붙어 온 판 id 를 그대로 올린다', (tester) async {
    when(
      () => useCase.createPost(any()),
    ).thenAnswer((_) async => Ok(_post('새 기록')));

    await pumpEditor(tester, tradeResult: _summary());
    await tester.enterText(find.byType(TextFormField), '오늘 판 결과');
    await tester.tap(find.text('올리기'));
    await tester.pumpAndSettle();

    final draft =
        verify(() => useCase.createPost(captureAny())).captured.single
            as PostDraft;
    expect(draft.content, '오늘 판 결과');
    expect(draft.tradeSessionId, 'session-1');
  });

  testWidgets('판만 붙어 있고 아무것도 쓰지 않았으면 나갈 때 묻지 않는다', (tester) async {
    // 카드는 입력이 아니다. 붙어 있다는 이유만으로 "버릴까요?"를 물으면
    // 잘못 들어왔다 나가는 길이 막힌다.
    await pumpEditor(tester, tradeResult: _summary());

    final route = ModalRoute.of(tester.element(find.byType(PostEditorPage)))!;
    route.navigator!.maybePop();
    await tester.pumpAndSettle();

    expect(find.text('작성 중인 내용을 버릴까요?'), findsNothing);
  });
}
