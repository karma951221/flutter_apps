import 'package:flutter/widgets.dart';

import 'package:core/core.dart';

import '../l10n/app_localizations.dart';

/// Converts locale-independent failures into text at the presentation edge.
extension FailureLocalizations on Failure {
  String localizedMessage(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final code = failureCode;
    if (code != null) return code.localized(l10n);

    final raw = message;
    if (raw != null && raw.isNotEmpty) return raw;

    return switch (this) {
      NetworkFailure() => l10n.failureNetwork,
      AuthFailure() => l10n.failureAuth,
      ForbiddenFailure() => l10n.failureForbidden,
      NotFoundFailure() => l10n.failureNotFound,
      ValidationFailure() => l10n.failureValidation,
      ServerFailure() => l10n.failureServer,
      UnknownFailure() => l10n.failureUnknown,
    };
  }
}

extension on FailureCode {
  String localized(AppLocalizations l10n) => switch (this) {
    FailureCode.networkUnavailable => l10n.failureNetwork,
    FailureCode.invalidCredentials => l10n.failureInvalidCredentials,
    FailureCode.signInFailed => l10n.failureSignInFailed,
    FailureCode.signUpFailed => l10n.failureSignUpFailed,
    FailureCode.emailAlreadyRegistered => l10n.failureEmailAlreadyRegistered,
    FailureCode.weakPassword => l10n.failureWeakPassword,
    FailureCode.samePassword => l10n.failureSamePassword,
    FailureCode.otpExpired => l10n.failureOtpExpired,
    FailureCode.rateLimited => l10n.failureRateLimited,
    FailureCode.duplicateValue => l10n.failureDuplicateValue,
    FailureCode.constraintViolation => l10n.failureConstraintViolation,
    FailureCode.referencedTargetMissing => l10n.failureReferencedTargetMissing,
    FailureCode.forbiddenOrDeleted => l10n.failureForbiddenOrDeleted,
    FailureCode.targetNotFound => l10n.failureNotFound,
    FailureCode.nicknameLength => l10n.failureNicknameLength,
    FailureCode.nicknameTaken => l10n.profileNicknameTaken,
    FailureCode.bioTooLong => l10n.failureBioTooLong,
    FailureCode.postContentLength => l10n.failurePostContentLength,
    FailureCode.commentContentLength => l10n.failureCommentContentLength,
    FailureCode.unsupportedReaction => l10n.failureUnsupportedReaction,
    FailureCode.reportAlreadySubmitted => l10n.failureReportAlreadySubmitted,
    FailureCode.reportDetailTooLong => l10n.failureReportDetailTooLong,
    FailureCode.reportSelfNotAllowed => l10n.failureReportSelfNotAllowed,
    FailureCode.blockSelfNotAllowed => l10n.failureBlockSelfNotAllowed,
    FailureCode.blockAlreadyExists => l10n.failureBlockAlreadyExists,
    FailureCode.nestedReplyNotAllowed => l10n.failureNestedReplyNotAllowed,
    FailureCode.replyToDeletedCommentNotAllowed =>
      l10n.failureReplyToDeletedCommentNotAllowed,
    FailureCode.replyParentPostMismatch => l10n.failureReplyParentPostMismatch,
    FailureCode.replyParentMissing => l10n.failureReplyParentMissing,
    FailureCode.reportTargetMissing => l10n.failureReportTargetMissing,
    FailureCode.reportOwnPostNotAllowed => l10n.failureReportOwnPostNotAllowed,
    FailureCode.reportOwnCommentNotAllowed =>
      l10n.failureReportOwnCommentNotAllowed,
    FailureCode.commentNotAllowed => l10n.failureCommentNotAllowed,
    FailureCode.authenticationRequired => l10n.failureAuthenticationRequired,
    FailureCode.operationInProgress => l10n.failureOperationInProgress,
    FailureCode.commentsRangeInvalid => l10n.failureCommentsRangeInvalid,
    FailureCode.commentCursorInvalid => l10n.failureCommentCursorInvalid,
    FailureCode.commentContentRequired => l10n.failureCommentContentRequired,
    FailureCode.commentTooLong => l10n.failureCommentTooLong,
    FailureCode.commentDeleteTargetMissing =>
      l10n.failureCommentDeleteTargetMissing,
    FailureCode.roomTitleRequired => l10n.failureRoomTitleRequired,
    FailureCode.roomTitleTooLong => l10n.failureRoomTitleTooLong,
    FailureCode.roomDescriptionTooLong => l10n.failureRoomDescriptionTooLong,
    FailureCode.roomMemberLimitInvalid => l10n.failureRoomMemberLimitInvalid,
    FailureCode.roomNicknameTooShort => l10n.failureRoomNicknameTooShort,
    FailureCode.roomNicknameTooLong => l10n.failureRoomNicknameTooLong,
    FailureCode.messageContentRequired => l10n.failureMessageContentRequired,
    FailureCode.messageTooLong => l10n.failureMessageTooLong,
    FailureCode.feedRangeInvalid => l10n.failureFeedRangeInvalid,
    FailureCode.feedCursorInvalid => l10n.failureFeedCursorInvalid,
    FailureCode.feedNotLoaded => l10n.failureFeedNotLoaded,
    FailureCode.postNotFound => l10n.failurePostNotFound,
    FailureCode.messageCursorInvalid => l10n.failureMessageCursorInvalid,
    FailureCode.roomCursorInvalid => l10n.failureRoomCursorInvalid,
    FailureCode.postIdRequired => l10n.failurePostIdRequired,
    FailureCode.postContentRequired => l10n.failurePostContentRequired,
    FailureCode.postTooLong => l10n.failurePostTooLong,
    FailureCode.postImageLimit => l10n.failurePostImageLimit,
    FailureCode.avatarUploadFailed => l10n.failureAvatarUploadFailed,
    FailureCode.roomFull => l10n.failureRoomFull,
    FailureCode.roomNotFound => l10n.failureRoomNotFound,
    FailureCode.directChatNotAllowed => l10n.failureDirectChatNotAllowed,
    FailureCode.directChatSelfNotAllowed =>
      l10n.failureDirectChatSelfNotAllowed,
    FailureCode.chatSendNotAllowed => l10n.failureChatSendNotAllowed,
    FailureCode.reportOwnMessageNotAllowed =>
      l10n.failureReportOwnMessageNotAllowed,
    FailureCode.followUserIdRequired => l10n.failureFollowUserIdRequired,
    FailureCode.followRangeInvalid => l10n.failureFollowRangeInvalid,
    FailureCode.followCursorInvalid => l10n.failureFollowCursorInvalid,
    FailureCode.followBlocked => l10n.failureFollowBlocked,
    FailureCode.invalidData => l10n.failureInvalidData,
    FailureCode.tradeSessionAlreadyActive =>
      l10n.failureTradeSessionAlreadyActive,
    FailureCode.tradeSessionNotFound => l10n.failureTradeSessionNotFound,
    FailureCode.tradeSessionFinished => l10n.failureTradeSessionFinished,
    FailureCode.tradeInsufficientCash => l10n.failureTradeInsufficientCash,
    FailureCode.tradeInsufficientQuantity =>
      l10n.failureTradeInsufficientQuantity,
    FailureCode.tradeQuantityInvalid => l10n.failureTradeQuantityInvalid,
    FailureCode.tradeSessionNotShareable =>
      l10n.failureTradeSessionNotShareable,
    FailureCode.commuteNotConfigured => l10n.failureCommuteNotConfigured,
    FailureCode.locationPermissionDenied =>
      l10n.failureLocationPermissionDenied,
    FailureCode.locationServiceDisabled => l10n.failureLocationServiceDisabled,
    FailureCode.locationTimeout => l10n.failureLocationTimeout,
    FailureCode.routeSearchFailed => l10n.failureRouteSearchFailed,
    FailureCode.walkDogRequired => l10n.failureWalkDogRequired,
    FailureCode.walkTrackingAlreadyActive =>
      l10n.failureWalkTrackingAlreadyActive,
    FailureCode.walkNotFound => l10n.failureWalkNotFound,
    FailureCode.walkPhotoSaveFailed => l10n.failureWalkPhotoSaveFailed,
    FailureCode.dogNameRequired => l10n.failureDogNameRequired,
  };
}
