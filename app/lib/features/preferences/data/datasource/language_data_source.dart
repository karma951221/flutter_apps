/// 언어 선택을 기기에 읽고 쓰는 계약.
///
/// 값은 [String] 코드다 — 저장 형식을 아는 곳은 data 뿐이다.
abstract interface class LanguageDataSource {
  /// 저장된 코드. 없으면 null.
  String? readLanguageCode();

  Future<void> writeLanguageCode(String code);
}
