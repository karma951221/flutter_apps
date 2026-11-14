import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/weather/entity/weather_condition.dart';

void main() {
  final cases = <int, WeatherCondition>{
    0: WeatherCondition.clear,
    1: WeatherCondition.partlyCloudy,
    2: WeatherCondition.partlyCloudy,
    3: WeatherCondition.cloudy,
    45: WeatherCondition.fog,
    48: WeatherCondition.fog,
    51: WeatherCondition.drizzle,
    57: WeatherCondition.drizzle,
    61: WeatherCondition.rain,
    67: WeatherCondition.rain,
    71: WeatherCondition.snow,
    77: WeatherCondition.snow,
    80: WeatherCondition.showers,
    82: WeatherCondition.showers,
    85: WeatherCondition.snow,
    86: WeatherCondition.snow,
    95: WeatherCondition.thunderstorm,
    99: WeatherCondition.thunderstorm,
    100: WeatherCondition.unknown,
    4: WeatherCondition.unknown,
    58: WeatherCondition.unknown,
    78: WeatherCondition.unknown,
    83: WeatherCondition.unknown,
  };

  for (final e in cases.entries) {
    test('WMO ${e.key} → ${e.value.name}', () {
      expect(WeatherCondition.fromWmo(e.key), e.value);
    });
  }
}
