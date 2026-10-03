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
  String get walkAppTitle => 'pawlog';

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
  String get walkLocating => '位置情報を探しています…';
}
