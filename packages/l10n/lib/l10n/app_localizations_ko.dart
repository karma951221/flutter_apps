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
  String get failureLocationStreamFailed => '위치를 받아 오지 못하고 있습니다';

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
  String get walkAppTitle => 'Life Tool';

  @override
  String get walkToday => '오늘';

  @override
  String walkStepsCount(String steps) {
    return '$steps 걸음';
  }

  @override
  String walkGoalOf(String goal) {
    return '목표 $goal';
  }

  @override
  String walkGoalRemaining(String steps) {
    return '목표까지 $steps';
  }

  @override
  String walkGoalRemainingWithDistance(String steps, String distance) {
    return '목표까지 $steps · 약 $distance';
  }

  @override
  String walkGoalExceeded(String steps) {
    return '목표보다 $steps 더 걸었어요';
  }

  @override
  String get walkGoalReached => '달성';

  @override
  String walkGoalDaysReached(int reached, int total) {
    return '달성 $reached/$total일';
  }

  @override
  String walkGoalOfPercent(int percent) {
    return '목표 $percent%';
  }

  @override
  String walkGoalRingSemantics(String steps, String goal, int percent) {
    return '오늘 $steps, 목표 $goal의 $percent%';
  }

  @override
  String get walkGoalLine => '목표';

  @override
  String get walkSettingsWalk => '걷기';

  @override
  String get walkSettingsStepGoal => '하루 목표';

  @override
  String get walkSettingsStepGoalSave => '저장';

  @override
  String get walkTabWeek => '주간';

  @override
  String get walkTabMonth => '월간';

  @override
  String get walkTotalSteps => '합계';

  @override
  String get walkAverageSteps => '일평균';

  @override
  String get walkDistance => '거리';

  @override
  String get walkActiveCalories => '활동 칼로리';

  @override
  String get walkPreviousPeriod => '이전';

  @override
  String get walkNextPeriod => '다음';

  @override
  String get walkHealthConnectMissing => 'Health Connect 가 필요해요';

  @override
  String get walkHealthConnectMissingDescription =>
      '폰의 헬스 앱이 기록한 걸음을 Health Connect 에서 읽어요';

  @override
  String get walkInstall => '설치하기';

  @override
  String get walkHealthConnectUpdate => 'Health Connect 를 업데이트해 주세요';

  @override
  String get walkUpdate => '업데이트하기';

  @override
  String get walkPermissionNeeded => '걸음 기록을 읽을 권한이 필요해요';

  @override
  String get walkPermissionDescription =>
      '걸음 · 거리 · 활동 칼로리를 읽기만 하고 저장하거나 보내지 않아요';

  @override
  String get walkGrantPermission => '권한 허용';

  @override
  String get walkOpenSettings => '설정 열기';

  @override
  String get walkLoadFailed => '기록을 불러오지 못했어요';

  @override
  String get walkAlarmDefaultTitle => '알람';

  @override
  String get walkAlarmStop => '알람 끄기';

  @override
  String walkAlarmSnooze(int minutes) {
    return '$minutes분 뒤 다시 울림';
  }

  @override
  String get walkReminderSoonTitle => '곧 알람이 울려요';

  @override
  String walkReminderSoonBody(String time, String label) {
    return '$time $label';
  }

  @override
  String get walkReminderTurnOffOnce => '이번만 끄기';

  @override
  String get walkReminderHolidayTitle => '공휴일에 울리는 알람';

  @override
  String walkReminderHolidayBody(String date, String name, String time) {
    return '$date($name) $time 알람이 공휴일에 울려요';
  }

  @override
  String walkReminderHolidayBodyNoName(String date, String time) {
    return '$date $time 알람이 공휴일에 울려요';
  }

  @override
  String get walkReminderSkip => '다음 알람 건너뛰기';

  @override
  String get walkReminderRing => '울리기';

  @override
  String get walkAlarmRingSettings => '울림 설정';

  @override
  String walkAlarmRingSummary(int volume, String snooze, String autoStop) {
    return '볼륨 $volume% · 스누즈 $snooze · 자동 멈춤 $autoStop';
  }

  @override
  String get walkAlarmAutoStopNone => '없음';

  @override
  String get walkAlarmVolume => '볼륨';

  @override
  String walkAlarmPercent(int percent) {
    return '$percent%';
  }

  @override
  String get walkAlarmFade => '점점 커지기';

  @override
  String get walkAlarmFadeOff => '끔';

  @override
  String walkAlarmSeconds(int seconds) {
    return '$seconds초';
  }

  @override
  String get walkAlarmSnoozeInterval => '스누즈 간격';

  @override
  String get walkAlarmSnoozeLimit => '스누즈 횟수';

  @override
  String get walkAlarmSnoozeUnlimited => '무제한';

  @override
  String walkAlarmTimes(int count) {
    return '$count회';
  }

  @override
  String get walkAlarmAutoStop => '자동 멈춤';

  @override
  String get walkAlarmAutoStopNever => '안 함';

  @override
  String walkAlarmMinutes(int minutes) {
    return '$minutes분';
  }

  @override
  String get walkAlarmRemindBefore => '30분 전에 알려 주기';

  @override
  String get walkAlarmRemindBeforeHint => '알림에서 이번만 끌 수 있어요';

  @override
  String get walkAlarmSkipNext => '다음 알람 건너뛰기';

  @override
  String get walkAlarmUnskip => '건너뛰기 취소';

  @override
  String get walkAlarmSkipped => '건너뜀';

  @override
  String get walkAlarmHolidayChip => '공휴일';

  @override
  String get walkSettingsAlarm => '알람';

  @override
  String get walkSettingsHolidayReminder => '공휴일 미리 알림';

  @override
  String get walkSettingsHolidayReminderDescription =>
      '반복 알람이 공휴일에 울리면 하루 전에 알려요';

  @override
  String get walkSettingsHolidaySource => '공휴일 출처';

  @override
  String walkSettingsHolidaySourceDevice(String name) {
    return '폰 캘린더: $name';
  }

  @override
  String get walkSettingsHolidaySourceDeviceUnnamed => '폰 캘린더';

  @override
  String walkSettingsHolidaySourceBundled(String firstYear, String lastYear) {
    return '내장 표 $firstYear–$lastYear';
  }

  @override
  String get walkSettingsCalendarGranted => '캘린더 허용됨';

  @override
  String get walkSettingsCalendarNeedsPermission => '캘린더 허용 필요 ›';

  @override
  String get walkShellTabAlarm => '알람';

  @override
  String get walkShellTabWalk => '걷기';

  @override
  String get walkShellTabSettings => '설정';

  @override
  String get walkShellTabDiary => '일기';

  @override
  String get walkDiaryDailyStoryTitle => '일상';

  @override
  String get walkDiaryAll => '전체';

  @override
  String get walkDiarySeeAll => '모두 보기';

  @override
  String get walkDiaryAllStories => '모든 스토리';

  @override
  String get walkDiaryPastStories => '지난 스토리';

  @override
  String get walkDiaryPlayFromStart => '처음부터 보기';

  @override
  String get walkDiaryPlay => '▶ 보기';

  @override
  String walkDiaryStoryStats(int entries, int photos) {
    return '기록 $entries · 사진 $photos';
  }

  @override
  String get walkDiaryArchive => '보관함';

  @override
  String get walkDiaryEmpty => '아직 기록이 없어요';

  @override
  String get walkDiaryToday => '오늘';

  @override
  String get walkDiaryYesterday => '어제';

  @override
  String get walkDiaryNow => '지금';

  @override
  String get walkDiaryOngoing => '진행 중';

  @override
  String walkDiaryStoryPeriod(String start, String end) {
    return '$start ~ $end';
  }

  @override
  String get walkDiaryViewProse => '줄글';

  @override
  String get walkDiaryViewFeed => '피드';

  @override
  String get walkDiaryViewReels => '릴스';

  @override
  String get walkDiaryShowMore => '더 보기';

  @override
  String walkDiaryPlace(String name) {
    return '📍 $name';
  }

  @override
  String walkDiaryTag(String name) {
    return '#$name';
  }

  @override
  String walkDiaryMediaPosition(int index, int count) {
    return '$index/$count';
  }

  @override
  String get walkDiaryLoadError => '기록을 불러오지 못했어요';

  @override
  String get walkAlarmListTitle => '알람';

  @override
  String get walkAlarmEmpty => '알람이 없어요';

  @override
  String get walkAlarmEmptyDescription => '+ 를 눌러 기상 알람을 추가하세요';

  @override
  String get walkAlarmAdd => '알람 추가';

  @override
  String get walkAlarmNextTitle => '다음 알람';

  @override
  String walkAlarmIn(String duration) {
    return '$duration 뒤';
  }

  @override
  String get walkAlarmNoneEnabled => '켜진 알람이 없어요';

  @override
  String get walkAlarmNoneScheduled => '예약된 알람이 없어요';

  @override
  String get walkAlarmNoneScheduledHint => '권한을 확인하세요';

  @override
  String get walkAlarmLoadFailed => '알람을 불러오지 못했어요';

  @override
  String get walkAlarmDayToday => '오늘';

  @override
  String get walkAlarmDayTomorrow => '내일';

  @override
  String walkAlarmRingsIn(String duration) {
    return '$duration 뒤에 울려요';
  }

  @override
  String get walkAlarmSavedPausedOut => '쉬는 기간이라 울리지 않아요';

  @override
  String get walkAlarmPausedOutRow => '쉬는 중';

  @override
  String walkAlarmDurationMinutes(int minutes) {
    return '$minutes분';
  }

  @override
  String walkAlarmDurationHours(int hours) {
    return '$hours시간';
  }

  @override
  String walkAlarmDurationHoursMinutes(int hours, int minutes) {
    return '$hours시간 $minutes분';
  }

  @override
  String walkAlarmDurationDays(int days) {
    return '$days일';
  }

  @override
  String walkAlarmDurationDaysHours(int days, int hours) {
    return '$days일 $hours시간';
  }

  @override
  String get walkAlarmPermissionWarning => '알람이 울리지 않을 수 있어요';

  @override
  String get walkAlarmPermissionWarningAction => '설정 탭에서 권한을 확인하세요';

  @override
  String get walkAlarmRepeatDaily => '매일';

  @override
  String get walkAlarmRepeatWeekdays => '평일';

  @override
  String get walkAlarmRepeatWeekends => '주말';

  @override
  String get walkAlarmRepeatOnce => '1회';

  @override
  String get walkAlarmEdit => '알람 수정';

  @override
  String get walkAlarmSound => '알람음';

  @override
  String get walkAlarmSoundSystem => '시스템 기본';

  @override
  String get walkAlarmSoundBundledSection => '앱 소리';

  @override
  String get walkAlarmSoundDeviceSection => '기기 알람음';

  @override
  String get walkAlarmSoundBeep => '비프';

  @override
  String get walkAlarmSoundChime => '차임';

  @override
  String get walkAlarmSoundRising => '점점 빠르게';

  @override
  String get walkAlarmSoundSelect => '선택';

  @override
  String get walkAlarmSoundDeviceUnavailable => '기기 알람음을 불러오지 못했어요';

  @override
  String get walkAlarmSoundImportFailed => '이 알람음을 쓸 수 없어요';

  @override
  String get walkAlarmDeleteTitle => '알람을 삭제할까요?';

  @override
  String get walkAlarmDeleteContent => '삭제한 알람은 되돌릴 수 없어요';

  @override
  String get walkAlarmDuplicate => '복제';

  @override
  String get walkAlarmPause => '알람 쉬기';

  @override
  String get walkAlarmPauseDescription => '고른 기간에는 모든 알람이 울리지 않아요. 스위치는 그대로예요.';

  @override
  String get walkAlarmPauseToday => '오늘만';

  @override
  String get walkAlarmPauseUntilTomorrow => '내일까지';

  @override
  String get walkAlarmPauseWeekend => '이번 주말';

  @override
  String get walkAlarmPausePickDates => '날짜 고르기';

  @override
  String walkAlarmPausedUntil(String until) {
    return '$until까지 알람을 쉬어요';
  }

  @override
  String walkAlarmPausedRange(String from, String until) {
    return '$from부터 $until까지 알람을 쉬어요';
  }

  @override
  String get walkAlarmPauseStop => '그만 쉬기';

  @override
  String get walkAlarmHistory => '울림 기록';

  @override
  String get walkAlarmHistoryEmpty => '아직 기록이 없어요';

  @override
  String get walkAlarmHistoryEmptyHint => '알람이 울리고 꺼지면 여기에 30일 동안 남아요';

  @override
  String get walkAlarmHistoryLoadFailed => '기록을 불러오지 못했어요';

  @override
  String walkAlarmHistoryRang(String time) {
    return '$time 울림';
  }

  @override
  String walkAlarmHistorySnoozes(int count) {
    return '스누즈 $count번';
  }

  @override
  String walkAlarmHistoryStopped(String time) {
    return '$time 끔';
  }

  @override
  String walkAlarmHistoryAutoStopped(String time) {
    return '$time 자동 멈춤';
  }

  @override
  String get walkAlarmHistoryDeleted => '지운 알람';

  @override
  String get walkAlarmSaveFailed => '알람을 저장하지 못했어요';

  @override
  String get walkAlarmKindTitle => '어떤 알람을 만들까요';

  @override
  String get walkAlarmKindOneShot => '한 번';

  @override
  String get walkAlarmKindOneShotHint => '지금부터 얼마 뒤에 울려요';

  @override
  String get walkAlarmKindRepeat => '반복';

  @override
  String get walkAlarmKindRepeatHint => '정한 요일마다 울려요';

  @override
  String get walkAlarmNewOneShot => '한 번 알람';

  @override
  String get walkAlarmNewRepeat => '반복 알람';

  @override
  String walkAlarmAfter(String duration) {
    return '$duration 뒤';
  }

  @override
  String walkAlarmRingsAtChip(String time) {
    return '$time에 울림';
  }

  @override
  String walkAlarmWheelHourSemantics(int hour) {
    return '$hour시';
  }

  @override
  String walkAlarmAddHour(int hours) {
    return '+$hours시간';
  }

  @override
  String walkAlarmAddMinutes(int minutes) {
    return '+$minutes분';
  }

  @override
  String get walkAlarmReset => '초기화';

  @override
  String get walkAlarmNeedTime => '시간을 더해 주세요';

  @override
  String get walkAlarmNeedDays => '요일을 골라 주세요';

  @override
  String get walkAlarmPickTimeConfirm => '이 시각으로';

  @override
  String get walkAlarmPresetEveryday => '매일';

  @override
  String get walkAlarmPresetWeekdays => '평일';

  @override
  String get walkAlarmPresetWeekend => '주말';

  @override
  String get walkAlarmTitle => '제목';

  @override
  String get walkAlarmTitleHint => '예: 출근';

  @override
  String get walkAlarmSilentWhenMuted => '무음 · 진동 모드에선 진동만';

  @override
  String get walkAlarmSilentWhenMutedHint => '폰이 무음이나 진동 모드면 소리 없이 진동으로 울려요';

  @override
  String walkAlarmOneShotRow(String remaining) {
    return '한 번 · $remaining';
  }

  @override
  String get walkSettingsTitle => '설정';

  @override
  String get walkSettingsPermissions => '권한';

  @override
  String get walkSettingsNotification => '알림';

  @override
  String get walkSettingsNotificationDescription => '알람 알림과 끄기 버튼을 보여줘요';

  @override
  String get walkSettingsExactAlarm => '정확한 알람';

  @override
  String get walkSettingsExactAlarmDescription => '정한 시각에 정확히 울려요';

  @override
  String get walkSettingsFullScreen => '전체 화면 알림';

  @override
  String get walkSettingsFullScreenDescription => '잠금 화면에서 알람 화면을 띄워요';

  @override
  String get walkSettingsHealthConnect => 'Health Connect';

  @override
  String get walkSettingsHealthConnectDescription => '걸음 기록을 읽어요';

  @override
  String get walkSettingsGranted => '허용됨';

  @override
  String get walkSettingsNeedsPermission => '허용 필요 ›';

  @override
  String get walkSettingsNeedsInstall => '설치 필요 ›';

  @override
  String get walkSettingsNeedsUpdate => '업데이트 필요 ›';

  @override
  String get walkSettingsTheme => '테마';

  @override
  String get walkSettingsThemeSystem => '시스템 설정';

  @override
  String get walkSettingsThemeLight => '라이트';

  @override
  String get walkSettingsThemeDark => '다크';

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
  String get pawlogAppTitle => 'pawlog';

  @override
  String get walkDogListTitle => '반려견';

  @override
  String get walkDogListEmptyTitle => '등록된 반려견이 없습니다';

  @override
  String get walkDogListEmptyMessage => '함께 산책할 반려견을 등록해 주세요';

  @override
  String get walkDogAddAction => '반려견 추가';

  @override
  String get walkDogNewTitle => '반려견 등록';

  @override
  String get walkDogEditTitle => '반려견 수정';

  @override
  String get walkDogNameLabel => '이름';

  @override
  String get walkDogBreedLabel => '품종';

  @override
  String get walkDogBirthdayLabel => '생일';

  @override
  String get walkDogBirthdayUnset => '설정 안 함';

  @override
  String get walkDogPhotoChange => '사진 변경';

  @override
  String get walkDogSaveAction => '저장';

  @override
  String get walkDogDeleteAction => '삭제';

  @override
  String get walkDogDeleteConfirmTitle => '반려견을 삭제할까요?';

  @override
  String get walkDogDeleteConfirmMessage => '산책 기록은 남고, 기록에서 이 반려견만 빠집니다.';

  @override
  String get walkActiveTitle => '산책 중';

  @override
  String get walkReadyTitle => '산책 준비';

  @override
  String get walkSelectDogs => '함께 걷는 반려견';

  @override
  String get walkStart => '산책 시작';

  @override
  String get walkStop => '산책 종료';

  @override
  String get walkStopConfirmTitle => '산책을 끝낼까요?';

  @override
  String get walkStopConfirmMessage => '기록을 멈추고 저장 화면으로 이동합니다.';

  @override
  String get walkElapsedLabel => '시간';

  @override
  String get walkDistanceLabel => '거리';

  @override
  String walkDistanceMeters(int meters) {
    return '$meters m';
  }

  @override
  String walkDistanceKm(String km) {
    return '$km km';
  }

  @override
  String walkDurationMinutes(int minutes) {
    return '$minutes분';
  }

  @override
  String get walkDurationUnderMinute => '1분 미만';

  @override
  String walkDurationHours(int hours) {
    return '$hours시간';
  }

  @override
  String walkDurationHoursMinutes(int hours, int minutes) {
    return '$hours시간 $minutes분';
  }

  @override
  String get walkTrackingNotificationTitle => '산책을 기록하고 있어요';

  @override
  String get walkTrackingNotificationText => '앱을 닫아도 경로가 계속 기록됩니다';

  @override
  String get walkActiveNoDogsTitle => '먼저 반려견을 등록해 주세요';

  @override
  String get walkActiveNoDogsMessage => '산책에는 반려견이 한 마리 이상 필요합니다';

  @override
  String get walkOpenDogsAction => '반려견 등록하기';

  @override
  String get walkLocationDeniedHint => '설정에서 위치 권한을 허용한 뒤 다시 시도해 주세요';

  @override
  String get walkLocationLostHint => '산책 기록은 이어집니다. 다시 시도하면 위치를 다시 받아요';

  @override
  String get walkLocationServiceHint => '위치 서비스를 켠 뒤 다시 시도해 주세요';

  @override
  String get walkOpenLocationSettings => '위치 설정 열기';

  @override
  String get walkLocating => '위치를 찾는 중…';

  @override
  String get walkEditNewTitle => '산책 저장';

  @override
  String get walkEditTitle => '산책 수정';

  @override
  String get walkMemoLabel => '메모';

  @override
  String get walkMemoHint => '오늘 산책은 어땠나요?';

  @override
  String get walkPhotosLabel => '사진';

  @override
  String get walkAddPhoto => '사진 추가';

  @override
  String get walkRemovePhoto => '사진 삭제';

  @override
  String get walkAddPhotoFromGallery => '앨범에서 고르기';

  @override
  String get walkAddPhotoFromCamera => '카메라로 찍기';

  @override
  String get walkPhotoLimitReached => '사진은 최대 10장까지 붙일 수 있어요';

  @override
  String get walkDiscard => '버리기';

  @override
  String get walkDiscardConfirmTitle => '이 산책을 버릴까요?';

  @override
  String get walkDiscardConfirmMessage => '경로와 붙인 사진이 모두 지워집니다.';

  @override
  String get walkNoSessionToSave => '저장할 산책이 없습니다';

  @override
  String get walkBackToFeed => '피드로 돌아가기';

  @override
  String get walkDetailTitle => '산책 기록';

  @override
  String get walkEdit => '수정';

  @override
  String get walkDeleteConfirmTitle => '산책 기록을 삭제할까요?';

  @override
  String get walkDeleteConfirmMessage => '경로와 사진이 함께 삭제됩니다.';

  @override
  String get walkNoTrack => '기록된 경로가 없습니다';

  @override
  String get walkDogsLabel => '함께한 반려견';

  @override
  String get walkDateLabel => '날짜';

  @override
  String get walkFeedEmptyTitle => '첫 산책을 시작해 보세요';

  @override
  String get walkFeedEmptyMessage => '산책을 마치면 여기에 기록이 쌓입니다';

  @override
  String get walkFeedEmptyActiveTitle => '첫 산책이 곧 여기에 보여요';

  @override
  String get walkFeedEmptyActiveMessage => '위 배너에서 산책을 마치고 저장해 주세요';

  @override
  String get walkContinue => '산책 계속';

  @override
  String get walkInProgressBanner => '산책 중이에요 · 눌러서 돌아가기';

  @override
  String get walkUnsavedBanner => '저장하지 않은 산책이 있어요 · 눌러서 저장하기';

  @override
  String get walkOpenDogsTooltip => '반려견';

  @override
  String get walkLockTitle => '일기가 잠겨 있어요';

  @override
  String get walkLockEnterPin => 'PIN 4자리를 입력하세요';

  @override
  String get walkLockEnterPattern => '패턴을 그리세요';

  @override
  String get walkLockWrong => '맞지 않아요. 다시 해 보세요';

  @override
  String walkLockBlocked(int seconds) {
    return '$seconds초 뒤에 다시 시도할 수 있어요';
  }

  @override
  String walkLockBlockedLong(int hours, int minutes) {
    return '폰 인증에 실패했어요. $hours시간 $minutes분 뒤에 다시 시도할 수 있어요';
  }

  @override
  String get walkLockForgot => '잊어버렸어요';

  @override
  String get walkLockDeviceReason => '일기 잠금을 다시 설정하려면 본인 확인이 필요해요';

  @override
  String get walkLockDeviceUnavailable =>
      '지금은 폰 인증을 쓸 수 없어요. 폰 화면 잠금 설정을 확인해 주세요';

  @override
  String get walkLockPinDelete => '지우기';

  @override
  String get walkLockSetupTitle => '일기 잠금';

  @override
  String get walkLockSetupChoose => '잠금 방식을 고르세요';

  @override
  String get walkLockSetupPin => 'PIN 4자리';

  @override
  String get walkLockSetupPattern => '패턴';

  @override
  String walkLockSetupInUse(String method) {
    return '$method (사용 중)';
  }

  @override
  String get walkLockSetupOff => '잠금 끄기';

  @override
  String get walkLockSetupVerify => '지금 쓰는 PIN · 패턴을 입력하세요';

  @override
  String get walkLockSetupNewPin => '새 PIN 4자리를 입력하세요';

  @override
  String get walkLockSetupNewPattern => '점 4개 이상을 이어 새 패턴을 그리세요';

  @override
  String get walkLockSetupConfirm => '확인을 위해 한 번 더 입력하세요';

  @override
  String get walkLockSetupMismatch => '처음 입력과 달라요. 처음부터 다시 입력하세요';

  @override
  String get walkLockSetupTooShort => '점을 4개 이상 이어 주세요';

  @override
  String get walkLockSetupPinInvalid => '숫자 4자리를 입력해 주세요';

  @override
  String get walkLockSetupSaved => '일기 잠금 설정을 저장했어요';

  @override
  String get walkLockNeedsScreenLock => '폰 화면 잠금을 먼저 설정해야 일기 잠금을 켤 수 있어요';

  @override
  String get walkLockOpenScreenLockSettings => '화면 잠금 설정 열기';

  @override
  String get walkDiaryEditorNewTitle => '새 기록';

  @override
  String get walkDiaryEditorEditTitle => '기록 고치기';

  @override
  String get walkDiaryEditorPost => '올리기';

  @override
  String get walkDiaryEditorSave => '저장';

  @override
  String get walkDiaryEditorClose => '닫기';

  @override
  String walkDiaryEditorTimeNow(String when) {
    return '지금 · $when';
  }

  @override
  String walkDiaryEditorDateTime(String date, String time) {
    return '$date $time';
  }

  @override
  String get walkDiaryEditorRevertTime => '올린 시각으로 되돌리기';

  @override
  String get walkDiaryEditorPickTimeConfirm => '확인';

  @override
  String get walkDiaryEditorLocating => '위치를 찾는 중…';

  @override
  String get walkDiaryEditorUnnamedPlace => '이름 없는 위치';

  @override
  String get walkDiaryEditorRemoveLocation => '위치 빼기';

  @override
  String get walkDiaryEditorPlaceHint => '장소 이름';

  @override
  String get walkDiaryWhereToPost => '어디에 올릴까요?';

  @override
  String get walkDiaryTextOnly => '글만 쓰기';

  @override
  String walkDiaryPostedTo(String title) {
    return '$title에 올렸어요';
  }

  @override
  String get walkDiaryEditorPickStory => '스토리 고르기';

  @override
  String get walkDiaryEditorAddMedia => '사진·영상 추가';

  @override
  String get walkDiaryEditorRemoveMedia => '빼기';

  @override
  String get walkDiaryEditorPickGallery => '앨범에서 고르기';

  @override
  String get walkDiaryEditorTakePhoto => '사진 찍기';

  @override
  String get walkDiaryEditorTakeVideo => '영상 찍기';

  @override
  String get walkDiaryEditorBodyHint => '오늘 있었던 일을 적어 보세요';

  @override
  String get walkDiaryEditorTagHint => '태그 추가';

  @override
  String get walkDiaryEditorDiscardTitle => '작성을 그만둘까요?';

  @override
  String get walkDiaryEditorDiscardContent => '쓴 내용은 저장되지 않아요.';

  @override
  String get walkDiaryEditorDiscardConfirm => '그만두기';

  @override
  String get walkDiaryErrorEmptyEntry => '글이나 사진·영상을 넣어 주세요';

  @override
  String get walkDiaryErrorFutureTime => '앞으로의 시각으로는 쓸 수 없어요';

  @override
  String walkDiaryErrorTooManyMedia(int max) {
    return '사진·영상은 $max개까지 넣을 수 있어요';
  }

  @override
  String walkDiaryErrorVideoTooLong(int seconds) {
    return '$seconds초 이하 영상만 넣을 수 있어요';
  }

  @override
  String get walkDiaryErrorStoryClosed => '닫힌 스토리에는 쓸 수 없어요';

  @override
  String get walkDiaryErrorNotFound => '기록을 찾을 수 없어요';

  @override
  String get walkDiaryErrorMediaProcessing => '사진·영상을 불러오지 못했어요';

  @override
  String get walkDiaryErrorSave => '저장하지 못했어요. 다시 시도해 주세요';

  @override
  String walkDiaryEditorTagSuggestion(String name, int count) {
    return '#$name $count';
  }

  @override
  String walkDiaryEditorPlaceSuggestion(String name, int count) {
    return '$name $count';
  }

  @override
  String get walkDiaryMenuStories => '스토리 관리';

  @override
  String get walkDiaryStoryNew => '새 스토리';

  @override
  String get walkDiaryStoryRename => '이름 바꾸기';

  @override
  String get walkDiaryStoryCover => '표지 바꾸기';

  @override
  String get walkDiaryStoryClose => '닫기';

  @override
  String get walkDiaryStoryReopen => '다시 열기';

  @override
  String get walkDiaryStoryDelete => '삭제';

  @override
  String walkDiaryStoryDeleteTitle(String title) {
    return '\'$title\' 스토리를 삭제할까요?';
  }

  @override
  String get walkDiaryStoryDeleteContent =>
      '이 스토리의 기록은 휴지통으로 가요. 복원하면 \'일상\'으로 돌아와요.';

  @override
  String get walkDiaryStoryTitleLabel => '제목';

  @override
  String walkDiaryStoryStart(String date) {
    return '시작일 $date';
  }

  @override
  String walkDiaryStoryEnd(String date) {
    return '종료일 $date';
  }

  @override
  String get walkDiaryStoryNoEnd => '종료일 없음 (진행 중)';

  @override
  String get walkDiaryStoryClearEnd => '종료일 지우기';

  @override
  String get walkDiaryStoryCreate => '만들기';

  @override
  String get walkDiaryStorySave => '저장';

  @override
  String get walkDiaryStoryCloseNow => '지금 닫기';

  @override
  String get walkDiaryStoryCloseOnDate => '날짜를 골라 닫기';

  @override
  String get walkDiaryStoryCoverAuto => '자동 (가장 최근 사진)';

  @override
  String get walkDiaryStoryCoverEmpty => '이 스토리에는 아직 사진이 없어요';

  @override
  String get walkDiaryStoryMoveTitle => '이 기간의 \'일상\' 기록을 옮길까요?';

  @override
  String walkDiaryStoryMoveConfirm(int count) {
    return '$count개 옮기기';
  }

  @override
  String get walkDiaryStoryMoveSkip => '건너뛰기';

  @override
  String walkDiaryStoryMoved(int count) {
    return '기록 $count개를 옮겼어요';
  }

  @override
  String get walkDiaryErrorEndBeforeStart => '종료일이 시작일보다 빠를 수 없어요';

  @override
  String get walkDiaryErrorDefaultStoryLocked => '기본 스토리는 닫거나 지울 수 없어요';

  @override
  String get walkDiaryEntryEdit => '수정';

  @override
  String get walkDiaryEntryDelete => '삭제';

  @override
  String get walkDiaryEntryDeleteTitle => '기록을 삭제할까요?';

  @override
  String get walkDiaryEntryDeleteContent => '휴지통으로 옮겨요. 휴지통에서 복원할 수 있어요.';

  @override
  String get walkDiaryEntryTrashed => '기록을 휴지통으로 옮겼어요';

  @override
  String get walkDiaryEntryTrashFailed => '휴지통으로 옮기지 못했어요. 다시 시도해 주세요';

  @override
  String get walkDiaryEntryTrash => '휴지통으로';

  @override
  String get walkDiaryEntryMove => '스토리 옮기기';

  @override
  String walkDiaryEntryMoved(String story) {
    return '$story 스토리로 옮겼어요';
  }

  @override
  String get walkDiaryEntryMoveFailed => '옮기지 못했어요. 다시 시도해 주세요';

  @override
  String get walkDiaryUndo => '되돌리기';

  @override
  String walkDiaryDayNumber(int n) {
    return '$n일차';
  }

  @override
  String get walkDiaryViewerClose => '닫기';

  @override
  String walkDiaryEntryDateTime(String date, String time) {
    return '$date $time';
  }

  @override
  String get walkDiarySearch => '검색';

  @override
  String get walkDiarySearchHint => '일기 검색';

  @override
  String get walkDiarySearchTabBody => '글';

  @override
  String get walkDiarySearchTabStory => '스토리';

  @override
  String get walkDiarySearchTabTag => '해시태그';

  @override
  String get walkDiarySearchTabPlace => '장소';

  @override
  String get walkDiarySearchBodyPrompt => '글에서 찾을 말을 입력해 보세요';

  @override
  String get walkDiarySearchStoryPrompt => '찾을 스토리 이름을 입력해 보세요';

  @override
  String get walkDiarySearchNoResults => '찾는 결과가 없어요';

  @override
  String walkDiaryEntryCount(int count) {
    return '기록 $count개';
  }

  @override
  String get walkDiaryCollectionEmpty => '모아 볼 기록이 없어요';

  @override
  String get walkDiaryMenuTrash => '휴지통';

  @override
  String get walkDiaryTrashEmpty => '휴지통이 비어 있어요';

  @override
  String walkDiaryTrashDaysLeft(int days) {
    return '$days일 남음';
  }

  @override
  String get walkDiaryTrashDueToday => '오늘 삭제돼요';

  @override
  String get walkDiaryTrashNoBody => '(글 없는 기록)';

  @override
  String get walkDiaryTrashRestore => '복원';

  @override
  String get walkDiaryTrashDeleteForever => '영구 삭제';

  @override
  String get walkDiaryTrashEmptyAll => '휴지통 비우기';

  @override
  String get walkDiaryTrashPurgeTitle => '영구 삭제할까요?';

  @override
  String get walkDiaryTrashPurgeContent => '되돌릴 수 없어요. 사진과 영상도 함께 지워져요.';

  @override
  String get walkDiaryTrashEmptyAllTitle => '휴지통을 비울까요?';

  @override
  String walkDiaryTrashEmptyAllContent(int count) {
    return '기록 $count개가 영구 삭제돼요. 되돌릴 수 없어요.';
  }

  @override
  String get walkDiaryTrashRestored => '기록을 복원했어요';

  @override
  String get walkDiaryTrashPurged => '기록을 영구 삭제했어요';

  @override
  String get walkDiaryTrashEmptied => '휴지통을 비웠어요';

  @override
  String get walkDiaryTrashRestoreFailed => '복원하지 못했어요. 다시 시도해 주세요';

  @override
  String get walkDiaryTrashDeleteFailed => '삭제하지 못했어요. 다시 시도해 주세요';

  @override
  String get walkDiarySettings => '일기';

  @override
  String get walkDiarySettingsLock => '일기 잠금';

  @override
  String get walkDiarySettingsLockOff => '꺼짐';

  @override
  String get walkDiarySettingsRelock => '다시 잠기는 시간';

  @override
  String get walkDiarySettingsRelockImmediate => '바로';

  @override
  String get walkDiarySettingsRelock30s => '30초 뒤';

  @override
  String get walkDiarySettingsRelock1m => '1분 뒤';

  @override
  String get walkDiarySettingsRelock5m => '5분 뒤';

  @override
  String get walkDiarySettingsRetention => '휴지통 보관 기간';

  @override
  String get walkDiarySettingsRetention1d => '1일';

  @override
  String get walkDiarySettingsRetention7d => '7일';

  @override
  String get walkDiarySettingsRetention30d => '30일';

  @override
  String get walkDiarySettingsRetentionNever => '지우지 않음';

  @override
  String get walkDiarySettingsStorage => '저장 공간';

  @override
  String walkDiarySettingsStorageUsage(String size) {
    return '사용 중 $size';
  }

  @override
  String walkDiarySettingsStorageDetail(int photos, int videos, String trash) {
    return '사진 $photos장 · 영상 $videos개, 휴지통 $trash 포함';
  }

  @override
  String get walkDiarySettingsLocalOnly => '기록은 이 폰에만 저장돼요. 앱을 지우면 함께 사라져요.';

  @override
  String get walkStatsTitle => '산책 통계';

  @override
  String get walkStatsWeek => '주';

  @override
  String get walkStatsMonth => '월';

  @override
  String get walkStatsPreviousTooltip => '이전 기간';

  @override
  String get walkStatsNextTooltip => '다음 기간';

  @override
  String get walkStatsDistanceLabel => '걸은 거리';

  @override
  String get walkStatsDurationLabel => '걸은 시간';

  @override
  String get walkStatsCountLabel => '산책';

  @override
  String walkStatsCountValue(int count) {
    return '$count번';
  }

  @override
  String walkStatsMoreThanLastWeek(String distance) {
    return '지난주보다 $distance 더 걸었어요';
  }

  @override
  String walkStatsLastWeek(String distance) {
    return '지난주 $distance';
  }

  @override
  String walkStatsMoreThanLastMonth(String distance) {
    return '지난달보다 $distance 더 걸었어요';
  }

  @override
  String walkStatsLastMonth(String distance) {
    return '지난달 $distance';
  }

  @override
  String walkStatsBarSemantics(String label, String distance) {
    return '$label $distance';
  }

  @override
  String get walkStatsRecordsTitle => '기록';

  @override
  String get walkStatsCurrentStreak => '연속 산책';

  @override
  String get walkStatsLongestStreak => '최장 연속';

  @override
  String walkStatsDays(int count) {
    return '$count일';
  }

  @override
  String get walkStatsFarthestWalk => '가장 먼 산책';

  @override
  String get walkStatsLongestWalk => '가장 오래 걸은 산책';

  @override
  String get walkStatsEmptyTitle => '아직 통계가 없어요';

  @override
  String get walkStatsEmptyMessage => '산책을 기록하면 여기에 쌓여요';

  @override
  String walkFeedWeekSummary(String distance, int count) {
    return '이번 주 $distance · $count번';
  }

  @override
  String get walkFeedWeekSummaryEmpty => '이번 주는 아직 산책 전이에요';

  @override
  String get walkPause => '일시정지';

  @override
  String get walkUnpause => '계속 걷기';

  @override
  String get walkPausedLabel => '일시정지 중';

  @override
  String get walkPausedBanner => '산책을 잠시 멈췄어요';

  @override
  String get walkExportGpx => 'GPX로 내보내기';

  @override
  String get walkExportNoRoute => '경로가 없어 내보낼 수 없어요';

  @override
  String get walkExportFailed => '내보내지 못했어요';

  @override
  String get walkBackupExport => '백업 내보내기';

  @override
  String get walkBackupImport => '백업 가져오기';

  @override
  String get walkBackupImportFromFirstRun => '백업에서 가져오기';

  @override
  String get walkBackupExportFailed => '백업을 만들지 못했어요';

  @override
  String walkBackupImported(int dogs, int walks) {
    return '반려견 $dogs마리 · 산책 $walks개를 가져왔어요';
  }

  @override
  String get walkBackupNothingNew => '새로 가져올 기록이 없어요';

  @override
  String get walkBackupInvalid => '백업 파일을 읽지 못했어요';

  @override
  String get walkBackupImportFailed => '가져오지 못했어요';

  @override
  String get walkFeedMoreTooltip => '더보기';

  @override
  String get walkFavoriteAdd => '즐겨찾기에 추가';

  @override
  String get walkFavoriteRemove => '즐겨찾기에서 빼기';

  @override
  String get walkFeedShowFavorites => '즐겨찾기만 보기';

  @override
  String get walkFeedShowAll => '모든 산책 보기';

  @override
  String get walkFeedFavoritesEmptyTitle => '즐겨찾기한 산책이 없어요';

  @override
  String get walkFeedFavoritesEmptyMessage => '산책 상세에서 별을 눌러 보세요';

  @override
  String get walkFavoriteLabel => '즐겨찾기';

  @override
  String get walkSocialTitle => '모두의 산책';

  @override
  String get walkSocialSignIn => '로그인';

  @override
  String get walkSocialSignUp => '가입하기';

  @override
  String get walkSocialSignOut => '로그아웃';

  @override
  String get walkSocialEmail => '이메일';

  @override
  String get walkSocialPassword => '비밀번호';

  @override
  String get walkSocialNickname => '닉네임';

  @override
  String get walkSocialSwitchToSignUp => '처음이면 가입하기';

  @override
  String get walkSocialSwitchToSignIn => '이미 계정이 있으면 로그인';

  @override
  String get walkSocialSignInRequired => '로그인하면 공유하고 좋아요를 누를 수 있어요';

  @override
  String get walkSocialAuthFailed => '로그인하지 못했어요. 이메일과 비밀번호를 확인해 주세요';

  @override
  String get walkSocialNicknameTaken => '이미 쓰는 닉네임이에요';

  @override
  String get walkSocialEmpty => '아직 공유된 산책이 없어요';

  @override
  String get walkSocialOpenTooltip => '모두의 산책';

  @override
  String get walkSocialLoadFailed => '모두의 산책을 불러오지 못했어요';

  @override
  String get walkSocialShare => '모두에게 공유';

  @override
  String get walkSocialUnshare => '공유 취소';

  @override
  String get walkSocialShared => '공유했어요';

  @override
  String get walkSocialUnshared => '공유를 취소했어요';

  @override
  String get walkSocialShareFailed => '공유하지 못했어요';

  @override
  String get walkSocialLikeTooltip => '좋아요';

  @override
  String get walkSocialUnshareOnDeleteFailed => '산책은 지웠지만 공유를 취소하지 못했어요';

  @override
  String get walkSocialUpdateFailed => '기록은 고쳤지만 공유한 글은 바꾸지 못했어요';

  @override
  String walkDiaryMinutesAgo(int minutes) {
    return '$minutes분 전';
  }

  @override
  String walkDiaryHoursAgo(int hours) {
    return '$hours시간 전';
  }
}
