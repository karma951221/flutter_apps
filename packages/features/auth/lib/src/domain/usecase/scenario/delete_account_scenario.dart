import 'package:core/core.dart';
import '../../repository/auth_repository.dart';

/// 회원 탈퇴.
///
/// 지금은 위임 하나지만, 유예 기간이나 탈퇴 사유 수집이 생기면 그 흐름이
/// 여기에 놓인다. 삭제 범위(cascade)와 Storage 정리의 분담은 저장소 구현과
/// docs/schema.md 가 설명한다 — domain 은 "계정을 지운다"만 안다.
class DeleteAccountScenario {
  const DeleteAccountScenario(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call() => _repository.deleteAccount();
}
