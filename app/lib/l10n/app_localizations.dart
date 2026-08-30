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
  /// **'{email} 으로 보낸 6자리 코드를 입력하세요.'**
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
  /// **'감정을 남기지 못했습니다.'**
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
