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

  /// 위치 추적 중 위치 스트림이 오류를 냈을 때
  ///
  /// In ko, this message translates to:
  /// **'위치를 받아 오지 못하고 있습니다'**
  String get failureLocationStreamFailed;

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

  /// 앱 표시 이름 (걷기 외 생활 기능도 담을 예정이라 특정 기능명을 쓰지 않는다)
  ///
  /// In ko, this message translates to:
  /// **'Life Tool'**
  String get walkAppTitle;

  /// 오늘 걸음 수 섹션 라벨
  ///
  /// In ko, this message translates to:
  /// **'오늘'**
  String get walkToday;

  /// 걸음 수를 단위와 함께 표시
  ///
  /// In ko, this message translates to:
  /// **'{steps} 걸음'**
  String walkStepsCount(String steps);

  /// 하루 걸음 목표 표시
  ///
  /// In ko, this message translates to:
  /// **'목표 {goal}'**
  String walkGoalOf(String goal);

  /// 목표까지 남은 걸음 수. steps 는 walkStepsCount 로 포맷한 값
  ///
  /// In ko, this message translates to:
  /// **'목표까지 {steps}'**
  String walkGoalRemaining(String steps);

  /// 목표까지 남은 걸음 수와 거리
  ///
  /// In ko, this message translates to:
  /// **'목표까지 {steps} · 약 {distance}'**
  String walkGoalRemainingWithDistance(String steps, String distance);

  /// 목표를 넘긴 걸음 수
  ///
  /// In ko, this message translates to:
  /// **'목표보다 {steps} 더 걸었어요'**
  String walkGoalExceeded(String steps);

  /// 목표 달성 라벨
  ///
  /// In ko, this message translates to:
  /// **'달성'**
  String get walkGoalReached;

  /// 기간 중 목표를 달성한 일수
  ///
  /// In ko, this message translates to:
  /// **'달성 {reached}/{total}일'**
  String walkGoalDaysReached(int reached, int total);

  /// 목표 대비 백분율
  ///
  /// In ko, this message translates to:
  /// **'목표 {percent}%'**
  String walkGoalOfPercent(int percent);

  /// 목표 링의 접근성 설명
  ///
  /// In ko, this message translates to:
  /// **'오늘 {steps}, 목표 {goal}의 {percent}%'**
  String walkGoalRingSemantics(String steps, String goal, int percent);

  /// 차트의 목표선 라벨
  ///
  /// In ko, this message translates to:
  /// **'목표'**
  String get walkGoalLine;

  /// 설정의 걷기 섹션 제목
  ///
  /// In ko, this message translates to:
  /// **'걷기'**
  String get walkSettingsWalk;

  /// 하루 걸음 목표 설정 항목
  ///
  /// In ko, this message translates to:
  /// **'하루 목표'**
  String get walkSettingsStepGoal;

  /// 하루 목표 저장 버튼
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get walkSettingsStepGoalSave;

  /// 주간 탭 라벨
  ///
  /// In ko, this message translates to:
  /// **'주간'**
  String get walkTabWeek;

  /// 월간 탭 라벨
  ///
  /// In ko, this message translates to:
  /// **'월간'**
  String get walkTabMonth;

  /// 기간 합계 걸음 수 라벨
  ///
  /// In ko, this message translates to:
  /// **'합계'**
  String get walkTotalSteps;

  /// 기간 일평균 걸음 수 라벨
  ///
  /// In ko, this message translates to:
  /// **'일평균'**
  String get walkAverageSteps;

  /// 이동 거리 라벨
  ///
  /// In ko, this message translates to:
  /// **'거리'**
  String get walkDistance;

  /// 활동 칼로리 라벨
  ///
  /// In ko, this message translates to:
  /// **'활동 칼로리'**
  String get walkActiveCalories;

  /// 이전 기간으로 이동하는 버튼 라벨
  ///
  /// In ko, this message translates to:
  /// **'이전'**
  String get walkPreviousPeriod;

  /// 다음 기간으로 이동하는 버튼 라벨
  ///
  /// In ko, this message translates to:
  /// **'다음'**
  String get walkNextPeriod;

  /// Health Connect 미설치 안내 제목
  ///
  /// In ko, this message translates to:
  /// **'Health Connect 가 필요해요'**
  String get walkHealthConnectMissing;

  /// Health Connect 미설치 안내 설명
  ///
  /// In ko, this message translates to:
  /// **'폰의 헬스 앱이 기록한 걸음을 Health Connect 에서 읽어요'**
  String get walkHealthConnectMissingDescription;

  /// Health Connect 설치 버튼 라벨
  ///
  /// In ko, this message translates to:
  /// **'설치하기'**
  String get walkInstall;

  /// Health Connect 업데이트 필요 안내 제목
  ///
  /// In ko, this message translates to:
  /// **'Health Connect 를 업데이트해 주세요'**
  String get walkHealthConnectUpdate;

  /// Health Connect 업데이트 버튼 라벨
  ///
  /// In ko, this message translates to:
  /// **'업데이트하기'**
  String get walkUpdate;

  /// 권한 요청 안내 제목
  ///
  /// In ko, this message translates to:
  /// **'걸음 기록을 읽을 권한이 필요해요'**
  String get walkPermissionNeeded;

  /// 권한 요청 안내 설명
  ///
  /// In ko, this message translates to:
  /// **'걸음 · 거리 · 활동 칼로리를 읽기만 하고 저장하거나 보내지 않아요'**
  String get walkPermissionDescription;

  /// 권한 요청 버튼 라벨
  ///
  /// In ko, this message translates to:
  /// **'권한 허용'**
  String get walkGrantPermission;

  /// 설정 화면을 여는 버튼 라벨
  ///
  /// In ko, this message translates to:
  /// **'설정 열기'**
  String get walkOpenSettings;

  /// 기록 불러오기 실패 안내 문구
  ///
  /// In ko, this message translates to:
  /// **'기록을 불러오지 못했어요'**
  String get walkLoadFailed;

  /// 라벨 없는 알람의 알림 제목
  ///
  /// In ko, this message translates to:
  /// **'알람'**
  String get walkAlarmDefaultTitle;

  /// 울리는 알람을 끄는 버튼 라벨(알림 · 울림 화면)
  ///
  /// In ko, this message translates to:
  /// **'알람 끄기'**
  String get walkAlarmStop;

  /// 울리는 알람을 스누즈 간격만큼 미루는 버튼 라벨(알림 · 울림 화면). minutes 는 알람별 스누즈 간격(5 · 10 · 15)
  ///
  /// In ko, this message translates to:
  /// **'{minutes}분 뒤 다시 울림'**
  String walkAlarmSnooze(int minutes);

  /// 울리기 30분 전 미리 알림의 제목
  ///
  /// In ko, this message translates to:
  /// **'곧 알람이 울려요'**
  String get walkReminderSoonTitle;

  /// 울리기 30분 전 미리 알림의 본문. time 은 기기 언어의 울릴 시각(오전 7:00), label 은 알람 라벨(없으면 '알람')
  ///
  /// In ko, this message translates to:
  /// **'{time} {label}'**
  String walkReminderSoonBody(String time, String label);

  /// 미리 알림의 액션 — 곧 울릴 회차 하나만 쉰다
  ///
  /// In ko, this message translates to:
  /// **'이번만 끄기'**
  String get walkReminderTurnOffOnce;

  /// 반복 알람이 공휴일에 울릴 때 24시간 전에 띄우는 알림의 제목
  ///
  /// In ko, this message translates to:
  /// **'공휴일에 울리는 알람'**
  String get walkReminderHolidayTitle;

  /// 공휴일 미리 알림의 본문. date 는 기기 언어의 날짜(10월 9일), name 은 공휴일 이름(한글날), time 은 울릴 시각(오전 7:00). 영어 · 일본어는 이름을 쓰지 않는다
  ///
  /// In ko, this message translates to:
  /// **'{date}({name}) {time} 알람이 공휴일에 울려요'**
  String walkReminderHolidayBody(String date, String name, String time);

  /// 공휴일 이름을 모를 때의 공휴일 미리 알림 본문. date 는 날짜, time 은 울릴 시각
  ///
  /// In ko, this message translates to:
  /// **'{date} {time} 알람이 공휴일에 울려요'**
  String walkReminderHolidayBodyNoName(String date, String time);

  /// 공휴일 미리 알림의 액션 — 공휴일 회차 하나를 건너뛴다
  ///
  /// In ko, this message translates to:
  /// **'다음 알람 건너뛰기'**
  String get walkReminderSkip;

  /// 공휴일 미리 알림의 액션 — 그대로 울리도록 알림만 닫는다
  ///
  /// In ko, this message translates to:
  /// **'울리기'**
  String get walkReminderRing;

  /// 알람 편집 화면 아래 접히는 울림 설정 영역 제목
  ///
  /// In ko, this message translates to:
  /// **'울림 설정'**
  String get walkAlarmRingSettings;

  /// 접힌 울림 설정 영역의 한 줄 요약. snooze 는 "5분", autoStop 은 "10분" 또는 "없음"
  ///
  /// In ko, this message translates to:
  /// **'볼륨 {volume}% · 스누즈 {snooze} · 자동 멈춤 {autoStop}'**
  String walkAlarmRingSummary(int volume, String snooze, String autoStop);

  /// 울림 설정 요약에서 자동 멈춤을 쓰지 않을 때
  ///
  /// In ko, this message translates to:
  /// **'없음'**
  String get walkAlarmAutoStopNone;

  /// 울림 설정 — 볼륨 슬라이더 제목
  ///
  /// In ko, this message translates to:
  /// **'볼륨'**
  String get walkAlarmVolume;

  /// 볼륨 값 표시
  ///
  /// In ko, this message translates to:
  /// **'{percent}%'**
  String walkAlarmPercent(int percent);

  /// 울림 설정 — 소리가 처음엔 작다가 점점 커지는 시간 선택 제목
  ///
  /// In ko, this message translates to:
  /// **'점점 커지기'**
  String get walkAlarmFade;

  /// 점점 커지기 선택지 — 쓰지 않음
  ///
  /// In ko, this message translates to:
  /// **'끔'**
  String get walkAlarmFadeOff;

  /// 초 단위 선택지(점점 커지기)
  ///
  /// In ko, this message translates to:
  /// **'{seconds}초'**
  String walkAlarmSeconds(int seconds);

  /// 울림 설정 — 스누즈 간격 선택 제목
  ///
  /// In ko, this message translates to:
  /// **'스누즈 간격'**
  String get walkAlarmSnoozeInterval;

  /// 울림 설정 — 스누즈 최대 횟수 선택 제목
  ///
  /// In ko, this message translates to:
  /// **'스누즈 횟수'**
  String get walkAlarmSnoozeLimit;

  /// 스누즈 횟수 선택지 — 제한 없음
  ///
  /// In ko, this message translates to:
  /// **'무제한'**
  String get walkAlarmSnoozeUnlimited;

  /// 횟수 선택지(스누즈 횟수)
  ///
  /// In ko, this message translates to:
  /// **'{count}회'**
  String walkAlarmTimes(int count);

  /// 울림 설정 — 울리기 시작해 정한 시간이 지나면 스스로 멈추는 선택 제목
  ///
  /// In ko, this message translates to:
  /// **'자동 멈춤'**
  String get walkAlarmAutoStop;

  /// 자동 멈춤 선택지 — 쓰지 않음
  ///
  /// In ko, this message translates to:
  /// **'안 함'**
  String get walkAlarmAutoStopNever;

  /// 분 단위 선택지(스누즈 간격 · 자동 멈춤)
  ///
  /// In ko, this message translates to:
  /// **'{minutes}분'**
  String walkAlarmMinutes(int minutes);

  /// 울림 설정 — 울리기 30분 전 미리 알림 스위치
  ///
  /// In ko, this message translates to:
  /// **'30분 전에 알려 주기'**
  String get walkAlarmRemindBefore;

  /// 30분 전 미리 알림 스위치 설명
  ///
  /// In ko, this message translates to:
  /// **'알림에서 이번만 끌 수 있어요'**
  String get walkAlarmRemindBeforeHint;

  /// 반복 알람 행을 길게 누르면 뜨는 시트 — 다음 회차 하나를 건너뛴다
  ///
  /// In ko, this message translates to:
  /// **'다음 알람 건너뛰기'**
  String get walkAlarmSkipNext;

  /// 건너뛰기 시트 — 건너뛴 회차를 다시 울리게 한다
  ///
  /// In ko, this message translates to:
  /// **'건너뛰기 취소'**
  String get walkAlarmUnskip;

  /// 다음 회차를 건너뛴 반복 알람 행의 칩
  ///
  /// In ko, this message translates to:
  /// **'건너뜀'**
  String get walkAlarmSkipped;

  /// 다음 울림이 24시간 안 공휴일인 반복 알람 행의 칩(누르면 건너뛰기 시트)
  ///
  /// In ko, this message translates to:
  /// **'공휴일'**
  String get walkAlarmHolidayChip;

  /// 설정 탭 — 알람 섹션 제목
  ///
  /// In ko, this message translates to:
  /// **'알람'**
  String get walkSettingsAlarm;

  /// 설정 탭 — 반복 알람이 공휴일에 울리면 하루 전에 알리는 스위치
  ///
  /// In ko, this message translates to:
  /// **'공휴일 미리 알림'**
  String get walkSettingsHolidayReminder;

  /// 공휴일 미리 알림 스위치 설명
  ///
  /// In ko, this message translates to:
  /// **'반복 알람이 공휴일에 울리면 하루 전에 알려요'**
  String get walkSettingsHolidayReminderDescription;

  /// 설정 탭 — 공휴일을 어디서 읽는지 보이는 행 제목
  ///
  /// In ko, this message translates to:
  /// **'공휴일 출처'**
  String get walkSettingsHolidaySource;

  /// 공휴일 출처 — 폰 캘린더의 휴일 캘린더. name 은 캘린더 표시 이름
  ///
  /// In ko, this message translates to:
  /// **'폰 캘린더: {name}'**
  String walkSettingsHolidaySourceDevice(String name);

  /// 공휴일 출처 — 이름을 모르는 폰 캘린더
  ///
  /// In ko, this message translates to:
  /// **'폰 캘린더'**
  String get walkSettingsHolidaySourceDeviceUnnamed;

  /// 공휴일 출처 — 앱에 들어 있는 표. 연도는 그대로(쉼표 없이) 넣는다
  ///
  /// In ko, this message translates to:
  /// **'내장 표 {firstYear}–{lastYear}'**
  String walkSettingsHolidaySourceBundled(String firstYear, String lastYear);

  /// 공휴일 출처 행 — 캘린더 읽기 권한이 허용됨
  ///
  /// In ko, this message translates to:
  /// **'캘린더 허용됨'**
  String get walkSettingsCalendarGranted;

  /// 공휴일 출처 행 — 캘린더 읽기 권한이 없어 내장 표를 쓴다. 누르면 권한을 묻는다
  ///
  /// In ko, this message translates to:
  /// **'캘린더 허용 필요 ›'**
  String get walkSettingsCalendarNeedsPermission;

  /// 하단 탭 — 알람
  ///
  /// In ko, this message translates to:
  /// **'알람'**
  String get walkShellTabAlarm;

  /// 하단 탭 — 걸음
  ///
  /// In ko, this message translates to:
  /// **'걷기'**
  String get walkShellTabWalk;

  /// 하단 탭 — 설정
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get walkShellTabSettings;

  /// 하단 탭 — 일기
  ///
  /// In ko, this message translates to:
  /// **'일기'**
  String get walkShellTabDiary;

  /// 기본 스토리의 표시 이름 — 사용자가 이름을 바꾸지 않았을 때
  ///
  /// In ko, this message translates to:
  /// **'일상'**
  String get walkDiaryDailyStoryTitle;

  /// 일기 스토리 바 — 모든 스토리의 기록을 함께 보는 항목
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get walkDiaryAll;

  /// 일기 스토리 바 끝 — 닫힌 스토리 모음. 누르면 목록 시트가 열린다
  ///
  /// In ko, this message translates to:
  /// **'보관함'**
  String get walkDiaryArchive;

  /// 일기 타임라인에 보일 기록이 없을 때 안내
  ///
  /// In ko, this message translates to:
  /// **'아직 기록이 없어요'**
  String get walkDiaryEmpty;

  /// 일기 날짜 머리 — 오늘
  ///
  /// In ko, this message translates to:
  /// **'오늘'**
  String get walkDiaryToday;

  /// 일기 날짜 머리 — 어제
  ///
  /// In ko, this message translates to:
  /// **'어제'**
  String get walkDiaryYesterday;

  /// 일기 기록 시각 — 1분 안에 올린 기록
  ///
  /// In ko, this message translates to:
  /// **'지금'**
  String get walkDiaryNow;

  /// 일기 스토리 기간 — 아직 닫지 않은 스토리의 끝 자리
  ///
  /// In ko, this message translates to:
  /// **'진행 중'**
  String get walkDiaryOngoing;

  /// 일기 스토리 머리의 기간 — 시작일 ~ 끝난 날(또는 진행 중)
  ///
  /// In ko, this message translates to:
  /// **'{start} ~ {end}'**
  String walkDiaryStoryPeriod(String start, String end);

  /// 일기 보기 모드 — 날짜별로 글이 이어지는 줄글
  ///
  /// In ko, this message translates to:
  /// **'줄글'**
  String get walkDiaryViewProse;

  /// 일기 보기 모드 — 카드 세로 목록
  ///
  /// In ko, this message translates to:
  /// **'피드'**
  String get walkDiaryViewFeed;

  /// 일기 보기 모드 — 전체 화면으로 한 기록씩 넘기는 릴스
  ///
  /// In ko, this message translates to:
  /// **'릴스'**
  String get walkDiaryViewReels;

  /// 일기 피드 카드 — 접힌 긴 본문을 펼치는 버튼
  ///
  /// In ko, this message translates to:
  /// **'더 보기'**
  String get walkDiaryShowMore;

  /// 일기 기록의 장소 이름 표시
  ///
  /// In ko, this message translates to:
  /// **'📍 {name}'**
  String walkDiaryPlace(String name);

  /// 일기 기록의 해시태그 칩
  ///
  /// In ko, this message translates to:
  /// **'#{name}'**
  String walkDiaryTag(String name);

  /// 일기 기록의 사진 · 영상 중 지금 보이는 순번 / 전체 개수
  ///
  /// In ko, this message translates to:
  /// **'{index}/{count}'**
  String walkDiaryMediaPosition(int index, int count);

  /// 일기 타임라인을 읽지 못했을 때 안내
  ///
  /// In ko, this message translates to:
  /// **'기록을 불러오지 못했어요'**
  String get walkDiaryLoadError;

  /// 알람 목록 화면 제목
  ///
  /// In ko, this message translates to:
  /// **'알람'**
  String get walkAlarmListTitle;

  /// 알람 목록이 비었을 때 안내
  ///
  /// In ko, this message translates to:
  /// **'알람이 없어요'**
  String get walkAlarmEmpty;

  /// 알람 목록이 비었을 때 보조 설명
  ///
  /// In ko, this message translates to:
  /// **'+ 를 눌러 기상 알람을 추가하세요'**
  String get walkAlarmEmptyDescription;

  /// 새 알람 버튼(FAB) 툴팁
  ///
  /// In ko, this message translates to:
  /// **'알람 추가'**
  String get walkAlarmAdd;

  /// 알람 목록 맨 위 요약 카드 머리
  ///
  /// In ko, this message translates to:
  /// **'다음 알람'**
  String get walkAlarmNextTitle;

  /// 요약 카드 · 알람 행 — 다음 울림까지 남은 시간
  ///
  /// In ko, this message translates to:
  /// **'{duration} 뒤'**
  String walkAlarmIn(String duration);

  /// 요약 카드 — 알람은 있지만 모두 꺼졌을 때
  ///
  /// In ko, this message translates to:
  /// **'켜진 알람이 없어요'**
  String get walkAlarmNoneEnabled;

  /// 요약 카드 — 켜진 알람은 있는데 실제로 걸린 예약이 없을 때(권한 거부 등)
  ///
  /// In ko, this message translates to:
  /// **'예약된 알람이 없어요'**
  String get walkAlarmNoneScheduled;

  /// 요약 카드 둘째 줄 — 예약이 없는 이유가 대개 권한임을 알린다
  ///
  /// In ko, this message translates to:
  /// **'권한을 확인하세요'**
  String get walkAlarmNoneScheduledHint;

  /// 알람 탭 — 저장된 알람 목록을 읽지 못했을 때
  ///
  /// In ko, this message translates to:
  /// **'알람을 불러오지 못했어요'**
  String get walkAlarmLoadFailed;

  /// 요약 카드 날짜 — 오늘 울릴 때
  ///
  /// In ko, this message translates to:
  /// **'오늘'**
  String get walkAlarmDayToday;

  /// 요약 카드 날짜 — 내일 울릴 때
  ///
  /// In ko, this message translates to:
  /// **'내일'**
  String get walkAlarmDayTomorrow;

  /// 알람 저장 · 켜기 뒤 스낵바 — 울릴 때까지 남은 시간
  ///
  /// In ko, this message translates to:
  /// **'{duration} 뒤에 울려요'**
  String walkAlarmRingsIn(String duration);

  /// 알람 저장 · 켜기 뒤 스낵바 — 쉬는 기간 안의 회차뿐이라 울리지 않을 때
  ///
  /// In ko, this message translates to:
  /// **'쉬는 기간이라 울리지 않아요'**
  String get walkAlarmSavedPausedOut;

  /// 알람 목록 — 쉬는 기간 때문에 예약이 없는 알람 행의 표시(한 번 알람은 `한 번 · 쉬는 중`)
  ///
  /// In ko, this message translates to:
  /// **'쉬는 중'**
  String get walkAlarmPausedOutRow;

  /// 남은 시간 — 분만
  ///
  /// In ko, this message translates to:
  /// **'{minutes}분'**
  String walkAlarmDurationMinutes(int minutes);

  /// 남은 시간 — 시간만(분이 0)
  ///
  /// In ko, this message translates to:
  /// **'{hours}시간'**
  String walkAlarmDurationHours(int hours);

  /// 남은 시간 — 시간과 분
  ///
  /// In ko, this message translates to:
  /// **'{hours}시간 {minutes}분'**
  String walkAlarmDurationHoursMinutes(int hours, int minutes);

  /// 남은 시간 — 하루 이상, 시간이 0
  ///
  /// In ko, this message translates to:
  /// **'{days}일'**
  String walkAlarmDurationDays(int days);

  /// 남은 시간 — 하루 이상(분은 생략)
  ///
  /// In ko, this message translates to:
  /// **'{days}일 {hours}시간'**
  String walkAlarmDurationDaysHours(int days, int hours);

  /// 알림 · 정확한 알람 권한이 없을 때 목록 위 경고
  ///
  /// In ko, this message translates to:
  /// **'알람이 울리지 않을 수 있어요'**
  String get walkAlarmPermissionWarning;

  /// 권한 경고의 보조 설명 — 누르면 설정 탭으로 간다
  ///
  /// In ko, this message translates to:
  /// **'설정 탭에서 권한을 확인하세요'**
  String get walkAlarmPermissionWarningAction;

  /// 반복 요약 — 7일 모두
  ///
  /// In ko, this message translates to:
  /// **'매일'**
  String get walkAlarmRepeatDaily;

  /// 반복 요약 — 월~금
  ///
  /// In ko, this message translates to:
  /// **'평일'**
  String get walkAlarmRepeatWeekdays;

  /// 반복 요약 — 토 · 일
  ///
  /// In ko, this message translates to:
  /// **'주말'**
  String get walkAlarmRepeatWeekends;

  /// 반복 요약 — 반복 없음(한 번 울리고 꺼짐)
  ///
  /// In ko, this message translates to:
  /// **'1회'**
  String get walkAlarmRepeatOnce;

  /// 기존 알람 편집 화면 제목
  ///
  /// In ko, this message translates to:
  /// **'알람 수정'**
  String get walkAlarmEdit;

  /// 편집 화면 알람음 줄 · 알람음 선택 화면 제목
  ///
  /// In ko, this message translates to:
  /// **'알람음'**
  String get walkAlarmSound;

  /// 기기의 기본 알람음 이름
  ///
  /// In ko, this message translates to:
  /// **'시스템 기본'**
  String get walkAlarmSoundSystem;

  /// 알람음 선택 화면 — 앱 내장음 구역 제목
  ///
  /// In ko, this message translates to:
  /// **'앱 소리'**
  String get walkAlarmSoundBundledSection;

  /// 알람음 선택 화면 — 기기 알람음 구역 제목
  ///
  /// In ko, this message translates to:
  /// **'기기 알람음'**
  String get walkAlarmSoundDeviceSection;

  /// 앱 내장음 — 기존 비프음 이름
  ///
  /// In ko, this message translates to:
  /// **'비프'**
  String get walkAlarmSoundBeep;

  /// 앱 내장음 — 부드러운 2음 차임 이름
  ///
  /// In ko, this message translates to:
  /// **'차임'**
  String get walkAlarmSoundChime;

  /// 앱 내장음 — 간격이 점점 짧아지는 비프 이름
  ///
  /// In ko, this message translates to:
  /// **'점점 빠르게'**
  String get walkAlarmSoundRising;

  /// 알람음 선택 화면 아래 확인 버튼
  ///
  /// In ko, this message translates to:
  /// **'선택'**
  String get walkAlarmSoundSelect;

  /// 기기 알람음 목록을 읽지 못했거나 비었을 때 구역 안내
  ///
  /// In ko, this message translates to:
  /// **'기기 알람음을 불러오지 못했어요'**
  String get walkAlarmSoundDeviceUnavailable;

  /// 기기 알람음 복사 · 검증 실패 스낵바
  ///
  /// In ko, this message translates to:
  /// **'이 알람음을 쓸 수 없어요'**
  String get walkAlarmSoundImportFailed;

  /// 알람 삭제 확인 다이얼로그 제목
  ///
  /// In ko, this message translates to:
  /// **'알람을 삭제할까요?'**
  String get walkAlarmDeleteTitle;

  /// 알람 삭제 확인 다이얼로그 본문
  ///
  /// In ko, this message translates to:
  /// **'삭제한 알람은 되돌릴 수 없어요'**
  String get walkAlarmDeleteContent;

  /// 알람 메뉴 시트 · 편집 화면 앱바 메뉴의 알람 복제 항목
  ///
  /// In ko, this message translates to:
  /// **'복제'**
  String get walkAlarmDuplicate;

  /// 알람 탭 앱바 쉬기 아이콘 툴팁 · 쉬기 시트 제목
  ///
  /// In ko, this message translates to:
  /// **'알람 쉬기'**
  String get walkAlarmPause;

  /// 쉬기 시트 안내 — 기간 동안 모든 알람이 빠지고 스위치는 그대로
  ///
  /// In ko, this message translates to:
  /// **'고른 기간에는 모든 알람이 울리지 않아요. 스위치는 그대로예요.'**
  String get walkAlarmPauseDescription;

  /// 쉬기 시트 빠른 기간 — 오늘 하루
  ///
  /// In ko, this message translates to:
  /// **'오늘만'**
  String get walkAlarmPauseToday;

  /// 쉬기 시트 빠른 기간 — 오늘부터 내일까지
  ///
  /// In ko, this message translates to:
  /// **'내일까지'**
  String get walkAlarmPauseUntilTomorrow;

  /// 쉬기 시트 빠른 기간 — 이번 토 · 일
  ///
  /// In ko, this message translates to:
  /// **'이번 주말'**
  String get walkAlarmPauseWeekend;

  /// 쉬기 시트 — 기간 달력을 여는 항목
  ///
  /// In ko, this message translates to:
  /// **'날짜 고르기'**
  String get walkAlarmPausePickDates;

  /// 알람 탭 쉬는 중 배너 — 이미 쉬기 시작했을 때. until 은 '10월 12일 (월)' 같은 날
  ///
  /// In ko, this message translates to:
  /// **'{until}까지 알람을 쉬어요'**
  String walkAlarmPausedUntil(String until);

  /// 알람 탭 쉬는 중 배너 — 시작 날이 아직 오지 않았을 때
  ///
  /// In ko, this message translates to:
  /// **'{from}부터 {until}까지 알람을 쉬어요'**
  String walkAlarmPausedRange(String from, String until);

  /// 쉬는 중 배너 버튼 — 쉬는 기간을 지운다
  ///
  /// In ko, this message translates to:
  /// **'그만 쉬기'**
  String get walkAlarmPauseStop;

  /// 알람 탭 앱바 기록 아이콘 툴팁 · 울림 기록 화면 제목
  ///
  /// In ko, this message translates to:
  /// **'울림 기록'**
  String get walkAlarmHistory;

  /// 울림 기록 화면 — 최근 30일 기록이 없을 때 제목
  ///
  /// In ko, this message translates to:
  /// **'아직 기록이 없어요'**
  String get walkAlarmHistoryEmpty;

  /// 울림 기록 화면 — 빈 상태 설명
  ///
  /// In ko, this message translates to:
  /// **'알람이 울리고 꺼지면 여기에 30일 동안 남아요'**
  String get walkAlarmHistoryEmptyHint;

  /// 울림 기록 화면 — 읽기 실패
  ///
  /// In ko, this message translates to:
  /// **'기록을 불러오지 못했어요'**
  String get walkAlarmHistoryLoadFailed;

  /// 울림 기록 한 줄 — 처음 울린 시각. time 은 '오전 7:00'
  ///
  /// In ko, this message translates to:
  /// **'{time} 울림'**
  String walkAlarmHistoryRang(String time);

  /// 울림 기록 한 줄 — 그 회차에서 스누즈한 횟수
  ///
  /// In ko, this message translates to:
  /// **'스누즈 {count}번'**
  String walkAlarmHistorySnoozes(int count);

  /// 울림 기록 한 줄 — 사용자가 끈 시각
  ///
  /// In ko, this message translates to:
  /// **'{time} 끔'**
  String walkAlarmHistoryStopped(String time);

  /// 울림 기록 한 줄 — 자동 멈춤 설정으로 스스로 멈춘 시각
  ///
  /// In ko, this message translates to:
  /// **'{time} 자동 멈춤'**
  String walkAlarmHistoryAutoStopped(String time);

  /// 울림 기록 — 지금은 지운 알람의 회차 제목
  ///
  /// In ko, this message translates to:
  /// **'지운 알람'**
  String get walkAlarmHistoryDeleted;

  /// 알람 저장 · 삭제 · 켜기 실패 스낵바
  ///
  /// In ko, this message translates to:
  /// **'알람을 저장하지 못했어요'**
  String get walkAlarmSaveFailed;

  /// 알람 종류 시트 제목
  ///
  /// In ko, this message translates to:
  /// **'어떤 알람을 만들까요'**
  String get walkAlarmKindTitle;

  /// 알람 종류 시트 — 한 번 울리는 알람
  ///
  /// In ko, this message translates to:
  /// **'한 번'**
  String get walkAlarmKindOneShot;

  /// 알람 종류 시트 — 한 번 알람 설명
  ///
  /// In ko, this message translates to:
  /// **'지금부터 얼마 뒤에 울려요'**
  String get walkAlarmKindOneShotHint;

  /// 알람 종류 시트 — 요일마다 울리는 알람
  ///
  /// In ko, this message translates to:
  /// **'반복'**
  String get walkAlarmKindRepeat;

  /// 알람 종류 시트 — 반복 알람 설명
  ///
  /// In ko, this message translates to:
  /// **'정한 요일마다 울려요'**
  String get walkAlarmKindRepeatHint;

  /// 새 한 번 알람 편집 화면 제목
  ///
  /// In ko, this message translates to:
  /// **'한 번 알람'**
  String get walkAlarmNewOneShot;

  /// 새 반복 알람 편집 화면 제목
  ///
  /// In ko, this message translates to:
  /// **'반복 알람'**
  String get walkAlarmNewRepeat;

  /// 한 번 알람 편집 — 울릴 때까지 남은 시간(큰 글자)
  ///
  /// In ko, this message translates to:
  /// **'{duration} 뒤'**
  String walkAlarmAfter(String duration);

  /// 한 번 알람 편집 — 울릴 시각 칩. 누르면 시각을 직접 고른다
  ///
  /// In ko, this message translates to:
  /// **'{time}에 울림'**
  String walkAlarmRingsAtChip(String time);

  /// 시각 휠 — 시 열 한 칸의 화면 읽기 라벨. 분과 어긋나지 않게 '정각'을 붙이지 않는다
  ///
  /// In ko, this message translates to:
  /// **'{hour}시'**
  String walkAlarmWheelHourSemantics(int hour);

  /// 한 번 알람 편집 — 시간 더하기 버튼
  ///
  /// In ko, this message translates to:
  /// **'+{hours}시간'**
  String walkAlarmAddHour(int hours);

  /// 한 번 알람 편집 — 분 더하기 버튼
  ///
  /// In ko, this message translates to:
  /// **'+{minutes}분'**
  String walkAlarmAddMinutes(int minutes);

  /// 한 번 알람 편집 — 남은 시간을 0 으로
  ///
  /// In ko, this message translates to:
  /// **'초기화'**
  String get walkAlarmReset;

  /// 한 번 알람 편집 — 1분 미만이라 저장할 수 없을 때 안내
  ///
  /// In ko, this message translates to:
  /// **'시간을 더해 주세요'**
  String get walkAlarmNeedTime;

  /// 반복 알람 편집 — 요일이 없어 저장할 수 없을 때 안내
  ///
  /// In ko, this message translates to:
  /// **'요일을 골라 주세요'**
  String get walkAlarmNeedDays;

  /// 한 번 알람 편집 — 시각 휠 시트의 확인 버튼
  ///
  /// In ko, this message translates to:
  /// **'이 시각으로'**
  String get walkAlarmPickTimeConfirm;

  /// 반복 알람 편집 — 빠른 버튼(월~일)
  ///
  /// In ko, this message translates to:
  /// **'매일'**
  String get walkAlarmPresetEveryday;

  /// 반복 알람 편집 — 빠른 버튼(월~금)
  ///
  /// In ko, this message translates to:
  /// **'평일'**
  String get walkAlarmPresetWeekdays;

  /// 반복 알람 편집 — 빠른 버튼(토 · 일)
  ///
  /// In ko, this message translates to:
  /// **'주말'**
  String get walkAlarmPresetWeekend;

  /// 알람 편집 — 제목 입력
  ///
  /// In ko, this message translates to:
  /// **'제목'**
  String get walkAlarmTitle;

  /// 알람 편집 — 제목 입력 힌트
  ///
  /// In ko, this message translates to:
  /// **'예: 출근'**
  String get walkAlarmTitleHint;

  /// 알람 편집 — 무음 모드 체크 줄
  ///
  /// In ko, this message translates to:
  /// **'무음 · 진동 모드에선 진동만'**
  String get walkAlarmSilentWhenMuted;

  /// 알람 편집 — 무음 모드 체크 줄 보조 설명
  ///
  /// In ko, this message translates to:
  /// **'폰이 무음이나 진동 모드면 소리 없이 진동으로 울려요'**
  String get walkAlarmSilentWhenMutedHint;

  /// 알람 목록 — 한 번 알람 행의 남은 시간 줄
  ///
  /// In ko, this message translates to:
  /// **'한 번 · {remaining}'**
  String walkAlarmOneShotRow(String remaining);

  /// 설정 화면 제목
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get walkSettingsTitle;

  /// 설정 — 권한 섹션 제목
  ///
  /// In ko, this message translates to:
  /// **'권한'**
  String get walkSettingsPermissions;

  /// 설정 — 알림 권한 행
  ///
  /// In ko, this message translates to:
  /// **'알림'**
  String get walkSettingsNotification;

  /// 설정 — 알림 권한 설명
  ///
  /// In ko, this message translates to:
  /// **'알람 알림과 끄기 버튼을 보여줘요'**
  String get walkSettingsNotificationDescription;

  /// 설정 — 정확한 알람(SCHEDULE_EXACT_ALARM) 권한 행
  ///
  /// In ko, this message translates to:
  /// **'정확한 알람'**
  String get walkSettingsExactAlarm;

  /// 설정 — 정확한 알람 권한 설명
  ///
  /// In ko, this message translates to:
  /// **'정한 시각에 정확히 울려요'**
  String get walkSettingsExactAlarmDescription;

  /// 설정 — 전체 화면 알림(USE_FULL_SCREEN_INTENT) 권한 행
  ///
  /// In ko, this message translates to:
  /// **'전체 화면 알림'**
  String get walkSettingsFullScreen;

  /// 설정 — 전체 화면 알림 권한 설명
  ///
  /// In ko, this message translates to:
  /// **'잠금 화면에서 알람 화면을 띄워요'**
  String get walkSettingsFullScreenDescription;

  /// 설정 — Health Connect 권한 행
  ///
  /// In ko, this message translates to:
  /// **'Health Connect'**
  String get walkSettingsHealthConnect;

  /// 설정 — Health Connect 권한 설명
  ///
  /// In ko, this message translates to:
  /// **'걸음 기록을 읽어요'**
  String get walkSettingsHealthConnectDescription;

  /// 권한 상태 — 허용됨
  ///
  /// In ko, this message translates to:
  /// **'허용됨'**
  String get walkSettingsGranted;

  /// 권한 상태 — 거부됨(누르면 설정을 연다)
  ///
  /// In ko, this message translates to:
  /// **'허용 필요 ›'**
  String get walkSettingsNeedsPermission;

  /// Health Connect 상태 — 설치 안 됨
  ///
  /// In ko, this message translates to:
  /// **'설치 필요 ›'**
  String get walkSettingsNeedsInstall;

  /// Health Connect 상태 — 업데이트 필요
  ///
  /// In ko, this message translates to:
  /// **'업데이트 필요 ›'**
  String get walkSettingsNeedsUpdate;

  /// 설정 — 테마 섹션 제목
  ///
  /// In ko, this message translates to:
  /// **'테마'**
  String get walkSettingsTheme;

  /// 테마 — 기기 설정을 따름
  ///
  /// In ko, this message translates to:
  /// **'시스템 설정'**
  String get walkSettingsThemeSystem;

  /// 테마 — 밝게
  ///
  /// In ko, this message translates to:
  /// **'라이트'**
  String get walkSettingsThemeLight;

  /// 테마 — 어둡게
  ///
  /// In ko, this message translates to:
  /// **'다크'**
  String get walkSettingsThemeDark;

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
  String get pawlogAppTitle;

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

  /// 진행 화면 앱바 제목
  ///
  /// In ko, this message translates to:
  /// **'산책 중'**
  String get walkActiveTitle;

  /// 진행 화면에서 반려견을 고르는(시작 전) 동안의 앱바 제목
  ///
  /// In ko, this message translates to:
  /// **'산책 준비'**
  String get walkReadyTitle;

  /// 진행 화면에서 산책에 데려갈 반려견을 고르는 칩 목록의 제목
  ///
  /// In ko, this message translates to:
  /// **'함께 걷는 반려견'**
  String get walkSelectDogs;

  /// 산책 시작 버튼 라벨
  ///
  /// In ko, this message translates to:
  /// **'산책 시작'**
  String get walkStart;

  /// 산책 종료 버튼 · 종료 확인 다이얼로그 확인 버튼 라벨
  ///
  /// In ko, this message translates to:
  /// **'산책 종료'**
  String get walkStop;

  /// 산책 종료 확인 다이얼로그 제목
  ///
  /// In ko, this message translates to:
  /// **'산책을 끝낼까요?'**
  String get walkStopConfirmTitle;

  /// 산책 종료 확인 다이얼로그 본문
  ///
  /// In ko, this message translates to:
  /// **'기록을 멈추고 저장 화면으로 이동합니다.'**
  String get walkStopConfirmMessage;

  /// 진행 화면 경과 시간 칸의 라벨
  ///
  /// In ko, this message translates to:
  /// **'시간'**
  String get walkElapsedLabel;

  /// 진행 화면 이동 거리 칸의 라벨
  ///
  /// In ko, this message translates to:
  /// **'거리'**
  String get walkDistanceLabel;

  /// 1 km 미만 거리 표기. meters 는 반올림한 미터
  ///
  /// In ko, this message translates to:
  /// **'{meters} m'**
  String walkDistanceMeters(int meters);

  /// 1 km 이상 거리 표기. km 는 소수 1자리로 포맷한 문자열
  ///
  /// In ko, this message translates to:
  /// **'{km} km'**
  String walkDistanceKm(String km);

  /// 1시간 미만 산책 시간 표기
  ///
  /// In ko, this message translates to:
  /// **'{minutes}분'**
  String walkDurationMinutes(int minutes);

  /// 1분이 안 되는 산책 시간 표기(0분 대신)
  ///
  /// In ko, this message translates to:
  /// **'1분 미만'**
  String get walkDurationUnderMinute;

  /// 분이 0인 1시간 이상 산책 시간 표기
  ///
  /// In ko, this message translates to:
  /// **'{hours}시간'**
  String walkDurationHours(int hours);

  /// 1시간 이상 산책 시간 표기
  ///
  /// In ko, this message translates to:
  /// **'{hours}시간 {minutes}분'**
  String walkDurationHoursMinutes(int hours, int minutes);

  /// Android 포그라운드 서비스 알림 제목
  ///
  /// In ko, this message translates to:
  /// **'산책을 기록하고 있어요'**
  String get walkTrackingNotificationTitle;

  /// Android 포그라운드 서비스 알림 본문
  ///
  /// In ko, this message translates to:
  /// **'앱을 닫아도 경로가 계속 기록됩니다'**
  String get walkTrackingNotificationText;

  /// 산책 시작 화면에서 등록된 반려견이 없을 때 안내 제목
  ///
  /// In ko, this message translates to:
  /// **'먼저 반려견을 등록해 주세요'**
  String get walkActiveNoDogsTitle;

  /// 산책 시작 화면에서 등록된 반려견이 없을 때 안내 본문
  ///
  /// In ko, this message translates to:
  /// **'산책에는 반려견이 한 마리 이상 필요합니다'**
  String get walkActiveNoDogsMessage;

  /// 반려견 등록 화면으로 가는 버튼 라벨
  ///
  /// In ko, this message translates to:
  /// **'반려견 등록하기'**
  String get walkOpenDogsAction;

  /// 위치 권한 거부 실패 안내 아래에 붙는 보조 설명
  ///
  /// In ko, this message translates to:
  /// **'설정에서 위치 권한을 허용한 뒤 다시 시도해 주세요'**
  String get walkLocationDeniedHint;

  /// 추적 중 위치 오류 안내 아래에 붙는 보조 설명
  ///
  /// In ko, this message translates to:
  /// **'산책 기록은 이어집니다. 다시 시도하면 위치를 다시 받아요'**
  String get walkLocationLostHint;

  /// 위치 서비스 꺼짐 실패 안내 아래에 붙는 보조 설명
  ///
  /// In ko, this message translates to:
  /// **'위치 서비스를 켠 뒤 다시 시도해 주세요'**
  String get walkLocationServiceHint;

  /// 위치 서비스가 꺼져 있을 때 기기 위치 설정을 여는 버튼 라벨
  ///
  /// In ko, this message translates to:
  /// **'위치 설정 열기'**
  String get walkOpenLocationSettings;

  /// 추적은 시작했지만 아직 GPS 점이 없을 때 지도 자리에 보이는 문구
  ///
  /// In ko, this message translates to:
  /// **'위치를 찾는 중…'**
  String get walkLocating;

  /// 산책 저장 화면(방금 끝낸 산책) 앱 바 제목
  ///
  /// In ko, this message translates to:
  /// **'산책 저장'**
  String get walkEditNewTitle;

  /// 저장된 산책을 고치는 화면 앱 바 제목
  ///
  /// In ko, this message translates to:
  /// **'산책 수정'**
  String get walkEditTitle;

  /// 산책 메모 입력란 라벨
  ///
  /// In ko, this message translates to:
  /// **'메모'**
  String get walkMemoLabel;

  /// 산책 메모 입력란 힌트
  ///
  /// In ko, this message translates to:
  /// **'오늘 산책은 어땠나요?'**
  String get walkMemoHint;

  /// 산책 사진 절 제목
  ///
  /// In ko, this message translates to:
  /// **'사진'**
  String get walkPhotosLabel;

  /// 사진 띠 끝의 추가 칸 라벨
  ///
  /// In ko, this message translates to:
  /// **'사진 추가'**
  String get walkAddPhoto;

  /// 사진 띠 썸네일의 빼기 버튼 스크린 리더 라벨
  ///
  /// In ko, this message translates to:
  /// **'사진 삭제'**
  String get walkRemovePhoto;

  /// 사진 추가 시트의 앨범 선택 항목
  ///
  /// In ko, this message translates to:
  /// **'앨범에서 고르기'**
  String get walkAddPhotoFromGallery;

  /// 사진 추가 시트의 카메라 촬영 항목
  ///
  /// In ko, this message translates to:
  /// **'카메라로 찍기'**
  String get walkAddPhotoFromCamera;

  /// 사진이 최대 장수에 닿았을 때 추가 칸 대신 보이는 안내
  ///
  /// In ko, this message translates to:
  /// **'사진은 최대 10장까지 붙일 수 있어요'**
  String get walkPhotoLimitReached;

  /// 방금 끝낸 산책을 저장하지 않고 버리는 버튼과 확인 버튼 라벨
  ///
  /// In ko, this message translates to:
  /// **'버리기'**
  String get walkDiscard;

  /// 산책 버리기 확인 다이얼로그 제목
  ///
  /// In ko, this message translates to:
  /// **'이 산책을 버릴까요?'**
  String get walkDiscardConfirmTitle;

  /// 산책 버리기 확인 다이얼로그 본문
  ///
  /// In ko, this message translates to:
  /// **'경로와 붙인 사진이 모두 지워집니다.'**
  String get walkDiscardConfirmMessage;

  /// 저장 화면에 들어왔지만 끝난 산책 세션이 없을 때 안내
  ///
  /// In ko, this message translates to:
  /// **'저장할 산책이 없습니다'**
  String get walkNoSessionToSave;

  /// 저장할 산책이 없을 때 피드로 가는 버튼 라벨
  ///
  /// In ko, this message translates to:
  /// **'피드로 돌아가기'**
  String get walkBackToFeed;

  /// 산책 상세 화면 앱 바 제목
  ///
  /// In ko, this message translates to:
  /// **'산책 기록'**
  String get walkDetailTitle;

  /// 산책 상세 더보기 메뉴의 수정 항목
  ///
  /// In ko, this message translates to:
  /// **'수정'**
  String get walkEdit;

  /// 산책 삭제 확인 다이얼로그 제목
  ///
  /// In ko, this message translates to:
  /// **'산책 기록을 삭제할까요?'**
  String get walkDeleteConfirmTitle;

  /// 산책 삭제 확인 다이얼로그 본문
  ///
  /// In ko, this message translates to:
  /// **'경로와 사진이 함께 삭제됩니다.'**
  String get walkDeleteConfirmMessage;

  /// 산책 상세에서 경로 점이 하나도 없을 때 지도 자리 문구
  ///
  /// In ko, this message translates to:
  /// **'기록된 경로가 없습니다'**
  String get walkNoTrack;

  /// 산책 상세의 반려견 절 제목
  ///
  /// In ko, this message translates to:
  /// **'함께한 반려견'**
  String get walkDogsLabel;

  /// 산책 날짜 라벨
  ///
  /// In ko, this message translates to:
  /// **'날짜'**
  String get walkDateLabel;

  /// 피드가 비어 있을 때 안내 제목
  ///
  /// In ko, this message translates to:
  /// **'첫 산책을 시작해 보세요'**
  String get walkFeedEmptyTitle;

  /// 피드가 비어 있을 때 안내 본문
  ///
  /// In ko, this message translates to:
  /// **'산책을 마치면 여기에 기록이 쌓입니다'**
  String get walkFeedEmptyMessage;

  /// 피드가 비어 있지만 산책을 기록 중이거나 저장 전일 때 안내 제목
  ///
  /// In ko, this message translates to:
  /// **'첫 산책이 곧 여기에 보여요'**
  String get walkFeedEmptyActiveTitle;

  /// 피드가 비어 있지만 산책을 기록 중이거나 저장 전일 때 안내 본문
  ///
  /// In ko, this message translates to:
  /// **'위 배너에서 산책을 마치고 저장해 주세요'**
  String get walkFeedEmptyActiveMessage;

  /// 진행 중인 산책으로 돌아가는 피드의 버튼 라벨
  ///
  /// In ko, this message translates to:
  /// **'산책 계속'**
  String get walkContinue;

  /// 피드 상단의 산책 중 배너 문구
  ///
  /// In ko, this message translates to:
  /// **'산책 중이에요 · 눌러서 돌아가기'**
  String get walkInProgressBanner;

  /// 피드 상단의 저장하지 않은 산책 배너 문구
  ///
  /// In ko, this message translates to:
  /// **'저장하지 않은 산책이 있어요 · 눌러서 저장하기'**
  String get walkUnsavedBanner;

  /// 피드 앱 바의 반려견 목록 버튼 툴팁
  ///
  /// In ko, this message translates to:
  /// **'반려견'**
  String get walkOpenDogsTooltip;

  /// 일기 잠금 화면 제목
  ///
  /// In ko, this message translates to:
  /// **'일기가 잠겨 있어요'**
  String get walkLockTitle;

  /// 일기 잠금 화면에서 PIN 입력 안내
  ///
  /// In ko, this message translates to:
  /// **'PIN 4자리를 입력하세요'**
  String get walkLockEnterPin;

  /// 일기 잠금 화면에서 패턴 입력 안내
  ///
  /// In ko, this message translates to:
  /// **'패턴을 그리세요'**
  String get walkLockEnterPattern;

  /// 일기 잠금 해제 시 PIN · 패턴이 틀렸을 때 안내
  ///
  /// In ko, this message translates to:
  /// **'맞지 않아요. 다시 해 보세요'**
  String get walkLockWrong;

  /// 일기 잠금 해제를 5회 틀려 잠시 막혔을 때 남은 초 안내
  ///
  /// In ko, this message translates to:
  /// **'{seconds}초 뒤에 다시 시도할 수 있어요'**
  String walkLockBlocked(int seconds);

  /// 폰 인증 실패로 일기 잠금 해제가 24시간 막혔을 때 남은 시간 안내
  ///
  /// In ko, this message translates to:
  /// **'폰 인증에 실패했어요. {hours}시간 {minutes}분 뒤에 다시 시도할 수 있어요'**
  String walkLockBlockedLong(int hours, int minutes);

  /// 일기 잠금 화면에서 폰 인증으로 PIN · 패턴을 재설정하는 버튼
  ///
  /// In ko, this message translates to:
  /// **'잊어버렸어요'**
  String get walkLockForgot;

  /// 일기 잠금 재설정 시 폰 인증 창에 보이는 이유 문구
  ///
  /// In ko, this message translates to:
  /// **'일기 잠금을 다시 설정하려면 본인 확인이 필요해요'**
  String get walkLockDeviceReason;

  /// 일기 잠금 재설정 시 폰 인증 창을 띄울 수 없을 때 안내
  ///
  /// In ko, this message translates to:
  /// **'지금은 폰 인증을 쓸 수 없어요. 폰 화면 잠금 설정을 확인해 주세요'**
  String get walkLockDeviceUnavailable;

  /// PIN 입력 키패드의 마지막 숫자 지우기 버튼
  ///
  /// In ko, this message translates to:
  /// **'지우기'**
  String get walkLockPinDelete;

  /// 일기 잠금 설정 화면 제목
  ///
  /// In ko, this message translates to:
  /// **'일기 잠금'**
  String get walkLockSetupTitle;

  /// 일기 잠금 설정에서 방식 고르기 안내
  ///
  /// In ko, this message translates to:
  /// **'잠금 방식을 고르세요'**
  String get walkLockSetupChoose;

  /// 일기 잠금 방식 PIN 버튼 라벨
  ///
  /// In ko, this message translates to:
  /// **'PIN 4자리'**
  String get walkLockSetupPin;

  /// 일기 잠금 방식 패턴 버튼 라벨
  ///
  /// In ko, this message translates to:
  /// **'패턴'**
  String get walkLockSetupPattern;

  /// 일기 잠금 설정에서 지금 쓰는 방식 버튼 라벨
  ///
  /// In ko, this message translates to:
  /// **'{method} (사용 중)'**
  String walkLockSetupInUse(String method);

  /// 일기 잠금을 끄는 버튼 라벨
  ///
  /// In ko, this message translates to:
  /// **'잠금 끄기'**
  String get walkLockSetupOff;

  /// 일기 잠금을 끄거나 방식을 바꾸기 전 현재 비밀 확인 안내
  ///
  /// In ko, this message translates to:
  /// **'지금 쓰는 PIN · 패턴을 입력하세요'**
  String get walkLockSetupVerify;

  /// 일기 잠금 새 PIN 첫 입력 안내
  ///
  /// In ko, this message translates to:
  /// **'새 PIN 4자리를 입력하세요'**
  String get walkLockSetupNewPin;

  /// 일기 잠금 새 패턴 첫 입력 안내
  ///
  /// In ko, this message translates to:
  /// **'점 4개 이상을 이어 새 패턴을 그리세요'**
  String get walkLockSetupNewPattern;

  /// 일기 잠금 새 PIN · 패턴 확인 입력 안내
  ///
  /// In ko, this message translates to:
  /// **'확인을 위해 한 번 더 입력하세요'**
  String get walkLockSetupConfirm;

  /// 일기 잠금 확인 입력이 첫 입력과 다를 때 오류
  ///
  /// In ko, this message translates to:
  /// **'처음 입력과 달라요. 처음부터 다시 입력하세요'**
  String get walkLockSetupMismatch;

  /// 일기 잠금 패턴 점이 4개보다 적을 때 오류
  ///
  /// In ko, this message translates to:
  /// **'점을 4개 이상 이어 주세요'**
  String get walkLockSetupTooShort;

  /// 일기 잠금 새 PIN 이 숫자 4자리가 아닐 때 오류
  ///
  /// In ko, this message translates to:
  /// **'숫자 4자리를 입력해 주세요'**
  String get walkLockSetupPinInvalid;

  /// 일기 잠금 켜기 · 끄기 · 방식 변경을 마쳤을 때 알림
  ///
  /// In ko, this message translates to:
  /// **'일기 잠금 설정을 저장했어요'**
  String get walkLockSetupSaved;

  /// 폰에 화면 잠금이 없어 일기 잠금을 켤 수 없을 때 안내
  ///
  /// In ko, this message translates to:
  /// **'폰 화면 잠금을 먼저 설정해야 일기 잠금을 켤 수 있어요'**
  String get walkLockNeedsScreenLock;

  /// 화면 잠금이 없을 때 폰의 화면 잠금 설정 화면을 여는 버튼
  ///
  /// In ko, this message translates to:
  /// **'화면 잠금 설정 열기'**
  String get walkLockOpenScreenLockSettings;

  /// 일기 작성 화면 제목 · 일기 탭의 새 기록 버튼 툴팁
  ///
  /// In ko, this message translates to:
  /// **'새 기록'**
  String get walkDiaryEditorNewTitle;

  /// 일기 기록 수정 화면 제목
  ///
  /// In ko, this message translates to:
  /// **'기록 고치기'**
  String get walkDiaryEditorEditTitle;

  /// 새 일기 기록을 저장하는 버튼
  ///
  /// In ko, this message translates to:
  /// **'올리기'**
  String get walkDiaryEditorPost;

  /// 고친 일기 기록을 저장하는 버튼
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get walkDiaryEditorSave;

  /// 일기 작성 화면을 닫는 ✕ 버튼 툴팁
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get walkDiaryEditorClose;

  /// 일기 작성 시각 행 — 시각을 바꾸지 않았을 때. when 은 '10월 10일 (토) 오후 3:24'
  ///
  /// In ko, this message translates to:
  /// **'지금 · {when}'**
  String walkDiaryEditorTimeNow(String when);

  /// 일기 작성 시각 행의 날짜와 시각
  ///
  /// In ko, this message translates to:
  /// **'{date} {time}'**
  String walkDiaryEditorDateTime(String date, String time);

  /// 일기 기록 시각을 바꿨을 때 처음 시각으로 되돌리는 버튼
  ///
  /// In ko, this message translates to:
  /// **'올린 시각으로 되돌리기'**
  String get walkDiaryEditorRevertTime;

  /// 일기 기록 시각 휠 시트의 확인 버튼
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get walkDiaryEditorPickTimeConfirm;

  /// 일기 작성 화면에서 지금 위치를 찾는 동안 안내
  ///
  /// In ko, this message translates to:
  /// **'위치를 찾는 중…'**
  String get walkDiaryEditorLocating;

  /// 좌표만 있고 장소 이름을 못 찾았을 때 위치 행 문구
  ///
  /// In ko, this message translates to:
  /// **'이름 없는 위치'**
  String get walkDiaryEditorUnnamedPlace;

  /// 일기 작성 화면 위치 행의 ✕ 버튼 툴팁
  ///
  /// In ko, this message translates to:
  /// **'위치 빼기'**
  String get walkDiaryEditorRemoveLocation;

  /// 일기 작성 화면 장소 직접 입력칸 힌트
  ///
  /// In ko, this message translates to:
  /// **'장소 이름'**
  String get walkDiaryEditorPlaceHint;

  /// 일기 작성 화면 스토리 행
  ///
  /// In ko, this message translates to:
  /// **'스토리: {title}'**
  String walkDiaryEditorStory(String title);

  /// 일기 작성 화면 스토리 선택 시트 제목
  ///
  /// In ko, this message translates to:
  /// **'스토리 고르기'**
  String get walkDiaryEditorPickStory;

  /// 일기 작성 화면 미디어 추가 버튼
  ///
  /// In ko, this message translates to:
  /// **'사진·영상 추가'**
  String get walkDiaryEditorAddMedia;

  /// 일기 작성 화면 미디어 썸네일의 ✕ 버튼 툴팁
  ///
  /// In ko, this message translates to:
  /// **'빼기'**
  String get walkDiaryEditorRemoveMedia;

  /// 일기 미디어 추가 시트 — 앨범에서 사진 · 영상 고르기
  ///
  /// In ko, this message translates to:
  /// **'앨범에서 고르기'**
  String get walkDiaryEditorPickGallery;

  /// 일기 미디어 추가 시트 — 카메라로 사진 찍기
  ///
  /// In ko, this message translates to:
  /// **'사진 찍기'**
  String get walkDiaryEditorTakePhoto;

  /// 일기 미디어 추가 시트 — 카메라로 영상 찍기
  ///
  /// In ko, this message translates to:
  /// **'영상 찍기'**
  String get walkDiaryEditorTakeVideo;

  /// 일기 작성 화면 본문 입력칸 힌트
  ///
  /// In ko, this message translates to:
  /// **'오늘 있었던 일을 적어 보세요'**
  String get walkDiaryEditorBodyHint;

  /// 일기 작성 화면 태그 입력칸 힌트
  ///
  /// In ko, this message translates to:
  /// **'태그 추가'**
  String get walkDiaryEditorTagHint;

  /// 일기 작성 중 닫을 때 확인 다이얼로그 제목
  ///
  /// In ko, this message translates to:
  /// **'작성을 그만둘까요?'**
  String get walkDiaryEditorDiscardTitle;

  /// 일기 작성 중 닫을 때 확인 다이얼로그 본문
  ///
  /// In ko, this message translates to:
  /// **'쓴 내용은 저장되지 않아요.'**
  String get walkDiaryEditorDiscardContent;

  /// 일기 작성 중 닫을 때 확인 다이얼로그의 버리기 버튼
  ///
  /// In ko, this message translates to:
  /// **'그만두기'**
  String get walkDiaryEditorDiscardConfirm;

  /// 빈 일기 기록을 저장하려 할 때 오류
  ///
  /// In ko, this message translates to:
  /// **'글이나 사진·영상을 넣어 주세요'**
  String get walkDiaryErrorEmptyEntry;

  /// 일기 기록 시각이 미래일 때 오류
  ///
  /// In ko, this message translates to:
  /// **'앞으로의 시각으로는 쓸 수 없어요'**
  String get walkDiaryErrorFutureTime;

  /// 일기 기록 하나에 미디어 개수 제한을 넘었을 때 오류
  ///
  /// In ko, this message translates to:
  /// **'사진·영상은 {max}개까지 넣을 수 있어요'**
  String walkDiaryErrorTooManyMedia(int max);

  /// 일기에 넣으려는 영상이 길이 제한을 넘었을 때 오류
  ///
  /// In ko, this message translates to:
  /// **'{seconds}초 이하 영상만 넣을 수 있어요'**
  String walkDiaryErrorVideoTooLong(int seconds);

  /// 닫힌 스토리로 일기 기록을 저장하려 할 때 오류
  ///
  /// In ko, this message translates to:
  /// **'닫힌 스토리에는 쓸 수 없어요'**
  String get walkDiaryErrorStoryClosed;

  /// 고치려는 일기 기록이 없거나 휴지통에 있을 때 오류
  ///
  /// In ko, this message translates to:
  /// **'기록을 찾을 수 없어요'**
  String get walkDiaryErrorNotFound;

  /// 일기에 고른 사진 · 영상을 열거나 줄이지 못했을 때 오류
  ///
  /// In ko, this message translates to:
  /// **'사진·영상을 불러오지 못했어요'**
  String get walkDiaryErrorMediaProcessing;

  /// 일기 기록을 저장 · 읽기 중 규칙 밖의 오류가 났을 때
  ///
  /// In ko, this message translates to:
  /// **'저장하지 못했어요. 다시 시도해 주세요'**
  String get walkDiaryErrorSave;

  /// 일기 작성 화면 태그 추천 — 태그 이름과 쓴 기록 수
  ///
  /// In ko, this message translates to:
  /// **'#{name} {count}'**
  String walkDiaryEditorTagSuggestion(String name, int count);

  /// 일기 작성 화면 장소 추천 — 장소 이름과 쓴 기록 수
  ///
  /// In ko, this message translates to:
  /// **'{name} {count}'**
  String walkDiaryEditorPlaceSuggestion(String name, int count);

  /// 일기 탭 ⋮ 메뉴의 스토리 관리 항목 · 스토리 관리 화면 제목
  ///
  /// In ko, this message translates to:
  /// **'스토리 관리'**
  String get walkDiaryMenuStories;

  /// 스토리 관리 화면의 새 스토리 만들기 버튼 · 만들기 시트 제목
  ///
  /// In ko, this message translates to:
  /// **'새 스토리'**
  String get walkDiaryStoryNew;

  /// 스토리 메뉴의 이름 바꾸기 · 이름 시트 제목
  ///
  /// In ko, this message translates to:
  /// **'이름 바꾸기'**
  String get walkDiaryStoryRename;

  /// 스토리 메뉴의 표지 바꾸기 · 표지 시트 제목
  ///
  /// In ko, this message translates to:
  /// **'표지 바꾸기'**
  String get walkDiaryStoryCover;

  /// 스토리 메뉴의 닫기(보관함으로) 항목
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get walkDiaryStoryClose;

  /// 닫힌 스토리 메뉴의 다시 열기 항목
  ///
  /// In ko, this message translates to:
  /// **'다시 열기'**
  String get walkDiaryStoryReopen;

  /// 스토리 메뉴의 삭제 항목 · 삭제 확인 버튼
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get walkDiaryStoryDelete;

  /// 스토리 삭제 확인 다이얼로그 제목
  ///
  /// In ko, this message translates to:
  /// **'\'{title}\' 스토리를 삭제할까요?'**
  String walkDiaryStoryDeleteTitle(String title);

  /// 스토리 삭제 확인 다이얼로그 본문 — 기록은 휴지통, 복원하면 기본 스토리
  ///
  /// In ko, this message translates to:
  /// **'이 스토리의 기록은 휴지통으로 가요. 복원하면 \'일상\'으로 돌아와요.'**
  String get walkDiaryStoryDeleteContent;

  /// 스토리 만들기 · 이름 바꾸기 시트의 제목 입력칸
  ///
  /// In ko, this message translates to:
  /// **'제목'**
  String get walkDiaryStoryTitleLabel;

  /// 스토리 만들기 시트의 시작일 행
  ///
  /// In ko, this message translates to:
  /// **'시작일 {date}'**
  String walkDiaryStoryStart(String date);

  /// 스토리 만들기 시트의 종료일 행(넣었을 때)
  ///
  /// In ko, this message translates to:
  /// **'종료일 {date}'**
  String walkDiaryStoryEnd(String date);

  /// 스토리 만들기 시트의 종료일 행(비었을 때) — 누르면 날짜를 고른다
  ///
  /// In ko, this message translates to:
  /// **'종료일 없음 (진행 중)'**
  String get walkDiaryStoryNoEnd;

  /// 스토리 만들기 시트에서 넣은 종료일을 지우는 버튼
  ///
  /// In ko, this message translates to:
  /// **'종료일 지우기'**
  String get walkDiaryStoryClearEnd;

  /// 스토리 만들기 시트의 확인 버튼
  ///
  /// In ko, this message translates to:
  /// **'만들기'**
  String get walkDiaryStoryCreate;

  /// 스토리 이름 바꾸기 시트의 저장 버튼
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get walkDiaryStorySave;

  /// 스토리 닫기 시트 — 지금 시각으로 닫기
  ///
  /// In ko, this message translates to:
  /// **'지금 닫기'**
  String get walkDiaryStoryCloseNow;

  /// 스토리 닫기 시트 — 종료일을 골라 닫기
  ///
  /// In ko, this message translates to:
  /// **'날짜를 골라 닫기'**
  String get walkDiaryStoryCloseOnDate;

  /// 스토리 표지 시트의 자동 표지 항목
  ///
  /// In ko, this message translates to:
  /// **'자동 (가장 최근 사진)'**
  String get walkDiaryStoryCoverAuto;

  /// 스토리 표지 시트 — 고를 사진 · 영상이 없을 때
  ///
  /// In ko, this message translates to:
  /// **'이 스토리에는 아직 사진이 없어요'**
  String get walkDiaryStoryCoverEmpty;

  /// 지난 기간 스토리를 만든 뒤 그 기간의 기본 스토리 기록을 옮기자는 시트 제목
  ///
  /// In ko, this message translates to:
  /// **'이 기간의 \'일상\' 기록을 옮길까요?'**
  String get walkDiaryStoryMoveTitle;

  /// 일상 기록 옮기기 시트의 확인 버튼 — 고른 기록 수
  ///
  /// In ko, this message translates to:
  /// **'{count}개 옮기기'**
  String walkDiaryStoryMoveConfirm(int count);

  /// 일상 기록 옮기기 시트의 건너뛰기 버튼
  ///
  /// In ko, this message translates to:
  /// **'건너뛰기'**
  String get walkDiaryStoryMoveSkip;

  /// 일상 기록을 새 스토리로 옮긴 뒤 알림
  ///
  /// In ko, this message translates to:
  /// **'기록 {count}개를 옮겼어요'**
  String walkDiaryStoryMoved(int count);

  /// 스토리 종료일이 시작일보다 이를 때 오류
  ///
  /// In ko, this message translates to:
  /// **'종료일이 시작일보다 빠를 수 없어요'**
  String get walkDiaryErrorEndBeforeStart;

  /// 기본 스토리(일상)를 닫거나 지우려 할 때 오류
  ///
  /// In ko, this message translates to:
  /// **'기본 스토리는 닫거나 지울 수 없어요'**
  String get walkDiaryErrorDefaultStoryLocked;

  /// 일기 기록 상세 ⋮ 메뉴의 수정 항목
  ///
  /// In ko, this message translates to:
  /// **'수정'**
  String get walkDiaryEntryEdit;

  /// 일기 기록 상세 ⋮ 메뉴의 삭제 항목 · 삭제 확인 버튼
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get walkDiaryEntryDelete;

  /// 일기 기록 삭제 확인 다이얼로그 제목
  ///
  /// In ko, this message translates to:
  /// **'기록을 삭제할까요?'**
  String get walkDiaryEntryDeleteTitle;

  /// 일기 기록 삭제 확인 다이얼로그 본문
  ///
  /// In ko, this message translates to:
  /// **'휴지통으로 옮겨요. 휴지통에서 복원할 수 있어요.'**
  String get walkDiaryEntryDeleteContent;

  /// 일기 기록을 휴지통으로 보낸 뒤 알림
  ///
  /// In ko, this message translates to:
  /// **'기록을 휴지통으로 옮겼어요'**
  String get walkDiaryEntryTrashed;

  /// 일기 기록을 휴지통으로 보내지 못했을 때 오류
  ///
  /// In ko, this message translates to:
  /// **'휴지통으로 옮기지 못했어요. 다시 시도해 주세요'**
  String get walkDiaryEntryTrashFailed;

  /// 일기 기록 상세의 날짜와 시각
  ///
  /// In ko, this message translates to:
  /// **'{date} {time}'**
  String walkDiaryEntryDateTime(String date, String time);

  /// 일기 탭 앱바의 검색 버튼 툴팁
  ///
  /// In ko, this message translates to:
  /// **'검색'**
  String get walkDiarySearch;

  /// 일기 검색 화면 입력칸 안내 문구
  ///
  /// In ko, this message translates to:
  /// **'일기 검색'**
  String get walkDiarySearchHint;

  /// 일기 검색 탭 — 기록 본문에서 찾기
  ///
  /// In ko, this message translates to:
  /// **'글'**
  String get walkDiarySearchTabBody;

  /// 일기 검색 탭 — 스토리 이름에서 찾기
  ///
  /// In ko, this message translates to:
  /// **'스토리'**
  String get walkDiarySearchTabStory;

  /// 일기 검색 탭 — 해시태그 추천
  ///
  /// In ko, this message translates to:
  /// **'해시태그'**
  String get walkDiarySearchTabTag;

  /// 일기 검색 탭 — 장소 추천
  ///
  /// In ko, this message translates to:
  /// **'장소'**
  String get walkDiarySearchTabPlace;

  /// 일기 검색 글 탭에서 아직 아무것도 입력하지 않았을 때 안내
  ///
  /// In ko, this message translates to:
  /// **'글에서 찾을 말을 입력해 보세요'**
  String get walkDiarySearchBodyPrompt;

  /// 일기 검색 스토리 탭에서 아직 아무것도 입력하지 않았을 때 안내
  ///
  /// In ko, this message translates to:
  /// **'찾을 스토리 이름을 입력해 보세요'**
  String get walkDiarySearchStoryPrompt;

  /// 일기 검색 결과가 없을 때 안내
  ///
  /// In ko, this message translates to:
  /// **'찾는 결과가 없어요'**
  String get walkDiarySearchNoResults;

  /// 일기 검색 결과 · 모아보기의 기록 수
  ///
  /// In ko, this message translates to:
  /// **'기록 {count}개'**
  String walkDiaryEntryCount(int count);

  /// 태그 · 장소 모아보기에 남은 기록이 없을 때(모두 휴지통으로 갔을 때 등) 안내
  ///
  /// In ko, this message translates to:
  /// **'모아 볼 기록이 없어요'**
  String get walkDiaryCollectionEmpty;

  /// 일기 탭 ⋮ 메뉴의 휴지통 항목 · 휴지통 화면 제목
  ///
  /// In ko, this message translates to:
  /// **'휴지통'**
  String get walkDiaryMenuTrash;

  /// 휴지통에 기록이 없을 때 빈 상태 안내
  ///
  /// In ko, this message translates to:
  /// **'휴지통이 비어 있어요'**
  String get walkDiaryTrashEmpty;

  /// 휴지통 기록이 영구 삭제되기까지 남은 일수(1일 이상)
  ///
  /// In ko, this message translates to:
  /// **'{days}일 남음'**
  String walkDiaryTrashDaysLeft(int days);

  /// 휴지통 기록이 오늘 영구 삭제될 때의 표시
  ///
  /// In ko, this message translates to:
  /// **'오늘 삭제돼요'**
  String get walkDiaryTrashDueToday;

  /// 본문이 없는 휴지통 기록의 제목 자리 표시
  ///
  /// In ko, this message translates to:
  /// **'(글 없는 기록)'**
  String get walkDiaryTrashNoBody;

  /// 휴지통 기록 복원 메뉴 항목
  ///
  /// In ko, this message translates to:
  /// **'복원'**
  String get walkDiaryTrashRestore;

  /// 휴지통 기록 영구 삭제 메뉴 항목 · 확인 버튼
  ///
  /// In ko, this message translates to:
  /// **'영구 삭제'**
  String get walkDiaryTrashDeleteForever;

  /// 휴지통 화면 앱바의 비우기 버튼 · 확인 버튼
  ///
  /// In ko, this message translates to:
  /// **'휴지통 비우기'**
  String get walkDiaryTrashEmptyAll;

  /// 휴지통 기록 영구 삭제 확인 제목
  ///
  /// In ko, this message translates to:
  /// **'영구 삭제할까요?'**
  String get walkDiaryTrashPurgeTitle;

  /// 휴지통 기록 영구 삭제 확인 본문
  ///
  /// In ko, this message translates to:
  /// **'되돌릴 수 없어요. 사진과 영상도 함께 지워져요.'**
  String get walkDiaryTrashPurgeContent;

  /// 휴지통 비우기 확인 제목
  ///
  /// In ko, this message translates to:
  /// **'휴지통을 비울까요?'**
  String get walkDiaryTrashEmptyAllTitle;

  /// 휴지통 비우기 확인 본문
  ///
  /// In ko, this message translates to:
  /// **'기록 {count}개가 영구 삭제돼요. 되돌릴 수 없어요.'**
  String walkDiaryTrashEmptyAllContent(int count);

  /// 휴지통 기록을 복원한 뒤 알림
  ///
  /// In ko, this message translates to:
  /// **'기록을 복원했어요'**
  String get walkDiaryTrashRestored;

  /// 휴지통 기록을 영구 삭제한 뒤 알림
  ///
  /// In ko, this message translates to:
  /// **'기록을 영구 삭제했어요'**
  String get walkDiaryTrashPurged;

  /// 휴지통을 비운 뒤 알림
  ///
  /// In ko, this message translates to:
  /// **'휴지통을 비웠어요'**
  String get walkDiaryTrashEmptied;

  /// 휴지통 기록을 복원하지 못했을 때 오류
  ///
  /// In ko, this message translates to:
  /// **'복원하지 못했어요. 다시 시도해 주세요'**
  String get walkDiaryTrashRestoreFailed;

  /// 휴지통 기록을 영구 삭제하거나 휴지통을 비우지 못했을 때 오류
  ///
  /// In ko, this message translates to:
  /// **'삭제하지 못했어요. 다시 시도해 주세요'**
  String get walkDiaryTrashDeleteFailed;

  /// 설정 탭 일기 섹션 제목
  ///
  /// In ko, this message translates to:
  /// **'일기'**
  String get walkDiarySettings;

  /// 설정 탭 일기 잠금 행 제목
  ///
  /// In ko, this message translates to:
  /// **'일기 잠금'**
  String get walkDiarySettingsLock;

  /// 일기 잠금이 꺼져 있을 때 행 오른쪽 문구
  ///
  /// In ko, this message translates to:
  /// **'꺼짐'**
  String get walkDiarySettingsLockOff;

  /// 앱을 떠난 뒤 일기가 다시 잠기기까지의 시간 행 제목
  ///
  /// In ko, this message translates to:
  /// **'다시 잠기는 시간'**
  String get walkDiarySettingsRelock;

  /// 다시 잠기는 시간 선택지: 즉시
  ///
  /// In ko, this message translates to:
  /// **'바로'**
  String get walkDiarySettingsRelockImmediate;

  /// 다시 잠기는 시간 선택지: 30초
  ///
  /// In ko, this message translates to:
  /// **'30초 뒤'**
  String get walkDiarySettingsRelock30s;

  /// 다시 잠기는 시간 선택지: 1분
  ///
  /// In ko, this message translates to:
  /// **'1분 뒤'**
  String get walkDiarySettingsRelock1m;

  /// 다시 잠기는 시간 선택지: 5분
  ///
  /// In ko, this message translates to:
  /// **'5분 뒤'**
  String get walkDiarySettingsRelock5m;

  /// 휴지통 자동 삭제 기간 행 제목
  ///
  /// In ko, this message translates to:
  /// **'휴지통 보관 기간'**
  String get walkDiarySettingsRetention;

  /// 휴지통 보관 기간 선택지: 1일
  ///
  /// In ko, this message translates to:
  /// **'1일'**
  String get walkDiarySettingsRetention1d;

  /// 휴지통 보관 기간 선택지: 7일
  ///
  /// In ko, this message translates to:
  /// **'7일'**
  String get walkDiarySettingsRetention7d;

  /// 휴지통 보관 기간 선택지: 30일
  ///
  /// In ko, this message translates to:
  /// **'30일'**
  String get walkDiarySettingsRetention30d;

  /// 휴지통 보관 기간 선택지: 자동으로 지우지 않음
  ///
  /// In ko, this message translates to:
  /// **'지우지 않음'**
  String get walkDiarySettingsRetentionNever;

  /// 일기가 차지하는 저장 공간 행 제목
  ///
  /// In ko, this message translates to:
  /// **'저장 공간'**
  String get walkDiarySettingsStorage;

  /// 저장 공간 행 본문. size 는 1.2GB 같은 크기
  ///
  /// In ko, this message translates to:
  /// **'사용 중 {size}'**
  String walkDiarySettingsStorageUsage(String size);

  /// 저장 공간 행 부가 설명. trash 는 휴지통이 차지하는 크기
  ///
  /// In ko, this message translates to:
  /// **'사진 {photos}장 · 영상 {videos}개, 휴지통 {trash} 포함'**
  String walkDiarySettingsStorageDetail(int photos, int videos, String trash);

  /// 일기 섹션 맨 아래 안내
  ///
  /// In ko, this message translates to:
  /// **'기록은 이 폰에만 저장돼요. 앱을 지우면 함께 사라져요.'**
  String get walkDiarySettingsLocalOnly;

  /// 통계 화면 앱바 제목
  ///
  /// In ko, this message translates to:
  /// **'산책 통계'**
  String get walkStatsTitle;

  /// 통계 기간 토글 — 주
  ///
  /// In ko, this message translates to:
  /// **'주'**
  String get walkStatsWeek;

  /// 통계 기간 토글 — 월
  ///
  /// In ko, this message translates to:
  /// **'월'**
  String get walkStatsMonth;

  /// 통계 이전 기간 버튼 툴팁
  ///
  /// In ko, this message translates to:
  /// **'이전 기간'**
  String get walkStatsPreviousTooltip;

  /// 통계 다음 기간 버튼 툴팁
  ///
  /// In ko, this message translates to:
  /// **'다음 기간'**
  String get walkStatsNextTooltip;

  /// 통계 요약 — 총 거리 라벨
  ///
  /// In ko, this message translates to:
  /// **'걸은 거리'**
  String get walkStatsDistanceLabel;

  /// 통계 요약 — 총 시간 라벨
  ///
  /// In ko, this message translates to:
  /// **'걸은 시간'**
  String get walkStatsDurationLabel;

  /// 통계 요약 — 산책 횟수 라벨
  ///
  /// In ko, this message translates to:
  /// **'산책'**
  String get walkStatsCountLabel;

  /// 통계 요약 — 산책 횟수 값
  ///
  /// In ko, this message translates to:
  /// **'{count}번'**
  String walkStatsCountValue(int count);

  /// 이번 기간이 지난주보다 길 때. distance 는 차이(WalkFormat.distance)
  ///
  /// In ko, this message translates to:
  /// **'지난주보다 {distance} 더 걸었어요'**
  String walkStatsMoreThanLastWeek(String distance);

  /// 이번 기간이 지난주보다 길지 않을 때 중립 비교. distance 는 지난주 합
  ///
  /// In ko, this message translates to:
  /// **'지난주 {distance}'**
  String walkStatsLastWeek(String distance);

  /// 이번 기간이 지난달보다 길 때. distance 는 차이
  ///
  /// In ko, this message translates to:
  /// **'지난달보다 {distance} 더 걸었어요'**
  String walkStatsMoreThanLastMonth(String distance);

  /// 이번 기간이 지난달보다 길지 않을 때 중립 비교. distance 는 지난달 합
  ///
  /// In ko, this message translates to:
  /// **'지난달 {distance}'**
  String walkStatsLastMonth(String distance);

  /// 막대 한 칸의 접근성 라벨. label 은 요일 또는 일 범위
  ///
  /// In ko, this message translates to:
  /// **'{label} {distance}'**
  String walkStatsBarSemantics(String label, String distance);

  /// 통계 화면 기록 절 제목
  ///
  /// In ko, this message translates to:
  /// **'기록'**
  String get walkStatsRecordsTitle;

  /// 지금 이어지고 있는 연속 산책 일수 라벨
  ///
  /// In ko, this message translates to:
  /// **'연속 산책'**
  String get walkStatsCurrentStreak;

  /// 가장 길게 이어진 연속 산책 일수 라벨
  ///
  /// In ko, this message translates to:
  /// **'최장 연속'**
  String get walkStatsLongestStreak;

  /// 연속 일수 값
  ///
  /// In ko, this message translates to:
  /// **'{count}일'**
  String walkStatsDays(int count);

  /// 거리가 가장 긴 산책 라벨
  ///
  /// In ko, this message translates to:
  /// **'가장 먼 산책'**
  String get walkStatsFarthestWalk;

  /// 시간이 가장 긴 산책 라벨
  ///
  /// In ko, this message translates to:
  /// **'가장 오래 걸은 산책'**
  String get walkStatsLongestWalk;

  /// 산책이 하나도 없을 때 통계 화면 안내 제목
  ///
  /// In ko, this message translates to:
  /// **'아직 통계가 없어요'**
  String get walkStatsEmptyTitle;

  /// 산책이 하나도 없을 때 통계 화면 안내 본문
  ///
  /// In ko, this message translates to:
  /// **'산책을 기록하면 여기에 쌓여요'**
  String get walkStatsEmptyMessage;

  /// 피드 맨 위 이번 주 요약 줄. 탭하면 통계
  ///
  /// In ko, this message translates to:
  /// **'이번 주 {distance} · {count}번'**
  String walkFeedWeekSummary(String distance, int count);

  /// 이번 주 산책이 0건일 때 피드 요약 줄
  ///
  /// In ko, this message translates to:
  /// **'이번 주는 아직 산책 전이에요'**
  String get walkFeedWeekSummaryEmpty;

  /// 산책 진행 화면의 일시정지 보조 버튼
  ///
  /// In ko, this message translates to:
  /// **'일시정지'**
  String get walkPause;

  /// 일시정지 중 산책을 이어 가는 보조 버튼
  ///
  /// In ko, this message translates to:
  /// **'계속 걷기'**
  String get walkUnpause;

  /// 산책 진행 시트에서 멈춘 상태를 알리는 라벨
  ///
  /// In ko, this message translates to:
  /// **'일시정지 중'**
  String get walkPausedLabel;

  /// 피드 맨 위 배너. 산책이 일시정지 중일 때
  ///
  /// In ko, this message translates to:
  /// **'산책을 잠시 멈췄어요'**
  String get walkPausedBanner;

  /// 산책 상세 더보기 메뉴에서 산책 한 건을 GPX 파일로 공유하는 항목
  ///
  /// In ko, this message translates to:
  /// **'GPX로 내보내기'**
  String get walkExportGpx;

  /// 경로 점이 없는 산책을 GPX 로 내보내려 할 때 스낵바
  ///
  /// In ko, this message translates to:
  /// **'경로가 없어 내보낼 수 없어요'**
  String get walkExportNoRoute;

  /// GPX 파일 쓰기 · 공유가 실패했을 때 스낵바
  ///
  /// In ko, this message translates to:
  /// **'내보내지 못했어요'**
  String get walkExportFailed;

  /// 피드 더보기 메뉴에서 모든 기록을 백업 파일로 공유하는 항목
  ///
  /// In ko, this message translates to:
  /// **'백업 내보내기'**
  String get walkBackupExport;

  /// 피드 더보기 메뉴에서 백업 파일을 골라 기록을 합쳐 넣는 항목
  ///
  /// In ko, this message translates to:
  /// **'백업 가져오기'**
  String get walkBackupImport;

  /// 첫 실행 반려견 등록 화면 아래의 백업 가져오기 텍스트 버튼
  ///
  /// In ko, this message translates to:
  /// **'백업에서 가져오기'**
  String get walkBackupImportFromFirstRun;

  /// 백업 파일 만들기 · 공유가 실패했을 때 스낵바
  ///
  /// In ko, this message translates to:
  /// **'백업을 만들지 못했어요'**
  String get walkBackupExportFailed;

  /// 백업에서 새 항목을 가져왔을 때 스낵바
  ///
  /// In ko, this message translates to:
  /// **'반려견 {dogs}마리 · 산책 {walks}개를 가져왔어요'**
  String walkBackupImported(int dogs, int walks);

  /// 백업의 항목이 모두 이미 있을 때 스낵바
  ///
  /// In ko, this message translates to:
  /// **'새로 가져올 기록이 없어요'**
  String get walkBackupNothingNew;

  /// 고른 파일이 읽을 수 있는 pawlog 백업이 아닐 때 스낵바
  ///
  /// In ko, this message translates to:
  /// **'백업 파일을 읽지 못했어요'**
  String get walkBackupInvalid;

  /// 백업을 읽었지만 저장에 실패했을 때 스낵바
  ///
  /// In ko, this message translates to:
  /// **'가져오지 못했어요'**
  String get walkBackupImportFailed;

  /// 피드 앱바 더보기 메뉴 버튼의 툴팁
  ///
  /// In ko, this message translates to:
  /// **'더보기'**
  String get walkFeedMoreTooltip;

  /// 산책 상세 앱바의 빈 별 버튼 툴팁 — 누르면 즐겨찾기에 넣는다
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기에 추가'**
  String get walkFavoriteAdd;

  /// 산책 상세 앱바의 꽉 찬 별 버튼 툴팁 — 누르면 즐겨찾기에서 뺀다
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기에서 빼기'**
  String get walkFavoriteRemove;

  /// 피드 더보기 메뉴에서 즐겨찾기한 산책만 보게 거르는 항목
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기만 보기'**
  String get walkFeedShowFavorites;

  /// 즐겨찾기 필터 중 피드 더보기 메뉴에서 필터를 끄는 항목
  ///
  /// In ko, this message translates to:
  /// **'모든 산책 보기'**
  String get walkFeedShowAll;

  /// 즐겨찾기만 보기 중 결과가 없을 때 안내 제목
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기한 산책이 없어요'**
  String get walkFeedFavoritesEmptyTitle;

  /// 즐겨찾기만 보기 중 결과가 없을 때 안내 설명
  ///
  /// In ko, this message translates to:
  /// **'산책 상세에서 별을 눌러 보세요'**
  String get walkFeedFavoritesEmptyMessage;

  /// 피드 항목의 즐겨찾기 별 아이콘의 스크린리더 라벨
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기'**
  String get walkFavoriteLabel;

  /// 모두의 산책 화면 앱바 제목
  ///
  /// In ko, this message translates to:
  /// **'모두의 산책'**
  String get walkSocialTitle;

  /// pawlog 로그인 화면 제목 · 로그인 버튼
  ///
  /// In ko, this message translates to:
  /// **'로그인'**
  String get walkSocialSignIn;

  /// pawlog 가입 모드의 제목 · 가입 버튼
  ///
  /// In ko, this message translates to:
  /// **'가입하기'**
  String get walkSocialSignUp;

  /// 모두의 산책 앱바 더보기의 로그아웃 항목
  ///
  /// In ko, this message translates to:
  /// **'로그아웃'**
  String get walkSocialSignOut;

  /// pawlog 로그인 화면 이메일 입력칸 라벨
  ///
  /// In ko, this message translates to:
  /// **'이메일'**
  String get walkSocialEmail;

  /// pawlog 로그인 화면 비밀번호 입력칸 라벨
  ///
  /// In ko, this message translates to:
  /// **'비밀번호'**
  String get walkSocialPassword;

  /// pawlog 가입 모드의 닉네임 입력칸 라벨
  ///
  /// In ko, this message translates to:
  /// **'닉네임'**
  String get walkSocialNickname;

  /// 로그인 모드에서 가입 모드로 바꾸는 글자 버튼
  ///
  /// In ko, this message translates to:
  /// **'처음이면 가입하기'**
  String get walkSocialSwitchToSignUp;

  /// 가입 모드에서 로그인 모드로 바꾸는 글자 버튼
  ///
  /// In ko, this message translates to:
  /// **'이미 계정이 있으면 로그인'**
  String get walkSocialSwitchToSignIn;

  /// 로그인 화면 위 안내 — 왜 로그인이 필요한지
  ///
  /// In ko, this message translates to:
  /// **'로그인하면 공유하고 좋아요를 누를 수 있어요'**
  String get walkSocialSignInRequired;

  /// 이메일 · 비밀번호가 틀렸을 때 스낵바
  ///
  /// In ko, this message translates to:
  /// **'로그인하지 못했어요. 이메일과 비밀번호를 확인해 주세요'**
  String get walkSocialAuthFailed;

  /// 가입 때 닉네임이 이미 있을 때 닉네임 입력칸 아래 오류
  ///
  /// In ko, this message translates to:
  /// **'이미 쓰는 닉네임이에요'**
  String get walkSocialNicknameTaken;

  /// 모두의 산책에 공유된 산책이 하나도 없을 때 안내
  ///
  /// In ko, this message translates to:
  /// **'아직 공유된 산책이 없어요'**
  String get walkSocialEmpty;

  /// 피드 앱바에서 모두의 산책을 여는 아이콘 툴팁
  ///
  /// In ko, this message translates to:
  /// **'모두의 산책'**
  String get walkSocialOpenTooltip;

  /// 모두의 산책 목록을 못 읽었거나 서버를 쓸 수 없을 때 안내
  ///
  /// In ko, this message translates to:
  /// **'모두의 산책을 불러오지 못했어요'**
  String get walkSocialLoadFailed;

  /// 산책 상세 더보기 — 이 산책을 모두의 산책에 공유
  ///
  /// In ko, this message translates to:
  /// **'모두에게 공유'**
  String get walkSocialShare;

  /// 산책 상세 더보기 — 공유한 산책을 내림
  ///
  /// In ko, this message translates to:
  /// **'공유 취소'**
  String get walkSocialUnshare;

  /// 공유 성공 스낵바
  ///
  /// In ko, this message translates to:
  /// **'공유했어요'**
  String get walkSocialShared;

  /// 공유 취소 성공 스낵바
  ///
  /// In ko, this message translates to:
  /// **'공유를 취소했어요'**
  String get walkSocialUnshared;

  /// 공유 · 공유 취소 실패 스낵바
  ///
  /// In ko, this message translates to:
  /// **'공유하지 못했어요'**
  String get walkSocialShareFailed;

  /// 모두의 산책 하트 버튼 툴팁
  ///
  /// In ko, this message translates to:
  /// **'좋아요'**
  String get walkSocialLikeTooltip;
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
