import 'package:freezed_annotation/freezed_annotation.dart';

import 'station.dart';

part 'commute_settings.freezed.dart';

@freezed
class CommuteSettings with _$CommuteSettings {
  @override
  final Station? home;
  @override
  final Station? work;

  const CommuteSettings({this.home, this.work});

  bool get isComplete => home != null && work != null;
}
