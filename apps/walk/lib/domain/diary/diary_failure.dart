import 'package:core/core.dart';

/// 일기 규칙 위반의 종류. `Failure.validation(field: DiaryFailure.x.name)` 로 실어 보낸다.
enum DiaryFailure {
  emptyEntry,
  futureTime,
  tooManyMedia,
  videoTooLong,
  defaultStoryLocked,
  endBeforeStart,
  storyClosed,
  notFound,
  mediaProcessing;

  Failure toFailure() => Failure.validation(field: name);
}
