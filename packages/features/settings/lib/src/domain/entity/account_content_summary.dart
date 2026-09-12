import 'package:freezed_annotation/freezed_annotation.dart';

part 'account_content_summary.freezed.dart';

/// 탈퇴 확인에 보여줄 "잃게 될 것" 의 개수.
///
/// 종류만 나열하면 심리적 무게가 없다 — 이름과 숫자여야 한다
/// (손실 회피, ux-psychology-review.md 6번). 정보이지 압박이 아니므로
/// 이 값으로 버튼 문구를 바꾸지 않는다.
@freezed
class AccountContentSummary with _$AccountContentSummary {
  @override
  final int postCount;
  @override
  final int commentCount;

  const AccountContentSummary({
    required this.postCount,
    required this.commentCount,
  });
}
