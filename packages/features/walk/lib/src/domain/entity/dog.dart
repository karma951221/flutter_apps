import 'package:freezed_annotation/freezed_annotation.dart';

part 'dog.freezed.dart';

/// [photoPath] 는 앱 문서 폴더 기준 상대 경로다 (절대 경로는 재설치마다 바뀐다).
@freezed
class Dog with _$Dog {
  @override
  final String id;
  @override
  final String name;
  @override
  final String? breed;
  @override
  final DateTime? birthday;
  @override
  final String? photoPath;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  const Dog({
    required this.id,
    required this.name,
    this.breed,
    this.birthday,
    this.photoPath,
    required this.createdAt,
    required this.updatedAt,
  });
}
