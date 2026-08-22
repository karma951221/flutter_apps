import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entity/profile_update.dart';
import '../dto/profile_dto.dart';
import 'profile_data_source.dart';

@LazySingleton(as: ProfileDataSource)
class SupabaseProfileDataSource implements ProfileDataSource {
  SupabaseProfileDataSource(this._client);

  final SupabaseClient _client;

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
    final row = await _client
        .from('profiles')
        .select('id')
        .ilike('nickname', nickname.trim())
        .maybeSingle();
    return row == null;
  }

  String? _nullIfBlank(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
