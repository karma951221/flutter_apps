/// 화면에 표시할 문구와 분리된 입력 검증 결과.
enum ValidationError {
  emailRequired,
  emailInvalid,
  passwordRequired,
  passwordTooShort,
  passwordConfirmationRequired,
  passwordMismatch,
  nicknameRequired,
  nicknameTooShort,
  nicknameTooLong,
  otpRequired,
  otpInvalid,
}

/// 입력 검증 규칙.
///
/// DB 제약(profiles_nickname_length 등)과 값을 일치시킨다.
/// 서버에 갔다 와서 실패하는 것보다 여기서 막는 편이 사용자에게 빠르다.
abstract final class Validators {
  static const nicknameMinLength = 2;
  static const nicknameMaxLength = 20;
  static const passwordMinLength = 8;
  static const bioMaxLength = 200;

  static final _emailRegExp = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  /// 반환값이 null 이면 통과, 아니면 locale 독립 오류 코드.
  static ValidationError? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return ValidationError.emailRequired;
    if (!_emailRegExp.hasMatch(v)) return ValidationError.emailInvalid;
    return null;
  }

  static ValidationError? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return ValidationError.passwordRequired;
    if (v.length < passwordMinLength) {
      return ValidationError.passwordTooShort;
    }
    return null;
  }

  static ValidationError? passwordConfirm(String? value, String password) {
    if ((value ?? '').isEmpty) {
      return ValidationError.passwordConfirmationRequired;
    }
    if (value != password) return ValidationError.passwordMismatch;
    return null;
  }

  static ValidationError? nickname(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return ValidationError.nicknameRequired;
    if (v.length < nicknameMinLength) {
      return ValidationError.nicknameTooShort;
    }
    if (v.length > nicknameMaxLength) {
      return ValidationError.nicknameTooLong;
    }
    return null;
  }

  static ValidationError? otpCode(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return ValidationError.otpRequired;
    if (v.length != 6 || int.tryParse(v) == null) {
      return ValidationError.otpInvalid;
    }
    return null;
  }
}
