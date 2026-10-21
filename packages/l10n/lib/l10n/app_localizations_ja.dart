// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get commonDelete => '削除';

  @override
  String get commonRetry => '再試行';

  @override
  String get commonMoreActions => 'その他';

  @override
  String get authSignInDescription => '今日一日を記録して、ご近所と分かち合いましょう。';

  @override
  String get authEmailLabel => 'メールアドレス';

  @override
  String get authPasswordLabel => 'パスワード';

  @override
  String get authSignIn => 'ログイン';

  @override
  String get authForgotPassword => 'パスワードをお忘れですか？';

  @override
  String get authNoAccountPrompt => 'まだアカウントをお持ちではありませんか？';

  @override
  String get authSignUp => '新規登録';

  @override
  String get authBrowseFirst => 'まず見てみる';

  @override
  String get authSignUpDescription => 'メールアドレスとニックネームだけですぐに始められます。';

  @override
  String get authNicknameLabel => 'ニックネーム（2〜20文字）';

  @override
  String get authPasswordWithRuleLabel => 'パスワード（8文字以上）';

  @override
  String get authPasswordConfirmLabel => 'パスワード確認';

  @override
  String get authSignUpSubmit => '登録';

  @override
  String get authPasswordResetTitle => 'パスワード再設定';

  @override
  String get authPasswordResetDescription => '登録したメールアドレスに6桁のコードをお送りします。';

  @override
  String get authPasswordResetSendCode => 'コードを送信';

  @override
  String get authPasswordResetCodeTitle => 'コード入力';

  @override
  String authPasswordResetCodeDescription(String email) {
    return '$email に送信した6桁のコードを入力してください。';
  }

  @override
  String get authPasswordResetCodeLabel => '認証コード';

  @override
  String get authPasswordResetVerify => '確認';

  @override
  String get authPasswordResetChangeEmail => 'メールアドレスを入力し直す';

  @override
  String get authNewPasswordTitle => '新しいパスワード';

  @override
  String get authNewPasswordDescription => 'これから使用するパスワードを入力してください。';

  @override
  String get authNewPasswordLabel => '新しいパスワード（8文字以上）';

  @override
  String get authNewPasswordConfirmLabel => '新しいパスワード確認';

  @override
  String get authPasswordChangeSubmit => 'パスワード変更';

  @override
  String get authPasswordChangedTitle => 'パスワードを変更しました。';

  @override
  String get authPasswordChangedDescription => '新しいパスワードでもう一度ログインしてください。';

  @override
  String get authGoToSignIn => 'ログインへ進む';

  @override
  String get authPasswordShow => 'パスワードを表示';

  @override
  String get authPasswordHide => 'パスワードを非表示';

  @override
  String get feedLoadFailed => 'フィードを読み込めませんでした';

  @override
  String get feedLoadFailedDescription => '接続を確認してもう一度お試しください。';

  @override
  String get feedComposeTooltip => '新しい投稿を作成';

  @override
  String get feedComposeLabel => '投稿';

  @override
  String get feedEmptyMessage => 'まだ投稿がありません';

  @override
  String get feedEmptyDescription => '最初の投稿を残してみましょう。';

  @override
  String get feedEmptyAction => '最初の投稿を書く';

  @override
  String get feedEndOfList => 'すべて確認しました';

  @override
  String get guestFeedTitle => '見てみる';

  @override
  String get guestPromptTitle => '登録するとリアクションやコメントができます';

  @override
  String get guestPromptDescription => 'メールアドレスとニックネームだけで始められます。';

  @override
  String get postEditTitle => '投稿を編集';

  @override
  String get postCreateTitle => '新しい投稿';

  @override
  String get postContentLabel => '今日の記録';

  @override
  String get postContentHint => 'いま思い浮かんだことを残してみましょう。';

  @override
  String get postTradeAttached => 'この回の結果も一緒に投稿されます';

  @override
  String get postContentRequired => '投稿の内容を入力してください。';

  @override
  String get postSaveButton => '保存';

  @override
  String get postSubmitButton => '投稿';

  @override
  String get postCreated => '投稿を作成しました。';

  @override
  String get postUpdated => '投稿を編集しました。';

  @override
  String get postSaveFailed => '投稿を保存できませんでした。';

  @override
  String get postImagePrepareFailed => '画像を準備できませんでした。';

  @override
  String get postDiscardEditTitle => '編集を取り消しますか？';

  @override
  String get postDiscardCreateTitle => '作成中の内容を破棄しますか？';

  @override
  String get postDiscardMessage => '入力した内容は保存されません。';

  @override
  String get postDiscardKeepWriting => '書き続ける';

  @override
  String get postDiscardLeave => '破棄';

  @override
  String postImageLimitReached(int count) {
    return '写真は$count枚までアップロードできます';
  }

  @override
  String postAddImages(int count, int max) {
    return '写真を追加（$count/$max）';
  }

  @override
  String get postRemoveImageTooltip => '写真を削除';

  @override
  String get postCommentCountTooltip => 'コメント';

  @override
  String get postMenuTooltip => '投稿メニュー';

  @override
  String get postMenuEdit => '編集';

  @override
  String get postMenuReport => '報告';

  @override
  String get postMenuBlockUser => 'このユーザーをブロック';

  @override
  String get postDeleteConfirmTitle => '投稿を削除しますか？';

  @override
  String get postDeleteConfirmMessage => '削除した投稿は元に戻せません。';

  @override
  String get postDeleteSucceeded => '投稿を削除しました。';

  @override
  String get postDeleteFailed => '投稿を削除できませんでした。';

  @override
  String get commentTitle => 'コメント';

  @override
  String get commentLoadFailed => 'コメントを読み込めませんでした';

  @override
  String get commentEmptyMessage => '最初のコメントを残してみましょう。';

  @override
  String get commentLoadMoreReplies => '返信をもっと見る';

  @override
  String get commentMenuTooltip => 'コメントメニュー';

  @override
  String get commentMenuReport => '報告';

  @override
  String get commentDeletedPlaceholder => '削除されたコメントです';

  @override
  String get commentReply => '返信';

  @override
  String get commentHideReplies => '返信を隠す';

  @override
  String commentShowReplies(int count) {
    return '返信$count件を見る';
  }

  @override
  String get commentDeleteConfirmTitle => 'コメントを削除しますか？';

  @override
  String get commentDeleteConfirmMessage => '削除したコメントは元に戻せません。';

  @override
  String get commentDeleteSucceeded => 'コメントを削除しました。';

  @override
  String get commentDeleteNotAllowed => '削除できるコメントではありません。';

  @override
  String get commentDeleteFailed => 'コメントを削除できませんでした。';

  @override
  String commentReplyingTo(String nickname) {
    return '$nicknameさんへの返信';
  }

  @override
  String get commentReplyCancelTooltip => '返信を取り消す';

  @override
  String get commentInputHint => 'コメントする';

  @override
  String get commentReplyInputHint => '返信する';

  @override
  String get commentSubmitTooltip => '送信';

  @override
  String get commentSignInRequired => 'ログインが必要です。';

  @override
  String get commentCreateFailed => 'コメントを投稿できませんでした。';

  @override
  String get reactionSaveFailed => 'リアクションを保存できませんでした。';

  @override
  String get safetyReportSubmitted => '報告を受け付けました';

  @override
  String get safetyBlockConfirmTitle => 'このユーザーをブロックしますか？';

  @override
  String get safetyBlockConfirmMessage => 'ブロックすると、このユーザーの投稿とコメントは表示されなくなります。';

  @override
  String get safetyBlockConfirmAction => 'ブロック';

  @override
  String get safetyBlockSucceeded => 'ブロックしました。';

  @override
  String get safetyBlockFailed => 'ブロックできませんでした。';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsProfileEdit => 'プロフィール編集';

  @override
  String get settingsAccount => 'アカウント設定';

  @override
  String get settingsTheme => 'テーマ';

  @override
  String get settingsLanguage => '言語';

  @override
  String get settingsBlockedUsers => 'ブロックしたユーザー';

  @override
  String get settingsSignOut => 'ログアウト';

  @override
  String get settingsSignOutConfirmTitle => 'ログアウトしますか？';

  @override
  String get settingsSignOutConfirmMessage => '再び利用するにはログインが必要です。';

  @override
  String get themeModeSystem => 'システムに合わせる';

  @override
  String get themeModeLight => 'ライト';

  @override
  String get themeModeDark => 'ダーク';

  @override
  String get languageSystem => 'システムに合わせる';

  @override
  String get homeTabTrade => '投資';

  @override
  String get homeTabFeed => 'ホーム';

  @override
  String get homeTabChat => 'チャット';

  @override
  String get homeTabProfile => 'プロフィール';

  @override
  String get homeTabSettings => '設定';

  @override
  String get chatTitle => 'チャット';

  @override
  String get chatLoadFailed => 'チャット一覧を読み込めませんでした';

  @override
  String get chatEmptyMessage => '参加中のルームがありません';

  @override
  String get chatEmptyDescription => '公開ルームを探して参加してみましょう。';

  @override
  String get chatEmptyAction => 'ルームを探す';

  @override
  String get chatExploreTooltip => 'ルームを探す';

  @override
  String get chatCreateRoomLabel => 'ルーム作成';

  @override
  String get chatNoMessagesYet => 'まだ会話がありません';

  @override
  String get chatLastMessageImage => '写真';

  @override
  String get chatExploreTitle => 'ルームを探す';

  @override
  String get chatSearchHint => 'ルーム名で検索';

  @override
  String get chatExploreEmptyMessage => '公開ルームがありません';

  @override
  String get chatExploreEmptyDescription => '最初のルームを作ってみましょう。';

  @override
  String get chatExploreNoResult => '検索結果がありません';

  @override
  String get chatExploreLoadFailed => 'ルーム一覧を読み込めませんでした';

  @override
  String get chatJoinTitle => 'このルームで使う名前';

  @override
  String get chatJoinDescription => 'ルームごとに違う名前を使えます。';

  @override
  String get chatJoinNicknameLabel => 'ルームでの名前';

  @override
  String get chatJoinAction => '参加';

  @override
  String get chatJoinFailed => '参加できませんでした';

  @override
  String get chatCreateTitle => 'ルーム作成';

  @override
  String get chatRoomTitleLabel => 'ルーム名';

  @override
  String get chatRoomDescriptionLabel => '説明（任意）';

  @override
  String get chatNicknameLabel => 'ルームでの名前';

  @override
  String get chatCreateAction => '作成';

  @override
  String get chatCreateFailed => 'ルームを作成できませんでした';

  @override
  String get chatRoomEmptyMessage => '最初のメッセージを送ってみましょう';

  @override
  String get chatRoomLoadFailed => '会話を読み込めませんでした';

  @override
  String get chatComposerHint => 'メッセージを入力';

  @override
  String get chatSendTooltip => '送信';

  @override
  String get chatAttachTooltip => '写真を送る';

  @override
  String get chatRoomMenuTooltip => 'ルームメニュー';

  @override
  String get chatMenuParticipants => '参加者';

  @override
  String get chatMenuLeave => 'ルームを退出';

  @override
  String get chatParticipantsTitle => '参加者';

  @override
  String get chatLeaveConfirmTitle => 'ルームを退出しますか？';

  @override
  String get chatLeaveConfirmMessage => '一覧から消えます。送信したメッセージはルームに残ります。';

  @override
  String get chatLeaveConfirmAction => '退出';

  @override
  String get chatLeaveFailed => '退出できませんでした';

  @override
  String get chatMessageDelete => '削除';

  @override
  String get chatMessageReport => '報告';

  @override
  String get chatDeleteConfirmTitle => 'メッセージを削除しますか？';

  @override
  String get chatDeleteConfirmMessage => '削除したメッセージは元に戻せません。';

  @override
  String get chatSendFailed => 'メッセージを送信できませんでした';

  @override
  String get chatSendFailedShort => '送信失敗';

  @override
  String get chatSending => '送信中';

  @override
  String get chatRetry => '再送信';

  @override
  String get chatImageLoadFailed => '写真を読み込めませんでした';

  @override
  String get chatImagePrepareFailed => '写真を準備できませんでした。';

  @override
  String chatSystemJoined(String nickname) {
    return '$nicknameさんが入室しました';
  }

  @override
  String chatSystemLeft(String nickname) {
    return '$nicknameさんが退室しました';
  }

  @override
  String chatMemberCount(int count) {
    return '$count人';
  }

  @override
  String chatMemberLimitValue(int count) {
    return '定員 $count人';
  }

  @override
  String get commonSave => '保存';

  @override
  String get profileTitle => 'プロフィール';

  @override
  String get profileUserTitle => 'ユーザープロフィール';

  @override
  String get profileMenuTooltip => 'プロフィールメニュー';

  @override
  String get profileMenuUnblock => 'ブロック解除';

  @override
  String get profileLoadFailed => 'プロフィールを読み込めませんでした';

  @override
  String get profileBioEmpty => '自己紹介を書いてみましょう。';

  @override
  String profileCompletionTitle(int percent) {
    return 'プロフィール完成度 $percent%';
  }

  @override
  String get profileCompletionNickname => 'ニックネームを決める';

  @override
  String get profileCompletionAvatar => 'プロフィール写真を追加';

  @override
  String get profileCompletionBio => '自己紹介を書く';

  @override
  String get profileCompletionFirstPost => '最初の投稿を書く';

  @override
  String get profileCompletionFirstFollow => '気になる人をフォロー';

  @override
  String get profileEditAction => 'プロフィール編集';

  @override
  String get profileMessageButton => 'メッセージ';

  @override
  String get profilePostsTitle => '投稿';

  @override
  String get profilePostsReload => '投稿を再読み込み';

  @override
  String get profilePostsEmpty => 'まだ投稿がありません';

  @override
  String get profileNicknameChecking => '確認中…';

  @override
  String get profileNicknameAvailable => 'このニックネームは使用できます';

  @override
  String get profileNicknameTaken => 'このニックネームはすでに使用されています';

  @override
  String get profileNicknameLabel => 'ニックネーム';

  @override
  String get profileAvatarPickFailed => 'プロフィール写真を読み込めませんでした。';

  @override
  String get profileEditTitle => 'プロフィール編集';

  @override
  String get profileSetupTitle => 'プロフィールを整える';

  @override
  String get profileSetupDescription =>
      '写真とひとこと紹介で、ご近所に自分を知ってもらいましょう。あとで設定から変更できます。';

  @override
  String get profileSetupSkip => 'あとで';

  @override
  String get profileSetupContinue => '続ける';

  @override
  String get profileSaveFailed => 'プロフィールを保存できませんでした';

  @override
  String get profileSaveSucceeded => 'プロフィールを保存しました';

  @override
  String get profileChoosePhoto => '写真を選択';

  @override
  String get profileBioLabel => '自己紹介';

  @override
  String get safetyUnblockAction => 'ブロック解除';

  @override
  String get safetyUnblockSucceeded => 'ブロックを解除しました。';

  @override
  String get safetyUnblockFailed => 'ブロックを解除できませんでした。';

  @override
  String get safetyReportTitle => '報告';

  @override
  String get safetyReportFailed => '報告を送信できませんでした';

  @override
  String get safetyReportDetailLabel => '詳細（任意）';

  @override
  String get safetyReportDetailHint => '問題の内容を入力してください';

  @override
  String get safetyReportAction => '報告を送信';

  @override
  String get safetyReportReasonSpam => 'スパムまたは広告';

  @override
  String get safetyReportReasonAbuse => '暴言またはヘイトスピーチ';

  @override
  String get safetyReportReasonSexual => '性的なコンテンツ';

  @override
  String get safetyReportReasonViolence => '暴力または脅迫';

  @override
  String get safetyReportReasonOther => 'その他';

  @override
  String get safetyBlockedUsersTitle => 'ブロックしたユーザー';

  @override
  String get safetyBlockedUsersLoadFailed => 'ブロック一覧を読み込めませんでした';

  @override
  String get safetyBlockedUsersEmpty => 'ブロックしたユーザーはいません';

  @override
  String get accountSettingsTitle => 'アカウント設定';

  @override
  String get accountPasswordChange => 'パスワード変更';

  @override
  String get accountDelete => 'アカウント削除';

  @override
  String get accountDeleteSubtitle => 'アカウントとすべての記録がすぐに削除されます';

  @override
  String get accountDeleteFailed => 'アカウントを削除できませんでした。もう一度お試しください。';

  @override
  String get accountDeleteConfirmTitle => 'アカウントを削除しますか？';

  @override
  String get accountDeleteConfirmMessage =>
      'アカウントとともに以下がすべて削除され、元に戻せません。\n\n・プロフィールとプロフィール写真\n・投稿と写真\n・コメントとリアクション';

  @override
  String accountDeleteConfirmMessageCounted(int postCount, int commentCount) {
    return 'アカウントとともに以下がすべて削除され、元に戻せません。\n\n・プロフィールとプロフィール写真\n・投稿 $postCount件と写真\n・コメント $commentCount件とリアクション';
  }

  @override
  String get accountDeleteConfirmAction => 'アカウントを削除';

  @override
  String get passwordChangeTitle => 'パスワード変更';

  @override
  String get passwordChangeSucceeded => 'パスワードを変更しました';

  @override
  String get passwordChangeFailed => 'パスワードを変更できませんでした';

  @override
  String get passwordChangeNewLabel => '新しいパスワード';

  @override
  String get passwordChangeConfirmLabel => '新しいパスワード確認';

  @override
  String get passwordChangeAction => '変更';

  @override
  String get validationEmailRequired => 'メールアドレスを入力してください';

  @override
  String get validationEmailInvalid => '正しいメールアドレスを入力してください';

  @override
  String get validationPasswordRequired => 'パスワードを入力してください';

  @override
  String get validationPasswordTooShort => 'パスワードは8文字以上で入力してください';

  @override
  String get validationPasswordConfirmationRequired => 'パスワードをもう一度入力してください';

  @override
  String get validationPasswordMismatch => 'パスワードが一致しません';

  @override
  String get validationNicknameRequired => 'ニックネームを入力してください';

  @override
  String get validationNicknameTooShort => 'ニックネームは2文字以上で入力してください';

  @override
  String get validationNicknameTooLong => 'ニックネームは20文字以内で入力してください';

  @override
  String get validationOtpRequired => 'コードを入力してください';

  @override
  String get validationOtpInvalid => '6桁の数字を入力してください';

  @override
  String get failureNetwork => 'ネットワークに接続できません';

  @override
  String get failureAuth => '認証に失敗しました';

  @override
  String get failureForbidden => '権限がありません';

  @override
  String get failureNotFound => '対象が見つかりません';

  @override
  String get failureValidation => '入力内容を確認してください';

  @override
  String get failureServer => 'サーバーエラーが発生しました';

  @override
  String get failureUnknown => '不明なエラーが発生しました';

  @override
  String get failureInvalidCredentials => 'メールアドレスまたはパスワードが正しくありません';

  @override
  String get failureSignInFailed => 'ログインできませんでした';

  @override
  String get failureSignUpFailed => 'アカウントを作成できませんでした';

  @override
  String get failureEmailAlreadyRegistered => 'このメールアドレスはすでに登録されています';

  @override
  String get failureWeakPassword => 'より強いパスワードを設定してください';

  @override
  String get failureSamePassword => '現在と異なるパスワードを入力してください';

  @override
  String get failureOtpExpired => 'コードの有効期限が切れました。再度リクエストしてください';

  @override
  String get failureRateLimited => 'リクエストが多すぎます。しばらくしてからお試しください';

  @override
  String get failureDuplicateValue => 'この値はすでに使用されています';

  @override
  String get failureConstraintViolation => '入力内容が条件を満たしていません';

  @override
  String get failureReferencedTargetMissing => '参照先が存在しません';

  @override
  String get failureForbiddenOrDeleted => '権限がないか、対象が削除されています';

  @override
  String get failureNicknameLength => 'ニックネームは2〜20文字で入力してください';

  @override
  String get failureBioTooLong => '自己紹介は200文字以内で入力してください';

  @override
  String get failurePostContentLength => '投稿は1〜500文字で入力してください';

  @override
  String get failureCommentContentLength => 'コメントは1〜300文字で入力してください';

  @override
  String get failureUnsupportedReaction => '対応していないリアクションです';

  @override
  String get failureReportAlreadySubmitted => 'この項目はすでに報告済みです';

  @override
  String get failureReportDetailTooLong => '詳細は500文字以内で入力してください';

  @override
  String get failureReportSelfNotAllowed => '自分自身を報告することはできません';

  @override
  String get failureBlockSelfNotAllowed => '自分自身をブロックすることはできません';

  @override
  String get failureBlockAlreadyExists => 'このユーザーはすでにブロックされています';

  @override
  String get failureNestedReplyNotAllowed => '返信に返信することはできません';

  @override
  String get failureReplyToDeletedCommentNotAllowed => '削除されたコメントには返信できません';

  @override
  String get failureReplyParentPostMismatch => '親コメントは別の投稿に属しています';

  @override
  String get failureReplyParentMissing => '親コメントが存在しません';

  @override
  String get failureReportTargetMissing => '報告する対象が存在しません';

  @override
  String get failureReportOwnPostNotAllowed => '自分の投稿を報告することはできません';

  @override
  String get failureReportOwnCommentNotAllowed => '自分のコメントを報告することはできません';

  @override
  String get failureCommentNotAllowed => 'この投稿にはコメントできません';

  @override
  String get failureAuthenticationRequired => 'ログインが必要です';

  @override
  String get failureOperationInProgress => 'すでに処理中です';

  @override
  String get failureCommentsRangeInvalid => 'コメントの取得範囲が正しくありません';

  @override
  String get failureCommentCursorInvalid => 'コメントカーソルが正しくありません';

  @override
  String get failureCommentContentRequired => 'コメントを入力してください';

  @override
  String get failureCommentTooLong => 'コメントは300文字以内で入力してください';

  @override
  String get failureCommentDeleteTargetMissing => '削除するコメントが見つかりません';

  @override
  String get failureRoomTitleRequired => 'ルーム名を入力してください';

  @override
  String get failureRoomTitleTooLong => 'ルーム名は30文字以内で入力してください';

  @override
  String get failureRoomDescriptionTooLong => '説明は200文字以内で入力してください';

  @override
  String get failureRoomMemberLimitInvalid => '定員は2〜500人で設定してください';

  @override
  String get failureRoomNicknameTooShort => 'ルームでの名前は2文字以上で入力してください';

  @override
  String get failureRoomNicknameTooLong => 'ルームでの名前は20文字以内で入力してください';

  @override
  String get failureMessageContentRequired => 'メッセージを入力してください';

  @override
  String get failureMessageTooLong => 'メッセージは1000文字以内で入力してください';

  @override
  String get failureFeedRangeInvalid => 'フィードの取得範囲が正しくありません';

  @override
  String get failureFeedCursorInvalid => 'フィードカーソルが正しくありません';

  @override
  String get failureFeedNotLoaded => '先に一覧を読み込んでください';

  @override
  String get failurePostNotFound => '投稿が見つかりません';

  @override
  String get failureMessageCursorInvalid => 'メッセージカーソルが正しくありません';

  @override
  String get failureRoomCursorInvalid => 'ルームカーソルが正しくありません';

  @override
  String get failurePostIdRequired => '投稿IDが必要です';

  @override
  String get failurePostContentRequired => '投稿内容を入力してください';

  @override
  String get failurePostTooLong => '投稿は500文字以内で入力してください';

  @override
  String get failurePostImageLimit => '写真は5枚まで添付できます';

  @override
  String get failureAvatarUploadFailed => 'プロフィール写真をアップロードできませんでした。';

  @override
  String get failureInvalidData => '正しくないデータを受信しました';

  @override
  String get reactionLike => 'いいね';

  @override
  String get reactionDislike => 'よくないね';

  @override
  String avatarSemanticsLabel(String nickname) {
    return '$nicknameさんのプロフィール写真';
  }

  @override
  String get feedTabAll => 'すべて';

  @override
  String get feedTabFollowing => 'フォロー中';

  @override
  String get feedFollowingEmptyMessage => 'フォロー中の人がいません';

  @override
  String get feedFollowingEmptyDescription => '気になる人をフォローすると、ここに投稿が集まります。';

  @override
  String get feedFollowingEmptyAction => 'みんなの投稿を見る';

  @override
  String get followAction => 'フォロー';

  @override
  String get followFollowingAction => 'フォロー中';

  @override
  String get followMutualAction => '相互フォロー';

  @override
  String get followFailed => 'フォローできませんでした';

  @override
  String get followUnfollowFailed => 'フォローを解除できませんでした';

  @override
  String get followFollowersLabel => 'フォロワー';

  @override
  String get followFollowingsLabel => 'フォロー中';

  @override
  String get followFollowersTitle => 'フォロワー';

  @override
  String get followFollowingsTitle => 'フォロー中';

  @override
  String get followFollowersEmpty => 'まだフォロワーがいません';

  @override
  String get followFollowingsEmpty => 'まだ誰もフォローしていません';

  @override
  String get followListLoadFailed => 'リストを読み込めませんでした';

  @override
  String get failureFollowUserIdRequired => 'ユーザーIDが必要です';

  @override
  String get failureFollowRangeInvalid => 'フォロー一覧の取得範囲が正しくありません';

  @override
  String get failureFollowCursorInvalid => 'フォロー一覧のカーソルが正しくありません';

  @override
  String get failureFollowBlocked => '現在このアカウントはフォローできません';

  @override
  String get failureRoomFull => 'このルームは満員です';

  @override
  String get failureRoomNotFound => 'このルームは存在しません';

  @override
  String get failureDirectChatNotAllowed => '現在この会話を開始できません';

  @override
  String get failureDirectChatSelfNotAllowed => '自分自身とは会話できません';

  @override
  String get failureChatSendNotAllowed => '現在メッセージを送信できません';

  @override
  String get failureReportOwnMessageNotAllowed => '自分のメッセージは報告できません';

  @override
  String get failureTradeSessionAlreadyActive => '進行中のセッションがあります';

  @override
  String get failureTradeSessionNotFound => 'セッションが見つかりません';

  @override
  String get failureTradeSessionFinished => 'すでに終了したセッションです';

  @override
  String get failureTradeInsufficientCash => '残高が不足しています';

  @override
  String get failureTradeInsufficientQuantity => '保有数量が不足しています';

  @override
  String get failureTradeQuantityInvalid => '数量は0より大きくなければなりません';

  @override
  String get failureTradeSessionNotShareable => '終了したセッションのみ共有できます';

  @override
  String get failureCommuteNotConfigured => '自宅駅と勤務先駅を先に設定してください';

  @override
  String get failureLocationPermissionDenied => '位置情報の権限を利用できません';

  @override
  String get failureLocationServiceDisabled => '位置情報サービスがオフになっています';

  @override
  String get failureLocationStreamFailed => '位置情報を受け取れていません';

  @override
  String get failureLocationTimeout => '現在地を取得できませんでした';

  @override
  String get failureRouteSearchFailed => '通勤経路を検索できませんでした';

  @override
  String get tradeHomeTitle => '模擬投資';

  @override
  String get tradeStart => '新しい回を始める';

  @override
  String get tradeResume => '続きから';

  @override
  String tradeStepOf(int step, int total) {
    return '$step / $total';
  }

  @override
  String get tradeEquity => '評価額';

  @override
  String get tradePastSessions => 'これまでの回';

  @override
  String get tradeEmptyTitle => 'まだ遊んだ回がありません';

  @override
  String get tradeEmptyDescription => '過去のチャートを1日ずつ進めながら売買してみましょう';

  @override
  String get tradeResultTitle => '結果';

  @override
  String get tradeReturn => '収益率';

  @override
  String get tradeBuyHold => '保有し続けた場合';

  @override
  String get tradeMaxDrawdown => '最大ドローダウン';

  @override
  String get tradeCount => '売買回数';

  @override
  String tradeCountValue(int count) {
    return '$count回';
  }

  @override
  String tradeBeatBuyHold(String diff) {
    return '保有より$diff良い結果です';
  }

  @override
  String tradeLostToBuyHold(String diff) {
    return '保有より$diff劣る結果です';
  }

  @override
  String get tradeResultNotReady => 'まだ終わっていない回です';

  @override
  String get tradeShare => '共有する';

  @override
  String tradeCardBuyHold(String pct) {
    return '保有のみ $pct';
  }

  @override
  String tradeCardMaxDrawdown(String pct) {
    return '最大ドローダウン $pct';
  }

  @override
  String tradeCardCount(int count) {
    return '売買 $count回';
  }

  @override
  String get tradeSessionTitle => '模擬投資';

  @override
  String get tradeFinishNow => '清算して終了';

  @override
  String get tradeFinishConfirmTitle => '今すぐ終了しますか？';

  @override
  String get tradeFinishConfirmMessage => '保有数量を現在価格ですべて売却して結果を表示します。取り消せません。';

  @override
  String get tradeCash => '現金';

  @override
  String get tradeQuantity => '保有数量';

  @override
  String get tradeCurrentReturn => '現在の収益率';

  @override
  String get tradeCurrentPrice => '現在価格';

  @override
  String tradeChartSemantics(
    int visibleCount,
    int totalCount,
    String currentPrice,
  ) {
    return '全$totalCount本中$visibleCount本を表示、現在価格$currentPrice';
  }

  @override
  String tradeChartEmptySemantics(int totalCount) {
    return 'まだローソク足は表示されていません。全$totalCount本';
  }

  @override
  String get tradeBuy => '買う';

  @override
  String get tradeSell => '売る';

  @override
  String get tradeNextDay => '次の日';

  @override
  String get tradeByAmount => '金額';

  @override
  String get tradeByQuantity => '数量';

  @override
  String get tradeExpectedQuantity => '予想数量';

  @override
  String get tradeExpectedProceeds => '予想受取額';

  @override
  String get tradeFee => '手数料';

  @override
  String get tradeRemainingCash => '注文後の現金';

  @override
  String get tradeRemainingQuantity => '注文後の保有数量';

  @override
  String get tradeConfirmOrder => '注文する';

  @override
  String get tradeInvalidNumber => '有効な数値を入力してください';

  @override
  String get tradeQuantityMustBePositive => '0より大きい値を入力してください';

  @override
  String get tradeOrderPlaced => '注文が約定しました';

  @override
  String tradeFractionLabel(int pct) {
    return '$pct%';
  }

  @override
  String get commuteSettingsTitle => '通勤設定';

  @override
  String get commuteSettingsDescription => '自宅と職場の近くの駅を選択してください';

  @override
  String get commuteHomeStation => '自宅の駅';

  @override
  String get commuteWorkStation => '職場の駅';

  @override
  String get commuteStationNotSet => '駅を選択してください';

  @override
  String get commuteStationSearchTitle => '駅を検索';

  @override
  String get commuteStationSearchHint => '駅名を入力してください';

  @override
  String get commuteStationSearchPrompt => '駅名で検索してください';

  @override
  String get commuteStationSearchEmpty => '駅が見つかりません';

  @override
  String get commuteAppTitle => '通勤時間';

  @override
  String get commuteDirectionToWork => '出勤';

  @override
  String get commuteDirectionToHome => '帰宅';

  @override
  String get commuteCurrentLocationOrigin => '現在地から';

  @override
  String get commuteHomeFallbackOrigin => '自宅から · 位置情報を取得できませんでした';

  @override
  String get commuteWorkFallbackOrigin => '職場から · 位置情報を取得できませんでした';

  @override
  String get commuteModeSubway => '地下鉄';

  @override
  String get commuteModeBus => 'バス';

  @override
  String get commuteModeBest => '最適';

  @override
  String commuteDurationMinutes(int minutes) {
    return '$minutes分';
  }

  @override
  String commuteTransferCount(int count) {
    return '乗換 $count回';
  }

  @override
  String get commuteSettingsRequiredTitle => '通勤駅の設定が必要です';

  @override
  String get commuteSettingsRequiredDescription => '自宅と職場の駅を先に選択してください';

  @override
  String get commuteOpenSettings => '設定する';

  @override
  String get commuteOpenSettingsTooltip => '通勤設定';

  @override
  String get walkAppTitle => 'Life Tool';

  @override
  String get walkToday => '今日';

  @override
  String walkStepsCount(String steps) {
    return '$steps 歩';
  }

  @override
  String walkGoalOf(String goal) {
    return '目標 $goal';
  }

  @override
  String walkGoalRemaining(String steps) {
    return '目標まで $steps';
  }

  @override
  String walkGoalRemainingWithDistance(String steps, String distance) {
    return '目標まで $steps · 約 $distance';
  }

  @override
  String walkGoalExceeded(String steps) {
    return '目標より $steps 多く歩きました';
  }

  @override
  String get walkGoalReached => '達成';

  @override
  String walkGoalDaysReached(int reached, int total) {
    return '達成 $reached/$total日';
  }

  @override
  String walkGoalOfPercent(int percent) {
    return '目標の $percent%';
  }

  @override
  String walkGoalRingSemantics(String steps, String goal, int percent) {
    return '今日 $steps、目標 $goal の $percent%';
  }

  @override
  String get walkGoalLine => '目標';

  @override
  String get walkSettingsWalk => 'ウォーキング';

  @override
  String get walkSettingsStepGoal => '1日の目標';

  @override
  String get walkSettingsStepGoalSave => '保存';

  @override
  String get walkTabWeek => '週間';

  @override
  String get walkTabMonth => '月間';

  @override
  String get walkTotalSteps => '合計';

  @override
  String get walkAverageSteps => '1日平均';

  @override
  String get walkDistance => '距離';

  @override
  String get walkActiveCalories => '活動カロリー';

  @override
  String get walkPreviousPeriod => '前へ';

  @override
  String get walkNextPeriod => '次へ';

  @override
  String get walkHealthConnectMissing => 'Health Connect が必要です';

  @override
  String get walkHealthConnectMissingDescription =>
      'ヘルスアプリが Health Connect に記録した歩数を読み取ります';

  @override
  String get walkInstall => 'インストール';

  @override
  String get walkHealthConnectUpdate => 'Health Connect をアップデートしてください';

  @override
  String get walkUpdate => 'アップデート';

  @override
  String get walkPermissionNeeded => '歩数を読み取る許可が必要です';

  @override
  String get walkPermissionDescription => '歩数・距離・活動カロリーを読み取るだけで、保存や送信はしません';

  @override
  String get walkGrantPermission => '許可する';

  @override
  String get walkOpenSettings => '設定を開く';

  @override
  String get walkLoadFailed => '記録を読み込めませんでした';

  @override
  String get walkAlarmDefaultTitle => 'アラーム';

  @override
  String get walkAlarmStop => 'アラームを止める';

  @override
  String walkAlarmSnooze(int minutes) {
    return '$minutes分後に再通知';
  }

  @override
  String get walkReminderSoonTitle => 'まもなくアラームが鳴ります';

  @override
  String walkReminderSoonBody(String time, String label) {
    return '$time $label';
  }

  @override
  String get walkReminderTurnOffOnce => '今回だけオフ';

  @override
  String get walkReminderHolidayTitle => '祝日に鳴るアラーム';

  @override
  String walkReminderHolidayBody(String date, String name, String time) {
    return '$date $timeのアラームは祝日に鳴ります';
  }

  @override
  String walkReminderHolidayBodyNoName(String date, String time) {
    return '$date $timeのアラームは祝日に鳴ります';
  }

  @override
  String get walkReminderSkip => '次のアラームをスキップ';

  @override
  String get walkReminderRing => '鳴らす';

  @override
  String get walkAlarmRingSettings => '鳴動設定';

  @override
  String walkAlarmRingSummary(int volume, String snooze, String autoStop) {
    return '音量 $volume% · スヌーズ $snooze · 自動停止 $autoStop';
  }

  @override
  String get walkAlarmAutoStopNone => 'なし';

  @override
  String get walkAlarmVolume => '音量';

  @override
  String walkAlarmPercent(int percent) {
    return '$percent%';
  }

  @override
  String get walkAlarmFade => 'だんだん大きく';

  @override
  String get walkAlarmFadeOff => 'オフ';

  @override
  String walkAlarmSeconds(int seconds) {
    return '$seconds秒';
  }

  @override
  String get walkAlarmSnoozeInterval => 'スヌーズ間隔';

  @override
  String get walkAlarmSnoozeLimit => 'スヌーズ回数';

  @override
  String get walkAlarmSnoozeUnlimited => '無制限';

  @override
  String walkAlarmTimes(int count) {
    return '$count回';
  }

  @override
  String get walkAlarmAutoStop => '自動停止';

  @override
  String get walkAlarmAutoStopNever => 'しない';

  @override
  String walkAlarmMinutes(int minutes) {
    return '$minutes分';
  }

  @override
  String get walkAlarmRemindBefore => '30分前に知らせる';

  @override
  String get walkAlarmRemindBeforeHint => '通知から今回だけオフにできます';

  @override
  String get walkAlarmSkipNext => '次のアラームをスキップ';

  @override
  String get walkAlarmUnskip => 'スキップを取り消す';

  @override
  String get walkAlarmSkipped => 'スキップ';

  @override
  String get walkAlarmHolidayChip => '祝日';

  @override
  String get walkSettingsAlarm => 'アラーム';

  @override
  String get walkSettingsHolidayReminder => '祝日のお知らせ';

  @override
  String get walkSettingsHolidayReminderDescription =>
      '繰り返しアラームが祝日に鳴るとき前日にお知らせします';

  @override
  String get walkSettingsHolidaySource => '祝日の情報元';

  @override
  String walkSettingsHolidaySourceDevice(String name) {
    return '端末のカレンダー: $name';
  }

  @override
  String get walkSettingsHolidaySourceDeviceUnnamed => '端末のカレンダー';

  @override
  String walkSettingsHolidaySourceBundled(String firstYear, String lastYear) {
    return '内蔵の表 $firstYear–$lastYear';
  }

  @override
  String get walkSettingsCalendarGranted => 'カレンダー許可済み';

  @override
  String get walkSettingsCalendarNeedsPermission => 'カレンダーの許可が必要 ›';

  @override
  String get walkShellTabAlarm => 'アラーム';

  @override
  String get walkShellTabWalk => 'ウォーク';

  @override
  String get walkShellTabSettings => '設定';

  @override
  String get walkShellTabDiary => '日記';

  @override
  String get walkDiaryDailyStoryTitle => '日常';

  @override
  String get walkDiaryAll => 'すべて';

  @override
  String get walkDiaryArchive => 'アーカイブ';

  @override
  String get walkDiaryEmpty => 'まだ記録がありません';

  @override
  String get walkDiaryToday => '今日';

  @override
  String get walkDiaryYesterday => '昨日';

  @override
  String get walkDiaryNow => 'たった今';

  @override
  String get walkDiaryOngoing => '進行中';

  @override
  String walkDiaryStoryPeriod(String start, String end) {
    return '$start〜$end';
  }

  @override
  String get walkDiaryViewProse => '文章';

  @override
  String get walkDiaryViewFeed => 'フィード';

  @override
  String get walkDiaryViewReels => 'リール';

  @override
  String get walkDiaryShowMore => 'もっと見る';

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
  String get walkDiaryLoadError => '記録を読み込めませんでした';

  @override
  String get walkAlarmListTitle => 'アラーム';

  @override
  String get walkAlarmEmpty => 'アラームがありません';

  @override
  String get walkAlarmEmptyDescription => '＋をタップして目覚ましを追加しましょう';

  @override
  String get walkAlarmAdd => 'アラームを追加';

  @override
  String get walkAlarmNextTitle => '次のアラーム';

  @override
  String walkAlarmIn(String duration) {
    return '$duration後';
  }

  @override
  String get walkAlarmNoneEnabled => 'オンのアラームはありません';

  @override
  String get walkAlarmNoneScheduled => '予約されたアラームはありません';

  @override
  String get walkAlarmNoneScheduledHint => '権限を確認してください';

  @override
  String get walkAlarmLoadFailed => 'アラームを読み込めませんでした';

  @override
  String get walkAlarmDayToday => '今日';

  @override
  String get walkAlarmDayTomorrow => '明日';

  @override
  String walkAlarmRingsIn(String duration) {
    return '$duration後に鳴ります';
  }

  @override
  String get walkAlarmSavedPausedOut => 'アラームを休む期間なので鳴りません';

  @override
  String get walkAlarmPausedOutRow => '休み中';

  @override
  String walkAlarmDurationMinutes(int minutes) {
    return '$minutes分';
  }

  @override
  String walkAlarmDurationHours(int hours) {
    return '$hours時間';
  }

  @override
  String walkAlarmDurationHoursMinutes(int hours, int minutes) {
    return '$hours時間$minutes分';
  }

  @override
  String walkAlarmDurationDays(int days) {
    return '$days日';
  }

  @override
  String walkAlarmDurationDaysHours(int days, int hours) {
    return '$days日$hours時間';
  }

  @override
  String get walkAlarmPermissionWarning => 'アラームが鳴らない可能性があります';

  @override
  String get walkAlarmPermissionWarningAction => '設定タブで権限を確認してください';

  @override
  String get walkAlarmRepeatDaily => '毎日';

  @override
  String get walkAlarmRepeatWeekdays => '平日';

  @override
  String get walkAlarmRepeatWeekends => '週末';

  @override
  String get walkAlarmRepeatOnce => '1回';

  @override
  String get walkAlarmEdit => 'アラームを編集';

  @override
  String get walkAlarmSound => 'アラーム音';

  @override
  String get walkAlarmSoundSystem => 'システムのデフォルト';

  @override
  String get walkAlarmSoundBundledSection => 'アプリのサウンド';

  @override
  String get walkAlarmSoundDeviceSection => '端末のアラーム音';

  @override
  String get walkAlarmSoundBeep => 'ビープ';

  @override
  String get walkAlarmSoundChime => 'チャイム';

  @override
  String get walkAlarmSoundRising => 'だんだん速く';

  @override
  String get walkAlarmSoundSelect => '選択';

  @override
  String get walkAlarmSoundDeviceUnavailable => '端末のアラーム音を読み込めませんでした';

  @override
  String get walkAlarmSoundImportFailed => 'このアラーム音は使えません';

  @override
  String get walkAlarmDeleteTitle => 'このアラームを削除しますか？';

  @override
  String get walkAlarmDeleteContent => '削除したアラームは元に戻せません';

  @override
  String get walkAlarmDuplicate => '複製';

  @override
  String get walkAlarmPause => 'アラームを休む';

  @override
  String get walkAlarmPauseDescription => '選んだ期間はすべてのアラームが鳴りません。スイッチはそのままです。';

  @override
  String get walkAlarmPauseToday => '今日だけ';

  @override
  String get walkAlarmPauseUntilTomorrow => '明日まで';

  @override
  String get walkAlarmPauseWeekend => '今週末';

  @override
  String get walkAlarmPausePickDates => '日付を選ぶ';

  @override
  String walkAlarmPausedUntil(String until) {
    return '$untilまでアラームを休みます';
  }

  @override
  String walkAlarmPausedRange(String from, String until) {
    return '$fromから$untilまでアラームを休みます';
  }

  @override
  String get walkAlarmPauseStop => '休むのをやめる';

  @override
  String get walkAlarmHistory => '鳴動履歴';

  @override
  String get walkAlarmHistoryEmpty => 'まだ履歴がありません';

  @override
  String get walkAlarmHistoryEmptyHint => 'アラームが鳴って止まると、ここに30日間残ります';

  @override
  String get walkAlarmHistoryLoadFailed => '履歴を読み込めませんでした';

  @override
  String walkAlarmHistoryRang(String time) {
    return '$time 鳴動';
  }

  @override
  String walkAlarmHistorySnoozes(int count) {
    return 'スヌーズ $count回';
  }

  @override
  String walkAlarmHistoryStopped(String time) {
    return '$time 停止';
  }

  @override
  String walkAlarmHistoryAutoStopped(String time) {
    return '$time 自動停止';
  }

  @override
  String get walkAlarmHistoryDeleted => '削除したアラーム';

  @override
  String get walkAlarmSaveFailed => 'アラームを保存できませんでした';

  @override
  String get walkAlarmKindTitle => 'どんなアラームにしますか';

  @override
  String get walkAlarmKindOneShot => '1回';

  @override
  String get walkAlarmKindOneShotHint => '今から指定した時間後に鳴ります';

  @override
  String get walkAlarmKindRepeat => '繰り返し';

  @override
  String get walkAlarmKindRepeatHint => '選んだ曜日ごとに鳴ります';

  @override
  String get walkAlarmNewOneShot => '1回のアラーム';

  @override
  String get walkAlarmNewRepeat => '繰り返しアラーム';

  @override
  String walkAlarmAfter(String duration) {
    return '$duration後';
  }

  @override
  String walkAlarmRingsAtChip(String time) {
    return '$timeに鳴ります';
  }

  @override
  String walkAlarmWheelHourSemantics(int hour) {
    return '$hour時';
  }

  @override
  String walkAlarmAddHour(int hours) {
    return '+$hours時間';
  }

  @override
  String walkAlarmAddMinutes(int minutes) {
    return '+$minutes分';
  }

  @override
  String get walkAlarmReset => 'リセット';

  @override
  String get walkAlarmNeedTime => '時間を追加してください';

  @override
  String get walkAlarmNeedDays => '曜日を選んでください';

  @override
  String get walkAlarmPickTimeConfirm => 'この時刻にする';

  @override
  String get walkAlarmPresetEveryday => '毎日';

  @override
  String get walkAlarmPresetWeekdays => '平日';

  @override
  String get walkAlarmPresetWeekend => '週末';

  @override
  String get walkAlarmTitle => 'タイトル';

  @override
  String get walkAlarmTitleHint => '例: 出勤';

  @override
  String get walkAlarmSilentWhenMuted => 'マナー・サイレントモードでは振動のみ';

  @override
  String get walkAlarmSilentWhenMutedHint => '端末がマナーやサイレントモードのときは音を出さず振動で知らせます';

  @override
  String walkAlarmOneShotRow(String remaining) {
    return '1回 · $remaining';
  }

  @override
  String get walkSettingsTitle => '設定';

  @override
  String get walkSettingsPermissions => '権限';

  @override
  String get walkSettingsNotification => '通知';

  @override
  String get walkSettingsNotificationDescription => 'アラーム通知と停止ボタンを表示します';

  @override
  String get walkSettingsExactAlarm => 'アラームとリマインダー';

  @override
  String get walkSettingsExactAlarmDescription => '設定した時刻ちょうどに鳴ります';

  @override
  String get walkSettingsFullScreen => '全画面通知';

  @override
  String get walkSettingsFullScreenDescription => 'ロック画面にアラーム画面を表示します';

  @override
  String get walkSettingsHealthConnect => 'ヘルスコネクト';

  @override
  String get walkSettingsHealthConnectDescription => '歩数の記録を読み取ります';

  @override
  String get walkSettingsGranted => '許可済み';

  @override
  String get walkSettingsNeedsPermission => '許可が必要 ›';

  @override
  String get walkSettingsNeedsInstall => 'インストールが必要 ›';

  @override
  String get walkSettingsNeedsUpdate => 'アップデートが必要 ›';

  @override
  String get walkSettingsTheme => 'テーマ';

  @override
  String get walkSettingsThemeSystem => 'システム設定';

  @override
  String get walkSettingsThemeLight => 'ライト';

  @override
  String get walkSettingsThemeDark => 'ダーク';

  @override
  String get failureWalkDogRequired => '一緒に散歩した犬を選んでください';

  @override
  String get failureWalkTrackingAlreadyActive => 'すでに散歩が進行中です';

  @override
  String get failureWalkNotFound => '散歩の記録が見つかりません';

  @override
  String get failureWalkPhotoSaveFailed => '写真を保存できませんでした';

  @override
  String get failureDogNameRequired => '犬の名前を入力してください';

  @override
  String get pawlogAppTitle => 'pawlog';

  @override
  String get walkDogListTitle => 'わんちゃん';

  @override
  String get walkDogListEmptyTitle => '登録されたわんちゃんがいません';

  @override
  String get walkDogListEmptyMessage => '一緒に散歩するわんちゃんを登録してください';

  @override
  String get walkDogAddAction => 'わんちゃんを追加';

  @override
  String get walkDogNewTitle => 'わんちゃんの登録';

  @override
  String get walkDogEditTitle => 'わんちゃんの編集';

  @override
  String get walkDogNameLabel => '名前';

  @override
  String get walkDogBreedLabel => '犬種';

  @override
  String get walkDogBirthdayLabel => '誕生日';

  @override
  String get walkDogBirthdayUnset => '未設定';

  @override
  String get walkDogPhotoChange => '写真を変更';

  @override
  String get walkDogSaveAction => '保存';

  @override
  String get walkDogDeleteAction => '削除';

  @override
  String get walkDogDeleteConfirmTitle => 'わんちゃんを削除しますか？';

  @override
  String get walkDogDeleteConfirmMessage => '散歩の記録は残り、記録からこのわんちゃんだけが外れます。';

  @override
  String get walkActiveTitle => '散歩中';

  @override
  String get walkReadyTitle => '散歩の準備';

  @override
  String get walkSelectDogs => '一緒に歩くわんちゃん';

  @override
  String get walkStart => '散歩を始める';

  @override
  String get walkStop => '散歩を終える';

  @override
  String get walkStopConfirmTitle => '散歩を終えますか？';

  @override
  String get walkStopConfirmMessage => '記録を止めて保存画面に移動します。';

  @override
  String get walkElapsedLabel => '時間';

  @override
  String get walkDistanceLabel => '距離';

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
    return '$minutes分';
  }

  @override
  String get walkDurationUnderMinute => '1分未満';

  @override
  String walkDurationHours(int hours) {
    return '$hours時間';
  }

  @override
  String walkDurationHoursMinutes(int hours, int minutes) {
    return '$hours時間$minutes分';
  }

  @override
  String get walkTrackingNotificationTitle => '散歩を記録しています';

  @override
  String get walkTrackingNotificationText => 'アプリを閉じても経路は記録され続けます';

  @override
  String get walkActiveNoDogsTitle => 'まずわんちゃんを登録してください';

  @override
  String get walkActiveNoDogsMessage => '散歩にはわんちゃんが1匹以上必要です';

  @override
  String get walkOpenDogsAction => 'わんちゃんを登録する';

  @override
  String get walkLocationDeniedHint => '設定で位置情報の権限を許可してからもう一度お試しください';

  @override
  String get walkLocationLostHint => '散歩の記録は続いています。再試行すると位置情報を受け取り直します';

  @override
  String get walkLocationServiceHint => '位置情報サービスをオンにしてからもう一度お試しください';

  @override
  String get walkOpenLocationSettings => '位置情報の設定を開く';

  @override
  String get walkLocating => '位置情報を探しています…';

  @override
  String get walkEditNewTitle => '散歩を保存';

  @override
  String get walkEditTitle => '散歩を編集';

  @override
  String get walkMemoLabel => 'メモ';

  @override
  String get walkMemoHint => '今日の散歩はどうでしたか？';

  @override
  String get walkPhotosLabel => '写真';

  @override
  String get walkAddPhoto => '写真を追加';

  @override
  String get walkRemovePhoto => '写真を削除';

  @override
  String get walkAddPhotoFromGallery => 'アルバムから選ぶ';

  @override
  String get walkAddPhotoFromCamera => 'カメラで撮る';

  @override
  String get walkPhotoLimitReached => '写真は最大10枚まで添付できます';

  @override
  String get walkDiscard => '破棄';

  @override
  String get walkDiscardConfirmTitle => 'この散歩を破棄しますか？';

  @override
  String get walkDiscardConfirmMessage => 'ルートと添付した写真がすべて削除されます。';

  @override
  String get walkNoSessionToSave => '保存する散歩がありません';

  @override
  String get walkBackToFeed => 'フィードに戻る';

  @override
  String get walkDetailTitle => '散歩の記録';

  @override
  String get walkEdit => '編集';

  @override
  String get walkDeleteConfirmTitle => '散歩の記録を削除しますか？';

  @override
  String get walkDeleteConfirmMessage => 'ルートと写真も一緒に削除されます。';

  @override
  String get walkNoTrack => '記録されたルートがありません';

  @override
  String get walkDogsLabel => '一緒に歩いたわんちゃん';

  @override
  String get walkDateLabel => '日付';

  @override
  String get walkFeedEmptyTitle => '最初の散歩を始めましょう';

  @override
  String get walkFeedEmptyMessage => '散歩を終えると、ここに記録が貯まります';

  @override
  String get walkFeedEmptyActiveTitle => '最初の散歩がもうすぐここに表示されます';

  @override
  String get walkFeedEmptyActiveMessage => '上のバナーから散歩を終えて保存してください';

  @override
  String get walkContinue => '散歩を続ける';

  @override
  String get walkInProgressBanner => '散歩中です · タップして戻る';

  @override
  String get walkUnsavedBanner => '保存していない散歩があります · タップして保存';

  @override
  String get walkOpenDogsTooltip => 'わんちゃん';

  @override
  String get walkLockTitle => '日記はロックされています';

  @override
  String get walkLockEnterPin => '4桁のPINを入力してください';

  @override
  String get walkLockEnterPattern => 'パターンを描いてください';

  @override
  String get walkLockWrong => '違います。もう一度お試しください';

  @override
  String walkLockBlocked(int seconds) {
    return '$seconds秒後にもう一度お試しください';
  }

  @override
  String walkLockBlockedLong(int hours, int minutes) {
    return '本人確認に失敗しました。$hours時間$minutes分後にもう一度お試しください';
  }

  @override
  String get walkLockForgot => '忘れました';

  @override
  String get walkLockDeviceReason => '日記のロックを再設定するには本人確認が必要です';

  @override
  String get walkLockDeviceUnavailable => '今は本人確認を使えません。スマホの画面ロック設定を確認してください';

  @override
  String get walkLockPinDelete => '削除';

  @override
  String get walkLockSetupTitle => '日記のロック';

  @override
  String get walkLockSetupChoose => 'ロック方法を選んでください';

  @override
  String get walkLockSetupPin => '4桁のPIN';

  @override
  String get walkLockSetupPattern => 'パターン';

  @override
  String walkLockSetupInUse(String method) {
    return '$method（使用中）';
  }

  @override
  String get walkLockSetupOff => 'ロックをオフにする';

  @override
  String get walkLockSetupVerify => '今のPIN・パターンを入力してください';

  @override
  String get walkLockSetupNewPin => '新しい4桁のPINを入力してください';

  @override
  String get walkLockSetupNewPattern => '4つ以上の点をつないで新しいパターンを描いてください';

  @override
  String get walkLockSetupConfirm => '確認のためもう一度入力してください';

  @override
  String get walkLockSetupMismatch => '最初の入力と違います。最初からやり直してください';

  @override
  String get walkLockSetupTooShort => '4つ以上の点をつないでください';

  @override
  String get walkLockSetupPinInvalid => '4桁の数字を入力してください';

  @override
  String get walkLockSetupSaved => '日記のロック設定を保存しました';

  @override
  String get walkLockNeedsScreenLock => '日記のロックをオンにするには、先にスマホの画面ロックを設定してください';

  @override
  String get walkLockOpenScreenLockSettings => '画面ロックの設定を開く';

  @override
  String get walkDiaryEditorNewTitle => '新しい記録';

  @override
  String get walkDiaryEditorEditTitle => '記録を編集';

  @override
  String get walkDiaryEditorPost => '投稿';

  @override
  String get walkDiaryEditorSave => '保存';

  @override
  String get walkDiaryEditorClose => '閉じる';

  @override
  String walkDiaryEditorTimeNow(String when) {
    return '今 · $when';
  }

  @override
  String walkDiaryEditorDateTime(String date, String time) {
    return '$date $time';
  }

  @override
  String get walkDiaryEditorRevertTime => '投稿時刻に戻す';

  @override
  String get walkDiaryEditorPickTimeConfirm => '決定';

  @override
  String get walkDiaryEditorLocating => '位置を取得中…';

  @override
  String get walkDiaryEditorUnnamedPlace => '名前のない場所';

  @override
  String get walkDiaryEditorRemoveLocation => '位置を外す';

  @override
  String get walkDiaryEditorPlaceHint => '場所の名前';

  @override
  String walkDiaryEditorStory(String title) {
    return 'ストーリー: $title';
  }

  @override
  String get walkDiaryEditorPickStory => 'ストーリーを選ぶ';

  @override
  String get walkDiaryEditorAddMedia => '写真・動画を追加';

  @override
  String get walkDiaryEditorRemoveMedia => '外す';

  @override
  String get walkDiaryEditorPickGallery => 'アルバムから選ぶ';

  @override
  String get walkDiaryEditorTakePhoto => '写真を撮る';

  @override
  String get walkDiaryEditorTakeVideo => '動画を撮る';

  @override
  String get walkDiaryEditorBodyHint => '今日あったことを書いてみましょう';

  @override
  String get walkDiaryEditorTagHint => 'タグを追加';

  @override
  String get walkDiaryEditorDiscardTitle => '作成をやめますか?';

  @override
  String get walkDiaryEditorDiscardContent => '書いた内容は保存されません。';

  @override
  String get walkDiaryEditorDiscardConfirm => 'やめる';

  @override
  String get walkDiaryErrorEmptyEntry => '文章か写真・動画を入れてください';

  @override
  String get walkDiaryErrorFutureTime => '未来の時刻は選べません';

  @override
  String walkDiaryErrorTooManyMedia(int max) {
    return '写真・動画は$max件まで追加できます';
  }

  @override
  String walkDiaryErrorVideoTooLong(int seconds) {
    return '$seconds秒以下の動画のみ追加できます';
  }

  @override
  String get walkDiaryErrorStoryClosed => '終了したストーリーには書けません';

  @override
  String get walkDiaryErrorNotFound => '記録が見つかりません';

  @override
  String get walkDiaryErrorMediaProcessing => '写真・動画を読み込めませんでした';

  @override
  String get walkDiaryErrorSave => '保存できませんでした。もう一度お試しください';

  @override
  String walkDiaryEditorTagSuggestion(String name, int count) {
    return '#$name $count';
  }

  @override
  String walkDiaryEditorPlaceSuggestion(String name, int count) {
    return '$name $count';
  }

  @override
  String get walkDiaryMenuStories => 'ストーリー管理';

  @override
  String get walkDiaryStoryNew => '新しいストーリー';

  @override
  String get walkDiaryStoryRename => '名前を変更';

  @override
  String get walkDiaryStoryCover => 'カバーを変更';

  @override
  String get walkDiaryStoryClose => '終了';

  @override
  String get walkDiaryStoryReopen => '再開';

  @override
  String get walkDiaryStoryDelete => '削除';

  @override
  String walkDiaryStoryDeleteTitle(String title) {
    return '「$title」を削除しますか?';
  }

  @override
  String get walkDiaryStoryDeleteContent =>
      'このストーリーの記録はゴミ箱に移動します。復元すると「日常」に戻ります。';

  @override
  String get walkDiaryStoryTitleLabel => 'タイトル';

  @override
  String walkDiaryStoryStart(String date) {
    return '開始日 $date';
  }

  @override
  String walkDiaryStoryEnd(String date) {
    return '終了日 $date';
  }

  @override
  String get walkDiaryStoryNoEnd => '終了日なし(進行中)';

  @override
  String get walkDiaryStoryClearEnd => '終了日を消す';

  @override
  String get walkDiaryStoryCreate => '作成';

  @override
  String get walkDiaryStorySave => '保存';

  @override
  String get walkDiaryStoryCloseNow => '今すぐ終了';

  @override
  String get walkDiaryStoryCloseOnDate => '日付を選んで終了';

  @override
  String get walkDiaryStoryCoverAuto => '自動(最新の写真)';

  @override
  String get walkDiaryStoryCoverEmpty => 'このストーリーにはまだ写真がありません';

  @override
  String get walkDiaryStoryMoveTitle => 'この期間の「日常」の記録を移動しますか?';

  @override
  String walkDiaryStoryMoveConfirm(int count) {
    return '$count件を移動';
  }

  @override
  String get walkDiaryStoryMoveSkip => 'スキップ';

  @override
  String walkDiaryStoryMoved(int count) {
    return '$count件の記録を移動しました';
  }

  @override
  String get walkDiaryErrorEndBeforeStart => '終了日を開始日より前にはできません';

  @override
  String get walkDiaryErrorDefaultStoryLocked => 'デフォルトのストーリーは終了・削除できません';

  @override
  String get walkDiaryEntryEdit => '編集';

  @override
  String get walkDiaryEntryDelete => '削除';

  @override
  String get walkDiaryEntryDeleteTitle => '記録を削除しますか?';

  @override
  String get walkDiaryEntryDeleteContent => 'ゴミ箱に移動します。ゴミ箱から復元できます。';

  @override
  String get walkDiaryEntryTrashed => '記録をゴミ箱に移動しました';

  @override
  String get walkDiaryEntryTrashFailed => 'ゴミ箱に移動できませんでした。もう一度お試しください';

  @override
  String walkDiaryEntryDateTime(String date, String time) {
    return '$date $time';
  }

  @override
  String get walkDiarySearch => '検索';

  @override
  String get walkDiarySearchHint => '日記を検索';

  @override
  String get walkDiarySearchTabBody => '本文';

  @override
  String get walkDiarySearchTabStory => 'ストーリー';

  @override
  String get walkDiarySearchTabTag => 'ハッシュタグ';

  @override
  String get walkDiarySearchTabPlace => '場所';

  @override
  String get walkDiarySearchBodyPrompt => '本文から探す言葉を入力してください';

  @override
  String get walkDiarySearchStoryPrompt => '探すストーリー名を入力してください';

  @override
  String get walkDiarySearchNoResults => '見つかりませんでした';

  @override
  String walkDiaryEntryCount(int count) {
    return '記録$count件';
  }

  @override
  String get walkDiaryCollectionEmpty => '表示する記録がありません';

  @override
  String get walkDiaryMenuTrash => 'ごみ箱';

  @override
  String get walkDiaryTrashEmpty => 'ごみ箱は空です';

  @override
  String walkDiaryTrashDaysLeft(int days) {
    return 'あと$days日';
  }

  @override
  String get walkDiaryTrashDueToday => '今日削除されます';

  @override
  String get walkDiaryTrashNoBody => '(本文なし)';

  @override
  String get walkDiaryTrashRestore => '元に戻す';

  @override
  String get walkDiaryTrashDeleteForever => '完全に削除';

  @override
  String get walkDiaryTrashEmptyAll => 'ごみ箱を空にする';

  @override
  String get walkDiaryTrashPurgeTitle => '完全に削除しますか?';

  @override
  String get walkDiaryTrashPurgeContent => '元に戻せません。写真と動画も一緒に削除されます。';

  @override
  String get walkDiaryTrashEmptyAllTitle => 'ごみ箱を空にしますか?';

  @override
  String walkDiaryTrashEmptyAllContent(int count) {
    return '記録$count件が完全に削除されます。元に戻せません。';
  }

  @override
  String get walkDiaryTrashRestored => '記録を元に戻しました';

  @override
  String get walkDiaryTrashPurged => '記録を完全に削除しました';

  @override
  String get walkDiaryTrashEmptied => 'ごみ箱を空にしました';

  @override
  String get walkDiaryTrashRestoreFailed => '復元できませんでした。もう一度お試しください';

  @override
  String get walkDiaryTrashDeleteFailed => '削除できませんでした。もう一度お試しください';

  @override
  String get walkDiarySettings => '日記';

  @override
  String get walkDiarySettingsLock => '日記のロック';

  @override
  String get walkDiarySettingsLockOff => 'オフ';

  @override
  String get walkDiarySettingsRelock => '再ロックまでの時間';

  @override
  String get walkDiarySettingsRelockImmediate => 'すぐ';

  @override
  String get walkDiarySettingsRelock30s => '30秒後';

  @override
  String get walkDiarySettingsRelock1m => '1分後';

  @override
  String get walkDiarySettingsRelock5m => '5分後';

  @override
  String get walkDiarySettingsRetention => 'ゴミ箱の保管期間';

  @override
  String get walkDiarySettingsRetention1d => '1日';

  @override
  String get walkDiarySettingsRetention7d => '7日';

  @override
  String get walkDiarySettingsRetention30d => '30日';

  @override
  String get walkDiarySettingsRetentionNever => '削除しない';

  @override
  String get walkDiarySettingsStorage => '保存容量';

  @override
  String walkDiarySettingsStorageUsage(String size) {
    return '使用中 $size';
  }

  @override
  String walkDiarySettingsStorageDetail(int photos, int videos, String trash) {
    return '写真$photos枚・動画$videos本、ゴミ箱$trashを含む';
  }

  @override
  String get walkDiarySettingsLocalOnly =>
      '記録はこのスマホにだけ保存されます。アプリを削除するといっしょに消えます。';

  @override
  String get walkStatsTitle => '散歩の記録';

  @override
  String get walkStatsWeek => '週';

  @override
  String get walkStatsMonth => '月';

  @override
  String get walkStatsPreviousTooltip => '前の期間';

  @override
  String get walkStatsNextTooltip => '次の期間';

  @override
  String get walkStatsDistanceLabel => '距離';

  @override
  String get walkStatsDurationLabel => '時間';

  @override
  String get walkStatsCountLabel => '散歩';

  @override
  String walkStatsCountValue(int count) {
    return '$count回';
  }

  @override
  String walkStatsMoreThanLastWeek(String distance) {
    return '先週より$distance多く歩きました';
  }

  @override
  String walkStatsLastWeek(String distance) {
    return '先週 $distance';
  }

  @override
  String walkStatsMoreThanLastMonth(String distance) {
    return '先月より$distance多く歩きました';
  }

  @override
  String walkStatsLastMonth(String distance) {
    return '先月 $distance';
  }

  @override
  String walkStatsBarSemantics(String label, String distance) {
    return '$label $distance';
  }

  @override
  String get walkStatsRecordsTitle => '記録';

  @override
  String get walkStatsCurrentStreak => '連続散歩';

  @override
  String get walkStatsLongestStreak => '最長連続';

  @override
  String walkStatsDays(int count) {
    return '$count日';
  }

  @override
  String get walkStatsFarthestWalk => 'いちばん遠い散歩';

  @override
  String get walkStatsLongestWalk => 'いちばん長い散歩';

  @override
  String get walkStatsEmptyTitle => 'まだ記録がありません';

  @override
  String get walkStatsEmptyMessage => '散歩を記録するとここに積み上がります';

  @override
  String walkFeedWeekSummary(String distance, int count) {
    return '今週 $distance・$count回';
  }

  @override
  String get walkFeedWeekSummaryEmpty => '今週はまだ散歩していません';

  @override
  String get walkPause => '一時停止';

  @override
  String get walkUnpause => '再開';

  @override
  String get walkPausedLabel => '一時停止中';

  @override
  String get walkPausedBanner => '散歩を一時停止中';

  @override
  String get walkExportGpx => 'GPXで書き出す';

  @override
  String get walkExportNoRoute => '書き出せる経路がありません';

  @override
  String get walkExportFailed => '書き出せませんでした';

  @override
  String get walkBackupExport => 'バックアップを書き出す';

  @override
  String get walkBackupImport => 'バックアップを読み込む';

  @override
  String get walkBackupImportFromFirstRun => 'バックアップから復元';

  @override
  String get walkBackupExportFailed => 'バックアップを作成できませんでした';

  @override
  String walkBackupImported(int dogs, int walks) {
    return '犬$dogs匹・散歩$walks件を読み込みました';
  }

  @override
  String get walkBackupNothingNew => '新しく読み込む記録はありません';

  @override
  String get walkBackupInvalid => 'バックアップファイルを読み込めませんでした';

  @override
  String get walkBackupImportFailed => '読み込めませんでした';

  @override
  String get walkFeedMoreTooltip => 'その他';

  @override
  String get walkFavoriteAdd => 'お気に入りに追加';

  @override
  String get walkFavoriteRemove => 'お気に入りから外す';

  @override
  String get walkFeedShowFavorites => 'お気に入りだけ表示';

  @override
  String get walkFeedShowAll => 'すべての散歩を表示';

  @override
  String get walkFeedFavoritesEmptyTitle => 'お気に入りの散歩はまだありません';

  @override
  String get walkFeedFavoritesEmptyMessage => '散歩の詳細で星をタップしてください';

  @override
  String get walkFavoriteLabel => 'お気に入り';

  @override
  String get walkSocialTitle => 'みんなの散歩';

  @override
  String get walkSocialSignIn => 'ログイン';

  @override
  String get walkSocialSignUp => '登録';

  @override
  String get walkSocialSignOut => 'ログアウト';

  @override
  String get walkSocialEmail => 'メール';

  @override
  String get walkSocialPassword => 'パスワード';

  @override
  String get walkSocialNickname => 'ニックネーム';

  @override
  String get walkSocialSwitchToSignUp => '初めての方は登録';

  @override
  String get walkSocialSwitchToSignIn => 'アカウントをお持ちの方はログイン';

  @override
  String get walkSocialSignInRequired => 'ログインすると共有やいいねができます';

  @override
  String get walkSocialAuthFailed => 'ログインできませんでした。メールとパスワードを確認してください';

  @override
  String get walkSocialNicknameTaken => 'そのニックネームは使われています';

  @override
  String get walkSocialEmpty => 'まだ共有された散歩はありません';

  @override
  String get walkSocialOpenTooltip => 'みんなの散歩';

  @override
  String get walkSocialLoadFailed => 'みんなの散歩を読み込めませんでした';

  @override
  String get walkSocialShare => 'みんなに共有';

  @override
  String get walkSocialUnshare => '共有をやめる';

  @override
  String get walkSocialShared => '共有しました';

  @override
  String get walkSocialUnshared => '共有をやめました';

  @override
  String get walkSocialShareFailed => '共有できませんでした';

  @override
  String get walkSocialLikeTooltip => 'いいね';

  @override
  String get walkSocialUnshareOnDeleteFailed => '散歩は削除しましたが、共有をやめられませんでした';

  @override
  String get walkSocialUpdateFailed => '記録は保存しましたが、共有した投稿は更新できませんでした';

  @override
  String get walkShellTabCommute => '通勤';

  @override
  String get walkCommuteToWork => '出勤';

  @override
  String get walkCommuteToHome => '退勤';

  @override
  String get walkCommuteQuery => '照会';

  @override
  String get walkCommuteVerdictCatchFirst => '歩いても間に合います';

  @override
  String get walkCommuteVerdictCatchSecond => '歩くと今の電車には間に合いません — 次の電車基準';

  @override
  String get walkCommuteVerdictMissBoth => '歩くと2本とも間に合いません';

  @override
  String walkCommuteTrainMinutes(int minutes) {
    return '$minutes分後';
  }

  @override
  String walkCommuteTrainMinutesEstimated(int minutes) {
    return '約$minutes分後';
  }

  @override
  String walkCommuteTrainStationsAway(int count) {
    return '$count駅前';
  }

  @override
  String get walkCommuteTrainArriving => 'まもなく到着';

  @override
  String walkCommuteWalkToStation(int minutes) {
    return '駅まで徒歩$minutes分';
  }

  @override
  String walkCommuteStationHeader(String station, String line, String way) {
    return '$station · $line $way';
  }

  @override
  String walkCommuteEta(String time) {
    return '到着予定 $time';
  }

  @override
  String get walkCommuteEtaEstimated => '(推定)';

  @override
  String walkCommuteSummary(int minutes, int count) {
    return '合計$minutes分 · 乗換$count回';
  }

  @override
  String walkCommuteLegWalk(int minutes) {
    return '徒歩 $minutes';
  }

  @override
  String walkCommuteLegSubway(
    String line,
    String from,
    String to,
    int minutes,
  ) {
    return '$line $from→$to $minutes';
  }

  @override
  String walkCommuteAlternatives(int count) {
    return '他のルート$count件';
  }

  @override
  String walkCommuteQueriedAt(String time) {
    return '$time 照会';
  }

  @override
  String get walkCommuteStale => 'もう一度照会してください';

  @override
  String get walkCommuteRealtimeUnavailable => 'リアルタイム情報なし';

  @override
  String get walkCommuteRealtimeFailed => 'リアルタイム情報を読み込めませんでした';

  @override
  String get walkCommuteMissingPlaces => '先に自宅と会社を設定してください';

  @override
  String get walkCommuteMissingKey => 'APIキーがありません — config/commute_keys.json';

  @override
  String get walkCommuteNetwork => 'ネットワークに接続できません';

  @override
  String get walkCommuteNoRoute => 'この区間の地下鉄ルートがありません';

  @override
  String walkCommuteServer(String message) {
    return 'サーバーエラー: $message';
  }

  @override
  String get walkCommutePlaceHome => '自宅';

  @override
  String get walkCommutePlaceWork => '会社';

  @override
  String get walkCommutePlaceUnset => '設定';
}
