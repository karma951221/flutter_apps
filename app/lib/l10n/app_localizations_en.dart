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
  String get authBrowseFirst => 'Browse first';

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
  String get guestFeedTitle => 'Browse';

  @override
  String get guestPromptTitle => 'Sign up to react and comment';

  @override
  String get guestPromptDescription =>
      'All you need is an email and a nickname.';

  @override
  String get postEditTitle => 'Edit post';

  @override
  String get postCreateTitle => 'New post';

  @override
  String get postContentLabel => 'Today\'s record';

  @override
  String get postContentHint => 'Write down what comes to mind.';

  @override
  String get postTradeAttached => 'This round\'s result goes with the post';

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
  String get postDiscardLeave => 'Discard';

  @override
  String postImageLimitReached(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You can add up to $count photos',
      one: 'You can add up to 1 photo',
    );
    return '$_temp0';
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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Show $count replies',
      one: 'Show 1 reply',
    );
    return '$_temp0';
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
  String get themeModeSystem => 'System default';

  @override
  String get themeModeLight => 'Light';

  @override
  String get themeModeDark => 'Dark';

  @override
  String get languageSystem => 'System default';

  @override
  String get homeTabTrade => 'Trade';

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
  String get chatRoomEmptyMessage => 'Send the first message';

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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String chatMemberLimitValue(int count) {
    return 'Limit: $count';
  }

  @override
  String get commonSave => 'Save';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileUserTitle => 'User profile';

  @override
  String get profileMenuTooltip => 'Profile menu';

  @override
  String get profileMenuUnblock => 'Unblock';

  @override
  String get profileLoadFailed => 'Couldn\'t load the profile';

  @override
  String get profileBioEmpty => 'Add a bio.';

  @override
  String profileCompletionTitle(int percent) {
    return 'Profile $percent% complete';
  }

  @override
  String get profileCompletionNickname => 'Pick a nickname';

  @override
  String get profileCompletionAvatar => 'Add a profile photo';

  @override
  String get profileCompletionBio => 'Write a bio';

  @override
  String get profileCompletionFirstPost => 'Write your first post';

  @override
  String get profileCompletionFirstFollow => 'Follow someone you like';

  @override
  String get profileEditAction => 'Edit profile';

  @override
  String get profileMessageButton => 'Message';

  @override
  String get profilePostsTitle => 'Posts';

  @override
  String get profilePostsReload => 'Reload posts';

  @override
  String get profilePostsEmpty => 'No posts yet';

  @override
  String get profileNicknameChecking => 'Checking…';

  @override
  String get profileNicknameAvailable => 'This nickname is available';

  @override
  String get profileNicknameTaken => 'This nickname is already in use';

  @override
  String get profileNicknameLabel => 'Nickname';

  @override
  String get profileAvatarPickFailed => 'Couldn\'t load the profile photo.';

  @override
  String get profileEditTitle => 'Edit profile';

  @override
  String get profileSetupTitle => 'Set up your profile';

  @override
  String get profileSetupDescription =>
      'A photo and a short bio help neighbors know you. You can change them later in Settings.';

  @override
  String get profileSetupSkip => 'Later';

  @override
  String get profileSetupContinue => 'Continue';

  @override
  String get profileSaveFailed => 'Couldn\'t save the profile';

  @override
  String get profileSaveSucceeded => 'Profile saved';

  @override
  String get profileChoosePhoto => 'Choose photo';

  @override
  String get profileBioLabel => 'Bio';

  @override
  String get safetyUnblockAction => 'Unblock';

  @override
  String get safetyUnblockSucceeded => 'User unblocked.';

  @override
  String get safetyUnblockFailed => 'Couldn\'t unblock the user.';

  @override
  String get safetyReportTitle => 'Report';

  @override
  String get safetyReportFailed => 'Couldn\'t submit the report';

  @override
  String get safetyReportDetailLabel => 'Details (optional)';

  @override
  String get safetyReportDetailHint => 'Tell us what is wrong';

  @override
  String get safetyReportAction => 'Submit report';

  @override
  String get safetyReportReasonSpam => 'Spam or advertising';

  @override
  String get safetyReportReasonAbuse => 'Abuse or hate speech';

  @override
  String get safetyReportReasonSexual => 'Sexual content';

  @override
  String get safetyReportReasonViolence => 'Violence or threats';

  @override
  String get safetyReportReasonOther => 'Other';

  @override
  String get safetyBlockedUsersTitle => 'Blocked users';

  @override
  String get safetyBlockedUsersLoadFailed => 'Couldn\'t load blocked users';

  @override
  String get safetyBlockedUsersEmpty => 'You haven\'t blocked anyone';

  @override
  String get accountSettingsTitle => 'Account settings';

  @override
  String get accountPasswordChange => 'Change password';

  @override
  String get accountDelete => 'Delete account';

  @override
  String get accountDeleteSubtitle =>
      'Your account and all activity will be deleted immediately';

  @override
  String get accountDeleteFailed => 'Couldn\'t delete the account. Try again.';

  @override
  String get accountDeleteConfirmTitle => 'Delete your account?';

  @override
  String get accountDeleteConfirmMessage =>
      'The following will be permanently deleted with your account:\n\n• Profile and profile photo\n• Posts and photos\n• Comments and reactions';

  @override
  String accountDeleteConfirmMessageCounted(int postCount, int commentCount) {
    String _temp0 = intl.Intl.pluralLogic(
      postCount,
      locale: localeName,
      other: '$postCount posts and their photos',
      one: '1 post and its photos',
    );
    String _temp1 = intl.Intl.pluralLogic(
      commentCount,
      locale: localeName,
      other: '$commentCount comments and reactions',
      one: '1 comment and reactions',
    );
    return 'The following will be permanently deleted with your account:\n\n• Profile and profile photo\n• $_temp0\n• $_temp1';
  }

  @override
  String get accountDeleteConfirmAction => 'Delete account';

  @override
  String get passwordChangeTitle => 'Change password';

  @override
  String get passwordChangeSucceeded => 'Password changed';

  @override
  String get passwordChangeFailed => 'Couldn\'t change the password';

  @override
  String get passwordChangeNewLabel => 'New password';

  @override
  String get passwordChangeConfirmLabel => 'Confirm new password';

  @override
  String get passwordChangeAction => 'Change';

  @override
  String get validationEmailRequired => 'Enter your email';

  @override
  String get validationEmailInvalid => 'Enter a valid email address';

  @override
  String get validationPasswordRequired => 'Enter your password';

  @override
  String get validationPasswordTooShort =>
      'Password must be at least 8 characters';

  @override
  String get validationPasswordConfirmationRequired =>
      'Enter your password again';

  @override
  String get validationPasswordMismatch => 'Passwords don\'t match';

  @override
  String get validationNicknameRequired => 'Enter a nickname';

  @override
  String get validationNicknameTooShort =>
      'Nickname must be at least 2 characters';

  @override
  String get validationNicknameTooLong =>
      'Nickname must be 20 characters or fewer';

  @override
  String get validationOtpRequired => 'Enter the code';

  @override
  String get validationOtpInvalid => 'Enter the 6-digit code';

  @override
  String get failureNetwork => 'Can\'t connect to the network';

  @override
  String get failureAuth => 'Authentication failed';

  @override
  String get failureForbidden => 'You don\'t have permission';

  @override
  String get failureNotFound => 'Couldn\'t find the requested item';

  @override
  String get failureValidation => 'Check your input';

  @override
  String get failureServer => 'A server error occurred';

  @override
  String get failureUnknown => 'An unknown error occurred';

  @override
  String get failureInvalidCredentials => 'Email or password is incorrect';

  @override
  String get failureSignInFailed => 'Couldn\'t sign in';

  @override
  String get failureSignUpFailed => 'Couldn\'t create the account';

  @override
  String get failureEmailAlreadyRegistered =>
      'This email is already registered';

  @override
  String get failureWeakPassword => 'Choose a stronger password';

  @override
  String get failureSamePassword =>
      'Enter a password different from your current one';

  @override
  String get failureOtpExpired => 'The code has expired. Request a new one';

  @override
  String get failureRateLimited => 'Too many requests. Try again later';

  @override
  String get failureDuplicateValue => 'This value is already in use';

  @override
  String get failureConstraintViolation =>
      'The input doesn\'t meet the requirements';

  @override
  String get failureReferencedTargetMissing =>
      'The referenced item doesn\'t exist';

  @override
  String get failureForbiddenOrDeleted =>
      'You don\'t have permission or the item was deleted';

  @override
  String get failureNicknameLength => 'Nickname must be 2–20 characters';

  @override
  String get failureBioTooLong => 'Bio must be 200 characters or fewer';

  @override
  String get failurePostContentLength => 'Post must be 1–500 characters';

  @override
  String get failureCommentContentLength => 'Comment must be 1–300 characters';

  @override
  String get failureUnsupportedReaction => 'This reaction isn\'t supported';

  @override
  String get failureReportAlreadySubmitted =>
      'You\'ve already reported this item';

  @override
  String get failureReportDetailTooLong =>
      'Details must be 500 characters or fewer';

  @override
  String get failureReportSelfNotAllowed => 'You can\'t report yourself';

  @override
  String get failureBlockSelfNotAllowed => 'You can\'t block yourself';

  @override
  String get failureBlockAlreadyExists => 'This user is already blocked';

  @override
  String get failureNestedReplyNotAllowed => 'You can\'t reply to a reply';

  @override
  String get failureReplyToDeletedCommentNotAllowed =>
      'You can\'t reply to a deleted comment';

  @override
  String get failureReplyParentPostMismatch =>
      'The parent comment belongs to another post';

  @override
  String get failureReplyParentMissing => 'The parent comment doesn\'t exist';

  @override
  String get failureReportTargetMissing => 'The item to report doesn\'t exist';

  @override
  String get failureReportOwnPostNotAllowed =>
      'You can\'t report your own post';

  @override
  String get failureReportOwnCommentNotAllowed =>
      'You can\'t report your own comment';

  @override
  String get failureCommentNotAllowed =>
      'Comments aren\'t available for this post';

  @override
  String get failureAuthenticationRequired => 'You need to sign in';

  @override
  String get failureOperationInProgress => 'This action is already in progress';

  @override
  String get failureCommentsRangeInvalid => 'Invalid comment range';

  @override
  String get failureCommentCursorInvalid => 'Invalid comment cursor';

  @override
  String get failureCommentContentRequired => 'Enter a comment';

  @override
  String get failureCommentTooLong => 'Comment must be 300 characters or fewer';

  @override
  String get failureCommentDeleteTargetMissing =>
      'Couldn\'t find the comment to delete';

  @override
  String get failureRoomTitleRequired => 'Enter a room name';

  @override
  String get failureRoomTitleTooLong =>
      'Room name must be 30 characters or fewer';

  @override
  String get failureRoomDescriptionTooLong =>
      'Description must be 200 characters or fewer';

  @override
  String get failureRoomMemberLimitInvalid =>
      'Room limit must be between 2 and 500 members';

  @override
  String get failureRoomNicknameTooShort =>
      'Name in room must be at least 2 characters';

  @override
  String get failureRoomNicknameTooLong =>
      'Name in room must be 20 characters or fewer';

  @override
  String get failureMessageContentRequired => 'Enter a message';

  @override
  String get failureMessageTooLong =>
      'Message must be 1,000 characters or fewer';

  @override
  String get failureFeedRangeInvalid => 'Invalid feed range';

  @override
  String get failureFeedCursorInvalid => 'Invalid feed cursor';

  @override
  String get failureFeedNotLoaded => 'Load the list first';

  @override
  String get failurePostNotFound => 'Couldn\'t find the post';

  @override
  String get failureMessageCursorInvalid => 'Invalid message cursor';

  @override
  String get failureRoomCursorInvalid => 'Invalid room cursor';

  @override
  String get failurePostIdRequired => 'Post ID is required';

  @override
  String get failurePostContentRequired => 'Enter post content';

  @override
  String get failurePostTooLong => 'Post must be 500 characters or fewer';

  @override
  String get failurePostImageLimit => 'You can attach up to 5 photos';

  @override
  String get failureAvatarUploadFailed => 'Couldn\'t upload the profile photo.';

  @override
  String get failureInvalidData => 'Received invalid data';

  @override
  String get reactionLike => 'Like';

  @override
  String get reactionDislike => 'Dislike';

  @override
  String avatarSemanticsLabel(String nickname) {
    return '$nickname\'s profile photo';
  }

  @override
  String get feedTabAll => 'All';

  @override
  String get feedTabFollowing => 'Following';

  @override
  String get feedFollowingEmptyMessage => 'You are not following anyone yet';

  @override
  String get feedFollowingEmptyDescription =>
      'Follow someone and their posts will show up here.';

  @override
  String get feedFollowingEmptyAction => 'Browse everyone';

  @override
  String get followAction => 'Follow';

  @override
  String get followFollowingAction => 'Following';

  @override
  String get followMutualAction => 'Mutual';

  @override
  String get followFailed => 'Couldn\'t follow';

  @override
  String get followUnfollowFailed => 'Couldn\'t unfollow';

  @override
  String get followFollowersLabel => 'Followers';

  @override
  String get followFollowingsLabel => 'Following';

  @override
  String get followFollowersTitle => 'Followers';

  @override
  String get followFollowingsTitle => 'Following';

  @override
  String get followFollowersEmpty => 'No followers yet';

  @override
  String get followFollowingsEmpty => 'Not following anyone yet';

  @override
  String get followListLoadFailed => 'Couldn\'t load the list';

  @override
  String get failureFollowUserIdRequired => 'User ID is required';

  @override
  String get failureFollowRangeInvalid => 'Invalid follow list range';

  @override
  String get failureFollowCursorInvalid => 'Invalid follow list cursor';

  @override
  String get failureFollowBlocked => 'You can\'t follow this account right now';

  @override
  String get failureRoomFull => 'This room is full';

  @override
  String get failureRoomNotFound => 'This room doesn\'t exist';

  @override
  String get failureDirectChatNotAllowed =>
      'You can\'t start this conversation right now';

  @override
  String get failureDirectChatSelfNotAllowed =>
      'You can\'t start a conversation with yourself';

  @override
  String get failureChatSendNotAllowed =>
      'You can\'t send this message right now';

  @override
  String get failureReportOwnMessageNotAllowed =>
      'You can\'t report your own message';

  @override
  String get failureTradeSessionAlreadyActive =>
      'You already have a session in progress';

  @override
  String get failureTradeSessionNotFound => 'Session not found';

  @override
  String get failureTradeSessionFinished => 'This session has already ended';

  @override
  String get failureTradeInsufficientCash => 'Insufficient cash balance';

  @override
  String get failureTradeInsufficientQuantity => 'Insufficient quantity held';

  @override
  String get failureTradeQuantityInvalid => 'Quantity must be greater than 0';

  @override
  String get failureTradeSessionNotShareable =>
      'Only finished sessions can be shared';

  @override
  String get tradeHomeTitle => 'Paper trading';

  @override
  String get tradeStart => 'Start a new round';

  @override
  String get tradeResume => 'Resume';

  @override
  String tradeStepOf(int step, int total) {
    return '$step / $total';
  }

  @override
  String get tradeEquity => 'Equity';

  @override
  String get tradePastSessions => 'Past rounds';

  @override
  String get tradeEmptyTitle => 'No rounds yet';

  @override
  String get tradeEmptyDescription =>
      'Step through a real past chart one day at a time and trade it';

  @override
  String get tradeResultTitle => 'Result';

  @override
  String get tradeReturn => 'Return';

  @override
  String get tradeBuyHold => 'Buy & hold';

  @override
  String get tradeMaxDrawdown => 'Max drawdown';

  @override
  String get tradeCount => 'Trades';

  @override
  String tradeCountValue(int count) {
    return '$count';
  }

  @override
  String tradeBeatBuyHold(String diff) {
    return '$diff better than buy & hold';
  }

  @override
  String tradeLostToBuyHold(String diff) {
    return '$diff worse than buy & hold';
  }

  @override
  String get tradeResultNotReady => 'This round hasn\'t finished yet';

  @override
  String get tradeShare => 'Share';

  @override
  String tradeCardBuyHold(String pct) {
    return 'Buy & hold $pct';
  }

  @override
  String tradeCardMaxDrawdown(String pct) {
    return 'Max drawdown $pct';
  }

  @override
  String tradeCardCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trades',
      one: '1 trade',
    );
    return '$_temp0';
  }

  @override
  String get tradeSessionTitle => 'Paper trading';

  @override
  String get tradeFinishNow => 'Close out and finish';

  @override
  String get tradeFinishConfirmTitle => 'Finish now?';

  @override
  String get tradeFinishConfirmMessage =>
      'Your holdings are sold at the current price and the round ends. This can\'t be undone.';

  @override
  String get tradeCash => 'Cash';

  @override
  String get tradeQuantity => 'Holdings';

  @override
  String get tradeCurrentReturn => 'Current return';

  @override
  String get tradeCurrentPrice => 'Current price';

  @override
  String get tradeBuy => 'Buy';

  @override
  String get tradeSell => 'Sell';

  @override
  String get tradeNextDay => 'Next day';

  @override
  String get tradeByAmount => 'Amount';

  @override
  String get tradeByQuantity => 'Quantity';

  @override
  String get tradeExpectedQuantity => 'Estimated quantity';

  @override
  String get tradeExpectedProceeds => 'Estimated proceeds';

  @override
  String get tradeFee => 'Fee';

  @override
  String get tradeRemainingCash => 'Cash after order';

  @override
  String get tradeRemainingQuantity => 'Holdings after order';

  @override
  String get tradeConfirmOrder => 'Place order';

  @override
  String get tradeInvalidNumber => 'Enter a valid number';

  @override
  String get tradeQuantityMustBePositive => 'Enter a value greater than zero';

  @override
  String get tradeOrderPlaced => 'Order filled';

  @override
  String tradeFractionLabel(int pct) {
    return '$pct%';
  }
}
