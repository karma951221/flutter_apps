import 'package:freezed_annotation/freezed_annotation.dart';

part 'entry_location.freezed.dart';

/// 좌표만(오프라인) · 이름만(직접 입력) · 둘 다.
@freezed
class EntryLocation with _$EntryLocation {
  @override
  final String? placeName;

  @override
  final double? lat;

  @override
  final double? lng;

  const EntryLocation({this.placeName, this.lat, this.lng});

  bool get hasCoordinates => lat != null && lng != null;
}
