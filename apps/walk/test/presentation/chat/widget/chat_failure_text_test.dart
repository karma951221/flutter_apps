import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/domain/chat/usecase/chat_session.dart';
import 'package:walk/presentation/chat/widget/chat_failure_text.dart';

void main() {
  test('크레딧 부족 · 모델 없음 문구(ko)', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));

    expect(
      chatFailureText(l10n, ChatFailure.quotaExceeded),
      '크레딧이 부족해요. 결제 상태를 확인해 주세요',
    );
    expect(
      chatFailureText(l10n, ChatFailure.modelUnavailable),
      '지금 모델을 쓸 수 없어요. 잠시 뒤 다시 물어봐 주세요',
    );
  });

  test('모든 실패에 빈 문구가 없다', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    for (final failure in ChatFailure.values) {
      expect(chatFailureText(l10n, failure), isNotEmpty, reason: '$failure');
    }
  });
}
