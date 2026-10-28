import 'package:l10n/l10n.dart';

import '../../../domain/chat/usecase/chat_session.dart';

/// 실패 말풍선에 보일 문구.
String chatFailureText(AppLocalizations l10n, ChatFailure failure) =>
    switch (failure) {
      ChatFailure.noKey => l10n.walkChatFailureNoKey,
      ChatFailure.invalidKey => l10n.walkChatFailureInvalidKey,
      ChatFailure.rateLimited => l10n.walkChatFailureRateLimited,
      ChatFailure.overloaded => l10n.walkChatFailureOverloaded,
      ChatFailure.network => l10n.walkChatFailureNetwork,
      ChatFailure.refused => l10n.walkChatFailureRefused,
      ChatFailure.tooManySteps => l10n.walkChatFailureTooManySteps,
      ChatFailure.unknown => l10n.walkChatFailureUnknown,
    };
