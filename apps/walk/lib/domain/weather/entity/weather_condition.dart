/// 날씨 상태. Open-Meteo 의 WMO 코드를 앱이 쓰는 갈래로 줄인 것.
enum WeatherCondition {
  clear,
  partlyCloudy,
  cloudy,
  fog,
  drizzle,
  rain,
  showers,
  snow,
  thunderstorm,
  unknown;

  /// WMO 날씨 코드 → 상태. 정의되지 않은 코드는 [unknown].
  static WeatherCondition fromWmo(int code) {
    if (code == 0) return clear;
    if (code == 1 || code == 2) return partlyCloudy;
    if (code == 3) return cloudy;
    if (code == 45 || code == 48) return fog;
    if (code >= 51 && code <= 57) return drizzle;
    if (code >= 61 && code <= 67) return rain;
    if ((code >= 71 && code <= 77) || code == 85 || code == 86) return snow;
    if (code >= 80 && code <= 82) return showers;
    if (code >= 95 && code <= 99) return thunderstorm;
    return unknown;
  }
}
