import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/domain/lock/lock_config.dart';
import 'package:walk/presentation/lock/widget/lock_secret_input.dart';
import 'package:walk/presentation/lock/widget/pattern_lock.dart';

void main() {
  group('lockBlockedMessage', () {
    final l10n = lookupAppLocalizations(const Locale('ko'));

    test('차단이 아니면 null', () {
      expect(lockBlockedMessage(l10n, null, longBlock: false), isNull);
    });

    test('30초 차단은 남은 초를 올림', () {
      expect(
        lockBlockedMessage(
          l10n,
          const Duration(seconds: 29, milliseconds: 1),
          longBlock: false,
        ),
        '30초 뒤에 다시 시도할 수 있어요',
      );
    });

    test('24시간 차단은 시간 · 분', () {
      expect(
        lockBlockedMessage(
          l10n,
          const Duration(hours: 23, minutes: 5, seconds: 10),
          longBlock: true,
        ),
        '폰 인증에 실패했어요. 23시간 5분 뒤에 다시 시도할 수 있어요',
      );
    });
  });

  testWidgets('패턴은 점 인덱스를 - 로 이어 넘긴다', (tester) async {
    final secrets = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: LockSecretInput(
            method: LockMethod.pattern,
            onSecret: secrets.add,
          ),
        ),
      ),
    );

    tester.widget<PatternLock>(find.byType(PatternLock)).onCompleted([
      0,
      1,
      2,
      5,
    ]);

    expect(secrets, ['0-1-2-5']);
  });
}
