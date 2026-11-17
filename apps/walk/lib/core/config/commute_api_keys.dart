/// 통근 탭이 쓰는 외부 API 키. `--dart-define-from-file=config/commute_keys.json` 으로 주입한다.
/// 키가 비면 네트워크 없이 "키 없음" 상태로 둔다.
class CommuteApiKeys {
  final String odsay;
  final String seoulSubway;

  const CommuteApiKeys({required this.odsay, required this.seoulSubway});

  factory CommuteApiKeys.fromEnvironment() => const CommuteApiKeys(
        odsay: String.fromEnvironment('ODSAY_API_KEY'),
        seoulSubway: String.fromEnvironment('SEOUL_SUBWAY_API_KEY'),
      );

  bool get isComplete => odsay.trim().isNotEmpty && seoulSubway.trim().isNotEmpty;
}
