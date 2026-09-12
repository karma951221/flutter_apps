import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import 'package:core/core.dart';

extension ValidationErrorLocalizations on ValidationError {
  String localized(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (this) {
      ValidationError.emailRequired => l10n.validationEmailRequired,
      ValidationError.emailInvalid => l10n.validationEmailInvalid,
      ValidationError.passwordRequired => l10n.validationPasswordRequired,
      ValidationError.passwordTooShort => l10n.validationPasswordTooShort,
      ValidationError.passwordConfirmationRequired =>
        l10n.validationPasswordConfirmationRequired,
      ValidationError.passwordMismatch => l10n.validationPasswordMismatch,
      ValidationError.nicknameRequired => l10n.validationNicknameRequired,
      ValidationError.nicknameTooShort => l10n.validationNicknameTooShort,
      ValidationError.nicknameTooLong => l10n.validationNicknameTooLong,
      ValidationError.otpRequired => l10n.validationOtpRequired,
      ValidationError.otpInvalid => l10n.validationOtpInvalid,
    };
  }
}
