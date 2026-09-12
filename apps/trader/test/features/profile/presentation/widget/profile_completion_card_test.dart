import 'package:daylog/design_system/theme/app_theme.dart';
import 'package:daylog/features/profile/domain/entity/profile.dart';
import 'package:daylog/features/profile/presentation/widget/profile_completion_card.dart';
import 'package:l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Profile _profile({String? avatarUrl, String? bio, int followingCount = 0}) =>
    Profile(
      id: 'me',
      nickname: '카르마',
      avatarUrl: avatarUrl,
      bio: bio,
      createdAt: DateTime.utc(2026, 9, 6),
      updatedAt: DateTime.utc(2026, 9, 6),
      followingCount: followingCount,
    );

void main() {
  Future<void> pumpCard(
    WidgetTester tester, {
    required Profile profile,
    bool hasPost = false,
    VoidCallback? onEditProfile,
    VoidCallback? onWritePost,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ProfileCompletionCard(
            profile: profile,
            hasPost: hasPost,
            onEditProfile: onEditProfile ?? () {},
            onWritePost: onWritePost ?? () {},
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('새 프로필은 닉네임 하나로 20% 에서 시작한다', (tester) async {
    await pumpCard(tester, profile: _profile());

    expect(find.text('프로필 완성 20%'), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, closeTo(0.2, 0.001));
    // 끝난 닉네임은 진행바가 말한다 — 줄로는 그리지 않는다.
    expect(find.text('닉네임 정하기'), findsNothing);
    expect(find.text('프로필 사진 올리기'), findsOneWidget);
    expect(find.text('자기소개 쓰기'), findsOneWidget);
    expect(find.text('첫 게시물 남기기'), findsOneWidget);
    expect(find.text('마음에 드는 사람 팔로우하기'), findsOneWidget);
  });

  testWidgets('끝난 항목은 목록에서 빠지고 남은 항목만 빈 원으로 남는다', (tester) async {
    await pumpCard(
      tester,
      profile: _profile(avatarUrl: 'https://x/a.webp', followingCount: 2),
      hasPost: true,
    );

    expect(find.text('프로필 완성 80%'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNothing);
    expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
    expect(find.text('자기소개 쓰기'), findsOneWidget);
    expect(find.text('닉네임 정하기'), findsNothing);
    expect(find.text('프로필 사진 올리기'), findsNothing);
    expect(find.text('첫 게시물 남기기'), findsNothing);
    expect(find.text('마음에 드는 사람 팔로우하기'), findsNothing);
  });

  testWidgets('사진·자기소개는 프로필 편집으로, 첫 게시물은 작성으로 보낸다', (tester) async {
    var editTaps = 0;
    var writeTaps = 0;
    await pumpCard(
      tester,
      profile: _profile(),
      onEditProfile: () => editTaps++,
      onWritePost: () => writeTaps++,
    );

    await tester.tap(find.text('프로필 사진 올리기'));
    await tester.tap(find.text('자기소개 쓰기'));
    await tester.tap(find.text('첫 게시물 남기기'));
    // 팔로우는 이 화면에서 할 수 있는 일이 아니라 눌러도 아무 일도 없다.
    await tester.tap(find.text('마음에 드는 사람 팔로우하기'));

    expect(editTaps, 2);
    expect(writeTaps, 1);
  });

  testWidgets('다섯 항목이 모두 끝나면 카드를 그리지 않는다', (tester) async {
    await pumpCard(
      tester,
      profile: _profile(
        avatarUrl: 'https://x/a.webp',
        bio: '안녕',
        followingCount: 1,
      ),
      hasPost: true,
    );

    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.textContaining('프로필 완성'), findsNothing);
  });
}
