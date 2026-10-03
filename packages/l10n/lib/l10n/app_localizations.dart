import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
  ];

  /// 다이얼로그의 취소 버튼
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get commonCancel;

  /// 삭제 확인 다이얼로그·메뉴의 삭제 버튼
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get commonDelete;

  /// 오류 화면의 재시도 버튼
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get commonRetry;

  /// AppOverflowMenu 의 기본 툴팁
  ///
  /// In ko, this message translates to:
  /// **'더보기'**
  String get commonMoreActions;

  /// 로그인 화면 헤더 설명
  ///
  /// In ko, this message translates to:
  /// **'오늘 하루를 기록하고 이웃과 나눠보세요.'**
  String get authSignInDescription;

  /// 이메일 입력 필드 라벨
  ///
  /// In ko, this message translates to:
  /// **'이메일'**
  String get authEmailLabel;

  /// 비밀번호 입력 필드 라벨 (로그인)
  ///
  /// In ko, this message translates to:
  /// **'비밀번호'**
  String get authPasswordLabel;

  /// 로그인 화면 제출 버튼
  ///
  /// In ko, this message translates to:
  /// **'로그인'**
  String get authSignIn;

  /// 비밀번호 재설정으로 가는 텍스트 버튼
  ///
  /// In ko, this message translates to:
  /// **'비밀번호를 잊으셨나요?'**
  String get authForgotPassword;

  /// 회원가입 유도 안내 문구
  ///
  /// In ko, this message translates to:
  /// **'아직 계정이 없으신가요?'**
  String get authNoAccountPrompt;

  /// 회원가입 화면 제목이자 로그인 화면의 회원가입 버튼
  ///
  /// In ko, this message translates to:
  /// **'회원가입'**
  String get authSignUp;

  /// 로그인 화면 맨 아래. 가입 없이 전체 피드를 읽기 전용으로 본다
  ///
  /// In ko, this message translates to:
  /// **'먼저 둘러보기'**
  String get authBrowseFirst;

  /// 회원가입 화면 헤더 설명
  ///
  /// In ko, this message translates to:
  /// **'이메일과 닉네임만 있으면 바로 시작할 수 있습니다.'**
  String get authSignUpDescription;

  /// 회원가입 닉네임 입력 필드 라벨
  ///
  /// In ko, this message translates to:
  /// **'닉네임 (2~20자)'**
  String get authNicknameLabel;

  /// 회원가입 비밀번호 입력 필드 라벨
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 (8자 이상)'**
  String get authPasswordWithRuleLabel;

  /// 회원가입 비밀번호 확인 입력 필드 라벨
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 확인'**
  String get authPasswordConfirmLabel;

  /// 회원가입 화면 제출 버튼
  ///
  /// In ko, this message translates to:
  /// **'가입하기'**
  String get authSignUpSubmit;

  /// 비밀번호 재설정 1단계 헤더 제목
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 재설정'**
  String get authPasswordResetTitle;

  /// 비밀번호 재설정 1단계 헤더 설명
  ///
  /// In ko, this message translates to:
  /// **'가입한 이메일로 6자리 코드를 보내드립니다.'**
  String get authPasswordResetDescription;

  /// 비밀번호 재설정 1단계 제출 버튼
  ///
  /// In ko, this message translates to:
  /// **'코드 받기'**
  String get authPasswordResetSendCode;

  /// 비밀번호 재설정 2단계 헤더 제목
  ///
  /// In ko, this message translates to:
  /// **'코드 입력'**
  String get authPasswordResetCodeTitle;

  /// 비밀번호 재설정 2단계 헤더 설명
  ///
  /// In ko, this message translates to:
  /// **'{email} 주소로 보낸 6자리 코드를 입력하세요.'**
  String authPasswordResetCodeDescription(String email);

  /// 비밀번호 재설정 2단계 코드 입력 필드 라벨
  ///
  /// In ko, this message translates to:
  /// **'인증 코드'**
  String get authPasswordResetCodeLabel;

  /// 비밀번호 재설정 2단계 제출 버튼
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get authPasswordResetVerify;

  /// 비밀번호 재설정 2단계에서 1단계로 되돌아가는 버튼
  ///
  /// In ko, this message translates to:
  /// **'이메일 다시 입력'**
  String get authPasswordResetChangeEmail;

  /// 비밀번호 재설정 3단계 헤더 제목
  ///
  /// In ko, this message translates to:
  /// **'새 비밀번호'**
  String get authNewPasswordTitle;

  /// 비밀번호 재설정 3단계 헤더 설명
  ///
  /// In ko, this message translates to:
  /// **'앞으로 사용할 비밀번호를 입력하세요.'**
  String get authNewPasswordDescription;

  /// 비밀번호 재설정 3단계 새 비밀번호 입력 필드 라벨
  ///
  /// In ko, this message translates to:
  /// **'새 비밀번호 (8자 이상)'**
  String get authNewPasswordLabel;

  /// 비밀번호 재설정 3단계 새 비밀번호 확인 입력 필드 라벨
  ///
  /// In ko, this message translates to:
  /// **'새 비밀번호 확인'**
  String get authNewPasswordConfirmLabel;

  /// 비밀번호 재설정 3단계 제출 버튼
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 변경'**
  String get authPasswordChangeSubmit;

  /// 비밀번호 재설정 완료 화면 제목
  ///
  /// In ko, this message translates to:
  /// **'비밀번호가 변경되었습니다.'**
  String get authPasswordChangedTitle;

  /// 비밀번호 재설정 완료 화면 설명
  ///
  /// In ko, this message translates to:
  /// **'새 비밀번호로 다시 로그인하세요.'**
  String get authPasswordChangedDescription;

  /// 비밀번호 재설정 완료 화면에서 로그인으로 돌아가는 버튼
  ///
  /// In ko, this message translates to:
  /// **'로그인하러 가기'**
  String get authGoToSignIn;

  /// 비밀번호 보기 토글 tooltip — 지금은 가려져 있다
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 표시'**
  String get authPasswordShow;

  /// 비밀번호 보기 토글 tooltip — 지금은 보이는 상태다
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 숨기기'**
  String get authPasswordHide;

  /// 피드 조회 실패 안내 (서버 문구가 없을 때)
  ///
  /// In ko, this message translates to:
  /// **'피드를 불러오지 못했습니다'**
  String get feedLoadFailed;

  /// 피드 조회 실패 보조 설명
  ///
  /// In ko, this message translates to:
  /// **'연결을 확인하고 다시 시도해 주세요.'**
  String get feedLoadFailedDescription;

  /// 피드 작성 FAB tooltip
  ///
  /// In ko, this message translates to:
  /// **'새 게시물 작성'**
  String get feedComposeTooltip;

  /// 피드 작성 FAB 라벨
  ///
  /// In ko, this message translates to:
  /// **'작성'**
  String get feedComposeLabel;

  /// 피드가 비었을 때 안내
  ///
  /// In ko, this message translates to:
  /// **'아직 게시물이 없습니다'**
  String get feedEmptyMessage;

  /// 피드가 비었을 때 보조 설명
  ///
  /// In ko, this message translates to:
  /// **'첫 게시물을 남겨보세요.'**
  String get feedEmptyDescription;

  /// 피드가 비었을 때 작성 버튼
  ///
  /// In ko, this message translates to:
  /// **'첫 게시물 쓰기'**
  String get feedEmptyAction;

  /// 목록 끝 꼬리표
  ///
  /// In ko, this message translates to:
  /// **'모두 확인했습니다'**
  String get feedEndOfList;

  /// 비로그인 읽기 전용 피드의 AppBar 제목
  ///
  /// In ko, this message translates to:
  /// **'둘러보기'**
  String get guestFeedTitle;

  /// 게스트가 반응·댓글·게시물을 누를 때 뜨는 시트 제목
  ///
  /// In ko, this message translates to:
  /// **'가입하면 반응과 댓글을 남길 수 있어요'**
  String get guestPromptTitle;

  /// 게스트 안내 시트의 한 줄 설명. 가입 버튼과 로그인 버튼이 아래에 온다
  ///
  /// In ko, this message translates to:
  /// **'이메일과 닉네임만 있으면 됩니다.'**
  String get guestPromptDescription;

  /// 게시물 편집 화면 AppBar 제목 (수정)
  ///
  /// In ko, this message translates to:
  /// **'게시물 수정'**
  String get postEditTitle;

  /// 게시물 편집 화면 AppBar 제목 (작성)
  ///
  /// In ko, this message translates to:
  /// **'새 게시물'**
  String get postCreateTitle;

  /// 게시물 본문 입력 라벨
  ///
  /// In ko, this message translates to:
  /// **'오늘의 기록'**
  String get postContentLabel;

  /// 게시물 본문 입력 힌트
  ///
  /// In ko, this message translates to:
  /// **'지금 떠오르는 생각을 남겨보세요.'**
  String get postContentHint;

  /// 작성 화면 — 판 결과 카드가 이 게시물에 붙는다는 안내
  ///
  /// In ko, this message translates to:
  /// **'판 결과가 함께 올라갑니다'**
  String get postTradeAttached;

  /// 본문이 비었을 때 폼 검증 문구
  ///
  /// In ko, this message translates to:
  /// **'게시물 내용을 입력하세요.'**
  String get postContentRequired;

  /// 게시물 편집 제출 버튼 (수정)
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get postSaveButton;

  /// 게시물 편집 제출 버튼 (작성)
  ///
  /// In ko, this message translates to:
  /// **'올리기'**
  String get postSubmitButton;

  /// 게시물 작성 성공 스낵바
  ///
  /// In ko, this message translates to:
  /// **'게시물을 작성했습니다.'**
  String get postCreated;

  /// 게시물 수정 성공 스낵바
  ///
  /// In ko, this message translates to:
  /// **'게시물을 수정했습니다.'**
  String get postUpdated;

  /// 게시물 저장 실패 스낵바
  ///
  /// In ko, this message translates to:
  /// **'게시물을 저장하지 못했습니다.'**
  String get postSaveFailed;

  /// 이미지 선택 실패 스낵바
  ///
  /// In ko, this message translates to:
  /// **'이미지를 준비하지 못했습니다.'**
  String get postImagePrepareFailed;

  /// 수정 중 이탈 확인 다이얼로그 제목
  ///
  /// In ko, this message translates to:
  /// **'수정을 취소할까요?'**
  String get postDiscardEditTitle;

  /// 작성 중 이탈 확인 다이얼로그 제목
  ///
  /// In ko, this message translates to:
  /// **'작성 중인 내용을 버릴까요?'**
  String get postDiscardCreateTitle;

  /// 이탈 확인 다이얼로그 본문
  ///
  /// In ko, this message translates to:
  /// **'입력한 내용은 저장되지 않습니다.'**
  String get postDiscardMessage;

  /// 이탈 확인 다이얼로그 — 머무르기
  ///
  /// In ko, this message translates to:
  /// **'계속 쓰기'**
  String get postDiscardKeepWriting;

  /// 이탈 확인 다이얼로그 — 나가기
  ///
  /// In ko, this message translates to:
  /// **'나가기'**
  String get postDiscardLeave;

  /// 사진 첨부 최대 장수에 닿았을 때 버튼 라벨
  ///
  /// In ko, this message translates to:
  /// **'사진은 {count}장까지 올릴 수 있습니다'**
  String postImageLimitReached(int count);

  /// 사진 첨부 버튼 라벨
  ///
  /// In ko, this message translates to:
  /// **'사진 추가 ({count}/{max})'**
  String postAddImages(int count, int max);

  /// 첨부한 사진 제거 버튼 tooltip
  ///
  /// In ko, this message translates to:
  /// **'사진 삭제'**
  String get postRemoveImageTooltip;

  /// 게시물 타일의 댓글 수 버튼 tooltip
  ///
  /// In ko, this message translates to:
  /// **'댓글'**
  String get postCommentCountTooltip;

  /// 게시물 타일 overflow 메뉴 tooltip
  ///
  /// In ko, this message translates to:
  /// **'게시물 메뉴'**
  String get postMenuTooltip;

  /// 게시물 메뉴 — 수정
  ///
  /// In ko, this message translates to:
  /// **'수정'**
  String get postMenuEdit;

  /// 게시물 메뉴 — 신고
  ///
  /// In ko, this message translates to:
  /// **'신고'**
  String get postMenuReport;

  /// 게시물 메뉴 — 작성자 차단
  ///
  /// In ko, this message translates to:
  /// **'이 사용자 차단'**
  String get postMenuBlockUser;

  /// 게시물 삭제 확인 다이얼로그 제목
  ///
  /// In ko, this message translates to:
  /// **'게시물을 삭제할까요?'**
  String get postDeleteConfirmTitle;

  /// 게시물 삭제 확인 다이얼로그 본문
  ///
  /// In ko, this message translates to:
  /// **'삭제한 게시물은 되돌릴 수 없습니다.'**
  String get postDeleteConfirmMessage;

  /// 게시물 삭제 성공 스낵바
  ///
  /// In ko, this message translates to:
  /// **'게시물을 삭제했습니다.'**
  String get postDeleteSucceeded;

  /// 게시물 삭제 실패 스낵바
  ///
  /// In ko, this message translates to:
  /// **'게시물을 삭제하지 못했습니다.'**
  String get postDeleteFailed;

  /// 댓글 화면 AppBar 제목
  ///
  /// In ko, this message translates to:
  /// **'댓글'**
  String get commentTitle;

  /// 댓글 조회 실패 안내 (서버 문구가 없을 때)
  ///
  /// In ko, this message translates to:
  /// **'댓글을 불러오지 못했습니다'**
  String get commentLoadFailed;

  /// 댓글이 하나도 없을 때 안내
  ///
  /// In ko, this message translates to:
  /// **'첫 댓글을 남겨보세요.'**
  String get commentEmptyMessage;

  /// 답글 다음 페이지 버튼
  ///
  /// In ko, this message translates to:
  /// **'답글 더 보기'**
  String get commentLoadMoreReplies;

  /// 댓글 타일 overflow 메뉴 tooltip
  ///
  /// In ko, this message translates to:
  /// **'댓글 메뉴'**
  String get commentMenuTooltip;

  /// 댓글 메뉴 — 신고
  ///
  /// In ko, this message translates to:
  /// **'신고'**
  String get commentMenuReport;

  /// 삭제된 댓글 자리에 남는 문구
  ///
  /// In ko, this message translates to:
  /// **'삭제된 댓글입니다'**
  String get commentDeletedPlaceholder;

  /// 댓글에 답글을 달기 시작하는 버튼
  ///
  /// In ko, this message translates to:
  /// **'답글'**
  String get commentReply;

  /// 펼친 답글을 접는 버튼
  ///
  /// In ko, this message translates to:
  /// **'답글 숨기기'**
  String get commentHideReplies;

  /// 답글을 펼치는 버튼
  ///
  /// In ko, this message translates to:
  /// **'답글 {count}개 보기'**
  String commentShowReplies(int count);

  /// 댓글 삭제 확인 다이얼로그 제목
  ///
  /// In ko, this message translates to:
  /// **'댓글을 삭제할까요?'**
  String get commentDeleteConfirmTitle;

  /// 댓글 삭제 확인 다이얼로그 본문
  ///
  /// In ko, this message translates to:
  /// **'삭제한 댓글은 되돌릴 수 없습니다.'**
  String get commentDeleteConfirmMessage;

  /// 댓글 삭제 성공 스낵바
  ///
  /// In ko, this message translates to:
  /// **'댓글을 삭제했습니다.'**
  String get commentDeleteSucceeded;

  /// 삭제 대상이 아닌 댓글에 대한 스낵바
  ///
  /// In ko, this message translates to:
  /// **'삭제할 수 있는 댓글이 아닙니다.'**
  String get commentDeleteNotAllowed;

  /// 댓글 삭제 실패 스낵바
  ///
  /// In ko, this message translates to:
  /// **'댓글을 삭제하지 못했습니다.'**
  String get commentDeleteFailed;

  /// 입력 줄 위에 뜨는 답글 대상 표시
  ///
  /// In ko, this message translates to:
  /// **'{nickname} 님에게 답글'**
  String commentReplyingTo(String nickname);

  /// 답글 대상 해제 버튼 tooltip
  ///
  /// In ko, this message translates to:
  /// **'답글 취소'**
  String get commentReplyCancelTooltip;

  /// 댓글 입력 힌트
  ///
  /// In ko, this message translates to:
  /// **'댓글 달기'**
  String get commentInputHint;

  /// 답글 입력 힌트
  ///
  /// In ko, this message translates to:
  /// **'답글 달기'**
  String get commentReplyInputHint;

  /// 댓글 전송 버튼 tooltip
  ///
  /// In ko, this message translates to:
  /// **'등록'**
  String get commentSubmitTooltip;

  /// 세션 없이 댓글을 쓰려 할 때 스낵바
  ///
  /// In ko, this message translates to:
  /// **'로그인이 필요합니다.'**
  String get commentSignInRequired;

  /// 댓글 작성 실패 스낵바
  ///
  /// In ko, this message translates to:
  /// **'댓글을 남기지 못했습니다.'**
  String get commentCreateFailed;

  /// 감정 토글 실패 스낵바 (피드·댓글 공용)
  ///
  /// In ko, this message translates to:
  /// **'감정표현을 남기지 못했습니다.'**
  String get reactionSaveFailed;

  /// 신고 접수 성공 스낵바
  ///
  /// In ko, this message translates to:
  /// **'신고가 접수되었습니다'**
  String get safetyReportSubmitted;

  /// 차단 확인 다이얼로그 제목
  ///
  /// In ko, this message translates to:
  /// **'이 사용자를 차단할까요?'**
  String get safetyBlockConfirmTitle;

  /// 차단 확인 다이얼로그 본문
  ///
  /// In ko, this message translates to:
  /// **'차단하면 이 사용자의 게시물과 댓글이 더 이상 보이지 않습니다.'**
  String get safetyBlockConfirmMessage;

  /// 차단 확인 다이얼로그 실행 버튼
  ///
  /// In ko, this message translates to:
  /// **'차단'**
  String get safetyBlockConfirmAction;

  /// 차단 성공 스낵바
  ///
  /// In ko, this message translates to:
  /// **'차단했습니다.'**
  String get safetyBlockSucceeded;

  /// 차단 실패 스낵바
  ///
  /// In ko, this message translates to:
  /// **'차단하지 못했습니다.'**
  String get safetyBlockFailed;

  /// 설정 화면 AppBar 제목
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get settingsTitle;

  /// 설정 목록 — 프로필 편집 화면으로 가는 행
  ///
  /// In ko, this message translates to:
  /// **'프로필 편집'**
  String get settingsProfileEdit;

  /// 설정 목록 — 계정 설정 화면으로 가는 행
  ///
  /// In ko, this message translates to:
  /// **'계정 설정'**
  String get settingsAccount;

  /// 설정 목록의 화면 테마 행이자 선택 다이얼로그 제목
  ///
  /// In ko, this message translates to:
  /// **'화면 테마'**
  String get settingsTheme;

  /// 설정 목록의 언어 행이자 선택 다이얼로그 제목
  ///
  /// In ko, this message translates to:
  /// **'언어'**
  String get settingsLanguage;

  /// 설정 목록 — 차단 목록 화면으로 가는 행
  ///
  /// In ko, this message translates to:
  /// **'차단한 사용자'**
  String get settingsBlockedUsers;

  /// 설정 목록의 로그아웃 행이자 확인 다이얼로그의 실행 버튼
  ///
  /// In ko, this message translates to:
  /// **'로그아웃'**
  String get settingsSignOut;

  /// 로그아웃 확인 다이얼로그 제목
  ///
  /// In ko, this message translates to:
  /// **'로그아웃할까요?'**
  String get settingsSignOutConfirmTitle;

  /// 로그아웃 확인 다이얼로그 본문
  ///
  /// In ko, this message translates to:
  /// **'다시 사용하려면 로그인해야 합니다.'**
  String get settingsSignOutConfirmMessage;

  /// 화면 테마 — 기기 설정을 따른다
  ///
  /// In ko, this message translates to:
  /// **'시스템 설정'**
  String get themeModeSystem;

  /// 화면 테마 — 밝은 테마
  ///
  /// In ko, this message translates to:
  /// **'라이트'**
  String get themeModeLight;

  /// 화면 테마 — 어두운 테마
  ///
  /// In ko, this message translates to:
  /// **'다크'**
  String get themeModeDark;

  /// 앱 언어 — 기기 언어를 따른다. 다른 언어 이름은 자기 표기로 고정이라 번역하지 않는다
  ///
  /// In ko, this message translates to:
  /// **'시스템 설정'**
  String get languageSystem;

  /// 홈 하단 탭 라벨 — 모의투자 탭
  ///
  /// In ko, this message translates to:
  /// **'투자'**
  String get homeTabTrade;

  /// 하단 탭 — 피드
  ///
  /// In ko, this message translates to:
  /// **'홈'**
  String get homeTabFeed;

  /// 하단 탭 — 채팅
  ///
  /// In ko, this message translates to:
  /// **'채팅'**
  String get homeTabChat;

  /// 하단 탭 — 프로필
  ///
  /// In ko, this message translates to:
  /// **'프로필'**
  String get homeTabProfile;

  /// 하단 탭 — 설정
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get homeTabSettings;

  /// 채팅 탭 제목
  ///
  /// In ko, this message translates to:
  /// **'채팅'**
  String get chatTitle;

  /// 내 방 목록 조회 실패
  ///
  /// In ko, this message translates to:
  /// **'채팅 목록을 불러오지 못했습니다'**
  String get chatLoadFailed;

  /// 내 방 목록 빈 상태
  ///
  /// In ko, this message translates to:
  /// **'참여 중인 방이 없습니다'**
  String get chatEmptyMessage;

  /// 내 방 목록 빈 상태 보조 설명
  ///
  /// In ko, this message translates to:
  /// **'공개방을 찾아 들어가 보세요.'**
  String get chatEmptyDescription;

  /// 내 방 목록 빈 상태의 행동 버튼
  ///
  /// In ko, this message translates to:
  /// **'방 탐색하기'**
  String get chatEmptyAction;

  /// 채팅 탭 AppBar 의 탐색 버튼
  ///
  /// In ko, this message translates to:
  /// **'방 탐색'**
  String get chatExploreTooltip;

  /// 채팅 탭의 FAB
  ///
  /// In ko, this message translates to:
  /// **'방 만들기'**
  String get chatCreateRoomLabel;

  /// 목록 미리보기 — 메시지가 하나도 없는 방
  ///
  /// In ko, this message translates to:
  /// **'아직 대화가 없습니다'**
  String get chatNoMessagesYet;

  /// 목록 미리보기 — 마지막 메시지가 사진일 때
  ///
  /// In ko, this message translates to:
  /// **'사진'**
  String get chatLastMessageImage;

  /// 공개방 탐색 화면 제목
  ///
  /// In ko, this message translates to:
  /// **'방 탐색'**
  String get chatExploreTitle;

  /// 탐색 화면 검색 입력 힌트
  ///
  /// In ko, this message translates to:
  /// **'방 이름 검색'**
  String get chatSearchHint;

  /// 탐색 빈 상태
  ///
  /// In ko, this message translates to:
  /// **'공개방이 없습니다'**
  String get chatExploreEmptyMessage;

  /// 탐색 빈 상태 보조 설명
  ///
  /// In ko, this message translates to:
  /// **'첫 방을 만들어 보세요.'**
  String get chatExploreEmptyDescription;

  /// 탐색 검색 결과 없음
  ///
  /// In ko, this message translates to:
  /// **'검색 결과가 없습니다'**
  String get chatExploreNoResult;

  /// 탐색 조회 실패
  ///
  /// In ko, this message translates to:
  /// **'방 목록을 불러오지 못했습니다'**
  String get chatExploreLoadFailed;

  /// 입장 시트 제목
  ///
  /// In ko, this message translates to:
  /// **'이 방에서 쓸 이름'**
  String get chatJoinTitle;

  /// 입장 시트 설명
  ///
  /// In ko, this message translates to:
  /// **'방마다 다른 이름을 쓸 수 있습니다.'**
  String get chatJoinDescription;

  /// 입장 시트 입력 라벨
  ///
  /// In ko, this message translates to:
  /// **'방에서 쓸 이름'**
  String get chatJoinNicknameLabel;

  /// 입장 시트 제출 버튼
  ///
  /// In ko, this message translates to:
  /// **'입장'**
  String get chatJoinAction;

  /// 입장 실패
  ///
  /// In ko, this message translates to:
  /// **'입장하지 못했습니다'**
  String get chatJoinFailed;

  /// 방 만들기 화면 제목
  ///
  /// In ko, this message translates to:
  /// **'방 만들기'**
  String get chatCreateTitle;

  /// 방 만들기 — 제목 입력
  ///
  /// In ko, this message translates to:
  /// **'방 이름'**
  String get chatRoomTitleLabel;

  /// 방 만들기 — 소개 입력
  ///
  /// In ko, this message translates to:
  /// **'소개 (선택)'**
  String get chatRoomDescriptionLabel;

  /// 방 만들기 — 개설자 닉네임 입력
  ///
  /// In ko, this message translates to:
  /// **'방에서 쓸 이름'**
  String get chatNicknameLabel;

  /// 방 만들기 제출 버튼
  ///
  /// In ko, this message translates to:
  /// **'만들기'**
  String get chatCreateAction;

  /// 방 생성 실패
  ///
  /// In ko, this message translates to:
  /// **'방을 만들지 못했습니다'**
  String get chatCreateFailed;

  /// 방 안 빈 상태
  ///
  /// In ko, this message translates to:
  /// **'첫 메시지를 남겨보세요'**
  String get chatRoomEmptyMessage;

  /// 방 조회 실패
  ///
  /// In ko, this message translates to:
  /// **'대화를 불러오지 못했습니다'**
  String get chatRoomLoadFailed;

  /// 입력창 힌트
  ///
  /// In ko, this message translates to:
  /// **'메시지 입력'**
  String get chatComposerHint;

  /// 전송 버튼
  ///
  /// In ko, this message translates to:
  /// **'보내기'**
  String get chatSendTooltip;

  /// 사진 첨부 버튼
  ///
  /// In ko, this message translates to:
  /// **'사진 보내기'**
  String get chatAttachTooltip;

  /// 방 AppBar 더보기
  ///
  /// In ko, this message translates to:
  /// **'방 메뉴'**
  String get chatRoomMenuTooltip;

  /// 방 메뉴 — 참여자 목록
  ///
  /// In ko, this message translates to:
  /// **'참여자'**
  String get chatMenuParticipants;

  /// 방 메뉴 — 나가기
  ///
  /// In ko, this message translates to:
  /// **'방 나가기'**
  String get chatMenuLeave;

  /// 참여자 목록 시트 제목
  ///
  /// In ko, this message translates to:
  /// **'참여자'**
  String get chatParticipantsTitle;

  /// 나가기 확인 제목
  ///
  /// In ko, this message translates to:
  /// **'방에서 나갈까요?'**
  String get chatLeaveConfirmTitle;

  /// 나가기 확인 본문
  ///
  /// In ko, this message translates to:
  /// **'나가면 목록에서 사라집니다. 남긴 메시지는 방에 그대로 남습니다.'**
  String get chatLeaveConfirmMessage;

  /// 나가기 확인 버튼
  ///
  /// In ko, this message translates to:
  /// **'나가기'**
  String get chatLeaveConfirmAction;

  /// 나가기 실패
  ///
  /// In ko, this message translates to:
  /// **'방에서 나가지 못했습니다'**
  String get chatLeaveFailed;

  /// 말풍선 길게 누르기 — 삭제
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get chatMessageDelete;

  /// 말풍선 길게 누르기 — 신고
  ///
  /// In ko, this message translates to:
  /// **'신고'**
  String get chatMessageReport;

  /// 메시지 삭제 확인 제목
  ///
  /// In ko, this message translates to:
  /// **'메시지를 삭제할까요?'**
  String get chatDeleteConfirmTitle;

  /// 메시지 삭제 확인 본문
  ///
  /// In ko, this message translates to:
  /// **'삭제한 메시지는 되돌릴 수 없습니다.'**
  String get chatDeleteConfirmMessage;

  /// 전송 실패 스낵바
  ///
  /// In ko, this message translates to:
  /// **'메시지를 보내지 못했습니다'**
  String get chatSendFailed;

  /// 말풍선 옆의 짧은 실패 표시
  ///
  /// In ko, this message translates to:
  /// **'전송 실패'**
  String get chatSendFailedShort;

  /// 말풍선 옆의 전송 중 표시
  ///
  /// In ko, this message translates to:
  /// **'보내는 중'**
  String get chatSending;

  /// 실패한 말풍선의 재전송 버튼
  ///
  /// In ko, this message translates to:
  /// **'다시 보내기'**
  String get chatRetry;

  /// 말풍선 사진 로딩 실패
  ///
  /// In ko, this message translates to:
  /// **'사진을 불러오지 못했습니다'**
  String get chatImageLoadFailed;

  /// 사진 압축·선택 실패
  ///
  /// In ko, this message translates to:
  /// **'사진을 준비하지 못했습니다.'**
  String get chatImagePrepareFailed;

  /// 입장 시스템 메시지. DB 는 키만 저장하고 문장은 앱이 만든다
  ///
  /// In ko, this message translates to:
  /// **'{nickname} 님이 들어왔습니다'**
  String chatSystemJoined(String nickname);

  /// 퇴장 시스템 메시지. DB 는 키만 저장하고 문장은 앱이 만든다
  ///
  /// In ko, this message translates to:
  /// **'{nickname} 님이 나갔습니다'**
  String chatSystemLeft(String nickname);

  /// 참여자 수 표시
  ///
  /// In ko, this message translates to:
  /// **'{count}명'**
  String chatMemberCount(int count);

  /// 방 만들기 슬라이더의 현재 정원
  ///
  /// In ko, this message translates to:
  /// **'정원 {count}명'**
  String chatMemberLimitValue(int count);

  /// 저장 버튼 (프로필·게시물이 함께 쓴다)
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get commonSave;

  /// 내 프로필 화면 제목
  ///
  /// In ko, this message translates to:
  /// **'프로필'**
  String get profileTitle;

  /// 타인 프로필 화면 제목
  ///
  /// In ko, this message translates to:
  /// **'사용자 프로필'**
  String get profileUserTitle;

  /// 프로필 AppBar 더보기 메뉴 툴팁
  ///
  /// In ko, this message translates to:
  /// **'프로필 메뉴'**
  String get profileMenuTooltip;

  /// 프로필 메뉴의 차단 해제 항목
  ///
  /// In ko, this message translates to:
  /// **'차단 해제'**
  String get profileMenuUnblock;

  /// 프로필 조회 실패
  ///
  /// In ko, this message translates to:
  /// **'프로필을 불러오지 못했습니다'**
  String get profileLoadFailed;

  /// 자기소개가 비었을 때 자리 문구
  ///
  /// In ko, this message translates to:
  /// **'자기소개를 작성해보세요'**
  String get profileBioEmpty;

  /// 내 프로필의 완성도 카드 제목. percent 는 0~100 정수
  ///
  /// In ko, this message translates to:
  /// **'프로필 완성 {percent}%'**
  String profileCompletionTitle(int percent);

  /// 완성도 카드 항목. 가입 때 이미 끝났으므로 항상 완료로 표시된다
  ///
  /// In ko, this message translates to:
  /// **'닉네임 정하기'**
  String get profileCompletionNickname;

  /// 완성도 카드 항목. 누르면 프로필 편집으로 간다
  ///
  /// In ko, this message translates to:
  /// **'프로필 사진 올리기'**
  String get profileCompletionAvatar;

  /// 완성도 카드 항목. 누르면 프로필 편집으로 간다
  ///
  /// In ko, this message translates to:
  /// **'자기소개 쓰기'**
  String get profileCompletionBio;

  /// 완성도 카드 항목. 누르면 게시물 작성으로 간다
  ///
  /// In ko, this message translates to:
  /// **'첫 게시물 남기기'**
  String get profileCompletionFirstPost;

  /// 완성도 카드 항목. 홈 피드에서 하는 일이라 누를 수 없다
  ///
  /// In ko, this message translates to:
  /// **'마음에 드는 사람 팔로우하기'**
  String get profileCompletionFirstFollow;

  /// 내 프로필의 편집 진입 버튼
  ///
  /// In ko, this message translates to:
  /// **'프로필 편집'**
  String get profileEditAction;

  /// 남의 프로필에서 1:1 대화를 여는 버튼
  ///
  /// In ko, this message translates to:
  /// **'메시지'**
  String get profileMessageButton;

  /// 프로필 안 게시물 목록 제목
  ///
  /// In ko, this message translates to:
  /// **'게시물'**
  String get profilePostsTitle;

  /// 프로필 게시물 목록 다시 읽기
  ///
  /// In ko, this message translates to:
  /// **'게시물을 다시 불러오기'**
  String get profilePostsReload;

  /// 프로필에 게시물이 없을 때
  ///
  /// In ko, this message translates to:
  /// **'아직 게시물이 없습니다'**
  String get profilePostsEmpty;

  /// 닉네임 중복을 확인하는 중
  ///
  /// In ko, this message translates to:
  /// **'확인 중…'**
  String get profileNicknameChecking;

  /// 닉네임 사전 확인 — 쓸 수 있다
  ///
  /// In ko, this message translates to:
  /// **'사용할 수 있는 닉네임입니다'**
  String get profileNicknameAvailable;

  /// 닉네임 사전 확인 — 이미 쓰이고 있다
  ///
  /// In ko, this message translates to:
  /// **'이미 사용 중인 닉네임입니다'**
  String get profileNicknameTaken;

  /// 프로필 편집의 닉네임 입력 라벨
  ///
  /// In ko, this message translates to:
  /// **'닉네임'**
  String get profileNicknameLabel;

  /// 프로필 사진 선택 실패
  ///
  /// In ko, this message translates to:
  /// **'프로필 사진을 불러오지 못했습니다.'**
  String get profileAvatarPickFailed;

  /// 프로필 편집 화면 제목
  ///
  /// In ko, this message translates to:
  /// **'프로필 편집'**
  String get profileEditTitle;

  /// 가입 직후 한 번 보이는 프로필 편집 화면의 제목
  ///
  /// In ko, this message translates to:
  /// **'프로필 꾸미기'**
  String get profileSetupTitle;

  /// 프로필 꾸미기 화면 상단의 안내 한 문장
  ///
  /// In ko, this message translates to:
  /// **'사진과 한 줄 소개로 이웃에게 나를 알려보세요. 나중에 설정에서 바꿀 수 있습니다.'**
  String get profileSetupDescription;

  /// 프로필 꾸미기를 건너뛰고 홈으로 가는 버튼. 저장 버튼 아래에 둔다
  ///
  /// In ko, this message translates to:
  /// **'나중에'**
  String get profileSetupSkip;

  /// 프로필 꾸미기 화면의 저장 버튼. '가입'이 아니라 '계속' — 내가 만든 것을 들고 넘어간다는 뜻
  ///
  /// In ko, this message translates to:
  /// **'계속'**
  String get profileSetupContinue;

  /// 프로필 저장 실패
  ///
  /// In ko, this message translates to:
  /// **'프로필을 저장하지 못했습니다'**
  String get profileSaveFailed;

  /// 프로필 저장 성공
  ///
  /// In ko, this message translates to:
  /// **'프로필을 저장했습니다'**
  String get profileSaveSucceeded;

  /// 프로필 사진 고르기 버튼
  ///
  /// In ko, this message translates to:
  /// **'사진 선택'**
  String get profileChoosePhoto;

  /// 프로필 편집의 자기소개 입력 라벨
  ///
  /// In ko, this message translates to:
  /// **'자기소개'**
  String get profileBioLabel;

  /// 차단 해제 버튼
  ///
  /// In ko, this message translates to:
  /// **'차단 해제'**
  String get safetyUnblockAction;

  /// 차단 해제 성공
  ///
  /// In ko, this message translates to:
  /// **'차단을 해제했습니다.'**
  String get safetyUnblockSucceeded;

  /// 차단 해제 실패
  ///
  /// In ko, this message translates to:
  /// **'차단을 해제하지 못했습니다.'**
  String get safetyUnblockFailed;

  /// 신고 시트 제목
  ///
  /// In ko, this message translates to:
  /// **'신고'**
  String get safetyReportTitle;

  /// 신고 전송 실패
  ///
  /// In ko, this message translates to:
  /// **'신고를 접수하지 못했습니다'**
  String get safetyReportFailed;

  /// 신고 상세 설명 입력 라벨
  ///
  /// In ko, this message translates to:
  /// **'상세 설명 (선택)'**
  String get safetyReportDetailLabel;

  /// 신고 상세 설명 입력 힌트
  ///
  /// In ko, this message translates to:
  /// **'무엇이 문제인지 적어주세요'**
  String get safetyReportDetailHint;

  /// 신고 시트의 제출 버튼
  ///
  /// In ko, this message translates to:
  /// **'신고하기'**
  String get safetyReportAction;

  /// 신고 사유 — 스팸
  ///
  /// In ko, this message translates to:
  /// **'스팸 또는 광고'**
  String get safetyReportReasonSpam;

  /// 신고 사유 — 욕설·괴롭힘
  ///
  /// In ko, this message translates to:
  /// **'욕설 또는 혐오 표현'**
  String get safetyReportReasonAbuse;

  /// 신고 사유 — 성적 콘텐츠
  ///
  /// In ko, this message translates to:
  /// **'음란물 또는 선정적인 내용'**
  String get safetyReportReasonSexual;

  /// 신고 사유 — 폭력
  ///
  /// In ko, this message translates to:
  /// **'폭력 또는 위협'**
  String get safetyReportReasonViolence;

  /// 신고 사유 — 기타
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get safetyReportReasonOther;

  /// 차단 목록 화면 제목
  ///
  /// In ko, this message translates to:
  /// **'차단한 사용자'**
  String get safetyBlockedUsersTitle;

  /// 차단 목록 조회 실패
  ///
  /// In ko, this message translates to:
  /// **'차단 목록을 불러오지 못했습니다'**
  String get safetyBlockedUsersLoadFailed;

  /// 차단한 사용자가 없을 때
  ///
  /// In ko, this message translates to:
  /// **'차단한 사용자가 없습니다'**
  String get safetyBlockedUsersEmpty;

  /// 계정 설정 화면 제목
  ///
  /// In ko, this message translates to:
  /// **'계정 설정'**
  String get accountSettingsTitle;

  /// 계정 설정의 비밀번호 변경 행
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 변경'**
  String get accountPasswordChange;

  /// 계정 설정의 회원 탈퇴 행
  ///
  /// In ko, this message translates to:
  /// **'회원 탈퇴'**
  String get accountDelete;

  /// 회원 탈퇴 행의 보조 설명
  ///
  /// In ko, this message translates to:
  /// **'계정과 모든 기록이 즉시 삭제됩니다'**
  String get accountDeleteSubtitle;

  /// 회원 탈퇴 실패
  ///
  /// In ko, this message translates to:
  /// **'탈퇴하지 못했습니다. 다시 시도해 주세요.'**
  String get accountDeleteFailed;

  /// 회원 탈퇴 확인 다이얼로그 제목
  ///
  /// In ko, this message translates to:
  /// **'정말 탈퇴할까요?'**
  String get accountDeleteConfirmTitle;

  /// 회원 탈퇴 확인 다이얼로그 본문 — 사라지는 것을 알린다
  ///
  /// In ko, this message translates to:
  /// **'계정과 함께 아래가 모두 삭제되며 되돌릴 수 없습니다.\n\n· 프로필과 프로필 사진\n· 작성한 게시물과 사진\n· 남긴 댓글과 감정표현'**
  String get accountDeleteConfirmMessage;

  /// 탈퇴 확인 본문. 실제 게시물·댓글 개수를 넣은 판. 개수 조회에 실패하면 accountDeleteConfirmMessage 를 쓴다
  ///
  /// In ko, this message translates to:
  /// **'계정과 함께 아래가 모두 삭제되며 되돌릴 수 없습니다.\n\n· 프로필과 프로필 사진\n· 작성한 게시물 {postCount}개와 사진\n· 남긴 댓글 {commentCount}개와 감정표현'**
  String accountDeleteConfirmMessageCounted(int postCount, int commentCount);

  /// 회원 탈퇴 확인 버튼 (되돌릴 수 없다)
  ///
  /// In ko, this message translates to:
  /// **'탈퇴'**
  String get accountDeleteConfirmAction;

  /// 비밀번호 변경 화면 제목
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 변경'**
  String get passwordChangeTitle;

  /// 비밀번호 변경 성공
  ///
  /// In ko, this message translates to:
  /// **'비밀번호를 변경했습니다'**
  String get passwordChangeSucceeded;

  /// 비밀번호 변경 실패
  ///
  /// In ko, this message translates to:
  /// **'비밀번호를 변경하지 못했습니다'**
  String get passwordChangeFailed;

  /// 새 비밀번호 입력 라벨
  ///
  /// In ko, this message translates to:
  /// **'새 비밀번호'**
  String get passwordChangeNewLabel;

  /// 새 비밀번호 확인 입력 라벨
  ///
  /// In ko, this message translates to:
  /// **'새 비밀번호 확인'**
  String get passwordChangeConfirmLabel;

  /// 비밀번호 변경 제출 버튼
  ///
  /// In ko, this message translates to:
  /// **'변경'**
  String get passwordChangeAction;

  /// 입력 검증 — 이메일이 비었다
  ///
  /// In ko, this message translates to:
  /// **'이메일을 입력하세요'**
  String get validationEmailRequired;

  /// 입력 검증 — 이메일 형식이 아니다
  ///
  /// In ko, this message translates to:
  /// **'이메일 형식이 올바르지 않습니다'**
  String get validationEmailInvalid;

  /// 입력 검증 — 비밀번호가 비었다
  ///
  /// In ko, this message translates to:
  /// **'비밀번호를 입력하세요'**
  String get validationPasswordRequired;

  /// 입력 검증 — 비밀번호가 8자 미만이다
  ///
  /// In ko, this message translates to:
  /// **'비밀번호는 8자 이상이어야 합니다'**
  String get validationPasswordTooShort;

  /// 입력 검증 — 비밀번호 확인이 비었다
  ///
  /// In ko, this message translates to:
  /// **'비밀번호를 한 번 더 입력하세요'**
  String get validationPasswordConfirmationRequired;

  /// 입력 검증 — 비밀번호와 확인이 다르다
  ///
  /// In ko, this message translates to:
  /// **'비밀번호가 일치하지 않습니다'**
  String get validationPasswordMismatch;

  /// 입력 검증 — 닉네임이 비었다
  ///
  /// In ko, this message translates to:
  /// **'닉네임을 입력하세요'**
  String get validationNicknameRequired;

  /// 입력 검증 — 닉네임이 2자 미만이다
  ///
  /// In ko, this message translates to:
  /// **'닉네임은 2자 이상이어야 합니다'**
  String get validationNicknameTooShort;

  /// 입력 검증 — 닉네임이 20자를 넘는다
  ///
  /// In ko, this message translates to:
  /// **'닉네임은 20자 이하여야 합니다'**
  String get validationNicknameTooLong;

  /// 입력 검증 — 인증 코드가 비었다
  ///
  /// In ko, this message translates to:
  /// **'코드를 입력하세요'**
  String get validationOtpRequired;

  /// 입력 검증 — 인증 코드가 6자리 숫자가 아니다
  ///
  /// In ko, this message translates to:
  /// **'6자리 숫자를 입력하세요'**
  String get validationOtpInvalid;

  /// 실패 기본 문구 — 네트워크 (FailureCode 없는 NetworkFailure 포함)
  ///
  /// In ko, this message translates to:
  /// **'네트워크에 연결할 수 없습니다'**
  String get failureNetwork;

  /// 실패 기본 문구 — 인증
  ///
  /// In ko, this message translates to:
  /// **'인증에 실패했습니다'**
  String get failureAuth;

  /// 실패 기본 문구 — 권한 없음
  ///
  /// In ko, this message translates to:
  /// **'권한이 없습니다'**
  String get failureForbidden;

  /// 실패 기본 문구 — 대상 없음
  ///
  /// In ko, this message translates to:
  /// **'대상을 찾을 수 없습니다'**
  String get failureNotFound;

  /// 실패 기본 문구 — 입력값
  ///
  /// In ko, this message translates to:
  /// **'입력값을 확인하세요'**
  String get failureValidation;

  /// 실패 기본 문구 — 서버
  ///
  /// In ko, this message translates to:
  /// **'서버 오류가 발생했습니다'**
  String get failureServer;

  /// 실패 기본 문구 — 분류되지 않음
  ///
  /// In ko, this message translates to:
  /// **'알 수 없는 오류가 발생했습니다'**
  String get failureUnknown;

  /// 로그인 — 이메일 또는 비밀번호가 틀렸다
  ///
  /// In ko, this message translates to:
  /// **'이메일 또는 비밀번호가 올바르지 않습니다'**
  String get failureInvalidCredentials;

  /// 로그인 — 응답에 사용자가 없다
  ///
  /// In ko, this message translates to:
  /// **'로그인에 실패했습니다'**
  String get failureSignInFailed;

  /// 가입 — 응답에 사용자가 없다
  ///
  /// In ko, this message translates to:
  /// **'가입에 실패했습니다'**
  String get failureSignUpFailed;

  /// 가입 — 이미 가입된 이메일이다
  ///
  /// In ko, this message translates to:
  /// **'이미 가입된 이메일입니다'**
  String get failureEmailAlreadyRegistered;

  /// 가입·변경 — 비밀번호가 너무 단순하다
  ///
  /// In ko, this message translates to:
  /// **'비밀번호가 너무 단순합니다'**
  String get failureWeakPassword;

  /// 비밀번호 변경 — 이전과 같은 비밀번호다
  ///
  /// In ko, this message translates to:
  /// **'이전과 다른 비밀번호를 입력하세요'**
  String get failureSamePassword;

  /// 재설정 — 인증 코드가 만료됐다
  ///
  /// In ko, this message translates to:
  /// **'코드가 만료되었습니다. 다시 요청하세요'**
  String get failureOtpExpired;

  /// 요청이 너무 잦다 (Supabase 429)
  ///
  /// In ko, this message translates to:
  /// **'요청이 너무 잦습니다. 잠시 후 다시 시도하세요'**
  String get failureRateLimited;

  /// DB 유니크 제약 위반 (23505)
  ///
  /// In ko, this message translates to:
  /// **'이미 사용 중인 값입니다'**
  String get failureDuplicateValue;

  /// DB CHECK 제약 위반 (23514)
  ///
  /// In ko, this message translates to:
  /// **'입력값이 조건을 만족하지 않습니다'**
  String get failureConstraintViolation;

  /// DB 외래키 위반 — 참조 대상이 없다 (23503)
  ///
  /// In ko, this message translates to:
  /// **'참조 대상이 존재하지 않습니다'**
  String get failureReferencedTargetMissing;

  /// RLS 거부 또는 삭제된 대상 (42501)
  ///
  /// In ko, this message translates to:
  /// **'권한이 없거나 삭제된 대상입니다'**
  String get failureForbiddenOrDeleted;

  /// DB — 닉네임 길이 제약
  ///
  /// In ko, this message translates to:
  /// **'닉네임은 2자 이상 20자 이하여야 합니다'**
  String get failureNicknameLength;

  /// DB — 자기소개 길이 제약
  ///
  /// In ko, this message translates to:
  /// **'자기소개는 200자 이하여야 합니다'**
  String get failureBioTooLong;

  /// DB — 게시물 길이 제약
  ///
  /// In ko, this message translates to:
  /// **'게시물은 1자 이상 500자 이하여야 합니다'**
  String get failurePostContentLength;

  /// DB — 댓글 길이 제약
  ///
  /// In ko, this message translates to:
  /// **'댓글은 1자 이상 300자 이하여야 합니다'**
  String get failureCommentContentLength;

  /// DB — 지원하지 않는 감정표현 종류
  ///
  /// In ko, this message translates to:
  /// **'지원하지 않는 감정표현입니다'**
  String get failureUnsupportedReaction;

  /// DB — 같은 대상을 이미 신고했다
  ///
  /// In ko, this message translates to:
  /// **'이미 신고한 항목입니다'**
  String get failureReportAlreadySubmitted;

  /// DB — 신고 상세 설명 길이 제약
  ///
  /// In ko, this message translates to:
  /// **'상세 설명은 500자 이하여야 합니다'**
  String get failureReportDetailTooLong;

  /// DB — 자기 자신은 신고할 수 없다
  ///
  /// In ko, this message translates to:
  /// **'자기 자신은 신고할 수 없습니다'**
  String get failureReportSelfNotAllowed;

  /// DB — 자기 자신은 차단할 수 없다
  ///
  /// In ko, this message translates to:
  /// **'자기 자신은 차단할 수 없습니다'**
  String get failureBlockSelfNotAllowed;

  /// DB — 이미 차단한 사용자다
  ///
  /// In ko, this message translates to:
  /// **'이미 차단한 사용자입니다'**
  String get failureBlockAlreadyExists;

  /// DB 트리거 — 답글에는 답글을 달 수 없다 (2단 제한)
  ///
  /// In ko, this message translates to:
  /// **'답글에는 답글을 달 수 없습니다'**
  String get failureNestedReplyNotAllowed;

  /// DB 트리거 — 삭제된 댓글에는 답글을 달 수 없다
  ///
  /// In ko, this message translates to:
  /// **'삭제된 댓글에는 답글을 달 수 없습니다'**
  String get failureReplyToDeletedCommentNotAllowed;

  /// DB 트리거 — 부모 댓글이 다른 게시물의 것이다
  ///
  /// In ko, this message translates to:
  /// **'부모 댓글이 다른 게시물의 댓글입니다'**
  String get failureReplyParentPostMismatch;

  /// DB 트리거 — 부모 댓글이 없다
  ///
  /// In ko, this message translates to:
  /// **'부모 댓글이 없습니다'**
  String get failureReplyParentMissing;

  /// DB 트리거 — 신고 대상이 존재하지 않는다
  ///
  /// In ko, this message translates to:
  /// **'신고할 대상이 없습니다'**
  String get failureReportTargetMissing;

  /// DB 트리거 — 내 게시물은 신고할 수 없다
  ///
  /// In ko, this message translates to:
  /// **'내 게시물은 신고할 수 없습니다'**
  String get failureReportOwnPostNotAllowed;

  /// DB 트리거 — 내 댓글은 신고할 수 없다
  ///
  /// In ko, this message translates to:
  /// **'내 댓글은 신고할 수 없습니다'**
  String get failureReportOwnCommentNotAllowed;

  /// DB 트리거 — 이 게시물에는 댓글을 달 수 없다. 차단 사실을 밝히지 않으려고 방향 중립이다
  ///
  /// In ko, this message translates to:
  /// **'이 게시물에는 댓글을 달 수 없습니다'**
  String get failureCommentNotAllowed;

  /// 로그인이 필요한 동작을 비로그인으로 시도했다
  ///
  /// In ko, this message translates to:
  /// **'로그인이 필요합니다'**
  String get failureAuthenticationRequired;

  /// 같은 동작이 이미 진행 중이다 (연타 방어)
  ///
  /// In ko, this message translates to:
  /// **'이미 처리 중입니다'**
  String get failureOperationInProgress;

  /// 댓글 조회 개수가 허용 범위 밖이다
  ///
  /// In ko, this message translates to:
  /// **'올바른 댓글 조회 범위가 아닙니다'**
  String get failureCommentsRangeInvalid;

  /// 댓글 커서를 해석할 수 없다
  ///
  /// In ko, this message translates to:
  /// **'잘못된 댓글 커서입니다'**
  String get failureCommentCursorInvalid;

  /// 댓글 내용이 비었다
  ///
  /// In ko, this message translates to:
  /// **'댓글 내용을 입력해 주세요'**
  String get failureCommentContentRequired;

  /// 댓글이 최대 길이를 넘는다
  ///
  /// In ko, this message translates to:
  /// **'댓글은 300자까지 쓸 수 있습니다'**
  String get failureCommentTooLong;

  /// 삭제할 댓글을 찾을 수 없다
  ///
  /// In ko, this message translates to:
  /// **'삭제할 댓글을 찾을 수 없습니다'**
  String get failureCommentDeleteTargetMissing;

  /// 채팅방 이름이 비었다
  ///
  /// In ko, this message translates to:
  /// **'방 이름을 입력하세요'**
  String get failureRoomTitleRequired;

  /// 채팅방 이름이 최대 길이를 넘는다
  ///
  /// In ko, this message translates to:
  /// **'방 이름은 30자 이하여야 합니다'**
  String get failureRoomTitleTooLong;

  /// 채팅방 설명이 최대 길이를 넘는다
  ///
  /// In ko, this message translates to:
  /// **'소개는 200자 이하여야 합니다'**
  String get failureRoomDescriptionTooLong;

  /// 채팅방 정원이 허용 범위 밖이다
  ///
  /// In ko, this message translates to:
  /// **'정원은 2명 이상 500명 이하여야 합니다'**
  String get failureRoomMemberLimitInvalid;

  /// 방에서 쓸 이름이 너무 짧다
  ///
  /// In ko, this message translates to:
  /// **'방에서 쓸 이름은 2자 이상이어야 합니다'**
  String get failureRoomNicknameTooShort;

  /// 방에서 쓸 이름이 너무 길다
  ///
  /// In ko, this message translates to:
  /// **'방에서 쓸 이름은 20자 이하여야 합니다'**
  String get failureRoomNicknameTooLong;

  /// 보낼 메시지가 비었다
  ///
  /// In ko, this message translates to:
  /// **'보낼 내용을 입력하세요'**
  String get failureMessageContentRequired;

  /// 메시지가 최대 길이를 넘는다
  ///
  /// In ko, this message translates to:
  /// **'메시지는 1000자 이하여야 합니다'**
  String get failureMessageTooLong;

  /// 피드 조회 개수가 허용 범위 밖이다
  ///
  /// In ko, this message translates to:
  /// **'올바른 피드 조회 범위가 아닙니다'**
  String get failureFeedRangeInvalid;

  /// 피드 커서를 해석할 수 없다
  ///
  /// In ko, this message translates to:
  /// **'잘못된 피드 커서입니다'**
  String get failureFeedCursorInvalid;

  /// 목록을 읽기 전에 목록 동작을 시도했다
  ///
  /// In ko, this message translates to:
  /// **'목록을 먼저 읽어야 합니다'**
  String get failureFeedNotLoaded;

  /// 목록에서 그 게시물을 찾을 수 없다
  ///
  /// In ko, this message translates to:
  /// **'게시물을 찾을 수 없습니다'**
  String get failurePostNotFound;

  /// 메시지 커서를 해석할 수 없다
  ///
  /// In ko, this message translates to:
  /// **'잘못된 메시지 커서입니다'**
  String get failureMessageCursorInvalid;

  /// 채팅방 커서를 해석할 수 없다
  ///
  /// In ko, this message translates to:
  /// **'잘못된 방 커서입니다'**
  String get failureRoomCursorInvalid;

  /// 게시물 식별자가 필요하다
  ///
  /// In ko, this message translates to:
  /// **'게시물 식별자가 필요합니다'**
  String get failurePostIdRequired;

  /// 게시물 내용이 비었다
  ///
  /// In ko, this message translates to:
  /// **'게시물 내용을 입력하세요'**
  String get failurePostContentRequired;

  /// 게시물이 최대 길이를 넘는다
  ///
  /// In ko, this message translates to:
  /// **'게시물은 500자 이하여야 합니다'**
  String get failurePostTooLong;

  /// 사진 첨부 최대 장수를 넘었다
  ///
  /// In ko, this message translates to:
  /// **'사진은 5장까지 첨부할 수 있습니다'**
  String get failurePostImageLimit;

  /// 프로필 사진 업로드에 실패했다
  ///
  /// In ko, this message translates to:
  /// **'프로필 사진을 업로드하지 못했습니다.'**
  String get failureAvatarUploadFailed;

  /// 응답을 해석할 수 없다
  ///
  /// In ko, this message translates to:
  /// **'올바르지 않은 데이터를 받았습니다'**
  String get failureInvalidData;

  /// 감정표현 — 좋아요
  ///
  /// In ko, this message translates to:
  /// **'좋아요'**
  String get reactionLike;

  /// 감정표현 — 싫어요
  ///
  /// In ko, this message translates to:
  /// **'싫어요'**
  String get reactionDislike;

  /// 아바타의 스크린리더 라벨
  ///
  /// In ko, this message translates to:
  /// **'{nickname} 프로필 사진'**
  String avatarSemanticsLabel(String nickname);

  /// 피드 전체 탭
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get feedTabAll;

  /// 피드 팔로잉 탭
  ///
  /// In ko, this message translates to:
  /// **'팔로잉'**
  String get feedTabFollowing;

  /// 팔로잉 피드가 비었을 때 안내
  ///
  /// In ko, this message translates to:
  /// **'팔로우한 사람이 없습니다'**
  String get feedFollowingEmptyMessage;

  /// 팔로잉 피드가 비었을 때 보조 설명
  ///
  /// In ko, this message translates to:
  /// **'마음에 드는 사람을 팔로우하면 여기에 글이 모입니다.'**
  String get feedFollowingEmptyDescription;

  /// 팔로잉 탭이 비어 있을 때의 행동 버튼. 누르면 전체 탭으로 옮긴다
  ///
  /// In ko, this message translates to:
  /// **'사람 둘러보기'**
  String get feedFollowingEmptyAction;

  /// 팔로우 버튼
  ///
  /// In ko, this message translates to:
  /// **'팔로우'**
  String get followAction;

  /// 이미 팔로우한 상태의 버튼
  ///
  /// In ko, this message translates to:
  /// **'팔로잉'**
  String get followFollowingAction;

  /// 서로 팔로우 중인 상태의 버튼
  ///
  /// In ko, this message translates to:
  /// **'맞팔로우'**
  String get followMutualAction;

  /// 팔로우 실패
  ///
  /// In ko, this message translates to:
  /// **'팔로우하지 못했습니다'**
  String get followFailed;

  /// 팔로우 해제 실패
  ///
  /// In ko, this message translates to:
  /// **'팔로우를 해제하지 못했습니다'**
  String get followUnfollowFailed;

  /// 프로필의 팔로워 수 라벨
  ///
  /// In ko, this message translates to:
  /// **'팔로워'**
  String get followFollowersLabel;

  /// 프로필의 팔로잉 수 라벨
  ///
  /// In ko, this message translates to:
  /// **'팔로잉'**
  String get followFollowingsLabel;

  /// 팔로워 목록 화면 제목
  ///
  /// In ko, this message translates to:
  /// **'팔로워'**
  String get followFollowersTitle;

  /// 팔로잉 목록 화면 제목
  ///
  /// In ko, this message translates to:
  /// **'팔로잉'**
  String get followFollowingsTitle;

  /// 팔로워 목록이 비었을 때
  ///
  /// In ko, this message translates to:
  /// **'아직 팔로워가 없습니다'**
  String get followFollowersEmpty;

  /// 팔로잉 목록이 비었을 때
  ///
  /// In ko, this message translates to:
  /// **'아직 팔로우한 사람이 없습니다'**
  String get followFollowingsEmpty;

  /// 팔로우 목록 조회 실패
  ///
  /// In ko, this message translates to:
  /// **'목록을 불러오지 못했습니다'**
  String get followListLoadFailed;

  /// 팔로우 조회에 사용자 id 가 없다
  ///
  /// In ko, this message translates to:
  /// **'사용자 식별자가 필요합니다'**
  String get failureFollowUserIdRequired;

  /// 팔로우 목록 조회 범위 오류
  ///
  /// In ko, this message translates to:
  /// **'올바른 팔로우 조회 범위가 아닙니다'**
  String get failureFollowRangeInvalid;

  /// 팔로우 목록 커서 오류
  ///
  /// In ko, this message translates to:
  /// **'잘못된 팔로우 커서입니다'**
  String get failureFollowCursorInvalid;

  /// 차단 관계라 팔로우가 거부됐다. 방향을 밝히지 않는다
  ///
  /// In ko, this message translates to:
  /// **'지금은 팔로우할 수 없습니다'**
  String get failureFollowBlocked;

  /// DB 트리거 — 채팅방 정원이 찼다
  ///
  /// In ko, this message translates to:
  /// **'정원이 가득 찬 방입니다'**
  String get failureRoomFull;

  /// DB 트리거 — 입장하려는 방이 없다
  ///
  /// In ko, this message translates to:
  /// **'없는 방입니다'**
  String get failureRoomNotFound;

  /// DB 트리거 — 차단 관계 등으로 DM 방 개설이 거부됐다
  ///
  /// In ko, this message translates to:
  /// **'대화를 시작할 수 없습니다'**
  String get failureDirectChatNotAllowed;

  /// DB 트리거 — open_direct_room 의 partner_id 가 본인이다
  ///
  /// In ko, this message translates to:
  /// **'자기 자신과는 대화할 수 없습니다'**
  String get failureDirectChatSelfNotAllowed;

  /// DB 트리거 — 차단 관계 등으로 메시지 전송이 거부됐다
  ///
  /// In ko, this message translates to:
  /// **'메시지를 보낼 수 없습니다'**
  String get failureChatSendNotAllowed;

  /// DB 트리거 — 내 채팅 메시지는 신고할 수 없다
  ///
  /// In ko, this message translates to:
  /// **'내 메시지는 신고할 수 없습니다'**
  String get failureReportOwnMessageNotAllowed;

  /// trade RPC — 사용자당 진행 중인 판은 1개만 허용된다
  ///
  /// In ko, this message translates to:
  /// **'진행 중인 판이 있습니다'**
  String get failureTradeSessionAlreadyActive;

  /// trade RPC — 남의 진행 중 판이거나 없는 id. 존재 여부를 밝히지 않는다
  ///
  /// In ko, this message translates to:
  /// **'판을 찾을 수 없습니다'**
  String get failureTradeSessionNotFound;

  /// trade RPC — 이미 종료된 판에 매매·advance 를 시도했다
  ///
  /// In ko, this message translates to:
  /// **'이미 끝난 판입니다'**
  String get failureTradeSessionFinished;

  /// trade RPC — 매수에 필요한 현금이 부족하다
  ///
  /// In ko, this message translates to:
  /// **'잔고가 부족합니다'**
  String get failureTradeInsufficientCash;

  /// trade RPC — 매도하려는 수량이 보유량을 초과한다
  ///
  /// In ko, this message translates to:
  /// **'보유 수량이 부족합니다'**
  String get failureTradeInsufficientQuantity;

  /// trade RPC — 주문 수량이 0 이하다
  ///
  /// In ko, this message translates to:
  /// **'수량은 0보다 커야 합니다'**
  String get failureTradeQuantityInvalid;

  /// trade RPC — 진행 중인 판은 피드에 공유할 수 없다
  ///
  /// In ko, this message translates to:
  /// **'끝난 판만 공유할 수 있습니다'**
  String get failureTradeSessionNotShareable;

  /// 통근 경로 검색 — 집 또는 회사 역이 아직 설정되지 않았을 때
  ///
  /// In ko, this message translates to:
  /// **'집과 회사 역을 먼저 설정해 주세요'**
  String get failureCommuteNotConfigured;

  /// 통근 출발지 확인 — 위치 권한이 거부됐거나 영구 거부됐을 때
  ///
  /// In ko, this message translates to:
  /// **'위치 권한을 사용할 수 없습니다'**
  String get failureLocationPermissionDenied;

  /// 통근 출발지 확인 — 기기의 위치 서비스가 꺼져 있을 때
  ///
  /// In ko, this message translates to:
  /// **'위치 서비스가 꺼져 있습니다'**
  String get failureLocationServiceDisabled;

  /// 통근 출발지 확인 — 제한 시간 안에 위치를 받지 못했을 때
  ///
  /// In ko, this message translates to:
  /// **'현재 위치를 가져오지 못했습니다'**
  String get failureLocationTimeout;

  /// 통근 경로 검색 구현이 결과를 만들지 못했을 때
  ///
  /// In ko, this message translates to:
  /// **'통근 경로를 찾지 못했습니다'**
  String get failureRouteSearchFailed;

  /// 모의투자 홈(투자 탭) AppBar 제목
  ///
  /// In ko, this message translates to:
  /// **'모의투자'**
  String get tradeHomeTitle;

  /// 모의투자 홈에서 새 판을 시작하는 버튼
  ///
  /// In ko, this message translates to:
  /// **'새 판 시작'**
  String get tradeStart;

  /// 진행 중인 판으로 돌아가는 카드의 제목
  ///
  /// In ko, this message translates to:
  /// **'이어하기'**
  String get tradeResume;

  /// 진행 중인 판의 진행도 — 현재 step 과 전체 step 수
  ///
  /// In ko, this message translates to:
  /// **'{step} / {total}'**
  String tradeStepOf(int step, int total);

  /// 현금과 보유 수량을 현재가로 평가한 총 자산의 라벨
  ///
  /// In ko, this message translates to:
  /// **'평가액'**
  String get tradeEquity;

  /// 모의투자 홈에서 끝난 판 목록의 섹션 제목
  ///
  /// In ko, this message translates to:
  /// **'지난 판'**
  String get tradePastSessions;

  /// 진행 중인 판도 지난 판도 없을 때의 빈 상태 제목
  ///
  /// In ko, this message translates to:
  /// **'아직 해본 판이 없습니다'**
  String get tradeEmptyTitle;

  /// 모의투자 빈 상태에서 무엇을 하는 기능인지 알려주는 설명
  ///
  /// In ko, this message translates to:
  /// **'과거 시세를 하루씩 넘기며 매매해 보세요'**
  String get tradeEmptyDescription;

  /// 끝난 판의 결과 화면 AppBar 제목
  ///
  /// In ko, this message translates to:
  /// **'결과'**
  String get tradeResultTitle;

  /// 결과 화면 지표 — 초기 자본 대비 수익률
  ///
  /// In ko, this message translates to:
  /// **'수익률'**
  String get tradeReturn;

  /// 결과 화면 지표 — 매매하지 않고 계속 들고만 있었을 때의 수익률
  ///
  /// In ko, this message translates to:
  /// **'보유만 했을 때'**
  String get tradeBuyHold;

  /// 결과 화면 지표 — 평가액 고점 대비 가장 크게 내려간 폭
  ///
  /// In ko, this message translates to:
  /// **'최대낙폭'**
  String get tradeMaxDrawdown;

  /// 결과 화면 지표 — 체결한 주문 수
  ///
  /// In ko, this message translates to:
  /// **'매매 횟수'**
  String get tradeCount;

  /// 매매 횟수 지표의 값 표기
  ///
  /// In ko, this message translates to:
  /// **'{count}회'**
  String tradeCountValue(int count);

  /// 결과 판정 한 줄 — 보유만 했을 때보다 나은 경우. diff 는 부호 없는 퍼센트
  ///
  /// In ko, this message translates to:
  /// **'보유보다 {diff} 나았습니다'**
  String tradeBeatBuyHold(String diff);

  /// 결과 판정 한 줄 — 보유만 했을 때보다 못한 경우. diff 는 부호 없는 퍼센트
  ///
  /// In ko, this message translates to:
  /// **'보유보다 {diff} 못했습니다'**
  String tradeLostToBuyHold(String diff);

  /// 결과 화면을 열었는데 그 판이 아직 진행 중일 때의 안내
  ///
  /// In ko, this message translates to:
  /// **'아직 끝나지 않은 판입니다'**
  String get tradeResultNotReady;

  /// 결과 화면 — 내 판의 결과를 게시물로 올리러 가는 버튼
  ///
  /// In ko, this message translates to:
  /// **'공유하기'**
  String get tradeShare;

  /// 피드의 판 결과 카드 — 매매하지 않고 들고만 있었을 때의 수익률. pct 는 부호 포함 퍼센트
  ///
  /// In ko, this message translates to:
  /// **'보유만 했을 때 {pct}'**
  String tradeCardBuyHold(String pct);

  /// 피드의 판 결과 카드 — 평가액 고점 대비 가장 크게 내려간 폭. pct 는 부호 포함 퍼센트
  ///
  /// In ko, this message translates to:
  /// **'최대낙폭 {pct}'**
  String tradeCardMaxDrawdown(String pct);

  /// 피드의 판 결과 카드 — 그 판에서 체결한 주문 수
  ///
  /// In ko, this message translates to:
  /// **'매매 {count}회'**
  String tradeCardCount(int count);

  /// 판 진행 화면 AppBar 제목
  ///
  /// In ko, this message translates to:
  /// **'모의투자'**
  String get tradeSessionTitle;

  /// 판 진행 화면 더보기 메뉴 — 보유분을 현재가로 팔고 판을 끝낸다
  ///
  /// In ko, this message translates to:
  /// **'청산하고 끝내기'**
  String get tradeFinishNow;

  /// 청산하고 끝내기 확인 다이얼로그 제목
  ///
  /// In ko, this message translates to:
  /// **'지금 끝낼까요?'**
  String get tradeFinishConfirmTitle;

  /// 청산하고 끝내기 확인 다이얼로그 본문 — 되돌릴 수 없음을 알린다
  ///
  /// In ko, this message translates to:
  /// **'보유 수량을 현재가로 모두 팔고 결과를 봅니다. 되돌릴 수 없습니다.'**
  String get tradeFinishConfirmMessage;

  /// 판 진행 화면 지표 — 아직 쓰지 않은 현금
  ///
  /// In ko, this message translates to:
  /// **'현금'**
  String get tradeCash;

  /// 판 진행 화면 지표 — 지금 들고 있는 수량
  ///
  /// In ko, this message translates to:
  /// **'보유 수량'**
  String get tradeQuantity;

  /// 판 진행 화면 지표 — 초기 자본 대비 지금까지의 수익률
  ///
  /// In ko, this message translates to:
  /// **'현재 수익률'**
  String get tradeCurrentReturn;

  /// 판 진행 화면 — 현재 봉의 정규화 종가. 단위 없는 지수다
  ///
  /// In ko, this message translates to:
  /// **'현재가'**
  String get tradeCurrentPrice;

  /// 캔들 차트 스크린 리더 설명 — 공개 진행도와 마지막 봉의 현재가
  ///
  /// In ko, this message translates to:
  /// **'총 {totalCount}개 봉 중 {visibleCount}개 공개, 현재가 {currentPrice}'**
  String tradeChartSemantics(
    int visibleCount,
    int totalCount,
    String currentPrice,
  );

  /// 캔들 차트 스크린 리더 설명 — 공개된 봉이 없을 때
  ///
  /// In ko, this message translates to:
  /// **'아직 공개된 봉이 없습니다. 전체 {totalCount}개'**
  String tradeChartEmptySemantics(int totalCount);

  /// 판 진행 화면의 매수 버튼과 매수 주문 시트 제목
  ///
  /// In ko, this message translates to:
  /// **'매수'**
  String get tradeBuy;

  /// 판 진행 화면의 매도 버튼과 매도 주문 시트 제목
  ///
  /// In ko, this message translates to:
  /// **'매도'**
  String get tradeSell;

  /// 판 진행 화면 — 다음 봉으로 넘어가는 버튼
  ///
  /// In ko, this message translates to:
  /// **'다음 날'**
  String get tradeNextDay;

  /// 매수 주문 시트 — 금액을 입력해 수량을 계산하는 방식
  ///
  /// In ko, this message translates to:
  /// **'금액'**
  String get tradeByAmount;

  /// 매수 주문 시트 — 수량을 직접 입력하는 방식
  ///
  /// In ko, this message translates to:
  /// **'수량'**
  String get tradeByQuantity;

  /// 매수 주문 시트 미리보기 — 이 주문으로 사게 될 수량
  ///
  /// In ko, this message translates to:
  /// **'예상 수량'**
  String get tradeExpectedQuantity;

  /// 매도 주문 시트 미리보기 — 수수료를 뺀 뒤 받게 될 금액
  ///
  /// In ko, this message translates to:
  /// **'예상 수령액'**
  String get tradeExpectedProceeds;

  /// 주문 시트 미리보기 — 이 주문에 붙는 수수료
  ///
  /// In ko, this message translates to:
  /// **'수수료'**
  String get tradeFee;

  /// 매수 주문 시트 미리보기 — 주문이 체결된 뒤 남는 현금
  ///
  /// In ko, this message translates to:
  /// **'주문 후 현금'**
  String get tradeRemainingCash;

  /// 매도 주문 시트 미리보기 — 주문이 체결된 뒤 남는 보유 수량
  ///
  /// In ko, this message translates to:
  /// **'주문 후 보유 수량'**
  String get tradeRemainingQuantity;

  /// 주문 시트의 확인 버튼
  ///
  /// In ko, this message translates to:
  /// **'주문하기'**
  String get tradeConfirmOrder;

  /// 주문 시트 — 입력값을 하나의 유한한 숫자로 해석할 수 없을 때 안내
  ///
  /// In ko, this message translates to:
  /// **'올바른 숫자를 입력해 주세요'**
  String get tradeInvalidNumber;

  /// 주문 시트 — 입력값이나 소수 6자리 내림 뒤 수량이 0 이하일 때 안내
  ///
  /// In ko, this message translates to:
  /// **'0보다 큰 값을 입력해 주세요'**
  String get tradeQuantityMustBePositive;

  /// 주문이 성공했을 때의 스낵바
  ///
  /// In ko, this message translates to:
  /// **'주문이 체결됐습니다'**
  String get tradeOrderPlaced;

  /// 주문 시트의 비율 프리셋 버튼 라벨 — 현금 또는 보유 수량의 몇 %인지
  ///
  /// In ko, this message translates to:
  /// **'{pct}%'**
  String tradeFractionLabel(int pct);

  /// 통근 앱 설정 화면 제목
  ///
  /// In ko, this message translates to:
  /// **'통근 설정'**
  String get commuteSettingsTitle;

  /// 통근 앱 설정 화면에서 역 선택을 안내하는 문구
  ///
  /// In ko, this message translates to:
  /// **'집과 회사에서 가까운 역을 선택하세요'**
  String get commuteSettingsDescription;

  /// 통근 앱 설정 화면의 집 기준 역 항목
  ///
  /// In ko, this message translates to:
  /// **'집 역'**
  String get commuteHomeStation;

  /// 통근 앱 설정 화면의 회사 기준 역 항목
  ///
  /// In ko, this message translates to:
  /// **'회사 역'**
  String get commuteWorkStation;

  /// 통근 역이 아직 선택되지 않았을 때의 안내
  ///
  /// In ko, this message translates to:
  /// **'역을 선택해 주세요'**
  String get commuteStationNotSet;

  /// 통근 앱 역 검색 시트 제목
  ///
  /// In ko, this message translates to:
  /// **'역 검색'**
  String get commuteStationSearchTitle;

  /// 통근 앱 역 검색 입력 필드의 힌트
  ///
  /// In ko, this message translates to:
  /// **'역 이름을 입력하세요'**
  String get commuteStationSearchHint;

  /// 통근 앱 역 검색 전의 빈 상태 안내
  ///
  /// In ko, this message translates to:
  /// **'역 이름을 검색해 주세요'**
  String get commuteStationSearchPrompt;

  /// 통근 앱 역 검색 결과가 비었을 때의 안내
  ///
  /// In ko, this message translates to:
  /// **'검색 결과가 없습니다'**
  String get commuteStationSearchEmpty;

  /// 통근 앱 이름과 홈 화면 제목
  ///
  /// In ko, this message translates to:
  /// **'통근 시간'**
  String get commuteAppTitle;

  /// 통근 앱에서 집에서 회사로 가는 방향
  ///
  /// In ko, this message translates to:
  /// **'출근'**
  String get commuteDirectionToWork;

  /// 통근 앱에서 회사에서 집으로 가는 방향
  ///
  /// In ko, this message translates to:
  /// **'퇴근'**
  String get commuteDirectionToHome;

  /// 현재 GPS 위치를 경로 출발지로 썼다는 안내
  ///
  /// In ko, this message translates to:
  /// **'현 위치 기준'**
  String get commuteCurrentLocationOrigin;

  /// 출근 경로에서 GPS 대신 집 역을 썼다는 안내
  ///
  /// In ko, this message translates to:
  /// **'집 기준 · 위치를 못 가져왔어요'**
  String get commuteHomeFallbackOrigin;

  /// 퇴근 경로에서 GPS 대신 회사 역을 썼다는 안내
  ///
  /// In ko, this message translates to:
  /// **'회사 기준 · 위치를 못 가져왔어요'**
  String get commuteWorkFallbackOrigin;

  /// 통근 경로 카드의 지하철 모드 이름
  ///
  /// In ko, this message translates to:
  /// **'지하철'**
  String get commuteModeSubway;

  /// 통근 경로 카드의 버스 모드 이름
  ///
  /// In ko, this message translates to:
  /// **'버스'**
  String get commuteModeBus;

  /// 통근 경로 카드의 최적 조합 모드 이름
  ///
  /// In ko, this message translates to:
  /// **'최적'**
  String get commuteModeBest;

  /// 통근 경로의 총 소요 시간을 분 단위로 표시
  ///
  /// In ko, this message translates to:
  /// **'{minutes}분'**
  String commuteDurationMinutes(int minutes);

  /// 통근 경로의 환승 횟수
  ///
  /// In ko, this message translates to:
  /// **'환승 {count}회'**
  String commuteTransferCount(int count);

  /// 홈에서 집이나 회사 역이 비었을 때의 안내 제목
  ///
  /// In ko, this message translates to:
  /// **'통근 역 설정이 필요해요'**
  String get commuteSettingsRequiredTitle;

  /// 홈에서 통근 설정을 먼저 마치도록 안내하는 설명
  ///
  /// In ko, this message translates to:
  /// **'집과 회사 역을 먼저 선택해 주세요'**
  String get commuteSettingsRequiredDescription;

  /// 통근 설정 화면을 여는 행동 버튼 라벨
  ///
  /// In ko, this message translates to:
  /// **'설정하기'**
  String get commuteOpenSettings;

  /// 통근 홈의 설정 아이콘 접근성 문구
  ///
  /// In ko, this message translates to:
  /// **'통근 설정'**
  String get commuteOpenSettingsTooltip;

  /// 산책을 시작하거나 저장할 때 반려견이 한 마리도 선택되지 않았을 때
  ///
  /// In ko, this message translates to:
  /// **'함께 산책한 반려견을 선택해 주세요'**
  String get failureWalkDogRequired;

  /// 산책 추적 중에 새 산책을 시작하려 할 때
  ///
  /// In ko, this message translates to:
  /// **'이미 진행 중인 산책이 있습니다'**
  String get failureWalkTrackingAlreadyActive;

  /// 수정하거나 삭제하려는 산책 기록이 이미 없을 때
  ///
  /// In ko, this message translates to:
  /// **'산책 기록을 찾을 수 없습니다'**
  String get failureWalkNotFound;

  /// 산책이나 반려견 사진을 앱 저장소에 복사하지 못했을 때
  ///
  /// In ko, this message translates to:
  /// **'사진을 저장하지 못했습니다'**
  String get failureWalkPhotoSaveFailed;

  /// 반려견 이름이 비어 있는 채로 저장하려 할 때
  ///
  /// In ko, this message translates to:
  /// **'반려견 이름을 입력해 주세요'**
  String get failureDogNameRequired;

  /// pawlog 앱의 이름. 앱 바와 작업 전환 화면에 쓰인다
  ///
  /// In ko, this message translates to:
  /// **'pawlog'**
  String get walkAppTitle;

  /// 반려견 목록 화면 앱 바 제목
  ///
  /// In ko, this message translates to:
  /// **'반려견'**
  String get walkDogListTitle;

  /// 반려견이 한 마리도 없을 때 빈 상태 제목
  ///
  /// In ko, this message translates to:
  /// **'등록된 반려견이 없습니다'**
  String get walkDogListEmptyTitle;

  /// 반려견이 없을 때 등록을 권하는 안내 문구
  ///
  /// In ko, this message translates to:
  /// **'함께 산책할 반려견을 등록해 주세요'**
  String get walkDogListEmptyMessage;

  /// 반려견 등록 화면으로 가는 버튼 라벨
  ///
  /// In ko, this message translates to:
  /// **'반려견 추가'**
  String get walkDogAddAction;

  /// 반려견 등록 화면 앱 바 제목
  ///
  /// In ko, this message translates to:
  /// **'반려견 등록'**
  String get walkDogNewTitle;

  /// 반려견 수정 화면 앱 바 제목
  ///
  /// In ko, this message translates to:
  /// **'반려견 수정'**
  String get walkDogEditTitle;

  /// 반려견 이름 입력란 라벨
  ///
  /// In ko, this message translates to:
  /// **'이름'**
  String get walkDogNameLabel;

  /// 반려견 품종 입력란 라벨
  ///
  /// In ko, this message translates to:
  /// **'품종'**
  String get walkDogBreedLabel;

  /// 반려견 생일 행 라벨
  ///
  /// In ko, this message translates to:
  /// **'생일'**
  String get walkDogBirthdayLabel;

  /// 반려견 생일을 아직 정하지 않았을 때 행에 보이는 문구
  ///
  /// In ko, this message translates to:
  /// **'설정 안 함'**
  String get walkDogBirthdayUnset;

  /// 반려견 사진을 고르는 버튼 라벨
  ///
  /// In ko, this message translates to:
  /// **'사진 변경'**
  String get walkDogPhotoChange;

  /// 반려견 폼 저장 버튼 라벨
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get walkDogSaveAction;

  /// 반려견 수정 화면 더보기 메뉴의 삭제 항목 라벨
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get walkDogDeleteAction;

  /// 반려견 삭제 확인 다이얼로그 제목
  ///
  /// In ko, this message translates to:
  /// **'반려견을 삭제할까요?'**
  String get walkDogDeleteConfirmTitle;

  /// 반려견 삭제 확인 다이얼로그 본문. 산책 기록은 유지됨을 알린다
  ///
  /// In ko, this message translates to:
  /// **'산책 기록은 남고, 기록에서 이 반려견만 빠집니다.'**
  String get walkDogDeleteConfirmMessage;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
