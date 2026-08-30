import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/data/nickname_match.dart';
import '../../../../core/media/image_storage.dart';
import '../../domain/entity/avatar_image_draft.dart';
import '../../domain/entity/profile_update.dart';
import '../dto/profile_dto.dart';
import 'profile_data_source.dart';

@LazySingleton(as: ProfileDataSource)
class SupabaseProfileDataSource implements ProfileDataSource {
  SupabaseProfileDataSource(this._client, this._images);

  final SupabaseClient _client;
  final ImageStorage _images;

  /// 아바타 이미지를 담는 Storage 버킷.
  static const _avatarBucket = 'avatars';

  static const _profileColumns =
      'id, nickname, bio, avatar_url, created_at, updated_at';

  @override
  Future<ProfileDto> getProfile(String userId) async {
    final row = await _client
        .from('profiles')
        .select(_profileColumns)
        .eq('id', userId)
        .single();
    return ProfileDto.fromJson(row);
  }

  @override
  Future<ProfileDto?> getMyProfile() {
    final userId = _client.auth.currentUser?.id;
    return userId == null ? Future.value(null) : getProfile(userId);
  }

  @override
  Future<ProfileDto?> updateMyProfile(ProfileUpdate update) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final row = await _client
        .from('profiles')
        .update({
          'nickname': update.nickname.trim(),
          'bio': _nullIfBlank(update.bio),
          'avatar_url': _nullIfBlank(update.avatarUrl),
        })
        .eq('id', userId)
        .select(_profileColumns)
        .single();
    return ProfileDto.fromJson(row);
  }

  @override
  Future<bool> isNicknameAvailable(String nickname) async {
    final candidate = nickname.trim();
    // `ilike` 로 좁히고 최종 판정은 Dart 가 한다 — 이유는 [NicknameMatch].
    final rows = await _client
        .from('profiles')
        .select('nickname')
        .ilike('nickname', NicknameMatch.escapeLikePattern(candidate))
        .limit(NicknameMatch.candidateLimit);
    return !rows.any(
      (row) =>
          NicknameMatch.isSameNickname(row['nickname'] as String, candidate),
    );
  }

  @override
  Future<String> uploadAvatar(AvatarImageDraft image) => _images.upload(
    bucket: _avatarBucket,
    bytes: image.bytes,
    contentType: image.contentType,
    extension: image.extension,
  );

  @override
  Future<void> removeAvatar(String? publicUrl) =>
      _images.removeByPublicUrl(bucket: _avatarBucket, publicUrl: publicUrl);

  String? _nullIfBlank(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
