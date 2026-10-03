import 'package:freezed_annotation/freezed_annotation.dart';

part 'tracking_notice.freezed.dart';

/// Android 포그라운드 알림 문구. l10n 은 UI 가 풀어서 넘긴다.
@freezed
class TrackingNotice with _$TrackingNotice {
  @override
  final String title;
  @override
  final String text;

  const TrackingNotice({required this.title, required this.text});
}
