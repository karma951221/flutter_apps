import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/walk/entity/health_access.dart';

part 'health_access_state.freezed.dart';

@freezed
class HealthAccessState with _$HealthAccessState {
  /// null = 아직 확인 중.
  @override
  final HealthAccess? access;

  /// 이번 세션에 권한을 거부했다 — Health Connect 는 두 번 거부하면 다이얼로그를
  /// 조용히 생략하므로 "설정 열기"를 함께 보인다.
  @override
  final bool canOpenSettings;

  const HealthAccessState({this.access, this.canOpenSettings = false});
}
