import 'package:freezed_annotation/freezed_annotation.dart';

import 'geo_point.dart';

part 'station.freezed.dart';

@freezed
class Station with _$Station {
  @override
  final String id;
  @override
  final String name;
  @override
  final List<String> lines;
  @override
  final GeoPoint location;

  const Station({
    required this.id,
    required this.name,
    required this.lines,
    required this.location,
  });
}
