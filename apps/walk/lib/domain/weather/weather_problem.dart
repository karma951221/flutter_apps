/// 날씨를 못 가져온 이유. 화면은 종류만 보고 문구를 고른다.
enum WeatherProblem {
  locationServiceOff,
  locationDenied,
  locationUnavailable,
  offline,
  server,
}

/// 날씨 조회 실패.
class WeatherFailure implements Exception {
  const WeatherFailure(this.problem);

  final WeatherProblem problem;

  @override
  String toString() => 'WeatherFailure($problem)';
}
