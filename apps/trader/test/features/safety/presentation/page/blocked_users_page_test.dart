import 'package:core/core.dart';
import 'package:daylog/l10n/app_localizations.dart';
import 'package:daylog/design_system/theme/app_theme.dart';
import 'package:daylog/design_system/widget/app_list_tile.dart';
import 'package:daylog/features/safety/domain/entity/blocked_user.dart';
import 'package:daylog/features/safety/domain/usecase/safety_use_case.dart';
import 'package:daylog/features/safety/presentation/cubit/blocked_users_cubit.dart';
import 'package:daylog/features/safety/presentation/page/blocked_users_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSafetyUseCase extends Mock implements SafetyUseCase {}

void main() {
  late _MockSafetyUseCase useCase;

  final userA = BlockedUser(
    id: 'a',
    nickname: '이웃A',
    avatarUrl: null,
    blockedAt: DateTime.utc(2026, 8, 25),
  );
  final userB = BlockedUser(
    id: 'b',
    nickname: '이웃B',
    avatarUrl: null,
    blockedAt: DateTime.utc(2026, 8, 24),
  );

  setUpAll(() => registerFallbackValue('_'));

  setUp(() {
    useCase = _MockSafetyUseCase();
    getIt.registerFactory<BlockedUsersCubit>(() => BlockedUsersCubit(useCase));
  });

  tearDown(getIt.reset);

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const BlockedUsersPage(),
      ),
    );
    await tester.pump();
  }

  testWidgets('차단한 사용자가 없으면 안내 문구를 보여준다', (tester) async {
    when(() => useCase.getBlockedUsers()).thenAnswer((_) async => const Ok([]));

    await pumpPage(tester);

    expect(find.text('차단한 사용자가 없습니다'), findsOneWidget);
  });

  testWidgets('목록은 닉네임과 차단 해제 버튼을 함께 보여준다', (tester) async {
    when(
      () => useCase.getBlockedUsers(),
    ).thenAnswer((_) async => Ok([userA, userB]));

    await pumpPage(tester);

    expect(find.byType(AppListTile), findsNWidgets(2));
    expect(find.text('이웃A'), findsOneWidget);
    expect(find.text('이웃B'), findsOneWidget);
    expect(find.widgetWithText(TextButton, '차단 해제'), findsNWidgets(2));
  });

  testWidgets('조회 실패면 오류와 다시 시도 버튼을 보여준다', (tester) async {
    when(
      () => useCase.getBlockedUsers(),
    ).thenAnswer((_) async => const Err(Failure.network()));

    await pumpPage(tester);

    expect(find.text('다시 시도'), findsOneWidget);
  });

  testWidgets('차단 해제를 누르면 그 행이 사라지고 스낵바가 뜬다', (tester) async {
    when(
      () => useCase.getBlockedUsers(),
    ).thenAnswer((_) async => Ok([userA, userB]));
    when(
      () => useCase.unblockUser(any()),
    ).thenAnswer((_) async => const Ok(null));

    await pumpPage(tester);

    await tester.tap(find.widgetWithText(TextButton, '차단 해제').first);
    await tester.pump();

    expect(find.byType(AppListTile), findsNWidgets(1));
    expect(find.text('차단을 해제했습니다.'), findsOneWidget);
    verify(() => useCase.unblockUser('a')).called(1);
  });

  testWidgets('차단 해제가 실패하면 행이 그대로 남고 오류 스낵바가 뜬다', (tester) async {
    when(() => useCase.getBlockedUsers()).thenAnswer((_) async => Ok([userA]));
    when(
      () => useCase.unblockUser(any()),
    ).thenAnswer((_) async => const Err(Failure.network()));

    await pumpPage(tester);

    await tester.tap(find.widgetWithText(TextButton, '차단 해제').first);
    await tester.pump();

    expect(find.byType(AppListTile), findsNWidgets(1));
    expect(find.text('차단을 해제하지 못했습니다.'), findsOneWidget);
  });
}
