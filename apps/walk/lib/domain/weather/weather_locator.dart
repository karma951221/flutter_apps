import 'package:freezed_annotation/freezed_annotation.dart';

import 'weather_problem.dart';

part 'weather_locator.freezed.dart';

/// 날씨를 볼 위치를 얻은 결과.
@freezed
sealed class WeatherFix with _$WeatherFix {
  const factory WeatherFix.located(double lat, double lng) = WeatherLocated;
  const factory WeatherFix.failed(WeatherProblem problem) = WeatherNoFix;
}

/// 날씨용 지금 위치. 화면은 좌표 대신 이 인터페이스만 안다.
abstract interface class WeatherLocator {
  /// 지금 위치. 못 얻으면 이유를 담아 돌려준다(던지지 않는다).
  Future<WeatherFix> locate();

  /// 좌표의 장소 이름. 없거나 못 물으면 null.
  Future<String?> placeName(double lat, double lng);

  /// [problem] 을 사용자가 풀 수 있게 설정 · 권한 화면으로 보낸다.
  Future<void> resolve(WeatherProblem problem);
}
