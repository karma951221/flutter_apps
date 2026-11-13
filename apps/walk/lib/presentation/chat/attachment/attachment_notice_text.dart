import 'package:l10n/l10n.dart';

import '../../../domain/chat/attachment/attachment_rules.dart';
import '../cubit/chat_state.dart';

/// 첨부하지 못한 이유의 스낵바 문구.
String attachmentNoticeText(
  AppLocalizations l10n,
  AttachmentNotice notice,
) => switch (notice.reason) {
  AttachmentRejection.unsupportedType => l10n.walkChatAttachUnsupported,
  AttachmentRejection.tooLarge => l10n.walkChatAttachTooLarge(notice.name),
  AttachmentRejection.notUtf8 => l10n.walkChatAttachNotUtf8(notice.name),
  AttachmentRejection.perQuestionLimit => l10n.walkChatAttachPerQuestionLimit,
  AttachmentRejection.conversationDocLimit => l10n.walkChatAttachDocLimit,
  AttachmentRejection.conversationImageLimit => l10n.walkChatAttachImageLimit,
  AttachmentRejection.conversationSizeLimit => l10n.walkChatAttachSizeLimit,
};

/// [📎] 가 꺼진 이유의 툴팁 문구.
String attachBlockText(AppLocalizations l10n, AttachBlock block) =>
    switch (block) {
      AttachBlock.perQuestion => l10n.walkChatAttachPerQuestionLimit,
      AttachBlock.conversation => l10n.walkChatAttachConversationFull,
    };
