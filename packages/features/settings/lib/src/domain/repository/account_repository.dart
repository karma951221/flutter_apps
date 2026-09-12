import 'package:core/core.dart';
import '../entity/account_content_summary.dart';

/// 계정 단위의 조회. 탈퇴처럼 계정 자체에 손대는 흐름이 쓴다.
abstract interface class AccountRepository {
  /// 로그인한 사용자가 남긴 게시물·댓글 개수 (소프트 삭제 제외).
  Future<Result<AccountContentSummary>> myContentSummary();
}
