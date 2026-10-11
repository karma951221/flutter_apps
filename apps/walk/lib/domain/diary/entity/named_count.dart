import 'package:freezed_annotation/freezed_annotation.dart';

part 'named_count.freezed.dart';

/// 태그 · 장소처럼 이름과 쓴 횟수.
@freezed
class NamedCount with _$NamedCount {
  @override
  final String name;

  @override
  final int count;

  @override
  final DateTime lastUsedAt;

  const NamedCount({
    required this.name,
    required this.count,
    required this.lastUsedAt,
  });
}
