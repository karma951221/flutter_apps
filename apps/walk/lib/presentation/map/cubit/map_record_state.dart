import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../data/location/background_location_access.dart';
import '../../../domain/location/entity/record_retention.dart';
import '../../../domain/location/recorder/recorder_status.dart';

part 'map_record_state.freezed.dart';

/// 위치 기록 켜기 흐름의 상태.
@freezed
class MapRecordState with _$MapRecordState {
  @override
  final RecorderStatus status;

  /// 켜기 · 끄기 · 지우기가 진행 중이다.
  @override
  final bool busy;

  /// 마지막 권한 확인 결과. 아직 묻지 않았으면 null.
  @override
  final AlwaysAccess? access;

  /// 보관 기간.
  @override
  final RecordRetention retention;

  /// 신체 활동 권한(정지 감지). 확인 전이면 null.
  @override
  final bool? activityRecognition;

  /// 알림 권한. 확인 전이면 null.
  @override
  final bool? notification;

  /// 저장된 위치 점이 하나라도 있는지. 읽기 전 · 읽지 못했으면 null — 지도는 false 일 때만
  /// 처음 안내(기록을 켠 적 없음)를 띄운다.
  @override
  final bool? hasPoints;

  /// [MapRecordCubit.load] 가 한 번 끝났다(실패해도). 그 전엔 지도가 칩도 안내도 띄우지 않는다.
  @override
  final bool loaded;

  const MapRecordState({
    required this.status,
    required this.busy,
    this.access,
    this.retention = RecordRetention.never,
    this.activityRecognition,
    this.notification,
    this.hasPoints,
    this.loaded = false,
  });
}
