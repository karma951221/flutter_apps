import 'place.dart';

enum CommuteDirection {
  toWork,
  toHome;

  PlaceKind get origin => switch (this) {
        CommuteDirection.toWork => PlaceKind.home,
        CommuteDirection.toHome => PlaceKind.work,
      };

  PlaceKind get destination => switch (this) {
        CommuteDirection.toWork => PlaceKind.work,
        CommuteDirection.toHome => PlaceKind.home,
      };

  /// 정오 전이면 출근, 아니면 퇴근.
  static CommuteDirection defaultAt(DateTime now) =>
      now.hour < 12 ? CommuteDirection.toWork : CommuteDirection.toHome;
}
