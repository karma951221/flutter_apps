import 'package:freezed_annotation/freezed_annotation.dart';

part 'dog_draft.freezed.dart';

/// 반려견 폼 입력값. [id] 가 null 이면 새로 만든다.
@freezed
class DogDraft with _$DogDraft {
  @override
  final String? id;
  @override
  final String name;
  @override
  final String? breed;
  @override
  final DateTime? birthday;
  @override
  final String? photoPath;

  const DogDraft({
    this.id,
    required this.name,
    this.breed,
    this.birthday,
    this.photoPath,
  });
}
