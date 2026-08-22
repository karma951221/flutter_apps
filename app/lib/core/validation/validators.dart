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

  /// 반환값이 null 이면 통과, 아니면 오류 메시지.
  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return '이메일을 입력하세요';
    if (!_emailRegExp.hasMatch(v)) return '이메일 형식이 올바르지 않습니다';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return '비밀번호를 입력하세요';
    if (v.length < passwordMinLength) {
      return '비밀번호는 $passwordMinLength자 이상이어야 합니다';
    }
    return null;
  }

  static String? passwordConfirm(String? value, String password) {
    if ((value ?? '').isEmpty) return '비밀번호를 한 번 더 입력하세요';
    if (value != password) return '비밀번호가 일치하지 않습니다';
    return null;
  }

  static String? nickname(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return '닉네임을 입력하세요';
    if (v.length < nicknameMinLength) {
      return '닉네임은 $nicknameMinLength자 이상이어야 합니다';
    }
    if (v.length > nicknameMaxLength) {
      return '닉네임은 $nicknameMaxLength자 이하여야 합니다';
    }
    return null;
  }

  static String? otpCode(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return '코드를 입력하세요';
    if (v.length != 6 || int.tryParse(v) == null) return '6자리 숫자를 입력하세요';
    return null;
  }
}
