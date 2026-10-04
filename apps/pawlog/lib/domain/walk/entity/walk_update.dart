import 'package:freezed_annotation/freezed_annotation.dart';

part 'walk_update.freezed.dart';

@freezed
class WalkUpdate with _$WalkUpdate {
  @override
  final String id;
  @override
  final List<String> dogIds;
  @override
  final String? memo;
  @override
  final List<String> photoPaths;

  const WalkUpdate({
    required this.id,
    required this.dogIds,
    this.memo,
    required this.photoPaths,
  });
}
