import 'package:freezed_annotation/freezed_annotation.dart';

part 'train_arrival.freezed.dart';

@freezed
class TrainArrival with _$TrainArrival {
  /// 도착까지 남은 분. 모르면 null.
  @override
  final int? minutes;

  /// 정거장 수로 추정한 값인지.
  @override
  final bool estimated;

  @override
  final int? stationsAway;

  @override
  final String message;

  @override
  final String? destination;

  const TrainArrival({
    this.minutes,
    this.estimated = false,
    this.stationsAway,
    required this.message,
    this.destination,
  });
}
