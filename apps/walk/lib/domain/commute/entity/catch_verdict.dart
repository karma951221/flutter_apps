import 'package:freezed_annotation/freezed_annotation.dart';

part 'catch_verdict.freezed.dart';

@freezed
sealed class CatchVerdict with _$CatchVerdict {
  const factory CatchVerdict.catchFirst() = CatchFirst;
  const factory CatchVerdict.catchSecond() = CatchSecond;
  const factory CatchVerdict.missBoth() = MissBoth;
  const factory CatchVerdict.unknown() = CatchUnknown;
}
