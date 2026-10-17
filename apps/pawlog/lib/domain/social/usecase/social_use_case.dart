import 'package:core/core.dart';
import 'package:injectable/injectable.dart';

import '../../walk/entity/walk.dart';
import '../../walk/entity/walk_track_point.dart';
import '../../walk/repository/walk_repository.dart';
import '../entity/auth_session.dart';
import '../entity/walk_post.dart';
import '../entity/walk_post_draft.dart';
import '../repository/auth_repository.dart';
import '../repository/community_repository.dart';

/// 모두의 산책(W5 social) facade — 로그인 · 공유 · 좋아요를 [WalkUseCase] 와 나눠 둔다.
///
/// 공유 · 공유 취소 · 좋아요는 로그인이 필요하다. 로그인하지 않았으면 서버에 묻지 않고
/// [FailureCode.authenticationRequired] 로 끝낸다 — 화면은 이 코드를 보고 로그인 화면을 연다.
/// 둘러보기([fetchCommunityPage])는 로그인 없이 된다(plan 결정 6).
abstract interface class SocialUseCase {
  Stream<AuthSession?> get sessions;

  AuthSession? get currentSession;

  Future<Result<void>> signIn(String email, String password);

  Future<Result<void>> signUp(String email, String password, String nickname);

  Future<Result<void>> signOut();

  /// 모두의 산책 한 페이지. [after] 는 앞 페이지의 `nextCursor`.
  Future<Result<CursorPage<WalkPost>>> fetchCommunityPage({String? after});

  /// 기기의 산책 [walkId] 를 공유하고 글 id 를 돌려준다. 경로는 앞뒤 150 m 를 잘라 낸다.
  Future<Result<String>> shareWalk(String walkId);

  Future<Result<void>> unshareWalk(String walkId);

  /// 로그인하지 않았으면 false.
  Future<Result<bool>> isWalkShared(String walkId);

  Future<Result<void>> likePost(String postId);

  Future<Result<void>> unlikePost(String postId);
}

@LazySingleton(as: SocialUseCase)
class DefaultSocialUseCase implements SocialUseCase {
  DefaultSocialUseCase(this._auth, this._walks, this._community);

  final AuthRepository _auth;
  final WalkRepository _walks;
  final CommunityRepository _community;

  static const pageSize = 20;

  static const _signInRequired = Failure.auth(
    message: '로그인이 필요합니다',
    code: 'sign_in_required',
    failureCode: FailureCode.authenticationRequired,
  );

  bool get _signedIn => _auth.current != null;

  @override
  Stream<AuthSession?> get sessions => _auth.sessions;

  @override
  AuthSession? get currentSession => _auth.current;

  @override
  Future<Result<void>> signIn(String email, String password) =>
      _auth.signIn(email.trim(), password);

  @override
  Future<Result<void>> signUp(String email, String password, String nickname) =>
      _auth.signUp(email.trim(), password, nickname.trim());

  @override
  Future<Result<void>> signOut() => _auth.signOut();

  @override
  Future<Result<CursorPage<WalkPost>>> fetchCommunityPage({String? after}) =>
      _community.fetchPage(after: after, limit: pageSize);

  @override
  Future<Result<String>> shareWalk(String walkId) async {
    if (!_signedIn) return const Err(_signInRequired);

    final found = await _walks.findById(walkId);
    if (found case Err(:final failure)) return Err(failure);
    final walk = (found as Ok<Walk?>).value;
    if (walk == null) {
      return const Err(Failure.notFound(failureCode: FailureCode.walkNotFound));
    }

    final tracked = await _walks.getTrack(walkId);
    if (tracked case Err(:final failure)) return Err(failure);
    final track = (tracked as Ok<List<WalkTrackPoint>>).value;

    final draft = WalkPostDraft.fromWalk(walk, track);
    // 서버는 반려견 이름 1~10개를 요구한다. 반려견을 지워 비어 버린 기록은 여기서 막는다.
    if (draft.dogNames.isEmpty) {
      return const Err(
        Failure.validation(
          message: '반려견이 없는 산책은 공유할 수 없습니다',
          field: 'dogs',
          failureCode: FailureCode.walkDogRequired,
        ),
      );
    }
    return _community.publish(draft);
  }

  @override
  Future<Result<void>> unshareWalk(String walkId) async {
    if (!_signedIn) return const Err(_signInRequired);
    return _community.unpublish(walkId);
  }

  @override
  Future<Result<bool>> isWalkShared(String walkId) async {
    if (!_signedIn) return const Ok(false);
    return _community.isPublished(walkId);
  }

  @override
  Future<Result<void>> likePost(String postId) async {
    if (!_signedIn) return const Err(_signInRequired);
    return _community.like(postId);
  }

  @override
  Future<Result<void>> unlikePost(String postId) async {
    if (!_signedIn) return const Err(_signInRequired);
    return _community.unlike(postId);
  }
}
