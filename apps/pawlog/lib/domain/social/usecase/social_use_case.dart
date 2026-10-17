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

  /// 산책 [walkId] 를 고친 뒤 공유한 글에도 반영한다(반려견 · 메모 · 경로, 목록 위치는 그대로).
  /// 로그인하지 않았으면 서버에 묻지 않고 Ok. 공유하지 않은 산책이어도 Ok — 고칠 글이 없다.
  Future<Result<void>> updateSharedWalk(String walkId);

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

  static const _dogRequired = Failure.validation(
    message: '반려견이 없는 산책은 공유할 수 없습니다',
    field: 'dogs',
    failureCode: FailureCode.walkDogRequired,
  );

  @override
  Future<Result<String>> shareWalk(String walkId) async {
    if (!_signedIn) return const Err(_signInRequired);

    final drafted = await _draftOf(walkId);
    if (drafted case Err(:final failure)) return Err(failure);
    final draft = (drafted as Ok<WalkPostDraft>).value;
    // 서버는 반려견 이름 1~10개를 요구한다. 반려견을 지워 비어 버린 기록은 여기서 막는다.
    if (draft.dogNames.isEmpty) return const Err(_dogRequired);
    return _community.publish(draft);
  }

  @override
  Future<Result<void>> updateSharedWalk(String walkId) async {
    if (!_signedIn) return const Ok(null);

    final drafted = await _draftOf(walkId);
    if (drafted case Err(:final failure)) return Err(failure);
    final draft = (drafted as Ok<WalkPostDraft>).value;
    if (draft.dogNames.isEmpty) {
      // 서버가 받지 않는 글이다. 공유한 산책일 때만 실패로 알린다 — 공유하지 않은 산책을
      // 고칠 때마다 실패 안내가 뜨면 안 된다.
      final shared = await _community.isPublished(walkId);
      return switch (shared) {
        Ok(value: false) => const Ok(null),
        Ok() => const Err(_dogRequired),
        Err(:final failure) => Err(failure),
      };
    }
    final updated = await _community.updatePublished(draft);
    return switch (updated) {
      Ok() => const Ok(null),
      Err(:final failure) => Err(failure),
    };
  }

  /// 공유 · 공유 글 고치기가 같이 쓰는 초안 — 경로 앞뒤 자르기 · 메모 다듬기는 [WalkPostDraft.fromWalk].
  Future<Result<WalkPostDraft>> _draftOf(String walkId) async {
    final found = await _walks.findById(walkId);
    if (found case Err(:final failure)) return Err(failure);
    final walk = (found as Ok<Walk?>).value;
    if (walk == null) {
      return const Err(Failure.notFound(failureCode: FailureCode.walkNotFound));
    }

    final tracked = await _walks.getTrack(walkId);
    if (tracked case Err(:final failure)) return Err(failure);
    final track = (tracked as Ok<List<WalkTrackPoint>>).value;

    return Ok(WalkPostDraft.fromWalk(walk, track));
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
