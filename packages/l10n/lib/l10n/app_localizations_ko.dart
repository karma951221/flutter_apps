// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get commonCancel => '취소';

  @override
  String get commonDelete => '삭제';

  @override
  String get commonRetry => '다시 시도';

  @override
  String get commonMoreActions => '더보기';

  @override
  String get authSignInDescription => '오늘 하루를 기록하고 이웃과 나눠보세요.';

  @override
  String get authEmailLabel => '이메일';

  @override
  String get authPasswordLabel => '비밀번호';

  @override
  String get authSignIn => '로그인';

  @override
  String get authForgotPassword => '비밀번호를 잊으셨나요?';

  @override
  String get authNoAccountPrompt => '아직 계정이 없으신가요?';

  @override
  String get authSignUp => '회원가입';

  @override
  String get authBrowseFirst => '먼저 둘러보기';

  @override
  String get authSignUpDescription => '이메일과 닉네임만 있으면 바로 시작할 수 있습니다.';

  @override
  String get authNicknameLabel => '닉네임 (2~20자)';

  @override
  String get authPasswordWithRuleLabel => '비밀번호 (8자 이상)';

  @override
  String get authPasswordConfirmLabel => '비밀번호 확인';

  @override
  String get authSignUpSubmit => '가입하기';

  @override
  String get authPasswordResetTitle => '비밀번호 재설정';

  @override
  String get authPasswordResetDescription => '가입한 이메일로 6자리 코드를 보내드립니다.';

  @override
  String get authPasswordResetSendCode => '코드 받기';

  @override
  String get authPasswordResetCodeTitle => '코드 입력';

  @override
  String authPasswordResetCodeDescription(String email) {
    return '$email 주소로 보낸 6자리 코드를 입력하세요.';
  }

  @override
  String get authPasswordResetCodeLabel => '인증 코드';

  @override
  String get authPasswordResetVerify => '확인';

  @override
  String get authPasswordResetChangeEmail => '이메일 다시 입력';

  @override
  String get authNewPasswordTitle => '새 비밀번호';

  @override
  String get authNewPasswordDescription => '앞으로 사용할 비밀번호를 입력하세요.';

  @override
  String get authNewPasswordLabel => '새 비밀번호 (8자 이상)';

  @override
  String get authNewPasswordConfirmLabel => '새 비밀번호 확인';

  @override
  String get authPasswordChangeSubmit => '비밀번호 변경';

  @override
  String get authPasswordChangedTitle => '비밀번호가 변경되었습니다.';

  @override
  String get authPasswordChangedDescription => '새 비밀번호로 다시 로그인하세요.';

  @override
  String get authGoToSignIn => '로그인하러 가기';

  @override
  String get authPasswordShow => '비밀번호 표시';

  @override
  String get authPasswordHide => '비밀번호 숨기기';

  @override
  String get feedLoadFailed => '피드를 불러오지 못했습니다';

  @override
  String get feedLoadFailedDescription => '연결을 확인하고 다시 시도해 주세요.';

  @override
  String get feedComposeTooltip => '새 게시물 작성';

  @override
  String get feedComposeLabel => '작성';

  @override
  String get feedEmptyMessage => '아직 게시물이 없습니다';

  @override
  String get feedEmptyDescription => '첫 게시물을 남겨보세요.';

  @override
  String get feedEmptyAction => '첫 게시물 쓰기';

  @override
  String get feedEndOfList => '모두 확인했습니다';

  @override
  String get guestFeedTitle => '둘러보기';

  @override
  String get guestPromptTitle => '가입하면 반응과 댓글을 남길 수 있어요';

  @override
  String get guestPromptDescription => '이메일과 닉네임만 있으면 됩니다.';

  @override
  String get postEditTitle => '게시물 수정';

  @override
  String get postCreateTitle => '새 게시물';

  @override
  String get postContentLabel => '오늘의 기록';

  @override
  String get postContentHint => '지금 떠오르는 생각을 남겨보세요.';

  @override
  String get postTradeAttached => '판 결과가 함께 올라갑니다';

  @override
  String get postContentRequired => '게시물 내용을 입력하세요.';

  @override
  String get postSaveButton => '저장';

  @override
  String get postSubmitButton => '올리기';

  @override
  String get postCreated => '게시물을 작성했습니다.';

  @override
  String get postUpdated => '게시물을 수정했습니다.';

  @override
  String get postSaveFailed => '게시물을 저장하지 못했습니다.';

  @override
  String get postImagePrepareFailed => '이미지를 준비하지 못했습니다.';

  @override
  String get postDiscardEditTitle => '수정을 취소할까요?';

  @override
  String get postDiscardCreateTitle => '작성 중인 내용을 버릴까요?';

  @override
  String get postDiscardMessage => '입력한 내용은 저장되지 않습니다.';

  @override
  String get postDiscardKeepWriting => '계속 쓰기';

  @override
  String get postDiscardLeave => '나가기';

  @override
  String postImageLimitReached(int count) {
    return '사진은 $count장까지 올릴 수 있습니다';
  }

  @override
  String postAddImages(int count, int max) {
    return '사진 추가 ($count/$max)';
  }

  @override
  String get postRemoveImageTooltip => '사진 삭제';

  @override
  String get postCommentCountTooltip => '댓글';

  @override
  String get postMenuTooltip => '게시물 메뉴';

  @override
  String get postMenuEdit => '수정';

  @override
  String get postMenuReport => '신고';

  @override
  String get postMenuBlockUser => '이 사용자 차단';

  @override
  String get postDeleteConfirmTitle => '게시물을 삭제할까요?';

  @override
  String get postDeleteConfirmMessage => '삭제한 게시물은 되돌릴 수 없습니다.';

  @override
  String get postDeleteSucceeded => '게시물을 삭제했습니다.';

  @override
  String get postDeleteFailed => '게시물을 삭제하지 못했습니다.';

  @override
  String get commentTitle => '댓글';

  @override
  String get commentLoadFailed => '댓글을 불러오지 못했습니다';

  @override
  String get commentEmptyMessage => '첫 댓글을 남겨보세요.';

  @override
  String get commentLoadMoreReplies => '답글 더 보기';

  @override
  String get commentMenuTooltip => '댓글 메뉴';

  @override
  String get commentMenuReport => '신고';

  @override
  String get commentDeletedPlaceholder => '삭제된 댓글입니다';

  @override
  String get commentReply => '답글';

  @override
  String get commentHideReplies => '답글 숨기기';

  @override
  String commentShowReplies(int count) {
    return '답글 $count개 보기';
  }

  @override
  String get commentDeleteConfirmTitle => '댓글을 삭제할까요?';

  @override
  String get commentDeleteConfirmMessage => '삭제한 댓글은 되돌릴 수 없습니다.';

  @override
  String get commentDeleteSucceeded => '댓글을 삭제했습니다.';

  @override
  String get commentDeleteNotAllowed => '삭제할 수 있는 댓글이 아닙니다.';

  @override
  String get commentDeleteFailed => '댓글을 삭제하지 못했습니다.';

  @override
  String commentReplyingTo(String nickname) {
    return '$nickname 님에게 답글';
  }

  @override
  String get commentReplyCancelTooltip => '답글 취소';

  @override
  String get commentInputHint => '댓글 달기';

  @override
  String get commentReplyInputHint => '답글 달기';

  @override
  String get commentSubmitTooltip => '등록';

  @override
  String get commentSignInRequired => '로그인이 필요합니다.';

  @override
  String get commentCreateFailed => '댓글을 남기지 못했습니다.';

  @override
  String get reactionSaveFailed => '감정표현을 남기지 못했습니다.';

  @override
  String get safetyReportSubmitted => '신고가 접수되었습니다';

  @override
  String get safetyBlockConfirmTitle => '이 사용자를 차단할까요?';

  @override
  String get safetyBlockConfirmMessage => '차단하면 이 사용자의 게시물과 댓글이 더 이상 보이지 않습니다.';

  @override
  String get safetyBlockConfirmAction => '차단';

  @override
  String get safetyBlockSucceeded => '차단했습니다.';

  @override
  String get safetyBlockFailed => '차단하지 못했습니다.';

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsProfileEdit => '프로필 편집';

  @override
  String get settingsAccount => '계정 설정';

  @override
  String get settingsTheme => '화면 테마';

  @override
  String get settingsLanguage => '언어';

  @override
  String get settingsBlockedUsers => '차단한 사용자';

  @override
  String get settingsSignOut => '로그아웃';

  @override
  String get settingsSignOutConfirmTitle => '로그아웃할까요?';

  @override
  String get settingsSignOutConfirmMessage => '다시 사용하려면 로그인해야 합니다.';

  @override
  String get themeModeSystem => '시스템 설정';

  @override
  String get themeModeLight => '라이트';

  @override
  String get themeModeDark => '다크';

  @override
  String get languageSystem => '시스템 설정';

  @override
  String get homeTabTrade => '투자';

  @override
  String get homeTabFeed => '홈';

  @override
  String get homeTabChat => '채팅';

  @override
  String get homeTabProfile => '프로필';

  @override
  String get homeTabSettings => '설정';

  @override
  String get chatTitle => '채팅';

  @override
  String get chatLoadFailed => '채팅 목록을 불러오지 못했습니다';

  @override
  String get chatEmptyMessage => '참여 중인 방이 없습니다';

  @override
  String get chatEmptyDescription => '공개방을 찾아 들어가 보세요.';

  @override
  String get chatEmptyAction => '방 탐색하기';

  @override
  String get chatExploreTooltip => '방 탐색';

  @override
  String get chatCreateRoomLabel => '방 만들기';

  @override
  String get chatNoMessagesYet => '아직 대화가 없습니다';

  @override
  String get chatLastMessageImage => '사진';

  @override
  String get chatExploreTitle => '방 탐색';

  @override
  String get chatSearchHint => '방 이름 검색';

  @override
  String get chatExploreEmptyMessage => '공개방이 없습니다';

  @override
  String get chatExploreEmptyDescription => '첫 방을 만들어 보세요.';

  @override
  String get chatExploreNoResult => '검색 결과가 없습니다';

  @override
  String get chatExploreLoadFailed => '방 목록을 불러오지 못했습니다';

  @override
  String get chatJoinTitle => '이 방에서 쓸 이름';

  @override
  String get chatJoinDescription => '방마다 다른 이름을 쓸 수 있습니다.';

  @override
  String get chatJoinNicknameLabel => '방에서 쓸 이름';

  @override
  String get chatJoinAction => '입장';

  @override
  String get chatJoinFailed => '입장하지 못했습니다';

  @override
  String get chatCreateTitle => '방 만들기';

  @override
  String get chatRoomTitleLabel => '방 이름';

  @override
  String get chatRoomDescriptionLabel => '소개 (선택)';

  @override
  String get chatNicknameLabel => '방에서 쓸 이름';

  @override
  String get chatCreateAction => '만들기';

  @override
  String get chatCreateFailed => '방을 만들지 못했습니다';

  @override
  String get chatRoomEmptyMessage => '첫 메시지를 남겨보세요';

  @override
  String get chatRoomLoadFailed => '대화를 불러오지 못했습니다';

  @override
  String get chatComposerHint => '메시지 입력';

  @override
  String get chatSendTooltip => '보내기';

  @override
  String get chatAttachTooltip => '사진 보내기';

  @override
  String get chatRoomMenuTooltip => '방 메뉴';

  @override
  String get chatMenuParticipants => '참여자';

  @override
  String get chatMenuLeave => '방 나가기';

  @override
  String get chatParticipantsTitle => '참여자';

  @override
  String get chatLeaveConfirmTitle => '방에서 나갈까요?';

  @override
  String get chatLeaveConfirmMessage => '나가면 목록에서 사라집니다. 남긴 메시지는 방에 그대로 남습니다.';

  @override
  String get chatLeaveConfirmAction => '나가기';

  @override
  String get chatLeaveFailed => '방에서 나가지 못했습니다';

  @override
  String get chatMessageDelete => '삭제';

  @override
  String get chatMessageReport => '신고';

  @override
  String get chatDeleteConfirmTitle => '메시지를 삭제할까요?';

  @override
  String get chatDeleteConfirmMessage => '삭제한 메시지는 되돌릴 수 없습니다.';

  @override
  String get chatSendFailed => '메시지를 보내지 못했습니다';

  @override
  String get chatSendFailedShort => '전송 실패';

  @override
  String get chatSending => '보내는 중';

  @override
  String get chatRetry => '다시 보내기';

  @override
  String get chatImageLoadFailed => '사진을 불러오지 못했습니다';

  @override
  String get chatImagePrepareFailed => '사진을 준비하지 못했습니다.';

  @override
  String chatSystemJoined(String nickname) {
    return '$nickname 님이 들어왔습니다';
  }

  @override
  String chatSystemLeft(String nickname) {
    return '$nickname 님이 나갔습니다';
  }

  @override
  String chatMemberCount(int count) {
    return '$count명';
  }

  @override
  String chatMemberLimitValue(int count) {
    return '정원 $count명';
  }

  @override
  String get commonSave => '저장';

  @override
  String get profileTitle => '프로필';

  @override
  String get profileUserTitle => '사용자 프로필';

  @override
  String get profileMenuTooltip => '프로필 메뉴';

  @override
  String get profileMenuUnblock => '차단 해제';

  @override
  String get profileLoadFailed => '프로필을 불러오지 못했습니다';

  @override
  String get profileBioEmpty => '자기소개를 작성해보세요';

  @override
  String profileCompletionTitle(int percent) {
    return '프로필 완성 $percent%';
  }

  @override
  String get profileCompletionNickname => '닉네임 정하기';

  @override
  String get profileCompletionAvatar => '프로필 사진 올리기';

  @override
  String get profileCompletionBio => '자기소개 쓰기';

  @override
  String get profileCompletionFirstPost => '첫 게시물 남기기';

  @override
  String get profileCompletionFirstFollow => '마음에 드는 사람 팔로우하기';

  @override
  String get profileEditAction => '프로필 편집';

  @override
  String get profileMessageButton => '메시지';

  @override
  String get profilePostsTitle => '게시물';

  @override
  String get profilePostsReload => '게시물을 다시 불러오기';

  @override
  String get profilePostsEmpty => '아직 게시물이 없습니다';

  @override
  String get profileNicknameChecking => '확인 중…';

  @override
  String get profileNicknameAvailable => '사용할 수 있는 닉네임입니다';

  @override
  String get profileNicknameTaken => '이미 사용 중인 닉네임입니다';

  @override
  String get profileNicknameLabel => '닉네임';

  @override
  String get profileAvatarPickFailed => '프로필 사진을 불러오지 못했습니다.';

  @override
  String get profileEditTitle => '프로필 편집';

  @override
  String get profileSetupTitle => '프로필 꾸미기';

  @override
  String get profileSetupDescription =>
      '사진과 한 줄 소개로 이웃에게 나를 알려보세요. 나중에 설정에서 바꿀 수 있습니다.';

  @override
  String get profileSetupSkip => '나중에';

  @override
  String get profileSetupContinue => '계속';

  @override
  String get profileSaveFailed => '프로필을 저장하지 못했습니다';

  @override
  String get profileSaveSucceeded => '프로필을 저장했습니다';

  @override
  String get profileChoosePhoto => '사진 선택';

  @override
  String get profileBioLabel => '자기소개';

  @override
  String get safetyUnblockAction => '차단 해제';

  @override
  String get safetyUnblockSucceeded => '차단을 해제했습니다.';

  @override
  String get safetyUnblockFailed => '차단을 해제하지 못했습니다.';

  @override
  String get safetyReportTitle => '신고';

  @override
  String get safetyReportFailed => '신고를 접수하지 못했습니다';

  @override
  String get safetyReportDetailLabel => '상세 설명 (선택)';

  @override
  String get safetyReportDetailHint => '무엇이 문제인지 적어주세요';

  @override
  String get safetyReportAction => '신고하기';

  @override
  String get safetyReportReasonSpam => '스팸 또는 광고';

  @override
  String get safetyReportReasonAbuse => '욕설 또는 혐오 표현';

  @override
  String get safetyReportReasonSexual => '음란물 또는 선정적인 내용';

  @override
  String get safetyReportReasonViolence => '폭력 또는 위협';

  @override
  String get safetyReportReasonOther => '기타';

  @override
  String get safetyBlockedUsersTitle => '차단한 사용자';

  @override
  String get safetyBlockedUsersLoadFailed => '차단 목록을 불러오지 못했습니다';

  @override
  String get safetyBlockedUsersEmpty => '차단한 사용자가 없습니다';

  @override
  String get accountSettingsTitle => '계정 설정';

  @override
  String get accountPasswordChange => '비밀번호 변경';

  @override
  String get accountDelete => '회원 탈퇴';

  @override
  String get accountDeleteSubtitle => '계정과 모든 기록이 즉시 삭제됩니다';

  @override
  String get accountDeleteFailed => '탈퇴하지 못했습니다. 다시 시도해 주세요.';

  @override
  String get accountDeleteConfirmTitle => '정말 탈퇴할까요?';

  @override
  String get accountDeleteConfirmMessage =>
      '계정과 함께 아래가 모두 삭제되며 되돌릴 수 없습니다.\n\n· 프로필과 프로필 사진\n· 작성한 게시물과 사진\n· 남긴 댓글과 감정표현';

  @override
  String accountDeleteConfirmMessageCounted(int postCount, int commentCount) {
    return '계정과 함께 아래가 모두 삭제되며 되돌릴 수 없습니다.\n\n· 프로필과 프로필 사진\n· 작성한 게시물 $postCount개와 사진\n· 남긴 댓글 $commentCount개와 감정표현';
  }

  @override
  String get accountDeleteConfirmAction => '탈퇴';

  @override
  String get passwordChangeTitle => '비밀번호 변경';

  @override
  String get passwordChangeSucceeded => '비밀번호를 변경했습니다';

  @override
  String get passwordChangeFailed => '비밀번호를 변경하지 못했습니다';

  @override
  String get passwordChangeNewLabel => '새 비밀번호';

  @override
  String get passwordChangeConfirmLabel => '새 비밀번호 확인';

  @override
  String get passwordChangeAction => '변경';

  @override
  String get validationEmailRequired => '이메일을 입력하세요';

  @override
  String get validationEmailInvalid => '이메일 형식이 올바르지 않습니다';

  @override
  String get validationPasswordRequired => '비밀번호를 입력하세요';

  @override
  String get validationPasswordTooShort => '비밀번호는 8자 이상이어야 합니다';

  @override
  String get validationPasswordConfirmationRequired => '비밀번호를 한 번 더 입력하세요';

  @override
  String get validationPasswordMismatch => '비밀번호가 일치하지 않습니다';

  @override
  String get validationNicknameRequired => '닉네임을 입력하세요';

  @override
  String get validationNicknameTooShort => '닉네임은 2자 이상이어야 합니다';

  @override
  String get validationNicknameTooLong => '닉네임은 20자 이하여야 합니다';

  @override
  String get validationOtpRequired => '코드를 입력하세요';

  @override
  String get validationOtpInvalid => '6자리 숫자를 입력하세요';

  @override
  String get failureNetwork => '네트워크에 연결할 수 없습니다';

  @override
  String get failureAuth => '인증에 실패했습니다';

  @override
  String get failureForbidden => '권한이 없습니다';

  @override
  String get failureNotFound => '대상을 찾을 수 없습니다';

  @override
  String get failureValidation => '입력값을 확인하세요';

  @override
  String get failureServer => '서버 오류가 발생했습니다';

  @override
  String get failureUnknown => '알 수 없는 오류가 발생했습니다';

  @override
  String get failureInvalidCredentials => '이메일 또는 비밀번호가 올바르지 않습니다';

  @override
  String get failureSignInFailed => '로그인에 실패했습니다';

  @override
  String get failureSignUpFailed => '가입에 실패했습니다';

  @override
  String get failureEmailAlreadyRegistered => '이미 가입된 이메일입니다';

  @override
  String get failureWeakPassword => '비밀번호가 너무 단순합니다';

  @override
  String get failureSamePassword => '이전과 다른 비밀번호를 입력하세요';

  @override
  String get failureOtpExpired => '코드가 만료되었습니다. 다시 요청하세요';

  @override
  String get failureRateLimited => '요청이 너무 잦습니다. 잠시 후 다시 시도하세요';

  @override
  String get failureDuplicateValue => '이미 사용 중인 값입니다';

  @override
  String get failureConstraintViolation => '입력값이 조건을 만족하지 않습니다';

  @override
  String get failureReferencedTargetMissing => '참조 대상이 존재하지 않습니다';

  @override
  String get failureForbiddenOrDeleted => '권한이 없거나 삭제된 대상입니다';

  @override
  String get failureNicknameLength => '닉네임은 2자 이상 20자 이하여야 합니다';

  @override
  String get failureBioTooLong => '자기소개는 200자 이하여야 합니다';

  @override
  String get failurePostContentLength => '게시물은 1자 이상 500자 이하여야 합니다';

  @override
  String get failureCommentContentLength => '댓글은 1자 이상 300자 이하여야 합니다';

  @override
  String get failureUnsupportedReaction => '지원하지 않는 감정표현입니다';

  @override
  String get failureReportAlreadySubmitted => '이미 신고한 항목입니다';

  @override
  String get failureReportDetailTooLong => '상세 설명은 500자 이하여야 합니다';

  @override
  String get failureReportSelfNotAllowed => '자기 자신은 신고할 수 없습니다';

  @override
  String get failureBlockSelfNotAllowed => '자기 자신은 차단할 수 없습니다';

  @override
  String get failureBlockAlreadyExists => '이미 차단한 사용자입니다';

  @override
  String get failureNestedReplyNotAllowed => '답글에는 답글을 달 수 없습니다';

  @override
  String get failureReplyToDeletedCommentNotAllowed => '삭제된 댓글에는 답글을 달 수 없습니다';

  @override
  String get failureReplyParentPostMismatch => '부모 댓글이 다른 게시물의 댓글입니다';

  @override
  String get failureReplyParentMissing => '부모 댓글이 없습니다';

  @override
  String get failureReportTargetMissing => '신고할 대상이 없습니다';

  @override
  String get failureReportOwnPostNotAllowed => '내 게시물은 신고할 수 없습니다';

  @override
  String get failureReportOwnCommentNotAllowed => '내 댓글은 신고할 수 없습니다';

  @override
  String get failureCommentNotAllowed => '이 게시물에는 댓글을 달 수 없습니다';

  @override
  String get failureAuthenticationRequired => '로그인이 필요합니다';

  @override
  String get failureOperationInProgress => '이미 처리 중입니다';

  @override
  String get failureCommentsRangeInvalid => '올바른 댓글 조회 범위가 아닙니다';

  @override
  String get failureCommentCursorInvalid => '잘못된 댓글 커서입니다';

  @override
  String get failureCommentContentRequired => '댓글 내용을 입력해 주세요';

  @override
  String get failureCommentTooLong => '댓글은 300자까지 쓸 수 있습니다';

  @override
  String get failureCommentDeleteTargetMissing => '삭제할 댓글을 찾을 수 없습니다';

  @override
  String get failureRoomTitleRequired => '방 이름을 입력하세요';

  @override
  String get failureRoomTitleTooLong => '방 이름은 30자 이하여야 합니다';

  @override
  String get failureRoomDescriptionTooLong => '소개는 200자 이하여야 합니다';

  @override
  String get failureRoomMemberLimitInvalid => '정원은 2명 이상 500명 이하여야 합니다';

  @override
  String get failureRoomNicknameTooShort => '방에서 쓸 이름은 2자 이상이어야 합니다';

  @override
  String get failureRoomNicknameTooLong => '방에서 쓸 이름은 20자 이하여야 합니다';

  @override
  String get failureMessageContentRequired => '보낼 내용을 입력하세요';

  @override
  String get failureMessageTooLong => '메시지는 1000자 이하여야 합니다';

  @override
  String get failureFeedRangeInvalid => '올바른 피드 조회 범위가 아닙니다';

  @override
  String get failureFeedCursorInvalid => '잘못된 피드 커서입니다';

  @override
  String get failureFeedNotLoaded => '목록을 먼저 읽어야 합니다';

  @override
  String get failurePostNotFound => '게시물을 찾을 수 없습니다';

  @override
  String get failureMessageCursorInvalid => '잘못된 메시지 커서입니다';

  @override
  String get failureRoomCursorInvalid => '잘못된 방 커서입니다';

  @override
  String get failurePostIdRequired => '게시물 식별자가 필요합니다';

  @override
  String get failurePostContentRequired => '게시물 내용을 입력하세요';

  @override
  String get failurePostTooLong => '게시물은 500자 이하여야 합니다';

  @override
  String get failurePostImageLimit => '사진은 5장까지 첨부할 수 있습니다';

  @override
  String get failureAvatarUploadFailed => '프로필 사진을 업로드하지 못했습니다.';

  @override
  String get failureInvalidData => '올바르지 않은 데이터를 받았습니다';

  @override
  String get reactionLike => '좋아요';

  @override
  String get reactionDislike => '싫어요';

  @override
  String avatarSemanticsLabel(String nickname) {
    return '$nickname 프로필 사진';
  }

  @override
  String get feedTabAll => '전체';

  @override
  String get feedTabFollowing => '팔로잉';

  @override
  String get feedFollowingEmptyMessage => '팔로우한 사람이 없습니다';

  @override
  String get feedFollowingEmptyDescription => '마음에 드는 사람을 팔로우하면 여기에 글이 모입니다.';

  @override
  String get feedFollowingEmptyAction => '사람 둘러보기';

  @override
  String get followAction => '팔로우';

  @override
  String get followFollowingAction => '팔로잉';

  @override
  String get followMutualAction => '맞팔로우';

  @override
  String get followFailed => '팔로우하지 못했습니다';

  @override
  String get followUnfollowFailed => '팔로우를 해제하지 못했습니다';

  @override
  String get followFollowersLabel => '팔로워';

  @override
  String get followFollowingsLabel => '팔로잉';

  @override
  String get followFollowersTitle => '팔로워';

  @override
  String get followFollowingsTitle => '팔로잉';

  @override
  String get followFollowersEmpty => '아직 팔로워가 없습니다';

  @override
  String get followFollowingsEmpty => '아직 팔로우한 사람이 없습니다';

  @override
  String get followListLoadFailed => '목록을 불러오지 못했습니다';

  @override
  String get failureFollowUserIdRequired => '사용자 식별자가 필요합니다';

  @override
  String get failureFollowRangeInvalid => '올바른 팔로우 조회 범위가 아닙니다';

  @override
  String get failureFollowCursorInvalid => '잘못된 팔로우 커서입니다';

  @override
  String get failureFollowBlocked => '지금은 팔로우할 수 없습니다';

  @override
  String get failureRoomFull => '정원이 가득 찬 방입니다';

  @override
  String get failureRoomNotFound => '없는 방입니다';

  @override
  String get failureDirectChatNotAllowed => '대화를 시작할 수 없습니다';

  @override
  String get failureDirectChatSelfNotAllowed => '자기 자신과는 대화할 수 없습니다';

  @override
  String get failureChatSendNotAllowed => '메시지를 보낼 수 없습니다';

  @override
  String get failureReportOwnMessageNotAllowed => '내 메시지는 신고할 수 없습니다';

  @override
  String get failureTradeSessionAlreadyActive => '진행 중인 판이 있습니다';

  @override
  String get failureTradeSessionNotFound => '판을 찾을 수 없습니다';

  @override
  String get failureTradeSessionFinished => '이미 끝난 판입니다';

  @override
  String get failureTradeInsufficientCash => '잔고가 부족합니다';

  @override
  String get failureTradeInsufficientQuantity => '보유 수량이 부족합니다';

  @override
  String get failureTradeQuantityInvalid => '수량은 0보다 커야 합니다';

  @override
  String get failureTradeSessionNotShareable => '끝난 판만 공유할 수 있습니다';

  @override
  String get failureCommuteNotConfigured => '집과 회사 역을 먼저 설정해 주세요';

  @override
  String get failureLocationPermissionDenied => '위치 권한을 사용할 수 없습니다';

  @override
  String get failureLocationServiceDisabled => '위치 서비스가 꺼져 있습니다';

  @override
  String get failureLocationTimeout => '현재 위치를 가져오지 못했습니다';

  @override
  String get failureRouteSearchFailed => '통근 경로를 찾지 못했습니다';

  @override
  String get tradeHomeTitle => '모의투자';

  @override
  String get tradeStart => '새 판 시작';

  @override
  String get tradeResume => '이어하기';

  @override
  String tradeStepOf(int step, int total) {
    return '$step / $total';
  }

  @override
  String get tradeEquity => '평가액';

  @override
  String get tradePastSessions => '지난 판';

  @override
  String get tradeEmptyTitle => '아직 해본 판이 없습니다';

  @override
  String get tradeEmptyDescription => '과거 시세를 하루씩 넘기며 매매해 보세요';

  @override
  String get tradeResultTitle => '결과';

  @override
  String get tradeReturn => '수익률';

  @override
  String get tradeBuyHold => '보유만 했을 때';

  @override
  String get tradeMaxDrawdown => '최대낙폭';

  @override
  String get tradeCount => '매매 횟수';

  @override
  String tradeCountValue(int count) {
    return '$count회';
  }

  @override
  String tradeBeatBuyHold(String diff) {
    return '보유보다 $diff 나았습니다';
  }

  @override
  String tradeLostToBuyHold(String diff) {
    return '보유보다 $diff 못했습니다';
  }

  @override
  String get tradeResultNotReady => '아직 끝나지 않은 판입니다';

  @override
  String get tradeShare => '공유하기';

  @override
  String tradeCardBuyHold(String pct) {
    return '보유만 했을 때 $pct';
  }

  @override
  String tradeCardMaxDrawdown(String pct) {
    return '최대낙폭 $pct';
  }

  @override
  String tradeCardCount(int count) {
    return '매매 $count회';
  }

  @override
  String get tradeSessionTitle => '모의투자';

  @override
  String get tradeFinishNow => '청산하고 끝내기';

  @override
  String get tradeFinishConfirmTitle => '지금 끝낼까요?';

  @override
  String get tradeFinishConfirmMessage =>
      '보유 수량을 현재가로 모두 팔고 결과를 봅니다. 되돌릴 수 없습니다.';

  @override
  String get tradeCash => '현금';

  @override
  String get tradeQuantity => '보유 수량';

  @override
  String get tradeCurrentReturn => '현재 수익률';

  @override
  String get tradeCurrentPrice => '현재가';

  @override
  String tradeChartSemantics(
    int visibleCount,
    int totalCount,
    String currentPrice,
  ) {
    return '총 $totalCount개 봉 중 $visibleCount개 공개, 현재가 $currentPrice';
  }

  @override
  String tradeChartEmptySemantics(int totalCount) {
    return '아직 공개된 봉이 없습니다. 전체 $totalCount개';
  }

  @override
  String get tradeBuy => '매수';

  @override
  String get tradeSell => '매도';

  @override
  String get tradeNextDay => '다음 날';

  @override
  String get tradeByAmount => '금액';

  @override
  String get tradeByQuantity => '수량';

  @override
  String get tradeExpectedQuantity => '예상 수량';

  @override
  String get tradeExpectedProceeds => '예상 수령액';

  @override
  String get tradeFee => '수수료';

  @override
  String get tradeRemainingCash => '주문 후 현금';

  @override
  String get tradeRemainingQuantity => '주문 후 보유 수량';

  @override
  String get tradeConfirmOrder => '주문하기';

  @override
  String get tradeInvalidNumber => '올바른 숫자를 입력해 주세요';

  @override
  String get tradeQuantityMustBePositive => '0보다 큰 값을 입력해 주세요';

  @override
  String get tradeOrderPlaced => '주문이 체결됐습니다';

  @override
  String tradeFractionLabel(int pct) {
    return '$pct%';
  }

  @override
  String get commuteSettingsTitle => '통근 설정';

  @override
  String get commuteSettingsDescription => '집과 회사에서 가까운 역을 선택하세요';

  @override
  String get commuteHomeStation => '집 역';

  @override
  String get commuteWorkStation => '회사 역';

  @override
  String get commuteStationNotSet => '역을 선택해 주세요';

  @override
  String get commuteStationSearchTitle => '역 검색';

  @override
  String get commuteStationSearchHint => '역 이름을 입력하세요';

  @override
  String get commuteStationSearchPrompt => '역 이름을 검색해 주세요';

  @override
  String get commuteStationSearchEmpty => '검색 결과가 없습니다';

  @override
  String get commuteAppTitle => '통근 시간';

  @override
  String get commuteDirectionToWork => '출근';

  @override
  String get commuteDirectionToHome => '퇴근';

  @override
  String get commuteCurrentLocationOrigin => '현 위치 기준';

  @override
  String get commuteHomeFallbackOrigin => '집 기준 · 위치를 못 가져왔어요';

  @override
  String get commuteWorkFallbackOrigin => '회사 기준 · 위치를 못 가져왔어요';

  @override
  String get commuteModeSubway => '지하철';

  @override
  String get commuteModeBus => '버스';

  @override
  String get commuteModeBest => '최적';

  @override
  String commuteDurationMinutes(int minutes) {
    return '$minutes분';
  }

  @override
  String commuteTransferCount(int count) {
    return '환승 $count회';
  }

  @override
  String get commuteSettingsRequiredTitle => '통근 역 설정이 필요해요';

  @override
  String get commuteSettingsRequiredDescription => '집과 회사 역을 먼저 선택해 주세요';

  @override
  String get commuteOpenSettings => '설정하기';

  @override
  String get commuteOpenSettingsTooltip => '통근 설정';

  @override
  String get failureWalkDogRequired => '함께 산책한 반려견을 선택해 주세요';

  @override
  String get failureWalkTrackingAlreadyActive => '이미 진행 중인 산책이 있습니다';

  @override
  String get failureWalkNotFound => '산책 기록을 찾을 수 없습니다';

  @override
  String get failureWalkPhotoSaveFailed => '사진을 저장하지 못했습니다';

  @override
  String get failureDogNameRequired => '반려견 이름을 입력해 주세요';

  @override
  String get walkAppTitle => 'pawlog';
}
