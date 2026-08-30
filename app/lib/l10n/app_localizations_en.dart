// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonMoreActions => 'More';

  @override
  String get authSignInDescription =>
      'Record your day and share it with your neighbors.';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authForgotPassword => 'Forgot your password?';

  @override
  String get authNoAccountPrompt => 'Don\'t have an account yet?';

  @override
  String get authSignUp => 'Sign up';

  @override
  String get authSignUpDescription =>
      'An email and a nickname are all you need to start.';

  @override
  String get authNicknameLabel => 'Nickname (2-20 characters)';

  @override
  String get authPasswordWithRuleLabel => 'Password (8 characters or more)';

  @override
  String get authPasswordConfirmLabel => 'Confirm password';

  @override
  String get authSignUpSubmit => 'Create account';

  @override
  String get authPasswordResetTitle => 'Reset password';

  @override
  String get authPasswordResetDescription =>
      'We send a 6-digit code to your registered email.';

  @override
  String get authPasswordResetSendCode => 'Send code';

  @override
  String get authPasswordResetCodeTitle => 'Enter code';

  @override
  String authPasswordResetCodeDescription(String email) {
    return 'Enter the 6-digit code sent to $email.';
  }

  @override
  String get authPasswordResetCodeLabel => 'Verification code';

  @override
  String get authPasswordResetVerify => 'Confirm';

  @override
  String get authPasswordResetChangeEmail => 'Use a different email';

  @override
  String get authNewPasswordTitle => 'New password';

  @override
  String get authNewPasswordDescription =>
      'Enter the password you will use from now on.';

  @override
  String get authNewPasswordLabel => 'New password (8 characters or more)';

  @override
  String get authNewPasswordConfirmLabel => 'Confirm new password';

  @override
  String get authPasswordChangeSubmit => 'Change password';

  @override
  String get authPasswordChangedTitle => 'Your password has been changed.';

  @override
  String get authPasswordChangedDescription =>
      'Sign in again with your new password.';

  @override
  String get authGoToSignIn => 'Go to sign in';

  @override
  String get authPasswordShow => 'Show password';

  @override
  String get authPasswordHide => 'Hide password';

  @override
  String get feedLoadFailed => 'Couldn\'t load the feed';

  @override
  String get feedLoadFailedDescription =>
      'Check your connection and try again.';

  @override
  String get feedComposeTooltip => 'Write a new post';

  @override
  String get feedComposeLabel => 'Write';

  @override
  String get feedEmptyMessage => 'No posts yet';

  @override
  String get feedEmptyDescription => 'Leave your first post.';

  @override
  String get feedEmptyAction => 'Write the first post';

  @override
  String get feedEndOfList => 'You\'re all caught up';

  @override
  String get postEditTitle => 'Edit post';

  @override
  String get postCreateTitle => 'New post';

  @override
  String get postContentLabel => 'Today\'s record';

  @override
  String get postContentHint => 'Write down what comes to mind.';

  @override
  String get postContentRequired => 'Enter the post content.';

  @override
  String get postSaveButton => 'Save';

  @override
  String get postSubmitButton => 'Publish';

  @override
  String get postCreated => 'Post published.';

  @override
  String get postUpdated => 'Post updated.';

  @override
  String get postSaveFailed => 'Couldn\'t save the post.';

  @override
  String get postImagePrepareFailed => 'Couldn\'t prepare the image.';

  @override
  String get postDiscardEditTitle => 'Cancel editing?';

  @override
  String get postDiscardCreateTitle => 'Discard this draft?';

  @override
  String get postDiscardMessage => 'What you typed will not be saved.';

  @override
  String get postDiscardKeepWriting => 'Keep writing';

  @override
  String get postDiscardLeave => 'Leave';

  @override
  String postImageLimitReached(int count) {
    return 'You can add up to $count photos';
  }

  @override
  String postAddImages(int count, int max) {
    return 'Add photos ($count/$max)';
  }

  @override
  String get postRemoveImageTooltip => 'Remove photo';

  @override
  String get postCommentCountTooltip => 'Comments';

  @override
  String get postMenuTooltip => 'Post menu';

  @override
  String get postMenuEdit => 'Edit';

  @override
  String get postMenuReport => 'Report';

  @override
  String get postMenuBlockUser => 'Block this user';

  @override
  String get postDeleteConfirmTitle => 'Delete this post?';

  @override
  String get postDeleteConfirmMessage => 'A deleted post cannot be restored.';

  @override
  String get postDeleteSucceeded => 'Post deleted.';

  @override
  String get postDeleteFailed => 'Couldn\'t delete the post.';

  @override
  String get commentTitle => 'Comments';

  @override
  String get commentLoadFailed => 'Couldn\'t load the comments';

  @override
  String get commentEmptyMessage => 'Leave the first comment.';

  @override
  String get commentLoadMoreReplies => 'Show more replies';

  @override
  String get commentMenuTooltip => 'Comment menu';

  @override
  String get commentMenuReport => 'Report';

  @override
  String get commentDeletedPlaceholder => 'This comment was deleted';

  @override
  String get commentReply => 'Reply';

  @override
  String get commentHideReplies => 'Hide replies';

  @override
  String commentShowReplies(int count) {
    return 'Show $count replies';
  }

  @override
  String get commentDeleteConfirmTitle => 'Delete this comment?';

  @override
  String get commentDeleteConfirmMessage =>
      'A deleted comment cannot be restored.';

  @override
  String get commentDeleteSucceeded => 'Comment deleted.';

  @override
  String get commentDeleteNotAllowed => 'This comment cannot be deleted.';

  @override
  String get commentDeleteFailed => 'Couldn\'t delete the comment.';

  @override
  String commentReplyingTo(String nickname) {
    return 'Replying to $nickname';
  }

  @override
  String get commentReplyCancelTooltip => 'Cancel reply';

  @override
  String get commentInputHint => 'Write a comment';

  @override
  String get commentReplyInputHint => 'Write a reply';

  @override
  String get commentSubmitTooltip => 'Post';

  @override
  String get commentSignInRequired => 'You need to sign in.';

  @override
  String get commentCreateFailed => 'Couldn\'t post the comment.';

  @override
  String get reactionSaveFailed => 'Couldn\'t save your reaction.';

  @override
  String get safetyReportSubmitted => 'Your report has been submitted';

  @override
  String get safetyBlockConfirmTitle => 'Block this user?';

  @override
  String get safetyBlockConfirmMessage =>
      'Once blocked, this user\'s posts and comments no longer appear.';

  @override
  String get safetyBlockConfirmAction => 'Block';

  @override
  String get safetyBlockSucceeded => 'User blocked.';

  @override
  String get safetyBlockFailed => 'Couldn\'t block the user.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsProfileEdit => 'Edit profile';

  @override
  String get settingsAccount => 'Account settings';

  @override
  String get settingsTheme => 'Appearance';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsBlockedUsers => 'Blocked users';

  @override
  String get settingsSignOut => 'Sign out';

  @override
  String get settingsSignOutConfirmTitle => 'Sign out?';

  @override
  String get settingsSignOutConfirmMessage =>
      'You will need to sign in again to use the app.';

  @override
  String get themeModeSystem => 'System setting';

  @override
  String get themeModeLight => 'Light';

  @override
  String get themeModeDark => 'Dark';

  @override
  String get languageSystem => 'System setting';

  @override
  String get homeTabFeed => 'Home';

  @override
  String get homeTabChat => 'Chat';

  @override
  String get homeTabProfile => 'Profile';

  @override
  String get homeTabSettings => 'Settings';

  @override
  String get chatTitle => 'Chat';

  @override
  String get chatLoadFailed => 'Couldn\'t load your chats';

  @override
  String get chatEmptyMessage => 'You haven\'t joined any rooms';

  @override
  String get chatEmptyDescription => 'Find an open room and join in.';

  @override
  String get chatEmptyAction => 'Browse rooms';

  @override
  String get chatExploreTooltip => 'Browse rooms';

  @override
  String get chatCreateRoomLabel => 'New room';

  @override
  String get chatNoMessagesYet => 'No messages yet';

  @override
  String get chatLastMessageImage => 'Photo';

  @override
  String get chatExploreTitle => 'Browse rooms';

  @override
  String get chatSearchHint => 'Search by room name';

  @override
  String get chatExploreEmptyMessage => 'No open rooms';

  @override
  String get chatExploreEmptyDescription => 'Be the first to make one.';

  @override
  String get chatExploreNoResult => 'No results';

  @override
  String get chatExploreLoadFailed => 'Couldn\'t load rooms';

  @override
  String get chatJoinTitle => 'Your name in this room';

  @override
  String get chatJoinDescription =>
      'You can use a different name in each room.';

  @override
  String get chatJoinNicknameLabel => 'Name in room';

  @override
  String get chatJoinAction => 'Join';

  @override
  String get chatJoinFailed => 'Couldn\'t join';

  @override
  String get chatCreateTitle => 'New room';

  @override
  String get chatRoomTitleLabel => 'Room name';

  @override
  String get chatRoomDescriptionLabel => 'Description (optional)';

  @override
  String get chatNicknameLabel => 'Name in room';

  @override
  String get chatCreateAction => 'Create';

  @override
  String get chatCreateFailed => 'Couldn\'t create the room';

  @override
  String get chatRoomEmptyMessage => 'Say something first';

  @override
  String get chatRoomLoadFailed => 'Couldn\'t load the conversation';

  @override
  String get chatComposerHint => 'Message';

  @override
  String get chatSendTooltip => 'Send';

  @override
  String get chatAttachTooltip => 'Send a photo';

  @override
  String get chatRoomMenuTooltip => 'Room menu';

  @override
  String get chatMenuParticipants => 'Members';

  @override
  String get chatMenuLeave => 'Leave room';

  @override
  String get chatParticipantsTitle => 'Members';

  @override
  String get chatLeaveConfirmTitle => 'Leave this room?';

  @override
  String get chatLeaveConfirmMessage =>
      'It disappears from your list. Messages you sent stay in the room.';

  @override
  String get chatLeaveConfirmAction => 'Leave';

  @override
  String get chatLeaveFailed => 'Couldn\'t leave the room';

  @override
  String get chatMessageDelete => 'Delete';

  @override
  String get chatMessageReport => 'Report';

  @override
  String get chatDeleteConfirmTitle => 'Delete this message?';

  @override
  String get chatDeleteConfirmMessage => 'Deleted messages can\'t be restored.';

  @override
  String get chatSendFailed => 'Couldn\'t send the message';

  @override
  String get chatSendFailedShort => 'Failed';

  @override
  String get chatSending => 'Sending';

  @override
  String get chatRetry => 'Send again';

  @override
  String get chatImageLoadFailed => 'Couldn\'t load the photo';

  @override
  String get chatImagePrepareFailed => 'Couldn\'t prepare the photo.';

  @override
  String chatSystemJoined(String nickname) {
    return '$nickname joined';
  }

  @override
  String chatSystemLeft(String nickname) {
    return '$nickname left';
  }

  @override
  String chatMemberCount(int count) {
    return '$count members';
  }

  @override
  String chatMemberLimitValue(int count) {
    return 'Limit: $count';
  }
}
