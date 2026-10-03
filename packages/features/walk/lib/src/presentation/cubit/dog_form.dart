import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entity/dog.dart';
import '../../domain/entity/dog_draft.dart';

part 'dog_form.freezed.dart';

/// 반려견 폼 입력값. [originalPhotoPath] 는 불러올 때의 사진이라, 새로 고른
/// 파일([photoPath])과 구별해 버릴 파일을 판단하는 데 쓴다.
@freezed
class DogForm with _$DogForm {
  @override
  final String? id;
  @override
  final String name;
  @override
  final String breed;
  @override
  final DateTime? birthday;
  @override
  final String? photoPath;
  @override
  final String? originalPhotoPath;

  const DogForm({
    this.id,
    this.name = '',
    this.breed = '',
    this.birthday,
    this.photoPath,
    this.originalPhotoPath,
  });

  factory DogForm.fromDog(Dog dog) => DogForm(
    id: dog.id,
    name: dog.name,
    breed: dog.breed ?? '',
    birthday: dog.birthday,
    photoPath: dog.photoPath,
    originalPhotoPath: dog.photoPath,
  );

  DogDraft toDraft() => DogDraft(
    id: id,
    name: name,
    breed: breed.isEmpty ? null : breed,
    birthday: birthday,
    photoPath: photoPath,
  );
}
