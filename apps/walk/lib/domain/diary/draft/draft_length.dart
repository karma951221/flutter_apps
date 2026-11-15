import 'package:freezed_annotation/freezed_annotation.dart';

part 'draft_length.freezed.dart';

/// 초안의 목표 문장 수(스펙 §4 길이 규칙). 프롬프트에 숫자로 주고 모델이 대략 따른다 — 잘라 내지 않는다.
///
/// 경계값은 여기 한 곳에만 둔다. 실사용 뒤 고친다.
@freezed
class DraftLength with _$DraftLength {
  @override
  final int min;
  @override
  final int max;

  /// 메모가 길다 — 새 문장을 덧붙이기보다 메모를 다듬으라고 지시한다.
  @override
  final bool polishMemo;

  const DraftLength({
    required this.min,
    required this.max,
    this.polishMemo = false,
  });

  /// 이 글자 수 이하면 "아주 짧은 메모"(사진도 [fewPhotos] 이하일 때 1~2문장).
  static const shortMemoChars = 20;

  /// 이 글자 수 이상이면 "긴 메모" — 최대 [long] 문장, 메모를 다듬는다.
  static const longMemoChars = 100;

  /// 짧은 메모와 함께 이 장수 이하면 짧게.
  static const fewPhotos = 1;

  /// 이 장수 이상이면 길게.
  static const manyPhotos = 4;

  static const short = DraftLength(min: 1, max: 2);
  static const normal = DraftLength(min: 2, max: 4);
  static const long = DraftLength(min: 3, max: 6);

  /// [memo] 는 앞뒤 공백을 빼고 센다.
  static DraftLength of({required String memo, required int photoCount}) {
    final chars = memo.trim().runes.length;
    if (chars >= longMemoChars) {
      return const DraftLength(min: 3, max: 6, polishMemo: true);
    }
    if (photoCount >= manyPhotos) return long;
    if (chars <= shortMemoChars && photoCount <= fewPhotos) return short;
    return normal;
  }
}
