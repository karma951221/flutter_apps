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
    return '$email 으로 보낸 6자리 코드를 입력하세요.';
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
  String get postEditTitle => '게시물 수정';

  @override
  String get postCreateTitle => '새 게시물';

  @override
  String get postContentLabel => '오늘의 기록';

  @override
  String get postContentHint => '지금 떠오르는 생각을 남겨보세요.';

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
  String get reactionSaveFailed => '감정을 남기지 못했습니다.';

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
}
