import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/domain/chat/attachment/attachment_rules.dart';
import 'package:walk/presentation/chat/attachment/attachment_notice_text.dart';
import 'package:walk/presentation/chat/cubit/chat_state.dart';

void main() {
  test('문서 바이트 합계 한도 문구', () {
    final l10n = lookupAppLocalizations(const Locale('ko'));

    expect(
      attachmentNoticeText(
        l10n,
        const AttachmentNotice(
          name: 'a.pdf',
          reason: AttachmentRejection.conversationSizeLimit,
        ),
      ),
      '이 대화에서 보낸 파일이 너무 커요(PDF · 텍스트 합계 18MB까지). [새 대화]에서 다시 보내 주세요',
    );
  });
}
