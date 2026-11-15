import 'package:freezed_annotation/freezed_annotation.dart';

part 'draft_context.freezed.dart';

/// 초안 요청의 재료. 모델로 가는 것은 이것뿐이다 — 좌표는 담지 않는다(장소는 이름만).
/// 메모 · 장소 이름이 담기므로 생성 toString 을 끈다.
@Freezed(toStringOverride: false)
class DraftContext with _$DraftContext {
  /// 사용자가 쓴 한 줄 메모. 비어도 된다.
  @override
  final String memo;

  /// 기록 시각(작성 화면의 시각).
  @override
  final DateTime occurredAt;

  /// 작성 화면의 장소 이름.
  @override
  final String? placeName;

  /// [placeName] 이 자동으로 잡힌 현재 위치인가(직접 넣은 장소가 아니다).
  @override
  final bool autoPlace;

  /// 초안을 요청한 시각. 촬영 시각이 이와 멀면 자동 위치를 뺀다(R-A6). null 이면 빼지 않는다.
  @override
  final DateTime? now;

  /// 앱 언어 코드(`ko` · `en` · `ja`). 메모가 비면 이 언어로 쓴다(R-A8). null 이면 한국어.
  @override
  final String? locale;

  @override
  final int photoCount;
  @override
  final int videoCount;

  /// 사진 촬영 시각 범위(EXIF). 하나면 둘이 같다.
  @override
  final DateTime? photoTakenFrom;
  @override
  final DateTime? photoTakenTo;

  @override
  final List<String> tags;

  const DraftContext({
    required this.memo,
    required this.occurredAt,
    this.placeName,
    this.autoPlace = false,
    this.now,
    this.locale,
    this.photoCount = 0,
    this.videoCount = 0,
    this.photoTakenFrom,
    this.photoTakenTo,
    this.tags = const [],
  });

  @override
  String toString() =>
      'DraftContext(photoCount: $photoCount, videoCount: $videoCount)';
}
